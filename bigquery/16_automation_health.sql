-- Automation health: backup-freshness + out-of-band Apps Script heartbeats. Project: stock-trading-498512.
-- Closes two "who watches the watchers?" gaps the 2026-06-22 stack review found — the same §19/§20
-- anti-pattern (a job whose silent death no monitor would notice), now applied to the DR + delivery layer:
--
--   * BACKUP FRESHNESS. events.* -> GCS Parquet runs daily (scheduled_queries/backup_events_export.sql),
--     but the freshness dead-man's switch (state.freshness) watches the DATA tables, not the bucket — so
--     a silently-stalled backup (expired identity, deleted schedule) would go unnoticed until a restore
--     was needed. The export now logs a marker row to ops.backup_log on success; state.backup_health flags
--     a stale backup, and cadence_check.sql RAISEs on it (so the DTS failure-email — an identity-
--     independent channel — delivers the alarm).
--
--   * APPS SCRIPT LIVENESS. alert_emailer.gs + weekly_report.gs run OUTSIDE Claude on Google's servers;
--     if one silently dies (token revoked / trigger deleted), alerts/reports just stop with no signal —
--     and for the alert emailer that is circular (a dead emailer can't email that it is dead). Both now
--     write an ops.heartbeat beat each run; state.automation_heartbeat flags a stale source and
--     cadence_check.sql RAISEs (again via the independent DTS email, not via the maybe-dead emailer).
--
-- SELF-BOOTSTRAPPING (same philosophy as state.cadence_watch / state.instruction_drift): a source is
-- "monitored" only once it has produced >=1 row, so applying this file BEFORE the producers are wired
-- (the backup-log write + the two heartbeat writes) never false-alarms — the alarm arms itself the first
-- time a backup logs / a script beats, and then a SUBSEQUENT silence is what fires.
--
-- Depends on 09_market_calendar.sql (state.trading_day_today) + 10_observability.sql (ops.alerts,
-- ops.sp_raise_alert_once). Idempotent (CREATE TABLE IF NOT EXISTS / OR REPLACE). Apply after 10/12 via
-- the BigQuery MCP execute_sql, and BEFORE re-pasting cadence_check.sql (which references these views).

-- ===== ops.backup_log — one row per successful events.* backup export =====
CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.backup_log` (
  backup_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  run_date DATE NOT NULL,             -- America/Denver operating day the backup ran for
  tables_exported INT64,              -- how many base tables were exported this run
  note STRING
) PARTITION BY run_date
OPTIONS(description='One row per successful backup export (written at the end of scheduled_queries/backup_events_export.sql for dataset=events and ops_export.sql for dataset=ops). Source for state.backup_health (events) + state.ops_backup_health (ops) — catches a silently-stalled backup the data-side freshness switch cannot see.');

-- ===== 2026-06-28 stack review #2 — distinguish events vs ops backups in the marker =====
-- The events.* export (backup_events_export.sql) and the NEW ops.* export (ops_export.sql) both log a
-- marker here. A `dataset` discriminator lets state.backup_health watch the events backup and a parallel
-- state.ops_backup_health watch the ops backup INDEPENDENTLY, and keeps the restore drill's drill-date
-- read (ops.sp_restore_drill, 17) pinned to the events snapshot. Legacy rows (pre-2026-06-28) have NULL
-- dataset and are treated as 'events' via COALESCE everywhere. CREATE TABLE IF NOT EXISTS above will not
-- add a column to a pre-existing table, so this explicit ALTER is the upgrade path (same as 18's per_table_rows).
ALTER TABLE `stock-trading-498512.ops.backup_log` ADD COLUMN IF NOT EXISTS dataset STRING;

-- ===== ops.heartbeat — liveness beats from out-of-band automation =====
CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.heartbeat` (
  beat_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  source STRING NOT NULL,             -- 'weekly_report' | 'alert_emailer'
  note STRING
) PARTITION BY DATE(beat_ts) CLUSTER BY source
OPTIONS(description='Liveness beats from out-of-band Google Apps Scripts (alert_emailer.gs, weekly_report.gs). Source for state.automation_heartbeat — catches a silently-dead emailer/report (the §19 who-watches-the-watchers gap).');

-- ===== state.backup_health — is the latest events backup fresh? (self-bootstrapping) =====
-- Backups run DAILY (incl. non-trading days) ~05:30 UTC. stale = a backup has logged before AND the
-- newest is older than 2 calendar days (tolerates the UTC/Denver offset + one missed run, catches a
-- multi-day outage). monitored gates the alarm so this never fires before the marker write is wired.
CREATE OR REPLACE VIEW `stock-trading-498512.state.backup_health` AS
WITH b AS (
  SELECT MAX(run_date) AS last_backup_date, MAX(backup_ts) AS last_backup_ts
  FROM `stock-trading-498512.ops.backup_log`
  WHERE COALESCE(dataset, 'events') = 'events'   -- events.* export only (ops.* watched by state.ops_backup_health)
),
td AS (SELECT today FROM `stock-trading-498512.state.trading_day_today`)
SELECT
  b.last_backup_date,
  b.last_backup_ts,
  td.today,
  (b.last_backup_date IS NOT NULL) AS monitored,
  COALESCE(b.last_backup_date IS NOT NULL
           AND b.last_backup_date < DATE_SUB(td.today, INTERVAL 2 DAY), FALSE) AS stale,
  CURRENT_TIMESTAMP() AS checked_at
FROM b, td;

-- ===== state.ops_backup_health — is the latest ops.* (audit/control-plane) backup fresh? =====
-- 2026-06-28 stack review #2 (#2). The ops.* dataset (run_log / alerts / backup_log / heartbeat /
-- account_snapshot / drill_log) is IRREPLACEABLE append-only audit history with NO upstream to rebuild
-- from — yet backup_events_export.sql only ever exported events.*. ops_export.sql now backs ops.* up too
-- and logs a dataset='ops' marker here; this view is its dead-man's switch, identical in shape + window to
-- state.backup_health. Self-bootstrapping (monitored only once an ops backup has logged). cadence_check.sql
-- RAISEs on stale (the DTS failure-email — independent of the thing being backed up).
CREATE OR REPLACE VIEW `stock-trading-498512.state.ops_backup_health` AS
WITH b AS (
  SELECT MAX(run_date) AS last_backup_date, MAX(backup_ts) AS last_backup_ts
  FROM `stock-trading-498512.ops.backup_log`
  WHERE COALESCE(dataset, 'events') = 'ops'
),
td AS (SELECT today FROM `stock-trading-498512.state.trading_day_today`)
SELECT
  b.last_backup_date,
  b.last_backup_ts,
  td.today,
  (b.last_backup_date IS NOT NULL) AS monitored,
  COALESCE(b.last_backup_date IS NOT NULL
           AND b.last_backup_date < DATE_SUB(td.today, INTERVAL 2 DAY), FALSE) AS stale,
  CURRENT_TIMESTAMP() AS checked_at
FROM b, td;

-- ===== state.automation_heartbeat — are the out-of-band scripts still firing? (self-bootstrapping) =====
-- Per source, the expected max age between beats. stale = has beaten before AND the last beat is older
-- than that. monitored = has ever beaten (so a script the owner hasn't deployed yet never alarms).
CREATE OR REPLACE VIEW `stock-trading-498512.state.automation_heartbeat` AS
WITH expected AS (
  SELECT * FROM UNNEST([
    STRUCT('alert_emailer' AS source, 8   AS max_age_hours),   -- polls every ~2h; stale after ~4 misses (jitter-tolerant)
    STRUCT('weekly_report' AS source, 216 AS max_age_hours)    -- weekly; stale after ~9 days (1 missed week + slack)
  ])
),
last AS (
  SELECT source, MAX(beat_ts) AS last_beat_ts
  FROM `stock-trading-498512.ops.heartbeat`
  GROUP BY source
)
SELECT
  e.source,
  e.max_age_hours,
  l.last_beat_ts,
  TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), l.last_beat_ts, HOUR) AS age_hours,
  (l.last_beat_ts IS NOT NULL) AS monitored,
  COALESCE(l.last_beat_ts IS NOT NULL
           AND TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), l.last_beat_ts, HOUR) > e.max_age_hours, FALSE) AS stale,
  CURRENT_TIMESTAMP() AS checked_at
FROM expected e
LEFT JOIN last l USING (source);

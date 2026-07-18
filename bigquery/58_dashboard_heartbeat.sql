-- Dashboard liveness heartbeat (self-improvement audit 2026-07-15, Architect recommendation #3).
-- Project: stock-trading-498512. ops/dashboard/generate_dashboard.py (.github/workflows/dashboard.yml,
-- daily ~05:20 UTC when vars.PUBLISH_DASHBOARD is enabled) was the one out-of-band delivery surface
-- with NO liveness monitor at all — unlike alert_emailer.gs / weekly_report.gs, which both beat
-- ops.heartbeat and are watched by state.automation_heartbeat, a silently-broken dashboard build had
-- no dead-man's switch. generate_dashboard.py now best-effort-writes ops.heartbeat(source='dashboard')
-- at the end of a successful build (never fails the build if the write errors — same best-effort
-- discipline every other heartbeat write in this codebase follows). This view adds 'dashboard' to the
-- watched-source set so state.automation_heartbeat / cadence_check.sql's dead-man's switch can flag it
-- stale. Self-bootstrapping: monitored stays FALSE (no alarm) until the dashboard has beaten at least
-- once, i.e. immediately after this file + the generate_dashboard.py write both go live.
--
-- Apply AFTER bigquery/16_automation_health.sql (redefines state.automation_heartbeat verbatim, adding
-- exactly one UNNEST row). Idempotent (CREATE OR REPLACE VIEW); safe to re-run.
--
-- OWNER ACTION: generate_dashboard.py's heartbeat write needs `gh-ci-runner@` granted a narrow,
-- TABLE-SCOPED `roles/bigquery.dataEditor` on `ops.heartbeat` (it does not have this today — the
-- baseline WIF grant is read-only, RUNBOOK §6). The write is wrapped try/except (never fails the
-- dashboard build without it); until granted, 'dashboard' simply never appears as `monitored` here,
-- which is the correct fail-quiet default, not a bug.
CREATE OR REPLACE VIEW `stock-trading-498512.state.automation_heartbeat` AS
WITH expected AS (
  SELECT * FROM UNNEST([
    STRUCT('alert_emailer' AS source, 8   AS max_age_hours),   -- polls every ~2h; stale after ~4 misses (jitter-tolerant)
    STRUCT('weekly_report' AS source, 216 AS max_age_hours),   -- weekly; stale after ~9 days (1 missed week + slack)
    STRUCT('dashboard'     AS source, 56  AS max_age_hours)    -- daily; stale after ~2.3 days (1 missed run + slack, matching state.backup_health's 2-day tolerance)
  ])
),
last AS (
  SELECT source, MAX(beat_ts) AS last_beat_ts
  FROM `stock-trading-498512.ops.heartbeat`
  -- A 'poll-error' beat (alert_emailer.gs beat_(false) on a PERSISTENT BigQuery failure) is NOT proof
  -- of life; excluding it from the liveness MAX lets a sustained emailer outage age out and trip the
  -- DTS instead of the error-beat keeping the source "fresh" forever (2026-07-18 audit). Kept in
  -- lockstep with bigquery/16_automation_health.sql's identical `last` CTE (58 redefines this view
  -- verbatim + the one 'dashboard' UNNEST row). weekly_report/dashboard never write 'poll-error'.
  WHERE note IS DISTINCT FROM 'poll-error'
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

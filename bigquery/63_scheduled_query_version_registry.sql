-- Scheduled-query body-drift detection (self-improvement audit 2026-07-15 — CONFIRMED GAP
-- scheduled-query-body-drift-undetected). Project: stock-trading-498512. Apply after
-- 16_automation_health.sql, 34_alert_lifecycle.sql.
--
-- WHY: state.instruction_drift (bigquery/15_routine_catalog.sql) already catches a live-vs-canonical
-- mismatch for ROUTINE triggers (the web-UI Claude sessions). No analogous mechanism exists for the 11
-- registered `bigquery/scheduled_queries/*.sql` bodies — an edit there takes effect only via a manual
-- owner console re-paste (an accepted platform limitation, RUNBOOK), but nothing confirms whether or
-- when that re-paste actually happened. `cadence_check.sql`'s own header has previously admitted a
-- live-body lag ("LIVE scheduled-query body still ran without the sp_auto_resolve_alerts call").
--
-- DESIGN, mirrors bigquery/43_script_version_registry.sql (the Apps Script version-drift pattern)
-- EXACTLY, ported to scheduled queries: each `bigquery/scheduled_queries/*.sql` file gets a version
-- marker + a self-reported `ops.heartbeat(source='sq:<name>', version=<v>)` write at the end of its own
-- body. SELF-REPORTING (not job-history scraping): a scheduled query proving "I, the CURRENTLY EXECUTING
-- body, am version N" is far more reliable than retroactively parsing INFORMATION_SCHEMA.JOBS_BY_PROJECT
-- job text for an embedded marker (fragile, and would need broader job-history-read permissions than
-- resourceViewer reliably grants). NO NEW IAM GRANT NEEDED: `ops.sp_beat_heartbeat` below has no
-- `SQL SECURITY INVOKER` clause, so — exactly like the already-live `ops.sp_raise_alert` every
-- resourceViewer-scoped scheduled query already calls successfully — it runs with its CREATOR's
-- (DEFINER) rights, not the calling scheduled query's own read-only identity.
--
-- SELF-BOOTSTRAPPING (same convention as state.script_version_drift / state.automation_heartbeat):
-- monitored=FALSE (no alarm) until a query has beaten at least once with its version marker; fail-closed
-- once monitored=TRUE, so a regressed/missing beat is drift=TRUE, never silently "up to date."

-- ===== ops.sp_beat_heartbeat — DEFINER-rights heartbeat write, callable by any scheduled query =====
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_beat_heartbeat`(in_source STRING, in_version STRING, in_note STRING)
BEGIN
  INSERT INTO `stock-trading-498512.ops.heartbeat` (source, version, note)
  VALUES (in_source, in_version, in_note);
END;

-- ===== state.expected_scheduled_query_versions — what SHOULD be deployed, per this repo =====
CREATE TABLE IF NOT EXISTS `stock-trading-498512.state.expected_scheduled_query_versions` (
  sq_name STRING NOT NULL,            -- bare filename without .sql, e.g. 'cadence_check' — MUST match
                                       -- the 'sq:<name>' ops.heartbeat source suffix
  expected_version STRING NOT NULL,
  git_note STRING,
  updated_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
) OPTIONS(description='Seed/reference table: the version each bigquery/scheduled_queries/*.sql body SHOULD be running live, per repo state. Source of truth for state.scheduled_query_version_drift. Updated by a guarded MERGE whenever a file''s SQ_VERSION marker is bumped.');

MERGE `stock-trading-498512.state.expected_scheduled_query_versions` T
USING (
  SELECT * FROM UNNEST([
    STRUCT('embed_pending' AS sq_name, 'v1' AS expected_version, 'initial version marker, 2026-07-15' AS git_note),
    STRUCT('daily_freshness_check', 'v1', 'initial version marker, 2026-07-15'),
    STRUCT('cadence_check', 'v4', 'v3, 2026-07-15 (same day as initial marker): v2 added the b3_trading_enabled_drift check (bigquery/64_b3_live_invariants.sql, Gap 13); v3 added the backup_per_table_row_drop check (bigquery/65_backup_per_table_health.sql, Gap 19). v4, 2026-07-16 (consolidated consumption-closure + resilience audit): added the ci_finding raise/auto-resolve block (bigquery/67_ci_findings_bridge.sql, CC-1); wired scheduled_query_version_drift / probe_funding_stalled / cash_flows_backfill_broken record-only warning checks (bigquery/63/62/68, CC-3+RES-4); added loop:research_quality_feedback to both constant_tuning_loop_heartbeat_missing dead-man UNNEST lists (LC-4 cadence_check portion); extended the #14 auto-age category list with immediate_action_flagged + process_scorecard_signal (CC-7)'),
    STRUCT('integrity_check', 'v1', 'initial version marker, 2026-07-15'),
    STRUCT('safety_critical_dml_watch', 'v1', 'initial version marker, 2026-07-15'),
    STRUCT('daily_staging_cap_check', 'v1', 'initial version marker, 2026-07-15'),
    STRUCT('backup_events_export', 'v1', 'initial version marker, 2026-07-15'),
    STRUCT('ops_export', 'v1', 'initial version marker, 2026-07-15'),
    STRUCT('delivery_canary', 'v1', 'initial version marker, 2026-07-15'),
    STRUCT('restore_drill', 'v1', 'initial version marker, 2026-07-15'),
    STRUCT('fire_drill_order_guard', 'v1', 'initial version marker, 2026-07-15'),
    STRUCT('fire_drill_alert_lifecycle', 'v1', 'initial version marker, 2026-07-15')
  ])
) S
ON T.sq_name = S.sq_name
WHEN MATCHED AND T.expected_version != S.expected_version THEN
  UPDATE SET expected_version = S.expected_version, git_note = S.git_note, updated_ts = CURRENT_TIMESTAMP()
WHEN NOT MATCHED THEN
  INSERT (sq_name, expected_version, git_note) VALUES (S.sq_name, S.expected_version, S.git_note);

-- ===== state.scheduled_query_version_drift — latest reported version vs expected, per query =====
CREATE OR REPLACE VIEW `stock-trading-498512.state.scheduled_query_version_drift` AS
WITH latest_beat AS (
  SELECT
    SUBSTR(source, 4) AS sq_name,   -- strip the 'sq:' prefix
    ARRAY_AGG(beat_ts ORDER BY beat_ts DESC LIMIT 1)[SAFE_OFFSET(0)] AS last_beat_ts,
    ARRAY_AGG(version ORDER BY beat_ts DESC LIMIT 1)[SAFE_OFFSET(0)] AS last_reported_version,
    LOGICAL_OR(version IS NOT NULL AND TRIM(version) != '') AS ever_reported_version
  FROM `stock-trading-498512.ops.heartbeat`
  WHERE STARTS_WITH(source, 'sq:')
  GROUP BY source
)
SELECT
  e.sq_name,
  e.expected_version,
  lb.last_reported_version,
  lb.last_beat_ts,
  COALESCE(lb.ever_reported_version, FALSE) AS monitored,
  COALESCE(lb.ever_reported_version, FALSE)
    AND (lb.last_reported_version IS NULL
         OR TRIM(lb.last_reported_version) = ''
         OR lb.last_reported_version != e.expected_version) AS drift,
  CURRENT_TIMESTAMP() AS checked_at
FROM `stock-trading-498512.state.expected_scheduled_query_versions` e
LEFT JOIN latest_beat lb ON lb.sq_name = e.sq_name;

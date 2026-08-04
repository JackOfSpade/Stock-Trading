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
  expected_interval_hours INT64,      -- MON H5 (2026-07-17): the cadence of this DTS job in hours
                                       --   (daily=24, weekly=168, monthly=744, every-6h=6). Drives the
                                       --   beat-AGE dead-man (stale_beat) in state.scheduled_query_version_drift.
  updated_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
) OPTIONS(description='Seed/reference table: the version each bigquery/scheduled_queries/*.sql body SHOULD be running live, per repo state. Source of truth for state.scheduled_query_version_drift. Updated by a guarded MERGE whenever a file\'s SQ_VERSION marker is bumped. expected_interval_hours (MON H5) drives the beat-age dead-man.');

-- MON H5 (2026-07-17): additive column for the beat-age dead-man on the ALREADY-LIVE table (the
-- CREATE TABLE IF NOT EXISTS above is a no-op once the table exists, so it cannot add the column live).
ALTER TABLE `stock-trading-498512.state.expected_scheduled_query_versions`
  ADD COLUMN IF NOT EXISTS expected_interval_hours INT64;

MERGE `stock-trading-498512.state.expected_scheduled_query_versions` T
USING (
  SELECT * FROM UNNEST([
    STRUCT('embed_pending' AS sq_name, 'v2' AS expected_version, 'v2 -- body moved into ops.sp_sq_embed_pending wrapper (bigquery/75_scheduled_query_wrappers.sql), ARCH-1 2026-07-16' AS git_note, 24 AS expected_interval_hours),
    STRUCT('daily_freshness_check', 'v3', 'v2 -- body moved into ops.sp_sq_daily_freshness_check wrapper (bigquery/75_scheduled_query_wrappers.sql), ARCH-1 2026-07-16. v3, 2026-07-17 (MON STALENESS PART-3) -- RAISE predicate narrowed from all_green to the data-staleness component conjunction only (drops the open-critical-alerts echo term)', 24),
    STRUCT('cadence_check', 'v11', 'v3, 2026-07-15 (same day as initial marker): v2 added the b3_trading_enabled_drift check (bigquery/64_b3_live_invariants.sql, Gap 13); v3 added the backup_per_table_row_drop check (bigquery/65_backup_per_table_health.sql, Gap 19). v4, 2026-07-16 (consolidated consumption-closure + resilience audit): added the ci_finding raise/auto-resolve block (bigquery/67_ci_findings_bridge.sql, CC-1); wired scheduled_query_version_drift / probe_funding_stalled / cash_flows_backfill_broken record-only warning checks (bigquery/63/62/68, CC-3+RES-4); added loop:research_quality_feedback to both constant_tuning_loop_heartbeat_missing dead-man UNNEST lists (LC-4 cadence_check portion); extended the #14 auto-age category list with immediate_action_flagged + process_scorecard_signal (CC-7). v5, 2026-07-16 (ARCH-1) -- body moved into ops.sp_sq_cadence_check wrapper (bigquery/75_scheduled_query_wrappers.sql); no check logic changed. v6, 2026-07-17 (MON): added ci_findings_bridge_stale (H2) + scheduled_query_stale beat-age (H5) record-only warnings and the unconditional b3_trading_enabled_drift monitor-health-history MERGE (M2, bigquery/79). v7, 2026-07-26 (D3 monitor-promotion self-flip, ITEM 24): ddl_drift promoted WARNING->CRITICAL + joined raise_msg after state.ddl_drift_promotion_readiness fired (14 consecutive clean logged days). v8, 2026-07-26 (PARK v3 immediate-binding redesign, owner directive): park_allocator converted shadow->active_auto (ops/autonomy_levels.yaml) in the same change -- added loop:park_allocator to both constant_tuning_loop_heartbeat_missing UNNEST literals (belt-and-suspenders active_auto coverage) PLUS a new dedicated park_allocator daily-heartbeat staleness WARNING block with its own 3-trading-day (not flat 10-calendar-day) window, since D1 writes this heartbeat daily and W5\'s weekly belt-and-suspenders write to the same source could otherwise mask a dead daily call under the generic window v9, 2026-07-27 (bigquery/111_cadence_check_version_drift_autoage.sql, owner-approved follow-up to INCIDENT[ref=423ecc02-fdb7-4f47-9445-d8c79d399e8c]): added scheduled_query_version_drift to the #14 auto-age category list. It is the same self-healing shape as scheduled_query_stale -- a version marker reports what a query said the LAST time it ran, and cadence_check evaluates ~05:15 UTC ahead of most of the queries it audits, so a mid-day wrapper bump raises a drift warning that heals on the next cycle. It was the one such class missing from the list AND absent from ops.alert_policy, so every version bump left a permanently-open row needing a manual UPDATE ops.alerts (embed_pending 2026-07-17/18; daily_staging_cap_check v3->v4 2026-07-27, alert 0c2b631a). A still-drifted query is re-raised by the scheduled_query_version_drift check inside that same procedure, so a genuinely unapplied wrapper cannot age away silently. No other check logic changed. v10, 2026-07-30 (bigquery/120_ci_finding_payload_detail.sql): added detail to the ci_finding alert payload so CI finding detail text reaches the operator email. v11, 2026-08-03 (bigquery/128_b3_drift_promotion.sql -- D3 MONITOR-PROMOTION SELF-FLIP): b3_trading_enabled_drift promoted WARNING->CRITICAL + joined raise_msg after state.b3_promotion_readiness fired (14 consecutive clean logged days, measured n_recent=14/n_recent_clean=14 on 2026-08-03). Promoted body copied verbatim from bigquery/79_b3_promotion.sql\'s header spec; no standalone RAISE added (the accumulator plus the single bottom RAISE handle delivery). Downstream, per bigquery/79: severity=critical for this category now folds into state.trading_enabled blocking_criticals (bigquery/78), so a real future formula clobber auto-halts new order-staging. No other check logic changed.', 24),
    STRUCT('integrity_check', 'v2', 'v2 -- body moved into ops.sp_sq_integrity_check wrapper (bigquery/75_scheduled_query_wrappers.sql), ARCH-1 2026-07-16', 24),
    STRUCT('safety_critical_dml_watch', 'v4', 'v2 -- body moved into ops.sp_sq_safety_critical_dml_watch wrapper (bigquery/75_scheduled_query_wrappers.sql), ARCH-1 2026-07-16. v3, 2026-07-17 (MON H4) -- INSERT-aware extension: flags INSERT on ops.trading_control / ops.arsenal_control / events.strategy_lifecycle (warning), CRITICAL on a spoofed manual halt-clear or an unknown-code lifecycle add. v4, 2026-07-20 -- control_plane_insert re-raise-noise fix: WARNING-tier check now uses a per-target-table watermark (last raised-or-resolved alert for that table) instead of a flat 24h EXISTS, so resolving an alert no longer triggers a byte-identical re-raise every 6h and a genuinely second same-day insert to the same table is no longer swallowed; the 3 CRITICAL conditions are unchanged', 6),
    STRUCT('daily_staging_cap_check', 'v4', 'v2 -- body moved into ops.sp_sq_daily_staging_cap_check wrapper (bigquery/75_scheduled_query_wrappers.sql), ARCH-1 2026-07-16. v3, 2026-07-17 (DEF-3) -- added the order_guard_verdict_mismatch recompute backstop. v4, 2026-07-26 (owner directive) -- daily order-count/notional cap retired; dropped the daily_cap_breach IF block (bigquery/109_retire_daily_staging_cap.sql)', 24),
    STRUCT('backup_events_export', 'v2', 'v2 -- body moved into ops.sp_sq_backup_events_export wrapper (bigquery/75_scheduled_query_wrappers.sql), ARCH-1 2026-07-16', 24),
    STRUCT('ops_export', 'v2', 'v2 -- body moved into ops.sp_sq_ops_export wrapper (bigquery/75_scheduled_query_wrappers.sql), ARCH-1 2026-07-16', 24),
    STRUCT('delivery_canary', 'v2', 'v2 -- body moved into ops.sp_sq_delivery_canary wrapper (bigquery/75_scheduled_query_wrappers.sql), ARCH-1 2026-07-16', 168),
    STRUCT('restore_drill', 'v2', 'v2 -- body moved into ops.sp_sq_restore_drill wrapper (bigquery/75_scheduled_query_wrappers.sql), ARCH-1 2026-07-16', 744),
    STRUCT('fire_drill_order_guard', 'v2', 'v2 -- body moved into ops.sp_sq_fire_drill_order_guard wrapper (bigquery/75_scheduled_query_wrappers.sql), ARCH-1 2026-07-16', 744),
    STRUCT('fire_drill_alert_lifecycle', 'v3', 'v2 -- body moved into ops.sp_sq_fire_drill_alert_lifecycle wrapper (bigquery/75_scheduled_query_wrappers.sql), ARCH-1 2026-07-16. v3, 2026-08-04 (bigquery/134_roster_change_notifications.sql, owner directive on roster-change email notifications) -- adds a third drill, ops.sp_fire_drill_roster_notice, which proves the roster-change notice auto-resolves on delivery and, critically, stays open while undelivered. No other drill logic changed.', 744)
  ])
) S
ON T.sq_name = S.sq_name
-- WHEN MATCHED is unconditional so expected_interval_hours always syncs, but updated_ts is bumped ONLY on
-- a real version change (IF guard) — the never_beat_overdue dead-man keys on updated_ts as its 7-day
-- registry grace clock, and re-applying this file (or only an interval edit) must NOT reset that clock.
WHEN MATCHED THEN
  UPDATE SET expected_version = S.expected_version, git_note = S.git_note,
             expected_interval_hours = S.expected_interval_hours,
             updated_ts = IF(T.expected_version != S.expected_version, CURRENT_TIMESTAMP(), T.updated_ts)
WHEN NOT MATCHED THEN
  INSERT (sq_name, expected_version, git_note, expected_interval_hours)
  VALUES (S.sq_name, S.expected_version, S.git_note, S.expected_interval_hours);

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
  e.expected_interval_hours,
  lb.last_reported_version,
  lb.last_beat_ts,
  COALESCE(lb.ever_reported_version, FALSE) AS monitored,
  COALESCE(lb.ever_reported_version, FALSE)
    AND (lb.last_reported_version IS NULL
         OR TRIM(lb.last_reported_version) = ''
         OR lb.last_reported_version != e.expected_version) AS drift,
  -- MON H5 (2026-07-17) beat-AGE dead-man. GRACE_FACTOR = 1.5 (a daily query tolerates one missed run
  -- before flagging; weekly ~10.5d; monthly ~46d — the monthly restore_drill is additionally covered by
  -- restore_stale's own >40d critical, so a generous grace here just avoids false fires on the backstop).
  --   * stale_beat: a query that HAS beaten (monitored) but whose last beat is older than interval x grace
  --     — it was running and silently stopped. NULL expected_interval_hours (unseeded) can never fire.
  (COALESCE(lb.ever_reported_version, FALSE)
   AND e.expected_interval_hours IS NOT NULL
   AND lb.last_beat_ts < TIMESTAMP_SUB(CURRENT_TIMESTAMP(),
                                       INTERVAL CAST(e.expected_interval_hours * 1.5 AS INT64) HOUR)) AS stale_beat,
  --   * never_beat_overdue: a query registered (updated_ts) more than its own cadence-scaled grace ago
  --     that has NEVER beaten — the self-bootstrapping grace so a freshly-registered query stays quiet
  --     until it has had a real chance to fire at least once (matching the state.script_version_drift /
  --     automation_heartbeat convention: no alarm until first beat unless the never-beat state itself
  --     persists past the grace window). FIXED (2026-07-25): this used to be a flat 7 days regardless of
  --     cadence, same GRACE_FACTOR=1.5 scaling as stale_beat above -- but for a MONTHLY query (interval
  --     744h) that flat floor fires every night for ~24 days after registration despite the query never
  --     having had a chance to run yet (verified live: fire_drill_order_guard / restore_drill both
  --     registered 2026-07-17, both monthly-1st-of-month, both correctly never-beaten-yet, both wrongly
  --     flagged never_beat_overdue starting 2026-07-24 -- the scheduled_query_stale alert this fix
  --     resolves). Now GREATEST(7 days, interval_hours * 1.5) -- daily/weekly queries keep effectively the
  --     same (or the already-more-correct stale_beat-matching) grace; a monthly query gets ~46.5 days,
  --     comfortably past its next real firing before ever alarming.
  (NOT COALESCE(lb.ever_reported_version, FALSE)
   AND e.updated_ts < TIMESTAMP_SUB(CURRENT_TIMESTAMP(),
       INTERVAL CAST(GREATEST(7 * 24, COALESCE(e.expected_interval_hours, 0) * 1.5) AS INT64) HOUR)) AS never_beat_overdue,
  CURRENT_TIMESTAMP() AS checked_at
FROM `stock-trading-498512.state.expected_scheduled_query_versions` e
LEFT JOIN latest_beat lb ON lb.sq_name = e.sq_name;

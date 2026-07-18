-- b3_trading_enabled_drift monitor-promotion readiness (MON M2, 2026-07-17 whole-system deep audit).
-- Project: stock-trading-498512. Closes CONFIRMED GAP `b3-drift-no-promotion-path`:
-- bigquery/64_b3_live_invariants.sql's own header promised state.b3_trading_enabled_check would be
-- "promote[d] to critical+RAISE via the existing D3 MONITOR-PROMOTION SELF-FLIP mechanism
-- (bigquery/45_monitor_promotion.sql) once a clean baseline is confirmed, same as
-- ddl_drift/restore_stale/append_only_integrity" — but nothing ever wrote b3 history to
-- ops.monitor_health_history and no readiness view existed, so the promise was unreachable (verified
-- live 2026-07-17: ops.monitor_health_history has ZERO check_id='b3_trading_enabled_drift' rows).
-- This file gives b3 the SAME self-flip substrate ITEM 24/31 already built and proved for
-- ddl_drift/restore_stale/append_only_integrity — it does not invent a new pattern.
--
-- Apply AFTER bigquery/45_monitor_promotion.sql (reuses its ops.monitor_health_history /
-- ops.monitor_promotion_log tables verbatim — no new table DDL here), AFTER
-- bigquery/64_b3_live_invariants.sql (state.b3_trading_enabled_check — REDEFINED by
-- bigquery/78_book_drawdown_rebase_and_staleness_gate.sql; apply 78 first too), and paired with the
-- v5->v6 edit to ops.sp_sq_cadence_check (bigquery/75_scheduled_query_wrappers.sql) that adds the
-- unconditional per-run history MERGE this readiness view depends on. Idempotent (ALTER ... SET OPTIONS /
-- CREATE OR REPLACE VIEW); safe to re-run.
--
-- NO BACKFILL, by deliberate design (matching ITEM 24/31's precedent): history starts accumulating the
-- day the cadence_check v6 body goes live (via the BigQuery MCP apply of bigquery/75). state.b3_trading_
-- enabled_check is a today-only live view (no history of its own), so there is no way to mechanically
-- reconstruct a trustworthy prior daily history; promotion is real-time-only and fail-closed until 14
-- FRESH logged days accumulate — the same wait every other staged-rollout monitor in this codebase serves.
--
-- WHERE THE PROMOTION TARGET LIVES: unlike append_only_integrity (bigquery/57 — its own separate
-- integrity_check.sql query with no raise_msg accumulator), b3_trading_enabled_drift lives INSIDE
-- ops.sp_sq_cadence_check, which already has the consolidated `raise_msg` STRING accumulator every
-- CRITICAL-tier check appends to before one final `RAISE USING MESSAGE = ...`. So it promotes exactly
-- like ddl_drift/restore_stale: when state.b3_promotion_readiness.ready flips TRUE, D3's MONITOR-PROMOTION
-- SELF-FLIP step (Claude_Task_Plan.md) edits the b3 IF block in bigquery/75 to (a) flip the
-- sp_raise_alert_once severity literal 'warning' -> 'critical', AND (b) append to raise_msg — it does NOT
-- add a standalone RAISE (the accumulator + the file's single bottom RAISE handle delivery). It must also
-- write the ops.monitor_promotion_log idempotency row (check_id='b3_trading_enabled_drift'). The exact
-- promoted b3 IF block (so D3 copies it verbatim, mirroring the restore_stale RECORD-then-accumulate
-- pattern already in this same file) is:
--
--   IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.b3_trading_enabled_check` WHERE drift) THEN
--     CALL `stock-trading-498512.ops.sp_raise_alert_once`(
--       'critical', 'scheduled.cadence', 'b3_trading_enabled_drift',
--       (SELECT CONCAT('state.trading_enabled formula drift: live=', CAST(live_value AS STRING),
--                      ' but independently-recomputed expected=', CAST(expected_value AS STRING),
--                      ' -- a gate AND-term may have been silently clobbered (see bigquery/47_trading_enabled_resync.sql)')
--        FROM `stock-trading-498512.state.b3_trading_enabled_check`),
--       (SELECT TO_JSON_STRING(t) FROM `stock-trading-498512.state.b3_trading_enabled_check` t));
--     SET raise_msg = raise_msg || (SELECT CONCAT('[b3_trading_enabled_drift] live=', CAST(live_value AS STRING),
--       ' expected=', CAST(expected_value AS STRING), '; ') FROM `stock-trading-498512.state.b3_trading_enabled_check`);
--   END IF;
--
-- Once promoted, this alert's severity='critical' + category='b3_trading_enabled_drift' (NOT IN
-- ('trading_halted','staleness')) automatically folds into state.trading_enabled's blocking_criticals
-- (bigquery/78) — a real future formula clobber then auto-halts new order-staging the same way every
-- other critical alert already does, with zero further wiring required.

-- ============================================================================
-- Doc-only: extend ops.monitor_health_history.check_id's description to name the fourth value this file
-- adds. No structural change (the column is a bare STRING with no CHECK constraint) — purely keeps
-- bigquery/45/57's inline column comment from reading as stale/incomplete.
-- ============================================================================
ALTER TABLE `stock-trading-498512.ops.monitor_health_history`
  ALTER COLUMN check_id SET OPTIONS (description = "'ddl_drift' | 'restore_stale' | 'append_only_integrity' | 'b3_trading_enabled_drift'");

-- ============================================================================
-- state.b3_promotion_readiness — ready once 14 consecutive DISTINCT logged days are clean (IDENTICAL bar
-- to state.ddl_drift_promotion_readiness / state.append_only_integrity_promotion_readiness) AND not
-- already promoted. Fail-closed: fewer than 14 logged days, or any non-clean day in the trailing 14,
-- reads FALSE. Depends on ops.sp_sq_cadence_check's v6 body actually writing the b3 history MERGE — until
-- that apply lands live, this reads n_recent=0 / ready=FALSE forever, the correct fail-closed default.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.b3_promotion_readiness` AS
WITH by_day AS (
  -- Dedupe to ONE row per check_date before ranking (same defensive rationale as the ddl_drift /
  -- append_only_integrity readiness views — a day counts clean only if EVERY logged row that day was
  -- clean, so a same-day duplicate can never promote a day early).
  SELECT check_date, LOGICAL_AND(clean) AS clean
  FROM `stock-trading-498512.ops.monitor_health_history`
  WHERE check_id = 'b3_trading_enabled_drift'
  GROUP BY check_date
),
ranked AS (
  SELECT check_date, clean,
    ROW_NUMBER() OVER (ORDER BY check_date DESC) AS rn
  FROM by_day
),
trailing14 AS (
  SELECT COUNT(*) AS n_recent, COUNTIF(clean) AS n_recent_clean
  FROM ranked WHERE rn <= 14
)
SELECT
  t.n_recent, t.n_recent_clean,
  (t.n_recent >= 14 AND t.n_recent_clean = 14) AS baseline_met,
  NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.monitor_promotion_log` pl WHERE pl.check_id = 'b3_trading_enabled_drift') AS not_already_promoted,
  (t.n_recent >= 14 AND t.n_recent_clean = 14
   AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.monitor_promotion_log` pl WHERE pl.check_id = 'b3_trading_enabled_drift')) AS ready
FROM trailing14 t;

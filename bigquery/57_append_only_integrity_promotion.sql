-- Append-only-integrity monitor-promotion readiness (self-improvement audit ITEM 31, 2026-07-15).
-- Project: stock-trading-498512. Closes CONFIRMED GAP `append-only-integrity-no-promotion`:
-- state.append_only_integrity / integrity_check.sql has been stuck at record-only WARNING (no RAISE,
-- no self-halt) since it was built 2026-06-24, and — unlike its structurally identical siblings
-- ddl_drift and restore_stale, which got an automated WARNING->CRITICAL self-flip promotion path in
-- bigquery/45_monitor_promotion.sql (ITEM 24, 2026-07-11) — it was never wired into that mechanism.
-- state.append_only_integrity is NOT read by state.trading_enabled at all (unlike
-- state.position_reconciliation, which auto-halts trading on drift), so a genuine unauthorized
-- UPDATE/DELETE/MERGE/TRUNCATE on the immutable events.* audit trail today produces only a dismissible
-- WARNING email, with no path to a halt/escalation ever, even after a long clean run proves the
-- detector trustworthy. This file gives it the SAME self-flip substrate ITEM 24 already built and
-- proved for ddl_drift/restore_stale — it does not invent a new pattern.
--
-- Apply AFTER bigquery/45_monitor_promotion.sql (reuses its ops.monitor_health_history /
-- ops.monitor_promotion_log tables verbatim — no new table DDL here) and AFTER
-- bigquery/18_stack_review_fixes.sql (state.append_only_integrity). Then re-paste the updated
-- bigquery/scheduled_queries/integrity_check.sql (adds the unconditional per-run history write this
-- readiness view depends on; the WARNING-only alerting behavior is UNCHANGED by that re-paste — see
-- that file's own header). Idempotent (ALTER ... SET OPTIONS / CREATE OR REPLACE VIEW); safe to re-run.
--
-- NO BACKFILL, by deliberate design (matching ITEM 24's own precedent for ddl_drift/restore_stale):
-- history starts accumulating the day integrity_check.sql's edited body goes live via console re-paste,
-- not before. state.append_only_integrity's own live view only ever looks back 2 days, so there is no
-- way to mechanically reconstruct a trustworthy PRIOR daily history from it; the pre-2026-07-15
-- "baseline verified clean" note (RUNBOOK §25 B3, a one-time manual check) does NOT count toward the
-- 14-day bar below. Promotion is therefore real-time-only and fail-closed until 14 FRESH logged days
-- accumulate post-re-paste — the same wait every other staged-rollout monitor in this codebase serves.
--
-- WHY THE PROMOTION TARGET DIFFERS FROM ddl_drift/restore_stale: those two live inside
-- bigquery/scheduled_queries/cadence_check.sql, which already has a consolidated `raise_msg` STRING
-- accumulator that every CRITICAL-tier check appends to before one final `RAISE USING MESSAGE = raise_msg`
-- at the bottom of the file. append_only_integrity lives in its OWN separate scheduled query,
-- integrity_check.sql (different file, different IAM grant — see that file's header), which has NO
-- raise_msg accumulator of its own and, being WARNING-only today, currently has NO RAISE statement at
-- all. So when state.append_only_integrity_promotion_readiness.ready flips to TRUE, D3's
-- MONITOR-PROMOTION SELF-FLIP step (Claude_Task_Plan.md) must (a) flip integrity_check.sql's
-- `sp_raise_alert_once` call's severity literal 'warning' -> 'critical', AND (b) ADD a new, direct
-- `RAISE USING MESSAGE = ...` statement right after that call, inside the same `IF EXISTS (...) THEN
-- ... END IF;` block — it does NOT touch cadence_check.sql at all for this check_id. The exact promoted
-- body of integrity_check.sql (so D3 copies it verbatim instead of freewriting the RAISE message,
-- mirroring bigquery/scheduled_queries/safety_critical_dml_watch.sql's RAISE-after-alert pattern, the
-- closest existing single-condition analog) is:
--
--   BEGIN
--     MERGE `stock-trading-498512.ops.monitor_health_history` T
--     USING (
--       SELECT 'append_only_integrity' AS check_id, CURRENT_DATE('America/Denver') AS check_date,
--              NOT EXISTS (SELECT 1 FROM `stock-trading-498512.state.append_only_integrity`) AS clean
--     ) S
--     ON T.check_id = S.check_id AND T.check_date = S.check_date
--     WHEN MATCHED THEN
--       UPDATE SET clean = S.clean, logged_ts = CURRENT_TIMESTAMP()
--     WHEN NOT MATCHED THEN
--       INSERT (check_id, check_date, clean) VALUES (S.check_id, S.check_date, S.clean);
--
--     IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.append_only_integrity`) THEN
--       CALL `stock-trading-498512.ops.sp_raise_alert_once`(
--         'critical', 'scheduled.integrity', 'append_only_violation',
--         CONCAT('Append-only integrity: out-of-band UPDATE/DELETE/MERGE on immutable events.* table(s): ',
--                (SELECT STRING_AGG(DISTINCT CONCAT(statement_type, ' ', target_table), ', ' ORDER BY CONCAT(statement_type, ' ', target_table))
--                 FROM `stock-trading-498512.state.append_only_integrity`)),
--         (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(job_id, user_email, statement_type, target_table, query_preview)))
--          FROM `stock-trading-498512.state.append_only_integrity`));
--       RAISE USING MESSAGE = CONCAT(
--         'STOCK-TRADING append-only integrity check FAILED — out-of-band UPDATE/DELETE/MERGE on immutable events.* table(s): ',
--         (SELECT STRING_AGG(DISTINCT CONCAT(statement_type, ' ', target_table), ', ' ORDER BY CONCAT(statement_type, ' ', target_table))
--          FROM `stock-trading-498512.state.append_only_integrity`),
--         '. See ops.alerts (category=append_only_violation) for job_id/user_email detail.');
--     END IF;
--   END;
--
-- Once promoted, this alert's severity='critical' + category='append_only_violation' (!=
-- 'trading_halted') automatically folds into state.trading_enabled's blocking_criticals count
-- (bigquery/47_trading_enabled_resync.sql) — a real future violation then auto-halts new order-staging
-- the same way every other critical alert already does, with zero further wiring required.

-- ============================================================================
-- Doc-only: extend ops.monitor_health_history.check_id's description to name the third value this file
-- adds. No structural change (the column is already a bare STRING with no CHECK constraint) — purely
-- keeps bigquery/45_monitor_promotion.sql's inline column comment from reading as stale/incomplete.
-- ============================================================================
ALTER TABLE `stock-trading-498512.ops.monitor_health_history`
  ALTER COLUMN check_id SET OPTIONS (description = "'ddl_drift' | 'restore_stale' | 'append_only_integrity'");

-- ============================================================================
-- state.append_only_integrity_promotion_readiness — ready once 14 consecutive DISTINCT logged days are
-- clean (IDENTICAL bar to state.ddl_drift_promotion_readiness — RUNBOOK §25/§27 has always described
-- append_only_integrity and ddl_drift as sharing the same staged-rollout posture) AND not already
-- promoted. Fail-closed: fewer than 14 logged days, or any non-clean day in the trailing 14, reads
-- FALSE. Depends on bigquery/scheduled_queries/integrity_check.sql's re-pasted body (see header above)
-- actually writing to ops.monitor_health_history — until that re-paste lands live, this view reads
-- n_recent=0 / ready=FALSE forever, which is the correct fail-closed default, not a bug.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.append_only_integrity_promotion_readiness` AS
WITH by_day AS (
  -- Dedupe to ONE row per check_date before ranking (same defensive rationale as
  -- state.ddl_drift_promotion_readiness — a day counts clean only if EVERY logged row that day was
  -- clean, so a same-day duplicate can never promote a day early).
  SELECT check_date, LOGICAL_AND(clean) AS clean
  FROM `stock-trading-498512.ops.monitor_health_history`
  WHERE check_id = 'append_only_integrity'
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
  NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.monitor_promotion_log` pl WHERE pl.check_id = 'append_only_integrity') AS not_already_promoted,
  (t.n_recent >= 14 AND t.n_recent_clean = 14
   AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.monitor_promotion_log` pl WHERE pl.check_id = 'append_only_integrity')) AS ready
FROM trailing14 t;

-- append_only_integrity monitor promotion: WARNING -> CRITICAL (+RAISE). SQ_VERSION v4.
-- Project: stock-trading-498512. Written by D3's MONITOR-PROMOTION SELF-FLIP step
-- (Claude_Task_Plan.md, self-improvement audit ITEM 24 / ITEM 31) on 2026-08-19.
--
-- WHY NOW. state.append_only_integrity_promotion_readiness
-- (bigquery/57_append_only_integrity_promotion.sql) flipped `ready = TRUE`, MEASURED live
-- 2026-08-19: n_recent = 14, n_recent_clean = 14, baseline_met = TRUE, not_already_promoted = TRUE.
-- That is the same 14-consecutive-clean-logged-day bar ddl_drift (bigquery/45, promoted 2026-07-26)
-- and b3_trading_enabled_drift (bigquery/128, promoted 2026-08-03) each cleared before their own
-- self-flip. ops.monitor_promotion_log carried no `append_only_integrity` row before this change,
-- and carries one after it, so `not_already_promoted` is now FALSE and this promotion can never
-- re-fire.
--
-- WHAT CHANGED -- EXACTLY THREE string replacements, generated programmatically against the live/
-- repo-canonical v3 body in bigquery/141_append_only_halt_scope.sql (verified byte-identical to
-- INFORMATION_SCHEMA.ROUTINES before the edit), NOT retyped -- the same discipline bigquery/128 and
-- bigquery/157 record for their own bodies:
--   1. heartbeat literal 'v3' -> 'v4' (paired with the bigquery/63 registry row in this same commit;
--      scripts/check_sq_version_registry.py enforces that pairing).
--   2. the MERGE's trailing comment, which asserted the body was "still WARNING-only below, no RAISE,
--      until D3's MONITOR-PROMOTION SELF-FLIP later promotes it" -- true until this file, false after
--      it. No code in the MERGE changed; the MERGE still logs every run, pass or fail.
--   3. the single unpromoted WARNING `IF EXISTS` block, replaced by the promoted two-block body
--      COPIED VERBATIM from bigquery/57's header spec (the "do not freewrite the RAISE message"
--      rule in Claude_Task_Plan.md's D3 step). No check logic, threshold or population changed
--      beyond the tier flip the promotion IS.
--
-- WHAT THE PROMOTED BODY DOES. The two blocks partition the same population the single v3 block
-- covered, and the order between them is load-bearing (see the inline comment):
--   * NON-HALTING companion, WARNING, evaluated FIRST: statement_type='UPDATE' AND
--     target_table='adversarial_reviews' -- the historical bb21c91 sanctioned-repair class. WARNING
--     severity never contributes to state.trading_enabled's blocking_criticals, so it can never halt.
--   * HALTING block, CRITICAL + RAISE, over state.append_only_integrity_haltable (bigquery/141) --
--     the mutually exclusive complement. severity='critical' with category='append_only_violation'
--     folds into state.trading_enabled's blocking_criticals (bigquery/78 via bigquery/47), so a real
--     out-of-band UPDATE/DELETE/MERGE/TRUNCATE on any of the other seven audit-truth events.* tables
--     -- or a DELETE/MERGE/TRUNCATE on adversarial_reviews -- now auto-halts NEW order-staging
--     instead of producing a dismissible warning email. That halt is the entire point of the
--     promotion, and it is why the 14-clean-day bar exists.
--
-- SAFE TO PROMOTE TODAY, MEASURED not assumed: both state.append_only_integrity and
-- state.append_only_integrity_haltable returned 0 rows at write time, so applying this body does not
-- raise a critical (and does not halt trading) on its first run. A promotion applied over a dirty
-- population would halt trading the same evening; that check is not optional.
--
-- SUPERSESSION. This file is the NEW single source of truth for ops.sp_sq_integrity_check,
-- SUPERSEDING bigquery/141_append_only_halt_scope.sql (v3), which itself superseded
-- bigquery/75_scheduled_query_wrappers.sql (v2). The chain is 75 -> 141 -> 185. Per bigquery/111's
-- standing rule, the edit lands as a NEW numbered file rather than in place, and BOTH superseded
-- copies' markers are repointed here in this same commit or
-- scripts/check_superseded_markers.py fails the build. bigquery/141's OTHER object
-- (state.append_only_integrity_haltable) is untouched and stays canonical there.
--
-- NOT CHANGED BY THIS FILE, deliberately: the haltable carve-out itself. bigquery/141's
-- "PREMISE SUPERSEDED" block retires the carve-out (and the haltable view with it) only after 14
-- consecutive UPDATE-free days on events.adversarial_reviews, and that retirement is a separate
-- change on its own clock. Promoting the tier while the carve-out still stands is strictly
-- conservative: the carve-out can only ever REDUCE what halts, never cause a halt.
--
-- APPLY ORDER: after bigquery/57 (readiness view), bigquery/75 (original wrapper), bigquery/141
-- (haltable view + v3 body). Apply this procedure TOGETHER WITH the bigquery/63 registry bump to v4,
-- or the procedure first -- applying only the registry row sets expected_version='v4' while a live v3
-- procedure keeps beating 'v3', raising a nightly scheduled_query_version_drift warning until the
-- pair is reconciled (the partial-apply trap bigquery/63's own git_note documents throughout).
-- APPLIED LIVE in the same D3 session that wrote this file, via the BigQuery MCP, and verified
-- against INFORMATION_SCHEMA.ROUTINES.
--
-- The console body for this scheduled query is the frozen one-line `CALL ops.sp_sq_integrity_check()`
-- wrapper (bigquery/README.md ARCH-1), so there is no owner re-paste step in this path at all.
-- Idempotent (CREATE OR REPLACE PROCEDURE); safe to re-run.

CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_sq_integrity_check`()
BEGIN
  CALL `stock-trading-498512.ops.sp_beat_heartbeat`('sq:integrity_check', 'v4', 'integrity_check.sql ran');

  -- MONITOR-PROMOTION HISTORY (self-improvement audit ITEM 31, 2026-07-15; SCOPED 2026-08-06 -- see
  -- this file's header). Logged UNCONDITIONALLY (pass or fail) every run, mirroring cadence_check.sql's
  -- ddl_drift/restore_stale MERGE-upsert pattern (bigquery/45_monitor_promotion.sql, ITEM 24) --
  -- state.append_only_integrity_promotion_readiness (bigquery/57_append_only_integrity_promotion.sql)
  -- needs this history to evaluate "14 consecutive clean logged days", which state.append_only_
  -- integrity (a today-only, 2-day-lookback snapshot) cannot provide on its own. PROMOTED 2026-08-19
  -- (this file): D3's MONITOR-PROMOTION SELF-FLIP fired after state.append_only_integrity_promotion_
  -- readiness.ready flipped TRUE, so the alerting body below is no longer WARNING-only -- it is the
  -- promoted CRITICAL+RAISE form copied verbatim from bigquery/57's header spec. The MERGE itself is
  -- unchanged and keeps logging every run, pass or fail.
  --
  -- SCOPE CHANGE (bigquery/141, 2026-08-06): `clean` now reads state.append_only_integrity_haltable, NOT
  -- the full state.append_only_integrity, so the promotion clock is measured over exactly the
  -- population the promotion governs -- see file header. NO BACKFILL: existing rows logged under the
  -- old, unscoped `clean` definition are left as-is (conservative -- only delays arming, never falsely
  -- advances it). MERGE, not INSERT, so a same-day re-run never double-logs one day (same rationale as
  -- cadence_check.sql's 2026-07-11 adversarial-self-audit fix).
  MERGE `stock-trading-498512.ops.monitor_health_history` T
  USING (
    SELECT 'append_only_integrity' AS check_id, CURRENT_DATE('America/Denver') AS check_date,
           NOT EXISTS (SELECT 1 FROM `stock-trading-498512.state.append_only_integrity_haltable`) AS clean
  ) S
  ON T.check_id = S.check_id AND T.check_date = S.check_date
  WHEN MATCHED THEN
    UPDATE SET clean = S.clean, logged_ts = CURRENT_TIMESTAMP()
  WHEN NOT MATCHED THEN
    INSERT (check_id, check_date, clean) VALUES (S.check_id, S.check_date, S.clean);

  -- Non-halting companion (bigquery/141, 2026-08-06): the ONE sanctioned exception (bb21c91) —
  -- an in-place UPDATE on events.adversarial_reviews — still surfaces as a record after
  -- promotion, on the MUTUALLY EXCLUSIVE complement of the CRITICAL block below. WARNING severity
  -- never contributes to state.trading_enabled's blocking_criticals, so this can never halt trading.
  --
  -- ORDER IS LOAD-BEARING — THIS BLOCK MUST STAY ABOVE THE CRITICAL BLOCK. The CRITICAL block ends
  -- in an uncaught RAISE, which aborts the whole procedure immediately. Placed after it, this
  -- companion would be DEAD CODE on exactly the runs where both populations are non-empty: a real
  -- violation on a watched table would suppress the record of a concurrent sanctioned review repair,
  -- so the one alert an operator needs in order to tell the two apart would be the one never written.
  -- Both populations are evaluated BEFORE anything can RAISE. (Caught in adversarial review of
  -- bigquery/141, 2026-08-06, when this companion was first drafted below the CRITICAL block.)
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.append_only_integrity`
             WHERE statement_type = 'UPDATE' AND target_table = 'adversarial_reviews') THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.integrity', 'append_only_violation',
      CONCAT('Append-only integrity (sanctioned review-repair class, non-halting): in-place UPDATE on events.adversarial_reviews: ',
             (SELECT STRING_AGG(DISTINCT CONCAT(statement_type, ' ', target_table), ', ' ORDER BY CONCAT(statement_type, ' ', target_table))
              FROM `stock-trading-498512.state.append_only_integrity`
              WHERE statement_type = 'UPDATE' AND target_table = 'adversarial_reviews')),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(job_id, user_email, statement_type, target_table, query_preview)))
       FROM `stock-trading-498512.state.append_only_integrity`
       WHERE statement_type = 'UPDATE' AND target_table = 'adversarial_reviews'));
  END IF;

  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.append_only_integrity_haltable`) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.integrity', 'append_only_violation',
      CONCAT('Append-only integrity: out-of-band UPDATE/DELETE/MERGE on immutable events.* table(s): ',
             (SELECT STRING_AGG(DISTINCT CONCAT(statement_type, ' ', target_table), ', ' ORDER BY CONCAT(statement_type, ' ', target_table))
              FROM `stock-trading-498512.state.append_only_integrity_haltable`)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(job_id, user_email, statement_type, target_table, query_preview)))
       FROM `stock-trading-498512.state.append_only_integrity_haltable`));
    RAISE USING MESSAGE = CONCAT(
      'STOCK-TRADING append-only integrity check FAILED — out-of-band UPDATE/DELETE/MERGE on immutable events.* table(s): ',
      (SELECT STRING_AGG(DISTINCT CONCAT(statement_type, ' ', target_table), ', ' ORDER BY CONCAT(statement_type, ' ', target_table))
       FROM `stock-trading-498512.state.append_only_integrity_haltable`),
      '. See ops.alerts (category=append_only_violation) for job_id/user_email detail.');
  END IF;
END;

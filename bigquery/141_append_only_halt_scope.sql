-- 141_append_only_halt_scope.sql (2026-08-06)
-- Project: stock-trading-498512. Scope the append_only_integrity HALT (once promoted) to the
-- population the promotion should actually govern; keep the WARNING universal and unchanged.
-- Apply after 57_append_only_integrity_promotion.sql, 63_scheduled_query_version_registry.sql,
-- 75_scheduled_query_wrappers.sql, 139_append_only_violation_alert_class.sql.
--
-- ============================ WHY (2026-08-06 alert-triage follow-up) ============================
-- bigquery/57_append_only_integrity_promotion.sql wires state.append_only_integrity (bigquery/
-- 18_stack_review_fixes.sql) into D3's autonomous MONITOR-PROMOTION SELF-FLIP: once promoted,
-- severity='critical' on category='append_only_violation' folds into state.trading_enabled's
-- blocking_criticals (bigquery/47_trading_enabled_resync.sql) and auto-halts new order-staging.
-- 57's own header lays out the exact BEGIN...END body D3 copies verbatim on promotion.
--
-- Commit bb21c91 (2026-08-05) separately established that an in-place UPDATE on
-- events.adversarial_reviews, keyed on (review_id, role, review_date), is the ONE SANCTIONED
-- correction mechanism for that table -- it has no superseded_by column, and
-- ops.sp_score_cross_model_referee filters role='attacker' with no dedup across rows, so a
-- superseding row would insert duplicate referee_gemini rows (see ops.alert_policy's
-- append_only_violation row, bigquery/139_append_only_violation_alert_class.sql, and
-- Claude_Task_Plan.md's shared-preamble section titled "Writing long markdown into a BigQuery
-- column").
--
-- So the promoted form as originally written would convert a SANCTIONED, EXPECTED repair into a
-- trading halt. It is not armed today (state.append_only_integrity_promotion_readiness read
-- n_recent=14, n_recent_clean=10, ready=false as of this triage) but arms on the first quiet
-- 14-day stretch, and a review-repair UPDATE recurs on an ordinary cadence (precedent pairs:
-- 4353777f then afdc096d; 58da7e8f then 94ce1df2; 9c7c0261) -- so the gap was real and
-- time-bounded, not hypothetical.
--
-- ============================ THE FIX: scope the HALT by table, keep the WARNING universal ========
-- state.append_only_integrity_haltable (new view, this file) is state.append_only_integrity MINUS
-- ONLY rows where statement_type='UPDATE' AND target_table='adversarial_reviews'. The exclusion is
-- DELIBERATELY NARROW and gated on statement_type: only the UPDATE on adversarial_reviews is
-- blessed. A DELETE / MERGE / TRUNCATE_TABLE on adversarial_reviews is NEVER sanctioned and MUST
-- remain halt-eligible -- this view does not exempt the table, only that one statement shape. No
-- query-text heuristic is used: a JOBS_BY_PROJECT-metadata view cannot verify row CONTENT (so it
-- cannot tell a sanctioned repair from a malicious one by text alone), and a body_md-only carve-out
-- would exempt the column that carries the entire review narrative -- the exact content a malicious
-- or buggy UPDATE would most likely target.
--
-- ops.sp_sq_integrity_check is re-created at SQ_VERSION v3 (superseding bigquery/75_scheduled_
-- query_wrappers.sql:719's v2 definition) with exactly two changes from the v2 body, copied
-- verbatim otherwise: (1) the heartbeat literal 'v2' -> 'v3'; (2) the monitor_health_history
-- MERGE's `clean` expression now reads state.append_only_integrity_haltable instead of the full
-- view. The WARNING `IF EXISTS (...) THEN sp_raise_alert_once('warning', ...)` block at the bottom
-- is UNCHANGED and still reads the FULL state.append_only_integrity -- today's alerting behaviour
-- does not change at all. Only the promotion CLOCK narrows: the 14-consecutive-clean-day bar
-- bigquery/57's readiness view evaluates must be measured over exactly the population the
-- promotion governs, or a sanctioned adversarial_reviews repair would permanently prevent the
-- other seven audit-truth tables (decision_log, position_events, trade_fills, regime_events,
-- queue_events, parking_events, hf_capability_captures) from ever gaining halt teeth -- one
-- recurring, sanctioned event on one table should never be able to veto promotion for the whole
-- monitor.
--
-- bigquery/57's commented-out promoted-body spec is updated in place (same file, not a new one --
-- that block is documentation D3 copies verbatim at promotion time, not a live object) to match:
-- the CRITICAL block now reads the HALTABLE view, and a second, non-halting WARNING block is added
-- so a sanctioned review repair still surfaces as a record after promotion, over the MUTUALLY
-- EXCLUSIVE complement population (statement_type='UPDATE' AND target_table='adversarial_reviews').
-- Both blocks share category='append_only_violation' (already registered in ops.alert_policy,
-- bigquery/139) but carry distinct message text, so ops.sp_raise_alert_once's exact (category,
-- message) dedup lets the two raise independently instead of colliding.
--
-- NO BACKFILL of ops.monitor_health_history, matching bigquery/57's own stated no-backfill design
-- for this monitor: existing check_id='append_only_integrity' rows logged under the OLD (unscoped)
-- `clean` definition stay exactly as logged. This is conservative and fail-closed, not a bug -- a
-- historically-dirty day computed against the wider population can only ever make `ready` arm
-- LATER than the narrower definition would have on its own, never earlier and never falsely clean.
-- Promotion readiness accrues a true 14-fresh-day count starting from this file's first live run,
-- exactly as bigquery/57 already documents for the original append_only_integrity rollout.
--
-- ============================ APPLY-ORDER WARNING (read before applying) ==========================
-- The bigquery/63 registry MERGE and this file's ops.sp_sq_integrity_check procedure MUST be
-- applied LIVE TOGETHER, or the procedure FIRST. Applying the bigquery/63 MERGE alone sets
-- expected_version='v3' in state.expected_scheduled_query_versions while the live procedure still
-- reports 'v2' on its next beat, which raises a scheduled_query_version_drift WARNING that CANNOT
-- auto-resolve -- that category has no ops.alert_policy row, so a manual UPDATE ops.alerts is the
-- only way to close it. This is EXACTLY the bug fixed for daily_staging_cap_check earlier in this
-- same session (commit 0b9fd49's registry lag, repaired via bigquery/63's own git_note) -- do not
-- repeat it here. If only one of the two can land in a given pass, apply the PROCEDURE first: a
-- live v3 procedure against a v2 registry row also reads as drift, but it self-heals the moment
-- the registry MERGE lands, whereas the reverse order leaves a real, alerting mismatch open until
-- the procedure is re-pasted.
--
-- !! THAT IS NOT SUFFICIENT ON ITS OWN -- READ THIS BEFORE RUNNING THE MERGE !!
-- The bigquery/63 registry MERGE is a SINGLE statement carrying ALL TWELVE rows, and TWO of them
-- were bumped on 2026-08-06 by TWO DIFFERENT new files: integrity_check v2->v3 by THIS file, and
-- cadence_check v11->v12 by bigquery/142_cadence_deadline_revert_and_evidence_drift.sql. There is
-- no way to apply "just this file's registry row". Following the paragraph above in ISOLATION --
-- applying this file's procedure and then running the MERGE -- would set expected_version='v12'
-- against a still-live v11 ops.sp_sq_cadence_check body and raise the very same non-auto-resolving
-- drift WARNING for the OTHER procedure, which is precisely the failure this warning exists to
-- prevent. The two files must land as ONE changeset, registry LAST:
--   1. THIS file in full -- state.append_only_integrity_haltable, THEN ops.sp_sq_integrity_check v3.
--   2. bigquery/142 Statements 1, 2, 3, 4 in written order (its Statement 2 view MUST precede its
--      Statement 3 procedure -- see that file's own APPLY ORDER section for why).
--   3. ONLY NOW the bigquery/63 MERGE -- both v3 and v12 bodies are live, so expected matches
--      reported on every row and nothing is raised.
--   4. Verify state.scheduled_query_version_drift reads 0 drift across all 12 rows.

-- ============================================================================
-- state.append_only_integrity_haltable -- the HALT-ELIGIBLE subset of state.append_only_integrity.
-- See file header for the full rationale. SCOPE: excludes ONLY statement_type='UPDATE' AND
-- target_table='adversarial_reviews' (the bb21c91-sanctioned review-repair mechanism). A DELETE /
-- MERGE / TRUNCATE_TABLE on adversarial_reviews, or ANY statement type on any of the other seven
-- audit-truth tables, is unaffected and stays halt-eligible.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.append_only_integrity_haltable` AS
SELECT * FROM `stock-trading-498512.state.append_only_integrity`
WHERE NOT (statement_type = 'UPDATE' AND target_table = 'adversarial_reviews');

-- ============================================================================
-- ops.sp_sq_integrity_check -- SQ_VERSION v3. Byte-for-byte identical to the v2 body in bigquery/
-- 75_scheduled_query_wrappers.sql:717-751 EXCEPT the two changes described in the file header
-- above (heartbeat literal 'v2'->'v3'; monitor_health_history `clean` now reads
-- state.append_only_integrity_haltable). The WARNING IF block is UNCHANGED, still reading the
-- FULL state.append_only_integrity.
-- NEW single source of truth for ops.sp_sq_integrity_check; SUPERSEDES that ONE procedure in
-- bigquery/75_scheduled_query_wrappers.sql (75's other 12 ops.sp_sq_* wrappers are untouched and
-- stay canonical there; 75 carries a matching SUPERSEDED LIVE marker above its own v2 definition).
-- ============================================================================
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_sq_integrity_check`()
BEGIN
  CALL `stock-trading-498512.ops.sp_beat_heartbeat`('sq:integrity_check', 'v3', 'integrity_check.sql ran');

  -- MONITOR-PROMOTION HISTORY (self-improvement audit ITEM 31, 2026-07-15; SCOPED 2026-08-06 -- see
  -- this file's header). Logged UNCONDITIONALLY (pass or fail) every run, mirroring cadence_check.sql's
  -- ddl_drift/restore_stale MERGE-upsert pattern (bigquery/45_monitor_promotion.sql, ITEM 24) --
  -- state.append_only_integrity_promotion_readiness (bigquery/57_append_only_integrity_promotion.sql)
  -- needs this history to evaluate "14 consecutive clean logged days", which state.append_only_
  -- integrity (a today-only, 2-day-lookback snapshot) cannot provide on its own. This does NOT change
  -- this query's alerting behavior at all -- still WARNING-only below, no RAISE, until D3's
  -- MONITOR-PROMOTION SELF-FLIP later promotes it (see bigquery/57's header for the exact promoted
  -- body, updated 2026-08-06 to match this file's scoping).
  --
  -- SCOPE CHANGE (this file, 2026-08-06): `clean` now reads state.append_only_integrity_haltable, NOT
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

  -- WARNING alerting body -- UNCHANGED from bigquery/75's v2 (byte-identical), still reads the FULL
  -- state.append_only_integrity. Only the promotion clock above narrows; today's alerting does not
  -- change at all.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.append_only_integrity`) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.integrity', 'append_only_violation',
      CONCAT('Append-only integrity: out-of-band UPDATE/DELETE/MERGE on immutable events.* table(s): ',
             (SELECT STRING_AGG(DISTINCT CONCAT(statement_type, ' ', target_table), ', ' ORDER BY CONCAT(statement_type, ' ', target_table))
              FROM `stock-trading-498512.state.append_only_integrity`)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(job_id, user_email, statement_type, target_table, query_preview)))
       FROM `stock-trading-498512.state.append_only_integrity`));
  END IF;
END;

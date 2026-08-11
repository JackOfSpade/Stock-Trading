-- bigquery/162_append_only_watchlist_cash_flows.sql (2026-08-10)
-- Project: stock-trading-498512. Apply after bigquery/18_stack_review_fixes.sql and after
-- bigquery/161_withdrawal_after_the_fact.sql (which creates events.cash_flow_candidates).
--
-- SUPERSEDES state.append_only_integrity from bigquery/18_stack_review_fixes.sql (see the SUPERSEDED
-- marker left there pointing here, same commit). This is the current single source of truth for this
-- view. Keep 18 for DR-rebuild history; do not re-apply its definition of this object in isolation.
-- bigquery/18's OTHER objects (ops.backup_log.per_table_rows, state.position_reconciliation,
-- state.trigger_attestation, state.go_without_order, state.stalled_runs,
-- state.market_calendar_horizon, state.embedding_scale_watch, ops.alerts.notified_ts) are UNTOUCHED
-- and remain canonical there -- this file redefines append_only_integrity only.
--
-- ============================ THE GAP ============================================================
-- events.cash_flows is the account's money ledger -- the single source of truth for total NAV
-- deposits, the §13 cash-tripwire baseline, and (via analytics.strategy_nav) every strategy's booked
-- capital. It is append-only by design: bigquery/22_cash_flows.sql's own header calls a new flow
-- "a single INSERT (Operating_Protocols §13.C), never a code edit", and no sanctioned in-place-repair
-- pattern exists for it anywhere (unlike decision_log.sub_pattern, which has one).
--
-- But it was never on state.append_only_integrity's watch-list. An out-of-band UPDATE or DELETE
-- against the money ledger -- the single most consequential append-only violation available in this
-- system -- raised NO governance alert at all, while an UPDATE against events.parking_events or
-- events.hf_capability_captures did. That is exactly backwards by consequence.
--
-- This was tolerable while the only writer was an occasional hand-authored INSERT. It stops being
-- tolerable with bigquery/161: ops.sp_record_withdrawal makes cash_flows a ROUTINE-written table, and
-- D2a's two-pass withdrawal path will write to it autonomously. Raising a table's write volume and
-- automation level without also putting it under the governance tripwire is the wrong order to do
-- those two things in.
--
-- ============================ THE CHANGE =========================================================
-- Exactly one edit: 'cash_flows' and 'cash_flow_candidates' are added to the
-- destination_table.table_id IN (...) allow-list. Nothing else in the view -- no other predicate, no
-- column, no formatting, and specifically NOT the decision_log.sub_pattern sanctioned-exception
-- clause -- changed; the body below is byte-for-byte bigquery/18's definition with those two names
-- appended to the list.
--
-- WHY NO NEW EXCEPTION CLAUSE IS NEEDED. Verified before writing this file: a 90-day scan of
-- region-us.INFORMATION_SCHEMA.JOBS_BY_PROJECT for statement_type IN
-- ('UPDATE','DELETE','MERGE','TRUNCATE_TABLE') against events.cash_flows returns ZERO rows. There is
-- no existing legitimate in-place mutation pattern to carve out, so adding the table cannot produce a
-- known false positive. (The view's own CAVEAT 4 applies unchanged: JOBS_BY_PROJECT retains ~180
-- days, so this is forward-detecting evidence, not a permanent guarantee.)
--
-- WHY cash_flow_candidates TOO. It is the two-phase staging ledger for an inferred external flow
-- (bigquery/161). Its status transitions are appended as NEW rows with the same candidate_key, never
-- mutated in place -- the same invariant, so the same tripwire. It does not exist until bigquery/161
-- is applied; that is harmless here, because this view scans JOBS_BY_PROJECT and filters by table
-- NAME, never joining the table itself. A watched name with no matching jobs simply contributes no
-- rows, exactly as low-volume hf_capability_captures already does.
--
-- KNOWN, ACCEPTED CONSEQUENCES (both correct, stated so a future audit does not read them as
-- surprises):
--   1. state.append_only_integrity_haltable (bigquery/141_append_only_halt_scope.sql) is
--      SELECT * FROM this view WHERE NOT (<adversarial_reviews carve-out>). The two new tables are
--      NOT carved out, so a violation on either counts toward the 14-consecutive-clean-day promotion
--      clock in state.append_only_integrity_promotion_readiness (bigquery/57). Widening the watch-list
--      can therefore delay that promotion -- which is the correct trade: a clean clock that does not
--      watch the money ledger is measuring the wrong thing.
--   2. D3's MONITOR-PROMOTION SELF-FLIP will eventually promote the append_only_violation alert from
--      warning to critical+RAISE (Claude_Task_Plan.md -- this is the one remaining unpromoted check).
--      After that promotion, a violation on cash_flows becomes a blocking critical and therefore a
--      trading halt via bigquery/107's halt_reason CASE. That is the intended severity for someone
--      mutating the money ledger out of band.

CREATE OR REPLACE VIEW `stock-trading-498512.state.append_only_integrity` AS
SELECT
  job_id,
  user_email,
  statement_type,
  destination_table.dataset_id AS target_dataset,
  destination_table.table_id   AS target_table,
  creation_time,
  end_time,
  SUBSTR(query, 0, 400) AS query_preview
FROM `stock-trading-498512`.`region-us`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 2 DAY)
  AND state = 'DONE'
  AND error_result IS NULL
  AND statement_type IN ('UPDATE', 'DELETE', 'MERGE', 'TRUNCATE_TABLE')
  AND destination_table.dataset_id = 'events'
  -- AUDIT-TRUTH watch-list only (reference/market-data feeds deliberately excluded — see header).
  -- cash_flows / cash_flow_candidates added 2026-08-10 (bigquery/162): the money ledger and its
  -- two-phase staging table are append-only audit truth, not a refreshed feed.
  AND destination_table.table_id IN (
    'decision_log', 'position_events', 'trade_fills', 'regime_events',
    'queue_events', 'adversarial_reviews', 'parking_events', 'hf_capability_captures',
    'cash_flows', 'cash_flow_candidates'
  )
  -- Suppress the ONE sanctioned exception: an UPDATE that sets ONLY decision_log.sub_pattern, on a
  -- day W5 (the taxonomy owner) logged a completed run. Anything else — any other column, any other
  -- watched table, any DELETE/MERGE/TRUNCATE — is a violation.
  AND NOT (
    statement_type = 'UPDATE'
    AND destination_table.table_id = 'decision_log'
    AND REGEXP_CONTAINS(query, r'(?i)set\s+sub_pattern\s*=')
    AND NOT REGEXP_CONTAINS(query,
          r'(?i)set[\s\S]*\b(decision|conviction|conviction_pct|body_md|title|entry_type|entry_date|strategy|ticker|fields|refs|tags|theater_check)\b\s*=')
    AND EXISTS (
      SELECT 1 FROM `stock-trading-498512.ops.run_log` r
      WHERE r.routine = 'W5' AND r.status = 'completed'
        AND r.run_date = DATE(creation_time, 'America/Denver')
    )
  );

-- VERIFICATION (run after apply; read-only).
-- NOTE: double-dash line comments only. A trailing C-style block comment placed after this file's
-- last statement causes permanent live-sql-parity drift -- never introduce one here.
--
-- 1. The view is still clean (no violation anywhere, including the two new tables):
--    SELECT * FROM `stock-trading-498512.state.append_only_integrity`;
--    -> expect zero rows. If a row appears for cash_flows immediately after apply, something is
--    mutating the money ledger in place and that is the alarm working, not a bug in this file.
--
-- 2. The two new names really are in the live predicate:
--    SELECT REGEXP_CONTAINS(view_definition, r"'cash_flows'") AS has_cash_flows,
--           REGEXP_CONTAINS(view_definition, r"'cash_flow_candidates'") AS has_candidates
--    FROM `stock-trading-498512.state.INFORMATION_SCHEMA.VIEWS` WHERE table_name='append_only_integrity';
--    -> expect true, true.
--
-- 3. The decision_log.sub_pattern sanctioned exception survived the copy-forward intact:
--    SELECT REGEXP_CONTAINS(view_definition, r'sub_pattern') AS exception_intact
--    FROM `stock-trading-498512.state.INFORMATION_SCHEMA.VIEWS` WHERE table_name='append_only_integrity';
--    -> expect true.
--
-- 4. The derived haltable view still resolves against the new base (it selects * from it):
--    SELECT COUNT(*) FROM `stock-trading-498512.state.append_only_integrity_haltable`;
--    -> expect 0, and no error.

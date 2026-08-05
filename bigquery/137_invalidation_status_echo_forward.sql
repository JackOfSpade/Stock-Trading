-- 137_invalidation_status_echo_forward.sql (2026-08-04)
-- Project: stock-trading-498512. Apply AFTER 136_declared_vs_realized_orphan_sides.sql.
-- Defines NO objects (pure append-only DML on events.position_events) -- SUPERSEDES nothing,
-- creates/replaces no view or procedure, so it is invisible to scripts/check_live_sql_parity.py.
--
-- ============================================================================
-- WHY
-- ============================================================================
-- ops.alerts 07125db5-0a10-44b3-bd9e-d1c8deedeac9 (D1, invalidation_mirror_dropped, 2026-08-04):
-- D:GEV:2026-08-03 lost its thesis-invalidation criteria. The D2a 2026-08-03 STEP 0
-- fill-reconciliation OPEN row (2b3ae339-ae3b-4395-9ba3-7086c7d14f68) correctly SUPERSEDED the
-- staging-time provisional OPEN (1a9138ab-c2fe-4a38-aa13-23905f4ccad2) on the same position_key
-- per the STAGING-OPEN KEY INVARIANT, but wrote invalidation_status = NULL, discarding a
-- complete, freshly-assessed 10-key criteria set.
--
-- state.current_positions (bigquery/01_schema.sql:129-133) is PURE LATEST-ROW-WINS ON EVERY
-- COLUMN with NO coalescing, so a column merely OMITTED from a session INSERT is not
-- unspecified -- it is NULLed for that position. That is the whole mechanism here.
--
-- EFFECT OF THE DEFECT: invalidation_criteria_evaluable flips FALSE (Claude_Task_Plan.md:614),
-- so D1 Rev 40 add HARD GATE cannot affirmatively confirm UNBREACHED and the position is
-- structurally ineligible for adds; and the criteria are absent from the field D1 daily
-- thesis-invalidation sweep reads. On the substance GEV is the least-threatened position in the
-- book -- this is a defect in the RECORD, not in the thesis.
--
-- ============================================================================
-- SCOPE -- measured, not assumed. TWO axes: which POSITIONS, and which COLUMNS.
-- ============================================================================
-- AXIS 1 -- POSITIONS. The alert names only D:GEV:2026-08-03. A full-table window scan (LAG over
-- every position_key, looking for any populated -> NULL transition on invalidation_status) found
-- the same 2026-08-03 D2a STEP 0 batch (event_ts 2026-08-03 16:51 MT) hit THREE positions, not one:
--
--   D:GEV:2026-08-03  OPEN   criteria destroyed on the reconciliation row   -> REPAIRED HERE
--   B:MTZ:2026-08-03  CLOSED criteria destroyed on the reconciliation row,
--                            then restored by the 2026-08-04 D2a CLOSE row  -> already clean
--   B:MDT:2026-06-17  CLOSED NOT_DISCRETELY_RECORDED_AT_ENTRY marker
--                            destroyed on EXIT_PENDING and again on CLOSE   -> REPAIRED HERE
--
-- As of 2026-08-04 these are the ONLY two position_keys whose LATEST row has a NULL
-- invalidation_status while an EARLIER row for the same key had it populated (verified by the
-- exact query dbt/tests/assert_no_invalidation_status_regression.sql runs). Repairing both is
-- what lets that new test ship GREEN rather than red-from-birth.
--
-- AXIS 2 -- COLUMNS. invalidation_status was NOT the only field that write dropped. On GEV the
-- SAME reconciliation row also nulled ltcg_date (2027-08-04) and conviction (MEDIUM), so
-- STATEMENT 1 restores all THREE from the provisional row. This matters operationally, not just
-- cosmetically: M4 STEP C reads ltcg_date to defer a Strategy D exit past the 12-month
-- qualification date, so a NULL there silently forfeits a tax-timing decision.
--
-- A wider scan over ltcg_date / conviction / source_thesis_ref / convergence_target /
-- time_exit_date / contract_id found 12 position_keys with SOME populated -> NULL transition on
-- the latest row -- but 9 of those are CLOSED positions whose terminal CLOSE row drops
-- conviction / convergence_target / time_exit_date, which is the long-standing NORM for a CLOSE
-- row across this table, not a defect introduced here. Those are deliberately NOT touched: this
-- file repairs only the 2026-08-03 batch damage, and only on fields where the loss is real.
-- D:DIS:2026-05-07 (lost source_thesis_ref) and D:RTX:2026-04-27 (lost time_exit_date) are
-- separate, older, unrelated cases and are likewise left alone.
--
-- MDT gets ONLY invalidation_status restored, deliberately. Its CLOSE row also dropped
-- conviction / convergence_target / time_exit_date / source_thesis_ref, but that matches all 8
-- other closed Strategy B positions -- restoring them on MDT alone would make it the anomaly.
--
-- ============================================================================
-- METHOD -- append-only, idempotent, carry-forward-safe
-- ============================================================================
-- events.position_events is append-only (state.append_only_integrity watches for
-- UPDATE/DELETE/MERGE on events.*). The repair is a new row, NEVER an UPDATE -- exactly what the
-- alert itself prescribes, and the bigquery/117_invalidation_status_backfill.sql pattern.
--
-- CARRY-FORWARD SAFETY (the trap this file is built around, inherited from 117): every column
-- except invalidation_status is echoed from the position OWN latest row by SELECTing from it --
-- never hand-retyped -- so a typo cannot silently rewrite cost_basis, shares or source_thesis_ref.
--
-- IDEMPOTENCE: each statement carries AND invalidation_status IS NULL against the position latest
-- row. After the first successful run that latest row IS the row written here, which HAS
-- invalidation_status, so a re-run matches zero rows and inserts nothing.
--
-- event_type CHOICE IS LOAD-BEARING, and differs between the two statements:
--   * GEV is OPEN. Its latest row is event_type='OPEN'. ADJUST is correct and matches bigquery/117
--     (every 117 target was likewise open), and ADJUST <> CLOSE keeps GEV visible in
--     state.current_positions exactly as today.
--   * MDT is CLOSED. state.current_positions filters `WHERE event_type <> 'CLOSE'` and looks at
--     event_type ALONE -- the status column is NOT part of that filter. An ADJUST row here would
--     therefore RESURRECT a closed position into the live book with its old shares and cost_basis,
--     regardless of writing status='CLOSED', and would then drive a false
--     state.position_reconciliation share_diff and fail
--     dbt/tests/assert_current_positions_match_lifecycle.sql. So MDT gets event_type='CLOSE'.
--     Verified safe: nothing in bigquery/*.sql assumes exactly one CLOSE row per position_key, and
--     analytics.position_lifecycle / analytics.position_campaigns / perf.strategy_daily.closed_trades
--     are all built from state.trade_fills_curated and never read events.position_events at all,
--     so P&L, FIFO lots and campaigns are unaffected by either statement.
--
-- Editor trap (bigquery/117 header, hit twice there): BigQuery does NOT accept '' doubling to
-- escape a quote inside a string literal -- it reads adjacent literals as CONCATENATION. Use a
-- backslash. The notes below deliberately contain no apostrophes at all.
--
-- ============================================================================
-- STATEMENT 1 -- D:GEV:2026-08-03 (OPEN)  event_type = ADJUST
-- ============================================================================
INSERT INTO `stock-trading-498512.events.position_events`
  (event_id, event_ts, position_key, event_type, status, strategy, ticker, contract_id, cost_basis,
   shares, convergence_target, time_exit_date, ltcg_date, invalidation_status, conviction,
   model_at_entry, source_thesis_ref, note)
SELECT
  GENERATE_UUID(),
  CURRENT_TIMESTAMP(),
  cur.position_key,
  'ADJUST',
  cur.status,
  cur.strategy,
  cur.ticker,
  cur.contract_id,
  cur.cost_basis,
  cur.shares,
  cur.convergence_target,
  cur.time_exit_date,
  (SELECT src.ltcg_date
   FROM `stock-trading-498512.events.position_events` src
   WHERE src.event_id = '1a9138ab-c2fe-4a38-aa13-23905f4ccad2'),
  (SELECT src.invalidation_status
   FROM `stock-trading-498512.events.position_events` src
   WHERE src.event_id = '1a9138ab-c2fe-4a38-aa13-23905f4ccad2'),
  (SELECT src.conviction
   FROM `stock-trading-498512.events.position_events` src
   WHERE src.event_id = '1a9138ab-c2fe-4a38-aa13-23905f4ccad2'),
  cur.model_at_entry,
  cur.source_thesis_ref,
  'Append-only repair (bigquery/137, 2026-08-04): echoes invalidation_status, ltcg_date and conviction forward VERBATIM from the staging-time provisional OPEN 1a9138ab-c2fe-4a38-aa13-23905f4ccad2, all THREE of which the D2a 2026-08-03 STEP 0 fill-reconciliation row 2b3ae339-ae3b-4395-9ba3-7086c7d14f68 dropped to NULL by omission in one write. Criteria are NOT re-derived and NOT re-stamped -- byte-identical to the entry-time assessment, per the metric_immutability clause they carry. ltcg_date 2027-08-04 and conviction MEDIUM likewise restored unchanged. Repairs ops.alerts 07125db5-0a10-44b3-bd9e-d1c8deedeac9. cost_basis stays at the RECONCILED fill value (120.656279), NOT the staging-time reference price -- the reconciliation row was right about that. Every other column echoed from the superseded row.'
FROM (
  SELECT * FROM `stock-trading-498512.events.position_events`
  WHERE position_key = 'D:GEV:2026-08-03'
  QUALIFY ROW_NUMBER() OVER (ORDER BY event_ts DESC, event_id DESC) = 1
) cur
WHERE cur.invalidation_status IS NULL OR TO_JSON_STRING(cur.invalidation_status) = 'null';

-- ============================================================================
-- STATEMENT 2 -- B:MDT:2026-06-17 (CLOSED)  event_type = CLOSE  (see METHOD above)
-- ============================================================================
INSERT INTO `stock-trading-498512.events.position_events`
  (event_id, event_ts, position_key, event_type, status, strategy, ticker, contract_id, cost_basis,
   shares, convergence_target, time_exit_date, ltcg_date, invalidation_status, conviction,
   model_at_entry, source_thesis_ref, note)
SELECT
  GENERATE_UUID(),
  CURRENT_TIMESTAMP(),
  cur.position_key,
  'CLOSE',
  cur.status,
  cur.strategy,
  cur.ticker,
  cur.contract_id,
  cur.cost_basis,
  cur.shares,
  cur.convergence_target,
  cur.time_exit_date,
  cur.ltcg_date,
  (SELECT src.invalidation_status
   FROM `stock-trading-498512.events.position_events` src
   WHERE src.event_id = '5326855e-79ea-49cd-9b8b-dbe110983226'),
  cur.conviction,
  cur.model_at_entry,
  cur.source_thesis_ref,
  'Append-only repair (bigquery/137, 2026-08-04): restores the NOT_DISCRETELY_RECORDED_AT_ENTRY marker bigquery/117 wrote on ADJUST row 5326855e-79ea-49cd-9b8b-dbe110983226 on 2026-07-30, which the 2026-08-03 EXIT_PENDING row dec0743e-858d-4ace-8d6d-0f345791837f and the D2a STEP 0 CLOSE row a692ca47-f5b3-4235-9d4b-23aadf6f23ba both dropped to NULL by omission. The marker exists so a count query can distinguish no data from no criteria BY DESIGN, and losing it silently re-hid exactly that distinction. event_type is CLOSE and NOT ADJUST on purpose: state.current_positions filters on event_type alone and ignores the status column, so an ADJUST row would resurrect this closed position into the live book. Position stays CLOSED; every other column echoed from the terminal CLOSE row; no other field changes.'
FROM (
  SELECT * FROM `stock-trading-498512.events.position_events`
  WHERE position_key = 'B:MDT:2026-06-17'
  QUALIFY ROW_NUMBER() OVER (ORDER BY event_ts DESC, event_id DESC) = 1
) cur
WHERE cur.invalidation_status IS NULL OR TO_JSON_STRING(cur.invalidation_status) = 'null';

-- ============================================================================
-- VERIFICATION (run manually after apply -- all three must hold)
-- ============================================================================
-- 1) The regression set is now EMPTY (this is the same query the new dbt singular test runs;
--    it must return ZERO rows):
--
-- WITH ranked AS (
--   SELECT position_key, event_id, event_ts, invalidation_status,
--          ROW_NUMBER() OVER (PARTITION BY position_key ORDER BY event_ts DESC, event_id DESC) AS rn
--   FROM `stock-trading-498512.events.position_events`
-- ), latest AS (SELECT * FROM ranked WHERE rn = 1),
--    ever AS (SELECT position_key,
--                    COUNTIF(invalidation_status IS NOT NULL
--                            AND TO_JSON_STRING(invalidation_status) <> 'null') AS n_pop
--             FROM ranked GROUP BY position_key)
-- SELECT l.position_key FROM latest l JOIN ever e USING (position_key)
-- WHERE (l.invalidation_status IS NULL OR TO_JSON_STRING(l.invalidation_status) = 'null')
--   AND e.n_pop > 0;
--
-- 2) GEV is still OPEN and now evaluable; MDT is still absent from the live book:
--
-- SELECT position_key, event_type, status, ltcg_date, conviction, cost_basis, shares,
--        TO_JSON_STRING(invalidation_status) AS inv
-- FROM `stock-trading-498512.state.current_positions`
-- WHERE position_key IN ('D:GEV:2026-08-03','B:MDT:2026-06-17');
-- -- EXPECT exactly 1 row: D:GEV:2026-08-03, event_type ADJUST, status OPEN, inv populated
-- -- (10 keys incl. primary_trend_metric), ltcg_date 2027-08-04, conviction MEDIUM,
-- -- cost_basis 120.656279 (the RECONCILED fill, unchanged), shares 0.1244 (unchanged).
-- -- B:MDT:2026-06-17 must NOT appear.
--
-- 3) The open-position count and share totals are UNCHANGED (15 open positions before this file;
--    the GEV ADJUST replaces GEV latest row rather than adding a position, and MDT stays closed):
--
-- SELECT COUNT(*) AS n_open, SUM(shares) AS total_shares
-- FROM `stock-trading-498512.state.current_positions` WHERE status = 'OPEN';
--
-- 4) Resolve the alert only AFTER 1-3 pass:
--
-- UPDATE `stock-trading-498512.ops.alerts`
-- SET resolved = TRUE, resolved_ts = CURRENT_TIMESTAMP(),
--     resolved_note = 'repaired by bigquery/137 append-only echo-forward; D2a/D2 write path fixed in Claude_Task_Plan.md shared rules; dbt/tests/assert_no_invalidation_status_regression.sql now guards the class'
-- WHERE alert_id = '07125db5-0a10-44b3-bd9e-d1c8deedeac9';

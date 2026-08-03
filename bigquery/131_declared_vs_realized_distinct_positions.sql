-- 131_declared_vs_realized_distinct_positions.sql (2026-08-03)
-- Project: stock-trading-498512. Apply AFTER 118_decision_record_audit_followups.sql.
--
-- SUPERSEDES bigquery/118_decision_record_audit_followups.sql's definition of
-- analytics.declared_vs_realized, and ONLY that object. 118's other object
-- (analytics.find_precedents) is UNCHANGED and deliberately NOT re-issued here -- per bigquery/47's
-- header rule, re-applying an old file's CREATE in isolation is the exact action that caused the 47
-- regression.
--
-- ============================ WHY ============================
-- W5 2026-08-03 raised process_scorecard_signal (alert 5dedd49e-552f-40b3-a8df-c3dd50eee37e):
-- go_minus_opened = -3 for BOTH strategy B and strategy D with min_n_met = TRUE -- i.e. three more
-- positions appeared to have been OPENED than there were GO theses to explain them, in each strategy.
-- The spec anticipates the POSITIVE direction (GO theses that never became positions); a negative
-- reading reads as a decision-provenance hole and invites a hunt for unexplained trades.
--
-- Most of it is a metric artifact, not a provenance hole. The `opened` CTE counts every
-- events.position_events row with event_type = 'OPEN' using COUNT(*). But the STAGING-OPEN KEY
-- INVARIANT deliberately writes TWO physical OPEN rows per position: a provisional row at staging
-- time, then a second fill-reconciliation row from D2a Step 0 carrying the same position_key.
-- events.position_events is append-only, so both rows necessarily coexist -- by design, not by
-- accident. Every fully-reconciled position is therefore counted twice.
--
-- MEASURED live 2026-08-03, before this fix:
--   strategy  go_theses  OPEN rows  DISTINCT position_key  go_minus_opened (old -> new)
--   B         12         15         13                     -3 -> -1
--   D         12         15         12                     -3 ->  0
-- min_n_met stays TRUE for both (it depends only on go_theses >= 5, which this file does not touch).
--
-- Adversarial checks run before adopting COUNT(DISTINCT position_key), because DISTINCT would
-- UNDER-count if any position legitimately owns two genuine OPENs:
--   * max OPEN rows for any single position_key = 2, and ZERO keys have 3 or more -- consistent with
--     the two-row invariant and inconsistent with an accidental duplicate-write bug.
--   * ZERO OPEN rows have a NULL position_key, so DISTINCT cannot silently collapse a NULL group.
--   * ADD tranches (the 2026-07-21 adds-to-positions feature, strategies A/B/D) mint their OWN
--     distinct position_key rather than re-using the parent's, so an add is still counted once --
--     DISTINCT does not swallow it.
--   * No re-open-after-close case exists in the data today; such a case would also carry a distinct
--     position_key under the current key format (bigquery/102's campaign/FIFO-lot rebuild).
--
-- ============================ RESIDUAL, DELIBERATELY NOT FIXED HERE ============================
-- The row-duplication artifact explains ALL of strategy D's -3 and -2 of strategy B's -3. B retains a
-- genuine -1 on a distinct-position basis: one real decision-log provenance/vocabulary gap where an
-- opened position has no matching GO-family thesis row. That residual was already investigated and
-- EXPLICITLY DEFERRED in bigquery/118_decision_record_audit_followups.sql; this file does not reopen
-- it. Fixing the metric first is the right order -- it removes the noise that was hiding the single
-- real case, so the next W5 pass sees -1 (one genuine item to adjudicate) instead of -3.
--
-- Scope check: no other metric in this view, and no consumer downstream, shares the defect.
-- analytics.process_scorecard reads go_minus_opened / min_n_met as scalar subqueries, and
-- state.strategy_playbook_readiness's dvr_ok is COUNTIF(min_n_met) > 0 across all strategies -- both
-- unaffected in shape. go_minus_opened moves toward zero (less alarming), so no downstream gate can
-- newly trip on this change.

CREATE OR REPLACE VIEW `stock-trading-498512.analytics.declared_vs_realized` AS
WITH go_theses AS (
  -- Was: SELECT ... FROM events.decision_log WHERE entry_type='thesis-construction' AND decision='GO'.
  -- Now reads the corrected single source (bigquery/116), so entry_type synonyms and the GO family
  -- ('GO (add tranche)') are counted here identically to how calibration counts them.
  SELECT strategy, COUNT(*) AS go_count
  FROM `stock-trading-498512.analytics.thesis_outcomes`
  WHERE is_go_family
  GROUP BY strategy
),
opened AS (
  -- COUNT(DISTINCT position_key), NOT COUNT(*): the STAGING-OPEN KEY INVARIANT writes a provisional
  -- OPEN at staging and a second fill-reconciliation OPEN under the SAME position_key, and
  -- events.position_events is append-only so both persist. COUNT(*) double-counted every reconciled
  -- position. See this file's header for the adversarial checks proving DISTINCT does not under-count
  -- adds or re-opens (both mint their own position_key).
  SELECT strategy, COUNT(DISTINCT position_key) AS opened_count
  FROM `stock-trading-498512.events.position_events`
  WHERE event_type = 'OPEN'
  GROUP BY strategy
)
SELECT
  COALESCE(g.strategy, o.strategy) AS strategy,
  COALESCE(g.go_count, 0) AS go_theses,
  COALESCE(o.opened_count, 0) AS positions_opened,
  COALESCE(g.go_count, 0) - COALESCE(o.opened_count, 0) AS go_minus_opened,
  (COALESCE(g.go_count, 0) >= 5) AS min_n_met
FROM go_theses g
FULL OUTER JOIN opened o ON o.strategy = g.strategy
ORDER BY strategy;

-- VERIFICATION (run manually after the live apply; expected values measured live 2026-08-03):
--   SELECT strategy, go_theses, positions_opened, go_minus_opened, min_n_met
--   FROM `stock-trading-498512.analytics.declared_vs_realized` ORDER BY strategy;
-- Expect B: go_theses=12, positions_opened=13, go_minus_opened=-1, min_n_met=TRUE
--        D: go_theses=12, positions_opened=12, go_minus_opened= 0, min_n_met=TRUE
-- Expect no strategy to report positions_opened greater than its DISTINCT position_key count:
--   SELECT strategy, COUNT(DISTINCT position_key)
--   FROM `stock-trading-498512.events.position_events` WHERE event_type='OPEN' GROUP BY strategy;

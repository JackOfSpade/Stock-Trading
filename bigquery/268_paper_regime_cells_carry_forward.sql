-- ===== 268: state.strategy_paper_regime_cells -- carry a skipped day's change forward, never drop it =====
-- Project: stock-trading-498512. Apply after 267. ONE statement: CREATE OR REPLACE VIEW
-- state.strategy_paper_regime_cells. SUPERSEDES the definition in bigquery/267_paper_regime_coverage_gate.sql.
-- The body is 267's, extracted mechanically; the only change is the marginal-excess base (below). Every output
-- column and the DEMONSTRATED rule (>= 5 days, no unloggable day, compounded in-cell excess >= 0) are unchanged.
--
-- ===== THE DEFECT (found 2026-10-25 reviewing 267 before its live apply) =====
-- 267's header says a paper day with no series row or NULL excess "rolls into the next non-NULL day, so no
-- loss is dropped". That held for a NULL-excess day only. The base of each day's marginal change was the
-- previous paper day's cumulative excess (LAST_VALUE over ALL paper days), and the series JOIN then removed any
-- day without a regime cell. A day that had excess but no cell was therefore the base of the next day's change
-- while its own change appeared nowhere: a loss on that day vanished from every cell's compounded excess,
-- which loosens the gate in exactly the direction 267 was written to close.
--
-- MEASURED 2026-10-25: no paper rows exist (analytics.strategy_incubation_perf phase = paper: 0), and
-- state.technical_regime_daily has a complete cell on every trading day from 2026-07-31, so no live value
-- moved. The exposure was future days with a missing or partial D2a TECHNICAL_SIGNAL write.
--
-- ===== THE FIX =====
-- The series join becomes a LEFT JOIN that keeps every paper day in sequence (celled), and the base is the
-- cumulative excess on the last KEPT day: LAST_VALUE(IF(regime_cell IS NOT NULL, excess, NULL) IGNORE NULLS).
-- The kept day after a gap then carries the whole change since the previous kept day, and is assigned its own
-- cell. Over a strategy's whole run, the compounded marginal excess across all cells equals the latest kept
-- day's cumulative index, so no change is lost. Reference implementation and vectors: scripts/paper_regime_cells.py,
-- tests/fixtures/paper_regime_cells_vectors.json (tests/test_paper_regime_cells.py).
--
-- ===== DIRECTION AND BLAST RADIUS =====
-- Identical to 267 whenever every paper day has a cell. Otherwise a cell can now see a loss it previously
-- missed (or a gain), so demonstrated can flip either way for the kept day's cell; that is the correct value.
-- Readers: state.arsenal_regime_coverage and state.strategy_paper_readiness (bigquery/267), unchanged.
CREATE OR REPLACE VIEW `stock-trading-498512.state.strategy_paper_regime_cells` AS
WITH paper AS (
  -- One row per (strategy_code, incubation_day): SL3's idempotency guard should already make it unique;
  -- newest computed_ts wins if it does not.
  SELECT strategy_code, incubation_day, CAST(excess AS FLOAT64) AS excess
  FROM `stock-trading-498512.analytics.strategy_incubation_perf`
  WHERE phase = 'paper'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY strategy_code, incubation_day ORDER BY computed_ts DESC) = 1
),
celled AS (
  -- LEFT JOIN: every paper day stays in the sequence, with regime_cell NULL where the series has no
  -- complete row for that day.
  SELECT p.strategy_code, p.incubation_day, p.excess, t.regime_cell
  FROM paper p
  LEFT JOIN `stock-trading-498512.state.technical_regime_daily` t ON t.as_of_date = p.incubation_day
),
marginal AS (
  -- The base is the cumulative excess on the last KEPT day (non-NULL excess AND a regime cell), so the
  -- change over any skipped day rolls into the next kept day instead of being dropped.
  SELECT strategy_code, incubation_day, excess, regime_cell,
    COALESCE(LAST_VALUE(IF(regime_cell IS NOT NULL, excess, NULL) IGNORE NULLS) OVER (
      PARTITION BY strategy_code ORDER BY incubation_day
      ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS prior_excess
  FROM celled
),
daily AS (
  SELECT strategy_code, incubation_day, regime_cell,
    SAFE.LN(SAFE_DIVIDE(1 + excess, 1 + prior_excess)) AS log_rel_excess
  FROM marginal
  WHERE excess IS NOT NULL AND regime_cell IS NOT NULL
)
SELECT
  strategy_code, regime_cell,
  COUNT(*) AS paper_days_in_cell,
  COUNTIF(log_rel_excess IS NULL) AS unloggable_days,
  EXP(SUM(log_rel_excess)) - 1 AS cell_excess,
  (COUNT(*) >= 5 AND COUNTIF(log_rel_excess IS NULL) = 0 AND SUM(log_rel_excess) >= 0) AS demonstrated
FROM daily
GROUP BY strategy_code, regime_cell;

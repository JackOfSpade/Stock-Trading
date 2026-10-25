-- Parallel-run dbt port of bigquery/267_paper_regime_coverage_gate.sql:state.strategy_paper_regime_cells — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
WITH paper AS (
  -- One row per (strategy_code, incubation_day): SL3's idempotency guard should already make it unique;
  -- newest computed_ts wins if it does not.
  SELECT strategy_code, incubation_day, CAST(excess AS FLOAT64) AS excess
  FROM {{ source('analytics_external', 'strategy_incubation_perf') }}
  WHERE phase = 'paper'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY strategy_code, incubation_day ORDER BY computed_ts DESC) = 1
),
marginal AS (
  SELECT strategy_code, incubation_day, excess,
    COALESCE(LAST_VALUE(excess IGNORE NULLS) OVER (
      PARTITION BY strategy_code ORDER BY incubation_day
      ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS prior_excess
  FROM paper
),
daily AS (
  SELECT m.strategy_code, m.incubation_day, t.regime_cell,
    SAFE.LN(SAFE_DIVIDE(1 + m.excess, 1 + m.prior_excess)) AS log_rel_excess
  FROM marginal m
  JOIN {{ ref('technical_regime_daily') }} t ON t.as_of_date = m.incubation_day
  WHERE m.excess IS NOT NULL AND t.regime_cell IS NOT NULL
)
SELECT
  strategy_code, regime_cell,
  COUNT(*) AS paper_days_in_cell,
  COUNTIF(log_rel_excess IS NULL) AS unloggable_days,
  EXP(SUM(log_rel_excess)) - 1 AS cell_excess,
  (COUNT(*) >= 5 AND COUNTIF(log_rel_excess IS NULL) = 0 AND SUM(log_rel_excess) >= 0) AS demonstrated
FROM daily
GROUP BY strategy_code, regime_cell

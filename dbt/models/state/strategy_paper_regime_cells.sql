-- Parallel-run dbt port of bigquery/268_paper_regime_cells_carry_forward.sql:state.strategy_paper_regime_cells — canonical source is that file until
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
celled AS (
  -- LEFT JOIN: every paper day stays in the sequence, with regime_cell NULL where the series has no
  -- complete row for that day.
  SELECT p.strategy_code, p.incubation_day, p.excess, t.regime_cell
  FROM paper p
  LEFT JOIN {{ ref('technical_regime_daily') }} t ON t.as_of_date = p.incubation_day
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
GROUP BY strategy_code, regime_cell

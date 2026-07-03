-- Parallel-run dbt port of bigquery/21_strategy_vs_park.sql:analytics.strategy_vs_park_daily — canonical source is that file until owner cutover.
-- The weekly email's chart series: excess_vs_sgov (the % PRIMARY, straight from the engine) plus
-- the dollar edge (secondary). edge_dollars_day = deployed_capital × (r_deployed − r_sgov): the
-- dollars the deployed slice made over what those same dollars would have earned staying in the
-- SGOV park; cumulative sum is the sleeve-level dollar edge (undeployed sleeve cash already sits in
-- the account-level SGOV park, so the sleeve differs from the all-parked counterfactual only on the
-- deployed slice). r_sgov forward-fill mirrors ops.sp_recompute_engine (a missing SGOV mark must
-- not read as 0).

WITH j AS (
  SELECT
    sdr.as_of_date, sdr.strategy, sdr.deployed_capital, sdr.r_deployed,
    COALESCE(
      sg.r_sgov,
      LAST_VALUE(sg.r_sgov IGNORE NULLS) OVER (
        PARTITION BY sdr.strategy ORDER BY sdr.as_of_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
      0) AS r_sgov
  FROM {{ ref('strategy_daily_returns') }} sdr
  LEFT JOIN {{ ref('sgov_daily_return') }} sg USING (as_of_date)
)
SELECT
  j.as_of_date, j.strategy, j.deployed_capital,
  pd.deployed_unit_value,
  pd.excess_vs_sgov,
  j.deployed_capital * (j.r_deployed - j.r_sgov) AS edge_dollars_day,
  SUM(j.deployed_capital * (j.r_deployed - j.r_sgov)) OVER (
    PARTITION BY j.strategy ORDER BY j.as_of_date) AS edge_dollars_cum
FROM j
LEFT JOIN {{ source('perf', 'strategy_daily') }} pd
  ON pd.as_of_date = j.as_of_date AND pd.strategy = j.strategy

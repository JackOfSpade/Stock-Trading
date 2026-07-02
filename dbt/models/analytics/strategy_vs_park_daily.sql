-- Parallel-run dbt port of bigquery/21_strategy_vs_park.sql:analytics.strategy_vs_park_daily — canonical source is that file until owner cutover.
-- The weekly email's chart series. edge_dollars_day = deployed_capital × (r_deployed − r_sgov):
-- the dollars the deployed slice made over what those same dollars would have earned staying in
-- the SGOV park. Cumulative sum answers "beating the park?" at SLEEVE level, because undeployed
-- sleeve cash already sits in the account-level SGOV park — the sleeve differs from the
-- all-parked counterfactual only on the deployed slice. r_sgov forward-fill mirrors
-- ops.sp_recompute_engine (a missing SGOV mark must not read as 0).

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
  as_of_date, strategy, deployed_capital,
  deployed_capital * (r_deployed - r_sgov) AS edge_dollars_day,
  SUM(deployed_capital * (r_deployed - r_sgov)) OVER (
    PARTITION BY strategy ORDER BY as_of_date) AS edge_dollars_cum
FROM j

-- Parallel-run dbt port of bigquery/21_strategy_vs_park.sql:analytics.deployed_book_vs_sgov — canonical source is that file until owner cutover.
-- One row: the combined deployed-book excess % — the weekly email's hero headline (2026-07-03).
-- Treat every strategy's deployed positions as ONE book, value-weight the daily returns by
-- deployed_capital, chain it, and compare to SGOV chained over the same days. Weighting by
-- deployed_capital makes this a portfolio-level answer, not a naive average of per-strategy
-- percentages (which don't combine). r_sgov forward-fill mirrors the engine.

WITH agg AS (
  SELECT sdr.as_of_date,
         SAFE_DIVIDE(SUM(sdr.deployed_capital * sdr.r_deployed), SUM(sdr.deployed_capital)) AS r_agg
  FROM {{ ref('strategy_daily_returns') }} sdr
  GROUP BY sdr.as_of_date
),
j AS (
  SELECT a.as_of_date, a.r_agg,
    COALESCE(
      sg.r_sgov,
      LAST_VALUE(sg.r_sgov IGNORE NULLS) OVER (
        ORDER BY a.as_of_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
      0) AS r_sgov
  FROM agg a
  LEFT JOIN {{ ref('sgov_daily_return') }} sg USING (as_of_date)
)
SELECT
  MIN(as_of_date) AS first_deployed_date,
  MAX(as_of_date) AS as_of_date,
  EXP(SUM(LN(1 + r_agg))) - 1 AS book_return,
  EXP(SUM(LN(1 + r_sgov))) - 1 AS sgov_return,
  EXP(SUM(LN(1 + r_agg))) / EXP(SUM(LN(1 + r_sgov))) - 1 AS combined_excess_pct
FROM j

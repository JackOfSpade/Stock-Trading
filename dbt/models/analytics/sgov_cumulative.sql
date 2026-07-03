-- Parallel-run dbt port of bigquery/21_strategy_vs_park.sql:analytics.sgov_cumulative — canonical source is that file until owner cutover.
-- SGOV's own cumulative total return (close + dividends) chained from the first deployed date,
-- aligned to the union of dates in strategy_vs_park_daily. The weekly email plots this as the SGOV
-- line on the returns chart and derives SGOV's own average return per week/month/year over those days.

WITH days AS (
  SELECT DISTINCT as_of_date FROM {{ ref('strategy_vs_park_daily') }}
),
j AS (
  SELECT d.as_of_date,
    COALESCE(
      sg.r_sgov,
      LAST_VALUE(sg.r_sgov IGNORE NULLS) OVER (
        ORDER BY d.as_of_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
      0) AS r_sgov
  FROM days d
  LEFT JOIN {{ ref('sgov_daily_return') }} sg USING (as_of_date)
)
SELECT
  as_of_date,
  EXP(SUM(LN(1 + r_sgov)) OVER (ORDER BY as_of_date)) - 1 AS sgov_cum_return
FROM j

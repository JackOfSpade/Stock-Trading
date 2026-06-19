-- Parallel-run dbt port of bigquery/03_twr_engine.sql:analytics.sgov_daily_return — canonical source is that file until owner cutover.
-- SGOV benchmark = SGOV's ACTUAL total return (close + dividend). SGOV price is ~flat because
-- its yield pays out as a monthly dividend (IBKR DRIP), so price-only understates it. Chain-link
-- r_sgov over a strategy's deployed days for its benchmark index.

WITH s AS (
  SELECT mark_date, close, COALESCE(dividend, 0) AS dividend,
         LAG(close) OVER (ORDER BY mark_date) AS prev_close
  FROM {{ ref('daily_marks_curated') }}
  WHERE ticker = 'SGOV'
)
SELECT mark_date AS as_of_date, SAFE_DIVIDE(close + dividend - prev_close, prev_close) AS r_sgov
FROM s WHERE prev_close IS NOT NULL

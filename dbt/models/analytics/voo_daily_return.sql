-- Parallel-run dbt port of bigquery/46_weekly_benchmarks.sql:analytics.voo_daily_return — canonical source is that file until owner cutover.
-- VOO benchmark = VOO's ACTUAL total return (close + dividend). Byte-parallel to sgov_daily_return.sql.

WITH s AS (
  SELECT mark_date, close, COALESCE(dividend, 0) AS dividend,
         LAG(close) OVER (ORDER BY mark_date) AS prev_close
  FROM {{ ref('daily_marks_curated') }}
  WHERE ticker = 'VOO'
)
SELECT mark_date AS as_of_date, SAFE_DIVIDE(close + dividend - prev_close, prev_close) AS r_voo
FROM s WHERE prev_close IS NOT NULL

-- Parallel-run dbt port of bigquery/46_weekly_benchmarks.sql:analytics.voo_cumulative — canonical source is that file until owner cutover.
-- VOO's own cumulative total return (close + dividends), aligned to the union of dates in
-- strategy_vs_park_daily (same axis as sgov_cumulative, so the weekly email's chart lines share an
-- x-axis). Unlike SGOV's forward-fill, a missing VOO mark reads as a 0% return for that day
-- (COALESCE, not LAST_VALUE) — repeating a stale rate is right for a cash-like accrual, wrong for a
-- volatile equity index. NULL before VOO's first observed mark so the email can render "Not enough
-- data" instead of a misleading flat line from day one.

WITH axis AS (
  SELECT DISTINCT as_of_date FROM {{ ref('strategy_vs_park_daily') }}
),
j AS (
  SELECT a.as_of_date, v.r_voo,
         MIN(CASE WHEN v.r_voo IS NOT NULL THEN a.as_of_date END) OVER () AS first_voo_date
  FROM axis a
  LEFT JOIN {{ ref('voo_daily_return') }} v USING (as_of_date)
)
SELECT as_of_date,
  CASE WHEN first_voo_date IS NULL OR as_of_date < first_voo_date THEN NULL
       ELSE EXP(SUM(LN(1 + GREATEST(COALESCE(r_voo, 0), -0.9999)))
                OVER (ORDER BY as_of_date)) - 1
  END AS voo_cum_return
FROM j

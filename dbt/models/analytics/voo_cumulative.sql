-- Parallel-run dbt port of bigquery/46_weekly_benchmarks.sql:analytics.voo_cumulative — canonical source is that file until owner cutover.
-- VOO's own cumulative total return (close + dividends), aligned to the union of dates in
-- strategy_vs_park_daily (same axis as sgov_cumulative, so the weekly email's chart lines share an
-- x-axis).
-- NULL-ON-GAP (2026-07-17 audit fix — keep in lockstep with bigquery/46): voo_cum_return is NULL on
-- ANY axis day with no real VOO mark — before VOO's first mark AND on any interior/trailing ingest gap
-- (r_voo IS NULL). The cumulative is still chained internally with COALESCE(r_voo,0), so the level is
-- preserved across a gap and resumes exactly on the next real mark; only the output on gap days is
-- hidden. This makes the chart show a genuine break (not a false flat line through missing data) and
-- keeps the last non-null day equal to the true last VOO mark, so weekly_report.gs's "⚠ VOO data
-- through <date>" staleness warning can fire (a VOO-only stall doesn't trip the all-ticker freshness).

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
  CASE WHEN first_voo_date IS NULL OR as_of_date < first_voo_date THEN NULL  -- before VOO's first mark
       WHEN r_voo IS NULL THEN NULL  -- interior/trailing ingest gap: break the line, don't carry a false 0
       ELSE EXP(SUM(LN(1 + GREATEST(COALESCE(r_voo, 0), -0.9999)))
                OVER (ORDER BY as_of_date)) - 1  -- level chained across gaps via COALESCE, hidden above
  END AS voo_cum_return
FROM j

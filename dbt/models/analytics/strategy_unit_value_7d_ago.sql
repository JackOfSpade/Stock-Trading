-- Parallel-run dbt port of bigquery/14_weekly_report.sql:analytics.strategy_unit_value_7d_ago — canonical source is that file until owner cutover.
-- Nearest perf.strategy_daily row to "7 days ago" per strategy (handles weekends/holidays where
-- there is no exact 7-day-back trading day). Feeds strategy_scorecard's week-over-week Δ column.
SELECT strategy, deployed_unit_value AS deployed_unit_value_7d_ago
FROM {{ source('perf', 'strategy_daily') }}
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY strategy
  ORDER BY ABS(DATE_DIFF(as_of_date, DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY), DAY))
) = 1

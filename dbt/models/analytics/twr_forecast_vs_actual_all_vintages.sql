-- Parallel-run dbt port of bigquery/06_forecast.sql:analytics.twr_forecast_vs_actual_all_vintages — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
SELECT f.run_date AS forecast_run_date, f.entity AS strategy, f.forecast_date,
       f.forecast_value, f.pi_lower, f.pi_upper,
       a.deployed_unit_value AS actual,
       a.deployed_unit_value < f.pi_lower AS below_band,
       a.deployed_unit_value > f.pi_upper AS above_band
FROM {{ source('analytics_external', 'deployed_twr_forecast') }} f
JOIN {{ source('perf', 'strategy_daily') }} a
  ON a.strategy = f.entity AND a.as_of_date = f.forecast_date
WHERE f.series = 'deployed_unit_value'

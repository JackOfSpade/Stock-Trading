-- Parallel-run dbt port of bigquery/06_forecast.sql:analytics.twr_forecast_vs_actual — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH last_run AS (
  SELECT * FROM {{ source('analytics_external', 'deployed_twr_forecast') }}
  WHERE series = 'deployed_unit_value'
    AND run_date = (SELECT MAX(run_date)
                    FROM {{ source('analytics_external', 'deployed_twr_forecast') }}
                    WHERE series = 'deployed_unit_value')
)
SELECT f.run_date AS forecast_run_date, f.entity AS strategy, f.forecast_date,
       f.forecast_value, f.pi_lower, f.pi_upper,
       a.deployed_unit_value AS actual,
       a.deployed_unit_value < f.pi_lower AS below_band,
       a.deployed_unit_value > f.pi_upper AS above_band
FROM last_run f
JOIN {{ source('perf', 'strategy_daily') }} a
  ON a.strategy = f.entity AND a.as_of_date = f.forecast_date

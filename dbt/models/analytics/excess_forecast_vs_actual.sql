-- Parallel-run dbt port of bigquery/77_forecast_consumption.sql:analytics.excess_forecast_vs_actual — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
SELECT
  f.run_date AS forecast_run_date,
  f.entity AS strategy,
  f.forecast_date,
  f.forecast_value,
  f.pi_lower,
  f.pi_upper,
  a.excess_vs_sgov AS actual,
  a.excess_vs_sgov < f.pi_lower AS below_band,
  a.excess_vs_sgov > f.pi_upper AS above_band
FROM {{ source('analytics_external', 'deployed_twr_forecast') }} f
JOIN {{ source('perf', 'strategy_daily') }} a
  ON a.strategy = f.entity AND a.as_of_date = f.forecast_date
WHERE f.series = 'excess_vs_sgov'

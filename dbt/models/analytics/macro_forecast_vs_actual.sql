-- Parallel-run dbt port of bigquery/77_forecast_consumption.sql:analytics.macro_forecast_vs_actual — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
SELECT
  f.run_date AS forecast_run_date,
  f.series AS metric,
  f.forecast_date,
  f.forecast_value,
  f.pi_lower,
  f.pi_upper,
  a.value AS actual,
  a.value < f.pi_lower AS below_band,
  a.value > f.pi_upper AS above_band
FROM {{ source('analytics_external', 'deployed_twr_forecast') }} f
JOIN {{ ref('macro_fred_latest') }} a
  ON a.metric = f.series AND DATE_TRUNC(a.ref_month, MONTH) = DATE_TRUNC(f.forecast_date, MONTH)
WHERE f.entity = 'macro'

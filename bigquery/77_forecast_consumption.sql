-- Consumption-closure 2026-07-16: the excess_vs_sgov and entity=macro forecast rows were written
-- monthly by M5 but excluded from every calibration view (bigquery/06_forecast.sql filters
-- series='deployed_unit_value' only) — stored, never read. Both views below are ADVISORY (never a
-- trigger), read by M5 STEP 1 (early-warning) and M4 §H (gate/kill context only). Depends on
-- 06_forecast.sql (analytics.deployed_twr_forecast), 03_twr_engine.sql (perf.strategy_daily),
-- 07_fred_macro.sql (state.macro_fred_latest). Note: file number 77 (not 67 as originally scoped) —
-- bigquery/ already had a 67_ci_findings_bridge.sql and ran up to 76_owner_confirmation_liveness.sql
-- by the time this was applied; 77 is the actual next free apply-order slot.

-- ===== excess_vs_sgov forecast-vs-actual (the m2m-proxy series; single most-recent-vintage, =====
-- ===== same pattern as 06_forecast.sql §B twr_forecast_vs_actual) =====
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.excess_forecast_vs_actual` AS
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
FROM `stock-trading-498512.analytics.deployed_twr_forecast` f
JOIN `stock-trading-498512.perf.strategy_daily` a
  ON a.strategy = f.entity AND a.as_of_date = f.forecast_date
WHERE f.series = 'excess_vs_sgov';

-- ===== macro forecast-vs-actual (entity='macro' rows; every vintage kept, matching the =====
-- ===== twr_forecast_vs_actual_all_vintages calibration pattern — the alert path in M5 STEP 1 =====
-- ===== pins to the latest vintage itself, this view stays all-vintages by design) =====
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.macro_forecast_vs_actual` AS
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
FROM `stock-trading-498512.analytics.deployed_twr_forecast` f
JOIN `stock-trading-498512.state.macro_fred_latest` a
  ON a.metric = f.series AND DATE_TRUNC(a.ref_month, MONTH) = DATE_TRUNC(f.forecast_date, MONTH)
WHERE f.entity = 'macro';

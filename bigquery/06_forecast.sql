-- BigQuery forecast layer (v2 redesign addendum, 2026-06-06). Project: stock-trading-498512.
-- Zero-shot AI.FORECAST (built-in TimesFM 2.0 -- NO model to train or host) over the deployed-TWR
-- engine (perf.strategy_daily) and, once it accrues history, the macro series (events.macro_series).
-- Written monthly by the M5 routine (Claude_Task_Plan.md "M5. Deployed-TWR & Macro Forecast").
-- ADVISORY / EARLY-WARNING ONLY: kill/gate triggers fire on REALISED values (perf.kill_flags),
-- never on a forecast. Validated 2026-06-06 against live data: AI.FORECAST runs on the 29-deployed-day
-- perf.strategy_daily series (handles the business-day spacing); a 2-point macro series returns
-- ai_forecast_status='The time series data is too short.' -> macro is GATED on history (STEP 4 / §C).

-- ===== Forecast store (append-only; one run = many rows) =====
CREATE TABLE IF NOT EXISTS `stock-trading-498512.analytics.deployed_twr_forecast` (
  run_date DATE NOT NULL,                 -- M5 run date (America/Denver) that produced the forecast
  run_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  series STRING NOT NULL,                 -- 'deployed_unit_value' | 'excess_vs_sgov' | a macro metric
  entity STRING,                          -- strategy (A..E) for TWR series; metric name for macro
  horizon_index INT64,                    -- 1..H step ahead
  forecast_date DATE,                     -- AI.FORECAST forecast_timestamp cast to DATE
  forecast_value FLOAT64,
  pi_lower FLOAT64, pi_upper FLOAT64, confidence_level FLOAT64,
  model STRING DEFAULT 'AI.FORECAST/TimesFM-2.0',
  note STRING
) PARTITION BY run_date CLUSTER BY series, entity
OPTIONS(description='Monthly AI.FORECAST output (deployed-TWR + macro), written by M5. Advisory only -- never a trigger.');

-- ===== (A) New forecast: deployed_unit_value + excess_vs_sgov, per active strategy =====
-- M5 runs this twice (data_col 'deployed_unit_value' then 'excess_vs_sgov') and INSERTs the rows.
-- horizon 21 ~= one trading month; confidence 0.9. Re-runnable: M5 stamps run_date = today.
--   INSERT INTO `stock-trading-498512.analytics.deployed_twr_forecast`
--     (run_date, series, entity, horizon_index, forecast_date,
--      forecast_value, pi_lower, pi_upper, confidence_level)
--   SELECT CURRENT_DATE('America/Denver'), 'deployed_unit_value', strategy,
--          ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY forecast_timestamp),
--          DATE(forecast_timestamp), forecast_value,
--          prediction_interval_lower_bound, prediction_interval_upper_bound, confidence_level
--   FROM AI.FORECAST(
--     (SELECT as_of_date, strategy, deployed_unit_value FROM `stock-trading-498512.perf.strategy_daily`),
--     data_col => 'deployed_unit_value', timestamp_col => 'as_of_date',
--     id_cols => ['strategy'], horizon => 21, confidence_level => 0.9)
--   WHERE COALESCE(ai_forecast_status,'') = '';   -- drop any strategy AI.FORECAST flags too-short
--   -- repeat with data_col => 'excess_vs_sgov' and series => 'excess_vs_sgov'.

-- ===== (B) Forecast-vs-actual early-warning: did realised TWR fall outside the PRIOR forecast band? =====
-- The monitoring payoff of storing forecasts: compare the most-recent PRIOR run's forecast for
-- now-elapsed dates against realised perf.strategy_daily. A realised value below pi_lower is a
-- downside surprise (possible regime shift / unmodeled deterioration) M5 flags for the operator.
-- Single-vintage BY DESIGN -- this is the STEP 1 early-warning read (Claude_Task_Plan.md M5), which
-- wants only the most-recent PRIOR run compared to what has since elapsed. Do NOT use this view as an
-- accumulating bias tally -- see twr_forecast_vs_actual_all_vintages below (ITEM 21 fix, 2026-07-11:
-- this view's MAX(run_date) filter previously fed analytics.forecast_bias directly, so the bias tally
-- reset to ~zero every M5 run and could never detect a persistently-biased forecaster).
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.twr_forecast_vs_actual` AS
WITH last_run AS (
  SELECT * FROM `stock-trading-498512.analytics.deployed_twr_forecast`
  WHERE series = 'deployed_unit_value'
    AND run_date = (SELECT MAX(run_date)
                    FROM `stock-trading-498512.analytics.deployed_twr_forecast`
                    WHERE series = 'deployed_unit_value')
)
SELECT f.run_date AS forecast_run_date, f.entity AS strategy, f.forecast_date,
       f.forecast_value, f.pi_lower, f.pi_upper,
       a.deployed_unit_value AS actual,
       a.deployed_unit_value < f.pi_lower AS below_band,
       a.deployed_unit_value > f.pi_upper AS above_band
FROM last_run f
JOIN `stock-trading-498512.perf.strategy_daily` a
  ON a.strategy = f.entity AND a.as_of_date = f.forecast_date;

-- ===== (B2) Forecast-vs-actual, ALL vintages -- the rolling calibration tally (ITEM 21 fix, 2026-07-11) =====
-- Same join as (B) but over EVERY forecast run_date, not just the latest -- every past vintage's
-- now-elapsed forecast_date rows stay in the comparison permanently (deployed_twr_forecast is
-- append-only, so this view only grows). analytics.forecast_bias (bigquery/26_process_metrics.sql)
-- is repointed to this view so a systematically biased forecaster accumulates evidence across M5 runs
-- instead of the tally resetting to ~zero each run. A given forecast_date can appear multiple times
-- (once per vintage that forecast it) -- that is intentional: each vintage's forecast is judged
-- independently against the one realised outcome. Advisory only, same as (B) -- never a trigger.
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.twr_forecast_vs_actual_all_vintages` AS
SELECT f.run_date AS forecast_run_date, f.entity AS strategy, f.forecast_date,
       f.forecast_value, f.pi_lower, f.pi_upper,
       a.deployed_unit_value AS actual,
       a.deployed_unit_value < f.pi_lower AS below_band,
       a.deployed_unit_value > f.pi_upper AS above_band
FROM `stock-trading-498512.analytics.deployed_twr_forecast` f
JOIN `stock-trading-498512.perf.strategy_daily` a
  ON a.strategy = f.entity AND a.as_of_date = f.forecast_date
WHERE f.series = 'deployed_unit_value';

-- ===== (C) Macro forecast -- FRED-backed (state.macro_fred_latest), un-gated =====
-- events.macro_fred holds 15 FRED-derived monthly regime metrics with deep history (37-54 months;
-- St. Louis Fed public CSV, no API key -- see 07_fred_macro.sql); state.macro_fred_latest dedups
-- (metric, ref_month). The >=8-obs gate is satisfied, so AI.FORECAST runs (ai_forecast_status='' on
-- success). M5 forecasts all metrics 3 months ahead and INSERTs the empty-status rows into
-- analytics.deployed_twr_forecast (series = metric, entity = 'macro'). Keep the gate as a guard for any
-- thin/new metric. (The M1a-curated events.macro_series audit table is separate.)
--   INSERT INTO `stock-trading-498512.analytics.deployed_twr_forecast`
--     (run_date, series, entity, horizon_index, forecast_date, forecast_value, pi_lower, pi_upper, confidence_level)
--   SELECT CURRENT_DATE('America/Denver'), metric, 'macro',
--          ROW_NUMBER() OVER (PARTITION BY metric ORDER BY forecast_timestamp),
--          DATE(forecast_timestamp), forecast_value,
--          prediction_interval_lower_bound, prediction_interval_upper_bound, confidence_level
--   FROM AI.FORECAST(
--     (SELECT metric, ref_month, value FROM `stock-trading-498512.state.macro_fred_latest`),
--     data_col => 'value', timestamp_col => 'ref_month',
--     id_cols => ['metric'], horizon => 3, confidence_level => 0.8)
--   WHERE COALESCE(ai_forecast_status,'') = '';

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

-- ===== (C) Macro forecast -- GATED on history =====
-- events.macro_series carries only 1-2 monthly points per metric as of 2026-06; AI.FORECAST returns
-- ai_forecast_status='The time series data is too short.' until a metric accrues history. M5 forecasts
-- a metric only once it has >= 8 monthly observations (tunable); otherwise it records
-- 'insufficient history (n=<k>)'. Eligible set + per-metric forecast:
--   SELECT metric, COUNT(*) n FROM `stock-trading-498512.events.macro_series`
--     GROUP BY metric HAVING n >= 8;            -- eligible metrics
--   -- then, per eligible metric @m:
--   SELECT * FROM AI.FORECAST(
--     (SELECT release_date, metric, value
--        FROM `stock-trading-498512.events.macro_series` WHERE metric = @m),
--     data_col => 'value', timestamp_col => 'release_date',
--     id_cols => ['metric'], horizon => 3, confidence_level => 0.8);

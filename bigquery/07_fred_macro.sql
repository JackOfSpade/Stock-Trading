-- BigQuery FRED macro layer (2026-06-06). Project: stock-trading-498512.
-- events.macro_fred = FRED-derived MONTHLY regime metrics with deep history -- the un-gated input to
-- M5 STEP 4's macro AI.FORECAST (06_forecast.sql §C). Sourced from the St. Louis Fed PUBLIC CSV
-- (https://fred.stlouisfed.org/graph/fredgraph.csv?id=<SERIES> -- NO API KEY, no connector, no cost).
-- Kept SEPARATE from the M1a-curated events.macro_series audit table (the experiment's hand-entered
-- monthly reads); macro_fred is the bulk historical / forecast substrate.
-- Seeded 2026-06-06: 777 rows, 15 metrics, 2022-01..2026-06 (hy_oas 2023-06..2026-06), validated by a
-- per-metric count+sum checksum against the source. value is FLOAT64.

-- ===== Table =====
CREATE TABLE IF NOT EXISTS `stock-trading-498512.events.macro_fred` (
  metric STRING NOT NULL,        -- regime metric name (see map below)
  ref_month DATE NOT NULL,       -- first-of-month reference date
  value FLOAT64,                 -- YoY %, level, MoM-diff (thousands), or month-end level per the map
  source STRING,                 -- 'FRED'
  fetched_ts TIMESTAMP
) PARTITION BY ref_month CLUSTER BY metric
OPTIONS(description='FRED-derived monthly macro regime metrics (public CSV, no key). Deep history for M5 AI.FORECAST. Separate from M1a-curated events.macro_series.');

-- Dedup view (latest fetch wins per metric/month) -- M5 + AI.FORECAST read THIS (unique id/timestamp).
CREATE OR REPLACE VIEW `stock-trading-498512.state.macro_fred_latest` AS
SELECT metric, ref_month, value, source, fetched_ts
FROM `stock-trading-498512.events.macro_fred`
QUALIFY ROW_NUMBER() OVER (PARTITION BY metric, ref_month ORDER BY fetched_ts DESC) = 1;

-- ===== metric  <-  FRED series_id  (transform) =====
--   CPI_core_yoy               <- CPILFESL        (YoY % of index)
--   CPI_headline_yoy           <- CPIAUCSL        (YoY %)
--   PCE_core_yoy               <- PCEPILFE        (YoY %)
--   PPI_headline_yoy           <- PPIFIS          (YoY %, final demand)
--   retail_sales_yoy           <- RSAFS           (YoY %)
--   avg_hourly_earnings_yoy    <- CES0500000003   (YoY %, total private)
--   industrial_production_yoy  <- INDPRO          (YoY %)
--   unemployment_u3            <- UNRATE          (level %)
--   fed_funds                  <- FEDFUNDS        (level %, monthly effective)
--   nonfarm_payrolls           <- PAYEMS          (MoM change, thousands)
--   treasury_10y               <- DGS10           (daily -> month-end level %)
--   treasury_2y                <- DGS2            (daily -> month-end level %)
--   yield_curve_10y2y          <- T10Y2Y          (daily -> month-end, %)
--   hy_oas                     <- BAMLH0A0HYM2    (daily -> month-end, ICE BofA US HY OAS %)
--   vix                        <- VIXCLS          (daily -> month-end level)

-- ===== §refresh -- run monthly to append new prints =====
-- BigQuery cannot fetch HTTP, so the pull runs OUTSIDE BQ (curl -> transform -> INSERT). M1a (the
-- monthly macro routine) refreshes this each cycle, before M5 forecasts:
--   1. For each FRED series above, fetch the public CSV (no key):
--        curl -s "https://fred.stlouisfed.org/graph/fredgraph.csv?id=<SERIES>&cosd=2020-01-01"
--      Skip rows whose value is '.' or empty; forward-fill any missing month so the series stays
--      CONTIGUOUS (a single forward-filled month is fine; gaps misalign monthly forecasting).
--   2. Transform per the map: YoY = (v / v_12mo - 1) * 100 ; MoM-diff = v - v_prev ;
--      daily -> the last VALID obs in the month (dated first-of-month) ; levels as-is.
--   3. INSERT the new month's rows (idempotent via the dedup view):
--        INSERT INTO `stock-trading-498512.events.macro_fred` (metric, ref_month, value, source, fetched_ts)
--        VALUES ('<metric>', DATE '<YYYY-MM-01>', <value>, 'FRED', CURRENT_TIMESTAMP());
-- Full reseed = CREATE OR REPLACE TABLE (above) + the array-load used at seed time (contiguous monthly
-- value arrays per metric, decoded with GENERATE_ARRAY + DATE_ADD; all-FLOAT64 so UNION ALL types match).

-- ===== M5 macro forecast (see 06_forecast.sql §C) =====
-- SELECT * FROM AI.FORECAST(
--   (SELECT metric, ref_month, value FROM `stock-trading-498512.state.macro_fred_latest`),
--   data_col => 'value', timestamp_col => 'ref_month', id_cols => ['metric'],
--   horizon => 3, confidence_level => 0.8)
-- WHERE COALESCE(ai_forecast_status,'') = '';   -- all 15 metrics un-gated as of 2026-06.

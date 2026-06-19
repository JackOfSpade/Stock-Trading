-- BigQuery market-calendar layer (P1-3). Project: stock-trading-498512.
-- ONE authoritative answer to "is today a trading day?" / "what was the last close?"
-- so every routine and view stops re-deriving it ad hoc. This closes the recurring
-- date-anchor fragility (e.g. the 2026-05-27 UTC-drift regression that deleted same-day
-- order-confirmation events, and the manual "markets CLOSED Fri 6/19 Juneteenth" note).
-- Idempotent (IF NOT EXISTS / OR REPLACE / MERGE). Apply via the BigQuery MCP execute_sql.
--
-- Design: store only the EXCEPTIONS (full-close holidays + early closes). A trading day
-- is then "a weekday that is not a full-close holiday" — computed in state.market_calendar.
-- Scalar SQL UDFs cannot query tables in BigQuery, so the table-backed logic lives in VIEWS.

-- ===== Holiday / early-close exceptions =====
CREATE TABLE IF NOT EXISTS `stock-trading-498512.events.market_holidays` (
  holiday_date DATE NOT NULL,
  holiday_name STRING,
  full_close BOOL,            -- TRUE = market fully closed; FALSE = early close (still a trading day)
  source STRING,
  fetched_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
) PARTITION BY holiday_date
OPTIONS(description='US equity-market full-close + early-close exceptions. Trading day = weekday AND NOT a full_close row. Extend yearly (see ops/RUNBOOK.md).');

-- Seed 2024–2027 US equity-market FULL closes (NYSE/Nasdaq). Observed dates used where a
-- fixed holiday falls on a weekend (e.g. Jul 4 2026 = Sat -> observed Fri 2026-07-03).
-- MERGE keeps it idempotent (re-running this file will not duplicate rows).
-- VERIFY/EXTEND before each new year per the runbook — exchange holiday schedules are the source.
MERGE `stock-trading-498512.events.market_holidays` T
USING (
  SELECT * FROM UNNEST([
    STRUCT(DATE '2024-01-01' AS holiday_date, "New Year's Day" AS holiday_name),
    STRUCT(DATE '2024-01-15', 'Martin Luther King Jr. Day'),
    STRUCT(DATE '2024-02-19', "Washington's Birthday"),
    STRUCT(DATE '2024-03-29', 'Good Friday'),
    STRUCT(DATE '2024-05-27', 'Memorial Day'),
    STRUCT(DATE '2024-06-19', 'Juneteenth'),
    STRUCT(DATE '2024-07-04', 'Independence Day'),
    STRUCT(DATE '2024-09-02', 'Labor Day'),
    STRUCT(DATE '2024-11-28', 'Thanksgiving Day'),
    STRUCT(DATE '2024-12-25', 'Christmas Day'),
    STRUCT(DATE '2025-01-01', "New Year's Day"),
    STRUCT(DATE '2025-01-09', 'National Day of Mourning (J. Carter)'),
    STRUCT(DATE '2025-01-20', 'Martin Luther King Jr. Day'),
    STRUCT(DATE '2025-02-17', "Washington's Birthday"),
    STRUCT(DATE '2025-04-18', 'Good Friday'),
    STRUCT(DATE '2025-05-26', 'Memorial Day'),
    STRUCT(DATE '2025-06-19', 'Juneteenth'),
    STRUCT(DATE '2025-07-04', 'Independence Day'),
    STRUCT(DATE '2025-09-01', 'Labor Day'),
    STRUCT(DATE '2025-11-27', 'Thanksgiving Day'),
    STRUCT(DATE '2025-12-25', 'Christmas Day'),
    STRUCT(DATE '2026-01-01', "New Year's Day"),
    STRUCT(DATE '2026-01-19', 'Martin Luther King Jr. Day'),
    STRUCT(DATE '2026-02-16', "Washington's Birthday"),
    STRUCT(DATE '2026-04-03', 'Good Friday'),
    STRUCT(DATE '2026-05-25', 'Memorial Day'),
    STRUCT(DATE '2026-06-19', 'Juneteenth'),
    STRUCT(DATE '2026-07-03', 'Independence Day (observed)'),
    STRUCT(DATE '2026-09-07', 'Labor Day'),
    STRUCT(DATE '2026-11-26', 'Thanksgiving Day'),
    STRUCT(DATE '2026-12-25', 'Christmas Day'),
    STRUCT(DATE '2027-01-01', "New Year's Day"),
    STRUCT(DATE '2027-01-18', 'Martin Luther King Jr. Day'),
    STRUCT(DATE '2027-02-15', "Washington's Birthday"),
    STRUCT(DATE '2027-03-26', 'Good Friday'),
    STRUCT(DATE '2027-05-31', 'Memorial Day'),
    STRUCT(DATE '2027-06-18', 'Juneteenth (observed)'),
    STRUCT(DATE '2027-07-05', 'Independence Day (observed)'),
    STRUCT(DATE '2027-09-06', 'Labor Day'),
    STRUCT(DATE '2027-11-25', 'Thanksgiving Day'),
    STRUCT(DATE '2027-12-24', 'Christmas Day (observed)')
  ])
) S
ON T.holiday_date = S.holiday_date
WHEN NOT MATCHED THEN
  INSERT (holiday_date, holiday_name, full_close, source, fetched_ts)
  VALUES (S.holiday_date, S.holiday_name, TRUE, 'seed-2024-2027', CURRENT_TIMESTAMP());

-- ===== Trading-day calendar (computed) =====
-- DAYOFWEEK: 1=Sunday .. 7=Saturday. A trading day = weekday AND not a full-close holiday.
CREATE OR REPLACE VIEW `stock-trading-498512.state.market_calendar` AS
WITH days AS (
  SELECT d AS cal_date
  FROM UNNEST(GENERATE_DATE_ARRAY(DATE '2023-01-01', DATE '2028-12-31')) d
)
SELECT
  days.cal_date,
  EXTRACT(DAYOFWEEK FROM days.cal_date) NOT IN (1, 7)
    AND h.holiday_date IS NULL AS is_trading_day,
  hh.holiday_name,
  hh.full_close,
  -- early-close rows are still trading days but flagged for downstream awareness
  (hh.holiday_date IS NOT NULL AND hh.full_close = FALSE) AS is_early_close
FROM days
LEFT JOIN `stock-trading-498512.events.market_holidays` h
  ON h.holiday_date = days.cal_date AND h.full_close = TRUE
LEFT JOIN `stock-trading-498512.events.market_holidays` hh
  ON hh.holiday_date = days.cal_date;

-- ===== "Today" in the experiment's operating timezone (America/Denver) =====
-- The single source every routine/view should read instead of bespoke TZ math.
-- last_trading_day = most recent trading day <= today (today itself if it is one).
-- next_trading_day = soonest trading day strictly after today.
CREATE OR REPLACE VIEW `stock-trading-498512.state.trading_day_today` AS
WITH today AS (SELECT CURRENT_DATE('America/Denver') AS d)
SELECT
  t.d AS today,
  (SELECT mc.is_trading_day FROM `stock-trading-498512.state.market_calendar` mc WHERE mc.cal_date = t.d) AS is_trading_day,
  (SELECT MAX(mc.cal_date) FROM `stock-trading-498512.state.market_calendar` mc
     WHERE mc.cal_date <= t.d AND mc.is_trading_day) AS last_trading_day,
  (SELECT MIN(mc.cal_date) FROM `stock-trading-498512.state.market_calendar` mc
     WHERE mc.cal_date > t.d AND mc.is_trading_day) AS next_trading_day
FROM today t;

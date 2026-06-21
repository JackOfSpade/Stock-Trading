-- Parallel-run dbt port of bigquery/09_market_calendar.sql:state.market_calendar — canonical source is that file until owner cutover.
-- Trading-day calendar (computed). Stored exceptions = full-close holidays + early closes;
-- a trading day = a weekday that is not a full-close holiday.
-- Ported here (alongside trading_day_today) because state.freshness / system_health ref it;
-- the underlying events.market_holidays seed MERGE stays in 09 (DDL/DML, not dbt-owned).
-- DAYOFWEEK: 1=Sunday .. 7=Saturday.

WITH days AS (
  SELECT d AS cal_date
  -- End date MUST match the live view in bigquery/09_market_calendar.sql (kept in lockstep; the
  -- dbt↔live parity check enforces it). Bump both together when the calendar horizon is extended.
  FROM UNNEST(GENERATE_DATE_ARRAY(DATE '2023-01-01', DATE '2030-12-31')) d
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
LEFT JOIN {{ source('events', 'market_holidays') }} h
  ON h.holiday_date = days.cal_date AND h.full_close = TRUE
LEFT JOIN {{ source('events', 'market_holidays') }} hh
  ON hh.holiday_date = days.cal_date

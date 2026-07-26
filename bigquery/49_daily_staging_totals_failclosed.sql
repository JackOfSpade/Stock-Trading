-- ITEM: state.daily_staging_totals.daily_cap_breach fails OPEN if analytics.strategy_nav ever
-- returns zero rows (2026-07-14 self-improvement audit, finding sql-mid#3).
--
-- BUG: bigquery/23_trading_control.sql's `cap` CTE computes
-- `SUM(sizing_base_2pct) FROM analytics.strategy_nav` with no row-count guard. SUM over zero input
-- rows is NULL (not 0, unlike COUNT). If analytics.strategy_nav ever returns zero rows (e.g.
-- state.strategy_roster / state.active_strategy_codes momentarily empty from an upstream data
-- issue -- an infra incident, not reachable via normal SL1-SL5 roster churn since the N>=2 floor
-- keeps `active` non-empty under normal operation), `combined_sizing_base` and `max_daily_notional`
-- both read NULL, and `notional_staged_today > 10 * NULL` evaluates to NULL (not TRUE) --
-- `daily_cap_breach` reads NULL, and any consumer filtering `WHERE daily_cap_breach` silently skips
-- the ENTIRE notional cap (only the independent `orders_staged_today > 15` count-cap still works,
-- since COUNT can never be NULL). This is unlike this same file's state.trading_enabled /
-- state.book_drawdown_watch / bigquery/35's state.arsenal_enabled, which all use the ARRAY_AGG-
-- single-row / fail-closed-COALESCE pattern specifically so an empty upstream can never silently
-- disable a safety check.
--
-- FIX: COALESCE the SUM to 0 (so a zero-row strategy_nav doesn't propagate NULL through the
-- comparison), and treat combined_sizing_base <= 0 as an explicit breach (fail closed instead of
-- fail open). <= 0 (not just = 0) also covers the theoretical case of a small negative aggregate
-- sizing base (a strategy's NAV underwater enough to flip the sum's sign) as a free, strictly-more-
-- defensive extra -- under the ORIGINAL code a negative sum flips the notional comparison to
-- almost-always-TRUE (over-eager, not silently-open), so it isn't part of the confirmed bug, but
-- costs nothing to also guard here.
--
-- SUPERSEDES the state.daily_staging_totals VIEW definition in bigquery/23_trading_control.sql. No
-- dbt mirror exists for this view. Apply after 23_trading_control.sql, 46_weekly_benchmarks.sql.
--
-- SUPERSEDED LIVE, IN TURN, by bigquery/109_retire_daily_staging_cap.sql (owner directive 2026-07-26 —
-- the daily order-count/notional cap this file introduced the fail-closed fix for is itself retired;
-- 109 is the CURRENT single source of truth for state.daily_staging_totals). Kept here, unmodified,
-- for DR-rebuild apply-in-order reference only. DO NOT re-apply this CREATE OR REPLACE VIEW statement
-- live in isolation.
CREATE OR REPLACE VIEW `stock-trading-498512.state.daily_staging_totals` AS
WITH today_staged AS (
  SELECT
    item_key,
    CAST(JSON_VALUE(payload, '$.qty') AS NUMERIC) * CAST(JSON_VALUE(payload, '$.limit_price') AS NUMERIC) AS notional
  FROM `stock-trading-498512.events.queue_events`
  WHERE queue = 'ORDER_STAGED'
    AND DATE(event_ts, 'America/Denver') = CURRENT_DATE('America/Denver')
  QUALIFY ROW_NUMBER() OVER (PARTITION BY item_key ORDER BY event_ts DESC) = 1
),
cap AS (
  SELECT COALESCE(SUM(sizing_base_2pct), 0) AS combined_sizing_base
  FROM `stock-trading-498512.analytics.strategy_nav`
)
SELECT
  (SELECT COUNT(DISTINCT item_key) FROM today_staged) AS orders_staged_today,
  (SELECT ROUND(SUM(notional), 2) FROM today_staged) AS notional_staged_today,
  ROUND(10 * cap.combined_sizing_base, 2) AS max_daily_notional,
  15 AS max_daily_orders,
  ((SELECT COUNT(DISTINCT item_key) FROM today_staged) > 15
    OR (SELECT COALESCE(SUM(notional), 0) FROM today_staged) > 10 * cap.combined_sizing_base
    OR cap.combined_sizing_base <= 0) AS daily_cap_breach
FROM cap;

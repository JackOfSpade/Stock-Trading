-- ITEM: retire the daily aggregate order-count/notional cap on state.daily_staging_totals (owner
-- directive 2026-07-26 — no daily cap on how many trades or how much notional a strategy can stage in
-- a day; per-order risk is governed by analytics.fn_order_guard / fn_order_guard_options, not by a
-- daily aggregate ceiling).
--
-- WHAT THIS DROPS. bigquery/49_daily_staging_totals_failclosed.sql's state.daily_staging_totals
-- exposed three cap-related fields: max_daily_notional (10x the combined 2%-sizing base across active
-- strategies), max_daily_orders (hardcoded 15), and daily_cap_breach (TRUE if either threshold was
-- exceeded, or the sizing base was <= 0). The ONLY consumer of daily_cap_breach was
-- ops.sp_sq_daily_staging_cap_check (bigquery/75_scheduled_query_wrappers.sql) — a RECORD-ONLY WARNING
-- alert (no RAISE; never blocked any order craft, per bigquery/scheduled_queries/daily_staging_cap_check.sql's
-- own POSTURE note). Removing these three fields therefore changes nothing about which orders can be
-- staged or executed today — it retires a review-only alert, not a trading control. The companion edit
-- to bigquery/75_scheduled_query_wrappers.sql (ops.sp_sq_daily_staging_cap_check, bumped to v4) drops
-- the daily_cap_breach IF block accordingly; the order_guard_omitted / order_guard_verdict_mismatch
-- checks in that same procedure are UNRELATED (per-order guard-record integrity, not a daily aggregate
-- cap) and are untouched.
--
-- WHAT THIS KEEPS. orders_staged_today / notional_staged_today (the raw counters) stay, for
-- visibility/dashboards only — no threshold is compared against them anymore.
--
-- SUPERSEDES the state.daily_staging_totals VIEW definition in bigquery/23_trading_control.sql AND
-- bigquery/49_daily_staging_totals_failclosed.sql. No dbt mirror exists for this view. Apply after
-- 49_daily_staging_totals_failclosed.sql.
CREATE OR REPLACE VIEW `stock-trading-498512.state.daily_staging_totals` AS
WITH today_staged AS (
  SELECT
    item_key,
    CAST(JSON_VALUE(payload, '$.qty') AS NUMERIC) * CAST(JSON_VALUE(payload, '$.limit_price') AS NUMERIC) AS notional
  FROM `stock-trading-498512.events.queue_events`
  WHERE queue = 'ORDER_STAGED'
    AND DATE(event_ts, 'America/Denver') = CURRENT_DATE('America/Denver')
  QUALIFY ROW_NUMBER() OVER (PARTITION BY item_key ORDER BY event_ts DESC) = 1
)
SELECT
  (SELECT COUNT(DISTINCT item_key) FROM today_staged) AS orders_staged_today,
  (SELECT ROUND(SUM(notional), 2) FROM today_staged) AS notional_staged_today;

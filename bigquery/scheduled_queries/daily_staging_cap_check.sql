-- SCHEDULED QUERY (2026-07-04 audit finding): wires up state.daily_staging_totals
-- (bigquery/23_trading_control.sql), which was computed but read by nothing — a per-order guard
-- (analytics.fn_order_guard) cannot stop a runaway session staging many small in-band orders; this is
-- that missing daily-aggregate backstop actually being checked.
--
-- POSTURE: RECORD-ONLY WARNING (no RAISE) — same staged-rollout posture as integrity_check.sql. A
-- breach means "review today's staging before crafting one more", not a proven hard failure of any one
-- order, so it should not flip all_green or storm the DTS failure-email until a clean baseline is
-- confirmed. Promote to critical + RAISE later if desired (cadence_check.sql's pattern).
--
-- TIMING: any time during/after the trading day; ~05:25 UTC sits with the other daily control-plane
-- checks (after D2 has staged the day's orders). APPLY ORDER: bigquery/23_trading_control.sql must be
-- applied first.
BEGIN
  IF (SELECT daily_cap_breach FROM `stock-trading-498512.state.daily_staging_totals`) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.staging_cap', 'staging_cap_breach',
      'Daily staging cap check: today''s staged orders exceed the daily notional/order-count cap.',
      (SELECT TO_JSON_STRING(t) FROM `stock-trading-498512.state.daily_staging_totals` t));
  END IF;
END;

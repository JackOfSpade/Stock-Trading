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
      'Daily staging cap check: today\'s staged orders exceed the daily notional/order-count cap.',
      (SELECT TO_JSON_STRING(t) FROM `stock-trading-498512.state.daily_staging_totals` t));
  END IF;

  -- order_guard_omitted (CRITICAL, not staged-rollout -- ITEM 15, self-improvement audit 2026-07-11).
  -- fn_order_guard / fn_order_guard_options is a per-order obligation on the calling routine, with no
  -- mechanical enforcement possible (no BigQuery stored procedure can gate a call to a DIFFERENT MCP
  -- tool, create_order_instruction) -- compliance depended entirely on the routine's markdown instructions
  -- being followed verbatim. state.open_orders.guard_passed (bigquery/01_schema.sql) now surfaces whether
  -- the guard's own result was embedded in the ORDER_STAGED payload; a row STAGED TODAY with guard_passed
  -- IS NULL means either the guard never ran, or it ran and the routine didn't record it -- either way
  -- the safety envelope was bypassed for that order, not merely undocumented. Unlike the daily_cap_breach
  -- check above (a soft "review before crafting more" signal), a missing guard record is unambiguous --
  -- CRITICAL immediately, no staged-rollout warning period.
  IF EXISTS (
    SELECT 1 FROM `stock-trading-498512.state.open_orders`
    WHERE DATE(staged_ts, 'America/Denver') = CURRENT_DATE('America/Denver')
      AND guard_passed IS NULL
  ) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.staging_cap', 'order_guard_omitted',
      'One or more orders staged today have no recorded fn_order_guard/fn_order_guard_options result -- the pre-craft risk envelope may have been bypassed for these orders.',
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(item_key, strategy, ticker, side, qty, limit_price, staged_ts)))
       FROM `stock-trading-498512.state.open_orders`
       WHERE DATE(staged_ts, 'America/Denver') = CURRENT_DATE('America/Denver') AND guard_passed IS NULL));
  END IF;
END;

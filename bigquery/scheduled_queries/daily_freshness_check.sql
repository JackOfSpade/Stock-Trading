-- SCHEDULED QUERY (P0-2): the dead-man's switch. Detects a silently-skipped D2
-- (stale marks/engine), unhealthy embeddings, firing kill flags, or open critical alerts.
--
-- NOTIFICATION (zero extra infra): this query RAISEs an error when the system is not
-- green, so BigQuery's built-in "Send email notifications on failure" toggle emails the
-- owner. It ALSO writes a durable ops.alerts row (idempotent — one open row per issue).
--
-- TIMING MATTERS: schedule for the EVENING after D2 should have ingested the close,
-- ~21:00-23:00 America/Denver. state.system_health compares marks/engine to the last
-- TRADING day (state.trading_day_today), so it auto-suppresses on weekends/holidays
-- (last_trading_day is the prior close, already covered) — no false alarms when markets
-- are shut. See ops/RUNBOOK.md "Scheduled queries".
BEGIN
  IF (SELECT NOT all_green FROM `stock-trading-498512.state.system_health`) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.freshness', 'staleness',
      'Daily freshness check: system_health not green',
      (SELECT TO_JSON_STRING(t) FROM `stock-trading-498512.state.system_health` t));
    RAISE USING MESSAGE = CONCAT(
      'STOCK-TRADING freshness check FAILED (not all_green): ',
      (SELECT TO_JSON_STRING(t) FROM `stock-trading-498512.state.system_health` t));
  END IF;
END;

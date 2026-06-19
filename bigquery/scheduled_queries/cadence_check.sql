-- SCHEDULED QUERY (fix A3): cadence dead-man's switch. Detects a MONITORED routine that was expected
-- to run on the current operating day but logged no 'completed' run (state.cadence_watch.needs_attention).
-- Complements daily_freshness_check.sql: freshness catches a stale ENGINE (D2's data work); this catches
-- any routine that has adopted run-logging and then silently skips a scheduled run.
--
-- SELF-BOOTSTRAPPING (see bigquery/12_cadence_monitor.sql): a routine is only "monitored" once it has
-- logged a 'completed' run in the last 14 days, so this never false-alarms on routines that don't yet
-- self-log. As more routines adopt ops.sp_routine_start/end, they auto-enroll.
--
-- NOTIFICATION: RAISEs on failure so BigQuery's built-in "Send email notifications on failure" emails
-- the owner, AND writes a durable idempotent ops.alerts row.
--
-- TIMING: BigQuery schedules are UTC. Run ~05:15 UTC (≈ 22:45 MDT / 21:45 MST) — same Denver evening,
-- after D2/D3, like the freshness check. On non-trading days only D3 (daily_all) is expected, so this
-- stays quiet unless a monitored routine genuinely missed. See ops/RUNBOOK.md "Scheduled queries".
BEGIN
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.cadence_watch` WHERE needs_attention) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.cadence', 'missed_run',
      CONCAT('Cadence check: monitored routine(s) expected today did not complete: ',
             (SELECT STRING_AGG(routine, ', ' ORDER BY routine)
              FROM `stock-trading-498512.state.cadence_watch` WHERE needs_attention)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(routine, schedule, today)))
       FROM `stock-trading-498512.state.cadence_watch` WHERE needs_attention));
    RAISE USING MESSAGE = CONCAT(
      'STOCK-TRADING cadence check FAILED — monitored routine(s) did not complete today: ',
      (SELECT STRING_AGG(routine, ', ' ORDER BY routine)
       FROM `stock-trading-498512.state.cadence_watch` WHERE needs_attention));
  END IF;
END;

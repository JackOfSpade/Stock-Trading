-- SCHEDULED QUERY (fix A3 + 2026-06-22 automation-health additions): the cadence / control-plane
-- dead-man's switch. Complements daily_freshness_check.sql (which catches a stale ENGINE / D2 data work).
-- This one catches the things that "ran or didn't" rather than "data is current":
--   * missed_run            — a MONITORED routine expected today logged no 'completed' run (state.cadence_watch)
--   * backup_stale          — the events.* GCS backup has gone silent (state.backup_health; 16_automation_health.sql)
--   * automation_heartbeat  — an out-of-band Apps Script (alert_emailer / weekly_report) went silent (state.automation_heartbeat)
--   * instruction_drift     — a routine's live web-UI trigger differs from the canonical catalog (state.instruction_drift; W2)
--
-- SELF-BOOTSTRAPPING (see bigquery/12 + 16): every signal here only fires once a routine/backup/script has
-- demonstrably started logging, so this never false-alarms on something not yet adopted.
--
-- RECORD-THEN-RAISE: every condition writes a durable, idempotent ops.alerts row FIRST (so no condition
-- masks another), then a SINGLE consolidated RAISE at the end fires BigQuery's built-in "Send email
-- notifications on failure" — an identity-independent channel that delivers even when the thing that
-- failed is the alert emailer itself. instruction_drift is a config bug to FIX, not a halt, so it records
-- a warning but does NOT contribute to the RAISE (matching the prior behaviour).
--
-- TIMING: BigQuery schedules are UTC. Run ~05:15 UTC (≈ 22:45 MDT / 21:45 MST) — same Denver evening,
-- after D2/D3, like the freshness check. APPLY ORDER: bigquery/16_automation_health.sql must be applied
-- BEFORE re-pasting this query (it references state.backup_health + state.automation_heartbeat). See
-- ops/RUNBOOK.md "Scheduled queries".
BEGIN
  DECLARE raise_msg STRING DEFAULT '';

  -- missed_run (critical) — a monitored routine expected today did not complete.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.cadence_watch` WHERE needs_attention) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.cadence', 'missed_run',
      CONCAT('Cadence check: monitored routine(s) expected today did not complete: ',
             (SELECT STRING_AGG(routine, ', ' ORDER BY routine)
              FROM `stock-trading-498512.state.cadence_watch` WHERE needs_attention)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(routine, schedule, today)))
       FROM `stock-trading-498512.state.cadence_watch` WHERE needs_attention));
    SET raise_msg = raise_msg || CONCAT('[missed_run] ',
      (SELECT STRING_AGG(routine, ', ' ORDER BY routine)
       FROM `stock-trading-498512.state.cadence_watch` WHERE needs_attention), '; ');
  END IF;

  -- backup_stale (critical) — events.* GCS backup has not logged a success in >2 days (16_automation_health.sql).
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.backup_health` WHERE stale) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.cadence', 'backup_stale',
      'Backup check: events.* GCS backup has not logged a successful run in >2 days',
      (SELECT TO_JSON_STRING(t) FROM `stock-trading-498512.state.backup_health` t));
    SET raise_msg = raise_msg || (SELECT CONCAT('[backup_stale] last_backup_date=',
      CAST(last_backup_date AS STRING), '; ') FROM `stock-trading-498512.state.backup_health`);
  END IF;

  -- automation_heartbeat (critical) — an out-of-band Apps Script went silent (16_automation_health.sql).
  -- Delivered via THIS query's DTS failure-email, NOT via the (possibly-dead) alert emailer.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.automation_heartbeat` WHERE stale) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.cadence', 'automation_heartbeat',
      CONCAT('Heartbeat check: out-of-band automation went silent: ',
             (SELECT STRING_AGG(source, ', ' ORDER BY source)
              FROM `stock-trading-498512.state.automation_heartbeat` WHERE stale)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(source, age_hours, max_age_hours, CAST(last_beat_ts AS STRING) AS last_beat_ts)))
       FROM `stock-trading-498512.state.automation_heartbeat` WHERE stale));
    SET raise_msg = raise_msg || CONCAT('[automation_heartbeat] ',
      (SELECT STRING_AGG(source, ', ' ORDER BY source)
       FROM `stock-trading-498512.state.automation_heartbeat` WHERE stale), '; ');
  END IF;

  -- instruction_drift (WARNING, non-raising). The schedule/instruction live only in the web UI;
  -- state.instruction_drift (bigquery/15_routine_catalog.sql) diffs each routine's LIVE logged trigger
  -- against the canonical catalog. A drift is a config bug to fix, not a halt — so it records but does
  -- NOT contribute to the RAISE.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.instruction_drift` WHERE drifted OR unknown_routine) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'instruction_drift',
      CONCAT('Trigger drift: routine(s) whose live web-UI trigger differs from the canonical catalog: ',
             (SELECT STRING_AGG(routine, ', ' ORDER BY routine)
              FROM `stock-trading-498512.state.instruction_drift` WHERE drifted OR unknown_routine)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(routine, drifted, unknown_routine, live_instruction, canonical_instruction)))
       FROM `stock-trading-498512.state.instruction_drift` WHERE drifted OR unknown_routine));
  END IF;

  -- Single consolidated RAISE so the DTS failure-email fires once, AFTER every condition is recorded.
  IF raise_msg != '' THEN
    RAISE USING MESSAGE = CONCAT('STOCK-TRADING cadence/backup/heartbeat check FAILED — ', raise_msg);
  END IF;
END;

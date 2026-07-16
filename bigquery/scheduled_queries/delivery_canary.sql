-- SCHEDULED QUERY (2026-06-28 stack review #2, #15): end-to-end ALERT-DELIVERY canary.
--
-- WHY. Every delivery channel (the DTS failure-email, the alert_emailer Apps Script, the alert-relay
-- webhook) is exercised ONLY by real incidents — so a degradation that is silent precisely because nothing
-- is red right now (a lapsed emailer BigQuery scope, a Gmail send-quota cap, a rotated webhook) would be
-- discovered during the NEXT real incident, the worst possible time. The automation_heartbeat proves the
-- emailer RAN; it does NOT prove GmailApp.sendEmail actually DELIVERED + stamped ops.alerts.notified_ts
-- (the field added by 18). This canary turns notified_ts (written-but-never-asserted today) into a checked
-- end-of-pipeline fact, covering exactly that last slice.
--
-- HOW. Once per week it:
--   1. ASSERTS the PRIOR canary delivered — any canary row aged 2–9 days whose notified_ts is still NULL
--      means the emailer failed to deliver+stamp it within its 48h window → RAISE, so the INDEPENDENT
--      BigQuery email-on-failure (DTS) channel fires (a channel that survives the emailer being the thing
--      that died). The 2-day floor gives the ~2h-poll emailer ample time; the 9-day ceiling bounds it to
--      the prior weekly cycle so a pre-canary-era / already-known gap can't perma-fire.
--   2. EMITS a fresh canary row — severity 'warning' (the emailer only forwards critical/warning), written
--      resolved=TRUE with notified_ts NULL so it stays OUT of state.system_health.open_alerts (no digest
--      noise) while the emailer (which keys on notified_ts IS NULL over the last 48h, RUNBOOK §20) still
--      forwards it and stamps notified_ts. Message is unmistakable self-test text.
--
-- INBOX / IDENTIFICATION: the canary produces one weekly self-email. alert_emailer.gs renders a
-- canary-only batch with an unmistakable subject ("🧪 [TEST] Stock-Trading alert-delivery self-test —
-- no action needed") and a [TEST] body tag, so it is never mistaken for a real alert. Per operator
-- preference (2026-06-29) the test email is left VISIBLE in the inbox — do NOT add a Gmail auto-filter
-- to archive it. The Apps Script still stamps notified_ts on the successful send either way, so the
-- step-1 assertion remains valid.
--
-- ONE-TIME SETUP (ops/RUNBOOK.md §18): create as a WEEKLY scheduled query (e.g. Mon ~05:40 UTC; Location
-- US; no destination), run-as bq-scheduler@ (already writes ops.alerts). Enable "Send email on failure"
-- (that IS the step-1 delivery-failure alarm). Depends on bigquery/18_stack_review_fixes.sql
-- (ops.alerts.notified_ts) + a deployed alert_emailer.gs that stamps notified_ts.
-- SQ_NAME: delivery_canary  SQ_VERSION: v1 (self-improvement audit 2026-07-15, scheduled-query
-- body-drift detection — bigquery/63_scheduled_query_version_registry.sql). Bump SQ_VERSION here AND
-- state.expected_scheduled_query_versions' matching row on any future edit to this file's body.
BEGIN
  CALL `stock-trading-498512.ops.sp_beat_heartbeat`('sq:delivery_canary', 'v1', 'delivery_canary.sql ran');

  -- 1. Emit this week's canary FIRST (resolved + unnotified so it is forwarded-and-stamped but never
  -- an open alert). Reordered ahead of the assertion below (2026-07-04 audit finding): the assertion's
  -- RAISE previously ran first and — RAISE terminating the script — aborted before this INSERT ran,
  -- so a SUSTAINED delivery outage skipped emitting a fresh canary every other week, halving the
  -- canary's effective detection cadence. This INSERT is independent of the assertion below, so
  -- running it unconditionally first means it always happens, RAISE or not.
  INSERT INTO `stock-trading-498512.ops.alerts`
    (severity, source, category, message, payload, resolved, resolved_ts, notified_ts)
  VALUES (
    'warning', 'scheduled.canary', 'delivery_canary',
    CONCAT('[CANARY] Weekly alert-delivery self-test — no action needed (', CAST(CURRENT_DATE('America/Denver') AS STRING), ').'),
    SAFE.PARSE_JSON('{"canary":true}'),
    TRUE, CURRENT_TIMESTAMP(), NULL);

  -- 2. Assert the prior week's canary was delivered (notified_ts stamped).
  IF EXISTS (
    SELECT 1 FROM `stock-trading-498512.ops.alerts`
    WHERE source = 'scheduled.canary' AND category = 'delivery_canary'
      AND notified_ts IS NULL
      AND alert_ts < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 2 DAY)
      AND alert_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 9 DAY)
  ) THEN
    -- Also record it durably (so the relay/digest see it too), then RAISE for the DTS failure-email.
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.canary', 'delivery_failure',
      'Alert-delivery canary: the prior weekly canary was never delivered (notified_ts still NULL after >2 days) — the alert_emailer is not stamping/sending. Verify the Apps Script BigQuery+Gmail scopes and trigger.',
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(alert_id, CAST(alert_ts AS STRING) AS alert_ts)))
       FROM `stock-trading-498512.ops.alerts`
       WHERE source = 'scheduled.canary' AND category = 'delivery_canary' AND notified_ts IS NULL
         AND alert_ts < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 2 DAY)
         AND alert_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 9 DAY)));
    RAISE USING MESSAGE = 'STOCK-TRADING delivery canary FAILED — prior weekly canary undelivered (notified_ts NULL).';
  END IF;
END;

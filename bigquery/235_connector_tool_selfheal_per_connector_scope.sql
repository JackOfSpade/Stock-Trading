-- 235_connector_tool_selfheal_per_connector_scope.sql (2026-09-13)
-- Project: stock-trading-498512. Revises ops.sp_raise_connector_tool_drift (introduced in
-- bigquery/151_connector_tool_inventory.sql, STATEMENT 6). Apply after 151. Supersedes 151's
-- STATEMENT 6 definition ONLY — 151's statements 1-5 and 7+ are unchanged and are still the
-- apply-in-order source for everything else in that file.
--
-- WHAT CHANGES, AND ONLY THIS: block (c) SELF-HEAL's staleness guard goes from FLEET-WIDE to
-- PER-CONNECTOR. Blocks (a), (b) and (d) are reproduced byte-for-byte from 151 and are not touched.
--
-- THE DEFECT (found 2026-09-13 by an adversarial audit of the OPS1 connector_tool_added alert for
-- Google-Cloud-BigQuery.cancel_job / .get_query_results; dormant, never observed firing). 151's
-- block (c) wrapped the whole self-heal UPDATE in
--
--     IF NOT EXISTS (SELECT 1 FROM state.connector_tool_inventory_stale) THEN ... END IF;
--
-- state.connector_tool_inventory_stale emits ONE ROW PER STALE CONNECTOR (plus a synthetic 'ALL'
-- sentinel row, see below). The guard asks "is ANY connector stale?", not "is THE connector this
-- alert is about stale?". So a single connector going stale — enumeration_ok=FALSE, or simply not
-- observed, for more than 4 days — freezes the self-heal for EVERY OTHER connector's alerts too.
-- Those alerts then sit unresolved, re-emailed as recurring, while their manifest edit is already
-- correct and their own drift is already clear. The alert text ("Adding it to the manifest is what
-- clears this alert") gives a triage session no hint that an unrelated connector is the real cause,
-- so the predictable outcome is someone re-verifying a manifest edit that was never wrong.
--
-- NOT hypothetical-by-construction: OPS1 sweeps all 7 connectors each run and writes per-connector
-- enumeration_ok, explicitly failing closed per connector (Claude_Task_Plan.md, TOOL-INVENTORY DRIFT
-- CHECK: "FAIL CLOSED ... record enumeration_ok = FALSE for that connector"). One connector failing
-- to enumerate for >4 days while the other six succeed is an ordinary future state. It simply has
-- not happened yet: verified live 2026-09-13, state.connector_tool_inventory_stale returns 0 rows
-- and all 7 connectors show n_bad=0 with last_seen=2026-09-13 back to 2026-08-09.
--
-- WHY THE 'ALL' ARM IS PRESERVED EXPLICITLY — this is the part a naive fix gets wrong, and it is the
-- difference between a fix and a regression. The obvious rewrite is a correlated
--     AND NOT EXISTS (SELECT 1 FROM ...stale s WHERE s.connector = JSON_VALUE(payload,'$.connector'))
-- and that DROPS the view's synthetic 'ALL' sentinel row, which is emitted when NOTHING has
-- enumerated successfully anywhere in 4 days (151 STATEMENT 4's second UNION arm). 'ALL' never equals
-- a real connector name, so under that rewrite a TOTAL OPS1 outage would stop blocking self-heal
-- entirely. That is strictly worse than the bug being fixed, because state.connector_tool_latest —
-- which feeds state.connector_tool_drift — is itself windowed to the trailing 30 days: once nothing
-- has enumerated for 30+ days the drift view goes EMPTY, the `NOT EXISTS (... connector_tool_drift)`
-- clause becomes vacuously TRUE for every row, and the self-heal would mass-resolve every open
-- connector_tool_added/removed alert off pure absence of data. That is exactly the "absence reads as
-- healthy" trap this project has been bitten by before (liveness must rest on positive evidence).
-- So the guard below is: stale if the 'ALL' sentinel is present, OR if THIS alert's own connector is
-- listed. Do NOT "simplify" the `s.connector = 'ALL' OR` away.
--
-- Folding the guard into the UPDATE's WHERE rather than keeping an outer IF is what makes it
-- per-row-correlatable at all — an outer IF cannot see the row being considered.
--
-- NO registry row needed: this procedure is not `sp_sq_`-prefixed and is not a scheduled query; it is
-- CALLed by OPS1. Mirrors 151's own header note to the same effect.

CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_raise_connector_tool_drift`(in_source STRING)
BEGIN
  DECLARE latest_run_date DATE;

  -- (a) added — a tool the connector now exposes that the manifest does not know about. This is the
  -- new-tool-defaults-to-ask case: an unattended routine that happens to call it hits a permission
  -- prompt nobody can answer and silently stalls.
  FOR rec IN (
    SELECT connector, tool_name, manifest_use, observed_run_date
    FROM `stock-trading-498512.state.connector_tool_drift`
    WHERE drift_kind = 'added'
  ) DO
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', in_source, 'connector_tool_added',
      CONCAT('New connector tool not in the manifest: ', rec.connector, '.', rec.tool_name, ' — set it to Always allow in the claude.ai connector settings if the fleet should use it, then add it to ops/connector_tools.yaml. Adding it to the manifest is what clears this alert.'),
      TO_JSON_STRING(STRUCT(rec.connector AS connector, rec.tool_name AS tool_name, 'added' AS drift_kind,
                             rec.manifest_use AS manifest_use, rec.observed_run_date AS observed_run_date)));
  END FOR;

  -- (b) removed — a tool the manifest expects that has vanished. severity is passed through from the
  -- view (critical when the fleet actively calls it and it is gone, otherwise warning).
  FOR rec IN (
    SELECT connector, tool_name, severity, manifest_use, observed_run_date
    FROM `stock-trading-498512.state.connector_tool_drift`
    WHERE drift_kind = 'removed'
  ) DO
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      rec.severity, in_source, 'connector_tool_removed',
      CONCAT('Connector tool in the manifest has disappeared: ', rec.connector, '.', rec.tool_name, ' (manifest use: ', rec.manifest_use, ') — routine text that calls it will now fail. Remove it from ops/connector_tools.yaml or restore it in the claude.ai connector settings.'),
      TO_JSON_STRING(STRUCT(rec.connector AS connector, rec.tool_name AS tool_name, 'removed' AS drift_kind,
                             rec.manifest_use AS manifest_use, rec.observed_run_date AS observed_run_date)));
  END FOR;

  -- (c) SELF-HEAL — resolve any unresolved alert in these two categories whose (connector, tool) pair no
  -- longer appears in state.connector_tool_drift (the operator updated the manifest, or the tool came
  -- back). The staleness guard is PER-CONNECTOR (revised 2026-09-13, this file): an alert self-heals
  -- only when its OWN connector has a trustworthy recent reading, so one stale connector no longer
  -- freezes the others. The `s.connector = 'ALL'` arm keeps the fleet-wide sentinel blocking
  -- everything during a total enumeration outage — see this file's header for why removing it would
  -- be a regression, not a simplification.
  UPDATE `stock-trading-498512.ops.alerts`
  SET resolved = TRUE, resolved_ts = CURRENT_TIMESTAMP(),
      resolved_note = CONCAT('verified-clear: connector tool drift no longer present on state.connector_tool_drift. ', COALESCE(resolved_note, ''))
  WHERE NOT resolved
    AND category IN ('connector_tool_added', 'connector_tool_removed')
    AND NOT EXISTS (
      SELECT 1 FROM `stock-trading-498512.state.connector_tool_drift` d
      WHERE d.connector = JSON_VALUE(payload, '$.connector')
        AND d.tool_name = JSON_VALUE(payload, '$.tool_name'))
    AND NOT EXISTS (
      SELECT 1 FROM `stock-trading-498512.state.connector_tool_inventory_stale` s
      WHERE s.connector = 'ALL'
         OR s.connector = JSON_VALUE(payload, '$.connector'));

  -- (d) enumeration_ok=FALSE watch — raise once (warning) if the most recent run_date in the table has
  -- any connector that could not be reliably enumerated, naming the affected connectors so the operator
  -- knows state.connector_tool_drift is untrustworthy for them until the next clean run.
  SET latest_run_date = (SELECT MAX(run_date) FROM `stock-trading-498512.ops.connector_tool_inventory`);
  IF EXISTS (
    SELECT 1 FROM `stock-trading-498512.ops.connector_tool_inventory`
    WHERE run_date = latest_run_date AND NOT enumeration_ok
  ) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', in_source, 'connector_tool_enumeration_failed',
      (SELECT CONCAT('Connector tool inventory could not be reliably enumerated for: ',
                      STRING_AGG(DISTINCT connector, ', ' ORDER BY connector),
                      ' — drift readings for these connectors are untrustworthy until the next clean run.')
       FROM `stock-trading-498512.ops.connector_tool_inventory`
       WHERE run_date = latest_run_date AND NOT enumeration_ok),
      (SELECT TO_JSON_STRING(STRUCT(latest_run_date AS run_date,
                                     ARRAY_AGG(DISTINCT connector ORDER BY connector) AS connectors))
       FROM `stock-trading-498512.ops.connector_tool_inventory`
       WHERE run_date = latest_run_date AND NOT enumeration_ok));
  END IF;
END;

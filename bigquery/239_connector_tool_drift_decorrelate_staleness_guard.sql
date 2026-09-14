-- 239_connector_tool_drift_decorrelate_staleness_guard.sql (2026-09-14)
-- Project: stock-trading-498512. Revises ops.sp_raise_connector_tool_drift (introduced in
-- bigquery/151_connector_tool_inventory.sql STATEMENT 6, last revised in
-- bigquery/235_connector_tool_selfheal_per_connector_scope.sql). Apply after 235. Supersedes 235's
-- procedure definition ONLY — 151's statements 1-5 and 7+, and every other object, are unchanged.
--
-- WHAT CHANGES, AND ONLY THIS: block (c)'s PER-CONNECTOR staleness guard is resolved into two script
-- locals (`stale_all`, `stale_connectors`) and applied as an outer IF plus a `NOT IN UNNEST(...)`
-- predicate, instead of 235's correlated `NOT EXISTS` against state.connector_tool_inventory_stale.
-- Blocks (a), (b) and (d) are reproduced byte-for-byte from 235 and are not touched. The INTENDED
-- SEMANTICS OF 235 ARE PRESERVED EXACTLY, including the 'ALL' sentinel arm 235's header insists on.
--
-- THE DEFECT (found 2026-09-14 by OPS1, at the point of use — the first run that ever CALLed 235).
-- 235 wrote the guard as:
--
--     AND NOT EXISTS (
--       SELECT 1 FROM state.connector_tool_inventory_stale s
--       WHERE s.connector = 'ALL' OR s.connector = JSON_VALUE(payload, '$.connector'))
--
-- BigQuery rejects that AT RUNTIME with: "Correlated subqueries that reference other tables are not
-- supported unless they can be de-correlated, such as by transforming them into an efficient JOIN."
-- state.connector_tool_inventory_stale is a UNION of an aggregate and a synthetic 'ALL' sentinel row
-- (151 STATEMENT 4), and a correlated subquery over that shape cannot be rewritten as a JOIN.
--
-- WHY THIS SHIPPED GREEN AND BROKE ANYWAY — the trap worth remembering: **CREATE OR REPLACE PROCEDURE
-- does not validate the body.** DDL succeeded, CI passed (the dry-run gate dry-runs the CREATE, not a
-- CALL), and the defect stayed invisible until something actually CALLed the procedure. 235 landed
-- 2026-09-13 AFTER that day's OPS1 run had already raised its two connector_tool_added alerts, so
-- OPS1 2026-09-14 was the first CALL — and it failed outright, taking the whole TOOL-INVENTORY DRIFT
-- CHECK with it (no raise, no self-heal). A procedure whose only caller is a once-daily routine has a
-- blast radius of one full day per defect, and no test between landing and firing.
--
-- DE MORGAN IS NOT THE FIX — verified empirically 2026-09-14, do not retry it. Splitting the OR into
--     AND NOT EXISTS (... WHERE s.connector = 'ALL')
--     AND NOT EXISTS (... WHERE s.connector = JSON_VALUE(payload, '$.connector'))
-- is logically identical and WAS APPLIED AND RE-CALLED: it failed with the identical error, because
-- the CORRELATION ITSELF is what BigQuery cannot de-correlate here, not the disjunction. Resolving
-- the view into locals first is what actually removes the correlation.
--
-- WHY THE (connector, tool_name) NOT EXISTS IS DELIBERATELY LEFT CORRELATED. The other subquery in
-- this UPDATE — against state.connector_tool_drift — is a plain conjunction of equality predicates,
-- de-correlates into a JOIN without complaint, and has run unchanged since bigquery/151 went live
-- 2026-08-08. It is not the fault and must not be "fixed" alongside; rewriting it would be churn on
-- the one clause with a year of green history.
--
-- WHY `COALESCE(JSON_VALUE(payload,'$.connector'), '')`. Under 235's NOT EXISTS form, an alert whose
-- payload carries no connector key simply matched nothing and was therefore NOT blocked from healing.
-- A bare `JSON_VALUE(...) NOT IN UNNEST(...)` would instead evaluate to NULL for that row, silently
-- excluding it from the UPDATE forever — a latent never-heals bug introduced by the fix itself. The
-- COALESCE to '' (never a real connector name) reproduces 235's behaviour exactly.
--
-- THE 'ALL' SENTINEL ARM IS PRESERVED, as an outer `IF NOT stale_all THEN`. 235's header explains at
-- length why dropping it would be a regression rather than a simplification (during a TOTAL
-- enumeration outage state.connector_tool_latest ages out of its 30-day window, state.connector_tool_drift
-- goes EMPTY, and self-heal would mass-resolve every open connector_tool_added/removed alert off pure
-- absence of data — the "absence reads as healthy" trap). That reasoning is unchanged and still
-- binding here: do NOT remove the stale_all guard.
--
-- NO registry row needed: this procedure is not `sp_sq_`-prefixed and is not a scheduled query; it is
-- CALLed by OPS1. Mirrors 151's and 235's own header notes to the same effect.
--
-- APPLIED LIVE 2026-09-14 by OPS1 via the BigQuery MCP, and verified by re-CALLing it: the call
-- succeeded, raised nothing (0 added / 0 removed / 0 enumeration failures across all 7 connectors on
-- 123 observed tools), and block (c) correctly self-healed the two open Google-Cloud-BigQuery
-- connector_tool_added alerts from 2026-09-13 (3c018514 cancel_job, 6db3f571 get_query_results) at
-- 18:46:16 UTC, their manifest rows having landed in d958b8b.

CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_raise_connector_tool_drift`(in_source STRING)
BEGIN
  DECLARE latest_run_date DATE;
  DECLARE stale_all BOOL;
  DECLARE stale_connectors ARRAY<STRING>;

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
  -- back). The staleness guard is PER-CONNECTOR (bigquery/235, 2026-09-13): an alert self-heals only
  -- when its OWN connector has a trustworthy recent reading, so one stale connector no longer freezes
  -- the others; the 'ALL' sentinel still blocks everything during a total enumeration outage.
  --
  -- THE STALENESS GUARD IS RESOLVED INTO LOCALS FIRST, AND MUST STAY THAT WAY (2026-09-14,
  -- bigquery/239). 235 expressed it as a correlated NOT EXISTS against
  -- state.connector_tool_inventory_stale, which BigQuery REJECTS AT RUNTIME: "Correlated subqueries
  -- that reference other tables are not supported unless they can be de-correlated". That view is a
  -- UNION of an aggregate and a synthetic 'ALL' sentinel row, and a correlated subquery over it
  -- cannot be turned into a JOIN. DDL does not catch this — CREATE OR REPLACE PROCEDURE succeeds and
  -- the body fails only when CALLed — so 235 was committed green and broke OPS1's drift step on the
  -- first run that called it (2026-09-14). Splitting the OR by De Morgan is NOT sufficient; the
  -- correlation itself is the problem. The (connector, tool_name) NOT EXISTS against
  -- state.connector_tool_drift below is a plain equality correlation, de-correlates fine, and has run
  -- since bigquery/151 — it is deliberately left alone.
  --
  -- Semantics preserved exactly: self-heal only when the 'ALL' sentinel is absent AND this alert's own
  -- connector is not listed stale. COALESCE keeps a payload with no connector key behaving as it did
  -- under 235's NOT EXISTS form (no match -> not blocked) instead of going NULL and silently never
  -- healing. Do NOT re-inline these into a correlated subquery.
  SET stale_all = EXISTS (
    SELECT 1 FROM `stock-trading-498512.state.connector_tool_inventory_stale` WHERE connector = 'ALL');
  SET stale_connectors = ARRAY(
    SELECT connector FROM `stock-trading-498512.state.connector_tool_inventory_stale`
    WHERE connector IS NOT NULL);

  IF NOT stale_all THEN
    UPDATE `stock-trading-498512.ops.alerts`
    SET resolved = TRUE, resolved_ts = CURRENT_TIMESTAMP(),
        resolved_note = CONCAT('verified-clear: connector tool drift no longer present on state.connector_tool_drift. ', COALESCE(resolved_note, ''))
    WHERE NOT resolved
      AND category IN ('connector_tool_added', 'connector_tool_removed')
      AND COALESCE(JSON_VALUE(payload, '$.connector'), '') NOT IN UNNEST(stale_connectors)
      AND NOT EXISTS (
        SELECT 1 FROM `stock-trading-498512.state.connector_tool_drift` d
        WHERE d.connector = JSON_VALUE(payload, '$.connector')
          AND d.tool_name = JSON_VALUE(payload, '$.tool_name'));
  END IF;

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

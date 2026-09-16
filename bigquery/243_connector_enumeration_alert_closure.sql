-- 243_connector_enumeration_alert_closure.sql (2026-09-16)
-- Project: stock-trading-498512. Revises ops.sp_raise_connector_tool_drift (introduced in
-- bigquery/151_connector_tool_inventory.sql STATEMENT 6, revised in
-- bigquery/235_connector_tool_selfheal_per_connector_scope.sql, last revised in
-- bigquery/239_connector_tool_drift_decorrelate_staleness_guard.sql). Apply after 239. Supersedes
-- 239's procedure definition ONLY — 151's statements 1-5 and 7+, and every other object, are
-- unchanged. Also registers one new ops.alert_policy row.
--
-- GENERATED, NOT RETYPED. This file's procedure body was produced by a Python script performing two
-- exact-string transformations against bigquery/239's own body text (read off disk, never
-- hand-copied): (1) insert one new `DECLARE clean_connectors ARRAY<STRING>;` line immediately after
-- the existing `DECLARE stale_connectors ARRAY<STRING>;` line, and (2) insert one new block (e),
-- verbatim below, between block (d)'s closing `END IF;` and the procedure's final `END;`. Blocks
-- (a), (b), (c) and (d) are reproduced BYTE-FOR-BYTE from 239 and are not touched — verified by a
-- unified diff of the two bodies showing exactly those two hunks and nothing else (reported in this
-- change's summary). This mirrors 239's and 235's own "supersedes ONLY this, reproduced byte-for-
-- byte" discipline and this repo's standing rule that a carried-forward procedure body (bigquery/63's
-- cadence_check registry note) is transformed programmatically, never retyped from memory.
--
-- THE DEFECT (measured 2026-09-16). Block (d) raises category 'connector_tool_enumeration_failed'
-- (warning) whenever the newest run_date in ops.connector_tool_inventory has any connector with
-- enumeration_ok = FALSE. Nothing has ever closed it:
--   * block (c)'s self-heal UPDATE lists only 'connector_tool_added' and 'connector_tool_removed' —
--     'connector_tool_enumeration_failed' was never in scope for it;
--   * ops.alert_policy has ZERO rows for any connector-prefixed category — verified live
--     2026-09-16: `SELECT category FROM ops.alert_policy WHERE category LIKE 'connector%'` returns
--     no rows at all;
--   * it is absent from the 7-day auto-age allowlist inside ops.sp_sq_cadence_check (bigquery/241's
--     `category IN (...)` list carries 'connector' and 'connector_tool_inventory_stale' but not this
--     category);
--   * ops.sp_auto_resolve_alerts is hardcoded to missing_dependency / missed_run / routine_stalled /
--     catchup_refire_blocked / staleness / six roster notices only, none of which match.
-- So a raised row sits open forever. Worse, because ops.sp_raise_alert_once dedups on exact
-- (category, message) over UNRESOLVED rows, a stuck open row also SUPPRESSES a later genuine
-- re-raise whose connector set happens to render the same message — the stuck row jams its own
-- detector, exactly the shape this repo's own "alert closure paths must be reachable" precedent
-- warns about.
--
-- LIVE RIGHT NOW, verified 2026-09-16: ops.alerts fa114bbc-ca6f-40f3-a0ce-ab902089acc3, category
-- connector_tool_enumeration_failed, unresolved, message "Connector tool inventory could not be
-- reliably enumerated for: Tavily — drift readings for these connectors are untrustworthy until the
-- next clean run.", payload {"connectors":["Tavily"],"run_date":"2026-09-16"}. Root cause: the
-- Tavily connector's OAuth token has expired account-wide (confirmed from an interactive session
-- too, not container-specific) and needs an owner re-consent — that is a separate, out-of-scope
-- fix. This file's job is only that once Tavily (or any other connector) enumerates cleanly again,
-- the alert that named it actually closes.
--
-- THE SIXTH INSTANCE OF AN ALREADY-FIXED BUG CLASS. bigquery/63_scheduled_query_version_registry.sql's
-- cadence_check git_note documents the identical "raised category with no closure path" defect for
-- five prior sibling categories, each fixed by adding the category to the #14 auto-age allowlist:
-- v15 (connector, strategy_revised; bigquery/150), v16 (connector_tool_inventory_stale; bigquery/150/
-- 151), v17 (account_snapshot_gap; bigquery/153), and v21 (monitor_promoted; bigquery/186, applied via
-- bigquery/230/241's carried-forward allowlist). This file is deliberately the odd one out: it closes
-- the SAME class of defect with a CONDITION-KEYED resolve instead of the age-out pattern all five
-- precedents used. See below for why.
--
-- WHY CONDITION-KEYED, NOT THE 7-DAY AUTO-AGE ALLOWLIST — the choice this file's header exists to
-- justify, since every precedent above (and bigquery/241's queue_driven_missed_fire, the most recent
-- instance of this bug class) used age-out instead. Age-out is the right tool exactly when there is
-- no condition left to check: monitor_promoted is a receipt for a promotion that already happened
-- (idempotent by construction — ops.monitor_promotion_log makes it permanently true, so there is
-- nothing to re-verify), and queue_driven_missed_fire's missed date is immutable history (2026-09-14
-- stays a day M1R did not log, forever — no future run can ever back-fill it). connector_tool_
-- enumeration_failed is the opposite shape: it reports a TRANSIENT, RE-CHECKABLE condition ("was the
-- most recent enumeration trustworthy for this connector") that genuinely heals the moment OPS1 next
-- enumerates it cleanly — the exact same shape as connector_tool_inventory_stale and
-- scheduled_query_version_drift, both of which this repo already treats as self-healing-with-a-
-- condition rather than as a permanent receipt. A future clean enumeration is POSITIVE, checkable
-- evidence that the specific thing the alert complained about is no longer true; there is no
-- analogous positive evidence for "M1R logged on 2026-09-14" ever appearing. Age-out would also have
-- a materially larger blast radius here than the fix this file actually makes: bumping
-- ops.sp_sq_cadence_check's #14 allowlist means bumping its own heartbeat literal (v23 -> v24, per
-- bigquery/241's own LOCKSTEP note) and bigquery/63's matching registry MERGE — a change to the
-- FLEET-WIDE cadence dead-man's-switch procedure that every other monitored routine also depends on —
-- to fix a defect that is entirely local to one small procedure with a single caller (OPS1). A
-- condition-keyed fix inside ops.sp_raise_connector_tool_drift itself touches nothing outside that
-- procedure and carries none of the registry-lockstep partial-apply risk bigquery/63's own note
-- documents recurring at v9/v14/v15/v16/v17/v18/v22-v23 (and scripts/apply_sql_file.py's REGISTRY
-- LOCKSTEP REMINDER section, v23 recurrence, 2026-09-16).
--
-- WHAT CHANGES, AND ONLY THIS: one new block (e), appended after block (d) and before the procedure's
-- closing END, plus one new script local (`clean_connectors`) declared alongside the existing three.
-- Blocks (a), (b), (c) (both its existing categories and its per-connector staleness guard) and (d)
-- keep their EXACT current behaviour, predicates and text — see the GENERATED, NOT RETYPED note above
-- for how that was verified mechanically rather than by eyeballing a hand-edit.
--
-- POSITIVE EVIDENCE, NEVER AN ABSENCE TEST — this repo's own standing rule (liveness must rest on
-- positive evidence; absence of a row reads as healthy in both directions, which is exactly backwards
-- for a dead-man's-switch-adjacent check). Block (e)'s `clean_connectors` local is built with
-- `GROUP BY connector ... HAVING LOGICAL_AND(enumeration_ok)` over ops.connector_tool_inventory at
-- the newest run_date: a connector lands in that array ONLY if the table actually HAS a row for it at
-- that run_date AND every row it has there is enumeration_ok = TRUE. An EMPTY inventory table (no
-- rows at all — latest_run_date is NULL, guarded by the outer `IF latest_run_date IS NOT NULL`) or a
-- newest run that simply does not MENTION a given connector both produce zero evidence for that
-- connector, not positive evidence of health, and neither can put it in clean_connectors.
--
-- RESOLVES ONLY ROWS WHOSE OWN NAMED CONNECTORS ARE ALL CLEAN NOW, read from the payload the alert
-- itself carries (`$.connectors`, the JSON array block (d) writes via
-- `TO_JSON_STRING(STRUCT(... ARRAY_AGG(DISTINCT connector ...) AS connectors))`) — never from the
-- free-text message. An alert that named "Tavily, FMP" and saw only FMP recover stays OPEN: the
-- `NOT EXISTS (... WHERE ... NOT IN UNNEST(clean_connectors))` predicate fails closed the instant any
-- ONE named connector is absent from clean_connectors. A `COALESCE(ARRAY_LENGTH(...), 0) > 0` guard
-- additionally refuses to resolve a row whose payload carries no connectors array (or an empty one) —
-- without it, `NOT EXISTS` over zero candidate rows is vacuously TRUE and would resolve a malformed
-- alert on no evidence at all, the same absence-reads-as-healthy trap one layer down.
--
-- resolved_note follows block (c)'s own "verified-clear: ..." convention, naming the run_date that
-- supplied the evidence, so a later reader can see exactly which enumeration justified the close —
-- matching this repo's rule that a correction must land where routines actually read it, with a
-- receipt of what was checked, not merely that something was checked.
--
-- ops.alert_policy REGISTRATION (this file, guarded by the same NOT EXISTS idiom bigquery/241 uses
-- for its own alert_policy INSERT, so re-applying this file is a no-op the second time). latching =
-- FALSE, and resolve_rule describes the condition-keyed path above in full rather than pointing at an
-- age-out interval, since there is none here.
--
-- NO registry row / no heartbeat-version bump needed: this procedure is not `sp_sq_`-prefixed and is
-- not itself a scheduled query — it is CALLed by OPS1, exactly as 151/235/239 already note. This
-- file changes nothing about ops.sp_sq_cadence_check or bigquery/63's registry.
--
-- APPLY ORDER: after bigquery/239 (the procedure body this carries forward) and after
-- bigquery/34_alert_lifecycle.sql (ops.alert_policy) / bigquery/10_observability.sql
-- (ops.sp_raise_alert_once). Idempotent and safe to re-apply: the CREATE OR REPLACE is total and the
-- alert_policy INSERT is guarded on NOT EXISTS, matching bigquery/241's own idempotency statement.
--
-- APPLIED LIVE: NOT YET as of 2026-09-16 — this file is staged. Applying it will make
-- scripts/check_live_sql_parity.py report exactly one mismatched object
-- (ops.sp_raise_connector_tool_drift, live body still 239's) until the CREATE statement below is
-- applied; that is expected and is the operator's cue to apply it, not a defect in this file.

CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_raise_connector_tool_drift`(in_source STRING)
BEGIN
  DECLARE latest_run_date DATE;
  DECLARE stale_all BOOL;
  DECLARE stale_connectors ARRAY<STRING>;
  DECLARE clean_connectors ARRAY<STRING>;

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

  -- (e) SELF-HEAL for connector_tool_enumeration_failed (added 2026-09-16, bigquery/243) -- resolve
  -- an open enumeration-failure alert once EVERY connector it named has come back with a clean,
  -- POSITIVE reading on the most recent enumeration run. Deliberately a SEPARATE block from (c)
  -- above, not folded into it: (c)'s guard asks whether an alert's OWN connector should be BLOCKED
  -- from healing (staleness); this asks whether the condition the alert reported has ITSELF gone
  -- away. There is no state.connector_tool_drift-shaped view to re-check here -- only
  -- ops.connector_tool_inventory's own newest run_date -- so the two self-heals read different
  -- evidence and cannot share a guard or a WHERE clause.
  --
  -- POSITIVE EVIDENCE ONLY, never absence -- this repo has been bitten before by absence reading as
  -- healthy in both directions, and that is exactly the trap a naive "no longer reported as bad"
  -- read would fall into here. clean_connectors is built with GROUP BY connector ... HAVING
  -- LOGICAL_AND(enumeration_ok): a connector appears in it ONLY if ops.connector_tool_inventory
  -- actually HAS at least one row for it at latest_run_date, AND every row it has there is
  -- enumeration_ok = TRUE. A connector with NO row at latest_run_date -- an empty table, or a run
  -- that simply never mentions it -- produces no group at all and is therefore never treated as
  -- clean; a connector with a MIX of TRUE and FALSE rows at latest_run_date also fails
  -- LOGICAL_AND and is correctly excluded. Absence cannot resolve anything here.
  SET clean_connectors = ARRAY(
    SELECT connector
    FROM `stock-trading-498512.ops.connector_tool_inventory`
    WHERE run_date = latest_run_date
    GROUP BY connector
    HAVING LOGICAL_AND(enumeration_ok)
  );

  -- Resolve only when EVERY connector named in the alert's OWN payload (block (d)'s
  -- ARRAY_AGG(DISTINCT connector ...) AS connectors, read back here with JSON_VALUE_ARRAY -- payload
  -- is JSON, the same column the JSON_VALUE(payload, '$.connector') idiom in (c) already reads) is
  -- now in clean_connectors. An alert that named "Tavily, FMP" stays OPEN if only FMP recovered:
  -- NOT EXISTS below fails closed the instant any ONE named connector is missing from
  -- clean_connectors, so a partial recovery can never resolve the row. The
  -- COALESCE(ARRAY_LENGTH(...), 0) > 0 guard separately refuses to resolve a row whose payload
  -- carries no connectors array at all, or an empty one -- NOT EXISTS over zero candidate rows is
  -- vacuously TRUE, and without this guard that vacuous truth would resolve a malformed alert on no
  -- evidence whatsoever, the same absence-reads-as-healthy trap the POSITIVE EVIDENCE note above
  -- already guards against one layer down.
  IF latest_run_date IS NOT NULL THEN
    UPDATE `stock-trading-498512.ops.alerts`
    SET resolved = TRUE, resolved_ts = CURRENT_TIMESTAMP(),
        resolved_note = CONCAT('verified-clear: every connector named in this alert enumerated cleanly (enumeration_ok=TRUE for every tool observed, no failures) on run_date ', CAST(latest_run_date AS STRING), '. ', COALESCE(resolved_note, ''))
    WHERE NOT resolved
      AND category = 'connector_tool_enumeration_failed'
      AND COALESCE(ARRAY_LENGTH(JSON_VALUE_ARRAY(payload, '$.connectors')), 0) > 0
      AND NOT EXISTS (
        SELECT 1 FROM UNNEST(JSON_VALUE_ARRAY(payload, '$.connectors')) AS named_connector
        WHERE COALESCE(named_connector, '') NOT IN UNNEST(clean_connectors));
  END IF;
END;


-- =====================================================================================================
-- ops.alert_policy registration for the new category.
--
-- NON-LATCHING, closed by the CONDITION-KEYED path block (e) above implements, not by age-out — see
-- this file's header for why that is the deliberate departure from every sibling category (connector,
-- connector_tool_inventory_stale, account_snapshot_gap, monitor_promoted, queue_driven_missed_fire)
-- this repo has fixed the same way before. Guarded by the same NOT EXISTS idiom bigquery/241 uses for
-- its own alert_policy INSERT, so re-applying this file a second time is a no-op.
-- =====================================================================================================

INSERT INTO `stock-trading-498512.ops.alert_policy` (category, latching, resolve_rule, note)
SELECT p.category, p.latching, p.resolve_rule, p.note
FROM UNNEST([
  STRUCT('connector_tool_enumeration_failed' AS category, FALSE AS latching,
         'CONDITION-KEYED, closed by ops.sp_raise_connector_tool_drift block (e) (bigquery/243_connector_enumeration_alert_closure.sql), NOT by any auto-age allowlist. Resolves an open row only when the newest run_date in ops.connector_tool_inventory has a POSITIVE clean reading (GROUP BY connector HAVING LOGICAL_AND(enumeration_ok)) for EVERY connector named in the alert\'s own JSON payload ($.connectors) -- an alert naming two connectors stays open until BOTH have recovered, and an empty or absent inventory reading never resolves anything (positive evidence only, never an absence test). This procedure is CALLed by OPS1 (not a scheduled query), so it re-evaluates on OPS1\'s own cadence with no separate cron of its own. DO NOT resolve this row by hand while the connector(s) it names are still failing to enumerate -- check ops.connector_tool_inventory for the newest run_date first; a manual resolve ahead of a genuine clean run would only let the next bad enumeration re-mint a fresh alert (sp_raise_alert_once dedups only over UNRESOLVED rows).' AS resolve_rule,
         'CONNECTOR TOOL ENUMERATION FAILED, registered 2026-09-16 alongside the self-heal that closes it. Raised (bigquery/151/235/239, block (d), unchanged by this file) when the newest ops.connector_tool_inventory run_date has any connector with enumeration_ok=FALSE, naming the affected connector(s) -- drift readings for them are untrustworthy until the next clean run. This category existed with NO closure path at all from 2026-08-08 (bigquery/151) through 2026-09-16: not in ops.alert_policy, not on the sp_sq_cadence_check 7-day auto-age allowlist, and not handled by ops.sp_auto_resolve_alerts, so a raised row stayed open forever and its exact-message dedup could suppress a later genuine re-raise for the same connector set. First live instance: ops.alerts fa114bbc-ca6f-40f3-a0ce-ab902089acc3, 2026-09-16, Tavily OAuth token expiry (owner re-consent required; separate from this fix).' AS note)
]) AS p
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.ops.alert_policy` e WHERE e.category = p.category
);

-- 151_connector_tool_inventory.sql (2026-08-08)
-- Project: stock-trading-498512.
-- ===== WHY =====
-- OPS1 (ops/cadence.yaml) probes exactly ONE tool per connector every pre-market morning to prove that
-- connector is authenticated (IBKR/Calendar/FMP/Gmail read-only liveness). That proves the connector
-- session is live and says NOTHING about the other ~99 tools each connector exposes
-- (scripts/check_settings_toolcov.py's header states this exact gap on the sibling axis: a tool a
-- routine calls that was never allowlisted at all). When a connector VENDOR ships a brand-new tool, it
-- arrives in the claude.ai connectors UI defaulted to ask / needs approval — not silently blocked, not
-- silently allowed. An unattended scheduled routine that happens to call that new tool mid-run then hits
-- a permission prompt with nobody there to answer it, and the routine silently stalls: no error, no
-- alert, just a session that never completes and a missed_run the cadence watch eventually raises hours
-- later with no indication of WHY. ops/RUNBOOK.md section 15a documents the per-tool allow/ask/block
-- matrix and its warning that a group label flip is not proof anyone changed a needed permission — the
-- same blind spot, one layer up.
--
-- This file adds the observation record and the drift surface for the FULL per-connector tool
-- inventory (not just the one OPS1-probed tool). The repo baseline is ops/connector_tools.yaml — the
-- version-controlled EXPECTED inventory a human reconciles by hand; this file's tables/views are the
-- LIVE observation side, diffed against that baseline. There is NO scheduled-query wrapper in this
-- file, so no bigquery/63 scheduled-query version registry row is needed for THIS file (that registry
-- only tracks ops.sp_sq_* wrapper procedures via SQ_VERSION heartbeats).
--
-- Apply after 10_observability.sql (ops.alerts, ops.sp_raise_alert_once).

-- ===== STATEMENT 1: ops.connector_tool_inventory =====
-- Append-only observation record. One run writes the UNION of observed-and-manifest tools for every
-- connector it can enumerate, so an absent tool is a row (present=FALSE), never an inference from a
-- missing row — the same discipline state.append_only_integrity's sibling tables already follow.
-- enumeration_ok=FALSE marks a run that could not reliably enumerate a given connector's tools; rows
-- from such a run are untrustworthy and MUST NOT be read as drift evidence (see state.connector_tool_
-- latest below, which excludes them entirely rather than trying to interpret them).
CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.connector_tool_inventory` (
  observed_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  run_date DATE NOT NULL,
  routine STRING NOT NULL,
  connector STRING NOT NULL,          -- matches ops/connector_tools.yaml connectors[].name
  tool_name STRING NOT NULL,
  present BOOL NOT NULL,              -- observed in the running session's tool inventory
  in_manifest BOOL NOT NULL,          -- listed in ops/connector_tools.yaml
  manifest_use STRING,                -- required | optional | unused; NULL when not in manifest
  enumeration_ok BOOL NOT NULL,       -- FALSE = this connector could not be reliably enumerated this run
  note STRING
) PARTITION BY run_date CLUSTER BY connector, tool_name
OPTIONS(description='Append-only per-connector-per-tool observation record. One run writes the UNION of observed-and-manifest tools per connector, so an absent tool is a row (present=FALSE), not an inference from a missing row. enumeration_ok=FALSE marks a run that could not reliably enumerate that connector; its rows are untrustworthy and must not be read as drift evidence.');

-- ===== STATEMENT 2: state.connector_tool_latest =====
-- The most recent TRUSTWORTHY observation per (connector, tool_name). Only run_date values where that
-- connector's enumeration_ok=TRUE are eligible, so a bad-enumeration run can never shadow a good one.
CREATE OR REPLACE VIEW `stock-trading-498512.state.connector_tool_latest` AS
SELECT
  connector, tool_name, observed_ts, run_date AS observed_run_date, routine,
  present, in_manifest, manifest_use, enumeration_ok, note
FROM (
  SELECT
    connector, tool_name, observed_ts, run_date, routine,
    present, in_manifest, manifest_use, enumeration_ok, note,
    ROW_NUMBER() OVER (PARTITION BY connector, tool_name ORDER BY observed_ts DESC) AS rn
  FROM `stock-trading-498512.ops.connector_tool_inventory`
  WHERE enumeration_ok
    AND run_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 30 DAY)
)
WHERE rn = 1;

-- ===== STATEMENT 3: state.connector_tool_drift =====
-- Rows needing attention. added = the connector now exposes a tool the manifest does not know about
-- (the new-tool-defaults-to-ask case). removed = the manifest expects a tool that has vanished — but
-- ONLY when the manifest says something depends on it (required/optional); a manifest tool marked
-- unused that vanishes is deliberately NOT drift, since nothing depends on it. severity is critical
-- only when the fleet actively calls the vanished tool (removed AND manifest_use=required) — every
-- other case is a warning.
CREATE OR REPLACE VIEW `stock-trading-498512.state.connector_tool_drift` AS
SELECT
  connector, tool_name, drift_kind,
  CASE WHEN drift_kind = 'removed' AND manifest_use = 'required' THEN 'critical' ELSE 'warning' END AS severity,
  manifest_use, observed_run_date, CURRENT_TIMESTAMP() AS checked_at
FROM (
  SELECT connector, tool_name, manifest_use, observed_run_date, 'added' AS drift_kind
  FROM `stock-trading-498512.state.connector_tool_latest`
  WHERE present AND NOT in_manifest
  UNION ALL
  SELECT connector, tool_name, manifest_use, observed_run_date, 'removed' AS drift_kind
  FROM `stock-trading-498512.state.connector_tool_latest`
  WHERE in_manifest AND NOT present AND manifest_use IN ('required', 'optional')
);

-- ===== STATEMENT 4: state.connector_tool_inventory_stale =====
-- Independent dead-man switch: OPS1 could complete while silently skipping the tool-inventory step — a
-- self-reported check cannot detect its own omission, so something outside OPS1 must. One row per
-- connector (seen in the trailing 30 days) whose newest trustworthy observation is older than 4
-- calendar days (America/Denver), plus a synthetic ALL row when the table has no trustworthy rows at
-- all in the last 4 days (covers the case where nothing has ever enumerated successfully, or every
-- connector went stale at once). THRESHOLD 2 -> 4 (2026-08-08, daily-tier Fri/Sat consolidation onto
-- Sunday, ops/cadence.yaml): OPS1 -- the sole writer of this table -- moved to monitor_class:
-- daily_sun_thu, so its own maximum scheduled gap became Thursday -> Sunday = 3 calendar days
-- (Fri/Sat skipped by design), which would have consumed the ENTIRE old 2-day tolerance and left zero
-- margin for a genuinely late-but-healthy Sunday run before this view falsely called it stale. 4
-- restores one day of slack over that 3-day scheduled gap, the same margin the original 2 gave over
-- OPS1's old every-calendar-day (1-day max gap) schedule.
CREATE OR REPLACE VIEW `stock-trading-498512.state.connector_tool_inventory_stale` AS
WITH recent AS (
  SELECT DISTINCT connector
  FROM `stock-trading-498512.ops.connector_tool_inventory`
  WHERE run_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 30 DAY)
),
last_good AS (
  SELECT connector, MAX(run_date) AS last_good_run_date
  FROM `stock-trading-498512.ops.connector_tool_inventory`
  WHERE enumeration_ok
    AND run_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 30 DAY)
  GROUP BY connector
),
per_connector AS (
  SELECT
    r.connector,
    lg.last_good_run_date,
    DATE_DIFF(CURRENT_DATE('America/Denver'), lg.last_good_run_date, DAY) AS days_stale
  FROM recent r
  LEFT JOIN last_good lg USING (connector)
)
SELECT connector, last_good_run_date, days_stale, CURRENT_TIMESTAMP() AS checked_at
FROM per_connector
WHERE last_good_run_date IS NULL
   OR days_stale > 4
UNION ALL
-- FROM UNNEST([1]) is load-bearing, NOT redundant: GoogleSQL rejects a SELECT expression-list that
-- carries a WHERE with no FROM ("Query without FROM clause cannot have a WHERE clause"), so the
-- literal-only synthetic row needs a one-row source to hang the WHERE off. Do NOT "simplify" this
-- away — the file was rejected at apply time on 2026-08-08 for exactly that shape, and
-- scripts/check_sql_dryrun.py's no-FROM-WHERE lint did not catch it because that lint scanned only
-- INSERT ... SELECT statements, not a CREATE VIEW union arm (both fixed the same day).
SELECT
  'ALL' AS connector, CAST(NULL AS DATE) AS last_good_run_date,
  CAST(NULL AS INT64) AS days_stale, CURRENT_TIMESTAMP() AS checked_at
FROM UNNEST([1])
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.ops.connector_tool_inventory`
  WHERE enumeration_ok
    AND run_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 4 DAY)
);

-- ===== STATEMENT 5: ops.sp_record_connector_tools =====
-- Writer for a single routine run's tool-inventory observation. Plain INSERT, no dedup — the table is
-- append-only by design and OPS1 has its own same-day double-run guard. in_rows_json is a JSON array of
-- objects: connector, tool_name, present, in_manifest, manifest_use, enumeration_ok, note. Booleans are
-- coerced from their JSON string form via LOWER(...) = 'true' rather than SAFE_CAST(... AS BOOL), since
-- a hand-built JSON payload may carry them as bare string tokens.
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_record_connector_tools`(
  in_routine STRING, in_run_date DATE, in_rows_json STRING
)
BEGIN
  INSERT INTO `stock-trading-498512.ops.connector_tool_inventory`
    (run_date, routine, connector, tool_name, present, in_manifest, manifest_use, enumeration_ok, note)
  SELECT
    in_run_date, in_routine,
    JSON_VALUE(item, '$.connector'),
    JSON_VALUE(item, '$.tool_name'),
    LOWER(JSON_VALUE(item, '$.present')) = 'true',
    LOWER(JSON_VALUE(item, '$.in_manifest')) = 'true',
    JSON_VALUE(item, '$.manifest_use'),
    LOWER(JSON_VALUE(item, '$.enumeration_ok')) = 'true',
    JSON_VALUE(item, '$.note')
  FROM UNNEST(JSON_QUERY_ARRAY(PARSE_JSON(in_rows_json))) AS item;
END;

-- ===== STATEMENT 6: ops.sp_raise_connector_tool_drift =====
-- Two categories, ONE ALERT PER TOOL (not one aggregate alert) so each tool's alert independently
-- dedups and independently self-heals, then a mechanical self-heal pass. Read pattern mirrors
-- bigquery/150_cadence_check_autoage_connector_and_revised.sql's raise blocks: sp_raise_alert_once
-- dedups on exact (category, message) among unresolved rows, so every message below is a STABLE string
-- with no count or date embedded — all per-run detail lives in the payload only.
-- SUPERSEDED LIVE by bigquery/239_connector_tool_drift_decorrelate_staleness_guard.sql (2026-09-14) —
-- current single source of truth for this object. Kept here, unmodified, for DR-rebuild
-- apply-in-order reference only. DO NOT re-apply this CREATE statement live in isolation.
-- History: bigquery/235 (2026-09-13) rescoped block (c)'s staleness guard from fleet-wide to
-- per-connector (plus the 'ALL' sentinel) so one stale connector no longer freezes every other
-- connector's self-heal; 239 keeps that intent but resolves the guard into script locals, because
-- 235's correlated NOT EXISTS against state.connector_tool_inventory_stale is rejected by BigQuery at
-- CALL time ("Correlated subqueries ... not supported unless they can be de-correlated") and broke
-- OPS1's drift step on the first run that called it. Blocks (a), (b) and (d) are unchanged in both.
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
  -- back). Guarded by NOT EXISTS on state.connector_tool_inventory_stale: if the inventory is stale or
  -- enumeration failed, state.connector_tool_drift may simply be un-refreshed rather than genuinely
  -- clear, and this self-heal must not mass-resolve real alerts off a stale read.
  IF NOT EXISTS (SELECT 1 FROM `stock-trading-498512.state.connector_tool_inventory_stale`) THEN
    UPDATE `stock-trading-498512.ops.alerts`
    SET resolved = TRUE, resolved_ts = CURRENT_TIMESTAMP(),
        resolved_note = CONCAT('verified-clear: connector tool drift no longer present on state.connector_tool_drift. ', COALESCE(resolved_note, ''))
    WHERE NOT resolved
      AND category IN ('connector_tool_added', 'connector_tool_removed')
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

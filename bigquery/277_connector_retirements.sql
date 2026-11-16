-- bigquery/277_connector_retirements.sql (2026-11-16)
-- Project: stock-trading-498512.
-- Apply after bigquery/151_connector_tool_inventory.sql (it reads ops.connector_tool_inventory and
-- redefines state.connector_tool_inventory_stale, which that file creates).
--
-- WHY. state.connector_tool_inventory_stale (bigquery/151 STATEMENT 4) lists every connector seen in
-- the trailing 30 days whose newest trustworthy observation is more than 4 days old. It is the
-- dead-man switch for "OPS1 silently stopped enumerating a connector". It had no way to know that a
-- connector was removed from ops/connector_tools.yaml ON PURPOSE, so a deliberate retirement looked
-- exactly like the omission it exists to catch, for the full 30 days the old rows take to age out.
--
-- MEASURED 2026-11-16: Tavily was replaced by Parallel-Search-Paid in commit 669cebaa (2026-11-14).
-- OPS1 correctly stopped recording it (last observation 2026-11-09). The view kept listing it, so
-- ops.sp_sq_cadence_check raised connector_tool_inventory_stale for it; that category is on the
-- 7-day auto-age list, and the check re-raises the same night it ages out because the view still
-- lists the connector. Net effect: one owner email about every 7 days until 2026-12-09, each telling
-- the owner to act on something that needs no action. W5 2026-11-15 documented the behaviour in
-- ops/RUNBOOK.md section 15 but left the emails in place.
--
-- WHAT THIS DOES.
--   1. ops.connector_retirements -- append-only record that a connector was removed from the
--      manifest deliberately (connector, retired_date, replaced_by, reason, recorded_by).
--   2. ops.sp_retire_connector -- the only writer. It refuses a retirement the observations
--      contradict (a trustworthy observation AFTER the stated retired_date means the connector is
--      still being enumerated), so a mistaken call cannot hide a live connector.
--   3. Seeds the Tavily retirement.
--   4. Redefines state.connector_tool_inventory_stale to skip a connector whose newest observation
--      of any kind is on or before its retired_date.
--
-- WHY NOT THE TWO OBVIOUS SHORTCUTS (both rejected in ops/RUNBOOK.md section 15 already):
--   * Keying the view on the newest run's connector set would also hide a manifest connector that
--     OPS1 silently omits -- the exact failure the per-connector rows exist to catch.
--   * Writing synthetic inventory rows for the retired connector restarts its 30-day clock and
--     pollutes state.connector_tool_latest / state.connector_tool_drift.
--
-- A RETIREMENT IS NOT PERMANENT BLINDNESS. The exclusion holds only while the connector's newest
-- observation is on or before retired_date. If the connector returns to the manifest and OPS1
-- records it again, that newer row re-arms the dead-man switch with no un-retire step.
--
-- Idempotent: CREATE TABLE IF NOT EXISTS, CREATE OR REPLACE, and the procedure skips a
-- (connector, retired_date) pair it has already recorded, so a DR re-apply is safe.

-- ===== STATEMENT 1: ops.connector_retirements =====
CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.connector_retirements` (
  recorded_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  connector STRING NOT NULL,       -- matches ops.connector_tool_inventory.connector
  retired_date DATE NOT NULL,      -- the day it left ops/connector_tools.yaml (America/Denver)
  replaced_by STRING,              -- successor connector name, NULL when there is none
  reason STRING NOT NULL,          -- the removing commit and why
  recorded_by STRING NOT NULL      -- routine or session that recorded it
)
OPTIONS(description='Append-only record of connectors removed from ops/connector_tools.yaml on purpose. state.connector_tool_inventory_stale skips a connector whose newest observation is on or before its retired_date. Written only by ops.sp_retire_connector (bigquery/277).');

-- ===== STATEMENT 2: ops.sp_retire_connector =====
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_retire_connector`(
  in_connector STRING, in_retired_date DATE, in_replaced_by STRING, in_reason STRING, in_recorded_by STRING
)
BEGIN
  DECLARE newest_good DATE;
  IF in_connector IS NULL OR TRIM(in_connector) = '' OR in_retired_date IS NULL
     OR in_reason IS NULL OR TRIM(in_reason) = '' OR in_recorded_by IS NULL OR TRIM(in_recorded_by) = '' THEN
    RAISE USING MESSAGE = 'sp_retire_connector: connector, retired_date, reason and recorded_by are all required.';
  END IF;
  SET newest_good = (
    SELECT MAX(run_date) FROM `stock-trading-498512.ops.connector_tool_inventory`
    WHERE connector = in_connector AND enumeration_ok
  );
  IF newest_good IS NULL THEN
    RAISE USING MESSAGE = CONCAT('sp_retire_connector: no trustworthy observation of connector ', in_connector, ' exists, so there is nothing to retire. Check the name against ops.connector_tool_inventory.connector.');
  END IF;
  IF newest_good > in_retired_date THEN
    RAISE USING MESSAGE = CONCAT('sp_retire_connector: connector ', in_connector, ' has a trustworthy observation on ', CAST(newest_good AS STRING), ', after the stated retired_date. It is still being enumerated and is not retired.');
  END IF;
  INSERT INTO `stock-trading-498512.ops.connector_retirements`
    (connector, retired_date, replaced_by, reason, recorded_by)
  SELECT in_connector, in_retired_date, in_replaced_by, in_reason, in_recorded_by
  FROM UNNEST([1])
  WHERE NOT EXISTS (
    SELECT 1 FROM `stock-trading-498512.ops.connector_retirements`
    WHERE connector = in_connector AND retired_date = in_retired_date
  );
END;

-- ===== STATEMENT 3: seed the Tavily retirement =====
CALL `stock-trading-498512.ops.sp_retire_connector`(
  'Tavily', DATE '2026-11-14', 'Parallel-Search-Paid',
  'Removed from ops/connector_tools.yaml by commit 669cebaa (Replace Tavily with Parallel Search). Last observed by OPS1 on 2026-11-09.',
  'interactive 2026-11-16 alert triage'
);

-- ===== STATEMENT 4: state.connector_tool_inventory_stale (supersedes bigquery/151 STATEMENT 4) =====
-- bigquery/151's body with ONE change: the `recent` CTE no longer lists a connector whose newest
-- observation (trustworthy or not) is on or before its recorded retired_date. The 30-day window, the
-- 4-day threshold and the synthetic ALL row are unchanged.
-- Joins only, no correlated subquery: this view is read inside ops.sp_raise_connector_tool_drift
-- (bigquery/239), where a correlated reference to it was rejected at CALL time.
-- FROM UNNEST([1]) on the synthetic row is load-bearing; see bigquery/151 STATEMENT 4.
CREATE OR REPLACE VIEW `stock-trading-498512.state.connector_tool_inventory_stale` AS
WITH last_seen AS (
  SELECT connector, MAX(run_date) AS last_seen_run_date
  FROM `stock-trading-498512.ops.connector_tool_inventory`
  WHERE run_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 30 DAY)
  GROUP BY connector
),
retired AS (
  SELECT connector, MAX(retired_date) AS retired_date
  FROM `stock-trading-498512.ops.connector_retirements`
  GROUP BY connector
),
recent AS (
  SELECT s.connector
  FROM last_seen s
  LEFT JOIN retired r USING (connector)
  WHERE r.connector IS NULL
     OR s.last_seen_run_date > r.retired_date
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
SELECT
  'ALL' AS connector, CAST(NULL AS DATE) AS last_good_run_date,
  CAST(NULL AS INT64) AS days_stale, CURRENT_TIMESTAMP() AS checked_at
FROM UNNEST([1])
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.ops.connector_tool_inventory`
  WHERE enumeration_ok
    AND run_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 4 DAY)
);

-- Parallel-run dbt port of bigquery/151_connector_tool_inventory.sql:state.connector_tool_inventory_stale — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH recent AS (
  SELECT DISTINCT connector
  FROM {{ source('ops', 'connector_tool_inventory') }}
  WHERE run_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 30 DAY)
),
last_good AS (
  SELECT connector, MAX(run_date) AS last_good_run_date
  FROM {{ source('ops', 'connector_tool_inventory') }}
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
  SELECT 1 FROM {{ source('ops', 'connector_tool_inventory') }}
  WHERE enumeration_ok
    AND run_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 4 DAY)
)

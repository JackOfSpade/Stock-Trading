-- Parallel-run dbt port of bigquery/277_connector_retirements.sql:state.connector_tool_inventory_stale — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
WITH last_seen AS (
  SELECT connector, MAX(run_date) AS last_seen_run_date
  FROM {{ source('ops', 'connector_tool_inventory') }}
  WHERE run_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 30 DAY)
  GROUP BY connector
),
retired AS (
  SELECT connector, MAX(retired_date) AS retired_date
  FROM {{ source('ops', 'connector_retirements') }}
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
SELECT
  'ALL' AS connector, CAST(NULL AS DATE) AS last_good_run_date,
  CAST(NULL AS INT64) AS days_stale, CURRENT_TIMESTAMP() AS checked_at
FROM UNNEST([1])
WHERE NOT EXISTS (
  SELECT 1 FROM {{ source('ops', 'connector_tool_inventory') }}
  WHERE enumeration_ok
    AND run_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 4 DAY)
)

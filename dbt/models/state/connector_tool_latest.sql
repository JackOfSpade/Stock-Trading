-- Parallel-run dbt port of bigquery/151_connector_tool_inventory.sql:state.connector_tool_latest — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
SELECT
  connector, tool_name, observed_ts, run_date AS observed_run_date, routine,
  present, in_manifest, manifest_use, enumeration_ok, note
FROM (
  SELECT
    connector, tool_name, observed_ts, run_date, routine,
    present, in_manifest, manifest_use, enumeration_ok, note,
    ROW_NUMBER() OVER (PARTITION BY connector, tool_name ORDER BY observed_ts DESC) AS rn
  FROM {{ source('ops', 'connector_tool_inventory') }}
  WHERE enumeration_ok
    AND run_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 30 DAY)
)
WHERE rn = 1

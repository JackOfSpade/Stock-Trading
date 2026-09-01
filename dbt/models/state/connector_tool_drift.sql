-- Parallel-run dbt port of bigquery/151_connector_tool_inventory.sql:state.connector_tool_drift — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
SELECT
  connector, tool_name, drift_kind,
  CASE WHEN drift_kind = 'removed' AND manifest_use = 'required' THEN 'critical' ELSE 'warning' END AS severity,
  manifest_use, observed_run_date, CURRENT_TIMESTAMP() AS checked_at
FROM (
  SELECT connector, tool_name, manifest_use, observed_run_date, 'added' AS drift_kind
  FROM {{ ref('connector_tool_latest') }}
  WHERE present AND NOT in_manifest
  UNION ALL
  SELECT connector, tool_name, manifest_use, observed_run_date, 'removed' AS drift_kind
  FROM {{ ref('connector_tool_latest') }}
  WHERE in_manifest AND NOT present AND manifest_use IN ('required', 'optional')
)

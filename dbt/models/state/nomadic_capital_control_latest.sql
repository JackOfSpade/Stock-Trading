-- Parallel-run dbt port of bigquery/167_nomadic_capital.sql:state.nomadic_capital_control_latest — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH ctrl AS (
  SELECT ARRAY_AGG(
           STRUCT(enabled, reason, set_by, control_ts)
           ORDER BY control_ts DESC LIMIT 1
         )[SAFE_OFFSET(0)] AS latest
  FROM {{ source('ops', 'capital_nomad_control') }}
)
SELECT
  COALESCE(ctrl.latest.enabled, FALSE) AS enabled,
  ctrl.latest.reason                   AS reason,
  ctrl.latest.set_by                   AS set_by,
  ctrl.latest.control_ts               AS control_ts
FROM ctrl

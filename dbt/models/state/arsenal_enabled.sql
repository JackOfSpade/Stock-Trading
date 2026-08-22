-- Parallel-run dbt port of bigquery/35_strategy_arsenal.sql:state.arsenal_enabled — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
WITH ctrl AS (
  SELECT ARRAY_AGG(STRUCT(enabled, incubation_frozen, reason) ORDER BY control_ts DESC LIMIT 1)[SAFE_OFFSET(0)] AS latest
  FROM {{ source('ops', 'arsenal_control') }}
)
SELECT
  COALESCE(ctrl.latest.enabled, FALSE) AS enabled,
  COALESCE(ctrl.latest.incubation_frozen, TRUE) AS incubation_frozen,
  ctrl.latest.reason AS reason
FROM ctrl

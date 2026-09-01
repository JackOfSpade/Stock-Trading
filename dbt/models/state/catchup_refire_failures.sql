-- Parallel-run dbt port of bigquery/59_catchup_autofire.sql:state.catchup_refire_failures — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
SELECT miss_key, routine, tier, attempted_ts, note
FROM {{ source('ops', 'catchup_refire_log') }}
WHERE outcome = 'no_trigger_id'
  AND DATE(attempted_ts, 'America/Denver') = CURRENT_DATE('America/Denver')

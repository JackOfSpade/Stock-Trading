-- Parallel-run dbt port of bigquery/54_park_policy_voo_cutover.sql:state.park_policy_current — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
SELECT vehicle, effective_date, note
FROM {{ source('events', 'park_policy_changes') }}
QUALIFY ROW_NUMBER() OVER (ORDER BY event_ts DESC) = 1

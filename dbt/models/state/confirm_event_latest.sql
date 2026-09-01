-- Parallel-run dbt port of bigquery/30_confirm_attestation.sql:state.confirm_event_latest — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
SELECT *
FROM {{ source('ops', 'confirm_event_snapshot') }}
QUALIFY ROW_NUMBER() OVER (PARTITION BY item_key ORDER BY snapshot_ts DESC) = 1

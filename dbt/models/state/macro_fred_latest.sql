-- Parallel-run dbt port of bigquery/53_curated_view_tiebreak_fix.sql:state.macro_fred_latest — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
SELECT metric, ref_month, value, source, fetched_ts
FROM {{ source('events', 'macro_fred') }}
QUALIFY ROW_NUMBER() OVER (PARTITION BY metric, ref_month ORDER BY fetched_ts DESC, row_uid DESC) = 1

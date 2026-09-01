-- Parallel-run dbt port of bigquery/62_probe_stake_funding.sql:state.strategy_probe_funding_stalled — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
SELECT strategy_code, probe_entry_ts, booked_allocation, funding_gap_dollars, days_since_probe_entry
FROM {{ ref('strategy_probe_funding_gap') }}
WHERE NOT floor_met AND days_since_probe_entry >= 90

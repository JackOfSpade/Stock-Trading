-- Parallel-run dbt port of bigquery/62_probe_stake_funding.sql:state.strategy_probe_funding_gap — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
SELECT
  r.strategy_code,
  r.immutable_since AS probe_entry_ts,
  COALESCE(nav.deposits, 0) AS booked_allocation,
  GREATEST(0, 2000 - COALESCE(nav.deposits, 0)) AS funding_gap_dollars,
  COALESCE(nav.deposits, 0) >= 2000 AS floor_met,
  TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), r.immutable_since, DAY) AS days_since_probe_entry
FROM {{ source('state_external', 'strategy_roster') }} r
LEFT JOIN {{ ref('strategy_nav') }} nav ON nav.strategy = r.strategy_code
WHERE r.current_state = 'PROBE'

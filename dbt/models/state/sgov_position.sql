-- Parallel-run dbt port of bigquery/54_park_policy_voo_cutover.sql:state.sgov_position — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
SELECT
  events_shares AS events_sgov_shares, buy_shares, sell_shares, drip_shares,
  events_park_net_cash, parking_commissions_total, parking_event_count, last_parking_date
FROM {{ ref('park_position') }}
WHERE ticker = 'SGOV'

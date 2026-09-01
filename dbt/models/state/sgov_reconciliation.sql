-- Parallel-run dbt port of bigquery/54_park_policy_voo_cutover.sql:state.sgov_reconciliation — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH p AS (SELECT * FROM {{ ref('sgov_position') }}),
mark AS (
  SELECT close AS sgov_close, mark_date AS sgov_mark_date
  FROM {{ ref('daily_marks_curated') }}
  WHERE ticker = 'SGOV'
  QUALIFY ROW_NUMBER() OVER (ORDER BY mark_date DESC) = 1
)
SELECT
  p.events_sgov_shares, p.buy_shares, p.sell_shares, p.drip_shares,
  p.events_park_net_cash, p.parking_commissions_total,
  mark.sgov_close, mark.sgov_mark_date,
  ROUND(p.events_sgov_shares * mark.sgov_close, 2)                         AS events_sgov_market_value,
  COALESCE(mark.sgov_mark_date >= (SELECT last_trading_day FROM {{ ref('trading_day_today') }}),
           FALSE)                                                          AS sgov_mark_fresh,
  CURRENT_TIMESTAMP()                                                      AS checked_at
FROM p LEFT JOIN mark ON TRUE

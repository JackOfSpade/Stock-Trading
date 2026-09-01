-- Parallel-run dbt port of bigquery/54_park_policy_voo_cutover.sql:state.park_position — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
SELECT
  ticker,
  SUM(CASE action WHEN 'BUY' THEN shares
                  WHEN 'DIVIDEND_REINVEST' THEN shares
                  WHEN 'RECON_ADJUST' THEN shares  -- signed delta (+/-)
                  WHEN 'SELL' THEN -shares
                  ELSE 0 END)                                              AS events_shares,
  SUM(IF(action = 'BUY',  shares, 0))                                      AS buy_shares,
  SUM(IF(action = 'SELL', shares, 0))                                      AS sell_shares,
  SUM(IF(action = 'DIVIDEND_REINVEST', shares, 0))                         AS drip_shares,
  ROUND(SUM(CASE action
              WHEN 'BUY'  THEN -(gross + COALESCE(commission, 0))
              WHEN 'SELL' THEN  (gross - COALESCE(commission, 0))
              ELSE 0 END), 4)                                             AS events_park_net_cash,
  ROUND(SUM(COALESCE(commission, 0)), 4)                                  AS parking_commissions_total,
  COUNT(*)                                                                 AS parking_event_count,
  MAX(action_date)                                                         AS last_parking_date
FROM {{ source('events', 'parking_events') }}
GROUP BY ticker

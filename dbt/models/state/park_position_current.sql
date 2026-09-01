-- Parallel-run dbt port of bigquery/92_park_allocator.sql:state.park_position_current — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH cur AS (SELECT vehicle FROM {{ ref('park_policy_current') }}),
policy_row AS (
  SELECT
    cur.vehicle                                 AS ticker,
    COALESCE(pp.events_shares, 0)                AS events_shares,
    COALESCE(pp.buy_shares, 0)                   AS buy_shares,
    COALESCE(pp.sell_shares, 0)                  AS sell_shares,
    COALESCE(pp.drip_shares, 0)                  AS drip_shares,
    COALESCE(pp.events_park_net_cash, 0)         AS events_park_net_cash,
    COALESCE(pp.parking_commissions_total, 0)    AS parking_commissions_total,
    COALESCE(pp.parking_event_count, 0)          AS parking_event_count,
    pp.last_parking_date                         AS last_parking_date,
    TRUE                                          AS is_policy_vehicle
  FROM cur
  LEFT JOIN {{ ref('park_position') }} pp ON pp.ticker = cur.vehicle
),
residual_rows AS (
  SELECT
    pp.ticker,
    pp.events_shares, pp.buy_shares, pp.sell_shares, pp.drip_shares,
    pp.events_park_net_cash, pp.parking_commissions_total, pp.parking_event_count, pp.last_parking_date,
    FALSE AS is_policy_vehicle
  FROM {{ ref('park_position') }} pp
  CROSS JOIN cur
  WHERE pp.ticker != cur.vehicle
    AND ABS(pp.events_shares) > 0.0005
)
SELECT * FROM policy_row
UNION ALL
SELECT * FROM residual_rows

-- Parallel-run dbt port of bigquery/220_park_two_sleeve_book.sql:state.park_position_current — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
WITH cur AS (
  SELECT risk_sleeve, defensive_sleeve, target_f_pct FROM {{ ref('park_policy_current') }}
),
-- The two sleeves and their TARGET weights. A sleeve at weight 0 is a vehicle the book is leaving.
targets AS (
  SELECT cur.risk_sleeve      AS ticker, 100 - cur.target_f_pct AS target_weight_pct FROM cur
  UNION ALL
  SELECT cur.defensive_sleeve AS ticker, cur.target_f_pct       AS target_weight_pct FROM cur
),
-- Collapse in case both sleeves name the same ticker (a degenerate but legal policy).
targets_dedup AS (
  SELECT ticker, SUM(target_weight_pct) AS target_weight_pct
  FROM targets GROUP BY ticker
),
sleeve_rows AS (
  SELECT
    t.ticker,
    COALESCE(pp.events_shares, 0)              AS events_shares,
    COALESCE(pp.buy_shares, 0)                 AS buy_shares,
    COALESCE(pp.sell_shares, 0)                AS sell_shares,
    COALESCE(pp.drip_shares, 0)                AS drip_shares,
    COALESCE(pp.events_park_net_cash, 0)       AS events_park_net_cash,
    COALESCE(pp.parking_commissions_total, 0)  AS parking_commissions_total,
    COALESCE(pp.parking_event_count, 0)        AS parking_event_count,
    pp.last_parking_date                       AS last_parking_date,
    t.target_weight_pct,
    TRUE                                       AS is_target_sleeve
  FROM targets_dedup t
  LEFT JOIN {{ ref('park_position') }} pp ON pp.ticker = t.ticker
),
-- Anything held above dust that is NOT a named sleeve. Under a binary book this is the old
-- residual_rows set exactly; under a graded book the second sleeve is NOT here, which is the point.
residual_rows AS (
  SELECT
    pp.ticker,
    pp.events_shares, pp.buy_shares, pp.sell_shares, pp.drip_shares,
    pp.events_park_net_cash, pp.parking_commissions_total, pp.parking_event_count, pp.last_parking_date,
    0   AS target_weight_pct,
    FALSE AS is_target_sleeve
  FROM {{ ref('park_position') }} pp
  WHERE ABS(pp.events_shares) > 0.0005
    AND pp.ticker NOT IN (SELECT ticker FROM targets_dedup)
)
SELECT
  ticker, events_shares, buy_shares, sell_shares, drip_shares,
  events_park_net_cash, parking_commissions_total, parking_event_count, last_parking_date,
  target_weight_pct,
  is_target_sleeve,
  -- COMPATIBILITY, AND THE STRANDED-LEG FIX IN ONE LINE. Every pre-v4 consumer reads this column and
  -- keeps working: under a binary book it is identical to the old flag, and under a graded book both
  -- weighted sleeves are policy vehicles so neither is treated as stranded.
  target_weight_pct > 0 AS is_policy_vehicle
FROM (
  SELECT * FROM sleeve_rows
  UNION ALL
  SELECT * FROM residual_rows
)

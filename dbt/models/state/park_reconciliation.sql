-- Parallel-run dbt port of bigquery/173_freshness_cadence_aware.sql:state.park_reconciliation — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH p AS (SELECT * FROM {{ ref('park_position_current') }}),
dm AS (
  SELECT ticker, close AS park_close, mark_date AS park_mark_date
  FROM {{ ref('daily_marks_curated') }}
  WHERE ticker IN (SELECT ticker FROM p)
  QUALIFY ROW_NUMBER() OVER (PARTITION BY ticker ORDER BY mark_date DESC) = 1
),
sm AS (
  SELECT ticker, close AS park_close, mark_date AS park_mark_date
  FROM {{ source('state_external', 'signal_marks_curated') }}
  WHERE ticker IN (SELECT ticker FROM p)
  QUALIFY ROW_NUMBER() OVER (PARTITION BY ticker ORDER BY mark_date DESC) = 1
),
mark AS (
  SELECT
    p.ticker,
    COALESCE(dm.park_close, sm.park_close)         AS park_close,
    COALESCE(dm.park_mark_date, sm.park_mark_date) AS park_mark_date
  FROM p
  LEFT JOIN dm ON dm.ticker = p.ticker
  LEFT JOIN sm ON sm.ticker = p.ticker
)
SELECT
  p.ticker                    AS park_ticker,
  p.events_shares              AS events_park_shares,
  p.buy_shares, p.sell_shares, p.drip_shares,
  p.events_park_net_cash,
  p.parking_commissions_total,
  mark.park_close,
  mark.park_mark_date,
  -- COALESCE to 0 (2026-07-19 fix): the CASH policy vehicle has no price series in either marks
  -- source (mark.park_close is NULL for ticker='CASH'), so 0 shares * NULL close would otherwise
  -- surface as NULL, not 0, on a CASH-parked day. A CASH-parked day correctly shows $0 instrument
  -- value here — the real cash lives in state.account_latest.total_cash, not this column.
  ROUND(p.events_shares * COALESCE(mark.park_close, 0), 2) AS events_park_market_value,
  -- BASIS CHANGED 2026-08-15 (bigquery/173): was `>= last_trading_day`, which read FALSE every
  -- Friday/Saturday under the Sun-Thu daily tier because state.daily_marks_curated is D2a-written.
  -- marks_due_through is "as fresh as the schedule allows", so a FALSE here is once again a real
  -- signal. Operating_Protocols.md 13.A cites this column by name as the park staleness guard.
  COALESCE(mark.park_mark_date >= (SELECT marks_due_through FROM {{ ref('freshness') }}),
           FALSE)                                   AS park_mark_fresh,
  p.is_policy_vehicle,
  CURRENT_TIMESTAMP()                                AS checked_at
FROM p
LEFT JOIN mark ON mark.ticker = p.ticker

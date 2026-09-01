-- Parallel-run dbt port of bigquery/178_park_wash_sale_exposure.sql:state.wash_sale_exposure — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH losing_sells AS (
  -- Loss-realizing SELLs (closes a LONG strategy position) — unchanged from bigquery/50.
  SELECT trade_id AS close_trade_id, strategy AS close_strategy, ticker,
         DATE(fill_ts, 'America/New_York') AS close_date,
         shares AS close_shares, realized_pnl, 'SELL' AS close_side
  FROM {{ ref('trade_fills_curated') }}
  WHERE side = 'SELL' AND ticker != 'SGOV'
    AND realized_pnl IS NOT NULL AND realized_pnl < 0
    AND shares IS NOT NULL AND shares > 0 AND fill_ts IS NOT NULL
  UNION ALL
  -- NEW: loss-realizing park SELLs. analytics.park_tax_lots has no single "realized_pnl per
  -- disposing fill" column (unlike state.trade_fills_curated, where IBKR already attaches one) — it
  -- is FIFO-fragmented per (buy lot, sell) pair instead, so the fragments are aggregated back up to
  -- one row per actual disposing SELL event (sell_trade_id = parking_events.event_id) here, matching
  -- the granularity of the strategy-side arm above.
  SELECT sell_trade_id AS close_trade_id, 'PARK' AS close_strategy, ticker,
         close_date, close_shares, realized_pnl, 'SELL' AS close_side
  FROM (
    SELECT sell_trade_id, ANY_VALUE(ticker) AS ticker, ANY_VALUE(exit_date) AS close_date,
           SUM(shares) AS close_shares, SUM(realized_gain_loss) AS realized_pnl
    FROM {{ ref('park_tax_lots') }}
    WHERE status = 'CLOSED'
    GROUP BY sell_trade_id
  )
  WHERE realized_pnl < 0
),
losing_covers AS (
  -- Loss-realizing BUYs (closes/covers a SHORT strategy position) — unchanged from bigquery/50. Park
  -- never shorts, so there is no park arm here.
  SELECT trade_id AS close_trade_id, strategy AS close_strategy, ticker,
         DATE(fill_ts, 'America/New_York') AS close_date,
         shares AS close_shares, realized_pnl, 'BUY' AS close_side
  FROM {{ ref('trade_fills_curated') }}
  WHERE side = 'BUY' AND ticker != 'SGOV'
    AND realized_pnl IS NOT NULL AND realized_pnl < 0
    AND shares IS NOT NULL AND shares > 0 AND fill_ts IS NOT NULL
),
losing_closes AS (
  SELECT * FROM losing_sells
  UNION ALL
  SELECT * FROM losing_covers
),
candidate_buys AS (
  -- Strategy-side replacement-purchase candidates — unchanged from bigquery/50.
  SELECT trade_id AS buy_trade_id, strategy AS buy_strategy, ticker,
         DATE(fill_ts, 'America/New_York') AS buy_date, shares AS buy_shares
  FROM {{ ref('trade_fills_curated') }}
  WHERE side = 'BUY' AND ticker != 'SGOV'
    AND shares IS NOT NULL AND shares > 0 AND fill_ts IS NOT NULL
  UNION ALL
  -- NEW: park-side replacement-purchase candidates. BUY and DIVIDEND_REINVEST both count (see file
  -- header); RECON_ADJUST is excluded (bookkeeping correction, not a purchase). Cross-source on
  -- purpose -- a strategy BUY can qualify as a replacement for a park loss-sale and vice versa (this
  -- view's own long-standing whole-taxpayer rationale, extended from cross-strategy to cross-source).
  SELECT event_id AS buy_trade_id, 'PARK' AS buy_strategy, ticker,
         DATE(event_ts, 'America/New_York') AS buy_date, shares AS buy_shares
  FROM {{ source('events', 'parking_events') }}
  WHERE action IN ('BUY', 'DIVIDEND_REINVEST') AND ticker != 'SGOV'
    AND shares IS NOT NULL AND shares > 0 AND event_ts IS NOT NULL
),
candidate_sells AS (
  -- Symmetric replacement-purchase pool for a losing SHORT COVER (a re-opened SHORT, i.e. a new
  -- SELL) — unchanged from bigquery/50. Deliberately NOT extended with park SELLs: a park SELL
  -- liquidates a long position, it is not "opening a new short", so it has no place in this pool.
  SELECT trade_id AS sell_trade_id, strategy AS sell_strategy, ticker,
         DATE(fill_ts, 'America/New_York') AS sell_date, shares AS sell_shares
  FROM {{ ref('trade_fills_curated') }}
  WHERE side = 'SELL' AND ticker != 'SGOV'
    AND shares IS NOT NULL AND shares > 0 AND fill_ts IS NOT NULL
),
own_basis_for_sell AS (
  -- The buy lot(s) that ARE a given losing SELL's own FIFO cost basis — excluded as "replacement"
  -- candidates. Unioned across analytics.tax_lots (strategy) AND analytics.park_tax_lots (park) so a
  -- park close's own basis is excluded the same way a strategy close's is. The two sources' trade_id
  -- key spaces never collide (IBKR trade_id format vs. parking_events.event_id, a GENERATE_UUID()
  -- string), so no cross-source ambiguity.
  SELECT sell_trade_id, ARRAY_AGG(DISTINCT buy_trade_id) AS own_buy_trade_ids
  FROM (
    SELECT sell_trade_id, buy_trade_id
    FROM {{ ref('tax_lots') }}
    WHERE sell_trade_id IS NOT NULL AND buy_trade_id IS NOT NULL
    UNION ALL
    SELECT sell_trade_id, buy_trade_id
    FROM {{ ref('park_tax_lots') }}
    WHERE sell_trade_id IS NOT NULL AND buy_trade_id IS NOT NULL
  )
  GROUP BY sell_trade_id
),
own_basis_for_buy AS (
  -- The sell lot(s) that a given losing BUY (cover) itself closed — unchanged from bigquery/50. Park
  -- never covers a short, so a park buy_trade_id never needs an exclusion set here.
  SELECT buy_trade_id, ARRAY_AGG(DISTINCT sell_trade_id) AS own_sell_trade_ids
  FROM {{ ref('tax_lots') }}
  WHERE buy_trade_id IS NOT NULL AND sell_trade_id IS NOT NULL
  GROUP BY buy_trade_id
),
qualifying_replacements AS (
  -- Replacement BUYs for a losing SELL (closes a LONG, strategy OR park — losing_sells and
  -- candidate_buys are each already the unioned population, so this arm needs no park-specific
  -- change of its own).
  SELECT
    s.close_trade_id, s.close_strategy, s.ticker, s.close_date, s.realized_pnl AS close_realized_pnl,
    s.close_shares, s.close_side,
    b.buy_trade_id AS replacement_trade_id, b.buy_strategy AS replacement_strategy,
    b.buy_date AS replacement_date, b.buy_shares AS replacement_shares,
    DATE_DIFF(b.buy_date, s.close_date, DAY) AS days_offset
  FROM losing_sells s
  JOIN candidate_buys b ON b.ticker = s.ticker
  LEFT JOIN own_basis_for_sell ocb ON ocb.sell_trade_id = s.close_trade_id
  WHERE DATE_DIFF(b.buy_date, s.close_date, DAY) BETWEEN -30 AND 30
    AND NOT (ocb.own_buy_trade_ids IS NOT NULL AND b.buy_trade_id IN UNNEST(ocb.own_buy_trade_ids))
  UNION ALL
  -- Replacement SELLs (re-shorts) for a losing BUY/cover (closes a SHORT) — strategy-only, unchanged.
  SELECT
    c.close_trade_id, c.close_strategy, c.ticker, c.close_date, c.realized_pnl AS close_realized_pnl,
    c.close_shares, c.close_side,
    sl.sell_trade_id AS replacement_trade_id, sl.sell_strategy AS replacement_strategy,
    sl.sell_date AS replacement_date, sl.sell_shares AS replacement_shares,
    DATE_DIFF(sl.sell_date, c.close_date, DAY) AS days_offset
  FROM losing_covers c
  JOIN candidate_sells sl ON sl.ticker = c.ticker
  LEFT JOIN own_basis_for_buy ocb ON ocb.buy_trade_id = c.close_trade_id
  WHERE DATE_DIFF(sl.sell_date, c.close_date, DAY) BETWEEN -30 AND 30
    AND NOT (ocb.own_sell_trade_ids IS NOT NULL AND sl.sell_trade_id IN UNNEST(ocb.own_sell_trade_ids))
),
agg AS (
  SELECT
    close_trade_id, ANY_VALUE(close_strategy) AS close_strategy, ANY_VALUE(ticker) AS ticker,
    ANY_VALUE(close_date) AS close_date, ANY_VALUE(close_realized_pnl) AS close_realized_pnl,
    ANY_VALUE(close_shares) AS close_shares, ANY_VALUE(close_side) AS close_side,
    ARRAY_AGG(STRUCT(replacement_trade_id, replacement_strategy, replacement_date, replacement_shares, days_offset)
              ORDER BY replacement_date) AS replacement_trades,
    SUM(replacement_shares) AS total_replacement_shares_uncapped,
    MIN(days_offset) AS earliest_days_offset,
    MAX(days_offset) AS latest_days_offset
  FROM qualifying_replacements
  GROUP BY close_trade_id
)
-- Base population = EVERY loss-realizing close (SELL closing a long -- strategy or park; BUY closing
-- a strategy short; SGOV-excluded, non-NULL data). LEFT JOIN to the replacement aggregation so a
-- close with no replacement trade in the window defaults cleanly to has_exposure = FALSE /
-- estimated_disallowed_loss = 0 -- never NULL, never a stray "exposed" flag on missing data
-- (fail-closed, per bigquery/41's original header note).
SELECT
  c.close_trade_id, c.close_strategy, c.ticker, c.close_date, c.close_shares,
  c.realized_pnl AS close_realized_pnl, c.close_side,
  a.close_trade_id IS NOT NULL AS has_exposure,
  COALESCE(a.replacement_trades, []) AS replacement_trades,
  LEAST(COALESCE(a.total_replacement_shares_uncapped, 0), c.close_shares) AS capped_replacement_shares,
  a.earliest_days_offset, a.latest_days_offset,
  ROUND(ABS(c.realized_pnl)
        * SAFE_DIVIDE(LEAST(COALESCE(a.total_replacement_shares_uncapped, 0), c.close_shares), c.close_shares),
        2) AS estimated_disallowed_loss
FROM losing_closes c
LEFT JOIN agg a ON a.close_trade_id = c.close_trade_id

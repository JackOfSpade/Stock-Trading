-- Parallel-run dbt port of bigquery/219_wash_sale_shared_pool_allocation.sql:state.wash_sale_exposure — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
WITH RECURSIVE losing_sells AS (
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
    -- SIBLING-LEG EXCLUSION (bigquery/219, 2026-09-04) — a park SELL is split by the exchange into
    -- several partial fills, each its own parking_events.event_id and therefore its own
    -- sell_trade_id. 178 excluded only the lots FIFO-assigned to THAT leg, so the SAME sale's other
    -- legs' basis lots looked like external replacement purchases and manufactured a wash sale out
    -- of an ordinary full liquidation. Measured on the 2026-09-02 park sale: 13 of the 14 listed
    -- "replacements" were that very sale's own basis, seen through its 7 sibling legs. The exclusion
    -- set is therefore taken at ORDER level — every buy lot that is basis for ANY leg of the same
    -- disposing order is excluded for EVERY leg of it.
    SELECT ptl.sell_trade_id, sib.buy_trade_id
    FROM {{ ref('park_tax_lots') }} ptl
    JOIN {{ source('events', 'parking_events') }} pe
      ON pe.event_id = ptl.sell_trade_id
    JOIN {{ source('events', 'parking_events') }} pe_sib
      ON pe_sib.order_id = pe.order_id AND pe_sib.order_id IS NOT NULL
    JOIN {{ ref('park_tax_lots') }} sib
      ON sib.sell_trade_id = pe_sib.event_id
    WHERE ptl.sell_trade_id IS NOT NULL AND sib.buy_trade_id IS NOT NULL
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
-- SHARED-POOL ALLOCATION (bigquery/219, 2026-09-04) — replaces 178's per-close INDEPENDENT cap.
-- 178 capped each close at its own close_shares, but the SAME replacement lot could be counted in
-- full against EVERY qualifying close. With one close per episode that is invisible; under a graded
-- ladder, where one de-risk becomes several partial closes, it multiplies the disallowance by the
-- number of steps. A replacement lot can only replace its own shares ONCE.
-- Lot supply is allocated across qualifying closes OLDEST-CLOSE-FIRST.
-- JOINT ALLOCATION (corrected 2026-09-04). The first cut of this file used a per-lot running sum of
-- FULL close_shares as "demand". That STARVES later closes: a lot was booked as consumed by an
-- earlier close even when that close had already been fully replaced by OTHER lots, and the surplus
-- was then discarded by the downstream per-close cap. Measured on live data, the 2026-07-27 VOO group
-- read $51.36 against a correct $77.17 — 4.4048 shares of genuine demand left unserved with 26.7739
-- shares of supply available. Under-reporting a wash sale is the UNSAFE direction for a detector.
-- A pair of scalar running balances cannot fix it, because the qualification graph is incomplete
-- (the 09-02 legs qualify for 1 of the 13 VOO lots, the July legs for all 13), so a two-axis interval
-- overlap silently allocates lots to closes that never qualified for them.
-- Correct form: walk the qualifying (close, lot) pairs in (close_date, close_trade_id,
-- replacement_date, replacement_trade_id) order, threading BOTH per-lot remaining supply and
-- per-close remaining demand, and allocate LEAST(lot_remaining, close_remaining) at each step.
-- Cardinality is tiny (10 closes x 13 lots on VOO today), so the recursion is cheap.
ordered AS (
  SELECT qr.*,
         ROW_NUMBER() OVER (ORDER BY qr.close_date, qr.close_trade_id,
                                     qr.replacement_date, qr.replacement_trade_id) AS k
  FROM qualifying_replacements qr
),
lots AS (
  SELECT ARRAY_AGG(STRUCT(lot, shares)) AS l
  FROM (SELECT replacement_trade_id AS lot, ANY_VALUE(replacement_shares) AS shares
        FROM ordered GROUP BY replacement_trade_id)
),
alloc_walk AS (
  SELECT o.k, o.close_trade_id,
         LEAST(o.close_shares,
               (SELECT x.shares FROM UNNEST(lots.l) x WHERE x.lot = o.replacement_trade_id)) AS alloc,
         o.close_shares - LEAST(o.close_shares,
               (SELECT x.shares FROM UNNEST(lots.l) x WHERE x.lot = o.replacement_trade_id)) AS close_left,
         ARRAY(SELECT AS STRUCT x.lot,
                      IF(x.lot = o.replacement_trade_id,
                         x.shares - LEAST(o.close_shares, x.shares), x.shares) AS shares
               FROM UNNEST(lots.l) x) AS lot_state
  FROM ordered o, lots
  WHERE o.k = 1
  UNION ALL
  SELECT o.k, o.close_trade_id,
         LEAST(IF(o.close_trade_id = w.close_trade_id, w.close_left, o.close_shares),
               (SELECT x.shares FROM UNNEST(w.lot_state) x WHERE x.lot = o.replacement_trade_id)) AS alloc,
         IF(o.close_trade_id = w.close_trade_id, w.close_left, o.close_shares)
           - LEAST(IF(o.close_trade_id = w.close_trade_id, w.close_left, o.close_shares),
                   (SELECT x.shares FROM UNNEST(w.lot_state) x WHERE x.lot = o.replacement_trade_id)) AS close_left,
         ARRAY(SELECT AS STRUCT x.lot,
                      IF(x.lot = o.replacement_trade_id,
                         x.shares - LEAST(IF(o.close_trade_id = w.close_trade_id, w.close_left, o.close_shares), x.shares),
                         x.shares) AS shares
               FROM UNNEST(w.lot_state) x) AS lot_state
  FROM alloc_walk w JOIN ordered o ON o.k = w.k + 1
),
per_close AS (
  SELECT close_trade_id, SUM(alloc) AS allocated_replacement_shares
  FROM alloc_walk GROUP BY close_trade_id
),
agg AS (
  SELECT
    close_trade_id, ANY_VALUE(close_strategy) AS close_strategy, ANY_VALUE(ticker) AS ticker,
    ANY_VALUE(close_date) AS close_date, ANY_VALUE(close_realized_pnl) AS close_realized_pnl,
    ANY_VALUE(close_shares) AS close_shares, ANY_VALUE(close_side) AS close_side,
    ARRAY_AGG(STRUCT(replacement_trade_id, replacement_strategy, replacement_date, replacement_shares, days_offset)
              ORDER BY replacement_date) AS replacement_trades,
    ANY_VALUE(pc.allocated_replacement_shares) AS total_replacement_shares_uncapped,
    MIN(days_offset) AS earliest_days_offset,
    MAX(days_offset) AS latest_days_offset
  FROM qualifying_replacements qr
  JOIN per_close pc USING (close_trade_id)
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

-- 219_wash_sale_shared_pool_allocation.sql (2026-09-04) — PARK ALLOCATOR v4, PHASE 1.
-- Project: stock-trading-498512. SUPERSEDES the definition of state.wash_sale_exposure in
-- bigquery/178_park_wash_sale_exposure.sql (chain: 41 -> 178 -> 219). 178 keeps analytics.park_tax_lots
-- and the whole matching/exclusion apparatus, which is carried through here byte-identically apart
-- from the one block named below. Apply after 218.
--
-- ============================ THE DEFECT ========================================================
-- 178 capped each loss-realizing close INDEPENDENTLY at its own close_shares:
--     LEAST(SUM(replacement_shares), close_shares)
-- but the SAME replacement lot was free to be counted IN FULL against EVERY qualifying close. A
-- replacement lot can only replace its own shares ONCE; counting it against several closes
-- double-counts the disallowance.
--
-- WHY IT WAS INVISIBLE AND WHY IT MATTERS NOW. With one close per de-risk episode there is nothing
-- to double-count. The graded ladder (PARK_ALLOCATOR_V4_DESIGN.md §2.3) turns one de-risk into
-- SEVERAL partial closes across sessions, so the same replacement buy becomes a candidate against
-- each step and the overstatement scales with the number of steps. The 2x shape is already visible
-- in live data: the 2026-09-02 park sale is EIGHT partial closes (one order, exchange-split), and
-- every one of them draws on the same August sweep buys.
--
-- ============================ THE FIX ===========================================================
-- Allocate each replacement lot's shares across its qualifying closes OLDEST-CLOSE-FIRST, using the
-- same interval-overlap arithmetic this file already uses to match tax lots to sells:
--     allocated = GREATEST(0, LEAST(consumed_before + close_shares, lot_shares) - consumed_before)
-- Oldest-first is the conservative and conventional reading: the earliest loss in the window is the
-- one the replacement is treated as replacing. The per-close LEAST(..., close_shares) cap is RETAINED
-- downstream, so a close can still never be more than fully replaced.
--
-- SCOPE, unchanged from 178: detection-only. The IBKR 1099-B remains authoritative — see 178's own
-- header and the ~$49 repo-FIFO-vs-broker basis seam recorded in PARK_ALLOCATOR_V4_DESIGN.md §2.6.
-- This view is not a tax filing and no consumer treats it as one.
--
-- ============================ SECOND DEFECT, FOUND WHILE VERIFYING THE FIRST ==================
-- The shared-pool fix alone moved the 2026-09-02 park sale from $107.73 disallowed to $0.33, a
-- reduction too large to accept without asking WHY. It has a second, independent cause, and the
-- right answer was reached partly for the wrong reason until this was fixed:
-- A park SELL is split by the exchange into several partial fills (the 09-02 sale is EIGHT), each
-- with its own parking_events.event_id and therefore its own sell_trade_id. 178's own-basis
-- exclusion is keyed on sell_trade_id, so it removed only the lots FIFO-assigned to THAT leg —
-- leaving the SAME sale's other legs' basis lots to be counted as external replacement purchases.
-- MEASURED: of the 14 replacement lots listed against the 09-02 sale, 13 were that sale's own basis.
-- So the $107.73 figure was substantially an ARTIFACT: a full liquidation cannot be washed by its
-- own basis, and before the 09-04 rebuy the correct exposure on that sale is ~0.
-- Fixed at the root by taking the exclusion set at ORDER level (below). Both defects are real and
-- both are fixed here; the shared-pool allocation still matters independently, because under the
-- graded ladder several SEPARATE de-risk steps (different orders, different days) draw on one
-- replacement pool.
-- NOTE FOR ANYONE RE-READING THE 09-01..09-03 ROUND-TRIP WRITE-UPS. FIVE documents quote the
-- pre-fix figure: bigquery/213's header, PARK_ALLOCATOR_V4_DESIGN.md, Claude_Task_Plan.md,
-- task_plan/D1.md and PARK_ROUTER_DESIGN.md. The last three were corrected 2026-09-04; the first
-- two are LANDED HEADERS and are deliberately NOT edited (editing a landed bigquery/*.sql header
-- is parity drift, and the design doc is the historical handoff record).
-- THREE DIFFERENT RULERS are in play and must never be netted against one another:
--   -149.180705  IBKR account-level realized, AVERAGE-COST basis (ties to the connector exactly)
--   -100.0633    repo FIFO, WHOLE liquidation (analytics.park_tax_lots: 20 fragments, 21.888 sh)
--   -107.7328    repo FIFO, LOSING LEGS ONLY (what this view scopes; winners add back +7.6695)
-- The 49.12 gap between the first two is a BASIS-METHOD SEAM, not an un-disallowed remainder. The
-- realized loss (-$149.18, broker-tied) is unaffected and still correct; the DISALLOWED portion was
-- overstated. The forward-looking statement in those documents — that the 09-04 rebuy will disallow
-- the loss — remains right, and becomes the dominant effect once it fills.
--
-- MEASURED EFFECT AT LANDING is asserted at the foot of this file rather than asserted in prose.

CREATE OR REPLACE VIEW `stock-trading-498512.state.wash_sale_exposure` AS
WITH RECURSIVE losing_sells AS (
  -- Loss-realizing SELLs (closes a LONG strategy position) — unchanged from bigquery/50.
  SELECT trade_id AS close_trade_id, strategy AS close_strategy, ticker,
         DATE(fill_ts, 'America/New_York') AS close_date,
         shares AS close_shares, realized_pnl, 'SELL' AS close_side
  FROM `stock-trading-498512.state.trade_fills_curated`
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
    FROM `stock-trading-498512.analytics.park_tax_lots`
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
  FROM `stock-trading-498512.state.trade_fills_curated`
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
  FROM `stock-trading-498512.state.trade_fills_curated`
  WHERE side = 'BUY' AND ticker != 'SGOV'
    AND shares IS NOT NULL AND shares > 0 AND fill_ts IS NOT NULL
  UNION ALL
  -- NEW: park-side replacement-purchase candidates. BUY and DIVIDEND_REINVEST both count (see file
  -- header); RECON_ADJUST is excluded (bookkeeping correction, not a purchase). Cross-source on
  -- purpose -- a strategy BUY can qualify as a replacement for a park loss-sale and vice versa (this
  -- view's own long-standing whole-taxpayer rationale, extended from cross-strategy to cross-source).
  SELECT event_id AS buy_trade_id, 'PARK' AS buy_strategy, ticker,
         DATE(event_ts, 'America/New_York') AS buy_date, shares AS buy_shares
  FROM `stock-trading-498512.events.parking_events`
  WHERE action IN ('BUY', 'DIVIDEND_REINVEST') AND ticker != 'SGOV'
    AND shares IS NOT NULL AND shares > 0 AND event_ts IS NOT NULL
),
candidate_sells AS (
  -- Symmetric replacement-purchase pool for a losing SHORT COVER (a re-opened SHORT, i.e. a new
  -- SELL) — unchanged from bigquery/50. Deliberately NOT extended with park SELLs: a park SELL
  -- liquidates a long position, it is not "opening a new short", so it has no place in this pool.
  SELECT trade_id AS sell_trade_id, strategy AS sell_strategy, ticker,
         DATE(fill_ts, 'America/New_York') AS sell_date, shares AS sell_shares
  FROM `stock-trading-498512.state.trade_fills_curated`
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
    FROM `stock-trading-498512.analytics.tax_lots`
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
    FROM `stock-trading-498512.analytics.park_tax_lots` ptl
    JOIN `stock-trading-498512.events.parking_events` pe
      ON pe.event_id = ptl.sell_trade_id
    JOIN `stock-trading-498512.events.parking_events` pe_sib
      ON pe_sib.order_id = pe.order_id AND pe_sib.order_id IS NOT NULL
    JOIN `stock-trading-498512.analytics.park_tax_lots` sib
      ON sib.sell_trade_id = pe_sib.event_id
    WHERE ptl.sell_trade_id IS NOT NULL AND sib.buy_trade_id IS NOT NULL
  )
  GROUP BY sell_trade_id
),
own_basis_for_buy AS (
  -- The sell lot(s) that a given losing BUY (cover) itself closed — unchanged from bigquery/50. Park
  -- never covers a short, so a park buy_trade_id never needs an exclusion set here.
  SELECT buy_trade_id, ARRAY_AGG(DISTINCT sell_trade_id) AS own_sell_trade_ids
  FROM `stock-trading-498512.analytics.tax_lots`
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
-- ORDERING HONESTY: oldest-close-first is honored at DATE GRAIN only. Within one date the
-- tie-break is close_trade_id, a GENERATE_UUID() string with NO economic meaning — it is chosen
-- for DETERMINISM, not correctness. Per-share losses differ across legs of one order
-- (-5.7508 / -5.81133 / -5.86137 on the three 2026-07-27 legs), so a different within-date order
-- moves the group total 51.36 -> 51.59, about $0.23. That is the bounded size of the arbitrariness;
-- it does not affect the DATE-grain allocation, which is what the shared-pool fix is about.
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
LEFT JOIN agg a ON a.close_trade_id = c.close_trade_id;

-- ============================ POST-CONDITIONS — SEE dbt/tests/, NOT HERE =======================
-- These invariants were written as ASSERT statements in this file and CANNOT run that way: this view
-- became recursive when the joint allocation walk landed, and BigQuery rejects
-- "WITH RECURSIVE is not supported in ASSERT statements". They were moved verbatim rather than
-- dropped, to dbt/tests/assert_wash_sale_allocation_invariants.sql, which pins:
--   2026-09-02 VOO  -> 0.00   TWO mechanisms, not one -- do not restate this as "there is no
--                            external replacement", which the view's own replacement_trades
--                            contradicts. (a) The order-level sibling exclusion removes 13 of the
--                            14 candidate lots as the sale's OWN basis. (b) The 14th, lot
--                            129b0405 (0.8477 sh), IS a genuine external candidate and still
--                            appears on all five legs at offset -29 -- but the JOINT allocation
--                            walk had already consumed it entirely at the earlier 2026-07-27
--                            close, where the same lot qualifies at offset +8. Zero shares remain
--                            to allocate to 09-02. Mechanism (b) is exactly what the shared-pool
--                            fix exists to model, so this row guards it too.
--   2026-07-27 VOO  -> 77.18  (fully disallowed; the starving allocator read 51.36)
--   2026-06-29 HCA  -> 0.00   (strategy-side arm untouched by the park-specific fix)
-- Realized P&L is broker-tied and unchanged throughout: the 09-02 legs still sum to -107.73.
-- The 09-02 row flips BY DESIGN once the staged 2026-09-04 VOO rebuy fills — re-pin it there, do not
-- delete it.

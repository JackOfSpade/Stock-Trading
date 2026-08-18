-- Park wash-sale blind spot (2026-08-18, interactive-session probe). Project: stock-trading-498512.
--
-- CONFIRMED LIVE (all four claims independently re-verified against primary sources this session,
-- not trusted from a prior report):
--   1. `SELECT COUNT(*) FROM state.wash_sale_exposure WHERE ticker='VOO'` = 0, and
--      `SELECT COUNT(*) FROM events.trade_fills WHERE ticker='VOO'` = 0. state.wash_sale_exposure
--      (bigquery/41_tax_lots.sql, redefined bigquery/50_short_sale_tax_lots.sql) is built from
--      state.trade_fills_curated -> events.trade_fills, which holds ONLY strategy-tagged fills. Every
--      park fill (VOO today; SGOV historically; any future menu ticker) lands in
--      events.parking_events instead — a separate table with no realized_pnl column and no lot-basis
--      concept — so a park round trip has been structurally invisible to the wash-sale watch since
--      that table was created.
--   2. The park's 07-21..07-27 VOO liquidation: read directly from events.parking_events. The 07-15
--      BUY lot (13.4048 sh @ 690.33) is FIFO-consumed by five SELLs (07-21 0.0561 @685.87, 07-22
--      0.1268 @686.61, and three 07-27 legs of 0.2219/6/7 sh, all @684.56-684.62) — realized loss
--      ~-$77.00 before commissions, matching the prior report's estimate. 11.8477 of those 13.4048
--      shares (88.4%) were repurchased on 2026-08-04 @~699.2, 8-14 days later — inside the IRC §1091
--      30-day window.
--   3. `SELECT entry_type, decision, title FROM events.decision_log WHERE entry_type='wash-sale-review'
--      ORDER BY entry_date DESC` — every row 2026-07-12 through 2026-08-17 (the entire life of the
--      review, spanning both legs of the VOO round trip above) reports only Strategy B (HCA/IBM)
--      exposure, $0 estimated disallowed loss, and explicitly "no cross-strategy exposure" — the
--      monitor has been actively, silently wrong about the park's own book for a month.
--   4. `PARK_ROUTER_DESIGN.md` §8 ("Safety rails...") states "Wash sales: monitored via the extended
--      wash-sale watch; the AI is told the lot situation in its briefing" — false as measured above.
--      Fixed in that file, same commit as this one.
--   Mitigating (unchanged by this fix, restated from the ITEM 18 disclaimer this view has always
--   carried): IBKR's own 1099-B computes wash sales at broker/CUSIP level across the WHOLE account
--   regardless of what this repo tracks, so the owner's actual tax liability was never at risk — only
--   this repo's advance-visibility reporting (the whole reason this view exists: "so Claude can SEE
--   exposure building intra-year instead of discovering it only when the 1099-B arrives") was blind.
--
-- FIX (this file, two objects):
--   1. NEW `analytics.park_tax_lots` — an account-wide FIFO lot view over events.parking_events,
--      built with the IDENTICAL cumulative-interval-overlap FIFO technique as `analytics.tax_lots`
--      (bigquery/41/50) — see that view's header for how/why the technique works. Simplified relative
--      to tax_lots in two ways that are correct for park specifically, not a shortcut: no OCC-option
--      multiplier (park only ever holds a plain ETF/equity menu ticker, never an option), and no
--      SHORT-side branch (park is long-only by construction — Operating_Protocols/PARK_ROUTER_DESIGN
--      never let it short). SGOV excluded (`ticker != 'SGOV'`), matching analytics.tax_lots' own SGOV
--      exclusion and this file's header note there: SGOV is the cash-sweep proxy, not a tax-lot
--      security. `action IN ('BUY', 'DIVIDEND_REINVEST')` feeds the buy side — a DRIP reinvestment
--      is a genuine acquisition of the SAME security at a real per-share price and is a well-known
--      unintentional wash-sale trigger under IRC §1091, so excluding it would just be a narrower
--      version of the same blind spot this file exists to close (moot on TODAY's data — VOO carries
--      zero DIVIDEND_REINVEST/RECON_ADJUST rows as of 2026-08-18, verified live — but not moot for a
--      future menu ticker or a future VOO distribution). `RECON_ADJUST` is deliberately EXCLUDED from
--      both sides: it is a §13.D bookkeeping correction against the connector's authoritative holding
--      (bigquery/13_sgov_reconciliation.sql), not a market transaction — it carries no real per-share
--      price and is not a "sale or purchase" for wash-sale purposes.
--   2. REDEFINES `state.wash_sale_exposure` (SUPERSEDES the definitions in bigquery/41_tax_lots.sql
--      and bigquery/50_short_sale_tax_lots.sql — both files' own headers/pointers are updated in the
--      same commit as this file, per bigquery/README.md's supersede discipline) to UNION park's
--      losing closes and park's replacement-purchase candidates into the existing strategy-side
--      populations, HELD AT THE IDENTICAL OUTPUT SHAPE (same 13 columns, same types) so W5's existing
--      reader (Claude_Task_Plan.md ITEM 18: "Read state.wash_sale_exposure... any exposure rows dated
--      since the last W5 run") needs NO change at all. Concretely, relative to bigquery/50:
--        * `losing_sells` gains a second UNION ALL arm: park SELL events aggregated by their own
--          sell_trade_id (= parking_events.event_id) via analytics.park_tax_lots, filtered to a net
--          realized loss — matching the existing arm's granularity of "one row per actual disposing
--          fill", not one row per FIFO lot-fragment. `close_strategy = 'PARK'` (a literal, non-NULL
--          tag distinguishable from the A-E strategy codes — park has no per-strategy attribution,
--          same reasoning bigquery/13's header already gives for events.parking_events.strategy being
--          NULL on every row).
--        * `candidate_buys` (the replacement-purchase pool) gains a second UNION ALL arm: park
--          BUY/DIVIDEND_REINVEST events. This makes the check CROSS-SOURCE, not just cross-strategy —
--          a strategy's future BUY of a ticker the park just loss-sold (or vice versa: a park BUY
--          replacing a strategy's loss-sale) now counts as a qualifying replacement, consistent with
--          this view's own long-standing header note that "the IRS wash-sale rule operates at the
--          TAXPAYER (whole-account) level, not per internal strategy attribution" — the same
--          principle that already justified the cross-STRATEGY check is extended to cross-SOURCE.
--          (No live effect today: VOO has never been a strategy-traded ticker — confirmed 0 rows in
--          events.trade_fills for ticker='VOO' — so this arm is presently a no-op broadening, not a
--          behavior change on live data.)
--        * `own_basis_for_sell` (excludes a close's OWN FIFO cost-basis buy leg(s) from being
--          double-counted as its own "replacement") is unioned across analytics.tax_lots AND
--          analytics.park_tax_lots so a park close's own basis is excluded the same way a strategy
--          close's is. The two sources' trade_id key spaces never collide (IBKR's own trade_id format
--          vs. parking_events.event_id, a GENERATE_UUID() string), so no cross-source ambiguity.
--        * `losing_covers`, `candidate_sells`, and `own_basis_for_buy` are UNCHANGED — that machinery
--          exists only for a losing SHORT COVER's replacement re-short, and park never shorts, so
--          there is nothing for park to add there. Adding park SELLs to `candidate_sells` would be
--          semantically wrong regardless (a park SELL liquidates a long position; it is not "opening
--          a new short"), so it is deliberately left alone rather than broadened by analogy.
--      INHERITED, NOT INTRODUCED, METHODOLOGICAL NOTE: bigquery/50's `estimated_disallowed_loss` caps
--      each CLOSE's own replacement shares against that close's OWN pool of qualifying buys in its OWN
--      30-day window, independently per close row — it does not allocate a single replacement lot's
--      shares across multiple closes that each separately qualify for it. On the VOO round trip above,
--      the five park closes each independently see the full 11.8477-share 08-04 replacement (every
--      close's own window contains it), so each is individually reported near/at full disallowance
--      rather than the pool being split ~88.4%/11.6% pro rata across the five. This is the SAME
--      simplification bigquery/50 already applies to strategy trades (a strategy with several
--      loss-sells all replaced by one larger buy exhibits the identically-shaped effect) — this file
--      does not change that methodology, for park or for strategy, only extends its INPUT population.
--      Still directionally correct and still strictly more informative than the current $0/zero-rows
--      status quo; a shared-pool allocation refinement (if ever wanted) is a separate, deliberate
--      change to bigquery/50's original design, not something to fold in here.
--
-- DETECTION / REPORTING ONLY — unchanged from every prior revision of this view. Changes no gate, no
-- sizing, no kill trigger, blocks nothing. IBKR's own 1099-B (computed off the account's ELECTED
-- cost-basis method) remains the authoritative tax figure; this layer exists so exposure is visible
-- intra-year instead of discovered only when the 1099-B arrives.
--
-- NOT APPLIED LIVE BY THIS SESSION (interactive session — operator approves push/apply separately).
-- Apply after bigquery/01_schema.sql (events.parking_events), bigquery/41_tax_lots.sql,
-- bigquery/50_short_sale_tax_lots.sql (state.trade_fills_curated, analytics.tax_lots — this file reads
-- both but redefines neither), bigquery/53_curated_view_tiebreak_fix.sql (state.trade_fills_curated's
-- canonical tiebreak), bigquery/54_park_policy_voo_cutover.sql (events.parking_events.ticker column).

-- ============================================================================
-- analytics.park_tax_lots — account-wide FIFO lot view over events.parking_events, keyed by ticker
-- only (park has no strategy attribution to wall against — see header). SGOV excluded (cash-sweep
-- proxy, not a tax-lot security). Long-only (park never shorts): only a CLOSED/OPEN-long shape is
-- produced, the symmetric short branches in analytics.tax_lots (bigquery/50) do not apply here.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.park_tax_lots` AS
WITH buys AS (
  SELECT event_id AS trade_id, ticker, event_ts AS fill_ts, price, shares, commission,
         SAFE_DIVIDE(commission, NULLIF(shares, 0)) AS commission_per_share,
         -- cum_start = total park BUY/DIVIDEND_REINVEST shares in this ticker strictly before this
         -- event (FIFO entry order) — identical technique to analytics.tax_lots' `buys` CTE.
         COALESCE(SUM(shares) OVER (
           PARTITION BY ticker ORDER BY event_ts, event_id
           ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS cum_start
  FROM `stock-trading-498512.events.parking_events`
  WHERE action IN ('BUY', 'DIVIDEND_REINVEST') AND ticker != 'SGOV'
    AND shares IS NOT NULL AND shares > 0 AND price IS NOT NULL
),
sells AS (
  SELECT event_id AS trade_id, ticker, event_ts AS fill_ts, price, shares, commission,
         SAFE_DIVIDE(commission, NULLIF(shares, 0)) AS commission_per_share,
         -- cum_start = total park SELL shares in this ticker strictly before this event (FIFO
         -- consumption order). RECON_ADJUST is excluded here (see file header) -- it is a bookkeeping
         -- correction, not a disposal, and has no realized-gain meaning.
         COALESCE(SUM(shares) OVER (
           PARTITION BY ticker ORDER BY event_ts, event_id
           ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS cum_start
  FROM `stock-trading-498512.events.parking_events`
  WHERE action = 'SELL' AND ticker != 'SGOV'
    AND shares IS NOT NULL AND shares > 0 AND price IS NOT NULL
),
matched AS (
  SELECT
    b.ticker,
    b.trade_id AS buy_trade_id, b.fill_ts AS buy_fill_ts, b.price AS buy_price,
    b.commission_per_share AS buy_commission_per_share,
    s.trade_id AS sell_trade_id, s.fill_ts AS sell_fill_ts, s.price AS sell_price,
    s.commission_per_share AS sell_commission_per_share,
    LEAST(b.cum_start + b.shares, s.cum_start + s.shares) - GREATEST(b.cum_start, s.cum_start) AS matched_shares
  FROM buys b
  JOIN sells s ON s.ticker = b.ticker
  WHERE LEAST(b.cum_start + b.shares, s.cum_start + s.shares) > GREATEST(b.cum_start, s.cum_start)
),
buy_matched_totals AS (
  SELECT buy_trade_id, SUM(matched_shares) AS total_matched
  FROM matched
  GROUP BY buy_trade_id
),
open_remainder AS (
  SELECT
    b.ticker, b.trade_id AS buy_trade_id, b.fill_ts AS buy_fill_ts, b.price AS buy_price,
    b.commission_per_share AS buy_commission_per_share,
    b.shares - COALESCE(t.total_matched, 0) AS open_shares
  FROM buys b
  LEFT JOIN buy_matched_totals t ON t.buy_trade_id = b.trade_id
  WHERE b.shares - COALESCE(t.total_matched, 0) > 0.0000001   -- guard FP noise on fractional-share fills
)
-- CLOSED lot pieces (a buy fragment matched to a sell fragment).
SELECT
  CONCAT(ticker, ':', buy_trade_id, ':', sell_trade_id)           AS lot_id,
  ticker,
  buy_trade_id, DATE(buy_fill_ts, 'America/New_York') AS entry_date,
  sell_trade_id, DATE(sell_fill_ts, 'America/New_York') AS exit_date,
  'CLOSED' AS status,
  matched_shares AS shares,
  buy_price AS entry_price, sell_price AS exit_price,
  ROUND(matched_shares * buy_price
        + matched_shares * COALESCE(buy_commission_per_share, 0), 4)  AS cost_basis,
  ROUND(matched_shares * sell_price
        - matched_shares * COALESCE(sell_commission_per_share, 0), 4) AS proceeds,
  ROUND((matched_shares * sell_price - matched_shares * COALESCE(sell_commission_per_share, 0))
        - (matched_shares * buy_price + matched_shares * COALESCE(buy_commission_per_share, 0)), 4) AS realized_gain_loss,
  DATE_DIFF(DATE(sell_fill_ts, 'America/New_York'), DATE(buy_fill_ts, 'America/New_York'), DAY) AS holding_period_days,
  IF(DATE(sell_fill_ts, 'America/New_York') > DATE_ADD(DATE(buy_fill_ts, 'America/New_York'), INTERVAL 1 YEAR),
     'LONG_TERM', 'SHORT_TERM') AS term
FROM matched
UNION ALL
-- OPEN lot remainders (no sell yet, or only partially sold) — the park's current holding.
SELECT
  CONCAT(ticker, ':', buy_trade_id, ':OPEN')                      AS lot_id,
  ticker,
  buy_trade_id, DATE(buy_fill_ts, 'America/New_York') AS entry_date,
  CAST(NULL AS STRING) AS sell_trade_id, CAST(NULL AS DATE) AS exit_date,
  'OPEN' AS status,
  open_shares AS shares,
  buy_price AS entry_price, CAST(NULL AS NUMERIC) AS exit_price,
  ROUND(open_shares * buy_price
        + open_shares * COALESCE(buy_commission_per_share, 0), 4) AS cost_basis,
  CAST(NULL AS NUMERIC) AS proceeds,
  CAST(NULL AS NUMERIC) AS realized_gain_loss,
  DATE_DIFF(CURRENT_DATE('America/New_York'), DATE(buy_fill_ts, 'America/New_York'), DAY) AS holding_period_days,
  IF(CURRENT_DATE('America/New_York') > DATE_ADD(DATE(buy_fill_ts, 'America/New_York'), INTERVAL 1 YEAR),
     'LONG_TERM', 'SHORT_TERM') AS term
FROM open_remainder;

-- ============================================================================
-- state.wash_sale_exposure — REDEFINED (SUPERSEDES bigquery/41 and bigquery/50): same 13-column
-- output shape as before; the loss-realizing and replacement-candidate populations now also cover
-- park round trips (see file header for exactly what changed and why). Short-sale logic
-- (losing_covers / candidate_sells / own_basis_for_buy) is copied verbatim from bigquery/50 —
-- park never shorts, so nothing there needed to change.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.wash_sale_exposure` AS
WITH losing_sells AS (
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
    SELECT sell_trade_id, buy_trade_id
    FROM `stock-trading-498512.analytics.park_tax_lots`
    WHERE sell_trade_id IS NOT NULL AND buy_trade_id IS NOT NULL
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
LEFT JOIN agg a ON a.close_trade_id = c.close_trade_id;

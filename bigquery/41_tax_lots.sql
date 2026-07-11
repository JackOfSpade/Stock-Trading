-- Wash-sale / tax-lot detection layer (Item 18, self-improvement audit 2026-07-11). Project:
-- stock-trading-498512. Apply after 01_schema.sql (events.trade_fills, state.trade_fills_curated,
-- state.current_positions) and 03_twr_engine.sql (analytics.position_lifecycle — this file is
-- deliberately NOT built on top of that view; see the note below). Idempotent (CREATE OR REPLACE
-- VIEW throughout; no tables, no INSERTs, no mutation of any other object).
--
-- WHY THIS EXISTS. The system is the SOLE books-of-record for a taxable IBKR account and computes a
-- post-tax success metric (Experiment_Parameters.md: "excess real return ... post-fees, post-taxes,
-- post-inflation"; §"Taxes calculated at actual marginal rates, with short-term capital gains treated
-- as ordinary income; LTCG for positions held >=12 months"). Despite that, the system had ZERO
-- wash-sale / tax-lot concept before this file (grep for 'wash'/'8949'/'substantially identical' = 0
-- hits as of 2026-07-11). A wash sale (IRC §1091: a loss-realizing SELL followed or preceded within
-- 30 calendar days by a purchase of the SAME or a "substantially identical" security) disallows the
-- loss for CURRENT-YEAR tax purposes and adds it to the replacement lot's basis instead — if this
-- system's post-tax metric assumes every realized loss is currently deductible, it can be silently
-- overstating post-tax performance on any strategy (or cross-strategy pair) that re-enters a name it
-- recently exited at a loss. SISA (bigquery/35_strategy_arsenal.sql) makes this MORE likely, not
-- less: independent strategies can legitimately hold/trade the SAME ticker walled apart from each
-- other's P&L (position_lifecycle pairs by (strategy,ticker,leg_seq) on purpose), but the IRS wash-
-- sale rule operates at the TAXPAYER (whole-account) level, not per internal strategy attribution —
-- a Strategy-D loss-sale in NVDA and a same-week Strategy-A NVDA entry are two independent trading
-- decisions in this system's model but ONE wash sale to the IRS. This file is DETECTION / REPORTING
-- ONLY. It changes no gate, no sizing, no kill trigger, and blocks nothing:
--   * IBKR remains the tax authority. IBKR's own 1099-B wash-sale adjustments (computed off the
--     account's ELECTED cost-basis method) are the authoritative figures at tax-filing time; this
--     layer exists so Claude can SEE exposure building intra-year instead of discovering it only when
--     the 1099-B arrives — it is a heads-up/estimate layer, not a substitute return.
--   * A COST-BASIS METHOD MUST BE ELECTED WITH IBKR (default is typically FIFO, applied ACCOUNT-WIDE
--     across the whole taxpayer, not per internal strategy) before analytics.tax_lots below can be
--     reconciled to the broker's own lot accounting. This file assumes FIFO (matching the presumed
--     IBKR default) purely for its OWN internal lot construction; if the owner elects a different
--     method (e.g. specific-ID) with IBKR, analytics.tax_lots will diverge from the broker's 1099-B
--     lot-by-lot (though total shares/proceeds still reconcile) — see owner_actions in the review
--     packet that shipped this file. Do NOT infer a cost-basis election from this file's existence.
--
-- WHY NOT dbt/dbt models/analytics/position_lifecycle.sql AS THE INPUT. That view (and its BigQuery
-- twin, analytics.position_lifecycle in 03_twr_engine.sql) intentionally pairs BUY/SELL legs WITHIN
-- one (strategy, ticker) — it is the deployed-TWR profitability engine's input and the per-strategy
-- wall is the whole point (03_twr_engine.sql:81-83). Reusing it here would silently inherit that wall
-- into a tax computation where the wall does NOT apply, undercounting cross-strategy wash-sale
-- exposure. analytics.tax_lots below re-derives its own account-wide FIFO matching straight from
-- events.trade_fills (via state.trade_fills_curated, the idempotent dedup-by-trade_id view — same
-- source, same curation discipline, just partitioned by ticker only, not (strategy, ticker)).
--
-- SGOV EXCLUSION: SGOV is the shared account-level cash-sweep proxy (events.parking_events, NOT
-- events.trade_fills under normal operation — see bigquery/13_sgov_reconciliation.sql), not a traded
-- security for tax-lot purposes; both objects below filter ticker != 'SGOV' defensively in case a
-- stray SGOV row ever lands in trade_fills (mirrors the SGOV filter in analytics.position_lifecycle).
--
-- FAIL-CLOSED DEFAULT: state.wash_sale_exposure defaults every SELL to has_exposure = FALSE /
-- estimated_disallowed_loss = 0 unless a qualifying replacement BUY is POSITIVELY found in the window
-- — it never flags on missing/NULL data (a NULL realized_pnl, shares, or fill_ts on either leg simply
-- excludes that row from the exposure population rather than defaulting it to exposed). This is a
-- reporting view with no downstream gate today; the fail-closed convention is followed anyway so a
-- future W5-digest read (see the shared_edits note in the review packet — NOT wired by this file)
-- inherits safe semantics for free.

-- ============================================================================
-- analytics.tax_lots — account-wide FIFO lot view keyed by TICKER ONLY (crosses the per-strategy
-- wall on purpose — see header). Built with the classic SQL "cumulative-interval overlap" FIFO
-- technique: every BUY occupies a half-open interval [cum_shares_before_this_buy, cum_shares_after)
-- on a per-ticker number line, in fill-time order (= FIFO entry order into inventory); every SELL
-- occupies the same kind of interval, in its OWN fill-time order (= FIFO consumption order). Because
-- both cumulative sequences are ordered by time independently of each other, the overlap between a
-- given BUY interval and a given SELL interval is EXACTLY the quantity of that buy's shares consumed
-- by that sell under FIFO — correct regardless of how buys/sells interleave in time, and correct for
-- partial-lot fills (a SELL that only consumes part of a BUY, or is itself only partly filled from
-- one BUY and partly from the next). This needs no procedural loop, so it is expressible as a view.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.tax_lots` AS
WITH buys AS (
  SELECT trade_id, strategy, ticker, fill_ts, price, shares, commission,
         SAFE_DIVIDE(commission, NULLIF(shares, 0)) AS commission_per_share,
         -- cum_start = total BUY shares in this ticker strictly before this fill (FIFO entry order)
         COALESCE(SUM(shares) OVER (
           PARTITION BY ticker ORDER BY fill_ts, trade_id
           ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS cum_start
  FROM `stock-trading-498512.state.trade_fills_curated`
  WHERE side = 'BUY' AND ticker != 'SGOV' AND shares IS NOT NULL AND shares > 0
),
sells AS (
  SELECT trade_id, strategy, ticker, fill_ts, price, shares, commission, realized_pnl,
         SAFE_DIVIDE(commission, NULLIF(shares, 0)) AS commission_per_share,
         -- cum_start = total SELL shares in this ticker strictly before this fill (FIFO consumption order)
         COALESCE(SUM(shares) OVER (
           PARTITION BY ticker ORDER BY fill_ts, trade_id
           ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS cum_start
  FROM `stock-trading-498512.state.trade_fills_curated`
  WHERE side = 'SELL' AND ticker != 'SGOV' AND shares IS NOT NULL AND shares > 0
),
-- Every (buy, sell) pair on the same ticker whose cumulative-share intervals overlap; the overlap
-- width is the FIFO-matched share count between that specific buy lot and that specific sell fill.
matched AS (
  SELECT
    b.ticker,
    b.trade_id AS buy_trade_id, b.strategy AS buy_strategy, b.fill_ts AS buy_fill_ts,
    b.price AS buy_price, b.commission_per_share AS buy_commission_per_share,
    s.trade_id AS sell_trade_id, s.strategy AS sell_strategy, s.fill_ts AS sell_fill_ts,
    s.price AS sell_price, s.commission_per_share AS sell_commission_per_share,
    LEAST(b.cum_start + b.shares, s.cum_start + s.shares) - GREATEST(b.cum_start, s.cum_start) AS matched_shares
  FROM buys b
  JOIN sells s ON s.ticker = b.ticker
  WHERE LEAST(b.cum_start + b.shares, s.cum_start + s.shares) > GREATEST(b.cum_start, s.cum_start)
),
-- Portion of each BUY not yet consumed by any SELL to date = still-open shares of that lot.
buy_matched_totals AS (
  SELECT buy_trade_id, SUM(matched_shares) AS total_matched
  FROM matched
  GROUP BY buy_trade_id
),
open_remainder AS (
  SELECT
    b.ticker, b.trade_id AS buy_trade_id, b.strategy AS buy_strategy, b.fill_ts AS buy_fill_ts,
    b.price AS buy_price, b.commission_per_share AS buy_commission_per_share,
    b.shares - COALESCE(t.total_matched, 0) AS open_shares
  FROM buys b
  LEFT JOIN buy_matched_totals t ON t.buy_trade_id = b.trade_id
  WHERE b.shares - COALESCE(t.total_matched, 0) > 0.0000001   -- guard FP noise on fractional-share fills
)
-- CLOSED lot pieces (buy matched to a sell)
SELECT
  CONCAT(ticker, ':', buy_trade_id, ':', sell_trade_id)           AS lot_id,
  ticker,
  buy_trade_id, buy_strategy, DATE(buy_fill_ts, 'America/New_York') AS entry_date,
  sell_trade_id, sell_strategy, DATE(sell_fill_ts, 'America/New_York') AS exit_date,
  'CLOSED' AS status,
  matched_shares AS shares,
  buy_price AS entry_price, sell_price AS exit_price,
  ROUND(matched_shares * (buy_price + COALESCE(buy_commission_per_share, 0)), 4)  AS cost_basis,
  ROUND(matched_shares * (sell_price - COALESCE(sell_commission_per_share, 0)), 4) AS proceeds,
  ROUND(matched_shares * (sell_price - COALESCE(sell_commission_per_share, 0))
        - matched_shares * (buy_price + COALESCE(buy_commission_per_share, 0)), 4) AS realized_gain_loss,
  DATE_DIFF(DATE(sell_fill_ts, 'America/New_York'), DATE(buy_fill_ts, 'America/New_York'), DAY) AS holding_period_days,
  IF(DATE_DIFF(DATE(sell_fill_ts, 'America/New_York'), DATE(buy_fill_ts, 'America/New_York'), DAY) > 365,
     'LONG_TERM', 'SHORT_TERM') AS term
FROM matched
UNION ALL
-- OPEN lot remainders (no sell yet, or only partially sold) — mark-free, cost-basis-only rows; term
-- and holding_period_days are AS-OF-TODAY snapshots and will drift day to day for a still-open lot.
SELECT
  CONCAT(ticker, ':', buy_trade_id, ':OPEN')                      AS lot_id,
  ticker,
  buy_trade_id, buy_strategy, DATE(buy_fill_ts, 'America/New_York') AS entry_date,
  CAST(NULL AS STRING) AS sell_trade_id, CAST(NULL AS STRING) AS sell_strategy, CAST(NULL AS DATE) AS exit_date,
  'OPEN' AS status,
  open_shares AS shares,
  buy_price AS entry_price, CAST(NULL AS NUMERIC) AS exit_price,
  ROUND(open_shares * (buy_price + COALESCE(buy_commission_per_share, 0)), 4) AS cost_basis,
  CAST(NULL AS NUMERIC) AS proceeds,
  CAST(NULL AS NUMERIC) AS realized_gain_loss,
  DATE_DIFF(CURRENT_DATE('America/New_York'), DATE(buy_fill_ts, 'America/New_York'), DAY) AS holding_period_days,
  IF(DATE_DIFF(CURRENT_DATE('America/New_York'), DATE(buy_fill_ts, 'America/New_York'), DAY) > 365,
     'LONG_TERM', 'SHORT_TERM') AS term
FROM open_remainder;

-- ============================================================================
-- state.wash_sale_exposure — one row per LOSS-realizing SELL (any strategy, any ticker except SGOV),
-- flagging whether a REPLACEMENT purchase (any strategy, same ticker, NOT one of the buy lot(s) that
-- this specific sell's own cost basis is FIFO-matched against) landed within 30 calendar days before
-- OR after the sell. Includes kill-trigger liquidations and SISA termination sales on purpose — they
-- are ordinary SELL rows in events.trade_fills with no distinguishing "reason" tag, so nothing here
-- filters them out; a strategy-kill/termination sale that happens to be followed by another strategy's
-- entry in the same name is exactly the cross-strategy exposure this view exists to catch.
--
-- "Within 30 days... of the SAME ticker" is IRC §1091's own text (substantially-identical is narrower
-- than "same ticker" for options/convertibles, but every position this system trades is a single-class
-- equity/ETF, so same-ticker IS substantially-identical here — no separate similarity model needed).
--
-- ESTIMATED disallowed-loss amount (clearly an ESTIMATE, not a filing figure): for a given loss sale,
-- replacement shares are capped at the shares actually sold (buying MORE than you sold does not
-- disallow MORE than the original loss), and the disallowed amount is the sale's loss prorated by
-- (capped replacement shares / shares sold) — full disallowance once replacement shares >= shares sold.
CREATE OR REPLACE VIEW `stock-trading-498512.state.wash_sale_exposure` AS
WITH losing_sells AS (
  SELECT trade_id AS sell_trade_id, strategy AS sell_strategy, ticker,
         fill_ts AS sell_fill_ts, DATE(fill_ts, 'America/New_York') AS sell_date,
         shares AS sell_shares, price AS sell_price, realized_pnl
  FROM `stock-trading-498512.state.trade_fills_curated`
  WHERE side = 'SELL' AND ticker != 'SGOV'
    AND realized_pnl IS NOT NULL AND realized_pnl < 0
    AND shares IS NOT NULL AND shares > 0 AND fill_ts IS NOT NULL
),
candidate_buys AS (
  SELECT trade_id AS buy_trade_id, strategy AS buy_strategy, ticker,
         fill_ts AS buy_fill_ts, DATE(fill_ts, 'America/New_York') AS buy_date, shares AS buy_shares
  FROM `stock-trading-498512.state.trade_fills_curated`
  WHERE side = 'BUY' AND ticker != 'SGOV'
    AND shares IS NOT NULL AND shares > 0 AND fill_ts IS NOT NULL
),
-- The buy lot(s) that ARE this sell's own FIFO cost basis — excluded below, since closing a position
-- via its own original entry is not a "replacement purchase".
own_cost_basis AS (
  SELECT sell_trade_id, ARRAY_AGG(DISTINCT buy_trade_id) AS own_buy_trade_ids
  FROM `stock-trading-498512.analytics.tax_lots`
  WHERE sell_trade_id IS NOT NULL
  GROUP BY sell_trade_id
),
qualifying_buys AS (
  SELECT
    s.sell_trade_id, s.sell_strategy, s.ticker, s.sell_date, s.realized_pnl AS sell_realized_pnl,
    s.sell_shares,
    b.buy_trade_id, b.buy_strategy, b.buy_date, b.buy_shares,
    DATE_DIFF(b.buy_date, s.sell_date, DAY) AS days_offset
  FROM losing_sells s
  JOIN candidate_buys b ON b.ticker = s.ticker
  LEFT JOIN own_cost_basis ocb ON ocb.sell_trade_id = s.sell_trade_id
  WHERE DATE_DIFF(b.buy_date, s.sell_date, DAY) BETWEEN -30 AND 30
    AND NOT (ocb.own_buy_trade_ids IS NOT NULL AND b.buy_trade_id IN UNNEST(ocb.own_buy_trade_ids))
),
agg AS (
  SELECT
    sell_trade_id, ANY_VALUE(sell_strategy) AS sell_strategy, ANY_VALUE(ticker) AS ticker,
    ANY_VALUE(sell_date) AS sell_date, ANY_VALUE(sell_realized_pnl) AS sell_realized_pnl,
    ANY_VALUE(sell_shares) AS sell_shares,
    ARRAY_AGG(STRUCT(buy_trade_id, buy_strategy, buy_date, buy_shares, days_offset) ORDER BY buy_date) AS replacement_buys,
    SUM(buy_shares) AS total_replacement_shares_uncapped,
    MIN(days_offset) AS earliest_days_offset,
    MAX(days_offset) AS latest_days_offset
  FROM qualifying_buys
  GROUP BY sell_trade_id
)
-- Base population = EVERY loss-realizing SELL (SGOV-excluded, non-NULL data). LEFT JOIN to the
-- qualifying-buy aggregation so a sell with no replacement purchase in the window defaults cleanly to
-- has_exposure = FALSE / estimated_disallowed_loss = 0 — never NULL, never a stray "exposed" flag on
-- missing data (fail-closed, per the header note).
SELECT
  s.sell_trade_id, s.sell_strategy, s.ticker, s.sell_date, s.sell_shares,
  s.realized_pnl AS sell_realized_pnl,
  a.sell_trade_id IS NOT NULL AS has_exposure,
  COALESCE(a.replacement_buys, []) AS replacement_buys,
  LEAST(COALESCE(a.total_replacement_shares_uncapped, 0), s.sell_shares) AS capped_replacement_shares,
  a.earliest_days_offset, a.latest_days_offset,
  ROUND(ABS(s.realized_pnl)
        * SAFE_DIVIDE(LEAST(COALESCE(a.total_replacement_shares_uncapped, 0), s.sell_shares), s.sell_shares),
        2) AS estimated_disallowed_loss
FROM losing_sells s
LEFT JOIN agg a ON a.sell_trade_id = s.sell_trade_id;

-- ITEM: analytics.tax_lots / state.wash_sale_exposure hardcode BUY=entry/SELL=exit and only scan
-- SELL rows for a realized loss, silently mis-handling short positions (2026-07-14 self-improvement
-- audit, finding sql-late#1).
--
-- BUG: bigquery/41_tax_lots.sql's `matched` CTE FIFO-pairs BUY and SELL legs on the same ticker
-- regardless of which one happened first, but the CLOSED-lot projection always labels the BUY leg
-- "entry" and the SELL leg "exit". For a short sale (SELL opens, BUY covers/closes) -- Strategy E's
-- entire mechanism is "long L / short S" and it is roster-adopted since 2026-04-23 -- this makes
-- entry_date LATER than exit_date (the cover date reported as "entry", the open date as "exit"),
-- producing a negative holding_period_days and an inverted term/lifecycle direction. Separately,
-- state.wash_sale_exposure's `losing_sells` CTE only reads `side='SELL' AND realized_pnl < 0` to find
-- loss-realizing closes -- per Claude_Task_Plan.md ("Take realized P&L from the connector's
-- realized_pnl field"), IBKR attaches realized_pnl to whichever execution actually closes the
-- position, which for a short sale is the BUY (cover), not the SELL (open) -- so a losing short-cover
-- never enters the `losing_sells` population and is entirely invisible to wash-sale detection.
-- Confirmed latent (not yet manifested) via a live read-only query: state.trade_fills_curated
-- currently has 0 rows for strategy='E' and no shorts elsewhere -- but this will start silently
-- corrupting both views the first time E's router activates.
--
-- FIX (this file):
--   1. analytics.tax_lots: CLOSED-lot entry/exit date+price now derive from CHRONOLOGICAL order
--      (whichever leg's fill_ts is earlier is "entry"), not a hardcoded buy=entry/sell=exit
--      assumption. cost_basis/proceeds/realized_gain_loss are UNCHANGED -- those are pure dollar
--      arithmetic off buy_price/sell_price directly and are already correct regardless of order (a
--      short's "cost to cover" = the buy leg, "proceeds at open" = the sell leg, which is exactly
--      what cost_basis/proceeds already compute). A new `position_side` column ('LONG'/'SHORT') is
--      added so a consumer can distinguish direction. Also adds a symmetric OPEN-SHORT lot branch
--      (an unconsumed SELL = an open short position) -- previously every open short had ZERO rows in
--      analytics.tax_lots.
--   2. state.wash_sale_exposure: the loss-realizing population is now BOTH losing SELLs (closes a
--      long) and losing BUYs/covers (closes a short), each checked against its OWN symmetric
--      replacement-purchase pool (a losing SELL's replacement candidates are BUYs; a losing
--      cover's replacement candidates are re-shorts, i.e. SELLs) within the 30-day window, excluding
--      each close's own FIFO cost-basis trade(s) from counting as a "replacement". Column names are
--      generalized (close_trade_id/close_side, not sell_trade_id) since nothing in the repo consumes
--      this view yet (verified via repo-wide grep) -- there is no backward-compatibility constraint.
--
-- SUPERSEDES the analytics.tax_lots and state.wash_sale_exposure VIEW definitions in
-- bigquery/41_tax_lots.sql. No dbt mirror exists for either view. Apply after 41_tax_lots.sql,
-- 46_weekly_benchmarks.sql.

CREATE OR REPLACE VIEW `stock-trading-498512.analytics.tax_lots` AS
WITH buys AS (
  SELECT trade_id, strategy, ticker, fill_ts, price, shares, commission,
         IF(`stock-trading-498512.analytics.fn_is_occ_option_symbol`(ticker), 100, 1) AS multiplier,
         SAFE_DIVIDE(commission, NULLIF(shares, 0)) AS commission_per_share,
         COALESCE(SUM(shares) OVER (
           PARTITION BY ticker ORDER BY fill_ts, trade_id
           ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS cum_start
  FROM `stock-trading-498512.state.trade_fills_curated`
  WHERE side = 'BUY' AND ticker != 'SGOV' AND shares IS NOT NULL AND shares > 0
),
sells AS (
  SELECT trade_id, strategy, ticker, fill_ts, price, shares, commission, realized_pnl,
         IF(`stock-trading-498512.analytics.fn_is_occ_option_symbol`(ticker), 100, 1) AS multiplier,
         SAFE_DIVIDE(commission, NULLIF(shares, 0)) AS commission_per_share,
         COALESCE(SUM(shares) OVER (
           PARTITION BY ticker ORDER BY fill_ts, trade_id
           ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS cum_start
  FROM `stock-trading-498512.state.trade_fills_curated`
  WHERE side = 'SELL' AND ticker != 'SGOV' AND shares IS NOT NULL AND shares > 0
),
matched AS (
  SELECT
    b.ticker,
    b.multiplier AS multiplier,
    b.trade_id AS buy_trade_id, b.strategy AS buy_strategy, b.fill_ts AS buy_fill_ts,
    b.price AS buy_price, b.commission_per_share AS buy_commission_per_share,
    s.trade_id AS sell_trade_id, s.strategy AS sell_strategy, s.fill_ts AS sell_fill_ts,
    s.price AS sell_price, s.commission_per_share AS sell_commission_per_share,
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
    b.ticker, b.multiplier, b.trade_id AS buy_trade_id, b.strategy AS buy_strategy, b.fill_ts AS buy_fill_ts,
    b.price AS buy_price, b.commission_per_share AS buy_commission_per_share,
    b.shares - COALESCE(t.total_matched, 0) AS open_shares
  FROM buys b
  LEFT JOIN buy_matched_totals t ON t.buy_trade_id = b.trade_id
  WHERE b.shares - COALESCE(t.total_matched, 0) > 0.0000001
),
-- NEW: portion of each SELL not yet consumed by any BUY to date = still-open shares of a SHORT
-- position (the symmetric counterpart to open_remainder above).
sell_matched_totals AS (
  SELECT sell_trade_id, SUM(matched_shares) AS total_matched
  FROM matched
  GROUP BY sell_trade_id
),
open_remainder_short AS (
  SELECT
    s.ticker, s.multiplier, s.trade_id AS sell_trade_id, s.strategy AS sell_strategy, s.fill_ts AS sell_fill_ts,
    s.price AS sell_price, s.commission_per_share AS sell_commission_per_share,
    s.shares - COALESCE(t.total_matched, 0) AS open_shares
  FROM sells s
  LEFT JOIN sell_matched_totals t ON t.sell_trade_id = s.trade_id
  WHERE s.shares - COALESCE(t.total_matched, 0) > 0.0000001
)
-- CLOSED lot pieces (buy matched to a sell) -- entry/exit now derive from CHRONOLOGICAL order
-- (whichever leg's fill_ts is earlier is "entry"), not a hardcoded buy=entry/sell=exit assumption.
SELECT
  CONCAT(ticker, ':', buy_trade_id, ':', sell_trade_id)           AS lot_id,
  ticker,
  buy_trade_id, buy_strategy,
  IF(buy_fill_ts <= sell_fill_ts, DATE(buy_fill_ts, 'America/New_York'), DATE(sell_fill_ts, 'America/New_York')) AS entry_date,
  sell_trade_id, sell_strategy,
  IF(buy_fill_ts <= sell_fill_ts, DATE(sell_fill_ts, 'America/New_York'), DATE(buy_fill_ts, 'America/New_York')) AS exit_date,
  'CLOSED' AS status,
  matched_shares AS shares,
  IF(buy_fill_ts <= sell_fill_ts, buy_price, sell_price) AS entry_price,
  IF(buy_fill_ts <= sell_fill_ts, sell_price, buy_price) AS exit_price,
  -- cost_basis/proceeds/realized_gain_loss are UNCHANGED from the original: pure dollar arithmetic
  -- off buy_price/sell_price directly, already correct for a short (cost to cover = buy leg,
  -- proceeds at open = sell leg) regardless of chronological order.
  ROUND(matched_shares * multiplier * buy_price
        + matched_shares * COALESCE(buy_commission_per_share, 0), 4)  AS cost_basis,
  ROUND(matched_shares * multiplier * sell_price
        - matched_shares * COALESCE(sell_commission_per_share, 0), 4) AS proceeds,
  ROUND((matched_shares * multiplier * sell_price - matched_shares * COALESCE(sell_commission_per_share, 0))
        - (matched_shares * multiplier * buy_price + matched_shares * COALESCE(buy_commission_per_share, 0)), 4) AS realized_gain_loss,
  DATE_DIFF(
    IF(buy_fill_ts <= sell_fill_ts, DATE(sell_fill_ts, 'America/New_York'), DATE(buy_fill_ts, 'America/New_York')),
    IF(buy_fill_ts <= sell_fill_ts, DATE(buy_fill_ts, 'America/New_York'), DATE(sell_fill_ts, 'America/New_York')),
    DAY) AS holding_period_days,
  IF(
    IF(buy_fill_ts <= sell_fill_ts, DATE(sell_fill_ts, 'America/New_York'), DATE(buy_fill_ts, 'America/New_York'))
      > DATE_ADD(IF(buy_fill_ts <= sell_fill_ts, DATE(buy_fill_ts, 'America/New_York'), DATE(sell_fill_ts, 'America/New_York')), INTERVAL 1 YEAR),
    'LONG_TERM', 'SHORT_TERM') AS term,
  IF(buy_fill_ts <= sell_fill_ts, 'LONG', 'SHORT') AS position_side
FROM matched
UNION ALL
-- OPEN LONG lot remainders (no sell yet, or only partially sold) — unchanged from the original,
-- plus position_side='LONG'.
SELECT
  CONCAT(ticker, ':', buy_trade_id, ':OPEN')                      AS lot_id,
  ticker,
  buy_trade_id, buy_strategy, DATE(buy_fill_ts, 'America/New_York') AS entry_date,
  CAST(NULL AS STRING) AS sell_trade_id, CAST(NULL AS STRING) AS sell_strategy, CAST(NULL AS DATE) AS exit_date,
  'OPEN' AS status,
  open_shares AS shares,
  buy_price AS entry_price, CAST(NULL AS NUMERIC) AS exit_price,
  ROUND(open_shares * multiplier * buy_price
        + open_shares * COALESCE(buy_commission_per_share, 0), 4) AS cost_basis,
  CAST(NULL AS NUMERIC) AS proceeds,
  CAST(NULL AS NUMERIC) AS realized_gain_loss,
  DATE_DIFF(CURRENT_DATE('America/New_York'), DATE(buy_fill_ts, 'America/New_York'), DAY) AS holding_period_days,
  IF(CURRENT_DATE('America/New_York') > DATE_ADD(DATE(buy_fill_ts, 'America/New_York'), INTERVAL 1 YEAR),
     'LONG_TERM', 'SHORT_TERM') AS term,
  'LONG' AS position_side
FROM open_remainder
UNION ALL
-- NEW: OPEN SHORT lot remainders (no cover yet, or only partially covered) — an unconsumed SELL is
-- an open short position. entry_date is the short-open date (the sell); cost_basis is the
-- short-sale CREDIT received at open (a LIABILITY, not an asset) — consumers must check
-- position_side='SHORT' to interpret this column correctly, unlike an OPEN LONG's cost_basis (a
-- cash outlay / asset).
SELECT
  CONCAT(ticker, ':OPEN:', sell_trade_id)                         AS lot_id,
  ticker,
  CAST(NULL AS STRING) AS buy_trade_id, CAST(NULL AS STRING) AS buy_strategy,
  DATE(sell_fill_ts, 'America/New_York') AS entry_date,
  sell_trade_id, sell_strategy, CAST(NULL AS DATE) AS exit_date,
  'OPEN' AS status,
  open_shares AS shares,
  sell_price AS entry_price, CAST(NULL AS NUMERIC) AS exit_price,
  ROUND(open_shares * multiplier * sell_price
        - open_shares * COALESCE(sell_commission_per_share, 0), 4) AS cost_basis,
  CAST(NULL AS NUMERIC) AS proceeds,
  CAST(NULL AS NUMERIC) AS realized_gain_loss,
  DATE_DIFF(CURRENT_DATE('America/New_York'), DATE(sell_fill_ts, 'America/New_York'), DAY) AS holding_period_days,
  IF(CURRENT_DATE('America/New_York') > DATE_ADD(DATE(sell_fill_ts, 'America/New_York'), INTERVAL 1 YEAR),
     'LONG_TERM', 'SHORT_TERM') AS term,
  'SHORT' AS position_side
FROM open_remainder_short;

-- ============================================================================
-- state.wash_sale_exposure — REDEFINED: the loss-realizing population is now BOTH losing SELLs
-- (closes a LONG) and losing BUYs/covers (closes a SHORT), each checked against its OWN symmetric
-- replacement-purchase pool. Column names generalized (close_trade_id/close_side rather than
-- sell_trade_id) — verified via repo-wide grep that nothing consumes this view yet, so there is no
-- backward-compatibility constraint from the rename.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.wash_sale_exposure` AS
WITH losing_sells AS (
  -- Loss-realizing SELLs (closes a LONG position) — same population as the original view.
  SELECT trade_id AS close_trade_id, strategy AS close_strategy, ticker,
         DATE(fill_ts, 'America/New_York') AS close_date,
         shares AS close_shares, realized_pnl, 'SELL' AS close_side
  FROM `stock-trading-498512.state.trade_fills_curated`
  WHERE side = 'SELL' AND ticker != 'SGOV'
    AND realized_pnl IS NOT NULL AND realized_pnl < 0
    AND shares IS NOT NULL AND shares > 0 AND fill_ts IS NOT NULL
),
losing_covers AS (
  -- NEW: loss-realizing BUYs (closes/covers a SHORT position). IBKR attaches realized_pnl to
  -- whichever execution actually closes the position — for a short that is the BUY (cover), not
  -- the SELL (open) — so without this population a losing short-cover was entirely invisible.
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
  SELECT trade_id AS buy_trade_id, strategy AS buy_strategy, ticker,
         DATE(fill_ts, 'America/New_York') AS buy_date, shares AS buy_shares
  FROM `stock-trading-498512.state.trade_fills_curated`
  WHERE side = 'BUY' AND ticker != 'SGOV'
    AND shares IS NOT NULL AND shares > 0 AND fill_ts IS NOT NULL
),
candidate_sells AS (
  -- NEW: symmetric replacement-purchase pool for a losing SHORT COVER — a re-opened SHORT (a new
  -- SELL) within the window.
  SELECT trade_id AS sell_trade_id, strategy AS sell_strategy, ticker,
         DATE(fill_ts, 'America/New_York') AS sell_date, shares AS sell_shares
  FROM `stock-trading-498512.state.trade_fills_curated`
  WHERE side = 'SELL' AND ticker != 'SGOV'
    AND shares IS NOT NULL AND shares > 0 AND fill_ts IS NOT NULL
),
-- The buy lot(s) that ARE a given losing SELL's own FIFO cost basis — excluded as "replacement"
-- candidates (closing a position via its own original entry is not a "replacement purchase").
own_basis_for_sell AS (
  SELECT sell_trade_id, ARRAY_AGG(DISTINCT buy_trade_id) AS own_buy_trade_ids
  FROM `stock-trading-498512.analytics.tax_lots`
  WHERE sell_trade_id IS NOT NULL AND buy_trade_id IS NOT NULL
  GROUP BY sell_trade_id
),
-- NEW, symmetric: the sell lot(s) that a given losing BUY (cover) itself closed — excluded as
-- "replacement" candidates for that cover.
own_basis_for_buy AS (
  SELECT buy_trade_id, ARRAY_AGG(DISTINCT sell_trade_id) AS own_sell_trade_ids
  FROM `stock-trading-498512.analytics.tax_lots`
  WHERE buy_trade_id IS NOT NULL AND sell_trade_id IS NOT NULL
  GROUP BY buy_trade_id
),
qualifying_replacements AS (
  -- Replacement BUYs for a losing SELL (closes a LONG) — same logic as the original view.
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
  -- NEW: replacement SELLs (re-shorts) for a losing BUY/cover (closes a SHORT).
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
-- Base population = EVERY loss-realizing close (SELL closing a long, OR BUY closing a short;
-- SGOV-excluded, non-NULL data). LEFT JOIN to the replacement aggregation so a close with no
-- replacement trade in the window defaults cleanly to has_exposure = FALSE / estimated_disallowed_
-- loss = 0 — never NULL, never a stray "exposed" flag on missing data (fail-closed, per the
-- original file header note).
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

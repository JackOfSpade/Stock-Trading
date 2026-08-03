-- Parallel-run dbt port of bigquery/102_pyramid_aware_lifecycle.sql:analytics.position_lifecycle
-- (Tier 1 -- FIFO LOTS) -- canonical source is that file until owner cutover.
--
-- REBUILT 2026-07-21 (pyramid-aware accounting rebuild, owner directive "allow adds for A/B/D"):
-- supersedes the ROW_NUMBER() leg_seq pairing this file used to carry (bigquery/03_twr_engine.sql's
-- original) -- that pairing leaves a pyramid add-leg perpetually-open (no matching Nth SELL) and
-- mis-pairs a re-traded ticker's later legs. Now: FIFO cumulative-interval-overlap lots per
-- (strategy,ticker), same technique as analytics.tax_lots (bigquery/41_tax_lots.sql /
-- bigquery/50_short_sale_tax_lots.sql), just partitioned by (strategy,ticker) to preserve the
-- per-strategy wall. EXACT SAME 12 output columns (names + types) as before -- every downstream
-- consumer keeps working; 2026-08-02 appends is_dust for the TWR exclusion.
-- Long-only-correct; short-sale mislabeling is DEFERRED (see bigquery/102's header SCOPE note).
--
-- SGOV EXCLUSION (2026-07-01, RUNBOOK §29): SGOV is the shared account-level cash-sweep / benchmark
-- (parking_events, NULL strategy; reconciled via state.sgov_position / §13), NOT a per-strategy deployed
-- position. Filter both legs so a stray SGOV fill in trade_fills cannot fabricate a phantom open lot
-- (position_reconciliation B4 false-drift) or contaminate strategy_daily_returns. Preserved verbatim.
-- entry_date/exit_date use DATE(fill_ts, 'America/New_York') — the EXCHANGE TRADING DATE the
-- daily-marks join and every downstream DATE_DIFF/window keys on.
-- Dust source BUYs and their exact liquidation SELLs have a separate FIFO lane per dust_id. This
-- prevents an ordinary SELL after a legitimate re-entry from consuming the older dust BUY first.

WITH buys AS (
  SELECT f.trade_id, f.strategy, f.ticker, f.contract_id, f.fill_ts, f.price, f.shares, f.commission,
    COALESCE(dcf.is_dust, FALSE) AS is_dust,
    dcf.dust_id,
    COALESCE(SUM(shares) OVER (PARTITION BY strategy, ticker, COALESCE(dcf.is_dust, FALSE),
      IF(COALESCE(dcf.is_dust, FALSE), dcf.dust_id, '') ORDER BY fill_ts, trade_id
      ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS cum_start
  FROM {{ ref('trade_fills_curated') }} f
  LEFT JOIN {{ ref('dust_classified_fills') }} dcf USING (trade_id)
  WHERE side = 'BUY' AND ticker != 'SGOV' AND shares IS NOT NULL AND shares > 0
),
sells AS (
  SELECT f.trade_id, f.strategy, f.ticker, f.fill_ts, f.price, f.shares, f.commission, f.realized_pnl,
    COALESCE(dcf.is_dust, FALSE) AS is_dust, dcf.dust_id,
    COALESCE(SUM(f.shares) OVER (PARTITION BY f.strategy, f.ticker, COALESCE(dcf.is_dust, FALSE),
      IF(COALESCE(dcf.is_dust, FALSE), dcf.dust_id, '') ORDER BY f.fill_ts, f.trade_id
      ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS cum_start
  FROM {{ ref('trade_fills_curated') }} f
  LEFT JOIN {{ ref('dust_classified_fills') }} dcf USING (trade_id)
  WHERE f.side = 'SELL' AND f.ticker != 'SGOV' AND f.shares IS NOT NULL AND f.shares > 0
),
-- Every (buy, sell) pair on the same (strategy,ticker) whose cumulative-share intervals overlap --
-- the overlap width is the FIFO-matched share count between that specific buy lot and that specific
-- sell fill, correct regardless of how buys/sells interleave in time.
matched AS (
  SELECT b.strategy, b.ticker, b.contract_id,
    b.trade_id AS buy_trade_id, b.fill_ts AS buy_fill_ts, b.price AS buy_price,
    b.shares AS buy_shares, b.commission AS buy_commission, b.is_dust,
    s.trade_id AS sell_trade_id, s.fill_ts AS sell_fill_ts, s.price AS sell_price,
    s.shares AS sell_shares, s.commission AS sell_commission, s.realized_pnl AS sell_realized_pnl,
    LEAST(b.cum_start + b.shares, s.cum_start + s.shares) - GREATEST(b.cum_start, s.cum_start) AS shares_matched
  FROM buys b
  JOIN sells s ON s.strategy = b.strategy AND s.ticker = b.ticker
    AND s.is_dust = b.is_dust
    AND (NOT b.is_dust OR s.dust_id = b.dust_id)
  WHERE LEAST(b.cum_start + b.shares, s.cum_start + s.shares) > GREATEST(b.cum_start, s.cum_start)
),
-- Portion of each BUY not yet consumed by any SELL to date = still-open shares of that lot.
buy_matched_totals AS (
  SELECT strategy, ticker, buy_trade_id, SUM(shares_matched) AS total_matched
  FROM matched
  GROUP BY 1, 2, 3
),
open_tail AS (
  -- NOTE: aliased explicitly (buy_trade_id/buy_fill_ts/buy_price/buy_shares/buy_commission), NOT a
  -- bare `b.*` -- the OPEN-lot SELECT below reads those buy_-prefixed names (same convention as the
  -- `matched` CTE above); a bare `b.*` would carry buys' raw column names (trade_id/fill_ts/price/
  -- shares/commission) instead and the OPEN-lot SELECT would fail with "Unrecognized name".
  SELECT
    b.strategy, b.ticker, b.contract_id,
    b.trade_id AS buy_trade_id, b.fill_ts AS buy_fill_ts, b.price AS buy_price,
    b.shares AS buy_shares, b.commission AS buy_commission, b.is_dust,
    b.shares - COALESCE(t.total_matched, 0) AS open_shares
  FROM buys b
  LEFT JOIN buy_matched_totals t
    ON t.strategy = b.strategy AND t.ticker = b.ticker AND t.buy_trade_id = b.trade_id
  WHERE b.shares - COALESCE(t.total_matched, 0) > 0.0000001   -- guard FP noise on fractional-share fills
)
-- CLOSED lot pieces (a buy interval matched to a sell interval). NOTE: entry_commission/
-- exit_commission/realized_pnl are NOT wrapped in ROUND(...,4) -- this system trades fractional
-- shares down to ~1/100 of a share, so commission/realized_pnl are prorated to 6-8 decimal places;
-- rounding to 4 decimals is LOSSY on real data and breaks the single-entry byte-identical regression
-- (see bigquery/102_pyramid_aware_lifecycle.sql's header for the live verification). NUMERIC
-- arithmetic already has a fixed max scale of 9 decimal digits, so no explicit rounding is needed.
SELECT
  CONCAT(strategy, ':', ticker, ':', buy_trade_id, ':', sell_trade_id) AS position_key,
  strategy, ticker, contract_id,
  shares_matched AS shares,
  DATE(buy_fill_ts, 'America/New_York') AS entry_date,
  buy_price AS entry_price,
  shares_matched * SAFE_DIVIDE(buy_commission, NULLIF(buy_shares, 0)) AS entry_commission,
  DATE(sell_fill_ts, 'America/New_York') AS exit_date,
  sell_price AS exit_price,
  shares_matched * SAFE_DIVIDE(sell_commission, NULLIF(sell_shares, 0)) AS exit_commission,
  sell_realized_pnl * SAFE_DIVIDE(shares_matched, NULLIF(sell_shares, 0)) AS realized_pnl,
  is_dust
FROM matched
UNION ALL
-- OPEN lot remainder (a BUY, or the un-sold tail of one, with no sell yet).
SELECT
  CONCAT(strategy, ':', ticker, ':', buy_trade_id, ':OPEN') AS position_key,
  strategy, ticker, contract_id,
  open_shares AS shares,
  DATE(buy_fill_ts, 'America/New_York') AS entry_date,
  buy_price AS entry_price,
  open_shares * SAFE_DIVIDE(buy_commission, NULLIF(buy_shares, 0)) AS entry_commission,
  CAST(NULL AS DATE) AS exit_date,
  CAST(NULL AS NUMERIC) AS exit_price,
  CAST(NULL AS NUMERIC) AS exit_commission,
  CAST(NULL AS NUMERIC) AS realized_pnl,
  is_dust
FROM open_tail

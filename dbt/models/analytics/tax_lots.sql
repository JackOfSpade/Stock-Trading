-- Parallel-run dbt port of bigquery/50_short_sale_tax_lots.sql:analytics.tax_lots — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH buys AS (
  SELECT trade_id, strategy, ticker, fill_ts, price, shares, commission,
         IF(`stock-trading-498512.analytics.fn_is_occ_option_symbol`(ticker), 100, 1) AS multiplier,
         SAFE_DIVIDE(commission, NULLIF(shares, 0)) AS commission_per_share,
         COALESCE(SUM(shares) OVER (
           PARTITION BY ticker ORDER BY fill_ts, trade_id
           ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS cum_start
  FROM {{ ref('trade_fills_curated') }}
  WHERE side = 'BUY' AND ticker != 'SGOV' AND shares IS NOT NULL AND shares > 0
),
sells AS (
  SELECT trade_id, strategy, ticker, fill_ts, price, shares, commission, realized_pnl,
         IF(`stock-trading-498512.analytics.fn_is_occ_option_symbol`(ticker), 100, 1) AS multiplier,
         SAFE_DIVIDE(commission, NULLIF(shares, 0)) AS commission_per_share,
         COALESCE(SUM(shares) OVER (
           PARTITION BY ticker ORDER BY fill_ts, trade_id
           ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS cum_start
  FROM {{ ref('trade_fills_curated') }}
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
FROM open_remainder_short

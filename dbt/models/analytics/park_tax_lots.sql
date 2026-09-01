-- Parallel-run dbt port of bigquery/178_park_wash_sale_exposure.sql:analytics.park_tax_lots — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH buys AS (
  SELECT event_id AS trade_id, ticker, event_ts AS fill_ts, price, shares, commission,
         SAFE_DIVIDE(commission, NULLIF(shares, 0)) AS commission_per_share,
         -- cum_start = total park BUY/DIVIDEND_REINVEST shares in this ticker strictly before this
         -- event (FIFO entry order) — identical technique to analytics.tax_lots' `buys` CTE.
         COALESCE(SUM(shares) OVER (
           PARTITION BY ticker ORDER BY event_ts, event_id
           ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS cum_start
  FROM {{ source('events', 'parking_events') }}
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
  FROM {{ source('events', 'parking_events') }}
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
FROM open_remainder

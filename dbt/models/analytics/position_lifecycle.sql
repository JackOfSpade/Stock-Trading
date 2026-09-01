-- Parallel-run dbt port of bigquery/125_dust_excluded_from_twr.sql:analytics.position_lifecycle — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH buys AS (
  SELECT f.trade_id, f.strategy, f.ticker, f.contract_id, f.fill_ts, f.price, f.shares, f.commission,
    COALESCE(dcf.is_dust, FALSE) AS is_dust,
    dcf.dust_id,
    COALESCE(SUM(f.shares) OVER (PARTITION BY f.strategy, f.ticker, COALESCE(dcf.is_dust, FALSE),
      IF(COALESCE(dcf.is_dust, FALSE), dcf.dust_id, '') ORDER BY f.fill_ts, f.trade_id
      ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS cum_start
  FROM {{ ref('trade_fills_curated') }} f
  LEFT JOIN {{ ref('dust_classified_fills') }} dcf USING (trade_id)
  WHERE f.side = 'BUY' AND f.ticker != 'SGOV' AND f.shares IS NOT NULL AND f.shares > 0
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
matched AS (
  SELECT b.strategy, b.ticker, b.contract_id,
    b.trade_id AS buy_trade_id, b.fill_ts AS buy_fill_ts, b.price AS buy_price,
    b.shares AS buy_shares, b.commission AS buy_commission, b.is_dust,
    s.trade_id AS sell_trade_id, s.fill_ts AS sell_fill_ts, s.price AS sell_price,
    s.shares AS sell_shares, s.commission AS sell_commission, s.realized_pnl AS sell_realized_pnl,
    LEAST(b.cum_start + b.shares, s.cum_start + s.shares)
      - GREATEST(b.cum_start, s.cum_start) AS shares_matched
  FROM buys b
  JOIN sells s ON s.strategy = b.strategy AND s.ticker = b.ticker
    AND s.is_dust = b.is_dust
    AND (NOT b.is_dust OR s.dust_id = b.dust_id)
  WHERE LEAST(b.cum_start + b.shares, s.cum_start + s.shares)
        > GREATEST(b.cum_start, s.cum_start)
),
buy_matched_totals AS (
  SELECT strategy, ticker, buy_trade_id, SUM(shares_matched) AS total_matched
  FROM matched
  GROUP BY 1, 2, 3
),
open_tail AS (
  SELECT b.strategy, b.ticker, b.contract_id,
    b.trade_id AS buy_trade_id, b.fill_ts AS buy_fill_ts, b.price AS buy_price,
    b.shares AS buy_shares, b.commission AS buy_commission, b.is_dust,
    b.shares - COALESCE(t.total_matched, 0) AS open_shares
  FROM buys b
  LEFT JOIN buy_matched_totals t
    ON t.strategy = b.strategy AND t.ticker = b.ticker AND t.buy_trade_id = b.trade_id
  WHERE b.shares - COALESCE(t.total_matched, 0) > 0.0000001
)
SELECT
  CONCAT(strategy, ':', ticker, ':', buy_trade_id, ':', sell_trade_id) AS position_key,
  strategy, ticker, contract_id, shares_matched AS shares,
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
SELECT
  CONCAT(strategy, ':', ticker, ':', buy_trade_id, ':OPEN') AS position_key,
  strategy, ticker, contract_id, open_shares AS shares,
  DATE(buy_fill_ts, 'America/New_York') AS entry_date,
  buy_price AS entry_price,
  open_shares * SAFE_DIVIDE(buy_commission, NULLIF(buy_shares, 0)) AS entry_commission,
  CAST(NULL AS DATE) AS exit_date,
  CAST(NULL AS NUMERIC) AS exit_price,
  CAST(NULL AS NUMERIC) AS exit_commission,
  CAST(NULL AS NUMERIC) AS realized_pnl,
  is_dust
FROM open_tail

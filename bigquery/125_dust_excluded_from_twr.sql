-- Audited DRIP-dust classification carried into Tier-1 lots and excluded from deployed TWR.
-- Project: stock-trading-498512. Apply AFTER 123_drip_dust_campaign_exclusion.sql and
-- 124_dust_excluded_from_closed_trades.sql.
--
-- SUPERSEDES analytics.position_lifecycle from bigquery/102 and analytics.strategy_daily_returns
-- from bigquery/82. The lifecycle remains complete for reconciliation and audit; an appended is_dust
-- column identifies source BUYs and their exact liquidation SELLs. FIFO intervals are partitioned by
-- real-vs-dust and dust_id, so an ordinary SELL can never consume an older dust BUY (or vice versa).
-- The TWR view filters dust lots, preventing a sub-dollar orphan from becoming 100% of a strategy's
-- return denominator or advancing deployed_days.

-- ============================================================================
-- analytics.position_lifecycle -- FIFO lots, with audited fill classification appended last.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.position_lifecycle` AS
WITH buys AS (
  SELECT f.trade_id, f.strategy, f.ticker, f.contract_id, f.fill_ts, f.price, f.shares, f.commission,
    COALESCE(dcf.is_dust, FALSE) AS is_dust,
    dcf.dust_id,
    COALESCE(SUM(f.shares) OVER (PARTITION BY f.strategy, f.ticker, COALESCE(dcf.is_dust, FALSE),
      IF(COALESCE(dcf.is_dust, FALSE), dcf.dust_id, '') ORDER BY f.fill_ts, f.trade_id
      ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS cum_start
  FROM `stock-trading-498512.state.trade_fills_curated` f
  LEFT JOIN `stock-trading-498512.analytics.dust_classified_fills` dcf USING (trade_id)
  WHERE f.side = 'BUY' AND f.ticker != 'SGOV' AND f.shares IS NOT NULL AND f.shares > 0
),
sells AS (
  SELECT f.trade_id, f.strategy, f.ticker, f.fill_ts, f.price, f.shares, f.commission, f.realized_pnl,
    COALESCE(dcf.is_dust, FALSE) AS is_dust, dcf.dust_id,
    COALESCE(SUM(f.shares) OVER (PARTITION BY f.strategy, f.ticker, COALESCE(dcf.is_dust, FALSE),
      IF(COALESCE(dcf.is_dust, FALSE), dcf.dust_id, '') ORDER BY f.fill_ts, f.trade_id
      ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS cum_start
  FROM `stock-trading-498512.state.trade_fills_curated` f
  LEFT JOIN `stock-trading-498512.analytics.dust_classified_fills` dcf USING (trade_id)
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
FROM open_tail;


-- ============================================================================
-- analytics.strategy_daily_returns -- latest split/option-aware definition, excluding audited dust.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.strategy_daily_returns` AS
WITH equity_marked AS (
  SELECT m.mark_date, l.strategy, l.position_key, l.shares, l.entry_price, l.exit_price, l.exit_date,
         CAST(1 AS INT64) AS multiplier, m.close, COALESCE(m.dividend, 0) AS dividend,
         COALESCE(NULLIF(m.split_ratio, 0), 1) AS day_split
  FROM `stock-trading-498512.analytics.position_lifecycle` l
  JOIN `stock-trading-498512.state.daily_marks_curated` m
    ON m.ticker = l.ticker
   AND m.mark_date >= l.entry_date
   AND (l.exit_date IS NULL OR m.mark_date <= l.exit_date)
  WHERE l.strategy IS NOT NULL
    AND NOT COALESCE(l.is_dust, FALSE)
    AND NOT `stock-trading-498512.analytics.fn_is_occ_option_symbol`(l.ticker)
),
equity_runprod AS (
  SELECT *, EXP(SUM(LN(day_split)) OVER (
    PARTITION BY position_key ORDER BY mark_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)) AS rp
  FROM equity_marked
),
equity_held AS (
  SELECT mark_date, strategy, position_key, shares, entry_price, multiplier,
    shares * eff * IF(mark_date = exit_date, exit_price, close) AS mv,
    shares * eff * dividend AS div_cash
  FROM (
    SELECT *, SAFE_DIVIDE(rp,
      FIRST_VALUE(rp) OVER (PARTITION BY position_key ORDER BY mark_date)) AS eff
    FROM equity_runprod
  )
),
option_held AS (
  SELECT om.mark_date, l.strategy, l.position_key, l.shares, l.entry_price,
         om.multiplier,
         l.shares * om.multiplier * IF(om.mark_date = l.exit_date, l.exit_price, om.premium_close) AS mv,
         CAST(0 AS NUMERIC) AS div_cash
  FROM `stock-trading-498512.analytics.position_lifecycle` l
  JOIN `stock-trading-498512.state.option_marks_curated` om
    ON om.occ_symbol = l.ticker
   AND om.mark_date >= l.entry_date
   AND (l.exit_date IS NULL OR om.mark_date <= l.exit_date)
  WHERE l.strategy IS NOT NULL
    AND NOT COALESCE(l.is_dust, FALSE)
    AND `stock-trading-498512.analytics.fn_is_occ_option_symbol`(l.ticker)
),
held AS (
  SELECT * FROM equity_held
  UNION ALL
  SELECT * FROM option_held
),
lagged AS (
  SELECT mark_date, strategy, position_key, mv, div_cash,
         COALESCE(LAG(mv) OVER (PARTITION BY position_key ORDER BY mark_date),
                  shares * multiplier * entry_price) AS prev_mv
  FROM held
)
SELECT mark_date AS as_of_date, strategy,
       SAFE_DIVIDE(SUM(mv + div_cash) - SUM(prev_mv), SUM(prev_mv)) AS r_deployed,
       SUM(prev_mv) AS deployed_capital,
       COUNT(*) AS n_positions
FROM lagged
GROUP BY mark_date, strategy;

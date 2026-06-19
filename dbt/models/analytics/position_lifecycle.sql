-- Parallel-run dbt port of bigquery/03_twr_engine.sql:analytics.position_lifecycle — canonical source is that file until owner cutover.
-- A position = a ticker's BUY (entry) and optional SELL (exit), carrying entry/exit prices +
-- commissions so the TWR baselines at TOTAL COST and closes at NET PROCEEDS. Reads the CURATED
-- dedup view (trade_fills_curated): a re-ingested fill can't shift leg_seq pairing or create
-- phantom positions. Entries<->exits pair by (strategy, ticker, leg_seq) — NOT ticker alone —
-- so a ticker traded by two strategies (or re-traded) does not fan out.

WITH entries AS (
  SELECT strategy, ticker, contract_id, DATE(fill_ts) AS entry_date,
         price AS entry_price, shares, commission AS entry_commission,
         -- sequence the BUYs within a (strategy,ticker) so the Nth buy pairs to the Nth sell
         ROW_NUMBER() OVER (PARTITION BY strategy, ticker ORDER BY fill_ts, trade_id) AS leg_seq
  FROM {{ ref('trade_fills_curated') }} WHERE side='BUY'
),
exits AS (
  SELECT strategy, ticker, DATE(fill_ts) AS exit_date, price AS exit_price,
         realized_pnl, commission AS exit_commission,
         ROW_NUMBER() OVER (PARTITION BY strategy, ticker ORDER BY fill_ts, trade_id) AS leg_seq
  FROM {{ ref('trade_fills_curated') }} WHERE side='SELL'
)
-- position_key carries leg_seq so it is unique per round-trip (strategy_daily_returns' LAG
-- window partitions on it; a shared key would merge two positions).
SELECT CONCAT(e.strategy,':',e.ticker,':',CAST(e.entry_date AS STRING),':',CAST(e.leg_seq AS STRING)) AS position_key,
       e.strategy, e.ticker, e.contract_id, e.shares,
       e.entry_date, e.entry_price, e.entry_commission,
       x.exit_date, x.exit_price, x.exit_commission, x.realized_pnl
FROM entries e
LEFT JOIN exits x
  ON e.strategy = x.strategy AND e.ticker = x.ticker AND e.leg_seq = x.leg_seq

-- Singular test (passes when ZERO rows): proves the Tier-1 FIFO-interval-overlap + Tier-2
-- 0-crossing SQL LOGIC ITSELF is correct on a synthetic pyramid + a synthetic partial exit, using
-- literal inline fills (no live table -- dbt ref()/source() calls are not used, so this runs even
-- before bigquery/102_pyramid_aware_lifecycle.sql is ever applied live, and stays independent of
-- however few real pyramids exist in production on a given day).
--
-- Companion to assert_campaign_lifecycle_reconciliation.sql: that test guards the DEPLOYED views
-- (real data, whatever pyramids happen to exist today); this one guards the ALGORITHM on a fixed,
-- hand-verified fixture that deliberately exercises the exact shape the old engine broke on, so a
-- regression is caught immediately on the next `dbt test`, not whenever a real pyramid next closes.
--
-- CAUTION -- DUPLICATED LOGIC: the `buys`/`sells`/`matched`/`open_tail`/`lifecycle` and
-- `fills`/`running`/`seqd`/`tagged`/`campaigns` CTEs below are a byte-for-byte copy of
-- bigquery/102_pyramid_aware_lifecycle.sql's analytics.position_lifecycle / analytics.
-- position_campaigns bodies (FROM swapped to `synthetic_fills`, DATE()/timezone kept identical). If
-- that file's SQL is ever refactored WITHOUT updating this copy, this test silently stops proving
-- anything about the live logic (it would still pass, just against stale logic) -- keep the two in
-- sync (same convention bigquery/40's own header note already asks of bigquery/03/40/102). This is
-- why assert_campaign_lifecycle_reconciliation.sql exists as an independent, non-duplicating guard
-- on the deployed views regardless of whether this file is kept in sync.
--
-- FIXTURE (synthetic_fills, all strategy 'B', fill_ts mid-day UTC so the America/New_York DATE()
-- conversion never crosses a calendar boundary):
--   Ticker PYR -- a pyramid fully closed by one combined SELL:
--     t1  BUY  10 sh @ $100  2026-01-01  (the add-then-perpetually-open bug's exact shape)
--     t2  BUY   5 sh @ $110  2026-01-05
--     t3  SELL 15 sh @ $120  2026-01-10, realized_pnl=$250 (flattens 15->0)
--   Ticker PEX -- a single entry, partial exit (still open):
--     t4  BUY  10 sh @  $50  2026-02-01
--     t5  SELL  6 sh @  $55  2026-02-10, realized_pnl=$30 (10->4, NOT flat)
--
-- EXPECTED (hand-derived from the FIFO-overlap / 0-crossing algorithm and CONFIRMED by executing
-- this exact query, read-only, against live BigQuery on 2026-07-21 -- see the file-level report for
-- the full derivation):
--   Tier 1 (4 lots, not 5 -- NO row is dropped and NO row is left open when it shouldn't be):
--     B:PYR:t1:t3  shares=10  entry=2026-01-01 exit=2026-01-10 (NOT NULL)  realized_pnl~=166.67
--     B:PYR:t2:t3  shares=5   entry=2026-01-05 exit=2026-01-10 (NOT NULL) realized_pnl~=83.33
--       -- ^ this is the add-leg that the OLD ROW_NUMBER() leg_seq pairing left exit_date=NULL
--       -- forever (verified live: the old bigquery/03_twr_engine.sql logic, run against this same
--       -- fixture, produces position_key 'B:PYR:2026-01-05:2' with exit_date NULL) -- the single
--       -- assertion this whole file exists to pin.
--     B:PEX:t4:t5    shares=6  entry=2026-02-01 exit=2026-02-10 (NOT NULL) realized_pnl=30
--     B:PEX:t4:OPEN  shares=4  entry=2026-02-01 exit=NULL (correctly still open -- negative control:
--       the algorithm must NOT mark a genuinely-open remainder as closed either)
--   Tier 2 (2 campaigns):
--     B:PYR:1  entry=2026-01-01 exit=2026-01-10 realized_pnl=250  bought=15 sold=15 open_shares=0
--     B:PEX:1  entry=2026-02-01 exit=NULL       realized_pnl=30   bought=10 sold=6  open_shares=4

WITH synthetic_fills AS (
  SELECT
    't1' AS trade_id, 'B' AS strategy, 'PYR' AS ticker, 'PYR' AS contract_id,
    TIMESTAMP '2026-01-01 20:00:00 UTC' AS fill_ts, 'BUY' AS side,
    CAST(100.00 AS NUMERIC) AS price, CAST(10 AS NUMERIC) AS shares,
    CAST(1.00 AS NUMERIC) AS commission, CAST(NULL AS NUMERIC) AS realized_pnl
  UNION ALL SELECT 't2','B','PYR','PYR', TIMESTAMP '2026-01-05 20:00:00 UTC','BUY',
    CAST(110.00 AS NUMERIC), CAST(5 AS NUMERIC), CAST(1.00 AS NUMERIC), CAST(NULL AS NUMERIC)
  UNION ALL SELECT 't3','B','PYR','PYR', TIMESTAMP '2026-01-10 20:00:00 UTC','SELL',
    CAST(120.00 AS NUMERIC), CAST(15 AS NUMERIC), CAST(2.00 AS NUMERIC), CAST(250.00 AS NUMERIC)
  UNION ALL SELECT 't4','B','PEX','PEX', TIMESTAMP '2026-02-01 20:00:00 UTC','BUY',
    CAST(50.00 AS NUMERIC), CAST(10 AS NUMERIC), CAST(1.00 AS NUMERIC), CAST(NULL AS NUMERIC)
  UNION ALL SELECT 't5','B','PEX','PEX', TIMESTAMP '2026-02-10 20:00:00 UTC','SELL',
    CAST(55.00 AS NUMERIC), CAST(6 AS NUMERIC), CAST(1.00 AS NUMERIC), CAST(30.00 AS NUMERIC)
),
-- ===== Tier 1 -- byte-for-byte copy of bigquery/102_pyramid_aware_lifecycle.sql's
-- analytics.position_lifecycle body, FROM swapped to synthetic_fills. =====
buys AS (
  SELECT trade_id, strategy, ticker, contract_id, fill_ts, price, shares, commission,
    COALESCE(SUM(shares) OVER (PARTITION BY strategy, ticker ORDER BY fill_ts, trade_id
      ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS cum_start
  FROM synthetic_fills
  WHERE side = 'BUY' AND ticker != 'SGOV' AND shares IS NOT NULL AND shares > 0
),
sells AS (
  SELECT trade_id, strategy, ticker, fill_ts, price, shares, commission, realized_pnl,
    COALESCE(SUM(shares) OVER (PARTITION BY strategy, ticker ORDER BY fill_ts, trade_id
      ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS cum_start
  FROM synthetic_fills
  WHERE side = 'SELL' AND ticker != 'SGOV' AND shares IS NOT NULL AND shares > 0
),
matched AS (
  SELECT b.strategy, b.ticker, b.contract_id,
    b.trade_id AS buy_trade_id, b.fill_ts AS buy_fill_ts, b.price AS buy_price,
    b.shares AS buy_shares, b.commission AS buy_commission,
    s.trade_id AS sell_trade_id, s.fill_ts AS sell_fill_ts, s.price AS sell_price,
    s.shares AS sell_shares, s.commission AS sell_commission, s.realized_pnl AS sell_realized_pnl,
    LEAST(b.cum_start + b.shares, s.cum_start + s.shares) - GREATEST(b.cum_start, s.cum_start) AS shares_matched
  FROM buys b
  JOIN sells s ON s.strategy = b.strategy AND s.ticker = b.ticker
  WHERE LEAST(b.cum_start + b.shares, s.cum_start + s.shares) > GREATEST(b.cum_start, s.cum_start)
),
buy_matched_totals AS (
  SELECT strategy, ticker, buy_trade_id, SUM(shares_matched) AS total_matched
  FROM matched
  GROUP BY 1, 2, 3
),
open_tail AS (
  SELECT
    b.strategy, b.ticker, b.contract_id,
    b.trade_id AS buy_trade_id, b.fill_ts AS buy_fill_ts, b.price AS buy_price,
    b.shares AS buy_shares, b.commission AS buy_commission,
    b.shares - COALESCE(t.total_matched, 0) AS open_shares
  FROM buys b
  LEFT JOIN buy_matched_totals t
    ON t.strategy = b.strategy AND t.ticker = b.ticker AND t.buy_trade_id = b.trade_id
  WHERE b.shares - COALESCE(t.total_matched, 0) > 0.0000001
),
lifecycle AS (
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
    sell_realized_pnl * SAFE_DIVIDE(shares_matched, NULLIF(sell_shares, 0)) AS realized_pnl
  FROM matched
  UNION ALL
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
    CAST(NULL AS NUMERIC) AS realized_pnl
  FROM open_tail
),
-- ===== Tier 2 -- byte-for-byte copy of analytics.position_campaigns' body. =====
fills AS (
  SELECT trade_id, strategy, ticker, contract_id,
    DATE(fill_ts, 'America/New_York') AS fill_date, fill_ts,
    side, price, shares, commission, realized_pnl,
    IF(side = 'BUY', shares, -shares) AS signed_shares
  FROM synthetic_fills
  WHERE ticker != 'SGOV' AND shares IS NOT NULL AND shares > 0
),
running AS (
  SELECT *,
    SUM(signed_shares) OVER w AS running_shares,
    COALESCE(SUM(signed_shares) OVER (PARTITION BY strategy, ticker ORDER BY fill_ts, trade_id
      ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS prev_running_shares
  FROM fills
  WINDOW w AS (PARTITION BY strategy, ticker ORDER BY fill_ts, trade_id
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
),
seqd AS (
  SELECT *,
    COUNTIF(prev_running_shares = 0 AND running_shares != 0) OVER (
      PARTITION BY strategy, ticker ORDER BY fill_ts, trade_id
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS campaign_seq
  FROM running
),
tagged AS (
  SELECT *,
    FIRST_VALUE(contract_id) OVER (PARTITION BY strategy, ticker, campaign_seq ORDER BY fill_ts, trade_id) AS campaign_contract_id,
    FIRST_VALUE(price) OVER (PARTITION BY strategy, ticker, campaign_seq ORDER BY fill_ts, trade_id) AS campaign_entry_price,
    LAST_VALUE(running_shares) OVER (PARTITION BY strategy, ticker, campaign_seq ORDER BY fill_ts, trade_id
      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS campaign_open_shares,
    LAST_VALUE(IF(running_shares = 0, price, NULL) IGNORE NULLS) OVER (
      PARTITION BY strategy, ticker, campaign_seq ORDER BY fill_ts, trade_id
      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS campaign_exit_price
  FROM seqd
),
campaigns AS (
  SELECT
    CONCAT(strategy, ':', ticker, ':', CAST(campaign_seq AS STRING)) AS campaign_key,
    strategy, ticker,
    ANY_VALUE(campaign_contract_id) AS contract_id,
    MIN(fill_date) AS entry_date,
    ANY_VALUE(campaign_entry_price) AS entry_price,
    MAX(IF(running_shares = 0, fill_date, NULL)) AS exit_date,
    ANY_VALUE(campaign_exit_price) AS exit_price,
    SUM(IF(side = 'SELL', realized_pnl, 0)) AS realized_pnl,
    SUM(IF(side = 'BUY', shares, 0)) AS total_shares_bought,
    SUM(IF(side = 'SELL', shares, 0)) AS total_shares_sold,
    ANY_VALUE(campaign_open_shares) AS open_shares,
    SUM(commission) AS total_commission,
    COUNTIF(side = 'BUY') AS n_buy_fills,
    COUNTIF(side = 'SELL') AS n_sell_fills
  FROM tagged
  GROUP BY strategy, ticker, campaign_seq
),
-- ===== Expected fixtures (see file header for derivation + live-verification note) =====
expected_lifecycle AS (
  SELECT * FROM UNNEST(ARRAY<STRUCT<
    position_key STRING, exp_shares NUMERIC, exp_entry_date DATE,
    exp_exit_is_null BOOL, exp_exit_date DATE, exp_realized_pnl NUMERIC
  >>[
    ('B:PYR:t1:t3', 10, DATE '2026-01-01', FALSE, DATE '2026-01-10', 166.67),
    ('B:PYR:t2:t3', 5,  DATE '2026-01-05', FALSE, DATE '2026-01-10', 83.33),
    ('B:PEX:t4:t5', 6,  DATE '2026-02-01', FALSE, DATE '2026-02-10', 30.0),
    ('B:PEX:t4:OPEN', 4, DATE '2026-02-01', TRUE, NULL, NULL)
  ])
),
expected_campaigns AS (
  SELECT * FROM UNNEST(ARRAY<STRUCT<
    campaign_key STRING, exp_entry_date DATE, exp_exit_is_null BOOL, exp_exit_date DATE,
    exp_realized_pnl NUMERIC, exp_bought NUMERIC, exp_sold NUMERIC, exp_open_shares NUMERIC
  >>[
    ('B:PYR:1', DATE '2026-01-01', FALSE, DATE '2026-01-10', 250.0, 15, 15, 0),
    ('B:PEX:1', DATE '2026-02-01', TRUE,  NULL,               30.0, 10, 6,  4)
  ])
),
-- ===== Failures =====
lifecycle_count_check AS (
  SELECT 'lifecycle_row_count' AS failure, FORMAT('actual=%d expected=%d', actual_n, expected_n) AS detail
  FROM (SELECT COUNT(*) AS actual_n FROM lifecycle), (SELECT COUNT(*) AS expected_n FROM expected_lifecycle)
  WHERE actual_n != expected_n
),
lifecycle_row_checks AS (
  SELECT CONCAT('lifecycle_mismatch: ', e.position_key) AS failure,
    TO_JSON_STRING(STRUCT(l.shares, l.entry_date, l.exit_date, l.realized_pnl)) AS detail
  FROM expected_lifecycle e
  LEFT JOIN lifecycle l ON l.position_key = e.position_key
  WHERE l.position_key IS NULL
     OR ABS(l.shares - e.exp_shares) > 0.0001
     OR l.entry_date != e.exp_entry_date
     OR (e.exp_exit_is_null AND l.exit_date IS NOT NULL)         -- the phantom-open-leg regression check
     OR (NOT e.exp_exit_is_null AND l.exit_date IS DISTINCT FROM e.exp_exit_date)
     OR (e.exp_realized_pnl IS NOT NULL AND ABS(COALESCE(l.realized_pnl, 0) - e.exp_realized_pnl) > 0.01)
     OR (e.exp_realized_pnl IS NULL AND l.realized_pnl IS NOT NULL)
),
campaign_count_check AS (
  SELECT 'campaign_row_count' AS failure, FORMAT('actual=%d expected=%d', actual_n, expected_n) AS detail
  FROM (SELECT COUNT(*) AS actual_n FROM campaigns), (SELECT COUNT(*) AS expected_n FROM expected_campaigns)
  WHERE actual_n != expected_n
),
campaign_row_checks AS (
  SELECT CONCAT('campaign_mismatch: ', e.campaign_key) AS failure,
    TO_JSON_STRING(STRUCT(c.entry_date, c.exit_date, c.realized_pnl, c.total_shares_bought, c.total_shares_sold, c.open_shares)) AS detail
  FROM expected_campaigns e
  LEFT JOIN campaigns c ON c.campaign_key = e.campaign_key
  WHERE c.campaign_key IS NULL
     OR c.entry_date != e.exp_entry_date
     OR (e.exp_exit_is_null AND c.exit_date IS NOT NULL)
     OR (NOT e.exp_exit_is_null AND c.exit_date IS DISTINCT FROM e.exp_exit_date)
     OR ABS(c.realized_pnl - e.exp_realized_pnl) > 0.01
     OR ABS(c.total_shares_bought - e.exp_bought) > 0.0001
     OR ABS(c.total_shares_sold - e.exp_sold) > 0.0001
     OR ABS(c.open_shares - e.exp_open_shares) > 0.0001
)
SELECT * FROM lifecycle_count_check
UNION ALL SELECT * FROM lifecycle_row_checks
UNION ALL SELECT * FROM campaign_count_check
UNION ALL SELECT * FROM campaign_row_checks

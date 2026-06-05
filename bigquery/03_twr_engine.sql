-- BigQuery deployed-TWR engine (v2 redesign §5). Project: stock-trading-498512.
-- METHOD: value-weighted daily TWR on the active-positions book (NOT a sequential
-- chain-link of closed-trade returns). Flow-immune. The benchmark is a daily risk-free
-- accrual (~4.3%/yr) on deployed days. Replaces the ledger's hand-computed method, which
-- sequentially chain-linked concurrent independent closed trades and materially OVERSTATED
-- Strategy B (reported 1.1099 / +11%; corrected ~0.992 / -0.8%). D was ~unaffected (0 closed
-- trades -> no chaining artifact). See the finding note at the bottom.

-- ===== Daily marks (fed by D2 Step 0 from the IBKR connector, one day per run) =====
-- D2 MUST pull get_price_history(include_corporate_actions=true) so dividends + splits are
-- captured for TOTAL-return TWR. `dividend` = cash dividend per share on its ex-div date;
-- `split_ratio` = e.g. 4.0 for a 4:1 split (prices should be split-adjusted at ingest).
CREATE TABLE IF NOT EXISTS `stock-trading-498512.events.daily_marks` (
  mark_date DATE NOT NULL, ticker STRING NOT NULL, close NUMERIC,
  dividend NUMERIC, split_ratio NUMERIC,
  source STRING DEFAULT 'connector', ingest_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
) PARTITION BY mark_date CLUSTER BY ticker
OPTIONS(description='Daily closes + corporate actions per held ticker (+SGOV). Total-return source for the deployed-TWR engine.');

-- ===== Position lifecycle (entry/exit/shares) — robust to migrated + future events =====
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.position_lifecycle` AS
SELECT position_key,
  ANY_VALUE(strategy) AS strategy, ANY_VALUE(ticker) AS ticker, ANY_VALUE(shares) AS shares,
  COALESCE(MIN(IF(event_type IN ('OPEN','FILL'), DATE(event_ts), NULL)),
           SAFE.PARSE_DATE('%Y-%m-%d', SPLIT(position_key, ':')[SAFE_OFFSET(2)])) AS entry_date,
  MIN(IF(status='CLOSED' OR event_type='CLOSE', DATE(event_ts), NULL)) AS exit_date
FROM `stock-trading-498512.events.position_events`
GROUP BY position_key;

-- ===== Value-weighted daily deployed TOTAL returns per strategy =====
-- r_deployed = Sum(MV_t + dividends_t - MV_{t-1}) / Sum(MV_{t-1}) over held positions.
-- Includes dividends (total return), so held-stock payouts are captured (material for D's
-- multi-month holds). New positions have no prev_mv on entry day -> excluded (join next
-- session). Flow-immune. (Splits handled via split-adjusted close at ingest.)
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.strategy_daily_returns` AS
WITH held AS (
  SELECT m.mark_date, l.strategy, l.position_key,
         l.shares * m.close AS mv,
         l.shares * COALESCE(m.dividend, 0) AS div_cash
  FROM `stock-trading-498512.analytics.position_lifecycle` l
  JOIN `stock-trading-498512.events.daily_marks` m
    ON m.ticker = l.ticker
   AND m.mark_date >= l.entry_date
   AND (l.exit_date IS NULL OR m.mark_date <= l.exit_date)
  WHERE l.strategy IS NOT NULL
),
lagged AS (
  SELECT mark_date, strategy, position_key, mv, div_cash,
         LAG(mv) OVER (PARTITION BY position_key ORDER BY mark_date) AS prev_mv
  FROM held
)
SELECT mark_date AS as_of_date, strategy,
       SAFE_DIVIDE(SUM(mv + div_cash) - SUM(prev_mv), SUM(prev_mv)) AS r_deployed,
       COUNT(*) AS n_positions
FROM lagged
WHERE prev_mv IS NOT NULL
GROUP BY mark_date, strategy;

-- ===== SGOV benchmark = SGOV's ACTUAL total return (close + dividend) =====
-- Replaces the risk-free-accrual proxy. SGOV price is ~flat because its yield pays out as a
-- monthly dividend (IBKR DRIP, action='DIVIDEND_REINVEST' in parking_events), so price-only
-- understates it. Chain-link r_sgov over a strategy's deployed days for its benchmark index.
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.sgov_daily_return` AS
WITH s AS (
  SELECT mark_date, close, COALESCE(dividend, 0) AS dividend,
         LAG(close) OVER (ORDER BY mark_date) AS prev_close
  FROM `stock-trading-498512.events.daily_marks`
  WHERE ticker = 'SGOV'
)
SELECT mark_date AS as_of_date, SAFE_DIVIDE(close + dividend - prev_close, prev_close) AS r_sgov
FROM s WHERE prev_close IS NOT NULL;

-- ===== perf.strategy_daily: authoritative engine state (seeded; extended daily) =====
CREATE TABLE IF NOT EXISTS `stock-trading-498512.perf.strategy_daily` (
  as_of_date DATE NOT NULL, strategy STRING NOT NULL,
  deployed_unit_value NUMERIC, peak_unit_value NUMERIC, current_drawdown NUMERIC,
  sgov_index NUMERIC, excess_vs_sgov NUMERIC,
  deployed_days INT64, closed_trades INT64, gate_n INT64,
  method STRING, note STRING, computed_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
) PARTITION BY as_of_date CLUSTER BY strategy
OPTIONS(description='Deployed-TWR engine output. Seeded 2026-06-05 with corrected current state; extended daily from events.daily_marks.');

-- ===== Kill-trigger flags (latest row per strategy) =====
CREATE OR REPLACE VIEW `stock-trading-498512.perf.kill_flags` AS
SELECT strategy, as_of_date, deployed_unit_value, peak_unit_value, current_drawdown,
       excess_vs_sgov, deployed_days, closed_trades, gate_n,
       current_drawdown <= -0.50                          AS drawdown_kill,        -- kill #1
       (deployed_unit_value >= 2 AND closed_trades < 30)  AS runaway_review,       -- kill #3
       (deployed_days >= 756 AND excess_vs_sgov <= -0.10) AS m2m_underperf_review, -- kill #4
       (closed_trades >= 30)                              AS gate_reached          -- 30-trade gate
FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY as_of_date DESC) rn
      FROM `stock-trading-498512.perf.strategy_daily`)
WHERE rn = 1;

-- ===== Daily forward-extension (run by D2 Step 0 after inserting the day's marks) =====
-- 1. INSERT today's closes into events.daily_marks (held tickers + SGOV).
-- 2. Append one perf.strategy_daily row per deployed strategy:
--   INSERT INTO perf.strategy_daily (as_of_date, strategy, deployed_unit_value, peak_unit_value,
--                                    current_drawdown, sgov_index, excess_vs_sgov, deployed_days,
--                                    closed_trades, gate_n, method, note)
--   WITH prev AS (  -- yesterday's engine state
--     SELECT strategy, deployed_unit_value AS puv, peak_unit_value AS ppeak, sgov_index AS psgov,
--            deployed_days AS pdays, closed_trades, gate_n
--     FROM perf.strategy_daily
--     QUALIFY ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY as_of_date DESC)=1),
--   today AS (SELECT strategy, r_deployed FROM analytics.strategy_daily_returns WHERE as_of_date=@d),
--   sg    AS (SELECT r_sgov FROM analytics.sgov_daily_return WHERE as_of_date=@d)
--   SELECT @d, p.strategy,
--          p.puv*(1+t.r_deployed),
--          GREATEST(p.ppeak, p.puv*(1+t.r_deployed)),
--          p.puv*(1+t.r_deployed)/GREATEST(p.ppeak, p.puv*(1+t.r_deployed)) - 1,
--          p.psgov*(1+sg.r_sgov),          -- SGOV ACTUAL total return on this deployed day
--          p.puv*(1+t.r_deployed)/(p.psgov*(1+sg.r_sgov)) - 1,
--          p.pdays+1, p.closed_trades, p.gate_n,
--          'value-weighted-daily-TWR', NULL
--   FROM prev p JOIN today t USING (strategy) CROSS JOIN sg;
-- (closed_trades / gate_n increment when a CLOSE event lands.)

-- ===== SGOV / corporate-action handling (audited 2026-06-05) =====
-- SGOV pays a MONTHLY dividend reinvested via IBKR DRIP (IBDRIPUS) -> its price is ~flat and its
-- whole return is income. Five gaps were found + addressed:
--   (1) SGOV benchmark: was a risk-free-accrual proxy -> now analytics.sgov_daily_return uses
--       SGOV's actual close+dividend total return.
--   (2) parking_events conflated the DRIP reinvest with trade-funded buys -> reclassified to
--       action='DIVIDEND_REINVEST' (parser updated). Reconciliation (§13) must treat these as
--       income (shares added, NO strategy-cash debit; allocate pro-rata across strategies' SGOV).
--   (3) held-STOCK dividends: strategy_daily_returns now adds dividends (total return) -> matters
--       for D's multi-month holds (DIS ~0.9%/yr, RTX ~2%/yr); negligible for B's week holds.
--   (4) daily_marks now has dividend + split_ratio; D2 MUST pull include_corporate_actions=true.
--   (5) splits: assume split-adjusted close at ingest; split_ratio recorded for audit.
-- The 2026-06-05 SEED row keeps sgov_index=1.0045 (the proxy); the forward engine uses the actual
-- SGOV total return from daily_marks.

-- ===== FINDING (2026-06-05): ledger deployed-TWR was overstated for Strategy B =====
-- The ledger computed B's deployed unit value as a SEQUENTIAL chain of 3 closed winners
-- (IBM 1.0700 x META 1.0453 x BURL 1.0230 = 1.1442) x open-book -3.0% = 1.1099 (+11%).
-- Those trades were CONCURRENT, independent 2%-of-sleeve bets funded separately from SGOV, so
-- chaining them as sequential reinvestment manufactures compounding that did not occur, and it
-- compounds only the realized WINNERS while open losers (HCA -15%, ZBRA -8%) enter as a single
-- -3% drag. Live connector net B P&L is ~flat (realized ~+$6.4, unrealized ~-$7.4 => ~-$1).
-- Corrected via value-weighted method: B ~= 0.992 (-0.8%). D ~= 0.960 (~unchanged; 0 closed
-- trades => no chaining). Operational note: the LIVE Portfolio_Ledger.md still shows 1.1099 and
-- the experiment's kill/gate decisions read it until cutover -> recommend correcting it.

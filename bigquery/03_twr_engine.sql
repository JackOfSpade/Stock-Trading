-- BigQuery deployed-TWR engine (v2 redesign §5). Project: stock-trading-498512.
-- METHOD: value-weighted daily TOTAL-return TWR on the active-positions book, NET of
-- commissions (NOT a sequential chain-link of closed-trade returns). Flow-immune.
-- Benchmark = SGOV's ACTUAL total return (close + dividend) over the same deployed days.
--
-- VALIDATED + POPULATED 2026-06-05 by a full rebuild from the IBKR connector's authoritative
-- fills (get_account_trades) + real daily marks (get_price_history, include_corporate_actions).
-- The original migration had populated events.trade_fills / events.position_events with only
-- the entry fills (missing ALL exits), NULL shares on later positions, and placeholder
-- entry dates (the position_key's 2026-04-22) -- so the engine could not have produced a
-- correct number until this rebuild. Independent hand-check of Strategy D matched the engine
-- to 0.04pct. See the finding note at the bottom.

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

-- ===== Position lifecycle -- sourced from the authoritative fills (events.trade_fills) =====
-- A position = a ticker's BUY (entry) and optional SELL (exit). Carries entry/exit prices +
-- commissions so the TWR can baseline at TOTAL COST and close at NET PROCEEDS.
-- (Redefined 2026-06-05 to read trade_fills, not the broken migrated position_events.)
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.position_lifecycle` AS
WITH entries AS (
  SELECT strategy, ticker, contract_id, DATE(fill_ts) AS entry_date,
         price AS entry_price, shares, commission AS entry_commission
  FROM `stock-trading-498512.events.trade_fills` WHERE side='BUY'
),
exits AS (
  SELECT ticker, DATE(fill_ts) AS exit_date, price AS exit_price,
         realized_pnl, commission AS exit_commission
  FROM `stock-trading-498512.events.trade_fills` WHERE side='SELL'
)
SELECT CONCAT(e.strategy,':',e.ticker,':',CAST(e.entry_date AS STRING)) AS position_key,
       e.strategy, e.ticker, e.contract_id, e.shares,
       e.entry_date, e.entry_price, e.entry_commission,
       x.exit_date, x.exit_price, x.exit_commission, x.realized_pnl
FROM entries e LEFT JOIN exits x USING (ticker);
-- NOTE: assumes one round-trip per ticker (true to date). A re-traded ticker needs a
-- buy/sell pairing key (e.g. by order sequence) before this generalises.

-- ===== Value-weighted daily deployed TOTAL returns per strategy (NET of commissions) =====
-- r_deployed = Sum(mv_t + div_t - prev_mv) / Sum(prev_mv) over held positions, where:
--   entry day: prev_mv = shares*entry_price + entry_commission   (baseline at TOTAL COST)
--   exit  day: mv      = shares*exit_price  - exit_commission     (NET PROCEEDS)
--   interior:  mv = shares*close ; prev_mv = LAG(mv)
-- Dividends (total return) enter the numerator -- material for held-STOCK payouts (IBM, RTX)
-- and decisive for D's multi-month holds. Flow-immune. (Splits via split-adjusted close.)
-- The fill-price boundaries matter: BURL was bought 303.00 but CLOSED 323.83 on entry day;
-- a close-baseline would mis-state it badly. Entry/exit commissions (~$0.32 on ~$30 trades,
-- ~1pct each) are the dominant drag at this position size -- see the finding note.
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.strategy_daily_returns` AS
WITH held AS (
  SELECT m.mark_date, l.strategy, l.position_key, l.shares, l.entry_price, l.entry_commission,
         CASE WHEN m.mark_date = l.exit_date
              THEN l.shares*l.exit_price - COALESCE(l.exit_commission,0)   -- exit day: net proceeds
              ELSE l.shares*m.close END AS mv,                              -- interior: mark at close
         l.shares * COALESCE(m.dividend,0) AS div_cash
  FROM `stock-trading-498512.analytics.position_lifecycle` l
  JOIN `stock-trading-498512.events.daily_marks` m
    ON m.ticker = l.ticker
   AND m.mark_date >= l.entry_date
   AND (l.exit_date IS NULL OR m.mark_date <= l.exit_date)
  WHERE l.strategy IS NOT NULL
),
lagged AS (
  SELECT mark_date, strategy, position_key, mv, div_cash,
         COALESCE(LAG(mv) OVER (PARTITION BY position_key ORDER BY mark_date),
                  shares*entry_price + entry_commission) AS prev_mv   -- entry-day baseline: total cost
  FROM held
)
SELECT mark_date AS as_of_date, strategy,
       SAFE_DIVIDE(SUM(mv + div_cash) - SUM(prev_mv), SUM(prev_mv)) AS r_deployed,
       COUNT(*) AS n_positions
FROM lagged
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

-- ===== perf.strategy_daily: authoritative engine state (rebuilt daily from the views) =====
CREATE TABLE IF NOT EXISTS `stock-trading-498512.perf.strategy_daily` (
  as_of_date DATE NOT NULL, strategy STRING NOT NULL,
  deployed_unit_value NUMERIC, peak_unit_value NUMERIC, current_drawdown NUMERIC,
  sgov_index NUMERIC, excess_vs_sgov NUMERIC,
  deployed_days INT64, closed_trades INT64, gate_n INT64,
  method STRING, note STRING, computed_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
) PARTITION BY as_of_date CLUSTER BY strategy
OPTIONS(description='Deployed-TWR engine output. Full series computed 2026-06-05 from events.daily_marks; recomputed daily by D2.');

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

-- ===== Recompute perf.strategy_daily (the DEPLOYED engine query; run by D2 Step 0) =====
-- After ingesting the day's marks, D2 re-runs this wholesale (idempotent DELETE+INSERT). The
-- full recompute is trivially cheap (~30 deployed days x 2 strategies) and is state-free, so it
-- naturally absorbs any late mark/fill correction -- preferred over an incremental append.
-- deployed_unit_value chains (1+r_deployed); peak = high-water mark vs the 1.000 inception base;
-- sgov_index chains the ACTUAL SGOV total return over the same deployed days.
DELETE FROM `stock-trading-498512.perf.strategy_daily` WHERE TRUE;
INSERT INTO `stock-trading-498512.perf.strategy_daily`
(as_of_date, strategy, deployed_unit_value, peak_unit_value, current_drawdown, sgov_index, excess_vs_sgov, deployed_days, closed_trades, gate_n, method, note)
WITH r AS (
  SELECT sdr.as_of_date, sdr.strategy, sdr.r_deployed, COALESCE(sg.r_sgov,0) AS r_sgov
  FROM `stock-trading-498512.analytics.strategy_daily_returns` sdr
  LEFT JOIN `stock-trading-498512.analytics.sgov_daily_return` sg USING (as_of_date)
),
chained AS (
  SELECT as_of_date, strategy,
    EXP(SUM(LN(1+r_deployed)) OVER w) AS duv,
    EXP(SUM(LN(1+r_sgov)) OVER w) AS sgovidx,
    ROW_NUMBER() OVER w AS dday
  FROM r WINDOW w AS (PARTITION BY strategy ORDER BY as_of_date)
),
peaked AS (
  SELECT *, GREATEST(1.0, MAX(duv) OVER (PARTITION BY strategy ORDER BY as_of_date)) AS peak
  FROM chained
)
SELECT p.as_of_date, p.strategy,
  CAST(p.duv AS NUMERIC), CAST(p.peak AS NUMERIC), CAST(p.duv/p.peak-1 AS NUMERIC),
  CAST(p.sgovidx AS NUMERIC), CAST(p.duv/p.sgovidx-1 AS NUMERIC), p.dday,
  (SELECT COUNT(*) FROM `stock-trading-498512.analytics.position_lifecycle` l
     WHERE l.strategy=p.strategy AND l.exit_date IS NOT NULL AND l.exit_date<=p.as_of_date),
  (SELECT COUNT(*) FROM `stock-trading-498512.analytics.position_lifecycle` l
     WHERE l.strategy=p.strategy AND l.exit_date IS NOT NULL AND l.exit_date<=p.as_of_date),
  'value-weighted-daily-TWR-net-v2',
  'Total-return, net of commissions; SGOV actual total-return benchmark.'
FROM peaked p;

-- ===== SGOV / corporate-action handling (audited 2026-06-05) =====
-- SGOV pays a MONTHLY dividend reinvested via IBKR DRIP (IBDRIPUS) -> its price is ~flat and its
-- whole return is income. Five gaps were found + addressed:
--   (1) SGOV benchmark: was a risk-free-accrual proxy -> now analytics.sgov_daily_return uses
--       SGOV's actual close+dividend total return (validated: index 1.0041 over 29 deployed days;
--       captures the two ex-div dates 2026-05-01 $0.29792 and 2026-06-01 $0.299492).
--   (2) parking_events conflated the DRIP reinvest with trade-funded buys -> reclassified to
--       action='DIVIDEND_REINVEST' (parser updated). Reconciliation (§13) must treat these as
--       income (shares added, NO strategy-cash debit; allocate pro-rata across strategies' SGOV).
--   (3) held-STOCK dividends: strategy_daily_returns adds dividends (total return). Confirmed in
--       the backfill: IBM ex-div $1.69 (2026-05-08, B held) and RTX ex-div $0.73 (2026-05-22,
--       D held) entered the TWR numerator -- a price-only mark would have dropped them.
--   (4) daily_marks now has dividend + split_ratio; D2 MUST pull include_corporate_actions=true.
--   (5) splits: assume split-adjusted close at ingest; split_ratio recorded for audit.

-- ===== FINDINGS (2026-06-05) =====
-- (A) Ledger deployed-TWR was OVERSTATED for Strategy B. The ledger's FIRST-RUN seed computed
--     B's deployed unit value as a SEQUENTIAL chain of 3 closed winners
--     (IBM 1.0700 x META 1.0453 x BURL 1.0230 = 1.1442) x open-book -3.0% = 1.1099 (+11%).
--     Those trades were CONCURRENT, independently-funded 2%-of-sleeve bets, so chaining them as
--     sequential reinvestment manufactures compounding that did not occur and compounds only the
--     winners while open losers enter as a single drag.
-- (B) The migrated event tables were INCOMPLETE/WRONG (trade_fills had only the 10 entries, no
--     exits; position_events had NULL shares + placeholder 2026-04-22 dates). Rebuilt from the
--     connector's 14 authoritative strategy fills + real daily marks.
-- (C) VALIDATED exact value-weighted, total-return, NET-of-commission deployed-TWR (29 days):
--       B = 0.9663 (-3.37pct), peak 1.000, drawdown -3.37pct, excess vs SGOV -3.77pct, 4 closed.
--       D = 0.9573 (-4.27pct), peak 1.000, drawdown -4.27pct, excess vs SGOV -4.66pct, 0 closed.
--     GROSS (pre-commission) deployed-TWR is B +0.05pct / D -2.81pct -- i.e. B's stock-picking
--     was ~flat and COMMISSIONS (~$0.32 on ~$30 trades, ~1pct/fill) are the dominant drag at
--     this position size. Both strategies trail SGOV (1.0041). No kill/gate trigger is near
--     firing (drawdown -3 to -4pct vs the -50pct kill; gate 4/30 and 0/30).
-- These figures SUPERSEDE the 1.1099 seed AND the interim 0.992 estimate; the live ledger +
-- Decision_Log + design doc were updated to match.

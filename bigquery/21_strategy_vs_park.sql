-- Sleeve-vs-SGOV-park substrate for the redesigned weekly self-email. Project: stock-trading-498512.
-- Apply after 03_twr_engine.sql (reads analytics.strategy_daily_returns.deployed_capital, added
-- there in this same redesign) and after 04_analytics.sql (analytics.strategy_nav, state.trade_fills_curated).
--
-- WHY THIS EXISTS: the weekly email answers a single question — "is each strategy beating just
-- parking the cash it was allocated in SGOV?"
--   * PRIMARY (2026-07-03 owner directive): as a PERCENTAGE — the deployed-slice excess return
--     vs SGOV (perf.strategy_daily.excess_vs_sgov = deployed_unit_value / sgov_index − 1, chained
--     over the strategy's own deployed days). This is how the owner evaluates "performance of a
--     strategy"; it's the return on the capital actually put to work, and it's the sanctioned
--     kill/gate metric. Surfaced per-strategy (excess_vs_sgov, carried on strategy_vs_park_daily
--     for the chart) + aggregated across the deployed book (analytics.deployed_book_vs_sgov).
--   * SECONDARY (kept for scale): the DOLLAR edge — deployed_capital × (r_deployed − r_sgov),
--     summed over deployed days. Answers the same question at SLEEVE level (undeployed sleeve cash
--     already sits in the account-level SGOV park — RUNBOOK §29 — so the sleeve differs from the
--     "park everything" counterfactual only on its deployed slice). Shown small in the email as a
--     "$ for scale" note, not the headline.
-- Read by ops/weekly_report/weekly_report.gs (2026-07 redesign) — see ops/weekly_report/README.md
-- and ops/RUNBOOK.md §33.

-- ===== analytics.strategy_vs_park_daily — daily excess-% + cumulative $ edge vs the SGOV park =====
-- The weekly email's chart series (excess_vs_sgov, the % primary) plus the dollar edge (secondary).
-- excess_vs_sgov comes straight from the engine (perf.strategy_daily) so the chart, the scorecard %,
-- and the kill/gate metric are one number. edge_dollars_day = deployed_capital × (r_deployed −
-- r_sgov); cumulative sum is the sleeve-level dollar edge. Simple (non-compounded) daily $ sum:
-- second-order compounding of the counterfactual is < $0.01 at current scale/horizon.
-- r_sgov forward-fill mirrors ops.sp_recompute_engine (a missing SGOV mark must not read as 0).
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.strategy_vs_park_daily` AS
WITH j AS (
  SELECT
    sdr.as_of_date, sdr.strategy, sdr.deployed_capital, sdr.r_deployed,
    COALESCE(
      sg.r_sgov,
      LAST_VALUE(sg.r_sgov IGNORE NULLS) OVER (
        PARTITION BY sdr.strategy ORDER BY sdr.as_of_date
        ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
      0) AS r_sgov
  FROM `stock-trading-498512.analytics.strategy_daily_returns` sdr
  LEFT JOIN `stock-trading-498512.analytics.sgov_daily_return` sg USING (as_of_date)
)
SELECT
  j.as_of_date, j.strategy, j.deployed_capital,
  -- % primary: the engine's chained deployed-vs-SGOV excess for this strategy-day (the chart's y).
  pd.excess_vs_sgov,
  -- $ secondary: sleeve-level dollar edge (kept for the "for scale" note).
  j.deployed_capital * (j.r_deployed - j.r_sgov) AS edge_dollars_day,
  SUM(j.deployed_capital * (j.r_deployed - j.r_sgov)) OVER (
    PARTITION BY j.strategy ORDER BY j.as_of_date) AS edge_dollars_cum
FROM j
LEFT JOIN `stock-trading-498512.perf.strategy_daily` pd
  ON pd.as_of_date = j.as_of_date AND pd.strategy = j.strategy;

-- ===== analytics.strategy_vs_park — latest verdict row per ever-deployed strategy =====
-- 7d-ago anchor: nearest row to CURRENT_DATE−7 (America/Denver — the operating plane; display tz
-- never leaks into SQL windows), deterministic tie-break toward the NEWER row (', as_of_date DESC'
-- — same pattern as state.account_nav_7d_ago; a Monday-holiday week produces real two-row ties,
-- and dbt-parity evaluates the twin and the live view independently, so a nondeterministic pick
-- would show up as spurious drift). In a strategy's first week the nearest row is its own early
-- history, so edge_dollars_wk reads as approximately since-inception — same accepted behavior as
-- twr_7d.
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.strategy_vs_park` AS
WITH latest AS (
  SELECT strategy, as_of_date, edge_dollars_cum
  FROM `stock-trading-498512.analytics.strategy_vs_park_daily`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY as_of_date DESC) = 1
),
wk_ago AS (
  SELECT strategy, edge_dollars_cum AS edge_dollars_cum_7d_ago
  FROM `stock-trading-498512.analytics.strategy_vs_park_daily`
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY strategy
    ORDER BY ABS(DATE_DIFF(as_of_date, DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY), DAY)),
             as_of_date DESC
  ) = 1
),
firsts AS (
  SELECT strategy, MIN(as_of_date) AS first_deployed_date
  FROM `stock-trading-498512.analytics.strategy_vs_park_daily`
  GROUP BY strategy
),
comm AS (
  SELECT strategy, SUM(commission) AS commissions_to_date
  FROM `stock-trading-498512.state.trade_fills_curated`
  WHERE ticker != 'SGOV' AND strategy IS NOT NULL
  GROUP BY strategy
)
SELECT
  l.strategy, l.as_of_date, l.edge_dollars_cum,
  l.edge_dollars_cum - w.edge_dollars_cum_7d_ago AS edge_dollars_wk,
  f.first_deployed_date,
  c.commissions_to_date
FROM latest l
JOIN wk_ago w USING (strategy)
JOIN firsts f USING (strategy)
LEFT JOIN comm c USING (strategy);

-- ===== analytics.park_baseline — "what would parking everything have earned" (hero subline) =====
-- One row. Anchored on strategy_vs_park_daily (NOT perf.strategy_daily, which is rebuilt via a
-- non-atomic DELETE+INSERT in ops.sp_recompute_engine — a mid-recompute read would transiently
-- see an empty table). park_dollars_approx uses current total sleeve NAV as the base
-- (≈ deposits ± small P&L) rather than duplicating the deposit literal hardcoded in
-- analytics.strategy_nav — labeled ≈ in the email.
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.park_baseline` AS
WITH f AS (
  SELECT MIN(as_of_date) AS first_deployed_date
  FROM `stock-trading-498512.analytics.strategy_vs_park_daily`
),
p AS (
  SELECT EXP(SUM(LN(1 + sg.r_sgov))) - 1 AS park_return
  FROM `stock-trading-498512.analytics.sgov_daily_return` sg, f
  WHERE sg.as_of_date >= f.first_deployed_date
)
SELECT
  f.first_deployed_date,
  p.park_return,
  (SELECT SUM(nav) FROM `stock-trading-498512.analytics.strategy_nav`) * p.park_return
    AS park_dollars_approx
FROM f, p;

-- ===== analytics.deployed_book_vs_sgov — combined deployed-book excess % (the email's hero) =====
-- One row. The single percentage the hero tile leads with: treat every strategy's deployed
-- positions as ONE book, value-weight the daily returns by deployed_capital, chain it, and compare
-- to SGOV chained over the same days. book_return / sgov_return are the two legs; combined_excess_pct
-- = book_return-vs-sgov as a ratio (the number shown). Weighting by deployed_capital is what makes
-- this a portfolio-level answer rather than a naive average of per-strategy percentages (which don't
-- combine). r_sgov forward-fill mirrors the engine. Percentages don't sum, so this is NOT the sum of
-- per-strategy excess — it's the aggregate book's own excess return.
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.deployed_book_vs_sgov` AS
WITH agg AS (
  SELECT sdr.as_of_date,
         SAFE_DIVIDE(SUM(sdr.deployed_capital * sdr.r_deployed), SUM(sdr.deployed_capital)) AS r_agg
  FROM `stock-trading-498512.analytics.strategy_daily_returns` sdr
  GROUP BY sdr.as_of_date
),
j AS (
  SELECT a.as_of_date, a.r_agg,
    COALESCE(
      sg.r_sgov,
      LAST_VALUE(sg.r_sgov IGNORE NULLS) OVER (
        ORDER BY a.as_of_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
      0) AS r_sgov
  FROM agg a
  LEFT JOIN `stock-trading-498512.analytics.sgov_daily_return` sg USING (as_of_date)
)
SELECT
  MIN(as_of_date) AS first_deployed_date,
  MAX(as_of_date) AS as_of_date,
  EXP(SUM(LN(1 + r_agg))) - 1 AS book_return,
  EXP(SUM(LN(1 + r_sgov))) - 1 AS sgov_return,
  EXP(SUM(LN(1 + r_agg))) / EXP(SUM(LN(1 + r_sgov))) - 1 AS combined_excess_pct
FROM j;

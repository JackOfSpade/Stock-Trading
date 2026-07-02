-- Weekly performance report substrate. Project: stock-trading-498512.
-- Feeds the WEEKLY SELF-EMAIL digest, which is sent by a Google Apps Script
-- (ops/weekly_report/weekly_report.gs) running on Google's servers as the owner —
-- NOT by a Claude routine and NOT via the Gmail connector (the official connector
-- can only draft, not send). The Apps Script reads the objects below straight from
-- BigQuery and self-emails. See ops/weekly_report/README.md.
--
-- Objects:
--   * analytics.strategy_scorecard  — one row per strategy: activation + budget + profitability
--   * ops.account_snapshot          — daily account-level NAV/cash/TWR (written by D2 Step 0b)
--   * state.account_latest          — latest account snapshot (dedup view)
--   * analytics.weekly_activity     — last-7-day fills / GO / NO-GO / pending-order counts
-- Idempotent (OR REPLACE / IF NOT EXISTS). Apply via the BigQuery MCP execute_sql after
-- 04_analytics.sql, 03_twr_engine.sql, 01_schema.sql, 10_observability.sql.

-- ===== analytics.strategy_scorecard — one row per strategy (the digest's main table) =====
-- Joins the three domains the digest needs:
--   * activation (state.current_regime, scope=STRATEGY_ACTIVATION) — "what's active/inactive"
--   * budget     (analytics.strategy_nav)                          — NAV + 2%-sizing base + deployed/available
--   * profitability (perf.kill_flags = latest perf.strategy_daily) — deployed-TWR, excess vs SGOV, drawdown, gate
-- Reused beyond the email as a clean one-row-per-strategy feed for the health dashboard.
-- unit_value_7d_ago — nearest perf.strategy_daily row to "7 days ago" per strategy (handles
-- weekends/holidays where there is no exact 7-day-back trading day). Feeds the scorecard's
-- week-over-week Δ column so the weekly digest shows movement, not just since-inception TWR.
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.strategy_unit_value_7d_ago` AS
SELECT strategy, deployed_unit_value AS deployed_unit_value_7d_ago
FROM `stock-trading-498512.perf.strategy_daily`
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY strategy
  ORDER BY ABS(DATE_DIFF(as_of_date, DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY), DAY))
) = 1;

CREATE OR REPLACE VIEW `stock-trading-498512.analytics.strategy_scorecard` AS
WITH act AS (
  SELECT key AS strategy, value AS activation, rationale AS activation_note
  FROM `stock-trading-498512.state.current_regime`
  WHERE scope = 'STRATEGY_ACTIVATION'
)
SELECT
  n.strategy,
  a.activation,
  a.activation_note,
  -- ACTIVE = activation contains ACTIVATE and is not a DO-NOT-ACTIVATE; everything
  -- else (DO-NOT-ACTIVATE, NULL) is inactive. HYBRID/divergent still reads as active here.
  COALESCE(a.activation LIKE '%ACTIVATE%' AND a.activation NOT LIKE '%DO-NOT%', FALSE) AS is_active,
  n.nav, n.sizing_base_2pct, n.deployed_mv, n.available_funds,
  n.realized_pnl, n.unrealized_pnl, n.dividends_held,
  k.deployed_unit_value, k.peak_unit_value, k.current_drawdown,
  k.excess_vs_sgov, k.deployed_days, k.closed_trades,
  SAFE_DIVIDE(k.deployed_unit_value, u.deployed_unit_value_7d_ago) - 1 AS twr_7d,
  GREATEST(0, 30 - COALESCE(k.closed_trades, 0)) AS closed_to_gate,
  COALESCE(k.drawdown_kill, FALSE) OR COALESCE(k.runaway_review, FALSE)
    OR COALESCE(k.m2m_underperf_review, FALSE) AS any_kill_flag,
  (COALESCE(n.deployed_mv, 0) > 0) AS has_open_exposure
FROM `stock-trading-498512.analytics.strategy_nav` n
LEFT JOIN act a ON a.strategy = n.strategy
LEFT JOIN `stock-trading-498512.perf.kill_flags` k ON k.strategy = n.strategy
LEFT JOIN `stock-trading-498512.analytics.strategy_unit_value_7d_ago` u ON u.strategy = n.strategy
ORDER BY n.strategy;

-- ===== ops.account_snapshot — daily account-level NAV / cash / TWR (written by D2 Step 0b) =====
-- The account-level NAV + Week/MTD/YTD TWR come from the IBKR connector
-- (get_account_summary / get_account_balances / get_pa_performance_all_periods), which the
-- Apps Script cannot reach. D2 already reads these in Step 0, so D2 persists one row/day here.
-- This also fills a real gap: perf.strategy_daily is per-strategy deployed-TWR; this is the
-- first account-level NAV history in BigQuery (week-over-week deltas, charts, the digest header).
-- twr_* are cumulative TWR fractions for the period END (e.g. 0.0009 = +0.09%), taken from the
-- LAST element of each period's `cps` array in get_pa_performance_all_periods.
CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.account_snapshot` (
  snapshot_date DATE NOT NULL,
  nav NUMERIC,
  total_cash NUMERIC,
  buying_power NUMERIC,
  available_funds NUMERIC,
  gross_position_value NUMERIC,
  sgov_market_value NUMERIC,
  twr_1d NUMERIC, twr_7d NUMERIC, twr_mtd NUMERIC, twr_ytd NUMERIC, twr_1y NUMERIC,
  source STRING DEFAULT 'D2-connector',
  ingest_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP()
) PARTITION BY snapshot_date
OPTIONS(description='Daily account-level NAV/cash/TWR snapshot from the IBKR connector (D2 Step 0b). Account-level NAV history; read by the weekly Apps Script emailer + dashboard. Per-strategy deployed-TWR is perf.strategy_daily.');

-- Latest snapshot (dedup: newest snapshot_date, newest ingest within the day).
CREATE OR REPLACE VIEW `stock-trading-498512.state.account_latest` AS
SELECT * FROM `stock-trading-498512.ops.account_snapshot`
QUALIFY ROW_NUMBER() OVER (ORDER BY snapshot_date DESC, ingest_ts DESC) = 1;

-- Nearest snapshot to "7 days before the latest snapshot" — an EXACT dollar NAV delta for the
-- digest header (twr_7d strips cash flows, so it cannot answer "how many dollars did NAV move
-- this week" whenever a deposit/withdrawal occurred; this reads the actual snapshot history
-- instead of backing the delta out of a return fraction).
CREATE OR REPLACE VIEW `stock-trading-498512.state.account_nav_7d_ago` AS
SELECT nav, snapshot_date
FROM `stock-trading-498512.ops.account_snapshot`
QUALIFY ROW_NUMBER() OVER (
  ORDER BY ABS(DATE_DIFF(snapshot_date,
    DATE_SUB((SELECT MAX(snapshot_date) FROM `stock-trading-498512.ops.account_snapshot`), INTERVAL 7 DAY),
    DAY)),
    snapshot_date DESC
) = 1;

-- ===== analytics.weekly_activity — last-7-day activity counts for the digest =====
-- Relative 7-day window (America/Denver), so it stays a view, not a stored table.
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.weekly_activity` AS
SELECT
  -- DATE(fill_ts, 'America/Denver') — NOT bare DATE(fill_ts) (defaults to UTC): a fill timestamped
  -- after ~17-18:00 Denver lands on the next UTC calendar day, mis-aging it by one day against this
  -- Denver-anchored 7-day window (2026-07 report-system fix; the count is display-only but the two
  -- date derivations must agree).
  (SELECT COUNT(*) FROM `stock-trading-498512.state.trade_fills_curated`
     WHERE DATE(fill_ts, 'America/Denver') >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY)) AS fills_7d,
  (SELECT COUNT(*) FROM `stock-trading-498512.events.decision_log`
     WHERE entry_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY)
       AND UPPER(decision) = 'GO') AS go_7d,
  (SELECT COUNT(*) FROM `stock-trading-498512.events.decision_log`
     WHERE entry_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY)
       AND UPPER(decision) = 'NO-GO') AS nogo_7d,
  (SELECT COUNT(*) FROM `stock-trading-498512.state.open_queue`
     WHERE queue = 'ORDER_STAGED') AS pending_orders;

-- ===== analytics.weekly_fills / analytics.weekly_nogos — single-source the email's detail lists =====
-- Previously the fills/NO-GO SELECTs lived only inline in weekly_report.gs (the one email query not
-- backed by a view here). Moved so every email query is a named, version-controlled BigQuery object
-- and the .gs file does SELECT * — same convention as strategy_scorecard / weekly_activity.
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.weekly_fills` AS
SELECT ticker, side, shares, price, strategy,
       CAST(DATE(fill_ts, 'America/Denver') AS STRING) AS fill_date,
       UNIX_MILLIS(fill_ts) AS fill_ts_ms  -- lets the renderer format in the DETECTED user tz (state.user_tz)
FROM `stock-trading-498512.state.trade_fills_curated`
WHERE DATE(fill_ts, 'America/Denver') >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY)
ORDER BY fill_ts DESC LIMIT 6;

CREATE OR REPLACE VIEW `stock-trading-498512.analytics.weekly_nogos` AS
SELECT ticker, strategy, entry_date
FROM `stock-trading-498512.events.decision_log`
WHERE entry_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY)
  AND UPPER(decision) = 'NO-GO' AND ticker IS NOT NULL
ORDER BY entry_date DESC LIMIT 8;

-- ===== state.open_positions_summary — the current book (2026-07 addition) =====
-- The single biggest content gap in the weekly digest: the most operator-relevant fact (what is
-- currently held) was not in the email at all. One row per open position, marked at the latest
-- curated close, with its two mechanical exit triggers (convergence_target / time_exit_date).
CREATE OR REPLACE VIEW `stock-trading-498512.state.open_positions_summary` AS
WITH latest_close AS (
  SELECT ticker, close, mark_date FROM `stock-trading-498512.state.daily_marks_curated`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY ticker ORDER BY mark_date DESC) = 1
)
SELECT
  cp.strategy, cp.ticker, cp.shares, cp.cost_basis,
  lc.close AS mark, lc.mark_date,
  ROUND(cp.shares * lc.close, 2) AS market_value,
  SAFE_DIVIDE(cp.shares * lc.close - cp.cost_basis, cp.cost_basis) AS unrealized_pct,
  cp.convergence_target, cp.time_exit_date
FROM `stock-trading-498512.state.current_positions` cp
LEFT JOIN latest_close lc ON lc.ticker = cp.ticker
WHERE cp.status = 'OPEN' AND cp.ticker != 'SGOV'
ORDER BY cp.strategy, cp.ticker;

-- ===== state.next_7_days — forward-looking action calendar (2026-07 addition) =====
-- Turns the digest forward-looking instead of purely retrospective: queue items due, mechanical
-- time-exits due, and staged-order windows closing in the next 7 days. Mirrors the "due today"
-- categories in 05_state_briefing.sql (state.daily_briefing) but widened to a 7-day forward window
-- for weekly-digest purposes — NOT a substitute for the daily due-today gate D1/D2 use.
CREATE OR REPLACE VIEW `stock-trading-498512.state.next_7_days` AS
SELECT 'QUEUE_DUE' AS category, item_key AS ref, ticker, strategy, due_date
FROM `stock-trading-498512.state.open_queue`
WHERE due_date BETWEEN CURRENT_DATE('America/Denver')
                    AND DATE_ADD(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY)
UNION ALL
SELECT 'TIME_EXIT' AS category, position_key AS ref, ticker, strategy, time_exit_date AS due_date
FROM `stock-trading-498512.state.current_positions`
WHERE status = 'OPEN' AND strategy != 'D'  -- D runs to thesis-invalidation, no time exit
  AND time_exit_date BETWEEN CURRENT_DATE('America/Denver')
                          AND DATE_ADD(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY)
UNION ALL
SELECT 'ORDER_WINDOW' AS category, item_key AS ref, ticker, strategy, entry_window_close AS due_date
FROM `stock-trading-498512.state.open_orders`
WHERE entry_window_close BETWEEN CURRENT_DATE('America/Denver')
                              AND DATE_ADD(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY)
ORDER BY due_date;

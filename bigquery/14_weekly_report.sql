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
  GREATEST(0, 30 - COALESCE(k.closed_trades, 0)) AS closed_to_gate,
  COALESCE(k.drawdown_kill, FALSE) OR COALESCE(k.runaway_review, FALSE)
    OR COALESCE(k.m2m_underperf_review, FALSE) AS any_kill_flag,
  (COALESCE(n.deployed_mv, 0) > 0) AS has_open_exposure
FROM `stock-trading-498512.analytics.strategy_nav` n
LEFT JOIN act a ON a.strategy = n.strategy
LEFT JOIN `stock-trading-498512.perf.kill_flags` k ON k.strategy = n.strategy
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

-- ===== analytics.weekly_activity — last-7-day activity counts for the digest =====
-- Relative 7-day window (America/Denver), so it stays a view, not a stored table.
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.weekly_activity` AS
SELECT
  (SELECT COUNT(*) FROM `stock-trading-498512.state.trade_fills_curated`
     WHERE DATE(fill_ts) >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY)) AS fills_7d,
  (SELECT COUNT(*) FROM `stock-trading-498512.events.decision_log`
     WHERE entry_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY)
       AND UPPER(decision) = 'GO') AS go_7d,
  (SELECT COUNT(*) FROM `stock-trading-498512.events.decision_log`
     WHERE entry_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY)
       AND UPPER(decision) = 'NO-GO') AS nogo_7d,
  (SELECT COUNT(*) FROM `stock-trading-498512.state.open_queue`
     WHERE queue = 'ORDER_STAGED') AS pending_orders;

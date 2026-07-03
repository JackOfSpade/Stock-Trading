-- Parallel-run dbt port of bigquery/22_cash_flows.sql:analytics.account_reconciliation (redefined
-- there, supersedes the earlier hardcoded-literal version) — canonical source is that file until
-- owner cutover. §13 account-integrity, ACCOUNT-LEVEL: the events-side expected total, now sourced
-- from events.cash_flows (self-improvement audit B-1-exec) instead of a hardcoded literal. D2 Step 0
-- compares it (+ the connector's live SGOV mark) to the connector NLV / SGOV shares / cash and flags
-- any residual > ~$1. Per-strategy budget = analytics.strategy_nav (available_funds).

SELECT
  (SELECT ROUND(SUM(amount),2) FROM {{ source('events', 'cash_flows') }}) AS total_deposits,
  (SELECT ROUND(SUM(realized_pnl),2) FROM {{ ref('trade_fills_curated') }}) AS strategy_realized_pnl,
  (SELECT ROUND(SUM(nav),2) FROM {{ ref('strategy_nav') }}) AS events_side_nav_total,
  (SELECT ROUND(SUM(deployed_mv),2) FROM {{ ref('strategy_nav') }}) AS deployed_total,
  (SELECT ROUND(SUM(available_funds),2) FROM {{ ref('strategy_nav') }}) AS undeployed_total

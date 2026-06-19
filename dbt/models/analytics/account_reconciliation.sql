-- Parallel-run dbt port of bigquery/04_analytics.sql:analytics.account_reconciliation — canonical source is that file until owner cutover.
-- §13 account-integrity, ACCOUNT-LEVEL: the events-side expected total. D2 Step 0 compares it
-- (+ the connector's live SGOV mark) to the connector NLV / SGOV shares / cash and flags any
-- residual > ~$1. Per-strategy budget = analytics.strategy_nav (available_funds).

SELECT
  CAST(9446.86 AS NUMERIC) AS total_deposits,
  (SELECT ROUND(SUM(realized_pnl),2) FROM {{ ref('trade_fills_curated') }}) AS strategy_realized_pnl,
  (SELECT ROUND(SUM(nav),2) FROM {{ ref('strategy_nav') }}) AS events_side_nav_total,
  (SELECT ROUND(SUM(deployed_mv),2) FROM {{ ref('strategy_nav') }}) AS deployed_total,
  (SELECT ROUND(SUM(available_funds),2) FROM {{ ref('strategy_nav') }}) AS undeployed_total

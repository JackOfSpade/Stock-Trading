-- Singular test (passes when ZERO rows): SUM(events.cash_flows.amount) must equal
-- SUM(analytics.strategy_nav.deposits) — i.e. the equal-split/attributed allocation in strategy_nav
-- never drops or double-counts a flow. Self-improvement audit B-1-exec. Also guards the "exactly 5
-- strategies" assumption baked into the equal-split (amount/5): if that ever changes, this test
-- catches the resulting reconciliation drift immediately rather than a silent NAV mis-split.

SELECT
  (SELECT ROUND(SUM(amount), 2) FROM {{ source('events', 'cash_flows') }}) AS cash_flows_total,
  (SELECT ROUND(SUM(deposits), 2) FROM {{ ref('strategy_nav') }}) AS strategy_nav_deposits_total
HAVING cash_flows_total != strategy_nav_deposits_total

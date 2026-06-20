-- Parallel-run dbt port of bigquery/14_weekly_report.sql:analytics.strategy_scorecard — canonical source is that file until owner cutover.
-- One row per strategy: activation (current_regime) + budget (strategy_nav) + profitability
-- (kill_flags = latest perf.strategy_daily). The weekly self-email + dashboard read this.
WITH act AS (
  SELECT key AS strategy, value AS activation, rationale AS activation_note
  FROM {{ ref('current_regime') }}
  WHERE scope = 'STRATEGY_ACTIVATION'
)
SELECT
  n.strategy,
  a.activation,
  a.activation_note,
  COALESCE(a.activation LIKE '%ACTIVATE%' AND a.activation NOT LIKE '%DO-NOT%', FALSE) AS is_active,
  n.nav, n.sizing_base_2pct, n.deployed_mv, n.available_funds,
  n.realized_pnl, n.unrealized_pnl, n.dividends_held,
  k.deployed_unit_value, k.peak_unit_value, k.current_drawdown,
  k.excess_vs_sgov, k.deployed_days, k.closed_trades,
  GREATEST(0, 30 - COALESCE(k.closed_trades, 0)) AS closed_to_gate,
  COALESCE(k.drawdown_kill, FALSE) OR COALESCE(k.runaway_review, FALSE)
    OR COALESCE(k.m2m_underperf_review, FALSE) AS any_kill_flag,
  (COALESCE(n.deployed_mv, 0) > 0) AS has_open_exposure
FROM {{ ref('strategy_nav') }} n
LEFT JOIN act a ON a.strategy = n.strategy
LEFT JOIN {{ ref('kill_flags') }} k ON k.strategy = n.strategy
ORDER BY n.strategy

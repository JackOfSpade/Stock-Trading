-- Parallel-run dbt port of bigquery/10_observability.sql:state.system_health — canonical source is that file until owner cutover.
-- One-row green/red rollup (freshness + embeddings + kills + open critical alerts).
--
-- Caveats vs the live view:
--   * embedding_health is a SOURCE here (it depends on remote models / AI.* — not dbt-owned).
--   * ops.alerts (the alert sink) is NOT modeled by dbt either; the two alert COUNTIFs are
--     queried inline from the live ops.alerts table via the project-qualified name, exactly
--     as in 10_observability.sql. This is the one place the ported view reaches outside the
--     dbt DAG (ops.* is procedure/DML-maintained, intentionally out of scope). The singular
--     test assert_system_health_single_row.sql guards the one-row invariant.

SELECT
  f.last_trading_day, f.last_mark_date, f.engine_through,
  f.marks_fresh, f.engine_fresh, f.d2_ran_last_trading_day,
  eh.is_healthy AS embeddings_healthy,
  (SELECT COUNTIF(NOT resolved AND severity = 'critical') FROM `stock-trading-498512.ops.alerts`) AS open_critical_alerts,
  (SELECT COUNTIF(NOT resolved) FROM `stock-trading-498512.ops.alerts`) AS open_alerts,
  (SELECT COUNTIF(drawdown_kill OR runaway_review OR m2m_underperf_review) FROM {{ ref('kill_flags') }}) AS firing_kill_flags,
  (f.marks_fresh AND f.engine_fresh AND eh.is_healthy
     AND (SELECT COUNTIF(NOT resolved AND severity = 'critical') FROM `stock-trading-498512.ops.alerts`) = 0
  ) AS all_green,
  CURRENT_TIMESTAMP() AS checked_at
FROM {{ ref('freshness') }} f, {{ source('state_external', 'embedding_health') }} eh

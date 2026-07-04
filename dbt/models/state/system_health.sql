-- Parallel-run dbt port of bigquery/10_observability.sql + bigquery/23_trading_control.sql (position
-- drift promoted to blocking there, self-improvement audit B-5-exec/B-6-data):state.system_health —
-- canonical source is those files until owner cutover.
-- One-row green/red rollup (freshness + embeddings + kills + open critical alerts + position drift).
--
-- Caveats vs the live view:
--   * embedding_health is a SOURCE here (it depends on remote models / AI.* — not dbt-owned).
--   * ops.alerts (the alert sink) is NOT modeled by dbt either; the two alert COUNTIFs are
--     queried inline from the live ops.alerts table via the project-qualified name, exactly
--     as in 10_observability.sql. This is the one place the ported view reaches outside the
--     dbt DAG (ops.* is procedure/DML-maintained, intentionally out of scope). The singular
--     test assert_system_health_single_row.sql guards the one-row invariant.
--   * state.position_reconciliation (18_stack_review_fixes.sql) is likewise not yet dbt-ported —
--     referenced inline by project-qualified name, same as ops.alerts above.

WITH alerts_summary AS (
  -- Computed once and reused below (2026-07-04 audit finding: open_critical_alerts and the
  -- identical subquery embedded in all_green were two hand-kept copies of the same COUNTIF —
  -- mirrors the identical fix in the live bigquery/23_trading_control.sql).
  SELECT
    COUNTIF(NOT resolved AND severity = 'critical') AS open_critical_alerts,
    COUNTIF(NOT resolved) AS open_alerts
  FROM `stock-trading-498512.ops.alerts`
)
SELECT
  f.last_trading_day, f.last_mark_date, f.engine_through,
  f.marks_fresh, f.engine_fresh, f.d2_ran_last_trading_day,
  eh.is_healthy AS embeddings_healthy,
  a.open_critical_alerts,
  a.open_alerts,
  (SELECT COUNTIF(drawdown_kill OR runaway_review OR m2m_underperf_review) FROM {{ ref('kill_flags') }}) AS firing_kill_flags,
  COALESCE((SELECT LOGICAL_OR(drifted) FROM `stock-trading-498512.state.position_reconciliation`), FALSE) AS position_drift_detected,
  (f.marks_fresh AND f.engine_fresh AND eh.is_healthy
     AND a.open_critical_alerts = 0
     AND NOT COALESCE((SELECT LOGICAL_OR(drifted) FROM `stock-trading-498512.state.position_reconciliation`), FALSE)
  ) AS all_green,
  CURRENT_TIMESTAMP() AS checked_at
FROM {{ ref('freshness') }} f, {{ source('state_external', 'embedding_health') }} eh, alerts_summary a

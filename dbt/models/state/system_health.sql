-- Parallel-run dbt port of bigquery/10_observability.sql + bigquery/23_trading_control.sql (position
-- drift promoted to blocking there, self-improvement audit B-5-exec/B-6-data):state.system_health —
-- canonical source is those files until owner cutover.
-- One-row green/red rollup (freshness + embeddings + kills + open critical alerts + position drift).
--
-- Caveats vs the live view:
--   * embedding_health is a SOURCE here (it depends on remote models / AI.* — not dbt-owned).
--   * ops.alerts (the alert sink) is a dbt SOURCE (declared under `ops` in sources.yml, added
--     2026-08-22 dbt view-coverage burn-down); the two alert COUNTIFs read it via source('ops',
--     'alerts'), same as 10_observability.sql's live definition. ops.* stays out of dbt's own build
--     graph (procedure/DML-maintained), but is declared so `dbt list`/`dbt docs`'s DAG includes this
--     model in ops.alerts' downstream set. The singular test assert_system_health_single_row.sql
--     guards the one-row invariant.
--   * ORGANIZATION FIX (2026-08-31 code-quality pass, dbt#1): state.position_reconciliation
--     (18_stack_review_fixes.sql) IS dbt-ported (dbt/models/state/position_reconciliation.sql) — this
--     comment and the two hardcoded `stock-trading-498512.state.position_reconciliation` references
--     below were stale (position_drift_detected read the raw table by name instead of ref(), which
--     kept this model OUT of `dbt list --select state.position_reconciliation+`'s downstream set).
--     Now ref('position_reconciliation'), a compiled-SQL-identical substitution.

WITH alerts_summary AS (
  -- Computed once and reused below (2026-07-04 audit finding: open_critical_alerts and the
  -- identical subquery embedded in all_green were two hand-kept copies of the same COUNTIF —
  -- mirrors the identical fix in the live bigquery/23_trading_control.sql).
  SELECT
    COUNTIF(NOT resolved AND severity = 'critical') AS open_critical_alerts,
    COUNTIF(NOT resolved) AS open_alerts
  FROM {{ source('ops', 'alerts') }}
)
SELECT
  f.last_trading_day, f.last_mark_date, f.engine_through,
  f.marks_fresh, f.engine_fresh, f.d2_ran_last_trading_day,
  f.marks_due_through, f.marks_current, f.engine_current,
  eh.is_healthy AS embeddings_healthy,
  a.open_critical_alerts,
  a.open_alerts,
  (SELECT COUNTIF(drawdown_kill OR runaway_review OR m2m_underperf_review) FROM {{ ref('kill_flags') }}) AS firing_kill_flags,
  COALESCE((SELECT LOGICAL_OR(drifted) FROM {{ ref('position_reconciliation') }}), FALSE) AS position_drift_detected,
  -- CADENCE-AWARE as of 2026-08-15 (bigquery/173): was marks_fresh AND engine_fresh, which read FALSE
  -- every Friday evening through Sunday's D2a purely because the daily tier is Sun-Thu. all_green is
  -- display-only now (bigquery/107's trading gates read state.freshness directly, never this column).
  (f.marks_current AND f.engine_current AND eh.is_healthy
     AND a.open_critical_alerts = 0
     AND NOT COALESCE((SELECT LOGICAL_OR(drifted) FROM {{ ref('position_reconciliation') }}), FALSE)
  ) AS all_green,
  CURRENT_TIMESTAMP() AS checked_at
FROM {{ ref('freshness') }} f, {{ source('state_external', 'embedding_health') }} eh, alerts_summary a

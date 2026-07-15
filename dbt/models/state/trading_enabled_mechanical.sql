-- Parallel-run dbt port of bigquery/34_alert_lifecycle.sql:state.trading_enabled_mechanical —
-- canonical source is that file until owner cutover. Added 2026-07-14 (audit finding, HIGH
-- severity) — this D2a-scoped safety gate had ZERO dbt mirror despite its live sibling
-- state.trading_enabled having full coverage since 2026-07-04, so scripts/dbt_parity.py could never
-- catch drift on this gate. Deliberately excludes marks_fresh/engine_fresh (D2a's own same-run-
-- circular term — see bigquery/33_gate_ordering_fix.sql's header). ops.sp_assert_trading_enabled_
-- mechanical reads this before D2a's mechanical sweep/persist-and-wait re-craft step.
WITH ctrl AS (
  SELECT ARRAY_AGG(STRUCT(halt_all, reason, mode) ORDER BY control_ts DESC LIMIT 1)[SAFE_OFFSET(0)] AS latest
  FROM {{ source('ops', 'trading_control') }}
),
health AS (
  SELECT embeddings_healthy, position_drift_detected
  FROM {{ ref('system_health') }}
),
al AS (
  SELECT COUNTIF(NOT resolved AND severity = 'critical' AND category != 'trading_halted') AS blocking_criticals
  FROM `stock-trading-498512.ops.alerts`
),
dd AS (SELECT drawdown_breach, drawdown_from_peak FROM {{ ref('book_drawdown_watch') }})
SELECT
  NOT COALESCE(ctrl.latest.halt_all, FALSE)
  AND COALESCE(health.embeddings_healthy, FALSE)
  AND al.blocking_criticals = 0
  AND NOT COALESCE(health.position_drift_detected, TRUE)
  AND NOT COALESCE(dd.drawdown_breach, FALSE) AS trading_enabled,
  CASE
    WHEN COALESCE(ctrl.latest.halt_all, FALSE) THEN
      FORMAT('halt_all (mode=%s): %s', COALESCE(ctrl.latest.mode, '?'), COALESCE(ctrl.latest.reason, 'no reason logged'))
    WHEN NOT COALESCE(health.embeddings_healthy, FALSE) THEN
      'state.system_health.embeddings_healthy = FALSE'
    WHEN al.blocking_criticals != 0 THEN
      FORMAT('%d open critical alert(s) (excluding the trading_halted gate echo) — see ops.alerts', al.blocking_criticals)
    WHEN COALESCE(health.position_drift_detected, TRUE) THEN
      'state.position_reconciliation drift detected'
    WHEN COALESCE(dd.drawdown_breach, FALSE) THEN
      FORMAT('book NAV drawdown %.2f%% from trailing peak exceeds the -15%% circuit-breaker threshold', dd.drawdown_from_peak * 100)
    ELSE NULL
  END AS halt_reason
FROM ctrl, health, al, dd

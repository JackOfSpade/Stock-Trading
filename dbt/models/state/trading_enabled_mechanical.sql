-- Parallel-run dbt port of state.trading_enabled_mechanical. CANONICAL SOURCE is
-- bigquery/176_decouple_embedding_health_from_trading_gate.sql (which SUPERSEDES 107's definition of
-- this object; 107 itself SUPERSEDES 97, 78, 34 and 33) until owner cutover; 2026-07-19: 97's
-- halt-echo missing_dependency exclusion (halt_echo_md) added; 2026-07-26: 107's halt-echo missed_run
-- exclusion (halt_echo_mr) added; 2026-08-17: 176 removed the embeddings_healthy term (owner decision
-- — see trading_enabled.sql's header for the full rationale; events.decision_log
-- f74c31be-9dbc-4af0-92b6-931d9ab21e3c). Keep all halt_reason strings in lockstep with 176 when
-- either side changes.
-- Added 2026-07-14 (audit finding, HIGH severity) as a port of bigquery/34 — this D2a-scoped
-- safety gate had ZERO dbt mirror despite its live sibling
-- state.trading_enabled having full coverage since 2026-07-04, so scripts/dbt_parity.py could never
-- catch drift on this gate. Deliberately excludes marks_fresh/engine_fresh (D2a's own same-run-
-- circular term — see bigquery/33_gate_ordering_fix.sql's header). ops.sp_assert_trading_enabled_
-- mechanical reads this before D2a's mechanical sweep/persist-and-wait re-craft step.
-- ORGANIZATION FIX (2026-08-31 code-quality pass, dbt#1/dbt#2): halt_echo_md/halt_echo_mr now come
-- from the shared dbt/macros/halt_echo.sql macro (was byte-identical copy-pasted CTE text here and in
-- trading_enabled.sql/b3_trading_enabled_check.sql — dbt#2), and the `al` CTE below now uses
-- source('ops','alerts') instead of a hardcoded `stock-trading-498512.ops.alerts` literal (already
-- declared in sources.yml but bypassed here — same class of gap dbt#1 found in trading_enabled.sql,
-- just not separately enumerated there). Purely a compiled-SQL-identical substitution.
WITH ctrl AS (
  SELECT ARRAY_AGG(STRUCT(halt_all, reason, mode) ORDER BY control_ts DESC LIMIT 1)[SAFE_OFFSET(0)] AS latest
  FROM {{ source('ops', 'trading_control') }}
),
health AS (
  SELECT position_drift_detected
  FROM {{ ref('system_health') }}
),
{{ halt_echo() }}
al AS (
  SELECT COUNTIF(NOT resolved AND severity = 'critical'
    AND category NOT IN ('trading_halted', 'staleness')
    AND alert_id NOT IN (SELECT alert_id FROM halt_echo_md)
    AND alert_id NOT IN (SELECT alert_id FROM halt_echo_mr)) AS blocking_criticals
  FROM {{ source('ops', 'alerts') }}
),
dd AS (SELECT breach_hard, drawdown_from_peak FROM {{ ref('book_drawdown_watch') }})
SELECT
  NOT COALESCE(ctrl.latest.halt_all, FALSE)
  AND al.blocking_criticals = 0
  AND NOT COALESCE(health.position_drift_detected, TRUE)
  AND NOT COALESCE(dd.breach_hard, FALSE) AS trading_enabled,
  CASE
    WHEN COALESCE(ctrl.latest.halt_all, FALSE) THEN
      FORMAT('halt_all (mode=%s): %s', COALESCE(ctrl.latest.mode, '?'), COALESCE(ctrl.latest.reason, 'no reason logged'))
    WHEN al.blocking_criticals != 0 THEN
      FORMAT('%d open critical alert(s) (excluding trading_halted/staleness/halt-echo dependency+missed_run gate echoes) — see ops.alerts', al.blocking_criticals)
    WHEN COALESCE(health.position_drift_detected, TRUE) THEN
      'state.position_reconciliation drift detected'
    WHEN COALESCE(dd.breach_hard, FALSE) THEN
      FORMAT('book NAV drawdown %.2f%% from flow-adjusted peak exceeds the -40%% CATASTROPHE circuit-breaker (full halt)', dd.drawdown_from_peak * 100)
    ELSE NULL
  END AS halt_reason
FROM ctrl, health, al, dd

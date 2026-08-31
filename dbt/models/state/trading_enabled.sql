-- Parallel-run dbt port of state.trading_enabled. CANONICAL SOURCE is
-- bigquery/176_decouple_embedding_health_from_trading_gate.sql (which SUPERSEDES 107's definition of
-- this object; 107 itself SUPERSEDES 97, 78, 47, 34 and 23) until owner cutover. Originally added
-- 2026-07-04 (audit finding, HIGH severity) as a port of 23_trading_control.sql; updated 2026-07-14
-- to 47, then to 78's two changes (drawdown AND-term is breach_hard, not the -15% soft tier;
-- blocking_criticals excludes category IN ('trading_halted','staleness')), then 2026-07-19 to 97's
-- halt-echo missing_dependency exclusion (halt_echo_md below), 2026-07-26 to 107's halt-echo
-- missed_run exclusion (halt_echo_mr below), and 2026-08-17 to 176's removal of the eh.is_healthy
-- term (owner decision: a derived retrieval index being momentarily behind an async embed must not
-- read as a capital-blocking halt — see events.decision_log f74c31be-9dbc-4af0-92b6-931d9ab21e3c).
-- The machine-readable gate: sp_assert_trading_enabled reads this before every order-staging step.
--
-- DRIFT FIX 2026-07-18: this port carried 78's LOGIC but had kept 47's older snapshot_stale halt_reason
-- WORDING. Both sides currently return halt_reason = NULL (snapshot_stale is FALSE), so row-level parity
-- passed — but the moment that branch fired, dbt_parity.py would have reported real drift and failed CI
-- on a purely cosmetic string. The message below is byte-identical to the canonical file's.
-- Keep all SIX halt_reason strings in lockstep with 176 when either side changes.
-- ORGANIZATION FIX (2026-08-31 code-quality pass, dbt#1/dbt#2): halt_echo_md/halt_echo_mr now come
-- from the shared dbt/macros/halt_echo.sql macro (was byte-identical copy-pasted CTE text here and in
-- trading_enabled_mechanical.sql/b3_trading_enabled_check.sql — dbt#2), and the `al`/`pr` CTEs below
-- now use source('ops','alerts') / ref('position_reconciliation') instead of hardcoded
-- `stock-trading-498512.ops.alerts` / `...state.position_reconciliation` literals — both already
-- declared (sources.yml / dbt/models/state/position_reconciliation.sql) but bypassed here, which kept
-- this model (and system_health/trading_enabled_mechanical, which read its data) OUT of
-- `dbt list --select state.position_reconciliation+`'s downstream set (dbt#1). Purely a
-- compiled-SQL-identical substitution — b3_trading_enabled_check.sql already does this for the same
-- tables with zero drift.
WITH ctrl AS (
  SELECT ARRAY_AGG(STRUCT(halt_all, reason, mode) ORDER BY control_ts DESC LIMIT 1)[SAFE_OFFSET(0)] AS latest
  FROM {{ source('ops', 'trading_control') }}
),
f AS (SELECT marks_fresh, engine_fresh FROM {{ ref('freshness') }}),
{{ halt_echo() }}
al AS (
  SELECT COUNTIF(NOT resolved AND severity = 'critical'
    AND category NOT IN ('trading_halted', 'staleness')
    AND alert_id NOT IN (SELECT alert_id FROM halt_echo_md)
    AND alert_id NOT IN (SELECT alert_id FROM halt_echo_mr)) AS blocking_criticals
  FROM {{ source('ops', 'alerts') }}
),
pr AS (SELECT COALESCE(LOGICAL_OR(drifted), FALSE) AS drift FROM {{ ref('position_reconciliation') }}),
dd AS (SELECT breach_hard, drawdown_from_peak, snapshot_stale FROM {{ ref('book_drawdown_watch') }})
SELECT
  NOT COALESCE(ctrl.latest.halt_all, FALSE)
  AND COALESCE(f.marks_fresh, FALSE)
  AND COALESCE(f.engine_fresh, FALSE)
  AND al.blocking_criticals = 0
  AND NOT pr.drift
  AND NOT COALESCE(dd.breach_hard, FALSE)
  AND NOT COALESCE(dd.snapshot_stale, FALSE) AS trading_enabled,
  CASE
    WHEN COALESCE(ctrl.latest.halt_all, FALSE) THEN
      FORMAT('halt_all (mode=%s): %s', COALESCE(ctrl.latest.mode, '?'), COALESCE(ctrl.latest.reason, 'no reason logged'))
    WHEN NOT COALESCE(f.marks_fresh, FALSE) OR NOT COALESCE(f.engine_fresh, FALSE) THEN
      'state.freshness marks_fresh/engine_fresh not both TRUE'
    WHEN al.blocking_criticals != 0 THEN
      FORMAT('%d open critical alert(s) (excluding trading_halted/staleness/halt-echo dependency+missed_run gate echoes) — see ops.alerts', al.blocking_criticals)
    WHEN pr.drift THEN
      'state.position_reconciliation drift detected'
    WHEN COALESCE(dd.breach_hard, FALSE) THEN
      FORMAT('book NAV drawdown %.2f%% from flow-adjusted peak exceeds the -40%% CATASTROPHE circuit-breaker (full halt); the -15%% soft tier pauses new entries only', dd.drawdown_from_peak * 100)
    WHEN COALESCE(dd.snapshot_stale, FALSE) THEN
      'state.book_drawdown_watch.snapshot_stale = TRUE (ops.account_snapshot not refreshed for the current trading day — the breaker cannot trust its own peak/current NAV comparison; ITEM 16, 2026-07-11)'
    ELSE NULL
  END AS halt_reason
FROM ctrl, f, al, pr, dd

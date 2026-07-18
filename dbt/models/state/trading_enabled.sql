-- Parallel-run dbt port of state.trading_enabled. CANONICAL SOURCE is
-- bigquery/78_book_drawdown_rebase_and_staleness_gate.sql (which SUPERSEDES 47, which superseded 34
-- and 23) until owner cutover — verified 2026-07-18 against the deployed view. Originally added
-- 2026-07-04 (audit finding, HIGH severity) as a port of 23_trading_control.sql; updated 2026-07-14
-- to 47, then to 78's two changes (drawdown AND-term is breach_hard, not the -15% soft tier;
-- blocking_criticals excludes category IN ('trading_halted','staleness')). The machine-readable gate:
-- sp_assert_trading_enabled reads this before every order-staging step.
--
-- DRIFT FIX 2026-07-18: this port carried 78's LOGIC but had kept 47's older snapshot_stale halt_reason
-- WORDING. Both sides currently return halt_reason = NULL (snapshot_stale is FALSE), so row-level parity
-- passed — but the moment that branch fired, dbt_parity.py would have reported real drift and failed CI
-- on a purely cosmetic string. The message below is now byte-identical to bigquery/78 and to the
-- deployed view. Keep all SEVEN halt_reason strings in lockstep with 78 when either side changes.
WITH ctrl AS (
  SELECT ARRAY_AGG(STRUCT(halt_all, reason, mode) ORDER BY control_ts DESC LIMIT 1)[SAFE_OFFSET(0)] AS latest
  FROM {{ source('ops', 'trading_control') }}
),
f AS (SELECT marks_fresh, engine_fresh FROM {{ ref('freshness') }}),
eh AS (SELECT is_healthy FROM {{ source('state_external', 'embedding_health') }}),
al AS (
  SELECT COUNTIF(NOT resolved AND severity = 'critical' AND category NOT IN ('trading_halted', 'staleness')) AS blocking_criticals
  FROM `stock-trading-498512.ops.alerts`
),
pr AS (SELECT COALESCE(LOGICAL_OR(drifted), FALSE) AS drift FROM `stock-trading-498512.state.position_reconciliation`),
dd AS (SELECT breach_hard, drawdown_from_peak, snapshot_stale FROM {{ ref('book_drawdown_watch') }})
SELECT
  NOT COALESCE(ctrl.latest.halt_all, FALSE)
  AND COALESCE(f.marks_fresh, FALSE)
  AND COALESCE(f.engine_fresh, FALSE)
  AND COALESCE(eh.is_healthy, FALSE)
  AND al.blocking_criticals = 0
  AND NOT pr.drift
  AND NOT COALESCE(dd.breach_hard, FALSE)
  AND NOT COALESCE(dd.snapshot_stale, FALSE) AS trading_enabled,
  CASE
    WHEN COALESCE(ctrl.latest.halt_all, FALSE) THEN
      FORMAT('halt_all (mode=%s): %s', COALESCE(ctrl.latest.mode, '?'), COALESCE(ctrl.latest.reason, 'no reason logged'))
    WHEN NOT COALESCE(f.marks_fresh, FALSE) OR NOT COALESCE(f.engine_fresh, FALSE) THEN
      'state.freshness marks_fresh/engine_fresh not both TRUE'
    WHEN NOT COALESCE(eh.is_healthy, FALSE) THEN
      'state.embedding_health.is_healthy = FALSE'
    WHEN al.blocking_criticals != 0 THEN
      FORMAT('%d open critical alert(s) (excluding trading_halted/staleness gate echoes) — see ops.alerts', al.blocking_criticals)
    WHEN pr.drift THEN
      'state.position_reconciliation drift detected'
    WHEN COALESCE(dd.breach_hard, FALSE) THEN
      FORMAT('book NAV drawdown %.2f%% from flow-adjusted peak exceeds the -40%% CATASTROPHE circuit-breaker (full halt); the -15%% soft tier pauses new entries only', dd.drawdown_from_peak * 100)
    WHEN COALESCE(dd.snapshot_stale, FALSE) THEN
      'state.book_drawdown_watch.snapshot_stale = TRUE (ops.account_snapshot not refreshed for the current trading day — the breaker cannot trust its own peak/current NAV comparison; ITEM 16, 2026-07-11)'
    ELSE NULL
  END AS halt_reason
FROM ctrl, f, eh, al, pr, dd

-- ======================= SUPERSEDED — DO NOT APPLY THIS FILE =======================
-- This file's `CREATE OR REPLACE VIEW state.trading_enabled` is NO LONGER CANONICAL.
-- bigquery/78_book_drawdown_rebase_and_staleness_gate.sql SUPERSEDED it (2026-07-17; confirmed
-- against the deployed view 2026-07-18: live matched 78, not this file), 78 was in turn
-- superseded by bigquery/97_halt_echo_dependency_gate.sql (2026-07-19), 97 was in turn
-- superseded by bigquery/107_halt_echo_missed_run_gate.sql (2026-07-26), and 107 was in turn
-- superseded LIVE (2026-08-17) by bigquery/176_decouple_embedding_health_from_trading_gate.sql — 176
-- is the current single source of truth for this gate (78/97/107 are themselves superseded).
--
-- Re-applying THIS file would REGRESS the live gate on BOTH of 78's changes (and on 97's
-- halt-echo missing_dependency exclusion, and on 107's halt-echo missed_run exclusion):
--   * the drawdown AND-term would revert from `breach_hard` (the -40% CATASTROPHE tier) to
--     `drawdown_breach` (the -15% soft tier) — hard-halting ALL trading on a soft-tier drawdown that
--     is only supposed to pause new entries; and
--   * blocking_criticals would revert from `category NOT IN ('trading_halted','staleness')` to
--     `category != 'trading_halted'` — letting a staleness gate-echo latch the gate closed.
-- That is precisely the apply-an-older-file-in-isolation accident this very file was written to fix
-- (see ROOT CAUSE below) — the same rake, one link further down the chain.
--
-- Marker added 2026-07-18, after this header was found still asserting "THIS FILE is the new single
-- source of truth" long after 78 landed — the misleading claim, not the SQL, was the hazard. The DDL
-- below is deliberately left UNMODIFIED as the historical record of the 2026-07-14 resync.
-- ===================================================================================
--
-- ITEM: live-vs-repo drift fix (2026-07-14 self-improvement audit, finding P0/sql-mid#1).
--
-- ROOT CAUSE: bigquery/34_alert_lifecycle.sql redefined state.trading_enabled to exclude the
-- gate's own `trading_halted` alert from its blocking-critical count (so a transient trip's alert
-- can't latch the gate closed forever after the root cause heals). On 2026-07-11, commit e82cc96
-- edited bigquery/23_trading_control.sql IN PLACE to add the ITEM 16 `snapshot_stale` AND-term and
-- re-applied 23's CREATE OR REPLACE VIEW for state.trading_enabled live, in isolation -- silently
-- clobbering 34's trading_halted exclusion for this one view (state.trading_enabled_mechanical,
-- defined only in 33/34, was untouched and still carries the fix -- that asymmetry is what exposed
-- the regression). Confirmed live via INFORMATION_SCHEMA.VIEWS before this file was applied: the
-- deployed view lacked `category != 'trading_halted'` entirely.
--
-- THIS FILE WAS the single source of truth for state.trading_enabled AS OF 2026-07-14 (it is NOT any
-- longer — bigquery/78 superseded it 2026-07-17, bigquery/97 superseded 78 on 2026-07-19, and
-- bigquery/107 superseded 97 on 2026-07-26; see the SUPERSEDED banner at the top), merging:
--   * 34's trading_halted exclusion (al AS ... category != 'trading_halted')
--   * 23's 2026-07-11 ITEM 16 snapshot_stale AND-term (dd AS ... snapshot_stale)
-- Supersedes the trading_enabled definitions in both 23 (as edited 2026-07-11) and 34.
--
-- DO NOT ever re-apply 23's or 34's CREATE OR REPLACE VIEW state.trading_enabled statement in
-- isolation again -- that is the exact operator action that caused this regression. Any future
-- change to this gate's composition must land as a new numbered file that supersedes this one.
--
-- Apply after 23_trading_control.sql, 34_alert_lifecycle.sql, 46_weekly_benchmarks.sql.
CREATE OR REPLACE VIEW `stock-trading-498512.state.trading_enabled` AS
WITH ctrl AS (
  SELECT ARRAY_AGG(STRUCT(halt_all, reason, mode) ORDER BY control_ts DESC LIMIT 1)[SAFE_OFFSET(0)] AS latest
  FROM `stock-trading-498512.ops.trading_control`
),
f AS (SELECT marks_fresh, engine_fresh FROM `stock-trading-498512.state.freshness`),
eh AS (SELECT is_healthy FROM `stock-trading-498512.state.embedding_health`),
al AS (
  SELECT COUNTIF(NOT resolved AND severity = 'critical' AND category != 'trading_halted') AS blocking_criticals
  FROM `stock-trading-498512.ops.alerts`
),
pr AS (SELECT COALESCE(LOGICAL_OR(drifted), FALSE) AS drift FROM `stock-trading-498512.state.position_reconciliation`),
dd AS (SELECT drawdown_breach, drawdown_from_peak, snapshot_stale FROM `stock-trading-498512.state.book_drawdown_watch`)
SELECT
  NOT COALESCE(ctrl.latest.halt_all, FALSE)
  AND COALESCE(f.marks_fresh, FALSE)
  AND COALESCE(f.engine_fresh, FALSE)
  AND COALESCE(eh.is_healthy, FALSE)
  AND al.blocking_criticals = 0
  AND NOT pr.drift
  AND NOT COALESCE(dd.drawdown_breach, FALSE)
  AND NOT COALESCE(dd.snapshot_stale, FALSE) AS trading_enabled,
  CASE
    WHEN COALESCE(ctrl.latest.halt_all, FALSE) THEN
      FORMAT('halt_all (mode=%s): %s', COALESCE(ctrl.latest.mode, '?'), COALESCE(ctrl.latest.reason, 'no reason logged'))
    WHEN NOT COALESCE(f.marks_fresh, FALSE) OR NOT COALESCE(f.engine_fresh, FALSE) THEN
      'state.freshness marks_fresh/engine_fresh not both TRUE'
    WHEN NOT COALESCE(eh.is_healthy, FALSE) THEN
      'state.embedding_health.is_healthy = FALSE'
    WHEN al.blocking_criticals != 0 THEN
      FORMAT('%d open critical alert(s) (excluding the trading_halted gate echo) — see ops.alerts', al.blocking_criticals)
    WHEN pr.drift THEN
      'state.position_reconciliation drift detected'
    WHEN COALESCE(dd.drawdown_breach, FALSE) THEN
      FORMAT('book NAV drawdown %.2f%% from trailing peak exceeds the -15%% circuit-breaker threshold', dd.drawdown_from_peak * 100)
    WHEN COALESCE(dd.snapshot_stale, FALSE) THEN
      'state.book_drawdown_watch.snapshot_stale = TRUE (ops.account_snapshot has not been refreshed for the current trading day -- the book-level drawdown breaker cannot trust its own peak/current NAV comparison; ITEM 16, 2026-07-11)'
    ELSE NULL
  END AS halt_reason
FROM ctrl, f, eh, al, pr, dd;

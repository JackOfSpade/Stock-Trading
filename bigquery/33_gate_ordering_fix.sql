-- D2a trading-enable GATE-ORDERING fix (2026-07-07 — self-diagnosed by D2a, ops.alerts
-- 48ca83df-08d2-4e57-a04c-5d67f9f7bc17, warning/gate_ordering). Project: stock-trading-498512.
-- Apply after 23_trading_control.sql.
--
-- THE BUG. `ops.sp_assert_trading_enabled` (23_trading_control.sql) is documented to run "before
-- anything else" at the start of D2a/D2's Step 0 — but `state.trading_enabled` folds in
-- `state.system_health.all_green`, which requires `marks_fresh`/`engine_fresh` (today's
-- events.daily_marks / perf.strategy_daily). D2a is the routine that PRODUCES that freshness each
-- trading morning (its own PER-STRATEGY PERFORMANCE MAINTENANCE step, which runs AFTER Step 0/0b) —
-- so calling the freshness-inclusive gate before that ingest sees today's marks as correctly-stale
-- (they aren't ingested yet) and RAISEs. The RAISE hard-aborts the ENTIRE routine (BigQuery script
-- semantics), so reconciliation/snapshot/ingest never run either, contradicting the gate's own
-- documented intent ("reads/reconciliation are safe regardless"). Worse, the RAISE's own critical
-- `trading_halted` alert then keeps `state.system_health.open_critical_alerts > 0` — and critical
-- alerts are deliberately NOT auto-resolved (bigquery/scheduled_queries/cadence_check.sql #14 ages out
-- only WARNING self-healing classes, on purpose, so a real halt always gets human review before
-- clearing — same asymmetric-clearing discipline as ops.trading_control's halt_all). So a same-day
-- freshness transient that would otherwise clear itself within the very same run instead becomes a
-- standing lock on trading_enabled until a human runs `UPDATE ops.alerts SET resolved=TRUE`.
--
-- THE FIX. D2a's own actions (fill reconciliation, the cash/SGOV tripwire, the mechanical SGOV
-- sweep/cover, the persist-and-wait staged-order re-craft) price off LIVE connector quotes
-- (get_price_snapshot / IBKR), never off events.daily_marks / perf.strategy_daily — the tables
-- marks_fresh/engine_fresh measure. Gating them on SAME-DAY marks/engine freshness was never actually
-- protecting anything; it only recreated the chicken-and-egg deadlock above. This file adds a
-- D2a-scoped gate that keeps every OTHER real stop signal (a manual/auto halt_all, the book-level NAV
-- drawdown breach, unhealthy embeddings, any open critical alert, position-reconciliation drift) but
-- excludes marks_fresh/engine_fresh — mirroring `state.system_health.all_green`'s actual formula minus
-- that one same-run-circular term.
--
-- D2/W4/M4/Q4/A1/A3 are UNCHANGED — still call the original `ops.sp_assert_trading_enabled` (the
-- freshness-inclusive gate) unmodified, because they size DISCRETIONARY entries/exits off
-- analytics.strategy_nav (engine-derived), where same-day freshness is a real precondition — and by
-- the time they run, D2a (now able to actually complete) has already ingested it. D2's OWN duplicate
-- Step 0 (pre-cutover only; deleted once D2a's autonomous cutover fires, Claude_Task_Plan.md "## D2a."
-- banner) is deliberately left calling the original procedure too: it is temporary/soon-removed code,
-- and it runs after D2a in the daily order, so the same-run circularity does not arise for it in
-- practice.
--
-- Only D2a's own call site changes (Claude_Task_Plan.md "## D2a." TRADING-ENABLE GATE line): it now
-- calls `ops.sp_assert_trading_enabled_mechanical('D2a')` instead of `ops.sp_assert_trading_enabled('D2a')`.

-- ===== state.trading_enabled_mechanical — D2a-scoped gate (excludes marks_fresh/engine_fresh) =====
-- SUPERSEDED LIVE — first by bigquery/34_alert_lifecycle.sql (trading_halted exclusion), then by
-- bigquery/78_book_drawdown_rebase_and_staleness_gate.sql (2026-07-17, verified against the
-- deployed view 2026-07-18), then by bigquery/97_halt_echo_dependency_gate.sql (2026-07-19), then
-- by bigquery/107_halt_echo_missed_run_gate.sql (2026-07-26), which is the CURRENT single source
-- of truth for this view (78/97 are themselves superseded). Kept here, unmodified, for DR-rebuild
-- apply-in-order reference only. DO NOT re-apply this CREATE OR REPLACE VIEW statement live in
-- isolation: it would revert 78's two changes — the drawdown AND-term back from `breach_hard`
-- (-40% catastrophe) to the -15% soft tier, and blocking_criticals back to counting
-- 'trading_halted'/'staleness' gate-echoes — plus 97's halt-echo missing_dependency exclusion and
-- 107's halt-echo missed_run exclusion, re-latching the gate. That in-isolation re-apply is the
-- exact accident documented in bigquery/47's ROOT CAUSE.
-- Marker added 2026-07-18; chain extended to 97 on 2026-07-19, to 107 on 2026-07-26.
CREATE OR REPLACE VIEW `stock-trading-498512.state.trading_enabled_mechanical` AS
WITH ctrl AS (
  SELECT ARRAY_AGG(STRUCT(halt_all, reason, mode) ORDER BY control_ts DESC LIMIT 1)[SAFE_OFFSET(0)] AS latest
  FROM `stock-trading-498512.ops.trading_control`
),
health AS (
  SELECT embeddings_healthy, open_critical_alerts, position_drift_detected
  FROM `stock-trading-498512.state.system_health`
),
dd AS (SELECT drawdown_breach, drawdown_from_peak FROM `stock-trading-498512.state.book_drawdown_watch`)
SELECT
  NOT COALESCE(ctrl.latest.halt_all, FALSE)
  AND COALESCE(health.embeddings_healthy, FALSE)
  AND COALESCE(health.open_critical_alerts, 1) = 0
  AND NOT COALESCE(health.position_drift_detected, TRUE)
  AND NOT COALESCE(dd.drawdown_breach, FALSE) AS trading_enabled,
  CASE
    WHEN COALESCE(ctrl.latest.halt_all, FALSE) THEN
      FORMAT('halt_all (mode=%s): %s', COALESCE(ctrl.latest.mode, '?'), COALESCE(ctrl.latest.reason, 'no reason logged'))
    WHEN NOT COALESCE(health.embeddings_healthy, FALSE) THEN
      'state.system_health.embeddings_healthy = FALSE'
    WHEN COALESCE(health.open_critical_alerts, 1) != 0 THEN
      FORMAT('%d open critical alert(s) — see ops.alerts', health.open_critical_alerts)
    WHEN COALESCE(health.position_drift_detected, TRUE) THEN
      'state.position_reconciliation drift detected'
    WHEN COALESCE(dd.drawdown_breach, FALSE) THEN
      FORMAT('book NAV drawdown %.2f%% from trailing peak exceeds the -15%% circuit-breaker threshold', dd.drawdown_from_peak * 100)
    ELSE NULL
  END AS halt_reason
FROM ctrl, health, dd;

-- ===== ops.sp_assert_trading_enabled_mechanical — FATAL pre-stage gate for D2a's mechanical-only
-- actions (sweep/cover + persist-and-wait re-craft). Same shape/behavior as
-- ops.sp_assert_trading_enabled, reading the mechanical view above instead. =====
-- SUPERSEDED BY bigquery/85_gate_selfheal_repo_catchup.sql (2026-07-18) — same reason and same
-- direction as the banner on ops.sp_assert_trading_enabled in bigquery/23: 85 adds the 2026-07-17
-- stale-echo self-heal resolver that went live but was never written back to the repo. This procedure
-- is the one whose ROOT INCIDENT the resolver fixed (D2a halted trading for a whole day on an
-- already-healed `staleness` critical). Kept unmodified for apply-in-order reference only; DO NOT
-- re-apply in isolation — that reverts the resolver.
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_assert_trading_enabled_mechanical`(in_routine STRING)
BEGIN
  DECLARE v_enabled BOOL;
  DECLARE v_reason STRING;
  SET (v_enabled, v_reason) = (
    SELECT AS STRUCT trading_enabled, halt_reason FROM `stock-trading-498512.state.trading_enabled_mechanical`
  );
  IF NOT v_enabled THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', in_routine, 'trading_halted',
      'Order staging blocked: trading is HALTED. See payload for the triggering routine and reason.',
      TO_JSON_STRING(STRUCT(in_routine AS routine, v_reason AS halt_reason)));
    RAISE USING MESSAGE = FORMAT(
      '%s: trading_enabled_mechanical=FALSE (%s) — order staging aborted. Investigate state.trading_enabled_mechanical / state.trading_control_latest before retrying.',
      in_routine, COALESCE(v_reason, 'unspecified'));
  END IF;
END;

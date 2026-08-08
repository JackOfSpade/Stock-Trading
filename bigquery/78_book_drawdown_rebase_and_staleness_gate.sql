-- Book-drawdown breaker rebase + staleness-echo gate exclusion (2026-07-17 whole-system deep audit,
-- findings C1 [risk-rails, CRITICAL] and the staleness-echo deadlock [risk-rails, HIGH]).
-- Project: stock-trading-498512. Apply AFTER 23_trading_control.sql, 34_alert_lifecycle.sql,
-- 47_trading_enabled_resync.sql, 64_b3_live_invariants.sql, 76_owner_confirmation_liveness.sql.
-- This file WAS the new single source of truth for state.book_drawdown_watch, state.trading_enabled,
-- state.trading_enabled_mechanical, state.b3_trading_enabled_check and ops.sp_auto_resolve_alerts;
-- it SUPERSEDES those definitions in 23/33/34/47/64. It REMAINS canonical ONLY for
-- state.book_drawdown_watch and state.entry_staging_allowed: sp_auto_resolve_alerts was superseded
-- by bigquery/94, and the three gate views AND 94's procedure are in turn superseded by
-- bigquery/97_halt_echo_dependency_gate.sql (2026-07-19) — see the per-statement markers below.
-- Per 47's header rule, any future change to this gate cluster must land as a new numbered file
-- that supersedes THIS one — never re-apply an earlier file's CREATE OR REPLACE for these objects
-- in isolation.
--
-- ============================ WHY (C1 — the drawdown breaker) ============================
-- state.book_drawdown_watch's -15% breach was a no-override AND-term in BOTH trading gates. In the
-- SGOV parking era (NAV ~97% SGOV, ~0 vol) it could only trip on a catastrophe or data corruption.
-- The 2026-07-15 SGOV->VOO park cutover (bigquery/54-56) moved ~97% of NAV into VOO equity WITHOUT
-- re-reviewing this breaker, so the same -15% rail now trips on an ORDINARY correction (VOO fell
-- >15% peak-to-trough in 2018/2020/2022). Because the breach fed the gates and D2a FATAL-aborts
-- before exit sweeps / kill-trigger terminations / park cover, an ordinary bear market would have
-- FROZEN THE ENTIRE PIPELINE INCLUDING GETTING OUT — directly contradicting bigquery/76's stated
-- principle ("a halt is a reason to stop ADDING ... never a reason to stop trying to get OUT") and
-- AI_Trading_Foundation 3b.3 (kill triggers must execute under loss pressure).
--
-- TWO-TIER REBASE (per the audit's value-lens: re-scoping the -15% breach to entries-only + a raw
-- catastrophe tier "would suffice" — the park-beta refinement is deferred as a documented future
-- option, see Experiment_Parameters.md):
--   * breach_soft  (drawdown <= -15%): feeds state.entry_staging_allowed (below) — pauses NEW-entry
--     staging ONLY, exactly like 76's entries_halted. Exit re-craft, per-strategy drawdown-kill
--     terminations, and park cover are UNAFFECTED. Conservative and non-damaging: a -15% book
--     drawdown is a fine reason to stop deploying new capital, never a reason to freeze exits.
--   * breach_hard  (drawdown <= -40%): the genuine-catastrophe tier — still a hard AND-term in both
--     gates (full-halt semantics preserved for a true book collapse / data corruption).
--
-- FLOW-ADJUSTED PEAK (fixes C1's secondary defect: raw MAX(nav) let a deposit permanently ratchet
-- the peak and a >=15% withdrawal manufacture a phantom breach). We neutralise external flows by
-- measuring drawdown on flow-neutral trading gain rather than raw NAV:
--     cum_flows(t)  = SUM(events.cash_flows.amount WHERE flow_date <= snapshot_date)  [deposits +]
--     gain(t)       = nav(t) - cum_flows(t)                 -- cumulative trading P&L, flow-neutral
--     peak_gain(t)  = MAX(gain) over snapshots <= t         -- high-water trading P&L
--     drawdown      = (gain - peak_gain) / cum_flows        -- % of deposited capital
-- A deposit raises nav and cum_flows equally -> gain unchanged -> no ratchet; a withdrawal lowers
-- both equally -> gain unchanged -> no phantom breach. When flows are constant this reproduces the
-- old raw-NAV drawdown to within rounding (verified live 2026-07-17: -0.63% either way), so applying
-- this file is behaviourally inert on apply day (breach_soft=breach_hard=FALSE), not a silent change.
--
-- ============================ WHY (the staleness-echo gate exclusion) ============================
-- The scheduled freshness check raises category='staleness' whenever state.system_health is not
-- green at 05:00 UTC. all_green includes open_critical_alerts=0, so ANY open critical spawns a
-- staleness alert carrying no new information (alert-on-alert echo). Both gates counted 'staleness'
-- as a blocking critical (only 'trading_halted' was excluded), so a staleness echo of a since-healed
-- overnight transient kept the gates FALSE all day, and D2a then hit a FATAL gate whose clear
-- condition (marks_fresh) needs the very marks D2a would ingest — a circular deadlock resolvable
-- only by a manual owner UPDATE (observed 2026-07-14, and again 2026-07-17). The staleness alert is
-- definitionally an ECHO of components each gate already reads directly (marks_fresh/engine_fresh/
-- embeddings/position-drift/other-criticals), so excluding it from the gates removes ZERO real
-- protection while breaking the circularity — identical reasoning to 34's existing trading_halted
-- exclusion. Both gates below now exclude category IN ('trading_halted','staleness').

-- SUPERSEDED LIVE by bigquery/153_account_snapshot_gap_watch.sql — current single source of truth for
-- state.book_drawdown_watch. 153 reproduces this exact view body, byte-for-byte, and adds ONE new
-- column, peak_window_gap_days INT64 (a COUNT of state.account_snapshot_gap — trading days between the
-- first and last ops.account_snapshot row that D2a never wrote, so the flow-adjusted peak_gain running
-- max above cannot have seen them). Observability only: no existing column, threshold, or semantic
-- changes, and state.trading_enabled's read of breach_hard/breach_soft/snapshot_stale is unaffected.
-- Kept here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT re-apply this CREATE OR
-- REPLACE VIEW statement live in isolation.
--
-- ===== state.book_drawdown_watch — flow-adjusted, two-tier (SUPERSEDES bigquery/23) =====
CREATE OR REPLACE VIEW `stock-trading-498512.state.book_drawdown_watch` AS
WITH snaps AS (
  SELECT snapshot_date, nav
  FROM `stock-trading-498512.ops.account_snapshot`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY snapshot_date ORDER BY ingest_ts DESC) = 1
),
flowed AS (
  SELECT
    s.snapshot_date,
    s.nav,
    -- cumulative net external flows (deposits +, withdrawals -) up to and including this snapshot.
    COALESCE((
      SELECT SUM(cf.amount)
      FROM `stock-trading-498512.events.cash_flows` cf
      WHERE cf.flow_date <= s.snapshot_date
    ), 0) AS cum_flows
  FROM snaps s
),
gained AS (
  SELECT
    snapshot_date, nav, cum_flows,
    nav - cum_flows AS gain,
    MAX(nav - cum_flows) OVER (ORDER BY snapshot_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS peak_gain
  FROM flowed
),
agg AS (
  SELECT COUNT(*) AS n_snapshots,
    ARRAY_AGG(STRUCT(snapshot_date, nav, cum_flows, gain, peak_gain) ORDER BY snapshot_date DESC LIMIT 1)[SAFE_OFFSET(0)] AS latest
  FROM gained
),
ltd AS (SELECT last_trading_day FROM `stock-trading-498512.state.trading_day_today`)
SELECT
  agg.latest.snapshot_date AS as_of_date,
  agg.latest.nav AS current_nav,
  -- flow-adjusted peak, expressed in today's capital terms (peak trading-gain + current deposited
  -- capital) so dashboards keep a NAV-scale "peak" number; equals raw MAX(nav) when flows are constant.
  agg.latest.peak_gain + agg.latest.cum_flows AS peak_nav,
  agg.latest.cum_flows AS capital_base,
  SAFE_DIVIDE(agg.latest.gain - agg.latest.peak_gain, NULLIF(agg.latest.cum_flows, 0)) AS drawdown_from_peak,
  agg.n_snapshots,
  (agg.n_snapshots > 0 AND agg.latest.snapshot_date < ltd.last_trading_day) AS snapshot_stale,
  -- soft tier (-15%): entries-only, via state.entry_staging_allowed. NOT a gate term.
  (agg.n_snapshots >= 5 AND SAFE_DIVIDE(agg.latest.gain - agg.latest.peak_gain, NULLIF(agg.latest.cum_flows, 0)) <= -0.15) AS breach_soft,
  -- hard tier (-40%): genuine catastrophe — the gate AND-term (full halt).
  (agg.n_snapshots >= 5 AND SAFE_DIVIDE(agg.latest.gain - agg.latest.peak_gain, NULLIF(agg.latest.cum_flows, 0)) <= -0.40) AS breach_hard,
  -- backward-compat alias for pre-78 consumers (23/33/34/64 DR-apply-order copies): drawdown_breach
  -- now means the HARD tier (the term that still hard-halts the gates). New code should read breach_hard.
  (agg.n_snapshots >= 5 AND SAFE_DIVIDE(agg.latest.gain - agg.latest.peak_gain, NULLIF(agg.latest.cum_flows, 0)) <= -0.40) AS drawdown_breach
FROM agg CROSS JOIN ltd;

-- ===== state.entry_staging_allowed — consolidated NEW-ENTRY staging gate (NEW) =====
-- Single view D2's "NEW ENTRY CANDIDATES" section reads. entries_allowed=FALSE pauses NEW-entry
-- staging ONLY (never exits/kills/park-cover), consolidating the two entries-only signals:
--   * the book soft-drawdown breach (breach_soft, this file), and
--   * the owner-confirmation absence gate (state.owner_confirmation_liveness.entries_halted, 76).
-- Fail-safe: any NULL underlying reads as blocked. Auto-clears when both underlying signals clear.
CREATE OR REPLACE VIEW `stock-trading-498512.state.entry_staging_allowed` AS
WITH bdw AS (SELECT breach_soft, drawdown_from_peak FROM `stock-trading-498512.state.book_drawdown_watch`),
ocl AS (SELECT entries_halted, trading_days_since_last_fill, n_pending_instructions FROM `stock-trading-498512.state.owner_confirmation_liveness`)
SELECT
  (NOT COALESCE(bdw.breach_soft, TRUE) AND NOT COALESCE(ocl.entries_halted, TRUE)) AS entries_allowed,
  COALESCE(bdw.breach_soft, FALSE) AS book_drawdown_soft_breach,
  COALESCE(ocl.entries_halted, FALSE) AS owner_confirmation_entries_halted,
  CASE
    WHEN COALESCE(bdw.breach_soft, TRUE) THEN
      FORMAT('book_drawdown_soft_breach: NAV %.2f%% below flow-adjusted peak exceeds the -15%% soft threshold — NEW-entry staging paused; exits / kill-trigger terminations / park cover UNAFFECTED', bdw.drawdown_from_peak * 100)
    WHEN COALESCE(ocl.entries_halted, TRUE) THEN
      FORMAT('owner_confirmation_stale: %d pending instruction(s), %d trading day(s) since last fill — NEW-entry staging paused (76)', ocl.n_pending_instructions, ocl.trading_days_since_last_fill)
    ELSE NULL
  END AS block_reason
FROM bdw, ocl;

-- ===== state.trading_enabled — REDEFINED (SUPERSEDES bigquery/47) =====
-- Changes vs 47: (1) drawdown AND-term is now breach_hard (-40% catastrophe) not the -15% soft tier;
-- (2) blocking_criticals excludes category IN ('trading_halted','staleness') (was trading_halted only).
--
-- SUPERSEDED (2026-07-26): this definition of state.trading_enabled is now superseded by
-- bigquery/107_halt_echo_missed_run_gate.sql (97 in turn superseded — both are themselves
-- superseded), which reproduces this exact body and additionally excludes halt-echo
-- missing_dependency AND halt-echo missed_run alerts (pure fallout of a still-open trading halt)
-- from blocking_criticals. Re-applying the CREATE OR REPLACE VIEW below live in isolation would
-- REGRESS both halt-echo exclusions (re-arming the 2026-07-19 W5-on-halted-W4 deadlock AND the
-- 2026-07-25/26 D2/D3 missed_run deadlock). Kept here, unmodified, for DR-rebuild apply-in-order
-- reference only. DO NOT re-apply this CREATE OR REPLACE VIEW statement live in isolation.
CREATE OR REPLACE VIEW `stock-trading-498512.state.trading_enabled` AS
WITH ctrl AS (
  SELECT ARRAY_AGG(STRUCT(halt_all, reason, mode) ORDER BY control_ts DESC LIMIT 1)[SAFE_OFFSET(0)] AS latest
  FROM `stock-trading-498512.ops.trading_control`
),
f AS (SELECT marks_fresh, engine_fresh FROM `stock-trading-498512.state.freshness`),
eh AS (SELECT is_healthy FROM `stock-trading-498512.state.embedding_health`),
al AS (
  SELECT COUNTIF(NOT resolved AND severity = 'critical' AND category NOT IN ('trading_halted', 'staleness')) AS blocking_criticals
  FROM `stock-trading-498512.ops.alerts`
),
pr AS (SELECT COALESCE(LOGICAL_OR(drifted), FALSE) AS drift FROM `stock-trading-498512.state.position_reconciliation`),
dd AS (SELECT breach_hard, drawdown_from_peak, snapshot_stale FROM `stock-trading-498512.state.book_drawdown_watch`)
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
FROM ctrl, f, eh, al, pr, dd;

-- ===== state.trading_enabled_mechanical — REDEFINED (SUPERSEDES bigquery/34) =====
-- Same two changes as state.trading_enabled (breach_hard; exclude trading_halted+staleness). Still
-- deliberately excludes marks_fresh/engine_fresh (D2a's own same-run-circular term, per 33's header).
--
-- SUPERSEDED (2026-07-26): this definition of state.trading_enabled_mechanical is now superseded by
-- bigquery/107_halt_echo_missed_run_gate.sql (97 in turn superseded — both are themselves
-- superseded), which reproduces this exact body and additionally excludes halt-echo
-- missing_dependency AND halt-echo missed_run alerts (pure fallout of a still-open trading halt)
-- from blocking_criticals. Re-applying the CREATE OR REPLACE VIEW below live in isolation would
-- REGRESS both halt-echo exclusions. Kept here, unmodified, for DR-rebuild apply-in-order
-- reference only. DO NOT re-apply this CREATE OR REPLACE VIEW statement live in isolation.
CREATE OR REPLACE VIEW `stock-trading-498512.state.trading_enabled_mechanical` AS
WITH ctrl AS (
  SELECT ARRAY_AGG(STRUCT(halt_all, reason, mode) ORDER BY control_ts DESC LIMIT 1)[SAFE_OFFSET(0)] AS latest
  FROM `stock-trading-498512.ops.trading_control`
),
health AS (
  SELECT embeddings_healthy, position_drift_detected
  FROM `stock-trading-498512.state.system_health`
),
al AS (
  SELECT COUNTIF(NOT resolved AND severity = 'critical' AND category NOT IN ('trading_halted', 'staleness')) AS blocking_criticals
  FROM `stock-trading-498512.ops.alerts`
),
dd AS (SELECT breach_hard, drawdown_from_peak FROM `stock-trading-498512.state.book_drawdown_watch`)
SELECT
  NOT COALESCE(ctrl.latest.halt_all, FALSE)
  AND COALESCE(health.embeddings_healthy, FALSE)
  AND al.blocking_criticals = 0
  AND NOT COALESCE(health.position_drift_detected, TRUE)
  AND NOT COALESCE(dd.breach_hard, FALSE) AS trading_enabled,
  CASE
    WHEN COALESCE(ctrl.latest.halt_all, FALSE) THEN
      FORMAT('halt_all (mode=%s): %s', COALESCE(ctrl.latest.mode, '?'), COALESCE(ctrl.latest.reason, 'no reason logged'))
    WHEN NOT COALESCE(health.embeddings_healthy, FALSE) THEN
      'state.system_health.embeddings_healthy = FALSE'
    WHEN al.blocking_criticals != 0 THEN
      FORMAT('%d open critical alert(s) (excluding trading_halted/staleness gate echoes) — see ops.alerts', al.blocking_criticals)
    WHEN COALESCE(health.position_drift_detected, TRUE) THEN
      'state.position_reconciliation drift detected'
    WHEN COALESCE(dd.breach_hard, FALSE) THEN
      FORMAT('book NAV drawdown %.2f%% from flow-adjusted peak exceeds the -40%% CATASTROPHE circuit-breaker (full halt)', dd.drawdown_from_peak * 100)
    ELSE NULL
  END AS halt_reason
FROM ctrl, health, al, dd;

-- ===== state.b3_trading_enabled_check — REDEFINED (SUPERSEDES bigquery/64) =====
-- The live formula self-check must track the gate it mirrors, or it false-fires drift. Updated to the
-- new blocking-criticals exclusion (trading_halted+staleness) and breach_hard drawdown term.
--
-- SUPERSEDED (2026-07-26): this definition of state.b3_trading_enabled_check is now superseded by
-- bigquery/107_halt_echo_missed_run_gate.sql (97 in turn superseded — both are themselves
-- superseded), which reproduces this exact body and additionally carries the halt-echo
-- missing_dependency AND halt-echo missed_run exclusions in its blocking-criticals recomputation.
-- Re-applying the CREATE OR REPLACE VIEW below live in isolation would REGRESS both halt-echo
-- exclusions and false-fire drift against the 107-based state.trading_enabled. Kept here,
-- unmodified, for DR-rebuild apply-in-order reference only. DO NOT re-apply this CREATE OR REPLACE
-- VIEW statement live in isolation.
CREATE OR REPLACE VIEW `stock-trading-498512.state.b3_trading_enabled_check` AS
WITH ctrl AS (
  SELECT ARRAY_AGG(STRUCT(halt_all) ORDER BY control_ts DESC LIMIT 1)[SAFE_OFFSET(0)] AS latest
  FROM `stock-trading-498512.ops.trading_control`
),
f AS (SELECT marks_fresh, engine_fresh FROM `stock-trading-498512.state.freshness`),
eh AS (SELECT is_healthy FROM `stock-trading-498512.state.embedding_health`),
al AS (
  SELECT COUNTIF(NOT resolved AND severity = 'critical' AND category NOT IN ('trading_halted', 'staleness')) AS blocking_criticals
  FROM `stock-trading-498512.ops.alerts`
),
pr AS (SELECT COALESCE(LOGICAL_OR(drifted), FALSE) AS drift FROM `stock-trading-498512.state.position_reconciliation`),
dd AS (SELECT breach_hard, snapshot_stale FROM `stock-trading-498512.state.book_drawdown_watch`),
expected AS (
  SELECT
    NOT COALESCE(ctrl.latest.halt_all, FALSE)
    AND COALESCE(f.marks_fresh, FALSE)
    AND COALESCE(f.engine_fresh, FALSE)
    AND COALESCE(eh.is_healthy, FALSE)
    AND al.blocking_criticals = 0
    AND NOT pr.drift
    AND NOT COALESCE(dd.breach_hard, FALSE)
    AND NOT COALESCE(dd.snapshot_stale, FALSE) AS v
  FROM ctrl, f, eh, al, pr, dd
)
SELECT
  t.trading_enabled AS live_value,
  e.v AS expected_value,
  (t.trading_enabled IS DISTINCT FROM e.v) AS drift,
  CURRENT_TIMESTAMP() AS checked_at
FROM `stock-trading-498512.state.trading_enabled` t, expected e;

-- ===== ops.sp_auto_resolve_alerts — Rule 4 made payload-aware (SUPERSEDES bigquery/34) =====
-- Rules 1-3 are byte-identical to 34. Rule 4 (staleness) gains an ECHO branch: a staleness alert
-- whose OWN payload shows marks_fresh AND engine_fresh were TRUE at raise time was a pure alert-on-
-- alert echo (never about stale marks), so it may resolve as soon as no OTHER critical remains,
-- WITHOUT waiting for intraday marks_fresh (which is false by construction until the evening ingest).
-- A genuinely-stale staleness alert (payload marks_fresh=false) still resolves only via the strict
-- live-recheck path. This removes the last source of the daily staleness echo lingering all day.
--
-- SUPERSEDED (2026-07-19): this definition of ops.sp_auto_resolve_alerts was first superseded by
-- bigquery/94_catchup_refire_blocked_policy.sql, which reproduces this exact procedure body (Rules
-- 1-4 below, byte-identical) and additionally adds Rule 3b (catchup_refire_blocked) — and 94 was in
-- turn superseded by bigquery/107_halt_echo_missed_run_gate.sql (97 in turn superseded — both are
-- themselves superseded; 107 adds a halt-echo missed_run exclusion in Rule 4's no_other_criticals
-- count, alongside 97's original halt-echo missing_dependency exclusion), and 107 was in turn
-- SUPERSEDED by bigquery/130_missing_dependency_alias_resolve.sql (Rule 1 payload-key/array
-- tolerance), and 130 was in turn SUPERSEDED by bigquery/134_roster_change_notifications.sql (adds
-- Rule 5: roster-change notices auto-resolve once notified_ts is stamped), and 134 was in turn
-- SUPERSEDED LIVE by bigquery/148_audit_2026_08_08_fixes.sql (Rule 4's staleness echo arm now
-- re-checks all four state.system_health components instead of two). bigquery/148 is the CURRENT
-- single source of truth for this procedure: apply bigquery/148 -- do NOT re-apply the CREATE OR
-- REPLACE PROCEDURE below live in isolation. Kept here, unmodified, for DR-rebuild apply-in-order
-- reference only. (Historical context preserved: this definition itself SUPERSEDES bigquery/34, per
-- the banner above.)
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_auto_resolve_alerts`()
BEGIN
  DECLARE eligible_dep, eligible_run, eligible_stalled, eligible_stale ARRAY<STRING>;
  DECLARE live_would_clear BOOL;
  DECLARE no_other_criticals BOOL;

  -- Rule 1: missing_dependency.
  SET eligible_dep = (
    SELECT ARRAY_AGG(alert_id) FROM (
      SELECT a.alert_id
      FROM `stock-trading-498512.ops.alerts` a
      CROSS JOIN UNNEST(SPLIT(JSON_VALUE(a.payload, '$.missing_deps'), ', ')) AS dep
      LEFT JOIN `stock-trading-498512.ops.run_log` r
        ON r.routine = dep AND r.status = 'completed'
           AND r.run_date >= SAFE.PARSE_DATE('%Y-%m-%d', JSON_VALUE(a.payload, '$.run_date'))
      WHERE NOT a.resolved AND a.category = 'missing_dependency'
        AND a.category IN (SELECT category FROM `stock-trading-498512.ops.alert_policy` WHERE NOT latching)
      GROUP BY a.alert_id
      HAVING LOGICAL_AND(r.routine IS NOT NULL)
          OR SAFE.PARSE_DATE('%Y-%m-%d', ANY_VALUE(JSON_VALUE(a.payload, '$.run_date'))) < DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 1 DAY)
    )
  );
  UPDATE `stock-trading-498512.ops.alerts`
  SET resolved = TRUE, resolved_ts = CURRENT_TIMESTAMP(),
      resolved_note = CONCAT('auto-resolved: dependency satisfied or window closed (ops.sp_auto_resolve_alerts). ', COALESCE(resolved_note, ''))
  WHERE alert_id IN UNNEST(COALESCE(eligible_dep, []));

  -- Rule 2: missed_run.
  SET eligible_run = (
    SELECT ARRAY_AGG(alert_id) FROM (
      SELECT a.alert_id
      FROM `stock-trading-498512.ops.alerts` a
      CROSS JOIN UNNEST(JSON_QUERY_ARRAY(a.payload)) AS item
      LEFT JOIN `stock-trading-498512.ops.run_log` r
        ON r.routine = JSON_VALUE(item, '$.routine') AND r.status = 'completed'
           AND r.run_date >= SAFE.PARSE_DATE('%Y-%m-%d', JSON_VALUE(item, '$.today'))
      WHERE NOT a.resolved AND a.category = 'missed_run'
        AND a.category IN (SELECT category FROM `stock-trading-498512.ops.alert_policy` WHERE NOT latching)
      GROUP BY a.alert_id
      HAVING LOGICAL_AND(
        r.routine IS NOT NULL
        OR SAFE.PARSE_DATE('%Y-%m-%d', JSON_VALUE(item, '$.today')) < DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 1 DAY)
      )
    )
  );
  UPDATE `stock-trading-498512.ops.alerts`
  SET resolved = TRUE, resolved_ts = CURRENT_TIMESTAMP(),
      resolved_note = CONCAT('auto-resolved: named routine(s) since completed or window closed (ops.sp_auto_resolve_alerts). ', COALESCE(resolved_note, ''))
  WHERE alert_id IN UNNEST(COALESCE(eligible_run, []));

  -- Rule 3: routine_stalled.
  SET eligible_stalled = (
    SELECT ARRAY_AGG(alert_id) FROM (
      SELECT a.alert_id
      FROM `stock-trading-498512.ops.alerts` a
      CROSS JOIN UNNEST(JSON_QUERY_ARRAY(a.payload)) AS item
      LEFT JOIN `stock-trading-498512.ops.run_log` r
        ON r.routine = JSON_VALUE(item, '$.routine')
           AND r.run_date = SAFE.PARSE_DATE('%Y-%m-%d', JSON_VALUE(item, '$.run_date'))
           AND r.status IN ('completed', 'failed', 'halted')
      WHERE NOT a.resolved AND a.category = 'routine_stalled'
        AND a.category IN (SELECT category FROM `stock-trading-498512.ops.alert_policy` WHERE NOT latching)
      GROUP BY a.alert_id
      HAVING LOGICAL_AND(
        r.routine IS NOT NULL
        OR SAFE.PARSE_DATE('%Y-%m-%d', JSON_VALUE(item, '$.run_date')) < DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 1 DAY)
      )
    )
  );
  UPDATE `stock-trading-498512.ops.alerts`
  SET resolved = TRUE, resolved_ts = CURRENT_TIMESTAMP(),
      resolved_note = CONCAT('auto-resolved: stalled run(s) since reached a terminal status, or window closed (ops.sp_auto_resolve_alerts). ', COALESCE(resolved_note, ''))
  WHERE alert_id IN UNNEST(COALESCE(eligible_stalled, []));

  -- Rule 4: staleness — strict live-recheck OR pure-echo (payload-aware). Both require that no OTHER
  -- critical (excluding staleness/trading_halted) remains open. Computed as independent variables
  -- first to avoid the self-reference de-correlation restriction documented in 34.
  SET no_other_criticals = (
    (SELECT COUNTIF(NOT resolved AND severity = 'critical' AND category NOT IN ('staleness', 'trading_halted')) FROM `stock-trading-498512.ops.alerts`) = 0
  );
  SET live_would_clear = (
    SELECT f.marks_fresh AND f.engine_fresh AND eh.is_healthy
      AND NOT COALESCE((SELECT LOGICAL_OR(drifted) FROM `stock-trading-498512.state.position_reconciliation`), FALSE)
    FROM `stock-trading-498512.state.freshness` f, `stock-trading-498512.state.embedding_health` eh
  );
  SET eligible_stale = (
    SELECT ARRAY_AGG(alert_id)
    FROM `stock-trading-498512.ops.alerts`
    WHERE NOT resolved AND category = 'staleness'
      AND category IN (SELECT category FROM `stock-trading-498512.ops.alert_policy` WHERE NOT latching)
      AND COALESCE(no_other_criticals, FALSE)
      AND (
        COALESCE(live_would_clear, FALSE)                                    -- strict: genuinely stale at raise, now healed
        OR (JSON_VALUE(payload, '$.marks_fresh') = 'true'                    -- echo: freshness was already green at raise time
            AND JSON_VALUE(payload, '$.engine_fresh') = 'true')
      )
  );
  UPDATE `stock-trading-498512.ops.alerts`
  SET resolved = TRUE, resolved_ts = CURRENT_TIMESTAMP(),
      resolved_note = CONCAT('auto-resolved: freshness verified green (or payload shows it was green at raise — pure alert-on-alert echo), no other open critical (ops.sp_auto_resolve_alerts). ', COALESCE(resolved_note, ''))
  WHERE alert_id IN UNNEST(COALESCE(eligible_stale, []));
END;

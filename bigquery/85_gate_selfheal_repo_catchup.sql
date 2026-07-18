-- REPO CATCH-UP: bake the 2026-07-17 stale-echo self-heal resolver into the two trading-enable gate
-- procedures' CANONICAL repo definitions (2026-07-18, live-sql-parity follow-up).
-- Project: stock-trading-498512. Apply after 23_trading_control.sql and 33_gate_ordering_fix.sql.
--
-- WHY THIS FILE EXISTS — this is a repo-catches-up-to-LIVE change, the opposite direction from the
-- usual apply-in-order flow, so read this before "fixing" it back.
--
-- On 2026-07-17 the D2a trading-halt stale-echo deadlock was triaged and fixed by baking a best-effort
-- `ops.sp_auto_resolve_alerts()` call into BOTH gate procedures, ahead of the halt decision. That fix
-- was applied LIVE (console/MCP) but was never written back into the repo's canonical files. The repo
-- therefore still carried the PRE-fix bodies of:
--   * ops.sp_assert_trading_enabled              (canonical in bigquery/23_trading_control.sql)
--   * ops.sp_assert_trading_enabled_mechanical   (canonical in bigquery/33_gate_ordering_fix.sql)
--
-- CONSEQUENCE IF LEFT ALONE: a DR rebuild (or any apply-in-order replay of 23/33) would silently
-- REVERT the resolver and reintroduce the exact deadlock it fixed — D2a reaching the gate before its
-- own preamble auto-resolve runs and halting trading for a whole day on an ALREADY-HEALED `staleness`
-- critical. This is the same in-isolation-re-apply accident class documented in bigquery/47's ROOT
-- CAUSE and in 33's own `state.trading_enabled_mechanical` banner.
--
-- HOW IT WAS FOUND: scripts/check_live_sql_parity.py, after its 2026-07-18 comparator fix (it had been
-- reporting 70/179 objects as drifted, ~93% of them false positives caused by comparing repo text to
-- BigQuery's RE-SERIALIZED stored definition — comments stripped, whitespace normalized adjacent to
-- punctuation, backticks dropped). With the canonicalizer in place the count fell to 5 genuine drifts,
-- of which these two were "live is AHEAD of repo".
--
-- SCOPE — DELIBERATELY MINIMAL. Verified 2026-07-18 by diffing the LIVE INFORMATION_SCHEMA.ROUTINES
-- bodies against the repo bodies: the ONLY difference in either procedure is the inserted self-heal
-- BEGIN/EXCEPTION/END block (plus its comment) immediately after the DECLAREs. Every other line —
-- the stable-message comment block, the sp_raise_alert_once payload shape, the RAISE wording — is
-- byte-identical and is reproduced verbatim below. This file changes NOTHING live; live already looks
-- exactly like this. It exists so the repo stops lying about what is deployed.
--
-- SUPERSEDES the ops.sp_assert_trading_enabled PROCEDURE in 23_trading_control.sql and the
-- ops.sp_assert_trading_enabled_mechanical PROCEDURE in 33_gate_ordering_fix.sql. Those files keep
-- their (now superseded) bodies for apply-in-order reference; this file is the current source of truth
-- for these two procedures. It does NOT touch state.trading_enabled_mechanical — bigquery/78 remains
-- that view's source of truth.
--
-- SAFETY OF THE RESOLVER ITSELF (unchanged from the 2026-07-17 reasoning, restated so it is not lost):
-- ops.sp_auto_resolve_alerts is a DRILLED, FAIL-CLOSED allowlist. It only ever REMOVES self-healing
-- criticals (missing_dependency / missed_run / routine_stalled / staleness) whose heal condition is
-- already verifiably met, and it never touches a capital class (cash_tripwire / order_guard_block /
-- drawdown / trading_halted). So it can only make a gate PASS, never falsely halt. The call is wrapped
-- best-effort: a resolver error must never break the gate itself.

-- ===== ops.sp_assert_trading_enabled — the freshness-inclusive gate (D2/W4/M4/Q4/A1/A3) =====
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_assert_trading_enabled`(in_routine STRING)
BEGIN
  DECLARE v_enabled BOOL;
  DECLARE v_reason STRING;
  -- SELF-HEAL BEFORE DECIDING TO HALT (self-improvement audit 2026-07-17) — identical rationale + root
  -- incident as the block in ops.sp_assert_trading_enabled_mechanical. ops.sp_auto_resolve_alerts is a
  -- drilled fail-closed allowlist and only REMOVES healed self-healing criticals, so this can only make
  -- the gate PASS, never falsely halt. Best-effort: a resolver error must never break the gate itself.
  BEGIN
    CALL `stock-trading-498512.ops.sp_auto_resolve_alerts`();
  EXCEPTION WHEN ERROR THEN SELECT @@error.message;  -- swallow: self-heal must not abort the gate
  END;
  SET (v_enabled, v_reason) = (
    SELECT AS STRUCT trading_enabled, halt_reason FROM `stock-trading-498512.state.trading_enabled`
  );
  IF NOT v_enabled THEN
    -- Message kept STABLE, not folding in in_routine or v_reason (2026-07-04 audit finding, cross-
    -- cutting): v_reason embeds a daily-changing drawdown % and in_routine differs per caller
    -- (D2/D2a/W4/M4/Q4/A3) — either one varying the `message` text defeats sp_raise_alert_once's
    -- exact-match (category, message) dedup, so a SUSTAINED halt on this single highest-stakes gate
    -- would accumulate a fresh unresolved critical alert per day/routine instead of deduping to one,
    -- with no auto-resolve path. The dynamic detail still reaches the operator via the payload (and
    -- via the RAISE message below, which is per-call and not subject to alert dedup).
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', in_routine, 'trading_halted',
      'Order staging blocked: trading is HALTED. See payload for the triggering routine and reason.',
      TO_JSON_STRING(STRUCT(in_routine AS routine, v_reason AS halt_reason)));
    RAISE USING MESSAGE = FORMAT(
      '%s: trading_enabled=FALSE (%s) — order staging aborted. Investigate state.trading_enabled / state.trading_control_latest before retrying.',
      in_routine, COALESCE(v_reason, 'unspecified'));
  END IF;
END;

-- ===== ops.sp_assert_trading_enabled_mechanical — D2a-scoped gate (excludes marks_fresh/engine_fresh)
-- Reads state.trading_enabled_mechanical (source of truth: bigquery/78). =====
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_assert_trading_enabled_mechanical`(in_routine STRING)
BEGIN
  DECLARE v_enabled BOOL;
  DECLARE v_reason STRING;
  -- SELF-HEAL BEFORE DECIDING TO HALT (self-improvement audit 2026-07-17). Mechanically clear any
  -- self-healing critical (missing_dependency / missed_run / routine_stalled / staleness) whose heal
  -- condition is ALREADY verifiably met, so this gate cannot trip on a stale echo that the routine's own
  -- best-effort preamble auto-resolve would clear moments later. ROOT INCIDENT: 2026-07-17 D2a reached
  -- this gate at 16:22 BEFORE its preamble auto-resolve ran, and halted trading for the whole day on an
  -- already-healed `staleness` critical (its root SL5 missing_dependency resolved 00:30; marks became
  -- fresh ~16:18). The resolver's only other live path (nightly cadence_check) was never live.
  -- ops.sp_auto_resolve_alerts is a DRILLED FAIL-CLOSED allowlist (never touches cash_tripwire /
  -- order_guard_block / drawdown / trading_halted / any capital class) and only REMOVES healed criticals,
  -- so this can ONLY make the gate PASS, never falsely halt. Best-effort: a resolver error must never
  -- break the gate itself.
  BEGIN
    CALL `stock-trading-498512.ops.sp_auto_resolve_alerts`();
  EXCEPTION WHEN ERROR THEN SELECT @@error.message;  -- swallow: self-heal must not abort the gate
  END;
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

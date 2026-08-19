-- ============================================================================================
-- ops.alert_policy registration for `catchup_executor_headroom`.
-- Project: stock-trading-498512. Added 2026-08-18 by OPS2 on a no-op cycle.
--
-- WHAT THIS FILE IS: exactly ONE guarded INSERT into ops.alert_policy. It creates no view, no
-- procedure, no table, and no scheduled query; it grants no credential; it changes no gate and no
-- existing policy row. Apply order is irrelevant beyond ops.alert_policy existing
-- (bigquery/34_alert_lifecycle.sql).
--
-- ACCIDENT-OF-ABSENCE DISCIPLINE, same as handoff_contract_unpinned (bigquery/180),
-- premortem_live_gate_defect (bigquery/158), prompt_injection_attempt (bigquery/138),
-- append_only_violation (bigquery/139) and queue_venue_claim_unwired (bigquery/160): the class gets
-- a written resolve rule at its FIRST finding rather than after its second, so no future session has
-- to invent one. Registered BEFORE the class has ever fired.
--
-- ============================================================================================
-- THE FINDING (OPS2, 2026-08-18)
-- ============================================================================================
-- OPS2 (Catch-up Executor) fires at 04:15 UTC = 22:15 MDT. OPS0 (Cadence Watchdog) sweeps at
-- 04:30 UTC = 22:30 MDT. That is 15 MINUTES of headroom. OPS2's STEP 2 authorises up to N=4 missed
-- routines executed INLINE, and single routines empirically take 17-29 minutes each (ops.run_log
-- 2026-08-17/18: W3 17m, SL5 20m, W5 25m, D1 29m). So on any night OPS2 has real work, it is still
-- mid-execution when OPS0 sweeps.
--
-- THE OVERLAP IS NOT COVERED by the existing in-flight guard. bigquery/90's `in_flight` CTE -- the
-- mechanism that hides an in-progress routine from state.catchup_available /
-- state.period_catchup_available and therefore from state.catchup_refire_readiness -- joins on
-- `f.run_date = w.today`. A PERIOD-tier routine hosted by OPS2 logs its 'started' row under
-- <as_of> = period_start (OPS2 hosting requirement (c), RUN-LOG IDENTITY), not today, so that join
-- cannot match it. And OPS2 deliberately does not write its ops.catchup_refire_log suppression row
-- until STEP 2.6 has VERIFIED completion -- writing it earlier would durably and permanently
-- suppress a genuine miss if the inline execution died.
--
-- NET EFFECT: OPS0's 22:30 sweep still sees the miss and emails the operator an actionable
-- `catchup_refire_blocked` "re-run these manually" alert naming routines OPS2 is at that moment
-- successfully catching up. That INVERTS the invariant the OPS2 spec states outright ("OPS0 emails
-- only the residual") and asks the operator to hand-run work already in flight.
--
-- WHY IT WENT UNNOTICED FOR THREE WEEKS: the OPS2 spec, ops/RUNBOOK.md 15b, and a comment inside
-- ops/cadence.yaml's own OPS2 block all claimed a "~21:15 MT" fire time -- the MST rendering of the
-- same cron. cadence.yaml's machine-read `time_local` was normalized to the MDT convention on
-- 2026-08-01 and is now CI-enforced (scripts/check_cron_dst_safety.py, pinned by
-- tests/test_check_cron_dst_safety.py), but that sweep stopped at the YAML field and left the prose.
-- At the 75-minute gap the stale figure implied, this overlap would have been rare. All three prose
-- sites were corrected 2026-08-18 in the same commit as this file.
--
-- HAS NEVER FIRED, and could not have: every night since OPS2 went live 2026-07-27 has had an empty
-- state.catchup_refire_readiness feed, so OPS2 has never executed a routine inline at all.
--
-- ============================================================================================
-- NOT FIXED HERE, DELIBERATELY
-- ============================================================================================
-- The durable fix is a live-trigger retime (move OPS2 earlier or OPS0 later), which lives in the
-- claude.ai routines console and is OWNER-ONLY -- a routine cannot alter its own cron. Recorded as
-- OWNER_ACTIONS.md item `OPS2-headroom` with both options costed.
--
-- The Claude-side alternative -- widening bigquery/90's `in_flight` join to also match a hosted
-- routine's as_of -- is a live-SQL change to a view the ENTIRE catch-up path depends on (OPS0's
-- refire feed, OPS2's own STEP 1, D3's watchdog fallback). A routine fire on a night with zero
-- misses to test against is the wrong place to make that unilaterally; same reasoning as the
-- 2026-08-17 AR_orc embedding-gate finding, which hardened the read side in prose and left the gate
-- SQL for an owner / W5 consolidation cycle. Worth doing there if the owner would rather not move a
-- trigger.
--
-- SEVERITY: WARNING, never critical -- an open critical enters bigquery/107's blocking_criticals
-- term and sets state.trading_enabled=FALSE, and a scheduling-overlap that produces a redundant
-- email is not a reason to halt order staging. Never info: alert_emailer.gs (SEVERITIES =
-- ['critical','warning']) and scripts/alert_relay.py both filter info out, so an info raise would be
-- invisible to the operator BY CONSTRUCTION -- and reaching the operator is this row's entire
-- purpose, since only the operator can perform the fix.
--
-- Guarded by NOT EXISTS so re-applying this file is idempotent (same shape as bigquery/160 and 180).
-- ============================================================================================
INSERT INTO `stock-trading-498512.ops.alert_policy` (category, latching, resolve_rule, note)
SELECT p.category, p.latching, p.resolve_rule, p.note
FROM UNNEST([
  STRUCT(
    'catchup_executor_headroom' AS category,
    FALSE AS latching,
    CONCAT(
      'EVIDENCE-BASED, CONFIG-VERIFIABLE resolve -- NOT covered by any ops.sp_auto_resolve_alerts ',
      'rule (those are hardcoded to missing_dependency/missed_run/routine_stalled/',
      'catchup_refire_blocked/staleness), so latching=FALSE only SANCTIONS the resolve below under ',
      'the fail-closed allowlist; it does not perform it. Resolve when the measured gap between the ',
      'OPS2 and OPS0 fire times is large enough to hold OPS2 STEP 2 bound (N=4) inline executions: ',
      'read both routines cron_utc from ops/cadence.yaml, confirm against the LIVE trigger in the ',
      'routines console (ops.run_log CANNOT prove a trigger fired -- OPS2 guard-suppressed runs ',
      'write no row at all; see the OPS2 block in ops/cadence.yaml), and require the gap to exceed ',
      'N times the observed p90 routine duration. Alternatively resolve if the structural cause is ',
      'removed instead of the timing: bigquery/90 in_flight join widened to match a hosted routine ',
      'as_of, or OPS2 STEP 2 N lowered to what the real headroom holds. Resolve with UPDATE ',
      'ops.alerts SET resolved=TRUE, resolved_ts=CURRENT_TIMESTAMP(), resolved_note=<the two cron ',
      'values re-read + which remedy landed> scoped by alert_id. NEVER resolve on age: this class ',
      'is a STANDING CONFIG condition, not an event -- it is equally true every night and an aged-',
      'out row would be indistinguishable from a fixed one, the same aging-alert trap ',
      'phantom_run_completion and handoff_contract_unpinned both document. NEVER resolve on a quiet ',
      'night: an empty state.catchup_refire_readiness feed is exactly when this class is invisible, ',
      'because OPS2 executes nothing and the overlap cannot manifest.'
    ) AS resolve_rule,
    CONCAT(
      'CADENCE-ORDERING CLASS, registered 2026-08-18 by OPS2 on a no-op cycle, after its own ',
      'corroboration sweep found the OPS2 spec, ops/RUNBOOK.md 15b and a comment inside ',
      'ops/cadence.yaml OPS2 own block all claiming a ~21:15 MT fire (the MST rendering) while the ',
      'declared and live cron 15 4 * * 1,2,3,4,5 is 22:15 MDT -- leaving 15 min, not 75, before ',
      'OPS0 04:30 UTC sweep. CONDITION: a recovery routine that executes work INLINE is scheduled ',
      'too close to the watchdog that reports the same work as unrecovered. bigquery/90 in_flight ',
      'guard does not cover the overlap (it joins f.run_date = w.today, while a hosted period-tier ',
      'routine logs started under period_start per OPS2 hosting requirement (c)), and OPS2 ',
      'deliberately withholds its ops.catchup_refire_log suppression row until completion is ',
      'VERIFIED -- so OPS0 emails an actionable re-run-manually alert for routines being caught up ',
      'successfully at that moment, inverting the OPS0-emails-only-the-residual invariant. Found ',
      'BEFORE it ever fired: every night since OPS2 went live 2026-07-27 has had an empty ',
      'catchup_refire_readiness feed, so no inline execution has ever occurred. Secondary cost ',
      'already paid: the stale 21:15 prose made five consecutive OPS2 sessions (2026-08-14 to ',
      '2026-08-18) log a phantom timing-drift anomaly against a trigger firing exactly on schedule. ',
      'Durable fix is an owner console retime (OWNER_ACTIONS.md OPS2-headroom); the Claude-side ',
      'alternative is a fleet-blast-radius change to shared catch-up SQL and was deliberately not ',
      'made from a routine fire. WARNING, never critical: an open critical sets ',
      'state.trading_enabled=FALSE (bigquery/107) and a redundant operator email is not a reason to ',
      'halt order staging. Never info: alert_emailer.gs and alert_relay.py both filter info out, so ',
      'an info raise would be invisible by construction -- and only the operator can apply the fix.'
    ) AS note
  )
]) AS p
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.ops.alert_policy` e WHERE e.category = p.category
);

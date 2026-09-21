-- ops0_missed_fallback alert policy: registers the ONE D3-raised category that had no
-- ops.alert_policy row and no resolving code anywhere in the fleet, so every instance latched
-- open forever. Project: stock-trading-498512.
--
-- THE DEFECT, MEASURED 2026-09-21 rather than inferred. `ops0_missed_fallback` is raised by D3's
-- OPS0 WATCHDOG-FALLBACK bullet when OPS0 logged no completed run on its last expected day and D3
-- ran the catch-up sweep inline. A repo-wide grep for the category name returns exactly two hits --
-- Claude_Task_Plan.md and its generated task_plan/D3.md mirror -- and BOTH are the raise site. There
-- is no UPDATE anywhere, no ops.alert_policy row (confirmed by direct query: zero rows), and no arm
-- in ops.sp_auto_resolve_alerts (current source of truth bigquery/148; chain 94 -> 97 -> 107 -> 130
-- -> 134 -> 148). Per ops.alert_policy's own documented semantics a category absent from this table
-- is latching by construction, so the generic auto-resolver can never touch it. Live proof: alert
-- ccd0e848 (D3, 2026-09-20) sits unresolved while the condition it reports is long gone -- OPS0
-- missed only its 2026-09-17 slot, killed by the account's seven-day quota exhaustion
-- (2026-09-18 01:16:06 UTC -> 2026-09-19 08:00:00 UTC, RUNBOOK section 53), and has fired normally
-- since. The alert outlived its own condition by design gap, not by neglect.
--
-- This is the same class ops.alert_policy's own spec_defect_notice_stalled note complains about:
-- "the category had NO ops.alert_policy row from its 2026-09-08 creation until then, so its
-- latching semantics and closure rule were undeclared for its whole life and a triage session
-- reading the registry would have found nothing."
--
-- WHY THE CLOSER IS D3 AND NOT ops.sp_auto_resolve_alerts. D3 already evaluates the EXACT inverse
-- predicate on every single run -- `SELECT COUNT(*) FROM ops.run_log WHERE routine='OPS0' AND
-- status='completed' AND run_date = <ops0_last_expected_day>` -- and raises only when that count is
-- 0. A count > 0 is therefore positive evidence that the reported condition has cleared, produced by
-- the same routine, from the same query, on the same cadence. Putting the clear limb there makes
-- raise and clear one paired mechanism in one place rather than two that can drift apart. It also
-- keeps the judgement with the INDEPENDENT watcher: OPS0 resolving an alert about OPS0 would be
-- self-attestation, and if OPS0's trigger is genuinely broken OPS0 never runs to clear it, which is
-- exactly when the row must stay open. D3's limb is specified in Claude_Task_Plan.md's D3 section,
-- OPS0 WATCHDOG-FALLBACK bullet (landed with this file).
--
-- WHY latching = TRUE. It is never aged out. The row closes only on positive evidence that OPS0
-- completed an expected day, never on elapsed time -- the same shape as spec_defect_notice_stalled,
-- and for the same reason: ageing out a watchdog notice would silently discard the one signal that
-- the fleet's own cadence watchdog stopped running. Do NOT add this category to
-- ops.sp_auto_resolve_alerts.
--
-- THIS FILE IS DML-ONLY AND DELIBERATELY CREATES NO OBJECT. It adds one guarded row and nothing
-- else, so scripts/check_live_sql_parity.py never sees it: that checker compares CREATE
-- VIEW/PROCEDURE/TABLE FUNCTION bodies against live BigQuery and fails a run on an object the repo
-- declares but the warehouse lacks. A new CREATE here would turn CI red until applied live; a DML
-- statement cannot. The behavioural fix rides entirely in D3's routine prose, which needs no
-- warehouse object at all, so the fleet gains the closure path the moment the prose merges --
-- applying this row live is a separate, order-independent step that only affects what a triage
-- session reads out of the registry.
--
-- Apply live via the BigQuery MCP (execute_sql), same apply-in-order discipline as bigquery/01..NN.

-- ===== ops.alert_policy — seed the ops0_missed_fallback row =====
-- Guarded insert, one row, matching bigquery/94's
-- `INSERT ... SELECT ... FROM UNNEST([STRUCT(...)]) WHERE NOT EXISTS` idiom (itself matching
-- bigquery/34's seed block), scoped to this one category because the table already holds others.
-- Re-applying this file is a no-op once the row exists.
INSERT INTO `stock-trading-498512.ops.alert_policy` (category, latching, resolve_rule, note)
SELECT * FROM UNNEST([
  STRUCT('ops0_missed_fallback' AS category, TRUE AS latching,
    'Closed by D3 OWN OPS0 WATCHDOG-FALLBACK bullet, on the inverse of the predicate that raises it: when D3 computes ops0_last_expected_day and finds COUNT(*) FROM ops.run_log WHERE routine = OPS0 AND status = completed AND run_date = that day is greater than 0, it resolves every unresolved ops0_missed_fallback row with a resolved_note naming the run_date that supplied the evidence. Positive evidence only -- a completed OPS0 row for an expected day. NEVER aged out and NEVER closed by elapsed time, because a watchdog notice that expires on its own would silently discard the signal that the fleet cadence watchdog itself stopped running; this category must NOT be added to ops.sp_auto_resolve_alerts. If OPS0 trigger is genuinely broken OPS0 never runs, D3 never sees a completed row, and the row correctly stays open.' AS resolve_rule,
    'Registered 2026-09-21 by an interactive triage session (bigquery/245), closing a structural gap found while triaging alert ccd0e848. The category was created by D3 and raised at least twice (2026-08-02, 2026-09-20) with NO policy row, NO auto-resolver arm and NO resolving code anywhere in the repo -- a grep for the name returned only the raise site and its generated slice -- so every instance latched open permanently while the condition it reported had already cleared. The 2026-09-20 instance reported OPS0 missing only its 2026-09-17 slot to the seven-day quota exhaustion recorded in RUNBOOK section 53; OPS0 fired normally on 2026-09-20. Same undeclared-semantics class as the spec_defect_notice_stalled row below. The closing mechanism lives in D3 routine prose, not in a procedure.' AS note)
])
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.ops.alert_policy` WHERE category = 'ops0_missed_fallback'
);

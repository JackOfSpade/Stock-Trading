-- ops.alert_policy row for AR_orc's artifact_version_drift class.
-- Project: stock-trading-498512. Registers policy only — CREATES NO OBJECT, REPLACES NO PROCEDURE,
-- and therefore carries no scheduled-query version bump and no partial-apply trap. Guarded by
-- NOT EXISTS, so re-applying this file is a no-op.
--
-- ===================== WHY: THE CLASS FIRED, AND ITS CLOSE WAS UNREACHABLE =====================
-- artifact_version_drift is raised by AR_orc's Step 1.5 ARTIFACT-VERSION GATE when the artifact under
-- review moved between the attacker's write and the orchestrator's read. It had ZERO rows until
-- 2026-08-19, when the gate fired for the first time ever and raised TWO at once:
--   premortem-C-2026-a3  cycle 14 withheld, cycle 15 re-enqueued   FALSE POSITIVE (file-SHA on a
--                                                                  shared five-review artifact;
--                                                                  the C section was byte-identical)
--   premortem-E-2026-a3  cycle 10 withheld, cycle 11 re-enqueued   TRUE POSITIVE (rev 10 -> rev 11)
-- The same firing correctly fixed the granularity defect (section-scoped fallback, commit 31b25db)
-- and wrote a close for the notice — "at Step 5 of the cycle that DOES produce a verdict, resolve it".
--
-- BUT THAT CLOSE WAS WRITTEN INTO STEP 1.5's *WITHHOLD BRANCH*, WHICH IS NOT THE BRANCH THAT
-- EXECUTES IT. The session that performs the close is a LATER AR_orc fire that takes the gate's
-- *equal-SHA* branch ("proceed to Step 2 normally... and say nothing further") and never reads the
-- withhold branch's bullets at all; Step 5 itself said only "insert a queue_events row with status =
-- complete". So the sole closer for this category, in the sole file that carried it, sat in dead
-- prose. Measured 2026-08-19, ~20:50 MT: both rows still open, and nothing anywhere would have closed them.
-- Fixed the same evening by moving the operative statement to Step 5 (Claude_Task_Plan.md, AR_orc), keyed
-- off the payload.artifact_moved='true' marker the re-enqueue already writes.
--
-- THIS IS THE THIRD INSTANCE OF ONE DEFECT CLASS IN THREE DAYS, which is why the class earns a
-- policy row rather than another one-off prose patch:
--   2026-08-18  SL5   handoff_contract_unpinned  the SL3->SL5 handoff pinned no queue/item_key
--   2026-08-19  SL5   handoff_contract_unpinned  SL5's drain site never stated its own close
--   2026-08-19  SL2   bigquery/185_sl2_*         two of SL2's three notice classes can never close
--   2026-08-19  AR_orc                           this one — a close stated at the wrong site
-- The invariant they share: A CLOSE STATED ANYWHERE OTHER THAN AT THE SITE THAT WILL EXECUTE IT IS
-- NOT A CLOSE. A policy row is the one surface a triage session reads BEFORE grepping a 1MB task
-- plan — it is how the sibling handoff_contract_unpinned row made its own same-evening triage
-- mechanical instead of archaeological.
--
-- WHAT latching=FALSE DOES AND DOES NOT DO. It SANCTIONS the routine-owned resolve under this table's
-- fail-closed allowlist; it does not perform it and cannot make anything resolve that was not already
-- resolving. ops.sp_auto_resolve_alerts's rules are each hardcoded to a specific category
-- (missing_dependency / missed_run / routine_stalled / catchup_refire_blocked / staleness, plus the
-- roster-notice Rule 5 keyed on notified_ts) and reach this one never. Same posture as
-- catchup_executor_headroom, phantom_run_completion, queue_venue_claim_unwired and
-- handoff_contract_unpinned. NOTE FOR A FUTURE READER: Claude_Task_Plan.md's Step 1.5 previously said
-- this category was "deliberately ABSENT from ops.alert_policy, so it is latching" — that sentence was
-- rewritten in the same commit as this file, so the two do not disagree. Nothing operational changed
-- by registering it; the triage surface did.
--
-- Severity stays WARNING, never critical: an open critical enters state.trading_enabled's
-- blocking_criticals term (bigquery/107) and a review whose artifact moved under it is not a reason to
-- halt order staging — no capital is at risk from this class, and the withhold is itself the
-- conservative action. Never info: alert_emailer.gs (SEVERITIES = ['critical','warning']) and
-- scripts/alert_relay.py both filter info out, so an info raise would be invisible by construction.

INSERT INTO `stock-trading-498512.ops.alert_policy` (category, latching, resolve_rule, note)
SELECT * FROM UNNEST([
  STRUCT('artifact_version_drift' AS category, FALSE AS latching,
    'EVIDENCE-BASED, ROUTINE-OWNED resolve -- NOT covered by any ops.sp_auto_resolve_alerts rule '
    '(those are hardcoded to missing_dependency/missed_run/routine_stalled/catchup_refire_blocked/'
    'staleness), so latching=FALSE only SANCTIONS the resolve below under the fail-closed allowlist; '
    'it does not perform it. AR_orc owns it, at STEP 5 of the cycle that actually produces a verdict '
    'for the same review id -- keyed off payload.artifact_moved=\'true\', the marker Step 1.5\'s '
    're-enqueue writes on the fresh cycle. Statement: UPDATE ops.alerts SET resolved=TRUE, '
    'resolved_ts=CURRENT_TIMESTAMP(), resolved_note=<cycle re-adjudicated + current sha + review id> '
    'WHERE category=\'artifact_version_drift\' AND NOT resolved AND message LIKE CONCAT(\'%\', '
    '<review id>, \'%\') -- resolving every open row for the same review id together is deliberate: a '
    'review re-enqueued twice raises two rows for one condition and one verdict discharges both. '
    'READ THE PLACEMENT NOTE BEFORE MOVING ANYTHING: for about two hours on the evening of 2026-08-19 this instruction '
    'lived in Step 1.5\'s WITHHOLD branch, which is the one branch the resolving session never '
    'executes (it takes the equal-SHA branch and proceeds straight to Step 2), so the class had a '
    'written close and no reachable one. It was moved to Step 5 later the same evening (2026-08-19). Do not move it back. '
    'NEVER resolve on age -- a withheld review produces no signal of its own, so an aged-out row is '
    'indistinguishable from a re-adjudicated one, the same aging-alert trap phantom_run_completion '
    'documents. NEVER resolve a review id other than the one graded -- per-review evidence, same '
    'discipline handoff_contract_unpinned keeps per-handoff and queue_venue_claim_unwired per '
    '(item_key, finding_class). A cycle that is WITHHELD AGAIN raises a second row and closes '
    'nothing: that is correct, the condition genuinely persists.' AS resolve_rule,
    'ADVERSARIAL-REVIEW / HANDOFF-INTEGRITY CLASS, first raised 2026-08-19 by AR_orc on the very first '
    'live firing of its Step 1.5 ARTIFACT-VERSION GATE (added 2026-08-07); registered here 2026-08-19 '
    'after that firing revealed the class had no ops.alert_policy row and, separately, that its only '
    'written closer sat in an unreachable branch. Same accident-of-absence discipline as '
    'premortem_live_gate_defect (bigquery/158), prompt_injection_attempt (bigquery/138), '
    'append_only_violation (bigquery/139), queue_venue_claim_unwired (bigquery/160) and the SL2 notice '
    'classes (bigquery/185_sl2_notice_alert_lifecycle.sql). CONDITION: the artifact moved between the attacker\'s write and the '
    'orchestrator\'s read, so the attacker\'s critique is not evidence about the current text and must '
    'not be graded as if it were; the verdict is withheld and a fresh, penalty-free, cap-exempt '
    'attacker cycle is enqueued. THE GATE COMPARES THE SECTION UNDER REVIEW, NOT THE FILE (fixed '
    '2026-08-19, commit 31b25db, after the founding firing withheld premortem-C-2026-a3 cycle 14 on a '
    'section that was byte-identical at both commits, sha256 3ea41925 -- strategy/08_pre_mortems.md is '
    'a SHARED artifact all five per-strategy pre-mortem reviews name, so a file-level compare '
    'livelocks every other in-flight review of it every time SL2 revises any one section). A NEW '
    'FIRING IS THEREFORE EXPECTED TO BE GENUINE: check the payload\'s section_identity_note and '
    'section_byte_identical before assuming a false positive, and if section_byte_identical is TRUE '
    'the gate itself has regressed to file granularity -- fix the gate, not the alert. WARNING, never '
    'critical: an open critical sets state.trading_enabled=FALSE (bigquery/107) and a review that '
    'correctly declined to grade stale evidence is not a reason to halt order staging. Never info: '
    'alert_emailer.gs and scripts/alert_relay.py both filter info out, so an info raise would be '
    'invisible by construction.' AS note)
]) AS p
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.ops.alert_policy` a WHERE a.category = p.category
);

-- ops.alert_policy rows for SL2's three lifecycle-notice classes:
-- strategy_drafted, strategy_revised, postmortem_written.
-- Project: stock-trading-498512. Registers policy only — CREATES NO OBJECT, REPLACES NO PROCEDURE,
-- and therefore carries no scheduled-query version bump and no partial-apply trap.
--
-- ===================== WHY: TWO OF SL2'S THREE NOTICES CAN NEVER CLOSE =====================
-- Claude_Task_Plan.md §SL2 ends every processed queue item with
--   CALL ops.sp_raise_alert('info','SL2','strategy_drafted'|'strategy_revised'|'postmortem_written', ...)
-- — one notice per item, at INFO severity, by design. SL2 is the SOLE producer of all three.
--
-- An INFO row is invisible to both delivery paths (alert_emailer.gs and scripts/alert_relay.py each
-- filter info out before the notification query), so it NEVER reaches notified_ts. That rules out
-- ops.sp_auto_resolve_alerts Rule 5 — the on-delivery resolve the six SISA ROSTER-CHANGE notices use
-- ('ops.alerts.notified_ts IS NOT NULL'). Rules 1-4 are each hardcoded to a specific category
-- (missing_dependency / missed_run / routine_stalled / catchup_refire_blocked / staleness) and reach
-- none of these three. So the ONLY mechanical closer available to this family is the #14 7-day
-- self-healing auto-age block inside ops.sp_sq_cadence_check.
--
-- MEASURED 2026-08-19 against the LIVE procedure body (ops.INFORMATION_SCHEMA.ROUTINES, 71,174 chars,
-- current body bigquery/172_run_log_unpaired_terminal.sql, SQ_VERSION v20) — not against the repo, and
-- not inferred from the file that was supposed to have fixed it:
--   severity IN ('warning', 'info')   PRESENT   (the bigquery/159 widening IS live)
--   'strategy_revised'                PRESENT   in the #14 fail-closed category allowlist
--   'strategy_drafted'                ABSENT    — the literal appears NOWHERE in the 71KB body
--   'postmortem_written'              ABSENT    — the literal appears NOWHERE in the 71KB body
--
-- So exactly ONE of SL2's three notice categories has any mechanism capable of resolving it. The other
-- two are, today, structurally unclearable: no ops.alert_policy row (hence LATCHING under this table's
-- fail-closed default), no auto-age entry, no delivery path to stamp notified_ts, and no routine
-- instructed to close them by hand.
--
-- THIRD RECURRENCE IN THE SAME FAMILY, and this file closes it before its first firing.
--   * bigquery/150 added 'strategy_revised' to the #14 list — into a block whose first predicate was
--     `AND severity = 'warning'`, which an INFO row can no more satisfy than it could satisfy Rule 5.
--     Inert on arrival; undetected, because an ABSENT category and an UNREACHABLE one present the
--     identical symptom (one alert stays open).
--   * bigquery/159 (2026-08-10) widened that predicate to severity IN ('warning','info') and fixed
--     strategy_revised for real. In the SAME file it pre-emptively added 'trigger_drift_corrected' for
--     precisely this reason, stating it plainly: that category "is in neither ops.alert_policy nor this
--     auto-age list — so every drift OPS0 ever auto-corrects would strand a permanently-open info row,
--     the exact bug this file fixes for strategy_revised. Latent rather than observed only because the
--     sweep has not completed." It swept the sibling in an unrelated routine and missed the two sitting
--     next to the category it had come to fix.
--   * strategy_drafted and postmortem_written are those two. Nine days on, still unregistered.
--
-- WHY NOBODY HAS SEEN IT: neither has EVER been raised. ops.alerts holds 5 rows for strategy_revised
-- (2026-08-02..2026-08-17) and ZERO for the other two, because SL2 routes (A) and (C) have never fired
-- — events.queue_events has never carried an item_type='strategy-draft' row at all, and
-- events.strategy_lifecycle carries no TERMINATED transition, so events.strategy_postmortems is
-- legitimately empty. The defect is invisible precisely because the arsenal has not yet done either of
-- the two things it exists to do.
--
-- WHICH IS ALSO WHY IT MATTERS MORE THAN ITS SIZE SUGGESTS. Both are FIRST-EVENT notices:
-- strategy_drafted fires when a candidate is first authored into the pipeline, postmortem_written when
-- a strategy is first terminated — the highest-consequence event in the SISA loop. The very first time
-- the arsenal adds or removes a strategy, it would strand a permanently-open row, and the operator's
-- board would carry it forever with no one able to say why. Found BEFORE first firing, the same
-- posture SL5 took on handoff_contract_unpinned (2026-08-18, route 2 never run) and bigquery/159 took
-- on trigger_drift_corrected — and the opposite of ar_orc_revision_unrouted, which was found only
-- after it had cost two SL2 fires.
--
-- ===================== SEVERITY: DELIBERATELY LEFT AT info =====================
-- The obvious-looking fix — promote all three to `warning` so Rule 5's on-delivery resolve reaches them
-- — is REJECTED, and recorded here so a future audit does not read its absence as an oversight.
-- Claude_Task_Plan.md §SL2 pins the raise at info, and the six SISA ROSTER-CHANGE notices are warning
-- for a reason that does not transfer: they report a change in roster MEMBERSHIP, which the operator
-- must see. SL2's three report EDITORIAL work inside the lifecycle — a draft authored, a pre-mortem
-- redrafted, a post-mortem written — where no human action is ever owed and no roster membership
-- moves. Under the 2026-07-10 owner directive there is no human review/approval step anywhere in the
-- add or delete path, so routing routine editorial churn into the operator's inbox would re-introduce
-- exactly the human-facing traffic that conversion removed. info is CORRECT for this family; what was
-- missing is a declared way for an info row to close, which is what this file supplies.
--
-- ===================== WHY NOT ALSO PATCH THE #14 ALLOWLIST =====================
-- Adding the two literals to ops.sp_sq_cadence_check's #14 IN-list would give all three a uniform
-- mechanical backstop, and was CONSIDERED. Deliberately not done from an SL2 fire:
--   * It requires CREATE OR REPLACE of a 71KB fleet-critical procedure — the cadence dead-man's switch
--     itself — plus a matching bigquery/63 registry bump. That object family has recorded THREE
--     partial-apply incidents (embed_pending; daily_staging_cap_check v3->v4, alert 0c2b631a;
--     bigquery/157 leaving the registry on v17 against a live v18, alert f614015c). The semantic change
--     is two string literals; the DEPLOYMENT is where the risk actually lives.
--   * OPS2 set the governing precedent on 2026-08-18 (catchup_executor_headroom), declining "a
--     fleet-blast-radius change to shared catch-up SQL ... from a routine fire" for a defect it had
--     found and could describe exactly.
--   * It is not needed for completeness. SL2 is the sole producer AND the sole consumer of this family,
--     fires Sun-Thu on its own trigger regardless of queue content (evidenced by its 2026-08-12,
--     08-16 and 08-18 no-op fires, each of which logged completed against an empty queue), and is now
--     instructed by its own section to close its prior notices. A routine-owned resolve is the SAME
--     disposition queue_venue_claim_unwired, handoff_contract_unpinned, phantom_run_completion and
--     artifact_version_drift (added 2026-08-19 by AR_orc) all carry, and it is REACHABLE here where an
--     age-out merely hides the row.
-- If a later session is already replacing that procedure for another reason, adding the two literals in
-- that pass is a free improvement and is encouraged — it just does not justify the replacement alone.
--
-- ===================== A LIVE PREDICTION, LEFT DELIBERATELY UNRESOLVED =====================
-- The #14 auto-age has NEVER been observed to close a strategy_revised row: all three resolved rows in
-- ops.alerts (7d79530d, 2d4bf02a, ea91bdc3) were closed BY HAND in interactive or follow-up sessions,
-- every one of them before the 7-day mark. Two rows are open right now — f34b3920 (raised 2026-08-13,
-- 5.98 days old at the time of writing) and 9a1e498d (raised 2026-08-17). This session deliberately did
-- NOT resolve either. Closing them tonight would be cosmetic tidiness on non-blocking info rows and
-- would destroy the only natural experiment available: f34b3920 crosses 7 days on 2026-08-20, so the
-- next cadence_check beat after that is the FIRST end-to-end observation of whether bigquery/159's
-- widening actually fires in the live body. PREDICTION, recorded so it can be checked rather than
-- re-derived: f34b3920 auto-resolves with resolved_note beginning 'auto-aged (>7d self-healing
-- warning/info; cadence_check.sql #14)'. If it is still open on the 2026-08-20 SL2 fire, the widening
-- is inert live for a third time and THAT is the finding — escalate it rather than resolving by hand.
--
-- ===================== SAFETY =====================
-- Adding a row here changes no behaviour. ops.sp_auto_resolve_alerts' rules are each hardcoded to a
-- specific category, so ops.alert_policy is a fail-closed ALLOWLIST that GATES those rules, never a
-- trigger that enables one. latching=FALSE records that a class has a sanctioned disposition and
-- SANCTIONS the documented resolve; it does not perform it and cannot make anything resolve that was
-- not already resolving. Guarded by NOT EXISTS, so re-applying this file is a no-op.

INSERT INTO `stock-trading-498512.ops.alert_policy` (category, latching, resolve_rule, note)
SELECT * FROM UNNEST([
  STRUCT('strategy_revised' AS category, FALSE AS latching,
    'ROUTINE-OWNED resolve, WITH a 7-day mechanical backstop — the only one of SL2\'s three notice '
    'classes that has the backstop. (1) BACKSTOP: the #14 self-healing auto-age block inside '
    'ops.sp_sq_cadence_check lists this category AND, since bigquery/159 (2026-08-10), reads '
    'severity IN (\'warning\',\'info\'), so a row older than 7 days is auto-resolved with a '
    'resolved_note beginning \'auto-aged (>7d self-healing warning/info; cadence_check.sql #14)\'. '
    'Verified PRESENT in the live 71KB body 2026-08-19, but NEVER YET OBSERVED to fire: all three '
    'resolved rows to date (7d79530d, 2d4bf02a, ea91bdc3) were closed by hand before day 7. '
    '(2) PRIMARY, and preferred because it closes on evidence rather than on age: SL2 resolves its own '
    'prior notices on a later fire, once the work each announced is verifiably downstream — the '
    'revised pre-mortem is committed on main and its re-enqueued review has advanced past SL2 (an '
    'events.queue_events PENDING_REVIEW row for that item_key at the incremented cycle). Resolve with '
    'UPDATE ops.alerts SET resolved=TRUE, resolved_ts=CURRENT_TIMESTAMP(), resolved_note=<which '
    'revisions landed + where the review now sits>, scoped by alert_id. NEVER promote this class to '
    'warning to reach sp_auto_resolve_alerts Rule 5 — see the note field. Registered 2026-08-19 '
    '(bigquery/185) by SL2, the sole producer, on a no-op cycle.' AS resolve_rule,
    'SISA LIFECYCLE-NOTICE CLASS, first raised 2026-08-02; 5 rows through 2026-08-17. Raised by SL2 '
    'route (B) per Claude_Task_Plan.md §SL2 when a live-strategy pre-mortem or a candidate draft is '
    'redrafted from an AR_orc REVISION REQUIRED verdict. INFO by design and deliberately NOT promoted: '
    'the six SISA ROSTER-CHANGE notices are warning because they report a change in roster MEMBERSHIP '
    'the operator must see, whereas this reports EDITORIAL work inside the lifecycle where no human '
    'action is ever owed and no roster membership moves — and under the 2026-07-10 owner directive '
    'there is no human review step anywhere in the add/delete path, so routing routine editorial churn '
    'into the operator inbox would re-introduce the traffic that conversion removed. Never critical: '
    'an open critical sets state.trading_enabled=FALSE (bigquery/107) and a documentary pre-mortem '
    'revision is not a reason to halt order staging.' AS note),
  STRUCT('strategy_drafted' AS category, FALSE AS latching,
    'ROUTINE-OWNED resolve, WITH NO MECHANICAL BACKSTOP — read this before assuming an open row is '
    'someone else\'s problem. Unlike its sibling strategy_revised, this category is ABSENT from the '
    '#14 auto-age allowlist in ops.sp_sq_cadence_check (measured 2026-08-19: the literal appears '
    'nowhere in the live 71KB body), and at INFO severity it can never reach notified_ts, so '
    'ops.sp_auto_resolve_alerts Rule 5 cannot see it either. NOTHING will close this row but a '
    'deliberate write. SL2 is the sole producer and owns the resolve: on a later fire, once the '
    'candidate section it announced is committed on main and its strategy-adoption review is enqueued '
    'in events.queue_events (PENDING_REVIEW, review_type=\'strategy-adoption\'), resolve with '
    'UPDATE ops.alerts SET resolved=TRUE, resolved_ts=CURRENT_TIMESTAMP(), resolved_note=<candidate '
    'code + where its adoption review now sits>, scoped by alert_id. Resolve on that evidence, never '
    'on age: this class fires once per candidate ever authored, so an aged-out row would be '
    'indistinguishable from one whose candidate quietly went nowhere. Registered 2026-08-19 '
    '(bigquery/185) BEFORE its first firing.' AS resolve_rule,
    'SISA LIFECYCLE-NOTICE CLASS, NEVER YET RAISED — zero rows in ops.alerts. Raised by SL2 route (A) '
    'per Claude_Task_Plan.md §SL2 when a QUALIFYING candidate\'s mechanism section and 7-section '
    'pre-mortem are first authored. Unfired because SL1 has never promoted a candidate: '
    'events.queue_events has never carried an item_type=\'strategy-draft\' row, and the only three '
    'candidates to date (F, G, H) were all default-REJECTED at SL1 STEP 3. Registered proactively for '
    'the same accident-of-absence reason as prompt_injection_attempt (bigquery/138), '
    'append_only_violation (bigquery/139), premortem_live_gate_defect (bigquery/158) and '
    'queue_venue_claim_unwired (bigquery/160) — a class discovered before its first firing rather than '
    'after the eighth. INFO by design and deliberately NOT promoted to warning; see the '
    'strategy_revised note for the full reasoning. Never critical: an open critical sets '
    'state.trading_enabled=FALSE (bigquery/107) and authoring a candidate — which touches no capital, '
    'stages no order and does not join the roster — is not a reason to halt order staging.' AS note),
  STRUCT('postmortem_written' AS category, FALSE AS latching,
    'ROUTINE-OWNED resolve, WITH NO MECHANICAL BACKSTOP — identical mechanics to strategy_drafted: '
    'ABSENT from the #14 auto-age allowlist in ops.sp_sq_cadence_check (measured 2026-08-19 against '
    'the live 71KB body), and unreachable by ops.sp_auto_resolve_alerts Rule 5 at INFO severity. '
    'NOTHING will close this row but a deliberate write. SL2 is the sole producer and owns the '
    'resolve: on a later fire, confirm the post-mortem it announced is durable and complete — an '
    'events.strategy_postmortems row exists for that (strategy_code, retired_date) with '
    'material_diff_required_for_restart populated, AND every events.premortem_flags row for that '
    'strategy_code has a matching events.premortem_flag_outcomes row (the ITEM 22 scoring pass is part '
    'of the work this notice claims to have completed, so a missing outcome row means the notice is '
    'premature and the ROW SHOULD STAY OPEN). Then resolve with UPDATE ops.alerts SET resolved=TRUE, '
    'resolved_ts=CURRENT_TIMESTAMP(), resolved_note=<strategy + retired_date + flags scored>, scoped '
    'by alert_id. Resolve on that evidence, never on age. Registered 2026-08-19 (bigquery/185) BEFORE '
    'its first firing.' AS resolve_rule,
    'SISA LIFECYCLE-NOTICE CLASS, NEVER YET RAISED — zero rows in ops.alerts. Raised by SL2 route (C) '
    'per Claude_Task_Plan.md §SL2 when a termination post-mortem is authored from a D2 §5 or AR_orc '
    'TERMINATED transition. Unfired because no strategy has ever terminated: events.strategy_lifecycle '
    'holds only ADOPTED (A-E, founding seed) and candidate-stage REJECTED (F, G, H) transitions, so '
    'events.strategy_postmortems being empty is correct rather than a gap, and the 15 unscored '
    'events.premortem_flags rows are the expected pre-termination state. This is the notice that fires '
    'at the single highest-consequence event in the SISA loop — the first time the arsenal removes a '
    'strategy — which is exactly why it must not be the notice that strands a permanently-open row on '
    'the board that night. INFO by design and deliberately NOT promoted to warning; the operator-facing '
    'signals for a termination are elsewhere and are already loud: the critical termination_close_staged '
    'confirm tap on each close order, and the warning strategy_deregistered roster-change notice from '
    'SL5. Never critical here: this notice reports that the RECORD was written, not that capital moved.' AS note)
]) AS p
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.ops.alert_policy` a WHERE a.category = p.category
);

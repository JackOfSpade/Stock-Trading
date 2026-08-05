-- 138_prompt_injection_alert_class.sql (2026-08-04)
-- Project: stock-trading-498512. Apply AFTER 137_invalidation_status_echo_forward.sql.
-- Defines NO views or procedures -- one registry INSERT into ops.alert_policy.
-- SUPERSEDES nothing; does NOT redefine ops.sp_auto_resolve_alerts (bigquery/134 remains current).
--
-- ============================================================================
-- WHY
-- ============================================================================
-- On 2026-08-04 AR_att raised ops.alerts d4aca178-d84e-4f1b-90bd-5137f5c552f2, category
-- 'prompt_injection_attempt' -- the FIRST of its kind in the system's history. An adversarial-review
-- sub-agent was fed a spoofed system-reminder claiming its scratch findings file had been edited by
-- "the user or a linter", offering substitute findings that referenced a short-leg / stop-distance /
-- shorted-name mechanic. Strategy A is long-only with no price-based stop (strategy/03_strategy_a.md),
-- so the substitute content described machinery that does not exist. The agent identified it as an
-- injection, rejected it, and rebuilt the review from the permitted artifact alone. AR_att's STRICT
-- BLINDING wall (task_plan/AR_att.md) is what made the injected content detectable as foreign.
--
-- Contamination independently re-verified during 2026-08-04 triage: all 10 adversarial-review rows
-- written that day were pulled from events.adversarial_reviews and searched for the injected
-- concepts; premortem-A-2026-a3's body_md was additionally read in full rather than regex-scanned.
-- Zero traces. (Strategies C and E legitimately reference short legs and a 25% short stop -- that is
-- real documented machinery in Experiment_Parameters.md, not injected content.)
--
-- ============================================================================
-- THE GAP THIS CLOSES
-- ============================================================================
-- The class WORKED but was completely undeclared. Before this file:
--   * grep for 'prompt_injection_attempt' across the entire repo returned ZERO hits -- no schema,
--     no docs, no runbook, no policy row. The category existed only as a string literal a routine
--     invented at raise time.
--   * It was latching only BY ACCIDENT OF ABSENCE. ops.sp_auto_resolve_alerts gates all six of its
--     rules on `category IN (SELECT category FROM ops.alert_policy WHERE NOT latching)`, so an
--     unregistered category cannot auto-resolve. Correct behaviour, reached by omission rather than
--     by decision -- and a future session adding a well-meaning row without `latching = TRUE` would
--     silently make a SECURITY alert auto-resolvable.
--   * No responder had a written procedure. A first-of-kind security signal that nobody has told
--     anybody how to handle is a signal that will eventually be mishandled.
--
-- Registering it with latching = TRUE is a DOUBLE LOCK, strictly safer than absence: the category
-- has no matching rule in the procedure AND is excluded by every rule's `WHERE NOT latching` filter.
-- The row is inert to the auto-resolver by construction; its whole job is to make the decision
-- explicit, discoverable and hard to reverse by accident.
--
-- WHY NOT AUTO-RESOLVE IT. Every other latching-FALSE category in this table resolves on a MECHANICAL
-- fact -- an upstream completed, an email was delivered, a freshness view went green. There is no
-- mechanical fact that means "an injection attempt was harmless". That judgement requires reading the
-- artifacts the agent actually wrote and confirming the injected content is absent, which is a human
-- or deliberate-session act. A security alert that clears itself teaches the operator to ignore it.
--
-- ============================================================================
-- REGISTER THE CATEGORY (idempotent -- NOT EXISTS on category)
-- ============================================================================
INSERT INTO `stock-trading-498512.ops.alert_policy` (category, latching, resolve_rule, note)
SELECT p.category, p.latching, p.resolve_rule, p.note
FROM UNNEST([
  STRUCT('prompt_injection_attempt' AS category, TRUE AS latching,
         'NEVER auto-resolves. Requires a deliberate human-or-session review that (a) identifies the injection vector, (b) enumerates every artifact the affected agent wrote in that fire, and (c) searches those artifacts for the injected content and records the result. Resolve by hand with UPDATE ops.alerts SET resolved=TRUE, resolved_note=<what was checked and what was found>, scoped by alert_id.' AS resolve_rule,
         'SECURITY CLASS, first raised 2026-08-04 by AR_att (alert d4aca178-d84e-4f1b-90bd-5137f5c552f2, a spoofed system-reminder claiming a scratchpad findings file had been edited). Registered 2026-08-04 with latching=TRUE so the no-auto-resolve posture is DECLARED rather than an accident of absence -- ops.sp_auto_resolve_alerts gates every rule on `WHERE NOT latching`, so this row is a double lock and can never make the class auto-resolvable. Raise at warning, not critical: an open critical sets state.trading_enabled=FALSE (bigquery/107), and a rejected injection against a review agent is not a reason to halt order staging -- the blinding walls contained it. Escalate to critical ONLY if injected content is found to have reached a written artifact, a staged order, or a roster mutation. Response procedure lives in Claude_Task_Plan.md, AR_att section.' AS note)
]) AS p
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.ops.alert_policy` ap WHERE ap.category = p.category
);

-- ============================================================================
-- VERIFICATION (run manually after apply)
-- ============================================================================
-- 1) The row exists exactly once and is LATCHING:
--
-- SELECT category, latching FROM `stock-trading-498512.ops.alert_policy`
-- WHERE category = 'prompt_injection_attempt';
-- -- EXPECT exactly 1 row, latching = true
--
-- 2) It is NOT visible to any auto-resolve rule (every rule filters on NOT latching):
--
-- SELECT COUNT(*) AS visible_to_autoresolve
-- FROM `stock-trading-498512.ops.alert_policy`
-- WHERE NOT latching AND category = 'prompt_injection_attempt';
-- -- EXPECT 0
--
-- 3) Registering the category did NOT retroactively resolve the live alert:
--
-- SELECT alert_id, resolved, resolved_note FROM `stock-trading-498512.ops.alerts`
-- WHERE category = 'prompt_injection_attempt';

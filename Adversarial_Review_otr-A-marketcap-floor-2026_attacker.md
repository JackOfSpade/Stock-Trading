# Adversarial Review — otr-A-marketcap-floor-2026 (attacker)

- **id:** otr-A-marketcap-floor-2026
- **review_type:** out-of-table-resolution
- **strategy:** A
- **date:** 2026-07-29
- **cycle_number:** 1
- **artifact:** Annual_AI_Foundation_Sweep.md

## Verdict
HOLD

## Findings

### F1 — The artifact never performs the re-derivation route (a) asks for
**Anchor:** "re-derive whether the $2B floor survives on grounds other than 2.3 (liquidity, spread, borrow, index membership, catalyst-coverage density), and if it does, re-annotate it to cite those grounds instead" (Annual_AI_Foundation_Sweep.md:971)
§F.2's Strategy A section poses exactly this question but does not answer it — it hands the question forward ("A2 constraint-audit question") rather than resolving it in-artifact. Line 969's mention that "A's liquidity requirement is carried separately by the adjacent `30-day ADV ≥ $10M` criterion" establishes that liquidity is *already* covered by a *different, separate* entry criterion — it is evidence that the $2B floor is not needed to carry liquidity (i.e., points toward the floor having no independent liquidity rationale), not an affirmative re-derivation of the floor itself on liquidity grounds. None of spread, borrow, index membership, or catalyst-coverage density are addressed anywhere in the read regions. Route (a) is not satisfied.

### F2 — trigger_context confirms the escalation chain terminated before reaching re-derivation
**Anchor:** "A2 audit terminated at Step 1 for every constraint (zero disadvantages classified as reduced), so it never reached that re-derivation" (trigger_context)
This is a direct statement that the one process step designed to attempt route (a) — the A2 constraint audit — did not execute for this constraint. There is no re-derivation attempt anywhere upstream of this review to inherit a result from. This is consistent with F1.

### F3 — Route (b) (correct the stated rationale, hold the value) is not decided anywhere in the artifact either
**Anchor:** "if it survives on no other grounds, that is an out-of-table flag for the autonomous out-of-table-resolution review with conservative default HOLD the constraint at its current value" (Annual_AI_Foundation_Sweep.md:971)
The artifact frames the fork (survives on other grounds → re-annotate; survives on no other grounds → out-of-table flag with default HOLD) but does not itself choose "correct the rationale, keep the value" as a resolution — it explicitly defers that choice to this review under a conservative default. Deciding that the *stated* rationale (2.3's market-cap direction) should now be swapped for some *other, unstated* rationale is itself a judgment call requiring identification of which alternative ground (liquidity/spread/borrow/index-membership/catalyst-coverage) actually applies and by how much — and per F1, no such ground is derived or even attempted in what is available. A non-adversarial out-of-table-resolution pass, whose only license is to check for *objective, already-present* criteria, cannot manufacture that derivation itself.

### F4 — The reversed finding driving the trigger is explicitly qualified as unverified for Claude
**Anchor:** "The L4 market-cap reversal has no Claude replication at any level, so it transfers on architectural-generality grounds only — the direction is now clear in the general-LLM literature, but the claim *about Claude specifically* is unverified in either direction." (Annual_AI_Foundation_Sweep.md:273); "unverified for Claude specifically" (trigger_context)
This weakens any argument for resolving now in either direction. Even if one wanted to lean on the reversal to justify a rationale correction, the reversal's own evidentiary status (§5.5 guardrail-1 failure, single paper, no Claude in panel — Annual_AI_Foundation_Sweep.md:270,273) is exactly the kind of unresolved uncertainty that argues for holding rather than acting.

### F5 — The artifact itself repeatedly instructs against treating this as license to act
**Anchor:** "Do not relax or remove the $2B floor on the strength of this finding" (Annual_AI_Foundation_Sweep.md:971); "a contradicted rationale makes a constraint potentially UNMOTIVATED, not over-tight" (trigger_context, echoing Annual_AI_Foundation_Sweep.md:525's parallel treatment of 2.17: "Do not read a contradicted disadvantage as a reduced disadvantage")
The artifact's own internal precedent (2.17, §2.17 note at line 525) treats a directionally-contradicted rationale as grounds for flagging a review, not for independently resolving the constraint. This review's finding is consistent with that precedent: contradiction is not resolution.

## Objective-criteria assessment

### Route (a) — affirmative re-derivation on other grounds
Not present. §F.2's Strategy A discussion (Annual_AI_Foundation_Sweep.md:965–971) poses the re-derivation question but explicitly routes it onward rather than answering it; trigger_context confirms A2 never reached the re-derivation step. Liquidity is addressed only to note it is carried by a *separate* criterion (the ADV floor), which is not an affirmative case for the $2B floor on liquidity grounds — if anything it is a data point *against* the floor having independent liquidity value. Spread, borrow, index membership, and catalyst-coverage density are not addressed at all in the read material. **Route (a) fails to resolve.**

### Route (b) — correct the stated rationale, hold the value
Facially attractive because it changes no live constraint value, but it is not objectively satisfiable from what's in front of this review. Correcting the rationale requires affirmatively naming a *different, correct* justification, which is precisely what route (a)'s re-derivation was supposed to supply and did not. Absent that, "correct the rationale" has no candidate rationale to substitute — there is nothing to write in its place, only the observation that the old one is contested. Concluding "hold the value" is compatible with the default; concluding "and update the citation" is not something this pass can do without performing the very re-derivation A2 skipped, which is out of scope for a non-adversarial resolution check. **Route (b) also fails to resolve as an in-scope objective determination**, though it correctly identifies the value itself as never in question.

## Explicit non-relaxation statement
A contradicted rationale makes the $2B floor potentially unmotivated, not over-tight. Nothing in the artifact or trigger_context licenses loosening, removing, or relaxing the $2B floor — the reversed 2.3 sub-claim is itself unverified for Claude specifically, single-source, and fails the sweep's own replication guardrail (§5.5 guardrail 1). This review's HOLD applies to the constraint's current value, unchanged.

## Self-imposed scope confirmation
I read only: `Annual_AI_Foundation_Sweep.md` (Grep for market-cap/hallucination/2.3 anchors; lines 255–284, 505–544, 940–984) and the trigger_context supplied in this task. I did not read: events.decision_log or any BigQuery state, prior adversarial reviews, AI_Trading_Foundation.md, Strategy.md or strategy slices, Experiment_Parameters.md, Annual_Constraint_Audit.md, Operating_Protocols.md, Claude_Task_Plan.md, git history, or any other repo file. No web search was performed.

## Reasoning
This review_type is non-adversarial by protocol: the task is not to attack the constraint or the artifact but only to check whether objective, already-present criteria clearly resolve the out-of-table question. They do not. The artifact (§F.2, Strategy A) surfaces the problem precisely and correctly declines to resolve it in-line, deferring to A2 (which terminated before reaching the re-derivation step, per trigger_context) and then to this review with an explicit conservative default of HOLD. Route (a) has no re-derivation to point to. Route (b) is superficially a documentation-only fix but actually requires the same missing re-derivation to name a replacement rationale, so it cannot be executed as a mechanical, judgment-free step either. The reversed finding driving the whole question is itself flagged unverified for Claude and single-source, which further removes any pressure to act now rather than wait for a proper re-derivation or Claude-panel replication. The default therefore stands: HOLD the $2B floor at its current value, with the rationale annotation left as-is pending a future, actual re-derivation (which this review is not positioned to perform). This finding does not read as, and must not be read as, an argument for loosening the constraint.

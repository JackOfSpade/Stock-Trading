# Adversarial Review — otr-F5-cadence-criteria-2026 (attacker)

- **id:** otr-F5-cadence-criteria-2026
- **review_type:** out-of-table-resolution
- **strategy:** n/a
- **date:** 2026-07-29
- **cycle_number:** 1
- **artifact:** Annual_Constraint_Audit.md

## Verdict
HOLD

## Findings
### F1 — resolves_when describes future authoring work, not a present condition
**Anchor:** "Either the promised per-purpose mechanical criteria are authored, or 5.6 is amended to state that cadence rules hold pending an explicit owner-directed change" (trigger_context, resolves_when)
Both branches of the stated resolution condition are actions that have not occurred as of this review. Neither the artifact nor trigger_context contains authored per-purpose mechanical criteria for any cadence rule, nor an amendment to §5.6's text. A `resolves_when` phrased as future work is itself evidence against present resolution, per the protocol's own bar.

### F2 — the artifact confirms the criteria remain an unfilled forward reference
**Anchor:** "§5.6 routes cadence rules to 'explicit review at the annual constraint audit (A2) with mechanical criteria specific to the cadence rule's purpose.' Those criteria do not exist in any document." (Annual_Constraint_Audit.md:581)
§2.5's own F-5 finding states plainly that the referenced criteria "do not exist in any document" and that the branch "currently reduces to 'hold and confirm.'" This is a direct, artifact-authored statement that no mechanical criteria are available to apply — it forecloses any reading in which the artifact itself supplies the missing criteria.

### F3 — the artifact's own recommendation is phrased as an unexecuted choice, not a resolution
**Anchor:** "Recommendation (default HOLD): either author the criteria or amend §5.6 to state that cadence rules hold pending an explicit owner-directed change." (Annual_Constraint_Audit.md:581)
The audit explicitly labels its own suggestion a "Recommendation" under a stated "default HOLD," not an action taken. Nothing in §2.4 or §2.5 shows either recommended path executed — no criteria are authored anywhere in the reviewed sections, and no §5.6 amendment is quoted or referenced as having occurred.

### F4 — the two rules with citations still terminate at Step 1, adding no operative criteria
**Anchor:** "The 2 that do (C-C-43 -> 2.12 Tier 1; C-D-29 -> 2.8, Tier 2 but classified NONE and monitoring-only since Rev 35 removed its blocking behaviour) both terminate at Step 1." (trigger_context)
Even the two cadence rules with recoverable foundation citations do not reach a point where mechanical cadence-specific criteria would need to be applied — they stop at Step 1 (citation/classification), never reaching a step where the promised "criteria specific to the cadence rule's purpose" would fire. This reinforces that no instance in the current record supplies or tests such criteria; there is nothing to point to as "already satisfied."

## Objective-criteria assessment
No. Neither trigger_context nor the artifact (§2.4, §2.5) contains an objective, already-satisfied criterion resolving this item. The `resolves_when` payload names two possible future actions (author criteria; amend §5.6), and the artifact independently confirms neither has happened — the criteria "do not exist in any document" and the audit's own text is a recommendation under an explicit "default HOLD," not an executed amendment. The gap is exactly what F-5 describes: an unfilled forward reference with nothing to mechanically check it against. Default HOLD stands.

## Kill-trigger boundary (recorded, not decided)
Trigger_context explicitly flags that D's cadence rules (trading frequency C-D-25/C-D-26 and review cadence C-D-27…C-D-35) are load-bearing on the kill-trigger path, that §5.6 does not relax them, and that `Experiment_Parameters.md` marks them globally immutable. D's own mechanism record (quoted in §2.4) states its 30-trade gate "will likely not be reached within any stable model-generation window" and calls this "an accepted, documented property, not a flaw." Any future resolution of F-5 — whether by authoring generic per-purpose mechanical criteria or by amending §5.6's hold language — must carve out D's kill-trigger-path cadence rules and not treat them as ordinary relaxable cadence rules subject to whatever criteria get authored. This review takes no position on how that carve-out should be drafted; it only records that a resolution silent on this point would be unsafe.

## Self-imposed scope confirmation
I read only: `Annual_Constraint_Audit.md` §2.4 (lines 500-511) and §2.5 (lines 513-607, covering F-1 through F-6 and the A3 handoff table), plus the trigger_context provided in the task. I did not read: events.decision_log or any BigQuery state, prior adversarial reviews, AI_Trading_Foundation.md, Strategy.md or strategy slices, Experiment_Parameters.md, Annual_AI_Foundation_Sweep.md, Operating_Protocols.md, Claude_Task_Plan.md, git history, or any other repo file.

## Reasoning
Per the routine spec, `out-of-table-resolution` triage is deliberately non-adversarial — the job here is only to check whether trigger_context plus the artifact already contain an objective, presently-satisfied criterion that resolves F-5, not to construct or recommend one. The `resolves_when` condition given in the entry is itself forward-looking ("are authored," "is amended") — grammatically and substantively describing work not yet done. Cross-checking against the artifact confirms this: §2.5's F-5 text states the criteria "do not exist in any document," and the audit frames its own suggestion as a "Recommendation" under "default HOLD," not as an accomplished fact. There is no third reading available under the strict-blinding scope that would supply a satisfied criterion. The kill-trigger note in trigger_context is recorded as a boundary condition for whoever eventually resolves F-5, consistent with the instruction to note it "without deciding it." Conclusion: the default holds — HOLD.

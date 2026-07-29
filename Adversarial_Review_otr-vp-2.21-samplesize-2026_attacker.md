# Adversarial Review — otr-vp-2.21-samplesize-2026 (attacker)

- **id:** otr-vp-2.21-samplesize-2026
- **review_type:** out-of-table-resolution
- **strategy:** n/a
- **date:** 2026-07-29
- **cycle_number:** 1
- **artifact:** Annual_AI_Foundation_Sweep.md (§2.21)

## Verdict
HOLD

## Findings

### F1 — 2.21 is confirmed Tier 1, outside the document-wide blanket flip
**Anchor:** "### 2.21 Minimum viable sample size constraint [Tier 1] — FULL traversal (bears the 96/216/370 figures)" (Annual_AI_Foundation_Sweep.md:587)
The section header itself tags 2.21 as `[Tier 1]`, not Tier 2. The document's blanket flip mechanism (Part 4 step 4, referenced generically elsewhere in the artifact) applies to Tier 2 numerical claims document-wide; 2.21 sits outside that mechanism by its own header tag. This matches trigger_context's framing that 2.21 is "flagged here on its own per-item grounds," scoped only to the three figures, not swept in by the blanket flip.

### F2 — The defect is scoped to exactly three unsourced integers, not the qualitative claim
**Anchor:** "The underlying relationship is nonetheless well-supported in standard statistical terms, independent of those numbers... Carrying three unsourced precise integers in a document that gates strategy validation is the defect." (Annual_AI_Foundation_Sweep.md:590, 594)
The artifact itself separates the qualitative statistical relationship (sample size scales with variance, fat tails invalidate CLT heuristics, etc. — line 590) from the three specific integers 96 / 216+ / 370+, which are independently confirmed untraceable ("Two agents searched separately... None cites 96, 216 or 370 as a package; none traces to an academic or regulatory primary source" — line 589). The qualitative claim is not flagged as deficient anywhere in §2.21; only the three integers are tagged `ABSENT-FROM-RECENT-RESEARCH [all levels]` (line 594).

### F3 — Neither resolution route is satisfied in the artifact as it stands
**Anchor:** "A3 should either derive the figures explicitly from stated assumptions (edge size, per-trade variance, confidence level) so they become reproducible, or replace them with the qualitative claim plus a worked example." (Annual_AI_Foundation_Sweep.md:594)
This sentence is phrased as a forward-looking instruction to a future actor (A3), not a report of completed work. §2.21's own text (lines 587–594) contains: (a) the untraceability finding, (b) the qualitative statistical relationship in prose, and (c) the remedy instruction — but no stated assumptions (no effect size, no per-trade variance figure, no power/confidence level chosen) and no worked numeric example computing toward 96, 216, or 370 (or any substitute figures). The generic statistical mechanisms named ("required sample size scales with per-trade variance and inversely with the square of desired precision," etc.) are standard textbook relationships, not a derivation instantiated with this experiment's numbers — consistent with the entry's own caution that standard arithmetic being available does not make the specific integers derived.

### F4 — Downstream reconciliation entry (item 18) restates the same not-yet-done remedy
**Anchor:** "18. **2.21** — Retain the qualitative claim; mark the 96 / 216+ / 370+ figures as untraceable and either derive them explicitly from stated assumptions... or replace them with the qualitative claim plus a worked example." (Annual_AI_Foundation_Sweep.md:868)
This is the artifact's own disposition-table restatement of the identical directive, again in imperative/future form ("Retain," "mark," "derive... or replace"), confirming this is a planned citation-integrity fix rather than an executed one. No later passage within the read scope (§2.21, lines 587–597, and the ~594 passage) shows the fix as completed.

## Scope confirmation — three numbers only, outside the blanket flip
Confirmed directly from the artifact: the §2.21 header (line 587) reads `[Tier 1]`, not `[Tier 1 existence / Tier 2 magnitudes]` as used elsewhere (e.g. 1.3, 1.7, 2.4, 2.14, 2.15 headers carry the dual tag). This places 2.21 outside the document-wide Part 4 step 4 blanket flip, which by trigger_context and the artifact's own framing applies to Tier 2 magnitudes. The defect here is scoped strictly to the three figures 96 / 216+ / 370+ (line 594, "the three specific figures" per line 592's cross-level verdict). The qualitative claim — that a minimum viable sample size exists and is large relative to this experiment's trade counts — is treated in the artifact as a settled, well-supported statistical fact (line 590) and is explicitly not in question.

## Objective-criteria assessment

### Route — explicit derivation from stated assumptions
Not present. §2.21 names the general statistical mechanisms (variance scaling, CLT invalidation under fat tails/serial dependence, heteroskedasticity from proportional sizing, multiple-testing inflation — line 590) but states no concrete assumption values (no effect size, no per-trade variance number, no chosen confidence/power level) and performs no computation connecting those assumptions to 96, 216, or 370 (or replacement figures). A derivation satisfying resolves_when route one would need those inputs stated and the arithmetic shown; neither appears.

### Route — qualitative claim plus a worked example
Partially present, not complete. The qualitative claim is present and is not in dispute (line 590). A "worked example" — a concrete numeric illustration deriving a sample-size figure from stated inputs — is absent. The instruction to add one (line 594, restated at line 868) is prospective ("A3 should... derive... or replace... with... a worked example"), directed at a future actor, not a description of content already in the section.

## Self-imposed scope confirmation
I read only: Annual_AI_Foundation_Sweep.md §2.21 (lines 587–597), the ~line 594 passage, a small number of grep-located context lines from the same file (lines 66–1072, matched via keyword search for "2.21", "Tier 2", "minimum viable sample size" — used only to locate and confirm the section boundaries, the Tier tag, and the reconciliation-table restatement at line 868, all within the same artifact), and the trigger_context provided in this task. I did not read: events.decision_log or any BigQuery state, prior adversarial reviews, AI_Trading_Foundation.md, Strategy.md or strategy slices, Experiment_Parameters.md, Operating_Protocols.md, Claude_Task_Plan.md, Annual_Constraint_Audit.md, git history, or any other repo file.

## Reasoning
This review_type is explicitly non-adversarial by protocol: the task is only to surface whether trigger_context plus the artifact contains objective criteria that clearly resolve the item, not to attack or stress-test the finding. Applying that narrowly: the artifact confirms the scope claim (2.21 is Tier 1, outside the blanket flip, defect limited to three integers) and confirms the qualitative claim is settled and not at issue. But on the actual resolves_when test, the artifact does not itself contain a completed derivation from stated assumptions, nor does it contain a completed worked example alongside the qualitative claim — it contains only the untraceability finding, the settled qualitative claim, and a forward-looking instruction to produce one of those two remedies. Since resolves_when requires the figures to already be derived/reproducible or already replaced with a worked example, and neither has occurred within the readable scope, there is no objective basis to flip this item to RESOLVE. The default HOLD stands.

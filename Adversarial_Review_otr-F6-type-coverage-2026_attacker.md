# Adversarial Review — otr-F6-type-coverage-2026 (attacker)

- **id:** otr-F6-type-coverage-2026
- **review_type:** out-of-table-resolution
- **strategy:** n/a
- **date:** 2026-07-29
- **cycle_number:** 1
- **artifact:** Annual_Constraint_Audit.md

## Verdict
HOLD

## Findings
### F1 — resolves_when asks for a decision, not a criterion
**Anchor:** trigger_context — "A decision on whether exit triggers and regime gates warrant their own 5.6 rows (both would most likely be no-automatic-relaxation, which resolves the volume problem cleanly)"
The payload's own `resolves_when` is phrased as a decision to be *taken*, not a fact to be checked. "Would most likely be" is the artifact's own hedge (§2.5, F-6 recommendation: "Recommendation (default HOLD): consider whether exit triggers and regime gates warrant their own §5.6 rows (both would most likely be 'no automatic relaxation' …)"). A prediction of a likely outcome is not the outcome having occurred. No document records that §5.6 has actually been amended to add exit-trigger or regime-gate rows, or that a "no automatic relaxation" verdict has actually been assigned to either category.

### F2 — No objective trigger exists in trigger_context or the artifact
**Anchor:** Annual_Constraint_Audit.md:589 — "Recommendation (default HOLD): consider whether exit triggers and regime gates warrant their own §5.6 rows…"
Nothing in the artifact or trigger_context states a rule, threshold, or owner directive that would let this triage mechanically determine the answer today (e.g., no cited foundation revision adding such rows, no owner directive analogous to the F-1/F-2 same-day resolutions recorded elsewhere in §2.5). Taking the decision here — even adopting the "most likely" outcome — would be exercising discretion, which the protocol and 5.6's own no-discretion principle bar this path from doing.

### F3 — Scoping instruction is already satisfied and is separate from resolves_when
**Anchor:** trigger_context — "the 39 O-typed constraints are TYPED out-of-table but were never FLAGGED — no constraint passed Step 1 — and A3 must NOT enqueue individual out-of-table-resolution reviews for them. This single framework row is the correct representation."
This is a scoping instruction about *what not to enqueue*, already reflected in the entry (one framework row, not 39 per-constraint rows). It does not resolve F-6 itself; it only confirms the review's own shape is correct. Default HOLD stands independent of this point.

## Objective-criteria assessment
No. trigger_context contains a *description of the open decision* and a *prediction* about its likely resolution ("most likely be no-automatic-relaxation"), not an objective criterion already satisfied. The bar set by this protocol is an objective criterion satisfied *now* — e.g., a cited owner directive, a foundation-document amendment already in force, or a mechanical rule this triage can apply without judgment. None of these is present. Taking the decision here would itself be the discretionary act §5.6's "no discretion" principle and this review type's non-adversarial, decision-free charter both preclude. Default **HOLD** stands, unchanged.

## Coverage-claim verification (factual, from the artifact)
**Count consistency:** Verified independently by grepping the artifact's per-constraint tables for rows typed `O`. Sections 1.1–1.5 (per-strategy corpus, Strategies A–E) contain exactly 39 `O`-typed rows (A: 6, B: 5, C: 9, D: 8, E: 11 = 39), matching the "39" figure in F-6 exactly. A further 8 `O`-typed rows appear in §1.6 (experiment-level constraints X-02, X-03, X-05–X-10), but §1.6 explicitly states these "are not per-strategy constraints" and are inventoried separately from the corpus — so they are correctly excluded from the 201-constraint denominator. 39/201 = 19.4%, which rounds to the stated "19%". The artifact's own numbers are internally consistent, and this independently reproduces the headline count rather than merely trusting the artifact's arithmetic.

**Category non-reducibility:** Scanning the 39 O-typed rows' descriptions confirms the five named out-of-table categories are real and distinct from the five §5.6 types (sizing/universe/concentration/cadence/threshold): exit triggers ("Exit — thesis completion/invalidation," "12-month hard time stop," "convergence target reached," time-based exits), regime-router activation gates ("Router — SPY Trend UP and Breadth HEALTHY," "Router — SPY≠DOWN AND VIX≠HIGH…"), execution-integrity mechanics ("Partial exit — both legs proportionally, no naked leg"), verification requirements ("Dual-path verification (closed-form vs Monte Carlo)"), and computation-method-selection ("Classical-method delegation (all numerical work to code)") all appear verbatim among the O rows and plainly do not fit sizing, universe, concentration, cadence, or threshold. A handful of O-typed rows are less clean fits for the five named subcategories specifically (e.g., "borrow-rate cap >10% annualized → close," "Probe-stake floor $2,000," "Capital-allocation split bound") — these read closer to threshold/sizing-adjacent rules that were nonetheless typed O rather than reclassified — but this is a minor classification-boundary observation, not a challenge to the core claim: the five named categories are genuine and none of them collapses into any of the five §5.6 types.

## Self-imposed scope confirmation
I read only: Annual_Constraint_Audit.md (§2.5, lines 515–598, including the F-6 entry and A3 handoff table) and the §1.1–§1.6 per-constraint tables (grepped for `| O |` rows to obtain O-typed counts, sections spanning roughly lines 74–360), plus the trigger_context provided in the task prompt. I did not read: events.decision_log or any BigQuery state, prior adversarial reviews, AI_Trading_Foundation.md, Strategy.md or strategy slices, Experiment_Parameters.md, Annual_AI_Foundation_Sweep.md, Claude_Task_Plan.md, Operating_Protocols.md, git history, or any other repo file.

## Reasoning
Per protocol, `out-of-table-resolution` reviews are non-adversarial by design: the sole task is to check whether an objective, already-satisfied criterion resolves the item, and to hold otherwise. Here the item's own `resolves_when` field names a *pending decision* ("a decision on whether exit triggers and regime gates warrant their own 5.6 rows"), which by construction cannot be an objective criterion already met — a decision not yet taken cannot simultaneously be evidence that it has been taken. The artifact reinforces this by phrasing its own recommendation as a hedge ("would most likely be"), not an accomplished fact. Adopting that likely outcome here would require this triage to exercise the very discretion that both this review type's charter and §5.6's "no discretion" principle place off-limits. Separately, the factual coverage question I *can* assess from the artifact — whether the 39/201/19% figures are internally consistent and whether the five named out-of-table categories are genuinely distinct from the five §5.6 types — checks out on independent verification against the constraint tables, which gives a future resolver a solid, already-confirmed factual basis to work from when the actual decision is eventually made (by an appropriately authorized process, not this triage).

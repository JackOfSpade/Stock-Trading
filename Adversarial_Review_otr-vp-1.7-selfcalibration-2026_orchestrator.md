# Adversarial Review — otr-vp-1.7-selfcalibration-2026 (orchestrator)

- **id:** otr-vp-1.7-selfcalibration-2026
- **review_type:** out-of-table-resolution
- **strategy:** n/a
- **date:** 2026-07-30
- **cycle_number:** 1
- **artifact:** Annual_AI_Foundation_Sweep.md §1.7 (lines 192–202), cross-checked against AI_Trading_Foundation.md §1.7 (lines 160–172) and Experiment_Parameters.md (lines 69–71)
- **attacker_output:** Adversarial_Review_otr-vp-1.7-selfcalibration-2026_attacker.md

## Final verdict
HOLD — neither objective resolution route (`resolves_when`: "NEW RESEARCH, or an explicit in-document derivation of the thresholds from stated assumptions") is met; the version-pending flag on the "30+/200+ outcomes per category" thresholds stays in force unchanged.

## Theater-check flag
CONVERGENT — but substantively so, not by default. I independently re-verified every anchor the attacker cites (Annual_AI_Foundation_Sweep.md:198, :201, :886) against the live file and all three quote exactly. I also went outside the attacker's blind (AI_Trading_Foundation.md, Experiment_Parameters.md, sibling item 2.21) specifically looking for a derivation or citation the attacker could not have seen, and found none — only a second, equally citation-less restatement of the same claim (Experiment_Parameters.md:69) and a structural precedent (2.21) that confirms rather than undermines the HOLD. Agreement here tracks the actual state of the repo, not recycled framing.

## (a) Validity assessment of each attacker finding

### F1 — No new research is present or citable
**Supports HOLD, valid.** Anchor checked verbatim at Annual_AI_Foundation_Sweep.md:198 ("L3 — ABSENT for the thresholds. L4 — ABSENT for the thresholds. Two agents searched independently.") — holds exactly. `trigger_context` (pulled fresh from `events.queue_events` this pass) introduces no new citation either; it only restates the A3 due-date housekeeping correction, unrelated to route content. Route 1 is unmet.

### F2 — No explicit in-document derivation from stated assumptions exists
**Supports HOLD, valid, and the strongest finding.** Anchor at :198 checked verbatim. The attacker's three-input breakdown (edge size / per-trade variance / confidence level, per `resolves_when`) is correctly applied: the passage supplies only a confidence level (95%) and an assumed p≈0.5, sourced externally and explicitly flagged as "not tied in any retrievable source to 'calibration category tracking,'" and reaches neither the 30 nor the 200 figure by any shown arithmetic. I searched the rest of the repo for a derivation the blinded attacker could not reach (see (c)) and found none.

### F3 — The document explicitly forecloses treating this as a magnitude defect
**Supports HOLD, valid.** Anchors checked verbatim: line 201 ("Materially different from 'wrong'; A3 must not treat it as a magnitude to be replaced") and line 886 ("substantively correct, spuriously precise"). Both match exactly. This correctly establishes the defect class as citation/reproducibility, not correctness — which matters because it forecloses one plausible resolution shortcut (just replace the numbers) that a less careful reviewer might have reached for.

## (b) Theater in the attacker's output
None material. All three anchors check out verbatim against the live file, the reasoning is specific rather than generic (F2 in particular decomposes `resolves_when`'s three named inputs and checks each individually rather than pattern-matching on "absence found = HOLD"), and the guard-compliance section correctly self-polices against the one failure mode this review type is most likely to produce (conflating "untraceable" with "wrong"). I looked specifically for padding or recycled boilerplate given this is cycle 1 with no prior cycles to recycle from — found none; the self-imposed scope confirmation is unusually precise about exactly which lines and grep hits it did and did not read, which is verifiable discipline rather than a generic disclaimer.

## (c) Weaknesses the attacker missed
The attacker was correctly scoped to §1.7 alone per its blind, so it could not see two things visible only from the de-blinded view — neither changes the verdict, but both are worth recording:

1. **The same unresolved claim recurs as a live premise elsewhere, and is equally uncited there.** Experiment_Parameters.md:69 states: "Research on minimum viable sample sizes for strategy validation shows that proving a 2% per-trade edge with 95% confidence requires 200+ independent trades" — this is the operative justification for the experiment's own 30-trade gate design, not a footnote. It supplies an edge size (2%) and confidence level (95%) that §1.7 itself lacks, but it attributes the 200+ figure to external "research" rather than deriving it in-document, and that external research is exactly what §1.7 records as ABSENT at L3/L4. So this is not a qualifying derivation either — it is a second, independent instance of the identical citation gap, now load-bearing for the experiment's success-threshold design rather than merely descriptive. This raises the practical stakes of the HOLD (this isn't an isolated footnote) without supplying grounds to flip it.

2. **A sibling item (2.21, same ABSENCE class, explicitly cross-referenced at Annual_AI_Foundation_Sweep.md:593 "As with 1.7") was handled differently, and that difference confirms 1.7's guard is doing real work.** AI_Trading_Foundation.md:373-393 shows 2.21's specific integers (96/216/370 trades) were already withdrawn from the prose pending its own separate `out-of-table-resolution` review (`otr-vp-2.21-samplesize-2026`, also default-HOLD per line 391) — the qualitative claim was kept, the precise numbers were pulled. §1.7's numbers, by contrast, remain in the text verbatim at AI_Trading_Foundation.md:171 ("30+ ... 200+ outcomes per category"), consistent with its explicit "must not treat it as a magnitude to be replaced" guard (line 165 quotes this verbatim, confirming the guard has actually been honored downstream, not just stated in the sweep). This is a real, deliberate distinction in how the framework treats these two same-class defects, not an inconsistency — F3 identified the guard's existence correctly but had no way to check that it was actually being followed elsewhere; I checked, and it is.

No finding here weighs toward RESOLVE; if anything, (1) shows the unresolved claim is more consequential than the attacker's narrow read suggested, and (2) shows the framework is behaving consistently with its own stated constraint.

## (d) Verdict reasoning
This review type is non-adversarial triage with a stated default (HOLD) and a high, objective bar for RESOLVE: the resolving fact must already be present, not something this pass would have to construct. Both named routes fail on inspection:

- **Route 1 (new research):** absent. Two independent search agents came up empty at L3/L4 per the artifact's own text; `trigger_context` supplies nothing new; my own read of every adjacent document (AI_Trading_Foundation.md, Experiment_Parameters.md) surfaces only restatements of the same unsourced claim, never a citation.
- **Route 2 (explicit in-document derivation from stated assumptions):** absent. No passage in the artifact or its governing documents states an edge size AND a per-trade-variance assumption AND a confidence level AND shows algebra connecting them to either 30 or 200. The closest candidates (Annual_AI_Foundation_Sweep.md:198's externally-sourced binomial aside; Experiment_Parameters.md:69's "2%/95%" restatement) each supply at most a subset of the required inputs and neither performs a shown derivation reaching the specific thresholds — they assert, they don't derive.

Since neither route is objectively satisfied, and satisfying either would require me to supply the missing derivation or citation myself (out of scope for this review type by the briefing's own terms — "if resolving would require you to invent, choose, or derive... HOLD"), the default stands.

**Non-relaxation statement:** This HOLD is not a finding against the "30+/200+ outcomes per category" thresholds and does not license replacing, rounding, or deleting them. Per the artifact's own guard (line 201, honored downstream at AI_Trading_Foundation.md:165), the defect is citation/reproducibility, not magnitude, and the underlying binomial-sampling logic is affirmatively endorsed as standard and substantively correct. Nothing in this review moves the thresholds, and nothing in this review should be read by a future A3 pass as grounds to treat them as a "magnitude to be replaced."

## (e) Action taken
Verdict HOLD is recorded for `otr-vp-1.7-selfcalibration-2026`; the current version-pending state of Annual_AI_Foundation_Sweep.md §1.7 / AI_Trading_Foundation.md §1.7 is left undisturbed and the item stays queued for re-surfacing at the next review cycle per standing protocol. No BigQuery write and no git operation is performed by this review — the orchestrating session performs the corresponding `events.decision_log` / `events.queue_events` state transition.

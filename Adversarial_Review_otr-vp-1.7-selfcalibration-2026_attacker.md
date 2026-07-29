# Adversarial Review — otr-vp-1.7-selfcalibration-2026 (attacker)

- **id:** otr-vp-1.7-selfcalibration-2026
- **review_type:** out-of-table-resolution
- **strategy:** n/a
- **date:** 2026-07-29
- **cycle_number:** 1
- **artifact:** Annual_AI_Foundation_Sweep.md (§1.7)

## Verdict
HOLD

## Findings
### F1 — No new research is present or citable
**Anchor:** "L3 — ABSENT for the thresholds. L4 — ABSENT for the thresholds. Two agents searched independently." (Annual_AI_Foundation_Sweep.md:198)
§1.7 itself states the thresholds are untraceable at L3/L4 after two independent search attempts. Nothing in trigger_context or the surrounding artifact text introduces a new citation, dataset, or study that would satisfy the "NEW RESEARCH" route. I am also blinded from web search, and none is cited in-document, so this route is plainly unmet.

### F2 — No explicit in-document derivation from stated assumptions exists
**Anchor:** "textbook binomial-proportion-CI arithmetic (n ≈ 200 gives roughly ±7% margin at 95% for p ≈ 0.5), standard statistics but not tied in any retrievable source to 'calibration category tracking.'" (Annual_AI_Foundation_Sweep.md:198)
This is the closest thing to a derivation anywhere in the section, but it is offered as "nearest material" found during an *external* search (L4), not as an in-document derivation performed by the artifact from 1.7's own stated assumptions. Critically, it supplies only one of the three inputs `resolves_when` asks for (confidence level = 95%, and an assumed p≈0.5) — it does not state or derive an **edge size** or **per-trade variance** specific to the trading context, and it does not connect the resulting margin back to a justified "30+" directional-signal threshold at all. The 30+ figure is not addressed by any arithmetic in the passage. There is no worked derivation section, formula, or stated-assumptions block anywhere in §1.7 or its surroundings (lines 192–202) that ties inputs to outputs.

### F3 — The document explicitly forecloses treating this as a magnitude defect
**Anchor:** "Materially different from 'wrong'; A3 must not treat it as a magnitude to be replaced." (Annual_AI_Foundation_Sweep.md:201)
The artifact's own guard, plus its characterization "substantively correct, spuriously precise" (line 886) and "mathematically standard but citation-less as stated" (line 201), together establish that the defect class is reproducibility/citation, not correctness. This confirms the resolution bar is a derivation-or-citation bar, not a replace-the-number bar — and no such derivation is present (F2), so the bar is not met.

## Objective-criteria assessment
### Route — new research
Not present. §1.7 records two independent L3/L4 search attempts, both coming up empty for the specific thresholds. Trigger_context adds no new citation. Blinding prevents me from checking further, and per protocol I must not go looking — recorded as a self-containment non-finding, not evidence either way, but irrelevant since this route requires something to be *present* and nothing is.

### Route — explicit in-document derivation
Not present. What §1.7 contains is: (a) a statement that the thresholds are untraceable to any source (L3/L4 both ABSENT), and (b) a single external, partial statistical fact ("n≈200 → ±7% margin at 95% for p≈0.5") explicitly flagged as *not tied to* calibration-category tracking by any retrievable source. That is not an in-document derivation "from stated assumptions (edge size, per-trade variance, confidence level)" as `resolves_when` requires — no edge size or per-trade variance appears anywhere in the section, and the 30+ figure has no arithmetic treatment at all. A qualifying derivation would need to: (1) state an assumed per-trade edge/effect size, (2) state an assumed per-trade outcome variance (or Bernoulli p), (3) state a target confidence level, and (4) show the algebra connecting those to both the ~30 (directional-signal) and ~200 (statistical-proof) figures. None of the four steps is present as an artifact-native derivation; step (3)/partial-(2) appear only as an externally-sourced aside explicitly disclaimed as unconnected to the claim.

## Guard compliance
This review does not assert or imply that the 30+/200+ figures are wrong. Per the artifact's own language, the binomial arithmetic underlying such thresholds is standard and the figures are "substantively correct, spuriously precise" — the defect is that the specific figures as stated in 1.7 carry no citation and no in-document derivation, i.e., a reproducibility/citation gap, not a magnitude error. Nothing in this review recommends replacing, deleting, or altering the numbers; the finding is strictly about whether the resolution criteria in `resolves_when` are currently met (they are not), which leaves the existing default undisturbed.

## Self-imposed scope confirmation
I read only: Annual_AI_Foundation_Sweep.md §1.7 item section (lines 192–202) and immediate surroundings read for context (lines 188–227, and grep hits at lines 58, 72, 80, 102, 118, 411, 593, 656, 780, 819, 823, 842, 861, 886, 893, 980, 1013, 1020, 1065, 1067 — matched-line text only, via Grep, not full surrounding context), plus the trigger_context provided in this task. I did not read: events.decision_log or any BigQuery state, prior adversarial reviews, AI_Trading_Foundation.md, Strategy.md or strategy slices, Experiment_Parameters.md, Annual_Constraint_Audit.md, Operating_Protocols.md, Claude_Task_Plan.md, git history, or any other repo file. No web search was performed.

## Reasoning
Per the routine spec, `out-of-table-resolution` is non-adversarial by design: the task is not to attack the artifact's claims but to check objectively whether the two named resolution routes are satisfied. Route 1 (new research) is unmet on its face — the artifact itself records two failed independent searches and trigger_context supplies nothing new. Route 2 (explicit in-document derivation from stated assumptions) is the substantive check, and on close reading of the full §1.7 text, no such derivation exists: the section documents the *absence* of a traceable derivation (L3/L4 ABSENT) and offers only an external, explicitly-disclaimed statistical aside covering at most one of the three required inputs (confidence level), with no edge-size or per-trade-variance assumption and no arithmetic reaching either the 30+ or 200+ figure. Since neither objective route is clearly satisfied, the default HOLD stands. This assessment is careful to track the artifact's own guard (line 201): the conclusion here is about missing citation/derivation, not about the figures being incorrect, so it does not read as, and must not be read as, a claim that A3 should treat 30+/200+ as a wrong magnitude to swap out.

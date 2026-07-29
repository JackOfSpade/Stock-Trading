# Adversarial Review — otr-vp-2.19-alphadecay-2026 (attacker)

- **id:** otr-vp-2.19-alphadecay-2026
- **review_type:** out-of-table-resolution
- **strategy:** n/a
- **date:** 2026-07-29
- **cycle_number:** 1
- **artifact:** Annual_AI_Foundation_Sweep.md (§2.19)

## Verdict
RESOLVE — the artifact's own §2.19 (and its PART 2 update-action entry) already contains an explicit, verbatim re-expression of the item's claim into the units the evidence reports (Sharpe decay 51–62%, total-return decay 50–72%), which is what resolves_when's second route requires.

## Findings

### F1 — Decay is CONFIRMED and LARGER than the item claimed, not weakened
§2.19 line 551: Profit Mirage (`2510.07920`) reports *"Sharpe Ratio decay ranges from 51.48% (QuantAgent) to 62.23% (FinCON)"* and *"Total Return decay ranges from 50.18%... to 71.85%."* Line 562: "decay magnitude **confirmed and larger**." Line 560: "CROSS-LEVEL VERDICT: CONVERGENT on the contamination mechanism and its severity (L3 and L4 agree in direction, magnitudes large and in a common band)." The trigger_context's own framing matches this exactly. There is no ambiguity here: the underlying phenomenon is stronger evidence than the item as currently worded, not a downgrade.

### F2 — The defect is units/citation, not substance
§2.19 line 561: "**Units problem:** the foundation says '15 percentage points of alpha decay' while the retrieved sources report *percentage decay* in Sharpe and total return (51–72%). Not the same quantity, and the '15pp' figure was **not** located verbatim in any source this cycle." Line 563 tags "15pp" as `ABSENT-FROM-RECENT-RESEARCH [all levels]` — but explicitly "as stated (units mismatch)," i.e., the tag is about the specific number/unit, not the finding it was meant to convey.

### F3 — The evidence's own units are already drafted into a re-expression, in-artifact, verbatim
Line 866 (PART 2, item 16a): *"Re-express the decay magnitude in the sources' own units: 'Sharpe decay of 51–62% and total-return decay of 50–72% between pre- and post-cutoff evaluation' — and note the current '15 percentage points' figure is not traceable and is in different units."* This is not a hint or raw data point requiring this reviewer to compose new wording — it is A1's own finished, adopted UPDATE text, already phrased in the evidence's reporting units and already listed among the sweep's 26 UPDATE actions (line 1066 includes 2.19). trigger_context reproduces the identical figures independently, confirming the artifact is internally self-contained on this point.

### F4 — Scaling Paradox sub-claim removal is a separate, independent finding
§2.19 lines 555–559: Profit Mirage explicitly states *"no clear evidence that larger models exhibit proportionally worse leakage... closed-source models consistently outperform open-source counterparts,"* and One-Switch finds leakage vulnerability "tracks **architecture family**... **not model capacity**." Line 560: "**CONTRADICTED** on the Scaling Paradox sub-claim." Line 866(b) and line 931/1069 confirm A1 proposes REMOVING this sub-claim entirely. This is orthogonal to the units question on the main decay-magnitude claim and does not bear on the resolve/hold call for this queue entry.

## Objective-criteria assessment

### Route — new research in the claimed units
Not satisfied. No source retrieved this cycle (§2.19, L1–L4) reports a figure in "percentage points of alpha decay," and the artifact says so explicitly (line 561, line 563). No basis to RESOLVE on this route.

### Route — re-expression into the units the evidence reports
Satisfied, objectively and without discretion on this reviewer's part. The concern to guard against was that "restating the claim in different units" could be a discretionary editorial act — i.e., that resolving this entry would require *this* non-adversarial review to invent or choose replacement wording, which is outside what an out-of-table-resolution pass is licensed to do. That concern does not apply here: the exact replacement wording already exists, fully formed, inside the artifact itself, authored by A1 (the sweep), not by this review — "Sharpe decay of 51–62% and total-return decay of 50–72% between pre- and post-cutoff evaluation" (line 866), corroborated independently by the raw source quotes at line 551 and by trigger_context. This reviewer performed no editorial judgment; it only confirmed that an explicit, already-adopted re-expression is present in the units the evidence reports. That is precisely what resolves_when's second route asks for. Whether/when that already-drafted language gets propagated into the downstream foundation document is a separate application step outside this review's scope (and outside the blinding boundary), but the *objective criterion for resolving the queue entry* — existence of an explicit re-expression in the evidence's own units — is met by the artifact as written.

## Direction-and-severity statement
Decay is CONFIRMED and LARGER than the item claimed. The item's directional finding (severe pre/post-cutoff look-ahead contamination causing material performance decay) is convergent across L3 and L4 evidence and, if anything, understates the magnitude once expressed in the sources' own units (51–62% Sharpe decay, 50–72% total-return decay, vs. an untraceable "15pp" figure). The only defect is that the specific "15 percentage points of alpha decay" citation is not traceable to any retrieved source and is expressed in a unit ("percentage points of alpha") the in-window evidence does not use. This is a citation/units correction, not a weakening of the underlying finding.

## Scaling Paradox sub-claim removal (recorded separately)
A1 REMOVED the item's "Scaling Paradox" sub-claim ("larger models show this bias worse, not better"). In-window evidence directly contradicts it: Profit Mirage finds no evidence of proportionally worse leakage in larger models (closed-source models outperform on TR/SR/leakage control), and One-Switch finds vulnerability tracks architecture family (tree-based/graph-informed models most vulnerable) rather than model capacity. Two independent search agents specifically looked for a model-size sweep supporting "bigger = worse" and found none (line 558). This removal is independent of the units question addressed above and is not itself part of the resolve/hold determination for this queue entry — it is noted here only because trigger_context calls it out as a distinct change worth recording.

## Self-imposed scope confirmation
I read only: Annual_AI_Foundation_Sweep.md §2.19 (lines 546–567), plus lines 866, 890, 908, 931, 950–987, 1066–1069 (the PART 2 cross-reference/summary lines needed to confirm the §2.19 update action and Scaling Paradox removal are the artifact's own stated actions, located via grep on "2.19" within the same file), and the trigger_context provided in the task. I did not read: events.decision_log or any BigQuery state, prior adversarial reviews, AI_Trading_Foundation.md, Strategy.md or strategy slices, Experiment_Parameters.md, Annual_Constraint_Audit.md, Operating_Protocols.md, Claude_Task_Plan.md, git history, or any other repo file. No web search was performed.

## Reasoning
This review_type is non-adversarial by protocol: the job is only to surface whether trigger_context plus the artifact contain objective criteria that clearly resolve the item, not to attack, second-guess, or independently research the claim. On that narrow question: resolves_when offers two routes. Route 1 (new research in the claimed "pp of alpha decay" units) is not available and the artifact says so plainly. Route 2 (explicit re-expression into the evidence's own units) is available — not as something this review must construct, but as something A1 already constructed and recorded verbatim within the very artifact under review, as an adopted UPDATE action (line 866) corroborated by the raw source figures (line 551) and by trigger_context. Because the re-expression already exists as objective, already-authored text rather than requiring this reviewer to exercise editorial discretion, the distinction the task asked me to be careful about (objectively available fact vs. discretionary act this non-adversarial path cannot perform) resolves in favor of "objectively available." I was careful not to let the units defect read as a weakening of the finding (F1/direction-and-severity statement above), and I recorded the Scaling Paradox removal as a separate, non-determinative finding per the task's instruction.

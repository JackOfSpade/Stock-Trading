# Adversarial Review — otr-vp-2.10-promptinjection-2026 (orchestrator)

- **id:** otr-vp-2.10-promptinjection-2026
- **review_type:** out-of-table-resolution
- **strategy:** n/a
- **date:** 2026-07-30
- **cycle_number:** 1
- **artifact:** Annual_AI_Foundation_Sweep.md §2.10 (lines 356–402), plus the transfer-failure/absence distinction (lines 892–896) and version-change scope (lines 908–915)
- **attacker_output:** Adversarial_Review_otr-vp-2.10-promptinjection-2026_attacker.md

## Final verdict
HOLD — the objective criterion in `resolves_when` ("a measurement on the current model line for this workflow's actual exposure surface — source-content manipulation of consumed research documents") is not met anywhere in the artifact, trigger_context, or the wider repo/BigQuery state I checked; item 2.10 stays VERSION-PENDING / TRANSFER FAILURE.

## Theater-check flag
CONVERGENT — I reach the same verdict as the attacker and largely the same reasoning, but the agreement is substantive, not rubber-stamped: I independently re-derived the key facts from outside the attacker's blind (below) rather than accepting its framing on trust, and every place I could have found a resolving fact that the attacker structurally couldn't see (it read only §2.10 and trigger_context), I instead found further confirmation that no such fact exists. There is no post-sweep decision_log entry, no strategy-file citation, and no updated foundation-doc text that supplies the missing measurement.

## (a) Validity assessment of each attacker finding

**F1 — no measurement on the actual exposure surface.** Valid, supports HOLD. Anchor checked verbatim against Annual_AI_Foundation_Sweep.md:390 ("per the item's own text its residual exposure is *'source-content manipulation of consumed research reports and financial documents.'* No retrieved benchmark measures that surface at all.") — quote is exact, not paraphrased or stretched.

**F2 — version-volatility undercuts using proxy numbers as a stable baseline.** Valid, supports HOLD, but secondary/reinforcing rather than load-bearing. Anchor checked at line 382 ("78.6% → 78.6% → 50.0% (7/14) → 7.1% (1/14)") — exact. This finding matters for why even the covered surfaces can't be leaned on as informal evidence; it does not by itself establish the resolves_when gap (F1 does that).

**F3 — refusal ≠ containment on the nearest analog surface.** Valid, supports HOLD. Anchor at line 377 checked verbatim ("Opus 4.7 refuses the harmful action in both probe sessions (0%/0%) but the poisoned payload persists in memory 100% of the time"). Correctly used to block the implicit inference "low ASR elsewhere → low risk here."

**F4 — PARTIAL classification and mootness are not resolving evidence.** Valid, and correctly self-limiting. Anchors at lines 392 and 394 checked verbatim and match exactly. The attacker is careful to say mootness explains low urgency, not resolution — this is the correct application of the protocol's HOLD-default rule (mootness is a stakes argument, not an objective criterion satisfying `resolves_when`).

**Class confirmation (transfer failure vs. absence).** Valid. Lines 892–896 checked verbatim; "the research exists and is abundant, but the L2 volatility read means it does not transfer to the deployed model. Needs a measurement on the current line" (894) matches both the attacker's characterization and the `resolves_when` clause's own wording almost word for word. The attacker's warning that a resolver could mis-file this as an "absence" and satisfy the wrong (easier) bar is a legitimate and correctly-scoped process point, not padding.

## (b) Theater in the attacker's output
None found. Every finding carries a specific line anchor, and I checked all four (377, 382, 390, 392/394) plus the class-confirmation anchors (892–896) against the live file text — all quotes are exact, not loosely paraphrased. There is no generic "prompt injection is scary" framing; each finding turns on a specific quantity or quoted sentence in the artifact. The "Objective-criteria assessment" and "Reasoning" sections restate the same four points rather than introducing new padding, which is appropriate for a non-adversarial triage type (there is no attack to stack additional angles on). I am confident this is a clean pass, not convergent laziness, because the self-imposed-scope disclosure (lines 37–38 of the attacker file) shows deliberate, auditable restraint rather than an attempt to pad coverage.

## (c) Weaknesses the attacker missed
The attacker was correctly blinded to everything outside §2.10 and trigger_context (it discloses this explicitly). From the de-blinded view I checked three things it structurally could not, and all three reinforce HOLD rather than undercut it:

1. **AI_Trading_Foundation.md (the actual foundation document, not just the sweep proposing edits to it) already carries the identical replacement text** (rev 8, line 287: "...this workflow's actual exposure — source-content manipulation of consumed research documents — is unmeasured"). So the sweep's proposed fix has already been applied to the artifact of record, and even there, no resolving measurement has since appeared — closing off a path where a resolver might mistake "the foundation doc was updated" for "the gap was measured."
2. **Independently verified no strategy file cites 2.10** (`grep -rln "2\.10" strategy/*.md` — no hits), corroborating F4/mootness from outside the sweep's own self-report rather than taking the sweep's citation-graph claim on faith.
3. **Checked `events.decision_log` for any post-sweep entry touching 2.10** — none exists; the only related entries are the A3 annual-conversion summary (2026-07-28, restating PARTIAL/zero-relaxation) and an unrelated Strategy C 2.11 foundation-change assessment. No hidden resolving fact is sitting in BigQuery that the artifact-only attacker couldn't see.

None of this changes the verdict — if anything it removes any doubt that a resolving fact exists somewhere just out of the attacker's blinded view. I found no weakness in the attacker's case, only confirmation of it.

## (d) Verdict reasoning
The `resolves_when` clause (trigger_context, verbatim) requires "A MEASUREMENT ON THE CURRENT MODEL LINE for this workflow actual exposure surface — source-content manipulation of consumed research documents." Per the protocol's bar for RESOLVE, the resolving fact must be objectively already present, not something this review constructs by editorial judgment. It is not present: every retrieved benchmark in §2.10 (Gray Swan IPI, Shade coding, Shade computer-use, Bad Memory persistent-memory, BrowseSafe, WAInjectBench) measures an agentic tool-use, computer-use, browser-agent, or persistent-memory-file surface — none is a passive research/financial-document-consumption surface, and the artifact says so itself under guardrail 4 (line 390). The version-volatility read (line 382) further means even the covered surfaces can't informally stand in as a stable proxy, and the persistent-memory result (line 377) shows that "the model refuses" is not equivalent to "the corrupted content is contained" — undermining any soft inference from nearby-surface safety to this surface's safety. A1's own PARTIAL classification (guardrails 1 and 4 fail) and its mootness finding (no roster-active strategy cites 2.10) are consistent with HOLD but are not resolving evidence themselves — they bear on stakes, not on whether the measurement exists. My own independent checks outside the attacker's blind (AI_Trading_Foundation.md's already-updated text, the strategy-citation grep, and the decision_log scan) surfaced no additional fact that would clear the bar. Since no objective criterion in the available material — artifact, trigger_context, or the wider repo/BigQuery state — satisfies `resolves_when`, the default HOLD stands.

**Non-relaxation statement.** This HOLD does not loosen anything: disadvantage 2.10 stays classified PARTIAL (not MATERIAL), stays VERSION-PENDING/TRANSFER FAILURE, and no constraint or mitigation text tied to it is touched. The item is re-surfaced at the next A1/A2 cycle per the standing rule (`Claude_Task_Plan.md` line 2519, 2640–2642); only an affirmative RESOLVE grounded in an actual document-consumption-surface measurement on `claude-opus-5` would authorize a change.

## (e) Action taken
AR_orc will record this HOLD verdict and its objective basis in `events.decision_log` (orchestrating session performs the write, not this review). Item 2.10 remains filed as VERSION-PENDING / TRANSFER FAILURE in `AI_Trading_Foundation.md` and is re-surfaced for reassessment at the next A1/A2 review cycle, per the standing out-of-table-resolution rule. No BigQuery write, git commit, or artifact edit was performed by this review.

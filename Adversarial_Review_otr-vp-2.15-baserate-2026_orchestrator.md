# Adversarial Review — otr-vp-2.15-baserate-2026 (orchestrator)

- **id:** otr-vp-2.15-baserate-2026
- **review_type:** out-of-table-resolution
- **strategy:** n/a
- **date:** 2026-07-30
- **cycle_number:** 1
- **artifact:** Annual_AI_Foundation_Sweep.md §2.15 (lines 477–492)
- **attacker_output:** Adversarial_Review_otr-vp-2.15-baserate-2026_attacker.md

## Final verdict
HOLD — the "~85% Bayesian base-rate error rate" magnitude for 2.15 stays version-pending; no extractable figure exists in the artifact or trigger_context, so the entry stays in `PENDING_REVIEW` unresolved.

## Theater-check flag
CONVERGENT — but substantively, not by default. I independently pulled `trigger_context` from `events.queue_events` (item_key match, both rows: the original 2026-07-28 creation and the 2026-07-28 A3 due-date correction), re-read Annual_AI_Foundation_Sweep.md §2.15 at the attacker's cited lines, checked `events.decision_log` for any prior resolution activity on this item (none), confirmed no prior `Adversarial_Review_otr-vp-2.15*` file exists (cycle 1 is genuine), and additionally read the downstream artifact the blinded attacker could not see (`AI_Trading_Foundation.md` §2.15 and its §5.6 reduction-band table). All of these independently corroborate the attacker's account: the anchors quote verbatim, the `resolves_when` bar is unmet, and the guard is already correctly propagated downstream. This is convergence earned by checking four separate evidence sources, not recycled agreement.

## (a) Validity assessment of each attacker finding

### F1 — trigger_context restates, does not add to, §2.15's own evidence
**Valid Tier 1 (supports HOLD).** Confirmed against BigQuery directly: both `queue_events` rows for this `item_key` carry `note` text that is a close paraphrase of §2.15's L2 line, and `payload.resolves_when` is exactly `"NEW RESEARCH: an extractable base-rate-task error rate with a Claude-family model in the panel"`. The only difference between the two rows is the A3 due-date correction described in the note itself (fixing `due_date` vs. `payload.orchestrator_due_date`, per RUNBOOK §37) — purely administrative, no new evidentiary content. F1 holds.

### F2 — the L2 "near-miss" is precisely characterized, and it is still an absence
**Valid Tier 1 (supports HOLD).** Anchor checked verbatim against Annual_AI_Foundation_Sweep.md:482: *"L2 — PRESENT but magnitude unconfirmed. NBER Working Paper w34745... includes a base-rate-neglect item (Question 10) with Claude 3 Opus in the panel. The Claude-specific error rate could not be extracted — [UNCONFIRMED]."* Quote and characterization are exact. The cross-references to lines 823 and 888 also check out verbatim (line 823: "2.15" listed among 7 SPARSE items with "phenomenon-level or adjacent-construct evidence but no magnitude"; line 888: the C.2 table row "L2 unconfirmed, others empty / Phenomenon confirmed, magnitude not extractable from any retrieved source"). No misquote anywhere in this finding.

### F3 — no alternative extractable figure or derivation exists anywhere in §2.15
**Valid Tier 1 (supports HOLD).** Lines 487 and 490 quote verbatim: "CROSS-LEVEL VERDICT: SPARSE for the magnitude" and "Tag: ABSENT-FROM-RECENT-RESEARCH [all levels] for the 85% figure." I additionally checked the two L4 items cited (CogBias `2604.01366`, CBEval `2412.03605`) and the counter-signal (`2507.17951`) as characterized in the artifact — both correctly described as non-numeric / not guardrail-clearing. No derivable proxy exists.

### F4 — resolves_when criterion is not met
**Valid Tier 1 (supports HOLD).** I read `payload.resolves_when` directly from BigQuery rather than trusting the attacker's paraphrase of it (attacker cites it as "Entry spec," consistent with what it could see in `trigger_context`), and it is character-for-character what the attacker quotes. "Claude-family model in the panel" is satisfied (Claude 3 Opus, w34745); "extractable... error rate" is not (explicitly "could not be extracted"). The criterion is conjunctive and one conjunct fails. F4 holds.

## (b) Theater in the attacker's output
None found. Every claim carries a checkable line anchor, and I verified all of them against the live file rather than accepting them on faith — all check out exactly as quoted. The "Objective-criteria assessment" and "Phenomenon vs magnitude" sections are not padding: they draw the same absence-vs-extraction-failure distinction that Annual_AI_Foundation_Sweep.md itself insists on for sibling items (e.g. line 472's parallel warning for 2.14: *"this is an absence needing new research, NOT a transfer failure"*), so the attacker's framing tracks a real, document-wide distinction rather than inventing one. The "Self-imposed scope confirmation" section is an honest disclosure of what was and was not read, which is exactly the kind of verifiable scope statement this protocol wants, not filler.

## (c) Weaknesses the attacker missed
Two things the de-blinded view surfaces, neither of which changes the verdict:

1. **2.15 is load-bearing across most of the active roster, not capital-inert.** The strict-blinded attacker had no way to see Part 3 of the same document (outside its self-declared scope of §2.15 proper), but §2.15 is cited by Strategies B, C, D and E (Annual_AI_Foundation_Sweep.md:951–954) — only Strategy A does not cite it (line 957). This is a stronger reason than the attacker's output gives for treating the non-relaxation statement below as more than boilerplate: a HOLD here has real downstream reach across four of five roster strategies, unlike a genuinely inert item.
2. **Downstream consistency is already correct, and the resolution mechanism is genuinely out-of-table, not just under-evidenced.** `AI_Trading_Foundation.md`:325–331 already carries a blockquote matching §2.15 verbatim: *"the phenomenon confirmed but the '~85% Bayesian base-rate error rate' magnitude unconfirmed at L2 and ABSENT at every other level — an ABSENCE, so the remedy is NEW RESEARCH extracting the magnitude, not a replication on the current model line."* Separately, `AI_Trading_Foundation.md`:685 (the §5.6 reduction-band lookup table) requires a *measured reduction magnitude* to route through relaxation bands ("Error rate reduced to 40-60%" / "≤40%") — but there is no measured current-model figure at all, so there is nothing to look up. This confirms the "out-of-table" framing precisely: the mechanical relaxation lookup literally has no input to key off, which is a stronger and more specific statement than "the attacker's HOLD default applied."

Neither finding changes the verdict — both reinforce HOLD and the non-relaxation posture.

## (d) Verdict reasoning
This is `out-of-table-resolution`, non-adversarial triage: default HOLD unless the `resolves_when` criterion is objectively already present in the artifact or trigger_context. The criterion is conjunctive — a Claude-family model in the panel (satisfied: Claude 3 Opus, NBER w34745) AND an extractable error-rate figure (not satisfied: "the Claude-specific error rate could not be extracted"). Resolving this to RESOLVE would require either (i) a number that does not currently exist anywhere in the record, or (ii) treating "a relevant study exists but its figure is unextracted" as equivalent to "an extractable figure exists," which is exactly the kind of editorial substitution the review type's scope explicitly excludes ("if resolving would require you to invent, choose, or derive replacement wording/rationale, that is out of scope for this pass → HOLD"). No such fact is present. HOLD is correct.

I deliberately did not attempt independent re-extraction of NBER w34745 myself using this session's broader tool access (WebFetch/Tavily), even though I am not strict-blinded and technically could try. Two reasons: first, `Operating_Protocols.md`:634 frames this review type as resolving "foundation-change out-of-table flags autonomously... instead of deferring to an annual human cycle" — i.e. adjudicating whether documented criteria are already met, not conducting fresh primary research that is A1/A3's job in the next sweep cycle. Second, the `resolves_when` clause itself is phrased as "NEW RESEARCH," signaling the resolving artifact is expected to be a future A1/A3 deliverable, not something manufactured mid-triage by AR_orc. Doing so here would blur exactly the invent/derive line the review type is built to avoid, even if the intent were benign.

**Non-relaxation statement (required — this entry concerns a constraint-adjacent foundation disadvantage).** This HOLD is not a finding against base-rate neglect as a disadvantage and licenses no relaxation of it. The *phenomenon* is confirmed and unaffected (§2.15's L4 transfer assessment stands: GPT-4 base-rate neglect comparable to human rates, per Macmillan-Scott & Musolesi 2402.09193, partially but not fully mitigated by CoT). Only the specific 85% *magnitude* is version-pending, per the document-wide Part 4 step 4 flip that applies to every Tier 2 magnitude in the sweep with no exemptions (Annual_AI_Foundation_Sweep.md:904, :1068) — 2.15 is not being singled out or treated more leniently than any sibling item. The disadvantage stays in force as a best-available proxy exactly as it is documented today for Strategies B, C, D and E; nothing here should be read as grounds to discount it.

## (e) Action taken
Verdict recorded as HOLD in this file. No BigQuery write, no git action, and no edit to any other repo file is performed by me. The orchestrating session is responsible for logging this verdict to `events.decision_log`, advancing the `PENDING_REVIEW` queue row's status (with `orchestrator_output_path` set, per `task_plan/AR_orc.md` step 5), and any subsequent git operations. Per the type's default-HOLD handling, the constraint/foundation item stays in force and will be re-surfaced by the next A1/A2 cycle — no silent drop.

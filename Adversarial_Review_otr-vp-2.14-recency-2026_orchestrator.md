# Adversarial Review — otr-vp-2.14-recency-2026 (orchestrator)

- **id:** otr-vp-2.14-recency-2026
- **review_type:** out-of-table-resolution
- **strategy:** n/a
- **date:** 2026-07-30
- **cycle_number:** 1
- **artifact:** Annual_AI_Foundation_Sweep.md §2.14 (lines 461–473), cross-refs 819–823, 842–844, 877, 892–896, 908, 950–955, 1065–1068
- **attacker_output:** Adversarial_Review_otr-vp-2.14-recency-2026_attacker.md

## Final verdict
HOLD — the version-pending magnitude for 2.14 ("~10× most-recent-week weighting") stays at its current value; no criterion in the artifact or `trigger_context` objectively resolves it this cycle.

## Theater-check flag
CONVERGENT — but substantively, not by default. I independently re-read §2.14 in full, verified every attacker anchor against the source text, cross-checked the item's synced state in `AI_Trading_Foundation.md` (lines 317–323, byte-consistent with the sweep), grepped `strategy/*` for any alternate source or derivation of the 10× figure, and pulled the live `PENDING_REVIEW` row and `events.adversarial_reviews` from BigQuery. All of it points the same direction as the attacker: there is no resolving fact anywhere in this repo, not just in the artifact. Agreement here is earned by an independent search, not inherited from the attacker's framing.

## (a) Validity assessment of each attacker finding

**F1 — Class is ABSENCE, not transfer failure.** Supports HOLD, Tier: valid. Anchor checked: line 472 reads exactly as quoted ("This is an absence needing new research, NOT a transfer failure — A3 must not conflate the two."). Line 470 (attacker cites as "470" in prose, actual text is the TRANSFER ASSESSMENT line at 470 in my read) does separate the existence-transfer finding from the magnitude-absence finding, confirmed. Correct and load-bearing for the review's framing.

**F2 — Resolving bar was maximally permissive and still came back empty.** Supports HOLD, valid. `resolves_when` from the live `payload` JSON is verbatim "NEW RESEARCH: any source, in any domain, measuring a recency-weight ratio" — matches the attacker's characterization exactly (no domain/tier restriction). Lines 465 and 467 quote correctly ("L1 — ABSENT. L2 — ABSENT. L3 — ABSENT. L4 — ABSENT for the ratio."; "Two agents searched independently... corroborating the prior cycle's finding of total absence."). Anchor holds.

**F3 — This absence is comparatively total vs. version-pending siblings.** Not determinative, valid. Line 823 confirmed verbatim ("Items SPARSE: 7 ... 2.14 and 2.21 are empty at all four levels; the rest have phenomenon-level or adjacent-construct evidence but no magnitude."). The comparison is accurate but doesn't move the RESOLVE/HOLD binary either way — it's context, not a resolving criterion. Correctly not weighted as decisive by the attacker either; included for completeness rather than padding, since it is genuinely anchored.

**F4 — trigger_context/artifact supply no resolving criterion this cycle.** Supports HOLD, valid. This is the operative finding: the resolving fact must be objectively present already, and both the live BigQuery row and the artifact affirmatively state total absence rather than supplying a new source. Correct application of the type's default rule.

## (b) Theater in the attacker's output
None found. Every anchor I checked (lines 465, 467, 469–473, 823) quotes the artifact verbatim and in context; none are misquoted, cherry-picked to reverse the artifact's own meaning, or non-existent. The "Why absence does not license removal" and "Self-imposed scope confirmation" sections are not required by the protocol's minimum output but are genuinely load-bearing here (publication-asymmetry argument correctly forecloses reading "absence of a ratio study" as evidence the true ratio is smaller than 10×) rather than generic filler — they engage the specific artifact language ("Per Part 4, absence alone does not remove it," line 472) rather than reciting a boilerplate absence-is-not-evidence-of-absence line. I looked for recycled/generic phrasing not tied to a quote and did not find any that changed the verdict's basis.

## (c) Weaknesses the attacker missed
One minor contextual point, not a defect: line 473 ("2.14 is cited by A, B, C, D and the regime router — the most widely-cited item with zero evidentiary support for its stated magnitude") was not quoted by the attacker, though it is directly adjacent to its F1 anchor. This raises the operational stakes of getting the HOLD right (four strategies plus the regime router all load-bear on this uncalibrated figure per `strategy/08_pre_mortems.md` lines 131, 255, 391, 555, 598, 679, 801, all of which independently treat the 10× figure as an accepted, uncalibrated residual rather than a resolved measurement) but does not change the resolution test itself — trigger_context still supplies no new source. Beyond that, the de-blinded cross-check surfaced nothing the attacker got wrong: `AI_Trading_Foundation.md`'s live 2.14 entry (lines 317–323) is byte-consistent with the sweep's characterization and carries the identical "ABSENT... at all four evidence levels" language; no strategy file or BigQuery table supplies an alternate measurement of the ratio.

## (d) Verdict reasoning
This is a non-adversarial triage review; the only question is whether an objective resolving fact is *already present* in the artifact or trigger_context, per the type's default-HOLD rule. It is not. The artifact states, and the live `payload.resolves_when` confirms, that the resolving criterion is "any source, in any domain, measuring a recency-weight ratio" — the widest possible bar in this version-pending batch — and both the artifact (§2.14, lines 465–467) and the trigger_context affirmatively report that bar was checked across all four evidence levels on two independent search passes and came back empty, corroborating a prior cycle's identical finding. Resolving this item RESOLVE would require inventing or deriving a ratio the search explicitly did not find — exactly the "editorial or analytical discretion" the protocol puts out of scope for this review type. HOLD is therefore the only defensible verdict on the material provided.

Non-relaxation statement: this HOLD is not a finding against the 10× magnitude and licenses no loosening. The phenomenon (recency bias) is independently well-supported at L4 on architectural-generality grounds (7-model replication, `2509.11353`); only the specific ratio is unmeasured. Absence of a ratio study is not evidence the true ratio is smaller than stated — publication asymmetry cuts the other way — so the 10× figure stays in force as the best-available proxy under Part 4 step 5 pending new research that actually measures a recency-weight ratio.

## (e) Action taken
Verdict HOLD is recorded for `otr-vp-2.14-recency-2026`, cycle 1. The orchestrating session will log this verdict to `events.adversarial_reviews` and `events.queue_events` (marking the pending row resolved-as-HOLD, current state retained) and re-surface the item in the next review cycle per the standing per-item fade-review rule; no BigQuery write or git action is performed by this review itself.

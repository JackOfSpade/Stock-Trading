# Adversarial Review — otr-vp-2.14-recency-2026 (attacker)

- **id:** otr-vp-2.14-recency-2026
- **review_type:** out-of-table-resolution
- **strategy:** n/a
- **date:** 2026-07-29
- **cycle_number:** 1
- **artifact:** Annual_AI_Foundation_Sweep.md (§2.14)

## Verdict
HOLD

## Findings

### F1 — Class is ABSENCE, explicitly not transfer failure
**Anchor:** "This is an absence needing new research, NOT a transfer failure — A3 must not conflate the two." (Annual_AI_Foundation_Sweep.md:472)
The artifact itself names the class in terms, at the point of tagging the item VERSION-PENDING. There is no ambiguity to adjudicate here — §2.14's transfer assessment (line 470) separately confirms the *existence* of recency bias transfers on L4 architectural-generality grounds (7-model replication), while the **10× magnitude** is the thing with no evidentiary basis at any level. Existence-transfer and magnitude-absence are two different findings about two different sub-claims within the same item; keeping them apart, as line 472 insists, is straightforward and the trigger_context preserves it correctly.

### F2 — The resolving bar is maximally permissive and still came back empty
**Anchor:** "Two agents searched independently across finance-specific, forecasting-specific and domain-general framings. Neither found a ratio statistic at any level, independently corroborating the prior cycle's finding of total absence." (Annual_AI_Foundation_Sweep.md:467); "L1 — ABSENT. L2 — ABSENT. L3 — ABSENT. L4 — ABSENT for the ratio." (line 465)
`resolves_when` asks for "any source, in any domain, measuring a recency-weight ratio" — the widest possible resolving criterion in this version-pending batch (no domain restriction, no tier restriction, no unit restriction beyond "a ratio"). The artifact reports that even this bar was checked across all four evidence levels (L1-L4) and came back empty on two independent search passes, corroborating a prior cycle's finding. An absence this thoroughly checked, at this permissive a bar, is unusually well-established — which argues for HOLD, not against it: there is no unexamined corner where a resolving source could plausibly be hiding.

### F3 — This absence is stronger (more total) than typical version-pending siblings
**Anchor:** "Items SPARSE: 7 — 1.3, 1.7, 2.4, 2.14, 2.15, 2.21, 3b.2. Of these, **2.14 and 2.21 are empty at all four levels**; the rest have phenomenon-level or adjacent-construct evidence but no magnitude." (Annual_AI_Foundation_Sweep.md:823); "Do Large Language Models Favor Recent Content?" ... rank-shift and preference-reversal metrics in an information-retrieval setting — not a week-over-week weight ratio in any domain." (line 466)
Most of the batch's SPARSE/version-pending items have *some* adjacent or wrong-unit evidence to anchor against (e.g., the nearest retrieved study here, `2509.11353`, gives rank-shift and preference-reversal numbers, not a weight ratio, in a different task setting entirely). 2.14 is explicitly called out alongside 2.21 as one of only two items empty at *all four* levels with nothing usable even by analogy for the specific quantity. That is a difference in degree from other version-pending items in this same batch (several of which at least have adjacent-construct or wrong-unit numbers to reason from), and it is worth recording as such rather than treating all version-pending items as evidentiarily uniform.

### F4 — trigger_context and artifact contain no criterion that resolves the item this cycle
**Anchor:** "resolves_when: 'NEW RESEARCH: any source, in any domain, measuring a recency-weight ratio'" (entry); §2.14 body (lines 461-473), trigger_context verbatim.
Neither the artifact section nor the trigger_context supplies a source meeting the resolving condition — both affirmatively state the opposite (total absence, independently re-confirmed). There is nothing here to apply the resolution test *to*; the entry itself is a report of continued absence, not of new research. Per protocol, when the needed information is absent from the artifact and trigger_context, that is recorded as the answer, not treated as license to search further.

## Class confirmation — ABSENCE, not transfer failure

Confirmed per F1. The artifact's own language at line 472 makes this an explicit authorial statement, not an inference this review had to construct. The 10× magnitude has no evidentiary basis at any level in 24 months; separately and independently, the underlying phenomenon (recency bias exists in LLM outputs) transfers on architectural-generality grounds. Only the magnitude is version-pending; a downstream reader must not read this item as casting doubt on the phenomenon's existence.

## Objective-criteria assessment

The resolving bar named in trigger_context — "any source, in any domain, measuring a recency-weight ratio" — is the widest of the version-pending set reviewed under this protocol: no domain restriction, no tier restriction. The artifact reports this bar was tested across all four evidence levels (L1/L2/L3/L4) and came back empty on two independent search passes across finance-specific, forecasting-specific, and domain-general framings, corroborating a prior cycle's identical finding. Neither the artifact nor trigger_context supplies anything meeting the criterion. There is no objective basis in the provided material to RESOLVE; the absence is, if anything, unusually well-established precisely because the bar checked against it was so permissive.

## Why absence does not license removal

Absence of measurement is not evidence of absence of the bias. The artifact is explicit that the phenomenon itself (recency bias in LLM weighting/preference) is well documented and transfers on architectural-generality grounds (7-model replication in `2509.11353`); what is missing is a specific quantitative ratio for a specific claimed magnitude ("~10× weighting on the most recent week"). Nobody publishes a null result establishing "there is no ~10x-type ratio" — publication asymmetry means the absence of a matching statistic in the literature is not informative about whether the true ratio is near, above, or below 10×; it only tells us nobody has measured it. Per the artifact's own governing rule ("Per Part 4, absence alone does not remove it," line 472), removing a Tier 2 magnitude on absence alone is explicitly flagged as too aggressive given this asymmetry. This review's finding — that even the widest possible resolving bar came back empty — must not be read by any downstream process as strengthening a case for deletion; it strengthens the case for HOLD by ruling out an unexamined gap in the search, not by adding evidence against the magnitude.

## Self-imposed scope confirmation

I read only: Annual_AI_Foundation_Sweep.md §2.14 (lines 461-476, plus a `grep` locating all "2.14" cross-references at lines 72, 102, 461, 473, 797, 823, 842, 877, 887, 893, 908, 950-955, 962, 974, 978, 983, 1065, 1067 to confirm the item's tag/class status, all within the same artifact), and the trigger_context block supplied in this task. I did not read: events.decision_log or any BigQuery state, prior adversarial reviews, AI_Trading_Foundation.md, Strategy.md or strategy slices, Experiment_Parameters.md, Operating_Protocols.md, Claude_Task_Plan.md, Annual_Constraint_Audit.md, git history, or any other repo file. No web search or BigQuery tool was used.

## Reasoning

This review_type is non-adversarial by protocol: the task is not to attack the item's classification or magnitude but only to check whether trigger_context plus the artifact contain objective criteria that clearly resolve it. They do not — the artifact affirmatively states total, independently-re-confirmed absence at all four evidence levels against the widest resolving bar in the version-pending batch, and trigger_context supplies no new source. The default therefore stands: HOLD. The class is cleanly ABSENCE, not transfer failure, per the artifact's own explicit language, and the reasoning chain that must survive intact — absence of measurement is not evidence of absence of the bias, and publication asymmetry makes removing this Tier 2 magnitude on absence alone too aggressive — is preserved here without alteration.

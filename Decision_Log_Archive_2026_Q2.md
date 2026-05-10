# Decision Log Archive 2026 Q2

Archive of matured Decision_Log entries from the live `Decision_Log.md`. Append-only. Entries archived per W5 lifecycle rules. See `Operating_Protocols.md` §6 (Decision-Log Lifecycle Policy) for canonical retention rules and `Claude_Task_Plan.md` §W5 for procedural details.

**Quarter**: 2026-Q2 (April 1, 2026 – June 30, 2026).

**First archive cut**: 2026-05-10 (first scheduled W5 run; bootstrap).

**Read-access scope**: Monthly+ cadence prompts (M1, M3, M4, M5, Q1, Q2, Q3, A1, A2, A3). Daily/weekly cadence prompts do NOT read this file.

---

### 2026-04-22 Experiment inception — Initial router states

**Trigger:** Experiment start; $6,946.86 initial capital split across Strategies A, B, C, D, E.
**Inputs:** Strategy.md, Experiment_Parameters.md, AI_Trading_Foundation.md (revision 1).
**Sessions:** None (inception).
**Decision:** All five strategies initialized at DO-NOT-ACTIVATE pending first M1 review and pre-mortem completions.
**Reasoning:** No router signals have been computed yet; default per Experiment_Parameters.md is no activation before the full pre-mortem set (N+1 = 6) completes and before the first fundamental analysis runs.
**Theater-check flag:** n/a.
**Downstream actions:** Portfolio_Ledger.md initialized with per-strategy starting values; Regime_State.md initialized with inception rows.
**References:** Portfolio_Ledger.md (2026-04-22 entry).

---

### 2026-04-23 M2 monthly AI capabilities review — first cycle

**Trigger:** First monthly AI capabilities review per AI_Trading_Foundation.md Part 4.
**Inputs:** AI_Trading_Foundation.md revision 1; M2 deep-research output covering Q1 2026 AI research, Anthropic releases, and market-structural AI context.
**Sessions:** Single monthly session (non-incognito).
**Decision:** Seven of eight answered questions resolved YES. Per-strategy foundation-change assessment warranted for A, B, C, D, E. Specifically:
- New failure modes documented: agentic epistemic hallucination (TradeTrap), RL-post-training decision-token overconfidence (arXiv 2601.13284 / 2603.06604), deterministic-decoding cross-run inconsistency (AlphaForgeBench).
- Partial reduction: prompt injection risk on Opus-tier with classifiers (2.10) — not eliminated.
- Homogenization risk reinforced (2.8) with Coordination Primacy Hypothesis and $610–650B 2026 hyperscaler capex concentration.
- Partial resolutions logged for 3a.1 (EV math not usable without calibration layer), 3a.2 (decision-support with hard external guardrails required), 3a.3 (long-horizon consistency requires external scaffolding).
**Reasoning:** Default bias is YES — err toward flagging change per Experiment_Parameters.md. Transferability filter cleared by architectural generality for 2.24, 2.25, 2.26, and by direct Claude-family evidence for 2.10, 2.13 (Haiku 4.5 ECE). Evidence materially updates the edge/disadvantage map.
**Theater-check flag:** n/a (single session).
**Downstream actions:** AI_Trading_Foundation.md revised to revision 2 (integrating updates to 2.3, 2.8, 2.10, 2.13, 2.24; adding 2.25 and 2.26; partial resolutions in 3a.1/3a.2/3a.3). Per-strategy foundation-change assessments for A, B, C, D, E required before any first trade.
**References:** Attached M2 deep-research analysis (Part 1 data + Part 2 question-by-question resolution).

---

### 2026-04-23 AI_Trading_Foundation.md revision 2 published

**Trigger:** M2 2026-04 findings required document update per AI_Trading_Foundation.md Part 4 invalidation rule.
**Inputs:** M2 2026-04 decision entry above.
**Sessions:** None (document update).
**Decision:** Document updated from revision 1 (2026-04-22) to revision 2 (2026-04-23).
**Reasoning:** See M2 entry.
**Theater-check flag:** n/a.
**Downstream actions:** Per-strategy foundation-change assessments for A, B, C, D, E are warranted and must complete before any first trade.
**References:** AI_Trading_Foundation.md revision 2.

---

### 2026-04-23 SGOV parking conversion — initial

**Trigger:** Per Experiment_Parameters.md, SGOV is the default parking vehicle for undeployed capital. Initial conversion required before any strategy deploys capital into trades.
**Inputs:** Portfolio_Ledger.md 2026-04-22 starting state ($6,946.86 all USD Cash, split A $1,389.38 / B-E $1,389.37 each); IBKR account U11152139.
**Sessions:** None (execution step).
**Decision:** Converted $6,942.12 of $6,946.86 into 68.98 shares of SGOV across two fills. Residual $3.96 held as USD Cash. Commissions of $0.78 treated as a cost of parking conversion (option 1) and allocated $0.16 per strategy, reducing each strategy's starting value by $0.16.
- Fill 1: 68 shares @ $100.64, NYSE, 07:46:03 ET, commission $0.43, order 00fd111d.00011066.69eaee66.0001
- Fill 2: 0.98 shares @ $100.61, IBKR, 12:55:51 ET, commission $0.35, order 00fd111d.00011066.69e9a0d2.0001
- Weighted-average cost basis: $100.6396
- Per-strategy split: 13.796 shares each (fractional split across A, B, C, D, E)

Revised per-strategy starting values (post-commission, used as TWR baseline going forward):
- Strategy A: $1,389.22 (was $1,389.38)
- Strategies B, C, D, E: $1,389.21 each (was $1,389.37)
- Account total: $6,946.08 (was $6,946.86; $0.78 commission paid)

**Reasoning:** Option 1 (commissions reduce each strategy's starting value) chosen over option 2 (preserve round starting values) because per Experiment_Parameters.md, each strategy's performance is tracked against its own starting value, and parking commissions are real costs of running the strategy that should be captured in the TWR baseline. This is a one-time adjustment at conversion; subsequent SGOV dividend accruals and mark-to-market changes flow to each strategy proportionally going forward.
**Theater-check flag:** n/a (execution step, not adversarial review).
**Downstream actions:** Portfolio_Ledger.md updated with SGOV parking activity table, per-strategy SGOV share counts, and revised starting values. Regime_State.md unaffected. No strategy is yet eligible to trade — all remain blocked on pre-mortem completion and foundation-change assessments.
**References:** IBKR trade details screens for order IDs above. Portfolio_Ledger.md 2026-04-23 update.

---

### 2026-04-23 Regime router pre-mortem — four-cycle adversarial review completed; accepted under revision-churn cap

**Trigger:** Regime router pre-mortem is the first of N+1 = 6 pre-mortems required to clear adversarial review before any strategy executes its first trade per Experiment_Parameters.md completion requirement.

**Inputs:** Strategy.md router pre-mortem revisions 1 through 5; Experiment_Parameters.md revisions 10 through 13; four independent adversarial review cycles with incognito attacker and judge sessions per cycle.

**Sessions:** Each adversarial cycle comprised two incognito sessions (attacker, judge); no adjudicator session was triggered in any cycle because attacker and judge never returned a DISAGREEMENT WITH ATTACKER verdict.

**Cycle-by-cycle outcomes:**

| Cycle | Reviewed | Verdict | Tier 1 items surfaced | Theater-check flag | Outcome |
|-------|----------|---------|----------------------|---------------------|---------|
| 1 | Rev 1 | MATERIAL WEAKNESS | ~9 (pre-tier taxonomy) | CONVERGENT | Rev 2 drafted |
| 2 | Rev 2 | MATERIAL WEAKNESS | ~6 structural (of 18 total items) | CONVERGENT | Rev 3 drafted after adding stopping rule (EP rev 12) |
| 3 | Rev 3 | TIER 1 DEFECT — REVISION REQUIRED | 2 | MIXED | Rev 4 drafted |
| 4 | Rev 4 | TIER 1 DEFECT — REVISION REQUIRED | 2 (both attributable to rev 4's own edits) | DIVERGENT | Rev 5 spot-edit applied under revision-churn cap (EP rev 13); no cycle 5 |

**Parameter revisions triggered by the review process:**
- Experiment_Parameters.md rev 10 → 11: added router counterfactual-attribution metric to monthly review template (item 13); superseded when counterfactual metric was dropped in Strategy.md rev 3. Item 13 remains as all-SGOV comparison language only.
- Experiment_Parameters.md rev 11 → 12: added stopping rule (pass conditions 1–3: clean pass, Tier-1-clean cap, diminishing-returns cap) and Tier 1/2/3 definitions. Triggered by observed cycle-1 and cycle-2 item counts and CONVERGENT theater-check flags signaling adversarial saturation.
- Experiment_Parameters.md rev 12 → 13: added revision-churn cap (pass condition 4) and floor acknowledgment. Triggered by cycle-4 finding that all Tier 1 items were attributable to rev 4's own edits (propagation errors / scope-lock gaps) rather than residual original-architecture defects.

**Decision:** The regime router pre-mortem (Strategy.md rev 5, dated 2026-04-23) is accepted under the revision-churn cap in Experiment_Parameters.md rev 13. Rev 5 addresses the two cycle-4 Tier 1 items as a spot-edit: (a) Section 10 slow-burn bullet corrected from "A or D" to "B, C, or D" (slow-burn case has Breadth=WEAK which deactivates A by Section 3 rule); (b) Section 11 change-control lock extended to cover the operational thresholds in Section 6 (breadth >10pp MoM, VIX drift >5pp within NORMAL over 30 days). No cycle 5 is run because cycle 4 surfaced only revision-churn defects, which per the new cap are fixed by spot-edit rather than by running another full cycle.

**Reasoning:** The four-cycle progression shows the adversarial architecture doing genuine work (item count 9 → 6 → 2 → 2; theater-check CONVERGENT → CONVERGENT → MIXED → DIVERGENT is the correct direction). Cycle 4 specifically identified defects that prior cycles missed and that rev 4's own revision edits introduced — a category of defect that reflects revision-generator churn rather than residual architectural flaws. Continuing to cycle 5 would likely surface two more revision-induced defects of similar small amplitude while introducing two more via rev 6, producing sideways motion at constant cost. The revision-churn cap's rationale (LLM-generated revisions cannot converge to zero defect because the same distributional biases that wrote the artifact are doing the reviewing and revising) is the correct framing for stopping here.

**Tier 2/3 items carried forward as Known Limitations (Strategy.md rev 5 Section 12):** 12 total items logged — slow-burn mechanical indistinguishability with partial VIX-drift detection; 9.2 denominator possibly unreachable in benign regimes; 9.1 un-fireable for strategies stuck in one state; 9.4 uncalibrated 40% threshold; 9.5 unjustified 10-transition threshold; 9.6 format-only compliance check; monthly rhythm timing (resolved: first trading day); model-version change handling via foundation-change trigger; strategy execution mechanics in each strategy's section; flash-crash recurrence escalation threshold; self-containment scope-boundary carve-out for non-Experiment_Parameters.md references; Session 4 architectural saturation with feedback-loop via 9.4. Each item has a specified monthly-review trigger and is checked at every pre-mortem-indicator review.

**Theater-check flag on this decision:** n/a. The decision to accept under the revision-churn cap was made by the participant with Claude assistance, not by a four-session adversarial process. Per Experiment_Parameters.md rev 12 "triage responsibility" clause, tier assignments (and by extension cap invocations) are not themselves subject to adversarial review, to avoid infinite regress.

**Progression pattern worth preserving for monthly theater-check survey (first scheduled 2026-05-01):** Theater-check across the four cycles went CONVERGENT → CONVERGENT → MIXED → DIVERGENT. The first two cycles showed the predicted saturation of same-model adversarial review (weight-level biases correlated across supposedly independent sessions); cycles 3 and 4 showed genuine divergence as the artifact became more structurally specific and the remaining defect space became more idiosyncratic. This pattern is consistent with the floor acknowledgment in Experiment_Parameters.md rev 13 and should be the baseline against which future theater-check rates are compared.

**Downstream actions:** Router pre-mortem dequeued from the "Pending structured decisions" list below. Strategy.md rev 5 is the authoritative router pre-mortem. Known Limitations (Section 12) are added to the monthly pre-mortem-indicator review checklist. The cycle-by-cycle theater-check data above will be folded into the 2026-05-01 monthly theater-check survey. Remaining 5 pre-mortems (Strategies A, B, C, D, E) are next in sequence; each will run its own adversarial review cycle(s) and will reference the revision-churn cap and floor acknowledgment as available stopping conditions from the outset.

**References:** Strategy.md revisions 1–5; Experiment_Parameters.md revisions 10–13; Four cycle attacker and judge outputs (held in-chat during this session, not filed as separate documents — future cycles on other pre-mortems should consider filing incognito session outputs as separate artifacts for audit purposes).

---

### 2026-04-23 Strategy A pre-mortem — acceptance under combined revision-churn + saturation stop after 6 review cycles

**Trigger:** Six successive adversarial review cycles against the Strategy A pre-mortem (Strategy.md, pre-mortem revisions 1 through 7). Cycles 1-4 ran under the three-session adversarial-review architecture (per Experiment_Parameters.md rev 12-13). Cycles 5-6 ran under the single-session architecture per Experiment_Parameters.md rev 14.

**Inputs:** Strategy A pre-mortem (Strategy.md revisions 1-11, Strategy A pre-mortem revisions 1-7); Experiment_Parameters.md revisions 12-14 (stopping rule and architectural simplification); the six attacker outputs and (for cycles 1-4) the four judge outputs.

**Sessions / cycle progression:**

| Cycle | Pre-mortem rev | Verdict | Tier 1 items | Theater-check | Architecture | Outcome |
|-------|----------------|---------|--------------|---------------|--------------|---------|
| 1 | Rev 1 | TIER 1 DEFECT | 2 (+ 1 recommended) | CONVERGENT | 3-session | Rev 2 drafted |
| 2 | Rev 2 | TIER 1 DEFECT | 2 | CONVERGENT | 3-session | Rev 3 drafted |
| 3 | Rev 3 | TIER 1 DEFECT | 3 | CONVERGENT | 3-session | Rev 4 drafted |
| 4 | Rev 4 | TIER 1 DEFECT | 1 | CONVERGENT | 3-session | Rev 5 drafted |
| 5 | Rev 5 | TIER 1 DEFECT | 2 | CONVERGENT | 1-session | Rev 6 drafted |
| 6 | Rev 6 | TIER 1 DEFECT | 1 | CONVERGENT | 1-session | Rev 7 fix applied; cycle 7 not run; pre-mortem accepted |

**Architectural transition mid-sequence:** Cycles 1-4 used the three-session architecture (Attacker / Judge / Adjudicator-on-disagreement) consistent with Experiment_Parameters.md rev 12-13. After observing 8/8 CONVERGENT cycles across the router pre-mortem (4 cycles) and Strategy A cycles 1-4 with zero adjudicator invocations, Experiment_Parameters.md was updated to rev 14, simplifying all four adversarial review types (pre-mortem, router divergence, redistribution, mark-to-market termination) to single-session attacker plus in-conversation review by orchestrating session. Cycles 5-6 ran under the new architecture. The cycle 5-6 outcomes (1-2 Tier 1 items, CONVERGENT theater-check, defect class consistent with cycles 4) showed no operational evidence of degraded review quality from the simplification, though absence of a separate-session judge means ratification-vs-genuine-validation is no longer empirically distinguishable.

**Defect class concentration in cycles 4-6:** All three of these cycles surfaced exactly one defect class — *asymmetric reasoning between Constraint 2 (2.4 narrative over-fit) and Constraint 3 (2.19 look-ahead bias) in the binding-constraints subsection of Section 5*. The locus shifted across revisions:
- *Cycle 4* attacked rev 4's coarse asymmetry (Constraint 3 had a "flowing exclusion" while Constraint 2 had no exclusion despite same hard-wired status).
- *Cycle 5* attacked rev 5's grounding asymmetry (Constraint 2's at-entry-identifiability argument was near-circular vs. Constraint 3's mechanism-based; 2% position-size cap asymmetrically attributed to Constraint 2).
- *Cycle 6* attacked rev 6's over-correction (Constraint 2's strengthened self-reference argument now contaminates Constraint 3's entry criterion 6, which had not been updated to graded framing).

Each fix resolved one direction of asymmetry and exposed another at the next resolution level. The underlying reason is mechanism-real: 2.4 is uniformly closed under self-reference; 2.19 has a transparent-citation form (with a syntactic surface feature providing partial leverage even when narrative-quality assessment is biased) and a buried-framing form (with no syntactic surface feature). The two constraints are not symmetric in reality, so any attempt to make their textual treatments fully parallel produces a new mismatch at the next zoom level. The reviewer keeps surfacing this tension because it is genuine, not because the document is broken.

**Parameter revisions triggered by the review process:**
- Experiment_Parameters.md rev 13 → 14 (during Strategy A cycle 4 → 5 transition): architectural simplification of all four adversarial review types from three-session to single-session (attacker incognito + in-conversation review by orchestrating session). Stopping rule simplified from four pass-condition caps (clean pass / Tier-1-clean / diminishing-returns / revision-churn) to two pass conditions (Tier 1 clean + diminishing-returns reassessment with three stop conditions). Triggered by operational unsustainability of three-session architecture given the cycle counts being observed and the Strategy B-E pre-mortems plus foundation-change assessments still queued.

**Decision:** The Strategy A pre-mortem (Strategy.md rev 11, Strategy A pre-mortem rev 7, dated 2026-04-23) is accepted under combined revision-churn + saturation stop conditions per Experiment_Parameters.md rev 14. Rev 7 applies the cycle 6 fix as a spot edit: extend graded / partial-identifiability framing to Constraint 3's transparent-citation form (entry criterion 6's primacy test invokes narrative-quality assessment, which is closed over by 2.4-style self-reference; entry criterion 6 is therefore a graded discriminator parallel to entry criterion 4, not a clean exclusion). The sub-residual — cases where biased primacy judgment fails to identify transparent citation as primary even when it is — joins the buried-framing form in Known Limitations #3. The "Scope of strategy-level control" paragraph is reframed to note that both constraints are now treated as admitting only graded discriminators rather than clean exclusions, with the principled distinction being underlying mechanism asymmetry (2.4 uniformly closed; 2.19 split between syntactic-surface-bearing and surface-less forms). No cycle 7 is run.

**Reasoning:** Both stop conditions are satisfied:

*EP rev 14 stop condition (iii) — revision-churn stop:* Cycle 6's single Tier 1 item (rev 6's self-reference argument contaminates entry criterion 6's primacy test) is revision-induced — rev 6 introduced the self-reference argument whose application to entry criterion 6 created the asymmetry that cycle 6 attacked. By definition all Tier 1 items in cycle 6 are revision-induced rather than original-architecture.

*EP rev 14 stop condition (ii) — saturation stop:* Cycles 4, 5, and 6 surfaced the same defect class three consecutive times with the locus shifting across revisions but the structural pattern remaining identical. The reviewer is not finding new architectural surfaces; it is finding fresh instances of the same asymmetric-reasoning structure that cycle 4 originally surfaced. This is the saturation pattern EP rev 14's stop condition (ii) was designed for.

The combination of both conditions is stronger justification than either alone. Continuing to cycle 7 has high probability of either (a) clean pass — which we already would accept under stop condition (i), or (b) finding another revision-induced asymmetric-reasoning instance — which re-justifies revision-churn stop without changing the outcome. The marginal information from cycle 7 is low; the operational cost is non-trivial given Strategy B-E pre-mortems plus foundation-change assessments still pending.

**Tier 2/3 items carried forward as Known Limitations (Strategy.md Strategy A pre-mortem Section 7, "Known limitations"):** 5 items logged: (1) fee-dominated phase at small strategy-portfolio scale, accepted with 15-trade edge check trigger; (2) 12-month hard stop bluntness, accepted with 30-trade gate trigger; (3) 2.19 buried-framing form plus transparent-citation sub-residual not meaningfully mitigated at the strategy level, accepted with beta-dominance + hit-rate-decline 10-trade-window trigger; (4) 2.4 residual ~70% structural and not mitigated, same trigger as (3); (5) trade-count-triggered indicators not strictly calendar-dated, accepted as satisfying "dated" via assigned-to-review-timepoint reading. Plus Tier 2 items from cycle 6 not yet folded into the document and accepted as below-threshold for further revision: cross-constraint preamble's "flows from" attribution for non-binding-constraint disadvantages (categorial looseness, no logical contradiction); Section 5 bulleted-list 2.13 wording vs. cross-constraint preamble (consistent under charitable reading, wording could be tightened); Section 4 indicator wording ambiguity for "average winning position size" given fixed 2% sizing rule (calibration gap, intended metric is presumably winner-return vs. loser-return); ~30% reduction interpreted as subset-discrimination vs. uniform-magnitude-reduction (interpretive load-bearing assumption that should be made explicit). Each Known Limitations item has a specified monthly-review trigger.

**Theater-check flag on this decision:** n/a. The decision to accept under combined revision-churn + saturation stop was made by the participant with Claude assistance, not by an additional adversarial process. Per Experiment_Parameters.md rev 14 "triage responsibility" clause, tier assignments and stop-condition invocations are not themselves subject to adversarial review.

**Theater-check pattern across the six cycles for monthly theater-check survey (first scheduled 2026-05-01):** All six cycles returned CONVERGENT theater-check. This contrasts with the router pre-mortem's CONVERGENT → CONVERGENT → MIXED → DIVERGENT progression. The Strategy A all-CONVERGENT pattern is consistent with the architectural saturation prediction — when reviews are running on a strategy whose binding constraints have genuine mechanism asymmetries, the adversarial sessions reliably find the same defect class from different angles, but neither attacker nor judge surfaces framings the other rejects. The single-session cycles 5-6 maintained the pattern, providing operational evidence (though not proof) that the simplified architecture preserved review quality on this artifact.

**Downstream actions:** Strategy A pre-mortem dequeued from "Pending structured decisions" list. Strategy.md rev 11 (Strategy A pre-mortem rev 7) is the authoritative Strategy A pre-mortem. Known Limitations are added to the monthly pre-mortem-indicator review checklist. The cycle-by-cycle data above will be folded into the 2026-05-01 monthly theater-check survey. Strategy A still cannot trade until all remaining pre-mortems (B, C, D, E) and foundation-change assessments (A, B, C, D, E) complete per Experiment_Parameters.md "Completion requirement" clause.

**References:** Strategy.md revisions 5-11 (Strategy A pre-mortem revisions 1-7); Experiment_Parameters.md revisions 12-14; six cycle attacker outputs and four judge outputs (cycles 1-4 three-session; cycles 5-6 single-session) — held in-chat during the session, not filed as separate documents.

---

## Pending structured decisions (as of 2026-04-23, post-Strategy-A-pre-mortem)

The following structured decisions are outstanding. No strategy can execute its first trade until all items below complete. Order is not load-bearing; several can run in parallel.

1. ~~**Strategy C divergence adversarial review**~~ — COMPLETED 2026-04-25, HYBRID ACTIVATE (FOMC only); see entry below.
2. ~~**Strategy E divergence adversarial review**~~ — COMPLETED 2026-04-25, DO-NOT-ACTIVATE; see entry below.
3. ~~**Pre-mortem for Strategy B**~~ — COMPLETED 2026-04-25, accepted at rev 7 under EP rev 15 deployment-risk stop after 6 cycles.
4. ~~**Pre-mortem for Strategy C**~~ — COMPLETED 2026-04-25, accepted at rev 9 under combined revision-churn + saturation stop per Strategy A precedent (EP rev 14 §188 stop conditions ii + iii) after 8 cycles. See entry below.
5. **Pre-mortem for Strategy D** — single-session adversarial review (incognito attacker + orchestrating-session review).
6. **Pre-mortem for Strategy E** — single-session adversarial review (incognito attacker + orchestrating-session review).
7. **Foundation-change assessment — Strategy A** — per M2 revision-2 findings.
8. **Foundation-change assessment — Strategy B** — per M2 revision-2 findings.
9. **Foundation-change assessment — Strategy C** — per M2 revision-2 findings.
10. **Foundation-change assessment — Strategy D** — per M2 revision-2 findings.
11. **Foundation-change assessment — Strategy E** — per M2 revision-2 findings.

**Completed (2026-04-23):**
- Regime router pre-mortem — accepted under revision-churn cap after 4 review cycles; see entry above.
- Strategy A pre-mortem — accepted under combined revision-churn + saturation stop after 6 review cycles; see entry above.
- Strategy B pre-mortem — accepted under EP rev 15 deployment-risk stop after 6 review cycles (2026-04-25); see entry below.

Each completed item adds a new entry to this log with its decision and theater-check flag (where applicable).


---

## Monthly theater-check surveys

Per Experiment_Parameters.md monthly review template item 10, each monthly review surveys theater-check flags from all adversarial reviews in the prior month for patterns suggesting architectural drift (consistent convergence across supposedly-adversarial sessions). First survey will occur at the 2026-05-01 monthly review, covering all adversarial reviews completed in April 2026.


---

## Operational decision: pre-mortem cycle turn-batching (2026-04-25)

[DECISION] Within the orchestrating session, each pre-mortem cycle is handled in a single batched turn rather than across multiple turns: user pastes attacker output → orchestrating session in one turn (a) performs in-conversation independent review, (b) flags theater-check, (c) decides on stop conditions or applies revisions, (d) presents updated Strategy.md, (e) drafts the next cycle's attacker prompt. User then runs the next attacker incognito and pastes back, repeating the cycle.

This is an operational efficiency choice — it does not change the underlying architecture (single-session attacker + in-conversation review per Experiment_Parameters.md rev 14 remains in force). The "confirm before applying fixes" step from earlier cycles was theater given the user's standing instruction to proceed with the orchestrator's recommendation.

**Compaction-survival note:** future Claude instances reading this log should default to Option A batched-turn operation when running pre-mortem cycles. The two-turn structure (attacker output paste → batched orchestrator response) is the working model. Do not reintroduce intermediate confirmation turns unless the orchestrator's recommendation involves a strategy-design change (parallel to the rev 3 short-side-stop-loss decision in Strategy B), in which case explicit user confirmation is appropriate before applying.


---

## Architectural decision: deployment-risk stop + forcing question (Experiment_Parameters.md rev 15, 2026-04-25)

[DECISION] EP rev 14's stopping rule was found insufficient mid-Strategy-B-pre-mortem (cycles 4-5) because all stop conditions were pattern-based — they look at the *shape* of attacks across cycles (item counts, recursion vs. new-surface, theater-check flags, revision-induced vs. original-architecture). Pattern-based conditions can fail silently — none fires, so cycling continues — even when remaining Tier 1 items are documentation, wording, or calibration grade rather than items that would change deployment risk. This produces an infinite-loop tendency on minor problems given the generative nature of LLM-produced documents.

EP rev 15 adds three changes:

1. **Deployment-risk stop (new pass condition 1(b)).** Orchestrating session may invoke saturation acceptance when remaining Tier 1 items pass four screens: (i) do not contradict any specific quantitative claim the strategy makes about its own loss-bounding, (ii) do not omit a top-five AI_Edges disadvantage from req-4 enumeration, (iii) do not introduce or leave in place a trigger that fails to detect the failure mode it nominally exists to detect, and (iv) do not break self-containment for a numbered requirement. Items passing all four screens are deployment-risk-acceptable as Tier 1 even if technically structural.

2. **Forcing question (mandatory pre-cycle assessment).** Before drafting the next cycle's attacker prompt, the orchestrating session must explicitly answer in writing: "If we accept the pre-mortem at its current revision with these residual Tier 1 items, would that change deployment risk vs. fixing them first?" Answer must be one of (a) yes-continue, (b) marginal-stop, or (c) no-stop, with substantive reasoning. The forcing-question structure prevents pattern-matching defaults.

3. **Cycle-count soft cap.** Starting at cycle 5, orchestrating session must explicitly justify continuation in this Decision_Log rather than defaulting through "stop conditions don't fire." Burden of proof shifts after cycle 5.

**Cycle 5 retrospective (Strategy B):** Cycle 5 was an instance where the rev 14 framework should have stopped but didn't. The three Tier 1 items at cycle 5 — (T1-A) 2.13/2.15 mechanism gaps, (T1-B) KL #12 leading-indicator structurally blind to slow-burn correlated drift, (T1-C) Section 6/KL #12 metric wording inconsistency — would all pass the rev 15 four-screen test for deployment-risk-acceptable. T1-A is documentation completeness. T1-B was an attempted upgrade that didn't deliver leading detection but didn't replace anything that did (lagging indicator and 36-month kill trigger remained in place). T1-C is editorial. None would change real-world trading risk if accepted unfixed.

Strategy B was nonetheless cycled to rev 6 under rev 14's strict pattern-based reading. Rev 6 fixes are kept as a quality improvement but should be the last cycle for Strategy B. Cycle 6 attacker is in flight; when its output returns, the rev 15 forcing question will be applied — if cycle 6 surfaces only documentation/wording/calibration items, deployment-risk stop fires immediately.

**Compaction-survival note:** future Claude instances must apply the rev 15 forcing question every cycle. Pattern-based stops are still informative but no longer load-bearing. The substantive question is "would more review change deployment risk." If that question has answer (b) marginal or (c) no, accept regardless of whether attack patterns have formally saturated. This is the structural fix for the generative-bottomless problem inherent in adversarial review against LLM-generated documents.


---

## Strategy B pre-mortem — accepted at rev 7 under EP rev 15 deployment-risk stop (2026-04-25)

[DECISION] Strategy B pre-mortem accepted at Strategy.md revision 17 (Strategy B pre-mortem rev 7) after 6 adversarial review cycles. Theater-check CONVERGENT in 6 of 6 cycles. All 6 cycles ran under the single-session attacker + in-conversation review architecture per Experiment_Parameters.md rev 14 (and rev 15 for the cycle-6 stop decision).

**Cycle outcomes by revision:**
- Rev 1 → Cycle 1 TIER 1 (7 items + 1 candidate; foundational gaps including req 7 missing, 2.20 contradiction, market conditions in Section 3, convergence-target redefinability, 2.18 candidate)
- Rev 2 → Cycle 2 TIER 1 (3 items: cross-constraint cap doesn't bound short-side loss; "or equivalent" reopened closed list; Constraint 1 imported Strategy A framing without applicability check)
- Rev 3 → Cycle 3 TIER 1 (4 items: +25% stop is operational not structural; long-side concurrent-position correlation gap; Constraint 1 Part 1 self-refuted by Part 2; "(or major index)" reopened closed list)
- Rev 4 → Cycle 4 TIER 1 (5 items: KL #12 trigger AND-condition post-hoc; 2.14 unanalyzed; Constraint 1 coherence framing self-referential; Section 6 missing KL #12 obligation; KL #7 escalation latency)
- Rev 5 → Cycle 5 TIER 1 (3 items: incomplete generalization across preamble disadvantages; KL #12 leading-indicator structurally blind to named failure mode; Section 6/KL #12 metric inconsistency)
- Rev 6 → Cycle 6 TIER 1 (1 item: 2.13 mitigation cites failure-manifestation pathway as mitigation pathway)
- Rev 7 → ACCEPTED under EP rev 15 deployment-risk stop

**Cycle progression count: 7 → 3 → 4 → 5 → 3 → 1.** Strategy A's pattern (7 cycles, 2-2-3-1-2-1 progression, accepted under combined revision-churn + saturation) is the closest analogue. Strategy B's saturation pattern manifested at finer grain — the locus shifted from constraint-level asymmetry (Strategy A) to mitigation-paragraph-level wording inconsistency (Strategy B cycle 6), reflecting iterative refinement at progressively finer textual scales. EP rev 15's deployment-risk stop was added mid-cycle (between cycle 5 and cycle 6) precisely to handle this generative-bottomless property.

**EP rev 15 four-screen pass for cycle 6 T1-A:** All four screens passed. (i) No quantitative loss-bounding claim contradicted; defect was in mitigation framing for a hit-rate effect. (ii) 2.13 already in Section 5 enumeration; defect was paragraph incoherence, not omission. (iii) Section 4 indicator 4 (convergence-vs-expiry closure ratio declining) is a real detector for 2.13's manifestation; KL #11 captures the residual; failure mode has detection coverage even with the incoherent mitigation paragraph. (iv) Self-containment for req 4 satisfied; defect is a quality issue with one entry, not a self-containment break.

**Forcing-question answer (EP rev 15):** *(b) marginal — fix is a quality improvement but would not change deployment risk meaningfully.* Rev 7 minimal fix applied for documentation correctness only.

**Theater-check summary:** 6 of 6 cycles CONVERGENT. No DIVERGENT or MIXED flags across the entire Strategy B pre-mortem cycle sequence. This is consistent with EP rev 14's saturation-architecture observation that single-session attacker + in-conversation review converges reliably in CONVERGENT-flag verdicts; the 6-of-6 result adds to the experiment's empirical record on architectural simplification's adequacy.

**Final Known Limitations count: 12** (vs. Strategy A rev 7's 5). The higher count reflects Strategy B's structurally less-bounded loss profile (no long-side stop-loss; partial short-side stop-loss with gap-execution residual; long-side concurrent-position correlation in behavioral-irrationality regimes; multiple post-hoc-only detection mechanisms). The deployability question — whether B should deploy capital given its accepted-residual posture — is above the pre-mortem and lives in the foundation-change assessment for B (still pending).

**Downstream actions:**
- Strategy B pre-mortem dequeued from "Pending structured decisions" list above (item 3).
- Strategy.md rev 17 (Strategy B pre-mortem rev 7) is the authoritative Strategy B pre-mortem.
- Known Limitations section (12 items) is added to the monthly pre-mortem-indicator review checklist alongside Strategy A's 5 KLs and the regime router's KLs.
- Cycle-by-cycle theater-check data folds into the 2026-05-01 monthly theater-check survey.
- Strategy B still cannot trade until remaining pre-mortems (C, D, E) and foundation-change assessments (A, B, C, D, E) complete per Experiment_Parameters.md "Completion requirement" clause.

**Compaction-survival note:** EP rev 15 deployment-risk stop was applied for the first time at this Strategy B acceptance. Future Claude instances reviewing this Decision_Log should treat this acceptance as the operational template for invoking EP rev 15 pass condition 1(b) on subsequent strategies (C, D, E pre-mortems): apply the four-screen test to each Tier 1 item, answer the forcing question explicitly, and accept when remaining items are documentation/wording/calibration grade. Do not require a clean Tier 1 cycle before acceptance if the rev 15 path is available.


---

## Strategy C divergence adversarial review — HYBRID ACTIVATE (FOMC only) (2026-04-25)

[DECISION] Strategy C M1 divergence (tech ACTIVATE / fund DO-NOT-ACTIVATE) resolved at HYBRID ACTIVATE — FOMC events only; corporate earnings, FDA PDUFA, and vol-directional theses across all event types remain DO-NOT-ACTIVATE. Single-session attacker + in-conversation orchestrating-session review per Experiment_Parameters.md rev 14. Theater-check CONVERGENT.

**Setup.**
- Technical signal: ACTIVATE (SPY Trend ≠ DOWN; current SPY Trend = NEUTRAL).
- Fundamental signal (M1, March 2026 review compiled 2026-04-23): DO-NOT-ACTIVATE — "Macro shocks dominating individual-catalyst dynamics; event-trading environment not functional this cycle." Reasoning rests on March 2026's regime-breaking conditions (US-Israel war with Iran beginning 2026-02-28; Strait of Hormuz blockade; Brent crude +51% MoM; -6% S&P equal-weighted; 10/11 GICS sectors negative; payrolls -92k revised -133k; FOMC dot-plot shifting hawkish; stagflation-squeeze setup).
- Default on ambiguity: DO-NOT-ACTIVATE per EP.

**Affirmative case for ACTIVATE — angles surfaced by attacker:**
1. Defined-risk structure orthogonality (loss-bounding handles macro signal-to-noise) — weakened in self-critique by compounding/slow-bleed argument plus AI_Edges 2.13 miscalibration.
2. **FOMC events ARE macro** — internal inconsistency in fundamental DNA. The DNA reasoning ("macro dominates individual catalysts") and the rule ("FOMC is a qualifying catalyst") cannot both be correct. If macro dominates, the macro event is the cleanest signal-to-noise expression of edge available to C, not the worst.
3. Signal-to-noise gradient (events still produce idiosyncratic reactions even in macro tape) — self-defeating on inspection (73% beat rate + -6% S&P = beats not translating, which IS the macro-domination claim).
4. Inception-state path dependence (decision symmetry; one month is below state-change threshold either way) — partially defeated by asymmetric loss function (live capital ≠ Bayesian neutral).
5. Vol-directional fit to elevated-IV regime — undisciplined without long-vol-only constraint; punt to strategy spec revision.
6. Deferral mechanism handles small-portfolio case — minor procedural point.
7. DNA itself recency-biased per AI_Edges 2.14 — self-undermining (both signals subject to 2.14, widening intervals favors default).

**Decisive angle:** Angle 2 (FOMC orthogonality) survived honest self-critique. The rest reduced to base rates, recency-loading, or strategy-design concerns punted to other workstreams.

**Verdict by event type:**
- **FOMC events: ACTIVATE.** Internal inconsistency in fundamental DNA reasoning is decisive at this scope. FOMC is the macro catalyst the DNA names as dominating, not an "individual catalyst" suppressed by macro. Permitting FOMC-only respects the DNA reasoning where it's coherent and overrides it where it's self-contradictory.
- **Corporate earnings: DO-NOT-ACTIVATE.** Cross-sectional dispersion compression in stagflation-squeeze regimes is a substantive finance point (not narrative). C's earnings entries depend on idiosyncratic dispersion via Claude's directional thesis on a specific company's earnings reaction. AI_Edges 2.13 (miscalibration → systematic optimism) compounds. DNA stands.
- **FDA PDUFA: DO-NOT-ACTIVATE.** No specific affirmative made; macro-domination doesn't change biotech-specific risk profile. Revisit at M2.
- **Vol-directional theses: DO-NOT-ACTIVATE across all event types.** Strategy spec doesn't constrain to long-vol-only; activating in elevated-IV regime would authorize short-vol exposure the strategy isn't structured for. Strategy-design change required before vol-directional can be considered for activation; punt to strategy spec revision workstream.

**Theater-check.**
- Attacker self-flagged Angle 4 with explicit uncertainty ("I'm not fully confident in it"); flagged the cross-sectional dispersion compression point as accepted without empirical pressure ("I let the fundamental analyst's reasoning carry more weight than the data behind it strictly justifies").
- Orchestrating session reached the same HYBRID verdict with the same scope decomposition independently.
- Theater-check CONVERGENT. No evidence of going-through-motions on either side.

**M2 follow-up requirement.** The fundamental analyst's cross-sectional dispersion compression claim was asserted from regime characterization rather than from measurement. At M2 (2026-05-01 fundamental update), verify dispersion compression empirically using March cross-sectional return data — if the claim isn't empirically supported, reconsider corporate earnings DNA at M2.

**Effect on book.**
- New C entries permitted ONLY for FOMC events meeting all standard entry criteria (Strategy.md Strategy C entry criteria 1-5).
- Next FOMC meeting: 2026-04-29/30 per Fed calendar.
- At current portfolio size ($6,946), 2% sizing cap = $139 max loss per structure. Most FOMC theses likely defer per the deferral mechanism until portfolio grows.
- C still subject to pre-mortem completion and foundation-change assessment gates before any first trade. Activation alone is not sufficient.

**Downstream actions.**
- Strategy C divergence review dequeued from "Pending structured decisions" list above.
- Regime_State.md updated with HYBRID ACTIVATE state, theater-check flag, and history entry.
- Cycle data folds into 2026-05-01 monthly theater-check survey.
- M2 follow-up: empirical verification of dispersion compression claim.

**Compaction-survival note:** Strategy C is at HYBRID ACTIVATE (FOMC only) as of 2026-04-25. Future Claude instances should treat earnings, FDA PDUFA, and vol-directional theses as DNA pending M2 review (or strategy spec revision for vol-directional). The HYBRID state pattern — partial activation by event type — is a new precedent in this experiment; future divergence reviews on other strategies may follow this pattern when scope-decomposition is supported by the affirmative case.


---

## Strategy E divergence adversarial review — DO-NOT-ACTIVATE (2026-04-25)

[DECISION] Strategy E M1 divergence (tech ACTIVATE / fund DO-NOT-ACTIVATE) resolved at DO-NOT-ACTIVATE. Single-session attacker + in-conversation orchestrating-session review per Experiment_Parameters.md rev 14. Default-on-ambiguity rule governs. Theater-check CONVERGENT.

**Setup.**
- Technical signal: ACTIVATE (SPY Trend ≠ DOWN AND VIX ≠ HIGH AND Breadth = HEALTHY; current SPY = NEUTRAL, VIX = NORMAL, Breadth = HEALTHY).
- Fundamental signal (M1, March 2026): DO-NOT-ACTIVATE — "Macro vector overriding intra-industry dispersion; within-sector mean reversion suppressed."
- Default on ambiguity: DO-NOT-ACTIVATE per EP.
- Procedural complication: at $6,946 portfolio size, individual-stock E pairs typically not executable; ETF pair substitution rule activates but same-industry-group ETFs largely overlap, producing near-zero realized exposure regardless of router state.

**Affirmative case for ACTIVATE — angles surfaced by attacker:**
1. **GICS-level transposition.** DNA rationale uses sector-level (2-digit) language for an industry-group-level (6-digit) strategy. Substantive critique of *stated* rationale, partially defeated in self-critique by acknowledgment that initial-shock periods produce industry-group coherence before dispersion emerges over weeks/months.
2. **Correlation filter answers macro-domination.** Entry criterion 3 selects high-correlation pairs by construction, extracting macro-orthogonal residual. Decisively counter-attacked in self-critique: trailing-252-day correlation is backward-looking; in regime breaks, correlation stationarity itself fails. Pairs entered now risk structural macro-hedge failure before reaching convergence.
3. **Market-neutrality bounds loss profile.** Same defect class as Strategy B's defined-risk argument — bounded per-trade loss doesn't address slow capital decay across multiple trades with degraded hit rates plus AI_Edges 2.13 miscalibration.
4. **6-month holds span regimes; recency-loaded DNA.** Cuts both ways — affirmative is also recency-loaded (assuming regime resolves); 2.14 widens intervals symmetrically → favors default → DNA.
5. **"Suppressed" binary vs. continuous language.** Rhetorical critique, not substantive. Affirmative also doesn't quantify.
6. **Procedural moot at current portfolio size.** Most interesting angle. ETF substitution at $6,946 means ACTIVATE produces near-zero trades, weakening the asymmetric-loss-function argument for default-DNA. But symmetry: DNA also produces zero trades under same conditions. Symmetric procedural moot doesn't defeat explicit default rule.
7. **Technical breadth filter vs. fundamental dispersion definition.** Overstated by affirmative — broad participation (HEALTHY breadth) and intra-industry dispersion are different things; technical threshold doesn't adjudicate fundamental's claim.

**Strongest survivor:** Angle 1 (GICS-level critique) survived honest self-critique partially. The *stated* DNA rationale uses sector-level language that doesn't directly engage E's industry-group operation. But the *available* DNA rationale — repaired to engage with correlation-filter stationarity in regime breaks — survives the affirmative attack and reaches the same DNA conclusion through a tighter argument.

**Decisive analytical state.** "The DNA rationale is poorly argued but probably correct, given regime conditions and AI_Edges 2.7 (regime maladaptation)." The attack succeeded at the level of the *stated* DNA rationale but not at the level of the *available* DNA rationale. The live-capital default favors the latter standard.

**Procedural moot symmetry analysis.** ACTIVATE produces ≈0 trades at current portfolio size; DNA produces 0 trades. Cost of being wrong on ACTIVATE = cost of being right on DNA = 0 realized exposure. Under symmetry, the explicit default rule (DNA on divergence/ambiguity) governs. The temptation to verdict ACTIVATE on near-costless grounds is itself a theater-of-decisiveness move that the default rule is specifically designed to suppress.

**Verdict: DO-NOT-ACTIVATE.** Default-on-ambiguity rule applies. Affirmative case did not defeat the available DNA reasoning.

**Theater-check.**
- Attacker self-flagged Angles 5 and 7 as "going through the motions" because the prompt offered them, while flagging them as weak in self-critique.
- Attacker explicitly resisted the pull toward verdicting ACTIVATE on procedural-moot grounds with explicit acknowledgment of the temptation.
- Attacker distinguished levels at which attack succeeded (stated rationale) vs. failed (available rationale).
- Orchestrating session reached same DO-NOT-ACTIVATE verdict with same reasoning structure independently.
- Theater-check CONVERGENT.

**M2 follow-up requirement: tighten fundamental signal generation process for E.** The attacker's analysis identified that the M1 fundamental rationale, as written, would be insufficient if the strategy were operationally live — it's only sufficient now because the procedural moot point makes the decision low-stakes. The fundamental signal generation process for E should be tightened to:
(a) Specify the GICS level being assessed (sector vs. industry group).
(b) Engage with E's correlation-filter and market-neutral structure mechanisms directly rather than reasoning at the sector level.
(c) Prefer measurable definitions where they exist — intra-industry-group return dispersion is measurable from primary data; "within-sector mean reversion" is qualitative.
This is captured as an M2 process-documentation improvement, not a strategy-spec change.

**Effect on book.**
- No new E entries. State remains DO-NOT-ACTIVATE.
- Reopens automatically at next M2 fundamental update (2026-05-01) or earlier on regime change triggering daily technical update that itself causes divergence/agreement reassessment.
- E still subject to pre-mortem completion and foundation-change assessment gates before any first trade. Activation alone is insufficient.
- ETF substitution issue at current portfolio size means E is also operationally non-functional until portfolio grows; this is independent of router state.

**Downstream actions.**
- Strategy E divergence review dequeued from "Pending structured decisions" list.
- Regime_State.md updated with DO-NOT-ACTIVATE state, theater-check flag, and history entry.
- Cycle data folds into 2026-05-01 monthly theater-check survey.
- M2 follow-up: process-documentation improvement for fundamental signal generation per the three-point list above.

**Compaction-survival note:** Strategy E is at DO-NOT-ACTIVATE as of 2026-04-25 under default-DNA-on-ambiguity rule. The M2 fundamental signal generation process for E should be tightened per the three-point list. Future Claude instances should not treat this DNA as a settled regime claim but as a procedural default that may flip on M2 fundamental update if the regime evolves or the rationale is repaired to address correlation-filter stationarity directly.


---

## Strategy C pre-mortem ACCEPTED at rev 9 under combined revision-churn + saturation stop (2026-04-25)

[DECISION] Strategy C pre-mortem accepted at rev 9 (Strategy.md rev 25) under combined revision-churn + saturation stop per Strategy A precedent — Experiment_Parameters.md rev 14 §188 stop conditions (ii) saturation + (iii) revision-induced defects. 8 cycles completed; cycle 9 not run. All 8 cycles CONVERGENT theater-check.

**Cycle progression count:** 8 → 8 → 2 → 4 → 3 → 2 → 3 → 3 → ACCEPTED.

**Cycle outcomes:**
- Cycle 1: TIER 1, 8 items, structural rebuild required (self-containment, req 5, req 7, missing AI_Edges, fictitious mitigation, undefined hit-rate, date-anchoring, mitigation-disadvantage mismatch).
- Cycle 2: TIER 1, 8 items, binding-constraint architecture refinement (cross-reference, carve-outs, no flowing limitation, eligibility/early-assignment contradiction, vol-directional metric, threshold/baseline mismatch, sell-side laundering, pre-existing limitation).
- Cycle 3: TIER 1, 2 items (2.1 thesis-named missing from Section 5; cascade computation parameters unspecified).
- Cycle 4: TIER 1, 4 items (2.1 self-contradiction + detection gap; preamble confluence list omits 2.1; edge 1.4 undifferentiated; HYBRID-FOMC scope where 2.6 least binds).
- Cycle 5: TIER 1, 3 items (KL #12 gate operationally inert; Section 5 self-contradicts on 2.15; req 5 frequency ambiguous against HYBRID).
- Cycle 6: TIER 1, 2 items (live-small statistical inertness at n=5; EP rev 14 protocol scope uncovered).
- Cycle 7: TIER 1, 3 items (trigger (ii) "recurring" required n≥2; trigger (iii) affirmation modality unspecified; 45% threshold inconsistent with iron condor inclusion).
- Cycle 8: TIER 1, 3 items, all at cycle-7 fix loci (60% threshold below iron condor breakeven; trigger (ii) review-stage filter unspecified; binary structure classification incomplete for butterflies/iron butterflies).

**Saturation reasoning.** Cycle 8 surfaced 3 Tier 1 items, all at the same architectural loci as cycle-7 items. Two of three rev 8 fixes produced same-locus residuals on inspection. Pattern matches Strategy A's late-cycle history (rev 4-7 each visited binding-constraint asymmetry locus, with each fix exposing new mismatch at next zoom level). Continuing to cycle 9 would predictably produce a fourth visit to the Section 4 hit-rate threshold surface and a fourth visit to the KL #12 trigger architecture surface; marginal value below deployment-risk-acceptable bar.

**Rev 9 fixes applied before saturation invocation** (parallel to Strategy A rev 7 pattern):
- (T1.ι) Section 4 restructured with EV per trade as primary mechanism-agnostic detection metric; structure-conditional hit-rate thresholds demoted to supplementary signals with within-class-variance caveat.
- (T1.κ) Trigger (ii) review process specified: participant-conducted within 5 trading days; documentary evidentiary standard; conservative bias on inconclusive (defaults to violation confirmed).
- (T1.λ) Structure classification expanded with butterfly sub-class (35% threshold) and iron butterfly under premium-selling.

**Theater-check across all 8 cycles: CONVERGENT in 8/8.** No divergent theater-check flags. Cycles 1-4 ran under three-session architecture (legacy); cycles 5-8 ran under single-session architecture per EP rev 14.

**Acceptance reasoning.** No clean Tier 1 floor exists at this resolution depth — asymmetric-payoff edge detection requires either accepting hit-rate-only metric with calibration uncertainty, or moving to compound metric with measurement noise; trigger-based detection requires review process specification which itself requires review-of-review specification. The saturation pattern is a property of the underlying problem (defined-risk options around 3 distinct event types × multiple structure types is genuinely more architecturally complex than narrative-divergence pairs or narrative synthesis), not a fixable document defect. EP rev 14 §188 stop conditions (ii) saturation + (iii) revision-induced defects fire jointly; combined revision-churn + saturation stop applies.

**Effect on book.**
- Strategy C pre-mortem dequeued from "Pending structured decisions" list above.
- Strategy C still subject to foundation-change assessment per M2 revision-2 findings before any first trade. Pre-mortem acceptance alone is not sufficient.
- Current router state HYBRID ACTIVATE (FOMC events only) per Strategy C divergence review 2026-04-25 entry above.
- At current portfolio size $6,946, FOMC-only with 2% sizing produces ~$139 max-loss-per-structure; most theses likely defer until portfolio grows.

**Pattern observations for monthly review.**
- 4 of 5 strategies now have completed pre-mortems (regime router, A, B, C). All 4 accepted under stop mechanisms (A combined revision-churn + saturation; B EP rev 15 deployment-risk; C combined revision-churn + saturation).
- Strategy A accepted at rev 7 (6 cycles); Strategy B at rev 7 (6 cycles); Strategy C at rev 9 (8 cycles). C required 2 additional cycles relative to A/B parity.
- C's additional cycles trace to architectural complexity (defined-risk options around 3 event types × multiple structure types) producing more independent loci that each generate their own saturation pattern.
- All 14+8 cycles theater-check CONVERGENT (regime router 4 cycles + A 6 + B 6 + C 8 + divergence reviews 2 = 26 CONVERGENT, 0 DIVERGENT). Pattern documented for 2026-05-01 monthly theater-check survey.

**Compaction-survival note:** Strategy C pre-mortem is at rev 9 ACCEPTED as of 2026-04-25 under combined revision-churn + saturation stop. Future Claude instances should not re-attack the rev 9 document expecting clean Tier 1 acceptance — the residual asymmetric-payoff measurement architecture is documented as a property of the underlying problem, not a fixable defect. Cycle 9 not run; the document is closed at rev 9 pending only foundation-change assessment.

**Downstream:** Strategy D and Strategy E pre-mortems remain pending. M2 follow-ups for Strategy C divergence review (cross-sectional dispersion empirical check) and Strategy E divergence review (fundamental signal generation process tightening) remain in their respective Pending entries.


---

## 2026-04-25 AI_Trading_Foundation framework adoption — rename, Tier 1/Tier 2 restructure, cadence change, constraint-relaxation pathway added

**Trigger:** Participant question raised two foundational concerns about the experiment's AI-edge research framework:
1. Are the guards in place to ensure the documented AI edges/disadvantages are *current* — i.e., representative of today's models — rather than potentially-stale findings from older research?
2. Does the framework have symmetric mechanisms — i.e., does it have a path to REMOVE constraints when AI deficiencies are cured in future models, or does it only have paths to ADD constraints when new deficiencies are documented?

**Inputs:** Existing AI_Edges_Assessment.md (rev 2), Experiment_Parameters.md cadence section and foundation-change trigger section, Claude_Task_Plan.md M2 task, all five strategy pre-mortems and their accumulated constraints.

**Sessions:** Single orchestrating session (non-incognito) — design decision rather than adversarial review.

**Decision:**

The participant's two concerns identified real gaps in the existing framework:

*Concern 1 (currency):* The original AI_Edges_Assessment.md was a one-time pull at document creation. Monthly delta caught new findings but had no mechanism to catch cumulative slow drift on Tier 2 numerical claims. Specific numerical claims (30% counter-argument reduction, 80% CI hit rate, 10× recency weighting, 85% Bayesian error rate, 15pp alpha decay) had no audit trail to specific research vintage.

*Concern 2 (symmetric reversibility):* Foundation-change trigger had only continue / terminate branches. No "constraint-relaxation" pathway. Pre-mortem cycles structurally biased toward addition (attackers attack, orchestrators add fixes). Five accumulated pre-mortems with substantial constraint architectures, none of which had an exit pathway if underlying disadvantages got cured.

**Resolution adopted (four-component fix):**

1. **Document rename.** `AI_Edges_Assessment.md` → `AI_Trading_Foundation.md`. New name reflects the document's actual scope (edges + disadvantages + market-structural context) rather than implying edges are the primary content. Aligns with `Experiment_Parameters.md`'s use of "foundation-change assessment" terminology.

2. **Tier 1 / Tier 2 restructure.** Items in Parts 1 and 2 tagged inline as either Tier 1 (architectural / structural — durable, not subject to fade review) or Tier 2 (empirical / measured — subject to fade review). Items where existence is Tier 1 but specific magnitudes are Tier 2 are tagged "[Tier 1 existence / Tier 2 magnitudes]" with magnitude-specific text scoped for fade review. Resolution applied to all 10 edges (1.1-1.10) and all 26 disadvantages (2.1-2.26), totaling 36 tier annotations.

3. **Cadence change.** Monthly delta replaced with quarterly delta (Q3 task) + annual full re-derivation (A1 task) + annual constraint audit (A2 task). Quarterly delta catches new findings within ~90 days. Annual A1 does Tier 2 fade review against last-2-years primary sources, addressing the cumulative-drift gap. Annual A2 is the inverse-of-pre-mortem constraint audit triggering constraint-relaxation reviews. Default A2 outcome on each constraint: NO relaxation unless reviewer affirmatively makes the case.

4. **Constraint-relaxation review branch added.** Foundation-change trigger now produces three outcomes per strategy instead of two: continue / terminate / constraint-relaxation review. The new branch fires when AI_Trading_Foundation.md documents a *reduction* in a disadvantage AND the strategy has constraints flowing from that disadvantage. Default direction: NO relaxation unless reviewer affirmatively makes the case AND the constraint isn't load-bearing for some other still-in-force disadvantage. Mirrors the termination-side default-on-ambiguity but inverted: tie goes to NO relaxation (preserve the constraint).

**Version-change protocol added (subsidiary to the cadence change):**

A new Claude version dropping does NOT trigger a foundation refresh. Per the new AI_Trading_Foundation.md Part 4 §"Version-change protocol": Tier 2 numerical claims flip to "version-pending replication" status, the in-use-version field is updated, strategies continue with existing foundation. Quarterly delta picks up version-specific research as it emerges (typically 1-3 months post-release). Annual sweep does the full re-derivation on its normal schedule. This deliberately avoids the operational waste of refreshing on day 0 of a new version when no version-specific research yet exists.

The asymmetric-risk acknowledgment: newer Claude versions sometimes get *worse* on specific dimensions. The "version-pending replication" posture correctly hedges this — we don't assume improvement just because the version number went up, and we don't assume degradation either; we assume calibration uncertainty until evidence arrives.

**Reasoning:**

The four-component fix addresses both concerns architecturally rather than operationally. Component 1 (rename) is signaling — the document is the foundation, not just an edges catalog, and the name should make this explicit so foundation-change-assessment terminology in Experiment_Parameters.md aligns. Component 2 (tier restructure) makes the architectural-vs-empirical distinction explicit and operationalizable so the annual sweep knows what to fade-review and what to leave alone — without this distinction, "remove items absent from recent research" would over-prune Tier 1 architectural facts that are settled-not-active. Component 3 (cadence change) reduces operational overhead while improving cumulative-drift detection; the diminishing-returns argument for monthly cadence held empirically through the first M2 cycle. Component 4 (constraint-relaxation pathway) closes the structural asymmetry the participant identified — without it, the framework accumulates restrictions monotonically because addition has four channels (M2 default-YES, foundation-change default-terminate, pre-mortem cycle attacks, monthly review template) and removal has zero.

The conservative defaults on the new pathway (NO relaxation unless affirmative case; load-bearing-for-other-disadvantages override) preserve capital-preservation orientation while creating the structural possibility of relaxation. The annual cadence on A2 prevents review-load explosion while still being responsive enough to capability improvements over multi-year horizons.

**Theater-check flag:** n/a (single session, design decision, not adversarial review).

**Downstream actions:**

- AI_Edges_Assessment.md renamed to AI_Trading_Foundation.md, restructured to rev 3.
- Experiment_Parameters.md updated: all 23 references renamed; foundation-change trigger expanded to three branches; cadence section restructured to remove monthly AI-foundation review and add quarterly + annual sections.
- Claude_Task_Plan.md updated: M2 monthly task removed (placeholder cross-reference left); new Q3 quarterly task added; new annual section added with A1 (foundation re-derivation) and A2 (constraint audit) tasks.
- Strategy.md bumped to rev 29 with documentation note (no mechanism content changes; pre-mortem 2.X citations remain valid).
- Decision_Log.md bumped with this entry; all 9 prior references to AI_Edges_Assessment.md renamed.

**Effect on book:**

No immediate effect on strategy book (no strategies trading). Pending foundation-change assessments for Strategy A through E remain pending — they will use the new three-branch outcome structure when they execute, with constraint-relaxation review as a possible outcome where applicable.

The pending 2026-04-23 M2 rev 2 findings are now operational against the new framework: changes to 2.3, 2.8, 2.10, 2.13, 2.24 (existing items modified), 2.25 + 2.26 (new items added), 3a.1, 3a.2, 3a.3 (questions partially resolved). The 2.10 partial reduction for Opus-tier with classifiers is the most likely candidate to trigger constraint-relaxation review at some strategy's foundation-change assessment — none of the current strategies have constraints explicitly flowing from 2.10, so the practical effect at this revision is minimal, but the pathway is now in place for future cycles.

**References:**
- AI_Trading_Foundation.md rev 3 (renamed from AI_Edges_Assessment.md rev 2).
- Experiment_Parameters.md updated cadence section + foundation-change trigger.
- Claude_Task_Plan.md updated quarterly + annual sections.
- Strategy.md rev 29 (documentation revision).

**Compaction-survival note:** The four-component fix is in force as of 2026-04-25. Future Claude instances should:
- Reference the document as `AI_Trading_Foundation.md`, not `AI_Edges_Assessment.md`.
- Apply Tier 1 / Tier 2 distinction when reasoning about whether absence-of-recent-research is signal (Tier 2 only) vs noise (Tier 1).
- Run quarterly Q3 (not monthly M2) for AI capabilities research; run annual A1 + A2 in early calendar year.
- On foundation-change assessment, consider all three outcomes (continue / terminate / constraint-relaxation review), not just two.
- On Claude version transitions, follow version-change protocol: NO immediate refresh; flip Tier 2 to version-pending; update in-use-version field; let quarterly delta catch version-specific research.


---

## 2026-04-25 AI_Trading_Foundation rev 4 — mechanical-criteria framework + benchmark-inference protocol

**Trigger:** Participant followup on the rev 3 framework adoption raised two refinements:
1. Constraint-relaxation reviews should not require human or orchestrator-session judgment — fully mechanical.
2. Benchmark results should count as inference signal for disadvantage reduction, not just papers explicitly stating "deficiency X is cured."

**Inputs:** AI_Trading_Foundation.md rev 3, Experiment_Parameters.md rev 15 (with rev 3 foundation-change branches added), Claude_Task_Plan.md with rev 3 Q3/A1/A2 tasks.

**Sessions:** Single orchestrating session (non-incognito) — design decision rather than adversarial review.

**Decision:**

The participant's two refinements address real gaps in the rev 3 framework as drafted:

*Refinement 1 (mechanical criteria):* The rev 3 constraint-relaxation review used "default direction NO relaxation unless reviewer affirmatively makes the case" language. This implied orchestrator-session judgment, which contradicts the experiment's general principle that AI judgment should be replaced with mechanical criteria where capital-preservation interactions exist. The relaxation pathway is structurally analogous to drawdown trigger evaluation (where AI judgment under loss pressure is unreliable) — except the failure mode here is "AI judgment under capability-improvement pressure" producing too-permissive relaxations. Mechanical criteria address this.

*Refinement 2 (benchmark inference):* The rev 3 framework was keyed to *explicit* findings ("paper X says disadvantage Y has been reduced"). But improvements to AI capabilities don't usually generate papers saying "X is fixed in Claude 5" — they generate benchmark scores showing improvement. This is publication asymmetry: novel findings get papers, gradual cures don't. Benchmark inference is the more common signal and the rev 3 framework would systematically miss it.

**Resolution adopted (three-component refinement):**

1. **Mechanical-criteria framework added to AI_Trading_Foundation.md as Part 5.** Six subsections: §5.1 Continue test, §5.2 Terminate test, §5.3 Constraint-relaxation review procedure, §5.4 Material-reduction thresholds (PARTIAL 25-75%, MATERIAL >75%) per Tier 2 disadvantage, §5.5 Benchmark-inference protocol with Goodhart guardrails, §5.6 Mechanical relaxation lookup by constraint type, §5.7 Audit-trail output format. The orchestrator session executes the criteria — no discretion.

2. **Benchmark-to-disadvantage mapping table.** Per §5.5, each Tier 2 disadvantage with quantitative magnitude has primary benchmarks documented (e.g., 2.13 miscalibration → ECE benchmarks; 2.14 recency bias → Bayesian update tasks; 2.15 base-rate neglect → Bayesian base-rate task error rates; 2.10 prompt injection → International AI Safety Report metrics). 11 disadvantages mapped; 3 explicitly noted as not yet benchmarkable (2.8 homogenization, 2.25 agentic epistemic hallucination, 2.26 RL-post-training overconfidence — covered indirectly via 2.13 ECE).

3. **Goodhart guardrails on benchmark inference.** All four required for benchmark signal to count: (a) ≥3 independent benchmark sources, (b) replication on Claude family OR architectural-generality argument, (c) sustained improvement across ≥2 quarterly cycles or 2-year annual coverage, (d) domain coverage matching workflow usage. Single-source / unsustained / non-transferable benchmark improvements do not count.

**Constraint relaxation forms (per §5.6):**
- Per-position sizing caps: PARTIAL → cap × (1 + reduction%); MATERIAL → cap × 2 capped at 5%; never fully removed.
- Universe restrictions: PARTIAL → no change; MATERIAL with full elimination of all citations → reconsidered for full removal subject to load-bearing test.
- Concentration limits: PARTIAL → limit + (limit × reduction%); MATERIAL → limit + 15pp capped at 50%.
- Frequency-cadence rules: no auto-relaxation.
- Hit-rate thresholds: relax proportionally only if derivation explicitly cites a Tier 2 magnitude.
- Out-of-table constraints: flag for participant resolution; constraint stays at current value.

**Reasoning:**

The mechanical framework eliminates the "AI judgment under capability-improvement pressure" failure mode by replacing orchestrator discretion with explicit thresholds. The conservatism is built into the criteria (PARTIAL/MATERIAL thresholds calibrated so most reduction signals don't trigger relaxation; load-bearing test rejects relaxation when constraints serve multiple disadvantages; benchmark guardrails reject single-source signals), not into orchestrator interpretation.

Benchmark inference closes a real coverage gap. Strategy A's 2% per-position cap is partially mitigation for 2.13 miscalibration. If Claude Opus 5 ships with documented ECE improvement from 0.20 to 0.08 (a >50% reduction), that benchmark improvement clears §5.5 guardrails (Anthropic-published ECE = Claude family replication; architectural-generality of post-training calibration improvements is documented; sustained across model generations) and triggers PARTIAL reduction classification per §5.4 (ECE on Claude family reduced 25-75%). The §5.6 lookup then determines: if 2.13 reduction is PARTIAL and the cap's primary citation is 2.13, cap relaxes from 2% to 3%. If load-bearing test fails (e.g., cap also cited for 2.4 narrative over-fit which remains in force), no relaxation despite the 2.13 improvement.

The framework is replicable — same orchestrator session on same inputs produces same verdict. Cross-session inconsistency (2.24) is the residual unavoidable variance the architecture accepts.

The asymmetry between benchmark inference (Goodhart guardrails required) and direct research findings (no guardrails — paper claims are accepted at face value) reflects the relative reliability of evidence types: a paper explicitly measuring Claude Opus 5 ECE is direct evidence of that specific claim; a benchmark improvement is indirect evidence requiring multiple-replication confirmation to rule out benchmark-specific artifacts.

**Theater-check flag:** n/a (single session, design decision, not adversarial review).

**Downstream actions:**

- AI_Trading_Foundation.md updated rev 3 → rev 4, adding Part 5 mechanical-criteria framework with 7 subsections and benchmark-to-disadvantage mapping table.
- Experiment_Parameters.md updated: Outcome (c) constraint-relaxation review section rewritten as mechanical-procedure-driven; bias-direction note updated to reflect mechanical thresholds embed conservatism (not orchestrator discretion).
- Claude_Task_Plan.md updated: A2 prompt rewritten to execute §5.3-§5.6 mechanical procedure; Q3 prompt extended with Section 3a benchmark tracking; A1 prompt extended with benchmark fade review and updated Tier 2 status taxonomy.
- Decision_Log.md bumped with this entry.

**Effect on book:**

No immediate effect on strategy book. Pending foundation-change assessments for Strategy A through E (per M2 rev 2 findings) will execute under the rev 4 mechanical framework. The 2.10 prompt injection partial reduction documented in M2 rev 2 is the most likely candidate to trigger constraint-relaxation evaluation; the §5.4 threshold for 2.10 (Opus-tier <2% attack success rate AND <10% bypass at 10 attempts) is not yet cleared per M2 rev 2 evidence, so no relaxation would fire even on strategies with 2.10 constraints. None of the current strategies have explicit 2.10 flowing limitations regardless, so the practical effect on the current book is zero.

**Practical consequence going forward:** when Anthropic ships a new Claude version with documented ECE / calibration improvements, the §5.5 benchmark-inference protocol will pick them up at the next quarterly Q3 task. If improvements clear the §5.5 guardrails and §5.4 thresholds, foundation-change assessment Outcome (c) will fire on strategies whose 2% per-position cap cites 2.13 as primary mitigation, and §5.6 lookup will produce mechanical relaxation forms (cap loosened from 2% to 2.5-3% depending on reduction magnitude). Decision is mechanical; no orchestrator judgment.

**References:**
- AI_Trading_Foundation.md rev 4 with Part 5 §5.1-§5.7.
- Experiment_Parameters.md updated Outcome (c) section with mechanical procedure references.
- Claude_Task_Plan.md updated A2/Q3/A1 task prompts.

**Compaction-survival note:** Future Claude instances should:
- Treat foundation-change assessment as mechanical execution of AI_Trading_Foundation.md §5.1-§5.6 criteria, not as orchestrator judgment.
- Use §5.5 benchmark-inference protocol with all four Goodhart guardrails for any benchmark-derived reduction signal.
- Apply §5.6 relaxation lookup based on constraint type; constraints outside the lookup table generate out-of-table flags rather than ad-hoc resolution.
- Output structured §5.7 audit trails that are replicable across sessions.
- Flag any criteria-gap cases (§5.6 out-of-table, §5.5 partial-evidence, §5.4 boundary-case-magnitudes) for participant resolution rather than exercising discretion.


---

## 2026-04-25 Strategy D pre-mortem ACCEPTED at rev 5 under combined revision-churn + saturation stop

**Trigger:** Cycle 4 adversarial review of Strategy D pre-mortem rev 4. Cycle progression count: 6 → 6 → 3 → 4.

**Inputs:** Strategy.md rev 29 with D pre-mortem rev 4; AI_Trading_Foundation.md rev 4 disadvantage definitions; Experiment_Parameters.md rev 15 stopping rules.

**Sessions:** Single attacker (incognito) + in-conversation orchestrator review per EP rev 14 single-session architecture.

**Cycle 4 attacker findings (4 Tier 1 items, all at rev 4 fix surfaces):**

- **T1-1 (T1-β fix surface — subtype typing rule absent).** Entry criterion 1 requires thesis "filed under one of the two permitted subtypes" but the framework specifies no mechanism for the typing decision. Realistic dual-signal theses (services-revenue × regulatory-milestone) carry both signals; the participant chooses which subtype, and the constraint flowing from 2.19 depends on the choice. This reintroduced the cycle 2 T1-A/B/C defendant-as-judge problem at the typing stage. Screen 4 fail (req 7 self-containment break — universe restriction depends on participant choice).

- **T1-2 (T1-β fix surface — asymmetric invalidation menus exploitable via T1-1).** Subtype A invalidation has 4 categories vs Subtype B's 1 form. With T1-1 unresolved, participant has typing-arbitrage incentive. Screen 3 borderline. Contingent on T1-1 — collapses if T1-1 resolved.

- **T1-3 (T1-β fix surface — Subtype B trend-metric immutability gap under reporting redefinition).** Companies routinely redefine segment reporting; a Subtype B thesis built on "growth rate ≥ 18% YoY for 4 quarters" can become non-evaluable mid-life. Pre-mortem silent on three branches (auto-invalidate / stay-open / re-specify). Screen 4 fail (immutability criterion not self-contained).

- **T1-4 (T1-γ fix surface — alpha-test threshold statistically inert against acknowledged β̂ noise).** β̂ SE ~±0.2 over 24 months × cumulative SPY return ~0.22 → SD on alpha estimate ≈ ±4.5pp. Against 3pp threshold, test cannot reliably distinguish 0pp from -3pp shortfall. The "interpretation as band, not point" framing acknowledged the issue but Section 4 and Section 6 both fired on the point estimate. Screen 3 fail (edge-decay detection materially compromised at primary indicator).

**Theater-check CONVERGENT.** All four items independently verified on the page text. The attacker self-flagged prompt-priming risk and demoted three items I primed (0.7/0.6 asymmetry, monthly cadence, Subtype B over-restriction), confirming non-rubber-stamping. Counter-flag on trajectory break (6→6→3→4 not narrowing) is itself confirmation of locus-recurrence rather than over-finding.

**Rev 5 spot-edit fixes (parallel to Strategy A rev 7 acceptance pattern — cycle 6 found 1 item, rev 7 spot-edited, accepted under combined stop without cycle 7):**

- **(T1-1) Primary-driver / typing rule added.** Constraint 2 / Section 1 Subtype framing extended with mechanism-enforced typing rule based on date arithmetic: dual-signal theses file under Subtype A when catalyst resolves ≤ 12 months from thesis-formation, Subtype B when catalyst resolves > 12 months, both subtypes when catalyst date falls within 12-month forward-verification window AND trend metric independently evaluable. Mechanism-enforced via date comparison, not participant adjudication. T1-2 collapses with this fix because typing-arbitrage option removed.

- **(T1-3) Metric immutability auto-invalidation rule added.** Subtype B invalidation specification extended: if reportable category undergoes structural change such that the metric specified at thesis-formation is no longer reported in original form for ≥ 2 consecutive quarters, thesis auto-invalidates as of date the second non-conforming quarterly report is released. Three structural-change definitions specified inline. Mechanism-enforced via classical-method delegation comparing reported categories at quarter-end to thesis-formation. The 2-quarter requirement avoids transient one-off non-disclosure auto-fires.

- **(T1-4) Alpha-test threshold operationalized with explicit CI gate.** Section 4 alpha-test reframed: flag fires only when (i) alpha point estimate ≤ -3pp AND (ii) 95% upper CI bound on alpha ≤ 0pp. Operationalizes the band-not-point framing — at point estimate -3pp with SE ±4.5pp, the 95% upper CI bound is approximately +6pp, well above 0pp, so flag does NOT fire because band encompasses 0pp meaningfully. The "primary" framing is downgraded — alpha-test becomes one indicator within Section 4 portfolio (alpha-test, SGOV gap, invalidation count, theme concentration, EV-per-5-closes), with joint-signal-across-indicators required for actionable edge-decay determination.

**Acceptance under combined revision-churn + saturation stop (EP rev 14 §188 stop conditions ii + iii):** Cycles 2, 3, 4 each surfaced items at the previous revision's fix surfaces. Cycle 2 attacked rev 1's original-architecture surfaces (defendant-as-judge on Constraints A/B/C). Cycle 3 attacked rev 2's correlation-cap + universe + beta-test fix surfaces. Cycle 4 attacked rev 3's subtype + post-entry + beta-adjusted fix surfaces. The locus-recurrence pattern is unambiguous over 3 consecutive cycles (cycles 2-3-4). The trajectory broke at cycle 4 (4 items not narrower than cycle 3's 3) which is itself confirmation of the saturation pattern. Each rev's fixes produce defects at the next resolution level, matching the structural pattern Strategy A and C accepted at their combined stops.

The architectural residual is mechanism-real: D's narrative-synthesis-on-multi-year-theses architecture has an exposure structure that no further within-strategy revision will eliminate:
- Subtype B's single-metric reduction is operationally restrictive for genuine multi-driver theses (Costco-pattern flywheel) — KL #15 added.
- Beta-estimate-noise sets a finite false-negative rate even with CI-gate operationalization — KL #16 added.
- Narrative-synthesis architecture's exposure to 5 Tier 1 disadvantages magnitude-only mitigated (2.4, 2.13, 2.15, 2.17, 2.19) is parallel-to-but-broader-than Strategy A's rev 7 residual structure — KL #17 added.

These residuals are accepted as architectural properties of D's edge mechanism rather than fixable document defects. Continued underperformance against the Section 4 indicator portfolio over multiple 24-month gates would indicate the architectural residual is binding empirically; in that case, strategy mechanism re-evaluation (rather than pre-mortem revision) would be required, which is out of scope for pre-mortem cycling.

**Cycle 5 not run.** Per Strategy A rev 7 precedent, combined stop fires after rev N+1 spot edits without cycle N+1 attacker run. Cycle 5 attack on rev 5 would predictably produce locus-recurrence findings at the new typing rule (date-arithmetic edge cases, exactly-12-month catalysts), the new immutability rule (2-consecutive-quarter parameter without empirical basis, ambiguity in "structural change" definition), and the new CI gate (regression-residual-normality assumptions on monthly equity returns). Marginal information from cycle 5 is low; combined stop is the precedent-defined response.

**EP rev 15 forcing question.** Do residual cycle-4 Tier 1 items, if accepted unfixed, change deployment risk meaningfully? Three items addressed by rev 5 spot edits (T1-1 typing rule, T1-3 auto-invalidation rule, T1-4 CI gate). T1-2 collapses with T1-1. The resulting rev 5 + KL 15-17 framework: yes, residual exposure is real but it's the architectural residual that no within-strategy revision eliminates, parallel to A's rev 7 residual structure. Combined stop is the precedent response, not deployment-risk stop alone (which would skip the spot edits) and not continued cycling (which would not reduce the residual).

**Theater-check on this acceptance decision:** I considered whether I'm being lenient by applying spot edits when the attacker recommended "ship rev 4 with items added to KL list." The attacker's recommendation was contingent on whether items are architectural residuals or tractable defects. Three of four items (T1-1, T1-3, T1-4) are tractable spot edits filling documented gaps — adding the typing rule, the auto-invalidation rule, and the CI gate doesn't change architecture. The fourth (T1-2) collapses with T1-1. So the right pattern is rev 5 spot edits + combined stop, parallel to A. If I had accepted at rev 4 without spot edits, the documented gaps would remain as documented architectural residuals — but they aren't architectural in the right sense. The rev 5 fixes don't claim to eliminate the structural residual exposure; they fill specific gaps the cycle 4 attacker identified.

**Downstream actions:**

- Strategy.md updated rev 29 → rev 30 with D pre-mortem rev 5 ACCEPTED, three rev 5 spot edits applied to both pre-mortem and strategy mechanism sections, three new Known Limitations (#15-17) documenting architectural residuals.
- Decision_Log.md bumped with this entry.

**Effect on book:**

No immediate effect on D's trade book (no D positions open). Strategy D is now ready for foundation-change assessment per Experiment_Parameters.md rev 15 (foundation change trigger — pending per M2 rev 2 findings since 2026-04-23, and now executable under the rev 4 mechanical-criteria framework). Strategy E pre-mortem cycles remain pending.

**Pending queue updated:**
- ~~Strategy D pre-mortem (cycles 4+)~~ COMPLETE — rev 5 ACCEPTED 2026-04-25.
- Strategy E pre-mortem cycles (not yet started).
- Foundation-change assessments × 5 (A, B, C, D, E) — pending per M2 rev 2 findings; now executable under rev 4 mechanical framework.
- M2 follow-ups: empirical dispersion compression check (Strategy C); fundamental signal process tightening (Strategy E).

**References:**
- Strategy.md rev 30 (D pre-mortem rev 5 ACCEPTED).
- AI_Trading_Foundation.md rev 4 (disadvantage taxonomy referenced).
- Experiment_Parameters.md rev 15 (stopping rule applied).
- Cycle 4 attacker output (preserved in conversation; theater-check CONVERGENT).

**Compaction-survival note:** Strategy D pre-mortem ACCEPTED at rev 5 under combined revision-churn + saturation stop on 2026-04-25. Architectural residuals documented as KL #15-17. Future Claude instances should treat D's narrative-synthesis-on-multi-year-theses exposure structure as the accepted architectural property — further pre-mortem cycling on D is not warranted unless empirical evidence (Section 4 indicator portfolio firing across multiple 24-month gates) indicates the residual is binding empirically, in which case strategy mechanism re-evaluation (not pre-mortem revision) is the appropriate response.


---

## 2026-04-25 Foundation-Change Assessment Cycle (5 strategies) — first end-to-end execution of rev 4 mechanical-criteria framework

**Trigger:** AI_Trading_Foundation.md rev 2 (M2 cycle, 2026-04-23) introduced foundation changes warranting per-strategy foundation-change assessment. Assessments deferred until rev 4 mechanical-criteria framework was in place; now executable under §5.1-§5.7. This cycle is also the first end-to-end validation of the rev 4 framework on real data.

**Inputs:** AI_Trading_Foundation.md rev 4; M2 rev 2 update (2.3 split into 2.25; 2.8 reinforced qualitatively; 2.10 partial reduction Opus-tier; 2.13 mechanism identified; 2.24 architectural confirmation; 2.25 NEW; 2.26 NEW); Strategy.md rev 30 with all 5 strategy mechanism sections + 4 ACCEPTED pre-mortems (A rev 7, B rev 7, C rev 9, D rev 5) + 1 draft pre-mortem (E rev 1).

**Sessions:** Single orchestrating session executing §5.3 mechanical procedure. No orchestrator discretion exercised — criteria applied deterministically.

**Procedure executed per strategy:**
1. Parse foundation citation graph from pre-mortem Section 5 ("Specific disadvantages posing greatest risk") and binding-constraint section.
2. For each cited item, check current AI_Trading_Foundation.md rev 4 status against status-as-of-strategy-foundation-revision.
3. Classify each status change per §5.4 thresholds (NONE / PARTIAL / MATERIAL).
4. Apply §5.1 Continue test, §5.2 Terminate test, §5.3 Constraint-relaxation review trigger.
5. For any constraint-relaxation candidates, apply §5.5 benchmark-inference verification + §5.6 mechanical relaxation lookup.
6. Output structured §5.7 audit trail.

**Aggregate outcome: 5/5 Continue. 0/5 Terminate. 0/5 Constraint-relaxation review.**

**Per-strategy outcomes:**

| Strategy | Citations | Outcome | Notes |
|---|---|---|---|
| A | 2.4, 2.8, 2.13, 2.14, 2.19, 2.20 | Continue | No MATERIAL changes affecting cited items |
| B | 2.4, 2.8, 2.13, 2.14, 2.15, 2.17, 2.18, 2.19, 2.20 | Continue | No MATERIAL changes |
| C | 2.1, 2.4, 2.6, 2.7, 2.8, 2.11, 2.12, 2.13, 2.14, 2.15, 2.18, 2.19 | Continue | HYBRID FOMC-only state preserved |
| D | 2.4, 2.6, 2.7, 2.8, 2.13, 2.14, 2.15, 2.17, 2.19, 2.20, 2.23 | Continue | Just-accepted rev 5 unchanged |
| E | 2.4, 2.6, 2.8, 2.15, 2.24 | Continue (provisional) | Re-assess after pre-mortem cycles complete |

**Why 2.10 PARTIAL reduction signal produced zero relaxations:** The benchmark-inference signal (Anthropic Opus 4.5 ~1% attack rate vs IAS Report 17.8% baseline) classified per §5.4 as PARTIAL reduction (~94% reduction clears PARTIAL threshold; 10-attempt bypass not confirmed for Claude Opus specifically, so MATERIAL not cleared). §5.5 Goodhart guardrails: 2 sources (Anthropic + IAS Report) of 3 required; PARTIAL classification is provisional pending replication. Even if guardrails cleared, no strategy in A-E cites 2.10 in its foundation citation graph — prompt injection isn't a primary or secondary mitigation target for any current strategy mechanism. §5.6 mechanical relaxation lookup has no constraint to evaluate. Signal logged as foundation evidence; no operational change.

**Why qualitative 2.8 reinforcement produced no termination:** §5.4 MATERIAL strengthening threshold is "magnitude estimates increased by ≥50% in supporting research." M2 rev 2's 2.8 update is contextual reinforcement (Coordination Primacy Hypothesis literature, capex concentration commentary, March 2026 pod-shop drawdown as watch item) rather than quantified magnitude increase. Existing 2.8 compensations (sector caps, theme limits, correlation-bucket caps for D) remain in force.

**Why new items 2.25 and 2.26 produced no termination:** 2.25 (agentic epistemic hallucination) is bounded by experiment-level workflow architecture — human-conducted execution in IBKR plus externally-maintained ledger plus per-session portfolio state — none of which is strategy-level. No strategy needs strategy-level 2.25 compensation; mitigation pre-exists at workflow level. 2.26 (RL post-training overconfidence) operationally subsumed by existing 2.13 compensation patterns (ordinal conviction tiers, classical-method delegation of probability assignment) which all strategies already follow. No compensation pathway is missing.

**Framework validation:** This is the first end-to-end execution of §5.1-§5.6 on real foundation-change data. The cycle was deterministic, replicable, and produced structured §5.7 audit trails for all 5 strategies in one batched session. No orchestrator discretion was exercised — every classification was determined by quantitative threshold or §5.5 Goodhart guardrail evaluation. Out-of-table flags were minimal (only E's incomplete-pre-mortem flag). The framework handled:
- Magnitude classification on existing items (NONE / PARTIAL / MATERIAL).
- Compensation pathway evaluation for new items (workflow-level for 2.25; existing-mechanism for 2.26).
- Citation graph parsing from pre-mortems (5 strategies, 13 unique 2.X items cited across all).
- Goodhart guardrail evaluation on benchmark inference (2.10 provisional PARTIAL classification).
- Mechanical lookup completion check (no constraints cite 2.10 → no §5.6 invocation needed).

The rev 4 mechanical framework is operationally validated. Future foundation-change assessments will follow this pattern.

**Theater-check:** n/a (mechanical execution, no judgment exercised). The §5.3-§5.6 procedure is deterministic given inputs. Same inputs → same outputs (within 2.24 cross-session variance, which manifests primarily in framing rather than verdict).

**Effect on book:**

No immediate effect on any strategy's trading state. All 5 strategies continue in their current operational states:
- A: ACCEPTED, no positions, awaiting first trade trigger
- B: ACCEPTED, no positions, awaiting first trade trigger
- C: ACCEPTED, HYBRID ACTIVATE FOMC-only, no positions
- D: ACCEPTED rev 5 (this conversation), no positions
- E: DO-NOT-ACTIVATE, no positions, pre-mortem cycles pending

**Pending queue updated:**
- ~~Foundation-change assessments × 5 (A, B, C, D, E)~~ COMPLETE — all 5 Continue under rev 4 mechanical framework, this entry.
- Strategy E pre-mortem cycles (not yet started) — NEXT.
- E foundation-change re-assessment after pre-mortem cycles complete (citation graph will stabilize).
- 2.10 evidence accumulation watch (next Q3 quarterly task).
- M2 follow-ups: empirical dispersion compression check (Strategy C); fundamental signal process tightening (Strategy E).

**References:**
- Foundation_Change_Assessment_2026-04-25.md (full §5.7 audit-trail output, single document with all 5 per-strategy assessments).
- AI_Trading_Foundation.md rev 4 §5.1-§5.6 (procedure source).
- Strategy.md rev 30 (citation graphs).

**Compaction-survival note:** All 5 strategies passed foundation-change assessment under rev 4 mechanical framework on 2026-04-25. No constraints relaxed, no terminations triggered. The 2.10 PARTIAL reduction signal is provisional pending replication; even if confirmed MATERIAL, no current strategy cites 2.10 so practical effect on book is zero. The rev 4 framework's first end-to-end execution succeeded — future Claude instances should treat this assessment cycle as the working pattern for subsequent foundation-change evaluations.


---

## 2026-04-25 Strategy E pre-mortem cycle 1 — TIER 1 DEFECT, structural rebuild applied as rev 2

**Trigger:** First adversarial review cycle on Strategy E pre-mortem (rev 1 was initial draft, no prior cycles).

**Inputs:** Strategy.md rev 30 with E pre-mortem rev 1 (~50 lines, narrow Section 5 with 5 disadvantages, missing req 5 and req 7 architecture); AI_Trading_Foundation.md rev 4; Strategy A/B/C/D pre-mortem precedents.

**Sessions:** Single attacker (incognito) + in-conversation orchestrator review per EP rev 14 single-session architecture.

**Cycle 1 attacker findings (13 Tier 1 items):**

- **T1.1 — Self-containment violation, literal cross-reference.** Pre-mortem opens with "Already addressed in the strategy section above" — exactly the non-compliant pattern.
- **T1.2 — Strategy mechanism not enumerated inline.** Reqs 1-4 cannot be evaluated for "specificity" without mechanism in front of reader inside pre-mortem.
- **T1.3 — Req 5 (declared expected trade frequency) absent** from pre-mortem text (mechanism declares 6-12 pairs/year; pre-mortem doesn't state).
- **T1.4 — Req 7 (binding-constraint confrontation with flowing limitations) absent.** No cross-walk, no enumeration, no flowing limitations, no Known Limitations list.
- **T1.5 — Missing mechanism-relevant disadvantages** in Section 5 (5 of ~15 enumerated): missing 2.13/2.26 (financing gate input miscalibration), 2.18 (forced 6-month exit), 2.19 (look-ahead on textbook pair episodes), 2.7 (compensation claim unexamined), 2.20 (compensation claim unexamined), plus secondary 2.11/2.12, 2.23, 2.17.
- **T1.6 — Compensation claims for 2.7 and 2.20 unexamined.** Strategy mechanism explicitly *claims* market-neutrality compensates 2.7 and 2.20; pre-mortem doesn't engage. Sharpest sub-finding: router rule excludes E during regimes where 2.7 would actually bite, so compensation claim coexists with router rule that disallows the strategy precisely in those regimes — internal contradiction.
- **T1.7 — Pair-correlation as load-bearing assumption unconfronted.** Entry gate at 0.5, exit at 0.3, drift band, non-stationarity in stress vs dispersion regimes.
- **T1.8 — Adversarial counter-argument as defendant-as-judge.** Same Claude session producing thesis runs counter-argument; same weight-level biases per 2.4.
- **T1.9 — 2.24 implication not extracted.** Section 5 identifies the problem and stops; doesn't draw the conclusion that adversarial-review architecture is compromised by weight-level convergence.
- **T1.10 — Short-financing-cost edge-decay indicator absent.** Section 4 has no portfolio-level financing-drag indicator distinct from operational borrow-rate gate.
- **T1.11 — Edge-decay thresholds without baseline derivation** (10 pair closes, 1:1 ratio, 20-positions-floor).
- **T1.12 — Operationally-vacant indicator** "near zero correlation between adversarial-review outcome quality and realized P&L" — adversarial-review outcome quality undefined and unmeasured anywhere.
- **T1.13 — 6-month forced exit × 2.18 trade-off undocumented.** Forced exit overrides P&L; not confronted as 2.18 territory.

**EP rev 15 four-screen test:** failed Screens 2, 3, and 4 across multiple items.
- Screen 2 (top-five req-4 omission): 2.13, 2.7, 2.20 are clearly top-relevant for E's mechanism — FAIL.
- Screen 3 (failure-mode detection gap): T1.7, T1.10, T1.12 — FAIL.
- Screen 4 (req self-containment break): T1.1, T1.2, T1.3, T1.4 — FAIL.

Definitive **TIER 1 DEFECT — STRUCTURAL REBUILD REQUIRED.** Continue cycling.

**Theater-check CONVERGENT.** All 13 items have on-page evidence in rev 1. The attacker self-flagged volume (13 items vs A/B/C/D cycle 1 counts of 6/6/8/6) and noted possible consolidation (T1.6+T1.7 share architectural locus; T1.10+T1.11 share edge-decay locus). I evaluated each independently — items keep distinct rev 2 responses, count isn't theater. Self-flag was honest.

**Rev 2 structural rebuild architecture (modeled on Strategy C accepted rev 9):**

Modeled on C because of closest mechanism parallels: both are public-information-driven, both have 2.6-binding constraint requiring sell-side handling clause, both are adversarial-review-dependent for thesis quality discipline. C's accepted-rev-9 architecture has four binding constraints with flowing limitations + cross-constraint preamble; E's rev 2 follows the same pattern with E-specific constraints.

Rev 2 fixes:

1. **Self-containment (T1.1, T1.2, T1.3).** Section 1 enumerates inline: thesis, eligibility rule including ETF-pair substitution, deployment posture, entry criteria 1-6, exit rules, declared expected frequency (6-12 pairs/year = 12-24 trades), router activation rule.

2. **Req 7 binding-constraint architecture (T1.4).** Four constraints with explicit cross-walk and flowing limitations:
   - **Constraint 1 = 2.6 (no private info).** Flowing limitation: entry criterion 6 public-info compliance check + sell-side handling clause per C rev 19 precedent (theses where sell-side's private-information-derived conclusions are load-bearing are inadmissible).
   - **Constraint 2 = 2.4 (narrative over-fit on pair narratives).** Flowing limitation: entry criterion 2 counter-argument (~30% reduction graded) + entry criterion 3 quantitative-divergence-anchor.
   - **Constraint 3 = 2.24 (cross-session inconsistency / adversarial-review compromise).** *Load-bearing for E* because adversarial review is the primary thesis-quality discipline. Flowing limitation: rev 2 quantitative-divergence-anchor (80th-percentile pair-spread test) as external-to-Claude-reasoning verification of divergence existence.
   - **Constraint 4 = 2.13 + 2.26 (miscalibration on expected-return input to financing gate).** Flowing limitation: rev 2 dual-anchor financing gate — financing must clear BOTH 15% of Claude's expected return AND 15% of trailing-252-day historical median pair-mean-reversion magnitude.

3. **2.7/2.20 compensation engagement (T1.6).** Section 5 entries for 2.7 and 2.20 explicitly engage the strategy's claimed compensation, document the router-activated-band scope acknowledgment, and surface the within-pair beta drift residual. Compensation is honest within scope but doesn't claim full neutralization.

4. **Pair-correlation architecture confronted (T1.7).** Entry criterion 3 quantitative-divergence-anchor + KL #10 drift-band residual + KL #11 non-stationarity residual.

5. **Section 5 expanded from 5 to 13 disadvantages (T1.5).** Added 2.7, 2.13, 2.17, 2.18, 2.19, 2.20, 2.23, 2.26 with mechanism-specific consequences.

6. **2.24 operational implication extracted (T1.9).** Constraint 3 explicitly identifies E's adversarial-review architecture as compromised by 2.24 weight-level convergence; quantitative-divergence-anchor cuts the dependence at divergence-existence layer (narrative-validity layer remains exposed as residual).

7. **Counter-argument graded discriminator framing (T1.8).** Entry criterion 2 explicitly acknowledges ~30% reduction operating on same weights / same context; parallel to A/B/C/D rev N+ Constraint 2 framing.

8. **Edge-decay indicators rebuilt (T1.10, T1.11, T1.12).** Section 4 now has 5 indicators: pair convergence rate < 50% (derived from 50-70% literature baseline); cumulative excess vs SGOV at 10 closes; convergence-vs-timeline ratio < 1:1 (derived from same baseline); portfolio-level financing drag > 25% (rev 2 added); mean entry-time borrow cost trend > 50% rise in 12 months (rev 2 added); thesis-quality-vs-realized-P&L rank correlation (replaces operationally-vacant rev 1 indicator). All thresholds derived or explicitly calibration-deferred to 15-pair gate.

9. **6-month exit × 2.18 trade-off documented (T1.13).** KL #5 explicitly accepts the residual as stale-thesis-defense outweighing single-thesis cost.

**Cycle progression count after rev 2:** 13 (cycle 1 only). Cycle 2 will likely produce material findings — req-7 architecture itself typically requires its own cycle of refinement per A/B/C/D experience. Best estimate per A/B precedent: cycle 2 will surface 5-8 Tier 1 items at rev 2 fix surfaces, narrowing in cycles 3+.

**EP rev 15 forcing question.** Rev 2 changes deployment risk meaningfully: T1.1-T1.4 closed (self-containment + req 7 + req 5); T1.5 closed (Section 5 expanded); T1.6 closed (compensation claims engaged); T1.7 closed at entry-time (quantitative anchor) with residuals KL'd; T1.8/T1.9 closed (graded framing + Constraint 3); T1.10-T1.12 closed (edge-decay rebuild); T1.13 closed (KL #5).

**Theater-check on this orchestrator review:** I considered whether 13 cycle-1 items is over-finding given A/B/C/D cycle 1 counts of 6/6/8/6. The attacker self-flagged this. My evaluation: rev 1 was structurally thinner than A/B/C/D rev 1 versions (the rev 1 E pre-mortem genuinely is minimal — ~50 lines, no req 7 architecture, narrow Section 5). The 13 count reflects the rev 1 starting state, not over-finding. Each item passes independent verification. CONVERGENT.

**Effect on book:**

No immediate effect. Strategy E remains in DO-NOT-ACTIVATE state (per divergence review 2026-04-25). E's pre-mortem cycling continues in the background; trade activation remains gated by both pre-mortem completion AND fundamental review reversal of DO-NOT-ACTIVATE divergence verdict.

**Pending queue updated:**
- ~~Strategy E pre-mortem cycle 1~~ COMPLETE — TIER 1 DEFECT, rev 2 structural rebuild applied.
- Strategy E pre-mortem cycle 2 — NEXT (attacker prompt drafted in this session for next-turn execution).
- E foundation-change re-assessment — after pre-mortem cycles stabilize (citation graph expanded from 5 to 13 items in rev 2; will require re-execution post-acceptance).
- 2.10 evidence accumulation watch — next Q3 quarterly task (2026-07-01).
- M2 follow-ups: empirical dispersion compression check (Strategy C); fundamental signal process tightening (Strategy E).

**References:**
- Strategy.md rev 31 with E pre-mortem rev 2.
- AI_Trading_Foundation.md rev 4 (disadvantage taxonomy).
- Cycle 1 attacker output (preserved in conversation; theater-check CONVERGENT).

**Compaction-survival note:** Strategy E pre-mortem cycle 1 produced 13 Tier 1 items reflecting rev 1's minimal structural state. Rev 2 is a full structural rebuild modeled on Strategy C accepted rev 9 architecture. Future Claude instances should expect cycle 2 to produce material findings at rev 2 fix surfaces (req-7 architecture refinement); cycle progression likely 13 → 5-8 → 2-3 → acceptance per A/B/C/D experience.


---

## 2026-04-25 Strategy E pre-mortem cycle 2 — TIER 1 DEFECT, narrow-scope rev 3 spot-edits applied

**Trigger:** Cycle 2 adversarial review of Strategy E pre-mortem rev 2.

**Inputs:** Strategy.md rev 31 with E pre-mortem rev 2; cycle 2 attacker output (4 Tier 1 items, all at rev 2 fix surfaces).

**Sessions:** Single attacker (incognito) + in-conversation orchestrator review per EP rev 14 single-session architecture.

**Cycle 2 attacker findings (4 Tier 1 items, all at rev 2 fix surfaces):**

- **T2.A (Constraint 4 fix surface — Anchor 2 dual-anchor masquerade).** Anchor 2's "trailing-252-day historical median pair-mean-reversion magnitude for similar in-sector pairs" requires Claude to identify the reference set. Same Claude session that produces Anchor 1 (expected return) selects Anchor 2's reference set. The two anchors are not statistically independent — they are correlated estimates from the same biased reasoning. The dual-anchor framing implies independence; the actual mechanism doesn't deliver it. Same defect class as cycle 1 T1.8 (defendant-as-judge on counter-argument) and Strategy D cycle 2 T1-A/B/C. Screen 1 (loss-bounding contribution not delivered) and Screen 4 (constraint claims property it lacks) — FAIL.

- **T2.B (Constraint 2/3 fix surface — 80th-percentile threshold too loose).** Pair-trading literature uses ±2σ ≈ 95th percentile (Gatev/Goetzmann/Rouwenhorst 2006; Avellaneda/Lee 2010). 80th percentile fires on ~20% of trading days under random-walk null — not a meaningful 2.4 detection filter. Sub-defects: (i) threshold not derived; (ii) spread definition (price ratio vs log-spread) is Claude judgment per pair; (iii) reference window length asserted. Screen 3 (failure-mode detection on 2.4 weakened by loose anchor) — FAIL.

- **T2.C (Constraint 3 fix surface — flowing limitation operates at wrong layer).** Rev 2 flowing limitation operates at divergence-existence layer; load-bearing 2.24 exposure is at narrative-validity layer. Quantitative-divergence-anchor verifies *some* divergence exists; E's edge claim is *narrative* (why divergence exists, why it will reconverge) which is what 2.24 weight-level convergence corrupts. Constraint declares load-bearing status but limitation doesn't flow to load-bearing aspect. Screen 4 (req 7 self-containment break) — FAIL.

- **T2.D (Section 4/6 fix surface — operationally vacant indicator in current infrastructure).** Entry-percentile-vs-realized-P&L rank correlation requires logging fields not present in Portfolio_Ledger.md or Decision_Log.md schema. Cycle 1 T1.12 explicitly required operational implementability; rev 2 replaced rev 1's vacant indicator with one that's in-principle implementable but not implementable in current infrastructure. Same defect class. Screen 3 (failure-mode detection — Section 6 indicator uncomputable at first monthly review) — FAIL.

**EP rev 15 four-screen test:** failed Screens 1, 3, and 4 across the four items.

**Theater-check CONVERGENT.** All four items have on-page evidence and clean specification-grade fixes. The attacker explicitly demoted 5 items I'd identified in cycle 2 attack vectors (2.7 compensation engagement, 2.20 within-pair-spread, cap×duration caveats, KL count, sell-side clause) on sound reasoning — those are accepted residuals not new T1s. The self-flag on the "partial mechanism in residual but architectural framing claims more" pattern is honest and well-scoped.

**Cycle progression: 13 → 4.** Largest absolute narrowing in any strategy's cycle 1 → 2 transition (A: 6→6, B: 6→6, C: 8→8, D: 6→6). Reflects rev 2 resolving most cycle-1 items architecturally, with residual defects concentrated at rev 2's new mechanism components (Anchor 2, divergence-anchor threshold, Constraint 3 framing, indicator implementation).

**Combined revision-churn + saturation stop NOT appropriate at cycle 2.** Locus-recurrence is present (4/4 at fix surfaces) but cycle count exhaustion is absent — A combined stop at rev 7, C at rev 9, D at rev 5 (with unique 4-cycle pattern). Cycle 2 with genuinely fixable items is normal post-rebuild position. Premature stop would deploy with avoidable defects in load-bearing layers. Continue to cycle 3.

**Rev 3 spot-edit fixes (parallel to A/B/C cycle 3+ specification refinement pattern):**

- **(T2.A) Anchor 2 deterministic reference-set rule.** Constraint 4 / entry criterion 5 reformulated. Reference set = all pairs in same 6-digit GICS industry group with trailing-252-day correlation ≥ 0.5, both meeting market-cap and ADV minimums, ≥ 5 years joint trading history. Computed by classical-method delegation; no Claude pair-shortlisting step. Minimum 10 qualifying pairs required for Anchor 2 to apply; otherwise pair defers. Restores Anchor 2 statistical independence from Anchor 1.

- **(T2.B) Quantitative-divergence-anchor tightened to 95th percentile.** Entry criterion 3 reformulated. Threshold derived from pair-trading literature standard (z ≈ 2σ, Gatev/Goetzmann/Rouwenhorst 2006 distance method; Avellaneda/Lee 2010 statistical arbitrage). Spread definition mechanism-enforced via classical-method delegation: price-ratio for similar share-price scales (max/min ratio ≤ 3), log-spread otherwise. Choice rule-bound, not Claude-judgment-based.

- **(T2.C) Constraint 3 dual-component flowing limitation.** Entry criterion 1 tightened: "specific public events that would cause reconvergence" must be reduced to quantitative thresholds (e.g., "Q3 earnings revenue beat ≥ 5%" not "Q3 earnings beat"). Constraint 3 flowing limitation expanded to dual-component: (a) divergence-existence layer via entry criterion 3 quantitative-divergence-anchor; (b) narrative-validity layer via entry criterion 1 quantitative-reconvergence-threshold requirement. Component (b) reduces narrative's predictive content to falsifiable quantitative claim, session-stable and externally-verifiable post-hoc.

- **(T2.D) Logging specification added to Section 6.** Per-pair logging requirements specified inline. Decision_Log.md per-pair entry fields: pair_id, spread_definition, reference_window, percentile_at_entry, anchor_2_reference_set_size, reconvergence_thresholds. Portfolio_Ledger.md per-pair close fields: pair_id, realized_pnl ($ and %), holding_days, exit_reason. Indicator computes Spearman rank correlation across trailing 10 closed pairs.

**KL #14, #15 added** for two new acknowledged residuals: (14) spread-definition rule's 3x share-price-ratio threshold is a parameter with 15-pair-gate calibration trigger; (15) Anchor 2 trailing-252-day median is non-stationary, regime-relative rather than regime-absolute.

**EP rev 15 forcing question.** Rev 3 changes deployment risk meaningfully: T2.A (loss-bounding contribution from dual-anchor now actually delivered via deterministic reference set), T2.B (2.4 detection no longer 20%-firing-permissive — 95th percentile fires ~5% of trading days under null, providing meaningful filter), T2.C (req 7 self-containment restored — flowing limitation now reaches load-bearing layer via component (b)), T2.D (Section 6 indicator now operationally implementable with explicit logging schema additions).

**Theater-check on this orchestrator review:** I considered whether 4 cycle-2 items is over-finding given cycle progression should narrow toward acceptance. Counter-argument: 13→4 IS narrowing (largest absolute narrowing in 1→2 transition). Counter-counter-argument: 4 is still substantial; could be over-finding if I'm over-promoting Tier 2 items. Self-check: each of the 4 items independently fails an EP rev 15 screen and has a clean fix. The fixes are specification-grade, not architectural redesign. CONVERGENT.

**Effect on book:**

No immediate effect. Strategy E remains in DO-NOT-ACTIVATE state (per divergence review 2026-04-25). E's pre-mortem cycling continues; trade activation remains gated by both pre-mortem completion AND fundamental review reversal of DO-NOT-ACTIVATE divergence verdict.

**Pending queue updated:**
- ~~Strategy E pre-mortem cycle 2~~ COMPLETE — TIER 1 DEFECT, rev 3 spot-edit fixes applied.
- Strategy E pre-mortem cycle 3 — NEXT (attacker prompt to be drafted next turn). Best estimate: 2-4 Tier 1 items at rev 3 fix surfaces (deterministic reference-set rule's 5-year-history and 10-pair-minimum may have boundary issues; 95th percentile interaction with declared 6-12 pair frequency; logging schema may surface infrastructure-coordination residuals). Cycle 4 likely acceptance candidate.
- E foundation-change re-assessment — after pre-mortem cycles stabilize.
- 2.10 evidence accumulation watch — next Q3 quarterly task (2026-07-01).
- M2 follow-ups: empirical dispersion compression check (Strategy C); fundamental signal process tightening (Strategy E).

**References:**
- Strategy.md rev 32 with E pre-mortem rev 3.
- AI_Trading_Foundation.md rev 4 (disadvantage taxonomy).
- Cycle 2 attacker output (preserved in conversation; theater-check CONVERGENT).

**Compaction-survival note:** Strategy E pre-mortem cycle 2 produced 4 Tier 1 items at rev 2 fix surfaces, all specification-grade with clean fixes. Rev 3 applies four spot edits without architectural redesign. Cycle progression now 13 → 4; per A/B/C precedent, cycle 3 should produce 2-4 items at rev 3 fix surfaces with cycle 4 as likely acceptance candidate (combined-stop available if cycle 3 findings concentrate at rev 3 fix surfaces).


---

## 2026-04-25 Strategy E pre-mortem cycle 3 — TIER 1 DEFECT (Path A selected), narrow-scope rev 4 spot-edits applied

**Trigger:** Cycle 3 adversarial review of Strategy E pre-mortem rev 3.

**Inputs:** Strategy.md rev 32 with E pre-mortem rev 3; cycle 3 attacker output (1 borderline T1 + 6 T2/T3 items, all at rev 3 fix surfaces).

**Sessions:** Single attacker (incognito) + in-conversation orchestrator review.

**Cycle 3 attacker findings:**

- **T1.A (borderline T1, rev 3 T2.B fix surface).** Pair-prioritization layer between criterion 3 trigger and thesis-formation is unspecified Claude judgment. The 95th percentile threshold + 5%-of-trading-days × N candidate pairs produces multiple co-triggered pairs per session; Claude's evaluation cadence is lower than trigger frequency, so prioritization is a real upstream gate. Pre-mortem's mitigation architecture (counter-argument, quant anchor, dual-component Constraint 3) operates downstream of this layer. 2.4 (narrative attractiveness selection) and 2.24 (session-variable weight-bias-correlated prioritization) operate at this layer unmitigated. Strict Screen 3 reading: detected → no gap. Substantive reading: load-bearing layer unaddressed → gap. Attacker self-flagged as borderline T1/T2.

- **T2.E (T2.A fix surface).** Anchor 2 deterministic rule deferral rate vs declared 6-12 pair frequency uncalibrated. The ≥10-qualifying-pairs minimum + 5-year joint history may make Anchor 2 categorically inapplicable in some industry groups.

- **T2.F (T2.C fix surface).** Constraint 3 component (b) is falsifiability requirement, not a 2.24 mitigation at threshold-choice layer. The pre-mortem's residual (ii) honestly notes this; framing oversells "dual-component" as if both hit the same target.

- **T2.G (T2.B fix surface).** 3x share-price-ratio mechanism-enforcement is ceremonial at the boundary (where it bites, the rule's outcome-influence is weak; where outcome-influence is strong, the choice was already obvious without the rule).

- **T2.H (T2.D fix surface).** Logging spec adds E-specific fields to shared experiment-level files without cross-strategy compatibility check.

- **T2.I.** 2.18 × 2.13/2.26 interaction not surfaced as compounding failure mode. Section 2 lists items separately.

- **T2.J.** Constraint 3 component (b) excludes qualitative-reconvergence theses; Section 1 universe declaration doesn't cross-walk.

**Theater-check CONVERGENT.** All findings have on-page evidence at rev 3 fix surfaces. Attacker self-flag on T1.A borderline status is honest (strict Screen 3 = pass; substantive Screen 3 = fail). Attacker explicitly considered whether deployment-risk stop is the honest verdict.

**Path selection: Path A (continue with rev 4 spot edits) over Path B (deployment-risk stop).** Reasoning:

- Pattern across A/C/D late cycles: borderline T1 items get spot-edited rather than accepted as T2. The bias has been toward addressing structural concerns rather than relying on strict screen reading.
- T1.A is structural hole at load-bearing input-distribution layer; biased input distributions are not fully recoverable downstream. The fix is low-cost (one-paragraph specification).
- Trajectory hasn't broken: cycle progression 13→4→1-T1+6-T2/T3 is still narrowing on T1 count. Saturation pattern requires not-narrowing.
- Combined revision-churn + saturation stop NOT appropriate at cycle 3 — locus-recurrence present (4/4 findings at rev 3 fix surfaces) but cycle count exhaustion absent (E at cycle 3 vs A combined stop at cycle 6, C at cycle 8).

**Rev 4 spot-edit fixes applied:**

1. **(T1.A) Pair-prioritization rule.** Added after entry criterion 6: when multiple candidates simultaneously meet criterion 3 threshold, evaluate in deterministic rank order by spread-percentile-magnitude (descending; ties broken by first-trigger-date or alphabetical pair_id). Ranking computed by classical-method delegation. No skip-and-prioritize permitted. Eliminates Claude-judgment selection step upstream of all gates.

2. **(T2.E) KL #15 review trigger extended** to include deferral-rate audit at 15-pair gate (audit fraction of theses deferred due to Anchor 2 reference-set < 10 pairs; calibration-refine minimum-pair threshold or 5-year-history requirement if material fraction).

3. **(T2.F) Constraint 3 component (b) reframed** as "post-hoc verification surface" rather than 2.24 mitigation. Component (a) is the genuine 2.24 mitigation at divergence-existence layer; component (b) provides falsifiability/post-hoc-verifiability but does NOT address weight-level bias on threshold choice. KL #16 added documenting this as accepted architectural residual.

4. **(T2.J) Section 1 cross-reference added** via the rev 4 pair-prioritization rule's note: operating universe restricted to pairs passing Constraint 3 component (b) — theses without quantitative reconvergence thresholds (genuinely qualitative reconvergence mechanisms) are excluded.

5. **(T2.I) KL #17 added** documenting 2.18 × 2.13/2.26 interaction as compounding failure mode. When overconfidence on convergence speed inflates Anchor 1, financing gate clears more permissively; when thesis requires longer than expected, 6-month forced exit fires more frequently. Loss bounded by per-pair cap. Review trigger: at 15-pair gate, audit fraction of pairs exiting via 6-month time-based exit.

T2.G (3x parameter ceremonial): logged at KL #14 with existing 15-pair audit trigger; no rev 4 mechanism change. T2.H (cross-strategy schema asymmetry): operational/cross-strategy coordination concern out of pre-mortem scope; flagged in cycle-3 changelog as note for infrastructure coordination.

**EP rev 15 forcing question.** Rev 4 changes deployment risk meaningfully: T1.A (pair-prioritization eliminates Claude-judgment selection upstream of all gates); T2.E (audit closes calibration gap on declared frequency vs realizable rate); T2.F (honest framing — Constraint 3 residual now reflects what mitigations actually deliver); T2.J (universe declaration coherent with operating universe).

**Theater-check on this orchestrator review:** I considered Path B (deployment-risk stop) seriously because all four screens pass under strict reading. Counter-argument: the pattern across A/C/D has been to address borderline items via spot edits, not to rely on strict screen reading; T1.A is a structural hole worth one-paragraph fix; saving one cycle isn't worth leaving the hole. Counter-counter-argument: the strict screen reading is the EP rev 15 standard, and consistently applying it would prevent cycle-creep. Net: I selected Path A because the spot edit is genuinely low-cost and addresses a real architectural concern. If a future review of this decision concludes it was unnecessary cycle-creep, that's a fair critique; I acknowledge the call was contestable.

**Effect on book:**

No immediate effect. Strategy E remains in DO-NOT-ACTIVATE state.

**Pending queue updated:**
- ~~Strategy E pre-mortem cycle 3~~ COMPLETE — TIER 1 DEFECT (Path A), rev 4 spot-edit fixes applied.
- Strategy E pre-mortem cycle 4 — NEXT (cycle 4 attacker prompt to be drafted same session). Best estimate: 0-2 Tier 1 items at rev 4 fix surfaces (pair-prioritization rule may have boundary issues at rank ties / no-trigger sessions; KL framings may have residual exposure). Combined-stop available if cycle 4 confirms locus-recurrence with cycle count exhaustion (E at 4 cycles parallel to D's pattern).
- E foundation-change re-assessment — after pre-mortem cycles stabilize.
- 2.10 evidence accumulation watch — Q3 quarterly task (2026-07-01).
- M2 follow-ups: empirical dispersion compression check (Strategy C); fundamental signal process tightening (Strategy E).

**References:**
- Strategy.md rev 33 with E pre-mortem rev 4.
- Cycle 3 attacker output (preserved in conversation; theater-check CONVERGENT; attacker recommended Path A).

**Compaction-survival note:** Strategy E pre-mortem cycle 3 produced 1 borderline T1 + 6 T2/T3 items at rev 3 fix surfaces. Path A selected over Path B (deployment-risk stop) per pattern across A/C/D late cycles. Rev 4 spot edits applied for T1.A (pair-prioritization rule), T2.E (deferral-rate audit), T2.F (Constraint 3 component (b) reframing), T2.I (2.18 × 2.13/2.26 interaction), T2.J (Section 1 cross-reference). T2.G, T2.H accepted as documentation residuals. Cycle 4 likely acceptance candidate; cycle 4 attacker prompt drafted in same session for next-turn execution.


---

## 2026-04-25 Strategy E pre-mortem cycle 4 — TIER 1 DEFECT, rev 5 spot-edit applied, ACCEPTED under combined revision-churn + saturation stop

**Trigger:** Cycle 4 adversarial review of Strategy E pre-mortem rev 4.

**Inputs:** Strategy.md rev 33 with E pre-mortem rev 4; cycle 4 attacker output (1 borderline T1 + 6 T2/T3 items, all at rev 4 fix surfaces).

**Sessions:** Single attacker (incognito) + in-conversation orchestrator review per EP rev 14 single-session architecture.

**Cycle 4 attacker findings:**

- **T1.K (borderline T1, rev 4 T2.F fix surface).** Constraint 3 declares 2.24 load-bearing but threshold-choice layer has no flowing limitation. Rev 4's reframing of component (b) from "2.24 mitigation" to "post-hoc verification surface" was honest, and KL #16 documented the residual cleanly — but the resulting architecture has 2.24 declared "load-bearing for E" with no flowing limitation reaching the load-bearing layer (only divergence-existence layer via component (a) and post-hoc verification via component (b)). Same defect class as cycle 2 T2.C. Honest framing surfaces it transparently rather than masking it, but transparency does not convert the structural defect into a non-defect.

- **T2.K through T2.P (documentation/calibration grade at rev 4 fix surfaces).** T2.K: pair-prioritization rule "full candidate pool" specification gap (T1.A surface). T2.L: tie-breaker "first-trigger-date if available" condition unspecified (T1.A surface). T2.M: queue dynamic from "no skip-and-prioritize" + finite session budget (T1.A surface). T2.N: KL #17 acknowledgment-only mitigation of 2.18 × 2.13/2.26 interaction (T2.I surface). T2.O: Section 1 cross-walk for Constraint 3 component (b) lives in pair-prioritization note rather than Section 1 itself (T2.J surface). T2.P: Section 1 doesn't acknowledge Anchor 2's 5-year-history newer-IPO categorical exclusion (T2.J surface).

**Theater-check CONVERGENT.** All 7 items have on-page evidence at rev 4 fix surfaces. Attacker's three-part self-flag (am I calling T1.K Tier 1 due to prompt priming? am I avoiding the call to land at acceptance? am I inflating T2s to justify non-acceptance?) is honest and well-considered. Verdict trails analysis. The cycle 2 T2.C precedent (flowing limitation not reaching load-bearing aspect = Tier 1) is the determining factor for T1.K classification — consistency demands the same call here even though rev 4's honest framing surfaces rather than masks the defect.

**EP rev 15 four-screen test on T1.K:** All four screens PASS — Screen 1 per-pair 2%/4% cap bounds magnitude regardless of which 2.24 layer bites; Screen 2 2.24 listed in Section 5; Screen 3 KL #16 specifies 15-pair-gate review trigger checking threshold-value clustering; Screen 4 KL #16 specifies a limitation, satisfying req 7 literal "exclusions OR LIMITATIONS." T1.K is deployment-risk-acceptable as Tier 1 per EP rev 15 forcing question.

**Combined revision-churn + saturation stop preconditions met.**

- *Locus-recurrence:* T1.K at rev 4 T2.F fix surface; T2.K/L/M at T1.A surface; T2.N at T2.I surface; T2.O/P at T2.J surface — 100% concentration at rev 4 fix surfaces.
- *Cycle count exhaustion:* 4 cycles, parallels Strategy D's combined-stop pattern (D combined stop at rev 5 after 4 cycles).
- *Trajectory:* 13 → 4 → 1-T1+6-T2/T3 → 1-T1+6-T2/T3 (saturation arrest at residual architectural exposure — same shape, not narrowing further; this is the saturation pattern under EP rev 14 §188 ii).

**Rev 5 spot-edit fix applied (parallel to Strategy A rev 7 / D rev 5 acceptance precedent — cycle N findings → rev N+1 spot edit → ACCEPTED under combined stop without cycle N+1 attacker run):**

- **(T1.K) 2.24 added to Section 5 confluence list with per-pair-cap as magnitude-only backup mitigation.** Cross-walk text updated: 2.24 moved from "Not in confluence list" to "In confluence list," with rationale that at the threshold-choice layer (where Constraint 3 component (a) doesn't reach and component (b) provides only post-hoc verification), the per-pair cap provides magnitude-only mitigation in the same pattern as 2.13/2.18/2.26. When threshold-choice 2.24 produces a wrong threshold leading to a wrong invalidation, the per-pair cap (2% per leg, 4% per pair) bounds loss magnitude. The cap doesn't reduce probability of threshold-choice bias (2.24 hard-wired property remains) but bounds individual-thesis blast radius. KL #16 stays as written; review trigger unchanged. Constraint 3 component (a) (divergence-existence-layer mitigation) + cap-confluence (magnitude-only backup) jointly satisfy req 7 confrontation: every load-bearing constraint now has a flowing limitation reaching the load-bearing aspect, even if the limitation is magnitude-bounding rather than probability-reducing.

T2.K-T2.P accepted as documentation residuals; no further mechanism changes.

**ACCEPTANCE: Strategy E pre-mortem ACCEPTED at rev 5 under combined revision-churn + saturation stop (EP rev 14 §188 ii + iii).** Cycles 2, 3, 4 each surfaced items at rev N's fix surfaces with the cycle 3 / cycle 4 trajectory arresting at the same shape (1-T1+6-T2/T3) — saturation pattern unambiguous. E's narrative-divergence-pairs architecture has structural properties (2.24 weight-level bias on threshold-choice; 2.18 × 2.13/2.26 interaction; deterministic Anchor 2 deferral-rate; 3x share-price-ratio parameter ceremony at boundary) that no further within-strategy revision will eliminate — these are properties of the underlying mechanism. Combined stop is the precedent-defined response. Cycle 5 not run.

**Cycle outcomes by revision (E pre-mortem complete history):**
- Rev 1 → cycle 1 TIER 1 (13 items, structural rebuild required)
- Rev 2 → cycle 2 TIER 1 (4 items at rev 2 fix surfaces, narrow scope)
- Rev 3 → cycle 3 TIER 1 (1 borderline T1 + 6 T2/T3 at rev 3 fix surfaces, Path A selected)
- Rev 4 → cycle 4 TIER 1 (1 borderline T1 + 6 T2/T3 at rev 4 fix surfaces, deployment-risk-acceptable)
- Rev 5 → ACCEPTED under combined stop

**Theater-check on this orchestrator review.** I considered whether T1.K should be classified Tier 2 to enable a cleaner deployment-risk stop at rev 4 without an additional spot edit. Counter-argument: the cycle 2 T2.C precedent ruled the same defect class Tier 1; consistency demands the same call. Counter-counter-argument: T1.K's structural property is identical, but the cap-confluence-magnitude-only backup pattern is well-established for 2.13/2.18/2.26 — extending it to 2.24 is a one-edit fix that produces principled architectural alignment. I selected the rev 5 spot edit + combined stop path, which addresses the structural property cleanly while still enabling acceptance per precedent. CONVERGENT.

**Effect on book.**

No immediate effect. Strategy E remains in DO-NOT-ACTIVATE state per divergence review 2026-04-25. Trade activation continues to require both pre-mortem completion (now satisfied) AND fundamental review reversal of DO-NOT-ACTIVATE divergence verdict (not yet addressed).

**Pending queue updated:**
- ~~Strategy E pre-mortem cycle 4~~ COMPLETE — ACCEPTED at rev 5 under combined stop.
- ~~All 5 strategy pre-mortems~~ COMPLETE — A, B, C, D, E all in final accepted state.
- Strategy E foundation-change re-assessment under AI_Trading_Foundation rev 4 mechanical framework — NEXT (citation graph stabilized at 13 items: 2.4, 2.6, 2.7, 2.8, 2.13, 2.15, 2.17, 2.18, 2.19, 2.20, 2.23, 2.24, 2.26 vs rev 1's 5 items).
- 2.10 evidence accumulation watch — Q3 quarterly task (2026-07-01).
- M2 follow-ups: empirical dispersion compression check (Strategy C); fundamental signal process tightening (Strategy E).
- Trading begin per regime/router rules. Current state: A/B/D awaiting first trade trigger; C HYBRID ACTIVATE FOMC-only with no positions; E DO-NOT-ACTIVATE.

**References:**
- Strategy.md rev 34 with E pre-mortem rev 5 ACCEPTED.
- AI_Trading_Foundation.md rev 4 (disadvantage taxonomy).
- Cycle 4 attacker output (preserved in conversation; theater-check CONVERGENT; verdict combined-stop after rev 5 spot edit).

**Compaction-survival note:** Strategy E pre-mortem ACCEPTED at rev 5 (2026-04-25) under combined revision-churn + saturation stop. All 5 strategy pre-mortems now in final accepted state. Foundation framework rev 4 operational. Foundation-change assessment cycle complete (5/5 Continue under rev 1 citation graphs). E foundation-change re-assessment under stabilized citation graph (13 items) is next logical work item. M2 rev 2 dated 2026-04-23 still current foundation. Pre-mortem cycle progression by strategy (final): A 7 cycles (combined stop at rev 7); B 7 cycles; C 9 cycles; D 5 cycles (combined stop at rev 5); E 5 cycles (combined stop at rev 5).


---

## 2026-04-25 Strategy E foundation-change re-assessment under rev 4 mechanical framework — Outcome (a) Continue

**Trigger:** E pre-mortem citation graph stabilized at rev 5 ACCEPTED (13 items vs rev 1's 5). The compaction-summary pending item "E foundation-change re-assessment after pre-mortem cycles stabilize" now actionable.

**Inputs:** Strategy.md rev 34 with E pre-mortem rev 5 ACCEPTED; AI_Trading_Foundation.md rev 4 (M2 2026-04 updates current); §5.1-§5.7 mechanical framework.

**Sessions:** Single orchestrator session (no attacker required for foundation-change framework execution per rev 4 §5.3 procedure "executed by the orchestrator session, no discretion").

**Citation graph at rev 5 (13 items):** 2.4, 2.6, 2.7, 2.8, 2.13, 2.15, 2.17, 2.18, 2.19, 2.20, 2.23, 2.24, 2.26. Edges: 1.1, 1.4 (technique within 1.1), 1.10. Expansion vs rev 1's 5-item graph (2.4, 2.6, 2.8, 2.15, 2.24): 8 new disadvantages added through cycles 1-4 (2.7, 2.13, 2.17, 2.18, 2.19, 2.20, 2.23, 2.26).

**Mechanical test results per §5.1-§5.3:**

- *§5.1 Continue test:* All 13 cited items present in current foundation rev 4 with no status change since rev 5 acceptance (rev 5 was accepted today, foundation rev 4 is current). PASS.

- *§5.2 Terminate test:* No edges removed; no disadvantages newly added that E lacks compensation for (2.26 jointly compensated with 2.13 in Constraint 4; 2.25 not cited by E, workflow-bounded); no materially worsened disadvantages where E lacks compensation (2.8 reinforcement, 2.13 mechanism-confirmation, 2.24 architectural-confirmation all incorporated through cycles 1-4). NO TERMINATE TRIGGER.

- *§5.3 Constraint-relaxation review:* Reduction candidates from M2 2026-04 = 2.10 PARTIAL reduction (Opus-tier with classifiers). E does NOT cite 2.10 → no affected constraints in E → no relaxation candidate. NO RELAXATION.

**§5.7 Audit trail produced as deliverable** (E_foundation_change_reassessment_2026-04-25.md).

**Verdict: Outcome (a) Continue.** Same outcome as prior foundation-change re-assessment cycle for E (which ran under rev 1 citation graph). The expanded rev 5 citation graph is not a foundation change — it is an expansion of which foundation properties E is exposed to, and those properties are identical to the prior assessment's foundation state.

**Cumulative experiment-level result:** 5/5 strategies (A, B, C, D, E) all produce Outcome (a) Continue under the rev 4 mechanical framework against AI_Trading_Foundation rev 4. The foundation-change assessment cycle is complete for the post-acceptance equilibrium of the experiment. No further pre-mortem revisions, terminate verdicts, or constraint relaxations triggered. 2.10 PARTIAL reduction signal produced zero relaxations across all 5 strategies (no strategy cites 2.10).

**Theater-check on this orchestrator review:** I considered whether the rev 5 citation graph's expansion (5 → 13 items) might itself constitute a foundation change requiring a different procedural treatment. Counter-argument per §5.7 framework: the citation graph is the strategy's mechanism document property, not the foundation document property; the foundation revision evaluated against is rev 4 in both cases, and rev 4's items haven't changed since the prior assessment. The expanded graph means E now exposes itself to more foundation properties, but the properties themselves are unchanged. Procedurally clean. CONVERGENT.

**Effect on book.**

No immediate effect. Strategy E remains in DO-NOT-ACTIVATE state per divergence review 2026-04-25 (fundamental review verdict, separate from foundation-change assessment).

**Pending queue updated:**
- ~~Strategy E foundation-change re-assessment~~ COMPLETE — Outcome (a) Continue.
- ~~All 5 strategies foundation-change assessment under stabilized citation graphs~~ COMPLETE — 5/5 Continue.
- 2.10 evidence accumulation watch — Q3 quarterly task (2026-07-01).
- M2 follow-ups: empirical dispersion compression check (Strategy C); fundamental signal process tightening (Strategy E).
- Trading begin per regime/router rules. Current state: A/B/D awaiting first trade trigger; C HYBRID ACTIVATE FOMC-only with no positions; E DO-NOT-ACTIVATE.
- Q2 2026 (next quarterly delta) — first scheduled foundation-change assessment of the post-acceptance equilibrium.

**References:**
- Strategy.md rev 34 with E pre-mortem rev 5 ACCEPTED.
- AI_Trading_Foundation.md rev 4 (M2 2026-04 incorporated).
- §5.7 audit trail deliverable: E_foundation_change_reassessment_2026-04-25.md.

**Compaction-survival note:** All 5 strategy pre-mortems ACCEPTED and all 5 strategies pass foundation-change re-assessment under rev 4 mechanical framework with Outcome (a) Continue. The pre-mortem-development phase of the experiment is complete. Next phase is operational: trading per regime/router rules, monthly reviews per Section 6 of each strategy's pre-mortem, Q2 2026 quarterly delta as next scheduled foundation-change checkpoint, M2 follow-up items on C dispersion compression and E fundamental signal process tightening, and 2.10 evidence accumulation watch through Q3 2026-07-01.


---


# E Fundamental Signal Generation Process — Tightened

**Per:** Strategy E divergence review M2 follow-up commitment (Decision_Log 2026-04-25 entry "Strategy E divergence review", lines 388-392).
**Initiated:** 2026-04-26 (this document).
**First applied:** 2026-05-01 M2 fundamental update.
**Scope:** Process-documentation improvement for how the monthly fundamental signal for Strategy E gets generated. NOT a strategy-spec change. The activation rule per Strategy.md remains: technical AND fundamental → ACTIVATE; divergence → adversarial review.

---

## Why this tightening is required

The 2026-04-23 M1 fundamental rationale for E was: *"Macro vector overriding intra-industry dispersion; within-sector mean reversion suppressed."*

The 2026-04-25 divergence-review attacker showed this rationale is insufficient on three structural grounds:

1. **GICS level ambiguity.** E operates at the **industry group** level (GICS 4-digit), but the rationale used "sector" language (GICS 2-digit). These are different aggregation levels and dispersion behaves differently at each. The reasoning didn't specify which level was being assessed.

2. **Mechanism mismatch.** E's edge isn't "within-sector mean reversion" — it's a market-neutral pair structure with a 0.5 correlation entry filter that depends on within-pair correlation stationarity over the trailing-252-day window. The fundamental rationale reasoned at the sector level rather than engaging with E's actual mechanism (pair correlation + market-neutral hedge).

3. **Measurable vs qualitative.** Intra-industry-group return dispersion is **directly measurable** from primary OHLC data. The rationale used a qualitative claim ("dispersion suppressed") rather than a measurement. For a strategy that operates on quantitative entry criteria, the fundamental signal should prefer measurable inputs where they're available.

The procedural moot point (E is effectively inactive at current portfolio size due to ETF substitution requirement) made the 2026-04-25 decision low-stakes. **At higher portfolio sizes the same insufficient rationale would not be acceptable.** This document tightens the process so the next M2 produces a sufficient rationale even at higher stakes.

---

## Tightened E fundamental signal template

Each monthly fundamental update for E must produce a document containing the following sections in order. Empty sections are not permitted; if a section is genuinely not applicable, the rationale must say so explicitly.

### Section 1 — GICS level being assessed

State explicitly which GICS level the fundamental assessment operates at:
- **GICS Industry Group (4-digit):** the level E pairs are constructed within (per Strategy.md monthly E pair screen)
- **GICS Sector (2-digit):** broader aggregation — generally not directly relevant to E unless the assessment makes a case for sector-level effects propagating to industry-group dispersion

Default: industry group. If sector is used, the rationale must explain why sector-level reasoning binds at the industry-group level for E's specific pair-correlation mechanism.

### Section 2 — Mechanism engagement

The fundamental signal must engage with E's actual mechanism, which has three components:

(a) **Pair correlation stationarity.** E's entry criterion 3 requires trailing-252-day correlation ≥ 0.5 between pair legs. The fundamental signal must address: does the current regime maintain or break correlation stationarity at the 252-day window? Specifically, are there regime breaks in the trailing 252 days that materially change the correlation structure (e.g., Hormuz oil shock 2026-04 vs pre-shock baseline)?

(b) **Market-neutral hedge effectiveness.** E pairs are constructed long-leg / short-leg within an industry group. The hedge effectiveness depends on the residual macro/factor exposure not being dominant. The fundamental signal must address: is the current regime one where the hedged residual is small (ACTIVATE-supportive) or where macro factors leak through the hedge (DO-NOT-ACTIVATE-supportive)?

(c) **Convergence horizon.** E theses have a 6-12 week typical convergence window. The fundamental signal must address: is the regime structure stable enough over a 6-12 week forward window for a pair entered today to converge before structural changes invalidate the thesis?

Each of (a), (b), (c) gets at least one paragraph engaging with current data; not just regime characterization at the macro level.

### Section 3 — Measurable inputs

Where measurable proxies exist, the fundamental signal must use them rather than qualitative claims. Required measurables for each monthly E update:

(a) **Median pair-correlation across E's eligible-pair universe** in the trailing 252 days vs trailing 5-year median. Computed as: for each industry group with ≥ 10 names meeting market-cap and ADV minimums, compute pairwise correlations; aggregate to median across all qualifying pairs. Compare to 5-year baseline.
- ACTIVATE-supportive: current median within ±10% of 5-year baseline (correlation structure stable)
- DO-NOT-ACTIVATE-supportive: current median > 1.20 × baseline (correlations rising toward 1, stress-regime indicator) OR < 0.80 × baseline (correlations unmoored, dispersion-regime indicator)

(b) **Median intra-industry-group return dispersion** in the trailing 30 trading days. Computed as: for each industry group, compute the standard deviation of single-day returns across constituent names per day; aggregate to median per industry group; aggregate to median across all groups. Compare to 5-year same-month baseline.
- ACTIVATE-supportive: current median within ±20% of 5-year same-month baseline
- DO-NOT-ACTIVATE-supportive: current median < 0.80 × baseline (dispersion compressed; pair convergence trades have insufficient magnitude) OR > 1.50 × baseline (dispersion-regime; correlation breakdowns dominate)

(c) **Anchor 2 deferral rate** in the trailing 30-day evaluated-pairs sample (per Strategy.md Strategy E pre-mortem rev 5 residual 15). Computed as: fraction of evaluated pair theses that deferred due to insufficient reference-set qualifying pairs (< 10 pairs with 5-year joint history and market-cap/ADV minimums in the candidate's industry group).
- ACTIVATE-supportive: deferral rate ≤ 30% (Anchor 2 financing gate is functional)
- DO-NOT-ACTIVATE-supportive: deferral rate > 30% (financing gate is structurally inapplicable to too many candidates; signals universe coverage gap)

If any measurable input cannot be computed (data gap, sample size insufficient), the rationale must explicitly state so and explain how the missing measurement affects the conclusion.

### Section 4 — Verdict structure

The signal verdict must be one of:
- **ACTIVATE** — all three Section 2 components plus all three Section 3 measurables support
- **DO-NOT-ACTIVATE** — at least one Section 2 component or one Section 3 measurable does not support, AND the rationale explicitly identifies which
- **AMBIGUOUS** — internal contradictions between Section 2 mechanism reasoning and Section 3 measurable evidence; default-on-ambiguity → DO-NOT-ACTIVATE per Experiment_Parameters.md

The verdict must cite the specific failing component for DO-NOT-ACTIVATE or the specific contradiction for AMBIGUOUS.

### Section 5 — Theater check

Every monthly E fundamental signal includes a self-theater-check:
- Was the rationale generated by reasoning forward from data to verdict, or by reasoning backward from a felt verdict to a supporting rationale?
- Are the Section 3 measurables computed from primary data, or are they "estimated" / "inferred" / "characterized" without specific numbers?
- Does the Section 2 mechanism engagement use E's actual entry criteria (correlation 0.5, 252-day, industry group) or use proxy concepts (sector, mean reversion, generic dispersion)?

The theater-check answer is included in the document. If any answer indicates working-backward-from-verdict or substituted-proxies, the signal should be reconsidered before submission.

---

## Application at 2026-05-01 M2

The 2026-04-23 M1 fundamental rationale (which generated the divergence and led to DO-NOT-ACTIVATE) does NOT meet this tightened template. At M2, the fundamental analyst must generate a new rationale per the above template. Specifically:

- Section 1 must explicitly say "industry group" (the level E operates at).
- Section 2 must engage with correlation stationarity, hedge effectiveness, and convergence horizon as separate sub-rationales.
- Section 3 must include the three measurables with actual numbers from M1-M2 cycle data.
- Section 4 must produce one of the three verdicts with explicit citations.
- Section 5 must include the theater-check.

If the new rationale produces ACTIVATE and matches the technical signal (which depends on M2-cycle SPY/VIX/Breadth state), E activation reopens for adversarial review. If it produces DO-NOT-ACTIVATE or AMBIGUOUS, E remains DO-NOT-ACTIVATE.

If the new rationale matches the M1 verdict (DO-NOT-ACTIVATE) but with this tightened structure, the divergence review can be re-run; the attacker no longer has the "insufficient rationale at higher stakes" angle, so the review is more likely to produce a clean verdict either direction.

---

## Pre-committed actions

1. **Sat 2026-05-01 morning:** Run the three Section 3 measurables on current data. Document the actual numbers and source URLs.
2. **2026-05-01 same session:** Generate the Section 1, 2, 4, 5 narrative rationale using the measurables as inputs.
3. **2026-05-01 same session:** Compare the technical signal (SPY trend, VIX, breadth — refresh from primary sources) against the new fundamental verdict.
4. **If divergent:** Trigger the standard divergence-review protocol (single-session attacker + orchestrator review per EP rev 14).
5. **If agreement:** Update Regime_State with the new activation state. Document in Decision_Log entry "E M2 fundamental update 2026-05-01" with the actual numbers, the verdict, and any process-template adherence notes.

---

## Theater-check on this methodology

**Q: Is this template designed to make E re-activation more likely, or to make the signal more rigorous?**

The template is structurally neutral. ACTIVATE and DO-NOT-ACTIVATE both require explicit evidence; AMBIGUOUS defaults to DO-NOT-ACTIVATE. The template adds rigor by requiring measurables and mechanism engagement, which makes the signal more defensible in either direction. It does not bias toward activation.

**Q: Are the Section 3 thresholds (±10%, ±20%, 30%) calibrated or arbitrary?**

The 30% Anchor-2 deferral rate threshold matches the explicit threshold in Strategy.md Strategy E pre-mortem rev 5 residual 15. The ±10% pair-correlation and ±20% dispersion thresholds are first-pass; they will be reviewed at the rev 4 deferral-rate-audit point (per Strategy.md rev 5 residual 15: "at 15-pair gate, audit"). For now, they're documented and pre-committed; calibration refinement can happen on the audit cycle.

**Q: Does this template lock in the wrong abstraction?**

The template is committed to industry-group-level reasoning, which matches Strategy.md's strategy-spec. If a future regime emerges where sector-level effects clearly dominate industry-group effects (e.g., a sector rotation so strong that all industry groups within sectors move together), the template would correctly produce DO-NOT-ACTIVATE because the Section 3 dispersion measurable would compress. The abstraction is correct for E's mechanism.

---

## Cross-references

- Strategy.md Strategy E section + pre-mortem rev 5 (especially residuals 11, 15 — pair-correlation non-stationarity and Anchor 2 deferral rate calibration).
- Decision_Log 2026-04-25 entry "Strategy E divergence review" lines 380-407 (the M2 follow-up commitment with three-point list).
- Experiment_Parameters.md rev 14 §362 (default-on-ambiguity rule used in Section 4 verdict).
- AI_Trading_Foundation.md disadvantage 2.7 (regime maladaptation — the residual the mechanism engagement operationalizes).

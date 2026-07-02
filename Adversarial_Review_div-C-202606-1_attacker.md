# Adversarial Review — Attacker

- **id:** div-C-202606-1
- **review_type:** divergence-review
- **date:** 2026-07-02
- **cycle_number:** 1
- **strategy:** C
- **artifact under review:** Monthly_Fundamental.md (M1b, 2026-06)
- **divergence:** Technical ACTIVATE / Fundamental DO-NOT-ACTIVATE

## Verdict (one line)

**FUNDAMENTAL CLAIM SHOULD NOT SURVIVE as a blanket DNA** — the Strategy-C DO-NOT-ACTIVATE rests on an unfalsifiable "macro-dominated by construction" assertion with no measured cross-sectional dispersion, is internally contradicted by its own FOMC-tradeable carve-out, and leans on an out-of-artifact edge citation the reviewer cannot verify; the technical ACTIVATE is the better-supported call for June.

## Specific weaknesses identified (each anchored to artifact text)

1. **Unfalsifiable / unmeasured core premise ("macro-dominated by construction").** The DNA reasoning (§Strategy C, "June is macro-dominated by construction … per-name earnings-reaction dispersion compresses toward a common Fed-and-inflation factor") asserts that idiosyncratic options-pricing dispersion has degraded, but reports **zero measurement** of it — no realized single-name earnings-reaction dispersion, no option-implied dispersion, no cross-name correlation figure. C's fundamental question is empirical ("is the event-trading environment functional"), yet the answer is inferred entirely from macro headlines. "By construction" is precisely the phrasing that makes a claim unfalsifiable: any macro-active month is DNA by definition regardless of whether per-name catalysts actually stopped being rewarded.

2. **Internal contradiction — the FOMC carve-out concedes a functional event.** The same paragraph states "FOMC IS the macro catalyst the DNA reasoning names as dominating" and that the prior HYBRID resolution activated C for FOMC. If the single highest-signal scheduled event of the month is affirmatively tradeable, the blanket "event-trading environment non-functional" claim is self-refuted at its most important instance. The artifact carries the exception as "the existing final state, not re-issued here," but that is a bookkeeping move, not a fundamental reason the environment is non-functional.

3. **Non-sequitur: macro dominating the INDEX ≠ per-name catalysts unrewarded.** The evidence cited (dot-plot flip, dollar to 15-month high, two macro VIX spikes — §PART 1, lines 27–29) is index-level / cross-asset. C trades individual-name event dispersion. Macro dominating aggregate index returns does not entail that a specific earnings surprise fails to move its own name idiosyncratically. The inference "macro loud → per-name signal dead" is asserted, not shown.

4. **The cited vol evidence does not clear the strategy's own non-functional threshold.** Both VIX spikes "topped ~22 then settled 16.45" (echoed in the B section, line 70) — i.e. NORMAL by the shared vocabulary (15 ≤ VIX ≤ 25). The router's own HIGH-VIX exclusion (>25) never fired. Credit stayed historically tight (IG ~80bps / HY ~285bps, line 29). The regime the artifact describes is an orderly, non-crashing tape — exactly the environment C's technical rule (SPY Trend ≠ DOWN → ACTIVATE) is designed to green-light.

5. **Out-of-artifact, unverifiable support citation.** The reasoning leans on "AI_Edges 2.13 miscalibration compounds directional thesis quality in compressed cross-sections" without reproducing or quantifying it in the artifact. Under the self-containment requirement, a load-bearing edge claim the (blinded) reviewer cannot check is a weakness; it functions as an appeal to authority rather than in-artifact evidence.

## Self-imposed scope confirmation

I read only: the PENDING_REVIEW queue entry `div-C-202606-1` (item + trigger_context/payload) and its `artifact_path` **Monthly_Fundamental.md**. I did NOT read: `events.decision_log` or any decision history, prior `events.adversarial_reviews` / `Adversarial_Review_*.md` files (including the div-C-202605-1 prior cycle), any Strategy.md / Experiment_Parameters.md section beyond what the artifact itself reproduces, prior versions of the artifact, or any other repo file or BigQuery state.

## Reasoning

C's divergence is Tech ACTIVATE / Fund DNA, same-direction as the prior cycle. The technical rule passes cleanly (orderly tape, VIX NORMAL, no HIGH-VIX exclusion). The fundamental DNA depends on a single chain — "macro is loud → per-name dispersion compresses → C's directional theses degrade" — where only the first link (macro is loud) is evidenced, and it is evidenced at the index level. The middle link (measured dispersion compression) is never demonstrated, and the third (thesis degradation) leans on an unverifiable external edge citation. The artifact's own FOMC carve-out is a direct counterexample to the blanket claim. The strongest bear case therefore favors the technical ACTIVATE; at minimum the fundamental should not survive as an un-decomposed blanket DNA, and the FOMC-tradeable concession is the seam where ACTIVATE gets in. The honest residual for the fundamental side: the prior HYBRID (FOMC-only) resolution already reflects a middle path, and nothing in the artifact shows June's per-name environment is *more* functional than the FOMC-only scope — but the burden of proof is on the DNA claim to demonstrate non-functionality, and it does not carry it.

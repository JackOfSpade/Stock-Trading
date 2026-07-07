# Adversarial Review — Orchestrator

- **id:** div-C-202606-1
- **review_type:** divergence-review
- **date:** 2026-07-06
- **cycle_number:** 1
- **strategy:** C
- **artifact under review:** Monthly_Fundamental.md (M1b, 2026-06)
- **attacker output:** Adversarial_Review_div-C-202606-1_attacker.md
- **divergence:** Technical ACTIVATE / Fundamental DO-NOT-ACTIVATE

## Final verdict (one line)

**HYBRID ACTIVATE (FOMC-only) — binding, UNCHANGED from prior state.** The attacker correctly dismantles the *blanket* fundamental DNA (unmeasured, index-level, unfalsifiable "by construction"), so a full-DNA that parks C entirely is not supported; but the attacker itself concedes nothing in the artifact shows the broader per-name environment is *more* functional than the FOMC-only scope, so a full ACTIVATE is equally unsupported — the calibrated middle (activate C only for the affirmatively-tradeable FOMC catalyst, stay parked otherwise) is exactly what June's evidence re-confirms.

## Theater-check flag

**MIXED.** The orchestrator partially ratifies the attacker (the blanket DNA does not survive) and partially diverges (it declines the attacker's implied full-ACTIVATE, performing an independent FOMC-scope decomposition grounded in the attacker's own concession and the burden-of-proof symmetry). A genuine middle-path verdict with independent reasoning — not a rubber-stamp. Verdict binds (theater-check ≠ CONVERGENT).

## (a) Validity of each attacker weakness

1. **Unfalsifiable / unmeasured "macro-dominated by construction."** — **VALID (Tier 1).** C's fundamental question is empirical (is the event-trading environment functional?), yet the artifact reports zero measured single-name earnings-reaction dispersion, option-implied dispersion, or cross-name correlation. "By construction" is unfalsifiable phrasing; the DNA is inferred entirely from macro headlines.

2. **FOMC carve-out concedes a functional event (internal contradiction).** — **VALID (Tier 2).** The blanket "event-trading environment non-functional" claim is in genuine tension with an affirmatively-tradeable FOMC. The artifact's "carried by existing state, not re-issued" is a bookkeeping move, not a fundamental reason. But this is precisely why the resolution is HYBRID, not full DNA — the seam the attacker finds is exactly the FOMC scope that stays activated.

3. **Non-sequitur: macro dominating the INDEX ≠ per-name catalysts unrewarded.** — **VALID (Tier 2).** The cited evidence (dot-plot flip, dollar to 15-month high, two macro VIX spikes) is index/cross-asset level; C trades individual-name event dispersion. The inference "macro loud → per-name signal dead" is asserted, not shown.

4. **Vol evidence does not clear the non-functional threshold.** — **VALID (Tier 2).** Both VIX spikes topped ~22 then settled 16.45 = NORMAL; the router's HIGH-VIX (>25) exclusion never fired; credit stayed tight (IG ~80 / HY ~285). The regime described is orderly — exactly what C's technical rule green-lights.

5. **Out-of-artifact unverifiable edge citation (AI_Edges 2.13).** — **VALID but MINOR (Tier 3).** Under self-containment a load-bearing edge claim the blinded reviewer cannot check is a weakness, but it is a supporting citation, not the spine of the DNA. Noted, low weight.

## (b) Theater in the attacker output

Minimal. The attacker is well-anchored throughout. The one over-reach is the framing that "the technical ACTIVATE is the better-supported call" read as full ACTIVATE — the attacker's own reasoning section walks this back ("the prior HYBRID … already reflects a middle path … nothing in the artifact shows June's per-name environment is more functional than the FOMC-only scope"). Its verdict headline is stronger than its own analysis supports.

## (c) Weaknesses the attacker missed

- **The burden-of-proof cuts both ways.** The attacker correctly places the burden on the DNA to demonstrate non-functionality (it fails). But the symmetric point — no evidence discharges a burden to demonstrate *broad* functionality either — means the resolution cannot be full ACTIVATE. The prior HYBRID (FOMC-only) is the only scope with affirmative support (FOMC is a scheduled, high-signal, tradeable macro catalyst), and June adds nothing to broaden it.
- **The divergence is recurring same-direction.** This is a re-run of the standing C divergence with no new per-name-functionality evidence; the default posture is to re-confirm the last calibrated resolution, not to re-open the scope.

## (d) Reasoning and binding decision

The attacker's narrow claim — the fundamental should not survive as a blanket un-decomposed DNA — is correct and I adopt it. But its headline (technical ACTIVATE wins) over-reaches its own concession. The correct resolution is the scope decomposition the prior cycle already reached: **HYBRID ACTIVATE — FOMC events only.** New C entries permitted ONLY for FOMC catalysts meeting Strategy C entry criteria 1–5; corporate-earnings / FDA-PDUFA / vol-directional theses across all other event types remain DO-NOT-ACTIVATE (C otherwise parked in SGOV). June's macro-dominated-but-orderly tape supports neither broadening beyond FOMC (no measured per-name functionality) nor closing FOMC (it is affirmatively tradeable). **UNCHANGED from the prior binding state.**

## Action taken

- `events.regime_events` (scope `STRATEGY_ACTIVATION`, key `C`): binding state `HYBRID ACTIVATE (FOMC-only)` written, superseding the M4 2026-07-01 PENDING row; theater_check MIXED; source_review_ref this orchestrator review.
- Verdict does not differ from the prior binding state (HYBRID ACTIVATE, FOMC-only) → no `events.decision_log` flip entry (per AR_orc protocol; outcome recorded in `events.adversarial_reviews`).
- No orders staged; no calendar events.

2026-06

# Monthly Fundamental — Strategy Mapping and Activation Calls (M1b)

Routine: M1b strategy-mapping. Coverage period: regime scoring is the **June 2026** M1a output (`events.regime_events` scope `FUNDAMENTAL_AXIS`, `as_of_date = 2026-07-01`). Compiled 2026-07-01 (America/Denver).

Inputs read for this routine (per M1b read-scope discipline):
- `events.regime_events` / `state.current_regime` scope `FUNDAMENTAL_AXIS` (latest month) — M1a strategy-blind regime scoring, the ONLY regime input.
- `Strategy.md` (per-strategy activation rules, fundamental questions, reconciliation rules, immutable output format) — read via slices `02_regime_router.md` + `03–07`.
- `events.regime_events` / `state.current_regime` scope `TECHNICAL_SIGNAL` (current technical signals per the shared regime vocabulary — for divergence flagging only).
- `events.regime_events` scope `STRATEGY_ACTIVATION` (prior-call lookup) + `state.current_positions` / `events.decision_log` (operational context).

Inputs explicitly NOT read for this routine (architectural blinding per Strategy.md "Two-routine blinded scoring"): `events.macro_series` and any other macro / Fed / earnings / geopolitical / policy source for June 2026. M1b's regime view is exactly M1a's `FUNDAMENTAL_AXIS` scoring — no more.

Fallback-suppression flag from M1a: `fallback_suppression = false` → proceed with per-strategy activation calls and divergence flags.

---

## PART 1 — Echo of M1a regime scoring (June 2026)

Reproduced from `events.regime_events` (`FUNDAMENTAL_AXIS`, `as_of_date = 2026-07-01`). This is the only regime context for downstream consumers and for any divergence-review attacker.

- **growth_momentum: stable.** May payrolls +172k beat the +80k consensus with Mar/Apr revised up a combined +93k (strongest 3-month advance in 2+ years); U-3 steady at 4.3%. Retail sales +0.9% MoM (core +0.7%) and Q1 GDP revised UP to +2.1% (from the +1.6% second estimate) corroborate firm demand, though industrial production was soft (+0.1% MoM). Re-firms from the prior month's `decelerating` read: real-time labor and consumer data reversed the softening, so momentum is holding rather than deteriorating.

- **inflation_trend: reaccelerating.** May CPI +4.2% YoY / +0.5% MoM (core +2.9% YoY, highest since Sep 2025); PPI +6.5% YoY (wholesale gasoline +23.4%); core PCE +3.4% YoY and headline PCE +4.1% YoY — the preferred gauge at its fastest in ~3 years. Every major price gauge accelerated versus the prior release. Oil's retreat to pre-war ~$73 is a forward disinflationary signal not yet reflected in the reported data.

- **policy_stance: hawkish.** June FOMC held the target range at 3.50–3.75% unanimously, but the dot-plot 2026 year-end median rose to 3.8% (from 3.4% in March), implying no cuts with a tilt to a hike (9 of 18 participants project ≥1 hike, 1 a cut). The statement was sharply shortened with easing-bias language removed, and projected 2026 inflation was raised to 3.6% headline / 3.3% core. The dollar index rose ~2% to a 15-month high (~101.3) on the hawkish shift.

- **risk_sentiment: neutral.** Equities slipped ~1% on the month (broad index −1.06%, ending near but below early-June record highs) with two intramonth volatility spikes — VIX to ~22 on the hot CPI print and ~19.5 on the late-June geopolitical flare — before settling at 16.45. Credit spreads stayed historically tight (IG OAS ~80bps, HY ~285bps), arguing against stress. Net: appetite cooled from the prior month's `risk-on` to `neutral` as the rally paused, with no credit-market stress.

- **shock_overlay: latent.** The Iran conflict (active since Feb 28) de-escalated further: a mid-June ceasefire framework restored near-normal Strait of Hormuz flows and Brent fell to pre-war ~$73 (lowest since Feb 27). But late-June tit-for-tat US/Iranian strikes and un-cleared mines kept the ceasefire fragile and unconfirmed by Tehran. Residual tail risk persists (`latent`); `acute` excluded as the kinetic phase has paused and oil normalized.

**Integrative summary (strategy-blind, June 2026).** Stable (re-firmed) growth + reaccelerating inflation + hawkish policy + neutral risk sentiment + latent shock overlay. The prior month's stagflation tilt resolved toward **reflation** as strong May labor (+172k, large upward revisions) and consumer data reversed the growth-deceleration narrative while every inflation gauge accelerated (core PCE 3.4%, fastest in ~3yrs). Dominant tension: a firm, still-inflationary real economy meeting a decisively hawkish Fed (dot plot flipped to no-cuts / hike-bias), with the equity rally pausing (−1%) but credit tight. `fallback_suppression = false`.

**Month-over-month regime deltas (May → June).** growth_momentum `decelerating → stable` (the material change); risk_sentiment `risk-on → neutral`; inflation_trend `reaccelerating` (unchanged); policy_stance `hawkish` (unchanged); shock_overlay `latent` (unchanged). Integrative tilt `stagflation + risk-on → reflation + neutral`.

---

## PART 2 — Activation calls and divergence flags

Current technical signal states (from `state.current_regime` / `events.regime_events` scope `TECHNICAL_SIGNAL`, `as_of 2026-06-03`; VIX regime derived from the M1a-reported June close of 16.45 per the shared vocabulary 15 ≤ VIX ≤ 25 = NORMAL), applied to each strategy's technical activation rule:

| Indicator | State |
|-----------|-------|
| SPY Trend State | NEUTRAL |
| VIX Regime | NORMAL |
| Yield Curve Sustained Inversion Flag | NOT-SUSTAINED |
| Equity Breadth State | HEALTHY |

Prior-month calls, for the FLIP/UNCHANGED comparison. Two lineages are tracked because they diverge: (i) prior **M1b fundamental** call (post-reconciliation) — from `Monthly_Fundamental.md (2026-05)` / `events.regime_events` `STRATEGY_ACTIVATION` `as_of 2026-06-01`; (ii) prior **final activation state** (post-M4 / post-divergence-review) — `STRATEGY_ACTIVATION` `as_of 2026-06-03`. The FLIP tag below is on the **fundamental** lineage (what M1b produces); the final-state lineage is carried in the downstream-action notes so M4 sees the operative state each divergence review re-opens.

| Strategy | Prior M1b fundamental (post-recon, May) | Prior final activation state (post-review, 2026-06-03) |
|----------|------------------------------------------|--------------------------------------------------------|
| A | DO-NOT-ACTIVATE | DO-NOT-ACTIVATE |
| B | ACTIVATE | ACTIVATE |
| C | DO-NOT-ACTIVATE | HYBRID ACTIVATE (FOMC-only) |
| D | DO-NOT-ACTIVATE | ACTIVATE (M1b flip-to-DNA rejected at review; RTX/DIS run to invalidation) |
| E | DO-NOT-ACTIVATE | ACTIVATE (substantive; execution-feasibility-deferred, ETF-substitution-required) |

### Strategy A:
  Activation call: DO-NOT-ACTIVATE
  Reasoning: M1a June scoring is `stable growth + reaccelerating inflation + hawkish policy + neutral risk + latent shock`. A's fundamental question asks whether individual-stock catalysts are being rewarded, or whether macro factors dominate idiosyncratic narrative. June is a Fed-reaction-function-dominated tape: every inflation gauge accelerated (core PCE 3.4%, fastest in ~3yrs), the dot plot flipped to no-cuts / hike-bias, the dollar hit a 15-month high, and the two intramonth VIX spikes were both macro-driven (the hot CPI print; the late-June geopolitical flare) — not idiosyncratic-catalyst dispersion. The equity rally *paused* (−1%) and sentiment cooled to `neutral`, so the risk-on breadth that a catalyst-reward regime needs has faded rather than broadened; SPY Trend is NEUTRAL, not UP. The growth re-firm to `stable` removes the recessionary leg of A's May case but does not convert the tape to one that rewards single-name narrative over the next macro print (next CPI, July FOMC, tariff-appeal path). Over A's 1–12 month horizon the payoff requires the market to absorb the catalyst rather than re-price on the Fed reaction function — the opposite of the observed June tape. Fundamental DO-NOT-ACTIVATE stands.
  Reconciliation override applied: no. NOTE the change from May: the `growth_momentum = decelerating AND policy_stance = hawkish → A DNA` rule's precondition is NO LONGER satisfied (growth re-firmed to `stable`), so unlike May it is not even a latent trigger this month; A's DNA rests solely on the fundamental reasoning.
  Technical signal for this strategy: DO-NOT-ACTIVATE (rule: SPY Trend = UP AND Breadth = HEALTHY → SPY Trend = NEUTRAL fails the first clause)
  Divergence: NO
  Prior call comparison: UNCHANGED (May fundamental: DO-NOT-ACTIVATE)

### Strategy B:
  Activation call: ACTIVATE
  Reasoning: B's fundamental question asks whether event reactions show measurable mean reversion at 2–8 week horizons, or whether the regime is one where reactions are fully informative. June's `neutral` risk + NORMAL VIX (close 16.45) + `latent` shock supports the mean-reversion mechanism: vol is moderate rather than compressed-or-panicked, so individual post-event overshoots are large enough to fade yet not drowned by regime beta. The cooling from `risk-on` to `neutral` is, if anything, favorable for B — the euphoric-extrapolation tail that makes beats hard to fade has eased while credit stays tight (no stress that would turn every reaction into a selling cascade). The principal residual risk is macro-print sentiment shock: the two June VIX spikes show reaccelerating inflation + a hawkish Fed can produce sharp cross-asset moves around CPI/FOMC that mimic post-event noise. B's per-thesis criterion-4 information-vs-sentiment test and the short 10-day entry window already filter for information-driven single-name moves, and the router's HIGH-VIX exclusion (VIX > 25) provides regime-level mitigation if vol rebreaks 25 (it did not — spikes topped ~22 then settled 16.45). Mechanism intact; fundamental ACTIVATE stands.
  Reconciliation override applied: no (no reconciliation rule applies to B at any regime-axis combination)
  Technical signal for this strategy: ACTIVATE (rule: SPY Trend ≠ DOWN AND VIX ≠ HIGH → NEUTRAL ≠ DOWN passes; NORMAL ≠ HIGH passes)
  Divergence: NO
  Prior call comparison: UNCHANGED (May fundamental: ACTIVATE)

### Strategy C:
  Activation call: DO-NOT-ACTIVATE
  Reasoning: C's fundamental question asks whether the event-trading environment is functional, or whether the regime is dominated by macro shocks that override individual-catalyst dynamics. June is macro-dominated by construction: the Fed reaction function is the dominant pricing factor (dot plot flipped to no-cuts / hike-bias; projected 2026 inflation raised to 3.6% / 3.3%; dollar to a 15-month high), and both intramonth vol spikes were macro (CPI print; geopolitical flare). In that configuration per-name earnings-reaction dispersion compresses toward a common Fed-and-inflation factor, degrading the clean idiosyncratic options-pricing dispersion C's directional theses require (AI_Edges 2.13 miscalibration compounds directional thesis quality in compressed cross-sections). Per the M1b immutable output format the strategy-level fundamental call is binary DO-NOT-ACTIVATE. The FOMC-only affirmative exception that produced the prior HYBRID resolution (FOMC IS the macro catalyst the DNA reasoning names as dominating, not an individual catalyst suppressed by macro) is a divergence-review-resolved scope decomposition, not an M1b output — it is carried by the existing final state, not re-issued here. Fundamental DO-NOT-ACTIVATE stands.
  Reconciliation override applied: no (no reconciliation rule applies to C at any regime-axis combination)
  Technical signal for this strategy: ACTIVATE (rule: SPY Trend ≠ DOWN → NEUTRAL passes)
  Divergence: YES (Tech ACTIVATE / Fund DO-NOT-ACTIVATE)
  Prior call comparison: UNCHANGED (May fundamental: DO-NOT-ACTIVATE)

### Strategy D:
  Activation call: ACTIVATE  →  **post-reconciliation DO-NOT-ACTIVATE** (override fires; see below)
  Reasoning: D's fundamental question asks whether the current macro-structural environment is one in which multi-year equity theses can plausibly play out, or whether structural headwinds argue against initiating new long-horizon positions. The material June change is the growth re-firm to `stable`: May's DNA flip was built on decelerating growth + a record-low UMich + a GDP revision to +1.6% ("late-cycle compression risk materially elevated"); that leg has REVERSED (payrolls +172k, GDP revised UP to +2.1%, retail +0.9%, U-3 steady 4.3%), and the yield curve is NOT-SUSTAINED-inverted with no recession signal. On the recessionary-compression axis alone, the raw fundamental case for initiating multi-year theses tips back to ACTIVATE. HOWEVER, the reflation configuration carries the discount-rate leg intact: inflation reaccelerating (core PCE 3.4%) + a decisively hawkish Fed (no-cuts / hike-bias) is a higher-for-longer regime that structurally compresses long-duration equity theses via the discount-rate path — precisely the case the M1a/M1b reconciliation rule codifies. So the raw ACTIVATE is mechanically overridden to DO-NOT-ACTIVATE.
  Reconciliation override applied: **yes** — rule `inflation_trend = reaccelerating AND policy_stance = hawkish → override D ACTIVATE → DO-NOT-ACTIVATE`. Precondition satisfied (reaccelerating + hawkish) AND raw call is ACTIVATE → the rule **FIRES this month** (contrast May, when it was precondition-satisfied but did not fire because the raw call was already DNA). Post-reconciliation fundamental call: DO-NOT-ACTIVATE.
  Technical signal for this strategy: ACTIVATE (rule: (SPY Trend = UP OR NEUTRAL) AND Sustained Inversion = NOT-SUSTAINED → NEUTRAL passes; NOT-SUSTAINED passes)
  Divergence: YES (Tech ACTIVATE / Fund post-reconciliation DO-NOT-ACTIVATE)
  Prior call comparison: UNCHANGED post-reconciliation (May fundamental post-recon: DO-NOT-ACTIVATE → June post-recon: DO-NOT-ACTIVATE). The RAW call rose ACTIVATE on the growth re-firm, but the reconciliation override returns the final call to DO-NOT-ACTIVATE — **net final call unchanged, so there is NO router flip for M4 to action.** Existing D positions (RTX, DIS per `state.current_positions`) run to thesis-invalidation under the router-deactivation-does-not-force-exits rule; new D entries remain blocked pending the divergence-review outcome.

### Strategy E:
  Activation call: DO-NOT-ACTIVATE
  Reasoning: E's fundamental question asks whether the current sector-rotation environment is conducive to within-industry-group mean reversion, or whether macro forces are dominating intra-sector dynamics. June is macro-driven: the Fed reaction function and reaccelerating inflation are the dominant cross-sectional factor, and the oil-normalization / ceasefire-relief vector (Brent to pre-war ~$73) is itself an intra-sector macro overlay that compresses within-industry dispersion in energy, transports and industrials — the sectors most prone to E pairs at retail-tradeable instrument depth. The growth re-firm to `stable` and the cooling to `neutral` risk do not restore the L-vs-S fundamental-divergence signal E needs; they leave the tape governed by a common macro factor rather than idiosyncratic within-group divergence. The trailing-252-day correlation stationarity E's criterion 3 relies on remains stressed by the 2026 regime-break sequence (Feb tariff-IEEPA ruling; the Feb–Jun Iran conflict; the oil round-trip) — the structural-macro-hedge-failure-before-convergence risk from the prior divergence-review verdict persists. Fundamental DO-NOT-ACTIVATE stands.
  Reconciliation override applied: no (no reconciliation rule applies to E at any regime-axis combination)
  Technical signal for this strategy: ACTIVATE (rule: SPY Trend ≠ DOWN AND VIX ≠ HIGH AND Breadth = HEALTHY → NEUTRAL ≠ DOWN passes; NORMAL ≠ HIGH passes; HEALTHY passes)
  Divergence: YES (Tech ACTIVATE / Fund DO-NOT-ACTIVATE)
  Prior call comparison: UNCHANGED (May fundamental: DO-NOT-ACTIVATE)

---

## Reconciliation overrides applied

Mechanically checked AFTER step 1 per Strategy.md M1a/M1b reconciliation rules and the M1b prompt:

| Rule | M1a June axis values | Strategy targeted | M1b raw call | Override applied? |
|------|----------------------|-------------------|--------------|-------------------|
| shock_overlay = acute → override all ACTIVATE → DNA | shock_overlay = `latent` | all | n/a | NO (precondition fails — `latent` not `acute`) |
| risk_sentiment = stressed → override A or D ACTIVATE → DNA | risk_sentiment = `neutral` | A, D | A DNA / D ACTIVATE | NO (precondition fails — `neutral` not `stressed`) |
| growth_momentum = decelerating AND policy_stance = hawkish → override A ACTIVATE → DNA | growth `stable`, policy `hawkish` | A | A DNA | NO (precondition fails — growth `stable` not `decelerating`; note this rule WAS precondition-satisfied in May and is now inert) |
| inflation_trend = reaccelerating AND policy_stance = hawkish → override D ACTIVATE → DNA | inflation `reaccelerating`, policy `hawkish` | D | D **ACTIVATE** | **YES — RULE FIRES.** Precondition satisfied AND raw call ACTIVATE → D overridden ACTIVATE → DO-NOT-ACTIVATE |

**One override fired this month: Strategy D** (`inflation_trend = reaccelerating AND policy_stance = hawkish`). This is the reconciliation architecture doing exactly its job — the growth re-firm genuinely lifted D's raw fundamental case to ACTIVATE, and the mechanical rule caught the reflation / hawkish-inflation discount-rate compression that the raw reasoning would otherwise let through. Logged for the monthly-review record per Strategy.md "Contradictions logged for monthly review": here the raw reasoning and the mechanical rule do NOT converge (raw ACTIVATE vs rule DNA), so this is a genuine reconciliation contradiction, resolved in favor of DO-NOT-ACTIVATE per the rule. No other rule fired.

---

## Divergence flags (post-reconciliation, per-strategy)

| Strategy | Technical | Fundamental (post-reconciliation) | Divergence | Downstream action (M4) |
|----------|-----------|-----------------------------------|------------|------------------------|
| A | DO-NOT-ACTIVATE | DO-NOT-ACTIVATE | NO | Confirm A DO-NOT-ACTIVATE (UNCHANGED) via `STRATEGY_ACTIVATION`; A queue in `Watchlist.md` remains queued (no router flip); no divergence review |
| B | ACTIVATE | ACTIVATE | NO | Confirm B ACTIVATE (UNCHANGED) via `STRATEGY_ACTIVATION`; no divergence review |
| C | ACTIVATE | DO-NOT-ACTIVATE | YES | Queue `divergence-review` (C) to `events.queue_events` (`PENDING_REVIEW`); prior cycle resolved HYBRID ACTIVATE (FOMC-only) — re-run for June regime; existing HYBRID state remains operative until the review completes |
| D | ACTIVATE | DO-NOT-ACTIVATE (post-override) | YES | Queue `divergence-review` (D); the divergence is driven by the reconciliation override, NOT by a fundamental flip (raw call flipped to ACTIVATE, override returns it to DNA — no net final flip); existing D positions (RTX, DIS) run to thesis-invalidation per router-deactivation-does-not-force-exits; new D entries blocked pending review; prior review outcome was ACTIVATE (flip-to-DNA rejected) |
| E | ACTIVATE | DO-NOT-ACTIVATE | YES | Queue `divergence-review` (E); prior cycle resolved ACTIVATE (substantive; execution-feasibility-deferred) — re-run for June regime; existing ACTIVATE state remains operative until the review completes |

Three divergences for M4 to queue as `divergence-review` entries (`events.queue_events`, queue `PENDING_REVIEW`): **C, D, E** — all same-direction (Tech ACTIVATE / Fund DO-NOT-ACTIVATE) as the prior cycle. No new-direction divergence was created this month (D's May flip-to-DNA fundamental is now delivered by the reconciliation override rather than the raw call, but the post-reconciliation divergence direction is unchanged). B and A agree (no review).

---

## Routine-end notes

- Per the Strategy.md immutable output format: Activation call / Reasoning / Reconciliation override applied / Technical signal / Divergence populated for all five strategies.
- No router state changes are applied by this routine. M4 (Monthly Action Conversion) reads this PART 2 verbatim and (a) confirms the no-divergence agreements (B ACTIVATE; A DO-NOT-ACTIVATE) via `STRATEGY_ACTIVATION`, (b) queues divergence-reviews for C / D / E to `events.queue_events` (`PENDING_REVIEW`), (c) processes Strategy-A queue-drain triggers (A remains DO-NOT-ACTIVATE → no drain), and (d) carries the existing D / E / C final states (all currently ACTIVATE / ACTIVATE / HYBRID) as operative until each divergence review completes.
- Read-scope discipline confirmed: no macro / policy / earnings / geopolitical source for June 2026 was consulted by this routine; the regime view is exactly M1a's `FUNDAMENTAL_AXIS` scoring.

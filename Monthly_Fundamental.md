2026-10

# Monthly Fundamental — Strategy Mapping and Activation Calls (M1b)

Routine: M1b strategy-mapping. Coverage period: regime scoring is the **September 2026** M1a output (`events.regime_events` scope `FUNDAMENTAL_AXIS`, `as_of_date = 2026-10-01`). Compiled 2026-10-02 (America/Denver), the second trading day of October.

Cycle lineage: the scheduled 2026-10-01 M1b fire HALTED at its dependency gate because M1a's 2026-10-01 trigger never created a session (`ops.run_log` M1b 2026-10-01 `halted`; `missing_dependency` critical `f14d020b`). M1a then completed as a catch-up on 2026-10-02 (marker 2026-10, `as_of_date` 2026-10-01). This run is M1b's catch-up for the same monthly period: `ops.sp_assert_deps('M1b', ['M1a'], 2026-10-02)` passed on that same-period completion. The prior M1b cycle ran 2026-09-01 against the August regime. One cycle, no gap. `state.routine_catchup_window` = 30.74 days, cadence-normal for a monthly routine (fallback 31 days), so there are no widened-window sub-sections and no `CATCHUP` token.

Inputs read for this routine (per M1b read-scope discipline):

- `events.regime_events` scope `FUNDAMENTAL_AXIS` (`as_of_date = 2026-10-01`, plus the 2026-09-01 rows for the month-over-month comparison) — M1a's strategy-blind regime scoring, the ONLY regime input.
- `strategy/02_regime_router.md` + `strategy/03_strategy_a.md`–`07_strategy_e.md` (per-strategy activation rules, fundamental questions, reconciliation rules, the immutable output format) and `strategy/01_shared_regime_vocabulary.md`, read via the slice map rather than `Strategy.md` whole. None of the reconciliation rules, per-strategy technical rules, fundamental questions or the output format has changed since the 2026-09-01 run. The only router-adjacent change is Rev 48 (`4c588c9`, 2026-09-05), which moved the frozen vocabulary to `disinflating` / `risk-on · neutral · stressed` / `none · latent · acute`.
- `events.regime_events` scope `TECHNICAL_SIGNAL` (`as_of_date = 2026-10-01`) — for divergence flagging only.
- `events.regime_events` scope `STRATEGY_ACTIVATION` (prior-call lookup), `state.strategy_roster` (roster enumeration), `state.current_positions` + `state.open_queue` (operational context), and `events.decision_log` (the `div-*-202608-1` adjudications and `otr-router-shock-override-2026`).

Inputs explicitly NOT read for scoring (architectural blinding per Strategy.md "Two-routine blinded scoring"): `events.macro_series`, `events.macro_fred`, and any other macro / Fed / earnings / geopolitical / policy source for September 2026. Every `events.regime_events` read used an explicit `scope = …` predicate rather than the unfiltered `state.current_regime` view.

**Disclosure.** During the dependency pre-flight this session read M1a's own 2026-10-02 `ops.run_log` completion note. That note restates figures M1a also wrote into its `FUNDAMENTAL_AXIS` rationales. Nothing from it was used below beyond what those rationales already carry, and every figure in this file is quoted from `events.regime_events`.

`fallback_suppression = FALSE`: M1a's integrative row records that all five primary categories were retrieved. Absent inputs were recorded rather than substituted. The full mapping runs and divergence flags are computed.

---

## PART 1 — Echo of M1a regime scoring (September 2026)

The five axis assignments, reproduced from `events.regime_events` scope `FUNDAMENTAL_AXIS`, `as_of_date = 2026-10-01`. This is the only regime context downstream consumers and the divergence-review attacker receive.

**Provenance (State-provenance rule): these are M1a's ASSERTIONS, echoed — not M1b measurements.** M1b is blinded from M1a's sources and can only check internal arithmetic. It did, and every check passes:

- **Rates.** 2Y 4.34 → 4.88 and 10Y 4.75 → 5.29 are both +54bp against the August rows, so the curve is unchanged at +0.41.
- **VIX.** 14.92 → 16.34.
- **Brent triplet.** Elevation 108.75 − 87.20 = 21.55. Midpoint 97.975. Retracement is (108.75 − 98.03) / 21.55 = 49.7% on the stored series and (108.75 − 103.50) / 21.55 = 24.4% on the like-for-like contract.
- **Quiet-session count.** 13 quiet sessions after 09-11 within the 09-10..09-30 window of 15.

All five tokens are in the Rev 48 frozen vocabulary.

| Axis | Assignment | Move vs prior month |
|------|------------|---------------------|
| `growth_momentum` | **stable** | **FLIP** from `decelerating` |
| `inflation_trend` | **stable** | **FLIP** from `disinflating` |
| `policy_stance` | **hawkish** | UNCHANGED (from debating a hike to delivering one) |
| `risk_sentiment` | **neutral** | **FLIP** from `risk-on` |
| `shock_overlay` | **acute** | UNCHANGED |

**`growth_momentum` = stable (FLIP).** August payrolls rose 162k, and June and July were revised up a net 55k (three-month average 71k). Unemployment held at 4.1% while participation rose to 61.6%. August retail sales gained 1.2% after a revised −0.5% July, and the Q2 GDP third estimate was revised up 0.7pp to 2.2% SAAR. Corroboration:

- The Beige Book reports modest growth, with activity up in 10 districts and unchanged in 2.
- ISM manufacturing and services read 54.6 and 55.4.
- The FOMC raised its 2026 growth median to 2.3% and cut its unemployment median to 4.1%.
- FactSet's Q3 EPS growth estimate rose to 29.1%.

Acceleration is not established. The three-month payroll pace is modest, industrial production was flat, ISM manufacturing eased from 55.6, the ISM figures are unverified, and retail ex-autos and the control group are absent.

**`inflation_trend` = stable (FLIP).** The 12-month rates were flat to lower: CPI 3.4% unchanged, core CPI 2.4% from 2.5%, and average hourly earnings 3.1% from 3.2%. But the August monthly prints firmed:

- CPI +0.4% from +0.1%.
- Core CPI +0.3% from +0.2%.
- PPI final demand +0.4% from 0.0%, with its 12-month rate back to 5.4% from 4.7%.
- PCE +0.3% from +0.2%.

Last month's disinflation therefore did not continue. The FOMC now says "Inflation remains elevated", and its PCE and core PCE medians rose to 3.7% and 3.4%. September's Brent surge has not yet passed through to reported prices, and M1a deliberately did not score it on this axis.

**`policy_stance` = hawkish.** On 09-16 the FOMC raised the target range 25bp to 3.75–4.00% by a unanimous 12–0 vote, after July's 9–3 hold with three dissents for a hike. It also:

- tightened its inflation language;
- lifted the 2026 and 2027 SEP medians to 4.1%, with 16 of 18 end-2026 dots above the new midpoint;
- had the Chair say the convergence condition had "not been satisfied", while Barr argued twice for further adjustment.

The 2-year yield rose 54bp to 4.88%. The CME FedWatch path was not retrieved, and M1a records it as absent rather than inferring it.

**`risk_sentiment` = neutral (FLIP).** The market cooled from risk-on:

- HY OAS widened 49bp to 3.12% and was still widening at month-end.
- VIX rose to 16.34, back above the 15 line.
- The S&P 500 slipped 0.45%, while the Russell 2000 fell 5.40% against a +3.23% Nasdaq-100. M1a calls this narrow, rate-sensitive leadership.
- 10-year yields jumped 54bp to 5.29%.

Stressed is ruled out. VIX sits inside its NORMAL band, IG OAS widened only 4bp to 0.84%, the forward P/E of 19.2 is below its five-year average of 19.8, and gold fell 6.58% instead of drawing haven buying. M1a gives the 42.0% breadth reading little weight because it comes from a single provider.

**`shock_overlay` = acute.** The most recent qualifying event was on 2026-09-11: drone strikes on Saudi Arabia's export pipeline halted Red Sea loadings averaging 3.9 mb/d. They followed the 09-09 Gulf shipping attacks. The 09-20 rerouting and the 09-27 Yanbu resumption count as flows recovering, not as qualifying events.

The Brent triplet on the stored BZUSD series is baseline 87.20, peak 108.75 and current 98.03, where the current figure is the December contract after the 09-29 roll (like-for-like November 103.50). Both de-escalation legs fail:

- **Quiet sessions:** 13 of the 15 required.
- **Retracement:** below 50% on both contract bases (49.7% stored, 24.4% like-for-like).

So no downgrade is triggered, and both of the rubric's routes into acute are met. On transmission, Brent held well above baseline (EIA spot 113.96 on 09-29). Sovereign spreads could not be measured. FX moves were attributed to yields and rate differentials rather than to the shock channel.

**M1a's integrative summary (verbatim).** "September 2026: stable growth + stable inflation + hawkish policy + neutral risk sentiment + acute shock overlay. Three axes moved: growth firmed back from decelerating as August payrolls, retail sales and an upward Q2 GDP revision reversed July's weakness; inflation stepped from disinflating to stable as monthly prints firmed across CPI, PPI and PCE while 12-month rates held flat to lower; and risk sentiment cooled from risk-on to neutral as high-yield spreads widened 49bp, small caps fell 5.4% and 10-year yields rose 54bp — all while a unanimous Fed hike met a renewed Gulf oil shock that has retraced just under half its elevation on the stored series and about a quarter like-for-like."

---

## PART 2 — Activation calls and divergence flags

### Technical signal states used for divergence flagging

These come from `events.regime_events` scope `TECHNICAL_SIGNAL`, `as_of_date = 2026-10-01`, the most recent completed session. **Freshness was verified before computing flags:** the rows are 1 calendar day old, all four vocabulary keys are present, and all four were computed mechanically. Today's (2026-10-02) rows are not written until this evening, so 2026-10-01 is correctly the operative reading.

| Indicator | State | Measurement | As of |
|-----------|-------|-------------|-------|
| SPY Trend State | **UP** | close 763.99 > 50d SMA 763.073 > 200d SMA 720.026 (both windows full). Knife-edge: the close is only 0.917 above the 50d, and the state read NEUTRAL on 09-30. | 2026-10-01 |
| VIX Regime | **NORMAL** | `^VIX` 16.39; LOW → NORMAL on 2026-09-28 | 2026-10-01 |
| Yield Curve Sustained Inversion Flag | **NOT-SUSTAINED** | 10Y 5.24 > 2Y 4.78, curve NORMAL (+0.46pp) | 2026-10-01 |
| Equity Breadth State | **WEAK** | 41.15% of S&P 500 above own 200d < 50% (D1 `TECHNICAL_INPUT` `EQUITY_BREADTH_PCT`, Barchart `$S5TH`, same-day observation). Was HEALTHY at 66.2% on 2026-08-31. | 2026-10-01 |

**Breadth is the change this month.** HEALTHY → WEAK turns the technical call for **A** (which requires Breadth HEALTHY) and **E** (which requires Breadth HEALTHY) from ACTIVATE to **DO-NOT-ACTIVATE**. B, C and D are unaffected and stay ACTIVATE.

**Robustness to the SPY knife-edge:** none of the five technical calls depends on SPY being UP rather than NEUTRAL. B and C test `≠ DOWN`, D accepts `UP OR NEUTRAL`, and A and E already fail on breadth. A one-session flip back to NEUTRAL would change no flag. A flip to DOWN would need the 50d SMA to cross below the 200d, which is about 43 points away.

### Prior-call baseline for the FLIP/UNCHANGED comparison

Two lineages are tracked. The FLIP tag below is on the **fundamental, post-reconciliation** lineage, which is what M1b produces.

- **(i) Prior M1b fundamental call** — from the 2026-09-01 run (August regime, marker `2026-09`).
- **(ii) Prior final activation state** — `events.regime_events` scope `STRATEGY_ACTIVATION`, `as_of_date = 2026-09-03`, written by the five orchestrators that resolved `div-*-202608-1`.

| Strategy | Prior M1b fundamental (post-recon, Aug regime) | Prior M1b RAW call | Prior final activation state (post-review, 2026-09-03) |
|----------|------------------------------------------------|--------------------|--------------------------------------------------------|
| A | DO-NOT-ACTIVATE | DO-NOT-ACTIVATE | DO-NOT-ACTIVATE — `div-A-202608-1`, MIXED, unchanged |
| B | DO-NOT-ACTIVATE (override-manufactured) | ACTIVATE | DO-NOT-ACTIVATE — `div-B-202608-1`, DIVERGENT, override upheld |
| C | DO-NOT-ACTIVATE | DO-NOT-ACTIVATE | HYBRID ACTIVATE (FOMC-only) — `div-C-202608-1`, MIXED, CONTINUE HYBRID |
| D | DO-NOT-ACTIVATE (raw) | DO-NOT-ACTIVATE | DO-NOT-ACTIVATE — `div-D-202608-1`, DIVERGENT, unchanged |
| E | DO-NOT-ACTIVATE (override-manufactured) | ACTIVATE | DO-NOT-ACTIVATE — `div-E-202608-1`, DIVERGENT, **state change from ACTIVATE** |

All five `202608` reviews are RESOLVED, and `state.open_queue` carries no open `divergence-review` item. Separately, `otr-router-shock-override-2026` was adjudicated **HOLD** on 2026-09-09 (`events.decision_log` `14f51a6f`): the acute-shock override stands as written — uniform, one-directional and unscaled.

### Strategy A:
  Activation call: DO-NOT-ACTIVATE
  Reasoning: M1a's September scoring is `stable growth + stable inflation + hawkish policy + neutral risk + acute shock`. A's question asks whether individual-stock catalysts are being rewarded, or whether macro factors overwhelm idiosyncratic narrative. Two facts favour activation. Growth firmed (payrolls +162k, Q2 revised up to 2.2%), and M1a records Q3 EPS growth estimates rising to 29.1%, with 72 companies giving positive guidance. That is a richer catalyst supply than last month. It does not carry, because M1a's own description of how the tape priced that information is macro-factor dominance. The Russell 2000 fell 5.40% against a +3.23% Nasdaq-100, which M1a calls "narrow, rate-sensitive leadership", while 10-year yields jumped 54bp. Returns sorted on duration and size, not on company news. A Fed that delivered a unanimous hike, with 16 of 18 dots above the new midpoint, makes the rate path the dominant common factor for A's 1–12 month hold. `shock_overlay = acute`, with Brent 21.55 above baseline at peak and under half retraced, adds a second common factor. Raw call: DO-NOT-ACTIVATE. The earnings-revision evidence is real and is the thing to re-test once the rate shock settles.
  Reconciliation override applied: no. `growth_momentum = decelerating AND policy_stance = hawkish → A` is now precondition-FAILED for the first time in three months, because growth is `stable`, so that latent A-specific rule has DISARMED. `shock_overlay = acute → any` is precondition-satisfied but finds no ACTIVATE. `risk_sentiment = stressed` fails (`neutral`). A's DNA now rests on raw reasoning plus the universal acute rule only.
  Technical signal for this strategy: DO-NOT-ACTIVATE (rule: SPY Trend State = UP AND Equity Breadth State = HEALTHY → UP passes; WEAK at 41.15% FAILS)
  Divergence: **NO** (Tech DO-NOT-ACTIVATE / Fund DO-NOT-ACTIVATE)
  Prior call comparison: **UNCHANGED** (prior M1b fundamental: DO-NOT-ACTIVATE; prior raw: DO-NOT-ACTIVATE). A's `Watchlist.md` queue stays queued, because its drain trigger is a router ACTIVATE.

### Strategy B:
  Activation call: ACTIVATE  →  **post-reconciliation DO-NOT-ACTIVATE** (override fires; see below)
  Reasoning: B's question asks whether event reactions show measurable mean reversion at 2–8 week horizons, or whether reactions are fully informative. This month's scoring argues more clearly for mean reversion than last month's. Last month the counter-case was a calm, earnings-led tape with the multiple flat ("information priced without overshoot"). That premise is gone. Risk sentiment cooled to neutral as HY OAS widened 49bp and was still widening at month-end, and the cross-section moved violently: Russell 2000 −5.40% against Nasdaq-100 +3.23%, an 8.6pp gap in a month when the index moved −0.45%. A rate shock of +54bp on both the 2Y and the 10Y is exactly the kind of common-factor impulse that pushes single-name event reactions past their information content, which is the overshoot B fades. Vol is NORMAL at 16.34, far from the VIX > 25 exclusion, and credit stress is not systemic (IG +4bp only). The risk is that the rate path keeps trending rather than reverting, so overshoots extend instead of mean-reverting. That is a sizing and selection concern inside B's own rules, not a regime-level refutation. Raw call: ACTIVATE.
  Reconciliation override applied: **yes** — rule `shock_overlay = acute → override ACTIVATE → DO-NOT-ACTIVATE for ANY strategy`. The precondition is satisfied (`acute`: most recent qualifying event 2026-09-11, quiet-session leg at 13/15, retracement leg failing at 49.7% / 24.4%) AND B's raw call is ACTIVATE, so the rule **FIRES**. Post-reconciliation call: DO-NOT-ACTIVATE. This is the third consecutive month the rule has fired on B. The rule's design was adjudicated HOLD on 2026-09-09 (`otr-router-shock-override-2026`), so this firing is mechanical application of an upheld rule.
  Technical signal for this strategy: ACTIVATE (rule: SPY Trend State ≠ DOWN AND VIX Regime ≠ HIGH → UP ≠ DOWN passes; NORMAL ≠ HIGH passes)
  Divergence: **YES** (Tech ACTIVATE / Fund post-reconciliation DO-NOT-ACTIVATE)
  Prior call comparison: **UNCHANGED** post-reconciliation (DO-NOT-ACTIVATE → DO-NOT-ACTIVATE). The raw call is also unchanged (ACTIVATE), and its basis is now stronger: dispersion under a rate shock rather than internal dispersion beneath a calm surface. No router flip for M4.

### Strategy C:
  Activation call: DO-NOT-ACTIVATE
  Reasoning: C's question asks whether the event-trading environment is functional, or whether the regime is dominated by macro shocks that override individual-catalyst dynamics. M1a's scoring answers it directly, and on two fronts this month rather than one. `shock_overlay = acute` is a scored finding of an active oil shock: pipeline strikes halting 3.9 mb/d of Red Sea loadings, and Brent peaking 21.55 above its 60-session baseline. `policy_stance = hawkish` is no longer a debate but a delivered, unanimous hike with SEP medians lifted to 4.1%, and 2Y and 10Y yields both rose 54bp. Both re-price implied-vol surfaces through the rate path and the energy path rather than through per-name catalysts. Per-name event dispersion then compresses toward common factors, which degrades the clean idiosyncratic options pricing C's directional theses need. The growth firming does not change this: it raises catalyst supply but not the share of vol explained by single-name events. Per the immutable format the call is binary: DO-NOT-ACTIVATE. The FOMC-only carve-out is a review-resolved scope decomposition, not an M1b output. It remains in force, and it has live work: `thesis-FOMC-C-20261020` (due 2026-10-20, for the 2026-10-28 FOMC, no SEP).
  Reconciliation override applied: no. No C-specific rule exists. The universal `acute` rule is precondition-satisfied but finds no ACTIVATE.
  Technical signal for this strategy: ACTIVATE (rule: SPY Trend State ≠ DOWN → UP passes)
  Divergence: **YES** (Tech ACTIVATE / Fund DO-NOT-ACTIVATE)
  Prior call comparison: **UNCHANGED** (prior M1b fundamental: DO-NOT-ACTIVATE; prior raw: DO-NOT-ACTIVATE). The HYBRID ACTIVATE (FOMC-only) final state is not re-issued here. Strategy.md reserves any widening to a separate scope-widening adjudication, and the 2026-09-03 orchestrator found that path procedurally unreachable for now.

### Strategy D:
  Activation call: ACTIVATE  →  **post-reconciliation DO-NOT-ACTIVATE** (override fires; see below)
  Reasoning: D's question asks whether multi-year equity theses can plausibly play out, or whether structural headwinds (recessionary signals, regulatory shifts, secular theme disruption) argue against new long-horizon positions. Last month's raw DNA rested on recessionary signals: the cycle's first negative payroll print, −103k of revisions, falling retail sales, and a central bank tightening into decelerating demand. **That ground has reversed in M1a's scoring.** Growth flipped to `stable`: payrolls +162k with net upward revisions, retail sales +1.2%, Q2 GDP revised up to 2.2%, and FOMC growth and unemployment medians improved. The policy-error configuration ("tightening into decelerating demand") no longer holds, because demand is not decelerating. The counter-case is serious and stated plainly. The Fed delivered a hike with more priced, and 10-year yields rose 54bp to 5.29% — a discount-rate headwind at exactly D's horizon. Inflation stopped disinflating. Risk sentiment cooled from risk-on to `neutral`, though M1a explicitly rules out `stressed` (IG +4bp, forward P/E 19.2 below its five-year average). Those are cyclical valuation headwinds, not the structural, thesis-breaking class D's question names, and D's multi-year horizon is built to sit through a rate cycle. Raw call: ACTIVATE, marginal, and produced by the growth reversal rather than a softer reading of the same evidence.
  Reconciliation override applied: **yes** — rule `shock_overlay = acute → override ACTIVATE → DO-NOT-ACTIVATE for ANY strategy`. Precondition satisfied AND D's raw call is ACTIVATE, so the rule **FIRES**. Post-reconciliation call: DO-NOT-ACTIVATE. D's own rule (`inflation_trend = reaccelerating AND policy_stance = hawkish`) is precondition-FAILED for the third consecutive month (inflation `stable`), and `risk_sentiment = stressed` fails (`neutral`). **D's DNA is override-manufactured for the first time since the 2026-07 M1b cycle**, which mirrors E's position last month.
  Technical signal for this strategy: ACTIVATE (rule: (SPY Trend State = UP OR NEUTRAL) AND Yield Curve Sustained Inversion Flag = NOT-SUSTAINED → UP passes; NOT-SUSTAINED passes, 10Y 5.24 > 2Y 4.78)
  Divergence: **YES** (Tech ACTIVATE / Fund post-reconciliation DO-NOT-ACTIVATE)
  Prior call comparison: **UNCHANGED** post-reconciliation (DO-NOT-ACTIVATE → DO-NOT-ACTIVATE), so there is no router flip for M4. But the **raw call FLIPPED DNA → ACTIVATE**, and the basis inverted from raw to override-manufactured. Router deactivation does not force exits: the twelve open D lots (AMZN, DIS, GEV, GOOGL, ISRG, RTX, TSM, UBER) run to their normal thesis-invalidation or exit conditions. The constraint applies to NEW D entries only.

### Strategy E:
  Activation call: DO-NOT-ACTIVATE
  Reasoning: E's question asks whether the sector-rotation environment is conducive to within-industry-group mean reversion, or whether macro forces dominate intra-sector dynamics. Last month's raw ACTIVATE rested on one specific finding: the style-rotation leg was ABSENT, because August's advance was earnings-led with the multiple flat, so dispersion was company-level. **September's scoring removes that premise.** M1a records narrow, rate-sensitive leadership — Russell 2000 −5.40% against Nasdaq-100 +3.23% — on a +54bp move in 10-year yields. That is a single duration and size factor sorting the cross-section, and it cuts within industry groups as well as across them. Long-duration versus short-duration names and small versus large inside the same group move apart for factor reasons that E's pair spreads would read as divergence to fade. E's beta-adjustment clause absorbs market beta, but not a rate-duration factor of this size moving within groups. The oil shock (Brent peak 21.55 above baseline, under half retraced) adds a second within-group common factor through energy sensitivity. The 2026-09-03 orchestrator already upheld DNA for E. This month's raw reasoning independently reaches the same answer on new evidence and does not lean on the override. Raw call: DO-NOT-ACTIVATE.
  Reconciliation override applied: no. The universal `acute` rule is precondition-satisfied but finds no ACTIVATE. E's DNA is raw this month, where last month it was override-manufactured.
  Technical signal for this strategy: DO-NOT-ACTIVATE (rule: SPY Trend State ≠ DOWN AND VIX Regime ≠ HIGH AND Breadth State = HEALTHY → UP ≠ DOWN passes; NORMAL ≠ HIGH passes; WEAK at 41.15% FAILS)
  Divergence: **NO** (Tech DO-NOT-ACTIVATE / Fund DO-NOT-ACTIVATE)
  Prior call comparison: **UNCHANGED** post-reconciliation (DO-NOT-ACTIVATE → DO-NOT-ACTIVATE). The raw call FLIPPED ACTIVATE → DNA, so M1b's raw reasoning now agrees with the standing final state. No router flip for M4.

---

## Reconciliation overrides applied

These were checked mechanically AFTER step 1, per Strategy.md's M1a/M1b reconciliation rules (`Strategy.md`:131–134; slice `02_regime_router.md`:26–29). A rule fires only when the regime precondition holds AND M1b's raw call is ACTIVATE. Overrides are one-directional: ACTIVATE → DO-NOT-ACTIVATE only.

| Rule | M1a September axis values | Strategy targeted | M1b raw call | Override applied? |
|------|---------------------------|-------------------|--------------|-------------------|
| `shock_overlay = acute` → override any ACTIVATE → DNA | shock_overlay = **`acute`** ✔ | ALL (A,B,C,D,E) | A DNA / **B ACTIVATE** / C DNA / **D ACTIVATE** / E DNA | **YES — FIRES on B and on D.** Third consecutive firing on B; first firing on D since the 2026-07 M1b cycle. Inert on A/C/E (already DNA). Rule design upheld HOLD 2026-09-09. |
| `risk_sentiment = stressed` → override A or D ACTIVATE → DNA | risk_sentiment = `neutral` ✘ | A, D | A DNA / D ACTIVATE | NO — precondition fails. `stressed` remains in-vocabulary after Rev 48 and is armed, but it has never been emitted. M1a explicitly ruled it out this month. |
| `growth_momentum = decelerating AND policy_stance = hawkish` → override A ACTIVATE → DNA | growth `stable` ✘, policy `hawkish` ✔ | A | A DNA | NO — precondition **FAILED for the first time in three months**. This A-specific rule has disarmed. |
| `inflation_trend = reaccelerating AND policy_stance = hawkish` → override D ACTIVATE → DNA | inflation `stable` ✘, policy `hawkish` ✔ | D | D ACTIVATE | NO — precondition FAILED for the third consecutive month. Inflation moved `disinflating` → `stable`, toward but not at `reaccelerating`. |

**Two overrides fired, on B and D, both from the universal `acute` rule.** Both are genuine reconciliation contradictions (raw ACTIVATE vs rule DNA) and are logged here for the monthly review. Compared with last month, the set changed: last month the rule fired on B and E, and this month on B and D. E's raw call returned to DNA on the rate-factor evidence, and D's raw call turned ACTIVATE on the growth reversal.

**The precondition picture changed for the first time in three months.** The A growth/policy rule disarmed with the growth flip. The D inflation/policy rule moved one step closer: `stable` is adjacent to `reaccelerating`, and M1a flags that Brent pass-through is still pending. `acute` stayed armed.

**The `acute` override is now the binding constraint on the whole roster. Its de-escalation status is a knife-edge that M4 must carry.** M1a's own rubric numbers put both legs close to the threshold:

- **Quiet-session leg** at 13 of 15. It completes after two more sessions with no qualifying event.
- **Retracement leg** at 49.7% on the stored series, against a 50% threshold. That is $0.055 of Brent.

The like-for-like November basis reads only 24.4% retraced, and the de-escalation test requires both legs. If an out-of-cycle M1R re-score grades the overlay `acute → latent` before the November cycle, the universal rule stops firing. **B's and D's raw ACTIVATE calls would then stand unopposed.** Combined with their technical ACTIVATE, that is a de-facto router flip for two strategies that neither this file nor M4 would see until the next M1b. This is flagged, not actioned: re-scoring belongs to M1a and M1R, and acting on a re-score belongs to the routines that consume it.

**Net effect: every roster strategy is fundamentally DO-NOT-ACTIVATE for the third consecutive month.** Three are on raw reasoning (A, C, E) and two are by override (B, D).

---

## Divergence flags (post-reconciliation, per-strategy)

| Strategy | Technical | Fundamental (post-reconciliation) | Divergence | Downstream action (M4) |
|----------|-----------|-----------------------------------|------------|------------------------|
| A | DO-NOT-ACTIVATE | DO-NOT-ACTIVATE | NO | **No review.** The planes agree, and the prior final state (DNA) is confirmed. The agreement comes from breadth turning WEAK. A's `Watchlist.md` queue stays queued (no drain). |
| B | ACTIVATE | DO-NOT-ACTIVATE (post-override) | **YES** | Queue `divergence-review` (B). The prior final state DNA stays operative. Tell the attacker that the raw call is ACTIVATE on a stronger basis than last month, and that the DNA is produced entirely by the `acute` override for the third month running. The override's DESIGN was adjudicated HOLD on 2026-09-09 (`otr-router-shock-override-2026`), so the review is about whether the rule was validly applied this month — chiefly the de-escalation knife-edge above — not about re-litigating its design. |
| C | ACTIVATE | DO-NOT-ACTIVATE | **YES** | Queue `divergence-review` (C). The prior cycle resolved CONTINUE HYBRID ACTIVATE (FOMC-only, MIXED), and that HYBRID state stays operative. Live carve-out work: `thesis-FOMC-C-20261020` (PENDING_ANALYSIS, due 2026-10-20) for the 2026-10-28 FOMC. Note for the review: the hiking cycle has now started, which changes what an FOMC event-vol thesis is pricing. |
| D | ACTIVATE | DO-NOT-ACTIVATE (post-override) | **YES** | Queue `divergence-review` (D). The prior final state DNA stays operative, and the twelve open D lots run to normal exits either way. **This is the consequential review this cycle.** M1b's raw call flipped to ACTIVATE on the growth reversal, so D's DNA is now override-manufactured. That is the same configuration that produced E's state change last cycle, and the ground type the `div-D-202607-1` review turned on. Both Tier-1 findings adopted on 2026-09-03 (the risk-on flip was absent from D's reasoning) are addressed: risk sentiment is explicitly weighed in this month's D reasoning. |
| E | DO-NOT-ACTIVATE | DO-NOT-ACTIVATE | NO | **No review.** The planes agree, and the prior final state (DNA, set by `div-E-202608-1`) is confirmed. M1b's raw call now independently agrees with it on new evidence (the rate-duration factor), rather than via the override. |

**THREE divergences for M4 to queue as `divergence-review` entries (`events.queue_events`, queue `PENDING_REVIEW`): B, C, D.** All three run in the same direction (Tech ACTIVATE / Fund DO-NOT-ACTIVATE). **Two agreements (A, E) for M4 to confirm mechanically.** This is down from five divergences in each of the prior two months. The drop comes entirely from breadth turning WEAK on the technical plane, which brought A's and E's technical calls into line with the fundamental DNA.

**Common-cause warning for M4 and for the reviews.** These three divergences are not independent. Two of them, B and D, have the same proximate driver: the universal `acute` override sitting on a de-escalation knife-edge. Their reviews will therefore ask the same question twice — does the override validly bind this month? — and M4 must NOT read two concurrent DIVERGENT verdicts on B and D as two independent confirmations. C's DNA is raw and rests on the same two macro facts (the oil shock and the delivered hike), so it is correlated with the others too, though less directly. Per-review theater checks will not catch the correlation, because each orchestrator sees only its own strategy. Carry this note into every queue entry.

**What is at stake this cycle.** No operative state is a live unqualified ACTIVATE: A, B, D and E are DNA, and C is HYBRID FOMC-only. So no review this round can deactivate anything. The practical question is the reverse of last cycle's: whether a strategy whose raw fundamental case now supports activation (B, and newly D) should stay held off by an override whose triggering condition M1a's own numbers place within a hair of de-escalation.

---

## Routine-end notes

- **Output format.** Per the Strategy.md immutable output format, Activation call / Reasoning / Reconciliation override applied / Technical signal / Divergence are populated for all five roster strategies. A–E were enumerated from `state.strategy_roster`: all five are `ADOPTED` and `is_active`, and F, G and H are `REJECTED` and receive no call. Each reasoning block is within the 300-word cap and references only M1a's regime scoring.
- **No router state changes are applied by this routine.** M1b writes no `events.regime_events` `STRATEGY_ACTIVATION` rows. M4 reads this PART 2 verbatim and does three things:
  - (a) queues divergence-reviews for B, C and D to `events.queue_events` (`PENDING_REVIEW`) and confirms the A and E agreements mechanically;
  - (b) processes Strategy-A queue-drain triggers (A's fundamental call remains DNA, so there is no drain);
  - (c) carries the existing final states as operative until each review completes: A DNA / B DNA / C HYBRID ACTIVATE FOMC-only / D DNA / E DNA.
  M4's own 2026-10-01 run halted on this M1b dependency (`missing_dependency` `f5c0d8a1`). That M4 fire is in the never-refire set, so its re-run comes from OPS0 STEP 2b's manual-rerun notice or M4's next regular fire. This is not M1b's to trigger.
- **Marker:** the first line is `2026-10`, the CURRENT month, per `Claude_Task_Plan.md` §"File-write conventions" (`M1b | Monthly_Fundamental.md | current month`). `scripts/check_cadence_marker.py` enforces it.
- **Technical-plane freshness verified** before the flags were computed: all four keys carry `as_of_date = 2026-10-01`, 1 day old. Breadth is genuinely measured (D1's same-day `$S5TH` capture at 41.15%), and its HEALTHY → WEAK move is what reduced the divergence count from five to three.
- **The vocabulary finding from the 2026-09-01 run is closed.** That run's `regime_axis_vocabulary_drift` info alert (`0c421a12`) was resolved on 2026-09-13. Rev 48 (2026-09-05) moved the frozen text to the tokens M1a writes, and all five September tokens are in-vocabulary. The one residual point that Rev 48 itself names — `stressed` has never been emitted — is a property of four regimes that were never stressed, not a defect. M1a ruled it out on evidence again this month. Nothing is re-raised.
- **Read-scope discipline confirmed**, with the one disclosure at the top of this file: M1a's `ops.run_log` note was read during the pre-flight. No macro, policy, earnings or geopolitical source for September 2026 was consulted. The technical-plane values were read, not re-measured, and no market-data call was made.
- **Metered spend: ZERO.** Neither the orchestrator nor either sub-agent made a Tavily, `web_search`, `web_fetch`, FMP or HF call. Every fact came from BigQuery, repo files or the strategy slices, so no `ops.web_calls` rows are owed.

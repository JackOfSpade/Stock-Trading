2026-05

# Monthly Fundamental — Strategy Mapping and Activation Calls (M1b)

Routine: M1b strategy-mapping. Coverage period: regime scoring is the May 2026 M1a output. Compiled 2026-06-01 (America/Denver).

Inputs read for this routine (per M1b read-scope discipline):
- `Monthly_Fundamental_RegimeScore.md` (M1a strategy-blind regime scoring — the ONLY regime input)
- `Strategy.md` (per-strategy activation rules, fundamental questions, reconciliation rules, immutable output format)
- `Regime_State.md` (current technical signals per the shared regime vocabulary — for divergence flagging only)
- `Decision_Log.md` (live) / `Operating_Protocols.md` / `Portfolio_Ledger.md` / `Watchlist.md` (prior-call lookup and operational context)

Inputs explicitly NOT read for this routine (architectural blinding per Strategy.md "Two-routine blinded scoring"): `Monthly_Macro_Data_2026-05.md`; any other macro / Fed / earnings / geopolitical / policy source for the May 2026 month. M1b's regime view is exactly M1a's regime-scoring file.

Fallback-suppression flag from M1a: `fallback_suppression = false` → proceed with per-strategy activation calls and divergence flags.

---

## PART 1 — Echo of M1a regime scoring (May 2026)

Reproduced verbatim from `Monthly_Fundamental_RegimeScore.md`. This is the only regime context for downstream consumers and for any divergence-review attacker.

- **growth_momentum: decelerating.** Q1 2026 GDP second estimate revised DOWN to +1.6% from +2.0% advance, with downward revisions concentrated in private inventory investment and services-side consumer spending — material softening of the rebound off shutdown-affected Q4 2025 (+0.5%). April retail sales decelerated to +0.5% MoM from March's revised +1.6%; ISM Services New Orders fell 7.1pp to 53.5 with headline Services PMI 53.6. Forward sentiment cratered: UMich Consumer Sentiment at record-low 44.8 (third consecutive monthly decline); Conference Board CCI 93.1. Q1 S&P 500 blended earnings growth +28.6% / 84% beat rate reflects prior-quarter activity and does not contradict directional softening in real-time activity data and consumer expectations.

- **inflation_trend: reaccelerating.** April CPI +3.8% headline YoY / +0.6% MoM SA with core +2.8% YoY / +0.4% MoM SA — largest core monthly print since January 2025, ~2× the February/March pace; acceleration concentrated in services (airfare +2.8% MoM, +20.7% YoY) and energy (+3.8% MoM); goods flat MoM. April PPI Final Demand +6.0% YoY (+1.4% MoM SA) — largest 12-month advance since +6.4% Dec 2022, sharply up from March's +4.0% YoY. UMich 1Y inflation expectations 4.8%; 5–10Y expectations 3.9%. Brent ~−19% MoM to ~$93 is a forward disinflationary signal not yet in May release data.

- **policy_stance: hawkish.** April 28–29 FOMC minutes documented broad hawkish drift: "many participants" preferred removing easing-bias language; majority noted "some policy tightening may be needed were inflation to continue running persistently above the Committee's 2% target." 8–4 April vote largest dissent count since 1992; three dissents specifically against retaining easing-bias language. Kevin Warsh Senate-confirmed May 13 (54–45) and sworn in May 22; fed-funds-path commentary repriced "later and shallower" through May. No FOMC meeting in May; target range 3.50–3.75%.

- **risk_sentiment: risk-on.** Unambiguous risk-asset signals: S&P 500 fresh ATHs (May 1 close 7,230; May 29 close 7,580; ~+4.25% monthly return); IG OAS ~77–80 bps near 25-year tights; HY OAS ~280–320 bps also tight; VIX decompressed to low-to-mid teens (15.32 May 29 close). Cross-asset reinforces: Brent −19% MoM on ceasefire-progress newsflow; DXY +1% MoM range-bound; 10Y UST ~4.45% with curve modestly steepening. Breadth caveats noted but did not redirect call: ~54% of S&P 500 above own 50-day SMA (moderate participation); UMich at record low (forward-quality concern but not yet expressed in risk-asset pricing or credit). "Stressed" excluded by credit/equity evidence; May moves one step beyond April's "neutral" toward risk-on.

- **shock_overlay: latent.** Iran war remained active through May (~3 months running) with Hormuz commercial traffic at ~4% of pre-crisis volume as of May 24, but kinetic phase did NOT escalate further: U.S.–Iran 60-day MOU and ceasefire-extension talks advanced through month-end; May 4–5 oil spike on ceasefire-wobble was reversed by month-end; Brent settled ~$93 (elevated vs ~$70s pre-war baseline but well off early-April ~$128 peak). Secondary domestic shock layer via tariff legal uncertainty continued (May 7 CIT ruling against §122 limited to three plaintiffs; May 12 Federal Circuit stay) but net practical impact on effective tariff rate (~11.8% per Yale Budget Lab) is muted while appeal proceeds. "None" excluded because active real-economy transmission persists (Hormuz at ~4%; tariff-driven cost pressure working through prices); "acute" excluded because kinetic phase paused, diplomatic track materially advanced, and equity/credit/oil all moved in shock-recovery direction.

**Integrative summary (strategy-blind, May 2026).** Decelerating growth + reaccelerating inflation + hawkish policy + risk-on sentiment + latent shock overlay — a stagflation-tilted activity backdrop running concurrent with strong risk-asset pricing as the geopolitical shock's kinetic phase recedes. Dominant cross-axis tension: asset-pricing rally (record S&P, 25-year-tight credit, low VIX, oil down ~19% MoM) vs. deteriorating fundamentals (Q1 GDP revised down to +1.6%; UMich at record low; CPI/PPI re-accelerating decisively; hawkish FOMC minutes plus new Chair). Risk-on signal is driven primarily by reported Q1 earnings momentum and ceasefire-progress relief, while activity, inflation, and policy axes are moving in the structurally adverse direction.

---

## PART 2 — Activation calls and divergence flags

Current technical signal states (from `Regime_State.md`, applied to each strategy's technical activation rule):

| Indicator | State |
|-----------|-------|
| SPY Trend State | NEUTRAL |
| VIX Regime | NORMAL |
| Yield Curve Sustained Inversion Flag | NOT-SUSTAINED |
| Equity Breadth State | HEALTHY |

Prior-month fundamental calls (M1 2026-04-23 inaugural cycle, per `Decision_Log.md` pointer to `Decision_Log_Archive_2026_Q2.md` "2026-04-23 M1 monthly fundamental analysis — first cycle"): A fundamental DO-NOT-ACTIVATE; B fundamental ACTIVATE; C fundamental DO-NOT-ACTIVATE; D fundamental ACTIVATE; E fundamental DO-NOT-ACTIVATE.

### Strategy A:
  Activation call: DO-NOT-ACTIVATE
  Reasoning: M1a regime scoring is `decelerating growth + reaccelerating inflation + hawkish policy + risk-on sentiment + latent shock`. A's fundamental question asks whether individual-stock catalysts are being rewarded by the market or whether macro factors dominate idiosyncratic narrative. The May regime is a textbook macro-dominated tape: Q1 GDP revision to +1.6% with UMich at a record low; April CPI core +2.8% YoY / +0.6% MoM SA and PPI +6.0% YoY (largest since Dec 2022); FOMC minutes drift hawkish with majority noting tightening may be needed; new Chair (Warsh) sworn in. The risk-on asset-pricing channel is concentrated narrative — Q1 earnings momentum, ceasefire relief, mega-cap leadership — not a broad cross-sectional reward for individual-stock catalysts (breadth at ~54% above 50-day = moderate, not broad). The dominant tension between adverse-fundamental and risk-on-pricing axes argues for whippy idiosyncratic catalyst reactions over the 1–12 month A horizon, dominated by macro-print volatility (next CPI, FOMC June 16–17, Brent path, tariff appeal). Late-cycle stagflation-tilt is structurally adverse for catalyst-driven longs whose payoff path requires the market to absorb the narrative rather than re-price on the next macro print. Fundamental DNA stands.
  Reconciliation override applied: no (call is already DO-NOT-ACTIVATE; the `growth_momentum=decelerating AND policy_stance=hawkish → A DNA` override would fire IF call were ACTIVATE, but does not apply mechanically since the override is directional only)
  Technical signal for this strategy: DO-NOT-ACTIVATE (rule: SPY Trend=UP AND Breadth=HEALTHY → SPY Trend=NEUTRAL fails first clause)
  Divergence: NO
  Prior call comparison: UNCHANGED (April: DO-NOT-ACTIVATE)

### Strategy B:
  Activation call: ACTIVATE
  Reasoning: B's fundamental question asks whether event reactions show measurable mean reversion at 2–8 week horizons or whether the regime is one where reactions are fully informative (no mean reversion to exploit). M1a's risk-on / latent-shock combination supports the mean-reversion mechanism: VIX decompressed to mid-teens reduces noise around individual event reactions; risk-on sentiment with the kinetic shock phase receding produces overshoots in both directions (sentiment-driven over-extrapolation on beats; capitulation-style underreactions on misses against a record-high tape backdrop). The stagflation-tilt fundamental backdrop introduces sentiment-shock risk around macro prints (CPI, PPI, FOMC), but B's per-thesis adversarial counter-argument step (criterion 4 information-vs-sentiment test) and short 10-day entry window already filter for information-driven moves. The April call was ACTIVATE under "high-volatility tape with geopolitical overshoot conditions"; May replaces that with low-vol / risk-on / shock-recovery conditions which also support the mechanism via the low-VIX channel of B's pre-mortem. The reaccelerating-inflation/hawkish-policy combination is the principal residual risk (a sharp inflation print could produce macro-driven selling cascades that mimic post-event noise), but the router's HIGH-VIX exclusion provides regime-level mitigation if VIX rebreaks 25.
  Reconciliation override applied: no (no rule applies to B at any regime axis combination)
  Technical signal for this strategy: ACTIVATE (rule: SPY Trend≠DOWN AND VIX≠HIGH → NEUTRAL≠DOWN passes; NORMAL≠HIGH passes)
  Divergence: NO
  Prior call comparison: UNCHANGED (April: ACTIVATE)

### Strategy C:
  Activation call: DO-NOT-ACTIVATE
  Reasoning: C's fundamental question asks whether the event-trading environment is functional or whether the regime is dominated by macro shocks that override individual-catalyst dynamics. May's regime is macro-dominated by construction: stagflation-tilted fundamental axes are simultaneously moving against trend (growth, inflation, policy) while the risk-on asset-pricing channel is itself concentrated in Q1-earnings-momentum and ceasefire-relief vectors — not a regime where event-specific options pricing reflects clean idiosyncratic dispersion. The cross-sectional dispersion-compression dynamic that informed the April HYBRID resolution (corporate earnings DO-NOT-ACTIVATE; FOMC-only ACTIVATE) is reinforced in May: hawkish-FOMC-minutes / new-Chair dynamics make Fed reaction-function the dominant pricing factor, compressing per-name earnings reaction dispersion in stagflation-squeeze cross-sections (AI_Edges 2.13 miscalibration compounds directional thesis quality). FOMC events remain the affirmative exception per the April HYBRID logic (FOMC IS the macro catalyst that the DNA reasoning names as dominating, not an individual catalyst suppressed by macro), but per the M1b immutable output format the strategy-level fundamental call is binary; the FOMC-only carve-out is a divergence-review-resolved scope decomposition, not an M1b output. Strategy-level fundamental DNA stands.
  Reconciliation override applied: no (no rule applies to C at any regime axis combination)
  Technical signal for this strategy: ACTIVATE (rule: SPY Trend≠DOWN → NEUTRAL passes)
  Divergence: YES (Tech ACTIVATE / Fund DO-NOT-ACTIVATE) — to be queued as a divergence-review by M5
  Prior call comparison: UNCHANGED (April: DO-NOT-ACTIVATE fundamental; April final state HYBRID-ACTIVATE-FOMC-only via divergence review)

### Strategy D:
  Activation call: DO-NOT-ACTIVATE
  Reasoning: D's fundamental question asks whether the current macro-structural environment is one in which multi-year equity theses can plausibly play out or whether structural headwinds argue against initiating new long-horizon positions this month. The April call was ACTIVATE under "secular theses intact; no sustained inversion; no confirmed recession; AI/earnings concentration durable." May materially weakens the activation case on the growth and inflation axes: Q1 GDP revised down to +1.6% with downward revisions concentrated in private inventory and services-side consumer spending; UMich at record low (third consecutive monthly decline); ISM Services New Orders fell 7.1pp. April PPI +6.0% YoY is the largest 12-month advance since Dec 2022, and core CPI +0.4% MoM SA is the largest monthly print since Jan 2025 — reaccelerating against a hawkish FOMC minutes / new-hawkish-Chair backdrop. Persistent hawkish-inflation regimes structurally compress multi-year equity theses through (a) higher discount-rate path, (b) elevated reaccelerating-inflation tail risk that forces another tightening leg, (c) cumulative pressure on long-duration earnings streams. The yield curve sustained-inversion safeguard remains NOT-SUSTAINED, but the fundamental case has tipped from "secular theses intact" to "late-cycle compression risk materially elevated." Risk-on asset pricing does not alter the multi-year structural backdrop — it is the principal vector by which D would absorb regime breaks (concentration / AI / large-cap leadership), exactly the configuration D's pre-mortem identifies as most exposed to multi-year decompression. Existing D positions (RTX open per Portfolio_Ledger) run to thesis-invalidation under router-deactivation-does-not-force-exits rule; only new entries are blocked.
  Reconciliation override applied: no (call is already DO-NOT-ACTIVATE; the `inflation_trend=reaccelerating AND policy_stance=hawkish → D DNA` override would fire IF call were ACTIVATE, but does not apply mechanically since the override is directional only)
  Technical signal for this strategy: ACTIVATE (rule: (SPY Trend=UP OR NEUTRAL) AND Sustained Inversion=NOT-SUSTAINED → NEUTRAL passes; NOT-SUSTAINED passes)
  Divergence: YES (Tech ACTIVATE / Fund DO-NOT-ACTIVATE) — to be queued as a divergence-review by M5
  Prior call comparison: FLIP TO DO-NOT-ACTIVATE (April: ACTIVATE fundamental)

### Strategy E:
  Activation call: DO-NOT-ACTIVATE
  Reasoning: E's fundamental question asks whether the current sector-rotation environment is conducive to within-industry-group mean reversion or whether macro forces are dominating intra-sector dynamics. The May regime is macro-driven by construction: stagflation-tilted fundamental axes move against trend simultaneously while risk-on pricing is concentrated in Q1-earnings-momentum and ceasefire-relief vectors. Within-industry dispersion in that configuration tracks regime-stress reaction patterns more than fundamental L-vs-S divergence — the shock-recovery vector (Iran kinetic phase receding, oil normalizing, ceasefire newsflow) is itself an intra-sector macro-overlay that compresses within-industry dispersion in energy, transports, and industrials (the sectors most prone to E pair opportunities at retail-tradeable instrument depth). Trailing-252-day correlation stationarity that E's criterion 3 relies on remains stressed by the regime-break sequence of 2026 (March oil shock; February tariff-IEEPA SCOTUS ruling; ongoing Iran conflict) — the structural-macro-hedge-failure-before-convergence risk identified in the April divergence-review verdict persists. The May M1a's risk-on asset-pricing signal does not contradict that: the surface pattern is risk-on, but the underlying regime configuration (stagflation-tilt + active-but-receding shock + hawkish-policy-and-new-Chair) is exactly the kind of regime-break sequence the April DNA reasoning identified as structurally adverse for within-industry mean reversion. April DNA stands.
  Reconciliation override applied: no (no rule applies to E at any regime axis combination)
  Technical signal for this strategy: ACTIVATE (rule: SPY Trend≠DOWN AND VIX≠HIGH AND Breadth=HEALTHY → NEUTRAL≠DOWN passes; NORMAL≠HIGH passes; HEALTHY passes)
  Divergence: YES (Tech ACTIVATE / Fund DO-NOT-ACTIVATE) — to be queued as a divergence-review by M5
  Prior call comparison: UNCHANGED (April: DO-NOT-ACTIVATE)

---

## Reconciliation overrides applied

Mechanically checked AFTER step 1 per Strategy.md M1a/M1b reconciliation rules and the M1b prompt:

| Rule | M1a axis values | Strategy targeted | M1b raw call | Override applied? |
|------|-----------------|---------------------|----------------|----------------------|
| shock_overlay = acute → override all ACTIVATE → DNA | shock_overlay = latent | all | n/a | NO (precondition fails — `latent` not `acute`) |
| risk_sentiment = stressed → override A or D ACTIVATE → DNA | risk_sentiment = risk-on | A, D | A DNA, D DNA | NO (precondition fails — `risk-on` not `stressed`) |
| growth_momentum = decelerating AND policy_stance = hawkish → override A ACTIVATE → DNA | decelerating, hawkish | A | A DNA | NO (precondition satisfied; rule did not fire because A's raw M1b call is already DNA — override is directional ACTIVATE→DNA only) |
| inflation_trend = reaccelerating AND policy_stance = hawkish → override D ACTIVATE → DNA | reaccelerating, hawkish | D | D DNA | NO (precondition satisfied; rule did not fire because D's raw M1b call is already DNA — override is directional ACTIVATE→DNA only) |

No overrides materially changed any M1b call this month. The two preconditions-satisfied rules (A under decelerating+hawkish; D under reaccelerating+hawkish) are logged for the monthly review record per Strategy.md "Contradictions logged for monthly review" instruction — no contradiction exists here because the raw fundamental reasoning and the mechanical reconciliation rule converge on the same DNA call.

---

## Divergence flags (post-reconciliation, per-strategy)

| Strategy | Technical | Fundamental (post-reconciliation) | Divergence | Downstream action (M5) |
|----------|-----------|----------------------------------------|----------------|-----------------------------|
| A | DO-NOT-ACTIVATE | DO-NOT-ACTIVATE | NO | Update Regime_State.md to confirm A DO-NOT-ACTIVATE (UNCHANGED); A queue in Watchlist.md remains queued (no router flip); no divergence review |
| B | ACTIVATE | ACTIVATE | NO | Update Regime_State.md to confirm B ACTIVATE (UNCHANGED); no divergence review |
| C | ACTIVATE | DO-NOT-ACTIVATE | YES | Queue divergence-review (C); prior cycle resolved HYBRID-ACTIVATE-FOMC-only — re-run for May regime; existing HYBRID state remains operative until review completes |
| D | ACTIVATE | DO-NOT-ACTIVATE | YES | Queue divergence-review (D); FLIP-TO-DO-NOT-ACTIVATE-fundamental drives the new divergence; existing D positions (RTX open per Portfolio_Ledger) run to thesis-invalidation per router-deactivation-does-not-force-exits rule; new D entries blocked pending review outcome |
| E | ACTIVATE | DO-NOT-ACTIVATE | YES | Queue divergence-review (E); prior cycle resolved DO-NOT-ACTIVATE — re-run for May regime; existing DNA state remains operative until review completes |

Three divergences for M5 to queue as `divergence-review` entries in `Pending_Adversarial_Reviews.md`: C, D, E. C and E divergences carry forward from the April cycle (same direction); D is a new divergence created by the fundamental flip from ACTIVATE to DO-NOT-ACTIVATE.

---

## Routine-end notes

- Per the Strategy.md immutable output format: Activation call / Reasoning / Reconciliation override applied / Technical signal / Divergence per strategy — all five fields populated above.
- No router state changes are applied by this routine. M5 (Monthly Action Conversion) reads this PART 2 verbatim and (a) updates `Regime_State.md` for no-divergence agreements (B confirms ACTIVATE; A confirms DNA), (b) queues divergence-reviews for C/D/E, (c) processes Strategy A queue-drain triggers (A remains DNA → no drain), and (d) addresses the D fundamental flip's effect on existing D positions and on the W4-cycle D thesis-construction scheduling.
- Read-scope discipline confirmed: no macro/policy/earnings/geopolitical source for May 2026 was consulted by this routine.

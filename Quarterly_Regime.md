# Quarterly_Regime.md

2026-Q2

> **Scope.** Retrospective for the prior calendar quarter, **Q2 2026 (April 1 – June 30, 2026)**. This is the first quarter for which **Part 2** (router activation trace and consistency comparison) is produced: the AI-directed multi-strategy experiment began **2026-04-22**, so the router history covers ~10 weeks (Apr 22 – Jun 30). Part 1 covers the full calendar quarter regardless of the experiment start.
>
> **Data provenance.** SPY price path, 50/200-day SMAs, SPY Trend State, and realized volatility are computed directly from IBKR-connector daily bars (SPY, contract 756733) and cross-checked against FMP `^GSPC` daily closes (index +14.87% vs SPY +14.83% — consistent). VIX / Treasury yields / breadth from FRED and market trackers; earnings from FactSet; regime/router state from `events.regime_events`, `events.decision_log`, `events.adversarial_reviews`. Figures labeled *(derived)* are computed here; *(est.)* are best-sourced estimates where a primary print was unavailable.

---

## PART 1 — Retrospective characterization of Q2 2026

### 1. SPY trend character

**Total return.** Q2 2026 was a powerful **V-shaped recovery quarter** — the strongest quarter since Q2 2020. The S&P 500 rose from a Q1-end close of **6,528.53 (Mar 31)** to **7,499.35 (Jun 30)**, a **price return of +14.9%**; SPY moved in line (650.34 → 746.77, +14.83% price; **total return ~+15.1%** including the June $1.90/sh distribution). Nasdaq +21.4%, Dow +12.9% ([CNBC, Jun 29 2026](https://www.cnbc.com/2026/06/29/stock-market-today-live-updates.html)).

**Path description.** A **sharp recovery then a rolling top**: the quarter opened right at the Iran-war-shock low inherited from Q1, dipped once more in early April (SPY intraday low ~645; index 6,616.84 on Apr 7), then rallied almost uninterrupted through April and May to record highs by early June, before a choppy June pullback. Three legs: (a) early-April retest of the war-shock low; (b) an April–May melt-up to all-time highs; (c) a June rolling top / mild distribution.

**50-day / 200-day SMA relationship.** The quarter *began* with SPY **below its 50-day SMA** (650.34 vs 50-day 677.49) — the residue of the late-February/March war-shock correction — while the 50>200 structure itself was never broken. SPY crossed back above its 50-day in mid-April and *ended* the quarter **above both averages** (close 746.77 > 50-day 735.87 > 200-day 691.43). **No golden or death cross occurred during Q2** *(derived from one-year SPY bars)*; the 50>200 "golden" structure that has held since July 2025 remained intact and the 50-day itself turned back up mid-quarter.

**Major intra-quarter moves.**
- **Apr 1–7 retest:** early-April dip to the war-shock low (SPY ~645 intraday, Apr 7; VIX 25.78) before the recovery took hold.
- **Apr 8 – Jun 2 rally:** ~+15% advance off the low to a record **7,609.77 (Jun 2)**; the strongest stretch of the year, driven by Iran-war de-escalation, oil normalization, and a blowout Q1 earnings season.
- **Jun 2–26 rolling top:** −1% June as hot CPI (Jun), a hawkish June FOMC, and a late-June mega-cap-tech/chip selloff pulled the index to ~7,354 (Jun 26) before a quarter-end rebound to 7,499.

**Quarter start / end / high / low.** Start 6,528.53 (Mar 31); end 7,499.35 (Jun 30); high 7,609.77 (Jun 2); low 6,528.53 (Mar 31) — the index never revisited the Q1-end level, with the early-April 6,616.84 (Apr 7) the intra-quarter trough.

### 2. Volatility regime

**VIX range and average.** VIX opened the quarter **elevated at 24.54 (Apr 1)**, peaked at a **quarter-high 25.78 close (Apr 7)** during the early-April retest, then ground steadily lower to a **quarter-low 15.32 (May 29)** as the melt-up ran, before re-elevating in June (intramonth pops toward ~19–22 on the hot-CPI print and the late-June geopolitical/tech-selloff flare) and settling at **16.45 (Jun 30)**. **Quarter average ~18.3** *(derived from FRED VIXCLS daily)* ([FRED VIXCLS](https://fred.stlouisfed.org/series/VIXCLS)).

**Realized S&P 500 volatility (annualized).** **~13.7–14.0%** *(derived, close-to-close, 62 trading days ×√252)* — front-loaded in April (**~11.3%**), compressed through the calm May grind-up (**~9.5%**), and re-elevated in the June chop (**~17.3%**). Realized ran well *below* the ~18.3 average VIX all quarter — implied carried a healthy risk premium, characteristic of a recovering-vol regime.

**Vol events.** One **HIGH-VIX day** (>25 close: 25.78 on Apr 7) at the early-April retest; a **sub-16 compression** into the May 29 low (15.32, approaching but not breaching the <15 LOW threshold); June re-elevation without stress. No sustained HIGH-VIX regime after early April.

### 3. Yield curve trajectory

**10Y and 2Y path.** 10Y ~**4.30% (Mar 31) → ~4.38% (Jun 29)**; 2Y ~**3.79% → ~4.23%**. Intra-quarter the 10Y ranged ~4.26% (mid-April low) to **4.67% (May 19 high)**; the 2Y ran from ~3.71% (Apr 17 low) to ~4.24% (Jun 22 high). The **10Y–2Y spread stayed positive all quarter** and compressed from **+52bps (early April) to ~+30bps (late June)** — a classic **bear-flattener**, the 2Y selling off ~+42bps versus the 10Y's ~+7bps ([FRED DGS10](https://fred.stlouisfed.org/series/DGS10) / [DGS2](https://fred.stlouisfed.org/series/DGS2) / [T10Y2Y](https://fred.stlouisfed.org/series/T10Y2Y)).

**Inversion state.** **NORMAL (positively sloped) the entire quarter — no re-inversion.** Sustained-Inversion flag = NOT-SUSTAINED throughout.

**Fed / macro drivers.** The flattening was policy-driven: reaccelerating inflation prints lifted the front end, and the **June FOMC (Jun 17)** — while holding the target range at **3.50–3.75%** — turned decisively hawkish: the 2026 year-end dot median rose to ~**3.8%** (from 3.4% in March), implying **no cuts with a hike bias** (9 of 18 members penciled ≥1 hike). Fed-funds futures repriced toward a possible December hike; the dollar index rose ~2% to a ~15-month high (~101.3) ([Fed decision, Jun 17 2026](https://www.stocktitan.net/articles/fed-rate-decision-june-17-2026)).

### 4. Equity market breadth

**% of S&P 500 above 200-day SMA.** **V-shaped, mirroring price.** Breadth collapsed to a **~21% washout at the early-April low**, then climbed steadily through the April–May rally to **~62–63% by quarter-end** (Equity Breadth State transitioning **WEAK → HEALTHY** around mid-May and holding HEALTHY into June) ([StreetStats S&P breadth](https://streetstats.finance/markets/breadth-momentum/SP500); [Barchart $S5TH](https://www.barchart.com/stocks/quotes/$S5TH)).

**Participation character.** Began **narrow / mega-cap-tech-led** (Info Tech supplied essentially all of the S&P's top contributors during the May leg; ~38–39% index weight in Tech), then **broadened** as breadth crossed 50%; late June saw a **rotation** — a mega-cap-tech/chip/memory selloff while defensives (Health Care, Staples, Utilities) and the Dow led the final week. Net: a rally that started narrow and healed into broad-but-still-top-heavy participation.

### 5. Dominant macro narrative

**Quarter-start narrative (April): war shock → recovery.** Q2 opened under the tail of the Iran war (active since Feb 28). The dominant driver early was **geopolitical de-escalation and oil normalization** — a mid-June ceasefire framework restored near-normal Strait of Hormuz flows and **Brent fell from an April peak ~$128 to pre-war ~$73**, the risk-on fuel for the recovery.

**Quarter-end narrative (June): reflation + a hawkish Fed.** As the war premium bled out, the story pivoted to a **firm, still-inflationary economy meeting a decisively hawkish Fed.** Growth *re-firmed* (May payrolls +172k with +93k of upward revisions; Q1 GDP revised up to +2.1%), every inflation gauge *accelerated* (May CPI +4.2% YoY, core PCE +3.4% — fastest in ~3 years), and the June FOMC flipped the dot plot to no-cuts/hike-bias. The framework's own fundamental read captured the arc: **May = "stagflation-tilt + risk-on"** (asset-pricing rally vs softening fundamentals) → **June = "reflation-tilt + neutral risk"** (growth re-firm, inflation hot, rally pausing).

**Inflection points.** (a) early-April war-shock retest/bottom; (b) Q1 earnings blowout (Apr–May) validating the rally; (c) new Fed Chair **Warsh** sworn May 22 (hawkish-at-margin); (d) June's hot CPI + hawkish FOMC pivot that stalled the tape.

### 6. Earnings and fundamentals backdrop

**Q1 2026 season (reported Apr–May) was exceptionally strong** — the fundamental engine of the rally. **84% of S&P 500 companies beat EPS estimates** (vs 5-yr avg 78%), at an **average surprise of +18.2%** (vs 5-yr avg 7.3%) — the largest since Q1 2021. **Blended YoY EPS growth was +27.7%** (highest since Q4 2021), a massive beat of the +13.1% expected at quarter start ([FactSet Earnings Insight, May 8 2026](https://insight.factset.com/sp-500-earnings-season-update-may-8-2026)).

**Forward consensus rose over the quarter** — analysts moved 2026 S&P EPS growth projections up (~14% → ~17% YoY) with broad, positive-ex-Energy revisions; forward-quarter estimates settled around **Q2 +19.9% / Q3 +23.2% / FY26 +21.0%**. Rising forward EPS was a key structural support for the +14.9% price advance.

**Sector-level divergences.** 10 of 11 sectors posted YoY earnings growth (Info Tech, Comm Services, Materials, Consumer Discretionary leading double-digit); **Health Care was the sole sector with declining YoY earnings.** Energy estimates were revised up on higher oil.

**Sector price leadership (Q2).** Leaders: **Energy** (oil/geopolitics) and **Information Technology** (AI trade), with Industrials and Materials strong (cyclical/reflation). Laggards: **Health Care, Consumer Discretionary, and Financials** ([Schwab Sector Views, Jun 26 2026](https://www.schwab.com/learn/story/stock-sector-outlook)). *(Ranking high-confidence; clean Apr–Jun-only per-sector total-return magnitudes were not individually sourceable — trailing-6M and late-June-tracker proxies used.)*

### 7. Overall regime characterization

Q2 2026 was, on balance, a **risk-on, trending recovery quarter that transitioned into a macro-driven pause.** For roughly two-thirds of the quarter (early April → early June) the regime was decisively **risk-on and trending**: a +15% V-recovery off the war-shock low to record highs, restored UP trend structure, VIX grinding from the mid-20s toward 15, a positively-sloped curve, and a blowout earnings season broadening participation from narrow mega-cap leadership toward HEALTHY breadth. The final month turned **macro-driven and range-bound / mildly distributive**: reaccelerating inflation and a hawkish Fed pivot capped the tape (−1% June), flattened the curve, and drove a late-quarter **sector rotation** out of mega-cap tech into defensives. It was **not** risk-off (credit stayed historically tight — IG OAS ~80bps, HY ~285bps — and there was no growth scare), and only transitional at the margin. Best single description: **a risk-on recovery uptrend (Apr–early Jun) capped by a macro/Fed-driven range-bound pause with rotation (Jun).**

---

## PART 2 — Router activation trace, consistency comparison, and diagnostic flags

*Backward-looking factbase only. Per `Experiment_Parameters.md` mid-experiment immutability, the technical indicator set and fundamental template are immutable once trading begins; nothing below is a mid-experiment revision — the diagnostic flags are inputs to the **next experiment-restart router pre-mortem**.*

### 1. Router activation trace (Apr 22 – Jun 30, 2026)

| Strat | Technical rule | Activation trace | Divergence / adversarial reviews (outcome) | Deployment |
|---|---|---|---|---|
| **A** | SPY Trend=UP AND Breadth=HEALTHY | **DO-NOT-ACTIVATE the entire quarter** (inception 4/22 → confirmed 4/23, 6/1, 6/3, 7/1). Fundamental DNA (Fed-reaction-function-dominated tape). | None triggered. *(But see Diagnostic Flag 1 — an A divergence review was **suppressed** by a stale technical read.)* | None. A-queue held in Watchlist.md. |
| **B** | SPY Trend≠DOWN AND VIX≠HIGH | **ACTIVATE from 4/23** (pending foundation-change gate, cleared) → confirmed 6/1, 6/3, 7/1. No divergence (tech + fund agreed all quarter). | None (agreement). | **Most active strategy.** ~108 theses screened → **107 NO-GO / 8 GO**. Open: ZBRA (5/14), AZO (5/27), MDT (6/17). **TJX exited at convergence 6/9.** 0 shorts (long-bias by construction). |
| **C** | SPY Trend≠DOWN | DNA at inception (4/22) → **divergence 4/23** (tech ACTIVATE / fund DNA) → adversarial review → **HYBRID ACTIVATE (FOMC-only) 4/25** → re-derived (div-C-202605-1) **6/3 HYBRID ACTIVATE (FOMC-only)** → 7/1 pending div-C-202606-1. | **div-C (inception)** → HYBRID; **div-C-202605-1** → attacker "fundamental claim should not survive"; orchestrator **HYBRID ACTIVATE, theater-check MIXED (binding).** | None (FOMC-only scope; no qualifying FOMC catalyst cleared). |
| **D** | (SPY Trend=UP OR NEUTRAL) AND Sustained-Inversion=NOT-SUSTAINED | DNA inception → **ACTIVATE 4/23** → 6/1 fundamental **flip-to-DNA attempt** (div-D-202605-1; new-entry block) → **6/3 flip REJECTED, ACTIVATE maintained, block lifted** → 7/1 ACTIVATE pending div-D-202606-1. | **div-D-202605-1** → attacker "flip-to-DNA should not survive"; orchestrator **ACTIVATE (flip rejected), theater-check DIVERGENT (binding).** | **RTX (4/27), DIS (5/7)** — both open, run to thesis-invalidation (M3 2026-07: all invalidation criteria NOT-TRIPPED, HOLD/HOLD). |
| **E** | SPY Trend≠DOWN AND VIX≠HIGH AND Breadth=HEALTHY | DNA inception → **divergence 4/23** → review → **DNA 4/25** (default-DNA-on-ambiguity) → 6/1 DNA pending div-E-202605-1 → **6/3 flip DNA→ACTIVATE (substantive), execution-feasibility-deferred** → 7/1 ACTIVATE pending div-E-202606-1. | **div-E (inception)** → DNA; **div-E-202605-1** → attacker "DNA should not survive"; orchestrator **ACTIVATE, theater-check DIVERGENT (binding).** | None — substantive ACTIVATE but ETF-substitution-required at current per-strategy book size (~$1,890 NAV → ~$38/leg), so no pair entries. |

**Summary.** A never activated; B activated throughout and drove all real deployment; C settled into a narrow HYBRID (FOMC-only) scope; D activated and deployed (RTX/DIS) surviving a contested end-May flip attempt; E's router flipped to ACTIVATE on the merits in early June but deployment stayed blocked on execution feasibility. Every non-B strategy sat on a **technical-ACTIVATE / fundamental-DNA divergence** for much or all of the quarter, and in each adjudicated case the adversarial layer found the fundamental-DNA case weak (attacker "should not survive" on C, D-flip, and E).

### 2. Consistency comparison — router classification vs. retrospective

**Technical half (mechanical vocabulary) vs. actual Q2 tape:**

| Signal | Router-recorded state | Retrospective / mechanically-correct value | Match? |
|---|---|---|---|
| SPY Trend State | **NEUTRAL** (persisted, last written 2026-06-03) | **UP** on every session from ~4/22 through 6/30 (close > 50-day > 200-day, *derived*) | **NO — systematic disagreement** |
| Equity Breadth | HEALTHY (6/3) | WEAK (~21%, early April) → HEALTHY (~62%, quarter-end); HEALTHY correct *as of 6/3* | Yes (at 6/3) |
| VIX Regime | NORMAL | NORMAL (one HIGH-close day Apr 7; low 15.32 May 29) | Yes |
| Yield Curve / Sustained-Inversion | NORMAL / NOT-SUSTAINED | Positively sloped all quarter; NOT-SUSTAINED | Yes |

**Fundamental half (M1b) vs. actual regime.** The fundamental template correctly identified the *tension* of the quarter (reaccelerating inflation + hawkish Fed against a risk-on tape) and the growth re-firm (May stagflation-tilt → June reflation-tilt). But it ran **systematically more cautious than the realized regime warranted**: it returned DNA for A, C, and E and attempted a D flip-to-DNA, into a quarter that delivered a +14.9% melt-up to record highs on an 84%-beat, +27.7%-YoY earnings season. The reconciliation overrides (`inflation-reaccelerating + hawkish → D DNA`; `decelerating + hawkish → A DNA`) and the general stagflation framing pulled the fundamental calls bearish; the adversarial layer then repeatedly overturned or hybridized them (D-flip rejected, E flipped to ACTIVATE, C held at HYBRID). **The recurring pattern is a fundamental-vs-tape divergence in which the router's fundamental half lagged/underweighted a strongly risk-on, strong-earnings recovery** — precisely the "asset-pricing rally vs deteriorating fundamentals" tension the May read itself flagged.

### 3. Diagnostic flags (inputs to the next router pre-mortem — not mid-experiment revision triggers)

**Flag 1 — SPY Trend State signal-fidelity gap (highest priority).** The router's persisted SPY Trend State was **NEUTRAL**, last written to state on **2026-06-03** (migration snapshot, source `Regime_State.md`) and still operative at the M4 2026-07 run ("SPY Trend NEUTRAL fails the UP+HEALTHY clause"). The **mechanically-correct value was UP** on every session from ~2026-04-22 through quarter-end (verified from SPY 50/200-day SMAs). The vocabulary defines SPY Trend as "computed daily," but no daily technical recompute was persisted after 6/3, and the 6/3 value itself (NEUTRAL, a residue of the March correction when SPY sat below its 50-day) was already stale by mid-April.
- **Consequence, isolated:** Only **Strategy A** is affected, because A is the only strategy whose technical rule requires `SPY Trend = UP` — B/C/D/E require only `≠ DOWN`, which **both** NEUTRAL and UP satisfy, so their activation is robust to this error. For A, the correct `UP + HEALTHY` (HEALTHY held from ~mid-May) would have produced a **technical ACTIVATE**, creating a **tech-ACTIVATE / fund-DNA divergence that should have triggered an A divergence review** — which never occurred (the router saw spurious agreement, tech-DNA = fund-DNA).
- **Not an activation error, a process error:** this does **not** imply A should have been activated — A's fundamental call was DNA and, given the quarter's default-DNA-on-ambiguity / CONVERGENT→DNA tie-breakers, the suppressed review would very likely have resolved to DNA anyway. The defect is that a mechanical signal was mis-recorded and a required adversarial process step was skipped.
- **Pre-mortem candidate:** guarantee the technical vocabulary is recomputed and persisted **daily** (dead-man's switch on technical-signal freshness), and have M1b/M4 read a live-computed value rather than a possibly-stale persisted one.

**Flag 2 — Fundamental template ran systematically bearish vs. the realized risk-on regime.** Across the quarter the M1b fundamental half produced DNA/flip-to-DNA calls (A, C, E, attempted-D) that the adversarial layer overturned or hybridized in every adjudicated case, against a tape that melted up +14.9% to record highs on a blowout earnings season. This may be a small-sample coincidence, but it is the kind of systematic fundamental-vs-reasonable-observer disagreement Part 2 exists to surface. **Pre-mortem candidate:** examine whether the stagflation-framing and the `hawkish`-conditioned reconciliation overrides fire too readily in a strong-forward-EPS recovery, and whether the fundamental half adequately weights earnings-breadth/forward-EPS momentum against the inflation/policy axis.

**Flag 3 — Adversarial layer bore heavy load; theater-check distribution.** Five divergence reviews adjudicated in the quarter (C×2, D, E×2 across inception + May cycles); orchestrator theater-checks came back **MIXED (C) and DIVERGENT (D, E)** — i.e., not uniformly CONVERGENT, so the self-certified theater-check did not (yet) show the degenerate all-CONVERGENT pattern that would mandate adding a separate Theater Auditor routine. Worth continued monitoring as sample grows.

**Flag 4 — Short sample.** The trace covers only ~10 weeks (inception 4/22). All Part 2 patterns are provisional; re-assess with a fuller experiment history.

---

*Part 1 sources: FRED (VIXCLS, DGS10, DGS2, T10Y2Y); IBKR connector SPY daily bars; FMP `^GSPC`; FactSet Earnings Insight; CNBC; Schwab Sector Views; StreetStats; Barchart. Part 2 sources: `events.regime_events`, `events.decision_log`, `events.adversarial_reviews`, `state.current_positions` (project `stock-trading-498512`); `strategy/01,02,03,04,05,06,07`; `Experiment_Parameters.md`.*

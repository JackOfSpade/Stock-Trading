# Shock-native candidate — research dossier (2026-10-19)

**What this is.** The evidence base for a strategy that trades in the market condition the roster
currently sits out: a hawkish Fed hiking into an `acute` oil shock (Brent $95–110, 10Y > 5%), SPY
NEUTRAL, VIX NORMAL, breadth marginal. Written in the interactive owner session of 2026-10-19,
after Strategy.md Rev 50 made the acute-shock cell coverable. It is an input to SL1's next
synthesis (first trading day of 2027-Q1), recorded as `events.strategy_research_leads` lead
`interactive-2026-10-shock-transmission-second-order-hedged`.

**What this is not.** Not a `state.strategy_candidates` row (SL1's job; a row written here would
burn an archetype cooldown on rejection), not a Strategy.md section (SL2's job), not a backtest
(see §3.6 — none of the pre-cutoff evidence can be re-run with this system's model). It states what
is known, what it buys the design, and what it forbids.

---

## 1. The condition, measured

| Plane | 2026-10-16 reading | Source |
|---|---|---|
| SPY trend | NEUTRAL (close 763 < 50d 768.5; 50d > 200d); chopping across the 50d since 09-10 | `events.regime_events` TECHNICAL_SIGNAL |
| VIX | NORMAL 19.99 | same |
| Breadth | HEALTHY 51.9% (WEAK 41–49% from 09-18 to 10-14) | same |
| Curve | NORMAL, +35bp | same |
| M1a 2026-10-01 | growth stable · inflation stable · policy **hawkish** (hike 09-16, 10Y 5.1–5.3%) · risk neutral · **shock_overlay acute** (3rd month) | FUNDAMENTAL_AXIS |
| Roster | A/B/D/E DNA, C HYBRID FOMC-only; last fill 2026-08-27 | STRATEGY_ACTIVATION, `state.trade_fills_curated` |

The technical cell (NEUTRAL/NORMAL) is covered by B, C, D, E's routers. What was uncovered was the
*fundamental* cell `shock_overlay = acute`, and Rev 50's SHOCK-NATIVE class now makes a strategy
whose activation rule *requires* `shock_overlay ∈ {latent, acute}` admissible by construction.

## 2. The philosophy as a checklist (the test any candidate must pass)

1. The **return driver is a Part-1 AI edge** — narrative synthesis (1.1), contradiction surfacing
   (1.4), cross-disciplinary integration (1.10) — never a factor premium, trend or rotation
   (candidates F and H died on exactly this; SL1 STEP 3 (a)).
2. It **compensates a non-version-pending Part-2 disadvantage** (eligible today: 2.1, 2.2, 2.5,
   2.6, 2.9, 2.11, 2.12, 2.16, 2.18, 2.21–2.31).
3. **Capital preservation over edge maximisation** (2.18): hard rails, bounded or hedged downside,
   thesis-invalidation exits.
4. **Material structural difference** from A–E and **non-redundancy** on its target cells.
5. **Countable signal** + declared frequency band; **cost fit** ≤ 1.8% round-trip at the $2,000 probe.
6. **Cooldowns clear** (F/G to 2026-10-25, H to 2026-11-01 — all distinct archetypes).
7. Rev 50 SHOCK-NATIVE rails: hedged or defined-risk; invalidation keyed to the rubric's
   de-escalation legs; frequency denominated in qualifying shock events.

## 3. Evidence, by strand

### 3.1 Economic-link underreaction is real, large in-sample, and attention-driven

- **Cohen & Frazzini 2008 (JF 63:1977)** — suppliers drift after their principal customers' news:
  value-weighted L/S 1.58%/mo excess, 4-factor alpha 1.38% (t 3.1); drift persists ~12 months;
  **3.02%/mo where common-fund ownership is low vs 0.55% (n.s.) where high** — the effect lives
  where attention is scarce. An independent **2026 replication** on the authors' link workbook
  reproduces 1.37%/mo (t 3.36), 4-factor alpha 1.19% (t 2.68) in-sample.
- **Menzly & Ozbas 2010 (JF 65:1555)** — the same along input–output industry links; magnitude
  *declines with analyst coverage and institutional ownership*.
- **Cohen & Lou 2012 (JFE 104:383)** — "complicated firms": information about conglomerates
  diffuses slowly because it needs assembly across segments.
- **Ali & Hirshleifer 2020 (JFE 136:649)** — shared-analyst-coverage momentum (1.68%/mo, t 9.7)
  *subsumes* customer, industry, technology and geographic spillovers; sell-side analysts
  incorporate linked-firm news sluggishly; **effects are stronger for complex and indirect
  linkages.**
- **Decay:** McLean & Pontiff 2016 — −26% out-of-sample, −58% post-publication; a 2025
  reproduction on 212 predictors through 2024 finds −26–32% / −40–51%.

*What it buys the design:* the mechanism the philosophy needs — markets under-react to news that
must be **assembled across documents and hops**, which is the 1.10/1.4 edge stated as an asset-
pricing fact. *What it forbids:* first-order links in well-covered names; expect the published
magnitudes to be roughly halved, and to concentrate in the less-covered half of any universe.

### 3.2 Industry lead-lag at the index level is gone

Hong, Torous & Valkanov 2007 (14 of 34 industries led the market by ≤ 2 months) does not survive
Tse 2015's re-examination (1–7 of 48 industries, consistent with efficiency). **Do not build on
sector-level timing.**

### 3.3 Oil and macro shocks reprice the cross-section over months, not weeks

Fieldhouse, Kim & Mahajan (2025-12, Texas A&M WP) — identified oil-supply (Känzig 2021), monetary,
credit and fiscal shocks have significant, *persistent and heterogeneous* effects on industry
portfolios and on anomaly/mispricing factors; the oil-supply shock's effect on the performance
cluster appears at **31–36 months**, its size tilt at **12–26 months**. Kilian-type SVAR
replications (arXiv 2409.00769, 2024–25) confirm effects are shock-type-dependent (supply vs
aggregate-demand vs precautionary), "statistically significant but economically modest" at the
index level. *Design consequence:* holding horizon of **1–6 months**, hedged — not B's 2–8-week
fade and not an index bet.

### 3.4 Text-measured exposure is priced fast at first order; the residual is second order

- Hassan, Hollander, van Lent & Tahoun 2019 (QJE) and 2023 (RFS, epidemic exposure): earnings-call
  text measures of firm-level exposure track valuations and are priced in options; the 2023 paper
  decomposes COVID into simultaneous demand and supply shocks.
- **Tariff exposure from 10-K Items 1/1A** (Economics Letters 2025; Andreou et al. 2026): higher
  disclosed exposure → significantly more negative CAR[0,+1] around 2025-04-02 — i.e. the market
  prices *disclosed first-order* exposure within two days. Delayed reaction over several days is
  documented only in less-covered markets (ASEAN event study).

*Design consequence:* a shock-native strategy earns nothing on "airlines are hurt by jet fuel". The
candidate must target the **second hop** — the customer of the supplier that lost its naphtha, the
insurer of the rerouted hull, the chemical converter whose feedstock is the refined product whose
crack spread tripled — exactly where Ali & Hirshleifer find the slowest incorporation.

### 3.5 LLM-built networks produce modest gross Sharpes in large caps

- arXiv 2604.19476 (2026) "Cross-stock predictability via LLM-augmented semantic networks":
  retrieve-then-reason over 10-Ks, the LLM classifies each candidate edge (competitor / supply
  chain / peer …), competitor edges removed. L/S 4.67% annualised, vol 5.7%, **Sharpe 0.82**.
- arXiv 2606.29290 (2026) "Supply-chain propagation of textual signals": FinBERT embeddings of
  MD&A propagated through a supply-chain graph, 255 S&P 500 firms 2011–2025; network factor NW
  t −2.64 after momentum/vol/size controls; L/S **Sharpe 0.86**.
- arXiv 2512.19484 (2025) structured event representation from news beats text baselines
  out-of-sample.

*Design consequence:* the mapping step is feasible and has literature precedent; the realistic
gross edge from *mechanical* link signals in liquid names is Sharpe ≈ 0.8 before costs. The
candidate's claim to more than that rests on (i) shock-conditioning — the literature does not
measure these signals *in shock months* — and (ii) judgment over the transmission chain rather
than embedding similarity. Both are **unmeasured** and must be treated as hypotheses the forward
test decides.

### 3.6 No pre-cutoff backtest of the LLM step counts — and the lifecycle already knows this

Lopez-Lira, Tang & Zhu 2025 (arXiv 2504.14765): GPT-4o recalls S&P 500 closes within 1% inside its
training window and de-anonymises masked firms; arXiv 2512.23847 (2025) measures that memorisation
amplifies apparent LLM return predictability by ~37% of the baseline effect; Look-Ahead-Bench
(arXiv 2601.13770) and a point-in-time fix (arXiv 2512.06607) exist but are not this system's
model. **Consequence:** evidence for the LLM mapping can only come from SHADOW → PAPER forward
tests on post-cutoff data (2.19), which is precisely the SISA pipeline; a replay over the 2026
Iran-war shock with the current model is contaminated by construction and must not be cited.

### 3.7 The 2026 shock's own transmission ran for months, through second-order channels

Documented facts (Reuters/Fortune/Morgan Lewis/CSIS, Mar–May 2026): Hormuz closure from late Feb;
Brent $71 → ~$100; jet fuel +120% to $1,838/t by early April; diesel/jet crack spreads $50–80/bbl
vs $15–20 pre-war; airlines ≥ $15bn of a ≥ $25bn corporate hit by mid-May; Toyota −$4.3bn,
P&G −$1bn, Whirlpool halved guidance and suspended its dividend; a naphtha shortage shut small
Asian plastics converters while large ones gained share; China cut refined-product exports. The
first-order losers were known in week one; the converter, appliance, consumer-staples and
freight-insurance consequences surfaced over 6–12 weeks — the horizon §3.3 implies.

### 3.8 Crowding (2.8)

Claude sits behind most retail-broker AI agents (A1 2026 sweep); a second-order map built by the
same model family is correlated with other agents' maps. Mitigation is structural, not
analytical: hedged construction, modest size, and invalidation that does not depend on other
agents' behaviour.

## 4. What the evidence implies for the candidate (for SL1 to synthesise, not a spec)

| Element | Implication | Why |
|---|---|---|
| Mechanism | For a rubric-qualifying shock event, build the transmission graph from public filings/transcripts/news (2.6 rail), classify each edge (input cost, customer demand, logistics, financing), rank **second-hop** names by (exposure × low analyst co-coverage with the first-order names), and express the mispricing hedged | §3.1, §3.4, §3.5 |
| Return driver | 1.10 cross-disciplinary assembly + 1.4 contradiction between a firm's disclosed dependence and its sell-side framing; the *assembly* is the edge, not a factor | checklist 1 |
| Compensated disadvantages | 2.6 (public-document-only universe, E's rail), 2.12 (hedge ratio, beta and sizing by code), 2.2 (multi-week horizon, no intraday) | checklist 2 |
| Structure | Hedged long/short (sector-ETF or index hedge; cross-industry pairs allowed) — net-long directional expression forbidden by the SHOCK-NATIVE rail | Rev 50 rail (i) |
| Horizon | 1–6 months; time-exit at 6 months | §3.3, §3.7 |
| Countable signal | one per rubric qualifying shock event × graph refresh; declared band in qualifying events per year | Rev 50 rail (iii) |
| Invalidation | the rubric's de-escalation legs (15-day quiet window AND 50% retracement) close every open thesis; plus per-thesis public-information invalidation | Rev 50 rail (ii) |
| Router line | `shock_overlay ∈ {latent, acute}` AND VIX ≠ HIGH (spread mechanics break in HIGH VIX, E's rationale); trend and breadth unconstrained — the hedge, not the tape, carries DOWN cells | coverage of DOWN/* and NEUTRAL/* cells |
| Register row | SHOCK-NATIVE, exempt by class, no gate, horizon-class status-quo | Rev 50 |
| Instruments | US-listed, ≥ $2B cap, ≥ $10M ADV (B's floors), fractional execution; borrow ≤ 15% of expected return (E's gate) | cost rail (d) |
| Size | seven-factor CaR per thesis, both legs counted once, mandatory short-leg stop set at entry (E's Rev 45 pattern) | 2.18 |

## 5. Rails status today

| Rail | Status | Blocker / evidence needed |
|---|---|---|
| (a) edge validity | PLAUSIBLE — mechanism traces to 1.10/1.4; 2.6/2.12/2.2 compensated | SL1 must write the derivation; the shock-conditioning claim is unmeasured |
| (b) structural difference | PASS — cross-industry, shock-triggered, hedged; differs from E (same-industry-group, ≥ 0.5 correlation pairs) and B (single-name 5% event-day move) | — |
| (c) non-redundancy | PASS — no live strategy activates on `acute`; targets DOWN/* and NEUTRAL/* cells no one covers | — |
| (d) cost fit | PLAUSIBLE — 0.42% equity-pair round trip measured 2026-08; borrow 0.25–0.43% sampled | per-thesis check at authoring |
| (e) ceiling | PASS — 5 < 8 | — |
| (f) cooldown | PASS — archetype is new | — |

## 6. Expected economics, stated honestly

Published link-momentum: ~1.4%/mo gross in-sample on attention-starved names; halve it for decay and
again for a large-cap universe → **0.3–0.7%/mo gross** is the defensible prior for a mechanical
version; LLM-network studies land at Sharpe ≈ 0.8 gross. Costs at the probe scale (~0.4%
round-trip + borrow) eat a meaningful share at 1–6-month holds. The strategy's case for being better
than that prior is the shock-conditioned, second-hop, judgment-assembled selection — which **no
source measures**, and which only SHADOW/PAPER can measure for this model. That is the honest
expected-value statement: a positive but thin mechanical prior, plus an unmeasured hypothesis that
the lifecycle exists to test at zero capital.

## 7. What SL1 needs to do next (and what this dossier deliberately did not)

1. Resolve the lead against `events.strategy_research_leads` (it is OPEN); do not open a duplicate.
2. Derive the three SHOCK-NATIVE rails into concrete machinery with provenance; the signal-rate band
   must be countable (qualifying events are already dated by the rubric).
3. Decide the second-hop selection rule as a judgment-native protocol (SL2 (A) 1b) with a declared
   conviction gate, and pre-register the analyst-co-coverage proxy it will use.
4. State the declared frequency in qualifying shock events (2026 to date: ≥ 2 structures, ≥ 6
   qualifying events) and the 30-trade gate arithmetic that follows.
5. Not done here, on purpose: no candidate row, no Strategy.md section, no backtest, no live
   trigger change.

## Appendix A — Limb (b) measurement: D's shock-era vs pre-shock entry cohorts (2026-10-19)

Beta-unadjusted excess vs SPY at a matched 50-trading-day holding age (dust lots < 0.01 sh excluded):

| Cohort | n | Mean excess @50td | Median | Mean excess now |
|---|---|---|---|---|
| Pre-shock entries (04-27 … 07-31, `latent`) | 11 | +6.0% | +4.8% | +5.0% |
| Acute-era entries (GEV 08-03, DIS 08-06) | 2 | +4.6% | +4.6% | +1.3% |

n = 2 in the acute cohort; the difference is within one lot's dispersion (CRM +48.5% alone moves the
pre-shock mean by ~4 points). **No evidence either way → D's horizon row stays `status-quo`.** The
measurement that could move it needs ≥ 10 acute-era entries, which D's 3–8 trades/year will not
produce before 2027.

## Appendix B — Sources

Cohen & Frazzini 2008 JF; replication report 2026 (dmurav.com, Table III Panel A); Menzly & Ozbas
2010 JF; Cohen & Lou 2012 JFE; Ali & Hirshleifer 2020 JFE 136:649; McLean & Pontiff 2016 JF +
anomaly-decay reproduction (OSAP 2025-10); Hong, Torous & Valkanov 2007 JFE; Tse 2015 JEF 34:195;
Fieldhouse, Kim & Mahajan 2025-12 WP; arXiv 2409.00769 (Kilian replication); Hassan et al. 2019 QJE,
2023 RFS; Economics Letters 2025 "Tariff exposure and Liberation Day reactions"; Andreou et al. 2026
Economics Letters; arXiv 2604.19476; arXiv 2606.29290; arXiv 2512.19484; arXiv 2504.14765; arXiv
2512.23847; arXiv 2601.13770; arXiv 2512.06607; Reuters via Times of India 2026-05-19; Fortune
2026-05-06; Morgan Lewis 2026-05-11; CSIS ChinaPower 2026-04-30; Barclays Hedge Fund Outlook 2026.

---

## 8. Event-study outcome (same day, 2026-10-19) — the design inverts

§§1–7 above are the pre-study record and are left as written. The study they asked for was run the
same day (`ops/research/shock_episode_event_study_2026-10.md`, `scripts/research/shock_episode_event_study.py`;
BEA 2023 use table for the link map, Kenneth French 49-industry portfolios for six supply shocks
1990–2026 plus two demand-shock controls, Nasdaq data for an ETF-era cross-check, 12 seeded placebo
onsets and a 500-draw placebo distribution; no LLM in the loop). Its verdict, quoted:

> Second-hop hedged drift over 4 weeks is +0.6% (bootstrap 95% CI −2.2% to +3.2%) vs +0.1% in
> placebo windows, positive in 4 of 6 episodes; over 12 weeks it is −2.9% (CI −10.1% to +4.6%) vs
> +0.5% in placebos, positive in 2 of 6. No horizon from 1 to 12 weeks shows a second-hop drift
> distinguishable from the base rate, while the dispersion of second-hop outcomes in shock months is
> about twice the placebo dispersion (3.5% vs 1.5% at 1 week, 10.5% vs 5.5% at 12 weeks). The spread
> second-hop minus first-hop is negative at every horizon (−0.6% at 2 weeks to −4.1% at 12, 5th–25th
> placebo percentile) because the FIRST hop keeps repricing for 2–4 weeks after onset (+1.9% hedged
> at 4 weeks, 95th percentile; refiners +17% and airlines −9% on 2016–2026 ETF data, 3 of 3).

### 8.1 What it kills

- **The second-hop mechanical drift (§4's mechanism).** Not distinguishable from placebo at any
  horizon; what shock months add is dispersion, with episode-specific direction. The "judgment
  picks the right second-hop names" hypothesis survives only as an unmeasurable residual on top of a
  zero mechanical prior — which is exactly the shape SL1 STEP 3 (a) default-rejects.
- **§3.4's inference that first-order exposure is fully priced in two days.** True for a disclosed
  tariff list on announcement day; false for an oil supply shock, where the first-hop industries
  keep moving in the shock's direction for 2–4 weeks, hedged.

### 8.2 What it supports — and why the philosophy makes it harder, not easier

The repeatable, placebo-beating pattern is **first-hop continuation**: long the shock's first-order
winners / short its first-order losers, market-hedged, held 2–4 weeks from a rubric-qualifying
onset. +1.9% hedged at 4 weeks pooled (95th placebo percentile, 4 of 6 episodes); the 2026 Iran
episode itself read +6.0% hedged at 4 weeks. Bounds: n = 6 supply shocks (3 in the ETF era),
industry-level portfolios, a survivorship-selected 2026 basket, no dividend-adjusted long ETF series.

Identifying refiners and airlines after an oil shock is not a Part-1 AI edge; it is a classical
post-event industry drift, and rail (a) rejects a mechanical version of it on the same ground that
rejected F and H. The only philosophy-consistent form is **Strategy B's mechanism applied to the
shock**: for each first-hop name, judge whether the first-order repricing is over- or under-done
against the shock's *measured* transmission legs (Brent triplet, crack spreads, disclosed fuel
hedges, contract pass-through in filings), with the AI's value in the per-name magnitude call and
the pair/hedge construction, not in the sector call. Two things stop B itself from doing this today:
B is long-biased by construction (0 of ~108 theses ever short, so it cannot hold the loser leg), and
B's register row BINDS under `acute` (Rev 50, deliberately — B's long post-event drift carries beta
in a shock). The data say the override removes B from the one regime where a post-event drift is
measurably present, while B's construction could only take half of it.

### 8.3 Revised candidate for SL1 — a short-capable, shock-triggered sibling of B

| Element | Revised implication | Why |
|---|---|---|
| Mechanism | On a rubric-qualifying shock event, enumerate first-hop industries from a STATIC link map (BEA use table — never the model's recall), then per name judge over/under-reaction vs the measured transmission legs; express as hedged pairs (first-hop winner long / first-hop loser short, or either leg vs a sector/index hedge) | §8.2; event-study table 3 |
| Return driver | 1.1/1.4 on the *quality* of a realised reaction to known public information — B's own accepted trace — narrowed to shock-driven moves and extended to the short leg | rail (a) |
| Compensated disadvantages | 2.6 (public documents only), 2.12 (link map, beta, hedge ratio by code), 2.2 (multi-week horizon) | rail (a) |
| Structure | Hedged; net-long directional forbidden; mandatory short-leg stop set at entry (E's Rev 45 pattern) | SHOCK-NATIVE rail (i), 2.18 |
| Horizon | 2–6 weeks from onset; hard time-exit at 6 weeks | drift is spent by week 4–6 |
| Countable signal | one per rubric qualifying shock event × first-hop enumeration; band declared in qualifying events/yr (2026 to date: ≥ 2 structures, ≥ 6 events) | rail (iii) |
| Invalidation | rubric de-escalation legs close every open thesis; plus per-name public-information invalidation | rail (ii) |
| Router line | `shock_overlay ∈ {latent, acute}` AND VIX ≠ HIGH; trend and breadth unconstrained | hedge carries DOWN cells |
| Register row | SHOCK-NATIVE, exempt by class, no gate, horizon `status-quo` | Rev 50 |
| Differentiation vs B | short-capable; shock-triggered rather than single-name 5% event-day move; hedged; 2–6-week horizon; exempt under `acute` where B binds | rail (b) |
| Prior | +1.9% hedged per 4-week episode window, 4 of 6 episodes, n = 6 — a per-event prior, not a per-month one; costs ~0.4% round trip + borrow per pair | §6 restated |

### 8.4 Rails status after the study

| Rail | Status | What changed |
|---|---|---|
| (a) edge validity | PLAUSIBLE, now with a measured mechanical prior instead of none | the AI edge is the per-name magnitude judgment on top of a +1.9%/episode first-hop base; SL1 must show the judgment layer is more than the base |
| (b) structural difference | PASS vs A–E (short-capable, shock-triggered, hedged, 2–6 wk) | — |
| (c) non-redundancy | PASS — B binds under `acute` and cannot short | — |
| (d) cost fit | PLAUSIBLE (0.42% equity-pair round trip measured) | per-thesis at authoring |
| (e)/(f) | PASS | — |

### 8.5 What SL1 needs to do next (replaces §7)

1. Resolve the lead `interactive-2026-10-shock-first-hop-continuation-hedged` (OPEN; the second-hop
   lead is CLOSED with this outcome). Do not reopen the second-hop archetype on the same evidence.
2. Derive the first-hop enumeration as code over the BEA use table (static, point-in-time safe) and
   the per-name judgment protocol as judgment-native machinery (SL2 (A) 1b) with a declared
   conviction gate; the signal count is the rubric's qualifying events.
3. Declare the frequency in qualifying events/year and the 30-trade arithmetic (two trades per
   pair).
4. State the B relationship explicitly in the differentiation section: this is B's mechanism on the
   shock's first hop with a short leg, exempt under `acute` where B binds — and why that is not a
   B restart (it is additive machinery, not a B edit).
5. Still deliberately not done here: no candidate row, no Strategy.md section, no backtest with the
   model, no change to B's register row (which stays BINDS until an adversarial review says
   otherwise — `premortem-router-2026-a1`, enqueued 2026-10-19, asks exactly that question).

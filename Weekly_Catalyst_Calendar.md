2026-W36

# Weekly Catalyst Calendar — Strategies A and C

Run date **2026-09-06** (Sunday, the `weekly_sun` slot). Windows measured from the run date: **Strategy A = 6 months (2026-09-06 → 2027-03-06); Strategy C = 45 days (2026-09-06 → 2026-10-21).**

**EFFECTIVE CONFIRMED-EARNINGS HORIZON: ~12.6 weeks, to 2026-12-03 — the "6 months" above describes the window this file *searches*, not the horizon its bulk source *reaches*.** Beyond that cliff this file carries only per-name dates obtained from company IR pages and cadence projections, at `(C)`/`(2S)`/`(E)` provenance, for shortlisted names. See the COVERAGE STATEMENT before 1A.1 — **the constraint is materially wider than prior cycles recorded.** The horizon itself is a standing vendor-plan limit already logged in `Claude_Task_Plan.md` PART 1A, `ops/connector_tools.yaml` and `OWNER_ACTIONS.md` item `FMP-earn-horizon`; **no fresh alert is raised for it and none should be.**

**Marker.** `2026-W36` is the ISO week of this run date (Sun 2026-09-06 is weekday 7 of the Mon 08-31 → Sun 09-06 week) — the same week W2/W3 stamp this cycle, and the plain ISO week of today, which is what W4's upstream-freshness gate computes.

**Catch-up window.** `state.routine_catchup_window` for W1: `never_completed = false`, `window_days = 6.98` — below the weekly 1.5× threshold (10.5 days), so **no `CATCHUP[]` token is owed**. Evidence window: **2026-08-30 → 2026-09-06**.

**Trading-day context.** `state.trading_day_today`: today `2026-09-06`, `is_trading_day = false`, last trading day **2026-09-04**, next trading day **2026-09-08** — Mon 2026-09-07 is Labor Day. Every price, volatility and volume figure here is measured against the **2026-09-04** regular-session close unless stated otherwise.

> ### THE FIVE THINGS IN THIS FILE A READER SHOULD NOT MISS
>
> 1. **The Strategy C thesis's premium leg has TURNED, and it is the reverse of last cycle's read.** Last cycle the case for the 09-16 FOMC rested on cheap volatility: IV near the 0th percentile and an IV/HV ratio bracketing 1.0 tightly (0.914–1.006). Measured now, SPY ATM IV on the 09-18 expiry is **10.525% against HV10 of 8.578% and HV20 of 8.101% — ratios of 1.227 and 1.299.** For a 12-day structure those are the windows that matter, and implied is now clearly *richer* than realized. Absolute IV is still near its historical floor; realized has simply collapsed faster. **The premium metric now favours a defined-risk credit structure, not a long-premium one.** With the directional leg already having weakened last cycle, both legs have now moved against the original framing.
> 2. **And the compression that looks like the biggest signal is not one.** The ATM straddle fell from ±2.20% to ±1.796% week-over-week on the *same* 09-18 contract. But √(12/19) × 2.20% = **1.75%**. Essentially the entire move is the square-root-of-time term; the IV itself went 10.86% → 10.525%, about −3%. A thesis citing the shrinking straddle as evidence of under-priced risk is reading a calendar effect as an information effect.
> 3. **Every catalyst in September is unreachable for Strategy A — about a third of this file's dated content.** A is DO-NOT-ACTIVATE and nothing before the **2026-10-01** M1a/M1b re-score can change that, so any catalyst before ~2026-10-05 is SPENT-BY-GATE. **ORCL is the sharpest case:** its earnings date has been this file's flagship carry-forward for four cycles, was resolved this run to first-party certainty (**2026-09-10**, from Oracle's own "Sets the Date" release of 2026-09-02) — and lands **six days before the earliest epoch A could open.**
> 4. **A third phantom catalyst was struck, and this one was never scheduled at all.** **MRK's Winrevair HYPERION sBLA "PDUFA 2026-09-21" does not exist** — no such filing was found; the only sotatercept sBLA on record is a different, already-past one (ZENITH, PDUFA 2025-10-25). After META's "UTECA trial October 2026" (a one-year mis-projection) and "QCOM v. Arm 2026-10-05" (uncorroborated) last cycle, that is three consecutive cycles. The mechanical lesson: **a row that has sat at (2S) or below for two consecutive cycles is a claim to falsify, not a fact to re-carry.** Separately, three PDUFAs resolved as approvals — rusfertide 08-28, brepocitinib 08-26, and **zilganersen on 09-03, ahead of its own 09-22 date.**
> 5. **The FMP constraint is much wider than "a 13-week horizon."** Measured this run: `search-company-screener`, the entire `directory` tool, and `quote.batch-quote` are **all ACCESS DENIED** on this plan tier. **A true market-wide screen for "cap ≥ $2B and ADV ≥ $10M" is impossible at any call budget** — not a budget shortfall, a structural gate. The Strategy A "universe" in this file is the set of names the earnings feed happens to return plus names carried from prior per-name verification. It is a floor, not a screen.

---

## Regime and routing state (measured this run)

Read from `state.current_regime` at run time. The fundamental plane is M1a's 2026-09-01 scoring; the activation plane is the 2026-09-03 divergence-review cohort, which resolved all five reviews.

| Plane | Key | Value | As of |
|---|---|---|---|
| FUNDAMENTAL_AXIS | growth_momentum | decelerating | 2026-09-01 |
| FUNDAMENTAL_AXIS | inflation_trend | disinflating | 2026-09-01 |
| FUNDAMENTAL_AXIS | policy_stance | hawkish | 2026-09-01 |
| FUNDAMENTAL_AXIS | risk_sentiment | risk-on | 2026-09-01 |
| FUNDAMENTAL_AXIS | shock_overlay | **acute** | 2026-09-01 |
| STRATEGY_ACTIVATION | **A** | **DO-NOT-ACTIVATE** (unchanged) | 2026-09-03 |
| STRATEGY_ACTIVATION | B | DO-NOT-ACTIVATE (unchanged) | 2026-09-03 |
| STRATEGY_ACTIVATION | **C** | **HYBRID ACTIVATE (FOMC-only)** (unchanged) | 2026-09-03 |
| STRATEGY_ACTIVATION | D | DO-NOT-ACTIVATE (unchanged) | 2026-09-03 |
| STRATEGY_ACTIVATION | E | DO-NOT-ACTIVATE (**STATE CHANGE** from ACTIVATE) | 2026-09-03 |

**What this means for the two strategies this file serves.**

- **Strategy A is shut to new entries.** `div-A-202608-1` resolved 2026-09-03 and held A at DO-NOT-ACTIVATE for a third consecutive cycle. The technical call was ACTIVATE and the fundamental call DO-NOT-ACTIVATE; the orchestrator reached its verdict affirmatively rather than by default, finding that two independently-satisfied pre-committed router rules would force any raw ACTIVATE back to DNA. A stays `capital_disabled`. **The next scheduled opportunity for A to open is the 2026-10-01 M1a/M1b re-score** — there is no scheduled event between now and then that can flip it, so every A candidate in PART 2A is being ranked for an epoch that cannot begin before ~2026-10-01 at the earliest.
- **Strategy C is open, but only for FOMC.** `div-C-202608-1` resolved 2026-09-03 as CONTINUE HYBRID and affirmatively re-confirmed the FOMC-only carve-out rather than defaulting to it. The review recorded that broad ACTIVATE is **procedurally unreachable through a divergence review**: widening beyond FOMC-only is reserved to a separate scope-widening adjudication whose conditions (≥5 closed FOMC trades, or portfolio ≥ ~$25k) are unmet and none is open. C remains `capital_enabled` and is, as of 2026-09-04, **the only capital-enabled strategy in the book**.

**Consequence for how PART 2 must be read.** Exactly one row anywhere in this file is executable this cycle: the **2026-09-16 FOMC**. Every other C candidate is barred by the carve-out, not by rank; every A candidate is barred by the router, not by rank. Both facts are stated per-row rather than left for a downstream reader to rediscover.

### The C thesis is already enqueued — W4 must not enqueue it again

`events.queue_events` carries `thesis-FOMC-C-20260908` (`PENDING_ANALYSIS`, `strategy = C`, `item_type = thesis-construction`, `due_date = 2026-09-08`, status pending, `artifact_path = Weekly_Catalyst_Calendar.md`). D2 drains it on 2026-09-08. Its recorded conservative default is: decline if unresolved by 2026-09-15 (entry is required at least one trading day before the 2026-09-16 decision), or if no affirmative, sourced, quantified divergence from market pricing can be established.

W4's §D C-limb enqueues one `PENDING_ANALYSIS` row per top-tier C name. **The FOMC row is already live and must not be duplicated** — the 2026-08-30 W4 run resolved this correctly by matching to the existing row rather than minting a second one, and that is the behaviour to repeat.

### Positions and overlap (measured)

`state.current_positions` holds **zero open A, B, C and E positions**. The twelve open lots are all Strategy D (GOOGL ×2, AMZN ×2, TSM ×2, DIS ×2, UBER, ISRG, RTX, GEV). Consequences:

- The **A↔C simultaneous-holding constraint cannot bind any candidate in this file**, because there is nothing in either book to collide with. The per-candidate overlap field is therefore reported against the Strategy A *watchlist queue* and against the open D book, which is the only live exposure.
- Names carried in the open D book that also appear as A candidates below — **GOOGL, GEV** — are flagged where they appear. Strategy D and Strategy A are separate mandates and may hold the same name, so this is disclosure, not an exclusion.

The Strategy A watchlist queue (`state.open_queue`, queue `WATCHLIST`) currently holds 23 pending A rows: ADBE, AMD, AMZN, DDOG, DELL, GEV, GOOGL, HD, HPE, IBM, INTC, LLY, MRVL, MSFT, MU, OKTA, ORCL, QCOM, SMCI, SNOW, TGT, VRTX, WMT. Overlap with each shortlist candidate is marked in PART 2A field (d).

### Park state

The park vehicle is **VOO** as of 2026-09-03 (D1 BOUND SWITCH SGOV → VOO, re-risk, MEDIUM 60, executed by D2 the same day). This is context only — the park is D1/D2's surface, not W1's, and no row in this file bears on it.


---

## DAILY-TO-WEEKLY BOUNDARY — what D1 already owns, and one claimed gap that is not one

### The claimed gap, and why it is refuted

A discovery sub-agent this run reported that **"the 2026-09-04 session was never screened by D1"** and recommended W1 either cover Friday's tape itself or file an out-of-scope referral. **That claim is a false positive and was refuted before any of it was acted on.** It is recorded here rather than silently dropped, because it is a fresh instance of the exact failure `Claude_Task_Plan.md`'s RUN-LOG GAP INTERPRETATION bullet was written to prevent — and that bullet exists because **W1 itself** raised the original `cadence_outage` false alarm on 2026-08-23 (`ops.alerts` `f6ff58ee`), counting zero rows on a Friday and a Saturday and calling it a fleet-wide trigger outage. An operator email went out before W3 refuted it.

The sub-agent reproduced the error the same way: by reading raw `ops.run_log` row counts. The rule requires resolving a **single-routine** claim against `state.cadence_expected_history`, where a routine is missing only if `expected AND in_service AND rows_logged = 0`. Measured this run:

| routine | run_date | expected | in_service | rows_logged | verdict |
|---|---|---|---|---|---|
| D1 | 2026-08-30 | true | true | 2 | ran |
| D1 | 2026-08-31 | true | true | 2 | ran |
| D1 | 2026-09-01 | true | true | 2 | ran |
| D1 | 2026-09-02 | true | true | 2 | ran |
| D1 | 2026-09-03 | true | true | 2 | ran |
| **D1** | **2026-09-04 (Fri)** | **false** | true | 0 | **not expected — not a miss** |
| D1 | 2026-09-05 (Sat) | false | true | 0 | not expected — not a miss |
| D1 | 2026-09-06 (Sun) | true | true | 0 | expected today; W1 fires before D1 |

D1's `monitor_class` is `daily_sun_thu` (`dow NOT IN (6,7)`), so **Friday is not a D1 day by design.** Friday's tape is not unowned either: W2's own section records that *"D1's Sunday dynamic scan owns the Friday/Saturday gap before the next daily action cycle."* Today's D1 run is the scan that covers 2026-09-04, and it has not fired yet at W1's slot — `rows_logged = 0` for 2026-09-06 is W1 running first on a Sunday, not D1 failing.

**Consequence for this run: W1 does NOT cover Friday 2026-09-04's single-name or sector moves, and does not file a referral.** Doing either would duplicate D1's Sunday scan a few hours before it runs, which is the specific thing the daily-to-weekly boundary forbids. No `ops.alerts` row is raised; per the same bullet, a residual concern would go to `sp_log_decision`, and there is no residual concern here — the claim is simply wrong.

### Catalysts D1 already announced — reused, not re-searched

D1 completed five runs in the boundary window (2026-08-30 → 09-03, five of five expected days). Per the boundary rule, the following are taken from D1's records at D1's canonical date and source; W1 performed **no** announcement search for any of them.

| Ticker | Catalyst type | Date | Canonical source as D1 recorded it | D1 decision_log ref |
|---|---|---|---|---|
| — (rates) | FOMC decision, SEP-carrying | **2026-09-16** | CME FedWatch hike odds 39.9% → 57% → **65-66%**; Kalshi 59% | `611b5499-270e-4d85-b7da-912a5da21592` (2026-08-31) |
| PCG | Capex deferral + strategic review | ~2027 capex horizon; **no fixed decision date** | ~$2B 2027 capex deferral and strategic review announced 2026-09-02, after CA SB 492 died 2026-09-01 | `b606229e-1a83-455f-bcf8-cc9160dad805` (2026-09-03) |
| TSLA | Cybercab event (Austin, invite-only) | **2026-09-03** — now spent | D1 flagged the 08-31 +5.51% as anticipation of a scheduled catalyst, not a resolved one | `0c8ece63-9a7d-4845-a803-0622b30490dc` (2026-08-31) |
| UBER | Restructuring | Announced **2026-09-02**; no forward date | ~3,300 roles (~10% headcount) cut, management layers −20%, AV footprint 7 → 15 cities | `b57c82aa-2ae1-41b8-9e2b-43e66e023dc2` (2026-09-02) |
| AMZN | Capacity commitment | **2027-28** horizon; no dated event | AWS tripled its Nvidia GPU order to ~2M GPUs, ~$110B commitment | `ec0c9a26-7602-4518-bee0-032de9551956` (2026-08-30) |

**Only one of these is a dated forward catalyst W1 can calendar: the 2026-09-16 FOMC.** PCG, UBER and AMZN are announcements with no scheduled forward date — they are narrative inputs to PART 2A, not PART 1 rows. TSLA's event has already occurred inside the window.

**Nothing else with a new forward date surfaced in D1's window.** D1 recorded no new PDUFA, spin-off, investor-day, tariff or M&A date in the boundary window; the one M&A item (PYPL / Advent-Stripe) is a **collapsed** deal, not a forward one. So W1's forward-calendar acquisition below is genuinely W1-owned work, not a re-run of D1's.

### Movers D1 flagged — Strategy A context, carried not re-measured

Per the boundary rule W1 does not recompute these. Session-dated, from D1's screens:

- **2026-08-28**: PYPL −12.71% (Advent/Stripe take-private abandoned) · MRVL −10.28% (beat, soft FY28 guide) · IREN −12.53%, PCG −7.52%, COIN −6.33% (crypto + rates unwind) · ESTC +19.31% (beat + raise) · GAP +12.94% · AMZN +3.97% (AWS GPU order) · INTC −2.85% (Altera-sale reports) · RIVN −4.35% (CFO resignation)
- **2026-08-31**: EIX −23.07%, PCG −20.06%, SRE −3.10% — the CA SB 492 wildfire-liability bill failure is the whole session · TSLA +5.51% (Cybercab anticipation)
- **2026-09-01**: FRVO +28.41% · CRK +11.02% · PCG +5.95% (bounce) · AAL −3.57% (Hormuz → jet fuel) · NIO −4.02% (Q2 miss) · AAPL +2.61% (CEO transition effective; D1 flagged the attribution as unresolved)
- **2026-09-02**: CRDO −20.04%, MDB −13.54% (beats sold on margin anxiety) against DELL +15.81% (ISG +89%, guide raised) — D1's framing: *demand intact, the fight moved to margin* · PLTR −5.81% · PCG −5.19% (second-session persistence, refuting the prior day's "bounded" read) · RTX −2.13%
- **2026-09-03**: DELL +4.91%, HPE +5.04%, ORCL +5.69% — AI-infrastructure continuation

### Killed rows that must not be resurrected

The prior W1 completion (`0975eda6`, 2026-08-30) struck three phantom catalysts. No D1 entry in this window touched any of them, so there is nothing to reconcile — but they must not reappear:

- **META "UTECA trial, October 2026"** — does not exist; a one-year mis-projection of a trial held 1-2 October **2025** that already produced a ~€479M judgment.
- **QCOM v. Arm "trial begins 2026-10-05"** — uncorroborated by any source; a conflation of a case Qualcomm already won in 2025 with a separate undated suit.
- **FDX 2026-09-17 earnings** — a phantom the FMP feed still returns; FedEx changed its fiscal year end (May 31 → Dec 31, effective 2026-06-01) and has no quarterly call in the window.


---

## Past-window tape — what the eleven scheduled catalysts of 2026-08-31 → 09-04 actually produced

Every earnings date last cycle carried inside the week just closed has now resolved. This section exists because **PART 2A ranks on narrative-versus-price gaps, and a spent catalyst either closes a gap or widens it** — carrying a candidate forward without reading its own print is how a shortlist goes stale.

Reaction figures below are source-attributed approximations from financial media, **not** broker-measured closes. The exact regular-session closes and 5-bar returns are measured separately against IBKR daily bars (see the measurement table in PART 2A); where the two disagree, **the IBKR figure is the one that governs** — §19 PRICE BASIS names IBKR regular-session daily bars as the authority for any close this file gates on.

| Ticker | Date | Print vs consensus | Guidance — usually the mover | Reaction (approx.) | What it did to the gap |
|---|---|---|---|---|---|
| **DELL** | 09-01 AMC | Rev $47B (+58%), non-GAAP EPS $7.04 (+203%); ISG +89% to $31.8B; $60.9B AI orders, $95B AI backlog | FY raised to $192B rev / $25.50 EPS; Q3 $49.0B / $6.50 | **+16%** | Gap closed decisively bullish. The AI-server backlog *was* the bull case and it printed. |
| **PANW** | 09-01 AMC | Rev $3.41B (+34%, beat $3.35B); adj EPS $1.02 (beat $0.98); NGS ARR $9.10B (+63%) | FY27 EPS $4.16-4.19, rev $14.1-14.2B | **−9%** | Beat-and-raise sold. Priced-for-perfection setup; spend/margin dominated. |
| **NIO** *(ADR)* | 09-01 BMO | Deliveries 107,658 (+49.4%) but below guide; rev RMB32.1B (+69.1%), missed; adj EPS ¥0.01 vs est −¥0.21 | Q3 guide weak; JPM to Neutral, PT $7 → $4.50 | **−4%** → ~**−14%** on the week | Surprise profit overridden by revenue miss + weak guide. Not A-eligible (ADR). |
| **AVGO** | 09-02 AMC | Rev $29.6B (+86%); AI semis $16.7B (+221%); NI $13.09B / EPS $2.68 — but rev beat only ~0.5%, EPS ~2.5% | FY26 AI rev raised to $58B; FY27/28 $115B/$230B; **Q4 rev guide $34.8B vs $35.03B consensus — a miss** | **−5 to −6%** | Thin beat + guide miss punctured the premium. The standing AI-financing objection is not answered by this print. |
| **SNOW** | 09-02 AMC | Product rev $1.49B (+37%), total $1.55B (+35%); EPS $0.62 vs $0.26 est; NRR 126% | FY27 product rev raised $5.84B → $6.07B; Q3 $1.59B vs $1.50B consensus | **+21%**, held | Clean beat-and-raise. Gap closed bullish; sell-side PT hikes followed. |
| **HPE** | 09-02 | Record Q3 rev $12.2B (+34%), above high end of guide; non-GAAP EPS $1.11 vs $0.93 — fifth straight beat; orders +42%, AI orders +30% QoQ | FY26 EPS raised to $3.75-3.85; FY27 rev +13-17%, EPS $4.40-4.60, FCF ≥$5B | **+8.5%**, fresh 52-week high $58.79 | Gap closed bullish and the company gave a full FY27 frame a quarter early. |
| **NTAP** | 09-02 AMC | Rev $2.03B (+30%, beat $1.84B); non-GAAP EPS $2.58 (+66%); above high end of own guide | FY27 rev raised to $7.975-8.225B; EPS to $9.73-10.03 | **−8 to −10%** | **The most interesting row in the table.** Beat, raised, and fell — coverage attributes it to a free-cash-flow decline behind the headline beats (Barclays still raised PT to $219). This is a *created* gap, not a closed one. |
| **LULU** | 09-03 | Rev $2.4B (−4%), missed $2.46B; comps −9% (−10% cc); adj EPS $2.92 vs $1.82 est **but including a $0.86/sh one-time tariff refund** — ex-item ~$2.06 | **Cut hard**: FY rev $10.35-10.5B (−5 to −7%) vs $11.03B consensus; EPS $9.48-9.73 from $10.95-11.15; Q3 implies −10 to −11% | **−15 to −18%**, through the 52-week low | The guide, not the print, drove it. The headline "beat" was a tariff refund. Bear case confirmed. |
| **DOCU** | 09-03 | Rev $876M (+9%); non-GAAP op margin 31.6% (+180bps); IAM 15.1% of ARR from 12.6% | FY27 rev $3.499-3.507B (~9%); ARR growth raised to 8.5-9.0%; Q3 $886-890M | **+3.7%** | Steady beat-and-raise, no narrative shift. |
| **CPB** | 09-03 | Adj EPS $0.39 in line; net sales $2.14B slightly below $2.15B; gross margin −190bps to 28.6% on ~6% inflation | FY27 adj EPS **$1.65-1.80 vs $1.84 est**; organic sales −2 to −4%; **dividend cut 36%** to accelerate debt paydown | **−6.3%** premarket | Bearish confirmation. A dividend cut is a structural signal, not a quarter. |
| **RH** | — | **DID NOT REPORT** | — | — | **Correction.** Last cycle carried RH at `(!)` "09-03 or 09-10". It is **2026-09-10 AMC** — a forward catalyst for the coming week, not a spent one. |

### The pattern worth carrying into PART 2A

Nine of the ten actual prints beat. **Four of those nine fell anyway** — PANW −9%, AVGO −5/−6%, NTAP −8/−10%, and (on an ex-item basis) LULU. The 2026-08-28 tape D1 recorded showed the same shape (CRDO −20.04%, MDB −13.54%: *"beats sold on margin anxiety"*), and D1's own framing for the 09-02 session was **"demand intact, the fight moved to margin."**

That is a coherent, twice-observed cross-sectional regularity and it is **directly adverse to a naive Strategy A long-on-a-good-print thesis**: in this tape, a beat is not the operative variable. It also refines — rather than restores — the "beats keep landing, the tape sells them" objection last cycle narrowed to hardware/semicap after the 08-26/27 software rally. This week the selling hit software (PANW), semis (AVGO) and storage (NTAP) alike, while DELL, SNOW and HPE — all beat-and-*raise* with the raise on AI infrastructure — rose hard.

The discriminator this week was not sector and not the beat. It was **whether the guide went up and whether cash conversion held**. NTAP is the clean instance: it raised guidance and still fell, on cash flow. Any A thesis ranked below that leans on "the print will be good" must answer this.

### Carry-forwards closed and left open

- **ORCL — CLOSED after four cycles.** Oracle's Q1 FY27 report is **Thursday 2026-09-10, after market close** (call 5:00 p.m. ET). Verified directly against Oracle's own "Oracle Sets the Date…" release on `investor.oracle.com`, published **2026-09-02** — a primary source, not an aggregator inference. The 09-08 / 09-10 / 09-14 split is resolved to **09-10 (C)**. This also means the prior cycle's #1-ranked A candidate finally has a datable catalyst, and that ORCL and RH report the same day.
- **NVO denecimig (Mim8) — still open, but tightened.** BLA submitted 2025-09-29; **no FDA action taken** as of 2026-09-06 (searched for approval and CRL, found neither); **no official PDUFA date has ever been published** by Novo Nordisk or FDA. The closest available is a pharmacy-benefit-manager pipeline tracker (Prime Therapeutics, published 2026-06-15) citing an expected decision window of **Q3 2026** — an industry tracker's estimate, not a company or FDA date. Carried at `(E)` and flagged: Q3 2026 ends this month, so a decision could land inside this file's window without a date ever having been announced.
- **FDA advisory committees — re-checked, unchanged.** Two FDA notices stand for the window: the **GRAIL / Galleri** Molecular and Clinical Genetics Panel on **2026-09-23** (notice published 2026-08-10 — the same panel known last cycle, not a new date), and a **Pediatric Advisory Committee** virtual meeting on **2026-09-16**, which the surfaced notice describes as general pediatric regulatory issues and not sponsor- or product-specific. **No October 2026 FDA AdCom for a US-listed sponsor has been noticed yet.** Committees found on October dates (Office of AIDS Research 10-22, Research on Women's Health 10-20, NIOSH radiation-worker 10-28) are NIH/HHS/NIOSH bodies, not FDA sponsor-review AdComs, and are excluded. Coverage here is structurally incomplete by design — the Federal Register lead time is ~15-75 days, so October notices can post any day; this is a re-check next cycle, not a gap to alert on.


---

## PART 1A — Strategy A universe catalyst calendar (6-month window, 2026-09-06 → 2027-03-06)

Universe rails per `strategy/03_strategy_a.md`: **US-listed common equity, market cap ≥ $2B at entry, 30-day average daily volume ≥ $10M.** Long-only; no options (an options-shaped thesis belongs in C). **ADRs are not A-eligible** per W4's 2026-08-09 ruling — they appear below tagged `ADR` for calendar completeness and are excluded from PART 2A.

No interpretation in this PART.

> ### COVERAGE STATEMENT — read before using the tables. The vendor constraint is WIDER than previously recorded.
>
> **The horizon itself has not moved — it rolled, exactly as a rolling window should.** Measured this run by direct probe: the latest earnings date FMP returns anywhere is **2026-12-03** (DOCU), which is 88 days / ~12.6 weeks from the run date. Last cycle the same probe returned 2026-11-24 from a 2026-08-30 vantage — 86 days / ~12.3 weeks. The window advanced 9 days as the calendar advanced 7. **This is the documented ~13-week forward-only rolling window behaving normally, not a change in the constraint, and it is therefore not a run-note finding.** Probes: 2026-12-16→12-31 returned **0 rows**; 2027-01-15→02-15 returned **0 rows**; the historical probe 2026-01-26→01-30 returned `ACCESS DENIED` verbatim, so the "project last year's actual report dates forward" fallback remains unavailable.
>
> **What IS new, and is a genuine finding: the plan gate is far broader than a date cliff.** Measured this run, on this FMP tier:
>
> | FMP surface | Result |
> |---|---|
> | `search.search-company-screener` | **ACCESS DENIED** — requires Starter/Premium/Ultimate/Enterprise |
> | `directory.*` (all endpoints) | **ACCESS DENIED** — same tiers |
> | `quote.batch-quote` | **ACCESS DENIED** — requires Premium/Ultimate/Enterprise |
> | `quote.quote` (single symbol) | works, 1 request per symbol |
> | `company.profile-symbol` | works, no batch form |
> | `calendar.earnings-calendar` (forward) | works, allow-listed subset only |
>
> **Consequence, stated plainly: a true market-wide screen for "market cap ≥ $2B and 30-day ADV ≥ $10M" is IMPOSSIBLE on this plan at any call budget.** This is not a budget shortfall and not a transient failure. Prior cycles framed the constraint as a date cliff plus a ~78-87 name symbol allow-list; the allow-list is real (this run's full forward pull returned **77 unique symbols** across seven slices) but it is a *symptom*. The actual gate is that every bulk-enumeration surface is denied, leaving only one-symbol-at-a-time lookups. **The Strategy A "universe" in this file is therefore not a screened universe — it is the set of names the earnings feed happens to return, plus names carried forward from prior cycles' per-name IR verification.** Downstream readers must treat it as a floor.
>
> This is recorded here and belongs in `OWNER_ACTIONS.md` item `FMP-earn-horizon`, whose framing ("raise the tier or accept the gap") is narrower than what is actually gated. **No fresh `ops.alerts` row is raised for the horizon** — `37a4de80` already covers it and a weekly re-raise is alarm fatigue. The *screener* denial is a distinct and previously unrecorded fact and is referred once, in the OUT-OF-SCOPE section.
>
> **Eligibility verification is correspondingly partial.** Of 77 symbols on the feed, 46 were individually checked against both rails this run before the 60-request ceiling was reached: **43 passed, 3 failed** — TLRY ($503M), FUBO ($1.23B), LCID ($1.49B), all below the $2B floor and excluded. **31 symbols were not re-checked** and are marked `NOT VERIFIED` in the tables: they are large, liquid, long-established index constituents almost certainly past both rails, but that is an inference, not a measurement, and is not written as one.
>
> Two further feed limitations, both verified as properties of the whole payload rather than per-row gaps: **no report-time (bmo/amc) field exists** on this plan, so every FMP-sourced row is `unknown` for timing; and **sector/industry could not be pulled** for any row (`company.profile-symbol` has no batch form and was unaffordable alongside the calendar slices).

**Status vocabulary** (unchanged from prior cycles): **(C)** confirmed against the company's own IR release or SEC filing · **(2S)** two independent sources agree, no company release located · **(E)** single-source or cadence estimate · **(!)** sources disagree, all candidate dates shown · **ADR** — listed for completeness, not Strategy A eligible.

### 1A.1 — Earnings catalysts inside the Strategy C 45-day window (2026-09-06 → 2026-10-21)

| Date | Ticker | Company | Fiscal Q | Status / source |
|---|---|---|---|---|
| ~2026-09-08/09 | GME | GameStop | Q2 FY26 | **(!)** sources split; GameStop does not pre-announce. Unchanged |
| 2026-09-09 | CHWY | Chewy | Q2 FY26 | **(C)** investor.chewy.com |
| **2026-09-10** | **ORCL** | **Oracle** | **Q1 FY27** | **(C) — RESOLVED AFTER FOUR CYCLES.** Oracle's own *"Oracle Sets the Date…"* release, investor.oracle.com, published 2026-09-02; results after the close, call 5:00pm ET. The 09-08 / 09-10 / 09-14 split is closed |
| **2026-09-10** | **RH** | **RH** | **Q2 FY26** | **(C) — RESOLVED.** RH did **not** report in the week just past; last cycle's "09-03 or 09-10" split settles at **09-10 AMC**. Market cap is near the $2B floor — verify before any A use |
| 2026-09-10 | ADBE | Adobe | Q3 FY26 | **(2S)** — FMP feed corroborates the carried date. **Third consecutive cycle with no Adobe IR release located** |
| 2026-09-11 | KR | Kroger | Q2 FY26 | **(C)** ir.kroger.com |
| ~~2026-09-17~~ | ~~FDX~~ | ~~FedEx~~ | — | **STRUCK — phantom.** See the FedEx note below |
| 2026-09-22 | AZO | AutoZone | Q4 FY26 | **(C)** globenewswire 2026-08-24 |
| 2026-09-23 | GIS | General Mills | Q1 FY27 | **(C)** businesswire 2026-08-26 |
| ~2026-09-23/24 | CTAS | Cintas | Q1 FY27 | **(E)** cadence only; no FY27 announcement located |
| 2026-09-24 | COST | Costco | Q4 FY26 | **(C)** investor.costco.com; FMP corroborates. Cap $406.1B, ADV $1,879.9M — both rails verified |
| 2026-09-24 | DRI | Darden Restaurants | Q1 FY27 | **(2S)** |
| 2026-09-24 | JBL | Jabil | Q4 FY26 | **(2S)** |
| ~2026-09-29/30 | PAYX | Paychex | Q1 FY27 | **(E)** cadence only |
| 2026-09-30 | MU | Micron | Q4 FY26 | **(C)** globenewswire 2026-08-26 |
| ~late Sept | ACN | Accenture | Q4 FY26 | **(E)** cadence only |
| 2026-10-01 | NKE | Nike | Q1 FY27 | **(C)**; FMP corroborates |
| ~2026-10-01 | STZ | Constellation Brands | Q2 FY27 | **(E)** single-source |
| 2026-10-05 | CCL | Carnival | Q3 FY26 | **(2S)**; FMP corroborates. Cap $32.2B, ADV $380.3M verified |
| 2026-10-08 | DAL | Delta Air Lines | Q3 2026 | **(2S)** — FMP resolves last cycle's "~10-08/12" to 10-08. Cap $52.7B, ADV $406.5M verified |
| 2026-10-08 | PEP | PepsiCo | Q3 2026 | **(2S)**; FMP corroborates |
| 2026-10-08 | ~~TLRY~~ | Tilray | Q1 FY27 | **INELIGIBLE** — market cap $503M, measured. Below the $2B floor |
| 2026-10-13 | JPM | JPMorgan Chase | Q3 2026 | **(C)** from JPM's own multi-quarter 2026 date release. Cap $961.0B, ADV $1,745.9M verified |
| 2026-10-13 | JNJ | Johnson & Johnson | Q3 2026 | **(E)** feed. Cap $663.3B, ADV $1,067.7M verified |
| 2026-10-13 | GS · C · WFC | Goldman · Citigroup · Wells Fargo | Q3 2026 | **(E)** feed; not individually verified against company IR |
| 2026-10-14 | BAC | Bank of America | Q3 2026 | **(C)** from BAC's own 2026 reporting-dates release |
| 2026-10-15 | TSM | Taiwan Semiconductor | Q3 2026 | **(E)** · **ADR — not A-eligible** |
| 2026-10-20 | GE | GE Aerospace | Q3 2026 | **(E)** feed. Cap $349.8B, ADV $825.0M verified |
| 2026-10-20 | GM · KO · LMT · NFLX · VZ | — | Q3 2026 | **(E)** feed |
| 2026-10-21 | UAL | United Airlines | Q3 2026 | **(E)** feed. Cap $36.2B, ADV $326.2M verified |
| 2026-10-21 | T | AT&T | Q3 2026 | **(E)** feed |
| ~2026-10-21/22 | GEV · IBM | GE Vernova · IBM | Q3 2026 | **(E)** cadence — **absent from the FMP feed entirely** |

**The FedEx correction — a prior-cycle withdrawal that went one step too far.** Last cycle withdrew FDX outright for a second time, on the correct finding that FedEx changed its fiscal year end from May 31 to December 31 effective 2026-06-01 and therefore has no quarterly call on the old cadence. This run the FMP feed returned FDX **twice** — 2026-09-17 *and* 2026-10-28 — five weeks apart with distinct estimates, which the population agent flagged as anomalous rather than silently deduplicating. It is not simply a duplicate. Checked directly: FedEx will report results for the **seven-month transition period 2026-06-01 → 2026-12-31 on a Transition Report Form 10-K**, moving to calendar-year reporting from FY2027, and its **next earnings report is ~2026-10-29**. So:

- **2026-09-17 is the phantom** — the stale old-cadence date, correctly struck, now for the third cycle.
- **2026-10-28/29 is a REAL reporting event** under the new calendar, and last cycle's blanket withdrawal wrongly removed it. It is restored to §1A.2 at **(!)** — FMP says 10-28, the corroborating search says 10-29, and no FedEx IR release giving the exact date was located.

The general lesson is worth stating because it is the mirror image of this cycle's other errors: **a correct finding about why one date is wrong does not license striking every date for that name.** The fiscal-year change invalidated the September row and simultaneously *created* an October one.

### 1A.2 — Earnings catalysts, 2026-10-22 → 2026-12-03 (where the bulk feed still reaches)

Cap/ADV shown only where FMP verified them this run; `NV` = NOT VERIFIED, meaning not measured, not "failed".

| Date | Ticker(s) | Status |
|---|---|---|
| 2026-10-22 | INTC · F | (E) feed · NV |
| 2026-10-22 | AAL | (E) feed. Cap $8.7B, ADV $972.3M verified |
| 2026-10-22 | NOK | (E) feed · **ADR**. Cap $54.2B verified |
| 2026-10-23 | HCA | (E) feed. Cap $87.7B, ADV $376.3M verified |
| 2026-10-27 | UNH · V | (E) feed. UNH cap $360.7B / ADV $1,917.2M; V cap $700.3B / ADV $1,730.5M — verified |
| 2026-10-27 | CARR · SOFI | (E) feed. CARR $49.2B/$259.7M; SOFI $23.4B/$520.8M — verified |
| 2026-10-27 | PYPL | (E) feed · NV |
| 2026-10-28 | GOOGL · META · MSFT · TSLA | (E) feed. All four verified: GOOGL $4,096.1B/$7,054.3M · META $1,571.2B/$9,712.1M · MSFT $3,710.6B/$8,713.8M · TSLA $1,398.5B/$22,862.7M |
| 2026-10-28 | BA · SBUX | (E) feed · NV |
| **2026-10-28 or 10-29** | **FDX** | **(!) RESTORED** — first report under the new calendar-year cadence. FMP 10-28 vs corroborating search 10-29; no FedEx IR release located |
| 2026-10-29 | AAPL · AMZN | (E) feed. AAPL $4,699.5B/$12,246.7M · AMZN $2,780.8B/$7,748.0M — verified |
| 2026-10-29 | COIN · RBLX · RIOT · RKT | (E) feed. All four verified, caps $8.2B-$48.7B |
| 2026-10-30 | XOM · ABBV | (E) feed. XOM $660.9B/$2,537.3M · ABBV $452.9B/$1,197.9M — verified |
| 2026-10-30 | CVX | (E) feed · NV |
| 2026-11-02 | PLTR | (E) feed · NV |
| 2026-11-03 | AMD · SHOP · UBER | (E) feed · NV |
| 2026-11-03 | PFE · PINS · RIVN · SIRI | (E) feed. PFE $162.2B/$669.4M · PINS $13.0B/$204.2M · RIVN $19.1B/$218.8M · SIRI $9.8B/$92.1M — verified |
| 2026-11-04 | ET · ETSY · HOOD · MGM · ROKU · SNAP | (E) feed. All six verified; HOOD $109.8B/$2,886.1M is the largest |
| 2026-11-05 | MRNA | (E) feed · NV |
| 2026-11-10 | SONY | (E) feed · **ADR** · NV |
| **2026-11-11 or 11-12** | **CSCO** | **(!) — NEW DISAGREEMENT.** FMP feed says **11-11**; last cycle carried **11-12 at (C)** from newsroom.cisco.com. **The company release governs: 11-12 (C).** Recorded because it is a measured instance of the feed disagreeing with first-party IR, which bears on how much weight (E)-feed rows deserve elsewhere in this table |
| 2026-11-12 | BILI | (E) feed · **ADR**. Cap $6.4B verified |
| 2026-11-12 | DIS | (E) feed · NV |
| 2026-11-17 | BIDU | (E) feed · **ADR**. Cap $33.8B verified |
| 2026-11-18 | NVDA | (E) feed. Cap $5,579.6B, ADV $30,462.0M verified — the largest on the feed |
| 2026-11-18 | TGT | (E) feed · NV |
| 2026-11-19 | WMT | (E) feed. Cap $852.6B, ADV $2,055.8M verified |
| 2026-11-23 | ZM | (E) feed. Cap $29.7B, ADV $353.9M verified |
| 2026-11-24 | BABA | (E) feed · **ADR** · NV |
| 2026-11-24 | NIO | (E) feed · **ADR**. Cap $9.4B verified |
| **2026-12-03** | **DOCU** | (E) feed. Cap $13.1B, ADV $542.6M verified. **This is the last date the feed reaches** |

**Names with confirmed or cadence-projected dates in this span that the FMP feed does not carry at all** — carried from prior cycles' per-name verification, all **(E)** cadence unless noted: MU Q1 FY27 ~12-16 · CRWD ~12-01 (2S) · NTAP Q2 FY27 **2026-12-01 (C)**, stated in NetApp's own Q1 release · MRVL ~12-01/02 · OKTA ~12-02 (2S) · CRM ~12-02/03 · HPE ~12-03/04 · ORCL Q2 FY27 ~12-09/10 · ADBE Q4 FY26 ~12-09/10 · AVGO Q4 FY26 ~12-10 · KR and COST early Dec (low confidence) · NKE Q2 FY27 ~12-17/18 · SNOW **(!)** 11-27 or ~12-02/03. Also absent from the feed across the whole window: **CAT, GEV, SMCI, DDOG, AMAT, CRWV, NBIS, NOW, VRTX, LLY, MRK, IBM, QCOM, AKAM, TTWO, FSLR, HD, CTVA** — the same absentee set as last cycle, re-confirmed.

### 1A.3 — The 2026-12-04 → 2027-03-06 tail, filled per-name for shortlisted names only

Beyond the feed's reach. Every row is a cadence projection off the company's own prior-year date unless marked otherwise, and **none of these may be used to date an options structure or a catalyst-timed entry.** That companies have not yet announced December-to-February dates from a 2026-09-06 vantage is normal — they typically announce two to four weeks ahead — and is a property of the calendar, not a research failure.

| Date | Ticker | Fiscal Q | Status |
|---|---|---|---|
| 2026-12-16 | MU | Q1 FY27 | (E) vendor-inferred |
| 2026-12-17/18 | NKE | Q2 FY27 | (E) cadence |
| 2027-01-13/14 | JPM | Q4 2026 | (E) cadence |
| 2027-01-14/15 | GS | Q4 2026 | (E) cadence |
| 2027-01-14/15 | TSM | Q4 2026 | (E) cadence · **ADR** |
| 2027-01-21/22 | INTC | Q4 2026 | (E) cadence |
| 2027-01-27 | MSFT | Q2 FY27 | (E) cadence |
| 2027-01-27/28 | META · GEV · IBM | Q4 2026 | (E) cadence |
| 2027-01-28 | AAPL | Q1 FY27 | (E) cadence |
| 2027-01-28 | CAT | Q4 2026 | (E) cadence |
| 2027-02-02/03 | AMD | Q4 2026 | (E) cadence |
| 2027-02-03/04 | GOOGL | Q4 2026 | (E) cadence |
| 2027-02-05 | AMZN | Q4 2026 | (E) single-source |
| 2027-02-24 | HD | Q4 FY26 | (E) cadence |
| 2027-02-25 | NVDA | Q4 FY27 | (E) cadence — prior three years landed 2/21, 2/26, 2/25 |

**Newly reachable this cycle because the window rolled forward one week:** the span 2027-02-28 → 2027-03-06 is now inside the 6-month window and was outside it last cycle. **No confirmed or projected earnings date was located inside that new week** — early March is a genuinely quiet stretch for large-cap reporters, falling between the Q4 season that ends in late February and the Q1 season that begins in mid-April. Recorded as an affirmative "nothing found," not as an unexamined gap.

**Not reached at all:** TTWO, FSLR, MRK and DELL have no located date beyond 2026-10-21. TTWO and FSLR are ranked on non-earnings catalysts (see §1A.4 and §1A.6) so this does not blind them; **MRK and DELL are genuine holes** — DELL notably so, having just printed the strongest beat-and-raise of the week just past with no next date available.


### 1A.4 — Product launches, keynotes and product events

| Date | Ticker | Event | Status |
|---|---|---|---|
| 2026-09-09 | AAPL | Hardware keynote, Apple Park — "Surprise and Shine"; iPhone 18 Pro / Pro Max and a first foldable expected; first Ternus-led keynote | **(2S)** — invites went out 2026-08-26. Corroborated by two trackers; no Apple newsroom page located giving the date |
| 2026-09-15 → 09-17 | CRM | Dreamforce 2026, Moscone Center SF — Agentforce announcements expected | **(C)** |
| 2026-09-23 → 09-24 | META | Meta Connect 2026 — AI / VR / wearables | **(C)** — **upgraded from (E)**; last cycle could not re-verify it before its search budget ran out |
| 2026-10-20 → 10-22 | NVDA | GTC Berlin | **(E)** — carried, not re-verified |
| 2026-10-25 → 10-28 | ORCL | Oracle AI World / CloudWorld 2026 | **(C)** — **upgraded from (E)** |
| 2026-11-10 → 11-12 | ADBE | Adobe MAX 2026 | **(E)** — carried, not re-verified |
| 2026-11-17 → 11-20 | MSFT | Microsoft Ignite 2026 | **(C)** — **upgraded from (E)** |
| **2026-11-19** | **TTWO** | **GTA VI launch** (PS5, Xbox Series X\|S); pre-load opens 11-12 | **(2S)** reaffirmed. The single largest dated non-earnings binary in the window |
| 2026-11-30 → 12-04 | AMZN | AWS re:Invent 2026 | **(C)** — **upgraded from (E)** |
| 2026-11-30 → 12-03 | NVDA | GTC Washington DC | **(E)** — carried, not re-verified |
| 2026 (year-level only) | GOOGL | Waymo multi-city robotaxi launches — Dallas, Houston, San Antonio, Miami, Orlando | **(T)** — no day-level date published per city |
| 2027-01-06 → 01-09 | broad | CES 2027, Las Vegas | **(E)** — carried, not re-verified |

**Dropped as out-of-window:** NVDA **GTC 2027** is confirmed for **2027-03-15 → 03-18**, which falls after this window's 2027-03-06 close. It is named here so a future cycle does not treat it as newly discovered — it is known and simply not yet reachable.

Four rows that last cycle downgraded from (C) to (E) purely because its search budget ran out (META Connect, ORCL CloudWorld, MSFT Ignite, AMZN re:Invent) have been **re-verified and restored to (C)** this run. Three remain at (E) — NVDA's two GTC events and Adobe MAX — and CES 2027 stays (E); these are carried, and the fact that they are carried rather than checked is stated rather than hidden.

### 1A.5 — Analyst days, investor days and major conferences

| Date | Ticker | Event | Status |
|---|---|---|---|
| 2026-09-10 | LH | Labcorp Investor Day, 9am–12pm ET | **(C)** ir.labcorp.com |
| 2026-09-16 | ON | onsemi Financial Analyst Day, NYC | **(C)** onsemi.com |
| 2026-09-17 | INTU | Intuit Investor Day, 8:00am–12:00pm PDT | **(C)** investors.intuit.com — re-verified first-party for a second consecutive cycle |
| 2026-09-17 | DCO | Ducommun (~$3.1B) Investor Day, NYC | **(C)** |
| 2026-10-13 | BGC | FMX (BGC Group) first-ever Investor Day, NYC; Geoffrey Hinton keynote | **(C)** businesswire |
| **2026-10-13** | **WDAY** | **Workday Financial Analyst Day**, held at Workday Rising | **(C) NEW** — newsroom.workday.com release dated **2026-09-01**, i.e. announced inside this cycle's own boundary window |
| "Fall 2026" | NKE | Nike investor day | **(T)** — no specific day published; single low-quality source |
| ~early Dec 2026 | UNH | UnitedHealth investor conference | **(E)** — projected from a firm annual early-December cadence (2024 edition was Dec 4) |
| **2027-02-22** | **JPM** | **JPMorganChase Investor Day** | **(C) NEW** — company release syndicated via Nasdaq, 2026-06-15. Context: JPM held a placeholder "Company Update" on 2026-02-23 precisely *because* it was deferring its investor day to Q1 2027 |

This category was the thinnest in the first research pass (two rows, neither day-level) and was re-run against IR-calendar surfaces rather than broad search. **Three day-level, primary-sourced additions resulted.** Targeted searches for investor days at GM, Wells Fargo, Caterpillar, Deere, Costco, Visa and American Express found **none announced** in the window — Caterpillar's most recent ("The Next 100 Years") was 2025-11-04, before the window, with no follow-up announced. That is an affirmative negative, not an unsearched gap.

### 1A.6 — Regulatory, legal, trade and policy decisions

| Date | Ticker(s) | Event | Status |
|---|---|---|---|
| 2026-09-29 | GOOGL | DOJ v. Google **search**-remedies appeal — Google's reply brief due (D.C. Cir.); oral argument unscheduled | **(C)** |
| 2026-09-30 | BMY | Camzyos adolescent oHCM sNDA PDUFA — see §1B.3 | **(2S)** |
| 2026-09-30 | broad | US government funding deadline; Senate-passed CR ran to 2026-12-11 | **(E)** — live process; bears on October BLS/BEA print reliability |
| **2026-10-02** | **GOOGL** | **DOJ v. Google ad-tech — deadline for a joint proposed Final Judgment**, following Judge Brinkema's 2026-09-02 remedies ruling (Google spared a breakup; operational changes ordered) | **(C) NEW** — a genuinely new dated catalyst created inside this cycle's own boundary window. Distinct from the search case above |
| 2026-10-04 | MRK | Welireg + Lenvima advanced-RCC sNDA PDUFA — see §1B.3 | **(C)** |
| 2026-10-10 | MRK | Ifinatamab deruxtecan ES-SCLC BLA PDUFA — see §1B.3 | **(C)** |
| 2026-10-16 | V | DOJ v. Visa — fact discovery closes (expert to 2027-04-08); **no trial date set** | **(C)** |
| 2026-10-17 | VTRS | MR-141 presbyopia sNDA PDUFA — see §1B.3 | **(C)** |
| by Oct 2026 | AAPL | Company-stated deadline to update App Store terms for EU DMA compliance | **(C)** as a commitment; no fixed day |
| 2026-11-10 | broad China-import-exposed | USTR Section 301 China-tariff exclusions (178 products) expire 11:59pm ET 11-09 absent extension | **(C)** ustr.gov |
| 2026-11-18 | UNP · NSC | STB UP–NS review: public comments due | **(C)** |
| **2026-11-30** | **VRTX** | Povetacicept BLA PDUFA, IgA nephropathy, Priority Review | **(C)** news.vrtx.com — company release |
| 2026-12-03 | UNP · NSC | STB UP–NS: DOJ / USDOT preliminary comments due | **(C)** |
| 2026-12-04 | FSLR + solar chain | Section 232 tariff / minimum-import-price regime effective (polysilicon $21/kg, ingots-wafers $100/kg, cells $0.22/W, modules $0.38/W) | **(C)** whitehouse.gov |
| by year-end 2026 | BA | FAA type-certification of 737 MAX 10 | **(T)** — FAA guidance, no fixed day |
| late 2026 | NVO | FDA decision on CagriSema NDA | **(T)** company guidance, no PDUFA day published · **ADR — not A-eligible** |
| **2027-01-21** | **DYN** | z-rostudirsen BLA PDUFA, DMD exon 51, Priority Review | **(C) NEW** — company-reported off the FDA BLA acceptance (July 2026) |
| 2027-02-16 | UNP · NSC | STB UP–NS: responses to comments/protests due | **(C)** |
| **2027-02-28** | **BMRN** | VOXZOGO (vosoritide) sNDA — full approval in achondroplasia | **(C) NEW** biomarin.com |
| **2027-02-28** | **SRPT** | AMONDYS 45 / VYONDYS 53 sNDAs, DMD | **(C) NEW** — **cap ~$2.14B, immediately at the $2B floor** after a heavy decline. Verify current cap before any A use |
| ~2027-02 | LYV | DOJ / states v. Live Nation — remedies phase, estimated and unscheduled | **(E)** |
| **2027-03-02** | **WBD** (acquirer PSKY) | States' antitrust trial over the Paramount Skydance–WBD merger begins — **judge-set date** | **(C) NEW** |

**Out of window, named so it is not rediscovered:** the FTC v. Amazon trial (~2027-03-29) falls after 2027-03-06, as it did last cycle.

**The 2027 tail is no longer empty.** Last cycle's regulatory table stopped at 2027-02-16 with a single (E) row beyond it. Four confirmed 2027 dates now sit in the window (DYN 01-21, BMRN 02-28, SRPT 02-28, WBD 03-02), which matters disproportionately because §1A.3 showed the *earnings* tail cannot be filled at all past ~2026-12-03. **For the last quarter of this window, regulatory and legal dates are the only confirmed catalysts available** — a structural fact about what Strategy A can even be timed against in Jan–Mar 2027.

### 1A.7 — Restructuring and structural events

| Date | Ticker(s) | Event | Status |
|---|---|---|---|
| 2026-09-18 | broad S&P 500 | Q3 quarterly index rebalance (third Friday; effective ~09-21 open) | **(E)** |
| Q4 2026 | CTVA | "Vylor" seed/genetics spin-off completion | **(T)** — a **quarter, not a date**. Corteva's own releases (05-04, 06-29, 08-06) say only "on track for Q4 2026." Last cycle's demotion stands |
| 2H / by year-end 2026 | KMB · KVUE | Kimberly-Clark / Kenvue merger close; shareholder votes already passed 2026-01-29; outside date 2026-11-02, auto-extending to 2027-05-03 | **(T)** — no exact day |
| 2026-09 → 2027-03 | TECK | Anglo American–Teck final approvals; China MOFCOM the last pending item | **(C)** angloamerican.com |
| mid-Dec 2026 | broad Nasdaq-100 | Annual reconstitution, effective before the open on the third Friday | **(E)** — mechanism date only |
| 2026-12-18 | broad S&P 500 | Q4 quarterly index rebalance | **(E)** |
| 2027-01-01 | DG | CEO transition — Fleeman becomes CEO; Vasos senior advisor to 2027-04-02 | **(C)** |
| upon 2026 10-K filing | BA | SVP Finance Shedd succeeds Cleary as Controller | **(C)** 8-K Item 5.02, disclosed 2026-08-21 |

**Resolved during the week just past — moved out of the forward calendar.** Three CEO transitions this file carried as forward catalysts took effect **2026-09-01** and are now history: **AAPL** (Ternus succeeds Cook; Cook to Executive Chairman), **COP** (O'Brien succeeds Lance), **TFC** (Lyons succeeds Rogers). D1 measured AAPL +2.61% on 2026-09-01 and explicitly flagged the attribution as unresolved — the keynote on 09-09 is the nearer catalyst and the two are entangled.

**The structural-narrative category is genuinely thin, and that is not a research failure.** Two sub-categories were pursued and both are structurally unavailable right now:

- **IPO lockup expiries** require a company to have already priced. The two most visible 2026 candidates have not: **Wella (WELA)** filed 2026-08-31 with no price range, offer size or trade date; **Panera Brands** remains a confidential S-1 with no public terms. Medline's lockup already expired 2026-06-15, before the window. Other Oct–Nov 2026 lockups found (Avalyn, Hemab, Seaport, CH4) carry $60M–$300M deal sizes implying caps far below the $2B floor and volumes unlikely to clear $10M ADV; they were not individually confirmed and are named here rather than silently omitted.
- **Index reconstitution** additions and removals are announced by S&P and Nasdaq only about a **week before** they take effect. The December 2026 mechanism dates are known and are in the table; **no company-specific addition or removal for Oct 2026 – Mar 2027 has been announced by anyone yet.** Nothing citable exists at this vantage.

Last cycle's **SPCX lockup expiry (2026-12-08)** row is **struck**: it was tagged (C) but its own cited source said the lockup expired 2026-08-06, and a follow-up found SpaceX's lockup is not a single date at all but a staged release — an initial tranche, a 180-day tranche, an "extended group" running into 2027, and a separate longer lock on Musk's block. No single clean in-window date is sourceable. A row whose date contradicts its own citation cannot stand.


---

## PART 1B — Strategy C universe catalyst calendar (45-day window, 2026-09-06 → 2026-10-21)

Strategy C admits **only three event types**, from named sources: corporate earnings releases (US-listed, confirmed date from company IR), FDA PDUFA dates (FDA calendar or company disclosure), and FOMC meetings (confirmed Fed calendar). Analyst days, product launches, conferences, M&A, legal rulings and index rebalances are **excluded at the strategy level** and do not appear here, even though several sit in PART 1A for Strategy A.

No interpretation in this PART. Ranking is PART 2B.

### 1B.1 — FOMC

| Meeting | Decision day | SEP? | Press conf. | Status | Source |
|---|---|---|---|---|---|
| **2026-09-15 → 09-16** | **2026-09-16** | **Yes** | Yes | **(C)** — the only FOMC in the window | federalreserve.gov/monetarypolicy/fomccalendars.htm, fetched 2026-09-06 |

One qualifier on the press conference, stated rather than smoothed over: the Fed's own calendar page had not yet posted meeting-specific press-conference and materials links for the Sept–Dec 2026 meetings at fetch time. Every FOMC meeting has carried a press conference since 2019 and two independent third-party trackers confirm one for 09-16, so the row stands — but the press-conference leg specifically is corroborated, not first-party. The **meeting dates and the SEP** are first-party from the Fed calendar.

**This is the only router-eligible event anywhere in this file.** C's activation state is HYBRID ACTIVATE (FOMC-only), so the 2026-09-16 decision is the single event in either window that Strategy C may act on this cycle.

Remaining 2026 meetings, outside the window and listed for context: **2026-10-27/28** (decision 10-28, no SEP) and **2026-12-08/09** (decision 12-09, SEP). The October meeting sits eight days past the window close and enters the window next cycle. 2027 meetings, marked tentative by the Fed's own convention until confirmed at the preceding meeting: Jan 26-27 · Mar 16-17 (SEP) · Apr 27-28 · Jun 8-9 (SEP) · Jul 27-28 · Sep 14-15 (SEP) · Oct 26-27 · Dec 7-8 (SEP).

**Scheduled macro releases inside the window.** These are not Strategy C qualifying events in their own right — none of them is an earnings release, a PDUFA or an FOMC meeting — but they land inside the holding period of any structure written around the 09-16 decision, so they are calendar facts a C thesis must price rather than discover:

| Date | Release | Agency | Note |
|---|---|---|---|
| 2026-09-10 | PPI, August | BLS | Carried from prior cycle at (C); not re-verified this run |
| **2026-09-11** | **CPI, August** | BLS | Carried at (C). **Falls between a 09-08 entry and the 09-16 decision** — see PART 2B |
| **2026-09-16** | **FOMC decision + SEP** | Fed | (C), first-party |
| 2026-09-30 | PCE + Personal Income, August | BEA | Carried at (C). After the decision |
| 2026-09-30 | GDP Q2, third estimate | BEA | Carried at (C) |
| 2026-09-30 | US government funding deadline | — | Senate-passed CR ran to 2026-12-11; live process, (E). Bears on October data reliability |
| 2026-10-02 | Employment Situation, September | BLS | Carried at (C) |
| 2026-10-14 | CPI, September | BLS | Carried at (C); lands on the window's second-to-last day |
| 2026-10-15 | PPI, September | BLS | Carried at (C) |

**Provenance honesty on this table:** these dates were confirmed against bls.gov and bea.gov in a prior cycle and are **carried, not re-verified this run**. The metered budget went to the PDUFA verification pass instead, which found three rows that needed correcting — a better use of the calls. They are marked as carried so no reader mistakes them for fresh first-party reads.

### 1B.2 — Corporate earnings inside the 45-day window

Deferred to §1A.1, which enumerates the same dated set for the same window and is not duplicated here. Two changes matter for Strategy C specifically and are flagged at the point of use in PART 2B:

- **ORCL is now dated: 2026-09-10 AMC (C)**, first-party from Oracle's own "Sets the Date" release of 2026-09-02, closing a four-cycle ambiguity.
- **RH is now dated: 2026-09-10 AMC (C)** and did **not** report last week, correcting last cycle's `(!)` split.

### 1B.3 — FDA PDUFA and advisory actions inside the window

Every row below was individually checked for whether the action has **already been taken** — not merely whether a date was once scheduled. That check is why this section looks different from last cycle's.

**PENDING — verified still open as of 2026-09-06**

| Date | Ticker | Company | Drug / candidate | Indication | Type | Status |
|---|---|---|---|---|---|---|
| 2026-09-11 | **TLX** | Telix Pharmaceuticals | Pixclara (TLX101-Px, floretyrosine F 18) | Recurrent glioma PET imaging | NDA, 2nd cycle | **(C)** — US-listed test resolved explicitly: **Nasdaq: TLX**, a genuine dual listing (ASX + Nasdaq), not an OTC ADR. First NDA drew a CRL 2025-04-28; resubmitted 2026-03-13, accepted 2026-04-10 |
| 2026-09-19 | **RARE** | Ultragenyx | UX111 (rebisufligene etisparvovec) | Sanfilippo A (MPS IIIA) | BLA, 2nd cycle | **(C)** company 8-K. Prior CRL July 2025. Market cap ~$2.5-2.6B — **borderline on the $2B A-floor**, immaterial for C |
| 2026-09-23 | **GRAL** | GRAIL | Galleri | Multi-cancer early detection | **CDRH advisory panel — a VOTE, not a decision** | **(C)** Federal Register notice 2026-16245 (pub. 2026-08-10) **and** FDA's own Advisory Committee Calendar. Molecular and Clinical Genetics Panel, 9am-6pm ET. No rescheduling notice found |
| 2026-09-26 | **MIRM** | Mirum (asset in-licensed from Incyte) | Zilurgisertib | Fibrodysplasia ossificans progressiva | NDA, Priority Review | **(C)** — Mirum Q2 2026 release still refers to a pending approval; no later action found |
| 2026-09-30 | **SRRK** | Scholar Rock | Apitegromab | Spinal muscular atrophy | BLA, Priority Review | **(C)** — company release 2026-08-07: *"remains on track for potential FDA approval by the September 30, 2026 PDUFA action date"* |
| 2026-09-30 | **BMY** | Bristol Myers Squibb | Camzyos (mavacamten) | Adolescent (12-<18y) obstructive HCM | sNDA | **(2S)** — FDA acceptance covered June 2026; no approval or CRL found |
| 2026-10-04 | **MRK** / Eisai | Merck (primary) + Eisai | Welireg (belzutifan) + Lenvima | Advanced RCC | sNDA ×2 | **(C)** — Eisai's own release, Merck.com, and two trade sources all give 2026-10-04. Based on LITESPARK-011 |
| 2026-10-09 | RHHBY | Genentech / Roche | Atezolizumab (Tecentriq / Tecentriq Hybreza) | Adjuvant stage III dMMR/MSI-H colon cancer | sBLA | **(C)** — Priority Review accepted June 2026. **US-listing caveat below** |
| 2026-10-10 | **MRK** / Daiichi Sankyo | Merck (US-listed) + Daiichi (TSE) | Ifinatamab deruxtecan (I-DXd) | Previously-treated ES-SCLC | BLA | **(C)** merck.com |
| 2026-10-15 | RHHBY | Genentech / Roche | Enspryng (satralizumab) | Thyroid eye disease | sBLA | **(C)** — Genentech's and Roche's own releases plus three trade sources. Priority Review granted 2026-06-29/30 on SatraGO-1/2. **Newly inside the window** (last cycle's closed 10-14). **US-listing caveat below** |
| 2026-10-17 | **VTRS** | Viatris | MR-141 (phentolamine ophthalmic 0.75%) | Presbyopia | sNDA | **(C)** — date unchanged in all located coverage; no approval or CRL found |

**The Roche/Genentech US-listing caveat, stated once and applied to both rows.** Genentech is a US-headquartered, wholly-owned Roche subsidiary. Roche's primary listing is SIX:RO/ROG; its only US quotation is **OTCQX: RHHBY**, an over-the-counter ADR, not a primary US listing. Strategy C's qualifying-event definition says "US-listed companies." **Both Roche rows are therefore carried as calendar facts but flagged as failing a strict reading of the US-listed test**, and neither is ranked in PART 2B. This is the same ADR question W4 ruled on for Strategy A on 2026-08-09; the ruling is applied consistently here rather than re-litigated. The Merck/Daiichi row is *not* affected — Merck (NYSE: MRK) is the US-listed BLA sponsor.

**RESOLVED — acted on before the window opened. Recorded so they are not carried as pending.**

| Original date | Ticker | Drug | What actually happened | Source |
|---|---|---|---|---|
| ~Q3 CY2026 ("~09-30") | **PTGX** / **TAK** | Rusfertide | **APPROVED 2026-08-28** as **Mimrylo™**, first drug of its kind for polycythemia vera | FDA.gov press release 08/28/2026 + Takeda newsroom, same date + drugs.com approval history |
| ~Q3 CY2026 ("~09-30") | **ROIV** | Brepocitinib | **APPROVED 2026-08-26** as **Lisraya™**, first oral drug for adult dermatomyositis; announced 08-27 | Roivant IR release (GlobeNewswire 2026-08-27) + AJMC citing the FDA announcement + Reuters + drugs.com |
| 2026-09-22 | **IONS** | Zilganersen | **APPROVED 2026-09-03** as **Zanvastro™** — *ahead of* its PDUFA date, first disease-modifying therapy for Alexander disease | FDA.gov press announcement 09/03/2026 + Ionis IR release |
| 2026-09-18 | GSK | Zidesamtinib | **APPROVED 2026-07-22** as **Jideytro™**. Already struck last cycle; re-confirmed here so it cannot return a third time | GSK release, FDA drug-approval page, four trade outlets, all 2026-07-22/23 |

**POSTPONED out of the window**

| Ticker | Drug | Was | Now | Why |
|---|---|---|---|---|
| **PRAX** | Relutrigine (SCN2A/SCN8A DEE) | 2026-09-27 | **2026-12-27** | FDA extended review three months after Praxis submitted additional sensitivity analyses, classified a "major amendment." No new studies requested; **no safety or manufacturing issue cited.** Company IR release + 8-K, both 2026-06-29 |

**STRUCK — the date does not appear to exist**

> **MRK / Winrevair (sotatercept), HYPERION label update for newly-diagnosed PAH, carried last cycle at 2026-09-21 (2S) — REMOVED.** A dedicated verification pass found **no sBLA tied to HYPERION at all.** HYPERION has reached topline and full results (positive, primary endpoint met, per Merck.com, September 2026), and one source states explicitly that *Merck has not stated an expected date for regulatory submission.* The only sotatercept label sBLA with a real PDUFA date on record is a **different and already-past filing** — the ZENITH-trial label update, PDUFA **2025-10-25**. The most likely origin of the 09-21 row is a conflation of the two.
>
> This is the **third consecutive cycle** in which a carried, ranked catalyst turned out not to exist as described — after META's "UTECA trial October 2026" (a one-year mis-projection of an October **2025** trial) and "QCOM v. Arm, 2026-10-05" (uncorroborated) last cycle. The prior cycle already named the failure mode as *confirming that a date was scheduled without checking whether it had already been acted on.* **This instance is a distinct and worse variant: the date was never scheduled at all.** Last cycle's own downgrade of this row from (C) to (2S) was the tell, and the lesson to carry is narrow and mechanical — **a row that has sat at (2S) or below for two consecutive cycles should be treated as a claim to falsify, not a fact to re-carry.**

**Excluded — sponsor fails the US-listed screen** (all still pending as filings)

| Drug | Indication | Date | Sponsor | Why excluded |
|---|---|---|---|---|
| Levacetylleucine (AQNEURSA), sNDA | Ataxia-telangiectasia | 2026-09-19 | IntraBio Inc. | Private (Austin, TX); no ticker across company site, BioSpace or BusinessWire |
| Lirafugratinib (RLY-4008), NDA | FGFR2-altered cholangiocarcinoma | 2026-09-27 | Elevar Therapeutics | Majority-owned subsidiary of HLB Co. (Korea); Elevar not separately listed |
| Emcitate (tiratricol), NDA | MCT8 deficiency | 2026-09-28 | Egetis Therapeutics AB | Listed **only** on Nasdaq Stockholm (EGTX) |
| Tabelecleucel, BLA | EBV+ PTLD | 2026-10-10 | Pierre Fabre | **Now properly sourced**: thepharmaletter describes it as privately held; Pierre Fabre's own site states its majority shareholder is the Pierre Fabre Foundation. Not listed anywhere. Incidental finding: a **second CRL was issued 2026-01-09**, so this 10-10 date is a *third* review cycle |

### 1B.4 — Beyond-window PDUFAs (2026-10-22 → 2026-11-22), context only

Verified at a lighter standard than the in-window rows — sourced from the aggregator layer (checkrare, TipRanks) and **not** cross-checked against company IR. Treat as unconfirmed-pending. These enter the window over the next two cycles.

- **GSK** — bepirovirsen, chronic hepatitis B — 2026-10-26
- **PHAR** (Pharming Group, Nasdaq ADR) — Joenja (leniolisib) — 2026-10-24; indication/expansion not independently confirmed
- **INO** (Inovio) — INO-3107, recurrent respiratory papillomatosis — 2026-10-30; note INO is far below the $2B floor, so it is C-context only
- **Beren Therapeutics** — adrabetadex, Niemann-Pick type C — 2026-11-17; listing status not verified
- **SVRA** (Savara) — Molbreevi, autoimmune pulmonary alveolar proteinosis — 2026-11-22

### Coverage statement for this PART

**FOMC coverage is complete and first-party.** There is exactly one meeting in the window and the Fed publishes the full calendar; nothing here is inferred.

**PDUFA coverage is a floor, not a ceiling, and the reason is structural.** FDA is barred by 21 CFR 314.430 from confirming that an application even exists before the sponsor discloses it, so there is no authoritative forward list to enumerate against. Every "pending" verdict above rests on the most recent dated sponsor release or trade-press item found — between roughly one week and two months old at run time — showing no approval, CRL or further extension. The two approvals and the one postponement are firmer: those are corroborated directly against FDA.gov press announcements and company 8-Ks. **A PDUFA date that no sponsor has ever announced cannot appear in this table at all**, and NVO's denecimig is the known live instance of exactly that (see the carry-forward note in the past-window section).

**Advisory-committee coverage is structurally incomplete and will remain so.** The Federal Register lead time is ~15-75 days, so October AdComs may simply not be noticed yet. Two FDA notices stand for the window: the GRAIL panel (09-23) and a Pediatric Advisory Committee virtual meeting (09-16) whose notice is general rather than sponsor-specific. **No October FDA AdCom for a US-listed sponsor has been noticed as of 2026-09-06.** One October-scoped Federal Register API query returned zero documents and a browser-facing search hit an anti-bot redirect that was deliberately not followed. This is a re-check next cycle, not a gap worth alerting on.

**One unresolved aggregator artifact, recorded rather than invented:** a ticker rendered "IRD" appears alongside Viatris on one aggregator's 2026-10-17 entry. It could not be matched to any company or drug and appears in no other sourced list. It is left unidentified rather than assigned a plausible identity.


---

## PART 2A — Strategy A preliminary ranked shortlist (44 candidates)

All price, return and liquidity figures are **IBKR regular-session daily bars through the 2026-09-04 close**, `step=ONE_DAY`, `outside_rth=false`, 35 bars per name. Dollar ADV is the mean of per-bar (close × volume), **not** mean(close) × mean(volume); the convention was validated against SPY at **$20.8B/day**, inside the $15–30B sanity band. Eight rows (GEV, DDOG, PLTR, RARE, SMMT, AVGO, LLY, XLE) were independently re-fetched and matched the batch data exactly. No symbol failed to resolve.

> ### THE REACH MARKER IS RE-ANCHORED. THE ENTIRE SEPTEMBER CATALYST CLUSTER IS UNREACHABLE.
>
> Strategy A is DO-NOT-ACTIVATE and **no scheduled event before 2026-10-01 can change that** — the router moves on the M1a/M1b monthly re-score, and the next one is 2026-10-01. Capital restoration on `trigger=regime_enable` then takes a few sessions. So:
>
> - **E1** — reachable if the **2026-10-01** re-score flips A. Requires a catalyst on or after **~2026-10-05**.
> - **E2** — reachable only if 10-01 holds and the **2026-11-01** cycle flips it. Requires a catalyst on or after **~2026-11-05**.
> - **SPENT-BY-GATE** — catalyst before ~2026-10-05. **Unreachable under either epoch, regardless of merit.**
>
> Applying that marker to §1A.1 is bleak and must be said plainly: **every dated catalyst in September is SPENT-BY-GATE.** ORCL 09-10, RH 09-10, ADBE 09-10, KR 09-11, AZO 09-22, GIS 09-23, COST 09-24, DRI 09-24, JBL 09-24, MU 09-30, NKE 10-01 — plus every non-earnings September item: the AAPL keynote 09-09, LH investor day 09-10, CRM Dreamforce 09-15/17, ON analyst day 09-16, INTU investor day 09-17, META Connect 09-23/24, and the GOOGL ad-tech Final-Judgment deadline 10-02. **That is roughly a third of this file's dated content, ranked for an epoch it cannot reach.**
>
> **The sharpest instance is ORCL.** Its date has been the file's flagship carry-forward for four consecutive cycles. It was resolved this run to first-party certainty — **2026-09-10** — and that resolution places it **six days before the earliest date any A epoch could open.** The four cycles of effort produced a correct answer that arrives too late to trade. That is not an argument against having resolved it (the date is now right for every other consumer, including PART 2B where ORCL ranks #3 on measured premium), but it *is* an argument about what W1 should be spending its research budget on while A is gated — recorded in the OUT-OF-SCOPE section.

> ### A SECOND STRUCTURAL FINDING: BEARISH CANDIDATES CANNOT BECOME STRATEGY A POSITIONS
>
> `strategy/03_strategy_a.md` is explicit that A is **long-only** — *"no shorts — short is B's territory."* A candidate whose hypothesized mispricing is that the name is **over**-valued therefore cannot produce an A entry no matter how strong the evidence.
>
> Last cycle's shortlist ranked four bearish candidates inside its ranked tiers, including one at **#3** (AMAT), with AKAM at #10, WMT at #12 and ADBE at #34. W4's §D converts the **top-10** into A thesis-construction work (or, while gated, into Watchlist rows). **A bearish name in the top-10 consumes a thesis slot that cannot produce a position**, which is a category error rather than a judgment call.
>
> **This cycle's top-10 is therefore all long-direction.** Bearish candidates are still ranked and still carried — the analysis has value for Strategy B's taxonomy and for the divergence record — but they are marked **DIRECTION-INADMISSIBLE (A long-only rail)** and placed below the actionable tier. This is a W1-side fix; the underlying spec gap is referred in the OUT-OF-SCOPE section.

### What the week established, and why it re-orders the list

The week just past produced a cross-sectional regularity that is directly adverse to the naive A thesis. **Nine of ten prints beat consensus. Four fell anyway** — PANW −9%, AVGO −5/−6%, NTAP −8/−10%, and LULU on an ex-item basis once the $0.86/share tariff refund is stripped. D1 recorded the identical shape on 2026-08-28 (CRDO −20.04%, MDB −13.54%, *"beats sold on margin anxiety"*) and framed the 09-02 session as **"demand intact, the fight moved to margin."**

Last cycle narrowed the standing "beats keep landing, the tape sells them" objection to **hardware and semicap only**, after the 08-26/27 software rally appeared to refute its general form. **This week refutes that narrowing.** The selling hit software (PANW), semis (AVGO) and storage (NTAP) alike. The discriminator was neither sector nor the beat: it was **whether guidance went up and whether cash conversion held.** DELL, SNOW and HPE each raised guidance on AI infrastructure and rose hard (+16%, +21%, +8.5%). NTAP raised guidance too and still fell, on free cash flow.

**Any A thesis below that rests on "the print will be good" is answering the wrong question.** The operative question is now the guide and the cash conversion, and every top-10 rationale is stated against that bar.

### Two eligibility facts measured this run

**Every one of the 49 names measured clears the 30-day $10M ADV rail.** The thinnest are COGT $38.5M, RARE $40.7M, SMMT $53.2M, EXEL $67.8M, IONS $73.4M and BBIO $81.2M — all comfortably above. The liquidity screen struck nobody this cycle, unlike last cycle where it removed GRAL at $6.8M/day.

**RARE fails the market-cap floor and comes off the shortlist.** Measured: **−43.12% over 30 bars and −40.26% in the last five**, closing 2026-09-04 at **$15.30**. The cause is *not* its PDUFA: Ultragenyx's **Angelman syndrome candidate (GTX-102) failed a late-stage study**, the stock fell ~46% after hours from a $26.53 regular close, and Baird cut to Neutral with a target of $40 → $16. Carrying last cycle's ~$2.5–2.6B cap reading through the measured −43.12% puts the cap at roughly **$1.4–1.5B — below the $2B floor.** This is a *derived* figure, not a fresh FMP quote (RARE was among the 31 symbols the population pull could not re-check before its ceiling), and it is flagged as derived; but the margin is wide enough that the conclusion is not close. **RARE is struck on the cap rail — a mechanical exclusion, not a narrative one.**

Two things worth separating, because conflating them would be the same error this file caught elsewhere: **the UX111 PDUFA on 2026-09-19 is unaffected and remains pending.** The prior CRL (July 2025) was on CMC/manufacturing grounds, not clinical data; the BLA was resubmitted early 2026 and accepted April 2026. A failed trial on a *different* asset does not invalidate that date. RARE leaves the A shortlist on size and stays in §1B.3 as a live PDUFA.

### TOP-10 — all long-direction, all reachable at E1 or E2

| # | Ticker | Direction | Catalyst (date, provenance) | REACH | 30-bar | 5-bar | ADV $M | Gap thesis, and how it answers the guide/cash bar |
|---|---|---|---|---|---|---|---|---|
| 1 | **GEV** | Bullish | Q3 ~2026-10-21/22 **(E)**; Q4 ~2027-01-27/28 **(E)** | **E1+E2** | −7.17% | +3.29% | 1,281.8 | Widest documents-vs-price gap in the set: Q2 orders **+88% to $24.2B**, backlog **$176B**, and the stock is still down over 30 bars. Orders and backlog *are* the guide-and-conversion evidence the week demanded. **Open Strategy D lot in GEV — disclosure, not exclusion** |
| 2 | **CAT** | Bullish | Q3 **2026-11-04 (C)**; Q4 ~2027-01-28 (E) | **E1+E2** | −8.42% | +1.71% | 1,263.4 | Largest beat in five years, record **$63B backlog**, and the de-rating **deepened** this cycle (−7.41% → −8.42%). Confirmed date. The gap widened while the evidence didn't move |
| 3 | **NTAP** | Bullish | Q2 FY27 **2026-12-01 (C)** | **E1+E2** | +10.64% | −0.76% | 224.0 | **The week's cleanest newly-created gap.** Beat (rev +30%, EPS +66%), *raised* FY27 guidance, and fell 8–10% on a free-cash-flow decline. It is the one name that failed the week's actual discriminator rather than the beat test — which makes it the most decidable name here. **The only company-confirmed date beyond the feed horizon** |
| 4 | **DDOG** | Contested (long) | Q3 ~2026-11-05 **(E)** | **E1+E2** | −13.74% | **−10.15%** | 587.1 | Worst 5-bar in the set after PANW, and the worst 30-bar of any mega-cap-adjacent name. The 08-06 customer-concentration objection is still unanswered and price has now moved *with* it for a second cycle. Decidable at the print; the objection is explicit and falsifiable |
| 5 | **AMD** | Contested (long) | Q3 **2026-11-03** (E feed); Q4 ~2027-02-02/03 (E) | **E1+E2** | −8.50% | +2.58% | 5,970.7 | MI400 ratified on product while the stock de-rated; priced its largest-ever bond and rose on it. Must answer the AVGO read-across — a semi that beat and still sold on guide |
| 6 | **TTWO** | Bullish | **GTA VI launch 2026-11-19 (2S)**; pre-load 11-12 | **E1+E2** | −7.32% | **−8.79%** | 291.6 | The largest dated non-earnings binary in the window, **sold hard into it** ten weeks out. Uncorrelated with the AI complex, so it is the one top-10 name the guide/cash discriminator does not govern |
| 7 | **INTC** | Bullish | Q3 **2026-10-22** (E feed); Q4 ~2027-01-21/22 (E) | **E1+E2** | +3.77% | +7.07% | 6,382.0 | Q2 rev +25% (fastest in 15 years), DCAI +59%, unrefuted since. Gap narrowing (+7.07% on the week) but not closed. Altera-sale reports are the live counter |
| 8 | **GOOGL** | Bullish | Q3 **2026-10-28** (E feed); Q4 ~2027-02-03/04 (E) | **E1+E2** | +5.85% | −2.35% | 5,105.6 | Cloud trend intact. **The 2026-09-02 ad-tech remedies ruling removed the breakup tail** — Brinkema ordered operational changes only. The 10-02 Final-Judgment deadline is SPENT-BY-GATE, but the *reduced* legal tail persists into the Q3 print. **Open Strategy D lots in GOOGL ×2 — disclosure** |
| 9 | **FSLR** | Bullish | **Section 232 regime effective 2026-12-04 (C)** | **E1+E2** | +0.80% | −0.00% | 284.0 | Fully specified, quantified, dated policy catalyst (polysilicon $21/kg, cells $0.22/W, modules $0.38/W) and the stock is **flat** over 30 bars and exactly flat on the week. A non-earnings thesis the guide/cash bar does not touch |
| 10 | **VRTX** | Bullish | **Povetacicept PDUFA 2026-11-30 (C)**; Q3 ~2026-11-02/03 (E) | **E1+E2** | +14.40% | +0.82% | 299.8 | Non-AI diversifier carrying a dated, company-confirmed regulatory binary plus a print. The +14.40% means part of the gap is already paid for — the weakest of the ten on that basis, retained for the dated catalyst and the diversification |

### 11–20

| # | Ticker | Direction | Catalyst | REACH | 30-bar | 5-bar | Note |
|---|---|---|---|---|---|---|---|
| 11 | ORCL | Bullish | **2026-09-10 (C)** — resolved after four cycles | **SPENT-BY-GATE** | +38.08% | +5.26% | Date finally certain, six days before any reachable epoch. Also +38% over 30 bars, so the gap it was ranked #1 on last cycle has substantially closed on price alone. Next reachable: Q2 FY27 ~12-09/10 (E) |
| 12 | CRWV | Bullish, two-sided | Q3 ~2026-11-10/11 (E) | E1+E2 | +24.32% | +6.09% | Rev +112%, backlog +246% — and the purest instance of the standing AI-financing objection |
| 13 | NBIS | Bullish | Q3 ~2026-11-10/11 (E) | E1+E2 | +20.57% | +8.23% | Financing objection reads across from CRWV |
| 14 | META | Reframed | Q3 **2026-10-28** (E feed) | E1+E2 | +3.63% | +6.70% | Rests on the print alone since the phantom UTECA row was struck. +6.70% on the week erodes the de-rating it was ranked on |
| 15 | NVDA | Bullish | Q3 FY27 **2026-11-18** (E feed); GTC Berlin 10-20/22 (E) | E1+E2 | +11.37% | +5.89% | Largest ADV in the set at $16.2B/day. Two dated catalysts, both reachable |
| 16 | MRVL | Bullish | Q3 FY27 ~2026-12-01/02 (E) | E1+E2 | **+15.10%** | +3.20% | **Demoted from #2.** Ranked last cycle on a −10.28% post-print drop; it has since recovered to +15.10% over 30 bars. The gap largely closed on price without new evidence |
| 17 | MU | Bullish | Q4 FY26 **2026-09-30 (C)** → next Q1 FY27 ~12-16 (E) | **SPENT-BY-GATE**, then E2 | +10.38% | +8.98% | Second-largest ADV ($20.2B/day). The near catalyst is unreachable; the December one is E2 only |
| 18 | CSCO | Bullish | **2026-11-12 (C)** newsroom.cisco.com | E1+E2 | −4.35% | −0.66% | AI-infra orders $9.3B (4.5× prior year) beat the thesis's own $9B cite, and the stock is *down* 4.35%. **Feed/IR date conflict resolved to the company: 11-12, not FMP's 11-11** |
| 19 | MSFT | Bullish, largely realized | Q1 FY27 **2026-10-28** (E feed); Ignite 11-17/20 **(C)** | E1+E2 | +30.91% | −2.69% | Thesis substantially realized at +30.91%. Retained for the dated Ignite catalyst |
| 20 | QCOM | Bullish | Q4 FY26 ~2026-11-11 (E) | E1+E2 | +1.06% | +2.77% | Still resting on its print alone after the phantom Arm-trial row was struck last cycle. Flat over 30 bars |

### 21–44 (rest tier)

**Long-direction, ranked:** 21 **SNOW** (+25.79%; catalyst spent 09-02, next ~11-27 or 12-02/03 `(!)`) · 22 **DELL** (+19.80%, **+14.88% on the week** — the strongest print of the week; no next date located, a genuine hole) · 23 **CRM** (+58.40%, largest 30-bar move in the set; next ~12-02/03 E) · 24 **NOW** (+43.00%, no own catalyst; Q3 10-28 E1+E2) · 25 **SMCI** (+31.53%, +6.77% on the week; Q1 FY27 11-03 C) · 26 **AMZN** (+11.37%; Q3 10-29 E1+E2; open D lots ×2 — disclosure) · 27 **IBM** (+9.66%; Q3 ~10-21/22 E) · 28 **MRK** (+14.69%; the densest regulatory calendar in the file — Welireg+Lenvima 10-04 (C), I-DXd 10-10 (C), both E1) · 29 **PLTR** (+41.82%, −6.42% on the week; direction SUSPENDED, bearish lean refuted at the print) · 30 **INTU** (+12.27%, **−7.08% on the week**; investor day 09-17 SPENT-BY-GATE, Q1 FY27 11-20 (C) E1+E2) · 31 **BA** (+1.30%; Q3 10-28; 737 MAX 10 cert (T) year-end) · 32 **LLY** (−3.90%; Q3 10-29; retatrutide filing slipped to Q1 2027) · 33 **CTVA** (−1.56%; spin-off is a *quarter*, not a date — demotion stands) · 34 **SMMT** (+28.88%, **+28.22% on the week**; ivonescimab PDUFA 2026-11-14 (C), contested HARMONi HR 0.76) · 35 **BBIO** (−10.93%; BBP-418 PDUFA 11-27 (C), no AdCom planned) · 36 **EXEL** (+6.57%, +8.37% on the week; zanzalintinib PDUFA 12-03 (2S)) · 37 **IONS** (+2.72%, −4.85% on the week; **its 09-22 PDUFA resolved early as an APPROVAL on 09-03** — the catalyst is spent, not forthcoming) · 38 **COGT** (−12.58%; bezuclastinib PDUFA 12-30, unconfirmed) · 39 **ON** (−14.32%; analyst day 09-16 SPENT-BY-GATE) · 40 **DYN** (z-rostudirsen PDUFA **2027-01-21 (C)** — E2, one of only four confirmed 2027 catalysts) · 41 **BMRN** (VOXZOGO sNDA **2027-02-28 (C)** — E2) · 42 **WDAY** (Financial Analyst Day **2026-10-13 (C)** — E1) · 43 **JPM** (Q3 10-13 (C) E1; **Investor Day 2027-02-22 (C)** E2) · 44 **TSM** — **ADR, NOT A-ELIGIBLE**, listed for visibility only; the open Strategy D lots ×2 are unaffected.

**DIRECTION-INADMISSIBLE for A entry (long-only rail) — ranked but not convertible:** **AMAT** (−15.21%, the worst large-cap 30-bar in the set; bearish; Q4 FY26 10-22-or-11-12 `(!)`) · **AKAM** (−8.80%; bearish/contested; Q3 ~11-05) · **WMT** (−2.13%, +3.93% on the week; bearish; Q3 11-19) · **ADBE** (+18.39%, **−8.58% on the week**; bearish; Q3 09-10 SPENT-BY-GATE, Q4 ~12-09/10) · **HD** (−3.58%; bearish/neutral; Q3 11-18). These five carry real evidence and are retained for the divergence record and for Strategy B's taxonomy, but **none can produce a Strategy A position** and W4 must not convert them.

**STRUCK this cycle:** **RARE** — market cap fails the $2B floor after the Angelman Phase 3 failure (mechanical, see above). **SRPT** — considered on its confirmed 2027-02-28 PDUFA but **cap ~$2.14B sits directly on the floor** after a heavy decline; not ranked pending a fresh cap measurement, and named rather than silently dropped.

**SPENT cluster** (catalysts resolved in the week just past, retained in `Watchlist.md`, not ranked): DELL 09-01 · PANW 09-01 (+2.92% 30-bar but **−10.32% on the week**, the worst 5-bar in the set) · AVGO 09-02 (−6.29%, −2.96%) · SNOW 09-02 · HPE 09-02 · NTAP 09-02 (promoted to #3 on the gap the print created) · LULU 09-03 · DOCU 09-03 · CPB 09-03 · NIO 09-01 (ADR).

### The standing objection class produced no new instance this week

The **AI-financing objection** (NVDA 07-27, DDOG 08-06, AVGO 08-14, CRWV structural, IREN 08-28) produced **no new instance** this cycle. AVGO's 09-02 print did not answer the existing one — a thin beat and a Q4 guide below consensus leaves it exactly where it was. CRWV (#12) and NBIS (#13) remain the purest carriers. A thesis on either must answer the objection on its own terms rather than inherit a cohort verdict.


---

## PART 2B — Strategy C preliminary ranked shortlist (20 measured event candidates)

> ### ⚠️ THE FOMC THESIS IS ALREADY ENQUEUED. W4 MUST NOT ENQUEUE IT AGAIN.
> `thesis-FOMC-C-20260908` is live in `events.queue_events` (`PENDING_ANALYSIS`, strategy C, due **2026-09-08**, status pending). W4's §D C-limb enqueues one row per top-tier C name; the 2026-08-30 W4 run correctly resolved this to the existing row rather than minting a duplicate. Repeat that. **Candidate 1 below is that queue item, not a new one.**

**Router reality, stated once and applied per row.** C is **HYBRID ACTIVATE (FOMC-only)**. Candidate 1 is the only router-eligible row in this section. Candidates 2–20 are **router-PARKED — barred by the carve-out, not by rank** — and are carried as divergence context and as the evidence series a future scope-widening adjudication would read. They are explicitly **not** handoff-ready, and W4 should not enqueue them.

**Ratios below are not comparable across rows** without reading the tenor flag: each name is measured against the first listed expiry strictly after its own event, and those tenors range from 1 day to 24 days past the event.

---

### Candidate 1 — FOMC 2026-09-16 (the only router-eligible row) · TOP-5 tier, rank 1

**(a) Direction of hypothesized divergence: NO VIEW TAKEN — and this cycle the reason is stronger than last cycle's.** Both legs of the case have now moved against a long-premium reading, where last cycle only one had.

**(b) Supporting measurement.** All figures measured against the 2026-09-04 close via the IBKR connector; SPY primary, QQQ cross-check. Expiry **2026-09-18**, the first regular monthly after the decision (a 09-17 weekly also exists and was not used). ATM strike SPY 769 against spot 769.45.

| Quantity | This cycle (2026-09-06) | Last cycle (2026-08-30) | Change |
|---|---|---|---|
| SPY ATM IV, 09-18 expiry | **10.525%** | 10.86% | **−0.34 vol pts** |
| ATM straddle expected move to 09-18 | **±1.796%** (last) / ±1.762% (mid) | ±2.20% | **−0.40pp** |
| Days to expiry at measurement | 12 | 19 | −7 |
| IV / HV10 | **1.227** | — | — |
| IV / HV20 | **1.299** | — | — |
| IV / HV30 | **0.900** | — | — |
| Ratio range across estimators | **0.814 – 1.299** (incl. QQQ) | 0.914 – 1.006 | **materially wider** |

**THE COMPRESSION IN EXPECTED MOVE IS TIME DECAY, NOT A VOL RE-PRICING — do not read it as a signal.** The straddle fell from ±2.20% to ±1.796%, which looks like a 19% collapse in priced risk into a decision that is now closer. It is not. Both readings are on the **same contract** (09-18 expiry), 19 days out then and 12 days out now. √(12/19) = 0.795, and 2.20% × 0.795 = **1.75%** — against an observed 1.796%. **Essentially the entire move is the square-root-of-time term.** The IV itself barely moved: 10.86% → 10.525%, about −3%. A thesis that cites the shrinking straddle as evidence the market is under-pricing the meeting is reading a calendar effect as an information effect, and the 09-08 session must not make that error.

**THE PREMIUM LEG HAS TURNED, AND THIS IS THE CYCLE'S KEY FINDING.** Last cycle the premium leg *supported* a long-vol thesis: IV sat at the 0th/0th/~2nd percentile of its own 13w/26w/52w distributions and the IV/HV ratio bracketed 1.0 tightly (0.914–1.006), so implied was arguably cheap against realized. **That is no longer true on the windows that matter.** For a 12-day structure the relevant realized comparison is HV10 and HV20, and against both, implied is now clearly *richer* than realized — 1.227 and 1.299. Only against HV30 (11.701%) does IV look cheap at 0.900, and HV30 is the least appropriate window here *and* is inflated by an early-August volatility patch that has already rolled out of the 10- and 20-day windows but not the 30-day one.

Both things are simultaneously true and the reconciliation is the analytical content: **absolute IV is still near the bottom of its own history** (raw connector fractions: SPY 13w 0.0156, 26w 0.0079, 52w 0.0278 — near-zero on any reading), **but realized volatility has collapsed faster than implied did.** Cheap in absolute terms; expensive relative to what the market has actually been delivering. A long-premium structure is now buying above realized; a defined-risk *credit* structure is the one the premium metric favours. That is a reversal of last cycle's read and it is the single most consequential thing this file hands to the 09-08 session.

**(c) Event date:** 2026-09-16 **(C)**, first-party from the Fed calendar, with SEP.

**(d) Executability.** C is the only capital-enabled strategy in the book and holds zero open positions, so the whole strategy NAV is available. Sizing is the AI-chosen per-thesis risk budget with **no numeric ceiling at any level** — both the per-name ≤10% CaR and the per-strategy ≤75% deployed-CaR envelopes were retired by owner directive 2026-08-05. What still binds and must appear in the thesis record: a **seven-factor sizing justification**, a **mandatory adversarial attack on the size**, and C's own defined-risk rails — max loss deterministically computable at entry, the bounded early-assignment cascade quantity ≤ the stated budget, **dual-path verification** of base max loss (closed-form + Monte Carlo agreeing within $1, disagreement defers the thesis), single expiration only (calendars and diagonals are excluded), and structure expiration 1–45 days out with the event strictly before expiration. **No deferral flag is raised on size** — nothing in the current state blocks constructing a defined-risk structure.

**(e) Overlap with open A positions:** **none.** Zero open A positions exist, so the A↔C simultaneous-holding bar cannot bind.

**(f) Priority tier: TOP-5, rank 1** — and the only member of the tier that is actionable.

#### Three measurement caveats the 09-08 session must carry, not inherit silently

1. **Call and put ATM IV are identical to all 16 significant figures — on BOTH SPY and QQQ.** Last cycle flagged this as a tell on SPY; it is now confirmed as a property of the connector, not of the market. The `option_midpoint_iv` field returned invalid (`isValid:false`, negative annualised IV) on every contract tried, so `implied_vol` is the only usable field and it evidently computes one vol per strike rather than solving calls and puts separately. **Consequence: this connector cannot evidence skew, and no C thesis may assert a call-put IV divergence from it.**
2. **Week-over-week IV direction could not be measured by the connector** — it exposes point-in-time option snapshots and OHLCV bars, with no IV history series. The −0.34pt figure in the table above is *this file* differencing its own prior-cycle reading of the same contract, which is a legitimate comparison but rests on a stored measurement, not on a vendor time series.
3. **The IV-percentile fractions cannot be responsibly converted to percentile claims.** The connector returns `implied_volatility_percentile` at 13w/26w/52w but does not document whether the semantic is percentile-of-days or fraction-of-52-week-high. The raw fractions are reported above and deliberately not translated. The agent declining to invent an interpretation is the correct behaviour and is recorded as such.

Additional transparency, both reported rather than reconciled: the connector's own `implied_vol_underlying` for SPY annualises to **11.435%** against the 769-strike solve's 10.525%, and its built-in `historical_vol` reads **10.051%** against the computed close-to-close HV30 of 11.701%. Different methodologies; the computed figures are the ones used above because their estimator is stated (close-to-close log returns, sample stdev, ×√252).

#### What still governs the entry decision

**CPI for August lands 2026-09-11**, between a 09-08 entry and the 09-16 decision. Entering before versus after that print remains a materially different trade and the queue item's conservative default (decline if unresolved by 09-15, or if no affirmative sourced quantified divergence can be established) is unchanged. Note also that **2026-09-07 is Labor Day**, so a 09-08 entry is the first session available and there is no earlier fallback.

---

### Candidates 2–20 — router-PARKED, divergence context only

Sorted by IV/HV descending. Every row confirmed `expiry > event_date`; the wrong-expiry defect that voided last cycle's MU row is closed and MU is re-measured correctly.

| # | Ticker | Event date | Expiry | ATM strike | ATM IV % | HV30 % | IV/HV | Flags |
|---|---|---|---|---|---|---|---|---|
| 2 | CHWY | 2026-09-09 | 09-11 | 23.5 | 94.150 | 42.135 | **2.234** | Richest premium in the window |
| 3 | **ORCL** | **2026-09-10** | 09-11 | 160 | 105.273 | 54.337 | **1.937** | **Date resolved this run; the DATE-COMPROMISED flag is REMOVED and the reading is now directly comparable** |
| 4 | RH | 2026-09-10 | 09-11 | 148 | 116.035 | 59.948 | 1.936 | Highest absolute IV on the list; near the $2B cap floor |
| 5 | KR | 2026-09-11 | 09-18 | 59 | 41.581 | 22.547 | 1.844 | A same-day 09-11 weekly exists but is not strictly-after; 09-18 used per rule |
| 6 | NKE | 2026-10-01 | 10-02 | 38 | 46.525 | 31.120 | 1.495 | |
| 7 | BAC | 2026-10-14 | 10-16 | 62.5 | 24.553 | 16.801 | 1.461 | |
| 8 | ADBE | 2026-09-10 | 09-11 | 267.5 | 72.626 | 51.700 | 1.405 | Date still (2S), third cycle without an Adobe IR release |
| 9 | JPM | 2026-10-13 | 10-16 | 360 | 23.819 | 17.394 | 1.369 | |
| 10 | AZO | 2026-09-22 | 10-16 | 2980 | 35.247 | 26.643 | 1.323 | **TENOR-COMPROMISED** — overshoots 24 days, no weekly listed |
| 11 | COST | 2026-09-24 | 09-25 | 915 | 24.150 | 19.049 | 1.268 | |
| 12 | NFLX | 2026-10-20 | 10-23 | 78 | 41.794 | 34.403 | 1.215 | |
| 13 | PEP | 2026-10-08 | 10-09 | 138 | 22.555 | 18.586 | 1.214 | |
| 14 | CCL | 2026-10-05 | 10-09 | 24 | 42.049 | 36.955 | 1.138 | |
| 15 | STZ | ~2026-10-01 | 10-02 | 128 | 30.099 | 26.828 | 1.122 | **DATE-APPROXIMATE** — "~10-01" not further resolved |
| 16 | LMT | 2026-10-20 | 10-23 | 525 | 28.539 | 26.121 | 1.093 | |
| 17 | JBL | 2026-09-24 | 09-25 | 310 | 54.704 | 53.717 | 1.018 | |
| 18 | GIS | 2026-09-23 | 10-16 | 37.5 | 32.827 | 32.577 | 1.008 | **TENOR-COMPROMISED** — overshoots 23 days |
| 19 | DRI | 2026-09-24 | 10-16 | 220 | 30.998 | 31.071 | 0.998 | **TENOR-COMPROMISED** — overshoots 22 days |
| 20 | TSM | 2026-10-15 | 10-16 | 430 | 34.230 | 34.745 | 0.985 | **ADR** — fails the US-listed test for C as it does for A |
| — | MU | 2026-09-30 | 10-02 | 1015 | 65.888 | 83.785 | **0.786** | **DEFECT CLOSED.** Last cycle measured MU against a 09-25 expiry that expired *before* the 09-30 event and had to be voided. Re-measured on a correct 10-02 expiry: MU is the **only** name in the window with implied meaningfully BELOW realized |

**The MU row is the one worth carrying forward.** It is the only genuine implied-below-realized reading in the window (0.786), and it exists only because the wrong-expiry defect was fixed rather than re-inherited. It is router-parked and cannot be traded under the FOMC-only carve-out — but it is precisely the kind of evidence a scope-widening adjudication would want, and it should not be lost when this file is overwritten next week.

**PDUFA events carried without volatility measurement** (out of scope for this measurement pass, and mostly sub-$2B or single-name binaries where an ATM IV reading carries little information): TLX 09-11 · RARE 09-19 · GRAL panel 09-23 · MIRM 09-26 · SRRK 09-30 · BMY 09-30 · MRK/Eisai 10-04 · MRK/Daiichi 10-10 · VTRS 10-17. The two Roche rows (10-09, 10-15) fail the US-listed test. Last cycle's RARE IV/HV of 2.14 is now two cycles stale and **must not be carried forward** — it is not restated here.

### Methodological note on this section

All measurements are IBKR connector reads at zero metered cost. Five rows (SPY 769C, ADBE 267.5C, MU 1015C, JPM 360C, LMT 525C) were independently re-pulled at the end of the measurement pass and returned identical IV and last-price values with identical timestamps — snapshot data was stable across the session and no transcription discrepancy was found. Every one of the 20 rows returned valid option data; there were no UNAVAILABLE rows.


---

## OUT-OF-SCOPE FINDINGS — RECORDED, NOT REPAIRED

Three findings surfaced this run on surfaces W1 does not own. Per the standing scope addendum, each is recorded at a venue with a verified consumer and named here; none was repaired, and none blocks this run's own job.

**1. FMP bulk-enumeration surfaces are ALL plan-gated, which is broader than the recorded constraint.** `OWNER_ACTIONS.md` item `FMP-earn-horizon` frames the decision as "raise the tier or accept the reduced confirmed-earnings horizon." Measured this run, the horizon is only the visible symptom: `search.search-company-screener`, all `directory.*` endpoints, and `quote.batch-quote` are each ACCESS DENIED. **The consequence is that no routine on this plan can perform a market-wide screen at any budget** — which affects the framing of that open owner decision, since "accept the gap" is accepting more than a shortened earnings calendar. Recorded as an `ops.alerts` `info` row for W5's SPEC-DEFECT NOTICE INTAKE. **No new alert is raised for the horizon itself** — `37a4de80` covers it, and a weekly re-raise is alarm fatigue, exactly as W1's own section directs.

**2. W1's PART 2A has no router-aware mode, unlike W2's PART 2.** W2 gained an explicit **INDEX MODE** on 2026-08-24 after three consecutive router-gated cycles produced 15 full-depth candidate analyses of which *not one* was ever evaluated against B's entry criteria. W1 has no analogous limb: it produces a 30–50 name Strategy A shortlist at full specified depth every cycle regardless of A's activation state, and A has now been DO-NOT-ACTIVATE for three consecutive cycles. The two cases are **not identical** — W1's shortlist is explicitly "preliminary narrative synthesis," inherently lighter than W2's per-candidate enrichment, and W4's §D already gates the *enqueue* side by routing A top-tier names to `Watchlist.md` while gated. So the downstream waste W2 suffered does not occur here. **But the research cost is still incurred every week**, and this cycle produced a sharp illustration: the ORCL date, chased across four cycles, resolved to a catalyst six days before any reachable A epoch. Recorded as an `ops.alerts` `info` row naming W5.

**3. A bearish candidate cannot become a Strategy A position, and nothing in W1's or W4's spec prevents one being ranked and converted.** Strategy A is long-only. W4 §D converts the W1 top-10 into A thesis-construction work. Last cycle's top-10 contained a bearish candidate at #3 (AMAT), and #10, #12 and #34 were bearish too. A thesis slot spent on a name that cannot produce a long entry is a category error, not a judgement call. **W1 fixed this on its own side this cycle** — the top-10 is all long-direction and bearish names are marked DIRECTION-INADMISSIBLE — but the underlying spec permits the error to recur, and the fix should live in the spec rather than in one cycle's discipline. Recorded as an `ops.alerts` `info` row naming W5.

One further item, deliberately **not** raised as a finding: a discovery sub-agent this run reported a D1 coverage gap on Friday 2026-09-04. It was refuted against `state.cadence_expected_history` before anything was acted on (`expected = false`; D1's `monitor_class` is `daily_sun_thu`). It is written up in the DAILY-TO-WEEKLY BOUNDARY section as a reproduction of the 2026-08-23 `cadence_outage` false positive, and **no alert is raised** — per the RUN-LOG GAP INTERPRETATION rule, a residual concern would go to `sp_log_decision`, and there is no residual concern because the claim is simply wrong.

---

## Method and coverage notes

**Orchestration.** Eight Sonnet 5 sub-agents did the retrieval and measurement; ranking, adjudication, corrections, the reach-marker design and every finding above were done in-session and not delegated. Two agents were sent targeted follow-ups after their first returns (a PDUFA gap-closing pass against the prior cycle's carried rows, and a re-run of the thinnest non-earnings categories against IR-calendar surfaces rather than broad search); both follow-ups changed the output materially, and the ORCL resolution was pushed back into the volatility agent mid-run so its ORCL reading could be re-measured on a correct expiry.

**One shared pull, not N independent ones.** The FMP earnings calendar was pulled **once**, by a single dedicated population agent, which persisted the raw result to disk. **No other agent called FMP.** The IBKR connector (free) was used by two agents for price and option measurement; the web agents were told explicitly which surfaces they did *not* own.

**Where facts came from.** Every `(C)` row rests on a company IR release, an SEC filing, or an agency publication (federalreserve.gov, federalregister.gov, fda.gov, ustr.gov, whitehouse.gov, stb.gov). Every price, return, ADV, implied-volatility and realized-volatility figure is an IBKR read at zero metered cost. Regime, position, queue and cadence state came from BigQuery.

**Anti-transcription protocol.** Market data was pulled in batches of ≤4 symbols with each symbol kept attached to its own intermediate values; 8 of 49 rows were independently re-fetched and all 8 matched exactly. The dollar-volume convention was validated against SPY at $20.8B/day. In the option pass, 5 rows were re-pulled and all 5 returned identical values.

**Known measurement limits, stated rather than smoothed.** The IBKR connector returns one implied volatility per strike, not separate call and put solves — confirmed this run on both SPY and QQQ, where ATM call and put IV were identical to 16 significant figures. **No thesis may assert option skew from this connector.** It also exposes no IV history, so week-over-week IV direction is computed by differencing this file's own prior-cycle reading, not from a vendor series. Its `implied_volatility_percentile` field has undocumented semantics and its raw fractions are reported untranslated rather than converted into a percentile claim.

**Sources that failed, recorded so they are not re-attempted blind:** thecardiologyadvisor.com (HTTP 402 paywall) · endocrinologyadvisor.com (403) · federalregister.gov browser search (anti-bot redirect to `unblock.federalregister.gov`, deliberately not followed) · the Federal Register JSON API scoped to FDA notices since 2026-08-30 returned zero documents. Previously recorded failures were not retried: cnbc.com and bloomberg.com 403 on direct fetch, drugs.com 403, and fda.gov's live AdCom calendar (401/JS shell — the Federal Register was used instead and confirmed the GRAIL panel).

**Coverage caveats, each stated at its point of use:** the Strategy A universe is a floor and not a screen (COVERAGE STATEMENT, §1A.1); 31 of 77 feed symbols could not be re-checked against the eligibility rails before the FMP request ceiling and are marked NOT VERIFIED rather than presumed passing; PDUFA coverage rests on sponsor disclosure because 21 CFR 314.430 bars FDA from confirming an application exists before the sponsor discloses it; advisory-committee coverage is structurally incomplete because Federal Register lead times are ~15–75 days; the macro-release dates in §1B.1 are carried from a prior cycle, not re-verified this run; four product-event rows remain at (E) as carried, not checked; and the structural-narrative category is thin because forward IPO lockups require a priced deal and index-reconstitution names are published only about a week ahead — nothing citable exists yet at this vantage.

**Carry-forwards for the next cycle.** ORCL is **closed**. Still open: **NVO denecimig** has no published PDUFA date at all and a PBM tracker's Q3 2026 estimate expires this month — a decision could land inside the window with no date ever announced. **FDX** needs a company-sourced date to resolve the 10-28-vs-10-29 split. **SNOW** carries a `(!)` between 11-27 and ~12-02/03. **AMAT** carries a `(!)` between 10-22 and 11-12. **ADBE** has now gone three cycles with no IR release for a date the feed and aggregators agree on. **SRPT's ~$2.14B cap** sits directly on the floor and needs a fresh measurement before it can be ranked. **October FDA AdComs** may be noticed any day. And **RARE's derived sub-$2B cap** should be confirmed against a direct quote when the FMP budget allows.

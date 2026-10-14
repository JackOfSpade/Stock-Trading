2026-10-14
<!-- d1_scan_through_utc: 2026-10-14T22:45:00Z -->

# Daily Market Development Scan — 2026-10-14 (Wed, MT)

Scan window: 2026-10-13 16:27 MT → 2026-10-14 16:45 MT (~24h, the normal daily hand-off). The start comes from the prior `Daily.md` marker `2026-10-13T22:27:00Z`, and that file's commit (22:23:59Z) agrees. The window holds Tuesday's after-hours and **one completed US trading session, Wednesday 2026-10-14**.

Tape: **risk-off on a hot CPI and an AI-credit scare, with a sharp rotation into defensives.**
- **Indices.** The S&P 500 closed at **7,719.54 (−1.10%)**, its worst day since July. The Nasdaq 100 fell ~−2.0% and the Russell 2000 ~−1.9%, while the Dow was ~flat (−0.09%) (secondary).
  - IBKR regular-session closes: SPY 778.01 → **769.60 (−1.0810%)**, still **+0.13% above its 50dma** (768.57) and −1.22% from its 779.09 closing high. QQQ −1.9662%, IWM −1.9263%, SMH −3.9754%.
- **VIX** closed at **16.87 (+10.48%)** (IBKR, `delayed:900`). That is its first close above its 20d SMA (15.4205) after eight sessions below.
- **Credit.** HYG/IEF closed at 0.85620, **−0.90% vs its 20d SMA** (−0.40% yesterday).
- **Rates.** The 10Y spiked ~+9bp toward 5.30% on CPI, then reversed into the close (~5.19–5.28%, secondary). Hike odds jumped: ~39–60% for October (from ~22%) and ~95% for December.
- **Oil and gold.** Brent December settled **106.06 (+0.37)** on Gulf escalation, and gold fell −1.7%.
- **Leadership.** **XLV +2.53%** and **XLP +2.22%** led; **XLK −2.98%** lagged.

## TL;DR

- **Exits triggered: none.** All twelve open tranches are Strategy D. None carries a mechanical trigger, and no Development engaged any thesis criterion; GEV −6.20% is price action on its own not-exit-triggering list.
- **New entry candidates: none routed.** Seven US-listed names clear Strategy B's frozen ≥5% floor on resolved own events: **BSP, LQDA, DELL, HPE, NTAP, IONQ and MMED**. B is `DO-NOT-ACTIVATE` and capital-disabled, so all seven go to the index only. CRWV is written up but its anchor is UNRESOLVED, so it is not indexed.
- **Add candidates: none (0 of 12).** The HARD GATE clears on all 12 for the tenth run in a row.
- **Watchlist: 7 changes.** ADD BSP, LQDA, DELL, HPE, NTAP, IONQ and MMED to the Strategy B new-entry index.
- **Regime review: no review.**

> **NOTE (not a bullet, and deliberately not a `d1_actions` entry): PARK ALLOCATION CALL — GRADED DE-RISK `target_f_pct` 0 → 25 (VOO 75 / SGOV 25), BOUND, LOW 35.** D2 reaches this through `state.park_allocation_latest` (`1cc33c99-74f1-45b9-abf3-58d11be4c29d`). Two pre-registered raise clauses fired on measured closes: credit (−0.90% vs SMA) and volatility (VIX above 15 and its SMA).

---

## DEVELOPMENTS

### 1. Market-wide breaking events

- **CoreWeave credit scare.** CoreWeave's 2032 notes traded at a record ~14.5% yield on 10-13 and ~14.8–15% on 10-14 (CNBC). Its 9.75% notes were near 81 cents, and CDS implies a ~10% five-year default probability. The scare spread to every AI-financed name: neoclouds (NBIS), AI hosts and miners (IREN, CIFR, WULF, CORZ, APLD), ORCL, and power (GEV, VRT, VST, CEG, BE). CRWV itself fell −15.46%. No issuer filing or rating action was found; a CEO memo calling the market "irrational" was reported by Bloomberg.
- **Gulf / energy.** The Houthis struck an Aramco administrative building in Dhahran, causing a limited fire, and explosions were reported in Jeddah late in the day. Saudi-led coalition strikes hit Houthi oil depots near Sanaa, and Trump is reported to be considering strikes. Iran has escalated Hormuz ship attacks: 15 between 10-06 and 10-14, 11 of them in the last four days. A US–Russia diesel deal is capping part of the premium.
- **Treasury.** It fined Bank of America $1.2B (OCC/FinCEN, AML) on 10-13 and announced a buyback of up to $6B in 10–20 year coupons.
- **Cross-asset.** Gold fell −1.66% (December ~4,110). The dollar index was ~102.55, off its 102.95 YTD high. No bankruptcy, disaster or tariff/Taiwan item of market significance was found.

### 2. Scheduled events that resolved in the window

- **September CPI** (bls.gov, 08:30 ET) ran hot:

  | Measure | Actual | Consensus |
  |---|---|---|
  | Headline m/m | +0.6% | 0.6% |
  | Headline y/y | 3.7% (Aug 3.4%) | 3.6% |
  | Core m/m | +0.3% | 0.2% |
  | Core y/y | 2.6% (Aug 2.4%) | 2.5% |

  Gasoline rose +9.1% and accounted for over half of the headline increase.
- **Beige Book.** 9 of 12 districts grew, price pressures broadened, and 5 districts noted AI-related hiring cuts.
- **Fed speakers.** Barkin said CPI was "higher than he hoped" and would not pre-commit for October. Goolsbee called it "discouraging". Bowman, speaking pre-CPI, saw no urgency. Tuesday: Williams backed one more hike this year, and Waller said more hikes are likely needed.
- **Earnings (all fiscal Q3, all pre-open 10-14).** Issuer minutes are verified only for BAC (06:45 ET); the rest rest on media.
  - **BAC:** adj EPS 1.08 vs ~1.10 and revenue $29.96B vs $30.58B, with the $1.2B fine costing $0.17 a share. Stock **−4.76%**, its worst day since April 2025.
  - **MS:** EPS 3.03 vs ~2.92, revenue $20.34B vs $19.95B. Stock −2.75%.
  - **BLK:** EPS 15.93 vs 14.30, inflows $205B. Stock +0.72%.
  - **PGR:** EPS 4.37 vs ~4.30, NPW slightly light. Stock −4.23%.
  - **STT:** EPS 3.69 vs ~3.68, revenue $4.00B vs $4.04B. Stock −4.14%.
  - **FAST:** EPS 0.35 vs 0.34, revenue $2.46B vs $2.44B. Stock +1.11%.
  - **ASML** (6-K): EPS €12.95, including a €509.7M Mistral AI gain. It raised its Q4 guide to €14.2–15.2B and its FY26 guide to €44–45B. The ADR fell −3.94% anyway.
- **After the close 10-13:** **LQDA** settled all six United Therapeutics suits (GlobeNewswire), and the reaction session was 10-14 (+26.59%). HOMB reported after the close 10-14; it was −0.25% in the session, and the result was not verified.
- **FDA: nothing verified in the window.** fda.gov's novel approvals list tops out at Hovilpri (10-09), and the 10-14 posting was a policy framework. Recorded as unresolved, not as a measured absence.
- **Anthropic investor day (10-14)** was held behind closed doors. Reported targets were a $1.8–2T valuation, a roadshow the week of Nov 9, and a pre-Thanksgiving listing. **No post-event figures were found**; a social-media run-rate figure is unconfirmed.
- **Next up:** **TSM Q3 on 10-15 before the open** (EPS est ~4.45, revenue ~$45.7B), plus PPI, retail sales and claims; BNY, SCHW, PNC and USB on 10-15; TRV and TFC on 10-16. The date of Warsh's speech is conflicting (10-15 evening or 10-16). FOMC is 10-27/28.

### 3. Large single-name moves — AI-SIGNIFICANCE SCREEN

Durable record: **`c75cac94-6362-4cb3-923c-2f92811f86c2`** (`research-screen`, single-name-move).

- **Population.** 222 stocks were measured on IBKR regular-session bars (`close` array at both ends; every STK last bar is 2026-10-14, with 10-13 directly before it). 123 cleared ≥2% and ≥$2B; 16 of those carry an identified own event (`rail_tally`).
  - `surfaced_count` = 8 = `ARRAY_LENGTH(passed)`.
  - **Selection:** a complete ~190-name liquid large-cap sweep (X has no US STK row at IBKR), the 8 held names, and a 37-name phase-2 pass drawn from FMP most-active/gainers/losers and ~70 discovery and attribution searches. This is a bounded scan, not an enumeration.
- **Passed (8):**

  | Name | Move | Closes | Anchor (timing) | Event | Conv. | B routing |
  |---|---|---|---|---|---|---|
  | BSP | +41.2044% | 37.86 → 53.46 | 10-14 (6-K; pre-open or early session) | Berkshire $330M placement at $33, stake to ~4% | 60 | indexed |
  | LQDA | +26.5946% | 26.81 → 33.94 | **10-13 after the close**; reaction 10-14 | Settled all 6 UTHR suits, net $380.7M | 60 | indexed, **magnitude-clock caveat** |
  | DELL | −11.2740% | 572.47 → 507.93 | 10-14 pre-open | Barclays cut to EW, PT 574 | 60 | indexed (sector component) |
  | HPE | −8.2837% | 68.81 → 63.11 | 10-14 pre-open | Barclays cut to EW, PT 77 | 45 | indexed |
  | NTAP | −7.0332% | 239.01 → 222.20 | 10-14 pre-open | Barclays cut to EW | 45 | indexed |
  | IONQ | −9.5307% | 34.73 → 31.42 | 10-14 pre-open (~08:50 ET, unverified) | $2.0B registered direct with warrants | 45 | indexed (a distinct event from the 10-12 Elisity anchor) |
  | MMED | −8.6413% | 18.40 → 16.81 | 10-14 (minute unverified) | Medtronic completed its exchange-offer exit | 45 | indexed |
  | CRWV | −15.4607% | 77.81 → 65.78 | **UNRESOLVED** | Market repricing of its own debt to ~15% | 60 | **not indexed** |

  - **LQDA magnitude-clock caveat.** It clears ≥5% on its reaction session, but on its anchor session (27.67 → 26.81, −3.11%, before the release) it does not. Which session criterion 1 reads is the open D2 notice `d1_anchor_convention_magnitude_clock_conflated` (W5 adjudication). Both are recorded, per the CCC 10-12 precedent.
  - **BSP's listing.** Bending Spoons S.p.A. ordinary shares are NASDAQ-listed; it is not an ADR. Its $35.8B cap clears the Rev 49 foreign-instrument line on either reading.
  - **IONQ is partly sector beta.** Quantum peers fell about as much (QBTS −10.09, RGTI −8.61), so the company-specific share is uncertain.
- **Rejected notable (40 names ≥5%, conviction 30, no own event or mechanical):**
  - **SKYD −23.84** is a mechanical warrant ex-entitlement, not information: 470.7M $12 warrants were distributed, and NYSE adjusted the reference price to 9.07.
  - **FRMI −15.05** gave back its 10-13 anchor move. Its cap is $2.03B, second-sourced.
  - **CoreWeave contagion:** WULF −12.64, CORZ −12.44, CIFR −12.35, IREN −12.18, NBIS −10.08, MARA −9.66, APLD −9.43, RIOT −9.42.
  - **Optical and AI hardware:** CIEN −10.19, FLEX −9.50, LITE −9.28, COHR −9.19, SMCI −8.42, AKAM −8.23, JBL −7.53.
  - **Power:** BE −9.15, OKLO −8.62, VST −6.51, **GEV −6.20 (held)**, VRT −6.09, NRG −5.91, CEG −5.49.
  - **Chips and software:** ORCL −8.83, MRVL −8.73, ARM −6.81, NET −6.72, SNOW −6.34, MPWR −5.79, AMD −5.73, PANW −5.54.
  - **Quantum:** QBTS −10.09, RGTI −8.61.
  - **Other:** HOOD −8.54, ONDS −8.49, ENPH −8.37, PLUG −7.05 (a minor PT cut; cap $2.02B, second-sourced), SNAP −6.01, MSTR −5.87.
- **Under the $2B rail:** SMR −10.17. Its cap is disputed: FMP has $1.74B and Yahoo $2.39B.
- **Context under the floor:**
  - **Earnings:** BAC −4.76 (Q3 miss and fine), PGR −4.23, STT −4.14, MS −2.75, ASML ADR −3.94.
  - **Gainers:** GFS +4.80 (US–Japan initiative), and UNH +4.73 on day 2 of its beat.
  - **Defensive bid:** BMY +4.61, MRNA +4.65, DLTR +4.71, LLY +3.62, MRK +3.80, WMT +3.46, LMT +3.61.
  - **Held:** TSM −3.40 and UBER −2.85.
- **Cross-row close-chain check: ran, 0 hits.** No prior item carries a passed name at anchor 2026-10-14, or LQDA at 10-13. The prior IONQ anchors (09-23, 10-12) are distinct events. Coverage is ~32%, so a clean pass is not a clearance.
- **Degraded legs.**
  - No after-hours 10-14 movers list was obtainable.
  - Release minutes are unverified for BSP, LQDA, IONQ, MMED and the Barclays note. Each still resolves to its anchor date.
  - Nothing at all was found for MSTR, CIEN, LITE, COHR, JBL, MPWR and VRT, so an own event cannot be ruled out for them.
  - FMP news and quote endpoints are plan-denied (a standing limit).

### 4. Sector-level moves — AI-SIGNIFICANCE SCREEN

Durable record: **`ab91c8e7-9293-4dbb-818a-9704ca2ba1eb`** (`research-screen`, sector-move). All eleven ETFs used the registry ids, and the first-use guard passed: every prior close equals the 10-13 event close.

| ETF | Move | Closes | Verdict |
|---|---|---|---|
| **XLV** | **+2.5345%** | 169.66 → 173.96 | passed, 60: a broad defensive bid (UNH, BMY, MRNA, LLY, MRK, GILD) |
| **XLP** | **+2.2212%** | 84.19 → 86.06 | passed, 45: defensive rotation (DLTR, DG, WMT, PM, CL) |
| XLE | +0.6399% | 67.20 → 67.63 | — (Brent +0.37 on Gulf escalation) |
| XLB | −0.1006% | 49.72 → 49.67 | — |
| XLU | −0.3583% | 41.87 → 41.72 | — |
| XLF | −0.5472% | 54.82 → 54.52 | — (BAC, STT, PGR, MS lower) |
| XLY | −0.7654% | 112.36 → 111.50 | — |
| XLRE | −0.8128% | 41.83 → 41.49 | — |
| XLI | −0.9664% | 168.67 → 167.04 | — |
| **XLC** | **−1.3003%** | 112.28 → 110.82 | passed, 30: META −3.27, GOOGL −1.74 |
| **XLK** | **−2.9804%** | 196.28 → 190.43 | passed, 60: the chip, AI-hardware, optical and software selloff |

Dispersion is 5.51pp (XLV − XLK). The agreement counts are both 3 / ai_only 1 / rule_only 0.

### 5. Notable commentary

- **CoreWeave.** D.A. Davidson's Gil Luria said shareholders could lose everything. The CEO memo called the market "irrational".
- **Analyst actions.**
  - Barclays (Tim Long) downgraded DELL, HPE and NTAP: no enterprise-AI inflection, and revenue inflated by memory pass-through.
  - Susquehanna trimmed its GEV target to 1,270 and its PLUG target to 1.75.
  - UBS raised its SNAP target to 7.
  - Jefferies called the LQDA settlement a clear UTHR win.
- **Fed calls.** Citi now sees a December hike. Pantheon and First Trust see no October hike.
- **Bank CFOs.** BAC's CFO said the consent order carries no growth restriction.

## ANALYSIS — RISK TO EXISTING POSITIONS

### Mechanical exit-trigger sweep

Run for **every** position over the **union** of `state.current_positions` and live `get_account_positions`.

- **Twelve tranches, all Strategy D, eight names.** `convergence_target` and `time_exit_date` are NULL on all twelve, so **no mechanical exit trigger can fire**.
- **The union is clean.** Broker share counts match BigQuery exactly: AMZN 0.3464, DIS 0.7244, GEV 0.1244, GOOGL 0.2577, ISRG 0.1091, RTX 0.1601, TSM 0.155, UBER 0.5156. **No RECONCILIATION-LAG position exists, so no alert is owed.**
- **Park sleeves:** VOO 17.7307 and SGOV 0.

### Per-strategy kill-trigger sweep

- **Strategy D** (`perf.kill_flags` as of 2026-10-13): `current_drawdown` −0.45%, `excess_vs_sgov` +8.32%, `deployed_days` 118. All five flags are FALSE, including `interim_underperf_warning`.
  - **Refreshed on the 10-14 IBKR closes:** the D book's market value moved 565.41 → **551.79 (−2.41%)**. That puts the drawdown at ~**−2.85%** from peak, nowhere near the −50% kill.
- **Strategy B** (stale as of 2026-08-18; capital-disabled): all flags FALSE.
- **A, C, E:** no positions.
- **Alerts and correlation.** No `interim_underperf_warning` alert is open or owed. **B pairwise correlation is inert:** `n_positions = 0`.

### Thesis-invalidation review

**No Development engaged any entry-record criterion.**

- **GEV** −6.20% (1004.04 → 941.78) fell on the CoreWeave AI-power contagion plus a Susquehanna PT trim. Its criterion is organic orders growth (below 15% for 2 quarters), and "short-term price action" sits on its own not-exit-triggering list. Q3 is 10-28. NOT met.
- **TSM** −3.40% (445.12 → 430.00) slid into its **10-15** Q3 print. Criterion 3 needs hyperscaler/Nvidia order cuts or a CoWoS utilization drop, and a customer's credit repricing is neither. Criteria 1 and 2 are tested by the print. NOT met.
- **UBER** −2.85% had no gross-bookings datum (M3 assessed all four criteria UNBREACHED on 10-01). NOT met.
- **AMZN** −1.74% had no AWS datum, and Anthropic's investor-day figures are not yet reported. **GOOGL** −1.74% had no Cloud datum.
- **DIS** +0.38%: the FCC suit is still pending, with no final order (criterion 5 not engaged). **ISRG** −0.43% and **RTX** +1.89% (defense bid): no criterion news; both report on 10-20.

**No dividend-netting test was reached.** **Watchlist candidates:** no Development changed the candidacy of any Strategy A queue name, and A remains `DO-NOT-ACTIVATE`.

## ANALYSIS — OPPORTUNITY CHECK

Evaluated against the reactive-cadence roster set (A, B, C, E).

- **Strategy B — seven US-listed names clear the frozen ≥5% floor on resolved own-event anchors; none is routed.** B is `DO-NOT-ACTIVATE` (10-06) and capital-disabled, so no `thesis-construction` identity is minted. Indexed:
  - **BSP:** the endorsement-driven repricing of a serial software acquirer.
  - **LQDA:** a litigation-overhang removal. Criterion 1's session is the open question.
  - **DELL, HPE, NTAP:** a sell-side downgrade cohort. Criterion 4 (information vs noise) is the crux, given the sector beta.
  - **IONQ:** a dilutive financing.
  - **MMED:** supply and overhang resolution.
  - **CRWV** is excluded because its anchor is unresolved.
- **Strategy A — no new candidate.** No name gained a newly announced catalyst within 6 months that fits A's thesis shape.
- **Strategy C — no new candidate.** C is FOMC-only. The hot CPI is an input to the in-pipeline `thesis-FOMC-C-20261020` for 10-28, not a new catalyst.
- **Strategy E — no new candidate.** DELL/HPE/NTAP against SMCI, and the CoreWeave-contagion names, are factor and sector moves, not intra-group mispricings. E is `DO-NOT-ACTIVATE`.

## ANALYSIS — ADD-CANDIDATE CHECK (Strategies A, B, D only)

Durable record, including every decline: **`d67db786-abc5-445a-bff6-0f2218221492`** (`add-candidate-review`). **12 evaluated, 0 flagged, 0 declined at the HARD GATE.**

| Position | mark vs cost | Trigger | Disposition |
|---|---|---|---|
| D:ISRG:2026-07-20 | +20.2367% | none | declined |
| D:TSM:2026-07-29 | +9.4474% | none | declined |
| D:GOOGL:2026-07-26 | +6.0384% | none | declined |
| D:RTX:2026-04-27 | +5.4106% | none | declined |
| D:AMZN:2026-07-09 | +5.3207% | none | declined |
| D:DIS:2026-08-05 | +5.0148% | none | declined |
| D:TSM:2026-07-21 | +0.4999% | none | declined |
| D:DIS:2026-05-07 | −2.0922% | dip-with-intact-thesis | declined |
| D:GEV:2026-08-03 | −2.8998% | dip-with-intact-thesis | declined |
| D:GOOGL:2026-07-09 | −3.3926% | dip-with-intact-thesis | declined |
| D:AMZN:2026-07-30 | −4.3708% | dip-with-intact-thesis | declined |
| D:UBER:2026-07-09 | −5.3510% | dip-with-intact-thesis | declined |

- **Price basis.** The numerator is the 2026-10-14 IBKR bar close; the denominator is the tranche's own `cost_basis / shares`.
- **HARD GATE — clear on all 12** for the tenth consecutive run. The three-disjunct, COALESCE-wrapped test was re-read immediately before the append; D2a had not run and no position event has landed since 10-01.
- **Why everything is declined.** No criterion datum arrived, and **D is `DO-NOT-ACTIVATE` and capital-disabled**, so no add has a funding path. TSM's 10-15 print is the next decisive datum.

## ANALYSIS — REGIME CHECK

**NO inter-monthly router review is recommended.**

- `state.current_regime` STRATEGY_ACTIVATION is unchanged:
  - B and D `DO-NOT-ACTIVATE` (10-06);
  - A and E `DO-NOT-ACTIVATE` (10-02);
  - C `HYBRID ACTIVATE (FOMC-only)`.
- FUNDAMENTAL_AXIS (as of 10-01) reads growth stable, inflation stable, policy hawkish, risk sentiment neutral, shock overlay acute.
- **What moved.**
  - **Inflation:** the hot CPI is one month's print, and the inflation axis was already scored "stable" on firming monthly prints.
  - **Policy:** the hike-odds jump reinforces the existing *hawkish* reading rather than changing it.
  - **Risk sentiment:** this is the axis to watch (VIX above its SMA, credit −0.90% vs SMA), but one session does not establish a regime change. M1a's month-end scoring owns it.
  - **Shock:** Gulf escalation keeps it acute.
  - Nothing clears D1's high bar. Default NO.

## EQUITY-BREADTH OBSERVATION

**48.31** for session **2026-10-14**, written to `events.regime_events` (`TECHNICAL_INPUT` / `EQUITY_BREADTH_PCT`). D2a owns the HEALTHY/WEAK call.

- **Barchart `$S5TH` (the declared primary)** answered on the advanced-depth `tavily_extract` path (cache-busted).
  - The page is headed "Quote Overview for Wed, Oct 14th, 2026": last **48.31 (−1.39)** stamped **17:04 ET**, Previous Close 49.70 (equal to the stored 10-13 value, so no revision), O 48.31 / H 48.31 / L 46.91.
  - **The on-page time is after 16:00 ET, so the settled-time check passes.**
- **Cross-check: EODData's settled table row for 14 Oct is identical** (O 48.31 / H 48.31 / L 46.91 / C 48.31). Its Low differs from its Close, so there is no unsettled tell. EODData's top quote box was a stale 15:57 snapshot (47.91) and was disregarded. **That gives two agreeing sources.**
- **MacroMicro was not probed.** The weekly re-probe rides the Sunday run.

## PARK ALLOCATION CALL

- **`vehicle`: VOO** (majority sleeve). **`target_f_pct` 25**: risk sleeve VOO 75%, defensive sleeve SGOV 25%.
  - **`direction`: de-risk.**
  - **`status`: BOUND.**
  - **`park_watch` false.**
  - Decision row `1cc33c99-74f1-45b9-abf3-58d11be4c29d`. Heartbeat written.
- **`conviction`: LOW, `conviction_pct` 35.**
- **`rationale`.**
  - **Two of the 10-13 call's named raise clauses fired on measured 10-14 closes:**
    - **(b)** HYG/IEF closed **−0.902% vs its 20d SMA**, past the −0.50% line.
    - **VIX** closed **16.87, above both 15 and its 20d SMA** of 15.4205. That is its first session above; clause (a) wanted two, but the volatility axis is now defensive and freshly entered.
  - **Hand-scored, the standing count is 5 and the firing count is 2**, so the increase gate is OPEN and the cap is 100.
  - **Sizing.** LOW 35 × cap 100 = 35, and the nearest step is **25**. No deviation was taken.
  - **Why 25 beats KEEP.** A hot CPI lifted hike odds on top of a credit-market scare spreading through AI-financed names. That is a rates-plus-credit shock with two independent measured axes entering the same session, exactly the shape the clauses pre-registered.
  - **Why not 50.**
    - SPY fell only 1.08% and still closes above its 50dma, so the index axis is not defensive.
    - The 10Y reversed into the close.
    - The selloff was a rotation into healthcare and staples (XLV +2.53, XLP +2.22), not indiscriminate.
    - This allocator's measured record is that de-risking costs against VOO: both closed AI-era defensive excursions lost (−2.841pp and −1.019pp).
- **Hand-scored axes, 2026-10-14 readings taken this session** (`state.park_axis_daily` carries every axis at `measured_on` 10-13; the overrides are in `fields.axis_overrides`):

  | Axis | Status | Reading |
  |---|---|---|
  | volatility | **DEFENSIVE, FIRING** | VIX 16.87 > 20d SMA 15.4205 and > 15 (overrides the carried reading) |
  | credit | **DEFENSIVE, FIRING** | HYG/IEF 0.85620 vs SMA 0.86400 (−0.902%) (overrides the carried reading) |
  | breadth | defensive, standing | 48.31 < 66 |
  | rates | defensive, standing | 10Y ~5.25% (secondary) ≥ 4.90 |
  | shock | defensive, standing | overlay `acute`; Brent 106.06 > 95 |
  | index | not defensive | SPY 769.60 vs 50dma 768.57 (+0.13%); −1.22% from its high |

- **Ladder.**
  - **The cap rises 75 → 100** on the standing count moving from 3 to 5. Caps step up immediately; decay governs only the way down.
  - f=25 sits under the cap, so no clamp applies.
  - **Crisis override not engaged** (SPY −1.08%, VIX 16.87 < 28).
- **`invalidation` — disjunctive both ways.**
  - **Return to f=0 on ANY ONE of:**
    - (a) VIX closes back below its 20d SMA;
    - (b) HYG/IEF closes back within 0.50% of its SMA.
    - Each mirrors a clause that carried this de-risk, so the way back is no harder than the way out.
  - **Raise to f=50 on ANY ONE of:**
    - (c) SPY closes below its 50dma while VIX stays above its SMA;
    - (d) HYG/IEF closes 1.25% or more below its SMA;
    - (e) the crisis override.
  - This binds no later session.
- **`theater_check`.** A red headline day makes a de-risk feel obligatory and KEEP feel complacent. This call is taken because two pre-registered clauses fired on measured closes and the gate opened. It is sized at one step because the allocator's own record says de-risking has cost money, not to look decisive.

---

## RECOMMENDED ACTIONS

**Exits triggered: none.** No open position carries a mechanical trigger, and no Development engaged any thesis-invalidation criterion.

**New entry candidates: none routed.** Strategy B is `DO-NOT-ACTIVATE` and capital-disabled. The seven resolved-anchor B-floor clearers are indexed below instead.

**Add candidates: none.**

**Router reviews: none.**

Watchlist updates (Strategy B new-entry index; each window runs 10 trading days from the anchor, and D2 computes the close date on the inclusive convention; source `research-screen` `c75cac94-6362-4cb3-923c-2f92811f86c2`):

- ADD **BSP** (Strategy B, `qualifying_event_date` 2026-10-14) — +41.2044% (37.86 → 53.46) on the 10-14 6-K Berkshire $330M private placement; index only.
- ADD **LQDA** (Strategy B, `qualifying_event_date` 2026-10-13) — +26.5946% (26.81 → 33.94) on the reaction session to the after-close 10-13 UTHR settlement; index only; the anchor-session move was −3.11%, so this carries the magnitude-clock caveat (open D2 notice, W5).
- ADD **DELL** (Strategy B, `qualifying_event_date` 2026-10-14) — −11.2740% (572.47 → 507.93) on the pre-open 10-14 Barclays downgrade to Equal Weight; index only; sector component noted.
- ADD **HPE** (Strategy B, `qualifying_event_date` 2026-10-14) — −8.2837% (68.81 → 63.11) on the pre-open 10-14 Barclays downgrade; index only.
- ADD **NTAP** (Strategy B, `qualifying_event_date` 2026-10-14) — −7.0332% (239.01 → 222.20) on the pre-open 10-14 Barclays downgrade; index only.
- ADD **IONQ** (Strategy B, `qualifying_event_date` 2026-10-14) — −9.5307% (34.73 → 31.42) on the pre-open 10-14 $2.0B registered direct offering; index only; a distinct event from the 10-12 Elisity anchor.
- ADD **MMED** (Strategy B, `qualifying_event_date` 2026-10-14) — −8.6413% (18.40 → 16.81) on Medtronic's 10-14 final exchange-offer exit; index only.

> NOTE (not a bullet): the park's GRADED DE-RISK to `target_f_pct` 25 is carried by `state.park_allocation_latest` (`1cc33c99`), not by this section or the block below.

```yaml d1_actions
- action: watchlist
  ticker: BSP
  strategy: B
  qualifying_event_date: 2026-10-14
  source_research_screen_id: c75cac94-6362-4cb3-923c-2f92811f86c2
  detail: ADD to B new-entry index — +41.2044% on the 10-14 6-K Berkshire $330M private placement; index only
- action: watchlist
  ticker: LQDA
  strategy: B
  qualifying_event_date: 2026-10-13
  source_research_screen_id: c75cac94-6362-4cb3-923c-2f92811f86c2
  detail: ADD to B new-entry index — +26.5946% reaction-session move to the after-close 10-13 UTHR settlement (anchor session -3.11%, magnitude-clock caveat); index only
- action: watchlist
  ticker: DELL
  strategy: B
  qualifying_event_date: 2026-10-14
  source_research_screen_id: c75cac94-6362-4cb3-923c-2f92811f86c2
  detail: ADD to B new-entry index — -11.2740% on the pre-open 10-14 Barclays downgrade to Equal Weight; index only
- action: watchlist
  ticker: HPE
  strategy: B
  qualifying_event_date: 2026-10-14
  source_research_screen_id: c75cac94-6362-4cb3-923c-2f92811f86c2
  detail: ADD to B new-entry index — -8.2837% on the pre-open 10-14 Barclays downgrade; index only
- action: watchlist
  ticker: NTAP
  strategy: B
  qualifying_event_date: 2026-10-14
  source_research_screen_id: c75cac94-6362-4cb3-923c-2f92811f86c2
  detail: ADD to B new-entry index — -7.0332% on the pre-open 10-14 Barclays downgrade; index only
- action: watchlist
  ticker: IONQ
  strategy: B
  qualifying_event_date: 2026-10-14
  source_research_screen_id: c75cac94-6362-4cb3-923c-2f92811f86c2
  detail: ADD to B new-entry index — -9.5307% on the pre-open 10-14 $2.0B registered direct offering; index only
- action: watchlist
  ticker: MMED
  strategy: B
  qualifying_event_date: 2026-10-14
  source_research_screen_id: c75cac94-6362-4cb3-923c-2f92811f86c2
  detail: ADD to B new-entry index — -8.6413% on Medtronic's 10-14 final exchange-offer exit; index only
```

## PROCESS NOTES

- **Pre-flight.** BigQuery and IBKR are both live. The run is logged on branch `claude/d1-2026-10-14`. The double-run guard found no prior completion. The history-depth precheck returned not shallow.
- **Frontier-LLM capability check (Wednesday battery: calibration).**
  - One `hf_fs` paper search ("LLM calibration confidence uncertainty estimation") returned five results. The newest is 2605.13484 (2026-05-13), so **nothing was published since the window floor**.
  - No `[HF Frontier-LLM Capture]` entry and no strategy-candidate row were written.
- **Durable records this run.**
  - `events.regime_events` 1 row (breadth 48.31).
  - `events.decision_log` 4 rows: `c75cac94` single-name screen, `ab91c8e7` sector screen, `d67db786` add-candidate review, `1cc33c99` park allocation. All four were checked after writing: `fields` parses, `routine='D1'` is on both screens, `surfaced_count` equals `ARRAY_LENGTH(passed)`, and `state.park_allocation_latest` surfaces the f=25 call.
  - `ops.heartbeat` 1 row.
  - `ops.web_calls` batch before run end.
- **Orchestration.** Six Sonnet workers ran:
  - an IBKR market-inputs and sweep worker;
  - a macro and scheduled-events worker;
  - a discovery and held-name news worker;
  - a breadth and HF worker;
  - an IBKR phase-2 measurement worker;
  - an attribution and market-cap worker.
  - The orchestrator itself made three FMP `profile-symbol` calls (DELL, HPE, NTAP caps). Worker call timestamps in `ops.web_calls` are approximate.
- **Degraded legs, stated.**
  - The IBKR VIX bar carries `delayed:900`. The volatility verdict holds at any print above 15.42.
  - The 10Y, Brent, gold and the dollar index are secondary readings; Brent's is a press-reported settle.
  - Release minutes are unverified for BSP, LQDA, IONQ, MMED and the Barclays note.
  - The SMR cap is disputed.
  - No after-hours 10-14 movers list was obtained.
  - None of these is load-bearing for a verdict except the LQDA magnitude clock, which is carried as a caveat into the index entry.

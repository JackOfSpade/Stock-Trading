2026-09-30
<!-- d1_scan_through_utc: 2026-09-30T22:15:00Z -->

# Daily Market Development Scan — 2026-09-30 (Wed, MT)

Scan window: 2026-09-29 16:20 MT → 2026-09-30 16:15 MT (**~23.9h — normal daily cadence**; resolved from the prior `Daily.md` marker `2026-09-29T22:20:00Z`, cross-checked against that file's commit at 2026-09-29T22:17:28+00:00 — agreement within 3 minutes). Exactly **one completed US trading session** in the window: **Wednesday 2026-09-30** (`state.trading_day_today`: `is_trading_day = true`), which was also month-end and quarter-end. Same-day double-run guard returned 0 D1 completions. Run as an orchestrator plus three read-only research/measurement sub-agents; every BigQuery write and every judgment below is the orchestrator's.

Tape: **good data, bad rates, narrow tape.** S&P 500 **7,651.54 (−0.3%)**, Dow **50,906.05 (−0.9%)**, Nasdaq Composite **26,861.06 (+0.2%)** (AP). IBKR RTH: SPY 764.20 → **762.63 (−0.2054%)**, QQQ +0.2494%. The morning brought the week's best macro news for risk: core PCE **3.0% y/y vs 3.3%** expected, Q2 GDP revised to **2.2%**, ADP **+90k**, Chicago PMI **58.8**. October hike odds fell to **~37%** (from ~50%). The long end sold off anyway: the 10Y closed **5.29%** (AP; WSJ reports a 5.304% intraday print, highest since May 2002 on its series) and the 30Y **5.64%**. Breadth fell to **40.55**, and SPY closed **0.0146% below its 50-day average**. **VIX 16.34.** Single-name action was event-heavy: **LQDA −57%** / **UTHR +13%** on a patent ruling, **JBL −10%** on a beat.

## TL;DR

- **Exits triggered: none.** Twelve open tranches, all Strategy D. None carries a `convergence_target` or a `time_exit_date`, and no Development engaged any thesis criterion.
- **New entry candidates: none routed.** Four names clear Strategy B's frozen ≥5% floor. Three have resolved anchors (LQDA, UTHR, JBL). B is `DO-NOT-ACTIVATE` and capital-disabled (NAV $0.00), so they go to the state index only.
- **Add candidates: none (0 of 12).** Nine declined on the merits. Three blocked at the HARD GATE (ISRG, RTX, UBER) for the **eighth** consecutive cycle.
- **Watchlist: 3 changes.** ADD LQDA, UTHR, JBL (anchor 2026-09-30) to the Strategy B new-entry index.
- **Regime review: no review.** M1a/M1b re-score tomorrow (2026-10-01).

> **NOTE (not a bullet, and deliberately not a `d1_actions` entry): PARK ALLOCATION CALL — KEEP `target_f_pct` 25 (VOO 75 / SGOV 25), BOUND, LOW-MEDIUM 35.** D2 reaches this through `state.park_allocation_latest` (`3e93a408-8244-4e27-85ee-4a2ec7d9b474`). The increase gate is open, but the one new defensive axis is a 0.0146% hairline cross, so no increase. None of yesterday's return-to-f=0 conditions fired.

---

## DEVELOPMENTS

### 1. Market-wide breaking events

- **Rates: the 10Y made a new cycle high on a cool-inflation day.** 10Y closed **5.29%** (5.26% Tuesday), after dipping to ~5.20–5.22% on the PCE print (AP; Capital Street FX). The 30Y closed **5.64%** (5.59%). The 2Y ended **4.89%**, unchanged, after touching ~4.83%. A falling policy path with a rising long end is again a term-premium move, not a policy move.
- **Fed pricing.** CME FedWatch October hike odds **~37%**, down from ~50% Tuesday and >70% a week ago (AP, WSJ). Context: the Fed hiked 25bp to 3.75–4.00% on 09-16; the next FOMC is 10-27/28.
- **FTC confirms an investigation of AI labs** (OpenAI, Anthropic and others; AP, CBS, CNBC, WSJ, NYT, 2026-09-30). It is investigative only; compulsory requests are planned "in the coming weeks". The trigger is the July agent intrusion into Hugging Face. No market reaction figure was found.
- **Iran / Hormuz.** Kpler (via CNBC) puts the 7-day average of Hormuz crude flows at **13.5 mb/d**, back to pre-war levels, though refined products remain constrained. The IRGC says the strait is "not normal". Qatar is still mediating. There is no deal.
  - **Brent: AP settle $98.03 (+1.9%)**, contract month not stated by AP (December is the likely reference; December settled $96.16 Tuesday). WSJ quoted front-month (expiring November) at ~$103.53 intraday. No November settle was found. Both sit above the park's $95 shock line.
  - WTI settle, gold close and DXY close were not found. DXY was ~101.20 intraday after the PCE print.
- **No October 1 shutdown risk.** Agencies are funded through 2026-12-11 (FedWeek/AFGE).
- **Other AI items.** Anthropic's prospectus (reported 09-29) continued to circulate: a >$2T valuation target (Reuters), ~$518B of forward compute obligations (Substack, single-source), and a warning of "existential risks" (FT, single-source). Google announced Gemini 4 "Argon" with no release date (Reuters). Nvidia's record $150B buyback increase dates from 09-28.
- **No material bankruptcy, disaster or enforcement action** affecting global risk assets was identified.

### 2. Scheduled events that resolved in the window

**EVENT-IDENTITY GATE applied.** Figures marked issuer-sourced come from the issuer release or 8-K; consensus figures are secondary.

- **US macro, all released pre-open 09-30:**

  | Release | Actual | Consensus | Prior |
  |---|---|---|---|
  | August core PCE y/y | **3.0%** | 3.3% | — |
  | August headline PCE y/y | 3.4% | 3.7% | 3.4% |
  | August core PCE m/m | +0.2% | +0.3% | — |
  | Q2 GDP, third estimate | **+2.2%** | 1.5% | 1.5% |
  | ADP private payrolls (Sep) | **+90k** | ~70–74k | 36k |
  | Chicago PMI (Sep) | **58.8** | 51.2 | 47.1 |
  | Personal income / spending (Aug) | +0.2% / +0.9% | 0.4–0.5% / 0.8–0.9% | — |

  Sources: CNBC (PCE), WSJ (GDP), Chrisman Commentary (ADP; personal income/spending, single-source), Trading Economics (Chicago PMI). Pending home sales and Australian CPI were not found.
- **Abroad.** Germany's flash CPI **3.3%** vs 2.9% (the euro-area aggregate was not found). China's official manufacturing PMI **50.1**, the first expansion since June.
- **Fed speakers.** Governor **Cook** (federalreserve.gov, cook20260930a): inflation "too high for too long"; she supported the September hike. Goolsbee, Kashkari and Barkin were scheduled; their content was not retrieved. A Barr "further hikes likely" item has an ambiguous 09-29/09-30 date and is treated as unverified.
- **Earnings.**
  - **JBL — Jabil, fiscal Q4 (ended 08-31). ISSUER-SOURCED** release and 8-K dated 09-30; pre-open (Barron's reported premarket trading). Revenue **$10.6B** vs $9.69B; core EPS **$4.40** vs $4.06. FY27 guide revenue $44.5B, core EPS $17.55, AI-related revenue +54% to $22.1B. IBKR close-to-close **−10.0301%**.
  - **CAG — Conagra, fiscal Q1 FY27. ISSUER-SOURCED**, PRNewswire **07:30 ET** 09-30. Adjusted EPS $0.41 vs $0.28; net sales $2.596B (−1.4%); FY27 guide reaffirmed. IBKR **−4.8832%**.
  - **FDS — FactSet, fiscal Q4.** Pre-open 09-30 (issuer minute not extracted). Adjusted EPS $4.52 vs $4.38; revenue $634.7M vs $636.1M. IBKR **+3.8389%**.
  - **MU — Micron, fiscal Q4. ISSUER-SOURCED**, GlobeNewswire **16:01 ET 09-30, after the close.** Revenue $54.23B vs ~$51.1–51.5B; adjusted EPS $33.42 vs ~$31.6–31.8; guide $61.5B ±$1.5B vs ~$56.8B. **The anchor is 2026-09-30; the reaction session is 2026-10-01**, so there is no screen item today. MU closed +0.0028% in regular hours.
  - **CALM** reported a larger-than-expected loss (AP); not issuer-verified. **Progress Software** reported after the close; results not retrieved, **PENDING**. WDAY (09-29 after the close) moved +0.6819%.
- **FDA.**
  - **BMY Camzyos (mavacamten), pediatric oHCM: APPROVED 2026-09-30**, confirmed on the FDA's own page (fda.gov, "FDA approves first drug to improve functional capacity and symptoms in children with rare inherited heart…"). Sponsor BMY. BMY moved +0.11% (third-party).
  - **Teva Degevma (denosumab-adet): approved 2026-09-28, before the window.** Teva's own release (GlobeNewswire/IR) is dated Sept. 28; clock time not retrieved. **Yesterday's UNRESOLVED item is closed as out-of-window.**
  - Other approvals seen in aggregator roundups (tavapadon, zilurgisertib, efsitora, Gazyva, belzutifan+lenvatinib) were **not resolved against fda.gov** and are not recorded as dated actions.

### 3. Large single-name moves — AI-SIGNIFICANCE SCREEN

Durable record: `events.decision_log` **`795e6fb0-825d-4b57-83bd-08cc54d2e362`** (`research-screen`, `single-name-move`). **59 names measured, 11 surfaced (`surfaced_count` = `ARRAY_LENGTH(passed)` = 11), `rail_tally` 16, agreement both 4 / ai_only 7 / rule_only 2.**

- **Measurement basis.** Every move is an IBKR RTH daily bar read from the **close array at both ends**. Caps come from FMP `profile-symbol`. One 16-way parallel IBKR batch was taken before the orchestrator relayed the `7cc25b71` concurrency warning; every series in it was re-pulled at ≤3 concurrency and matched exactly.
- **Selection rule.** A union of FMP most-active/gainers/losers, ~20 wide Tavily mover and event searches, the news worker's earnings list, all held names, and the prior session's B-index names. This is a bounded scan, **not an enumeration**, so `surfaced_count` is a floor.

| Name | prior → event close | move % | conv | anchor (qualifying_event_date) | ≥5% | driver |
|---|---|---|---|---|---|---|
| **LQDA** | 70.69 → 30.26 | **−57.1934** | 75 | **2026-09-30** (intraday) | yes | Delaware court: Yutrepia infringes two claims of UTHR's '327 patent; halted intraday. Cap after the move ~$2.69B (borderline) |
| **UTHR** | 481.47 → 541.89 | +12.5491 | 60 | **2026-09-30** (intraday) | yes | Same ruling, other side — one event with LQDA |
| **JBL** | 318.84 → 286.86 | **−10.0301** | 60 | **2026-09-30** (pre-open) | yes | Issuer-verified beat-and-raise sold hard |
| MRNA | 203.46 → 192.57 | −5.3524 | 45 | **UNRESOLVED** (leans 09-30) | yes | Citi cut to Sell; note time not established |
| CAG | 14.13 → 13.44 | −4.8832 | 45 | 2026-09-30 (07:30 ET) | no (`below_spec_floor`) | EPS beat, sales −1.4% |
| GIS | 33.82 → 32.16 | −4.9083 | 30 | UNRESOLVED | no | CEO succession; weak causation in a staples sell-off |
| NOC | 504.61 → 483.48 | −4.1874 | 60 | **2026-09-29** (after close) | no | Lost Navy F/A-XX to Boeing (~$20B); BA itself −0.8685% |
| HPE | 61.49 → 63.89 | +3.9031 | 45 | UNRESOLVED | no | Raised networking revenue forecast (AP) |
| FDS | 259.97 → 269.95 | +3.8389 | 45 | 2026-09-30 (pre-open) | no | FQ4 EPS beat; reversed a −3% premarket |
| GME | 23.76 → 24.65 | +3.7458 | 30 | 2026-09-29 (after close) | no | CEO Cohen's $10.6M Form 4 purchase |
| MDB | 337.19 → 348.61 | +3.3868 | 30 | UNRESOLVED | no | $1B buyback increase after the CEO's exit (AP) |

- **The headline item is LQDA/UTHR.** A court ruling is binary, public and dated to the session. It removed most of the value of Liquidia's only commercial product. Recorded as **one event with two sides**, not two independent candidates.
- **JBL is the cleaner information-vs-sentiment case.** An issuer-verified beat and a guide with AI revenue +54% drew a 10% sell-off, probably positioning after a strong run (52-week range 189.6–428.93 per FMP).
- **CROSS-ROW CLOSE-CHAIN CHECK: 4 hits, none on a passed item** (one read, research-screen rows 2026-09-14..09-29).
  - FICO (617.87 → 592.47, −4.1109), AIR (106.75 → 101.47, −4.9461) and SMMT (+3.1727) each have a `prior_close` equal to the `f93a84d0` item's `event_close` on the same after-close 2026-09-28 anchor. They are forward chains; **the earlier dispositions are carried forward, not re-screened.**
  - CCL (−2.2700) chains on a **pre-open** 2026-09-29 anchor, so today's pair is a session late and is not a qualifying measurement. The 09-29 measurement stands.
  - The worker proposed a 09-29 anchor for AIR. It is rejected: D1 verified the 16:50 ET 09-28 issuer stamp yesterday.
  - A clean pass is not a clearance (32% coverage).
- **Rejected but recorded (`rejected_notable`).**
  - **rule_only** ITUB (+5.4388) and MARA (−5.5046): no event.
  - HOOD (−3.2008): its pre-open product event ran the other way.
  - BE (−4.8996): day-2 reversal of 09-29's +10.8%, no event.
  - AGNC (−4.0212, rates), WMT (−2.6966), INTC (+3.7092): no company event.
  - Cap fails: SVRN (−25.77, ~$94M) and AI (+6.29, ~$1.67B).
- **Source disagreements, all re-derived; the IBKR close array stands.**
  - 24/7 Wall St's "September 30 close" article carries **09-29** data mislabelled by one day (BE, RCL, LITE, DUOL, AMAT, DKNG), and its SLB figure (−3.6%) disagrees with IBKR (−2.3060%).
  - LQDA press figures ranged "−25%" to "nearly −50%" intraday; IBKR close −57.1934%.
  - A Kalkine SMMT 09-29 close of $17.96 conflicts with IBKR's 16.39.
- **Discovered but NOT IBKR-measured (named per the REPORTING RULE):**
  - SCTX (~−20% per FMP, cap unchecked) and ASAN (~−4.2%, cap near the rail).
  - Named in news but not measured: AMD, LMT, ANET, ADBE, FORM, TSLA, LEN.
  - The FMP microcap tail was not cap-verified.
  - **Failed discovery legs:** two multi-topic Tavily queries returned nothing; no consolidated movers list was found; FMP most-active was ETF/penny-dominated.
- **Day-2 behaviour of yesterday's names** (context only): RCL +1.9910, DUOL −0.1543, AMAT −0.1230, LITE −0.2291, IOVA +2.5606, DKNG −3.0117.

### 4. Sector-level moves — AI-SIGNIFICANCE SCREEN

Durable record: **`bd235450-d4ec-4603-b784-6e8c6e2101b1`** (`sector-move`). **11 measured, 3 surfaced, `rail_tally` 5.** Dispersion 2.1699pp. No sector cleared the legacy 2% bar. All series re-pulled solo; no contamination.

| ETF | 09-29 → 09-30 | move % |
|---|---|---|
| XLK | 194.50 → 195.75 | **+0.6427** |
| XLE | 61.54 → 61.50 | −0.0650 |
| XLY | 109.15 → 108.84 | −0.2840 |
| XLC | 111.47 → 110.97 | −0.4486 |
| XLU | 39.71 → 39.44 | −0.6799 |
| XLB | 49.10 → 48.70 | −0.8147 |
| XLRE | 41.34 → 40.91 | −1.0402 |
| XLF | 54.01 → 53.40 | −1.1294 |
| XLI | 169.13 → 166.98 | −1.2712 |
| XLV | 170.73 → 168.42 | −1.3530 |
| XLP | 81.85 → 80.60 | **−1.5272** |

- **XLP (magnitude, conviction 60).** Staples were the worst sector on a day of data beats and a cool core PCE, with the 10Y at 5.29%. Tuesday's defensive bid (XLU +1.17) reversed into a bond-proxy sell-off: a rotation signal, not a staples event. CAG, GIS and WMT fit the pattern.
- **XLI (magnitude, conviction 45).** Industrials led the Dow's −0.9% despite the Chicago PMI beat; NOC contributed.
- **XLK (dispersion, conviction 45).** The only clearly positive sector (SMH +0.3460) into Micron's after-close beat.
- **Rejected but noted.** XLV, XLF and XLRE pass the 1% rail, but the same yield move explains them and no sector-specific driver was found. XLE was flat even with Brent up 1.9%.

### 5. Notable commentary

- **Fed.** Cook: inflation "too high for too long". NYT: Chair Warsh has avoided signalling the timing of further hikes.
- **Sell side.**
  - Citi cut **Moderna** to Sell (MRNA −5.35%).
  - HSBC upgraded **Target** to Buy (PT $190).
  - BofA upgraded Grocery Outlet to Buy; Oppenheimer upgraded NICE; Wells Fargo upgraded Pinnacle Financial.
  - BTIG raised its Palo Alto target to $425. UBS flagged added risk in Bristol's admilparant protocol changes.
- **Other commentary.**
  - Wells Fargo's Schlossberg (AP): "The consumer remains resilient, in a much better position than previously thought."
  - Rabobank's Michael Every (Reuters): Q3 "doused" lower-for-longer hopes "in scarce diesel".

## ANALYSIS — RISK TO EXISTING POSITIONS

### Mechanical exit-trigger sweep

Run for **every** position over the **union** of `state.current_positions` and live `get_account_positions`.

- **Twelve tranches, all Strategy D, eight names.** `convergence_target` and `time_exit_date` are NULL on all twelve, so **no mechanical exit trigger can fire**. This is a property of the book, not a skipped check.
- **The union is clean.** Broker share counts match BigQuery exactly on all eight names: AMZN 0.3464, DIS 0.7244, GEV 0.1244, GOOGL 0.2577, ISRG 0.1091, RTX 0.1601, TSM 0.1550, UBER 0.5156. **No RECONCILIATION-LAG position exists, so no `position_reconciliation_lag` alert is owed.**
- **Park sleeves.** The broker now holds **VOO 13.3239 / SGOV 30.8239**, the filled legs of D2's 09-29 de-risk (SELL 4.4412 VOO / BUY 30.8239 SGOV). `state.park_position_current` still shows VOO 17.7651 / SGOV 0 because D2a records fills after this run. That is the normal sequence, not a lag defect.

### Per-strategy kill-trigger sweep

- **Strategy D** (`perf.kill_flags` as of 2026-09-29): `current_drawdown` −2.27%, `excess_vs_sgov` +5.68%, `deployed_days` 108, 1 of 29 closed trades.
  - All five flags are FALSE, including **`interim_underperf_warning` FALSE**.
  - Refreshed against today's IBKR closes: the book moved between −1.3465% (ISRG) and +1.0054% (AMZN), nowhere near the −50% drawdown kill.
- **Strategy B** (stale as of 2026-08-18; capital-disabled): all flags FALSE.
- **A, C, E:** no positions.
- **Alerts and correlation.** No `interim_underperf_warning` alert is open or owed. **B pairwise correlation is inert:** `n_positions = 0`.

### Thesis-invalidation review

**No Development in the window engaged any position's entry-record invalidation criteria.** Every criterion is a multi-quarter fundamental metric, and no held company reported. Name-specific items:

- **AMZN.** Reports from the Anthropic prospectus put its AWS commitment at roughly a fifth of Amazon's ~$496B backlog (Substack, single-source, unverified). If confirmed, that is a reinforcing datum for criteria 3–4, not a breach. The FTC's AI-lab probe names Anthropic as a subject, not AWS.
- **GOOGL.** It appealed the EU DMA search-data-sharing order at the General Court (Reuters; filed 09-29). This continues the behavioral-remedy path already assessed as unbreached. Gemini 4 was announced.
- **TSM.** Reuters (two unnamed sources) reports TSMC is evaluating a Texas fab beyond its Arizona commitment. This is capacity news; no criterion is touched.
- **DIS.** About 300 layoffs (third round) and Disney+ price increases taking effect. Cost and pricing items; no criterion is touched.
- **RTX.** Q3 date set (10-20); the AMRAAM award is from 09-28. **NOC's F/A-XX loss is not an RTX event.**
- **ISRG, GEV, UBER.** Nothing material. UBER sits near its 52-week low (68.51 vs 65.41) with no bookings, margin or Uber One news.

Held-name moves: AMZN +1.0054, GOOGL +0.9269, TSM −0.1641, DIS −0.4838, RTX −0.6901, UBER −1.2255, GEV −1.2468, ISRG −1.3465.

**No dividend-netting test was reached.** `state.price_level_criterion_drift` carries one row (D:DIS:2026-08-05), and it is a sizing notional, not an actionable price level.

**Watchlist candidates.** No Development changed the candidacy of any Strategy A queue name. A remains `DO-NOT-ACTIVATE` pending tomorrow's re-score.

## ANALYSIS — OPPORTUNITY CHECK

Evaluated against the reactive-cadence roster set (A, B, C, E).

- **Strategy B — four names clear the frozen ≥5% floor; three have resolved anchors; none is routed.** B is `DO-NOT-ACTIVATE` and capital-disabled (`analytics.strategy_nav` B: nav 0, available_funds 0, sizing_base_2pct 0, read this session). No `thesis-construction` identity is minted, and field-based dedupe is not reached. The three are indexed:
  - **LQDA (anchor 2026-09-30): the most information-dense event, and the hardest to read.** A patent-infringement ruling is real information. A thesis session would have to judge whether −57% overshoots the value left after appeal and design-around options, and whether a ~$2.7B post-move cap sits too near the rail.
  - **UTHR (2026-09-30): the same event from the other side.** A thesis session should treat LQDA/UTHR as a single event.
  - **JBL (2026-09-30):** a verified beat-and-raise sold 10%. This is exactly B's information-versus-sentiment question.
  - **MRNA clears the floor with an `UNRESOLVED` anchor and is NOT indexed.** A defaulted anchor is the failure mode the 2026-09-21 ANCHOR CONVENTION limb closed.
- **Strategy A — no new candidate.** No name acquired a newly announced catalyst within 6 months.
- **Strategy C — no new candidate.** No newly announced qualifying catalyst within 45 days.
- **Strategy E — no new candidate.** LQDA/UTHR is one legal event transmitted in opposite directions: a permanent repricing, not a divergence expected to converge. E is `DO-NOT-ACTIVATE`.

## ANALYSIS — ADD-CANDIDATE CHECK (Strategies A, B, D only)

Durable record, including every decline: **`8176efce-77f3-417a-9ec5-c125c46133ab`** (`add-candidate-review`). **12 evaluated, 0 flagged, 3 declined at the HARD GATE.**

| Position | mark vs cost | Trigger | Disposition |
|---|---|---|---|
| D:ISRG:2026-07-20 | +16.3427% | none | **declined_hard_gate** |
| D:TSM:2026-07-29 | +16.1135% | none | declined |
| D:TSM:2026-07-21 | +6.6210% | none | declined |
| D:GOOGL:2026-07-26 | +4.9525% | none | declined |
| D:RTX:2026-04-27 | +4.9470% | none | **declined_hard_gate** |
| D:AMZN:2026-07-09 | +3.2771% | none | declined |
| D:DIS:2026-08-05 | +1.0740% | none | declined |
| D:GEV:2026-08-03 | −2.0018% | none | declined |
| D:GOOGL:2026-07-09 | −4.3819% | dip-with-intact-thesis | declined |
| D:DIS:2026-05-07 | −5.7663% | dip-with-intact-thesis | declined |
| D:AMZN:2026-07-30 | −6.2264% | dip-with-intact-thesis | declined |
| D:UBER:2026-07-09 | −6.4165% | dip-with-intact-thesis | **declined_hard_gate** |

**Price basis (2026-09-07 pin).** The numerator is the 2026-09-30 IBKR bar close. The denominator is the tranche's own `cost_basis / shares`. The broker position endpoint again served non-close marks: GOOGL 348.65 vs the bar's **344.08**, DIS 105.00 vs **104.90**, ISRG 407.00 vs **406.63**.

**HARD GATE.** Seven tranches carry `$.breach_status = 'NOT_ASSESSED_BY_THIS_BACKFILL'`, evaluated with all three disjuncts and COALESCE-wrapped. AMZN, DIS, GOOGL and TSM are covered at name level by a later fresh-assessment tranche. **ISRG, RTX and UBER are covered nowhere and are structurally ineligible for the eighth consecutive cycle.** The gate stays fail-closed, and M3 owns the backfill.

**Why the gate-clearing dips are declined.** AMZN:07-30, DIS:05-07 and GOOGL:07-09 carry genuine dips with clear gates. The markdowns are macro and discount-rate sourced, and nothing verified *reinforces* a thesis. The AMZN prospectus figures are single-source, and the FTC probe cuts the other way.

## ANALYSIS — REGIME CHECK

**NO inter-monthly router review is recommended.** The scheduled **M1a/M1b re-score runs tomorrow, 2026-10-01**, so an out-of-cycle review would add nothing.

`state.current_regime` FUNDAMENTAL_AXIS (as of 2026-09-01) reads growth decelerating, inflation disinflating, policy hawkish, risk sentiment risk-on, shock overlay acute. Today's evidence splits by axis:

- **Growth.** GDP 2.2, ADP +90k and Chicago PMI 58.8 argue *against* "decelerating". This is M1a's call.
- **Inflation.** Core PCE 3.0 vs 3.3 supports "disinflating".
- **Policy.** Hike odds are falling, but the long end is rising.
- **Shock.** Brent is back above $98 with Hormuz crude flows normalised; the overlay still reads acute.
- **Risk sentiment is the axis with a real claim to review.** It was scored on breadth "healthy at 66.2%", and breadth is now **40.55**, the lowest of 39 readings. Flagged for M1a again; no out-of-cycle action.

## EQUITY-BREADTH OBSERVATION

**40.55** for session **2026-09-30**, written to `events.regime_events` (`TECHNICAL_INPUT` / `EQUITY_BREADTH_PCT`). D2a owns the HEALTHY/WEAK call.

- **Source: Barchart `$S5TH`** (the declared primary), cache-busted, via `tavily_extract` at **advanced** depth. Published as `40.55 −2.59 (−6.00%)`; on-page wording *"Quote Overview for Wed, Sep 30th, 2026"*.
- **Both settlement limbs pass:** the date is the claimed session, and the stamp is **17:50 ET**, after the close.
- **Low == Close (40.55) on Barchart.** This is not the EODData unsettled tell: the post-close stamp shows the index genuinely closed at its session low.
- **Single usable settled source, stated as such.** EODData read 40.95 but was stamped **15:55** (before the close), so it is not counted. The gap is −0.40pp, far inside the 5pp bar.
- **MacroMicro not attempted, and none was due:** the re-probe rides on the Sunday run.
- **Prior-session revision check:** Barchart's Previous Close reads **43.14**, matching the stored 09-29 row exactly.
- **Context, computed** from `events.regime_events`. 40.55 is the **lowest of the 39 readings** since 2026-08-05 (prior minimum 43.14, 2026-09-29). The **−2.59pp** change is the **7th largest of 28** day-over-day declines.

## PARK ALLOCATION CALL

- **`vehicle`: VOO** (majority sleeve). **`target_f_pct` 25**: risk sleeve VOO 75%, defensive sleeve SGOV 25%.
  - **`direction`: keep** (standing f=25).
  - **`status`: BOUND.**
  - `park_watch` false.
  - Decision row `3e93a408-8244-4e27-85ee-4a2ec7d9b474`.
- **`conviction`: LOW-MEDIUM, `conviction_pct` 35.**
- **`rationale` — why an open gate does not become an increase.**
  - **The gate is open on hand-scoring:** standing count 5, and firing count 2 (index entered today; volatility is still inside its 2-session event window from 09-28).
  - **The only NEW axis is a hairline.** SPY 762.63 sits 0.0146% under its 50dma of 762.7414, on a −0.2054% day. That is the threshold-flicker shape the 2026-09-28 call declined to count on volatility, so it is recorded as standing but given near-zero weight as new evidence.
  - **The information flow ran FOR risk:** core PCE 3.0 vs 3.3, GDP 2.2, ADP and Chicago PMI beats, October hike odds ~50 → 37, Nasdaq +0.2%. Credit still sits above its average.
  - **Against:** breadth −2.59pp to a series-low 40.55, and the 10Y at 5.29% on a cool-inflation day.
  - **The evidence moved both ways and nets to no change in conviction.** A quarter of the park remains its honest size.
- **Hand-scored axes, from readings taken this session:**

  | Axis | Status | Reading |
  |---|---|---|
  | volatility | defensive, standing (entered 09-28) | VIX 16.34 > 15 and > its 20d SMA 15.8095; third consecutive close above both |
  | breadth | defensive, standing | 40.55 < 66 |
  | rates | defensive, standing | 10Y 5.29%, 30Y 5.64% |
  | shock | defensive, standing | overlay `acute`; Brent 98.03 > 95 |
  | index | **defensive by the letter, ENTERED today** | SPY 762.63 vs 50dma 762.7414 (−0.0146%); drawdown from 777.88 is −1.9605% |
  | credit | **not** defensive | HYG/IEF 0.864517 vs 20d SMA 0.862912, +0.1860% (from +0.2565%) |

  - **`state.park_axis_daily` 2026-09-30** carries all six axes at `measured_on` 2026-09-29 (`axes_measured_today` 0: standing 4, firing 0, gate closed) because D2a has not run. Every level here is recomputed from this session's readings. `fields.axis_overrides` records index (carried not-defensive → measured defensive) and breadth (fresher reading, same verdict).
  - **Crisis override not engaged:** SPY −0.2054% vs −2.5%; VIX 16.34 vs 28.
- **Ladder.** Confirmed cap **100** (raw cap 100; clamp non-binding). 0.35 × 100 = 35. |35−25| = 10 < |35−50| = 15, so the nearest step is **25**, which equals the standing f. No deviation was taken, and no decay applies.
- **Prior invalidation honoured.** Yesterday's (`2100112b`) return-to-f=0 conditions were ANY ONE of:
  - (a) VIX < 15 — **not met** (16.34);
  - (b) VIX below its 20d SMA on two sessions — **not met** (above);
  - (c) breadth > 50 with SPY above its 50dma — **not met** (40.55; below).
- **`invalidation` — disjunctive, no higher than the de-risk bar.**
  - **Return to f=0 on ANY ONE of:** (a) VIX closes below 15; (b) VIX closes below its own 20d SMA on two consecutive sessions; (c) breadth closes above 50 with SPY above its 50dma.
  - **Raise to f=50 on ANY ONE of:** (d) SPY closes below its 50dma a second consecutive session by more than a flicker (>0.25%) while breadth stays below 50; (e) HYG/IEF closes below its 20d SMA; (f) the crisis override.
  - This binds no later session.
- **`theater_check`.** The easy essay for f=50 was available: five standing axes, an open gate, breadth at a series low, and a WSJ-reported 24-year-high 10Y. It is rejected because the only NEW axis is a 1.5bp cross. The easy essay for f=0 (the best macro day of the week, Nasdaq up) is rejected because none of yesterday's pre-named return conditions fired. **Counter-test:** had SPY closed at 757 (−0.75% below its 50dma) with HYG/IEF under its average, this would be a raise to 50.

---

## RECOMMENDED ACTIONS

**Exits triggered: none.** No open position carries a mechanical trigger, and no Development engaged any thesis-invalidation criterion.

**New entry candidates: none routed.** Strategy B is `DO-NOT-ACTIVATE` and capital-disabled (NAV $0.00). The three resolved-anchor B-floor clearers are indexed below instead.

**Add candidates: none.**

**Router reviews: none.** Risk-sentiment scoring is flagged for tomorrow's scheduled M1a re-score rather than for an out-of-cycle review.

Watchlist updates (Strategy B new-entry index; each window runs 10 trading days from the anchor, D2 to compute the close date on the inclusive convention; source `research-screen` `795e6fb0-825d-4b57-83bd-08cc54d2e362`):

- ADD **LQDA** (Strategy B, `qualifying_event_date` 2026-09-30) — −57.1934% (70.69 → 30.26) on the intraday Delaware ruling that Yutrepia infringes United Therapeutics' '327 patent; post-move cap ~$2.69B (borderline); index only, B capital-disabled.
- ADD **UTHR** (Strategy B, `qualifying_event_date` 2026-09-30) — +12.5491% (481.47 → 541.89) on the same ruling, the same event as LQDA, not an independent one; index only.
- ADD **JBL** (Strategy B, `qualifying_event_date` 2026-09-30) — −10.0301% (318.84 → 286.86) on the pre-open fiscal-Q4 beat-and-raise sold hard; index only.

> NOTE (not a bullet): the park KEEP at `target_f_pct` 25 is carried by `state.park_allocation_latest`, not by this section or the block below.

```yaml d1_actions
- action: watchlist
  ticker: LQDA
  strategy: B
  qualifying_event_date: 2026-09-30
  source_research_screen_id: 795e6fb0-825d-4b57-83bd-08cc54d2e362
  detail: ADD to B new-entry index — -57.1934% on intraday 09-30 Delaware patent ruling (Yutrepia infringes UTHR '327); post-move cap ~$2.69B borderline; index only
- action: watchlist
  ticker: UTHR
  strategy: B
  qualifying_event_date: 2026-09-30
  source_research_screen_id: 795e6fb0-825d-4b57-83bd-08cc54d2e362
  detail: ADD to B new-entry index — +12.5491% on the same 09-30 ruling (same event as LQDA); index only
- action: watchlist
  ticker: JBL
  strategy: B
  qualifying_event_date: 2026-09-30
  source_research_screen_id: 795e6fb0-825d-4b57-83bd-08cc54d2e362
  detail: ADD to B new-entry index — -10.0301% on pre-open 09-30 FQ4 beat-and-raise; index only
```

## PROCESS NOTES

- **Frontier-LLM capability check (Wednesday battery: calibration).** One `hf_fs` paper search returned a single hit, arXiv 2412.15296 (2024-12-19), which pre-dates the window. **No `[HF Frontier-LLM Capture]` entry and no strategy-candidate row were written.** The standing `56dde459` notice describes exactly this outcome and remains open with W5.
- **Durable records this run.**
  - `events.regime_events` 1 row (breadth).
  - `events.decision_log` 4 rows: `795e6fb0` single-name screen, `bd235450` sector screen, `8176efce` add-candidate review, `3e93a408` park allocation.
  - `ops.heartbeat` 1 row.
  - `ops.web_calls` batch before run end.
- **IBKR concurrency defect (`7cc25b71`, OPS1-owned).** The orchestrator read the open alert mid-run and relayed it to both measurement workers. Each had already run large parallel batches (up to 16-way). Every series was re-pulled at ≤3 concurrency and **all matched exactly**, so this run observed no contamination. That is a bounded negative, not a clearance of the defect. Recorded, not re-raised.
- **Sub-agent discipline (open notice `959693b5`).** The screen worker again issued several narrow per-name "why did X move" searches after its wide sweeps, and two multi-topic queries returned nothing. Recorded, not re-raised: `959693b5` already names it.
- **Degraded legs, stated.**
  - No WTI, gold or DXY close, and no November Brent settle, was found. AP's Brent contract month is unstated.
  - The Russell 2000 close was not found.
  - Release minutes were not retrieved for GIS, HPE, MDB or the Citi MRNA note (anchors UNRESOLVED), nor for JBL/FDS (dated pre-open by premarket-trading reports).
  - None of these is load-bearing for any action above.

2026-11-22
<!-- d1_scan_through_utc: 2026-11-22T22:21:28Z -->

# Daily Market Development Scan — session 2026-11-20 (Fri), run 2026-11-22 (Sun)

Scan window: 2026-11-19 15:31 MT → 2026-11-22 15:21 MT (~72 hours, a multi-session gap). The start is the prior `Daily.md` marker `2026-11-19T22:31:01Z`; git agrees (last Daily.md commit 2026-11-19T22:36:23Z). The gap is the normal Fri/Sat pause of the Sun–Thu cadence, not a missed run. It covers Thursday-evening prints, the whole Friday 11-20 session and the weekend.

SCAN MODE: ROUTER-GATED for A (DO-NOT-ACTIVATE), B (DO-NOT-ACTIVATE, held pending div-B-202611-3), D (DO-NOT-ACTIVATE) and E (DO-NOT-ACTIVATE, held pending div-E-202611-3), read live from `state.current_regime`. The single-name screen therefore runs in ROUTER-GATED mode (≥5% rail, free primary sources only, compact rejections). C is `HYBRID ACTIVATE (FOMC-only)`, so only its carve-out class is evaluated.

- **Indices (IBKR closes 11-19 → 11-20).** SPY 715.87 → 689.81 (−3.64%). SPX 6,910.39 (−3.70%; delayed index bar), its seventh straight loss and about 10% below the 10-06 record (correction). QQQ −5.67%, IWM −2.88%, SMH −10.60%. Nasdaq Composite −5.28% to 22,617.73; Dow −1.93% to 48,147.33 (CNBC/Yahoo). Week: S&P −8.6%, Nasdaq −10.0%.
- **Volatility.** VIX 28.44 → **35.89** (IBKR CBOE bar, delayed; Yahoo agrees), intraday high 40.03, the highest close since spring 2025. D2a classifies it.
- **What drove it.** An AI-led rout. Nvidia −12% (IBKR-screen close; −14% per wires) after a Reuters report that the SEC is probing its accounting, on top of the CEO turmoil; memory and semis −10% to −16% (MU, SNDK, WDC, AMD). Anthropic's IPO did not steady the AI trade (ANT about −8% on day two). Hawkish Fed repricing continued.
- **Data.** UMich final November sentiment 51.5 (prelim 51.0); 1-year inflation expectations 3.7% (from 4.7%), 5–10-year 3.3% (UMich). China's LPR unchanged for an 18th month (PBoC).
- **Rates, FX, commodities (secondary closes).** 10-year about 4.91% (−12 bp, fifth straight decline), 2-year about 4.62%. DXY about 103.84, off Thursday's 19-month high. Gold about 3,515 (−4.6%, a 14.5-month low), silver −7.4%. WTI settled 83.98. Bitcoin about $58–59k, first close under $60k since July.
- **Oil.** Brent (BZUSD, provisional same-evening read) **92.57 on 2026-11-20**, against 91.98 on 2026-11-19 in the same FMP series (+0.59). The 11-19 figure was restated from the stored 92.70.
- **Breadth.** **45.92** for 11-20 (Barchart `$S5TH`), down from 49.10. See EQUITY-BREADTH OBSERVATION.

## TL;DR

- **Exits triggered: none.** No tranche reaches a convergence target or time exit, kill flags are all FALSE, and no development meets a judgment invalidation criterion. ANDE's criterion-5 review trigger (close below $52) has been met since 11-18; it closed 44.97, and W4 already queued it for D2 on 11-23 (exit if unresolved), so it is not re-raised here.
- **New entry candidates: none routed as thesis handoffs.** B is DO-NOT-ACTIVATE, so the screen ran router-gated. 4 names passed and go to the B new-entry index (W2 ranks): INTU, GAP, BJ, BKE. 391 other ≥5% movers were rejected, almost all with no own event on an AI-led rout.
- **Add candidates: none (0 of 26).** B and D both read DO-NOT-ACTIVATE; ANDE is declined at the hard gate.
- **Watchlist: 4 changes.** ADD INTU, GAP, BJ, BKE to the Strategy B new-entry index.
- **Regime review: 1 flag, window PENDING.** A dated Gulf escalation cluster on 11-20/11-21 (three tankers struck near Khasab; Iranian drones and missiles at US bases in Bahrain) while `shock_overlay` reads latent. Oil window not yet closed; M1R rules.

Park: VOO-only pin verified

Paper book (J): 120 calls, 446/30 realized, net_mu -0.87%, ready=FALSE

## DEVELOPMENTS

### 1. Market-wide breaking events

**The AI unwind deepened.**
- Nvidia fell about 12–14% to roughly $125, its worst day since January 2025, after Reuters reported on 11-20 that the SEC is probing its accounting; its 10-Q is delayed and a board committee is investigating. This follows the CEO's resignation around 11-12 and a California AG subpoena on 11-19 (Reuters, CNBC, NYT; some figures secondary). Nvidia rose about 3.6% after hours.
- Semis and memory: SMH −10.6% (IBKR); MU −13.9%, SNDK −16.1%, AMD −13.2%, WDC −12.0% (Nasdaq closing prints). The PHLX semiconductor index hit a 7-month low (Reuters).
- Overseas Friday: Nikkei −5.1%, KOSPI −5.2% with a sidecar, SoftBank −14.5%, Taiwan's worst week in 35 years (CNBC, Bloomberg).
- The US Commerce rule on remote access to advanced chips (effective 11-19) stands; TSMC and Samsung paused some China orders pending licenses (Reuters/FT).
- After hours Friday: reports that CrowdStrike is in talks to buy Zscaler (not agreed) and of private-equity interest in Global Payments (GPN +10.0% in the session). Neither has an issuer filing.
- Weekend: President Trump said he would like Nvidia to reinstate Jensen Huang (Al Jazeera, 11-21) and signed an order on contractor communications with Congress (AP, 11-21). No bankruptcy or new enforcement action beyond the Nvidia probe was found.

**Iran / Hormuz / Gulf (channel: US blockade of Iranian ports plus Iran's restriction of Hormuz).** No ceasefire, settlement or blockade lift is in force. CENTCOM counted day 130 of the blockade on 11-21.
- 11-20 1500Z: UKMTO 214-26, an outbound tanker struck on the port bow by an unknown projectile 8nm north of Khasab; fire, no casualties (UKMTO).
- 11-21 0500Z and 0550Z: UKMTO 215-26 and 216-26, two more tankers hit 11nm north and 17nm east of Khasab; no casualties (UKMTO). Iran's navy claimed a mine strike (Iran International, secondary).
- 11-21 night: Iran fired two waves of drones and ballistic missiles at US bases in Bahrain. Bahrain intercepted several and a fire broke out at a civilian industrial site, no injuries (Al Jazeera; Euronews citing Fars). IRGC damage claims are unconfirmed.
- Talks only: a Qatari delegation met in Tehran on 11-20; Iran's two-day reopening plan "stays on the table"; Trump said Iran's terms are unacceptable and he is in no rush (Al Jazeera, Axios, Reuters). No tanker convoy has formed (Windward, 11-21).
- See REGIME CHECK for the flag.

### 2. Scheduled events that resolved in the window

Enumerated from the key-less Nasdaq earnings calendar for 11-19 (after-hours rows) and 11-20 (7 rows at ≥$2B). Release times are EDGAR acceptance stamps (UTC; ET = UTC−5).

- **Intuit (INTU)**, Q1 FY27, after the 11-19 close (8-K Item 2.02 at 21:08Z). Guidance cut and the agreed sale of Mailchimp to Bending Spoons for about $3.68B (8-K Item 1.01 at 22:26Z; deal value secondary). IBKR −12.77%.
- **Gap (GAP)**, Q3, after the 11-19 close (8-K 2.02 at 21:17Z). IBKR +11.44%.
- **Keysight (KEYS)**, FQ4, after the 11-19 close (8-K 2.02 at 21:09Z). −6.98%, inside a −8% to −10% test/semis peer sell-off.
- **ESCO (ESE)**, FQ4, after the 11-19 close (21:15Z), −5.53%. **Webull (BULL)**, Q3 6-K after the 11-19 close, −9.19%.
- **Elastic (ESTC)** and **Nike (NKE)**, deferred from 11-19 to this session: both moved less than 5% on 11-20.
- **BJ's Wholesale (BJ)**, Q3, pre-open 11-20 (8-K 2.02 at 12:01Z). IBKR −5.35% while staples rose.
- **IES Holdings (IESC)**, FQ4, pre-open 11-20 (8-K 2.02 at 12:49Z), −6.49% inside an AI-infrastructure contractor sell-off.
- **Buckle (BKE)**, Q3, 11-20 (8-K 2.02 at 18:18Z). IBKR +5.67%.
- Moog, Frontline and KT reported 11-20 and moved less than 5%.
- **FDA:** no novel approval after Regeneron's Livsayis (11-18) on the FDA's own list. Complete response letters reported for Capricor's deramiocel (11-20) and Summit's ivonescimab combination (date unstated; secondary). Belite Bio's tinlarebant review was extended to May 2027. Supplements: Sogroya (Turner syndrome) and Imfinzi plus EV (bladder cancer). These rest on press and trade sources, not the FDA's own CRL page, so they are recorded as reported, not verified.

### 3. Large single-name moves — AI-significance screen, ROUTER-GATED mode (B DO-NOT-ACTIVATE)

- **Population.** 2,074 US-listed names ≥$2B (Nasdaq screener list), all measured on dated 11-20 closing prints. 1,034 moved ≥2%; **395 moved ≥5%**.
- **Events.** One EDGAR submissions batch over all 387 non-warrant ≥5% names (filings accepted 11-19 20:30Z to 11-20 21:00Z), primary text for 9 filings, and the earnings calendar. No per-name news search (router-gated).
- **Passed (4, measured on IBKR bars):**
  - **INTU −12.77%** (310.02 → 270.44), conviction 75. After-close Q1 FY27 with a guidance cut and the Mailchimp sale; large software peers fell only 1.4–1.8%. 1 prior ≥5% session in the window (11-17 −7.17%, sector beta). Anchor 2026-11-19, reaction 11-20.
  - **GAP +11.44%** (18.79 → 20.94), conviction 60. After-close Q3, up against a −3.6% tape with apparel peers flat. 2 prior ≥5% sessions (11-16 −6.22%, and 11-19 −5.29% before the print). Anchor 2026-11-19, reaction 11-20.
  - **BJ −5.35%** (110.75 → 104.82), conviction 45. Pre-open Q3 while staples rose. Anchor 2026-11-20.
  - **BKE +5.67%** (41.78 → 44.15), conviction 45. Q3 on 11-20 (EDGAR stamp 18:18Z; the release time itself was not established, but any 11-20 release anchors there). 1 prior ≥5% session (11-06 −5.43%). Anchor 2026-11-20.
- **Rejected (391, compact by code):** 349 with no own event (market and AI/semis/crypto/fintech beta), 13 non-common listings, 12 ADRs below $10B, 8 own events inside peer beta (KEYS, IESC, PLXS, ESE, PYPL, AAL, BULL, GEO), 5 held names, 2 offerings (SLS, NSIT convertible notes) and 2 unresolved anchors (GPN on a buyout report, NVDA on the SEC-probe report; neither has an issuer filing).
- No deal-pinned target. Cross-row close-chain check: clean.
- Recorded in `events.decision_log` `research-screen` 182dc13e-a47e-4adb-8007-bb22b17bf553.

### 4. Sector-level moves (IBKR regular-session closes 11-19 → 11-20)

Six of 11 sectors cleared the 1% rail; five reached the old 2% bar.
- **XLK −7.27% (passed, 75):** the Nvidia probe report and the semis/memory collapse.
- **XLI −3.09% (passed, 45):** AI-infrastructure contractors (MTZ −12.2%, PRIM −10.8%, STRL −9.3%) and GEV −7.5%.
- **XLY −2.95% (passed, 45):** TSLA −7.6% and AMZN −4.1%.
- **XLC −2.66% (passed, 45):** META −5.9% and GOOGL −2.7%.
- **XLP +0.67% (passed as dispersion, 45):** the only sector up, on defensive rotation.
- Rejected as beta (30): XLF −1.82% (fintech and crypto), XLB −2.19% (gold −4.6%, silver −7.4%).
- Below the rail: XLV −0.12%, XLE −0.62%, XLU −0.74%, XLRE −0.98%.
- Recorded in `research-screen` 891ae9f6-d3ae-48e7-9627-47250bef73e7.

### 5. Notable commentary

- **Fed.** Governor Cook (Santiago, 11-20) said the policy rate is "not high enough" and backed further hikes; she estimates October PCE at 3.8% headline and 3.2% core (federalreserve.gov). Goolsbee and Paulson on 11-19 also leaned hawkish. Futures price a December hike at about 93% (secondary; CME FedWatch 98% per Reuters midday).
- **Strategists (secondary).** Goldman says a bottom needs AI-earnings confidence, a dovish Fed signal or a positioning flush. Baird sees conditions for a tactical low forming; Schwab says it is not capitulation yet. Average 2027 S&P 500 target across eight firms is about 8,638; UBS moved US equities to neutral.
- **Week ahead.** Thanksgiving week: consumer confidence and Dell (11-24); October PCE, a Q3 GDP revision and the Beige Book (11-25); markets closed 11-26; early close 11-27. FOMC 12-08/09.

## ANALYSIS — RISK TO EXISTING POSITIONS

**Mechanical sweep (union of `state.current_positions` and IBKR `get_account_positions`).** 26 strategy tranches plus the VOO park. Every connector position is in `state.current_positions`, so there is no reconciliation lag. Closes are IBKR 11-20 regular-session bars.

| Tranche | Close | Convergence target | Time exit | Triggered? |
|---|---|---|---|---|
| B:ANDE | 44.97 | 61.50 | 2027-01-15 | No |
| B:ARQT | 26.36 | 32.00 | 2027-01-15 | No |
| B:DDOG | 157.37 | 202.00 | 2027-01-15 | No |
| B:ECG | 76.59 | 103.00 | 2027-01-15 | No |
| B:EXPE | 234.96 | 290.00 (289.52 dividend-adjusted) | 2027-01-15 | No |
| B:IRTC | 94.72 | 111.00 | 2027-01-15 | No |
| B:MCY | 81.43 | 96.00 | 2027-01-15 | No |
| B:MTRN | 182.47 | 225.00 (224.855 dividend-adjusted) | 2027-01-15 | No |
| B:NRIX | 12.85 | 19.50 | 2027-01-15 | No |
| B:RELY | 19.83 | 24.50 | 2027-01-15 | No |
| B:ROK | 361.93 | 430.00 (428.55 dividend-adjusted) | 2027-01-15 | No |
| B:RVMD | 161.20 | 188.00 | 2027-01-15 | No |
| B:SM | 28.57 | 35.50 | 2027-01-15 | No |
| B:SYY | 78.17 | 81.00 | 2027-01-15 | No |
| D (12 tranches: AMZN ×2, DIS ×2, GEV, GOOGL ×2, ISRG, RTX, TSM ×2, UBER) | — | none | none | No |

**Kill-trigger sweep (`perf.kill_flags`, as of 11-19, refreshed against 11-20 closes).**
- B: drawdown −7.75% at the 11-19 engine row. The B book moved about −3.8% on 11-20, so roughly −11%. Far from the 50% kill. No runaway, evidence kill or interim warning.
- D: drawdown −11.18% at 11-19. The D book moved about −4.4% (TSM −9.5%, GEV −7.5%, AMZN −4.1%), so roughly −15%. No flags.
- `analytics.b_pairwise_correlation`: 14 positions, average correlation NULL (no pair has ≥40 overlap days yet), so no warning.
- Price-level lines (`state.price_level_criterion_drift`): MCY 81.43 vs its $79 review line, unbreached. ECG 76.59 vs $70.44, unbreached. ROK 361.93 is just above its $360 line. No dividend drift on these lines.

**Judgment invalidation sweep.** No development meets a criterion. No held name filed an 8-K or 6-K in the window (EDGAR batch over all 22 tickers).
- **ANDE −5.25% to 44.97 (new 52-week low):** criterion 5 (close below $52 on volume, a review trigger) has been met since 11-18. W4 queued `research-deferral-ANDE-B-2026W47` for D2 on 11-23 with exit-if-unresolved, so this run adds no action. Criteria 1–4 are not met: no deal, financing, 45Z or crush-margin news was found.
- **MTRN −10.02%:** no filing. Criterion 2 needs semiconductor customer capex or wafer-start cuts, or rules that materially hit AI-materials demand. The Commerce remote-access rule restricts Chinese designers' access to advanced nodes; it is not a customer capex cut. Not met.
- **ECG −8.66% and DDOG −5.46%:** AI-infrastructure and software beta. No hyperscaler capex pull-back (ECG criterion 3; DDOG criterion 2) and no company news.
- **EXPE −1.77%:** Bernstein cut its target to $261 (Market Perform) on 11-20. A single cut is not the consensus cut or downgrade wave of criterion 5. The separate extortion-group breach claim (Expedia calls it unverified) has no filing.
- **ROK −5.53% to 361.93:** no news; Mizuho raised its target to $415. Criterion 2 (FY27 EPS consensus below $14.55) is not met.
- **NRIX −5.51%, RVMD +1.12%:** no new clinical, safety or financing news. RVMD's 11-19 PDAC update came before the window. Both have W4 research deferrals due 11-23.
- **D:TSM (two tranches, −9.48%):** the semis rout and Taiex −6.2%. The export rule is not a hyperscaler or Nvidia order cut or a node push-out, so c1–c3 are not met.
- **D:GEV −7.53%:** AI-infrastructure beta and a reported analyst downgrade (firm not found). Its numeric criterion needs two quarters of data. Not met.
- **D:GOOGL −2.70%:** a Canadian-dollar debt offering (8-A12B/FWP) and an amended class-action complaint. No cloud or remedy criterion is touched.
- **ARQT, IRTC, MCY, RELY, SM, SYY, D:AMZN, D:DIS, D:ISRG, D:RTX, D:UBER:** no company development in the window touches a criterion. KeyBanc reiterated SM Overweight; DIS insiders filed Form 4s.

**Watchlist candidates.** No in-window development invalidates or advances a queued name beyond the screen items above.

## ANALYSIS — OPPORTUNITY CHECK

Reactive-cadence set: C (carve-out only). A, B, D and E are gated and not evaluated, except that B's ≥5% screen passes still reach the new-entry index as `watchlist` actions (below).
- **B:** 4 router-gated screen passes go to the new-entry index. W2 ranks them; D1 makes no thesis handoff.
- **C (FOMC-only carve-out):** Cook's call for more hikes and the 11-25 PCE print sharpen the 12-09 meeting, but that catalyst is already known. No new FOMC-class catalyst.

## ANALYSIS — ADD-CANDIDATE CHECK

26 tranches evaluated (14 B, 12 D, no A): 0 flagged, 25 declined, 1 at the hard gate. All are `invalidation_criteria_evaluable = TRUE`.
- **B tranches:** B is DO-NOT-ACTIVATE and VIX closed 35.89, so no add is proposed. **B:ANDE is declined at the hard gate**: its criterion-5 review trigger is met. Earlier sweeps declined ANDE without naming this criterion. Largest losses vs cost: ANDE −18.85%, NRIX −16.39%, DDOG −13.84%, SM −11.86%, RELY −11.39%.
- **D tranches:** criteria unbreached, but D reads DO-NOT-ACTIVATE (div-D-202611-1).

Recorded in `events.decision_log` `add-candidate-review` df1aff29-551e-4855-a3e2-9acc4df683c1.

## ANALYSIS — REGIME CHECK

**One geopolitical flag, window PENDING.**
- `shock_overlay` reads latent (M1R re-score 2026-11-22); the Gulf/Hormuz structure is open.
- **New dated cluster on 11-20 and 11-21, all on the named channel:** UKMTO 214-26 (11-20 1500Z), 215-26 and 216-26 (11-21), and Iran's drone and missile waves at US bases in Bahrain (11-21 night). These are escalations, not relief moves.
- **Oil leg (two-session window):**
  - Anchor 11-20: P 91.98 (BZUSD 11-19, restated) / S1 92.57 (11-20, provisional) = +0.59 / S2 11-23 not closed.
  - Anchor 11-21 (Saturday): P 92.57 / S1 11-23 and S2 11-24 not closed.
  - Neither window meets an oil criterion on the closed sessions. The flag is marked PENDING so D2 can log it and M1R can rule once S2 closes.
- M1R's 11-22 record already lists the 11-21 events as "(13) NEW PENDING, window INCOMPLETE". This flag is the producer step the plan requires, not a second ruling.
- No qualifying resolution event: nothing is signed, lifted or in force.

**Measured triggers (for D2 item 4, not computed here):** VIX closed 35.89, its second HIGH close. Breadth read 45.92, below 50 for a second session. SPY closed 689.81, below both its 50-day (761.67) and 200-day (732.69) averages as of 11-19; D2a classifies the trend.

## EQUITY-BREADTH OBSERVATION

- **Value written:** **45.92** for 2026-11-20 (`events.regime_events` `TECHNICAL_INPUT` / `EQUITY_BREADTH_PCT`).
- **Source:** Barchart `$S5TH` via Parallel `web_fetch`: "45.92 −3.18 (−6.48%) 11/20/26", "Quote Overview for Fri, Nov 20th, 2026", Previous Close 49.10, Open 52.48, High 54.07, Low 45.92. This is a single usable source.
- **Settled:** it was read on Sunday, two days after the session. The bar is not a vendor carry. Low equals close, which here reads as a close at the low on a −3.7% day.
- **ChartRow cross-check:** "as of market close, Nov 20, 2026", 228 of 497 eligible (45.88%). With no 11-19 ChartRow count on record, the check spans two sessions: −10.06pp on ChartRow vs −10.14pp on `$S5TH` (`chartrow_dod_gap=0.08`). Direction confirmed.
- **Sunday MacroMicro re-probe:** HTTP 403, so Barchart stays primary.

## ANALYSIS — FRONTIER-LLM CAPABILITY CHECK

NO CAPTURE. Sunday's long-context battery search returned only older papers (2410.03227, 2604.09494, 2411.08147, 2410.04422, 2509.13683). The date-ordered `hf://papers/daily/latest` listing was read and is empty on a Sunday, so no in-window paper exists to skim. Default is silent.

## RECOMMENDED ACTIONS

- Watchlist: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, router-gated screen; W2 ranks, no thesis handoff from D1): INTU — Q1 FY27 results with a guidance cut and the Mailchimp sale, after-close 8-K Item 2.02 accepted 2026-11-19 21:08Z (16:08 ET); reaction session 2026-11-20, -12.77% (310.02 -> 270.44), with 1 prior >=5% session in the window; qualifying_event_date 2026-11-19.
- Watchlist: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, router-gated screen; W2 ranks, no thesis handoff from D1): GAP — Q3 results, after-close 8-K Item 2.02 accepted 2026-11-19 21:17Z (16:17 ET); reaction session 2026-11-20, +11.44% (18.79 -> 20.94), with 2 prior >=5% sessions in the window (including the pre-print 11-19 -5.29%); qualifying_event_date 2026-11-19.
- Watchlist: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, router-gated screen; W2 ranks, no thesis handoff from D1): BJ — Q3 results, pre-open 8-K Item 2.02 accepted 2026-11-20 12:01Z (07:01 ET); reaction session 2026-11-20, -5.35% (110.75 -> 104.82); qualifying_event_date 2026-11-20.
- Watchlist: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, router-gated screen; W2 ranks, no thesis handoff from D1): BKE — Q3 results, 8-K Item 2.02 accepted 2026-11-20 18:18Z (13:18 ET); reaction session 2026-11-20, +5.67% (41.78 -> 44.15), with 1 prior >=5% session in the window; qualifying_event_date 2026-11-20.
- Router review (refresh-only, geopolitical qualifying event, window PENDING): Gulf/Hormuz escalation cluster dated 2026-11-20 (UKMTO 214-26, tanker struck 8nm N of Khasab) and 2026-11-21 (UKMTO 215-26/216-26, two tankers hit; Iranian drone and ballistic-missile waves at US bases in Bahrain), while `shock_overlay` reads latent. Inclusion criterion tested: the oil leg over the TWO-SESSION WINDOW. Closed sessions so far: P 91.98 (BZUSD 2026-11-19) -> S1 92.57 (2026-11-20) = +0.59; S2 2026-11-23 (and the 11-21 anchor's S1/S2 11-23/11-24) not closed. D2 logs it; M1R rules after S2 closes.

```yaml d1_actions
- action: watchlist
  ticker: INTU
  strategy: B
  qualifying_event_date: 2026-11-19
  source_research_screen_id: 182dc13e-a47e-4adb-8007-bb22b17bf553
  detail: "ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, router-gated screen; W2 ranks, no thesis handoff from D1): INTU — Q1 FY27 results with a guidance cut and the Mailchimp sale, after-close 8-K Item 2.02 accepted 2026-11-19 21:08Z (16:08 ET); reaction session 2026-11-20, -12.77% (310.02 -> 270.44), with 1 prior >=5% session in the window; qualifying_event_date 2026-11-19."
- action: watchlist
  ticker: GAP
  strategy: B
  qualifying_event_date: 2026-11-19
  source_research_screen_id: 182dc13e-a47e-4adb-8007-bb22b17bf553
  detail: "ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, router-gated screen; W2 ranks, no thesis handoff from D1): GAP — Q3 results, after-close 8-K Item 2.02 accepted 2026-11-19 21:17Z (16:17 ET); reaction session 2026-11-20, +11.44% (18.79 -> 20.94), with 2 prior >=5% sessions in the window (including the pre-print 11-19 -5.29%); qualifying_event_date 2026-11-19."
- action: watchlist
  ticker: BJ
  strategy: B
  qualifying_event_date: 2026-11-20
  source_research_screen_id: 182dc13e-a47e-4adb-8007-bb22b17bf553
  detail: "ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, router-gated screen; W2 ranks, no thesis handoff from D1): BJ — Q3 results, pre-open 8-K Item 2.02 accepted 2026-11-20 12:01Z (07:01 ET); reaction session 2026-11-20, -5.35% (110.75 -> 104.82); qualifying_event_date 2026-11-20."
- action: watchlist
  ticker: BKE
  strategy: B
  qualifying_event_date: 2026-11-20
  source_research_screen_id: 182dc13e-a47e-4adb-8007-bb22b17bf553
  detail: "ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, router-gated screen; W2 ranks, no thesis handoff from D1): BKE — Q3 results, 8-K Item 2.02 accepted 2026-11-20 18:18Z (13:18 ET); reaction session 2026-11-20, +5.67% (41.78 -> 44.15), with 1 prior >=5% session in the window; qualifying_event_date 2026-11-20."
- action: router_review
  ticker: n/a
  strategy: n/a
  qualifying_event_date: n/a
  source_research_screen_id: n/a
  detail: "Refresh-only geopolitical qualifying-event flag, window PENDING: Gulf/Hormuz escalation dated 2026-11-20 (UKMTO 214-26) and 2026-11-21 (UKMTO 215-26/216-26; Iranian drone and missile waves at US bases in Bahrain) while shock_overlay reads latent; oil leg over the two-session window so far P 91.98 (BZUSD 2026-11-19) -> S1 92.57 (2026-11-20) = +0.59, S2 not closed; M1R rules after S2 closes."
```

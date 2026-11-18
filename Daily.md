2026-11-18
<!-- d1_scan_through_utc: 2026-11-18T22:21:53Z -->

# Daily Market Development Scan — session 2026-11-18 (Wed), run 2026-11-18

Scan window: 2026-11-17 15:25 MT → 2026-11-18 15:21 MT (~24 hours). The start is the prior `Daily.md` marker `2026-11-17T22:25:19Z`; git agrees (last Daily.md commit 2026-11-17T22:30:32Z). This covers the Wednesday 11-18 session plus Tuesday-evening news (Nvidia's print).

SCAN MODE: ROUTER-GATED for A (DO-NOT-ACTIVATE), B (DO-NOT-ACTIVATE since D2 2026-11-17, VIX HIGH), D (DO-NOT-ACTIVATE) and E (DO-NOT-ACTIVATE since D2 2026-11-17), read live from `state.current_regime`. The single-name screen therefore runs in ROUTER-GATED mode (≥5% rail, free primary sources only, compact rejections). C is `HYBRID ACTIVATE (FOMC-only)`, so only its carve-out class is evaluated.

- **Indices (IBKR closes 11-17 → 11-18).** SPY 732.44 → 730.20 (−0.31%). SPX 7,322.28 (−0.25%; delayed index bar). QQQ +0.39%, IWM +0.40%, SMH −0.12%. Dow −1.11% to 50,198 (Yahoo/WSJ). The Nasdaq closed up on a cybersecurity surge while Nvidia fell for a fifth day after its beat.
- **Volatility.** VIX 25.46 → **24.56** (IBKR CBOE bar, delayed), back under the 25 NORMAL/HIGH line one session after crossing it. D2a classifies it; D2 item 4 owns any measured refresh trigger.
- **Rates and dollar.** The 10-year was about 5.07% (−4 to −5bp) and the 2-year about 4.80%. DXY about 103.6, near a 19-month high; EURUSD hit 1.0965. FOMC minutes (Oct 27–28) said almost all participants saw further hikes as likely appropriate. Waller called for 50bp in December (or 25bp plus a signalled 25bp in January). A December hike is about 95% priced.
- **Oil.** Brent (BZUSD, provisional same-evening read) **91.41 on 2026-11-18**, against 93.14 on 2026-11-17 in the same FMP series (−1.73). The 11-17 figure was restated from the stored 93.46. WTI was about −3.3% on a crude inventory build.
- **Metals and crypto.** Gold about −3.5% to roughly $3,728, below $3,800 for the first time since September 2025. LME copper broke below $13,000. Bitcoin about $62.3K (−3.7%).
- **Breadth.** **56.06** for 11-18 (Barchart `$S5TH`, stamped 16:57 ET, "unch"), an exact repeat of 11-17. ChartRow still shows 11-17. See EQUITY-BREADTH OBSERVATION.

## TL;DR

- **Exits triggered: none.** No tranche reaches a convergence target or time exit, kill flags are all FALSE, and no in-window development meets an invalidation criterion. ROK's Investor Day reaffirmed FY27 and set a higher long-term margin target. ANDE fell 8.67% with no identified cause.
- **New entry candidates: none routed as thesis handoffs.** B is now DO-NOT-ACTIVATE, so the screen ran router-gated. 4 names passed and go to the B new-entry index (W2 ranks): TJX, ACIW, MOD, BLSH. UNH's second leg is carried forward from yesterday's pass. 144 other ≥5% movers were rejected, mostly cybersecurity, metals, refining and managed-care moves.
- **Add candidates: none (0 of 26).** B and D both read DO-NOT-ACTIVATE.
- **Watchlist: 4 changes.** ADD TJX, ACIW, MOD and BLSH to the Strategy B new-entry index.
- **Regime review: one new PENDING flag.** The ADNOC Logistics vessel strike in Hormuz and Iran's first attack on Kuwait since September (11-17 evening to 11-18) are dated channel events while `shock_overlay` reads latent. S1 (11-18) closed with Brent down 1.73, so the window is incomplete. Yesterday's flag window has closed below the criterion. No resolution event.

Park: VOO-only pin verified

Paper book (J): 120 calls, 377/30 realized, net_mu -0.73%, ready=FALSE

## DEVELOPMENTS

### 1. Market-wide breaking events

**Nvidia after its print, and the Anthropic IPO.**
- Nvidia reported after the 11-17 close: revenue $115.8B vs about $109.1B, Q4 guide $130B ±3% (Reuters). It traded up 3–5% after hours, then closed −2.90% on IBKR bars (155.46 → 150.96), its fifth straight decline. The board said it will not reinstate Jensen Huang (Reuters 11-18). Piper Sandler cut its target to $230 from $300.
- Anthropic priced its IPO at $83, above the $70–78 range, with the offering reportedly upsized (CNBC and Bloomberg, citing a person familiar; no issuer pricing release seen). It is due to trade on Nasdaq as "ANT" on Thu 11-19.

**Fed.** The October minutes were hawkish: almost all participants said further hikes would likely be appropriate, and AI was discussed as a driver of both inflation and financial-stability risk (federalreserve.gov release 11-18 14:00 ET; content via CNBC). Waller argued for 50bp in December. Daly said more hikes may be needed.

**Cybersecurity surge.** PANW +9.90%, TENB +15.8%, OKTA +12.1%, QLYS +12.9%, CRWD +7.9%, ZS +6.8% (Nasdaq closing prints). Catalysts were intraday: DHS Secretary testimony to the House Homeland Security Committee on rising AI-powered attacks on US infrastructure, a CISA Java-vulnerability warning (secondary sources), and software dip-buying. PANW reported after the close (8-K 21:37Z): adjusted EPS $1.05 vs $0.97, revenue $3.44B vs $3.31B, with an acquisition of Applied Compute (secondary, not checked against the release). Its reaction session is 11-19.

**Managed care, second leg.** HUM −12.98% and UNH −10.21% on IBKR bars, ELV −7.6%, CNC −7.1%, MOH −6.6%, CVS −5.2%. No new filing; this continues the CMS RADV-extrapolation ("CRUSH") proposed rule, which goes into the Federal Register on 11-19 (comments due 2027-01-19), plus break-up rhetoric.

**Metals and energy.** Gold, silver and copper miners fell 5–12% on the hawkish Fed and a strong dollar (NEM −6.1%, FCX −7.0%, SCCO −5.9%, AEM −6.4%). Refiners fell with crude and a crack spread down about a third in six weeks: CVI −11.18% on IBKR, VLO −5.5%, MPC −5.2%, PBF −7.1%.

**Iran / Hormuz / Gulf (channel: US blockade of Iranian ports plus Iran's restriction of Hormuz).** No ceasefire, settlement or blockade lift is in force.
- Late 11-17: an ADNOC Logistics & Services vessel was struck in the Strait of Hormuz, with 1 crew missing and 11 injured. UKMTO reported a tanker hit by a projectile about 13nm north of Khasab (fire extinguished).
- 11-17 evening: the US struck an IRGC missile site on Qeshm after drone attacks on the US radar at Bahrain's Isa Air Base (CENTCOM: intercepted).
- Overnight: Iran said it targeted US sites at Kuwait's Ali Al Salem base, its first attack on Kuwait since September; Kuwait intercepted the drones (Reuters). Bahrain intercepted a third attack in a week.
- The Saudi-led coalition intercepted two Houthi cruise missiles aimed at Riyadh and struck 60 Houthi targets.
- Talks only: Qatar–Iran mediation on 11-17, no agreement.

No large bankruptcy or disaster was found.

### 2. Scheduled events that resolved in the window

Enumerated from the key-less Nasdaq earnings calendar for 2026-11-18 (62 rows, 18 at ≥$2B) and the 11-17 after-hours rows. Release times are from EDGAR.

- **TJX (TJX)**, Q3 FY27, pre-open (8-K Item 2.02 accepted 09:19 ET). Comps +4% vs a 2–3% plan; FY comps guide raised to 4% and adjusted EPS guide $5.17–5.20 (per Reuters coverage of the release). IBKR +8.05%.
- **Target (TGT)**, Q3, pre-open. Comps +5.6%; adjusted EPS $2.65 including $0.50 of tariff refunds (CNBC). Nasdaq close +3.99%.
- **Lowe's (LOW)**, Q3, pre-open. Adjusted EPS $3.10 including $0.34 of tariff refunds; comps +1.8%; margin guide trimmed (secondary). Nasdaq close +1.02%.
- **Bullish (BLSH)**, Q3, pre-open (6-K 06:45 ET). IBKR +5.66% while bitcoin fell.
- **Global-E (GLBE), Golar LNG (GLNG), ZIM (ZIM)**, pre-open: reported; moves −4.5%, −3.4%, +0.7% (no outcome figures gathered under router-gated sourcing).
- **SQM (SQM)**, nine months to September: revenue $6.34B and net income $1.57B ($5.49/share) per its 6-K (accepted 11-18 12:09 ET; the calendar listed it for 11-17). −5.52%.
- **Nvidia (NVDA)**, Disney (DIS), Viking (VIK) and the other 11-17 reporters: see section 1 and yesterday's scan. DIS +4.63% and VIK +6.45% today.
- **After the 11-18 close (reaction session 11-19):** Palo Alto Networks (see section 1), Everpure (P), Woodward (WWD), UGI, StoneX, NJR, Copa, JOYY, Helmerich & Payne, Kulicke & Soffa, Star Bulk. Outcomes are not recorded here beyond PANW's.
- **FDA.** The FDA novel-approvals page lists Lembaz (adrabetadex, Niemann-Pick type C) and Nelkarmi (neladalkib, ALK+ NSCLC) dated 11-17. Sponsors are not stated on that page, so they are recorded as unresolved. Nothing is dated 11-18. The oncology-notifications page came back stale.

### 3. Large single-name moves — AI-significance screen, ROUTER-GATED mode (B DO-NOT-ACTIVATE)

**Discovery ran in full.** The key-less Nasdaq screener listed 2,085 symbols at ≥$2B. Each was measured on its 11-18 closing print (Nasdaq `quote/info`, "Closed at Nov 18, 2026 4:00 PM ET"): 2,081 measured, 693 moved ≥2%, 149 moved ≥5%. Four symbols had no dated print (CCZ, GJS, NE.WS, WLYB). Events were identified from free primary sources only: an EDGAR submissions batch over all 146 common-equity ≥5% names (19 re-fetched after an SEC rate threshold, none missing), primary filing text for 9 names, and the earnings calendar. Passed and notable names were measured on IBKR regular-session daily bars.

**Passed (4), each to the Strategy B new-entry index:**

- TJX — Q3 FY27 earnings, pre-open 8-K Item 2.02 accepted 2026-11-18 09:19 ET; reaction session 2026-11-18, +8.05% (129.85 -> 140.30), with 1 prior >=5% session in the window; qualifying_event_date 2026-11-18.
- ACIW — CEO Thomas Warsop resigned effective 11-18, CFO named interim CEO; pre-open 8-K Item 5.02 accepted 2026-11-18 09:00 ET; reaction session 2026-11-18, -10.25% (58.93 -> 52.89); qualifying_event_date 2026-11-18.
- MOD — Investor Day slides and a new $500M buyback; pre-open 8-K Items 7.01/8.01 accepted 2026-11-18 09:00 ET; reaction session 2026-11-18, +6.28% (129.73 -> 137.88), with 5 prior >=5% sessions in the window (distinct from the 11-12 Samsung talks report passed on 11-15); qualifying_event_date 2026-11-18.
- BLSH — Q3 2026 results, pre-open 6-K accepted 2026-11-18 06:45 ET; rose against falling crypto peers; reaction session 2026-11-18, +5.66% (19.27 -> 20.36), with 4 prior >=5% sessions in the window; qualifying_event_date 2026-11-18.

**Chain-carried (1):** UNH −10.21% (389.68 → 349.91). Its prior close equals the event close of yesterday's passed UNH item (46f9523a), and there is no new UNH filing, so yesterday's disposition (passed, anchor 11-17) carries forward. Note: the CRUSH rule went on public inspection 11-16 at 16:15 ET (secondary source), which would put that anchor on 11-16; it is not superseded on unverified timing.

**Rejected (144), all in the `research-screen` row's compact form:**
- 20 cybersecurity rally (PANW, TENB, QLYS, OKTA, CRWD, ZS, NET, FTNT and 12 more); 29 metals miners; 11 refining/energy (CVI −11.18% IBKR-confirmed); 9 managed care (HUM −12.98% IBKR-confirmed); 9 retail read-through; 5 crypto.
- 4 offerings (ARDT, AAOI ATM, ASTS, SLS); 6 ADRs below $10B; 3 preferred/warrants; 2 held names (IRTC, SM).
- SQM (anchor unresolved); VIK (follow-through of its 11-17 print).
- 44 with no identified event in free sources, among them PLBL +16.8%, GNRC +9.8%, CBRS −9.6%, RBLX +7.5%, AMD +5.3%, SAP −5.3%.
- No deal-pinned target.

### 4. Sector-level moves (IBKR regular-session closes 11-17 → 11-18)

Four sectors cleared the 1% rail; two reached the old 2% bar.
- **XLE −3.27% (passed, 60):** crude fell (Brent (BZUSD, provisional same-evening read) 91.41 on 2026-11-18 vs 93.14 on 2026-11-17) and refiners led down on collapsing cracks.
- **XLV −2.20% (passed, 60):** the managed-care second leg on the CMS CRUSH rule.
- **XLY +1.79% (passed, 45):** retail earnings (TJX, Target, read-through to BURL, LULU, M) and AMZN +3.82%.
- **XLK +0.34% (passed as dispersion, 45):** the cybersecurity surge against Nvidia −2.9% and SAP −5.3%.
- Rejected as risk-off beta (30): XLF −1.14% (crypto names and the hawkish Fed).
- Not on the rail: XLB −0.75%, XLP −0.31%, XLI −0.05%, XLRE +0.07%, XLU +0.30%, XLC +0.30%.

### 5. Notable commentary

- **Fed.** Waller wants 50bp in December; Daly sees more hikes; the minutes leaned hawkish. BofA strategists did not rule out 50bp (secondary).
- **ECB.** Lagarde (DealBook) called Europe's economy resilient "contrary to our projections"; no policy signal. Vujcic said another hike next year "does not seem unreasonable".
- **Sell-side (secondary, trendonify.com).** Piper Sandler cut NVDA to $230; BTIG cut CRM to $250; Bernstein cut SMMT to Underperform; Stifel downgraded PODD and upgraded TNDM. Goldman raised its 2027 AI project-financing estimate to $545B (secondary).

## ANALYSIS — RISK TO EXISTING POSITIONS

**Mechanical sweep (union of `state.current_positions` and IBKR `get_account_positions`).** 26 strategy tranches plus the VOO park. Every connector position is in `state.current_positions`, so there is no reconciliation lag. Closes are IBKR 11-18 regular-session bars.

| Tranche | Close | Convergence target | Time exit | Triggered? |
|---|---|---|---|---|
| B:ANDE | 47.51 | 61.50 | 2027-01-15 | No |
| B:ARQT | 27.61 | 32.00 | 2027-01-15 | No |
| B:DDOG | 167.11 | 202.00 | 2027-01-15 | No |
| B:ECG | 85.56 | 103.00 | 2027-01-15 | No |
| B:EXPE | 245.79 | 290.00 | 2027-01-15 | No |
| B:IRTC | 94.87 | 111.00 | 2027-01-15 | No |
| B:MCY | 83.75 | 96.00 | 2027-01-15 | No |
| B:MTRN | 201.00 | 225.00 | 2027-01-15 | No |
| B:NRIX | 14.10 | 19.50 | 2027-01-15 | No |
| B:RELY | 20.61 | 24.50 | 2027-01-15 | No |
| B:ROK | 395.86 | 430.00 | 2027-01-15 | No |
| B:RVMD | 159.82 | 188.00 | 2027-01-15 | No |
| B:SM | 28.82 | 35.50 | 2027-01-15 | No |
| B:SYY | 77.92 | 81.00 | 2027-01-15 | No |
| D (12 tranches: AMZN ×2, DIS ×2, GEV, GOOGL ×2, ISRG, RTX, TSM ×2, UBER) | — | none | none | No |

**Kill-trigger sweep (`perf.kill_flags`, as of 11-17, refreshed against 11-18 closes).**
- B: drawdown −6.77% at the 11-17 engine row. Today's B book moved about −0.2% (ANDE −8.7% and SM −5.3% against IRTC +5.8% and MTRN +2.3%), so roughly −7%. Far from the 50% kill. No runaway, evidence kill or interim warning.
- D: drawdown −9.63% at 11-17; roughly −8.5% after 11-18 (AMZN +3.8%, DIS +4.6%). No flags.
- `analytics.b_pairwise_correlation`: 14 positions, average correlation NULL (no pair has ≥40 overlap days yet), so no warning.
- Price-level criteria (`state.price_level_criterion_drift`): MCY 83.75 vs its 81.78 level and ECG 85.56 vs 70.44, both unbreached; no dividend drift on either.

**Judgment invalidation sweep.** No development meets a criterion.
- **ROK +1.18%:** criterion 1 was tested at the 11-18 Investor Day. FY27 guidance was reaffirmed, the long-term enterprise margin target rose to about 25% (above the legacy 23.5%), and segment targets rose (Intelligent Devices 22–25%, Software & Control 35–37%, Lifecycle Services 16–18%) (Quartr summary of the event; Newsquawk). No ARR target was withdrawn. Not met; reinforcing. An S-3ASR shelf was filed after the close with no offering named.
- **ANDE −8.67% (52.02 → 47.51):** no 8-K, deal change, financing change, equity issuance, 45Z/45Q action or RFS relief was found (EDGAR, held-name news search). Criteria 1–4 are not met. The cause is unidentified; the next run should re-check for a filing.
- **SM −5.29%:** energy beta with crude down. No guidance, capex or dividend change, so criteria 1–4 are not met.
- **IRTC +5.80%:** a $100M accelerated buyback announced after the 11-17 close. Reinforcing.
- **DDOG +1.17%:** no AI-customer, peer or guidance development.
- **EXPE +1.08%:** the Gulf attacks extend the standing structure, and Brent fell to 91.41 with no airspace closure or travel advisory reported, so criterion 2 is not met.
- **MCY, MTRN, NRIX, RELY, RVMD, ARQT, ECG, SYY:** no company developments found in the window.
- **D:GOOGL:** Waymo paused US freeway rides after a California suspension (Reuters via MarketBeat). That is not a cloud or remedy criterion.
- **D:DIS +4.63%, D:AMZN +3.82%:** reinforcing tape. No D criterion is touched.

**Watchlist candidates.** No in-window development invalidates or advances a queued name beyond the screen items above.

## ANALYSIS — OPPORTUNITY CHECK

Reactive-cadence set: C (carve-out only). A, B, D and E are gated and not evaluated, except that B's ≥5% screen passes still reach the new-entry index as `watchlist` actions (below).
- **B:** 4 router-gated screen passes go to the new-entry index. W2 ranks them; D1 makes no thesis handoff.
- **C (FOMC-only carve-out):** the minutes and Waller's 50bp call sharpen the 12-09 meeting, but that catalyst is already known. No new FOMC-class catalyst.

## ANALYSIS — ADD-CANDIDATE CHECK

26 tranches evaluated (14 B, 12 D, no A): 0 flagged, 26 declined, 0 at the hard gate. All are `invalidation_criteria_evaluable = TRUE`.
- **B tranches:** B turned DO-NOT-ACTIVATE on 11-17, so no add is proposed. Largest losses vs cost: ANDE −14.27%, SM −11.09%, DDOG −8.50%, NRIX −8.26%, RELY −7.90%.
- **D tranches:** criteria unbreached, but D reads DO-NOT-ACTIVATE (div-D-202611-1).

Recorded in `events.decision_log` `add-candidate-review` 0b121f3e-2780-4ddf-b829-fbf652576e46.

## ANALYSIS — REGIME CHECK

**One new PENDING geopolitical flag, no resolution flag.**
- `shock_overlay` reads latent; the Gulf/Hormuz structure is open.
- New dated events on the named channel, late 11-17 to 11-18: the ADNOC Logistics & Services vessel struck in Hormuz (1 missing, 11 injured); a tanker hit north of Khasab; Iran's claimed attack on US sites at Kuwait's Ali Al Salem base, the first on Kuwait since September; a third Bahrain interception in a week; US strikes on Qeshm.
- Two-session window: P 93.14 (BZUSD 2026-11-17, same FMP series), S1 91.41 on 2026-11-18 (−1.73, not met), S2 2026-11-19 open. Flagged PENDING for D2 and M1R.
- Yesterday's flag (11-16 evening / 11-17 attacks) now has a closed window: P 91.76 (stored 11-16), S1 93.46 stored (restated 93.14), S2 91.41 provisional, so about −0.35 at S2. That does not meet an upward oil criterion; M1R rules.
- No qualifying resolution event: the Qatar–Iran talks produced no agreement, and the blockade and Hormuz restrictions continue.

**Measured triggers (for D2 item 4, not computed here):** VIX closed 24.56, back below the 25 line after one HIGH session; breadth read unchanged at 56.06.

## EQUITY-BREADTH OBSERVATION

- **Value written:** **56.06** for 2026-11-18 (`events.regime_events` `TECHNICAL_INPUT` / `EQUITY_BREADTH_PCT`).
- **Source:** Barchart `$S5TH` via Parallel `web_fetch`: "56.06 unch (unch) 16:57 ET", "Quote Overview for Wed, Nov 18th, 2026", Previous Close 56.06, Open 55.26, range 55.26–57.45. It is settled (on-page time ≥16:00 ET), and the bar is not a vendor carry (O/H/L differ from the prior close). This is a single usable source.
- **Exact repeat:** `exact_repeat_of_prior=2026-11-17`. ChartRow's 200-day card still reads 278 of 497 as of Nov 17 (`chartrow_unconfirmed=lag session 2026-11-17`). A late re-read (last breadth step) still showed Nov 17, so the repeat is unconfirmed; filed as in-run issue `breadth_exact_repeat_unconfirmed` with the evidence that would settle it.
- **Lagged check of the prior row:** ChartRow 11-16 → 11-17 −3.82pp vs stored −3.78pp, so `chartrow_lagged_dod_gap=0.04`. Consistent.
- No MacroMicro re-probe (Wednesday).

## ANALYSIS — FRONTIER-LLM CAPABILITY CHECK

NO CAPTURE. The paper search ran the anchoring/sycophancy battery (Thursday's topic, used a day early) and returned only older or catalogued papers. The date-ordered `hf://papers/daily/latest` listing for 11-18 was read with Wednesday's calibration topic in mind. Its in-window items (11-17/18) include agent self-improvement work (2611.23219, 2611.18856) and a measurement of the run-to-run noise floor in decision models (2611.15671). None materially changes a documented `AI_Trading_Foundation.md` disadvantage, so the default is silent.

## RECOMMENDED ACTIONS

- Watchlist: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, router-gated screen; W2 ranks, no thesis handoff from D1): TJX — Q3 FY27 earnings, pre-open 8-K Item 2.02 accepted 2026-11-18 09:19 ET; reaction session 2026-11-18, +8.05% (129.85 -> 140.30), with 1 prior >=5% session in the window; qualifying_event_date 2026-11-18.
- Watchlist: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, router-gated screen; W2 ranks, no thesis handoff from D1): ACIW — CEO resignation effective 11-18 with the CFO as interim CEO; pre-open 8-K Item 5.02 accepted 2026-11-18 09:00 ET; reaction session 2026-11-18, -10.25% (58.93 -> 52.89); qualifying_event_date 2026-11-18.
- Watchlist: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, router-gated screen; W2 ranks, no thesis handoff from D1): MOD — Investor Day and a new $500M buyback; pre-open 8-K Items 7.01/8.01 accepted 2026-11-18 09:00 ET; reaction session 2026-11-18, +6.28% (129.73 -> 137.88), with 5 prior >=5% sessions in the window; qualifying_event_date 2026-11-18.
- Watchlist: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, router-gated screen; W2 ranks, no thesis handoff from D1): BLSH — Q3 2026 results, pre-open 6-K accepted 2026-11-18 06:45 ET; reaction session 2026-11-18, +5.66% (19.27 -> 20.36), with 4 prior >=5% sessions in the window; qualifying_event_date 2026-11-18.
- Router review (refresh-only): late 2026-11-17 / 2026-11-18 Gulf-channel attacks (ADNOC Logistics & Services vessel struck in Hormuz with 1 missing and 11 injured; tanker hit north of Khasab; Iran-claimed attack on US sites at Kuwait's Ali Al Salem base, the first on Kuwait since September; third Bahrain interception; US strikes on Qeshm) while shock_overlay reads latent; they may meet the Qualifying shock event criterion. Two-session window PENDING: P 93.14 (BZUSD 2026-11-17), S1 91.41 on 2026-11-18 (-1.73, not met), S2 2026-11-19 open. The 11-16/11-17 flag window has closed at P 91.76 / S1 93.46 (restated 93.14) / S2 91.41 (about -0.35, not met) for M1R to rule.

```yaml d1_actions
- action: watchlist
  ticker: TJX
  strategy: B
  qualifying_event_date: 2026-11-18
  source_research_screen_id: 5e7515bb-8d49-4b10-a7eb-8676466cc4c5
  detail: "ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, router-gated screen; W2 ranks, no thesis handoff from D1): TJX — Q3 FY27 earnings, pre-open 8-K Item 2.02 accepted 2026-11-18 09:19 ET; reaction session 2026-11-18, +8.05% (129.85 -> 140.30), with 1 prior >=5% session in the window; qualifying_event_date 2026-11-18."
- action: watchlist
  ticker: ACIW
  strategy: B
  qualifying_event_date: 2026-11-18
  source_research_screen_id: 5e7515bb-8d49-4b10-a7eb-8676466cc4c5
  detail: "ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, router-gated screen; W2 ranks, no thesis handoff from D1): ACIW — CEO resignation effective 11-18 with the CFO as interim CEO; pre-open 8-K Item 5.02 accepted 2026-11-18 09:00 ET; reaction session 2026-11-18, -10.25% (58.93 -> 52.89); qualifying_event_date 2026-11-18."
- action: watchlist
  ticker: MOD
  strategy: B
  qualifying_event_date: 2026-11-18
  source_research_screen_id: 5e7515bb-8d49-4b10-a7eb-8676466cc4c5
  detail: "ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, router-gated screen; W2 ranks, no thesis handoff from D1): MOD — Investor Day and a new $500M buyback; pre-open 8-K Items 7.01/8.01 accepted 2026-11-18 09:00 ET; reaction session 2026-11-18, +6.28% (129.73 -> 137.88), with 5 prior >=5% sessions in the window; qualifying_event_date 2026-11-18."
- action: watchlist
  ticker: BLSH
  strategy: B
  qualifying_event_date: 2026-11-18
  source_research_screen_id: 5e7515bb-8d49-4b10-a7eb-8676466cc4c5
  detail: "ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, router-gated screen; W2 ranks, no thesis handoff from D1): BLSH — Q3 2026 results, pre-open 6-K accepted 2026-11-18 06:45 ET; reaction session 2026-11-18, +5.66% (19.27 -> 20.36), with 4 prior >=5% sessions in the window; qualifying_event_date 2026-11-18."
- action: router_review
  ticker: n/a
  strategy: n/a
  qualifying_event_date: n/a
  source_research_screen_id: n/a
  detail: "Refresh-only: late 2026-11-17 / 2026-11-18 Gulf-channel attacks (ADNOC Logistics & Services vessel struck in Hormuz with 1 missing and 11 injured; tanker hit north of Khasab; Iran-claimed attack on US sites at Kuwait's Ali Al Salem base, the first on Kuwait since September; third Bahrain interception; US strikes on Qeshm) while shock_overlay reads latent; they may meet the Qualifying shock event criterion. Two-session window PENDING: P 93.14 (BZUSD 2026-11-17), S1 91.41 on 2026-11-18 (-1.73, not met), S2 2026-11-19 open. The 11-16/11-17 flag window has closed at P 91.76 / S1 93.46 (restated 93.14) / S2 91.41 (about -0.35, not met) for M1R to rule."
```

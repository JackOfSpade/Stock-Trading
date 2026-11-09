2026-11-09
<!-- d1_scan_through_utc: 2026-11-09T22:41:02Z -->

# Daily Market Development Scan — session 2026-11-09 (Mon), run 2026-11-09 (Mon)

Scan window: 2026-11-08 22:49 MT → 2026-11-09 15:41 MT (~17 hours). The start is the prior `Daily.md` marker `2026-11-09T05:49:33Z`. The window holds one completed US session, Monday 2026-11-09.

SCAN MODE: ROUTER-GATED (A DO-NOT-ACTIVATE; B DO-NOT-ACTIVATE — PENDING div-B-202611-2; D DO-NOT-ACTIVATE; E DO-NOT-ACTIVATE), read live from `state.current_regime`. C is `HYBRID ACTIVATE (FOMC-only)`, so only its carve-out class is evaluated.

- **Indices (IBKR closes 11-06 → 11-09).** SPY **+2.37%** (735.29 → 752.69), QQQ +3.54%, SMH +5.05%, RSP +2.27%, SPX 7,376.86 → 7,549.01. A broad relief rally: every sector ETF rose, and Reuters called it the S&P's best day since April 8.
- **Volatility.** VIX 25.64 → **19.92** (−22.3%; IBKR index bar, 15-minute delayed). It is now below the HIGH threshold of 25; D2a's `TECHNICAL_SIGNAL` still reads HIGH as of 11-06.
- **Rates and dollar.** Morning yields: 2-year 4.53%, 10-year 4.86%, 30-year 5.26% (CNBC). DXY about 101.8 (−0.46%). Hike odds for the December 8–9 FOMC are about 79% (CME FedWatch).
- **Oil.** Brent (BZUSD, provisional same-evening read) **92.32 on 2026-11-09**, against 98.32 on 2026-11-06 in the same FMP series (**−6.10%**). The move was on de-escalation talk; no resolution took effect.
- **Breadth.** Up to **63.14** from 55.97 (Barchart `$S5TH`, single settled source; ChartRow still lagged at Nov 6).

## TL;DR

- **Exits triggered: none.** No tranche carries a mechanical trigger, and no development meets an invalidation criterion.
- **New entry candidates: none routed.** 22 names cleared Strategy B's frozen ≥5% floor on their own stamped events, all confirmed on IBKR bars. B is gated, so they go to the new-entry index only; no thesis handoff. No new FOMC-class C candidate.
- **Add candidates: none (0 of 12).** All 12 D tranches clear the hard gate. Five dip reads (GEV, GOOGL ×2, TSM ×2) are declined because D is DO-NOT-ACTIVATE.
- **Watchlist: 22 changes.** ADD the 22 names to the Strategy B new-entry index.
- **Regime review: no review.** There was no qualifying escalation and no qualifying resolution in the window. The unconfirmed Qatari "interim deal" report moved oil but is not a resolution in force.

Park: VOO-only pin verified

Paper book (J): 118 calls, 361/30 realized, net_mu -0.85%, ready=FALSE

## DEVELOPMENTS

### 1. Market-wide breaking events

#### Iran / Hormuz / Gulf (channel: US blockade of Iranian ports plus Iran's closure of Hormuz)
- **Trump met Qatar's prime minister** (also foreign minister) Sheikh Mohammed bin Abdulrahman Al Thani in a closed Oval Office session on Monday; VP Vance met him separately. There was no readout, no announced agreement and no strike order. Trump was reported as saying "now we will make a decision" (HNGN; House of Saud, 11-09 15:47Z). The official readout is UNRESOLVED.
- **Reported, NOT confirmed: an interim deal.** Israel Hayom, citing two unnamed diplomats, said Iran signed off on a Qatari interim framework:
  - Iran reopens Hormuz, halts tanker attacks and drops its toll/control demand.
  - The US lifts the blockade and releases $8B of frozen funds held in Qatar.
  - The nuclear program is off the table.
  - Neither government confirmed it (OilPrice 13:00Z; Invezz 15:00Z), and a Qatari official told Bloomberg the report was false and negotiations were ongoing (Capital Brief, 14:04Z).
  - Rubio and Bessent reportedly object (BeInCrypto, 12:58Z).
- **Positions.** Rubio (Sunday evening, CNBC/CBS/AP): not "at the verge of a breakthrough"; Iran's demands are "outrageous and ridiculous". Iran's foreign-ministry spokesman Baghaei (11-09): sanctions lifted and the war ended on all fronts before talks (CNBC, 11:09Z). Araghchi: Iran is awaiting a US reply. Trump (Sunday, CNN/60 Minutes): renewed strikes "highly unlikely" if talks progress.
- **Kinetic.** NBC (11:22Z) cites Iranian state media reporting US strikes on Qeshm Island "overnight"; the timing relative to the window start is UNRESOLVED. Iran has attacked tankers "this month". **No new 11-09 attack on supply infrastructure was found.** Hormuz remains functionally closed (Gulf News via House of Saud: 1 transit on 11-01 against a ~85/day baseline).
- **Oil reaction:**
  - Brent (BZUSD, provisional same-evening read) closed **92.32 on 11-09**, against 98.32 on 11-06 (−6.10%).
  - Intraday wires had Brent futures 93.4–94.0 (−4 to −5%) by 14:00Z, and WTI 88.09 (OilPrice, 11:26Z). Drivers: Trump's de-escalation remarks and the disputed Israel Hayom report. JPMorgan flagged a widening global surplus; UBS said the physical market is weak.
  - EIA STEO comes Tue 11-10, OPEC MOMR Wed, IEA Fri.

#### US policy after the election
- **Tariffs.** No new tariff action and no unwind in the window. Democrats take both chambers in January; Wyden is likely Finance chair and is pushing a Congressional Trade Authority Reform Act. A filibuster or veto makes reversal unlikely, and Section 232/301 tariffs stay executive (Seoul Economic Daily 08:58Z; Business Sweden 17:00Z). UBS: Democratic control may raise the odds of lower building-material tariffs. Trump flagged a robot/industrial-machinery import review with six months of trade talks and no immediate tariffs.
- **Data centers.** No new state moratorium in the window. Stifel says state-level permitting is back in focus, with friction mainly for 2028 projects (TipRanks, 11:24Z).
- **SoftBank / Stargate credit.** Musk's 11-06 claim that SoftBank is "defaulting on turbine orders" is still **unconfirmed** by SoftBank or GE Vernova. SoftBank's 5-year CDS is 466 bp, the widest since Oct 2022; SoftBank reports Tue 11-10. Its ABB robotics deal is reported "blocked", though ABB says it is working constructively (TNW/Reuters, 12:03Z). OpenAI closed about $11B of a first tranche at a $1.25T valuation (LA Times, 17:38Z). CoreWeave reports Tue; neoclouds are down about 50% in a month (CNBC). The Goldman CEO says AI financing demand is still strong (CNBC, 18:14Z).
- A debt-ceiling risk was flagged after the midterms (CNBC video, 11-09).

#### Other unscheduled corporate events
- **Nvidia.** Its board opened an independent probe (announced Sunday 11-08) into whether CEO Jensen Huang was the target of a Chinese intelligence effort (NYT). NVDA fell about 6% (about −9% at the intraday low per BI), its lowest since 3-31. Trump said Huang should stay (CNBC). Nvidia reports 11-17.
- **Anthropic** can begin marketing its IPO as early as Tue 11-10 (Bloomberg, 14:20Z). It is also buying about $3.4B of gas generators (FT via TechCrunch).
- No bankruptcies, disasters or SEC enforcement actions were found in the window.

### 2. Scheduled events that resolved in the window

- **Earnings enumeration.** The key-less Nasdaq earnings calendar lists 65 names of $2B or more for 11-09: CEG, KKR, B, IX, ROIV, NRG, KSPI and RBA pre-market; OXY, TTWO, RKLB, BAP and CIB after hours. It also lists BRK.A/BRK.B for 11-07 and RDNT for 11-08. The calendar is a schedule only; printed results come from each issuer's EDGAR 8-K (EVENT-IDENTITY GATE).
- **Confirmed prints with a ≥5% IBKR reaction** (issuer 8-K accepted in the window; all are in item 3): IONS −21.36%, PRAX +19.94%, QXO +19.20%, IMVT +15.13%, VIA +12.80%, FERG +11.22%, CNH +10.90%, CEG +10.46%, NRG +10.32%, MNDY −9.10%, KGS +7.20%, WTTR −6.86%, GCMG +6.24%, TGTX +5.93%, TNGX +5.77%, AMG +5.56%. FRVO +26.02% and IBRX −17.66% also printed pre-open. ROIV printed (+4.60%, below the floor).
- **Other confirmed releases:** CEG beat on Q3 (+10%). KKR posted a record profit. Berkshire's Q3 profit was lower (11-07, wires). After-close prints (OXY, TTWO, RKLB and others) fall after this session; their EDGAR filings are coded POST_MOVE_EVENT.
- **Clinical:** VIR Phase 3 ECLIPSE 1 topline (hepatitis delta, +11.71%). VRDN VRDN-008 phase 1 data (+5.97%). IBRX's QUILT-2.005 met its primary endpoint, but the stock fell 17.66%. **No FDA PDUFA outcome** was found in the window (none resolved against the FDA's own page).
- **Macro data:** NY Fed October Survey of Consumer Expectations: inflation expectations unchanged but elevated, and expectations of higher unemployment the highest since April 2020 (Reuters/Kitco, 18:56Z). September wholesale inventories (minor).
- **No FOMC action** in the window. The next FOMC is **December 8–9**; the decision is 12/9 at 2:00 pm ET with an SEP (federalreserve.gov calendar).
- **Next:**
  - Tue 11-10: October CPI 08:30 ET (consensus +0.3% m/m, about 3.8–3.9% y/y). Bloomberg (19:05Z) says BLS will not publish the 12-month October figures; the reason is UNRESOLVED.
  - Tue 11-10 also brings TSM's October sales, SoftBank and CoreWeave earnings, and the Anthropic IPO launch.
  - 11-12: CSCO and AMAT after hours.
  - Fri 11-13: PPI.
  - **DIS FQ4 FY26 on 11-17 before the open** (company announcement); NVDA on 11-17.

### 3. Large single-name moves — AI-significance screen, ROUTER-GATED MODE

- **Population.** US-listed common stocks, market cap ≥$2B, |close-to-close| ≥5% on 11-09 against 11-06 (B's frozen floor; no sub-floor write-ups in this mode).
- **Discovery.** The Nasdaq screener supplied symbols and caps only. Moves came from per-symbol Nasdaq `quote/info` regular-session closes ("Closed at Nov 9, 2026 4:00 PM ET"): **1,990** names measured, **439** at ≥5% (`rail_tally`). The median discovery move was **+2.27%**, a broad up-tape, so most ≥5% moves are beta. 10 symbols had no derivable prior close, and AMX was dropped in error (both named in `degraded_legs`).
- **Confirmation and identity.** Release times come only from one scripted EDGAR batch (about 607 requests, no failures; `acceptanceDateTime` verified as UTC), and labels from the key-less earnings calendar. **26** names had an own-event filing in the reaction window and were measured on IBKR regular-session daily bars (`close` array, `outside_rth=false`) in one batch.
  - **22 passed.**
  - 2 fell below 5% on IBKR and are dropped: CRL +4.69% and ROIV +4.60%.
  - 2 are rejected notable: SGRY (deal-pinned) and AUGO.
  - No metered call was made for this screen.
- **Passed:** FRVO +26.02%, IONS −21.36%, PRAX +19.94%, QXO +19.20%, IBRX −17.66%, IMVT +15.13%, ASTS +14.10%, VIA +12.80%, VIR +11.71%, AGLT −11.31%, FERG +11.22%, CNH +10.90%, CEG +10.46%, NRG +10.32%, MNDY −9.10%, KGS +7.20%, WTTR −6.86%, GCMG +6.24%, VRDN +5.97%, TGTX +5.93%, TNGX +5.77%, AMG +5.56%.
  - Anchors: 20 are pre-open 11-09 (anchor and reaction session coincide). ASTS and AGLT carry an after-close 11-06 anchor and react on 11-09.
- **Close-chain check.** One query over 15 landed rows (2026-10-19 → 11-08), including compact tuples. Two hits, neither on an intraday or pre-open anchor; this is not a clearance.
  - **ASTS** is a legitimate forward chain: the 11-08 row coded it POST_MOVE_EVENT on the same after-close 11-06 anchor, and its event_close there equals today's prior_close of 32.33.
  - **AUGO** chains to its own 11-05-anchored *passed* item in `d564cda0`. Its only new filing is a 6-K results *presentation* (11-06 after close), so the 11-09 +11.78% is a later-day move on the same results. That disposition is carried forward in `rejected_notable`, with no new watchlist action.
- **Noisy names** (≥3 other ≥5% sessions in the 10-session window; context for criteria 2 and 4): FRVO (6), IBRX (5), AGLT (5), PRAX (4), ASTS (4), KGS (4), QXO (3), WTTR (3).
- **Deal-pinned:** **SGRY.** It is the target of a definitive all-cash merger with Spyglass Topco at **$25.00/share** (Amendment No. 1, 8-K Item 1.01 accepted 11-09 09:15 ET). It closed at 26.45 on IBKR, **$1.45 above the offer**, so the move prices a hoped-for higher bid. Recorded with `reason` beginning `deal-pinned:`, with no watchlist action.
- **Rejected compact** (415, closes on the discovery basis):
  - 188 `ANCHOR_UNRESOLVED`: no own-event filing that explains the move. Examples: AMAT +11.4%, AVGO +8.8%, APH +8.3%, CAT +7.2%, held GEV +7.1%, MU +6.2%, ASML +6.2%, OKLO +14.0%, MPWR +16.6%, FLY +17.1%.
  - 207 `DAY2_EVENT_PRIOR`: second-day moves on events filed 10-30 → 11-06, e.g. COHR, AMD, LRCX, VSAT, WRBY, UI.
  - 20 `POST_MOVE_EVENT`: earnings filed after the 11-09 close, e.g. RKLB, TTD, TXN, ONTO, SANM, HIMS.
- **Durable row:** `research-screen` `single-name-move`, entry **`9f5c6b11-5ff1-4e65-b563-d0290627864d`**. It was written by the orchestrator through the digest-checked split path (3 parts + call, each accepted first try; `outcome=written`). Readback: `surfaced_count` 22 = `ARRAY_LENGTH(passed)`, and `state.research_screen_calls` parses 24 items.

### 4. Sector-level moves (IBKR regular-session closes 11-06 → 11-09)

- **Surfaced (3 of 9 at |move| ≥ 1%; rail tally 9):**
  - **XLI +3.82%** (162.67 → 168.89), conviction 45: cyclicals led the relief rally on the oil slide.
  - **XLK +3.73%** (164.74 → 170.88), conviction 45: a chip-led rebound (SMH +5.05%) despite NVDA's −6%.
  - **XLY +2.92%** (117.58 → 121.01), conviction 30: beta plus a fuel-cost tailwind.
- **Rejected notable:** XLE +0.52% (61.62 → 61.94), conviction 45. A dispersion item: energy lagged every other sector as Brent fell 6.10%.
- **Not surfaced** (tracked the tape): XLC +2.45% (clears the legacy 2% bar: `rule_only`), XLV +1.91%, XLB +1.91%, XLU +1.53%, XLRE +1.45%, XLF +1.45%, XLP +0.90%.
- **Brent** (BZUSD, provisional same-evening read) 92.32 on 2026-11-09 against 98.32 on 2026-11-06 (one FMP call; the curated series had no 11-09 row yet).
- **Id check.** All 11 contract ids verified: each IBKR 11-06 close equals the 11-08 row's event_close. None was re-resolved.
- **Durable row:** `research-screen` `sector-move`, entry **`8327041f-73b7-4cdc-9477-473f2ee3efc0`** (digest-checked, `written`).

### 5. Notable commentary

- **Fed:**
  - Barkin (Richmond): inflation is "stubbornly elevated" and the "direction of policy" is "relatively straightforward", but policy should move "with care" (Reuters/Kitco, 18:56Z).
  - Natixis: a hike is warranted in December (Kitco, 18:25Z).
  - Bowman and Goolsbee were scheduled; content not found.
- **Strategists:**
  - Citi cut US equities to neutral from overweight, citing positioning and AI regulation (Reuters, 13:00Z).
  - Capital Economics: the AI selloff could deepen, and earnings forecasts have not yet been cut (Investing.com).
  - JPMorgan reiterates an 8,000 S&P year-end target and calls the selloff a "de-leveraging event". BlackRock's Rieder calls it an "unwind", not a bubble (Business Insider, 16:44Z).
  - HSBC: look at equities again (MarketWatch).
- **Sell-side:**
  - Oppenheimer upgraded AMD to Outperform with a $600 target.
  - JPMorgan upgraded SAP.
  - Wells Fargo cut its CRWV target to $115 from $160.
  - Jefferies set LLY at $1,700.
- **Corporate:**
  - TSMC is reportedly weighing 3D DRAM at Nvidia's request (Reuters/The Information via Benzinga, 15:14Z).
  - Google launched new TPU variants (8tx, 8i Max) (Bloomberg, 12:30Z).
  - Tesla is ending Cybertruck production in about 8 months (GovTech).

## ANALYSIS — RISK TO EXISTING POSITIONS

- **Union of book and view.** IBKR `get_account_positions` (read about 22:15Z on 11-09) and `state.current_positions` agree on all 8 names and share counts: AMZN 0.3464, DIS 0.7244, GEV 0.1244, GOOGL 0.2577, ISRG 0.1091, RTX 0.1601, TSM 0.155, UBER 0.5156. IBKR also holds the VOO park (16.895 shares), which is not a strategy position. **There is no reconciliation-lag position.**
- **Exit triggers.** No tranche carries a `convergence_target` or `time_exit_date`. **No EXIT TRIGGERED.**
- **Kill-trigger sweep.**
  - **Strategy D.** `perf.kill_flags` (as of 11-06): every flag FALSE (drawdown, runaway, m2m, evidence, interim warning). Unit value 1.0081 against a peak of 1.1065, so drawdown is −8.89% on the 11-06 closes.
    - **Refreshed on today's closes**, every D name rose on 11-09 (AMZN +2.94%, DIS +2.03%, GEV +7.13%, GOOGL +1.18%, ISRG +1.71%, RTX +3.58%, TSM +3.51%, UBER +3.76%), so the drawdown narrows. It is far from the 50% kill.
    - Live snapshots were after-hours prints (`is_close` false), so closes were used.
    - No interim-warning alert is open or due.
  - **Strategy B.** No open positions; `analytics.b_pairwise_correlation` reports 0 positions, so the correlation check is inert.
- **Thesis-invalidation sweep** (IBKR 11-09 closes; criteria from each tranche's `invalidation_status`):
  - **AMZN** 266.93. No AWS growth, margin, backlog or Anthropic/OpenAI commitment datapoint. Anthropic's reported $3.4B generator purchase is not an AWS reading. **NO.**
  - **DIS** 119.12. FQ4 FY26 is confirmed for **11-17 before the open** and has **not occurred** (EVENT-IDENTITY GATE). There is no streaming-margin, guidance, buyback or FCC news. **NO.**
  - **GEV** 829.34 (+7.13%). Musk's SoftBank turbine-default claim is still unconfirmed and is not an orders reading. One report notes customers ordered 57 aeroderivative turbines against 9 a year ago in Q3 (FourWeekMBA, citing the filing). The criterion is organic orders growth below 15% for two quarters. **NO** (watch item).
  - **GOOGL** 288.15. There is no structural-remedy ruling and no Cloud datapoint; the new TPU variants are not a criterion input. **NO.**
  - **ISRG** 460.56. No company development. **NO.**
  - **RTX** 196.31. There is no Airbus ruling, GTF slip, backlog or FCF change, or FY27 procurement cut. **NO.**
  - **TSM** 388.62. No N2/A16 pushout and no AI-capex cut. October monthly revenue is due 11-10, and the reported 3D-DRAM study is not a criterion input. **NO.**
  - **UBER** 71.17. No gross-bookings, margin or Uber One datapoint. **NO.**
- **Dividend netting:** no tranche has a price-level criterion, so it does not apply.
- **Watchlist candidates:** B is gated, and no development changes the new-entry index beyond today's additions.

## ANALYSIS — OPPORTUNITY CHECK

- **A, D and E are GATED** under the ROUTER-GATED SCAN RULE, so nothing was evaluated for them.
- **B (gated):** its ≥5% names reach the new-entry index as `watchlist` actions (item 3). SGRY is excluded as deal-pinned, and AUGO as a later-day move.
- **C, HYBRID (FOMC-only carve-out).** No new FOMC-class candidate. The December 8–9 FOMC is already inside the 45-day window, and no new FOMC-class catalyst was announced.

## ANALYSIS — ADD-CANDIDATE CHECK

- **Durable row:** `add-candidate-review`, entry **`226bf170-5769-4201-bdf5-64f790c968f5`** (digest-checked, `written`). 12 evaluated, **0 flagged, 0 `declined_hard_gate`**, 12 `declined`.
- **Gate.** `invalidation_status` is populated and evaluable for all 12: no NULL, no `NOT_DISCRETELY_RECORDED_AT_ENTRY` and no `NOT_ASSESSED_BY_THIS_BACKFILL`. No criterion is breached.

|Tranche|Close 11-09|Mark vs cost|Trigger|Disposition|
|---|---|---|---|---|
|D:AMZN:2026-07-09|266.93|+10.65%|none|declined|
|D:AMZN:2026-07-30|266.93|+0.47%|none|declined|
|D:DIS:2026-05-07|119.12|+7.01%|none|declined|
|D:DIS:2026-08-05|119.12|+14.78%|none|declined|
|D:GEV:2026-08-03|829.34|−14.49%|dip-with-intact-thesis|declined (no funding path)|
|D:GOOGL:2026-07-09|288.15|−19.92%|dip-with-intact-thesis|declined (no funding path)|
|D:GOOGL:2026-07-26|288.15|−12.11%|dip-with-intact-thesis|declined (no funding path)|
|D:ISRG:2026-07-20|460.56|+31.77%|none|declined|
|D:RTX:2026-04-27|196.31|+10.97%|none|declined|
|D:TSM:2026-07-21|388.62|−9.17%|dip-with-intact-thesis|declined (no funding path)|
|D:TSM:2026-07-29|388.62|−1.08%|dip-with-intact-thesis|declined (no funding path)|
|D:UBER:2026-07-09|71.17|−2.78%|none|declined|

- **Price basis.** IBKR 11-09 regular-session closes over each tranche's own `cost_basis / shares`. IBKR position marks and snapshots were after-hours prints (`is_close` false) and were not used.
- **Why none is flagged.** D is DO-NOT-ACTIVATE and capital-disabled, so no add has a funding path.

## ANALYSIS — REGIME CHECK

The standing `shock_overlay` reads `latent` (live read this run; FUNDAMENTAL_AXIS re-scored as of 2026-11-09). The Gulf/Hormuz structure is open, with the US blockade of Iranian ports in force.

**Qualifying shock event: NO new one.** No dated, attributable escalation on the Gulf/Iran channel was found on 11-09: no new attack on supply infrastructure and no new closure. The Iranian state-media claim of US strikes on Qeshm "overnight" has UNRESOLVED timing, and its oil reaction was negative. The 11-08 Houthi/Riyadh and Khor Mor escalations were flagged PENDING by the prior run. For the record, their two-session oil window has S1 = 11-09: Brent (BZUSD) 98.32 → 92.32 (−6.10%), the opposite direction. S2 = 11-10 has not closed; M1R rules on qualification.

**Qualifying resolution event: NO.** No ceasefire or settlement is in force, the blockade has not been lifted, and no tariff regime was removed or sanctions posture settled. The Israel Hayom "interim deal" (Hormuz reopens, blockade lifted, $8B released) is unconfirmed by either government and was called false by a Qatari official (Bloomberg). The Trump–Qatar PM meeting ended with no announced agreement. Brent's −6.10% is a measurable move, but it is a reaction to talk, not to a resolution in force; narrative de-escalation does not qualify. No `router_review` flag.

**Measured triggers, for D2 to detect (not computed here).**
- VIX closed **19.92** against 25.64: a move *out of* HIGH on the IBKR bar. That is one of the mirror triggers D2 item 4 reads from D2a's step-1e `TECHNICAL_SIGNAL` rows.
- SPY_TREND reads NEUTRAL (D2a, 11-06).
- Breadth is **63.14** (this run's row), up from 55.97.
- Brent's BZUSD row for the shock price leg is D2a step 1d's.

## EQUITY-BREADTH OBSERVATION

- **Row written:** `events.regime_events` `TECHNICAL_INPUT` / `EQUITY_BREADTH_PCT`, as_of 2026-11-09, **63.14**.
- **Source.** Barchart `$S5TH` via `tavily_extract` (`?cb=20261109`), headed "Quote Overview for Mon, Nov 9th, 2026". The page stamp is **16:50 ET** (post-close, settled). Previous Close 55.97 equals the stored 11-06 value (no revision). It is not an exact repeat, and there is no carry bar.
- **EODData** shows a 09 Nov row of O 57.76 H 65.33 L 57.76 **C 64.74**, but its quote-box stamp is **15:57 ET**, a pre-close capture, so it is unsettled. Barchart and EODData are one feed family anyway, so this run has a **single settled source**. The 1.60 pp gap is read as EODData's pre-close capture, consistent with the 2026-09-17 settlement-lag precedent.
- **ChartRow** still carries the Nov 6 reading (278 of 497, 55.94%) behind a "Nov 9" header: `chartrow_unconfirmed=lag session 2026-11-06`. No 11-05 ChartRow count is on record, so the lagged check of the prior row neither confirms nor refutes. A re-read is scheduled as the last step before run completion.
- **MacroMicro** was not probed (Monday; the weekly re-probe rides on Sunday).

## ANALYSIS — FRONTIER-LLM CAPABILITY CHECK

NO CAPTURE. The `hf://papers/daily/latest` listing was read alongside the Monday battery search ("cross-session consistency LLM agent"). Its only agent-risk items are 2611.06808 (LLM temporal self-knowledge and backtest leakage), 2611.09113 (agent authorization drift) and 2611.07624 (agent-evolution gains unreliable). All are dated 2026-11-04..06, before this window. The battery search returned nothing newer than 2026-10-02.

## RECOMMENDED ACTIONS

- Watchlist: ADD FRVO to the Strategy B new-entry index — earnings release (8-K 2.02), pre-open release (EDGAR 2026-11-09T13:37:24Z); reaction session 2026-11-09, +26.02% (9.03 → 11.38), with 6 prior ≥5% sessions in the window; qualifying_event_date 2026-11-09.
- Watchlist: ADD IONS to the Strategy B new-entry index — earnings release (8-K 2.02), pre-open release (EDGAR 2026-11-09T12:00:30Z); reaction session 2026-11-09, -21.36% (39.42 → 31.0), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-09.
- Watchlist: ADD PRAX to the Strategy B new-entry index — earnings release (8-K 2.02), pre-open release (EDGAR 2026-11-09T12:02:20Z); reaction session 2026-11-09, +19.94% (277.62 → 332.97), with 4 prior ≥5% sessions in the window; qualifying_event_date 2026-11-09.
- Watchlist: ADD QXO to the Strategy B new-entry index — earnings release (8-K 2.02), pre-open release (EDGAR 2026-11-09T11:02:42Z); reaction session 2026-11-09, +19.20% (11.56 → 13.78), with 3 prior ≥5% sessions in the window; qualifying_event_date 2026-11-09.
- Watchlist: ADD IBRX to the Strategy B new-entry index — 8-K 2.02 earnings filed same morning, pre-open release (EDGAR 2026-11-09T12:39:35Z); reaction session 2026-11-09, -17.66% (8.635 → 7.11), with 5 prior ≥5% sessions in the window; qualifying_event_date 2026-11-09.
- Watchlist: ADD IMVT to the Strategy B new-entry index — earnings release (8-K 2.02), pre-open release (EDGAR 2026-11-09T12:09:17Z); reaction session 2026-11-09, +15.13% (30.53 → 35.15), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-09.
- Watchlist: ADD ASTS to the Strategy B new-entry index — Reg FD: plan to build own 20-ton rocket w/ Firefly Miranda engines, after-close release (EDGAR 2026-11-06T22:00:25Z); reaction session 2026-11-09, +14.10% (32.33 → 36.89), with 4 prior ≥5% sessions in the window; qualifying_event_date 2026-11-06.
- Watchlist: ADD VIA to the Strategy B new-entry index — earnings release (8-K 2.02), pre-open release (EDGAR 2026-11-09T11:59:27Z); reaction session 2026-11-09, +12.80% (37.72 → 42.55), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-09.
- Watchlist: ADD VIR to the Strategy B new-entry index — 7.01: Phase 3 ECLIPSE 1 topline call (elebsiran+tobevibart, hepatitis delta) 8:30 ET, pre-open release (EDGAR 2026-11-09T13:31:22Z); reaction session 2026-11-09, +11.71% (12.21 → 13.64), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-09.
- Watchlist: ADD AGLT to the Strategy B new-entry index — de-SPAC business combination closing (Churchill Capital XI -> Agility Robotics, after-close release (EDGAR 2026-11-06T21:18:25Z); reaction session 2026-11-09, -11.31% (9.9 → 8.78), with 5 prior ≥5% sessions in the window; qualifying_event_date 2026-11-06.
- Watchlist: ADD FERG to the Strategy B new-entry index — earnings release (8-K 2.02), pre-open release (EDGAR 2026-11-09T11:50:12Z); reaction session 2026-11-09, +11.22% (233.7 → 259.93), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-09.
- Watchlist: ADD CNH to the Strategy B new-entry index — Q3 2026 earnings 8-K (2.02) + 1.01 sale of 70% of Construction Equipment business to Kobelco (acquirer-side counterparty news, pre-open release (EDGAR 2026-11-09T13:02:04Z); reaction session 2026-11-09, +10.90% (11.56 → 12.82); qualifying_event_date 2026-11-09.
- Watchlist: ADD CEG to the Strategy B new-entry index — earnings release (8-K 2.02), pre-open release (EDGAR 2026-11-09T11:53:11Z); reaction session 2026-11-09, +10.46% (249.95 → 276.09), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-09.
- Watchlist: ADD NRG to the Strategy B new-entry index — 7.01: agreed to sell six gas-fired plants to LS Power affiliate for $4B cash (NRG is seller), pre-open release (EDGAR 2026-11-09T11:45:04Z); reaction session 2026-11-09, +10.32% (88.29 → 97.4), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-09.
- Watchlist: ADD MNDY to the Strategy B new-entry index — 6-K: Q3 2026 results press release, pre-open release (EDGAR 2026-11-09T12:00:31Z); reaction session 2026-11-09, -9.10% (87.93 → 79.93), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-09.
- Watchlist: ADD KGS to the Strategy B new-entry index — earnings release (8-K 2.02), pre-open release (EDGAR 2026-11-09T11:32:12Z); reaction session 2026-11-09, +7.20% (41.67 → 44.67), with 4 prior ≥5% sessions in the window; qualifying_event_date 2026-11-09.
- Watchlist: ADD WTTR to the Strategy B new-entry index — earnings release (8-K 2.02), pre-open release (EDGAR 2026-11-09T12:05:36Z); reaction session 2026-11-09, -6.86% (16.18 → 15.07), with 3 prior ≥5% sessions in the window; qualifying_event_date 2026-11-09.
- Watchlist: ADD GCMG to the Strategy B new-entry index — earnings release (8-K 2.02), pre-open release (EDGAR 2026-11-09T12:01:57Z); reaction session 2026-11-09, +6.24% (12.66 → 13.45); qualifying_event_date 2026-11-09.
- Watchlist: ADD VRDN to the Strategy B new-entry index — 7.01/8.01: VRDN-008 phase 1 data, pre-open release (EDGAR 2026-11-09T12:33:19Z); reaction session 2026-11-09, +5.97% (28.49 → 30.19), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-09.
- Watchlist: ADD TGTX to the Strategy B new-entry index — earnings release (8-K 2.02), pre-open release (EDGAR 2026-11-09T12:04:06Z); reaction session 2026-11-09, +5.93% (59.83 → 63.38), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-09.
- Watchlist: ADD TNGX to the Strategy B new-entry index — earnings release (8-K 2.02), pre-open release (EDGAR 2026-11-09T12:13:42Z); reaction session 2026-11-09, +5.77% (21.5 → 22.74), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-09.
- Watchlist: ADD AMG to the Strategy B new-entry index — earnings release (8-K 2.02), pre-open release (EDGAR 2026-11-09T12:06:46Z); reaction session 2026-11-09, +5.56% (362.96 → 383.15); qualifying_event_date 2026-11-09.

```yaml d1_actions
- action: watchlist
  ticker: FRVO
  strategy: B
  qualifying_event_date: 2026-11-09
  source_research_screen_id: 9f5c6b11-5ff1-4e65-b563-d0290627864d
  detail: "ADD to the Strategy B new-entry index (B gated, index only, no thesis handoff): earnings release (8-K 2.02), pre-open release (EDGAR 2026-11-09T13:37:24Z); reaction session 2026-11-09, +26.02% (9.03 -> 11.38), with 6 prior ≥5% sessions in the window; qualifying_event_date 2026-11-09."
- action: watchlist
  ticker: IONS
  strategy: B
  qualifying_event_date: 2026-11-09
  source_research_screen_id: 9f5c6b11-5ff1-4e65-b563-d0290627864d
  detail: "ADD to the Strategy B new-entry index (B gated, index only, no thesis handoff): earnings release (8-K 2.02), pre-open release (EDGAR 2026-11-09T12:00:30Z); reaction session 2026-11-09, -21.36% (39.42 -> 31.0), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-09."
- action: watchlist
  ticker: PRAX
  strategy: B
  qualifying_event_date: 2026-11-09
  source_research_screen_id: 9f5c6b11-5ff1-4e65-b563-d0290627864d
  detail: "ADD to the Strategy B new-entry index (B gated, index only, no thesis handoff): earnings release (8-K 2.02), pre-open release (EDGAR 2026-11-09T12:02:20Z); reaction session 2026-11-09, +19.94% (277.62 -> 332.97), with 4 prior ≥5% sessions in the window; qualifying_event_date 2026-11-09."
- action: watchlist
  ticker: QXO
  strategy: B
  qualifying_event_date: 2026-11-09
  source_research_screen_id: 9f5c6b11-5ff1-4e65-b563-d0290627864d
  detail: "ADD to the Strategy B new-entry index (B gated, index only, no thesis handoff): earnings release (8-K 2.02), pre-open release (EDGAR 2026-11-09T11:02:42Z); reaction session 2026-11-09, +19.20% (11.56 -> 13.78), with 3 prior ≥5% sessions in the window; qualifying_event_date 2026-11-09."
- action: watchlist
  ticker: IBRX
  strategy: B
  qualifying_event_date: 2026-11-09
  source_research_screen_id: 9f5c6b11-5ff1-4e65-b563-d0290627864d
  detail: "ADD to the Strategy B new-entry index (B gated, index only, no thesis handoff): 8-K 2.02 earnings filed same morning, pre-open release (EDGAR 2026-11-09T12:39:35Z); reaction session 2026-11-09, -17.66% (8.635 -> 7.11), with 5 prior ≥5% sessions in the window; qualifying_event_date 2026-11-09."
- action: watchlist
  ticker: IMVT
  strategy: B
  qualifying_event_date: 2026-11-09
  source_research_screen_id: 9f5c6b11-5ff1-4e65-b563-d0290627864d
  detail: "ADD to the Strategy B new-entry index (B gated, index only, no thesis handoff): earnings release (8-K 2.02), pre-open release (EDGAR 2026-11-09T12:09:17Z); reaction session 2026-11-09, +15.13% (30.53 -> 35.15), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-09."
- action: watchlist
  ticker: ASTS
  strategy: B
  qualifying_event_date: 2026-11-06
  source_research_screen_id: 9f5c6b11-5ff1-4e65-b563-d0290627864d
  detail: "ADD to the Strategy B new-entry index (B gated, index only, no thesis handoff): Reg FD: plan to build own 20-ton rocket w/ Firefly Miranda engines, after-close release (EDGAR 2026-11-06T22:00:25Z); reaction session 2026-11-09, +14.10% (32.33 -> 36.89), with 4 prior ≥5% sessions in the window; qualifying_event_date 2026-11-06."
- action: watchlist
  ticker: VIA
  strategy: B
  qualifying_event_date: 2026-11-09
  source_research_screen_id: 9f5c6b11-5ff1-4e65-b563-d0290627864d
  detail: "ADD to the Strategy B new-entry index (B gated, index only, no thesis handoff): earnings release (8-K 2.02), pre-open release (EDGAR 2026-11-09T11:59:27Z); reaction session 2026-11-09, +12.80% (37.72 -> 42.55), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-09."
- action: watchlist
  ticker: VIR
  strategy: B
  qualifying_event_date: 2026-11-09
  source_research_screen_id: 9f5c6b11-5ff1-4e65-b563-d0290627864d
  detail: "ADD to the Strategy B new-entry index (B gated, index only, no thesis handoff): 7.01: Phase 3 ECLIPSE 1 topline call (elebsiran+tobevibart, hepatitis delta) 8:30 ET, pre-open release (EDGAR 2026-11-09T13:31:22Z); reaction session 2026-11-09, +11.71% (12.21 -> 13.64), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-09."
- action: watchlist
  ticker: AGLT
  strategy: B
  qualifying_event_date: 2026-11-06
  source_research_screen_id: 9f5c6b11-5ff1-4e65-b563-d0290627864d
  detail: "ADD to the Strategy B new-entry index (B gated, index only, no thesis handoff): de-SPAC business combination closing (Churchill Capital XI -> Agility Robotics, after-close release (EDGAR 2026-11-06T21:18:25Z); reaction session 2026-11-09, -11.31% (9.9 -> 8.78), with 5 prior ≥5% sessions in the window; qualifying_event_date 2026-11-06."
- action: watchlist
  ticker: FERG
  strategy: B
  qualifying_event_date: 2026-11-09
  source_research_screen_id: 9f5c6b11-5ff1-4e65-b563-d0290627864d
  detail: "ADD to the Strategy B new-entry index (B gated, index only, no thesis handoff): earnings release (8-K 2.02), pre-open release (EDGAR 2026-11-09T11:50:12Z); reaction session 2026-11-09, +11.22% (233.7 -> 259.93), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-09."
- action: watchlist
  ticker: CNH
  strategy: B
  qualifying_event_date: 2026-11-09
  source_research_screen_id: 9f5c6b11-5ff1-4e65-b563-d0290627864d
  detail: "ADD to the Strategy B new-entry index (B gated, index only, no thesis handoff): Q3 2026 earnings 8-K (2.02) + 1.01 sale of 70% of Construction Equipment business to Kobelco (acquirer-side counterparty news, pre-open release (EDGAR 2026-11-09T13:02:04Z); reaction session 2026-11-09, +10.90% (11.56 -> 12.82); qualifying_event_date 2026-11-09."
- action: watchlist
  ticker: CEG
  strategy: B
  qualifying_event_date: 2026-11-09
  source_research_screen_id: 9f5c6b11-5ff1-4e65-b563-d0290627864d
  detail: "ADD to the Strategy B new-entry index (B gated, index only, no thesis handoff): earnings release (8-K 2.02), pre-open release (EDGAR 2026-11-09T11:53:11Z); reaction session 2026-11-09, +10.46% (249.95 -> 276.09), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-09."
- action: watchlist
  ticker: NRG
  strategy: B
  qualifying_event_date: 2026-11-09
  source_research_screen_id: 9f5c6b11-5ff1-4e65-b563-d0290627864d
  detail: "ADD to the Strategy B new-entry index (B gated, index only, no thesis handoff): 7.01: agreed to sell six gas-fired plants to LS Power affiliate for $4B cash (NRG is seller), pre-open release (EDGAR 2026-11-09T11:45:04Z); reaction session 2026-11-09, +10.32% (88.29 -> 97.4), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-09."
- action: watchlist
  ticker: MNDY
  strategy: B
  qualifying_event_date: 2026-11-09
  source_research_screen_id: 9f5c6b11-5ff1-4e65-b563-d0290627864d
  detail: "ADD to the Strategy B new-entry index (B gated, index only, no thesis handoff): 6-K: Q3 2026 results press release, pre-open release (EDGAR 2026-11-09T12:00:31Z); reaction session 2026-11-09, -9.10% (87.93 -> 79.93), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-09."
- action: watchlist
  ticker: KGS
  strategy: B
  qualifying_event_date: 2026-11-09
  source_research_screen_id: 9f5c6b11-5ff1-4e65-b563-d0290627864d
  detail: "ADD to the Strategy B new-entry index (B gated, index only, no thesis handoff): earnings release (8-K 2.02), pre-open release (EDGAR 2026-11-09T11:32:12Z); reaction session 2026-11-09, +7.20% (41.67 -> 44.67), with 4 prior ≥5% sessions in the window; qualifying_event_date 2026-11-09."
- action: watchlist
  ticker: WTTR
  strategy: B
  qualifying_event_date: 2026-11-09
  source_research_screen_id: 9f5c6b11-5ff1-4e65-b563-d0290627864d
  detail: "ADD to the Strategy B new-entry index (B gated, index only, no thesis handoff): earnings release (8-K 2.02), pre-open release (EDGAR 2026-11-09T12:05:36Z); reaction session 2026-11-09, -6.86% (16.18 -> 15.07), with 3 prior ≥5% sessions in the window; qualifying_event_date 2026-11-09."
- action: watchlist
  ticker: GCMG
  strategy: B
  qualifying_event_date: 2026-11-09
  source_research_screen_id: 9f5c6b11-5ff1-4e65-b563-d0290627864d
  detail: "ADD to the Strategy B new-entry index (B gated, index only, no thesis handoff): earnings release (8-K 2.02), pre-open release (EDGAR 2026-11-09T12:01:57Z); reaction session 2026-11-09, +6.24% (12.66 -> 13.45); qualifying_event_date 2026-11-09."
- action: watchlist
  ticker: VRDN
  strategy: B
  qualifying_event_date: 2026-11-09
  source_research_screen_id: 9f5c6b11-5ff1-4e65-b563-d0290627864d
  detail: "ADD to the Strategy B new-entry index (B gated, index only, no thesis handoff): 7.01/8.01: VRDN-008 phase 1 data, pre-open release (EDGAR 2026-11-09T12:33:19Z); reaction session 2026-11-09, +5.97% (28.49 -> 30.19), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-09."
- action: watchlist
  ticker: TGTX
  strategy: B
  qualifying_event_date: 2026-11-09
  source_research_screen_id: 9f5c6b11-5ff1-4e65-b563-d0290627864d
  detail: "ADD to the Strategy B new-entry index (B gated, index only, no thesis handoff): earnings release (8-K 2.02), pre-open release (EDGAR 2026-11-09T12:04:06Z); reaction session 2026-11-09, +5.93% (59.83 -> 63.38), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-09."
- action: watchlist
  ticker: TNGX
  strategy: B
  qualifying_event_date: 2026-11-09
  source_research_screen_id: 9f5c6b11-5ff1-4e65-b563-d0290627864d
  detail: "ADD to the Strategy B new-entry index (B gated, index only, no thesis handoff): earnings release (8-K 2.02), pre-open release (EDGAR 2026-11-09T12:13:42Z); reaction session 2026-11-09, +5.77% (21.5 -> 22.74), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-09."
- action: watchlist
  ticker: AMG
  strategy: B
  qualifying_event_date: 2026-11-09
  source_research_screen_id: 9f5c6b11-5ff1-4e65-b563-d0290627864d
  detail: "ADD to the Strategy B new-entry index (B gated, index only, no thesis handoff): earnings release (8-K 2.02), pre-open release (EDGAR 2026-11-09T12:06:46Z); reaction session 2026-11-09, +5.56% (362.96 -> 383.15); qualifying_event_date 2026-11-09."
```

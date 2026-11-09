2026-11-08
<!-- d1_scan_through_utc: 2026-11-09T05:49:33Z -->

# Daily Market Development Scan — session 2026-11-06 (Fri), run 2026-11-08 (Sun)

Scan window: 2026-11-05 15:42 MT → 2026-11-08 22:49 MT (~3 days 7 hours). The start is the prior `Daily.md` marker `2026-11-05T22:42:50Z`. The window holds one completed US session, Friday 2026-11-06, plus the weekend. This run was hosted inline by OPS2 at 22:15 MT because D1's own 16:10 MT session stopped at about 16:36 MT without finishing. That session had already landed the breadth row, the sector-move screen, the add-candidate sweep, the park heartbeat and the paper-book calls; this run reuses those rows and does not write them again.

SCAN MODE: ROUTER-GATED (A DO-NOT-ACTIVATE; B DO-NOT-ACTIVATE — PENDING div-B-202611-2; D DO-NOT-ACTIVATE; E DO-NOT-ACTIVATE), read live from `state.current_regime`. C is `HYBRID ACTIVATE (FOMC-only)`, so only its carve-out class is evaluated.

- **Indices (IBKR closes 11-05 → 11-06).** SPY +0.31% (735.29), QQQ +1.40%, SMH +3.63%, RSP −0.38%. A narrow, chip-led relief session after the 11-05 rout. The S&P 500 had its worst week since April 2025 (TheStreet Pro).
- **Volatility.** VIX 28.18 → **25.64**, still above the HIGH threshold of 25 (D2a `TECHNICAL_SIGNAL` VIX_REGIME HIGH, as of 11-06).
- **Rates and dollar.** October payrolls +165k against about 65k expected; the 2-year yield rose about 4 bp to 4.51%, and the dollar index gained 0.7%, its best day since 06-18. CME FedWatch put December hike odds at 77%. Curve 10Y 4.86 / 2Y 4.51 (D2a).
- **Oil.** Brent (BZUSD, provisional same-evening read) **98.32 on 2026-11-06**, against 98.29 on 2026-11-05 in the same FMP series (flat, +0.03%). The curated series carries 99.37 for 11-05 (vendor revision). Brent fell more than 16% over the week.
- **Crypto.** Bitcoin closed the week at $74,968, under its 50-week average.
- **Breadth.** Down to **55.97** from 58.56 (Barchart `$S5TH`, single settled source; ChartRow 55.94% as of Nov 6).

## TL;DR

- **Exits triggered: none.** No tranche carries a mechanical trigger, and no development meets an invalidation criterion.
- **New entry candidates: none routed.** 63 names cleared Strategy B's frozen ≥5% floor on their own stamped events, all confirmed on IBKR bars. B is gated, so they go to the new-entry index only; no thesis handoff. The screen's durable row did not land this run (see item 3). No new FOMC-class C candidate.
- **Add candidates: none (0 of 12).** All 12 D tranches clear the hard gate; five dip reads (GOOGL ×2, TSM ×2, GEV) are declined because D is DO-NOT-ACTIVATE.
- **Watchlist: 63 changes.** ADD the 63 names to the Strategy B new-entry index.
- **Regime review: one PENDING flag.** The 2026-11-08 Houthi missile strike on Riyadh (Aramco Tower damaged) and the drone strike on Iraq's Khor Mor gas field are dated Gulf-channel escalations. Their two-session oil window (11-09, 11-10) has not closed. No resolution event.

Park: VOO-only pin verified

Paper book (J): 39 calls, 361/30 realized, net_mu -0.85%, ready=FALSE

## DEVELOPMENTS

### 1. Market-wide breaking events

### Iran / Hormuz / Gulf (channel: US blockade of Iranian ports plus Iran's closure of Hormuz)
- **No ceasefire, settlement or blockade lift took effect 11-06..11-08.**
  - Qatar sent a two-stage, 48-hour reciprocal plan: Day 1 the US lifts the blockade and IAEA inspections start; Day 2 Hormuz reopens. Neither side had accepted it as of 11-06 (houseofsaud.com citing Axios, 2026-11-06; LA Times, 2026-11-07).
  - Iran is reviewing Qatari nuclear proposals (AP, 2026-11-06 22:14Z).
  - Qatar denied that talks had failed (Qatar Int'l Media Office via Open Magazine and Euronews, 2026-11-07). An LA Times headline says "Iran delegation has left Qatar" (UNRESOLVED detail).
  - VP Vance is pushing a new ceasefire through Qatari and Pakistani mediators (Axios via AA, 2026-11-07; SFG Media, 2026-11-08: "little substantive progress").
  - **Trump meets the Qatari PM on Mon 11-09 at 12:00 ET (17:00Z)** about a new ceasefire (investingLive, 2026-11-09 03:53Z). This is outside the window and is the next possible resolution catalyst.
- **New kinetic and supply events:**
  - **11-06:** Trump confirmed "minor" US strikes on an Iranian air-defense system; explosions reported at Suza, Qeshm Island (AP via The Hindu, 2026-11-07; Euronews, 2026-11-07). The IRGC claimed two more tankers hit mines in Hormuz (Mehr / houseofsaud, 2026-11-06). These claims are unverified by any independent maritime authority (UNRESOLVED).
  - **11-07:** US forces disabled a St Kitts-flagged cargo ship (M/V Huda) that was trying to breach the blockade in the Gulf of Oman (AP via Seattle Times, 2026-11-08). Iran said two tankers struck mines and caught fire (same source; UNRESOLVED). CENTCOM announced **Task Force Iron Gate**, which extends the blockade effort to Iran's land borders and the Caspian (iranintl / houseofsaud, 2026-11-07–09). Per houseofsaud, CENTCOM says the blockade has prevented more than $25B of Iranian crude exports since 07-14.
  - **11-08 (Sunday):**
    - **Houthi missiles at Riyadh.** Saudi forces intercepted two missiles. Falling debris damaged the **Aramco Tower** in KAFD (minor damage, no casualties, per Saudi Energy Ministry; Reuters via CNBC and NBC, 2026-11-08). The Houthis claimed strikes on Aramco facilities in Riyadh and Khurais and on KKIA airport (UNRESOLVED). **No outage of Saudi production or exports has been confirmed** (discoveryalert, 2026-11-08).
    - **Khor Mor gas field (Iraqi Kurdistan) drone strike** late Sunday. Production halted and about 2.5–2.8 GW of power was lost (KRG Electricity Ministry via Al Jazeera, 2026-11-09; Reuters via investingLive, 2026-11-08). The gas feeds domestic power plants, not exports, so the global supply impact is limited (investingLive). No one has claimed it; Iran or allied militias are suspected.
- **Oil reaction:**
  - Brent fell more than 16% in the week to 11-06 as traders bet on post-election diplomacy (NDTV Profit, 2026-11-08).
  - Monday 11-09 Asia: crude fell at the open on Trump's CNN comments, then recovered to about unchanged after downbeat remarks from Rubio (investingLive, 2026-11-09 03:53Z). Trump said new Iran strikes were "highly unlikely."
  - No session in the window had closed after the weekend events at the time of writing.

#### US politics and policy after the election
- **Democratic sweep of the House and Senate** (11-03). CNBC (2026-11-08) reports Democrats are preparing a "first-100-hours" push to unwind tariffs. About $138B of tariff refunds have been paid since the February SCOTUS ruling, with about $20B still pending. Trump vowed to "VETO anything that hurts America" (PBS, 2026-11-08). Trump's 60 Minutes interview aired 11-08 (CBS). **No new tariff action and no CR or shutdown event found in the window** (UNRESOLVED / none found).
- **Data-center policy** was the driver of the 11-05 rout and remains the dominant equity theme:
  - Texas Governor-elect Hinojosa has pledged an immediate moratorium; about 13 GW of planned capacity is at risk (GLJ Research note via LinkedIn digest, 2026-11-06).
  - Georgia Governor-elect Bottoms pledged a pause.
  - Goldman (Mike Ng) frames the risk as "timing rather than cancellations" for 2027. Texas is about 20% / 27% of 2027/28 under-construction additions (ZeroHedge, 2026-11-06).
  - OpenAI's CFO says it will keep investing (CNBC, 2026-11-06, per aibubblemonitor).
- **SoftBank / Stargate credit stress:**
  - Musk posted at 06:25Z on 11-06: "SoftBank is defaulting on their turbine orders." He gave no evidence. Neither SoftBank nor any supplier (GE Vernova / Siemens Energy / MHI) has confirmed (FourWeekMBA, 2026-11-06; Benzinga, 2026-11-06). **UNRESOLVED.**
  - SoftBank 5-year CDS reached 466 bp, the highest since Oct 2022 (Reuters via Benzinga, 2026-11-06). SoftBank shares fell about 11% in Tokyo (SilverTrade, 2026-11-06).
  - Neither GEV nor SoftBank filed anything on EDGAR in the window (GEV's last filing was a 13G/A on 11-05).
  - Separately: Microsoft is winding down Oracle AI-compute rental (briefs.co headline, 2026-11-06), and Oracle has reportedly issued a force-majeure notice on a New Mexico Stargate site (SilverTrade). Both are **UNRESOLVED**.
- **Nvidia CEO scandal (Sunday 11-08):**
  - Jensen Huang admitted an affair with Alice Huang, a Megaspeed executive whom US intelligence reportedly regards as an MSS asset. He did so in an all-staff email ("A message to our company"; Axios / The Verge / FT via Yahoo, 2026-11-08).
  - The board opened an independent investigation. It says it has "no reason to believe" national security or company secrets were compromised and expresses confidence in Huang. He continues as CEO.
  - House Republican chairs (Mast, Moolenaar, Crawford) requested a closed-door briefing on **11-18** (CTech, 2026-11-08).
  - **No NVDA 8-K in the window** (EDGAR: the only filing is a Form 4 accepted 2026-11-06T21:12). Asia markets "shrug off" the news (investingLive, 2026-11-09).
- **Bankruptcies:** no material ≥$2B US bankruptcy found. Brightspeed is weighing a $2–3B lifeline (briefs.co headline, 2026-11-06; UNRESOLVED). Paraguay's president was ousted after the Ueno Bank collapse (Open Magazine sidebar; not a US-listed event).
- **Crypto:** BTC closed the week ending 11-08 at $74,968, back under its 50-week MA (BeInCrypto, 2026-11-09). About $745M of liquidations (96% longs) hit on Sunday evening. ETH was about $2,120 (cryptoticker, 2026-11-08), with about $93M of US ETH-ETF outflows on Friday. BTC was below $75k in Monday Asia trading (investingLive, 2026-11-09).
- **Other:**
  - China October PPI +5.7% y/y (largest since 2022); CPI 0.7% (investingLive, 2026-11-09).
  - Gold about $4,130 Monday Asia, despite Goldman cutting its forecasts (same source).
  - USD/JPY about 158.3.
  - The dollar index gained 0.7% on 11-06, its best day since 06-18 (TheStreet Pro, 2026-11-07).
  - The S&P 500 had its worst week since April 2025 (TheStreet Pro).

### 2. Scheduled events that resolved in the window

### October Employment Situation (BLS, released 2026-11-06 08:30 ET; figures from wires because bls.gov returned 403 to curl)
- **Nonfarm payrolls +165k** vs consensus 65k (Reuters / LSEG; Dow Jones consensus 59k per CNBC). The Reuters range was 35k–125k.
- **Revisions +84k:** August revised to 186k (+53k) and September to 60k (+31k).
- Private payrolls +159k.
- **Unemployment rate 4.1%** (prior and consensus 4.2%). U-6 rose to 7.9% from 7.6%. Participation 61.9%.
- **Average hourly earnings +0.4% m/m** (consensus 0.3%), **+3.1% y/y** (consensus 2.9%).
- Sector gains: professional and business services +70k, healthcare +42k (Reuters; Zillow says healthcare and social assistance +55k), transportation +25k. Leisure and hospitality fell.
- Household employment +463k. Part-time for economic reasons +339k.
- Sources: Reuters, CNN, Fox Business, Stephens PDF, all 2026-11-06.
- **Market reaction:** the 2-year Treasury yield rose about 4 bp to 4.51%. The dollar index gained 0.7%. CME FedWatch put December hike odds at **77%**, up from 67% on Thursday and 82% on Wednesday (TheStreet Pro, 2026-11-07).

#### Other data and central banks
- **UMich preliminary November sentiment: 51.0** vs 48.0 prior and consensus, the highest since August. Year-ahead inflation expectations fell to **4.3%**. The survey closed 11-02, before the election and the AI rout (TheStreet Pro, 2026-11-07; TickerSpark, 2026-11-07).
- **Fed speakers on 11-06:**
  - **Williams** (Frankfurt, 04:30 ET): "Inflation is absolutely too high." Expectations "remain well anchored." It is an "appropriate time to accumulate more information." No December signal (Reuters via Ausecure, 2026-11-06).
  - **Musalem** (09:10 ET) and **Bowman** (12:15 ET, a fireside chat on supervision and regulation at the University of Mississippi; Forex Factory) also spoke, as did Hammack and Logan per TickerSpark. No market-moving content was found (UNRESOLVED detail).
- **BoE** hiked 25 bp to **4.00%** on 11-05 (8–1 vote), keeping options open (EXANTE, 2026-11-06; ING, 2026-11-06).
- **Canada** October jobs −4.7k vs +14.6k expected; unemployment rose to 6.7% (Ausecure, 2026-11-06).
- **BoJ:** Ueda spoke 11-07 00:00 GMT+8 (no content captured, UNRESOLVED).

#### Earnings 2026-11-06 — enumeration (Nasdaq `api/calendar/earnings?date=2026-11-06`, curl, fetched 2026-11-09 05:20Z)
- 129 rows in total; **47 at or above $2B market cap**. Time field: **2 pre-market (VST, ECHO), 0 after-hours, 45 time-not-supplied**. EDGAR acceptance times show that almost every verified print was filed 11:00–14:00Z, which is pre-market ET.
- ≥$2B names, largest first: ENB, MRNA, BAM, HUM, HMC, VST, UI, PPL, ECHO, BIP, PAA, BEN, EMA, TU, CHTR, ELAN, FRHC, KT, MSGK, ESNT, FLR, CGON, PAGP, VEON, WULF, STWD, AQN, DK, CLMT, ATMU, BH, BH.A, TDS, OKLO, NHC, KYIV, DKL, TR, MSGR, AD, ASST, BKD, UA, UAA, SHO, TILE, UTZ.
- **Calendar rows that fail the EVENT-IDENTITY GATE:**
  - **ECHO:** its Q3 10-Q was accepted **2026-11-03T13:15**, so it did not report in this window. The calendar row is stale.
  - **HMC:** no 6-K in the window, so its print is unverified (UNRESOLVED / pending).

#### Earnings — verified against the issuer's own EDGAR filing
The table gives the data.sec.gov `acceptanceDateTime` for each 8-K or 6-K; every Q3 release covers the period ended 2026-09-30. "Consensus" is labelled by source: Nasdaq calendar `epsForecast` is a free source, and wire or Briefing figures are noted where used.

| Ticker | Filing (accession), accepted | Fiscal period stated | Result (issuer) | Consensus (source) | Reaction |
|---|---|---|---|---|---|
| **MRNA** | 8-K 2.02 (0001682852-26-000194), 2026-11-06T11:47:30 | Q3 2026 | Revenue $1.313B (+29%); GAAP diluted EPS **$0.38**; net income $162M; FY26 revenue growth raised to 15–25% (was ≤10%); year-end cash $8.1–8.3B | EPS −$1.25 / revenue $885.1M (LSEG via CNBC / qz); FactSet −$1.10 (WSJ); Nasdaq −$1.10 | **+5.3%** close (Trefis, 2026-11-07) |
| **CHTR** | 8-K 2.02 (0001091667-26-000072), 2026-11-06T12:00:54 | Q3 2026 | Revenue $14.9B (+9.1% actual; pro forma $16.5B, −1.5%); net loss $2.4B (EPS −$20.50) on a **$6.3B franchise impairment**; pro forma Internet customers −233k; new $2B cost-savings plan; 2026 pro forma capex about $13.0B (was about $11.4B) | EPS $8.85 (Briefing.com) / $9.08 (Nasdaq) | **−6.19%** (Investing.com quote) |
| **HUM** | 8-K 2.02/7.01 (0000049071-26-000064), 2026-11-06T11:09:28 | 3Q26 | GAAP EPS $1.33; **adjusted loss −$0.70**; benefit ratio 93.7% (better than guided); FY26 adjusted EPS guide raised to "at least $9.50" (from $9.00) | −$1.03 (Nasdaq) | UNRESOLVED |
| **VST** | 8-K 2.02 (0001692819-26-000023), 2026-11-06T12:01:01 | Q3 2026 | GAAP net income $1,140M; ongoing-operations adjusted EBITDA **$2,378M** (more than +50% y/y); FY26 EBITDA $7.1–7.5B (midpoint raised); 2027 EBITDA guide $7.7–8.5B; extra $1.5B buyback | EPS $2.94 (Nasdaq; EPS not in the release headline, so not compared) | UNRESOLVED |
| **ENB** | 8-K 2.02 (0001193125-26-450711), 2026-11-06T12:01:25 | Q3 2026 (C$) | GAAP EPS C$0.59; **adjusted EPS C$0.49**; adjusted EBITDA C$4.4B; DCF C$2.7B; FY26 guidance reaffirmed; US$2.6B Tallgrass crude acquisition | $0.36 (Nasdaq; probably USD, not comparable to C$) | UNRESOLVED |
| **UI** | 8-K 2.02 (0001511737-26-000076), 2026-11-06T12:10:12 | Q1 FY2027 (ended 2026-09-30) | Record revenue **$1,026.2M** (+40% y/y); GAAP EPS $5.29; non-GAAP EPS **$5.32**; $1.00 dividend | $3.82 (Nasdaq, 1 estimate) | Higher (Benzinga movers list, 2026-11-06; % UNRESOLVED) |
| **PPL** | 8-K 2.02 (0000922224-26-000050), 2026-11-06T12:51:16 | Q3 2026 | Ongoing EPS **$0.54** (GAAP $0.49); FY26 range narrowed to $1.92–1.96; long-term EPS growth raised to 7–9%; $25B 2027–30 capital plan; about 2 GW agreed for the QTS data center | $0.53 (Nasdaq) | UNRESOLVED |
| **BEN** | 8-K 2.02 (0000038777-26-000287), 2026-11-06T13:36:02 | Q4 FY2026 (quarter ended 2026-09-30) | GAAP diluted EPS $0.72; **adjusted EPS $0.94** | $0.78 (Nasdaq) | UNRESOLVED |
| **ELAN** | 8-K 2.02 (0001739104-26-000054), 2026-11-06T11:27:25 | Q3 2026 | Revenue $1.265B (+11%); adjusted EPS **$0.27**; FY26 guidance raised (revenue $5.155–5.18B, adjusted EPS $1.17–1.20) | $0.20 (Briefing.com and Nasdaq) | UNRESOLVED |
| **UAA** | 8-K 2.02 (0001336917-26-000160), 2026-11-06T12:40:34 | Q2 FY2027 (ended 2026-09-30) | Revenue $1.2B (−7%); diluted EPS $0.00; FY27 GAAP EPS guide revised to −$0.02 to +$0.02; adjusted EPS $0.08–0.12 unchanged; **Middle East conflict headwind about $45M** (was $35M) | −$0.01 (Nasdaq) | UNRESOLVED |
| BAM | 8-K 8.01 (0001171843-26-007210), 2026-11-06T12:17:15 | Q3 2026 | FRE $864M (+15%); DE $763M (+15%); $25B raised in Q3 | $0.44 (Nasdaq); per-share figure not extracted, so UNRESOLVED | — |

- Also filed in the window (not table-verified):
  - 11-06 8-K 2.02 filings: PAA (13:38Z), FLR (12:04Z), DK (11:31Z; Briefing has DK $13.55 vs $8.12), WULF (12:02Z).
  - TU 6-Ks (Q3 2026, 12:08Z).
  - BIP 6-K (Q3, 22:00Z; Briefing has $0.91 vs $0.90).
  - OKLO 10-Q (12:32Z; Benzinga says +15.3% intraday on a revenue beat).
- **Large 11-06 movers on prints from the 11-05 after-hours session** (the prior window's events; these are reactions only and the prints were not re-verified here):
  - Up: ABNB +8.7%, NET +11–18%, IONQ +9.8%, IREN +15.7%, TMDX +20%, JFrog up about 23% pre-market.
  - Down: TEAM −19%, DKNG −20%, AXON −9%, XRAY −14%, FIVN −17% pre-market.
  - LRCX +9% on a $25B buyback.
  - Sources: Benzinga / CNBC / ZeroHedge, 2026-11-06.

#### FDA
- FDA *Novel Drug Approvals 2026* page (curl of fda.gov, HTTP 200): latest entries are dated 10/20/2026. **No novel approval dated 11-05..11-08.**
- openFDA Drugs@FDA: no submission action dated 2026-11-05..11-09 ("No matches found").
- openFDA CRL transparency dataset: last updated 2026-08-13, so it cannot evidence CRLs in this window.
- **Verdict: no PDUFA or CRL outcome for a ≥$2B sponsor was confirmed on FDA's own pages. CRL status is UNRESOLVED** because the dataset lags.
- Moderna's release mentions FDA approval of mFLUSIVA. Its date is not on the novel-approvals page (it is likely a BLA/CBER action), so its timing is UNRESOLVED and it is **not treated as an in-window event**.

#### Upcoming, 11-09..11-13
- **CPI (October): Tue 11-10, 08:30 ET.** Consensus: headline +0.3% m/m, core +0.2% (CME Group, 2026-11-06; Reuters says "next Tuesday").
- PPI (October): Fri 11-13, 08:30 ET (ATFX calendar).
- UK Q3 GDP: Thu 11-12. China CPI/PPI: already released Mon 11-09.
- **Veterans Day, Wed 11-11:** bond market closed, stocks open.
- **Treasury quarterly refunding** (TheStreet Pro, 2026-11-07), all at 1:00pm ET: $58B 3-year Mon 11-09, $42B 10-year Tue 11-10, $25B 30-year Thu 11-12.
- **Fed speakers** (TheStreet Pro week-ahead):
  - Mon: Bowman, Goolsbee, Barkin
  - Tue: Bowman, Waller, Logan, Schmid, Paulson
  - Thu: Goolsbee, Hammack, Barr, Daly, Schmid, **Williams**
  - Fri: Collins, Bowman, Daly, Jefferson
- **Earnings ≥$2B** (Nasdaq calendar curl; pre = pre-market, AH = after-hours):
  - 11-09: KKR, CEG (pre), B (pre), OXY (AH), FERG, TTWO (AH), RKLB (AH), ROIV; 67 names in total. Note that The Trade Desk is cited by JournalArta but is not in the Nasdaq ≥$2B list (UNRESOLVED).
  - 11-10: PBR (AH), TDG (pre), SE (pre), ALC, VOD, **CRWV (AH)**, ONON; 34 names.
  - 11-11: FNV, GIB, ASND, CTVA; 24 names.
  - 11-12: **CSCO (AH), AMAT (AH)**, BN, NU, NBIS (pre); 39 names.
  - 11-13: MUFG, SMFG, MFG, KB; 10 names.
  - CME also names Berkshire Hathaway for next week, but it is not on the Nasdaq calendar (UNRESOLVED).
- Events: Trump meets the Qatari PM on 11-09, 17:00Z. Huang's House briefing on 11-18 falls after the week.

### 3. Large single-name moves — AI-significance screen, ROUTER-GATED MODE

- **Population.** US-listed common stocks, market cap ≥$2B, |close-to-close| ≥5% on 11-06 against 11-05 (B's frozen floor; no sub-floor write-ups in this mode).
- **Discovery.** The Nasdaq screener supplied symbols and caps only. Moves came from per-symbol Nasdaq `quote/info` closes dated Nov 6, 2026: **1971** names measured, **279** at ≥5% (`rail_tally`). A flat tape (discovery median −0.11%). 15 symbols had no dated close (named in `degraded_legs`).
- **Confirmation and identity.** Release times come only from one scripted EDGAR batch (385 requests, no failures), labels from the key-less earnings calendar. **67** names had an own-event filing in the reaction window and were measured on IBKR regular-session daily bars (`close` array, `outside_rth=false`) in two sequential batches of 34 and 33. **63 passed.** 4 fell below 5% on IBKR and are dropped: VCRE +3.90%, MP +4.95%, BEN +4.72%, WYNN +4.78%. No metered call.
- **Passed, largest moves:** KRMN +42.13%, FROG +35.33%, IRTC -30.70%, TMDX +27.92%, QNT +25.99%, IONQ +23.42%, DKNG -21.30%, IREN +20.02%, TILE -18.72%, AXON -18.18%, FIVN -17.63%, CGON +17.27% … (63 in all; each one is listed under RECOMMENDED ACTIONS). 48 of the 67 measured names carry an after-close 11-05 anchor, and 19 a pre-open 11-06 anchor.
- **Close-chain check.** 13 landed rows read (2026-10-20 → 11-05). **26 hits**, all names that the 11-05 row coded `POST_MOVE_EVENT` (filing after the 11-05 close) and that now pass on that after-close 11-05 anchor. Each is a legitimate forward chain, recorded in its `reason`. No intraday or pre-open anchor hit. This is not a clearance.
- **Noisy names** (≥3 other ≥5% sessions in the 10-day window; context for criteria 2 and 4): KRMN (4), FROG (3), QNT (5), IONQ (5), IREN (8), DIOD (5), WULF (8), GMED (3), COMP (3), ELVN (3), NET (4), AUGO (3), CLMT (3), VSAT (5), MSGR (5), AAOI (7), AKAM (4), DXPE (4), WSC (3), UAA (3), KTOS (4).
- **Rejected:** `rejected_notable` is empty. `rejected_compact` (216), closes on the discovery basis: 89 `ANCHOR_UNRESOLVED` (no own-event filing, or one that does not explain the move, e.g. FLY, OKLO, RGTI, ONDS, PPTA, XE, FRVO, RKLB, ACHR, EXTR, FORM, SMTC; OKLO +22.7% has only a 10-Q, LRCX a buyback 8-K), 125 `DAY2_EVENT_PRIOR`, 2 `POST_MOVE_EVENT` (ASTS, KLAC).
- **Deal-pinned:** none. The FIVN and AXON filings are the acquirer or investor side.
- **Durable row: NOT WRITTEN this run.** The generated, digest-checked split write (4 parts + call) is committed at `ops/spikes/d1-2026-11-08-single-name-screen-unlanded/`. Its issuing sub-agent staged part 1, then a provider safety filter stopped it while it was sending part 2, and the harness barred the orchestrator from taking over that work. In-run issue `research_screen_write_refused` filed; an interactive session lands it per RUNBOOK §57.

### 4. Sector-level moves (IBKR regular-session closes 11-05 → 11-06)

- **Surfaced (1 of 2 at |move| ≥ 1%; rail tally 2).** **XLK +1.45%** (162.38 → 164.74), conviction 45: a partial chip-led rebound one session after the 11-05 data-center rout (SMH +3.63%), retracing under a fifth of the prior −8.00% session. Relief inside a repriced trade, not a reversal.
- **Rejected notable:** XLP −1.28% (91.25 → 90.08), conviction 30: bond-proxy defensives lagged on the strong payrolls print and higher December hike odds. A rates rotation with no sector catalyst.
- **Not surfaced:** XLF −0.59%, XLB −0.73%, XLRE −0.68%, XLU −0.39%, XLV −0.06%, XLY −0.05%, XLE −0.02%, XLI +0.12%, XLC +0.43%.
- **Id check.** All 11 contract ids verified against the 11-05 row; none re-resolved.
- **Durable row:** `research-screen` `sector-move`, entry `cb1d002c-0efc-4ec5-a262-ea4ddf6fac69` (written by the 16:10 MT session).

### 5. Notable commentary

- **Fed:** Williams (11-06): "Inflation is absolutely too high"; time to "accumulate more information" (Reuters via Ausecure).
- **Sell-side on payrolls:** Lombard Odier's Ielpo said the report "all but seals the case for a December rate hike." SMBC Nikko said growth is "better than expected again" and the bond rally could reverse (TheStreet Pro, 2026-11-07).
- **AI and data centers:**
  - BofA reiterated Buy on NVDA with a $350 target (22x CY27E P/E).
  - Morgan Stanley said to buy SpaceX weakness, calling the selloff "driven (in part) by anti data center sentiment" (CNBC roundup via FourWeekMBA, 2026-11-06).
  - Barclays' Toublan: "a war of attrition: scarce power favors the biggest balance sheets" (CNBC via aibubblemonitor).
  - Goldman: Texas data-center risk is "timing rather than cancellations" (ZeroHedge, 2026-11-06).
  - Fundstrat's Tom Lee says AI doom is overdone and blames the "blue tsunami" shock (Benzinga, 2026-11-06).
  - BofA mapped three scenarios for chips (Investing.com headline, 2026-11-08; detail UNRESOLVED).
- **Oil:**
  - Rapidan's McNally puts an 80% chance on fighting resuming and sees Brent back above $100 (CNBC via NDTV Profit, 2026-11-08).
  - Range of forecasts: Goldman $90 for December, UBS $110 by year-end, Capital Economics $120 if the conflict broadens (discoveryalert, 2026-11-08).
- **Corporate:**
  - Huang's apology memo (11-08).
  - Charter CEO Winfrey's "new operating model" plus $2B cost cuts. TD Cowen said a Comcast/Charter tie-up "may need to occur sooner rather than later" (Deadline, 2026-11-06).
  - Moderna CEO Bancel on the raised outlook.
  - Under Armour cited Middle East conflict cost pressure.
  - JPMorgan downgraded Hannover Re and Munich Re; Morgan Stanley downgraded Equinor to Underweight (2026-11-06).

## ANALYSIS — RISK TO EXISTING POSITIONS

- **Union of book and view.** IBKR `get_account_positions` (read 05:2xZ 11-09) and `state.current_positions` agree on all 8 names and share counts (AMZN 0.3464, DIS 0.7244, GEV 0.1244, GOOGL 0.2577, ISRG 0.1091, RTX 0.1601, TSM 0.155, UBER 0.5156). IBKR also holds the VOO park (16.895 shares), which is not a strategy position. No reconciliation-lag position.
- **Exit triggers.** No tranche carries a `convergence_target` or `time_exit_date`. **No EXIT TRIGGERED.**
- **Kill-trigger sweep.**
  - **Strategy D.** `perf.kill_flags` (as of 11-06, already on the 11-06 closes): every flag FALSE (drawdown, runaway, m2m, evidence, interim warning); unit 1.0081 against peak 1.1065, drawdown **−8.89%**, far from the 50% kill. No session has closed since, so the refresh against live marks leaves it unchanged.
  - **Strategy B.** No open positions; `analytics.b_pairwise_correlation` reports 0 positions, so the correlation check is inert.
- **Thesis-invalidation sweep** (IBKR 11-06 closes; criteria from each tranche's `invalidation_status`):
  - **AMZN** 259.30. No AWS growth, margin, backlog or commitment datapoint in the window. **NO.**
  - **DIS** 116.75. FQ4 FY26 is confirmed for 11-17 and has **not occurred** (EVENT-IDENTITY GATE). **NO.**
  - **GEV** 774.11. Musk posted on 11-06 that SoftBank is "defaulting on their turbine orders." No evidence was given, neither SoftBank nor GE Vernova has confirmed, and GEV filed nothing on EDGAR in the window. SoftBank's 5-year CDS reached 466 bp. The criterion is organic orders growth below 15% for two quarters; an unconfirmed claim is not an orders reading. **NO** (watch item).
  - **GOOGL** 284.78. No structural-remedy ruling and no Cloud datapoint. **NO.**
  - **ISRG** 452.80. No company development. **NO.**
  - **RTX** 189.53. No FY27 procurement cut enacted or proposed. **NO.**
  - **TSM** 375.44 (+6.33% on the chip rebound). No hyperscaler or Nvidia order cut and no CoWoS utilization datapoint; October revenue is due 11-10. Texas and Georgia governors-elect pledged data-center pauses, and Goldman frames that as a timing risk rather than cancellations. **NO.**
  - **UBER** 68.59. No company development in the window. **NO.**
- **Not held, noted:** Nvidia CEO Jensen Huang admitted on 11-08 an affair with an executive US intelligence reportedly regards as a Chinese intelligence asset; the board opened an investigation, and a House briefing is set for 11-18. No NVDA 8-K. NVDA is not in the book.
- **Watchlist candidates:** B is gated, and no development changes the new-entry index beyond today's additions.

## ANALYSIS — OPPORTUNITY CHECK

- **A, D and E are GATED** under the ROUTER-GATED SCAN RULE, so nothing was evaluated for them.
- **B is GATED.** Its 63 ≥5% own-event names still reach the new-entry index as `watchlist` actions (item 3); no deal-pinned target, and no thesis handoff is routed. None is a held name.
- **C, HYBRID (FOMC-only carve-out).** No new FOMC-class candidate; the December 8–9 FOMC is already inside the 45-day window.

## ANALYSIS — ADD-CANDIDATE CHECK

- **Durable row:** `add-candidate-review`, entry `5ada3494-c056-412a-ad47-3d2f7e8462cf` (written by the 16:10 MT session). 12 evaluated, **0 flagged, 0 `declined_hard_gate`**, 12 `declined`.
- **Gate.** `invalidation_status` is populated and evaluable for all 12, and no criterion is breached.

|Tranche|Close 11-06|Mark vs cost|Trigger|Disposition|
|---|---|---|---|---|
|D:AMZN:2026-07-09|259.30|+7.48%|none|declined|
|D:AMZN:2026-07-30|259.30|−2.41%|none|declined|
|D:DIS:2026-05-07|116.75|+4.88%|none|declined|
|D:DIS:2026-08-05|116.75|+12.49%|none|declined|
|D:GEV:2026-08-03|774.11|−20.19%|dip-with-intact-thesis|declined (no funding path)|
|D:GOOGL:2026-07-09|284.78|−20.86%|dip-with-intact-thesis|declined (no funding path)|
|D:GOOGL:2026-07-26|284.78|−13.14%|dip-with-intact-thesis|declined (no funding path)|
|D:ISRG:2026-07-20|452.80|+29.55%|none|declined|
|D:RTX:2026-04-27|189.53|+7.14%|none|declined|
|D:TSM:2026-07-21|375.44|−12.25%|dip-with-intact-thesis|declined (no funding path)|
|D:TSM:2026-07-29|375.44|−4.44%|dip-with-intact-thesis|declined (no funding path)|
|D:UBER:2026-07-09|68.59|−6.31%|none|declined|

- **Price basis.** IBKR 11-06 regular-session closes over each tranche's own `cost_basis / shares`.
- **Why none is flagged.** D is DO-NOT-ACTIVATE and capital-disabled, so no add has a funding path.

## ANALYSIS — REGIME CHECK

The standing `shock_overlay` reads `latent` (live read this run): the Gulf/Hormuz structure is open, with the US blockade of Iranian ports in force.

**Qualifying shock event: PENDING (flagged).** On **2026-11-08** two dated escalations hit the named Gulf/Iran channel:
- Houthi missiles at Riyadh. Saudi forces intercepted two; debris damaged the Aramco Tower in KAFD (Saudi Energy Ministry: minor damage, no casualties, no production or export outage confirmed).
- A drone strike halted Iraq's Khor Mor gas field (domestic power supply; global supply impact limited).

They followed US "minor" strikes on Qeshm (11-06), the disabling of a blockade-runner and CENTCOM's Task Force Iron Gate extending the blockade to Iran's land borders (11-07). The event is not a relief move, and its oil leg is measured over a two-session window that has not closed (P = 11-06, BZUSD 98.32; S1 = 11-09, S2 = 11-10). The inclusion criterion sought is an oil move above $5/bbl attributable to the channel. No session has closed since the event, and Monday Asia crude traded about flat. Flagged as a `router_review` with the window PENDING, for D2 to verify and M1R to rule after S2 closes. The FX leg (dollar index +0.7% on payrolls, USD/JPY about 158.3) has no move above 2% attributable to the channel, and no sovereign-spread widening was found.

**Qualifying resolution event: NO.** No ceasefire, settlement or blockade lift took effect 11-06..11-08. Qatar's two-stage 48-hour plan was not accepted, and Iran is "reviewing" proposals. Brent's weekly fall of more than 16% was a market bet on diplomacy, not a resolution in force. Trump meets the Qatari prime minister on 11-09 at 17:00Z, outside this window.

**Measured triggers, for D2 to detect (not computed here).** VIX closed 25.64, still HIGH. SPY_TREND reads NEUTRAL (D2a). Breadth is 55.97, a fall of 10.16 points from 66.13 on 11-04. D2 item 4 reads D2a's step-1d/1e rows and this routine's breadth row.

## EQUITY-BREADTH OBSERVATION

- **Row written (16:10 MT session):** `events.regime_events` `TECHNICAL_INPUT` / `EQUITY_BREADTH_PCT`, as_of 2026-11-06, **55.97**.
- **Source.** Barchart `$S5TH` via `tavily_extract` (`?cb=20261108`), headed "Quote Overview for Fri, Nov 6th, 2026". Previous Close 58.56 equals the stored 11-05 value. EODData's end-of-day table row for 06 Nov reads C 55.97, read on a later New York calendar date, so the settled-table exemption applies. Barchart and EODData count as one source family: **single settled source**.
- **ChartRow** states "as of market close, Nov 6, 2026": 278 of 497 (55.94%). With no Nov 5 ChartRow count on record, the span 11-04 → 11-06 gives −10.19pp against `$S5TH` −10.16pp; `chartrow_dod_gap=0.03`. The weekly MacroMicro re-probe failed; Barchart remains primary.

## ANALYSIS — FRONTIER-LLM CAPABILITY CHECK

NO CAPTURE. The `hf://papers/daily/latest` listing (daily papers date 2026-11-09) was read: video and 3D generation, agent-harness evolution, streaming ASR, weight-space editing, agent cost hand-offs and a Terminal-Bench real-world agent paper. None bears on a documented `AI_Trading_Foundation.md` disadvantage.

## RECOMMENDED ACTIONS

- Watchlist: ADD KRMN to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, +42.13% (32.09 → 45.61), with 4 prior ≥5% sessions in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD FROG to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, +35.33% (74.62 → 100.98), with 3 prior ≥5% sessions in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD IRTC to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, -30.70% (130.19 → 90.22), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD TMDX to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, +27.92% (68.98 → 88.24), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD QNT to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, +25.99% (29.82 → 37.57), with 5 prior ≥5% sessions in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD IONQ to the Strategy B new-entry index — Earnings release (8-K Items 2.01, 2.02, 3.02, 7.01); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, +23.42% (26.43 → 32.62), with 5 prior ≥5% sessions in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD DKNG to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), pre-open release; reaction session 11-06, -21.30% (23.52 → 18.51), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-06.
- Watchlist: ADD IREN to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, +20.02% (18.03 → 21.64), with 8 prior ≥5% sessions in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD TILE to the Strategy B new-entry index — Earnings release (8-K Items 2.02, 7.01); Nasdaq earnings calendar lists 2026-11-06 (time-not-supplied), pre-open release; reaction session 11-06, -18.72% (37.82 → 30.74), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-06.
- Watchlist: ADD AXON to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, -18.18% (382.56 → 313.0), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD FIVN to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, -17.63% (34.14 → 28.12), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD CGON to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-06 (time-not-supplied), pre-open release; reaction session 11-06, +17.27% (64.8 → 75.99), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-06.
- Watchlist: ADD BKD to the Strategy B new-entry index — Earnings release (8-K Items 2.02, 7.01); Nasdaq earnings calendar lists 2026-11-06 (time-not-supplied), pre-open release; reaction session 11-06, -16.65% (10.81 → 9.01), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-06.
- Watchlist: ADD TEAM to the Strategy B new-entry index — Earnings release (8-K Items 2.02, 5.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, -16.15% (183.29 → 153.68), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD HALO to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, -15.72% (122.96 → 103.63), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD UI to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-06 (time-not-supplied), pre-open release; reaction session 11-06, +15.29% (514.2 → 592.84), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-06.
- Watchlist: ADD WK to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, -14.90% (85.5 → 72.76); qualifying_event_date 2026-11-05.
- Watchlist: ADD NTRA to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, -14.59% (363.76 → 310.67), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD LION to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, +13.38% (12.56 → 14.24), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD DIOD to the Strategy B new-entry index — Earnings release (8-K Items 2.02, 7.01); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, +13.17% (68.36 → 77.36), with 5 prior ≥5% sessions in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD WULF to the Strategy B new-entry index — Earnings release (8-K Items 2.02, 7.01); Nasdaq earnings calendar lists 2026-11-06 (time-not-supplied), pre-open release; reaction session 11-06, +12.80% (10.08 → 11.37), with 8 prior ≥5% sessions in the window; qualifying_event_date 2026-11-06.
- Watchlist: ADD GMED to the Strategy B new-entry index — Earnings release (8-K Items 2.02, 8.01); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, -12.76% (81.44 → 71.05), with 3 prior ≥5% sessions in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD NMIH to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, -11.84% (44.27 → 39.03); qualifying_event_date 2026-11-05.
- Watchlist: ADD PLUS to the Strategy B new-entry index — Earnings release (8-K Items 2.02, 5.02, 8.01); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, +11.74% (82.43 → 92.11), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD ABNB to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, +11.67% (170.13 → 189.99), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD CENX to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, +11.31% (30.07 → 33.47), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD STEP to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, +10.84% (42.81 → 47.45), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD COMP to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, +10.74% (9.22 → 10.21), with 3 prior ≥5% sessions in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD VST to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-06 (time-pre-market), pre-open release; reaction session 11-06, +10.55% (112.89 → 124.8), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-06.
- Watchlist: ADD ELVN to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, +10.36% (44.79 → 49.43), with 3 prior ≥5% sessions in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD MCHP to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, -10.02% (64.85 → 58.35), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD NET to the Strategy B new-entry index — Earnings release (8-K Items 2.02, 7.01); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, +9.91% (244.51 → 268.75), with 4 prior ≥5% sessions in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD ATMU to the Strategy B new-entry index — Earnings release (8-K Items 2.02, 8.01); Nasdaq earnings calendar lists 2026-11-06 (time-not-supplied), pre-open release; reaction session 11-06, +9.62% (46.16 → 50.6); qualifying_event_date 2026-11-06.
- Watchlist: ADD SARO to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, +9.21% (25.3 → 27.63), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD AUGO to the Strategy B new-entry index — Q3 2026 earnings release + financial statements (6-K); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, +9.19% (71.27 → 77.82), with 3 prior ≥5% sessions in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD AGM to the Strategy B new-entry index — Earnings release (8-K Items 2.02, 7.01); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, -8.98% (197.97 → 180.2); qualifying_event_date 2026-11-05.
- Watchlist: ADD ELAN to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-06 (time-not-supplied), pre-open release; reaction session 11-06, +8.70% (23.68 → 25.74), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-06.
- Watchlist: ADD CLMT to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-06 (time-not-supplied), pre-open release; reaction session 11-06, -8.56% (43.35 → 39.64), with 3 prior ≥5% sessions in the window; qualifying_event_date 2026-11-06.
- Watchlist: ADD FG to the Strategy B new-entry index — Earnings release (8-K Items 2.02, 7.01); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, +7.84% (21.68 → 23.38); qualifying_event_date 2026-11-05.
- Watchlist: ADD VSAT to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, +7.70% (59.38 → 63.95), with 5 prior ≥5% sessions in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD ESNT to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-06 (time-not-supplied), pre-open release; reaction session 11-06, -7.57% (68.6 → 63.41); qualifying_event_date 2026-11-06.
- Watchlist: ADD MSGR to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-06 (time-not-supplied), pre-open release; reaction session 11-06, +7.26% (224.5 → 240.8), with 5 prior ≥5% sessions in the window; qualifying_event_date 2026-11-06.
- Watchlist: ADD IAG to the Strategy B new-entry index — Q3 2026 results: MD&A + financial statements (6-K; results news release 6-K followed 23:12Z); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, +7.20% (17.5 → 18.76), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD COGT to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, +6.96% (29.58 → 31.64), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD AAOI to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, +6.91% (46.89 → 50.13), with 7 prior ≥5% sessions in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD AKAM to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, +6.74% (77.84 → 83.09), with 4 prior ≥5% sessions in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD CARG to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, -6.67% (36.15 → 33.74), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD STWD to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-06 (time-not-supplied), pre-open release; reaction session 11-06, -6.44% (12.88 → 12.05); qualifying_event_date 2026-11-06.
- Watchlist: ADD GRDN to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, +6.32% (39.87 → 42.39), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD XRAY to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, -6.24% (10.09 → 9.46), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD CHTR to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-06 (time-not-supplied), pre-open release; reaction session 11-06, -6.19% (125.86 → 118.07), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-06.
- Watchlist: ADD DXPE to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, +5.88% (132.87 → 140.68), with 4 prior ≥5% sessions in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD WSC to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, +5.72% (17.84 → 18.86), with 3 prior ≥5% sessions in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD CALY to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, +5.72% (15.92 → 16.83), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD CLDX to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, +5.66% (28.27 → 29.87), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD SKWD to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, -5.50% (63.86 → 60.35); qualifying_event_date 2026-11-05.
- Watchlist: ADD SBS to the Strategy B new-entry index — Q3 2026 earnings release (6-K); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, +5.48% (4.56 → 4.81), with 1 prior ≥5% session in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD HUM to the Strategy B new-entry index — Earnings release (8-K Items 2.02, 7.01); Nasdaq earnings calendar lists 2026-11-06 (time-not-supplied), pre-open release; reaction session 11-06, +5.33% (411.79 → 433.74); qualifying_event_date 2026-11-06.
- Watchlist: ADD MRNA to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-06 (time-not-supplied), pre-open release; reaction session 11-06, +5.27% (241.46 → 254.19), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-06.
- Watchlist: ADD TIGO to the Strategy B new-entry index — Q3 2026 earnings release + interim financial statements (6-K); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, +5.21% (79.12 → 83.24); qualifying_event_date 2026-11-05.
- Watchlist: ADD UAA to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-06 (time-not-supplied), pre-open release; reaction session 11-06, -5.21% (5.57 → 5.28), with 3 prior ≥5% sessions in the window; qualifying_event_date 2026-11-06.
- Watchlist: ADD KTOS to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close release; reaction session 11-06, +5.12% (33.39 → 35.1), with 4 prior ≥5% sessions in the window; qualifying_event_date 2026-11-05.
- Watchlist: ADD UA to the Strategy B new-entry index — Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-06 (time-not-supplied), pre-open release; reaction session 11-06, -5.04% (5.36 → 5.09), with 2 prior ≥5% sessions in the window; qualifying_event_date 2026-11-06.
- Router review: 2026-11-08 Gulf-channel escalation (Houthi missile strike on Riyadh damaging the Aramco Tower; drone strike halting Iraq's Khor Mor gas field), a candidate qualifying shock event under Strategy.md misclassification scenario 3 while `shock_overlay` reads `latent`. Inclusion criterion sought: an oil move above $5/bbl attributable to the channel, over the two-session window P 11-06 (BZUSD 98.32) → S1 11-09 / S2 11-10. Window PENDING: no session has closed since the event. For D2 to verify, refresh-only; M1R rules after S2.

```yaml d1_actions
- action: watchlist
  ticker: KRMN
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, +42.13% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: FROG
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, +35.33% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: IRTC
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, -30.70% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: TMDX
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, +27.92% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: QNT
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, +25.99% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: IONQ
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Items 2.01, 2.02, 3.02, 7.01); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, +23.42% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: DKNG
  strategy: B
  qualifying_event_date: 2026-11-06
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), pre-open, -21.30% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: IREN
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, +20.02% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: TILE
  strategy: B
  qualifying_event_date: 2026-11-06
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Items 2.02, 7.01); Nasdaq earnings calendar lists 2026-11-06 (time-not-supplied), pre-open, -18.72% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: AXON
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, -18.18% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: FIVN
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, -17.63% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: CGON
  strategy: B
  qualifying_event_date: 2026-11-06
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-06 (time-not-supplied), pre-open, +17.27% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: BKD
  strategy: B
  qualifying_event_date: 2026-11-06
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Items 2.02, 7.01); Nasdaq earnings calendar lists 2026-11-06 (time-not-supplied), pre-open, -16.65% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: TEAM
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Items 2.02, 5.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, -16.15% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: HALO
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, -15.72% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: UI
  strategy: B
  qualifying_event_date: 2026-11-06
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-06 (time-not-supplied), pre-open, +15.29% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: WK
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, -14.90% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: NTRA
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, -14.59% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: LION
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, +13.38% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: DIOD
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Items 2.02, 7.01); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, +13.17% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: WULF
  strategy: B
  qualifying_event_date: 2026-11-06
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Items 2.02, 7.01); Nasdaq earnings calendar lists 2026-11-06 (time-not-supplied), pre-open, +12.80% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: GMED
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Items 2.02, 8.01); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, -12.76% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: NMIH
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, -11.84% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: PLUS
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Items 2.02, 5.02, 8.01); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, +11.74% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: ABNB
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, +11.67% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: CENX
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, +11.31% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: STEP
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, +10.84% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: COMP
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, +10.74% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: VST
  strategy: B
  qualifying_event_date: 2026-11-06
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-06 (time-pre-market), pre-open, +10.55% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: ELVN
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, +10.36% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: MCHP
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, -10.02% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: NET
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Items 2.02, 7.01); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, +9.91% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: ATMU
  strategy: B
  qualifying_event_date: 2026-11-06
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Items 2.02, 8.01); Nasdaq earnings calendar lists 2026-11-06 (time-not-supplied), pre-open, +9.62% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: SARO
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, +9.21% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: AUGO
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Q3 2026 earnings release + financial statements (6-K); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, +9.19% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: AGM
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Items 2.02, 7.01); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, -8.98% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: ELAN
  strategy: B
  qualifying_event_date: 2026-11-06
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-06 (time-not-supplied), pre-open, +8.70% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: CLMT
  strategy: B
  qualifying_event_date: 2026-11-06
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-06 (time-not-supplied), pre-open, -8.56% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: FG
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Items 2.02, 7.01); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, +7.84% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: VSAT
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, +7.70% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: ESNT
  strategy: B
  qualifying_event_date: 2026-11-06
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-06 (time-not-supplied), pre-open, -7.57% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: MSGR
  strategy: B
  qualifying_event_date: 2026-11-06
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-06 (time-not-supplied), pre-open, +7.26% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: IAG
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Q3 2026 results: MD&A + financial statements (6-K; results news release 6-K followed 23:12Z); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, +7.20% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: COGT
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, +6.96% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: AAOI
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, +6.91% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: AKAM
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, +6.74% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: CARG
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, -6.67% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: STWD
  strategy: B
  qualifying_event_date: 2026-11-06
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-06 (time-not-supplied), pre-open, -6.44% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: GRDN
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, +6.32% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: XRAY
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, -6.24% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: CHTR
  strategy: B
  qualifying_event_date: 2026-11-06
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-06 (time-not-supplied), pre-open, -6.19% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: DXPE
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, +5.88% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: WSC
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, +5.72% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: CALY
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, +5.72% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: CLDX
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, +5.66% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: SKWD
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, -5.50% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: SBS
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Q3 2026 earnings release (6-K); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, +5.48% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: HUM
  strategy: B
  qualifying_event_date: 2026-11-06
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Items 2.02, 7.01); Nasdaq earnings calendar lists 2026-11-06 (time-not-supplied), pre-open, +5.33% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: MRNA
  strategy: B
  qualifying_event_date: 2026-11-06
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-06 (time-not-supplied), pre-open, +5.27% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: TIGO
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Q3 2026 earnings release + interim financial statements (6-K); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, +5.21% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: UAA
  strategy: B
  qualifying_event_date: 2026-11-06
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-06 (time-not-supplied), pre-open, -5.21% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: KTOS
  strategy: B
  qualifying_event_date: 2026-11-05
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-05 (time-not-supplied), after-close, +5.12% on IBKR 11-05 → 11-06
- action: watchlist
  ticker: UA
  strategy: B
  qualifying_event_date: 2026-11-06
  source_research_screen_id: UNLANDED (ops/spikes/d1-2026-11-08-single-name-screen-unlanded)
  detail: ADD to the Strategy B new-entry index (B DO-NOT-ACTIVATE, index only); Earnings release (8-K Item 2.02); Nasdaq earnings calendar lists 2026-11-06 (time-not-supplied), pre-open, -5.04% on IBKR 11-05 → 11-06
- action: router_review
  ticker: n/a
  strategy: n/a
  qualifying_event_date: n/a
  source_research_screen_id: n/a
  detail: geopolitical qualifying shock candidate dated 2026-11-08 (Houthi strike on Riyadh/Aramco Tower + Khor Mor drone strike, Gulf/Iran channel); criterion oil > $5/bbl over P 11-06 (BZUSD 98.32) -> S1 11-09 / S2 11-10, window PENDING, closed-session moves none
```

2026-W42

# Weekly Catalyst Calendar — Strategies A and C

**Run date 2026-10-18** (Sunday, `weekly_sun`). ISO week of TODAY's run date, 2026-W42. The upcoming trading week opens Monday 2026-10-19; that is context, not the marker.

**Windows.** Strategy A: 6 months, **2026-10-18 → 2027-04-18** — **effective confirmed-earnings horizon 2026-12-18 (61 days, ~8.7 weeks); sparse vendor coverage beyond it, per-name (E) fallback for shortlisted names.** Strategy C: 45 days, **2026-10-18 → 2026-12-02**.

**EFFECTIVE CONFIRMED-EARNINGS HORIZON: 2026-12-18, 61 days (~8.7 weeks) from 2026-10-18. The terminal date did NOT move for a third week** (CCL 2026-12-18). Depth fell 68 → 61 days only because the clock advanced. Seven-week series, terminal date / days from that week's run date: 2026-12-03/88d (09-06), 2026-12-09/87d (09-13), 2026-12-09/80d (09-20), 2026-12-10/74d (09-27), 2026-12-18/75d (10-04), 2026-12-18/68d (10-11), **2026-12-18/61d (10-18)**.

Coverage shape (MEASURED, six chunked FMP calls, each ≤ 60 days):

| Span | Rows | Notes |
|---|---|---|
| Printed 10-12 → 10-17 | 8 | with actuals |
| 10-18 → 11-01 | 37 | |
| 11-02 → 11-30 | 24 | |
| 12-01 → 12-31 | 5 | |
| 2027-01-01 → 02-28 | 14 | **the tail grew:** C, JPM, WFC 01-14; BAC 01-15; JNJ, UNH 01-20; GS, TSM 01-21 are new |
| 2027-03-01 → 04-18 | 1 | |

Dead zones: 2026-11-25 → 12-02 and 2026-12-19 → 2027-01-10. This is a standing plan-tier constraint (`FMP-earn-horizon`, `OWNER_ACTIONS.md`), deliberately NOT re-alerted.

**Every count in PART 1 is a FLOOR.** Universe enumeration is impossible on this plan tier: `search/search-company-screener`, every `directory.*` route and `quote/batch-quote` are tool-level ACCESS DENIED. PART 1A is built from three sources:
- the 81 forward vendor rows returned by the chunked calls;
- the 44-row live A queue;
- the carried 57-name PART 2A candidate set.

The plan-tier gate is not re-alerted (`ops.alerts` `6c4004e3`, standing).

**This cycle's changes:**
- **Gate.** The gate holds at 2026-11-02 for a sixth cycle, but now as a fail-open LOWER BOUND. Gulf/Hormuz incidents on 10-13, 10-14 and 10-15 (D1) would, if M1a/M1R rule them qualifying, keep the quiet clock open past the 11-02 scoring and move A's gate to 2026-12-01. 21 currently-surviving candidates sit in that band (PART 2A, STEP 1 and the "Provisional" list).
- **Provenance.** Eight more earnings dates became company-issued (C): META (moved −7 days to 10-21), MSFT 10-28, AMZN 10-29, XOM 10-30 (the 10-23 claim is refuted), CAT 10-29, V 10-27, FSLR 10-29, and DDOG (11-04, moved −1 day).
- **Prints struck.** The bank and health-care prints of 10-13 → 10-15 (JPM, C, GS, WFC, JNJ, UNH, BAC), TSM 10-15 and TRV 10-16.
- **FDX is re-admitted.** FedEx moved to a calendar fiscal year effective 2026-06-01 (SEC 8-K, search excerpt). That removes the fiscal-arithmetic basis on which W1 had rejected the 10-28 and 2027-02-02 rows for five cycles.

---

## PART 1A — Strategy A universe, 6-month window (2026-10-18 → 2027-04-18)

No interpretation in this PART. Provenance tags:
- **(C)** company- or primary-source confirmed
- **(E)** estimated (vendor or aggregator projection)
- **(T)** tentative, no firm day
- **(2S)** two-source tracker agreement

"Δ" marks a change against the 2026-10-11 artifact. Baseline (C) rows marked "carried" were NOT re-read this run.

### 1A.1 — Earnings, inside the 45-day C window (2026-10-18 → 2026-12-02)

| Ticker | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| GE | GE Aerospace | Earnings (BMO) | 2026-10-20 | **(C)** | geaerospace.com (carried); FMP agrees |
| GM | General Motors | Earnings | 2026-10-20 | (E) | FMP |
| NFLX | Netflix | Earnings | 2026-10-20 | **(C)** | Netflix release 2026-09-14 (carried); FMP agrees |
| UAL | United Airlines | Earnings (AMC; call 10-21) | 2026-10-20 | **(C)** | United release (carried); FMP agrees |
| META | Meta Platforms | Earnings (AMC, call 13:30 PT / 16:30 ET) | **2026-10-21** | **(C)** | investor.atmeta.com "Meta to Announce Third Quarter 2026 Results" (also finviz copy), search excerpt; FMP agrees. **Δ -7d, E→C** (baseline 10-28 E) |
| CB | Chubb | Earnings call | 2026-10-21 | (C) | issuer-confirmed per M2 `50d589a2` (carried) |
| IBM | IBM | Earnings (call 17:00 ET) | 2026-10-21 | **(C)** | newsroom.ibm.com 2026-10-07 (carried); FMP silent |
| T | AT&T | Earnings | 2026-10-21 | (E) | FMP |
| TSLA | Tesla | Earnings (AMC) | 2026-10-21 | **(C)** | ir.tesla.com (carried); FMP agrees |
| AAL | American Airlines | Earnings | 2026-10-22 | **(C)** | news.aa.com (carried); FMP agrees |
| LMT | Lockheed Martin | Earnings | 2026-10-22 | (E) | FMP |
| NOK | Nokia | Earnings | 2026-10-22 | (E) | FMP — A-INELIGIBLE, ADR |
| VZ | Verizon | Earnings | 2026-10-26 | (E) | FMP |
| V | Visa (FQ4) | Earnings (AMC, webcast 14:00 PT) | 2026-10-27 | **(C)** | investor.visa.com "Visa to Announce Fiscal Fourth Quarter and Full-Year 2026 Financial Results on October 27, 2026" (search excerpt); FMP agrees. **Δ E→C** |
| BA · HCA · HOOD · KO · PYPL · SOFI | — | Earnings | 2026-10-27 | (E) | FMP |
| F · GOOGL · MGM | Ford · Alphabet · MGM | Earnings | 2026-10-28 | (E) | FMP. GOOGL: no company notice found (search 10-18; days.to "not confirmed", 10-28 4:30 PM ET est). Alphabet's 2025 notice lead ~2-3 wk |
| MSFT | Microsoft (FQ1 FY27) | Earnings (AMC, webcast 14:30 PT / 17:30 ET) | 2026-10-28 | **(C)** | Microsoft release dated 2026-10-07 (PRNewswire dateline "Oct. 7, 2026"), read via finviz copy (WebFetch). **Δ E→C** |
| ETSY | Etsy | Earnings | 2026-10-28 | (E) | FMP. **Δ -7d** (baseline 11-04) |
| GEV | GE Vernova | Earnings (BMO) | 2026-10-28 | **(C)** | gevernova.com (carried); FMP silent |
| NOW | ServiceNow | Earnings (AMC, call 14:00 PT) | 2026-10-28 | **(C)** | newsroom.servicenow.com 2026-10-07 (carried) |
| FDX | FedEx | Earnings | 2026-10-28 Δ | (E) | FMP bulk; MarketBeat claims company-confirmed with a 5:30 PM ET call (not read at FedEx IR). **RE-ADMITTED this cycle (orchestrator ruling):** the five-cycle rejection rested on a 31 May fiscal year-end, which FedEx's SEC 8-K (search excerpt) says moved to 31 December effective 2026-06-01. See 1A.9 item 14. |
| AMZN | Amazon | Earnings (call 14:00 PT / 17:00 ET) | 2026-10-29 | **(C)** | aboutamazon.com "Amazon will share its Q3 2026 earnings on October 29" (search excerpt); FMP agrees. **Δ E→C** |
| CAT | Caterpillar | Earnings (release 05:30 CDT; call 07:30 CDT) | 2026-10-29 | **(C)** | caterpillar.com "Caterpillar to announce 3Q 2026 financial results on Oct 29" (also finviz copy; search excerpt). **Δ E→C** (baseline: TradingKey single source) |
| FSLR | First Solar | Earnings (AMC) | 2026-10-29 | **(C)** | "First Solar, Inc. to Announce Third Quarter 2026 Financial Results on October 29, 2026" (Business Wire copy at offshoresource.com, search excerpt); FMP agrees. **Δ E→C** |
| INTC* · RBLX* · SBUX · CARR · COIN · RIOT · RIVN · RKT · SIRI | — | Earnings | 2026-10-29 | (E) unless marked | FMP. *INTC **(C)** intc.com 2026-10-06; *RBLX **(C)** ir.roblox.com (both carried). CARR **Δ +2d** vs baseline 10-27 (carried from last run's note; FMP 10-29) |
| LLY | Eli Lilly | Earnings | 2026-10-29 | **(C)** | investor.lilly.com (carried); FMP silent |
| MRK | Merck | Earnings | 2026-10-29 | **(C)** | merck.com (carried); FMP silent |
| ABBV | AbbVie | Earnings (BMO) | 2026-10-30 | **(C)** | AbbVie release 2026-10-01 (carried); FMP agrees |
| CVX | Chevron | Earnings call (11:00 ET) | 2026-10-30 | **(C)** | Chevron advisory (carried); FMP agrees |
| XOM | ExxonMobil | Earnings (release 05:30 CT; call 08:30 CT) | 2026-10-30 | **(C)** | investor.exxonmobil.com "ExxonMobil to Release Third Quarter 2026 Financial Results" (Business Wire; search excerpt); FMP agrees. **Δ E→C**; the one-tracker 10-23 claim is refuted |
| AAPL | Apple | Earnings (AMC, call 17:00 ET) | 2026-11-02 | **(C)** | Apple IR notice via MacTrast relay (carried); FMP agrees |
| PLTR | Palantir | Earnings | 2026-11-02 | (E) | FMP + Benzinga. No company release found (search 10-18); therighttrader.com says "company has announced" but uncorroborated, days.to says unconfirmed. 2025 notice came 10-13 for 11-03. AJ Bell 11-03 not reproduced this run |
| VRTX | Vertex | Earnings (AMC, call 16:30 ET) | 2026-11-02 | **(C)** | Vertex release 2026-10-07 (carried) |
| FUBO | fuboTV | Earnings | 2026-11-02 | (E) | FMP — A-INELIGIBLE |
| AMD | AMD | Earnings (AMC, call 17:00 ET) | 2026-11-03 | **(C)** | ir.amd.com 2026-10-06 (carried); FMP agrees |
| ET · PINS · PFE · SHOP | — | Earnings | 2026-11-03 | (E) | FMP |
| SMCI | Super Micro | Earnings | 2026-11-03 | (E) | aggregator (carried; days.to "not confirmed"); no company notice found; absent from FMP |
| DDOG | Datadog | Earnings (BMO, call 08:00 ET) | **2026-11-04** | **(C)** | "Datadog announces date of third quarter fiscal year 2026 earnings call" (finviz copy of company release, search excerpt). **Δ -1d, E→C** (baseline 11-05 E) |
| UBER | Uber | Earnings | 2026-11-04 | (E) | FMP. No company notice found; Bullstory (uncited) says 11-02 BMO, same as last week's tracker |
| SNAP | Snap | Earnings | 2026-11-04 | (E) | FMP |
| AKAM | Akamai | Earnings (call 16:30 ET) | 2026-11-05 | **(C)** | Akamai release 2026-10-08 (carried) |
| TTWO | Take-Two (FQ2) | Earnings | 2026-11-05 | (E) | aggregator (carried); no company notice surfaced (search 10-18). 2025 notice came 10-09 |
| ROKU | Roku | Earnings | 2026-11-05 | (E) | FMP |
| SONY | Sony | Earnings | 2026-11-05 | (E) | FMP — A-INELIGIBLE, ADR. **Δ -5d** (baseline 11-10) |
| MRNA | Moderna | Earnings | 2026-11-06 | (E) | FMP. **Δ +1d** (baseline 11-05) |
| LCID | Lucid | Earnings | 2026-11-09 | (E) | FMP — A-INELIGIBLE |
| CSCO | Cisco | Earnings | 2026-11-11 | (E) | FMP; one calendar 11-10; TheStreet week-of-11-16 calendar lists 11-18 (TBD). No company notice found |
| QCOM | Qualcomm (FQ4) | Earnings (AMC) | 2026-11-11 | (E) | aggregator (carried); no FQ4 notice surfaced (search returned only the FQ3 July notice, "Qualcomm Schedules Third Quarter Fiscal 2026..." 2026-07-15) |
| NBIS | Nebius | Earnings (BMO, 08:00 ET) | 2026-11-11 | (E) | Earnings Whispers + AJ Bell; one calendar says 11-10; no company notice found |
| AMAT | Applied Materials | Earnings (AMC) | 2026-11-12 | (E) | aggregator (carried); not individually re-searched |
| BILI | Bilibili | Earnings | 2026-11-12 | (E) | FMP — A-INELIGIBLE, ADR |
| PANW | Palo Alto Networks | Earnings (FQ1 FY27) | 11-12 or 11-18 | (T) | Unusual Whales (10-06) says 11-18; baseline aggregators 11-12/11-18; no notice (2025 notice came 11-04). Unchanged |
| BIDU | Baidu | Earnings | 2026-11-17 | (E) | FMP — A-INELIGIBLE |
| DIS | Disney | Earnings | 2026-11-17 | (E) | FMP. **Δ +5d** (baseline 11-12) |
| HD | Home Depot | Earnings (BMO) | 2026-11-17 | (E) | aggregators; Benzinga/therighttrader say scheduled, Wall Street Horizon "UNCONFIRMED"; no company release found |
| NVDA | NVIDIA | Earnings | 2026-11-18 | (E) | FMP; one aggregator 11-17; no notice found |
| TGT | Target | Earnings | 2026-11-18 | **(C)** | corporate.target.com (carried); FMP agrees |
| WMT | Walmart | Earnings | 2026-11-19 | **(C)** | corporate.walmart.com (carried); FMP agrees |
| ZM | Zoom | Earnings | 2026-11-23 | (E) | FMP |
| DELL | Dell Technologies | Earnings | 2026-11-24 | (E) | aggregator (carried); therighttrader "not confirmed" |
| BABA · NIO | — | Earnings | 2026-11-24 | (E) | FMP — A-INELIGIBLE, ADR |
| CRWD | CrowdStrike (AMC) | Earnings | 2026-12-01 | (E) | days.to / therighttrader projection, "not confirmed" (search 10-18); not in FMP |
| NTAP | NetApp | Earnings | 2026-12-01 | (E) | aggregator (carried); nothing new found |
| OKTA | Okta (AMC) | Earnings | 12-01 or 12-02 | (E) | aggregators conflict by a day (carried); nothing new found |
| SNOW | Snowflake | Earnings | 2026-12-02 | (E) | aggregator (carried); nothing new found |

Zero vendor rows between 2026-11-25 and 2026-11-30 other than ZM/DELL/BABA/NIO above; FMP chunk 2026-11-02..11-30 = 24 rows, last row NIO/BABA 11-24, then DOCU 12-03.

### 1A.2 — Earnings, 2026-12-03 → dense horizon 2026-12-18

| Ticker | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| DOCU | DocuSign | Earnings | 2026-12-03 | (E) | FMP |
| HPE | Hewlett Packard Enterprise | Earnings (AMC) | 2026-12-03 | (E) | aggregator (carried); no notice found |
| ADBE | Adobe | Earnings | 2026-12-09 | (E) | FMP |
| AVGO | Broadcom (FQ4) | Earnings (AMC) | 2026-12-09 | (E) | aggregator (carried); not in FMP; no notice found |
| COST | Costco | Earnings | 2026-12-10 | (E) | FMP |
| ORCL | Oracle (FQ2) | Earnings | 2026-12-10 | (E) | calendar sites (carried); not re-searched this run |
| NKE | Nike (FQ2) | Earnings | 2026-12-17 | (E) | FMP |
| CCL | Carnival (Q4) | Earnings | 2026-12-18 | (E) | FMP — terminal row of the dense horizon |

(Unchanged from baseline; DOCU through CCL identical to FMP 12-01..12-31 chunk of 5 rows plus aggregator rows.)

### 1A.3 — Earnings, 2026-12-19 → 2027-04-18

Coverage gap, not absence of events: FMP returns nothing 2026-12-19 → 2027-01-10 and nothing after 2027-03-25.

| Ticker | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| MU | Micron (FQ1) | Earnings | 2026-12-23 | (E) | aggregator (carried); not in FMP; not re-searched |
| TLRY | Tilray | Earnings | 2027-01-11 | (E) | FMP tail — A-INELIGIBLE |
| DAL | Delta (Q4) | Earnings | 2027-01-12 | (E) | FMP tail |
| C · JPM · WFC | Citigroup · JPMorgan · Wells Fargo | Q4 earnings | 2027-01-14 | (E) | FMP tail. **New** |
| BAC | Bank of America | Q4 earnings | 2027-01-15 | (E) | FMP tail. **New** |
| JNJ · UNH | J&J · UnitedHealth | Q4 earnings | 2027-01-20 | (E) | FMP tail. **New** |
| GS · TSM | Goldman Sachs · TSMC | Q4 earnings | 2027-01-21 | (E) | FMP tail. **New** (TSM A-INELIGIBLE, ADR) |
| META | Meta | Q4 earnings | ~2027-01-27 | (E) | days.to projection, "not yet confirmed" (search). **New**, single aggregator |
| MRK | Merck | Q4 call | 2027-02-02 | (C) | merck.com (carried) |
| PEP | PepsiCo (Q4) | Earnings | 2027-02-02 | (E) | FMP tail |
| TSLA | Tesla | Earnings | 2027-02-03 | (E) | FMP tail |
| NVDA | NVIDIA (FQ4 FY27) | Earnings | ~2027-02-24 | (E) | days.to / Wall Street Horizon inferred; MarketScreener 02-23. **New**, unconfirmed |
| RIVN | Rivian | Earnings | 2027-02-25 | (E) | FMP tail |
| AVGO | Broadcom (FQ1 FY27) | Earnings | ~2027-03-03 | (E) | days.to projection, "not confirmed". **New** |
| ORCL | Oracle (FQ3 FY27) | Earnings | ~2027-03-10 | (E) | days.to projection. **New** |
| MU | Micron (FQ2 FY27) | Earnings | ~2027-03-17 | (E) | days.to + Wall Street Horizon "INFERRED". **New** |
| FDX | FedEx | Earnings | 2027-03-25 | (T) Δ | FMP tail. **Now the SUSPECT row:** under a calendar fiscal year no quarter ends in time for a late-March print. It is kept as (T) and is not relied on. See 1A.9 item 14. |
| FDX | FedEx | Earnings | 2027-02-02 Δ | (E) | FMP tail; RE-ADMITTED (orchestrator ruling). It fits a calendar-quarter schedule (the transition period ends 12-31). See 1A.9 item 14. |

Undated Q4/Q1 names: CRM, MRVL, INTU (see 1A.10). All other A-queue names not listed above have NO sourced date after their next print: AAPL, MSFT, GOOGL, AMZN (late Jan / early Feb 2027 by pattern only — search found only prior-year dates), CRWD, NTAP, OKTA, SNOW, HPE, DELL, TGT, WMT, HD, ADBE, COST, AMAT, CSCO, QCOM, SMCI, NBIS, DDOG, TTWO, PANW, XOM, CVX, CAT, GE, GEV, LLY, VRTX, AMD, AKAM, INTC, IBM, NOW, PLTR, UBER = **NOT ESTABLISHED** (no reachable source states a date). MRK Q1 2027-04-29 (C) is outside the 04-18 edge.

### 1A.4 — Product launches, keynotes, developer events

| Ticker/Event | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| NVDA | NVIDIA | GTC Berlin (keynote 10-21) | 2026-10-20 → 10-22 | (C) | carried from W41 (NVIDIA GTC FAQ); not re-verified this run |
| ORCL | Oracle | **Δ renamed "Oracle AI World"** (was CloudWorld), Las Vegas, The Venetian | 2026-10-25 → 10-28 (majority of listings); CMSWire/VKTR/RelationshipOne say 10-26 → 10-29 | (E) **Δ downgraded from (C)** | third-party event listings only; date conflict unresolved; Oracle site not fetched |
| ADBE | Adobe | Adobe MAX | 2026-11-10 → 11-12 | (E) | carried |
| MSFT | Microsoft | Ignite (San Francisco) | 2026-11-17 → 11-20 | (E) **Δ downgraded from (C)** | third-party calendar; one listing says 11-17 → 11-24 (less reliable); Microsoft page not fetched |
| TTWO | Take-Two | GTA VI launch (preload 11-12 carried) | 2026-11-19 | (C) | reaffirmed on 2026-08-07 earnings call per press/boerse-express; no Sept/Oct update found |
| AMZN | Amazon | AWS re:Invent (Las Vegas) | 2026-11-30 → 12-04 | (E) **Δ downgraded from (C)** | two third-party listings agree; AWS page not fetched |
| NVDA | NVIDIA | GTC Washington DC | 2026-11-30 → 12-03 | (E) | conflict: one listing cites NVIDIA event page for these dates; another tracker says no 2026 DC edition announced. Unresolved |
| GOOGL | Alphabet | Waymo multi-city robotaxi launches | 2026 (year only) | (T) | carried |
| — | broad | CES 2027 | 2027-01-06 → 01-09 | (E) | carried |
| NVDA | NVIDIA | GTC 2027 San Jose | 2027-03-15 → 03-18 | (C) | carried |

### 1A.5 — Analyst and investor days

| Ticker/Event | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| MRK | Merck | Investor event at ESMO (webcast) | 2026-10-26 | (C) carried, **not re-verified** | search for it returned nothing this run |
| ENTG | Entegris | Investor Day, New York (webcast) | 2026-11-09 | (C) | **NEW**, company release via 01net copy; cap not measured |
| EPAC | Enerpac Tool Group | Investor Day at NYSE | 2026-11-04 | (C) | **NEW**, company release PDF 2026-07-27; cap not measured (likely near $2B floor) |
| MH | McGraw Hill | Investor Day, New York | 2026-11-18 | (E) | **NEW**, briefglance summary only; listing/cap not verified |
| NTR | Nutrien | Investor Day, Toronto (1:00pm ET) | 2026-11-30 | (C) | **NEW**, company release (BNN Bloomberg wire, 2026-09-23); NYSE/TSX dual listed |
| NTNX | Nutanix | Investor Day 2026 | undated | (T) | **NEW**, Akros listing, no date |
| NKE | Nike | Investor day "Fall 2026" | — | (T) | carried, no day |
| UNH | UnitedHealth | Investor conference | ~2026-12 early | (E) | carried |
| JPM | JPMorganChase | Investor Day | 2027-02-22 | (C) | carried |

Not US-listed (excluded): Norsk Hydro 2026-11-25 (Oslo), Alpha Bank 2026-11-05 (Athens). Searched with no 2026 announcement found: CRM, MU, CRWD, INTC, PANW, QCOM, CSCO, DELL, HPE (one combined search; a floor, not proof of absence). No December-2026 investor-day announcements surfaced.

### 1A.6 — Regulatory, legal, trade and macro

PDUFA rows mirrored in 1B.3. Macro dates marked (C) were read from bls.gov schedule pages this run.

| Ticker/Event | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| — | broad | GDP advance estimate, Q3 2026 | 2026-10-29 | (E) | BEA schedule per search snippet; BEA page carries "lapse in appropriations, not being updated" notice, so dates could slip |
| — | broad | **FOMC decision** | **2026-10-28** | (C) | federalreserve.gov fetched 2026-10-18 (Oct 27-28, no SEP) |
| GSK | GSK | Bepirovirsen PDUFA (chronic hep B), ADR | 2026-10-26 | (E) | carried; Assyro "Upcoming" |
| INO | Inovio | INO-3107 BLA PDUFA (RRP) | 2026-10-30 | (E) | Assyro "Upcoming"; baseline (C) not re-read, so held at (E) |
| AGIO | Agios | Mitapivat sNDA PDUFA, sickle cell disease (priority review) | 2026-11-01 (Sunday) | **(C) Δ upgraded** | Agios press release 2026-07-07 via BioSpace/HCPLive snippets (goal date 11-01; sNDA submitted 05-12) |
| — | OPEC+ (7 members: SA, RU, IQ, KW, KZ, DZ, OM) | Monthly meeting; 10-04 meeting held output flat for November | **2026-11-01** | (C) | opec.org press release 2026-10-04 |
| — | broad | US midterm elections | 2026-11-03 | (C) | statutory |
| — | broad | PCE / personal income & outlays, Sept | 2026-11-04 | (E) | BEA schedule via search snippet (same caveat as GDP) |
| — | broad | Employment Situation (Oct) | 2026-11-06 | (C) | bls.gov |
| — | broad | CPI (Oct) | 2026-11-10 | (C) | bls.gov |
| — | broad | USTR Sec 301 exclusions expire | 2026-11-10 | (C) | carried, not re-verified |
| BTAI | BioXcel | IGALMI at-home sNDA PDUFA | 2026-11-14 | (E) | Assyro; baseline (2S) |
| CYTK | Cytokinetics | Aficamten (MYQORZO) oHCM NDA PDUFA | 2026-11-14 | (E) | Assyro |
| SMMT | Summit | Ivonescimab + chemo BLA PDUFA | 2026-11-14 | (E) | Assyro (single source; W40 read it as a filing date; Assyro Nov page lists it as BLA) |
| Beren | Beren Therapeutics | Adrabetadex NDA PDUFA | 2026-11-17 | (E) | Assyro; not listed |
| UNP·NSC | Union Pacific / Norfolk Southern | STB comments due | 2026-11-18 | (C) | carried |
| CAPR | Capricor | Deramiocel BLA PDUFA (extended from 08-22; major amendment) | 2026-11-22 | (C) | Capricor 8-K 2026-08-24 (sec.gov) |
| SVRA | Savara | Molgramostim BLA PDUFA (review extended from 08-22 per Regards of Wall Street) | 2026-11-22 | (E) | Assyro + Checkrare; baseline (2S) |
| — | broad | PCE (Oct) | ~2026-11-25 | (E) | single source (financecalendar.com), unconfirmed |
| SAN | Sanofi (ADR) | Venglustat NDA PDUFA, type 3 Gaucher (priority review) | 2026-11-25 | (C) | Sanofi priority-review release 2026-05-28 per search snippet |
| BBIO | BridgeBio | BBP-418 NDA PDUFA (LGMD2I/R9) | 2026-11-27 | (E) | Assyro |
| NUVL | Nuvalent | Neladalkib NDA PDUFA | 2026-11-27 | (E) | Assyro |
| ZYD | Zydus (not US-listed) | Saroglitazar NDA PDUFA | 2026-11-27 | (E) | Assyro |
| PYPD | PolyPid | D-PLEX100 NDA PDUFA (priority review) | 2026-11-28 | (C) | PolyPid 8-K per search; cap likely < $2B |
| VRTX | Vertex | Povetacicept BLA PDUFA | 2026-11-30 | (E) | Assyro; baseline (C), not re-read |
| RHHBY | Roche (ADR) | Giredestrant (adjuvant) NDA PDUFA | 2026-11-30 | (E) | Assyro |
| COGT | Cogent | **Δ RESOLVED**: bezuclastinib + sunitinib (GIST, priority review) PDUFA 2026-11-30; bezuclastinib NonAdvSM PDUFA 2026-12-30; AdvSM 2027-06-29 | see left | (C) for 11-30 and 12-30 | Cogent acceptance releases (BioSpace/Barchart/investors.cogentbio.com snippets); Assyro Nov and Dec pages list the two separately. Baseline "conflict" was two different applications |
| EXEL | Exelixis | Zanzalintinib + atezolizumab mCRC PDUFA **Δ confirmed**: original 12-03 extended to 2027-03-03 (major amendment, notice 2026-09-10) | 2027-03-03 | (C) | OncLive/TargetedOnc/CancerNetwork 2026-09-11/14 citing Exelixis. Baseline row stands. |
| UNP·NSC | Union Pacific / Norfolk Southern | DOJ/USDOT comments | 2026-12-03 | (C) | carried |
| FSLR | First Solar + solar | Sec 232 tariff regime effective | 2026-12-04 | (C) | carried, not re-verified |
| — | broad | Employment Situation (Nov) | 2026-12-04 | (C) | bls.gov |
| VRTX | Vertex | Journavx sNDA PDUFA | 2026-12-05 | (2S) | carried |
| — | broad | **FOMC decision** | **2026-12-09** (SEP) | (C) | federalreserve.gov 2026-10-18 |
| — | broad | CPI (Nov) | 2026-12-10 | (C) | bls.gov |
| — | broad | US government funding: CR runs to 12-11 | 2026-12-11 | (E) | carried |
| VNDA·ANAB | Vanda / AnaptysBio | Imsidolimab BLA PDUFA | 2026-12-12 | (E) | **NEW**, Assyro Dec page (outside C window) |
| CORT | Corcept | Relacorilant NDA PDUFA | 2026-12-17 | (E) | **NEW**, Assyro |
| — | Deciphera (Ono sub; not listed) | Tirabrutinib NDA PDUFA | 2026-12-18 | (E) | **NEW**, Assyro |
| RHHBY | Roche (ADR) | Giredestrant + everolimus NDA PDUFA | 2026-12-18 | (E) | **NEW**, Assyro |
| — | Camurus (not US-listed) | Oclaiz NDA PDUFA | 2026-12-18 | (E) | **NEW**, Assyro |
| — | Hansa (not US-listed) | Imlifidase BLA PDUFA | 2026-12-19 | (E) | **NEW**, Assyro |
| MLYS | Mineralys | Lorundrostat NDA PDUFA | 2026-12-22 | (E) | **NEW**, Assyro |
| ACLX·GILD | Arcellx / Gilead | Anito-cel BLA PDUFA | 2026-12-23 | (E) | **NEW**, Assyro |
| VTRS | Viatris | MR-107A-02 (fast-acting meloxicam) NDA PDUFA | 2026-12-27 | (E) | **NEW**, Assyro |
| PRAX | Praxis | Relutrigine PDUFA (extended from 09-27; major amendment) | 2026-12-27 | (C) | Praxis 8-K 2026-06-29 per search |
| — | Saol (not listed) | SL1009 NDA PDUFA | 2026-12-30 | (E) | **NEW**, Assyro |
| BA | Boeing | FAA 737 MAX 10 certification "by year-end 2026" | — | (T) | carried |
| — | broad | Employment Situation (Dec) | 2027-01-08 | (C) | bls.gov |
| — | broad | CPI (Dec) | 2027-01-13 | (C) | bls.gov |
| DYN | Dyne | Z-rostudirsen BLA PDUFA (priority) | 2027-01-21 | (C) | carried; confirmed by 8-K copy |
| — | broad | **FOMC decision** | 2027-01-27 | (C) | federalreserve.gov (2027 tentative) |
| PHAR | Pharming | Joenja lower-dose sNDA PDUFA | 2027-01-30 | (C) | carried; Assyro shows 2026-10-24 "Decided" (stale/other application, unresolved) |
| V | Visa | **Δ DOJ debit case: fact discovery deadline moved from Oct 2026 to 2027-01-29**; no trial date (likely 2028) | 2027-01-29 | (E) | Payments Dive (undated articles) citing Magistrate Judge Cave; baseline 10-16 row struck |
| — | broad | Employment Situation (Jan) / CPI (Jan) | 2027-02-05 / 2027-02-11 | (C) | bls.gov |
| UNP·NSC | Union Pacific / Norfolk Southern | STB responses due | 2027-02-16 | (C) | carried |
| BMRN | BioMarin | VOXZOGO full approval | 2027-02-28 | (C) | carried |
| SRPT | Sarepta | AMONDYS 45 / VYONDYS 53 sNDAs | 2027-02-28 | (C) | carried |
| LYV | Live Nation | DOJ/states remedies phase | ~2027-02 | (E) | carried |
| WBD | Warner Bros Discovery | Antitrust trial begins | 2027-03-02 | (C) | carried |
| EXEL | Exelixis | Zanzalintinib PDUFA | 2027-03-03 | (C) | see above |
| — | broad | Employment Situation (Feb) / CPI (Feb) | 2027-03-05 / 2027-03-10 | (C) | bls.gov |
| — | broad | **FOMC decision** | 2027-03-17 (SEP) | (C) | federalreserve.gov (tentative) |
| — | broad | Employment Situation (Mar) / CPI (Mar) | 2027-04-02 / 2027-04-13 | (C) | bls.gov |
| HRMY | Harmony Biosciences | Pitolisant GR PDUFA | 2027-04-01 | (E) | **NEW**, search snippet via simianx (event label ambiguous: "extended") |
| — | broad | **FOMC decision** | 2027-04-28 (outside window, 04-18) | (C) | named only |

Policy/Gulf context (not re-adjudicated): OPEC+ 11-01 is the only dated Gulf-policy row found. No dated Hormuz/Gulf policy events (sanctions deadlines, IEA meetings) were surfaced. FTC v. Amazon trial ~2027-03-29 (E, carried, beyond data-row window).

### 1A.7 — Restructuring, M&A and structural

Carried unchanged (not re-verified): PCRX/Viatris $36.50 (announced 10-08, close undated); PTC/Schneider $205 (10-05); OPCH CD&R/McKesson $32.05 (10-06); ON·SYNA (10-01); UBER/ezCater $2.3B (10-06); CMG·SBUX FT rumour (T); ORCL WSJ OpenAI financing report (T); CVX·HESM restructuring (10-07); WDAY take-private report (T, unverified); VRTX Crinetics (closed 09-01); CAT Fabick close (late Oct, T); SWKS·QRVO; KMB·KVUE (outside date 11-02 → 2027-05-03); TECK; CTVA Vylor spin (Q4); Nasdaq-100 recon mid-Dec (E); S&P Q4 rebalance 12-18 (E); DG CEO transition 2027-01-01; BA controller; S&P Q1 rebalance 2027-03-19 (E).

| Ticker/Event | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| IONQ·Elisity | IonQ / Elisity | Acquisition/deal | 2026-10-12 | (C) announce | **NEW**, D1 `f5a0c793`/`394b6b39`/`982a5f26` (via orchestrator state_context); terms not re-searched |
| CCC | CCC Intelligent Solutions | Take-private report | 2026-10-12 | (T) | **NEW**, D1 report; unconfirmed |
| IONQ | IonQ | $2B offering | 2026-10-14 | (C) | **NEW**, D1 `c75cac94`/`ab91c8e7` |
| T·VZ·TMUS | SpaceX / Grain | 800MHz spectrum deal (TMUS/T/VZ down, towers up) | 2026-10-09 | (C) | **NEW**, D1 `bba9dd7a`/`c69c1a3d` |
| CRWV | CoreWeave | Debt repricing | 2026-10-14 | (C) | **NEW**, D1 |
| CIFR | Cipher | Converts | 2026-10-13 | (C) | **NEW**, D1 `c4156ada` |
| DELL·HPE·NTAP | Dell / HPE / NetApp | Barclays downgrades (DELL -11.27, HPE -8.28, NTAP -7.03) | 2026-10-14 | (C) | **NEW**, D1; analyst actions, recorded as context not catalysts |
| FRMI·AMD | Fermi / AMD | AMD credit support | 2026-10-13 | (C) | **NEW**, D1 `c4156ada` |

### 1A.8 — Universe rails (carried, dated)

**Market-cap rail (≥ $2B).** CARRIED FORWARD from two earlier measurements, not re-measured this run:
- **2026-10-04:** 61 names (the 44-row A queue plus 17 candidate/tier names). 0 FAIL. Smallest are AAL $8.57B (4.3× the floor), AKAM $15.84B and FSLR $18.77B.
- **2026-10-09:** 50 vendor-calendar names via `company/batch-market-cap`. 0 FAIL. Smallest is RIOT $6.39B (3.2×).

That data is now 9–14 days old. The week's largest drawdowns among A names were AMD (−13% on the week to 528.75) and the Barclays-downgraded DELL, HPE and NTAP (−7% to −11% on 10-14). All sit at caps many multiples of $2B, so a two-week carry cannot flip a verdict. **New vendor names this cycle:** the eight January tail rows are all large caps already measured (C, JPM, WFC, BAC, JNJ, UNH, GS; TSM is ADR-ineligible). **FAIL the cap floor, A-ineligible (carried):** TLRY, LCID, FUBO. **ADR rail (carried):** TSM, NOK, SONY, BILI, BIDU, BABA and NIO are A-ineligible.

### 1A.9 — Rows struck, rejected or corrected this cycle (earnings and non-earnings)

**Earnings.**

**Printed 2026-10-12 → 2026-10-17 (struck from forward tables; actual vs estimate):**
1. ~~JPM~~ PRINTED 2026-10-13: EPS 5.75 vs 5.93 est; revenue $50.17B vs $51.23B (FMP). Next 2027-01-14 (E, FMP).
2. ~~UNH~~ PRINTED 2026-10-13: EPS 4.69 vs 4.14; revenue $112.7B vs $111.3B (FMP). Next 2027-01-20 (E).
3. ~~WFC~~ PRINTED 2026-10-13: EPS 1.87 vs 1.85; revenue $21.87B vs $22.30B (FMP). Next 2027-01-14 (E).
4. ~~C~~ PRINTED 2026-10-13: EPS 2.85 vs 2.66; revenue $23.85B vs $23.74B (FMP). Next 2027-01-14 (E).
5. ~~GS~~ PRINTED 2026-10-13: EPS 17.01 vs 12.86; revenue $18.68B vs $16.83B (FMP). Next 2027-01-21 (E).
6. ~~JNJ~~ PRINTED 2026-10-13: EPS 2.59 vs 2.52; revenue $25.40B vs $25.38B (FMP). Next 2027-01-20 (E).
7. ~~BAC~~ PRINTED 2026-10-14: EPS 1.08 vs 1.10; revenue $30.00B vs $30.58B (FMP). Next 2027-01-15 (E).
8. ~~TSM~~ PRINTED 2026-10-15: EPS 4.60 vs 4.45; revenue $46.06B vs $45.67B (FMP). A-INELIGIBLE (ADR). Next 2027-01-21 (E).
9. ~~TRV~~ PRINTED 2026-10-16 (baseline (C) row): core income/share $9.18 (net $9.04), revenue ~$12.4B, core income ~$1.95B (Travelers 8-K / 10-Q per search; no consensus figure obtained; one outlet cites revenue est $11.40B, unverified). FMP has no TRV row. Next print: NOT ESTABLISHED.
(No other baseline row dated 10-12..10-17 existed. ABT, MS, PGR, BLK, PNC, USB and ASML were NOT in the baseline and are not tracked.)

**Moved or corrected (Δ):**
10. **META 10-28 (E) → 2026-10-21 (C)**, -7d; company release, FMP agrees (still pre-gate).
11. **MSFT 10-28 (E) → (C)**; **AMZN 10-29 (E) → (C)**; **XOM 10-30 (E) → (C)** (the 10-23 tracker claim refuted); **CAT 10-29 (E) → (C)**; **V 10-27 (E) → (C)**; **FSLR 10-29 (E) → (C)**. All dates unchanged, tags upgraded.
12. **DDOG 11-05 (E) → 2026-11-04 (C)**, -1d (still post-gate).
13. FMP-driven shifts: **DIS 11-12 → 11-17** (+5d), **ETSY 11-04 → 10-28** (-7d), **SONY 11-10 → 11-05**, **MRNA 11-05 → 11-06**, **CARR 10-27 → 10-29** (carried note).
14. **FDX — the five-cycle rejection premise is now contradicted by a primary-source filing.** SEC 8-K (Item 5.03 originally 2025; recast Item 2.02 filed 2026-07-21; FedEx Freight spin-off completed 2026-06-01) shows FedEx moved its fiscal year-end from May 31 to December 31 effective 2026-06-01, with a seven-month transition period Jun 1 – Dec 31, 2026 and calendar-year reporting from FY ending 2027-12-31 (search excerpts of sec.gov and secondary coverage; filings not fetched). Under calendar quarters, a late-October print (Q3 CY2026) and an early-February print (Q4/transition period) are no longer arithmetically impossible. MarketBeat (2026-03-19 page) states FedEx "confirmed" 10-28 with a 5:30 PM ET call; TipRanks lists 10-28 as an estimate; no investors.fedex.com notice was reached (the news page fetched returned navigation only). **Orchestrator ruling (2026-10-18):** a reasoned rejection must not outlive its reason. 10-28 and 2027-02-02 are RE-ADMITTED as (E). 2027-03-25 becomes the suspect (T) row, because a calendar fiscal year has no quarter that ends in time for it. FedEx IR is still unread, so nothing is (C). FDX is not on the A queue or in PART 2A, so no rank depends on it.
15. **Not changed / no company notice found:** GOOGL 10-28, PLTR 11-02, UBER 11-04, TTWO 11-05, CSCO 11-11, QCOM 11-11, SMCI 11-03, NBIS 11-11, PANW (T), HD 11-17, NVDA 11-18, DELL 11-24, CRWD 12-01, HPE 12-03, AVGO 12-09 (all stay (E)/(T)).

**Non-earnings.**

Continues numbering from the 2026-10-11 file (last = 22).

23. ~~CPI (Sept) 2026-10-14~~ — RELEASED: hot, 3.7% y/y (D1 `c75cac94`). Tag upgrade moot.
24. ~~PPI 2026-10-15~~ (not a baseline row) — RELEASED: hot, +6.3% y/y (D1 `3e90f4a0`). Retail sales (10-15) beat; 10Y -10bp (D1).
25. ~~AMAT Investor Day / Investor Breakfast at SEMICON West 2026-10-13~~ — HELD: D1: no WFE forecast, AMAT -6.69%. Third-party slide page (not AMAT's) reports CY2030 targets (>2pt WFE share gain, >$12B services revenue, ~54% non-GAAP GM, ~40% non-GAAP op margin); unverified against AMAT IR.
26. ~~WDAY Financial Analyst Day 2026-10-13~~ — HELD (Workday release 2026-09-01: 2:00pm PT, Las Vegas, Workday Rising). Outcome not found; WDAY is not an A-queue name.
27. ~~BGC FMX Investor Day 2026-10-13~~ — status UNVERIFIED (one search returned nothing). Struck as PAST by date only, no outcome.
28. ~~ACN Accenture Investor Day 2026-10-14~~ (not a baseline row) — HELD: 3-year plan (mid-single-digit revenue growth FY27/28, 10-30bp/yr margin, $5.5B FY27 buybacks); stock +1.7% intraday per Bloomberg via TIKR, premarket +3.7-4% faded. Not on A queue.
29. ~~RHHBY Enspryng thyroid eye disease PDUFA 2026-10-15~~ — **APPROVED 2026-10-16** (roche.com med-cor-2026-10-16; Healio, PharmExec 10-16 per search snippets). First at-home subcutaneous TED therapy. ADR, not C-eligible.
30. ~~VTRS/Opus MR-141 presbyopia PDUFA 2026-10-17 (Saturday)~~ — outcome NOT found (searches return only acceptance news); Assyro shows "Overdue". Treat as undecided/unreported; re-check next cycle.
31. ~~V Visa DOJ fact discovery closes 2026-10-16~~ — **CORRECTED**: deadline moved to 2027-01-29 (Judge Cave); trial likely 2028 (Payments Dive, undated). Row moved to 1A.6.
32. ~~MRK/Eisai WELIREG + LENVIMA sNDAs PDUFA 2026-10-04~~ — **APPROVED 2026-09-25** (Merck release; early action). Not a baseline row; Assyro Oct page also lists it, stale. Note for completeness only.
33. **COGT Cogent bezuclastinib 11-30 vs 12-30 conflict RESOLVED** — two separate NDAs (GIST+sunitinib 11-30, priority; NonAdvSM 12-30). Both (C).
34. **AGIO mitapivat 11-01 (E) → (C)** (Agios press release 07-07, priority review).
35. **ORCL "CloudWorld" renamed "Oracle AI World"**; date conflict 10-25→28 vs 10-26→29; tag (C) → (E).
36. **MSFT Ignite, AMZN re:Invent (C) → (E)**: only third-party calendars retrieved this run (dates agree with baseline).
37. **EXEL zanzalintinib** one aggregator shows 12-03 (original PDUFA); superseded by extension to 2027-03-03. Baseline correct.
38. **PHAR Joenja 2026-10-24** Assyro still "Decided"; baseline treated 2027-01-30 sNDA as live. Unchanged.
39. **Not re-verified (gate-relevant, before/near 11-02)**: MRK ESMO event 10-26, CAT Fabick close, INO 10-30, GSK 10-26, NVDA GTC Berlin 10-20→22, FSLR Sec 232 12-04, USTR 11-10.

### 1A.10 — Names with NO firm forward earnings date

**Newly (C) this run:** META (10-21), MSFT (10-28), AMZN (10-29), XOM (10-30), CAT (10-29), V (10-27), FSLR (10-29), DDOG (11-04).

**STILL NO FIRM DATE (A queue / shortlist):**
- **CRM** — no FQ3 FY27 notice (search found only the FY26 Q3 notice, 2025-12-03 earnings); early December INFERRED; Salesforce usually issues timing in early November.
- **INTU** — no notice; date announced at quarter end; late November INFERRED.
- **MRVL** — Q3 FY26 was 2025-12-02; FQ3 FY27 notice absent; early December INFERRED.
- **NBIS** — (E) 11-11 (Earnings Whispers, AJ Bell; another calendar 11-10), no company notice.

**Dated (E) but company notice not yet found (checked 2026-10-18):** GOOGL, PLTR, UBER, TTWO, CSCO, QCOM, SMCI, PANW (T), DELL, HD, NVDA, AMAT, ORCL, AVGO, CRWD, SNOW, NTAP, OKTA, HPE, MU (Dec). ORCL, AMAT, MU, SNOW, NTAP, OKTA, HPE were covered only by the grouped CRWD-family search or not at all (see caveat).

### 1A.11 — Liquidity rail (30-day ADV ≥ $10M), carried

CARRIED FORWARD from the 2026-10-04 measurement (IBKR regular-session daily bars, window 2026-08-21 → 2026-10-02). 61 of 61 cleared; the lowest was VRTX at $222.0M (~22× the floor). **Not re-measured this run.** The measurement is 14 days old, every name cleared by ≥ 22×, and this week's sell-off RAISED traded value rather than thinning it. The vendor-only names in 1A.8's 2026-10-09 table remain UNMEASURED for ADV. A ≥ $10M ADV is INFERRED for them, not measured. Measure on demand if any is promoted to the shortlist.

---

## PART 1B — Strategy C universe, 45-day window (2026-10-18 → 2026-12-02)

C qualifying types only: earnings (company IR), FDA PDUFA, FOMC. No interpretation.

### 1B.1 — FOMC

| Event | Meeting | Decision date | In C window (10-18 → 12-02) | Tag | Source |
|---|---|---|---|---|---|
| FOMC | 2026-10-27 → 10-28 (no SEP) | **2026-10-28** | **YES** | (C) | federalreserve.gov/monetarypolicy/fomccalendars.htm, fetched 2026-10-18; 2026 dates all confirmed, none tentative |
| FOMC | 2026-12-08 → 12-09 (**SEP**) | 2026-12-09 | **NO** — 7 days after 12-02 | (C) | same fetch |
| FOMC | 2027-01-26 → 01-27 (no SEP) | 2027-01-27 | No (A window) | (C), page: 2027 tentative | same |
| FOMC | 2027-03-16 → 03-17 (SEP) | 2027-03-17 | No (A window) | (C) tentative | same |
| FOMC | 2027-04-27 → 04-28 (no SEP) | 2027-04-28 | No (A window ends 04-18) | (C) tentative | same |

**Only the 2026-10-28 meeting falls inside the C window.** Other 2026 meetings after it: 12-09 only. No other FOMC meeting in 10-18 → 12-02.

### 1B.2 — Earnings inside the C window: company-IR-confirmed subset

Window 2026-10-18 → 2026-12-02. Struck: JPM, UNH, WFC, BAC, TRV (printed). "NEW" = upgraded/read this run (search excerpt of company release; not first-party page fetched except MSFT via finviz copy).

| Date | Ticker | Confirmation |
|---|---|---|
| 2026-10-20 | GE | geaerospace.com (carried) |
| 2026-10-20 | NFLX | Netflix release (carried) |
| 2026-10-20 | UAL | United release (carried) |
| 2026-10-21 | META | **NEW** investor.atmeta.com release (date moved from 10-28 E) |
| 2026-10-21 | CB | issuer-confirmed per M2 `50d589a2` (carried) |
| 2026-10-21 | IBM | newsroom.ibm.com 2026-10-07 (carried) |
| 2026-10-21 | TSLA | ir.tesla.com (carried) |
| 2026-10-22 | AAL | news.aa.com (carried) |
| 2026-10-27 | V | **NEW** investor.visa.com |
| 2026-10-28 | MSFT | **NEW** Microsoft release 2026-10-07 (read via finviz copy) |
| 2026-10-28 | GEV | gevernova.com (carried) |
| 2026-10-28 | NOW | newsroom.servicenow.com 2026-10-07 (carried) |
| 2026-10-29 | AMZN | **NEW** aboutamazon.com |
| 2026-10-29 | CAT | **NEW** caterpillar.com release |
| 2026-10-29 | FSLR | **NEW** First Solar release (Business Wire copy) |
| 2026-10-29 | INTC | intc.com 2026-10-06 (carried) |
| 2026-10-29 | LLY | investor.lilly.com (carried) |
| 2026-10-29 | MRK | merck.com (carried) |
| 2026-10-29 | RBLX | ir.roblox.com (carried; not on A queue) |
| 2026-10-30 | ABBV | AbbVie release 2026-10-01 (carried) |
| 2026-10-30 | CVX | Chevron advisory (carried) |
| 2026-10-30 | XOM | **NEW** investor.exxonmobil.com release |
| 2026-11-02 | AAPL | Apple IR notice via MacTrast relay (carried; secondary copy) |
| 2026-11-02 | VRTX | Vertex release 2026-10-07 (carried) |
| 2026-11-03 | AMD | ir.amd.com 2026-10-06 (carried) |
| 2026-11-04 | DDOG | **NEW** Datadog release (finviz copy), moved from 11-05 E |
| 2026-11-05 | AKAM | Akamai release 2026-10-08 (carried) |
| 2026-11-18 | TGT | corporate.target.com (carried) |
| 2026-11-19 | WMT | corporate.walmart.com (carried) |

Not yet IR-confirmed (checked 2026-10-18): GOOGL, PLTR, UBER, SMCI, TTWO, CSCO, QCOM, NBIS, NVDA, DIS, HD, DELL, PANW, CRWD, HPE, SNOW, OKTA, NTAP, AMAT. CAT, MSFT, META, AMZN, XOM, FSLR, V, DDOG have left this list.

### 1B.3 — FDA PDUFA dates in window (2026-10-18 → 2026-12-02)

Cap/ADV not measured here. "Instrument" = US-listed non-ADR.

| Date | Ticker | Drug / indication | Tag | C-eligible | Note |
|---|---|---|---|---|---|
| ~~2026-10-15~~ | ~~RHHBY~~ | Enspryng / TED | — | — | **APPROVED 10-16; struck (1A.9 #29)** |
| ~~2026-10-17~~ | ~~VTRS~~ | MR-141 / presbyopia | — | — | decision not found; struck as PAST by date (#30), re-check |
| 2026-10-24 | PHAR | Joenja | "Decided" per Assyro | — | stale/other application |
| 2026-10-26 | GSK | Bepirovirsen / chronic hep B | (E) | NO — ADR | Upcoming |
| 2026-10-29 | Sun Pharma | ILUMYA (BLA) | (E) | NO — not US-listed | Upcoming |
| 2026-10-30 | INO | INO-3107 (BLA) / RRP | (E) | instrument yes; cap likely small | Upcoming |
| 2026-11-01 | AGIO | Mitapivat sNDA / sickle cell, priority review | (C) Δ | instrument yes | a Sunday |
| 2026-11-14 | BTAI | IGALMI at-home | (E) | micro-cap | |
| 2026-11-14 | CYTK | Aficamten / oHCM | (E) | instrument yes | |
| 2026-11-14 | SMMT | Ivonescimab + chemo BLA | (E) | instrument yes; low confidence | |
| 2026-11-17 | Beren | Adrabetadex | (E) | NO — not listed | |
| 2026-11-22 | CAPR | Deramiocel / DMD | (C) | instrument yes | extended from 08-22 |
| 2026-11-22 | SVRA | Molgramostim / aPAP | (E) | instrument yes | |
| 2026-11-25 | SAN | Venglustat / type 3 Gaucher | (C) | NO — ADR | |
| 2026-11-27 | BBIO | BBP-418 / LGMD2I/R9 | (E) | instrument yes | |
| 2026-11-27 | NUVL | Neladalkib | (E) | instrument yes | |
| 2026-11-27 | Zydus | Saroglitazar | (E) | NO — not US-listed | |
| 2026-11-28 | PYPD | D-PLEX100 / SSI | (C) | instrument yes; cap likely < $2B | priority review |
| 2026-11-30 | VRTX | Povetacicept BLA | (E) | instrument yes | large cap |
| 2026-11-30 | RHHBY | Giredestrant (adjuvant) | (E) | NO — ADR | |
| 2026-11-30 | COGT | Bezuclastinib + sunitinib / GIST, priority review | (C) Δ | instrument yes | resolved |

No PDUFA dates found for MRK or LLY in the C window (MRK Welireg+Lenvima approved 09-25; MRK ifinatamab BLA withdrawn, stays struck; LLY orforglipron: one unconfirmed page says approved 2026-04-01 as Foundayo under a priority voucher, treat as unverified; no LLY date in window). No new large-cap (≥$2B) PDUFA surfaced beyond the VRTX, CYTK, BBIO, NUVL, SMMT, AGIO, INO-class names already carried; search coverage of big pharma was thin (two broad queries). Out of C window, named: COGT NonAdvSM 12-30, PRAX 12-27, Exelixis 2027-03-03, Dyne 2027-01-21, plus the Dec list in 1A.6 (12-12 → 12-30). Floor, not census.

---

## PART 2A — Strategy A ranked shortlist

W4 reads this PART verbatim and enqueues thesis-construction entries for the ranked shortlist; D2 runs them. Rankings and date specifics are therefore explicit. Every candidate row ends with its fixed-format `GATE:` literal (W4 copies it verbatim into the A-queue row; `ops.alerts` `559ee98c` is RESOLVED).

### The A-queue census — the PINNED query, run verbatim

```sql
SELECT * FROM state.open_queue WHERE strategy = 'A'
```

**It returns 44 rows** (MEASURED by the orchestrator this run), reconciled ticker by ticker to that count: AAPL, ADBE, AKAM, AMAT, AMD, AMZN, AVGO, CAT, CRM, CRWD, CSCO, CVX, DDOG, DELL, FSLR, GEV, GOOGL, HD, HPE, IBM, INTC, INTU, JPM, LLY, META, MRK, MRVL, MSFT, MU, NBIS, NOW, NTAP, NVDA, OKTA, ORCL, PANW, QCOM, SMCI, SNOW, TGT, TTWO, VRTX, WMT, XOM. **Identical set to 2026-10-11; zero new Strategy A ticker rows.** `Watchlist.md`'s extra row remains **TSM** (ADR, deliberately kept for its reasoning, correctly absent from the live queue). **The query wins** over any hand enumeration. `ops.alerts` `559ee98c` (W1 STEP 3b fixed-format GATE literal) is **RESOLVED**: W4 copies the literal on each row below verbatim; nothing further is owed by W1 on that item.

**Contract-identity flag carried for whoever constructs the XOM thesis.** IBKR resolves XOM to "ExxonMobil Holdings Corp", NYSE, conid **895178251** (the plain legacy listing is no longer returned); any order craft must resolve the contract fresh. Not re-read this run.

### STEP 1 — the GATE DATE, re-derived from scratch, with the arithmetic shown

**DERIVED GATE DATE = 2026-11-02 — the provable LOWER BOUND, applied fail-open.** Sixth consecutive cycle at this date, but for the first time it is not the most likely reachable re-score: on the measured evidence 2026-12-01 probably is (see the quiet-clock leg). Re-derived from live reads this run, not carried.

**Router state read first.** A's `STRATEGY_ACTIVATION` reads **DO-NOT-ACTIVATE** (`state.current_regime`, event `3883e492`, as_of 2026-10-02, M4 carry-forward, NO FLIP); no A router event has landed since. M1b's raw call for A is DO-NOT-ACTIVATE on its own reasoning, and A's growth/policy override is DISARMED. **The technical leg flipped this week:** equity breadth read **51.88 on 2026-10-15 → HEALTHY** (it was WEAK 48.31 on 10-14 and 46.7 at last cycle's read). So the M1R conjunct that failed on breadth last cycle now passes. A is DO-NOT-ACTIVATE and not ACTIVATE, so CATALYST-GATE MODE is live, not inert.

**PRICE leg** (MEASURED, `state.rerisking_limb_status`, `as_of_denver` 2026-10-18): `shock_overlay_state` **acute** since 2026-08-01 · `brent_baseline` **84.73** (43 obs, 2026-06-01..07-31) · `brent_peak` **108.75** · `brent_current` **105.92** as of **2026-10-15** · `brent_retrace_trigger` **96.74** = (84.73 + 108.75)/2, reproduced · `leg_b_basis` **not_retraced** · `leg_b_price_leg` **FALSE** · `sql_limbs_fired` **FALSE**.
- On the view's own stored, mixed-contract basis, the required fall is (96.74 − 105.92)/105.92 = **−8.67%** (last cycle −7.23% at 104.28). Retracement is (108.75 − 105.92)/24.02 = **11.8%** (last cycle 18.6%). **The leg moved further from clearing for the third straight cycle.** D1 has Brent ~−1.7% on 10-15 to ~104.3 (secondary, no settle), which the view's 105.92 does not yet reflect. Even on that figure the leg needs about −7.2%.
- Like-for-like is NOT re-derived. The November contract has expired, so no live spread exists. Last cycle's INFERRED band (a like-for-like retracement of ≈0%) is not carried as a number. The Dec→Jan roll (~10-29) lands two sessions before the 11-02 scoring and will flatter the stored figure.

**QUIET-CLOCK leg — 15 trading days clear of the most recent qualifying shock-cluster member.**
- **New events, all dated and reused from D1** (Daily.md 2026-10-15; sector screen `982a5f26`):
  - 10-12: Houthi strike on Riyadh airport (Brent +1.8% to ~106.65).
  - 10-13: the container ship GFS Pride sank.
  - 10-14: the cargo ship Cape Dao sank; Houthi strikes on Aramco HQ Dhahran and on Riyadh airport.
  - 10-15: a tanker caught fire in the Gulf of Oman; Kpler shows Hormuz flow at about one-tenth of the prior week's.
- **Arithmetic** (counting `state.market_calendar` sessions; Oct 17-18, 24-25 and 31 and Nov 1 are non-trading):
  - Anchor 10-12 clears on **11-02**: 10-13(1) 10-14 10-15 10-16 10-19(5) 10-20 10-21 10-22 10-23 10-26(10) 10-27 10-28 10-29 10-30 11-02(15).
  - Anchor 10-13 clears **11-03**.
  - Anchor 10-14 clears **11-04**.
  - Anchor 10-15 clears **11-05**.
- **So if ANY of the 10-13, 10-14 or 10-15 events qualifies, the quiet clock cannot clear by the 11-02 scoring.** The price leg is also far from clearing, so acute would hold through 11-02. The universal acute override would then make 11-02 unreachable for A, and the gate would step to **2026-12-01**.
- The 09-23, 09-28..10-04 and 10-08 anchors from prior cycles are all superseded by these later dates.

**Why 11-02 and not 12-01.** Whether the 10-13..10-15 events qualify is M1a's or M1R's adjudication, not W1's (`strategy/09`: a qualifying event needs a category-4 measurable leg AND a named channel). The Kpler collapse in Hormuz flow is a trade-flow measurement attributable to a named channel, so qualification is LIKELY, but it is not ruled. This run does not rule it. Instead it applies the spec's FAIL-OPEN direction, "ambiguity resolves toward more research":
- **11-02 is a provable lower bound.** No resolution of the qualification question can make any re-score before 11-02 reachable.
- **A name marked SPENT-BY-GATE (gate 2026-11-02) is spent under EVERY possible resolution.**
- **A name whose catalyst falls between 2026-11-02 and 2026-11-30 might be spent if the true gate is 12-01.** Those names keep FULL (a)-(e) and are marked `GATE-SURVIVING`. They are listed separately under "provisional, would be SPENT if the gate is 12-01" so that W4 and next cycle can see the exposure.

**Scheduled re-scores** (`monthly_ftd`): next **2026-11-02**, then 2026-12-01 and 2027-01-04.

**Out-of-cycle M1R path.** `sql_limbs_fired` needs four conjuncts: dwell ≥ 15, technical leg HEALTHY, price retraced, and the axis still acute.
- Dwell: TRUE (123 trading days).
- Technical leg: now TRUE (HEALTHY 51.88).
- Price retraced: FALSE.
- Axis still acute: TRUE.
- One conjunct is false, down from two last cycle. That is the closest this path has come, but the price leg still blocks it. The verdict is unchanged: the out-of-cycle path does not make an earlier A activation reachable. The spec gap (`ops.alerts` `99ccd487`, STEP 1 silent on M1R) is still OPEN with W5. It is not re-filed.

**FAIL-OPEN status: the PARTIAL form applies, by construction.** `state.rerisking_limb_status` read cleanly, and the price leg was derivable. The quiet-clock leg is indeterminate between 11-02 and 12-01 only, so the gate was set to the earliest candidate. Every classification that depends on the indeterminacy resolves toward GATE-SURVIVING.

### STEP 2 — the DIRECTION rail, run FIRST

Strategy A is **long-only** (`strategy/03_strategy_a.md`: "no short positions in A — short is B's territory"). A candidate whose hypothesized mispricing is that the name is **over**-valued cannot produce an A entry at any conviction. The rail ran before ranking and before the gate classification.

**Nine names remain `DIRECTION-INADMISSIBLE (A long-only rail)` and one (TGT) remains direction-unresolved**, the same set as 2026-10-11. No evidence read this week reverses any direction. Direction-relevant developments this week, all consistent with the existing marks: AMAT fell **-6.69% on 10-13** after an Investor Day with no WFE forecast (D1 `c4156ada`), reinforcing the China-WFE bearish mark; the Barclays downgrades of DELL/HPE/NTAP (10-14) do not flip those three (they are bullish A candidates with a new adverse datapoint, see their rows); HD and WMT carry no new direction evidence beyond the hot Sept CPI (3.7% y/y) and hot PPI (+6.3% y/y), which sit on the housing-turnover and low-income-consumer legs of their bearish marks.

**The airline cluster stays categorically inadmissible, and its two best-dated members are near.** **UAL prints 2026-10-20 (C, AMC; call 10-21)** and **AAL prints 2026-10-22 (C)**; both are SPENT-BY-GATE. DAL printed 10-09 (next 2027-01-12 (E)); CCL's next print is 2026-12-18 (E). Fuel-shock channel is live: Brent ~105.9 on the view, Houthi/Hormuz events 10-12..10-15 (STEP 1). B reads DO-NOT-ACTIVATE (`div-B-202609-1`), so there is no open review where the cluster can land this week.

**Rank-direction notes on admissible names (no rail change):** AMD stays bullish-but-contested (competitive position, not direction); TGT stays DIRECTION UNRESOLVED (the earlier bearish thesis was refuted by a beat-and-raise and no replacement direction is established).

### STEP 3 — classification and counts

A candidate is `SPENT-BY-GATE (gate 2026-11-02)` iff it carries a DATED catalyst strictly before 2026-11-02 and NO dated catalyst on or after it. A date ON 2026-11-02 is not strictly before. Undated, or a mix of spent and surviving catalysts, is `GATE-SURVIVING` (fail-open). **Every row was re-derived from this run's date tables (PART 1A), not carried from 2026-10-11.**

**48 ranked candidates + 9 DIRECTION-INADMISSIBLE = 57 carried. Against the 2026-11-02 gate: 45 GATE-SURVIVING, 12 SPENT-BY-GATE.** Spent twelve: XOM, CVX, GEV, NOW, CAT, IBM, LLY, INTC, META, GE (ranked) and UAL, AAL (inadmissible). Last cycle: 43 surviving / 14 spent. Of the 45 survivors, **4 survive on fail-open** (MRVL, CRM, INTU: no date established; GOOGL: undated Waymo launches alongside a pre-gate print), and **the survivors split into 39 that carry a dated post-gate catalyst and 6 that survive on thin or conditional dating** (V, BAC, UNH, JPM, MSFT, AMZN: see below).

**Names that changed class versus 2026-10-11, and why:**
- **V: SPENT → SURVIVING (date move).** Visa FQ4 print is 10-27 (C, now company-issued) but the DOJ fact-discovery close moved from 10-16 to **2027-01-29 (E)** (out_events), a dated post-gate catalyst. Thin: an (E) litigation milestone; if W3/W4 judge it not a catalyst, V reverts to spent.
- **BAC: SPENT → SURVIVING (print consumed).** BAC printed 10-14 (EPS 1.08 vs 1.10 est; revenue $30.00B vs $30.58B, FMP); next print **2027-01-15 (E)**. The 2026-10-11 spent mark rested on the 10-14 print, now consumed.
- **META: stays SPENT, date moved.** 10-28 (E) → **10-21 (C)** (investor.atmeta.com), still pre-gate.
- **CAT: stays SPENT; date firmed to 10-29 (C)** (caterpillar.com). The Fabick close (late October, T) is also pre-gate. If Caterpillar's own Fabick notice ever names a date on or after 11-02, CAT returns to surviving.
- **XOM: stays SPENT; date firmed to 10-30 (C)** (investor.exxonmobil.com); the uncorroborated 10-23 claim is refuted.
- **Tag upgrades with no class change:** MSFT 10-28 (C), AMZN 10-29 (C), FSLR 10-29 (C), V 10-27 (C), DDOG **11-04 (C)** (was 11-05 E), AAPL 11-02 (C; Apple release text relayed by MacRumors/MacTrast: Monday 2026-11-02, 2:00 pm PT), VRTX povetacicept PDUFA 11-30 upgraded **(E) → (C)** (Vertex 2026-06-01 release via news.vrtx.com, found this run).
- **Downgrades / conflicts:** ORCL's "AI World" (renamed from CloudWorld) 10-25..28 is (E); MSFT Ignite 11-17..20 and AMZN re:Invent 11-30..12-04 are (E) (third-party listings only). Because MSFT and AMZN's only post-gate catalysts are (E) conference dates, **both are GATE-SURVIVING only on those weak dates; their substantive catalyst (10-28, 10-29 prints) is spent.** They stay surviving by rule (fail-open), but are the first names to re-examine if W4 wants to avoid enqueuing a thesis whose main catalyst is spent.
- **Printed this week and re-classified on the next print:** JPM (10-13: EPS 5.75 vs 5.93 est, revenue $50.17B vs $51.23B; next 2027-01-14 (E); Investor Day 2027-02-22 (C)), UNH (10-13: EPS 4.69 vs 4.14; next 2027-01-20 (E); investor conference ~early Dec (E)), BAC (above). All surviving.
- **Fragile survivors (one day earlier flips them):** AAPL, VRTX (both (C); a move is unlikely), PLTR (11-02, E, no company notice), SMCI/SHOP/AMD (11-03).

| Ticker | Dated catalysts (re-read this run) | Class vs gate 2026-11-02 |
|---|---|---|
| TTWO | FQ2 11-05 (E); GTA VI launch 11-19 (C) | SURVIVING |
| NVDA | GTC Berlin 10-20..22 (C, keynote 10-21); earnings 11-18 (E); GTC DC 11-30 (E, conflicting) | SURVIVING |
| VRTX | earnings 11-02 (C), ON gate; povetacicept PDUFA 11-30 (C); Journavx sNDA 12-05 (2S) | SURVIVING |
| FSLR | earnings 10-29 (C); Sec 232 regime 12-04 (C) | SURVIVING |
| AVGO | earnings 12-09 (E) | SURVIVING |
| CSCO | earnings 11-11 (E) | SURVIVING |
| AMD | earnings 11-03 (C) | SURVIVING |
| MSFT | earnings 10-28 (C); Ignite 11-17..20 (E) | SURVIVING (on the (E) Ignite date only) |
| AMZN | earnings 10-29 (C); re:Invent 11-30..12-04 (E) | SURVIVING (on the (E) re:Invent date only) |
| AAPL | earnings 11-02 (C), ON gate | SURVIVING |
| ORCL | AI World 10-25..28 (E); FQ2 12-10 (E) | SURVIVING |
| XOM | earnings 10-30 (C) | SPENT-BY-GATE |
| MU | FQ1 12-23 (E) | SURVIVING |
| QCOM | earnings 11-11 (E) | SURVIVING |
| MRVL | none dated (early Dec INFERRED) | SURVIVING (undated, fail-open) |
| DELL | earnings 11-24 (E) | SURVIVING |
| UBER | earnings 11-04 (E; one tracker 11-02) | SURVIVING |
| PLTR | earnings 11-02 (E), ON gate | SURVIVING |
| SNOW | earnings 12-02 (E) | SURVIVING |
| CRM | none dated (early Dec INFERRED) | SURVIVING (undated, fail-open) |
| GEV | earnings 10-28 (C) | SPENT-BY-GATE |
| CVX | earnings call 10-30 (C) | SPENT-BY-GATE |
| PANW | earnings 11-12 or 11-18 (T) | SURVIVING |
| CRWD | earnings 12-01 (E) | SURVIVING |
| JPM | printed 10-13; next 2027-01-14 (E); Investor Day 2027-02-22 (C) | SURVIVING |
| HPE | earnings 12-03 (E) | SURVIVING |
| NBIS | earnings 11-11 (E) | SURVIVING |
| DIS | earnings 11-17 (E; was 11-12) | SURVIVING |
| SHOP | earnings 11-03 (E) | SURVIVING |
| NOW | earnings 10-28 (C) | SPENT-BY-GATE |
| DDOG | earnings 11-04 (C) | SURVIVING |
| OKTA | earnings 12-01 or 12-02 (E) | SURVIVING |
| NTAP | earnings 12-01 (E) | SURVIVING |
| SMCI | earnings 11-03 (E) | SURVIVING |
| MRNA | earnings 11-06 (E) | SURVIVING |
| INTU | none dated (late Nov INFERRED) | SURVIVING (undated, fail-open) |
| GOOGL | earnings 10-28 (E); Waymo launches "2026" (T, undated) | SURVIVING (fail-open on the undated catalyst) |
| CAT | earnings 10-29 (C); Fabick close late Oct (T) | SPENT-BY-GATE |
| IBM | earnings 10-21 (C) | SPENT-BY-GATE |
| LLY | earnings 10-29 (C) | SPENT-BY-GATE |
| MRK | ESMO event 10-26 (C, unverified); earnings 10-29 (C); Q4 call 2027-02-02 (C) | SURVIVING |
| UNH | printed 10-13; next 2027-01-20 (E); investor conference ~early Dec (E) | SURVIVING |
| BAC | printed 10-14; next 2027-01-15 (E) | SURVIVING |
| V | earnings 10-27 (C); DOJ discovery close 2027-01-29 (E) | SURVIVING (thin) |
| TGT | earnings 11-18 (C) | SURVIVING |
| INTC | earnings 10-29 (C) | SPENT-BY-GATE |
| META | earnings 10-21 (C) | SPENT-BY-GATE |
| GE | earnings 10-20 (C) | SPENT-BY-GATE |
| UAL | earnings 10-20 (C) | SPENT-BY-GATE |
| AAL | earnings 10-22 (C) | SPENT-BY-GATE |
| DAL | printed 10-09; next 2027-01-12 (E) | SURVIVING |
| CCL | earnings 12-18 (E) | SURVIVING |
| AMAT | earnings 11-12 (E) | SURVIVING |
| WMT | earnings 11-19 (C) | SURVIVING |
| ADBE | MAX 11-10..12 (E); earnings 12-09 (E) | SURVIVING |
| HD | earnings 11-17 (E) | SURVIVING |
| AKAM | earnings 11-05 (C) | SURVIVING |

### Provisional — would be SPENT if the gate is 2026-12-01

Per STEP 1, the true gate may be 2026-12-01 if any of the 10-13/10-14/10-15 shock events qualifies (likely, not ruled). Every GATE-SURVIVING candidate with a dated catalyst in 2026-11-02 → 2026-11-30 is listed. The first group carries ONLY catalysts in that window (all dated catalysts <= 11-30, none later, none undated) and so flips to SPENT-BY-GATE at 12-01; the second group has an in-window date but also a later catalyst and stays surviving.

**Would flip to SPENT at 12-01 (21 names):** AAPL (11-02), PLTR (11-02), AMD (11-03), SHOP (11-03), SMCI (11-03), UBER (11-04), DDOG (11-04), TTWO (11-05, 11-19), AKAM (inadmissible; 11-05), MRNA (11-06), CSCO (11-11), QCOM (11-11), NBIS (11-11), AMAT (inadmissible; 11-12), PANW (11-12 or 11-18, T), DIS (11-17), HD (inadmissible; 11-17), MSFT (Ignite 11-17..20; (E)), TGT (11-18), WMT (inadmissible; 11-19), DELL (11-24). That is **21** names, of which 4 are inadmissible (AKAM, AMAT, HD, WMT) and **17 are admissible ranked names**.

**In-window date but still SURVIVING at 12-01 on a later catalyst:** NVDA (11-18, GTC DC 11-30; GTC 2027 03-15 (C)), VRTX (povetacicept 11-30 (C); Journavx sNDA 12-05 (2S)), AMZN (re:Invent 11-30..12-04 straddles 12-01), ADBE (MAX 11-10..12; earnings 12-09), FSLR (Sec 232 12-04; earnings 10-29 spent), plus names whose only in-window items are non-catalysts.

**Net effect if the gate is 12-01:** survivors 45 → 24 (21 flip), spent 12 → 33. Admissible survivors at 12-01 among the current top-10: NVDA, VRTX, FSLR, AVGO, AMZN (5 of 10); TTWO, CSCO, AMD, MSFT, AAPL would be spent. W4 should treat the top-10 as **durable only for NVDA, VRTX, FSLR, AVGO (and AMZN, thinly)** if 12-01 is the reachable re-score.

### TOP-10 — the actionable tier

All long. **10 of 10 GATE-SURVIVING; zero spent names in the tier.** Friday 2026-10-16 price half is from IBKR regular-session daily bars (RTH), no news research for Friday (the 10-16 narrative gap is structural; D1's Sunday fire runs after W1). Friday was a broad AI-hardware sell-off: AMD -5.95%, ORCL -4.64%, AVGO -4.52%, FSLR -3.45%, CSCO -2.24%; only AAPL rose.

**1. TTWO — Take-Two Interactive.** (a) **Bullish**, under-valued. (b) GTA VI (largest entertainment launch attempted) against a market that has repeatedly discounted Rockstar holding a date. Take-Two reaffirmed the 2026-11-19 launch and FY27 net bookings of $8.0-8.2B on the 2026-08-07 call (press reports); no October update found (search this run). Supporting: last two 10-Qs (deferred-revenue mechanics, preload schedule). (c) **GTA VI launch 2026-11-19 (C)**, preload 11-12 (carried); FQ2 earnings **2026-11-05 (E)** (no company notice; 2025 notice came 10-09). (d) On the A queue since 2026-08-09; no open position. (e) **Top-10.** *Friday 10-16: close 205.28, -1.96%.* Unchanged at #1. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-05)

**2. NVDA — NVIDIA.** (a) Bullish. (b) The AI-compute and memory re-rating read-through; FQ2 10-Q, last four transcripts, GTC materials. **New this week:** TSMC's Q3 beat (10-15: revenue ~$46.7B vs guided $44.6-45.8B; Q4 guide $52.3-54.3B; 2026 growth "slightly above 40%"; chairman said AI demand still exceeds supply, advanced packaging the binding constraint; capex "significantly higher" next three years) is a direct supply-side read-through to NVDA/AVGO/AMD, even though TSM itself fell -1.80% (D1). **Counter-evidence, new:** the CoreWeave credit scare (2032 notes below 80c, ~15% yield, record CDS for CoreWeave and Oracle; stock -16% intraday 10-14; CEO cites >$104B backlog) puts AI-infrastructure financing, which NVDA's customers depend on, under scrutiny; NVDA has also agreed to buy unsold CoreWeave capacity through April 2032. Carried objection: circular financing (2026-07-27), FT OpenAI-revenue report (10-08). (c) **GTC Berlin 10-20..22 (C; keynote Wed 10-21, Tempodrom)** is spent; earnings **2026-11-18 (E)** (one aggregator 11-17); GTC DC 11-30..12-03 (E, conflicting listings). (d) Queued 2026-05-09; no open position. (e) Top-10. *Friday 10-16: close 214.13, -1.43%* (down from 228.52 on 10-13: -6.3% in three sessions). GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-18)

**3. VRTX — Vertex Pharmaceuticals.** (a) Bullish. (b) Two regulatory decisions in a five-week band; the closed Crinetics acquisition (2026-09-01); the ~$8.8B Q3 IPR&D charge lands in the 11-02 print (known, non-cash). **Povetacicept BLA: Vertex's own 2026-06-01 release (via news.vrtx.com / BusinessWire) states FDA acceptance for accelerated approval in IgAN with PDUFA 2026-11-30**, resting on the RAINIER Week-36 interim proteinuria analysis; no early action or date change reported. The W41 uncertainty ("D2's 10-07 record did not re-confirm 11-30") is closed on the company release. (c) Earnings **2026-11-02 (C)**, AMC, call 16:30 ET, ON the gate; **povetacicept PDUFA 2026-11-30 (C)**; Journavx sNDA 2026-12-05 (2S). (d) Queued 2026-07-05; no open position. (e) Top-10. *Friday 10-16: close 499.74, -1.77%.* GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-02)

**4. FSLR — First Solar.** (a) Bullish. (b) A fully specified policy catalyst: the Sec 232 polysilicon-and-derivatives regime (proclamation signed 2026-08-06: minimum import price on polysilicon, wafers, cells and modules, 15% tariff on certain derivatives, effective 12:01 am ET 2026-12-04; secondary coverage cites a ~$0.38/W module floor). FSLR's cadmium-telluride panels contain no polysilicon, so rules that punish importers protect its pricing; BMO upgrade to Outperform ($263). Secondary commentary only; the proclamation text and the next 10-Q are the primary sources to confirm in construction. (c) **Sec 232 regime effective 2026-12-04 (C)**; earnings **2026-10-29 (C)** (First Solar release, now company-issued) is spent. (d) Queued 2026-09-06; no open position. (e) Top-10. *Friday 10-16: close 172.64, -3.45%* (186.60 on 10-13: -7.5% in three sessions; no news researched for the move). GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-12-04)

**5. AVGO — Broadcom.** (a) Bullish. (b) Custom-silicon and AI-networking attach; TSMC's packaging-constrained, supply-short AI demand is a positive read-through. Counter-evidence carried and strengthened: BofA note on a ~$370B AI-debt vehicle (2026-08-14, -5.94%); WSJ report (10-07/08, T) on OpenAI-capacity financing together with Oracle; the CoreWeave credit scare of 10-13..14 (above). (c) Earnings **2026-12-09 (E)** (aggregator; not in FMP; no notice found). (d) Queued 2026-05-09; no open position. (e) Top-10. *Friday 10-16: close 328.75, -4.52%* (357.31 on 10-13: -8.0% in three sessions). GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-12-09)

**6. CSCO — Cisco.** (a) Bullish. (b) AI-networking order growth against a durably low multiple; fiscal-2026 hyperscaler AI orders were raised to ~$9B (from $5B); management has flagged FY27 AI-infrastructure revenue of ~$7.5B and noted some customers may have pulled orders forward on supply fears; non-GAAP gross margin fell to 66.3% (from 68.4%) on AI-hardware mix (secondary summaries, not cross-checked with the 10-K). Valuation-reset objection carried (new high 112.23 earlier). (c) Earnings **2026-11-11 (E)**; one calendar 11-10, another 11-18; no company notice (2025 notice came 11-03). (d) Queued 2026-05-09; no open position. (e) Top-10. *Friday 10-16: close 107.39, -2.24%.* GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-11)

**7. AMD — AMD.** (a) Bullish, **contested** on competitive position rather than direction (the rail does not engage). (b) Counter-evidence carried and material: the exclusive SpaceX AI-compute socket lost to NVDA (2026-08-05). New: AMD fell 5.7% on 10-14 to 570.82 on the CoreWeave bond sell-off (Barron's attribution via a news aggregator), with FRMI AMD credit support noted by D1 on 10-13; the TSMC capacity read-through is positive. (c) Earnings **2026-11-03 (C)**, AMC, call 17:00 ET (ir.amd.com 2026-10-06), one day past the gate. (d) Queued 2026-05-29; no open position. (e) Top-10. *Friday 10-16: close 528.75, -5.95%* (605.53 on 10-13: -12.7% in three sessions, the sharpest drop in the tier). GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-03)

**8. MSFT — Microsoft.** (a) Bullish. (b) Azure AI capacity commentary; last four transcripts. July FQ4: revenue ~$90B (+18%), Azure +43%, management pointing to ~45% in FQ1 and capex above $50B for the quarter (search summary of the 07-29 call; figures not cross-checked). (c) Earnings **2026-10-28 (C)** (Microsoft release dated 2026-10-07), spent; **Ignite 2026-11-17..20 (E)**, the only post-gate catalyst and a third-party listing. (d) Queued 2026-07-05; no open position. (e) Top-10, **held on rank but flagged**: its substantive catalyst is spent and it survives by rule on a weak (E) conference date. *Friday 10-16: close 529.05, -1.93%.* GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-17)

**9. AMZN — Amazon.** (a) Bullish. (b) AWS: Q2 revenue $42.2B (+36.7%, fifth straight quarter of acceleration, fastest in 18 quarters), operating income $16.6B, backlog $496B (from $364B at March), 2027 capacity largely reserved; 2026 capex guidance raised to $220B, trailing-12-month FCF negative $7.6B; Q3 net-sales guide $197-202B (+14-17%) (search summary of the 2026 Q2 call, secondary). The CoreWeave/AI-credit scare is a funding-structure read-through, though AWS is self-funded. (c) Earnings **2026-10-29 (C)** (aboutamazon.com), spent; **re:Invent 2026-11-30..12-04 (E)**, straddles 12-01. (d) Queued 2026-07-12; **two open Strategy D lots** (`D:AMZN:2026-07-09`, `D:AMZN:2026-07-30`). (e) Top-10, *promoted from #12 into the vacated XOM slot*: the strongest admissible surviving name outside the tier, with the most recent first-party quantification of backlog; flagged as survivor on an (E) date only, same as MSFT. *Friday 10-16: close 250.00, -1.87%.* GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-30)

**10. AAPL — Apple.** (a) Bullish. (b) Apple's own announcement (relayed by MacRumors/MacTrast 2026-10-06): FQ4 results **Monday 2026-11-02, 2:00 pm PT / 5:00 pm ET**. On the FQ3 call Apple guided September-quarter revenue growth of 9-11% (implies ~$111.7-113.7B vs $102.5B) and iPhone growth in the mid-teens, with FX and supply headwinds; the quarter captures launch-week iPhone 18 Pro, Watch Series 12 / Ultra 4 and AirPods 5; base iPhone 18 reportedly slips to spring 2027 (The Information; conflicting with other reports). Watch items: memory pricing and supply constraints. No consensus estimate was found. (c) Earnings **2026-11-02 (C)**, ON the gate (not strictly before it). (d) Queued 2026-05-02; no open position. (e) Top-10, *promoted from #11* into the vacated XOM slot: the only top-candidate with a company-issued date landing exactly on the gate and a quantified guide to test; **zero-day margin** is the standing fragility. *Friday 10-16: close 343.46, +0.43%* (the only name in the tier to rise on the day). GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-02)

### 11–20

**11. ORCL — Oracle.** (a) Bullish. (b) AI-capex backlog thesis. **Adverse, materially new:** 5-year CDS for Oracle and CoreWeave reportedly at record levels (Seeking Alpha, via search summary), Oracle caught in the CoreWeave/AI-credit wave of 10-13..14, plus the unconfirmed WSJ OpenAI-financing report (10-07/08, -5.5%). This is the reason it falls out of the top-10 (#9 → #11): funding structure is the live question. (c) **FQ2 2026-12-10 (E)** (three calendar sites); Oracle AI World (renamed from CloudWorld) 10-25..28 or 10-26..29 (E, third-party listings; date conflict unresolved). (d) Queued 2026-05-09; no open position. (e) 11-20. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-12-10)

**12. XOM — ExxonMobil.** (a) Bullish. (b) Reduced per the mode, no first-party document chase. The shock evidence strengthened again this week: Houthi strikes on Riyadh airport and Aramco HQ Dhahran, three ship incidents, Hormuz flow ~one-tenth of the prior week (Kpler), Brent 105.92 on the view, 104.3 (D1 secondary) after -1.7% on 10-15. (c) Earnings **2026-10-30 (C)** (investor.exxonmobil.com); no later dated item. (d) Queued 2026-09-13; no open position; contract identity see census. (e) 11-20, *down from #10*: it is SPENT, and AAPL / AMZN are surviving admissible names of comparable conviction. Kept at #12 as the energy-seam representative. Gap thesis: the market prices a transient shock while physical flow data shows a structural one; the print is before A can open. GATE: SPENT-BY-GATE (gate 2026-11-02; catalyst 2026-10-30)

**13. MU — Micron.** (a) Bullish. (b) The old thesis was consumed by the 09-30 print; a new thesis must be on guidance durability. **Adverse, new:** CXMT server-DRAM push (ByteDance five-year deal >$7B in July; CXMT at 7-9.5% DRAM revenue share in Q2 vs Micron 23-25%; D1 10-12: MU -3.9%); Micron's FY2026 10-K shows 81% consolidated gross margin and a $35.16B buyback authorization usable from 2026-12-09 (search summary of the 10-K). (c) **FQ1 2026-12-23 (E)**. (d) Queued 2026-05-09; no open position. (e) 11-20. *Flag for W4/D2: the queue row's catalyst reference is the consumed 09-30 print and should be read as stale.* GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-12-23)

**14. QCOM — Qualcomm.** (a) Bullish. (b) Stellantis Snapdragon expansion; auto/IoT diversification. No fresh document this week. (c) **FQ4 2026-11-11 (E)**; no FQ4 notice surfaced. (d) Queued 2026-05-01; no open position. (e) 11-20. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-11)

**15. MRVL — Marvell Technology.** (a) Bullish. (b) Custom-silicon ramp; Investor Day 10-06 (FY28 ~$20B outlook, +5.81%) is consumed. **Adverse, new:** MRVL sank 8.7% on 10-14, worse than AMD, in the CoreWeave sell-off (search summary of Barron's coverage). (c) **No FQ3 date established**; early December INFERRED from the 2025 pattern (FQ3 FY26 was 2025-12-02). (d) Queued 2026-05-25; no open position. (e) 11-20. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst undated)

**16. DELL — Dell Technologies.** (a) Bullish. (b) AI-server capex. **Adverse, new:** Barclays downgrade on 10-14 (-11.27% that day with HPE -8.28%, NTAP -7.03%; D1 `c75cac94`), a sell-side challenge to the AI-server margin thesis; the downgrade note itself was not read. (c) **2026-11-24 (E)**; "not confirmed". (d) Queued 2026-05-17; no open position. (e) 11-20. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-24)

**17. UBER — Uber.** (a) Bullish. (b) The ~3,300-role restructuring's margin effect lands in this print; ezCater $2.3B acquisition (10-06). (c) Earnings **2026-11-04 (E)** (FMP; no company notice; one tracker says 11-02, still not strictly before the gate). (d) **NOT on the A queue**, so new intake if W4 converts it; **open Strategy D lot** `D:UBER:2026-07-09`. (e) 11-20. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-04)

**18. PLTR — Palantir.** (a) Bullish. (b) Government and commercial bookings. (c) Earnings **2026-11-02 (E, FMP + Benzinga)**, ON the gate; no company release found (2025 notice came 10-13 for 11-03). (d) Not on the A queue. (e) 11-20, the thinnest-margin name without a company-issued date. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-02)

**19. SNOW — Snowflake.** (a) Bullish; Cortex AI monetisation and the $6B AWS commitment. (b) Dilution evidence carried: $3.5B convertible (09-28). (c) **2026-12-02 (E).** (d) Queued 2026-05-25; no open position. (e) 11-20. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-12-02)

**20. CRM — Salesforce.** (a) Bullish; agentic-AI attach against a compressed multiple. (b) No fresh document. (c) **No date established**; early December INFERRED (FQ3 FY26 was 2025-12-03). (d) Queued 2026-05-17; no open position. (e) 11-20. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst undated)

### 21–30

**21. GEV — GE Vernova.** (a) Bullish. (c) Earnings **2026-10-28 (C)**, the FOMC day. (d) Queued 2026-08-09; **open Strategy D lot `D:GEV:2026-08-03`**. (e) Rank 21, *down from #15* (spent). Gap thesis: electrification and grid-capex demand under-appreciated; adverse GLJ Research Sell ($470, 2026-09-14) carried. GATE: SPENT-BY-GATE (gate 2026-11-02; catalyst 2026-10-28)

**22. CVX — Chevron.** (a) Bullish. (c) Earnings call **2026-10-30 (C)**. (d) Queued 2026-09-13; no open position. (e) Rank 22, *down from #14* (spent; XOM and CVX are one concentration decision). Gap thesis: the same shock seam as XOM; Chevron/HESM restructuring (10-07) is past. GATE: SPENT-BY-GATE (gate 2026-11-02; catalyst 2026-10-30)

**23. PANW — Palo Alto Networks.** (a) Bullish; platformisation. (b) No fresh document. (c) FQ1 FY27 **11-12 or 11-18 (T)**, both post-gate; no notice (2025 notice came 11-04). (d) Queued 2026-05-31. (e) 21-30. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-12)

**24. CRWD — CrowdStrike.** (a) Bullish; module attach. (c) **2026-12-01 (E)** (projection, "not confirmed"). (d) Queued 2026-05-31. (e) 21-30. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-12-01)

**25. JPM — JPMorganChase.** (a) Bullish. (b) The 10-13 print missed (EPS 5.75 vs 5.93 est; revenue $50.17B vs $51.23B, FMP) while GS (EPS 17.01 vs 12.86) and C (2.85 vs 2.66) beat; hot Sept CPI (3.7% y/y) and PPI (+6.3% y/y) keep the rate-supportive NIM arithmetic intact but pressure credit-sensitivity; the 10-year sits ~5.10%. (c) The 10-13 print is consumed; next print **2027-01-14 (E)**; **Investor Day 2027-02-22 (C)**. (d) Queued 2026-09-13. (e) 21-30. The existing `spent_by_gate_likely` payload on JPM's queue row is now stale. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2027-01-14)

**26. HPE — Hewlett Packard Enterprise.** (a) Bullish; AI-server read-through as DELL. **Adverse, new:** Barclays downgrade 10-14 (-8.28%). (c) **2026-12-03 (E).** (d) Queued 2026-05-29. (e) 21-30. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-12-03)

**27. NBIS — Nebius Group.** (a) Bullish; neocloud capacity. **Adverse, new:** the CoreWeave credit scare is the closest listed comparable stress (neocloud debt financing); OpenAI's reported training pause (09-28) and the 10-08 OpenAI-revenue report carried. (c) **2026-11-11 (E)**; one calendar 10-22/11-10 split; no company notice. (d) Queued 2026-05-13. (e) 21-30; *conviction lowered, rank held*. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-11)

**28. DIS — Disney.** (a) Bullish; SVOD margin expansion. (c) Earnings **2026-11-17 (E)** (FMP; was 11-12, +5d). (d) **Not on the A queue**; two open Strategy D lots. (e) 21-30. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-17)

**29. SHOP — Shopify.** (a) Bullish; GMV take-rate. (c) Earnings **2026-11-03 (E)**. (d) Not on the A queue. (e) 21-30. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-03)

**30. NOW — ServiceNow.** (a) Bullish; platform attach. Passed on its own event (D1 10-15, positive move). (c) Earnings **2026-10-28 (C)**, AMC, call 14:00 PT. (d) Queued 2026-05-29. (e) 21-30, *down from #23* (spent). Gap thesis: agentic-platform attach under-credited; the WDAY take-private report is unverified and unweighted. GATE: SPENT-BY-GATE (gate 2026-11-02; catalyst 2026-10-28)

### 31–40

- **31. DDOG — Datadog.** (a) Bullish. (b) reduced: no fresh document. (c) Earnings **2026-11-04 (C)** (company release, finviz copy; was 11-05 E). (d) Queued 2026-05-07. (e) 31-40. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-04)
- **32. OKTA — Okta.** (a) Bullish. (c) **12-01 or 12-02 (E)** (aggregators conflict by a day). (d) Queued 2026-05-29. (e) 31-40. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-12-01)
- **33. NTAP — NetApp.** (a) Bullish. **Adverse, new:** Barclays downgrade 10-14 (-7.03%). (c) **2026-12-01 (E)**. (d) Queued 2026-05-29. (e) 31-40. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-12-01)
- **34. SMCI — Super Micro.** (a) Bullish. (c) **2026-11-03 (E)**; aggregator, absent from FMP, no company notice. (d) Queued 2026-05-29. (e) 31-40. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-03)
- **35. MRNA — Moderna.** (a) Bullish. NYT vaccine report (D1 10-09) carried as an adverse datapoint. (c) **2026-11-06 (E)** (FMP; was 11-05, +1d). (d) **Not on the A queue.** (e) 31-40. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-06)
- **36. INTU — Intuit.** (a) Bullish. Passed on its own event 10-15 with a positive move (D1). (c) **No date**: Intuit announces the date at quarter end; late November INFERRED. (d) Queued 2026-08-03. (e) 31-40. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst undated)
- **37. GOOGL — Alphabet.** (a) Bullish. (c) Earnings **2026-10-28 (E)** (no Alphabet notice found; days.to "not confirmed"); Waymo multi-city launches "2026" (year-only, T, undated), so **surviving on fail-open**. (d) Queued 2026-07-05; two open Strategy D lots. (e) 31-40. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst undated)
- **38. CAT — Caterpillar.** (a) Bullish (data-centre and energy capex pull-through). Reduced. (c) Earnings **2026-10-29 (C)** (caterpillar.com); Fabick close late October (T). (d) Queued 2026-05-01. (e) 31-40. Gap thesis: data-centre power and dealer-consolidation demand under-credited; FTC/USDA farm-equipment RFI (10-07) is a policy overhang with no deadline. GATE: SPENT-BY-GATE (gate 2026-11-02; catalyst 2026-10-29)
- **39. IBM — IBM.** (a) Bullish. (c) Earnings **2026-10-21 (C)** (newsroom.ibm.com). (d) Queued 2026-05-29. (e) 31-40. Gap thesis: software-and-consulting mix shift to AI under-credited at a low multiple. GATE: SPENT-BY-GATE (gate 2026-11-02; catalyst 2026-10-21)
- **40. LLY — Eli Lilly.** (a) Bullish. (c) Earnings **2026-10-29 (C)**; no PDUFA date in the window. (d) Queued 2026-05-01; a Strategy D router-gated NO-GO was recorded 2026-10-07 (context, not a barrier). (e) 31-40. Gap thesis: obesity-franchise durability under-credited; print precedes A's reachable re-score. GATE: SPENT-BY-GATE (gate 2026-11-02; catalyst 2026-10-29)

### 41–48

- **41. MRK — Merck.** (a) Bullish, held low on substance. ESMO investor event 10-26 (C, unverified) and earnings 10-29 (C) are pre-gate; **Q4 call 2027-02-02 (C)** is post-gate. Both near-term PDUFAs are gone (Welireg + Lenvima approved early 09-25; I-DXd BLA withdrawn): adverse pipeline evidence. (d) Queued 2026-09-13; its `spent_by_gate_likely` payload is stale. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2027-02-02)
- **42. UNH — UnitedHealth.** (a) Bullish. Printed 10-13 (EPS 4.69 vs 4.14; revenue $112.7B vs $111.3B); HUM star-ratings news (10-09) is a sector datapoint. (c) Next print **2027-01-20 (E)**; investor conference ~early December (E, month-level). (d) Not queued. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2027-01-20)
- **43. BAC — Bank of America.** (a) Bullish. Printed 10-14 (EPS 1.08 vs 1.10; revenue $30.00B vs $30.58B). (c) Next print **2027-01-15 (E)**. (d) Not queued. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2027-01-15)
- **44. V — Visa.** (a) Bullish. (c) Earnings **2026-10-27 (C)** (investor.visa.com); DOJ fact-discovery close **2027-01-29 (E)** (moved from 10-16). (d) Not queued. Thin survivor. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2027-01-29)
- **45. TGT — Target.** (a) **DIRECTION UNRESOLVED**: the prior bearish thesis was refuted by a beat-and-raise and no replacement direction is established; held below the tier for that reason. (c) Earnings **2026-11-18 (C)** (corporate.target.com). (d) Queued 2026-05-09. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-18)
- **46. INTC — Intel.** (a) Bullish. (c) Earnings **2026-10-29 (C)** (intc.com, 10-06). (d) Queued 2026-05-12. Gap thesis: foundry-turnaround optionality under-credited; print precedes the gate. GATE: SPENT-BY-GATE (gate 2026-11-02; catalyst 2026-10-29)
- **47. META — Meta Platforms.** (a) Bullish. (c) Earnings **2026-10-21 (C)**, AMC, call 13:30 PT (investor.atmeta.com; moved 7 days earlier from 10-28 E). (d) Queued 2026-08-03. Gap thesis: AI-capex returns under-credited; the print is 11 days out and is first of the megacaps. GATE: SPENT-BY-GATE (gate 2026-11-02; catalyst 2026-10-21)
- **48. GE — GE Aerospace.** (a) Bullish. (c) Earnings **2026-10-20 (C)**, BMO (geaerospace.com). (d) Not queued. Gap thesis: aerospace aftermarket durability under-credited. GATE: SPENT-BY-GATE (gate 2026-11-02; catalyst 2026-10-20)

### DIRECTION-INADMISSIBLE tier — ranked and carried, never actionable for A

These belong to Strategy B. The rail governs only admission to the actionable tier. Each row ends with its gate literal.

| # | Ticker | (a) Direction | (c) Catalyst | (e) Tier / thesis | Gate literal |
|---|---|---|---|---|---|
| I-1 | **UAL** | Bearish | Earnings **2026-10-20 (C)**, AMC (call 10-21) | Inadmissible; same fuel-shock channel, independent print | GATE: SPENT-BY-GATE (gate 2026-11-02; catalyst 2026-10-20) |
| I-2 | **AAL** | Bearish | Earnings **2026-10-22 (C)** | Inadmissible; thinnest balance sheet of the three | GATE: SPENT-BY-GATE (gate 2026-11-02; catalyst 2026-10-22) |
| I-3 | **DAL** | Bearish | Printed 2026-10-09; next **2027-01-12 (E)** | Inadmissible; first airline to report, fuel thesis live | GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2027-01-12) |
| I-4 | **CCL** | Bearish | Earnings 2026-12-18 (E) | Inadmissible; bunker-fuel channel | GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-12-18) |
| I-5 | **AMAT** | Bearish | Earnings **2026-11-12 (E)** | Inadmissible; China WFE cliff, reinforced by the 10-13 Investor Day with no WFE forecast (-6.69%) | GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-12) |
| I-6 | **WMT** | Bearish | Earnings **2026-11-19 (C)** | Inadmissible; two adverse datapoints vs the original bullish framing | GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-19) |
| I-7 | **ADBE** | Bearish | Earnings 2026-12-09 (E); MAX 11-10..12 (E) | Inadmissible; vindicated on tape | GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-10) |
| I-8 | **HD** | Bearish / neutral | Earnings **2026-11-17 (E)** | Inadmissible; housing-turnover starvation under a ~5.10% 10-year and hot CPI | GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-17) |
| I-9 | **AKAM** | Bearish / contested | Earnings **2026-11-05 (C)** | Inadmissible; smallest cap in the file | GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-05) |

**W4 side, restated because it binds:** no candidate marked `DIRECTION-INADMISSIBLE` may be converted into a Strategy A `PENDING_ANALYSIS` row, and a vacated slot is filled from the next admissible candidate rather than shipping a short top-10. None of the nine is in the top-10. Five of the nine (AKAM, AMAT, ADBE, HD, WMT) are already on the A queue; D2 applies the rail to any thesis run on them.

### Handoff notes for W4

- **New intake vs census: ZERO.** All ten top-10 names (TTWO, NVDA, VRTX, FSLR, AVGO, CSCO, AMD, MSFT, AMZN, AAPL) are on the 44-row A queue (verified against the census). The seventh consecutive cycle of zero new A intake from the top-10; that is the steady state while A reads DO-NOT-ACTIVATE.
- **Tier changes W4 should see:** XOM leaves the top-10 (#10 → #12, spent); AMZN enters (#12 → #9) and AAPL enters (#11 → #10); ORCL leaves (#9 → #11) on the AI-credit evidence; GEV/CVX/NOW/CAT/IBM/LLY and the lower spent names sink below survivors; BAC and V move from SPENT to SURVIVING. All are queued names except where noted, so these change ranking, not membership.
- **Candidates NOT on the A queue**, if W4's limb ever reaches past tier 1: UBER (#17), PLTR (#18), DIS (#28), SHOP (#29), MRNA (#35), UNH (#42), BAC (#43), V (#44), GE (#48); plus the inadmissible DAL, CCL, UAL, AAL.
- **Gate marks to carry** (copy the literal at the end of each row verbatim): SPENT-BY-GATE (gate 2026-11-02) on XOM, CVX, GEV, NOW, CAT, IBM, LLY, INTC, META, GE (ranked) and UAL, AAL (inadmissible) = 12. **Stale queue-row payloads to overwrite:** JPM and MRK carry `spent_by_gate_likely` but are SURVIVING; MU's queue row cites the consumed 09-30 print (live catalyst 12-23 (E)); CAT is newly firm-spent. **Exposure if the gate is 12-01:** 21 further names flip (see "Provisional"); W4 should not treat TTWO, CSCO, AMD, MSFT or AAPL as durable top-10 names if 12-01 is the true gate.
- **Cross-strategy overlap.** `state.current_positions`: only Strategy D open (AMZN x2, DIS x2, GEV, GOOGL x2, ISRG, RTX, TSM x2, UBER); zero open A, B or C. Overlap tickers among A candidates are **AMZN (now top-10 #9)**, GEV, GOOGL, DIS and UBER; AMZN's presence in the tier is new, and D2 should confirm the A and D sleeves are distinct for it. C is HYBRID ACTIVATE (FOMC-only): the only C row is `thesis-FOMC-C-20261020` (FOMC 2026-10-28); A and C cannot hold simultaneously, and A has no open position, so no conflict arises. TSM (A-ineligible ADR, open D lots) printed a Q3 beat on 10-15.
- **NO-GO records are context, not barriers.** New since 10-11 in the state_context handed to this sub-agent: none of Strategy A significance. Carried: Strategy D router-gated NO-GOs of 2026-10-07 for LLY, V, VRTX, GE, MSFT, SPOT, MELI, HWM and AVGO (router-gated outcomes under D's criteria, not findings on the names) and Strategy E pair NO-GOs of 2026-10-04 (MCHP/ADI, CB/TRV, MDB/SNOW); none changes an A rank.
- **FedEx:** per the orchestrator ruling the fiscal-year-end change (Dec-31, effective 2026-06-01) removes the basis for rejecting the FDX 10-28 print; treated as (E) in PART 1. FDX is not on the A queue and is not a PART 2A candidate.
- **Re-check next cycle:** whether the 10-13/14/15 shock events qualify (decides gate 11-02 vs 12-01); AAPL (zero-day margin; Apple IR first-party page still not reached, only MacRumors/MacTrast relay), PLTR (on the gate, no company notice), VRTX 11-30 date (company release only, no FDA confirmation), the large caps without a company notice (GOOGL, TTWO, CSCO, QCOM, NVDA, DELL, PANW, SMCI, HD), MSFT/AMZN/ORCL conference dates (third-party listings), V's 2027-01-29 DOJ date, the AI-infrastructure credit thread (CoreWeave maturities, ORCL CDS) as a cross-cutting risk to NVDA, AVGO, AMD, ORCL, NBIS, MRVL.

### REPORT IT — CATALYST-GATE MODE

- **Gate date: 2026-11-02** (sixth consecutive cycle; provable lower bound, applied fail-open; the probable true reachable re-score is 2026-12-01 if any 10-13..10-15 event qualifies).
- **Legs:** price leg FALSE (Brent 105.92 as of 10-15 vs trigger 96.74: needs -8.67% on the view; retracement 11.8%; third straight cycle further from clearing). Quiet-clock leg: anchors 10-12 → clears 11-02, 10-13 → 11-03, 10-14 → 11-04, 10-15 → 11-05; qualification of the 10-13..15 events is M1a/M1R's ruling, not W1's. Technical leg now HEALTHY (breadth 51.88 on 10-15). M1R out-of-cycle path: one conjunct false (price retraced); `ops.alerts` `99ccd487` still open. A reads DO-NOT-ACTIVATE (`3883e492`); mode live, not inert; partial fail-open (the quiet-clock ambiguity resolves toward GATE-SURVIVING).
- **Counts:** 57 carried (48 ranked + 9 inadmissible); **12 SPENT-BY-GATE, 45 GATE-SURVIVING** (4 of those on fail-open; 2 on weak (E) conference dates; V thin). **21 of the 45 surviving are provisional-if-12-01** (would flip to SPENT; 17 admissible + 4 inadmissible); 24 would remain surviving.
- **Friday 10-16 price half:** closed from IBKR bars for the 10 top-10 names (all ten ended down but AAPL).
- **Calls used:** 13 WebSearch (standard), 0 WebFetch; logged in `calls_2a.csv`. Tavily unavailable.

---

## PART 2C — Strategy C ranked shortlist

### Router state, and what it admits

C reads **`HYBRID ACTIVATE (FOMC-only)` — UNCHANGED** (event `4bed3605`, 2026-10-06; `div-C-202609-1` RESOLVED; `capital_enabled` TRUE for C; per the orchestrator's `state.current_regime` read of 2026-10-18). M1b's raw fundamental call for C remains DO-NOT-ACTIVATE, but the operative router state is the HYBRID carve-out. Under it, only an FOMC-type event is router-admissible. Corporate earnings and FDA PDUFA candidates stay **router-PARKED** and must not be enqueued. Widening beyond FOMC-only is reserved to a separate scope-widening adjudication; none is open. A/B/D/E all read DO-NOT-ACTIVATE.

**The one router-eligible event in the 45-day window (2026-10-18 -> 2026-12-02 for the C window; 45 days from the 2026-10-20 queue date reaches 2026-12-04) is the 2026-10-28 FOMC.** `thesis-FOMC-C-20261020` (event `295d48ce`) is already pending on `state.open_queue`, due 2026-10-20; **W4 must not create a duplicate.**

### The capital position (MEASURED 2026-10-18)

C is **NOMADIC**. Borrow capacity is **ZERO** (orchestrator-measured `state.nomadic_borrow_capacity_watch`): C `donor_capacity_total` **0**, `donor_count` **0**, `borrow_blocked` **TRUE**. A, B and E are `capital_enabled` FALSE; D is itself nomadic. E holds **$12,668.28** idle (capital-disabled, unchanged since 10-11). C's `analytics.strategy_nav`: NAV / available funds **$19.48**, realized and unrealized P&L $0, `sizing_base_2pct` **$0.39** (both unchanged from 10-11). **Already alerted, not re-raised:** `ops.alerts` `71d484fa-0623-4443-89ed-a357ab305f67` (`nomadic_borrow_blocked`) is **still OPEN**. `INCIDENT[ref=71d484fa]`. **C has never opened a position**; `state.current_positions` holds only Strategy D (AMZN x2, DIS x2, GEV, GOOGL x2, ISRG, RTX, TSM x2, UBER) — zero open A, B, C or E rows.

### Criterion 1 (a qualifying event within 45 days)

- **FOMC 2026-10-28 is (C)** — carried from the baseline's direct federalreserve.gov fetch (October 27-28, no SEP); not re-fetched by this sub-agent. It clears.
- **Earnings (router-PARKED).** Dates for names carried from the baseline are carried unchanged; the replacement names' dates (NFLX 10-20, TSLA 10-21, META 10-21, MSFT 10-28, AAPL 11-02, AMD 11-03, NVDA 11-18) were supplied by the W1 orchestrator and **not independently verified here** (no calendar source was queried). **Events that have already passed and are STRUCK this cycle:** UNH (10-13), JPM (10-13) — both printed before the window opened; they cannot be entered even if scope widened.
- **PDUFAs (router-PARKED), carried, not re-verified (no source call):** INO-3107 10-30, CYTK 11-14. **VTRS MR-141 (10-17) is STRUCK** — its date passed Saturday 10-17 and no outcome was researched here. **BTAI (11-14) is STRUCK as unusable:** IBKR now resolves Bioxcel only as `BTAIQ` on PINK with a STK section only and **no OPT section**, so no option structure of any kind exists on it (MEASURED via `search_contracts`; the `Q` suffix is a delinquency/bankruptcy marker in general, the cause was not researched).

### The tenor rail — CLEAR, fifth cycle running; SPY expiry grid changed

C requires structure expiration within **1-45 days of entry** (`strategy/05_strategy_c.md`). Queue item: `thesis-FOMC-C-20261020` pending, due **2026-10-20**, conservative default "Decline - no entry" (orchestrator-measured).

MEASURED from the live SPY option parameters (IBKR, underlying conid 756733, verified: `search` not repeated, the chain returns SPY-class expiries with `SPY` descriptions), expiries 10-19 -> 12-31: **10-19, 10-20, 10-21, 10-22, 10-23, 10-26, 10-27, 10-28, 10-29, 10-30** (a full set of weekday expiries, all non-regular SPY class), 11-02, 11-06, 11-13, **11-20 (regular, plus a 2SPY class)**, **11-27 (SPY and 2SPY)**, 11-30, **12-18 (regular)**, 12-31. **New vs last cycle: 10-27, 10-28, 10-29 and 11-02 (last cycle's grid jumped from 10-26 straight to 10-30).**

**The first expiry strictly after the 2026-10-28 decision is now 2026-10-29** (it was 10-30 last cycle). Tenor from the 10-20 queue date: **9 days to 10-29, 10 days to 10-30**, both inside 1-45. **Caveat (MEASURED):** the 10-29 contracts are newly listed and show **no market** (763 call: no bid/ask, last 0.0, OI 0, `implied_vol` invalid, frozen Sunday) so all pricing below uses the **10-30 expiry, the first expiry after the event that carries a quote**. The FOMC decision is announced intra-session on 10-28 (2pm ET), so a 10-28 expiry is not "after" the event and is excluded. Criterion 5 (entry at least one trading day before the event) holds: entry 10-20 Tue leaves sessions 10-21, 10-22, 10-23, 10-26, 10-27 (5 whole sessions, 6 trading-day steps to 10-28).

### Criterion 2 (implied vs realized) — MEASURED on the spec window (trailing 30 days)

Per `strategy/05_strategy_c.md` the headline is **IV/HV30**; HV20 and HV10 are context. (Window question still open as `ops.alerts` `1876c957` per baseline; the spec's 30-day window is applied.)

**Quotes are FROZEN (Sunday); all option values are Friday 2026-10-16's regular-session close book** (last-trade timestamps 20:07-20:14 UTC = 16:07-16:14 ET). SPY **2026-10-16 regular-session close 763.25** (IBKR daily bar, `outside_rth` false; a snapshot "last" of 761.26 at 23:59 UTC is an after-hours print and is NOT used). SPY 2026-10-30 expiry, ATM strike **763** (nearest listed $1 strike to 763.25):

| Field | Value |
|---|---|
| ATM call 763 | bid 9.17 / ask 9.24, last 9.21 (20:14:37Z), OI 1,070 |
| ATM put 763 | bid 8.19 / ask 8.29, last 8.47 (20:07:50Z), OI 2,511 |
| ATM straddle | mid **17.445 -> $1,744.50 per contract** (ask 17.53 -> $1,753); **2.29% of spot** (baseline 2.16%) |
| `implied_vol` on the contracts | **-1.0, `is_valid` FALSE** on both call and put (it was valid at 11.204% last cycle; reverted to the known sentinel, so the ratio below is DERIVED) |
| `implied_vol_underlying` (SPY) | **14.397%**, `is_valid` TRUE (30-day constant maturity; baseline 11.990%) |
| Derived IV (Black-Scholes on bid/ask mids; r 4.0%, q 1.2%, T = 14/365, S 763.25) | call 14.54%, put 14.71%, **average 14.63%**. Derived, assumption-dependent (same r/q as the baseline) |
| IBKR `historical_vol` (broker's own 30d) | 10.542% (context only; method not disclosed; baseline 10.339%) |

Realized volatility, annualized close-to-close (log returns, sample stdev, x sqrt(252)), computed from IBKR regular-session daily closes, last close 2026-10-16:

| Window | N closes (N-1 returns) | Date range | Realized vol | IV/HV (derived 14.63%) | IV/HV (underlying 14.397%) |
|---|---|---|---|---|---|
| **HV30 (spec window)** | 31 (30) | 2026-09-03 -> 2026-10-16 | **10.143%** | **1.442** | 1.419 |
| HV20 | 21 (20) | 2026-09-18 -> 2026-10-16 | 10.459% | 1.399 | 1.376 |
| HV10 | 11 (10) | 2026-10-02 -> 2026-10-16 | 10.290% | 1.422 | 1.399 |

**Comparison with last cycle (HV30 9.890%; IV/HV30 1.144 derived / 1.212 underlying):** the headline ratio **rose** to **1.442** derived (1.419 underlying) — back above the 1.32 of two cycles ago, reversing last week's narrowing. Both legs moved: the 10-30 ATM IV is up ~3.3 pt (11.31% -> 14.63% derived), the 30-day underlying IV is up 2.4 pt (11.99% -> 14.40%), and HV30 is up only 0.25 pt (9.890% -> 10.143%). The tape that produced it: SPY fell **-1.97% on the week** (778.57 -> 763.25), including **-1.11% on Friday 10-16** (771.79 -> 763.25; the lowest close since 09-30's 762.63) after -1.08% on 10-14; the market is repricing event risk faster than realized vol has moved. **Implied is RICH to realized on the spec window and the premium re-widened** (~26% above the 1.144 of a week ago). The realized term structure is now **flat** (HV10 10.29 ~ HV20 10.46 ~ HV30 10.14), so unlike prior cycles the ratio no longer depends on which window is chosen (1.40-1.44).

**Measurement-integrity notes.**
1. `implied_vol` is INVALID on the contracts this cycle, so the headline rests on the derived figure; it is cross-checked by the valid `implied_vol_underlying` (within 0.23 pt of the derived number). Derived inputs are shown above.
2. Frozen Sunday quotes: the call and put last-trades are ~7 minutes apart (20:14:37Z vs 20:07:50Z); bid/ask are the close book. A live in-session read is required before any trade. D2's 10-20 run must read a live quote on a valid expiry; the 10-29 contracts must be re-checked for a market.
3. The 10-30 expiry's IV contains the FOMC jump (10-28) plus 2 post-event days, so it is event-loaded by construction; a rich-vs-realized finding on an event expiry is partly event premium, not a pure volatility risk premium. The 30-day underlying IV is the cleaner context figure.
4. HV is close-to-close on regular-session closes only; excludes overnight gap vol. D1 has not covered the 10-16 narrative (structural Friday gap); price half only is closed here.

**The structural disjointness, unchanged.** Implied rich favours **selling** premium. A credit structure's max loss must be deterministically collateralized and C's reachable $19.48 cannot collateralize any SPY credit spread (a 1-point spread carries $100 gross max loss). The cheapest *debit* structures are priced below and are also unaffordable.

**Cheapest defined-risk SPY structure, MEASURED (10-30 expiry, 1-wide, close book):**

| Structure | Legs (bid/ask) | Debit at natural (ask-bid) | Debit at mid | vs C NAV $19.48 |
|---|---|---|---|---|
| Call debit spread 763/764 | buy 763C ask 9.24, sell 764C bid 8.55 (764C 8.55/8.62) | 0.69 -> **$69.00** | 0.62 -> $62.00 | 3.5x NAV; shortfall $49.52 |
| Put debit spread 763/762 | buy 763P ask 8.29, sell 762P bid 7.82 (762P 7.82/7.92, last 8.00) | 0.47 -> **$47.00** | 0.37 -> $37.00 | 2.4x NAV; shortfall $27.52 |
| ATM straddle (long) | 763C + 763P | $1,753.00 | $1,744.50 | 89.6x NAV |

Max loss of a long debit spread equals its debit, so the minimum debit that clears Criterion 4's max-loss <= stated-risk-budget test is $47 against a hard ceiling of $19.48 (the whole portfolio). **No measured SPY structure is executable at C's NAV.** (Far-wing single long options were not priced this cycle; the baseline reached the same conclusion on the same structures.)

**Panel measurement, extended LIGHTLY this cycle (fourth cycle parked; no decision rests on it).** All names below are earnings or PDUFA candidates and router-PARKED under FOMC-only. Straddle implied move = ATM straddle mid / spot on the first expiry after the event (Friday 10-16 close book); realized-equivalent move = 0.8 x HV30 x sqrt(T/365) over the same horizon; HV30 is IBKR daily closes 2026-09-03 -> 2026-10-16 (same method as SPY). Ratio > 1 means the event straddle is richer than a no-event realized move.

| Name | Event | Expiry used (T cal days) | Spot (10-16 close) | ATM straddle mid | Implied move | HV30 | Realized-equiv. move | Ratio | Quote quality |
|---|---|---|---|---|---|---|---|---|---|
| TSLA | earnings 10-21 | 10-23 (7) | 354.72 | 355C 13.00/13.20 + 355P 13.10/13.25 = 26.275 | 7.41% | 34.5% | 3.82% | 1.94 | tight |
| NFLX | earnings 10-20 | 10-23 (7) | 70.53 | 70 straddle 6.635; 71 straddle 6.70; interpolated 6.66 | 9.44% | 35.2% | 3.90% | 2.42 | tight |
| META | earnings 10-21 | 10-23 (7) | 709.33 | 710C 25.45/26.10 + 710P 25.45/26.50 = 51.75 | 7.30% | 50.2% | 5.56% | 1.31 | moderate |
| MSFT | earnings 10-28 | 10-30 (14) | 529.05 | 530C 15.15/16.50 + 530P 15.70/16.55 = 31.95 | 6.04% | 22.2% | 3.48% | 1.74 | wide (1.35/0.85) |
| AMD | earnings 11-03 | 11-06 (21) | 528.75 | 530C 30.65/32.80 + 530P 31.70/33.90 = 64.525 | 12.20% | 57.5% | 11.03% | 1.11 | wide |
| XOM | earnings 10-30 | 11-06 (21) | 178.98 | 180C 4.50/5.00 + 180P 5.05/5.80 = 10.175 | 5.68% | 23.9% | 4.59% | 1.24 | wide; strike 1.02 ITM-put side |
| INO | PDUFA 10-30 | 11-06 (21) | 0.990 | 1C 0.10/0.30 + 1P 0.25/0.50 = 0.575 | 58% | 69.3% | 13.3% | 4.37 | **unusable**: penny-wide, one-tick spreads exceed 30% of premium |

Reads: implied is rich to realized across the panel; widest on NFLX and TSLA (heavy event premia into 10-20/10-21 prints), narrowest on AMD (stock already -13% on the week, realized vol already 57%). The INO ratio is noise (spreads wider than the mid). AMD, XOM, MSFT have post-event days in the expiry so event premium is diluted; the ratios are conservative for them. None is a divergence finding — it is a pricing measurement only.

### Ranked shortlist — 15 event candidates

Changes vs last cycle's 15: **struck (event passed or unusable): JPM (10-13), UNH (10-13), VTRS (10-17), BTAI (no OPT section, PINK `BTAIQ`).** Replaced by **META, MSFT, AAPL, NVDA** (in-window large-cap earnings, dates orchestrator-supplied). Ranks 4-5 promoted from the baseline's 7-8 (AMD, XOM) because ranks 4-5 (VTRS, UNH) are struck. No other date moved.

**TOP-5**

**1. FOMC 2026-10-28** — (a) **No affirmative directional divergence established by W1.** The measurable divergence is on volatility: IV/HV30 about **1.44** (derived; up from 1.14), implied-rich and re-widened after SPY's -1.97% week; the structures C could theoretically afford are on the buying side and none is affordable (see capital). (b) federalreserve.gov meeting calendar (carried from baseline). The baseline's context (09-16 hike unanimous, 16 of 18 dots for more; 10Y 5.35-5.36% on 10-08) is carried; this week's D1 record adds hot Sept CPI 3.7% y/y (10-14) and hot PPI +6.3% y/y (10-15) per the orchestrator's brief, which keeps the meeting live. (c) **2026-10-28 (C).** (d) **NOT executable at current C capital: flagged DEFERRAL RISK.** C NAV $19.48 vs cheapest measured SPY 1-wide debit spread $47-$69 (above); borrow capacity zero. Whether to defer is D2's decision, not W1's. (e) No open A positions, so no A-C conflict. (f) **Top-5, rank 1, the only router-eligible candidate.**
  **Disposition: W1 shortlists and does not drain.** `thesis-FOMC-C-20261020` is **pending**, due **2026-10-20**; GO/NO-GO is **D2's on that date**, default "Decline - no entry". It is the only FOMC row. **W4 must not create a duplicate.**

**2. TSLA — earnings 2026-10-21 (C).** (a) Implied is rich: straddle 7.41% vs 3.82% realized-equivalent (ratio 1.94); a sell-side divergence C cannot fund. Friday close 354.72 (-2.13%; -7.31% on the week). (b) Tesla IR and 8-K; Q3 deliveries of 486,532 reported 10-02 (carried). (c) 2026-10-21; first post-event expiry 10-23. (d) **Not executable:** ATM straddle $2,627.50; no measured 1-wide TSLA spread, but any debit structure's max loss floor is far above $19.48 (TSLA strikes in $5 steps near spot). Deferral. (e) Not on the A queue. (f) Top-5. **Router-PARKED.**

**3. INO — INO-3107 PDUFA 2026-10-30.** (a) A binary regulatory outcome; implied usually under-prices a first-approval binary in a small cap, but the chain cannot confirm that. (b) Inovio BLA-acceptance release plus trackers (carried). (c) 2026-10-30 (carried, not re-verified). (d) **Not executable at current capital / chain unusable:** stock closed $0.99 (-4.80% Friday, -13.9% on the week), the Nov-06 1-strike straddle quotes 0.10/0.30 and 0.25/0.50 (mid $57.50 per straddle; a single 1C costs $10-$30, i.e. at the ask $30 it exceeds the entire $19.48 NAV). Deferral. (e) No A overlap. (f) Top-5. **Router-PARKED.**

**4. AMD — earnings 2026-11-03 (C; ir.amd.com release 10-06, carried).** (a) Post-shock semis repricing; AMD fell **-5.95% Friday (528.75) and -13.05% on the week** after the AI-hardware rotation; implied move 12.2% vs 11.0% realized-equivalent (ratio 1.11, the leanest on the panel). (b) AMD IR release; the FRMI credit-support item in D1's 10-13 record (carried context only; not researched). (c) 2026-11-03; first post-event expiry 11-06 (AMD and 2AMD classes both listed). (d) **Not executable:** ATM straddle $6,452.50; $2.50-wide spreads alone run several dollars of debit per share at this spot. Deferral. (e) **A queue (AMD)**; no open A position. (f) Top-5 (promoted from baseline #7). **Router-PARKED.**

**5. XOM — earnings 2026-10-30 (C — ExxonMobil's own date notice, per PART 1A 1A.1 this cycle).** (a) Energy-seam second leg; Brent 105.92 per `state.rerisking_limb_status` (10-15), shock acute since 08-01; XOM +2.46% Friday to 178.98 (+5.94% week), implied move 5.68% vs 4.59% (ratio 1.24). (b) Exxon IR (carried). (c) 2026-10-30; first expiry carrying the event 10-30, quoted post-event expiry 11-06. Note: IBKR now lists the equity under `EXXONMOBIL HOLDINGS CORP` (conid 895178251, NYSE) — option chain measured on that line. (d) **Not executable:** ATM straddle $1,017.50 with wide quotes (180C 4.50/5.00). Deferral. (e) **A queue (XOM)**; no open A position. (f) Top-5 (promoted from baseline #8). **Router-PARKED.**

**REST (6-15)** — all **router-PARKED**; Friday close and Friday change are IBKR regular-session (MEASURED); implied move measured only where stated.

| # | Candidate | (a) Hypothesized divergence | (c) Date | Tag | (d) Executability at C $19.48 | (e) A overlap | Fri 10-16 close (chg) / note |
|---|---|---|---|---|---|---|---|
| 6 | **CVX** earnings | As XOM, correlated energy second leg | 2026-10-30 | (C; carried) | Deferral (stock $224.99; any spread > NAV) | A queue (CVX) | 224.99 (+2.59%); week +6.14%; HV30 23.5% |
| 7 | **NFLX** earnings | First print after the summer content slate; straddle 9.44% vs 3.90% realized-equiv. (ratio 2.42, richest) | 2026-10-20 | (C; carried) | Deferral (straddle $666) | not queued | 70.53 (-2.86%); same day as the thesis due date |
| 8 | **GEV** earnings | Grid-capex print after an initiated Sell; stock -8.3% on the week | 2026-10-28 | (C; carried) | Deferral (stock $921) | A queue (GEV) | 921.20 (-0.57%); **same day as FOMC, confounded**; GEV is also an open D position (D, not A or C) |
| 9 | **LLY** earnings | GLP-1 volume vs pricing; +6.6% on the week | 2026-10-29 | (C; carried) | Deferral (stock $1,257) | A queue (LLY) | 1,257.03 (+0.43%); HV30 24.0% |
| 10 | **MRK** earnings | First print after the I-DXd BLA withdrawal | 2026-10-29 | (C; carried) | Deferral | A queue (MRK) | 145.95 (+0.52%) |
| 11 | **META** earnings (replaces JPM) | Post-print repricing; straddle 7.30% vs 5.56% (ratio 1.31) | 2026-10-21 | orchestrator-supplied, unverified | Deferral (straddle $5,175) | A queue (META) | 709.33 (-3.72%); HV30 50.2% |
| 12 | **MSFT** earnings (replaces UNH) | Cloud/AI capex read; straddle 6.04% vs 3.48% (ratio 1.74); wide quotes | 2026-10-28 | orchestrator-supplied, unverified | Deferral (straddle $3,195) | A queue (MSFT) | 529.05 (-1.93%); **same day as FOMC, confounded** |
| 13 | **AAPL** earnings (replaces VTRS) | Services/iPhone print | 2026-11-02 | orchestrator-supplied, unverified | Deferral (stock $343); option chain NOT measured | A queue (AAPL) | 343.46 (+0.43%); HV30 19.8% |
| 14 | **NVDA** earnings (replaces BTAI) | AI-hardware bellwether into the 11-18 print; bars and chain NOT measured this cycle | 2026-11-18 | orchestrator-supplied, unverified | Deferral (not measured; stock far above NAV scale) | A queue (NVDA) | not measured (no IBKR pull this cycle) |
| 15 | **CYTK** PDUFA | Binary label expansion | 2026-11-14 | (E; single source, carried) | Deferral (chain not measured; $61.95 stock) | none | 61.95 (-3.08%); HV30 30.2% |

**(e) A-vs-C exclusivity is vacuous this cycle.** `state.current_positions` holds zero open A and zero open C positions. A-queue membership (AAPL, AMD, CVX, GEV, LLY, META, MRK, MSFT, NVDA, XOM) re-verified against the orchestrator's 44-name A-queue census (identical set to 10-11); TSLA, NFLX, INO, CYTK are not on it.

**Price half of Friday 2026-10-16 (CLOSED, IBKR regular-session daily bars; no news researched, D1's 10-16 narrative is not yet covered).** SPY: 10-12 778.10, 10-13 778.01, 10-14 769.60, 10-15 771.79, **10-16 763.25 (-1.11% day; -1.97% vs 10-09's 778.57)**. TSLA 354.72, INO 0.9901, AMD 528.75, XOM 178.98, NFLX 70.53, CVX 224.99, GEV 921.20, LLY 1,257.03, MRK 145.95, CYTK 61.95, META 709.33, MSFT 529.05, AAPL 343.46 (day changes in the table above; NVDA not pulled).

**Shortlists only.** Full thesis construction per Strategy.md happens in the sessions W4 schedules. Nothing here authorizes an enqueue for any parked name.

---

---

## Coverage, provenance and what this cycle changed

**Read scope.** Weekly cadence. MEASURED or INFERRED is labelled wherever it matters.
- **BigQuery (read-only):** `state.trading_day_today`, `state.current_regime`, `state.current_positions`, `state.open_queue`, `state.rerisking_limb_status`, `state.strategy_capital_enablement`, `state.nomadic_borrow_capacity_watch`, `analytics.strategy_nav`, `state.market_calendar`, `state.routine_catchup_window`, `events.decision_log`, `ops.run_log`, `ops.alerts`.
- **Repo:** `strategy/03_strategy_a.md`, `strategy/05_strategy_c.md`, `strategy/09_regime_scoring_strategy_blind_monthly.md` (the shock-overlay rubric, read only for STEP 1), `Daily.md` (2026-10-15), the Claude_Task_Plan.md W1 section, and the prior `Weekly_Catalyst_Calendar.md`.
- **Live sources:**
  - FMP `calendar/earnings-calendar`: six chunked calls, all by the orchestrator, before any fan-out.
  - IBKR daily bars, the SPY option chain and snapshots (free).
  - Anthropic `web_search` / `web_fetch`, including federalreserve.gov and bls.gov fetches.
- **Tavily was unavailable this session** (the connector needs re-authorization). No step depended on it, because the free surfaces were adequate.

**Orchestration.** Four Sonnet sub-agents did the grunt work: earnings dates, non-earnings/FDA/FOMC, Strategy C measurement and the PART 2A synthesis. The orchestrator did the following itself:
- the shared FMP pull, passed to the sub-agents as provided data that they did not re-fetch;
- every BigQuery read;
- the STEP 1 gate derivation;
- the FDX ruling;
- assembly and validation, including all 57 GATE literals checked for format and for SPENT/SURVIVING consistency against the gate.

**Catch-up window.** `state.routine_catchup_window` gives `window_days` **7.0**, against a weekly 1.5× threshold of 10.5. That is cadence-normal, so no `CATCHUP` token is owed.

**The daily-to-weekly boundary, honoured.** Catalysts reused from in-window D1 records are cited by `entry_id`:
- the SpaceX/Grain spectrum deal, HUM star ratings and MRNA (`bba9dd7a`, `c69c1a3d`);
- IONQ/Elisity, the CCC take-private report, the CXMT DRAM news and the 10-12 Houthi/Brent move (`394b6b39`, `982a5f26`);
- the JNJ miss, AMAT Investor Day, CIFR and FRMI (`c4156ada`);
- hot CPI, the CoreWeave repricing and the DELL/HPE/NTAP downgrades (`c75cac94`, `ab91c8e7`);
- the TSM beat, INTU/NOW and hot PPI (`3e90f4a0`, `2caefda0`);
- the Gulf/Hormuz shipping incidents of 10-13..10-15 (`Daily.md` 2026-10-15).

**No second broad news scan was run.** Web effort went to forward-calendar acquisition, date confirmation and per-candidate documents.

**The FRIDAY-SESSION GAP, closed from IBKR.** D1 has not yet covered Friday 2026-10-16. This is the structural weekly gap, not a D1 outage. The price half was closed at zero cost from IBKR regular-session bars:
- **SPY 763.25** (−1.11% on the day, −1.97% on the week).
- The A top-10 (closes in each PART 2A row): AMD −5.95%, AVGO −4.52%, FSLR −3.45%, CSCO −2.24%; AAPL +0.43% was the only gainer.
- The C panel (PART 2C): META −3.72%, INO −4.80%, XOM +2.46%.

The narrative half of Friday is not chased.

**Standing constraints NOT re-alerted:**
- the FMP earnings-horizon plan cap (`FMP-earn-horizon`);
- the FMP 90-day span clamp (chunking applied, all chunks ≤ 60 days);
- the bulk-enumeration plan gate (`6c4004e3`);
- C's blocked nomadic borrow (`71d484fa`, still OPEN);
- the Friday boundary gap (`b4e4e563`).

The gate-mark enqueue gap `559ee98c` is now RESOLVED. Every PART 2A row carries the STEP 3b fixed-format literal for W4 to copy.

**Open W1 referrals, re-checked and still open with W5 (none re-filed):**
- `99ccd487` (STEP 1 silent on the M1R path). Re-examined in STEP 1: the path is down to one false conjunct (price retraced) after breadth flipped HEALTHY.
- `1876c957` (C's realized-vol window). PART 2C applied the trailing-30-day window again.

**One process finding this cycle, filed as an info alert for W5** (`w1_gate_quiet_clock_qualification_unowned`). STEP 1 tells W1 to apply the quiet-clock leg, but it gives W1 no rule for an event M1a/M1R has not yet ruled qualifying. This cycle that unruled question decides whether the gate is 11-02 or 12-01. W1 resolved it fail-open, using 11-02 as the provable lower bound and listing the 21 names exposed in the band.

**Gate-relevant dates NOT re-verified this run (stated, not implied):**
- MRK ESMO 10-26, NVDA GTC Berlin, CAT Fabick, INO 10-30, GSK, FSLR Sec 232 (12-04) and USTR 11-10. These are carried.
- GOOGL 10-28, PLTR 11-02, UBER 11-04 and TTWO's FQ2 date are still (E) with no company notice found.
- Oracle AI World: the dates conflict between 10-25→28 and 10-26→29.
- MSFT Ignite and AMZN re:Invent are third-party listings only, so they were downgraded to (E). Both names survive the gate ONLY on these conference dates, because their earnings (10-28 and 10-29) are spent.

**What moved this cycle, in one place.**
- **Gate:** 2026-11-02 for a sixth cycle, now as a fail-open lower bound.
  - The price leg moved further from clearing (Brent 104.28 → 105.92 on the view; required fall −7.23% → −8.67%).
  - The quiet clock clears no earlier than 11-03 to 11-05 if any 10-13..10-15 Gulf incident qualifies.
  - Breadth flipped HEALTHY (51.88), leaving the M1R path one conjunct short.
- **Ranking:** 12 spent and 45 surviving (was 14 and 43).
  - BAC and V moved to surviving: BAC printed and its next print is 2027-01-15; V's DOJ discovery moved to 2027-01-29.
  - XOM left the top-10, and AAPL and AMZN joined it.
  - ORCL fell #9 → #11 on the CoreWeave credit scare.
  - Zero new A queue intake for the seventh cycle; the census is 44, an identical set.
- **Provenance:** the eight (E)→(C) earnings upgrades listed in the header; COGT resolved into two separate NDAs (11-30 and 12-30, both (C)); AGIO 11-01 (C); the Enspryng PDUFA was approved 10-16. FOMC 10-27/28 (no SEP) and 12-08/09 (SEP) were confirmed at federalreserve.gov; only 10-28 falls in the C window.
- **Strategy C:** HYBRID ACTIVATE (FOMC-only) is unchanged.
  - Implied re-widened after the sell-off: IV/HV30 is ≈ 1.44, up from 1.14.
  - The first SPY expiry after the FOMC is now 10-29.
  - No structure is executable at the $19.48 NAV; the cheapest 1-wide SPY debit spread is $37–47.
  - UNH, JPM and VTRS are struck because their events passed. BTAI is struck as untradeable (IBKR resolves it only as BTAIQ on PINK).
  - META, MSFT, AAPL and NVDA were added.

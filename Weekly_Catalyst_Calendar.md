2026-W41

# Weekly Catalyst Calendar — Strategies A and C

**Run date 2026-10-11** (Sunday, `weekly_sun`). ISO week of TODAY's run date, 2026-W41. The upcoming trading week opens Monday 2026-10-12; that is context, not the marker.

**Windows.** Strategy A: 6 months, **2026-10-11 → 2027-04-11**. Strategy C: 45 days, **2026-10-11 → 2026-11-25**.

**EFFECTIVE CONFIRMED-EARNINGS HORIZON: 2026-12-18 — 68 days, ~9.7 weeks from 2026-10-11. The terminal date did NOT move** (CCL 2026-12-18, identical to last week); depth fell 75 → 68 days only because the clock advanced seven days. Six-week series (terminal date / days from that week's run date): 2026-12-03/88d (09-06), 2026-12-09/87d (09-13), 2026-12-09/80d (09-20), 2026-12-10/74d (09-27), 2026-12-18/75d (10-04), **2026-12-18/68d (10-11)**. Last week's +8-day jump was a one-off batch roll, not a trend: the date has held a full week while depth erodes about a day per day. Coverage shape (MEASURED): dense 2026-10-12 → 2026-11-24 (69 rows); 2026-11-25 → 12-02 empty (Thanksgiving week); five December rows (DOCU 12-03, ADBE 12-09, COST 12-10, NKE 12-17, CCL 12-18); 2026-12-19 → 2027-01-10 empty; then an isolated tail of seven rows (TLRY 2027-01-11, DAL 01-12, FDX 02-02, PEP 02-02, TSLA 02-03, RIVN 02-25, FDX 03-25); nothing after 2027-03-25. Well short of the ~13 weeks the plan documents (standing plan-tier constraint, `FMP-earn-horizon` in `OWNER_ACTIONS.md`; deliberately NOT re-alerted).

**Every count in PART 1 is a FLOOR.** Universe enumeration is impossible on this plan tier (`search/search-company-screener`, every `directory.*` route and `quote/batch-quote` are tool-level ACCESS DENIED). PART 1A is built over the 81 reachable vendor calendar rows (17 + 40 + 12 + 5 + 7 across the chunked calls) plus the 44-row live A queue and the carried PART 2A candidate set, including the DIRECTION-INADMISSIBLE tier. Not re-alerted (`ops.alerts` `6c4004e3`, standing).

**FMP silent partial, measured this cycle.** A single wide call 2026-12-01 → 2027-04-11 returned the seven tail rows but silently omitted all five December rows (DOCU, ADBE, COST, NKE, CCL) that a narrow 12-01 → 12-31 call returns, with no error. Chunked calls, diffed against each other, are the mitigation (details in 1A.9).

**The cycle's change is provenance again.** Ten more earnings dates became company-issued (C): AMD 11-03, INTC 10-29 (moved +7 days), NOW 10-28, VRTX 11-02, AKAM 11-05 (was undated), AAPL 11-02 (moved +4 days; read through a MacTrast relay of Apple's IR notice), IBM 10-21 (preliminary now firm), ABBV 10-30, WFC 10-13, RBLX 10-29. Large caps still without a company notice: MSFT, GOOGL, META, AMZN, XOM, FSLR, CAT, TTWO, DDOG, CSCO, PLTR, UBER. DAL (10-09), PEP (10-08) and TLRY (10-08) printed and are struck.

---

## PART 1A — Strategy A universe, 6-month window (2026-10-11 → 2027-04-11)

No interpretation in this PART. Provenance tags: **(C)** company- or primary-source confirmed · **(E)** estimated (vendor or aggregator projection) · **(T)** tentative, no firm day · **(2S)** two-source tracker agreement. "Δ" marks a change against the 2026-10-04 artifact. Baseline (C) rows marked "carried" were NOT re-read this run; FMP agrees with every one that FMP lists.


### 1A.1 — Earnings, inside the 45-day C window (2026-10-11 → 2026-11-25)

| Ticker | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| C · GS · JNJ | Citigroup · Goldman Sachs · J&J | Earnings | 2026-10-13 | (E) | FMP bulk |
| JPM | JPMorganChase | Earnings (~07:00 ET) | 2026-10-13 | **(C)** | company Business Wire release 2026-09-17, via syndicated copy (carried) |
| UNH | UnitedHealth | Earnings (BMO) | 2026-10-13 | **(C)** | unitedhealthgroup.com (carried) |
| WFC | Wells Fargo | Earnings (~07:00 ET, call 10:00 ET) | 2026-10-13 | **(C)** | newsroom.wf.com release, search excerpt. **Δ** upgraded E→C |
| BAC | Bank of America | Earnings | 2026-10-14 | **(C)** | newsroom.bankofamerica.com (carried) |
| TSM | Taiwan Semiconductor | Earnings | 2026-10-15 | (E) | FMP bulk — A-INELIGIBLE, ADR |
| TRV | Travelers | Earnings | 2026-10-16 | (C) | issuer-confirmed per M2 `50d589a2` (carried) |
| GE | GE Aerospace | Earnings (BMO) | 2026-10-20 | **(C)** | geaerospace.com (carried); FMP agrees |
| GM | General Motors | Earnings | 2026-10-20 | (E) | FMP bulk |
| NFLX | Netflix | Earnings | 2026-10-20 | **(C)** | Netflix release 2026-09-14 (carried); FMP agrees |
| UAL | United Airlines | Earnings (AMC; call 10-21) | 2026-10-20 | **(C)** | United release (carried); FMP agrees |
| CB | Chubb | Earnings call | 2026-10-21 | (C) | issuer-confirmed per M2 `50d589a2` (carried) |
| IBM | IBM | Earnings (call 17:00 ET) | 2026-10-21 | **(C)** | newsroom.ibm.com release 2026-10-07, Tavily excerpt. **Δ** no longer "preliminary" |
| T | AT&T | Earnings | 2026-10-21 | (E) | FMP bulk |
| TSLA | Tesla | Earnings (AMC) | 2026-10-21 | **(C)** | ir.tesla.com (carried). **FMP now also shows 10-21** — the vendor row was corrected from 10-28 |
| AAL | American Airlines | Earnings | 2026-10-22 | **(C)** | news.aa.com (carried); FMP agrees |
| LMT | Lockheed Martin | Earnings | 2026-10-22 | (E) | FMP bulk |
| NOK | Nokia | Earnings | 2026-10-22 | (E) | FMP bulk — A-INELIGIBLE, ADR |
| VZ | Verizon | Earnings | 2026-10-26 | (E) | FMP bulk |
| BA · CARR* · HCA · HOOD · KO · PYPL · SOFI · V | — | Earnings | 2026-10-27 | (E) | FMP bulk. *CARR **Δ +2d**: FMP now 10-29, listed below |
| F · GOOGL · META · MGM · MSFT | Ford · Alphabet · Meta · MGM · Microsoft | Earnings | 2026-10-28 | (E) | FMP bulk. No company notice found for GOOGL, META, MSFT (searches 2026-10-11; Meta's 2025 notice came 10-01, so absence is notable but not a date change) |
| GEV | GE Vernova | Earnings (BMO) | 2026-10-28 | **(C)** | gevernova.com (carried) |
| NOW | ServiceNow | Earnings (AMC, call 14:00 PT) | 2026-10-28 | **(C)** | newsroom.servicenow.com release 2026-10-07, search excerpt. **Δ** E→C |
| ~~FDX~~ | ~~FedEx~~ | ~~Earnings~~ | ~~2026-10-28~~ | (T) | FMP row **REJECTED AS SUSPECT, fifth cycle** (1A.9) |
| AAPL | Apple | Earnings (AMC, call 17:00 ET) | **2026-11-02** | **(C)** | Apple IR notice as relayed by MacTrast 2026-10-06 (first-party page fetch returned no event data). FMP also 11-02. **Δ +4d** (baseline 10-29, which a countdown site flagged as unconfirmed) |
| AMZN · CARR · COIN · INTC* · RBLX* · RIOT · RIVN · RKT · SBUX* · SIRI · FSLR | — | Earnings | 2026-10-29 | (E) unless marked | FMP bulk (FSLR aggregator-only, no company notice found). *INTC **(C)** intc.com release 2026-10-06, **Δ +7d** (baseline 10-22 E). *RBLX **(C)** ir.roblox.com release, Tavily excerpt. *SBUX **Δ +1d** (was 10-28) |
| CAT | Caterpillar | Earnings (call 08:30 ET per one source) | 2026-10-29 | (E) | TradingKey 2026-10-08 ("published 2026 earnings schedule"); same date as 2025 pattern. TIKR 2026-10-08: "has not confirmed". No CAT advisory yet. **Δ** was NOT ESTABLISHED |
| LLY | Eli Lilly | Earnings | 2026-10-29 | **(C)** | investor.lilly.com (carried) |
| MRK | Merck | Earnings | 2026-10-29 | **(C)** | merck.com (carried) |
| ABBV | AbbVie | Earnings (BMO, call 08:00 CT) | 2026-10-30 | **(C)** | AbbVie release 2026-10-01 (finviz/investingnews copies, search excerpt). **Δ** E→C |
| CVX | Chevron | Earnings call (11:00 ET) | 2026-10-30 | **(C)** | Chevron advisory (carried); FMP agrees |
| XOM | ExxonMobil | Earnings | 2026-10-30 | (E) | FMP bulk. No XOM notice yet (2025 notice came 10-13). One tracker (Bullstory, no source) says 10-23, uncorroborated |
| PLTR | Palantir | Earnings | 2026-11-02 | (E) | FMP bulk; AJ Bell calendar says 11-03; no company notice |
| VRTX | Vertex | Earnings (AMC, call 16:30 ET) | 2026-11-02 | **(C)** | Vertex release 2026-10-07 (BioSpace / finviz copies, search excerpt). **Δ** E→C |
| FUBO | fuboTV | Earnings | 2026-11-02 | (E) | FMP bulk — A-INELIGIBLE, cap floor |
| AMD | AMD | Earnings (AMC, call 17:00 ET) | 2026-11-03 | **(C)** | ir.amd.com release 2026-10-06, search excerpt. **Δ** E→C |
| ET · PINS · PFE · SHOP | — | Earnings | 2026-11-03 | (E) | FMP bulk (ET row last updated 10-06) |
| SMCI | Super Micro | Earnings | 2026-11-03 | (E) | aggregator (carried); no company notice (2025 FQ1 was 11-04) |
| UBER | Uber | Earnings | 2026-11-04 | (E) | FMP bulk. **Δ +1d** (was 11-03); one tracker says 11-02. Baseline's 10-29 aggregator claim not reproduced this run |
| ETSY · SNAP | — | Earnings | 2026-11-04 | (E) | FMP bulk |
| AKAM | Akamai | Earnings (call 16:30 ET) | 2026-11-05 | **(C)** | Akamai release 2026-10-08 (akamai.com newsroom / finviz, search excerpt). **Δ** was UNDATED (11-05/11-10 split) |
| DDOG · TTWO | Datadog · Take-Two (FQ2) | Earnings | 2026-11-05 | (E) | aggregators (carried); no notice yet (2025 notices 10-16 and 10-09) |
| MRNA · ROKU | — | Earnings | 2026-11-05 | (E) | FMP bulk. ROKU **Δ +1d** (was 11-04) |
| LCID | Lucid | Earnings | 2026-11-09 | (E) | FMP bulk — A-INELIGIBLE, cap floor. **Δ +5d** (was 11-04) |
| SONY | Sony | Earnings | 2026-11-10 | (E) | FMP bulk — A-INELIGIBLE, ADR |
| CSCO | Cisco | Earnings | 2026-11-11 | (E) | FMP bulk; one calendar says 11-10; no notice (2025 notice came 11-03) |
| QCOM | Qualcomm | Earnings (AMC) | 2026-11-11 | (E) | aggregator (carried) |
| NBIS | Nebius | Earnings (BMO) | 2026-11-11 | (E) | Earnings Whispers + AJ Bell forecast; no company notice (2025 notice came 10-22). **Δ** narrowed from a 10-22/11-10 split |
| AMAT | Applied Materials | Earnings (AMC) | 2026-11-12 | (E) | aggregator (carried) |
| BILI | Bilibili | Earnings | 2026-11-12 | (E) | FMP bulk — A-INELIGIBLE, ADR |
| DIS | Disney | Earnings | 2026-11-12 | (E) | FMP bulk |
| PANW | Palo Alto Networks | Earnings (FQ1 FY27) | 11-12 or 11-18 | (T) | aggregators conflict (carried); no notice (2025 notice came 11-04 for 11-19) |
| BIDU | Baidu | Earnings | 2026-11-17 | (E) | FMP bulk — A-INELIGIBLE, ADR |
| HD | Home Depot | Earnings (BMO) | 2026-11-17 | (E) | aggregator, "unconfirmed" (carried) |
| NVDA | NVIDIA | Earnings | 2026-11-18 | (E) | FMP bulk; one aggregator 11-17 |
| TGT | Target | Earnings | 2026-11-18 | **(C)** | corporate.target.com (carried); FMP agrees |
| WMT | Walmart | Earnings | 2026-11-19 | **(C)** | corporate.walmart.com (carried); FMP agrees. Moved here from baseline 1A.2 because the window now runs to 11-25 |
| ZM | Zoom | Earnings | 2026-11-23 | (E) | FMP bulk |
| DELL | Dell Technologies | Earnings | 2026-11-24 | (E) | aggregator (carried) |
| BABA · NIO | — | Earnings | 2026-11-24 | (E) | FMP bulk — A-INELIGIBLE, ADR |

### 1A.2 — Earnings, 2026-11-26 → dense horizon 2026-12-18

2026-11-25 → 2026-12-02 returned **zero** vendor rows (separate probe).

| Ticker | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| CRWD · NTAP | CrowdStrike (AMC) · NetApp | Earnings | 2026-12-01 | (E) | aggregators (carried); not in FMP |
| OKTA | Okta | Earnings (AMC) | 12-01 or 12-02 | (E) | aggregators conflict by a day (carried) |
| SNOW | Snowflake | Earnings | 2026-12-02 | (E) | aggregator (carried) |
| DOCU | DocuSign | Earnings | 2026-12-03 | (E) | FMP bulk |
| HPE | Hewlett Packard Enterprise | Earnings (AMC) | 2026-12-03 | (E) | aggregator (carried) |
| ADBE | Adobe | Earnings | 2026-12-09 | (E) | FMP bulk |
| AVGO | Broadcom (FQ4) | Earnings (AMC) | 2026-12-09 | (E) | aggregator (carried); not in FMP |
| COST | Costco | Earnings | 2026-12-10 | (E) | FMP bulk |
| ORCL | Oracle (FQ2) | Earnings | 2026-12-10 | (E) | calendar sites (days.to, financecalendar, Trendlyne) agree on 12-10 after last week's 12-10/12-14 split; no company notice (2025 notice came 12-02). FQ1 printed 2026-09-10 |
| NKE | Nike (FQ2) | Earnings | 2026-12-17 | (E) | FMP bulk |
| CCL | Carnival (Q4) | Earnings | 2026-12-18 | (E) | FMP bulk — terminal row of the dense horizon |

### 1A.3 — Earnings, 2026-12-19 → 2027-04-11

Structurally almost empty: 2026-12-19 → 2027-01-10 returned zero rows, and after 2027-03-25 nothing. This is a coverage gap, not an absence of events.

| Ticker | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| MU | Micron (FQ1) | Earnings | 2026-12-23 | (E) | aggregator (carried); FQ4 printed 2026-09-30; not in FMP |
| TLRY | Tilray | Earnings | 2027-01-11 | (E) | FMP tail row — A-INELIGIBLE, cap floor |
| DAL | Delta (Q4) | Earnings | 2027-01-12 | (E) | FMP tail row. **New**; DAL printed Q3 on 2026-10-09 |
| MRK | Merck | Q4 call | 2027-02-02 | (C) | merck.com (carried) |
| PEP | PepsiCo (Q4) | Earnings | 2027-02-02 | (E) | FMP tail row. **New**; PEP printed Q3 on 2026-10-08 |
| TSLA | Tesla | Earnings | 2027-02-03 | (E) | FMP tail row |
| RIVN | Rivian | Earnings | 2027-02-25 | (E) | FMP tail row |
| FDX | FedEx | Earnings | 2027-03-25 | (E) | FMP tail row; the one FedEx row that fits its fiscal calendar (retained). FDX 2027-02-02 stays rejected (1A.9) |
| MRK | Merck | Q1 call | 2027-04-29 | (C) | merck.com (carried); outside the 04-11 edge, named so it is not re-discovered |

Undated Q4/Q1 names (no row possible): CRM, MRVL (early December by pattern, INFERRED), INTU (late November by pattern, INFERRED); see 1A.10.

### 1A.4 — Product launches, keynotes, developer events

| Ticker | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| NVDA | NVIDIA | GTC Berlin (keynote 10-21, Tempodrom) | 2026-10-20 → 10-22 | **(C)** | **upgraded from (E)**: NVIDIA's own GTC FAQ page per search result 2026-10-11 (page itself not fetched) |
| ORCL | Oracle | CloudWorld | 2026-10-25 → 10-28 | (C) | carried; gate-relevant, not re-verified this run (budget) |
| ADBE | Adobe | Adobe MAX | 2026-11-10 → 11-12 | (E) | carried |
| MSFT | Microsoft | Ignite | 2026-11-17 → 11-20 | (C) | carried |
| TTWO | Take-Two | **GTA VI launch** | 2026-11-19 | (C) | carried, not re-verified this run; preload 11-12 |
| AMZN | Amazon | re:Invent | 2026-11-30 → 12-04 | (C) | carried |
| NVDA | NVIDIA | GTC Washington DC | 2026-11-30 → 12-03 | (E) | carried |
| GOOGL | Alphabet | Waymo multi-city robotaxi launches | 2026 (year only) | (T) | carried |
| — | broad | CES 2027 | 2027-01-06 → 01-09 | (E) | carried |
| NVDA | NVIDIA | GTC 2027 San Jose | 2027-03-15 → 03-18 | (C) | carried |

Struck as PAST (see 1A.9): DIS Believe ship reveal (10-07), META enterprise-AI launch (09-28, divergence record only).

### 1A.5 — Analyst and investor days

| Ticker | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| BGC | BGC Group | FMX Investor Day | 2026-10-13 | (C) | carried; gate-relevant (before 11-02), not re-verified |
| WDAY | Workday | Financial Analyst Day | 2026-10-13 | (C) | carried; see 1A.7 for the unverified take-private report |
| MRK | Merck | Investor event at ESMO 2026 (webcast) | 2026-10-26 | (C) | carried (merck.com events page, W40) |
| NKE | Nike | Investor day, "Fall 2026" | — | (T) | carried, no day |
| UNH | UnitedHealth | Investor conference | ~2026-12 early | (E) | carried |
| JPM | JPMorganChase | Investor Day | 2027-02-22 | (C) | carried |

Dropped as PAST: MRVL Investor Day (held 2026-10-06; FY28 ~$20B outlook, MRVL +5.81%, D1 `7ac0f2f6`). It was not a baseline row. No new investor-day dates surfaced in D1 records; no broad investor-day calendar sweep was run.

### 1A.6 — Regulatory, legal, trade and macro

PDUFA rows are mirrored in 1B.3. Dates for the new PDUFA rows come from one aggregator (Assyro, fetched 2026-10-11), so they are (E) unless carried from baseline.

| Ticker | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| — | broad | CPI release (September) | 2026-10-14 | (E) | cited in D1 park-allocation `95adacb5`/`8fb124e9`; BLS schedule not fetched |
| V | Visa | DOJ fact discovery closes | 2026-10-16 | (C) | carried; gate-relevant, not re-verified |
| RHHBY | Roche | Enspryng (satralizumab) PDUFA, thyroid eye disease | **2026-10-15** | (E) | **day now given** by Assyro (was "Oct, no day"); single source. ADR |
| VTRS | Viatris / Opus | MR-141 PDUFA (presbyopia) | 2026-10-17 | (2S) | carried; Assyro re-lists same day |
| GSK | GSK | Bepirovirsen PDUFA (chronic hep B) | 2026-10-26 | (C) | carried; Assyro re-lists. ADR |
| — | broad | **FOMC decision** | **2026-10-28** | (C) | **RE-CONFIRMED** federalreserve.gov fetch 2026-10-11 (Oct 27–28, no SEP) |
| — | broad | US midterm elections | 2026-11-03 | (C) | statutory date; context: Trump said 10-08 the US would not resume strikes on Iran before it (OGJ 2026-10-08) |
| INO | Inovio | INO-3107 BLA PDUFA (RRP) | 2026-10-30 | (C) | carried; Assyro re-lists |
| AGIO | Agios | Mitapivat PDUFA | 2026-11-01 | (E) | **NEW**, Assyro single source (a Sunday) |
| — | broad | USTR Sec 301 exclusions expire | 2026-11-10 | (C) | carried |
| BTAI | BioXcel | BXCL501 (IGALMI) at-home sNDA PDUFA | 2026-11-14 | (2S) | carried; Assyro re-lists |
| CYTK | Cytokinetics | Aficamten (MYQORZO) oHCM NDA PDUFA | 2026-11-14 | (E) | carried; Assyro agrees |
| SMMT | Summit | Ivonescimab + chemo BLA PDUFA | 2026-11-14 | (E) | **conflict**: W40 rejected it as a filing date; Assyro now lists it as a BLA PDUFA. Single source, low confidence |
| Beren | Beren Therapeutics | Adrabetadex PDUFA | 2026-11-17 | (2S) | carried; Assyro re-lists |
| UNP·NSC | Union Pacific / Norfolk Southern | STB comments due | 2026-11-18 | (C) | carried |
| CAPR | Capricor | Deramiocel PDUFA | 2026-11-22 | (C) | carried; Assyro agrees |
| SVRA | Savara | Molgramostim PDUFA | 2026-11-22 | (2S) | carried; Assyro agrees |
| SAN (ADR) | Sanofi | Venglustat PDUFA | 2026-11-25 | (E) | **NEW**, Assyro. ADR |
| BBIO | BridgeBio | BBP-418 (LGMD2I/R9) NDA PDUFA | 2026-11-27 | (E) | carried; Assyro agrees |
| NUVL | Nuvalent | Neladalkib PDUFA | 2026-11-27 | (E) | **NEW**, Assyro + search snippet |
| PYPD | PolyPid | D-PLEX100 PDUFA | 2026-11-28 | (E) | **NEW**, Assyro; cap very likely < $2B (unmeasured) |
| VRTX | Vertex | Povetacicept PDUFA | 2026-11-30 | (C) | carried; Assyro agrees; D2 `dde6be0a` (10-07) did not re-confirm |
| RHHBY | Roche | Giredestrant PDUFA | 2026-11-30 | (E) | **NEW**, Assyro. ADR |
| COGT | Cogent | Bezuclastinib PDUFA | 2026-11-30 **or 2026-12-30** | (E) | **date conflict**: Assyro 11-30; a search snippet cites a calendar and checkrare at 12-30 "per the company". Unresolved; 12-30 reported as likelier |
| UNP·NSC | Union Pacific / Norfolk Southern | DOJ/USDOT comments | 2026-12-03 | (C) | carried |
| FSLR | First Solar + solar | Sec 232 tariff regime effective | 2026-12-04 | (C) | carried, not re-verified |
| VRTX | Vertex | Journavx sNDA PDUFA | 2026-12-05 | (2S) | carried |
| — | broad | **FOMC decision** | **2026-12-09** | (C) | federalreserve.gov fetch 2026-10-11 (Dec 8–9, SEP) |
| — | broad | US government funding: CR runs to 12-11 | 2026-12-11 | (E) | carried |
| BA | Boeing | FAA 737 MAX 10 certification "by year-end 2026" | — | (T) | carried |
| PRAX | Praxis | Relutrigine PDUFA | 2026-12-27 | (2S) | carried |
| DYN | Dyne | Z-rostudirsen PDUFA | 2027-01-21 | (C) | carried |
| — | broad | **FOMC decision** | 2027-01-27 | (C) | federalreserve.gov (page marks 2027 tentative) |
| PHAR | Pharming | Joenja lower-dose sNDA PDUFA | 2027-01-30 | (C) | carried |
| UNP·NSC | Union Pacific / Norfolk Southern | STB responses due | 2027-02-16 | (C) | carried |
| BMRN | BioMarin | VOXZOGO full approval | 2027-02-28 | (C) | carried |
| SRPT | Sarepta | AMONDYS 45 / VYONDYS 53 sNDAs | 2027-02-28 | (C) | carried; cap near floor, re-measure |
| LYV | Live Nation | DOJ/states remedies phase | ~2027-02 | (E) | carried |
| WBD | Warner Bros Discovery (acq. PSKY) | Antitrust trial begins | 2027-03-02 | (C) | carried |
| EXEL | Exelixis | Zanzalintinib PDUFA (mCRC) | 2027-03-03 | (E) | carried |
| — | broad | **FOMC decision** | 2027-03-17 | (C) | federalreserve.gov (tentative) |
| — | broad | **FOMC decision** | 2027-04-28 (outside window, 04-11) | (C) | named only; page lists 2027 Apr 27–28 |

Policy context recorded from D1 (not dated catalysts): FTC/USDA farm-equipment RFI hit XLI/DE/CAT on 2026-10-07 (D1 `e863504e`, `434a6738`; no comment deadline recorded in the warehouse and none searched). FOMC minutes (10-07) were read by D1 as signalling another hike by year-end. IEA agreed 10-07 to accelerate deliveries under the emergency stock release; ~325M bbl released since March, ~100M bbl still available (OGJ 2026-10-08).

Beyond the window: FTC v. Amazon trial ~2027-03-29 (E).

### 1A.7 — Restructuring, M&A and structural

| Ticker | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| PCRX | Pacira | **Viatris $36.50 cash acquisition** (~$1.43–1.65B) | announced 2026-10-08; close undated | (C) announce / (T) close | **NEW**, D1 `8e407ff8`. PCRX +44.4%; FAILS the $2B cap rail, so not an A candidate. VTRS side: no deal terms beyond D1 |
| PTC | PTC | Schneider $205 cash acquisition | announced 2026-10-05; close undated | (C) announce | **NEW**, D1 `0e8fe4c3` (PTC +33.5%, deal-pinned) |
| OPCH | Option Care Health | CD&R / McKesson $32.05 cash take-private | announced 2026-10-06; close undated | (C) announce | **NEW**, D1 `7ac0f2f6` |
| ON·SYNA | onsemi / Synaptics | Revised all-cash deal | 2026-10-01; close undated | (C) announce | **NEW**, D1 `d5ee1347` |
| UBER | Uber | ezCater $2.3B acquisition | announced 2026-10-06; close undated | (C) announce | **NEW**, D1 `513dcd0c` |
| CMG·SBUX | Chipotle / Starbucks | FT report that Starbucks explored a takeover; no comment from either | 2026-10-08 | (T) | **NEW, UNCONFIRMED**, D1 `8e407ff8`; media rumour, not a fact |
| ORCL | Oracle | WSJ report of financing for OpenAI capacity (with Broadcom); ORCL −5.5% | 2026-10-07/08 (publish time unresolved) | (T) | **NEW**, D1 `8e407ff8`; unconfirmed report |
| CVX·HESM | Chevron / Hess Midstream | Chevron restructuring (HESM −14.6%) | 2026-10-07 | (C) | **NEW**, D1 `e863504e`; details not in warehouse |
| WDAY | Workday | Reported take-private target | undated | (T) | carried, still UNVERIFIED; no new source |
| VRTX | Vertex | Crinetics closed; ~$8.8B IPR&D charge in Q3 | closed 2026-09-01 | (C) / (E) | carried; lands in the 11-02 print |
| CAT | Caterpillar | Fabick dealer acquisition, close late Oct | late Oct 2026 | (T) | carried, single aggregator |
| SWKS·QRVO | Skyworks / Qorvo | $22B merger, cleared all but 2 jurisdictions | undated | (C) | carried |
| KMB·KVUE | Kimberly-Clark / Kenvue | Merger close; outside date auto-extends | 2026-11-02 → 2027-05-03 | (T) | carried |
| TECK | Teck Resources | Anglo American–Teck; China MOFCOM last pending | spans window | (C) | carried |
| CTVA | Corteva | "Vylor" spin-off (CTVA −5.2% on 10-02 as a spin-off tail, D1 `d5ee1347`) | Q4 2026 | (T) | carried |
| — | broad | Nasdaq-100 annual reconstitution | mid-2026-12 | (E) | carried |
| — | broad | S&P 500 Q4 rebalance | 2026-12-18 | (E) | carried |
| DG | Dollar General | CEO transition | 2027-01-01 | (C) | carried |
| BA | Boeing | SVP Finance → Controller succession | — | (C) | carried |
| — | broad | S&P 500 Q1 2027 rebalance | 2027-03-19 | (E) | carried |
| CEG·GOOGL | Constellation / Alphabet | 890 MW nuclear PPA | 2026-10-06 | (C) | PAST, D1 `7ac0f2f6`; recorded (CEG +12.2%, XLU +2.98%) |

Narrative-only: UBER ~3,300-role restructuring (margin effect in the Q3 print). C.H. Robinson / RXO (RXO +22.5%, CHRW −10.8% on 10-05, D1 `0e8fe4c3`): the underlying event is not described in the warehouse text, so no row.

### 1A.8 — Universe rails, MEASURED

**Market-cap rail (≥ $2B).** The 61-name measurement of 2026-10-04 (44-row A queue + 17 candidates/tier names; 0 FAIL; smallest AAL $8.57B 4.3×, AKAM $15.84B, FSLR $18.77B, SMCI $28.26B, OKTA $35.13B) is **CARRIED FORWARD, dated 2026-10-04, not re-measured this run** (no cap-sensitive price move was reported in the brief). Smallest caps remain ≥ 4× the floor, so a one-week carry cannot flip a verdict.

**New measurement this run (MEASURED 2026-10-09 via `company/batch-market-cap`).** One call on 50 vendor-calendar names not in the 61: **50 requested, 50 returned, diff empty** (no silent drop this time). Smallest: **RIOT $6.39B (3.2×)** · ETSY $7.28B · MGM $7.36B · SIRI $8.94B · SNAP $10.53B · DOCU $13.57B · PINS $13.61B · RIVN $16.95B · SOFI $20.27B · ROKU $22.67B; the rest are $28B–$1.5T (TSLA 1,511B, WMT 886B, V 720B). **0 FAIL on cap among the 50.** Share-count-lag caveat (`ops/connector_tools.yaml`) binds only inside 3× of the rail ($6B): RIOT at 3.2× is the one name close enough to note. Full 50: RIOT 6.39 · ETSY 7.28 · MGM 7.36 · SIRI 8.94 · SNAP 10.53 · DOCU 13.57 · PINS 13.61 · RIVN 16.95 · SOFI 20.27 · ROKU 22.67 · ZM 28.66 · RKT 32.42 · RBLX 34.35 · CARR 45.80 · COIN 47.33 · PYPL 47.50 · F 48.53 · NKE 51.36 · FDX 69.01 · ET 71.30 · GM 74.83 · MRNA 89.28 · ADBE 96.30 · HCA 97.66 · HOOD 98.02 · SBUX 103.46 · LMT 117.61 · BA 150.46 · T 151.99 · PFE 161.18 · PEP 172.08 · VZ 173.91 · DIS 187.63 · SHOP 221.70 · C 222.30 · WFC 252.66 · GS 264.13 · NFLX 292.72 · GE 319.78 · UNH 344.46 · KO 378.84 · BAC 385.49 · COST 419.94 · PLTR 479.99 · ABBV 488.47 · JNJ 630.04 · V 719.65 · WMT 886.13 · TSLA 1,511.49 ($B).

**FAIL the cap floor, A-ineligible (carried):** TLRY, LCID, FUBO.

**ADR / instrument rail (carried):** TSM `isAdr` TRUE → A-ineligible. NOK, SONY, BILI, BIDU, BABA, NIO ADRs carried. NBIS, SHOP, CCL passed (ordinary US-listed shares). Not re-measured.

### 1A.9 — Rows struck, rejected or corrected this cycle (earnings and non-earnings)

**Earnings.**
**Printed 2026-10-05 → 2026-10-09 (struck from forward tables; FMP rows carry `epsActual`):**
1. **~~DAL~~ — PRINTED 2026-10-09** (BMO): EPS 1.72 vs 1.77 est; revenue $20.20B vs $17.65B est (FMP). Was the (C) row in baseline 1A.1 and PART 1B.2. Next print: 2027-01-12 (E, FMP tail).
2. **~~PEP~~ — PRINTED 2026-10-08**: EPS 2.34 vs 2.29 est; revenue $25.27B vs $24.95B est (FMP; PepsiCo's own Q3 release PDF also surfaced in search). Next: 2027-02-02 (E).
3. **~~TLRY~~ — PRINTED 2026-10-08**: EPS −0.32 vs −0.181 est; revenue $257.1M vs $266.3M est (FMP). A-INELIGIBLE (cap floor). Next: 2027-01-11 (E).
(No other baseline row in 10-05 → 10-09 existed. FMP lists exactly these three printed rows for that span.)

**Moved or corrected:**
4. **AAPL 2026-10-29 (E) → 2026-11-02 (C).** Apple's IR notice (relayed 10-06) sets Monday 11-02 AMC; FMP agrees. The 10-29 date was a third-party estimate. The new date sits ON the gate date 2026-11-02 (relevant to gate classification; classification itself is not made here).
5. **INTC 2026-10-22 (E) → 2026-10-29 (C).** intc.com release 2026-10-06 supersedes the estimate (Δ +7d); FMP follows.
6. **IBM 2026-10-21 "preliminary" → firm (C)** after IBM's 10-07 release.
7. **TSLA:** baseline noted FMP's 10-28 as wrong (company: 10-21). **FMP now shows 10-21**; the vendor correction landed. Item closed.
8. **CAT: baseline "NOT ESTABLISHED" → 2026-10-29 (E).** Single-source (TradingKey "published schedule") plus 2025 pattern; the company has not issued its advisory (TIKR 10-08: not confirmed). Treat as (E), not (C).
9. **UBER 2026-11-03 → 11-04 (FMP)**; the baseline's conflicting 10-29 aggregator claim is not reproduced (a tracker now says 11-02). All current candidates are ≥ 2026-11-02.
10. **ORCL ~12-10/12-14 → 2026-12-10 (E)** (three calendar sites agree); **NBIS 10-22/11-10 split → 2026-11-11 (E)**; **AKAM 11-05/11-10 split → 2026-11-05 (C)**.
11. **~~FDX 2026-10-28~~ and ~~FDX 2027-02-02~~ — REJECTED AS SUSPECT, fifth cycle.** FMP still returns both. FedEx FY ends 31 May; quarters end Aug/Nov/Feb/May; a late-October print fits no quarter. Only 2027-03-25 is retained. Reasoned rejection on fiscal arithmetic; FedEx IR not reached.
12. **FMP silent partial (process note):** a single wide call 2026-12-01→2027-04-11 omitted five December rows (see header block). Not an alert-class event; chunking is the mitigation.

**Non-earnings — struck this cycle** (occurred 2026-10-04 → 10-10):
13. **~~RHHBY Tecentriq (+ Tecentriq Hybreza) PDUFA 2026-10-09~~ — APPROVED 2026-10-09** (stage III dMMR colon; Roche release `med-cor-2026-10-09` and Healio/PharmExec 10-09 per search results; Roche pages not fetched). Struck from 1A.6 and 1B.3.
14. **~~DIS Disney Believe ship reveal 2026-10-07~~ — PAST.** Date was (E), single secondary source. No outcome found; no D1 record of a DIS move. Struck without outcome.
15. **~~MRVL Investor Day~~ — HELD 2026-10-06**: FY28 ~$20B outlook, MRVL +5.81% (D1 `7ac0f2f6`). Not a baseline row.
16. **~~FOMC minutes 2026-10-07~~ — RELEASED**; D1 reads them as signalling another hike by year-end (`95adacb5`).
17. **~~MRK ifinatamab deruxtecan PDUFA 2026-10-10~~** — already struck last cycle (BLA withdrawn 09-25); Assyro still lists it as "overdue". Stays struck; the aggregator is stale.

**Non-earnings — corrections / re-verified:**
18. **NVDA GTC Berlin (E) → (C)**, 10-20 → 10-22 with keynote 10-21 (NVIDIA FAQ via search result).
19. **RHHBY Enspryng**: "Oct, no day" → 2026-10-15 (E, Assyro only).
20. **PHAR Joenja 2026-10-24** still shown "decided" by Assyro, consistent with the prior strike.
21. **Cogent bezuclastinib** 11-30 vs 12-30 conflict (see 1A.6). Treat as undated within the C window; GATE-irrelevant either way (both after 11-02).
22. **Gate-relevant (E)/(T) rows landing before 2026-11-02 that were NOT re-verified** (budget and brief's "modest" check): CAT Fabick close (T), AGIO mitapivat 11-01 (E), CPI 10-14 (E). BGC/WDAY 10-13, V 10-16, ORCL CloudWorld and MRK ESMO are (C) carried. Say so rather than imply they were re-read.

### 1A.10 — Names with NO firm forward earnings date

**Newly dated this run:** AKAM (C 11-05), CAT (E 10-29, single source). **Now (C) from (E):** AAPL, AMD, INTC, NOW, VRTX, IBM (firm).

**STILL NO FIRM DATE (A queue / shortlist):**
- **CRM** — only past quarters surface; no FQ3 FY27 notice (FQ3 FY26 notice came 2025-11-05 for 12-03). Early December is INFERRED.
- **INTU** — Intuit says the date is announced at quarter end (Investor Day held 2026-09-17); late November is INFERRED.
- **MRVL** — FQ2 printed 2026-08-27, Investor Day 2026-10-06 passed; FQ3 notice absent; early December INFERRED (FQ3 FY26 was 2025-12-02).
- **NBIS** — (E) 11-11 from two forecast calendars, no company notice.
- **CAT** — (E) 10-29, single-source, company unconfirmed.

**Dated (E) but company notice not yet issued (checked 2026-10-11, nothing found):** MSFT, GOOGL, META, AMZN, XOM, FSLR, TTWO, DDOG, CSCO, QCOM, SMCI, PLTR, UBER, DELL, PANW, ORCL, AVGO, CRWD, SNOW, NTAP, OKTA, HPE, AMAT, HD, NVDA, MU (December). Prior-year notice lead times: Meta 28d, XOM 18d, AMZN 14d, DDOG 21d, FSLR 21d, PLTR ~14d, TTWO 28d, CSCO 9d, ORCL 8d, PANW 15d.

### 1A.11 — Liquidity rail (30-day ADV ≥ $10M), MEASURED

**CARRIED FORWARD, dated 2026-10-04 measurement, window 2026-08-21 → 2026-10-02, IBKR regular-session daily bars (figure of record).** 61 names measured, 61 clear, 0 UNMEASURED; lowest VRTX $222.0M (~22× floor), then NTAP 226.9, FSLR 231.7, UAL 235.4, DAL 259.7, TTWO 278.0 ($M); top MU 16,352.8, NVDA 15,395.6, TSLA 10,458.8. TSM fails A only on the ADR rail. **Not re-measured this run** (a 9-day-old measurement; every name cleared by ≥ 22× and no thinning event was reported).

**New names with NO ADV measurement (UNMEASURED, stated plainly):** the 50 vendor-only names in 1A.8's new cap table (e.g. RIOT, ETSY, MGM, SIRI, SNAP, DOCU, PINS). None is an A-queue or PART 2A name; all have caps ≥ $6.4B and are widely traded, so a ≥ $10M ADV is INFERRED, not measured. Measure on demand if any is promoted to the shortlist.


---

## PART 1B — Strategy C universe, 45-day window (2026-10-11 → 2026-11-25)


### 1B.1 — FOMC

| Event | Meeting | Decision date | In window (to 2026-11-25) | Tag | Source |
|---|---|---|---|---|---|
| FOMC | 2026-10-27 → 10-28 (no SEP) | **2026-10-28** | **YES** | (C) | **federalreserve.gov/monetarypolicy/fomccalendars.htm, fetched 2026-10-11**: "October 27-28", no SEP marker; no 2026 entry marked tentative |
| FOMC | 2026-12-08 → 12-09 (SEP) | 2026-12-09 | No — 14 days past the 11-25 edge | (C) | same fetch |
| FOMC | 2027-01-26 → 01-27 | 2027-01-27 | No | (C) | same fetch; page: 2027 dates "tentative until confirmed at the meeting immediately preceding it" |

**No other FOMC meeting falls in 2026-10-11 → 2026-11-25.** The next after 10-28 is 12-09. Other macro releases: baseline 1B.1 listed none; CPI 10-14 is in 1A.6 only.


### 1B.2 — Earnings inside the window: company-IR-confirmed subset

Carried rows are (C) from baseline, not re-read this run; "NEW" rows were read this run (search or Tavily excerpts of the company's own release, URL in 1A.1 source column). **DAL struck (printed 10-09).** Calendar edge moved from 11-18 to 11-25, so WMT (11-19) enters; DELL (11-24) is (E) only.

| Date | Ticker | Confirmation |
|---|---|---|
| 2026-10-13 | JPM | company Business Wire release via syndicated copy (carried; wire-copy caveat) |
| 2026-10-13 | UNH | unitedhealthgroup.com (carried) |
| 2026-10-13 | WFC | **NEW** newsroom.wf.com release |
| 2026-10-14 | BAC | newsroom.bankofamerica.com (carried) |
| 2026-10-16 | TRV | issuer-confirmed per M2 `50d589a2` (carried) |
| 2026-10-20 | GE | geaerospace.com (carried) |
| 2026-10-20 | NFLX | Netflix release (carried) |
| 2026-10-20 | UAL | United release (carried) |
| 2026-10-21 | CB | issuer-confirmed per M2 `50d589a2` (carried) |
| 2026-10-21 | IBM | **UPDATED** newsroom.ibm.com 2026-10-07 release; firm, no longer preliminary, so it now clears criterion 1 on provenance |
| 2026-10-21 | TSLA | ir.tesla.com (carried; FMP now agrees) |
| 2026-10-22 | AAL | news.aa.com (carried) |
| 2026-10-28 | GEV | gevernova.com (carried) |
| 2026-10-28 | NOW | **NEW** newsroom.servicenow.com 2026-10-07 |
| 2026-10-29 | INTC | **NEW** intc.com 2026-10-06 |
| 2026-10-29 | LLY | investor.lilly.com (carried) |
| 2026-10-29 | MRK | merck.com (carried) |
| 2026-10-29 | RBLX | **NEW** ir.roblox.com (not on the A queue) |
| 2026-10-30 | ABBV | **NEW** AbbVie 2026-10-01 release (copies) |
| 2026-10-30 | CVX | Chevron advisory (carried) |
| 2026-11-02 | AAPL | **NEW** Apple IR notice via MacTrast relay (secondary copy of the company notice; first-party page not retrievable) |
| 2026-11-02 | VRTX | **NEW** Vertex release 2026-10-07 |
| 2026-11-03 | AMD | **NEW** ir.amd.com 2026-10-06 |
| 2026-11-05 | AKAM | **NEW** Akamai release 2026-10-08 |
| 2026-11-18 | TGT | corporate.target.com (carried) |
| 2026-11-19 | WMT | corporate.walmart.com (carried) |

Not yet IR-confirmed (checked 2026-10-11, no notice found): MSFT, GOOGL, META, AMZN, XOM, CAT, FSLR, PLTR, UBER, SMCI, TTWO, DDOG, CSCO, QCOM, NBIS, NVDA, DIS. **Re-check next cycle.** Incidental IR-confirmed non-universe dates seen in the same sweep: GDDY 10-29, FORM 10-28, SPXC 10-29.


### 1B.3 — FDA PDUFA dates in window (2026-10-11 → 2026-11-25)

Sources: baseline carry-forward plus Assyro October and November pages (fetched 2026-10-11, aggregator; no tickers, no first-party confirmation, so most new rows are (E)). Rail note: C-eligible = US-listed (not ADR) and cap ≥ $2B / ADV ≥ $10M; caps and ADV for the new tickers were NOT measured here, so "yes" means instrument-eligible only and cap/ADV remain to be checked by the cap/ADV sub-agent.

| Date | Ticker | Drug / indication | Tag | C-eligible | Note |
|---|---|---|---|---|---|
| ~~2026-10-09~~ | ~~RHHBY~~ | Tecentriq + chemo / stage III dMMR colon | — | — | **APPROVED 10-09; struck (1A.9 #13)** |
| 2026-10-15 | RHHBY | Enspryng / thyroid eye disease | (E) | **NO — ADR** | day newly given, single source |
| 2026-10-17 | VTRS | MR-141 (phentolamine 0.75%) / presbyopia | (2S) | yes (instrument); Opus partnered | pending |
| 2026-10-26 | GSK | Bepirovirsen / chronic hep B | (C) | **NO — ADR** | pending |
| 2026-10-29 | Sun Pharma | ILUMYA (tildrakizumab) | (E) | **NO — not US-listed** (Indian issuer, INFERRED) | **NEW**, Assyro |
| 2026-10-30 | INO | INO-3107 (BLA) / RRP | (C) | yes (instrument); cap likely small, unmeasured | pending |
| 2026-11-01 | AGIO | Mitapivat | (E) | yes (instrument) | **NEW**, a Sunday; Assyro only |
| 2026-11-14 | BTAI | BXCL501 (IGALMI) at-home / agitation | (2S) | yes; micro-cap | defined-risk chain unlikely usable |
| 2026-11-14 | CYTK | Aficamten (MYQORZO) / oHCM | (E) | yes | |
| 2026-11-14 | SMMT | Ivonescimab + chemo / NSCLC (BLA) | (E) | yes (instrument) | conflicts with W40's "filing date" reading; low confidence |
| 2026-11-17 | Beren | Adrabetadex | (2S) | **NO — not listed** (INFERRED) | carried |
| 2026-11-22 | CAPR | Deramiocel | (C) | yes | carried; extended to this date |
| 2026-11-22 | SVRA | Molgramostim | (2S) | yes | carried |
| 2026-11-25 | SAN | Venglustat | (E) | **NO — ADR** | **NEW** |

Out of window, named: BBIO BBP-418 (11-27), NUVL neladalkib (11-27, NEW), Zydus saroglitazar (11-27, not US-listed), PYPD D-PLEX100 (11-28, NEW), VRTX povetacicept (11-30), RHHBY giredestrant (11-30, ADR, NEW), COGT bezuclastinib (11-30 or 12-30), 
VRTX Journavx (12-05), PRAX (12-27). Floor, not census: Assyro listed 10 October and 15 November entries; it can lag first-party updates (it still shows MRK ifinatamab as "overdue").

---

## PART 2A — Strategy A ranked shortlist

W4 reads this PART verbatim and enqueues thesis-construction entries for the ranked shortlist; D2 runs them. Rankings and date specifics are therefore explicit.

### The A-queue census — the PINNED query, run verbatim

```sql
SELECT * FROM state.open_queue WHERE strategy = 'A'
```

**It returns 44 rows** (MEASURED by the orchestrator this run), reconciled ticker by ticker to that count: AAPL, ADBE, AKAM, AMAT, AMD, AMZN, AVGO, CAT, CRM, CRWD, CSCO, CVX, DDOG, DELL, FSLR, GEV, GOOGL, HD, HPE, IBM, INTC, INTU, JPM, LLY, META, MRK, MRVL, MSFT, MU, NBIS, NOW, NTAP, NVDA, OKTA, ORCL, PANW, QCOM, SMCI, SNOW, TGT, TTWO, VRTX, WMT, XOM. **No new Strategy A ticker row landed since the 2026-10-04 run.** The only new Strategy A items are two foundation-change-assessment entries (`foundation-A-usertrust-anchor-202610`, `foundation-A-homogenization-202610`), both completed CONTINUE by D2 on 2026-10-07; they are not ticker rows and do not enter the census. The ticker census is unchanged from last cycle. `Watchlist.md`'s extra row remains **TSM**, an ADR deliberately kept in the file so its reasoning survives and correctly absent from the live queue. **The query wins.** Gate marks existed (W40 read) only in four rows' payloads (`spent_by_gate_likely` on XOM, CVX, MRK and JPM); that is the open W4/W1 enqueue-boundary gap (`ops.alerts` `559ee98c`), carried and not re-raised. Note that MRK's mark is now stale (STEP 3: MRK is GATE-SURVIVING).

**One contract-identity flag for whoever constructs the XOM thesis.** IBKR resolves XOM to "ExxonMobil Holdings Corp", NYSE, conid **895178251**; the plain legacy listing is no longer returned by contract search (the 10-09 Friday bar in this file was read from that conid). Any XOM order craft must resolve the contract fresh rather than reuse a stored conid. Recorded for D2, not acted on here.

### STEP 1 — the GATE DATE, re-derived from scratch, with the arithmetic shown

**DERIVED GATE DATE = 2026-11-02.** Fifth consecutive cycle at this date. Re-derived from live reads this run, not carried.

**Router state read first.** A's `STRATEGY_ACTIVATION` reads **DO-NOT-ACTIVATE** (`state.current_regime`, event `3883e492`, as_of 2026-10-02, M4 2026-10 carry-forward, NO FLIP). No A router event landed since. The basis is unchanged: M1b's raw call for A is DO-NOT-ACTIVATE **on its own reasoning**, A's growth/policy override is DISARMED, the universal acute override is **inert** for A, and the technical leg is DO-NOT-ACTIVATE (breadth WEAK, **46.7** on 2026-10-08, up from 41.15 at the M1b read but still under 50). **A is not parked by the shock**, so CATALYST-GATE MODE is live, not inert. (The 10-06 divergence reviews re-affirmed B and D DO-NOT-ACTIVATE; D's basis is now override-manufactured. That matters for D's re-opening, not A's.)

**PRICE leg** (MEASURED, `state.rerisking_limb_status`, `as_of_denver` 2026-10-11): `shock_overlay_state` **acute** since 2026-08-01 · `brent_baseline` **84.73** (43 obs, 2026-06-01..07-31) · `brent_peak` **108.75** · `brent_current` **104.28** as of **2026-10-08** · `brent_retrace_trigger` **96.74** = (84.73 + 108.75)/2, reproduced · `leg_b_basis` **not_retraced** · `leg_b_price_leg` **FALSE** · `sql_limbs_fired` **FALSE**.

- **On the view's own (stored, mixed-contract) basis:** required fall = (96.74 − 104.28)/104.28 = **−7.23%** (last cycle −5.44% at 102.31). Retracement = (108.75 − 104.28)/(108.75 − 84.73) = 4.47/24.02 = **18.6%** (last cycle 26.8% at 102.31). Brent December rose **+4.1% on 10-08** (D1 `8fb124e9`). **The price leg moved further from clearing this week on the view's own figures.**
- **Like-for-like (INFERRED, approximate) — and a correction to last cycle's file.** The view compares a December-contract `current` against a November-contract peak. The 2026-W40 file stated the like-for-like required fall as "≈ −10% to −11%" and, in the same sentence, the like-for-like retracement as "only ~25–30%". **Those two figures cannot both hold** (`ops.alerts` `2bf52b18`, W3 2026-10-04, correctly reproduced): ~25–30% was the STORED-basis retracement at the 10-01 close, not a like-for-like figure; like-for-like at 10-01 was only **~4%** (Dec 102.31 + the 5.47–6.43 Nov–Dec spread ≈ 107.8–108.7 Nov-equivalent, against a 108.75 peak). The conclusion (moved away from clearing) and the gate were unaffected; the figure was wrong, and is corrected here. **This cycle, consistently on one basis:** Dec 104.28 + 5.47–6.43 ≈ **109.8–110.7 Nov-equivalent, at or ABOVE the 108.75 peak** — like-for-like retracement **≈ 0% (no retracement; arguably a new like-for-like high)**, and the like-for-like required fall to the 96.74 trigger is **≈ −11.9% to −12.6%**. The spread figures are last-cycle measurements (09-29/09-30) carried forward, not re-measured — the November contract has expired, so no live like-for-like quote exists; treat these as an INFERRED band. **The next roll (December → January, ~2026-10-29) lands two sessions before the 11-02 scoring and will flatter the stored-basis figure again.**

**QUIET-CLOCK leg — 15 trading days clear of the most recent qualifying shock-cluster member.** Anchors carried: 2026-09-23 (W1's adjudicated cluster member) → clears **2026-10-14**; 2026-09-11 (M1a's `3b6d1923` anchor) → cleared 2026-10-02. **New this cycle:** the 10-08 Brent +4.1% session. D1 attributed it in its 10-08 sector screen (`c2f7afe6`: "Brent +4.1% (Hormuz/Houthi, Hurricane Isaias shut-ins)"), reused here per the daily-to-weekly boundary. This run's two-search check added, as extracted facts: Oil & Gas Journal (2026-10-08) attributes the move to **renewed Strait of Hormuz tanker attacks** (Kpler: **10 tankers struck 2026-09-28 → 10-04**; transits fell to 7 on 10-06) and to **Hurricane Isaias shut-ins** (~511,619 b/d, 25.1% of US Gulf output, as of 10-07). **That contradicts last cycle's "no new physical supply event after 2026-09-23"** — the tanker strikes are physical disruption events that were not in the warehouse when W40 was written (D1 named Hormuz only on 10-08), so the W40 quiet-clock anchor was understated. Whether they qualify under the shock rubric is M1a/M1R's adjudication, not W1's, and the exact post-10-04 incident dates were not established. **It does not matter for the gate, and the arithmetic proves it without needing the cause or the qualification ruling:** anchored on the last struck tanker (10-04 is a Sunday → first session 10-05), the clock clears **2026-10-26** (10-06(1) … 10-26(15)). More generally, even if 10-08 — or any day through today, 10-11 — were a new qualifying physical-supply event, counting off `state.market_calendar` the clock would clear no later than **2026-10-30** (anchor 10-09/10-10: 10-12(1) 10-13 10-14 10-15 10-16(5) 10-19 10-20 10-21 10-22 10-23(10) 10-26 10-27 10-28 10-29 **10-30(15)**), still before 2026-11-02. **No event that can have happened by this run can push the quiet clock past the gate.** A NEW event on or after 2026-10-12 could (an event on 10-12 clears exactly on 11-02) — that is next cycle's re-derivation, which STEP 4 obliges anyway.

**Scheduled re-scores** (`monthly_ftd`): next **2026-11-02**, then 2026-12-01 and 2027-01-04. 11-02 is **not provably unreachable** — the price leg can clear at any time (it needs ≈ −7.2% on the view, ≈ −12% like-for-like), and the quiet clock clears by 10-14 on the current anchor — so **11-02 is the gate.**

**Out-of-cycle M1R path** (examined last cycle; re-checked): `sql_limbs_fired` needs dwell ≥ 15 (TRUE for A, 118 trading days), technical leg HEALTHY (**FALSE**, breadth 46.7 < 50), price retraced (**FALSE**) and the axis still acute (TRUE). Two conjuncts false. And A's DO-NOT-ACTIVATE does not rest on the shock, so a `latent` downgrade alone would not change A's raw call. **Verdict unchanged: the out-of-cycle path does not make an earlier A activation reachable; gate stays 2026-11-02.** The spec gap (STEP 1 silent on M1R) remains open with W5 as `ops.alerts` `99ccd487` — not re-filed, not adjudicated yet (re-checked this run: still unresolved).

**FAIL-OPEN status: not triggered.** `state.rerisking_limb_status` read cleanly, both legs were derivable, and A reads DO-NOT-ACTIVATE.

### STEP 2 — the DIRECTION rail, run FIRST

Strategy A is **long-only** (`strategy/03_strategy_a.md`, "Long-only (no short positions in A — short is B's territory)"). A candidate whose hypothesized mispricing is that the name is **over**-valued cannot produce an A entry at any conviction. The rail ran before ranking.

**Nine names are `DIRECTION-INADMISSIBLE (A long-only rail)` and one is direction-unresolved (TGT)**, the same set as last cycle. No evidence read this week reverses any direction. All are ranked and carried below the actionable tier, as evidence for the divergence record and for Strategy B's sub-pattern taxonomy.

**The airline cluster lost its first leg.** DAL **printed 2026-10-09** (EPS 1.72 vs 1.77 est; revenue $20.20B vs $17.65B est, FMP). Its catalyst is consumed; the next print is **2027-01-12 (E)**, so DAL's gate status is recomputed below (SURVIVING, a class change from W40). UAL (10-20, C) and AAL (10-22, C) remain the best-dated bearish pair. The cluster stays categorically inadmissible for A. B reads DO-NOT-ACTIVATE, re-affirmed 2026-10-06 (`div-B-202609-1` resolved); there is no open review in which the cluster could find a home this week.

### STEP 3 — classification and counts

A candidate is `SPENT-BY-GATE (gate 2026-11-02)` iff it carries a DATED catalyst strictly before 2026-11-02 and NO dated catalyst on or after it. A date ON 2026-11-02 is not strictly before. Undated or conflicting-straddle is `GATE-SURVIVING` (fail-open). A name with both a spent and a surviving catalyst is surviving. **Every row below was re-derived from this run's date tables (PART 1A), not carried from W40.**

**48 ranked candidates + 9 DIRECTION-INADMISSIBLE = 57 carried. Against the 2026-11-02 gate: 43 GATE-SURVIVING, 14 SPENT-BY-GATE.** (39 survive on a dated post-gate or on-gate catalyst; 4 — MRVL, CRM, INTU and GOOGL — survive on fail-open: no date is established for MRVL/CRM/INTU, and GOOGL carries an undated (T) Waymo catalyst alongside its pre-gate earnings.) The spent fourteen: XOM, CVX, GEV, NOW, CAT, IBM, LLY, INTC, META, GE, BAC and V among the ranked names, plus UAL and AAL among the inadmissible. Last cycle: 40 surviving / 17 spent.

**Names that changed class versus W40, and why:**
- **AAPL: SPENT → SURVIVING.** Earnings moved 10-29 (E) → **11-02 (C)**, Apple IR notice as relayed 10-06. A date ON the gate is not strictly before it. Margin is zero days, but the date is company-issued.
- **CAT: SURVIVING (fail-open) → SPENT.** W40 withdrew the date; this run dates it **10-29 (E)** (TradingKey "published schedule", 2025 pattern; the company has not confirmed). The only other dated item, the Fabick close, is late October (T). W40 predicted this transition.
- **DAL: SPENT → SURVIVING.** Printed 10-09; next print **2027-01-12 (E)**. (Inadmissible tier.)
- **MRK: SPENT → SURVIVING — a correction of W40, not a date move.** W40's own 1A.3 listed the **Q4 call 2027-02-02 (C)** (merck.com), yet W40 marked MRK "FULLY SPENT". Re-derived from scratch, MRK carries a dated post-gate catalyst, so it survives. Its substance is thin (a call date three months out; the pipeline evidence is adverse: I-DXd BLA withdrawn 09-25), so it is held at #41, but the class mark is surviving.
- **Date moves with no class change:** INTC 10-22 → 10-29 (C), still spent. UBER 11-03 → 11-04 (E), surviving. PLTR 11-02 (E; AJ Bell 11-03), surviving, on the gate. VRTX 11-02 upgraded to (C), surviving on the gate and on povetacicept 11-30. AKAM now dated 11-05 (C), surviving (was undated). NBIS now dated 11-11 (E), surviving (was a straddle). AMD 11-03 (C), surviving. NOW, IBM, LLY, GE, BAC, V, GEV, XOM, CVX, META: spent as before. **GOOGL: spent → surviving, a correction of W40 rather than a date move** — its (c) carries the Waymo multi-city launches dated "2026" (year only, (T)), and the spec routes an undated catalyst to GATE-SURVIVING (fail open; the harmful direction is under-research). W40 marked it spent on the same evidence.
- **Fragile survivors (one day earlier flips them):** AAPL, VRTX (both (C), so a move is unlikely), PLTR (E, no company notice), and SMCI/SHOP/AMD at 11-03.

| Ticker | Dated catalysts (re-read this run) | Class vs gate 2026-11-02 |
|---|---|---|
| TTWO | FQ2 11-05 (E); GTA VI launch 11-19 (C) | SURVIVING |
| NVDA | GTC Berlin 10-20..22 (C); earnings 11-18 (E); GTC DC 11-30 (E) | SURVIVING |
| VRTX | earnings 11-02 (C), ON gate; povetacicept PDUFA 11-30 (C) | SURVIVING |
| FSLR | earnings 10-29 (E); Sec 232 regime 12-04 (C) | SURVIVING |
| AVGO | earnings 12-09 (E) | SURVIVING |
| CSCO | earnings 11-11 (E) | SURVIVING |
| AMD | earnings 11-03 (C) | SURVIVING |
| MSFT | earnings 10-28 (E); Ignite 11-17..20 (C) | SURVIVING |
| ORCL | CloudWorld 10-25..28 (C); FQ2 12-10 (E) | SURVIVING |
| XOM | earnings 10-30 (E; one source 10-23) | SPENT-BY-GATE |
| AAPL | earnings 11-02 (C), ON gate | SURVIVING |
| AMZN | earnings 10-29 (E); re:Invent 11-30..12-04 (C) | SURVIVING |
| MU | FQ1 12-23 (E) | SURVIVING |
| CVX | earnings call 10-30 (C) | SPENT-BY-GATE |
| GEV | earnings 10-28 (C) | SPENT-BY-GATE |
| QCOM | earnings 11-11 (E) | SURVIVING |
| MRVL | none dated (early Dec INFERRED) | SURVIVING (undated, fail-open) |
| DELL | earnings 11-24 (E) | SURVIVING |
| UBER | earnings 11-04 (E; one tracker 11-02) | SURVIVING |
| PLTR | earnings 11-02 (E; AJ Bell 11-03), ON gate | SURVIVING |
| SNOW | earnings 12-02 (E) | SURVIVING |
| CRM | none dated (early Dec INFERRED) | SURVIVING (undated, fail-open) |
| NOW | earnings 10-28 (C) | SPENT-BY-GATE |
| PANW | earnings 11-12 or 11-18 (T), both post-gate | SURVIVING |
| CRWD | earnings 12-01 (E) | SURVIVING |
| JPM | earnings 10-13 (C); Investor Day 2027-02-22 (C) | SURVIVING |
| HPE | earnings 12-03 (E) | SURVIVING |
| NBIS | earnings 11-11 (E) | SURVIVING |
| DIS | earnings 11-12 (E) | SURVIVING |
| SHOP | earnings 11-03 (E) | SURVIVING |
| CAT | earnings 10-29 (E); Fabick close late Oct (T) | SPENT-BY-GATE |
| IBM | earnings 10-21 (C) | SPENT-BY-GATE |
| DDOG | earnings 11-05 (E) | SURVIVING |
| OKTA | earnings 12-01 or 12-02 (E) | SURVIVING |
| NTAP | earnings 12-01 (E) | SURVIVING |
| SMCI | earnings 11-03 (E) | SURVIVING |
| MRNA | earnings 11-05 (E) | SURVIVING |
| LLY | earnings 10-29 (C) | SPENT-BY-GATE |
| INTU | none dated (late Nov INFERRED) | SURVIVING (undated, fail-open) |
| GOOGL | earnings 10-28 (E); Waymo launches 2026 year-only (T, undated) | GATE-SURVIVING (fail-open on the undated catalyst) |
| MRK | ESMO event 10-26 (C); earnings 10-29 (C); Q4 call 2027-02-02 (C) | SURVIVING |
| INTC | earnings 10-29 (C) | SPENT-BY-GATE |
| META | earnings 10-28 (E) | SPENT-BY-GATE |
| UNH | earnings 10-13 (C); investor conference ~early Dec (E) | SURVIVING |
| GE | earnings 10-20 (C) | SPENT-BY-GATE |
| BAC | earnings 10-14 (C) | SPENT-BY-GATE |
| V | DOJ discovery close 10-16 (C); earnings 10-27 (E) | SPENT-BY-GATE |
| TGT | earnings 11-18 (C) | SURVIVING |
| DAL | earnings 2027-01-12 (E); Q3 printed 10-09 | SURVIVING |
| UAL | earnings 10-20 (C) | SPENT-BY-GATE |
| AAL | earnings 10-22 (C) | SPENT-BY-GATE |
| CCL | earnings 12-18 (E) | SURVIVING |
| AMAT | earnings 11-12 (E) | SURVIVING |
| WMT | earnings 11-19 (C) | SURVIVING |
| ADBE | earnings 12-09 (E); MAX 11-10..12 (E) | SURVIVING |
| HD | earnings 11-17 (E) | SURVIVING |
| AKAM | earnings 11-05 (C) | SURVIVING |

Dating names is the only thing that converts a fail-open survivor into a spent name. This cycle the conversions were CAT (spent) and the dated-but-post-gate NBIS and AKAM; three names (MRVL, CRM, INTU) remain undated.

### TOP-10 — the actionable tier

All long. All rail-checked against the 2026-10-04 cap and liquidity measurements (carried, 1A.8 / 1A.11). **9 of 10 GATE-SURVIVING, 1 SPENT-BY-GATE** (XOM, kept for conviction; see #10). Price-tape figures appear only where this run measured them (Friday 10-09 IBKR bars: XOM, CVX); the W40 tape lines are carried only where marked "W40".

**1. TTWO — Take-Two Interactive.** (a) **Bullish**, under-valued. (b) GTA VI is the largest entertainment launch ever attempted, and the market has repeatedly discounted Rockstar's ability to hold a date. The date was re-confirmed against Rockstar and TTWO IR in two prior cycles and held; supporting: the last two 10-Qs on deferred-revenue mechanics and the preload schedule. (c) **GTA VI launch 2026-11-19 (C)**, preload 11-12 (carried, not re-verified this run); FQ2 earnings **2026-11-05 (E)** (no notice yet; 2025 notice came 10-09). (d) On the A queue since 2026-08-09; no open position in any strategy. (e) **Top-10.** GATE-SURVIVING; both catalysts post-gate. Unchanged at #1.

**2. NVDA — NVIDIA.** (a) Bullish. (b) The AI-compute and memory re-rating read-through; FQ2 10-Q, last four transcripts, GTC materials. Live objection, carried: the circular-financing critique (2026-07-27). New this week: the FT OpenAI-revenue report took the Nasdaq −1.25% on 10-08 (D1), a demand-side read-through to carry into construction. (c) Earnings **2026-11-18 (E)** (one aggregator 11-17, both post-gate); GTC Berlin 10-20 → 10-22 (C, upgraded) is spent; GTC Washington DC 11-30 → 12-03 (E). (d) Queued 2026-05-09; no open position. (e) Top-10. GATE-SURVIVING.

**3. VRTX — Vertex Pharmaceuticals.** (a) Bullish. (b) BLA/sNDA announcements plus the latest 10-Q pipeline disclosure: two regulatory decisions in a five-week band, and the closed Crinetics acquisition (2026-09-01) broadening the endocrine pipeline; the ~$8.8B Q3 IPR&D charge lands in the 11-02 print (known, non-cash). **Adverse tape from W40, still unattributed in the warehouse:** −3.07% on 10-01 and −4.08% on that week. (c) Earnings **2026-11-02 (C)**, AMC, call 16:30 ET, ON the gate and not strictly before it; **povetacicept PDUFA 2026-11-30 (C)**; Journavx sNDA 2026-12-05 (2S). D2's 10-07 record did not re-confirm the 11-30 date. (d) Queued 2026-07-05; no open position. (e) Top-10. GATE-SURVIVING on substance: the regulatory catalysts are post-gate.

**4. FSLR — First Solar.** (a) Bullish. (b) A fully specified, primary-sourced policy catalyst: the Sec 232 tariff regime (whitehouse.gov), with date, mechanism and magnitude documented by the imposing party (carried, not re-verified). (c) **Sec 232 regime effective 2026-12-04 (C)**, surviving; earnings **2026-10-29 (E)**, spent (no Q3 notice found; the 2025 notice came 10-09). (d) Queued 2026-09-06; no open position. (e) Top-10. GATE-SURVIVING on the both-catalysts reading.

**5. AVGO — Broadcom.** (a) Bullish. (b) Custom-silicon and AI-networking attach. Counter-evidence carried: the BofA note on a ~$370B AI-debt vehicle (2026-08-14, −5.94%). New: the WSJ report (10-07/08, T) of financing for OpenAI capacity together with Oracle hit ORCL −5.5% (D1 `8e407ff8`); it is an AI-capex funding read-through for AVGO that is unconfirmed. (c) Earnings **2026-12-09 (E)** (aggregator; not in FMP). (d) Queued 2026-05-09; no open position. (e) Top-10. GATE-SURVIVING.

**6. CSCO — Cisco.** (a) Bullish. (b) AI-networking order growth against a durably low multiple. Objection carried from W40: valuation reset after a +12.96% session and a new high of 112.23, with no catalyst recorded in the warehouse; both readings argue for urgency in construction, not a higher rank. (c) Earnings **2026-11-11 (E)**; one calendar says 11-10; no notice yet (2025 notice came 11-03). (d) Queued 2026-05-09; no open position. (e) Top-10. GATE-SURVIVING.

**7. AMD — AMD.** (a) Bullish, **contested** on competitive position rather than direction, so the rail does not engage. (b) Counter-evidence carried and material: the exclusive SpaceX AI-compute socket lost to NVDA (2026-08-05). (c) Earnings **2026-11-03 (C)**, AMC, call 17:00 ET (ir.amd.com release 2026-10-06). **The W40 one-day-margin concern is resolved on provenance:** the date is now company-issued, though a one-day margin remains. (d) Queued 2026-05-29; no open position. (e) Top-10. GATE-SURVIVING. *Up from #8.*

**8. MSFT — Microsoft.** (a) Bullish. (b) Azure AI capacity commentary; last four transcripts. (c) Earnings **2026-10-28 (E)**, spent (no notice found); **Ignite 2026-11-17 → 11-20 (C)**, surviving. (d) Queued 2026-07-05; no open position. (e) Top-10. GATE-SURVIVING on the both-catalysts reading. *Up from #10.*

**9. ORCL — Oracle.** (a) Bullish. (b) The AI-capex backlog thesis, on the corrected tape of the 09-14 session (−3.65% close-to-close; D1 `4264b87f`). **Adverse, new:** −5.5% on the 10-07/08 WSJ financing report (T, unconfirmed); that is a funding-structure question to answer in construction, and the reason it is not ranked higher. (c) **FQ2 2026-12-10 (E)** (three calendar sites agree; 2025 notice came 12-02); CloudWorld 10-25 → 10-28 (C) is spent. (d) Queued 2026-05-09; no open position. (e) Top-10, *promoted from #13* because CAT left and the other survivors above it are fully dated. GATE-SURVIVING on a date.

**10. XOM — ExxonMobil.** (a) Bullish. (b) **Reduced per the mode, no first-party document chase.** The shock thesis strengthened this week on measured facts: Brent December +4.1% on 10-08 to 104.28 (D1), renewed Hormuz tanker attacks and Gulf hurricane shut-ins reported by OGJ (STEP 1), and the retracement of the shock peak fell to ~18.6% on the view. Tape: **XOM +0.26% on Friday 10-09 to 168.94 (IBKR bar, conid 895178251)**; CVX +0.20% to 211.98; XLE −0.25%. (c) Earnings **2026-10-30 (E)**; no ExxonMobil notice yet (2025 notice came 10-13 for 10-31); one uncorroborated source says 10-23 (also pre-gate). (d) Queued 2026-09-13; no open position. **Contract identity: conid 895178251, see the census.** (e) Top-10. **SPENT-BY-GATE (gate 2026-11-02)**, kept in tier on conviction as the single representative of the energy seam, for the stated reason that the shock evidence strengthened rather than faded. CVX stays out of the tier: XOM and CVX are one concentration decision.

### 11–20

**11. AAPL — Apple.** (a) Bullish. (b) No thesis-supporting document was re-read this run; the change is the date. (c) Earnings **2026-11-02 (C)**, AMC, call 17:00 ET (Apple IR notice as relayed by MacTrast 2026-10-06; apple.com page returned no event data; FMP agrees). (d) Queued 2026-05-02; no open position. (e) 11–20. GATE-SURVIVING, *up from #42*, **considered for the tier on merit and held at #11**: it survives only by landing exactly on the gate (not strictly before), and no fresh supporting evidence was gathered this week to displace a fully dated top-10 name.

**12. AMZN — Amazon.** (a) Bullish. (b) AWS backlog and margin disclosures; 10-Q Note 10. (c) Earnings 2026-10-29 (E), spent (no notice yet; Amazon's notice typically ~10-16); **re:Invent 2026-11-30 → 12-04 (C)**, surviving. (d) Queued 2026-07-12; **two open Strategy D lots** (`D:AMZN:2026-07-09`, `D:AMZN:2026-07-30`). (e) 11–20. GATE-SURVIVING.

**13. MU — Micron.** (a) Bullish. (b) The old thesis (DRAM/NAND contract prices) was consumed by the 09-30 print. A thesis on the new catalyst must be a *new* one (guidance durability, contract-price follow-through). (c) **FQ1 2026-12-23 (E)**. (d) Queued 2026-05-09; no open position. (e) 11–20. GATE-SURVIVING. *Flagged for W4/D2: the queue row's catalyst reference is the consumed 09-30 print and should be read as stale.*

**14. CVX — Chevron.** (a) Bullish. (b) Reduced per the mode; the same seam as XOM. (c) Earnings call **2026-10-30 (C)**. Friday 10-09: +0.20% to 211.98 (IBKR). (d) Queued 2026-09-13; no open position. (e) 11–20. **SPENT-BY-GATE (gate 2026-11-02).** Held out of the tier on concentration, not conviction. Related: Chevron restructuring announced 10-07 (HESM −14.6%; D1 `e863504e`; details not in the warehouse).

**15. GEV — GE Vernova.** (a) Bullish. (b) Reduced per the mode. Electrification and grid capex. Adverse evidence carried: GLJ Research Sell, $470, 2026-09-14. (c) Earnings **2026-10-28 (C)**, the FOMC day. (d) Queued 2026-08-09; **open Strategy D lot `D:GEV:2026-08-03`**. (e) 11–20. **SPENT-BY-GATE.**

**16. QCOM — Qualcomm.** (a) Bullish. (b) Stellantis Snapdragon expansion; auto/IoT diversification. (c) **2026-11-11 (E)**. (d) Queued 2026-05-01; no open position. (e) 11–20. GATE-SURVIVING.

**17. MRVL — Marvell Technology.** (a) Bullish. (b) Custom-silicon ramp. The Investor Day was held 10-06 (FY28 ~$20B outlook, MRVL +5.81%, D1 `7ac0f2f6`): the catalyst that move priced is consumed. (c) **No FQ3 date established (T)**; early December INFERRED from the 2025 pattern. (d) Queued 2026-05-25; no open position. (e) 11–20. GATE-SURVIVING (fail-open).

**18. DELL — Dell Technologies.** (a) Bullish. (b) AI-server capex. (c) **2026-11-24 (E)**. (d) Queued 2026-05-17; no open position. (e) 11–20. GATE-SURVIVING.

**19. UBER — Uber.** (a) Bullish. (b) The ~3,300-role restructuring's margin effect lands in this print; new: ezCater $2.3B acquisition announced 10-06 (D1 `513dcd0c`). (c) Earnings **2026-11-04 (E)** (FMP; one tracker says 11-02, both not strictly before the gate). (d) **NOT on the A queue**, so new intake if W4 converts it; **open Strategy D lot** `D:UBER:2026-07-09`. (e) 11–20. GATE-SURVIVING.

**20. PLTR — Palantir.** (a) Bullish. (b) Government and commercial bookings. (c) Earnings **2026-11-02 (E, FMP)**, ON the gate; AJ Bell says 11-03; no company notice. (d) Not on the A queue. (e) 11–20. GATE-SURVIVING, the thinnest-margin name without a company-issued date: any revision one day earlier flips it.

### 21–30

**21. SNOW — Snowflake.** Bullish; Cortex AI monetisation and the $6B AWS commitment. Dilution evidence to carry: a **$3.5B convertible** (D1 `e3c878dc`, 09-28). (c) **2026-12-02 (E).** (d) Queued 2026-05-25. (e) GATE-SURVIVING.
**22. CRM — Salesforce.** Bullish; agentic-AI attach against a compressed multiple. (c) **No date established**: only past quarters surface; early December INFERRED (FQ3 FY26 was 2025-12-03). (d) Queued 2026-05-17. (e) GATE-SURVIVING (fail-open).
**23. NOW — ServiceNow.** Bullish; platform attach. Unverified WDAY take-private report (1A.7) recorded, unweighted. (c) **2026-10-28 (C)**, AMC, call 14:00 PT. (d) Queued 2026-05-29. (e) **SPENT-BY-GATE (gate 2026-11-02).**
**24. PANW — Palo Alto Networks.** Bullish; platformisation. (c) FQ1 FY27 **11-12 or 11-18 (T)**, both post-gate. (d) Queued 2026-05-31. (e) GATE-SURVIVING.
**25. CRWD — CrowdStrike.** Bullish; module attach. (c) **2026-12-01 (E).** (d) Queued 2026-05-31. (e) GATE-SURVIVING.
**26. JPM — JPMorganChase.** (a) Bullish. (b) Reduced. The NIM-supportive-hike arithmetic is intact; D1 read the 10-07 FOMC minutes as signalling another hike by year-end, and the 10-year tested 5.35-5.36% intraday on 10-08. (c) Earnings **2026-10-13 (C)**, spent; **Investor Day 2027-02-22 (C)**, surviving. (d) Queued 2026-09-13. (e) GATE-SURVIVING on the Investor Day only; the first bank print is two days out.
**27. HPE — Hewlett Packard Enterprise.** Bullish; the AI-server read-through as DELL. (c) **2026-12-03 (E).** (d) Queued 2026-05-29. (e) GATE-SURVIVING.
**28. NBIS — Nebius Group.** Bullish; neocloud capacity. OpenAI's reported training pause (D1 `e3c878dc`, 09-28) and the 10-08 OpenAI-revenue report are demand-side counter-signals, carried. (c) **2026-11-11 (E)**, narrowed from a 10-22/11-10 split (Earnings Whispers + AJ Bell; no company notice). (d) Queued 2026-05-13. (e) GATE-SURVIVING, now on a date.
**29. DIS — Disney.** Bullish; SVOD margin expansion. (c) Earnings **2026-11-12 (E)**; the Believe ship reveal (10-07) passed with no outcome found. (d) **Not on the A queue**; two open Strategy D lots. (e) GATE-SURVIVING.
**30. SHOP — Shopify.** Bullish; GMV take-rate. (c) Earnings **2026-11-03 (E)**. (d) Not on the A queue. (e) GATE-SURVIVING.

### 31–40

**31. CAT — Caterpillar.** Bullish (data-centre and energy capex pull-through; Fabick dealer acquisition expected to close late October, single aggregator). **Earnings 2026-10-29 (E)** (TradingKey 2026-10-08; company unconfirmed), **SPENT-BY-GATE**, *down from #7* because the date W40 lacked is now established and pre-gate. New policy context: the FTC/USDA farm-equipment RFI hit CAT/DE/XLI on 10-07 (D1 `e863504e`, `434a6738`; no response deadline in the warehouse). Queued 2026-05-01. If Caterpillar's own advisory names a date on or after 11-02, CAT returns to surviving.
**32. IBM** — earnings **2026-10-21 (C)** (newsroom release 10-07, now firm), **SPENT-BY-GATE**; queued 2026-05-29. **33. DDOG** — **2026-11-05 (E)**, surviving; queued 2026-05-07. **34. OKTA** — **12-01/12-02 (E)**, surviving; queued 2026-05-29. **35. NTAP** — **2026-12-01 (E)**, surviving; queued 2026-05-29. **36. SMCI** — **2026-11-03 (E)**, surviving; queued 2026-05-29. **37. MRNA** — **2026-11-05 (E)**, surviving; not queued. **38. LLY** — earnings **2026-10-29 (C)**, **SPENT-BY-GATE**; queued 2026-05-01; a Strategy D router-gated NO-GO was recorded 2026-10-07 (context, not a barrier). **39. INTU** — **no date**: Intuit announces the date at quarter end; late November INFERRED; surviving (fail-open); queued 2026-08-03. **40. GOOGL** — earnings **2026-10-28 (E)**, no Alphabet notice yet (MarketScreener says 10-26); Waymo launches "2026" are year-only and so undated (T); **GATE-SURVIVING on fail-open** (the undated catalyst could land after the gate; corrected from W40's spent mark); queued 2026-07-05; two open D lots. The Google/Constellation 890 MW nuclear PPA (10-06) is past.

### 41–48

**41. MRK** — earnings **10-29 (C)** and ESMO investor event **10-26 (C)** are pre-gate, but the **Q4 call 2027-02-02 (C)** is post-gate: **GATE-SURVIVING** (class change; W40 marked it spent in error). Both near-term PDUFAs are gone (Welireg + Lenvima approved early; I-DXd BLA withdrawn 09-25), real adverse evidence against any pipeline thesis; held low on substance. Queued 2026-09-13. **42. INTC** — earnings **2026-10-29 (C)** (intc.com 10-06; was 10-22 E), **SPENT-BY-GATE**; queued 2026-05-12. **43. META** — earnings **2026-10-28 (E)** (no Q3 notice; 2025 notice came 10-01), **SPENT-BY-GATE**; queued 2026-08-03. **44. UNH** — earnings **2026-10-13 (C)** spent; investor conference ~early December (E, month-level) surviving, so **GATE-SURVIVING**; not queued. **45. GE** — earnings **2026-10-20 (C)**, **SPENT-BY-GATE**; not queued. **46. BAC** — earnings **2026-10-14 (C)**, **SPENT-BY-GATE**; not queued. **47. V** — earnings 2026-10-27 (E) and DOJ discovery close 10-16 (C), **SPENT-BY-GATE**; not queued. **48. TGT** — earnings **2026-11-18 (C)**, GATE-SURVIVING, but **DIRECTION UNRESOLVED**: the prior bearish thesis was refuted by a beat-and-raise and no replacement direction is established; held below the tier for that reason. Queued 2026-05-09.

### DIRECTION-INADMISSIBLE tier — ranked and carried, never actionable for A

These belong to Strategy B. The rail governs only admission to the actionable tier.

| # | Ticker | (a) Direction | (c) Catalyst | Gate status | Thesis |
|---|---|---|---|---|---|
| I-1 | **UAL** | Bearish | Earnings **2026-10-20 (C)**, AMC (call 10-21) | SPENT | Same fuel-shock channel as the cluster, independent print |
| I-2 | **AAL** | Bearish | Earnings **2026-10-22 (C)** | SPENT | Same shock, thinnest balance sheet of the three |
| I-3 | **DAL** | Bearish | Printed 2026-10-09; next **2027-01-12 (E)** | SURVIVING (was SPENT) | First airline to report: EPS 1.72 vs 1.77 est, revenue beat; Brent +4.1% on 10-08 keeps the fuel thesis live |
| I-4 | **CCL** | Bearish | Earnings 2026-12-18 (E) | SURVIVING | Bunker-fuel channel; Q3 printed 2026-09-29; read-through taken in the B index (D2 `a501f39b`) |
| I-5 | **AMAT** | Bearish | Earnings **2026-11-12 (E)** | SURVIVING | China WFE cliff |
| I-6 | **WMT** | Bearish | Earnings **2026-11-19 (C)** | SURVIVING | Two adverse datapoints against the original bullish framing |
| I-7 | **ADBE** | Bearish | Earnings 2026-12-09 (E); MAX 11-10 → 11-12 (E) | SURVIVING | Vindicated on tape |
| I-8 | **HD** | Bearish / neutral | Earnings **2026-11-17 (E)** | SURVIVING | Housing-turnover starvation under a 10-year near 5.35% |
| I-9 | **AKAM** | Bearish / contested | Earnings **2026-11-05 (C)** (Akamai release 10-08; was undated) | SURVIVING | The smallest cap in the file ($15.84B, W40 measurement) |

**W4 side, restated because it binds:** no candidate marked `DIRECTION-INADMISSIBLE` may be converted into a Strategy A `PENDING_ANALYSIS` row, and a vacated slot is filled from the next admissible candidate rather than shipping a short top-10. None of the nine is in the top-10. Five of the nine (AKAM, AMAT, ADBE, HD, WMT) are already on the A queue from earlier cycles; D2 applies the rail to any thesis run on them.

### Handoff notes for W4

- **All ten top-10 names are already on the A queue** (TTWO, NVDA, VRTX, FSLR, AVGO, CSCO, AMD, MSFT, ORCL, XOM; verified against the 44-row census). **W4 has ZERO new A intake from the top-10 this week**, the sixth such cycle. That is the steady state, not a sign the limb failed to run. **New intake overall: none** (zero new ticker rows since 10-04).
- **Tier changes W4 should see:** CAT leaves the top-10 (#7 → #31) as SPENT; ORCL enters (#13 → #9); AMD and MSFT move up one and two places; AAPL rises #42 → #11. All are already queued, so these change ranking, not queue membership.
- **Candidates below the top-10 that are NOT on the A queue**, if W4's limb ever reaches past tier 1: UBER (#19), PLTR (#20), DIS (#29), SHOP (#30), MRNA (#37), UNH (#44), GE (#45), BAC (#46), V (#47).
- **Carry the gate mark onto the queue row** (`ops.alerts` `559ee98c`, open, not re-raised). The one spent name in the tier is **XOM**. **MRK's existing `spent_by_gate_likely` payload is now stale** (MRK survives on its 2027-02-02 call), and **MU's queue row references a consumed catalyst** (the 09-30 print); its live catalyst is 12-23 (E). CAT is newly spent with no mark on its row.
- **Cross-strategy overlap (§E).** `state.current_positions` shows only Strategy D open: RTX, UBER, ISRG, DIS (x2), GEV, GOOGL (x2), TSM (x2), AMZN (x2); zero open A, B or C positions. The overlap tickers among A candidates are AMZN, DIS, GEV, GOOGL and UBER; none of them is in the top-10.
- **NO-GO records are context, not barriers (`Operating_Protocols.md` §3).** New this week in `events.decision_log`: the **Strategy D router-gated thesis-construction NO-GO of 2026-10-07 for LLY, V, VRTX, GE, MSFT, SPOT, MELI, HWM and AVGO** (D's DNA and capital are disabled, so these are router-gated outcomes under D's criteria, not findings on the names); and **Strategy E pair NO-GOs of 2026-10-04 for MCHP/ADI, CB/TRV and MDB/SNOW** (conservative default). Of the nine D names, VRTX, MSFT and AVGO are A top-10 names and LLY, V and GE are ranked; none changes an A rank. The 2026-09-27 NKE D NO-GO is not an A candidate.
- **Re-check next cycle:** AAPL (zero-day margin; Apple's first-party page not reached), PLTR (on the gate, no company notice; UBER and SMCI/SHOP/AMD at 11-03/11-04), CAT (E, single source: its own advisory decides spent vs surviving), XOM (10-30 vs an uncorroborated 10-23; both pre-gate), and the large caps with no company notice (MSFT, GOOGL, META, AMZN, FSLR, TTWO, DDOG, CSCO).
- **Gate marks for W4 to carry:** SPENT-BY-GATE (gate 2026-11-02) on XOM, CVX, GEV, NOW, CAT, IBM, LLY, INTC, META, GE, BAC, V (ranked) and UAL, AAL (inadmissible).

### REPORT IT — CATALYST-GATE MODE

- **Gate date: 2026-11-02** (fifth consecutive cycle at this date).
- **Legs:** price leg FALSE (Brent 104.28 vs trigger 96.74; needs −7.23% on the view, ≈ −12% like-for-like; retracement 18.6% on the view, ≈ 0% like-for-like); quiet-clock leg clears 2026-10-14 on the adjudicated anchor, no later than 2026-10-30 on any anchor reachable by this run; next scheduled re-score 2026-11-02. A reads DO-NOT-ACTIVATE (event `3883e492`); mode live, not inert, no fail-open.
- **Counts:** 57 carried (48 ranked + 9 inadmissible); **14 SPENT-BY-GATE, 43 GATE-SURVIVING** (4 of those on fail-open).

---

## PART 2C — Strategy C ranked shortlist

### Router state, and what it admits

C reads **`HYBRID ACTIVATE (FOMC-only)` — UNCHANGED, `div-C-202609-1` RESOLVED 2026-10-06** (event `4bed3605`; `state.strategy_capital_enablement` latest C activation ts 2026-10-06, `capital_enabled` TRUE for C). The pending flag is cleared and the prior operative state was retained. M1b's raw fundamental call for C remains DO-NOT-ACTIVATE, but the operative router state is the HYBRID carve-out. Under it, only an FOMC-type event is router-admissible. Corporate earnings and FDA PDUFA candidates stay **router-PARKED** and must not be enqueued. Widening beyond FOMC-only is reserved to a separate scope-widening adjudication; none is open.

**The one router-eligible event in the 45-day window (2026-10-11 → 2026-11-25) is the 2026-10-28 FOMC.** A/B/D/E all read DO-NOT-ACTIVATE (MEASURED, `state.strategy_capital_enablement`).

### The capital position (MEASURED 2026-10-11)

C is **NOMADIC** (`state.strategy_nomadic_status.is_nomadic` TRUE). Borrow capacity is **ZERO**, MEASURED from `state.nomadic_borrow_capacity_watch`:

| strategy | donor_capacity_total | donor_count | borrow_blocked |
|---|---|---|---|
| C | **0** | **0** | **TRUE** |

The donor set is empty: A, B and E are `capital_enabled` FALSE (`capital_disabled` TRUE) and D is itself nomadic. E holds **$12,668.28** idle (was $12,672.77), capital-disabled. `state.nomadic_capital_ledger`: C `swept_out_total` **$9,464.72**, `restored_total` $0, `net_position` $9,464.72 (unchanged). C's `analytics.strategy_nav` row: deposits/NAV/available_funds **$19.48** (baseline $19.49; a $0.01 rounding-level move), realized and unrealized P&L $0, `sizing_base_2pct` $0.39. (The view carries no date column; it is a current-state view.) **Already alerted, not re-raised:** `ops.alerts` `71d484fa-0623-4443-89ed-a357ab305f67` (`nomadic_borrow_blocked`, warning) is **still OPEN** (`resolved` = FALSE), MEASURED today. `INCIDENT[ref=71d484fa]`. **C has never opened a position**; `state.current_positions` holds zero open A and zero open C rows (MEASURED).

### Criterion 1 (a qualifying event within 45 days)

- **FOMC 2026-10-28 is (C)**, re-confirmed by a direct federalreserve.gov fetch on 2026-10-11 (PART 1B.1; October 27-28, no SEP). It clears.
- **Earnings:** parked under FOMC-only. In-window dates below are carried from the baseline (1B.2, company-confirmed where tagged), cross-read against the earnings agent's raw FMP pull in the scratch dir (vendor dates, not company-first-party). The cross-read corroborates UNH, JPM, NFLX, TSLA, XOM, CVX, AMD (all same date as the baseline); GEV, LLY, MRK, INO-type names are absent from that vendor sample, which proves nothing (the pull is partial, ~81 rows). The earnings agent's `earnings_dates.csv` was reconciled against this table at assembly: AMD is now (C) (11-03, ir.amd.com release 10-06) and every other date agrees. The three prints of 10-05..10-09 in that pull (DAL, PEP, TLRY) are not on this shortlist, so no candidate was struck for printing.
- **PDUFAs** (INO 10-30, VTRS 10-17, BTAI 11-14, CYTK 11-14): carried forward unchanged from the baseline; I made no metered source call this cycle, so they were NOT re-verified. All router-PARKED.

### The tenor rail — CLEAR, fourth cycle running

C requires structure expiration within **1-45 days of entry** (`strategy/05_strategy_c.md`). Queue item check: `thesis-FOMC-C-20261020` (event `295d48ce`) is on `state.open_queue`, **status pending, strategy C, due 2026-10-20**, conservative default "Decline - no entry" (MEASURED today). It is the only FOMC row; **W4 must not create a duplicate.**

MEASURED from the live SPY option parameters (IBKR, conid 756733), expiries 10-12 → 12-31: daily/weekly 10-12, 10-13, 10-14, 10-15, **10-16 (regular)**, 10-19, 10-20, 10-21, 10-22, 10-23, **10-26 (new this cycle; 10-26 is a Monday)**, **10-30**, 11-06, 11-13, **11-20 (regular, plus a 2SPY class)**, 11-27, 11-30, **12-18 (regular)**, 12-31. **The first expiry strictly after the 2026-10-28 decision is 2026-10-30** (SPY class, non-regular weekly). With entry due 2026-10-20 the tenor is 10 days, inside 1-45. Criterion 5 (entry at least one trading day before the event) holds with 6 trading days of slack.

### Criterion 2 (implied vs realized) — MEASURED on the spec window (trailing 30 days)

Per `strategy/05_strategy_c.md` the headline is **IV/HV30**; HV20 and HV10 are context. (The window question is open with W5 as `ops.alerts` `1876c957`; this cycle applies the spec's own 30-day window.)

**Quotes are FROZEN** (`top_status` FROZEN, Sunday); all values are the Friday 2026-10-09 regular session's. SPY 2026-10-09 regular-session close **778.57** (IBKR daily bar; snapshot last 778.57). SPY 2026-10-30 expiry, ATM strike **779** (nearest listed $1 strike to 778.57):

| Field | Value |
|---|---|
| ATM call 779 | last 8.99, bid 9.01 / ask 9.05, OI 1,307 |
| ATM put 779 | last 7.80, bid 7.80 / ask 7.84, OI 833 |
| ATM straddle | mid **16.85 -> $1,685.00 per contract** (ask 16.89 -> $1,689) |
| `implied_vol` on the contracts | **11.204%, `is_valid` TRUE**, both call and put (daily 0.7058%). A change: last cycle this field was INVALID (-1.0) and the ratio was derived |
| `option_midpoint_iv` | -15.8745, `isValid` FALSE (the known sentinel, reproduced) |
| `implied_vol_underlying` (SPY) | **11.990%**, `is_valid` TRUE, a 30-day constant-maturity figure, not the 10-30 expiry |
| Cross-check, DERIVED (Black-Scholes on bid/ask mids; r 4.0%, q 1.2%, T = 21/365, S 778.57) | call 11.57%, put 11.05%, **average 11.31%**. Derived and assumption-dependent; agrees with the broker field within 0.11 pt |
| IBKR `historical_vol` (broker's own 30d) | 10.339% (context only; method not disclosed, not the spec figure) |

Realized volatility, annualized close-to-close (log returns, sample stdev, x sqrt(252)), computed from IBKR regular-session daily closes (`outside_rth` false), last close 2026-10-09:

| Window | N closes (N-1 returns) | Date range | Realized vol | IV/HV (broker `implied_vol` 11.204%) | IV/HV (derived 11.31%) | IV/HV (underlying 11.990%) |
|---|---|---|---|---|---|---|
| **HV30 (spec window)** | 31 (30) | 2026-08-27 -> 2026-10-09 | **9.890%** | **1.133** | 1.144 | 1.212 |
| HV20 | 21 (20) | 2026-09-11 -> 2026-10-09 | 9.952% | 1.126 | 1.136 | 1.205 |
| HV10 | 11 (10) | 2026-09-25 -> 2026-10-09 | 8.315% | 1.347 | 1.360 | 1.442 |

**Comparison with last cycle (HV30 9.640%; IV/HV30 1.322 derived / 1.296 underlying):** the headline ratio **fell** to 1.144 derived (1.133 on the now-valid broker field) and to 1.212 on the underlying figure. Both legs moved: the 10-30 ATM IV is down ~1.4 pt (12.74% derived -> 11.31%), and HV30 is up 0.25 pt (9.640% -> 9.890%). Implied is **still RICH to realized on the spec window, but the premium has narrowed materially** (about 14% on the derived basis and 6% on the underlying basis) after seven cycles of being stuck near 1.3. **The realized term structure flipped**: last cycle HV10 > HV20 > HV30 (inverted); this cycle HV10 8.3% < HV20 9.95% ~ HV30 9.89%, i.e. the last two weeks were calm (SPY rose 763.99 -> 778.57 on a low-vol grind, 10-09 +0.6%). HV10 is the shortest and the ratio against it (1.35) is the richest; the spec window is HV30. Context for the new IV level: VIX was NORMAL 15.41 per the orchestrator; SPY trend UP.

**Measurement-integrity notes.**
1. `implied_vol` was valid this cycle (it was invalid last cycle), so the headline no longer rests on a derived number; the derivation is shown only as a cross-check and agrees. The N and date range of HV windows differ from last cycle by construction (rolling).
2. Frozen Sunday quotes: bid/ask are the Friday close-of-session book; the call's last-trade timestamp and the put's differ by ~2 minutes (ts 1791576751 vs 1791576877), so the straddle mid mixes a nearly simultaneous pair; a live in-session read is required before any trade. D2's 2026-10-20 thesis run must read a live `implied_vol`.
3. The 10-30 expiry's IV contains the FOMC jump (10-28) plus ~2 post-event days, so ATM IV on it is event-loaded by construction; the 30-day underlying IV (11.99%) is the cleaner context figure. A rich-vs-realized finding on an event expiry is therefore partly the event premium, not a pure volatility-risk-premium.
4. HV uses close-to-close on regular-session closes only; it excludes overnight-gap-driven vol that the Friday-evening news flow (D1 has not yet covered the 10-09 session) could add.

**The structural disjointness, unchanged but milder.** Implied rich favours **selling** premium. A credit structure's max loss must be deterministically collateralized, and C's reachable $19.48 cannot collateralize any SPY credit spread (a 1-point spread carries $100 gross max loss). What C can afford is confined to far-wing **debit** structures (the buying side). The ATM straddle at $1,685.00 is ~86x C's NAV (was ~111x; the cut is the lower IV and the quote, not capital).

**Panel measurement deliberately NOT extended, third cycle.** Every name in the implied-vs-realized panel is an earnings or PDUFA candidate and router-PARKED under FOMC-only, so it buys no decision this week. **If scope ever widens, re-establish the panel before relying on the trend.**

### Ranked shortlist — 15 event candidates

**TOP-5**

**1. FOMC 2026-10-28** — (a) **No affirmative directional divergence established by W1.** The measurable divergence is on volatility: IV/HV30 about 1.14 (down from 1.32), still implied-rich but narrower, and the only structures C can fund are on the buying side. (b) federalreserve.gov meeting calendar (last cycle's direct fetch; re-confirmation by the dates agent). The 09-16 hike was unanimous with 16 of 18 dots for more; D1 notes the 10-year trading 5.35-5.36% intraday on 10-08 (24-year high test), so the meeting is live. (c) **2026-10-28 (C).** (d) **Structure affordable only in the far wings.** C NAV $19.48; ATM straddle $1,685.00; borrow capacity zero, `borrow_blocked` TRUE. **Flagged as a deferral risk, not a deferral**; the decision is not W1's. (e) No open A positions, so no A-C conflict. (f) **Top-5, rank 1, the only router-eligible candidate**, and now router-confirmed (div-C-202609-1 resolved HYBRID 10-06).
  **Disposition: W1 shortlists and does not drain.** `thesis-FOMC-C-20261020` is **pending**, due **2026-10-20**; GO/NO-GO is **D2's on that date** with a recorded default of "Decline - no entry". It is the only FOMC row. **W4 must not create a duplicate.**

**2. INO — INO-3107 PDUFA 2026-10-30.** (a) A binary regulatory outcome; implied typically under-prices a first-approval binary in a small cap. (b) Inovio BLA-acceptance release plus trackers (one quoting 89% approval odds). (c) 2026-10-30 (carried, not re-verified). (d) Chain liquidity unverified; a small-cap chain may not support a deterministic defined-risk structure at any size. (e) No A overlap. (f) Top-5. **Router-PARKED.**

**3. TSLA — earnings 2026-10-21 (C).** (a) Implied is habitually rich into TSLA prints, a sell-side divergence that C cannot fund. (b) Tesla IR and 8-K; Q3 deliveries of 486,532 already reported 10-02. (c) 2026-10-21 (vendor pull agrees); not the FOMC day. (d) Bounded as above. (e) Not on the A queue. (f) Top-5. **Router-PARKED.**

**4. VTRS — MR-141 PDUFA 2026-10-17.** (a) Binary; presbyopia approval is a commercial-scale question more than an approval-probability one. (b) Two trackers (2S). (c) 2026-10-17 (carried). Note D1 recorded the Viatris $36.50 cash acquisition of PCRX (+44% PCRX) in the week; whether it alters Viatris's event profile is not assessed here. (d) Bounded as above. (e) None. (f) Top-5. **Router-PARKED.**

**5. UNH — earnings 2026-10-13 (C).** (a) A post-guidance-reset print; implied may be rich after a volatile year. (b) unitedhealthgroup.com's own release. (c) 2026-10-13 (vendor pull agrees; 2 days out, so it will print before the 10-20 queue date and cannot be entered even if scope widened). (d) Bounded as above. (e) Not on the A queue (A #44). (f) Top-5. **Router-PARKED.**

**REST (6-15)** — all **router-PARKED**; none has an implied vol measured this cycle.

| # | Candidate | (a) Hypothesized divergence | (c) Date | Tag | (e) A overlap | Note |
|---|---|---|---|---|---|---|
| 6 | **JPM** earnings | Banks keep declining to price a hike they arithmetically benefit from | 2026-10-13 | (C, wire copy; vendor agrees) | A queue (JPM) | first bank print; also GS, C, WFC, JNJ same day per vendor |
| 7 | **AMD** earnings | Post-shock semis repricing; implied likely rich into a contested print | 2026-11-03 | (C; ir.amd.com 10-06; vendor agrees) | A queue (AMD) | first post-event expiry 11-06 |
| 8 | **XOM** earnings | Energy-seam second leg; Brent 104.28 (10-08), shock acute since 08-01 | 2026-10-30 | (E; vendor agrees; no XOM notice yet) | A queue (XOM) | same date as the FOMC-structure expiry |
| 9 | **CVX** earnings | As XOM, correlated | 2026-10-30 | (C; vendor agrees) | A queue (CVX) | |
| 10 | **NFLX** earnings | First print after the summer content slate | 2026-10-20 | (C; vendor agrees) | not queued | same day as the thesis due date |
| 11 | **GEV** earnings | Grid-capex print after an initiated Sell | 2026-10-28 | (C) | A queue (GEV) | **same day as the FOMC, a confounded structure**; GEV is also an open Strategy D position (D, not A or C, so no A-C conflict) |
| 12 | **LLY** earnings | GLP-1 volume vs pricing | 2026-10-29 | (C) | A queue (LLY) | not in the vendor sample |
| 13 | **BTAI** PDUFA | Binary, micro-cap | 2026-11-14 | (2S) | none | chain probably unusable |
| 14 | **MRK** earnings | First print after the I-DXd BLA withdrawal | 2026-10-29 | (C) | A queue (MRK) | not in the vendor sample |
| 15 | **CYTK** PDUFA | Binary label expansion | 2026-11-14 | (E) | none | single source |

**Changes vs last cycle's 15:** no name dropped and no date moved. The three prints of 10-05..10-09 in the vendor pull (DAL, PEP, TLRY) were never on the shortlist. UNH and JPM, which print 10-13, are now 2 days away and will have printed before the first possible queue action. A-queue position numbers (#) from the baseline were replaced by "A queue (ticker)" membership, re-verified against the 44-name A-queue census in the brief (JPM, AMD, XOM, CVX, GEV, LLY, MRK all present; UNH, NFLX, TSLA not).

**(e) A-vs-C exclusivity is vacuous this cycle.** `state.current_positions` holds zero open A and zero open C positions (MEASURED today).

**Shortlists only.** Full thesis construction per Strategy.md happens in the sessions W4 schedules.

---

---

## Coverage, provenance and what this cycle changed

**Read scope.** Weekly cadence. BigQuery (read-only): `state.trading_day_today`, `state.current_regime`, `state.current_positions`, `state.open_queue`, `state.rerisking_limb_status`, `state.strategy_capital_enablement`, `state.strategy_nomadic_status`, `state.nomadic_borrow_capacity_watch`, `state.nomadic_capital_ledger`, `analytics.strategy_nav`, `state.market_calendar`, `state.routine_catchup_window`, `events.decision_log`, `events.queue_events`, `ops.alerts`. Repo: `strategy/03_strategy_a.md`, `strategy/05_strategy_c.md`, the Claude_Task_Plan.md W1 section and the prior `Weekly_Catalyst_Calendar.md`. Live: FMP calendar and market-cap endpoints (chunked), IBKR (daily bars, option chain and snapshots), and web sources (federalreserve.gov, Assyro PDUFA pages, company releases through search and Tavily excerpts). Every metered call is logged in the run's per-agent call files. State is labelled MEASURED or INFERRED where it matters.

**Catch-up window.** `state.routine_catchup_window` gives `window_days` **6.99**, against a weekly 1.5× threshold of 10.5. That is cadence-normal, so **no `CATCHUP` token is owed** and no missed-period sub-sections are needed. Evidence window: 2026-10-04 07:55:59 UTC → now.

**The daily-to-weekly boundary, honoured.** Reused catalysts come from in-window D1/D2 records and are cited by `entry_id`: the PCRX/Viatris, CMG/SBUX and ORCL/WSJ items and the 10-08 tape (`8e407ff8`), PTC/Schneider and RXO/CHRW (`0e8fe4c3`), OPCH, MRVL Investor Day and the CEG/GOOGL PPA (`7ac0f2f6`), ON/SYNA (`d5ee1347`), UBER/ezCater (`513dcd0c`), the CVX/HESM restructuring and farm-equipment RFI (`e863504e`, `434a6738`), the 10-08 Brent attribution (`c2f7afe6`), rates and minutes (`95adacb5`, `8fb124e9`) and D2's VRTX record (`dde6be0a`). **No second broad news scan was run.** Web effort went to forward-calendar acquisition and date confirmation, which W1 owns. D1 records run through 2026-10-08.

**The FRIDAY-SESSION GAP, closed from IBKR.** D1 has not yet covered Friday 2026-10-09; that is the structural weekly gap (W1's Sunday trigger fires before the D1 that covers Friday), not a D1 outage. The price half was closed at zero cost from IBKR regular-session bars: **SPY 778.57 (+0.60%), XLE 65.08 (−0.25%), BNO 63.99 (+0.55%), XOM 168.94 (+0.26%), CVX 211.98 (+0.20%)**. SPY closed 0.07% under its 10-06 close of 779.09, so no new high. Only the narrative half of Friday is missing (Hurricane Isaias landfall outcome, any Hormuz development 10-09), and it is not chased.

**Standing constraints NOT re-alerted:** the FMP earnings-horizon plan cap (`FMP-earn-horizon`) and the bulk-enumeration plan gate (`6c4004e3`); C's blocked nomadic borrow (`71d484fa`); the Friday boundary gap (`b4e4e563`); the Brent contract-roll basis in the limb view (`0c7fcaec`, with `82c99515` on the same surface); and the gate-mark enqueue gap (`559ee98c`). The horizon depth (68 days, terminal date unchanged) is reported in the header because it is a measurement, not an alert.

**FMP silent partial, measured this cycle.** The wide 2026-12-01 → 2027-04-11 call dropped five December rows that the narrow December call returned, with no error; this is the shape shared rule (iv) names. It is a process finding (chunk and diff), not an alert-class event.

**Open W1 referrals, re-checked and still open with W5:** `99ccd487` (CATALYST-GATE MODE STEP 1 is silent on the out-of-cycle M1R path; re-examined in STEP 1, it still does not move A's gate) and `1876c957` (C's realized-vol window; PART 2C applied the spec's trailing-30-day window again). Neither is re-filed.

**Correction applied this cycle.** The 2026-W40 file stated the like-for-like Brent required fall as "≈ −10% to −11%" and the like-for-like retracement as "~25–30%" in one sentence; those cannot both hold (`ops.alerts` `2bf52b18`, W3 2026-10-04). STEP 1 restates both on one basis (required fall ≈ −11.9% to −12.6%; retracement ≈ 0%) and says so. Neither the gate nor its conclusion changes.

**Facts absent from the warehouse, found by web.** The Hormuz tanker strikes (Kpler: 10 tankers struck 2026-09-28 → 10-04; transits down to 7 on 10-06) and the Gulf hurricane shut-ins (~25% of US Gulf oil as of 10-07) are not recorded in `events.decision_log`; D1's 10-08 title attributes the Brent move to "Hormuz/Houthi, Hurricane Isaias" but the Houthi element is unverified. Sources are two web searches and one OGJ article; incident dates after 10-04 were not established. Whether they qualify as a shock-cluster member is M1a/M1R's adjudication; the gate arithmetic holds either way (STEP 1).

**Gate-relevant dates NOT re-verified this run (stated, not implied):** GTA VI 11-19, BGC and WDAY 10-13, V 10-16, ORCL CloudWorld, MRK ESMO, FSLR Sec 232, AGIO 11-01 and CPI 10-14 (carried or single-source); Apple's first-party IR page and Caterpillar's IR page returned no event data.

**What moved this cycle, in one place.**
- **Provenance:** ten earnings dates became company-issued; AAPL moved +4 days to 11-02 (C) and INTC +7 days to 10-29 (C); AKAM became dated 11-05 (C); CAT acquired a 10-29 (E) date from a single source.
- **Prints struck:** DAL (10-09), PEP and TLRY (10-08). RHHBY Tecentriq PDUFA approved 10-09. New PDUFA rows: AGIO, SAN, NUVL, PYPD, RHHBY giredestrant, Sun Pharma; COGT 11-30 vs 12-30 unresolved; SMMT 11-14 conflicts with W40's reading.
- **New deals (D1):** PCRX/Viatris, PTC/Schneider, OPCH/CD&R-McKesson, ON/SYNA, UBER/ezCater; CMG/SBUX and ORCL/WSJ are unconfirmed reports.
- **Gate:** held at 2026-11-02 for a fifth cycle. The price leg moved further from clearing (Brent 102.31 → 104.28; required fall −5.44% → −7.23% on the view). The quiet clock clears 10-14 on the adjudicated anchor and no later than 10-30 on any anchor reachable by today.
- **Ranking:** 14 spent / 43 surviving (was 17 / 40). AAPL, MRK, DAL and GOOGL moved to surviving (MRK and GOOGL are corrections of W40); CAT moved to spent and left the tier; **ORCL entered the top-10** and AMD and MSFT moved up; XOM remains the one spent name in the tier.
- **Strategy C:** HYBRID ACTIVATE (FOMC-only) unchanged, `div-C-202609-1` resolved 10-06; criterion 2 narrowed (IV/HV30 ≈ 1.14, from 1.32); the broker's per-contract IV field is valid again; borrow capacity still zero.

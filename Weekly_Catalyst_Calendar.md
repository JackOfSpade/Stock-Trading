2026-W40

# Weekly Catalyst Calendar — Strategies A and C

**Run date 2026-10-04** (Sunday, `weekly_sun`). ISO week of TODAY's run date per `state.trading_day_today.today`, the same week W2/W3 stamp this cycle. The upcoming trading week opens Monday 2026-10-05; that is context, not the marker.

**Windows.** Strategy A: 6 months, **2026-10-04 → 2027-04-04**. Strategy C: 45 days, **2026-10-04 → 2026-11-18**.

**EFFECTIVE CONFIRMED-EARNINGS HORIZON: 2026-12-18 — 75 days, ~10.7 weeks.** The 6-month figure above is the *analytical* window. Bulk earnings-date coverage is dense only to 2026-12-18. After that the vendor calendar returns four isolated rows (FDX 2027-02-02, TSLA 2027-02-03, RIVN 2027-02-25, FDX 2027-03-25), and **2026-12-19 → 2027-02-01 returns zero rows**. This is the standing plan-tier constraint (`ops/connector_tools.yaml`, FMP `calendar`; open owner decision `FMP-earn-horizon` in `OWNER_ACTIONS.md`), and it is deliberately NOT re-alerted. **The horizon moved, and that belongs here.** Five consecutive weekly probes give 2026-12-03/88d (09-06), 2026-12-09/87d (09-13), 2026-12-09/80d (09-20), 2026-12-10/74d (09-27) and **2026-12-18/75d (10-04)**. The terminal date jumped **+8 days** in one week after advancing one day in the previous three. Effective depth is flat week over week (74 → 75 days) and still well short of the ~13 weeks the plan documents. One jump does not make a trend. It reads as a batch roll of December reporters (NKE 12-17 and CCL 12-18 entered as their September/October prints rolled off), not as the window lengthening.

**Every count in PART 1 is a FLOOR.** Universe enumeration is impossible on this plan tier, because `search/search-company-screener`, every `directory.*` route and `quote/batch-quote` are each separately tool-level ACCESS DENIED. PART 1A is therefore built over the 81 reachable vendor calendar rows plus the 44-row live A queue and the carried candidate set, not over "all US-listed equities ≥ $2B cap and ≥ $10M ADV". Not re-alerted (`ops.alerts` `6c4004e3`, standing).

**The cycle's biggest change is provenance.** Last week not one earnings date in either window was company-confirmed. This week **sixteen are (C)**, read from the company's own IR page or release: DAL, JPM, UNH, BAC, GE, NFLX, UAL, AAL, TSLA, IBM (preliminary), GEV, MRK, LLY, CVX, TGT and WMT. Mid-to-late October reporters announce their dates 10–30 days ahead, and early October is when that happens. It changes two things downstream. Strategy C's criterion-1 provenance failure is no longer universal (PART 2C). And it exposed one vendor date that is plainly wrong: **TSLA is 2026-10-21 per Tesla's own IR table, while FMP still shows 2026-10-28**, a 7-day error that last week placed Tesla on the FOMC day.

---

## PART 1A — Strategy A universe, 6-month window (2026-10-04 → 2027-04-04)

No interpretation in this PART. Provenance tags: **(C)** company- or primary-source confirmed and read this run · **(E)** estimated (vendor or aggregator projection) · **(T)** tentative, no firm day. Where a (C) date was read through a wire-service copy of the company's own release rather than the IR site, the Source column says so.

### 1A.1 — Earnings, inside the 45-day C window (2026-10-04 → 2026-11-18)

FMP bulk rows are (E) unless upgraded. "Δ" marks a date that moved since the 2026-09-27 artifact.

| Ticker | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| PEP | PepsiCo | Earnings | 2026-10-08 | (E) | FMP bulk |
| TLRY | Tilray | Earnings | 2026-10-08 | (E) | FMP bulk — A-INELIGIBLE, cap floor |
| DAL | Delta | Earnings (BMO, call 10:00 ET) | 2026-10-09 | **(C)** | ir.delta.com webcast release, read |
| C | Citigroup | Earnings | 2026-10-13 | (E) | FMP bulk |
| GS | Goldman Sachs | Earnings | 2026-10-13 | (E) | FMP bulk |
| JNJ | Johnson & Johnson | Earnings | 2026-10-13 | (E) | FMP bulk |
| JPM | JPMorganChase | Earnings (~07:00 ET, call 08:30 ET) | 2026-10-13 | **(C)** | company Business Wire release (2026-09-17), read via syndicated copy, not jpmorganchase.com |
| UNH | UnitedHealth | Earnings (BMO, call 08:00 ET) | 2026-10-13 | **(C)** | unitedhealthgroup.com newsroom, 2026-09-15 release, read |
| WFC | Wells Fargo | Earnings | 2026-10-13 | (E) | FMP bulk |
| BAC | Bank of America | Earnings (~06:45 ET, call 08:30 ET) | 2026-10-14 | **(C)** | newsroom.bankofamerica.com release, read |
| TSM | Taiwan Semiconductor | Earnings | 2026-10-15 | (E) | FMP bulk — A-INELIGIBLE, ADR |
| TRV | Travelers | Earnings | 2026-10-16 | (C) | reused from M2 2026-10-01 pair screen `50d589a2` (issuer-confirmed there) |
| GE | GE Aerospace | Earnings (BMO, webcast 07:30 ET) | 2026-10-20 | **(C)** | geaerospace.com 3Q26 webcast page, read |
| GM | General Motors | Earnings | 2026-10-20 | (E) | FMP bulk |
| NFLX | Netflix | Earnings (post ~13:01 PT) | 2026-10-20 | **(C)** | Netflix release 2026-09-14 (PR Newswire PDF, raw text read; a summariser misread it as Oct 18) |
| UAL | United Airlines | Earnings (AMC; call 10-21 10:30 ET) | 2026-10-20 | **(C)** | United release, read. **Δ** last artifact had 10-21, which is the call day |
| CB | Chubb | Earnings call | 2026-10-21 | (C) | reused from M2 `50d589a2` |
| IBM | IBM | Earnings | 2026-10-21 | **(C, preliminary)** | ibm.com earnings-3q26 page, read. The page itself says the date is preliminary |
| T | AT&T | Earnings | 2026-10-21 | (E) | FMP bulk |
| TSLA | Tesla | Earnings (AMC, webcast 17:30 ET) | **2026-10-21** | **(C)** | ir.tesla.com earnings table and the 2026-10-02 deliveries release with its 8-K exhibit, read as returned excerpts (a direct fetch got a 403). **Δ −7 days: FMP still shows 10-28, which is wrong** |
| AAL | American Airlines | Earnings (call 07:30 CT) | 2026-10-22 | **(C)** | news.aa.com release, read |
| INTC | Intel | Earnings | 2026-10-22 | (E) | FMP bulk; intc.com shows no Q3 notice yet |
| LMT | Lockheed Martin | Earnings | 2026-10-22 | (E) | FMP bulk. **Δ +2d** (was 10-20) |
| NOK | Nokia | Earnings | 2026-10-22 | (E) | FMP bulk — A-INELIGIBLE, ADR |
| VZ | Verizon | Earnings | 2026-10-26 | (E) | FMP bulk. **Δ +6d** (was 10-20) |
| BA | Boeing | Earnings | 2026-10-27 | (E) | FMP bulk. **Δ −1d** (was 10-28) |
| CARR | Carrier Global | Earnings | 2026-10-27 | (E) | FMP bulk |
| HCA | HCA Healthcare | Earnings | 2026-10-27 | (E) | FMP bulk. **Δ +4d** (was 10-23) |
| HOOD | Robinhood | Earnings | 2026-10-27 | (E) | FMP bulk. **Δ −8d** (was 11-04) |
| KO | Coca-Cola | Earnings | 2026-10-27 | (E) | FMP bulk. **Δ +7d** (was 10-20) |
| PYPL | PayPal | Earnings | 2026-10-27 | (E) | FMP bulk |
| SOFI | SoFi | Earnings | 2026-10-27 | (E) | FMP bulk |
| V | Visa | Earnings | 2026-10-27 | (E) | FMP bulk |
| F | Ford | Earnings | 2026-10-28 | (E) | FMP bulk. **Δ +6d** (was 10-22) |
| GEV | GE Vernova | Earnings (BMO, webcast 07:30 ET) | 2026-10-28 | **(C)** | gevernova.com investors events page, read |
| GOOGL | Alphabet | Earnings | 2026-10-28 | (E) | FMP bulk; abc.xyz shows no Q3 notice yet |
| META | Meta Platforms | Earnings | 2026-10-28 | (E) | FMP bulk; no Q3 notice yet |
| MGM | MGM Resorts | Earnings | 2026-10-28 | (E) | FMP bulk. **Δ −7d** (was 11-04) |
| MSFT | Microsoft | Earnings | 2026-10-28 | (E) | FMP bulk; no Q3 notice yet |
| NOW | ServiceNow | Earnings (AMC) | 2026-10-28 | (E) | aggregator. **NEWLY DATED**; was undated |
| SBUX | Starbucks | Earnings | 2026-10-28 | (E) | FMP bulk |
| ~~FDX~~ | ~~FedEx~~ | ~~Earnings~~ | ~~2026-10-28~~ | (T) | **REJECTED AS SUSPECT, fourth cycle running.** It fits no FedEx quarter-end (FY ends 31 May). See 1A.9 |
| AAPL | Apple | Earnings | 2026-10-29 | (E) | FMP bulk; no Q4 notice yet |
| AMZN | Amazon | Earnings | 2026-10-29 | (E) | FMP bulk |
| COIN | Coinbase | Earnings | 2026-10-29 | (E) | FMP bulk |
| FSLR | First Solar | Earnings (AMC) | 2026-10-29 | (E) | aggregator |
| LLY | Eli Lilly | Earnings (call 10:00 ET) | 2026-10-29 | **(C)** | investor.lilly.com "Upcoming Events" (the event-detail page returned 503). **NEWLY DATED**; was undated |
| MRK | Merck | Earnings (call 09:00 ET) | 2026-10-29 | **(C)** | merck.com events-and-presentations page, read |
| RBLX · RIOT · RKT | — | Earnings | 2026-10-29 | (E) | FMP bulk |
| RIVN | Rivian | Earnings | 2026-10-29 | (E) | FMP bulk. **Δ −5d** (was 11-03) |
| SIRI | Sirius XM | Earnings | 2026-10-29 | (E) | FMP bulk. **Δ −5d** (was 11-03) |
| ABBV | AbbVie | Earnings | 2026-10-30 | (E) | FMP bulk. The company announced a call on 10-01 (headline only; date not read) |
| CVX | Chevron | Earnings call (11:00 ET) | 2026-10-30 | **(C)** | Chevron "3Q 2026 Earnings Conference Call" advisory (syndicated company release), read |
| XOM | ExxonMobil | Earnings | 2026-10-30 | (E) | FMP bulk; no Q3 notice yet (Q2's came 10 days ahead). One search source said 10-23; uncorroborated |
| PLTR | Palantir | Earnings | 2026-11-02 | (E) | FMP bulk; one aggregator says 11-09 — **conflicting** |
| VRTX | Vertex | Earnings | 2026-11-02 | (E) | aggregator. **NEWLY DATED**; was undated |
| FUBO | fuboTV | Earnings | 2026-11-02 | (E) | FMP bulk — A-INELIGIBLE, cap floor |
| AMD | AMD | Earnings | 2026-11-03 | (E) | FMP bulk; no notice on ir.amd.com yet (AMD's pattern is ~4 weeks ahead) |
| ET · PINS | — | Earnings | 2026-11-03 | (E) | FMP bulk. ET **Δ −1d** |
| PFE | Pfizer | Earnings | 2026-11-03 | (E) | FMP bulk |
| SHOP | Shopify | Earnings | 2026-11-03 | (E) | FMP bulk |
| SMCI | Super Micro | Earnings (AMC) | 2026-11-03 | (E) | aggregator. **NEWLY DATED**; one source says "not confirmed" |
| UBER | Uber | Earnings | 2026-11-03 | (E) | FMP bulk; one aggregator says 10-29 — **conflicting** |
| ETSY · ROKU · SNAP | — | Earnings | 2026-11-04 | (E) | FMP bulk |
| LCID | Lucid | Earnings | 2026-11-04 | (E) | FMP bulk — A-INELIGIBLE, cap floor |
| DDOG | Datadog | Earnings | 2026-11-05 | (E) | aggregator. **NEWLY DATED** |
| MRNA | Moderna | Earnings | 2026-11-05 | (E) | FMP bulk |
| TTWO | Take-Two | Earnings (FQ2) | 2026-11-05 | (E) | aggregator |
| SONY | Sony | Earnings | 2026-11-10 | (E) | FMP bulk — A-INELIGIBLE, ADR |
| CSCO | Cisco | Earnings | 2026-11-11 | (E) | FMP bulk; aggregators split 11-11 / 11-12 / 11-18 |
| QCOM | Qualcomm | Earnings (AMC) | 2026-11-11 | (E) | aggregator, marked "estimated"; investor.qualcomm.com shows no date. **NEWLY DATED** |
| AMAT | Applied Materials | Earnings (AMC) | 2026-11-12 | (E) | aggregator; IR page 503. **NEWLY DATED** |
| BILI | Bilibili | Earnings | 2026-11-12 | (E) | FMP bulk — A-INELIGIBLE, ADR |
| DIS | Disney | Earnings | 2026-11-12 | (E) | FMP bulk |
| PANW | Palo Alto Networks | Earnings (FQ1 FY27) | 11-12 or 11-18 | (T) | aggregators conflict. **It already printed FQ4 on 2026-09-01**, so last week's "no establishable date" was a stale read (1A.9) |
| BIDU | Baidu | Earnings | 2026-11-17 | (E) | FMP bulk — A-INELIGIBLE, ADR |
| HD | Home Depot | Earnings (BMO) | 2026-11-17 | (E) | aggregator, marked "unconfirmed". **NEWLY DATED** |
| NVDA | NVIDIA | Earnings | 2026-11-18 | (E) | FMP bulk; one aggregator says 11-17 |
| TGT | Target | Earnings (call 08:00 ET) | 2026-11-18 | **(C)** | corporate.target.com events page, read |

### 1A.2 — Earnings, 2026-11-19 → dense horizon 2026-12-18

| Ticker | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| WMT | Walmart | Earnings (release ~06:00 CT) | 2026-11-19 | **(C)** | corporate.walmart.com FY27 Q3 event page, read |
| ZM | Zoom | Earnings | 2026-11-23 | (E) | FMP bulk |
| DELL | Dell Technologies | Earnings | 2026-11-24 | (E) | aggregator. **NEWLY DATED** |
| BABA · NIO | — | Earnings | 2026-11-24 | (E) | FMP bulk — A-INELIGIBLE, ADR |
| CRWD | CrowdStrike | Earnings (AMC) | 2026-12-01 | (E) | aggregator. **NEWLY DATED** |
| NTAP | NetApp | Earnings | 2026-12-01 | (E) | aggregator (the company release reportedly sets the date; the page returned 503). **NEWLY DATED** |
| OKTA | Okta | Earnings (AMC) | 12-01 or 12-02 | (E) | aggregators conflict by one day. **NEWLY DATED** |
| SNOW | Snowflake | Earnings | 2026-12-02 | (E) | aggregator. **NEWLY DATED** |
| DOCU | DocuSign | Earnings | 2026-12-03 | (E) | FMP bulk |
| HPE | Hewlett Packard Enterprise | Earnings (AMC) | 2026-12-03 | (E) | aggregator. **NEWLY DATED** |
| ADBE | Adobe | Earnings | 2026-12-09 | (E) | FMP bulk |
| AVGO | Broadcom | Earnings (FQ4, AMC) | 2026-12-09 | (E) | aggregator. The text matches Broadcom's own release boilerplate, but the release page returned 503, so it is not read. **Δ −1d** (was 12-10) |
| COST | Costco | Earnings | 2026-12-10 | (E) | FMP bulk |
| ORCL | Oracle | Earnings (FQ2) | ~12-10 or 12-14 | (E) | aggregators conflict. It printed FQ1 on 2026-09-10 (1A.9) |
| NKE | Nike | Earnings (FQ2) | 2026-12-17 | (E) | FMP bulk; FQ1 printed 2026-10-01 |
| CCL | Carnival | Earnings (Q4) | 2026-12-18 | (E) | FMP bulk; Q3 printed 2026-09-29 |

### 1A.3 — Earnings, 2026-12-19 → 2027-04-04

**Structurally almost empty of bulk coverage.** 2026-12-19 → 2027-02-01 returned zero vendor rows. The only rows in range are MU **2026-12-23 (E)** (aggregator; Micron printed FQ4 on 2026-09-30), MRK Q4 call **2027-02-02 (C)** and Q1 2027 call **2027-04-29 (C)** (outside the window; both from Merck's own events page), TSLA **2027-02-03 (E)** (FMP tail row), RIVN **2027-02-25 (E)** (FMP tail row) and FDX **2027-03-25 (E)**, retained as the one FedEx row that fits its fiscal calendar. FDX 2027-02-02 stays rejected (1A.9). Six A-queue names still carry no firm forward earnings date (1A.10). This is a coverage gap, not an absence of events, and it shows up as a ranking distortion in PART 2A's lower bands, not as missing rows.

### 1A.4 — Product launches, keynotes, developer events

| Ticker | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| DIS | Disney | Disney Believe ship reveal event | 2026-10-07 | (E) | newly recorded; single secondary source |
| NVDA | NVIDIA | GTC Berlin | 2026-10-20 → 10-22 | (E) | carried |
| ORCL | Oracle | CloudWorld | 2026-10-25 → 10-28 | (C) | carried |
| ADBE | Adobe | Adobe MAX | 2026-11-10 → 11-12 | (E) | carried |
| TTWO | Take-Two | **GTA VI launch** | 2026-11-19 | (C) | carried, confirmed in two prior cycles and not re-verified this run; preload 11-12 |
| MSFT | Microsoft | Ignite | 2026-11-17 → 11-20 | (C) | carried |
| AMZN | Amazon | re:Invent | 2026-11-30 → 12-04 | (C) | carried |
| NVDA | NVIDIA | GTC Washington DC | 2026-11-30 → 12-03 | (E) | carried |
| GOOGL | Alphabet | Waymo multi-city robotaxi launches | 2026 (year only) | (T) | carried |
| — | broad | CES 2027 | 2027-01-06 → 01-09 | (E) | carried |
| NVDA | NVIDIA | GTC 2027 San Jose | 2027-03-15 → 03-18 | (C) | carried |
| META | Meta | Enterprise-AI platform launch plus senior hire | 2026-09-28 | (C) | **PAST.** D1 `e3c878dc`; META −4.79% that session. Recorded for the divergence record only |

### 1A.5 — Analyst and investor days

| Ticker | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| BGC | BGC Group | FMX Investor Day | 2026-10-13 | (C) | carried |
| WDAY | Workday | Financial Analyst Day | 2026-10-13 | (C) | carried. See 1A.7 for the unverified take-private report |
| MRK | Merck | Investor event at ESMO 2026 (webcast) | 2026-10-26 | **(C)** | **NEW**, merck.com events page, read |
| NKE | Nike | Investor day, "Fall 2026" | — | (T) | carried, single weak source, no day |
| UNH | UnitedHealth | Investor conference | ~2026-12 early | (E) | carried, projected from annual cadence |
| JPM | JPMorganChase | Investor Day | 2027-02-22 | (C) | carried |

Dropped as PAST: INTU Investor Day (held; guidance reaffirmed).

### 1A.6 — Regulatory, legal, trade and macro

| Ticker | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| RHHBY | Roche | Tecentriq + chemo PDUFA (stage III dMMR/MSI-H colon) | 2026-10-09 | (C) | carried dual-source plus two calendar listings this run. ADR |
| — | broad | US government funding: CR runs to 12-11 | 2026-12-11 | (E) | carried |
| V | Visa | DOJ fact discovery closes | 2026-10-16 | (C) | carried |
| VTRS | Viatris / Opus | MR-141 PDUFA (presbyopia) | 2026-10-17 | (2S) | **upgraded from single-source**: biopharmawatch + Assyro, neither company-confirmed |
| RHHBY | Roche | Enspryng (satralizumab) PDUFA, thyroid eye disease | Oct 2026, no day | (T) | **NEW**, low confidence; listed by Assyro and RTTNews, date not found. ADR |
| GSK | GSK | Bepirovirsen PDUFA (chronic hep B) | 2026-10-26 | (C) | carried multi-source, re-listed this run. ADR |
| — | broad | **FOMC decision** | **2026-10-28** | (C) | **RE-CONFIRMED by direct fetch of federalreserve.gov this run** (Oct 27–28 meeting, no SEP) |
| INO | Inovio | INO-3107 BLA PDUFA (recurrent respiratory papillomatosis) | 2026-10-30 | (C) | carried, multi-sourced and re-listed this run. INO = Inovio, not Inotiv (NOTV) |
| — | broad | USTR Sec 301 exclusions expire | 2026-11-10 | (C) | carried |
| BTAI | BioXcel | BXCL501 at-home agitation sNDA PDUFA | 2026-11-14 | (2S) | **NEW**: bioradar + thepharmaletter ("PDUFA target action date 14 Nov 2026") |
| CYTK | Cytokinetics | oHCM sNDA PDUFA | 2026-11-14 | (E) | **NEW**, single source |
| Beren | Beren Therapeutics | Adrabetadex PDUFA | 2026-11-17 | (2S) | carried, not re-verified |
| UNP·NSC | Union Pacific / Norfolk Southern | STB comments due | 2026-11-18 | (C) | carried |
| CAPR | Capricor | Deramiocel PDUFA | 2026-11-22 | (C) | carried; reported as extended to this date |
| SVRA | Savara | Molbreevi PDUFA | 2026-11-22 | (2S) | carried |
| BBIO | BridgeBio | LGMD2I/R9 NDA PDUFA | 2026-11-27 | (E) | **NEW**, single source |
| VRTX | Vertex | Povetacicept PDUFA | 2026-11-30 | (C) | carried, not re-verified this run |
| COGT | Cogent | Bezuclastinib PDUFA (GIST) | 2026-11-30 | (E) | **NEW**, single source |
| UNP·NSC | Union Pacific / Norfolk Southern | DOJ/USDOT preliminary comments | 2026-12-03 | (C) | carried |
| FSLR | First Solar + solar | **Sec 232 tariff regime effective** | 2026-12-04 | (C) | carried, whitehouse.gov; not re-verified this run |
| VRTX | Vertex | Journavx sNDA PDUFA | 2026-12-05 | (2S) | carried |
| — | broad | **FOMC decision** | **2026-12-09** | (C) | direct federalreserve.gov fetch (Dec 8–9 meeting, SEP) |
| BA | Boeing | FAA 737 MAX 10 certification, "by year-end 2026" | — | (T) | carried |
| PRAX | Praxis | Relutrigine PDUFA | 2026-12-27 | (2S) | carried; reported as extended from 09-27 |
| DYN | Dyne | Z-rostudirsen PDUFA | 2027-01-21 | (C) | carried |
| — | broad | **FOMC decision** | **2027-01-27** | (C) | direct federalreserve.gov fetch (Jan 26–27; the page marks 2027 dates tentative) |
| PHAR | Pharming | Joenja lower-dose sNDA (13–27 kg) PDUFA | 2027-01-30 | (C) | **NEW**, Pharming release via BioSpace (2026-09-25) |
| UNP·NSC | Union Pacific / Norfolk Southern | STB responses due | 2027-02-16 | (C) | carried |
| BMRN | BioMarin | VOXZOGO full approval | 2027-02-28 | (C) | carried |
| SRPT | Sarepta | AMONDYS 45 / VYONDYS 53 sNDAs | 2027-02-28 | (C) | carried; cap ~$2.14B, on the floor, so re-measure before use |
| LYV | Live Nation | DOJ/states remedies phase | ~2027-02 | (E) | carried |
| WBD | Warner Bros Discovery (acquirer PSKY) | Antitrust trial begins | 2027-03-02 | (C) | carried |
| EXEL | Exelixis | Zanzalintinib PDUFA (mCRC) | 2027-03-03 | (E) | **NEW to the table**, reported as extended from 12-03 |
| — | broad | **FOMC decision** | 2027-03-17 | (C) | federalreserve.gov (Mar 16–17, tentative) |

Beyond the window, named so it is not re-discovered: FTC v. Amazon trial ~2027-03-29 (E). **Rows that left this table this cycle** are listed at 1A.9: three PDUFAs resolved early or were withdrawn, and two dates passed.

Macro context, carried: the **2026-09-16 FOMC hiked 25bp to 3.75–4.00%**, unanimous (12–0), with 16 of 18 end-2026 dots above the new midpoint. Since the last cycle the 10-year reached **5.24–5.29%**, a 19–24-year high (D1 `8d0b7dee`, `bd235450`; Q1 retrospective `4c0487f7`). Both remaining 2026 meetings are live dated catalysts, not formalities.

### 1A.7 — Restructuring, M&A and structural

| Ticker | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| WDAY | Workday | **Reported take-private target** | undated | (T) | **NEW, UNVERIFIED.** Secondary report surfaced in M2's 2026-10-01 pair screen (`50d589a2`), which dropped the NOW/WDAY pair on it. No primary source read. Recorded so it is not re-discovered, not as a fact |
| VRTX | Vertex | Crinetics acquisition closed; ~$8.8B IPR&D charge expected in Q3 | closed 2026-09-01 | (C) close / (E) charge | **NEW to the table.** The close is from Vertex's newsroom list; the charge size is an aggregator estimate. It lands in the 11-02 print |
| CAT | Caterpillar | Fabick dealer acquisition, expected to close late October | late Oct 2026 | (T) | **NEW**, single aggregator snippet |
| SWKS·QRVO | Skyworks / Qorvo | $22B merger, cleared all but 2 jurisdictions | undated | (C) | carried |
| KMB·KVUE | Kimberly-Clark / Kenvue | Merger close; the outside date auto-extends | 2026-11-02 → 2027-05-03 | (T) | carried |
| TECK | Teck Resources | Anglo American–Teck; China MOFCOM last pending | spans window | (C) | carried |
| CTVA | Corteva | "Vylor" spin-off | Q4 2026 | (T) | carried |
| — | broad | Nasdaq-100 annual reconstitution | mid-2026-12 | (E) | carried |
| — | broad | S&P 500 Q4 rebalance | 2026-12-18 | (E) | carried |
| DG | Dollar General | CEO transition | 2027-01-01 | (C) | carried |
| BA | Boeing | SVP Finance → Controller succession, on the 10-K filing | — | (C) | carried |
| — | broad | S&P 500 Q1 2027 rebalance | 2027-03-19 | (E) | carried |
| MGM | MGM Resorts | People Incorporated withdrew its take-private proposal | 2026-09-23 | (C) | carried as PAST; divergence record only |

Narrative-only, no row: UBER's ~3,300-role restructuring, whose margin effect lands in the Q3 print (11-03 per FMP, 10-29 per one aggregator).

### 1A.8 — Universe rails, MEASURED

**Market-cap rail (≥ $2B at entry) — 61 names MEASURED this cycle, none carried. 0 FAIL on cap.** The set is the 44-row A queue plus 17 forward-calendar candidates and tier names. `company/batch-market-cap` was called once on all 61 and returned **32**. It **silently dropped 29** with no error: AKAM, AMAT, AVGO, CAT, CRM, CRWD, DDOG, DELL, FSLR, GEV, HD, HPE, IBM, INTU, LLY, MRK, MRVL, MU, NBIS, NOW, NTAP, OKTA, ORCL, PANW, QCOM, SMCI, SNOW, TTWO and VRTX. That is the documented mixed-batch behaviour, and the requested-vs-returned diff was taken explicitly rather than trusting a non-empty response. **All 29 were recovered individually via `company/profile-symbol`** (29/29), the manifest's documented route.

Smallest caps ($B, multiple of the $2B floor): **AAL 8.57 (4.3×)** · AKAM 15.84 (7.9×) · FSLR 18.77 (9.4×) · SMCI 28.26 (14.1×) · OKTA 35.13 (17.6×). **No name is within 3× of the rail** ($6B), so the `profile-symbol` share-count-lag caveat in `ops/connector_tools.yaml` does not bind. AAL is the closest; it is batch-sourced and self-consistent (price 12.94 × ~662M shares). Selected others: TTWO 37.91 · NTAP 44.40 · NBIS 58.27 · TGT 70.85 · INTU 76.89 · VRTX 128.10 · CAT 389.43 · ORCL 409.89 · CSCO 442.23 · AMAT 428.77 · MU 1,213.97 · AVGO 1,689.61 · NVDA 5,666.50 ($B). Week over week, AKAM moved 16.565 → 15.84 and no verdict changed.

**FAIL the cap floor, A-ineligible (carried, not candidates):** TLRY, LCID, FUBO.

**ADR / instrument rail.** **TSM: `isAdr` TRUE** (country TW), so it is A-ineligible on the instrument rail although its cap ($2,452B) and ADV ($2,392M) clear by orders of magnitude. The other foreign-domiciled names were checked and are **not** depositary receipts: **NBIS** (Nebius Group N.V., country NL, `isAdr` false, NASDAQ ordinary shares), **SHOP** (country CA, `isAdr` false) and **CCL** (country US, `isAdr` false). Ordinary shares listed on a US exchange satisfy "US-listed common equity", so all three pass. The ADR exclusions measured last cycle (NOK, SONY, BILI, BIDU, BABA, NIO, alongside TSM) are carried. None of those is a candidate, and re-measuring them would buy nothing.

### 1A.9 — Rows struck, rejected or corrected this cycle

1. **~~MRK Welireg + Lenvima PDUFA 2026-10-04~~ — RESOLVED EARLY.** Reported approved in September, ahead of the action date (a merck.com release appears in search results; that page was not fetched). Struck as a forward catalyst.
2. **~~MRK ifinatamab deruxtecan PDUFA 2026-10-10~~ — WITHDRAWN.** The BLA was voluntarily withdrawn on 2026-09-25 after FDA said the data did not support accelerated approval. Corroborated by about seven independent sources. Last cycle carried this row single-sourced. With both MRK PDUFAs gone, **MRK has no in-window regulatory catalyst left.**
3. **~~PHAR Joenja (pediatric 4–11y) PDUFA 2026-10-24~~ — RESOLVED EARLY**, approved in September (several sources, plus Pharming's own 09-25 release referring to the "recent approval"). The successor lower-dose sNDA (PDUFA 2027-01-30) is added at 1A.6.
4. **SRRK apitegromab: approved 2026-09-11** as Isembyld, before its 09-30 date (FDA novel-approvals listing, search excerpt). Last cycle carried the 09-30 PDUFA as live and ranked it #3 in PART 2C. It was in fact already decided when that artifact was written. **This is a W1 process miss, not a vendor error**: last cycle's PDUFA pass checked dates, not whether each decision had already landed. This cycle's pass checked status first and caught three rows that way (items 1–3).
5. **ORCL and PANW: last cycle's "NO ESTABLISHABLE DATE" was a stale read, not a coverage gap.** ORCL had already printed FQ1 FY27 on **2026-09-10** and PANW FQ4 FY26 on **2026-09-01**, both before last cycle's run. Searching for "the next date" without first checking whether the expected quarter had already printed made a just-reported name look undated. Both are now carried with their genuine next-print estimates.
6. **TSLA 2026-10-28 (FMP) → 2026-10-21 (C).** The vendor row is wrong by seven days. Last cycle's PART 2C flagged TSLA as "confounded with the FOMC, same day". **That confound does not exist.**
7. **UAL 2026-10-21 → 2026-10-20.** Last cycle's artifact carried the conference-call day. The release is after the close on 10-20 (company release, and FMP agrees).
8. **AVGO 2026-12-10 → 2026-12-09 (E), CAT 2026-11-04 (E) → NOT ESTABLISHED.** CAT's row was aggregator-only last cycle. FMP no longer lists it, and aggregators now split 10-28 / 10-29 / 11-04. A date that cannot be held is withdrawn, not carried. This matters for the gate (PART 2A STEP 2), because the spread straddles 2026-11-02.
9. **~~FDX 2026-10-28~~ and ~~FDX 2027-02-02~~ — REJECTED AS SUSPECT, fourth cycle.** Neither fits FedEx's quarter ends (FY ends 31 May; quarters end Aug / Nov / Feb / May). Only 2027-03-25 is retained. This is still a reasoned rejection on fiscal-calendar arithmetic; FedEx's IR page was not reached.
10. **Brent: the stored series rolled contracts on 2026-09-29, so 09-28 → 09-29 is not a price move.** `state.signal_marks_curated` BZUSD is the November contract through 09-28 and December from 09-29. About −6.43 of the stored −9.12 step is backwardation, not price (M1a evidence note `0c7fcaec`, which also covers the risk this poses to the re-risking limb's price leg). W1 does not re-raise it. It is cited at PART 2A STEP 1 because it changes how the price-leg distance must be read.
11. **INO = Inovio, not Inotiv** (carried precaution; INO-3107 belongs to Inovio, ticker INO).

### 1A.10 — Names with NO firm forward earnings date

Last cycle listed sixteen. This cycle the fallback chain (WebSearch → Tavily → IR page) dated most of them:
- **Now (C):** LLY 10-29, and IBM 10-21 (preliminary per IBM's own page).
- **Now (E), aggregator-only:** AMAT 11-12, CRWD 12-01, DDOG 11-05, DELL 11-24, HPE 12-03, NTAP 12-01, OKTA 12-01/02, QCOM 11-11, SMCI 11-03, SNOW 12-02, VRTX 11-02, NOW 10-28 and HD 11-17.
- **Were never undated** (already printed; 1A.9 item 5): ORCL, whose next print is ~12-10/12-14 (E), and PANW, whose next is 11-12 or 11-18 (T).
- **STILL NO FIRM DATE: AKAM** (aggregators split 11-05 / 11-10), **CRM** (only past quarters surface; early December by prior-year pattern, INFERRED), **INTU** (Intuit's IR calendar says the date "will be announced at the end of the quarter"), **MRVL** (the aggregator row is internally inconsistent), **NBIS** (10-22 / 11-10 split) and **CAT** (withdrawn this cycle, 1A.9 item 8).

Per CATALYST-GATE MODE, the six undated names are **GATE-SURVIVING on the fail-open reading** and receive full depth. A name cannot be proven spent without a date. That is deliberate, and it is the expensive direction.

### 1A.11 — Liquidity rail (30-day ADV ≥ $10M), MEASURED

Measured off **IBKR regular-session daily bars**, per `Operating_Protocols.md` §19 PRICE BASIS: `get_price_history(step='ONE_DAY', outside_rth=false)`, never `get_price_snapshot`. ADV is the mean of (close × volume) over the last **30 trading bars, 2026-08-21 → 2026-10-02**.

**61 names measured. 61 clear the $10M floor, 0 UNMEASURED.** TSM fails A only on the ADR rail. Every series used a full 30 bars and **every one ends 2026-10-02**, the last trading day, confirmed from each response's own timestamp array.

**Lowest measured: VRTX at $222.0M, about 22× the floor.** The lowest six: VRTX 222.0 · NTAP 226.9 · FSLR 231.7 · UAL 235.4 · DAL 259.7 · TTWO 278.0 ($M). The top of the range: MU 16,352.8 · NVDA 15,395.6 · TSLA 10,458.8 · META 9,088.3 · AAPL 7,687.9. NTAP, last cycle's lowest at $197.05M, is now $226.9M.

**Cross-contamination guard (`ops.alerts` `7cc25b71`).** Calls were made strictly one at a time, and every response's last close was checked against FMP's price or cap-implied share count for the same symbol. **No mismatch was found.** Separately, the warehouse sub-pass's IBKR SPY closes for 09-25 → 10-01 matched `state.signal_marks_curated` to the cent.

**A level caveat, stated so it is not mistaken for a defect.** IBKR 30-day dollar volume runs about **0.3–0.5×** FMP's `averageVolume × price`. The windows differ, and IBKR's day volume is ~0.55–0.65× FMP's consolidated figure for the same day (e.g. FSLR 1.03M vs 1.90M shares on 10-02). IBKR is the figure of record. Every name clears by at least 22× on it, so the verdict does not depend on which source is used.

**The rail is not close to binding**, for many cycles running. Its value is in catching a data defect, not in screening names out.

---

## PART 1B — Strategy C universe, 45-day window (2026-10-04 → 2026-11-18)

C's qualifying event types are exhaustive and there are only three (`strategy/05_strategy_c.md`:25-31): corporate earnings (US-listed, **date confirmed from company IR**), FDA PDUFA (FDA calendar or company disclosure) and FOMC (confirmed Fed calendar). Everything else is excluded at the strategy level.

No interpretation in this PART.

### 1B.1 — FOMC

| Event | Meeting | Decision date | In window | Tag | Source |
|---|---|---|---|---|---|
| FOMC | 2026-10-27 → 10-28 (no SEP) | **2026-10-28** | **YES** | (C) | **federalreserve.gov, fetched directly this run** |
| FOMC | 2026-12-08 → 12-09 (SEP) | 2026-12-09 | No — 21 days past the 11-18 edge | (C) | federalreserve.gov, direct |
| FOMC | 2027-01-26 → 01-27 | 2027-01-27 | No | (C) | federalreserve.gov, direct (2027 marked tentative) |

### 1B.2 — Earnings inside the window: company-IR-confirmed subset

The full dated set is 1A.1, not duplicated here. **The provenance picture changed this cycle.** Last cycle zero earnings dates in the window were company-IR-confirmed, so every earnings row failed C's criterion 1 on provenance. This cycle these rows are (C) and therefore **pass criterion 1 on provenance**:

| Date | Ticker | Confirmation read |
|---|---|---|
| 2026-10-09 | DAL | ir.delta.com |
| 2026-10-13 | JPM | company Business Wire release via syndicated copy (wire-copy caveat) |
| 2026-10-13 | UNH | unitedhealthgroup.com |
| 2026-10-14 | BAC | newsroom.bankofamerica.com |
| 2026-10-16 | TRV | issuer-confirmed per M2 `50d589a2` |
| 2026-10-20 | GE | geaerospace.com |
| 2026-10-20 | NFLX | Netflix release (PR Newswire PDF) |
| 2026-10-20 | UAL | United release |
| 2026-10-21 | CB | issuer-confirmed per M2 `50d589a2` |
| 2026-10-21 | IBM | ibm.com, **preliminary** per the page itself, so it does not yet clear criterion 1 |
| 2026-10-21 | TSLA | ir.tesla.com table + 8-K exhibit, read as excerpts |
| 2026-10-22 | AAL | news.aa.com |
| 2026-10-28 | GEV | gevernova.com |
| 2026-10-29 | LLY | investor.lilly.com |
| 2026-10-29 | MRK | merck.com |
| 2026-10-30 | CVX | Chevron advisory (call date) |
| 2026-11-18 | TGT | corporate.target.com (on the window edge) |

All other in-window earnings rows remain (E). Companies including MSFT, GOOGL, META, AAPL, AMZN, AMD, INTC and XOM have not yet posted their notices; their IR pages were checked and showed nothing. **Re-check them next cycle.**

### 1B.3 — FDA PDUFA dates in window

This is a floor. Three of last cycle's in-window rows resolved early or were withdrawn, and one more turned out to have been decided before last cycle was written (1A.9 items 1–4). RTTNews describes the October calendar as "relatively light".

| Date | Ticker | Drug / indication | Tag | C-eligible | Note |
|---|---|---|---|---|---|
| 2026-10-09 | RHHBY | Tecentriq + chemo / stage III dMMR-MSI-H colon | (C) | **NO — ADR** | pending |
| 2026-10-17 | VTRS | MR-141 (phentolamine 0.75%) / presbyopia | (2S) | yes | pending; Opus partnered |
| Oct, no day | RHHBY | Enspryng / thyroid eye disease | (T) | **NO — ADR** | new, low confidence |
| 2026-10-26 | GSK | Bepirovirsen / chronic hep B | (C) | **NO — ADR** | pending |
| 2026-10-30 | INO | INO-3107 (BLA) / RRP | (C) | yes | pending, multi-sourced (one tracker quotes 89% approval odds) |
| 2026-11-14 | BTAI | BXCL501 at-home / agitation | (2S) | yes | new; micro-cap, so a defined-risk chain is unlikely to be usable |
| 2026-11-14 | CYTK | oHCM sNDA | (E) | yes | new, single source |
| 2026-11-17 | Beren | Adrabetadex | (2S) | **NO — not listed** (private issuer as far as found, INFERRED) | carried |

Out of window, named so they are not re-discovered: SMMT EGFRm NSCLC (11-14 per one tracker, but the entry reads as a filing date, not a PDUFA, so it is not carried), CAPR and SVRA (both extended to 11-22), BBIO (11-27), VRTX and COGT (11-30).

---

## PART 2A — Strategy A ranked shortlist

W4 reads this PART verbatim and enqueues thesis-construction entries for the ranked shortlist; D2 runs them. Rankings and date specifics are therefore explicit.

### The A-queue census — the PINNED query, run verbatim

```sql
SELECT * FROM state.open_queue WHERE strategy = 'A'
```

**It returns 44 rows**, reconciled ticker by ticker to that count: AAPL, ADBE, AKAM, AMAT, AMD, AMZN, AVGO, CAT, CRM, CRWD, CSCO, CVX, DDOG, DELL, FSLR, GEV, GOOGL, HD, HPE, IBM, INTC, INTU, JPM, LLY, META, MRK, MRVL, MSFT, MU, NBIS, NOW, NTAP, NVDA, OKTA, ORCL, PANW, QCOM, SMCI, SNOW, TGT, TTWO, VRTX, WMT, XOM. All are `item_type` "Strategy A queue", status pending, `due_date` NULL. **Zero Strategy A `events.queue_events` rows landed in the catch-up window** (2026-09-27 08:27 UTC → now), so the census is unchanged from last cycle. `Watchlist.md`'s extra row is again **TSM**, an ADR deliberately kept in the file so its reasoning survives and correctly absent from the live queue. **The query wins.** Gate marks exist only in four rows' payloads (`spent_by_gate_likely` on XOM, CVX, MRK and JPM). That is the open W4/W1 enqueue-boundary gap (`ops.alerts` `559ee98c`), which this run does not re-raise.

**One contract-identity flag for whoever constructs the XOM thesis.** IBKR now resolves XOM to "ExxonMobil Holdings Corp", NYSE, conid **895178251**; the plain legacy listing is no longer returned by contract search. Any XOM order craft must resolve the contract fresh rather than reuse a stored conid. Recorded for D2, not acted on here.

### STEP 1 — the GATE DATE, re-derived from scratch, with the arithmetic shown

**DERIVED GATE DATE = 2026-11-02.** This is the fourth consecutive cycle at this date. This cycle also checks a path no prior cycle examined: the out-of-cycle M1R re-score.

**Router state read first.** A's `STRATEGY_ACTIVATION` reads **DO-NOT-ACTIVATE** (`state.current_regime`, event `3883e492`, as_of 2026-10-02, M4 2026-10 carry-forward, NO FLIP). Its rationale matters below. M1b's raw call for A is DO-NOT-ACTIVATE **on its own reasoning**, A's growth/policy override is DISARMED, the universal acute override is **inert** for A, and the technical leg is also DO-NOT-ACTIVATE (breadth WEAK 41.15%). The planes agree. **A is not parked by the shock.** CATALYST-GATE MODE is therefore live, not inert.

**PRICE leg** (MEASURED, `state.rerisking_limb_status`, `as_of_denver` 2026-10-04): `shock_overlay_state` **acute** since 2026-08-01 · `brent_baseline` **84.73** (43 obs, 2026-06-01..07-31) · `brent_peak` **108.75** · `brent_current` **102.31** as of 2026-10-01 · `brent_retrace_trigger` **96.74** = (84.73 + 108.75)/2, reproduced · `leg_b_basis` **not_retraced** · `leg_b_price_leg` **FALSE** · `sql_limbs_fired` **FALSE**.

Required fall on the view's own basis: (96.74 − 102.31)/102.31 = **−5.44%**. Last cycle it was −9.25%. **Most of that apparent 3.8pp improvement is not price.** It is the 2026-09-29 November → December contract roll (1A.9 item 10; `0c7fcaec`). The view compares a December-contract `current` against a November-contract peak and trigger. Like-for-like, December 102.31 sits about **5.5–6.4 above** its November equivalent (spreads of 5.47 on 09-30 and 6.43 on 09-29), so the November-basis current is roughly **107.8–108.7**. That puts the required fall at **≈ −10% to −11%**, slightly *wider* than last cycle's −9.25%, and the like-for-like retracement at only ~25–30% (M1a's own figure, `5d3998df`: ~30% at the 10-01 close). Read honestly, the price leg moved *away* from clearing this week. The view's −5.44% headline flatters it, and the next roll (December → January, ~2026-10-29) will flatter it again. The 10-01 session took December Brent **+4.4%** on stalled Iran talks (D1 `3ec80668`).

**QUIET-CLOCK leg — 15 trading days clear of the most recent qualifying shock-cluster member.** No new physical supply event (strike, blockade, export ban) appears in the warehouse after **2026-09-23**, the Libya El Sharara blockade plus the proposed US diesel-export ban that last cycle adopted as the anchor (`e01d9ca6`, `3b1fa412`). The in-window energy entries are diplomatic: US–Iran talks reported 09-25 (`de515993`), the "Iran deal rejected" crude bid on 09-28 (`8d0b7dee`) and "stalled Iran talks" with XLE +1.95% on 10-01 (`3ec80668`). None is a new disruption event, so the anchor does not move.

**One disagreement in the fleet, and why it does not matter here.** M1a's 2026-10-01 rubric row (`3b6d1923`) names **2026-09-11** (the Petroline drone strikes) as the most recent qualifying event and treats later flows as recovery. W1 last cycle adjudicated 09-23 as a cluster member (Brent +4.62% / +8.19% over two sessions, larger than the 09-15 peak-setting print). Counting off `state.market_calendar`:
- **Anchor 09-23 → the 15th trading day after it is 2026-10-14**: 09-24(1) 09-25(2) 09-28(3) 09-29(4) 09-30(5) 10-01(6) 10-02(7) 10-05(8) 10-06(9) 10-07(10) 10-08(11) 10-09(12) 10-12(13) 10-13(14) **10-14(15)**.
- **Anchor 09-11 → the clock cleared 2026-10-02**: 09-14(1) … 09-30(13) 10-01(14) **10-02(15)**.

Both fall well before 2026-11-02, so **the gate is the same under either anchor.** The disagreement matters for the date the shock could first be downgraded, not for this cycle's classifications.

**Scheduled re-scores** (`monthly_ftd`): 2026-10-01 has **passed**. It was actually scored (the M1a catch-up landed 2026-10-02) and both legs held `acute`. The next ones are **2026-11-02**, 2026-12-01 and 2027-01-04. **2026-11-02 is NOT provably unreachable.** The price leg can clear at any time, and the quiet clock has cleared or will clear by 10-14, so 11-02 is the gate.

**THE OUT-OF-CYCLE PATH, examined explicitly for the first time.** Since 2026-09-05 a second route to a re-score exists. D2a's RE-RISKING LIMB EVALUATION queues a `PENDING_REGIME_REFRESH` item when `sql_limbs_fired`, M1R re-scores all five axes blind the next morning, and D2 queues the affected router review the same evening (D2 item 4). W2 corrected its own B-side text for exactly this on 2026-09-06. CATALYST-GATE MODE's STEP 1 still names only "M1a/M1b". So: **could this path open A before 2026-11-02?**
- `sql_limbs_fired` needs ALL of (a) dwell ≥ 15 (TRUE for A, 113 trading days), (c) technical leg HEALTHY (**FALSE**: breadth WEAK 41.15, needs ≥ 50), (b) price retraced (**FALSE**, above) and the axis still `acute` (TRUE). Two of the four conjuncts are false today.
- Even if they flipped, M1R scores only the shock structure differently. The rubric requires BOTH the quiet leg and ≥ 50% retracement before it may downgrade `acute` to `latent`. And **A's DO-NOT-ACTIVATE does not rest on the shock.** It rests on M1b's raw reasoning plus a DO-NOT-ACTIVATE technical leg, with the acute override inert. M1R re-scores off the same macro substrate M1a ingested (it does not re-ingest), so the non-shock axes would very likely re-score unchanged, and a `latent` shock does not by itself change A's raw call.
- **Verdict: on present evidence the out-of-cycle path does not make an earlier A activation reachable, and the gate stays 2026-11-02.** This is a reasoned conclusion, not a mechanical proof. A B or D candidate, whose DO-NOT-ACTIVATE IS override-manufactured, would get a different answer. The spec gap (STEP 1 is silent on M1R) is routed to W5 rather than patched here. See "Coverage, provenance and what this cycle changed".

**FAIL-OPEN status: not triggered.** `state.rerisking_limb_status` read cleanly, both legs were derivable, and A reads DO-NOT-ACTIVATE.

### STEP 2 — the DIRECTION rail, run FIRST

Strategy A is **long-only** (`strategy/03_strategy_a.md`, "Long-only (no short positions in A — short is B's territory)"). A candidate whose hypothesized mispricing is that the name is **over**-valued cannot produce an A entry at any conviction. The rail ran before ranking.

**Nine names are `DIRECTION-INADMISSIBLE (A long-only rail)` and one is direction-unresolved**, the same set as last cycle. No new evidence this week reverses any direction. All are ranked and carried below the actionable tier, as evidence for the divergence record and for Strategy B's sub-pattern taxonomy.

**The airline thesis now has confirmed dates.** DAL 10-09, UAL 10-20 and AAL 10-22 are all (C) this cycle, so it is the best-dated bearish cluster in the file. It remains categorically inadmissible for A, and B also reads DO-NOT-ACTIVATE (pending `div-B-202609-1`, attacker 2026-10-05, orchestrator 2026-10-06). That review is the one place in the coming week where the cluster could find a home.

### STEP 3 — classification and counts

A candidate is `SPENT-BY-GATE (gate 2026-11-02)` iff it carries a dated catalyst strictly before 2026-11-02 and no dated catalyst on or after it. Undated or conflicting-straddle is `GATE-SURVIVING` (fail-open). A name with both a spent and a surviving catalyst is surviving.

**48 ranked candidates + 9 DIRECTION-INADMISSIBLE = 57 carried. Against the 2026-11-02 gate: 40 GATE-SURVIVING, 17 SPENT-BY-GATE.** The spent seventeen are XOM, CVX, GEV, NOW, IBM, LLY, GOOGL, MRK, INTC, AAPL, META, GE, BAC and V among the ranked names, plus DAL, UAL and AAL among the inadmissible.

The gate did not move. Five names changed class because their dates moved:
- **Spent → surviving (2):** **MU** and **CCL**. Their old catalysts printed (09-30, 09-29) and their next prints (12-23, 12-18) are post-gate.
- **Surviving → spent (3):** **NOW** (10-28 E), **IBM** (10-21 C, preliminary) and **LLY** (10-29 C), all newly dated before the gate.
- **Same class, weaker basis:** **CAT** survives as before, but now on fail-open (date withdrawn) rather than on an established 11-04.

**A reconciliation note against last cycle's headline.** The 2026-09-27 artifact stated 34 surviving / 23 spent. Re-counting the marks that artifact itself assigned gives about 16 spent: 12 ranked plus DAL, UAL, AAL and CCL. Its headline does not reproduce from its own per-name marks. This cycle's 17 is counted name by name above. The week-over-week comparison should be read as roughly 16 → 17, not 23 → 17. The per-name marks, not the headline, are what W4 consumes.

Dating names is the only thing that can convert a fail-open survivor into a spent name. This cycle dated many, but mostly on the post-gate side (the late-November / early-December software and hardware cluster), so the mode removed little additional work.

### TOP-10 — the actionable tier

All long. All rail-checked against this cycle's measurements (1A.8 / 1A.11). **9 of 10 GATE-SURVIVING, 1 SPENT-BY-GATE** (XOM, kept for conviction; see #9).

**1. TTWO — Take-Two Interactive.** (a) **Bullish**, under-valued. (b) GTA VI is the largest entertainment launch ever attempted, and the market has repeatedly discounted Rockstar's ability to hold a date. Two prior cycles re-confirmed the date against Rockstar and TTWO IR, and it held both times. Supporting: TTWO's last two 10-Qs on deferred-revenue mechanics and the preload schedule. Tape: +0.64% on the week, flat into the catalyst. (c) **GTA VI launch 2026-11-19 (C)**, preload 11-12; FQ2 earnings **2026-11-05 (E)**. (d) On the A queue since 2026-08-09; no open position in any strategy. (e) **Top-10.** GATE-SURVIVING; both catalysts are post-gate, the launch by 17 days. Unchanged at #1: still the best-dated, highest-magnitude single-company catalyst in the file.

**2. NVDA — NVIDIA.** (a) Bullish. (b) The AI-compute and memory re-rating read-through; FQ2 10-Q, last four transcripts, GTC materials. Live objection, carried and unresolved: the circular-financing critique (2026-07-27). Tape: +3.95% on the week, +1.34% on the unattested Friday. (c) Earnings **2026-11-18 (E)**, with one aggregator saying 11-17 (both post-gate); GTC Washington DC 11-30 → 12-03 (E). (d) Queued 2026-05-09; no open position. (e) Top-10. GATE-SURVIVING.

**3. VRTX — Vertex Pharmaceuticals.** (a) Bullish. (b) BLA/sNDA submission announcements plus the most recent 10-Q pipeline disclosure: two independent regulatory decisions in a five-week band, and the closed Crinetics acquisition (2026-09-01) broadening the endocrine pipeline. **Adverse tape, carried and NOT explained by anything in the warehouse:** −3.07% on 10-01 (522.81 → 506.74) and −4.08% on the week. No decision_log row records a cause. The aggregator-estimated ~$8.8B Q3 IPR&D charge from Crinetics is a known, non-cash item and is not obviously the explanation. D1 should attribute this move. (c) Earnings **2026-11-02 (E, NEWLY DATED)**, ON the gate date, so not strictly before; **povetacicept PDUFA 2026-11-30 (C)**; Journavx sNDA PDUFA 2026-12-05 (2S). (d) Queued 2026-07-05; no open position. (e) Top-10. GATE-SURVIVING on substance, not fail-open: both regulatory catalysts are post-gate.

**4. FSLR — First Solar.** (a) Bullish. (b) A fully specified, quantified, primary-sourced policy catalyst: the Sec 232 tariff regime (whitehouse.gov). Its date, mechanism and magnitude are all documented by the party imposing it. Tape: −1.74% on the week. (c) **Sec 232 regime effective 2026-12-04 (C)**, surviving; earnings **2026-10-29 (E)**, spent. (d) Queued 2026-09-06; no open position. (e) Top-10. **GATE-SURVIVING** on the both-catalysts reading.

**5. AVGO — Broadcom.** (a) Bullish. (b) Custom-silicon and AI-networking attach. Counter-evidence carried: the BofA note on a ~$370B AI-debt vehicle (2026-08-14, −5.94%). Tape: +3.35% on the Friday, +0.66% on the week. (c) Earnings **2026-12-09 (E)**, one day earlier than last cycle's estimate; the text matches Broadcom's own release boilerplate but the page was not read. (d) Queued 2026-05-09; no open position. (e) Top-10. GATE-SURVIVING. *Up from #7*, because CAT lost its date and XOM/CVX are spent.

**6. CSCO — Cisco.** (a) Bullish. (b) AI-networking order growth against a durably low multiple. Objection carried: valuation reset after the +12.96% session. **Tape: +5.15% on the week to a new high of 112.23, +3.16% on Friday, with no catalyst recorded anywhere in the warehouse.** That is either the market pricing in the thesis ahead of the print, which reduces the remaining misalignment, or a cohort move with XLK (+1.80% on the week). Both readings argue for urgency in construction, not for a higher rank. (c) Earnings **2026-11-11 (E)**; aggregators split 11-11 / 11-12 / 11-18, all post-gate. (d) Queued 2026-05-09; no open position. (e) Top-10. GATE-SURVIVING. *Up from #9.*

**7. CAT — Caterpillar.** (a) Bullish. (b) Data-centre and energy capex pull-through, plus the Fabick dealer acquisition expected to close late October (single aggregator snippet). Tape: +2.31% Friday, +2.90% on the week, to 845.42. (c) **Earnings date NOT ESTABLISHED this cycle**: the 11-04 (E) row was withdrawn because FMP no longer lists CAT and aggregators split 10-28 / 10-29 / 11-04, straddling the gate (1A.9 item 8). (d) Queued 2026-05-01; no open position. (e) Top-10. **GATE-SURVIVING on fail-open, not on an established date.** *Down from #5* for exactly that reason. Last cycle's promotion rested on the date; the date did not hold, so the promotion is unwound. If Caterpillar's own notice lands 10-28 or 10-29, CAT becomes SPENT next cycle.

**8. AMD — AMD.** (a) Bullish, **contested** on competitive position rather than direction, so the rail does not engage. (b) Counter-evidence carried and material: the exclusive SpaceX AI-compute socket lost to NVDA (2026-08-05). Supporting: the 2026-09-21 semis tape. Tape: +2.95% Friday, +0.52% on the week. (c) Earnings **2026-11-03 (E)**. AMD's IR shows no notice yet, and its pattern (announcing ~4 weeks ahead) puts the notice around 10-06 to 10-08. (d) Queued 2026-05-29; no open position. (e) Top-10. GATE-SURVIVING **by a single day**. A one-day margin is not robust to a date revision. Re-check against AMD's own notice next cycle.

**9. XOM — ExxonMobil.** (a) Bullish. (b) **Reduced per the mode, with no first-party document chase.** The supply-shock seam has held for a second week without a new physical event: Brent December +4.4% on 10-01 on stalled Iran talks, XLE +1.26% on the week. (c) Earnings **2026-10-30 (E)**; ExxonMobil has posted no notice yet, and one uncorroborated source says 10-23. (d) Queued 2026-09-13; no open position. **Contract identity changed in IBKR (conid 895178251), see the census.** (e) Top-10. **SPENT-BY-GATE (gate 2026-11-02)**, kept in tier on conviction as the single representative of the energy seam. **CVX is moved out of the tier (#11)**, because XOM and CVX are one concentration decision, not two, and that decision does not need two actionable slots.

**10. MSFT — Microsoft.** (a) Bullish. (b) Azure AI capacity commentary; last four transcripts. (c) Earnings **2026-10-28 (E)**, spent; **Ignite 2026-11-17 → 11-20 (C)**, surviving. (d) Queued 2026-07-05; no open position. (e) **Top-10, newly promoted from #13.** GATE-SURVIVING on the both-catalysts reading. It takes the slot CVX vacated, as the strongest-evidenced surviving name below the tier.

### 11–20

**11. CVX — Chevron.** (a) Bullish. (b) Reduced per the mode; the same seam as XOM. (c) Earnings call **2026-10-30 (C)**, now company-confirmed. (d) Queued 2026-09-13; no open position. (e) 11–20. **SPENT-BY-GATE (gate 2026-11-02).** *Down from #8* on concentration, not conviction.

**12. MU — Micron.** (a) Bullish. (b) Last cycle demoted MU because its thesis (DRAM contract prices forecast up more than 50% this quarter, NAND ~+60%; D1 `a913941a`) would be *consumed* by the 09-30 print. It was. MU printed FQ4 on 09-30, rose +3.03% on 10-01 and gave back −2.05% on 10-02. A November thesis cannot be early to that. **What is new is a fresh catalyst:** FQ1 FY27 **2026-12-23 (E)**, post-gate. A thesis built on it must be a *new* one (guidance durability, contract-price follow-through into the February quarter), not the old one re-dated. (c) **2026-12-23 (E)**. (d) Queued 2026-05-09; no open position. (e) 11–20. **GATE-SURVIVING on the new date.** *Flagged for W4/D2: the queue row's catalyst reference is the consumed 09-30 print and should be read as stale.*

**13. ORCL — Oracle.** (a) Bullish. (b) Reduced depth is not warranted, because the name now has a post-gate date. The AI-capex backlog thesis stands on the corrected tape (−3.65% close-to-close on the 09-14 session, not −13.79%; D1 `4264b87f`). (c) **FQ2 ~2026-12-10 or 12-14 (E)**; CloudWorld 10-25 → 10-28 (C) is spent. Last cycle's "no date" was a stale read: FQ1 printed 2026-09-10 (1A.9 item 5). (d) Queued 2026-05-09; no open position. (e) 11–20. GATE-SURVIVING, now on a date rather than fail-open.

**14. AMZN — Amazon.** (a) Bullish. (b) AWS backlog and margin disclosures; 10-Q Note 10. (c) Earnings 2026-10-29 (E), spent; **re:Invent 2026-11-30 → 12-04 (C)**, surviving. (d) Queued 2026-07-12; **two open Strategy D lots** (`D:AMZN:2026-07-09`, `D:AMZN:2026-07-30`). (e) 11–20. GATE-SURVIVING.

**15. GEV — GE Vernova.** (a) Bullish. (b) Reduced per the mode. Electrification and grid capex. Adverse evidence carried: GLJ Research Sell, $470, 2026-09-14 (−8.6189%). (c) Earnings **2026-10-28 (C)**, now company-confirmed. (d) Queued 2026-08-09; **open Strategy D lot `D:GEV:2026-08-03`**. (e) 11–20. **SPENT-BY-GATE.**

**16. QCOM — Qualcomm.** (a) Bullish. (b) Stellantis Snapdragon expansion; auto/IoT diversification. (c) **2026-11-11 (E), NEWLY DATED**. (d) Queued 2026-05-01; no open position. (e) 11–20. GATE-SURVIVING, now on a date.

**17. MRVL — Marvell Technology.** (a) Bullish. (b) Custom-silicon ramp. (c) **NOT ESTABLISHED (T)**; the only aggregator row is internally inconsistent. (d) Queued 2026-05-25; no open position. (e) 11–20. GATE-SURVIVING (fail-open).

**18. DELL — Dell Technologies.** (a) Bullish. (b) AI-server capex; +11.9776% on 2026-09-10. (c) **2026-11-24 (E), NEWLY DATED**. (d) Queued 2026-05-17; no open position. (e) 11–20. GATE-SURVIVING.

**19. UBER — Uber.** (a) Bullish. (b) The ~3,300-role restructuring's margin effect lands in this print. (c) Earnings **2026-11-03 (E, FMP)**; one aggregator says **10-29**. **The conflict straddles the gate**, so the name is GATE-SURVIVING on fail-open. (d) **NOT on the A queue**, so new intake if W4 converts it; **open Strategy D lot** `D:UBER:2026-07-09`. (e) 11–20. GATE-SURVIVING.

**20. PLTR — Palantir.** (a) Bullish. (b) Government and commercial bookings. (c) Earnings **2026-11-02 (E, FMP)**, ON the gate date; one aggregator says 11-09. Either way not strictly before the gate. (d) Not on the A queue. (e) 11–20. GATE-SURVIVING, still the thinnest margin in the file: any revision earlier by one day flips it.

### 21–30

**21. SNOW — Snowflake.** Bullish; Cortex AI monetisation and the $6B AWS commitment. New in window: a **$3.5B convertible** (D1 `e3c878dc`, 09-28), dilution evidence to carry into construction. (c) **2026-12-02 (E), NEWLY DATED.** (d) Queued 2026-05-25. (e) GATE-SURVIVING.
**22. CRM — Salesforce.** Bullish; agentic-AI attach against a compressed multiple. (c) **NOT ESTABLISHED**: only past quarters surface, and early December is INFERRED from the prior-year pattern. Dreamforce is spent. (d) Queued 2026-05-17. (e) GATE-SURVIVING (fail-open).
**23. NOW — ServiceNow.** Bullish; platform attach. Note the unverified WDAY take-private report (1A.7), a possible software-multiple read-through, recorded but unweighted. (c) **2026-10-28 (E), NEWLY DATED.** (d) Queued 2026-05-29. (e) **SPENT-BY-GATE (gate 2026-11-02)**, newly spent this cycle.
**24. PANW — Palo Alto Networks.** Bullish; platformisation. (c) FQ1 FY27 **11-12 or 11-18 (T)**, both post-gate; FQ4 already printed 09-01. (d) Queued 2026-05-31. (e) GATE-SURVIVING.
**25. CRWD — CrowdStrike.** Bullish; module attach. (c) **2026-12-01 (E), NEWLY DATED.** (d) Queued 2026-05-31. (e) GATE-SURVIVING.
**26. JPM — JPMorganChase.** (a) Bullish. (b) Reduced. The NIM-supportive-hike arithmetic is intact and the 10-year rose further (5.24–5.29%), but the adverse tape compounded: **XLF −2.46% on the week** (54.84 → 53.49), another adverse banking read on top of the three sessions recorded last cycle. (c) Earnings **2026-10-13 (C)**, spent; **Investor Day 2027-02-22 (C)**, surviving. (d) Queued 2026-09-13. (e) GATE-SURVIVING on the Investor Day only. Held down for the tape, not the gate.
**27. HPE — Hewlett Packard Enterprise.** Bullish; the same AI-server read-through as DELL. (c) **2026-12-03 (E), NEWLY DATED.** (d) Queued 2026-05-29. (e) GATE-SURVIVING.
**28. NBIS — Nebius Group.** Bullish; neocloud capacity. New context: OpenAI's reported training pause (D1 `e3c878dc`, 09-28) is a demand-side counter-signal for neocloud capacity, carried. (c) **NOT ESTABLISHED** (10-22 / 11-10 split, straddling the gate). (d) Queued 2026-05-13. (e) GATE-SURVIVING (fail-open).
**29. DIS — Disney.** Bullish; SVOD margin expansion. (c) Earnings **2026-11-12 (E)**; Believe ship reveal 10-07 (E) is spent. (d) **Not on the A queue**; two open Strategy D lots. (e) GATE-SURVIVING.
**30. SHOP — Shopify.** Bullish; GMV take-rate. (c) Earnings **2026-11-03 (E)**. (d) Not on the A queue. (e) GATE-SURVIVING.

### 31–40

**31. IBM** — earnings **2026-10-21 (C, preliminary)**, **SPENT-BY-GATE**, newly dated; queued 2026-05-29. **32. DDOG** — **2026-11-05 (E)**, newly dated, surviving; queued 2026-05-07. **33. OKTA** — **12-01/12-02 (E)**, surviving; queued 2026-05-29. **34. NTAP** — **2026-12-01 (E)**, surviving; queued 2026-05-29. **35. SMCI** — **2026-11-03 (E, "not confirmed")**, surviving; queued 2026-05-29. **36. MRNA** — **2026-11-05 (E)**, surviving; not queued. **37. LLY** — earnings **2026-10-29 (C)**, **SPENT-BY-GATE**, newly dated (it survived last cycle only on fail-open); queued 2026-05-01. Carries a terminal Strategy D NO-GO dated 2026-09-14, which is context, not a barrier (`Operating_Protocols.md` §3), and a different strategy's criteria. **38. INTU** — **no firm date**: Intuit says it will announce the date at quarter end; Investor Day held; queued 2026-08-03; GATE-SURVIVING (fail-open). **39. GOOGL** — earnings 10-28 (E); the DOJ dates passed; **SPENT-BY-GATE**; queued 2026-07-05; two open D lots. **40. MRK** — earnings **10-29 (C)**, ESMO investor event **10-26 (C)**, and **both in-window PDUFAs gone** (Welireg + Lenvima approved early; I-DXd BLA withdrawn 09-25): **FULLY SPENT-BY-GATE**. The withdrawal is real adverse evidence against any MRK pipeline thesis. Queued 2026-09-13.

### 41–48

**41. INTC** — earnings 2026-10-22 (E), **SPENT-BY-GATE**; queued 2026-05-12. **42. AAPL** — earnings 2026-10-29 (E), **SPENT-BY-GATE**; queued 2026-05-02. **43. META** — earnings 2026-10-28 (E), **SPENT-BY-GATE**; −4.79% on 09-28 on its enterprise-AI launch and senior hire (D1 `e3c878dc`); queued 2026-08-03. **44. UNH** — earnings **2026-10-13 (C)** spent; investor conference ~early December (E) surviving, so **GATE-SURVIVING**; not queued. **45. GE** — earnings **2026-10-20 (C)**, **SPENT-BY-GATE**; not queued. **46. BAC** — earnings **2026-10-14 (C)**, **SPENT-BY-GATE**; not queued. **47. V** — earnings 2026-10-27 (E) and DOJ discovery close 10-16 (C), **SPENT-BY-GATE**; not queued. **48. TGT** — earnings **2026-11-18 (C)**, GATE-SURVIVING, but **DIRECTION UNRESOLVED**: the prior bearish thesis was refuted by a beat-and-raise and no replacement direction has been established. Held below the tier for that reason, not for rank. Queued 2026-05-09.

### DIRECTION-INADMISSIBLE tier — ranked and carried, never actionable for A

These belong to Strategy B. The rail governs only admission to the actionable tier.

| # | Ticker | (a) Direction | (c) Catalyst | Gate status | Thesis |
|---|---|---|---|---|---|
| I-1 | **DAL** | Bearish | Earnings **2026-10-09 (C)** | SPENT | Fuel hedge books set before the September shock; the proposed US diesel-export ban attacks the distillate crack. First airline to report, now company-confirmed |
| I-2 | **UAL** | Bearish | Earnings **2026-10-20 (C)**, AMC | SPENT | Same shock, independent print. Date corrected from 10-21 (1A.9 item 7) |
| I-3 | **AAL** | Bearish | Earnings **2026-10-22 (C)** | SPENT | Same shock, thinnest balance sheet of the three |
| I-4 | **CCL** | Bearish | Earnings 2026-12-18 (E) | SURVIVING | Bunker-fuel channel. Q3 printed 2026-09-29, and the read-through was taken in the B index (D2 `a501f39b`, window closes 10-12) |
| I-5 | **AMAT** | Bearish | Earnings **2026-11-12 (E)**, newly dated | SURVIVING | China WFE cliff |
| I-6 | **WMT** | Bearish | Earnings **2026-11-19 (C)** | SURVIVING | Two adverse datapoints against the original bullish framing |
| I-7 | **ADBE** | Bearish | Earnings 2026-12-09 (E) | SURVIVING | Vindicated on tape |
| I-8 | **HD** | Bearish / neutral | Earnings **2026-11-17 (E)**, newly dated | SURVIVING | Housing-turnover starvation, now under a 5.2%+ 10-year |
| I-9 | **AKAM** | Bearish / contested | NOT ESTABLISHED (11-05 / 11-10 split) | SURVIVING | The smallest cap in the file |

**W4 side, restated because it binds:** no candidate marked `DIRECTION-INADMISSIBLE` may be converted into a Strategy A `PENDING_ANALYSIS` row, and a vacated slot is filled from the next admissible candidate rather than shipping a short top-10. None of the nine is in the top-10.

### Handoff notes for W4

- **All ten top-10 names are already on the A queue** (TTWO, NVDA, VRTX, FSLR, AVGO, CSCO, CAT, AMD, XOM, MSFT; verified against the 44-row census). **W4 has ZERO new A intake from the top-10 this week**, the fifth such cycle. That is the steady state, not a sign the limb failed to run.
- **One tier change W4 should see:** MSFT enters at #10 and CVX leaves to #11. Both are already queued, so this changes ranking, not queue membership.
- **Candidates below the top-10 that are NOT on the A queue**, if W4's limb ever reaches past tier 1: UBER (#19), PLTR (#20), DIS (#29), SHOP (#30), MRNA (#36), UNH (#44), GE (#45), BAC (#46), V (#47).
- **Carry the gate mark onto the queue row** (`ops.alerts` `559ee98c`, open). The one spent name in this cycle's actionable tier is **XOM**. **MU's queue row now references a consumed catalyst** (the 09-30 print); its live catalyst is 12-23 (E).
- **Cross-strategy overlap (§E).** `state.current_positions` returns 12 open rows, **all Strategy D**: zero open A, B or C positions. The overlap tickers are AMZN, DIS, GEV, GOOGL, ISRG, RTX, TSM and UBER. None is in the top-10.
- **Prior NO-GO records:** the only NO-GO in the window is NKE (Strategy D, conservative-default DECLINE, `6e315b07`, 2026-09-27). NKE is not a candidate. The earlier NO-GOs on queued names are B or D dispositions under different criteria: context, not barriers (`Operating_Protocols.md` §3).
- **Re-check next cycle:** AMD (one-day margin; notice expected ~10-06 to 10-08), CAT (date withdrawn; it becomes SPENT if Caterpillar confirms 10-28 or 10-29), PLTR (on the gate) and XOM (10-30 vs an uncorroborated 10-23).

---

## PART 2C — Strategy C ranked shortlist

### Router state, and what it admits

C reads **`HYBRID ACTIVATE (FOMC-only) — PENDING div-C-202609-1`** (`state.current_regime`, event `33a7cd6e`, as_of 2026-10-02, M4 2026-10 carry-forward, NO FLIP). M1b's raw fundamental call for C is DO-NOT-ACTIVATE. The operative state stays HYBRID FOMC-only from `div-C-202608-1` until the incoming review completes. **That review is THIS WEEK**: attacker 2026-10-05, orchestrator 2026-10-06, default RETAIN the prior operative state. Under the carve-out, only an FOMC-type event is router-admissible. Corporate earnings and FDA PDUFA candidates are **router-PARKED** and must not be enqueued. Widening beyond FOMC-only stays reserved to a separate scope-widening adjudication; none is open.

**The one router-eligible event in the 45-day window is the 2026-10-28 FOMC.** If `div-C-202609-1` returns DO-NOT-ACTIVATE on 10-06, it is not eligible either, and W4/D2 must read the router after 10-06, not this file.

### The capital position

C is a **NOMADIC** strategy (`state.strategy_nomadic_status.is_nomadic` TRUE; `bigquery/167`). It holds no standing capital by design, and its trade size is not bounded by its residual cash. The real constraint is borrow capacity, which is **ZERO**, MEASURED:

| strategy | donor_capacity_total | donor_count | borrow_blocked |
|---|---|---|---|
| C | **0** | **0** | **TRUE** |

The donor set is empty because A, B and E are all `capital_enabled: FALSE` and D is itself nomadic. E holds **$12,672.77** of idle cash and is capital-disabled. `state.nomadic_capital_ledger` records C at `swept_out_total` **$9,464.72**, `restored_total` **$0**. C's NAV is **$19.49**, unchanged on the week; last cycle's −17.6% NAV drift did not repeat. **Already alerted, not re-raised:** `ops.alerts` `71d484fa-0623-4443-89ed-a357ab305f67` (`nomadic_borrow_blocked`, warning, open since 2026-09-23). `INCIDENT[ref=71d484fa]`. **C has never opened a position**, so the realized cost of the blocked borrow is still $0.

### Criterion 1 (a qualifying event within 45 days)

- **FOMC 2026-10-28 is (C)**, from a direct federalreserve.gov fetch this run. It clears.
- **Earnings: no longer a blanket provenance failure.** Seventeen in-window earnings dates are company-confirmed (1B.2); IBM is preliminary, so sixteen clear criterion 1 on provenance. Every one is router-PARKED under FOMC-only, so this changes nothing actionable this week. It does mean a future scope widening would find a criterion-1-clean earnings set for the first time.
- **PDUFAs:** INO (C), VTRS (2S) and BTAI (2S) are US-listed and in window; RHHBY and GSK are ADRs. All router-PARKED.

### The tenor rail — CLEAR, third cycle running

C requires structure expiration within **1–45 days of entry** (`strategy/05_strategy_c.md`:21). MEASURED from the live SPY chain, the listed expiries 10-05 → 12-01 are: 10-05 through 10-09, 10-12 through 10-16 (10-16 regular), 10-19, 10-23, **10-30**, 11-06, 11-13, **11-20 (regular)**, 11-27 and 11-30. There is no 12-01 expiry; the next is 12-18. **The first expiry strictly after the 2026-10-28 decision is 2026-10-30.** Entry is due 2026-10-20 per the queued thesis, so the tenor is 10 days, inside 1–45.

### Criterion 2 (implied vs realized) — MEASURED on the spec window (trailing 30 days)

Per `strategy/05_strategy_c.md`:82 the headline is **IV/HV30**; HV20 and HV10 are context. (The window question is open with W5 as `ops.alerts` `1876c957`; this cycle simply applies the spec's own 30-day window.)

MEASURED, SPY, 2026-10-30 expiry, ATM strike **770** against the 2026-10-02 regular-session close **769.64** (IBKR, conid 756733):

| Field | Value |
|---|---|
| ATM call 770 | last 11.96, bid 11.96 / ask 12.01, OI 7,128 |
| ATM put 770 | last 9.66, bid 9.64 / ask 9.70, OI 4,034 |
| ATM straddle | mid **21.655 → $2,165.50 per contract** (ask $2,171.00) |
| `implied_vol` on the contracts | **−1.0, `is_valid` FALSE**, for both call and put, retried twice. **A change: last cycle this field was valid (12.7813%)** |
| `option_midpoint_iv` | −15.8745, `isValid` FALSE (the known sentinel, reproduced) |
| `implied_vol_underlying` (SPY) | **12.494%**, `is_valid` TRUE, but a 30-day constant-maturity figure, not the 10-30 expiry |
| Derived ATM IV (Black-Scholes on bid/ask mids, r 4%, q 1.2%, T 28/365) | call 13.34%, put 12.14%, **average 12.74%**. DERIVED and assumption-dependent, not a broker field |
| `top_status` | FROZEN (Sunday; the values are the 2026-10-02 session's) |

Realized volatility, annualized close-to-close (log returns, sample stdev, ×√252), from **31 IBKR regular-session closes**, 2026-08-20 → 2026-10-02:

| Window | Realized vol | IV/HV (derived IV 12.74%) | IV/HV (underlying IV 12.494%) |
|---|---|---|---|
| **HV30 (spec window)** | **9.640%** | **1.322** | 1.296 |
| HV20 | 10.322% | 1.234 | 1.210 |
| HV10 | 10.962% | 1.162 | 1.140 |

**Verdict: implied is still RICH to realized on the spec window, flat on the week** (1.309 → 1.322 on the derived IV, 1.296 on the broker's 30-day figure). Both are within measurement noise of last cycle, given that this cycle's IV is derived rather than read. **The realized term structure is still inverted** (HV10 > HV20 > HV30), but less so: HV10 fell 11.83% → 10.96%, so the convergence toward parity that last cycle observed at the 10-day horizon **did not continue this week.** The implied-rich condition that has blocked C's affordable structures for seven cycles is not closing on its own yet.

**A measurement-integrity note:** with `implied_vol` invalid this cycle, the headline ratio rests on a derived IV. The broker's own underlying 30-day IV gives the same verdict (1.296), so the conclusion does not depend on the derivation, but the number is less precise than last cycle's. D2's 2026-10-20 thesis run must read a live, in-session `implied_vol` before relying on any ratio here.

**The structural disjointness, unchanged.** Implied rich favours **selling** premium. A credit structure's max loss must be deterministically collateralized, and C's reachable $19.49 cannot collateralize any SPY credit spread (a 1-point spread carries $100 of gross max loss). What C can afford is confined to far-wing **debit** structures, on the **buying** side, which is the wrong side of the measured edge. The ATM straddle at $2,165.50 is ~111× C's reachable capital.

**Panel measurement deliberately NOT extended, second cycle.** Every name in the old implied-vs-realized panel is an earnings candidate and router-PARKED under FOMC-only, so measuring it buys no decision this week. The provenance improvement (1B.2) removes one of last cycle's two reasons for skipping it, but the router reason alone still suffices. **If `div-C-202609-1` widens scope, re-establish the panel before relying on the trend.**

### Ranked shortlist — 15 event candidates

**TOP-5**

**1. FOMC 2026-10-28** — (a) **No affirmative directional divergence established.** The measurable divergence is on *volatility*, and it runs against the only structures C can fund (IV/HV30 ≈ 1.32, implied rich; C can afford only the buying side). (b) federalreserve.gov meeting calendar, fetched directly. The 09-16 hike was unanimous with 16 of 18 dots for more, and the 10-year has since reached 5.24–5.29%, so this meeting is genuinely live. (c) **2026-10-28.** (d) **Structure affordable only in the far wings.** Reachable budget $19.49; ATM straddle $2,165.50 per contract; borrow capacity zero, `borrow_blocked` TRUE. **Flagged as a deferral risk, not a deferral**; the decision is not W1's. (e) No open A positions exist, so there is no A↔C conflict. (f) **Top-5, rank 1, the only router-eligible candidate in the window**, and only while `div-C-202609-1` retains HYBRID (verdict 10-06).
  **Disposition: W1 shortlists and does not drain.** `thesis-FOMC-C-20261020` is **pending** on `state.open_queue`, due **2026-10-20**, and the GO/NO-GO is **D2's on that date**, with a recorded conservative default of "Decline — no entry". It is the only FOMC row on the queue. **W4 must not create a duplicate.**

**2. INO — INO-3107 PDUFA 2026-10-30.** (a) A binary regulatory outcome; implied typically under-prices a first-approval binary in a small cap. (b) Inovio's own BLA-acceptance release plus multiple trackers (one quotes 89% approval odds, which, if the market agrees, lowers the binary's surprise content). (c) 2026-10-30. (d) Chain liquidity unverified; a small-cap chain may not support a deterministic defined-risk structure at any size. (e) No A overlap. (f) Top-5. **Router-PARKED.**

**3. TSLA — earnings 2026-10-21 (C).** (a) Implied is habitually rich into TSLA prints, a sell-side divergence that C cannot fund. (b) Tesla IR table and 8-K exhibit; Q3 deliveries of 486,532 were already reported 10-02, so the print's delivery component is known. (c) **2026-10-21, NOT 10-28**: last cycle's "same day as FOMC, confounded" flag was built on a wrong vendor date and is withdrawn (1A.9 item 6). (d) Bounded as above. (e) Not on the A queue. (f) Top-5. **Router-PARKED.** Promoted from #15 because the confound is gone and the date is (C).

**4. VTRS — MR-141 PDUFA 2026-10-17.** (a) Binary; presbyopia approval is a commercial-scale question more than an approval-probability one. (b) Now two trackers (2S). (c) 2026-10-17. (d) Bounded as above. (e) None. (f) Top-5. **Router-PARKED.**

**5. UNH — earnings 2026-10-13 (C).** (a) A post-guidance-reset print; implied may be rich after a volatile year. (b) unitedhealthgroup.com's own release, read. It is the cleanest criterion-1 earnings row in the window. (c) 2026-10-13. (d) Bounded as above. (e) Not on the A queue (A #44). (f) Top-5. **Router-PARKED.**

**REST (6–15)** — all **router-PARKED**; none has an implied vol measured this cycle (see the panel note).

| # | Candidate | (a) Hypothesized divergence | (c) Date | Tag | (e) A overlap | Note |
|---|---|---|---|---|---|---|
| 6 | **JPM** earnings | Banks keep declining to price a hike they arithmetically benefit from; XLF −2.46% on the week | 2026-10-13 | (C, wire copy) | A #26 | first bank print |
| 7 | **AMD** earnings | Post-shock semis repricing; implied likely rich into a contested print | 2026-11-03 | (E) | A #8 | first post-event expiry 11-06, inside the rail from a 10-20 entry |
| 8 | **XOM** earnings | Energy-seam second leg | 2026-10-30 | (E) | A #9 | same expiry as the FOMC structure |
| 9 | **CVX** earnings | As XOM, correlated | 2026-10-30 | (C) | A #11 | |
| 10 | **NFLX** earnings | First print after the summer content slate | 2026-10-20 | (C) | not queued | |
| 11 | **GEV** earnings | Grid-capex print after an initiated Sell | 2026-10-28 | (C) | A #15 | **same day as the FOMC, a genuinely confounded structure** (it replaces last cycle's mistaken TSLA flag) |
| 12 | **LLY** earnings | GLP-1 volume vs pricing | 2026-10-29 | (C) | A #37 | |
| 13 | **BTAI** PDUFA | Binary, micro-cap | 2026-11-14 | (2S) | none | the chain is probably unusable |
| 14 | **MRK** earnings | First print after the I-DXd BLA withdrawal | 2026-10-29 | (C) | A #40 | the PDUFA rows are gone (1A.9) |
| 15 | **CYTK** PDUFA | Binary label expansion | 2026-11-14 | (E) | none | single source |

**Dropped from last cycle's 15:** SRRK (decided 09-11, before last cycle was written), MRK I-DXd (withdrawn), MRK Welireg (decided early), PHAR (decided early), BMY Camzyos and BFRI (dates passed).

**(e) A-vs-C exclusivity is vacuous this cycle.** `state.current_positions` holds 12 open rows, all Strategy D, with **zero open A and zero open C positions**. Measured, not assumed.

**Shortlists only.** Full thesis construction per Strategy.md happens in the sessions W4 schedules.

---

## Coverage, provenance and what this cycle changed

**Read scope.** Weekly cadence. BigQuery: `state.trading_day_today`, `state.current_regime`, `state.current_positions`, `state.open_queue`, `state.rerisking_limb_status`, `state.strategy_nomadic_status`, `state.nomadic_borrow_capacity_watch`, `state.nomadic_capital_ledger`, `analytics.strategy_nav`, `state.market_calendar`, `state.signal_marks_curated`, `state.routine_catchup_window`, `state.fmp_daily_budget`, `events.decision_log`, `events.regime_events`, `events.queue_events`, `ops.alerts`, `ops.run_log`. Repo: `strategy/03_strategy_a.md`, `strategy/05_strategy_c.md`, `strategy/09_regime_scoring_strategy_blind_monthly.md` (the shock-rubric de-escalation clause only, for the M1R analysis), `bigquery/224_rerisking_limb_status.sql`, `ops/connector_tools.yaml` and the prior `Weekly_Catalyst_Calendar.md`. Live: the FMP calendar and company endpoints, IBKR (price history, option chain and snapshots, contract search), and web sources (federalreserve.gov plus company IR pages) through the sanctioned WebSearch → Tavily → IR chain.

**Catch-up window.** `state.routine_catchup_window` gives `window_days` **6.97**, against a weekly 1.5× threshold of 10.5. That is cadence-normal, so **no `CATCHUP` token is owed** and no missed-period sub-sections are needed. Evidence window: 2026-09-27 08:27:19 UTC → now.

**The daily-to-weekly boundary, honoured.** Every reused catalyst comes from in-window D1/D2/M-routine records and is cited by `entry_id`: TRV/CB dates and the WDAY report (`50d589a2`), the 09-28 META/OpenAI/SNOW items (`e3c878dc`), the 09-30 and 10-01 earnings and sector screens (`795e6fb0`, `63af8a6a`, `3ec80668`), the B index adds (`a501f39b`), rates (`8d0b7dee`, `bd235450`, `4c0487f7`), the energy-cluster record (`de515993`, `8d0b7dee`, `3ec80668`) and the Brent roll evidence (`0c7fcaec`, `5d3998df`). **No second broad news scan was run.** Web effort went only to forward-calendar acquisition and date confirmation, which W1 owns. **Warehouse coverage ends 2026-10-01** for D1/D2 (the latest `events.decision_log` row is a Q1 entry at 2026-10-02 17:18 UTC). **The Friday 2026-10-02 session is unattested by D1. That is the structural weekly gap**, not a D1 outage: W1's Sunday trigger fires before the D1 that covers Friday. Per the spec it was closed at zero cost from IBKR regular-session bars, and the Friday prints are quoted in the entries above (SPY +0.74%, XLK +1.01%, XLE +0.19%, XLF +0.06%; AVGO +3.35%, CSCO +3.16%, AMD +2.95%, CAT +2.31%, MU −2.05%). Only the narrative half of Friday is missing, and it is not re-alerted (`b4e4e563`).

**Standing constraints NOT re-alerted, per this section's own instruction:** the FMP earnings-horizon plan cap (`OWNER_ACTIONS.md` `FMP-earn-horizon`); the bulk-enumeration plan gate (`6c4004e3`); C's blocked nomadic borrow (`71d484fa`); the Friday boundary gap (`b4e4e563`); the Brent contract-roll basis in the limb view (`0c7fcaec`, with `82c99515` on the same surface); and the gate-mark enqueue gap (`559ee98c`). The horizon **movement** is reported above, because a moving horizon is new information even when the cap itself is standing.

**One new spec observation, routed to W5 rather than patched (W1 does not edit the fleet spec on a research fire).** CATALYST-GATE MODE STEP 1 derives A's gate from "A's next REACHABLE `M1a`/`M1b` re-score" and is silent on the out-of-cycle **M1R** path (D2a limb → M1R → D2 router review), which has existed since 2026-09-05 and which W2 already folded into its own B-side text on 2026-09-06. This cycle examined the path explicitly and found that it does not move A's gate, because A's DO-NOT-ACTIVATE is not override-manufactured (PART 2A STEP 1). That conclusion depends on A's current rationale, though. If A's raw call ever becomes ACTIVATE with only the acute override holding it down, an M1R downgrade could open A weeks before the next first trading day, and the mode as written would mark names spent that are reachable: the harmful, under-research direction. Filed as an `ops.alerts` info row for W5's SPEC-DEFECT NOTICE INTAKE.

**What moved this cycle, in one place.**
- **Provenance:** sixteen earnings dates became company-confirmed, and one vendor date (TSLA) was proven wrong by seven days.
- **Dates:** eleven previously undated A-queue names acquired estimated dates. Two "undated" names (ORCL, PANW) turned out to have already printed, a stale read last cycle owns.
- **PDUFAs:** three in-window rows resolved early or were withdrawn (MRK ×2, PHAR), and a fourth (SRRK) had been decided before last cycle was written, another W1 miss now corrected by checking decision status first.
- **Gate:** it held at 2026-11-02 for a fourth cycle. The price leg looks closer on the view (−5.44%) only because of a contract roll; like-for-like it moved slightly further away (≈ −10% to −11%). The quiet clock clears 10-14 (or cleared 10-02 on M1a's anchor). The out-of-cycle path was examined and does not move it.
- **Ranking:** the spent count fell 23 → 17. In the tier, **AVGO and CSCO rose**, **CAT fell** (date withdrawn), **CVX left** (concentration) and **MSFT entered**. **MU regained a post-gate catalyst but needs a new thesis.**
- **Strategy C:** criterion 2 is flat (IV/HV30 ≈ 1.32, on a derived IV because the broker's per-contract IV field was invalid), the realized-vol convergence did not continue, and the router faces `div-C-202609-1` on 10-05/10-06.

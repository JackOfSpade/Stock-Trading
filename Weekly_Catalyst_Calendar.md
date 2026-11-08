2026-W45

# Weekly Catalyst Calendar — Strategies A and C

**Run date 2026-11-08** (Sunday, `weekly_sun`). ISO week of TODAY's run date, 2026-W45. The upcoming trading week opens Monday 2026-11-09; that is context, not the marker.

**Windows.** Strategy A: 6 months, **2026-11-08 → 2027-05-08** — **effective confirmed-earnings horizon 2026-12-18 (40 days, ~5.7 weeks); sparse vendor coverage beyond it, per-name (E) fallback for shortlisted names.** Strategy C: 45 days, **2026-11-08 → 2026-12-23** (run date + 45 days, the same convention as W44's 11-01 → 12-16; the 12-09 FOMC decision sits on day 31 counting from 11-08 as day 0).

**EFFECTIVE CONFIRMED-EARNINGS HORIZON: 2026-12-18, 40 days (~5.7 weeks) from 2026-11-08. The terminal date did NOT move for a sixth week** (MEASURED: FMP chunk 1, 2026-11-08 → 2027-01-07, returned 17 rows, last row CCL 2026-12-18; chunk 2 begins 2027-01-11). Depth fell 47 → 40 days only because the clock advanced. Ten-week series, terminal date / days from that week's run date: 2026-12-03/88d (09-06), 2026-12-09/87d (09-13), 2026-12-09/80d (09-20), 2026-12-10/74d (09-27), 2026-12-18/75d (10-04), 2026-12-18/68d (10-11), 2026-12-18/61d (10-18), 2026-12-18/54d (10-25), 2026-12-18/47d (11-01), **2026-12-18/40d (11-08)**. Dead zone 2026-12-19 → 2027-01-10 (no FMP row). Separate fact from the orchestrator's fmp_summary: FMP chunk 2 returns a block of 56 rows dated 2027-01-11 → 02-18 (peak ISO weeks 2027-W04 18 rows, W05 16 rows) = the January/February mega-cap season projected as a sparse top-name sample; that block is NOT part of the series above (the series definition is the end of the contiguous near-term chunk-1 coverage, unchanged since W40). Standing plan-tier constraint (`FMP-earn-horizon`, `OWNER_ACTIONS.md`), deliberately NOT re-alerted; all FMP pulls chunked ≤ 60 days (4 chunks this run, 76 deduped rows, no errors).

**Nasdaq key-less per-day calendar** (every weekday 2026-11-02 → 2026-12-23, shared CSV, not re-fetched; 11-26 and 12-23 returned zero rows at ≥ $2B; 12-22 has 8 rows of all caps but none ≥ $2B; last ≥ $2B date 2026-12-21): 3,430 rows at all market caps; **1,136 rows at market cap ≥ $2B** (CSV parsed: 1,136 data rows). Of those: 737 fall 11-02 → 11-06 (week just printed) and **399 are forward 2026-11-09 → 2026-12-21** (294 in 11-09 → 11-30, 105 in December). **54 forward rows are ≥ $50B.** **164 of 399 forward rows carry `time-not-supplied`** (projected (E) signature); 119 BMO, 116 AMC. (For the printed week, 734 of 737 rows show n/s because Nasdaq drops the time field after the print.) Forward per-day counts at ≥ $2B: 11-09 67, 11-10 34, 11-11 24, 11-12 39, 11-13 10, 11-16 13, 11-17 19, 11-18 20, 11-19 21, 11-20 7, 11-23 12, 11-24 23, 11-25 4, 11-27 1, 12-01 11, 12-02 17, 12-03 21, 12-04 1, 12-07 2, 12-08 11, 12-09 8, 12-10 7, 12-14 1, 12-15 3, 12-16 6, 12-17 12, 12-18 4, 12-21 1.

**FMP coverage shape** (MEASURED, four chunked `calendar/earnings-calendar` calls by the orchestrator; 76 deduped symbol-date rows; counts parsed from the shared file):

| Span | Rows | Notes |
|---|---|---|
| 11-08 → 11-30 | 12 | LCID 11-09 … NIO/BILI 11-24 (CSCO 11-12, BIDU 11-16, DIS/NVDA/FUBO 11-17, TGT 11-18, BABA/WMT 11-19, ZM 11-23) |
| 12-01 → 12-18 | 5 | DOCU 12-03; ADBE 12-09; COST 12-10; NKE 12-17; CCL 12-18 (terminal row) |
| 12-19 → 2027-01-10 | 0 | dead zone (plan-tier constraint, not alerted) |
| 2027-01-11 → 02-21 | 56 | TLRY 01-11 … ETSY 02-18; ISO weeks 2027-W02 6, W03 6, W04 18, W05 16, W06 9, W07 1 (names that printed 11-02..11-06 appear re-projected, e.g. AAPL 02-04, AMD 02-02, PLTR 02-01) |
| 2027-02-22 → 05-08 | 3 | RKT 02-25, RIOT 03-01, FDX 03-25 (chunk 3) ; chunk 4 (05-07 → 05-08) 0 rows |

FMP also lists FDX twice (2027-02-02 in chunk 2 and 2027-03-25 in chunk 3): internal inconsistency in the vendor feed; neither is relied on.

**Cross-check FMP vs Nasdaq (inside 11-09 → 12-23):** FMP has 17 in-window rows; 15 of them are also on the Nasdaq ≥ $2B forward list (CSCO, BIDU, DIS, NVDA, TGT, BABA, WMT, ZM, BILI, NIO, DOCU, ADBE, COST, NKE, CCL). **14 agree on the date; 1 DISAGREES: BABA (FMP 2026-11-19 vs Nasdaq 2026-11-24)** — new vs W44 (which had 0 disagreements), unresolved. FMP-only names (absent from the Nasdaq ≥ $2B file): **LCID** (11-09; Nasdaq all-caps file shows market cap $1.17B) and **FUBO** (11-17; $0.84B) — both below the $2B floor (ET, the third W44 FMP-only name, printed 11-03 and left the window). FMP rows beyond 12-23 (58 rows, 2027-01-11 → 03-25) are outside the Nasdaq pull by construction. Nasdaq ≥ $2B forward names not in FMP: 384 of 399 (FMP is a sparse mega-cap subset, not an enumeration).

**A-queue (46) census vs Nasdaq** (pinned census, orchestrator-MEASURED this run, same 46 as W44): **22 have a forward Nasdaq date inside 11-09 → 12-23** (ADBE, AMAT, AVGO, CRM, CRWD, CSCO, DELL, HD, HPE, INTU, MRVL, MU, NBIS, NTAP, NVDA, OKTA, ORCL, PANW, SNOW, TGT, TTWO, WMT); **9 printed 11-02 → 11-06** (AAPL 11-02, VRTX 11-02, AMD 11-03, ANET 11-03, SMCI 11-03, DDOG 11-04, QCOM 11-04, AKAM 11-05, COP 11-05); **15 have none** (the 12 that printed 10-26 → 10-30: AMZN, INTC, MSFT, CVX, LLY, NOW, XOM, GEV, MRK, FSLR, GOOGL, CAT; plus IBM, META, JPM). Of the 22 forward names, 14 are issuer-confirmed this run ((C) or (C-secondary): TTWO, AMAT, CSCO, NBIS, NVDA, HD, PANW, TGT, WMT, INTU, CRWD, MRVL, OKTA, SNOW), 1 has an issuer target date (NTAP) and 7 remain (E) (DELL, HPE, CRM, ORCL, ADBE, AVGO, MU).

**Every count in PART 1 beyond the C window (after 2026-12-23) is a FLOOR.** Universe enumeration past the Nasdaq pull is impossible on this plan tier: `search/search-company-screener`, every `directory.*` route and `quote/batch-quote` are tool-level ACCESS DENIED (`ops.alerts` `6c4004e3`, standing, not re-alerted). The market-cap rail inside the C window is Nasdaq's own `marketCap` field; the 30-day ADV ≥ $10M rail is carried, not re-measured (1A.11).

## PART 1A — Strategy A universe, 6-month window (2026-11-08 → 2027-05-08)

No interpretation in this PART. Provenance tags:
- **(C)** company- or primary-source confirmed (**(C-secondary)** = issuer notice seen only through a copy or search snippet)
- **(E)** estimated (vendor or aggregator projection)
- **(T)** tentative, no firm day

"Δ" marks a change against the 2026-11-01 (2026-W44) artifact. Rows tagged (C) 'carried from W44' were issuer-confirmed last cycle and the Nasdaq date still matches; they were NOT re-read this run. Metered calls this sub-agent: 28 WebSearch, 4 WebFetch, 2 Tavily basic (see call log).

### 1A.1 — Earnings, inside the 45-day C window (2026-11-09 → 2026-12-23)

**Enumeration.** Nasdaq key-less per-day calendar, market cap ≥ $2B: 399 forward rows (2026-11-09 → 12-21); 54 are ≥ $50B. The detail table lists every forward row that is on the A queue, ≥ $50B, or tagged (C)/(E)-with-source this run (58 rows); the remainder is enumerated by session below. Time codes: BMO before open, AMC after close, n/s not supplied. Mcap = Nasdaq `marketCap` field as fetched. D marks held Strategy D positions. All Nasdaq-only rows are (E).

| Ticker | Name | Type | Date | Tag | Mcap | Source / consensus |
|---|---|---|---|---|---|---|
| KKR | KKR & Co. Inc. | Earnings (BMO, FQ Sep/2026) | 2026-11-09 | (E) | $88B | Nasdaq calendar |
| CEG | Constellation Energy Corporation | Earnings (BMO, FQ Sep/2026) | 2026-11-09 | (E) | $85B | Nasdaq calendar |
| B | Barrick Mining Corporation | Earnings (BMO, FQ Sep/2026) | 2026-11-09 | (E) | $66B | Nasdaq calendar |
| OXY | Occidental Petroleum Corporation | Earnings (AMC, FQ Sep/2026) | 2026-11-09 | (E) | $56B | Nasdaq calendar |
| TTWO | Take-Two Interactive Software, Inc. [A-queue] | Earnings (AMC, FQ Sep/2026) | 2026-11-09 | **(C)** | $40B | Take-Two IR release "to Report Second Quarter Fiscal Year 2027 Results on Monday, November 9, 2026" (4:30 pm ET), carried from W44, not re-read |
| PBR | Petroleo Brasileiro S.A.- Petrobras | Earnings (AMC, FQ Sep/2026) | 2026-11-10 | (E) | $121B | Nasdaq calendar |
| PBR.A | Petroleo Brasileiro S.A.- Petrobras | Earnings (AMC, FQ Sep/2026) | 2026-11-10 | (E) | $121B | Nasdaq calendar |
| TDG | Transdigm Group Incorporated | Earnings (BMO, FQ Sep/2026) | 2026-11-10 | (E) | $66B | Nasdaq calendar; **Δ 11-11→11-10 vs W44** |
| CSCO | Cisco Systems, Inc. [A-queue] | Earnings (AMC, FQ Oct/2026) | 2026-11-12 | **(C)** | $377B | NEW (C): Cisco release 2026-11-03 "Schedules Conference Call for Q1 FY2027 Financial Results": call Thu 11-12 1:30 pm PT, results after market close (newsroom.cisco.com / investor.cisco.com via WebSearch 2026-11-08); FMP agrees (EPS est 1.32, rev est $18.11B); **Δ 11-11→11-12 vs W44** |
| AMAT | Applied Materials, Inc. [A-queue] | Earnings (AMC, FQ Oct/2026) | 2026-11-12 | **(C)** | $253B | Applied Materials release 2026-10-22, carried from W44, not re-read |
| BN | Brookfield Corporation | Earnings (BMO, FQ Sep/2026) | 2026-11-12 | (E) | $102B | Nasdaq calendar |
| NU | Nu Holdings Ltd. | Earnings (n/s, FQ Sep/2026) | 2026-11-12 | (E) | $57B | Nasdaq calendar |
| NBIS | Nebius Group N.V. [A-queue] | Earnings (BMO, FQ Sep/2026) | 2026-11-12 | **(C)** | $33B | NEW (C): Nebius notice dated 2026-10-30 (nebius.com/newsroom, WebFetch 2026-11-08): results Thu 11-12 before market open, call 8:00 am ET. Δ vs W44 Nasdaq 11-10 (E); Nasdaq now 11-12 n/s |
| MUFG | Mitsubishi UFJ Financial Group Inc | Earnings (n/s, FQ Sep/2026) | 2026-11-13 | (E) | $251B | Nasdaq calendar |
| SMFG | Sumitomo Mitsui Financial Group Inc | Earnings (n/s, FQ Sep/2026) | 2026-11-13 | (E) | $150B | Nasdaq calendar |
| MFG | Mizuho Financial Group, Inc. | Earnings (n/s, FQ Sep/2026) | 2026-11-13 | (E) | $117B | Nasdaq calendar |
| NVDA | NVIDIA Corporation [A-queue] | Earnings (AMC, FQ Oct/2026) | 2026-11-17 | **(C)** | $4,377B | nvidianews.nvidia.com call notice (call Tue 11-17 2:00 pm PT), carried from W44, not re-read; FMP agrees (EPS est 2.47, rev est $108.80B) |
| HD | Home Depot, Inc. (The) [A-queue] | Earnings (BMO, FQ Oct/2026) | 2026-11-17 | **(C)** | $349B | NEW (C): Home Depot IR events page (ir.homedepot.com/events-and-presentations, WebFetch 2026-11-08): Q3 release Tue 11-17 9:00 am ET [page text as returned by the fetch tool]; search results disagree on time (pre-market vs 4:05 pm) |
| BHP | BHP Group Limited | Earnings (n/s, FQ Sep/2026) | 2026-11-17 | (E) | $203B | Nasdaq calendar |
| DIS | Walt Disney Company (The) [D held] | Earnings (BMO, FQ Sep/2026) | 2026-11-17 | **(C)** | $202B | Disney webcast notice 2026-10-12 (Tue 11-17, webcast 8:30 am ET), carried from W44, not re-read; FMP agrees (EPS est 1.69, rev est $25.19B) |
| PDD | PDD Holdings Inc. | Earnings (n/s, FQ Sep/2026) | 2026-11-17 | (E) | $119B | Nasdaq calendar |
| PANW | Palo Alto Networks, Inc. [A-queue] | Earnings (AMC, FQ Oct/2026) | 2026-11-18 | **(C-secondary)** | $258B | NEW: title "Palo Alto Networks to Announce Fiscal First Quarter 2027 Financial Results on Wednesday, November 18, 2026" (PR Newswire copy on stockhub.kr; paloaltonetworks.com not opened); webcast time not returned |
| TJX | TJX Companies, Inc. (The) | Earnings (BMO, FQ Oct/2026) | 2026-11-18 | (E) | $152B | Nasdaq calendar |
| LOW | Lowe's Companies, Inc. | Earnings (BMO, FQ Oct/2026) | 2026-11-18 | (E) | $127B | Nasdaq calendar |
| TGT | Target Corporation [A-queue] | Earnings (BMO, FQ Oct/2026) | 2026-11-18 | **(C)** | $72B | corporate.target.com, carried from W44, not re-read; FMP agrees (EPS est 2.06, rev est $26.43B) |
| WMT | Walmart Inc. [A-queue] | Earnings (BMO, FQ Oct/2026) | 2026-11-19 | **(C)** | $1,013B | corporate.walmart.com, carried from W44, not re-read; FMP agrees (EPS est 0.638, rev est $187.24B) |
| INTU | Intuit Inc. [A-queue] | Earnings (AMC, FQ Oct/2026) | 2026-11-19 | **(C-secondary)** | $95B | NEW: investors.intuit.com IR calendar snippet (WebSearch 2026-11-08) lists Q1 FY27 call 11-19 4:30 pm ET; single source, press release not seen |
| NTES | NetEase, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-11-19 | (E) | $81B | Nasdaq calendar |
| ROST | Ross Stores, Inc. | Earnings (n/s, FQ Oct/2026) | 2026-11-19 | (E) | $75B | Nasdaq calendar |
| VEEV | Veeva Systems Inc. | Earnings (n/s, FQ Oct/2026) | 2026-11-19 | (E) | $50B | Nasdaq calendar |
| HPE | Hewlett Packard Enterprise Company [A-queue] | Earnings (AMC, FQ Oct/2026) | 2026-11-23 | (E) | $59B | Nasdaq calendar; **Δ vs W44 12-03 → 11-23**; WebSearch 2026-11-08 found no HPE date notice (prior-year Q4 print was early December) |
| BABA | Alibaba Group Holding Limited | Earnings (n/s, FQ Sep/2026) | 2026-11-24 | (E) | $262B | Nasdaq calendar 11-24; **FMP shows 11-19 (EPS est 1.61, rev est $40.25B) - date disagreement, unresolved** |
| DELL | Dell Technologies Inc. [A-queue] | Earnings (n/s, FQ Oct/2026) | 2026-11-24 | (E) | $201B | Nasdaq calendar; Dell IR page lists "Fiscal Year 2027 Third Quarter Results" upcoming event with no date (Tavily 2026-11-08); prior-year call was 11-25; no issuer date notice found |
| ADI | Analog Devices, Inc. | Earnings (BMO, FQ Oct/2026) | 2026-11-24 | (E) | $175B | Nasdaq calendar |
| MDT | Medtronic plc | Earnings (BMO, FQ Oct/2026) | 2026-11-24 | (E) | $134B | Nasdaq calendar; **Δ 11-17→11-24 vs W44** |
| ADSK | Autodesk, Inc. | Earnings (AMC, FQ Oct/2026) | 2026-11-24 | (E) | $56B | Nasdaq calendar |
| DE | Deere & Company | Earnings (BMO, FQ Oct/2026) | 2026-11-25 | (E) | $179B | Nasdaq calendar |
| CRWD | CrowdStrike Holdings, Inc. [A-queue] | Earnings (AMC, FQ Oct/2026) | 2026-12-01 | **(C)** | $222B | NEW (C): CrowdStrike IR notice (ir.crowdstrike.com): results after close Tue 12-01, call 2:00 pm PT (WebSearch 2026-11-08) |
| MRVL | Marvell Technology, Inc. [A-queue] | Earnings (n/s, FQ Oct/2026) | 2026-12-01 | **(C)** | $117B | NEW (C): Marvell IR release 2026-11-06 "Announces Conference Call to Review Q3 FY2027 Financial Results": Tue 12-01, 1:30 pm PT (investor.marvell.com via WebSearch). Separate: Lumentum merger announced 11-02 (see 1A.7) |
| NTAP | NetApp, Inc. [A-queue] | Earnings (AMC, FQ Oct/2026) | 2026-12-01 | (E) | $33B | Nasdaq calendar (AMC); NetApp Q1 FY27 release lists "Q2 FY2027 results target date: December 1, 2026" (issuer target, via WebSearch snippet); Q2 webcast notice not yet issued |
| OKTA | Okta, Inc. [A-queue] | Earnings (AMC, FQ Oct/2026) | 2026-12-01 | **(C)** | $30B | NEW (C): Okta release "to Announce Third Quarter Fiscal Year 2027 Financial Results on December 1, 2026": after close, webcast 2:00 pm PT (finviz copy via WebSearch 2026-11-08) |
| CRM | Salesforce, Inc. [A-queue] | Earnings (n/s, FQ Oct/2026) | 2026-12-02 | (E) | $183B | Nasdaq calendar; WebSearch + Tavily 2026-11-08 found no Salesforce timing notice (prior-year notice came 11-05 for 12-03); calendar sites say 12-01 or 12-02 |
| BMO | Bank Of Montreal | Earnings (BMO, FQ Oct/2026) | 2026-12-02 | (E) | $120B | Nasdaq calendar; **Δ 12-03→12-02 vs W44** |
| BNS | Bank of Nova Scotia (The) | Earnings (BMO, FQ Oct/2026) | 2026-12-02 | (E) | $113B | Nasdaq calendar; **Δ 12-01→12-02 vs W44** |
| SNOW | Snowflake Inc. [A-queue] | Earnings (AMC, FQ Oct/2026) | 2026-12-02 | **(C)** | $95B | NEW (C): Snowflake release dated 2026-11-02 "to Announce Financial Results for the Third Quarter of Fiscal 2027 on December 2, 2026": after close, call 2:00 pm PT (snowflake.com via WebSearch) |
| RY | Royal Bank Of Canada | Earnings (BMO, FQ Oct/2026) | 2026-12-03 | (E) | $282B | Nasdaq calendar; **Δ 12-02→12-03 vs W44** |
| TD | Toronto Dominion Bank (The) | Earnings (n/s, FQ Oct/2026) | 2026-12-03 | (E) | $201B | Nasdaq calendar |
| CM | Canadian Imperial Bank of Commerce | Earnings (BMO, FQ Oct/2026) | 2026-12-03 | (E) | $105B | Nasdaq calendar |
| AZO | AutoZone, Inc. | Earnings (n/s, FQ Nov/2026) | 2026-12-08 | (E) | $53B | Nasdaq calendar |
| ORCL | Oracle Corporation [A-queue] | Earnings (n/s, FQ Nov/2026) | 2026-12-09 | (E) | $348B | Nasdaq calendar 12-09; calendar sites project 12-09 or 12-10; no Oracle date notice found (last year's came ~8 days ahead) |
| ADBE | Adobe Inc. [A-queue] | Earnings (n/s, FQ Nov/2026) | 2026-12-09 | (E) | $96B | Nasdaq calendar; FMP agrees (EPS est 6.32, rev est $6.83B); WebSearch 2026-11-08: no Adobe notice, calendar sites project 12-09 |
| SNPS | Synopsys, Inc. | Earnings (n/s, FQ Oct/2026) | 2026-12-09 | (E) | $84B | Nasdaq calendar |
| AVGO | Broadcom Inc. [A-queue] | Earnings (n/s, FQ Oct/2026) | 2026-12-10 | (E) | $1,392B | Nasdaq calendar 12-10; WebSearch 2026-11-08: no Broadcom notice; one calendar site expects 12-10 |
| COST | Costco Wholesale Corporation | Earnings (n/s, FQ Nov/2026) | 2026-12-10 | (E) | $472B | Nasdaq calendar; FMP agrees (EPS est 4.93, rev est $74.28B) |
| MU | Micron Technology, Inc. [A-queue] | Earnings (n/s, FQ Nov/2026) | 2026-12-16 | (E) | $743B | Nasdaq calendar 12-16; WebSearch 2026-11-08: no Micron notice; one countdown site 12-16 4:30 pm ET (unconfirmed) |
| ACN | Accenture plc | Earnings (n/s, FQ Nov/2026) | 2026-12-17 | (E) | $177B | Nasdaq calendar |
| CTAS | Cintas Corporation | Earnings (n/s, FQ Nov/2026) | 2026-12-17 | (E) | $90B | Nasdaq calendar |
| NKE | Nike, Inc. | Earnings (n/s, FQ Nov/2026) | 2026-12-17 | (E) | $59B | Nasdaq calendar; FMP agrees (EPS est 0.34, rev est $11.13B) |

Aggregator-only A-queue rows outside Nasdaq: none (every forward A-queue name is on the Nasdaq calendar).

**Full enumeration of the remainder, by session** — Nasdaq ≥ $2B reporters NOT in the detail table, ordered by market cap within the day; ᵇ = before open, ᵃ = after close, no mark = time not supplied. All (E).

- **2026-11-09** (62): FERGᵇ SKYDᵃ IXᵇ RKLBᵃ BAPᵃ ROIVᵇ CIBᵃ KSPIᵇ RBAᵇ NRGᵇ SGIᵇ CNHᵇ JBSᵃ EQXᵃ ASTSᵃ AMGᵇ LINEᵃ TGTXᵇ TIMBᵃ ONTOᵃ ZETAᵃ PRAXᵇ SANMᵃ QLYSᵃ HRBᵃ IONSᵇ CWSTᵃ RDNTᵇ TTDᵃ IMVTᵇ CWENᵃ HIMSᵃ NXEᵃ IFSᵃ NOVTᵃ AAONᵃ TEO DFTXᵃ TKCᵇ MNDYᵇ KGSᵇ XENEᵃ ABCLᵃ NHIᵃ EQPTᵃ TDWᵃ DHTᵃ VIAᵇ SGRY ACHRᵃ USARᵃ ASST GCMGᵇ FRVOᵇ ALM CSQRᵃ MARAᵃ WTTRᵇ SEPN KMPRᵃ ZYMEᵃ GSHDᵃ
- **2026-11-10** (31): SEᵇ ALCᵃ VODᵇ ECᵃ VGᵇ CRWVᵃ ONONᵇ VIVᵃ EMBJ IBRX SLAB SRRKᵇ MANE ATATᵇ ALHᵇ BWIN LEGNᵇ MRCYᵃ LQDAᵇ PHI TNGX QBTSᵇ RGTIᵃ WIXᵇ REZIᵃ FLYᵃ STUBᵃ ATROᵃ EXKᵇ COAGᵇ HSAIᵇ
- **2026-11-11** (24): FNVᵃ VYLRᵃ GIBᵇ ASND TTEKᵃ CAEᵃ CTVAᵃ ORᵃ ORKA UGP ICLᵇ ENSᵃ ERAS AYAᵇ ECOᵃ TR TNKᵃ IHS SA BGSIᵇ PLGOᵃ DGIIᵃ RUMᵇ PHVS
- **2026-11-12** (34): BSP CBRSᵃ BNT HBMᵇ STNᵃ ARWRᵃ TWSTᵇ ELPCᵃ ANDGᵃ NIQᵇ MBGLᵇ BLTEᵃ KOD OCTVᵇ FPSᵇ AVAL MWHᵇ FIGRᵇ HTFLᵃ ARXᵇ DPCᵇ DLOᵃ SKE XEᵇ YETIᵇ PBLS ENHA CLBTᵇ AVAHᵇ LFTOᵃ LGNᵇ ONDSᵇ GLOB SPBᵇ
- **2026-11-13** (7): KB WF CGON CIG XXI LPL PPTA
- **2026-11-16** (13): TCOM BIDUᵇ BEKEᵇ TSNᵇ HTHTᵇ ARMKᵇ XPEVᵇ ACMᵃ XP POWLᵃ BRC DAC PAGSᵃ
- **2026-11-17** (14): JDᵇ VIKᵇ ESLTᵇ ASᵇ SQM ZTOᵃ TMEᵇ KLARᵇ BZ DLBᵃ SRᵇ MNSOᵇ GBDCᵃ SBLK
- **2026-11-18** (16): Pᵃ WSM WWDᵃ UGIᵃ GLBEᵇ CPAᵃ DY NJRᵃ GFF GDS GLNGᵇ JOYY HPᵃ BLSHᵇ ZIMᵇ KLIC
- **2026-11-19** (16): KEYSᵃ CPRT WMGᵇ FUTUᵇ YMMᵇ ESTC GAPᵃ ESEᵃ VIPS VVVᵇ BBWIᵇ ROAD POSTᵃ MMSᵇ BULLᵃ DAOᵇ
- **2026-11-20** (7): BJᵇ FRO MOG.A MOG.B VFS IESC BKE
- **2026-11-23** (11): Aᵃ ZMᵃ SYMᵃ Jᵃ SMTC SNEX AMTMᵃ CAAP BWLPᵇ CENT CENTA
- **2026-11-24** (18): WDAYᵃ HPQᵃ DLTRᵇ BBYᵇ NTNX BURL SJMᵇ DKSᵇ NIO URBN ANFᵇ BILIᵇ MMEDᵇ GGAL KSSᵇ KCᵇ AMBA BBAR
- **2026-11-25** (3): LI CMBT BMA
- **2026-11-27** (1): CHA
- **2026-12-01** (7): MDBᵃ HQYᵃ GTLB BOXᵃ AEO UNFI ASANᵃ
- **2026-12-02** (13): ZSᵃ GWRE FIVE DCIᵇ NTSKᵃ DSGXᵃ PATH M SIGᵇ THO PVH KEN NCNO
- **2026-12-03** (18): KR DGᵇ ULTAᵃ IOTᵃ RBRK DOCU BF.Aᵇ BF.Bᵇ HRLᵇ COO TTANᵃ S SAIC DOO AGX WLY WLYB IDT
- **2026-12-04** (1): VSXY
- **2026-12-07** (2): CRDO HAFN
- **2026-12-08** (10): CASY GME SAIL CNM CPB OLLI BRZEᵃ AVAV KFY ASO
- **2026-12-09** (5): NDSN CHWY MTN PL UEC
- **2026-12-10** (5): CIEN LULU MANU FIZZ RH
- **2026-12-14** (1): TOL
- **2026-12-15** (3): LEN LEN.B WOR
- **2026-12-16** (5): JBL GIS TTC ABM EPAC
- **2026-12-17** (9): HEI HEI.A DRI KEP FDS KMX BIRK BB KBH
- **2026-12-18** (4): PAYX CCL LW CAG
- **2026-12-21** (1): ABVX

Check: detail 58 + remainder 341 = 399 forward rows (Nasdaq forward 399).

### 1A.2 — Earnings, after the C window up to the dense horizon (2026-12-24 → 2026-12-18): empty

Empty by construction: the C window (to 12-23) now extends past the FMP dense horizon (12-18), so the 12-17/12-18 rows (NKE 12-17, CCL 12-18, both FMP and Nasdaq agree) sit in 1A.1 above. Nasdaq ≥ $2B returned 12-17: 12 rows, 12-18: 4 rows, 12-21: 1 row, 12-22/12-23: none. No FMP row 12-19 → 2027-01-10. Effective confirmed-earnings horizon 2026-12-18 = 40 days from 2026-11-08 (unchanged, sixth week).

### 1A.3 — Earnings, 2026-12-24 → 2027-05-08

Coverage gap, not absence of events: FMP (4 chunked calls, 2026-11-08) returns nothing 12-19 → 2027-01-10, 56 rows 2027-01-11 → 02-18 and only RKT 02-25 / RIOT 03-01 / FDX 03-25 after that. Window end rolled 05-01 → 05-08; no sourced row falls 05-01..05-08 except as noted. Rows below are FMP, all (E) unless marked.

| Date | Tickers (FMP) |
|---|---|
| 2027-01-11 | TLRY |
| 2027-01-13 | DAL |
| 2027-01-14 | C · JPM · WFC |
| 2027-01-15 | BAC |
| 2027-01-19 | GS · NFLX · UAL |
| 2027-01-20 | UNH |
| 2027-01-21 | GE · TSM |
| 2027-01-26 | AAL · BA · HCA · JNJ · LMT |
| 2027-01-27 | GM · META · MSFT · SBUX · T · TSLA |
| 2027-01-28 | INTC · NOK · V |
| 2027-01-29 | CVX · SOFI · VZ · XOM |
| 2027-02-01 | PLTR |
| 2027-02-02 | AMD · FDX · PEP · PFE · PYPL |
| 2027-02-03 | ABBV · GOOGL · SNAP · UBER |
| 2027-02-04 | AAPL · AMZN · CARR · MGM · RBLX · SIRI |
| 2027-02-09 | F · HOOD · KO |
| 2027-02-10 | SHOP |
| 2027-02-11 | COIN · PINS · RIVN · ROKU |
| 2027-02-12 | MRNA |
| 2027-02-18 | ETSY |
| 2027-02-25 | RKT |
| 2027-03-01 | RIOT |
| 2027-03-25 | FDX |

Δ vs W44's FMP table (compared table-to-CSV; not re-searched): DAL 01-12 → **01-13**; JNJ 01-20 → **01-26**; LMT 02-04 → **01-26**; GM 01-26 → **01-27**; NOK 02-04 → **01-28**. Newly present (names that printed 11-02..11-06 or added by the vendor): PLTR 02-01, AMD 02-02, PFE 02-02, SNAP 02-03, UBER 02-03, AAPL 02-04, KO 02-09, SHOP 02-10, ROKU 02-11, MRNA 02-12, RIOT 03-01. Unchanged: TLRY, C/JPM/WFC, BAC, GS/NFLX/UAL, UNH, GE/TSM, AAL/BA/HCA, META/MSFT/SBUX/T/TSLA, INTC/V, CVX/SOFI/VZ/XOM, FDX/PEP/PYPL, ABBV/GOOGL, AMZN/CARR/MGM/RBLX/SIRI, F/HOOD, COIN/PINS/RIVN, ETSY, RKT.

**Per-name (E) tails carried from W44 (not in FMP; not re-sourced this run):**

| Ticker | Event | Date | Tag | Source |
|---|---|---|---|---|
| MRK | Q4 2026 call | 2027-02-02 | (C) | merck.com (carried from W43/W44, not re-read). FMP shows no MRK row |
| MRK | Q1 2027 call | 2027-04-29 | (C) | merck.com (carried; inside the window), not re-read |
| NVDA | FQ4 FY27 | ~2027-02-24 | (E) | days.to / WSH inferred (carried) |
| AVGO | FQ1 FY27 | ~2027-03-03 | (E) | days.to projection (carried) |
| ORCL | FQ3 FY27 | ~2027-03-10 | (E) | days.to projection (carried) |
| MU | FQ2 FY27 | ~2027-03-17 | (E) | days.to + WSH 'INFERRED' (carried) |
| FDX | FedEx | 2027-03-25 (FMP chunk 3) vs 2027-02-02 (FMP chunk 2) | (T) | FMP internal conflict; neither relied on |

Not established (no reachable source states a date after the next print or the last print): A-queue names with no FMP row and no per-name tail: AKAM, ANET, CAT, COP, DDOG, FSLR, GEV, IBM, LLY, NOW, QCOM, SMCI, VRTX, and every forward A-queue name other than NVDA/AVGO/ORCL/MU above. FMP-projected next prints exist for AAPL 2027-02-04, AMD 02-02, AMZN 02-04, GOOGL 02-03, MSFT 01-27, META 01-27, INTC 01-28, CVX 01-29, XOM 01-29, JPM 01-14. No search for post-print dates was run this cycle.

### Printed this week (2026-11-02 → 2026-11-06)

A-queue and ≥ $50B names whose Nasdaq date fell 11-02 → 11-06 (76 of 737 printed-week rows at ≥ $2B). These drop out of the forward calendar. A Nasdaq date is a schedule, not evidence of a print; the 'D1 record' column is evidence of a print where D1's decision-log records (events.decision_log, sessions through 2026-11-05) carry the name with an IBKR close-to-close move; a blank means D1 surfaced no ≥ 5% move for the name (not that no print occurred). The Friday 2026-11-06 session is outside D1 coverage (structural weekly gap); FMP actuals are not in the shared pull for this week. Outcomes were not researched.

| Ticker | Name | Nasdaq date | A-queue | Mcap | EPS fcst (Nasdaq, n est) | D1 record (event; move; entry) |
|---|---|---|---|---|---|---|
| AAPL | Apple Inc. | 2026-11-02 | A | $5,002B | $1.98 (7) |  |
| PLTR | Palantir Technologies Inc. | 2026-11-02 |  | $373B | $0.32 (11) |  |
| WMB | Williams Companies, Inc. (The) | 2026-11-02 |  | $163B | $0.55 (8) |  |
| VRTX | Vertex Pharmaceuticals Incorporated | 2026-11-02 | A | $138B | $4.36 (5) |  |
| MAR | Marriott International | 2026-11-02 |  | $107B | $2.86 (8) |  |
| O | Realty Income Corporation | 2026-11-02 |  | $57B | $1.11 (7) |  |
| IDXX | IDEXX Laboratories, Inc. | 2026-11-02 |  | $53B | $3.71 (6) | earnings; +21.8%; da7bf33a |
| ETR | Entergy Corporation | 2026-11-02 |  | $53B | $1.71 (6) |  |
| FANG | Diamondback Energy, Inc. | 2026-11-02 |  | $50B | $4.92 (8) |  |
| AMD | Advanced Micro Devices, Inc. | 2026-11-03 | A | $663B | $1.68 (13) |  |
| AMGN | Amgen Inc. | 2026-11-03 |  | $249B | $5.74 (9) |  |
| ANET | Arista Networks, Inc. | 2026-11-03 | A | $201B | $0.99 (9) | earnings release (8-K Item 2.02, quarter ending Sep/2026); +5.0%; 7701d3bc |
| SHOP | Shopify Inc. | 2026-11-03 |  | $185B | $0.33 (13) | Q3 earnings; -8.7%; c51c9632 |
| PFE | Pfizer, Inc. | 2026-11-03 |  | $170B | $0.72 (5) |  |
| ETN | Eaton Corporation, PLC | 2026-11-03 |  | $127B | $3.54 (10) | Q3 earnings; +7.0%; c51c9632 |
| BKNG | Booking Holdings Inc. | 2026-11-03 |  | $125B | $4.48 (11) | earnings release (8-K Item 2.02, quarter ending Sep/2026); +9.8%; 7701d3bc |
| MPC | Marathon Petroleum Corporation | 2026-11-03 |  | $103B | $25.74 (5) |  |
| RACE | Ferrari N.V. | 2026-11-03 |  | $99B | $2.66 (1) |  |
| SU | Suncor Energy  Inc. | 2026-11-03 |  | $81B | $2.35 (2) |  |
| ITUB | Itau Unibanco Banco Holding SA | 2026-11-03 |  | $80B | $0.22 (3) |  |
| APO | Apollo Global Management, Inc. | 2026-11-03 |  | $69B | $2.04 (8) |  |
| MPLX | MPLX LP | 2026-11-03 |  | $57B | $1.11 (6) |  |
| AME | AMTEK, Inc. | 2026-11-03 |  | $51B | $2.12 (7) |  |
| TRI | Thomson Reuters Corp | 2026-11-03 |  | $51B | $0.89 (2) | Q3 earnings (6-K); -9.9%; c51c9632 |
| XYZ | Block, Inc. | 2026-11-03 |  | $51B | $0.68 (9) | earnings release (8-K Item 2.02, quarter ending Sep/2026); +15.3%; 7701d3bc |
| KDP | Keurig Dr Pepper Inc. | 2026-11-03 |  | $50B | $0.63 (5) | Q3 earnings; -5.6%; c51c9632 |
| SMCI | Super Micro Computer, Inc. | 2026-11-03 | A | $18B | $1.04 (6) | earnings release (8-K Item 2.02, quarter ending Sep/2026; also Item 8.; -5.7%; 7701d3bc |
| MCD | McDonald's Corporation | 2026-11-04 |  | $197B | $3.36 (11) | earnings release (8-K Item 2.02, quarter ending Sep/2026); +6.5%; 7701d3bc |
| NVO | Novo Nordisk A/S | 2026-11-04 |  | $178B | $0.81 (4) |  |
| ARM | Arm Holdings plc | 2026-11-04 |  | $177B | $0.22 (7) | Q2 FY2027 results (6-K shareholder letter); -13.1%; f5359185 |
| QCOM | QUALCOMM Incorporated | 2026-11-04 | A | $168B | $1.46 (9) | Earnings release (8-K Item 2.02); -9.5%; f5359185 |
| UBER | Uber Technologies, Inc. | 2026-11-04 | D-held | $140B | $0.94 (7) |  |
| MCK | McKesson Corporation | 2026-11-04 |  | $124B | $10.69 (6) |  |
| APP | Applovin Corporation | 2026-11-04 |  | $118B | $3.94 (9) | Earnings release (8-K Item 2.02); +31.0%; f5359185 |
| CVS | CVS Health Corporation | 2026-11-04 |  | $104B | $1.62 (9) | earnings release (8-K Item 2.02, quarter ending Sep/2026); -12.5%; 7701d3bc |
| EMR | Emerson Electric Company | 2026-11-04 |  | $91B | $1.85 (7) |  |
| MSI | Motorola Solutions, Inc. | 2026-11-04 |  | $85B | $3.99 (5) |  |
| MELI | MercadoLibre, Inc. | 2026-11-04 |  | $78B | $9.41 (3) | Earnings release (8-K Item 2.02); -12.0%; f5359185 |
| MFC | Manulife Financial Corp | 2026-11-04 |  | $73B | $0.83 (2) |  |
| GWW | W.W. Grainger, Inc. | 2026-11-04 |  | $68B | $11.64 (7) | earnings release (8-K Item 2.02, quarter ending Sep/2026); +6.5%; 7701d3bc |
| ALL | Allstate Corporation (The) | 2026-11-04 |  | $66B | $7.03 (10) |  |
| COR | Cencora, Inc. | 2026-11-04 |  | $65B | $4.56 (4) |  |
| MET | MetLife, Inc. | 2026-11-04 |  | $63B | $2.71 (8) |  |
| AFL | Aflac Incorporated | 2026-11-04 |  | $63B | $1.80 (6) |  |
| DDOG | Datadog, Inc. | 2026-11-04 | A | $63B | $0.18 (10) | earnings release (8-K Item 2.02, quarter ending Sep/2026); -14.4%; 7701d3bc |
| EW | Edwards Lifesciences Corporation | 2026-11-04 |  | $58B | $0.73 (9) |  |
| MDLN | Medline Inc. | 2026-11-04 |  | $52B | $0.32 (6) | earnings release (8-K Item 2.02); +18.4%; 7701d3bc |
| CVE | Cenovus Energy Inc | 2026-11-04 |  | $50B | $1.21 (2) | Q3 results (6-K); -7.6%; 7701d3bc |
| TM | Toyota Motor Corp Ltd Ord | 2026-11-05 |  | $284B | — (N/A) |  |
| COP | ConocoPhillips | 2026-11-05 | A | $163B | $3.06 (8) |  |
| SONY | Sony Group Corporation | 2026-11-05 |  | $162B | $0.38 (1) | Q2 FY2026 consolidated financial results (6-K); +6.1%; f5359185 |
| MNST | Monster Beverage Corporation | 2026-11-05 |  | $141B | $0.30 (9) |  |
| PH | Parker-Hannifin Corporation | 2026-11-05 |  | $113B | $8.23 (6) |  |
| SO | Southern Company (The) | 2026-11-05 |  | $107B | $1.71 (6) |  |
| ABNB | Airbnb, Inc. | 2026-11-05 |  | $102B | $2.86 (11) |  |
| DUK | Duke Energy Corporation | 2026-11-05 |  | $101B | $1.87 (6) |  |
| CNQ | Canadian Natural Resources Limited | 2026-11-05 |  | $101B | $1.05 (2) |  |
| NET | Cloudflare, Inc. | 2026-11-05 |  | $87B | $0.02 (9) |  |
| CI | The Cigna Group | 2026-11-05 |  | $80B | $7.46 (7) |  |
| EOG | EOG Resources, Inc. | 2026-11-05 |  | $76B | $4.45 (8) |  |
| SPG | Simon Property Group, Inc. | 2026-11-05 |  | $73B | $3.32 (6) |  |
| APD | Air Products and Chemicals, Inc. | 2026-11-05 |  | $69B | $3.60 (7) |  |
| KMB | Kimberly-Clark Corporation | 2026-11-05 |  | $68B | $1.69 (6) |  |
| TRP | TC Energy Corporation | 2026-11-05 |  | $63B | $0.64 (4) |  |
| CAH | Cardinal Health, Inc. | 2026-11-05 |  | $62B | $2.92 (5) |  |
| CMI | Cummins Inc. | 2026-11-05 |  | $62B | $8.38 (7) |  |
| WPM | Wheaton Precious Metals Corp. | 2026-11-05 |  | $60B | $0.91 (5) |  |
| TRGP | Targa Resources, Inc. | 2026-11-05 |  | $58B | $2.81 (7) |  |
| BDX | Becton, Dickinson and Company | 2026-11-05 |  | $58B | $4.06 (7) |  |
| NTRA | Natera, Inc. | 2026-11-05 |  | $52B | ($0.17) (4) |  |
| SRE | Sempra | 2026-11-05 |  | $52B | $1.20 (4) |  |
| VMRK | Vivmark Residential | 2026-11-05 |  | $51B | $0.97 (5) |  |
| AKAM | Akamai Technologies, Inc. | 2026-11-05 | A | $11B | $0.92 (9) |  |
| ENB | Enbridge Inc | 2026-11-06 |  | $105B | $0.36 (5) |  |
| MRNA | Moderna, Inc. | 2026-11-06 |  | $96B | ($1.10) (7) |  |
| BAM | Brookfield Asset Management | 2026-11-06 |  | $84B | $0.44 (5) |  |

A-queue names printed in the week: AAPL 11-02, VRTX 11-02, AMD 11-03, ANET 11-03, SMCI 11-03, DDOG 11-04, QCOM 11-04, AKAM 11-05, COP 11-05 (9 of 46); of these ANET (+5.0%), SMCI (-5.7%), DDOG (-14.4%) and QCOM (-9.5%) have D1 earnings-move records (table); AAPL, VRTX, AMD, AKAM and COP have none in the pull. Market context recorded by D1 (not ticker catalysts): 2026-11-05 AI/semis rout, SPY -4.41%, SMH -11.21%, VIX 16.61 → 28.18 (entry 23dea2da); 2026-11-04 SPX +1.58%, VIX 20.83 → 16.61 with the midterm result cited as backdrop (entry a4e2f628; driver inferred by D1).

### 1A.4 — Product launches, keynotes, developer events (window 2026-11-08 → 2027-05-08)

Passed/resolved since W44 (dropped): none of the W44 rows in this table fell before 2026-11-08. Adobe MAX preconference days 11-08/09 precede the main event (below).

| Ticker/Event | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| ADBE | Adobe | Adobe MAX, Miami Beach Convention Center (preconference 11-08/09) | 2026-11-10 → 11-12 | (C-secondary) Δ firmer than W44 (E) | max.adobe.com listing text returned by WebSearch 2026-11-08 ("Conference Nov 10-12, preconference Nov 8-9"); Miami Beach Convention Center; page not opened |
| MSFT | Microsoft | Ignite, Moscone Center, San Francisco (pre-day 11-16) | 2026-11-17 → 11-20 | (E) | moscone.com/events/microsoft-ignite-2026 + ≥ 5 listings agree (WebSearch 2026-11-08); Microsoft page not opened |
| TTWO | Take-Two | Grand Theft Auto VI launch (PS5, Xbox Series X\|S; PC later) | 2026-11-19 | (C-secondary) | Take-Two reaffirmed 11-19 in its 2026-02-04 earnings release and a 2026-07-17 shareholder letter, per press summaries (WebSearch 2026-11-08); Take-Two release not opened. TTWO reports earnings 11-09 (1A.1) |
| AMZN | Amazon | AWS re:Invent, Las Vegas (badge/kickoff 11-29) | 2026-11-30 → 12-04 | (C) Δ upgraded from (E) | aws.amazon.com/events/reinvent (WebFetch 2026-11-08): "Nov. 30 to Dec. 4", Las Vegas; page gave no keynote timing |
| NVDA | NVIDIA | GTC Washington, D.C. (Ronald Reagan Building; workshops 11-30, conference 12-01 → 12-03; Huang keynote Tue 12-01 2:00 pm ET) | 2026-11-30 → 12-03 | (C) | nvidia.com/gtc/dc "November 30–December 3, 2026" (search result titles, 2026-11-08); keynote day/time from Baxtel + Eleven Forum listings (secondary) |
| GOOGL | Alphabet | Waymo multi-city robotaxi launches | 2026 (year only) | (T) | carried |
| — | broad | CES 2027, Las Vegas Convention Center | 2027-01-06 → 01-09 | (E) | majority of listings (audioXpress, gophotonics, tradeshowz, opencurious); CTA page not reached; one listing says 01-05..08; CES Unveiled 01-04 |
| — | healthcare broad | J.P. Morgan Healthcare Conference, San Francisco | 2027-01-11 → 01-14 | (E) carried | event-listing sites; organizer notes dates unconfirmed; not re-verified |
| NVDA | NVIDIA | GTC 2027 San Jose | 2027-03-14 → 03-18 | (C) carried | nvidia.com GTC FAQ (W43/W44), not re-read |

### 1A.5 — Analyst and investor days

Passed/resolved since W44 (dropped from the forward table): EPAC Investor Day 2026-11-04 (scheduled date; occurrence not verified); KMX "Strategic Update" investor event 2026-11-03 8:00 ET (D1 c51c9632: 8-K Item 7.01, KMX -5.4%); EL "Capital Markets Experience China" event 2026-11-04 announcing a fiscal-2030 ambition (D1 7701d3bc: 8-K Item 7.01, EL +6.3%). Marvell investor day was 2026-10-06 (past).

| Ticker/Event | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| ENTG | Entegris | Investor Day, NYC 1pm ET | 2026-11-09 | (C) carried | Entegris release 2026-08-26, not re-read |
| MH | McGraw Hill | Investor Day, NYC | 2026-11-18 | (E) carried | briefglance only |
| SHC | Sotera Health | Investor Day, NYC | 2026-11-20 | (T) carried | year not shown; unverified |
| NTR | Nutrien | Investor Day, Toronto | 2026-11-30 | (C) carried | Nutrien release 2026-09-23, not re-read |
| NU | Nu Holdings | First Investor Day, NYC | 2026-12-08 | (C) carried | Nu Holdings release 2026-09-02, W44 re-verified; not re-read |
| NKE | Nike | Investor day "Fall 2026" | — | (T) carried | |
| UNH | UnitedHealth | Investor conference | ~2026-12 early | (E) carried | |
| JPM | JPMorganChase | Investor Day | 2027-02-22 | (C) carried | not re-fetched |

Intuit hosted an Investor Day on 2026-09-17 (past; guidance reiterated per Intuit release text in search results). No new investor-day sweep was run this cycle (budget spent on date confirmation).

### 1A.6 — Regulatory, legal, trade and macro

PDUFA rows are mirrored in 1B.3 by another sub-agent (window to 12-23 there; this table runs to 2027-05-08). Macro dates marked (C) from bls.gov / federalreserve.gov unless noted; BLS rows are carried, not re-read.

**Passed/resolved since W44 (dropped, outcomes not researched here):**
- AGIO mitapivat sNDA PDUFA 2026-11-01: outcome UNRESOLVED as of W44; not re-searched.
- Midterm elections 2026-11-03: held; D1 (a4e2f628) cites a Democratic midterm sweep as backdrop for the 11-04 rally (D1's inference).
- Employment Situation (Oct) 2026-11-06 and Personal income & outlays (Sept) ~11-04: dates passed; releases not verified here.
- OPEC+ monthly meeting 2026-11-01: passed. BTAI IGALMI 11-14 row (struck in W44) not carried.
- Brent (FMP BZUSD via D1): 113.43 (10-30), 104.22 (11-02), 94.60 (11-04), 99.18 (11-05) - context.

| Ticker/Event | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| — | broad | CPI (Oct) | 2026-11-10 | (C carried) | bls.gov (W43/W44); not re-read |
| — | US-China | Busan one-year truce: reciprocal tariff cuts and suspension of the 2025-10-09 rare-earth export controls (one-year suspensions from late Nov 2025, i.e. lapse ~2026-11-10) | ~2026-11-10; W44 reported extension to **2027-01-10** | (E) Δ unchanged | WebSearch 2026-11-08 found NO official extension notice (USTR/WH/MOFCOM) and only 2025 coverage of the one-year terms; W44's "extended to 2027-01-10" came from one secondary report and remains uncorroborated. W43 row "USTR Sec 301 exclusions expire 11-10" carried, not re-verified |
| SMMT | Summit | Ivonescimab BLA PDUFA | 2026-11-14 | (C) | Summit release 2026-01-29 (carried) |
| CYTK | Cytokinetics | Aficamten label expansion | 2026-11-14 | (E) unverified | Assyro (carried) |
| Beren | Beren Therapeutics | Adrabetadex NDA | 2026-11-17 | (E) | Assyro; not listed (carried) |
| UNP·NSC | Union Pacific / Norfolk Southern | STB comments due | 2026-11-18 | (C) carried, **possibly superseded** | W44 row; see STB schedule note below |
| CAPR | Capricor | Deramiocel BLA (extended) | 2026-11-22 | (C) carried | 8-K 2026-08-24 |
| SVRA | Savara | Molgramostim BLA (extended) | 2026-11-22 | (E) | Assyro + Checkrare (carried) |
| — | broad | PCE (Oct) | ~2026-11-25 | (E) carried | single source |
| — | broad | GDP 2nd est. Q3 | 2026-11-25 | (E) carried | BEA per W43 |
| SAN | Sanofi (ADR) | Venglustat NDA PDUFA | 2026-11-25 | (C) carried | Sanofi release 2026-05-28 |
| BBIO | BridgeBio | BBP-418 NDA | 2026-11-27 | (E) | Assyro (carried) |
| GSK | GSK (ADR) | Neladalkib NDA | 2026-11-27 | (C) carried | Nuvalent release 2026-05-27; GSK release |
| ZYD | Zydus (not US-listed) | Saroglitazar | 2026-11-27 | (E) carried | |
| PYPD | PolyPid | D-PLEX100 NDA | 2026-11-28 | (C) carried | cap likely < $2B |
| VRTX | Vertex | Povetacicept BLA (accelerated, IgAN) | 2026-11-30 | (C) | Vertex release 2026-06-01 (carried) |
| COGT | Cogent | Bezuclastinib + sunitinib GIST NDA (priority) | 2026-11-30 | (C) carried | Cogent acceptance release |
| COGT | Cogent | Bezuclastinib NonAdvSM NDA | 2026-12-30 | (C) carried | Cogent release (per search) |
| RHHBY | Roche (ADR) | Giredestrant adjuvant NDA | 2026-11-30 | (E) | Assyro (carried) |
| EQT·RRC | EQT / Range Resources | All-stock merger (0.987 EQT per RRC; ~$13B); close targeted Q1 2027; shareholder votes + regulatory pending | announced 2026-10-26 | (C) carried | Range 8-K/425 and 10-Q; D1 7d029722; not re-read |
| UNP·NSC | Union Pacific / Norfolk Southern | DOJ/USDOT comments | 2026-12-03 | (C) carried, **possibly superseded** | W44 row |
| FSLR | First Solar + solar | Sec 232 tariff regime effective | 2026-12-04 | (C) carried, not re-verified | |
| — | broad | Employment Situation (Nov) | 2026-12-04 | (C) carried | bls.gov / calendars |
| VRTX | Vertex | Journavx sNDA | 2026-12-05 | (T) carried | |
| — | broad | **FOMC decision + SEP/dot plot** | 2026-12-09 (meeting 12-08/09) | (C) | federalreserve.gov/monetarypolicy/fomccalendars.htm fetched 2026-11-08 (curl, HTTP 200): "December 8-9, 2026 * (SEP)"; last 2026 meeting |
| — | broad | CPI (Nov) | 2026-12-10 | (C) carried | calendars; bls page not re-read |
| — | broad | US government funding: CR (P.L. 119-103) runs to **2026-12-11**; full-year FY27 appropriations unfinished | 2026-12-11 | (C-secondary) re-verified | signed 2026-09-02, Senate 90-6, House 370-48 (Fox News / Al Jazeera / Akin Gump via WebSearch 2026-11-08); no reporting found after early September on negotiation status |
| VNDA·ANAB | Vanda / AnaptysBio | Imsidolimab BLA | 2026-12-12 | (E) | Assyro (carried) |
| CORT | Corcept | Relacorilant NDA | 2026-12-17 | (E) | Assyro (carried) |
| — | Deciphera (Ono; not listed) | Tirabrutinib NDA | 2026-12-18 | (E) | Assyro (carried) |
| RHHBY | Roche (ADR) | Giredestrant + everolimus NDA | 2026-12-18 | (E) | Assyro (carried) |
| — | Camurus (not US-listed) | Oclaiz NDA | 2026-12-18 | (E) | Assyro (carried) |
| — | Hansa (not US-listed) | Imlifidase BLA | 2026-12-19 | (E) | Assyro (carried) |
| MLYS | Mineralys | Lorundrostat NDA | 2026-12-22 | (C) carried | release 2026-05-06 |
| — | broad | GDP 3rd est. Q3 | 2026-12-23 | (E) carried | |
| ACLX·GILD | Arcellx / Gilead | Anito-cel BLA | 2026-12-23 | (E) | Assyro (carried) |
| VTRS | Viatris | MR-107A-02 NDA | 2026-12-27 | (E) | Assyro (carried) |
| PRAX | Praxis | Relutrigine PDUFA (extended) | 2026-12-27 | (C) carried | 8-K 2026-06-29 |
| — | Saol (not listed) | SL1009 NDA | 2026-12-30 | (E) carried | |
| BA | Boeing | FAA 737 MAX 10 cert "by year-end" | — | (T) carried | |
| — | broad | Employment Situation (Dec) / CPI (Dec) | 2027-01-08 / 2027-01-13 | (C) carried | bls.gov |
| DYN | Dyne | Z-rostudirsen BLA (priority) | 2027-01-21 | (C) carried | |
| — | broad | **FOMC decision** (no SEP) | 2027-01-27 (meeting 01-26/27) | (C-tentative) | federalreserve.gov fetched 2026-11-08; page: "Each meeting date is tentative until confirmed at the meeting immediately preceding it" |
| V | Visa | DOJ debit case fact-discovery deadline | 2027-01-29 | (E) carried | |
| PHAR | Pharming | Joenja lower-dose sNDA | 2027-01-30 | (C) carried | |
| — | broad | Employment (Jan) / CPI (Jan) | 2027-02-05 / 02-11 | (C) carried | |
| UNP·NSC | UNP / NSC | STB responses due | 2027-02-16 | (C) carried, **possibly superseded** | W44 row |
| BMRN | BioMarin | VOXZOGO full approval | 2027-02-28 | (C) carried | |
| SRPT | Sarepta | AMONDYS 45 / VYONDYS 53 sNDAs | 2027-02-28 | (C) carried | |
| LYV | Live Nation | DOJ/states remedies | ~2027-02 | (E) carried | |
| WBD | Warner Bros Discovery | Antitrust trial begins | 2027-03-02 | (C) carried (note: D1 context line records WBD acquired by Skydance and delisted 2026-10-06; row likely moot) | |
| EXEL | Exelixis | Zanzalintinib + atezolizumab mCRC PDUFA (extended) | 2027-03-03 | (C) carried | OncLive/Exelixis (W43) |
| — | broad | Employment (Feb) / CPI (Feb) | 2027-03-05 / 03-10 | (C) carried | |
| — | broad | **FOMC decision + SEP** | 2027-03-17 (meeting 03-16/17) | (C-tentative) | federalreserve.gov fetched 2026-11-08 |
| — | broad | FTC v. Amazon trial | ~2027-03-29 | (E) carried | |
| HRMY | Harmony | Pitolisant GR PDUFA | 2027-04-01 | (E) carried | |
| — | broad | Employment (Mar) / CPI (Mar) | 2027-04-02 / 04-13 | (C) carried | |
| — | broad | **FOMC decision** (no SEP) | 2027-04-28 (meeting 04-27/28) | (C-tentative) | federalreserve.gov fetched 2026-11-08 |
| KMB·KVUE | Kimberly-Clark / Kenvue | Merger outside date extended to 2027-05-03 (W43 note) | 2027-05-03 | (E) carried | inside the window since the end rolled to 05-08 |

**UNP·NSC STB schedule note (new information, 2026-11-08 WebSearch):** FreightWaves/Trains summaries of the STB's 2026-08-18 decision report final briefs due 2027-05-28, a final decision within 90 days after the record closes (record-close date not yet set), i.e. second half of 2027 at the earliest; the STB had rejected the original application on 2026-01-16. The three W44 UNP·NSC rows above (11-18, 12-03, 2027-02-16) were not reconciled with that schedule; STB document itself not opened.

**Tariff / legal note (carried from W44, not re-verified):** Supreme Court struck down IEEPA tariffs (Learning Resources v. Trump, Feb 2026); Section 122 surcharge lapsed; CBP IEEPA refund phase for finally-liquidated entries opened 2026-10-06 (secondary); Section 232 semiconductor tariff 25% (effective 2026-01-15) stands; Section 301 tariffs on Chinese semiconductors scheduled 2027-06-23 (outside window). No dated Nov/Dec 2026 Section 232 deadline found (a sample, not proof of absence).

### 1A.7 — Restructuring, M&A and structural

D1 developments since 2026-11-01 (reused, not re-searched; entry ids from `events.decision_log`): MRVL–LITE merger (da7bf33a); CVI $4.2B Marathon Petroleum refinery-assets acquisition (CVI acquirer; c51c9632); MMM PFAS/AFFF MDL personal-injury settlement 11-03 (8-K Items 1.01/8.01; 7701d3bc); NEOG: Zoetis purchase of the Genomics business, regulatory review now expected to conclude early 2027 (8-K Item 8.01, 11-04; f5359185); ORCL issuance of $10B common stock, 86,206,897 shares (8-K Item 8.01, 11-04; f5359185; ORCL -6.9%); FCX board approval of $4.5B Bagdad expansion (11-04; f5359185); LBTYK Q3 earnings with spin-off plan discussed, no signed deal (11-03; c51c9632); FWONA/FWONK Exchange Agreement acquiring high-vote Series B from Malone-related entities (11-05; f5359185); PENG sale of Optimized LED business (11-03/04; 7701d3bc); INGM secondary offering of 11,000,000 shares by selling stockholder (11-04; f5359185); DT new $1B buyback (11-03; c51c9632); PTCT $500M buyback (11-03; c51c9632); SYY CFO appointment (11-03; c51c9632); UEC long-term uranium sales agreements (11-05; f5359185). M2 note (entry 67f68f9a, 2026-11-01): Skyworks–Qorvo closed 2026-10-05; WBD acquired by Skydance and delisted 2026-10-06; WDAY take-private unconfirmed; Kenvue pending (KMB/PG); DS Smith EMEA separation.

| Ticker/Event | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| MRVL·LITE | Marvell / Lumentum | **Δ NEW** all-stock merger: 4.500 MRVL shares per LITE share; agreement dated 2026-11-01; implied LITE enterprise value stated as $115B in the press release (a CEO email cited ~$100B); closing expected 1H calendar 2028 subject to MRVL and LITE stockholder votes (MRVL: share issuance + authorized-share charter amendment), regulatory approvals; MRVL termination fee $5.8B in certain cases + $3.2B regulatory termination fee; no meeting dates set | announced 2026-11-02; close 1H 2028 | (C) | Marvell IR PR 1040 "Marvell and Lumentum to Combine..." and LITE 8-K acc 0001193125-26-442758 / Form 425 (sec.gov) via WebSearch 2026-11-08, filings not opened; D1 da7bf33a (MRVL -12.7%, LITE -18.6% on 11-02) |
| EQT·RRC | EQT / Range | All-stock merger; close Q1 2027 | ann. 2026-10-26 | (C) carried | see 1A.6 |
| SGRY | Surgery Partners | Take-private (D1) | ann. ~2026-10-26 | (C per D1; terms not read) carried | D1 7d029722 |
| ADT | ADT | Deal (D1) | ~2026-10-29 | terms not read, carried | D1 b1e61b9c |
| — | Anthropic | IPO: confidential draft S-1 submitted 2026-06-01; **public Form S-1 reported filed 2026-10-26**, proposed Nasdaq Global Select listing, ticker "ANT"; offering size and price range not set; filing not effective. A WSJ-sourced report (via secondary outlets) says listing could come as early as the week of 2026-11-16 | pricing/listing date unknown | (T) Δ now reported by multiple outlets (letsdatascience, thepaypers, freepressjournal, futurumgroup, runtimewire); EDGAR not opened | WebSearch 2026-11-08; D1 cb06c3e0 cites an "Anthropic S-1" as sector driver 10-26/27 |
| PCRX·VTRS | Pacira / Viatris | $36.50 cash tender, ~$1.65B; closing "by end of 2026" | ann. 2026-10-08; close by ~2026-12-31 | (C) carried | Viatris 8-K; not re-read |
| NEOG·ZTS | Neogen / Zoetis | Genomics business sale; regulatory review to conclude early 2027 | early 2027 | (C per D1 8-K) | D1 f5359185 |
| PTC·Schneider; OPCH·CD&R/McKesson | | close undated | | carried, not re-verified | |
| (other W44 carried items) | ON·SYNA; UBER/ezCater; CMG·SBUX (T); ORCL/OpenAI (T); CVX·HESM; WDAY (T); CAT Fabick; KMB·KVUE; TECK; CTVA Vylor spin (Q4); Nasdaq-100 recon mid-Dec (E); S&P Q4 rebalance 2026-12-18 (E); DG CEO transition 2027-01-01; S&P Q1 rebalance 2027-03-19 (E) | | | carried unchanged | W44 (SWKS·QRVO dropped: closed 2026-10-05 per M2) |

### 1A.8 — Universe rails (carried, dated)

**Market-cap rail (≥ $2B).** Inside the C window the rail is Nasdaq's own `marketCap` field (every one of the 399 forward rows is ≥ $2B by construction; the smallest forward A-queue names by that field are OKTA $29.9B, NBIS $32.7B, NTAP $33.3B, TTWO $39.9B, all far above the floor; MEASURED from the CSV). Prior direct measurements are CARRIED, not re-measured: 2026-10-04 (61 names, 0 FAIL, smallest AAL $8.57B, AKAM $15.84B, FSLR $18.77B) and 2026-10-09 (50 vendor-calendar names via `company/batch-market-cap`, 0 FAIL, smallest RIOT $6.39B). Data is now 35 and 30 days old. **FAIL the cap floor, A-ineligible:** LCID ($1.17B) and FUBO ($0.84B) re-measured today from the Nasdaq all-caps file (MEASURED); TLRY carried. **ADR rail (carried):** TSM, NOK, SONY, BILI, BIDU, BABA, NIO, GSK, SAN, RHHBY are A-ineligible. **New/unmeasured this cycle:** the FMP 2027 rows (e.g. RKT, RIOT, SOFI, HOOD, COIN, PINS, ETSY, SNAP, ROKU, SIRI, RBLX, MGM) are cap UNMEASURED beyond the 12-23 Nasdaq pull; RIOT, SNAP, ROKU, SHOP, MRNA and UBER do appear in the Nasdaq ≥ $2B printed-week rows.

### 1A.9 — Rows struck, rejected or corrected this cycle (earnings only)

1. ~~All 2026-11-02 → 11-06 rows~~ - elapsed; moved to 'Printed this week'. The 11-02/11-03 Nasdaq rows that W44 tagged (C) were not independently checked for occurrence except through the D1 move records.
2. **Δ NBIS 2026-11-10 (E) → 2026-11-12 (C, BMO)** - Nebius notice dated 2026-10-30 (WebFetch); Nasdaq now also 11-12.
3. **Δ CSCO 2026-11-11 (E) → 2026-11-12 (C, AMC)** - Cisco release 2026-11-03 (call 1:30 pm PT).
4. **Δ HPE 2026-12-03 (E) → 2026-11-23 (Nasdaq, E)** - 10-day move on Nasdaq; no HPE notice found (WebSearch 2026-11-08).
5. **Δ other Nasdaq date moves vs W44:** TDG 11-11 → 11-10; MDT 11-17 → 11-24; BNS 12-01 → 12-02; RY 12-02 → 12-03; BMO 12-03 → 12-02; TM 11-04 → 11-05 and LITE 11-05 → 11-02 (both now printed week).
6. **A-queue date confirmations upgraded (E) → (C) this run:** CSCO, NBIS, HD, PANW (secondary), INTU (secondary), CRWD, MRVL, OKTA, SNOW. NTAP: issuer target 12-01 from the Q1 FY27 release (webcast notice pending).
7. **Searched, still NOT issuer-confirmed:** DELL 11-24 (IR page lists the event without a date; Tavily), HPE 11-23, CRM 12-02 (WebSearch + Tavily), ORCL 12-09 (calendar sites 12-09/12-10), ADBE 12-09, AVGO 12-10, MU 12-16.
8. **FMP/Nasdaq date disagreement (new):** BABA FMP 11-19 vs Nasdaq 11-24; unresolved, not searched.
9. FMP-only names absent from Nasdaq ≥ $2B inside the window: LCID 11-09, FUBO 11-17 (both below $2B). No other FMP in-window date disagrees with Nasdaq.
10. FMP lists FDX on both 2027-02-02 (chunk 2) and 2027-03-25 (chunk 3); both (T).

### 1A.10 — Names with NO firm forward earnings date

**Newly (C) this run (A-queue):** CSCO 11-12, NBIS 11-12, HD 11-17, PANW 11-18 (secondary), INTU 11-19 (secondary), CRWD 12-01, MRVL 12-01, OKTA 12-01, SNOW 12-02. Carried (C): TTWO 11-09, AMAT 11-12, NVDA 11-17, TGT 11-18, WMT 11-19.

**Forward A-queue names with an issuer target or only an (E) date (7 + 1):** NTAP 12-01 (issuer target), DELL 11-24, HPE 11-23, CRM 12-02, ORCL 12-09, ADBE 12-09, AVGO 12-10, MU 12-16 (all Nasdaq-sourced (E); searches in 1A.9 item 7).

**A-queue names with NO forward date in the Nasdaq pull (24):** the 15 with none (AMZN, CAT, CVX, FSLR, GEV, GOOGL, IBM, INTC, JPM, LLY, META, MRK, MSFT, NOW, XOM) and the 9 that printed 11-02 → 11-06 (AAPL, AKAM, AMD, ANET, COP, DDOG, QCOM, SMCI, VRTX). Of these, FMP (E) carries a next print for AAPL 2027-02-04, AMD 2027-02-02, AMZN 2027-02-04, GOOGL 2027-02-03, MSFT 2027-01-27, META 2027-01-27, INTC 2027-01-28, CVX 2027-01-29, XOM 2027-01-29, JPM 2027-01-14; MRK carried (C) 2027-02-02 (merck.com). **No date at all found:** AKAM, ANET, CAT, COP, DDOG, FSLR, GEV, IBM, LLY, NOW, QCOM, SMCI, VRTX. (CAT, GEV, NOW, LLY, FSLR printed 10-26 → 10-30 per W44; IBM printed in October, not in the pull.)

### 1A.11 — Liquidity rail (30-day ADV ≥ $10M), carried

CARRIED from the 2026-10-04 measurement (IBKR regular-session daily bars, 2026-08-21 → 2026-10-02): 61 of 61 cleared; lowest VRTX $222.0M (~22x floor). NOT re-measured by this sub-agent (now 35 days old). Names beyond that list (UAL, NFLX, GE, GM, LMT, CLS, NU, ENTG, EPAC, SHC, MH, NTR, ALAB, ROK, A, RKT, LITE) are UNMEASURED for ADV; ≥ $10M is INFERRED for large caps, unknown for EPAC/SHC/MH.

## PART 1B — Strategy C universe, 45-day window (2026-11-08 → 2026-12-23)

C qualifying types only: earnings (company IR), FDA PDUFA, FOMC. No interpretation. The C window is 2026-11-08 → 2026-12-23 (run date + 45 days, same convention as W44); the 12-08/09 FOMC sits inside. Tags: (C) confirmed by issuer/authority, (E) estimated, (T) tentative. 'carried' = read last cycle and not re-read this run. 'Search extract' = the issuer release was named and dated in a WebSearch/Tavily result; the issuer page itself was not opened first-hand unless stated. Metered calls this part: 33 WebSearch, 4 WebFetch (BLS CPI, BLS Employment Situation, BEA schedule, Nebius IR), 4 Tavily basic (4 credits); log at calls_1B.jsonl.

### 1B.1 — FOMC

| Event | Meeting | Decision date | In C window (11-08 → 12-23) | Tag | Source |
|---|---|---|---|---|---|
| FOMC | 2026-10-27/28 (no SEP) | 2026-10-28 — HELD, 3-3/4 to 4%, IORB 3.90%, 10-2 vote (Cook, Hammack preferring +25bp) — **carried from W44 row** (not re-read; D1 records since 11-01 contain no FOMC item; the fomccalendars page fetched today lists the meeting with statement links but states no outcome and no minutes yet) | NO — passed | (C) carried | federalreserve.gov/newsevents/pressreleases/monetary20261028a.htm (per W44); fomccalendars.htm fetched 2026-11-08T08:43Z |
| FOMC | 2026-12-08/09, **SEP/dot plot meeting** | **2026-12-09** (statement 2:00 pm ET and presser per W44; the page lists only the meeting dates) | **YES** (day 32 of the 2026-11-08 → 12-23 window, counting 11-08 as day 1) | (C) "Scheduled" | federalreserve.gov/monetarypolicy/fomccalendars.htm fetched 2026-11-08 |
| FOMC | 2027-01-26/27 (no SEP) | 2027-01-27 | No | tentative | same |
| FOMC | 2027-03-16/17 (SEP) | 2027-03-17 | No | tentative | same |
| FOMC | 2027-04-27/28 | 2027-04-28 | No | tentative | same |
| FOMC | 2027-06-08/09 (SEP) | 2027-06-09 | No | tentative | same |
| FOMC | 2027-07-27/28 | 2027-07-28 | No | tentative | same |
| FOMC | 2027-09-14/15 (SEP) | 2027-09-15 | No | tentative | same |
| FOMC | 2027-10-26/27 | 2027-10-27 | No | tentative | same |
| FOMC | 2027-12-07/08 (SEP) | 2027-12-08 | No | tentative | same |

Page note (verbatim in substance): "Each meeting date is tentative until confirmed at the meeting immediately preceding it"; the page also lists a two-day meeting January 25-26, 2028. Δ vs W44: C window end moved 12-16 → 12-23; Dec meeting day 39 → day 32 of the window (window start moved). C queue holds thesis-FOMC-C-20261130 (state.open_queue, orchestrator-MEASURED this run).

### 1B.2 — Earnings inside the C window: company-IR-confirmed subset

Window 2026-11-08 → 2026-12-23. Forward Nasdaq rows (≥ $2B) 11-09 → 12-21 = 399 rows; 11-26 and 12-23 returned zero rows. **Struck (printed 11-02 → 11-06, before the window):** AAPL, PLTR, VRTX, AMD, ANET, SHOP, PFE, SMCI, QCOM, UBER, DDOG, COP, AKAM (all W44 (C) rows, dates elapsed). Market caps below are the Nasdaq mcap_usd field in the 11-08 pull ($B, rounded). Names ≥ ~$50B plus every A-queue name in the window were checked; December names with no notice yet are expected only (E).

**Company-IR confirmed (C)**

| Date | Ticker | Timing | Mcap ($B) | Confirmation |
|---|---|---|---|---|
| 2026-11-09 | KKR | pre-market; call 10:00 am ET | 88 | **NEW** Business Wire "KKR & Co. Inc. to Announce Third Quarter 2026 Results" 2026-09-29 (search extract) |
| 2026-11-09 | B (Barrick) | pre-market (release 6:00 am ET; webcast 11:00 am ET) | 66 | **NEW** barrick.com Q3 2026 event page (search extract) |
| 2026-11-09 | TTWO | after close; 4:30 pm ET | 40 | carried (Take-Two release, W44) |
| 2026-11-12 | CSCO | after close; call 1:30 pm PT / 4:30 pm ET | 377 | **NEW** investor.cisco.com "Cisco Schedules Conference Call for Q1 Fiscal Year 2027 Financial Results" (announced 2026-11-03; search extract). Δ vs W44 Nasdaq/FMP 11-11 → 11-12 (E→C) |
| 2026-11-12 | NBIS | pre-market; call 8:00 am ET | 33 | **NEW** nebius.com newsroom "Nebius Group announces date of third quarter 2026 results and conference call" dated 2026-10-30 — **first-hand WebFetch**. Δ vs W44 Nasdaq 11-10 → 11-12 (E→C) |
| 2026-11-12 | AMAT | after close; 4:30 pm ET | 253 | carried (Applied Materials release 2026-10-22, W44) |
| 2026-11-17 | NVDA | after close; call 2:00 pm PT | 4,377 | carried (NVIDIA newsroom, W44) |
| 2026-11-17 | DIS | pre-market; webcast 8:30 am ET | 202 | carried (Disney release 2026-10-12, W44) |
| 2026-11-18 | PANW | after close (Nasdaq) | 258 | **NEW** Palo Alto Networks release dated 2026-11-03 "to Announce Fiscal First Quarter 2027 Financial Results on Wednesday, November 18, 2026" (search extract; webcast time not shown). Δ (E→C) |
| 2026-11-18 | TGT | pre-market | 72 | carried (corporate.target.com, W44) |
| 2026-11-19 | WMT | pre-market | 1,013 | carried (corporate.walmart.com, W44) |
| 2026-11-19 | INTU | after close; call 1:30 pm PT | 95 | **NEW** Intuit release 2026-10-29 "Intuit to Announce First-Quarter Fiscal Year 2027 Results on Nov. 19" (investors.intuit.com press release page returned by Tavily with text; investors.intuit.com home banner "November 19, 2026 - 4:30 PM EST Q1 2027 Conference Call"). Δ (E→C) |
| 2026-11-24 | DELL | after close; call 3:30 pm CST | 201 | **NEW** investors.delltechnologies.com "Upcoming Events: Nov 24, 2026 • 3:30 pm CST Dell Technologies Fiscal Year 2027 Third Quarter Results" (Tavily result of the IR page; a dated "to hold conference call" press release not located). Δ (E→C, IR event listing) |
| 2026-11-24 | WDAY | after close; call same afternoon | 48 | **NEW** Workday release "Workday to Announce Fiscal 2027 Third Quarter Financial Results on November 24, 2026" (search extract; relay site stockhub.kr/PRN) |
| 2026-12-01 | CRWD | after close; call 2:00 pm PT | 222 | **NEW** ir.crowdstrike.com "CrowdStrike Announces Date of Fiscal Third Quarter 2027 Financial Results Conference Call" 2026-11-04 (search extract). Δ (E→C) |
| 2026-12-01 | MRVL | call 1:30 pm PT after release (release time not stated in extract; Nasdaq: not supplied) | 117 | **NEW** investor.marvell.com "Marvell Technology, Inc. Announces Conference Call to Review Third Quarter of Fiscal Year 2027 Financial Results" 2026-11-06 (search extract). Δ (E→C). D1 recorded a Marvell all-stock merger announcement with Lumentum on 2026-11-02 (D1 entry da7bf33a) |
| 2026-12-01 | MDB | after close (Nasdaq) | 25 | MongoDB "announces date of third quarter fiscal 2027 earnings call" (finviz relay in search result; date 12-01) — secondary relay of issuer release, (C-secondary) |
| 2026-12-02 | SNOW | after close; call 2:00 pm PT | 95 | **NEW** snowflake.com "Snowflake to Announce Financial Results for the Third Quarter of Fiscal 2027 on December 2, 2026" (announced 2026-11-02; search extract). Δ (E→C) |

**Vendor-only (E) — no issuer notice found this run**

| Date | Ticker | Timing (Nasdaq) | Mcap ($B) | Source / check |
|---|---|---|---|---|
| 2026-11-09 | CEG | pre-market | 85 | Nasdaq; MarketBeat "estimated... may change once the company confirms"; Tavily search no issuer notice (Δ vs W44 CEG 11-06 → 11-09 was Nasdaq) |
| 2026-11-17 | HD | pre-market | 349 | Nasdaq; two WebSearch + one Tavily (ir.homedepot.com domain) found no Q3 notice; the ir.homedepot.com 2026 news-release index returned lists items only through 2026-09-29; last year's call notice was 11-04 for 11-18 |
| 2026-11-18 | LOW | pre-market | 127 | Nasdaq; Lowe's IR events page lists "Q3 2026 Earnings Conference Call (tentative)" 11/18/2026 (search extract); no notice (last year's came 11-12) |
| 2026-11-18 | TJX | pre-market | 152 | Nasdaq; a German outlet (boerse-express.com) reports TJX "confirmed" 11-18, 9:30 am ET release/11:00 am call; TJX release not seen — secondary only |
| 2026-11-23 | HPE | after close | 59 | Nasdaq (Δ vs W44 12-03 → 11-23; time supplied); search found no FQ4 FY26 notice (last year's call 12-04) |
| 2026-12-01 | NTAP | after close | 33 | Nasdaq; not searched |
| 2026-12-01 | OKTA | after close | 30 | Nasdaq; not searched |
| 2026-12-02 | CRM | not supplied | 183 | Nasdaq; two searches (one combined, one Salesforce-specific) found no notice; calendar sites show 12-02, unconfirmed (last year's timing notice 11-05) |
| 2026-12-02 | ZS | after close | 33 | Nasdaq; not searched |
| 2026-12-09 | ORCL | not supplied | 348 | Nasdaq 12-09; financecalendar.com lists 12-10 12:00 pm ET (conflict, both unconfirmed) |
| 2026-12-09 | ADBE | not supplied | 96 | Nasdaq + FMP 12-09 (EPS est 6.32); financecalendar 12-09 "to be confirmed" |
| 2026-12-10 | AVGO | not supplied | 1,392 | Nasdaq 12-10; financecalendar 12-10 "to be confirmed" |
| 2026-12-10 | COST | not supplied | 472 | Nasdaq + FMP 12-10 (EPS est 4.93); no date found |
| 2026-12-16 | MU | not supplied | 743 | Nasdaq 12-16; financecalendar lists 12-15 4:05 pm ET (conflict) |
| 2026-12-03 | DOCU | not supplied | 15 | Nasdaq + FMP 12-03; not searched |

**Other ≥ $50B names on the Nasdaq forward list, date vendor-only (E), not searched (no A-queue or carried status):** PBR 11-10 (121), TDG 11-10 (66), OXY 11-09 (56), BN 11-12 (102), NU 11-12 (57), MUFG 11-13 (251), SMFG 11-13 (150), MFG 11-13 (117), BHP 11-17 (203), PDD 11-17 (119), NTES 11-19 (81), ROST 11-19 (75), BABA 11-24 (262), ADI 11-24 (175), MDT 11-24 (134), ADSK 11-24 (56), DE 11-25 (179), BMO 12-02 (120), BNS 12-02 (113), RY 12-03 (282), TD 12-03 (201), CM 12-03 (105), AZO 12-08 (53), SNPS 12-09 (84), ACN 12-17 (177), CTAS 12-17 (90), NKE 12-17 (59; FMP 12-17), plus CCL 12-18 (40; FMP 12-18). Foreign-private issuers (PBR, BN, MUFG, SMFG, MFG, BHP, PDD, NTES, BABA, BMO, BNS, RY, TD, CM, NU) file 6-K/40-F; instrument eligibility not assessed here.

**Dropped / changed vs W44:** 13 passed rows struck (above). Moved to (C) this run: CSCO, NBIS, PANW, INTU, DELL, CRWD, MRVL, SNOW; new (C) rows KKR, B, WDAY, MDB (secondary). Still unconfirmed: HD, CEG, LOW, TJX, HPE, CRM, NTAP, OKTA, ORCL, ADBE, AVGO, COST, MU, DOCU. Δ dates: CSCO 11-11 → 11-12 (issuer); NBIS 11-10 → 11-12 (issuer); HPE 12-03 → 11-23 (Nasdaq, unconfirmed); CEG 11-06 → 11-09 (Nasdaq, carried). Marketcap changes since W44 are price-driven (e.g., MRVL 191 → 117, ORCL 422 → 348, AVGO 1,647 → 1,392, MU 1,057 → 743, NVDA 5,149 → 4,377); no filter applied.

### 1B.3 — FDA PDUFA dates in window (2026-11-08 → 2026-12-23)

Rule: sponsor/status resolved against the sponsor's own release or the FDA before naming either; a source that is only an aggregator or trade-press headline is tagged (E) and the row is "unresolved", not a dated forward action. Cap/ADV not measured. 'Release in extract' = the sponsor press release was named in a search result; the sponsor page itself was not opened first-hand.

| Date | Ticker | Sponsor / drug / indication | Tag | Resolution / source |
|---|---|---|---|---|
| 2026-11-14 (Sat) | SMMT | Summit Therapeutics — ivonescimab + chemo BLA / EGFRm non-squamous NSCLC post-TKI | (C) | Summit release 2026-01-29 (BusinessWire, release in extract; target action date Nov. 14, 2026). No FDA action or extension found (search 2026-11-08). Status: pending |
| 2026-11-14 | CYTK | Cytokinetics — aficamten (Myqorzo) label expansion | (E) UNRESOLVED | A date-specific search found no 2026 Cytokinetics release; only the earlier oHCM NDA (PDUFA 2025-09-26, extended 2025-12-26). The 11-14 entry stays on aggregators only; **recorded unresolved, not a dated action** |
| 2026-11-17 | — | Beren Therapeutics — adrabetadex NDA / infantile-onset NPC (review extended, trade headline) | (E) | not US-listed; trade press only |
| 2026-11-22 (Sun) | CAPR | Capricor — deramiocel BLA / DMD (PDUFA moved from 2026-08-22 after major amendment; narrowed to upper-limb indication per Aug-13 company update) | (C) carried | 8-K 2026-08-24 (W44, carried); this run's search could not re-confirm 11-22 from a post-August source (latest source found: PPMD 2026-08-13). 2026-07-29 adcom vote 9-3 against, per trade press (biopharminternational/pharmanow), not re-read |
| 2026-11-22 | SVRA | Savara — molgramostim (MOLBREEVI) BLA / autoimmune PAP | (C) | Savara release 2026-04-15 (BusinessWire, release in extract): 3-month extension, new target date Nov. 22, 2026 (original 2026-08-22, priority review) |
| 2026-11-25 | SAN (ADR) | Sanofi — venglustat / Gaucher disease type 3 | (C) carried | ADR; not C-eligible per W44; Pharmacy Times (2026-08-21) lists Nov 25 |
| 2026-11-27 | GSK (ADR) | Neladalkib / ALK+ NSCLC (Nuvalent asset; sponsor GSK after 2026-07-15 acquisition per W44) | (C) carried | ADR; Pharmacy Times lists "Nuvalent's neladalkib" Nov 27 — sponsor attribution in that listing differs from W44 and was not re-resolved this run |
| 2026-11-27 | BBIO | BridgeBio — BBP-418 / LGMD2I | (E) carried | aggregators, not re-read |
| 2026-11-27 | Zydus | Saroglitazar | (E) carried | not US-listed |
| 2026-11-28 | PYPD | PolyPid — D-PLEX100 | (C) carried | cap likely < $2B |
| 2026-11-30 | VRTX | Vertex — povetacicept BLA / IgAN | (C) | RTTNews headline "Vertex: FDA Accepts BLA Submission For Povetacicept, Assigns PDUFA Target Action Date Of Nov 30" (search extract); Vertex release 2026-06-01 per W44 |
| 2026-11-30 | COGT | Cogent — bezuclastinib + sunitinib / GIST (priority) | (C) carried | Cogent acceptance release; OncLive 2026-05-28 (W44) |
| 2026-11-30 | RHHBY | Roche — giredestrant adjuvant / early breast cancer | (E) carried | ADR; Pharmacy Times lists Nov 30 |
| Nov (undated) | RHHBY | Roche — obinutuzumab / primary membranous nephropathy | undated | ADR; trade press |
| Nov (undated) | REGN | Cemdisiran / gMG | undated carried | — |
| 2026-12-05 | VRTX | Journavx sNDA | (T) carried | not re-verified |
| 2026-12-12 (Sat) | VNDA | Vanda — imsidolimab BLA / generalized pustular psoriasis (W44 listed "VNDA·ANAB") | (E) | Dermatology Times headline "FDA Accepts Vanda Pharmaceuticals' BLA for Imsidolimab in GPP"; date 12-12 from search extract; Vanda release not opened; ANAB (AnaptysBio) role not resolved. **Unresolved** |
| 2026-12-17 | CORT | Corcept — relacorilant NDA resubmission / hypercortisolism (Cushing's) | (E) UNRESOLVED | Date 12-17 only on an aggregator (simianx.ai); Corcept's own resubmission release (June 2026) and FDA filing release name a 6-month clock but not the date in the extract. **Recorded unresolved, not a dated action** |
| 2026-12-18 | — | Camurus — CAM2029 resubmitted NDA / acromegaly | (E) | allsci/trade headline "FDA accepts Camurus resubmitted CAM2029"; extract gives 12-18; not US-listed |
| 2026-12-18 | RHHBY | Roche / Deciphera item | (E) carried | W44 listed "Roche/Deciphera 12-18"; not re-read |
| 2026-12-19 (Sat) | — | Hansa Biopharma — imlifidase BLA / kidney transplant | (E) | American Pharmaceutical Review headline "Hansa... Receives December 2026 PDUFA Date"; MarketScreener headline gives December 19; not US-listed |
| 2026-12-22 | MLYS | Mineralys — lorundrostat NDA / hypertension (with other antihypertensives) | (C) | Mineralys release 2026-03-09 (FDA acceptance; target date December 22, 2026) and Q1 release 2026-05-06 (both in extract); no later update found |
| 2026-12-23 | GILD | Gilead (Arcellx acquired; ACLX being delisted) — anito-cel BLA / 4L+ RRMM | (C) | Gilead/Arcellx release 2026-02-23 (BusinessWire in extract): FDA-accepted BLA, PDUFA target action date Dec. 23, 2026; Gilead release 2026-04-27 (acquisition completed, 77.2% by tender 04-28, remainder by merger) |

**Resolved / unresolved since last week (W44 rows whose date has passed or moved):**
- ~~2026-11-01 AGIO mitapivat sNDA / sickle cell~~ — **MOVED, not decided:** FDA extended the PDUFA goal date by 3 months to **2027-02-01** (HCPLive 2026-10-30 and GEN headlines, citing Agios; FDA information request 2026-10-09 re a possible REMS; Agios response 2026-10-19). Out of window. Source is trade press quoting the company; Agios release not opened.
- ~~2026-10-30 INO INO-3107~~ — outcome **UNRESOLVED**: one search this run found no approval or CRL item (results all predate 10-30). Not chased further.
- Carried strikes from W44 (do not re-import): GSK bepirovirsen APPROVED 2026-10-20 (Hibsago); Sun Pharma ILUMYA (not US-listed); BTAI IGALMI (BTAIQ PINK); EXEL zanzalintinib moved to 2027-03-03.
- D1 (records since 2026-11-01): REGN 2026-10-30 8-K (entry e2dfa715) records "FDA approval of Pasatru for FOP" alongside Q3 earnings and a Sanofi collaboration; this is a REGN approval record, not an item in the table above.
- Out of window by date: Praxis relutrigine 12-27 (review extended to Dec 27 per extract), Viatris 12-27, COGT NonAdvSM 12-30 (Cogent: PDUFA December 30, 2026).
- Coverage: two generic date-range searches (Nov, Dec 2026) plus nine sponsor-specific searches; this is a floor, not a census of PDUFA dates. No 12-10 → 12-16 PDUFA date surfaced beyond the rows above.

### Macro calendar in C window (2026-11-08 → 2026-12-23)

Context only; times 8:30 am ET unless noted.

| Date | Release | Tag | Source / note |
|---|---|---|---|
| 11-10 | CPI (Oct 2026), 8:30 am | (C) | bls.gov/schedule/news_release/cpi.htm fetched 2026-11-08 |
| 11-25 | Personal Income and Outlays (Oct 2026) incl. PCE, 8:30 am | (C) | bea.gov/news/schedule fetched 2026-11-08 (page last modified 11/8/26) |
| 11-25 | GDP (Second Estimate) and Corporate Profits, 3rd Quarter 2026, 8:30 am | (C) | same BEA page |
| 12-04 | Employment Situation (Nov 2026), 8:30 am | (C) | bls.gov/schedule/news_release/empsit.htm fetched 2026-11-08 (the 11-06 Oct report has already printed) |
| 12-08/09 | FOMC + SEP (decision 12-09) | (C) | federalreserve.gov (see 1B.1) |
| 12-10 | CPI (Nov 2026), 8:30 am | (C) | bls.gov CPI schedule page fetched 2026-11-08 |
| 12-23 | GDP (Third Estimate), Industries, Corporate Profits, 3rd Quarter 2026, 8:30 am | (C) | bea.gov schedule (last day of window) |
| 12-23 | Personal Income and Outlays (Nov 2026) incl. PCE, 8:30 am | (C) | bea.gov schedule (last day of window) |

Also on the BEA page in the window: International Trade in Goods and Services (Oct) 12-08; U.S. International Transactions (Q3) 12-18. W44 items not re-verified this run: government funding CR expiry 12-11 ((C-secondary), political.org/AACOM per W44) and 11-03 midterms (passed). Δ vs W44: PCE/GDP-2nd moved from "~11-25 (E)" to (C) 11-25; Oct PCE date conflict (10-29 vs 11-04) is moot (passed); GDP-3rd and Nov PCE both 12-23 (in window on its last day; W44 had GDP-3rd ~12-23 outside its window).

## PART 2A — Strategy A ranked shortlist

### The A-queue census — the PINNED query, run verbatim

`SELECT * FROM state.open_queue WHERE strategy = 'A'` → **46 rows** (MEASURED by the orchestrator 2026-11-08; same 46 as 2026-W44): AAPL, ADBE, AKAM, AMAT, AMD, AMZN, ANET, AVGO, CAT, COP, CRM, CRWD, CSCO, CVX, DDOG, DELL, FSLR, GEV, GOOGL, HD, HPE, IBM, INTC, INTU, JPM, LLY, META, MRK, MRVL, MSFT, MU, NBIS, NOW, NTAP, NVDA, OKTA, ORCL, PANW, QCOM, SMCI, SNOW, TGT, TTWO, VRTX, WMT, XOM (all item_type 'Strategy A queue', status pending). My hand enumeration of the list matches the query's 46 rows, so there is no discrepancy to reconcile; the query wins in any case. Every "QUEUED" / "NEW" mark below is tested against this list. Reconciliation: of the 59 names carried in this file, 39 admissible are QUEUED, 11 admissible are NEW, and 5 inadmissible are QUEUED (AMAT, WMT, ADBE, HD, AKAM); the two remaining census members, IBM and MRK, are not ranked (no forward catalyst; see Handoff).

### STEP 1 — the GATE DATE, re-derived from scratch, with the arithmetic shown

**DERIVED GATE DATE = 2026-11-08** (today, the run date; orchestrator-measured this run). Rev 52 STEP 1: earliest of (a), (b), (c). The retired pre-Rev 52 derivation was not run.

**Router state read first.** A's `STRATEGY_ACTIVATION` reads **DO-NOT-ACTIVATE** (`state.current_regime`). A is not ACTIVATE, so CATALYST-GATE MODE is live, not inert. A is LONG-ONLY (`strategy/03_strategy_a.md`: "Long-only (no short positions in A — short is B's territory)").

- **(a) Next scheduled M1a/M1b re-score.** Completed `M1a` = **1**, `M1b` = **1** this month (both 2026-11-01). `m1b >= 1`, so (a) = next month's first trading day = **2026-12-01**.
- **(b) Open `PENDING_REGIME_REFRESH` `regime-refresh` items:** **none** → does not apply.
- **(c) REFRESH REQUEST (D2a Step 0, verbatim query)** returned 1 row: `measured_trigger = vix_regime_high`, `trigger_run_start = 2026-11-05`, logged 2026-11-05 23:19:56 UTC (after D2a's 11-05 run finished 22:50 UTC). (b) found no open item, so (c) = D2a's next run = **2026-11-08** (D2a fires Sunday–Thursday at 16:40 MT; today is Sunday).
- **GATE DATE = earliest(2026-12-01, n/a, 2026-11-08) = 2026-11-08.** A candidate is SPENT-BY-GATE only if its dated catalyst falls strictly before 2026-11-08 with nothing dated on or after it; undated and forward-dated candidates are GATE-SURVIVING and get full (a)-(e). No input was unavailable, so FAIL-OPEN did not trigger (full depth was nevertheless applied to every candidate, because nothing is spent).

### STEP 2 — the DIRECTION ADMISSIBILITY rail (run before ranking and before gate classification)

Evidence read this week: D1 records 11-01..11-05 (`d1_catalysts.md`, entries a4e2f628, 23dea2da, da7bf33a, 514a7707, f5359185, e2dfa715/0b27dc01), IBKR regular-session daily bars through 11-06 (price only, not narrative), issuer/EDGAR releases cited per row, and secondary press where labelled. The Friday 11-06 narrative was not researched (structural weekly gap; price half closed below).

- **Nine names stay DIRECTION-INADMISSIBLE** (AMAT, WMT, ADBE, HD, AKAM, DAL, CCL, UAL, AAL). None is reversed to bullish. Two marks are WEAKER, one STRONGER:
  - **Fuel-shock cluster (DAL, CCL, UAL, AAL): bearish mark WEAKER.** Brent (FMP BZUSD via D1, provisional): 113.43 (10-30), 104.22 (11-02), ~103.60 (11-03), 94.60 (11-04), 99.18 (11-05). Press (Khaleej Times / Nation Thailand, 11-03) attributes the slide to US-Iran and Russia-Ukraine peace-talk hopes and Gulf crude exports returning toward pre-war levels (secondary). The fuel-cost thesis is eroding, but no bullish airline thesis is documented and no airline price was read, so they stay in the inadmissible tier as direction-unresolved. D2 should re-test before any B or A use.
  - **AMAT: bearish mark WEAKER, unresolved** (China-WFE-cliff framing contested by LRCX's record quarter and SK hynix on 10-28; the 11-05 sector rout hit the whole group). Not bullish-established either. Stays inadmissible.
  - **ADBE: mark STRONGER** (software kept falling: DDOG -14.4% on 11-04 on a flat Q4 guide; NOW -26.95% last week). **WMT, HD, AKAM: kept, no new evidence.**
- **TGT stays DIRECTION UNRESOLVED** (carried: prior bearish thesis refuted by a beat-and-raise, no replacement). Ranked last of the admissible list, ineligible for the top-10.
- **No new bearish names added.** The 11-05 rout (SPY -4.41%, SMH -11.21%) is a bullish-gap candidate generator for A only where fundamentals/prints are intact; names whose thesis it contradicts (COP, see row 17) are down-ranked, not flipped.

### STEP 3 — classification and counts

Gate date **2026-11-08**. SPENT-BY-GATE iff the dated catalyst is strictly before 2026-11-08 and there is nothing dated on/after it.

**59 carried: 50 ranked admissible (one, TGT, direction-unresolved) + 9 DIRECTION-INADMISSIBLE. 0 SPENT-BY-GATE, 59 GATE-SURVIVING.** Every name that printed 2026-11-02..11-06 was re-dated to its NEXT dated catalyst (FMP/Nasdaq, or the WebSearch fallback tagged (E)) or is `undated` (fail-open).

- **Printed this week, re-dated (MEASURED from FMP/Nasdaq unless noted):** AAPL 11-02 (next 2027-02-04 E FMP); PLTR 11-02 (2027-02-01 E FMP); VRTX 11-02 (keeps PDUFA 2026-11-30 C); SHOP 11-03 (2027-02-10 E FMP); AMD 11-03 (2027-02-02 E FMP); UBER 11-04 (2027-02-03 E FMP); MRNA 11-06 slot (2027-02-12 E FMP; whether the 11-06 print occurred is unverified, Friday gap); ANET 11-03 (2027-02-10/14 E, WebSearch fallback, MarketScreener/FXEmpire projections); SMCI 11-03 (2027-02-02 E, days.to projection); COP 11-05 (early February, MarketScreener projects 2027-02-10 E); ETN 11-03, QCOM 11-04, DDOG 11-04, AKAM 11-05: **no next date in FMP/Nasdaq; fallback found only "early February" patterns → `undated`** (INFERRED early Feb/late Jan, unsourced).
- **Date moves vs last week:** CSCO 11-11 (E) → **11-12 (C)** (Cisco IR notice); NBIS 11-10 → **11-12** pre-market (Nasdaq); HPE 12-03 → **11-23** after hours (Nasdaq); NVDA 11-17 stays (C, issuer notice reconfirmed); CEG 11-09 pre-market (E, no issuer notice found); TTWO 11-09 after hours (Nasdaq; no new issuer notice found by search); AVGO 12-10 (E, third-party calendar; Broadcom had not announced it in the sources searched).
- **Fragile (within one session of the gate):** TTWO and CEG (11-09). They are consumed by the first post-gate trading day.
- **Dropped from the ranked set (stay on the census where queued):** none this week (IBM and MRK were already dropped last week).
- **New intake:** none this week (the 50-name cap is full; all 11 NEW rows are carried intake).

### Price context (IBKR regular-session daily bars, MEASURED via `get_price_history`; 10-30 and 11-06 closes)

| Ticker | 10-30 | 11-06 | Wk chg | Note |
|---|---|---|---|---|
| SPY | 755.72 | 735.29 | -2.7% | 11-05 733.00 (-4.4% on the day), 11-04 766.81 (relief rally) |
| VRTX | 558.88 | 547.09 | -2.1% | peak 553.15 on 11-02 print day close; 11-03 530.76 |
| FSLR | 174.40 | 201.14 | +15.3% | 11-04 194.51 (high 214.87), +4.6% on 11-06 |
| TTWO | 190.17 | 214.87 | +13.0% | 11-04 +7.1%, 11-05 +2.1%, 11-06 +0.7%; new highs vs a 190 low |
| NVDA | 204.64 | 186.64 | -8.8% | 11-05 181.60 (-9.3%), volume 181M |
| AVGO | 326.08 | 293.69 | -9.9% | 11-05 291.53 (-10.4%) |
| CSCO | 104.51 | 93.85 | -10.2% | 11-05 95.72 (-7.6%); cause not established |
| CEG | 262.38 | 249.95 | -4.7% | 11-04 -6.7% (245.72) |
| MU | 884.74 | 690.00 | -22.0% | 11-05 656.39 (-17.5%) |
| MRVL | 196.40 | 141.20 | -28.1% | 11-02 -12.7% on the Lumentum deal, 11-05 133.55 |
| DELL | 424.30 | 328.53 | -22.6% | 11-05 316.91 (-14.9%) |
| AMD | 504.80 | 449.04 | -11.0% | 11-04 488.78, 11-05 404.40 (-17.3%) |
| ANET | 168.86 | 170.80 | +1.1% | 11-04 178.48, 11-05 159.16 (-10.8%) |
| ETN | 369.97 | 341.72 | -7.6% | 11-03 391.70 (+7.0% on print), 11-05 327.02 |
| SMCI | 32.95 | 28.76 | -12.7% | 11-04 -5.7% after the 11-03 print; 11-05 27.08 |
| QCOM | 164.79 | 165.41 | +0.4% | 11-04 173.19, 11-05 156.75 |
| LRCX | 239.11 | 200.44 | -16.2% | 11-05 185.20 (-16.4%) |
| COP | 154.03 | 136.27 | -11.5% | 11-04 136.94 (-5.2% on Brent), flat on the print |
| AAPL | 344.63 | 342.37 | -0.7% | 11-03 331.90 low, 11-04 349.51 |
| GOOGL | 279.84 | 284.78 | +1.8% | 11-04 288.93 |
| ORCL | 130.67 | 116.10 | -11.2% | 11-04 123.73 (-6.9% on the $10B stock issuance), 11-05 115.16 |
| PLTR | 184.11 | 160.38 | -12.9% | printed 11-02 AH; 11-05 154.99 |
| UBER | 65.25 | 68.59 | +5.1% | 11-04 +4.9% on print day |

**MEASURED vs INFERRED.** All closes are MEASURED (IBKR). Cause attributions: the 11-05 rout (SPY -4.41%, SMH -11.21%, VIX 16.61 → 28.18) is attributed by D1 (23dea2da) and press to fears that a Democratic congressional sweep slows the AI data-centre buildout and raises AI regulation (press: Nasdaq -5.5%, Nvidia about -9%, AMD about -17%; UBS estimate that construction pauses could put about 30% of expected 2028 US capacity additions at risk; secondary, figures approximate). That attribution is D1-recorded or secondary press, so it is a D1/INFERRED cause, not an issuer fact. The 10-30 chip selloff that last week's file left unexplained is now explained by D1 (0b27dc01): INTC's 10-29 after-close print (INTC -28.6%) triggered an AI/semis liquidation (SMH -6.98%), D1-recorded.

### Week narrative driving the revisions (MEASURED from issuer releases cited in rows, D1 and IBKR; inferences labelled)

- **Prints were strong, prices fell on policy.** Arista (Q3 revenue $3.66B +58.5%, Q4 guide $3.9-4.0B), AMD (Q3 revenue about $13.4B, Q4 guide about $17B ±3%), Eaton (record orders, 2026 EPS guide $13.70-13.80), Super Micro (FY27 revenue guide raised to $72-82B), Palantir (revenue about $2.31B +96%, FY guide $8.53B), Uber (gross bookings $59.8B +20%) all beat or raised. The 11-05 rout then took AI-hardware names 10-20% lower regardless. Reading for A: where fundamentals printed intact and the move was policy/beta, the gap hypothesis is bullish; the counter is that the policy risk (state-level data-centre halts, regulation) is a genuine change in the demand path that no print refutes, and SPY's 11-05 close shows the market repriced the whole complex, not individual issuers.
- **Counter-datapoints.** Datadog fell 14.4% on a flat Q4 revenue guide that assumes its largest customer at minimum commitment; Qualcomm printed a 26% handset-revenue drop on memory constraints and guided FQ1 EPS $2.15-2.35 against about $2.27 expected (marketbeat/webull secondary), -9.5% on 11-05 in D1's single-name screen; Oracle issued $10B of common stock (8-K Item 8.01, 11-04, -6.9%).
- **M&A.** Marvell agreed to acquire Lumentum in an all-stock deal (4.500 MRVL shares per LITE share; implied EV about $115B per press; close expected H1 2028; D1 da7bf33a, 8-K Item 1.01 pre-open 11-02). MRVL -12.7% (acquirer); Bank of America sees dilution through 2030 (Benzinga via search, secondary).
- **Energy.** Brent fell from 113.43 to 94.60 (11-04) before 99.18 (11-05) on peace-talk hopes and returning Gulf exports (secondary); XLE -4.74% on 11-04. COP beat (adjusted EPS $3.27 vs $3.06; Q4 production guide 2.32-2.36 MMBOED; dividend +11% to $0.93; 8-K Ex-99.1 11-05) but the stock is -11.5% on the week.
- **Policy.** The 11-03 midterm results (Democratic sweep per D1) are the common driver: positive for solar (FSLR +15.3%), negative for AI data-centre build-out.

### TOP-10 — the actionable tier

**Selection rule (stated for W4).** Only ADMISSIBLE, GATE-SURVIVING names with a DATED post-gate catalyst that is not merely a consumed print. Undated names are excluded from the tier. All ten rows are long. Zero SPENT names. TTWO and CEG are fragile (11-09, one session after the gate).

**1. VRTX - Vertex Pharmaceuticals.** (a) Bullish. (b) Povetacicept (IgAN) FDA decision, PDUFA **2026-11-30**, restated in Vertex's own Q3 release (re-checked this week): https://investors.vrtx.com/news-releases/news-release-details/vertex-reports-third-quarter-2026-financial-results (2026-11-02; via search snippet): revenue $3.44B (+12%), 2026 revenue guide raised to $13.15-13.25B, RAINIER Phase III fully enrolled, GAAP net income $654M on the Crinetics charge. Documents for construction: the 10-Q, BLA acceptance notice. Counter-evidence (MEASURED): 547.09, -2.1% on the week, so the approval is partly priced after a run from 517 on 10-26; Q3 launch metrics drew criticism in one BioSpace piece (that piece's revenue figure conflicts with the release and is disregarded). (c) PDUFA **2026-11-30 (C)**. (d) QUEUED; no open position. (e) Top-10, conviction **4**. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2026-11-30)

**2. FSLR - First Solar.** (a) Bullish. (b) Section 232 polysilicon-and-derivatives regime, signed 2026-08-06, effective **2026-12-04**: 15% duty on covered ingots/wafers/cells/modules plus minimum import prices (modules $0.38/W, cells $0.22/W, wafers/ingots $100/kg, polysilicon $21/kg) per BDO / Thomson Reuters summaries (https://www.bdo.com/insights/tax/new-tariffs-and-minimum-import-prices-on-polysilicon-derivatives-and-solar-products; https://www.thomsonreuters.com/en-us/help/onesource-global-trade/regulatory-insights/2026/august-12th/us-section-232-polysilicon-import-prices-tariffs.html; both re-checked via search this week). New: Democratic sweep read as positive for solar (press: FSLR +9% on 11-04, Mizuho PT $328 from $324, Outperform; secondary). FSLR makes CdTe thin film, so the polysilicon floor lifts its competitors' cost, not its own (INFERRED from a prior-week read; this week's sources did not address FSLR's exposure). Counter-evidence (MEASURED): +15.3% on the week to 201.14, so part of the gap has closed; the 10-29 beat (EPS $5.30 vs $4.64) is carried. Documents for construction: proclamation text, 10-Q. (c) **Sec 232 effective 2026-12-04 (C)**. (d) QUEUED; no open position. (e) Top-10, conviction **4** (held; gap narrower after the rally). GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2026-12-04)

**3. NVDA - NVIDIA.** (a) Bullish. (b) Issuer notice re-checked this week: https://nvidianews.nvidia.com/news/nvidia-sets-conference-call-for-third-quarter-financial-results-6928873 - call **Tuesday 2026-11-17**, 2 pm PT, quarter ended 10-25, CFO commentary at about 1:20 pm PT. Nasdaq consensus EPS $2.49 (13 estimates). Gap hypothesis (INFERRED): price 186.64 (-8.8% week, 181.60 low on 11-05 on 181M shares) reflects a policy-driven demand-path discount applied before a print; if the print and guide hold supply-constrained demand, the gap closes. Counter-evidence: the policy risk is real (state-level data-centre pauses; UBS 30% 2028 capacity-at-risk estimate, secondary), and circular-financing/CoreWeave credit objections (carried). Documents for construction: FQ2 10-Q, last four transcripts, hyperscaler capex disclosures. (c) Earnings **2026-11-17 (C)** after hours. (d) QUEUED; no open position. (e) Top-10, conviction **3**. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2026-11-17)

**4. TTWO - Take-Two Interactive.** (a) Bullish. (b) GTA VI launch **2026-11-19**, FY27 net bookings guide $8.0-8.2B reaffirmed, fiscal-Q2 net bookings guide $1.62-1.67B (MarketPulse preview dated 2026-11-05: https://www.marketpulse.com/markets/take-two-interactive-ttwo-q3-earnings-preview-gta-vi-launch-is-the-critical-catalyst-for-ttwo/; secondary, re-checked this week). The same preview cites an options-implied move of about ±10.2% on the print and a bear case of any new timetable doubt. Counter-evidence (MEASURED): the stock has rallied +13.0% in a week to 214.87 (190.17 on 10-30), so the pre-print gap has partly closed; a slip would be thesis-invalidating. This agent's search found no fresh issuer notice, but PART 1B.2 carries the 11-09 after-close date as issuer-confirmed from Take-Two's own release read in W44 (orchestrator reconciliation at assembly; Nasdaq EPS forecast $0.49, 6 estimates). (c) Earnings **2026-11-09 (C, carried)**; GTA VI **2026-11-19 (C)**. (d) QUEUED; no open position. (e) Top-10, conviction **3** (down from 4: price gap narrowed, date unconfirmed this week). Fragile. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2026-11-09)

**5. AVGO - Broadcom.** (a) Bullish. (b) Q3 FY2026 release (https://investors.broadcom.com/news-releases/news-release-details/broadcom-inc-announces-third-quarter-fiscal-year-2026-financial; via search, re-checked this week): Q4 revenue guide about $34.8B, non-GAAP operating margin about 66%. Price 293.69 (-9.9% week; 291.53 on 11-05, -10.4%): the policy rout, not an issuer event. Counter-evidence: AI-debt vehicle/OpenAI financing reports and CoreWeave credit (carried); the policy risk applies equally. Nasdaq consensus EPS $3.45 (10 estimates). (c) Earnings **2026-12-10 (E)** after hours (third-party calendars; not announced by Broadcom in the searched sources). (d) QUEUED; no open position. (e) Top-10, conviction **3**. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2026-12-10)

**6. CSCO - Cisco.** (a) Bullish. (b) Issuer notice re-checked this week (newly dated): https://investor.cisco.com/news/news-details/2026/Cisco-Schedules-Conference-Call-for-Q1-Fiscal-Year-2027-Financial-Results/default.aspx - Q1 FY27 call **Thursday 2026-11-12**, 1:30 pm PT, quarter ended 2026-10-24. Fiscal-2027 guide revenue $72.2-73.4B (Q4 FY26 release 2026-08-12; https://investor.cisco.com/news/news-details/2026/CISCO-REPORTS-FOURTH-QUARTER-AND-FISCAL-YEAR-2026-EARNINGS/default.aspx). Carried: hyperscaler AI orders about $9B in FY26 and some possible pull-forward (secondary). Nasdaq EPS $1.15 (8 est.), FMP $1.32 (consensus figures disagree). Price 93.85 (-10.2% week, 11-05 -7.6%; cause not established beyond the sector tape, INFERRED). (c) Earnings **2026-11-12 (C)**. (d) QUEUED; no open position. (e) Top-10, conviction **3**. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2026-11-12)

**7. CEG - Constellation Energy. NEW.** (a) Bullish. (b) Power for AI load and nuclear contracting; 2026 adjusted-operating-earnings guide $11.50-12.50 (carried secondary). Nasdaq EPS $3.90 (5 est.). Earnings Whispers lists 2026-11-09 before the open; no Constellation release found (https://www.earningswhispers.com/article/CEG/22555). Price 249.95 (-4.7% week; -6.7% on 11-04 as the AI-power complex sold). Gap hypothesis (INFERRED): contracted baseload is less exposed to a build-out slowdown than merchant capex names, yet sold off with them; a policy slowdown is the counter. Documents for construction: Q3 release, 10-Q. (c) Earnings **2026-11-09 (E)** pre-market. (d) **NEW** (not on the census). (e) Top-10, conviction **2**. Fragile. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2026-11-09)

**8. MU - Micron.** (a) Bullish. (b) FQ4 call 2026-09-30 (marketbeat transcript summary; re-checked via search): FQ1 guide revenue $61.5B ±$1.5B, non-GAAP EPS $38.15 ±$1, gross margin about 86.25% ("low point for fiscal 2027" per management), supply "much tighter" through 2027-28; QCOM's 11-04 call independently cites industry memory constraints and higher prices (secondary), consistent with pricing power. Price 690.00 (-22.0% week, 11-05 -17.5%) is the biggest percentage gap among large caps in the tier. Counter-evidence: strategic long-term agreements cover about 20% of DRAM volume and one third of NAND (cap capture of spot spikes); the rout is policy-driven but memory is AI-capex-geared; CXMT supply (carried). (c) FQ1 **2026-12-16 (E)** (Nasdaq; days.to projects 12-16 4:30 pm ET; Micron had not announced it). (d) QUEUED (the queue row cites the consumed 09-30 print; stale). No open position. (e) Top-10, conviction **3** (new to the tier). GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2026-12-16)

**9. MRVL - Marvell Technology.** (a) Bullish (merger-reaction overshoot). (b) D1 8-K record: Item 1.01 pre-open 2026-11-02 (https://www.sec.gov/Archives/edgar/data/1835632/000119312526442717/d352474d8k.htm; D1 da7bf33a): all-stock acquisition of Lumentum at 4.500 MRVL per LITE share (the 8-K is the merger announcement; Marvell's FQ3 FY27 results are scheduled separately for 12-01 per its own IR notice, PART 1B.2 — orchestrator correction at assembly); MRVL -12.7% on the day after two earlier double-digit declines (10-29, 10-30). Press: management targets $550B AI-connectivity TAM and more than $1B annual cost savings, expects first-year EPS accretion; Bank of America sees dilution through 2030; 25 of 27 analysts rate Buy (secondary). Price 141.20 (-28.1% week). Gap hypothesis (INFERRED): the market priced the worst case on dilution and AI demand together. Counter-evidence: overpay/dilution is a genuine thesis break for one analyst; customer-conflict risk (buyer owns a competitor's supplier); lasting H1 2028 close timeline. (c) FQ3 **2026-12-01 (C)** (Marvell IR notice 2026-11-06, PART 1B.2; orchestrator reconciliation at assembly). (d) QUEUED; no open position. (e) Top-10, conviction **2**. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2026-12-01)

**10. DELL - Dell Technologies.** (a) Bullish. (b) Q2 FY27 baseline (secondary, pulse2/niftytrader): AI-server backlog $95B (from $51.3B), FY27 AI-server revenue outlook about $74B, Q3 guide about $49B and EPS about $6.50. This week's read-through: Super Micro's 11-03 release (https://www.sec.gov/Archives/edgar/data/0001375365/000137536526000026/exhibit991_20260930.htm) raised FY27 revenue to $72-82B from $65-72B (non-GAAP EPS $1.81 vs $1.01-1.10 guide), supporting server demand. Price 328.53 (-22.6% week; 11-05 -14.9%). Counter-evidence: memory cost pressure on server margins (Barclays downgrade 10-14, note not read; SMCI GAAP gross margin 12.7% with a lower H2 margin guide); policy risk. Nasdaq EPS $6.41 (8 est.). (c) FQ3 **2026-11-24 (C)** (Dell IR events page, PART 1B.2; this agent's own search had not found it — orchestrator reconciliation at assembly). (d) QUEUED; no open position. (e) Top-10, conviction **2**. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2026-11-24)

### 11-20

Research-cost note: carry-forward rows keep (b) terse where unchanged; every row carries (a)-(e).

**11. AMD - AMD.** (a) Bullish. (b) Q3 beat and Q4 guide (finviz/letsdatascience summaries of the AMD release, via search): revenue about $13.4B (+45%), data centre $8.5B (+97%), non-GAAP EPS $2.09 vs about $1.94; Q4 guide about $17B ±3% (about 4% above consensus per one source). Stock closed 488.78 on 11-04 then 404.40 on 11-05 (-17.3%); 449.04 on 11-06. Counter-evidence: lost the exclusive SpaceX compute socket to NVDA (carried, 2026-08-05); expectations were high going in (+140% YTD per one source). Reaction reports conflict on 11-03/11-04 and are not relied on. (c) Next print **2027-02-02 (E)** (FMP). (d) QUEUED. (e) 11-20, conviction **3**; no dated near catalyst of its own (NVDA 11-17 is a read-through). GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2027-02-02)

**12. ANET - Arista Networks.** (a) Bullish. (b) Q3 release (https://www.sec.gov/Archives/edgar/data/0001596532/000159653226000252/ex991q326-earningsrelease.htm; re-checked): revenue $3.66B (+58.5% y/y), non-GAAP operating margin 49.1%, non-GAAP EPS $1.20; Q4 guide revenue $3.9-4.0B, EPS $1.26-1.30; 2026 revenue guide raised to about $13.3B (+48%). Price 170.80 (+1.1% week) is the only AI-hardware name not lower, so the gap is narrower. Counter-evidence: customer concentration, tariffs, component supply; 11-05 -10.8% on the sector tape. (c) Next print **2027-02-10 (E)** (WebSearch fallback: FXEmpire projects 02-10, MarketScreener 02-14; not issuer-confirmed). (d) QUEUED. (e) 11-20, conviction **3**. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2027-02-10)

**13. ETN - Eaton. NEW.** (a) Bullish. (b) Q3 (8-K Ex-99: https://www.sec.gov/Archives/edgar/data/0001551182/000155118226000037/etn09302026exhibit99.htm; re-checked via search): sales $8.9B (+28%), adjusted EPS $3.68 vs $3.54, data-centre revenue about +65%, rolling-12-month orders +39%, backlog about $16B, 2026 EPS guide raised to $13.70-13.80, Q4 EPS guide $4.05-4.15. Price 341.72 (-7.6% week; +7.0% on the print, then -10% on 11-05 on the policy rout). Gap hypothesis (INFERRED): the print gains were given back on a policy shock the order book contradicts for the near term. Counter: data-centre pause risk concentrated in exactly Eaton's end market. (c) Next print **undated** (early February by pattern, INFERRED; fallback search found no date). (d) **NEW**. (e) 11-20, conviction **3**. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst undated)

**14. SMCI - Super Micro.** (a) Bullish. (b) FQ1 FY27 (8-K Ex-99.1, 11-03; via search): net sales about $19.9B, non-GAAP EPS $1.81 vs the $1.01-1.10 guide, FY27 revenue guide raised to $72-82B, FQ2 guide $19.5-21.5B and EPS $1.66-1.90; operating cash outflow $434M; figures marked preliminary/unaudited. Price 28.76 (-12.7% week; -5.7% on 11-04 despite the beat). Counter: low and falling margins (12.7% GAAP), cash burn, preliminary numbers. (c) Next print **2027-02-02 (E)** (WebSearch fallback, days.to projection). (d) QUEUED. (e) 11-20, conviction **2**. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2027-02-02)

**15. QCOM - Qualcomm.** (a) Bullish, reduced. (b) FQ4 (11-04; marketbeat/webull secondary): handset revenue -26.2% to about $5.1B on industry memory constraints, automotive +89% to $1.99B, FY27 data-centre target $5B reiterated, FQ1 guide revenue $10.4-11.2B and EPS $2.15-2.35 vs about $2.27 expected; D1 shows -9.5% on the print. Price 165.41 (+0.4% week). The 10-30 -11% cut that created last week's gap is now explained by the INTC-driven liquidation; the print then added a handset-revenue problem. Gap largely closed or reversed. (c) Next print **undated**. (d) QUEUED. (e) 11-20, conviction **2**. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst undated)

**16. LRCX - Lam Research.** (a) Bullish. (b) Printed 10-21: December-quarter guide revenue $8.6B ±$0.4B, EPS $2.33 ±$0.15, operating margin 40.5% (marketbeat/247wallst summaries); WFE view raised in July (carried). Price 200.44 (-16.2% week; 11-05 -16.4%). Counter: AI-capex policy risk; supply timing. (c) Next print **undated**: the WebSearch fallback found only last year's 2026-01-28 call; a late-January 2027 call is INFERRED. (d) **NEW**. (e) 11-20, conviction **2**. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst undated)

**17. COP - ConocoPhillips.** (a) Bullish, thesis weakened. (b) Q3 8-K (https://www.sec.gov/Archives/edgar/data/0001163165/000116316526000043/cop-20261105x8kexx991.htm, 11-05): adjusted EPS $3.27 vs $3.06 consensus, production 2,302 MBOED (-2% adjusted y/y), Q4 guide 2.32-2.36 MMBOED, dividend +11% to $0.93. Last week's gap hypothesis (consensus models a transient shock; Hormuz flows point to a structural one) is contradicted by the week's evidence: Brent fell to 94.60-99.18 and press reports Gulf exports resuming (secondary). Price 136.27 (-11.5% week). Remaining case: stock may overshoot Brent. (c) Next print **2027-02-10 (E)** (WebSearch fallback, MarketScreener projection; early-February pattern). (d) QUEUED. (e) 11-20, conviction **2** (down from 3). GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2027-02-10)

**18. AAPL - Apple.** (a) Bullish. (b) FQ4 2026 (reported 11-02; secondary summaries of the Apple release, re-checked): revenue about $114.5B (+12%), iPhone about $57.6B (+17.5%), EPS $2.10, gross margin 47.9% including about one point of tariff refunds; December-quarter guide revenue growth 7-10% and gross margin 45-46%. Price 342.37 (-0.7% week), defensive through the rout. Counter: memory cost and Siri AI cost in margins; the guide's gross-margin step-down. Print consumed. (c) Next print **2027-02-04 (E)** (FMP). (d) QUEUED. (e) 11-20, conviction **2** (down from 3: print consumed, no dated near catalyst). GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2027-02-04)

**19. GOOGL - Alphabet.** (a) Bullish. (b) The 10-28 EPS miss ($2.12 vs about $3.02) is largely an $8.7B equity-investment loss (about 55 cents per share), per press (newsquawk/247wallst summaries; the 10-Q was not read in full this run, so INFERRED from secondary); one analysis still shows an operating-income shortfall (about $40.6B vs $43.2B, unverified). Price 284.78 (+1.8% week), the best performer among the large caps here. The "charge vs operating" question flagged last week is therefore partly answered: a mark-to-market loss, not a recurring cost. Documents to pull: 10-Q other-income note. (c) Next print **2027-02-03 (E)** (FMP). (d) QUEUED; **two open Strategy D lots** (D2 to confirm sleeves are distinct). (e) 11-20, conviction **2**. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2027-02-03)

**20. ORCL - Oracle.** (a) Bullish. (b) $10B common-stock issuance, 86,206,897 shares (8-K Item 8.01, 11-04; D1 f5359185; https://www.sec.gov/Archives/edgar/data/1341439/000119312526447507/d131790d8k.htm), -6.9% on the day; funding structure (record CDS, OpenAI financing reports, carried) is the live question. Price 116.10 (-11.2% week). Equity rather than debt funding may reduce credit risk; dilution is the counter. (c) FQ2 **2026-12-09 (E)** (Nasdaq; EPS $1.56). (d) QUEUED. (e) 11-20, conviction **2**. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2026-12-09)

### 21-30

- **21. PLTR - Palantir. NEW.** (a) Bullish. (b) Q3 (secondary, benzinga/stocktwits summaries): revenue about $2.31B (+96%), adjusted EPS $0.44 vs about $0.41, US commercial $984M above US government $953M for the first time, FY revenue guide raised to about $8.53B, Q4 guide about $2.65B vs about $2.46B expected; shares -3% after hours then 160.38 (-12.9% week). (c) Next print **2027-02-01 (E)** (FMP). (d) NEW. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2027-02-01)
- **22. UBER - Uber. NEW.** (a) Bullish. (b) Q3 8-K (https://www.sec.gov/Archives/edgar/data/0001543151/000154315126000039/uberq326earningspressrelea.htm): gross bookings $59.8B (+20%), adjusted EBITDA $3.0B (+31%), non-GAAP EPS $0.88, Q4 guide gross bookings $63.25-65.25B and EBITDA $3.13-3.23B; Zacks notes a GAAP EPS miss on an investment loss. +5.1% on the week to 68.59 (best of the group). (c) Next print **2027-02-03 (E)** (FMP). (d) NEW; open Strategy D lot. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2027-02-03)
- **23. DDOG - Datadog.** (a) Bullish, reduced. (b) Q3 (finviz release summary): revenue about $1.20B (+35%), RPO $3.85B (+38%), but Q4 revenue guide $1.19-1.20B flat vs Q3 on a largest-customer minimum-commitment assumption; -14.4% on 11-04 (D1). Gap hypothesis (INFERRED, weak): the guide embeds a single-customer worst case. Counter: billings +30% below revenue; fewer large wins. (c) Next print **undated** (early/mid February INFERRED). (d) QUEUED. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst undated)
- **24. HPE - Hewlett Packard Enterprise.** (a) Bullish; as DELL. (b) SMCI read-through; Nasdaq EPS $1.17 (7 est.). (c) **2026-11-23 (E)** after hours (Nasdaq; moved from 12-03). (d) QUEUED. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2026-11-23)
- **25. NTAP - NetApp.** (a) Bullish. Barclays downgrade 10-14 (carried). (c) **2026-12-01 (E)** after hours (Nasdaq; EPS $2.13). (d) QUEUED. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2026-12-01)
- **26. CRWD - CrowdStrike.** (a) Bullish; module attach. Software-group contagion (DDOG -14.4%) is the counter. (c) **2026-12-01 (E)** after hours (Nasdaq). (d) QUEUED. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2026-12-01)
- **27. PANW - Palo Alto Networks.** (a) Bullish; platformisation. (c) FQ1 FY27 **2026-11-18 (E)** after hours (Nasdaq; EPS $0.52, 15 est.). (d) QUEUED. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2026-11-18)
- **28. CRM - Salesforce.** (a) Bullish; agentic-AI attach vs compressed multiple; NOW's -26.95% and DDOG's -14.4% are direct counter-evidence for the same framing. (c) **2026-12-02 (E)** (Nasdaq; EPS $2.41). (d) QUEUED. (e) conviction 2 (watch). GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2026-12-02)
- **29. SNOW - Snowflake.** (a) Bullish; Cortex AI monetisation; dilution carried ($3.5B convertible 09-28). (c) **2026-12-02 (E)** after hours (Nasdaq). (d) QUEUED. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2026-12-02)
- **30. OKTA - Okta.** (a) Bullish. (c) **2026-12-01 (E)** after hours (Nasdaq; EPS $0.43). (d) QUEUED. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2026-12-01)

### 31-40

- **31. INTU - Intuit.** (a) Bullish. (c) **2026-11-19 (E)** after hours (Nasdaq; EPS $2.47). (d) QUEUED. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2026-11-19)
- **32. NBIS - Nebius.** (a) Bullish; neocloud capacity. Counter: Nebius -15.2% on 11-05 (press, secondary), CoreWeave -12%, the policy rout hits neoclouds hardest; credit stress carried. (c) **2026-11-12 (E)** pre-market (Nasdaq; moved from 11-10; EPS -$0.61, 4 est.). (d) QUEUED. (e) conviction 1-2. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2026-11-12)
- **33. DIS - Disney.** (a) Bullish; SVOD margin. Nasdaq EPS $1.67 (9 est.), FMP $1.69. (c) **2026-11-17 (E)** pre-market (Nasdaq, FMP; a 1B.2 issuer notice was carried last week). (d) NEW; two open Strategy D lots. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2026-11-17)
- **34. MSFT - Microsoft.** (a) Bullish. 10-28 beat consumed; 530.61 (+1.7% week), one of few names up. No new document. (c) Ignite 2026-11-17..20 (E, third-party listing); next print 2027-01-27 (E, FMP). (d) QUEUED. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2026-11-17)
- **35. AMZN - Amazon.** (a) Bullish. AWS +39.3% (carried); 259.30 (+7.9% week, best of the large caps). Gap narrowed by the rally. (c) re:Invent 2026-11-30..12-04 (E); next print 2027-02-04 (E, FMP). (d) QUEUED; two open Strategy D lots. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2026-11-30)
- **36. SHOP - Shopify. NEW.** (a) Bullish. Printed 11-03 (D1: -8.7%); no release read. (c) Next **2027-02-10 (E)** (FMP). (d) NEW. (e) conviction 1-2. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2027-02-10)
- **37. JPM - JPMorganChase.** (a) Bullish. 10-13 print missed (EPS 5.75 vs 5.93; carried). (c) **2027-01-14 (E)** (FMP); Investor Day 2027-02-22 (carried). (d) QUEUED (the queue row's `spent_by_gate_likely` payload is stale). (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2027-01-14)
- **38. META - Meta Platforms.** (a) Bullish, reduced. Capex floor $135B+ and negative FCF (carried). (c) **2027-01-27 (E)** (FMP). (d) QUEUED. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2027-01-27)
- **39. GE - GE Aerospace.** (a) Bullish. Printed 10-20; fuel-shock exposure weakens as Brent falls (a mitigant for the counter-evidence). (c) **2027-01-21 (E)** (FMP). (d) NEW. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2027-01-21)
- **40. MRNA - Moderna. NEW.** (a) Bullish; NYT vaccine report (D1 10-09) carried as adverse. The Nasdaq/FMP 11-06 slot was not verified (Friday gap). (c) Next **2027-02-12 (E)** (FMP). (d) NEW. (e) conviction 1-2. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2027-02-12)

### 41-50

- **41. LLY - Eli Lilly.** (a) Bullish. Printed 10-29 (carried); print consumed. (c) Next **undated** (early February INFERRED; no Nasdaq/FMP row). (d) QUEUED. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst undated)
- **42. XOM - ExxonMobil.** (a) Bullish. Printed 10-30; the shock thesis is weaker with Brent near 99. (c) **2027-01-29 (E)** (FMP). (d) QUEUED. (e) conviction 1-2. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2027-01-29)
- **43. CVX - Chevron.** (a) Bullish. Same seam as XOM/COP. (c) **2027-01-29 (E)** (FMP). (d) QUEUED. (e) conviction 1-2. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2027-01-29)
- **44. INTC - Intel.** (a) Bullish. The 10-29 print (EPS 0.52 vs 0.4066, Q4 guide $15.0-16.0B) was followed by -28.6% (D1 e2dfa715), which triggered the 10-30 AI/semis liquidation; thesis is whether the guide or the market's read of it was the issue. (c) **2027-01-28 (E)** (FMP). (d) QUEUED. (e) conviction 1-2. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2027-01-28)
- **45. CAT - Caterpillar.** (a) Bullish. Printed 10-29 (-9.25% on an in-line beat; carried); FTC/USDA farm-equipment RFI overhang. (c) Next **undated**. (d) QUEUED. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst undated)
- **46. GEV - GE Vernova.** (a) Bullish. Printed 10-28; -7.48% on 11-05 (D1 XLI note) with the AI-power complex. (c) Next **undated**. (d) QUEUED; **open Strategy D lot**. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst undated)
- **47. NOW - ServiceNow.** (a) Bullish, **thesis contradicted by the print** (-26.95% on 10-28; carried); kept only for a possible post-crash gap; drop at next refresh if no one-time cause emerges. (c) Next **undated**. (d) QUEUED. (e) conviction **1**. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst undated)
- **48. SNDK - Sandisk. NEW.** (a) Bullish. FQ1 EPS $49.51 vs $46.19 (carried, 8-K via Daily); -13.5% on 10-29 per D1; QCOM's memory-constraint commentary is mildly supportive (secondary). (c) Next **undated**. (d) NEW. (e) conviction 1. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst undated)
- **49. RDDT - Reddit. NEW.** (a) Bullish. Q3 EPS $1.40 vs $1.31, revenue $895M (+53%; carried 8-K); -29.2% on 10-30 per D1. (c) Next **undated**. (d) NEW. (e) conviction 1. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst undated)
- **50. TGT - Target.** (a) **DIRECTION UNRESOLVED** (prior bearish thesis refuted; no replacement); ineligible for the top-10. (c) Earnings **2026-11-18 (C)** pre-market (corporate.target.com notice carried; Nasdaq EPS $2.04, 12 est.). (d) QUEUED. (e) conviction 1. GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2026-11-18)

### DIRECTION-INADMISSIBLE tier

Belong to Strategy B. The rail governs only admission to the actionable tier. None is in the top-10; none may be converted to an A `PENDING_ANALYSIS` row.

| # | Ticker | (a) Direction | (b) Documents / this week's re-test | (c) Catalyst | (d) Queue | (e) Tier / conviction | Gate literal |
|---|---|---|---|---|---|---|---|
| I-1 | **UAL** | Bearish, weaker | Fuel-shock channel; Brent 113.43 → 99.18, peace-talk and Gulf-export press (secondary) weakens, does not reverse | Printed 10-20; next **2027-01-19 (E)** (FMP) | Not queued | Inadmissible, 1-2 | GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2027-01-19) |
| I-2 | **AAL** | Bearish, weaker | Thinnest balance sheet; same fuel seam | Printed 10-22; next **2027-01-26 (E)** (FMP) | Not queued | Inadmissible, 1-2 | GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2027-01-26) |
| I-3 | **DAL** | Bearish, weaker | First airline to report; same seam | Printed 10-09; next **2027-01-13 (E)** (FMP) | Not queued | Inadmissible, 1-2 | GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2027-01-13) |
| I-4 | **CCL** | Bearish, weaker | Bunker-fuel channel | Earnings **2026-12-18 (E)** (FMP) | Not queued | Inadmissible, 1-2 | GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2026-12-18) |
| I-5 | **AMAT** | Bearish, **weaker/unresolved** | China WFE cliff contested (LRCX record quarter, memory strength); sector -11% on 11-05; no price read taken; D2 re-test before any thesis | Earnings **2026-11-12 (C)** after hours (issuer notice carried; Nasdaq EPS $4.06, 10 est.) | On queue | Inadmissible, 1-2 | GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2026-11-12) |
| I-6 | **WMT** | Bearish, thin | Low-income consumer; staples relative strength (XLP -0.75% on the 11-05 rout) is contrary; no new evidence | Earnings **2026-11-19 (C)** pre-market (Nasdaq EPS $0.64, 12 est.) | On queue | Inadmissible, 1 | GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2026-11-19) |
| I-7 | **ADBE** | Bearish, **stronger** | Software kept falling (DDOG -14.4%, NOW -26.95%) on AI-disruption and guide worries | Earnings **2026-12-09 (E)** (Nasdaq EPS $5.11); MAX 11-10..12 (E) | On queue | Inadmissible, 2 | GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2026-11-10) |
| I-8 | **HD** | Bearish / neutral | Housing turnover starved; no new evidence | Earnings **2026-11-17 (E)** pre-market (Nasdaq EPS $3.86, 11 est.) | On queue | Inadmissible, 1 | GATE: GATE-SURVIVING (gate 2026-11-08; catalyst 2026-11-17) |
| I-9 | **AKAM** | Bearish / contested | Smallest cap in the file; printed 11-05 (Nasdaq (C) after hours); result not read | Next print **undated** (no FMP/Nasdaq row; early/mid February INFERRED) | On queue | Inadmissible, 1 | GATE: GATE-SURVIVING (gate 2026-11-08; catalyst undated) |

**W4 side, restated because it binds:** no `DIRECTION-INADMISSIBLE` candidate may be converted into an A `PENDING_ANALYSIS` row; a vacated slot is filled from the next admissible candidate. AMAT, WMT, ADBE, HD, AKAM are already on the A queue; D2 applies the rail to any thesis run on them. TGT (direction-unresolved) is also ineligible for the top-10.

### Handoff notes for W4

- **TOP-10 (all admissible, long):** 1 VRTX, 2 FSLR, 3 NVDA, 4 TTWO, 5 AVGO, 6 CSCO, 7 CEG, 8 MU, 9 MRVL, 10 DELL. **QUEUED: nine** (VRTX, FSLR, NVDA, TTWO, AVGO, CSCO, MU, MRVL, DELL). **NEW: one** (CEG, not on the 46-row census; enqueue only if W4's limb reaches it). Zero direction-inadmissible names in the tier.
- **Tier changes vs 2026-W44:** COP 4 → 17 (thesis contradicted by Brent/Gulf-export evidence), ANET 5 → 12, AAPL 6 → 18, AMD 7 → 11 (prints consumed; their next prints are 2027 and undated for ANET), so the tier is refilled by dated post-gate catalysts: MU 35 → 8, MRVL 25 → 9, DELL 26 → 10, CEG 13 → 7, AVGO 9 → 5, CSCO 10 → 6, NVDA 8 → 3, TTWO 2 → 4, FSLR 3 → 2.
- **NEW (not on the census), admissible:** CEG, ETN, LRCX, PLTR, UBER, SHOP, DIS, MRNA, GE, SNDK, RDDT (11 of 50). Inadmissible and not queued: UAL, AAL, DAL, CCL.
- **Already QUEUED but outside the top-10:** AMD, ANET, QCOM, AAPL, GOOGL, ORCL, DDOG, HPE, NTAP, CRWD, PANW, CRM, SNOW, OKTA, INTU, NBIS, MSFT, AMZN, JPM, META, LLY, XOM, CVX, INTC, CAT, GEV, NOW, TGT, COP (29). Census members not ranked: IBM, MRK.
- **SPENT in the top-10: zero; SPENT overall: zero.** TTWO and CEG (11-09) survive by one session; the gate may move (a VIX-regime refresh is already in input (c)).
- **Stale queue-row payloads to overwrite:** JPM `spent_by_gate_likely`; MU row cites the consumed 09-30 print (live catalyst 2026-12-16 (E)); TTWO row date 11-09; HPE now 11-23; NBIS now 11-12; CSCO now 11-12 (C); NTAP 12-01; AVGO 12-10; CEG 11-09; COP, ANET, AAPL, AMD, QCOM, SMCI, DDOG rows cite consumed prints (live catalysts 2027, mostly (E)).
- **Cross-strategy overlap:** only Strategy D is open (AMZN, DIS, GEV, GOOGL, ISRG, RTX, TSM, UBER); no A or C position, so no A/C conflict. Candidates with open D lots: AMZN (#35), GOOGL (#19), GEV (#46), DIS (#33), UBER (#22).
- **Re-check next cycle:** whether the data-centre policy shock (state-level pauses/regulation) is a lasting demand change; TTWO/CEG prints (11-09), CSCO/NBIS/AMAT (11-12); NVDA 11-17; Cisco's cause for -10%; the INTC post-print guide read; Brent versus COP; Nasdaq/FMP next-print dates for ETN, QCOM, LRCX, DDOG, LLY, CAT, GEV, NOW, SNDK, RDDT, AKAM.

### REPORT IT — CATALYST-GATE MODE

- **Gate date: 2026-11-08.** Inputs: (a) next scheduled re-score 2026-12-01 (completed `M1a` = 1, `M1b` = 1 this month); (b) no open `regime-refresh` item; (c) REFRESH REQUEST returned `vix_regime_high` (trigger_run_start 2026-11-05) → D2a run 2026-11-08. A reads DO-NOT-ACTIVATE; mode live.
- **Counts:** 59 carried (50 ranked admissible incl. direction-unresolved TGT + 9 DIRECTION-INADMISSIBLE); **0 SPENT-BY-GATE, 59 GATE-SURVIVING.** Zero SPENT because every name whose only dated catalyst was a 11-02..11-06 print was re-dated to its next dated catalyst or left `undated` (fail-open); no candidate has a dated catalyst before 2026-11-08 without a later one.
- **Undated survivors (fail-open): 11** (ETN, QCOM, LRCX, DDOG, LLY, CAT, GEV, NOW, SNDK, RDDT, plus inadmissible AKAM). Next dates are late-January/early-February by pattern, INFERRED and unsourced; the WebSearch fallback was run for ANET, COP, ETN, SMCI and LRCX and dated only ANET (2027-02-10), COP (2027-02-10) and SMCI (2027-02-02) as (E) projections.
- **Re-dated from the printed-this-week set:** AAPL, PLTR, AMD, UBER, SHOP, MRNA (FMP, (E)); ANET, COP, SMCI (fallback, (E)); VRTX keeps PDUFA 2026-11-30 (C).
- **Narrowest survivors:** TTWO and CEG (2026-11-09); CSCO, AMAT (inadmissible), NBIS (2026-11-12); NVDA, DIS, HD (2026-11-17).
- **Research-cost:** top-10 rows carry full (a)-(e) with at least one document re-checked or newly cited this week; 11-50 tiers carry terse carry-forward (b) where evidence is unchanged.

## PART 2C — Strategy C ranked shortlist

### Router state, and what it admits

C reads **HYBRID ACTIVATE (FOMC-only)** (`state.current_regime` STRATEGY_ACTIVATION, MEASURED by the orchestrator this run; A, B, D, E all DO-NOT-ACTIVATE). Under it **only an FOMC-type event is router-admissible**; the corporate-earnings and FDA PDUFA classes are DNA. Earnings and PDUFA candidates below are ranked for the divergence record and for the day C is widened, and stay **router-PARKED, not to be enqueued**.

`state.open_queue` strategy C returns **one row** (orchestrator-MEASURED): `thesis-FOMC-C-20261130` (thesis-construction, ticker FOMC, pending, due **2026-11-30**), for the 2026-12-09 FOMC. **W4 must not create a duplicate FOMC row.** Its conservative default is "decline, no entry" unless an affirmative, sourced, quantified divergence is established; last permitted entry day is **Tuesday 2026-12-08** (criterion 5: entry at least 1 trading day before the event). Delta vs last week: no change in queue; the 12-09 meeting is now 31 days out (day 32 of the window counting 11-08 as day 1).

### The capital position (MEASURED 2026-11-08, read-only BigQuery)

Same sources as last week (`analytics.strategy_nav`, `state.nomadic_borrow_capacity_watch`, `events.cash_flows`):

| Field | Value |
|---|---|
| `analytics.strategy_nav` C: deposits / NAV / available_funds | **$18.55 / $18.55 / $18.55** |
| realized P&L, unrealized P&L, deployed_mv, dividends_held | $0 each |
| `sizing_base_2pct` | $0.37 |
| `state.nomadic_borrow_capacity_watch` C | donor_capacity_total 0, donor_count 0, `borrow_blocked` TRUE |
| `state.open_queue` strategy C | 1 row (`thesis-FOMC-C-20261130`) |
| Open C positions | none (open positions are Strategy D only) |

**Delta vs 2026-11-01: NAV and deposits $18.56 to $18.55 (-$0.01) with realized, unrealized and deployed all $0.** MEASURED and RECONCILED: `events.cash_flows` `373a1eef-2d54-452b-9067-acdf1bec8783` (flow_date 2026-11-04, WITHDRAWAL, -0.01, source `account_fee`) is C's pro-rata share (0.01 of nav_basis 18.56) of the 4.68 November month-start IBKR account fee that D2a recorded on 2026-11-04. Ledger expense, not trading P&L. (The earlier -0.92 external-withdrawal share, flow `6cc95cbc`, 2026-10-23, is already in last week's base.)

**Per-thesis no-ceiling sizing discipline (Rev 43/19):** no numeric ceiling, but max loss (including the cascade term) must not exceed the thesis's stated risk budget; a long debit structure's max loss equals its debit. With a whole portfolio of $18.55, no budget above $18.55 is fundable, so the test is whether the cheapest defined-risk structure debits at or below $18.55. Credit spreads, iron condors and butterflies need collateral of width less credit (at least ~$100 per 1-wide spread) and are unfundable; borrow is blocked. **Every candidate below is a deferral at current NAV.**

### Criterion 1 (a qualifying event within 45 days)

Window 2026-11-08 to 2026-12-23.

- **FOMC 2026-12-09 (C)** — `S/fomc.txt`, federalreserve.gov calendar fetched 2026-11-08 08:43Z: "December 8-9, 2026 * (SEP / Summary of Economic Projections meeting). Last 2026 meeting." Clear. (The 10-27/28 meeting page states no outcome text and minutes not yet released as of that fetch.)
- **Earnings (router-PARKED):** dates from the Nasdaq per-day calendar (`S/nasdaq/nasdaq_ge2b.csv`, 11-09 to 12-21; `time-after-hours` / `time-pre-market` = announced, `time-not-supplied` = projected, tagged (E)) with FMP consensus-detail cross-check for CSCO 11-12, NVDA 11-17, WMT 11-19, COST 12-10 (dates agree). Issuer-IR confirmation was NOT re-done this run for any earnings name.
- **PDUFAs (router-PARKED), carried from 2026-W44 PART 1B.3:** SMMT ivonescimab 11-14 (C), CAPR deramiocel 11-22 (C), VRTX povetacicept 11-30 (C), COGT bezuclastinib 11-30 (C). SMMT re-checked by one WebSearch this run: "November 14, 2026" is consistent across sources (Summit release, Yahoo/TradingView, OncoDaily), BLA accepted January 2026; no decision and no extension report found; survival-data adequacy is disputed between sources and an FDA statement on OS is unverified. Others not re-verified.
- **Passed since last week (struck):** AAPL, AMD, PLTR, VRTX (earnings) 11-02/03, UBER 11-04. MRVL is NOT a passed print: D1 entry `da7bf33a` (2026-11-02, -12.7%) records the Lumentum all-stock merger 8-K, not a quarterly report (the "merger+earnings" tag in the shared extract was a keyword heuristic). MRVL's FQ3 FY27 report is issuer-confirmed for **2026-12-01** (C) (PART 1B.2, Marvell IR notice 2026-11-06) and IS in the window; it was not measured or ranked here (orchestrator correction at assembly; INFERRED parked, earnings class DNA under FOMC-only). Outcomes of the struck prints were not researched here.

### The tenor rail — CLEAR, eighth cycle running

C requires structure expiration within 1-45 days of entry. MEASURED from the live SPY option parameters (IBKR underlying 756733): listed expiries are 11-09, 11-10, 11-11, 11-12, 11-13, 11-16, 11-17, 11-18, 11-19, 11-20 (regular, 2SPY), 11-23, 11-27, 11-30, 12-04, **12-11 (SPY, 2SPY)**, 12-18 (regular), **12-24 (new)**, 12-31, then monthlies into 2027.

- **FOMC 12-09:** 12-09 is the event day (statement 2 pm ET) and an expiry on it would not be strictly after the event; no 12-10 expiry lists. **First listed expiry strictly after the event remains 12-11** (2 calendar days after). From a 11-09 entry that is 32 days, from the last permitted entry day 12-08 it is 3 days — inside 1-45 either way. A 12-24 expiry (45 days from 11-09) is the outer edge of the rail.

### Criterion 2 (implied vs realized) — MEASURED on the spec window (trailing 30 days)

Headline is **IV/HV30** per `strategy/05_strategy_c.md` (the trailing 30 days); HV10 and HV20 are context only. Realized vol = annualized close-to-close, log returns, sample stdev x sqrt(252), from **IBKR regular-session daily bars** (`outside_rth` false), last close **Friday 2026-11-06**. HV30 = 30 returns over 31 closes (09-24 to 11-06 for SPY); HV20 = 21 closes; HV10 = 11 closes. Option quotes: IBKR snapshot, books as of the Friday 11-06 close (market closed; ts ~20:55Z). Implied move = ATM straddle mid / spot; realized-equivalent = 0.8 x HV30 x sqrt(T/365), T calendar days from 11-06 to expiry. "Contract IV" is IBKR's `implied_vol` where `is_valid` TRUE.

**FOMC instrument: SPY (as prior weeks).** SPY closed **735.29** on 11-06. Contract: SPY 2026-12-11 735 call 20.31/20.44 (last 19.90) and put 16.64/16.81 (last 16.84); straddle mid **$37.10** ($3,710 per straddle), spreads ~1% of the straddle (tight). **IBKR contract `implied_vol` returned `is_valid` FALSE on both legs** (and `option_midpoint_iv` invalid), so no valid contract IV exists this week; IV is therefore DERIVED from the measured straddle mid: 37.10 / (0.8 x 735.29 x sqrt(35/365)) = **20.4%** (INFERRED from MEASURED mids; SPY `implied_vol_underlying`, the 30-day constant-maturity measure, is valid at **18.97%**; IBKR broker `historical_vol` 12.41%, method undisclosed, context only).

| SPY window | Closes (returns) | Realized vol | IV/HV (derived straddle IV 20.4%) | IV/HV (30d underlying IV 18.97%) |
|---|---|---|---|---|
| **HV30 (spec)** | 31 (30) | **17.25%** | **1.18** | 1.10 |
| HV20 | 21 (20) | 20.22% | 1.01 | 0.94 |
| HV10 | 11 (10) | 27.30% | 0.75 | 0.69 |

Delta vs last week (10-30 basis): HV30 11.32 to **17.25**, headline ratio **1.41 to 1.18** (richness narrowed; the contract-IV basis changed from a valid quoted IV to a straddle-derived one, so the comparison is approximate). **Realized vol has overtaken implied at the short end** (HV10 27.3% vs IV 20.4%): SPY fell **-4.41% on Thursday 11-05** (766.81 to 733.00, 82.6M shares, the heaviest volume of the 64-bar span) after +1.65% on 11-04, closed 735.29 on 11-06 (+0.31%), and is -2.70% on five sessions (755.72 on 10-30). The 11-05 session was a broad risk-off day (see the panel: NVDA -9.3%, AMAT -13.6%, MU -17.5%, AVGO -10.4%, PANW -9.6%, CRWD -9.9%, CSCO -7.6%); its driver was NOT researched this run (the Friday/Thursday price half only, per brief), and D1's coverage runs through 11-05 only. INFERRED: the HV30 window now contains one outsized day, which lifts HV30 and HV20 materially; the ratios will fall further if realized stays elevated.

Implied move for the 12-11 expiry: straddle mid 5.05% of spot (35 days; not event-isolated, only 2 of 35 days follow the event) vs realized-equivalent 4.27%. Caveats. (1) The 12-11 expiry is mostly non-event time, so the ratio is NOT event-isolated. (2) Option `last` prices are after-hours prints and the spot used (735.29) is the regular-session close; SPY's last print was 736.53, so put-call parity is only approximate. (3) HV is close-to-close and excludes overnight gaps. (4) The 12-09 thesis is queued (`thesis-FOMC-C-20261130`) and D2 judges criterion 2 on 11-30; nothing here is a GO path.

**Cheapest defined-risk SPY structure for 12-09 — MEASURED this run:** 1-wide 12-11 call debit spread 735/736: buy 735 call at ask 20.44, sell 736 call at bid 19.65 = **$0.79 per share = $79 per spread** at the natural ($65 at mids; 736 call 19.65/19.80). The 734 put quote was empty (no book), so no put-spread price is claimed. Against NAV $18.55 the cheapest measured structure is a shortfall of **at least ~$46 at mids and $60 at the natural**. **Deferral stands.**

**Panel — ATM straddle on the first listed expiry spanning each event** (IBKR Friday 11-06 close book). All earnings rows are router-PARKED; pricing measurement only, not a divergence finding. "Spr" = bid/ask spread of the two legs as a share of the straddle mid (quote quality); where Spr is above ~40% the straddle mid is unreliable and IV (valid, IBKR-modelled) is the better guide.

| Name | Event (tag) | Expiry (T) | Spot | Strike | Straddle mid ($/contract) | Spr | Contract IV | HV30 / HV20 / HV10 | IV/HV30 | Implied move vs realized-equiv. |
|---|---|---|---|---|---|---|---|---|---|---|
| SPY | FOMC 12-09 (C) | 12-11 (35) | 735.29 | 735 | 37.10 ($3,710) | 1% | 20.4% (derived; contract IV invalid) | 17.3 / 20.2 / 27.3 | **1.18** | 5.05% vs 4.27% |
| CSCO | earnings 11-12 AMC (Nasdaq, FMP) | 11-13 (7) | 93.85 | 94 | 9.03 ($903) | 12% | 87.2% | 39.6 / 38.9 / 50.7 | **2.20** | 9.6% vs 4.4% |
| AMAT | earnings 11-12 AMC (Nasdaq) | 11-13 (7) | 332.71 | 332.5 | 36.35 ($3,635) | 4% | 98.5% | 69.2 / 77.7 / 98.2 | 1.42 | 10.9% vs 7.7% |
| NVDA | earnings 11-17 AMC (Nasdaq, FMP; issuer notice per last week's 1B.2) | 11-18 (12) | 186.64 | 187.5 | ~18.75 (call 8.00/14.00, put 2.75/12.75) | 85% | 72.9% | 41.9 / 47.8 / 60.6 | 1.74 | 10.6% (from IV) vs 6.1% |
| HD | earnings 11-17 pre (Nasdaq) | 11-20 (14) | 343.47 | 345 | 22.80 ($2,280) | 12% | 40.3% | 34.4 / 38.0 / 44.6 | 1.17 | 6.6% vs 5.4% |
| PANW | earnings 11-18 AMC (Nasdaq) | 11-20 (14) | 313.84 | 315 | 41.83 ($4,183) | 11% | 85.8% | 59.7 / 63.0 / 59.6 | 1.44 | 13.3% vs 9.4% |
| WMT | earnings 11-19 pre (Nasdaq, FMP; not IR-checked) | 11-20 (14) | 125.52 | 125 | 9.00 ($900) | 7% | 45.3% | 26.6 / 28.2 / 32.8 | **1.70** | 7.2% vs 4.2% |
| CRWD | earnings 12-01 AMC (Nasdaq) | 12-04 (28) | 216.90 | 215 | 35.12 ($3,512) | 23% | 75.7% | 58.9 / 64.6 / 59.1 | 1.28 | 16.2% vs 13.1% |
| CRM | earnings 12-02 (E, time not supplied) | 12-04 (28) | 213.65 | 215 | 24.95 ($2,495) | 17% | 53.6% | 34.9 / 37.5 / 32.7 | 1.54 | 11.7% vs 7.7% |
| ORCL | earnings 12-09 (E), same day as FOMC | 12-11 (35) | 116.10 | 116 | ~18.25 (call 6.85/11.85, put 6.40/11.40) | 55% | 63.1% | 70.9 / 79.8 / 97.2 | **0.89** | 15.6% (from IV) vs 17.6% |
| AVGO | earnings 12-10 (E) | 12-11 (35) | 293.69 | 295 | ~44.08 (call 17.05/27.00, put 17.05/27.05) | 45% | 60.0% | 51.6 / 56.2 / 73.3 | 1.16 | 14.9% (from IV) vs 12.8% |
| COST | earnings 12-10 (E; FMP agrees) | 12-11 (35) | 1,053.56 | 1055 | 67.22 ($6,722) | 14% | 24.6% | 20.5 / 23.8 / 28.0 | 1.20 | 6.4% vs 5.1% |
| MU | earnings 12-16 (E) | 12-18 (42) | 690.00 | 690 | ~138.88 (call 64.00/81.10, put 58.55/74.10) | 24% | 74.5% | 79.9 / 93.3 / 122.3 | **0.93** | 20.2% (from IV) vs 21.7% |

Reads. (1) Implied is rich to HV30 on the near-dated, announced earnings names — richest CSCO (2.20), NVDA (1.74), WMT (1.70) — but **implied is below HV30 on ORCL (0.89) and MU (0.93)**, the two names whose HV30 is inflated by 11-05 (-6.9%, -17.5%) and whose HV10 is 97% and 122%; for those two the market is pricing LESS vol than they have just realized. (2) Every ratio is measured against an HV30 that now contains the 11-05 shock, so the "richness" of the near-dated names is partly a window artefact (HV10 exceeds HV30 on 11 of 13 rows); these ratios describe pricing vs a recent realized baseline, not a statement that the market is wrong about direction. (3) Several IVs for 7-14 day expiries include non-event days; the implied-move columns are therefore upper bounds on the event-only move. (4) Quote quality is poor on NVDA, ORCL, AVGO, MU and CRWD (wide bid/ask on a closed book); trust IV over the straddle mid there. (5) Delta vs last week where the same name was measured: NVDA 1.64 to 1.74 (expiry 11-20 to 11-18), WMT 1.59 to 1.70, SPY 1.41 to 1.18.

### Ranked shortlist — 15 event candidates

Changes vs last cycle's 15: **struck as passed:** AAPL, AMD, PLTR, UBER, VRTX (earnings 11-02 to 11-04). **Carried:** FOMC 12-09, NVDA, WMT, SMMT PDUFA, VRTX PDUFA, CRM, AVGO, ORCL, MU. **Dropped:** ANET (printed 11-03). **Added:** CSCO, AMAT, HD, PANW, CRWD, COST. **Rank rule:** router admissibility first; then earnings candidates with a measured options market ahead of the unmeasured PDUFA binary events; then event proximity, market cap and measured IV/HV30; not edge. Direction in every row is the divergence between the options market and a no-event realized baseline (HV30-based); W1 does not establish a directional view, and primary documents (transcripts, 10-Q/10-K) were NOT read this run, so column (b) names only what exists and what was actually consulted.

**TOP-5**

**1. FOMC 2026-12-09 (C, SEP meeting) — the only router-admissible candidate** — (a) No directional divergence established by W1. Measurable divergence is volatility: SPY IV/HV30 **1.18** (straddle-derived; 1.10 on the 30-day underlying IV), narrower than 1.41 last week, with HV10 27.3% above implied 20.4% after the 11-05 -4.41% day; at the short end realized now exceeds implied. (b) federalreserve.gov calendar (fetched 2026-11-08); the SEP and statement are primary documents published on the day; October minutes not yet released as of the fetch. (c) **2026-12-09 (C).** First listed SPY expiry after it: 12-11. (d) **NOT executable at current capital: DEFERRAL** (NAV $18.55; cheapest measured structure is the $79 natural / $65 mid 735/736 call debit spread, shortfall at least ~$46; borrow blocked). (e) No open A positions (none); not an A-queue name. (f) **Top-5, rank 1.** **Disposition:** thesis row `thesis-FOMC-C-20261130` already queued (due 11-30); W4 must not duplicate it.

**2. CSCO — earnings 2026-11-12 after close** — (a) Implied rich: 9.6% implied vs 4.4% realized-equivalent (IV/HV30 **2.20**, the richest on the panel); HV10 50.7% after -7.6% on 11-05 and -1.95% on 11-06 (93.85, -10.2% over five sessions). (b) Nasdaq (after-hours, EPS consensus $1.15 from 8 estimates vs $0.81 a year ago) and FMP (EPS 1.32) agree on the date; Cisco IR and 10-Q not read this run. (c) 2026-11-12 AMC; expiry 11-13. (d) **Deferral** (straddle $903; cheapest single ATM leg ~$470; a 1-wide spread INFERRED well above $18.55). (e) CSCO is in the A-queue census; no open A (none). (f) Top-5. **Router-PARKED.**

**3. AMAT — earnings 2026-11-12 after close** — (a) Implied 10.9% vs 7.7% realized-equivalent (IV/HV30 1.42); realized already extreme (HV30 69%, HV10 98%; -13.6% on 11-05, +4.2% on 11-06). (b) Nasdaq (after-hours; EPS $4.06 from 10 estimates vs $2.17); issuer IR and filings not read. (c) 2026-11-12 AMC; expiry 11-13. (d) **Deferral** (straddle $3,635; single leg ~$1,850-1,885). (e) AMAT is in the A-queue census; no open A. (f) Top-5. **Router-PARKED.**

**4. NVDA — earnings 2026-11-17 after close** — (a) Implied ~10.6% (from IV 72.9%) vs 6.1% realized-equivalent (IV/HV30 1.74); stock -9.3% on 11-05 then +2.8% on 11-06 (186.64). Straddle book very wide (85% of mid), so only the IV is reliable. (b) Nasdaq (after-hours; EPS $2.49 from 13 estimates) and FMP (EPS 2.47) agree on 11-17; issuer notice per the PART 1B.2 check of last week (carried, not re-fetched). (c) 2026-11-17 AMC; expiry 11-18 (a daily/weekly listing). (d) **Deferral** (single ATM put ask 12.75, call ask 14.00; $1,275+). (e) NVDA is in the A-queue census; no open A. (f) Top-5. **Router-PARKED.**

**5. HD — earnings 2026-11-17 pre-market** — (a) Implied 6.6% vs 5.4% realized-equivalent (IV/HV30 **1.17**, the leanest earnings ratio on the panel); HV30 34% reflects a +6.5% move on 11-04 (355.44) and -1.85% on 11-06 (343.47). (b) Nasdaq (pre-market; EPS $3.86 from 11 estimates vs $3.74); Home Depot IR not read. (c) 2026-11-17 pre-market; first listed monthly expiry 11-20 (no 11-18/19 listing for HD). (d) **Deferral** (straddle $2,280; single leg ~$1,185-1,235). (e) HD is in the A-queue census; no open A. (f) Top-5. **Router-PARKED.**

**REST (6-15)** — all **router-PARKED**; all deferrals at C NAV $18.55 (single ATM leg asks of $430 or more; 1-wide spreads on $1-strike names INFERRED to debit tens of dollars, above NAV).

| # | Candidate | (a) Direction of divergence | (c) Date (tag) | (d) Executability at C $18.55 | (e) A overlap / A-queue | IV/HV30 |
|---|---|---|---|---|---|---|
| 6 | **SMMT** PDUFA ivonescimab + chemo BLA / EGFRm NSCLC | Binary regulatory outcome; sources disagree on survival-data strength (OS trend, not significant); no extension or decision found | 2026-11-14 (C; WebSearch 2026-11-08, Saturday date, action may land earlier) | Deferral (chain not measured; stock fell -12.2% on 11-04 earnings per D1 `f5359185`) | not in A-queue; none open | not measured |
| 7 | **PANW** earnings | Implied rich: 13.3% vs 9.4%; stock -9.6% on 11-05, -14.2% over five sessions | 2026-11-18 AMC (Nasdaq; EPS $0.52, 15 estimates) | Deferral (straddle $4,183; single leg ~$2,160) | PANW in A-queue; no open A | 1.44 |
| 8 | **WMT** earnings | Implied rich: 7.2% vs 4.2% | 2026-11-19 pre-market (Nasdaq, FMP; not IR-checked) | Deferral (straddle $900; single leg ~$430-500) | WMT in A-queue; no open A | **1.70** |
| 9 | **VRTX** PDUFA povetacicept / IgAN | Binary regulatory outcome (accelerated approval) | 2026-11-30 (C, carried; Vertex release 2026-06-01; not re-verified) | Deferral (chain not measured) | VRTX in A-queue; no open A | not measured |
| 10 | **CRWD** earnings | Implied modestly rich: 16.2% vs 13.1% | 2026-12-01 AMC (Nasdaq; consensus EPS shown as $0 with 13 estimates, unreliable) | Deferral (straddle $3,512; single leg ~$1,890) | CRWD in A-queue; no open A | 1.28 |
| 11 | **CRM** earnings | Implied rich: 11.7% vs 7.7% | 2026-12-02 (E, time not supplied; carried) | Deferral (straddle $2,495; single leg ~$1,330) | CRM in A-queue; no open A | 1.54 |
| 12 | **ORCL** earnings | Implied LEAN: IV 63% below HV30 71% (HV10 97%); 15.6% vs 17.6% | 2026-12-09 (E), **same day as the FOMC (confounded)** | Deferral (book 55% wide; single leg ~$1,140) | ORCL in A-queue; no open A | **0.89** |
| 13 | **AVGO** earnings | Implied modestly rich: 14.9% vs 12.8%; falls the day after the FOMC | 2026-12-10 (E) | Deferral (book 45% wide; single leg ~$2,700) | AVGO in A-queue; no open A | 1.16 |
| 14 | **COST** earnings | Implied modestly rich: 6.4% vs 5.1%; calmest HV30 (20.5%) on the panel | 2026-12-10 (E; FMP agrees; EPS $4.87, 10 estimates) | Deferral (straddle $6,722; single leg ~$3,100-3,265) | COST not in the A-queue census; none open | 1.20 |
| 15 | **MU** earnings | Implied LEAN: IV 74.5% below HV30 79.9% (HV10 122%); 20.2% vs 21.7%; stock -17.5% on 11-05, +5.1% on 11-06 | 2026-12-16 (E), last week of the window; expiry 12-18 | Deferral (book 24% wide; single leg ~$6,400-7,400) | MU in A-queue; no open A | **0.93** |

Also in window but not ranked (still in PART 1B): KKR/CEG 11-09, TDG 11-10, DIS 11-17, TJX/LOW/TGT 11-18, INTU 11-19, DELL/ADI/MDT/ADSK/WDAY 11-24, DE 11-25, AZO 12-08, ADBE/SNPS 12-09 (E), ACN/NKE/CTAS 12-17 (E); PDUFAs CAPR 11-22 (C), COGT 11-30 (C), SVRA 11-22 (E), BBIO 11-27 (E), CYTK 11-14 (E, unverified).

**(e) A-vs-C exclusivity is vacuous this cycle.** `state.current_positions` holds Strategy D only (AMZN, DIS, GEV, GOOGL, ISRG, RTX, TSM, UBER); zero open A or C rows (orchestrator-MEASURED). A-queue membership above is from the run context's 46-name census (CSCO, AMAT, NVDA, HD, PANW, WMT, VRTX, CRWD, CRM, ORCL, AVGO, MU are members; SMMT, COST are not).

**Price half of Friday 2026-11-06 (IBKR regular-session daily bars, MEASURED).** SPY 735.29 (+0.31%; Thu 11-05 -4.41%), CSCO 93.85 (-1.95%), AMAT 332.71 (+4.22%), NVDA 186.64 (+2.78%), HD 343.47 (-1.85%), PANW 313.84 (-0.26%), WMT 125.52 (-1.72%), CRWD 216.90 (-0.14%), CRM 213.65 (-3.94%), ORCL 116.10 (+0.82%), AVGO 293.69 (+0.74%), COST 1,053.56 (-1.13%), MU 690.00 (+5.12%). Not measured (no bars pulled): SMMT, VRTX (the two PDUFA names; both carried unmeasured).

**Shortlists only.** Full thesis construction per Strategy.md happens in sessions W4 schedules. Nothing here authorizes an enqueue for any parked name. **Measurement coverage:** IV/HV30 measured for **13 names** (SPY plus CSCO, AMAT, NVDA, HD, PANW, WMT, CRWD, CRM, ORCL, AVGO, COST, MU), including all top-5; unmeasured: SMMT and VRTX PDUFAs (binary, no earnings-style straddle). MEASURED = IBKR bars/snapshots and BigQuery reads; INFERRED = straddle-derived SPY IV, "implied move from IV" where the book was too wide, single-leg and spread cost estimates for names other than SPY, and every statement about why 11-05 happened (not researched). Metered calls this run: 1 (one Anthropic WebSearch on the SMMT PDUFA); `calls_2C.jsonl` holds that one row.

## Coverage, provenance and what this cycle changed

**Read scope.** Weekly cadence. MEASURED vs INFERRED is labelled wherever it matters.
- **BigQuery (read-only):** `state.trading_day_today`, `state.current_regime`, `state.current_positions`, `state.open_queue`, `state.open_queue_detail`, `state.market_calendar`, `state.routine_catchup_window`, `state.nomadic_borrow_capacity_watch`, `analytics.strategy_nav`, `events.cash_flows`, `events.decision_log`, `events.queue_events`, `ops.run_log`, `ops.alerts`, `ops.web_calls` (schema/prior-run token check).
- **Repo:** `strategy/03_strategy_a.md`, `strategy/05_strategy_c.md`, `strategy/01_shared_regime_vocabulary.md`, the Claude_Task_Plan.md W1 section and shared rules, `Daily.md` (first line 2026-11-05, D1 scan through 2026-11-05T22:42:50Z) and the prior `Weekly_Catalyst_Calendar.md` (2026-W44).
- **Live sources:** FMP `calendar/earnings-calendar` (4 chunked calls ≤ 60 days, one shared pull); the Nasdaq key-less earnings calendar (38 per-day fetches, every weekday 2026-11-02 → 2026-12-23, one shared pull, unmetered); federalreserve.gov FOMC calendar (one shared curl fetch, unmetered); IBKR daily bars, option parameters, option data and snapshots (free); Anthropic `web_search` (95) / `web_fetch` (8) — issuer IR/press releases, FDA/sponsor releases, BLS/BEA schedules; Tavily basic search (6 calls, 6 credits). 113 `ops.web_calls` rows in total.

**Orchestration.** A Sonnet sub-agent ran the single shared FMP pull (4 chunks) plus the Fed-calendar fetch and the D1-record export; the orchestrator ran the Nasdaq pull. Four Sonnet sub-agents then did the grunt work from those shared files, none re-fetching them: (1) the header and PART 1A, (2) PART 1B (FOMC, IR-confirmed earnings, PDUFA under the FDA-limb rule, macro), (3) PART 2A, (4) PART 2C including the Strategy C IV/HV30 measurements. The orchestrator did itself: every gate-input BigQuery read (STEP 1 arithmetic and the A-queue census), assembly, and cross-part reconciliation. **Corrections made at assembly (orchestrator):** MRVL — PART 2C had struck MRVL as "printed 11-02" from a keyword-heuristic label on D1 entry `da7bf33a`; that record is the Lumentum merger 8-K, and Marvell's own IR notice (2026-11-06) schedules FQ3 FY27 results for **2026-12-01 (C)**, so MRVL is reinstated as in-window and PART 2A's MRVL row was corrected to (C) with the "plus Q3 results" wording removed. TTWO (11-09) and DELL (11-24) in PART 2A were re-tagged (C) to agree with PART 1B.2's issuer sources. All 59 PART 2A GATE literals were checked for format and against the gate date (59 GATE-SURVIVING, 0 SPENT-BY-GATE). HD's 11-17 date is (C) in PART 1A (IR page fetched) and (E) in PART 1B.2 (not re-read there); the IR page governs.

**Catch-up window.** `state.routine_catchup_window` gives `window_days` **7.03** against a weekly 1.5× threshold of 10.5: cadence-normal, no `CATCHUP` token owed.

**The daily-to-weekly boundary, honoured.** Catalysts newly announced 11-02..11-05 were reused from D1's 15 decision-log records since the last W1 completion (9 `research-screen`, 5 `add-candidate-review`, 1 `ops-note`), not re-searched: the MRVL–LITE all-stock merger (11-02), the 11-05 AI/semis rout (SPY −4.41%) and its midterm-sweep attribution, NRIX/Sanofi program discontinuation, CVI's refinery-asset acquisition, DRVN's Item 4.02 non-reliance, and the week's earnings reactions. The 10-30 chip selloff W44 could not explain is now attributed by D1 entry `0b27dc01` to INTC's 10-29 print. No second broad news scan was run; web effort went to forward-date confirmation and per-candidate documents.

**The FRIDAY-SESSION GAP, closed from IBKR.** D1 has not yet covered Friday 2026-11-06 (structural, by trigger ordering, not a D1 outage). The price half was closed at zero cost from IBKR regular-session bars for the PART 2A priority names and the PART 2C panel (SPY 735.29, +0.31% on the day, −2.7% on the week). The narrative half is D1's to record on its next fire and is not chased.

**CATALYST-GATE MODE.** Gate date **2026-11-08** = earliest of (a) 2026-12-01 (completed `M1a` = 1, `M1b` = 1 this month, both 2026-11-01), (b) no open `regime-refresh` item, (c) REFRESH REQUEST returned `vix_regime_high` (trigger_run_start 2026-11-05, logged 2026-11-05 23:19:56 UTC, after D2a's 11-05 run) → D2a run 2026-11-08. Counts: 0 SPENT-BY-GATE, 59 GATE-SURVIVING; full (a)-(e) on every candidate.

**Standing constraints NOT re-alerted:** the FMP earnings-horizon plan cap (`FMP-earn-horizon`; terminal 2026-12-18 unchanged for a sixth week); the FMP 90-day span clamp (chunking applied, all chunks ≤ 60 days); the bulk-enumeration plan gate (`6c4004e3`); C's blocked nomadic borrow; the Friday boundary gap (`b4e4e563`).

**Open W1 referrals re-checked.** `ops.alerts` holds no unresolved row sourced from or naming W1 (MEASURED 2026-11-08); no referral status line is carried.

**Known residual gaps (carried in the rows):** INO-3107 (PDUFA 10-30) outcome still unresolved; AGIO mitapivat goal date reported extended to 2027-02-01 (trade press citing Agios; out of window); neladalkib sponsor conflict (Nuvalent per a Pharmacy Times listing vs GSK per W44) unresolved; CYTK, CORT, VNDA PDUFA rows recorded unresolved (no sponsor/FDA source); CAPR 11-22 carried from W44's 8-K, not re-read; US–China truce extension to 2027-01-10 still uncorroborated (Busan suspensions lapse ~11-10); the UNP·NSC rows may be superseded by the STB's 2026-08-18 schedule and the WBD antitrust row is likely moot after the 10-06 delisting — both carried, flagged for re-verification next cycle; the Anthropic S-1 is still not EDGAR-verified (T); issuer notices still not found for CEG, AVGO, HPE (Nasdaq moved 12-03 → 11-23), CRM, ORCL, ADBE, COST, MU (all (E)); 11 PART 2A survivors are undated; MRNA's 11-06 and AKAM's 11-05 prints are unverified because of the Friday gap; FMP lists FDX twice (2027-02-02 and 2027-03-25) and BABA disagrees FMP 11-19 vs Nasdaq 11-24; Nasdaq shows CRWD's EPS consensus as $0 (13 estimates), not credible; SPY ATM contract IV was invalid on both legs, so the 20.4% straddle-derived IV (IV/HV30 1.18) is INFERRED and the 30-day underlying IV gives 1.10. Several PART 2A print figures are secondary press. Sub-agent `ops.web_calls` timestamps are batch-approximate (stamped when each batch was logged).

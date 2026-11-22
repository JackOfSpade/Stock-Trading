2026-W47

# Weekly Catalyst Calendar — Strategies A and C

**Run date 2026-11-22** (Sunday, `weekly_sun`), ISO week 2026-W47. The upcoming trading week opens Monday 2026-11-23 (context, not the marker). Metered web calls this part: 7 Parallel calls (6 web_search + 1 web_fetch), one `ops.web_calls` row each; no SEARCH GUARD event (no error, 429/quota text or zero-result pair). No FMP or IBKR call was made by this part; FMP and Nasdaq data are the orchestrator's shared pulls of 2026-11-22.

**Windows.** Strategy A: 6 months, **2026-11-22 → 2027-05-22** — **effective confirmed-earnings horizon 2026-12-18 (26 days, ~3.7 weeks); sparse vendor coverage beyond it, per-name (E) fallback for A-queue names without a forward date.** Strategy C: 45 days, **2026-11-22 → 2027-01-06** (run date + 45 days, same convention as W46's 11-15 → 12-30; the 12-09 FOMC decision sits on day 17 counting 11-22 as day 0; the 12-30 FOMC minutes sit on day 38).

**EFFECTIVE CONFIRMED-EARNINGS HORIZON: 2026-12-18, 26 days (~3.7 weeks) from 2026-11-22. The terminal date did NOT move for an eighth week** (MEASURED: FMP chunk 1, 2026-11-22 → 2027-01-20, returned 18 rows; the contiguous near-term block ends at CCL 2026-12-18, then nothing until TLRY 2027-01-11; the 10 rows 01-11 → 01-20 are the first of the post-gap block, not part of the series). Depth fell 33 → 26 days only because the clock advanced. Twelve-week series, terminal date / days from that week's run date: 2026-12-03/88d (09-06), 2026-12-09/87d (09-13), 2026-12-09/80d (09-20), 2026-12-10/74d (09-27), 2026-12-18/75d (10-04), 2026-12-18/68d (10-11), 2026-12-18/61d (10-18), 2026-12-18/54d (10-25), 2026-12-18/47d (11-01), 2026-12-18/40d (11-08), 2026-12-18/33d (11-15), **2026-12-18/26d (11-22)**. Dead zone 2026-12-19 → 2027-01-10 (no FMP row). The 2027 block (70 rows 2027-01-11 → 2027-04-30, 61 of them 01-11 → 02-21) is the January/February mega-cap season as a sparse top-name sample and is NOT part of the series. Standing plan-tier constraint (`FMP-earn-horizon`, `OWNER_ACTIONS.md`), deliberately NOT re-alerted; all FMP pulls chunked ≤ 60 days (4 chunks, 78 rows, no errors).

**Nasdaq key-less per-day calendar** (shared CSVs, FRESH pull 2026-11-22 19:25-19:27Z, every weekday 2026-11-16 → 2027-01-08; W46's cached-page staleness caveat does not apply to this pull): **905 rows at all market caps; 242 rows at market cap ≥ $2B** (39 ≥ $50B overall); last ≥ $2B date 2027-01-06 (10 rows). **82 of the 242 fall in the week just printed 11-16 → 11-20** (11-16 15, 11-17 18, 11-18 19, 11-19 23, 11-20 7; 13 are ≥ $50B; all 82 carry `time-not-supplied`, the post-print signature) and **160 are forward 2026-11-23 → 2027-01-06** (148 dated 11-23 → 12-30; 26 are ≥ $50B). Of the 160 forward rows: **51 `time-not-supplied`** (projected (E) signature), 54 BMO, 55 AMC. Forward per-day counts at ≥ $2B: 11-23 11, 11-24 24, 11-25 5, 11-27 1, 11-30 1, 12-01 14, 12-02 15, 12-03 23, 12-07 1, 12-08 14, 12-09 6, 12-10 7, 12-14 1, 12-15 4, 12-16 4, 12-17 11, 12-18 5, 12-21 1, 01-05 2, 01-06 10. All-cap rows exist but none ≥ $2B on 11-26 (17), 12-04 (4), 12-11 (8), 12-22 (8), 12-24 (1), 12-28 (5), 12-29 (1), 12-30 (4), 01-04 (7), 01-08 (2); 2027-01-07 has zero rows; 12-23 and 12-25 are absent. So the C window's last 10 days contain only 01-05 (2) and 01-06 (10, STZ ≥ $10B) at ≥ $2B. Δ vs W46: forward ≥ $2B rows 224 → 160 (window rolled; 11-16 → 11-20 rows printed; adds 01-05/01-06 rows); time-not-supplied forward 136 of 224 → 51 of 160 (fresh pull carries BMO/AMC for more names).

**FMP coverage shape** (MEASURED, four chunked `calendar/earnings-calendar` calls by the orchestrator 2026-11-22 ~19:27Z; 78 rows, 76 distinct symbols; counts parsed from the shared file):

| Span | Rows | Notes |
|---|---|---|
| 11-22 → 11-30 | 2 | ZM 11-23; BILI 11-24 |
| 12-01 → 12-18 | 6 | NIO 12-01; DOCU 12-03; ADBE 12-09; COST 12-10; NKE 12-17; CCL 12-18 (terminal row) |
| 12-19 → 2027-01-10 | 0 | dead zone (plan-tier constraint, not alerted) |
| 2027-01-11 → 02-21 | 61 | TLRY 01-11 … ETSY/WMT 02-18; ISO weeks 2027-W02 6, W03 6, W04 18, W05 19, W06 10, W07 2 |
| 2027-02-22 → 05-22 | 9 | LCID 02-23, NVDA 02-24, BIDU 02-25, RKT 02-25, RIOT 03-01, TGT 03-02, BABA 03-18, FDX 03-25, FUBO 04-30 (chunk 3 = FDX, FUBO; chunk 4 (05-21 → 05-22) 0 rows) |

FMP lists FDX (2027-02-02 and 03-25) and FUBO (2027-02-02 and 04-30) twice: internal vendor inconsistency, neither date relied on. Δ vs W46's FMP list: **no date changed** for any symbol present in both; newly present (post-print projections for names that printed 11-16 → 11-19): DIS 02-01, WMT 02-18, NVDA 02-24, BIDU 02-25, TGT 03-02, BABA 03-18, FUBO 02-02/04-30; none dropped (BIDU, DIS, NVDA, TGT, BABA, WMT, FUBO left the near-term block because they printed).

**Cross-check FMP vs Nasdaq (inside 11-23 → 01-06):** FMP has 8 in-window rows (ZM, BILI, NIO, DOCU, ADBE, COST, NKE, CCL); all 8 are on the Nasdaq ≥ $2B forward list and **all 8 agree on the date (8 agreements, 0 disagreements)**; no FMP-only in-window symbol. Nasdaq ≥ $2B forward names not in FMP: 152 of 160 (FMP is a sparse mega-cap subset, not an enumeration). FMP rows beyond 01-06 (70 rows) are outside the Nasdaq pull by construction. Prior-week W46 disagreement BABA (FMP 11-19 vs Nasdaq 11-24) is closed (issuer 11-19; Nasdaq now 11-19). **Issuer-vs-Nasdaq disagreement found this run:** MU, Nasdaq 12-16 (n/s) vs issuer 12-17 (Micron release 2026-11-19) — issuer governs. W46's two other conflicts moved toward the issuer on Nasdaq itself: AVGO (Nasdaq 12-10 -> 12-09, issuer 12-09) and ORCL (Nasdaq 12-09 -> 12-14, Oracle IR FAQ 12-14).

**A-queue (47) census vs Nasdaq** (pinned census, orchestrator-supplied 47 names, unchanged from W46): **12 have a forward Nasdaq date inside 11-23 → 01-06** (HPE 11-23, DELL 11-24, CRWD/MRVL/NTAP/OKTA 12-01, CRM/SNOW 12-02, AVGO/ADBE 12-09, ORCL 12-14, MU 12-16 on Nasdaq / 12-17 issuer); **6 printed 11-16 → 11-20** (NVDA, HD 11-17; PANW, TGT 11-18; WMT, INTU 11-19); **29 have none** (AAPL, AKAM, AMAT, AMD, AMZN, ANET, CAT, CEG, COP, CSCO, CVX, DDOG, FSLR, GEV, GOOGL, IBM, INTC, JPM, LLY, META, MRK, MSFT, NBIS, NOW, QCOM, SMCI, TTWO, VRTX, XOM; includes the 5 that printed 11-09 → 11-13 (CEG, TTWO, CSCO, AMAT, NBIS) and 24 with no date in either pull). 12 + 6 + 29 = 47. **All 12 forward A-queue names now carry an issuer date** ((C): HPE, DELL, CRWD, MRVL, NTAP, OKTA, CRM, SNOW, AVGO, ADBE, MU; ORCL (C) on the Oracle IR FAQ page without a dated release); W46 had 16 of 18 confirmed. Δ vs W46: ORCL conflict narrowed (Nasdaq now agrees with the issuer FAQ), MU upgraded (E) -> (C) with a date correction 12-16 -> 12-17, PANW/NVDA/HD/TGT/WMT/INTU moved to "printed".

**FLOOR + plan-tier gate (standing constraints, stated, NOT re-alerted).** Every count in PART 1 beyond the 12-18 horizon is a FLOOR: the FMP earnings horizon is plan-capped (~13 weeks nominal, dense coverage ends 12-18) and sparse inside it (`FMP-earn-horizon`, `ops.alerts` 37a4de80); the 90-day clamp is handled by ≤ 60-day chunks; and the plan tier separately denies bulk enumeration (`search/search-company-screener`, every `directory.*` route and `quote/batch-quote` ACCESS DENIED, `ops.alerts` 6c4004e3), so a bulk FMP pull cannot build the market-cap/ADV universe rail either. The market-cap rail inside the C window is Nasdaq's own `marketCap` field; the 30-day ADV ≥ $10M rail is carried, not re-measured (1A.11).

## PART 1A — Strategy A universe, 6-month window (2026-11-22 → 2027-05-22)

No interpretation in this PART. Provenance tags:
- **(C)** company- or primary-source confirmed (**(C-secondary)** = issuer notice seen only through a copy, aggregator quoting a filing, or a search snippet)
- **(E)** estimated (vendor or aggregator projection)
- **(T)** tentative, no firm day

"Δ" marks a change against the 2026-11-15 (2026-W46) artifact. Rows tagged (C) 'carried' were issuer-confirmed in W46 (or earlier) and the Nasdaq date still matches; they were NOT re-read this run unless the source cell says "this run". Metered calls this part: 6 web_search + 1 web_fetch (Parallel).

### 1A.1 — Earnings, inside the 45-day C window (2026-11-23 → 2027-01-06)

**Enumeration.** Nasdaq key-less per-day calendar, market cap ≥ $2B: 160 forward rows (2026-11-23 → 2027-01-06); 26 are ≥ $50B. **Restriction stated:** the detail table lists every forward row with market cap ≥ $10B (80 rows) — which includes all 12 forward A-queue names and every name W46 carried as issuer-confirmed in the window — and the 80 forward rows between $2B and $10B are enumerated by session below. Time codes: BMO before open, AMC after close, n/s not supplied. Mcap = Nasdaq `marketCap` field as fetched. D marks held Strategy D positions: not available to this part (none marked). Rows without an explicit source are Nasdaq-only and (E). Δ column text flags date moves versus W46's table (W46 pull was partly cached; moves are Nasdaq schedule changes or cache refreshes, not issuer-confirmed unless the source cell says so).

| Ticker | Name | Type | Date | Tag | Mcap | Source / consensus |
|---|---|---|---|---|---|---|
| HPE | Hewlett Packard Enterprise Company [A-queue] | Earnings (AMC, FQ Oct/2026) | 2026-11-23 | (C) | $60B | HPE release 2026-11-02 (hpe.com newsroom, carried W46): call Mon 11-23 4:00 pm CT / 5:00 pm ET; Nasdaq agrees |
| A | Agilent Technologies, Inc. | Earnings (AMC, FQ Oct/2026) | 2026-11-23 | (E) | $49B | Nasdaq calendar |
| TCOM | Trip.com Group Limited | Earnings (n/s, FQ Sep/2026) | 2026-11-23 | (E) | $27B | **Δ Nasdaq 11-16 (W46) -> 11-23** |
| ZM | Zoom Communications, Inc. | Earnings (AMC, FQ Oct/2026) | 2026-11-23 | (E) | $24B | Nasdaq 11-23 AMC; FMP 11-23 agrees (EPS est 1.49) |
| SYM | Symbotic Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-23 | (E) | $20B | Nasdaq calendar |
| J | Jacobs Solutions Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-23 | (E) | $18B | Nasdaq calendar |
| DELL | Dell Technologies Inc. [A-queue] | Earnings (AMC, FQ Oct/2026) | 2026-11-24 | (C) | $199B | Dell release 2026-11-10 (investors.delltechnologies.com, carried W46): call Tue 11-24 3:30 pm CST; Nasdaq agrees |
| ADI | Analog Devices, Inc. | Earnings (BMO, FQ Oct/2026) | 2026-11-24 | (C) | $183B | investor.analog.com events page, call 11-24 10:00 am ET (carried W46; one vendor says after close, timing only) |
| BHP | BHP Group Limited | Earnings (n/s, FQ Sep/2026) | 2026-11-24 | (E) | $176B | **Δ Nasdaq 11-17 (W46) -> 11-24**; foreign private issuer, no issuer notice seen |
| MDT | Medtronic plc | Earnings (BMO, FQ Oct/2026) | 2026-11-24 | (C) | $129B | Medtronic release 2026-11-04 (news.medtronic.com, carried W46): results Tue 11-24; **Δ back on the Nasdaq pull** (absent in W46) |
| ADSK | Autodesk, Inc. | Earnings (AMC, FQ Oct/2026) | 2026-11-24 | (C) | $51B | Autodesk release 2026-11-02 (adsknews.autodesk.com, carried W46): Tue 11-24, call 2:00 pm PT |
| WDAY | Workday, Inc. | Earnings (AMC, FQ Oct/2026) | 2026-11-24 | (C) | $42B | Workday release (carried W46, relay site) |
| DLTR | Dollar Tree, Inc. | Earnings (BMO, FQ Oct/2026) | 2026-11-24 | (E) | $26B | Nasdaq calendar; **Δ Nasdaq 12-02 (W46) -> 11-24** |
| HPQ | HP Inc. | Earnings (AMC, FQ Oct/2026) | 2026-11-24 | (E) | $25B | Nasdaq calendar |
| BBY | Best Buy Co., Inc. | Earnings (BMO, FQ Oct/2026) | 2026-11-24 | (E) | $21B | Nasdaq calendar |
| NTNX | Nutanix, Inc. | Earnings (AMC, FQ Oct/2026) | 2026-11-24 | (E) | $16B | Nasdaq calendar |
| BURL | Burlington Stores, Inc. | Earnings (BMO, FQ Oct/2026) | 2026-11-24 | (E) | $15B | Nasdaq calendar |
| SJM | The J.M. Smucker Company | Earnings (BMO, FQ Oct/2026) | 2026-11-24 | (E) | $14B | Nasdaq calendar |
| DKS | Dick's Sporting Goods Inc | Earnings (BMO, FQ Oct/2026) | 2026-11-24 | (E) | $12B | Nasdaq calendar |
| DE | Deere & Company | Earnings (BMO, FQ Oct/2026) | 2026-11-25 | (C) | $168B | Deere release 2026-11-11 (deere.com, carried W46): call Wed 11-25 9 a.m. CT |
| LI | Li Auto Inc. | Earnings (BMO, FQ Sep/2026) | 2026-11-25 | (E) | $11B | Nasdaq calendar |
| RBRK | Rubrik, Inc. | Earnings (AMC, FQ Oct/2026) | 2026-11-30 | (E) | $24B | Nasdaq calendar; **Δ Nasdaq 12-03 (W46) -> 11-30** |
| CRWD | CrowdStrike Holdings, Inc. [A-queue] | Earnings (AMC, FQ Oct/2026) | 2026-12-01 | (C) | $249B | CrowdStrike release 2026-11-04 (ir.crowdstrike.com, carried W46): after close Tue 12-01, call 2:00 pm PT |
| MRVL | Marvell Technology, Inc. [A-queue] | Earnings (AMC, FQ Oct/2026) | 2026-12-01 | (C) | $121B | Marvell IR release 2026-11-06 (carried W46): Tue 12-01, call 1:30 pm PT. Merger with LITE: see 1A.7 |
| OKTA | Okta, Inc. [A-queue] | Earnings (AMC, FQ Oct/2026) | 2026-12-01 | (C) | $36B | Okta release 2026-11-02 (carried W46): after close 12-01, call 2:00 pm PT |
| NTAP | NetApp, Inc. [A-queue] | Earnings (AMC, FQ Oct/2026) | 2026-12-01 | (C) | $33B | NetApp release 2026-11-10 (carried W46): after close Tue 12-01, webcast 2:30 pm PT |
| CPRT | Copart, Inc. | Earnings (BMO, FQ Oct/2026) | 2026-12-01 | (E) | $29B | Nasdaq calendar; **Δ Nasdaq 11-19 (W46) -> 12-01** |
| MDB | MongoDB, Inc. | Earnings (AMC, FQ Oct/2026) | 2026-12-01 | (C) | $24B | **Δ NEW (C), Nasdaq row returns (absent in W46):** MongoDB release 2026-11-05 (investors.mongodb.com, web_search this run): after close Tue 12-01, call 5:00 pm ET; IR events page agrees. Resolves W46 "(C-secondary), Nasdaq row missing"; scrutar 11-30 estimate superseded |
| CRDO | Credo Technology Group Holding Ltd | Earnings (AMC, FQ Oct/2026) | 2026-12-01 | (E) | $22B | Nasdaq calendar; **Δ Nasdaq 12-07 (W46) -> 12-01** |
| CRM | Salesforce, Inc. [A-queue] | Earnings (AMC, FQ Oct/2026) | 2026-12-02 | (C) | $151B | Salesforce release 2026-11-10 (carried W46): Wed 12-02 after close, 2:00 pm PT |
| BMO | Bank Of Montreal | Earnings (BMO, FQ Oct/2026) | 2026-12-02 | (E) | $112B | **Δ Nasdaq 12-03 (W46) -> 12-02** |
| BNS | Bank of Nova Scotia (The) | Earnings (BMO, FQ Oct/2026) | 2026-12-02 | (E) | $106B | **Δ Nasdaq 12-01 (W46) -> 12-02** |
| SNOW | Snowflake Inc. [A-queue] | Earnings (AMC, FQ Oct/2026) | 2026-12-02 | (C) | $95B | Snowflake release 2026-11-02 (carried W46): after close, call 2:00 pm PT |
| ZS | Zscaler, Inc. | Earnings (AMC, FQ Oct/2026) | 2026-12-02 | (C) | $34B | Zscaler release 2026-11-05 (carried W46): Wed 12-02, call 1:30 pm PT. **Δ Nasdaq 11-24 (W46) -> 12-02 now agrees with the issuer** |
| FIVE | Five Below, Inc. | Earnings (AMC, FQ Oct/2026) | 2026-12-02 | (E) | $13B | Nasdaq calendar |
| GWRE | Guidewire Software, Inc. | Earnings (n/s, FQ Oct/2026) | 2026-12-02 | (E) | $11B | Nasdaq calendar |
| NTSK | Netskope, Inc. | Earnings (AMC, FQ Oct/2026) | 2026-12-02 | (E) | $10B | Nasdaq calendar; **Δ new in pull** |
| RY | Royal Bank Of Canada | Earnings (BMO, FQ Oct/2026) | 2026-12-03 | (E) | $260B | Nasdaq calendar |
| TD | Toronto Dominion Bank (The) | Earnings (BMO, FQ Oct/2026) | 2026-12-03 | (E) | $188B | Nasdaq calendar |
| CM | Canadian Imperial Bank of Commerce | Earnings (BMO, FQ Oct/2026) | 2026-12-03 | (E) | $96B | Nasdaq calendar |
| VEEV | Veeva Systems Inc. | Earnings (AMC, FQ Oct/2026) | 2026-12-03 | (E) | $43B | Nasdaq calendar; **Δ Nasdaq 11-19 (W46) -> 12-03** |
| KR | Kroger Company (The) | Earnings (BMO, FQ Oct/2026) | 2026-12-03 | (E) | $40B | Nasdaq calendar |
| DG | Dollar General Corporation | Earnings (BMO, FQ Oct/2026) | 2026-12-03 | (E) | $29B | Nasdaq calendar |
| ULTA | Ulta Beauty, Inc. | Earnings (AMC, FQ Oct/2026) | 2026-12-03 | (E) | $27B | Nasdaq calendar |
| IOT | Samsara Inc. | Earnings (AMC, FQ Oct/2026) | 2026-12-03 | (E) | $22B | Nasdaq calendar |
| BF.A | Brown Forman Corporation | Earnings (BMO, FQ Oct/2026) | 2026-12-03 | (E) | $14B | Nasdaq calendar |
| BF.B | Brown Forman Corporation | Earnings (BMO, FQ Oct/2026) | 2026-12-03 | (E) | $14B | Nasdaq calendar |
| DOCU | DocuSign, Inc. | Earnings (n/s, FQ Oct/2026) | 2026-12-03 | (C) | $14B | **Δ NEW (C):** Docusign release 2026-11-19 (investor.docusign.com / docusign.com, web_search this run): after close Thu 12-03, call 5:00 pm ET; FMP 12-03 agrees. W46: (E), not searched |
| HRL | Hormel Foods Corporation | Earnings (BMO, FQ Oct/2026) | 2026-12-03 | (E) | $13B | Nasdaq calendar |
| COO | The Cooper Companies, Inc. | Earnings (AMC, FQ Oct/2026) | 2026-12-03 | (E) | $11B | Nasdaq calendar |
| TOL | Toll Brothers, Inc. | Earnings (AMC, FQ Oct/2026) | 2026-12-07 | (E) | $13B | Nasdaq calendar; **Δ Nasdaq 12-14 (W46) -> 12-07** |
| SNPS | Synopsys, Inc. | Earnings (AMC, FQ Oct/2026) | 2026-12-08 | (E) | $83B | **Δ Nasdaq 12-09 (W46) -> 12-08 AMC** (W46 note: vendors said 12-08 after close) |
| AZO | AutoZone, Inc. | Earnings (BMO, FQ Nov/2026) | 2026-12-08 | (E) | $53B | Nasdaq calendar |
| SUNB | Sunbelt Rentals Holdings, Inc. | Earnings (BMO, FQ Oct/2026) | 2026-12-08 | (E) | $32B | Nasdaq calendar; **Δ new in pull** |
| CASY | Caseys General Stores, Inc. | Earnings (AMC, FQ Oct/2026) | 2026-12-08 | (E) | $25B | Nasdaq calendar |
| GME | GameStop Corporation | Earnings (n/s, FQ Oct/2026) | 2026-12-08 | (E) | $14B | Nasdaq calendar |
| SAIL | SailPoint, Inc. | Earnings (BMO, FQ Oct/2026) | 2026-12-08 | (E) | $13B | Nasdaq calendar |
| AVGO | Broadcom Inc. [A-queue] | Earnings (AMC, FQ Oct/2026) | 2026-12-09 | (C) | $1,655B | Broadcom release 2026-11-09 (investors.broadcom.com, carried W46): Wed 12-09 after close, 2:00 pm PT. **Δ Nasdaq 12-10 (W46) -> 12-09 now agrees with the issuer** |
| ADBE | Adobe Inc. [A-queue] | Earnings (AMC, FQ Nov/2026) | 2026-12-09 | (C) | $86B | Adobe IR events page (carried W46): Wed 12-09, 2:00 pm PT; FMP agrees (EPS est 6.33) |
| COST | Costco Wholesale Corporation | Earnings (AMC, FQ Nov/2026) | 2026-12-10 | (C) | $485B | investor.costco.com event page (carried W46): Thu 12-10, call 2:00 pm PT (no dated release seen); FMP agrees |
| CIEN | Ciena Corporation | Earnings (BMO, FQ Oct/2026) | 2026-12-10 | (E) | $37B | Nasdaq calendar |
| LULU | lululemon athletica inc. | Earnings (n/s, FQ Oct/2026) | 2026-12-10 | (E) | $11B | Nasdaq calendar |
| ORCL | Oracle Corporation [A-queue] | Earnings (AMC, FQ Nov/2026) | 2026-12-14 | (C) issuer FAQ; no dated release | $334B | **Δ Nasdaq 12-09 (W46) -> 12-14 AMC.** Oracle IR FAQ (oracle.com/corporate/investor_relations/faq.html, web_search this run, page undated): "Second Quarter Fiscal Year 2027 earnings will be announced on December 14, 2026." Nasdaq now AGREES. A vendor page (theearningsmadness.com, dated 2026-11-19) still shows 12-09 "estimated, not yet announced". investor.oracle.com news page returned no release text (web_fetch, dynamic page). Residual: no dated press release; 12-09 only on vendors |
| LEN | Lennar Corporation | Earnings (n/s, FQ Nov/2026) | 2026-12-15 | (E) | $19B | Nasdaq calendar |
| LEN.B | Lennar Corporation | Earnings (n/s, FQ Nov/2026) | 2026-12-15 | (E) | $19B | Nasdaq calendar |
| NDSN | Nordson Corporation | Earnings (AMC, FQ Oct/2026) | 2026-12-15 | (E) | $18B | Nasdaq calendar; **Δ Nasdaq 12-09 (W46) -> 12-15** |
| MU | Micron Technology, Inc. [A-queue] | Earnings (n/s, FQ Nov/2026) | 2026-12-16 | (C) | $781B | **Δ NEW (C); Nasdaq 12-16 (n/s) is WRONG by one day:** Micron release 2026-11-19 (investors.micron.com, GlobeNewswire), "Micron Technology to Report Fiscal First Quarter Results on December 17, 2026": call Thu 12-17, 2:30 pm MT. W46: (E) 12-16, vendors conflicted 12-15/12-16/12-23 |
| JBL | Jabil Inc. | Earnings (n/s, FQ Nov/2026) | 2026-12-16 | (E) | $25B | Nasdaq calendar |
| ACN | Accenture plc | Earnings (BMO, FQ Nov/2026) | 2026-12-17 | (E) | $146B | Nasdaq calendar |
| CTAS | Cintas Corporation | Earnings (n/s, FQ Nov/2026) | 2026-12-17 | (E) | $87B | Nasdaq calendar |
| NKE | Nike, Inc. | Earnings (n/s, FQ Nov/2026) | 2026-12-17 | (E) | $51B | Nasdaq 12-17 n/s; FMP 12-17 agrees (EPS est 0.38) |
| HEI | Heico Corporation | Earnings (n/s, FQ Oct/2026) | 2026-12-17 | (E) | $46B | Nasdaq calendar |
| HEI.A | Heico Corporation | Earnings (n/s, FQ Oct/2026) | 2026-12-17 | (E) | $46B | Nasdaq calendar |
| GIS | General Mills, Inc. | Earnings (BMO, FQ Nov/2026) | 2026-12-17 | (E) | $18B | Nasdaq calendar; **Δ Nasdaq 12-16 (W46) -> 12-17** |
| KEP | Korea Electric Power Corporation | Earnings (n/s, FQ Sep/2026) | 2026-12-17 | (E) | $12B | Nasdaq calendar |
| FDS | FactSet Research Systems Inc. | Earnings (n/s, FQ Nov/2026) | 2026-12-17 | (E) | $11B | Nasdaq calendar |
| PAYX | Paychex, Inc. | Earnings (n/s, FQ Nov/2026) | 2026-12-18 | (E) | $40B | Nasdaq calendar |
| CCL | Carnival Corporation Ltd. | Earnings (n/s, FQ Nov/2026) | 2026-12-18 | (E) | $37B | Nasdaq 12-18 n/s; FMP 12-18 agrees (EPS est 0.23), terminal FMP row |
| DRI | Darden Restaurants, Inc. | Earnings (BMO, FQ Nov/2026) | 2026-12-18 | (E) | $26B | Nasdaq calendar; **Δ Nasdaq 12-17 (W46) -> 12-18** |
| STZ | Constellation Brands Inc | Earnings (n/s, FQ Nov/2026) | 2027-01-06 | (E) | $24B | Nasdaq calendar; **Δ new in pull** |

**Full enumeration of the remainder ($2B ≤ mcap < $10B), by session** — Nasdaq reporters NOT in the detail table, ordered by market cap within the day; ᵇ = before open, ᵃ = after close, no mark = time not supplied. All (E).
- **2026-11-23** (5): SMTCᵃ AMTMᵃ CENTᵃ CENTAᵃ DACᵃ
- **2026-11-24** (11): URBNᵃ DYᵇ VIPSᵇ ANFᵇ CMBTᵇ BILIᵇ MMEDᵇ GGAL BWLPᵇ KSSᵇ AMBAᵃ
- **2026-11-25** (3): BZᵇ BMA GDSᵇ
- **2026-11-27** (1): CHA
- **2026-12-01** (7): HQYᵃ GTLBᵃ NIOᵇ BOXᵃ AEO NCNOᵃ ASANᵃ
- **2026-12-02** (7): DCIᵇ DSGXᵃ VFSᵇ Mᵇ THO SIGᵇ KEN
- **2026-12-03** (10): Sᵃ VSXYᵇ TTANᵃ SAICᵇ PATHᵃ DOOᵇ PVHᵇ AGXᵃ WLY WLYB
- **2026-12-08** (8): CNMᵇ OLLI BRZEᵃ AVAV ASO KFY BRCᵇ UNFIᵇ
- **2026-12-09** (4): CHWYᵇ CPBᵇ MTNᵃ UEC
- **2026-12-10** (4): BIRKᵇ PLᵃ FIZZ RH
- **2026-12-15** (1): WORᵃ
- **2026-12-16** (2): TTC ABM
- **2026-12-17** (3): KMXᵇ BBᵇ KBH
- **2026-12-18** (2): LW CAG
- **2026-12-21** (1): ABVX
- **2027-01-05** (2): AIR PENG
- **2027-01-06** (9): JEF MSM ACI PSMT APLD UNF AZZ CALM RGC

Check: detail 80 + remainder 80 = 160 forward Nasdaq rows. **Δ vs W46 forward list (full per-name diff of all rows):** Nasdaq date moves for 38 carried symbols (all (E) unless stated; the larger names: BHP 11-17 -> 11-24; ORCL 12-09 -> 12-14; AVGO 12-10 -> 12-09; ZS 11-24 -> 12-02; BNS 12-01 -> 12-02; BMO 12-03 -> 12-02; SNPS 12-09 -> 12-08; VEEV 11-19 -> 12-03; CPRT 11-19 -> 12-01; TOL 12-14 -> 12-07; NIO 11-24 -> 12-01; TCOM 11-16 -> 11-23; DLTR 12-02 -> 11-24; GIS 12-16 -> 12-17; DRI 12-17 -> 12-18; NDSN 12-09 -> 12-15; RBRK 12-03 -> 11-30). New in the pull: MDB 12-01, MMED, NTSK, SUNB, AIR, PENG, STZ 01-06, JEF, MSM, ACI, PSMT, APLD, UNF, AZZ, CALM, RGC. In W46's forward list but absent now (no print evidence, not struck): BBAR, KC, CLSK (W46 11-24), IDT (12-03), EPAC (12-16). MDT is back on Nasdaq (11-24 BMO, issuer-confirmed).

### 1A.2 — Earnings, after the C window up to the dense horizon: empty

Empty by construction: the C window now ends 2027-01-06, beyond the FMP dense horizon (2026-12-18), so the 12-17 / 12-18 rows (NKE 12-17, CCL 12-18, FMP and Nasdaq agree) sit in 1A.1. Nasdaq ≥ $2B 12-21: 1 row (ABVX); 12-22 → 12-30: none; 01-05: 2, 01-06: 10. No FMP row 12-19 → 2027-01-10. Effective confirmed-earnings horizon 2026-12-18 = 26 days from 2026-11-22 (unchanged, eighth week).

### 1A.3 — Earnings, 2027-01-07 → 2027-05-22

Coverage gap, not absence of events: FMP (4 chunked calls, orchestrator, 2026-11-22) returns nothing 12-19 → 2027-01-10, 61 rows 2027-01-11 → 02-21, and only 9 rows after (LCID 02-23, NVDA 02-24, BIDU 02-25, RKT 02-25, RIOT 03-01, TGT 03-02, BABA 03-18, FDX 03-25, FUBO 04-30). Nasdaq pull ends 2027-01-08 (01-07 zero rows, 01-08 two rows < $2B). Window end rolled 05-15 → 05-22. All FMP rows below are (E).

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
| 2027-02-01 | DIS · PLTR |
| 2027-02-02 | AMD · FDX · FUBO · PEP · PFE · PYPL |
| 2027-02-03 | ABBV · GOOGL · SNAP · UBER |
| 2027-02-04 | AAPL · AMZN · CARR · MGM · RBLX · SIRI · SONY |
| 2027-02-09 | F · HOOD · KO |
| 2027-02-10 | CSCO · SHOP |
| 2027-02-11 | COIN · PINS · RIVN · ROKU |
| 2027-02-12 | MRNA |
| 2027-02-18 | ETSY · WMT |
| 2027-02-23 | LCID |
| 2027-02-24 | NVDA |
| 2027-02-25 | BIDU · RKT |
| 2027-03-01 | RIOT |
| 2027-03-02 | TGT |
| 2027-03-18 | BABA |
| 2027-03-25 | FDX |
| 2027-04-30 | FUBO |

Δ vs W46's FMP table (compared table-to-CSV): **no date changed** for any symbol present in both; newly present DIS 02-01, WMT 02-18, NVDA 02-24, BIDU 02-25, TGT 03-02, BABA 03-18, FUBO 02-02 / 04-30; none dropped.

**Per-name tails for A-queue names with no forward date in the Nasdaq pull ((E) fallback).** Rows are CARRIED from W46 (vendor and issuer sources as stated there) and were NOT re-searched this run (budget spent on 1A.1 / 1B.3 / macro confirmations; no source seen this run contradicted them); FMP dates for every carried symbol are unchanged. Δ rows are marked.

| Ticker | Event | Date | Tag | Source |
|---|---|---|---|---|
| NVDA | FQ4 FY27 (after the 11-17 print) | 2027-02-24 | (E) **Δ now FMP** | FMP (new row); W46 days.to/WSH inference ~02-24 |
| TGT | FQ4 (after the 11-18 print) | 2027-03-02 | (E) **Δ NEW** | FMP only |
| WMT | FQ4 FY27 (after the 11-19 print) | 2027-02-18 | (E) **Δ NEW** | FMP only |
| GEV | GE Vernova Q4 2026 earnings webcast | 2027-01-27, 7:30-8:30 am EST | (C) carried | gevernova.com events page (W46 web_search); vendors agree |
| MRK | Q4 2026 / Q1 2027 calls | 2027-02-02 / 2027-04-29 | (C) carried | merck.com, not re-read; FMP no MRK row |
| JPM | Q4 2026 results | 2027-01-14 | (E) | FMP; JPM Q4 2026 date not in the 2026-10-27 release |
| JPM | Q1 / Q2 / Q3 2027 earnings calls | 2027-04-13 / 07-13 / 10-12 (8:30 am ET) | (C) carried | JPMorganChase release 2026-10-27 "Updates 2027 Earnings Release Date Information" (W46) |
| AAPL | FQ1 FY27 | 2027-02-04 (FMP + vendors) or 2027-01-28 (WSH, days.to) | (E), vendors CONFLICT | Apple IR lists no date notice (W46) |
| MSFT | FQ2 FY27 | 2027-01-27 | (E) | FMP + vendors |
| META | Q4 2026 | 2027-01-27 | (E) | FMP + vendors |
| GOOGL | Q4 2026 | 2027-02-03 | (E) | FMP + vendors |
| AMZN | Q4 2026 | 2027-02-04 (after close) | (E) | FMP; WSH "UNCONFIRMED" |
| AMD | Q4 2026 | 2027-02-02 | (E) | FMP; days.to; findeal |
| INTC | Q4 2026 | 2027-01-28 | (E) | FMP |
| XOM · CVX | Q4 2026 | 2027-01-29 | (E) | FMP |
| CEG | FQ4 2026 (next after 11-09 print) | 2027-02-23 (howmanytradingdays) or 02-25 (TipRanks, Quartr) | (E), vendors differ | constellationenergy.com lists only the 11-09 call (W46) |
| LLY | Q4 2026 | 2027-02-03 or 02-02 | (E), vendors differ | no Lilly notice (W46) |
| IBM · NOW | Q4 2026 | 2027-01-27 (after close) | (E) | earningsmadness, Theta (W46) |
| CAT | Q4 2026 | 2027-01-28 (before open) | (E) | earningsmadness (W46) |
| AKAM | Q4 2026 | 2027-02-18 (after close) | (E) | findeal, howmanytradingdays, marketchameleon; steadybase 2027-02-04 |
| ANET | Q4 2026 | 2027-02-11 (after close) | (E) | howmanytradingdays, findeal |
| DDOG | Q4 2026 | 2027-02-09 (before open) | (E) | fru.dev, findeal |
| QCOM | FQ1 FY27 | 2027-02-03 (after close) | (E) | fru.dev, findeal |
| SMCI | FQ2 FY27 | 2027-02-02 | (E) | findeal only |
| FSLR | Q4 2026 | 2027-02-23 | (E) | findeal only |
| VRTX | Q4 2026 | 2027-02-11 (after close) | (E) | Zacks "estimated date", earningsmadness (W46) |
| CSCO | FQ2 FY27 | 2027-02-10 | (E) | FMP; howmanytradingdays |
| AMAT | FQ1 FY27 | 2027-02-11 | (E) | fru.dev projected |
| NTAP | FQ3 FY27 / FQ4 FY27 | target 2027-03-04 / 2027-06-03 (second outside window) | (C) issuer target carried | NetApp release 2026-11-10 "Future Targeted Release Dates" |
| AVGO | FQ1 FY27 | ~2027-03-03 | (E) carried | days.to projection |
| ORCL | FQ3 FY27 | ~2027-03-09/10 | (E) | fru.dev "Mar 9, 2027" |
| MU | FQ2 FY27 | ~2027-03-17 | (E) | fru.dev "Mar 17, 2027" |
| FDX | FedEx | 2027-03-25 (FMP chunk 3) vs 2027-02-02 (FMP chunk 2) | (T) | FMP internal conflict; neither relied on (not A-queue) |

**No date at all found:** COP (IR lists only the printed 11-05 call), NBIS, TTWO (FQ3 print date not searched). No post-print date searched for CRM, CRWD, SNOW, OKTA, MRVL, HD, PANW, INTU, HPE, DELL, ADBE (beyond 2027-02, mostly outside vendor horizons).

### Printed this week (2026-11-16 → 2026-11-20)

All 13 Nasdaq rows ≥ $50B plus A-queue names whose Nasdaq date fell 11-16 → 11-20 (82 printed-week rows at ≥ $2B; 13 listed, which includes all 6 A-queue printers; the 69 others are < $50B and not A-queue). These drop out of the forward calendar. A Nasdaq date is a schedule, not evidence of a print; this part researched dates, not outcomes (the thesis agent owns outcomes), so every row below is 'Nasdaq date only' unless stated.

| Ticker | Name | Nasdaq date | A-queue | Mcap | EPS fcst (Nasdaq, n est) | Print evidence |
|---|---|---|---|---|---|---|
| NVDA | NVIDIA Corporation | 2026-11-17 | A | $3,518B | $2.47 (14) | Nasdaq date only (time n/s on all printed-week rows); print outcome not researched |
| HD | Home Depot, Inc. (The) | 2026-11-17 | A | $336B | $3.86 (11) | Nasdaq date only (time n/s on all printed-week rows); print outcome not researched |
| DIS | Walt Disney Company (The) | 2026-11-17 |  | $205B | $1.67 (9) | (C) issuer date 11-17 BMO (Disney release 2026-10-12, carried W46); outcome not researched |
| PANW | Palo Alto Networks, Inc. | 2026-11-18 | A | $296B | $0.52 (16) | Nasdaq date only (time n/s on all printed-week rows); print outcome not researched |
| TJX | TJX Companies, Inc. (The) | 2026-11-18 |  | $153B | $1.33 (7) | Nasdaq date only (time n/s on all printed-week rows); print outcome not researched |
| LOW | Lowe's Companies, Inc. | 2026-11-18 |  | $123B | $2.86 (11) | Nasdaq date only (time n/s on all printed-week rows); print outcome not researched |
| TGT | Target Corporation | 2026-11-18 | A | $76B | $2.05 (13) | Nasdaq date only (time n/s on all printed-week rows); print outcome not researched |
| WMT | Walmart Inc. | 2026-11-19 | A | $1,000B | $0.64 (13) | Nasdaq date only (time n/s on all printed-week rows); print outcome not researched |
| BABA | Alibaba Group Holding Limited | 2026-11-19 |  | $202B | $1.56 (2) | (C) issuer date 2026-11-19 BMO (Alibaba release 2026-11-06, carried W46); outcome not researched |
| PDD | PDD Holdings Inc. | 2026-11-19 |  | $122B | $2.61 (2) | Nasdaq date only (time n/s on all printed-week rows); print outcome not researched |
| INTU | Intuit Inc. | 2026-11-19 | A | $83B | $2.47 (9) | Nasdaq date only (time n/s on all printed-week rows); print outcome not researched |
| ROST | Ross Stores, Inc. | 2026-11-19 |  | $70B | $1.85 (7) | Nasdaq date only (time n/s on all printed-week rows); print outcome not researched |
| NTES | NetEase, Inc. | 2026-11-19 |  | $67B | $2.37 (2) | Nasdaq date only (time n/s on all printed-week rows); print outcome not researched |

A-queue names printed in the week: NVDA 11-17, HD 11-17, PANW 11-18, TGT 11-18, WMT 11-19, INTU 11-19 (6 of 47). Earlier W46-week printers CEG, TTWO, CSCO, AMAT, NBIS (11-09 → 11-12) are in the census 'none' group. Rolled off from W46's forward calendar (dated before 2026-11-22): every W46 row dated 11-16 → 11-20 (the 82 printed-week names at ≥ $2B). One print-adjacent fact seen incidentally: Anthropic's Class N private placement and IPO (1A.7) involved AMD, Broadcom, Micron, Microsoft, NVIDIA (A-queue names).

### 1A.4 — Product launches, keynotes, developer events (window 2026-11-22 → 2027-05-22)

Passed/resolved since W46 (rolled off, dated before 2026-11-22; occurrence not verified unless stated): Microsoft Ignite, San Francisco 2026-11-17 → 11-20; Micron TomorrowX fireside 2026-11-18; Take-Two Grand Theft Auto VI launch 2026-11-19 (not re-checked). Rows below are carried from W46 unless a Δ is shown.

| Ticker/Event | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| AMZN | Amazon | Black Friday / Cyber Week promotions (in progress) | 2026-11-19 → 11-30 | (C-secondary) carried | Seeking Alpha 2026-11-10 (W46) |
| AMZN | Amazon | AWS re:Invent, Las Vegas (badge/kickoff 11-29) | 2026-11-30 → 12-04 | (C) carried | aws.amazon.com/events/reinvent (W45 fetch), not re-read |
| NVDA | NVIDIA | GTC Washington, D.C. (workshops 11-30; conference 12-01 → 12-03; keynote Tue 12-01, 2-4 pm ET) | 2026-11-30 → 12-03 | (C) event dates; keynote speaker **UNCERTAIN** | **Δ re-checked this run:** nvidia.com/gtc/dc/keynote (page acquired 2026-11-14) still reads "Join us live to see CEO Jensen Huang explore ... " for Tuesday December 1, 2-4 p.m. ET; page was last acquired two days after the 11-12 Huang resignation announcement (1A.7), so the wording is not evidence of who speaks |
| MU | Micron | UBS 30th Global Technology and AI Conference fireside, Scottsdale (12-01 8:15 am MT) | 2026-12-01 | (C) carried | Micron release 2026-11-12 (W46) |
| HPE | HPE | UBS Global Technology and AI Conference (12-02); Barclays 24th Global Technology Conference (12-09) | 2026-12-02; 2026-12-09 | (C) carried | investors.hpe.com (W46) |
| GOOGL | Alphabet | Waymo multi-city robotaxi launches | 2026 (year only) | (T) carried | |
| — | broad | CES 2027, Las Vegas Convention Center | 2027-01-06 → 01-09 | (E) carried | listings (W46) |
| — | healthcare broad | J.P. Morgan Healthcare Conference, San Francisco | 2027-01-11 → 01-14 | (E) carried | listings; not re-verified |
| NVDA | NVIDIA | GTC 2027 San Jose | 2027-03-14 → 03-18 | (C) carried | nvidia.com GTC FAQ (W43/W44) |

### 1A.5 — Analyst and investor days

Passed/resolved since W46 (rolled off): McGraw Hill Investor Day 2026-11-18 and Sotera Health 2026-11-20 (scheduled dates; occurrence not verified). Rows carried from W46, not re-verified this run (no investor-day sweep; no A-queue investor-day search was run).

| Ticker/Event | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| NTR | Nutrien | Investor Day, Toronto | 2026-11-30 | (C) carried | Nutrien release 2026-09-23 |
| NU | Nu Holdings | First Investor Day, NYC | 2026-12-08 | (C) carried | Nu Holdings release 2026-09-02 |
| LOW | Lowe's | Analyst and Investor Conference, NYC, 8:00 am ET | 2026-12-09 | (C) carried | corporate.lowes.com IR page (W46) |
| NKE | Nike | Investor day "Fall 2026" | — | (T) carried | |
| UNH | UnitedHealth | Investor conference | ~2026-12 early | (E) carried | |
| JPM | JPMorganChase | Investor Day | 2027-02-22 | (C) carried | not re-fetched |

### 1A.6 — Regulatory, legal, trade and macro

PDUFA rows are mirrored in 1B.3 (window to 2027-01-06 there; this table runs to 2027-05-22). Macro dates are (C) from bls.gov / bea.gov / federalreserve.gov (read through web_search 2026-11-22) unless noted; carried rows were not re-read.

**Passed/resolved since W46 (rolled off):**
- **SMMT ivonescimab BLA (PDUFA 2026-11-14): COMPLETE RESPONSE LETTER.** FDA's own CRL document BLA 761524 dated 2026-11-13 (download.open.fda.gov/crl/CRL_BLA761524_20261113.pdf: "substantial evidence of effectiveness is not established"; no statistically significant OS); Summit release 2026-11-15 (smmttx.com) and 8-K Ex. 99.1 filed 2026-11-16 (sec.gov) confirm. This resolves W46's "UNRESOLVED".
- **CYTK aficamten (MYQORZO) sNDA, MAPLE-HCM (PDUFA 11-14): APPROVED.** Cytokinetics release 2026-11-16 (ir.cytokinetics.com); Drugs@FDA lists Myqorzo NDA 219083 SUPPL-2 "Efficacy / Approved" in its 11-16 block; AJMC 11-17 and pdufa.bio (aggregators) place the FDA action on 11-13.
- **CAPR deramiocel BLA (PDUFA 11-22): COMPLETE RESPONSE LETTER** announced 2026-11-20 (Capricor release 7:55 pm EST, capricor.com; call Mon 11-23 8:30 am ET); NeurologyLive 11-20 confirms; 2 days before the action date.
- **SAN venglustat (Infilbray) NDA (PDUFA 11-25): APPROVED 2026-11-18** (FDA press announcement 2026-11-18 and Sanofi release 2026-11-18; label on accessdata.fda.gov) — nine days ahead of the date.
- **REGN cemdisiran (Livsayis) NDA (gMG; November, no day): APPROVED 2026-11-18** (Regeneron release 2026-11-18; Drugs@FDA lists NDA 221251; partner ALNY release 11-19: $25M payment).
- Oct FOMC minutes: released 2026-11-18 (federalreserve.gov fomccalendars page, "Released November 18, 2026"). UNP·NSC 11-18 STB comments and Beren NDA 11-17 (W46 rows) are dated before the window and drop off.

| Ticker/Event | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| SVRA | Savara | Molgramostim BLA, goal date 11-22 **MISSED by FDA; no revised date** | was 2026-11-22; now undated | (C) **Δ** | Savara release 2026-11-20 (investors.savarapharma.com): FDA "will not meet" the PDUFA date; review ongoing; no revised action date; BioSpace 11-20 (secondary): stock -18%, Jefferies reads it as bandwidth, not a CRL |
| BBIO | BridgeBio | BBP-418 NDA | 2026-11-27 | (C) carried | BridgeBio Q3 release 2026-10-29 (W46); uprighttrades/arca (secondary) restate |
| GSK | GSK (ADR) | Neladalkib NDA (Nuvalent) | 2026-11-27 | (C-secondary) carried | Nuvalent release 2026-05-27 / Royalty Pharma 8-K (W46) |
| PYPD | PolyPid | D-PLEX100 NDA | 2026-11-28 | (C-secondary) | arca lists PolyPid 6-K filed 2026-11-12 restating 11-28; cap likely < $2B |
| VRTX | Vertex | Povetacicept BLA (accelerated, IgAN) | 2026-11-30 | (C) carried | Vertex 10-Q 2026-11-03 per arca.inc (aggregator quoting filing) and biopharmatranscript quote of the BLA acceptance; **no FDA action or Vertex release seen in this run's 7-call search (searched explicitly, nothing returned)** |
| COGT | Cogent | Bezuclastinib + sunitinib GIST NDA | 2026-11-30 | (C) carried | Cogent Q3 release 2026-11-05 (W46) |
| COGT | Cogent | Bezuclastinib NonAdvSM NDA | 2026-12-30 | (C) carried | same release; AdvSM is 2027-06-29 |
| RHHBY | Roche (ADR) | Giredestrant adjuvant NDA | 2026-11-30 | (C-secondary) | Roche 2026-10-01 per W46; pdufa.bio 11-21 still lists 11-30 |
| — | broad | PCE (Oct) = Personal Income and Outlays; GDP 2nd est. Q3 | 2026-11-25 | **(C) Δ upgraded** | bea.gov/news/schedule (web_search 2026-11-22) |
| — | broad | Beige Book | 2026-11-25 | (C-secondary) **Δ NEW** | fedgazette.com calendar (copied from Fed, 2026-11-18); xoomar.com lists 2:00 pm ET |
| — | broad | JOLTS (Oct) | 2026-12-01, 10:00 am | (C-secondary) **Δ NEW** | fedgazette.com / xoomar.com (copy of BLS schedule) |
| EQT·RRC | EQT / Range Resources | All-stock merger (~$13B); close targeted Q1 2027; votes + regulatory pending | announced 2026-10-26 | (C) carried | Range 8-K/425; not re-read |
| UNP·NSC | Union Pacific / Norfolk Southern | DOJ/USDOT comments | 2026-12-03 | (C) carried, **possibly superseded** | W44 row; STB final briefs reported 2027-05-28 (W46 note) |
| FSLR | First Solar + solar | Sec 232 tariff regime effective | 2026-12-04 | (C) carried, not re-verified | |
| — | broad | Employment Situation (Nov) | 2026-12-04 | (C) | bls.gov/schedule/news_release/empsit.htm (web_search 2026-11-22): "November 2026 – Dec. 04, 2026 08:30 AM" |
| VRTX | Vertex | Journavx sNDA | 2026-12-05 | (T) carried | no source this run |
| — | broad | U.S. International Trade (Oct) | 2026-12-08 | (C) | bea.gov schedule |
| — | broad | **FOMC decision + SEP/dot plot** | 2026-12-09 (meeting 12-08/09) | (C) | federalreserve.gov fomccalendars (page "Last Update: November 18, 2026", web_search 2026-11-22): "December 8-9*"; Fed Dec 2026 calendar page: FOMC Press Conference 2:30 pm ET on 12-09; last 2026 meeting |
| — | broad | CPI (Nov) | 2026-12-10 | (C) carried | bls.gov (W46); fedgazette copy of BLS schedule agrees |
| — | broad | US government funding: CR (P.L. 119-103) runs to **2026-12-11** (11:59 pm ET) | 2026-12-11 | (C-secondary) Δ updated | governmentshutdowntracker.com (verified 2026-11-17 against the enacted law; no FY27 appropriations law after it, no new CR text in either chamber); Deseret News 2026-11-22: House appropriator Simpson "We're going to have to pass a CR ... we won't have it done by the 11th"; options discussed end-of-December, end-of-March or full-year CR; Iran-war defense funding dispute; Thanksgiving recess 11-23 → 11-27; Congress's scheduled end of session 12-17/12-18. Not an outcome |
| VNDA·ANAB | Vanda / AnaptysBio | Quimilza (imsidolimab) BLA | 2026-12-12 | (C) carried | Vanda release 2026-10-28; AnaptysBio 10-Q 2026-11-12 per arca |
| — | broad | PPI (Nov) | 2026-12-15 | (C-secondary) **Δ NEW** | fedgazette.com copy of BLS schedule; xoomar.com |
| — | broad | Retail Sales (Nov) | 2026-12-16 | (C-secondary) **Δ NEW** | xoomar.com (Census schedule copy) |
| CORT | Corcept | Relacorilant NDA | 2026-12-17 | (C) carried | Corcept 8-K 2026-11-03 per uprighttrades/arca |
| — | Deciphera (Ono; not listed) | Tirabrutinib NDA (R/R PCNSL) | 2026-12-18 | (C-secondary) **Δ E -> C-secondary** | checkrare.com links Deciphera's "acceptance for filing" release (biospace.com press-release title); Deciphera text not opened |
| RHHBY | Roche (ADR) | Giredestrant + everolimus NDA | 2026-12-18 | (C-secondary) carried | Roche 2026-10-01 per W46 |
| — | Camurus (not US-listed) | Oclaiz NDA | 2026-12-18 | (E) carried | |
| — | Hansa (not US-listed) | Imlifidase BLA | 2026-12-19 | (E) carried | |
| MLYS | Mineralys | Lorundrostat NDA | 2026-12-22 | (C) carried | Mineralys Q3 release 2026-11-04 |
| — | broad | GDP 3rd est. Q3; Personal Income and Outlays (Nov) incl. PCE | 2026-12-23 | **(C) Δ upgraded** | bea.gov schedule |
| ACLX·GILD | Arcellx / Gilead | Anito-cel BLA | 2026-12-23 | (C) carried | Gilead 8-K 2026-05-07 |
| VTRS | Viatris | MR-107A-02 NDA | 2026-12-27 | (C-secondary) **Δ E -> C-secondary** | SEC text quoted by nidhi-bhai PDUFA calendar (Viatris filing 2026-08-06) "PDUFA goal date of December 27, 2026"; Viatris page not opened |
| PRAX | Praxis | Relutrigine NDA (extended) | 2026-12-27 | (C) carried | Praxis filing text |
| — | Saol (not listed) | SL1009 NDA | 2026-12-30 | (E) carried | |
| — | broad | **FOMC minutes (Dec 8-9)** | 2026-12-30, 2:00 pm ET | **(C) Δ upgraded from rule-inferred** | federalreserve.gov Dec 2026 calendar page (web_search 2026-11-22) lists "FOMC Minutes, Meeting of December 8-9 ... 30, 2:00 p.m." |
| NUVB | Nuvation Bio | IBTROZI sNDA | 2027-01-04 | (C-secondary) **Δ NEW** | arca.inc PDUFA calendar citing Nuvation 8-K filed 2026-11-04; company text not opened |
| BA | Boeing | FAA 737 MAX 10 cert "by year-end" | — | (T) carried | |
| — | broad | U.S. International Trade in Goods and Services (Nov) | 2027-01-07 | (C) | bea.gov 2027 schedule |
| — | broad | Employment Situation (Dec) / CPI (Dec) | 2027-01-08 / 2027-01-13 | (C) | bls.gov empsit table (this run); CPI carried |
| — | US-China | Busan truce suspensions and USTR Section 301 exclusions run to **2027-01-09 / 2027-01-10** | 2027-01-09 → 01-10 | (C) US side; (C-secondary) China side | USTR Federal Register notice 2026-11-10 (W46), not re-read |
| DYN | Dyne | Z-rostudirsen BLA (priority) | 2027-01-21 | (C) | Dyne Q3 release 2026-11-05 text via uprighttrades ("PDUFA target action date of January 21, 2027") |
| — | Genentech/Roche | Enspryng (satralizumab) MOGAD sBLA | 2027-01-20 | (C-secondary) **Δ NEW** | checkrare.com list linking Genentech's 2026-09-09 priority-review release |
| — | broad | **FOMC decision** (no SEP) | 2027-01-27 (meeting 01-26/27) | (C-tentative) | federalreserve.gov (page: dates tentative until confirmed at the preceding meeting) |
| INSM | Insmed | ARIKAYCE sNDA (MAC lung disease), priority | 2027-01-28 | (C-secondary) **Δ NEW** | Insmed Sept 2026 release and 10-Q 2026-10-29 (arca / checkrare quoting) |
| — | broad | GDP (Advance, Q4); Personal Income and Outlays (Dec) | 2027-01-28 | (C) **Δ NEW** | bea.gov 2027 schedule |
| PRAX | Praxis | Ulixacaltamide NDA (essential tremor) | 2027-01-29 | (C-secondary) **Δ NEW** | Praxis 10-Q 2026-11-09 per nidhi-bhai / arca |
| V | Visa | DOJ debit case fact-discovery deadline | 2027-01-29 | (E) carried | |
| PHAR | Pharming | Joenja lower-dose sNDA | 2027-01-30 | (C) carried | |
| AGIO | Agios | Mitapivat sickle cell sNDA | 2027-02-01 | (C-secondary) | Agios 8-K 2026-11-05 text "launch-ready ahead of our PDUFA goal date of February 1, 2027" (via nidhi-bhai) |
| BBIO | BridgeBio | Infigratinib NDA | 2027-02-04 | (C-secondary) | BridgeBio release 2026-10-29 (via nidhi-bhai) |
| — | broad | Employment (Jan) / CPI (Jan) | 2027-02-05 / 02-11 | (C) carried | |
| UNP·NSC | UNP / NSC | STB responses due | 2027-02-16 | (C) carried, **possibly superseded** | W44 row |
| BMRN | BioMarin | VOXZOGO full approval (achondroplasia) | 2027-02-28 | (C) **Δ re-read** | BioMarin Q3 release 2026-11-02 (biomarin.com text seen): "PDUFA target action date of February 28, 2027" |
| SRPT | Sarepta | AMONDYS 45 / VYONDYS 53 sNDAs | 2027-02-28 | (C) carried | |
| LYV | Live Nation | DOJ/states remedies | ~2027-02 | (E) carried | |
| WBD | Warner Bros Discovery | Antitrust trial begins | 2027-03-02 | (C) carried (row likely moot: WBD acquired and delisted 2026-10-06 per D1 context) | |
| EXEL | Exelixis | Zanzalintinib + atezolizumab mCRC (extended) | 2027-03-03 | (C) carried | |
| — | broad | Employment (Feb) / CPI (Feb) | 2027-03-05 / 03-10 | (C) carried | |
| — | broad | **FOMC decision + SEP** | 2027-03-17 (meeting 03-16/17) | (C-tentative) | federalreserve.gov |
| UNCY | Unicycive | OLC NDA resubmission | 2027-03-25 | (C) **Δ NEW** | Unicycive Q3 release 2026-11-16 (globenewswire text seen); cap likely < $2B |
| — | broad | FTC v. Amazon trial | ~2027-03-29 | (E) carried | |
| HRMY | Harmony | Pitolisant GR PDUFA | 2027-04-01 | (E) carried | |
| — | broad | Employment (Mar) / CPI (Mar) | 2027-04-02 / 04-13 | (C) carried | |
| — | broad | **FOMC decision** (no SEP) | 2027-04-28 (meeting 04-27/28) | (C-tentative) | federalreserve.gov |
| KMB·KVUE | Kimberly-Clark / Kenvue | Merger outside date extended to 2027-05-03 | 2027-05-03 | (E) carried | |
| — | broad | Employment (Apr) / CPI (Apr) | 2027-05-07 / 2027-05-12 | (C) | bls.gov empsit table (this run: "April 2027 – May 07, 2027"); CPI carried |
| BBIO | BridgeBio | Encaleret NDA | 2027-05-08 | (C-secondary) carried | BridgeBio release 2026-10-29 (W46) |
| — | broad | CPI (Dec) / (Jan) / (Feb) / (Mar) | 2027-01-13 / 02-11 / 03-10 / 04-13 | (C) carried | bls.gov (W46) |

**Tariff / legal note (carried, not re-verified):** IEEPA tariffs struck down by the Supreme Court (Feb 2026); Section 232 semiconductor tariff 25% (effective 2026-01-15) stands; Section 301 tariffs on Chinese semiconductors scheduled 2027-06-23 (outside window).

### 1A.7 — Restructuring, M&A and structural

D1 developments carried from W46 (not re-searched): MRVL–LITE merger; CVI/Marathon Petroleum refinery assets; MMM PFAS MDL settlement; NEOG–Zoetis genomics; ORCL $10B common stock issuance; FCX Bagdad; FWONA/FWONK exchange; PENG LED sale; INGM secondary; DT/PTCT buybacks; SYY CFO; UEC uranium agreements. Searched this run only where a carried row looked stale (Anthropic IPO).

| Ticker/Event | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| — | Anthropic | **Δ OCCURRED: IPO priced and listed.** Priced 2026-11-18 at $83.00 (above the $70-$78 range), 980,000,000 Class A shares initially; first trade Thu 2026-11-19, Nasdaq "ANT" (first-day close $97.17, market value about $1.77-1.8 trillion per Bloomberg/CNBC); offering closed 2026-11-20 with the underwriters' 147,000,000-share option exercised in full: 1,127,000,000 shares, ~$93.5B gross (~$91.6B to Anthropic); concurrent private placement of 313,253,007 Class N shares at $83.00 (~$26.0B) to AMD, Broadcom, Google, Micron, Microsoft, NVIDIA and TSMC Partners | 2026-11-18 / 11-19 / 11-20 | (C) | Anthropic release 2026-11-20 "closing of initial public offering" (anthropic.com/news/ipo-close) and 2026-11-18 pricing release (company text seen); first-day price from Bloomberg 11-19 and CNBC 11-19 (secondary) |
| AKAM | Akamai Technologies [A-queue] | Report of a seven-year, $11.6B infrastructure commitment from Anthropic with an equity warrant | date not shown | (E) single secondary snippet, carried | W46 row; not re-searched |
| GEV | GE Vernova [A-queue] | SoftBank $3.7B write-down on prepaid power equipment 2026-11-10; GE Vernova "no impact" | 2026-11-10 | (C-secondary) carried | W46 |
| NVDA | NVIDIA [A-queue] | CEO transition: Huang resigned 2026-11-12; Kress interim CEO; reported probe involving Supermicro (SMCI is A-queue) | 2026-11-12 | (C-secondary) carried | W46 |
| AMD | AMD [A-queue] | World Labs (~$8.2B) acquisition close ~end 2026; Taalas $2.9B | ~end 2026 | (E) carried | |
| MRVL·LITE | Marvell / Lumentum | All-stock merger, close 1H 2028 | announced 2026-11-02 | (C) carried | |
| EQT·RRC | EQT / Range | All-stock merger; close Q1 2027 | ann. 2026-10-26 | (C) carried | |
| SGRY / ADT | Surgery Partners take-private / ADT deal | D1 | ~2026-10-26 / 10-29 | terms not read, carried | |
| PCRX·VTRS | Pacira / Viatris | $36.50 cash tender, ~$1.65B; closing "by end of 2026" | close by ~2026-12-31 | (C) carried | |
| (other W46 carried items) | PTC·Schneider; OPCH; ON·SYNA; UBER/ezCater; CMG·SBUX (T); ORCL/OpenAI (T); CVX·HESM; WDAY (T); CAT Fabick; TECK; CTVA Vylor spin (Q4); Nasdaq-100 recon mid-Dec (E); S&P Q4 rebalance 2026-12-18 (E); DG CEO transition 2027-01-01; S&P Q1 rebalance 2027-03-19 (E) | | | carried unchanged, not re-verified | W46 |

### 1A.8 — Universe rails (carried, dated)

**Market-cap rail (≥ $2B).** Inside the C window the rail is Nasdaq's own `marketCap` field (every one of the 160 forward rows is ≥ $2B by construction; smallest forward A-queue names by that field: OKTA $36B, NTAP $33B, both far above the floor; MEASURED from the CSV). Prior direct measurements are CARRIED, not re-measured: 2026-10-04 (61 names, 0 FAIL) and 2026-10-09 (50 vendor-calendar names via `company/batch-market-cap`, 0 FAIL).

### 1A.9 — Rows struck, rejected or corrected this cycle (earnings only)

1. ~~All 2026-11-16 → 11-20 forward rows~~ — elapsed; moved to 'Printed this week' (82 rows at ≥ $2B; occurrence of prints not researched here).
2. **Δ MU 2026-12-16 (E, Nasdaq) -> 2026-12-17 (C)** — Micron release 2026-11-19 (investors.micron.com): call Thu 12-17, 2:30 pm MT. Nasdaq's 12-16 is wrong by one day; W46 vendor candidates 12-15 and 12-23 are both wrong.
3. **Δ ORCL: conflict narrowed, not closed.** Nasdaq moved 12-09 -> 12-14; Oracle IR FAQ (live search result this run) says 12-14; a vendor page dated 2026-11-19 still shows "Dec. 9 (est.), not yet announced". No dated Oracle press release found; investor.oracle.com news (web_fetch) is a dynamic page and returned no item text. Carried (C) on the issuer FAQ page text only.
4. **Δ DOCU 12-03 (E) -> (C)** (Docusign release 2026-11-19, after close, call 5:00 pm ET) and **MDB 12-01 (C-secondary) -> (C)** (MongoDB release 2026-11-05); Nasdaq row for MDB returned.
5. **Δ AVGO / BABA** — W46 corrections now reflected on Nasdaq (AVGO 12-09; BABA printed 11-19).
6. **Δ Nasdaq date moves vs W46 (all (E) unless issuer-confirmed):** 38 symbols, listed in 1A.1.
7. **Dropped from the Nasdaq pull with no print evidence (not struck, flagged):** BBAR, KC, CLSK, IDT, EPAC. Not re-searched.
8. **No A-queue forward date is vendor-only any more** (ORCL on the issuer FAQ page; see item 3).
9. FMP lists FDX and FUBO twice (both (T)).

### 1A.10 — Names with NO firm forward earnings date

**Newly (C) this run (A-queue):** MU 12-17 (date correction); ORCL 12-14 (issuer FAQ page, no dated release). Carried (C): HPE 11-23, DELL 11-24, CRWD/MRVL/NTAP/OKTA 12-01, CRM/SNOW 12-02, AVGO/ADBE 12-09; GEV 2027-01-27, MRK 2027-02-02, JPM 2027-04-13.

**Forward A-queue names with only an (E) or conflicted date inside the C window (0).** ORCL's residual: no dated release.

**Printed 11-16 → 11-20 (6):** NVDA, HD, PANW, TGT, WMT, INTU (next prints: FMP NVDA 02-24, TGT 03-02, WMT 02-18 (E); HD, PANW, INTU none found).

**A-queue names with NO forward date in the Nasdaq pull (29):** AAPL, AKAM, AMAT, AMD, AMZN, ANET, CAT, CEG, COP, CSCO, CVX, DDOG, FSLR, GEV, GOOGL, IBM, INTC, JPM, LLY, META, MRK, MSFT, NBIS, NOW, QCOM, SMCI, TTWO, VRTX, XOM. Of these: (C) GEV 2027-01-27, MRK 2027-02-02, JPM Q1 2027-04-13; (E) tails in 1A.3 for AAPL, AMD, AMZN, GOOGL, MSFT, META, INTC, XOM, CVX, LLY, IBM, NOW, CAT, AKAM, ANET, DDOG, QCOM, SMCI, FSLR, VRTX, CEG, CSCO, AMAT, JPM (Q4); **no date at all found: COP, NBIS, TTWO**.

### 1A.11 — Liquidity rail (30-day ADV ≥ $10M), carried

CARRIED from the 2026-10-04 measurement (IBKR regular-session daily bars, 2026-08-21 → 2026-10-02): 61 of 61 cleared; lowest VRTX $222.0M (~22x floor). NOT re-measured by this part (now 51 days old). Names beyond that list are UNMEASURED for ADV; ≥ $10M INFERRED for large caps.

## PART 1B — Strategy C universe, 45-day window (2026-11-22 → 2027-01-06)

C qualifying types only: earnings (company IR), FDA PDUFA, FOMC. No interpretation. The C window is 2026-11-22 → 2027-01-06 (run date + 45 days). The 12-08/09 FOMC sits inside, plus the 12-30 minutes. Tags as in 1A. 'carried' = read last cycle (W46) and not re-read this run. Δ = change vs W46. Market caps are the Nasdaq `marketCap` field in the shared 2026-11-22 pull ($B, rounded).

### 1B.1 — FOMC

| Event | Meeting | Decision / release date | In C window (11-22 → 01-06) | Tag | Source |
|---|---|---|---|---|---|
| FOMC minutes | 2026-10-27/28 | **Released 2026-11-18** | **Passed (before window)** | (C) | federalreserve.gov/monetarypolicy/fomccalendars.htm (web_search 2026-11-22, "Last Update: November 18, 2026"): "Minutes ... (Released November 18, 2026)". Δ vs W46 (rule-inferred 11-18, now confirmed and elapsed) |
| FOMC | 2026-12-08/09, **SEP/dot plot meeting** | **Decision 2026-12-09**; press conference 2:30 pm ET | **YES** (day 17 of the window counting 11-22 as day 0) | (C) scheduled | same page: "December 8-9*", "*Meeting associated with a Summary of Economic Projections"; Fed Dec 2026 calendar page: "FOMC Press Conference 2:30 p.m., 9"; 2:00 pm statement |
| FOMC minutes | 2026-12-08/09 meeting | **2026-12-30, 2:00 pm ET** | **YES (day 38)** | **(C) Δ upgraded from (C-rule, inferred)** | federalreserve.gov newsevents/2026-december.htm (web_search 2026-11-22) lists "FOMC Minutes, Meeting of December 8-9 ... 2:00 p.m. ... 30" |
| FOMC | 2027-01-26/27 | 2027-01-27 | No | (C) scheduled (tentative until confirmed at the preceding meeting) | same fomccalendars page |
| FOMC | 2027-03-16/17 (SEP) | 2027-03-17 | No | same | same |

Page also lists 2027 meetings 04-27/28, 06-08/09, 07-27/28, 09-14/15, 10-26/27 (strategy meeting), 11-16/17 and a 2028-01-25/26 meeting (page text shows "January 25-26, 2028"); none in window. Δ vs W46: window start 11-15 -> 11-22, end 12-30 -> 01-06 (the Dec decision moved from day 25 to day 17; no FOMC event dropped from or added to the window other than the elapsed 11-18 minutes). C queue holds thesis-FOMC-C-20261130 per W46 (not re-measured by this part).

### 1B.2 — Earnings inside the C window: company-IR-confirmed subset

Window 2026-11-22 → 2027-01-06. Nasdaq forward rows (≥ $2B) dated 11-23 → 01-06 = 160 (148 dated 11-23 → 12-30). **Struck (printed 11-16 → 11-20, before the window):** NVDA, HD, DIS, PANW, TJX, LOW, TGT, WMT, BABA, PDD, INTU, ROST, NTES and every other 11-16 → 11-20 row (82 at ≥ $2B); prints not researched. Date confirmations this run (issuer IR/press release via Parallel, excerpt seen): MU, DOCU, MDB, ORCL (FAQ). All other rows below are carried from W46.

**Company-IR confirmed (C)**

| Date | Ticker | Timing | Mcap ($B) | Confirmation (source, date) | Δ vs W46 |
|---|---|---|---|---|---|
| 2026-11-23 | HPE | after close; call 4:00 pm CT / 5:00 pm ET | 60 | hpe.com release 2026-11-02 (carried) | — |
| 2026-11-24 | DELL | after close; call 3:30 pm CST | 199 | investors.delltechnologies.com (carried) | — |
| 2026-11-24 | ADI | call 10:00 am ET (IR listing); Nasdaq BMO | 183 | investor.analog.com events (carried) | — |
| 2026-11-24 | MDT | release 5:45 am CT; webcast 6:30 am CT | 129 | news.medtronic.com 2026-11-04 (carried); Nasdaq BMO | back on Nasdaq pull |
| 2026-11-24 | ADSK | after close; call 2:00 pm PT | 51 | adsknews.autodesk.com 2026-11-02 (carried) | — |
| 2026-11-24 | WDAY | after close | 42 | Workday release (carried; relay site) | — |
| 2026-11-25 | DE | call 9:00 am CT | 168 | deere.com 2026-11-11 (carried) | — |
| 2026-12-01 | CRWD | after close; call 2:00 pm PT | 249 | ir.crowdstrike.com 2026-11-04 (carried) | — |
| 2026-12-01 | MRVL | call 1:30 pm PT after release | 121 | investor.marvell.com 2026-11-06 (carried) | — |
| 2026-12-01 | NTAP | after close; call 2:30 pm PT | 33 | investors.netapp.com 2026-11-10 (carried) | — |
| 2026-12-01 | OKTA | after close; call 2:00 pm PT | 36 | investor.okta.com 2026-11-02 (carried) | — |
| 2026-12-01 | MDB | after close; call 5:00 pm ET | 24 | **NEW (C):** investors.mongodb.com "MongoDB, Inc. Announces Date of Third Quarter Fiscal 2027 Earnings Call", PRNewswire 2026-11-05; IR events page "12/01/2026 at 5:00 PM EST" | (C-secondary) -> (C); Nasdaq row returned |
| 2026-12-02 | CRM | after close; call 2:00 pm PT | 151 | investor.salesforce.com 2026-11-10 (carried) | — |
| 2026-12-02 | SNOW | after close; call 2:00 pm PT | 95 | snowflake.com 2026-11-02 (carried) | — |
| 2026-12-02 | ZS | after close; call 1:30 pm PT | 34 | ir.zscaler.com 2026-11-05 (carried) | Nasdaq now 12-02 (agrees) |
| 2026-12-03 | DOCU | after close; call 5:00 pm ET (2:00 pm PT) | 14 | **NEW (C):** investor.docusign.com "Docusign to Announce Third Quarter Fiscal 2027 Financial Results on December 3, 2026", PRNewswire 2026-11-19 | E -> C |
| 2026-12-09 | ADBE | after close; call 2:00 pm PT | 86 | adobe.com/investor-relations (carried) | — |
| 2026-12-09 | AVGO | after close; call 2:00 pm PT | 1,655 | investors.broadcom.com 2026-11-09 (carried) | Nasdaq now 12-09 (agrees) |
| 2026-12-10 | COST | call 2:00 pm PT | 485 | investor.costco.com event page (carried) | — |
| 2026-12-17 | MU | call 2:30 pm MT (4:30 pm ET) | 781 | **NEW (C):** investors.micron.com "Micron Technology to Report Fiscal First Quarter Results on December 17, 2026", GlobeNewswire 2026-11-19 | **E 12-16 -> C 12-17 (date change vs W46 and vs Nasdaq 12-16)** |

**Oracle (A-queue) — conflict narrowed**

| Date candidates | Ticker | Mcap ($B) | Sources | Tag |
|---|---|---|---|---|
| **2026-12-14 (issuer FAQ; Nasdaq now 12-14 AMC)** vs 2026-12-09 (vendor estimate) | ORCL | 334 | oracle.com/corporate/investor_relations/faq.html (web_search 2026-11-22; page undated): "Oracle's Second Quarter Fiscal Year 2027 earnings will be announced on December 14, 2026." Nasdaq pull 2026-11-22 AMC 12-14 (W46 had 12-09). theearningsmadness.com (dated 2026-11-19): "Dec. 9 · After close · estimated, not yet announced". No dated Oracle press release found (investor.oracle.com news page, dynamic, no item text returned). | (C) on the issuer FAQ text only; **12-09 is vendor-estimate-only** |

**Vendor-only (E) — no issuer notice found, ≥ $50B on the Nasdaq forward list inside the window**

| Date | Ticker | Timing (Nasdaq) | Mcap ($B) | Note |
|---|---|---|---|---|
| 2026-11-24 | BHP | n/s | 176 | **Δ Nasdaq 11-17 -> 11-24**; foreign private issuer |
| 2026-12-02 | BMO | BMO | 112 | **Δ Nasdaq 12-03 -> 12-02** |
| 2026-12-02 | BNS | BMO | 106 | **Δ Nasdaq 12-01 -> 12-02** |
| 2026-12-03 | RY | BMO | 260 | |
| 2026-12-03 | TD | BMO | 188 | |
| 2026-12-03 | CM | BMO | 96 | |
| 2026-12-08 | SNPS | AMC | 83 | **Δ Nasdaq 12-09 -> 12-08** |
| 2026-12-08 | AZO | BMO | 53 | |
| 2026-12-17 | ACN | BMO | 146 | |
| 2026-12-17 | CTAS | n/s | 87 | |
| 2026-12-17 | NKE | n/s | 51 | FMP 12-17 agrees |

Foreign-private issuers (BHP, BNS, RY, TD, BMO, CM) file 6-K/40-F/20-F and typically announce through issuer pages not searched here. **Dates that moved vs W46:** MU 12-16 -> 12-17 (issuer); ORCL Nasdaq 12-09 -> 12-14; AVGO Nasdaq 12-10 -> 12-09; ZS Nasdaq 11-24 -> 12-02; BNS, BMO, SNPS, BHP as above. E -> C this run: MU, DOCU, MDB. Still unconfirmed: ORCL (no dated release); all vendor-only rows above. Market-cap changes since W46 are price-driven (e.g. NVDA printed; AVGO 1,585 -> 1,655; ORCL 374 -> 334; MU 743 -> 781; DELL 260 -> 199; CRWD 251 -> 249; MRVL 151 -> 121); no filter applied.

### 1B.3 — FDA PDUFA dates in window (2026-11-22 → 2027-01-06)

Rule (FDA LIMB): sponsor/status resolved against the FDA's own page/document or the sponsor's release before naming either; aggregator-only items are (E)/(C-secondary) and flagged. Cap/ADV not measured. Coverage this part: 3 search calls on PDUFA/FDA (one outcome query batch, one outcomes+status batch, one new-date batch); a floor, not a census.

**Rolled off since W46 (dated 11-14 → 11-22) — outcome as stated by a primary source**

| Date | Ticker | Item | Outcome (source) |
|---|---|---|---|
| 2026-11-14 (Sat) | SMMT | Summit — ivonescimab + chemo BLA / EGFRm NSCLC post-TKI | **CRL.** FDA CRL letter BLA 761524 dated 2026-11-13 (download.open.fda.gov); Summit release 2026-11-15 and 8-K 2026-11-16. Reasons: no statistically significant OS; modest PFS benefit does not outweigh toxicity; FDA recommends a new multiregional trial. W46 UNRESOLVED -> resolved |
| 2026-11-14 (Sat) | CYTK | Cytokinetics — MYQORZO (aficamten) sNDA adding MAPLE-HCM | **Approved** (Cytokinetics release 2026-11-16; Drugs@FDA SUPPL-2 "Approved"); W46 UNRESOLVED -> resolved |
| 2026-11-22 (Sun) | CAPR | Capricor — deramiocel BLA / DMD (upper-limb, age > 9) | **CRL** announced 2026-11-20 (Capricor release; FDA acted 2 days before the date; second CRL; call Mon 11-23 8:30 am ET) |
| 2026-11-25 (Wed) | SNY (ADR) | Sanofi — venglustat (Infilbray) / Gaucher type 3 | **Approved 2026-11-18** (FDA press announcement; Sanofi release) — a week ahead of the date; ADR, not C-eligible per W46 |
| Nov (no day) | REGN / ALNY | Cemdisiran (Livsayis) / AChR+ gMG | **Approved 2026-11-18** (Regeneron release; Drugs@FDA NDA 221251) |
| Nov (no day) | RHHBY | Gazyva / primary membranous nephropathy | pdufa.bio (aggregator) lists approval 2026-11-13; FDA/Roche text not opened — (E) outcome |
| 2026-11-10 → 11-13 | MKKGY / AZN | Pimjetmi 11-10; Imfinzi 11-13 | pdufa.bio (aggregator) only; not W46 rows; not relied on |

**In-window PDUFA dates (2026-11-22 → 2027-01-06)**

| Date | Ticker | Sponsor / drug / indication | Tag | Resolution / source |
|---|---|---|---|---|
| 2026-11-22 (Sun) | SVRA | Savara — molgramostim BLA / autoimmune PAP | (C) **status changed** | **FDA told Savara it will NOT act by 11-22; review ongoing; no revised action date** (Savara release 2026-11-20, company text seen). Undated/overdue; not a dated forward action |
| 2026-11-27 (Fri) | BBIO | BridgeBio — BBP-418 NDA / LGMD2I/R9, priority | (C) carried | BridgeBio Q3 release 2026-10-29; arca/uprighttrades restate |
| 2026-11-27 (Fri) | GSK (ADR) | Neladalkib NDA / ALK+ NSCLC (Nuvalent, acquired by GSK) | (C-secondary) carried | W46; ADR |
| 2026-11-28 (Sat) | PYPD | PolyPid — D-PLEX100 NDA, priority | (C-secondary) | PolyPid 6-K filed 2026-11-12 per arca; cap likely < $2B |
| 2026-11-30 (Mon) | VRTX | Vertex — povetacicept BLA (accelerated) / IgAN | (C) carried | Vertex 10-Q 2026-11-03 per arca; Zai Lab restates; no action seen as of 2026-11-22 searches |
| 2026-11-30 (Mon) | COGT | Cogent — bezuclastinib + sunitinib NDA / GIST, priority | (C) carried | Cogent Q3 release 2026-11-05 |
| 2026-11-30 (Mon) | RHHBY | Roche — giredestrant adjuvant NDA | (C-secondary) carried | Roche 2026-10-01 per W46; ADR; pdufa.bio 11-21 still lists |
| 2026-12-05 | VRTX | Journavx sNDA | (T) carried | no source |
| 2026-12-12 (Sat) | VNDA | Vanda — Quimilza (imsidolimab) BLA / GPP (partner ANAB) | (C) carried | Vanda release 2026-10-28 |
| 2026-12-17 (Thu) | CORT | Corcept — relacorilant NDA resubmission / Cushing's | (C) carried | Corcept 8-K 2026-11-03 |
| 2026-12-18 | — | Deciphera (Ono) — tirabrutinib NDA / R/R PCNSL | (C-secondary) **Δ E -> C-secondary** | Deciphera "acceptance for filing" release title via checkrare.com; not US-listed |
| 2026-12-18 | RHHBY | Roche — giredestrant + everolimus NDA | (C-secondary) carried | W46 |
| 2026-12-18 / 12-19 | CAMX / HNSA | Camurus Oclaiz / Hansa imlifidase | (E) carried | aggregators; not US-listed; not re-checked |
| 2026-12-22 (Tue) | MLYS | Mineralys — lorundrostat NDA / hypertension | (C) carried | Mineralys Q3 release 2026-11-04 |
| 2026-12-23 (Wed) | GILD | Gilead (Arcellx) — anito-cel BLA / RRMM | (C) carried | Gilead 8-K 2026-05-07; 10-Q per aggregators |
| 2026-12-27 (Sun) | PRAX | Praxis — relutrigine NDA (extended) | (C) carried | Praxis 8-K/10-Q text |
| 2026-12-27 (Sun) | VTRS | Viatris — MR-107A-02 NDA / acute pain | (C-secondary) **Δ E -> C-secondary** | Viatris filing text 2026-08-06 quoted by nidhi-bhai calendar |
| 2026-12-30 (Wed) | COGT | Cogent — bezuclastinib NDA / NonAdvSM | (C) carried | Cogent Q3 release 2026-11-05 |
| 2027-01-04 (Mon) | NUVB | Nuvation Bio — IBTROZI sNDA | (C-secondary) **Δ NEW** | arca.inc PDUFA calendar citing Nuvation 8-K filed 2026-11-04; company text not opened; cap not measured |

Newly seen but after the window (in 1A.6): DYN 01-21, Genentech Enspryng 01-20, INSM 01-28, PRAX ulixacaltamide 01-29, AGIO 02-01, BBIO infigratinib 02-04, BMRN 02-28, UNCY 03-25. pdufa.bio (aggregator, updated 2026-11-21) counts 10 December 2026 goal dates, one dated only to the quarter. No new in-window PDUFA for a ≥ $2B company was found beyond the rows above.

### Macro calendar in C window (2026-11-22 → 2027-01-06)

Context only; 8:30 am ET unless noted. Sources read through web_search 2026-11-22 (bea.gov schedule page modified 2026-11-18/19; bls.gov empsit table; federalreserve.gov calendars).

| Date | Release | Tag | Source / note |
|---|---|---|---|
| 11-25 | Personal Income and Outlays (Oct 2026) incl. PCE | (C) | bea.gov/news/schedule |
| 11-25 | GDP (Second Estimate) and Corporate Profits, Q3 2026 | (C) | same |
| 11-25 | Beige Book | (C-secondary) | fedgazette.com copy of Fed calendar |
| 12-01 | JOLTS (Oct), 10:00 am | (C-secondary) | fedgazette.com / xoomar.com copy of BLS |
| 12-04 | Employment Situation (Nov 2026) | (C) | bls.gov empsit table |
| 12-08 | U.S. International Trade in Goods and Services (Oct) | (C) | bea.gov |
| 12-08/09 | FOMC + SEP (decision 12-09, 2:00 pm statement; presser 2:30 pm) | (C) | federalreserve.gov |
| 12-10 | CPI (Nov 2026) | (C) | bls.gov per W46; fedgazette copy agrees |
| 12-11 | Government funding CR expiry (11:59 pm ET) | (C-secondary) | see 1A.6 |
| 12-15 | PPI (Nov) | (C-secondary) | fedgazette.com / xoomar.com |
| 12-16 | Retail Sales (Nov); Industrial Production (G.17, 9:15 am) | (C-secondary) / (C) | xoomar.com; federalreserve.gov Dec calendar lists G.17 on 16 |
| 12-18 | U.S. International Transactions, Q3 | (C) | bea.gov |
| 12-23 | GDP (Third Estimate), Industries, Corporate Profits, State GDP and Personal Income, Q3 2026 | (C) | bea.gov |
| 12-23 | Personal Income and Outlays (Nov 2026) incl. PCE | (C) | bea.gov |
| 12-30 | FOMC minutes (Dec 8-9), 2:00 pm ET | (C) **Δ upgraded** | federalreserve.gov Dec 2026 calendar |
| 2027-01-05 | JOLTS (Nov) | (C-secondary) | xoomar.com |
| 2027-01-07 | U.S. International Trade (Nov) | (C) | bea.gov 2027 schedule |

Passed before the window: CPI (Oct) 11-10, Employment Situation (Oct) 11-06, FOMC minutes 11-18. Next after the window: Employment Situation (Dec) 2027-01-08 (bls.gov), CPI (Dec) 2027-01-13, GDP Advance Q4 and PCE (Dec) 2027-01-28 (bea.gov). Δ vs W46: window extension to 01-06 adds JOLTS (Nov) 01-05 and the 01-07 trade release at its edge; BEA dates 11-25, 12-08, 12-18, 12-23 and BLS dates 12-04, 12-10 unchanged; BEA state/county items (12-02, 12-10) omitted as not relevant. No shutdown-related schedule delay appears on any agency page seen this run.

## PART 2A — Strategy A ranked shortlist

### The A-queue census — the PINNED query, run verbatim

`SELECT * FROM state.open_queue WHERE strategy = 'A'` → **47 rows** (MEASURED by the orchestrator 2026-11-22; delta 0 vs the 47 of W46): AAPL, ADBE, AKAM, AMAT, AMD, AMZN, ANET, AVGO, CAT, CEG, COP, CRM, CRWD, CSCO, CVX, DDOG, DELL, FSLR, GEV, GOOGL, HD, HPE, IBM, INTC, INTU, JPM, LLY, META, MRK, MRVL, MSFT, MU, NBIS, NOW, NTAP, NVDA, OKTA, ORCL, PANW, QCOM, SMCI, SNOW, TGT, TTWO, VRTX, WMT, XOM. My hand count of that list is 47, matching the query; the query wins in any case. Every "QUEUED" / "NEW" mark below is tested against this list. Reconciliation: the ranked set is the same 50 admissible names as W46 (40 QUEUED, 10 NEW: ETN, LRCX, PLTR, UBER, SHOP, DIS, MRNA, GE, SNDK, RDDT) plus 8 DIRECTION-INADMISSIBLE names (4 QUEUED: WMT, ADBE, HD, AKAM; 4 not queued: DAL, CCL, UAL, AAL). Three census members are not ranked: IBM, MRK, NOW.

Open positions (orchestrator-measured): no A and no C position. B: ROK, IRTC, ARQT, RVMD, RELY, ANDE, DDOG, EXPE, NRIX, MTRN, ECG, SYY, SM, MCY. D: ISRG, DIS, AMZN, GOOGL, GEV, RTX, TSM, UBER. **DDOG is an open Strategy B position and is also on the A queue and in this ranking: A and B may not hold the same name under any circumstance (strategy/03_strategy_a.md), so DDOG cannot convert to an A entry while the B lot is open (flagged on its row and in the handoff).**

### STEP 1 — the GATE DATE, re-derived from scratch, with the arithmetic shown

**DERIVED GATE DATE = 2026-12-01** (orchestrator-measured; Rev 52 STEP 1, earliest of (a), (b), (c); the retired pre-Rev 52 derivation was not run).

**Router state read first.** A's `STRATEGY_ACTIVATION` reads **DO-NOT-ACTIVATE** (`state.current_regime`, div-A-202611-1), so CATALYST-GATE MODE is live, not inert. A is LONG-ONLY (`strategy/03_strategy_a.md`: "Long-only (no short positions in A — short is B's territory)").

- **(a) Next scheduled M1a/M1b re-score.** Completed `M1a` = **1**, `M1b` = **1** this month. `m1b >= 1`, so (a) = next month's first trading day = **2026-12-01**.
- **(b) Open `PENDING_REGIME_REFRESH` `regime-refresh` items:** **none** → does not apply.
- **(c) REFRESH REQUEST (D2a Step 0, verbatim query)** returned **0 rows** (M1R drained `regime-refresh-20261119` on 2026-11-22, NO AXIS MOVED; regime: stable growth + reaccelerating inflation + hawkish policy + stressed risk + latent shock) → does not apply.
- **GATE DATE = earliest(2026-12-01, n/a, n/a) = 2026-12-01.** Delta vs W46 (gate 2026-11-15): the gate moved forward 16 days because the 11-15 refresh was serviced and drained with no axis move, leaving only the scheduled December re-score. No input was unavailable, so FAIL-OPEN did not trigger. A candidate is SPENT-BY-GATE only if its dated catalyst falls strictly before 2026-12-01 with nothing dated on/after it relevant to the thesis.

### STEP 2 — the DIRECTION ADMISSIBILITY rail (run before ranking and before gate classification)

Evidence: D1 `research-screen` records 2026-11-16..11-19 (`events.decision_log`), IBKR regular-session daily bars through 2026-11-20 (the structural Friday-session price gap is closed from IBKR, not from D1), orchestrator state, and 9 Parallel web_search calls (issuer releases, Reuters, CNBC, Schwab, SEC filings).

- **Eight names stay DIRECTION-INADMISSIBLE** (WMT, ADBE, HD, AKAM, DAL, CCL, UAL, AAL). None is reversed and none enters the top-10. Fresh evidence this week: HD printed 11-17 (comps +2.2%, FY comp guide cut to about 1.4% from about flat to +2.0% midpoint, EPS growth about 1.5%; stock -2.45% on the day) which is consistent with the carried bearish/neutral housing read; WMT printed 11-19 (beat, raised FY27, but the raised range stays below consensus; GLP-1 comp contribution cut about 40%; stock 126.04) so the thin bearish thesis is neither confirmed nor refuted and the name stays inadmissible at conviction 1; cruise lines fell on 11-19 (RCL -5.5%, NCLH -5.1% per D1 2026-11-19), no new read on airlines.
- **TGT stays DIRECTION UNRESOLVED.** Q3 2026 (11-18): net sales +7.1%, comps +5.6% (consensus 3.5%), traffic +5.0%, FY sales outlook raised to about +6%, EPS $2.65 (includes $0.50 of tariff refunds; ex-refunds adjusted EPS +21%); stock +4.0% on the day. The prior bearish thesis is refuted and no bullish gap is established. Ineligible for the top-10.
- **AMAT stays DIRECTION UNRESOLVED** (W46 reversal from bearish; no new evidence read; down in the sector selloff). Ineligible for the top-10.
- **No new bearish names added.** The 11-20 crash is a beta event across A names, not a name-specific over-valuation thesis; applying "everything fell" as bearish would be a category error for a long-only rail.

### STEP 3 — classification and counts

Gate date **2026-12-01**. SPENT-BY-GATE iff the dated catalyst is strictly before 2026-12-01 and nothing relevant is dated on/after it.

**58 carried: 50 ranked admissible (TGT and AMAT direction-unresolved) + 8 DIRECTION-INADMISSIBLE. 3 SPENT-BY-GATE (HPE 2026-11-23, DELL 2026-11-24, VRTX 2026-11-30), 55 GATE-SURVIVING.**

- **SPENT (3):** HPE (FQ4 2026-11-23 (E) after hours, Nasdaq), DELL (FQ3 FY27 2026-11-24 (C), Dell IR notice carried from W46), VRTX (PDUFA 2026-11-30 (C), Vertex release 10-23 restated). Each has only a catalyst strictly before the gate; each gets (a), (c), (d), (e) and a one-line gap thesis, no (b) chase. SPENT names sit at the top of the 11-20 tier, not in the top-10: a catalyst that resolves before A can next activate cannot be an A entry trigger.
- **Names that printed 2026-11-16..11-20 and were re-dated:** NVDA (11-17; next 2027-02-24 (E, FMP); live dated item is Huang's 2026-12-01 House interview), PANW (11-18; next undated), INTU (11-19; next undated), HD (11-17, inadmissible; next undated), WMT (11-19; next 2027-02-18 (E, FMP)), TGT (11-18; next 2027-03-02 (E, FMP)), DIS (11-17; next 2027-02-01 (E, FMP)), TTWO (GTA VI launched 11-19; next print undated, Q3 FY27 print early February INFERRED), MSFT (Ignite consumed; next 2027-01-27 (E, FMP)).
- **Date moves vs W46 (delta):** **MU 2026-12-16 (E) → 2026-12-17 (C)** (Micron IR release 2026-11-19, call Thursday 12-17 2:30 pm MT: https://investors.micron.com/news/press-release/2026/Micron-Technology-to-Report-Fiscal-First-Quarter-Results-on-December-17-2026/); **ORCL 2026-12-09 (E) → 2026-12-14 (C, issuer FAQ text only; no dated release)** (Oracle IR FAQ page says "will be announced on December 14, 2026", Nasdaq file agrees; vendors still say 12-09; Oracle has not posted its date-notice press release as of the 11-12 vendor check, so tag (E)); NVDA, PANW, INTU, WMT, TGT, HD, DIS, TTWO re-dated as above.
- **Fragile (within one week of the gate):** none of the survivors has a dated catalyst before the gate. Nearest after-gate dates: MRVL, CRWD, NTAP, OKTA 2026-12-01; CRM, SNOW 2026-12-02; FSLR 2026-12-04 (Section 232 go-live); AVGO 2026-12-09 (C); FOMC 2026-12-09 (macro; CME FedWatch about 92-95% for a hike).
- **Undated survivors (fail-open): 17** (CEG, ETN, NBIS, QCOM, LRCX, DDOG, LLY, CAT, GEV, AMAT, SNDK, RDDT, TTWO, PANW, INTU, plus inadmissible HD and AKAM). No date was fabricated; next dates are late-January/February by pattern, INFERRED.
- **Dropped / new intake:** none (50 admissible cap full; same 50 names as W46).

### Week narrative (MEASURED facts with sources; inferences labelled)

- **MEASURED. Worst week for US equities since April 2025; the Friday 11-20 session closed the damage.** S&P 500 -3.70% to 6,910.39 on 11-20 (seventh straight loss, longest since Feb 2020, now more than 10% below the 10-06 record close, a correction), Nasdaq Composite -5.28% to 22,617.73 (negative for 2026), Dow -1.93%; Nasdaq members lost more than $4 trillion on the week (Schwab 11-20; Reuters/UPI 11-20; WSJ 11-20). IBKR: SPY 754.37 (11-13) to 689.81 (11-20), **-8.6%**. VIX 35.89 (Yahoo/FMP EOD 11-20; Schwab says above 37 at the close, vendor difference unreconciled). 10-year Treasury about 4.91-5%.
- **MEASURED. Drivers (Schwab, Reuters, HNGN 11-20):** AI-financing doubts and Anthropic's post-IPO fade (priced $83, +17% day one, about -9% on 11-20); the Reuters exclusive that the SEC is probing Nvidia's accounting; Huang's resignation fallout; data-centre political risk after the Democratic midterm win; Trump threat of a tax on US firms building AI data centres abroad; and a hawkish Fed (Oct minutes: almost all officials favour more hikes; Waller floated 50 bp; Cook said waiting risks "getting behind the curve"; futures price about 92-95% odds of a hike at the 2026-12-09 FOMC, fed funds now 3.75-4%). Staples were the only sector up. Taiwan -5.65%, Nikkei and Kospi about -5%.
- **MEASURED. NVIDIA printed 11-17 and beat and raised, and the stock still fell.** Q3 FY27 revenue $115.8B (+103%, LSEG $109.1B), non-GAAP EPS $2.68 (vs $2.48), Q4 guide $130.0B +/-3% (vs $125.1B) with no China data-centre compute assumed, gross margin guide 71-72%, FY28 growth outlook raised to about 75% from 70%, $150B added to the buyback (about $227B remaining); chair Jones said the board will not reinstate Huang (nvidianews.nvidia.com, 2026-11-17; CNBC; CoinDesk). IBKR closes: 162.85 (11-13), 155.46 (11-17, pre-print), 145.98 (11-19), **125.53 (11-20, -14.0%)**, week **-22.9%**, lowest close since 2025. Huang closed-door House interview **2026-12-01**, Nvidia GC **2026-12-02**, Senate Banking public hearing requested for 12-03 (timing under negotiation; Scott wants it before Christmas) (CNBC/Axios/Yahoo 11-17..18). Reuters/NYT 11-20: SEC probe into accounting practices (two sources briefed; no company comment in the excerpts read).
- **MEASURED. GTA VI launched 2026-11-19 and Take-Two reported $3.79B day-one retail sales** (32.5M units pre-release, Metacritic 99; company estimates through end of 11-19; Take-Two release 2026-11-20, WSJ/BBC). IBKR: TTWO 227.82 (11-13) to 210.00 (11-20), -7.8%, 208.65 on launch day (-3.7%) before the company figure. Take-Two's official Q3 guide (11-09) is net bookings $3.35-3.5B; retail sales are before console-store fees (INFERRED about 30% commonly reported, Take-Two does not publish it) so $3.79B is not directly comparable.
- **MEASURED. Earnings in the week:** PANW 11-18 revenue $3.44B (+39%, $3.31B expected), NGS ARR $9.73B (+66%), FY27 revenue guide raised to $14.52-14.57B, $4.5B Applied Compute acquisition (PANW IR; Benzinga; CNBC); IBKR PANW 309.29 (11-17) to 339.92 (11-18, +9.9%) to 361.73 (11-19), 343.32 on 11-20, week +6.5% (the only large name up besides CRWD). INTU 11-19 revenue $4.35B (+12%), non-GAAP EPS $2.91 vs $2.70, but Consumer and Credit Karma guidance cut ("faster-than-expected shift in consumer discovery toward AI tools"); the transcript summary has the stock -9.8% after hours from 310.02 (Investing.com; INTU not priced on IBKR here). HD 11-17 and WMT 11-19 as above; TGT 11-18 as above.
- **MEASURED (D1 2026-11-17 sector screen).** Seat-based software was routed on the Anthropic IPO launch and AI-agent displacement fears (CRM -9.4%, INTU -7.2%, NOW -6.6% on 11-17); IBKR CRM 217.84 (11-13) to 180.62 (11-20), -17.1%.
- **MEASURED (D1, 11-16..11-19).** AI-hardware selloff on a reported US plan to require licences for re-exports of advanced AI chips to Brazil, Singapore, Indonesia, Malaysia and Thailand (11-16, XLK -3.24%, SMH -5.11%); managed-care liquidation on the CMS RADV-extrapolation proposed rule (11-18/11-19); Brent 95.84 (11-13) to 92.76 (11-19), energy -3.27% on 11-18.
- **INFERRED.** A name's drop this week mostly tracks AI-capex/beta rather than a change in its own filings; PANW and CRWD (cyber demand) were the exceptions. The AI-financing channel (Anthropic's S-1/A-3 discloses a $42.0B convertible-note facility with Broadcom and $161.2B of lease rent; S&P (10-29) calls Broadcom's residual-value support "potentially a material liability") is the live counter-evidence for AVGO and, indirectly, ORCL, MRVL, MU and NBIS.
- **Gaps stated, not filled.** DIS/HD/TGT/WMT/INTU were read from release summaries and wire excerpts only (no 10-Q). No FMP call was made (instruction). FSLR news this week is secondary (Simply Wall St 11-22 on CEO congressional testimony and lawsuits; Trefis 11-18 on slowed new orders of 1.4 GW at about $0.36/W).

### Price context (IBKR regular-session daily bars via `get_price_history`, MEASURED; 11-13 and 11-20 closes)

15 names plus SPY priced (the instruction allowed up to 30; the remaining names were left unpriced to hold the call budget, and the per-name `search_contracts` lookups, not the bars, were the cost driver). Unpriced names carry no price claim below.

| Ticker | 11-13 | 11-20 | Wk chg | Note |
|---|---|---|---|---|
| SPY | 754.37 | 689.81 | -8.6% | 11-19 715.87; 11-20 range 686.75-718.29 on 83.5M shares |
| NVDA | 162.85 | 125.53 | -22.9% | 11-17 155.46 pre-print; 11-19 145.98; 11-20 -14.0% on 397M shares |
| FSLR | 171.39 | 137.59 | -19.7% | 11-20 -9.5%; 11-18 150.98 low close of week before bounce |
| AVGO | 347.01 | 304.41 | -12.3% | 11-20 -12.2% (343.01 open, low 301.02) |
| MU | 778.31 | 594.51 | -23.6% | 11-20 -13.9%; 811.30 on 11-11 |
| MRVL | 156.76 | 122.28 | -22.0% | 11-20 -11.7% |
| ORCL | 125.35 | 101.19 | -19.3% | 11-20 -8.5% |
| TTWO | 227.82 | 210.00 | -7.8% | 11-17 203.93 low; 11-18 216.61; 11-19 208.65 |
| CRWD | 226.61 | 229.44 | +1.2% | 11-19 243.46 high close on cyber demand read-through |
| CRM | 217.84 | 180.62 | -17.1% | 11-17 -9.5% on the software rout |
| VRTX | 538.60 | 515.02 | -4.4% | PDUFA 11-30 pending; range-bound defensive |
| SNOW | 291.00 | 254.82 | -12.4% | |
| DELL | 344.53 | 278.02 | -19.3% | 11-20 -11.0% |
| PANW | 322.24 | 343.32 | +6.5% | 11-18 +9.9% to 339.92; 11-19 361.73 |
| AMD | 534.06 | 424.39 | -20.5% | 11-20 -13.2% |
| CEG | 280.20 | 237.41 | -15.3% | 11-20 -5.8%; data-centre political risk |

### TOP-10 — the actionable tier

**Selection rule (stated for W4).** Only ADMISSIBLE, GATE-SURVIVING names with a DATED post-gate catalyst (a dated NVDA/TTWO substitute is named where the issuer print is not); direction-unresolved names (TGT, AMAT) and SPENT names are excluded from the tier. All ten rows are long. Zero SPENT names. All ten are QUEUED; none is NEW. Rank reflects conviction in a mispricing (price gap re-opened by the 11-20 crash against intact issuer documents), not momentum. **Risk statement for D2:** the whole tier is AI-beta; the regime is DO-NOT-ACTIVATE, VIX is 35.89, the S&P is in a correction and a December hike is priced, so sizing is D2's job, not this ranking's.

**1. FSLR - First Solar.** (a) Bullish (policy-protected US thin-film manufacturer). (b) Section 232 polysilicon proclamation (Federal Register 2026-16400, https://www.federalregister.gov/documents/2026/08/11/2026-16400/adjusting-imports-of-polysilicon-and-its-derivatives-into-the-united-states): 15% additional duty and minimum import prices (modules $0.38/W, cells $0.22/W, polysilicon $21/kg, ingots/wafers $100/kg) effective goods entered on/after 12:01 am ET **2026-12-04**; CBP activated simulated Chapter 99 test codes in ACE on 11-12 (GHY, https://www.ghy.com/trade-compliance/us-section-232-polysilicon-tariff/); BIS anti-stockpiling temporary rule runs 09-22 to 12-03 (BDO 10-07). FSLR's own Q3 release (10-29, https://www.businesswire.com/news/home/20261029415483/en/First-Solar-Inc.-Announces-Third-Quarter-2026-Financial-Results-Updates-Guidance-and-Announces-%24500-Million-Share-Repurchase-Program): net sales $1.23B (-23% y/y), net cash $1.5B, $500M buyback, "only fully-integrated utility-scale solar manufacturer without dependency on the Chinese crystalline silicon supply chain". Price 171.39 to 137.59 (-19.7%), the gap re-opened further. Counter-evidence: new orders slowed (about 1.4 GW at about $0.36/W since the last call, Trefis 11-18, secondary); customers deferring early-stage projects while they parse Section 232; tariff-disclosure lawsuits and CEO congressional testimony (Simply Wall St 11-22, secondary); policy can be reduced or modified by a future action. (c) **2026-12-04 (C, Federal Register)**. (d) QUEUED; no open position. (e) Top-10, conviction **3**. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2026-12-04)

**2. AVGO - Broadcom.** (a) Bullish. (b) Issuer notice 2026-11-09 (carried, https://investors.broadcom.com/news-releases/news-release-details/broadcom-inc-announce-fourth-quarter-and-fiscal-year-2026): FQ4 and FY2026 results **Wednesday 2026-12-09** after the close, call 2 pm PT. S&P (10-29): Broadcom expects AI revenue of $115B in FY27 and $230B in FY28, Anthropic 5 GW of TPUs in FY27 and 10 GW in FY28, OpenAI 1.3 GW in 2027; Q4 guide about $34.8B (W46, secondary). Price 347.01 to 304.41 (-12.3%; 11-20 -12.2%). Counter-evidence, and the reason conviction is 3 not higher: the Anthropic S-1/A-3 (https://www.sec.gov/Archives/edgar/data/2130357/000162828026074338/anthropicpbc-sx1ax3.htm) discloses up to $42.0B of convertible notes issuable to Broadcom and about $161.2B of lease rent, Broadcom's residual-value support peaks near $43B (Broadcom/BofA/Blackstone presentation 10-26), S&P applies about $8B of debt adjustment rising to about $41B in FY29 and calls RVS "potentially a material liability", CDS 133 bp (IFR 10-09); Anthropic itself fell about 9% on day two. (c) FQ4 **2026-12-09 (C)**. (d) QUEUED; no open position. (e) Top-10, conviction **3**. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2026-12-09)

**3. MU - Micron.** (a) Bullish. (b) FQ4 release 2026-09-30 (https://investors.micron.com/quarterly-results; carried): revenue $54.2B (+379%), FQ1 guide revenue $61.5B +/-$1.5B, non-GAAP gross margin about 86.25%, EPS $38.15 +/-$1.00. New this week: Micron's own notice (2026-11-19) fixes the FQ1 call for **Thursday 2026-12-17, 2:30 pm MT**. Price 778.31 to 594.51 (-23.6%; 11-20 -13.9%); Barron's 11-20: memory stocks "agonizingly cheap" (headline only, content gated). Counter-evidence: strategic long-term agreements cap spot capture; Micron is a named participant in Anthropic's $26.0B private placement (424B4, 11-19), so AI-financing exposure runs both ways; memory is capex-geared; the print is two weeks after the gate and the setup could still deteriorate. (c) FQ1 **2026-12-17 (C)** after the close (Micron IR). (d) QUEUED (queue row cites the consumed 09-30 print and the 12-16 (E) date; stale). No open position. (e) Top-10, conviction **3**. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2026-12-17)

**4. NVDA - NVIDIA.** (a) Bullish. (b) Q3 FY27 release 2026-11-17 (https://nvidianews.nvidia.com/news/nvidia-announces-financial-results-for-third-quarter-fiscal-2027): revenue $115.8B (+103%), Data Center $107.6B (+110%), non-GAAP EPS $2.68, Q4 guide $130.0B +/-3% (consensus $125.1B), gross margin guide 71-72%, no China compute assumed (so China is upside, not base); CFO commentary https://www.sec.gov/Archives/edgar/data/1045810/000104581026000088/q3fy27cfocommentary.htm. Call: FY28 growth outlook raised to about 75% from 70%, cloud backlog $2.5T from $2T (Fox Business, 11-18, secondary on the call), $150B buyback increase. Price 125.53 (-22.9% on the week), about 11.7x annualised Q3 non-GAAP EPS (INFERRED arithmetic: 125.53 / (2.68 x 4)). Counter-evidence, load-bearing: Reuters/NYT 11-20 report the SEC is probing Nvidia's accounting (two unnamed sources; scope and timing unknown, an event-risk that a long-only pre-catalyst thesis cannot size); Huang House interview 12-01, GC 12-02, Senate Banking hearing pending; permanent-CEO search with no timetable; customer-financing guarantees (Kress: guarantees apply only once a facility is ready); China export-licence policy (11-16 Bloomberg report, via D1). Fresh disclosure of accounting issues would invalidate the thesis. (c) **2026-12-01 (T; Huang closed-door House interview, a dated governance event, not an earnings date)**; next print 2027-02-24 (E, FMP). (d) QUEUED; no open position. (e) Top-10, conviction **2** (down from 3: the print resolved the demand question in the thesis' favour and the price fell 14% in a day, but an unquantified SEC accounting probe was reported after the print). GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2026-12-01)

**5. MRVL - Marvell Technology.** (a) Bullish (merger-reaction overshoot). (b) 8-K Item 1.01 2026-11-02: all-stock Lumentum acquisition at 4.500 MRVL per LITE share (carried; https://www.sec.gov/Archives/edgar/data/1835632/000119312526442717/d352474d8k.htm); Marvell notice (11-06): FQ3 FY27 call **Tuesday 2026-12-01, 1:30 pm PT** (https://investor.marvell.com/news-events/press-releases/detail/1041/marvell-technology-inc-announces-conference-call-to-review-third-quarter-of-fiscal-year-2027-financial-results). Price 156.76 to 122.28 (-22.0%). Counter-evidence: dilution and customer-conflict risk, merger closes H1 2028, AI-financing contagion; MRVL is a high-beta name inside an AI-capex unwind. Not re-researched beyond price and the Barron's/Reuters selloff reads this week. (c) FQ3 **2026-12-01 (C)** (the gate date itself, hence not SPENT: strictly-before test). (d) QUEUED; no open position. (e) Top-10, conviction **2**. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2026-12-01)

**6. ORCL - Oracle.** (a) Bullish. (b) $10B common-stock issuance, 86,206,897 shares (8-K Item 8.01, 11-04; https://www.sec.gov/Archives/edgar/data/1341439/000119312526447507/d131790d8k.htm, carried); funding structure (record CDS, OpenAI financing) is the live question. Oracle IR FAQ (https://www.oracle.com/corporate/investor_relations/faq.html): Q2 FY27 earnings "will be announced on December 14, 2026"; Oracle reaffirmed FY27 revenue of at least $90B and non-GAAP EPS $8.10 at its 10-28 Investor Day (factsdesk, secondary). Price 125.35 to 101.19 (-19.3%; 110.33 on 11-19 per MarketBeat). Counter-evidence: equity issuance dilution, leverage, AI-financing unwind; Q2 guide revenue growth 30-34% (EarningsMadness, secondary). (c) FQ2 **2026-12-14 (C, issuer FAQ text only; no dated release)** after the close (Oracle IR FAQ and Nasdaq; vendors say 12-09; no dated Oracle notice yet; either date is after the gate). (d) QUEUED; no open position. (e) Top-10, conviction **2**. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2026-12-14)

**7. TTWO - Take-Two Interactive.** (a) Bullish. (b) Issuer release 2026-11-20 (https://www.take2games.com/ir/news/grand-theft-auto-vi-shatters-entertainment-box-office-records): day-one retail sales **$3.79B** through end of 11-19 (company estimates), 32.5M units pre-release, Metacritic 99. FQ2 release 2026-11-09 (carried; http://www.take2games.com/ir/news/take-two-interactive-software-inc-reports-results-fiscal-4): FY27 net bookings $8.0-8.2B reiterated, FQ3 net bookings guide $3.35-3.5B, GTA VI pre-orders "far in excess of our initial expectations". Sensor Tower's day-one digital estimate was $2.36B (24.6M copies); BofA said about $1.9B in three days was the bar and under $1.5B a miss; Morgan Stanley kept Overweight and $280 target (247wallst 11-20, secondary). Price 227.82 to 210.00 (-7.8%) despite the record disclosure. Gap hypothesis (INFERRED): the guide of $3.35-3.5B was set before launch-day data and Take-Two has not raised it; the next scheduled update is the FQ3 print. Counter-evidence: retail sales are gross of console-store fees (Take-Two records net of fees; fee not published), NBA 2K27 and the base business were below forecast in FQ2 (net bookings -18% y/y), and a record day one invites a "sell the news" read. (c) Next print **undated** (early February INFERRED; no FMP/Nasdaq row); a first company sell-through update is expected by 11-23 per BofA (not a dated company commitment). (d) QUEUED (queue row cites 11-09, consumed). No open position. (e) Top-10, conviction **3**. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst undated)

**8. CRWD - CrowdStrike.** (a) Bullish (module attach, AI-driven cyber demand). (b) PANW's 11-18 print (NGS ARR +66%, record net new platformizations, FY27 revenue guide raised to $14.52-14.57B, "given the current threat environment... materially raising"; https://investors.paloaltonetworks.com/news-releases/news-release-details/palo-alto-networks-reports-fiscal-first-quarter-2027-financial) is a same-sector read-through (secondary for CRWD). Price 226.61 to 229.44 (+1.2%), the only top-10 name up on the week, so the price gap is NOT open: the thesis rests on the print itself. Counter-evidence: software multiples compressed on AI-displacement fears (CRM -17.1%), CRWD at 229 after a 243 high on 11-19; no CRWD-specific document was fetched this week. (c) FQ3 FY27 **2026-12-01 (C)** after the close (CrowdStrike release 2026-11-04, carried in PART 1A.1; Nasdaq agrees). (d) QUEUED; no open position. (e) Top-10, conviction **2** (thin evidence this week; included on a dated catalyst and the cyber-demand read-through). GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2026-12-01)

**9. CRM - Salesforce.** (a) Bullish (agentic-AI attach vs a compressed multiple). (b) No Salesforce filing fetched this week. D1 2026-11-17 records CRM -9.4% on the Anthropic IPO and agent-displacement fears; IBKR 217.84 to 180.62 (-17.1%). Counter-evidence is the thesis' own risk: the market is repricing seat-based software on AI substitution, and INTU's 11-19 note on a "faster-than-expected shift in consumer discovery toward AI tools" is a direct adverse data point for the sector. (c) FQ3 FY27 **2026-12-02 (C)** after the close (Salesforce release 2026-11-10, carried in PART 1A.1; Nasdaq EPS $2.41). (d) QUEUED; no open position. (e) Top-10, conviction **2** (low end; a gap hypothesis without a document this week). GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2026-12-02)

**10. SNOW - Snowflake.** (a) Bullish (Cortex AI monetisation). (b) No Snowflake filing fetched this week; Nebius's 11-12 letter names Snowflake among platforms signing multi-year AI-cloud agreements (secondary, carried); $3.5B convertible 09-28 (dilution, carried). IBKR 291.00 to 254.82 (-12.4%). Counter: software rout, dilution. (c) FQ3 FY27 **2026-12-02 (C)** after the close (Snowflake release 2026-11-02, carried in PART 1A.1). (d) QUEUED; no open position. (e) Top-10, conviction **2** (lowest in the tier; slot filled because AMD, ANET and the SPENT names are excluded by rule). GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2026-12-02)

### 11-20

Research-cost note: SPENT names get one-line gap theses (no (b) chase); survivors terse where evidence is unchanged.

**11. VRTX - Vertex Pharmaceuticals. SPENT.** (a) Bullish. Gap thesis (one line): priority-review povetacicept BLA (PDUFA 2026-11-30, RAINIER interim UPCR -49.8% vs placebo, p<0.0001) with the stock only -4.4% on the week at 515.02, but the binary resolves the day before A can next re-score. (c) **2026-11-30 (C)**. (d) QUEUED; no open position. (e) 11-20 tier (top of tier; would have been top-10 on conviction 3 but for the spent catalyst). GATE: SPENT-BY-GATE (gate 2026-12-01; catalyst 2026-11-30)

**12. DELL - Dell Technologies. SPENT.** (a) Bullish. Gap thesis: AI-server backlog ($95B, W46 secondary) vs a stock down 19.3% to 278.02 on AI-capex fear; FQ3 FY27 results precede the 2026-11-24 3:30 pm CST call (Dell IR notice, carried). (c) **2026-11-24 (C)**. (d) QUEUED; no open position. (e) 11-20, conviction 2. GATE: SPENT-BY-GATE (gate 2026-12-01; catalyst 2026-11-24)

**13. HPE - Hewlett Packard Enterprise. SPENT.** (a) Bullish; as DELL. Gap thesis: server/networking AI demand vs sector sell-off; FQ4 2026-11-23 after hours (Nasdaq EPS $1.17, 7 est.; EarningsMadness lists Mon 11-23 after close). (c) **2026-11-23 (E)**. (d) QUEUED; no open position. (e) 11-20, conviction 2. GATE: SPENT-BY-GATE (gate 2026-12-01; catalyst 2026-11-23)

**14. AMD - AMD.** (a) Bullish. (b) Q3 beat and Q4 guide about $17B +/-3% (W46, secondary summaries). Price 534.06 to 424.39 (-20.5%; 11-20 -13.2%). Counter-evidence: Schwab 11-20 cites "questions about ties AMD has to blacklisted Chinese firms" raising export-control scrutiny; lost the SpaceX compute socket to NVDA (carried); AMD is a named Anthropic private-placement participant. (c) Next print **2027-02-02 (E)** (FMP). (d) QUEUED. (e) 11-20, conviction **2**. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2027-02-02)

**15. PANW - Palo Alto Networks.** (a) Bullish. (b) Printed 11-18: revenue $3.44B (+39%), NGS ARR $9.73B (+66%), RPO $21.0B, FY27 guide raised (https://investors.paloaltonetworks.com/news-releases/news-release-details/palo-alto-networks-reports-fiscal-first-quarter-2027-financial); price 322.24 to 343.32 (+6.5%), gap largely closed. Counter: gross margin 75.2% (-170 bp), $4.5B Applied Compute acquisition. (c) Next print **undated** (late-February pattern INFERRED). (d) QUEUED. (e) 11-20, conviction **2** (from top-10 at W46: catalyst consumed). Timing note: PANW's IR notice said results after the close on 11-18 but IBKR shows the +9.9% move in the 11-18 regular session; the discrepancy is unresolved and immaterial to the ranking. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst undated)

**16. NTAP - NetApp.** (a) Bullish. (c) **2026-12-01 (C)** after hours (issuer, carried in PART 1A.1; Nasdaq EPS $2.13). No new document. (d) QUEUED. (e) 11-20, conviction 2. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2026-12-01)

**17. OKTA - Okta.** (a) Bullish. (c) **2026-12-01 (C)** after hours (issuer, carried in PART 1A.1; Nasdaq EPS $0.43). No new document. (d) QUEUED. (e) 11-20, conviction 2. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2026-12-01)

**18. ANET - Arista Networks.** (a) Bullish. (b) Q3 release (W46, https://www.sec.gov/Archives/edgar/data/0001596532/000159653226000252/ex991q326-earningsrelease.htm): revenue $3.66B (+58.5%), Q4 guide $3.9-4.0B. Not priced this week. (c) Next print **2027-02-10 (E)** (carried projection; no FMP row). (d) QUEUED. (e) 11-20, conviction **3** -> 2 (neck-and-neck with AMD; no AI-financing exposure disclosed in sources read). GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2027-02-10)

**19. CEG - Constellation Energy.** (a) Bullish. (b) Q3 release 2026-11-09 (carried): adjusted EPS $5.06, FY guide $12.50-12.80, up to $5B conditional DOE loan. Price 280.20 to 237.41 (-15.3%): data-centre political risk (Democratic midterm win, 38 of 39 data-centre referendums restricted per Reuters 11-04 via W46) now in the price. (c) Next print **undated** (late-February INFERRED). (d) QUEUED. (e) 11-20, conviction **2**. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst undated)

**20. INTU - Intuit.** (a) Bullish, reduced. (b) Printed 11-19 (https://investors.intuit.com/news-events/press-releases/detail/1331/intuit-reports-first-quarter-results-and-enters-agreement-to-sell-mailchimp-to-bending-spoons): revenue $4.4B (+12%), non-GAAP EPS $2.91, GBS +15%, Online Ecosystem +20%, mid-market +41%; FY27 EPS guide reiterated ($22.88-23.12 non-GAAP), Consumer and Credit Karma guides cut, Mailchimp sale to Bending Spoons (close early 2027), $1.5B buyback in Q1. After-hours reaction about -9.8% to 279.56 from 310.02 (Investing.com; not IBKR-priced). Gap hypothesis (INFERRED): a beat on a reiterated EPS guide with a consumer-only cut priced as a regime change; counter: the cut is attributed to AI substituting for consumer discovery. (c) Next print **undated** (late-February INFERRED). (d) QUEUED. (e) 11-20, conviction **2**. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst undated)

### 21-30

- **21. NBIS - Nebius.** (a) Bullish. Q3 11-12: revenue $980.8M, 2026 revenue at the low end of $3.0-3.4B (W46 read of the issuer letter); CNBC 11-18: whipsawed and ended 11-18 +0.87%; Yahoo 11-20: about -9% with CoreWeave. (c) Next print **undated**. (d) QUEUED. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst undated)
- **22. LRCX - Lam Research. NEW.** (a) Bullish. Dec-quarter guide $8.6B +/-$0.4B (W46, secondary); AMAT's 11-12 record print supports WFE demand (W46). Not priced. (c) Next print **undated** (late January INFERRED). (d) **NEW**. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst undated)
- **23. ETN - Eaton. NEW.** (a) Bullish. Q3 sales $8.9B (+28%), data-centre revenue about +65%, 2026 EPS guide $13.70-13.80 (W46, https://www.sec.gov/Archives/edgar/data/0001551182/000155118226000037/etn09302026exhibit99.htm). Counter: data-centre moratoria. (c) Next print **undated**. (d) **NEW**. (e) conviction 3 -> 2 (AI-power risk now in the price, unmeasured here). GATE: GATE-SURVIVING (gate 2026-12-01; catalyst undated)
- **24. SMCI - Super Micro.** (a) Bullish. FQ1 FY27 net sales about $19.9B, GAAP gross margin 12.7%, cash outflow $434M (W46). (c) Next print **2027-02-02 (E)** (carried projection). (d) QUEUED. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2027-02-02)
- **25. QCOM - Qualcomm.** (a) Bullish, reduced. FQ4: handset -26.2%, FQ1 guide $10.4-11.2B (W46, secondary). (c) Next print **undated**. (d) QUEUED. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst undated)
- **26. DIS - Disney. NEW.** (a) Bullish; SVOD margin. Printed 11-17 (Nasdaq EPS $1.67 expected); result not read this run (no web call spent). (c) Next **2027-02-01 (E)** (FMP). (d) **NEW**; two open Strategy D lots. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2027-02-01)
- **27. AMZN - Amazon.** (a) Bullish. AWS +39.3% (carried); D1 11-19 AMZN -3.87%. re:Invent 2026-11-30..12-04 (E, not re-checked) sits mid-window; next print 2027-02-04 (E, FMP). (c) next print as stated. (d) QUEUED; two open Strategy D lots. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2027-02-04)
- **28. GOOGL - Alphabet.** (a) Bullish. D1 11-19: GOOGL -3.46% as Anthropic (Alphabet holds a stake) gave back its day-one pop; Google is also in Anthropic's $26B private placement (424B4). (c) Next print **2027-02-03 (E)** (FMP). (d) QUEUED; **two open Strategy D lots**. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2027-02-03)
- **29. MSFT - Microsoft.** (a) Bullish. 10-28 beat consumed; Ignite 11-17..20 consumed (E, not re-checked); Stocktwits 11-19 had MSFT +1.6% on GTA VI/Xbox. (c) Next **2027-01-27 (E)** (FMP). (d) QUEUED. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2027-01-27)
- **30. AAPL - Apple.** (a) Bullish. FQ4 consumed (11-02). (c) Next **2027-02-04 (E)** (FMP). (d) QUEUED. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2027-02-04)

### 31-40

- **31. PLTR - Palantir. NEW.** (a) Bullish. Q3 revenue about $2.31B (+96%) (W46 secondary). (c) Next **2027-02-01 (E)** (FMP). (d) **NEW**. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2027-02-01)
- **32. UBER - Uber. NEW.** (a) Bullish. Q3 gross bookings $59.8B (+20%), Q4 guide $63.25-65.25B (W46). (c) Next **2027-02-03 (E)** (FMP). (d) **NEW**; open Strategy D lot. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2027-02-03)
- **33. DDOG - Datadog.** (a) Bullish, reduced. Flat Q4 guide on a largest-customer assumption; -14.4% on 11-04 (W46). **Open Strategy B position in DDOG: A and B cannot hold the same name; any A thesis is blocked until the B lot closes.** (c) Next print **undated**. (d) QUEUED; **open B position**. (e) conviction 2 -> 1 (position conflict). GATE: GATE-SURVIVING (gate 2026-12-01; catalyst undated)
- **34. CSCO - Cisco.** (a) Bullish. 11-12 print consumed (record revenue $18.5B, FY27 guide raised, W46). (c) Next **2027-02-10 (E, FMP)**. (d) QUEUED. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2027-02-10)
- **35. SHOP - Shopify. NEW.** (a) Bullish. (c) Next **2027-02-10 (E)** (FMP). (d) **NEW**. (e) conviction 1-2. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2027-02-10)
- **36. JPM - JPMorganChase.** (a) Bullish. 10-13 miss (carried). (c) **2027-01-14 (E)** (FMP). (d) QUEUED. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2027-01-14)
- **37. META - Meta Platforms.** (a) Bullish, reduced; capex floor and negative FCF (carried). (c) **2027-01-27 (E)** (FMP). (d) QUEUED. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2027-01-27)
- **38. GE - GE Aerospace. NEW.** (a) Bullish. Printed 10-20. (c) **2027-01-21 (E)** (FMP). (d) **NEW**. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2027-01-21)
- **39. MRNA - Moderna. NEW.** (a) Bullish; vaccine-policy report carried as adverse. (c) Next **2027-02-12 (E)** (FMP). (d) **NEW**. (e) conviction 1-2. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2027-02-12)
- **40. COP - ConocoPhillips.** (a) Bullish, thesis weakened (Brent 95.84 to 92.76 over 11-13..11-19; XLE -3.27% on 11-18 per D1). (c) Next **2027-02-10 (E)** (carried projection). (d) QUEUED. (e) conviction 2 -> 1-2. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2027-02-10)

### 41-50

- **41. LLY - Eli Lilly.** (a) Bullish. Printed 10-29. (c) Next **undated** (early February INFERRED). (d) QUEUED. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst undated)
- **42. XOM - ExxonMobil.** (a) Bullish. (c) **2027-01-29 (E)** (FMP). (d) QUEUED. (e) conviction 1-2. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2027-01-29)
- **43. CVX - Chevron.** (a) Bullish. (c) **2027-01-29 (E)** (FMP). (d) QUEUED. (e) conviction 1-2. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2027-01-29)
- **44. INTC - Intel.** (a) Bullish. 10-29 print then -28.6% (carried). (c) **2027-01-28 (E)** (FMP). (d) QUEUED. (e) conviction 1-2. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2027-01-28)
- **45. CAT - Caterpillar.** (a) Bullish. Printed 10-29 (carried). (c) Next **undated**. (d) QUEUED. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst undated)
- **46. GEV - GE Vernova.** (a) Bullish. D1 11-16: GEV -4.93%, VRT/BE/ROK also down on the data-centre-power capex unwind. (c) Next **undated**. (d) QUEUED; **open Strategy D lot**. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst undated)
- **47. SNDK - Sandisk. NEW.** (a) Bullish. FQ1 EPS $49.51 vs $46.19 (carried); D1 11-16: SNDK -8.58%. (c) Next **undated**. (d) **NEW**. (e) conviction 1. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst undated)
- **48. RDDT - Reddit. NEW.** (a) Bullish. Q3 EPS $1.40 vs $1.31 (carried). (c) Next **undated**. (d) **NEW**. (e) conviction 1. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst undated)
- **49. AMAT - Applied Materials. DIRECTION UNRESOLVED.** (a) Direction unresolved (W46: bearish thesis contradicted by the 11-12 record print; no bullish gap established). Ineligible for the top-10. (c) Next print **undated** (February pattern INFERRED). (d) QUEUED. (e) 41-50, conviction 1. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst undated)
- **50. TGT - Target. DIRECTION UNRESOLVED.** (a) Direction unresolved: prior bearish thesis refuted by the 11-18 beat-and-raise (comps +5.6%, FY sales about +6%, EPS $10.65-11.40 including about $2.14 of tariff refunds); +4.0% on the day to 165.93 and 167.46 on 11-19 (money365). No replacement thesis. Ineligible for the top-10. (c) Next print **2027-03-02 (E)** (FMP). (d) QUEUED. (e) 41-50, conviction 1. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2027-03-02)

### DIRECTION-INADMISSIBLE tier

Belong to Strategy B. The rail governs only admission to the actionable tier. None is in the top-10; none may be converted to an A `PENDING_ANALYSIS` row.

- **I-1. ADBE - Adobe.** `DIRECTION-INADMISSIBLE (A long-only rail)`. (a) Bearish (AI-disruption of seat-based software; the 11-17 software rout, CRM -9.4% and INTU -7.2%, and INTU's 11-19 consumer-AI-discovery comment are supportive). (b) No Adobe document read this run. (c) Earnings **2026-12-09 (C)** (issuer-confirmed per W46; Nasdaq and FMP agree). (d) On queue. (e) Inadmissible, conviction 2. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2026-12-09)
- **I-2. HD - Home Depot.** `DIRECTION-INADMISSIBLE (A long-only rail)`. (a) Bearish / neutral (housing turnover starved). (b) Q3 FY26 release 2026-11-17 (https://ir.homedepot.com/news-releases/2026/11-17-2026-110221331): sales $43.4B (+4.9%), comps +2.2%, adjusted EPS $3.86 vs $3.74, FY guide: comps about 1.4%, gross margin about 33.0% (from about 33.1%), EPS growth about 1.5%; stock -2.45% to 339.01 on 11-17, 336.68 on 11-19. (c) Printed 11-17; next print **undated** (late-February INFERRED; no FMP/Nasdaq row). (d) On queue. (e) Inadmissible, conviction 1. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst undated)
- **I-3. WMT - Walmart.** `DIRECTION-INADMISSIBLE (A long-only rail)`. (a) Bearish, thin (low-income consumer; staples relative strength is contrary; weaker GLP-1 contribution; raised guide still below consensus sales of $752.65B). (b) Q3 FY27 release 2026-11-19 (https://www.sec.gov/Archives/edgar/data/104169/000010416926000168/earningsreleasefy27q3.htm): revenue $188.8B (+5.2%), adjusted EPS $0.65 vs $0.64, Walmart U.S. comps +2.9%, e-commerce +17% (US +23%), FY27 adjusted EPS $2.84-2.89; stock 126.04 (-1.04%). The print does not support a bearish case, so conviction stays 1. (c) Printed 11-19; next **2027-02-18 (E)** (FMP). (d) On queue. (e) Inadmissible, conviction 1. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2027-02-18)
- **I-4. AKAM - Akamai.** `DIRECTION-INADMISSIBLE (A long-only rail)`. (a) Bearish / contested; printed 11-05, result not read. (b) No new evidence read. (c) Next print **undated** (no FMP/Nasdaq row). (d) On queue. (e) Inadmissible, conviction 1. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst undated)
- **I-5. CCL - Carnival.** `DIRECTION-INADMISSIBLE (A long-only rail)`. (a) Bearish (bunker-fuel channel); D1 11-19: cruise lines RCL -5.5%, NCLH -5.1%. (b) No new filing read. (c) Earnings **2026-12-18 (E)** (FMP and Nasdaq). (d) Not queued. (e) Inadmissible, conviction 1-2. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2026-12-18)
- **I-6. UAL - United Airlines.** `DIRECTION-INADMISSIBLE (A long-only rail)`. (a) Bearish (fuel-shock channel; Brent now lower at 92.76, so this thesis is weakening). (b) No new evidence read. (c) Next **2027-01-19 (E)** (FMP). (d) Not queued. (e) Inadmissible, conviction 1. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2027-01-19)
- **I-7. AAL - American Airlines.** `DIRECTION-INADMISSIBLE (A long-only rail)`. (a) Bearish (thinnest balance sheet; same fuel seam, weakening). (b) No new evidence read. (c) Next **2027-01-26 (E)** (FMP). (d) Not queued. (e) Inadmissible, conviction 1. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2027-01-26)
- **I-8. DAL - Delta Air Lines.** `DIRECTION-INADMISSIBLE (A long-only rail)`. (a) Bearish, same seam. (b) No new evidence read. (c) Next **2027-01-13 (E)** (FMP). (d) Not queued. (e) Inadmissible, conviction 1. GATE: GATE-SURVIVING (gate 2026-12-01; catalyst 2027-01-13)

### Handoff notes for W4

- **TOP-10 (all admissible, long, all QUEUED, zero NEW):** 1 FSLR, 2 AVGO, 3 MU, 4 NVDA, 5 MRVL, 6 ORCL, 7 TTWO, 8 CRWD, 9 CRM, 10 SNOW. Zero direction-inadmissible names in the tier; zero SPENT names in the tier. W4 carries the GATE literal verbatim on every A-queue row.
- **Tier changes vs W46:** VRTX 1 -> 11, DELL 6 -> 12 and HPE 21 -> 13 (all three SPENT: catalysts 11-23/11-24/11-30 fall before the 12-01 gate); PANW 10 -> 15, CSCO 11 -> 34, CEG 12 -> 19 (catalysts consumed or undated); FSLR 2 -> 1, AVGO 8 -> 2, MU 5 -> 3 (gaps re-opened by the 11-20 crash, dated post-gate catalysts, MU now (C)); NVDA 3 -> 4 (conviction 3 -> 2 on the SEC-probe report); MRVL 7 -> 5; ORCL 9 -> 6; TTWO 4 -> 7; CRWD 24 -> 8, CRM 27 -> 9, SNOW 28 -> 10 (refill on dated 12-01/12-02 catalysts). AMD 13 -> 14, ANET 14 -> 18, INTU 22 -> 20.
- **NEW (not on the census), admissible:** ETN, LRCX, PLTR, UBER, SHOP, DIS, MRNA, GE, SNDK, RDDT (10 of 50); none is in the top-30 above rank 22. Inadmissible and not queued: UAL, AAL, DAL, CCL.
- **Stale queue-row payloads to overwrite:** MU row (09-30 print and 12-16 (E)) -> live catalyst 2026-12-17 (C); ORCL row 12-09 (E) -> 12-14 (C, issuer FAQ only); TTWO row 11-09/11-19 -> GTA VI launched, $3.79B day-one, catalyst undated; NVDA row 11-17 -> consumed, live dated item 2026-12-01 (T) plus SEC probe; PANW row 11-18 -> consumed, undated; INTU row 11-19 -> consumed, undated; HPE/DELL/VRTX rows -> SPENT marks; AVGO 12-09 (C) unchanged; DDOG row -> flag open B position (A/B same-name exclusion).
- **Cross-strategy overlap:** no A or C position, so no A/C conflict. **DDOG has an open B position (A/B same-name exclusion applies).** Open D lots: AMZN (#27), GOOGL (#28), GEV (#46), DIS (#26), UBER (#32). B also holds names not on this shortlist.
- **Regime and sizing context for D2 (MEASURED, 11-20):** S&P in correction, VIX 35.89, 10-year about 4.9-5%, December hike priced at about 92-95%. The A router reads DO-NOT-ACTIVATE; any thesis here is pre-catalyst research, and the 2026-12-01 re-score is the first reachable activation.
- **Re-check next cycle:** NVDA SEC probe, 12-01 House interview and 12-03 Senate hearing, CEO search; MRVL/CRWD/NTAP/OKTA 12-01; CRM/SNOW 12-02; FSLR 12-04 go-live; AVGO 12-09 and the FOMC the same day; ORCL (12-14 vs 12-09 date); MU 12-17; TTWO's first official sell-through/guidance update; DELL/HPE/VRTX outcomes (spent names re-promote only if the gate moves behind their catalyst); next-print dates for CEG, ETN, NBIS, QCOM, LRCX, DDOG, LLY, CAT, GEV, AMAT, SNDK, RDDT, PANW, INTU, HD, AKAM.
- **Not done:** unpriced on IBKR this week (carry no price claim): ANET, HPE, INTU, NBIS, LRCX, ETN, SMCI, QCOM, DIS, AMZN, GOOGL, MSFT, AAPL and all names below rank 30; no document chase for CRM, SNOW, NTAP, OKTA, DIS; issuer-IR date confirmation is PART 1's (dates above reconciled to PART 1A.1 by the orchestrator).

### REPORT IT — CATALYST-GATE MODE

- **Gate date: 2026-12-01.** Inputs: (a) next scheduled re-score 2026-12-01 (completed `M1a` = 1, `M1b` = 1 this month); (b) no open `regime-refresh` item; (c) the REFRESH REQUEST query returned 0 rows (M1R drained `regime-refresh-20261119` on 2026-11-22, no axis moved). A reads DO-NOT-ACTIVATE; mode live.
- **Counts:** 58 carried (50 ranked admissible incl. direction-unresolved TGT and AMAT + 8 DIRECTION-INADMISSIBLE); **3 SPENT-BY-GATE (HPE, DELL, VRTX), 55 GATE-SURVIVING.** Undated survivors (fail-open): 17 (CEG, ETN, NBIS, QCOM, LRCX, DDOG, LLY, CAT, GEV, AMAT, SNDK, RDDT, TTWO, PANW, INTU, HD, AKAM).
- **Narrowest survivors:** none before the gate; first after: MRVL, CRWD, NTAP, OKTA 2026-12-01; NVDA governance item 2026-12-01; CRM, SNOW 2026-12-02; FSLR 2026-12-04.
- **Research-cost:** top-10 rows carry full (a)-(e) with a document re-read or newly cited this week for 7 of 10 (FSLR, AVGO, MU, NVDA, TTWO, ORCL, MRVL partial); CRWD, CRM, SNOW are thin by design; SPENT rows one-line. Parallel calls used: **9** (web_search only, budget 20); IBKR priced: **15 names plus SPY** (budget 30).

## PART 2C — Strategy C ranked shortlist

### Router state, and what it admits

C reads **HYBRID ACTIVATE (FOMC-only)** (div-C-202611-1; orchestrator-MEASURED; A and D DO-NOT-ACTIVATE; B and E "DO-NOT-ACTIVATE — PENDING div-B/E-202611-3", held state 2026-11-18). Under it **only an FOMC-class event is router-admissible**. Every earnings and PDUFA candidate below is ranked for the divergence record and for the day C is widened, and is marked **router-PARKED (not router-admissible), not to be enqueued**.

`state.open_queue` strategy C holds **one row** (orchestrator-MEASURED): `thesis-FOMC-C-20261130` (thesis-construction, FOMC, due **2026-11-30**), for the 2026-12-09 FOMC. **W4 must not create a duplicate FOMC row.** This row IS candidate 1. Its conservative default is "decline, no entry" unless an affirmative, sourced, quantified divergence is established. Last permitted entry day is **Tuesday 2026-12-08** (criterion 5: entry at least 1 trading day before the event). Delta vs W46: queue unchanged; the meeting is 17 days out.

### The capital position (orchestrator-MEASURED)

| Field | Value |
|---|---|
| Strategy C NAV (`analytics.strategy_nav`) / available | **$18.55 / $18.55** (unchanged) |
| 2% sizing base | $0.37 |
| Deployed | $0 |
| Open C positions / open A positions | none / none |
| Open B | ROK IRTC ARQT RVMD RELY ANDE DDOG EXPE NRIX MTRN ECG SYY SM MCY |
| Open D | ISRG DIS AMZN GOOGL GEV RTX TSM UBER |
| `state.open_queue` strategy C | 1 row (`thesis-FOMC-C-20261130`) |

Per-thesis sizing discipline (Rev 43/19): max loss including the cascade term must not exceed the thesis's stated risk budget; a long debit structure's max loss equals its debit. With a whole portfolio of $18.55 the test is whether the cheapest defined-risk structure debits at or below $18.55. Credit spreads, iron condors and butterflies need collateral of width less credit and are unfundable at this size. **Every candidate below is a deferral at current NAV; each (d) says so.** Borrow-blocked status and donor capacity were not re-read this part (carried from W45).

### Regime context (orchestrator facts, plus web-sourced detail read this run)

VIX 28.44 (11-19), 35.89 FMP EOD 11-20. SPY closed **689.81 on 11-20** (-3.64% on the day, -8.6% on the week from 754.37). Web-sourced (Parallel, 2026-11-22, E-tagged secondary except the minutes): Investrade and Schwab put the S&P 500 at 6,910.39 (-3.70%), a seventh straight down day, the Nasdaq Composite -5.28% and into the red for 2026, VIX closing 37.43 after touching 40.03 (Investrade; the FMP EOD figure differs, flagged), NVDA -14.0% (SEC accounting probe headline), memory names (MU, SNDK, STX) down more than 12%. This is an AI-financing and hawkish-Fed unwind with rates falling on the day (10-year 4.92%, -13 bp).

### Criterion 1 (a qualifying event within 45 days)

Window **2026-11-22 to 2027-01-06**. Event dates are taken from PART 1 (`part1.md`, the date agent's output, read this run, not re-searched here) except where stated.

- **FOMC 2026-12-09, decision 2:00 pm ET plus SEP/dots, press conference 2:30 pm ET (C-carried; PART 1B refreshed from federalreserve.gov calendars page "December 8-9").** Minutes of the Dec meeting 2026-12-30.
- **Earnings (router-PARKED), dates from PART 1 (C unless stated):** HPE 11-23 AMC; DELL 11-24 AMC (call 3:30 pm CST); ADI 11-24 BMO; CRWD and MRVL 12-01 AMC; CRM and SNOW 12-02 AMC; AVGO and ADBE 12-09 AMC (same day as the FOMC); COST 12-10 AMC; ORCL 12-14 AMC (issuer FAQ page, no dated release; a vendor still shows 12-09 estimate); **MU 12-17 (C; Micron release 2026-11-19, Nasdaq's 12-16 is one day wrong)**.
- **PDUFAs (router-PARKED):** VRTX povetacicept 2026-11-30 (C carried; no FDA action seen as of PART 1); COGT bezuclastinib GIST 2026-11-30 and NonAdvSM 2026-12-30 (C carried).
- **Struck since W46:** NVDA 11-17, HD 11-17, PANW 11-18, WMT 11-19 (printed). **CAPR deramiocel PDUFA 11-22: Complete Response Letter announced 11-20 (PART 1B).** **SMMT ivonescimab: CRL dated 2026-11-13 (PART 1B)**, so W46's UNRESOLVED flag is closed. **SVRA molgramostim goal date 11-22 missed by FDA, no revised date** (PART 1B; unranked, undated). Entry-window note: **HPE (event 11-23) cannot satisfy criterion 5 any more** (last entry day was Fri 11-20); DELL and ADI (event 11-24) have Monday 11-23 as their only entry day.

### The tenor rail: CLEAR, tenth cycle running

C requires structure expiration within 1-45 days of entry. MEASURED from live SPY option parameters (IBKR underlying 756733, read 2026-11-22): listed expiries include 11-23, 11-24, 11-25, 11-27 (SPY and 2SPY), 11-30, 12-01..12-04, 12-07, **12-11 (SPY and 2SPY)**, 12-18 (regular), 12-24 (SPY and B1SPY), 12-31, then 2027-01-15 monthly.

- **FOMC 12-09:** no 12-10 expiry lists, so **the first listed expiry strictly after the event is 2026-12-11** (2 calendar days after). From a Monday 11-23 entry that is 18 days; from the last permitted entry day 12-08 it is 3 days: inside 1-45 either way. 12-31 is 38 days from 11-23. Rail: CLEAR, no deferral on tenor.

### Criterion 2 (implied vs realized): MEASURED on the spec window

Headline is **IV/HV30** per `strategy/05_strategy_c.md`; HV10 and HV20 are context only. Realized vol = annualized close-to-close log returns, sample stdev x sqrt(252), from **IBKR regular-session daily bars** (`outside_rth` false), last close **Friday 2026-11-20**, computed in python. HV30 = 30 returns over 31 closes (SPY: 10-08 to 11-20; the 34-bar pull starts 10-06); HV20 = 21 closes; HV10 = 11 closes. Implied-move comparator = 0.8 x HV30 x sqrt(T/365), T = calendar days from 2026-11-22 to expiry. "Contract IV" is IBKR `implied_vol` where `is_valid` TRUE; "30d IV" is IBKR `implied_vol_underlying` (30-day constant-maturity, includes any event inside its horizon, so NOT event-isolated). Option quotes: IBKR snapshots read 2026-11-22 ~19:35Z, market closed; the books are Friday's close but the legs carry different timestamps, so put-call arithmetic is approximate. IBKR's own `historical_vol` field (SPY 16.5%, DELL 104.9%) uses an undisclosed window and is NOT used.

**FOMC instrument: SPY.** SPY closed **689.81** (-3.64%). SPY 2026-12-11 690 call 23.71/24.02 and put 19.02/19.38; straddle mid **$43.07** ($4,307 per straddle), 6.24% of spot (INFERRED-quality: **the legs are stale relative to each other** since call minus put mid is 4.67 against ~1.2 expected from put-call parity, so trust IV over the straddle mid). **Contract IV 32.32% (valid; both legs), `option_midpoint_iv` invalid.** SPY 30d IV **30.88%** (valid). IV-implied move (0.8 x IV x sqrt(19/365)) = 5.90% against a realized-equivalent of **4.09%** (0.8 x HV30 22.4%).

| SPY window | Closes (returns) | Realized vol | IV/HV (contract IV 32.32%) | IV/HV (30d IV 30.88%) |
|---|---|---|---|---|
| **HV30 (spec)** | 31 (30) | **22.4%** | **1.44** | 1.38 |
| HV20 | 21 (20) | 26.5% | 1.22 | 1.17 |
| HV10 | 11 (10) | 27.0% | 1.20 | 1.14 |

**Delta vs W46** (11-13 basis): HV30 18.9% to **22.4%**; headline ratio **0.80 to 1.44** (contract IV 15.1% to 32.3%). The sign has flipped: SPY options now price MORE vol than the trailing 30 days delivered, after the 11-16..11-20 collapse (VIX 19.9 to 37.4). INFERRED: the ratio is event-inflated (the 12-11 expiry spans the FOMC plus a 3.6% shock regime) and mean-reverts only if realized stays high; HV10 27.0% already exceeds HV30 less than the VIX regime would suggest. **Snapshot caveat:** IBKR `last` for SPY was 697.49 (after-hours print, +1.1% vs the 689.81 bar close); the bar close is used as spot.

**Market-implied policy path vs Fed communications (the divergence leg), web-sourced 2026-11-22, E-tagged except where primary.**
- **Priced (CME FedWatch via secondary pages):** 25 bp hike to 4.00-4.25% about **92%**, hold about 8% after Friday's flight to safety (Yahoo Finance live blog 11-20: 91.8%, "hold 8%, up from nil"; Schwab 11-20: 92%, two or more hikes by June above 80%); 50 bp hike 3-10% on 11-17..11-19 readings (Seoul Economic Daily 96.9/3.1 on 11-17, 92.7/7.3 on 11-18; Trading Economics 90/10 on 11-19; Kalshi 7 cents for "larger move" on 11-18). **Sources conflict on 11-20:** Investrade quotes a 99% 25 bp probability (labelled by it "CME FedWatch" after Goolsbee remarks); treated as an outlier against three sources, flagged.
- **Fed communications (primary: federalreserve.gov minutes of 10-27/28, released 2026-11-18):** "almost all participants judged ... further action to raise the target range ... would likely be appropriate"; "some participants favored an increase of 25 basis points" in October; 10-2 vote with Cook and Hammack dissenting for a hike; "a few ... a close call"; and (secondary quotes of the minutes) "a couple of participants noted that an increase of more than 25 basis points could warrant consideration at the next meeting if incoming inflation data were unfavorable". The Desk survey median expects one hike in December and one in March 2027; futures imply two more by summer 2027.
- **Speakers since:** Waller on CNBC 11-18: a 50 bp hike "probably necessary" in December, or 25 bp with a clear January signal ("shock people"); Cook 11-20: risk of getting "behind the curve" if the Fed does not raise now (Yahoo live blog); Williams 11-17: situation does not call for "dramatic action" (Axios via Admiral Markets); Goolsbee 11-20: a larger hike remains on the table (Investrade, secondary). October CPI +0.4% m/m, core 0.3% vs 0.2% forecast; PCE 3.6% y/y (staff, minutes), core 3.1%.
- **Where documents and pricing diverge (hypothesis only; W1 does not form a view):** (i) the **50 bp tail** (priced 3-10%) against Waller, "a couple" in the minutes and a hot October CPI; (ii) the **hold tail** (about 8% after the AI-driven equity break) against a minutes record and Cook that lean the other way; (iii) **equity vol** (SPY IV 32.3%) against a Fed whose near-term path is almost fully priced, so the event's SEP/dots and January guidance carry the information. The Fed's own caution is the counter: the minutes call the October decision "a close call" and Williams, the vice chair, argues against dramatic action. A weak-equity regime could also make a 25 bp-plus-January-signal outcome the modal case.

**Cheapest defined-risk SPY structure for 12-09:** **not measured this run.** Only the 690 strike was pulled (the get_option_data strike filter returned a single strike for the range). Single-leg 690 call ask **$24.02 = $2,402**; a 690/691 call debit spread is INFERRED at roughly $0.50 x 100 = ~$50 (delta ~0.5 per $1 width; not a chain read). Against NAV $18.55 even the INFERRED minimum is a shortfall of ~$30. **Deferral stands** (last week's measured $133 spread was likewise unaffordable).

**Panel: ATM IV and implied-vs-realized for each name.** All earnings/PDUFA rows are router-PARKED; pricing measurement only. "Spr" is leg bid/ask spread as a share of mid.

| Name | Event (tag) | Expiry (T) | Spot (11-20 close) | Contract IV / 30d IV | HV30 / HV20 / HV10 | IV/HV30 | Note |
|---|---|---|---|---|---|---|---|
| SPY | FOMC 12-09 (C-carried) | 12-11 (19) | 689.81 | 32.3% (valid) / 30.9% | 22.4 / 26.5 / 27.0 | **1.44** (30d 1.38) | straddle $43.07, stale legs |
| DELL | earnings 11-24 AMC (C) | 11-27 (5) | 278.02 | 149.3% (valid) / 107.8% | 100.7 / 111.2 / 104.6 | **1.48** (30d 1.07) | 280 straddle $45.70 ($4,570), 16.4% of spot vs realized-equivalent 9.4%; Spr ~2-4%; last 286.18 after hours |
| MRVL | earnings 12-01 AMC (C) | n/m | 122.28 | n/m / 95.1% | 110.2 / 125.2 / 108.1 | 0.86 (30d) | 11-20 -11.7%; the LITE all-stock merger (announced 11-02) confounds |
| CRWD | earnings 12-01 AMC (C) | n/m | 229.44 | n/m / 85.3% | 64.0 / 61.7 / 61.7 | 1.33 (30d) | last 218.34 after hours; press reports (via Stock Titan, E) CrowdStrike in talks to buy Zscaler, no deal agreed |
| CRM | earnings 12-02 AMC (C) | n/m | 180.62 | n/m / 66.6% | 43.4 / 42.7 / 52.6 | 1.53 (30d) | -17.1% over 5 sessions |
| SNOW | earnings 12-02 AMC (C) | n/m | 254.82 | n/m / 93.0% | 58.4 / 57.8 / 54.7 | 1.59 (30d) | |
| AVGO | earnings 12-09 AMC (C), same day as FOMC | n/m | 304.41 | n/m / 77.3% | 72.9 / 86.2 / 100.5 | 1.06 (30d) | -12.2% on 11-20 |
| ADBE | earnings 12-09 AMC (C), same day as FOMC | n/m | 217.71 | n/m / 65.0% | 38.7 / 29.8 / 33.3 | **1.68** (30d) | |
| COST | earnings 12-10 AMC (C) | n/m | 1,102.15 | n/m / 29.6% | 21.0 / 21.8 / 14.8 | 1.41 (30d) | only name near its high |
| ORCL | earnings 12-14 AMC (C, issuer FAQ) | n/m | 101.19 | n/m / 87.7% | 76.6 / 84.1 / 73.8 | 1.14 (30d) | 11-20 -8.5%; 30d IV covers the event only if 12-14 holds |
| MU | earnings 12-17 (C) | n/m | 594.51 | n/m / 69.9% | 97.9 / 114.2 / 111.5 | **0.71** (30d) | 12-17 sits at day 25, inside the 30d IV; 11-20 -13.9% |
| VRTX | PDUFA 11-30 (C carried) | n/m | 515.02 | not read | 32.0 / 29.3 / 16.0 | n/m | binary |
| ADI, HPE, COGT | 11-24, 11-23, 11-30 / 12-30 | n/m | not read | not read | not read | n/m | not measured (underlying cap of 15 and call budget) |

**Reads.** (1) **Every measured IV/HV30 ratio except MRVL (0.86) and MU (0.71) is above 1.0**, the reverse of W46 (where 5 of 10 were below 1.0), because implied vol re-rated up faster than 30-day realized vol after the 11-20 break; HV10 exceeds HV30 on 7 of 11 equities, so the 30-day window still understates current realized vol for the semis names. (2) **DELL**: the 11-27 straddle is 16.4% of spot against a realized-equivalent of 9.4%; the contract IV of 149% is event-dominated (5 days). (3) **MU and MRVL are the "implied below realized" cases**, and both are windows dominated by the 11-05 and 11-20 semis breaks. (4) 30d IV figures are not event-isolated and are weaker evidence than straddle rows; only SPY and DELL have contract-IV reads this run (limits below). (5) Close-to-close HV excludes overnight gaps.

### Ranked shortlist: 15 event candidates

**Changes vs W46's 15:** struck as passed or resolved: NVDA, HD, PANW, WMT (printed 11-17..11-19), CAPR (CRL 11-20). Added: SNOW, ADBE, ADI, HPE, COGT (carried, now in window). **Rank rule (unchanged):** router admissibility first; then earnings with a measured options market ahead of PDUFA binaries and unmeasured names; then event proximity, market cap and measured IV/HV30; not edge. Direction in every row is the divergence between the options market and a no-event realized baseline (HV30-based); W1 establishes no directional view on the underlying. Primary documents (transcripts, 10-Q/10-K) were NOT read this run. A-queue membership is from PART 1's 47-name census; **no open A positions, so (e) overlap is vacuous**.

**TOP-5**

**1. FOMC 2026-12-09 (C, SEP meeting), the only router-admissible candidate** — (a) No directional divergence established. The measured divergence is **implied above realized**: SPY IV/HV30 **1.44** (contract IV 32.3% vs HV30 22.4%), into an event where a 25 bp hike is ~92% priced, 50 bp 3-10%, hold ~8%. The hypothesis fields are the 50 bp tail and the January guidance in the SEP (Waller and "a couple of participants" vs Williams and the survey median). (b) federalreserve.gov minutes of 10-27/28 (released 11-18) and the FOMC calendar page; CNBC 11-18 and Bloomberg 11-18 (minutes coverage); CNBC 11-18 (Waller); Axios 11-17 (Williams); Admiral Markets 11-19, Seoul Economic Daily, Yahoo Finance 11-20, Schwab 11-20 (FedWatch readings, E). (c) **2026-12-09, 2:00 pm ET (C)**; first listed SPY expiry after it **12-11**; last entry day 12-08. (d) **NOT executable at current capital: DEFERRAL** (NAV $18.55; single-leg ATM call ask $2,402; cheapest INFERRED spread ~$50). (e) No open A positions; not an A-queue name. (f) **Top-5, rank 1.** Disposition: thesis row `thesis-FOMC-C-20261130` already queued (due 11-30); W4 must not duplicate it. GATE: N/A (C row).

**2. DELL, earnings 2026-11-24 after close (C)** — (a) Implied rich on the event expiry: 280 straddle 16.4% vs 9.4% realized-equivalent (contract IV 149% / HV30 100.7% = **1.48**; 30d IV ratio 1.07); stock -11.0% on 11-20 to 278.02 (-19% in a week). (b) Dell IR release 2026-11-10 (call Tue 11-24 3:30 pm CST; PART 1A). (c) 2026-11-24 AMC; expiry 11-27; **only entry day is Mon 11-23**. (d) **Deferral** (280 call ask $22.35 = $2,235; straddle $4,570). (e) DELL in A-queue; none open. (f) Top-5. **Router-PARKED.**

**3. CRWD, earnings 2026-12-01 after close (C)** — (a) Implied rich vs realized: 30d IV 85.3% vs HV30 64.0% (**1.33**); reported CrowdStrike-Zscaler acquisition talks (Reuters/Bloomberg via Stock Titan, E) add a non-event-type confound. (b) CrowdStrike release 2026-11-04 (ir.crowdstrike.com; PART 1A). (c) 2026-12-01 AMC (C); first listed expiry after it is 12-04 (INFERRED from the weekly cycle). (d) **Deferral** (single-leg ATM ~$1,419 INFERRED). (e) A-queue; none open. (f) Top-5. **Router-PARKED.**

**4. MRVL, earnings 2026-12-01 after close (C)** — (a) Implied LEAN vs a window inflated by the LITE merger and the semis breaks (30d IV 95.1% vs HV30 110.2%, **0.86**). (b) Marvell IR release 2026-11-06 (PART 1A). (c) 2026-12-01 AMC (C). (d) **Deferral** (single leg ~$843 INFERRED). (e) A-queue; none open. (f) Top-5. **Router-PARKED.**

**5. CRM, earnings 2026-12-02 after close (C)** — (a) Implied rich: 30d IV 66.6% vs HV30 43.4% (**1.53**); stock -17.1% over five sessions to 180.62. (b) Salesforce release 2026-11-10 (PART 1A). (c) 2026-12-02 AMC (C). (d) **Deferral** (single leg ~$872 INFERRED). (e) A-queue; none open. (f) Top-5. **Router-PARKED.**

**REST (6-15)**: all **router-PARKED**; all deferrals at C NAV $18.55. Single-leg ATM costs are INFERRED (Brenner-Subrahmanyam: 0.4 x S x 30d IV x sqrt(days/365) to the first expiry after the event), not chain reads.

| # | Candidate | (a) Direction of divergence | (b) Documents consulted | (c) Date (tag) | (d) Executability at C $18.55 | (e) A overlap | IV/HV30 |
|---|---|---|---|---|---|---|---|
| 6 | **SNOW** earnings | Implied rich: 30d IV 93.0% vs HV30 58.4% | Snowflake release 2026-11-02 (PART 1A) | 2026-12-02 AMC (C) | Deferral (~$1,719 INFERRED) | A-queue; none open | 1.59 (30d) |
| 7 | **ADBE** earnings | Implied richest on the panel vs a calm window: 65.0% vs 38.7% | Adobe IR events page (PART 1A) | 2026-12-09 AMC (C), same day as FOMC (confounded) | Deferral (~$1,291 INFERRED) | A-queue; none open | **1.68** (30d) |
| 8 | **AVGO** earnings | Implied near realized: 77.3% vs 72.9% (HV10 100.5%); -12.2% on 11-20 | Broadcom release 2026-11-09 (PART 1A) | 2026-12-09 AMC (C), same day as FOMC (confounded) | Deferral (~$2,147 INFERRED) | A-queue; none open | 1.06 (30d) |
| 9 | **COST** earnings | Implied rich vs a quiet name: 29.6% vs 21.0% | investor.costco.com event page; FMP agrees (PART 1A) | 2026-12-10 AMC (C) | Deferral (~$3,055 INFERRED) | not in A-queue; none open | 1.41 (30d) |
| 10 | **ORCL** earnings | Implied modestly rich: 87.7% vs 76.6%; -8.5% on 11-20 | Oracle IR FAQ, no dated release (PART 1A) | 2026-12-14 AMC (C issuer FAQ; vendor 12-09 conflict open) | Deferral (~$947 INFERRED) | A-queue; none open | 1.14 (30d) |
| 11 | **MU** earnings | Implied LEAN: 69.9% vs 97.9% (HV10 111.5%); -13.9% on 11-20 | Micron release 2026-11-19 (PART 1A) | 2026-12-17 (C); Nasdaq's 12-16 is wrong | Deferral (~$4,500 INFERRED, a very expensive single leg) | A-queue; none open | **0.71** (30d) |
| 12 | **VRTX** PDUFA povetacicept / IgAN | Binary regulatory outcome; options not read; HV30 only 32.0% | Vertex 10-Q 2026-11-03 via aggregator; no FDA action seen (PART 1B) | 2026-11-30 (C carried, secondary) | Deferral (chain not measured) | A-queue; none open | not measured |
| 13 | **ADI** earnings | Not measured | investor.analog.com events page (PART 1A); one vendor says after close (timing only) | 2026-11-24 BMO (C) | Deferral (chain not read) | not in A-queue; none open | not measured |
| 14 | **COGT** PDUFAs (GIST 11-30, NonAdvSM 12-30) | Binary; not measured | Cogent Q3 release 2026-11-05 (PART 1B) | 2026-11-30 and 2026-12-30 (C carried) | Deferral (chain not read) | not in A-queue; none open | not measured |
| 15 | **HPE** earnings | Not measured; **entry window already closed** (event 11-23, last entry 11-20) | Nasdaq/PART 1A | 2026-11-23 AMC (C) | Deferral and criterion-5 fail | A-queue; none open | not measured |

Also in window, not ranked: SVRA molgramostim (goal date missed 11-22, undated), RHHBY giredestrant 11-30 (C-secondary), VTRS 12-27 (C-secondary), NUVB 2027-01-04, ACN/NKE/CTAS 12-17, bank earnings RY/TD/CM/BMO/BNS 12-02/12-03.

**(e) A-vs-C exclusivity is vacuous this cycle:** zero open A or C positions (orchestrator-MEASURED).

**Price half (IBKR regular-session daily bars to Friday 2026-11-20, MEASURED).** SPY 689.81 (-3.64%), DELL 278.02 (-11.0%), MRVL 122.28 (-11.7%), CRWD 229.44 (-5.8%), CRM 180.62 (-1.5%), SNOW 254.82 (-5.1%), AVGO 304.41 (-12.2%), ADBE 217.71 (-1.8%), COST 1,102.15 (+0.8%), ORCL 101.19 (-8.5%), MU 594.51 (-13.9%), VRTX 515.02 (-1.1%).

**Shortlists only.** Full thesis construction happens in sessions W4 schedules. Nothing here authorizes an enqueue for any parked name. **Measurement coverage and limits:** SPY and DELL have contract IV (SPY 12-11 690 strike; DELL 11-27 280 strike); the other names carry 30d IV only (30d IV is NOT event-isolated); VRTX has no IV read; ADI, HPE, COGT have no read at all (the 15-underlying cap and the call budget). IBKR option pulls were limited to SPY and DELL; no rate-limit error occurred. MEASURED = IBKR bars/snapshots; INFERRED = single-leg estimates, the SPY spread estimate, 12-04 expiry assumptions, and every statement about why price moved (web-sourced context is E-tagged secondary). The first-pass SPY straddle is stale-leg and not used for conclusions. **Parallel calls this part: 2 (web_search); call log `calls_part2c.csv`.**

2026-W46

# Weekly Catalyst Calendar — Strategies A and C

**Run date 2026-11-15** (Sunday, `weekly_sun`). ISO week of TODAY's run date, 2026-W46. The upcoming trading week opens Monday 2026-11-16; that is context, not the marker. Fleet context (MEASURED, orchestrator): no routine ran 2026-11-10 → 11-12 (`state.fleet_blackout_days`) and D1's last completed run is 2026-11-09, so D1 did not cover sessions 11-10 → 11-13 (11-13 is the structural Friday gap); this PART carries D1's 11-09 records and adds only minimum per-name source checks for 11-10 → 11-13 (call log in `calls_1a.csv`: 14 Parallel calls this part).

**Windows.** Strategy A: 6 months, **2026-11-15 → 2027-05-15** — **effective confirmed-earnings horizon 2026-12-18 (33 days, ~4.7 weeks); sparse vendor coverage beyond it, per-name (E) fallback for A-queue names without a forward date.** Strategy C: 45 days, **2026-11-15 → 2026-12-30** (run date + 45 days, same convention as W45's 11-08 → 12-23; the 12-09 FOMC decision sits on day 24 counting from 11-15 as day 0).

**EFFECTIVE CONFIRMED-EARNINGS HORIZON: 2026-12-18, 33 days (~4.7 weeks) from 2026-11-15. The terminal date did NOT move for a seventh week** (MEASURED: FMP chunk 1, 2026-11-15 → 2027-01-14, returned 20 rows; the contiguous near-term block ends at CCL 2026-12-18, then nothing until TLRY 2027-01-11; the 5 rows 01-11 → 01-14 TLRY/DAL/C/JPM/WFC are the first of the post-gap block, not part of the series). Depth fell 40 → 33 days only because the clock advanced. Eleven-week series, terminal date / days from that week's run date: 2026-12-03/88d (09-06), 2026-12-09/87d (09-13), 2026-12-09/80d (09-20), 2026-12-10/74d (09-27), 2026-12-18/75d (10-04), 2026-12-18/68d (10-11), 2026-12-18/61d (10-18), 2026-12-18/54d (10-25), 2026-12-18/47d (11-01), 2026-12-18/40d (11-08), **2026-12-18/33d (11-15)**. Dead zone 2026-12-19 → 2027-01-10 (no FMP row). The 2027 block (62 rows 2027-01-11 → 2027-03-25, of which 58 fall 01-11 → 02-21) is the January/February mega-cap season as a sparse top-name sample and is NOT part of the series. Standing plan-tier constraint (`FMP-earn-horizon`, `OWNER_ACTIONS.md`), deliberately NOT re-alerted; all FMP pulls chunked ≤ 60 days (4 chunks, 77 deduped rows, no errors).

**Nasdaq key-less per-day calendar** (shared CSV, weekdays 2026-11-09 → 2026-12-31, not re-fetched; zero rows on 11-26, 12-23, 12-25, 12-31; 12-22 has 8 rows of all caps, none ≥ $2B; last ≥ $2B date 12-21 = ABVX; 12-23 → 12-30 contain no ≥ $2B row, so the C window's last 9 days are empty on this source): 1,716 rows at all market caps; **382 rows at market cap ≥ $2B** (53 ≥ $50B overall). Of those: **158 fall in the week just printed 11-09 → 11-13** (11-09 65, 11-10 30, 11-11 21, 11-12 33, 11-13 9) and **224 are forward 2026-11-16 → 2026-12-30** (121 dated 11-16 → 11-27 and 103 dated 12-01 → 12-21; 39 forward rows are ≥ $50B). **136 of 224 forward rows carry `time-not-supplied`** (projected (E) signature); 49 BMO, 39 AMC. Forward per-day counts at ≥ $2B: 11-16 14, 11-17 19, 11-18 20, 11-19 21, 11-20 7, 11-23 12, 11-24 23, 11-25 4, 11-27 1, 12-01 11, 12-02 13, 12-03 23, 12-04 1, 12-07 2, 12-08 11, 12-09 8, 12-10 7, 12-14 1, 12-15 3, 12-16 6, 12-17 12, 12-18 4, 12-21 1. **Staleness caveat (carried from the pull):** Parallel `acquired_at` shows many future-dated Nasdaq pages were cached 2026-10-23 → 11-10 (11-17 acquired 11-10; 11-18 → 11-20 and 12-07 → 12-18 acquired 11-09; 11-23 → 12-04 and 12-08 → 12-10 acquired 11-04/05; 12-21 → 12-31 acquired 10-23/11-02), so dates after 11-16 reflect Nasdaq as of that cache time, not 11-15; this run proved the effect (BABA below: Nasdaq's cached 11-24 was wrong). Dates 12-21, 12-24, 12-28 → 12-30 only returned rows after a cache-bust refetch (22 rows merged); 12-22 was not refetched.

**FMP coverage shape** (MEASURED, four chunked `calendar/earnings-calendar` calls by the orchestrator; 77 deduped symbol-date rows; counts parsed from the shared file):

| Span | Rows | Notes |
|---|---|---|
| 11-15 → 11-30 | 10 | BIDU 11-16; DIS/FUBO/NVDA 11-17; TGT 11-18; BABA/WMT 11-19; ZM 11-23; BILI/NIO 11-24 |
| 12-01 → 12-18 | 5 | DOCU 12-03; ADBE 12-09; COST 12-10; NKE 12-17; CCL 12-18 (terminal row) |
| 12-19 → 2027-01-10 | 0 | dead zone (plan-tier constraint, not alerted) |
| 2027-01-11 → 02-21 | 58 | TLRY 01-11 … ETSY 02-18; ISO weeks 2027-W02 6, W03 6, W04 18, W05 17, W06 10, W07 1 |
| 2027-02-22 → 05-15 | 4 | LCID 02-23, RKT 02-25, RIOT 03-01, FDX 03-25 (chunk 3); chunk 4 (05-14 → 05-15) 0 rows |

FMP lists FDX twice (2027-02-02 chunk 2 and 2027-03-25 chunk 3): internal vendor inconsistency, neither relied on. Δ vs W45's FMP list: no date changed for any carried symbol; newly present SONY 02-04, CSCO 02-10 (post-print projection), LCID 02-23 (printed 11-09).

**Cross-check FMP vs Nasdaq (inside 11-16 → 12-30):** FMP has 15 in-window rows; 14 are also on the Nasdaq ≥ $2B forward list (BIDU, DIS, NVDA, TGT, BABA, WMT, ZM, BILI, NIO, DOCU, ADBE, COST, NKE, CCL). **13 agree on the date; 1 DISAGREED: BABA (FMP 2026-11-19 vs Nasdaq 2026-11-24) — RESOLVED this run in FMP's favour: Alibaba's own release dated 2026-11-06 sets results before the U.S. open Thursday 11-19 (alibabagroup.com).** FMP-only: **FUBO** (11-17; Nasdaq all-caps file $0.88B, below the $2B floor). FMP rows beyond 12-30 (62 rows) are outside the Nasdaq pull by construction. Nasdaq ≥ $2B forward names not in FMP: 210 of 224 (FMP is a sparse mega-cap subset, not an enumeration). Separately, a secondary vendor page (Theta, 2026-11) lists "BABA 2026-11-13" and "DIS reported 2026-11-12"; both are contradicted by the issuers (BABA 11-19; Disney release 2026-10-12 sets 11-17) and are not used.

**A-queue (47) census vs Nasdaq** (pinned census `SELECT * FROM state.open_queue WHERE strategy = 'A'` → 47 rows, orchestrator-MEASURED; last cycle 46, **Δ +CEG** added by W4): **18 have a forward Nasdaq date inside 11-16 → 12-30** (NVDA, HD, PANW, TGT, WMT, INTU, HPE, DELL, CRWD, MRVL, NTAP, OKTA, CRM, SNOW, ADBE, AVGO, ORCL, MU); **5 printed 11-09 → 11-13** (CEG 11-09, TTWO 11-09, CSCO 11-12, AMAT 11-12, NBIS 11-12); **24 have none** (AAPL, AKAM, AMD, AMZN, ANET, CAT, COP, CVX, DDOG, FSLR, GEV, GOOGL, IBM, INTC, JPM, LLY, META, MRK, MSFT, NOW, QCOM, SMCI, VRTX, XOM; the 9 that printed 11-02 → 11-06 plus 15 with no date in either pull). 18 + 5 + 24 = 47. Of the 18 forward names, **16 are issuer-confirmed ((C) or (C-secondary): NVDA, HD, PANW (secondary), TGT, WMT, INTU, HPE, DELL, CRWD, MRVL, NTAP, OKTA, CRM, SNOW, ADBE, AVGO)** — up from 14 confirmed of 22 in W45 — and 2 remain (E)/conflicted (ORCL: Nasdaq 12-09 vs Oracle IR FAQ 12-14; MU 12-16, no notice).

**FLOOR + plan-tier gate (standing constraints, stated, NOT re-alerted).** Every count in PART 1 beyond the 12-18 horizon is a FLOOR: the FMP earnings horizon is plan-capped (~13 weeks nominal, dense coverage ends 12-18) and sparse inside it (`FMP-earn-horizon`, `ops.alerts` 37a4de80); the 90-day clamp is handled by ≤ 60-day chunks; and the plan tier separately denies bulk enumeration — `search/search-company-screener`, every `directory.*` route and `quote/batch-quote` are tool-level ACCESS DENIED (`ops.alerts` 6c4004e3), so a bulk FMP pull cannot build the market-cap/ADV universe rail either. The market-cap rail inside the C window is Nasdaq's own `marketCap` field; the 30-day ADV ≥ $10M rail is carried, not re-measured (1A.11). FMP `news`/`secFilings` were not called.


## PART 1A — Strategy A universe, 6-month window (2026-11-15 → 2027-05-15)

No interpretation in this PART. Provenance tags:
- **(C)** company- or primary-source confirmed (**(C-secondary)** = issuer notice seen only through a copy or search snippet)
- **(E)** estimated (vendor or aggregator projection)
- **(T)** tentative, no firm day

"Δ" marks a change against the 2026-11-08 (2026-W45) artifact. Rows tagged (C) 'carried' were issuer-confirmed in W45 (or earlier) and the Nasdaq date still matches; they were NOT re-read this run unless the source cell says re-read. Metered calls this part: 13 web_search + 1 web_fetch (Parallel), see `calls_1a.csv`. No Parallel SEARCH GUARD event.

### 1A.1 — Earnings, inside the 45-day C window (2026-11-16 → 2026-12-30)

**Enumeration.** Nasdaq key-less per-day calendar, market cap ≥ $2B: 224 forward rows (2026-11-16 → 12-21; none dated 12-22 → 12-30); 39 are ≥ $50B. **Restriction stated:** the detail table lists every forward row with market cap ≥ $10B (109 rows) — which includes all 18 forward A-queue names and every name carried in W45's table — plus MDT (absent from this week's Nasdaq pull; restored from the issuer notice); the 115 forward rows between $2B and $10B are enumerated by session below. Time codes: BMO before open, AMC after close, n/s not supplied. Mcap = Nasdaq `marketCap` field as fetched. D marks a held Strategy D position. Rows without an explicit source are Nasdaq-only and (E). Check: detail 109 + remainder 115 = 224 forward Nasdaq rows (+1 MDT row outside the Nasdaq pull).

| Ticker | Name | Type | Date | Tag | Mcap | Source / consensus |
|---|---|---|---|---|---|---|
| TCOM | Trip.com Group Limited | Earnings (n/s, FQ Sep/2026) | 2026-11-16 | (E) | $27B | Nasdaq calendar |
| BIDU | Baidu, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-11-16 | (E) | $26B | Nasdaq 11-16 BMO; FMP agrees (EPS est 0.85); China-tech preview (ifyouspent 2026-11-10) says company announcement Mon 11-16 before open, call 7:30 am ET (secondary) |
| TSN | Tyson Foods, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-11-16 | (E) | $21B | Nasdaq calendar |
| BEKE | KE Holdings Inc | Earnings (BMO, FQ Sep/2026) | 2026-11-16 | (E) | $20B | Nasdaq calendar |
| HTHT | H World Group Limited | Earnings (BMO, FQ Sep/2026) | 2026-11-16 | (E) | $15B | Nasdaq calendar |
| ARMK | Aramark | Earnings (BMO, FQ Sep/2026) | 2026-11-16 | (E) | $14B | Nasdaq calendar |
| NVDA | NVIDIA Corporation [A-queue] | Earnings (AMC, FQ Oct/2026) | 2026-11-17 | (C) | $4,306B | nvidianews.nvidia.com call notice (carried from W44/W45); NVIDIA 11-12 CEO-transition announcement states FQ3 FY27 results "remain scheduled for Tuesday, November 17, 2026" (via a secondary digest, X/TheValueist 2026-11-12); FMP agrees (EPS est 2.47) |
| HD | Home Depot, Inc. (The) [A-queue] | Earnings (BMO, FQ Oct/2026) | 2026-11-17 | (C) | $353B | Home Depot IR events page (W45 WebFetch), carried, not re-read |
| BHP | BHP Group Limited | Earnings (n/s, FQ Sep/2026) | 2026-11-17 | (E) | $210B | Nasdaq calendar |
| DIS | Walt Disney Company (The) [D held] | Earnings (BMO, FQ Sep/2026) | 2026-11-17 | (C) | $206B | (C) re-read: Disney release 2026-10-12 and IR event page (investors.thewaltdisneycompany.com): results before open Tue 11-17, webcast 8:30 am ET; FMP agrees. A secondary vendor page listing DIS as 'Reported 2026-11-12' is contradicted by the issuer |
| PDD | PDD Holdings Inc. | Earnings (n/s, FQ Sep/2026) | 2026-11-17 | (E) | $115B | Nasdaq calendar |
| VIK | Viking Holdings Ltd | Earnings (BMO, FQ Sep/2026) | 2026-11-17 | (E) | $39B | Nasdaq calendar |
| JD | JD.com, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-11-17 | (E) | $38B | Nasdaq 11-17 BMO; secondary preview cites JD.com announcement of 2026-11-04 (11-17, call 7:00 am ET) |
| ESLT | Elbit Systems Ltd. | Earnings (BMO, FQ Sep/2026) | 2026-11-17 | (E) | $34B | Nasdaq calendar |
| AS | Amer Sports, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-11-17 | (E) | $18B | Nasdaq calendar |
| SQM | Sociedad Quimica y Minera S.A. | Earnings (n/s, FQ Sep/2026) | 2026-11-17 | (E) | $16B | Nasdaq calendar |
| ZTO | ZTO Express (Cayman) Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-17 | (E) | $16B | Nasdaq calendar |
| TME | Tencent Music Entertainment Group | Earnings (BMO, FQ Sep/2026) | 2026-11-17 | (E) | $15B | Nasdaq calendar |
| PANW | Palo Alto Networks, Inc. [A-queue] | Earnings (AMC, FQ Oct/2026) | 2026-11-18 | (C-secondary) | $258B | PR Newswire title "Fiscal First Quarter 2027 ... Wednesday, November 18, 2026" (carried from W45 via stockhub.kr copy); secondary digest (theearningsmadness 2026-11-12) also lists 11-18 after close |
| TJX | TJX Companies, Inc. (The) | Earnings (BMO, FQ Oct/2026) | 2026-11-18 | (E) | $152B | Nasdaq calendar |
| LOW | Lowe's Companies, Inc. | Earnings (BMO, FQ Oct/2026) | 2026-11-18 | (E) | $127B | Nasdaq calendar |
| TGT | Target Corporation [A-queue] | Earnings (BMO, FQ Oct/2026) | 2026-11-18 | (C) | $72B | corporate.target.com (carried); FMP agrees (EPS est 2.07) |
| P | Everpure, Inc. | Earnings (AMC, FQ Oct/2026) | 2026-11-18 | (E) | $31B | Nasdaq calendar |
| WSM | Williams-Sonoma, Inc. | Earnings (n/s, FQ Oct/2026) | 2026-11-18 | (E) | $30B | Nasdaq calendar |
| WWD | Woodward, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-18 | (E) | $18B | Nasdaq calendar |
| WMT | Walmart Inc. [A-queue] | Earnings (BMO, FQ Oct/2026) | 2026-11-19 | (C) | $1,013B | corporate.walmart.com (carried); FMP agrees |
| INTU | Intuit Inc. [A-queue] | Earnings (AMC, FQ Oct/2026) | 2026-11-19 | (C) | $95B | **Δ (C-secondary -> C)**: Intuit release 2026-10-29 "Intuit to Announce First-Quarter Fiscal Year 2027 Results on Nov. 19", after close, call 4:30 pm ET (investors.intuit.com, via web_search) |
| NTES | NetEase, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-11-19 | (E) | $81B | Nasdaq 11-19; China-tech preview (secondary) cites company announcement 11-19 before US open |
| ROST | Ross Stores, Inc. | Earnings (n/s, FQ Oct/2026) | 2026-11-19 | (E) | $75B | Nasdaq calendar |
| VEEV | Veeva Systems Inc. | Earnings (n/s, FQ Oct/2026) | 2026-11-19 | (E) | $50B | Nasdaq calendar |
| KEYS | Keysight Technologies Inc. | Earnings (AMC, FQ Oct/2026) | 2026-11-19 | (E) | $44B | Nasdaq calendar |
| CPRT | Copart, Inc. | Earnings (n/s, FQ Oct/2026) | 2026-11-19 | (E) | $30B | Nasdaq calendar |
| WMG | Warner Music Group Corp. | Earnings (BMO, FQ Sep/2026) | 2026-11-19 | (E) | $17B | Nasdaq calendar |
| FUTU | Futu Holdings Limited | Earnings (BMO, FQ Sep/2026) | 2026-11-19 | (E) | $13B | Nasdaq calendar |
| BJ | BJ's Wholesale Club Holdings, Inc. | Earnings (BMO, FQ Oct/2026) | 2026-11-20 | (E) | $14B | Nasdaq calendar |
| HPE | Hewlett Packard Enterprise Company [A-queue] | Earnings (AMC, FQ Oct/2026) | 2026-11-23 | (C) | $70B | **Δ (E -> C)**: HPE release dated 2026-11-02 (hpe.com newsroom): call Mon 11-23 4:00 pm CT / 5:00 pm ET; same date as Nasdaq |
| A | Agilent Technologies, Inc. | Earnings (AMC, FQ Oct/2026) | 2026-11-23 | (E) | $49B | Nasdaq calendar |
| ZM | Zoom Communications, Inc. | Earnings (AMC, FQ Oct/2026) | 2026-11-23 | (E) | $27B | Nasdaq 11-23 AMC; FMP agrees |
| SYM | Symbotic Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-23 | (E) | $23B | Nasdaq calendar |
| J | Jacobs Solutions Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-23 | (E) | $19B | Nasdaq calendar |
| SMTC | Semtech Corporation | Earnings (n/s, FQ Oct/2026) | 2026-11-23 | (E) | $12B | Nasdaq calendar |
| DELL | Dell Technologies Inc. [A-queue] | Earnings (n/s, FQ Oct/2026) | 2026-11-24 | (C) | $260B | **Δ (E -> C)**: Dell release 2026-11-10 4:05 pm EST (investors.delltechnologies.com): call Tue 11-24 3:30 pm CST; same date as Nasdaq (n/s) |
| BABA | Alibaba Group Holding Limited | Earnings (n/s, FQ Sep/2026) | 2026-11-24 | (C) | $243B | **Δ (E -> C; Nasdaq WRONG)**: Alibaba release 2026-11-06 (alibabagroup.com): results BEFORE U.S. open Thu 11-19, call 7:00 am ET. FMP 11-19 agrees; Nasdaq cached 11-24 does not. Resolves the W45 disagreement in FMP favour |
| ADI | Analog Devices, Inc. | Earnings (BMO, FQ Oct/2026) | 2026-11-24 | (E) | $203B | Nasdaq calendar |
| ADSK | Autodesk, Inc. | Earnings (AMC, FQ Oct/2026) | 2026-11-24 | (E) | $53B | Nasdaq calendar |
| WDAY | Workday, Inc. | Earnings (AMC, FQ Oct/2026) | 2026-11-24 | (E) | $48B | Nasdaq calendar |
| ZS | Zscaler, Inc. | Earnings (n/s, FQ Oct/2026) | 2026-11-24 | (E) | $37B | Nasdaq 11-24; **Δ 12-02 -> 11-24 vs W45**; Theta calendar (secondary) still lists 12-02; unresolved |
| HPQ | HP Inc. | Earnings (AMC, FQ Oct/2026) | 2026-11-24 | (E) | $25B | Nasdaq calendar |
| DLTR | Dollar Tree, Inc. | Earnings (BMO, FQ Oct/2026) | 2026-11-24 | (E) | $25B | Nasdaq 12-02 (second row, n/s); **Δ 11-24 -> 12-02 vs W45**; scrutar estimate also "around Dec 2" |
| BBY | Best Buy Co., Inc. | Earnings (BMO, FQ Oct/2026) | 2026-11-24 | (E) | $20B | Nasdaq calendar |
| NTNX | Nutanix, Inc. | Earnings (n/s, FQ Oct/2026) | 2026-11-24 | (E) | $18B | Nasdaq calendar |
| BURL | Burlington Stores, Inc. | Earnings (n/s, FQ Oct/2026) | 2026-11-24 | (E) | $15B | Nasdaq calendar |
| SJM | The J.M. Smucker Company | Earnings (BMO, FQ Oct/2026) | 2026-11-24 | (E) | $14B | Nasdaq calendar |
| DKS | Dick's Sporting Goods Inc | Earnings (BMO, FQ Oct/2026) | 2026-11-24 | (E) | $12B | Nasdaq calendar |
| DE | Deere & Company | Earnings (BMO, FQ Oct/2026) | 2026-11-25 | (E) | $180B | Nasdaq 11-25; earningsmadness (secondary) also est. 11-25 |
| LI | Li Auto Inc. | Earnings (n/s, FQ Sep/2026) | 2026-11-25 | (E) | $11B | Nasdaq calendar |
| CRWD | CrowdStrike Holdings, Inc. [A-queue] | Earnings (n/s, FQ Oct/2026) | 2026-12-01 | (C) | $251B | **Δ (E/n.s. -> C)**: CrowdStrike release 2026-11-04 (ir.crowdstrike.com): after close Tue 12-01, call 2:00 pm PT |
| MRVL | Marvell Technology, Inc. [A-queue] | Earnings (n/s, FQ Oct/2026) | 2026-12-01 | (C) | $151B | Marvell IR release 2026-11-06 (carried from W45, not re-read): Tue 12-01, call 1:30 pm PT. Merger with LITE: see 1A.7 |
| BNS | Bank of Nova Scotia (The) | Earnings (n/s, FQ Oct/2026) | 2026-12-01 | (E) | $115B | **Δ 12-02 -> 12-01 vs W45** (Nasdaq) |
| NTAP | NetApp, Inc. [A-queue] | Earnings (AMC, FQ Oct/2026) | 2026-12-01 | (C) | $37B | **Δ (E -> C)**: NetApp release 2026-11-10 (investors.netapp.com): after close Tue 12-01, webcast 2:30 pm PT |
| OKTA | Okta, Inc. [A-queue] | Earnings (AMC, FQ Oct/2026) | 2026-12-01 | (C) | $33B | Okta release (carried from W45, finviz copy): after close 12-01, webcast 2:00 pm PT; not re-read |
| CRM | Salesforce, Inc. [A-queue] | Earnings (n/s, FQ Oct/2026) | 2026-12-02 | (C) | $186B | **Δ (E -> C)**: Salesforce release 2026-11-10 (investor.salesforce.com): Wed 12-02 after close, broadcast 2:00 pm PT |
| SNOW | Snowflake Inc. [A-queue] | Earnings (AMC, FQ Oct/2026) | 2026-12-02 | (C) | $103B | Snowflake release 2026-11-02 (carried from W45), after close, call 2:00 pm PT; not re-read |
| DLTR | Dollar Tree, Inc. | Earnings (n/s, FQ Oct/2026) | 2026-12-02 | (E) | $26B | Nasdaq 12-02 (second row, n/s); **Δ 11-24 -> 12-02 vs W45**; scrutar estimate also "around Dec 2" |
| GWRE | Guidewire Software, Inc. | Earnings (n/s, FQ Oct/2026) | 2026-12-02 | (E) | $13B | Nasdaq calendar |
| FIVE | Five Below, Inc. | Earnings (n/s, FQ Oct/2026) | 2026-12-02 | (E) | $13B | Nasdaq calendar |
| RY | Royal Bank Of Canada | Earnings (BMO, FQ Oct/2026) | 2026-12-03 | (E) | $290B | Nasdaq calendar |
| TD | Toronto Dominion Bank (The) | Earnings (n/s, FQ Oct/2026) | 2026-12-03 | (E) | $209B | Nasdaq calendar |
| BMO | Bank Of Montreal | Earnings (n/s, FQ Oct/2026) | 2026-12-03 | (E) | $123B | **Δ 12-02 -> 12-03 vs W45** (Nasdaq) |
| CM | Canadian Imperial Bank of Commerce | Earnings (n/s, FQ Oct/2026) | 2026-12-03 | (E) | $109B | Nasdaq calendar |
| KR | Kroger Company (The) | Earnings (n/s, FQ Oct/2026) | 2026-12-03 | (E) | $41B | Nasdaq calendar |
| DG | Dollar General Corporation | Earnings (n/s, FQ Oct/2026) | 2026-12-03 | (E) | $31B | Nasdaq calendar |
| ULTA | Ulta Beauty, Inc. | Earnings (AMC, FQ Oct/2026) | 2026-12-03 | (E) | $28B | Nasdaq calendar |
| IOT | Samsara Inc. | Earnings (AMC, FQ Oct/2026) | 2026-12-03 | (E) | $25B | Nasdaq calendar |
| RBRK | Rubrik, Inc. | Earnings (n/s, FQ Oct/2026) | 2026-12-03 | (E) | $25B | Nasdaq calendar |
| DOCU | DocuSign, Inc. | Earnings (n/s, FQ Oct/2026) | 2026-12-03 | (E) | $15B | Nasdaq 12-03; FMP agrees |
| BF.A | Brown Forman Corporation | Earnings (BMO, FQ Oct/2026) | 2026-12-03 | (E) | $14B | Nasdaq calendar |
| BF.B | Brown Forman Corporation | Earnings (BMO, FQ Oct/2026) | 2026-12-03 | (E) | $14B | Nasdaq calendar |
| HRL | Hormel Foods Corporation | Earnings (BMO, FQ Oct/2026) | 2026-12-03 | (E) | $13B | Nasdaq calendar |
| COO | The Cooper Companies, Inc. | Earnings (n/s, FQ Oct/2026) | 2026-12-03 | (E) | $12B | Nasdaq calendar |
| CRDO | Credo Technology Group Holding Ltd | Earnings (n/s, FQ Oct/2026) | 2026-12-07 | (E) | $21B | Nasdaq calendar |
| AZO | AutoZone, Inc. | Earnings (n/s, FQ Nov/2026) | 2026-12-08 | (E) | $52B | Nasdaq calendar |
| CASY | Caseys General Stores, Inc. | Earnings (n/s, FQ Oct/2026) | 2026-12-08 | (E) | $25B | Nasdaq calendar |
| GME | GameStop Corporation | Earnings (n/s, FQ Oct/2026) | 2026-12-08 | (E) | $12B | Nasdaq calendar |
| SAIL | SailPoint, Inc. | Earnings (n/s, FQ Oct/2026) | 2026-12-08 | (E) | $11B | Nasdaq calendar |
| ORCL | Oracle Corporation [A-queue] | Earnings (n/s, FQ Nov/2026) | 2026-12-09 | (E) | $374B | Nasdaq 12-09; **DATE CONFLICT**: Oracle IR FAQ page (oracle.com/corporate/investor_relations/faq.html; web_fetch acquired_at 2026-10-26) states "Second Quarter Fiscal Year 2027 earnings will be announced on December 14, 2026"; vendor calendars (days.to/earningsmadness/Theta) show 12-09. No dated Oracle release seen. Unresolved |
| ADBE | Adobe Inc. [A-queue] | Earnings (n/s, FQ Nov/2026) | 2026-12-09 | (C) | $97B | **Δ (E -> C)**: Adobe IR page (adobe.com/investor-relations, undated page via web_search): "Wednesday, December 9, 2026 Q4 & FY2026 earnings call 2:00pm Pacific"; FMP agrees (EPS est 6.33) |
| SNPS | Synopsys, Inc. | Earnings (n/s, FQ Oct/2026) | 2026-12-09 | (E) | $89B | Nasdaq calendar |
| NDSN | Nordson Corporation | Earnings (n/s, FQ Oct/2026) | 2026-12-09 | (E) | $18B | Nasdaq calendar |
| AVGO | Broadcom Inc. [A-queue] | Earnings (n/s, FQ Oct/2026) | 2026-12-10 | (C) | $1,585B | **Δ 12-10 -> 12-09 vs W45; (E -> C)**: Broadcom release 2026-11-09 (broadcom.com / investors.broadcom.com): Q4 FY26 results Wed 12-09 after close, call 2:00 pm PT. Nasdaq still shows 12-10 |
| COST | Costco Wholesale Corporation | Earnings (n/s, FQ Nov/2026) | 2026-12-10 | (E) | $452B | Nasdaq 12-10; FMP agrees (EPS est 4.92) |
| CIEN | Ciena Corporation | Earnings (n/s, FQ Oct/2026) | 2026-12-10 | (E) | $43B | Nasdaq calendar |
| LULU | lululemon athletica inc. | Earnings (n/s, FQ Oct/2026) | 2026-12-10 | (E) | $11B | Nasdaq calendar |
| TOL | Toll Brothers, Inc. | Earnings (n/s, FQ Oct/2026) | 2026-12-14 | (E) | $14B | Nasdaq calendar |
| LEN | Lennar Corporation | Earnings (n/s, FQ Nov/2026) | 2026-12-15 | (E) | $22B | Nasdaq calendar |
| LEN.B | Lennar Corporation | Earnings (n/s, FQ Nov/2026) | 2026-12-15 | (E) | $22B | Nasdaq calendar |
| MU | Micron Technology, Inc. [A-queue] | Earnings (n/s, FQ Nov/2026) | 2026-12-16 | (E) | $743B | Nasdaq 12-16; no Micron date notice found (Micron release 2026-11-12 lists only UBS conf. 12-01 and TomorrowX 11-18 fireside chats); vendor calendars 12-16 |
| JBL | Jabil Inc. | Earnings (n/s, FQ Nov/2026) | 2026-12-16 | (E) | $24B | Nasdaq calendar |
| GIS | General Mills, Inc. | Earnings (n/s, FQ Nov/2026) | 2026-12-16 | (E) | $19B | Nasdaq calendar |
| ACN | Accenture plc | Earnings (n/s, FQ Nov/2026) | 2026-12-17 | (E) | $177B | Nasdaq calendar |
| CTAS | Cintas Corporation | Earnings (n/s, FQ Nov/2026) | 2026-12-17 | (E) | $90B | Nasdaq calendar |
| NKE | Nike, Inc. | Earnings (n/s, FQ Nov/2026) | 2026-12-17 | (E) | $59B | Nasdaq 12-17; FMP agrees |
| HEI | Heico Corporation | Earnings (n/s, FQ Oct/2026) | 2026-12-17 | (E) | $46B | Nasdaq 12-17 |
| HEI.A | Heico Corporation | Earnings (n/s, FQ Oct/2026) | 2026-12-17 | (E) | $46B | Nasdaq calendar |
| DRI | Darden Restaurants, Inc. | Earnings (n/s, FQ Nov/2026) | 2026-12-17 | (E) | $26B | Nasdaq calendar |
| KEP | Korea Electric Power Corporation | Earnings (n/s, FQ Sep/2026) | 2026-12-17 | (E) | $14B | Nasdaq calendar |
| FDS | FactSet Research Systems Inc. | Earnings (n/s, FQ Nov/2026) | 2026-12-17 | (E) | $12B | Nasdaq calendar |
| PAYX | Paychex, Inc. | Earnings (n/s, FQ Nov/2026) | 2026-12-18 | (E) | $43B | Nasdaq calendar |
| CCL | Carnival Corporation Ltd. | Earnings (n/s, FQ Nov/2026) | 2026-12-18 | (E) | $40B | Nasdaq 12-18; FMP agrees (FMP terminal row) |
| MDT | Medtronic plc | Earnings (BMO, FQ Oct/2026) | 2026-11-24 | (C) | $134B (W45 Nasdaq field; carried) | **Δ not in this week's Nasdaq pull** (W45 Nasdaq 11-24): Medtronic release 2026-11-04 (news.medtronic.com): results Tue 11-24, release 5:45 am CT, webcast 6:30 am CT; a secondary vendor page still shows an estimated 11-17 |

Aggregator-only A-queue rows outside Nasdaq: none (every forward A-queue name is on the Nasdaq calendar; MDT is not A-queue).

**Full enumeration of the remainder ($2B ≤ mcap < $10B), by session** — Nasdaq reporters NOT in the detail table, ordered by market cap within the day; ᵇ = before open, ᵃ = after close, no mark = time not supplied. All (E).

- **2026-11-16** (8): XPEVᵇ ACMᵃ XPᵃ POWLᵃ TEO BRC DAC PAGSᵃ
- **2026-11-17** (7): KLARᵇ BZ DLBᵃ SRᵇ MNSOᵇ GBDCᵃ MFPᵇ
- **2026-11-18** (13): UGIᵃ GLBEᵇ CPAᵃ DY NJRᵃ GFF GDS GLNGᵇ JOYY HPᵃ BLSHᵇ ZIMᵇ KLIC
- **2026-11-19** (12): YMMᵇ ESTC GAPᵃ ESEᵃ VIPS VVVᵇ BBWIᵇ ROAD POSTᵃ MMSᵇ BULLᵃ DAOᵇ
- **2026-11-20** (6): FRO MOG.A MOG.B VFS IESC BKE
- **2026-11-23** (6): SNEX AMTMᵃ CAAP BWLPᵇ CENT CENTA
- **2026-11-24** (10): NIO URBN ANFᵇ BILIᵇ GGAL AMBA KSSᵇ BBAR KCᵇ CLSK
- **2026-11-25** (2): CMBT BMA
- **2026-11-27** (1): CHA
- **2026-12-01** (6): GTLB BOXᵃ SIG AEO UNFI ASANᵃ
- **2026-12-02** (8): HQY DSGXᵃ PATH M PVH THO KEN NCNO
- **2026-12-03** (9): DCI TTAN S SAIC DOO AGX WLY WLYB IDT
- **2026-12-04** (1): VSXY
- **2026-12-07** (1): HAFN
- **2026-12-08** (7): CNM CPB AVAV OLLI BRZEᵃ KFY ASO
- **2026-12-09** (4): CHWY MTN PL UEC
- **2026-12-10** (3): MANU FIZZ RH
- **2026-12-15** (1): WOR
- **2026-12-16** (3): TTC ABM EPAC
- **2026-12-17** (4): KMX BIRK BB KBH
- **2026-12-18** (2): LW CAG
- **2026-12-21** (1): ABVX

Check: detail 109 + remainder 115 = 224 forward rows (Nasdaq forward 224).

### 1A.2 — Earnings, after the C window up to the dense horizon: empty

Empty by construction: the C window now ends 2026-12-30, beyond the FMP dense horizon (2026-12-18), so the 12-17 / 12-18 rows (NKE 12-17, CCL 12-18, FMP and Nasdaq agree) sit in 1A.1. Nasdaq ≥ $2B returned 12-21: 1 row (ABVX), 12-22 → 12-30: none. No FMP row 12-19 → 2027-01-10. Effective confirmed-earnings horizon 2026-12-18 = 33 days from 2026-11-15 (unchanged, seventh week).

### 1A.3 — Earnings, 2026-12-31 → 2027-05-15

Coverage gap, not absence of events: FMP (4 chunked calls, orchestrator, 2026-11-15) returns nothing 12-19 → 2027-01-10, 58 rows 2027-01-11 → 02-21, and only LCID 02-23 / RKT 02-25 / RIOT 03-01 / FDX 03-25 after that. Window end rolled 05-08 → 05-15; no sourced row falls 05-09 → 05-15 except the BLS CPI (Apr) 05-12 in 1A.6. FMP rows below are all (E).

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
| 2027-02-04 | AAPL · AMZN · CARR · MGM · RBLX · SIRI · SONY |
| 2027-02-09 | F · HOOD · KO |
| 2027-02-10 | CSCO · SHOP |
| 2027-02-11 | COIN · PINS · RIVN · ROKU |
| 2027-02-12 | MRNA |
| 2027-02-18 | ETSY |
| 2027-02-23 | LCID |
| 2027-02-25 | RKT |
| 2027-03-01 | RIOT |
| 2027-03-25 | FDX |

Δ vs W45's FMP table (compared table-to-CSV): **no date changed** for any symbol present in both; newly present SONY 02-04, CSCO 02-10, LCID 02-23; none dropped.

**Per-name tails for A-queue names that have no forward date in the Nasdaq pull ((E) fallback, via web_search; sources are issuer IR pages where stated, otherwise vendor calendars read 2026-11-15):**

| Ticker | Event | Date | Tag | Source |
|---|---|---|---|---|
| GEV | GE Vernova Q4 2026 earnings webcast | 2027-01-27, 7:30-8:30 am EST | **(C) Δ NEW** | gevernova.com/investors/events/4th-quarter-2026-earnings-webcast (issuer event page, via web_search); vendor calendars agree |
| MRK | Q4 2026 call | 2027-02-02 | (C) carried | merck.com (W43-W45), not re-read; FMP shows no MRK row |
| MRK | Q1 2027 call | 2027-04-29 | (C) carried | merck.com, not re-read |
| JPM | Q1 2027 / Q2 / Q3 earnings calls | 2027-04-13 / 07-13 / 10-12 (8:30 am ET) | **(C) Δ NEW** | JPMorganChase release 2026-10-27 "Updates 2027 Earnings Release Date Information" (jpmorganchase.com). The release also moves Q4 2027 to 2028-01-13 (outside window) and does not state the Q4 2026 date |
| JPM | Q4 2026 results | 2027-01-14 | (E) | FMP; JPM Q4 2026 date not in the 10-27 release |
| AAPL | FQ1 FY27 | 2027-02-04 (FMP, GoBull, fru.dev) or 2027-01-28 (Wall Street Horizon, days.to) | (E), vendors CONFLICT | Apple IR page lists only the printed 11-02 call; no Apple date notice |
| MSFT | FQ2 FY27 | 2027-01-27 | (E) | FMP + GoBull/earningsmadness/days.to |
| META | Q4 2026 | 2027-01-27 | (E) | FMP + vendor pages |
| GOOGL | Q4 2026 | 2027-02-03 | (E) | FMP + vendor pages |
| AMZN | Q4 2026 | 2027-02-04 (after close) | (E) | FMP; Wall Street Horizon "UNCONFIRMED"; fru.dev projected |
| AMD | Q4 2026 | 2027-02-02 | (E) | FMP; days.to; findeal |
| INTC | Q4 2026 | 2027-01-28 | (E) | FMP; earningsdriver "late January" |
| XOM · CVX | Q4 2026 | 2027-01-29 | (E) | FMP; CVX also howmanytradingdays 01-29 (before open) |
| CEG | FQ4 2026 (printed 11-09; next) | 2027-02-23 (howmanytradingdays) or 2027-02-25 (TipRanks, Quartr) | (E), vendors differ by 2 days | constellationenergy.com IR page lists only the 11-09 call |
| LLY | Q4 2026 | 2027-02-03 (earningsmadness) or 2027-02-02 (ChartMill) | (E), vendors differ | no Lilly notice |
| IBM · NOW | Q4 2026 | 2027-01-27 (after close) | (E) | earningsmadness, Theta (IBM, consensus EPS 4.63) |
| CAT | Q4 2026 | 2027-01-28 (before open) | (E) | earningsmadness 2026-11-11 |
| AKAM | Q4 2026 | 2027-02-18 (after close) | (E) | findeal, howmanytradingdays, marketchameleon, Robinhood via wallstreetobserver 2026-11-06 ("tentatively"); steadybase shows 2027-02-04 |
| ANET | Q4 2026 | 2027-02-11 (after close) | (E) | howmanytradingdays, findeal |
| DDOG | Q4 2026 | 2027-02-09 (before open) | (E) | fru.dev projection, findeal |
| QCOM | FQ1 FY27 | 2027-02-03 (after close) | (E) | fru.dev projection, findeal |
| SMCI | FQ2 FY27 | 2027-02-02 | (E) | findeal only |
| FSLR | Q4 2026 | 2027-02-23 | (E) | findeal only |
| VRTX | Q4 2026 | 2027-02-11 (after close) | (E) | Zacks (page dated 2026-11-13, "estimated date"), earningsmadness |
| CSCO | FQ2 FY27 (after the 11-12 print) | 2027-02-10 | (E) | FMP; howmanytradingdays "expected Feb 10, 2027" |
| AMAT | FQ1 FY27 (after the 11-12 print) | 2027-02-11 | (E) | fru.dev projected |
| NTAP | FQ3 FY27 / FQ4 FY27 | target 2027-03-04 / 2027-06-03 (second is outside the window) | (C) issuer target | NetApp release 2026-11-10 "Future Targeted Release Dates" |
| NVDA | FQ4 FY27 | ~2027-02-24 | (E) carried | days.to / WSH inferred (W45), not re-searched |
| AVGO | FQ1 FY27 | ~2027-03-03 | (E) carried | days.to projection (W45) |
| ORCL | FQ3 FY27 | ~2027-03-09/10 | (E) | fru.dev "Mar 9, 2027"; W45 ~03-10 |
| MU | FQ2 FY27 | ~2027-03-17 | (E) | fru.dev "Mar 17, 2027"; W45 carried |
| FDX | FedEx | 2027-03-25 (FMP chunk 3) vs 2027-02-02 (FMP chunk 2) | (T) | FMP internal conflict; neither relied on |

**No date at all found:** COP (IR page lists only the printed 11-05 call), NBIS (Q4 date not returned by the search), TTWO (FQ3 print date not searched/returned). No search for the post-print date of CRM, CRWD, SNOW, OKTA, MRVL, HD, TGT, WMT, INTU, PANW, HPE, DELL, ADBE (all beyond 2027-02 and mostly outside vendor horizons).

### Printed this week (2026-11-09 → 2026-11-13)

A-queue and ≥ $50B names whose Nasdaq date fell 11-09 → 11-13 (158 printed-week rows at ≥ $2B; 16 listed). These drop out of the forward calendar. A Nasdaq date is a schedule, not evidence of a print; the 'Print evidence' column states what was seen this run. D1's last run is 2026-11-09 so D1 records for 11-10 → 11-13 do not exist; outcomes were not researched (date-of-print only).

| Ticker | Name | Nasdaq date | A-queue | Mcap | EPS fcst (Nasdaq, n est) | Print evidence |
|---|---|---|---|---|---|---|
| CEG | Constellation Energy Corporation | 2026-11-09 BMO | A | $88B | $3.90 (5) | (C) Constellation release dated 2026-11-09 (constellationenergy.com) "Reports Third Quarter 2026 Results" |
| KKR | KKR & Co. Inc. | 2026-11-09 BMO | | $87B | $1.41 (7) | Nasdaq date only |
| B | Barrick Mining Corporation | 2026-11-09 BMO | | $66B | $0.74 (5) | Nasdaq date only |
| OXY | Occidental Petroleum Corporation | 2026-11-09 AMC | | $56B | $1.43 (10) | Nasdaq date only |
| TTWO | Take-Two Interactive Software, Inc. | 2026-11-09 AMC | A | $40B | $0.49 (6) | (C) Take-Two 8-K Ex. 99.1 filed 2026-11-09 (sec.gov via web_search): FQ2 FY27 results, net bookings $1.60B; FY27 net bookings outlook $8.0-$8.2B reiterated; GTA VI release date listed November 19, 2026 |
| PBR · PBR.A | Petroleo Brasileiro S.A.- Petrobras | 2026-11-10 AMC | | $118B | $1.38 (2) | Nasdaq date only |
| TDG | Transdigm Group Incorporated | 2026-11-10 BMO | | $67B | $11.43 (5) | Nasdaq date only |
| CSCO | Cisco Systems, Inc. | 2026-11-12 AMC | A | $397B | $1.15 (8) | issuer notice (W45: call 11-12 1:30 pm PT); print itself not opened |
| AMAT | Applied Materials, Inc. | 2026-11-12 AMC | A | $313B | $4.06 (10) | secondary: distillintelligence weekly briefing 2026-11-13 cites an Applied Materials announcement dated 11-12 "reports record fourth quarter and fiscal 2026 results" (quarterly sales +53% to $10.41B, as quoted); applied materials release not opened |
| BN | Brookfield Corporation | 2026-11-12 BMO | | $103B | $0.72 (3) | Nasdaq date only |
| NU | Nu Holdings Ltd. | 2026-11-12 n/s | | $59B | $0.22 (4) | Nasdaq date only |
| NBIS | Nebius Group N.V. | 2026-11-12 BMO | A | $42B | ($0.61) (4) | issuer notice 2026-10-30 (nebius.com/newsroom: results Thu 11-12 before open, call 8:00 am ET); print itself not opened |
| MUFG | Mitsubishi UFJ Financial Group | 2026-11-13 n/s | | $258B | $0.45 (1) | Nasdaq date only |
| SMFG | Sumitomo Mitsui Financial Group | 2026-11-13 n/s | | $155B | $0.24 (1) | Nasdaq date only |
| MFG | Mizuho Financial Group, Inc. | 2026-11-13 n/s | | $125B | $0.21 (1) | Nasdaq date only |

A-queue names printed in the week: CEG 11-09, TTWO 11-09, CSCO 11-12, AMAT 11-12, NBIS 11-12 (5 of 47). Decision-log note: D1's 2026-11-09 sector record 8327041f cites NVDA -6% on 11-09 (a price move, not a catalyst row); no D1 earnings-move record exists for the five printers above. Rolled off from W45's forward calendar (dated before 2026-11-15): every W45 row dated 11-09 → 11-13, i.e. the W45 detail rows KKR, CEG, B, OXY, TTWO, PBR, TDG, CSCO, AMAT, BN, NU, NBIS, MUFG, SMFG, MFG and the 158 printed-week names in total.

### 1A.4 — Product launches, keynotes, developer events (window 2026-11-15 → 2027-05-15)

Passed/resolved since W45 (rolled off, dated before 2026-11-15): Adobe MAX, Miami Beach, 2026-11-10 → 11-12 (preconference 11-08/09; occurrence not verified). Rows below are carried from W45 unless a Δ is shown. Minimum 11-10 → 11-13 check: no search returned a change to the dated rows below.

| Ticker/Event | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| MSFT | Microsoft | Ignite, Moscone Center, San Francisco (pre-day 11-16) | 2026-11-17 → 11-20 | (E) carried | moscone.com/events/microsoft-ignite-2026 + listings (W45); not re-read |
| TTWO | Take-Two | Grand Theft Auto VI launch (PS5, Xbox Series X\|S) | 2026-11-19 | **(C) Δ upgraded from (C-secondary)** | Take-Two 8-K Ex. 99.1 dated 2026-11-09 (sec.gov / ir.take2games.com): "The launch of Grand Theft Auto VI is ten days away"; lineup table lists "November 19, 2026"; press coverage 11-10 says pre-loads opened 11-10 |
| AMZN | Amazon | Black Friday / Cyber Week promotions | 2026-11-19 → 11-30 | (C-secondary) **Δ NEW** | Seeking Alpha news 2026-11-10 (Amazon announcement of Tuesday 11-10); Amazon release not opened |
| AMZN | Amazon | AWS re:Invent, Las Vegas (badge/kickoff 11-29) | 2026-11-30 → 12-04 | (C) carried | aws.amazon.com/events/reinvent (W45 WebFetch), not re-read |
| NVDA | NVIDIA | GTC Washington, D.C. (workshops 11-30, conference 12-01 → 12-03; W45 listed a Huang keynote Tue 12-01 2:00 pm ET) | 2026-11-30 → 12-03 | (C) event dates carried; keynote speaker **UNCERTAIN** | nvidia.com/gtc/dc (W45). **Δ context:** NVIDIA announced 2026-11-12 that Jensen Huang resigned as CEO (Kress interim CEO); no source seen this run says whether the 12-01 keynote speaker changed |
| MU | Micron | Fireside chats: TomorrowX Summit, Austin (11-18 10:50 am MT); UBS 30th Global Technology and AI Conference, Scottsdale (12-01 8:15 am MT) | 2026-11-18; 2026-12-01 | (C) **Δ NEW** | Micron release 2026-11-12 (investors.micron.com / GlobeNewswire) |
| GOOGL | Alphabet | Waymo multi-city robotaxi launches | 2026 (year only) | (T) carried | |
| HPE | HPE | UBS Global Technology and AI Conference (12-02); Barclays 24th Global Technology Conference (12-09) | 2026-12-02; 2026-12-09 | (C) **Δ NEW** | investors.hpe.com News & Events (via web_search; Strategic-officer fireside chats) |
| — | broad | CES 2027, Las Vegas Convention Center | 2027-01-06 → 01-09 | (E) carried | listings (W45); CTA page not reached |
| — | healthcare broad | J.P. Morgan Healthcare Conference, San Francisco | 2027-01-11 → 01-14 | (E) carried | event-listing sites; not re-verified |
| NVDA | NVIDIA | GTC 2027 San Jose | 2027-03-14 → 03-18 | (C) carried | nvidia.com GTC FAQ (W43/W44), not re-read |
| AMD | AMD | Product news 2026-11-10/12: 6th Gen EPYC launched (11-10); MI450X/MI455X Instinct MI400 details (11-12) | 2026-11-10 → 11-12 (past) | (C-secondary) context | distillintelligence 2026-11-13 cites AMD announcements; not a forward catalyst |

### 1A.5 — Analyst and investor days

Passed/resolved since W45 (rolled off): ENTG Investor Day NYC 2026-11-09 (scheduled date; occurrence not verified). Rows carried from W45, not re-verified this run (no investor-day sweep; the 11-10 → 11-13 minimum check found no new A-queue investor day).

| Ticker/Event | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| MH | McGraw Hill | Investor Day, NYC | 2026-11-18 | (E) carried | briefglance only |
| SHC | Sotera Health | Investor Day, NYC | 2026-11-20 | (T) carried | year not shown; unverified |
| NTR | Nutrien | Investor Day, Toronto | 2026-11-30 | (C) carried | Nutrien release 2026-09-23, not re-read |
| NU | Nu Holdings | First Investor Day, NYC | 2026-12-08 | (C) carried | Nu Holdings release 2026-09-02, not re-read |
| NKE | Nike | Investor day "Fall 2026" | — | (T) carried | |
| UNH | UnitedHealth | Investor conference | ~2026-12 early | (E) carried | |
| JPM | JPMorganChase | Investor Day | 2027-02-22 | (C) carried | not re-fetched |

### 1A.6 — Regulatory, legal, trade and macro

PDUFA rows are mirrored in 1B.3 by another part (window to 12-30 there; this table runs to 2027-05-15). Macro dates marked (C) from bls.gov / federalreserve.gov unless noted; carried rows were not re-read.

**Passed/resolved since W45 (rolled off, outcomes not researched except where noted):**
- CPI (Oct) 2026-11-10: released (BLS: CPI-U +0.4% SA in October after +0.6% in September; energy +0.7%) — bls.gov news release page.
- Busan truce lapse ~2026-11-10: resolved by extension to 2027-01-09/10 (new row below; replaces W45's uncorroborated (E) row and the W43 "USTR Sec 301 exclusions expire 11-10" row).
- SMMT ivonescimab BLA PDUFA 2026-11-14 and CYTK aficamten label expansion 2026-11-14: dates passed; outcomes NOT researched here.
- PPI (Oct) 2026-11-13; Employment Situation (Oct) 2026-11-06: passed.
- Midterm elections 2026-11-03: held (carried context: D1 a4e2f628).

| Ticker/Event | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
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
| — | broad | **FOMC decision + SEP/dot plot** | 2026-12-09 (meeting 12-08/09) | (C) | federalreserve.gov/monetarypolicy/fomccalendars.htm fetched by W45 2026-11-08 (carried, not re-fetched): "December 8-9, 2026 * (SEP)"; last 2026 meeting |
| — | broad | CPI (Nov) | 2026-12-10 | (C) carried | calendars; bls page not re-read |
| — | broad | US government funding: CR (P.L. 119-103) runs to **2026-12-11**; full-year FY27 appropriations unfinished | 2026-12-11 | (C-secondary) Δ updated | CR terms carried from W45 (signed 2026-09-02). **New:** Punchbowl News 2026-11-13: "Congress is almost certain not to pass a full year of government funding by the Dec. 11 deadline"; a dispute over Iran-war funding is raising shutdown risk; options discussed include a short-term CR into early 2027 (article text via web_search; not an outcome) |
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
| — | broad | CPI (Nov) | 2026-12-10 | (C) Δ upgraded | bls.gov schedule + October CPI release footer (2026-11-13 page): "scheduled to be published on Thursday, December 10, 2026, at 8:30 a.m. (ET)" |
| — | broad | CPI (Dec) / (Jan) / (Feb) / (Mar) / (Apr) | 2027-01-13 / 02-11 / 03-10 / 04-13 / 05-12 | (C) | bls.gov/schedule/news_release/cpi.htm (web_search 2026-11-15); the 2027-05-12 CPI (Apr) row is new inside the window |
| — | broad | U.S. Import and Export Price Indexes (Oct) | 2026-11-17 | (C) | bls.gov Nov 2026 schedule (web_search) |
| — | US-China | Busan truce suspensions and USTR Section 301 exclusions (178) now run to **2027-01-09 / 2027-01-10** | 2027-01-09 → 01-10 | (C) US side; (C-secondary) China side | USTR notice in Federal Register 2026-11-10 (federalregister.gov, 2026-22925): all 178 exclusions extended through 11:59 pm ET 2027-01-09; China Briefing 2026-11-10 timeline: China's Tariff Commission extended its tariff suspension and export-control suspensions to 2027-01-10 (announced 2026-11-09), BIS Affiliates Rule suspension extended to 2027-01-10 (announced 11-05); China had not confirmed the extension in that report. Replaces W45's uncorroborated (E) row |
| — | US-China | Trump-Xi meeting at APEC Summit, Shenzhen | 2026-11-18 → 11-19 | (C-secondary) | China Briefing 2026-11-10 and The Edge 2026-11-11 (Bessent remarks "next week"); no official schedule page opened |
| NVDA | NVIDIA | Leadership: Jensen Huang resigned as President/CEO/director 2026-11-12; Colette Kress interim CEO; FQ3 FY27 results still scheduled 11-17 | 2026-11-12 (event) | (C-secondary) | NVIDIA announcement dated 2026-11-12 as quoted by a secondary digest (X/TheValueist 2026-11-12) and distillintelligence 2026-11-13; nvidia.com not opened. Entered here because the W45 GTC-DC row names a Huang keynote (1A.4) |

**UNP·NSC STB schedule note (carried from W45, STB document not opened):** FreightWaves/Trains summaries of the STB's 2026-08-18 decision report final briefs due 2027-05-28 and a final decision within 90 days after the record closes; the three W45 UNP·NSC rows (11-18, 12-03, 2027-02-16) were not reconciled with that schedule and remain "possibly superseded".

**Tariff / legal note (carried from W45, not re-verified):** Supreme Court struck down IEEPA tariffs (Learning Resources v. Trump, Feb 2026); Section 122 surcharge lapsed; CBP IEEPA refund phase for finally-liquidated entries opened 2026-10-06 (secondary); Section 232 semiconductor tariff 25% (effective 2026-01-15) stands; Section 301 tariffs on Chinese semiconductors scheduled 2027-06-23 (outside window). Δ new this run: the Section 301 exclusion extension to 2027-01-09 (row above).

### 1A.7 — Restructuring, M&A and structural

D1 developments since 2026-11-01 (reused from W45, not re-searched): MRVL–LITE merger (da7bf33a); CVI/Marathon Petroleum refinery assets (c51c9632); MMM PFAS MDL settlement (7701d3bc); NEOG–Zoetis genomics (f5359185); ORCL $10B common stock issuance (f5359185); FCX Bagdad (f5359185); FWONA/FWONK exchange agreement (f5359185); PENG LED sale (7701d3bc); INGM secondary (f5359185); DT/PTCT buybacks (c51c9632); SYY CFO (c51c9632); UEC uranium agreements (f5359185). M2 note (67f68f9a, 2026-11-01): Skyworks–Qorvo closed 2026-10-05; WBD acquired by Skydance and delisted 2026-10-06; WDAY take-private unconfirmed; Kenvue pending (KMB/PG). D1 add-candidate records 5ada3494 / 226bf170 (GEV watch item: unquantified 11-06 claim that SoftBank is defaulting on turbine orders) — see the GEV row below for the 11-10 follow-up (new, not D1).

| Ticker/Event | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| — | Anthropic | **Δ firmer: IPO priced/listed on a stated schedule.** Public S-1 filed late Oct 2026; amended S-1 released Tue 2026-11-10: 825 million shares at $70-$78 (implied market value $1.3-$1.45 trillion per Yahoo Finance); pricing Wed **2026-11-18**, trading Thu **2026-11-19** under Nasdaq ticker "ANT" (company announcement 11-12 per Yahoo Finance; ipo.anthropic.com not opened); CNBC 11-10 cites people familiar for ~20% retail allocation. Related chip/cloud-supplier participation reported: AMD agreed to invest up to $5B tied to a 2 GW GPU deployment and Nvidia a planned $10B (Crypto Briefing / NYT headlines via distillintelligence 2026-11-13, secondary) | 2026-11-18 (price) / 2026-11-19 (first trade) | (C-secondary) | CNBC 2026-11-10; Yahoo Finance 2026-11-12; EDGAR not opened. D1 cb06c3e0 cites an "Anthropic S-1" as a sector driver 10-26/27 |
| AKAM | Akamai Technologies [A-queue] | Report of a seven-year, $11.6B infrastructure commitment from Anthropic with an equity warrant; AKAM +16% premarket | date not shown in the snippet (appears after the 11-06 earnings coverage) | (E) single secondary snippet | wallstreetobserver.com page footer ("More on this"), not opened; Akamai 8-K filed 2026-11-12 titled "Entry into a material definitive agreement" per steadybase (SEC list, 11-13) — filing not opened; **unverified link between the two** |
| GEV | GE Vernova [A-queue] | SoftBank (Tokyo) reported a $3.7B write-down on prepaid power equipment on 2026-11-10 (SoftBank CFO: "There is no such default"; $2.85B non-refundable advance payments to equipment suppliers; WSJ reports >13 GW of gas-turbine reservations "mostly from GE Vernova"); GE Vernova told WSJ the moves had "no negative or positive impact"; GEV shares fell after the results | 2026-11-10 | (C-secondary) | Bloomberg 2026-11-10 (headline/excerpt), The Next Web 2026-11-12, 24/7 Wall St. 2026-11-12 via web_search; GE Vernova gas backlog+reservations 122 GW as of 10-28 per same source; resolves the unquantified D1 watch item (facts, no interpretation) |
| NVDA | NVIDIA [A-queue] | CEO transition: Huang resigned 2026-11-12; Kress interim CEO and CFO; Harvey Jones named first-ever Chair; US authorities reported probing a Huang relationship and possible China-bound chip smuggling involving partner Supermicro (reports via Bloomberg/Fortune headlines, secondary; shares fell as much as 14% per distillintelligence) | 2026-11-12 | (C-secondary) | NVIDIA announcement quoted in X/TheValueist digest 2026-11-12; distillintelligence briefing 2026-11-13; **SMCI is A-queue** — the DOJ/Supermicro item is a secondary report, nvidia.com and DOJ not opened |
| AMD | AMD [A-queue] | Agreed to acquire World Labs (~$8.2B, announced Sept; expected to close by end of 2026); 2026-11-10 headline: AMD puts $2.9B price on Taalas | close ~end 2026; Taalas 2026-11-10 | (E) secondary headlines | 36kr 2026-11-12 (World Labs); dealroom archive 2026-11-10 (Taalas); not opened |
| MRVL·LITE | Marvell / Lumentum | All-stock merger: 4.500 MRVL shares per LITE share; agreement dated 2026-11-01; implied LITE EV stated $115B; closing 1H calendar 2028 subject to stockholder votes and regulatory approvals; no meeting dates set. **Δ 2026-11-12:** Marvell announced three new independent directors (Morris, Bettinger, Goodarzi; board 7 → 10), per the X/TheValueist digest of 2026-11-12 | announced 2026-11-02; close 1H 2028 | (C) carried (merger) / (C-secondary) (board) | Marvell IR PR and LITE 8-K (W45, not re-read); board item via X/TheValueist 2026-11-12 |
| EQT·RRC | EQT / Range | All-stock merger; close Q1 2027 | ann. 2026-10-26 | (C) carried | see 1A.6 |
| SGRY | Surgery Partners | Take-private (D1) | ann. ~2026-10-26 | (C per D1; terms not read) carried | D1 7d029722 |
| ADT | ADT | Deal (D1) | ~2026-10-29 | terms not read, carried | D1 b1e61b9c |
| PCRX·VTRS | Pacira / Viatris | $36.50 cash tender, ~$1.65B; closing "by end of 2026" | ann. 2026-10-08; close by ~2026-12-31 | (C) carried | Viatris 8-K; not re-read |
| NEOG·ZTS | Neogen / Zoetis | Genomics business sale; regulatory review to conclude early 2027 | early 2027 | (C per D1 8-K) carried | D1 f5359185 |
| (other W45 carried items) | PTC·Schneider; OPCH·CD&R/McKesson (close undated); ON·SYNA; UBER/ezCater; CMG·SBUX (T); ORCL/OpenAI (T); CVX·HESM; WDAY (T); CAT Fabick; KMB·KVUE (merger outside date extended to 2027-05-03, (E)); TECK; CTVA Vylor spin (Q4); Nasdaq-100 recon mid-Dec (E); S&P Q4 rebalance 2026-12-18 (E); DG CEO transition 2027-01-01; S&P Q1 rebalance 2027-03-19 (E) | | | carried unchanged, not re-verified | W45 |

### 1A.8 — Universe rails (carried, dated)

**Market-cap rail (≥ $2B).** Inside the C window the rail is Nasdaq's own `marketCap` field (every one of the 224 forward rows is ≥ $2B by construction; the smallest forward A-queue names by that field are OKTA $33B, NTAP $37B and TTWO $40B (printed), all far above the floor; MEASURED from the CSV). Prior direct measurements are CARRIED, not re-measured: 2026-10-04 (61 names, 0 FAIL, smallest AAL $8.57B, AKAM $15.84B, FSLR $18.77B) and 2026-10-09 (50 vendor-calendar names via `company/batch-market-cap`, 0 FAIL, smallest RIOT $6.39B); that data is now 42 and 37 days old. **FAIL the cap floor, A-ineligible:** FUBO ($0.88B, Nasdaq all-caps file, MEASURED this run) and LCID ($1.30B on 11-09 per the same file; its FMP row is now 2027-02-23); TLRY carried. **ADR rail (carried):** TSM, NOK, SONY, BILI, BIDU, BABA, NIO, GSK, SAN, RHHBY are A-ineligible. **Unmeasured this cycle:** the FMP 2027 rows beyond 12-30 (e.g. RKT, RIOT, SOFI, HOOD, COIN, PINS, ETSY, SNAP, ROKU, SIRI, RBLX, MGM) are cap UNMEASURED.

### 1A.9 — Rows struck, rejected or corrected this cycle (earnings only)

1. ~~All 2026-11-09 → 11-13 forward rows~~ — elapsed; moved to 'Printed this week'. W45 rows for TTWO/CSCO/AMAT/NBIS (all tagged (C)) were checked for occurrence only as stated in that table (TTWO 8-K seen; CEG release seen; AMAT secondary; CSCO and NBIS issuer notices only).
2. **Δ BABA 2026-11-24 (E, Nasdaq) → 2026-11-19 BMO (C)** — Alibaba release 2026-11-06 (web_search); FMP was right, the cached Nasdaq page was wrong. W45 disagreement closed.
3. **Δ AVGO 2026-12-10 (E) → 2026-12-09 AMC (C)** — Broadcom release 2026-11-09 (broadcom.com). Nasdaq still shows 12-10.
4. **A-queue / ≥ $50B date confirmations upgraded this run ((E) or (C-secondary) → (C)):** INTU 11-19, HPE 11-23, DELL 11-24, CRWD 12-01, NTAP 12-01, CRM 12-02, ADBE 12-09, AVGO 12-09, BABA 11-19, MDT 11-24 (not A-queue). GEV 2027-01-27 and JPM 2027-04-13 added as (C) tails (1A.3).
5. **Δ ORCL: DATE CONFLICT, unresolved** — Nasdaq/vendors 2026-12-09 vs Oracle IR FAQ page (web_fetch acquired_at 2026-10-26) "Second Quarter Fiscal Year 2027 earnings will be announced on December 14, 2026". No dated Oracle release seen; carried as (E) at 12-09 with the conflict stated.
6. **Δ Nasdaq date moves vs W45 (all (E)):** ZS 12-02 → 11-24 (Theta still 12-02); DLTR 11-24 → 12-02; BNS 12-02 → 12-01; SIG 12-02 → 12-01; BMO 12-02 → 12-03; DCI 12-02 → 12-03; HQY 12-01 → 12-02; TEO 11-09 → 11-16. New in the pull: MFP 11-17, CLSK 11-24.
7. **Dropped from the Nasdaq pull with no print evidence (not struck, flagged):** MDT (W45 11-24; issuer release confirms 11-24, restored to 1A.1), MDB (W45 12-01; scrutar shows an (E) 11-30), NTSK (W45 12-02; scrutar 12-10), MMED, SBLK (W45 11-17). Not re-searched beyond MDT.
8. **Still NOT issuer-confirmed in the forward A-queue:** ORCL (conflict), MU 12-16 (no notice; Micron release 11-12 names only conferences). PANW remains (C-secondary).
9. Theta (secondary vendor) shows "DIS reported 2026-11-12" and "BABA 2026-11-13": both contradicted by issuer pages (Disney IR event page 11-17; Alibaba 11-19) — not used.
10. FMP lists FDX on both 2027-02-02 and 2027-03-25; both (T).

### 1A.10 — Names with NO firm forward earnings date

**Newly (C) this run (A-queue):** INTU 11-19, HPE 11-23, DELL 11-24, CRWD 12-01, NTAP 12-01, CRM 12-02, ADBE 12-09, AVGO 12-09; GEV 2027-01-27 (first-seen (C)). Carried (C): NVDA 11-17, HD 11-17, TGT 11-18, WMT 11-19, MRVL 12-01, OKTA 12-01, SNOW 12-02 and (C-secondary) PANW 11-18.

**Forward A-queue names with only an (E) or conflicted date (2):** ORCL (12-09 vs 12-14 conflict), MU 12-16.

**Printed 11-09 → 11-13 (5):** CEG, TTWO, CSCO, AMAT, NBIS (next print: see 1A.3 tails; TTWO and NBIS none found).

**A-queue names with NO forward date in the Nasdaq pull (24):** AAPL, AKAM, AMD, AMZN, ANET, CAT, COP, CVX, DDOG, FSLR, GEV, GOOGL, IBM, INTC, JPM, LLY, META, MRK, MSFT, NOW, QCOM, SMCI, VRTX, XOM. Of these: (C) GEV 2027-01-27, MRK 2027-02-02 (carried), JPM Q1 2027-04-13 (Q4 2026 2027-01-14 (E)); (E) tails in 1A.3 for AAPL, AMD, AMZN, GOOGL, MSFT, META, INTC, XOM, CVX, LLY, IBM, NOW, CAT, AKAM, ANET, DDOG, QCOM, SMCI, FSLR, VRTX; **no date at all found: COP** (plus TTWO and NBIS next prints).

### 1A.11 — Liquidity rail (30-day ADV ≥ $10M), carried

CARRIED from the 2026-10-04 measurement (IBKR regular-session daily bars, 2026-08-21 → 2026-10-02): 61 of 61 cleared; lowest VRTX $222.0M (~22x floor). NOT re-measured by this part (now 42 days old). Names beyond that list (UAL, NFLX, GE, GM, LMT, CLS, NU, ENTG, EPAC, SHC, MH, NTR, ALAB, ROK, A, RKT, LITE, CEG) are UNMEASURED for ADV; ≥ $10M is INFERRED for large caps, unknown for EPAC/SHC/MH.

## PART 1B — Strategy C universe, 45-day window (2026-11-15 → 2026-12-30)

C qualifying types only: earnings (company IR), FDA PDUFA, FOMC. No interpretation. The C window is 2026-11-15 → 2026-12-30 (run date + 45 days, same convention as W45). The 12-08/09 FOMC sits inside. Tags: (C) confirmed by issuer/authority, (C-secondary) issuer notice seen only via copy/snippet, (E) estimated (vendor/aggregator), (T) tentative. 'carried' = read last cycle (W45) and not re-read this run. Δ = change vs W45. Market caps are the Nasdaq `market_cap_usd` field in the shared 2026-11-15 pull ($B, rounded). Caveat: Parallel `acquired_at` shows many Nasdaq pages for dates after 11-16 were cached 10-23..11-10, so Nasdaq dates after 11-16 reflect Nasdaq as of that cache time. Metered calls this part: 14 Parallel calls (11 web_search, 3 web_fetch covering 11 URLs; 22 log rows incl. one per URL and per search); log at `w1/calls_1b.csv`. No SEARCH GUARD event.

### 1B.1 — FOMC

| Event | Meeting | Decision / release date | In C window (11-15 → 12-30) | Tag | Source |
|---|---|---|---|---|---|
| FOMC | 2026-10-27/28 (no SEP) | Decision 2026-10-28 (held per W45 carry). **Minutes of the Oct 27-28 meeting: 2026-11-18, 2:00 pm ET** | Decision passed; **minutes YES (11-18)** | minutes date (C-rule, inferred): page states "minutes ... released three weeks after the date of the policy decision" (10-28 + 21 d = 11-18); the same 11-18 2:00 pm ET slot appears in StockTitan's 2026-11-13 week-ahead (secondary) | federalreserve.gov/monetarypolicy/fomccalendars.htm (Parallel fetch, acquired 2026-11-15, page "Last Update: November 12, 2026"); stocktitan.net/articles/earnings-calendar-week-of-november-16-2026 |
| FOMC | 2026-12-08/09, **SEP/dot plot meeting** | **Decision 2026-12-09** (page lists "8-9*", "*Meeting associated with a Summary of Economic Projections") | **YES** (day 25 of the window counting 11-15 as day 1) | (C) scheduled | same fomccalendars.htm |
| FOMC minutes | 2026-12-08/09 meeting | **2026-12-30** | **YES (last day of window)** | (C-rule, inferred): 12-09 + 21 d = 12-30; precedent on the same page: 2025-12-10 meeting minutes "Released December 30, 2025". The page does not state the 2026 date. | same |
| FOMC | 2027-01-26/27 | 2027-01-27 | No | (C) scheduled (tentative until confirmed at preceding meeting per page note) | same |
| FOMC | 2027-03-16/17 (SEP) | 2027-03-17 | No | same | same |

Page also lists 2027 meetings 04-27/28, 06-08/09, 07-27/28, 09-14/15, 10-26/27 ("Monetary Policy Strategy Meeting"), 11-16/17 and a 2028-01-25/26 meeting; none in window. Δ vs W45: window end 12-23 → 12-30, so the Dec FOMC minutes (12-30) enter the window; Dec meeting day 32 → day 25 (window start moved 11-08 → 11-15); the Oct minutes (11-18) were outside W45's reading as "not yet" and are now in window. C queue holds thesis-FOMC-C-20261130 (orchestrator-MEASURED, state_brief).

### 1B.2 — Earnings inside the C window: company-IR-confirmed subset

Window 2026-11-15 → 2026-12-30. Nasdaq forward rows (≥ $2B) dated 11-16 → 12-30 = 224 rows (11-26, 12-23, 12-25, 12-31 returned zero rows; 12-24/28/29/30 carry only sub-$2B or no ≥$2B names). **Struck (printed 11-09 → 11-13, before the window):** KKR, B, TTWO, CEG, OXY, TDG, BN, NU, CSCO, NBIS, AMAT, MUFG, SMFG, MFG, PBR, plus all other W45 rows dated 11-09..11-13 (their prints are not read here; D1 did not cover 11-10..11-13 per state_brief). Checked this run (issuer IR / issuer press release via Parallel, first-hand page excerpt unless noted): every ≥$50B or A-queue name that W45 carried as (E) with a date in window, plus ADI, ADSK, DE, BABA, ZS, NTAP, OKTA, COST.

**Company-IR confirmed (C)**

| Date | Ticker | Timing | Mcap ($B) | Confirmation (source, date) | Δ vs W45 |
|---|---|---|---|---|---|
| 2026-11-17 | NVDA | after close; call 2:00 pm PT | 4,306 | carried (NVIDIA newsroom, W45); StockTitan 2026-11-13 lists "Confirmed", citing NVIDIA notice of 2026-10-28 (secondary) | — |
| 2026-11-17 | DIS | pre-market; webcast 8:30 am ET | 206 | carried (Disney release 2026-10-12, W45); StockTitan 2026-11-13 "Confirmed" (secondary) | — |
| 2026-11-17 | HD | pre-market; call 9:00 am ET | 353 | **NEW (C)** ir.homedepot.com "The Home Depot to Host Third Quarter Earnings Conference Call on November 17", PRNewswire 2026-11-03; IR events page lists "Q3 2026 ... EARNINGS RELEASE Tuesday, November 17, 2026 9:00 am ET" | E → C (W45 vendor-only) |
| 2026-11-18 | PANW | after close (Nasdaq) | 258 | carried (Palo Alto Networks release 2026-11-03, W45 search extract); webcast time not shown | — |
| 2026-11-18 | TGT | pre-market | 72 | carried (corporate.target.com, W45); StockTitan 2026-11-13 cites Target investor events page, call 8:00 am ET (secondary) | — |
| 2026-11-18 | TJX | before 9:30 am ET; call 11:00 am ET | 152 | **NEW (C)** investor.tjx.com "The TJX Companies, Inc. to Report Q3 FY27 Results November 18, 2026", Business Wire 2026-11-04; tjx.com reporting calendar lists Q3 FY27 "November 18, 2026" | E (W45 secondary German outlet) → C |
| 2026-11-18 | LOW | pre-market; call 9:00 am ET | 127 | **NEW (C)** corporate.lowes.com "Lowe's Companies, Inc. to Host Third Quarter 2026 Earnings Conference Call on Nov. 18", PRNewswire 2026-11-11 (IR page also lists 2026 Analyst and Investor Conference 12-09, 8:00 am ET, NYC) | E → C |
| 2026-11-19 | WMT | pre-market; call 8:00 am ET | 1,013 | carried (corporate.walmart.com, W45); StockTitan 2026-11-13 cites Walmart notice of 2026-11-12 (secondary) | — |
| 2026-11-19 | INTU | after close; call 1:30 pm PT | 95 | carried (Intuit release 2026-10-29, W45) | — |
| 2026-11-19 | BABA | before US open; call 7:00 am ET | 243 | **NEW (C)** alibabagroup.com "Alibaba Group Will Announce September Quarter 2026 Results on November 19, 2026", dated 2026-11-06; IR page "Upcoming Events November 19, 2026" | **Δ date: Nasdaq/W45 11-24 → issuer 11-19** (Nasdaq pull still shows 11-24; issuer governs) |
| 2026-11-23 | HPE | after close; call 4:00 pm CT / 5:00 pm ET | 70 | **NEW (C)** hpe.com press release "HPE to present live audio webcast of fiscal 2026 fourth quarter earnings conference call", 2026-11-02: call Monday Nov 23 | E → C (W45 date was Nasdaq 11-23, unconfirmed) |
| 2026-11-24 | DELL | after close; call 3:30 pm CST (IR event listing) | 260 | carried (investors.delltechnologies.com "Upcoming Events", W45); Nasdaq time not supplied | — |
| 2026-11-24 | ADI | call 10:00 am ET (IR listing); Nasdaq pre-market | 203 | **NEW (C)** investor.analog.com/events "Q4 2026 Analog Devices, Inc. Earnings Conference Call Nov 24, 2026 at 10:00 AM EST" (page acquired 2026-11-01); one vendor (thefilings.report) says after close — timing conflict, date not in conflict | E → C (date) |
| 2026-11-24 | ADSK | after close; call 2:00 pm PT | 53 | **NEW (C)** adsknews.autodesk.com "Autodesk extends invitation to join financial results conference call", PRNewswire 2026-11-02 (Tuesday Nov 24, 2:00 pm PT); investors.autodesk.com events lists Nov 24 | E → C |
| 2026-11-24 | WDAY | after close | 48 | carried (Workday release, W45; relay site) | — |
| 2026-11-25 | DE | call 9:00 am CT (release timing not stated in extract) | 180 | **NEW (C)** deere.com "Deere to Announce Fourth Quarter 2026 Financial Results" 2026-11-11: call Wednesday Nov. 25, 9 a.m. Central | E → C |
| 2026-12-01 | CRWD | after close; call 2:00 pm PT | 251 | carried (ir.crowdstrike.com 2026-11-04, W45) | — |
| 2026-12-01 | MRVL | call 1:30 pm PT after release | 151 | carried (investor.marvell.com 2026-11-06, W45). One vendor (thefilings.report, 11-10) lists MRVL 11-26 as "expected" — conflicts with issuer notice; issuer governs | — |
| 2026-12-01 | NTAP | after close; call 2:30 pm PT | 37 | **NEW (C)** investors.netapp.com "NetApp Hosts Second Quarter of Fiscal Year 2027 Financial Results Webcast", Business Wire 2026-11-10 | E → C (vendor dates 11-24 / 12-01) |
| 2026-12-01 | OKTA | after close; call 2:00 pm PT | 33 | **NEW (C)** investor.okta.com "Okta to Announce Third Quarter Fiscal Year 2027 Financial Results on December 1, 2026", Business Wire 2026-11-02 | E → C |
| 2026-12-01 | MDB | after close (Nasdaq in W45) | ~25 | carried (C-secondary, finviz relay of MongoDB release, W45). **Not found in this run's Nasdaq ≥$2B/all pull**; one vendor (scrutar) lists 11-30 (estimate). Not re-checked at issuer | C-secondary carried; Nasdaq row missing |
| 2026-12-02 | CRM | after close; call 2:00 pm PT | 186 | **NEW (C)** investor.salesforce.com "Salesforce Announces Date of Third Quarter Fiscal 2027 Earnings Release and Webcast", 2026-11-10 (results Wednesday Dec 2, after close) | E → C |
| 2026-12-02 | SNOW | after close; call 2:00 pm PT | 103 | carried (snowflake.com 2026-11-02, W45) | — |
| 2026-12-02 | ZS | after close; call 1:30 pm PT | 37 | **NEW (C)** ir.zscaler.com "Zscaler to Host First Quarter Fiscal Year 2027 Earnings Conference Call", GlobeNewswire 2026-11-05 (Wednesday Dec 2) | **Δ vs this run's Nasdaq (11-24)**; W45 had 12-02 (E); issuer = 12-02 |
| 2026-12-09 | ADBE | after close; call 2:00 pm PT | 97 | **NEW (C)** adobe.com/investor-relations events page "Q4 & FY2026 earnings call Wednesday, December 9, 2026 2:00pm Pacific Time" (fetched 2026-11-15) | E → C (date unchanged) |
| 2026-12-09 | AVGO | after close; call 2:00 pm PT | 1,585 | **NEW (C)** investors.broadcom.com "Broadcom Inc. to Announce Fourth Quarter and Fiscal Year 2026 Financial Results on Wednesday, December 9, 2026", PRNewswire 2026-11-09 | **Δ date: Nasdaq/W45 12-10 → issuer 12-09** |
| 2026-12-10 | COST | call 2:00 pm PT (IR event page; release after close implied by call time, not stated) | 452 | **NEW (C)** investor.costco.com "Q1 2027 Earnings Call December 10, 2026 02:00 PM PT" (event page, no dated press release seen) | E → C (IR event listing) |

**Conflict — Oracle (A-queue)**

| Date candidates | Ticker | Mcap ($B) | Sources | Tag |
|---|---|---|---|---|
| **2026-12-14 (issuer FAQ) vs 2026-12-09 (Nasdaq 12-09; vendors "expected")** | ORCL | 374 | oracle.com/corporate/investor_relations/faq.html fetched 2026-11-15 (acquired_at 2026-10-26): "Oracle's Second Quarter Fiscal Year 2027 earnings will be announced on December 14, 2026." No dated press release located; investor.oracle.com news page returned no content. Vendors (MarketBeat-derived, earnings.fru.dev, howmanytradingdays) show 12-09 "estimated, company has not announced." | (C) for 12-14 on the issuer FAQ page text only (page not date-stamped; release not seen) — **unresolved vs 12-09 (E)**. Δ vs W45 (12-09 vendor-only; financecalendar listed 12-10) |

**Vendor-only (E) — no issuer notice found this run**

| Date | Ticker | Timing (Nasdaq) | Mcap ($B) | Source / check |
|---|---|---|---|---|
| 2026-12-16 | MU | not supplied | 743 | Nasdaq 12-16. investors.micron.com events page (fetched; acquired 2026-11-06) lists no Q1 FY27 event. Vendors conflict: 12-15 (thefilings.report), 12-16 (earnings.fru.dev), 12-23 (Wall Street Horizon "UNCONFIRMED", theta.md). No issuer notice. **Δ vs W45: none (12-16); 12-23 vendor candidate added** |
| 2026-12-03 | DOCU | not supplied | 15 | Nasdaq + FMP 12-03; not searched |
| 2026-11-24 | MDT | — | 134 (W45) | W45 carried 11-24 (E). **Not present in this run's Nasdaq pull** for any date; thefilings.report (11-10) lists MDT 11-24 "expected". Unresolved |

**Other ≥ $50B names on the Nasdaq forward list in window, date vendor-only (E), not issuer-checked:** BHP 11-17 (210), PDD 11-17 (115), NTES 11-19 (81), ROST 11-19 (75), VEEV 11-19 (50), BNS 12-01 (115; **Δ W45 12-02 → Nasdaq 12-01**), RY 12-03 (290), TD 12-03 (209), BMO 12-03 (123; **Δ W45 12-02 → Nasdaq 12-03**), CM 12-03 (109), AZO 12-08 (52), SNPS 12-09 (89; vendors "12-08 after close" per thefilings.report), ACN 12-17 (177), CTAS 12-17 (90), NKE 12-17 (59; FMP 12-17), CCL 12-18 (40; FMP 12-18). Foreign-private issuers (BHP, PDD, NTES, BNS, RY, TD, BMO, CM, BABA) file 6-K/40-F/20-F; instrument eligibility not assessed here.

**Dates that moved vs W45:** BABA 11-24 → 11-19 (issuer); AVGO 12-10 → 12-09 (issuer); BNS 12-02 → 12-01 and BMO 12-02 → 12-03 (Nasdaq, unconfirmed); ZS Nasdaq 11-24 vs issuer 12-02 (W45 12-02 stands); ORCL issuer FAQ 12-14 vs 12-09. E → C this run: HD, TJX, LOW, HPE, ADI (date), ADSK, DE, NTAP, OKTA, CRM, ZS, ADBE, AVGO, COST. Still unconfirmed: MU, ORCL (conflict), DOCU, MDT, MDB (carried secondary). Market-cap changes since W45 are price-driven (NVDA 4,377 → 4,306; AVGO 1,392 → 1,585; ORCL 348 → 374; DELL 201 → 260; CRWD 222 → 251; MRVL 117 → 151); no filter applied.

### 1B.3 — FDA PDUFA dates in window (2026-11-15 → 2026-12-30)

Rule: sponsor/status resolved against the sponsor's own release/filing or the FDA before naming either; a source that is only an aggregator or trade-press headline is (E)/unresolved and not a dated forward action. Cap/ADV not measured. 'Company text seen' = the sponsor's own page/filing text appeared in a Parallel result this run (search excerpt of the sponsor page); aggregator pages that quote filings are (C-secondary).

**Rolled off since W45 (dated 11-09..11-14) — outcome only if a primary source states it**

| Date | Ticker | Item | Status as of 2026-11-15 |
|---|---|---|---|
| 2026-11-14 (Sat) | SMMT | Summit — ivonescimab + chemo BLA / EGFRm NSCLC post-TKI | **No FDA action or company statement found.** Summit release 2026-11-04 (per Biotech Stock Reports 2026-11-10, secondary) still uses 11-14 and says Summit will issue a release after FDA acts; pdufa.bio (updated 2026-11-12) lists "goal date remains". No source dated 11-13/11-14 found. Outcome UNRESOLVED |
| 2026-11-14 (Sat) | CYTK | Cytokinetics — MYQORZO (aficamten) sNDA adding MAPLE-HCM, standard review | **(C) now resolved as to existence:** Cytokinetics Q3 release 2026-11-04 / earnings call 2026-11-05 (ir.cytokinetics.com; call transcript): "sNDA ... remains under review with a PDUFA date of November 14." Δ vs W45 (which had UNRESOLVED/aggregator-only). No FDA action found as of the latest source (2026-11-12). Outcome UNRESOLVED |
| 2026-11-14 | TEVA / BTAI asset | IGALMI at-home sNDA | Sponsor changed: Teva bought IGALMI/BXCL501 from BioXcel in a court-supervised sale closed 2026-10-26 (BiopharmaWatch 2026-11-10, aggregator). W45 listed BTAI IGALMI as BTAIQ PINK strike. Outcome UNRESOLVED; not C-eligible by W45 rule (not re-assessed) |
| 2026-11-10 | MKKGY | Pimjetmi (pimicotinib) / TGCT | FDA approved 2026-11-10 (pdufa.bio updated 2026-11-12; aggregator citing FDA records; not a W45 row) |
| 2026-11-09 | BAYRY / NVCR | Sunharbo (asundexian) approved 2026-11-09; NVCR Optune "not approvable letter" 2026-11-09 | pdufa.bio (aggregator); not W45 rows; outcome only |
| 2026-11-01 (moved) | AGIO | mitapivat sNDA / sickle cell | W45: moved to 2027-02-01; lifesciencedaily lists "Aqvesme (Pyrukynd) Feb 1 [2027]" — still out of window |
| 2026-12-03 (moved) | EXEL | zanzalintinib + atezolizumab / mCRC | PDUFA moved to 2027-03-03 after major amendment (8-K, per Biotech Stock Reports 2026-11-10; W45 had already 2027-03-03). Catalyst aggregators still print 12-03 — stale |

**In-window PDUFA dates**

| Date | Ticker | Sponsor / drug / indication | Tag | Resolution / source |
|---|---|---|---|---|
| 2026-11-22 (Sun) | CAPR | Capricor — deramiocel BLA / DMD, proposed indication narrowed to upper-limb impairment, age > 9 | (C) | **Re-confirmed:** Capricor Q3 release 2026-11-10 (capricor.com, company text seen) and 10-Q 2026-11-10: "PDUFA target action date of November 22, 2026"; major amendment (OLE data) extended the date from 08-22; 2026-07-29 adcom voted against on the cardiomyopathy framing (per aggregator, W45) |
| 2026-11-22 (Sun) | SVRA | Savara — MOLBREEVI (molgramostim) BLA / autoimmune PAP | (C) | Savara release 2026-04-15 (3-month extension, W45) and Q2 results 2026-08-11 restating 11-22 (via regardsofwallstreet.com, secondary); no later company text seen this run |
| 2026-11-25 (Wed) | SNY (ADR) | Sanofi — venglustat NDA / Gaucher type 3, priority review | (C-secondary) | Sanofi announcement 2026-05-28 (via 2minutemedicine / biopharmatranscript / mdspire quoting Sanofi); ADR, not C-eligible per W45 |
| 2026-11-27 (Fri) | GSK (ADR) | Neladalkib NDA / TKI-pretreated ALK+ NSCLC, priority review. Sponsor: Nuvalent, acquired by GSK 2026-07-15 | (C-secondary) | Nuvalent 2026-05-27 acceptance release (via 2minutemedicine) and Royalty Pharma 8-K 2026-08-05 restating "PDUFA date of November 27, 2026" (via uprighttrades/vigi-eye); GSK-ownership per regardsofwallstreet.com. Δ vs W45: sponsor attribution **resolved to GSK** (W45: unresolved). ADR, not C-eligible |
| 2026-11-27 (Fri) | BBIO | BridgeBio — BBP-418 NDA / LGMD2I/R9, priority review | **(C)** | **Δ E → C:** BridgeBio Q3 release 2026-10-29 (investor.bridgebio.com, company text seen): "BBP-418 for LGMD2I/R9 has a November 27, 2026 PDUFA date, with Priority Review"; FDA accepted NDA 2026-05-27; no advisory committee planned. Same release lists infigratinib 2027-02-04 and encaleret 2027-05-08 (out of window) |
| 2026-11-28 (Sat) | PYPD | PolyPid — D-PLEX100 NDA / surgical-site infection prevention, priority review | (C-secondary) | PolyPid announcement 2026-07-29 (via 2minutemedicine; 6-K per getbreakaway); cap likely < $2B |
| 2026-11-30 (Mon) | VRTX | Vertex — povetacicept BLA (accelerated approval) / IgAN | (C) | Vertex 2026-06-01 release (per W45) and Vertex 2026-11-02 document still using 11-30 (per Biotech Stock Reports 2026-11-10, secondary); partner Zai Lab (ZLAB) also states "PDUFA target action date of November 30, 2026" (per aggregator quoting filing) |
| 2026-11-30 (Mon) | COGT | Cogent — bezuclastinib + sunitinib NDA / GIST second line, priority review | **(C)** | Cogent Q3 release 2026-11-05 (investors.cogentbio.com, company text seen): "Potential FDA approval of bezuclastinib in GIST — PDUFA date of November 30, 2026" |
| 2026-11-30 (Mon) | RHHBY | Roche — giredestrant adjuvant ER+/HER2- early breast cancer NDA | (C-secondary) | Roche 2026-10-01 release (per Biotech Stock Reports 2026-11-10, secondary); ADR |
| Nov (undated) | RHHBY | Roche — Gazyva (obinutuzumab) / primary membranous nephropathy | undated | aggregators (lifesciencedaily, catalystalert show "Nov 30" confirmed — not verified); ADR |
| Nov (undated, month only) | REGN / ALNY | Cemdisiran NDA (priority) / AChR+ gMG | (T) undated | Regeneron "FDA decision ... November 2026" (via biopharmatranscript quoting filing); Alnylam also lists November 2026 target action date. No day disclosed |
| 2026-12-05 | VRTX | Journavx sNDA | (T) carried | not re-verified, no 2026-11 source surfaced this run |
| 2026-12-12 (Sat) | VNDA | Vanda — Quimilza (imsidolimab) BLA / generalized pustular psoriasis (partner AnaptysBio ANAB, royalty) | **(C)** | **Δ E → C:** Vanda release 2026-10-28 (8-K per uprighttrades.com): "Quimilza BLA for GPP under review by the FDA; PDUFA target action date of December 12, 2026"; FDA accepted BLA in Feb 2026 per AnaptysBio filing text (via biopharmatranscript). ANAB role = partner/royalty |
| 2026-12-17 (Thu) | CORT | Corcept — relacorilant NDA resubmission / Cushing's (hypercortisolism) | **(C)** | **Δ E → C:** Corcept release 2026-11-03 (8-K per uprighttrades.com / vigi-eye): "Resubmitted New Drug Application ... PDUFA date of December 17, 2026"; resubmitted 2026-06-17 per Corcept (via Biotech Stock Reports). Company page itself not opened |
| 2026-12-18 | CAMX (Camurus) | CAM2029 (Oclaiz octreotide depot) resubmitted NDA / acromegaly | (E) | aggregators (catalystalert "confirmed", assyro); not US-listed |
| 2026-12-18 | RHHBY | Roche — giredestrant + everolimus NDA / ESR1-mutated advanced breast cancer | (C-secondary) | Roche 2026-10-01 release (per Biotech Stock Reports 2026-11-10, secondary). Assyro also lists Deciphera tirabrutinib NDA 12-18 (W45 carried "Roche/Deciphera 12-18") — Deciphera item (E), sponsor/drug not resolved from a primary source |
| 2026-12-19 (Sat) | HNSA (Hansa) | imlifidase BLA / kidney transplant desensitization | (E) | aggregators; not US-listed |
| 2026-12-22 (Tue) | MLYS | Mineralys — lorundrostat NDA / hypertension (add-on) | **(C)** | **Re-confirmed:** Mineralys Q3 release 2026-11-04 and AHA release 2026-11-08 (ir.mineralystx.com, company text seen): "PDUFA target date of December 22, 2026" |
| 2026-12-23 (Wed) | GILD | Gilead (acquired Arcellx; ACLX) — anito-cel BLA / 4L+ RRMM | (C) | Gilead/Arcellx release 2026-02-23 and 8-K 2026-05-07 (per aggregators quoting), Gilead 10-Q for Q3 still using 12-23 (per Biotech Stock Reports 2026-11-10) |
| 2026-12-27 (Sun) | PRAX | Praxis — relutrigine NDA / SCN2A, SCN8A DEE (extended from 09-27) | (C-secondary) | Praxis filing text "In June 2026, the FDA notified us ... updated PDUFA action date of December 27, 2026" (via biopharmatranscript quoting filing). **New in window (outside W45's 12-23 end)** |
| 2026-12-27 (Sun) | VTRS | Viatris — fast-acting meloxicam (MR-107A-02) NDA / acute pain | (E) | BiopharmaWatch / catalystalert / nextconsensus "confirmed"; Viatris source not seen. **New in window** |
| 2026-12-30 (Wed) | COGT | Cogent — bezuclastinib NDA / non-advanced systemic mastocytosis, standard review | **(C)** | Cogent Q3 release 2026-11-05 (company text seen): "NonAdvSM PDUFA target action date December 30, 2026; AdvSM PDUFA target action date June 29, 2027". **Δ: now inside window.** (Some aggregators mislabel 12-30 as AdvSM; the company's AdvSM date is 2027-06-29) |

Newly announced dates in window for ≥ $2B companies: none beyond the rows above (catalystalert lists HCM/HUTCHMED sovleplenib "Dec 2026, AI-detected", ALVO AVT16 "Dec 2026" and RDY abatacept biosimilar "Dec 2026"; all estimated/AI-detected, no day, not resolved). Coverage: 5 search calls (aggregate calendars plus sponsor-specific); this is a floor, not a census. FDA limb: no dated forward action is named above from an aggregator alone — aggregator-only items are tagged (E) and flagged unresolved. Out of window by date: Exelixis zanzalintinib 2027-03-03, Agios mitapivat 2027-02-01, BridgeBio infigratinib 2027-02-04, Dyne z-rostudirsen 2027-01-21, Lilly orforglipron 2027-01-20, ImmunityBio 2027-01-06, Cogent AdvSM 2027-06-29.

### Macro calendar in C window (2026-11-15 → 2026-12-30)

Context only; 8:30 am ET unless noted. Sources fetched via Parallel 2026-11-15 (BLS pages acquired 11-14/11-15; BEA page acquired 11-15).

| Date | Release | Tag | Source / note |
|---|---|---|---|
| 11-17 | Retail sales (Oct) 8:30 am | (C-secondary) | StockTitan week-ahead 2026-11-13; Census page not fetched |
| 11-18 | FOMC minutes (Oct 27-28), 2:00 pm ET | (C-rule, inferred) | federalreserve.gov rule + StockTitan (see 1B.1) |
| 11-25 | Personal Income and Outlays (Oct 2026) incl. PCE | (C) | bea.gov/news/schedule |
| 11-25 | GDP (Second Estimate) and Corporate Profits, Q3 2026 | (C) | same BEA page |
| 12-04 | Employment Situation (Nov 2026) | (C) | bls.gov/schedule/news_release/empsit.htm |
| 12-08 | U.S. International Trade in Goods and Services (Oct) | (C) | bea.gov schedule |
| 12-08/09 | FOMC + SEP (decision 12-09) | (C) | federalreserve.gov |
| 12-10 | CPI (Nov 2026) | (C) | bls.gov/schedule/news_release/cpi.htm |
| 12-18 | U.S. International Transactions, Q3 | (C) | bea.gov schedule |
| 12-23 | GDP (Third Estimate), Industries, Corporate Profits, State GDP and State Personal Income, Q3 2026 | (C) | bea.gov schedule |
| 12-23 | Personal Income and Outlays (Nov 2026) incl. PCE | (C) | bea.gov schedule |
| 12-30 | FOMC minutes (Dec 8-9) | (C-rule, inferred) | see 1B.1 |

Passed before the window: CPI (Oct) 11-10, Employment Situation (Oct) 11-06. Next after the window: CPI (Dec) 2027-01-13, Employment Situation (Dec) 2027-01-08. Δ vs W45: window extension to 12-30 adds the 12-30 FOMC minutes; no BLS/BEA date shifted since W45 (all 11-25, 12-04, 12-10, 12-23 dates unchanged; BEA schedule also lists non-market items 11-17, 11-18, 11-20, 12-02, 12-10 [state-level releases], not relevant). W45's carried non-verified items (government funding CR expiry 12-11 (C-secondary)) were not re-verified this run.

## PART 2A — Strategy A ranked shortlist

### The A-queue census — the PINNED query, run verbatim

`SELECT * FROM state.open_queue WHERE strategy = 'A'` → **47 rows** (MEASURED by the orchestrator 2026-11-15; W45 had 46, the one addition is CEG, enqueued by W4 after the W45 file named it NEW): AAPL, ADBE, AKAM, AMAT, AMD, AMZN, ANET, AVGO, CAT, CEG, COP, CRM, CRWD, CSCO, CVX, DDOG, DELL, FSLR, GEV, GOOGL, HD, HPE, IBM, INTC, INTU, JPM, LLY, META, MRK, MRVL, MSFT, MU, NBIS, NOW, NTAP, NVDA, OKTA, ORCL, PANW, QCOM, SMCI, SNOW, TGT, TTWO, VRTX, WMT, XOM. My hand count of that list is 47, matching the query, so there is no discrepancy to reconcile; the query wins in any case. Every "QUEUED" / "NEW" mark below is tested against this list. Reconciliation of the 47: 40 of the 50 ranked admissible names are QUEUED and 10 are NEW (ETN, LRCX, PLTR, UBER, SHOP, DIS, MRNA, GE, SNDK, RDDT); 4 of the 8 inadmissible names are QUEUED (WMT, ADBE, HD, AKAM); 3 census members are not ranked this week (IBM, MRK, and NOW, dropped this cycle, see Handoff). 40 + 4 + 3 = 47. **Open A positions: none** (Strategy A NAV 0; the only open positions are Strategy D lots).

### STEP 1 — the GATE DATE, re-derived from scratch, with the arithmetic shown

**DERIVED GATE DATE = 2026-11-15** (orchestrator-measured this run; Rev 52 STEP 1, earliest of (a), (b), (c); the retired pre-Rev 52 derivation was not run).

**Router state read first.** A's `STRATEGY_ACTIVATION` reads **DO-NOT-ACTIVATE** (`state.current_regime`), so CATALYST-GATE MODE is live, not inert. A is LONG-ONLY (`strategy/03_strategy_a.md`: "Long-only (no short positions in A — short is B's territory)").

- **(a) Next scheduled M1a/M1b re-score.** Completed `M1a` = **1**, `M1b` = **1** this month. `m1b >= 1`, so (a) = next month's first trading day = **2026-12-01**.
- **(b) Open `PENDING_REGIME_REFRESH` `regime-refresh` items:** **none** → does not apply.
- **(c) REFRESH REQUEST (D2a Step 0, verbatim query)** returned **4** uncovered triggers: `geopolitical_qualifying_event` (trigger_run_start 2026-11-08), `vix_drift_gt5_ending_normal` (2026-11-09), `breadth_mom_rise_gt10` (2026-11-09), `vix_regime_exit_high` (2026-11-09), all logged about 2026-11-10 00:xx UTC, after the last regime-refresh complete (M1R 2026-11-09 13:10 UTC). (b) found no open item, so (c) = D2a's next run = **2026-11-15** (D2a fires Sunday–Thursday 16:40 MT; today is Sunday).
- **GATE DATE = earliest(2026-12-01, n/a, 2026-11-15) = 2026-11-15.** A candidate is SPENT-BY-GATE only if its dated catalyst falls strictly before 2026-11-15 with nothing dated on/after it. No input was unavailable, so FAIL-OPEN did not trigger. Δ vs W45 (gate 2026-11-08): the gate moved forward one week because the 11-08 refresh was consumed and four new triggers were logged on 11-09/11-10.

### STEP 2 — the DIRECTION ADMISSIBILITY rail (run before ranking and before gate classification)

Evidence read: D1 records already in the repo (to 2026-11-09), orchestrator state, IBKR regular-session daily bars through 2026-11-13 (price only), and the minimum per-name issuer checks listed below. D1 did not run 11-10..11-13 (fleet blackout 11-10..11-12; Friday 11-13 is the structural gap), so the narrative below is limited to what the issuer documents and the cited wires establish; nothing here is a broad news scan.

- **Eight names stay DIRECTION-INADMISSIBLE** (WMT, ADBE, HD, AKAM, DAL, CCL, UAL, AAL). None is reversed to bullish and none enters the top-10.
- **AMAT: bearish mark REVERSED, by MEASURED evidence.** W45 carried AMAT as a bearish "China WFE cliff" candidate. Applied's own FQ4 release (2026-11-12) shows record revenue $10.41B (+53% y/y), record non-GAAP EPS $4.16 (vs Nasdaq consensus $4.06) and an FQ1 guide of $11.1B ±$0.5B / EPS $4.35 ±$0.20 (https://ir.appliedmaterials.com/news-releases/news-release-details/applied-materials-announces-fourth-quarter-and-fiscal-year-2026). An over-valued thesis resting on a demand cliff is contradicted. AMAT moves to the admissible list as **DIRECTION UNRESOLVED** (no established bullish gap: the stock is +11.4% on the week), ineligible for the top-10, same status as TGT.
- **TGT stays DIRECTION UNRESOLVED** (prior bearish thesis refuted by a beat-and-raise, no replacement). Ineligible for the top-10.
- **Fuel-shock cluster (DAL, CCL, UAL, AAL): unchanged, direction-unresolved.** No airline price read this week; Reuters (via RTE/Tacoma wires, 11-12) cites "higher oil prices" on 11-12 (no Brent read taken), so the W45 observation that the fuel-cost thesis was eroding is not extended. D2 should re-test before any B or A use.
- **ADBE, WMT, HD, AKAM: kept, no new evidence read.** HD (11-17) and WMT (11-19) print in the coming week.
- **No new bearish names added.**

### STEP 3 — classification and counts

Gate date **2026-11-15**. SPENT-BY-GATE iff the dated catalyst is strictly before 2026-11-15 and there is nothing dated on/after it.

**58 carried: 50 ranked admissible (two, TGT and AMAT, direction-unresolved) + 8 DIRECTION-INADMISSIBLE. 0 SPENT-BY-GATE, 58 GATE-SURVIVING.** Every name that printed 2026-11-09..11-13 (CEG, TTWO, CSCO, NBIS, AMAT) was re-dated to its next dated catalyst or left `undated` (fail-open). No candidate has a dated catalyst before 2026-11-15 without a later one, so every row gets full (a)-(e) with (b) depth set by tier (top-10 and 11-20 re-checked or newly cited this week; lower tiers terse where evidence is unchanged).

- **Printed 11-09..11-13 (MEASURED from issuer releases fetched this run):** CEG 11-09 (next print undated, early/late-February pattern INFERRED); TTWO 11-09 (still carries a dated GTA VI launch 2026-11-19 (C)); CSCO 11-12 (next 2027-02-10 (E, FMP)); AMAT 11-12 (next undated); NBIS 11-12 (next undated). Not in the carried set but printed in-window: CRWV 11-10 (not researched; see Handoff).
- **Date moves vs W45 (Δ):** AVGO 2026-12-10 (E) → **2026-12-09 (C)** after close (Broadcom IR notice 2026-11-09); PANW 11-18 (E) → **11-18 (C)** after close (Palo Alto IR notice 2026-11-03); DELL 11-24 confirmed **(C)** (Dell IR notice 2026-11-10, call 3:30 pm CST); NVDA 11-17 reconfirmed **(C)** after the CEO exit (NVIDIA release 2026-11-12: "as previously scheduled"); VRTX PDUFA 2026-11-30 reconfirmed (C); MRVL 12-01 (C) carried; MU 12-16 stays (E), Micron had not announced it in the sources searched.
- **Fragile (within one week of the gate):** NVDA 11-17, DIS 11-17, HD 11-17 (inadmissible), PANW 11-18, TGT 11-18, WMT 11-19 (inadmissible), INTU 11-19, TTWO GTA VI 11-19. All are post-gate.
- **Undated survivors (fail-open): 13** (CEG, ETN, NBIS, QCOM, LRCX, DDOG, LLY, CAT, GEV, AMAT, SNDK, RDDT, plus inadmissible AKAM). Next dates are late-January/February by pattern, INFERRED and unsourced; FMP's sparse chunk 2 (2027-01-14..03-15) returned no row for them and no web fallback was run for them this week (budget spent on the narrower print checks).
- **Dropped from the ranked set (stays on the census where queued):** NOW (W45 flagged "drop at next refresh if no one-time cause emerges"; none read; frees a slot for AMAT).
- **New intake:** none beyond the AMAT reclassification (the 50 admissible cap is full).

### Week narrative (MEASURED facts with sources; inferences labelled)

- **MEASURED. NVIDIA CEO Jensen Huang resigned effective immediately (announced 2026-11-12); CFO Colette Kress is interim CEO; Harvey C. Jones is the first board chair; the 3Q FY27 call stays on 2026-11-17** (https://nvidianews.nvidia.com/news/nvidia-announces-ceo-transition). NVDA closed 168.89 (11-10), 173.73 (11-11), 166.19 (11-12, intraday low 148.80 on 441.7M shares), 162.85 (11-13); -12.7% on the week. Wires (Reuters, NYT, WSJ, 11-12) say the stock fell as much as 14% intraday on 11-12 and closed down 4.3%; Reuters (RTE copy) puts NVDA at about 12x forward earnings, the lowest since November 2012 per LSEG.
- **MEASURED (Reuters, 11-13 morning, intraday).** AI-linked stocks fell again on 11-13 on jitters over AI financing (Nvidia vendor financing): neoclouds CoreWeave and Nebius -10.8% and -12.1% at the time, SOX -6% intraday. IBKR closes: AMD 585.30 (11-12) → 534.06 (11-13, -8.8%); AVGO 364.36 → 347.01 (-4.8%); CSCO 102.01 → 95.64 (-6.2%); MU 798.44 → 778.31 (-2.5%). SPY nonetheless +2.6% on the week (735.29 → 754.37) after the 11-09 relief rally (D1 8327041f).
- **MEASURED (D1 8327041f, 11-09):** broad relief rally, SPY +2.37%, QQQ +3.54%, SMH +5.05%, VIX 25.64 → 19.92 on unconfirmed Qatar/Hormuz interim-deal reports.
- **MEASURED. Policy overhang for the AI-power/solar complex:** Reuters (11-04) and CRU Group (11-12): of 39 data-centre referendums on 3 November, 38 voted for some form of moratorium or restriction; exit polling shows 56% of voters called data centres a major or crucial factor. PV Tech (11-13) counts 40 of 41 ballot measures restricting data centres approved. INFERRED: this is the "policy shock" W45 said to re-check; it persists, and its transmission to FSLR, CEG and the AI hardware names is indirect.
- **MEASURED issuer prints this week:** CEG, TTWO, CSCO, AMAT, NBIS (details in the rows below). Four of five were beats or reiterations; NBIS cut its 2026 revenue to the low end of range on capacity delays.
- **Not covered (gap):** nothing was read on 11-10..11-13 for names outside those listed, and no Brent/oil read was taken, so no claim is made about the energy complex beyond IBKR prices.

### Price context (IBKR regular-session daily bars, MEASURED via `get_price_history`; 11-06 and 11-13 closes)

| Ticker | 11-06 | 11-13 | Wk chg | Note |
|---|---|---|---|---|
| SPY | 735.29 | 754.37 | +2.6% | 11-09 752.69 (relief rally) |
| VRTX | 547.09 | 538.60 | -1.6% | range-bound 538-551 all week |
| FSLR | 201.14 | 171.39 | -14.8% | five straight lower closes; 11-13 low 166.70; midterm gain fully unwound |
| NVDA | 186.64 | 162.85 | -12.7% | 11-12 close 166.19 (low 148.80, 441.7M shares); 11-13 249.9M shares |
| TTWO | 214.87 | 227.82 | +6.0% | 11-09 207.40 then 224.64 (11-10), 231.31 (11-11) |
| MU | 690.00 | 778.31 | +12.8% | 11-11 811.30 high close |
| DELL | 328.53 | 344.53 | +4.9% | 11-11 373.68 |
| MRVL | 141.20 | 156.76 | +11.0% | 11-11 168.80 |
| AVGO | 293.69 | 347.01 | +18.2% | 11-12 364.36 |
| ORCL | 116.10 | 125.35 | +8.0% | 11-11 128.38 |
| CSCO | 93.85 | 95.64 | +1.9% | 11-12 close 102.01 (pre-print), 11-13 -6.2% after a beat-and-raise |
| CEG | 249.95 | 280.20 | +12.1% | 11-09 +10.5% to 276.09 on the print |
| AMD | 449.04 | 534.06 | +18.9% | 11-12 585.30 high close |
| ANET | 170.80 | 197.29 | +15.5% | 11-12 206.63 |
| NBIS | 129.49 | 115.88 | -10.5% | 11-11 154.69, 11-12 128.64 (-16.8% on the print), 11-13 115.88 |
| ETN | 341.72 | 352.97 | +3.3% | |
| SMCI | 28.76 | 26.86 | -6.6% | 11-12 26.99 on 92M shares |
| LRCX | 200.44 | 225.92 | +12.7% | |
| QCOM | 165.41 | 172.47 | +4.3% | |
| COP | 136.27 | 142.28 | +4.4% | |
| AAPL | 342.37 | 356.27 | +4.1% | |
| GOOGL | 284.78 | 295.77 | +3.9% | |
| AMAT | 332.72 | 370.50 | +11.4% | printed 11-12 after the close; 11-12 380.95 → 11-13 370.50 (-2.7%) |
| MSFT | 530.61 | 523.88 | -1.3% | |
| AMZN | 259.30 | 266.66 | +2.8% | |

### TOP-10 — the actionable tier

**Selection rule (stated for W4).** Only ADMISSIBLE, GATE-SURVIVING names with a DATED post-gate catalyst that is not merely a consumed print; direction-unresolved names (TGT, AMAT) and undated names are excluded from the tier. All ten rows are long. Zero SPENT names. All ten are QUEUED; none is NEW.

**1. VRTX - Vertex Pharmaceuticals.** (a) Bullish. (b) Povetacicept (IgAN) BLA under priority review, PDUFA **2026-11-30**, "on track" per Vertex (https://news.vrtx.com/news-releases/news-release-details/phase-3-rainier-results-supporting-best-class-potential, 2026-10-23; restated in the Q3 release https://news.vrtx.com/news-releases/news-release-details/vertex-reports-third-quarter-2026-financial-results, 2026-11-02). RAINIER Week-36 interim: UPCR -52.0% from baseline, -49.8% vs placebo (p<0.0001), AEs 75% vs 78%, SAEs 3% vs 4% (NEJM, https://www.nejm.org/doi/full/10.1056/NEJMoa2608682). Two APRIL-pathway IgAN drugs already hold accelerated approval on interim proteinuria (Otsuka Voyxact 2025-11-25; Vera Trutakna 2026-07-07; secondary, lifesciencedaily 2026-11-09), which supports the surrogate-endpoint path. Counter-evidence: the eGFR-slope endpoint is not reported until 2028; a secondary source (2026-11-09) found no FDA action yet; price 538.60 is -1.6% on the week after the run from 517 on 10-26, so approval is partly priced. (c) PDUFA **2026-11-30 (C)**, unchanged from W45. (d) QUEUED; no open position. (e) Top-10, conviction **4**. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2026-11-30)

**2. FSLR - First Solar.** (a) Bullish. (b) Section 232 polysilicon regime, signed 2026-08-06, effective **2026-12-04 12:01 am ET**: 15% additional duty plus minimum import prices (modules $0.38/W, cells $0.22/W, wafers/ingots $100/kg, polysilicon $21/kg) (Federal Register https://www.federalregister.gov/documents/2026/08/11/2026-16400/adjusting-imports-of-polysilicon-and-its-derivatives-into-the-united-states; GHY trade note updated 2026-11-12: CBP activated four simulated Chapter 99 test codes in ACE on 11-12 ahead of 12-04, https://www.ghy.com/trade-compliance/us-section-232-polysilicon-tariff/). The regime falls on imported crystalline silicon; FSLR's CdTe thin-film modules are not covered, so it lifts competitors' cost floor (Convexity 2026-11-11, secondary; consistent with FSLR's own 10-Q per that source). Δ vs W45: the price gap RE-OPENED. FSLR closed 201.14 on 11-06 and 171.39 on 11-13 (-14.8%, five lower closes). INFERRED: the post-midterm clean-energy pop (+8.4% on 11-04 per Reuters) unwound as the data-centre-moratorium result (40 of 41 ballot measures per PV Tech 11-13) clouded solar demand growth; no FSLR-specific issuer event this week. Counter-evidence: customer procurement hesitation on "an incomplete regulatory picture" and a state moratorium that stopped a 2 GW project (FSLR Q3 call, 2026-10-29, via Convexity); the BAAJA permitting bill's fate is uncertain (CRU 2026-11-12). Documents for construction: proclamation text, 10-Q (backlog 44.0 GW / $13.5B per Convexity), CBP guidance 2026-09-23. (c) **Sec 232 effective 2026-12-04 (C)**. (d) QUEUED; no open position. (e) Top-10, conviction **4** (held; gap wider than W45). GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2026-12-04)

**3. NVDA - NVIDIA.** (a) Bullish. (b) Issuer release 2026-11-12 (https://nvidianews.nvidia.com/news/nvidia-announces-ceo-transition): Huang resigned as president, CEO and director; Kress interim CEO while remaining CFO; the board "expect[s] the company's operations, customer commitments and product roadmap to continue without interruption" (company statement, not independent evidence); 3Q FY27 results **Tuesday 2026-11-17 about 1:20 pm PT**, call 2 pm PT, "as previously scheduled" (investor.nvidia.com event page, https://investor.nvidia.com/events-and-presentations/events-and-presentations/event-details/2026/NVIDIA-3rd-Quarter-FY27-Financial-Results/default.aspx). Press (Sulat 2026-11-13, secondary): Kress has called a company meeting for 11-18; House committee chairs proposed a closed-door Huang briefing for 11-18 (negotiating a date per CNBC via Sulat). Price: 162.85 on 11-13, -12.7% on the week and about 29% below the early-October level per stockanalysis 2026-11-13 (secondary); 12x forward earnings, lowest since 2012 per LSEG (Reuters via RTE). Gap hypothesis (INFERRED): the market is pricing a leadership/governance discount and an AI-financing unwind (vendor-financing fear for neoclouds) onto a business whose guide and demand signals are unchanged; a supply-constrained print and a stable interim-CEO message would narrow it. Counter-evidence (MEASURED/secondary): no permanent CEO, an independent board investigation opened 11-08, export-control questions from Senator Warren (Sulat 11-13), and CFO dual-hatting; the AI-financing channel (neoclouds -10% to -22% on 11-12/11-13) is a real second-order risk. This is the highest-variance catalyst in the tier. Documents for construction: FQ3 10-Q and CFO commentary (posted at the print), 8-K of 2026-11-12, last four transcripts, hyperscaler capex disclosures. (c) Earnings **2026-11-17 (C)** after the close. (d) QUEUED; no open position. (e) Top-10, conviction **3** (held, with explicit event-risk flag). GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2026-11-17)

**4. TTWO - Take-Two Interactive.** (a) Bullish. (b) Issuer FQ2 release 2026-11-09 (http://www.take2games.com/ir/news/take-two-interactive-software-inc-reports-results-fiscal-4; slide deck https://ir.take2games.com/static-files/01437b0a-6d3d-4f80-a2ac-5cecdb0c573f): net bookings **$1.60B (-18% y/y), slightly below the $1.62-1.67B guide** (NBA 2K27 below forecast; GTA series above forecast), FY27 net bookings **$8.0-8.2B reiterated**, FQ3 net bookings guide **$3.35-3.5B** (RCS about +12%), "pre-orders for Grand Theft Auto VI are tracking far in excess of our initial expectations"; **GTA VI launch 2026-11-19** on PS5 and Xbox Series X|S per the release's release table. The Q2 print is consumed (11-09); the live dated catalyst is the launch and its first sell-through disclosure. Price: 207.40 (11-09 close, -3.5%), then 224.64 and 231.31, 227.82 on 11-13 (+6.0% on the week), so the pre-launch gap has narrowed further since W45. Counter-evidence: a slip or a weaker-than-"unprecedented" first-week print is thesis-invalidating; guidance already embeds the launch; recurrent consumer spending declined 9%. Δ vs W45: the 11-09 print is now confirmed (C); catalyst re-pointed from the print to the launch. Documents for construction: the 8-K Ex-99.1 (https://www.sec.gov/Archives/edgar/data/946581/000162828026072175/ttwo2q27earningsrelease.htm), prepared remarks, 10-Q. (c) GTA VI launch **2026-11-19 (C)**; next earnings undated (early February by pattern, INFERRED). (d) QUEUED; no open position. (e) Top-10, conviction **3**. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2026-11-19)

**5. MU - Micron.** (a) Bullish. (b) FQ4 release 2026-09-30 (https://investors.micron.com/quarterly-results): FQ1 guide revenue $61.5B ±$1.5B, non-GAAP gross margin about 86.25%, non-GAAP EPS $38.15 ±$1.00. The W45 thesis (largest percentage gap among large caps after the 11-05 rout) has partly closed: 690.00 → 778.31 (+12.8%), still below the 884.74 level of 10-30. Counter-evidence: strategic long-term agreements cap spot capture; AI-financing fear (11-13 -2.5%); memory is capex-geared. (c) FQ1 **2026-12-16 (E)** after the close (vendor estimate; Micron has not announced it in the sources searched, earnings.fru.dev checked 2026-11-12). (d) QUEUED (the queue row cites the consumed 09-30 print; stale). No open position. (e) Top-10, conviction **3**. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2026-12-16)

**6. DELL - Dell Technologies.** (a) Bullish. (b) Issuer notice 2026-11-10: FQ3 FY27 call **Tuesday 2026-11-24, 3:30 pm CST**, results issued before the call (https://investors.delltechnologies.com/news-events/press-releases/detail/1661/dell-technologies-to-hold-conference-call-nov-24-to-discuss-third-quarter-fiscal-2027-financial-results). Baseline (Dell FQ2 release 2026-09-01 via factsdesk, secondary): revenue $47.0B (+58%), FY27 revenue guide $192.0B; AI-server backlog $95B (W45, secondary). SMCI's 11-03 raise (FY27 revenue $72-82B) supports server demand. Price 344.53 (+4.9%); 11-13 close -7.2% from 371.17 in the AI selloff (Reuters: Dell and HPE -6% to -11% intraday). Counter-evidence: memory cost pressure on server margins (SMCI GAAP gross margin 12.7%); policy and AI-financing risk. (c) FQ3 **2026-11-24 (C)**. (d) QUEUED; no open position. (e) Top-10, conviction **2**. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2026-11-24)

**7. MRVL - Marvell Technology.** (a) Bullish (merger-reaction overshoot). (b) 8-K Item 1.01 2026-11-02: all-stock acquisition of Lumentum at 4.500 MRVL per LITE share (D1 da7bf33a; https://www.sec.gov/Archives/edgar/data/1835632/000119312526442717/d352474d8k.htm). Marvell's own notice 2026-11-06: FQ3 FY27 call **Tuesday 2026-12-01, 1:30 pm PT** (https://investor.marvell.com/news-events/press-releases/detail/1041/marvell-technology-inc-announces-conference-call-to-review-third-quarter-of-fiscal-year-2027-financial-results). Price 156.76 (+11.0%) from 141.20; 11-13 -4.9% from 164.45. Gap hypothesis (INFERRED): dilution and customer-conflict risk are priced; the AI-hardware rebound has recovered part of the overshoot. Counter-evidence: the merger's H1 2028 close, Bank of America dilution view (W45, secondary), and the AI-financing risk that hit Huang-linked names. (c) FQ3 **2026-12-01 (C)**. (d) QUEUED; no open position. (e) Top-10, conviction **2**. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2026-12-01)

**8. AVGO - Broadcom.** (a) Bullish. (b) Issuer notice 2026-11-09: FQ4 and FY2026 results **Wednesday 2026-12-09 after the close**, call 2 pm PT (https://investors.broadcom.com/news-releases/news-release-details/broadcom-inc-announce-fourth-quarter-and-fiscal-year-2026). Δ vs W45: date moved from 12-10 (E, third-party) to **12-09 (C)**. Q3 release (2026-09-02, W45): Q4 revenue guide about $34.8B, non-GAAP operating margin about 66%. Price 347.01 (+18.2% on the week; 52-week high 495.00 and low 289.77 per investors.broadcom.com page dated 11-13); the W45 policy-rout gap has largely closed. Reuters 11-12 and stockanalysis 11-13 describe AVGO as a rotation beneficiary of Nvidia's turmoil (INFERRED, may reverse). Counter-evidence: the Oct 26 $63B Bank of America/Blackstone/Citi/Morgan Stanley financing structure with Broadcom (issuer news list) is AI-financing exposure; the rally leaves less gap. (c) FQ4 **2026-12-09 (C)**. (d) QUEUED; no open position. (e) Top-10, conviction **2** (down from 3: gap narrowed). GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2026-12-09)

**9. ORCL - Oracle.** (Orchestrator reconciliation: catalyst date CONFLICT unresolved — Nasdaq and vendors 2026-12-09, Oracle IR FAQ page 2026-12-14 (undated page, no dated release found; PART 1A/1B). Carried as 2026-12-09 (E); either date is after the 2026-11-15 gate, so the GATE literal is unaffected.) (a) Bullish. (b) $10B common-stock issuance, 86,206,897 shares (8-K Item 8.01, 11-04; D1 f5359185; https://www.sec.gov/Archives/edgar/data/1341439/000119312526447507/d131790d8k.htm); funding structure (record CDS, OpenAI financing, carried) is the live question; equity rather than debt may reduce credit risk, dilution is the counter. Price 125.35 (+8.0%). Not re-checked beyond price this week. (c) FQ2 **2026-12-09 (E)** (Nasdaq; EPS $1.56). (d) QUEUED; no open position. (e) Top-10, conviction **2** (up from 20th to 9th on a dated catalyst; Oracle has not announced the date in the sources read). GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2026-12-09)

**10. PANW - Palo Alto Networks.** (a) Bullish (platformisation). (b) Issuer notice 2026-11-03: FQ1 FY27 results **Wednesday 2026-11-18 after the close**, webcast 1:30 pm PT (https://investors.paloaltonetworks.com/news-releases/news-release-details/palo-alto-networks-announce-fiscal-first-quarter-2027-financial). Δ vs W45: date upgraded (E) → (C). Nasdaq EPS $0.52 (15 estimates). No price read this week (no contract lookup); the software group stayed weak in W45 (DDOG -14.4%, NOW -26.95%), which is the counter-evidence. Terse by design: this is the weakest-documented top-10 row, filling the slot vacated by CSCO and CEG (both printed). (c) FQ1 **2026-11-18 (C)**. (d) QUEUED; no open position. (e) Top-10, conviction **2**. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2026-11-18)

### 11-20

Research-cost note: rows keep (b) terse where unchanged; every row carries (a)-(e).

**11. CSCO - Cisco.** (a) Bullish. (b) Issuer release 2026-11-12 (https://investor.cisco.com/news/news-details/2026/CISCO-REPORTS-FIRST-QUARTER-EARNINGS/default.aspx): record revenue $18.5B (+24%), non-GAAP EPS $1.40 (+40%) vs LSEG $1.33 expected (CNBC), networking +43%, FY27 guide raised to revenue $74.8-75.8B and non-GAAP EPS $5.47-5.53, hyperscaler AI orders expectation raised to $9B in FY27, Q2 guide $18.0-18.2B / EPS $1.34-1.36. Δ vs W45: print consumed (a beat and raise), so CSCO leaves the top-10. Price: closed 102.01 on 11-12 before the release and 95.64 on 11-13 (-6.2%) despite the beat, on the AI-sector selloff (cause INFERRED from the same-day SOX move; no Cisco-specific negative read). Gap hypothesis (INFERRED): a record print with a raised guide was sold with the tape. Counter-evidence: gross margin fell (non-GAAP 65.6% vs 68.1%), RPO -1% q/q. (c) Next print **2027-02-10 (E)** (FMP). (d) QUEUED; no open position. (e) 11-20, conviction **3**. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2027-02-10)

**12. CEG - Constellation Energy.** (a) Bullish. (b) Issuer release 2026-11-09 (https://investors.constellationenergy.com/news-releases/news-release-details/constellation-reports-third-quarter-2026-results): adjusted operating EPS $5.06 vs $3.04 a year ago (vs about $3.89 consensus per zintick, secondary), full-year guide raised and narrowed to **$12.50-12.80** (midpoint $12.65), agreement to buy the Rhode Island State Energy Center for $715M, conditional DOE loan commitment up to $5B for nuclear uprates, about 4,560 MW contracted with three customers in Q3. Price 280.20 (+12.1%; +10.5% on the print day), so the W45 gap has largely closed. Counter-evidence: data-centre moratoria and the AI-financing unwind (utilities and equipment suppliers down 2% to 3.3% on 11-13 per Reuters). (c) Next print **undated** (late-February pattern INFERRED; no FMP/Nasdaq row). (d) QUEUED (enqueued since W45); no open position. (e) 11-20, conviction **2**; falls out of the top-10 (print consumed). GATE: GATE-SURVIVING (gate 2026-11-15; catalyst undated)

**13. AMD - AMD.** (a) Bullish. (b) Q3 beat and Q4 guide about $17B ±3% (W45, secondary summaries). Price 534.06 (+18.9% on the week; 585.30 on 11-12) as Nvidia's turmoil drove rotation (stockanalysis, Reuters); 11-13 -8.8%. Gap narrowed sharply. Counter-evidence: lost the SpaceX compute socket to NVDA (carried); rotation can reverse once NVDA reports. (c) Next print **2027-02-02 (E)** (FMP). (d) QUEUED. (e) 11-20, conviction **2** (down from 3). GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2027-02-02)

**14. ANET - Arista Networks.** (a) Bullish. (b) Q3 release (W45, https://www.sec.gov/Archives/edgar/data/0001596532/000159653226000252/ex991q326-earningsrelease.htm): revenue $3.66B (+58.5%), Q4 guide $3.9-4.0B. Price 197.29 (+15.5%). Counter: concentration, component supply; gap narrowed. (c) Next print **2027-02-10 (E)** (W45 fallback projection; FMP has no row). (d) QUEUED. (e) 11-20, conviction **3**. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2027-02-10)

**15. NBIS - Nebius.** (a) Bullish. (b) Issuer release and shareholder letter 2026-11-12 (https://nebius.com/newsroom/nebius-reports-third-quarter-2026-financial-results): revenue **$980.8M (+571% y/y)**, of which about **$325M non-recurring** from the asset-light model; adjusted EBITDA $465.8M; 2026 revenue now at the **low end** of $3.0-3.4B (Reuters cites $3.0-3.2B; the letter says "low end"), capex about $27B (above $20-25B), ARR above $7B now expected in February rather than December; first 2027 outlook revenue $12-13B, capex $40-45B, pre-tax breakeven by Q4 2027; prepayments on Q3 deals covered over 100% of capex; $12B TCV signed since the start of Q3; third-party capacity delays (New Jersey/Microsoft tranche in Q2 2027). Price: 154.69 (11-11) → 128.64 (11-12, -16.8%) → 115.88 (11-13); -10.5% on the week. Gap hypothesis (INFERRED): the market is pricing capacity-delay and AI-financing risk; contracted demand (RPO $38.7B per the letter) is intact. Counter-evidence: guidance cut on timing, funding dependence on Nvidia-linked sentiment, $14.0B non-current debt. Δ vs W45: print consumed (11-12 was the consumed date). (c) Next print **undated** (February pattern INFERRED). (d) QUEUED. (e) 11-20, conviction **2**. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst undated)

**16. ETN - Eaton. NEW.** (a) Bullish. (b) Q3 8-K Ex-99 (W45, https://www.sec.gov/Archives/edgar/data/0001551182/000155118226000037/etn09302026exhibit99.htm): sales $8.9B (+28%), data-centre revenue about +65%, 2026 EPS guide raised to $13.70-13.80. Price 352.97 (+3.3%). Counter: data-centre pause risk is concentrated in Eaton's end market. (c) Next print **undated**. (d) **NEW**. (e) 11-20, conviction **3**. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst undated)

**17. SMCI - Super Micro.** (a) Bullish. (b) FQ1 FY27 (8-K Ex-99.1 11-03, W45): net sales about $19.9B, FY27 revenue guide $72-82B, GAAP gross margin 12.7%, operating cash outflow $434M, figures preliminary. Price 26.86 (-6.6%), the only AI-hardware name lower on the week (11-12 26.99 on 92M shares). Counter: thin margins, cash burn. (c) Next print **2027-02-02 (E)** (W45 projection). (d) QUEUED. (e) 11-20, conviction **2**. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2027-02-02)

**18. LRCX - Lam Research. NEW.** (a) Bullish. (b) 10-21 print: December-quarter guide revenue $8.6B ±$0.4B (W45, secondary). AMAT's 11-12 release (record quarter, CY26 Semi Systems >40% growth, "demand for advanced chips much higher than supply") is a direct read-through that supports WFE demand (MEASURED, issuer deck https://ir.appliedmaterials.com/static-files/bbcd46e8-4188-4b4b-918b-f572dcfb232d). Price 225.92 (+12.7%). Counter: AI-capex policy risk. (c) Next print **undated** (late January INFERRED). (d) **NEW**. (e) 11-20, conviction **2**. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst undated)

**19. QCOM - Qualcomm.** (a) Bullish, reduced. (b) FQ4 (11-04; W45, secondary): handset -26.2%, FQ1 guide $10.4-11.2B. Price 172.47 (+4.3%). Gap largely closed or reversed. (c) Next print **undated**. (d) QUEUED. (e) 11-20, conviction **2**. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst undated)

**20. COP - ConocoPhillips.** (a) Bullish, thesis weakened. (b) Q3 8-K 11-05 (W45, https://www.sec.gov/Archives/edgar/data/0001163165/000116316526000043/cop-20261105x8kexx991.htm): adjusted EPS $3.27 vs $3.06. Price 142.28 (+4.4%); Reuters 11-12 cites "higher oil prices" that session, no Brent read taken here. (c) Next print **2027-02-10 (E)** (W45 projection). (d) QUEUED. (e) 11-20, conviction **2**. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2027-02-10)

### 21-30

- **21. HPE - Hewlett Packard Enterprise.** (a) Bullish; as DELL (Reuters 11-13: Dell and HPE -6% to -11% intraday). (b) Nasdaq EPS $1.17 (7 est.). (c) **2026-11-23 (E)** after hours (Nasdaq; issuer notice not read). (d) QUEUED. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2026-11-23)
- **22. INTU - Intuit.** (a) Bullish. (b) Nasdaq EPS $2.47. (c) **2026-11-19 (E)** after hours (Nasdaq). (d) QUEUED. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2026-11-19)
- **23. DIS - Disney. NEW.** (a) Bullish; SVOD margin. Nasdaq EPS $1.67 (9 est.), FMP $1.68. (c) **2026-11-17 (E)** pre-market (Nasdaq and FMP agree). (d) **NEW**; two open Strategy D lots. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2026-11-17)
- **24. CRWD - CrowdStrike.** (a) Bullish; module attach. Software contagion is the counter. (c) **2026-12-01 (E)** (Nasdaq; time not supplied). (d) QUEUED. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2026-12-01)
- **25. NTAP - NetApp.** (a) Bullish. (c) **2026-12-01 (E)** after hours (Nasdaq; EPS $2.13). (d) QUEUED. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2026-12-01)
- **26. OKTA - Okta.** (a) Bullish. (c) **2026-12-01 (E)** after hours (Nasdaq; EPS $0.43). (d) QUEUED. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2026-12-01)
- **27. CRM - Salesforce.** (a) Bullish; agentic-AI attach vs compressed multiple; software prints (DDOG, NOW) are the counter. (c) **2026-12-02 (E)** (Nasdaq; EPS $2.41). (d) QUEUED. (e) conviction 2 (watch). GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2026-12-02)
- **28. SNOW - Snowflake.** (a) Bullish; Cortex AI monetisation. Nebius's 11-12 letter names Snowflake among enterprise platforms signing multi-year AI-cloud agreements (secondary read-through, On The Wire 2026-11-12). Dilution carried ($3.5B convertible 09-28). (c) **2026-12-02 (E)** after hours (Nasdaq). (d) QUEUED. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2026-12-02)
- **29. AAPL - Apple.** (a) Bullish. FQ4 print consumed (11-02, W45). Price 356.27 (+4.1%). (c) Next print **2027-02-04 (E)** (FMP). (d) QUEUED. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2027-02-04)
- **30. GOOGL - Alphabet.** (a) Bullish. The 10-28 EPS miss is largely an equity-investment mark (W45, secondary; 10-Q not read). Price 295.77 (+3.9%; 304.97 intraday high 11-13). (c) Next print **2027-02-03 (E)** (FMP). (d) QUEUED; **two open Strategy D lots**. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2027-02-03)

### 31-40

- **31. PLTR - Palantir. NEW.** (a) Bullish. Q3 (W45, secondary): revenue about $2.31B (+96%), FY guide raised. Nebius letter: Palantir named Nebius a preferred AI cloud partner (secondary). (c) Next **2027-02-01 (E)** (FMP). (d) NEW. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2027-02-01)
- **32. UBER - Uber. NEW.** (a) Bullish. Q3 8-K (W45): gross bookings $59.8B (+20%), Q4 guide $63.25-65.25B. (c) Next **2027-02-03 (E)** (FMP). (d) NEW; open Strategy D lot. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2027-02-03)
- **33. DDOG - Datadog.** (a) Bullish, reduced. Flat Q4 guide on a largest-customer assumption; -14.4% on 11-04 (W45). Nebius's letter names Datadog among platforms signing multi-year agreements (secondary). (c) Next print **undated** (February INFERRED). (d) QUEUED. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst undated)
- **34. MSFT - Microsoft.** (a) Bullish. 10-28 beat consumed (W45); 523.88 (-1.3%). (c) Ignite 2026-11-17..20 (E, third-party listing, not re-checked); next print 2027-01-27 (E, FMP). (d) QUEUED. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2026-11-17)
- **35. AMZN - Amazon.** (a) Bullish. AWS +39.3% (carried); 266.66 (+2.8%). (c) re:Invent 2026-11-30..12-04 (E, not re-checked); next print 2027-02-04 (E, FMP). (d) QUEUED; two open Strategy D lots. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2026-11-30)
- **36. SHOP - Shopify. NEW.** (a) Bullish. Printed 11-03; no release read. (c) Next **2027-02-10 (E)** (FMP). (d) NEW. (e) conviction 1-2. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2027-02-10)
- **37. JPM - JPMorganChase.** (a) Bullish. 10-13 print missed (carried). (c) **2027-01-14 (E)** (FMP). (d) QUEUED. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2027-01-14)
- **38. META - Meta Platforms.** (a) Bullish, reduced; capex floor and negative FCF carried. Reuters 11-13: META +1.3% on 11-13 intraday, the only hyperscaler up. (c) **2027-01-27 (E)** (FMP). (d) QUEUED. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2027-01-27)
- **39. GE - GE Aerospace. NEW.** (a) Bullish. Printed 10-20. (c) **2027-01-21 (E)** (FMP). (d) NEW. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2027-01-21)
- **40. MRNA - Moderna. NEW.** (a) Bullish; vaccine-policy report carried as adverse. The 11-06 print slot was never verified (Friday gap in W45; still unverified). (c) Next **2027-02-12 (E)** (FMP). (d) NEW. (e) conviction 1-2. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2027-02-12)

### 41-50

- **41. LLY - Eli Lilly.** (a) Bullish. Printed 10-29; print consumed. (c) Next **undated** (early February INFERRED). (d) QUEUED. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst undated)
- **42. XOM - ExxonMobil.** (a) Bullish. Printed 10-30; shock thesis weaker with Brent near 99 (W45). (c) **2027-01-29 (E)** (FMP). (d) QUEUED. (e) conviction 1-2. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2027-01-29)
- **43. CVX - Chevron.** (a) Bullish. Same seam as XOM/COP. (c) **2027-01-29 (E)** (FMP). (d) QUEUED. (e) conviction 1-2. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2027-01-29)
- **44. INTC - Intel.** (a) Bullish. 10-29 print then -28.6% (D1 e2dfa715); thesis is whether the guide or the market's read was the issue. (c) **2027-01-28 (E)** (FMP). (d) QUEUED. (e) conviction 1-2. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2027-01-28)
- **45. CAT - Caterpillar.** (a) Bullish. Printed 10-29 (-9.25%, carried); farm-equipment RFI overhang. (c) Next **undated**. (d) QUEUED. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst undated)
- **46. GEV - GE Vernova.** (a) Bullish. Printed 10-28; AI-power complex down 2% to 3.3% on 11-13 (Reuters, with CEG and Vistra); D1 5ada3494 / 226bf170 watch item (unquantified SoftBank-default claim, 11-06) still open. (c) Next **undated**. (d) QUEUED; **open Strategy D lot**. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst undated)
- **47. AMAT - Applied Materials. DIRECTION UNRESOLVED (reversed from inadmissible).** (a) Direction unresolved: the W45 bearish WFE-cliff thesis is contradicted by the 2026-11-12 issuer release (record revenue $10.41B +53%, non-GAAP EPS $4.16, FQ1 guide $11.1B ±$0.5B / EPS $4.35 ±$0.20; DRAM 33% and foundry-logic 58% of Semi Systems) but the stock already rose +11.4% on the week (370.50 on 11-13 after 380.95 pre-print), so no bullish gap is established. Ineligible for the top-10. (c) Next print **undated** (February pattern INFERRED). (d) QUEUED. (e) 41-50, conviction 1. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst undated)
- **48. SNDK - Sandisk. NEW.** (a) Bullish. FQ1 EPS $49.51 vs $46.19 (carried); Reuters 11-13: Sandisk -9.3% intraday in the AI selloff. (c) Next **undated**. (d) NEW. (e) conviction 1. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst undated)
- **49. RDDT - Reddit. NEW.** (a) Bullish. Q3 EPS $1.40 vs $1.31 (carried); -29.2% on 10-30 per D1. (c) Next **undated**. (d) NEW. (e) conviction 1. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst undated)
- **50. TGT - Target.** (a) **DIRECTION UNRESOLVED** (prior bearish thesis refuted; no replacement); ineligible for the top-10. (c) Earnings **2026-11-18 (C)** pre-market (corporate.target.com notice carried from W45; Nasdaq EPS $2.04, 12 est.). (d) QUEUED. (e) conviction 1. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2026-11-18)

### DIRECTION-INADMISSIBLE tier

Belong to Strategy B. The rail governs only admission to the actionable tier. None is in the top-10; none may be converted to an A `PENDING_ANALYSIS` row.

- **I-1. UAL - United Airlines.** `DIRECTION-INADMISSIBLE (A long-only rail)`. (a) Bearish (fuel-shock channel), direction-unresolved as in W45. (b) No new evidence read; Reuters 11-12 cites higher oil prices that session. (c) Printed 10-20; next **2027-01-19 (E)** (FMP). (d) Not queued. (e) Inadmissible, conviction 1-2. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2027-01-19)
- **I-2. AAL - American Airlines.** `DIRECTION-INADMISSIBLE (A long-only rail)`. (a) Bearish (thinnest balance sheet; same fuel seam). (b) No new evidence read. (c) Printed 10-22; next **2027-01-26 (E)** (FMP). (d) Not queued. (e) Inadmissible, conviction 1-2. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2027-01-26)
- **I-3. DAL - Delta Air Lines.** `DIRECTION-INADMISSIBLE (A long-only rail)`. (a) Bearish, same seam. (b) No new evidence read. (c) Printed 10-09; next **2027-01-13 (E)** (FMP). (d) Not queued. (e) Inadmissible, conviction 1-2. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2027-01-13)
- **I-4. CCL - Carnival.** `DIRECTION-INADMISSIBLE (A long-only rail)`. (a) Bearish (bunker-fuel channel). (b) No new evidence read. (c) Earnings **2026-12-18 (E)** (FMP and Nasdaq). (d) Not queued. (e) Inadmissible, conviction 1-2. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2026-12-18)
- **I-5. WMT - Walmart.** `DIRECTION-INADMISSIBLE (A long-only rail)`. (a) Bearish, thin (low-income consumer; staples relative strength is contrary). (b) No new evidence read. (c) Earnings **2026-11-19 (C)** pre-market (Nasdaq and FMP agree; EPS $0.64). (d) On queue. (e) Inadmissible, conviction 1. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2026-11-19)
- **I-6. ADBE - Adobe.** `DIRECTION-INADMISSIBLE (A long-only rail)`. (a) Bearish, stronger as of W45 (software kept falling on AI-disruption and guide worries; DDOG -14.4%, NOW -26.95%). (b) No new evidence read this week. (c) Earnings **2026-12-09 (C)** (issuer-confirmed per PART 1B.2; Nasdaq and FMP agree; EPS $5.11 / $6.33 estimates differ, vendors not reconciled). (d) On queue. (e) Inadmissible, conviction 2. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2026-12-09)
- **I-7. HD - Home Depot.** `DIRECTION-INADMISSIBLE (A long-only rail)`. (a) Bearish / neutral (housing turnover starved). (b) No new evidence read. (c) Earnings **2026-11-17 (C)** pre-market (issuer-confirmed per PART 1B.2; Nasdaq; EPS $3.86). (d) On queue. (e) Inadmissible, conviction 1. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst 2026-11-17)
- **I-8. AKAM - Akamai.** `DIRECTION-INADMISSIBLE (A long-only rail)`. (a) Bearish / contested; smallest cap in the file; printed 11-05, result not read. (b) No new evidence read. (c) Next print **undated** (no FMP/Nasdaq row). (d) On queue. (e) Inadmissible, conviction 1. GATE: GATE-SURVIVING (gate 2026-11-15; catalyst undated)

**W4 side, restated because it binds:** no `DIRECTION-INADMISSIBLE` candidate may be converted into an A `PENDING_ANALYSIS` row; a vacated slot is filled from the next admissible candidate. WMT, ADBE, HD, AKAM are already on the A queue; D2 applies the rail to any thesis run on them. TGT and AMAT (direction-unresolved) are also ineligible for the top-10.

### Handoff notes for W4

- **TOP-10 (all admissible, long, all QUEUED):** 1 VRTX, 2 FSLR, 3 NVDA, 4 TTWO, 5 MU, 6 DELL, 7 MRVL, 8 AVGO, 9 ORCL, 10 PANW. **NEW: zero.** Zero direction-inadmissible names in the tier. NVDA (row 3) carries a leadership/governance event risk (CEO exit 11-12, print 11-17, company meeting 11-18); W4 should carry the GATE literal verbatim and D2 should size to the binary risk.
- **Tier changes vs 2026-W45:** CSCO 6 → 11 and CEG 7 → 12 (both printed, next dates 2027 or undated); NVDA 3 → 3, FSLR 2 → 2, VRTX 1 → 1 (unchanged); TTWO 4 → 4 (catalyst re-pointed to the 11-19 GTA VI launch); MU 8 → 5, DELL 10 → 6, MRVL 9 → 7, AVGO 5 → 8 (conviction 3 → 2, gap narrowed +18%); ORCL 20 → 9 (dated 12-09 (E) catalyst) and PANW 27 → 10 (11-18 (C)) refill the tier; AMAT inadmissible → 47 (reversed); NOW 47 → dropped.
- **NEW (not on the census), admissible:** ETN, LRCX, PLTR, UBER, SHOP, DIS, MRNA, GE, SNDK, RDDT (10 of 50). Inadmissible and not queued: UAL, AAL, DAL, CCL.
- **Already QUEUED but outside the top-10:** CSCO, CEG, AMD, ANET, NBIS, SMCI, QCOM, COP, HPE, INTU, CRWD, NTAP, OKTA, CRM, SNOW, AAPL, GOOGL, DDOG, MSFT, AMZN, JPM, META, LLY, XOM, CVX, INTC, CAT, GEV, AMAT, TGT (30). Census members not ranked: IBM, MRK, NOW.
- **SPENT in the top-10: zero; SPENT overall: zero.** The gate (2026-11-15) will move again if D2a queues a refresh after this run; re-derive next cycle.
- **Stale queue-row payloads to overwrite:** TTWO row date 11-09 (consumed; live catalyst GTA VI 2026-11-19 (C)); CEG, CSCO, NBIS, AMAT rows cite consumed 11-09/11-12 prints (CSCO live 2027-02-10 (E); CEG, NBIS, AMAT undated); MU row cites the consumed 09-30 print (live catalyst 2026-12-16 (E)); AVGO row 12-10 (E) → 12-09 (C); PANW 11-18 now (C); DELL 11-24 now (C); JPM `spent_by_gate_likely` payload stale; COP, ANET, AAPL, AMD, QCOM, SMCI, DDOG rows cite consumed prints (live catalysts 2027, mostly (E)).
- **Cross-strategy overlap:** only Strategy D is open (AMZN, DIS, GEV, GOOGL, ISRG, RTX, TSM, UBER); no A or C position, so no A/C conflict. Candidates with open D lots: AMZN (#35), GOOGL (#30), GEV (#46), DIS (#23), UBER (#32).
- **Re-check next cycle:** NVDA print and CEO-search/congressional outcome; TTWO GTA VI first-week disclosure; VRTX PDUFA 11-30; FSLR Section 232 go-live 12-04; whether the data-centre moratorium wave is a lasting demand change; CRWV (printed 11-10, not researched here, not in the census); next-print dates for CEG, ETN, NBIS, QCOM, LRCX, DDOG, LLY, CAT, GEV, AMAT, SNDK, RDDT, AKAM; HD/WMT/TGT prints (11-17/11-19/11-18).

### REPORT IT — CATALYST-GATE MODE

- **Gate date: 2026-11-15.** Inputs: (a) next scheduled re-score 2026-12-01 (completed `M1a` = 1, `M1b` = 1 this month); (b) no open `regime-refresh` item; (c) the REFRESH REQUEST query returned 4 uncovered triggers (`geopolitical_qualifying_event` 2026-11-08; `vix_drift_gt5_ending_normal`, `breadth_mom_rise_gt10`, `vix_regime_exit_high` all 2026-11-09) → D2a run 2026-11-15. A reads DO-NOT-ACTIVATE; mode live.
- **Counts:** 58 carried (50 ranked admissible incl. direction-unresolved TGT and AMAT + 8 DIRECTION-INADMISSIBLE); **0 SPENT-BY-GATE, 58 GATE-SURVIVING.** Zero SPENT because every name whose only dated catalyst was a 11-09..11-13 print was re-dated to its next dated catalyst or left `undated` (fail-open); no candidate has a dated catalyst before 2026-11-15 without a later one.
- **Undated survivors (fail-open): 13** (CEG, ETN, NBIS, QCOM, LRCX, DDOG, LLY, CAT, GEV, AMAT, SNDK, RDDT, plus inadmissible AKAM).
- **Narrowest survivors:** NVDA, DIS, HD (inadmissible) 2026-11-17; PANW, TGT 2026-11-18; TTWO (GTA VI), INTU, WMT (inadmissible) 2026-11-19.
- **Research-cost:** top-10 and 11-20 rows carry full (a)-(e) with a document re-checked or newly cited this week for 15 of 20 names; 21-50 tiers carry terse carry-forward (b) where evidence is unchanged. Parallel calls used: 11 (web_search only); IBKR price reads: 25 names plus SPY.

## PART 2C — Strategy C ranked shortlist

### Router state, and what it admits

C reads **HYBRID ACTIVATE (FOMC-only)** (`state.current_regime` STRATEGY_ACTIVATION, MEASURED by the orchestrator this run; A, D, E DO-NOT-ACTIVATE, B ACTIVATE). Under it **only an FOMC-class event is router-admissible**. Earnings and FDA PDUFA candidates below are ranked for the divergence record and for the day C is widened, and are marked **router-PARKED (not router-admissible), not to be enqueued**.

`state.open_queue` strategy C returns **one row** (orchestrator-MEASURED): `thesis-FOMC-C-20261130` (thesis-construction, ticker FOMC, PENDING_ANALYSIS, due **2026-11-30**), for the 2026-12-09 FOMC. **W4 must not create a duplicate FOMC row.** Overlap/context: this row IS candidate 1. Its conservative default is "decline, no entry" unless an affirmative, sourced, quantified divergence is established; last permitted entry day is **Tuesday 2026-12-08** (criterion 5: entry at least 1 trading day before the event). Δ vs W45: queue unchanged; the meeting is now 24 days out.

### The capital position (state_brief, orchestrator-MEASURED 2026-11-15)

| Field | Value |
|---|---|
| Strategy C NAV (`analytics.strategy_nav`) / available | **$18.55 / $18.55** |
| 2% sizing base | $0.37 |
| Open C positions / open A positions | none / none (open positions are Strategy D only) |
| `state.open_queue` strategy C | 1 row (`thesis-FOMC-C-20261130`) |

Δ vs W45: NAV unchanged at $18.55. Borrow-blocked status and donor capacity were measured in W45 (donor_capacity_total 0, `borrow_blocked` TRUE) and were NOT re-read this run (carried).

**Per-thesis no-ceiling sizing discipline (Rev 43/19):** max loss (including the cascade term) must not exceed the thesis's stated risk budget; a long debit structure's max loss equals its debit. With a whole portfolio of $18.55 the test is whether the cheapest defined-risk structure debits at or below $18.55. Credit spreads, iron condors and butterflies need collateral of width less credit and are unfundable; borrow is blocked. **Every candidate below is a deferral at current NAV; each (d) says so.**

### Criterion 1 (a qualifying event within 45 days)

Window **2026-11-15 to 2026-12-30**.

- **FOMC 2026-12-09 (C-carried):** federalreserve.gov calendar as fetched in W45 (2026-11-08): "December 8-9, 2026 (SEP meeting)". Not re-fetched by this part; PART 1B owns the refresh. Corroborating (E, secondary, fetched 2026-11-15): Frenzy Capital FedWatch page and The Edge both list the decision for Dec 9 14:00 ET with press conference 14:30 ET; Frenzy Capital also lists **FOMC minutes Wed 2026-11-18 14:00 ET** (E; not a Fed primary page; flag for 1B).
- **Earnings (router-PARKED):** dates from the Nasdaq shared pull (`nasdaq_ge2b.csv`, cache caveat: pages after 11-16 were cached 11-04 to 11-10, so dates reflect Nasdaq as of that time). Issuer-confirmed this run (C), by fetched issuer/IR text: **NVDA 2026-11-17 after close** (investor.nvidia.com event page "November 17, 2026 05:00 PM EST"), **PANW 2026-11-18 after close** (PANW release 2026-11-03), **WMT 2026-11-19 pre-market** (corporate.walmart.com release 2026-11-12: 6 a.m. CST results, 7 a.m. CST call), **DELL 2026-11-24, results before the 3:30 p.m. CST call** (Dell IR release 2026-11-10). Carried from W45 PART 1A/1B without re-fetch: HD 11-17 pre-market (W45 notes the IR page governs; (C) carried), MRVL 12-01 (C carried, Marvell IR notice 2026-11-06). Nasdaq-only (E): CRWD 12-01 (time not supplied), CRM 12-02, ORCL 12-09, AVGO 12-10, COST 12-10, MU 12-16.
- **PDUFAs (router-PARKED), re-checked this run:** CAPR deramiocel **2026-11-22** (C: Capricor 8-K ex. 99.1 filed 2026-11-10, "PDUFA target action date of November 22, 2026", extended by major amendment); VRTX povetacicept **2026-11-30** (C-secondary: Vertex announcement as quoted by MDSpire 2026-10-29 and biopharmatranscript calendar); COGT bezuclastinib GIST **2026-11-30** (C: Cogent release 2026-11-05) and NonAdvSM **2026-12-30** (C, same release).
- **Passed since W45 (struck):** CSCO and AMAT (earnings 2026-11-12 after close; outcomes not researched, D1 did not cover 11-10 to 11-13), KKR/CEG 11-09, TDG 11-10. **SMMT ivonescimab PDUFA 2026-11-14 (Saturday): date has passed; no FDA action found as of the sources fetched** (RTTNews 2026-11-12: outcome "pending"; Dan Sfera 2026-11-14: "Outcome Not Yet Recorded"; Summit's Q3 release 2026-11-04 says it will issue a release after FDA action). Treated as UNRESOLVED, not ranked; not re-searched beyond that one call. Δ: W45 ranked it #6. A Friday-11-13 action cannot be excluded.

### The tenor rail: CLEAR, ninth cycle running

C requires structure expiration within 1-45 days of entry. MEASURED from live SPY option parameters (IBKR underlying 756733, read 2026-11-15): listed expiries include 11-16..11-20, 11-23..11-25, 11-27, 11-30, 12-04, **12-11 (SPY, 2SPY)**, 12-18 (regular), 12-24, 12-31, then monthlies.

- **FOMC 12-09:** no 12-10 expiry lists, so **the first listed expiry strictly after the event is 12-11** (2 calendar days after). From an 11-16 entry that is 25 days, from the last permitted entry day 12-08 it is 3 days: inside 1-45 either way. 12-24 is 39 days from 11-15; 12-31 is 46 days from 11-15 (outside) and 23 days from 12-08.

### Criterion 2 (implied vs realized): MEASURED on the spec window (trailing 30 days)

Headline is **IV/HV30** per `strategy/05_strategy_c.md`; HV10 and HV20 are context only. Realized vol = annualized close-to-close, log returns, sample stdev x sqrt(252), from **IBKR regular-session daily bars** (`outside_rth` false), last close **Friday 2026-11-13**. HV30 = 30 returns over 31 closes (SPY: 10-02 to 11-13); HV20 = 21 closes; HV10 = 11 closes. Implied move = ATM straddle mid / spot; realized-equivalent = 0.8 x HV30 x sqrt(T/365), T = calendar days from 2026-11-15 to expiry. Option quotes: IBKR snapshots read 2026-11-15 ~07:45-07:55Z (market closed; books are Friday's close; quote timestamps differ by leg, so put-call and spread arithmetic is approximate). "Contract IV" is IBKR `implied_vol` where `is_valid` TRUE. "30d IV" is IBKR `implied_vol_underlying` (30-day constant-maturity; includes any event inside the next 30 days, so it is NOT event-isolated).

**FOMC instrument: SPY.** SPY closed **754.37** on 11-13 (-0.36%). SPY 2026-12-11 754 call 13.02/13.14 and put 12.20/12.33; straddle mid **$25.35** ($2,535 per straddle), 3.36% of spot. **Contract IV is VALID this week: 15.13%** (MEASURED, both legs); `option_midpoint_iv` invalid. Straddle-derived IV cross-check 15.7% (INFERRED). SPY 30d IV 14.82% (valid).

| SPY window | Closes (returns) | Realized vol | IV/HV (contract IV 15.13%) | IV/HV (30d IV 14.82%) |
|---|---|---|---|---|
| **HV30 (spec)** | 31 (30) | **18.9%** | **0.80** | 0.78 |
| HV20 | 21 (20) | 22.3% | 0.68 | 0.66 |
| HV10 | 11 (10) | 29.5% | 0.51 | 0.50 |

**Δ vs W45** (11-06 basis): HV30 17.25 to **18.9**; headline ratio **1.18 (straddle-derived) to 0.80 (contract IV, valid)**; the IV basis changed from an inferred straddle IV to a valid contract IV, so the move is approximate, but the sign is clear: **SPY options now price LESS vol than SPY realized over the trailing 30 days** (HV10 29.5% against 15.1%). The 30-day window still contains 11-05 (-4.41%) and the 11-09 relief rally (+2.37%, per D1 `8327041f`), and SPY then drifted to 754.37; D1's VIX 25.64 to 19.92 on 11-09 is consistent with implied compressing. INFERRED: the ratio will drift up if realized calms. Implied move to the 12-11 expiry 3.36% vs realized-equivalent 4.04% (26 days; only 2 of 26 days follow the event, so not event-isolated). **Snapshot caveat:** the IBKR `last` for SPY was 749.60 (ts 2026-11-14 00:59Z, an after-hours print, -0.63% vs the 754.37 close); the bar close is used as spot.

**Market-implied policy path (the "what the Fed is priced to do" leg), E-tagged, fetched 2026-11-15.** Fed funds target 3.75-4.00%. CME FedWatch via InvestmentNews 2026-11-13 (after PPI): **89.7% a 25bp hike to 4.00-4.25%, 10.3% a 50bp hike**, no cut or hold weight; Frenzy Capital (futures, as of 11-13 5 pm ET): 93% / 7%; Kalshi (predictionmarketspicks 11-14): hike 25bp 90%, hike 50bp 10%, hold 4%. History: 9-16 hike 25bp (first in three years per Investing.com 11-10), 10-28 hold 10-2 (Cook and Hammack dissented for a hike, per MLQ 11-12), October CPI +0.4% m/m vs 0.3% expected (11-10), Waller said the bank ought to hike in December (Investing.com 11-10), Bloomberg 2026-11-13 headline "Fed Set to Raise Interest Rates Next Month as Debate Moves to January". So **a 25bp hike is ~90% priced; the open uncertainty is a 50bp move and the SEP/dots/January guidance.** Hold is priced ~0-5%.

**Cheapest defined-risk SPY structure for 12-09, MEASURED this run:** 754/756 call debit spread (12-11): buy 754 call at ask 13.14, sell 756 call at bid 11.81 = **$1.33 per share = $133 per spread** at the natural (quotes not simultaneous; the 755 call was not quoted, so no 1-wide price is claimed). A put spread is NOT claimed: the 754 and 756 put quotes are mutually inconsistent (754 put bid 12.20 above 756 put ask 11.95), a stale-leg artefact. Against NAV $18.55 the cheapest measured structure is a shortfall of at least ~$114. **Deferral stands.**

**Panel: nearest-expiry ATM straddle spanning each event** (IBKR). All earnings rows are router-PARKED; pricing measurement only. "Spr" is leg bid/ask spread as a share of mid; where wide, trust IV over the straddle mid.

| Name | Event (tag) | Expiry (T) | Spot (11-13) | Strike | Straddle mid | Contract IV | HV30 / HV20 / HV10 | IV/HV30 | Implied move vs realized-equiv. |
|---|---|---|---|---|---|---|---|---|---|
| SPY | FOMC 12-09 (C-carried) | 12-11 (26) | 754.37 | 754 | $25.35 ($2,535) | 15.1% (valid) | 18.9 / 22.3 / 29.5 | **0.80** | 3.36% vs 4.04% |
| NVDA | earnings 11-17 AMC (C) | 11-18 (3) | 162.85 | 162.5 | $13.55 ($1,355), Spr ~12% | 93.2% | 46.3 / 54.0 / 64.7 | **2.01** | 8.3% vs 3.4% |
| HD | earnings 11-17 pre (C-carried) | 11-20 (5) | 348.69 | 347.5 | $18.05 ($1,805), Spr ~3% | 46.5% | 34.3 / 37.4 / 44.2 | 1.35 | 5.2% vs 3.2% |
| PANW | earnings 11-18 AMC (C) | 11-20 (5) | 322.24 | 322.5 | $35.83 ($3,583), Spr ~1% | 100.6% | 60.7 / 60.3 / 64.9 | 1.66 | 11.1% vs 5.7% |
| WMT | earnings 11-19 pre (C) | 11-20 (5) | 128.09 | 128 | $8.00 ($800), Spr ~4% | 56.5% | 24.0 / 25.6 / 30.4 | **2.36** | 6.3% vs 2.3% |
| DELL | earnings 11-24 after close (C) | 11-27 (12) | 344.53 | 345 | $56.70 ($5,670), Spr ~5% | 104.2% | 97.6 / 109.2 / 130.6 | 1.07 | 16.5% vs 14.2% |
| MRVL | earnings 12-01 (C-carried) | n/m (30d IV only) | 156.76 | n/m | n/m | 82.8% (30d IV) | 106.9 / 124.5 / 143.3 | 0.77 | n/m |
| CRWD | earnings 12-01 (E) | n/m | 226.61 | n/m | n/m | 72.7% (30d IV) | 60.2 / 60.7 / 64.2 | 1.21 | n/m |
| CRM | earnings 12-02 (E) | n/m | 217.84 | n/m | n/m | 55.2% (30d IV) | 32.7 / 31.4 / 30.3 | 1.69 | n/m |
| ORCL | earnings 12-09 (E), same day as FOMC | n/m | 125.35 | n/m | n/m | 63.0% (30d IV) | 74.1 / 76.7 / 84.8 | **0.85** | n/m |
| AVGO | earnings 12-10 (E) | n/m | 347.01 | n/m | n/m | 56.9% (30d IV) | 62.6 / 70.7 / 89.6 | **0.91** | n/m |
| COST | earnings 12-10 (E) | n/m | 1,106.21 | n/m | n/m | 24.2% (30d IV) | 20.2 / 22.4 / 25.2 | 1.20 | n/m |
| MU | earnings 12-16 (E) | n/m | 778.31 | n/m | n/m | 65.3% (30d IV; the 12-16 event is at ~31 days, so mostly ex-event) | 89.4 / 104.2 / 134.3 | **0.73** | n/m |
| TLT (rates proxy) | FOMC 12-09 | n/m | 79.38 | n/m | n/m | 11.8% (30d IV) | 11.5 / 12.5 / 11.3 | 1.03 | n/m |
| VRTX | PDUFA 11-30 | n/m | 538.60 | n/m | n/m | not read | 30.6 / 30.4 / 30.1 | n/m | n/m |

**IBKR rate limit hit.** After the NVDA/HD/WMT/PANW/DELL straddles, IBKR returned "Rate limit reached (limit: 10 requests per second, 30 requests per minute)" on the MRVL put leg and the MRVL call returned no quote; I did not retry. All "n/m" rows use the 30d constant-maturity IV only, which is NOT event-isolated, so those ratios are weaker evidence than the straddle rows. MRVL, CRWD, CRM, ORCL, AVGO, COST events fall inside the 30-day IV horizon (12-16 MU does not).

Reads. (1) **Near-dated announced earnings carry rich implied vs HV30: NVDA 2.01, WMT 2.36, PANW 1.66, HD 1.35**, DELL 1.07 (DELL's HV30 is already 98%). Those 3-5 day expiries are event-dominated, so the contract IV overstates the event-isolated vol less than for the longer expiries. (2) **Below 1.0 (market pricing less vol than the last 30 days delivered): SPY 0.80, MRVL 0.77, ORCL 0.85, AVGO 0.91, MU 0.73.** For MRVL, MU and AVGO the HV30 contains the 11-05 semis rout and the 11-09/11-10 rebound (MRVL -12.7% on the merger 8-K per D1 `da7bf33a`; MU -17.5% on 11-05; AVGO +18.2% over five sessions), so the ratio partly reflects a window artefact: HV10 exceeds HV30 on 12 of the 15 ranked names. (3) NVDA fell from 233.95 (10-02) to 162.85 (11-13); D1 recorded NVDA -6% on 11-09 (`8327041f`); the price half to 11-13 is from IBKR bars, the narrative for 11-10 to 11-13 was NOT researched (D1 did not run). (4) HV30 uses close-to-close and excludes overnight gaps. (5) NVDA and DELL straddle books are wide (Spr 12% and 5%); NVDA's straddle-derived IV is ~115% vs contract IV 93%.

### Ranked shortlist: 15 event candidates

**Changes vs W45's 15:** struck as passed: CSCO, AMAT (11-12). Added: DELL, MRVL, CAPR (COGT noted but not ranked); SMMT PDUFA removed (date 11-14 passed, outcome unresolved). Carried: FOMC, NVDA, HD, PANW, WMT, VRTX PDUFA, CRWD, CRM, ORCL, AVGO, COST, MU. **Rank rule (unchanged):** router admissibility first; then earnings with a measured options market ahead of PDUFA binaries; then event proximity, market cap and measured IV/HV30; not edge. Direction in every row is the divergence between the options market and a no-event realized baseline (HV30-based); W1 establishes no directional view. Primary documents (transcripts, 10-Q/10-K) were NOT read this run, so (b) names only what exists and what was consulted. A-queue membership is from the orchestrator's 47-name census.

**TOP-5**

**1. FOMC 2026-12-09 (C, SEP meeting), the only router-admissible candidate** — (a) No directional divergence established. The measurable divergence runs in the opposite direction to last week's: SPY IV/HV30 **0.80** (contract IV 15.1% vs HV30 18.9%, HV10 29.5%), so equity options are priced below recently realized vol into an event where the policy rate market prices a 25bp hike at ~90% and a 50bp hike at ~10% (the tail and the SEP/dots are the open variable). (b) federalreserve.gov calendar (W45 fetch); FedWatch-derived pages (InvestmentNews 2026-11-13, Frenzy Capital 11-13, Kalshi via predictionmarketspicks 11-14, Investing.com 2026-11-10, MLQ 2026-11-12, Bloomberg 2026-11-13, CNBC 2026-11-13 Goolsbee); the SEP and statement are primary documents published on the day; minutes of the 10-28 meeting due 11-18 14:00 ET (E). (c) **2026-12-09 (C-carried)**; first listed SPY expiry after it: 12-11. (d) **NOT executable at current capital: DEFERRAL** (NAV $18.55; cheapest measured structure is the $133 natural 754/756 call debit spread, shortfall at least ~$114; borrow blocked per W45). (e) No open A positions (none); not an A-queue name. (f) **Top-5, rank 1.** Disposition: thesis row `thesis-FOMC-C-20261130` already queued (due 11-30); W4 must not duplicate it. GATE-N/A (C row).

**2. NVDA, earnings 2026-11-17 after close (C)** — (a) Implied rich: ~8.3% straddle-implied vs 3.4% realized-equivalent (IV/HV30 **2.01**), after a 30-day slide from 233.95 to 162.85. (b) NVIDIA IR event page (Q3 FY27 results, Nov 17, 2026, 5:00 PM EST); factsdesk 2026-11-11 recounts guidance of $108.0B ±2% (E, secondary). (c) 2026-11-17 AMC; expiry 11-18. (d) **Deferral** (ATM call ask $7.00 = $700 single leg; straddle $1,355). (e) NVDA is in the A-queue census; no open A. (f) Top-5. **Router-PARKED.**

**3. HD, earnings 2026-11-17 pre-market (C-carried)** — (a) Implied modestly rich: 5.2% vs 3.2% (IV/HV30 **1.35**), HV30 34.3%. (b) Nasdaq pre-market; HD IR page per W45 (not re-fetched). (c) 2026-11-17 pre-market; first listed expiry 11-20. (d) **Deferral** (ATM call ask $9.85 = $985; straddle $1,805). (e) HD in A-queue; no open A. (f) Top-5. **Router-PARKED.**

**4. PANW, earnings 2026-11-18 after close (C)** — (a) Implied rich: 11.1% vs 5.7% (IV/HV30 **1.66**; IV 100.6%). (b) Palo Alto Networks release 2026-11-03 (fiscal Q1 FY27, after close Wed Nov 18; webcast 1:30 pm PT). (c) 2026-11-18 AMC; expiry 11-20. (d) **Deferral** (ATM call ask $18.00 = $1,800). (e) PANW in A-queue; no open A. (f) Top-5. **Router-PARKED.**

**5. WMT, earnings 2026-11-19 pre-market (C)** — (a) Implied richest relative to realized on the panel: 6.3% vs 2.3% (IV/HV30 **2.36**; HV30 only 24.0%). (b) Walmart corporate release 2026-11-12 (results 6 a.m. CST, call 7 a.m. CST) and its events page. (c) 2026-11-19 pre-market; expiry 11-20. (d) **Deferral** (ATM call ask $4.15 = $415; straddle $800). (e) WMT in A-queue; no open A. (f) Top-5. **Router-PARKED.**

**REST (6-15)**: all **router-PARKED**; all deferrals at C NAV $18.55. Single-leg ATM cost: MEASURED for DELL; for the "n/m" rows an INFERRED Brenner-Subrahmanyam estimate (0.4 x S x 30d IV x sqrt(days/365), to the first expiry after the event), not a chain read.

| # | Candidate | (a) Direction of divergence | (b) Documents consulted | (c) Date (tag) | (d) Executability at C $18.55 | (e) A overlap | IV/HV30 |
|---|---|---|---|---|---|---|---|
| 6 | **DELL** earnings | Implied roughly fair to realized: 16.5% vs 14.2%; HV30 98%; stock -7.2% on 11-13 (344.53) | Dell IR release 2026-11-10 | 2026-11-24, results before 3:30 pm CST call (C) | Deferral (ATM call ask $28.95 = $2,895) | DELL in A-queue; none open | 1.07 |
| 7 | **MRVL** earnings | Implied LEAN vs a window inflated by the LITE merger and 11-05 (HV30 107%, HV10 143%) | Marvell IR notice 2026-11-06 (per W45) | 2026-12-01 (C-carried) | Deferral (single leg ~$1,185 INFERRED) | MRVL in A-queue; none open | 0.77 (30d IV) |
| 8 | **CRWD** earnings | Implied modestly rich | Nasdaq only | 2026-12-01 (E, time not supplied) | Deferral (single leg ~$1,500 INFERRED) | CRWD in A-queue; none open | 1.21 (30d IV) |
| 9 | **CRM** earnings | Implied rich: IV 55% vs HV30 32.7% (30d IV already spans 12-02) | Nasdaq only | 2026-12-02 (E) | Deferral (single leg ~$1,100 INFERRED) | CRM in A-queue; none open | 1.69 (30d IV) |
| 10 | **VRTX** PDUFA povetacicept / IgAN | Binary regulatory outcome (accelerated approval, proteinuria surrogate); options not read | Vertex announcement via MDSpire 2026-10-29; biopharmatranscript PDUFA calendar | 2026-11-30 (C-secondary) | Deferral (chain not measured; HV30 30.6%) | VRTX in A-queue; none open | not measured |
| 11 | **CAPR** PDUFA deramiocel / DMD | Binary; third-party options read about +/-88.5% by the 11-27 expiry (BiopharmaWatch, as of 11-09; not measured here) | Capricor 8-K ex. 99.1 2026-11-10; Capricor release 2026-08-24 (extension) | 2026-11-22 (Sunday; C) | Deferral (chain not read) | not in A-queue; none open | not measured |
| 12 | **ORCL** earnings | Implied LEAN: 30d IV 63% below HV30 74% (HV10 85%) | Nasdaq only | 2026-12-09 (E), **same day as the FOMC (confounded)** | Deferral (single leg ~$843 INFERRED) | ORCL in A-queue; none open | **0.85** (30d IV) |
| 13 | **AVGO** earnings | Implied below realized: 56.9% vs 62.6% (HV10 89.6%) | Nasdaq only | 2026-12-10 (E), day after the FOMC | Deferral (single leg ~$2,108 INFERRED) | AVGO in A-queue; none open | **0.91** (30d IV) |
| 14 | **COST** earnings | Implied modestly rich: 24.2% vs 20.2% | Nasdaq only | 2026-12-10 (E) | Deferral (single leg ~$2,858 INFERRED) | COST not in A-queue; none open | 1.20 (30d IV) |
| 15 | **MU** earnings | Implied LEAN: 65.3% vs HV30 89.4% (HV10 134%); 30d IV is mostly ex-event | Nasdaq only | 2026-12-16 (E), expiry 12-18 | Deferral (single leg ~$6,113 INFERRED) | MU in A-queue; none open | **0.73** (30d IV) |

Also in window, not ranked: COGT bezuclastinib PDUFAs 11-30 (GIST) and 12-30 (NonAdvSM) (both C: Cogent release 2026-11-05); SMMT ivonescimab PDUFA 11-14 (passed, outcome unresolved); other earnings in PART 1B (DIS 11-17, TJX/LOW/TGT 11-18, INTU 11-19, ADI/MDT/ADSK/WDAY 11-24, ADBE/SNPS 12-09, ACN/NKE/CTAS 12-17).

**(e) A-vs-C exclusivity is vacuous this cycle.** `state.current_positions` holds Strategy D only; zero open A or C rows (state_brief, orchestrator-MEASURED).

**Price half (IBKR regular-session daily bars to Friday 2026-11-13, MEASURED).** SPY 754.37 (-0.36%), TLT 79.38, NVDA 162.85 (-2.0%), HD 348.69, PANW 322.24, WMT 128.09 (+1.5%), CRWD 226.61, MRVL 156.76 (-4.7%), CRM 217.84, ORCL 125.35, AVGO 347.01 (-4.8%), COST 1,106.21, MU 778.31 (-2.5%), DELL 344.53 (-7.2%), VRTX 538.60.

**Shortlists only.** Full thesis construction happens in sessions W4 schedules. Nothing here authorizes an enqueue for any parked name. **Measurement coverage:** contract-IV straddle (event-spanning expiry) for SPY, NVDA, HD, PANW, WMT, DELL; 30d IV only for MRVL, CRWD, CRM, ORCL, AVGO, COST, MU, TLT; no IV for VRTX, CAPR (PDUFA binaries). HV30/HV20/HV10 for all 15 plus TLT. MEASURED = IBKR bars/snapshots; INFERRED = straddle-derived IV cross-check, 30d-IV ratios as event proxies, single-leg estimates for "n/m" names, and every statement about why price moved on 11-05, 11-09 to 11-13 (D1 coverage: 11-09 only). Parallel calls this part: 4 (web_search); call log `calls_2c.csv`.

## Coverage, provenance and what this cycle changed

- **Orchestration.** Orchestrator plus five Sonnet sub-agents: one shared-data puller (the ONE FMP `calendar/earnings-calendar` pull in 4 chunks of ≤ 60 days, plus the Nasdaq key-less per-day calendar for every weekday 2026-11-09 → 2026-12-31, fetched through Parallel `web_fetch` because Parallel is now the only sanctioned web tool), then four section writers (PART 1A, 1B, 2A, 2C) working from those shared files without re-fetching them. BigQuery state (router, positions, A-queue census, CATALYST-GATE inputs) was read once by the orchestrator.
- **Metered calls this run:** 104 rows — 4 FMP (`credits=1` each) and 100 Parallel (39 `web_search`, 61 `web_fetch` URL rows). Nasdaq pages are now metered Parallel fetches (47 of the 61), unlike W45's unmetered curl. Many future-dated Nasdaq pages came back from Parallel's cache (`acquired_at` 2026-10-23 → 11-10), so dates after 11-16 reflect Nasdaq as of that cache; BABA's cached 11-24 was wrong (issuer: 11-19).
- **Orchestrator verification.** PART 2A's NVIDIA CEO-transition fact was re-read on the issuer page (nvidianews.nvidia.com, "NVIDIA Announces CEO Transition", 2026-11-12: Huang resigned as President, CEO and director; Kress interim CEO; Q3 FY27 results Tuesday 2026-11-17 ~1:20 pm PT "as previously scheduled").
- **Cross-part reconciliation.** BABA 2026-11-19 (issuer) in 1A/1B; AVGO 2026-12-09 (issuer) in 1A/1B/2A; ORCL date conflict (12-09 vs 12-14) stated in 1A, 1B and 2A row 9; SMMT and CYTK 11-14 PDUFA outcomes unresolved in 1B and unranked in 2C; FOMC minutes 11-18 tagged inferred in 1B and (E) vendor in 2C.
- **D1 coverage gap.** `state.fleet_blackout_days` lists 2026-11-10 → 11-12 (no routine ran), so D1 did not cover sessions 11-10 → 11-13 (11-13 is also the structural Friday gap). Newly announced catalysts in that span got only minimum per-name checks (issuer releases for names already carried); no broad news scan. The price half was closed from IBKR regular-session daily bars (11-06 and 11-13 closes, PART 2A).
- **Standing constraints, stated and deliberately NOT re-alerted:** FMP earnings horizon (terminal 2026-12-18, seventh week unmoved), 90-day clamp (chunked), FMP bulk-enumeration gate (`6c4004e3`), Friday-session gap (`b4e4e563`).

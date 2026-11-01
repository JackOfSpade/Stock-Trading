2026-W44

# Weekly Catalyst Calendar — Strategies A and C

**Run date 2026-11-01** (Sunday, `weekly_sun`). ISO week of TODAY's run date, 2026-W44. The upcoming trading week opens Monday 2026-11-02; that is context, not the marker.

**Windows.** Strategy A: 6 months, **2026-11-01 → 2027-05-01** — **effective confirmed-earnings horizon 2026-12-18 (47 days, ~6.7 weeks); sparse vendor coverage beyond it, per-name (E) fallback for shortlisted names.** Strategy C: 45 days, **2026-11-01 → 2026-12-16** (run date + 45 days, the same convention as W43's 10-25 → 12-09; the 12-09 FOMC decision sits on day 38 counting from 11-01 as day 0).

**EFFECTIVE CONFIRMED-EARNINGS HORIZON: 2026-12-18, 47 days (~6.7 weeks) from 2026-11-01. The terminal date did NOT move for a fifth week** (CCL 2026-12-18). Depth fell 54 → 47 days only because the clock advanced. Nine-week series, terminal date / days from that week's run date: 2026-12-03/88d (09-06), 2026-12-09/87d (09-13), 2026-12-09/80d (09-20), 2026-12-10/74d (09-27), 2026-12-18/75d (10-04), 2026-12-18/68d (10-11), 2026-12-18/61d (10-18), 2026-12-18/54d (10-25), **2026-12-18/47d (11-01)**. Standing plan-tier constraint (`FMP-earn-horizon`, `OWNER_ACTIONS.md`), deliberately NOT re-alerted; all FMP pulls chunked ≤ 60 days.

**Nasdaq key-less per-day calendar** (every weekday 2026-10-26 → 2026-12-16, shared CSV, not re-fetched): 4,224 total rows fetched (orchestrator figure); **1,712 rows at market cap ≥ $2B** (CSV parsed: 1,712 data rows). Of those: 561 fall 10-26 → 10-30 (week just printed) and **1,151 are forward 2026-11-02 → 2026-12-16** (1,061 in November, 90 in December to 12-16). 129 forward rows are ≥ $50B. 308 of 1,151 forward rows carry `time-not-supplied` (projected (E) signature). Latest Nasdaq date fetched: 2026-12-16.

**FMP coverage shape** (MEASURED, four chunked `calendar/earnings-calendar` calls by the orchestrator; 104 symbol-date rows over 77 symbols; counts parsed from the shared file):

| Span | Rows | Notes |
|---|---|---|
| Printed 10-26 → 10-30 | 27 | with actuals (e.g. MSFT, GOOGL, AMZN, INTC, XOM, CVX, ABBV, V, KO, BA, HCA, SBUX, F, FDX…) |
| 11-01 → 11-30 | 24 | AAPL, PLTR, ROKU 11-02 … BABA, NIO 11-24 |
| 12-01 → 12-24 | 5 | DOCU 12-03; ADBE 12-09; COST 12-10; NKE 12-17; CCL 12-18 |
| 12-24 → 2027-02-21 | 46 | chunk-2 header says 45; the row list parses to 46 (TLRY 01-11 … ETSY 02-18). Same shape as W43 plus the printed-week names re-projected (MSFT, AMZN, GOOGL, INTC, XOM, CVX, V, ABBV, SBUX…) |
| 2027-02-22 → 05-01 | 2 | RKT 02-25, FDX 03-25 (RIVN no longer here: now 02-11) |

Terminal date 2026-12-18 (CCL) = 47 days from 11-01, unchanged for a FIFTH week. Dead zones: 11-25 → 12-02 (DOCU 12-03 nearest) and 12-19 → 2027-01-10 (plan-tier constraint, not alerted).

**Cross-check FMP vs Nasdaq:** FMP covers 24 of the 1,151 forward Nasdaq names inside the window; **0 date disagreements** between FMP and Nasdaq for the in-window overlap. FMP names ABSENT from Nasdaq inside the pull: FUBO (11-17), LCID (11-09), ET (11-03) — same three as W43 (below the ≥ $2B filter or not in Nasdaq's feed). FMP names absent from Nasdaq because they report outside the pull dates (≥ 12-17 or already printed before 10-26 or 2027): CCL, NKE, LMT, NOK, PEP, META, T, TSLA, AAL, GM, GE, TSM, JNJ, UNH, GS, NFLX, UAL, BAC, C, JPM, WFC, DAL, TLRY (not an error). Nasdaq ≥ $2B forward names not in FMP: 1,127 of 1,151 (FMP is a sparse mega-cap subset; A-queue names with a forward date but no FMP row include HPE, PANW, AMAT, TTWO, CRWD, NTAP, SMCI, SNOW, DDOG, CRM, OKTA, MRVL, NBIS, INTU, ORCL, AVGO, MU, DELL, HD, COP, ANET, VRTX, AKAM).

A-queue (46) census vs Nasdaq forward window: 31 have a forward Nasdaq date inside 11-02 → 12-16, 12 printed 10-26 → 10-30 (AMZN, INTC, MSFT, CVX, LLY, NOW, XOM, GEV, MRK, FSLR, GOOGL, CAT), 3 have none: IBM, META, JPM (META/JPM FMP-only: 2027-01-27 / 2027-01-14).

**Every count in PART 1 beyond the C window is a FLOOR.** Universe enumeration past 2026-12-16 is impossible on this plan tier: `search/search-company-screener`, every `directory.*` route and `quote/batch-quote` are tool-level ACCESS DENIED (`ops.alerts` `6c4004e3`, standing, not re-alerted). The market-cap rail inside the C window is Nasdaq's own `marketCap` field; the 30-day ADV ≥ $10M rail is carried, not re-measured (1A.11).

## PART 1A — Strategy A universe, 6-month window (2026-11-01 → 2027-05-01)

No interpretation in this PART. Provenance tags:
- **(C)** company- or primary-source confirmed
- **(E)** estimated (vendor or aggregator projection)
- **(T)** tentative, no firm day

"Δ" marks a change against the 2026-10-25 (2026-W43) artifact. Rows tagged (C) "carried from W43" were issuer-confirmed last cycle and the date still matches; they were NOT re-read this run.

### 1A.1 — Earnings, inside the 45-day C window (2026-11-01 → 2026-12-16)

**Enumeration.** Nasdaq key-less per-day calendar, every weekday 2026-10-26 → 2026-12-16, market cap ≥ $2B: 1,712 rows, of which **1151 are forward (2026-11-02 → 2026-12-16)**; 129 of those are ≥ $50B. FMP rows (consensus detail) cover 24 of the forward Nasdaq names; all FMP dates inside the window agree with Nasdaq (FUBO 11-17, LCID 11-09 and ET 11-03 are FMP-only, below/outside the Nasdaq ≥ $2B pull). The 10-26 → 10-30 rows are the week just printed and are NOT in this table (see 'Printed this week'). `time-not-supplied` = projected (E): 308 of 1151 forward rows.

Tags this run: **(C)** issuer-confirmed. 'NEW' = confirmed by search of issuer release this run (WebSearch result citing the issuer's release; issuer page not opened first-hand unless stated). 'carried from W43, not re-read' = W43 file had an issuer confirmation for the same date, Nasdaq date unchanged. Everything else (E). Δ = date moved vs the 2026-W43 file.

**Detail table** — every forward reporter that is on the A queue, ≥ $50B, or tagged (C) last week (135 rows). Time codes: BMO before open, AMC after close, n/s not supplied. 'FMP' column = FMP consensus where covered (EPS est / revenue est).

| Ticker | Name | Type | Date | Tag | Mcap | Source / consensus |
|---|---|---|---|---|---|---|
| AAPL | Apple Inc. [A-queue] | Earnings (AMC, FQ Sep/2026) | 2026-11-02 | **(C)** | $5,092B | Nasdaq calendar; (C) Apple IR notice via secondary relay (C-secondary), carried from W43, not re-read; FMP agrees (EPS est 1.99, rev est $113.40B) |
| PLTR | Palantir Technologies Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-02 | **(C)** | $472B | Nasdaq calendar; (C) Palantir Business Wire release (read via copies), carried from W43, not re-read; FMP agrees (EPS est 0.4072, rev est $2.18B) |
| VRTX | Vertex Pharmaceuticals Incorporated [A-queue] | Earnings (AMC, FQ Sep/2026) | 2026-11-02 | **(C)** | $137B | Nasdaq calendar; (C) Vertex release 2026-10-07, carried from W43, not re-read |
| MAR | Marriott International | Earnings (BMO, FQ Sep/2026) | 2026-11-02 | (E) | $104B | Nasdaq calendar |
| WMB | Williams Companies, Inc. (The) | Earnings (AMC, FQ Sep/2026) | 2026-11-02 | (E) | $92B | Nasdaq calendar |
| FANG | Diamondback Energy, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-02 | (E) | $58B | Nasdaq calendar |
| O | Realty Income Corporation | Earnings (AMC, FQ Sep/2026) | 2026-11-02 | (E) | $54B | Nasdaq calendar |
| ETR | Entergy Corporation | Earnings (BMO, FQ Sep/2026) | 2026-11-02 | (E) | $51B | Nasdaq calendar |
| AMD | Advanced Micro Devices, Inc. [A-queue] | Earnings (AMC, FQ Sep/2026) | 2026-11-03 | **(C)** | $925B | Nasdaq calendar; (C) ir.amd.com 2026-10-06, carried from W43, not re-read; FMP agrees (EPS est 1.95, rev est $13.09B) |
| AMGN | Amgen Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-03 | (E) | $249B | Nasdaq calendar |
| ANET | Arista Networks, Inc. [A-queue] | Earnings (AMC (call 1:30 pm PT), FQ Sep/2026) | 2026-11-03 | **(C)** | $232B | NEW (C): arista.com press release 24817-pr-20261006 (2026-10-06) |
| SHOP | Shopify Inc. | Earnings (BMO (call 8:30 am ET), FQ Sep/2026) | 2026-11-03 | **(C)** | $217B | NEW (C): Shopify release 2026-10-06 "to Announce Third-Quarter 2026 Financial Results"; FMP agrees (EPS est 0.4613, rev est $3.70B) |
| PFE | Pfizer, Inc. | Earnings (BMO (call 10:00 am ET), FQ Sep/2026) | 2026-11-03 | **(C)** | $171B | NEW (C): Pfizer release 2026-09-22 "Invites Public to View and Listen to Webcast of November 3 Conference Call"; FMP agrees (EPS est 0.729, rev est $15.85B) |
| ETN | Eaton Corporation, PLC | Earnings (BMO, FQ Sep/2026) | 2026-11-03 | (E) | $153B | Nasdaq calendar |
| MPC | Marathon Petroleum Corporation | Earnings (BMO, FQ Sep/2026) | 2026-11-03 | (E) | $121B | Nasdaq calendar |
| BKNG | Booking Holdings Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-03 | (E) | $113B | Nasdaq calendar |
| RACE | Ferrari N.V. | Earnings (BMO, FQ Sep/2026) | 2026-11-03 | (E) | $94B | Nasdaq calendar |
| SU | Suncor Energy  Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-03 | (E) | $91B | Nasdaq calendar |
| ITUB | Itau Unibanco Banco Holding SA | Earnings (AMC, FQ Sep/2026) | 2026-11-03 | (E) | $81B | Nasdaq calendar |
| APO | Apollo Global Management, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-11-03 | (E) | $70B | Nasdaq calendar |
| MPLX | MPLX LP | Earnings (BMO, FQ Sep/2026) | 2026-11-03 | (E) | $61B | Nasdaq calendar |
| AME | AMTEK, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-11-03 | (E) | $58B | Nasdaq calendar |
| ALAB | Astera Labs, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-03 | (E) | $50B | Nasdaq calendar; new to the ≥ $50B / detail set this week (cap at the $50B boundary) |
| TRI | Thomson Reuters Corp | Earnings (BMO, FQ Sep/2026) | 2026-11-03 | (E) | $50B | Nasdaq calendar |
| SMCI | Super Micro Computer, Inc. [A-queue] | Earnings (AMC (call 5:00 pm ET), FQ Sep/2026) | 2026-11-03 | **(C)** | $23B | NEW (C): Supermicro IR (ir.supermicro.com) conference-call notice; 10-20 preliminary update also on IR |
| TM | Toyota Motor Corp Ltd Ord | Earnings (n/s, FQ Sep/2026) | 2026-11-04 | (E) | $256B | Nasdaq calendar |
| ARM | Arm Holdings plc | Earnings (AMC, FQ Sep/2026) | 2026-11-04 | (E) | $243B | Nasdaq calendar |
| QCOM | QUALCOMM Incorporated [A-queue] | Earnings (AMC, FQ Sep/2026) | 2026-11-04 | **(C)** | $195B | NEW (C): Qualcomm release 2026-10-22 "Schedules Fourth Quarter and Fiscal 2026 Earnings Release and Conference Call" (qualcomm.com/news/releases/2026/10) |
| MCD | McDonald's Corporation | Earnings (BMO, FQ Sep/2026) | 2026-11-04 | (E) | $182B | Nasdaq calendar |
| NVO | Novo Nordisk A/S | Earnings (BMO, FQ Sep/2026) | 2026-11-04 | (E) | $173B | Nasdaq calendar |
| UBER | Uber Technologies, Inc. [D held] | Earnings (BMO, FQ Sep/2026) | 2026-11-04 | **(C)** | $134B | Nasdaq calendar; (C) investor.uber.com release 2026-10-05, carried from W43, not re-read; FMP agrees (EPS est 0.864, rev est $14.67B) |
| CVS | CVS Health Corporation | Earnings (BMO, FQ Sep/2026) | 2026-11-04 | (E) | $116B | Nasdaq calendar |
| MCK | McKesson Corporation | Earnings (AMC, FQ Sep/2026) | 2026-11-04 | (E) | $114B | Nasdaq calendar |
| DDOG | Datadog, Inc. [A-queue] | Earnings (BMO, FQ Sep/2026) | 2026-11-04 | **(C)** | $95B | Nasdaq calendar; (C) Datadog date release, carried from W43, not re-read |
| EMR | Emerson Electric Company | Earnings (BMO, FQ Sep/2026) | 2026-11-04 | (E) | $95B | Nasdaq calendar |
| APP | Applovin Corporation | Earnings (AMC, FQ Sep/2026) | 2026-11-04 | (E) | $85B | Nasdaq calendar |
| MELI | MercadoLibre, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-04 | (E) | $84B | Nasdaq calendar |
| MSI | Motorola Solutions, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-04 | (E) | $81B | Nasdaq calendar |
| MFC | Manulife Financial Corp | Earnings (AMC, FQ Sep/2026) | 2026-11-04 | (E) | $76B | Nasdaq calendar |
| ALL | Allstate Corporation (The) | Earnings (AMC, FQ Sep/2026) | 2026-11-04 | (E) | $65B | Nasdaq calendar |
| GWW | W.W. Grainger, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-11-04 | (E) | $65B | Nasdaq calendar |
| MET | MetLife, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-04 | (E) | $64B | Nasdaq calendar |
| COR | Cencora, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-11-04 | (E) | $63B | Nasdaq calendar |
| AFL | Aflac Incorporated | Earnings (AMC, FQ Sep/2026) | 2026-11-04 | (E) | $62B | Nasdaq calendar |
| CVE | Cenovus Energy Inc | Earnings (BMO, FQ Sep/2026) | 2026-11-04 | (E) | $60B | Nasdaq calendar; **Δ vs W43 2026-10-30** |
| EW | Edwards Lifesciences Corporation | Earnings (AMC, FQ Sep/2026) | 2026-11-04 | (E) | $54B | Nasdaq calendar |
| COP | ConocoPhillips [A-queue] | Earnings (BMO (call 12:00 pm ET), FQ Sep/2026) | 2026-11-05 | **(C)** | $180B | NEW (C): ConocoPhillips Business Wire release 2026-09-24 |
| SONY | Sony Group Corporation | Earnings (BMO, FQ Sep/2026) | 2026-11-05 | (E) | $150B | Nasdaq calendar; FMP agrees (EPS est 0.38, rev est $20.15B) |
| MNST | Monster Beverage Corporation | Earnings (AMC, FQ Sep/2026) | 2026-11-05 | (E) | $136B | Nasdaq calendar |
| PH | Parker-Hannifin Corporation | Earnings (BMO, FQ Sep/2026) | 2026-11-05 | (E) | $117B | Nasdaq calendar |
| CNQ | Canadian Natural Resources Limited | Earnings (BMO, FQ Sep/2026) | 2026-11-05 | (E) | $114B | Nasdaq calendar |
| NET | Cloudflare, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-05 | (E) | $110B | Nasdaq calendar |
| SO | Southern Company (The) | Earnings (BMO, FQ Sep/2026) | 2026-11-05 | (E) | $107B | Nasdaq calendar |
| ABNB | Airbnb, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-05 | (E) | $100B | Nasdaq calendar |
| DUK | Duke Energy Corporation | Earnings (BMO, FQ Sep/2026) | 2026-11-05 | (E) | $98B | Nasdaq calendar |
| EOG | EOG Resources, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-05 | (E) | $85B | Nasdaq calendar |
| LITE | Lumentum Holdings Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-05 | (E) | $83B | Nasdaq calendar |
| CI | The Cigna Group | Earnings (BMO, FQ Sep/2026) | 2026-11-05 | (E) | $79B | Nasdaq calendar |
| CMI | Cummins Inc. | Earnings (BMO, FQ Sep/2026) | 2026-11-05 | (E) | $71B | Nasdaq calendar |
| SPG | Simon Property Group, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-05 | (E) | $70B | Nasdaq calendar |
| APD | Air Products and Chemicals, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-11-05 | (E) | $69B | Nasdaq calendar |
| TRGP | Targa Resources, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-11-05 | (E) | $67B | Nasdaq calendar |
| TRP | TC Energy Corporation | Earnings (BMO, FQ Sep/2026) | 2026-11-05 | (E) | $64B | Nasdaq calendar |
| NTRA | Natera, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-05 | (E) | $63B | Nasdaq calendar |
| CAH | Cardinal Health, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-11-05 | (E) | $58B | Nasdaq calendar |
| DVN | Devon Energy Corporation | Earnings (AMC, FQ Sep/2026) | 2026-11-05 | (E) | $56B | Nasdaq calendar |
| SRE | Sempra  | Earnings (BMO, FQ Sep/2026) | 2026-11-05 | (E) | $56B | Nasdaq calendar |
| WPM | Wheaton Precious Metals Corp. | Earnings (AMC, FQ Sep/2026) | 2026-11-05 | (E) | $56B | Nasdaq calendar |
| BDX | Becton, Dickinson and Company | Earnings (BMO, FQ Sep/2026) | 2026-11-05 | (E) | $54B | Nasdaq calendar |
| TEAM | Atlassian Corporation  | Earnings (AMC, FQ Sep/2026) | 2026-11-05 | (E) | $51B | Nasdaq calendar |
| ROK | Rockwell Automation, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-11-05 | (E) | $50B | Nasdaq calendar; new to the ≥ $50B / detail set this week (cap at the $50B boundary) |
| AKAM | Akamai Technologies, Inc. [A-queue] | Earnings (AMC, FQ Sep/2026) | 2026-11-05 | **(C)** | $14B | Nasdaq calendar; (C) Akamai release 2026-10-08, carried from W43, not re-read |
| BRK.A | Berkshire Hathaway Inc. | Earnings (n/s, FQ Sep/2026) | 2026-11-06 | (E) | $1,174B | Nasdaq calendar |
| BRK.B | Berkshire Hathaway Inc. | Earnings (n/s, FQ Sep/2026) | 2026-11-06 | (E) | $1,174B | Nasdaq calendar |
| ENB | Enbridge Inc | Earnings (BMO, FQ Sep/2026) | 2026-11-06 | (E) | $108B | Nasdaq calendar |
| MRNA | Moderna, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-11-06 | (E) | $89B | Nasdaq calendar; FMP agrees (EPS est -1.1, rev est $0.89B) |
| BAM | Brookfield Asset Management | Earnings (BMO, FQ Sep/2026) | 2026-11-06 | (E) | $78B | Nasdaq calendar |
| HUM | Humana Inc. | Earnings (BMO, FQ Sep/2026) | 2026-11-06 | (E) | $50B | Nasdaq calendar |
| CEG | Constellation Energy Corporation | Earnings (BMO, FQ Sep/2026) | 2026-11-09 | (E) | $94B | Nasdaq calendar; **Δ vs W43 2026-11-06** |
| KKR | KKR & Co. Inc. | Earnings (BMO, FQ Sep/2026) | 2026-11-09 | (E) | $86B | Nasdaq calendar |
| B | Barrick Mining Corporation | Earnings (BMO, FQ Sep/2026) | 2026-11-09 | (E) | $64B | Nasdaq calendar |
| OXY | Occidental Petroleum Corporation | Earnings (AMC, FQ Sep/2026) | 2026-11-09 | (E) | $63B | Nasdaq calendar |
| TTWO | Take-Two Interactive Software, Inc. [A-queue] | Earnings (AMC (4:30 pm ET), FQ Sep/2026) | 2026-11-09 | **(C)** | $36B | NEW (C): Take-Two IR release "to Report Second Quarter Fiscal Year 2027 Results on Monday, November 9, 2026" |
| PBR | Petroleo Brasileiro S.A.- Petrobras | Earnings (AMC, FQ Sep/2026) | 2026-11-10 | (E) | $141B | Nasdaq calendar |
| PBR.A | Petroleo Brasileiro S.A.- Petrobras | Earnings (AMC, FQ Sep/2026) | 2026-11-10 | (E) | $141B | Nasdaq calendar |
| NBIS | Nebius Group N.V. [A-queue] | Earnings (n/s, FQ Sep/2026) | 2026-11-10 | (E) | $47B | Nasdaq calendar; searched 2026-11-01, no issuer notice found (calendar sites only) |
| CSCO | Cisco Systems, Inc. [A-queue] | Earnings (n/s, FQ Oct/2026) | 2026-11-11 | (E) | $428B | Nasdaq calendar; FMP agrees (EPS est 1.32, rev est $18.11B); searched 2026-11-01, no FQ1 notice found |
| TDG | Transdigm Group Incorporated | Earnings (n/s, FQ Sep/2026) | 2026-11-11 | (E) | $65B | Nasdaq calendar |
| AMAT | Applied Materials, Inc. [A-queue] | Earnings (AMC (call 4:30 pm ET), FQ Oct/2026) | 2026-11-12 | **(C)** | $335B | NEW (C): Applied Materials release 2026-10-22 "to Report Fourth Quarter Fiscal 2026 Results" (appliedmaterials.com/.../102226-...) |
| BN | Brookfield Corporation | Earnings (BMO, FQ Sep/2026) | 2026-11-12 | (E) | $97B | Nasdaq calendar |
| NU | Nu Holdings Ltd. | Earnings (n/s, FQ Sep/2026) | 2026-11-12 | (E) | $59B | Nasdaq calendar |
| MUFG | Mitsubishi UFJ Financial Group Inc | Earnings (n/s, FQ Sep/2026) | 2026-11-13 | (E) | $260B | Nasdaq calendar |
| SMFG | Sumitomo Mitsui Financial Group Inc | Earnings (n/s, FQ Sep/2026) | 2026-11-13 | (E) | $157B | Nasdaq calendar |
| MFG | Mizuho Financial Group, Inc. | Earnings (n/s, FQ Sep/2026) | 2026-11-13 | (E) | $124B | Nasdaq calendar |
| NVDA | NVIDIA Corporation [A-queue] | Earnings (AMC (call 2:00 pm PT), FQ Oct/2026) | 2026-11-17 | **(C)** | $5,149B | NEW (C): nvidianews.nvidia.com "NVIDIA Sets Conference Call for Third-Quarter Financial Results" (search result, issuer newsroom); release ~1:20 pm PT; FMP agrees (EPS est 2.47, rev est $108.80B); **Δ vs W43 2026-11-18** |
| HD | Home Depot, Inc. (The) [A-queue] | Earnings (BMO, FQ Oct/2026) | 2026-11-17 | (E) | $328B | Nasdaq calendar; searched 2026-11-01, no issuer notice found (calendar sites only) |
| BHP | BHP Group Limited | Earnings (n/s, FQ Sep/2026) | 2026-11-17 | (E) | $208B | Nasdaq calendar |
| DIS | Walt Disney Company (The) [D held] | Earnings (BMO (webcast 8:30 am ET), FQ Sep/2026) | 2026-11-17 | **(C)** | $192B | NEW (C): Disney release 2026-10-12 (s206.q4cdn.com Walt Disney webcast notice); FMP agrees (EPS est 1.69, rev est $25.19B) |
| MDT | Medtronic plc | Earnings (n/s, FQ Oct/2026) | 2026-11-17 | (E) | $124B | Nasdaq calendar |
| PDD | PDD Holdings Inc. | Earnings (n/s, FQ Sep/2026) | 2026-11-17 | (E) | $113B | Nasdaq calendar |
| PANW | Palo Alto Networks, Inc. [A-queue] | Earnings (n/s, FQ Oct/2026) | 2026-11-18 | (E) | $311B | Nasdaq calendar; searched 2026-11-01, no issuer notice found (calendar sites only) |
| TJX | TJX Companies, Inc. (The) | Earnings (BMO, FQ Oct/2026) | 2026-11-18 | (E) | $156B | Nasdaq calendar |
| LOW | Lowe's Companies, Inc. | Earnings (BMO, FQ Oct/2026) | 2026-11-18 | (E) | $116B | Nasdaq calendar |
| TGT | Target Corporation [A-queue] | Earnings (BMO, FQ Oct/2026) | 2026-11-18 | **(C)** | $69B | Nasdaq calendar; (C) corporate.target.com, carried from W43, not re-read; FMP agrees (EPS est 2.05, rev est $26.39B) |
| WMT | Walmart Inc. [A-queue] | Earnings (BMO, FQ Oct/2026) | 2026-11-19 | **(C)** | $962B | Nasdaq calendar; (C) corporate.walmart.com, carried from W43, not re-read; FMP agrees (EPS est 0.638, rev est $187.24B) |
| INTU | Intuit Inc. [A-queue] | Earnings (n/s, FQ Oct/2026) | 2026-11-19 | (E) | $89B | Nasdaq calendar; searched 2026-11-01, no issuer notice found (calendar sites only) |
| ROST | Ross Stores, Inc. | Earnings (n/s, FQ Oct/2026) | 2026-11-19 | (E) | $74B | Nasdaq calendar |
| NTES | NetEase, Inc. | Earnings (n/s, FQ Sep/2026) | 2026-11-19 | (E) | $72B | Nasdaq calendar |
| KEYS | Keysight Technologies Inc. | Earnings (AMC, FQ Oct/2026) | 2026-11-19 | (E) | $56B | Nasdaq calendar; **Δ vs W43 2026-11-23** |
| VEEV | Veeva Systems Inc. | Earnings (n/s, FQ Oct/2026) | 2026-11-19 | (E) | $50B | Nasdaq calendar |
| A | Agilent Technologies, Inc. | Earnings (n/s, FQ Oct/2026) | 2026-11-23 | (E) | $51B | Nasdaq calendar; new to the ≥ $50B / detail set this week (cap at the $50B boundary) |
| DELL | Dell Technologies Inc. [A-queue] | Earnings (n/s, FQ Oct/2026) | 2026-11-24 | (E) | $302B | Nasdaq calendar; searched 2026-11-01, no issuer notice found (calendar sites only) |
| BABA | Alibaba Group Holding Limited | Earnings (n/s, FQ Sep/2026) | 2026-11-24 | (E) | $241B | Nasdaq calendar; FMP agrees (EPS est 1.61, rev est $40.26B) |
| ADI | Analog Devices, Inc. | Earnings (BMO, FQ Oct/2026) | 2026-11-24 | (E) | $210B | Nasdaq calendar |
| ADSK | Autodesk, Inc. | Earnings (n/s, FQ Oct/2026) | 2026-11-24 | (E) | $51B | Nasdaq calendar |
| DE | Deere & Company | Earnings (BMO, FQ Oct/2026) | 2026-11-25 | (E) | $178B | Nasdaq calendar |
| CRWD | CrowdStrike Holdings, Inc. [A-queue] | Earnings (n/s, FQ Oct/2026) | 2026-12-01 | (E) | $267B | Nasdaq calendar |
| MRVL | Marvell Technology, Inc. [A-queue] | Earnings (n/s, FQ Oct/2026) | 2026-12-01 | (E) | $191B | Nasdaq calendar |
| BNS | Bank of Nova Scotia (The) | Earnings (n/s, FQ Oct/2026) | 2026-12-01 | (E) | $117B | Nasdaq calendar |
| NTAP | NetApp, Inc. [A-queue] | Earnings (AMC, FQ Oct/2026) | 2026-12-01 | (E) | $43B | Nasdaq calendar; **Δ vs W43 2026-11-24** |
| OKTA | Okta, Inc. [A-queue] | Earnings (n/s, FQ Oct/2026) | 2026-12-01 | (E) | $39B | Nasdaq calendar |
| RY | Royal Bank Of Canada | Earnings (n/s, FQ Oct/2026) | 2026-12-02 | (E) | $285B | Nasdaq calendar |
| CRM | Salesforce, Inc. [A-queue] | Earnings (n/s, FQ Oct/2026) | 2026-12-02 | (E) | $190B | Nasdaq calendar |
| SNOW | Snowflake Inc. [A-queue] | Earnings (n/s, FQ Oct/2026) | 2026-12-02 | (E) | $117B | Nasdaq calendar |
| TD | Toronto Dominion Bank (The) | Earnings (n/s, FQ Oct/2026) | 2026-12-03 | (E) | $208B | Nasdaq calendar |
| BMO | Bank Of Montreal | Earnings (n/s, FQ Oct/2026) | 2026-12-03 | (E) | $122B | Nasdaq calendar |
| CM | Canadian Imperial Bank of Commerce | Earnings (n/s, FQ Oct/2026) | 2026-12-03 | (E) | $108B | Nasdaq calendar |
| HPE | Hewlett Packard Enterprise Company [A-queue] | Earnings (n/s, FQ Oct/2026) | 2026-12-03 | (E) | $78B | Nasdaq calendar |
| AZO | AutoZone, Inc. | Earnings (n/s, FQ Nov/2026) | 2026-12-08 | (E) | $50B | Nasdaq calendar |
| ORCL | Oracle Corporation [A-queue] | Earnings (n/s, FQ Nov/2026) | 2026-12-09 | (E) | $422B | Nasdaq calendar |
| ADBE | Adobe Inc. [A-queue] | Earnings (n/s, FQ Nov/2026) | 2026-12-09 | (E) | $97B | Nasdaq calendar; FMP agrees (EPS est 6.32, rev est $6.83B) |
| SNPS | Synopsys, Inc. | Earnings (n/s, FQ Oct/2026) | 2026-12-09 | (E) | $94B | Nasdaq calendar |
| AVGO | Broadcom Inc. [A-queue] | Earnings (n/s, FQ Oct/2026) | 2026-12-10 | (E) | $1,647B | Nasdaq calendar; **Δ vs W43 aggregator-only 2026-12-09 (E); Nasdaq now lists 12-10** |
| COST | Costco Wholesale Corporation | Earnings (n/s, FQ Nov/2026) | 2026-12-10 | (E) | $441B | Nasdaq calendar; FMP agrees (EPS est 4.93, rev est $74.25B); window end rolled 12-09 → 12-16 so COST (W43 1A.2 FMP row 12-10) is now inside the C window; date unchanged |
| MU | Micron Technology, Inc. [A-queue] | Earnings (n/s, FQ Nov/2026) | 2026-12-16 | (E) | $1,057B | Nasdaq calendar; **Δ vs W43 aggregator 2026-12-23 (E); Nasdaq now lists 12-16**; searched 2026-11-01, no issuer notice found (calendar sites only) |

Aggregator-only A-queue rows: none left outside Nasdaq (AVGO, MU and ORCL are now on the Nasdaq calendar inside the window: AVGO 12-10 Δ vs aggregator 12-09; MU 12-16 Δ vs aggregator 12-23; ORCL 12-09 unchanged).

**A-queue names with NO forward date in this window:** IBM, META, JPM (printed/outside; next print in 1A.3).

**Full enumeration of the remainder, by session** — Nasdaq ≥ $2B reporters NOT in the detail table, ordered by market cap within the day; ᵇ = before open, ᵃ = after close, no mark = time not supplied. All (E).

- **2026-11-02** (77): IDXXᵇ ELᵇ PEGᵇ ONᵃ RYAAYᵇ FOXᵇ FOXAᵇ ROKUᵃ Lᵇ TSEMᵇ PSᵃ SBACᵃ VNOMᵃ PKX CRBGᵃ CHKPᵇ EQHᵃ NBIXᵃ LSCCᵃ TEMᵇ JAZZᵃ CNAᵇ DOCᵃ SMMT BWXTᵃ FNᵃ UDRᵃ GRABᵃ BMRNᵃ CLXᵃ AMG MTCHᵃ KRYSᵇ AEISᵃ HNGEᵃ RHPᵃ ALSNᵃ VOYAᵃ TGTX JANᵃ AXSMᵇ RIGᵃ VALᵃ MSAᵃ TBBBᵃ VNOᵃ WAYᵃ CEᵃ CHHᵇ SBRAᵃ OGSᵃ CRCᵃ TVTXᵃ CRGYᵃ KTB PAMᵃ PAYᵃ LQDA CBTᵃ OTTRᵃ TGS CIFRᵇ XENE IRTᵃ EROᵃ BSMᵃ LIFEᵃ BCCᵃ ALM PPLIᵃ AKRᵇ VVXᵃ RNWᵃ ADEAᵃ CALXᵃ UFPT INSPᵃ
- **2026-11-03** (138): TEVAᵇ KDPᵇ WATᵇ XYZᵃ AIGᵃ YUMᵇ SYYᵇ PRUᵃ ADMᵇ FTSᵇ PHGᵇ CPNGᵃ EXPDᵇ FISVᵇ IFFᵃ BNTXᵇ OVVᵃ BRᵇ DDᵇ RVTYᵇ TOSTᵃ ZBRAᵇ LDOSᵇ DTᵇ BALLᵇ TLNᵇ YUMCᵇ ULSᵇ UNMᵃ AIZᵃ ITᵇ OHIᵃ EMBJ SWKSᵃ PNWᵇ FMSᵇ AFGᵃ WTRGᵃ DOCNᵇ JKHYᵃ RRXᵇ AES TXᵃ SYRE MDGLᵇ PCVX PAYPᵃ HLᵃ HSICᵇ ENLTᵇ SMᵃ CORTᵃ PCORᵃ IBRX APTVᵇ JXNᵃ PACSᵃ ALKSᵇ AMRXᵇ SLAB MTDRᵃ MODᵃ ADTᵇ RYTMᵇ DUOLᵃ PJTᵇ NPOᵇ TFPMᵃ MOSᵃ XMTRᵇ SSRMᵃ JBTMᵇ GXOᵃ CVIᵇ MCYᵃ AROCᵇ MIRMᵃ VRNSᵃ HGTYᵇ STVNᵇ ECGᵃ SGHCᵃ SHCᵇ FBINᵃ RRRᵃ LPXᵇ BETAᵇ HLNEᵇ CNKᵇ BWIN SKYᵃ VSNTᵇ TACᵇ CRVL PRIMᵃ SPHR VACᵃ FRSHᵃ CARᵃ SRADᵇ TNGX GEFᵃ GEF.Bᵃ IEPᵇ SEB PARRᵃ TARS HNIᵇ ASHᵃ KNFᵇ SDRLᵃ IPGPᵇ KAI ATRCᵃ IDYA DNLIᵃ HURNᵃ BEAM MZTIᵇ TALOᵃ DRHᵃ MARA EROKᵃ GPKᵇ LBTYAᵇ LBTYBᵇ LBTYKᵇ IOSPᵃ LINDᵇ UPSTᵇ NVTSᵃ LTCᵃ ALMRᵃ FLYWᵃ ADUSᵃ OUSTᵃ AUPH ANDEᵃ
- **2026-11-04** (223): VMRKᵃ COHRᵃ SLFᵃ MDLNᵇ RVMDᵃ MLMᵇ RPRXᵇ TKOᵃ NTRᵃ TSᵃ EXPEᵃ SNᵇ ATOᵃ KHCᵇ CPAYᵃ Qᵇ ESᵃ GFSᵇ UTHRᵇ STEᵃ TPLᵃ AMCRᵃ PRᵃ PTCᵃ CDWᵇ CRCLᵇ RGLDᵃ BEPᵇ FISᵇ WESᵃ ZBHᵇ CWᵃ ITTᵃ APAᵃ CRLᵇ CFᵃ HSTᵃ NWSᵃ NWSAᵃ PAASᵃ Wᵇ SWKᵇ PFGCᵇ FICOᵃ TRMBᵇ SITMᵃ MKSIᵃ CDEᵃ COKEᵃ FLUTᵇ HUBSᵃ FIGᵃ PAYCᵃ WTSᵃ TECH AMHᵃ NYTᵇ UHALᵃ UHAL.Bᵃ ALBᵃ CHYMᵃ PODDᵇ QGENᵃ BIOᵃ BIO.Bᵃ BEPCᵇ CAIᵃ SOLSᵇ CGNXᵃ OCᵇ SNAPᵃ BRKRᵇ KNTKᵃ LLYVA LLYVK CYTKᵃ PRIᵃ WLKᵇ CHRDᵃ VIAVᵃ HUTᵇ NNNᵇ TKRᵇ RALᵇ BROSᵃ AVTᵇ NFGᵃ SOBOᵃ IONS Zᵃ ZGᵃ TRNOᵃ GRALᵃ MGYᵃ VCTRᵃ CAVAᵃ MACᵃ NICEᵇ MATXᵃ SWXᵇ ELFᵃ ACTᵃ BTGᵃ LBᵃ YOUᵇ BKHᵃ MURᵃ MTGᵃ CAMTᵇ KVYOᵃ NXE CRUSᵃ RYNᵃ ORAᵃ OGCᵃ EXPᵇ BLLNᵃ SEIᵃ RELYᵃ TREXᵇ OBDCᵃ RIOTᵇ JOBYᵃ GOLFᵇ MTRNᵇ REYNᵇ LUMNᵃ CIGIᵇ NWEᵃ OPCHᵇ OPLNᵇ RDNᵃ DNTH ESABᵇ SEZLᵃ HCCᵃ VSHᵇ BXSLᵇ ADPTᵃ LIVNᵇ TRMDᵇ OTFᵃ VSECᵃ TPCᵃ CRKᵃ DAVEᵃ SKTᵃ BCOᵇ VCYTᵃ FSLYᵃ LOPEᵃ ARQTᵃ EEᵃ NVSTᵃ AVNTᵇ MSGEᵇ WBIᵃ IPARᵃ PLMRᵃ SMGᵇ ACADᵃ MWAᵃ TNK BATRAᵇ BATRKᵇ CXTᵃ GNWᵃ PKᵃ AWRᵃ NATLᵇ ARISᵃ USLM MGNIᵃ DYN FRPTᵇ AVAᵇ IONDᵃ CWKᵇ CXWᵃ KDᵇ VGNTᵇ PTRNᵃ COTYᵃ GPORᵃ FSMᵃ ARCBᵇ VRDNᵇ MGEE AMCᵃ SII ACHCᵃ AAUC POWIᵃ BTUᵇ ADMAᵃ VECOᵃ NGVTᵃ TTAMᵃ RXRX NAMS HCIᵃ CLOVᵃ VERXᵃ UWMCᵇ PGENᵃ RCUSᵃ ATHMᵇ RAMP KMTᵇ RDW HRMYᵇ SDGRᵃ PRGOᵇ MRVIᵃ LEUᵃ PGNYᵃ BCRXᵇ XNCR ECPGᵃ AMPLᵃ VETᵇ UUUUᵃ VIRᵃ
- **2026-11-05** (214): MTᵇ MCHPᵃ AUᵇ EDᵃ ONCᵇ LYVᵃ CHT KMBᵇ AXONᵃ GMABᵇ IRMᵇ MTDᵃ ZTSᵇ AEEᵃ PBAᵃ ECHO DTEᵇ AFRMᵃ GHᵃ VRSKᵇ RLᵇ TPRᵇ GPNᵇ CIB USFDᵇ VTRSᵇ FWONAᵇ FWONKᵇ EVRGᵇ MTSIᵇ BCEᵇ Uᵇ RGAᵃ SBSᵃ LAMRᵇ JHXᵃ HALOᵃ CGᵇ SOLVᵃ REGᵃ TIGOᵇ IONQᵃ AHRᵃ MAIRᵇ FROGᵃ TXRHᵃ BSYᵇ QXO SUZᵃ ARWᵇ GMEDᵃ GSAT FNFᵃ NVMIᵇ TXGᵃ IRENᵃ WMSᵇ DKNGᵃ CPTᵃ QNTᵃ IAGᵃ OSCRᵇ PTGX PCTYᵃ CTREᵃ VIRTᵇ DBXᵃ LNCᵇ SAROᵃ WYNNᵃ AGᵇ GILᵇ MPᵃ TAPᵇ TAP.Aᵇ CELH COMPᵃ PRMBᵇ EPAMᵇ OTEXᵇ AAOIᵃ AUGOᵃ LNTH Gᵃ LYFTᵃ AAON LOARᵇ INGRᵇ FTDRᵇ DOCSᵃ TFXᵇ BBUCᵇ INSWᵇ OUTᵃ IBPᵇ ACIWᵇ KRMNᵃ HAEᵇ STEPᵃ WTM BGCᵇ MIDDᵇ CONᵃ NSITᵇ NXSTᵇ MAINᵃ LFSTᵇ DFTX VNTᵇ MRXᵇ HASIᵃ MDAᵇ MCᵃ SYNA PRMᵇ CORZᵇ HHHᵃ WKᵃ APLEᵃ MATᵃ NNIᵃ IOVAᵇ CNRᵇ RLAY EWTX ICUIᵃ IRTCᵃ COLDᵇ BILLᵃ MDUᵇ TKC DIODᵃ PLNTᵇ PLSEᵃ USAR LIONᵃ BTEᵃ GEOᵇ IRON AVPTᵃ APPNᵇ FAᵇ AMLX FIGSᵃ LMNDᵇ ACLSᵇ ACMRᵇ CENXᵃ PURRᵃ CELCᵃ WSCᵃ GPGIᵇ SHOOᵇ CPKᵃ ALRMᵃ NMIHᵃ TDCᵃ AGOᵃ FOURᵇ FSKᵇ WRBYᵇ SHAKᵇ SPNTᵃ DNOWᵇ NOGᵃ CARGᵃ NTCTᵇ IMAXᵇ PRVAᵇ FIVNᵃ AAPᵇ FGᵃ DXPE CALY MHᵇ MBX SKWDᵃ LCLNᵇ GRDNᵃ SMRᵃ DCOᵇ ZLABᵇ PLUS BHF PAYOᵇ LCIIᵇ PTONᵇ LPG TMDXᵃ PBHᵇ BKVᵇ TICᵇ HLIOᵃ LASRᵃ GRNDᵃ AGIOᵇ AGMᵃ VERAᵃ VCELᵇ PVLAᵇ CTRIᵇ GCTᵇ IMNM BOBSᵇ DNN NWNᵇ SOUNᵃ NGLᵃ PENNᵇ TRLVᵇ HIMXᵇ SRPTᵃ GENB ZYME
- **2026-11-06** (41): VSTᵇ HMC UI PPLᵇ PAAᵇ BIPᵇ BENᵇ EMAᵇ TU CHTRᵇ FRHC ELANᵇ VSAT KT WULFᵇ FLRᵇ VEONᵇ ESNTᵇ PAGPᵇ COGT OKLOᵇ STWDᵇ BH BH.A DKᵇ CLMTᵇ AQN TDS ATMUᵇ NHC DKLᵇ KYIVᵇ AD BKDᵇ SHOᵇ UAᵇ UAAᵇ TILEᵇ DV UTZᵇ AMRᵇ
- **2026-11-09** (52): FERGᵇ IXᵇ SKYDᵃ RKLBᵃ BAPᵃ ROIVᵇ NRGᵇ BEKE KSPIᵇ ASTSᵃ RBAᵇ SGIᵇ CNHᵇ JBSᵃ EQXᵃ ONTOᵃ SANMᵃ TIMBᵃ LINEᵃ ZETAᵃ PRAXᵇ QLYSᵃ HIMSᵃ TTDᵃ IMVTᵇ HRBᵃ BLTE RDNTᵇ CWSTᵃ NOVTᵃ IFSᵃ CWENᵃ CRSP KGSᵇ TEO EQPTᵃ TDW ABCLᵃ MNDYᵇ DHTᵃ OGN ACHRᵃ NHIᵃ ASST SGRY VIAᵇ WTTRᵇ GCMGᵇ CSQRᵃ CLDX WGSᵃ SEPN
- **2026-11-10** (29): SEᵇ VGᵇ VODᵇ ALCᵃ ECᵃ CRWVᵃ ONONᵇ VIVᵃ DOX MANE SRRKᵇ MRCYᵃ ALHᵇ ATATᵇ QBTSᵇ LEGNᵇ RGTIᵃ PHI FLYᵃ WIXᵇ REZIᵃ ATROᵃ EXKᵇ STUBᵃ IMOS SONOᵃ BTDRᵇ NNᵃ HSAIᵇ
- **2026-11-11** (29): VYLRᵃ FNVᵃ GIBᵇ ASND TTEKᵃ CAEᵃ CTVAᵃ UGP ORKA ORᵃ ENSᵃ ICLᵇ ERAS ARX ECOᵃ AYAᵇ ELVN DGIIᵃ TGB IHS SA RUMᵇ FRVO PHVS BGSIᵇ PLGOᵃ INFQ SLS AADXᵇ
- **2026-11-12** (34): JD BSP CBRSᵃ BNT TWSTᵇ HBMᵇ FPSᵇ STNᵃ ELPCᵃ ANDGᵃ KOD NIQᵇ OCTVᵇ MBGLᵇ AVAL BILI FIGRᵇ HTFLᵃ ENHA MWHᵇ XE LGNᵇ DPCᵇ DLOᵃ ONDSᵇ SKE PBLS YETIᵇ CLBTᵇ AVAHᵇ LFTOᵃ LUNR NESR ABSIᵇ
- **2026-11-13** (9): KB WF LTM CGON CIG NORD XXI LPL PPTA
- **2026-11-16** (11): BIDUᵇ TCOM TSNᵇ ARMKᵇ HTHT XPEV ACMᵃ XP BRC DAC PAGSᵃ
- **2026-11-17** (14): ESLTᵇ ASᵇ SQM ZTOᵃ FUTU TMEᵇ KLARᵇ BZ POWL DLBᵃ SRᵇ GBDCᵃ SBLK NMM
- **2026-11-18** (17): Pᵃ VIK WSM WWDᵃ UGIᵃ DY GLBE CPAᵃ NJRᵃ GLNGᵇ GFF GDS BLSHᵇ KLIC HPᵃ JOYY PONYᵇ
- **2026-11-19** (17): CPRT WMGᵇ ESTC YMMᵇ GAP ESEᵃ VIPS ROAD BBWI VVVᵇ POSTᵃ ZIM MMSᵇ MNSO BULL CDLR DAO
- **2026-11-20** (7): BJᵇ FRO MOG.A MOG.B IESC VFS BKE
- **2026-11-23** (10): ZM SYM Jᵃ SMTC SNEX AMTMᵃ BWLPᵇ CAAP CENT CENTA
- **2026-11-24** (18): WDAY ZS HPQ BBYᵇ NTNX BURL SJM DKS ARWR NIO URBN ANF GGAL AMBA KSSᵇ KCᵇ BBAR CLSK
- **2026-11-25** (4): LI CMBT BMA STDN
- **2026-11-27** (1): CHA
- **2026-12-01** (6): GTLB BOX SIG AEO UNFI ASAN
- **2026-12-02** (11): DLTR FIVE GWRE HQY DSGX PATH M PVH THO KEN NCNO
- **2026-12-03** (19): KR DG ULTAᵃ RBRK IOT DOCU BF.A BF.B HRL COO DCI S TTAN SAIC AGX DOO WLY WLYB IDT
- **2026-12-04** (1): VSXY
- **2026-12-07** (4): CRDO MDB HAFN VSTS
- **2026-12-08** (10): CASY SAIL GME CNM AVAV CPB OLLI BRZE KFY ASO
- **2026-12-09** (5): NDSN CHWY MTN PL UEC
- **2026-12-10** (5): CIEN LULU MANU FIZZ RH
- **2026-12-14** (1): TOL
- **2026-12-15** (3): LEN LEN.B WOR
- **2026-12-16** (6): JBL GIS TTC ABM WS EPAC

Check: detail 135 + remainder 1016 = 1151 forward rows (Nasdaq forward 1151).

### 1A.2 — Earnings, 2026-12-17 → dense horizon 2026-12-18

| Ticker | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| NKE | Nike (FQ2) | Earnings | 2026-12-17 | (E) | FMP (EPS est 0.34, rev est $11.13B); not in Nasdaq pull (window ends 12-16). Unchanged vs W43 |
| CCL | Carnival (Q4) | Earnings | 2026-12-18 | (E) | FMP (EPS est 0.22, rev est $6.47B) — terminal row of the dense horizon, unchanged for a FIFTH week |

The C window end moved 12-09 → 12-16, so COST (12-10; FMP + Nasdaq agree), AVGO (12-10), MU (12-16) moved from 1A.2/1A.3 into 1A.1. This band is now FMP-only for NKE and CCL. 12-17 and 12-18 were not fetched from Nasdaq (outside the pull). Effective confirmed-earnings horizon 2026-12-18 = 47 days from 2026-11-01.

### 1A.3 — Earnings, 2026-12-19 → 2027-05-01

Coverage gap, not absence of events: FMP (4 chunked calls, 2026-11-01) returns nothing 2026-12-19 → 2027-01-10 and only FDX 03-25 / RKT 02-25 after 2027-02-22. Window end rolled 04-25 → 05-01; no vendor or sourced row falls 04-26..05-01 except MRK (below). Dense-horizon terminal row remains CCL 2026-12-18 (unchanged). Rows below are FMP unless stated; all (E) except where marked.

| Date | Tickers (FMP) | Δ vs W43 |
|---|---|---|
| 2027-01-11 | TLRY | unchanged |
| 2027-01-12 | DAL | unchanged |
| 2027-01-14 | C · JPM · WFC | unchanged |
| 2027-01-15 | BAC | unchanged |
| 2027-01-19 | GS · NFLX · UAL | unchanged |
| 2027-01-20 | JNJ · UNH | unchanged |
| 2027-01-21 | GE · TSM | unchanged |
| 2027-01-26 | AAL · BA · GM · HCA | BA new; HCA new |
| 2027-01-27 | META · MSFT · SBUX · T · TSLA | SBUX new; MSFT new |
| 2027-01-28 | INTC · V | INTC new; V new |
| 2027-01-29 | CVX · SOFI · VZ · XOM | CVX new; XOM new; SOFI new; VZ new |
| 2027-02-02 | FDX · PEP · PYPL | PYPL new |
| 2027-02-03 | ABBV · GOOGL | ABBV new |
| 2027-02-04 | AMZN · CARR · LMT · MGM · NOK · RBLX · SIRI | AMZN new; CARR new; RBLX new; SIRI new; MGM new |
| 2027-02-09 | F · HOOD | F new; HOOD new |
| 2027-02-11 | COIN · PINS · RIVN | COIN new; PINS new; RIVN 2027-02-25 → 2027-02-11 |
| 2027-02-18 | ETSY | ETSY new |
| 2027-02-25 | RKT | RKT new |
| 2027-03-25 | FDX | FDX 2027-02-02 → 2027-03-25 |

Notes: RIVN printed Q3 on 2026-10-29 (FMP actual); the W43 row 'RIVN 2027-02-25' is superseded — FMP now lists RIVN 2027-02-11 and RKT 2027-02-25. The 'new' rows are the names that printed 10-26..10-30 (MSFT, AMZN, GOOGL via FMP, INTC, V, XOM, CVX, ABBV, SBUX, BA, HCA etc.) whose next-quarter date FMP now projects; they are (E). GOOGL 2027-02-03 now FMP-sourced, agreeing with the W43 WSH snippet. FMP chunk 2 header says 45 rows, the row list parses to 46 (header/row-count discrepancy in the shared file; not investigated).

**Per-name (E) tails carried from W43 (not in FMP; not re-sourced this run):**

| Ticker | Event | Date | Tag | Source |
|---|---|---|---|---|
| MRK | Q4 2026 call | 2027-02-02 | (C) | merck.com (carried from W43, not re-read). NOTE: FMP shows no MRK row; keep as carried only |
| MRK | Q1 2027 call | 2027-04-29 | (C) | merck.com (carried from W43; now INSIDE the window since the end moved to 05-01); not re-read |
| NVDA | FQ4 FY27 | ~2027-02-24 | (E) | days.to / WSH inferred (carried) |
| AVGO | FQ1 FY27 | ~2027-03-03 | (E) | days.to projection (carried) |
| ORCL | FQ3 FY27 | ~2027-03-10 | (E) | days.to projection (carried) |
| MU | FQ2 FY27 | ~2027-03-17 | (E) | days.to + WSH 'INFERRED' (carried); note MU FQ1 now 12-16 on Nasdaq (was 12-23), so the March projection is likely about a week earlier than carried — Δ unverified |
| FDX | FedEx | 2027-03-25 | (T) | FMP; suspect row (see 1A.9 W43 item 14); not relied on |

**Struck:** MU 2026-12-23 (aggregator) — superseded by Nasdaq 2026-12-16 (E).

Not established (no reachable source states a date after the next print): AAPL, CRWD, NTAP, OKTA, SNOW, HPE, DELL, TGT, WMT, HD, ADBE, COST, AMAT, CSCO, QCOM, SMCI, NBIS, DDOG, TTWO, PANW, CAT, GEV, LLY, VRTX, AMD, AKAM, IBM, NOW, PLTR, UBER, CRM, MRVL, INTU, FSLR, COP. (MSFT, AMZN, GOOGL, INTC, XOM, CVX, META, JPM now carry FMP (E) dates and are removed from this list.) Per-name re-sourcing this run searched only the near-window names listed in 1B.2; no search for post-print dates.

### Printed this week (2026-10-26 → 2026-10-30)

A-queue and ≥ $50B names whose Nasdaq date fell 10-26 → 10-30, with FMP actuals where the FMP subset has them (EPS actual vs est; revenue actual vs est). These drop out of the forward calendar. A calendar date is a schedule, not evidence of a print; 'FMP actual' rows are evidence of a print, 'per Nasdaq calendar' rows are not independently evidenced here (D1 context corroborates: MSFT/GOOGL/AMZN/INTC/NOW/FTNT/LLY/MRK/BMY prints referenced in D1 records 10-28/10-29).

| Ticker | Name | Nasdaq date | A-queue | Mcap | EPS act / est | Rev act / est | Evidence |
|---|---|---|---|---|---|---|---|
| KOF | Coca Cola Femsa S.A.B. de C.V. | 2026-10-26 |  | $194B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| VZ | Verizon Communications Inc. | 2026-10-26 (FMP 2026-10-26) |  | $181B | 1.31 / 1.27 (beat) | $34.31B / $34.77B | FMP actuals row |
| WELL | Welltower Inc. | 2026-10-26 |  | $171B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| CDNS | Cadence Design Systems, Inc. | 2026-10-26 |  | $94B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| NUE | Nucor Corporation | 2026-10-26 |  | $62B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| PSA | Public Storage | 2026-10-26 |  | $59B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| V | Visa Inc. | 2026-10-27 (FMP 2026-10-27) |  | $734B | 3.48 / 3.44 (beat) | $12.14B / $12.09B | FMP actuals row |
| KO | Coca-Cola Company (The) | 2026-10-27 (FMP 2026-10-27) |  | $399B | 0.91 / 0.881 (beat) | $13.40B / $12.92B | FMP actuals row |
| NVS | Novartis AG | 2026-10-27 |  | $307B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| HSBC | HSBC Holdings plc | 2026-10-27 |  | $297B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| STX | Seagate Technology Holdings PLC | 2026-10-27 |  | $160B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| BA | Boeing Company (The) | 2026-10-27 (FMP 2026-10-27) |  | $137B | -0.34 / -0.25495 (miss) | $24.19B / $23.95B | FMP actuals row |
| SPGI | S&P Global Inc. | 2026-10-27 |  | $134B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| GLW | Corning Incorporated | 2026-10-27 |  | $111B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| HCA | HCA Healthcare, Inc. | 2026-10-27 (FMP 2026-10-27) |  | $104B | 7.22 / 6.65 (beat) | $19.85B / $19.33B | FMP actuals row |
| JCI | Johnson Controls International plc | 2026-10-27 |  | $96B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| FCX | Freeport-McMoran, Inc. | 2026-10-27 |  | $95B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| WM | Waste Management, Inc. | 2026-10-27 |  | $92B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| UPS | United Parcel Service, Inc. | 2026-10-27 |  | $91B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| AMT | American Tower Corporation (REIT) | 2026-10-27 |  | $86B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| ECL | Ecolab Inc. | 2026-10-27 |  | $84B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| RCL | Royal Caribbean Cruises Ltd. | 2026-10-27 |  | $83B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| HOOD | Robinhood Markets, Inc. | 2026-10-27 (FMP 2026-10-27) |  | $82B | 0.6 / 0.558 (beat) | $1.42B / $1.44B | FMP actuals row |
| ITW | Illinois Tool Works Inc. | 2026-10-27 |  | $80B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| SHW | Sherwin-Williams Company (The) | 2026-10-27 |  | $80B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| HLT | Hilton Worldwide Holdings Inc. | 2026-10-27 |  | $79B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| NXPI | NXP Semiconductors N.V. | 2026-10-27 |  | $67B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| OKE | ONEOK, Inc. | 2026-10-27 |  | $60B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| BKR | Baker Hughes Company | 2026-10-27 |  | $54B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| PCAR | PACCAR Inc. | 2026-10-27 |  | $54B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| MSFT | Microsoft Corporation | 2026-10-28 (FMP 2026-10-28) | Y | $3,937B | 4.89 / 4.72 (beat) | $92.28B / $90.62B | FMP actuals row |
| GOOG | Alphabet Inc. | 2026-10-28 |  | $3,489B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| GOOGL | Alphabet Inc. | 2026-10-28 (FMP 2026-10-28) | Y | $3,489B | 2.12 / 3.02 (miss) | $127.58B / $127.96B | FMP actuals row |
| SKHY | SK hynix Inc. | 2026-10-28 |  | $1,181B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| GEV | GE Vernova Inc. | 2026-10-28 | Y | $235B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| KLAC | KLA Corporation  | 2026-10-28 |  | $218B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| APH | Amphenol Corporation | 2026-10-28 |  | $202B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| SAN | Banco Santander, S.A. | 2026-10-28 |  | $167B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| TMUS | T-Mobile US, Inc. | 2026-10-28 |  | $156B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| UBS | UBS AG | 2026-10-28 |  | $149B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| EQNR | Equinor ASA | 2026-10-28 |  | $119B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| NOW | ServiceNow, Inc. | 2026-10-28 | Y | $114B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| ADP | Automatic Data Processing, Inc. | 2026-10-28 |  | $113B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| PSX | Phillips 66 | 2026-10-28 |  | $107B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| EQIX | Equinix, Inc. | 2026-10-28 |  | $103B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| FTNT | Fortinet, Inc. | 2026-10-28 |  | $102B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| GSK | GSK plc | 2026-10-28 |  | $99B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| VRT | Vertiv Holdings, LLC | 2026-10-28 |  | $95B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| AEM | Agnico Eagle Mines Limited | 2026-10-28 |  | $89B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| CP | Canadian Pacific Kansas City Limited | 2026-10-28 |  | $77B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| CVNA | Carvana Co. | 2026-10-28 |  | $75B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| FDX | FedEx Corporation | 2026-10-28 (FMP 2026-10-28) |  | $72B | 3.74 / 3.34 (beat) | $22.86B / $22.73B | FMP actuals row |
| ORLY | O'Reilly Automotive, Inc. | 2026-10-28 |  | $71B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| AEP | American Electric Power Company, Inc. | 2026-10-28 |  | $70B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| AON | Aon plc | 2026-10-28 |  | $68B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| DB | Deutsche Bank AG | 2026-10-28 |  | $66B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| TEL | TE Connectivity plc | 2026-10-28 |  | $64B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| BSX | Boston Scientific Corporation | 2026-10-28 |  | $62B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| GRMN | Garmin Ltd. | 2026-10-28 |  | $54B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| EBAY | eBay Inc. | 2026-10-28 |  | $54B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| HONA | Honeywell Aerospace Inc. | 2026-10-28 |  | $51B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| AMZN | Amazon.com, Inc. | 2026-10-29 (FMP 2026-10-29) | Y | $2,630B | 1.89 / 1.97 (miss) | $201.94B / $202.22B | FMP actuals row |
| LLY | Eli Lilly and Company | 2026-10-29 | Y | $1,293B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| MA | Mastercard Incorporated | 2026-10-29 |  | $557B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| INTC | Intel Corporation | 2026-10-29 (FMP 2026-10-29) | Y | $487B | 0.52 / 0.4066 (beat) | $16.51B / $16.56B | FMP actuals row |
| MRK | Merck & Company, Inc. | 2026-10-29 | Y | $361B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| CAT | Caterpillar, Inc. | 2026-10-29 | Y | $298B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| SHEL | Shell PLC | 2026-10-29 |  | $292B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| LIN | Linde plc | 2026-10-29 |  | $232B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| TTE | TotalEnergies SE | 2026-10-29 |  | $214B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| GILD | Gilead Sciences, Inc. | 2026-10-29 |  | $205B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| SNDK | Sandisk Corporation | 2026-10-29 |  | $193B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| BUD | Anheuser-Busch Inbev SA | 2026-10-29 |  | $157B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| BBVA | Banco Bilbao Vizcaya Argentaria S.A. | 2026-10-29 |  | $139B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| MO | Altria Group | 2026-10-29 |  | $128B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| BMY | Bristol-Myers Squibb Company | 2026-10-29 |  | $125B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| SBUX | Starbucks Corporation | 2026-10-29 (FMP 2026-10-29) |  | $120B | 0.8 / 0.719 (beat) | $9.14B / $9.22B | FMP actuals row |
| SYK | Stryker Corporation | 2026-10-29 |  | $120B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| ASX | ASE Technology Holding Co., Ltd. | 2026-10-29 |  | $99B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| TT | Trane Technologies plc | 2026-10-29 |  | $95B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| PWR | Quanta Services, Inc. | 2026-10-29 |  | $94B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| ING | ING Group, N.V. | 2026-10-29 |  | $94B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| ICE | Intercontinental Exchange Inc. | 2026-10-29 |  | $92B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| EPD | Enterprise Products Partners L.P. | 2026-10-29 |  | $84B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| HWM | Howmet Aerospace Inc. | 2026-10-29 |  | $82B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| LYG | Lloyds Banking Group Plc | 2026-10-29 |  | $82B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| MDLZ | Mondelez International, Inc. | 2026-10-29 |  | $80B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| DASH | DoorDash, Inc. | 2026-10-29 |  | $78B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| RSG | Republic Services, Inc. | 2026-10-29 |  | $72B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| AJG | Arthur J. Gallagher & Co. | 2026-10-29 |  | $69B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| DLR | Digital Realty Trust, Inc. | 2026-10-29 |  | $68B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| LNG | Cheniere Energy, Inc. | 2026-10-29 |  | $66B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| TAK | Takeda Pharmaceutical Company Limited | 2026-10-29 |  | $63B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| CRH | CRH PLC | 2026-10-29 |  | $60B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| MSTR | Strategy Inc | 2026-10-29 |  | $60B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| MPWR | Monolithic Power Systems, Inc. | 2026-10-29 |  | $59B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| LHX | L3Harris Technologies, Inc. | 2026-10-29 |  | $52B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| FSLR | First Solar, Inc. | 2026-10-29 | Y | $19B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| XOM | ExxonMobil Holdings Corporation | 2026-10-30 (FMP 2026-10-30) | Y | $754B | 4.23 / 4.12 (beat) | $113.16B / $104.89B | FMP actuals row |
| ABBV | AbbVie Inc. | 2026-10-30 (FMP 2026-10-30) |  | $514B | 3.82 / 3.73 (beat) | $17.40B / $17.32B | FMP actuals row |
| CVX | Chevron Corporation | 2026-10-30 (FMP 2026-10-30) | Y | $457B | 5.28 / 4.87 (beat) | $67.80B / $61.82B | FMP actuals row |
| AZN | AstraZeneca PLC | 2026-10-30 |  | $264B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| BP | BP p.l.c. | 2026-10-30 |  | $130B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| SNY | Sanofi | 2026-10-30 |  | $105B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| GD | General Dynamics Corporation | 2026-10-30 |  | $100B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| REGN | Regeneron Pharmaceuticals, Inc. | 2026-10-30 |  | $84B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| CNI | Canadian National Railway Company | 2026-10-30 |  | $75B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| CL | Colgate-Palmolive Company | 2026-10-30 |  | $74B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| NWG | NatWest Group plc | 2026-10-30 |  | $69B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| IMO | Imperial Oil Limited | 2026-10-30 |  | $63B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |
| D | Dominion Energy, Inc. | 2026-10-30 |  | $57B | — | — | printed per Nasdaq calendar; actuals not in FMP subset |

111 names listed; 15 have FMP actuals. FMP also returned actuals for non-listed names (e.g. CARR, COIN, PINS, RBLX, RIVN, RKT, SBUX, SIRI, ETSY, F, FDX, MGM, BA, HOOD, KO, PYPL, SOFI, VZ). FMP EPS 'estimated' is FMP's own consensus and can differ from the vendor consensus the market uses (e.g. GOOGL FMP est 3.02 vs actual 2.12 should be read with caution; D1 records a -12.6% reaction on 10-29, MEASURED in d1_context).

### 1A.4 — Product launches, keynotes, developer events (window 2026-11-01 → 2027-05-01)

Passed/resolved this week (dropped): NVDA GTC Berlin (held 10-20..22); ORCL Oracle AI World 10-25..28 (held; D1 72e9607d: ORCL +10.7% on 10-28 on own events).

| Ticker/Event | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| ADBE | Adobe | Adobe MAX, Miami Beach | 2026-11-10 → 11-12 | (E) carried | not re-verified |
| MSFT | Microsoft | Ignite, Moscone Center, SF (badge/pre-day 11-16) | 2026-11-17 → 11-20 | (E) Δ firmer: Moscone Center event page + 5 listings agree | moscone.com/events/microsoft-ignite-2026 (search 2026-11-01); Microsoft page not fetched |
| TTWO | Take-Two | GTA VI launch | 2026-11-19 | (C) carried | not re-verified this run |
| AMZN | Amazon | AWS re:Invent, Las Vegas (kickoff 11-29) | 2026-11-30 → 12-04 | (E) | govevents/founderpath/xbow/reworked agree (search 2026-11-01); AWS page not fetched |
| NVDA | NVIDIA | GTC Washington DC (Huang keynote 12-01) | 2026-11-30 → 12-03 | (C) carried | nvidia.com/en-us/gtc/dc (W43) |
| GOOGL | Alphabet | Waymo multi-city robotaxi launches | 2026 (year only) | (T) | carried |
| — | broad | CES 2027, Las Vegas Convention Center | 2027-01-06 → 01-09 | (E) | majority of listings (gophotonics, trade.gov, unmannedsystems); CTA page not reached; minority listings say 01-05..08 (press days) |
| — | healthcare broad | J.P. Morgan Healthcare Conference, San Francisco | 2027-01-11 → 01-14 (Δ NEW row) | (E) | event-listing sites (vision life sciences etc.); organizer notes dates unconfirmed; JPM page not reached |
| NVDA | NVIDIA | GTC 2027 San Jose | 2027-03-14 → 03-18 | (C) carried | nvidia.com GTC FAQ (W43) |

### 1A.5 — Analyst and investor days

Passed/resolved (dropped): MRK ESMO oncology event 10-26; CLS Investor Day 10-27 (D1 3b0ca8cf: CLS +12.12% on 10-27 on its print). Marvell investor day was 2026-10-06 (past; not a row).

| Ticker/Event | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| EPAC | Enerpac Tool Group | Investor Day, NYSE | 2026-11-04 | (C) carried | company release 2026-07-27 |
| ENTG | Entegris | Investor Day, NYC 1pm ET | 2026-11-09 | (C) carried | Entegris release 2026-08-26 |
| MH | McGraw Hill | Investor Day, NYC | 2026-11-18 | (E) carried | briefglance only |
| SHC | Sotera Health | Investor Day, NYC | 2026-11-20 | (T) carried | year not shown; unverified |
| NTR | Nutrien | Investor Day, Toronto | 2026-11-30 | (C) carried | Nutrien release 2026-09-23 |
| NU | Nu Holdings | First Investor Day, NYC | 2026-12-08 | (C) re-verified | Nu Holdings release dated 2026-09-02 (international.nubank.com.br), search 2026-11-01 |
| NKE | Nike | Investor day "Fall 2026" | — | (T) carried | |
| UNH | UnitedHealth | Investor conference | ~2026-12 early | (E) carried | |
| JPM | JPMorganChase | Investor Day | 2027-02-22 | (C) carried | not re-fetched |

Δ One sweep search ("investor day Dec 2026 / Jan / Feb 2027") found no NEW announcement in that span beyond NU; a sample, not an enumeration. GlobalFoundries "2026 Investor Day" and L3Harris 2026 Investor Day pages surfaced but their dates were not read: unresolved, not asserted.

### 1A.6 — Regulatory, legal, trade and macro

PDUFA rows mirrored in 1B.3 (window to 12-16 there; this table runs to 2027-05-01). Macro dates marked (C) from bls.gov / federalreserve.gov unless noted.

**Passed/resolved this week (dropped):**
- GSK bepirovirsen (Hibsago): **APPROVED 2026-10-20**, ahead of the 10-26 aggregator date (GSK release via eatg.org copy; HCPLive 2026-10-20; ajmc 10-21). (C-secondary; FDA page not fetched.)
- INO INO-3107 (PDUFA 10-30): **outcome UNRESOLVED**. Two searches and the Inovio IR page (did not render) returned no approval/CRL. Do not assert an outcome.
- FOMC 10-28: HELD, target range 3-3/4 to 4%, IORB 3.90%, vote 10-2 (Cook, Hammack dissented preferring a +25bp hike). Source: federalreserve.gov/newsevents/pressreleases/monetary20261028a.htm (search snippet 2026-11-01; dissent names via secondary summary, admiralmarkets).
- GDP advance Q3 and Sept personal income/PCE: BEA schedule showed 10-29 (one snippet showed 11-04); release not confirmed either way. D1 10-29 session did not cite them. Unresolved.
- MRK Q3 call 10-29: held (D1 014b69e9: XLV +2.40 on LLY/MRK/BMY beats).
- Sun Pharma ILUMYA 10-29: not re-verified, not US-listed; dropped.

| Ticker/Event | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| AGIO | Agios | Mitapivat sNDA PDUFA, sickle cell (priority; accelerated approval; primary pain-crisis endpoint missed significance) | 2026-11-01 (Sun) | (C) goal date; **outcome UNRESOLVED** | Agios release (investor.agios.com/node/19051); no approval/CRL found by search; Agios IR page returned 403 |
| — | OPEC+ (7 members) | Monthly meeting | 2026-11-01 | (C) carried | opec.org 2026-10-04 |
| — | broad | US midterm elections | 2026-11-03 | (C) | statutory |
| — | broad | Personal income & outlays (Sept) | 2026-11-04? | (T) | BEA conflicting snippets (10-29 vs 11-04); see Macro list |
| — | broad | Employment Situation (Oct) | 2026-11-06 | (C) | bls.gov schedule + calendars agree |
| — | broad | CPI (Oct) | 2026-11-10 | (C carried) | bls.gov (W43); financecalendar.com agrees; bls page not re-read |
| — | broad | US-China truce / rare-earth export-control suspension | was 2026-11-10; reported extended to **2027-01-10** | (E) Δ | investinglive "extend Busan trade truce to January 10" + a report dated 2026-09-23; no official USTR/WH/MOFCOM confirmation. W43 row "USTR Sec 301 exclusions expire 11-10" carried, not re-verified |
| BTAI | BioXcel | IGALMI sNDA | 2026-11-14 | struck: BTAIQ PINK, no options (see 1B.3) | |
| CYTK | Cytokinetics | Aficamten label expansion | 2026-11-14 | (E) unverified | Assyro |
| SMMT | Summit | Ivonescimab BLA PDUFA | 2026-11-14 | (C) | Summit release 2026-01-29 (carried) |
| Beren | Beren Therapeutics | Adrabetadex NDA | 2026-11-17 | (E) | Assyro; not listed |
| UNP·NSC | Union Pacific / Norfolk Southern | STB comments due | 2026-11-18 | (C) carried | |
| CAPR | Capricor | Deramiocel BLA (extended) | 2026-11-22 | (C) carried | 8-K 2026-08-24 |
| SVRA | Savara | Molgramostim BLA (extended) | 2026-11-22 | (E) | Assyro + Checkrare |
| — | broad | PCE (Oct) | ~2026-11-25 | (E) carried | single source |
| — | broad | GDP 2nd est. Q3 | 2026-11-25 | (E) carried | BEA per W43 |
| SAN | Sanofi (ADR) | Venglustat NDA PDUFA | 2026-11-25 | (C) carried | Sanofi release 2026-05-28 |
| BBIO | BridgeBio | BBP-418 NDA | 2026-11-27 | (E) | Assyro |
| GSK | GSK (ADR) | Neladalkib NDA (ex-NUVL; GSK closed Nuvalent 2026-07-15) | 2026-11-27 | (C) carried | Nuvalent release 2026-05-27; GSK release |
| ZYD | Zydus (not US-listed) | Saroglitazar | 2026-11-27 | (E) | |
| PYPD | PolyPid | D-PLEX100 NDA | 2026-11-28 | (C) carried | cap likely <$2B |
| VRTX | Vertex | Povetacicept BLA (accelerated, IgAN) | 2026-11-30 | (C) | Vertex release 2026-06-01 (carried) |
| COGT | Cogent | Bezuclastinib + sunitinib GIST NDA (priority) | 2026-11-30 | (C) Δ re-confirmed | Cogent acceptance release (investors.cogentbio.com) + OncLive 2026-05-28; no adcom planned |
| COGT | Cogent | Bezuclastinib NonAdvSM NDA | 2026-12-30 | (C) | Cogent release (per search) |
| RHHBY | Roche (ADR) | Giredestrant adjuvant NDA | 2026-11-30 | (E) | Assyro |
| EQT·RRC | EQT / Range Resources | **Δ NEW** all-stock merger (0.987 EQT per RRC; ~$13B; unanimous boards; close targeted Q1 2027; shareholder votes + regulatory pending, vote dates not yet set) | announced 2026-10-26; close ~Q1 2027 | (C) | Range 8-K/425 and 10-Q (sec.gov, search 2026-11-01); D1 7d029722 (10-26 RRC +17.66) |
| UNP·NSC | Union Pacific / Norfolk Southern | DOJ/USDOT comments | 2026-12-03 | (C) carried | |
| FSLR | First Solar + solar | Sec 232 tariff regime effective | 2026-12-04 | (C) carried, not re-verified | |
| — | broad | Employment Situation (Nov) | 2026-12-04 | (C) | bls.gov / calendars |
| VRTX | Vertex | Journavx sNDA | 2026-12-05 | (T) carried | |
| NU | see 1A.5 | | 2026-12-08 | | |
| — | broad | **FOMC decision + SEP/dot plot** | 2026-12-09 (meeting 12-08/09) | (C) | federalreserve.gov/monetarypolicy/fomccalendars.htm fetched 2026-11-01; "Scheduled", SEP = Yes |
| — | broad | CPI (Nov) | 2026-12-10 | (C) | calendars; bls page not re-read |
| — | broad | US government funding: CR (H.R. 6500) runs to **2026-12-11** | 2026-12-11 | (C-secondary) Δ upgraded from (E) | signed 2026-09-02 per political.org; AACOM; twelve approps bills still unpassed; 2025 had a 43-day lapse |
| VNDA·ANAB | Vanda / AnaptysBio | Imsidolimab BLA | 2026-12-12 | (E) | Assyro (indication not stated on page) |
| CORT | Corcept | Relacorilant NDA | 2026-12-17 | (E) | Assyro |
| — | Deciphera (Ono; not listed) | Tirabrutinib NDA | 2026-12-18 | (E) | Assyro |
| RHHBY | Roche (ADR) | Giredestrant + everolimus NDA | 2026-12-18 | (E) | Assyro |
| — | Camurus (not US-listed) | Oclaiz NDA | 2026-12-18 | (E) | Assyro |
| — | Hansa (not US-listed) | Imlifidase BLA | 2026-12-19 | (E) | Assyro |
| MLYS | Mineralys | Lorundrostat NDA | 2026-12-22 | (C) carried | release 2026-05-06; also listed on Dec aggregator |
| — | broad | GDP 3rd est. Q3 | 2026-12-23 | (E) carried | |
| ACLX·GILD | Arcellx / Gilead | Anito-cel BLA | 2026-12-23 | (E) | Assyro; "announcement of 2026-02-23" per search |
| VTRS | Viatris | MR-107A-02 NDA | 2026-12-27 | (E) | Assyro |
| PRAX | Praxis | Relutrigine PDUFA (extended) | 2026-12-27 | (C) carried | 8-K 2026-06-29 |
| — | Saol (not listed) | SL1009 NDA | 2026-12-30 | (E) | |
| BA | Boeing | FAA 737 MAX 10 cert "by year-end" | — | (T) carried | |
| — | broad | Employment Situation (Dec) / CPI (Dec) | 2027-01-08 / 2027-01-13 | (C) carried | bls.gov |
| DYN | Dyne | Z-rostudirsen BLA (priority) | 2027-01-21 | (C) carried | |
| — | broad | **FOMC decision** (no SEP) | 2027-01-27 (meeting 01-26/27) | (C-tentative) | federalreserve.gov: 2027 dates "tentative until confirmed at the preceding meeting" |
| V | Visa | DOJ debit case fact-discovery deadline | 2027-01-29 | (E) carried | |
| PHAR | Pharming | Joenja lower-dose sNDA | 2027-01-30 | (C) carried | Assyro "Decided" unresolved |
| — | broad | Employment (Jan) / CPI (Jan) | 2027-02-05 / 02-11 | (C) carried | |
| UNP·NSC | UNP / NSC | STB responses due | 2027-02-16 | (C) carried | |
| BMRN | BioMarin | VOXZOGO full approval | 2027-02-28 | (C) carried | |
| SRPT | Sarepta | AMONDYS 45 / VYONDYS 53 sNDAs | 2027-02-28 | (C) carried | |
| LYV | Live Nation | DOJ/states remedies | ~2027-02 | (E) carried | |
| WBD | Warner Bros Discovery | Antitrust trial begins | 2027-03-02 | (C) carried | |
| EXEL | Exelixis | Zanzalintinib + atezolizumab mCRC PDUFA (extended from 12-03; an aggregator still shows 12-03) | 2027-03-03 | (C) carried | OncLive/Exelixis (W43) |
| — | broad | Employment (Feb) / CPI (Feb) | 2027-03-05 / 03-10 | (C) carried | |
| — | broad | **FOMC decision + SEP** | 2027-03-17 (meeting 03-16/17) | (C-tentative) | federalreserve.gov |
| — | broad | FTC v. Amazon trial | ~2027-03-29 | (E) carried | |
| HRMY | Harmony | Pitolisant GR PDUFA | 2027-04-01 | (E) carried | |
| — | broad | Employment (Mar) / CPI (Mar) | 2027-04-02 / 04-13 | (C) carried | |
| — | broad | **FOMC decision** (no SEP) | 2027-04-28 (meeting 04-27/28) | (C-tentative) Δ now INSIDE the A window (ends 05-01) | federalreserve.gov |
| KMB·KVUE | Kimberly-Clark / Kenvue | Merger outside date extended to 2027-05-03 (W43 note) | 2027-05-03 | (E) carried | just outside window |

Tariff / legal note (Δ): Supreme Court struck down IEEPA tariffs (Learning Resources v. Trump, Feb 2026); Section 122 10% surcharge (effective 2026-02-24, 150 days to ~07-24) was itself held unauthorized (May 2026 per gtlaw) and has lapsed; CBP IEEPA refund phase for finally-liquidated entries opened 2026-10-06 (477 declarations, >425k entries, ~$11.4B capacity, per one Oct-8 guide, beancount.io, secondary). Section 232 semiconductor tariff 25% (effective 2026-01-15) stands; Commerce review was due 2026-07-01 (outcome not confirmed); Section 301 tariffs on Chinese semiconductors scheduled 2027-06-23 (outside window). No dated Nov/Dec 2026 Section 232 deadline found (searches are samples, not proof of absence). The FSLR 12-04 Sec 232 row remains unverified.

### 1A.7 — Restructuring, M&A and structural

D1 development titles since 10-26 (reused, not re-searched): SGRY take-private (10-26, +47.62%); RRC/EQT merger (10-26, +17.66%); ADT deal (10-29, +33.2%); Anthropic S-1 (cb06c3e0/56a602d2: AI/semis rally 10-26..27); SpaceX wireless (XLC -1.57% 10-26); UNF FTC suit report (10-27); BHC +28.8, PRCH +28.2 (10-29, drivers not read here).

| Ticker/Event | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| EQT·RRC | EQT / Range | All-stock merger; close Q1 2027 | ann. 2026-10-26 | (C) | see 1A.6 |
| SGRY | Surgery Partners | Take-private (D1) | ann. ~2026-10-26 | (C per D1; terms not read) | D1 7d029722 |
| ADT | ADT | Deal (D1) | ~2026-10-29 | terms not read | D1 b1e61b9c |
| — | Anthropic | IPO: confidential draft S-1 (2026-06-01); one source (tech-insider.org) claims public S-1 filed 2026-10-26, Nasdaq "ANT"; **uncorroborated**. D1 cites an "Anthropic S-1" as sector driver 10-26/27. Pricing date unknown. | TBD | (T) Δ | futuresearch/engadget/WUNC (June); D1 cb06c3e0; check EDGAR |
| PCRX·VTRS | Pacira / Viatris | $36.50 cash tender, ~$1.65B; closing "by end of 2026" | ann. 2026-10-08; close by ~2026-12-31 | (C) Δ close timing | Viatris 8-K (sec.gov) via search |
| PTC·Schneider; OPCH·CD&R/McKesson | | close undated | | carried, not re-verified (search returned only VTRS) | |
| (other W43 carried items) | ON·SYNA; UBER/ezCater; CMG·SBUX (T); ORCL/OpenAI (T); CVX·HESM; WDAY (T); CAT Fabick; SWKS·QRVO; KMB·KVUE; TECK; CTVA Vylor spin (Q4); Nasdaq-100 recon mid-Dec (E); S&P Q4 rebalance 2026-12-18 (E); DG CEO transition 2027-01-01; S&P Q1 rebalance 2027-03-19 (E) | | | carried unchanged | W43 |
| IONQ, CCC, T/VZ/TMUS spectrum, CRWV, CIFR, FRMI·AMD, DELL/HPE/NTAP downgrades | | | Oct 9-14 | carried (past events, context only; may be dropped) | W43 |

### 1A.8 — Universe rails (carried, dated)

**Market-cap rail (>= $2B).** Inside the C window the rail is Nasdaq's own `marketCap` field (every one of the 1,151 forward rows is ≥ $2B by construction; smallest A-queue name in window AKAM $14B, FSLR $19B printed). Prior direct measurements are CARRIED, not re-measured: 2026-10-04 (61 names, 0 FAIL, smallest AAL $8.57B, AKAM $15.84B, FSLR $18.77B) and 2026-10-09 (50 vendor-calendar names via `company/batch-market-cap`, 0 FAIL, smallest RIOT $6.39B). Data is now 28 and 23 days old; single-digit to low-double-digit cap moves are far from any 2x floor gap. **FAIL the cap floor, A-ineligible (carried):** TLRY, LCID, FUBO. **ADR rail (carried):** TSM, NOK, SONY, BILI, BIDU, BABA, NIO, GSK, SAN, RHHBY are A-ineligible. **New/unmeasured names this cycle:** EPAC (12-16, Nasdaq cap ~$2B boundary), RKT and other FMP rows beyond the window — cap UNMEASURED.

### 1A.9 — Rows struck, rejected or corrected this cycle (earnings only)

1. ~~All 2026-10-26 → 10-30 rows~~ — elapsed; moved to 'Printed this week'.
2. **Δ NVDA 2026-11-18 (E) → 2026-11-17 (C)** — NVIDIA release 'Sets Conference Call for Third-Quarter Financial Results' (call Tue 11-17 2:00 pm PT); FMP and Nasdaq now agree on 11-17.
3. **Δ NTAP 2026-11-24 → 2026-12-01 (E)** — Nasdaq flip-flop (W42 12-01, W43 11-24, now 12-01 with AMC time supplied); no issuer notice searched.
4. **Δ MU 2026-12-23 (aggregator) → 2026-12-16 (Nasdaq, E)**; **Δ AVGO 2026-12-09 (aggregator) → 2026-12-10 (Nasdaq, E)**; both enter the C window as the window end rolled to 12-16.
5. **Δ other date moves vs W43 (Nasdaq):** BIDU 11-17 → 11-16; CEG 11-06 → 11-09; KEYS 11-23 → 11-19; DASH 11-04 → 10-29, DB 11-04 → 10-28, EQNR 11-04 → 10-28 (these three now in the printed week, early vs W43 projections).
6. **A-queue date confirmations upgraded (E) → (C) this run:** NVDA, ANET, QCOM, TTWO, SMCI, AMAT, COP (see 1B.2).
7. **Searched, still NOT issuer-confirmed:** CSCO 11-11, PANW 11-18, HD 11-17, NBIS 11-10 (Nasdaq; calendar sites say 11-10/11-11), DELL 11-24, INTU 11-19, MU 12-16. HD: calendar sites list 11-17 as expected, not formally confirmed.
8. Disney's date: calendar sites list 11-11/11-12 (estimates); the issuer's own 2026-10-12 notice says Tue 11-17 (matches Nasdaq/FMP).
9. FMP-only names absent from Nasdaq inside the window (carried shape): FUBO 11-17, LCID 11-09, ET 11-03. FMP names beyond the Nasdaq pull (CCL, NKE, and the 2027 rows) are not 'absent' — outside the pull. No FMP in-window date disagrees with Nasdaq.

### 1A.10 — Names with NO firm forward earnings date

**Newly (C) this run:** NVDA 11-17, ANET 11-03, QCOM 11-04, TTWO 11-09, SMCI 11-03, AMAT 11-12, COP 11-05, PFE 11-03, DIS 11-17, SHOP 11-03.

**STILL NO ISSUER NOTICE (searched 2026-11-01):** CSCO (FQ1; last year's notice came 11-03 for 11-12; Nasdaq 11-11 n/s), PANW (last year's notice 11-04 for 11-19; Nasdaq 11-18 n/s), HD (Nasdaq 11-17 BMO; calendar sites only), NBIS (Nasdaq 11-10; calendar sites 11-10/11-11; last year's notice came 10-22), DELL (Nasdaq 11-24; calendar site projection), INTU (last year's notice late Oct for 11-20; Nasdaq 11-19), MU (Nasdaq/WSH/days.to 12-16, inferred). Not searched this run (carried as (E), no notice found W43): CRWD, SNOW, HPE, OKTA, MRVL, CRM, ORCL, AVGO, ADBE, COST, NTAP, DOCU.
CRM, INTU, MRVL: as in W43 — no notice; early-Dec (CRM, MRVL) and late-Nov (INTU) INFERRED from history; Nasdaq now says CRM 12-02, MRVL 12-01, INTU 11-19 (all n/s).
AAPL/MSFT/AMZN/GOOGL Q4 CY2026: no issuer dates; FMP (E) gives MSFT 2027-01-27, AMZN 2027-02-04, GOOGL 2027-02-03; AAPL none.

### 1A.11 — Liquidity rail (30-day ADV >= $10M), carried

CARRIED from the 2026-10-04 measurement (IBKR regular-session daily bars, 2026-08-21 → 2026-10-02): 61 of 61 cleared; lowest VRTX $222.0M (~22x floor). NOT re-measured by this sub-agent (now 28 days old). Names beyond that list (UAL, NFLX, GE, GM, LMT, CLS, NU, ENTG, EPAC, SHC, MH, NTR, ALAB, ROK, A, RKT) are UNMEASURED for ADV; ≥ $10M is INFERRED for large caps, unknown for EPAC/SHC/MH.

## PART 1B — Strategy C universe, 45-day window (2026-11-01 → 2026-12-16)

C qualifying types only: earnings (company IR), FDA PDUFA, FOMC. No interpretation. The C window is 2026-11-01 → 2026-12-16 (run date + 45 days, same convention as W43); the 12-08/09 FOMC sits inside. Tags: (C) confirmed by issuer/authority, (E) estimated, (T) tentative. 'carried' = read last cycle and not re-read this run.

### 1B.1 — FOMC

| Event | Meeting | Decision date | In C window (11-01 → 12-16) | Tag | Source |
|---|---|---|---|---|---|
| FOMC | 2026-10-27/28 (no SEP) | 2026-10-28 — **HELD**, 3-3/4 to 4%, IORB 3.90%, 10-2 vote (Cook, Hammack preferring +25bp) | NO — passed | (C) | federalreserve.gov/newsevents/pressreleases/monetary20261028a.htm; fomccalendars.htm fetched 2026-11-01 |
| FOMC | 2026-12-08/09, **SEP/dot plot meeting** | **2026-12-09** (2:00 pm ET statement; presser) | **YES** (day 39 of 2026-11-01 → 12-16 window) | (C) status "Scheduled" | fomccalendars.htm fetched 2026-11-01 |
| FOMC | 2027-01-26/27 (no SEP) | 2027-01-27 | No | (C-tentative) | same |
| FOMC | 2027-03-16/17 (SEP) | 2027-03-17 | No | tentative | same |
| FOMC | 2027-04-27/28 | 2027-04-28 | No (A window only) | tentative | same |

Δ vs W43: Dec meeting is now comfortably inside C window (was day 45 boundary). Context (secondary, unverified for C thesis): Admiral Markets headline "markets price a December hike"; two hawkish dissents. First 2027 meeting: 01-26/27. Per the page, no 2026 date is flagged tentative.

### 1B.2 — Earnings inside the C window: company-IR-confirmed subset

Window 2026-11-01 → 2026-12-16. **Struck (printed before the window, 10-26 → 10-30):** V, MSFT, GOOGL, GEV, NOW, AMZN, LLY, MRK, INTC, CAT, FSLR, XOM, CVX, ABBV (all W43 (C) rows, dates elapsed; see 'Printed this week' in 1A). 'NEW' = confirmed this run by WebSearch result citing the issuer's own release (the issuer page itself was not opened first-hand; the quoted release dates/times are from the search extract). 18 web searches in total; the ten NEW confirmations are all from search extracts, each naming an issuer notice with a date.

**Company-IR confirmed (C)**

| Date | Ticker | Timing | Mcap ($B) | Confirmation |
|---|---|---|---|---|
| 2026-11-02 | AAPL | after close; 2:00 pm PT | 5,092 | Apple IR notice relayed by secondary sites (carried from W43, held at (C-secondary); apple.com / investor.apple.com not first-hand read) |
| 2026-11-02 | PLTR | after close | 472 | Palantir Business Wire release; webcast 5:00 pm ET (carried from W43, not re-read; investors.palantir.com not fetched) |
| 2026-11-02 | VRTX | after close | 137 | Vertex release 2026-10-07 (carried from W43, not re-read) |
| 2026-11-03 | AMD | after close | 925 | ir.amd.com 2026-10-06 (carried from W43, not re-read) |
| 2026-11-03 | ANET | after close | 232 | **NEW** arista.com release 2026-10-06; call 1:30 pm PT |
| 2026-11-03 | SHOP | pre-market | 217 | **NEW** Shopify release 2026-10-06 (search result); call 8:30 am ET |
| 2026-11-03 | PFE | pre-market | 171 | **NEW** Pfizer release 2026-09-22; webcast/call 10:00 am ET |
| 2026-11-03 | SMCI | after close | 23 | **NEW** Supermicro IR call notice (5:00 pm ET); preliminary FQ1 update 2026-10-20 (rev $18.5-19.5B) already out |
| 2026-11-04 | QCOM | after close | 195 | **NEW** Qualcomm release 2026-10-22 (qualcomm.com/news/releases/2026/10) |
| 2026-11-04 | UBER | pre-market | 134 | investor.uber.com release 2026-10-05; call 8:00 am ET (carried from W43, not re-read) |
| 2026-11-04 | DDOG | pre-market | 95 | Datadog date release (carried from W43, not re-read) |
| 2026-11-05 | COP | pre-market | 180 | **NEW** ConocoPhillips Business Wire release 2026-09-24; call 12:00 pm ET |
| 2026-11-05 | AKAM | after close | 14 | Akamai release 2026-10-08 (carried from W43, not re-read) |
| 2026-11-09 | TTWO | after close | 36 | **NEW** Take-Two release; 4:30 pm ET |
| 2026-11-12 | AMAT | after close | 335 | **NEW** Applied Materials release 2026-10-22; call 4:30 pm ET |
| 2026-11-17 | NVDA | after close | 5,149 | **NEW** NVIDIA newsroom release "Sets Conference Call for Third-Quarter Financial Results"; call 2:00 pm PT. Δ vs W43 (E) 11-18 |
| 2026-11-17 | DIS | pre-market | 192 | **NEW** Disney release 2026-10-12; webcast 8:30 am ET |
| 2026-11-18 | TGT | pre-market | 69 | corporate.target.com (carried from W43, not re-read) |
| 2026-11-19 | WMT | pre-market | 962 | corporate.walmart.com (carried from W43, not re-read) |

**Vendor-only (E) — no issuer notice found**

| Date | Ticker | Timing (Nasdaq) | Mcap ($B) | Source / check |
|---|---|---|---|---|
| 2026-11-10 | NBIS | not supplied | 47 | Nasdaq; calendar sites 11-10/11-11 (AJ Bell/EarningsWhispers); no issuer notice found |
| 2026-11-11 | CSCO | not supplied | 428 | Nasdaq + FMP (EPS est 1.32). Searched 2026-11-01: no FQ1 FY27 notice (last year: notice 11-03 for 11-12) |
| 2026-11-17 | HD | pre-market | 328 | Nasdaq; calendar sites expect 11-17; no formal confirmation found |
| 2026-11-18 | PANW | not supplied | 311 | Nasdaq; no FQ1 FY27 notice found (last year: notice 11-04 for 11-19) |
| 2026-11-19 | INTU | not supplied | 89 | Nasdaq; no notice found (last year: late-Oct notice for 11-20) |
| 2026-11-24 | DELL | not supplied | 302 | Nasdaq; calendar-site projection only |
| 2026-12-01 | CRWD | not supplied | 267 | Nasdaq; not searched (no notice in W43) |
| 2026-12-01 | MRVL | not supplied | 191 | Nasdaq; not searched (no notice in W43) |
| 2026-12-01 | NTAP | after close | 43 | Nasdaq; Δ vs W43 11-24 → 12-01; not searched |
| 2026-12-01 | OKTA | not supplied | 39 | Nasdaq; not searched |
| 2026-12-02 | CRM | not supplied | 190 | Nasdaq; not searched; prior-year notice came 11-05 |
| 2026-12-02 | SNOW | not supplied | 117 | Nasdaq; not searched |
| 2026-12-03 | HPE | not supplied | 78 | Nasdaq; not searched |
| 2026-12-09 | ORCL | not supplied | 422 | Nasdaq; not searched |
| 2026-12-09 | ADBE | not supplied | 97 | Nasdaq + FMP (EPS est 6.32); not searched |
| 2026-12-10 | AVGO | not supplied | 1,647 | Nasdaq; not searched |
| 2026-12-10 | COST | not supplied | 441 | Nasdaq + FMP (EPS est 4.93); not searched |
| 2026-12-16 | MU | not supplied | 1,057 | Nasdaq/days.to/WSH 12-16; searched: inferred only |
| 2026-12-03 | DOCU | not supplied | 16 | FMP + Nasdaq; not searched |

Outside the window (FMP only): NKE 12-17, CCL 12-18.

**Dropped / changed vs W43:** passed rows struck (14 names above); GOOGL/PLTR/UBER already (C). Moved to (C) this run: NVDA, ANET, QCOM, TTWO, SMCI, AMAT, COP, PFE, DIS, SHOP. Still unconfirmed: CSCO, PANW, HD, NBIS, INTU, DELL, and the December names. Δ dates: NVDA 11-18 → 11-17; NTAP 11-24 → 12-01.

### 1B.3 — FDA PDUFA dates in window (2026-11-01 → 2026-12-16)

Rule: sponsor/status resolved against FDA/sponsor release where reachable; otherwise "unresolved". Cap/ADV not measured.

| Date | Ticker | Drug / indication | Tag | C-eligible instrument | Resolution / note |
|---|---|---|---|---|---|
| 2026-11-01 (Sun) | AGIO | Mitapivat sNDA / sickle cell (priority, accelerated) | (C) | yes | Goal date today. **Unresolved**: no FDA action or Agios release found (IR page 403). Pain-crisis primary endpoint missed significance |
| 2026-11-14 | SMMT | Ivonescimab + chemo BLA / EGFRm NSCLC | (C) | yes | Summit release 2026-01-29 (carried); no decision/extension found |
| 2026-11-14 | CYTK | Aficamten label expansion | (E) unverified | yes | oHCM NDA was approved Dec 2025; 11-14 only on aggregators |
| 2026-11-17 | Beren | Adrabetadex | (E) | NO not listed | |
| 2026-11-22 | CAPR | Deramiocel / DMD | (C) | yes | 8-K 2026-08-24 (carried) |
| 2026-11-22 | SVRA | Molgramostim / aPAP (extended) | (E) | yes | aggregators; no sponsor release read |
| 2026-11-25 | SAN | Venglustat / Gaucher type 3 | (C) | NO ADR | |
| 2026-11-27 | BBIO | BBP-418 / LGMD2I | (E) | yes | |
| 2026-11-27 | GSK (ADR) | Neladalkib / ALK+ NSCLC | (C) | NO ADR; sponsor GSK (acquired Nuvalent 2026-07-15) | |
| 2026-11-27 | Zydus | Saroglitazar | (E) | NO | |
| 2026-11-28 | PYPD | D-PLEX100 | (C) | yes; cap likely <$2B | |
| 2026-11-30 | VRTX | Povetacicept BLA / IgAN | (C) | yes | Vertex release 2026-06-01 |
| 2026-11-30 | COGT | Bezuclastinib + sunitinib / GIST (priority; no adcom) | (C) Δ re-confirmed | yes | Cogent acceptance release; OncLive 2026-05-28 |
| 2026-11-30 | RHHBY | Giredestrant adjuvant | (E) | NO ADR | |
| 2026-12-05 | VRTX | Journavx sNDA | (T) | yes | not re-verified |
| **Δ 2026-12-12** | VNDA·ANAB | Imsidolimab BLA | (E) | yes (both small/mid cap; not measured) | Assyro only; indication not stated; **newly in window** (12-10 → 12-16 range). No other PDUFA found for 12-10 → 12-16 (two searches; floor, not census) |
| Nov (undated) | REGN | Cemdisiran / gMG | undated | yes | |
| Q4 (undated) | PFE | Talzenna + Xtandi label expansion | undated | yes | |

**Resolved/struck this week (do not re-import):**
- ~~2026-10-26 GSK bepirovirsen~~ — APPROVED 2026-10-20 as Hibsago (GSK release copy at eatg.org, HCPLive 10-20, ajmc 10-21); ADR anyway.
- ~~2026-10-30 INO INO-3107~~ — outcome UNRESOLVED (no approval/CRL surfaced); past; do not assert.
- ~~2026-10-29 Sun Pharma ILUMYA~~ — not US-listed, not verified.
- ~~BTAI IGALMI 11-14~~ — BTAIQ PINK, no options (carried).
- ~~EXEL zanzalintinib~~ — moved to 2027-03-03; Dec Assyro aggregator still shows 12-03 (stale).
- Out of window by date (kept in 1A.6): CORT 12-17; Roche/Deciphera/Camurus 12-18; Hansa 12-19; MLYS 12-22; Arcellx/Gilead 12-23; Praxis/Viatris 12-27; COGT NonAdvSM + Saol 12-30.

### Macro calendar in C window (2026-11-01 → 2026-12-16)

| Date | Release | Tag | Source / note |
|---|---|---|---|
| 11-03 | US midterm elections | (C) | statutory |
| 11-04 (?) | Personal income & outlays (Sept) incl. PCE | (T) | BEA snippets conflict (10-29 vs 11-04); verify at bea.gov/news/schedule |
| 11-06 | Employment Situation (Oct) | (C) | bls.gov schedule; calendars agree |
| 11-10 | CPI (Oct) | (C) carried | bls.gov W43; financecalendar agrees |
| ~11-25 | PCE (Oct) + GDP 2nd est. Q3 | (E) | single-source / BEA per W43 |
| 12-04 | Employment Situation (Nov) | (C) | financecalendar/bls |
| 12-08/09 | FOMC + SEP (decision 12-09) | (C) | federalreserve.gov |
| 12-10 | CPI (Nov) | (C) | calendarx + financecalendar |
| 12-11 | Government funding CR expires | (C-secondary) | political.org/AACOM |
| ~12-23 | GDP 3rd est. (outside window) | (E) | |

No 2026 shutdown-related BLS/BEA delay found (only 2025's cancelled Oct-2025 releases). BEA page shows no confirmed lapse notice this run; risk reappears if the CR lapses 12-11 (inside the C window, after 12-09 FOMC, before 12-10 CPI would be unaffected but 12-11+ releases at risk).

## PART 2A — Strategy A ranked shortlist

### The A-queue census — the PINNED query, run verbatim

`SELECT * FROM state.open_queue WHERE strategy = 'A'` → **46 rows** (MEASURED 2026-11-01; 44 on 2026-10-25, +2 from W4's 2026-W43 intake of ANET and COP): AMZN, INTC, HPE, MSFT, ADBE, PANW, IBM, AMAT, TTWO, CVX, LLY, CRWD, NTAP, GEV, HD, SMCI, SNOW, AMD, DDOG, META, CRM, OKTA, NOW, XOM, QCOM, JPM, MU, MRVL, NVDA, WMT, CSCO, NBIS, FSLR, VRTX, INTU, ORCL, TGT, COP, MRK, GOOGL, AKAM, CAT, AVGO, ANET, AAPL, DELL. The enumeration is the query's own 46 rows, not a hand list, so there is no discrepancy to reconcile. Every "already queued" / "NEW" mark below is tested against it.

### STEP 1 — the GATE DATE, re-derived from scratch, with the arithmetic shown

**DERIVED GATE DATE = 2026-11-01** (today, the run date). Derived under the Rev 52 STEP 1: the earliest of inputs (a), (b), (c). The pre-Rev 52 derivation (quiet clock, retracement, `state.rerisking_limb_status`) is retired and was not run.

**Router state read first.** A's `STRATEGY_ACTIVATION` reads **DO-NOT-ACTIVATE** (`state.current_regime`, as_of 2026-10-22, `div-A-202610-1` resolved). A is not ACTIVATE, so CATALYST-GATE MODE is live, not inert.

- **(a) Next scheduled M1a/M1b re-score.** `SELECT COUNTIF(routine='M1a') m1a, COUNTIF(routine='M1b') m1b FROM ops.run_log WHERE routine IN ('M1a','M1b') AND status='completed' AND run_date >= DATE_TRUNC(2026-11-01, MONTH)` → **m1a = 0, m1b = 0**. `m1b = 0` and today (11-01) is before this month's first trading day per `state.market_calendar` (**2026-11-02**, Monday), so (a) = **2026-11-02**.
- **(b) Open `PENDING_REGIME_REFRESH` `regime-refresh` items** (`state.open_queue_detail`): **none** → does not apply.
- **(c) A refresh D2a is already due to queue.** D2a Step 0 REFRESH REQUEST detection query, run verbatim → **1 row**: `measured_trigger = shock_price_leg_exit`, `trigger_run_start = 2026-10-29`, `logged_ts = 2026-10-29T23:19:12Z` (D2's refresh-only router review `c13f9996`), with no `regime-refresh` row counting at or after it. (b) found no open item, so (c) = D2a's next run = **2026-11-01** (D2a fires Sunday–Thursday 16:40 MT; for W1's Sunday slot that is the same day).
- **Earliest of (a) 2026-11-02, (b) n/a, (c) 2026-11-01 = 2026-11-01.**

**Consequence, stated plainly.** With the gate on the run date, SPENT-BY-GATE requires a dated catalyst strictly before today — i.e. one already in the past. Every candidate is classified on its NEXT dated catalyst on or after 2026-11-01, so this cycle has **zero SPENT-BY-GATE** names by construction, and every candidate receives full (a)-(e). This is the mode working as specified (an out-of-cycle re-score is reachable today), not a fail-open.

**FAIL-OPEN status: not triggered.** All three inputs read cleanly.

### STEP 2 — direction rail

Strategy A is long-only; the rail ran before ranking and before gate classification. Evidence read this week: D1 records 10-26..10-29 (`d1_context.md`, `Daily.md`), FMP actuals 10-26..10-30, IBKR RTH daily bars through 10-30. The 10-30 narrative is NOT covered by D1; one WebSearch and one Tavily search for a 10-30 chip-selloff explanation returned nothing usable, so the 10-30 price moves below are MEASURED but their cause is unestablished.

- **Nine names stay in the DIRECTION-INADMISSIBLE tier** (AMAT, WMT, ADBE, HD, AKAM, DAL, CCL, UAL, AAL). None is reversed to bullish; two marks are flagged weaker (AMAT, fuel cluster), one stronger (ADBE).
- **AMAT: bearish mark WEAKENED, not reversed.** Against the "China WFE cliff" framing: Lam's record quarter (10-21) and July WFE raise; SK hynix +13.3% on 10-28 as a memory read-through (D1 10-28, which rejected AMAT/LRCX/MU/SNDK as a common driver); AMAT closed 390.09 on 10-30, +3.4% on the week (377.24 on 10-23), although it fell 7.5% on Friday (421.66 to 390.09, cause unestablished). No bullish thesis is established either, so AMAT is effectively direction-unresolved; D2 should re-test before any thesis run. Stays inadmissible and out of the top-10.
- **Fuel-shock cluster (DAL, CCL, UAL, AAL): mark kept, slightly weaker.** Brent 116.72 peak 10-23, 115.32 on 10-28, 111.57 on 10-29 (D1/FMP BZUSD, provisional). Still about 111, far above the pre-shock level; Hormuz still closed per the IRGC on 10-29 (unverified claims). Falling Brent is a mitigant, not a reversal. Airlines' next prints are 2027-01 (E, FMP); CCL 2026-12-18 (E).
- **WMT: kept, thinner** (no new evidence this week; staples/defensive rotation on 10-29 with XLV +2.40 and RSP +1.20 is a contrary datapoint). **HD: kept** (no new evidence; 10Y level not re-read). **AKAM: kept.** **ADBE: kept, stronger** (software sell-off: NOW -26.95%, FTNT -20.09% on 10-28 prints, XLK -1.18 on 10-29).
- **TGT stays DIRECTION UNRESOLVED** (carried; refuted bearish thesis, no replacement). Ranked last of the admissible list, ineligible for the top-10.
- **No new bearish names added to this file.** FTNT (-20%) and NOW-type software prints are B territory.

### STEP 3 — classification and counts

Gate date **2026-11-01** (orchestrator-derived). SPENT-BY-GATE iff the dated catalyst is strictly before 2026-11-01 and there is no dated catalyst on/after it; undated is GATE-SURVIVING (fail-open).

**59 carried: 50 ranked admissible (one, TGT, direction-unresolved) + 9 DIRECTION-INADMISSIBLE. 0 SPENT-BY-GATE, 59 GATE-SURVIVING.** Reason: the gate equals the run date, so the only way to be spent is a catalyst dated 2026-10-31 or earlier with nothing later; every 10-26..10-30 printer was re-dated to its NEXT dated catalyst (FMP/Nasdaq) or is undated (fail-open). Last week's 7 SPENT names move as follows:

- XOM and CVX: printed 10-30 (FMP actuals: XOM EPS 4.23 vs 4.12, revenue $113.2B vs $104.9B; CVX EPS 5.28 vs 4.87, revenue $67.8B vs $61.8B). Next **2027-01-29 (E)** (FMP). SURVIVING.
- INTC: printed 10-29 (EPS 0.52 vs 0.4066, revenue $16.51B vs $16.56B est; FMP; Daily: Q4 guide $15.0-16.0B). Next **2027-01-28 (E)** (FMP). SURVIVING.
- LLY (10-29), CAT (10-29), GEV (10-28), NOW (10-28): no next date in the FMP/Nasdaq pulls (Nasdaq pull ends 12-16; FMP lists none). Dates are late-Jan/early-Feb by pattern, INFERRED and unsourced, so **undated, SURVIVING on fail-open**.
- Other re-dated prints: MSFT 10-28 (EPS 4.89 vs 4.72, revenue $92.28B vs $90.62B) next **2027-01-27 (E)**; AMZN 10-29 (EPS 1.89 vs 1.97, revenue $201.9B vs $202.2B; AWS +39.3% per Daily) next **2027-02-04 (E)**, re:Invent 11-30..12-04 (E); GOOGL 10-28 (EPS 2.12 vs 3.02, revenue $127.6B vs $128.0B; -12.64% on 10-29) next **2027-02-03 (E)**; META (printed 10-21) next **2027-01-27 (E)**; MRK 10-29 dropped (below); FSLR 10-29 (Daily: EPS $5.30 vs $4.64, $500M buyback) keeps **Sec 232 effective 2026-12-04 (C)**; V 10-27 dropped (below); GE keeps **2027-01-21 (E)**.
- **Date moves vs last week (Nasdaq per-day, MEASURED; time `not-supplied` = (E))**: CEG 11-06 to **11-09** (pre-market); NTAP 11-24 to **12-01** (after hours); AVGO 12-09 to **12-10**; MU 12-23 to **12-16**; AAPL, PLTR, VRTX 11-02 now carry a stated time (after-hours); QCOM 11-04 after-hours and COP 11-05 pre-market confirmed on the calendar; TTWO 11-09 after-hours; others unchanged.
- **Fragile (one day past the gate):** AAPL, VRTX, PLTR (11-02); AMD, ANET, SHOP, SMCI, ETN (11-03). Gate = 11-01 is the run date, so they survive by one session; they are consumed by the first post-gate trading days.
- **Dropped from the ranked set with reasons (stay on the queue census where queued):** MRK (conviction 1 last week; near-term PDUFAs gone; beat on 10-29 EPS 2.49 vs 2.12 consumed the print; next 2027-02-02 (C carried) offers no differentiated thesis); V (thin litigation-date catalyst; 10-27 print EPS 3.48 vs 3.44 consumed). Both remain GATE-SURVIVING on their dates and are listed only here.
- **New intake (2):** SNDK, RDDT (preliminary, see rows 49-50).

### Price context (IBKR regular-session daily bars, MEASURED; 10-23 and 10-30 closes)

| Ticker | 10-23 | 10-30 | Week change | Note |
|---|---|---|---|---|
| VRTX | 523.93 | 558.88 | +6.7% | +3.6% on 10-30 into the 11-02 print; 10-30 high 563.80 |
| TTWO | 203.69 | 190.17 | -6.6% | 10-28 195.29, 10-30 -1.7%; no cause found |
| FSLR | 171.99 | 174.40 | +1.4% | 10-29 close 176.89 before the after-close print; 10-30 -1.4% |
| COP | 150.80 | 154.03 | +2.1% | XOM/CVX beats read-through; +2.7% on 10-30 |
| ANET | 172.37 | 168.86 | -2.0% | 10-30 -9.6% (186.72 on 10-28 to 168.86; 184.22 on 10-29) |
| AAPL | 347.73 | 344.63 | -0.9% | 10-30 low 334.35, close 344.63 |
| AMD | 516.79 | 504.80 | -2.3% | 578.44 on 10-28, 566.42 on 10-29; -10.9% on 10-30 |
| NVDA | 210.96 | 204.64 | -3.0% | 10-30 -4.2% (213.66 to 204.64) |
| AVGO | 321.68 | 326.08 | +1.4% | 351.81 on 10-28; -5.5% on 10-30 |
| CSCO | 106.50 | 104.51 | -1.9% | 10-30 -3.8% |
| QCOM | 175.91 | 164.79 | -6.3% | 185.41 on 10-29; -11.1% on 10-30 on 10.8M shares (about 3x normal) |
| LRCX | 230.10 | 239.11 | +3.9% | 254.39 on 10-29; -6.0% on 10-30 |
| MSFT | 524.51 | 521.91 | -0.5% | 10-29 530.14, flat after a beat |
| AMZN | 248.00 | 240.35 | -3.1% | 254.60 on 10-28, 243.79 on 10-29 (-4.25%), 240.35 on 10-30 |
| CEG | 253.45 | 262.38 | +3.5% | |
| PLTR | 196.75 | 184.11 | -6.4% | 10-30 -6.3% (196.42 to 184.11), the day before its print |
| ORCL | 126.16 | 130.67 | +3.6% | 144.54 on 10-28 (+10.7% on own event per D1), -6.4% on 10-30 |
| SMCI | 32.94 | 32.95 | 0.0% | |
| ETN | 366.11 | 369.97 | +1.1% | 393.72 on 10-29, -6.0% on 10-30 |
| AMAT (inadmissible) | 377.24 | 390.09 | +3.4% | 421.66 on 10-29, -7.5% on 10-30 |

**Friday 10-30 (MEASURED price only):** AI-hardware and semis fell together: AMD -10.9%, QCOM -11.1%, ANET -9.6%, AMAT -7.5%, ORCL -6.4%, PLTR -6.3%, LRCX -6.0%, ETN -6.0%, AVGO -5.5%, SMCI -4.3%, NVDA -4.2%. Cause not established (no D1 coverage, two searches empty). INFERRED only: a Friday de-risking in the AI-capex complex after a week that mixed strong prints with the GOOGL EPS miss and software collapse; no issuer event is claimed. This widens the prices going into the 11-02/11-03/11-04 prints for AAPL-adjacent hardware, AMD, ANET, SMCI, QCOM, and it is the new counter-evidence every AI-complex row must carry.

### Week narrative driving the revisions (MEASURED from FMP actuals, Daily.md/D1 and IBKR; inferences labelled)

- **Hyperscaler prints (10-28/29).** MSFT beat (EPS 4.89 vs 4.72; revenue $92.3B vs $90.6B; FMP) and closed flat (521.91, -0.5% week). AMZN: EPS 1.89 vs 1.97, revenue $201.9B vs $202.2B (FMP), but AWS +39.3% and a 38.65% margin (Daily); stock -4.25% on 10-29 and -1.4% on 10-30. GOOGL: EPS 2.12 vs 3.02 est (FMP), revenue $127.6B vs $128.0B; -12.64% on 10-29 (324.89 to 283.82); 10-Q backlog $567.7B and an ad-tech structural-divestiture denial (Daily). The reason for the EPS gap (charge vs operating) is not established here. META printed 10-21 (carried). Reading for A: hyperscaler capex and cloud demand strong (positive for suppliers), but the market is rewarding returns, not spend; GOOGL's reaction shows an EPS miss is punished hard.
- **Semis/memory.** INTC beat (EPS 0.52 vs 0.4066; Q4 guide $15.0-16.0B). SK hynix +13.3% on 10-28 (memory read-through). MRVL -13.2% on a Bloomberg report of advanced talks to buy Lumentum (not an issuer release). SNDK fiscal-Q1 EPS $49.51 vs $46.19 on $11.0B revenue (Daily, EDGAR). Then the 10-30 chip selloff above.
- **Software.** NOW -26.95% (150.13 to 109.67) and FTNT -20.09% on 10-28 after-close prints; XLK -1.18% on 10-29. Thesis for NOW ("agentic attach under-credited") was the print and the print contradicted it.
- **Energy.** XOM and CVX both beat (FMP, above). Brent 115.32 (10-28) to 111.57 (10-29); Hormuz still closed per IRGC (unverified). COP's 11-05 print inherits a positive peer read-through.
- **Health care.** LLY non-GAAP EPS $7.48 vs $5.38 (includes $4.57 acquired IPR&D), revenue $24.4B, 2026 revenue guide raised $5.5B to $91-92B; MRK $2.49 vs $2.12; BMY beat; XLV +2.40% (Daily). VRTX +6.7% on the week into its print.
- **Macro.** FOMC held at 3.75-4.00% on 10-28, 10-2 with two dissents for a hike (hawkish); Q3 GDP +3.4%; Sept core PCE +3.1% y/y; SPY -0.38%, QQQ -1.42% on 10-29; VIX about 17.
- **FSLR** printed 10-29 (EPS $5.30 vs $4.64, $500M buyback; Daily/EDGAR). The policy catalyst (Sec 232, 12-04) is untouched.

### TOP-10 — the actionable tier

**Selection rule (stated for W4).** The top-10 contains only ADMISSIBLE, GATE-SURVIVING names with a dated post-gate catalyst that is NOT merely a re-dated print already consumed. A name whose thesis was a print that has now occurred (MSFT, AMZN, GOOGL, META, INTC, XOM, CVX, LLY, CAT, GEV, NOW) cannot be top-10 unless a new dated forward catalyst exists; they sit at 11+ or lower. A name whose catalyst falls within one session of the gate (AAPL, VRTX, AMD, ANET) stays eligible but is flagged fragile. When a surviving admissible name of comparable conviction exists, a name with an undated catalyst is excluded. All ten rows are long. Zero SPENT names in the tier.

**1. VRTX - Vertex Pharmaceuticals.** (a) Bullish. (b) Povetacicept (IgAN) accelerated-approval BLA, PDUFA **2026-11-30 (C)** per Vertex's own 2026-06-01 release (carried, not re-read this run); Crinetics acquisition closed 2026-09-01; an ~$8.8B IPR&D charge lands in the 11-02 print (known, non-cash; carried). Documents for construction: 10-Q, the 11-02 release, the BLA acceptance notice. Counter-evidence (MEASURED): the stock is +6.7% on the week to 558.88 (10-30 high 563.80), so part of the regulatory optimism is priced into the run-up; XLV +2.40 on 10-29 rotation helped. (c) Earnings **2026-11-02 (C)** after hours (Nasdaq; company-issued date carried), ON the day after the gate; PDUFA 2026-11-30 (C). (d) Queued (already queued); no open position. (e) Top-10, conviction **4** (held; the PDUFA is the post-gate anchor). GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-11-02)

**2. TTWO - Take-Two Interactive.** (a) Bullish. (b) GTA VI launch 2026-11-19 reaffirmed in the fiscal-Q4 2026 release; FY27 net bookings $8.0-8.2B reaffirmed 2026-08-07 (press reports; carried, not re-read). Documents for construction: last two 10-Qs (deferred revenue, preload), the fiscal-Q2 release. The stock fell 6.6% on the week to 190.17 (195.29 on 10-28, 190.17 on 10-30, a new 4-week low) with no cause found in D1 or my searches; absence of evidence, not evidence of a delay. Counter-evidence: a launch slip would be thesis-invalidating, and no October company update was found. (c) **GTA VI launch 2026-11-19 (C)**; fiscal-Q2 earnings **2026-11-09 (C)** after hours (issuer notice per 1B.2; Nasdaq, EPS forecast $0.49, 6 estimates). (d) Already queued; no open position. (e) Top-10, conviction **4** (price gap widened; verify no delay report before construction). GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-11-09)

**3. FSLR - First Solar.** (a) Bullish. (b) Sec 232 polysilicon-and-derivatives regime (proclamation signed 2026-08-06; effective 12:01 am ET 2026-12-04; minimum import prices on polysilicon, wafers, cells and modules; secondary coverage about a $0.38/W module floor); CdTe contains no polysilicon. New: the 10-29 print beat (EPS $5.30 vs $4.64, guidance updated, $500M buyback; Daily/EDGAR 8-K, details of the guide not read). Documents for construction: proclamation text, the 10-29 8-K and 10-Q. Counter-evidence: stock ended 174.40 (-1.4% on 10-30, so the beat did not extend). (c) **Sec 232 regime effective 2026-12-04 (C)**. (d) Already queued; no open position. (e) Top-10, conviction **4**; the most policy-anchored, least AI-capex-exposed name. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-12-04)

**4. COP - ConocoPhillips.** (a) Bullish. (b) XOM and CVX beat on 10-30 (EPS 4.23 vs 4.12; 5.28 vs 4.87; revenue +8% and +10% above estimates; FMP) which is a positive read-through for an upstream pure-play; Nasdaq consensus EPS $2.97 (8 estimates). Brent 111.57 on 10-29, down from 116.72. Gap hypothesis (INFERRED, preliminary): consensus models a transient shock; physical flows (Hormuz closed per IRGC 10-29, unverified) point to a structural one. Documents for construction: Q2 10-Q (realized prices, hedging), Q3 release. Counter-evidence: falling Brent (-3.25% on 10-29) and de-escalation risk. (c) Earnings **2026-11-05 (C)** pre-market (ConocoPhillips release of 2026-09-24, carried; Nasdaq pre-market). (d) Already queued (W4 intake 2026-W43 per D1). No open position. Concentration note: the XOM/CVX seam is now post-print, so COP is the lone energy name in the tier. (e) Top-10, conviction **3**, raised in rank by peer beats. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-11-05)

**5. ANET - Arista Networks.** (a) Bullish. (b) AI back-end and front-end switching share; Q3 guide revenue about $3.3B, non-GAAP operating margin 48-49%, EPS $1.06-1.08 (Q2 release exhibit, carried); Nasdaq consensus EPS $0.99 (9 estimates). New support: AMZN AWS +39.3%, MSFT beat, META capex floor $135-145B (carried) all point to hyperscaler spending continuing. Counter-evidence (MEASURED): ANET -9.6% on 10-30 to 168.86, customer concentration (Meta, Microsoft), and the market is rewarding capex restraint. Documents for construction: Q2 10-Q, last four transcripts, Q3 release. (c) Earnings **2026-11-03 (C)** after hours, call 1:30 pm PT (Arista press release 2026-10-06, carried). (d) Already queued (W4 intake 2026-W43 per D1); no open position. (e) Top-10, conviction **3**. Fragile (11-03). GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-11-03)

**6. AAPL - Apple.** (a) Bullish. (b) FQ4 results 2026-11-02; FQ3 guide September-quarter revenue growth 9-11% (about $111.7-113.7B), iPhone growth mid-teens; FMP consensus revenue $113.4B, EPS $1.99; Nasdaq EPS $1.98 (7 estimates). Defensive mega-cap with a quantified guide; -0.9% on the week, held near 345 through the chip selloff (10-30 intraday low 334.35, close 344.63). Watch items: memory pricing and supply (SK hynix +13.3% on 10-28 raises memory cost risk). (c) Earnings **2026-11-02 (C)** after hours (Apple notice via press, carried; Apple IR page not reached). (d) Already queued; no open position. (e) Top-10, conviction **3**. Fragile. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-11-02)

**7. AMD - AMD.** (a) Bullish, contested on competitive position. (b) Lost the exclusive SpaceX AI-compute socket to NVDA (2026-08-05, carried); FMP consensus EPS $1.95, revenue $13.09B; Nasdaq EPS $1.68 (13 estimates; the two consensus figures disagree, so the beat bar is unclear). Price: 578.44 on 10-28, 504.80 on 10-30 (-10.9% on Friday, cause unestablished). Gap is wider than last week, but so is the risk that Friday's move reflects information not captured here. (c) Earnings **2026-11-03 (C)** after hours, call 5:00 pm ET (ir.amd.com 2026-10-06, carried). (d) Already queued; no open position. (e) Top-10, conviction **3**. Fragile. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-11-03)

**8. NVDA - NVIDIA.** (a) Bullish. (b) FQ2 10-Q, last four transcripts; supply side: TSMC Q3 beat and AI demand exceeds supply (carried). New: hyperscaler capex confirmed by the AWS +39.3% and MSFT prints. Counter-evidence: CoreWeave credit stress and circular-financing objections (carried); price 204.64 (-3.0% week, -4.2% on 10-30). (c) Earnings **2026-11-17 (C)** after hours (issuer notice per 1B.2, Δ from 11-18; Nasdaq: 11-17, EPS $2.49 est, 13 estimates; FMP says 11-17 too, EPS 2.47); GTC DC 11-30 (E, conflicting listings). (d) Already queued; no open position. (e) Top-10, conviction **3**. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-11-17)

**9. AVGO - Broadcom.** (a) Bullish. (b) Custom silicon and AI networking attach; Nasdaq consensus EPS $3.45 (10 estimates). Counter-evidence: AI-debt vehicle and OpenAI financing reports, CoreWeave credit, the capex-restraint reaction; price 326.08 (+1.4% week; 351.81 on 10-28, -5.5% on 10-30). (c) Earnings **2026-12-10 (E)** (Nasdaq; moved from 12-09; absent from FMP). (d) Already queued; no open position. (e) Top-10, conviction **3**. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-12-10)

**10. CSCO - Cisco.** (a) Bullish. (b) Fiscal-2026 hyperscaler AI orders raised to about $9B (from $5B), FY27 AI-infrastructure revenue about $7.5B flagged, some orders possibly pulled forward; non-GAAP gross margin 66.3% (secondary, carried); Nasdaq EPS $1.15 (8 estimates), FMP EPS $1.32 (the two consensus figures disagree). Price 104.51 (-1.9% week; -3.8% on 10-30). (c) Earnings **2026-11-11 (E)** (FMP and Nasdaq; time not supplied; no Cisco notice found). (d) Already queued; no open position. (e) Top-10, conviction **3**. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-11-11)

### 11-20

Research-cost note: every row in 11-50 carries the full (a)-(e); carry-forward rows keep (b) terse where the evidence is unchanged.

**11. QCOM - Qualcomm.** (a) Bullish. (b) Stellantis Snapdragon expansion, auto/IoT diversification (carried; no fresh document). New: -11.1% on 10-30 (185.41 to 164.79) on about 3x normal volume, cause unestablished; Nasdaq EPS $1.46 (9 estimates). A drop of that size into a print widens the gap if the drop was sector, not issuer, news; INFERRED. (c) FQ4 **2026-11-04 (C)** after hours (issuer notice per 1B.2; Nasdaq). (d) Already queued. (e) 11-20, conviction **3** (up from 3, rank up: the 10-30 move creates the gap, but the unknown cause caps conviction). GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-11-04)

**12. LRCX - Lam Research.** (a) Bullish. (b) Printed 10-21: record revenue $8.22B (+54% y/y), operating margin above 40% (secondary); July WFE view raised to the low $150B range; SK hynix +13.3% on 10-28 supports memory capex (D1). Price 239.11 (+3.9% week; 254.39 on 10-29, -6.0% on 10-30). Documents for construction: 10-Q, shipment-vs-revenue disclosures, transcript. Counter-evidence: AI-capex restraint; supply constraints. (c) Next print **undated** (late January INFERRED from the fiscal pattern). (d) **NOT on the A queue; new intake** (carried new intake from W43). (e) 11-20, conviction **2**. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst undated)

**13. CEG - Constellation Energy.** (a) Bullish. (b) Power for AI load and nuclear contracting; Q2 2026 adjusted operating earnings $2.55/share, full-year guidance raised to $11.50-12.50 (secondary, carried); Nasdaq EPS $3.90 (4 estimates). +3.5% on the week (253.45 to 262.38), contract-backed, less capex-cycle exposed. Documents for construction: Q3 release, 10-Q. (c) Earnings **2026-11-09 (E)** pre-market (Nasdaq; moved from 11-06). (d) **NOT on the A queue; new intake.** (e) 11-20, conviction **2**. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-11-09)

**14. GOOGL - Alphabet.** (a) Bullish. (b) The 10-28 print: EPS 2.12 vs 3.02 est, revenue $127.6B vs $128.0B (FMP), stock -12.64% to 283.82 (Daily); 10-Q backlog $567.7B and an ad-tech divestiture denial (Daily). Gap hypothesis (INFERRED, preliminary): the market priced an EPS miss as a structural issue; if the gap is a charge, not operating, the move overshoots. Documents to pull: the 10-28 8-K and 10-Q (to split charge vs operating). Counter-evidence: miss may be operating margin; capex. (c) Next print **2027-02-03 (E)** (FMP); Waymo multi-city launches "2026" undated. (d) Already queued; **two open Strategy D lots** (D2 to confirm sleeves are distinct). (e) 11-20, conviction **2**. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2027-02-03)

**15. MSFT - Microsoft.** (a) Bullish. (b) 10-28 beat (EPS 4.89 vs 4.72; revenue $92.3B vs $90.6B; FMP); flat (-0.5% week), so the market did not reward the beat. The print thesis is consumed; no new document. (c) Next print **2027-01-27 (E)** (FMP); Ignite 2026-11-17..20 (E, third-party listing). (d) Already queued. (e) 11-20, conviction **2** (down from 3: thesis consumed). GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-11-17)

**16. AMZN - Amazon.** (a) Bullish. (b) AWS +39.3%, margin 38.65% (Daily) against a small consensus miss on EPS (1.89 vs 1.97); stock 240.35 (-3.1% week). Counter-evidence: capex financing. (c) re:Invent **2026-11-30..12-04 (E)**; next print **2027-02-04 (E)** (FMP). (d) Already queued; **two open Strategy D lots**. (e) 11-20, conviction **2**. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-11-30)

**17. ETN - Eaton.** (a) Bullish. (b) Data-centre electrical equipment and grid demand; Nasdaq EPS $3.54 (10 estimates). Gap hypothesis (INFERRED, preliminary, no documents read this run). Price 369.97 (+1.1% week; 393.72 on 10-29, -6.0% on 10-30). Documents for construction: Q2 10-Q backlog and orders. (c) Earnings **2026-11-03 (E)** pre-market (Nasdaq). (d) **NOT on the A queue; new intake.** (e) 11-20, conviction **2**. Fragile. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-11-03)

**18. SMCI - Super Micro.** (a) Bullish. (b) Raised fiscal-Q1 outlook 10-21 (D1; carried); AI-server demand resilient against the Barclays DELL/HPE/NTAP downgrade thesis; Nasdaq EPS $1.04 (6 estimates). Price 32.95 (flat on the week). (c) Earnings **2026-11-03 (C)** after hours (issuer notice per 1B.2; Nasdaq; absent from FMP). (d) Already queued. (e) 11-20, conviction **2**. Fragile. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-11-03)

**19. PLTR - Palantir.** (a) Bullish. (b) Government and commercial bookings; Nasdaq EPS $0.33 (10 estimates), FMP EPS $0.41. -6.3% on 10-30 (196.42 to 184.11), the session before the print. (c) Earnings **2026-11-02 (E)** after hours (Nasdaq, FMP). (d) **NOT on the A queue.** (e) 11-20, conviction **2**. Fragile. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-11-02)

**20. UBER - Uber.** (a) Bullish. (b) ~3,300-role restructuring margin effect lands in this print; ezCater $2.3B acquisition (10-06); Nasdaq EPS $0.94 (7 estimates), FMP $0.864. (c) Earnings **2026-11-04 (E)** pre-market (Nasdaq, FMP). (d) **NOT on the A queue**; open Strategy D lot. (e) 11-20, conviction **2**. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-11-04)

### 21-30

- **21. ORCL - Oracle.** (a) Bullish. (b) +10.7% on 10-28 on own events (D1); price 130.67 (+3.6% week; -6.4% on 10-30). Adverse: record CDS for Oracle and CoreWeave, WSJ OpenAI-financing report; funding structure is the live question. (c) FQ2 **2026-12-09 (E)** (Nasdaq; EPS $1.57). (d) Already queued. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-12-09)
- **22. SHOP - Shopify.** (a) Bullish; GMV take-rate. (b) Nasdaq EPS $0.33 (13 estimates), FMP $0.46. (c) **2026-11-03 (C)** pre-market (issuer notice per 1B.2). (d) NOT on the A queue. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-11-03)
- **23. DDOG - Datadog.** (a) Bullish. (b) Bernstein upgrade 10-19 (D1); Nasdaq EPS $0.18 (10 estimates); software sell-off (NOW, FTNT) is counter-evidence for the group. (c) **2026-11-04 (C)** pre-market (company release carried). (d) Already queued. (e) conviction 2 (down from 3: peer-print contagion). GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-11-04)
- **24. DIS - Disney.** (a) Bullish; SVOD margin. (b) Nasdaq EPS $1.67 (9 estimates), FMP $1.69. (c) **2026-11-17 (C)** pre-market (issuer notice per 1B.2). (d) NOT on the A queue; two open Strategy D lots. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-11-17)
- **25. MRVL - Marvell.** (a) Bullish. (b) Custom silicon; -13.2% on 10-28/29 on a Bloomberg report of advanced talks to buy Lumentum (D1; not an issuer release), an acquisition-dilution/overpay risk, a different thesis from last week's. (c) FQ3 **2026-12-01 (E)** (Nasdaq). (d) Already queued. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-12-01)
- **26. DELL - Dell Technologies.** (a) Bullish. (b) AI-server capex; Barclays downgrade 10-14 (note not read); SMCI's raised outlook is a counter-datapoint; Nasdaq EPS $6.41. (c) **2026-11-24 (E)** (Nasdaq). (d) Already queued. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-11-24)
- **27. HPE - Hewlett Packard Enterprise.** (a) Bullish; as DELL. (c) **2026-12-03 (E)** (Nasdaq). (d) Already queued. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-12-03)
- **28. NTAP - NetApp.** (a) Bullish. Barclays downgrade 10-14. (c) **2026-12-01 (E)** after hours (Nasdaq; moved from 11-24). (d) Already queued. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-12-01)
- **29. CRWD - CrowdStrike.** (a) Bullish; module attach. (c) **2026-12-01 (E)** (Nasdaq). (d) Already queued. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-12-01)
- **30. CRM - Salesforce.** (a) Bullish; agentic-AI attach vs compressed multiple. Software-group risk: NOW -26.95% on an agentic-attach thesis is direct counter-evidence for CRM's same framing. (c) **2026-12-02 (E)** (Nasdaq). (d) Already queued. (e) conviction 2 (watch). GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-12-02)

### 31-40

- **31. PANW - Palo Alto Networks.** (a) Bullish; platformisation; FTNT -20% is a peer-security counter-datapoint. (c) FQ1 FY27 **2026-11-18 (E)** (Nasdaq). (d) Already queued. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-11-18)
- **32. OKTA - Okta.** (a) Bullish. (c) **2026-12-01 (E)** (Nasdaq). (d) Already queued. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-12-01)
- **33. SNOW - Snowflake.** (a) Bullish; Cortex AI monetisation; dilution evidence carried ($3.5B convertible 09-28). (c) **2026-12-02 (E)** (Nasdaq). (d) Already queued. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-12-02)
- **34. INTU - Intuit.** (a) Bullish. (c) **2026-11-19 (E)** (Nasdaq, EPS $2.47). (d) Already queued. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-11-19)
- **35. MU - Micron.** (a) Bullish; new thesis is guidance durability after the 09-30 print; SK hynix +13.3% 10-28 supports memory pricing; adverse: CXMT server-DRAM push. (c) FQ1 **2026-12-16 (E)** (Nasdaq; moved from 12-23). (d) Already queued; the queue row cites the consumed 09-30 print and is stale. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-12-16)
- **36. NBIS - Nebius.** (a) Bullish; neocloud capacity; NBIS -5.68% in the 10-29 AI-infra cluster; CoreWeave credit stress and the OpenAI training pause are counter-evidence. (c) **2026-11-10 (E)** (Nasdaq). (d) Already queued. (e) conviction 1-2. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-11-10)
- **37. MRNA - Moderna.** (a) Bullish; NYT vaccine report (D1 10-09) carried as adverse. (c) **2026-11-06 (E)** pre-market (Nasdaq, FMP). (d) NOT on the A queue. (e) conviction 1-2. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-11-06)
- **38. JPM - JPMorganChase.** (a) Bullish. 10-13 print missed (EPS 5.75 vs 5.93). (c) **2027-01-14 (E)** (FMP); Investor Day 2027-02-22 (C, carried). (d) Already queued; the `spent_by_gate_likely` payload is stale. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2027-01-14)
- **39. META - Meta Platforms.** (a) Bullish, reduced. Printed 10-21 (capex floor $135B+, negative FCF, $9.89B legal charge, Class C shares from January 2027); the 10-29 hyperscaler prints (AWS +39.3%, MSFT beat) are mild support for the spend-returns debate. (c) **2027-01-27 (E)** (FMP). (d) Already queued. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2027-01-27)
- **40. GE - GE Aerospace.** (a) Bullish. Printed 10-20 (EPS 2.25 vs 2.01; revenue $14.12B vs $12.88B); fuel-shock exposure the counter. (c) **2027-01-21 (E)** (FMP). (d) NOT on the A queue. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2027-01-21)

### 41-50

- **41. LLY - Eli Lilly.** (a) Bullish. Printed 10-29: non-GAAP EPS $7.48 vs $5.38 (includes $4.57 IPR&D), revenue $24.4B, 2026 revenue guide raised $5.5B to $91-92B; +6.63% on 10-29 (1288.3 to 1373.7, Daily). Print consumed; no new dated catalyst. (c) Next print **undated** (early February INFERRED). (d) Already queued. (e) conviction 2 (down: the market already re-rated). GATE: GATE-SURVIVING (gate 2026-11-01; catalyst undated)
- **42. XOM - ExxonMobil.** (a) Bullish. Printed 10-30: beat (above). Print consumed. (c) Next **2027-01-29 (E)** (FMP). (d) Already queued. (e) conviction 2 (down from 2: the shock thesis is the same, but the 10-30 beat is priced; COP carries the seam). GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2027-01-29)
- **43. CVX - Chevron.** (a) Bullish. Printed 10-30: EPS 5.28 vs 4.87. Print consumed; same seam as XOM/COP. (c) Next **2027-01-29 (E)** (FMP). (d) Already queued. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2027-01-29)
- **44. INTC - Intel.** (a) Bullish. Printed 10-29: EPS 0.52 vs 0.4066, revenue $16.5B (+21%), Q4 guide $15.0-16.0B; foundry-turnaround optionality. Print consumed. (c) Next **2027-01-28 (E)** (FMP). (d) Already queued. (e) conviction 1-2. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2027-01-28)
- **45. CAT - Caterpillar.** (a) Bullish. Printed 10-29: adj EPS $7.20 vs $7.12, revenue $20.7B; -9.25% (713.38 to 647.39, Daily) on an in-line beat. Gap hypothesis (INFERRED): the drop reflects guidance or margin items not read here. FTC/USDA farm-equipment RFI (10-07) overhang. (c) Next print **undated** (late January/early February INFERRED). (d) Already queued. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst undated)
- **46. GEV - GE Vernova.** (a) Bullish. Printed 10-28; D1 10-28 read it as strengthened conviction for the D lot (878.03 to 887.85 on 10-29, +1.12%). Print consumed; GLJ Sell ($470) carried. (c) Next print **undated** (late January INFERRED). (d) Already queued; **open Strategy D lot**. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst undated)
- **47. NOW - ServiceNow.** (a) Bullish, **thesis contradicted by the print**: -26.95% (150.13 to 109.67) on the 10-28 after-close results; FTNT -20.09% the same night; the "agentic attach under-credited" thesis was the print. Kept only because a post-crash entry could be a gap thesis if documents show a one-time cause; otherwise drop at next refresh. (c) Next print **undated** (late January INFERRED). (d) Already queued. (e) conviction **1**. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst undated)
- **48. SNDK - Sandisk. NEW (preliminary).** (a) Bullish. (b) Fiscal-Q1 FY2027 non-GAAP EPS $49.51 vs $46.19 on $11.0B revenue (EDGAR 8-K via Daily.md, 10-29 after close); SK hynix +13.3% on 10-28 as a memory read-through (D1). Gap hypothesis (INFERRED, weak): NAND pricing durability under-credited; the 10-29/30 reaction was -5.3% per Daily's "A29" list (ambiguous timing). Documents to pull: 8-K Ex-99.1 guide, 10-Q. Counter-evidence: memory-cycle peak risk (MU -4.98% on 10-29 in the AI-infra complex). (c) Next print **undated** (late January INFERRED). (d) **NOT on the A queue; new intake.** (e) conviction **1**. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst undated)
- **49. RDDT - Reddit. NEW (preliminary).** (a) Bullish. (b) Q3 diluted EPS $1.40 vs $1.31, revenue $895M (+53%) (EDGAR 8-K via Daily.md). Gap hypothesis (INFERRED, weak): ad-revenue growth and AI-licensing durability under-credited. No price read taken; documents to pull: the 8-K, last four transcripts. (c) Next print **undated** (early February INFERRED). (d) **NOT on the A queue; new intake.** (e) conviction **1**. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst undated)
- **50. TGT - Target.** (a) **DIRECTION UNRESOLVED**: prior bearish thesis refuted by a beat-and-raise, no replacement; ineligible for the top-10 until a direction is set. (c) Earnings **2026-11-18 (C)** (corporate.target.com, carried; Nasdaq pre-market, EPS $2.08, 12 estimates). (d) Already queued. (e) conviction 1. GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-11-18)

### DIRECTION-INADMISSIBLE tier

Belong to Strategy B. The rail governs only admission to the actionable tier. None is in the top-10; none may be converted to an A `PENDING_ANALYSIS` row.

| # | Ticker | (a) Direction | (b) Documents / this week's re-test | (c) Catalyst | (d) Queue | (e) Tier / conviction | Gate literal |
|---|---|---|---|---|---|---|---|
| I-1 | **UAL** | Bearish | Fuel-shock channel; Brent 116.72 peak to ~111.6 weakens, does not reverse | Printed 10-20; next **2027-01-19 (E)** (FMP) | Not queued | Inadmissible, 2 | GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2027-01-19) |
| I-2 | **AAL** | Bearish | Thinnest balance sheet; same fuel seam | Printed 10-22; next **2027-01-26 (E)** (FMP) | Not queued | Inadmissible, 2 | GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2027-01-26) |
| I-3 | **DAL** | Bearish | First airline to report; same seam | Printed 10-09; next **2027-01-12 (E)** (FMP) | Not queued | Inadmissible, 2 | GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2027-01-12) |
| I-4 | **CCL** | Bearish | Bunker-fuel channel | Earnings **2026-12-18 (E)** (FMP) | Not queued | Inadmissible, 2 | GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-12-18) |
| I-5 | **AMAT** | Bearish, **weakened/unresolved** | China WFE cliff after the 10-13 Investor Day (-6.69%) now contested: LRCX record quarter, SK hynix +13.3% on 10-28, AMAT +3.4% on the week; -7.5% on 10-30 unexplained; D2 re-test before any thesis | Earnings **2026-11-12 (C)** after hours (issuer notice per 1B.2; Nasdaq EPS $4.06, 10 estimates) | On queue | Inadmissible, 1-2 | GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-11-12) |
| I-6 | **WMT** | Bearish, thinner | Low-income consumer; staples bid is contrary; no new evidence this week | Earnings **2026-11-19 (C)** pre-market (Nasdaq EPS $0.64, 12 est.; FMP 11-19) | On queue | Inadmissible, 1-2 | GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-11-19) |
| I-7 | **ADBE** | Bearish, stronger | Vindicated on tape; software sell-off (NOW -26.95%, FTNT -20.09%) on AI-disruption fears | Earnings **2026-12-09 (E)** (Nasdaq, FMP); MAX 11-10..12 (E) | On queue | Inadmissible, 2 | GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-11-10) |
| I-8 | **HD** | Bearish / neutral | Housing turnover starved; no new evidence this week | Earnings **2026-11-17 (E)** pre-market (Nasdaq EPS $3.86, 11 est.) | On queue | Inadmissible, 1-2 | GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-11-17) |
| I-9 | **AKAM** | Bearish / contested | Smallest cap in the file | Earnings **2026-11-05 (C)** after hours (Nasdaq EPS $0.92, 9 est.) | On queue | Inadmissible, 1 | GATE: GATE-SURVIVING (gate 2026-11-01; catalyst 2026-11-05) |

**W4 side, restated because it binds:** no `DIRECTION-INADMISSIBLE` candidate may be converted into an A `PENDING_ANALYSIS` row; a vacated slot is filled from the next admissible candidate. AMAT, WMT, ADBE, HD, AKAM are already on the A queue; D2 applies the rail to any thesis run on them.

### Handoff notes for W4

- **Top-10 versus the 46-row census (brief):** ALREADY QUEUED: VRTX, TTWO, FSLR, COP, ANET, AAPL, AMD, NVDA, AVGO, CSCO (all ten; COP and ANET were the 2026-W43 intakes). NOT queued, new intake only if W4's limb reaches past tier 1: LRCX, CEG, ETN, PLTR, UBER, SHOP, DIS, MRNA, GE, SNDK, RDDT; plus inadmissible UAL, AAL, DAL, CCL.
- **Already queued but outside the top-10:** QCOM, GOOGL, MSFT, AMZN, SMCI, ORCL, DDOG, MRVL, DELL, HPE, NTAP, CRWD, CRM, PANW, OKTA, SNOW, INTU, MU, NBIS, JPM, META, LLY, XOM, CVX, INTC, CAT, GEV, NOW, TGT, MRK. Census members not ranked in this file: IBM (dropped, no forward catalyst), MRK (dropped), plus the inadmissible AMAT, WMT, ADBE, HD, AKAM.
- **SPENT in the top-10: zero; SPENT overall: zero** (gate = run date 2026-11-01). Names ON or one session after the gate (VRTX, AAPL, PLTR; AMD, ANET, SHOP, SMCI, ETN) survive by one session; the gate may move.
- **Tier changes versus 2026-W43:** MSFT 11 to 15, AMZN 12 to 16 (thesis consumed, no new catalyst); GOOGL 41 to 14 (print occurred; 10-29 -12.6% creates a gap hypothesis; two D lots); XOM 46 to 42, CVX 47 to 43, INTC 50 to 44, CAT 48 to 45, GEV 44 to 46, LLY 49 to 41 (all re-dated from spent to surviving on next print/undated); NOW 45 to 47 conviction 1 (thesis contradicted); COP 6 to 4 and ANET 5 stay 5 (COP up on peer beats); NVDA 4 to 8 and AMD 9 to 7 (reordered after the lower-conviction names moved; both still 3); QCOM 13 to 11; CEG 18 to 13; MRK 42 and V 38 dropped (reasons in STEP 3); SNDK, RDDT new at 48, 49; PLTR 15 to 19, UBER 17 to 20, ORCL 16 to 21, SMCI 19 to 18, ETN 20 to 17. IBM remains dropped (printed 10-21; no forward catalyst; still on the A queue).
- **Stale queue-row payloads to overwrite:** JPM `spent_by_gate_likely` (stale); MU row cites the consumed 09-30 print (live catalyst 2026-12-16 (E)); TTWO row's FQ2 date should read 11-09 (E); NTAP now 12-01, CEG 11-09, AVGO 12-10; MRK and V rows (not ranked) carry a spent print.
- **Cross-strategy overlap:** only Strategy D is open (AMZN, DIS, ISRG, TSM, RTX, GOOGL, GEV, UBER); no A or C position, so no A/C conflict. A-candidate tickers with open D lots: AMZN (#16), GOOGL (#14), GEV (#46), DIS (#24), UBER (#20).
- **Re-check next cycle:** whether the 10-30 chip selloff (AMD, QCOM, ANET, AVGO, NVDA) has an issuer or macro cause; AAPL/VRTX/PLTR prints (11-02) and AMD/ANET/SMCI/ETN/SHOP (11-03) as the first reads; Take-Two notice of the 11-09 date and any GTA VI date statement; GOOGL charge vs operating split; NOW post-crash documents; Brent versus COP's 11-05 print; Nasdaq next-print dates for LLY, CAT, GEV, NOW, LRCX, SNDK, RDDT.

### REPORT IT — CATALYST-GATE MODE

- **Gate date: 2026-11-01.** Inputs: (a) next scheduled re-score 2026-11-02 (completed `M1a` = 0, `M1b` = 0 this month); (b) no open `regime-refresh` item; (c) REFRESH REQUEST returned `shock_price_leg_exit` (trigger_run_start 2026-10-29) → D2a run 2026-11-01. A reads DO-NOT-ACTIVATE; mode live.
- **Counts:** 59 carried (50 ranked admissible incl. direction-unresolved TGT + 9 DIRECTION-INADMISSIBLE); **0 SPENT-BY-GATE, 59 GATE-SURVIVING.** Zero SPENT because the gate equals the run date and no candidate has a dated catalyst before 2026-11-01 without a later one after re-dating the 10-26..10-30 printers to their next print.
- **Undated survivors (fail-open): 7** (LRCX, LLY, CAT, GEV, NOW, SNDK, RDDT). Next dates are late-January/early-February by pattern, INFERRED and unsourced; they should be re-dated when Nasdaq/FMP publish them.
- **Re-dated from spent to dated-surviving:** XOM, CVX (2027-01-29 E), INTC (2027-01-28 E), MSFT (2027-01-27 E / Ignite 11-17), AMZN (re:Invent 11-30 / 2027-02-04), GOOGL (2027-02-03 E), META (2027-01-27 E).
- **Narrowest survivors:** VRTX, AAPL, PLTR (11-02); AMD, ANET, SHOP, SMCI, ETN (11-03).
- **Research-cost:** tiers 11-50 carry full (a)-(e) with terse carry-forward (b).

## PART 2C — Strategy C ranked shortlist

### Router state, and what it admits

C reads **HYBRID ACTIVATE (FOMC-only)** (`state.current_regime` STRATEGY_ACTIVATION, as_of 2026-10-06; per the run context). Under it **only an FOMC-type event is router-admissible** (FOMC event class affirmative; the corporate-earnings and FDA PDUFA classes are DNA). Earnings and PDUFA candidates stay **router-PARKED / DNA-blocked** and must not be enqueued; they are ranked for the divergence record and for the day C is widened. A, B, D and E all read DO-NOT-ACTIVATE.

`state.open_queue` strategy C returns **one row** (MEASURED 2026-11-01): `thesis-FOMC-C-20261130` (thesis-construction, ticker FOMC, status PENDING_ANALYSIS, due **2026-11-30**), queued by W4 2026-W43. Its conservative default is "decline, no entry" unless an affirmative, sourced, quantified divergence is established; last permitted entry day is 2026-12-08 (criterion 5). Δ vs last week: the 10-28 meeting has passed (held, funds 3.75-4.00%) and the 12-09 meeting now has its queued thesis. **W4 should not create a duplicate FOMC row** ("one FOMC row per meeting").

One router-eligible event sits in the window: **FOMC 2026-12-09** (day 39 of the window counting 11-01 as day 1; no longer at the inclusive edge as it was last week).

### The capital position (MEASURED 2026-11-01)

Same query path as last week (`analytics.strategy_nav`, `state.nomadic_borrow_capacity_watch`, `state.open_queue`):

| Field | Value |
|---|---|
| `analytics.strategy_nav` C: deposits / NAV / available_funds | **$18.56 / $18.56 / $18.56** |
| realized P&L, unrealized P&L, deployed_mv, dividends | $0 each |
| `sizing_base_2pct` | $0.37 |
| `state.nomadic_borrow_capacity_watch` C | donor_capacity_total 0, donor_count 0, `borrow_blocked` TRUE |
| `state.open_queue` strategy C | 1 row (`thesis-FOMC-C-20261130`) |
| Open C positions | none (open positions are Strategy D only, per run context) |

**Δ vs 2026-10-25: NAV and deposits $19.48 → $18.56 (−$0.92) with realized, unrealized and deployed all $0.** MEASURED and RECONCILED by the orchestrator: `events.cash_flows` `6cc95cbc` (flow_date 2026-10-23, `external_withdrawal`, −0.92) is C's pro-rata share of the 600.00 external withdrawal `wd-2026-10-23` (confirmed by D2a 2026-10-26). Ledger movement, not trading P&L.

**Per-thesis no-ceiling sizing discipline (Rev 43/19):** no numeric ceiling, but max loss (including the cascade term) must not exceed the thesis's stated risk budget; a long debit structure's max loss equals its debit. With a whole portfolio of $18.56, no budget above $18.56 is fundable, so the test is whether the cheapest defined-risk structure debits at or below $18.56. Credit spreads, iron condors and butterflies need collateral of width less credit (≥ ~$100 per 1-wide SPY spread) and are unfundable; borrow is blocked. **Every candidate below is a deferral at current NAV.**

### Criterion 1 (a qualifying event within 45 days)

- **FOMC 2026-12-09 (C)** — federalreserve.gov calendar, re-fetched this run by the PART 1B.1 sub-agent (meeting 12-08/09 "Scheduled", SEP meeting). Clear.
- **Earnings (router-PARKED):** window 11-01 → 12-16. Source of dates this run: the Nasdaq per-day calendar (`time-after-hours` / `time-pre-market` = announced; `time-not-supplied` = projected, tagged (E)). Issuer-IR confirmation was NOT re-done this run for any name; last week's IR confirmations (AMD, VRTX, UBER, PLTR) are carried, AAPL stays secondary-relay, NVDA vendor-only.
- **PDUFAs (router-PARKED):** SMMT ivonescimab 11-14 (C, carried), VRTX povetacicept 11-30 (C, carried); neither re-verified this run. INO 10-30 has passed (outcome not checked).

### The tenor rail — CLEAR, seventh cycle running

C requires structure expiration within 1-45 days of entry. MEASURED from the live SPY option parameters (IBKR underlying 756733): listed expiries are 11-02, 11-03, 11-04, 11-05, 11-06 (SPY and B1SPY), **11-09, 11-10, 11-11, 11-12, 11-13, 11-16 (new daily/weekly fill)**, 11-20 (regular, 2SPY, B1SPY), 11-27, 11-30, 12-04, **12-11 (new; SPY, 2SPY, B1SPY)**, 12-18 (regular), 12-31, then monthlies into 2027.

- **FOMC 12-09:** 12-09 is the event day (statement 2 pm ET) and an expiry on it would not be strictly after the event; no 12-10 expiry lists yet. **First listed expiry strictly after the event is now 12-11** (2 calendar days after; was 12-18 last week). From a 12-01 entry that is 10 days, from the last permitted entry day 12-08 it is 3 days — inside 1-45 either way. Criterion 5 (entry ≥ 1 trading day before) is met by any entry through Tuesday 12-08. A 12-10 expiry may list later and would shorten it further.

### Criterion 2 (implied vs realized) — MEASURED on the spec window (trailing 30 days)

Headline is **IV/HV30** per `strategy/05_strategy_c.md`; HV10 and HV20 are context. Realized vol = annualized close-to-close, log returns, sample stdev × √252, from **IBKR regular-session daily bars** (`outside_rth` false, THREE_MONTHS), last close **Friday 2026-10-30**. HV30 = 30 returns over 31 closes (09-17 → 10-30); HV20 = 21 closes; HV10 = 11 closes. This run closes the Friday price half that D1 does not cover. Option quotes: IBKR, last trades/book 2026-10-30 (market closed; Friday close book). `implied_vol` on contracts was `is_valid` TRUE on every contract used.

**FOMC instrument: SPY (as last week).** Contract: SPY 2026-12-11 756 call; IV **15.917%** (valid); `implied_vol_underlying` (30-day constant maturity) 15.698%; IBKR broker `historical_vol` 10.81% (context, method undisclosed). SPY closed 755.72 on 10-30 (−1.77% on the day, −0.56% on five sessions; 10-23 close was 759.97).

| SPY window | Closes (returns) | Realized vol | IV/HV (contract 15.917%) | IV/HV (underlying 15.698%) |
|---|---|---|---|---|
| **HV30 (spec)** | 31 (30) | **11.32%** | **1.41** | 1.39 |
| HV20 | 21 (20) | 11.64% | 1.37 | 1.35 |
| HV10 | 11 (10) | 13.42% | 1.19 | 1.17 |

Δ vs last week (10-23 basis): HV30 10.37 → 11.32, contract IV 16.36 → 15.92 (different expiry), headline ratio **1.58 → 1.41**. Implied is still rich to HV30 but the premium **narrowed**; HV10 (13.42%) above HV30 shows realized accelerating into Friday's −1.77%. Caveats. (1) The 12-11 expiry spans ~42 days, only two of them after the event, so its IV is mostly non-event time and the ratio is NOT event-isolated; the implied-move comparison (≈4.3% vs realized-equivalent ≈3.1% over 42 days, 0.8·σ·√(T/365)) is derived, not a quoted straddle. (2) SPY option bid/ask returned empty (closed market) and the 756 call/put `last` values (25.82 / 8.87) are stale closes that fail put-call parity, so **no SPY debit-spread or straddle price is claimed for 12-11**; a live in-session read is required before any trade. (3) HV is close-to-close and excludes overnight gaps. (4) The 12-09 thesis is queued (`thesis-FOMC-C-20261130`) and D2 judges criterion 2 on 11-30; nothing here is a GO path.

**Cheapest defined-risk SPY structure for 12-09:** NOT MEASURED this run (no tradable quotes). Last week's measured 1-wide 10-30-expiry debit spreads cost $47 (put) / $65 (call) at the natural; a 12-11 expiry holds more time value and would debit more. Against NAV $18.56 every such structure is a shortfall of at least ~$28 (INFERRED from last week's lower-bound cost). **Deferral stands.**

**Panel — ATM straddle on the first expiry spanning each event** (IBKR Friday 10-30 close book; straddle mid = call mid + put mid; implied move = straddle mid / spot; realized-equivalent = 0.8 × HV30 × √(T/365), T calendar days from 10-30). All router-PARKED; pricing measurement only, not a divergence finding.

| Name | Event (tag) | Expiry (T) | Spot | Strike | Straddle mid ($/contract) | Contract IV | HV30 / HV20 / HV10 | IV/HV30 | Implied move vs realized-equiv. | Quote quality |
|---|---|---|---|---|---|---|---|---|---|---|
| SPY | FOMC 12-09 (C) | 12-11 (42) | 755.72 | 756 | not quoted (derived ≈4.3% over 42 d) | 15.92% | 11.3 / 11.6 / 13.4 | **1.41** | ≈4.3% vs 3.1% (derived) | no bid/ask (closed) |
| AAPL | earnings 11-02 AMC (C-secondary) | 11-04 (5) | 344.63 | 345 | 14.95 ($1,495) | 46.09% | 16.4 / 14.5 / 17.5 | **2.81** | 4.34% vs 1.53% | tight (7.30/7.65 put; call 7.40 last) |
| AMD | earnings 11-03 AMC (C) | 11-04 (5) | 504.80 | 505 | 44.98 ($4,498) | 94.57% | 66.1 / 68.9 / 86.9 | 1.43 | 8.91% vs 6.19% | moderate (call 22.05/22.85, put 22.10/22.95) |
| PLTR | earnings 11-02 AMC (C) | 11-06 (7) | 184.11 | 185 | 24.475 ($2,448) | 120.55% | 44.4 / 51.0 / 50.8 | **2.72** | 13.29% vs 4.91% | tight |
| NVDA | earnings 11-17 AMC (Nasdaq; NVIDIA unconfirmed) | 11-20 (21) | 204.64 | 205 | 19.00 ($1,900) | 48.45% | 29.6 / 32.5 / 38.8 | 1.64 | 9.28% vs 5.68% | tight; 21-day expiry also holds ~2 weeks of non-event time |
| UBER | earnings 11-04 pre (C) | 11-06 (7) | 65.25 | 65 | 5.255 ($526) | 71.69% | 24.6 / 27.7 / 23.6 | **2.92** | 8.05% vs 2.72% | tight |
| VRTX | earnings 11-02 AMC (C) | 11-06 (7) | 558.88 | 560 | not reliable (call 12.10/18.00, put 12.50/20.10) | 50.83% | 27.4 / 30.6 / 27.2 | 1.86 | ≈5.6% vs 3.0% (derived from IV) | **wide**, stale last prints |
| WMT | earnings 11-19 pre (Nasdaq; not IR-checked) | 11-20 (21) | 123.51 | 124 | 9.00 ($900) | 37.58% | 23.6 / 20.5 / 21.5 | 1.59 | 7.29% vs 4.53% | tight |

Reads. Implied is rich to HV30 across the panel, richest on UBER (2.92), AAPL (2.81) and PLTR (2.72); leanest on AMD (1.43) and SPY (1.41). AMD's HV30 is already 66% and HV10 87% after a **−10.88% Friday** (504.80); PLTR −6.27%, NVDA −4.22% and SPY −1.77% on the same day (an AI/semis risk-off Friday; the 10-30 narrative driver was NOT researched this run, INFERRED only). Ratios for the mega-caps (AAPL HV30 16%) are inflated versus an ordinary quarter by calm windows. These ratios are "richness", not a statement that the market is wrong about direction. Straddle mids here match the 0.8·IV·√T approximation within ~0.1 pp where both exist.

Δ vs last week's panel: AAPL 2.07 → 2.81, AMD 1.18 → 1.43, NVDA 1.51 → 1.64 (all richer: IV rose into the prints while HV30 fell or held), SPY 1.58 → 1.41.

### Ranked shortlist — 15 event candidates

Changes vs last cycle's 15: **struck as passed:** FOMC 10-28, MSFT, GOOGL, AMZN, LLY, XOM (10-28 → 10-30 prints), INO PDUFA (10-30). **Carried:** FOMC 12-09, AAPL, AMD, PLTR, NVDA, UBER, VRTX (earnings and PDUFA), SMMT PDUFA. **Added:** WMT, ANET, CRM, AVGO, MU, ORCL (new window events). **Moved:** FOMC 12-09 to rank 1 (only router-admissible item, thesis queued). Direction in every row is the divergence between the options market and a no-event realized baseline; W1 does not establish a directional view. Ranking is by router admissibility, then event proximity, market cap and measured IV/HV30; not by edge.

**TOP-5**

**1. FOMC 2026-12-09 (C, SEP meeting) — the only router-admissible candidate** — (a) No directional divergence established by W1. Measurable divergence is volatility: SPY IV/HV30 **1.41** (contract) / 1.39 (underlying), implied rich but narrower than the 1.58 of last week; favors premium selling, which C cannot fund. Context (carried from last cycle, not re-fetched): policy hawkish, Fed held 10-28 at 3.75-4.00%; hike risk was characterized as concentrated at the SEP meeting by secondary sources (INFERRED). (b) federalreserve.gov calendar; the SEP/statement is a primary document published on the day. (c) **2026-12-09 (C).** First listed SPY expiry after it: 12-11. (d) **NOT executable at current capital: DEFERRAL** (NAV $18.56; 12-11 spread cost not measured, ≥ ~$47 inferred; borrow blocked). (e) No open A positions (none). (f) **Top-5, rank 1.** **Disposition:** the thesis row `thesis-FOMC-C-20261130` is already queued (due 11-30); W4 must not duplicate it.

**2. AAPL — earnings 2026-11-02 after close (C-secondary)** — (a) Implied rich: 4.34% implied move vs 1.53% realized-equivalent (IV/HV30 **2.81**); calmest HV30 of the panel (16.4%). (b) Apple IR/10-Q not read this run; Nasdaq lists the date with an after-hours time. (c) 2026-11-02 AMC; first expiry after 11-04 (note 11-03 is not listed for AAPL). (d) **Deferral** (straddle $1,495; cheapest single ATM leg ≈ $740). (e) A-queue member; no open A (none open). (f) Top-5. **Router-PARKED.**

**3. AMD — earnings 2026-11-03 after close (C)** — (a) Implied 8.91% vs 6.19% realized-equivalent (IV/HV30 1.43); HV10 86.9% after the −10.88% Friday; realized is already extreme. (b) AMD IR (carried); filings not read this run. (c) 2026-11-03 AMC; expiry 11-04. (d) **Deferral** (straddle $4,498). (e) A-queue member; no open A. (f) Top-5. **Router-PARKED.**

**4. PLTR — earnings 2026-11-02 after close (C)** — (a) Implied move 13.29% vs 4.91% realized-equivalent (IV/HV30 **2.72**), the largest implied move on the panel; stock −6.27% Friday (184.11). (b) Palantir IR (carried); filings not read. (c) 2026-11-02 AMC; expiry 11-06. (d) **Deferral** (straddle $2,448). (e) not on the 46-name A-queue census; none open. (f) Top-5. **Router-PARKED.**

**5. NVDA — earnings 2026-11-17 (C) after close (issuer notice per 1B.2; was 11-18 (E) last week)** — (a) Implied 9.28% vs 5.68% (IV/HV30 1.64); stock −4.22% Friday (204.64). (b) NVIDIA date confirmed by the PART 1B.2 issuer check this run; date moved a day versus last week's estimate (Δ). (c) 2026-11-17 AMC (vendor-announced time, issuer unconfirmed); expiry 11-20. (d) **Deferral** (straddle $1,900). (e) A-queue member; no open A. (f) Top-5. **Router-PARKED.**

**REST (6-15)** — all **router-PARKED**; all deferrals at C NAV $18.56.

| # | Candidate | (a) Direction of divergence | (c) Date (tag) | (d) Executability at C $18.56 | (e) A overlap | IV/HV30 |
|---|---|---|---|---|---|---|
| 6 | **UBER** earnings | Implied rich: 8.05% vs 2.72%; richest ratio measured | 2026-11-04 pre-market (C) | Deferral (straddle $526; single ATM leg ≈ $255-270) | none for A; **open D position (x1)** | **2.92** |
| 7 | **VRTX** earnings | Implied ≈5.6% vs 3.0% (derived; quotes wide 12.10/18.00) | 2026-11-02 AMC (C) | Deferral (stock $558.88; call ask 18.00 alone ≈ NAV) | A-queue member; no open A | 1.86 |
| 8 | **VRTX** PDUFA povetacicept / IgAN | Binary regulatory outcome (accelerated approval) | 2026-11-30 (C, carried) | Deferral (chain beyond 11-06 not measured) | A-queue member; no open A | not measured |
| 9 | **SMMT** PDUFA ivonescimab BLA | Binary; company states FDA wants an OS benefit | 2026-11-14 (C, carried) | Deferral (chain not measured; Saturday date, decision may land earlier) | none | not measured |
| 10 | **WMT** earnings | Implied 7.29% vs 4.53% | 2026-11-19 pre-market (Nasdaq; not IR-checked) | Deferral (straddle $900; single ATM leg ≈ $430-460) | WMT in A-queue; no open A | 1.59 |
| 11 | **ANET** earnings | Not measured | 2026-11-03 AMC (Nasdaq) | Deferral (not measured; large cap) | A-queue member (ANET); no open A | not measured |
| 12 | **CRM** earnings | Not measured | 2026-12-02 (E, time-not-supplied) | Deferral (not measured) | A-queue member; no open A | not measured |
| 13 | **AVGO** earnings | Not measured | 2026-12-10 (E) | Deferral (not measured); falls the day after the FOMC | A-queue member; no open A | not measured |
| 14 | **MU** earnings | Not measured | 2026-12-16 (E), last day of window | Deferral (not measured); edge of the window, expiry would be after 12-16 | A-queue member; no open A | not measured |
| 15 | **ORCL** earnings | Not measured | 2026-12-09 (E), **same day as the FOMC (confounded)** | Deferral (not measured) | A-queue member; no open A | not measured |

Also in window but not ranked (still in PART 1B): CSCO 11-11 (E), HD 11-17, PANW 11-18 (E), LOW/TGT 11-18, INTU 11-19 (E), DELL/ADSK 11-24 (E), DE 11-25, MRVL 12-01 (E), SNOW 12-02 (E), ADBE 12-09 (E), COST 12-10 (E), LULU 12-10 (E).

**(e) A-vs-C exclusivity is vacuous this cycle.** `state.current_positions` holds Strategy D only (AMZN, DIS, ISRG, TSM, RTX, GOOGL, GEV, UBER); zero open A or C rows (per run context). A-queue membership above is from the run context's 46-name census.

**Price half of Friday 2026-10-30 (IBKR regular-session bars).** SPY 755.72, AAPL 344.63, AMD 504.80, PLTR 184.11, NVDA 204.64, UBER 65.25, VRTX 558.88, WMT 123.51.

**Shortlists only.** Full thesis construction per Strategy.md happens in sessions W4 schedules. Nothing here authorizes an enqueue for any parked name. Measurement coverage: IV/HV30 measured for 8 names (SPY plus AAPL, AMD, PLTR, NVDA, UBER, VRTX, WMT), including all top-5; ANET, CRM, AVGO, MU, ORCL and the two PDUFAs are unmeasured. Metered calls this run: 0 (IBKR and BigQuery only; `calls_C2.jsonl` is empty by design).

## Coverage, provenance and what this cycle changed

**Read scope.** Weekly cadence. MEASURED or INFERRED is labelled wherever it matters.
- **BigQuery (read-only):** `state.trading_day_today`, `state.current_regime`, `state.current_positions`, `state.open_queue`, `state.open_queue_detail`, `state.market_calendar`, `state.routine_catchup_window`, `state.nomadic_borrow_capacity_watch`, `analytics.strategy_nav`, `events.cash_flows`, `events.decision_log`, `events.queue_events`, `ops.run_log`, `ops.alerts`.
- **Repo:** `strategy/03_strategy_a.md`, `strategy/05_strategy_c.md`, `strategy/01_shared_regime_vocabulary.md`, the Claude_Task_Plan.md W1 slice and shared rules, `Daily.md` (D1 through session 2026-10-29) and the prior `Weekly_Catalyst_Calendar.md` (2026-W43).
- **Live sources:** FMP `calendar/earnings-calendar` (4 chunked calls ≤ 60 days, orchestrator only); the Nasdaq key-less earnings calendar (38 per-day fetches 2026-10-26 → 12-16, orchestrator only, unmetered); IBKR daily bars, option parameters, option data and snapshots (free); Anthropic `web_search` (42) / `web_fetch` (4) — federalreserve.gov, issuer IR/press releases, FDA/sponsor releases; Tavily basic search (1 call, 1 credit). 51 `ops.web_calls` rows in total.

**Orchestration.** Four Sonnet sub-agents did the grunt work: (1) the PART 1A/1B.2 earnings tables, (2) the PART 1A non-earnings catalysts plus 1B.1 FOMC, 1B.3 PDUFA and the macro list, (3) the PART 2A synthesis, (4) PART 2C including the Strategy C IV/HV30 measurements. The orchestrator did itself: both shared pulls (FMP and Nasdaq), passed to the sub-agents as files they did not re-fetch; every BigQuery state read; the STEP 1 gate derivation and the census; and assembly and validation, including all 59 GATE literals checked for format and SURVIVING consistency against the gate. **Corrections applied on review:** (i) the PART 2A and 2C drafts carried seven earnings dates as (E) that the earnings sub-agent upgraded to (C) this run from issuer notices (NVDA 11-17, TTWO 11-09, QCOM 11-04, SMCI 11-03, AMAT 11-12, SHOP 11-03, DIS 11-17); they now agree with 1B.2. (ii) The 2C draft left C's −$0.92 NAV move unexplained; the orchestrator reconciled it to `events.cash_flows` `6cc95cbc` (C's pro-rata share of the 600.00 external withdrawal `wd-2026-10-23`). (iii) The 2C draft's FOMC row said "not re-fetched"; the 1B.1 sub-agent did re-fetch federalreserve.gov this run. (iv) A sub-agent questioned the "45-day" label (11-01 → 12-16 is 46 calendar days inclusive); the label keeps W43's convention (run date + 45 days), stated in the header.

**Catch-up window.** `state.routine_catchup_window` gives `window_days` **6.99** against a weekly 1.5× threshold of 10.5: cadence-normal, no `CATCHUP` token owed.

**The daily-to-weekly boundary, honoured.** Catalysts newly announced 10-26..10-29 were reused from D1's `research-screen` records and `Daily.md`, not re-searched: the EQT/RRC all-stock merger (10-26), the SGRY take-private, ADT deal, the 10-26/27 AI-semis bid on the Anthropic S-1 report, the 10-28 FOMC hold, and the 10-27..10-29 earnings reactions (BA, SOFI, XYL, FFIV, VRT, ORCL, NOW, FTNT, GOOGL, IOVA, ALNY). No second broad news scan was run; web effort went to forward-calendar acquisition, date confirmation and per-candidate documents.

**The FRIDAY-SESSION GAP, closed from IBKR.** D1 has not yet covered Friday 2026-10-30 (structural, by trigger ordering, not a D1 outage). The price half was closed at zero cost from IBKR regular-session bars for the PART 2A priority names and the PART 2C panel. MEASURED: 10-30 was a sharp AI-hardware down day (AMD −10.9%, QCOM −11.1%, ANET −9.6%, AMAT −7.5%, AVGO −5.5%, NVDA −4.2%, PLTR −6.3%; SPY −1.8%). Its cause is NOT established here (one free search and one Tavily basic search found nothing usable); the narrative half is D1's to record on its next fire and is not chased.

**Standing constraints NOT re-alerted:** the FMP earnings-horizon plan cap (`FMP-earn-horizon`); the FMP 90-day span clamp (chunking applied, all chunks ≤ 60 days); the bulk-enumeration plan gate (`6c4004e3`); C's blocked nomadic borrow (`borrow_blocked` TRUE); the Friday boundary gap (`b4e4e563`).

**Open W1 referrals re-checked.** `ops.alerts` holds no unresolved row sourced from or naming W1 (MEASURED 2026-11-01); no referral status line is carried.

**Known residual gaps (carried in the rows):** INO-3107 (PDUFA 10-30) and AGIO mitapivat (goal 11-01) outcomes not found and left unresolved; BEA September personal income/outlays date (10-29 vs 11-04) unconfirmed; the US–China truce extension to 2027-01-10 rests on secondary reporting; the Anthropic S-1 filing is not EDGAR-verified; issuer notices still not found for CSCO, PANW, HD, NBIS, INTU, DELL, MU (all (E)); next-print dates for LLY, CAT, GEV, NOW, LRCX, SNDK, RDDT are unpublished in either vendor pull (GATE literals say `undated`); PART 2A (b) documents for carry-forward names were not re-read this cycle and the two new intakes (SNDK, RDDT) are preliminary; the SPY 12-11 spread cost for the C FOMC structure was not measured (market closed, empty quotes); the investor-day and product-event sweeps are samples, not enumerations.

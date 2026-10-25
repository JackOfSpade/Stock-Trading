2026-W43

# Weekly Catalyst Calendar — Strategies A and C

**Run date 2026-10-25** (Sunday, `weekly_sun`). ISO week of TODAY's run date, 2026-W43. The upcoming trading week opens Monday 2026-10-26; that is context, not the marker.

**Windows.** Strategy A: 6 months, **2026-10-25 → 2027-04-25** — **effective confirmed-earnings horizon 2026-12-18 (54 days, ~7.7 weeks); sparse vendor coverage beyond it, per-name (E) fallback for shortlisted names.** Strategy C: 45 days, **2026-10-25 → 2026-12-09** (inclusive count; the 12-09 FOMC decision sits on day 45).

**EFFECTIVE CONFIRMED-EARNINGS HORIZON: 2026-12-18, 54 days (~7.7 weeks) from 2026-10-25. The terminal date did NOT move for a fourth week** (CCL 2026-12-18). Depth fell 61 → 54 days only because the clock advanced. Eight-week series, terminal date / days from that week's run date: 2026-12-03/88d (09-06), 2026-12-09/87d (09-13), 2026-12-09/80d (09-20), 2026-12-10/74d (09-27), 2026-12-18/75d (10-04), 2026-12-18/68d (10-11), 2026-12-18/61d (10-18), **2026-12-18/54d (10-25)**.

Coverage shape (MEASURED, four chunked FMP `calendar/earnings-calendar` calls, each ≤ 60 days, all by the orchestrator before fan-out):

| Span | Rows | Notes |
|---|---|---|
| Printed 10-19 → 10-24 | 10 | with actuals (UAL, NFLX, GM, GE, TSLA, T, META, NOK, LMT, AAL) |
| 10-25 → 11-23 | 49 | |
| 11-24 → 12-23 | 7 | BABA, NIO 11-24; DOCU 12-03; ADBE 12-09; COST 12-10; NKE 12-17; CCL 12-18 |
| 12-24 → 2027-02-21 | 22 | unchanged shape vs last week (TLRY, DAL … LMT, NOK) |
| 2027-02-22 → 04-25 | 2 | RIVN 02-25, FDX 03-25 |

Dead zones in the FMP feed: 2026-11-25 → 12-02 and 2026-12-19 → 2027-01-10. This is a standing plan-tier constraint (`FMP-earn-horizon`, `OWNER_ACTIONS.md`), deliberately NOT re-alerted.

**Near-term enumeration is now from the Nasdaq key-less per-day calendar** (the ENUMERATION SOURCE PIN), fetched by the orchestrator for every weekday 2026-10-26 → 2026-12-09 (34 fetches, unmetered): **1,669 reporter-rows at market cap ≥ $2B** in the C window, against FMP's 53 rows for the same span. FMP rows are kept as consensus detail for the names they cover. Three FMP rows are absent from Nasdaq (FUBO 11-02, ET 11-03, LCID 11-09). Nasdaq dates without an issuer notice are tagged (E): many carry `time-not-supplied`, which is the signature of a projected, not announced, date.

**Every count in PART 1 beyond the C window is a FLOOR.** Universe enumeration past 2026-12-09 is impossible on this plan tier: `search/search-company-screener`, every `directory.*` route and `quote/batch-quote` are tool-level ACCESS DENIED (`ops.alerts` `6c4004e3`, standing, not re-alerted). The market-cap rail inside the C window is Nasdaq's own `marketCap` field; the 30-day ADV ≥ $10M rail is carried, not re-measured (1A.11).

## PART 1A — Strategy A universe, 6-month window (2026-10-25 → 2027-04-25)

No interpretation in this PART. Provenance tags:
- **(C)** company- or primary-source confirmed
- **(E)** estimated (vendor or aggregator projection)
- **(T)** tentative, no firm day

"Δ" marks a change against the 2026-10-18 artifact. Rows tagged (C) "carried from W42" were issuer-confirmed last cycle and the date still matches; they were NOT re-read this run.

### 1A.1 — Earnings, inside the 45-day C window (2026-10-25 → 2026-12-09)

**Detail table** — every Nasdaq ≥ $2B reporter that is ≥ $50B market cap, on the A queue, held in Strategy D, in the FMP pull, or carried in last week's table (261 rows). Time codes: BMO before open, AMC after close, n/s not supplied. Plus one aggregator-only row: **AVGO** Broadcom (FQ4, AMC) **2026-12-09 (E)**, aggregator, absent from both Nasdaq and FMP.

| Ticker | Name | Type | Date | Tag | Mcap | Source |
|---|---|---|---|---|---|---|
| VZ | Verizon Communications Inc. | Earnings (BMO, FQ Sep/2026) | 2026-10-26 | (E) | $188B | Nasdaq calendar; FMP agrees |
| WELL | Welltower Inc. | Earnings (AMC, FQ Sep/2026) | 2026-10-26 | (E) | $171B | Nasdaq calendar |
| CDNS | Cadence Design Systems, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-10-26 | (E) | $85B | Nasdaq calendar |
| NUE | Nucor Corporation | Earnings (AMC, FQ Sep/2026) | 2026-10-26 | (E) | $59B | Nasdaq calendar |
| PSA | Public Storage | Earnings (AMC, FQ Sep/2026) | 2026-10-26 | (E) | $58B | Nasdaq calendar |
| V | Visa Inc. | Earnings (AMC, FQ Sep/2026) | 2026-10-27 | **(C)** | $740B | Nasdaq calendar; FMP agrees; (C) carried from W42 (investor.visa.com "Visa to Announce Fiscal Fourth Quarter an) |
| KO | Coca-Cola Company (The) | Earnings (BMO, FQ Sep/2026) | 2026-10-27 | (E) | $410B | Nasdaq calendar; FMP agrees |
| HSBC | HSBC Holdings plc | Earnings (n/s, FQ Sep/2026) | 2026-10-27 | (E) | $322B | Nasdaq calendar |
| NVS | Novartis AG | Earnings (BMO, FQ Sep/2026) | 2026-10-27 | (E) | $298B | Nasdaq calendar |
| BA | Boeing Company (The) | Earnings (BMO, FQ Sep/2026) | 2026-10-27 | (E) | $148B | Nasdaq calendar; FMP agrees |
| STX | Seagate Technology Holdings PLC | Earnings (AMC, FQ Sep/2026) | 2026-10-27 | (E) | $147B | Nasdaq calendar |
| SPGI | S&P Global Inc. | Earnings (BMO, FQ Sep/2026) | 2026-10-27 | (E) | $134B | Nasdaq calendar |
| GLW | Corning Incorporated | Earnings (BMO, FQ Sep/2026) | 2026-10-27 | (E) | $107B | Nasdaq calendar |
| HCA | HCA Healthcare, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-10-27 | (E) | $101B | Nasdaq calendar; FMP agrees |
| WM | Waste Management, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-10-27 | (E) | $96B | Nasdaq calendar |
| FCX | Freeport-McMoran, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-10-27 | (E) | $93B | Nasdaq calendar |
| HOOD | Robinhood Markets, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-10-27 | (E) | $87B | Nasdaq calendar; FMP agrees |
| JCI | Johnson Controls International plc | Earnings (BMO, FQ Sep/2026) | 2026-10-27 | (E) | $87B | Nasdaq calendar |
| UPS | United Parcel Service, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-10-27 | (E) | $86B | Nasdaq calendar |
| AMT | American Tower Corporation (REIT) | Earnings (BMO, FQ Sep/2026) | 2026-10-27 | (E) | $85B | Nasdaq calendar |
| SHW | Sherwin-Williams Company (The) | Earnings (BMO, FQ Sep/2026) | 2026-10-27 | (E) | $84B | Nasdaq calendar |
| ECL | Ecolab Inc. | Earnings (BMO, FQ Sep/2026) | 2026-10-27 | (E) | $82B | Nasdaq calendar |
| HLT | Hilton Worldwide Holdings Inc. | Earnings (BMO, FQ Sep/2026) | 2026-10-27 | (E) | $81B | Nasdaq calendar |
| ITW | Illinois Tool Works Inc. | Earnings (BMO, FQ Sep/2026) | 2026-10-27 | (E) | $80B | Nasdaq calendar |
| RCL | Royal Caribbean Cruises Ltd. | Earnings (BMO, FQ Sep/2026) | 2026-10-27 | (E) | $77B | Nasdaq calendar |
| NXPI | NXP Semiconductors N.V. | Earnings (AMC, FQ Sep/2026) | 2026-10-27 | (E) | $60B | Nasdaq calendar |
| OKE | ONEOK, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-10-27 | (E) | $59B | Nasdaq calendar |
| PCAR | PACCAR Inc. | Earnings (BMO, FQ Sep/2026) | 2026-10-27 | (E) | $58B | Nasdaq calendar |
| BKR | Baker Hughes Company | Earnings (AMC, FQ Sep/2026) | 2026-10-27 | (E) | $53B | Nasdaq calendar |
| PYPL | PayPal Holdings, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-10-27 | (E) | $49B | Nasdaq calendar; FMP agrees |
| SOFI | SoFi Technologies, Inc.  | Earnings (BMO, FQ Sep/2026) | 2026-10-27 | (E) | $19B | Nasdaq calendar; FMP agrees |
| GOOG | Alphabet Inc. | Earnings (AMC, FQ Sep/2026) | 2026-10-28 | (E) | $3965B | Nasdaq calendar |
| GOOGL | Alphabet Inc. [A-queue, D held] | Earnings (AMC, FQ Sep/2026) | 2026-10-28 | (E) | $3965B | Nasdaq calendar; FMP agrees |
| MSFT | Microsoft Corporation [A-queue] | Earnings (AMC, FQ Sep/2026) | 2026-10-28 | **(C)** | $3870B | Nasdaq calendar; FMP agrees; (C) carried from W42 (Microsoft release dated 2026-10-07 (PRNewswire dateline "Oct) |
| GEV | GE Vernova Inc. [A-queue, D held] | Earnings (BMO, FQ Sep/2026) | 2026-10-28 | **(C)** | $220B | Nasdaq calendar; (C) carried from W42 (gevernova.com (carried); FMP silent) |
| SAN | Banco Santander, S.A. | Earnings (BMO, FQ Sep/2026) | 2026-10-28 | (E) | $195B | Nasdaq calendar |
| KLAC | KLA Corporation  | Earnings (AMC, FQ Sep/2026) | 2026-10-28 | (E) | $193B | Nasdaq calendar |
| APH | Amphenol Corporation | Earnings (BMO, FQ Sep/2026) | 2026-10-28 | (E) | $180B | Nasdaq calendar |
| TMUS | T-Mobile US, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-10-28 | (E) | $170B | Nasdaq calendar |
| NOW | ServiceNow, Inc. [A-queue] | Earnings (AMC, FQ Sep/2026) | 2026-10-28 | **(C)** | $162B | Nasdaq calendar; (C) carried from W42 (newsroom.servicenow.com 2026-10-07 (carried)) |
| UBS | UBS AG | Earnings (BMO, FQ Sep/2026) | 2026-10-28 | (E) | $145B | Nasdaq calendar |
| BBVA | Banco Bilbao Vizcaya Argentaria S.A. | Earnings (AMC, FQ Sep/2026) | 2026-10-28 | (E) | $142B | Nasdaq calendar |
| FTNT | Fortinet, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-10-28 | (E) | $127B | Nasdaq calendar |
| ADP | Automatic Data Processing, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-10-28 | (E) | $122B | Nasdaq calendar |
| PSX | Phillips 66 | Earnings (BMO, FQ Sep/2026) | 2026-10-28 | (E) | $114B | Nasdaq calendar |
| GSK | GSK plc | Earnings (BMO, FQ Sep/2026) | 2026-10-28 | (E) | $101B | Nasdaq calendar |
| EQIX | Equinix, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-10-28 | (E) | $94B | Nasdaq calendar |
| AEM | Agnico Eagle Mines Limited | Earnings (AMC, FQ Sep/2026) | 2026-10-28 | (E) | $89B | Nasdaq calendar |
| CP | Canadian Pacific Kansas City Limited | Earnings (AMC, FQ Sep/2026) | 2026-10-28 | (E) | $81B | Nasdaq calendar |
| VRT | Vertiv Holdings, LLC | Earnings (BMO, FQ Sep/2026) | 2026-10-28 | (E) | $75B | Nasdaq calendar |
| ORLY | O'Reilly Automotive, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-10-28 | (E) | $74B | Nasdaq calendar |
| FDX | FedEx Corporation | Earnings (AMC, FQ Sep/2026) | 2026-10-28 | (E) | $72B | Nasdaq calendar; FMP agrees |
| AEP | American Electric Power Company, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-10-28 | (E) | $71B | Nasdaq calendar |
| BSX | Boston Scientific Corporation | Earnings (BMO, FQ Sep/2026) | 2026-10-28 | (E) | $67B | Nasdaq calendar |
| AON | Aon plc | Earnings (BMO, FQ Sep/2026) | 2026-10-28 | (E) | $65B | Nasdaq calendar |
| CVNA | Carvana Co. | Earnings (AMC, FQ Sep/2026) | 2026-10-28 | (E) | $65B | Nasdaq calendar |
| TEL | TE Connectivity plc | Earnings (BMO, FQ Sep/2026) | 2026-10-28 | (E) | $60B | Nasdaq calendar |
| GRMN | Garmin Ltd. | Earnings (BMO, FQ Sep/2026) | 2026-10-28 | (E) | $57B | Nasdaq calendar |
| EBAY | eBay Inc. | Earnings (AMC, FQ Sep/2026) | 2026-10-28 | (E) | $54B | Nasdaq calendar |
| HONA | Honeywell Aerospace Inc. | Earnings (AMC, FQ Sep/2026) | 2026-10-28 | (E) | $52B | Nasdaq calendar |
| F | Ford Motor Company | Earnings (AMC, FQ Sep/2026) | 2026-10-28 | (E) | $47B | Nasdaq calendar; FMP agrees |
| ETSY | Etsy, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-10-28 | (E) | $8B | Nasdaq calendar; FMP agrees |
| MGM | MGM Resorts International | Earnings (AMC, FQ Sep/2026) | 2026-10-28 | (E) | $8B | Nasdaq calendar; FMP agrees |
| AMZN | Amazon.com, Inc. [A-queue, D held] | Earnings (AMC, FQ Sep/2026) | 2026-10-29 | **(C)** | $2701B | Nasdaq calendar; FMP agrees; (C) carried from W42 (aboutamazon.com "Amazon will share its Q3 2026 earnings on O) |
| LLY | Eli Lilly and Company [A-queue] | Earnings (BMO, FQ Sep/2026) | 2026-10-29 | **(C)** | $1230B | Nasdaq calendar; (C) carried from W42 (investor.lilly.com (carried); FMP silent) |
| MA | Mastercard Incorporated | Earnings (BMO, FQ Sep/2026) | 2026-10-29 | (E) | $555B | Nasdaq calendar |
| INTC | Intel Corporation [A-queue] | Earnings (AMC, FQ Sep/2026) | 2026-10-29 | (E) | $452B | Nasdaq calendar; FMP agrees |
| MRK | Merck & Company, Inc. [A-queue] | Earnings (BMO, FQ Sep/2026) | 2026-10-29 | **(C)** | $363B | Nasdaq calendar; (C) carried from W42 (merck.com (carried); FMP silent) |
| CAT | Caterpillar, Inc. [A-queue] | Earnings (BMO, FQ Sep/2026) | 2026-10-29 | **(C)** | $324B | Nasdaq calendar; (C) carried from W42 (caterpillar.com "Caterpillar to announce 3Q 2026 financial r) |
| SHEL | Shell PLC | Earnings (BMO, FQ Sep/2026) | 2026-10-29 | (E) | $290B | Nasdaq calendar |
| LIN | Linde plc | Earnings (BMO, FQ Sep/2026) | 2026-10-29 | (E) | $235B | Nasdaq calendar |
| TTE | TotalEnergies SE | Earnings (BMO, FQ Sep/2026) | 2026-10-29 | (E) | $195B | Nasdaq calendar |
| GILD | Gilead Sciences, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-10-29 | (E) | $195B | Nasdaq calendar |
| SNDK | Sandisk Corporation | Earnings (AMC, FQ Sep/2026) | 2026-10-29 | (E) | $183B | Nasdaq calendar |
| BUD | Anheuser-Busch Inbev SA | Earnings (BMO, FQ Sep/2026) | 2026-10-29 | (E) | $169B | Nasdaq calendar |
| BMY | Bristol-Myers Squibb Company | Earnings (BMO, FQ Sep/2026) | 2026-10-29 | (E) | $129B | Nasdaq calendar |
| MO | Altria Group | Earnings (BMO, FQ Sep/2026) | 2026-10-29 | (E) | $127B | Nasdaq calendar |
| SYK | Stryker Corporation | Earnings (AMC, FQ Sep/2026) | 2026-10-29 | (E) | $118B | Nasdaq calendar |
| SBUX | Starbucks Corporation | Earnings (AMC, FQ Sep/2026) | 2026-10-29 | (E) | $116B | Nasdaq calendar; FMP agrees |
| TT | Trane Technologies plc | Earnings (BMO, FQ Sep/2026) | 2026-10-29 | (E) | $99B | Nasdaq calendar |
| ING | ING Group, N.V. | Earnings (BMO, FQ Sep/2026) | 2026-10-29 | (E) | $94B | Nasdaq calendar |
| ICE | Intercontinental Exchange Inc. | Earnings (BMO, FQ Sep/2026) | 2026-10-29 | (E) | $92B | Nasdaq calendar |
| ASX | ASE Technology Holding Co., Ltd. | Earnings (BMO, FQ Sep/2026) | 2026-10-29 | (E) | $84B | Nasdaq calendar |
| MDLZ | Mondelez International, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-10-29 | (E) | $83B | Nasdaq calendar |
| LYG | Lloyds Banking Group Plc | Earnings (BMO, FQ Sep/2026) | 2026-10-29 | (E) | $82B | Nasdaq calendar |
| PWR | Quanta Services, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-10-29 | (E) | $81B | Nasdaq calendar |
| EPD | Enterprise Products Partners L.P. | Earnings (BMO, FQ Sep/2026) | 2026-10-29 | (E) | $79B | Nasdaq calendar |
| HWM | Howmet Aerospace Inc. | Earnings (BMO, FQ Sep/2026) | 2026-10-29 | (E) | $77B | Nasdaq calendar |
| RSG | Republic Services, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-10-29 | (E) | $74B | Nasdaq calendar |
| AJG | Arthur J. Gallagher & Co. | Earnings (AMC, FQ Sep/2026) | 2026-10-29 | (E) | $69B | Nasdaq calendar |
| TAK | Takeda Pharmaceutical Company Limited | Earnings (BMO, FQ Sep/2026) | 2026-10-29 | (E) | $64B | Nasdaq calendar |
| DLR | Digital Realty Trust, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-10-29 | (E) | $63B | Nasdaq calendar |
| MSTR | Strategy Inc | Earnings (AMC, FQ Sep/2026) | 2026-10-29 | (E) | $62B | Nasdaq calendar |
| LNG | Cheniere Energy, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-10-29 | (E) | $59B | Nasdaq calendar |
| CRH | CRH PLC | Earnings (BMO, FQ Sep/2026) | 2026-10-29 | (E) | $58B | Nasdaq calendar |
| MPWR | Monolithic Power Systems, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-10-29 | (E) | $57B | Nasdaq calendar |
| ABEV | Ambev S.A. | Earnings (n/s, FQ Sep/2026) | 2026-10-29 | (E) | $52B | Nasdaq calendar |
| VALE | VALE S.A. | Earnings (AMC, FQ Sep/2026) | 2026-10-29 | (E) | $52B | Nasdaq calendar |
| CARR | Carrier Global Corporation | Earnings (BMO, FQ Sep/2026) | 2026-10-29 | (E) | $47B | Nasdaq calendar; FMP agrees |
| COIN | Coinbase Global, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-10-29 | (E) | $45B | Nasdaq calendar; FMP agrees |
| RBLX | Roblox Corporation | Earnings (AMC, FQ Sep/2026) | 2026-10-29 | (E) | $39B | Nasdaq calendar; FMP agrees |
| RKT | Rocket Companies, Inc. | Earnings (n/s, FQ Sep/2026) | 2026-10-29 | (E) | $33B | Nasdaq calendar; FMP agrees |
| FSLR | First Solar, Inc. [A-queue] | Earnings (AMC, FQ Sep/2026) | 2026-10-29 | **(C)** | $18B | Nasdaq calendar; (C) carried from W42 ("First Solar, Inc. to Announce Third Quarter 2026 Financial ) |
| RIVN | Rivian Automotive, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-10-29 | (E) | $17B | Nasdaq calendar; FMP agrees |
| PINS | Pinterest, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-10-29 | (E) | $13B | Nasdaq calendar; FMP agrees |
| SIRI | SiriusXM Holdings Inc. | Earnings (BMO, FQ Sep/2026) | 2026-10-29 | (E) | $9B | Nasdaq calendar; FMP agrees |
| XOM | ExxonMobil Holdings Corporation [A-queue] | Earnings (BMO, FQ Sep/2026) | 2026-10-30 | **(C)** | $733B | Nasdaq calendar; FMP agrees; (C) carried from W42 (investor.exxonmobil.com "ExxonMobil to Release Third Quarter) |
| ABBV | AbbVie Inc. | Earnings (BMO, FQ Sep/2026) | 2026-10-30 | **(C)** | $504B | Nasdaq calendar; FMP agrees; (C) carried from W42 (AbbVie release 2026-10-01 (carried); FMP agrees) |
| CVX | Chevron Corporation [A-queue] | Earnings (BMO, FQ Sep/2026) | 2026-10-30 | **(C)** | $448B | Nasdaq calendar; FMP agrees; (C) carried from W42 (Chevron advisory (carried); FMP agrees) |
| AZN | AstraZeneca PLC | Earnings (BMO, FQ Sep/2026) | 2026-10-30 | (E) | $262B | Nasdaq calendar |
| BP | BP p.l.c. | Earnings (BMO, FQ Sep/2026) | 2026-10-30 | (E) | $130B | Nasdaq calendar |
| SNY | Sanofi | Earnings (BMO, FQ Sep/2026) | 2026-10-30 | (E) | $102B | Nasdaq calendar |
| GD | General Dynamics Corporation | Earnings (BMO, FQ Sep/2026) | 2026-10-30 | (E) | $95B | Nasdaq calendar |
| REGN | Regeneron Pharmaceuticals, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-10-30 | (E) | $84B | Nasdaq calendar |
| CL | Colgate-Palmolive Company | Earnings (BMO, FQ Sep/2026) | 2026-10-30 | (E) | $78B | Nasdaq calendar |
| CNI | Canadian National Railway Company | Earnings (BMO, FQ Sep/2026) | 2026-10-30 | (E) | $75B | Nasdaq calendar |
| NWG | NatWest Group plc | Earnings (BMO, FQ Sep/2026) | 2026-10-30 | (E) | $69B | Nasdaq calendar |
| IMO | Imperial Oil Limited | Earnings (BMO, FQ Sep/2026) | 2026-10-30 | (E) | $64B | Nasdaq calendar |
| CVE | Cenovus Energy Inc | Earnings (n/s, FQ Sep/2026) | 2026-10-30 | (E) | $60B | Nasdaq calendar |
| D | Dominion Energy, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-10-30 | (E) | $58B | Nasdaq calendar |
| AAPL | Apple Inc. [A-queue] | Earnings (AMC, FQ Sep/2026) | 2026-11-02 | **(C)** | $5082B | Nasdaq calendar; FMP agrees; (C) carried from W42 (Apple IR notice via MacTrast relay (carried); FMP agrees) |
| PLTR | Palantir Technologies Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-02 | (E) | $471B | Nasdaq calendar; FMP agrees |
| VRTX | Vertex Pharmaceuticals Incorporated [A-queue] | Earnings (AMC, FQ Sep/2026) | 2026-11-02 | **(C)** | $136B | Nasdaq calendar; (C) carried from W42 (Vertex release 2026-10-07 (carried)) |
| MAR | Marriott International | Earnings (BMO, FQ Sep/2026) | 2026-11-02 | (E) | $103B | Nasdaq calendar |
| WMB | Williams Companies, Inc. (The) | Earnings (AMC, FQ Sep/2026) | 2026-11-02 | (E) | $86B | Nasdaq calendar |
| FANG | Diamondback Energy, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-02 | (E) | $55B | Nasdaq calendar |
| O | Realty Income Corporation | Earnings (AMC, FQ Sep/2026) | 2026-11-02 | (E) | $54B | Nasdaq calendar |
| ETR | Entergy Corporation | Earnings (BMO, FQ Sep/2026) | 2026-11-02 | (E) | $50B | Nasdaq calendar |
| ROKU | Roku, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-02 | (E) | $24B | Nasdaq calendar; FMP agrees; **Δ vs W42 2026-11-05** |
| AMD | Advanced Micro Devices, Inc. [A-queue] | Earnings (AMC, FQ Sep/2026) | 2026-11-03 | **(C)** | $829B | Nasdaq calendar; FMP agrees; (C) carried from W42 (ir.amd.com 2026-10-06 (carried); FMP agrees) |
| AMGN | Amgen Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-03 | (E) | $242B | Nasdaq calendar |
| SHOP | Shopify Inc. | Earnings (BMO, FQ Sep/2026) | 2026-11-03 | (E) | $218B | Nasdaq calendar; FMP agrees |
| ANET | Arista Networks, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-03 | (E) | $216B | Nasdaq calendar |
| PFE | Pfizer, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-11-03 | (E) | $173B | Nasdaq calendar; FMP agrees |
| ETN | Eaton Corporation, PLC | Earnings (BMO, FQ Sep/2026) | 2026-11-03 | (E) | $143B | Nasdaq calendar |
| MPC | Marathon Petroleum Corporation | Earnings (BMO, FQ Sep/2026) | 2026-11-03 | (E) | $129B | Nasdaq calendar |
| BKNG | Booking Holdings Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-03 | (E) | $121B | Nasdaq calendar |
| ITUB | Itau Unibanco Banco Holding SA | Earnings (AMC, FQ Sep/2026) | 2026-11-03 | (E) | $105B | Nasdaq calendar |
| RACE | Ferrari N.V. | Earnings (BMO, FQ Sep/2026) | 2026-11-03 | (E) | $93B | Nasdaq calendar |
| SU | Suncor Energy  Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-03 | (E) | $90B | Nasdaq calendar |
| APO | Apollo Global Management, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-11-03 | (E) | $68B | Nasdaq calendar |
| MPLX | MPLX LP | Earnings (BMO, FQ Sep/2026) | 2026-11-03 | (E) | $59B | Nasdaq calendar |
| AME | AMTEK, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-11-03 | (E) | $55B | Nasdaq calendar |
| TRI | Thomson Reuters Corp | Earnings (BMO, FQ Sep/2026) | 2026-11-03 | (E) | $53B | Nasdaq calendar |
| SMCI | Super Micro Computer, Inc. [A-queue] | Earnings (AMC, FQ Sep/2026) | 2026-11-03 | (E) | $22B | Nasdaq calendar |
| TM | Toyota Motor Corp Ltd Ord | Earnings (n/s, FQ Sep/2026) | 2026-11-04 | (E) | $258B | Nasdaq calendar |
| ARM | Arm Holdings plc | Earnings (AMC, FQ Sep/2026) | 2026-11-04 | (E) | $224B | Nasdaq calendar |
| QCOM | QUALCOMM Incorporated [A-queue] | Earnings (AMC, FQ Sep/2026) | 2026-11-04 | (E) | $182B | Nasdaq calendar; **Δ vs W42 2026-11-11** |
| MCD | McDonald's Corporation | Earnings (BMO, FQ Sep/2026) | 2026-11-04 | (E) | $179B | Nasdaq calendar |
| NVO | Novo Nordisk A/S | Earnings (BMO, FQ Sep/2026) | 2026-11-04 | (E) | $175B | Nasdaq calendar |
| UBER | Uber Technologies, Inc. [D held] | Earnings (BMO, FQ Sep/2026) | 2026-11-04 | (E) | $141B | Nasdaq calendar; FMP agrees |
| CVS | CVS Health Corporation | Earnings (BMO, FQ Sep/2026) | 2026-11-04 | (E) | $121B | Nasdaq calendar |
| MCK | McKesson Corporation | Earnings (AMC, FQ Sep/2026) | 2026-11-04 | (E) | $118B | Nasdaq calendar |
| EQNR | Equinor ASA | Earnings (n/s, FQ Sep/2026) | 2026-11-04 | (E) | $116B | Nasdaq calendar |
| DDOG | Datadog, Inc. [A-queue] | Earnings (BMO, FQ Sep/2026) | 2026-11-04 | **(C)** | $93B | Nasdaq calendar; (C) carried from W42 ("Datadog announces date of third quarter fiscal year 2026 ea) |
| MELI | MercadoLibre, Inc. | Earnings (n/s, FQ Sep/2026) | 2026-11-04 | (E) | $93B | Nasdaq calendar |
| EMR | Emerson Electric Company | Earnings (BMO, FQ Sep/2026) | 2026-11-04 | (E) | $89B | Nasdaq calendar |
| APP | Applovin Corporation | Earnings (AMC, FQ Sep/2026) | 2026-11-04 | (E) | $88B | Nasdaq calendar |
| DASH | DoorDash, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-04 | (E) | $81B | Nasdaq calendar |
| MSI | Motorola Solutions, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-04 | (E) | $79B | Nasdaq calendar |
| MFC | Manulife Financial Corp | Earnings (AMC, FQ Sep/2026) | 2026-11-04 | (E) | $76B | Nasdaq calendar |
| MET | MetLife, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-04 | (E) | $66B | Nasdaq calendar |
| ALL | Allstate Corporation (The) | Earnings (AMC, FQ Sep/2026) | 2026-11-04 | (E) | $66B | Nasdaq calendar |
| COR | Cencora, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-11-04 | (E) | $65B | Nasdaq calendar |
| GWW | W.W. Grainger, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-11-04 | (E) | $64B | Nasdaq calendar |
| AFL | Aflac Incorporated | Earnings (AMC, FQ Sep/2026) | 2026-11-04 | (E) | $62B | Nasdaq calendar |
| DB | Deutsche Bank AG | Earnings (n/s, FQ Sep/2026) | 2026-11-04 | (E) | $59B | Nasdaq calendar |
| EW | Edwards Lifesciences Corporation | Earnings (AMC, FQ Sep/2026) | 2026-11-04 | (E) | $52B | Nasdaq calendar |
| VMRK | Vivmark Residential | Earnings (AMC, FQ Sep/2026) | 2026-11-04 | (E) | $50B | Nasdaq calendar |
| SNAP | Snap Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-04 | (E) | $11B | Nasdaq calendar; FMP agrees |
| RIOT | Riot Platforms, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-11-04 | (E) | $5B | Nasdaq calendar; FMP agrees |
| COP | ConocoPhillips | Earnings (BMO, FQ Sep/2026) | 2026-11-05 | (E) | $175B | Nasdaq calendar |
| SONY | Sony Group Corporation | Earnings (BMO, FQ Sep/2026) | 2026-11-05 | (E) | $154B | Nasdaq calendar; FMP agrees |
| MNST | Monster Beverage Corporation | Earnings (n/s, FQ Sep/2026) | 2026-11-05 | (E) | $139B | Nasdaq calendar |
| PH | Parker-Hannifin Corporation | Earnings (BMO, FQ Sep/2026) | 2026-11-05 | (E) | $113B | Nasdaq calendar |
| CNQ | Canadian Natural Resources Limited | Earnings (n/s, FQ Sep/2026) | 2026-11-05 | (E) | $111B | Nasdaq calendar |
| NET | Cloudflare, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-05 | (E) | $108B | Nasdaq calendar |
| SO | Southern Company (The) | Earnings (BMO, FQ Sep/2026) | 2026-11-05 | (E) | $108B | Nasdaq calendar |
| ABNB | Airbnb, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-05 | (E) | $105B | Nasdaq calendar |
| DUK | Duke Energy Corporation | Earnings (BMO, FQ Sep/2026) | 2026-11-05 | (E) | $98B | Nasdaq calendar |
| CI | The Cigna Group | Earnings (BMO, FQ Sep/2026) | 2026-11-05 | (E) | $83B | Nasdaq calendar |
| EOG | EOG Resources, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-05 | (E) | $83B | Nasdaq calendar |
| CMI | Cummins Inc. | Earnings (BMO, FQ Sep/2026) | 2026-11-05 | (E) | $72B | Nasdaq calendar |
| APD | Air Products and Chemicals, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-11-05 | (E) | $69B | Nasdaq calendar |
| SPG | Simon Property Group, Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-05 | (E) | $69B | Nasdaq calendar |
| LITE | Lumentum Holdings Inc. | Earnings (AMC, FQ Sep/2026) | 2026-11-05 | (E) | $68B | Nasdaq calendar |
| TRGP | Targa Resources, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-11-05 | (E) | $62B | Nasdaq calendar |
| TRP | TC Energy Corporation | Earnings (BMO, FQ Sep/2026) | 2026-11-05 | (E) | $62B | Nasdaq calendar |
| CAH | Cardinal Health, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-11-05 | (E) | $59B | Nasdaq calendar |
| NTRA | Natera, Inc. | Earnings (n/s, FQ Sep/2026) | 2026-11-05 | (E) | $58B | Nasdaq calendar |
| TEAM | Atlassian Corporation  | Earnings (AMC, FQ Sep/2026) | 2026-11-05 | (E) | $56B | Nasdaq calendar |
| WPM | Wheaton Precious Metals Corp. | Earnings (AMC, FQ Sep/2026) | 2026-11-05 | (E) | $56B | Nasdaq calendar |
| SRE | Sempra  | Earnings (BMO, FQ Sep/2026) | 2026-11-05 | (E) | $55B | Nasdaq calendar |
| BDX | Becton, Dickinson and Company | Earnings (BMO, FQ Sep/2026) | 2026-11-05 | (E) | $55B | Nasdaq calendar |
| DVN | Devon Energy Corporation | Earnings (AMC, FQ Sep/2026) | 2026-11-05 | (E) | $54B | Nasdaq calendar |
| AKAM | Akamai Technologies, Inc. [A-queue] | Earnings (AMC, FQ Sep/2026) | 2026-11-05 | **(C)** | $13B | Nasdaq calendar; (C) carried from W42 (Akamai release 2026-10-08 (carried)) |
| BRK.A | Berkshire Hathaway Inc. | Earnings (n/s, FQ Sep/2026) | 2026-11-06 | (E) | $1179B | Nasdaq calendar |
| BRK.B | Berkshire Hathaway Inc. | Earnings (n/s, FQ Sep/2026) | 2026-11-06 | (E) | $1179B | Nasdaq calendar |
| ENB | Enbridge Inc | Earnings (BMO, FQ Sep/2026) | 2026-11-06 | (E) | $105B | Nasdaq calendar |
| CEG | Constellation Energy Corporation | Earnings (n/s, FQ Sep/2026) | 2026-11-06 | (E) | $90B | Nasdaq calendar |
| MRNA | Moderna, Inc. | Earnings (BMO, FQ Sep/2026) | 2026-11-06 | (E) | $81B | Nasdaq calendar; FMP agrees |
| BAM | Brookfield Asset Management | Earnings (BMO, FQ Sep/2026) | 2026-11-06 | (E) | $76B | Nasdaq calendar |
| HUM | Humana Inc. | Earnings (BMO, FQ Sep/2026) | 2026-11-06 | (E) | $51B | Nasdaq calendar |
| KKR | KKR & Co. Inc. | Earnings (BMO, FQ Sep/2026) | 2026-11-09 | (E) | $84B | Nasdaq calendar |
| B | Barrick Mining Corporation | Earnings (BMO, FQ Sep/2026) | 2026-11-09 | (E) | $63B | Nasdaq calendar |
| OXY | Occidental Petroleum Corporation | Earnings (AMC, FQ Sep/2026) | 2026-11-09 | (E) | $62B | Nasdaq calendar |
| TTWO | Take-Two Interactive Software, Inc. [A-queue] | Earnings (AMC, FQ Sep/2026) | 2026-11-09 | (E) | $39B | Nasdaq calendar; **Δ vs W42 2026-11-05** |
| PBR | Petroleo Brasileiro S.A.- Petrobras | Earnings (AMC, FQ Sep/2026) | 2026-11-10 | (E) | $165B | Nasdaq calendar |
| PBR.A | Petroleo Brasileiro S.A.- Petrobras | Earnings (AMC, FQ Sep/2026) | 2026-11-10 | (E) | $165B | Nasdaq calendar |
| NBIS | Nebius Group N.V. [A-queue] | Earnings (n/s, FQ Sep/2026) | 2026-11-10 | (E) | $43B | Nasdaq calendar; **Δ vs W42 2026-11-11** |
| CSCO | Cisco Systems, Inc. [A-queue] | Earnings (n/s, FQ Oct/2026) | 2026-11-11 | (E) | $414B | Nasdaq calendar; FMP agrees |
| TDG | Transdigm Group Incorporated | Earnings (n/s, FQ Sep/2026) | 2026-11-11 | (E) | $63B | Nasdaq calendar |
| AMAT | Applied Materials, Inc. [A-queue] | Earnings (AMC, FQ Oct/2026) | 2026-11-12 | (E) | $298B | Nasdaq calendar |
| BN | Brookfield Corporation | Earnings (BMO, FQ Sep/2026) | 2026-11-12 | (E) | $93B | Nasdaq calendar |
| NU | Nu Holdings Ltd. | Earnings (n/s, FQ Sep/2026) | 2026-11-12 | (E) | $72B | Nasdaq calendar |
| BILI | Bilibili Inc. | Earnings (n/s, FQ Sep/2026) | 2026-11-12 | (E) | $6B | Nasdaq calendar; FMP agrees |
| MUFG | Mitsubishi UFJ Financial Group Inc | Earnings (n/s, FQ Sep/2026) | 2026-11-13 | (E) | $254B | Nasdaq calendar |
| SMFG | Sumitomo Mitsui Financial Group Inc | Earnings (n/s, FQ Sep/2026) | 2026-11-13 | (E) | $154B | Nasdaq calendar |
| MFG | Mizuho Financial Group, Inc. | Earnings (n/s, FQ Sep/2026) | 2026-11-13 | (E) | $121B | Nasdaq calendar |
| HD | Home Depot, Inc. (The) [A-queue] | Earnings (BMO, FQ Oct/2026) | 2026-11-17 | (E) | $327B | Nasdaq calendar |
| BHP | BHP Group Limited | Earnings (n/s, FQ Sep/2026) | 2026-11-17 | (E) | $207B | Nasdaq calendar |
| DIS | Walt Disney Company (The) [D held] | Earnings (BMO, FQ Sep/2026) | 2026-11-17 | (E) | $195B | Nasdaq calendar; FMP agrees |
| MDT | Medtronic plc | Earnings (n/s, FQ Oct/2026) | 2026-11-17 | (E) | $124B | Nasdaq calendar |
| PDD | PDD Holdings Inc. | Earnings (n/s, FQ Sep/2026) | 2026-11-17 | (E) | $113B | Nasdaq calendar |
| BIDU | Baidu, Inc. | Earnings (n/s, FQ Sep/2026) | 2026-11-17 | (E) | $27B | Nasdaq calendar; FMP agrees |
| NVDA | NVIDIA Corporation [A-queue] | Earnings (n/s, FQ Oct/2026) | 2026-11-18 | (E) | $5114B | Nasdaq calendar; FMP agrees |
| PANW | Palo Alto Networks, Inc. [A-queue] | Earnings (n/s, FQ Oct/2026) | 2026-11-18 | (E) | $290B | Nasdaq calendar; **Δ vs W42 11-12 or 11-18** |
| TJX | TJX Companies, Inc. (The) | Earnings (n/s, FQ Oct/2026) | 2026-11-18 | (E) | $162B | Nasdaq calendar |
| LOW | Lowe's Companies, Inc. | Earnings (BMO, FQ Oct/2026) | 2026-11-18 | (E) | $115B | Nasdaq calendar |
| TGT | Target Corporation [A-queue] | Earnings (BMO, FQ Oct/2026) | 2026-11-18 | **(C)** | $72B | Nasdaq calendar; FMP agrees; (C) carried from W42 (corporate.target.com (carried); FMP agrees) |
| WMT | Walmart Inc. [A-queue] | Earnings (BMO, FQ Oct/2026) | 2026-11-19 | **(C)** | $961B | Nasdaq calendar; FMP agrees; (C) carried from W42 (corporate.walmart.com (carried); FMP agrees) |
| INTU | Intuit Inc. [A-queue] | Earnings (n/s, FQ Oct/2026) | 2026-11-19 | (E) | $95B | Nasdaq calendar |
| NTES | NetEase, Inc. | Earnings (n/s, FQ Sep/2026) | 2026-11-19 | (E) | $76B | Nasdaq calendar |
| ROST | Ross Stores, Inc. | Earnings (n/s, FQ Oct/2026) | 2026-11-19 | (E) | $76B | Nasdaq calendar |
| VEEV | Veeva Systems Inc. | Earnings (n/s, FQ Oct/2026) | 2026-11-19 | (E) | $52B | Nasdaq calendar |
| KEYS | Keysight Technologies Inc. | Earnings (n/s, FQ Oct/2026) | 2026-11-23 | (E) | $53B | Nasdaq calendar |
| ZM | Zoom Communications, Inc. | Earnings (n/s, FQ Oct/2026) | 2026-11-23 | (E) | $28B | Nasdaq calendar; FMP agrees |
| DELL | Dell Technologies Inc. [A-queue] | Earnings (n/s, FQ Oct/2026) | 2026-11-24 | (E) | $288B | Nasdaq calendar |
| BABA | Alibaba Group Holding Limited | Earnings (n/s, FQ Sep/2026) | 2026-11-24 | (E) | $247B | Nasdaq calendar; FMP agrees |
| ADI | Analog Devices, Inc. | Earnings (n/s, FQ Oct/2026) | 2026-11-24 | (E) | $187B | Nasdaq calendar |
| ADSK | Autodesk, Inc. | Earnings (n/s, FQ Oct/2026) | 2026-11-24 | (E) | $53B | Nasdaq calendar |
| WDAY | Workday, Inc. | Earnings (n/s, FQ Oct/2026) | 2026-11-24 | (E) | $51B | Nasdaq calendar |
| NTAP | NetApp, Inc. [A-queue] | Earnings (n/s, FQ Oct/2026) | 2026-11-24 | (E) | $42B | Nasdaq calendar; **Δ vs W42 2026-12-01** |
| NIO | NIO Inc. | Earnings (n/s, FQ Sep/2026) | 2026-11-24 | (E) | $8B | Nasdaq calendar; FMP agrees |
| DE | Deere & Company | Earnings (BMO, FQ Oct/2026) | 2026-11-25 | (E) | $174B | Nasdaq calendar |
| CRWD | CrowdStrike Holdings, Inc. [A-queue] | Earnings (n/s, FQ Oct/2026) | 2026-12-01 | (E) | $244B | Nasdaq calendar |
| MRVL | Marvell Technology, Inc. [A-queue] | Earnings (n/s, FQ Oct/2026) | 2026-12-01 | (E) | $196B | Nasdaq calendar |
| BNS | Bank of Nova Scotia (The) | Earnings (n/s, FQ Oct/2026) | 2026-12-01 | (E) | $114B | Nasdaq calendar |
| OKTA | Okta, Inc. [A-queue] | Earnings (n/s, FQ Oct/2026) | 2026-12-01 | (E) | $35B | Nasdaq calendar; **Δ vs W42 12-01 or 12-02** |
| RY | Royal Bank Of Canada | Earnings (n/s, FQ Oct/2026) | 2026-12-02 | (E) | $279B | Nasdaq calendar |
| CRM | Salesforce, Inc. [A-queue] | Earnings (n/s, FQ Oct/2026) | 2026-12-02 | (E) | $206B | Nasdaq calendar |
| SNOW | Snowflake Inc. [A-queue] | Earnings (n/s, FQ Oct/2026) | 2026-12-02 | (E) | $111B | Nasdaq calendar |
| TD | Toronto Dominion Bank (The) | Earnings (n/s, FQ Oct/2026) | 2026-12-03 | (E) | $204B | Nasdaq calendar |
| BMO | Bank Of Montreal | Earnings (n/s, FQ Oct/2026) | 2026-12-03 | (E) | $118B | Nasdaq calendar |
| CM | Canadian Imperial Bank of Commerce | Earnings (n/s, FQ Oct/2026) | 2026-12-03 | (E) | $104B | Nasdaq calendar |
| HPE | Hewlett Packard Enterprise Company [A-queue] | Earnings (n/s, FQ Oct/2026) | 2026-12-03 | (E) | $74B | Nasdaq calendar |
| DOCU | DocuSign, Inc. | Earnings (n/s, FQ Oct/2026) | 2026-12-03 | (E) | $16B | Nasdaq calendar; FMP agrees |
| AZO | AutoZone, Inc. | Earnings (n/s, FQ Nov/2026) | 2026-12-08 | (E) | $53B | Nasdaq calendar |
| ORCL | Oracle Corporation [A-queue] | Earnings (n/s, FQ Nov/2026) | 2026-12-09 | (E) | $380B | Nasdaq calendar; **Δ vs W42 2026-12-10** |
| ADBE | Adobe Inc. [A-queue] | Earnings (n/s, FQ Nov/2026) | 2026-12-09 | (E) | $105B | Nasdaq calendar; FMP agrees |
| SNPS | Synopsys, Inc. | Earnings (n/s, FQ Oct/2026) | 2026-12-09 | (E) | $81B | Nasdaq calendar |

**Full enumeration, by session** — every Nasdaq-calendar reporter at market cap ≥ $2B, ordered by market cap within the day; superscript ᵇ = before open, ᵃ = after close, none = time not supplied. All (E) unless the detail table above tags (C).

- **2026-10-26** (36): VZᵇ WELLᵃ CDNSᵃ NUEᵃ PSAᵃ HIGᵃ CLSᵃ CINFᵃ BROᵃ PFGᵃ PKX CXᵇ SUIᵃ SMMT BMRN GGBᵃ AMKRᵃ RMBSᵃ BRXᵃ SSDᵃ AREᵃ NEᵃ PSMTᵃ PECOᵃ MMYTᵇ DORMᵃ AGYSᵃ ARLPᵇ PRK CLBK HWKNᵃ BOHᵇ HTOᵃ NWBIᵃ BLXᵃ CTOSᵃ
- **2026-10-27** (118): Vᵃ KOᵇ HSBC NVSᵇ BAᵇ STXᵃ SPGIᵇ GLWᵇ HCAᵇ WMᵃ FCXᵇ HOODᵃ JCIᵇ UPSᵇ AMTᵇ SHWᵇ ECLᵇ HLTᵇ ITWᵇ RCLᵇ NXPIᵃ OKEᵃ PCARᵇ BKRᵃ PYPLᵇ TERᵃ IQVᵇ VTRᵃ CNCᵇ ACGLᵃ EQTᵃ EXRᵃ CNPᵇ FEᵃ XYLᵇ FFIVᵃ PPGᵃ LPLAᵃ HUBBᵇ CMSᵇ EXEᵃ SOFIᵇ ESSᵃ LOGIᵃ TRUᵇ RNRᵃ WPCᵃ CSGPᵃ ICLRᵃ MANHᵃ LECOᵇ WSOᵇ WSO.Bᵇ ARCCᵇ IVZᵇ AITᵇ INIOᵇ UHSᵃ CRᵃ UMBFᵃ RRCᵃ BXPᵃ PNRᵇ RGENᵇ CBCᵇ ZWSᵃ SFDᵇ AWIᵇ STAGᵃ CVLTᵇ CHEᵃ NOVᵃ EXLSᵃ KNSA KOFᵇ GLXYᵇ STᵃ CZRᵃ LSTRᵃ CAKEᵃ RUSHAᵃ RUSHBᵃ AROC AKO.A AKO.B HRIᵇ SIM ENPHᵃ TNLᵇ MRPᵇ ITRIᵇ RNSTᵃ MIRᵃ SEB INTAᵃ FFBCᵃ HIWᵃ CBUᵇ SBCFᵃ SLDEᵃ ABᵇ PIIᵇ KAI ABGᵇ BANCᵃ APAMᵃ NBTBᵃ TRMKᵃ BUSEᵃ EEFTᵇ RCUS NTBᵃ IVTᵃ ROGᵃ FCFᵃ MCRIᵃ UCTTᵃ WGS
- **2026-10-28** (158): GOOGᵃ GOOGLᵃ MSFTᵃ GEVᵇ SANᵇ KLACᵃ APHᵇ TMUSᵃ NOWᵃ UBSᵇ BBVAᵃ FTNTᵃ ADPᵇ PSXᵇ GSKᵇ EQIXᵃ AEMᵃ CPᵃ VRTᵇ ORLYᵃ FDXᵃ AEPᵇ BSXᵇ AONᵇ CVNAᵃ TELᵇ GRMNᵇ EBAYᵃ HONAᵃ Fᵃ UMCᵇ FMXᵇ ODFLᵇ BIIBᵇ CMGᵃ GEHCᵇ RJFᵃ OTISᵇ AWKᵃ FLEXᵇ KGCᵃ LHᵇ VICIᵃ NMRᵇ AERᵇ SWᵇ DINOᵇ AMRZᵃ ARXSᵃ NIᵇ GFLᵃ FTVᵇ IPᵇ CLHᵇ IEXᵇ CHRWᵇ INVHᵃ TYLᵃ EGᵃ MASᵇ GENᵃ JLLᵇ MAAᵃ CSLᵃ PAGᵇ LIIᵇ AGIᵃ EHCᵃ STLAᵇ ARᵃ NXTᵃ AVTRᵇ SCIᵃ STRLᵃ GNRCᵇ ALGNᵃ GKOSᵃ OGEᵇ EVRᵇ AMᵃ MUSAᵃ AURᵃ HLIᵃ EDUᵇ LFUSᵇ FLSᵃ EGOᵃ PBᵇ MORNᵃ THGᵃ ETSYᵇ NEUᵃ EATᵇ VISTᵃ MGMᵃ AXSᵃ FORMᵃ KEXᵇ VFCᵇ WEXᵃ PPCᵃ SFMᵃ SIMOᵃ BLCOᵇ TEXᵇ CHDNᵃ PLXSᵃ JMKEᵇ PSNᵇ PIᵃ WHDᵃ CHEFᵇ TENBᵃ UFPIᵃ SITEᵇ FELEᵇ PTENᵃ QTWOᵃ EPRᵃ STNGᵇ MTHᵃ OLEDᵃ MYRGᵃ JOEᵃ RSIᵃ BOOTᵃ BNLᵃ MCHBᵃ WINGᵇ CSTMᵇ VKTXᵃ DANᵇ PFSᵃ EXTRᵇ GPIᵇ MGRCᵃ GRBKᵃ TR TOWN HAYWᵇ BLKBᵇ UEᵇ OSWᵇ BHCᵃ FCPTᵃ PBIᵃ BHEᵃ PRCHᵃ DBDᵇ BELFAᵃ BELFBᵃ MBINᵃ CNXNᵃ COHUᵃ AXGNᵇ NEOᵃ CHCO CMPRᵃ
- **2026-10-29** (205): AMZNᵃ LLYᵇ MAᵇ INTCᵃ MRKᵇ CATᵇ SHELᵇ LINᵇ TTEᵇ GILDᵃ SNDKᵃ BUDᵇ BMYᵇ MOᵇ SYKᵃ SBUXᵃ TTᵇ INGᵇ ICEᵇ ASXᵇ MDLZᵃ LYGᵇ PWRᵇ EPDᵇ HWMᵇ RSGᵃ AJGᵃ TAKᵇ DLRᵃ MSTRᵃ LNGᵇ CRHᵇ MPWRᵃ ABEV VALEᵃ XELᵇ LHXᵇ CARRᵇ AMPᵇ COINᵃ HLNᵇ DHIᵇ ARESᵇ ILMNᵃ STMᵇ TWLOᵃ RBLXᵃ WECᵇ RMDᵃ HSYᵇ VMCᵇ QSRᵇ RKT CTSHᵇ CQPᵇ WTWᵇ ALNYᵇ DXCMᵃ EMEᵇ RDDTᵃ TECKᵇ IRᵃ TWᵇ WSTᵇ FTIᵇ VLTOᵃ INCYᵇ EIXᵃ XPOᵇ TROWᵇ ATIᵇ THCᵇ INSMᵇ BGᵇ ENTGᵇ FSLRᵃ LNTᵃ RIVNᵃ TPGᵇ APGᵇ Hᵇ FDXFᵃ EXELᵃ FTAIᵇ KIMᵇ WCCᵇ OWLᵇ GDDYᵃ WYᵃ AVYᵇ MTZᵃ TXTᵇ BBIOᵃ BAXᵇ PINSᵃ DTMᵇ TLK DVAᵃ ERIEᵃ SKM GLPIᵃ RYANᵃ BWAᵇ HIIᵇ ARW CFRᵇ TFIIᵃ PBFᵇ LTHᵇ SIRIᵇ SAIAᵇ DRSᵇ CUBEᵃ DARᵇ MHKᵃ IDCCᵇ AOSᵇ OSKᵇ IDAᵇ ATRᵃ SPXCᵃ AXTAᵇ EMNᵃ AGCOᵇ ACA BVNᵃ NCLHᵇ FSSᵇ INGMᵃ BLDRᵇ HRᵃ LGNDᵇ GATXᵇ MBLYᵇ ALGMᵇ TALᵇ CACC CROXᵇ LKQᵇ MMSIᵃ SNDRᵃ WFGᵇ LAURᵇ CNXᵇ PORᵇ PTCTᵃ AXᵃ CNOᵃ FNDᵃ KBRᵇ TVTX CSWᵇ CUZᵃ GVAᵇ MEOHᵃ OPCH TFSL CCC CVSAᵃ PRM BCᵇ FCNᵇ FHIᵃ CVCO SLGNᵇ INDVᵇ GTXᵇ CGAUᵃ BDCᵇ CDPᵃ SKYWᵃ EXPOᵃ LXP CDNAᵃ MIAXᵃ BFAMᵃ TNETᵇ AXTIᵃ SPSCᵃ AAMIᵇ PFSIᵃ OSISᵃ COLMᵃ HGᵃ HTGCᵃ HOGᵇ SPNT SXI CWTᵇ HGVᵇ EFXTᵇ KWRᵃ DXCᵃ SUPNᵃ MDᵇ PEBᵃ FTREᵇ PATKᵇ STGWᵇ NMRKᵇ PHINᵇ TBBKᵃ TRNᵇ NSPᵇ PRLBᵇ
- **2026-10-30** (38): XOMᵇ ABBVᵇ CVXᵇ AZNᵇ BPᵇ SNYᵇ GDᵇ REGNᵇ CLᵇ CNIᵇ NWGᵇ IMOᵇ CVE Dᵇ EXCᵇ KVUEᵇ CCJᵇ CHDᵇ LYBᵇ NVTᵇ BCHᵇ MGAᵇ RBCᵇ BSACᵇ BTSGᵇ CBOEᵇ FRTᵇ MSGS OMFᵇ TXNM GTESᵇ LEAᵇ SXTᵇ ANᵇ KRGᵇ PIPRᵇ WTᵇ NWLᵇ
- **2026-11-02** (83): AAPLᵃ PLTRᵃ VRTXᵃ MARᵇ WMBᵃ FANGᵃ Oᵃ ETRᵇ IDXXᵇ ELᵇ PEGᵇ ONᵃ RYAAYᵇ FOXᵇ FOXAᵇ ROKUᵃ Lᵇ TSEMᵇ SBACᵃ PSᵃ VNOMᵃ CRBGᵃ CHKPᵇ EQHᵃ NBIXᵃ JAZZᵃ LSCCᵃ CNAᵇ DOCᵃ GRABᵃ BWXTᵃ UDRᵃ TEMᵇ FNᵃ CLXᵃ MTCHᵃ ENSG AMG KRYSᵇ RHPᵃ ALSNᵃ VOYAᵃ JANᵃ HNGEᵃ AEISᵃ AXSMᵇ TGTX MSAᵃ RIGᵃ TBBBᵃ VNOᵃ VALᵃ WAYᵃ CEᵃ CHHᵇ SBRAᵃ OGSᵃ CRCᵃ CRGYᵃ PAYᵃ KTB PAMᵃ TGS HESM CBTᵃ OTTRᵃ CIFRᵇ IRTᵃ LQDA XENE EROᵃ BSMᵃ PPLIᵃ LIFEᵃ BCCᵃ AKRᵇ ALM ADEAᵃ CALXᵃ UFPT VVXᵃ AGM INSPᵃ
- **2026-11-03** (158): AMDᵃ AMGNᵃ SHOPᵇ ANETᵃ PFEᵇ ETNᵇ MPCᵇ BKNGᵃ ITUBᵃ RACEᵇ SUᵃ APOᵇ MPLXᵇ AMEᵇ TRIᵇ KDPᵇ XYZᵃ TEVAᵇ WATᵇ ALABᵃ AIGᵃ YUMᵇ SYYᵇ LYV PRUᵃ ADMᵇ AXON FTSᵇ FISVᵇ PHGᵇ EXPDᵇ CPNGᵃ IFFᵃ BNTXᵇ SMCIᵃ BRᵇ OVVᵃ TOSTᵃ DTᵇ DDᵇ ZBRAᵇ RVTYᵇ BALLᵇ LDOSᵇ TLNᵇ YUMCᵇ ULSᵇ UNMᵃ ITᵇ AIZᵃ OHIᵃ PNWᵇ AFGᵃ EMBJ FMSᵇ WTRGᵃ SWKSᵃ CORT JKHYᵃ TXᵃ DOCNᵇ AES MDGLᵇ PAYPᵃ RRXᵇ PCVX ENLTᵇ SYRE HSICᵇ PCORᵃ KYMR SMᵃ APTVᵇ JXNᵃ IBRX ZETA ALKSᵇ SLAB QLYS MODᵃ AMRXᵇ MTDRᵃ DUOLᵃ RYTMᵇ TFPMᵃ SSRMᵃ MCYᵃ CVIᵇ PJT SGHCᵃ HGTYᵇ JBTMᵇ NPOᵇ VRNSᵃ GXOᵃ MOSᵃ MIRM STVNᵇ RRRᵃ LPXᵇ FBINᵃ SHCᵇ XMTRᵇ ADTᵇ ECGᵃ DAVE TNGX HLNEᵇ CNKᵇ VSNTᵇ KGS BWIN BETAᵇ SKYᵃ CRVL PARRᵃ SPHR FRSHᵃ TACᵇ VACᵃ GEFᵃ GEF.Bᵃ SRADᵇ PRIMᵃ CARᵃ TARS IDYA HNIᵇ ASHᵃ SDRLᵃ HURNᵃ MZTIᵇ KNFᵇ ATRCᵃ IPGPᵇ TALOᵃ DRHᵃ MARA LBTYAᵇ LBTYBᵇ LBTYKᵇ GPKᵇ ATRO BEAM IOSPᵃ WTTR LTCᵃ FLYWᵃ UPSTᵇ LINDᵇ AUPH ADUSᵃ NVTSᵃ ANDEᵃ PRDO ALMRᵃ OUSTᵃ MQᵃ
- **2026-11-04** (247): TM ARMᵃ QCOMᵃ MCDᵇ NVOᵇ UBERᵇ CVSᵇ MCKᵃ EQNR DDOGᵇ MELI EMRᵇ APPᵃ DASHᵃ MSIᵃ MFCᵃ METᵃ ALLᵃ CORᵇ GWWᵇ AFLᵃ DB EWᵃ VMRKᵃ MDLNᵇ SLFᵃ COHRᵃ RVMDᵃ MLMᵇ RPRXᵇ EXPEᵃ TKOᵃ NTRᵃ TSᵃ KHCᵇ ATOᵃ SNᵇ CPAYᵃ PPL ESᵃ UTHRᵇ GFSᵇ MKL TPLᵃ Qᵇ STEᵃ CRCLᵇ AMCRᵃ PTCᵃ CDWᵇ PRᵃ RGLDᵃ FISᵇ BEPᵇ ZBHᵇ WESᵃ CFᵃ FICOᵃ CWᵃ APAᵃ HSTᵃ PAASᵃ ITTᵃ CRLᵇ Wᵇ PFGCᵇ SWKᵇ TRMBᵇ FLUTᵇ COKEᵃ CDEᵃ SITMᵃ HUBSᵃ MKSIᵃ FIGᵃ PEN IONQ PAYCᵃ WTSᵃ AMHᵃ CHYMᵃ TECH NYTᵇ UHALᵃ UHAL.Bᵃ ALBᵃ SNAPᵃ QGENᵃ PODDᵇ BEPCᵇ BIOᵃ BIO.Bᵃ SOLSᵇ HL OCᵇ CGNXᵃ CAIᵃ LLYVA LLYVK KNTKᵃ PRIᵃ BRKRᵇ CYTKᵃ CTRE CHRDᵃ WLKᵇ NNNᵇ Zᵃ ZGᵃ HUTᵇ NFGᵃ TKRᵇ VIAVᵃ IONS BROSᵃ AVTᵇ RALᵇ PRAX SOBOᵃ TRNO MATXᵃ MACᵃ ELFᵃ MGYᵃ VCTRᵃ SWX ACTᵃ BTGᵃ CAVAᵃ YOUᵇ MURᵃ BKHᵃ ENIC LBᵃ KVYOᵃ MTGᵃ GRALᵃ OGCᵃ RYNᵃ CAMTᵇ CRUSᵃ EXPᵇ NXE ORAᵃ RELYᵃ GHC TREXᵇ OBDCᵃ BLLNᵃ REYNᵇ CIGIᵇ RIOTᵇ GOLFᵇ NWEᵃ SEZLᵃ JOBYᵃ OPLNᵇ LUMNᵃ RDNᵃ BXSLᵇ BCOᵇ MTRNᵇ SEIᵃ LIVNᵇ DNTH HCCᵃ IEP LOPEᵃ OTFᵃ ESABᵇ VSECᵃ SKTᵃ VSHᵇ CRKᵃ ARQTᵃ TPC TRMDᵇ ADPTᵃ DHT NVSTᵃ PLSE AVNTᵇ IPARᵃ VCYTᵃ FSLYᵃ EEᵃ BATRAᵇ BATRKᵇ WBIᵃ ACADᵃ NATLᵇ SMGᵇ GNWᵃ AWRᵃ PKᵃ CXTᵃ MGNIᵃ KDᵇ TNK ARISᵃ FRPTᵇ USLM AVAᵇ VGNTᵇ ACHCᵃ DYN PTRNᵃ ARCBᵇ CXWᵃ FSMᵃ IONDᵃ CWKᵇ GPORᵃ COTYᵃ MGEE DNOW AAUC SII BTUᵇ POWIᵃ AMC VRDNᵇ NAMS HCIᵃ GCMG TTAMᵃ VECOᵃ CLOVᵃ TMDX VERXᵃ ADMA SYBT NGVTᵃ ATHMᵇ RAMP PRGOᵇ KMTᵇ PGNYᵃ RXRX AMPLᵃ ECPGᵃ HRMYᵇ VETᵇ LEU RDW SEDGᵇ WUᵃ
- **2026-11-05** (232): COPᵇ SONYᵇ MNST PHᵇ CNQ NETᵃ SOᵇ ABNBᵃ DUKᵇ CIᵇ EOGᵃ CMIᵇ APDᵇ SPGᵃ LITEᵃ TRGPᵇ TRPᵇ CAHᵇ NTRA TEAMᵃ WPMᵃ SREᵇ BDXᵇ DVNᵃ ROKᵇ MTᵇ ONCᵇ EDᵃ MCHPᵃ CHT KMBᵇ ZTSᵇ MTDᵃ IRMᵇ AEEᵃ PBAᵃ DTEᵇ VRSKᵇ GMABᵇ ECHO AFRMᵃ CIB RLᵇ TPRᵇ GPNᵇ USFDᵇ GHᵃ VTRSᵇ FWONAᵇ FWONKᵇ NRG EVRGᵇ BCEᵇ NWS NWSA RGAᵃ Uᵇ MTSIᵇ LAMRᵇ SOLVᵃ HALOᵃ CGᵇ REGᵃ TIGOᵇ AKAMᵃ AHRᵃ CARTᵃ BSYᵇ MAIRᵇ FROGᵃ QXO TXRHᵃ FNFᵃ GMEDᵃ SUZ GSAT DKNGᵃ CPTᵃ IREN OSCRᵇ WMSᵇ NVMIᵇ PCTYᵃ IAGᵃ TXGᵃ PTGX VIRTᵇ DBXᵃ LNCᵇ TAPᵇ TAP.Aᵇ WYNNᵃ GILᵇ COMPᵃ AGᵇ PRMBᵇ SAROᵃ CELH EPAMᵇ Gᵃ OTEXᵇ MPᵃ LYFTᵃ AUGOᵃ LNTH IOVA TTD HRB INGRᵇ LOARᵇ DOCSᵃ FTDRᵇ BBUCᵇ TFXᵇ AAOIᵃ AAON ACIWᵇ INSWᵇ BGCᵇ OUTᵃ WTM HAEᵇ IBPᵇ STEPᵃ NXSTᵇ MIDDᵇ CONᵃ MRXᵇ MAINᵃ NSITᵇ MATᵃ DFTX LFSTᵇ RXO HASIᵃ VNTᵇ SYNA WKᵃ KRMN NNIᵃ QBTS CNRᵇ EWTX MDAᵇ BILLᵃ MCᵃ APLEᵃ CORZᵇ ICUIᵃ TKC HHHᵃ MDUᵇ COLDᵇ RLAY PLNTᵇ IRTCᵃ PLMR LIONᵃ BTEᵃ DIODᵃ MSGE APPNᵇ FAᵇ GPGIᵇ USAR AMLX GEOᵇ LMNDᵇ MWA ACMRᵇ AVPTᵃ FIGSᵃ SHOOᵇ ACLSᵇ CPK CENX TDCᵃ WRBYᵇ FOUR NMIHᵃ AGOᵃ ALRM WSCᵃ DNLI ACHR PRVAᵇ CARGᵃ FSKᵇ SHAKᵇ NOGᵃ IRON IMAXᵇ MHᵇ AAPᵇ FGᵃ NTCTᵇ SKWDᵃ BHF FIVN CALY LCLNᵇ PLUS GRDNᵃ ZLABᵇ GRND DXPE BKD MBX PAYOᵇ DCOᵇ PTONᵇ PBHᵇ SMRᵃ BKVᵇ AGIOᵇ LPG VCELᵇ HLIOᵃ SOUN IMNM BOBSᵇ GCT LCIIᵇ TRLVᵇ NWNᵇ VERAᵃ TICᵇ LASRᵃ PENNᵇ INODᵃ AMR ZYME
- **2026-11-06** (47): BRK.A BRK.B ENBᵇ CEG MRNAᵇ BAMᵇ HUMᵇ VSTᵇ HMC UI YPF PAAᵇ BIPᵇ BENᵇ EMAᵇ TU CHTRᵇ ELANᵇ FRHC KT VSAT ESNTᵇ FLRᵇ MKTX WULFᵇ PAGPᵇ VEONᵇ COGT STWDᵇ DKᵇ BH BH.A CLMTᵇ AQN TDS NHC ATMUᵇ DKLᵇ KYIVᵇ AD SHOᵇ EXK TILEᵇ DV UAᵇ UAAᵇ UTZᵇ
- **2026-11-09** (47): KKRᵇ Bᵇ OXYᵃ SKYDᵃ TTWOᵃ RKLBᵃ CRWV BAPᵃ ROIVᵇ SBS BEKE KSPIᵇ RBAᵇ SGIᵇ ASTS CNHᵇ JBSᵃ EQXᵃ ONTOᵃ TIMBᵃ SANMᵃ LINEᵃ HIMSᵃ CWSTᵃ BLTE IMVTᵇ IFSᵃ RDNT TEO NOVTᵃ CWENᵃ CRSP MNDYᵇ TDW RGTI ABCLᵃ OGN ASST NHIᵃ VIAᵇ RUM RNW EROK CSQRᵃ CLDX BHVN SGRY
- **2026-11-10** (23): PBRᵃ PBR.Aᵃ SE NBIS AU VODᵇ ALCᵃ EC VGᵇ VIVᵃ QNT CAE DOX MANE SRRKᵇ OKLO MRCYᵃ PHI WIXᵇ FLYᵃ REZIᵃ STUBᵃ SONOᵃ
- **2026-11-11** (34): CSCO TDG VYLRᵃ FNVᵃ IX ONON GIBᵇ ASND TTEKᵃ UGP CTVAᵃ ANDG ORᵃ ENSᵃ ICLᵇ ORKA ERAS ARX EQPT LEGN ECOᵃ PAGS CELC ELVN IHS LFTO DGIIᵃ SA TGB FRVO BGSIᵇ SLS PLGOᵃ PHVS
- **2026-11-12** (36): AMATᵃ BNᵇ NU JD BSP CBRSᵃ BNT ELPCᵃ HBMᵇ STNᵃ NICE NIQᵇ MBGLᵇ OCTVᵇ AVAL BILI FIGR KOD HTFLᵃ DLOᵃ MWHᵇ XE ALH LGN DPCᵇ SKE ONDS AYA PBLS YETIᵇ INTR CLBTᵇ AVAHᵇ STNEᵃ LUNR PGEN
- **2026-11-13** (14): MUFG SMFG MFG KB SHG WF LTM TWST CIG CGON XXI LPL PPTA RLX
- **2026-11-16** (10): TCOM TSNᵇ JHX XP HTHT ARMKᵇ XPEV YMM BRC DAC
- **2026-11-17** (21): HDᵇ BHP DISᵇ MDT PDD ESLT BIDU ASᵇ SQM ZTOᵃ FUTU TMEᵇ KLARᵇ ACM BZ DLBᵃ POWL SRᵇ SBLK GBDCᵃ NMM
- **2026-11-18** (23): NVDA PANW TJX LOWᵇ TGTᵇ VIK WSM UGIᵃ PACS GLBE DY CPAᵃ NJR BLSH GLNGᵇ GDS GFF VVV JOYY KLIC HPᵃ KC PONYᵇ
- **2026-11-19** (21): WMTᵇ INTU NTES ROST VEEV CPRT J WMGᵇ ESTC GAP ESEᵃ VIPS ROAD BBWI POST ZIM MMSᵇ BULL MNSO CDLR DAO
- **2026-11-20** (7): BJ FRO MOG.A MOG.B IESC VFS BKE
- **2026-11-23** (12): KEYS A ZM SYM WWD SMTC SNEX AMTM CAAP BWLPᵇ CENT CENTA
- **2026-11-24** (23): DELL BABA ADI ADSK WDAY NTAP ZS HPQ BBY NTNX BURL SJM DKS NIO ARWR URBN ANF GGAL ATAT KSS AMBA BBAR CLSK
- **2026-11-25** (4): DEᵇ LI CMBT BMA
- **2026-11-27** (1): CHA
- **2026-12-01** (11): CRWD MRVL BNS P OKTA GTLB BOX SIG AEO UNFI ASAN
- **2026-12-02** (14): RY CRM SNOW DLTR GWRE FIVE HQY DSGX PATH M PVH THO KEN NCNO
- **2026-12-03** (23): TD BMO CM HPE KR DG ULTA IOT RBRK DOCU BF.A BF.B HRL COO DCI TTAN S SAIC AGX DOO WLY WLYB IDT
- **2026-12-04** (1): VSXY
- **2026-12-07** (3): CRDO MDB HAFN
- **2026-12-08** (11): AZO CASY GME SAIL CNM CPB AVAV OLLI BRZE KFY ASO
- **2026-12-09** (8): ORCL ADBE SNPS NDSN CHWY MTN PL UEC

### 1A.2 — Earnings, 2026-12-10 → dense horizon 2026-12-18

| Ticker | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| COST | Costco (FQ1) | Earnings | 2026-12-10 | (E) | FMP |
| NKE | Nike (FQ2) | Earnings | 2026-12-17 | (E) | FMP |
| CCL | Carnival (Q4) | Earnings | 2026-12-18 | (E) | FMP — terminal row of the dense horizon |

ORCL moved INTO the C window this cycle (Nasdaq 2026-12-09, was 12-10 aggregator, **Δ**); DOCU, HPE and ADBE are inside the C window too, so this band is now FMP-only. Nasdaq was not fetched past 2026-12-09.

### 1A.3 — Earnings, 2026-12-19 → 2027-04-25

Coverage gap, not absence of events: FMP (chunked pull, 2026-10-25) returns nothing 2026-12-19 → 2027-01-10 and only FDX after 2027-02-25. Window end rolled 04-18 → 04-25; no vendor or sourced row falls 04-19..04-25. Dense horizon terminal row remains CCL 2026-12-18 (unchanged).

| Ticker | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| MU | Micron (FQ1) | Earnings | 2026-12-23 | (E) | aggregator (carried); not in FMP; not re-searched |
| TLRY | Tilray | Earnings | 2027-01-11 | (E) | FMP — A-INELIGIBLE (cap floor) |
| DAL | Delta (Q4) | Earnings | 2027-01-12 | (E) | FMP |
| C · JPM · WFC | Citigroup · JPMorgan · Wells Fargo | Q4 earnings | 2027-01-14 | (E) | FMP |
| BAC | Bank of America | Q4 earnings | 2027-01-15 | (E) | FMP |
| UAL | United Airlines (Q4) | Earnings | 2027-01-19 | (E) | FMP. **New** (UAL printed Q3 2026-10-20) |
| NFLX | Netflix (Q4) | Earnings | 2027-01-19 | (E) | FMP. **New** |
| GS | Goldman Sachs | Q4 earnings | 2027-01-19 Δ (was 01-21) | (E) | FMP |
| JNJ · UNH | J&J · UnitedHealth | Q4 earnings | 2027-01-20 | (E) | FMP |
| TSM · GE | TSMC (A-INELIGIBLE, ADR) · GE Aerospace | Q4 earnings | 2027-01-21 | (E) | FMP. GE **New** |
| GM | General Motors | Q4 earnings | 2027-01-26 | (E) | FMP. **New** |
| AAL | American Airlines | Q4 earnings | 2027-01-26 | (E) | FMP. **New** |
| META · TSLA · T | Meta · Tesla · AT&T | Q4 earnings | 2027-01-27 | (E) | FMP. META now FMP-sourced (was days.to projection ~01-27, agrees). **TSLA Δ 02-03 → 01-27** |
| MRK | Merck | Q4 call | 2027-02-02 | (C) | merck.com (carried; not re-fetched) |
| PEP · FDX | PepsiCo · FedEx (transition-period report) | Earnings | 2027-02-02 | (E) | FMP. FDX re-admitted per 1A.9 item 14 (orchestrator ruling 2026-10-18) |
| NOK · LMT | Nokia (ADR, A-INELIGIBLE) · Lockheed Martin | Q4 earnings | 2027-02-04 | (E) | FMP. **New** |
| GOOGL | Alphabet | Q4 earnings | ~2027-02-03 | (E) | Wall Street Horizon "INFERRED" snippet only. **New**, single aggregator |
| NVDA | NVIDIA (FQ4 FY27) | Earnings | ~2027-02-24 | (E) | days.to / WSH inferred; carried, unconfirmed |
| RIVN | Rivian | Earnings | 2027-02-25 | (E) | FMP |
| AVGO | Broadcom (FQ1 FY27) | Earnings | ~2027-03-03 | (E) | days.to projection (carried) |
| ORCL | Oracle (FQ3 FY27) | Earnings | ~2027-03-10 | (E) | days.to projection (carried) |
| MU | Micron (FQ2 FY27) | Earnings | ~2027-03-17 | (E) | days.to + WSH "INFERRED" (carried) |
| FDX | FedEx | Earnings | 2027-03-25 | (T) | FMP. Suspect row (calendar FY has no quarter ending in time); not relied on; see 1A.9 item 14 |

Not established (no reachable source states a date after the next print): AAPL, MSFT, AMZN (late Jan / early Feb 2027 by pattern only), CRWD, NTAP, OKTA, SNOW, HPE, DELL, TGT, WMT, HD, ADBE, COST, AMAT, CSCO, QCOM, SMCI, NBIS, DDOG, TTWO, PANW, XOM, CVX, CAT, GEV, LLY, VRTX, AMD, AKAM, INTC, IBM, NOW, PLTR, UBER, CRM, MRVL, INTU. Per-name re-sourcing this run (CRM, MRVL, INTU, GOOGL/MSFT/AAPL/AMZN) found no issuer notice. MRK Q1 2027-04-29 (C, carried) is outside the 04-25 edge.

### 1A.4 — Product launches, keynotes, developer events

| Ticker/Event | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| NVDA | NVIDIA | GTC Berlin | 2026-10-20 → 10-22 | held | moved to 1A.9 |
| ORCL | Oracle | **Δ Oracle AI World** (ex-CloudWorld) + SuiteWorld, Venetian, Las Vegas | **2026-10-25 → 10-28** | **(C) Δ re-upgraded from (E); conflict resolved** | Oracle FAQ (oracle.com/ai-world/faq) via search 2026-10-25: "October 25 to 28, 2026". Event begins today |
| ADBE | Adobe | Adobe MAX, Miami Beach Convention Center (online 11-10..11) | 2026-11-10 → 11-12 | (E) | three third-party listings agree; max.adobe.com not fetched |
| MSFT | Microsoft | Ignite, Moscone Center, San Francisco | 2026-11-17 → 11-20 | (E) | multiple third-party listings agree (the 11-24 outlier not reproduced); Microsoft page not fetched |
| TTWO | Take-Two | GTA VI launch (PS5/Xbox Series X/S; PC 2027) | 2026-11-19 | (C) | reaffirmed on 2026-08-07 call (secondary reporting; no primary filing fetched); no later change found |
| AMZN | Amazon | AWS re:Invent (Las Vegas) | 2026-11-30 → 12-04 | (E) | govevents/founderpath/tradefest agree; Reltio lists 12-01..04; AWS page not fetched |
| NVDA | NVIDIA | **GTC Washington DC**, Reagan Building; Huang keynote Tue 2026-12-01 2pm ET | 2026-11-30 → 12-03 | **(C) Δ upgraded; conflict resolved** | nvidia.com/en-us/gtc/dc (search result titles/snippets); the "no 2026 edition" tracker was a projection page |
| GOOGL | Alphabet | Waymo multi-city robotaxi launches | 2026 (year only) | (T) | carried |
| — | broad | CES 2027 | 2027-01-06 → 01-09 | (E) | carried; not re-verified (search returned nothing) |
| NVDA | NVIDIA | GTC 2027 San Jose | 2027-03-14 → 03-18 (main program 03-15 → 03-18; 03-14 pre-conference) | (C) | nvidia.com GTC FAQ + call-for-submissions page (per search) |

### 1A.5 — Analyst and investor days

| Ticker/Event | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| MRK | Merck | Oncology investor event at ESMO 2026, Madrid (7:30pm CET = 2:30pm ET; webcast) | 2026-10-26 | (C) **Δ re-verified** | merck.com events listing per search 2026-10-25 |
| CLS | Celestica | Investor and Analyst Day (virtual with Q3 earnings call; in-person lunch after) | 2026-10-27 | (C) **NEW** | Celestica release (celestica.gcs-web.com/node/17761) via search |
| EPAC | Enerpac Tool Group | Investor Day at NYSE | 2026-11-04 | (C) | company release PDF 2026-07-27 (carried); cap not measured |
| ENTG | Entegris | Investor Day, New York, 1:00pm ET (webcast) | 2026-11-09 | (C) **Δ re-verified** | Entegris release 2026-08-26 (Business Wire copies) |
| MH | McGraw Hill | Investor Day, New York | 2026-11-18 | (E) | briefglance summary only (carried); listing/cap not verified |
| SHC | Sotera Health | Investor Day, New York, 12:30pm | 2026-11-20 | (T) **NEW** | TipRanks/The Fly snippet, **year not shown**; unverified |
| NTR | Nutrien | Investor Day, Toronto, 1:00pm ET | 2026-11-30 | (C) **Δ re-verified** | Nutrien release 2026-09-23 (Morningstar/BNN Bloomberg) |
| NU | Nu Holdings | First Investor Day, New York (in-person + webcast investors.nu) | 2026-12-08 | (C) **NEW** | Nu Holdings release (international.nubank.com.br) |
| NKE | Nike | Investor day "Fall 2026" | — | (T) | carried, no day |
| UNH | UnitedHealth | Investor conference | ~2026-12 early | (E) | carried |
| JPM | JPMorganChase | Investor Day | 2027-02-22 | (C) | carried; not re-fetched |

Excluded: Norsk Hydro 2026-11-25 (Oslo), Alpha Bank 2026-11-05 (Athens); Goehring & Rozencwajg 2026-11-02 (investment firm, not a listed company). Searched with no 2026 announcement found: CRM, MU, CRWD, INTC, PANW, QCOM, CSCO, DELL, HPE (last cycle's search; not repeated). Two generic investor-day sweeps this run were samples, not enumerations.

### 1A.6 — Regulatory, legal, trade and macro

PDUFA rows mirrored in 1B.3. Macro dates marked (C) carried from bls.gov / federalreserve.gov pages read 2026-10-18, not re-fetched. FDA sponsor/status for PDUFA rows below rests on sponsor releases where cited, otherwise Assyro (aggregator, tagged (E)).

| Ticker/Event | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| GSK | GSK (ADR) | Bepirovirsen PDUFA, chronic hepatitis B (priority review, BTD) | 2026-10-26 | **(C) Δ upgraded** | GSK release 2026-04-27 / Ionis (Business Wire) per search 2026-10-25; no decision reported yet |
| — | broad | **FOMC decision** | 2026-10-28 | (C) | federalreserve.gov 2026-10-18 (no SEP) |
| MRK | Merck | Q3 sales and earnings call, 9:00am ET | 2026-10-29 | (C) | merck.com release (search 2026-10-25) |
| — | broad | GDP advance estimate Q3 2026 (8:30 ET) | 2026-10-29 | (E) | BEA release calendar per search; BEA page carries an appropriations-lapse notice, so dates could slip. 2nd estimate 2026-11-25, 3rd 2026-12-23 (same source, (E)) |
| — | broad | Personal income and outlays / PCE (Sept) | 2026-10-29 Δ (was 11-04) | (E) | BEA per search (same caveat). Last week's 11-04 not reproduced |
| INO | Inovio | INO-3107 BLA PDUFA (RRP, accelerated approval) | 2026-10-30 | **(C) Δ upgraded** | Inovio Q2 release 2026-08-12 (s21.q4cdn.com) per search; late-cycle review and inspections completed; accelerated-approval eligibility flagged by FDA at filing |
| AGIO | Agios | Mitapivat sNDA PDUFA, sickle cell (priority) | 2026-11-01 (Sun) | (C) | Agios release 2026-07-07 (carried) |
| — | OPEC+ (7 members) | Monthly meeting | 2026-11-01 | (C) | opec.org 2026-10-04 (carried) |
| — | broad | US midterm elections | 2026-11-03 | (C) | statutory |
| — | broad | Employment Situation (Oct) | 2026-11-06 | (C) | bls.gov |
| — | broad | CPI (Oct) | 2026-11-10 | (C) | bls.gov |
| — | broad | USTR Sec 301 exclusions expire | 2026-11-10 | (C) | carried, not re-verified |
| BTAI | BioXcel | IGALMI at-home sNDA PDUFA | 2026-11-14 | (E) | Assyro |
| CYTK | Cytokinetics | Aficamten (MYQORZO) oHCM NDA PDUFA | 2026-11-14 | (E) | Assyro |
| SMMT | Summit | Ivonescimab + chemo BLA PDUFA | 2026-11-14 | (E) | Assyro (single source) |
| Beren | Beren Therapeutics | Adrabetadex NDA PDUFA | 2026-11-17 | (E) | Assyro; not listed |
| UNP·NSC | Union Pacific / Norfolk Southern | STB comments due | 2026-11-18 | (C) | carried |
| CAPR | Capricor | Deramiocel BLA PDUFA (extended) | 2026-11-22 | (C) | Capricor 8-K 2026-08-24 (carried) |
| SVRA | Savara | Molgramostim BLA PDUFA | 2026-11-22 | (E) | Assyro + Checkrare |
| — | broad | PCE (Oct) | ~2026-11-25 | (E) | single source (financecalendar.com), carried |
| SAN | Sanofi (ADR) | Venglustat NDA PDUFA, Gaucher type 3 (priority) | 2026-11-25 | (C) | Sanofi release 2026-05-28 (carried) |
| BBIO | BridgeBio | BBP-418 NDA PDUFA | 2026-11-27 | (E) | Assyro |
| NUVL | Nuvalent | Neladalkib NDA PDUFA | 2026-11-27 | (E) | Assyro |
| ZYD | Zydus (not US-listed) | Saroglitazar NDA PDUFA | 2026-11-27 | (E) | Assyro |
| PYPD | PolyPid | D-PLEX100 NDA PDUFA (priority) | 2026-11-28 | (C) | PolyPid 8-K (carried); cap likely < $2B |
| VRTX | Vertex | Povetacicept BLA PDUFA (accelerated approval, IgAN) | 2026-11-30 | **(C)** | Vertex release 2026-06-01 "Vertex Announces US FDA Acceptance of Biologics License Application for Accelerated Approval of Povetacicept in IgA Nephropathy" (investors.vrtx.com / Business Wire), re-confirmed by the orchestrator this run; a sub-agent pass that found no sponsor date was overruled on that primary source |
| RHHBY | Roche (ADR) | Giredestrant (adjuvant) NDA PDUFA | 2026-11-30 | (E) | Assyro |
| COGT | Cogent | Bezuclastinib + sunitinib (GIST, priority) PDUFA 2026-11-30; NonAdvSM PDUFA 2026-12-30; AdvSM 2027-06-29 | 2026-11-30 / 12-30 | (C) | acceptance releases (carried); 12-30 re-seen in Cogent's own release via search |
| UNP·NSC | Union Pacific / Norfolk Southern | DOJ/USDOT comments | 2026-12-03 | (C) | carried |
| FSLR | First Solar + solar | Sec 232 tariff regime effective | 2026-12-04 | (C) | carried, not re-verified |
| — | broad | Employment Situation (Nov) | 2026-12-04 | (C) | bls.gov |
| VRTX | Vertex | Journavx sNDA PDUFA | 2026-12-05 | (T) | carried (previously tagged 2S) |
| — | broad | **FOMC decision** (SEP) | 2026-12-09 | (C) | federalreserve.gov 2026-10-18 |
| — | broad | CPI (Nov) | 2026-12-10 | (C) | bls.gov |
| — | broad | US government funding: CR runs to 12-11 | 2026-12-11 | (E) | carried |
| VNDA·ANAB | Vanda / AnaptysBio | Imsidolimab BLA PDUFA | 2026-12-12 | (E) | Assyro |
| CORT | Corcept | Relacorilant NDA PDUFA | 2026-12-17 | (E) | Assyro |
| — | Deciphera (Ono sub; not listed) | Tirabrutinib NDA PDUFA | 2026-12-18 | (E) | Assyro |
| RHHBY | Roche (ADR) | Giredestrant + everolimus NDA PDUFA | 2026-12-18 | (E) | Assyro |
| — | Camurus (not US-listed) | Oclaiz NDA PDUFA | 2026-12-18 | (E) | Assyro |
| — | Hansa (not US-listed) | Imlifidase BLA PDUFA | 2026-12-19 | (E) | Assyro |
| MLYS | Mineralys | Lorundrostat NDA PDUFA | 2026-12-22 | **(C) Δ upgraded** | Mineralys release 2026-05-06 (simianx/kavout copies) via search |
| — | broad | GDP 3rd estimate Q3 | 2026-12-23 | (E) | BEA per search (same caveat) |
| ACLX·GILD | Arcellx / Gilead | Anito-cel BLA PDUFA | 2026-12-23 | (E) | Assyro |
| VTRS | Viatris | MR-107A-02 NDA PDUFA | 2026-12-27 | (E) | Assyro |
| PRAX | Praxis | Relutrigine PDUFA (extended) | 2026-12-27 | (C) | Praxis 8-K 2026-06-29 (carried) |
| — | Saol (not listed) | SL1009 NDA PDUFA | 2026-12-30 | (E) | Assyro |
| BA | Boeing | FAA 737 MAX 10 certification "by year-end 2026" | — | (T) | carried |
| — | broad | Employment Situation (Dec) | 2027-01-08 | (C) | bls.gov |
| — | broad | CPI (Dec) | 2027-01-13 | (C) | bls.gov |
| DYN | Dyne | Z-rostudirsen BLA PDUFA (priority) | 2027-01-21 | (C) | carried |
| — | broad | **FOMC decision** | 2027-01-27 (meeting 01-26/27) | (C) | federalreserve.gov 2027 tentative schedule (press release 2025-09-05, per search) |
| PHAR | Pharming | Joenja lower-dose sNDA PDUFA | 2027-01-30 | (C) | carried; Assyro 2026-10-24 "Decided" unresolved (1A.9) |
| V | Visa | DOJ debit case fact discovery deadline | 2027-01-29 | (E) | Payments Dive (carried) |
| — | broad | Employment Situation (Jan) / CPI (Jan) | 2027-02-05 / 2027-02-11 | (C) | bls.gov |
| UNP·NSC | Union Pacific / Norfolk Southern | STB responses due | 2027-02-16 | (C) | carried |
| BMRN | BioMarin | VOXZOGO full approval | 2027-02-28 | (C) | carried |
| SRPT | Sarepta | AMONDYS 45 / VYONDYS 53 sNDAs | 2027-02-28 | (C) | carried |
| LYV | Live Nation | DOJ/states remedies phase | ~2027-02 | (E) | carried |
| WBD | Warner Bros Discovery | Antitrust trial begins | 2027-03-02 | (C) | carried |
| EXEL | Exelixis | Zanzalintinib + atezolizumab mCRC PDUFA (extended from 12-03) | 2027-03-03 | (C) | OncLive etc. citing Exelixis (carried) |
| — | broad | Employment Situation (Feb) / CPI (Feb) | 2027-03-05 / 2027-03-10 | (C) | bls.gov |
| — | broad | **FOMC decision** (SEP) | 2027-03-17 (meeting 03-16/17) | (C) | federalreserve.gov tentative schedule (per search) |
| — | broad | FTC v. Amazon trial | ~2027-03-29 | (E) | carried |
| HRMY | Harmony Biosciences | Pitolisant GR PDUFA | 2027-04-01 | (E) | simianx snippet (carried; label ambiguous) |
| — | broad | Employment Situation (Mar) / CPI (Mar) | 2027-04-02 / 2027-04-13 | (C) | bls.gov |
| — | broad | **FOMC decision** | 2027-04-28 | (C) | outside window (04-25); named only |

Tariff note: IEEPA tariffs were struck down by the Supreme Court (Learning Resources v. Trump, 6-3, February 2026, per secondary search sources); Section 232 semiconductor tariff (25%, effective 2026-01-15) stands. No dated November/December 2026 semiconductor tariff deadline was found (one search; not proof of absence).

### 1A.7 — Restructuring, M&A and structural

Carried unchanged, not re-verified this run (D1 development records since 10-18 are reused by the orchestrator, not re-searched here; D1 titles listed in run context: MSTR MSCI rule 10-18; BRZE deal 10-20; LION bid report 10-20; SPCX/SMCI/WFRD/LAD/MHO/T/NFLX/ROIV/FLY/ASST 10-21): PCRX/Viatris $36.50 (announced 10-08, close undated); PTC/Schneider $205 (10-05); OPCH CD&R/McKesson $32.05 (10-06); ON·SYNA (10-01); UBER/ezCater $2.3B (10-06); CMG·SBUX FT rumour (T); ORCL WSJ OpenAI financing report (T); CVX·HESM restructuring (10-07); WDAY take-private report (T, unverified); CAT Fabick close (late Oct, T); SWKS·QRVO; KMB·KVUE (outside date 11-02 → 2027-05-03); TECK; CTVA Vylor spin (Q4); Nasdaq-100 recon mid-Dec (E); S&P Q4 rebalance 2026-12-18 (E); DG CEO transition 2027-01-01; BA controller; S&P Q1 rebalance 2027-03-19 (E).

| Ticker/Event | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| IONQ·Elisity | IonQ / Elisity | Acquisition | 2026-10-12 | (C) announce | D1 `f5a0c793`/`394b6b39`/`982a5f26` (carried) |
| CCC | CCC Intelligent Solutions | Take-private report | 2026-10-12 | (T) | D1 report; unconfirmed (carried) |
| IONQ | IonQ | $2B offering | 2026-10-14 | (C) | D1 `c75cac94`/`ab91c8e7` (carried) |
| T·VZ·TMUS | SpaceX / Grain | 800MHz spectrum deal | 2026-10-09 | (C) | D1 `bba9dd7a`/`c69c1a3d` (carried) |
| CRWV | CoreWeave | Debt repricing | 2026-10-14 | (C) | D1 (carried) |
| CIFR | Cipher | Converts | 2026-10-13 | (C) | D1 `c4156ada` (carried) |
| FRMI·AMD | Fermi / AMD | AMD credit support | 2026-10-13 | (C) | D1 `c4156ada` (carried) |
| DELL·HPE·NTAP | Dell / HPE / NetApp | Barclays downgrades 10-14 | 2026-10-14 | (C) | D1; analyst action, context not catalyst (carried) |

### 1A.8 — Universe rails (carried, dated)

**Market-cap rail (>= $2B).** CARRIED FORWARD, NOT re-measured this run (this sub-agent made no cap measurements):
- 2026-10-04: 61 names (the 44-row A queue plus 17 candidate/tier names). 0 FAIL. Smallest AAL $8.57B, AKAM $15.84B, FSLR $18.77B.
- 2026-10-09: 50 vendor-calendar names via `company/batch-market-cap`. 0 FAIL. Smallest RIOT $6.39B.

Data is now 16 and 21 days old. The 10-22 AI-hardware/semis sell-off (XLK -3.29, per run context) moves caps by single-digit to low-double-digit percent, far from any 2x floor gap. **New names this cycle with cap NOT measured:** UAL, NFLX, GE, GM, LMT, AAL (AAL measured 10-04), CLS, NU, ENTG, EPAC, SHC, MH, NTR. Of these, EPAC, SHC and MH are possibly near the $2B floor; treat as UNMEASURED. **FAIL the cap floor, A-ineligible (carried):** TLRY, LCID, FUBO. **ADR rail (carried):** TSM, NOK, SONY, BILI, BIDU, BABA, NIO, GSK, SAN, RHHBY are A-ineligible.

### 1A.9 — Rows struck, rejected or corrected this cycle

Resolved or held 2026-10-18 → 2026-10-24 (non-earnings; earnings prints in this window are listed by the other sub-agent's section):
1. ~~NVDA GTC Berlin 2026-10-20 → 10-22~~ — window elapsed (carried (C); outcome not searched).
2. ~~PHAR Joenja 2026-10-24 (Assyro "Decided")~~ — unresolved stale-vs-live question persists; 2027-01-30 sNDA row kept.
3. ~~ORCL 2026-10-25 conference-date conflict (10-25..28 vs 10-26..29)~~ — RESOLVED: Oracle FAQ states 10-25 → 10-28 (C).
4. ~~NVDA GTC DC conflict (dates vs "no 2026 edition")~~ — RESOLVED: nvidia.com lists 2026-11-30 → 12-03, keynote 12-01 (C).
5. ~~MRVL Investor Day 2026-10-06~~ — held (search snippet; outcome not retrieved). Not a tracked row.
6. ~~INTU Investor Day 2026-09-17~~ — held; reaffirmed Q1 FY27 guidance (revenue $4.294-4.313B, non-GAAP EPS $2.44-2.48). Context only.

**Corrected (Δ):**
7. NTNX Investor Day "undated (T)" — REJECTED: Nutanix Investor Day 2026 was held 2026-04-07 (Chicago, with .NEXT; release 2026-03-13). Row removed from 1A.5.
8. ORCL AI World (E) → (C); NVDA GTC DC (E) → (C); GSK bepirovirsen (E) → (C); INO-3107 (E) → (C); MLYS (E) → (C); MRK ESMO event re-verified (C); ENTG/NTR re-verified (C).
9. VRTX povetacicept 2026-11-30: a sub-agent pass proposed (C) → (E); REVERSED by the orchestrator — Vertex's 2026-06-01 BLA-acceptance release states the 2026-11-30 PDUFA target date, so it stays (C).
10. PCE (Sept) 2026-11-04 (E) → 2026-10-29 (E) (BEA release calendar via search; supersedes last week's single-source snippet).
11. TSLA 2027-02-03 (E) → 2027-01-27 (E) per FMP; GS 2027-01-21 → 01-19 per FMP.
12. FDX: unchanged from 10-18 orchestrator ruling (see 1A.3, still no IR notice).
13. SHC Sotera Health 11-20: year not shown in snippet; kept (T).
14. Not re-verified (gate-relevant, before 11-02): CAT Fabick close; USTR 11-10; FSLR Sec 232 12-04.

### 1A.10 — Names with NO firm forward earnings date

Newly (C) this run from this sub-agent's scope: MRK Q3 call 2026-10-29 (merck.com). All other (C) earnings tagging is in the other earnings section.

**STILL NO FIRM DATE (re-searched 2026-10-25, no issuer notice found):**
- CRM — FQ3 FY27: only prior-year notices (2025-11-05 notice for 2025-12-03; 2024-11-12 notice for 2024-12-03). Notice expected early-to-mid November; early December INFERRED.
- INTU — FQ1 FY27: no notice found; late November INFERRED from history.
- MRVL — FQ3 FY27: no notice; early December INFERRED (FQ3 FY26 was ~2025-12-02).
- GOOGL / MSFT / AAPL / AMZN — Q4 CY2026: no issuer dates; only a WSH "INFERRED" GOOGL 2027-02-03.
- NBIS — 11-11 (E) no company notice (carried).

Dated (E) but company notice not found (carried from 10-18): PLTR, UBER, TTWO, CSCO, QCOM, SMCI, PANW (T), DELL, HD, NVDA, AMAT, ORCL, AVGO, CRWD, SNOW, NTAP, OKTA, HPE, MU.

### 1A.11 — Liquidity rail (30-day ADV >= $10M), carried

CARRIED FORWARD from the 2026-10-04 measurement (IBKR regular-session daily bars, 2026-08-21 -> 2026-10-02): 61 of 61 cleared; lowest VRTX $222.0M (~22x floor). NOT re-measured by this sub-agent. Vendor-only names (1A.8, 2026-10-09 list) and the new names above (UAL, NFLX, GE, GM, LMT, CLS, NU, ENTG, EPAC, SHC, MH, NTR) are UNMEASURED for ADV; >= $10M is INFERRED for the large caps, unknown for EPAC/SHC/MH. Measure on demand if promoted.

## PART 1B — Strategy C universe, 45-day window (2026-10-25 → 2026-12-09)

C qualifying types only: earnings (company IR), FDA PDUFA, FOMC. No interpretation. Window end 2026-12-09 is day 45 counted inclusively from 2026-10-25 (Oct 6 + Nov 30 + Dec 9 = 45). Tags: (C) confirmed by issuer/authority, (E) estimated, (T) tentative. "carried" = read last cycle (2026-10-18) and not re-read this run.

### 1B.1 — FOMC

| Event | Meeting | Decision date | In C window (10-25 → 12-09) | Tag | Source |
|---|---|---|---|---|---|
| FOMC | 2026-10-27 → 10-28 (no SEP) | **2026-10-28** (2:00 pm ET statement) | **YES** | (C) | federalreserve.gov/monetarypolicy/fomccalendars.htm, fetched 2026-10-25 |
| FOMC | 2026-12-08 → 12-09 (**SEP**) | **2026-12-09** | **YES, on the boundary: day 45** (was OUTSIDE the window last cycle at +7 days) | (C) | same fetch; page states each date is tentative only until confirmed at the preceding meeting, none flagged tentative for 2026 |
| FOMC | 2027-01-26 → 01-27 | 2027-01-27 | No (A window) | (C), 2027 per the page's general tentative clause | same fetch |
| FOMC | 2027-03-16 → 03-17 (SEP) | 2027-03-17 | No (A window) | same | same fetch |
| FOMC | 2027-04-27 → 04-28 | 2027-04-28 | No (A window ends 04-25) | same | same fetch |

Two FOMC meetings fall inside the C window: 2026-10-28 and 2026-12-09. No other 2026 meeting remains.

### 1B.2 — Earnings inside the C window: company-IR-confirmed subset

Window 2026-10-25 → 2026-12-09. Names = last week's subset plus mega/large caps with liquid options (Nasdaq key-less calendar ≥ $2B; mcap and timing from `nasdaq_ge2b.json`). **Struck (printed before the window; FMP shows actuals):** META, TSLA, NFLX, GE, UAL, IBM, T, GM, LMT, AAL, CB (10-20 → 10-22). "NEW" = confirmed or re-read this run.

**Company-IR confirmed (C)**

| Date | Ticker | Timing | Mcap ($B) | Confirmation |
|---|---|---|---|---|
| 2026-10-27 | V | after close | 740 | investor.visa.com (carried) |
| 2026-10-28 | MSFT | after close | 3,870 | Microsoft release 2026-10-07 (carried) |
| 2026-10-28 | GOOGL | after close; call 4:30 pm ET | 3,965 | **NEW** Alphabet IR release 2026-10-06, abc.xyz/investor/news (Tavily result; call Wed 10-28 1:30 pm PT). Was "not yet confirmed" last week |
| 2026-10-28 | GEV | pre-market | 220 | gevernova.com (carried) |
| 2026-10-28 | NOW | after close | 162 | newsroom.servicenow.com (carried) |
| 2026-10-29 | AMZN | after close | 2,701 | aboutamazon.com (carried) |
| 2026-10-29 | LLY | pre-market | 1,230 | investor.lilly.com (carried) |
| 2026-10-29 | MRK | pre-market | 363 | merck.com (carried) |
| 2026-10-29 | INTC | after close | 452 | intc.com 2026-10-06 (carried) |
| 2026-10-29 | CAT | pre-market | 324 | caterpillar.com (carried) |
| 2026-10-29 | FSLR | after close | 18 | First Solar release (carried) |
| 2026-10-30 | XOM | pre-market | 733 | investor.exxonmobil.com (carried) |
| 2026-10-30 | CVX | pre-market | 448 | Chevron advisory (carried) |
| 2026-10-30 | ABBV | pre-market | 504 | AbbVie release 2026-10-01 (carried) |
| 2026-11-02 | VRTX | after close | 136 | Vertex release 2026-10-07 (carried) |
| 2026-11-02 | PLTR | after close; webcast 5:00 pm ET | 471 | **NEW** Palantir Business Wire release (read via BigGo/StockTitan/NatLawReview copies; investors.palantir.com not fetched) |
| 2026-11-03 | AMD | after close | 829 | ir.amd.com 2026-10-06 (carried) |
| 2026-11-04 | UBER | pre-market; call 8:00 am ET | 141 | **NEW** investor.uber.com release 2026-10-05 |
| 2026-11-04 | DDOG | — | — | Datadog release (carried) |
| 2026-11-05 | AKAM | — | — | Akamai release 2026-10-08 (carried) |
| 2026-11-18 | TGT | pre-market | 72 | corporate.target.com (carried) |
| 2026-11-19 | WMT | pre-market | 961 | corporate.walmart.com (carried) |

**Confirmed by a secondary relay only (issuer release not read first-hand)**

| Date | Ticker | Timing | Mcap ($B) | Note |
|---|---|---|---|---|
| 2026-11-02 | AAPL | after close; 2:00 pm PT | 5,082 | MacTrast / iClarified / iPhoneSoft relay an Apple IR notice; apple.com and investor.apple.com pages fetched this run were JS shells and showed no date. Held at (C-secondary) |

**Vendor-only (E) — no issuer notice found**

| Date | Ticker | Timing (Nasdaq) | Mcap ($B) | Source / check |
|---|---|---|---|---|
| 2026-11-18 | NVDA | not supplied | 5,114 | FMP + Nasdaq. Checked this run: NVIDIA's IR events page (JS shell) and a Tavily domain-limited search returned no Q3 FY2027 call notice; a prediction-market page also says 11-18. NVIDIA historically posts its notice 2-3 weeks ahead, so absence is not yet informative |
| 2026-10-27 | KO, BA | pre-market | 410, 148 | vendor |
| 2026-10-29 | SBUX | after close | 116 | vendor |
| 2026-11-03 | PFE, SHOP, SMCI | pre/pre/after | 173, 218, 22 | vendor |
| 2026-11-04 | QCOM | after close | 182 | vendor |
| 2026-11-09 | TTWO | after close | 39 | vendor |
| 2026-11-11 | CSCO | not supplied | 414 | vendor |
| 2026-11-17 | HD, DIS | pre-market | 327, 195 | vendor |
| 2026-11-18 | PANW | not supplied | 290 | vendor |
| 2026-11-24 | DELL | not supplied | 288 | vendor |
| 2026-12-01 | CRWD | not supplied | 244 | vendor |
| 2026-12-02 | SNOW | not supplied | 111 | vendor |
| 2026-12-03 | DOCU | — | — | FMP only |
| 2026-12-09 | ADBE | not supplied | 105 | FMP + Nasdaq; day 45 of the window |

Dropped from IR-pending list vs 10-18: GOOGL, PLTR, UBER (now C). Still unconfirmed: NVDA and the vendor rows above. COST (12-10) and the 12-17/12-18 prints (NKE, CCL) fall outside the window.

### 1B.3 — FDA PDUFA dates in window (2026-10-25 → 2026-12-09)

Each row resolved against FDA, a sponsor release, or the sponsor's own filing where one was reachable; "no decision found" means no FDA announcement or sponsor release of an action was returned by search on 2026-10-25. Cap/ADV not measured here. "Instrument" = US-listed non-ADR.

| Date | Ticker | Drug / indication | Tag | C-eligible instrument | Resolution / note |
|---|---|---|---|---|---|
| 2026-10-26 | GSK (ADR) | Bepirovirsen / chronic hepatitis B, priority review + breakthrough | (C) per GSK statements via secondary copies | NO — ADR | No decision found. **Sponsor is GSK**; one aggregator (biopharmawatch) mislabels the ticker IONS (Ionis is the licensor) |
| 2026-10-29 | Sun Pharma | ILUMYA (BLA) | (E) carried | NO — not US-listed | not re-verified |
| 2026-10-30 | INO | INO-3107 BLA / RRP, standard review | (C) | instrument yes; stock ~$1, chain unusable (last measured 10-16) | Review goal date 10-30 per Inovio BLA-acceptance release. No decision found. FDA flagged preliminary doubt on accelerated-approval eligibility; mid-cycle review completed (secondary report, undated) |
| 2026-11-01 (Sun) | AGIO | Mitapivat sNDA / sickle cell disease, priority review | (C) | instrument yes | Agios release 2026-07-07: goal date 11-01. No decision found, no extension found |
| 2026-11-14 | SMMT | Ivonescimab + chemo BLA / EGFRm NSCLC post-TKI | **(C) upgraded from (E)** | instrument yes | Summit BLA-acceptance release 2026-01-29 (BusinessWire): PDUFA 11-14. Release notes FDA position that a significant OS benefit is needed. No decision or extension found |
| 2026-11-14 | CYTK | Aficamten (MYQORZO) label expansion | (E), **unverified** | instrument yes | oHCM NDA was decided Dec 2025 (approved, per Zacks); the 11-14 date appears only on aggregators and two Cytokinetics-specific searches could not find the underlying filing. Carry as unverified |
| 2026-11-17 | Beren | Adrabetadex | (E) carried | NO — not listed | |
| 2026-11-22 | CAPR | Deramiocel / DMD | (C) | instrument yes | Capricor 8-K 2026-08-24 (carried); extension from 08-22 confirmed by aggregator |
| 2026-11-22 | SVRA | Molgramostim / aPAP | (E) | instrument yes | aggregator shows extension of three months; no sponsor release read |
| 2026-11-25 | SAN | Venglustat / type 3 Gaucher, priority review | (C) carried | NO — ADR | |
| 2026-11-27 | BBIO | BBP-418 / LGMD2I/R9 | (E) | instrument yes | aggregators only |
| 2026-11-27 | GSK (ADR) | Neladalkib / ALK+ NSCLC, priority review | (C) | NO — **sponsor is now GSK** | Nuvalent release of 2026-05-27 (via its news listing): PDUFA 11-27. **GSK completed its $10.6B acquisition of Nuvalent on 2026-07-15** (GSK release), so NUVL is no longer a US-listed instrument; row moved from NUVL to GSK |
| 2026-11-27 | Zydus | Saroglitazar | (E) | NO — not US-listed | |
| 2026-11-28 | PYPD | D-PLEX100 / SSI, priority review | (C) carried | instrument yes; cap likely < $2B | |
| 2026-11-30 | VRTX | Povetacicept BLA / IgAN (accelerated) | (C) | instrument yes; large cap | Vertex release 2026-06-01 (carried); aggregator lists no change |
| 2026-11-30 | COGT | Bezuclastinib + sunitinib / GIST, priority review | (C) carried | instrument yes | |
| 2026-11-30 | RHHBY | Giredestrant adjuvant | (E) carried | NO — ADR | |
| 2026-12-05 | VRTX | Journavx sNDA | (T) carried (2S) | instrument yes | not on the Q4 aggregator list; not re-verified |
| Nov (undated) | REGN | Cemdisiran / gMG | undated | instrument yes | month only; no day, so no date asserted |
| Q4 (undated) | PFE | Talzenna + Xtandi label expansion | undated | instrument yes | quarter only |

**Resolved and struck (do not re-import):**
- ~~2026-10-15 RHHBY Enspryng / TED~~ — APPROVED 10-16 (carried).
- ~~2026-10-17 VTRS MR-141 phentolamine / presbyopia~~ — **reported approved** as Ryzumvi 0.75% (Pharmacy Times, dated 2026-10-19); single secondary source, no FDA or Viatris release returned. Struck as past; outcome reported-unverified.
- ~~2026-10-24 PHAR Joenja~~ — aggregator "Decided"; stale/other application (carried).
- ~~2026-11-14 BTAI IGALMI~~ — IBKR resolves Bioxcel only as BTAIQ on PINK with no option section (carried from 10-18); no option structure can exist.
- ~~NUVL (ticker)~~ — acquired by GSK 2026-07-15; neladalkib row now under GSK above.
- ~~Zidesamtinib~~ — approved 2026-07-22 to Nuvalent (rule 8; not re-imported). ~~IONS zilganersen~~ — approved 2026-09-03 (not re-imported). ~~MRK Welireg + Lenvima~~ — approved 2026-09-25 (carried).
- Not a PDUFA: NRXP NRX-100 2026-11-10 is a GDUFA (ANDA) goal date; excluded.
- EXEL zanzalintinib moved to 2027-03-03 (carried); outside the window.

No PDUFA date was found in the window for MRK or LLY. Nothing dated 12-01 → 12-09 other than the VRTX 12-05 carried row. Coverage is one aggregator calendar (biopharmawatch, 17 entries 10-25 → 12-10) plus per-drug searches: a floor, not a census.

---

## PART 2A — Strategy A ranked shortlist

### The A-queue census — the PINNED query, run verbatim

`SELECT * FROM state.open_queue WHERE strategy = 'A'` → **44 rows** (MEASURED 2026-10-25; unchanged from 2026-10-18): ADBE, ORCL, TGT, XOM, HPE, MSFT, QCOM, WMT, FSLR, NOW, MRVL, AMD, DDOG, SNOW, AMAT, TTWO, DELL, PANW, CVX, LLY, AMZN, CRM, MRK, GOOGL, GEV, HD, SMCI, AVGO, META, JPM, MU, INTU, CAT, IBM, INTC, CRWD, NTAP, CSCO, NBIS, NVDA, VRTX, AAPL, OKTA, AKAM. The enumeration above is the query's own 44 rows, not a hand list, so there is no discrepancy to reconcile. Every "already queued" / "NEW" mark below is tested against it.

### STEP 1 — the GATE DATE, re-derived from scratch, with the arithmetic shown

**DERIVED GATE DATE = 2026-11-02.** Derived under the Rev 52 STEP 1 (owner directive 2026-10-22): the earliest of inputs (a), (b), (c). This is the first cycle on the Rev 52 derivation; the 2026-W42 derivation (price leg, quiet-clock leg, `state.rerisking_limb_status`) is RETIRED and was not run. Under the symmetric rubric every scheduled re-score is reachable, so 11-02 is the gate itself — last week's "provable lower bound, probable true gate 12-01" framing and its 21-name provisional list lapse with the quiet clock and are NOT carried.

**Router state read first.** A's `STRATEGY_ACTIVATION` reads **DO-NOT-ACTIVATE** (`state.current_regime`, as_of 2026-10-22; the D2 2026-10-20 technical-flip divergence `div-A-202610-1` was RESOLVED 2026-10-22 with the standing rate/oil call unrefuted). A is not ACTIVATE, so CATALYST-GATE MODE is live, not inert.

- **(a) Next scheduled M1a/M1b re-score.** `SELECT COUNTIF(routine='M1a') m1a, COUNTIF(routine='M1b') m1b FROM ops.run_log WHERE routine IN ('M1a','M1b') AND status='completed' AND run_date >= DATE_TRUNC(2026-10-25, MONTH)` → **m1a = 1, m1b = 1**. `m1b >= 1`, so (a) = next month's first trading day per `state.market_calendar` = **2026-11-02** (Monday; 10-31 and 11-01 non-trading).
- **(b) Open `PENDING_REGIME_REFRESH` `regime-refresh` items** (`state.open_queue_detail`): **none** → does not apply.
- **(c) A refresh D2a is already due to queue.** D2a Step 0 REFRESH REQUEST detection query, run verbatim (14-day look-back over `router-review` entries carrying `fields.measured_trigger`, anti-joined to any `regime-refresh` row counting at or after `logged_ts`) → **0 rows** → does not apply.
- **Earliest of (a), (b), (c) = 2026-11-02.**

**FAIL-OPEN status: not triggered.** All three inputs read cleanly.

### STEP 2 — direction rail

Strategy A is long-only. The rail ran before ranking and before the gate classification. Evidence read this week: D1 rows 10-18..10-22 (run_context), a Tavily news search on the 10-21/22 prints (MEASURED, secondary), and IBKR RTH daily bars through 2026-10-23.

- **Nine names stay `DIRECTION-INADMISSIBLE (A long-only rail)`**, the same set as 2026-10-18: AMAT, WMT, ADBE, HD, AKAM, plus the fuel-shock cluster DAL, CCL, UAL, AAL. Nothing read this week reverses any direction.
- **Fuel-shock cluster:** Brent Dec reached 113.17 on 10-22 (+4.0%, Houthi strikes on Saudi Arabia; D1 `sector screen 10-22`), above the 105.9 stored on the rerisking view last cycle. That strengthens the bearish marks.
- **AMAT: mark kept but flagged for D2.** Lam Research printed a record quarter 10-21 (revenue $8.22B, +54% y/y; secondary) and in July raised its 2026 WFE view to the low $150B range. That sits against AMAT's "China WFE cliff" framing. LRCX still fell about 11.8% on supply-constraint and guide commentary. No reversal of AMAT's direction is established; D2 should re-test it.
- **WMT: mark kept, thinner.** Staples were bid (XLP +3.31 on 10-22; PG +5.6% on its print). That contradicts the low-income-consumer leg of the bearish mark. One defensive-rotation day is not a reversal.
- **TGT stays DIRECTION UNRESOLVED** (carried; refuted bearish thesis, no replacement). It is ranked below the tier and is not eligible for the top-10.
- **No new bearish names added.** Newly surfaced bearish-leaning ideas (e.g. NFLX after a light Q4 guide and an ad-forecast cut; IBM after a gross-margin miss and the CEO saying enterprises question AI returns) are Strategy B territory and are not carried here.

### STEP 3 — classification and counts

Gate date **2026-11-02** (orchestrator-derived; not re-derived here). SPENT-BY-GATE iff a dated catalyst falls strictly before 2026-11-02 and no dated catalyst falls on or after it. Undated or mixed is GATE-SURVIVING (fail-open). AAPL, VRTX and PLTR (11-02) are ON the gate date, so they are GATE-SURVIVING.

**59 carried: 50 ranked admissible (one of them, TGT, direction-unresolved) + 9 DIRECTION-INADMISSIBLE.** Against the gate: **52 GATE-SURVIVING, 7 SPENT-BY-GATE.** Admissible: 50 (43 surviving, 7 spent). Inadmissible: 9 (all 9 now surviving).

SPENT-BY-GATE (7, all ranked): GEV 10-28, NOW 10-28, CAT 10-29, LLY 10-29, INTC 10-29, XOM 10-30, CVX 10-30. All dates MEASURED from the Nasdaq per-day calendar (`nasdaq_ge2b.json`); XOM, CVX, CAT, GEV, NOW also issuer-confirmed last week.

**Changes of class versus 2026-10-18 and why:**
- **META: SPENT to SURVIVING.** The 10-21 print is consumed; the next print is **2027-01-27 (E)** (FMP). Same treatment as JPM/BAC last cycle.
- **GE: SPENT to SURVIVING.** The 10-20 print is consumed (EPS 2.25 vs 2.01 est; revenue $14.12B vs $12.88B, FMP); next **2027-01-21 (E)** (FMP).
- **UAL, AAL (inadmissible): SPENT to SURVIVING.** Prints consumed; next **2027-01-19 (E)** and **2027-01-26 (E)** (FMP).
- **IBM: DROPPED.** The 10-21 print is consumed and no dated forward catalyst was found. It stays on the A queue (not removed from the census). It would return only if a forward catalyst is found next cycle.
- **Date moves from the Nasdaq per-day calendar (MEASURED, time-of-day mostly "not supplied", so (E) unless the issuer notice is cited):** TTWO earnings 11-05 (E) to **11-09** (a gaming site also says 11-09 AMC; no Take-Two notice found); QCOM 11-11 (E) to **11-04**; NBIS 11-11 to **11-10**; INTU undated to **11-19**; PANW 11-12/18 (T) to **11-18**; MRVL undated to **12-01**; CRM undated to **12-02**; DELL and NTAP to **11-24** (NTAP was 12-01); SNOW 12-02 unchanged; ORCL 12-10 to **12-09**; CRWD, OKTA 12-01 unchanged; PLTR 11-02 unchanged.
- **Fail-open survivors now:** LRCX (printed; next print late January INFERRED, undated), GOOGL (Waymo launches undated alongside the 10-28 print). MRVL, CRM and INTU are no longer undated.
- **Weak survivors:** MSFT (Ignite 11-17..20, E, third-party listing) and AMZN (re:Invent 11-30..12-04, E); their substantive catalysts (10-28, 10-29 prints) are spent. V (DOJ discovery close 2027-01-29, E) is thin.
- **Fragile (one day earlier flips them):** AAPL, VRTX, PLTR (all 11-02); AMD, SHOP, SMCI, ANET, ETN (11-03).
- **No alternative gate is carried.** The 2026-W42 artifact listed names that "would be SPENT if the gate is 2026-12-01"; that exposure rested on the quiet-clock leg, which Rev 52 (owner directive 2026-10-22) RETIRED. Under the symmetric rubric every scheduled re-score is reachable, so 2026-11-02 is the gate itself, not a lower bound, and no 12-01 provisional list is published this cycle. Thin-margin names (AAPL, VRTX, PLTR ON 11-02; AMD, SHOP, SMCI, ANET, ETN on 11-03) are surviving on the arithmetic, and only an earlier out-of-cycle re-score (a D2a refresh queued after this run) could move the gate behind them — see STEP 4 next cycle.

### Price context (IBKR regular-session daily bars, MEASURED; 2026-10-23 close and move since 10-16 close)

| Ticker | 10-16 | 10-23 | Change |
|---|---|---|---|
| TTWO | 205.28 | 203.69 | -0.8% |
| NVDA | 214.13 | 210.96 | -1.5% (221.97 on 10-21, 212.21 on 10-22: -4.4% on the rout day) |
| VRTX | 499.74 | 523.93 | +4.8% |
| FSLR | 172.64 | 171.99 | -0.4% |
| AVGO | 328.75 | 321.68 | -2.2% (-10% from 357.31 on 10-13) |
| CSCO | 107.39 | 106.50 | -0.8% |
| AMD | 528.75 | 516.79 | -2.3% (552.72 on 10-21, 507.93 on 10-22: -8.1% on the rout day) |
| AAPL | 343.46 | 347.73 | +1.2% |

### Week narrative driving the revisions (MEASURED from D1 rows and Tavily secondary, labelled)

- **10-21 after close / 10-22: AI-capex rout.** Nasdaq -2.60%, S&P -1.21%, SMH -5.99%, XLK -3.29 (D1 `10-22`). Meta printed revenue $64.60B (+26%), but raised the low end of 2026 capex to $135-145B, posted capex $34.91B vs operating cash flow $32.79B and the first negative free cash flow ($-2.12B), plus a $9.89B legal charge and a new non-voting Class C share plan (effective January 2027); stock about -7%. Tesla cut 2026 capex to about $20B (from more than $25B), net income $787M, stock lower. Lam printed a record $8.22B quarter but fell about 11.8% on a supply-constraint-clouded outlook. IBM fell about 5.7% (gross-margin miss; CEO said enterprise customers question AI returns). (Tavily search 10-24; investing.com, tradingnews, tradingkey, Stocktwits via Yahoo; all secondary.)
- **Reading for A:** the market is now rewarding capex restraint and punishing capex acceleration ("returns before more spending"). That is a direct challenge to the supplier-side bullish framings (NVDA, AVGO, AMD, CSCO, ANET) and to hyperscaler names (MSFT, AMZN, GOOGL) heading into 10-28/29. It is also the new counter-evidence every row below must carry in construction.
- **Defensives bid:** XLP +3.31, XLU +2.07, 10Y -18.5bp to about 4.96%. LMT rose about 7% and PG about 5.6% on prints. SMCI surged on a raised outlook after the 10-21 close (AI-server demand resilient). NFLX fell on a light Q4 guide.
- **Energy:** Brent Dec 113.17 (+4.0%) on 10-22 (D1), XLE -0.87 on that day.

### TOP-10 — the actionable tier

**Selection rule (stated for W4).** The top-10 contains only ADMISSIBLE, GATE-SURVIVING names. A SPENT name is excluded outright when a surviving admissible name of comparable conviction exists; there are none in the tier. A name whose only post-gate date is a weak (E) conference (MSFT, AMZN) is placed at 11-12, not in the top-10, because a thesis built on a spent print cannot be actionable when A first reopens; this reverses last week's promotion of AMZN and the hold of MSFT. A name whose catalyst falls ON the gate (AAPL, VRTX) stays eligible. All ten rows are long.

**1. TTWO - Take-Two Interactive.** (a) Bullish, under-valued. (b) GTA VI is the largest entertainment launch attempted; the market has repeatedly discounted Rockstar holding a date. Take-Two's fiscal-Q4 2026 release reaffirmed the 2026-11-19 launch and tied fiscal 2027 to it ("record levels of operating performance", search summary); FY27 net bookings $8.0-8.2B reaffirmed 2026-08-07 (press reports). Documents for construction: last two 10-Qs (deferred revenue, preload), the fiscal-Q2 release. No October update found. (c) **GTA VI launch 2026-11-19 (C)**; fiscal-Q2 earnings **2026-11-09 (E)** AMC (Nasdaq calendar and one gaming site, call 4:30 pm ET; no Take-Two notice found, was 11-05 E). (d) On the A queue since 2026-08-09 (already queued); no open position. (e) Top-10, conviction **4**. *10-23 close 203.69 (-0.8% on the week).* GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-09)

**2. VRTX - Vertex Pharmaceuticals.** (a) Bullish. (b) Two regulatory decisions in a five-week band: povetacicept (IgAN) accelerated-approval BLA, PDUFA **2026-11-30 (C)** per Vertex's own 2026-06-01 release (news.vrtx.com, carried from last week, not re-read); the Crinetics acquisition (closed 2026-09-01); an ~$8.8B IPR&D charge lands in the 11-02 print (known, non-cash). Journavx sNDA 2026-12-05 (2S, unverified here). Defensive rotation helps the tape. (c) Earnings **2026-11-02 (C)** AMC (Nasdaq calendar; company-issued date carried from last week), ON the gate; PDUFA 2026-11-30 (C). (d) Queued 2026-07-05 (already queued); no open position. (e) Top-10, conviction **4**. *10-23 close 523.93 (+4.8% on the week).* GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-02)

**3. FSLR - First Solar.** (a) Bullish. (b) Sec 232 polysilicon-and-derivatives regime (proclamation signed 2026-08-06; effective 12:01 am ET 2026-12-04; minimum import price on polysilicon, wafers, cells and modules; secondary coverage cites about a $0.38/W module floor). CdTe panels contain no polysilicon, so rules that punish importers protect pricing; BMO Outperform ($263). The proclamation text and the 10-Q are the primary sources to confirm in construction. Earnings 10-29 (Nasdaq, after hours) is spent. (c) **Sec 232 regime effective 2026-12-04 (C)**. (d) Queued 2026-09-06 (already queued); no open position. (e) Top-10, conviction **4**; the most policy-anchored, least AI-capex-exposed name in the tier. *10-23 close 171.99.* GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-12-04)

**4. NVDA - NVIDIA.** (a) Bullish. (b) AI-compute and memory re-rating; FQ2 10-Q, last four transcripts, GTC materials. Supply side: TSMC's Q3 beat (10-15; Q4 guide $52.3-54.3B; chairman said AI demand exceeds supply, advanced packaging binding; carried from last week). **Material new counter-evidence:** the 10-21/22 capex-restraint reaction (Meta negative FCF, Tesla capex cut, IBM CEO on AI-ROI); NVDA -4% on 10-22. Carried: CoreWeave credit stress (record CDS for CoreWeave and Oracle), circular-financing objection (2026-07-27), FT OpenAI-revenue report (10-08). (c) Earnings **2026-11-18 (E)** (FMP and Nasdaq calendar; time not supplied); GTC DC 11-30 (E, conflicting listings). GTC Berlin (10-21) is spent. (d) Queued 2026-05-09 (already queued); no open position. (e) Top-10, conviction **3** (lowered from the #2 position: the AI-capex financing and ROI question is now live on tape). *10-23 close 210.96 (221.97 on 10-21).* GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-18)

**5. ANET - Arista Networks. NEW.** (a) Bullish. (b) AI back-end and front-end switching share; Q3 guide was revenue about $3.3B, non-GAAP operating margin 48-49%, EPS $1.06-1.08 (Q2 release exhibit via SEC, search summary this run). Gap hypothesis (INFERRED, preliminary): the AI-capex rout of 10-22 is pricing hyperscaler capex restraint, but Arista's disclosed customer concentration and deferred revenue/purchase commitments should show whether orders are capex-timing or demand-driven; documents to pull in construction: Q2 10-Q, last four transcripts, Q3 release. Counter-evidence: customer concentration (Meta, Microsoft), and Meta's capex floor rising is a positive, while the market read is negative. (c) Earnings **2026-11-03 (C)** AMC, call 1:30 pm PT (Arista press release 2026-10-06, arista.com), one day after the gate. (d) **NOT on the A queue; new intake.** No open position. (e) Top-10, conviction **3**; admitted because the date is issuer-confirmed and post-gate, and there is no surviving non-AI name of comparable quality with a fully dated catalyst. Fragile: one day past the gate. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-03)

**6. COP - ConocoPhillips. NEW.** (a) Bullish. (b) Replaces the energy-seam exposure that XOM and CVX carried before their prints became spent. Brent Dec 113.17 on 10-22 (D1), Houthi/Hormuz disruptions (10-12..10-15 events carried from last week); an upstream pure-play captures crude beta without refining or chemicals dilution. Gap hypothesis (INFERRED, preliminary): consensus models a transient shock; physical flow data (Kpler, Hormuz about one-tenth of normal flow on 10-15) points to a structural one. Documents for construction: Q2 10-Q (realized prices, hedging), the Q3 release, Marathon-acquisition-era guidance. Counter-evidence: a 4% Brent day on 10-22 coincided with XLE -0.87, i.e. equities are not pricing the spot move; a Hormuz de-escalation reverses it. (c) Earnings **2026-11-05 (C)**, before the open, call 12:00 pm ET (ConocoPhillips release of 2026-09-24 via Business Wire/finviz; some calendars say 11-06, the company wins). (d) **NOT on the A queue; new intake.** No open position. Concentration note: same shock seam as the spent XOM/CVX rows. (e) Top-10, conviction **3**. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-05)

**7. AAPL - Apple.** (a) Bullish. (b) FQ4 results Monday 2026-11-02, 2:00 pm PT (Apple notice via MacRumors/MacTrast, carried; Apple IR page still not reached). FQ3 call guide: September-quarter revenue growth 9-11% (implies about $111.7-113.7B), iPhone growth mid-teens; FMP consensus revenue $113.3B and EPS $1.99, Nasdaq EPS forecast $2.00 (8 estimates). A defensive mega-cap with a quantified guide; the only tier name that rose through the AI rout (+1.2% on the week). Watch items: memory pricing and supply. (c) Earnings **2026-11-02 (C)**, ON the gate; zero-day margin is the standing fragility. (d) Queued 2026-05-02 (already queued); no open position. (e) Top-10, conviction **3**. *10-23 close 347.73.* GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-02)

**8. AVGO - Broadcom.** (a) Bullish. (b) Custom silicon and AI networking attach; TSMC's packaging-constrained supply is a positive read-through. Counter-evidence: BofA note on a roughly $370B AI-debt vehicle, WSJ OpenAI-capacity financing report, CoreWeave credit stress, and the 10-22 capex-restraint reaction; AVGO is -10% from 10-13 (321.68 vs 357.31). (c) Earnings **2026-12-09 (E)** (aggregator; absent from the Nasdaq calendar pull and FMP; fiscal year ends about 11-01 so a December print is consistent). (d) Queued 2026-05-09 (already queued); no open position. (e) Top-10, conviction **3**. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-12-09)

**9. AMD - AMD.** (a) Bullish, contested on competitive position rather than direction. (b) Carried: the exclusive SpaceX AI-compute socket lost to NVDA (2026-08-05). New: -8.1% on 10-22 (552.72 to 507.93), -14.6% from 10-13 (605.53) on the CoreWeave/AI-capex thread; TSMC supply read-through positive; FMP consensus EPS $1.94, revenue $13.08B for the 11-03 print. (c) Earnings **2026-11-03 (C)** AMC, call 5:00 pm ET (ir.amd.com 2026-10-06, carried). (d) Queued 2026-05-29 (already queued); no open position. (e) Top-10, conviction **3** (lowest in the tier). *10-23 close 516.79.* GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-03)

**10. CSCO - Cisco.** (a) Bullish. (b) AI-networking orders: fiscal-2026 hyperscaler AI orders raised to about $9B (from $5B), FY27 AI-infrastructure revenue about $7.5B flagged, some customers may have pulled orders forward; non-GAAP gross margin 66.3% (from 68.4%) on AI-hardware mix (secondary summaries, not cross-checked to the 10-K). Valuation-reset objection carried. (c) Earnings **2026-11-11 (E)** (FMP and Nasdaq calendar; time not supplied; no Cisco notice found, 2025 notice came 11-03). (d) Queued 2026-05-09 (already queued); no open position. (e) Top-10, conviction **3**. *10-23 close 106.50 (-0.8% on the week).* GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-11)

### 11-20

**11. MSFT - Microsoft.** (a) Bullish. (b) Azure AI capacity commentary; July FQ4: revenue about $90B (+18%), Azure +43%, ~45% pointed for FQ1 (07-29 call summary; not cross-checked). New: Meta's capex-restraint reaction is read-across risk into the 10-28 print. (c) Earnings **2026-10-28 (C)** AMC (spent); Ignite **2026-11-17..20 (E)** is the only post-gate catalyst and a third-party listing. (d) Queued 2026-07-05 (already queued). (e) 11-20, conviction **3**; demoted from #8 per the selection rule. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-17)

**12. AMZN - Amazon.** (a) Bullish. (b) AWS Q2 revenue $42.2B (+36.7%), backlog $496B, 2026 capex $220B (secondary summary of the Q2 call). (c) Earnings **2026-10-29 (C)** (spent); re:Invent **2026-11-30..12-04 (E)**. (d) Queued 2026-07-12 (already queued); **two open Strategy D lots** (`D:AMZN:2026-07-09`, `D:AMZN:2026-07-30`); D2 should confirm the A and D sleeves are distinct. (e) 11-20, conviction **3**; demoted from #9. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-30)

**13. QCOM - Qualcomm.** (a) Bullish. (b) Stellantis Snapdragon expansion, auto/IoT diversification; no fresh document. (c) FQ4 **2026-11-04 (E)** (Nasdaq calendar after hours; no Qualcomm notice found, 2025 print was Wed 11-05; was 11-11 E). (d) Queued 2026-05-01 (already queued). (e) 11-20, conviction **3**. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-04)

**14. LRCX - Lam Research. NEW.** (a) Bullish. (b) Printed 10-21: record revenue $8.22B (+54% y/y), adjusted EPS $2.20 vs $2.18, operating margin above 40% for the first time (BigGo/TradingNews, secondary); stock fell about 11.8% on 10-22 on a supply-constraint-clouded outlook. July: raised 2026 WFE view to the low $150B range. Gap hypothesis (INFERRED, preliminary): the market sold a supply-limited guide as demand fragility. Counter-evidence: AI-capex restraint, and the 2026-07-02 -10% day on "AI spending near peak" worries. Documents for construction: 10-Q, shipment-vs-revenue disclosures, transcript. (c) Next print **undated**; late January INFERRED from the fiscal pattern (Jul-29, Oct-21), not sourced. (d) **NOT on the A queue; new intake.** (e) 11-20, conviction **2** (undated, no forward dated catalyst; included because the fail-open rule treats undated as surviving). GATE: GATE-SURVIVING (gate 2026-11-02; catalyst undated)

**15. PLTR - Palantir.** (a) Bullish. (b) Government and commercial bookings. (c) Earnings **2026-11-02 (E)** AMC (FMP, Nasdaq, Benzinga; no company release found), ON the gate; thinnest margin among non-issuer-dated names. (d) Not on the A queue. (e) 11-20, conviction **2**. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-02)

**16. ORCL - Oracle.** (a) Bullish. (b) AI-capex backlog thesis. Adverse: record 5-year CDS for Oracle and CoreWeave, the WSJ OpenAI-financing report (10-07/08), and the 10-22 capex-restraint reaction. Funding structure is the live question. (c) FQ2 **2026-12-09 (E)** (Nasdaq calendar; was 12-10); AI World 10-25..28 (E, conflicting listings). (d) Queued 2026-05-09 (already queued). (e) 11-20, conviction **2**. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-12-09)

**17. UBER - Uber.** (a) Bullish. (b) The ~3,300-role restructuring margin effect lands in this print; ezCater $2.3B acquisition (10-06). (c) Earnings **2026-11-04 (E)** pre-market (Nasdaq, FMP; no company notice). (d) **NOT on the A queue**; open Strategy D lot `D:UBER:2026-07-09`. (e) 11-20, conviction **2**. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-04)

**18. CEG - Constellation Energy. NEW.** (a) Bullish. (b) Power for AI load and nuclear contracting; Q2 2026: adjusted operating earnings $2.55/share, full-year guidance raised to $11.50-12.50 (search summary of the Q2 release, secondary). Gap hypothesis (INFERRED, preliminary): the AI-power complex sold off with the rout but contract-backed nuclear cash flow is less capex-cycle exposed than chips. Counter-evidence: power/AI-power names sold off on 10-19 and 10-22 (D1); GLJ-style sell views on the sector. (c) Earnings **2026-11-06 (E)** pre-market (Nasdaq calendar; no Constellation notice found; the 2025 Q3 call was 11-07). (d) **NOT on the A queue; new intake.** (e) 11-20, conviction **2**. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-06)

**19. SMCI - Super Micro.** (a) Bullish. (b) Raised fiscal-Q1 outlook, stock surged (D1 10-21; Stocktwits); AI-server demand resilient, which sits against the Barclays DELL/HPE/NTAP downgrade thesis. (c) Earnings **2026-11-03 (E)** AMC (Nasdaq calendar; absent from FMP; no company notice). (d) Queued 2026-05-29 (already queued). (e) 11-20, conviction **2**; gap thesis weaker after the move. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-03)

**20. ETN - Eaton. NEW.** (a) Bullish. (b) Data-centre electrical equipment and grid demand; Nasdaq consensus EPS $3.54 (10 estimates). Gap hypothesis (INFERRED, preliminary, no documents read this run): electrification backlog under-credited versus an AI-capex-fear discount. Documents for construction: Q2 10-Q backlog and orders, last four transcripts. (c) Earnings **2026-11-03 (E)** (Nasdaq calendar, pre-market not stated). (d) **NOT on the A queue; new intake.** (e) 11-20, conviction **2**. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-03)

### 21-30

- **21. MRVL - Marvell.** (a) Bullish. (b) Custom-silicon ramp; Investor Day (10-06) consumed; sank 8.7% on 10-14 in the CoreWeave sell-off (carried). (c) FQ3 **2026-12-01 (E)** (Nasdaq calendar; was undated). (d) Queued 2026-05-25 (already queued). (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-12-01)
- **22. DELL - Dell Technologies.** (a) Bullish. (b) AI-server capex; Barclays downgrade 10-14 (-11.27% that day), note not read; SMCI's raised outlook is a counter-datapoint. (c) **2026-11-24 (E)** (Nasdaq). (d) Queued 2026-05-17 (already queued). (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-24)
- **23. HPE - Hewlett Packard Enterprise.** (a) Bullish; as DELL. (c) **2026-12-03 (E)** (Nasdaq). (d) Queued 2026-05-29 (already queued). (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-12-03)
- **24. NTAP - NetApp.** (a) Bullish. Barclays downgrade 10-14 (-7.03%). (c) **2026-11-24 (E)** (Nasdaq; was 12-01). (d) Queued 2026-05-29 (already queued). (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-24)
- **25. DDOG - Datadog.** (a) Bullish. Bernstein upgrade on 10-19 (+5.36%, D1). (c) Earnings **2026-11-04 (C)** (company release carried; Nasdaq pre-market). (d) Queued 2026-05-07 (already queued). (e) conviction 3. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-04)
- **26. SHOP - Shopify.** (a) Bullish; GMV take-rate. (c) Earnings **2026-11-03 (E)** pre-market (Nasdaq). (d) Not on the A queue. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-03)
- **27. DIS - Disney.** (a) Bullish; SVOD margin expansion. (c) Earnings **2026-11-17 (E)** pre-market (Nasdaq, FMP). (d) Not on the A queue; two open Strategy D lots. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-17)
- **28. CRWD - CrowdStrike.** (a) Bullish; module attach; cybersecurity rallied 10-21 (D1). (c) **2026-12-01 (E)** (Nasdaq). (d) Queued 2026-05-31 (already queued). (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-12-01)
- **29. CRM - Salesforce.** (a) Bullish; agentic-AI attach against a compressed multiple. (c) **2026-12-02 (E)** (Nasdaq; was undated). (d) Queued 2026-05-17 (already queued). (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-12-02)
- **30. PANW - Palo Alto Networks.** (a) Bullish; platformisation. (c) FQ1 FY27 **2026-11-18 (E)** (Nasdaq; was 11-12 or 11-18 T). (d) Queued 2026-05-31 (already queued). (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-18)

### 31-40

- **31. OKTA - Okta.** (a) Bullish. (c) **2026-12-01 (E)** (Nasdaq). (d) Queued 2026-05-29 (already queued). (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-12-01)
- **32. NBIS - Nebius Group.** (a) Bullish; neocloud capacity. Adverse: CoreWeave credit stress is the closest comparable; OpenAI training pause (09-28). (c) **2026-11-10 (E)** (Nasdaq, time not supplied; was 11-11). (d) Queued 2026-05-13 (already queued). (e) conviction 1-2; rank held low. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-10)
- **33. MU - Micron.** (a) Bullish. (b) Old thesis consumed by the 09-30 print; new thesis is guidance durability. Adverse: CXMT server-DRAM push; SK Hynix -9.2% on 10-22 (tradingnews, secondary). (c) FQ1 **2026-12-23 (E)** (not in the FMP or Nasdaq pulls; inferred from the fiscal pattern). (d) Queued 2026-05-09 (already queued); the queue row cites the consumed 09-30 print and should be read as stale. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-12-23)
- **34. INTU - Intuit.** (a) Bullish. (c) **2026-11-19 (E)** (Nasdaq, time not supplied; was undated). (d) Queued 2026-08-03 (already queued). (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-19)
- **35. MRNA - Moderna.** (a) Bullish. NYT vaccine report (D1 10-09) carried as adverse. (c) **2026-11-06 (E)** pre-market (Nasdaq, FMP). (d) Not on the A queue. (e) conviction 1-2. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-06)
- **36. JPM - JPMorganChase.** (a) Bullish. 10-13 print missed (EPS 5.75 vs 5.93 est); 10Y fell to about 4.96% on 10-22 (D1), helping rate-sensitives. (c) Next print **2027-01-14 (E)** (FMP); Investor Day 2027-02-22 (C, carried). (d) Queued 2026-09-13 (already queued); the `spent_by_gate_likely` payload on the queue row is stale. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2027-01-14)
- **37. SNOW - Snowflake.** (a) Bullish; Cortex AI monetisation, $6B AWS commitment. Dilution evidence carried ($3.5B convertible, 09-28). (c) **2026-12-02 (E)** (Nasdaq). (d) Queued 2026-05-25 (already queued). (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-12-02)
- **38. V - Visa.** (a) Bullish. (c) Earnings 2026-10-27 (spent); DOJ fact-discovery close **2027-01-29 (E)**. Thin survivor: if W3/W4 judge that litigation milestone not a catalyst, V reverts to spent. (d) Not on the A queue. (e) conviction 1-2. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2027-01-29)
- **39. META - Meta Platforms.** (a) Bullish. (b) Reduced: printed 10-21 (revenue $64.60B +26%, Q4 revenue guide above consensus; capex floor $135B; first negative FCF; $9.89B legal charge; Class C shares from January 2027); stock about -7%. Gap hypothesis: the market punishes capex acceleration, so a thesis would need documents showing returns (ads/engagement) outrun the cash burn. (c) Next print **2027-01-27 (E)** (FMP). (d) Queued 2026-08-03 (already queued). (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2027-01-27)
- **40. GE - GE Aerospace.** (a) Bullish. Printed 10-20: EPS 2.25 vs 2.01, revenue $14.12B vs $12.88B (FMP). Gap hypothesis: aftermarket durability under-credited; fuel-shock exposure to aviation demand is the counter. (c) Next print **2027-01-21 (E)** (FMP). (d) Not on the A queue. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2027-01-21)

### 41-50

- **41. GOOGL - Alphabet.** (a) Bullish. (c) Earnings **2026-10-28 (C)** AMC (Nasdaq calendar, EPS forecast $2.94 from 14 estimates); Waymo multi-city launches "2026" undated, so surviving on fail-open. (d) Queued 2026-07-05 (already queued); two open Strategy D lots. (e) conviction 2. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst undated)
- **42. MRK - Merck.** (a) Bullish, held low on substance. Near-term PDUFAs gone (Welireg + Lenvima approved 09-25; I-DXd BLA withdrawn). (c) Earnings 10-29 (spent); Q4 call **2027-02-02 (C)** carried. (d) Queued 2026-09-13 (already queued); its `spent_by_gate_likely` payload is stale. (e) conviction 1. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2027-02-02)
- **43. TGT - Target.** (a) **DIRECTION UNRESOLVED**: the prior bearish thesis was refuted by a beat-and-raise and no replacement is established; ineligible for the top-10 until a direction is set. (c) Earnings **2026-11-18 (C)** (corporate.target.com, carried; Nasdaq pre-market). (d) Queued 2026-05-09 (already queued). (e) conviction 1. GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-18)
- **44. GEV - GE Vernova.** (a) Bullish. (c) Earnings **2026-10-28 (C)** pre-market (Nasdaq; the FOMC day). Gap thesis: electrification and grid-capex demand under-credited; GLJ Sell ($470, 09-14) carried. (d) Queued 2026-08-09 (already queued); **open Strategy D lot `D:GEV:2026-08-03`**. (e) conviction 2. GATE: SPENT-BY-GATE (gate 2026-11-02; catalyst 2026-10-28)
- **45. NOW - ServiceNow.** (a) Bullish. Gap thesis: agentic-platform attach under-credited; the WDAY take-private report is unverified and unweighted. (c) Earnings **2026-10-28 (C)** AMC. (d) Queued 2026-05-29 (already queued). (e) conviction 2. GATE: SPENT-BY-GATE (gate 2026-11-02; catalyst 2026-10-28)
- **46. XOM - ExxonMobil.** (a) Bullish. Gap thesis: the market prices a transient shock while physical flow data shows a structural one (Brent 113.17 on 10-22); the print precedes A's reopening. (c) Earnings **2026-10-30 (C)** pre-market. (d) Queued 2026-09-13 (already queued); contract identity flag in the census (conid 895178251). (e) conviction 2. GATE: SPENT-BY-GATE (gate 2026-11-02; catalyst 2026-10-30)
- **47. CVX - Chevron.** (a) Bullish. Gap thesis: same shock seam as XOM; one concentration decision with XOM and COP. (c) Earnings **2026-10-30 (C)** pre-market. (d) Queued 2026-09-13 (already queued). (e) conviction 2. GATE: SPENT-BY-GATE (gate 2026-11-02; catalyst 2026-10-30)
- **48. CAT - Caterpillar.** (a) Bullish. Gap thesis: data-centre power and dealer-consolidation demand under-credited; FTC/USDA farm-equipment RFI (10-07) is an overhang with no deadline. (c) Earnings **2026-10-29 (C)** pre-market. (d) Queued 2026-05-01 (already queued). (e) conviction 2. GATE: SPENT-BY-GATE (gate 2026-11-02; catalyst 2026-10-29)
- **49. LLY - Eli Lilly.** (a) Bullish. Gap thesis: obesity-franchise durability under-credited; defensive rotation is supportive but the print precedes A's reopening. A Strategy D router-gated NO-GO (2026-10-07) is context, not a barrier. (c) Earnings **2026-10-29 (C)** pre-market. (d) Queued 2026-05-01 (already queued). (e) conviction 2. GATE: SPENT-BY-GATE (gate 2026-11-02; catalyst 2026-10-29)
- **50. INTC - Intel.** (a) Bullish. Gap thesis: foundry-turnaround optionality under-credited; the print precedes the gate. (c) Earnings **2026-10-29 (C)** AMC (intc.com, carried). (d) Queued 2026-05-12 (already queued). (e) conviction 1-2. GATE: SPENT-BY-GATE (gate 2026-11-02; catalyst 2026-10-29)

### DIRECTION-INADMISSIBLE tier

These belong to Strategy B. The rail governs only admission to the actionable tier. None is in the top-10; none may be converted to an A `PENDING_ANALYSIS` row.

| # | Ticker | (a) Direction | (c) Catalyst | (d) Queue | (e) Thesis / note | Gate literal |
|---|---|---|---|---|---|---|
| I-1 | **UAL** | Bearish | Printed 10-20; next **2027-01-19 (E)** (FMP) | Not queued | Fuel-shock channel; Brent 113.17 | GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2027-01-19) |
| I-2 | **AAL** | Bearish | Printed 10-22; next **2027-01-26 (E)** (FMP) | Not queued | Thinnest balance sheet of the group | GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2027-01-26) |
| I-3 | **DAL** | Bearish | Printed 10-09; next **2027-01-12 (E)** (FMP) | Not queued | First airline to report | GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2027-01-12) |
| I-4 | **CCL** | Bearish | Earnings **2026-12-18 (E)** (FMP) | Not queued | Bunker-fuel channel | GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-12-18) |
| I-5 | **AMAT** | Bearish | Earnings **2026-11-12 (E)** AMC (Nasdaq) | On queue | China WFE cliff after the 10-13 Investor Day (-6.69%); LRCX's record quarter and July WFE raise is a contrary datapoint for D2 | GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-12) |
| I-6 | **WMT** | Bearish | Earnings **2026-11-19 (C)** pre-market | On queue | Low-income consumer; staples bid on 10-22 is a contrary datapoint | GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-19) |
| I-7 | **ADBE** | Bearish | Earnings **2026-12-09 (E)**; MAX 11-10..12 (E) | On queue | Vindicated on tape | GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-10) |
| I-8 | **HD** | Bearish / neutral | Earnings **2026-11-17 (E)** pre-market | On queue | Housing turnover starved; 10Y fell to about 4.96% on 10-22 is a contrary datapoint | GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-17) |
| I-9 | **AKAM** | Bearish / contested | Earnings **2026-11-05 (C)** AMC | On queue | Smallest cap in the file | GATE: GATE-SURVIVING (gate 2026-11-02; catalyst 2026-11-05) |

**W4 side, restated because it binds:** no candidate marked `DIRECTION-INADMISSIBLE` may be converted into an A `PENDING_ANALYSIS` row; a vacated slot is filled from the next admissible candidate. Five of the nine (AMAT, WMT, ADBE, HD, AKAM) are already on the A queue; D2 applies the rail to any thesis run on them.

### Handoff notes for W4

- **Top-10 versus the 44-row census (MEASURED against run_context):** eight are ALREADY QUEUED (TTWO, VRTX, FSLR, NVDA, AAPL, AVGO, AMD, CSCO). **Two are NEW to the queue: ANET (#5) and COP (#6).** Everything else carried outside the top-10 and NOT on the queue: LRCX, PLTR, UBER, CEG, ETN, SHOP, DIS, MRNA, V, GE (new intake only if W4's limb reaches past tier 1); plus the inadmissible UAL, AAL, DAL, CCL.
- **SPENT in the top-10: zero.** Rule: a SPENT name does not enter the top-10 while a surviving, admissible name of comparable conviction exists; weak-(E)-only survivors (MSFT, AMZN) sit at 11-12. Names ON or one session after the gate (AAPL, VRTX, PLTR, AMD, ANET) are surviving by the narrowest margin; an out-of-cycle refresh queued after this run would re-classify them next cycle.
- **Tier changes versus 2026-10-18:** MSFT #8 to #11, AMZN #9 to #12 (selection rule); ORCL #11 to #16; XOM #12 to #46, CVX #22 to #47, GEV #21 to #44, NOW #30 to #45, CAT #38 to #48, LLY #40 to #49, INTC #46 to #50 (all spent); NVDA #2 to #4 (lowered after the 10-22 reaction); ANET, COP in; LRCX, CEG, ETN new at 14, 18, 20. META and GE move from spent to surviving at #39 and #40. IBM dropped (still on the A queue). BAC, UNH and the DAL/CCL-style carries: BAC and UNH dropped from the ranked set (printed, no fresh evidence, not queued); their next prints are 2027-01-15 and 2027-01-20 (E) if W4 wants them back.
- **Stale queue-row payloads to overwrite:** JPM and MRK carry `spent_by_gate_likely` but are SURVIVING; MU's queue row cites the consumed 09-30 print (live catalyst 2026-12-23 (E)); the TTWO queue row's FQ2 date should read 11-09 (E); QCOM/NBIS/INTU/PANW/MRVL/CRM/NTAP/DELL/ORCL dates moved (STEP 3).
- **Cross-strategy overlap:** only Strategy D is open (AMZN x2, GEV, DIS x2, ISRG, RTX, GOOGL x2, TSM x2, UBER, per run_context); no A or C position, so no A/C conflict. A-candidate tickers with open D lots: AMZN (#12), GEV (#44), GOOGL (#41), DIS (#27), UBER (#17). C reads HYBRID ACTIVATE (FOMC-only), the only C row being the 10-28 FOMC.
- **NO-GO records are context, not barriers.** Carried: Strategy D router-gated NO-GOs of 2026-10-07 (LLY, V, VRTX, GE, MSFT, AVGO, others); none changes an A rank.
- **Re-check next cycle:** the 10-28/10-29 hyperscaler prints (MSFT, GOOGL, AMZN) as a read on the capex-restraint regime for NVDA/AVGO/AMD/ANET/CSCO; AAPL, VRTX, PLTR (zero-day margin); Take-Two's own fiscal-Q2 notice (11-09 is a calendar date only); QCOM's notice (11-04 is a calendar date only); LRCX's next print date; whether Brent's 113 holds into COP's 11-05 print.

### REPORT IT — CATALYST-GATE MODE

- **Gate date: 2026-11-02**, first cycle on the Rev 52 derivation. Inputs: (a) next scheduled re-score 2026-11-02 (completed this month: M1a 1, M1b 1); (b) no open `regime-refresh` item (no `item_key` / `due_date`); (c) REFRESH REQUEST query returned 0 rows, so no D2a run date is implied. A reads DO-NOT-ACTIVATE; mode live.
- **Counts:** 59 carried (50 ranked admissible incl. direction-unresolved TGT, + 9 DIRECTION-INADMISSIBLE); **7 SPENT-BY-GATE** (GEV, NOW, CAT, LLY, INTC, XOM, CVX), **52 GATE-SURVIVING**. Zero SPENT names in the top-10.
- **Classification rule applied:** SPENT iff the candidate's dated catalyst(s) all fall strictly before 11-02. A name with a spent print AND a later dated catalyst (MSFT Ignite 11-17 (E), AMZN re:Invent 11-30 (E), V) is SURVIVING on the later date, fail-open, and its row names the surviving catalyst in the literal; such names were kept out of the top-10 by the selection rule because the later catalyst is weak. A name whose print already happened before this run (META, GE, UAL, AAL) is keyed to its next dated print.
- **Narrowest survivors:** AAPL, VRTX, PLTR (catalyst ON 11-02); AMD, ANET, SHOP, SMCI, ETN (11-03). STEP 4: re-derive next cycle; a refresh queued after this run moves the gate earlier and can spend them.

---

## PART 2C — Strategy C ranked shortlist

### Router state, and what it admits

C reads **HYBRID ACTIVATE (FOMC-only)** (`state.current_regime` STRATEGY_ACTIVATION, 2026-10-06; per the run context). Under it **only an FOMC-type event is router-admissible**. Corporate-earnings and FDA PDUFA candidates stay **router-PARKED** and must not be enqueued; they are listed for the divergence record and for the day C is widened. A, B, D and E all read DO-NOT-ACTIVATE. `state.open_queue` for strategy C returns **zero rows** (MEASURED 2026-10-25): the 10-20 `thesis-FOMC-C-20261020` item has been serviced (D2 2026-10-20: NO-GO on criterion 2, per run context) and no C item is pending.

Two router-eligible events sit in the window: **FOMC 2026-10-28** (3 days out) and **FOMC 2026-12-09** (day 45; newly inside the window this cycle).

### The capital position (MEASURED 2026-10-25)

C is nomadic. MEASURED from BigQuery this run:

| Field | Value |
|---|---|
| `analytics.strategy_nav` C: deposits / NAV / available_funds | $19.48 / $19.48 / $19.48 |
| realized P&L, unrealized P&L, deployed_mv, dividends | $0 each |
| `sizing_base_2pct` | $0.39 |
| `state.nomadic_borrow_capacity_watch` C | donor_capacity_total 0, donor_count 0, `borrow_blocked` TRUE |
| `state.open_queue` strategy C | 0 rows |
| Open C positions | none (C has never opened a position; open positions are Strategy D only, per run context) |

Unchanged from the 10-18 and 10-11 readings. `ops.alerts` `71d484fa-0623-4443-89ed-a357ab305f67` (`nomadic_borrow_blocked`) is **still unresolved** (resolved = false). Already alerted; not re-raised.

**Per-thesis no-ceiling sizing discipline (Rev 43/19):** the budget has no numeric ceiling but max loss (including the cascade term) must not exceed the thesis's stated risk budget, and a long debit structure's max loss equals its debit. With a whole portfolio of $19.48, no budget above $19.48 is fundable, so the test is whether the cheapest defined-risk structure debits at or below $19.48. Credit spreads, iron condors and butterflies need collateral equal to width less credit and are likewise unfundable ($100 gross per 1-point SPY spread). **Every candidate below is a deferral at current NAV.**

### Criterion 1 (a qualifying event within 45 days)

- **FOMC 2026-10-28 (C)** and **FOMC 2026-12-09 (C)** — clear (federalreserve.gov, fetched this run). The 12-09 meeting clears only on the inclusive day-45 count from 10-25.
- **Earnings (router-PARKED):** dates per PART 1B.2. IR-confirmed for the shortlist names: MSFT, GOOGL (new), AMZN, LLY, XOM, PLTR (new), UBER (new), AMD, VRTX; secondary relay: AAPL; vendor-only: NVDA.
- **PDUFAs (router-PARKED):** INO 10-30 (C), SMMT 11-14 (C), VRTX povetacicept 11-30 (C); see 1B.3.

### The tenor rail — CLEAR, sixth cycle running

C requires structure expiration within 1-45 days of entry. MEASURED from the live SPY option parameters (IBKR underlying 756733, class SPY): listed expiries are 10-26, 10-27, 10-28, **10-29**, **10-30**, 11-02, 11-03, 11-04, 11-05, 11-06, 11-09, 11-13, 11-20 (regular and 2SPY), 11-27 (SPY and 2SPY), 11-30, **12-04 (new; SPY and 2SPY)**, 12-18 (regular), 12-31, then monthlies into 2027. New vs 10-18: a full Mon-Fri weekly set now runs 10-26 → 11-06, plus 11-03/11-04/11-05/11-09 and 12-04.

- **FOMC 10-28:** the 10-28 expiry is the event day (statement 2 pm ET) and is excluded as not strictly after the event. First expiry strictly after: **10-29** (3 days from a 10-26 entry), then 10-30 (4 days). Criterion 5 (entry at least one trading day before the event) is met by an entry on Monday 10-26 or Tuesday 10-27; 10-27 is the last permitted entry day. Pricing below uses 10-30, the expiry quoted this run.
- **FOMC 12-09:** no weekly expiry yet lists for 12-09 → 12-11 (weeklies list out to 12-04). First listed expiry after the event today is **12-18** (regular); from a 12-07/12-08 entry that is 10-11 days (last permitted entry day 12-08), inside 1-45. Weekly expiries 12-09 → 12-11 will list later and shorten the tenor.

### Criterion 2 (implied vs realized) — MEASURED on the spec window (trailing 30 days)

Headline is IV/HV30 per `strategy/05_strategy_c.md`; HV10 and HV20 are context. Realized vol = annualized close-to-close, log returns, sample stdev × √252, from **IBKR regular-session daily bars** (`outside_rth` false), last close **Friday 2026-10-23**. HV30 = 30 returns over 31 closes (2026-09-11 → 2026-10-23); HV20 = 21 closes (09-25 → 10-23); HV10 = 11 closes (10-09 → 10-23). Option quotes: IBKR, last trades 2026-10-23 ~20:14 UTC (16:14 ET); the market is closed so bid/ask is the Friday close book. Spots below are the 10-23 regular-session closes (the SPY snapshot "last" of 761.11 at 23:59:58 UTC is after hours and not used).

**D2 2026-10-20 already ran the FOMC 10-28 thesis → NO-GO on criterion 2 (run context). Reused, not redone. Did anything change? Yes on the measure, no on the verdict's direction:** SPY 10-30 ATM IV (valid this time) is 16.36% against HV30 10.37%, ratio **1.58**, higher than the 1.44 (derived) / 1.42 (underlying) that fed the 10-18 baseline. Implied is still rich to realized and the premium widened again. NAV is unchanged at $19.48. Nothing here reopens a GO path.

SPY, expiry 2026-10-30, strike 760 (spot 759.97, 10-23 close):

| Field | Value |
|---|---|
| 760 call | 7.47 / 7.52, last 7.51, OI 3,934 |
| 760 put | 6.29 / 6.36, last 6.29, OI 75,291 |
| ATM straddle | mid **13.82 → $1,382 per contract**; 1.82% of spot (10-18 baseline: 2.29%, different T) |
| `implied_vol` on the contracts | **16.358%, `is_valid` TRUE** (it was invalid on 10-18, so no derived figure is needed this cycle) |
| `implied_vol_underlying` (SPY, 30-day constant maturity) | 15.091%, valid |
| IBKR `historical_vol` (broker 30d, method undisclosed; context) | 10.995% |

| Window | Closes (returns) | Range | Realized vol | IV/HV (contract 16.358%) | IV/HV (underlying 15.091%) |
|---|---|---|---|---|---|
| **HV30 (spec)** | 31 (30) | 09-11 → 10-23 | **10.37%** | **1.578** | 1.455 |
| HV20 | 21 (20) | 09-25 → 10-23 | 9.77% | 1.674 | 1.545 |
| HV10 | 11 (10) | 10-09 → 10-23 | 10.81% | 1.513 | 1.396 |

Realized term structure: HV20 9.77 < HV30 10.37 < HV10 10.81 (roughly flat). SPY closed 759.97 on 10-23 (-0.43% over five sessions; 10-16 was 763.25).

Caveats. (1) The 10-30 expiry's IV includes the FOMC jump plus two post-event days, so part of the "rich" reading is event premium, not a pure volatility risk premium; the 30-day underlying IV (1.455 on HV30) is the cleaner context. (2) HV is close-to-close on regular-session closes and excludes overnight gap vol. (3) Quotes are frozen Friday values; a live in-session read is required before any trade. (4) The 10-29 expiry was not quoted this run.

**Cheapest defined-risk SPY structure, MEASURED (10-30 expiry, 1-wide, Friday close book):**

| Structure | Legs (bid/ask) | Debit at natural | Debit at mid | vs C NAV $19.48 |
|---|---|---|---|---|
| Call debit spread 760/761 | buy 760C ask 7.52, sell 761C bid 6.87 (761C 6.87/6.94) | 0.65 → **$65.00** | 0.59 → $59.00 | 3.3x NAV; shortfall $45.52 |
| Put debit spread 760/759 | buy 760P ask 6.36, sell 759P bid 5.89 (759P 5.89/5.97) | 0.47 → **$47.00** | 0.395 → $39.50 | 2.4x NAV; shortfall $27.52 |
| ATM long straddle | 760C + 760P | **$1,388.00** at the ask (7.52 + 6.36 = 13.88) | $1,382.00 | ~71x NAV |

No measured SPY structure is executable at C's NAV. Implied-rich favors premium-selling, which needs collateral C does not have; the buy-side structures are unaffordable. (Far-wing single options were not priced.)

**Panel — ATM straddle on the first expiry spanning each event** (IBKR Friday 10-23 close book; contract `implied_vol` valid on all; implied move = straddle mid / spot; realized-equivalent = 0.8 × HV30 × √(T/365), T calendar days from 10-23; by construction ratio = IV/HV30). All router-PARKED; pricing measurement only, not a divergence finding.

| Name | Event (tag) | Expiry (T) | Spot | Strike | Straddle mid ($/contract) | Contract IV | HV30 / HV20 / HV10 | IV/HV30 | Implied move vs realized-equiv. | Quote quality |
|---|---|---|---|---|---|---|---|---|---|---|
| SPY | FOMC 10-28 (C) | 10-30 (7) | 759.97 | 760 | 13.82 ($1,382) | 16.36% | 10.4 / 9.8 / 10.8 | **1.58** | 1.82% vs 1.15% | tight |
| MSFT | earnings 10-28 AMC (C) | 10-30 (7) | 524.51 | 525 | 27.675 ($2,768) | 47.46% | 22.1 / 19.7 / 20.9 | **2.15** | 5.28% vs 2.45% | moderate (put 13.50/14.30) |
| GOOGL | earnings 10-28 AMC (C) | 10-30 (7) | 320.21 | 320 | 19.375 ($1,938) | 54.68% | 24.6 / 21.1 / 22.3 | **2.22** | 6.05% vs 2.72% | tight |
| AMZN | earnings 10-29 AMC (C) | 10-30 (7) | 248.00 | 247.5 | 19.45 ($1,945) | 71.04% | 29.9 / 32.7 / 37.9 | **2.37** | 7.84% vs 3.31% | tight |
| LLY | earnings 10-29 pre (C) | 10-30 (7) | 1,273.46 | 1272.5 | 82.375 ($8,238) | 59.04% | 27.2 / 30.8 / 37.4 | **2.17** | 6.47% vs 3.01% | wide (call 39.05/45.40, put 36.05/44.25) |
| XOM | earnings 10-30 pre (C) | 10-30 (7) | 183.21 | 182.5 | 7.20 ($720) | 34.99% | 23.7 / 18.2 / 21.5 | 1.48 | 3.93% vs 2.62% | wide on put (3.00/3.40) |
| AAPL | earnings 11-02 AMC (C-secondary) | 11-04 (12) | 347.73 | 347.5 | 15.775 ($1,578) | 31.13% | 15.1 / 16.5 / 12.3 | **2.07** | 4.54% vs 2.19% | moderate (7.85/8.45, 7.25/8.00) |
| AMD | earnings 11-03 AMC (C) | 11-04 (12) | 516.79 | 517.5 | 51.70 ($5,170) | 69.25% | 58.6 / 52.0 / 63.9 | 1.18 | 10.00% vs 8.50% | **wide** (call 23.15/28.25, put 24.40/27.60) |
| NVDA | earnings 11-18 (E) | 11-20 (28) | 210.96 | 210 | 20.50 ($2,050) | 43.80% | 28.9 / 29.6 / 33.6 | 1.51 | 9.72% vs 6.41% | tight; 28-day expiry also holds ~4 weeks of non-event time |

Reads. Implied is rich to HV30 across the panel, richest on AMZN, GOOGL, LLY, MSFT and AAPL (2.1-2.4x) and leanest on AMD (1.18; AMD's own HV30 is already 58.6%, and its spreads are too wide to trust). The mega-cap ratios are inflated relative to ordinary quarters by calm HV30 windows (AAPL 15%, MSFT 22%). GOOGL closed -5.98% over five sessions (320.21) and XOM +2.36% (183.21, ahead of its print). These ratios are INFERRED as "richness"; none says the options market is wrong about direction.

### Ranked shortlist — 15 event candidates

Changes vs last cycle's 15: **struck as printed:** META, TSLA, NFLX (10-20 → 10-21). **Added:** the second FOMC meeting (12-09, newly in window), GOOGL (now IR-confirmed), PLTR, UBER, VRTX (povetacicept PDUFA 11-30, C), SMMT (PDUFA 11-14, upgraded to C). **Dropped to make room (still in PART 1B):** CVX, GEV, MRK, CYTK (date unverified); CVX and GEV were correlated or FOMC-confounded duplicates and MRK carries no PDUFA. **Moved:** AMZN to the top-5 (IV/HV30 2.37, richest on the panel; C-confirmed 10-29), GOOGL and MSFT promoted by market cap, IR confirmation and ratio; XOM, AMD, AAPL, LLY to the rest. Direction in every row is the divergence between the options market and a no-event realized baseline; W1 does not establish a directional view.

**TOP-5**

**1. FOMC 2026-10-28 (C)** — (a) No affirmative directional divergence established by W1. The measurable divergence is volatility: IV/HV30 **1.58** (contract) / 1.46 (underlying), implied rich and widened from 1.44; this favors selling premium, which C cannot fund. (b) federalreserve.gov calendar (fetched this run); secondary market context only: a Sept-16 rate increase to 3.75-4.00% and ~83% hold / ~17% hike odds for 10-28 as of 10-20 (CME FedWatch via search snippets, not first-hand); the baseline's hot Sept CPI/PPI context is carried from last cycle. (c) **2026-10-28 (C).** (d) **Not executable: DEFERRAL.** NAV $19.48 vs cheapest SPY 1-wide debit spread $47 (put) / $65 (call); borrow capacity zero. (e) No open A positions. (f) **Top-5, rank 1.** **Disposition:** D2 already returned NO-GO on criterion 2 on 10-20 and no C queue item is pending; W4 should not create a duplicate for 10-28. Re-measurement raised the ratio and changed no input to the NO-GO.

**2. FOMC 2026-12-09 (C, SEP meeting)** — (a) No directional divergence established; the SEP/dot-plot meeting is the one where the hike risk is concentrated per the secondary sources above (INFERRED, not first-hand). (b) federalreserve.gov calendar; the SEP is a primary document that appears on the day. (c) **2026-12-09 (C), day 45 of the window.** (d) **NOT executable at current capital: DEFERRAL.** Same SPY structure arithmetic (no 12-09/12-11 weekly listed yet; 12-18 is the first listed expiry after the event, whose debit spread cost has not been measured and would be larger than a 4-day one). (e) None. (f) **Top-5.** Router-eligible, but it sits at the inclusive edge of the 45-day window: **a thesis for it is meaningful only if built before the event and while it is still inside the 45 days; no D2 item exists for it.** The orchestrator decides whether W4 enqueues it; the pending-thesis rule "one FOMC row per meeting" applies.

**3. AMZN — earnings 2026-10-29 after close (C)** — (a) Implied rich: 7.84% implied move vs 3.31% realized-equivalent (IV/HV30 **2.37**, the richest measured); HV10 37.9 vs HV30 29.9 shows realized already accelerating. (b) Amazon IR (carried); 10-Q/10-K and AWS/capex disclosures not read this run. (c) 2026-10-29; first post-event expiry 10-30. (d) **Not executable: DEFERRAL** (ATM straddle $1,945; the cheapest single ATM option leg costs about $935-$1,020). (e) AMZN is an open **Strategy D** position (x2) — D, not A or C; A-queue member; no open A. (f) Top-5. **Router-PARKED.**

**4. GOOGL — earnings 2026-10-28 after close (C, NEW)** — (a) Implied rich: 6.05% vs 2.72% (IV/HV30 **2.22**); stock -5.98% on the week (320.21) into the print, closing at the low of the 45-day bar window. (b) Alphabet IR release 2026-10-06 (date); capex and AI-monetization disclosures in the last 10-Q not read this run. (c) 2026-10-28 AMC; **same day as FOMC, confounded** (the release follows the 2 pm statement). (d) **Not executable: DEFERRAL** (straddle $1,938). (e) GOOGL is an open **Strategy D** position (x2); A-queue member. (f) Top-5. **Router-PARKED.**

**5. MSFT — earnings 2026-10-28 after close (C)** — (a) Implied rich: 5.28% vs 2.45% (IV/HV30 **2.15**); stock 524.51 (-0.86% on the week; +8.5% over the 45-day window). (b) Microsoft IR release 2026-10-07 (carried). (c) 2026-10-28 AMC; **same day as FOMC, confounded.** (d) **Not executable: DEFERRAL** (straddle $2,768). (e) A-queue member; no open A. (f) Top-5. **Router-PARKED.**

**REST (6-15)** — all **router-PARKED**; all deferrals at C NAV $19.48.

| # | Candidate | (a) Direction of divergence | (c) Date (tag) | (d) Executability at C $19.48 | (e) A overlap | Notes |
|---|---|---|---|---|---|---|
| 6 | **LLY** earnings | Implied rich: 6.47% vs 3.01% (IV/HV30 2.17), wide quotes; HV10 37.4 vs HV30 27.2 | 2026-10-29 pre-market (C) | Deferral (straddle $8,238; stock $1,273) | A queue (LLY); no open A | no PDUFA in window |
| 7 | **AAPL** earnings | Implied rich: 4.54% vs 2.19% (IV/HV30 2.07); calmest HV30 on the panel (15.1%) | 2026-11-02 AMC (C-secondary) | Deferral (straddle $1,578) | A queue (AAPL) | date via secondary relay only |
| 8 | **NVDA** earnings | Implied 9.72% vs 6.41% (1.51), 28-day expiry | 2026-11-18 (E) | Deferral (straddle $2,050) | A queue (NVDA) | date unconfirmed by NVIDIA; confirm when the notice posts |
| 9 | **XOM** earnings | Implied 3.93% vs 2.62% (1.48); stock +2.36% on the week to 183.21 | 2026-10-30 pre-market (C) | Deferral (straddle $720; put 3.00/3.40) | A queue (XOM) | |
| 10 | **AMD** earnings | Leanest ratio, 1.18 (HV30 58.6%); implied 10.0% vs 8.5% | 2026-11-03 AMC (C) | Deferral (straddle $5,170; spreads ~$5 wide) | A queue (AMD) | quotes too wide to trust |
| 11 | **PLTR** earnings (NEW) | Not measured (no chain pulled) | 2026-11-02 AMC (C, NEW) | Deferral (not measured; stock far above NAV scale) | none confirmed (not on the 44-name A census) | |
| 12 | **UBER** earnings (NEW) | Not measured | 2026-11-04 pre-market (C, NEW) | Deferral (not measured) | none for A; **open D position (x1)** | |
| 13 | **VRTX** PDUFA povetacicept / IgAN | Binary regulatory outcome (accelerated approval) | 2026-11-30 (C) | Deferral (not measured; large cap) | A queue (VRTX); no open A | earnings 11-02 (C) also in window |
| 14 | **SMMT** PDUFA ivonescimab BLA | Binary; company states FDA wants an OS benefit | 2026-11-14 (C) | Deferral (chain not measured) | none | |
| 15 | **INO** PDUFA INO-3107 | Binary; accelerated-approval eligibility is the flagged risk | 2026-10-30 (C) | Deferral — stock ~$1, penny-wide chain; a single long call cost $10-$30 on 10-16 | none | last chain read 10-16, not refreshed |

**(e) A-vs-C exclusivity is vacuous this cycle.** `state.current_positions` holds Strategy D only (AMZN x2, GEV, DIS x2, ISRG, RTX, GOOGL x2, TSM x2, UBER); zero open A or C rows. A-queue membership marked above is from the run context's 44-name census.

**Price half of Friday 2026-10-23 (IBKR regular-session bars).** SPY 759.97, MSFT 524.51, GOOGL 320.21, AMZN 248.00, AAPL 347.73, XOM 183.21, AMD 516.79, NVDA 210.96, LLY 1,273.46.

**Shortlists only.** Full thesis construction per Strategy.md happens in sessions W4 schedules. Nothing here authorizes an enqueue for any parked name.

---

## Coverage, provenance and what this cycle changed

**Read scope.** Weekly cadence. MEASURED or INFERRED is labelled wherever it matters.
- **BigQuery (read-only):** `state.trading_day_today`, `state.current_regime`, `state.current_positions`, `state.open_queue`, `state.open_queue_detail`, `state.market_calendar`, `state.routine_catchup_window`, `analytics.strategy_nav`, `state.nomadic_borrow_capacity_watch`, `events.decision_log`, `events.queue_events`, `ops.run_log`, `ops.alerts`.
- **Repo:** `strategy/03_strategy_a.md`, `strategy/05_strategy_c.md`, `strategy/01_shared_regime_vocabulary.md`, the Claude_Task_Plan.md W1 section and shared rules, and the prior `Weekly_Catalyst_Calendar.md` (2026-W42).
- **Live sources:** FMP `calendar/earnings-calendar` (4 chunked calls, orchestrator only); the Nasdaq key-less earnings calendar (34 per-day fetches, orchestrator only, unmetered); IBKR daily bars, option parameters and snapshots (free); Anthropic `web_search` / `web_fetch` (federalreserve.gov, issuer IR pages, FDA/sponsor releases); Tavily basic search (6 credits).

**Orchestration.** Three Sonnet sub-agents did the grunt work: (1) PART 1A non-earnings catalysts and the earnings tail, (2) the PART 2A synthesis, (3) PART 1B and PART 2C including the Strategy C measurements. The orchestrator did itself: both shared pulls (FMP and Nasdaq), passed to the sub-agents as provided data that they did not re-fetch; every BigQuery state read; the STEP 1 gate derivation and the census; the 1A.1/1A.2 earnings tables; and assembly and validation, including every GATE literal checked for format and SPENT/SURVIVING consistency against the gate. **Two sub-agent outputs were corrected on review:** (i) the PART 2A draft carried last week's retired "true gate may be 12-01" exposure forward; it was removed, since Rev 52 retired the quiet-clock leg it rested on; (ii) a sub-agent downgraded VRTX's povetacicept PDUFA 2026-11-30 from (C) to (E) for want of a sponsor date — the orchestrator found Vertex's own 2026-06-01 BLA-acceptance release stating 2026-11-30 and restored (C).

**Catch-up window.** `state.routine_catchup_window` gives `window_days` **6.99** against a weekly 1.5× threshold of 10.5: cadence-normal, no `CATCHUP` token owed.

**The daily-to-weekly boundary, honoured.** Catalysts newly announced 10-18..10-22 were reused from D1's `research-screen` records, not re-searched: the MSTR MSCI non-operating-company rule (10-18); the IRON/CLF/MANE/DDOG/ARQT own-event set (10-19); BRZE deal, LION bid report and the 10-20 earnings set; the SPCX/SMCI/WFRD/LAD/MHO/T/NFLX/ROIV/FLY/ASST set (10-21); and the 10-22 AI-hardware rout after META/TSLA/LRCX with defensives bid. D2's 2026-10-20 Strategy C FOMC 10-28 NO-GO (criterion 2) was reused, not redone. No second broad news scan was run; web effort went to forward-calendar acquisition, date confirmation and per-candidate documents.

**The FRIDAY-SESSION GAP, closed from IBKR.** D1 has not yet covered Friday 2026-10-23 (structural, by trigger ordering, not a D1 outage). The price half was closed at zero cost from IBKR regular-session bars for the PART 2A priority names and the PART 2C panel (closes quoted in their rows). The narrative half is not chased.

**Standing constraints NOT re-alerted:** the FMP earnings-horizon plan cap (`FMP-earn-horizon`); the FMP 90-day span clamp (chunking applied, all chunks ≤ 60 days); the bulk-enumeration plan gate (`6c4004e3`); C's blocked nomadic borrow (`71d484fa`, still OPEN); the Friday boundary gap (`b4e4e563`).

**Open W1 referrals re-checked.** `99ccd487` (`w1_catalyst_gate_omits_m1r_path`, STEP 1 silent on the M1R path) is still OPEN in `ops.alerts`. On this cycle's reading the Rev 52 STEP 1 now names the M1R route explicitly — input (b) (an open `regime-refresh` item) and input (c) (a refresh D2a is due to queue) — so the gap it describes appears closed by that revision; W5's SPEC-DEFECT NOTICE INTAKE owns the close and it is not re-filed. `fc7b0e63` (quiet-clock qualification) was resolved 2026-10-19 and its subject was then retired by Rev 52.

**Known residual gaps (carried in the rows):** issuer notices not yet found for TTWO 11-09, QCOM 11-04, NVDA 11-18, CSCO 11-11, PLTR 11-02, CEG 11-06, ETN 11-03 (all (E)); the first-party (b) documents for the five new A names (ANET, COP, LRCX, CEG, ETN) are INFERRED and preliminary, for thesis construction to confirm; most PDUFA rows beyond GSK, INO, MLYS, COGT, SMMT and VRTX still rest on one aggregator; META Q3 EPS differs by source (FMP 7.40 adjusted vs a GAAP-shaped 3.83 secondary) and is not reconciled here; the investor-day and product-event sweeps are samples, not enumerations.

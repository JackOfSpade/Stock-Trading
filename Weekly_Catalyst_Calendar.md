2026-W39

# Weekly Catalyst Calendar — Strategies A and C

**Run date 2026-09-27** (Sunday, `weekly_sun`). ISO week of TODAY's run date per `state.trading_day_today.today` — the same week W2/W3 stamp this cycle. The upcoming trading week opens Monday 2026-09-28; that is context, not the marker.

**Windows.** Strategy A: 6 months, **2026-09-27 → 2027-03-27**. Strategy C: 45 days, **2026-09-27 → 2026-11-11**.

**EFFECTIVE CONFIRMED-EARNINGS HORIZON: 2026-12-10 — 74 days, ~10.6 weeks.** The 6-month figure above is the *analytical* window; bulk earnings-date coverage reaches only to 2026-12-10. This is the standing plan-tier constraint (`ops/connector_tools.yaml`, FMP `calendar`; open owner decision `FMP-earn-horizon` in `OWNER_ACTIONS.md`) and is deliberately NOT re-alerted. **But the horizon is MOVING, and that belongs here:** four consecutive weekly probes give 2026-12-03/88d (09-06), 2026-12-09/87d (09-13), 2026-12-09/80d (09-20), **2026-12-10/74d (09-27)**. The terminal date advanced ONE day while the run date advanced seven, so effective depth has lost 14 days in three weeks. This surface is behaving less like a rolling ~13-week window than like a slowly-creeping terminal date, and it is now materially SHORTER than the ~13 weeks the plan documents. The last ~15 weeks of the A window (2026-12-11 → 2027-03-27) carry no bulk coverage at all.

**Every count in PART 1 is a FLOOR.** Universe enumeration is impossible on this plan tier — `search/search-company-screener`, every `directory.*` route and `quote/batch-quote` are each separately tool-level ACCESS DENIED — so PART 1A is built over the 79 reachable vendor calendar rows plus the 44-row live A queue, not over "all US-listed equities ≥ $2B cap and ≥ $10M ADV". Not re-alerted (`ops.alerts` `6c4004e3`, standing).

---

## PART 1A — Strategy A universe, 6-month window (2026-09-27 → 2027-03-27)

No interpretation in this PART. Provenance tags: **(C)** company- or primary-source confirmed · **(E)** estimated (vendor/aggregator projection) · **(T)** tentative / no firm day.

### 1A.1 — Earnings, inside the 45-day C window (2026-09-27 → 2026-11-11)

All rows (E) from the shared FMP `calendar/earnings-calendar` pull unless marked otherwise. A-eligibility notes applied from the measured rails in 1A.8.

| Ticker | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| CCL | Carnival | Earnings | 2026-09-29 | (E) | FMP bulk |
| NKE | Nike | Earnings | 2026-10-01 | (E) | FMP bulk |
| MU | Micron | Earnings (FQ1) | 2026-09-30 | (E) | wallstreethorizon — **NEWLY ESTABLISHED this cycle**; aggregator tags it "confirmed" but the Micron release was not read, so it is (E) not (C) |
| PEP | PepsiCo | Earnings | 2026-10-08 | (E) | FMP bulk |
| TLRY | Tilray | Earnings | 2026-10-08 | (E) | FMP bulk — A-INELIGIBLE, cap floor |
| DAL | Delta | Earnings | 2026-10-09 | (E) | FMP bulk |
| C | Citigroup | Earnings | 2026-10-13 | (E) | FMP bulk |
| GS | Goldman Sachs | Earnings | 2026-10-13 | (E) | FMP bulk |
| JNJ | Johnson & Johnson | Earnings | 2026-10-13 | (E) | FMP bulk |
| JPM | JPMorgan | Earnings | 2026-10-13 | (E) | FMP bulk |
| UNH | UnitedHealth | Earnings | 2026-10-13 | (E) | FMP bulk |
| WFC | Wells Fargo | Earnings | 2026-10-13 | (E) | FMP bulk |
| BAC | Bank of America | Earnings | 2026-10-14 | (E) | FMP bulk |
| TSM | Taiwan Semiconductor | Earnings | 2026-10-15 | (E) | FMP bulk — A-INELIGIBLE, ADR (`isAdr` true, MEASURED) |
| GE | GE Aerospace | Earnings | 2026-10-20 | (E) | FMP bulk |
| GM | General Motors | Earnings | 2026-10-20 | (E) | FMP bulk |
| KO | Coca-Cola | Earnings | 2026-10-20 | (E) | FMP bulk |
| LMT | Lockheed Martin | Earnings | 2026-10-20 | (E) | FMP bulk |
| NFLX | Netflix | Earnings | 2026-10-20 | (E) | FMP bulk |
| VZ | Verizon | Earnings | 2026-10-20 | (E) | FMP bulk |
| T | AT&T | Earnings | 2026-10-21 | (E) | FMP bulk |
| UAL | United Airlines | Earnings | 2026-10-21 | (E) | FMP bulk |
| AAL | American Airlines | Earnings | 2026-10-22 | (E) | FMP bulk |
| F | Ford | Earnings | 2026-10-22 | (E) | FMP bulk |
| INTC | Intel | Earnings | 2026-10-22 | (E) | FMP bulk |
| NOK | Nokia | Earnings | 2026-10-22 | (E) | FMP bulk — A-INELIGIBLE, ADR (MEASURED) |
| HCA | HCA Healthcare | Earnings | 2026-10-23 | (E) | FMP bulk |
| CARR | Carrier Global | Earnings | 2026-10-27 | (E) | FMP bulk |
| PYPL | PayPal | Earnings | 2026-10-27 | (E) | FMP bulk |
| SOFI | SoFi | Earnings | 2026-10-27 | (E) | FMP bulk |
| V | Visa | Earnings | 2026-10-27 | (E) | FMP bulk |
| BA | Boeing | Earnings | 2026-10-28 | (E) | FMP bulk |
| GEV | GE Vernova | Earnings (Q3) | 2026-10-28 | (E) | aggregator synthesis — **NEWLY ESTABLISHED**; was date-unestablished for two cycles |
| GOOGL | Alphabet | Earnings | 2026-10-28 | (E) | FMP bulk |
| META | Meta Platforms | Earnings | 2026-10-28 | (E) | FMP bulk |
| MSFT | Microsoft | Earnings | 2026-10-28 | (E) | FMP bulk |
| SBUX | Starbucks | Earnings | 2026-10-28 | (E) | FMP bulk |
| TSLA | Tesla | Earnings | 2026-10-28 | (E) | FMP bulk |
| ~~FDX~~ | ~~FedEx~~ | ~~Earnings~~ | ~~2026-10-28~~ | (T) | **REJECTED AS SUSPECT, third cycle running** — see 1A.9 |
| AAPL | Apple | Earnings | 2026-10-29 | (E) | FMP bulk |
| AMZN | Amazon | Earnings | 2026-10-29 | (E) | FMP bulk |
| COIN | Coinbase | Earnings | 2026-10-29 | (E) | FMP bulk |
| FSLR | First Solar | Earnings (Q3) | 2026-10-29 | (E) | aggregator synthesis — **NEWLY ESTABLISHED** |
| MRK | Merck | Earnings (Q3) | 2026-10-29 | (E) | aggregator synthesis — **NEWLY ESTABLISHED** |
| RBLX | Roblox | Earnings | 2026-10-29 | (E) | FMP bulk |
| RIOT | Riot Platforms | Earnings | 2026-10-29 | (E) | FMP bulk |
| RKT | Rocket Companies | Earnings | 2026-10-29 | (E) | FMP bulk |
| ABBV | AbbVie | Earnings | 2026-10-30 | (E) | FMP bulk |
| CVX | Chevron | Earnings | 2026-10-30 | (E) | FMP bulk |
| XOM | Exxon Mobil | Earnings | 2026-10-30 | (E) | FMP bulk |
| FUBO | fuboTV | Earnings | 2026-11-02 | (E) | FMP bulk — A-INELIGIBLE, cap floor |
| PLTR | Palantir | Earnings | 2026-11-02 | (E) | FMP bulk |
| AMD | AMD | Earnings | 2026-11-03 | (E) | FMP bulk |
| PFE | Pfizer | Earnings | 2026-11-03 | (E) | FMP bulk |
| PINS | Pinterest | Earnings | 2026-11-03 | (E) | FMP bulk |
| RIVN | Rivian | Earnings | 2026-11-03 | (E) | FMP bulk |
| SHOP | Shopify | Earnings | 2026-11-03 | (E) | FMP bulk |
| SIRI | Sirius XM | Earnings | 2026-11-03 | (E) | FMP bulk |
| UBER | Uber | Earnings | 2026-11-03 | (E) | FMP bulk |
| CAT | Caterpillar | Earnings (Q3) | 2026-11-04 | (E) | aggregator synthesis — **NEWLY ESTABLISHED**; was undated for two cycles |
| ET | Energy Transfer | Earnings | 2026-11-04 | (E) | FMP bulk |
| ETSY | Etsy | Earnings | 2026-11-04 | (E) | FMP bulk |
| HOOD | Robinhood | Earnings | 2026-11-04 | (E) | FMP bulk |
| LCID | Lucid | Earnings | 2026-11-04 | (E) | FMP bulk — A-INELIGIBLE, cap floor |
| MGM | MGM Resorts | Earnings | 2026-11-04 | (E) | FMP bulk |
| ROKU | Roku | Earnings | 2026-11-04 | (E) | FMP bulk |
| SNAP | Snap | Earnings | 2026-11-04 | (E) | FMP bulk |
| MRNA | Moderna | Earnings | 2026-11-05 | (E) | FMP bulk |
| TTWO | Take-Two | Earnings (FQ2) | 2026-11-05 | (E) | aggregator synthesis — **NEWLY ESTABLISHED** |
| SONY | Sony Group | Earnings | 2026-11-10 | (E) | FMP bulk — A-INELIGIBLE, ADR (MEASURED) |
| CSCO | Cisco | Earnings | 2026-11-11 | (E) | FMP bulk |

### 1A.2 — Earnings, 2026-11-12 → horizon 2026-12-10

| Ticker | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| BILI | Bilibili | Earnings | 2026-11-12 | (E) | FMP bulk — A-INELIGIBLE, ADR (MEASURED) |
| DIS | Disney | Earnings | 2026-11-12 | (E) | FMP bulk |
| BIDU | Baidu | Earnings | 2026-11-17 | (E) | FMP bulk — A-INELIGIBLE, ADR (MEASURED) |
| NVDA | NVIDIA | Earnings | 2026-11-18 | (E) | FMP bulk |
| TGT | Target | Earnings | 2026-11-18 | (E) | FMP bulk |
| WMT | Walmart | Earnings | 2026-11-19 | (E) | FMP bulk |
| ZM | Zoom | Earnings | 2026-11-23 | (E) | FMP bulk |
| BABA | Alibaba | Earnings | 2026-11-24 | (E) | FMP bulk — A-INELIGIBLE, ADR (MEASURED) |
| NIO | NIO | Earnings | 2026-11-24 | (E) | FMP bulk — A-INELIGIBLE, ADR (MEASURED) |
| DOCU | DocuSign | Earnings | 2026-12-03 | (E) | FMP bulk |
| ADBE | Adobe | Earnings | 2026-12-09 | (E) | FMP bulk |
| COST | Costco | Earnings | 2026-12-10 | (E) | FMP bulk |
| AVGO | Broadcom | Earnings (FQ4) | 2026-12-10 | (E) | aggregator synthesis — **NEWLY ESTABLISHED**; was undated |

### 1A.3 — Earnings, 2026-12-11 → 2027-03-27

**Structurally empty of bulk coverage.** The only vendor rows in this range are FDX 2027-02-02 and FDX 2027-03-25, and the first of those is rejected as suspect (1A.9). Of the FedEx pair only **2027-03-25 (E)** is retained, as the sole row consistent with FedEx's actual fiscal calendar. Sixteen A-queue names carry no establishable forward earnings date at all this cycle — see 1A.10. This is a coverage gap, not an absence of events, and it surfaces downstream as a RANKING distortion rather than as missing rows.

### 1A.4 — Product launches, keynotes, developer events

| Ticker | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| NVDA | NVIDIA | GTC Berlin | 2026-10-20 → 10-22 | (E) | carried |
| ORCL | Oracle | CloudWorld | 2026-10-25 → 10-28 | (C) | carried |
| ADBE | Adobe | Adobe MAX | 2026-11-10 → 11-12 | (E) | carried |
| TTWO | Take-Two | **GTA VI launch** | 2026-11-19 | (C) | carried, confirmed twice over; preload 11-12 |
| MSFT | Microsoft | Ignite | 2026-11-17 → 11-20 | (C) | carried |
| AMZN | Amazon | re:Invent | 2026-11-30 → 12-04 | (C) | carried |
| NVDA | NVIDIA | GTC Washington DC | 2026-11-30 → 12-03 | (E) | carried |
| GOOGL | Alphabet | Waymo multi-city robotaxi launches | 2026 (year only) | (T) | carried |
| — | broad | CES 2027 | 2027-01-06 → 01-09 | (E) | carried |
| NVDA | NVIDIA | GTC 2027 San Jose | 2027-03-15 → 03-18 | (C) | carried |
| FSLY | Fastly | AI Firewall / AI Runtime Control launch | 2026-09-21 | (C) | **PAST — recorded for the divergence record only.** D1/D2 `a0a163af`; +14.9204% close-to-close 09-18→09-21, routed to Strategy B |

Dropped as PAST this cycle: **META Meta Connect** (2026-09-23 → 09-24).

### 1A.5 — Analyst and investor days

| Ticker | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| BGC | BGC Group | FMX Investor Day | 2026-10-13 | (C) | carried |
| WDAY | Workday | Financial Analyst Day | 2026-10-13 | (C) | carried |
| NKE | Nike | Investor day, "Fall 2026" | — | (T) | carried, single weak source, no day |
| UNH | UnitedHealth | Investor conference | ~2026-12 early | (E) | carried, projected from annual cadence |
| JPM | JPMorgan | Investor Day | 2027-02-22 | (C) | carried |

### 1A.6 — Regulatory, legal, trade and macro

| Ticker | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| GOOGL | Alphabet | DOJ search-remedies reply brief | 2026-09-29 | (C) | carried |
| BMY | Bristol Myers Squibb | Camzyos PDUFA (adolescent oHCM) | 2026-09-30 | (2S) | carried |
| SRRK | Scholar Rock | Apitegromab PDUFA (SMA) | 2026-09-30 | (C) | carried |
| — | broad | US government funding deadline (CR to 12-11) | 2026-09-30 | (E) | carried |
| GOOGL | Alphabet | DOJ ad-tech Final Judgment due | 2026-10-02 | (C) | carried |
| MRK | Merck | Welireg + Lenvima PDUFA (RCC) | 2026-10-04 | (C) | carried |
| RHHBY | Roche | **Tecentriq + chemo PDUFA** (stage III dMMR/MSI-H colon) | 2026-10-09 | (C) | **DUAL-SOURCED this cycle** — roche.com release + BioSpace. ADR |
| MRK | Merck | Ifinatamab deruxtecan PDUFA (ES-SCLC) | 2026-10-10 | (E) | carried, single-sourced this cycle |
| V | Visa | DOJ fact discovery closes | 2026-10-16 | (C) | carried |
| VTRS | Viatris | MR-141 PDUFA (presbyopia) | 2026-10-17 | (E) | carried, single-sourced this cycle |
| PHAR | Pharming | Joenja PDUFA | 2026-10-24 | (2S) | carried |
| GSK | GSK | **Bepirovirsen PDUFA** (chronic hep B) | 2026-10-26 | (C) | **MULTI-SOURCED and the drug now IDENTIFIED** — GSK's own release + Ionis IR. ADR |
| AAPL | Apple | EU DMA App Store deadline, "by Oct 2026" | — | (T) | carried as a commitment, no day |
| — | broad | **FOMC decision** | **2026-10-28** | (C) | **RE-CONFIRMED by direct fetch of federalreserve.gov** (Oct 27–28 meeting) |
| INO | Inovio | **INO-3107 BLA PDUFA** (recurrent respiratory papillomatosis) | 2026-10-30 | (C) | **MULTI-SOURCED** — Inovio's own release + PRNewswire |
| — | broad | USTR Sec 301 exclusions expire | 2026-11-10 | (C) | carried |
| Beren | Beren Therapeutics | Adrabetadex PDUFA | 2026-11-17 | (2S) | carried |
| UNP·NSC | Union Pacific / Norfolk Southern | STB comments due | 2026-11-18 | (C) | carried |
| CAPR | Capricor | Deramiocel PDUFA | 2026-11-22 | (C) | carried, 8-K/EDGAR re-confirmed |
| SVRA | Savara | Molbreevi PDUFA | 2026-11-22 | (2S) | carried |
| VRTX | Vertex | Povetacicept PDUFA | 2026-11-30 | (C) | carried |
| UNP·NSC | Union Pacific / Norfolk Southern | DOJ/USDOT preliminary comments | 2026-12-03 | (C) | carried |
| FSLR | First Solar + solar | **Sec 232 tariff regime effective** | 2026-12-04 | (C) | carried, whitehouse.gov |
| VRTX | Vertex | Journavx sNDA PDUFA | 2026-12-05 | (2S) | carried |
| — | broad | **FOMC decision** | **2026-12-09** | (C) | direct federalreserve.gov fetch (Dec 8–9 meeting) |
| BA | Boeing | FAA 737 MAX 10 certification, "by year-end 2026" | — | (T) | carried |
| PRAX | Praxis | Relutrigine PDUFA | 2026-12-27 | (2S) | carried |
| DYN | Dyne | Z-rostudirsen PDUFA | 2027-01-21 | (C) | carried |
| — | broad | **FOMC decision** | **2027-01-27** | (C) | **direct federalreserve.gov fetch** (Jan 26–27 meeting). An aggregator claimed Jan 28–29; the direct source governs — see 1A.9 |
| UNP·NSC | Union Pacific / Norfolk Southern | STB responses due | 2027-02-16 | (C) | carried |
| BMRN | BioMarin | VOXZOGO full approval | 2027-02-28 | (C) | carried |
| SRPT | Sarepta | AMONDYS 45 / VYONDYS 53 sNDAs | 2027-02-28 | (C) | carried; cap ~$2.14B, on the floor — re-measure before use |
| LYV | Live Nation | DOJ/states remedies phase | ~2027-02 | (E) | carried |
| WBD | Warner Bros Discovery (acquirer PSKY) | Antitrust trial begins | 2027-03-02 | (C) | carried |

Beyond window, named so it is not re-discovered: FTC v. Amazon trial ~2027-03-29 (E).

Macro context carried forward: the **2026-09-16 FOMC hiked 25bp to 3.75–4.00%**, unanimous, the first hike since 2023, with 16 of 18 dots for at least one further 2026 hike. Both remaining 2026 meetings are therefore live dated catalysts, not formalities.

### 1A.7 — Restructuring and structural

| Ticker | Name | Type | Date | Tag | Source |
|---|---|---|---|---|---|
| MGM | MGM Resorts | **People Incorporated WITHDREW its take-private proposal** | 2026-09-23 | (C) | **PAST, and newly recorded.** PR Newswire 2026-09-23 18:05 ET + MGM's own board release. −2.6992% on the 09-23 anchor session, −10.9908% gap at the 09-24 open (37.85→33.69). D1 `6e179f3c`; D2 corrected it twice to the operative row `4fc1abc0`, which finds MGM DOES qualify for Strategy B on the corrected 09-23 anchor |
| SWKS·QRVO | Skyworks / Qorvo | $22B merger, cleared all but 2 jurisdictions | undated | (C) | carried |
| KMB·KVUE | Kimberly-Clark / Kenvue | Merger close, outside date auto-extending | 2026-11-02 → 2027-05-03 | (T) | carried |
| TECK | Teck Resources | Anglo American–Teck, China MOFCOM last pending | spans window | (C) | carried |
| CTVA | Corteva | "Vylor" spin-off | Q4 2026 | (T) | carried |
| — | broad | Nasdaq-100 annual reconstitution | mid-2026-12 | (E) | carried |
| — | broad | S&P 500 Q4 rebalance | 2026-12-18 | (E) | carried |
| DG | Dollar General | CEO transition | 2027-01-01 | (C) | carried |
| BA | Boeing | SVP Finance → Controller succession, upon 10-K filing | — | (C) | carried |
| — | broad | S&P 500 Q1 2027 rebalance | 2027-03-19 | (E) | carried |

Narrative-only, no row: UBER restructuring (~3,300 roles) whose margin effect lands in the 2026-11-03 print.

### 1A.8 — Universe rails, MEASURED

**Market-cap rail (≥ $2B at entry) — THE CAP-UNVERIFIED GAP IS CLOSED THIS CYCLE.** For 28 consecutive cycles' worth of queue-only names the cap was carried as CAP-UNVERIFIED because `company/batch-market-cap` silently dropped them. This run found the working route — `company/profile-symbol` reaches every symbol the batch endpoint denies — and measured all 27 outstanding names individually:

All 27 **PASS** the $2B floor, by wide margins. Smallest: **AKAM $16.565B** (≈8.3× the floor). Largest: **MU $1,222.316B**. Every one returned `isActivelyTrading: true` with a non-null cap. Measured: AKAM 16.565 · AMAT 385.070 · CAT 378.450 · CRM 191.662 · CRWD 256.734 · DDOG 95.444 · DELL 373.907 · FSLR 19.098 · GEV 255.049 · HD 292.355 · HPE 83.345 · IBM 212.461 · INTU 75.439 · LLY 1,114.758 · MRVL 229.394 · MU 1,222.316 · NBIS 56.959 · NOW 140.212 · NTAP 39.471 · OKTA 32.425 · ORCL 394.855 · PANW 305.413 · QCOM 212.069 · SMCI 27.984 · SNOW 116.437 · TTWO 37.665 · VRTX 133.550 (all $B). AVGO measured separately at 1,678.522.

The 20 allow-listed calendar names re-measured cleanly at 20/20 with zero drops: AAPL 5,009.417 · NVDA 5,451.420 · GOOGL 4,162.158 · MSFT 3,832.846 · AMZN 2,685.725 · META 1,914.844 · TSLA 1,469.666 · AMD 1,028.305 · JPM 919.233 · WMT 859.313 · V 685.916 · XOM 665.434 · INTC 620.412 · CVX 407.163 · BAC 402.377 · KO 377.807 · UNH 341.998 · GE 339.376 · DIS 184.339 · PEP 175.709 ($B).

**FAIL the cap floor, A-ineligible:** TLRY, LCID, FUBO (carried from the prior cycle's measurement; all three are far below $2B and none is a candidate).

**ADR rail — now MECHANICAL, not inferred.** Strategy A admits "US-listed common equity" (`strategy/03_strategy_a.md`:17); a depositary receipt is not common equity, which is the basis for the exclusion. That basis has been an *inference* for seven names for several cycles. FMP's `isAdr` field settles it: **`isAdr` returned TRUE for 7 of 7** — TSM, NOK, SONY, BILI, BIDU, BABA, NIO. The inherited exclusion is **CONFIRMED, not contradicted**, for every one. All seven separately clear the $2B cap floor (smallest BILI $6.248B), so the cap rail is not what excludes them — the instrument rail is, and it now rests on a measurement.

**Liquidity rail (30-day ADV ≥ $10M):** see 1A.11.

### 1A.9 — Rows struck, rejected or corrected this cycle

1. **~~ZEAL rusfertide PDUFA 2026-09-30~~ — STRUCK, and it is wrong in BOTH of the two documented ways at once.** A single aggregator (`biopharmawatch.com`) returned this as a forward PDUFA. (i) **Misattribution:** rusfertide (PTG-300) is **Protagonist Therapeutics'** (PTGX), partnered with Takeda — not Zealand Pharma's (ZEAL). (ii) **Already decided:** this project's own 2026-09-06 W1 cycle recorded rusfertide **APPROVED 2026-08-28**. One single-sourced, visibly-unreliable row, wrong on company and on date. Not promoted. This is the **fourth consecutive cycle** in which an aggregator has re-listed an already-decided PDUFA and the **third** in which one has misattributed a drug to the wrong company (previously: apitegromab → PFE/ROIV when it is SRRK's; zidesamtinib → GSK when it is NUVL's).
2. **~~RHHBY PDUFA 2026-10-15~~ — WITHDRAWN as uncorroborated.** Carried by the prior two cycles. A dedicated search this cycle could not corroborate it from any source and affirmatively ruled out giredestrant as the candidate drug (its PDUFA dates are 2026-11-30 and Dec 2026, not October). Since no Roche October-15 drug can be identified, the row is withdrawn rather than re-carried blind. Note this is the *second* Roche row this cycle and the other one (Tecentriq 10-09) was strengthened to dual-sourced, so this is a specific failure, not a source-wide one.
3. **~~FDX 2026-10-28~~ and ~~FDX 2027-02-02~~ — REJECTED AS SUSPECT.** FedEx's fiscal year ends 31 May, so its quarters end Aug / Nov / Feb / May and it reports in ~Sep / Dec / Mar / Jun. Neither 2026-10-28 nor 2027-02-02 matches any FedEx quarter-end. Only **2027-03-25** fits (the Feb quarter), and it alone is retained. Third cycle running for the 10-28 row; the 02-02 row is newly visible this cycle because the window advanced. FedEx's own IR page was not reached — the web budget was exhausted first — so this stays a reasoned rejection on fiscal-calendar arithmetic, not a source-confirmed one.
4. **INO = Inovio Pharmaceuticals, NOT Inotiv.** The 2026-10-30 INO-3107 PDUFA belongs to Inovio (ticker INO). Inotiv trades as NOTV. Confirmed against Inovio's own release. Flagged because the two are a live confusion risk in downstream tagging.
5. **FOMC 2027 dates — direct source beats aggregator.** federalreserve.gov, fetched directly, gives the January 2027 meeting as **Jan 26–27** (decision 2027-01-27). A secondary aggregator asserted Jan 28–29. The direct fetch governs; the aggregator claim is recorded as refuted, not carried as an alternative.
6. **ORCL — a prior-cycle move figure was corrected upstream and W1 carries the corrected one.** D1's 09-14 single-name screen measured −13.7912% **open-to-open**; the true close-to-close figure is **−3.6532%**, below Strategy B's 5% floor (D1 `4264b87f`, superseding `46d69e8d`; independently reproduced by D2 `64a9628f` to four decimals). The prior W1 artifact cited the −13.7912% figure in ORCL's PART 2A entry. It is corrected here.
7. **MSTR dropped.** D2 `75b5a4f6`: correcting the anchor session moves MSTR from clearing Strategy B criterion 1 by 3.3× to failing it by 19bp, and its event window had already closed. Not carried.
8. **EQUITY_BREADTH_PCT 2026-09-17 — use 50.29, not 51.09.** The stored 09-17 value (51.09) was an unsettled intraday snapshot (page timestamped 14:58 ET, pre-close); the settled figure is 50.29 (`0162cb25`). The prior W1 artifact quoted 51.09. Corrected here. Per append-only rules the original row was not rewritten upstream, so the true figure lives only in the later row's rationale.
9. **A D1 prose figure for Brent is off by one session — noted, not repaired (D1's own).** D1's 2026-09-23 sector screen (`e01d9ca6`) records Brent as having "settled 98.60" that day. The authoritative warehouse series (`state.signal_marks_curated`, BZUSD) has **98.53 on 09-22 and 103.08 on 09-23** — so the prose quotes the prior session's settle as the current one. Nothing propagates into this artifact, which reads the warehouse directly, but the discrepancy materially changed how this run first read the Libya event (see PART 2A's gate derivation) and is worth D1 knowing.

### 1A.10 — Names with NO establishable forward earnings date

Sixteen live A-queue names could not be dated this cycle. Ten were chased explicitly and returned "TBD" from every aggregator reached (LLY, QCOM, AMAT, INTU, ORCL, PANW, NOW, VRTX, AKAM, IBM); CRM was chased individually and only already-past quarters surfaced; five more (CRWD, DDOG, DELL, HPE, MRVL, NBIS, NTAP, OKTA, SMCI, SNOW) were below the web budget's reach.

Per CATALYST-GATE MODE these are **GATE-SURVIVING on the fail-open reading** and receive full depth: a name cannot be proven spent without a date. That is deliberate and it is the expensive direction. VRTX is the one name in this group with genuinely dated *non-earnings* catalysts (PDUFAs 2026-11-30 and 2026-12-05, both post-gate), so its survival is substantive rather than merely fail-open.

### 1A.11 — Liquidity rail (30-day ADV ≥ $10M), MEASURED

Measured off **IBKR regular-session daily bars** per `Operating_Protocols.md` §19 PRICE BASIS — `get_price_history(step='ONE_DAY', outside_rth=false)`, never `get_price_snapshot`. ADV computed as the mean of (close × volume) over the last 30 trading bars, 2026-08-14 → 2026-09-25.

**70 names measured (the 44-row A queue plus 26 forward-calendar candidates). 70 PASS, 0 FAIL, 0 UNMEASURED.** Every name used a full 30 bars.

**Lowest measured: NTAP at $197.05M — about 20× the $10M floor.** The ten lowest, so the margin is visible rather than asserted: NTAP 197.0 · UAL 221.8 · FSLR 236.3 · VRTX 240.3 · AKAM 241.9 · DAL 249.4 · GM 264.5 · LMT 274.8 · TTWO 279.4 · HCA 282.5 ($M). Top of range: MU 16,306.7 · NVDA 14,640.9 · TSLA 10,259.0 · META 8,588.5 · AAPL 7,689.5.

**Bar-currency check:** every one of the 70 series ends at **2026-09-25**, the last trading day, confirmed from each response's own timestamp array rather than assumed. No stale series.

**Cross-contamination check run deliberately, and it came back clean.** The known defect — `get_price_history` returning another symbol's series under the requested label, with no error, at concurrency ≥ 5 (`ops.alerts` `7cc25b71`, raised by W1 last cycle after GOOGL came back carrying AMZN's data byte-for-byte) — was guarded against by holding concurrency at 3 throughout, and all 70 ADV values plus all 70 closes were scanned for exact or near-identical pairs. **None found.** Stating the negative because last cycle's positive was caught only by a coincidence of three-decimal equality, and a check that is only reported when it fails is not a check.

**A second, independent liquidity cross-check, free and worth having.** FMP's `profile-symbol` returns `averageVolume`, so avgVolume × price gives a dollar-volume proxy on a different vendor's data for the 34 names swept in 1A.8. It agrees with the IBKR measurement in every case on the binary PASS verdict, with the smallest proxy value being **BILI at $45.5M** (an ADR, A-ineligible anyway) and the smallest A-eligible proxy **AKAM at $493.5M**. The two sources differ in level — different windows and different volume definitions — so this is a corroboration of the *verdict*, not of the *value*; the IBKR figure is the one of record per §19.

**The rail is not close to binding and has not been for many cycles.** Recorded because "all pass by 20×" is itself the finding: the ADV floor is not a live constraint on this universe, and the measurement's value is in catching a data defect (as it did last cycle), not in screening names out.

---

## PART 1B — Strategy C universe, 45-day window (2026-09-27 → 2026-11-11)

C's qualifying event types are exhaustive and are only three (`strategy/05_strategy_c.md`:25-31): corporate earnings (US-listed, **confirmed date from company IR**), FDA PDUFA (FDA calendar or company disclosure), FOMC (confirmed Fed calendar). Line 31 excludes everything else *at the strategy level* — analyst days, product launches, conference presentations, M&A, legal rulings, index rebalances. So most of PART 1A is structurally outside C's universe regardless of routing.

No interpretation in this PART.

### 1B.1 — FOMC

| Event | Meeting | Decision date | In window | Tag | Source |
|---|---|---|---|---|---|
| FOMC | 2026-10-27 → 10-28 | **2026-10-28** | **YES** | (C) | **federalreserve.gov, fetched directly this run** (not carried, not an aggregator) |
| FOMC | 2026-12-08 → 12-09 | 2026-12-09 | No — 28 days past the 11-11 edge | (C) | federalreserve.gov, direct |
| FOMC | 2027-01-26 → 01-27 | 2027-01-27 | No | (C) | federalreserve.gov, direct |

**The 2026-10-28 FOMC is the ONE router-eligible event in this window.** See PART 2C.

### 1B.2 — Earnings inside the window

The dated set is identical to 1A.1 and is not duplicated here. **One hard limit applies to every row of it and is not a presentation quibble:** C's entry criterion 1 requires an earnings date **confirmed from company IR**, and every earnings date in this artifact is tagged **(E)** — a vendor or aggregator projection. Not one earnings date in the 45-day window is company-IR confirmed. So every earnings-based C candidate fails criterion 1 on *provenance* before any volatility measurement is even reached, independently of the router. This has now been true for three consecutive cycles and is a structural property of the data surfaces available, not of any particular week's crop.

### 1B.3 — FDA PDUFA dates in window

A floor, measured twice over (a carried set plus an independent pass this cycle). Two rows left the table and none entered — see 1A.9 for both strikes.

| Date | Ticker | Drug / indication | Tag | C-eligible | Note |
|---|---|---|---|---|---|
| 2026-09-28 | BFRI | Ameluz PDT / sBCC | (E) | nominally | micro-cap; a defined-risk options chain is unlikely to be usable |
| 2026-09-30 | SRRK | Apitegromab / SMA | (C) | yes | carried, corroborated |
| 2026-09-30 | BMY | Camzyos / adolescent oHCM | (2S) | yes | carried |
| 2026-10-04 | MRK | Welireg + Lenvima / RCC | (C) | yes | carried |
| 2026-10-09 | RHHBY | Tecentriq + chemo / stage III dMMR-MSI-H colon | (C) | **NO — ADR** | **UPGRADED to dual-sourced this cycle**: roche.com release + BioSpace |
| 2026-10-10 | MRK | Ifinatamab deruxtecan / ES-SCLC | (E) | yes | carried; single-sourced this cycle, not independently re-verified |
| 2026-10-17 | VTRS | MR-141 / presbyopia | (E) | yes | carried; single-sourced this cycle |
| 2026-10-24 | PHAR | Joenja | (2S) | yes | carried |
| 2026-10-26 | GSK | Bepirovirsen / chronic hep B | (C) | **NO — ADR** | **UPGRADED to multi-sourced AND the drug identified**: GSK's own release + Ionis IR. Depemokimab and linerixibat were affirmatively ruled out as candidates for this date |
| 2026-10-30 | INO | INO-3107 (BLA) / recurrent respiratory papillomatosis | (C) | yes | **multi-sourced**: Inovio's own release + PRNewswire. INO = **Inovio**, not Inotiv (NOTV) |

**STRUCK this cycle:** ~~RHHBY 2026-10-15~~ (uncorroborated, withdrawn) and ~~ZEAL rusfertide 2026-09-30~~ (misattributed AND already approved 2026-08-28). Both at 1A.9.
**Now PAST, dropped:** MIRM zilurgisertib 2026-09-26.

**The PDUFA table is a FLOOR and is provably incomplete.** An independent pass spending five calls closed **zero** genuinely new in-window rows while *removing* two and *strengthening* three. A pass that subtracts more than it adds is still worth running — it is how a carried table stops drifting — but it is direct evidence that this surface is not enumerable from the sources reachable here.

---
## PART 2A — Strategy A ranked shortlist

W4 reads this PART verbatim and enqueues thesis-construction entries for the ranked shortlist; D2 runs them. Rankings and date specifics are therefore explicit.

### The A-queue census — the PINNED query, run verbatim

```sql
SELECT * FROM state.open_queue WHERE strategy = 'A'
```

**returns 44 rows.** Enumerated and reconciled ticker-by-ticker to that count: AAPL, ADBE, AKAM, AMAT, AMD, AMZN, AVGO, CAT, CRM, CRWD, CSCO, CVX, DDOG, DELL, FSLR, GEV, GOOGL, HD, HPE, IBM, INTC, INTU, JPM, LLY, META, MRK, MRVL, MSFT, MU, NBIS, NOW, NTAP, NVDA, OKTA, ORCL, PANW, QCOM, SMCI, SNOW, TGT, TTWO, VRTX, WMT, XOM.

`Watchlist.md` carries **45**. The one-name gap is **TSM**, an ADR deliberately left queued in the file (so the reasoning survives) and correctly absent from the live queue — the same recurring, closed gap, re-verified rather than carried. The ADR basis for it is now MEASURED, not inferred (1A.8). Discrepancy stated; **the query wins.** One further field-level difference, documented and already reconciled upstream: `Watchlist.md` shows META's date-added as 2026-07-05 where the live key is `A:META:2026-08-03`; that is a stale column in the file, not a membership difference.

### STEP 1 — the GATE DATE, re-derived from scratch, with the arithmetic shown

**DERIVED GATE DATE = 2026-11-02.** Third consecutive cycle at this date — but reached through arithmetic that moved on **both** legs this week, in opposite directions, and one of the moves was nearly decisive.

**PRICE leg** (MEASURED, `state.rerisking_limb_status`, `as_of_denver` 2026-09-27): `shock_overlay_state` **acute** since 2026-08-01 · `brent_baseline` **84.73** over 43 observations (2026-06-01..07-31) · `brent_peak` **108.75** · `brent_current` **106.60** as of 2026-09-24 · `brent_retrace_trigger` **96.74** — reproduced exactly as the midpoint (84.73 + 108.75)/2 = 193.48/2 = 96.74 · `leg_b_basis` **not_retraced** · `leg_b_price_leg` **FALSE** · `sql_limbs_fired` **FALSE**.

Required fall: (96.74 − 106.60) / 106.60 = **−9.25%**. Last cycle it was −7.71% from 104.82. **The required fall WIDENED by 1.54pp** — the peak did not ratchet (108.75 both cycles, so the trigger is unchanged at 96.74); Brent simply climbed back toward it.

**And the week's most important single fact, which is invisible if you read only the current value.** The authoritative series (`state.signal_marks_curated`, ticker `BZUSD`) ran: 09-15 **108.75** (the peak) → 09-16 105.83 → 09-17 104.82 → 09-18 103.87 → 09-21 100.34 → **09-22 98.53** → 09-23 **103.08** → 09-24 **106.60**. On 2026-09-22 Brent sat **1.85% above the 96.74 trigger** — by far the closest the price leg has come to firing in the entire acute run, after five consecutive sessions of clean decline and an Iranian offer to reopen Hormuz within seven days. Then it reversed **+4.62% on 09-23 and a further +3.42% on 09-24**, back out to −9.25%. **The price leg came within 1.85% of clearing and was pushed back out to 9.25% in two sessions.**

**QUIET-CLOCK leg — 15 trading days clear of the most recent qualifying shock-cluster member. This cycle that anchor MOVED, and adjudicating it was the judgment call of the run.**

Candidates in the window:
- **2026-09-15** (`db7dc01c`) — drone strikes on Saudi Arabia's East-West pipeline, the Hormuz bypass, forcing a shutdown; ~4% of global supply at risk. XLE +2.1695%, Brent +2.9050% to 108.75, USO +3.3198%. This is the event that **set the peak**, and it was the prior two cycles' anchor.
- **2026-09-22** (`21309492`) — Iran publicly offered to reopen the Strait of Hormuz within seven days; Saudi Arabia began testing the bypass pipe. **De-escalation, not a cluster member.**
- **2026-09-23** (`e01d9ca6` operative, superseding `372a84fa`; also `3b1fa412`) — an armed-group blockade of Libya's El Sharara field, roughly a third of Libyan output, compounded by a White-House-backed proposal to **ban US diesel exports**. XLE the sole GICS-sector gainer that session at +0.9550%.

**VERDICT: 2026-09-23 is a qualifying shock-cluster member and is the most recent one. The anchor moves from 09-15 to 09-23.**

The reasoning, and it nearly went the other way. On D1's own prose this looked like a non-event: XLE managed only +0.9550%, D1 files it as one contributing factor inside a broader *rates* shock (five-year-high flash PMI, hawkish governor comment, weak 5Y auction, 10Y to 5.11%), no entry names it as a cluster member, and D1's 09-23 screen states Brent "settled 98.60" — i.e. **down** on the day. A first pass read it as not qualifying, largely on that price reading. **That price reading is wrong.** The warehouse has 98.53 on 09-22 and 103.08 on 09-23, so D1's prose quotes the *prior* session's settle as the current one (1A.9 item 9). Brent actually rose **+4.62% on 09-23 and +8.19% across 09-23/09-24** — a two-session crude move **larger than the 09-15 anchor event's own +2.9050% one-day print.**

So on the measure this leg actually keys on — crude — the Libya event registers harder than the event currently anchoring the clock. It is energy-infrastructure disruption at real scale plus a policy action, the same class as the members already in the cluster. It did not set a new peak (106.60 < 108.75), but *setting a new peak was the prior cycle's rationale for choosing 09-15, not the qualifying test*, and nothing in the mode requires a member to be the largest one. And the fail-open direction points the same way: a later anchor means a later gate, which means **more** candidates survive and receive full depth, which is the direction ambiguity is required to resolve toward. 09-24's continuation is the same event's follow-through, not a separate member.

15th trading day strictly after 2026-09-23 = **2026-10-14**:
09-24(1) 09-25(2) 09-28(3) 09-29(4) 09-30(5) 10-01(6) 10-02(7) 10-05(8) 10-06(9) 10-07(10) 10-08(11) 10-09(12) 10-12(13) 10-13(14) **10-14(15)**.
(Counted off `state.market_calendar`, independently twice, by the orchestrator and by a separate measurement pass. On the superseded 09-15 anchor the same count gives 2026-10-06.)

Scheduled M1a/M1b re-scores are `monthly_ftd`: **2026-10-01, 2026-11-02** (11-01 is a Sunday), 2026-12-01, 2027-01-04.

- **2026-10-01 is UNREACHABLE.** The quiet clock does not clear until 2026-10-14 (and did not clear until 10-06 even on the superseded anchor), *and* the price leg is not retraced with −9.25% still required. Both legs hold acute through it.
- **2026-11-02 is NOT provably unreachable.** The price leg can clear at any time — it came within 1.85% this very week — so it is not excluded. It is therefore the gate.

**THE ROBUSTNESS POINT, stated because the cycle's central number must not rest on a contested judgment.** The gate is **2026-11-02 under either anchor**: 2026-10-06 and 2026-10-14 both fall well before it. The Libya adjudication does not move the gate date at all. It matters for the *next* cycle's arithmetic, and for the question of whether any early-October re-score could ever have been reachable — not for this one's classifications. Both readings were worked through rather than one assumed, and the conclusion is the same either way.

**FAIL-OPEN status: not triggered.** `state.rerisking_limb_status` read cleanly, both legs were derivable, and A's `STRATEGY_ACTIVATION` reads **DO-NOT-ACTIVATE** (`div-A-202608-1`, `as_of_date` 2026-09-03, theater-check MIXED), so the mode is live rather than inert. Full (a)–(e) was therefore NOT forced onto every candidate.

### STEP 2 — the DIRECTION rail, run FIRST

Strategy A is **long-only** — `strategy/03_strategy_a.md`:20, "Long-only (no short positions in A — short is B's territory)", without qualification. A candidate whose hypothesized mispricing is that the name is **over**-valued cannot produce an A entry at any conviction. This is a category error, not a judgment call. The rail ran before ranking.

**Nine names are `DIRECTION-INADMISSIBLE (A long-only rail)` and one is direction-unresolved.** All are ranked and carried below the actionable tier, not discarded — they are genuine evidence for the divergence record and for Strategy B's sub-pattern taxonomy, which is where short-direction theses belong. None is in the top-10.

**And for the third consecutive cycle the rail costs the strongest new thesis in the file.** The Libya blockade came bundled with a White-House-backed proposal to **ban US diesel exports** — a distillate/jet-fuel story landing directly on airline hedge books set before the shock, with DAL (10-09), UAL (10-21) and AAL (10-22) all reporting in window. The 09-15 pipeline strike already made this the best idea in the file twice; the diesel-export proposal strengthens it a third time, because it attacks the crack spread rather than only the crude price. It remains categorically inadmissible for A at any conviction. Routed to B — where B's own router also reads DO-NOT-ACTIVATE, so the idea is carried and acted on nowhere. That is the honest state of it.

### STEP 3 — counts

**48 ranked candidates + 9 DIRECTION-INADMISSIBLE = 57 carried.** Against the 2026-11-02 gate: **34 GATE-SURVIVING, 23 SPENT-BY-GATE.** That is a materially heavier spent share than last cycle's 43/14, and the reason is *not* that the gate moved — it did not. It is that **eight previously-undated names acquired dates this week**, and five of those dates fall before the gate. Establishing a date is the only thing that can convert a fail-open survivor into a spent name, so a cycle that successfully dates names will mechanically show more spent ones. That is the mode working, not degrading.

### TOP-10 — the actionable tier

All long. All rail-checked: every one clears the $2B cap floor on a figure MEASURED this cycle (1A.8) and the ADV floor (1A.11). **8 of 10 GATE-SURVIVING, 2 SPENT-BY-GATE** — the two are kept in tier because their conviction genuinely rose again this week, and the marks travel with the rows.

**1. TTWO — Take-Two Interactive.** (a) **Bullish** — under-valued. (b) GTA VI is the largest entertainment launch ever attempted and the market has repeatedly discounted Rockstar's ability to hold a date; the last two W1 cycles each re-confirmed the date against both Rockstar and TTWO IR and it survived both. Supporting: TTWO's last two 10-Qs on deferred-revenue mechanics and the preload schedule. (c) **GTA VI launch 2026-11-19 (C)**, preload 11-12; FQ2 earnings **2026-11-05 (E, newly established)**. (d) On the A queue since 2026-08-09; no open position in any strategy. (e) **Top-10.** GATE-SURVIVING — both catalysts post-gate, the launch by 17 days. *Promoted from #5.* This is now the best-dated, highest-magnitude single-company catalyst in the file and the only top-10 name whose principal catalyst is a confirmed (C) date rather than a vendor estimate.

**2. NVDA — NVIDIA.** (a) Bullish. (b) Memory/AI re-rating read-through; FQ2 10-Q, last four transcripts, GTC materials. Live objection carried and unresolved: the circular-financing critique (2026-07-27). (c) Earnings **2026-11-18 (E)**; GTC Washington DC 11-30→12-03 (E). (d) Queued 2026-05-09; no open position. (e) Top-10. GATE-SURVIVING, both catalysts well post-gate.

**3. VRTX — Vertex Pharmaceuticals.** (a) Bullish. (b) BLA/sNDA submission announcements plus the most recent 10-Q pipeline disclosure; two independent regulatory decisions in a five-week band. (c) **Povetacicept PDUFA 2026-11-30 (C)**; Journavx sNDA PDUFA 2026-12-05 (2S). (d) Queued 2026-07-05; no open position. (e) Top-10. GATE-SURVIVING. Notable: VRTX is the only name in the sixteen-strong "no establishable earnings date" group (1A.10) whose survival is **substantive rather than merely fail-open** — its dated catalysts are regulatory, not earnings, and both are post-gate.

**4. FSLR — First Solar.** (a) Bullish. (b) A fully specified, quantified, primary-sourced policy catalyst — the Sec 232 tariff regime, whitehouse.gov. Rare in this file: a catalyst whose date, mechanism and magnitude are all documented by the party imposing it. (c) **Sec 232 regime effective 2026-12-04 (C)** — surviving; earnings **2026-10-29 (E, newly established)** — spent. (d) Queued 2026-09-06; no open position. (e) Top-10. **GATE-SURVIVING** on the fail-open reading for a name carrying both a spent and a surviving catalyst.

**5. CAT — Caterpillar.** (a) Bullish. (b) Data-centre and energy capex pull-through; the thesis has been carried undated for two cycles on sector evidence alone. (c) Earnings **2026-11-04 (E) — NEWLY ESTABLISHED this cycle**, two days after the gate. (d) Queued 2026-05-01; no open position. (e) Top-10. **GATE-SURVIVING on an established date rather than on fail-open** — *promoted from #12 for exactly that reason*. Dating a name does not by itself strengthen its thesis, but it converts a candidate that could not be shown actionable into one that demonstrably is, and it removes CAT from the group whose ranking is distorted by unreachable dates. Cap $378.450B measured.

**6. XOM — Exxon Mobil.** (a) Bullish. (b) **Reduced per the mode — no first-party document chase.** The supply-shock seam intensified for a second consecutive week: the Libya El Sharara blockade plus a proposed US diesel-export ban took Brent +8.19% across 09-23/09-24 and made XLE the sole GICS-sector gainer on 09-23 (+0.9550%). (c) Earnings **2026-10-30 (E)**. (d) Queued 2026-09-13; no open position. (e) Top-10. **SPENT-BY-GATE (gate 2026-11-02)** — kept in tier because conviction genuinely rose again, not on gate status.

**7. AVGO — Broadcom.** (a) Bullish. (b) Custom-silicon and AI-networking attach. Live counter-evidence carried: the BofA note on a ~$370B AI-debt vehicle (2026-08-14, −5.94%). (c) Earnings **2026-12-10 (E) — NEWLY ESTABLISHED**, well post-gate. (d) Queued 2026-05-09; no open position. (e) Top-10. GATE-SURVIVING on an established date. *Promoted from #24* — the promotion is entirely the date: the thesis is unchanged, but it was previously ranked in the tier whose catalysts sit in the unreachable tail. Cap $1,678.522B measured.

**8. CVX — Chevron.** (a) Bullish. (b) **Reduced per the mode.** The same seam as XOM. Explicitly correlated with it — XOM and CVX are one concentration decision, not two independent ones, and W4/D2 should treat them as such. (c) Earnings **2026-10-30 (E)**. (d) Queued 2026-09-13; no open position. (e) Top-10. **SPENT-BY-GATE (gate 2026-11-02)**.

**9. CSCO — Cisco.** (a) Bullish. (b) AI-networking order growth against a durably low multiple. Objection carried: elevated valuation-reset concern after the +12.96% session. (c) Earnings **2026-11-11 (E)**, nine days post-gate. (d) Queued 2026-05-09; no open position. (e) Top-10. GATE-SURVIVING.

**10. AMD — AMD.** (a) Bullish, **contested** — the contest is on competitive position, not on direction, so the direction rail does not engage. (b) Counter-evidence carried and material: the exclusive SpaceX AI-compute socket lost to NVDA (2026-08-05). Supporting: the 2026-09-21 semis tape, where AMD reached $1T inside a broad XLK +2.7690% session. (c) Earnings **2026-11-03 (E)** — one day post-gate. (d) Queued 2026-05-29; no open position. (e) Top-10. GATE-SURVIVING **by a single day**, which is worth flagging: a one-day margin is not robust to a date revision, and four vendor dates moved week-over-week last cycle.

### 11–20

**11. MU — Micron. THE MOST CONSEQUENTIAL RECLASSIFICATION OF THE CYCLE, and the cleanest illustration of why this mode exists.** (a) Bullish. (b) **Reduced per the mode.** The thesis is the strongest *quantified* misalignment in the file and is unchanged: DRAM contract prices forecast +>50% this quarter and NAND ~+60% (D1 2026-09-17, `a913941a`), the first MU-specific non-cohort ratification a five-month-queued thesis has had. (c) Earnings (FQ1) **2026-09-30 (E) — NEWLY ESTABLISHED**. (d) Queued 2026-05-09; no open position. (e) **11–20. SPENT-BY-GATE (gate 2026-11-02).** *Demoted from #1.*

Why this is a conviction demotion and not merely an actionability one: MU's catalyst lands **three days from now and 33 days before the gate**. Tier (e) ranks on conviction-strength of the *narrative misalignment* — and this particular misalignment is *consumed by its own catalyst*. After the 09-30 print the DRAM-pricing thesis is no longer a divergence between consensus and public documents; it is either confirmed or refuted by a reported quarter. There is nothing left for an A thesis constructed in November to be early to. This is precisely the distinction the mode's own rationale draws: a queue *row* surviving indefinitely is not the same as the *catalyst thesis* it encodes surviving. **Routing note: from 2026-10-01 MU is a post-event name, which is Strategy B's territory, not A's — and B reads DO-NOT-ACTIVATE.**

**12. GEV — GE Vernova.** (a) Bullish. (b) Reduced per the mode. Electrification and grid capex. Adverse evidence carried: GLJ Research initiated Sell, $470, 2026-09-14 (−8.6189%). (c) Earnings (Q3) **2026-10-28 (E) — NEWLY ESTABLISHED**, five days before the gate. (d) Queued 2026-08-09; **open Strategy D lot `D:GEV:2026-08-03`** — the only name in the upper half of this shortlist that overlaps the open book. (e) 11–20. **SPENT-BY-GATE.** *Demoted from #10* — it survived last cycle only because its date could not be established at all, and establishing it resolved the fail-open in the spent direction. The second case this cycle of dating converting a survivor into a spent name.

**13. MSFT — Microsoft.** (a) Bullish. (b) Azure AI capacity commentary; last four transcripts. (c) Earnings 2026-10-28 (E) — spent; **Ignite 2026-11-17→11-20 (C)** — surviving. (d) Queued 2026-07-05; no open position. (e) 11–20. GATE-SURVIVING on the both-catalysts reading.

**14. AMZN — Amazon.** (a) Bullish. (b) AWS backlog and margin disclosures; 10-Q Note 10. (c) Earnings 2026-10-29 (E) — spent; **re:Invent 2026-11-30→12-04 (C)** — surviving. (d) Queued 2026-07-12; **two open Strategy D lots** (`D:AMZN:2026-07-09`, `D:AMZN:2026-07-30`). (e) 11–20. GATE-SURVIVING.

**15. ORCL — Oracle. DEMOTED ON A CORRECTION, and the correction is the point.** (a) Bullish. (b) Reduced. (c) FQ2 print date **NOT ESTABLISHED (T)** — chased and not found; CloudWorld 2026-10-25→10-28 (C) is spent. (d) Queued 2026-05-09; no open position. (e) 11–20. GATE-SURVIVING (fail-open on the undated print). *Demoted from #11.* **The prior artifact ranked ORCL substantially on a −13.7912% AI-capex repricing session. That figure was open-to-open and is wrong; the true close-to-close move is −3.6532%** (D1 `4264b87f` superseding `46d69e8d`, independently reproduced by D2 `64a9628f` to four decimals). A −3.65% session is not an AI-capex repricing event, and the narrative built on the larger figure does not survive the correction at the rank it held.

**16. QCOM — Qualcomm.** (a) Bullish. (b) Stellantis Snapdragon expansion; auto/IoT diversification. (c) **NOT ESTABLISHED (T)**. (d) Queued 2026-05-01; no open position. (e) 11–20. GATE-SURVIVING (fail-open). Cap $212.069B measured.

**17. MRVL — Marvell Technology.** (a) Bullish. (b) Custom-silicon ramp. (c) **NOT ESTABLISHED (T)**. (d) Queued 2026-05-25; no open position. (e) 11–20. GATE-SURVIVING (fail-open). Cap $229.394B.

**18. DELL — Dell Technologies.** (a) Bullish. (b) AI-server capex; +11.9776% on 2026-09-10. (c) **NOT ESTABLISHED (T)**. (d) Queued 2026-05-17; no open position. (e) 11–20. GATE-SURVIVING (fail-open). Cap $373.907B.

**19. UBER — Uber.** (a) Bullish. (b) The ~3,300-role restructuring's margin effect lands in this print; not on the A queue. (c) Earnings **2026-11-03 (E)**, one day post-gate. (d) **NOT on the A queue** — new intake if W4 converts it; **open Strategy D lot** `D:UBER:2026-07-09`. (e) 11–20. GATE-SURVIVING.

**20. PLTR — Palantir.** (a) Bullish. (b) Government and commercial bookings. (c) Earnings **2026-11-02 (E)** — **lands exactly ON the gate date**. (d) Not on the A queue. (e) 11–20. **GATE-SURVIVING**, on the mode's "strictly before" wording, by zero days. Flagged as the thinnest possible margin in the file: any revision earlier by one day flips it to spent.

### 21–30

**21. SNOW — Snowflake.** Bullish; Cortex AI monetisation (+33% after-hours, $6B AWS commitment). (c) NOT ESTABLISHED (T). (d) Queued 2026-05-25. (e) GATE-SURVIVING (fail-open). Cap $116.437B.
**22. CRM — Salesforce.** Bullish; agentic-AI attach vs a compressed multiple. (c) **NOT ESTABLISHED** — chased individually; only already-past FY27 quarters surfaced. Dreamforce is spent. (d) Queued 2026-05-17. (e) GATE-SURVIVING (fail-open). Cap $191.662B.
**23. NOW — ServiceNow.** Bullish; platform attach. (c) NOT ESTABLISHED (T). (d) Queued 2026-05-29. (e) GATE-SURVIVING (fail-open).
**24. PANW — Palo Alto Networks.** Bullish; platformisation. (c) NOT ESTABLISHED (T). (d) Queued 2026-05-31. (e) GATE-SURVIVING (fail-open).
**25. CRWD — CrowdStrike.** Bullish; module attach. (c) NOT ESTABLISHED (T). (d) Queued 2026-05-31. (e) GATE-SURVIVING (fail-open).
**26. JPM — JPMorgan.** (a) Bullish. (b) Reduced. The NIM-supportive-hike arithmetic survives a hike to 3.75–4.00%, but the adverse tape readings compounded again: XLF **−1.9678% on 2026-09-22** with every constituent moving more than the sector (SCHW −6.1097%, LPLA −7.4520%, ALL −5.5011%, WFC −3.9173%, RJF −3.5111%) — that is now **three separate sessions** in which banks have declined to price a hike they arithmetically benefit from. (c) Earnings 2026-10-13 (E) — spent; **Investor Day 2027-02-22 (C)** — surviving. (d) Queued 2026-09-13. (e) GATE-SURVIVING on the Investor Day only. Held down for the tape, not the gate.
**27. HPE — Hewlett Packard Enterprise.** Bullish; +12.4411% on 2026-09-10, same AI-server read-through as DELL. (c) NOT ESTABLISHED (T). (d) Queued 2026-05-29. (e) GATE-SURVIVING (fail-open).
**28. NBIS — Nebius Group.** Bullish; neocloud capacity. (c) NOT ESTABLISHED (T). (d) Queued 2026-05-13. (e) GATE-SURVIVING (fail-open). Cap $56.959B.
**29. DIS — Disney.** Bullish; SVOD margin expansion (three consecutive quarters, ~13% at FQ3 FY26). (c) Earnings **2026-11-12 (E)**, post-gate. (d) **Not on the A queue**; two open Strategy D lots. (e) GATE-SURVIVING.
**30. SHOP — Shopify.** Bullish; GMV take-rate. (c) Earnings **2026-11-03 (E)**, post-gate. (d) Not on the A queue. (e) GATE-SURVIVING.

### 31–40

All GATE-SURVIVING unless marked. Ranks in this band are set by carried thesis strength rather than catalyst proximity, because most of these names' catalysts sit in the coverage tail (1A.3/1A.10) — a **ranking distortion this artifact states rather than hides**.

**31. IBM** — undated (T), queued 2026-05-29, cap $212.461B. **32. DDOG** — undated (T), queued 2026-05-07. **33. OKTA** — undated (T), queued 2026-05-29. **34. NTAP** — undated (T), queued 2026-05-29. **35. SMCI** — undated (T), queued 2026-05-29, cap $27.984B. **36. MRNA** — earnings 2026-11-05 (E), post-gate; +8.5495% on 09-17 Phase 3 progress; not queued. **37. LLY** — undated (T), queued 2026-05-01, cap $1,114.758B; carries a **terminal Strategy D NO-GO dated 2026-09-14** — context, not a barrier (`Operating_Protocols.md` §3), and a different strategy's criteria entirely; next D re-screen 2026-12-14. **38. INTU** — **no forward dated catalyst at all**, second cycle; Investor Day passed 09-17; queued 2026-08-03; GATE-SURVIVING vacuously. **39. GOOGL** — earnings 10-28 (E), DOJ Final Judgment 10-02 (C), reply brief 09-29 (C): **ALL THREE SPENT-BY-GATE**; queued 2026-07-05; two open D lots. **40. MRK** — earnings 2026-10-29 (E, newly established) plus PDUFAs 10-04 and 10-10: **FULLY SPENT-BY-GATE, no surviving catalyst**; queued 2026-09-13.

### 41–48

**41. INTC** — earnings 2026-10-22 (E), **SPENT-BY-GATE**; +7.6695% on 09-17 on target hikes plus *reported, not confirmed* SK Hynix talks; queued 2026-05-12; cap $620.412B. **42. AAPL** — earnings 2026-10-29 (E), **SPENT-BY-GATE**; queued 2026-05-02. **43. META** — earnings 10-28 (E) and Connect 09-23→09-24 (C), **BOTH SPENT-BY-GATE**; queued 2026-08-03; note XLC +3.5556% on 09-21 was META-driven and explicitly not sector-wide. **44. UNH** — earnings 2026-10-13 (E) **spent**, investor conference ~early Dec (E) surviving; not queued. **45. GE** — earnings 2026-10-20 (E), **SPENT-BY-GATE**; not queued. **46. BAC** — earnings 2026-10-14 (E), **SPENT-BY-GATE**; not queued. **47. V** — earnings 2026-10-27 (E) and DOJ discovery close 10-16 (C), **BOTH SPENT-BY-GATE**; not queued. **48. TGT** — earnings 2026-11-18 (E), GATE-SURVIVING, but **DIRECTION UNRESOLVED**: the prior bearish thesis was refuted by a beat-and-raise and no replacement direction has been established. Held below the actionable tier for that reason specifically, not for rank. Queued 2026-05-09.

### DIRECTION-INADMISSIBLE tier — ranked and carried, never actionable for A

These belong to Strategy B. Suppressing them would lose real signal; the rail governs only admission to the actionable tier.

| # | Ticker | (a) Direction | (c) Catalyst | Gate status | Thesis |
|---|---|---|---|---|---|
| I-1 | **DAL** | Bearish | Earnings 2026-10-09 (E) | SPENT | Fuel hedge books set before the 09-15 shock; **strengthened a third time** by the proposed US diesel-export ban, which attacks the distillate crack rather than only crude. Strongest new thesis in the file, inadmissible for the third consecutive cycle |
| I-2 | **UAL** | Bearish | Earnings 2026-10-21 (E) | SPENT | Same shock, independent print |
| I-3 | **AAL** | Bearish | Earnings 2026-10-22 (E) | SPENT | Same shock, thinnest balance sheet of the three |
| I-4 | **CCL** | Bearish | Earnings 2026-09-29 (E) | SPENT | Bunker-fuel channel; first fuel-exposed reporter in the window |
| I-5 | **AMAT** | Bearish | NOT ESTABLISHED (T) | SURVIVING | China WFE cliff re-affirmed; cap $385.070B |
| I-6 | **WMT** | Bearish | Earnings 2026-11-19 (E) | SURVIVING | Two adverse datapoints against the original bullish framing |
| I-7 | **ADBE** | Bearish | Earnings 2026-12-09 (E) | SURVIVING | Vindicated on tape; sits one day inside the earnings horizon |
| I-8 | **HD** | Bearish / neutral | NOT ESTABLISHED (T) | SURVIVING | Housing-turnover starvation; cap $292.355B |
| I-9 | **AKAM** | Bearish / contested | NOT ESTABLISHED (T) | SURVIVING | Cap $16.565B — the smallest in the file, still 8.3× the floor |

**W4 side, restated because it binds:** no candidate carrying the `DIRECTION-INADMISSIBLE` mark may be converted into a Strategy A `PENDING_ANALYSIS` row, and a vacated slot is filled from the next admissible candidate rather than shipping a short top-10. None of these nine is in the top-10, so no slot needs filling this cycle.

### Handoff notes for W4

- **All ten top-10 names are already on the A queue** (TTWO, NVDA, VRTX, FSLR, CAT, XOM, AVGO, CVX, CSCO, AMD — verified against the 44-row census above). **W4 has ZERO new A intake from the top-10 this week** — the fourth such cycle, and the expected steady state now that the queue carries 44 names drawn from the same universe the shortlist is drawn from. Not a sign the limb failed to run.
- **Candidates below the top-10 that are NOT on the A queue**, should W4's limb ever reach past tier 1: UBER (#19), PLTR (#20), DIS (#29), SHOP (#30), MRNA (#36), UNH (#44), GE (#45), BAC (#46), V (#47).
- **Carry the gate mark onto the queue row.** Per the spec change W1 itself drove last cycle (`ops.alerts` `559ee98c`), each row's `SPENT-BY-GATE (gate 2026-11-02)` / `GATE-SURVIVING` mark and its gate date belong on both the `events.queue_events` row and the `Watchlist.md` table row. The two spent names in this cycle's actionable tier are **XOM and CVX**, and they are one concentration decision, not two.
- **Cross-strategy overlap (§E).** `state.current_positions` returns 12 open rows and **all 12 are Strategy D** — zero open A, B or C positions. Overlap tickers: AMZN, DIS, GEV, GOOGL, ISRG, RTX, TSM, UBER. Of the top-10 only **GEV** (#12 now, demoted out of tier) overlaps the open book; AMZN (#14), GOOGL (#39) and UBER (#19) also overlap, all below tier.
- **Prior NO-GO records exist on 20 of the 44 queued names, and none is a Strategy A NO-GO** — all are Strategy B or D dispositions under different criteria. Context, not barriers (`Operating_Protocols.md` §3). The only recent one worth naming is LLY's terminal Strategy D NO-GO of 2026-09-14.
- **Zero `events.queue_events` rows for Strategy A landed in the catch-up window** (2026-09-20 08:03 UTC → now), verified explicitly. Reported as a finding, not an omission.

---
## PART 2C — Strategy C ranked shortlist

### Router state, and what it admits

C reads **`HYBRID ACTIVATE (FOMC-only)`** (`state.current_regime`, `div-C-202608-1`, `as_of_date` 2026-09-03, theater-check MIXED, `judge_independent` TRUE). C is the **only capital-enabled strategy** in the roster. Under this carve-out only an FOMC-type event is router-admissible; corporate earnings and FDA PDUFA candidates are **router-PARKED** and must not be enqueued. Broad ACTIVATE is procedurally unreachable through a divergence review — widening is reserved to a separate scope-widening adjudication whose conditions (≥5 closed FOMC trades, or portfolio ≥ ~$25k) are unmet, and none is open.

**The one router-eligible event in the 45-day window is the 2026-10-28 FOMC.**

### THE CAPITAL POSITION — CORRECTED THIS CYCLE, AND THE CORRECTION MATTERS

Prior W1 cycles reported C's affordability as a function of its on-book NAV — "a $23.64 NAV cannot collateralise". **That framing is wrong, and it has been wrong for several cycles.** C is a **NOMADIC** strategy (`state.strategy_nomadic_status.is_nomadic` TRUE; mechanism `bigquery/167_nomadic_capital.sql`, owner redesign 2026-08-11). A nomadic strategy **holds no standing capital by design** — not even a reserve floor, which `bigquery/167` explicitly retired — and its trade size is **not** bounded by its residual cash. Per that file: size "is determined ENTIRELY by the AI's normal seven-factor risk-budget judgment (no ceiling)", and the borrow mechanism's only job is to **source** that amount, proportionally, from whatever capital the other enabled non-nomadic strategies hold. Reading C's idle balance as its risk budget is a category error.

**So the real question is borrow capacity, and it is ZERO.** MEASURED, `state.nomadic_borrow_capacity_watch`:

| strategy | donor_capacity_total | donor_count | borrow_blocked |
|---|---|---|---|
| C | **0** | **0** | **TRUE** |

The donor set is empty because the borrow draws on *enabled, non-nomadic* strategies, and there are none: **A, B and E are all `capital_enabled: FALSE`** (E was disabled 2026-09-04 by `div-E-202608-1`, the only state change of that cohort), and **D is itself nomadic**. E holds **$12,672.77** of idle cash and is precisely the strategy that would fund C — and it is capital-disabled. `state.nomadic_capital_ledger` records C at `swept_out_total` **$9,464.72**, `restored_total` **$0**, `net_position` **$9,464.72**.

**This is ALREADY ALERTED and is deliberately NOT re-raised here** — `ops.alerts` `71d484fa-0623-4443-89ed-a357ab305f67`, `nomadic_borrow_blocked`, warning, open since 2026-09-23, first-ever firing of the `bigquery/246` monitor. `INCIDENT[ref=71d484fa]`. Its own payload states the correct response is *an owner decision about the roster*, not a mechanism change, and that it is deliberately `warning` rather than `critical` because a critical would enter `blocking_criticals` and halt all order staging fleet-wide.

**What C can therefore actually afford — stated precisely, because both the old framing and a naive reading of the new one get it wrong.** C's reachable budget is its own cash, **$19.49**, and no more. On that:
- The ATM straddle on the relevant expiry costs **$2,458 per contract** (measured below) — about **126×** C's reachable capital. Out of reach by two orders of magnitude.
- But "affordable = nothing" is also false. `bigquery/246`'s own corrected header records that C's historical candidate structures priced at **$5–$14 per contract**, *inside* C's cash, and that "the cheapest deep-OTM wings remain affordable on C's own cash" while the blocked borrow caps only the richer **$26–$65** structures. The same header records that C **has never opened a position** (zero rows in `events.position_events`) and that the **realized cost of the blocked borrow is $0** — so this must not be cited as evidence that a trade has been lost to zero donor capacity. None has.

**Why the correction changes anything:** the remedy differs. "C's NAV is small" implies waiting for deposits. "C's borrow is blocked for want of any donor" implies that **re-enabling any non-nomadic strategy's capital restores C's funding immediately** — which is a roster/router question already sitting with the owner, not a funding question. That is a materially different thing to be waiting on, and it is why the distinction is worth making rather than glossing.

**One observation, referred rather than investigated:** C's on-book NAV fell **$23.64 → $19.49** (−17.6%) across the week with **zero open positions and zero trades**, and `sweep_now` is TRUE with `sweepable_amount` $19.49 — the residual is itself flagged for sweep. W1 uses the authoritative current figure and does not adjudicate the movement; park/NAV accounting is D2a's and W5's surface, and an open alert already covers that class (`574fed62`, `park_realized_pnl_absent_from_strategy_nav`). Not re-raised.

### Criterion 1 (a qualifying event within 45 days) — and a provenance limit that binds every earnings row

C requires an earnings date **confirmed from company IR** (`strategy/05_strategy_c.md`:25). **Every earnings date in this artifact is (E)** — a vendor or aggregator projection. Not one is company-IR confirmed. So every earnings-based C candidate fails criterion 1 on *provenance* before any volatility measurement, independently of the router. Third consecutive cycle; a property of the reachable data surfaces, not of this week's crop.

The **2026-10-28 FOMC is (C)** — confirmed by a direct fetch of federalreserve.gov this run, not carried and not from an aggregator. It is the only candidate in the window that clears criterion 1 cleanly.

### The tenor rail — CLEAR, second cycle running

C requires structure expiration within **1–45 days of entry** (`strategy/05_strategy_c.md`:21). MEASURED from the live SPY chain — the listed expiries between 2026-10-01 and 2026-12-01 are: 10-01, 10-02, 10-05, 10-06, 10-07, 10-08, 10-09, 10-12, **10-16 (regular)**, 10-23, **10-30**, 11-06, **11-20 (regular)**, 11-30.

**First expiry strictly after the 2026-10-28 decision = 2026-10-30.** Entry is due 2026-10-20 per the queued thesis, so the tenor is **10 days** — comfortably inside 1–45 — and the event falls strictly before expiry. There is no 10-28 or 10-29 expiry, so 10-30 sits two days after the decision, which is a clean event structure. **The tenor blocker that bound this thesis two cycles ago is gone and stays gone.**

### Criterion 2 (implied vs realized) — MEASURED, and on the SPEC-CORRECT WINDOW for the first time

**A correction to W1's own method, applied here.** `strategy/05_strategy_c.md`:82 specifies the entry test as "Implied volatility at entry and comparison to realized volatility over the **trailing 30 days**". W1's 2026-09-13 and 2026-09-20 artifacts both keyed their headline ratio on **HV20**. That is the wrong window. The headline is **IV/HV30**; HV20 and HV10 are context.

MEASURED, SPY, 2026-10-30 expiry, ATM strike 771 against spot 771.35 (IBKR regular-session close 2026-09-25):

| Field | Value |
|---|---|
| ATM call 771 | last 13.80, bid 13.78 / ask 14.05, OI 709 |
| ATM put 771 | last 10.78, bid 10.75 / ask 10.80, OI 269 |
| **`implied_vol` annual_iv** | **12.7813%** — `is_valid` **TRUE** |
| `option_midpoint_iv` annual_iv | **−15.8745**, `isValid` **FALSE** — the invalid sentinel, reproduced exactly again |
| `top_status` | **FROZEN** — Sunday, market closed; values are the 2026-09-25 session's |

Realized volatility, annualized close-to-close from **31 IBKR regular-session daily closes** (2026-08-13 → 2026-09-25, 30 returns), computed in-session:

| Window | Realized vol | Ratio vs IV 12.7813% |
|---|---|---|
| **HV30 (the spec window)** | **9.7628%** | **IV/HV30 = 1.309** |
| HV20 | 10.7612% | IV/HV20 = 1.188 |
| HV10 | 11.8300% | IV/HV10 = 1.080 |

**Verdict: implied is RICH to realized on the spec window — but materially less rich than reported last cycle, and the direction of travel is toward parity.** On the spec-correct window the ratio moved **1.47 → 1.309**. Note *why*: implied was essentially flat (12.84% → 12.7813%) while **realized rose 11.7%** (HV30 8.743% → 9.7628%). Last cycle's headline figure of 1.40 was the HV20 ratio; the comparable HV20 figure this week is 1.188, so the move looks even larger on the number that was actually being quoted. The correction does **not** rescue the long-premium case — the ratio is still above 1.0 on every window — so the verdict is unchanged in sign. It is the magnitude and the trend that change.

**And the realized-vol term structure is INVERTED, which a single HV20 print hides.** HV10 11.83% > HV20 10.76% > HV30 9.76%: realized volatility has been *rising* through the measurement window, and at the 10-day horizon it sits within **8%** of implied. That is forward-looking information the prior method could not surface. If realized continues to converge, the implied-rich condition that has blocked C's affordable structures for six consecutive cycles closes on its own — without any change to router state, roster or funding.

**The structural disjointness, restated with the capital mechanism now correct.** Implied rich favours **selling** premium. A credit structure's max loss must be deterministically collateralized within the risk budget, and **$19.49 cannot collateralize any SPY credit spread** — even a 1-point spread carries $100 gross max loss. What C *can* afford is confined to far-wing **debit** structures, which are on the **buying** side — the wrong side of the measured edge, and the side where probability-weighted payoff is worst. So the edge and the affordability point in opposite directions. This is the same disjointness recorded for six cycles; what is new is that it is now measured on the spec's own window, and the cause of the affordability limit is correctly identified as the **blocked borrow**, not a small NAV.

**Panel measurement deliberately NOT extended this cycle, and this is a scope choice, not an omission.** Prior cycles measured implied-vs-realized across a 19-name panel and tracked the cheapest-premium names as a trend (PYPL 0.68 → 0.72, F 0.83 → 0.94). That series is **not extended here.** Reason: every name in that panel is an *earnings* candidate, and each one now fails criterion 1 on date provenance (all dates (E), none company-IR confirmed) **and** is router-parked under FOMC-only. Measuring implied-vs-realized for a candidate that cannot be entered on two independent grounds buys no decision. The cost of the choice, stated plainly: the trend signal for "does any name offer cheap premium" goes unrefreshed this week, and if the router ever widens, that series will have a one-cycle gap. Judged worth it; a future cycle that sees a router widening should re-establish the panel before relying on the trend.

### Ranked shortlist — 15 event candidates

**TOP-5**

**1. FOMC 2026-10-28** — (a) **No affirmative directional divergence established.** The measurable divergence is on *volatility*, and it runs against the only structures C can fund (IV/HV30 = 1.309, implied rich; C can afford only the buying side). (b) federalreserve.gov meeting calendar, fetched directly; the 2026-09-16 hike to 3.75–4.00% was unanimous with 16 of 18 dots for ≥1 more 2026 hike, so this meeting is genuinely live rather than a formality. (c) **2026-10-28.** (d) **Structure affordable only in the far wings.** Reachable budget $19.49; ATM straddle $2,458/contract (≈126×); historical cheapest wings $5–$14/contract are inside it; borrow capacity zero, `borrow_blocked` TRUE. **Flagged as a deferral risk, not a deferral** — the decision is not W1's. (e) No open A positions exist at all, so no A↔C conflict. (f) **Top-5, rank 1 — the only router-eligible candidate in the window.**
  **Disposition: W1 shortlists and does not drain.** `thesis-FOMC-C-20261020` is **pending** on `state.open_queue`, due **2026-10-20**, and the GO/NO-GO is **D2's on that date**. Its recorded conservative default is "Decline — no entry", applying if no affirmative, sourced, quantified divergence can be established (criterion 2) or if entry cannot be made at least one trading day before the decision (criterion 5). A wildcard search of the queue returned **exactly one** FOMC row — no duplicate October-FOMC entry exists, and W4 must not create one.

**2. INO — INO-3107 PDUFA 2026-10-30.** (a) Binary regulatory outcome; implied typically under-prices a first-approval binary in a small-cap. (b) Inovio's own BLA-acceptance release plus PRNewswire — **multi-sourced**, the best-evidenced new PDUFA in the window. (c) 2026-10-30. (d) Chain liquidity unverified; a micro/small-cap chain may not support a deterministic defined-risk structure at any size. (e) No A overlap. (f) Top-5. **Router-PARKED** (PDUFA ≠ FOMC).

**3. SRRK — Apitegromab PDUFA 2026-09-30.** (a) Binary. (b) Carried and corroborated; note this is the drug an aggregator previously misattributed to PFE/ROIV. (c) 2026-09-30 — **three days out**; entry is not reachable within C's own process. (d) Not assessable in time. (e) None. (f) Top-5 by event quality, unenterable on timing. **Router-PARKED.**

**4. MRK — Ifinatamab deruxtecan PDUFA 2026-10-10.** (a) Binary, large-cap; implied divergence likely small because the name is diversified. (b) Single-sourced this cycle. (c) 2026-10-10. (d) Chain is liquid; affordability still bounded by $19.49. (e) MRK is on the A queue (#40) — **A↔C exclusivity would bind if A ever held it**; A holds nothing. (f) Top-5. **Router-PARKED.**

**5. VTRS — MR-141 PDUFA 2026-10-17.** (a) Binary; presbyopia approval is a commercial-scale question more than an approval-probability one. (b) Single-sourced this cycle. (c) 2026-10-17. (d) Bounded as above. (e) None. (f) Top-5. **Router-PARKED.**

**REST (6–15)** — all **router-PARKED**, all failing criterion 1 on (E) date provenance, none with a measured IV this cycle (see the scope note above). Ranked by event quality and chain usability.

| # | Candidate | (a) Hypothesized divergence | (c) Date | (e) A overlap | Note |
|---|---|---|---|---|---|
| 6 | **MRK** Welireg+Lenvima PDUFA | Binary, second MRK decision in a week | 2026-10-04 | A-queue #40 | (C) source |
| 7 | **BMY** Camzyos PDUFA | Binary, label expansion | 2026-09-30 | none | (2S) |
| 8 | **PHAR** Joenja PDUFA | Binary, micro-cap | 2026-10-24 | none | (2S); chain likely unusable |
| 9 | **BFRI** Ameluz PDT PDUFA | Binary, micro-cap | 2026-09-28 | none | chain likely unusable; 1 day out |
| 10 | **AMD** earnings | Post-shock semis repricing; implied likely rich into a contested print | 2026-11-03 | A-queue #10 | Tenor: expiries jump 10-30 → 11-06, so 11-06 is the first post-event expiry — **inside** the 45-day rail from a 10-20 entry (17 days). Unlike last cycle, AMD is **not** tenor-excluded |
| 11 | **XOM** earnings | Energy supply-shock seam; implied may under-price a second shock leg | 2026-10-30 | A-queue #6 | Same expiry as the FOMC structure |
| 12 | **CVX** earnings | As XOM, correlated | 2026-10-30 | A-queue #8 | |
| 13 | **JPM** earnings | Banks have declined to price a hike three sessions running — a directional divergence candidate | 2026-10-13 | A-queue #26 | |
| 14 | **UNH** earnings | Post-guidance reset | 2026-10-13 | not queued | Date moved two weeks earlier last cycle |
| 15 | **TSLA** earnings | Implied habitually rich into TSLA prints | 2026-10-28 | not queued | Same date as FOMC — a confounded structure, flagged |

**(e) A-vs-C exclusivity is vacuous this cycle.** `state.current_positions` holds 12 open rows, **all Strategy D**; there are **zero open A and zero open C positions**, so there is no ticker-level A↔C conflict to resolve. Recorded as measured, not assumed. Should A ever activate, the overlapping names above (MRK, AMD, XOM, CVX, JPM) are where the rule would bite first.

**Shortlists only.** Full thesis construction per Strategy.md happens in the sessions W4 schedules.

---
## Coverage, provenance and what this cycle changed

**Read scope.** Weekly cadence. `state.current_regime`, `state.current_positions`, `state.open_queue`, `state.rerisking_limb_status`, `state.strategy_nomadic_status`, `state.nomadic_borrow_capacity_watch`, `state.nomadic_capital_ledger`, `state.market_calendar`, `state.signal_marks_curated`, `events.decision_log`, `events.regime_events`, `events.queue_events`, `ops.alerts`, `ops.run_log`. Repo: `strategy/03_strategy_a.md`, `strategy/05_strategy_c.md`, `Experiment_Parameters.md`, `Watchlist.md`, `Operating_Protocols.md`, `ops/connector_tools.yaml`, `bigquery/167`, `bigquery/246`, and the prior `Weekly_Catalyst_Calendar.md`.

**Catch-up window.** `state.routine_catchup_window` gives `window_days` **6.98** against a weekly 1.5× threshold of 10.5 — cadence-normal, so **no `CATCHUP` token is owed** and no missed-period sub-sections are needed. Evidence window: 2026-09-20 08:03:41 UTC → now.

**The daily-to-weekly boundary, honoured, and its gap named again.** Every reused catalyst comes from D1/D2 records in the window and is cited by `entry_id` rather than re-researched: MGM's withdrawn take-private (`4fc1abc0`), FSLY's product launch (`a0a163af`), the 09-15 shock anchor (`db7dc01c`), the Libya blockade (`e01d9ca6`, `3b1fa412`), five sector screens (`4f06d0b0`, `909eda0e`, `730ccc29`, `e01d9ca6`, `4280a628`), and four upstream corrections (ORCL `4264b87f`, MSTR `75b5a4f6`, VIX `0600af1e`, breadth `0162cb25`). **No second broad news scan was run.** Two coverage facts: `events.decision_log` and `events.regime_events` hold **no rows dated after 2026-09-24**, so 09-25/26/27 are unattested by the warehouse; and the structural Friday gap (W1 fires before the D1 that first covers the preceding Friday) remains open as `ops.alerts` `b4e4e563` and is **deliberately not re-raised**. The spec's escape hatch is written for a D1 outage, and D1 is not unavailable — merely not yet due.

**Standing constraints NOT re-alerted, per this section's own instruction.** The FMP earnings-horizon plan cap (`OWNER_ACTIONS.md` `FMP-earn-horizon`); the bulk-enumeration plan gate (`ops.alerts` `6c4004e3`); C's blocked nomadic borrow (`71d484fa`, cited as `INCIDENT[ref=71d484fa]`); the Friday boundary gap (`b4e4e563`); the park/NAV accounting class (`574fed62`). The horizon **movement** is reported above because a moving horizon is new information even when the cap itself is standing.

**Rails, all MEASURED this cycle, none carried:** market cap 62 names (27 previously CAP-UNVERIFIED + 20 allow-listed batch + AVGO + 7 ADRs + 7 already known) — **0 fail**; ADR status **7/7 confirmed mechanically**; 30-day ADV **70 names, 70 pass**, lowest 20× the floor; SPY implied and realized volatility measured directly. **The CAP-UNVERIFIED gap is closed.** The `profile-symbol` caveat in `ops/connector_tools.yaml` — second-source any name within ~30% of the $2B rail, because FMP's implied share count can lag an issuance — was checked and does **not** bind: the smallest cap in the file is AKAM at $16.565B, 8.3× the rail.

**An honest note on how that gap was closed.** The route was not discovered this cycle — `ops/connector_tools.yaml`'s `company` entry has said "go to `profile-symbol` FIRST for a cap on a denied symbol" since 2026-08-30, with the measurement that established it. W1 carried 28 names as CAP-UNVERIFIED for multiple cycles while the remedy sat documented in the manifest it is expected to read. **That is a W1 process failure, not a vendor limitation**, and it is recorded as such rather than presented as a discovery.

**One genuinely new vendor measurement.** `company/batch-market-cap` has a **third** behaviour the manifest does not record. Known: all-allow-listed → complete response (re-confirmed, 20/20, zero drops); mixed → silently drops denied symbols at HTTP 200 (re-confirmed on a designed 4-symbol probe, AAPL+MSFT returned, AVGO+CAT dropped, no error). **New: a batch containing NO allow-listed symbol returns an outright `ACCESS DENIED` with zero rows** (28 queue-only symbols). So the gate is per-symbol filtering, and "silent partial" is simply what a mixed batch looks like. Consequence for callers: a non-empty response is never evidence of completeness, and an empty-vs-error distinction carries real information about batch composition.

**Coverage stated as floors.** Universe enumeration remains impossible on this tier, so every PART 1A count is a floor over 79 reachable vendor calendar rows plus the 44-row queue. The FMP calendar returned only 46 rows for late October, where the real US market has hundreds of reporters — it is the ~87-name free-tier allow-list, not a calendar. Sixteen A-queue names carry no establishable forward earnings date (1A.10). The PDUFA table is a floor measured twice. The last ~15 weeks of the A window carry no bulk coverage at all, which surfaces as a **ranking distortion** in the 31–40 band rather than as missing rows, and that band says so.

**What moved this cycle, in one place.** The gate date held at 2026-11-02 for a third cycle but the arithmetic moved on both legs — the price leg came within **1.85%** of clearing on 09-22 and was pushed back to **−9.25%** by the Libya blockade, and the quiet-clock anchor moved 09-15 → 09-23 (a judgment that does not change the gate under either reading). **Eight previously-undated names acquired dates**, five of them pre-gate, which is why the spent count rose 14 → 23 without the gate moving. **MU fell from #1 to the 11–20 band** because dating its catalyst to 2026-09-30 proved the thesis is consumed before A can act; **GEV** fell out of tier the same way. **CAT and AVGO were promoted** for the mirror-image reason. **ORCL was demoted on a corrected measurement** (−13.79% was open-to-open; the true close-to-close is −3.65%). **TTWO takes #1** on the only confirmed-date, high-magnitude catalyst in the file. Strategy C's criterion 2 was re-measured on the spec-correct 30-day window for the first time, and C's affordability was re-diagnosed from "small NAV" to "blocked borrow with zero donors".

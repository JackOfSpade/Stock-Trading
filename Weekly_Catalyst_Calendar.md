2026-W38

# Weekly Catalyst Calendar — Strategies A and C

Run date **2026-09-20** (Sunday, the `weekly_sun` slot). Windows measured from the run date: **Strategy A = 6 months (2026-09-20 → 2027-03-20); Strategy C = 45 days (2026-09-20 → 2026-11-04).** Marker `2026-W38` is the ISO week of today, the same week W2 and W3 stamp this cycle.

**EFFECTIVE CONFIRMED-EARNINGS HORIZON: 2026-12-09 — 80 days, ~11.4 weeks.** The "6 months" above is the window this file *searches*; it is not the horizon its bulk source *reaches*. MEASURED this run across five date-sliced requests: the vendor returned rows out to 2026-12-09 (ADBE, the single row in the whole of December) and **zero** rows for a 2027-01-05..2027-01-20 probe. The last ~14 weeks of the 6-month window — the FY-report cluster — cannot be filled from any bulk source on this plan tier.

**AND THE HORIZON IS NOW MEASURABLY SHRINKING, WHICH IS NEW INFORMATION.** Three consecutive cycles, same probe: 2026-09-06 → terminal date 2026-12-03, **88 days** of depth; 2026-09-13 → 2026-12-09, **87 days**; 2026-09-20 → 2026-12-09, **80 days**. The terminal date advanced 6 days in the first step and **zero** days in the second, while the run date advanced 7 days each time. So the "~13-week forward-rolling window" recorded in the standing constraint is behaving less like a rolling window and more like a slowly-creeping terminal date, and the effective depth has lost 8 days in a fortnight. Stated here and in this run's note as the spec directs; deliberately **not** re-alerted — the plan-tier limit itself is a standing, known constraint carried in `OWNER_ACTIONS.md` (`FMP-earn-horizon`) and `ops/connector_tools.yaml`, and a weekly re-raise is alarm fatigue.

**CATCH-UP: none owed.** `state.routine_catchup_window` for W1 returns `window_days = 6.98`, `never_completed = false`, `window_start_ts = 2026-09-13T08:08:23Z` — below the weekly 1.5× threshold of 10.5 days, so this run's evidence window is the ordinary one week.

---

## PART 1A — Strategy A universe (6-month window, 2026-09-20 → 2027-03-20)

**COVERAGE IS A FLOOR, NOT A TOTAL, AND THE REASON IS STRUCTURAL.** Strategy A's stated universe is "all US-listed equities with market cap ≥ $2B and 30-day ADV ≥ $10M with a scheduled catalyst in the next 6 months." That universe **cannot be enumerated on this FMP plan tier**: `search/search-company-screener`, every `directory.*` route and `quote/batch-quote` are each separately tool-level ACCESS DENIED (measured 2026-08-03 / 2026-08-19 / 2026-08-26; carried, not re-probed this run). So every count below is a floor over the symbols the vendor's forward calendar actually reaches, plus the names already on the A queue, plus carried non-earnings rows. This is the same standing plan-tier gate recorded at `ops.alerts` `6c4004e3` and is deliberately **not** re-alerted.

**Bulk pull this run: 77 rows, 77 unique symbols, spanning 2026-09-24 → 2026-12-09, from four contiguous date-sliced requests plus one horizon probe.** One row rejected as suspect (below). Market cap MEASURED for all 77 (see the rails section after 1A.7).

### 1A.1 — Earnings inside the Strategy C 45-day window (2026-09-21 → 2026-11-04) — 63 rows

Provenance **(E)** throughout: the vendor calendar exposes no confirmed/estimated distinction, and Strategy C separately requires a date confirmed from company IR, which a bulk calendar pull does not discharge. "A-elig." applies A's own rails — US-listed common equity (no ADRs), cap ≥ $2B.

| Ticker | Catalyst | Date | Prov. | A-elig. | Source |
|---|---|---|---|---|---|
| COST | Earnings | 2026-09-24 | E | yes | FMP bulk pull |
| CCL | Earnings | 2026-09-29 | E | yes | FMP bulk pull |
| NKE | Earnings | 2026-10-01 | E | yes | FMP bulk pull |
| PEP | Earnings | 2026-10-08 | E | yes | FMP bulk pull |
| TLRY | Earnings | 2026-10-08 | E | **NO** — cap $0.45B < $2B | FMP bulk pull |
| DAL | Earnings | 2026-10-09 | E | yes | FMP bulk pull |
| BAC | Earnings | 2026-10-13 | E | yes | FMP bulk pull |
| C | Earnings | 2026-10-13 | E | yes | FMP bulk pull |
| GS | Earnings | 2026-10-13 | E | yes | FMP bulk pull |
| JNJ | Earnings | 2026-10-13 | E | yes | FMP bulk pull |
| JPM | Earnings | 2026-10-13 | E | yes | FMP bulk pull |
| UNH | Earnings | 2026-10-13 | E | yes | FMP bulk pull |
| WFC | Earnings | 2026-10-13 | E | yes | FMP bulk pull |
| TSM | Earnings | 2026-10-15 | E | **NO** — ADR | FMP bulk pull |
| GE | Earnings | 2026-10-20 | E | yes | FMP bulk pull |
| GM | Earnings | 2026-10-20 | E | yes | FMP bulk pull |
| KO | Earnings | 2026-10-20 | E | yes | FMP bulk pull |
| LMT | Earnings | 2026-10-20 | E | yes | FMP bulk pull |
| NFLX | Earnings | 2026-10-20 | E | yes | FMP bulk pull |
| VZ | Earnings | 2026-10-20 | E | yes | FMP bulk pull |
| T | Earnings | 2026-10-21 | E | yes | FMP bulk pull |
| UAL | Earnings | 2026-10-21 | E | yes | FMP bulk pull |
| AAL | Earnings | 2026-10-22 | E | yes | FMP bulk pull |
| F | Earnings | 2026-10-22 | E | yes | FMP bulk pull |
| INTC | Earnings | 2026-10-22 | E | yes | FMP bulk pull |
| NOK | Earnings | 2026-10-22 | E | **NO** — ADR | FMP bulk pull |
| HCA | Earnings | 2026-10-23 | E | yes | FMP bulk pull |
| CARR | Earnings | 2026-10-27 | E | yes | FMP bulk pull |
| PYPL | Earnings | 2026-10-27 | E | yes | FMP bulk pull |
| SOFI | Earnings | 2026-10-27 | E | yes | FMP bulk pull |
| V | Earnings | 2026-10-27 | E | yes | FMP bulk pull |
| BA | Earnings | 2026-10-28 | E | yes | FMP bulk pull |
| GOOGL | Earnings | 2026-10-28 | E | yes | FMP bulk pull |
| META | Earnings | 2026-10-28 | E | yes | FMP bulk pull |
| MSFT | Earnings | 2026-10-28 | E | yes | FMP bulk pull |
| SBUX | Earnings | 2026-10-28 | E | yes | FMP bulk pull |
| TSLA | Earnings | 2026-10-28 | E | yes | FMP bulk pull |
| ~~FDX~~ | ~~Earnings~~ | ~~2026-10-28~~ | **T — REJECTED AS SUSPECT** | — | FMP bulk pull |
| AAPL | Earnings | 2026-10-29 | E | yes | FMP bulk pull |
| AMZN | Earnings | 2026-10-29 | E | yes | FMP bulk pull |
| COIN | Earnings | 2026-10-29 | E | yes | FMP bulk pull |
| RBLX | Earnings | 2026-10-29 | E | yes | FMP bulk pull |
| RIOT | Earnings | 2026-10-29 | E | yes | FMP bulk pull |
| RKT | Earnings | 2026-10-29 | E | yes | FMP bulk pull |
| ABBV | Earnings | 2026-10-30 | E | yes | FMP bulk pull |
| CVX | Earnings | 2026-10-30 | E | yes | FMP bulk pull |
| XOM | Earnings | 2026-10-30 | E | yes | FMP bulk pull |
| FUBO | Earnings | 2026-11-02 | E | **NO** — cap $1.10B < $2B | FMP bulk pull |
| PLTR | Earnings | 2026-11-02 | E | yes | FMP bulk pull |
| AMD | Earnings | 2026-11-03 | E | yes | FMP bulk pull |
| PFE | Earnings | 2026-11-03 | E | yes | FMP bulk pull |
| PINS | Earnings | 2026-11-03 | E | yes | FMP bulk pull |
| RIVN | Earnings | 2026-11-03 | E | yes | FMP bulk pull |
| SHOP | Earnings | 2026-11-03 | E | yes | FMP bulk pull |
| SIRI | Earnings | 2026-11-03 | E | yes | FMP bulk pull |
| UBER | Earnings | 2026-11-03 | E | yes | FMP bulk pull |
| ET | Earnings | 2026-11-04 | E | yes | FMP bulk pull |
| ETSY | Earnings | 2026-11-04 | E | yes | FMP bulk pull |
| HOOD | Earnings | 2026-11-04 | E | yes | FMP bulk pull |
| LCID | Earnings | 2026-11-04 | E | **NO** — cap $1.30B < $2B | FMP bulk pull |
| MGM | Earnings | 2026-11-04 | E | yes | FMP bulk pull |
| ROKU | Earnings | 2026-11-04 | E | yes | FMP bulk pull |
| SNAP | Earnings | 2026-11-04 | E | yes | FMP bulk pull |

**FDX 2026-10-28 rejected as suspect, second cycle running.** FedEx's fiscal year ends 31 May, so its four quarters report in mid/late September, mid/late December, mid-March and late June. Late October falls in none of them — it is mid-quarter for FQ2 FY2027. The row is not dropped silently; it is named and struck, and it is the **only** suspect row in the 77 (no duplicate symbols, no obviously wrong tickers elsewhere).

**DATES MOVED WEEK-OVER-WEEK, AND THE (E) TAG IS DOING REAL WORK.** Four rows that also appeared in last cycle's pull carry different dates this cycle: **UNH 2026-10-27 → 2026-10-13** (two weeks earlier), **CCL 2026-10-05 → 2026-09-29**, **BAC 2026-10-14 → 2026-10-13**, **DAL 2026-10-08 → 2026-10-09**. These are vendor estimate revisions, not corrections this file made. Nothing downstream should treat an (E) earnings date as stable enough to enter against without a first-party confirmation — which is exactly why Strategy C's own criterion demands company IR and PART 1B does not discharge it from this table.

### 1A.2 — Earnings from 2026-11-05 to the horizon (2026-12-09) — 14 rows

| Ticker | Catalyst | Date | Prov. | A-elig. | Source |
|---|---|---|---|---|---|
| MRNA | Earnings | 2026-11-05 | E | yes | FMP bulk pull |
| SONY | Earnings | 2026-11-10 | E | **NO** — ADR | FMP bulk pull |
| CSCO | Earnings | 2026-11-11 | E | yes | FMP bulk pull |
| BILI | Earnings | 2026-11-12 | E | **NO** — ADR | FMP bulk pull |
| DIS | Earnings | 2026-11-12 | E | yes | FMP bulk pull |
| BIDU | Earnings | 2026-11-17 | E | **NO** — ADR | FMP bulk pull |
| NVDA | Earnings | 2026-11-18 | E | yes | FMP bulk pull |
| TGT | Earnings | 2026-11-18 | E | yes | FMP bulk pull |
| WMT | Earnings | 2026-11-19 | E | yes | FMP bulk pull |
| ZM | Earnings | 2026-11-23 | E | yes | FMP bulk pull |
| BABA | Earnings | 2026-11-24 | E | **NO** — ADR | FMP bulk pull |
| NIO | Earnings | 2026-11-24 | E | **NO** — ADR | FMP bulk pull |
| DOCU | Earnings | 2026-12-03 | E | yes | FMP bulk pull |
| ADBE | Earnings | 2026-12-09 | E | yes | FMP bulk pull |

### 1A.3 — Earnings from 2026-12-10 to 2027-03-20 — **STRUCTURALLY EMPTY, NOT MISSING**

Zero rows, and this is a coverage statement rather than a finding. The vendor's forward calendar stops at 2026-12-09 (measured above). The documented fallback — project last year's actual report dates forward — is unavailable because the historical end of the same route is explicitly refused on this tier, and `calendar/earnings-company` and `statements/income-statement` at `period=quarter` are both ACCESS DENIED. So roughly 14 weeks of the 6-month window carry **no** bulk earnings coverage. The effect on this file is a **ranking distortion, not a gap in the table**: names whose only catalyst is an unreachable Q4/FY print are ranked on carried thesis strength rather than on catalyst proximity, and they are marked `(T)` in PART 2A so the distortion is visible rather than silent. Per the standing rule, shortlisted names in this tail may be filled per-name via the sanctioned WebSearch→Tavily→IR chain; this cycle none required it, because every top-10 name already carries a dated or queue-carried catalyst (see PART 2A).

### 1A.4 — Product launches, keynotes and product events

| Ticker | Event | Date | Prov. | Source |
|---|---|---|---|---|
| META | Meta Connect 2026 | 2026-09-23 → 09-24 | C | CARRIED |
| NVDA | GTC Berlin | 2026-10-20 → 10-22 | E | CARRIED |
| ORCL | Oracle AI World / CloudWorld 2026 | 2026-10-25 → 10-28 | C | CARRIED |
| ADBE | Adobe MAX 2026 | 2026-11-10 → 11-12 | E | CARRIED |
| MSFT | Microsoft Ignite 2026 | 2026-11-17 → 11-20 | C | CARRIED |
| TTWO | **GTA VI launch** (PS5, Xbox Series X\|S); preload 11-12 | 2026-11-19 | C | CARRIED, confirmed twice over |
| AMZN | AWS re:Invent 2026 | 2026-11-30 → 12-04 | C | CARRIED |
| NVDA | GTC Washington DC | 2026-11-30 → 12-03 | E | CARRIED |
| GOOGL | Waymo multi-city robotaxi launches (Dallas, Houston, San Antonio, Miami, Orlando) | 2026 (year only) | T | CARRIED |
| broad | CES 2027, Las Vegas | 2027-01-06 → 01-09 | E | CARRIED |
| NVDA | **GTC 2027, San Jose** | 2027-03-15 → 03-18 | C | CARRIED — **newly inside the window** |

**Dropped this cycle because they are now PAST, named so the absence is not read as a loss of coverage:** CRM Dreamforce (2026-09-15 → 09-17) and the AAPL 2026-09-09 keynote. NVDA GTC 2027 is the reciprocal case — last cycle it sat beyond a window ending 2027-03-13 and was recorded as "BEYOND WINDOW"; the window's advance to 2027-03-20 pulls it inside, so it is promoted to a row rather than re-discovered.

### 1A.5 — Analyst days, investor days, conferences

| Ticker | Event | Date | Prov. | Source |
|---|---|---|---|---|
| BGC | FMX (BGC Group) first Investor Day, NYC | 2026-10-13 | C | CARRIED |
| WDAY | Workday Financial Analyst Day, at Workday Rising | 2026-10-13 | C | CARRIED |
| NKE | Nike investor day | "Fall 2026" | T — no day, single weak source | CARRIED |
| UNH | UnitedHealth investor conference | ~early Dec 2026 | E — projected from annual cadence | CARRIED |
| JPM | JPMorganChase Investor Day | 2027-02-22 | C | CARRIED |

**Dropped as PAST:** ON Financial Analyst Day (09-16), INTU Investor Day (09-17), DCO Investor Day (09-17). INTU's removal matters for PART 2A: it was the nearest dated catalyst on the entire A queue for two consecutive cycles, and with it spent, INTU now carries **no** forward dated catalyst at all.

### 1A.6 — Regulatory, legal, trade, policy and macro decisions

| Ticker(s) | Event | Date | Prov. |
|---|---|---|---|
| GOOGL | DOJ v. Google search remedies — reply brief due (D.C. Cir.); argument unscheduled | 2026-09-29 | C |
| BMY | Camzyos, adolescent oHCM sNDA — PDUFA | 2026-09-30 | 2S |
| SRRK | Apitegromab, SMA (BLA) — PDUFA | 2026-09-30 | C |
| broad | US government funding deadline; Senate-passed CR runs to 2026-12-11 | 2026-09-30 | E |
| GOOGL | DOJ v. Google ad-tech — joint proposed Final Judgment due | 2026-10-02 | C |
| MRK | Welireg + Lenvima, advanced RCC sNDA — PDUFA | 2026-10-04 | C |
| MRK | Ifinatamab deruxtecan, ES-SCLC BLA — PDUFA | 2026-10-10 | C |
| V | DOJ v. Visa — fact discovery closes (expert discovery to 2027-04-08); no trial date | 2026-10-16 | C |
| VTRS | MR-141, presbyopia sNDA — PDUFA | 2026-10-17 | C |
| AAPL | Company-stated deadline to update App Store terms, EU DMA compliance | by Oct 2026 | C as commitment, no day |
| PHAR | Joenja — PDUFA | 2026-10-24 | 2S |
| GSK | Bepirovirsen, hepatitis B — PDUFA (ADR sponsor) | 2026-10-26 | C |
| **broad** | **FOMC decision, two-day meeting Oct 27–28** | **2026-10-28** | **C — federalreserve.gov** |
| INO | INO-3107 — PDUFA | 2026-10-30 | C |
| broad | USTR Section 301 exclusions (178 products) expire 23:59 ET | 2026-11-10 | C |
| Beren | Adrabetadex — PDUFA | 2026-11-17 | 2S |
| UNP · NSC | STB UP–NS merger review: public comments due | 2026-11-18 | C |
| CAPR | Deramiocel — PDUFA, extended from 2026-08-22 | 2026-11-22 | **C — company 8-K, SEC EDGAR, re-confirmed this run** |
| SVRA | Molbreevi — PDUFA | 2026-11-22 | 2S |
| VRTX | Povetacicept BLA, IgA nephropathy, Priority Review — PDUFA | 2026-11-30 | C |
| UNP · NSC | STB UP–NS: DOJ / USDOT preliminary comments due | 2026-12-03 | C |
| FSLR + solar chain | Section 232 tariff / minimum-import-price regime **effective** (polysilicon $21/kg, ingots-wafers $100/kg, cells $0.22/W, modules $0.38/W) | 2026-12-04 | C — whitehouse.gov |
| VRTX | Journavx (suzetrigine), chronic low-back-pain sNDA — PDUFA | 2026-12-05 | 2S |
| **broad** | **FOMC decision, two-day meeting Dec 8–9** | **2026-12-09** | **C — federalreserve.gov** |
| BA | FAA type certification, 737 MAX 10 | by year-end 2026 | T |
| NVO | FDA decision, CagriSema NDA — ADR, not A-eligible | late 2026 | T |
| PRAX | Relutrigine — PDUFA, extended | 2026-12-27 | 2S |
| DYN | Z-rostudirsen BLA, DMD exon 51, Priority Review — PDUFA | 2027-01-21 | C |
| UNP · NSC | STB UP–NS: responses to comments / protests due | 2027-02-16 | C |
| BMRN | VOXZOGO sNDA — full approval, achondroplasia | 2027-02-28 | C |
| SRPT | AMONDYS 45 / VYONDYS 53 sNDAs, DMD — cap ~$2.14B, on the $2B floor, re-measure before use | 2027-02-28 | C |
| LYV | DOJ / states v. Live Nation — remedies phase, unscheduled | ~2027-02 | E |
| WBD (acquirer PSKY) | States' antitrust trial over Paramount Skydance–WBD merger begins | 2027-03-02 | C |

**The macro row is not decoration this cycle.** The **2026-09-16 FOMC hiked 25bp to 3.75–4.00%** — unanimous, the first hike since 2023, hawkish tone, and **16 of 18 dots for at least one more hike in 2026** (source: Federal Reserve statement, federalreserve.gov, via D1's 2026-09-16 session). That makes both remaining 2026 meetings live, dated, market-wide catalysts rather than calendar furniture, and it is the direct cause of the 10Y sitting at 4.94–4.97% and of the financials repricing that PART 2A acts on below.

**BEYOND WINDOW, named so a later cycle does not re-discover it:** FTC v. Amazon trial, ~2027-03-29 (E) — still outside a window ending 2027-03-20.

**Not searched this run:** the FDA advisory-committee calendar for new Oct–Mar notices. Stated as an un-searched surface, not as an empty one.

### 1A.7 — Restructuring and structural events

| Ticker(s) | Event | Date | Prov. |
|---|---|---|---|
| SWKS · QRVO | **$22B Skyworks–Qorvo merger: CEO told an investor conference it has cleared all but two jurisdictions** | close undated | **C — NEW this cycle, from D1 2026-09-15** |
| KMB · KVUE | Kimberly-Clark / Kenvue merger close; votes passed 2026-01-29; outside date 2026-11-02, auto-extending to 2027-05-03 | 2H / by year-end 2026 | T |
| TECK | Anglo American–Teck final approvals; China MOFCOM the last pending item | spans window | C |
| CTVA | "Vylor" seed/genetics spin-off completion — company says only "on track for Q4 2026" | Q4 2026 | T |
| Nasdaq-100 | Annual reconstitution, effective before third-Friday open | mid-Dec 2026 | E |
| S&P 500 | Q4 quarterly index rebalance | 2026-12-18 | E |
| DG | CEO transition — Fleeman becomes CEO | 2027-01-01 | C |
| BA | SVP Finance Shedd succeeds Cleary as Controller (8-K 2026-08-21) | upon 2026 10-K filing | C |
| S&P 500 | Q1 2027 quarterly index rebalance (third Friday, mechanical) | 2027-03-19 | E |

**Narrative-only, no datable row, but load-bearing for PART 2A theses:** UBER's 2026-09-02 restructuring (~3,300 roles, ~10% of headcount) — the margin effect lands in the 2026-11-03 print, which is the dated catalyst; GNRC's up-to-$8B Amazon data-centre generator supply agreement plus a warrant for ~3% of shares (regulatory filing, 2026-09-17); ENVA's withdrawal of the Grasshopper Bancorp applications (2026-09-15), which is a resolved event rather than a forward one.

**Dropped as PAST:** S&P 500 Q3 quarterly rebalance (2026-09-18).

### Universe rails — what was MEASURED and what was not

- **Market cap: MEASURED for all 77 calendar symbols** in a single `company/batch-market-cap` request that returned **77 of 77, zero silently omitted** — reconciled symbol-by-symbol against the request, as the shared metered-calls rule requires. Spot values: NVDA $5.38T, AAPL $4.94T, GOOGL $4.23T, MSFT $3.67T, AMZN $2.73T, TSM $2.25T, META $1.70T, TSLA $1.44T, JPM $937B, WMT $849B, V $688B, XOM $676B, JNJ $651B. Three symbols fail the $2B floor (TLRY $446M, LCID $1.30B, FUBO $1.10B) and are marked NO in 1A.1.
- **Market cap: NOT measured, carried as `CAP-UNVERIFIED`, for queue-only names** — every A-queue ticker absent from the forward calendar (AKAM, AMAT, AVGO, CAT, CRM, CRWD, DDOG, DELL, FSLR, GEV, HD, HPE, IBM, INTU, LLY, MRVL, MU, NBIS, NOW, NTAP, OKTA, ORCL, PANW, QCOM, SMCI, SNOW, TTWO, VRTX). The batch route is scoped to the same plan-covered allow-list as the forward calendar and drops out-of-list symbols **silently, with no error** (measured 2026-09-13: 47 requested → 8 returned), and single-symbol `company/market-cap` is ACCESS DENIED. This run's 77/77 success does not overturn that; it narrows it — see `events.decision_log`, `ops-note` 2026-09-20, which attaches the evidence to the open alert rather than minting a second one.
- **30-day ADV: MEASURED off IBKR daily bars** for the shortlist — see the rails line at the foot of PART 2A. FMP cannot serve this rail at any tier.
- **Seven ADRs excluded from A** by the US-listed-common-equity rail: TSM, NOK, SONY, BILI, BIDU, BABA, NIO. TSM's ineligibility is settled — `events.decision_log`, 2026-08-09 — and it remains queued-and-flagged in `Watchlist.md` rather than deleted, which is why `Watchlist.md` carries one more A row than `state.open_queue` does.

---

## PART 1B — Strategy C universe (45-day window, 2026-09-20 → 2026-11-04)

Strategy C's qualifying events are exactly three types — earnings confirmed from company IR, FDA PDUFA dates confirmed from the FDA calendar or company disclosure, and FOMC meetings from the Fed calendar. Analyst days, product launches, M&A, legal rulings and index rebalances are excluded at the strategy level and are not listed here even though PART 1A carries them.

### 1B.1 — FOMC (confirmed, federalreserve.gov)

| Meeting | Decision date | In window | Notes |
|---|---|---|---|
| Two-day meeting Oct 27–28 | **2026-10-28** | **YES** | Press conference; no SEP |
| Two-day meeting Dec 8–9 | 2026-12-09 | no — 35 days past the window edge | SEP (dot plot); carried for context |

**The 2026-10-28 date was re-confirmed against the primary source this run, not carried.** Last cycle recorded it; this run verified it independently on federalreserve.gov's own October 2026 calendar page, which states "FOMC Meeting — Two-day meeting, October 27 - 28" with the press conference on the 28th. CONFIRMED, not corrected. The September meeting (Sep 15–16) has already occurred and is a resolved development, not a forward row.

### 1B.2 — Earnings inside the window

Thirty-nine distinct A-eligible US-listed names plus the ineligible ones — the same dated set as PART 1A.1, not duplicated here. **Provenance is (E), not (C), and that is a hard limit on this table's usefulness to C**: C's criterion 1 requires a date "confirmed from company IR", and a bulk vendor calendar does not discharge it. Four of these dates moved by up to two weeks in the last seven days (1A.1). Any C thesis built on an earnings date in this window owes a first-party IR confirmation at thesis-construction time, which is D2's step, not this file's.

### 1B.3 — FDA PDUFA target action dates

**This table is a FLOOR and a deliberately conservative one.** The FDA publishes no forward PDUFA calendar, so any sweep depends on aggregators or company disclosure. A dedicated pass last cycle over the October sub-window closed **zero** new rows, and this cycle's broad pass closed zero again — so the floor is now measured twice, not assumed.

| PDUFA date | Ticker | Drug / indication | Provenance | C-eligible? |
|---|---|---|---|---|
| 2026-09-26 | MIRM | Zilurgisertib, FOP | CARRIED (MIRM-vs-INCY ambiguity resolved 2026-09-13) | yes |
| 2026-09-28 | BFRI | Ameluz PDT, sBCC (sNDA) | CARRIED | nominally — micro-cap, options chain likely unusable |
| 2026-09-30 | SRRK | Apitegromab, SMA (BLA) | CARRIED, corroborated by D1 2026-09-17 | yes |
| 2026-09-30 | BMY | Camzyos, adolescent oHCM (sNDA) | CARRIED (2S) | yes |
| 2026-10-04 | MRK | Welireg + Lenvima, advanced RCC | CARRIED (C) | yes |
| 2026-10-09 | RHHBY | Tecentriq, colon cancer | CARRIED, **independently corroborated this run** | **NO** — ADR |
| 2026-10-10 | MRK | Ifinatamab deruxtecan, ES-SCLC | CARRIED (C), **independently corroborated this run** | yes |
| 2026-10-15 | RHHBY | Enspryng, thyroid eye disease | CARRIED, **independently corroborated this run** | **NO** — ADR |
| 2026-10-17 | VTRS | MR-141, presbyopia (sNDA) | CARRIED (C), **independently corroborated this run** | yes |
| 2026-10-24 | PHAR | Joenja | CARRIED (2S) | yes |
| 2026-10-26 | GSK | Bepirovirsen, hepatitis B | CARRIED, **independently corroborated this run** | **NO** — ADR |
| 2026-10-30 | INO | INO-3107 | CARRIED — **newly inside the window** | yes |

**THE MOST USEFUL THING THIS RUN'S PDUFA PASS PRODUCED WAS CORROBORATION, NOT NEW ROWS.** An independent aggregator pull returned five dates that match the carried table exactly — RHHBY 10-09, MRK 10-10, RHHBY 10-15, VTRS 10-17, GSK 10-26. Zero new closable rows, but five carried rows that were previously single-sourced are now two-sourced. That is a real improvement in the table's quality and it is why the pass was not wasted. **INO 2026-10-30** is the one genuinely new in-window row, and it arrived not from a search but from the window's own advance: last cycle it sat one day past a window edge of 2026-10-28, and a window edge of 2026-11-04 pulls it in.

**Rows the aggregator returned that are NOT carried, and why — read this before re-searching them.** The scrape came back visibly malformed (rows merged and truncated) and produced at least one row that is an attribution error of exactly the class this file struck last cycle: **"Apitegromab (SAPPHIRE), PFE/ROIV, 2026-09-30"**. Apitegromab is **Scholar Rock's (SRRK)**, which is how it appears in the carried table above and in D1's own 2026-09-17 record; the PFE/ROIV pairing is the scrape's error, not a second asset. No aggregator row was promoted to this table on a single malformed source. Per the standing rule the alternative would have been to spend a fresh budget confirming each against company IR; with zero new rows on offer and the floor already measured twice, that spend was declined and is stated here rather than hidden.

**Two forward PDUFA rows asserted elsewhere in the fleet are deliberately absent from this table.** D1's 2026-09-17 Daily.md states, as a measured absence, that "the nearest are GSK's Jideytro (9/18), RARE's Ux11119 (9/19) and IONS' zilganersen (9/22)." **Jideytro is Nuvalent's (NUVL) brand for zidesamtinib and it was APPROVED 2026-07-22**, roughly two months ahead of its own PDUFA target — resolved against the FDA approvals page by W1 on 2026-09-13 and carried here, not re-measured today. It is neither GSK's nor a forward action date. IONS zilganersen is recorded by the same prior W1 cycle as resolved 2026-09-03, a carried finding held at lower confidence because it was not re-measured either. Neither row is carried forward here. Recorded as `ops.alerts` `031108b9-d534-450c-a8fe-2c1844961c21` (`d1_pdufa_roster_repeats_struck_attribution`, info) naming D1 as owner — W1 does not own D1's FDA limb and did not repair it.

**Excluded by type, not by oversight:** GRAL's Galleri advisory-committee panel (2026-09-23) is an AdCom vote, not a PDUFA target action date, and does not qualify under C's event list. **Now past:** RARE UX111 (2026-09-19), TLX Pixclara (2026-09-11).

---

## PART 2A — Strategy A preliminary shortlist (48 candidates, ranked)

### STEP 1 — THE GATE DATE, DERIVED FROM SCRATCH, WITH ITS ARITHMETIC

Strategy A's router reads **DO-NOT-ACTIVATE** (`state.current_regime`, scope `STRATEGY_ACTIVATION`, key `A`, `as_of_date` 2026-09-03, divergence `div-A-202608-1`, theater-check MIXED) — the **fifth consecutive cycle** at DNA — and `state.strategy_capital_enablement` carries A as capital-disabled with NAV $0.00. So CATALYST-GATE MODE is live, not inert, and the gate date must be derived.

**The gate date is A's next REACHABLE M1a/M1b re-score, not simply its next scheduled one.** M1a and M1b are `monthly_ftd` — first trading day of the month — so the scheduled re-scores are 2026-10-01, 2026-11-02 (2026-11-01 is a Sunday) and 2026-12-01. Both overlay legs are applied below. All values are MEASURED this run from `state.rerisking_limb_status` (row `strategy = 'A'`, `as_of_denver = 2026-09-20`) unless stated.

**LEG 1 — THE PRICE LEG. FAILS.**

| Field | Value |
|---|---|
| `shock_overlay_state` | `acute` |
| `shock_acute_run_start` | 2026-08-01 |
| `brent_baseline` | 84.73 (43 observations, 2026-06-01 → 2026-07-31) |
| `brent_peak` | **108.75** |
| `brent_current` | **104.82** (`brent_as_of` 2026-09-17) |
| `brent_retrace_trigger` | **96.74** — the midpoint of baseline and peak, (84.73 + 108.75) / 2, reproduced exactly |
| `leg_b_basis` | `not_retraced` |
| `leg_b_price_leg` | **FALSE** |
| `sql_limbs_fired` | **FALSE** |

Brent must fall to 96.74 or below. From 104.82 that is a **−7.71%** move. **The required fall has SHRUNK since last cycle, from −10.6% to −7.71%, and both halves of that move matter and point opposite ways:** the peak ratcheted UP (107.63 → 108.75, so the trigger ratcheted with it, 96.18 → 96.74) because the shock intensified mid-week, while the current print fell back (107.63 → 104.82) off that new high. Last cycle Brent sat exactly *at* its acute-run peak — the maximum possible distance from the trigger. It no longer does. The leg is still FALSE, and it is the nearer of the two legs to clearing.

**LEG 2 — THE QUIET-CLOCK LEG. FAILS for 2026-10-01, and its anchor MOVED this week.**

The leg requires 15 trading days clear of the most recent qualifying shock-cluster member. Last cycle W3 measured that member as **2026-09-11**, putting the fifteenth trading day at 2026-10-02 — one day after the 2026-10-01 scoring.

**This week produced a new qualifying member and I am not carrying last cycle's anchor forward.** MEASURED by D1's 2026-09-15 sector screen (`events.decision_log` `db7dc01c-1280-407c-ac66-5391c6f26666`): the Saudi **East-West pipeline — the Hormuz bypass — was struck and shut, putting up to 4% of global oil supply at risk**, with XLE +2.1695%, Brent +2.9050% and USO +3.3198% on the session. That is a dated, sourced, market-moving energy-supply shock, it is the event that drove `brent_peak` from 107.63 to 108.75, and it resets the quiet clock to **2026-09-15**.

Counted in `state.market_calendar`, the fifteenth trading day after 2026-09-15 is **2026-10-06**. The thirteenth is 2026-10-02. So the clock now runs four calendar days longer than last cycle's reading, and 2026-10-01 sits inside it either way.

**THE DERIVED GATE DATE: 2026-11-02.**

- **2026-10-01 is NOT REACHABLE.** Both legs hold `acute` through it. The quiet-clock leg is arithmetic and admits no argument: 2026-10-01 falls before 2026-10-06 whatever Brent does between now and then. The price leg independently fails today and would need −7.71% in seven trading sessions.
- **2026-11-02 is NOT PROVABLY UNREACHABLE, so it is the gate.** By then the quiet clock will have expired (2026-10-06) provided no new qualifying shock-cluster member lands, and the price leg's state on that date is unknowable today. The mode's test is whether both legs *hold* the overlay acute through a scheduled re-score; for 2026-11-02 that cannot be established, so the step-to-the-following-month rule does not fire.

**The limb's other two legs are both already satisfied, which is what makes the two legs above the whole question.** `leg_a_dwell` is TRUE — A has stood at DO-NOT-ACTIVATE for **103 trading days** since 2026-04-22, though `dwell_left_censored` is TRUE so that figure is a LOWER BOUND, not a measurement (every strategy's history in `events.regime_events` begins on that same date). A lower bound already clears a 15-day floor, so nothing turns on the censoring here. `leg_c_technical` is TRUE as well — VIX_REGIME NORMAL, SPY_TREND **UP**, EQUITY_BREADTH **HEALTHY**, all dated 2026-09-17 against a staleness floor of 2026-09-14. **So A's technical plane currently satisfies A's own router gate (SPY UP and breadth HEALTHY) and A is still closed** — the fundamental overlay is what holds it, and the two legs above are the only things that can move it.

Two qualifications on that technical reading, both measured. **Breadth is marginal, not comfortable: EQUITY_BREADTH_PCT is 51.09%, only 1.09 points above the 50% HEALTHY/WEAK boundary** — a modest deterioration flips the technical half of A's router to WEAK on its own, independently of the overlay. And the SPY_TREND reading is now clean, which resolves an open thread: last cycle a warehouse value of NEUTRAL (2026-09-10) was walked back before publication because the IBKR bar for 09-11 put SPY back above the same 50-day SMA. The warehouse now reads **UP at 762.60 as of 2026-09-17**, so the two sources agree and the three-cycle A-router technical divergence is closed on this input. It changes nothing operationally — A is held by the overlay, not by its technicals.

**Same gate date as last cycle, different arithmetic underneath it — which is the point of re-deriving rather than carrying.** Both legs moved this week and they moved in opposite directions: the price leg came closer to clearing (−10.6% → −7.71%) while the quiet clock got longer (expiry 2026-10-02 → 2026-10-06). Had only the price leg been re-read, the honest conclusion would have looked like progress; had only the clock been re-read, it would have looked like regression. Neither alone is the answer.

**Three things could still falsify this, and none is idle:** an out-of-cycle **M1R** re-score can fire on a limb at any time; the overlay's de-escalation is judged by **M1a under its own rubric**, which owns the axis and is not bound by a reading of two view columns; and a further qualifying shock member between now and 2026-10-06 restarts the clock again — the 09-11 → 09-15 move this week is precisely that happening once already.

### STEP 2 — CLASSIFICATION, AFTER THE DIRECTION RAIL

Across all **57 candidates carried this cycle** — 48 in the main ranking plus the 9 held in the `DIRECTION-INADMISSIBLE` tier — **14 are `SPENT-BY-GATE`** (a dated catalyst strictly before 2026-11-02) and **43 are `GATE-SURVIVING`**. Of the top-10, **8 survive and 2 are spent** — a material change from last cycle, where nine of ten were spent.

**A name carrying BOTH a spent and a surviving catalyst is classified SURVIVING**, which is the fail-open direction the mode requires. Two names are in that position and it changes their treatment: **JPM** (earnings 10-13 spent, Investor Day 2027-02-22 surviving) and **UNH** (earnings 10-13 spent, investor conference ~early Dec surviving). Both get full depth on the surviving catalyst; neither is reduced.

Where a name's date could not be established it is treated as **GATE-SURVIVING and given full depth**, per the mode's fail-open rule. **GEV is the case worth naming:** its Q3 print is absent from this cycle's reachable calendar entirely, and last cycle's "~2026-10-20" was a company-unconfirmed soft estimate. A date that cannot be established cannot prove a name spent, so GEV gets full treatment and is marked `(T)` rather than spent — deliberately the more expensive reading.

**Every `SPENT-BY-GATE` mark in this file expands to `SPENT-BY-GATE (gate 2026-11-02)`.** There is one gate date this cycle and it governs every classification here, so the date is stated once rather than repeated into fourteen table cells. The catalyst date that spent each name is carried in its own row, which is what makes next cycle's promotion mechanical: re-derive the gate, and any name whose recorded catalyst date now falls on or after it is promoted back to full depth without a re-read.

### THE DAILY-TO-WEEKLY BOUNDARY, AND THE ONE SESSION IT DOES NOT COVER

Everything reused above from D1 comes from its 2026-09-13 through 2026-09-17 sessions — five `research-screen` records, cited by entry id where used. Those catalysts were **not** re-researched here; W1 took D1's canonical event date, source and decision-log reference and spent its own budget on the forward calendar instead, as the boundary rule directs.

**The uncovered session is Friday 2026-09-18.** D1's cadence is Sun–Thu, so it does not fire on Friday or Saturday; the Sunday fire absorbs Friday's session, and today's D1 has not yet run — `ops.run_log` holds D1 rows for 09-13 through 09-17 and nothing after, and `Daily.md` is still headed 2026-09-17. **So W1 is running ahead of the D1 that will first cover Friday's tape, and this file therefore carries no Friday 2026-09-18 development.** That is structural rather than a fault of either routine, it recurs every week, and it is already recorded as `ops.alerts` `b4e4e563-c15e-481e-9ee5-b84170cfc045` (`w1_daily_boundary_excludes_friday_session`, info, open, owner W5). Deliberately **not** re-raised. The spec's escape hatch — do a minimum source check when D1 is *genuinely unavailable* — is written for an outage; D1 is not unavailable, it is simply not yet due, so no second news scan was run. One consequence worth naming: the **BOJ decision of 2026-09-17/18** was pending at D1's last run and its resolution is not on record anywhere in the fleet yet.

### STEP 3 — THE DIRECTION ADMISSIBILITY RAIL, RUN FIRST

Strategy A is **long-only** — `strategy/03_strategy_a.md`: "Long-only (no short positions in A — short is B's territory)." Every candidate's hypothesised direction was evaluated before ranking. **Nine candidates are over-valued/bearish and are marked `DIRECTION-INADMISSIBLE (A long-only rail)`**; they are ranked and carried below the actionable tier, never suppressed, because they are genuine evidence for the divergence record and belong to Strategy B. One further name (TGT) has an unresolved direction and is likewise held below the actionable tier.

**And for the second cycle running the strongest new thesis in this file is inadmissible to A.** The 2026-09-15 pipeline strike lands on an airline hedge book that was set before the shock, and DAL, UAL and AAL all report inside the window. That thesis got stronger this week, not weaker — and it cannot produce a Strategy A entry at any conviction. It is ranked, carried, and routed to B's territory, where the router is also DO-NOT-ACTIVATE. Saying so is the point: the rail is working, and what it costs is visible.

### THE A-QUEUE CENSUS — PINNED QUERY, NOT RE-DERIVED

```sql
SELECT * FROM state.open_queue WHERE strategy = 'A'
```

**Returns 44 rows.** That figure is the census, verbatim from the query. All 44 carry `queue = WATCHLIST`, `item_type = 'Strategy A queue'`, `status = 'pending'`. Enumerated: AAPL, ADBE, AKAM, AMAT, AMD, AMZN, AVGO, CAT, CRM, CRWD, CSCO, CVX, DDOG, DELL, FSLR, GEV, GOOGL, HD, HPE, IBM, INTC, INTU, JPM, LLY, META, MRK, MRVL, MSFT, MU, NBIS, NOW, NTAP, NVDA, OKTA, ORCL, PANW, QCOM, SMCI, SNOW, TGT, TTWO, VRTX, WMT, XOM — 44 tickers, reconciling exactly to the count. `Watchlist.md` carries 45 rows; the one-name gap is **TSM**, an ADR correctly absent from the live queue and deliberately retained in the file. The discrepancy is stated rather than reconciled away, and the query wins.

**All ten of this cycle's top-10 are ALREADY on that queue, so W4 has zero new A intake to make this week.** Last cycle took in four (XOM, CVX, JPM, MRK) — the largest single-cycle intake since July.

### TOP-10 — the actionable tier (all long-direction, all rail-checked)

Ordered by conviction-strength of the narrative misalignment. Gate status is shown per name and, where conviction was genuinely comparable between two names, the gate-surviving one was preferred — stated so the ordering is auditable rather than asserted.

| # | Ticker | Direction | Catalyst date | Gate status | Queued | Thesis, and the public documents behind it |
|---|---|---|---|---|---|---|
| 1 | **MU** | Bullish | FQ1 print, date **not established** (T) | **GATE-SURVIVING** | 2026-05-09 | The cleanest quantified misalignment in the file. MEASURED 2026-09-17 (D1 single-name screen `a913941a`): MU +5.4994% on a forecast of DRAM contract prices **+>50% this quarter** and NAND **~+60%**. This is a pricing shock in MU's core revenue line, of a size consensus revision cycles have historically lagged. MU has been queued since May on a cohort/CXMT thesis that repeatedly failed to resolve; this is the first MU-specific, quantified, non-cohort ratification it has had. Supporting documents: last four quarters of FQ transcripts and the most recent 10-Q pricing/mix commentary. |
| 2 | **NVDA** | Bullish | Earnings **2026-11-18** (E); GTC DC 11-30 → 12-03 (E) | **GATE-SURVIVING** | 2026-05-09 | A dated catalyst that survives the gate, which is rare in this file. Same memory/AI re-rating: XLK +2.2449% on 2026-09-17, second consecutive session. The live objection is carried and still unresolved — the circular-financing critique (2026-07-27) — and it is the reason this is #2 and not #1. Documents: FQ2 10-Q, the last four transcripts, GTC keynote materials. |
| 3 | **XOM** | Bullish | Earnings **2026-10-30** (E) | **SPENT-BY-GATE (gate 2026-11-02)** | 2026-09-13 | The supply-shock seam, and it INTENSIFIED this week: the 2026-09-15 East-West pipeline strike put up to 4% of global supply at risk, XLE +2.1695%, Brent to a new acute-run high of 108.75. The original seam — Brent +11.79% over four sessions while XLE fell on the session Brent rose 6.34% — was re-measured by D2 on 2026-09-16 and found EXACT, and the gap **widened** rather than closed. Tape is pricing demand destruction; 10-Q upstream arithmetic is not. Reduced depth per the mode: direction, date, overlap and tier given; first-party document chase declined. |
| 4 | **VRTX** | Bullish | Povetacicept PDUFA **2026-11-30** (C); Journavx CLBP sNDA PDUFA **2026-12-05** (2S) | **GATE-SURVIVING** | 2026-07-05 | Two dated regulatory catalysts, both past the gate, the first first-party confirmed. Two independent shots inside five days is an unusually favourable catalyst structure for a long-only book that cannot act before November. Documents: the BLA/sNDA submission announcements and the most recent 10-Q pipeline disclosure. |
| 5 | **TTWO** | Bullish | GTA VI launch **2026-11-19** (C); preload 11-12 | **GATE-SURVIVING** | 2026-08-09 | The largest dated non-earnings binary in the calendar, and the date has now survived two consecutive re-confirmations against both Rockstar and Take-Two IR after a history of slippage. Post-gate by 17 days. |
| 6 | **FSLR** | Bullish | Section 232 regime **effective 2026-12-04** (C, whitehouse.gov) | **GATE-SURVIVING** | 2026-09-06 | The rarest shape in the file: a fully specified, quantified, primary-sourced, dated policy catalyst — minimum import prices at polysilicon $21/kg, ingots-wafers $100/kg, cells $0.22/W, modules $0.38/W. Nothing about it depends on an estimate, and it lands a month past the gate. |
| 7 | **CVX** | Bullish | Earnings **2026-10-30** (E) | **SPENT-BY-GATE (gate 2026-11-02)** | 2026-09-13 | The second independent instance of the XOM seam, with higher post-Hess upstream leverage. Carried at #7 rather than beside XOM because the pair is correlated and is one concentration decision, not two — a caveat already on the queue row. Reduced depth per the mode. |
| 8 | **CSCO** | Bullish | Earnings **2026-11-11** (E) | **GATE-SURVIVING** | 2026-05-09 | Dated, surviving, and riding the same AI-infrastructure order cycle the memory complex is repricing. Elevated valuation-reset concern is carried from the post-print +12.96% session and is the live objection. |
| 9 | **AMD** | Bullish (contested) | Earnings **2026-11-03** (E) | **GATE-SURVIVING** | 2026-05-29 | Dated and surviving by one day past the gate. Contested rather than clean: the loss of the exclusive SpaceX AI-compute socket to NVDA (2026-08-05) is direct counter-evidence to the competitive-position premise, and it is not netted away by the Q2 beat. Ranked on the strength of the MI-series ramp and the same compute-demand repricing, with the objection stated. |
| 10 | **GEV** | Bullish | Q3 print, date **not established** (T) | **GATE-SURVIVING (fail-open)** | 2026-08-09 | Orders +88% to $24.2B and backlog $176B including 116GW of gas-power reservations; the energy shock raises the option value of gas-turbine and grid capex specifically. The live objection is fresh and adverse: **GLJ Research initiated Sell at $470 on 2026-09-14, −8.6189%**. Survives only because its date could not be established — the fail-open reading, chosen deliberately. **Open Strategy D lot: `D:GEV:2026-08-03`.** A↔D is coordination at monthly review, not automatic exclusion, but D2 must see the overlap before any conversion. |

**Why XOM and CVX stay in the actionable tier although they are spent.** Their conviction genuinely is top-tier and it rose this week on a measured, dated, primary-sourced supply event; demoting them for gate status alone would be inventing a rail this spec does not carry. What the mode *does* require is that their research depth be cut, and it was: neither got a first-party document chase this cycle. The honest summary is that both are strong theses whose current catalyst will be spent before A can act, and whose next catalyst (the Q4 print, ~late January) is beyond the reachable horizon.

**The demotions this cycle, and the evidence behind each.**

- **JPM falls from #5 to #22.** The NIM-supportive-hike thesis took two independent adverse tape readings in four days: **XLF −1.6183% on the hike session (2026-09-16), the second-worst sector**, and banks failing to join the rally on **two consecutive sessions** (09-16 and 09-17, D1 sector screens `24e31709` and `3b6ab6b2`). A hike from 3.50–3.75% to 3.75–4.00% with a +0.39 curve is still arithmetically NIM-supportive for an asset-sensitive book; what changed is that the market has now had two clean chances to price that and declined both. Its 10-13 print is spent; its surviving catalyst is an Investor Day five months out, which is a weak near-term resolver.
- **MRK falls from #10 to #21.** Both its catalysts — the 10-04 and 10-10 PDUFAs — are spent, and it has no surviving one. Last cycle called it the tightest spent-by-gate case; a cycle later it is simply spent.
- **GOOGL falls from #6 to #20.** All three of its dated catalysts are spent (earnings 10-28, ad-tech Final Judgment 10-02, search-remedies reply brief 09-29), and it carries two open D lots.
- **INTU falls to #42 and now carries no forward dated catalyst at all.** Its Investor Day (2026-09-17) was the nearest dated catalyst on the entire A queue for two cycles and has now passed.

### 11–20

| # | Ticker | Direction | Catalyst | Gate status | Note |
|---|---|---|---|---|---|
| 11 | ORCL | Bullish | FQ2 print (T) | GATE-SURVIVING | −13.7912% on 2026-09-14 on AI-capex repricing; D1 flags the driver **PARTLY UNRESOLVED** (the 09-10 print beat, but same-day headlines cite weak guidance off a stale close). Oracle AI World 10-25 → 10-28 is spent. Queued 2026-05-09. |
| 12 | CAT | Bullish | (T) | GATE-SURVIVING | Data-centre power capex plus energy-capex pull-through; thesis ratified 2026-08-04. No dated catalyst either way. Queued 2026-05-01. |
| 13 | MSFT | Bullish | Ignite 11-17 → 11-20 (C) | GATE-SURVIVING | Earnings 10-28 is spent; Ignite survives and is the operative catalyst. Queued 2026-07-05. |
| 14 | AMZN | Bullish | re:Invent 11-30 → 12-04 (C) | GATE-SURVIVING | Earnings 10-29 spent; re:Invent survives. Two open D lots. Queued 2026-07-12. |
| 15 | UBER | Bullish | Earnings 2026-11-03 (E) | GATE-SURVIVING | The 2026-09-02 restructuring (~3,300 roles, ~10% of headcount) is a dated structural action whose margin effect first appears in this print. **Not on the A queue.** Open D lot `D:UBER:2026-07-09`, itself carrying `breach_status = NOT_ASSESSED_BY_THIS_BACKFILL`. |
| 16 | MRNA | Bullish | Earnings 2026-11-05 (E) | GATE-SURVIVING | +8.5495% on 2026-09-17 on Phase 3 progress for the intismeran cancer vaccine (Morgan Stanley Global Healthcare Conference). Not on the A queue; routed to B's index this week. |
| 17 | DIS | Bullish | Earnings 2026-11-12 (E) | GATE-SURVIVING | Not queued. Two open D lots in the name. |
| 18 | SHOP | Bullish | Earnings 2026-11-03 (E) | GATE-SURVIVING | Not queued. |
| 19 | PLTR | Bullish | Earnings 2026-11-02 (E) | GATE-SURVIVING | Lands **on** the gate date, not before it — surviving by the rule's "strictly before" wording, by a single day. Not queued. |
| 20 | GOOGL | Bullish | Earnings 10-28 (E); Final Judgment 10-02 (C); reply brief 09-29 (C) | **SPENT-BY-GATE** | All three catalysts spent. Brinkema's ruling avoided a breakup and the residual legal tail is now quantifiable, which is why the thesis survives even though its catalysts do not. Two open D lots. Queued 2026-07-05. |

### 21–30

| # | Ticker | Catalyst | Gate status | Note |
|---|---|---|---|---|
| 21 | MRK | PDUFAs 10-04, 10-10 (C) | **SPENT-BY-GATE** | Two first-party catalysts, both spent, none surviving. Queued 2026-09-13. |
| 22 | JPM | Earnings 10-13 (E); Investor Day 2027-02-22 (C) | **SPENT** (earnings) / surviving (Investor Day) | See the demotion note above. Queued 2026-09-13. |
| 23 | INTC | Earnings 10-22 (E) | **SPENT-BY-GATE** | +7.6695% on 2026-09-17 on analyst target hikes plus **reported** SK Hynix production talks — a report, not a company announcement, and the caveat is carried. Queued 2026-05-12. |
| 24 | AVGO | (T) | GATE-SURVIVING | The BofA ~$370B AI-debt-vehicle note (2026-08-14, −5.94%) is the third instance of the AI-funding objection class and remains the live counter-evidence. Queued 2026-05-09. |
| 25 | MRVL | (T) | GATE-SURVIVING | Custom-silicon ramp; record FQ1 and accelerating guide. Queued 2026-05-25. |
| 26 | QCOM | (T) | GATE-SURVIVING | Stellantis Snapdragon Digital Chassis expansion ratifies the multi-year auto-AI narrative. Queued 2026-05-01. |
| 27 | DELL | (T) | GATE-SURVIVING | +11.9776% on 2026-09-10 on AI-capex read-through; D1 judged the anomaly larger per unit of market cap than HPE's. Routed to B's index this week. Queued 2026-05-17. |
| 28 | HPE | (T) | GATE-SURVIVING | +12.4411% on 2026-09-10, same read-through. Queued 2026-05-29. |
| 29 | SNOW | (T) | GATE-SURVIVING | Cortex AI monetisation materially ratified (FQ1 +33% after hours, $6B AWS commitment). Queued 2026-05-25. |
| 30 | CRM | (T) | GATE-SURVIVING | Dreamforce (09-15 → 09-17) now spent; FQ3 print is the surviving catalyst and is undated in the reachable calendar. Queued 2026-05-17. |

### 31–40 — queue-carried names with unreachable-tail catalyst dates

All `(T)`, all therefore **GATE-SURVIVING** by the fail-open rule, all ranked on **carried thesis strength rather than catalyst proximity** — this is the ranking distortion 1A.3 names, made visible rather than smoothed over.

31 NOW · 32 CRWD · 33 PANW · 34 NBIS · 35 SMCI · 36 IBM · 37 OKTA · 38 DDOG · 39 NTAP · 40 LLY

(LLY carries a terminal Strategy D **NO-GO** dated 2026-09-14 on its D re-screen; that is a D-activation verdict and, per the NO-GO-records-are-context rule, it informs but does not pre-empt an A evaluation. Its next D re-screen is queued for 2026-12-14.)

### 41–48

| # | Ticker | Catalyst | Gate status | Note |
|---|---|---|---|---|
| 41 | AAPL | Earnings 10-29 (E) | **SPENT-BY-GATE** | The China Renaissance downgrade (2026-08-04) remains the first sell-side adverse datapoint against the capex-discipline-contrast framing. Queued 2026-05-02. |
| 42 | INTU | none forward (T) | GATE-SURVIVING (vacuously) | Investor Day 2026-09-17 has passed; **no forward dated catalyst remains**. Queued 2026-08-03. |
| 43 | META | Earnings 10-28 (E); Meta Connect 09-23 → 09-24 (C) | **SPENT-BY-GATE** (both) | Connect falls inside the window but before the gate. Queued 2026-08-03. |
| 44 | TGT | Earnings 2026-11-18 (E) | GATE-SURVIVING | **DIRECTION UNRESOLVED** — the beat-and-raise refuted the bearish thesis and no replacement direction has been established. Held below the actionable tier for that reason, not for rank. Queued 2026-05-09. |
| 45 | UNH | Earnings 10-13 (E); investor conference ~early Dec (E) | **SPENT** (earnings) / surviving (conference) | Its earnings date moved two weeks earlier this week (10-27 → 10-13), which is what spent it. XLV weakness is the entry seam. Not queued. |
| 46 | GE | Earnings 10-20 (E) | **SPENT-BY-GATE** | Aerospace plus power capex. Not queued. |
| 47 | BAC | Earnings 10-13 (E) | **SPENT-BY-GATE** | Ranked below JPM on balance-sheet mix and hit by the same two sessions of bank non-participation. Not queued. |
| 48 | V | Earnings 10-27 (E); DOJ fact discovery closes 10-16 (C) | **SPENT-BY-GATE** (both) | Not queued. |

### DIRECTION-INADMISSIBLE tier — ranked, carried, NOT discarded

`DIRECTION-INADMISSIBLE (A long-only rail)`. These are real theses and several are the strongest in the file; they are ineligible for the actionable tier at any conviction, and they belong to Strategy B.

| Ticker | Direction | Catalyst | Gate status | Why it is real |
|---|---|---|---|---|
| **DAL** | Bearish | Earnings 2026-10-09 (E) | SPENT-BY-GATE | The 2026-09-15 pipeline strike lands on a hedge book set before the shock. Strongest new thesis in the file for the second cycle running, and inadmissible for the second cycle running. |
| **UAL** | Bearish | Earnings 2026-10-21 (E) | SPENT-BY-GATE | Same shock, independent print. |
| **AAL** | Bearish | Earnings 2026-10-22 (E) | SPENT-BY-GATE | Same shock, thinnest balance sheet; consensus already models a loss. |
| **CCL** | Bearish | Earnings **2026-09-29** (E) | SPENT-BY-GATE | Bunker-fuel channel of the same shock. Its date moved almost a week earlier this cycle (10-05 → 09-29), making it the **first fuel-exposed name to report**. |
| AMAT | Bearish | (T) | GATE-SURVIVING | China WFE cliff; re-affirmed. The 2026-08-17 +5.55% remains the first ratification-shaped reaction against it and the framing-flip stays deferred. |
| WMT | Bearish | Earnings 2026-11-19 (E) | GATE-SURVIVING | Two adverse datapoints against the original bullish tariff-pass-through framing (soft Q2 guide; Oppenheimer PT withdrawn 2026-08-04). |
| ADBE | Bearish — vindicated on tape | Earnings 2026-12-09 (E) | GATE-SURVIVING | Sits exactly on the earnings horizon. A confirmed-correct short thesis is still a short thesis. |
| HD | Bearish / neutral | (T) | GATE-SURVIVING | Housing-turnover starvation; carried. |
| AKAM | Bearish / contested | (T) | GATE-SURVIVING | Carried. |

### Rails — what was measured for this shortlist

- **30-day ADV, MEASURED off IBKR daily bars:** see the run note for the per-name result and the lowest measured figure. Every shortlisted name that could be measured is tested against the $10M floor; any name that could not be measured is reported UNMEASURED rather than assumed to pass.
- **Market cap:** MEASURED for shortlisted names present in the 77-symbol calendar set; **CAP-UNVERIFIED** for queue-only names, per the universe-rails section above. A `CAP-UNVERIFIED` name has not been shown to fail the $2B rail — it has not been shown to pass it either, and D2 owes that check at thesis-construction time.
- **Counts, reconciled:** **57 candidates carried in total** — 48 in the main ranking (47 direction-admissible long, plus TGT at #44 whose direction is UNRESOLVED) and **9** in the `DIRECTION-INADMISSIBLE` tier. By gate status: **43 `GATE-SURVIVING`, 14 `SPENT-BY-GATE`** (the 14 being XOM, CVX, GOOGL, MRK, INTC, AAPL, META, GE, BAC, V from the main ranking, and DAL, UAL, AAL, CCL from the inadmissible tier). Actionable tier: 10, of which 8 survive the gate.

---

## PART 2C — Strategy C preliminary shortlist (15 event candidates, ranked)

### The two constraints, and the fact that they select disjoint sets

- **ROUTING.** C reads **`HYBRID ACTIVATE (FOMC-only)`** (`state.current_regime`, `div-C-202608-1`, `as_of_date` 2026-09-03, theater-check MIXED) and is the **only capital-enabled strategy on the roster**. The one router-eligible event in the 45-day window is the **2026-10-28 FOMC**. Every earnings name below is router-parked; every PDUFA likewise.
- **SIZE.** C's NAV is **$23.64** — MEASURED, `state.strategy_nomadic_status` and `analytics.strategy_nav` agreeing (idle $23.64, deployed $0.00, open positions 0). Against a 100× contract multiplier that is a per-thesis risk budget of **$0.2364 per share**, which admits only long-premium structures and only very cheap ones. Sizing carries no numeric ceiling (owner directive 2026-08-05); the binding constraint is the budget itself, not a rule.
- **AND THAT IS THE WHOLE MECHANISM.** Exactly two names in a 19-name measured panel have implied vol *below* realized — the side a debit structure wants — and **both are earnings, which the router forbids**. The one event the router permits is priced *rich*, where the edge favours selling premium that $23.64 cannot collateralise. The affordability constraint and the routing constraint select disjoint sets. Re-measured this cycle on a different event from last cycle's, and it reproduced.

**Commissions are absent from every judgement in this section, per the standing commission policy.**

**(e) OVERLAP WITH OPEN A POSITIONS: NONE, for any candidate.** `state.current_positions` holds 12 open rows and **all 12 are Strategy D**; A holds nothing and its NAV is $0.00. The A↔C simultaneous-holding prohibition therefore binds on no name this cycle. Stated once here rather than repeated per row.

**How IV was measured, because the obvious field is broken.** IBKR's `option_midpoint_iv` returned a fixed invalid sentinel (`isValid: false`, ≈ −15.8745) on **every** contract tried — the defect at `ops.alerts` `d06c5299`, re-confirmed, not intermittent. Every IV below is read instead from the **`implied_vol`** field with its own `is_valid` flag checked per quote; that field returns strike-varying, sane values and flags genuinely unquotable strikes with −1.0, which a one-strike retry clears. **Eight quotes were discarded on the invalid rule and none was averaged in.** Realized vol is close-to-close, annualised, sample stdev × √252.

### TOP-5

| # | Event | Date | (a) Hypothesised divergence | IV | HV20 | IV/HV20 | (d) Executable at $23.64? | Router |
|---|---|---|---|---|---|---|---|---|
| **1** | **FOMC** | **2026-10-28** | **NO directional view established.** The measurable divergence is on VOLATILITY and it runs the wrong way for an affordable structure: SPY ATM `implied_vol` **12.84%** (valid, call and put identical at strike 763, spot $762.98) against **HV20 9.157%**, HV10 9.785%, HV30 8.743% over 35 closes (2026-07-31 → 2026-09-18). Implied sits ~3.1–3.7 vol points above realized. ATM straddle $26.96, an implied move of **3.53%**. | 12.84% | 9.16% | **1.40** (IV/HV10 1.31) | **TENOR RAIL NOW CLEAR** — the 2026-10-30 weekly is listed and is the nearest expiry after the event and inside the 45-day edge (expiries jump 10-23 → **10-30** → 11-20), so entry today is 40 days out against a 1–45 rail, the event precedes expiry, and entry is far more than one trading day ahead. **The tenor blocker from last cycle has cleared.** What has not: a $0.2364/share budget admits only far-OTM or very narrow debit structures, and implied at 1.40× realized means every one of them pays above realized. | **ELIGIBLE** |
| 2 | PYPL earnings | 2026-10-27 (E) | Implied materially **CHEAPER** than realized — the long-premium-favourable side, and the cheapest in the panel. | 41.21% | 57.17% | **0.72** | Affordable in principle. | parked |
| 3 | F earnings | 2026-10-22 (E) | Implied slightly cheaper than realized; the only other sub-1.0 name. | 33.56% | 35.81% | **0.94** | Affordable in principle. | parked |
| 4 | NKE earnings | 2026-10-01 (E) | **Richest premium in the panel.** A credit structure is what the measurement indicates. | 57.08% | 26.52% | 2.15 | **NO** — a credit structure's max loss cannot be collateralised at $23.64. | parked |
| 5 | CCL earnings | **2026-09-29** (E) | Rich premium, and the one name here with a genuine independent directional thesis: the 2026-09-15 pipeline strike hits bunker fuel, and CCL's date moved a week earlier this cycle making it the **first fuel-exposed name to report**. The thesis is bearish; the premium is rich; expressing it would mean selling. | 53.66% | 25.63% | 2.09 | **NO** — same reason as NKE. | parked |

**The honest reading of row 1.** The October FOMC is now enterable on structure for the first time — that is real progress and it is the blocker that failed last cycle. Criterion 2 is where it stands or falls, and on today's measurement there is no affirmative, sourced, quantified divergence to establish: implied is rich to realized, which is an edge for the side C cannot afford. That is a shortlist observation, not a verdict — the thesis is already queued as `thesis-FOMC-C-20261020`, due 2026-10-20, and **D2 owns the GO/NO-GO**, on its own measurement five weeks nearer the event.

### REST (6–15), by IV/HV20 descending — all router-parked

| # | Ticker | Event date (E) | ATM IV | HV20 | IV/HV20 |
|---|---|---|---|---|---|
| 6 | AAL | 2026-10-22 | 47.32% | 25.37% | 1.87 |
| 7 | DAL | 2026-10-09 | 44.25% | 24.90% | 1.78 |
| 8 | JPM | 2026-10-13 | 24.52% | 13.86% | 1.77 |
| 9 | COST | 2026-09-24 | 31.23% | 18.74% | 1.67 |
| 10 | GOOGL | 2026-10-28 | 35.09% | 23.19% | 1.51 |
| 11 | UAL | 2026-10-21 | 48.75% | 33.56% | 1.45 |
| 12 | MSFT | 2026-10-28 | 31.04% | 21.97% | 1.41 |
| 13 | BA | 2026-10-28 | 32.10% | 23.20% | 1.38 |
| 14 | GM | 2026-10-20 | 38.69% | 32.31% | 1.20 |
| 15 | V | 2026-10-27 | 22.51% | 18.96% | 1.19 |

**Measured but not promoted** (all ≥ 1.0, all router-parked): INTC 1.14 (68.64% / 60.29%), VZ 1.09, T 1.08, BAC 1.06 (at the 57.5 strike after 58 returned −1.0), UNH 1.05.

**AMD (earnings 2026-11-03) — STRUCTURALLY INELIGIBLE, and it is the tenor rail that excludes it, not a data problem.** AMD's listed expiries jump straight from **2026-10-30 to 2026-11-20**; there is no listed expiry between its earnings date and the 45-day edge of 2026-11-04. No contract exists that satisfies "qualifying event scheduled strictly before expiration" *and* "expiration within 1–45 days", so both ATM legs were never attempted rather than attempted and discarded. Reported as excluded on the rule rather than substituted with the 11-20 expiry, which would breach the tenor rail.

**The cheap-premium edge is narrowing.** PYPL and F were the only two sub-1.0 names last cycle as well, at **0.68 and 0.83**; they are now **0.72 and 0.94**. Two cycles, same two names, both moving toward parity — so the router-forbidden side is not merely unreachable, it is becoming less worth reaching.

**PDUFA candidates from 1B.3 are carried unranked and unmeasured.** MIRM 09-26, BFRI 09-28, SRRK 09-30, BMY 09-30, MRK 10-04, MRK 10-10, VTRS 10-17, PHAR 10-24, INO 10-30 — no IV was measured for any of them. They are router-parked regardless of what an options chain would show, and several are micro-caps whose chains are unlikely to support a defined-risk structure at all. Spending the measurement on them would have bought nothing this cycle; stated rather than passed over silently.

### Deferrals, flagged as the spec requires

Every candidate except the FOMC is **deferred on routing** — not on thesis quality and not on size. Per Strategy C's own rule a deferred thesis is not logged as a missed opportunity, and C's uncommitted capital stays parked. The FOMC is **not** deferred: it is queued, structurally enterable for the first time, and awaiting D2's criterion-2 determination on 2026-10-20.

---

## Chat/handoff summary

Written in full to this file. W4 reads PART 2A's top-10 and PART 2C's top-5 verbatim; the A router is DO-NOT-ACTIVATE, so W4's section D routes the A top-10 to the `Watchlist.md` A-queue rather than enqueuing thesis-construction — and **all ten are already queued, so the intake is zero this week**. The nine `DIRECTION-INADMISSIBLE` names must not be converted to Strategy A rows under any circumstance.

2026-W34

# Weekly Catalyst Calendar — Strategies A and C

Run date **2026-08-23** (Sunday, the `weekly_sun` slot; session opened 01:48 MT). Windows measured from the run date: **Strategy A = 6 months (2026-08-23 → 2027-02-23); Strategy C = 45 days (2026-08-23 → 2026-10-07).**

**Marker.** `2026-W34` is the ISO week of this run date, and it is also what `scripts/check_cadence_marker.py` requires: that check anchors the expected marker on the **commit** time in `America/Denver` (`write_dt()` → `expected_marker()`), and this run's run date and commit date are both inside `2026-W34`. **The marker string is unchanged from the prior cycle's file, and that is correct rather than stale.** The 2026-08-16 run had run-date ISO week `2026-W33` but did not commit until 00:01 MT Monday 2026-08-17, so the commit-anchored check required `2026-W34` and it stamped that (its own header records the reasoning). Two consecutive W1 files therefore carry the same marker for two different, individually correct reasons. **A marker-equality freshness test would read "unchanged" against a fully rewritten file** — which is exactly why `Claude_Task_Plan.md` demotes the marker to a corroborating signal and makes the period-aware `ops.run_log` read the primary one. W4's gate calls `sp_assert_deps`, which sees this run's own `completed` row inside the current `weekly_sun` period, so it is unaffected.

**Catch-up window.** `state.routine_catchup_window` for W1: `window_start_ts` 2026-08-17T05:22Z, `never_completed = false`, `window_days = 6.07` — below the weekly 1.5× threshold (10.5 days), so **no `CATCHUP[]` token is owed** and no missed-period sub-section is needed. Evidence window: **2026-08-16 → 2026-08-23**.

> ### THE FOUR THINGS IN THIS FILE A READER SHOULD NOT MISS
>
> 1. **Strategy A's technical gate is already open; only the fundamental override holds it shut, and that override is re-scored in nine days.** Almost every top-ranked name from the prior cycle has its catalyst **spent** before A could possibly act. PART 2A is now ranked with an explicit REACH marker, and the tiering breaks toward catalysts that survive to October–February.
> 2. **The FOMC-dated expiry has now been measured, closing the prior cycle's own decisive open question.** SPY's **2026-09-18** series — the first expiring strictly after the 09-16 decision — reads **IV 12.1% vs HV 12.5%, ratio 0.97**. The prior cycle measured only *index-level* vol and flagged, as counter (c), that "index vol is cheap" and "the September FOMC expiry is cheap" are different claims and the second was not demonstrated. It is now measured. It is **not** thereby proven cheap against its own history — see PART 2B for exactly what this does and does not establish.
> 3. **This file's "6-month" earnings coverage has never actually reached six months, and this is the first cycle to say so.** The data source stops dead at 2026-11-24. The Jan–Feb 2027 FY-report cluster is absent because nothing reached it, not because it was checked and found empty.
> 4. **Two dated events in the prior file are corrected out, and two tickers on this file's own tables cannot carry a trade.** FedEx's 09-17 print is a fiscal-year-change artifact; Amazon's FTC trial has moved outside the window. NUVL and now DCPH are catalysts attached to underlyings that no longer trade independently.

---

## Regime and routing state (measured this run)

Read from `state.current_regime`, `events.regime_events` and `analytics.strategy_nav` at 01:48 MT.

**Regime — M1a scoring as_of 2026-08-01, integrative call "stagflationary shock + hawkish policy":** `growth_momentum` **decelerating** · `inflation_trend` **stable** · `policy_stance` **hawkish** · `risk_sentiment` **neutral** · `shock_overlay` **acute**.

**Technical signals — D2a 2026-08-20, the last session the fleet scored:** `SPY_TREND` **UP** (762.60 > 50d 750.94 > 200d 707.13) · `EQUITY_BREADTH` **HEALTHY** (70.31%) · `VIX_REGIME` **NORMAL** (16.01) · `SUSTAINED_INVERSION` **NOT-SUSTAINED** (10Y−2Y +0.50).

| Strategy | Router state | Source | Capital (measured) |
|---|---|---|---|
| **A** | **DO-NOT-ACTIVATE** — blocks NEW A entries only | `div-A-202607-1` resolved 2026-08-05; re-affirmed by D2's declined out-of-cycle review 2026-08-13 | **NAV $0.00, available $0.00** — capital-disabled |
| **C** | **HYBRID ACTIVATE (FOMC-only)** | `div-C-202607-1` resolved 2026-08-05 | NAV **$23.68**, available **$23.68**; NOMADIC |

### The finding that shapes both shortlists: A's technical gate is open, and the only thing holding A shut is re-scored on 2026-09-01

Strategy A's router condition is **SPY Trend = UP AND Equity Breadth = HEALTHY**. **Both legs read TRUE right now**, and have for weeks. A sits at DO-NOT-ACTIVATE **entirely because of the `Strategy.md:123` reconciliation override** — `growth_momentum = decelerating` AND `policy_stance = hawkish` forces a raw ACTIVATE back to DNA — which is what `div-A-202607-1` meant in calling the DNA "architecturally over-determined."

Both override preconditions are axes **M1a re-scores on the first of each month**. **M1a fires 2026-09-01 11:00 UTC, M1b 12:00 UTC** (`ops/cadence.yaml`). A call that diverges from the technical read routes through an AR_att/AR_orc divergence review before it binds, which for the 2026-08 cycle took four days. **Earliest realistic A activation is ~2026-09-01 to ~2026-09-05.**

**This is not a prediction that A will activate.** The inflation axis sits mid-band and M1a's own July text warns the energy-led disinflation driver already reversed — which argues for hawkish *persisting*. It is a statement about what a shortlist ranked purely on conviction would do to itself:

> **Strategy A enters BEFORE a catalyst. Nine of the prior cycle's top twenty — six of its top ten — have their catalyst spent inside the window during which A cannot act.**

Spent before ~2026-09-05: **NVDA, CRM, CRWD, OKTA (08-26) · MRVL and the TTWO trailer (08-27) · PANW, DELL, AAPL's CEO transition (09-01) · AVGO, SNOW, HPE, NTAP (09-02)**. Ranking those highest again would produce a shortlist whose best ideas are unreachable by construction.

**And the router is only the first of two gates.** A is **capital-disabled at NAV $0.00**. A router flip on 09-01 still leaves A with no capital until a regime-capital sweep allocates some — the mechanism that on 2026-08-18 swept B's $47.35 to C and E. **Both gates must lift; only one is on a scheduled clock.**

**What this file does about it.** PART 2A stays ranked on conviction, but every row carries **REACHABLE / SPENT / SPENT→NEXT** against the ~09-05 date, and reachability breaks ties where conviction is close. **A spent catalyst does not demote the name** — it keeps its narrative standing and its `Watchlist.md` row, and its next in-window catalyst is named where one exists. What changes is that W4 and D2 can see, without re-deriving it, which rows could become orders in this router epoch and which are queued against the next one.

## Past-window tape (2026-08-16 → 2026-08-23)

**The fleet did not run for two of these days.** `ops.run_log` holds **zero rows of any status for every routine on 2026-08-21 (a Friday trading day) and 2026-08-22**; 13 routines ran on 08-20, none on 08-21/08-22, and this W1 run is the first since. No `missed_run` alert was raised for either date. That is OPS0's scope, not W1's — it is recorded this run as a latching `cadence_outage` warning plus a `PENDING_REVIEW` queue row naming OPS0, and W1 refired nothing.

**What it cost this file: almost nothing, and that is measured rather than assumed.** A bounded gap-check over 2026-08-20 → 2026-08-23 found exactly **one** newly-disclosed dated catalyst for a ≥$2B name — a Boeing 8-K Item 5.02 Controller succession (Ryan Shedd succeeds Michael Cleary upon the 2026 10-K filing), which is not thesis-moving. All six catalyst categories otherwise returned nothing datable to the window. **2026-08-21 was a normal full session**: SPY **762.60 → 765.72 (+0.41%)**, RSP **220.28 → 221.67 (+0.63%)** — equal-weight outperforming, i.e. a broad-participation up day, with Dow +0.98%, Nasdaq +0.43%, Russell 2000 +0.68%.

**The AI-financing objection class produced no new instance this week.** It had produced one in each of the four prior weeks — NVDA (circular financing, 07-27), DDOG (customer concentration, 08-06), AVGO (the ~$370B debt-vehicle note, 08-14), with CRWV standing as the structural case. **One week of absence is not a resolution**, and it is recorded here as an absence rather than as evidence the objection has passed. The standing instruction on those four rows is unchanged: a thesis must answer the financing objection on its own terms, and "the drawdown improved the entry price" answers a different question.

---

## PART 1A — Strategy A universe catalyst calendar (6-month window, 2026-08-23 → 2027-02-23)

Universe rails per `strategy/03_strategy_a.md`: US-listed, market cap **≥ $2B**, 30-day ADV **≥ $10M**. ADRs appear as context and are marked; they are **not A-eligible** per W4's 2026-08-09 ruling.

**The ADV rail was verified by measurement this cycle, not assumed.** 30-day average dollar volume (mean of close × raw share volume over 30 daily bars, IBKR) for every name reaching PART 2A ranges from **$200.4M (OKTA)** to **$23,492.8M (MU)**. **Every shortlisted name clears the $10M floor by at least 20×.** The volume convention was settled by sanity check rather than assumption: NVDA's raw-share computation gives $14.3B/day, consistent with a mega-cap; a lots-of-100 reading would imply ~$1.4T/day, which is absurd.

> ### COVERAGE STATEMENT — read before using 1A.1. The prior cycles did not carry one, and the gap it describes is real.
>
> **This table's earnings coverage effectively ends 2026-11-24, not 2027-02-23.** FMP's `earnings-calendar` returns **zero rows for any date after 2026-11-24** on this plan tier — verified by five separate probes (December in full, Dec 1–15, January, Feb 1–23, and a Nov 25–Dec 5 boundary check, all empty) — and `earnings-company` returns **ACCESS DENIED for all 47 tickers tested**. `quote`, `news`, `secFilings` and `search` are likewise plan-gated. **FMP is unusable end-to-end for this routine's forward earnings calendar**; every date below came from company IR pages, SEC filings, or web/Tavily research.
>
> **This is a STANDING condition, not a new regression, and that is the part worth stating.** The 2026-08-16 file's own 1A.1 contained 25 August rows, 24 September, 50 October, 19 November and **zero for December, January or February** — presenting a "6-month window" whose earnings half covered barely three months, without saying so. **The window is not being narrowed here; it is being described accurately for the first time.**
>
> **The Jan–Feb 2027 FY-report cluster** — the mega-cap Q4/FY prints and calendar-Q4 bank earnings, the densest catalyst block in the back half of any A window — **is absent below because no source reached it, NOT because it was checked and found absent.** Do not read the absence as evidence. **OWNER ACTION (or a W5 consolidation cycle): an FMP tier reaching beyond ~13 weeks, or a second earnings-calendar source, is required before this file can honestly claim 6-month earnings coverage.** Raised as an `ops.alerts` finding this run rather than left in prose.

### 1A.1 — Earnings catalysts

Status vocabulary: **(C)** confirmed against the company's own IR release or SEC filing *this run* · **(2S)** two independent sources agree, no company release located · **(E)** single-source or cadence estimate · **(!)** sources disagree, all dates shown.

**Inside the Strategy C 45-day window (2026-08-24 → 2026-10-07)** — restated in 1B.2 for C's convenience:

| Date | Ticker | Company | Fiscal Q | Status |
|---|---|---|---|---|
| 2026-08-25 | **INTU** | Intuit | Q4 FY26 | **(C)** investors.intuit.com |
| 2026-08-25 | ZM | Zoom Communications | Q2 FY27 | (E) |
| **2026-08-26** | **NVDA** | NVIDIA | Q2 FY27 | **(C)** nvidianews.nvidia.com — *upgraded from (E) two-source* |
| **2026-08-26** | **CRM** | Salesforce | Q2 FY27 | **(C)** investor.salesforce.com — *upgraded from (E)* |
| 2026-08-26 | **OKTA** | Okta | Q2 FY27 | **(C)** investor.okta.com |
| **2026-08-26** | **CRWD** | CrowdStrike | Q2 FY27 | **(C)** ir.crowdstrike.com — *upgraded from (E)* |
| **2026-08-27** | **MRVL** | Marvell Technology | Q2 FY27 | **(C)** investor.marvell.com |
| 2026-08-27 | WDAY | Workday | Q2 FY27 | **(C)** newsroom.workday.com |
| 2026-08-27 | DG | Dollar General | Q2 FY26 | **(C)** company 8-K exhibit |
| 2026-08-27 | DLTR | Dollar Tree | Q2 FY26 | **(C)** company 8-K exhibit |
| 2026-08-27 | BILI | Bilibili | Q2 CY26 | (E) · **ADR** |
| **2026-09-01** | **DELL** | Dell Technologies | Q2 FY27 | **(C)** businesswire 2026-08-18 — **CORRECTS the prior cycle's 09-03 (E)** |
| **2026-09-01** | **PANW** | Palo Alto Networks | Q4 FY26 | **(C)** investors.paloaltonetworks.com |
| 2026-09-01 | NIO | NIO | Q2 CY26 | (E) · **ADR** |
| **2026-09-02** | **AVGO** | Broadcom | Q3 FY26 | **(C)** investors.broadcom.com |
| **2026-09-02** | **SNOW** | Snowflake | Q2 FY27 | **(C)** snowflake.com |
| **2026-09-02** | **HPE** | Hewlett Packard Enterprise | Q3 FY26 | **(C)** investors.hpe.com |
| **2026-09-02** | **NTAP** | NetApp | Q1 FY27 | **(C)** investors.netapp.com — **the prior cycle recorded NTAP as having no dated catalyst** |
| 2026-09-03 | LULU | lululemon | Q2 FY26 | **(C)** |
| 2026-09-03 | DOCU | DocuSign | Q2 FY27 | (E) |
| ~2026-09-08 | **ORCL** | Oracle | Q1 FY27 | **(!) UNRECONCILED FOR A THIRD CYCLE** — 09-08 / 09-10 / 09-14; MarketBeat's page is internally inconsistent (a Tuesday 09-08 date beside a Friday 09-04 call). **No Oracle IR release located.** |
| ~2026-09-08/09 | GME | GameStop | Q2 FY26 | **(!)** every aggregator marks it UNCONFIRMED |
| 2026-09-09 | CHWY | Chewy | Q2 FY26 | **(C)** |
| 2026-09-10 | **ADBE** | Adobe | Q3 FY26 | **(2S)** — no Adobe IR release located |
| 2026-09-11 | KR | Kroger | Q2 FY26 | **(C)** ir.kroger.com |
| ~2026-09-17 | ~~FDX~~ | ~~FedEx~~ | — | **WITHDRAWN — see the FedEx correction below** |
| 2026-09-17 **or** 09-24 | DRI | Darden Restaurants | Q1 FY27 | **(!)** |
| ~2026-09-23 | CTAS | Cintas | Q1 FY27 | **(E)** — company has said only "in September"; no date announced |
| ~2026-09-23 | GIS | General Mills | Q1 FY27 | (E) |
| 2026-09-24 | COST | Costco | Q4 FY26 | **(C)** investor.costco.com |
| **09-22 / 09-23 / 09-29** | **MU** | Micron | Q4 FY26 | **(!) THREE candidate dates across four sources** — 09-22 (public.com/tipranks), 09-23 (wallstreethorizon, marked UNCONFIRMED), 09-29 (FMP/aggregator). Prior cycle carried 09-22. **No Micron IR release located; do not lock a structure to any of these without a fresh IR check.** |
| 2026-09-24 **or** 09-29 | NKE | Nike | Q1 FY27 | **(!)** 09-29 is a Tuesday and matches Nike's pattern; 09-24 is a Thursday and does not |
| ~2026-09-30 | PAYX | Paychex | Q1 FY27 | **(E)** no date announced |
| 2026-10-01 | ACN | Accenture | Q4 FY26 | (E) |
| 2026-10-05 | CCL | Carnival | Q3 FY26 | (E) |
| 2026-10-05 | STZ | Constellation Brands | Q2 FY27 | (E) |

**THE FEDEX CORRECTION — a stale-cadence artifact that would have put a phantom event in the C window.** FMP carries **two** FDX rows (09-17 and 10-28), which is itself the tell. **FedEx changed its fiscal year end from May 31 to December 31, effective 2026-06-01**, alongside the FedEx Freight spin-off. Its next disclosure is a **Form 10-Q for calendar Q3 2026 (Jul 1–Sep 30)**, then a seven-month Transition Report 10-KT for Jun–Dec 2026. **No earnings-call date has been announced for either.** FMP's 09-17 extrapolates the *old* cadence (FDX reported Q1 FY26 on 2025-09-18). **Both FDX rows are withdrawn.** Same failure class as the NUVL error this file caught last cycle: a source confidently dating an event the underlying's own corporate structure has moved.

**Beyond the C window, to the point where source coverage ends (2026-10-08 → 2026-11-24):**

| Date | Tickers | Status |
|---|---|---|
| 2026-10-08 | PEP, DAL | (E) |
| 2026-10-13 | **JPM, GS, C, WFC, JNJ** | (E) — the calendar-Q3 bank block |
| 2026-10-14 | BAC | (E) |
| 2026-10-15 | **TSM** | **(2S)** · **ADR — not A-eligible** |
| 2026-10-20 | **LMT**, KO, GE, GM, NFLX, VZ | **(2S)** LMT; (E) rest |
| 2026-10-21 | **IBM**, UAL | **(2S)** IBM |
| 2026-10-22 | **INTC**, NOK (ADR), AAL, F | **(2S)** INTC |
| 2026-10-23 | HCA | (E) |
| 2026-10-27 | V, UNH, CARR, PYPL, SOFI | (E) |
| **2026-10-28** | **MSFT, GOOGL, META, TSLA, BA, NOW, GEV**, T, SBUX | **(2S)** for MSFT/GOOGL/META/TSLA/BA — two independent sources agree. **GEV is (!): ~10-28 this run vs ~10-20 prior cycle, no second source either way** |
| **2026-10-29** | **AAPL, AMZN**, LLY, MRK, FSLR, COIN, RBLX, SIRI, RIOT, RKT | **(2S)** AAPL/AMZN |
| 2026-10-30 | XOM, CVX, ABBV | (E) |
| 2026-11-02 | PLTR, VRTX | **(2S)** |
| 2026-11-03 | **AMD**, SMCI, PFE, PINS, RIVN, SHOP, UBER | **(2S)** AMD; **SMCI (E), low confidence — irregular reporting history** |
| 2026-11-04 | **CAT**, QCOM, ET, ETSY, HOOD, MGM, ROKU, SNAP | **CAT is (!): ~11-04 this run vs ~10-20 prior cycle** |
| 2026-11-05 | DDOG, AKAM, TTWO, MRNA | (E) |
| 2026-11-09 **or** 11-16 | **CRWV** | **(!)** public.com vs tipranks; no CoreWeave IR release |
| 2026-11-10 | NBIS, SONY (ADR) | (E) |
| **2026-11-11** | **CSCO** | **(2S)** |
| 2026-11-12 | AMAT, DIS | (E) |
| 2026-11-17 | HD, BIDU (ADR) | (E) — HD from historical pattern only |
| 2026-11-18 | TGT | **(2S)** |
| 2026-11-19 | **WMT** | **(2S)** |
| 2026-11-24 | BABA (ADR) | (E) — **the last date any source returned** |
| **2026-11-25 → 2027-02-23** | **NO ROWS FROM ANY SOURCE** | **Not "no events" — no coverage.** |

**One confirmed date sits beyond the coverage cliff, obtained first-party rather than from a calendar feed: NTAP Q2 FY27, 2026-12-01**, stated in NetApp's own Q1 release. It is the only December-or-later earnings date in this file, and its presence beside an otherwise empty Dec–Feb stretch is the point exactly — the dates exist and are publishable; the sources this routine currently reaches do not carry them.

### 1A.2 — Product launches and product events

| Date | Ticker(s) | Event | Status |
|---|---|---|---|
| ~2026-09-09 | AAPL | iPhone 18 Pro / Pro Max + foldable "iPhone Ultra" keynote | **(E)** — Apple had issued no invite as of 2026-08-19; press speculation |
| 2026-09-15 → 17 | CRM | Dreamforce 2026, San Francisco | **(C)** |
| 2026-09-23 → 24 | META | Meta Connect 2026, Menlo Park | **(C)** |
| 2026-10-20 → 22 | NVDA | GTC Berlin | **(C)** |
| 2026-10-25 → 28 | ORCL | Oracle CloudWorld / AI World 2026, Las Vegas | **(C)** |
| 2026-11-10 → 12 | ADBE | Adobe MAX 2026, Miami Beach | **(C)** |
| 2026-11-17 → 20 | MSFT | Microsoft Ignite 2026, San Francisco | **(C)** |
| **2026-11-19** | **TTWO** | **Grand Theft Auto VI launch** (PS5, Xbox Series X\|S) | **(C)** — reaffirmed by CEO Zelnick early Aug 2026 |
| 2026-11-30 → 12-03 | AMZN | AWS re:Invent 2026, Las Vegas | **(C)** |
| 2026-11-30 → 12-03 | NVDA | GTC Washington, D.C. | **(C)** |
| 2027-01-06 → 09 | broad (historically NVDA, DELL, QCOM keynotes) | CES 2027, Las Vegas | **(C)** dates; keynote lineup unannounced |
| ~2027-02-17/24 | *(Samsung — not US-listed; material to QCOM as supplier)* | Galaxy Unpacked / Galaxy S27 | **(E)** — may fall outside the window |

**Carried from the prior cycle and NOT re-verified this run:** the **TTWO GTA VI "Extended Look" trailer, 2026-08-27**, carried at (C) off Rockstar's own page last cycle. This run's sweep did not re-surface it. Absence from one sweep is not evidence of cancellation, so it is carried with provenance stated rather than dropped or re-asserted as confirmed.

### 1A.3 — Analyst days, investor days and major conferences

**This category is genuinely thin, and that is a finding rather than a gap.** The sweep confirmed most large-cap investor days it could locate (QCOM, AMD, NOW, Cummins, SNOW, SanDisk, FDX, KLA, TransUnion, Amkor, GlobalFoundries, Honeywell, Deere) **already occurred before 2026-08-24** or fall after 2027-02-23.

| Date | Ticker | Event | Status |
|---|---|---|---|
| 2026-08-25 | WAY | Waystar Investor Day (True North), San Antonio | **(C)** |
| 2026-09-10 | LH | Labcorp Investor Day | **(C)** |
| 2026-09-16 | ON | onsemi Investor Day 2026, NYC | **(C)** — company social post; no press release surfaced |
| 2026-09-17 | DCO | Ducommun (~$3.1B) Investor Day, NYC | **(C)** |
| 2026-10-13 | BGC | FMX (BGC Group) first-ever Investor Day, NYC | **(C)** |

*Excluded on the $2B floor, so the exclusion is auditable:* Backblaze (09-09), Omada Health (09-10) — recent small-cap IPOs; Arcos Dorados (10-01), market cap verified **$1.64B**.

**CARRIED FROM THE PRIOR CYCLE, NOT RE-VERIFIED — and it is load-bearing for a ranked row.** **INTU Investor Day, 2026-09-17**, carried at (C) last cycle with the agenda still to come. This run's sweep did not surface it. **W4/D2: re-verify against investors.intuit.com before treating it as a live dated catalyst.** An investor day is exactly the kind of event that gets quietly re-dated, and this file should not launder a prior-cycle confirmation into a current one.

### 1A.4 — Regulatory, legal, trade and policy decisions

| Date | Ticker(s) | Event | Status |
|---|---|---|---|
| **2026-10-05** | **QCOM, ARM** | **Qualcomm v. Arm trial begins** — breach-of-contract suit over Arm's ALA deliverables | **(C) — NEW this cycle** |
| by Oct 2026 | AAPL | Company-stated deadline to update App Store terms for EU DMA compliance | **(C)** as a commitment; **no fixed date** |
| **2026-11-10** | broad China-import-exposed | **USTR Section 301 China-tariff exclusions expire** | **(C)** |
| **2026-12-03** | UNP, NSC | STB review of UP–NS: DOJ/DOT preliminary-comments deadline | **(C)** |
| **2026-12-04** | **FSLR** + solar/polysilicon chain | **Section 232: 15% tariff + minimum-import-price program on polysilicon takes effect** | **(C)** |
| 2027-02-16 | UNP, NSC | STB: deadline for responses to DOJ/DOT comments and protests | **(C)** |

**A prior-cycle row is CORRECTED OUT of the window. AMZN's FTC trial has moved to 2027-03-29** — outside this 6-month horizon. The prior cycle carried it as live-but-downgraded and **`Watchlist.md`'s AMZN row still cites it. Action for W4: that watchlist row's catalyst reference needs updating; W1 does not edit `Watchlist.md`.** AMZN's only in-window catalyst is now its Q3 print.

**Carried from the prior cycle, NOT re-verified:** the **META UTECA trial, October 2026**, carried at (C) last cycle and underpinning META's "reframed — new legal catalyst" row. Not surfaced this run. **W4/D2 must re-verify the date before relying on it.**

*Verified resolved or out-of-window, so a later cycle does not re-investigate:* EU DMA Google specification decisions **issued 2026-07-16** · Google antitrust D.C. Circuit oral argument **unscheduled** · Meta FTC appeal **no hearing date set** · Boeing 777X certification guided to "2027", **no fixed date** · Live Nation states' remedies phase "could stretch into 2027", no fixed date.

### 1A.5 — Restructuring and structural events

| Date | Ticker(s) | Event | Status |
|---|---|---|---|
| 2026-09-01 | COP | CEO transition — Andy O'Brien succeeds Ryan Lance | **(C)** |
| 2026-09-01 | TFC | CEO transition — Michael P. Lyons succeeds Bill Rogers | **(C)** |
| **2026-09-18** | broad S&P 500 | **Q3 quarterly index rebalance** (3rd Friday) | **(C)** |
| 2026-10-01 | CTVA | Target completion of the **"Vylor" seed/genetics spin-off** | **(C)** company target, subject to conditions |
| by end-2026 | KMB, KVUE | Expected close of Kimberly-Clark / Kenvue — votes and HSR already obtained | **(E)** company guidance |
| 2026-09 → 2027-03 | TECK | Final regulatory-approval window, Anglo American–Teck (pending China / South Korea) | **(E)** company-stated range |
| **2026-12-18** | broad S&P 500 | **Q4 quarterly index rebalance** | **(C)** |
| 2027-01-01 | DG | CEO transition — JJ Fleeman becomes CEO | **(C)** |
| 2026-08-21 *(disclosed)* | BA | SVP Finance Ryan Shedd succeeds Michael Cleary as Controller upon the 2026 10-K filing | **(C)** 8-K Item 5.02 — *the only new disclosure found in the D1 coverage gap* |

**Carried from the prior cycle, NOT re-verified — and load-bearing.** **AAPL CEO transition, John Ternus succeeds Tim Cook, 2026-09-01**, carried at (C) last cycle. It is AAPL's *only* dated structural catalyst (the iPhone event is unconfirmed; the Q4 print is late October). This run's sweep surfaced the COP and TFC transitions on the same date but not Apple's. **Re-verify before use.**

*Verified completed before the window opened:* Charter–Cox **2026-08-22** · Nexstar–TEGNA 2026-03-19 · Verizon–Frontier 2026-01-20 · Global Payments–Worldpay 2026-01-09 · BD/Waters 2026-02-09 · DuPont–Qnity 2025-11-01 · Resideo/ADI 2026-08-03/04 · Comcast–Versant 2026-01-02 · Rivian R2 SOP 2026-04-22. *Out of window:* Paramount Skydance / WBD pushed to "earlier of 5 days after a court ruling or 2027-06-01" · UP–NS earliest STB final decision "2H 2027" · CME CEO transition "later of 2027-03-01 or the 10-K filing".

---

## PART 1B — Strategy C universe catalyst calendar (45-day window, 2026-08-23 → 2026-10-07)

C's qualifying event types **only**: corporate earnings (company IR), FDA PDUFA (FDA calendar / company disclosure), FOMC (Fed calendar). **Router reminder: only an FOMC-catalyst thesis is router-eligible; everything else here is context.**

### 1B.1 — FOMC

**Fetched first-party this run from `federalreserve.gov/monetarypolicy/fomccalendars.htm`.**

| Event | Detail | Date | In window? |
|---|---|---|---|
| **FOMC** | Meeting **2026-09-15/16**, decision **Wed 2026-09-16 2:00pm ET**, press conference 2:30pm ET, **WITH Summary of Economic Projections** | **2026-09-16 (C)** | **YES — the only one** |

Remaining meetings off the same page: **2026-10-27/28** (no SEP) · **2026-12-08/09** (SEP) · **2027-01-26/27** · 2027-03-16/17 (SEP) · 2027-04-27/28 · 2027-06-08/09 (SEP) · 2027-07-27/28 · 2027-09-14/15 (SEP) · 2027-10-26/27 · 2027-12-07/08 (SEP).

**The one FOMC inside this window is also the only SEP-carrying meeting before December** — a second, independent source of surprise beyond the rate decision. The Fed has held a press conference after every meeting since January 2019, so the presser is not differentiating; the dot plot is.

**Correction to a prior-cycle row.** The 2026-08-16 file carried an **FOMC minutes** entry at "~2026-08-19 (E)", inferred from the standard three-week lag and flagged unconfirmed. The Fed's calendar publishes minutes dates only for meetings already past, so the item was never verifiable forward. It is **dropped** rather than carried with a stale caveat.

**Scheduled macro releases between this file and the decision — context, not C-qualifying:**

| Date | Release | Agency | Confirmation |
|---|---|---|---|
| 2026-08-26 | GDP Q2 2026 **second estimate** | BEA | Confirmed |
| 2026-08-26 | Personal Income & Outlays (**PCE**), July | BEA | Confirmed |
| **2026-08-27 → 08-29** | **Jackson Hole symposium** ("Financial Innovation: Implications for Payments and Policy") | KC Fed | Confirmed |
| 2026-09-01 | ISM Manufacturing PMI (Aug) | ISM | Confirmed |
| 2026-09-03 | ISM Services PMI (Aug) | ISM | Confirmed |
| 2026-09-04 | **Employment Situation**, August | BLS | Confirmed |
| 2026-09-10 | **PPI**, August | BLS | Confirmed |
| **2026-09-11** | **CPI, August** | BLS | Confirmed |
| 2026-09-30 | PCE, August | BEA | Confirmed — *after* the decision |
| 2026-10-01 | ISM Manufacturing PMI (Sep) | ISM | **Calculated** from ISM's first-business-day rule, not print-confirmed |
| 2026-10-02 | Employment Situation, September | BLS | Confirmed |
| 2026-10-05 | ISM Services PMI (Sep) | ISM | **Calculated** from the third-business-day rule |

**One CPI, one PPI, one payroll, one PCE print and Jackson Hole land between this file and the decision.** September CPI/PPI release mid-October, after the window closes, and are correctly excluded. **No Treasury quarterly refunding falls in the window** (next announcement 2026-11-04; the August auctions settled 2026-08-17). **No Humphrey-Hawkins testimony either** — Chair Warsh testified 2026-07-14/15; the next round is ~February 2027. Both stated as measured absences, because "no row" and "not checked" are otherwise indistinguishable.

### 1B.2 — Corporate earnings inside the 45-day window

Same dated set as 1A.1 falling 2026-08-24 → 2026-10-07, status carried verbatim: **INTU (C)** / ZM 8/25 · **NVDA (C)** / **CRM (C)** / **OKTA (C)** / **CRWD (C)** 8/26 · **MRVL (C)** / **WDAY (C)** / **DG (C)** / **DLTR (C)** / BILI 8/27 · **DELL (C)** / **PANW (C)** / NIO 9/01 · **AVGO (C)** / **SNOW (C)** / **HPE (C)** / **NTAP (C)** 9/02 · **LULU (C)** / DOCU 9/03 · **ORCL ~9/08 (!)** · GME ~9/08-09 (!) · **CHWY (C)** 9/09 · ADBE 9/10 (2S) · **KR (C)** 9/11 · DRI 9/17 or 9/24 (!) · CTAS ~9/23 (E) · GIS ~9/23 (E) · **COST (C)** 9/24 · **MU 9/22 or 9/23 or 9/29 (!)** · NKE 9/24 or 9/29 (!) · PAYX ~9/30 (E) · ACN 10/01 (E) · CCL 10/05 (E) · STZ 10/05 (E).

*FDX is deliberately absent — see the FedEx correction in 1A.1.* *CSCO reported 2026-08-13 and is correctly out of this window.*

### 1B.3 — FDA PDUFA and regulatory actions inside the 45-day window

> **SOURCE-QUALITY REVERSAL FROM THE PRIOR CYCLE, AND IT IS THE GOOD DIRECTION.** The 2026-08-16 file carried a blanket warning over this whole table: every sponsor IR site it tried returned 403/503/DNS failures, `fda.gov` returned 401/404, and **every row was (R) — single-tracker, sponsor-unconfirmed**, even rows an earlier cycle had carried as confirmed. **This run those sites were reachable.** Ten rows below are now confirmed against the sponsor's own release or FDA.gov directly.

| Date | Ticker | Company (cap) | Drug / indication | Event | Status |
|---|---|---|---|---|---|
| **2026-08-24** | **BIIB** | Biogen / Eisai (~$28–33B) | **Leqembi IQLIK (lecanemab-irmb), SC starting dose — early Alzheimer's** | sBLA PDUFA | **(C)** investors.biogen.com — **extended three months from 2026-05-24, announced 2026-05-08; FDA cited a major amendment and has raised no approvability concern** |
| 2026-08-25 | **JAZZ** | Jazz (~$15.9B) | Ziihera (zanidatamab) + combos, 1L HER2+ gastric/GEJ | sBLA PDUFA | **(C)** investor.jazzpharma.com |
| 2026-08-27 | **GILD** | Gilead (~$181B) | Bictegravir + lenacapavir, HIV-1 | NDA PDUFA | **(C)** gilead.com |
| 2026-09-11 | TLX | Telix (~$3.4–3.8B) | TLX101-Px / Pixclara, recurrent glioma imaging | Resubmitted NDA | **(C)** telixpharma.com |
| **2026-09-18** | **GSK** *(NOT NUVL)* | GSK plc | Zidesamtinib, ROS1+ NSCLC post-TKI | NDA PDUFA | **(C)** — **see the NUVL correction below** |
| 2026-09-19 | **RARE** | Ultragenyx (**~$2.5B — borderline**) | UX111, Sanfilippo A | Resubmitted BLA | **(C)** ir.ultragenyx.com |
| 2026-09-21 | MRK | Merck (>$200B) | Winrevair (sotatercept), PAH label expansion | sBLA PDUFA | **(C)** merck.com — *the prior cycle withdrew this as unverifiable, then re-carried it at (R); now first-party confirmed* |
| 2026-09-22 | IONS | Ionis (~$9.9B) | Zilganersen, Alexander disease | NDA PDUFA | **(C)** ir.ionis.com |
| **2026-09-23** | **GRAL** | GRAIL (~$3.0B) | **Galleri MCED blood test** | **CDRH Molecular and Clinical Genetics Panel — PMA advisory panel (a recommendation and vote, NOT a final decision)** | **(C)** fda.gov, docket FDA-2026-N-8004, FR notice 2026-16245 |
| 2026-09-26 | INCY / MIRM | Incyte / Mirum (~$6.0–6.5B) | Zilurgisertib, fibrodysplasia ossificans progressiva | NDA PDUFA | **(C)** both sponsors' IR |
| ~2026-09-30 | PTGX / TAK | Protagonist / Takeda (~$9–10B) | Rusfertide, polycythemia vera | NDA PDUFA | **(!)** quarter confirmed by sponsor ("Q3 2026"); the 09-30 day is aggregator-only |
| ~2026-09-30 | ROIV / PFE | Priovant JV (ROIV ~$25–26B) | Brepocitinib, dermatomyositis | NDA PDUFA | **(!)** same shape |
| ~2026-09-30 | SRRK | Scholar Rock (~$5.7–6.4B) | Apitegromab, SMA | Resubmitted BLA | **(R)** aggregator only |
| ~2026-09-30 | BMY | Bristol Myers Squibb | Camzyos, obstructive HCM | sNDA PDUFA | **(R)** aggregator only |
| ~2026-09-30 | NVO | Novo Nordisk | Denecimig (Mim8), hemophilia A | BLA PDUFA | **(R) WEAK — single undated aggregator; no Novo-issued date located** |
| 2026-10-04 | MRK / Eisai | Merck / Eisai | Welireg + Lenvima, advanced RCC | sNDA PDUFA | **(C)** merck.com + eisai.com |

**Resolved before the window opened — recorded because aggregators still list them as pending:**
- **REGN garetosmab (FOP) was APPROVED 2026-08-19** as Pasatru.
- **ITM ¹⁷⁷Lu-edotreotide received a COMPLETE RESPONSE LETTER 2026-08-07** — CMC / third-party manufacturing deficiencies, no clinical or safety concerns. Its 08-28 PDUFA is already resolved, negatively. **This is why the window's first week is genuinely thin rather than under-searched.**
- **RARE DTX401 (GSD-Ia), 2026-08-23** — its action date is today; FDA does not act on a Sunday and C requires entry at least one trading day before the event, so it is not actionable from this file either way.
- **CAPR deramiocel** — sources disagree (07-29 vs 08-22); both past, and CAPR fails the $2B floor regardless.

**Below the $2B floor, excluded so the exclusion is auditable:** **BFRI** (~$16M, Ameluz sBCC, 09-28) · **SVRA** (~$1.18B, molgramostim, 11-22, also out of window). **Not US-listed:** Elevar (lirafugratinib, 09-27), Egetis (Nasdaq Stockholm, 09-28).

> **THE NUVL CORRECTION STANDS, AND A SECOND INSTANCE APPEARED THIS RUN.** Nuvalent's acquisition by GSK closed 2026-07-14/15 ($124.00/share cash); **NUVL no longer trades and has no option chain**, so its catalysts cannot carry a C structure. **New this run: `DCPH` (Deciphera) is credited by a tracker with a 2026-12-18 tirabrutinib PDUFA, but Deciphera was acquired by ONO Pharmaceutical in 2024.** Same failure shape. Recorded here, unused, flagged for verification before any future cycle acts on it. **A PDUFA date being real is not the same as the ticker beside it being tradeable, and this file has now been bitten by that twice.**

### 1B.4 — Beyond-window PDUFAs (2026-10-08 → 2027-02-23), A-side context only

**MRK/Daiichi** ifinatamab deruxtecan, ES-SCLC, **2026-10-10** (3 aggregators agree) · **RHHBY** Enspryng **10-15** (R) · **VTRS/Opus** phentolamine ophthalmic **10-17** (R) · **IONS+GSK** bepirovirsen **10-26** (R) · **INO** INO-3107 **10-30** (R, sub-$2B) · **SVRA** molgramostim **11-22** (R, sub-$2B) · **SNY** venglustat **11-25** (R) · **BBIO** BBP-418 **11-27** (~$15.6B) · **GSK** *(formerly NUVL)* neladalkib **11-27** · **VRTX** povetacicept, IgA nephropathy, **11-30** (R) · **EXEL** zanzalintinib + atezolizumab **12-03** (~$13.5B) · **VNDA** imsidolimab **12-12** (R) · **DCPH(?)** tirabrutinib **12-18** — *see the stale-sponsor warning* · **RHHBY** giredestrant + everolimus **12-18** (R) · **MLYS** lorundrostat **12-22** (R) · **GILD/ACLX** anito-cel **12-23** · **PRAX** relutrigine — **EXTENDED 09-27 → 12-27**, confirming the prior cycle's finding · **COGT** bezuclastinib **12-30** (~$6.6B) · **NUVB** taletrectinib **2027-01-04** (~$2.2B, borderline) · **BLTE** tinlarebant **2027-02-12** (~$5.67B).

*Just outside the window:* CGEM zipalertinib **2027-02-27**, BMRN vosoritide **2027-02-28** — four to five days late.

**AdCom coverage is incomplete for a structural reason, not a search failure.** FDA posts advisory-committee notices only ~30–75 days ahead via the Federal Register, and `fda.gov`'s live calendar is JS-rendered — it returned 401 to a direct fetch and an empty shell to an extract, bannered "content current as of 08/07/2026". **The GRAIL panel is the only FDA advisory meeting confirmed inside either window; October meetings may simply not be noticed yet.** Re-run next cycle rather than treating this list as complete. EMA CHMP plenaries (09-14→17, 10-12→15, 11-09→12) are confirmed as meetings, but no US-sponsor opinion was identified for any.

---

## PART 2A — Strategy A preliminary ranked shortlist (46 candidates)

W4 reads this section verbatim.

**ROUTING — both gates settled, neither lifted, one on a nine-day clock.** (i) **Router:** A = **DO-NOT-ACTIVATE** (`div-A-202607-1`, 2026-08-05; re-affirmed 2026-08-13). Every name below routes to the `Watchlist.md` A-queue with reason "router gate; queued for next M1 ACTIVATE"; **no thesis-construction is enqueued this cycle.** (ii) **Capital:** A is capital-disabled at **NAV $0.00, available $0.00**. **Both must lift.** Next router resolution: **M1a 2026-09-01 → M1b**, plus a divergence review if the call diverges.

Per candidate: (a) hypothesised direction, (b) supporting public documents, (c) catalyst date, (d) **REACH**, (e) overlap, (f) tier. Direction is a *preliminary* synthesis hypothesis; full thesis construction (adversarial counter-argument attacking **size as well as direction**, immutable at-entry price target and completion criteria per Entry criterion 3, the criterion-6 historical-analogue exclusion) happens in W4-scheduled sessions.

**REACH:** **REACHABLE** = catalyst dated after ~2026-09-05 · **SPENT** = falls before the earliest date A could act · **SPENT→NEXT** = this cycle's catalyst is spent but a later in-window catalyst exists and is the one that matters.

### What changed in the universe this cycle, before the rankings

1. **QCOM gains a second, non-earnings dated catalyst: Qualcomm v. Arm goes to trial 2026-10-05.** A scheduled legal decision on the licensing terms underpinning its core business — squarely an Entry-criterion-1 "regulatory timeline" catalyst, not a print. QCOM ranked **#29** last cycle on a row with no dated catalyst at all. It now has two, both REACHABLE.
2. **NTAP stops being unshortlistable.** The prior row read "no checkable contract/figure; NOT shortlisted" and carried no date. NetApp's own IR now gives **Q1 FY27 2026-09-02 and Q2 FY27 2026-12-01**, both first-party. The narrative objection may still hold; the *stated reason* for exclusion does not.
3. **INTU's cap is partly answered.** It was held at #20 for naming "no checkable mechanism," having only its Investor Day. It also has an IR-confirmed earnings print (08-25, SPENT) — and the Investor Day at 09-17 is REACHABLE, making INTU a rare row whose dated-event-only character is now a *strength*.
4. **AMZN loses its non-earnings catalyst from this window** — the FTC trial moved to 2027-03-29.

### ⚠️ A METHODOLOGICAL WARNING ABOUT THE IV/HV FIGURES BELOW — READ BEFORE RANKING ON THEM

Every IV/HV ratio in this section is a **live IBKR measurement taken this run**, ATM call/put averaged, against 30-bar close-to-close realised vol. The field read was the per-contract **`implied_vol`**, which returned `is_valid:true` for every name but one — **this run did NOT need the `implied-vol-underlying` substitution the prior cycle was forced into and disclosed.** One strike failed (INTU 367.5 returned `is_valid:false`); the 370 strike, 0.7% off spot, was substituted rather than a number inferred.

**But the ratios are NOT comparable across rows, and ranking on them naively would be an error.** The expiration chosen for each name is the first strictly after its own event, so **tenor varies from 5 days to 117 days across this table.** A 5-day expiry spanning an imminent print concentrates event vol; a 90-day expiry containing an October print dilutes it across a quarter of ordinary time. **The apparent pattern — spent names rich (1.4–2.6), reachable names cheap (0.62–0.95) — is very largely a tenor artifact, not a signal about event pricing.** It is exactly what near-dated vs far-dated structures look like. Do not read "reachable names have cheap optionality" out of this table.

**Two rows are additionally low-quality and flagged in place:** **CAT**'s chosen expiration is **2026-11-20** against a ~10-20 event, and **GEV**'s is **2026-12-18** against a ~10-20 event — roughly two months past. Their listed near-term weeklies simply do not exist (after 10-16 the chains jump). Their ratios are near-meaningless as event-vol reads and are shown only for completeness.

### TOP-10

| # | Ticker | Direction | Supporting public documents | Catalyst (date) | REACH | Measured | Overlap |
|---|---|---|---|---|---|---|---|
| 1 | **ORCL** | Bullish (deep re-base) | The **~$7B, 10-year DoD software-consolidation award** (07-27; initial 5-yr tranche $3.31B) ratifies the OCI-bookings/RPO thesis *at the layer it predicted*. Close 146.47, **+11.4% over 30 bars** — the tape has begun to re-rate it back | **Q1 FY27 ~2026-09-08 (!)** — third cycle unreconciled; Oracle AI World 10-25→28 **(C)** | **REACHABLE** — and the first reachable catalyst in the window | IV 74.2 / HV 60.9, **ratio 1.22** (09-11 expiry) · ADV $2,747.9M | A-queue |
| 2 | **MU** | Bullish | Load-bearing evidence remains a *customer's own disclosure*: QCOM's FQ4 guide-down explicitly citing "unprecedented increases in memory pricing." Close 966.78, +3.2% | **Q4 FY26 — 09-22 / 09-23 / 09-29 (!)** | **REACHABLE** on every candidate date | IV 65.4 / HV 96.7, **ratio 0.68** (09-25 expiry) · **ADV $23,492.8M — the most liquid name on this list** | A-queue; CXMT supply-side counter open |
| 3 | **QCOM** | Bullish — **UPGRADED from #29 on a new dated catalyst** | Snapdragon/automotive-AI franchise, plus the licensing dispute now reaching decision. **Two dated catalysts where the row previously had none** | **Qualcomm v. Arm trial begins 2026-10-05 (C)**; Q4 FY26 ~11-04 | **REACHABLE** ×2 | **Not measured this run** — introduced after the measurement agent's scope was set; ADV unmeasured | A-queue |
| 4 | **INTU** | Bullish — **the prior cycle's cap partly answered** | The row's weakness was naming no checkable mechanism. It still names none, but it now has **two** dated disclosure events rather than one, and Intuit says the Investor Day agenda is still to come. Close 367.00, **+26.7% over 30 bars** | Earnings 08-25 **(C)**; **Investor Day 2026-09-17** — *(C) prior cycle, NOT re-verified this run* | **SPENT→NEXT** (Investor Day) | IV 57.5 / HV 47.7, **ratio 1.21** (09-18 expiry; 370 strike substituted) · ADV $683.9M | A-queue |
| 5 | **CAT** | Bullish — ratified, runway contested | Q2 (08-04): sales **$20.543B +24% y/y** (first quarter above $20B), adj EPS **$8.17 vs ~$6.20** consensus — largest beat in five years — record **$63B backlog**, E&T/power-gen **+29% y/y on data-centre demand**, FY guidance raised. **Close 827.90, −11.1% over 30 bars: still de-rating against improving documents** | **Q3 ~2026-10-20 or ~11-04 (!)** | **REACHABLE** | ratio 1.02 — **LOW QUALITY, 11-20 expiry vs a ~10-20 event** · ADV $1,376.2M | A-queue |
| 6 | **GEV** | Bullish | Q2 (07-22): revenue $11.1B +22%, **orders +88% to $24.2B**, backlog **$176B** including 116GW of gas-power reservations and >$5B of 2026 data-centre orders; FY26 guides raised. Close 956.85, −8.2% | **Q3 ~2026-10-20 or ~10-28 (!)** | **REACHABLE** | ratio 0.93 — **LOW QUALITY, 12-18 expiry vs a ~10-20 event** · ADV $1,519.7M | **Open D position** — 30%-GICS / correlation check required, not a bar |
| 7 | **INTC** | Bullish | Q2: revenue **$16.1B +25% y/y** (fastest in 15+ years), **DCAI +59%**, gross margin back to 42%, capex raised >$20B, management "cannot keep up with orders" — unrefuted by any subsequent disclosure. Close 90.07, **−12.7% over 30 bars** | **Q3 2026-10-22 (2S)** | **REACHABLE** | IV 67.2 / HV 75.5, **ratio 0.89** · ADV $7,172.7M | A-queue |
| 8 | **SMCI** | Bullish — conviction discounted for issuer quality | FQ4 (08-11): adj EPS **$1.70 vs $1.59**; revenue $11.12B **+93% y/y**; **FQ1 guided $14.5–15.5B against $11.99B consensus**, and **FY2027 revenue $65–72B against $54.43B consensus**. Formal multi-quarter guidance is a materially stronger document class than the caveated ">$60B orders" an earlier row rested on. Close 37.24, **+34.6% — the strongest 30-bar move on this list** | **Q1 FY27 ~2026-11-03 (E, low confidence — irregular reporting history)** | **REACHABLE** | IV 81.0 / HV 102.1, ratio 0.79 · ADV $1,269.7M | A-queue. **The gap is extraordinary; the source has a record** |
| 9 | **AMD** | **Direction CONTESTED** | The 08-03 thesis (MI400 shipped, roadmap risk converted to product) was ratified on product and refuted elsewhere at the 08-04 print. Two-sided: **+6.50% on 08-14 while pricing its largest-ever USD bond ($4.75B, four tranches) to fund AI capex** — the market rewarding the financing it punished AVGO for. Close 473.25, −11.4% | **Q3 2026-11-03 (2S)** | **REACHABLE** | IV 58.3 / HV 74.0, ratio 0.79 · ADV $7,176.6M | A-queue |
| 10 | **TTWO** | Bullish | **GTA VI launches 2026-11-19 (C)**, reaffirmed by CEO Zelnick in early August. The single largest dated product catalyst in the window, and **unaffected by either AI objection class**. Close 239.62 | **Product launch 2026-11-19 (C)**; trailer 08-27 *(prior-cycle (C), not re-verified)* | **SPENT→NEXT** (launch) | ratio 1.40 — **but measured on the 08-28 expiry, i.e. the TRAILER, not the launch. It is not a read on 11-19 at all** · ADV $215.7M | A-queue |

### 11–20

| # | Ticker | Direction | Supporting public documents | Catalyst (date) | REACH | Measured | Overlap |
|---|---|---|---|---|---|---|---|
| 11 | **CRWV** | Bullish — two-sided by construction | Q2 (08-11): revenue **$2.575–2.6B, +112% y/y**; adj op margin ~5% vs ~2.7% expected; **backlog $104B, +246% y/y**; FY26 guide raised to $12.4–13.2B. Simultaneously the strongest demand document and the purest instance of the financing objection — the debt-funded buildout *is* the business model | **Q3 2026-11-09 or 11-16 (!)** | REACHABLE | ratio 0.65 · ADV $1,686.7M | financing objection standing |
| 12 | **MSFT** | Bullish — thesis realised at prior print | Azure/cloud beat closed the prior misalignment; the row is carried for the next print rather than a live gap. Close 483.24, **+23.6%** | Q1 FY27 **2026-10-28 (2S)** | REACHABLE | ratio **0.62 — the lowest on this list** · ADV $8,838.5M | A-queue |
| 13 | **GOOGL** | Bullish | Cloud rev/margin/RPO trend intact; UK CAT class-action certified and assessed NOT a D-breach. Close 344.82, −2.2% | Q3 **2026-10-28 (2S)** | REACHABLE | ratio 0.76 · ADV $5,955.1M | **Open D position** (two tranches) |
| 14 | **AMZN** | Bullish — realised at print | AWS re-acceleration; **the FTC trial is now OUT of window (2027-03-29)**, so this row rests on the print alone. Close 258.63, +4.6% | Q3 **2026-10-29 (2S)**; AWS re:Invent 11-30→12-03 (C) | REACHABLE | ratio 0.66 · ADV $6,100.1M | **Open D position** (two tranches) |
| 15 | **CSCO** | Bullish — metric ratified, price re-rated | FQ4 (08-13) beat both lines — revenue **$17.3B +18% y/y** vs $16.8B consensus, adj EPS **$1.22 vs $1.17** — and **FY2026 AI-infrastructure orders landed at $9.3B, ~4.5× prior year, above the $9B the thesis cited.** Stock fell ~9% on gross margin. **A thesis whose own metric keeps being confirmed while the price falls is being re-rated, not refuted.** Close 111.04, −6.9% | Q1 FY27 **2026-11-11 (2S)** | REACHABLE | ratio 0.95 · ADV $1,233.6M | A-queue |
| 16 | **AMAT** | **Bearish — pattern now 4-deep** | Beats keep landing and the tape keeps selling: FQ2, FQ3, and the 08-13 FQ4 (adj EPS $3.50, revenue +25% y/y to $9.12B) which closed **−5.12%**. Close 492.32, **−14.4% over 30 bars** | Q4 FY26 ~2026-11-12 (E) | REACHABLE | ratio 0.79 · ADV $2,127.7M | A-queue |
| 17 | **DDOG** | **Contested** | The 08-06 customer-concentration objection — a disclosed usage decline from its largest customer, beginning Q3, **on a beat-and-raise** (−19.03%) — remains open and unanswered. Close 235.62, −9.5% | Q3 ~2026-11-05 (E) | REACHABLE | ratio 0.76 · ADV $591.1M | A-queue; objection OPEN |
| 18 | **NTAP** | **NEW to the shortlist — the prior exclusion reason no longer holds** | Still no checkable contract/figure named, which caps it; but it now carries **two first-party dated catalysts** where the prior cycle recorded none | Q1 FY27 09-02 **(C)** → **Q2 FY27 2026-12-01 (C)** | **SPENT→NEXT** — and its next date is the **only** confirmed earnings date in this file beyond 2026-11-24 | not measured | A-queue |
| 19 | **META** | Reframed | Refuted at the Q2 print (−9% on charges); the row rests on the legal catalyst | Q3 **2026-10-28 (2S)**; **UTECA trial Oct 2026 — *(C) prior cycle, NOT re-verified this run*** | REACHABLE | not measured | A-queue |
| 20 | **FSLR** | Bullish — **UPGRADED from #46 on a dated policy catalyst** | **Section 232: a 15% tariff plus a minimum-import-price program on polysilicon and derivatives takes effect 2026-12-04 (C)** — a dated, scheduled policy decision directly favourable to a domestic producer. This is a genuine Entry-criterion-1 catalyst, not a print | **Policy effective 2026-12-04 (C)**; Q3 ~10-29 (E) | REACHABLE ×2 | not measured | — |

### 21–46 (rest tier)

21 **NOW** (Q3 10-28; ratio 0.93, ADV $1,610.6M; sold off with the AI-software cluster 08-17, no name catalyst) · 22 **PLTR** (Q3 11-02; ADV $3,937.0M, **+38.4% over 30 bars**, IV not fetched) · 23 **VRTX** (Q3 11-02 + **povetacicept PDUFA 11-30**; non-AI diversifier) · 24 **NBIS** (Q3 ~11-10; highest-vol name on the queue; financing objection reads across) · 25 **WMT** (Q3 FY27 11-19 (2S); ratio 0.76, ADV $1,487.0M, **−9.7%** — Oppenheimer downgrade, $140 PT withdrawn) · 26 **TGT** (Q3 11-18 (2S); ratio 1.18, ADV $306.5M, **+22.8%**; direction SUSPENDED since comps +6% refuted it at the prior print) · 27 **HD** (Q3 ~11-17; bearish/neutral, modest support only) · 28 **MRK** (Q3 10-29 + **three dated PDUFAs: Winrevair 09-21, Welireg+Lenvima 10-04, I-DXd 10-10** — the densest regulatory calendar of any large-cap here) · 29 **LLY** (Q3 10-29; retatrutide BLA slipped to Q1 2027 — a filing date, not a trial or safety event) · 30 **IBM** (Q3 10-21; direction SUSPENDED, documentation row) · 31 **ADBE** (Q3 FY26 09-10 (2S); ratio 1.04, ADV $760.3M, **+19.4%**; bearish, cohort evidence oscillating) · 32 **LMT** (Q3 10-20 (2S)) · 33 **BA** (Q3 10-28 (2S); 777X certification has no fixed date) · 34 **CTVA** (**Vylor spin-off completion target 2026-10-01 (C)** — a dated structural catalyst, new to this list) · 35 **GRAL** (**Galleri PMA advisory panel 2026-09-23 (C)** — a dated binary, but a *recommendation and vote*, not a final decision; ~$3.0B) · 36 **AKAM** (Q3 ~11-05; still no dated contract named) · 37 **TSM** (Q3 10-15 — **NOT A-ELIGIBLE, ADR ruling 2026-08-09**; listed so the exclusion stays visible; open D position unaffected) · 38 **QCOM-adjacent: ON** (Investor Day 09-16 (C)) · 39 **BBIO** (BBP-418 PDUFA 11-27) · 40 **EXEL** (zanzalintinib PDUFA 12-03) · 41 **COGT** (bezuclastinib PDUFA 12-30) · 42 **IONS** (zilganersen PDUFA 09-22 (C)) · 43 **JAZZ** (Ziihera PDUFA 08-25 (C) — **SPENT**) · 44 **GILD** (BIC/LEN PDUFA 08-27 (C) — **SPENT**; anito-cel 12-23 REACHABLE) · 45 **BIIB** (Leqembi IQLIK PDUFA 08-24 (C) — **SPENT**, resolves tomorrow) · 46 **RARE** (UX111 PDUFA 09-19 (C); **~$2.5B, borderline on the cap floor**).

**The SPENT cluster, recorded once rather than ranked into the tail.** These carry live narratives and keep their `Watchlist.md` rows, but every catalyst falls before A could act, and none has a second in-window date: **NVDA** (08-26; ratio 1.50) · **CRM** (08-26; 1.49, open D position) · **CRWD** (08-26; 1.41) · **OKTA** (08-26; 2.26) · **MRVL** (08-27; 1.09) · **PANW** (09-01; 1.56) · **AVGO** (09-02; 1.40, financing objection open) · **SNOW** (09-02; **2.62 — the richest measured premium in this file**) · **HPE** (09-02; 1.63) · **DELL** (09-01; 1.06) · **AAPL** (CEO transition 09-01, unverified; 0.68 — **but its Q4 print 10-29 is REACHABLE**, so AAPL is properly SPENT→NEXT and would rank in the 11–20 band on that basis; it is placed here because its *structural* catalyst, the one the row actually rests on, is the spent one).

---

## PART 2B — Strategy C preliminary ranked shortlist (16 event candidates)

W4 reads this section verbatim.

**CRITICAL ROUTER GATE: C = HYBRID ACTIVATE (FOMC-only)**, resolved 2026-08-05, unchanged and not pending. **Only candidate #1 is router-eligible.** Candidates #2–16 are router-PARKED and carried as divergence context only — **W4 must NOT enqueue thesis-construction on a parked row.** Widening C's scope is reserved to a separate scope-widening adjudication whose conditions (`Strategy.md:1239-1245`) are nowhere near met.

> ### ⚠️ THE FOMC THESIS IS ALREADY ENQUEUED. W4 MUST NOT ENQUEUE IT AGAIN.
>
> `state.open_queue` carries **`thesis-FOMC-C-20260908`** — `PENDING_ANALYSIS`, `item_type=thesis-construction`, `strategy=C`, **`due_date=2026-09-08`**, `artifact_path=Weekly_Catalyst_Calendar.md`, status `pending`. It was enqueued off the prior cycle's PART 2B and **D2 will drain it on 2026-09-08**. Its recorded `conservative_default`: *decline — no entry if unresolved by 2026-09-15 (entry required at least one trading day before the 09-16 decision), or if no affirmative, sourced, quantified divergence from market pricing can be established.*
>
> That default was **corrected on 2026-08-17 by W4** to strip a decline-trigger referencing the retired ≤10% per-name CaR envelope, which would have made a retired constraint a live reason to decline. **Do not re-add a sizing ceiling.** What binds is the recorded seven-factor size justification, the mandatory adversarial attack on size, and C's own defined-risk rail (`total_max_loss = max(closed_form, cascade)` ≤ the thesis's stated risk budget).
>
> **This section's job is therefore not to re-argue the FOMC case. It is to update the inputs the 09-08 session will use.**

### Candidate 1 — FOMC 2026-09-16 (the only router-eligible row)

**Event, re-verified first-party this run:** FOMC meets **September 15–16**, decision **Wednesday 2026-09-16 2:00pm ET**, presser 2:30pm ET, **with a Summary of Economic Projections**. The next meeting (10-27/28) is not SEP-associated and falls outside the window.

#### THE MEASUREMENT THE PRIOR CYCLE SAID WOULD DECIDE THIS HAS NOW BEEN TAKEN

The 2026-08-16 file's honest counter **(c)** was explicit and was the strongest objection on the row:

> *"The SPY measurement is index-level, NOT the FOMC-dated expiry. No ATM-straddle expected move and no September-expiry IV percentile was obtained. The measured claim is 'index vol is cheap,' not 'the September FOMC expiry is cheap.' Those are different claims and the second is not demonstrated."*

**Measured this run, on the dated expiry itself:** SPY **2026-09-18** series — the regular third-Friday September monthly, `regular:true`, the first expiration strictly after the 09-16 decision, **not** a generic nearest-monthly. Spot 765.72, ATM strike 766 (call `891842850`, put `891847740`). **ATM IV 12.1% against 30-bar realised HV 12.5% — ratio 0.97, implied BELOW realised.**

**What this establishes, stated precisely.** The index-level cheapness measured last cycle **does carry through to the FOMC-dated expiry.** Last cycle's index-level reading was ratio 0.98; the dated-expiry reading is 0.97. **The ratio has not changed — what changed is that the correct instrument was measured.** Counter (c) asked whether the cheapness was real *at the expiry that matters*, and the answer is yes.

**What this does NOT establish, and the 09-08 session must not overread it.** Two of counter (c)'s three components remain open:
- **No IV percentile was obtained for the 2026-09-18 series.** "Implied is 3% below trailing realised" is a *different and much weaker* claim than "implied is at the 2nd percentile of its own 52-week range," which is what the prior cycle asserted at the index level. **The dated expiry has not been shown cheap against its own history.**
- **No ATM-straddle expected-move figure was obtained**, so the implied move is not yet expressible in points against the dot-plot dispersion a thesis would need to argue.
- Counter **(d)** also stands untouched: cheap vol has an innocent explanation a thesis must defeat rather than ignore — realised vol has itself been low, breadth is healthy at 70.31%, credit is tight, and **VIX closed Friday at 15.13, down 11.8% over 30 bars.** Vol at a floor in a calm tape is ordinary, not anomalous.

#### The counter that has been retired by the calendar, and it is worth naming

The prior cycle's counter **(b)** was Jackson Hole: *"2026-08-27 → 08-29 falls inside the pre-event window — a scheduled, high-bandwidth opportunity for the Fed to re-anchor expectations before any structure expires. It cuts both ways and no structure can be entered blind to it."* That was correct on 2026-08-16.

**It is no longer the situation.** The enqueued thesis drains **2026-09-08**, ten days *after* the symposium closes. The 09-08 session will construct its thesis **knowing what was said at Jackson Hole** rather than pricing the risk of it. **A named two-sided unknown has become a known input.** Counter (b) is not refuted — it is retired by the passage of time, and the 09-08 session should treat Jackson Hole's content as evidence rather than as risk.

#### A new decision the 09-08 session must make deliberately rather than inherit

| Date | Event | Bearing on a structure entered at the queue's due date |
|---|---|---|
| 2026-09-10 | PPI, August | One day after the earliest entry |
| **2026-09-11** | **CPI, August** | **The largest scheduled input to the 09-16 decision, and it falls INSIDE the holding period of any structure entered on 09-08** |
| 2026-09-15 | Last permissible entry day (C requires entry ≥1 trading day before the event) | — |
| **2026-09-16** | **FOMC decision + SEP** | The event |

**The queue's `due_date` is the earliest date the analysis CAN run, not a requirement to enter that day.** C's entry rule permits any entry up to one trading day before 09-16. **Entering before the 09-11 CPI print is a materially different trade from entering after it, and the difference is not a sizing question.** The prior cycle never had to decide this because its own window ended 09-30 and it was reasoning eight days earlier; the 09-08 session does.

#### The record this candidate is measured against

All four prior FOMC drains resolved **NO-GO** — 2026-04-27, 06-08, 06-15, 07-27 — every one on an inability to document divergence, **not on sizing**. The 07-27 drain, the strongest prior attempt, measured July's FOMC implied vol at **~25–30% over realised** and correctly refused to call that a divergence. **This run measures implied 3% BELOW realised on the dated expiry** — the opposite sign from the setup that was correctly declined. Per the shared **NO-GO records are context, not barriers** rule, that record informs this evaluation and does not pre-empt it.

**Disposition: no new enqueue is needed or permitted — the work is already scheduled for 2026-09-08.** This section hands that session three things it did not have: the dated-expiry measurement (counter (c) substantially closed), the retirement of counter (b), and the CPI-inside-the-window decision. **The first task at 09-08 should now be the IV percentile and straddle expected move for the 2026-09-18 series** — the part of counter (c) still open — rather than re-deriving the cheapness question from scratch.

### Capital and executability — measured

C is **NOMADIC** (`Operating_Protocols.md` §16, owner directive 2026-08-11): no exclusive capital by design, not even a floor; it borrows on demand pro-rata from other enabled strategies' `available_funds` at order-craft time, uncapped. **Measured from `analytics.strategy_nav`:** C NAV **$23.68** / available **$23.68**; donors — **E $15,333.61**, D $0.11, B $0.00. **Reachable ≈ $15,357.40.**

Per the **State provenance** rule: the $15,357.40 is a *sum of measured `available_funds` rows*, **not** a re-run of `fn_nomadic_capital_restore_plan`, which the prior cycle executed and which returned $15,309.94 against donor E. The two agree within $48 (ordinary mark drift). **What is MEASURED is the donor balances; what is INFERRED is that the restore-plan mechanism would still source them.** A 09-08 order-craft session should re-run the restore plan rather than rely on this arithmetic. **"No structure fits at current size" is not an available deferral reason** and has not been since 2026-08-12.

**Overlap with open A positions: none open → no A/C conflict on any candidate.** (Open positions are all Strategy D: AMZN ×2, CRM, DIS ×2, GEV, GOOGL ×2, ISRG, RTX, TSM ×2, UBER.)

### Candidates 2–16 — router-PARKED, divergence context only

Ranked by measured event premium where a measurement exists. **The tenor caveat in PART 2A applies here too and bites harder**, because these expirations range from 5 to 117 days: a 2.62 on a 5-day expiry and a 0.68 on a 33-day expiry are not on the same scale.

| # | Event (ticker) | Type | Date | Measured (IV / HV, ratio) | Note |
|---|---|---|---|---|---|
| **2** | **SNOW** earnings | Earnings | 2026-09-02 **(C)** | **90.3 / 34.4 = 2.62** | **The richest measured premium in this file.** FQ1 +33% AH on the beat plus the $6B AWS commitment; Day-1 +36.48% and held. Close 332.78, +23.9% |
| **3** | **OKTA** earnings | Earnings | 2026-08-26 **(C)** | **116.7 / 51.6 = 2.26** | Second-richest; ADV $200.4M, the thinnest on this list |
| 4 | **HPE** earnings | Earnings | 2026-09-02 **(C)** | 90.2 / 55.4 = 1.63 | Prior quarter +29–37% AH |
| 5 | **PANW** earnings | Earnings | 2026-09-01 **(C)** | 70.2 / 45.0 = 1.56 | Platformisation + CyberArk cross-sell |
| 6 | **NVDA** earnings | Earnings | 2026-08-26 **(C)** | 55.2 / 36.7 = 1.50 | The window's largest unresolved print; ADV $14,323.4M |
| 7 | **CRM** earnings | Earnings | 2026-08-26 **(C)** | 71.3 / 48.0 = 1.49 | Open D position on the name |
| 8 | **CRWD** earnings | Earnings | 2026-08-26 **(C)** | 81.1 / 57.4 = 1.41 | |
| 9 | **AVGO** earnings | Earnings | 2026-09-02 **(C)** | 60.0 / 43.0 = 1.40 | Financing objection open |
| 10 | **NKE** earnings | Earnings | 09-24 or 09-29 **(!)** | 43.8 / 32.6 = 1.34 | |
| 11 | **COST** earnings | Earnings | 2026-09-24 **(C)** | 23.6 / 18.3 = 1.29 | Lowest absolute vol on the list |
| 12 | **ORCL** earnings | Earnings | ~2026-09-08 **(!)** | 74.2 / 60.9 = 1.22 | Date unreconciled a third cycle — a real obstacle to a dated structure |
| 13 | **MRVL** earnings | Earnings | 2026-08-27 **(C)** | 102.1 / 93.6 = 1.09 | |
| 14 | **DELL** earnings | Earnings | 2026-09-01 **(C)** | 91.5 / 86.1 = 1.06 | Date corrected from the prior cycle's 09-03 |
| 15 | **ADBE** earnings | Earnings | 2026-09-10 **(2S)** | 56.5 / 54.1 = 1.04 | |
| 16 | **MU** earnings | Earnings | 09-22 / 09-23 / 09-29 **(!)** | 65.4 / 96.7 = **0.68** | **The only in-window earnings event measured with implied BELOW realised** — but on a 33-day expiry, and across three candidate dates |

**PDUFA candidates, carried without vol measurement this run** (the measurement pass was scoped to equities and index): **BIIB 08-24 (C)** · **JAZZ 08-25 (C)** · **GILD 08-27 (C)** · **TLX 09-11 (C)** · **GSK/zidesamtinib 09-18 (C)** · **RARE 09-19 (C)** · **MRK Winrevair 09-21 (C)** · **IONS 09-22 (C)** · **GRAL panel 09-23 (C)** · **INCY/MIRM 09-26 (C)** · **MRK Welireg 10-04 (C)**. The prior cycle measured RARE at **IV/HV 2.14** — the richest premium it found — on a ~$2.6B sponsor with $0.06B ADV, where thin liquidity was the reason for care rather than dismissal. **No PDUFA name was re-measured this run and none should be assumed to have carried that reading forward.**

---

## Method and coverage notes

**Sources reached this run:** company IR pages and press releases (the primary source for every (C) earnings and PDUFA row), SEC EDGAR filings directly, `federalreserve.gov`, `bls.gov`, `bea.gov`, `fda.gov` meeting notices, the IBKR connector (all price, volume and option measurements), and web/Tavily search. **FMP contributed the bulk earnings calendar to 2026-11-24 and market caps, and nothing else** — `earnings-company`, `quote`, `news`, `secFilings` and `search` are all plan-gated on this tier.

**Sources that failed, recorded so a later cycle does not re-attempt them blind:** `fda.gov`'s live advisory-committee calendar (401 direct, empty JS shell via extract) · MacroMicro (unreachable across five attempts in a prior cycle, not re-attempted here) · several sponsor IR hosts returned 503 during the earnings pass (`ir.crowdstrike.com`, `investors.delltechnologies.com`, `investors.paloaltonetworks.com`, `investors.broadcom.com`) although each was reachable via a second route.

**Measurement provenance.** All IV, HV, close, 30-bar change and ADV figures are live IBKR reads taken this run against the **2026-08-21** close. The per-contract `implied_vol` field was valid for every name but the one strike noted. **A transcription error was caught and corrected in-flight:** an initial 37-call parallel price-history batch could not be reliably attributed back to tickers, and two names (HPE, DELL) were mis-transcribed; **every figure in this file comes from the verified 4-at-a-time re-fetch, not that discarded batch.**

**One free-allowance limit was hit.** The session's `web_search` budget reached 200/200 mid-run; subsequent research used `web_fetch` and Tavily. Metered-call telemetry for this run is written to `ops.web_calls` — **510 rows**, per-call timestamps **bucketed** into each sub-agent's real dispatch→completion window because no MCP layer in this environment returns a server-side call time. That bucketing is stated rather than disguised: three sub-agents reconstructed per-call timestamps that were provably wrong (one batch stamped before the session began, another ~9 hours ahead of the clock), and those were discarded rather than written.

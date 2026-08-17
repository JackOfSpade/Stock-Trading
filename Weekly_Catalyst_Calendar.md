2026-W34

# Weekly Catalyst Calendar — Strategies A and C

Run date **2026-08-16** (Sunday — the `weekly_sun` slot; ISO week **2026-W33** per `state.trading_day_today.today`, which reads `2026-08-16` while the container clock reads 2026-08-17 UTC). Windows measured from the run date: **Strategy A = 6 months (2026-08-16 → 2027-02-16); Strategy C = 45 days (2026-08-16 → 2026-09-30).** The upcoming trading week begins Monday **2026-08-17**, inside this same ISO week — stated in prose deliberately, because the marker is the ISO week of *today*, never the upcoming trading Monday's.

**Marker correction, applied post-write (2026-08-17).** This session's commit did not land until 00:01 MT Monday 2026-08-17 — after the Sunday→Monday ISO-week rollover — so per `scripts/check_cadence_marker.py`'s PERIOD check (which anchors the expected marker on the write/commit time, not the run-date reasoning above) the file's first-line marker is stamped `2026-W34`, one ISO week ahead of the run-date narrative in this section. The run date, regime context, and every window in this file remain anchored to 2026-08-16 as originally written; only the marker label changed, and per this repo's own precedent (`Claude_Task_Plan.md`'s M1b mis-stamp discussion) a marker/content offset like this does not mean the content is stale.

**The marker advances 2026-W32 → 2026-W34 this cycle (not → 2026-W33 as originally reasoned above).** The prior W1 file was written Sunday 2026-08-09, the last day of ISO week 2026-W32. W2's own session crossed the same Sunday→Monday rollover and independently landed on `2026-W34` for this cycle (`W2 Post-Event Screen 2026-W34 (2026-08-17)`, merged 2026-08-17) — so the claim that "W2/W3 stamp 2026-W33 this cycle as well" does not hold; W2 stamped `2026-W34`, and W3 had not yet run this cycle as of this write. W4's upstream-freshness gate treats a marker mismatch as a corroborating, non-fatal signal rather than authoritative proof (`Claude_Task_Plan.md`, "WHY THE MARKER CANNOT BE THE PROOF ON ITS OWN"), so this divergence does not block W4.

**Catch-up window.** `state.routine_catchup_window` for W1: `window_start_ts` = 2026-08-09, `never_completed = false`, `window_days = 7.86`. Below the weekly 1.5× threshold (10.5 days), so **no `CATCHUP[]` token** is owed and no missed-period sub-section is needed. The evidence window below is **2026-08-09 → 2026-08-16**.

> **THIS FILE OVERTURNS SEVERAL PRIOR-CYCLE CONCLUSIONS RATHER THAN EXTENDING THEM. The three that matter most:**
>
> 1. **NUVL was ranked #8 in last cycle's A top-10 and #12 on the C shortlist. It is not a listed company** — GSK's acquisition closed **2026-07-15** and the stock was delisted, three weeks *before* it was added. Struck from both lists below, and flagged for removal from the `Watchlist.md` A-queue.
> 2. **Strategy C's capital was swept to $0.00 on 2026-08-12 under a new NOMADIC classification — and that is the opposite of a constraint.** C now borrows on demand, uncapped; **$15,309.94 reachable, measured this run.** The "no structure fits at current portfolio size" deferral argument is retired.
> 3. **The FOMC divergence candidate is, for the first time in this file's record, supported on BOTH legs** — the directional argument *and* a volatility measurement, with **SPY implied vol at the 1st–6th percentile of its 52-week range and below realised** going into an SEP-carrying meeting.
>
> **Five further corrections are carried in place:** the **AVB/EQR merger closes on a point date 2026-08-17** (not "H2 2026") and renames to Vivmark Residential; **Kraft Heinz's spin-off is explicitly PAUSED**, not pending; **Salesforce's disaggregated-revenue change already happened** in Q1 FY2027 and is not a forward catalyst — which bears directly on the `D:CRM` metric-immutability criterion; **Disney's segment change moves Consumer Products *out of Experiences***, correcting how prior cycles framed it; and the **FTC v. Amazon 2027-02-09 trial date is downgraded (C) → unverified** after Amazon's own 10-Q was found to say nothing about a trial.

**Regime context (`state.current_regime`; M1a scored 2026-08-01, unchanged — next scoring 2026-09-01).** Integrative call **"stagflationary shock + hawkish policy"** — growth_momentum **decelerating**, inflation_trend **stable**, policy_stance **hawkish**, risk_sentiment **neutral**, shock_overlay **acute**. Technical plane as of the 2026-08-14 close: SPY_TREND **UP** (776.34 > 50d 748.93 > 200d 705.46), EQUITY_BREADTH **HEALTHY** at **72.76%**, VIX_REGIME **LOW** (14.25, a second consecutive sub-15 week), SUSTAINED_INVERSION **NOT-SUSTAINED** (10Y−2Y +0.51).

**Two axes took real evidence this week and they point opposite ways — recorded for M1a's 2026-09-01 scoring, not adjudicated here.** `growth_momentum = decelerating` was confirmed and arguably strengthened (retail sales −0.6% with the control group's first 2026 decline; UMich 51.0). `inflation_trend = stable` took its first genuinely disinflationary datapoint of the cycle (**core CPI 2.5% y/y — the bottom of the 2.47–2.82% three-quarter band M1a's own text defines**), while core PPI +0.4% m/m cuts the other way. `policy_stance = hawkish` faces a market that has priced the hike tail down by ~30 points in two weeks. **W1 records this; it does not score it.** D2's 2026-08-13 out-of-cycle router review already considered the `policy_stance` axis and **DECLINED** it (all four Strategy.md:698/:700 triggers unmet), and today's D1 explicitly declined to re-raise it. Nothing here reopens that.

**Router state — all five bindings settled 2026-08-05, none pending, no change this week.**

| Strategy | Binding state | Change this cycle |
|---|---|---|
| **A** | **DO-NOT-ACTIVATE** (`div-A-202607-1`) | None |
| **B** | DO-NOT-ACTIVATE (`div-B-202607-1`) | None |
| **C** | **HYBRID ACTIVATE (FOMC-only)** (`div-C-202607-1`) | None |
| **D** | DO-NOT-ACTIVATE (`div-D-202607-1`) | None |
| **E** | ACTIVATE (`div-E-202607-1`) | None |

**Capital state — the single most consequential change in this file, because it INVERTS the framing the last two cycles were written under.**

On **2026-08-12** Strategy C was classified **NOMADIC** (`state.strategy_nomadic_status.is_nomadic = TRUE`) under the 2026-08-11 owner directive (Operating_Protocols.md §13 NOMADIC STRATEGY CAPITAL; schema `bigquery/167`/`168`). Its entire **$9,464.72** was swept to E the same day. C's NAV now reads **$0.00**.

**That $0.00 is not a constraint. It is the mechanism working as designed, and reading it as a constraint would be the easiest error to make against this file.** A nomadic strategy holds no exclusive standing capital *by construction* — "not even a reserve floor" — because it is declared at ≤1 trade/month and would otherwise park idle cash. It **borrows on demand at order-craft time** via `analytics.fn_nomadic_capital_restore_plan`, pro-rata from the non-nomadic capital-enabled donors, **uncapped by its own sweep history**, with size set purely by the AI's ordinary seven-factor risk-budget judgment.

**Measured this run, not assumed:** `fn_nomadic_capital_restore_plan('C', 5000)` → donor **E**, `donor_capacity` **$15,309.94**, `pull_amount` **$5,000**, **`is_fully_funded = TRUE`**, `control_enabled = TRUE`.

| Strategy | NAV | Available funds | Outstanding regime-capital debt | Note |
|---|---|---|---|---|
| A | **$0.00** | $0.00 | **$3,888.45** | Capital-disabled (router DNA) |
| B | $49.30 | $0.18 | $4,925.90 | Capital-disabled; ISRG exit settled 08-12 |
| **C** | **$0.00** | **$0.00** | $0.00 | **NOMADIC — borrows on demand; $15,309.94 reachable** |
| D | $618.53 | $0.11 | $4,376.85 | Capital-disabled; 12 tranches deployed |
| E | **$15,309.94** | **$15,309.94** | $0.00 | The only funded, activated strategy — and C's sole donor |

An external withdrawal of **$3,525.00** was booked against E on 2026-08-11 (pro-rata to NAV, clamped to idle cash).

**Consequence for PART 2A:** unchanged in kind. A is router-blocked *and* capital-disabled at NAV $0.00 with $3,888.45 of regime debt. No A entry is fundable at any size today; both gates lift together and mechanically on `trigger=regime_enable`. The shortlist is a **queue against a future router flip**, ordered by conviction, not a list of presently-executable entries. Next scheduled resolution path: **M1a's 2026-09-01 re-scoring**.

**Consequence for PART 2B — the size-based deferral argument is now retired, and it should stop being written as though it were live.** For several cycles this file's C section leaned partly on "no eligible structure fits the budget at current portfolio size." That argument is dead twice over: **structurally**, by the nomadic mechanism above (executability is bounded by *donor capacity*, not by C's own NAV); and **empirically, predating the mechanism** — C's own most recent drain, `events.decision_log` 2026-07-27, concluded in its own title that **"structures ARE buildable inside budget; no directional divergence established."**

**The binding constraint on C is, and has consistently been, DIVERGENCE — not budget.** All four FOMC drains on record (2026-04-27, 2026-06-08, 2026-06-15, 2026-07-27) resolved **NO-GO**, every one on an inability to document a divergence from market pricing.

**Open positions (for overlap and deconfliction), from `state.current_positions` — 13 tranches across 10 names:**
- **B:** MSCI (07-27). *(`B:ISRG` closed 2026-08-12 on its convergence target at $402.64, so the A/B exclusion list is one name shorter than last cycle.)*
- **D:** AMZN ×2 (07-09, 07-30), GOOGL ×2 (07-09, 07-26), TSM ×2 (07-21, 07-29), DIS ×2 (05-07, 08-05), CRM, GEV, ISRG (07-20), RTX, UBER.
- **No open A or C positions** → no A/C conflict arises on any candidate below.

Strategy.md prohibits **A/B** and **A/C** simultaneous same-name holding; there is **no A/D prohibition**. **Excluded from the A shortlist on the A/B rule: MSCI only.** D holdings may appear on the A shortlist, but a future A activation on one must first run the correlation-bucket check against the open D position — a sizing input, not a bar.

**Operational state, recorded as observed.** `state.trading_enabled` = **TRUE** at the time of this read; `state.system_health.all_green` = **FALSE** with 1 open critical (`trading_halted`, raised 2026-08-16); marks and engine fresh through 2026-08-14; zero firing kill flags. **That pair is an internal disagreement and is recorded rather than resolved — W1 stages nothing and is unaffected either way.** Separately, **W5's 2026-08-16 run HALTED at pre-flight on a de-authorised BigQuery connector** while the §38 marker backfill wrote it into `ops.run_log` as `completed`; already double-alerted (`catchup_refire_blocked`, `run_log_backfill_masked_halt`) and not W1's to repair.

---

## Past-window tape (2026-08-09 → 2026-08-16)

*Facts only, each attributable to a source and a date; sources at foot. Where two sources disagree the disagreement is recorded rather than resolved.*

**The week's defining feature was a two-sided data set — benign inflation early, badly missing demand late — and the rate market took the demand side.** Equities finished up on the week; the Dow did not.

**Inflation (2026-08-12 and 2026-08-13).** July CPI rose **+0.1% m/m**, headline **+3.4% y/y**; **core CPI +0.2% m/m and +2.5% y/y** (BLS, released 2026-08-12). That core reading matters against this system's own record: M1a's 2026-08-01 scoring described core CPI as having "oscillated inside a 2.47–2.82% band for three quarters," February's 2.47% the low — **2.5% is at the bottom of that band, not mid-band.** July PPI final demand was **unchanged at 0.0% m/m, +4.7% y/y**, but **core PPI rose +0.4% m/m**, also +4.7% y/y, with final-demand goods **−0.7%** against services +0.2% (BLS, 2026-08-13). The goods/services split is the honest complication: the headline benefited from the same energy line the Hormuz disruption is pushing the other way.

**Demand (2026-08-14).** Retail sales fell **−0.6% m/m** to $763.6B, **ex-autos −0.3%**, **control group −0.4% — the first monthly decline of 2026** (Census Advance Monthly Retail Trade). Motor vehicles & parts −1.8% and nonstore retailers −2.2% led it. Preliminary August **University of Michigan sentiment printed 51.0** against 54.5–55.0 consensus and 55.2 prior — current conditions 51.8, expectations 50.6, **one-year inflation expectations UP to 4.3%**, five-to-ten-year steady at 3.3% (final due 2026-08-28). Initial claims for the week ended 08-08 were **209,000** against 202,000 consensus and 200,000 prior, though the four-week average was unchanged at 199,000 and continuing claims *fell* 22,000 to 1,777,000. **Contemporaneous coverage attributed both Friday misses to elevated fuel and energy prices from the Hormuz disruption** — the geopolitical shock is now measurably transmitting into US household demand, not only into oil and spreads.

**Equities finished higher but the internals split.** S&P 500 closed **7,785.76**, **+0.36% on the week**, a third consecutive weekly gain after touching all-time highs mid-week; Nasdaq Composite **26,729.16 (+0.14%)**; Dow **53,732.41 (−0.56%**, snapping a two-week streak); Russell 2000 **3,068.42**; SPY **776.34 (+0.40%)**. *(Recorded disagreement: the Russell's weekly percentage reads +1.12% from the FMP price series and +3.15% from a market-recap relay, while both agree the close was 3,068.42. Unreconciled; nothing here rests on it.)* **VIX closed 14.25**, the path running 14.90 → 15.46 → 15.28 → 14.55 → 14.63 → 14.25. *(Recorded disagreement: separate recaps put it "near 14.85" and at "14.63" for the same week; 14.25 is corroborated by two independent dated series and is the figure used.)*

**Friday's single session was itself the week's most legible finding, and it is not about any one name.** Reading the movers as a set: **AMAT −5.12%** *beat* (adj EPS $3.50, revenue +25% y/y to $9.12B) and was sold; **AVGO −5.94%** fell on a Bank of America note flagging a potential **~$370B AI-related debt-financing vehicle**; **AMD +6.50%** rose the same day it priced its **largest-ever USD bond offering ($4.75B, four tranches)** explicitly to fund AI/data-centre capex; **CIFR +7.43%** rose on completing project-level financing for a third data centre; **AAOI +15.53%** and **MXL +10.68%** rose on 800G/1.6T optical demand beats with raised guidance. On one tape the market punished a bellwether for beating, punished a mega-cap for how the buildout is *funded*, and rewarded two names for *issuing debt* alongside a supplier class for real order flow. **The demand side of the AI trade is intact and being paid for; the doubt has migrated to the financing side.** (Moves measured from IBKR regular-session daily bars, D1 2026-08-16.)

**Cross-sectional weighting, same session.** SPY **−0.20%**, equal-weight RSP **+0.02%**, IWM **+0.51%** — the average stock and small caps *outperformed* the cap-weighted index on a day carrying two large negative demand surprises. Total sector dispersion was **1.99pp with 9 of 11 GICS sectors inside ±0.6%**; XLE **+1.39%** the only sector clearing 1%, XLV **−0.60%** the weakest. A double growth-miss met by bidding small caps while selling mega-cap Technology and Health Care reads as **rate-path repricing rather than de-risking**.

**Rates bear-steepened, and the long end is the story.** Friday closes: **2Y 4.17% (−2bp on the week)**, **10Y 4.68% (+3bp)**, **30Y 5.25% (+6bp)** — the curve steepened *through* two large downside growth surprises. The 30-year auctioned during the week at **5.25%, the highest since 2001**. 10Y−2Y **+0.51**; a 24-month lookback finds no inversion at any point.

**September-hike pricing continued to collapse — a third consecutive weekly step down — but the venues disagree about the SHAPE of the tail, not merely its size.** Current target range **3.50–3.75%** (held 2026-07-29, **9–3, all three dissents for a hike**). For the 2026-09-16 decision: **CME-derived (Investing.com pass-through) read twice — 67.7% hold / 32.3% hike (page-stated 2026-08-15) and 69.4% hold / 30.6% hike / 0.0% cut (page-stated 2026-08-17 01:25 EDT, from a 96.335 futures price)**; **Kalshi (relay; direct fetch HTTP 429): 71% hold / 29% hike / 2% cut**; **Polymarket (direct fetch, no page timestamp): 75% hold / ~25% cut / <1% hike**. CME's own page is JS-rendered and exposes no numeric table. **The recordable disagreement is directional:** the two CME-derived reads are stable across two days and price **zero** chance of a cut, Kalshi agrees on a ~29% hike tail, and Polymarket alone puts the tail on the *cut* side. A "54% hike odds" Kalshi-linked headline and a "69% hold / 48% September cut" search summary (internally impossible) are **used nowhere in this file**.

**The three-week trajectory is the point.** Roughly **56–62% hike** on 2026-08-07 readings → **36–43%** in the 2026-08-09 file → **~29–32%** now. Roughly thirty points in two weeks, on data, into **a meeting the Fed's own calendar marks as carrying a Summary of Economic Projections** (verified first-party this run: September **15–16**, SEP-associated; October 27–28 is not, and falls outside the window).

**Credit stayed tight.** HY OAS **271bp as of 2026-08-12** (ICE BofA BAMLH0A0HYM2, dated third-party citation of FRED). **IG OAS: GAP** — the most recent dated reading obtainable was **80bp as of 2026-07-30**, *before* this window; FRED's CSV endpoints returned HTTP 403 on direct pull, so no in-window IG figure is asserted.

**Energy and the shock overlay escalated, and it is now dated forward.** Brent settled **$87.07 on 2026-08-13** (−2% on the day, +4% on the week) and traded **above $88 on 08-14**. WTI settled **+1.42% to ~$82.40** Friday. *(Recorded disagreement: WTI's Friday figure appears as an $81.12 open, "toward $83," and "above $82" across sources; FMP's WTI series is plan-blocked, so no single close is asserted.)* In-window: a Houthi attack on a cargo ship in Bab al-Mandeb (08-11); reporting that **only 10 vessels crossed the Strait of Hormuz** on the referenced Monday (08-12); a US statement that crude exports through Hormuz were near 9 million bpd (08-13); and **two ADNOC tankers struck by drones overnight 08-13/08-14, the third UAE-tanker attack in a week**. Forward-dated and *not* in Friday's close: Treasury Secretary Bessent said the US is preparing **"unprecedented" economic isolation measures against Iran, to be detailed in the coming week**; President Trump said he would "soon" declare the Strait "a territory of the United States"; Iran's deputy foreign ministry rejected both and reaffirmed no negotiations are under way. Israel ran its heaviest strikes on southern Lebanon since the ceasefire framework (08-15/08-16). **The EIA does not expect Middle East production near pre-conflict levels until early 2027.**

**Breadth remains broad and ticked down for the first time in a month.** **72.76%** of S&P 500 constituents closed above their own 200-day SMA on 2026-08-14 (EODData S5TH, source-dated; cross-checked at "72%" by a 2026-08-15 Real Investment Advice piece that independently anchors to the correct 7,785.76 close). **−0.40pp from 73.16 on 08-13**, the first down-tick after a one-month high, still the broadest participation since December 2024.

**No Fed speaker events fell inside the window** — the Fed's own 2026 speeches page lists nothing after Governor Cook's 2026-08-05 Anchorage remarks. **Jackson Hole runs 2026-08-27 to 08-29**, outside this window and inside the next.

---

## PART 1A — Strategy A universe catalyst calendar (6-month window, 2026-08-16 → 2027-02-16)

Universe: US-listed equities, market cap ≥ $2B, 30-day ADV ≥ $10M, with a scheduled catalyst inside the window. Per entry: ticker, name, catalyst type, date, date status, source. **No interpretation in PART 1.**

**Date-status convention, stricter this cycle than last.** **(C) = CONFIRMED** — the *company itself* (IR page, press release, 8-K) or the *deciding authority* (FDA, a court, an agency, an index provider, the Federal Reserve) stated the date. **(E) = ESTIMATED** — a data provider or aggregator carries it. **(T) = TENTATIVE.** **(R) = REPORTED** — a third-party tracker carries it and no primary source could be reached to corroborate.

**Read this before reading any date below.** Nearly every corporate IR site refused a fetch this run — NVIDIA, Tesla, Target, Walmart, Microsoft, JPMorgan, Amazon, Broadcom, Disney, GM, AT&T, Lilly, Ionis, Gilead, Ultragenyx, Jazz and Bristol Myers all returned 403/404/503 or a JavaScript shell with no populated dates. **The consequence is that this cycle achieved almost no company-confirmed upgrades on the earnings leg, and the PDUFA leg is tracker-sourced end to end.** Where the prior cycle carried a date as (C), that status was earned in *that* cycle against sources reachable then; it is **not re-asserted here on this run's evidence**. A date reading (E) or (R) below may well be correct — it simply was not verifiable today, and the file says so rather than inheriting a confidence it did not re-establish.

### 1A.1 — Earnings catalysts

Sorted by date. All rows **(E)** unless marked. Market caps as at the 2026-08-14 close.

| Date | Ticker | Company | Sector | Cap ($B) | Fiscal Q | Status |
|---|---|---|---|---|---|---|
| 2026-08-18 | HD | Home Depot | Cons. Disc. | 337.9 | Q2 FY26 | **(C)** IR page, BMO |
| 2026-08-18 | BIDU | Baidu | Comm. Svcs | 35.3 | Q2 CY26 | **(C)** company PR |
| 2026-08-19 | TGT | Target | Cons. Disc. | 70.2 | Q2 FY26 | (E) two-source |
| 2026-08-19 | LOW | Lowe's | Cons. Disc. | 122.5 | Q2 FY26 | **(C)** PR 2026-08-12, BMO 9am ET |
| 2026-08-19 | TJX | TJX Companies | Cons. Disc. | 168.0 | Q2 FY27 | **(C)** company PR |
| 2026-08-19 | ADI | Analog Devices | Info Tech | 189.7 | Q3 FY26 | **(C)** PR, BMO 7am ET |
| 2026-08-20 | WMT | Walmart | Cons. Staples | 917.3 | Q2 FY27 | **(C)** corporate.walmart.com PR |
| 2026-08-20 | BABA | Alibaba | Cons. Disc. | 282–297 | Q1 FY27 | (E) |
| 2026-08-20 | ROST | Ross Stores | Cons. Disc. | 78.7 | Q2 FY26 | **(C)** PR 2026-08-06, AMC |
| 2026-08-25 | ZM | Zoom Communications | Info Tech | 31.1 | Q2 FY27 | (E) |
| **2026-08-26** | **NVDA** | **NVIDIA** | Info Tech | 5,453.6 | Q2 FY27 | **(E) — two independent providers agree; see note** |
| 2026-08-26 | CRM | Salesforce | Info Tech | 160.7 | Q2 FY27 | (E) two-source |
| 2026-08-26 | OKTA | Okta | Info Tech | 25.6 | Q2 FY27 | **(C)** company PR |
| 2026-08-26 | HPQ | HP Inc. | Info Tech | 27.5 | Q3 FY26 | **(C)** company PR |
| 2026-08-26 | CRWD | CrowdStrike | Info Tech | 220.9 | Q2 FY27 | (E) |
| **2026-08-27** | **MRVL** | **Marvell Technology** | Info Tech | 194.4 | Q2 FY27 | **(C)** investor.marvell.com, 1:45pm PDT |
| 2026-08-27 | WDAY | Workday | Info Tech | 49.1 | Q2 FY27 | (E) |
| 2026-08-27 | DLTR | Dollar Tree | Cons. Disc. | 24.9 | Q2 FY26 | **(C)** |
| 2026-08-27 | DG | Dollar General | Cons. Disc. | 27.2 | Q2 FY26 | **(C)** |
| 2026-08-27 | BBY | Best Buy | Cons. Disc. | 18.2 | Q2 FY27 | (E) |
| 2026-08-27 | BILI | Bilibili | Comm. Svcs | 7.3 | Q2 CY26 | (E) |
| **2026-09-01** | **PANW** | **Palo Alto Networks** | Info Tech | 313.2 | Q4 FY26 | **(C)** company PR |
| 2026-09-01 | NIO | NIO | Cons. Disc. | 11.2 | Q2 CY26 | (E) |
| **2026-09-02** | **AVGO** | **Broadcom** | Info Tech | 1,870 | Q3 FY26 | **(C)** company PR |
| **2026-09-02** | **SNOW** | **Snowflake** | Info Tech | 114.0 | Q2 FY27 | **(C)** company PR |
| 2026-09-02 | HPE | Hewlett Packard Enterprise | Info Tech | 77.7 | Q3 FY26 | **(C)** investors.hpe.com |
| 2026-09-03 | DELL | Dell Technologies | Info Tech | 317.1 | Q2 FY27 | (E) |
| 2026-09-03 | ZS | Zscaler | Info Tech | 29.7 | Q4 FY26 | (E) |
| 2026-09-03 | DOCU | DocuSign | Info Tech | 11.8 | Q2 FY27 | (E) |
| **2026-09-08** | **ORCL** | **Oracle** | Info Tech | 433.6 | Q1 FY27 | **(E) — REVISES the prior cycle's 09-14; see note** |
| 2026-09-10 | ADBE | Adobe | Info Tech | 105.0 | Q3 FY26 | (E) |
| 2026-09-16 | GIS | General Mills | Cons. Staples | 21.0 | Q1 FY27 | (E) |
| 2026-09-17 | DRI | Darden Restaurants | Cons. Disc. | 25.6 | Q1 FY27 | (E) |
| 2026-09-17 | LEN | Lennar | Cons. Disc. | 20.9 | Q3 FY26 | (E) |
| **2026-09-22** | **MU** | **Micron Technology** | Info Tech | 1,104.0 | Q4 FY26 | (E) two-source |
| 2026-09-23 | CTAS | Cintas | Industrials | 79.8 | Q1 FY27 | (E) |
| 2026-09-24 | COST | Costco | Cons. Staples | 426.2 | Q4 FY26 | (E) |
| 2026-09-24 | JBL | Jabil | Info Tech | 38.1 | Q4 FY26 | (E) |
| 2026-09-24 | ACN | Accenture | Info Tech | 108.3 | Q4 FY26 | (E) |
| 2026-09-28 | CCL | Carnival | Cons. Disc. | 38.5 | Q3 FY26 | (E) |
| 2026-09-29 | NKE | Nike | Cons. Disc. | 60.3 | Q1 FY27 | (E) |
| 2026-09-29 | PAYX | Paychex | Industrials | 43.4 | Q1 FY27 | (E) |
| 2026-10-08 | DAL | Delta Air Lines | Industrials | 58.8 | Q3 CY26 | (E) |
| 2026-10-08 | PEP | PepsiCo | Cons. Staples | 192.3 | Q3 CY26 | (E) |
| 2026-10-13 | JPM | JPMorgan Chase | Financials | 972.2 | Q3 CY26 | (E) |
| 2026-10-13 | WFC | Wells Fargo | Financials | 268.5 | Q3 CY26 | (E) |
| 2026-10-13 | GS | Goldman Sachs | Financials | 306.6 | Q3 CY26 | (E) |
| 2026-10-13 | C | Citigroup | Financials | 238.9 | Q3 CY26 | (E) |
| 2026-10-13 | JNJ | Johnson & Johnson | Health Care | 627.4 | Q3 CY26 | (E) |
| 2026-10-14 | BAC | Bank of America | Financials | 457.7 | Q3 CY26 | (E) |
| 2026-10-15 | TSM | Taiwan Semiconductor | Info Tech | 2,211.3 | Q3 CY26 | (E) |
| ~2026-10-15 | PLD | Prologis | Real Estate | 136.7 | Q3 CY26 | (E) extrapolated |
| 2026-10-20 | LMT | Lockheed Martin | Industrials | 140.5 | Q3 CY26 | (E) |
| 2026-10-20 | GE | GE Aerospace | Industrials | 382.2 | Q3 CY26 | (E) |
| 2026-10-20 | GM | General Motors | Cons. Disc. | 78.5 | Q3 CY26 | (E) |
| 2026-10-20 | KO | Coca-Cola | Cons. Staples | 377.4 | Q3 CY26 | (E) |
| 2026-10-20 | NFLX | Netflix | Comm. Svcs | 325.5 | Q3 CY26 | (E) |
| 2026-10-20 | VZ | Verizon | Comm. Svcs | 202.4 | Q3 CY26 | (E) |
| 2026-10-21 | UAL | United Airlines | Industrials | 40.7 | Q3 CY26 | (E) |
| 2026-10-22 | INTC | Intel | Info Tech | 517.0 | Q3 CY26 | (E) |
| 2026-10-22 | F | Ford Motor | Cons. Disc. | 57.3 | Q3 CY26 | (E) |
| 2026-10-22 | NOK | Nokia | Info Tech | 58.2 | Q3 CY26 | (E) |
| ~2026-10-22 | FCX | Freeport-McMoRan | Materials | 95.5 | Q3 CY26 | (E) extrapolated |
| 2026-10-23 | HCA | HCA Healthcare | Health Care | 87.6 | Q3 CY26 | (E) |
| ~2026-10-23 | NEE | NextEra Energy | Utilities | 179.8 | Q3 CY26 | (E) extrapolated |
| 2026-10-27 | V | Visa | Financials | 679.9 | Q4 FY26 | (E) |
| 2026-10-27 | UNH | UnitedHealth Group | Health Care | 364.8 | Q3 CY26 | (E) |
| 2026-10-27 | CARR | Carrier Global | Industrials | 51.8 | Q3 CY26 | (E) |
| 2026-10-27 | PYPL | PayPal | Financials | 52.7 | Q3 CY26 | (E) |
| 2026-10-27 | SOFI | SoFi Technologies | Financials | 23.5 | Q3 CY26 | (E) |
| ~2026-10-27 | SHW | Sherwin-Williams | Materials | 86.7 | Q3 CY26 | (E) extrapolated |
| ~2026-10-27 | AMT | American Tower | Real Estate | 81.8 | Q3 CY26 | (E) extrapolated |
| 2026-10-28 | MSFT | Microsoft | Info Tech | 3,678.6 | Q1 FY27 | (E) |
| 2026-10-28 | GOOGL | Alphabet | Comm. Svcs | 4,186.1 | Q3 CY26 | (E) |
| 2026-10-28 | META | Meta Platforms | Comm. Svcs | 1,502.6 | Q3 CY26 | (E) |
| 2026-10-28 | TSLA | Tesla | Cons. Disc. | 1,351.8 | Q3 CY26 | (E) |
| 2026-10-28 | BA | Boeing | Industrials | 183.1 | Q3 CY26 | (E) |
| 2026-10-28 | T | AT&T | Comm. Svcs | 170.5 | Q3 CY26 | (E) |
| 2026-10-28 | SBUX | Starbucks | Cons. Disc. | 122.8 | Q4 FY26 | (E) |
| 2026-10-28 | FDX | FedEx | Industrials | 79.2 | Q1 FY27 | (E) — see conflict note |
| 2026-10-29 | AAPL | Apple | Info Tech | 4,493.3 | Q4 FY26 | (E) |
| 2026-10-29 | AMZN | Amazon | Cons. Disc. | 2,825.4 | Q3 CY26 | (E) |
| 2026-10-29 | COIN | Coinbase | Financials | 39.2 | Q3 CY26 | (E) |
| 2026-10-29 | RBLX | Roblox | Comm. Svcs | 27.3 | Q3 CY26 | (E) |
| 2026-10-29 | RKT | Rocket Companies | Financials | 41.7 | Q3 CY26 | (E) |
| 2026-10-29 | SIRI | Sirius XM | Comm. Svcs | 9.6 | Q3 CY26 | (E) |
| 2026-10-29 | RIOT | Riot Platforms | Financials | 7.2 | Q3 CY26 | (E) |
| 2026-10-30 | ABBV | AbbVie | Health Care | 440.7 | Q3 CY26 | (E) |
| 2026-10-30 | XOM | Exxon Mobil | Energy | 663.5 | Q3 CY26 | (E) |
| 2026-10-30 | CVX | Chevron | Energy | 398.3 | Q3 CY26 | (E) |
| ~2026-10-30 | LIN | Linde | Materials | 222.5 | Q3 CY26 | (E) extrapolated |
| 2026-11-02 | PLTR | Palantir Technologies | Info Tech | 399.6 | Q3 CY26 | (E) |
| 2026-11-03 | AMD | Advanced Micro Devices | Info Tech | 838.8 | Q3 CY26 | (E) |
| 2026-11-03 | UBER | Uber Technologies | Industrials | 154.6 | Q3 CY26 | (E) |
| 2026-11-03 | PFE | Pfizer | Health Care | 152.7 | Q3 CY26 | (E) |
| 2026-11-03 | SHOP | Shopify | Info Tech | 200.3 | Q3 CY26 | (E) |
| 2026-11-03 | PINS | Pinterest | Comm. Svcs | 15.3 | Q3 CY26 | (E) |
| 2026-11-03 | RIVN | Rivian Automotive | Cons. Disc. | 18.6 | Q3 CY26 | (E) |
| ~2026-11-03 | DUK | Duke Energy | Utilities | 96.6 | Q3 CY26 | (E) extrapolated |
| 2026-11-04 | HOOD | Robinhood Markets | Financials | 85.9 | Q3 CY26 | (E) |
| 2026-11-04 | ET | Energy Transfer | Energy | 72.4 | Q3 CY26 | (E) |
| 2026-11-04 | MGM | MGM Resorts | Cons. Disc. | 11.1 | Q3 CY26 | (E) |
| 2026-11-04 | SNAP | Snap | Comm. Svcs | 9.2 | Q3 CY26 | (E) |
| 2026-11-04 | ROKU | Roku | Comm. Svcs | 23.4 | Q3 CY26 | (E) |
| 2026-11-04 | ETSY | Etsy | Cons. Disc. | 7.6 | Q3 CY26 | (E) |
| 2026-11-05 | MRNA | Moderna | Health Care | 25.1 | Q3 CY26 | (E) |
| ~2026-11-05 | COP | ConocoPhillips | Energy | 152.3 | Q3 CY26 | (E) extrapolated |
| 2026-11-10 | SONY | Sony Group | Cons. Disc. | 142.6 | Q2 FY26 | (E) |
| 2026-11-11 | CSCO | Cisco Systems | Info Tech | 440.2 | Q1 FY27 | (E) |
| 2026-11-12 | DIS | Walt Disney | Comm. Svcs | 185.6 | Q4 FY26 | (E) |

**Three date notes that matter.**
- **NVDA 2026-08-26.** The prior cycle carried this as (E) with an explicit unresolved-date caveat. Two independent providers now agree on 08-26, and **one research pass labelled it CONFIRMED while another explicitly refused that label** because neither reached NVIDIA's own IR page (which returned an empty JS shell). **This file takes the conservative reading: (E), corroborated by two sources, not (C).** The caveat is narrowed, not removed.
- **ORCL 2026-09-08 REVISES the prior cycle's 2026-09-14 (E).** Both are provider estimates; neither is company-confirmed; they disagree by four business days and **the disagreement is recorded rather than averaged**. This matters because ORCL sits in the C 45-day window on one date and comfortably inside it on both — but a C structure's expiration selection depends on which is right.
- **FDX**: one FMP pull returned 2026-09-17 while a second FMP pull and an independent aggregator both returned 2026-10-28. The September row was treated as stale/duplicate and dropped.

**COVERAGE GAP, stated plainly because it is large: December 2026, January 2027 and February 1–16 2027 are essentially uncovered on this leg.** Every calendar-year mega-cap listed above with an October Q3 date (AAPL, MSFT, GOOGL, AMZN, META, JPM, BAC, WFC, GS, C, NFLX, TSM and others) will print again inside this window, as will the January big-bank season and the December-fiscal-quarter closers. **None of those dates could be sourced without fabricating them** — the two FMP endpoints capable of projecting that far (`earnings-company`, `financial-estimates`) are plan-restricted, and the calendar endpoint returned zero rows for Dec/Jan/Feb across two paging attempts. The gap is recorded rather than filled. Coverage is also thin in Utilities (2), Materials (3) and Real Estate (2), all extrapolated.

### 1A.2 — Product launches and product events

| Date | Ticker | Company | Event | Status |
|---|---|---|---|---|
| **2026-08-27, 3:00pm ET** | TTWO | Take-Two / Rockstar | **GTA VI "Extended Look" trailer premiere** | **(C)** rockstargames.com/VI |
| ~September 2026 | AAPL | Apple | Fall iPhone 18 launch event — **no 2026 date posted by Apple**; inferred only from the Sept-9 pattern of 2024 and 2025 | **(E)** apple.com/apple-events |
| **2026-11-19** | TTWO | Take-Two / Rockstar | **Grand Theft Auto VI worldwide launch** | **(C)** rockstargames.com/VI |

*Correction carried from last cycle: the "digital preload 2026-11-12" detail is **not stated on Rockstar's page** and is treated as unverified press reporting, not a company-stated date. Preorders opened 2026-06-25 (announced 06-24) per the same page.*

### 1A.3 — Analyst days, investor days and major industry conferences

| Date | Ticker(s) | Event | Status |
|---|---|---|---|
| **2026-08-27 → 08-29** | — (macro) | **Jackson Hole Economic Policy Symposium**, theme "Financial Innovation: Implications for Payments and Policy" | **(C)** kansascityfed.org |
| **2026-09-15 → 09-17** | CRM | **Dreamforce 2026** (Trailblazer Bootcamp 09-12→09-14) | **(C)** salesforce.com/dreamforce |
| **2026-09-17, 8am–12pm PDT** | INTU | **Intuit 2026 Investor Day**, Mountain View | **(C)** investors.intuit.com |
| **2026-09-22 → 09-24** | QCOM | **Snapdragon Summit 2026** | **(C)** qualcomm.com/company/events |
| **2026-09-23 → 09-24** | META | **Meta Connect 2026** — Zuckerberg keynote 09-23 | **(C)** meta.com/connect |
| **2026-10-18 → 10-21** | MA, V, PYPL, FI, GPN | **Money20/20 USA**, Las Vegas | **(C)** money2020.com |
| **2026-10-25 → 10-28** | ORCL | **Oracle AI World 2026**, Las Vegas — CloudWorld rebranded | **(C)** oracle.com/cloudworld |
| **2026-11-09 → 11-12** | broad tech | Web Summit, Lisbon — startup/VC-skewed, weight lower | **(C)** websummit.com |
| **2026-11-29 → 12-03** | GEHC, HOLX | **RSNA 2026**, Chicago (exhibits through 12-02) | **(C)** rsna.org |
| **2026-11-30 → 12-04** | AMZN | **AWS re:Invent 2026**, Las Vegas | **(C)** aws.amazon.com/events/reinvent |
| **2026-12-12 → 12-15** | BMY, JNJ, REGN, VRTX, GILD, ABBV | **ASH 68th Annual Meeting**, New Orleans — abstract deadline was 2026-08-04; watch the late-breaker list | **(C)** hematology.org |
| **2027-01-06 → 01-09** | broad tech | **CES 2027**, Las Vegas — keynote lineup not yet published | **(C)** ces.tech |
| **2027-01-10 → 01-12** | WMT, TGT, HD, LOW, COST, KR | **NRF 2027: Retail's Big Show**, New York | **(C)** nrfbigshow.nrf.com |
| ~2027-01-11 → 01-14 | LLY, PFE, MRK, BMY, JNJ, AMGN, GILD, VRTX, REGN | **J.P. Morgan Healthcare Conference 2027** — **2027 dates NOT yet published**; inferred from 2025 (Jan 13–16) and 2026 (Jan 12–15) | **(E)** |
| **2027-01-14 → 01-24** | GM, F, STLA | **Detroit Auto Show (NAIAS) 2027** | **(C)** detroitautoshow.com |

*Not in window and recorded so it is not mistakenly sought here: NVIDIA GTC 2027 is 2027-03-15→03-18 (past the 02-16 cutoff); AMD's Advancing AI 2026 already occurred in July 2026.*

### 1A.4 — Regulatory, legal, trade and policy decisions

**Antitrust and courts**

| Date | Ticker | Matter | Body | Status |
|---|---|---|---|---|
| **October 2026** (month only) | META | **UTECA v. Meta Ireland trial** (Spanish broadcasters, unfair competition/dominance) | Spanish court | **(C)** stated in Meta's own 10-Q filed 2026-07-30: "Trial is scheduled for October 2026." Companion case AMI v. Meta Ireland already produced a **~€542M** judgment (2025-11-19), under appeal |
| **2027-02-09** | AMZN | **FTC v. Amazon bench trial** (W.D. Wash. 2:23-cv-01495) | FTC + 18 state AGs | **(E) — DOWNGRADED FROM (C), see note** |
| argument not set | AAPL | **Epic v. Apple** — SCOTUS cert granted (limited scope) 2026-06-30 | US Supreme Court | **(C)** grant date only; Apple 10-Q 2026-07-31 |
| no trial date | AAPL | DOJ v. Apple monopolization (D.N.J.), filed 2024-03-21 | DOJ Antitrust | **(C)** filing date only |
| argument not set | META | FTC v. Meta appeal — notice filed **2026-01-20** | D.C. Circuit | **(C)** appeal-filing date; D.D.C. ruled for Meta 2025-11-18 |
| no hearing date | AAPL | EU DMA Art. 5(4) **€500M** fine, under appeal; Art. 6(4) preliminary findings carry exposure **up to 10% of annual worldwide net sales** | EU Commission / General Court | **(C)** findings dates only |

> **The FTC v. Amazon 2027-02-09 trial date is DOWNGRADED (C) → (E)/unverified, and the downgrade is a real finding.** Last cycle's file carried it as confirmed at rank #22. This run could not corroborate it: the FTC's own case page showed no trial date (most recent visible docket entry 2024-10-31), and **Amazon's 10-Q filed 2026-07-31 contains no occurrence of the word "trial" anywhere in its legal-proceedings disclosure.** `justice.gov` and `courtlistener.com` both returned HTTP 403 on every path, so no docket confirmation was possible either way. The date is not asserted false — it is **no longer asserted true**.

**Sector regulators, trade and policy — all dates below are agency-stated and (C)**

| Date | Ticker(s) | Action | Body |
|---|---|---|---|
| **2026-08-24** | VZ, T, TMUS | Auction 115 (Upper C-Band, 3.98–4.14 GHz, 3,248 licenses) — comments due; reply comments **2026-09-08**; auction itself 2027-04-27 | FCC |
| **2026-08-27** | ALB + battery-recycling sector | **DPAS allocation order: 100% domestic-sales requirement for black mass and tungsten scrap**, effective through 2027 | Commerce/BIS |
| **2026-08-27** | CAT, DE and the importer class | Section 232 — comments due on proposed duties covering **14 additional derivative articles** (trailers, cranes, heat-exchanger parts, welding-machine parts) | Commerce/BIS |
| **2026-08-29** | PCAR, CMI | MY2027+ heavy-duty diesel engine nonconformance-penalty and SCR-inducement rule — comments due | EPA |
| **2026-08-31** | TSLA, GOOGL (Waymo), AMZN (Zoox) | "AV Framework Updates" automated-driving guidance — comments due. NHTSA separately granted Zoox an FMVSS temporary exemption 2026-07-31 | NHTSA |
| **2026-09-11, 5pm ET** | VG | CP2 LNG Expansion (dockets CP26-530/533) — environmental scoping comments due, gating the certificate decision | FERC |
| **2026-09-25** | GOOGL, META, AMZN, MSFT | **Submarine Cable Landing License national-security framework — FINAL RULE EFFECTIVE.** Blanket-licensing option plus mandatory national-security certification for SLTE operators | FCC |
| **2026-12-04, 00:01 ET** | FSLR + solar-module importers | **Proclamation 11052 — Section 232 tariffs and minimum import prices on polysilicon and derivatives TAKE EFFECT.** MIP $21/kg polysilicon, $100/kg ingots/wafers, $0.22/W cells, $0.38/W modules; +15% ad valorem on ingots/derivatives; Japan/Korea/Taiwan/Switzerland/EU capped at a combined 15%, UK 10% | Exec. Office of the President / Commerce |

**International (all open-investigation dates confirmed; none carries a stated decision deadline)** — UK CMA Digital Markets Unit investigations opened **2026-01-23** into **GOOGL** and **AAPL** mobile platforms, **2026-05-14** into **MSFT** business software, plus a **MSFT** consumer-protection case opened **2026-07-27**. The **GOOGL** UK Competition Appeal Tribunal ad-tech opt-out class action (case 1773/7/7/26) is **registered 2026-05-06 (C)**; last cycle's **2026-08-06 certification date could not be re-confirmed** (CAT case-detail pages 404'd) and is carried as **(E)/unverified**.

*Recorded but explicitly failing the ticker test: China MOFCOM's ~2026-08-05/06 drone export-control countermeasures and entity-list addition name no US-listed company ≥$2B and are context only.*

**Coverage gap on this leg, named rather than glossed:** `justice.gov`, `courtlistener.com` and `fcc.gov/news-events` returned HTTP 403 on every path tried, and several large 10-Qs (Alphabet, Visa, Live Nation) truncated before Part II Item 1, so **DOJ v. Google (search and ad-tech remedies), DOJ v. Visa, and DOJ v. Live Nation/Ticketmaster could not be checked for trial dates at all this cycle** despite being highly relevant. No bank-M&A approval order and no dated defense-program award could be confirmed.

### 1A.5 — Restructuring and structural events

**This leg was rebuilt from SEC EDGAR 8-Ks and exhibits directly this cycle** (FMP was locked out, so full-text EDGAR search was the only route) — which makes it the **best-sourced leg in this file**, and it produced three corrections to carried-forward entries. Those are marked **[CORRECTION]**.

| Date | Ticker | Event | Status |
|---|---|---|---|
| **2026-08-17** | **AVB / EQR** | **[CORRECTION]** AvalonBay / Equity Residential all-stock merger of equals **closes on a point date, 2026-08-17** — not the "H2 2026" window carried previously. $52B pro forma equity / $69B EV; AVB holders receive **2.793 EQR shares**; combined company renamed **Vivmark Residential (VMRK)**. Both shareholder votes passed 2026-08-12 with ~90% of outstanding shares | **(C)** 8-K 2026-08-12 (updated close date), 8-K 2026-05-21 (terms) |
| **2026-08-18** | RDDT / AVB | **Reddit joins the S&P 500 before the open, replacing AvalonBay** — the removal is a direct consequence of the row above | **(C)** S&P Dow Jones Indices release, 2026-08-13 18:12 ET |
| **2026-08-20** | CHTR | Charter debt exchange (old notes → new Senior Secured Notes due 2038/2041) — **expiration date**, four days inside the window. Early tender was 2026-08-05. Balance-sheet preparation for the Cox close | **(C)** 8-K 2026-07-23 |
| **2026-08-20** | SUI | Sun Communities joins the S&P MidCap 400 before the open | **(C)** same S&P release |
| **2026-09-01** | AAPL | **CEO transition — John Ternus succeeds Tim Cook** (Cook becomes Executive Chairman); Ternus joins the board the same day | **(C)** board-approved, 2026-04-20 announcement |
| **2026-09-01** | **COP** | **NEW — dual CEO *and* CFO transition.** Andy O'Brien (CFO/EVP Strategy) becomes President & CEO succeeding **Ryan Lance, CEO for 14 years and with COP 40+ years**, who becomes Executive Chair; Konnie Haynes-Welsh becomes SVP & CFO. First print under the new pair is Q3 (~Nov 2026) | **(C)** 8-K 2026-08-11 |
| 2026-09-08 | LULU | CEO transition — Heidi O'Neill appointed CEO | **(T)** secondary aggregator only, not Lululemon-primary |
| **2026-09-30** | WBD / NFLX | "Ticking fee" to WBD shareholders begins if unclosed. **Reconciled with the primary source this cycle:** the Netflix acquisition of Warner Bros. (post-split) at **$27.75/WBD share cash** carries an outside date of **2027-03-04 extendable by up to three months** — which is exactly the "as late as June 2027" the July press report described, so the two accounts agree rather than conflict. WBD's own stockholder vote passed 2026-04-23; DOJ and EC review ongoing; a $16.1B debt-reduction milestone is set for 2026-12-31 | **(C)** 8-K 2026-01-20 + Ex-99.1; ticking fee per CNBC 2026-07-24 |
| **2026-10-01** | **CTVA** | **NEW — Corteva separates into two public companies "on or about 2026-10-01":** Crop Protection retains the Corteva name; the Seed business goes to a new entity, **Vylor**. Financed via a Vylor exchange offer and consent solicitation for EIDP's senior notes, launched 2026-08-06 | **(C)** point date, subject to closing conditions — 8-K 2026-08-06 |
| **2026-10-01** | FLUT | CEO transition — Dan Taylor succeeds Peter Jackson as Group CEO; Jackson leaves the board 09-30 and advises through year-end | **(C)** 8-K 2026-08-05 |
| **2026-10-21** | CSCO | Quarterly dividend $0.42/share, record date 2026-10-02. Buyback authorisation **$8.1B remaining, no stated expiration**; $1.5B repurchased in FQ4 FY26 alone | **(C)** 8-K 2026-08-12 |
| **2026-11-02** | KMB / KVUE | Kimberly-Clark / Kenvue — contractual outside date (walk-away trigger). EV ~$48.7B; KVUE holders receive $3.50 cash + 0.14625 KMB shares. Company-stated close window is **"second half of 2026"**, a window and not a point date; **no shareholder-vote 8-K found through 2026-08-16**, so the vote is still outstanding | **(C)** outside date; **(C) window** per 8-K 2025-11-03 |
| H2 2026, no fixed day | HON | Spin-off of Aerospace Technologies (third leg after Solstice) | **(E)** Honeywell investor release |
| **~early Feb 2027** | **DIS** | **[CORRECTION to the framing carried previously]** Disney's segment realignment moves **Consumer Products out of the Experiences segment** and under Entertainment's leadership — *not* "Consumer Products folds into Entertainment from a standalone line," which mis-stated where it currently sits. Effective **"commencing with our fiscal 2027 reporting"**; first print is the Q1 FY27 10-Q, ~early Feb 2027. **Directly relevant to the open `D:DIS` tranches' metric-immutability invalidation criterion**, whose earliest possible auto-invalidation the position record puts at ~May 2027 | **(C)** 10-Q filed 2026-08-05, period ended 2026-06-27 |
| **2027-03-04** (outside) | WBD / NFLX | Netflix / Warner Bros. outside date, extendable up to three months — straddles the window's end | **(C)** |
| H1 2027 (window) | MKTX / ICE | ICE to acquire MarketAxess all-cash at **$167/share** (33% premium to the 2026-07-29 close); ~$6.0B equity value. MKTX stockholder approval and regulatory clearances outstanding | **(C) window** 8-K 2026-07-30 |
| H2 2027 (window) | UBER | Uber / Delivery Hero cash tender at €41.50/share; $14.8B equity value ($13.7B net of Uber's existing 24.77% stake), plus an SSW Partners carve-out of 14 overlapping markets (~$1.6B). ~€14B bridge financing finalised 2026-08-07. **Close is beyond this window; the regulatory milestones are inside it** | **(C) window** 8-K 2026-07-16 |
| **PAUSED — no date** | **KHC** | **[CORRECTION]** The Kraft Heinz tax-free spin-off into a North American Grocery company and a global-brands remainco — announced 2025-09-02 and carried in prior cycles as pending — **is explicitly paused.** The Q2 FY26 earnings release refers to *"the current pause on work related to the separation."* There is no completion date to calendar | **(C)** Ex-99.1 to the 2026-08-05 earnings 8-K |
| by end-2027 | ZBH | Zimmer Biomet 2025 Restructuring Plan (expanded Dec 2025) — $175M targeted annual pre-tax savings; runs through this window. Distinct from the closed 2019/2021/2023 plans | **(E)** 8-K 2026-08-05 |
| late 2026 → 2027 | BA | 777X FAA certification / first delivery | **(T)** sources disagree; originally targeted Oct 2026 |

> **[CORRECTION] The Salesforce "FY28 disaggregated revenue reporting" item carried in prior cycles has already happened and is not a forward catalyst.** CRM's split into "Agentforce Apps" and "Data 360, Headless Platform & Other" took effect in **Q1 FY2027 (quarter ended 2026-04-30), reported 2026-05-27**. If a genuinely FY28-specific reporting change exists it was not found in the Q1 or Q2 FY27 filings searched. This matters because the `D:CRM` position's invalidation criterion 5 is a metric-immutability clause keyed to Agentforce ARR disclosure changing form — **the change it anticipates has already occurred, and the criterion should be evaluated against that fact rather than against a future date.**

*Completed before the window and recorded so they are not re-flagged as pending: Solstice Advanced Materials (Oct 2025), DuPont/Qnity (Nov 2025), **Global Payments/Worldpay (closed 2026-01-12 — resolving last cycle's explicitly-flagged "unresolved whether the deal has already closed")**, Comcast/Versant (2026-01-05), **Fifth Third/Comerica (2026-02-01)**, BD Biosciences–Waters (2026-02-09), Keurig Dr Pepper–JDE Peet's (Apr 2026), **Honeywell Aerospace/Automation split (2026-06-25)**, **FedEx Freight spin (~2026-06-23/25)**, **Electronic Arts go-private (appears closed 2026-08-04 — confirm the exact date next cycle)**, **GSK/Nuvalent (2026-07-15 — see the correction in PART 2A).***

*No procedural date exists to calendar for **Union Pacific / Norfolk Southern**: the STB placed the revised merger application "in abeyance" pending supplemental data as of 2026-07-22. Re-check the STB docket next cycle rather than carrying it as unresolved.*

---

## PART 1B — Strategy C universe catalyst calendar (45-day window, 2026-08-16 → 2026-09-30)

C's qualifying event types **only**: corporate earnings (company IR), FDA PDUFA (FDA calendar / company disclosure), FOMC (Fed calendar). No interpretation. **Router reminder: only an FOMC-catalyst thesis is router-eligible; everything else here is context.**

### 1B.1 — FOMC

| Event | Detail | Date | Source |
|---|---|---|---|
| **FOMC** | Meeting **2026-09-15/16**, decision **Wednesday 2026-09-16**, **WITH Summary of Economic Projections / dot plot** | **2026-09-16 (C)** | federalreserve.gov FOMC calendar, **fetched first-party this run** |

Remaining 2026–27 meetings off the same page: **2026-10-27/28** (no SEP) · **2026-12-08/09** (SEP) · **2027-01-26/27** (no SEP). **The one FOMC in this window is also the only SEP-carrying meeting before December** — a second, independent source of surprise beyond the rate decision itself.

**Dated macro releases between now and the 09-16 decision** (context for a C thesis, not themselves C-qualifying):

| Release | Period | Date | Note |
|---|---|---|---|
| Import/export prices, housing starts, industrial production | July 2026 | 2026-08-18 | |
| FOMC minutes | 07-28/29 meeting | ~2026-08-19 **(E)** | **Inferred from the standard three-week lag; the Fed page shows minutes dates only for past meetings, so this is NOT confirmed** — carried forward from last cycle with the same caveat |
| PCE / personal income | July 2026 | 2026-08-26 | |
| **Jackson Hole symposium** | — | **2026-08-27 → 08-29 (C)** | Falls inside the pre-event window for any 09-16 structure |
| UMich final | August 2026 | 2026-08-28 | Confirms or revises the 51.0 preliminary |
| Employment Situation | August 2026 | 2026-09-04 | |
| **CPI** | August 2026 | **2026-09-11** | |

**Two full inflation prints, one payroll print, and Jackson Hole land between this file and the decision.**

### 1B.2 — Corporate earnings inside the 45-day window

Same dated set as 1A.1 falling on or before 2026-09-30 — restated for C's convenience, with status carried verbatim: **HD (C)** and **BIDU (C)** 8/18 · **TGT** / **LOW (C)** / **TJX (C)** / **ADI (C)** 8/19 · **WMT (C)** / BABA / **ROST (C)** 8/20 · ZM 8/25 · **NVDA** / CRM / **OKTA (C)** / **HPQ (C)** / CRWD 8/26 · **MRVL (C)** / WDAY / **DLTR (C)** / **DG (C)** / BBY / BILI 8/27 · **PANW (C)** / NIO 9/01 · **AVGO (C)** / **SNOW (C)** / **HPE (C)** 9/02 · DELL / ZS / DOCU 9/03 · **ORCL 9/08 (E, revised from 09-14)** · ADBE 9/10 · GIS 9/16 · DRI / LEN 9/17 · **MU 9/22** · CTAS 9/23 · COST / JBL / ACN 9/24 · CCL 9/28 · NKE / PAYX 9/29.

*CSCO reported 2026-08-13 and is correctly OUT of this window.*

### 1B.3 — FDA PDUFA and regulatory actions (sponsors ≥ $2B) inside the 45-day window

**STATUS WARNING FOR THIS ENTIRE TABLE.** Every sponsor IR site was unreachable this run — `news.bms.com`, `gilead.com/news`, `ir.ionis.com`, `ir.nuvalent.com`, `ultragenyx.com`, `investors.jazzpha rma.com` and `investor.lilly.com` all returned 403/503/DNS failures — and `fda.gov`'s own approval pages returned 401/404. **Every date below is therefore (R) REPORTED from a single tracker (`rttnews.com`), not sponsor-confirmed, even where the prior cycle carried it as (C).** BioPharmaCatalyst has become a parked domain and is no longer usable.

| Date | Ticker | Company (cap) | Drug / indication | Event | Status |
|---|---|---|---|---|---|
| 2026-08-17 | BMY | Bristol Myers Squibb ($130.4B) | Iberdomide, r/r multiple myeloma | NDA PDUFA | **(R)** |
| 2026-08-17 | MRK (+PFE) | Merck | Keytruda ± QLEX + Padcev, cisplatin-eligible MIBC | sBLA, Priority | **(R)** — see the false-approval note below |
| 2026-08-23 | RARE | Ultragenyx ($2.60B) | DTX401 (AAV gene therapy), GSD-Ia | BLA PDUFA | **(R)** |
| **2026-08-24** | **BIIB** | **Biogen (~$30B)** | **Leqembi IQLIK (lecanemab, weekly SC), early Alzheimer's** | **sBLA PDUFA — NEW this cycle** | **(R)** |
| 2026-08-25 | JAZZ | Jazz ($15.90B) | Ziihera + Tevimbra, 1L HER2+ gastric/GEJ | sBLA PDUFA | **(R)** |
| 2026-08-27 | GILD | Gilead ($171.6B) | Bictegravir + lenacapavir, HIV-1 | NDA PDUFA | **(R)** |
| **2026-09-11** | TLX | Telix ($4.03B) | TLX101-Px1, glioma imaging | Resubmitted NDA (CRL resolution) | **(R)** |
| **2026-09-18** | **GSK** *(formerly NUVL)* | GSK plc | Zidesamtinib, ROS1+ NSCLC post-TKI | NDA PDUFA | **(R)** — **sponsor changed; see correction** |
| 2026-09-19 | RARE | Ultragenyx ($2.60B) | UX111, Sanfilippo A | Resubmitted BLA (CRL resolution) | **(R)** |
| **2026-09-21** | MRK | Merck | **Winrevair (sotatercept), PAH label expansion** | sBLA PDUFA | **(R)** — **last cycle WITHDREW this entry as unverifiable; it reappears on the tracker and is carried at (R) only** |
| 2026-09-22 | IONS | Ionis ($9.51B) | Zilganersen, Alexander disease | NDA PDUFA | **(R)** |
| **2026-09-23** | GRAL | GRAIL ($3.03B) | Galleri MCED blood test | **Device PMA advisory panel** (not a drug PDUFA; a panel, not a final decision) | **(R)** |
| **2026-09-26** | INCY / MIRM | Incyte / Mirum ($6.53B) | Zlurgisertib, fibrodysplasia ossificans progressiva | NDA PDUFA — **NEW** | **(R)** |
| **2026-09-30** | **SRRK** | Scholar Rock ($6.40B) | Apitegromab, spinal muscular atrophy | Resubmitted BLA — **NEW** | **(R)** |
| **2026-09-30** | BMY | Bristol Myers Squibb | Camzyos (mavacamten), obstructive HCM **adolescents** | sNDA PDUFA — **NEW, 2nd BMY catalyst in window** | **(R)** |

*Quarter-level only, not date-bounded, so not tradeable as dated events: **TAK** rusfertide (polycythemia vera) and oveporexton (narcolepsy type 1), **ROIV** brepocitinib (dermatomyositis) — all "Q3 2026."*

*Below the $2B floor and excluded, listed so the exclusion is auditable: **CAPR** ($386.6M, deramiocel 08-22 — this was on last cycle's watch list and fails the floor), **ZYME** ($1.78B, Ziihera originator — the catalyst is captured via JAZZ), **BFRI** ($16.6M, 09-28).*

> **A source-integrity note worth preserving.** One fetch of `merck.com` returned a claim that the Keytruda + Padcev MIBC combination had **already been approved on 2026-07-10**. A second, more careful fetch of Merck's actual press-release listing showed nothing past 2026-08-06, contradicting it. **The claim was discarded as a fetch artefact and is used nowhere.** It is recorded here because a plausible-looking false approval, silently accepted, would have deleted a live binary catalyst from this calendar.

### 1B.4 — Beyond-window PDUFAs (2026-10-01 → 2027-02-16), for A-side context only

**CYTK** aficamten/MYQORZO, obstructive HCM, **2026-11-14** · **SMMT** ivonescimab + platinum chemo, EGFR-mut NSCLC post-TKI, **2026-11-14** · **GSK** (formerly NUVL) neladalkib, **2026-11-27** · **VRTX** povetacicept, **2026-11-30** · **BBIO** BBP-418, **2026-11-27** · **COGT** bezuclastinib + sunitinib, **2026-11-30** · **EXEL** zanzalintinib, **2026-12-03** · **AGIO** mitapivat, sickle cell, **2026-11-01** · **MRK** Welireg + Lenvima (RCC) **2026-10-04** and I-DXd (ES-SCLC) **2026-10-10** · **IONS + GSK** bepirovirsen, chronic hep B, **2026-10-26** · **VTRS** phentolamine ophthalmic, presbyopia, **2026-10-17** · **PRAX** relutrigine — **PDUFA EXTENDED from 2026-09-27 to 2026-12-27**, which moves it out of the 45-day window. All **(R)**.

*Recorded correctly as a **filing** date, not a decision: **LLY** retatrutide BLA submission moved to **Q1 2027** for CMC documentation — a timing matter, not a trial or safety event. Could not be re-verified this run (investor.lilly.com 503).*

---

## PART 2A — Strategy A preliminary ranked shortlist (46 candidates)

W4 reads this section verbatim.

**ROUTING — both gates settled, neither lifted.** (i) **Router:** A = **DO-NOT-ACTIVATE**, resolved by `div-A-202607-1` on 2026-08-05 and re-affirmed by D2's declined out-of-cycle review on 2026-08-13. Every name below routes to the `Watchlist.md` A-queue with reason "router gate; queued for next M1 ACTIVATE"; **no thesis-construction is enqueued this cycle.** (ii) **Capital:** A is capital-disabled at **NAV $0.00** with **$3,888.45** of regime-capital debt. Both gates lift together and mechanically on `trigger=regime_enable`. **Next scheduled resolution path: M1a's 2026-09-01 re-scoring.**

Per candidate: (a) hypothesised mispricing direction, (b) supporting public documents, (c) catalyst date, (d) overlap with open positions / the A-queue, (e) tier. Direction is a *preliminary* synthesis hypothesis — full thesis construction (adversarial counter-argument attacking **size as well as direction**; immutable at-entry price target and thesis-completion criteria per Entry criterion 3; the criterion-6 historical-analogue exclusion) happens in W4-scheduled sessions.

> ### CORRECTION — NUVL is struck from this shortlist and from the C shortlist. It is not a listed company.
>
> **GSK's acquisition of Nuvalent closed 2026-07-15** — tender offer at $124.00/share cash, ~$10.6B equity value. **Nuvalent's own 8-K of that date carries items 2.01 (completion of acquisition), 3.01 (delisting notice), 3.03, 5.01 (change in control) and 5.03** — the canonical completed-merger-and-delisting signature, verified first-party against SEC EDGAR by the orchestrator this run, independently of the tracker that surfaced it. A third, independent line corroborates: the **IBKR connector cannot resolve a tradeable NUVL contract at all** — `search_contracts` returns a single stub row on exchange "VALUE" with no options chain, and `get_price_snapshot` returns empty on two routings.
>
> **NUVL was ranked #8 in last cycle's A top-10 and #12 on last cycle's C shortlist, having been added on 2026-08-09 — twenty-five days after the deal closed.** Strategy A requires US-listed common equity (instrument-eligibility rule); Strategy C requires a tradeable option chain. **It satisfies neither, and no thesis on it could ever have been executed.** The two PDUFA catalysts that earned it the ranking are real but now belong to **GSK**: zidesamtinib 2026-09-18 and neladalkib 2026-11-27.
>
> **Action for W4: NUVL also sits on the `Watchlist.md` Strategy A queue and must be removed there.** W1 does not edit Watchlist.md; this is flagged for the routine that does. The queue is the durable artefact, so leaving it would re-seed the error next cycle.

---

### The cross-cutting finding this cycle, stated once here rather than repeated down the table

**A single objection class now attaches to four names on this shortlist, and it has landed on a new one in each of the last three weeks. It is not a price objection and must not be netted against an improved entry price.**

| Date | Name | The objection | Move |
|---|---|---|---|
| 2026-07-27 | **NVDA** | Circular financing — the up-to-$250B backstop for OpenAI's Ohio build; Burry publicly framed it as circular and disclosed an increased short | −4.99% |
| 2026-08-06 | **DDOG** | Customer concentration — a disclosed usage decline from its largest customer, beginning Q3, *on a beat-and-raise* | −19.03% |
| 2026-08-14 | **AVGO** | Funding structure — a BofA note flagging a potential ~$370B AI-related debt-financing vehicle | −5.94% |
| (standing) | **CRWV** | The same objection in its purest form: a debt-funded buildout is the business model | — |

Each attacks the **quality or funding of AI demand**, not its valuation. Friday 2026-08-14 made the pattern legible in one session: the market punished **AVGO** for how the buildout is funded and rewarded **AMD (+6.50%)** the same day for pricing its largest-ever bond ($4.75B) to fund exactly that buildout, while **AAOI (+15.53%)** and **MXL (+10.68%)** rose on real 800G/1.6T order flow with raised guidance. **The demand side is intact and measurably being paid for. The doubt has migrated to the financing side.**

**What follows, and what does not.** It does *not* demote the AI-capex cohort wholesale — the demand documents were re-ratified this week, not weakened. It *does* mean any thesis on NVDA, AVGO, CRWV or DDOG must answer the financing objection **on its own terms** at the next M1 ACTIVATE, and a thesis resting on "the drawdown improved the entry price" is answering a different question. Three of the four already carry that instruction on their `Watchlist.md` rows.

**The second cross-cutting shape, and it is the one that should make a reader uncomfortable: three bellwether beats were sold in five sessions.** **AMAT** beat 08-13 (adj EPS $3.50, revenue +25% y/y to $9.12B) and closed **−5.12%**. **CSCO** beat 08-13 (revenue $17.3B +18% y/y vs $16.8B consensus; adj EPS $1.22 vs $1.17) and fell **~9%**. **AVGO** did not report and fell **−5.94%**. In each case the metric the queued A-thesis actually rests on was *ratified* — CSCO's FY2026 AI-infrastructure orders landed at **$9.3B, ~4.5× prior year and above the $9B the thesis cited** — and the stock fell on a different axis (gross margin 66.3% with a 65–66% FQ1 guide against ~66.1% consensus; WFE expectations; financing). **A thesis whose own metric keeps being confirmed while the price keeps falling is not being refuted — it is being re-rated.** That is a valuation/expectations objection, genuinely distinct from the financing one, and the two must not collapse into a single "AI names are wobbling" read.

---

### TOP-10

| # | Ticker | Direction | Supporting public documents | Catalyst (date) | Overlap |
|---|---|---|---|---|---|
| 1 | **NVDA** | Bullish | Demand re-ratified twice this week by *other companies' documents*: CRWV backlog **$104B, +246% y/y**, and AAOI/MXL optical beats with raised guides. Exclusive SpaceX AI-compute socket (08-05). Measured: **IV 37.2% vs HV 38.8%, ratio 0.96, IV %ile only 21/26/32** — implied vol is at the low end of its own year going into the window's largest unresolved print | **Q2 FY27 earnings 2026-08-26 (E, two-source)** | A-queue; 07-27 financing objection OPEN |
| 2 | **MRVL** | Bullish | Custom-silicon ramp (Google TPU / Amazon Trainium design-win pipeline); FQ1 record revenue **$2.418B +28% y/y** above guide midpoint, Q2 guided **$2.7B ±5%**. Measured: **IV 78.3% vs HV 94.2%, ratio 0.83, IV %ile 3/40/69** — implied well below realised into a company-confirmed date | **Q2 FY27 earnings 2026-08-27 (C)** | A-queue |
| 3 | **ORCL** | Bullish (deep re-base) | The **~$7B, 10-year DoD software-consolidation award (07-27, initial 5-yr tranche $3.31B)** ratifies the OCI-bookings/RPO thesis *at exactly the layer it predicted*. Measured: **IV 67.9% vs HV 56.4%, ratio 1.20, IV %ile 68/69/82.** Note YTD **−22.3%** — the tape has de-rated it hard against improving bookings | **Q1 FY27 earnings 2026-09-08 (E — revised from 09-14, unreconciled)**; Oracle AI World 10-25→10-28 (C) | A-queue |
| 4 | **CAT** | Bullish — ratified, runway contested | Q2 (08-04): sales **$20.543B +24% y/y** (first quarter above $20B), adj EPS **$8.17 vs ~$6.20** consensus — largest beat in five years — record **$63B backlog**, E&T/power-generation **+29% y/y on data-centre demand**, FY guidance raised. Measured: **IV 36.6% vs HV 58.9%, ratio 0.62 — the cheapest optionality in the top tier** | Q3 earnings ~2026-10-20 (E); Section 232 derivative-duty comments 08-27 | A-queue; valuation-reset caveat flagged at $876.54 |
| 5 | **GEV** | Bullish | Q2 (07-22): revenue $11.1B +22%, **orders +88% to $24.2B**, backlog **$176B** including **116GW of gas-power reservations** and >$5B of 2026 data-centre orders, FY26 guides raised. Measured: **IV 46.6% vs HV 68.1%, ratio 0.68, IV %ile 2/2/20** | Q3 earnings ~2026-10-20 (E) | **Open D position** — correlation-bucket check required, not a bar |
| 6 | **SMCI** | Bullish — **UPGRADED from #44, on document class not price** | FQ4 (08-11): adj EPS **$1.70 vs $1.59**; revenue $11.12B **+93% y/y** (marginally below $11.26B consensus); **FQ1 guided $14.5–15.5B against $11.99B consensus**, adj EPS **$1.01–1.10 against $0.74**, and **FY2027 revenue $65–72B against $54.43B consensus**. Last cycle's row rested on caveated ">$60B orders"; **formal multi-quarter guidance is a materially stronger document class** | Q1 FY27 earnings ~Nov 2026 (E) | A-queue. **Conviction discounted for issuer-quality history — the gap is extraordinary, the source has a record** |
| 7 | **TTWO** | Bullish | **GTA VI launches 2026-11-19 (C)**, confirmed on Rockstar's own page, with an **"Extended Look" trailer premiere 2026-08-27 3:00pm ET (C)** now dated as a separate pre-launch catalyst. Measured: **IV 38.8% vs HV 35.3%, ratio 1.10.** Unaffected by either AI objection class | **Product launch 2026-11-19 (C)**; trailer 08-27 (C) | A-queue |
| 8 | **AVGO** | Bullish — **demoted from #3** | Custom-AI ASIC pipeline + VMware EBITDA per the FQ2 print; **the demand thesis is untouched by this week's news**, which is why the demotion is modest. Counter: −5.94% on the BofA ~$370B AI-debt-vehicle note, the third instance of the financing class. **Measured, and it is a large change: IV 42.7% vs HV 49.2%, ratio 0.87, IV %ile 0/3/19** — last cycle this name measured ratio **1.37** at IV %ile 68/76/88. Its event premium has collapsed to its 52-week floor | **Q3 FY26 earnings 2026-09-02 (C)** | A-queue; financing objection OPEN |
| 9 | **INTC** | Bullish | Q2: revenue **$16.1B +25% y/y** (fastest in 15+ years), **DCAI +59%**, gross margin back to 42%, capex raised >$20B, management "cannot keep up with orders" — unrefuted by any subsequent disclosure. Measured: **IV 62.5% vs HV 83.9%, ratio 0.74.** YTD +183% | Q3 earnings 2026-10-22 (E) | A-queue |
| 10 | **MU** | Bullish — no new name-specific evidence this cycle | The load-bearing evidence remains a *customer's own disclosure*: QCOM's FQ4 guide-down explicitly cited "unprecedented increases in memory pricing." MU moved +2.30% Friday with **no identifiable driver** (D1 recorded it in the no-driver bucket rather than back-fitting one). Measured: **IV 63.5% vs HV 96.4%, ratio 0.66** | **Q4 FY26 earnings 2026-09-22 (E, two-source)** | A-queue; CXMT supply-side counter still open |

### 11–20

| # | Ticker | Direction | Supporting public documents | Catalyst (date) | Overlap |
|---|---|---|---|---|---|
| 11 | **CRWV** | Bullish — **NEW, and two-sided by construction** | Q2 (08-11): revenue **$2.575–2.6B, +112% y/y**, beat; adjusted operating margin ~5% vs ~2.7% expected; **backlog $104B, +246% y/y**; FY26 guide raised to $12.4–13.2B; Q3 guided $3.45–3.6B vs $3.43B. **Simultaneously the strongest demand document of the week and the purest instance of the financing objection** — the debt-funded buildout *is* the business model | Q3 earnings ~Nov 2026 (E) | — (new) |
| 12 | **PANW** | Bullish | Platformisation + CyberArk cross-sell (XSIAM/SASE/Cortex) per the FQ3 print. Measured: **IV 63.6% vs HV 49.6%, ratio 1.28, IV %ile 79/90/95** — implied uncertainty at its 52-week ceiling into a company-confirmed date | **Q4 FY26 earnings 2026-09-01 (C)** | A-queue |
| 13 | **CRWD** | Bullish | Falcon Flex + Charlotte AI net-new-ARR re-acceleration under-modelled at consensus. Measured: **IV 58.2% vs HV 53.7%, ratio 1.08, IV %ile 37/66/82** | Q2 FY27 earnings 2026-08-26 (E) | A-queue |
| 14 | **NOW** | Bullish — ratified at print | Q2 (07-22): revenue **$3.99B +24%**, adj EPS **$0.90 vs $0.76–0.86** consensus, subscription revenue +24.5%, cRPO +21.5%, FY26 guide raised. Measured: **IV 49.2% vs HV 69.2%, ratio 0.71.** YTD −19.5% | Q3 earnings ~2026-10-28 (E) | A-queue |
| 15 | **SNOW** | Bullish — the DDOG objection reads across | FQ1 FY27 +33% AH on the beat plus the **$6B AWS commitment**; Day-1 +36.48% and held. Measured: **IV 68.3% vs HV 52.3%, ratio 1.31, IV %ile 65/61/77** | **Q2 FY27 earnings 2026-09-02 (C)** | A-queue |
| 16 | **CSCO** | Bullish — **reframed; metric ratified, price re-rated** | FQ4 (08-13) beat both lines — revenue **$17.3B +18% y/y** vs $16.8B consensus, adj EPS **$1.22 vs $1.17** — and **FY2026 AI-infrastructure orders landed at $9.3B, ~4.5× prior year, above the $9B the thesis cited.** Stock fell **~9%** on gross margin (66.3%; FQ1 guide 65–66% vs ~66.1% consensus). Measured: **IV 28.8% vs HV 44.3%, ratio 0.65.** **A enters before a catalyst, so this print is spent** — the next A-eligible catalyst is FQ1 FY27 | Q1 FY27 earnings 2026-11-11 (E) | A-queue |
| 17 | **DELL** | Bullish | AI-server backlog conversion: FQ1 FY27 revenue **+88% y/y**, **AI-server revenue +757%**, ISG margin floor visible, FY27 guide raised. Measured: **IV 78.8% vs HV 84.2%, ratio 0.94, IV %ile 44/71/86.** YTD +298.6% | Q2 FY27 earnings 2026-09-03 (E) | A-queue |
| 18 | **AMD** | **Direction CONTESTED** | The 08-03 thesis (MI400 shipped, roadmap risk converted to product) was ratified on product and refuted elsewhere at the 08-04 print. New this week and genuinely two-sided: **+6.50% on 08-14 while pricing its largest-ever USD bond ($4.75B, four tranches) to fund AI capex** — the market rewarding the financing that it punished AVGO for. Measured: **IV 54.2% vs HV 83.3%, ratio 0.65** | Q3 earnings 2026-11-03 (E) | A-queue |
| 19 | **AAPL** | Reframed | The 08-03 read was refuted at print (beat both lines, soft forward guidance drove the reaction); a China Renaissance downgrade to Hold, PT $280, followed on a Q4 guide miss. **The dated structural catalyst is the CEO transition — John Ternus succeeds Tim Cook 2026-09-01 (C)** — a genuine narrative reset, not a print | **CEO transition 2026-09-01 (C)**; Q4 FY26 earnings 2026-10-29 (E); iPhone 18 event ~Sept (E, Apple has posted no date) | A-queue |
| 20 | **INTU** | Bullish — **the demotion from last cycle stands** | **Investor Day 2026-09-17 (C)** is a real, dated, company-confirmed disclosure event and Intuit says the agenda is still to come. But the A-queue row still names no checkable mechanism, which caps how high a dated-event-only row can rank. Measured: **IV 57.2% vs HV 56.9%, ratio 1.01, IV %ile 63/61/78.** YTD **−47.8%** | **Investor Day 2026-09-17 (C)** | A-queue |

### 21–46 (rest tier)

| # | Ticker | Direction | Disposition | Catalyst (date) |
|---|---|---|---|---|
| 21 | MSFT | Bullish — realised at print | Azure +43%, total cloud +27% to $59.3B, revenue $90.01B / EPS $4.74 both beat → +8.5%. Misalignment closed at the print. New: **FCC subsea-cable rule effective 2026-09-25**; UK CMA cases opened 05-14 and 07-27 | Q1 FY27 earnings 2026-10-28 (E) |
| 22 | AMZN | Bullish — realised at print | AWS +36.7% y/y, fastest in 18 quarters; AI run-rate >$25B. **The FTC trial date is DOWNGRADED to (E)/unverified this cycle** — Amazon's own 10-Q says nothing about a trial | FTC bench trial 2027-02-09 **(E, downgraded)**; Q3 earnings 2026-10-29 (E); AWS re:Invent 11-30 (C) |
| 23 | GOOGL | Bullish — realised, legally dated | Post-print capex selloff fully retraced. UK CAT ad-tech class action **registered 2026-05-06 (C)**; the 08-06 certification could not be re-confirmed. CMA mobile investigation open since 01-23 | Q3 earnings 2026-10-28 (E); FCC subsea rule 09-25 (C) |
| 24 | TSM | Bullish — **eligibility unresolved a third cycle** | FY26 growth guide >40% with capex raised — "the cleanest documents-vs-tape divergence in the universe" per the A-queue. **Strategy A's US-listed-common-equity test against an ADR remains unresolved and should be settled before it can rank higher** | Q3 earnings 2026-10-15 (E) |
| 25 | META | Bullish — reframed | The 08-03 bullish thesis was refuted at print (EPS $6.18 vs $7.19 on $2.40B legal + $1.18B layoff charges, −9%); charges now disclosed rather than feared. **New dated legal catalyst: UTECA trial October 2026 (C, month-level, from Meta's own 10-Q)**, alongside a ~€542M AMI judgment under appeal | Meta Connect 09-23 (C); Q3 earnings 2026-10-28 (E); UTECA trial Oct 2026 (C) |
| 26 | PLTR | Direction SUSPENDED — bearish lean REFUTED | The 08-03 print landed: revenue **$1.94B +93% y/y**, beating by ~$124M | Q3 earnings 2026-11-02 (E) |
| 27 | DDOG | **Direction CONTESTED — new objection class** | Beat and raised (revenue $1.12B +36%; EPS $0.65 vs $0.58) and fell **17–19%** on FCF margin 29%→25% *and* a disclosed Q3 usage decline at its largest customer | Q3 earnings ~Nov 2026 (E) |
| 28 | HPE | Bullish | FQ2 FY26 +29–37% after hours on AI-server + GreenLake demand. Measured (external, dated 08-14): **IV 74.2% vs HV 54.0%, ratio 1.37** | **Q3 FY26 earnings 2026-09-02 (C)** |
| 29 | QCOM | Bearish — largely realised | FQ4 guide $2.05 vs $2.35 street citing "unprecedented increases in memory pricing" and handset headwinds. **Next dated catalyst is the product event, not the print** | **Snapdragon Summit 2026-09-22→09-24 (C)** |
| 30 | LMT | Bullish | Q2 (07-23): sales +11%, EPS $7.94, FCF $2.9B, FY26 guide raised, **record $230B backlog including a $35B THAAD multiyear** | Q3 earnings 2026-10-20 (E) |
| 31 | BA | Bullish (recovery) | Q2: revenue $24.6B (+8%) beat with a wider core loss; FCF +$631M ahead of guide; **backlog $715B**. 777X certification genuinely contested across sources | Q3 earnings 2026-10-28 (E); 777X cert late-2026→2027 (T) |
| 32 | MRK | Bullish — **thesis partially restored this cycle** | Last cycle **withdrew** the Winrevair 09-21 PDUFA as unverifiable, weakening the row. It **reappears on the tracker at 2026-09-21 (R)**, joining I-DXd 10-10 and Welireg+Lenvima 10-04. **All three are (R), none sponsor-confirmed** — the row is restored in kind, not in confidence. Measured: IV 23.9% vs HV 28.8%, ratio 0.83, IV %ile 2/1/9 | PDUFAs 08-17, 09-21, 10-04, 10-10 (all R) |
| 33 | VRTX | Bullish (non-AI diversifier) | Q2: revenue $3.33B (+12.45%) beat by ~$110M; EPS $4.73 missed by ~$0.01; **FY26 guide raised to $13.1–13.2B**. Povetacicept **2026-11-30 (R)** | PDUFA 2026-11-30 (R) |
| 34 | CYTK | Bullish | MYQORZO (aficamten) sNDA for obstructive HCM on MAPLE-HCM data, Priority Review | **PDUFA 2026-11-14 (R)** |
| 35 | SMMT | Bullish | Ivonescimab + platinum chemo, EGFR-mutated NSCLC post-TKI, Priority Review | **PDUFA 2026-11-14 (R)** |
| 36 | IONS | Bullish | Zilganersen for Alexander disease, Priority + Breakthrough | **PDUFA 2026-09-22 (R)** |
| 37 | BIIB | Bullish — **NEW** | Leqembi IQLIK — weekly subcutaneous lecanemab for early Alzheimer's. A **delivery-form** extension of an approved franchise, which is a lower-variance binary than a first approval | **sBLA PDUFA 2026-08-24 (R)** |
| 38 | AMAT | Bearish — **pattern now three-deep** | FQ3 (08-13) beat — adj EPS $3.50, revenue +25% y/y to $9.12B — and closed **−5.12%**. Second consecutive print refuting the "China WFE cliff" bear case on fundamentals *and* second consecutive reaction declining to ratify a bullish flip (FQ2 Day-0 −0.89%). **Do not resolve the deferred framing-flip at the next M1 without weighing all three data points** | Q4 FY26 earnings ~Nov 2026 (E) |
| 39 | ADBE | Bearish | Creative Cloud deceleration + Firefly monetisation lag. **Cohort evidence is oscillating, not trending** — 08-06 de-rate then 08-07 re-rate — so it is not durable evidence in either direction; await a name-specific datapoint. Measured (external, 08-14): IV 50.8% vs HV 56.0%, ratio 0.91 | Q3 FY26 earnings 2026-09-10 (E) |
| 40 | HD | Bearish/neutral | FQ1 comps +0.6%, gross margin −75bps, OI −100bps — modest, not decisive, support for housing-turnover starvation. Measured (external, 08-14): IV 29.4% vs HV 28.7%, ratio 1.02 | **Q2 earnings 2026-08-18 (C)** |
| 41 | TGT | Direction SUSPENDED | The queued bearish thesis was refuted at the prior print (net sales $25.4B, **comps +6%**, adj EPS $1.71 vs $1.46, FY sales-growth target doubled to 4%). Measured (external, 08-14): **IV 39.4% vs HV 23.1%, ratio 1.71 — the richest event premium among the near-dated retailers** | Q2 earnings 2026-08-19 (E) |
| 42 | WMT | Bullish — **unratified at three consecutive checkpoints** | FQ1 FY27 revenue $175.7B (+6.1%) in line, Q2 guide ~0.5% below street; then an Oppenheimer downgrade to Perform with the **$140 PT WITHDRAWN**. Measured (external, 08-14): IV 28.3% vs HV 20.7%, ratio 1.37 | **Q2 FY27 earnings 2026-08-20 (C)** |
| 43 | TSLA | Bearish — ratified, documentation row | Q2 landed every bearish leg (GAAP EPS $0.32 miss, operating income −57%, operating margin 1.4%, first negative FCF in 2+ years on record $5.79B capex). **New dated regulatory item: NHTSA AV-framework comments due 2026-08-31 (C)** | Q3 earnings 2026-10-28 (E) |
| 44 | NBIS | Bullish (highest-vol name on the list) | $775M GPU-infrastructure debt (07-17) funding a documented buildout. **The financing objection class reads directly across to this name** | Q3 earnings ~Nov 2026 (E) |
| 45 | IBM | Direction SUSPENDED — documentation row | The 07-22 print confirmed the pre-announced miss and added nothing new | Q3 earnings ~Oct 2026 (E) |
| 46 | FSLR | Bearish/contested — **NEW, and it is a policy row not an earnings row** | **Proclamation 11052's Section 232 polysilicon tariffs and minimum import prices take effect 2026-12-04 00:01 ET (C)** — MIP $21/kg polysilicon, $0.22/W cells, $0.38/W modules, +15% ad valorem on ingots/derivatives. A dated, agency-confirmed repricing of US module input economics on the largest US-listed domestic module maker. **Direction is deliberately left contested**: the same measure raises rivals' costs and First Solar's own | **Tariffs effective 2026-12-04 (C)** |

**Also on the 41-name A-queue and deliberately NOT shortlisted, with reason:** **AKAM** (the $1.8B / 7-year AI-cloud contract is real and checkable, but no dated catalyst inside the window was found this cycle) · **NTAP** and **OKTA** (both A-queue rows name a thematic driver with no checkable contract, deal or figure — nothing to anchor a rank on; OKTA does have a confirmed 08-26 date and measures IV 72.3% vs HV 41.8%, ratio 1.73 externally, so it is a stronger **C**-side row than an A-side one) · **LLY** (retatrutide BLA slipped to Q1 2027 for CMC documentation — a real thesis, but its dated catalyst is now outside the window) · **RDDT** (**deliberately excluded despite a +12.63% week: its S&P 500 inclusion effective 2026-08-18 is mechanical, heavily-arbitraged index flow, which today's D1 independently labelled non-informational. Index-inclusion flow is not a narrative misalignment and does not become one by being large**) · **MSCI** (excluded by the A/B simultaneous-holding rule — the sole name so excluded this cycle).

**Priority-tier composition, characterised honestly.** The top tier remains AI-capex-levered and this file will not pretend otherwise — but **it is now internally split on an axis that did not exist a month ago.** Names whose thesis rests on *demand documents* (NVDA, MRVL, ORCL, CAT, GEV, SMCI, MU) and names that must additionally survive a *financing* objection (AVGO, CRWV, and NVDA on its separate 07-27 count) are no longer the same kind of bet, and the tiering reflects that rather than treating the cohort as one trade. The non-AI diversifiers — **TTWO** on a dated 2026-11-19 launch, **CAT** in its converted data-centre-power form, and the biotech binaries at 34–37 — are unaffected by either objection, and their relative standing improves passively as a result. **NUVL's removal cost the tier its cleanest non-AI diversifier**, which is the real analytical cost of the correction, over and above the embarrassment.

**Changes vs 2026-W32 (2026-08-09), one full cycle apart.**
- **NUVL #8 → STRUCK.** Delisted since 2026-07-15; see the correction box.
- **CSCO #18 → #16, reframed.** Its catalyst *occurred*, the thesis metric was ratified at $9.3B of AI-infrastructure orders, and the stock fell ~9% on gross margin. Ratified metric plus a 9% decline is a re-rating, not a refutation. A enters *before* a catalyst, so this print is spent.
- **SMCI #44 → #6.** Driven by **document class, not price**: caveated ">$60B orders" became formal FY27 guidance of $65–72B against a $54.43B consensus. Conviction discounted for issuer-quality history.
- **CRWV enters at #11** — strongest demand document of the week and purest instance of the financing objection, ranked with the two-sidedness on the row rather than buried.
- **AVGO #3 → #8.** First counter-evidence since being queued, and its **measured event premium collapsed from ratio 1.37 / IV %ile 68-76-88 last cycle to ratio 0.87 / IV %ile 0-3-19 now** — a large, measured change that cuts *against* an event-premium C thesis and *for* cheap optionality.
- **AMAT held bearish at #38, pattern now three-deep**; a dated NOTE was added to its `Watchlist.md` row by today's D2.
- **FSLR enters at #46** on a dated, agency-confirmed tariff effective date — the first purely policy-driven row this shortlist has carried.
- **AMZN's FTC trial date downgraded (C) → (E)**, which weakens the only dated catalyst that row had.
- **MRK's Winrevair PDUFA restored in kind but not in confidence** — reappears at 2026-09-21 as (R) after last cycle withdrew it.
- **MSCI is now the sole A/B exclusion** (ISRG's B position closed 08-12).

---

## PART 2B — Strategy C preliminary ranked shortlist (13 event candidates)

W4 reads this section verbatim.

**CRITICAL ROUTER GATE: C = HYBRID ACTIVATE (FOMC-only)**, resolved 2026-08-05, unchanged and not pending. **Only candidate #1 is router-eligible for a new C entry.** Candidates #2–#13 are router-PARKED (DO-NOT-ACTIVATE) and carried as divergence context only — **W4 must NOT enqueue thesis-construction on a parked row.** Widening C's scope is reserved to a separate scope-widening adjudication whose conditions (Strategy.md:1239-1245) are nowhere near met; restated each cycle so parked names are visibly parked rather than silently omitted.

**SIZING AND EXECUTABILITY — the argument this file used for several cycles is retired.** No flat 2% per-structure budget (retired by Experiment_Parameters rev 18 / Strategy.md Rev 43) and no numeric ceiling at any level (owner directive 2026-08-05). As of 2026-08-12 C is **NOMADIC**: NAV $0.00, no standing capital by design, borrowing on demand at order-craft time. **Measured this run: `fn_nomadic_capital_restore_plan('C', 5000)` → donor E, capacity $15,309.94, fully funded, control enabled.** Every row below is **budget-feasible as a matter of measured mechanism**, not assumption — and "no eligible structure fits at current portfolio size" is no longer an available reason to defer anything.

**Which makes this the operative point for W4, and it is the whole of PART 2B in one paragraph.** C's binding constraint has never actually been budget. Its own last drain says so in its title — 2026-07-27: *"structures ARE buildable inside budget; no directional divergence established."* All four FOMC drains (2026-04-27, 06-08, 06-15, 07-27) resolved **NO-GO**, every one on an inability to document divergence, and the 07-27 drain measured July's FOMC implied vol at only **~25–30% over realised**. **Removing the size constraint removes an excuse, not an obstacle.**

**A live interaction W4 should see, because the two halves were decided independently and nobody has yet put them side by side.** C can now borrow an **uncapped** amount at order-craft time. Its own live pre-mortem carries an **open TIER 1 DEFECT as of today** — AR_orc's `premortem-C-2026-a3` cycle 13 (2026-08-16) upheld exactly one finding as decisive: **the seven-factor size justification has no enforced consequence at the live order gate.** The orchestrator's own words: the sentence *"a size with no recorded justification is not a valid order"* does exist in entry criterion 3(a) — *"The sentence exists. It is not a gate."* An uncapped borrow facility and an unenforced size justification are individually defensible and jointly worth naming. **This is not a blocker** — C's binding state is unchanged and the defect routes to an SL2 auto-revision at cycle 14 — and W1 has no standing to make it one. It is flagged so the first C order crafted after 2026-08-12 is sized with this in view rather than discovering it afterwards.

**Overlap with open A positions: none open → no A/C conflict on any candidate below.**

**MEASURED market data.** IV, HV and IV-percentile figures marked *(IBKR)* are live connector reads taken 2026-08-16 reflecting the 2026-08-14 close. **Field-substitution disclosed:** the populated field is `implied-vol-underlying` (annualised IV of the underlying), **not** the per-contract `implied-vol`, which returned invalid for every symbol; `option-midpoint-iv` returned a constant invalid sentinel throughout and is reported nowhere. Figures marked *(AQ)* are AlphaQuery, page-dated 2026-08-14. **No ATM-straddle expected-move figure was obtained for any candidate** — that needs live option-chain quotes, which were not pulled.

---

### Candidate 1 — FOMC 2026-09-16 (the only router-eligible row), and why it is stronger than any predecessor

**Event, verified first-party this run against federalreserve.gov:** the FOMC meets **September 15–16, 2026**, decision Wednesday **2026-09-16**, and the Fed's own calendar marks it **associated with a Summary of Economic Projections**. The next meeting, October 27–28, is *not* SEP-associated and falls outside the window. **The one FOMC in this window is also the only SEP-carrying meeting before December** — a second, independent source of surprise beyond the rate decision.

**The hypothesised divergence: the market has repriced this meeting by roughly thirty points in two weeks, and what argued the other way has not moved at all.**

*What moved.* Hike pricing ~56–62% (08-07) → 36–43% (08-09) → **~29–32%** now. The driver is two weeks of demand data: retail sales −0.6% with the control group's first 2026 decline, UMich 51.0 against 54.5–55.0, claims 209k against 202k, and **core CPI 2.5% y/y — the bottom of the 2.47–2.82% band M1a's own scoring text defines.**

*What did not move, and this is the substance.*
1. **The dissents stand unretracted.** The July 29 hold was **9–3 with all three dissents for a +25bp hike** — the first time since September 2016 that three members dissented for an identical alternative — and Hammack, Kashkari and Logan each argued publicly on 07-31 for September tightening. **Not one Fed speaker event falls inside 2026-08-09 → 2026-08-16**; the Fed's own speeches page lists nothing after Cook's 2026-08-05 remarks. **The hawkish bloc has been repriced without having said anything.**
2. **The long end sold through the growth misses.** 30Y **+6bp to 5.25%, highest since 2001**, 10Y +3bp, against 2Y −2bp. A market genuinely convinced of a dovish turn does not bear-steepen through two large downside demand surprises.
3. **Inflation expectations rose on the very print that collapsed sentiment** — UMich one-year **4.2% → 4.3%**.
4. **A dated inflationary escalation sits between now and the meeting.** Bessent's "unprecedented" Iran measures are stated to be detailed **in the coming week**, after a third UAE-tanker strike; Hormuz transits are at a fraction of baseline; the EIA does not expect Middle East production near pre-conflict levels until **early 2027**. Core PPI already rose **+0.4% m/m** in July.
5. **Chair Warsh has removed forward guidance** and stated there is no soft inflation target, only a 2 percent target — so nothing pre-commits the September outcome, which is exactly the condition under which a dot plot surprises.

**And — new this cycle, and the reason this row reads differently from its four predecessors — the premium side is now MEASURED, and it points the same way.** **SPY implied volatility sits at the 2nd / 1st / 6th percentile of its own 13 / 26 / 52-week range**, with **IV 11.6% against 11.8% trailing realised — ratio 0.98, implied *below* realised** *(IBKR)*. An independent source dated 2026-08-14 corroborates the direction: **SPY IV 11.9% vs 30-day realised 13.5%, ratio 0.88** *(AQ)*. Two independent measurements, different realised-vol windows, same conclusion: **index optionality is priced near its cheapest in a year going into an SEP-carrying FOMC that the rates market has repriced by thirty points in a fortnight.**

**This is the first time in this file's record that the directional argument and the premium measurement have pointed the same way at the same time.** The 2026-07-27 drain — the strongest prior attempt — died precisely here, measuring July's FOMC implied vol at ~25–30% *over* realised and correctly refusing to call that a divergence. This time implied is at or *below* realised, at a 52-week percentile floor.

**The honest counters, recorded because C's whole record is a record of these winning.**
- **(a) The venues disagree on the direction of the tail.** Two dated CME-derived reads (08-15: 67.7/32.3; 08-17 01:25 EDT: **69.4% hold / 30.6% hike / 0.0% cut** from a 96.335 futures price) are stable and price **zero** chance of a cut; Kalshi agrees at 29% hike. Polymarket puts ~25% on a *cut* and under 1% on a hike. A thesis that "the market underprices a hike" must survive one venue not pricing a hike at all. **On the evidence the CME-derived pair is better grounded** — fully dated, internally consistent across two days, complete breakdown, sourced from an actual futures price — but W1 records this rather than resolving it.
- **(b) Jackson Hole (2026-08-27 → 08-29) falls inside the pre-event window** — a scheduled, high-bandwidth opportunity for the Fed to re-anchor expectations before any structure expires. It cuts both ways and no structure can be entered blind to it.
- **(c) The SPY measurement is index-level, NOT the FOMC-dated expiry.** No ATM-straddle expected move and no September-expiry IV percentile was obtained. **The measured claim is "index vol is cheap," not "the September FOMC expiry is cheap."** Those are different claims and the second is not demonstrated.
- **(d) Cheap index vol has an obvious innocent explanation** a thesis must defeat rather than ignore: realised vol has itself been low, the index is at record highs, breadth is the broadest since December 2024, credit is tight. Vol at a percentile floor in a calm tape is ordinary, not anomalous.

**Disposition: the strongest FOMC setup this file has recorded, and the first where the directional argument and the volatility measurement agree.** W4 should enqueue thesis-construction. **First task for that session, before any directional work: pull the actual September-expiry option complex and establish whether the FOMC-dated expiry is priced consistently with the index-level cheapness measured here** — the gap at (c) is what decides it. If the dated expiry is not cheap, this is a fifth NO-GO and should be recorded as one without embarrassment.

---

### Candidates 2–13 — router-PARKED, divergence context only

| # | Event (ticker) | Type | Date | Hypothesised divergence | Measured | Tier |
|---|---|---|---|---|---|---|
| **2** | **RARE — two binaries on one sponsor** | FDA | **2026-08-23 (R)** and **2026-09-19 (R)** | **The richest measured event premium in the file by a wide margin: IV 136.0% vs HV 63.7%, ratio 2.14, IV %ile 92/96/91** *(IBKR)*. Two confirmed-in-tracker binaries on one ~$2.6B sponsor inside one window — DTX401 (GSD-Ia), then UX111 (Sanfilippo A, a CRL resolution). The premium is *enormous*, and on a name only just above the cap floor with a $0.06B ADV — **thin liquidity is the reason to be careful, not a reason to dismiss the reading** | IV/HV **2.14** *(IBKR)* | **top-5** |
| **3** | **PANW earnings** | Earnings | **2026-09-01 (C)** | **The richest premium among confirmed-date large caps: IV 63.6% vs HV 49.6%, ratio 1.28, with IV %ile 79/90/95 — implied uncertainty essentially at its 52-week ceiling** *(IBKR)* into a company-confirmed print | IV/HV **1.28** | **top-5** |
| **4** | **SNOW earnings** | Earnings | **2026-09-02 (C)** | **IV 68.3% vs HV 52.3%, ratio 1.31, IV %ile 65/61/77** *(IBKR)*. Two-sided: the DDOG largest-customer usage disclosure is a live, dated reason the premium may be *correctly* priced rather than rich | IV/HV **1.31** | **top-5** |
| **5** | **NVDA earnings** | Earnings | **2026-08-26 (E, two-source)** | **The cheap-optionality case, and it got cheaper this week: IV 37.2% vs HV 38.8%, ratio 0.96, IV %ile only 21/26/32** *(IBKR)* — last cycle this measured ~50th percentile. Implied vol is near its own yearly lows into the largest unresolved print in the window | IV/HV **0.96** | **top-5** |
| **6** | **AVGO earnings** | Earnings | **2026-09-02 (C)** | **The largest measured change in the file, and it inverts last cycle's read. IV 42.7% vs HV 49.2%, ratio 0.87, IV %ile 0/3/19** *(IBKR)* — last cycle this name measured ratio **1.37** at IV %ile 68/76/88 and was ranked the *richest* premium on the list. **Its event premium has collapsed to the floor of its 52-week range in one week**, converting it from the best short-premium candidate to a cheap-optionality candidate | IV/HV **0.87** | rest |
| **7** | **MRVL earnings** | Earnings | **2026-08-27 (C)** | **IV 78.3% vs HV 94.2%, ratio 0.83, IV %ile 3/40/69** *(IBKR)* — implied materially below realised into a company-confirmed print on a name whose FQ1 was a record | IV/HV **0.83** | rest |
| **8** | **JAZZ PDUFA** | FDA | **2026-08-25 (R)** | Clean single-outcome binary on a ~$15.9B sponsor. **IV 40.4% vs HV 32.1%, ratio 1.26, IV %ile 84/91/86** *(IBKR)* — a genuinely rich premium into a dated binary, and the highest-percentile FDA row besides RARE | IV/HV **1.26** | rest |
| **9** | **ORCL earnings** | Earnings | **2026-09-08 (E) — date revised from 09-14 and unreconciled** | **IV 67.9% vs HV 56.4%, ratio 1.20, IV %ile 68/69/82** *(IBKR)*. **The date disagreement matters more here than anywhere else in this file** — a C structure's expiration selection depends on which estimate is right, and neither is company-confirmed | IV/HV **1.20** | rest |
| **10** | **OKTA earnings** | Earnings | **2026-08-26 (C)** | **IV 72.3% vs HV 41.8%, ratio 1.73** *(AQ, dated 08-14)* — the richest earnings-event premium measured this cycle on a company-confirmed date. Not IBKR-measured, so the field-substitution caveat does not apply but the percentile is unavailable | IV/HV **1.73** *(AQ)* | rest |
| **11** | **TGT earnings** | Earnings | 2026-08-19 (E) | **IV 39.4% vs HV 23.1%, ratio 1.71** *(AQ)* — richest premium among the near-dated retailers, into a print whose prior quarter refuted the standing bearish framing | IV/HV **1.71** *(AQ)* | rest |
| **12** | **GILD / BMY / MRK PDUFAs** | FDA | **08-27 / 08-17 / 08-17 (all R)** | Mega-cap binaries with the deepest underlying liquidity among the FDA rows, but **all three measure CHEAP-to-neutral and at percentile floors: GILD IV 25.1% vs HV 34.5% ratio 0.73 (%ile 2/1/11); BMY 24.0% vs 29.7% ratio 0.81 (%ile 0/0/9); MRK 23.9% vs 28.8% ratio 0.83 (%ile 2/1/9)** *(IBKR)*. **A dated binary with implied vol at the 1st percentile is either the cheapest optionality in the file or evidence the market does not regard these as binary at all** — the second reading is the more likely one for label-expansion sBLAs on mega-caps, and is why they rank here rather than top-5 | ratios **0.73 / 0.81 / 0.83** | rest |
| **13** | **BIIB PDUFA** | FDA | **2026-08-24 (R)** | Leqembi IQLIK weekly subcutaneous — a **delivery-form** extension of an approved franchise, structurally lower-variance than a first approval. New to the calendar this cycle; **no volatility measurement was taken** | GAP | rest |

**C top-5:** **#1 FOMC 2026-09-16 (the only router-eligible candidate)**, then **RARE** (ratio 2.14 — the richest measured premium in the file), **SNOW** (1.31) and **PANW** (1.28) as the richest *event premiums* on confirmed dates, and **NVDA** (0.96 at IV %ile 21/26/32) as the cleanest *cheap-optionality* case. The two-directional split that appeared last cycle has widened, and **AVGO crossed from one side to the other in a single week** — from ratio 1.37 to 0.87 — which is the most instructive single measurement in this file.

**Operative read for W4 — what changed since 08-09 and why it matters.** **(i)** The FOMC candidate is no longer only a directional argument: **index implied vol is measured at a 52-week percentile floor**, so for the first time both legs of a C divergence thesis point the same way — and the one gap (index-level vs FOMC-dated expiry) is a specific, closeable measurement task rather than an open question. **(ii)** The size-deferral argument is **structurally dead** — C borrows uncapped, $15,309.94 reachable, measured — so a NO-GO this cycle must be argued on divergence alone, and the file has removed the fallback. **(iii)** A name that ranked as the file's richest premium last week now sits at its 52-week floor, which should raise the standard of freshness applied to any carried-forward volatility figure anywhere in this system. **(iv)** One shortlisted name last cycle was **not a listed company**, and neither the A nor the C process caught it for a full cycle.

---

*Shortlists only. Full thesis construction per Strategy.md — adversarial counter-argument attacking size as well as direction; immutable at-entry price target and thesis-completion criteria for A; dual-path max-loss verification and a defined-risk single-expiration structure for C — happens in W4-scheduled sessions.*

*Sources and provenance: federalreserve.gov FOMC calendar (fetched first-party this run); SEC EDGAR (fetched first-party for the Nuvalent 8-K); bls.gov CPI and PPI releases; Census Advance Monthly Retail Trade; University of Michigan Surveys of Consumers; company IR releases and press releases as cited per row; federalregister.gov (the single most reliable external source this run — used for every FCC, EPA, NHTSA, FERC and BIS/Commerce item); gov.uk/cma-cases; catribunal.org.uk; company 10-Q legal-proceedings disclosures (Apple 2026-07-31, Meta 2026-07-30, Amazon 2026-07-31); rttnews.com FDA calendar (tracker-grade, labelled (R) throughout); stockanalysis.com and alphaquery.com; IBKR connector for all (IBKR)-marked volatility measurements.*

***Data-quality disclosures for this run — recorded so a later reader can weigh the numbers correctly.***

1. ***This run lost most of its external research capacity mid-flight, and the disclosure belongs first rather than last.*** *Eight parallel research sub-agents were dispatched across the six catalyst legs plus a volatility measurement pass. **Seven of the eight died simultaneously on a hard session-limit API error**, whose reset was hours beyond this run's own 23:30 America/Denver clamp — a **non-waitable** class under the TRANSIENT-FAILURE rules (same reasoning as the daily-window-quota branch), so no retry ladder was entered against it. All seven were relaunched on a second pass with WebSearch removed from their instructions (**the session's WebSearch budget was separately exhausted**) and re-scoped onto FMP and direct WebFetch; **all seven completed on that pass.** Coverage below reflects what the second pass returned.*
   - ***An unintended consequence worth recording, because it argues against a lazy reading of the failure.*** *Forcing the restructuring leg off FMP and onto **SEC EDGAR full-text search and direct 8-K/exhibit fetches** made it the **best-sourced section in this file** — it is the only leg sourced almost entirely from primary filings, and it is the leg that produced four of the six corrections above. Slower per entry, materially higher quality. The degraded path outperformed the intended one.*
2. ***FMP's request allowance was exhausted mid-run by the parallel agents*** *and returned "Limit Reach" thereafter; separately, its `earnings-company`, `financial-estimates`, `quote`, `technicalIndicators` and per-symbol endpoints returned plan-tier **ACCESS DENIED** throughout. **Consequence: no per-ticker ADV or market-cap screen against the $2B / $10M floors was run this cycle** — market caps in PART 1 come from third-party finance sites and are approximate.*
3. ***The FOMC date, its SEP status, and the Nuvalent delisting are first-party.*** *federalreserve.gov and SEC EDGAR were both fetched directly by the orchestrator. Neither is a relayed figure.*
4. ***Fed-pricing venues disagree on the DIRECTION of the tail*** *— two dated CME-derived reads (08-15, 08-17) and Kalshi put ~29–32% on a hike and 0–2% on a cut; Polymarket, fetched directly but carrying **no page-level timestamp**, puts ~25% on a cut and under 1% on a hike. CME's own page is JS-rendered and exposes no numeric table. A "54% hike odds" headline and a "69% hold / 48% September cut" summary (internally impossible) are **used nowhere**.*
5. ***Volatility data: field substitution disclosed, and two fields are unusable.*** *The IBKR per-contract `implied-vol` returned invalid for every symbol (expected — it prices an option contract, not the underlying stock ID passed), so **`implied-vol-underlying` is what populates every (IBKR) IV figure and every IV/HV ratio in this file**. `option-midpoint-iv` returned a **constant invalid sentinel (−15.87)** for all 23 resolved symbols and is reported nowhere. **No ATM-straddle expected-move figure was obtained for any candidate** — every IV/HV/percentile figure is a proxy for event premium and is labelled as such; no "options imply ±X%" claim appears anywhere in this file.*
6. ***Prices are weekend-stale and 18 of 23 are cached ticks, not official closes.*** *Only CAT, JAZZ, GILD, BMY and MRK returned `is_close: true` (the official 2026-08-14 close). The other 18 returned cached ticks stamped 2026-08-16 20:05 ET to 2026-08-17 01:45 ET, and three drifted materially from the verified RTH close — **MU +3.2%, RARE +1.2%, AMD +0.96%**. Volatility figures are unaffected by this; price levels quoted for those names should be read with the caveat.*
7. ***The entire PDUFA leg is tracker-grade (R), a real downgrade from last cycle's (C) rows.*** *Every sponsor IR site (BMS, Gilead, Ionis, Ultragenyx, Jazz, Lilly, Nuvalent) returned 403/503/DNS failures, fda.gov returned 401/404, and BioPharmaCatalyst is now a parked domain. **A single tracker is the sole source for every FDA date in PART 1B.3 and 1B.4.***
8. ***One fetch returned a false drug approval and was caught.*** *A `merck.com` fetch claimed the Keytruda + Padcev MIBC combination was approved 2026-07-10; a second fetch of Merck's actual release listing showed nothing past 2026-08-06. Discarded as a fetch artefact, recorded here because silently accepting it would have deleted a live binary from the calendar.*
9. ***December 2026 – February 2027 earnings coverage is essentially absent*** *(see PART 1A.1). Utilities, Materials and Real Estate coverage is thin and extrapolated (last-print + ~91 days).*
10. ***Legal-docket coverage failed.*** *justice.gov, courtlistener.com and fcc.gov/news-events returned HTTP 403 on every path; Alphabet's, Visa's and Live Nation's 10-Qs truncated before Part II Item 1. **DOJ v. Google (search and ad-tech remedies), DOJ v. Visa and DOJ v. Live Nation could not be checked for trial dates at all.** The FTC v. Amazon trial date was downgraded (C) → (E) as a direct result.*
11. ***IG OAS: GAP.*** *FRED's CSV endpoints returned HTTP 403 for both series. HY OAS is carried at 271bp dated 2026-08-12 from a dated third-party citation; the only IG figure obtainable was 80bp dated 2026-07-30, **before** this window, so no in-window IG spread is asserted.*
12. ***Sector figures are single-session, not weekly.*** *Every FMP sector-SPDR call returned ACCESS DENIED, so the sector table reflects **2026-08-14 IBKR regular-session bars measured by today's D1**, not weekly SPDR returns. One relayed weekly sector table was rejected because the same summary asserted an S&P close of "7,800" against the confirmed 7,785.76.*
13. ***Analyst price targets are used nowhere in this file*** *— FMP routes returned plan-tier ACCESS DENIED for a third consecutive cycle. No remembered PT figure is carried.*
14. ***Markets were closed at write time*** *(Sunday 2026-08-16). Every price and volatility figure reflects the 2026-08-14 close or a connector cached snapshot; none is a live tick.*

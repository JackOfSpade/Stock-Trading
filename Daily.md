2026-08-20
<!-- d1_scan_through_utc: 2026-08-20T22:45:00Z -->

# Daily Market Development Scan — 2026-08-20 (Thu, MT)

**Scan window:** 2026-08-19 16:30 MT → 2026-08-20 16:45 MT (**24.25 hours — normal daily cadence, no gap**). The prior-run marker `<!-- d1_scan_through_utc: 2026-08-19T22:30:00Z -->` parsed cleanly from the `Daily.md` on disk and cross-checks against that file's own commit at 2026-08-19T22:41:43Z (marker 11.7 minutes before the commit — the prior run stamped its intended completion boundary and committed after; consistent, not drift). `state.routine_catchup_window` reports `window_days = 0.98`, `never_completed = false` — inside the daily cadence, so **no `CATCHUP` token is owed** on this run.

**The window contains exactly ONE completed trading session — Thursday 2026-08-20, today.** `state.trading_day_today` reads `today = 2026-08-20`, `is_trading_day = true`, `last_trading_day = 2026-08-20`, `next_trading_day = 2026-08-21`. Every price, level and percentage in this file is measured from **IBKR regular-session daily bars** (`get_price_history`, `step=ONE_DAY`, `outside_rth=false`), 2026-08-19 close → 2026-08-20 close, unless explicitly labelled otherwise. No close-to-close figure here comes from `get_price_snapshot`. Bars were identified by their own `T13:30:00Z` timestamps, not by array position — and this run had a specific reason to insist on that, recorded in PROCESS NOTES 1.

## TL;DR

- **Exits triggered: none.** Zero mechanical triggers across the union of `state.current_positions` and the live broker book; no thesis-invalidation criterion breached on any of the 13 open D tranches. The book is 100% Strategy D.
- **New entry candidates: none routed. 6 recorded index-only (WMT, WOLF, MRVL, AAP, NDSN, DE — all Strategy B).** B is DO-NOT-ACTIVATE and capital-disabled. **WMT is the cleanest B shape in weeks.** One of the six, MRVL, qualified *yesterday* and yesterday's screen missed it.
- **Add candidates: none flagged.** Three genuine trigger-(a) fires — ISRG, RTX and AMZN's second tranche — the most of any session in the streak, all declined on the **ROUTER**, not on capital and not on merit.
- **Watchlist changes:** add WMT, WOLF, MRVL, AAP, NDSN, DE to the Strategy-B new-entry index; annotate MRNA with today's −23.55% give-back.
- **Regime review: no review.** Default-NO holds, but `growth_momentum` is the closest call it has been in weeks — see REGIME CHECK.
- **Park: KEEP VOO** (MEDIUM, 55 — down from 60), status BOUND.

**Tape — Thursday 2026-08-20 (US cash close).** SPY 769.06 → **762.60 (−0.84%)**; QQQ −0.72%; DIA −1.27%; IWM **−1.34%**; equal-weight RSP **−0.81%**, essentially in line with cap-weight. VIX 14.89 → **16.01 (+7.52%)**, still below its 50-day (16.98) and 200-day (18.50). Nine of eleven GICS sectors lower. USO **+2.77%**, SLV +2.75%, GLD +0.34%. TLT **−0.82%** — long yields *rebounded* despite Wednesday's Treasury buyback expansion. **Yesterday the index barely moved while the interior churned; today the index fell and the interior fell with it.** Sector spread 2.14pp against yesterday's 4.58pp.

---

## DEVELOPMENTS

### 1. Market-wide breaking events

**(a) Iran / Hormuz — ESCALATION on the diplomatic axis, and the day's dominant macro thread.** The ceasefire expired Monday 2026-08-17 and no talks are scheduled. In-window, Trump vowed **"economic warfare"** on Iran and financial penalties for its supporters, while the **UAE was reported suspending trade with Tehran**. Brent traded up more than 2% to around **$93.61** (CNBC live coverage, 04:46 ET), and our own independent measurement has **USO +2.77%** on IBKR regular-session bars. *Sources: CNBC live blog; Reuters via Idaho Business Review (a mid-session 13:02 GMT snapshot put Brent at $91.20, i.e. the intraday path was not monotonic); AP.* Counter-evidence recorded rather than suppressed, and it is the same standing tension as yesterday: Iraq approved new crude export mechanisms starting September 1, and no Hormuz closure or fresh strike was confirmed in-window. **What changed today is rhetoric and third-party trade posture, not physical supply.**

**(b) The Treasury buyback relief was SHORT-LIVED — this is the most important correction to yesterday's file.** Wednesday's announcement at least doubling long-dated buybacks to ≥$4B per operation (effective 2026-09-09) drove yields sharply lower into Wednesday's close. **Thursday they gave it back**: the 10-year "rose back to 4.69%, nearly where it stood early Wednesday before" the announcement (AP). Bessent said in a live CNBC interview Thursday that operations "could be more than $4 billion per issue" and that Treasury has "a big toolkit," and the department is going to "make a market" in longer-dated securities. It did not hold. Separately and on the same day, **total US public debt crossed $40 trillion for the first time** ($40.05T as of Tuesday per the Treasury), roughly four and a half years after crossing $30T. *Sources: AP; CNBC; Reuters/Euronews.* One strategist quoted in the coverage likened the buyback to rearranging deckchairs. **A funding-mechanics fix did not retire a fiscal concern, and the bond market said so within one session.**

**(c) Tariffs — Canada, and it moved TWO different complexes.** The 50% Section 338 tariffs on ~$20B of Canadian goods remain delayed by the 2026-08-18 proclamation to a new deadline of **00:01 ET 2026-08-22**; negotiations continued Thursday with both sides describing only "progress" and no deal in effect. *Sources: NYT, CBC, Orbitax.* Separately — and this is the part with a price consequence — Bloomberg reported on **2026-08-19** that the US and Canada were **nearing** a deal to roughly halve tariffs on Canadian steel and aluminium to ~25%. The domestic steel complex repriced hard on that report and kept repricing today. See section 3.

**(d) Crypto — a genuine in-window move with an identified, multi-part driver.** Bitcoin- and Ether-linked equities and ETFs rallied across the board (MARA +15.54%, BTBT +13.93%, HIVE +10.99%, ETHA +10.52%, RIOT +8.26%, MSTR +7.81%, COIN +7.58%, BMNR +6.57%, IBIT +6.24% — all IBKR-measured). The driver is a **compounding stack, not one filing**, and it is recorded that way: (i) Wednesday's buyback announcement pulled long yields down overnight and weakened the dollar to a three-month low; (ii) at a **2026-08-19 White House crypto summit** attended by SEC Chair Atkins and CFTC Chair Selig, Trump publicly urged Congress to pass the stalled **CLARITY Act**; (iii) roughly **$1–2.7B of leveraged shorts were liquidated**. BTC and ETH spot are reported up mid-single to low-double digits depending on the outlet's reference point (BTC ~$69–72K, ETH ~$2,251–2,289) — **recorded directionally only, because the sources disagree materially on magnitude and none is the IBKR authority this file measures equities against.** CFTC Chair Selig separately said Thursday the agency is preparing its own crypto rules if Congress does not act. **No XRP spot-ETF approval order or any other discrete regulatory approval was found in-window**, despite several XRP ETFs moving ~15%.

**(e) Nothing else cleared the bar.** No material bankruptcy, disaster, or unscheduled enforcement action with US market-wide impact surfaced in-window.

### 2. Scheduled events that resolved today

**US data — Thursday 2026-08-20, and it split cleanly in two.** All confirmed released today, consistent across Bloomberg, Reuters, Haver, FRED, TradingEconomics and Investing.com:

| Release | Actual | Consensus | Prior |
|---|---|---|---|
| **Philadelphia Fed Manufacturing (Aug)** | **47.4** | **~25** | 41.4 |
| Initial jobless claims (wk ending 08-15) | **206,000** | ~210,000 | 212,000 (revised up) |
| Continuing claims (wk ending 08-08) | 1.799M | ~1.790M | ~1.781M |
| Conference Board LEI (Jul) | **+0.2% m/m** | +0.1% | — |

The Philly Fed print is the outlier of the month — its highest since April 2021, with New Orders 30.1 and Employment 27.9 (highest since April 2022) and Prices Paid 40.9. The LEI's **six-month growth rate turned positive for the first time in over four years**. **Not today's releases, recorded so a later reader does not mis-date them:** S&P Global flash PMIs are scheduled for **Friday 2026-08-21** 09:45 ET, not today; no existing-home-sales print for today was confirmed.

**Fed.** No decision in-window; the July 28–29 minutes were Wednesday 14:00 ET, **pre-window**. September hike odds sit at **32.7% hike / 67.3% hold (CME FedWatch, dated 2026-08-20)** — roughly flat against the ~33–34% priced just before the minutes, and down from ~60–65% three weeks ago. SF Fed's **Mary Daly** said Thursday that policy is "currently in a good place" with no urgent case for a pre-emptive move, and that it is too early to assess how Treasury's buyback strategy affects Fed operations.

**Earnings that resolved in-window (US-listed, market cap ≥ $2B).** Every close below is IBKR regular-session daily bars, measured independently of the sources.

| Name | Print | Result | Close-to-close |
|---|---|---|---|
| **Walmart (WMT)** | Thu 08-20 ~06:00 CT | **Beat AND raised — and fell 9%.** Adj EPS $0.81 vs ~$0.741; revenue $187.9B (+5.9%, +5.1% cc) vs ~$186.6B; op income +28.8%; eCommerce +23%; FY27 guidance raised. **But Walmart U.S. comps ex-fuel +2.6% against +4.6% a year ago — the slowest in more than six years** — and Q3 adj operating income guided **+2.0–4.0% cc against the +17.4% just delivered.** | **−9.15%** (114.30 → 103.84) |
| **Alibaba (BABA)** | Thu 08-20 pre-market | **Mixed.** Revenue RMB268,953M / $39,639M, +9%. **Cloud external revenue +45% YoY and ACCELERATING**; AI-related revenue in its **12th consecutive triple-digit-growth quarter**, ~35% of external cloud. Against that: non-GAAP EPS/ADS $1.26 vs ~$1.94 consensus (a real miss), GAAP EPS/ADS $0.55 with net income −76% YoY on margin-dilutive AI-infrastructure and quick-commerce spend. | **+1.26%** (128.90 → 130.53) |
| **Advance Auto Parts (AAP)** | Thu 08-20 pre-market | **Beat that is not a beat.** Adj EPS $1.03 vs ~$0.81 — **but $0.31 of it is non-recurring tariff refunds.** Revenue $2.0B **missed** ~$2.04B; comps **−0.5%**; FY revenue reaffirmed *below* consensus; store openings cut to 30–35 from 40–45. Company cited "constrained" customer spending. | **−24.55%** (56.18 → 42.39) |
| **Deere (DE)** | Thu 08-20, 09:00 CT call | **Beat and raised.** EPS $5.10 vs ~$4.70; revenue $11.0B vs ~$10.73B; FY26 net income guidance raised to $4.75–5.0B. Construction & Forestry carried by infrastructure and data-centre demand. | **+6.94%** (580.63 → 620.94) |
| **Nordson (NDSN)** | Wed 08-19 **AMC** (resolves in-window) | **Record beat and raise.** Q3 FY26 (ended 07-31): adj EPS $3.25 vs ~$3.09; revenue $817.7M record, +10% YoY, vs ~$779.4M; EBITDA record $262M at 32% margin; **backlog +35%**. FY guidance raised on both lines. | **+8.00%** (309.92 → 334.70) |
| **Wolfspeed (WOLF)** | Wed 08-19 **16:05 ET** (resolves in-window) | **A beat, sold off.** Adj loss **$2.26 vs ~−$2.45** estimate; revenue $149.6M essentially in line and at the company's own guidance midpoint; Q1 FY27 guided $140–160M with gross margin still negative. AI data-centre revenue more than doubled YoY. | **−9.42%** (29.09 → 26.35) |
| **NetEase (NTES)**, **Autohome (ATHM)** | Thu 08-20 pre-market | Both reported. ATHM: net revenue RMB1,198.0M vs RMB1,758.1M YoY (−32%), net income RMB247.8M vs RMB415.7M (−40%). NTES figures carry an unresolved RMB/USD labelling ambiguity across two secondary sources and are **not asserted here**. | not measured |

**EVENT-IDENTITY GATE — three findings, and they cut in different directions.**

1. **ROST is a near-miss and must not be paired with its own print.** Ross Stores released Q2 FY2026 (13 weeks ended 08-01) at approximately **16:00–16:15 ET on 2026-08-20** — inside this scan window, which closes 22:45 UTC, but **at or after the 16:00 ET regular-session close.** So today's measured **−2.43%** is **pre-print positioning, not the reaction to it.** The print itself was strong (EPS $2.66 including ~$0.60/share of tariff refunds against $1.85–1.93 prior guidance; sales $6.26B +13%; comps +10%; FY EPS raised to $8.61–8.77). No outcome-dependent criterion is assessed against ROST's move. This is the identical shape to WOLF one session earlier.
2. **A mis-dated Walmart source was caught and discarded.** A Yahoo Finance article titled "Why Walmart Stock Fell Today" carried revenue +7.3% to $177.8B and EPS $0.66 — figures belonging to Walmart's **Q1 FY27 print of 2026-05-21** (itself a −7.3% session), not today's. It was discarded rather than blended in. Every Walmart figure above is from the company's own release.
3. **FMP's BABA EPS figure does not reconcile and is not used.** The connector returned `epsActual 0.16` for BABA against a 1.94 estimate. Neither the GAAP $0.55 nor the non-GAAP $1.26 per ADS from the primary source matches it. Treated as unreliable rather than resolved.

**FDA / court / M&A.** No PDUFA target action dates fall inside the window (nearest are 08-22, 08-27, 08-28). No court ruling, M&A closing or index rebalance was identified in-window. This sub-sweep received the shallowest search depth of the run and its "none found" is **not** an established-complete negative.

### 3. Large single-name moves — AI-SIGNIFICANCE SCREEN (Operating_Protocols.md §19)

**Layer-1 population rail:** US-listed, market cap ≥ $2B, moved ≥2% close-to-close, attributable to identifiable public events. **127 names measured against IBKR daily bars.** **The enumeration is a bounded sample and is NOT established as complete** — and this run has unusually direct proof of that, since a second measurement pass surfaced three further qualifying names *after* the screen had already been logged (PROCESS NOTES 2). Layer-2 significance judgment decides what is written up; the legacy ≥5% rule runs record-only alongside.

**THE DAY'S EVENT: WALMART.** A mega-cap that beat on both lines, raised full-year guidance, and fell 9.15%. The two figures that explain it both come from the company: US comps at their slowest in more than six years, and a Q3 operating-income guide of +2–4% against +17.4% just delivered. **This is the cleanest sentiment-versus-information divergence on the tape in weeks**, in the most liquid name available, with an unambiguous pre-event anchor at 114.30.

**Written up (Layer-2 SIGNIFICANT):**

| Ticker | Move | Event | Significance | `legacy_rule_pass` (≥5%) | `below_spec_floor` (<5%) |
|---|---|---|---|---|---|
| **WMT** | **−9.15%** (114.30 → 103.84) | Q2 FY27 beat-and-raise sold off on forward deceleration | **75** — the day's defining event and the best-formed B mechanism in weeks | true | false |
| **MRNA** | **−23.55%** (174.38 → 133.32) | **No new event.** Gave back 41.06 of the 111.42 points gained on the 08-19 INTerpath-001 readout, on profit-taking | **75** — the ABSENCE is the information, and it is the first live datapoint on the objection this system logged against MRNA one day ago | true | false |
| **AAP** | **−24.55%** (56.18 → 42.39) | Q2 2026: refund-inflated EPS beat over a revenue miss and −0.5% comps | **60** — largest magnitude of the day, but strip the $0.31 refund and it is a miss, so the move is substantially information-driven | true | false |
| **WOLF** | **−9.42%** (29.09 → 26.35) | Reaction to the **08-19 16:05 ET** FY26 Q4 print: adj loss $2.26 vs −$2.45 (a beat), revenue at guidance midpoint | **60** — a genuine divergence; counterweight is a post-Ch.11 issuer with −19.9% gross margin and ~45.5% short interest | true | false |
| **MRVL** | +5.79% today; **+9.85% on 08-19** (216.00 → 237.27) | **8-K filed 2026-08-19**: Google warrant, 58,970,907 shares at $206.58 (~$12.2B potential stake), against a commercial agreement signed 07-29 | **60** — **the qualifying day was YESTERDAY and yesterday's screen missed it.** Today is a second-day continuation | true | false |
| **NDSN** | **+8.00%** (309.92 → 334.70) | 08-19 AMC record Q3 FY26 beat-and-raise, backlog +35% | **60** — clean, primary-sourced, dated; ~$17.3B cap | true | false |
| **ISRG** | **−5.84%** (397.72 → 374.48) | **NO identifiable in-window event** | **60** — held position, largest decline in the book, and the circulating explanation is provably stale. See RISK below | true | false |
| **DE** | **+6.94%** (580.63 → 620.94) | Q3 FY26 beat-and-raise, FY guidance up | **60** — volume 2.01M against ~795K prior session | true | false |
| **Crypto-proxy complex** | MARA **+15.54%**, BTBT +13.93, HIVE +10.99, RIOT +8.26, MSTR +7.81, COIN +7.58, BMNR +6.57 (equities); ETHA +10.52, IBIT +6.24 (ETFs) | One driver, nine tickers — see Development 1(d) | **60** — logged as ONE item, not nine, to avoid manufacturing breadth. No individual catalyst for any name | true | false |
| **STLD** | −5.20% today; **−7.53% on 08-19**; −12.33% over two sessions | Bloomberg report the US and Canada are **nearing** a deal halving Canadian steel/aluminium tariffs, plus a same-day Jefferies sector cut naming STLD | **60** — **clears the floor and is DECLINED as a B candidate on the EVENT test.** See below | true | false |
| **CRWD** | **−5.60%** (201.63 → 190.34) | **No fresh in-window event.** Only driver is Cantor's 08-19 $725→$250 target cut at a maintained Overweight | **45** — two sessions now total −10.60% with the second unexplained | true | false |
| **IOVA** | **+12.52%** | A **2026-08-20 sell-side price-target cluster** (UBS →$7 confirmed dated), NOT an earnings event | **45** — aggregator framing calling today an earnings reaction is stale; the print is pre-window | true | false |
| **TEM** | **+8.82%** | Second consecutive session, no own event | **45** — continuation of the 08-19 precision-oncology re-rating plus a short squeeze | true | false |
| **RTX** | **−3.66%** (220.35 → 212.29) | **No in-window company event** | **45** — held position; **but yesterday's "unexplained underperformance" read is corrected today**: the whole defense complex fell | false | **true** |
| **Retail complex** | HD −2.85, TJX −2.64, DLTR −2.57, COST −2.45, ROST −2.43, DG −1.41, LOW −1.21, TGT −0.47 vs **KR +0.09** | WMT read-through | **45** — group item; the session's most coherent cross-name message. REGIME-CHECK input | false | **true** |

**Why STLD is declined despite clearing the floor — the most interesting call of the screen.** Strategy B requires a **RESOLVED** public event. This one is not resolved: no primary USTR, White House or Canadian-government source confirms terms or a finalisation date; the report is of a deal being *near*. That reading is independently corroborated by evidence gathered elsewhere in this run — the separate Section 338 Canadian tariffs were still in live negotiation today against a 00:01 ET 08-22 deadline. A market that repriced a ~$33B issuer by 12% on an unconfirmed report of a pending deal is a genuinely interesting object, but "the market may have over-extrapolated an unresolved headline" is a thesis about a **policy outcome**, not the post-event mispricing B is built to trade. The move is also unambiguously sector-wide: NUE −5.85%, CLF −5.98%, CMC −3.97% on 08-19 while Canadian producer ASTL rose **+17.11%** — a policy relative-value trade, not a single-name event. Recorded as context and SL1 ideation evidence.

**Rejected as NOT significant (every ≥5% legacy-rule-passing item declined is listed — §19 requires this floor):** **ONDS −5.84%** — declined on attribution integrity: aggregators attribute a "Q2 earnings miss" but the actual print was **2026-08-13** and was a *beat* with raised guidance; only same-day Form 144 filings are confirmed in-window, which does not carry the magnitude. Market cap also unverified.

**Rejected on the POPULATION RAIL:** CAPR (~$397M), LYTS (~$896M), SPRY (~$500M), CATO (<$100M), GWH (micro-cap). **PLUG's FMP-reported −2.22% is CONTRADICTED** by three independent sources showing it higher; no IBKR bar was pulled, so this system has no authoritative measurement of that move and does not assert one.

**Left UNRESEARCHED, named rather than silently dropped:** CF, TPL, LYB, CBOE, IQVIA and Charter all showed ≥3% moves on an S&P 500 movers screen and have no confirmed driver in this file — a sub-agent budget exhausted before reaching them.

**Screen decision ids (for W2/W5 provenance):** sector-move `219b9142-0e2c-4c4c-a1e0-69abc143b023`; single-name-move `bc9a1f62-b1b7-4f7e-9e3b-cb2bae8abb75`, **superseded append-only by the correction `in_superseded_by=bc9a1f62…`** carrying the three late-surfacing names (PROCESS NOTES 2).

**Strategy-B handoff identity.** Six names carry a qualifying event: **WMT 2026-08-20, AAP 2026-08-20, DE 2026-08-20, WOLF 2026-08-19, NDSN 2026-08-19, MRVL 2026-08-19.** Deterministic identity is `analysis_type='thesis-construction'` + `strategy='B'` + `ticker` + `qualifying_event_date`. Checked against **both open and terminal** `events.queue_events` and against `events.decision_log`: **no existing item carries any of the six four-part identities.** No thesis handoff is created today (B is DO-NOT-ACTIVATE and capital-disabled), so all six are index rows only. No ticker-only deduplication was used anywhere.

### 4. Sector-level moves — AI-SIGNIFICANCE SCREEN (Operating_Protocols.md §19)

All eleven GICS sector ETFs measured from IBKR daily bars. **Four cleared the ≥1% Layer-1 rail; NONE cleared the legacy ≥2% bar** — a session where the old fixed rule would have surfaced nothing at all.

| Sector (ETF) | Close-to-close | Driver | Significance | `legacy_rule_pass` (≥2%) |
|---|---|---|---|---|
| **Health Care (XLV)** | **−1.87%** | Give-back of the 08-19 INTerpath rally | **60** — and the asymmetry is the finding: XBI **−3.64%** and IBB **−2.83%** gave back roughly *twice* the sector, which says a meaningful share of yesterday's +3.51% was positioning, not repricing | false |
| **Consumer Discretionary (XLY)** | **−1.61%** | The consumer read, and it is genuine | **60** — AAP −24.55, HD −2.85, TJX −2.64, DLTR −2.57, COST −2.45, ROST −2.43, DG −1.41 | false |
| **Consumer Staples (XLP)** | **−1.41%** | **A one-name artifact — do not read it as a defensive-bid failure** | **60** — WMT −9.15% is the sector's largest weight; inside XLP, KR +0.09% and BJ −0.53% behave normally | false |
| **Information Technology (XLK)** | **−0.29%** | **SURFACED ON THE ABSENCE** (§19 escape valve) | **60** — see below; the most decision-relevant sector item today | false |
| **Industrials (XLI)** | **−1.20%** | Holds two book positions | **45** — RTX −3.66 and GEV −2.17 both underperformed it, but DE **rose** on its print, so the sector is not uniformly weak | false |
| **Energy (XLE)** | **+0.27%** | Iran/Hormuz | **45** — dispersion/context surfacing; the ONLY green sector | false |

**Full sector tape for the record:** XLE +0.27, XLRE +0.20, XLB −0.19, XLK −0.29, XLU −0.57, XLC −0.57, XLF −0.92, XLI −1.20, XLP −1.41, XLY −1.61, XLV −1.87. **Top-to-bottom spread 2.14 percentage points** against yesterday's 4.58pp — and on a session where the index moved four times as much.

**THE STRUCTURAL FINDING IS THE SPREAD, AND IT IS THE OPPOSITE OF YESTERDAY'S.** Yesterday the index barely moved (+0.21%) while the interior churned violently and equal-weight beat cap-weight five to one. Today SPY fell −0.84% and RSP fell −0.81%, essentially in line, with dispersion collapsing by more than half. **That is broad de-risking, not rotation** — a materially different regime shape even though both sessions look like ordinary sub-1% index days from the index alone.

**THE MOST DECISION-RELEVANT ITEM IS AN ABSENCE: XLK −0.29% MEANS THE AI-CAPEX DE-RATING STOPPED.** Yesterday's file asked explicitly that this be watched as a **sequence** rather than re-assessed daily as unrelated one-day moves. **The honest update is that the sequence broke.** Technology was the second-best sector, and inside it **NVDA −0.33%, AVGO +0.43%, AMD +0.65%, MU +3.97%, TSM +0.95%, DELL −0.63%, HPE −0.45%, SMCI −0.22%** — against AVGO −4.61%, AMD −3.71%, DELL −6.64% and WOLF −7.53% one session earlier. The financing *narrative* continued in the bond market and in commentary (long yields rebounded; Bloomberg reported **Broadcom in talks for a >$60B AI-chip debt financing benefiting Anthropic**, dated 2026-08-20 ~22:08 UTC, at the very edge of this window), but **it did not price in AI-hardware equities today.** This directly downgrades the urgency of yesterday's WATCH item — see RISK below.

**The power/electrification complex is the one place that DID fall together:** VST −2.63%, SMR −2.37%, TLN −1.66%, NEE −1.02%, CEG −0.46%, alongside GEV −2.17%. No in-window news was found for any of them.

### 5. Notable commentary

- **Scott Bessent (Treasury Secretary), live on CNBC Thursday:** buyback operations "could be more than $4 billion per issue"; the department has "a big toolkit" and will "make a market" in longer-dated securities. **Yields rose anyway.**
- **Mary Daly (SF Fed), Thursday:** policy is "currently in a good place"; no urgent case for a pre-emptive move; too early to assess how Treasury's buyback strategy affects Fed operations.
- **Michael Selig (CFTC Chair), Thursday:** the agency is preparing its own crypto market rules if Congress does not pass the CLARITY Act.
- **Jefferies, Thursday:** cut its US steel sector outlook, naming Cleveland-Cliffs and **Steel Dynamics** among the most negatively exposed to a Canadian tariff rollback given flat-rolled/plate exposure.
- **UBS:** raised its Merck target to $175 from $145 on the 08-19 INTerpath data. MRK nonetheless closed **−2.11%** today.
- **Deliberately NOT relied upon.** Same-day automated "market mover" content attributing ISRG's decline to competitor regulatory clearances — the clearances are from **July 2026 and December 2025** (see RISK). One GEV-attribution source **visibly leaked an LLM reasoning preamble into its published text**, confirming it is auto-generated; its explanation is not used.

---

## ANALYSIS — RISK TO EXISTING POSITIONS

### MECHANICAL EXIT-TRIGGER SWEEP

Run over the **UNION** of `state.current_positions` (13 open tranches) and the live IBKR book (`get_account_positions`).

**Reconciliation status: CLEAN — zero reconciliation-lag positions.** Every name in the connector reconciles to the BigQuery book to the share: AMZN 0.3464 (= 0.1910 + 0.1554), CRM 0.2275, DIS 0.7244 (= 0.2822 + 0.4422), GEV 0.1244, GOOGL 0.2577 (= 0.1534 + 0.1043), ISRG 0.1091, RTX 0.1601, TSM 0.1550 (= 0.0659 + 0.0891), UBER 0.5156. VOO 21.8139 is the §13 park, not a strategy position. **No `position_reconciliation_lag` alert is owed.**

**Mechanical triggers: ZERO.** All 13 tranches carry `convergence_target IS NULL` and `time_exit_date IS NULL` — Strategy D has **no** convergence targets and **no** time-based exits by design ("No maximum hold," `strategy/06_strategy_d.md`), so neither mechanical test can fire on this book. This is a structural property of an all-D book, not an absence of checking. `ltcg_date` values (2027-04-27 through 2027-07-31) are tax markers, **not** exit triggers.

**Strategy B remains FLAT.** `analytics.b_pairwise_correlation` reads `n_positions = 0`, so the KL #12 pairwise-correlation warning is inert (`n_positions >= 2` fails). No `b_pairwise_corr_high` alert owed.

### PER-STRATEGY KILL-TRIGGER SWEEP

`perf.kill_flags` as of 2026-08-19 for D (2026-08-18 for B — the engine is yesterday's close; D1 runs before D2), with `current_drawdown` **unconditionally refreshed against today's live marks** for every open position, as required — no judgment predicate gates this refresh.

| Strategy | Engine drawdown | **Refreshed on live marks (08-20)** | Drawdown kill (≥50%) | Runaway (2×, pre-gate) | m2m review | Interim underperf |
|---|---|---|---|---|---|---|
| **D** | −1.217% (08-19) | **≈ −2.50%** (deployed MV 610.89 → **602.96** on live marks, −1.30%; deployed unit value ≈ 1.0707 vs peak 1.0981) | **false** | false (unit value 1.071, needs 2.0) | false | **false** |
| **B** | −3.925% (08-18) | n/a — flat, no open positions to re-mark | **false** | false | false | **false** |

The refreshed D figure is derived by scaling the engine's 08-19 `deployed_unit_value` of 1.084750613 by today's mark ratio (602.96 / 610.89 = 0.98702); the 610.89 denominator is independently confirmed by `analytics.strategy_nav.deployed_mv` for D. No strategy is within an order of magnitude of the −50% drawdown kill. `interim_underperf_warning` is FALSE for both, and **no open alert of that category exists**, so no HEAL-RESOLUTION `UPDATE` is owed. A/C/E have no `perf.kill_flags` rows (never deployed). **No kill or review flag fires. Nothing routes to D2.**

### THESIS-INVALIDATION ASSESSMENT — all 13 tranches

Every tranche's at-entry criteria were read from `state.current_positions.invalidation_status`. **All 13 carry a populated `invalidation_status`; none carries the `NOT_DISCRETELY_RECORDED_AT_ENTRY` marker.** Assessed against today's DEVELOPMENTS specifically, not asserted generically.

| Position | Day | Mark vs cost | Criterion touched by today's developments? | Status |
|---|---|---|---|---|
| **D:ISRG:2026-07-20** | **−5.84%** | +7.14% | Procedure growth, placements, recurring-revenue decoupling, competitor displacement at named large IDNs. **No in-window event of any kind exists** — see the ISRG note below. | **UNBREACHED** |
| **D:RTX:2026-04-27** | **−3.66%** | +20.01% | Airbus damages, powder-metal charge, GTF Advantage EIS timing, backlog decline, FY26 FCF guide, FY27 procurement cut. No in-window RTX event; the whole defense complex fell. The 08-17 $22.9B Tomahawk award remains thesis-POSITIVE for backlog. | **UNBREACHED** |
| **D:GEV:2026-08-03** | **−2.17%** | −0.40% | Total-company organic orders growth YoY (entry 88%, prior quarter 71%; invalidation <15% for 2 consecutive quarters). No orders data published; the entire power complex fell together with no news. | **UNBREACHED** |
| **D:AMZN:2026-07-30 / :2026-07-09** | −2.16% | −2.10% / +7.82% | AWS revenue growth, AWS op-margin, AWS backlog, Anthropic/OpenAI commitments, metric-immutability. **The one in-window item touching a criterion cuts POSITIVE:** Bloomberg on Broadcom's >$60B AI-chip financing *benefiting* Anthropic is evidence against criterion-4 breach, not for it. | **UNBREACHED** |
| **D:GOOGL:2026-07-26 / :2026-07-09** | −1.17% | +3.91% / **−5.33%** | Cloud revenue growth, Cloud op-margin, Cloud RPO, adverse structural remedy, metric-immutability. No Google Cloud development in-window; news flow is routine. | **UNBREACHED** |
| **D:TSM:2026-07-29 / :2026-07-21** | **+0.95%** | +5.88% / −2.77% | GM/revenue growth, N2/A16 ramp and sub-7nm share, **structural AI-capex reset**. Criterion 3 is the most exposed to the running theme — and today TSM *rose* while the complex stabilised. Materially less pressure than yesterday. | **UNBREACHED** |
| **D:CRM:2026-07-09** | −0.32% | +28.11% | Agentforce/Data-360 ARR, cRPO, non-GAAP op margin, FY27 revenue guide, metric-immutability. **No CRM information exists** — Q2 FY27 is 2026-08-26 AMC, confirmed unreported. `recheck-CRM-criteria-D-20260827` is already queued for the day after. | **UNBREACHED** |
| **D:DIS:2026-05-07 / :2026-08-05** | **+0.36%** | −3.59% / +3.41% | SVOD margin, FY26 EPS guide, buyback pace, metric-immutability, FCC escalation. No in-window Disney financial or corporate news; all coverage is park-operations content. | **UNBREACHED** |
| **D:UBER:2026-07-09** | +0.65% | +7.30% | Gross bookings, adj-EBITDA margin, Uber One membership, metric-immutability. Its Q2 beat and Zagreb autonomous launch are both dated 2026-08-19 during that regular session — **pre-window**. | **UNBREACHED** |

**THE ISRG NOTE, because it is the most consequential decline in the book and the most consequential honest negative.** ISRG fell −5.84%, roughly 4pp under XLV and 5pp under SPY. A dedicated search found **no in-window company-specific event**: the FDA device-recall database's most recent Intuitive posting is **2026-07-10**, the most recent 8-K is **2026-07-27**, August SEC filings are small scheduled 10b5-1 Form 4 sales, and no analyst action is dated in-window. **Critically, the explanation being circulated is provably stale.** Same-day automated content attributes the move to competitor regulatory clearances — but J&J's Ottava received FDA De Novo authorization on **2026-07-22**, CMR's Versius Plus in **2025-12**, and Medtronic's Hugo urology clearance in **2025-12**; a separate 2026-08-18 item republishing a "da Vinci 5 cardiac clearance" recycles a **2026-01** event. That last one is the same claim yesterday's file flagged as unreliable; it is now positively resolved as stale rather than merely doubted. **A future session or routine that reads "J&J Ottava clearance" as today's ISRG catalyst is reading a July event re-attached to an August price print by a content generator.** None of the four criteria is touched. **The qualification, stated rather than omitted:** criterion 4 is a competitive-displacement test, and ISRG carries a live competitive-entry overhang alongside conservative FY26 procedure guidance from its 07-16 call, with the stock down ~30–35% YTD. That overhang is not new today and does not breach criterion 4 — an authorization is not a disclosed displacement at named large IDNs — but the structural driver in question is under live competitive pressure, and the absence of a same-day headline should not stand in for the absence of a thesis risk.

**THE WATCH ITEM FROM YESTERDAY — DOWNGRADED ON TODAY'S EVIDENCE, WHICH IS THE POINT OF WATCHING A SEQUENCE.** Yesterday's file identified GEV, TSM and to a lesser degree GOOGL/AMZN as carrying invalidation criteria whose demand channel is hyperscaler AI capital expenditure, and asked that the AI-capex financing story be tracked as a *sequence* rather than re-assessed daily. **It did not extend into a third session.** XLK closed −0.29% with MU +3.97%, AVGO +0.43%, AMD +0.65% and TSM itself +0.95% — the exact names that were de-rating are the ones that stabilised or rose. The narrative continued in the bond market and in commentary, and the Broadcom/Anthropic financing report shows the debt machine still running, but **the equity transmission channel that would eventually reach GEV's orders growth or TSM's criterion 3 did not operate today.** The watch stays open — these are all "2 consecutive quarters" tests and the earliest any could fire is two reporting cycles away — but it is a *weaker* watch tonight than it was last night, and saying so is the whole value of having framed it as a sequence.

### WATCHLIST CANDIDATE STATUS

- **CVS and DVA:** both windows **expired 2026-08-19** unexercised and were closed by D2 that session. No further action.
- **MRNA** (added 08-19, +176.97% event): **materially updated today.** Gave back **−23.55%** on no new information — 41.06 of the 111.42 points gained. This is the first live datapoint on the mechanism objection recorded against the row at creation ("a modality-defining re-rating leaves no pre-event anchor to converge back to"), and **it cuts both ways rather than settling it**: a give-back is what a sentiment overshoot does, but a −23.55% single-session reversal also says the post-event price is not a stable anchor to underwrite convergence against. Both readings recorded; neither asserted. Candidacy **unchanged** (index-only regardless — router).
- **EL** (added 08-19): closed −1.90% today. Window open to 2026-09-02. Unchanged.
- **FN, KLAR, BIDU, AMLX** (added 08-18), **ONON, TME** (added 08-11): BIDU −0.97% today, no bearing. All otherwise unchanged.
- **Strategy A queue (36 names):** unchanged. A remains DO-NOT-ACTIVATE with NAV $0.00.

---

## ANALYSIS — OPPORTUNITY CHECK

Scoped to roster-active strategies with `review_cadence: reactive` in `strategy/roster.yaml` — **currently A, B, C, E** (D is excluded via `review_cadence: long_horizon`). Read live from the roster this session, not carried forward.

**Strategy A — DO-NOT-ACTIVATE (`div-A-202607-1`, 2026-08-05), NAV $0.00.** No candidate routed. Nothing today creates an A-shaped catalyst worth queuing that is not already on the 36-name queue.

**Strategy B — DO-NOT-ACTIVATE (`div-B-202607-1`, 2026-08-05), NAV $0.00.** **Six names clear B's frozen Entry criterion 1 on a resolved, dated, in-window-or-prior-session public event — the largest single-day cohort this file has recorded.** All are index-only. Ranked on **mechanism fit rather than magnitude**, because that ranking is the actual output:

1. **WMT −9.15%** (event 2026-08-20) — **much the strongest, and the best B shape in weeks.** A mega-cap that beat both lines and raised guidance, sold off 9% on forward deceleration. Clear pre-event anchor at 114.30, deepest liquidity on the tape, unambiguous event identity. If B were active and funded, this would be the day's thesis-construction candidate without close competition.
2. **WOLF −9.42%** (event 2026-08-19) — a genuine divergence: adjusted loss $2.26 against a −$2.45 estimate is a beat, revenue at the company's own guidance midpoint, sold off 9.4%. **Counterweight stated because it is material:** post-Chapter-11 issuer, −19.9% gross margin, −24% YoY revenue, ~16% coupon on priority debt, ~45.5% short interest. "Beat" here means a smaller loss, and the convergence B would underwrite is inside a distressed capital structure.
3. **MRVL +9.85%** (event 2026-08-19) — **arguable both ways, which is why it is indexed rather than dismissed.** Read one way it is a justified re-rating on real new information (weak fit). Read the other way, the 8-K carries **no minimum purchase commitment** and third-party analysis puts any revenue impact beyond FY2028, so a +9.85% single-session re-rating on an option-like arrangement with an unbounded timeline is a plausible sentiment overshoot — which is exactly B's mechanism.
4. **AAP −24.55%** (event 2026-08-20) — largest magnitude, fourth on fit. Strip the $0.31 of non-recurring tariff refunds from the $1.03 "beat" and the print is a miss against a revenue miss and −0.5% comps, which makes the move substantially an information-driven repricing.
5. **NDSN +8.00%** (event 2026-08-19) and 6. **DE +6.94%** (event 2026-08-20) — clean, well-sourced events, but **B's weakest mechanism class**: the price moved in the direction the information supports. A justified re-rating has no reason to converge. This is the same standing objection already recorded against AMLX (08-18) and MRNA (08-19).

**Explicitly NOT routed to B, with reasons:** **ISRG −5.84%** clears the floor on magnitude but has **no qualifying event at all** — B needs an event and there is none. **CRWD −5.60%** has no fresh in-window event; its only driver is a pre-window 08-19 analyst action. **STLD −5.20%/−7.53%** is declined on the **resolved-event test** (see section 3). **ONDS −5.84%** is declined on stale attribution. **ROST −2.43%** is pre-print positioning, not a reaction.

**Strategy C — HYBRID ACTIVATE (FOMC-only) (`div-C-202607-1`, 2026-08-05).** No FOMC decision occurred in-window; the minutes were Wednesday, pre-window. `thesis-FOMC-C-20260908` is already queued for the September meeting. **No candidate today — but today sharpened the observation forwarded yesterday, and the sharpening is worth recording.** Yesterday's file noted that the July minutes revealed a hawkish distribution ("several" wanting a hike at the meeting, "many" saying tightening likely necessary) while market pricing moved the *other* way. **Today added a second, independent leg to that divergence:** three macro prints landed hawkish-supportive — Philly Fed 47.4 against a ~25 consensus, claims 206K beating 210K, LEI turning positive on a six-month basis — and September hike odds **barely moved** (32.7%, roughly flat against ~33–34% pre-minutes). So the priced distribution is now failing to respond to both the Fed's stated distribution *and* to strong incoming data. That is a stronger version of exactly the input C's criterion has been missing across four consecutive NO-GO drains. **Forwarded to the `thesis-FOMC-C-20260908` drain as evidence to weigh; no action today, and no claim it persists three weeks.**

**Strategy E — ACTIVATE (`div-E-202607-1`, 2026-08-05), NAV $15,333.61, fully funded.** E is again the only strategy with both an ACTIVATE router and deployable capital.

**No E candidate is routed, and today the reason is stronger than yesterday's, not weaker.** Yesterday declined on the measured ground that Rev 45's frozen Entry criterion 3 needs a **≥95th-percentile** spread anchor and one session of dispersion cannot move a trailing percentile. That still binds. **But today the dispersion itself collapsed** — the sector spread more than halved to 2.14pp from 4.58pp, and equal-weight tracked cap-weight to within 3bp. A session that de-risks uniformly produces *less* pair material, not more, so there is not even a raw candidate to test.

**Routed to M2 as ideation evidence** (M2 owns pair construction, the same-6-digit-GICS-group test and the 252-day correlation machinery, none of which D1 can supply): the **steel policy-relative-value pair** is the genuinely new item — STLD/NUE/CLF versus Canadian producer ASTL moved in opposite directions by ~25pp on a single policy report, which is a mechanically-driven divergence with an identifiable catalyst and a natural convergence trigger (the deal resolving either way). That is a materially better-formed E archetype than the one-day sector dispersions forwarded yesterday. Carried alongside the still-open managed-care-vs-pharma and NVDA-vs-AVGO/AMD items. This is a note, not a queue item — M2 runs monthly and reads D1 records.

---

## ANALYSIS — ADD-CANDIDATE CHECK (Strategies A, B, D only — Rev 40)

**Scope:** every open A/B/D position. **A = 0 positions. B = 0 positions. D = 13 tranches across 9 names. 13 evaluated.** Marks are today's IBKR regular-session close against each tranche's **own** per-share cost basis (`cost_basis / shares` per tranche — never a name-level blend, which would misstate all four multi-tranche names).

**RESULT: 0 flagged. 0 declined at the HARD GATE. 13 declined.** Ninth consecutive all-decline session — **and today produced MORE genuine triggers than any prior session in the streak, not fewer.**

**THE BINDING CONSTRAINT IS THE ROUTER, AND IT IS NOT CAPITAL.** D's `available_funds` of $0.11 is its **normal resting state**, not a deprivation: `state.strategy_declared_frequency.is_low_frequency_by_design = TRUE` and `state.strategy_nomadic_status.is_nomadic = TRUE`, D holds no exclusive standing capital, and `analytics.fn_nomadic_capital_restore_plan` would fund an add from E's idle $15,333.61 on demand. **What blocks a D add is that D has been DO-NOT-ACTIVATE since 2026-08-05** (`div-D-202607-1`). A deactivated strategy takes no new entries; an add deploys new capital by construction. Existing tranches run to their own criteria undisturbed, which is why all thirteen are evaluated on merit rather than skipped. **D adds unblock when the ROUTER flips — at M1a/M1b's 2026-09-01 re-scoring or an inter-monthly review — not when cash appears.**

**HARD GATE — all 13 pass.** Every tranche's original at-entry invalidation criteria remain UNBREACHED, so no position routes to exit and `n_declined_hard_gate = 0`. `invalidation_criteria_evaluable = TRUE` for all 13 — computed with the mandated `COALESCE(JSON_VALUE(invalidation_status,'$.status'), '')` wrap. **Measured again this session: all 13 tranches carry a populated `invalidation_status` and not one carries a `$.status` key at all**, so the literal unwrapped transcription would have emitted 13 NULLs where 13 TRUEs belong. The condition the 2026-08-17 note describes is still exactly the live state of this book.

**THE THREE GENUINE TRIGGER-(a) FIRES:**

**1. D:ISRG:2026-07-20 — the day's strongest case.** −5.84%, the largest decline in the book, ~4pp under XLV and ~5pp under SPY, with **no in-window company event** and a circulating explanation that is provably stale (full detail in RISK above). None of the four criteria is touched. Trigger (a) requires adverse price action with no bearing on the multi-year structural drivers, and that is what this is. The tranche sits **+7.14% above cost** — which trigger (a) does not preclude, being defined as short-term adverse movement, not a drawdown below basis. **Carrying its qualification:** criterion 4 is a competitive-displacement test and the Ottava overhang, while not a breach and not new today, is live. On merit this would have been flagged with that qualification attached.

**2. D:RTX:2026-04-27 — a real fire, but MATERIALLY WEAKER than yesterday's version of the same case.** −3.66%, second consecutive decline totalling −5.86% from near 52-week highs, no in-window company event, none of the six criteria touched, and the 08-17 $22.9B Tomahawk award still thesis-positive for backlog. **But yesterday's file called RTX's −2.28% roughly 1.4pp of *unexplained* single-name underperformance, and today's independent check of the aerospace-defense complex found it fell broadly** (Boeing −3.16% reported; DIA −1.27% on our own measurement). The correct read of both sessions is sector-and-market risk-off, not an idiosyncratic RTX de-rating. **That is a downgrade of yesterday's reasoning by today's evidence, recorded as such rather than left to stand.** Tranche +20.01% above cost.

**3. D:AMZN:2026-07-30 — a secondary but real fire.** −2.16% against SPY −0.84%, ~1.3pp of underperformance with no AWS-specific development. The tranche is now **−2.10% below** its own cost basis of $265.6931/share. And the one in-window item touching a criterion cuts **positive**: the Broadcom >$60B AI-chip financing *benefiting* Anthropic is evidence against a criterion-4 breach. Adverse price action plus a criterion nudged favourably is trigger (a) with a mild strengthened-conviction overlay.

**Convention note, because it affects the counts:** an ADD is a decision about a NAME (one new independently-sized tranche) while this record carries one row per open TRANCHE. To avoid counting one add decision twice, a name-level trigger is recorded on a single tranche and the sibling is marked `none` with the reason naming the convention. AMZN is the only name where this bites today.

**Declined with reasoning — the rest:**

- **D:GEV:2026-08-03** (−0.40% vs cost, −2.17% on the session): **declines on a REVISED ground.** Yesterday's basis was that the decline's driver — AI-capex financing anxiety — ran at GEV's own orders metric, so price action and thesis driver shared a mechanism. **That concern is WEAKER today, not stronger**: the AI-hardware complex actually rose. But GEV still declines, on a different ground: the entire power/electrification complex fell together (VST −2.63, SMR −2.37, TLN −1.66, NEE −1.02, CEG −0.46) with no in-window news for any of them, so this is a sector move, and trigger (a) wants adverse price action on the *position*, not on its whole sector. `none`.
- **D:GOOGL:2026-07-09** (**−5.33% below cost**, the deepest in the book): a −1.17% session broadly in line with SPY −0.84%. A standing unrealised loss is not a trigger; trigger (a) requires *movement*, and there was no adverse event today. `none`. **D:GOOGL:2026-07-26** (+3.91%): same session, above cost. `none`.
- **D:CRM:2026-07-09** (+28.11%, −0.32% on the session): flat, and the standing objection binds hardest now — **Q2 FY27 is 2026-08-26 AMC, six days out and company-confirmed**, with `recheck-CRM-criteria-D-20260827` already queued for the day after. Adding into a print inside a week is buying event risk and calling it conviction. `none`.
- **D:DIS ×2** (+0.36% on the session; −3.59% / +3.41% vs cost): DIS was the **only green name in the book**. A position that rose is not a dip. `none`.
- **D:TSM ×2** (+0.95%; −2.77% / +5.88%): TSM rose, outperforming both the tape and its own complex. `none`.
- **D:AMZN:2026-07-09** (+7.82%): trigger carried once on the sibling tranche per the convention above. `none`.
- **D:UBER:2026-07-09** (+7.30%, +0.65% on the session): up, no criterion-bearing news; its 08-19 Q2 beat and Zagreb launch are pre-window. `none`.

**On the streak.** Nine consecutive all-decline sessions, and today produced three defensible triggers — the most yet. **The streak measures the router's state, not the quality of the book or of this check.** It breaks mechanically when D reactivates; until then this section's real output is the durable record of *which* cases would have been taken. Logged to `events.decision_log` (`entry_type='add-candidate-review'`, id `c578d9ec-f154-431d-8604-17ee262f3077`).

---

## ANALYSIS — REGIME CHECK

**No inter-monthly router review is recommended. Default-NO holds on the high bar — but `growth_momentum` is the closest this call has been in weeks, and that deserves to be said plainly rather than buried.**

**`growth_momentum` (currently `decelerating`) — THREE independent data points landed today pointing the other way, and one landed pointing this way.** For: Philadelphia Fed manufacturing **47.4 against a ~25 consensus**, its highest since April 2021, with its employment sub-index the highest since April 2022; initial jobless claims **206,000 beating ~210,000**; and the Conference Board LEI **+0.2% m/m with its six-month growth rate positive for the first time in over four years**. That is the strongest single-session case for an upgrade this axis has seen. Against: **the consumer deteriorated in two independent issuers' own numbers on the same morning** — Walmart's US comps at +2.6%, their slowest in more than six years and down from +4.6% a year ago, and Advance Auto Parts citing "constrained" customer spending, with the whole retail complex closing lower as a group.

**Why this does not clear the bar.** The evidence is genuinely two-sided, not merely incomplete: manufacturing, labour and leading indicators say acceleration while the consumer says deceleration, and those are different halves of the same economy rather than a contradiction to be resolved by preference. Firing an out-of-cycle router review to adjudicate a split that one more month of data will resolve properly is motion, not information — **and M1a re-scores in 7 trading days on a full monthly evidence set.** Flagged forward as the **top item** for M1a 2026-09-01.

**`policy_stance` (currently `hawkish`) — CONFIRMED, and today strengthened it.** Strong manufacturing and labour data plus the July minutes' hawkish distribution both support the existing reading. The axis value does not change. What is worth carrying forward is the *gap*: September hike odds barely moved (32.7%) despite both the minutes and today's data. That is a Strategy C input, recorded above, not a router flip.

**`shock_overlay` (currently `acute`) — CONFIRMED, and the diplomatic axis deteriorated further.** Trump's "economic warfare" threat, the reported UAE trade suspension, no scheduled talks, and Brent around $93. `acute` was already the scored state, so there is nothing to flip. Unlike yesterday, the tape did partially respond this time (VIX +7.52%), which narrows — without closing — the disconnect yesterday's file flagged.

**`risk_sentiment` (currently `neutral`) — unchanged.** VIX rose but remains inside a LOW regime and below both moving averages; breadth contracted but sits at 70.31, far above any stress threshold; credit was a non-event (HYG −0.19%). All consistent with `neutral`.

**`inflation_trend` (currently `stable`) — no in-window CPI or PPI.** Oil at ~$93 and a fourth-plus session of gains is a forward risk to this axis, not present evidence about it. Not flagged.

---

## EQUITY-BREADTH OBSERVATION

**70.31% of S&P 500 constituents closed above their own 200-day SMA on 2026-08-20** — written to `events.regime_events`, `scope='TECHNICAL_INPUT'`, `key='EQUITY_BREADTH_PCT'`, `as_of_date=2026-08-20`. **MEASURED and SOURCE-DATED**; the post-close-inference fallback was not needed and was not used.

- **SINGLE-SOURCE THIS RUN, stated up front.** The mandated primary, **MacroMicro, was UNREACHABLE — not stale, unreachable.** Five attempts failed: four Tavily extracts with four different cache-busting values each returned a hard "Failed to fetch url" with an empty result set, and a direct WebFetch returned HTTP 403. A search fallback returned only the page's JavaScript nav chrome. No `Latest Stats` block was retrieved at all, so the two-cache-buster agreement check this key normally carries **could not be performed** (N/A — no content to compare, which is different from content that disagreed).
- **Source used — Barchart `$S5TH`, source-dated and settled.** Page verbatim: *"S&P 500 Stocks Above 200-Day Average($S5TH) 70.31-1.80(-2.50%)17:03 ET[INDEX]"*, *"Quote Overview for Thu, Aug 20th, 2026"*, with *"Day Low 70.31 / Day High 73.30 / Open 71.51 / Previous Close 72.11"*. The **17:03 ET** stamp is after the close.
- **The stale-cache failure mode is affirmatively ruled out, on two grounds, because a single-source row must earn that.** (1) The page was fetched **twice by two different callers with two different cache-busters** and returned identical figures and the identical "Thu, Aug 20th, 2026" heading — the exact check that caught the 2026-08-16 incident, where a Tavily-extracted Barchart copy came back headed *"Quote Overview for Fri, Aug 7th, 2026"* and coincidentally also read 72.76. (2) **Stronger, and internal to this warehouse:** the page's own *"Previous Close 72.11"* matches this table's stored 2026-08-19 row **to the decimal**. A stale copy could not carry the correct immediately-preceding settled value. That is better corroboration than a second undated tracker would have been.
- **The `Low == Close` tell was checked and does NOT fire.** Day Low 70.31 equals the close, which is one half of the documented EODData unsettled signature — but the tell requires **both** halves, Low==Close **and** a timestamp before 16:00 ET, and this page stamps 17:03 ET. On a session that sold off into the close (opened 71.51, ranged to 73.30, finished at the low) closing at the low is the expected shape.
- **EODData REJECTED — stale by ~two sessions, worse than merely unsettled.** No row for 08-19 or 08-20 exists; the newest completed row is still "18 Aug 26" at 68.12, and its live header reproduces the 08-18 open and high exactly while carrying the 08-17 close as "previous". Third consecutive session it has failed this key's settlement test, by a widening margin.
- **Why a row is written rather than suppressed.** The write-no-row rule is scoped to *two sources disagreeing by more than 5pp*, and that condition is not engaged — a second usable source was not obtainable at all. What the step requires unconditionally is a value pinned to the session it measures by a source stating its own as-of session; Barchart states it, post-close, and self-validates against the prior stored row. **Flagged for a future session: if MacroMicro stays unreachable across several runs, that is a source-availability regression worth acting on rather than absorbing silently.**

**Direction — a PARTIAL GIVE-BACK, not a resumption of the contraction, and the distinction matters.** Series: 08-13 73.16 → 08-14 72.76 → 08-17 68.58 → 08-18 68.12 → 08-19 72.11 → **08-20 70.31**. Yesterday's +3.99pp recovery gave back **45% of itself** in one session, leaving breadth 2.85pp below the one-month high and 2.19pp above the 08-18 trough. **Unlike 08-17/08-18, this contraction IS broadly explained by the index rather than by narrowing leadership:** SPY −0.84% and equal-weight RSP −0.81% fell essentially in line — the interior fell *with* the index instead of being abandoned by it — and the sector spread collapsed to 2.14pp. 08-17's −4.38pp on a −0.47% tape was narrowing participation; today's −1.80pp on a −0.84% tape is ordinary broad de-risking, a materially less concerning shape at the same arithmetic sign.

Threshold classification (HEALTHY/WEAK) is D2a's to apply on `TECHNICAL_SIGNAL` and is deliberately not written here. For D2a: 70.31 ≫ 50, `breadth_measurement_age_days = 0`, a genuine same-session measurement.

---

## PARK ALLOCATION CALL

- **`vehicle`: VOO — KEEP** (today's `state.park_policy_current.vehicle` is VOO, effective 2026-08-03).
- **`conviction`: MEDIUM — `conviction_pct` 55** (down from 60 yesterday).
- **`rationale`:** Yesterday raised conviction 55 → 60 on exactly one thing — breadth reversing a three-session contraction, +3.99pp in a day. **Today breadth gave back 45% of that recovery (72.11 → 70.31), VIX rose 7.52% to 16.01 off a fresh local low, SPY fell 0.84% and 9 of 11 sectors closed lower.** A metric that earns an upgrade when it moves one way must earn a downgrade when it moves back, or it was never the reason. **It remains a KEEP because none of the three invalidation conditions I named yesterday fired, and one of them moved actively away:** (a) breadth is 70.31, above the ~65 bar, and the condition specifies breadth falling *while SPY holds up* — SPY did not hold up, and equal-weight tracked it to within 3bp, so this is broad de-risking, not the narrowing-leadership shape the condition describes; (b) Brent at ~$93 is not ~$100, and VIX at 16.01 sits inside a LOW regime below both its 50-day (16.98) and 200-day (18.50) — the "equity vol responding" leg has still not engaged; (c) credit was a non-event (HYG −0.19%, LQD −0.48%) and the AI-capex story's *equity* leg actually reversed. **Why VOO beats the runner-up, VTI, and VTI was genuinely assessed:** it lost on BOTH legs today, not just cost. On direction, small caps underperformed badly (IWM −1.34% vs SPY −0.84%) and VTI closed −0.90% against VOO −0.83% — the tape said which tilt it wanted. On cost, the park's entire ~$15.3k sits in 21.8139 VOO shares, so switching pays a full round trip on the whole position for a few hundred basis points of weight difference. **The strongest argument for KEEP came out of today's data rather than out of the position: the de-risk leg had nothing to offer.** Every duration instrument on the menu fell alongside equities — TLT −0.82%, IEF −0.41%, GOVT −0.27%, LQD −0.48% — because long yields *rebounded* to ~4.69% despite Wednesday's buyback expansion, on a day total US public debt crossed $40 trillion. Rotating into duration today would have bought correlated loss, not protection. **Not higher than 55, and the reasons are stated rather than omitted:** breadth gave back, VIX rose, Hormuz escalated on the diplomatic axis with the UAE reported suspending Iranian trade, and the consumer deteriorated in two issuers' own numbers.
- **`invalidation` (SYMMETRIC EVIDENTIARY STANDARD, 2026-08-18):** a de-risk out of VOO becomes the better call if **ANY ONE** holds — stated as a **disjunction at narrative bar**, matching the narrative bar on which the 2026-08-03 re-risk into VOO was justified. **(a)** the give-back extends — % above 200-day rolls under ~65 and keeps falling *while SPY holds up*; **(b)** Hormuz converts from rhetoric to a supply interruption the tape prices — sustained Brent through ~$100 *with equity vol responding*; **(c)** the AI-capex story converts into a credit event — HY OAS widening materially off its ~2.85 base *on a live reading, not the stale monthly print* — or a hyperscaler capex guide-down; **(d) NEW TODAY** — the consumer deterioration now visible only in individual issuers' commentary shows up in a second, independent data class (a negative retail-sales print, a payrolls miss, or a break in the claims trend). **No conjunctive numeric checklist is set, and that is deliberate:** the 2026-07-31 / 08-02 KEEP-SGOV calls named a three-part conjunctive re-entry bar after a narratively-justified exit, and honouring it literally would have held the park in SGOV through VOO 684.56 → 706.23. An exit bar harder to clear than the entry bar quietly removes next-session reversibility — the only compensating control left after the 2026-07-26 directive retired the anti-churn rails.
- **`theater_check`:** The conviction moved **down** on the same metric that moved it up yesterday, which is what makes it a reading rather than a defence of the incumbent — had breadth held 72 with VIX flat, this would have stayed at 60. The four facts arguing *for* a de-risk are stated in the rationale ahead of the facts arguing against, not after them. VTI was assessed on today's evidence and lost on direction as well as cost rather than being waved past. And the strongest KEEP argument — that the entire de-risk tier fell alongside equities — emerged from today's data, not from the position being held.
- **`status`: BOUND** (a KEEP is trivially BOUND; D2's PARK ALLOCATION CONVERSION no-ops when the called vehicle equals the current policy vehicle). **`direction`: keep.**

---

## RECOMMENDED ACTIONS

- **Exits triggered:** none. Zero mechanical triggers (Strategy D carries no convergence targets or time exits by design); zero thesis-invalidation criteria breached across all 13 open tranches.
- **New entry candidates:** none routed. Strategy B is DO-NOT-ACTIVATE with NAV $0.00; Strategy E is ACTIVATE and funded but today's dispersion *collapsed*, so no pair can approach its ≥95th-percentile spread anchor.
- **Add candidates:** none. ISRG, RTX and AMZN's second tranche were genuine `dip-with-intact-thesis` triggers and are declined on the Strategy-D router (DO-NOT-ACTIVATE), not on capital and not on merit.
- **Watchlist updates:**
  1. **Add WMT** to the Strategy B new-entry index — −9.15% on the 2026-08-20 Q2 FY27 beat-and-raise; the cleanest B mechanism fit in weeks; index-only.
  2. **Add WOLF** — −9.42% reaction to the 2026-08-19 16:05 ET FY26 Q4 print (an adjusted-loss beat), qualifying event date 2026-08-19; index-only.
  3. **Add MRVL** — +9.85% on the 2026-08-19 Google-warrant 8-K, qualifying event date 2026-08-19; **missed by the 2026-08-19 screen and recorded now**; index-only.
  4. **Add AAP** — −24.55% on the 2026-08-20 Q2 print, with the refund-inflated-beat objection recorded; index-only.
  5. **Add NDSN** — +8.00% on the 2026-08-19 AMC record Q3 beat-and-raise, qualifying event date 2026-08-19; index-only.
  6. **Add DE** — +6.94% on the 2026-08-20 Q3 beat-and-raise; index-only, weakest mechanism class.
  7. **Annotate MRNA** — gave back −23.55% on no new information, the first live datapoint on the row's own recorded mechanism objection; no disposition change.
- **Router reviews recommended:** none. `growth_momentum` is flagged forward as the **top** item for M1a's 2026-09-01 re-scoring, with `policy_stance` and `shock_overlay` confirmed at their existing values.

```yaml d1_actions
- action: watchlist
  ticker: WMT
  strategy: B
  qualifying_event_date: 2026-08-20
  source_research_screen_id: bc9a1f62-b1b7-4f7e-9e3b-cb2bae8abb75
  detail: ADD to Strategy B new-entry index — -9.15% close-to-close (114.30 -> 103.84, IBKR RTH daily bars) on the 2026-08-20 Q2 FY27 print released ~06:00 CT; adj EPS 0.81 vs 0.741 BEAT and revenue 187.9B vs 186.6B BEAT with FY27 guidance RAISED, sold off on Walmart U.S. comps +2.6 pct (slowest in 6+ years vs +4.6 pct YoY) and a Q3 adj operating-income guide of +2-4 pct cc against the +17.4 pct just delivered; clears B frozen Entry criterion 1 and is the strongest mechanism fit of the six-name cohort; index-only, no thesis construction routed (B router DO-NOT-ACTIVATE and B NAV 0.00)
- action: watchlist
  ticker: WOLF
  strategy: B
  qualifying_event_date: 2026-08-19
  source_research_screen_id: bc9a1f62-b1b7-4f7e-9e3b-cb2bae8abb75
  detail: ADD to Strategy B new-entry index — -9.42% close-to-close (29.09 -> 26.35) as the reaction session to the FY26 Q4 print released 2026-08-19 16:05 ET (quarter ended 2026-06-28), so the qualifying event date is 2026-08-19 not 2026-08-20; adjusted loss 2.26 vs ~-2.45 estimate is a BEAT and revenue 149.6M was at the company guidance midpoint, yet the stock fell 9.4 pct — a genuine divergence; counterweight recorded that this is a post-Chapter-11 issuer with -19.9 pct gross margin, -24 pct YoY revenue and ~45.5 pct short interest, and market cap is FMP-unverifiable this run; index-only, same router/capital reason as WMT
- action: watchlist
  ticker: MRVL
  strategy: B
  qualifying_event_date: 2026-08-19
  source_research_screen_id: bc9a1f62-b1b7-4f7e-9e3b-cb2bae8abb75
  detail: ADD to Strategy B new-entry index — qualifying move is +9.85% close-to-close on 2026-08-19 (216.00 -> 237.27, IBKR RTH daily bars) on the 8-K filed that day disclosing a Google warrant for 58,970,907 shares at 206.58 strike against a commercial agreement signed 2026-07-29; today's +5.79% is a SECOND-DAY CONTINUATION and is not the qualifying move; the 2026-08-19 D1 screen missed this name and it is recorded now rather than absorbed; mechanism fit arguable both ways (justified re-rating vs sentiment overshoot given no minimum purchase commitment and revenue impact analysed as beyond FY2028); index-only, same router/capital reason as WMT
- action: watchlist
  ticker: AAP
  strategy: B
  qualifying_event_date: 2026-08-20
  source_research_screen_id: bc9a1f62-b1b7-4f7e-9e3b-cb2bae8abb75
  detail: ADD to Strategy B new-entry index — -24.55% close-to-close (56.18 -> 42.39) on the 2026-08-20 pre-market Q2 2026 print (quarter ended 2026-07-18); adj EPS 1.03 vs 0.81 but 0.31 of it non-recurring tariff refunds, revenue 2.0B MISSED ~2.04B, comps -0.5 pct, FY revenue reaffirmed below consensus, store openings cut to 30-35 from 40-45; largest magnitude of the day but ranked FOURTH on mechanism fit because stripping the refund makes the print a miss and the move substantially information-driven; market cap FMP-unverifiable this run; index-only, same router/capital reason as WMT
- action: watchlist
  ticker: NDSN
  strategy: B
  qualifying_event_date: 2026-08-19
  source_research_screen_id: bc9a1f62-b1b7-4f7e-9e3b-cb2bae8abb75
  detail: ADD to Strategy B new-entry index — +8.00% close-to-close (309.92 -> 334.70) as the reaction session to record Q3 FY2026 (quarter ended 2026-07-31) released AFTER THE CLOSE on 2026-08-19 with the webcast 2026-08-20 08:30 ET, so the qualifying event date is 2026-08-19; adj EPS 3.25 vs ~3.09, revenue 817.7M record +10 pct YoY vs ~779.4M, EBITDA record 262M at 32 pct margin, backlog +35 pct, FY guidance RAISED on both lines; market cap ~17.3B; B's WEAKEST mechanism class recorded explicitly (a beat-and-raise that rose 8 pct is a justified re-rating with no reason to converge); index-only, same router/capital reason as WMT
- action: watchlist
  ticker: DE
  strategy: B
  qualifying_event_date: 2026-08-20
  source_research_screen_id: bc9a1f62-b1b7-4f7e-9e3b-cb2bae8abb75
  detail: ADD to Strategy B new-entry index — +6.94% close-to-close (580.63 -> 620.94, volume 2.01M vs ~795K prior session) on the 2026-08-20 Q3 FY2026 print; EPS 5.10 vs ~4.70, revenue 11.0B vs ~10.73B, FY net income guidance RAISED to 4.75-5.0B, Construction & Forestry carried by infrastructure and data-centre demand; same WEAKEST mechanism class as NDSN and the same standing objection already recorded against AMLX 2026-08-18 and MRNA 2026-08-19; index-only, same router/capital reason as WMT
- action: watchlist
  ticker: MRNA
  strategy: B
  qualifying_event_date: 2026-08-19
  source_research_screen_id: bc9a1f62-b1b7-4f7e-9e3b-cb2bae8abb75
  detail: ANNOTATE the existing 2026-08-19 row — MRNA gave back -23.55% close-to-close (174.38 -> 133.32), 41.06 of the 111.42 points gained, on NO new disclosure, data detail, offering or index action, per multiple independently-dated 2026-08-20 sources converging on profit-taking after the largest one-day rally in company history; this is the first live datapoint on the mechanism objection recorded against that row at creation and it CUTS BOTH WAYS (a give-back is what a sentiment overshoot does, but a -23.55 pct single-session reversal also says the post-event price is not a stable anchor to underwrite convergence against); CONTINUATION of the 2026-08-19 event, not a new qualifying event, so no fresh B identity is minted; no disposition change, candidacy unchanged, index-only
```

---

## PROCESS NOTES

**1. A MEASUREMENT-INTEGRITY DEFECT WAS CAUGHT, AND IT WOULD HAVE BEEN INVISIBLE IN A WELL-FORMED TABLE.** One price-measurement sub-agent's **30-way parallel `get_price_history` batch returned internally SHIFTED results** — rows from roughly the midpoint onward carried another ticker's series, and the final three tickers returned nothing at all. The agent caught it by cross-check and re-measured every value in batches of ≤6 matched by `contract_id`, several double-confirmed. Because that failure mode produces a table that *looks* correct, the orchestrating session then independently re-pulled the **four decision-critical bars** straight from IBKR: **WMT 114.30 → 103.84 (−9.15%), ISRG 397.72 → 374.48 (−5.84%), RTX 220.35 → 212.29 (−3.66%), GEV 987.46 → 966.01 (−2.17%) — all four confirmed EXACT.** Independent corroboration also exists for eight further closes where FMP's most-active table and the IBKR bars agree to the cent (SPY 762.60, NVDA 216.85, INTC 92.13, WMT 103.84, MRNA 133.32, SMCI 36.50, MSTR 112.39, MARA 11.15). **Operational rule this establishes: do not issue wide parallel `get_price_history` batches from a single agent; keep batches small, match every response by `contract_id` rather than by request order, and spot-verify any figure a decision turns on.** Recorded in the screen's `measurement_integrity` field so it survives this file's overwrite.

**2. THE SINGLE-NAME SCREEN WAS CORRECTED APPEND-ONLY, AND THE REASON IS WORTH KEEPING.** The original `research-screen` row (`bc9a1f62-b1b7-4f7e-9e3b-cb2bae8abb75`) carried a completeness caveat saying the population was a bounded sample. Within twenty minutes that caveat cashed out: a second measurement pass surfaced **three further names clearing B's ≥5% floor — NDSN, MRVL and STLD** — one of which (MRVL) had qualified on the **prior** session and been missed then too. A complete replacement was appended via `ops.sp_log_decision` with `entry_type='research-screen'` preserved, tag `correction`, and `in_superseded_by=bc9a1f62…`. **The original was not touched — no UPDATE, DELETE or MERGE.** That the correction was needed at all is the honest measure of how bounded the enumeration is, and it is stated in the replacement's own caveat rather than smoothed away.

**3. FMP's partial-batch defect fired for the third consecutive session.** `company/batch-market-cap` called with **18 symbols returned exactly 3 rows** (WMT $826,367,027,200; MRNA $52,899,509,520; BABA $312,863,717,432) with HTTP 200 and no marker for the 15 dropped names. A single-symbol retry for AAP returned `ACCESS DENIED` (free-tier symbol allow-list). Per the binding reconciliation rule this is reported as **missing evidence, not an empty result**: caps for AAP, WOLF, ROST, DE, ISRG, CRWD, TEM, MU, NTES, ATHM and five micro-caps are **unverified this run**. DE/ISRG/CRWD/MU/TEM/ROST are unambiguously ≥$2B on any reasonable reading; **AAP and WOLF are the genuinely borderline pair, and their population-rail eligibility is asserted on judgment, not measured.** NDSN (~$17.3B), MRVL (~$189–205B) and STLD (~$31–37B) caps came from independent aggregators via a verification pass, not from FMP.

**4. FMP's sector snapshot silently applied an exchange filter again.** `marketPerformance/sector-performance-snapshot` called for 2026-08-20 with **no `exchange` argument** returned rows all stamped `"exchange":"NASDAQ"`. Second consecutive session. Discarded in full; every sector figure in this file comes from IBKR sector-ETF daily bars.

**5. Claims deliberately NOT relied upon.** (a) Same-day automated content attributing ISRG's decline to competitor clearances — resolved as stale (July 2026 / December 2025), not merely doubted. (b) A GEV-attribution source that visibly leaked an LLM reasoning preamble into its published text. (c) A Yahoo Walmart article whose figures belong to the May 2026 Q1 FY27 print. (d) An ONDS "Q2 earnings miss" framing whose actual print was 2026-08-13 and was a beat. (e) A SOFI Piper Sandler story dated 2026-08-17 whose "Thursday" framing almost certainly refers to 2026-08-13. (f) FMP's BABA `epsActual 0.16`, which reconciles to neither the GAAP $0.55 nor the non-GAAP $1.26 per ADS. (g) A third-party tracker reporting BABA down ~3.6% for the session against our measured **+1.26%** — the IBKR regular-session daily bar governs per §19 PRICE BASIS, and the discrepancy is recorded, not reconciled. (h) Intraday index figures from a Benzinga piece (S&P −0.38%, Nasdaq −0.49%) and a "Russell 2000 +0.50%" claim, all contradicted by our own IBKR close-to-close measurements.

**6. FRONTIER-LLM CAPABILITY CHECK — run, no capture.** One `hf_fs` paper search (Thursday rotation: sycophancy / anchoring). Five results returned; the newest was published **2026-06-15**, i.e. **none published since the last D1 run**. No paper bears on a documented `AI_Trading_Foundation.md` disadvantage within the window, so no `[HF Frontier-LLM Capture]` entry and no `state.strategy_candidates` row is written. Default-silent on ambiguity, as specified.

**7. Sub-agent fan-out honoured the shared-pull rule.** The orchestrating session pulled the FMP movers lists, earnings calendar and sector snapshot **once, before spawning anything**, and passed them into each sub-agent prompt as literal text with an explicit instruction not to re-fetch. Eight sub-agents ran; the four price-measurement agents were given IBKR-only mandates with metered tools explicitly forbidden. Per-agent call budgets were stated in every prompt along with what to do on exhaustion, and every prompt carried an explicit instruction **not** to pass `include_usage` to Tavily (the parameter does not exist in this server's schema — the correction landed in `Claude_Task_Plan.md` on 2026-08-19, and it held: zero agents burned retries on it this run).

**8. Two research budgets were exhausted and the truncation is surfaced rather than implied.** The single-name attribution agent spent 16/16 Tavily and 8/8 WebSearch calls and left six S&P 500 names showing ≥3% moves unresearched (CF, TPL, LYB, CBOE, IQVIA, Charter). The held-position agent spent 18/18 Tavily calls and did not complete a same-day percentage sweep of the power complex or a direct FDA MAUDE query for ISRG. Both gaps are named in the relevant sections rather than left to be inferred from silence.

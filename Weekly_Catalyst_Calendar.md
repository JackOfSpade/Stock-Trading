2026-W32

# Weekly Catalyst Calendar — Strategies A and C

Run date **2026-08-09** (Sunday — the `weekly_sun` slot; ISO week **2026-W32** per `state.trading_day_today.today`). Windows measured from the run date: **Strategy A = 6 months (2026-08-09 → 2027-02-09); Strategy C = 45 days (2026-08-09 → 2026-09-23).** The upcoming trading week begins Monday **2026-08-10**, which is ISO week 2026-W33 — stated here in prose deliberately, because the file marker is the ISO week of *today*, never the upcoming trading Monday's.

**The marker is unchanged from the previous file, and that is correct, not stale.** The prior W1 run was Monday **2026-08-03** — a catch-up for the missed W31 cycle — and Monday 08-03 and Sunday 08-09 are the first and last days of the *same* ISO week. So this is a **same-week refresh at the regular Sunday slot**, six days of new evidence on top of the 08-03 file, not a re-stamp of stale research. W2/W3/W4/W5 all run today and stamp 2026-W32 as well, so the W4 upstream-freshness gate (which computes "current period" as the plain ISO week of today) matches.

**Catch-up window.** `state.routine_catchup_window` for W1: `window_start_ts` = 2026-08-03, `never_completed = false`, `window_days = 5.63`. That is below the weekly 1.5× threshold (10.5 days), so **no `CATCHUP[]` token** is owed and no missed-period sub-section is needed. The evidence window below is 2026-08-03 → 2026-08-09.

**Regime context (`state.current_regime`; M1a scored 2026-08-01).** Integrative call **"stagflationary shock + hawkish policy"** — growth_momentum **decelerating**, inflation_trend **stable**, policy_stance **hawkish**, risk_sentiment **neutral**, shock_overlay **acute**. Technical plane as of the 2026-08-07 close: SPY_TREND **UP** (close 773.26 > 50d 747.19 > 200d 702.97), EQUITY_BREADTH **HEALTHY** at **72.76%** — the highest reading in the recorded series, source-dated to 08-07 — VIX_REGIME **LOW** (14.90, a flip down through the 15.00 boundary from NORMAL on 08-06), SUSTAINED_INVERSION **NOT-SUSTAINED** (10Y−2Y +0.46).

**Router state — all five divergence reviews are now RESOLVED. Nothing is sub judice this cycle.** This is the first change of posture from the 08-03 file, which was written with A and C both pending.

| Strategy | Binding state (resolved 2026-08-05) | Change |
|---|---|---|
| **A** | **DO-NOT-ACTIVATE** (`div-A-202607-1`) | Unchanged; pending flag cleared |
| **B** | **DO-NOT-ACTIVATE** (`div-B-202607-1`) | **STATE CHANGE** — the M4 flip applied |
| **C** | **HYBRID ACTIVATE (FOMC-only)** (`div-C-202607-1`) | Unchanged; pending flag cleared |
| **D** | **DO-NOT-ACTIVATE** (`div-D-202607-1`) | **STATE CHANGE** |
| **E** | **ACTIVATE** (`div-E-202607-1`) | STATE CHANGE — execution-feasibility qualifier lifted in full |

A's DO-NOT-ACTIVATE survived on architecture rather than narrative: the `Strategy.md:123` reconciliation rule (growth_momentum = decelerating **AND** policy_stance = hawkish → override an A ACTIVATE to DNA) was satisfied on both preconditions, so a raw ACTIVATE would have been forced back regardless of the technical leg. **That matters this week, because the two preconditions moved in opposite directions** — see the tape section below. The adjudication of that tension belongs to M1a's next scoring (2026-09-01) and to M1b, not to W1; it is recorded here as dated context only.

**Capital state — the decisive change this cycle, and it runs the opposite way from last week's.** Under the REGIME-CAPITAL SYNC directive a DO-NOT-ACTIVATE strategy is swept to zero and its capital moves to enabled strategies. With B and D joining A on DNA as of 08-05, three of five strategies are now capital-disabled and **all the capital has concentrated into C and E**:

| Strategy | `capital_disabled` | NAV | Available funds | Outstanding regime-capital debt |
|---|---|---|---|---|
| A | **TRUE** | **$0.00** | $0.00 | **$3,888.45** (was $1,889.37 on 08-03) |
| B | **TRUE** | $101.18 | $0.00 | $4,870.19 (new) |
| C | FALSE | **$9,436.86** | **$9,436.86** | $0.00 |
| D | **TRUE** | $610.24 | $0.00 | $4,376.85 (new) |
| E | FALSE | $9,342.37 | $9,342.37 | $0.00 |

**Consequence for PART 2A:** unchanged in kind from last cycle but larger in degree — the A shortlist is a queue against a future router flip that also restores funding, not a list of presently-fundable entries. At A NAV $0.00 no A entry is executable at any size today; restoration is mechanical on `trigger=regime_enable`.

**Consequence for PART 2B — this is genuinely new and it is the most operationally significant fact in this file.** For several cycles the C section's conclusion rested partly on "no eligible structure fits the budget at current portfolio size." **C now holds $9,436.86 with all of it available.** The size-based deferral argument is materially weaker than it has been at any prior point in this record. Whether a *thesis* clears is unchanged and unaffected; what has changed is that a cleared thesis is now constructible.

**Operational state:** `state.trading_enabled` = **TRUE** (it was FALSE on 08-03), `state.system_health.all_green` = **TRUE**, marks and engine fresh through 2026-08-07, zero open critical alerts, zero firing kill flags. W1 stages nothing and is unaffected either way; this bears on W4's conversion of anything below.

**Open positions (for overlap/deconfliction), from `state.current_positions`:**
- **B:** ISRG (7/21), MSCI (7/27)
- **D:** AMZN ×2 (7/09, 7/30), GOOGL ×2 (7/09, 7/26), TSM ×2 (7/21, 7/29), CRM, DIS ×2 (5/07, 8/05), GEV, ISRG, RTX, UBER
- **No open A or C positions** → no A/C conflict on any candidate below.

Strategy.md prohibits **A/B** and **A/C** same-name simultaneous holding; there is **no A/D prohibition**. **Excluded from the A shortlist on the A/B rule: ISRG, MSCI.** (The 08-03 file also excluded FTV, MTZ and MDT; those B positions are no longer open.) D holdings may appear on the A shortlist, but any future A activation on one must first run the correlation-bucket check against the open D position — a sizing input, not a bar.

---

## Past-window tape (2026-08-03 → 2026-08-09)

*Facts only, each attributable to a source and date; sources at foot. Where two sources disagree the disagreement is recorded rather than resolved.*

**The week's defining event was Friday's labour print, and the market's reaction to it was the opposite of its sign.** July nonfarm payrolls printed **−23,000** against a consensus variously reported at +80k (LSEG), +83k (Dow Jones) and +95k (Stephens) — all agree on a large miss. **May and June were revised down a combined ~103,000.** The unemployment rate *fell* to **4.1%** from 4.2%, but the labour-force participation rate fell to **61.4%**, and average hourly earnings decelerated to **+3.2% YoY** ($37.62/hr) from 3.5%. U-6 flat at 7.9%; workweek unchanged at 34.3 hours. (BLS Employment Situation, released 2026-08-07.)

**Equities took it as a rate reprieve and rallied to a record.** S&P 500 closed **7,757.64** Friday (+0.62% on the day, **+3.6% on the week**, a record close); Nasdaq Composite **26,690.62** (+1.30% / **+5.2%**); Dow **54,036.93** (+0.28% / +3.0%); Russell 2000 **3,034.49** (+1.10% / +3.5%). All three major indexes posted their **biggest weekly gain since the week of 2026-04-13**. VIX closed **14.90**, down from 15.15 on 08-06. HY OAS tightened through the week to **271bp** (from 285bp on 07-31); CCC OAS 10.17%. *(IG OAS: no dated August read was obtainable — recorded as a gap, not filled from a stale figure.)*

**September-hike pricing collapsed, and the venues disagree on how far.** Post-print readings: **Polymarket 36% hike / 63% hold** (page-stated 2026-08-09 07:31 UTC, $20.2M volume — the only first-party live read obtained); **Investing.com's CME-derived monitor 43.4% hike / 56.6% hold** (page-stated 2026-08-08); press relays of CME FedWatch on 08-07 give hold at **56% (CBS), 58% implied (Barron's), 60% (CNBC)** — three different figures for the same day, unreconciled, likely different intraday snapshots. A **61.9% hike** figure circulating in search results could not be traced to any primary source and **is not used anywhere in this file**. Kalshi's own market page returned HTTP 429 and could not be read live; a 07-29-dated secondary relay had it 54% hike / 44% hold, which is stale by eleven days. **The honest summary: the market moved from roughly 56–62% hike a week ago to roughly 36–43% hike now, on one data point.** Year-end 2026 fed funds futures price the modal outcome at 3.75–4.00% (44.4%), with 3.50–3.75% at 23.2% and 4.00–4.25% at 27.2%.

**Treasuries, Friday 2026-08-07 close:** 2Y **4.21%**, 10Y **4.63%** (Trading Economics) or **4.65%** (YCharts) — a 2bp unreconciled discrepancy — 30Y **5.20–5.21%**. Barron's reported the 2Y's biggest one-week decline since June.

**Earnings adjudications, 08-03 → 08-07 — and the pattern is not the one the 08-03 file expected.**

| Ticker | Date | Print | Reaction |
|---|---|---|---|
| **PLTR** | 8/3 AMC | Rev $1.94B **+93% YoY** (beat ~$1.80–1.81B); adj EPS $0.41 vs $0.33–0.35; US commercial **+149%**; FY26 guide raised to $8.15–8.16B | **+29% on 8/4** to $162.66 |
| **VRTX** | 8/3 AMC | Rev $3.33B (+12.45%) beat by ~$110M; EPS $4.73, missed by $0.01–0.02; FY guide raised to $13.1–13.2B | −1.68% AH |
| **AMD** | 8/4 AMC | Rev $11.5B beat by 2.2%; non-GAAP EPS $1.66 vs $1.62; Q3 guide $12.7–13.3B vs $12.5B consensus — **but GAAP gross margin 54% (non-GAAP 56%) missed the 56% consensus** | **−7% to −9%** |
| **CAT** | 8/4 | Sales **$20.543B, +24% YoY** — first-ever quarter above $20B; adj EPS **$8.17** vs $4.72 YoY; op margin 20.9% vs 17.3%; **backlog $72.1B, +92% YoY** | +7% to +12% intraday (unreconciled); closed 8/7 at $842.19 |
| **DIS** | 8/5 BMO | Adj EPS **$2.06 (+28%)** beat $1.86–1.88; rev $25.248B (+7%) **missed** $25.48B; FCF $3.072B missed by ~15%; SVOD op income more than doubled to $712M; buyback target raised to ≥$9B | +3.65% (8/5), +2.87% (8/6), $104.91 on 8/7 |
| **UBER** | 8/5 | Rev $14.19–14.2B (+12%) ~in line; adj EPS $0.81 (+35%) beat $0.80; gross bookings +22% cc to $58.0B — **Q3 guide below expectations** | −3% to **−5.29%** (unreconciled) |
| **SHOP** | 8/5 | Rev $3.58B (+34%); GMV +32% to $116B; non-GAAP op margin 17.4% | **+17% to +21%** |
| **DDOG** | 8/6 BMO | Rev $1.12B **+36%** beat $1.08B; non-GAAP EPS $0.65 beat $0.58; FY guide raised — **but FCF margin contracted 29% → 25%, and a Q3 usage decline from its largest customer was disclosed** | **−17% to −19%** |
| **MRK** | 8/4 | Rev $16.61B (+5%); Keytruda $8.37B (+5%); reported **loss** of $0.13/sh on a $2.31 acquisition charge (Cidara/Terns); FY revenue guide raised to $66.3–67.3B, adj EPS guide cut to $2.66–2.76 | +0.6% to $128.54 |
| **PFE** | 8/4 | Rev $15.03B (+2.6%); adj EPS $0.77; FY revenue guide midpoint **raised $500M** to $60.5–62.5B | +2.14% |

**Two prints inverted the 08-03 file's central read, and they inverted it in the same direction.** **AMD beat on revenue, beat on EPS, guided Q3 above consensus — and fell 7–9%,** because the *margin* structure missed. **DDOG beat, raised, and fell 17–19%,** because a single customer's usage decline was disclosed. Both are "beat-and-fall" on a second-order disclosure. Set against **PLTR +29%** and **SHOP +17–21%** on outright growth blowouts, the operative distinction this week was not payer-vs-receiver at all — it was **whether the print's *composition* survived inspection**, independent of whether the headline beat.

**A separate, dated competitive fact landed on 08-05 and it cuts cleanly between two shortlist names:** NVDA won the **exclusive SpaceX AI-compute socket** — the design win AMD lost — and was the sole Magnificent-7 gainer that session at **+3.43%**, with Melius sizing roughly **$200B of incremental-revenue visibility**. AMD's own row records the loss alongside its beat, closing **−7.04%**.

**Macro, other releases.** ISM Manufacturing (released 08-03) **55.6%**, +2.3pts, highest since May 2022, new orders 56.7%. ISM Services (08-05) **54.1** vs 54.5 consensus — but **Prices Paid 70.3 vs 65.0 expected (reaccelerating)** and **Employment 47.4 vs 51.2 expected (contraction)**. Initial claims 199,000 for the week ending 08-01, 4-week average 198,750.

**The growth and policy axes moved in opposite directions this week, which is exactly the pair the A-router override keys on.** Payrolls −23k with −103k of revisions, participation down, wages decelerating, and ISM Services employment at 47.4 all *strengthen* `growth_momentum = decelerating`. The collapse in September-hike odds *weakens* `policy_stance = hawkish` — though only in market pricing, not in anything the Fed itself has said since the 07-29 meeting, at which **three members dissented in favour of a hike** (Hammack, Kashkari, Logan — the first three-member dissent for an identical alternative since September 2016). ISM Services Prices Paid at 70.3 cuts against the dovish read from the other side. **W1 does not adjudicate this; M1a re-scores 2026-09-01.** It is flagged because it is the single most consequential unresolved question for both strategies in this file.

**Geopolitics — the Hormuz de-escalation remains one-sided and unconfirmed, now for the sixth consecutive claimed resolution.** After Trump called off a planned strike on 08-02 and claimed "perimeters of a deal," Iran's foreign ministry denied on 08-03 that any bilateral talks existed, with Baghaei stating the strait's status "will in no way return to the status it was before February 28th." On 08-05 NPR reported Iran aims to ban US and Israeli ships and charge others a toll. On 08-07/08 FM Araghchi said Iran and Oman are "close to an agreement on a temporary transit route" but that reopening "remains subject to other conditions"; ISW assesses Iran is seeking further US concessions while retaining control of maritime traffic. Saudi Arabia, Turkey and Pakistan signed the "Mecca Joint Defence Agreement" on 08-08. Brent traded roughly **$82–86** Friday depending on source and contract month (unreconciled); WTI September settled **$78.18** (+1.15%). Gold **$4,401.30**, with two providers reporting incompatible same-day changes (+2.37% vs +0.04%) on an identical level — unreconciled.

**Not resolvable at run time:** July **CPI lands 2026-08-12** and **PPI 2026-08-13**, both inside the C window and both ahead of the 09-16 FOMC. M1a's own July scoring states the energy-led June disinflation "will mechanically re-inflate the July headline print." Those two prints are the nearest dated fulcrum in either window and neither has occurred.

---

## PART 1A — Strategy A universe catalyst calendar (6-month window, 2026-08-09 → 2027-02-09)

Universe: US-listed common equity, market cap ≥ $2B, 30-day ADV ≥ $10M, with a scheduled catalyst in the window. Date labels: **(C)** confirmed to a company/primary source · **(E)** estimated (recurring cadence, a stated window with no fixed day, or a calendar-feed entry without primary confirmation) · **(T)** tentative (sources conflict, or only a single low-quality aggregator carries it). No interpretation — facts only.

*Universe floor unchanged: AR_orc adjudicated `otr-A-marketcap-floor-2026` on 2026-07-30 → **HOLD**, with an explicit non-relaxation note.*

*Screening caveat, stated once and applying to every table in PART 1A: the $2B market-cap and $10M ADV thresholds were **not** independently re-verified per ticker this session — `mcp__FMP__quote` returned plan-tier ACCESS DENIED. Names are included on judgment as known large/mid-cap US listings. A name here is a candidate for the floor check, not a certification that it passed one.*

### 1A.1 — Earnings catalysts

**August 2026**

| Ticker | Name | Catalyst | Date | Source |
|--------|------|----------|------|--------|
| SE | Sea Limited | Q2 earnings, BMO | 2026-08-11 (C) | Sea Limited release via StockTitan |
| CSCO | Cisco | FQ4 FY26 earnings | 2026-08-12 (E) | FMP earnings calendar |
| JD | JD.com | Q2 earnings, BMO | 2026-08-13 (C) | JD.com/GlobeNewswire release |
| HD | Home Depot | Q2 earnings, BMO | 2026-08-18 (C) | ir.homedepot.com |
| BIDU | Baidu | Q2 earnings | 2026-08-18 (E) | FMP earnings calendar |
| LOW | Lowe's | Q2 earnings call | 2026-08-19 (C) | corporate.lowes.com |
| TGT | Target | Q2 earnings | 2026-08-19 (E) | FMP earnings calendar |
| TJX | TJX | FQ2 FY27 earnings, pre-09:30 ET | 2026-08-19 (C) | TJX release via BusinessWire |
| WMT | Walmart | Q2 FY27 earnings | 2026-08-20 (E) | FMP earnings calendar |
| ROST | Ross Stores | Q2 earnings, ~16:00 ET | 2026-08-20 (C) | Ross Stores release |
| **DE** | **Deere** | **FQ3 earnings call, 09:00 CT** | **2026-08-20 (C — CONFLICT RESOLVED)** | **deere.com release** — the 08-03 file carried an unresolved 8/13-vs-8/20 (T); the company's own release settles it at 8/20 |
| ZM | Zoom | Earnings | 2026-08-25 (E) | FMP earnings calendar |
| DKS | Dick's Sporting Goods | Q2 earnings call, 08:00 ET | 2026-08-25 (C) | Company release |
| **NVDA** | **NVIDIA** | **FQ2 FY27 earnings** | **2026-08-26 (E)** | FMP earnings calendar — *no primary IR confirmation obtained this session; the single most consequential date in the window rests on a calendar feed and should be re-verified by W4* |
| SNPS | Synopsys | FQ3 earnings, AMC | 2026-08-26 (C) | news.synopsys.com |
| CRWD | CrowdStrike | FQ2 FY27 earnings, AMC | 2026-08-26 (C) | ir.crowdstrike.com |
| BILI | Bilibili | Q2 earnings | 2026-08-27 (E) | FMP earnings calendar |
| DG | Dollar General | Q2 earnings, 09:00 ET | 2026-08-27 (C) | Dollar General release |
| WDAY | Workday | FQ2 FY27 earnings, AMC | 2026-08-27 (C) | Workday newsroom |
| MRVL | Marvell | FQ2 FY27 earnings call, 13:45 PT | 2026-08-27 (C) | Marvell announcement via StockTitan |
| DLTR | Dollar Tree | Q2 earnings release, BMO | 2026-08-27 (C) — aggregators conflict at 09-02 | **SEC 8-K exhibit** (primary, preferred over aggregators) |
| DELL | Dell | FQ2 FY27 earnings | 2026-08-27 (T) | Aggregator projection; no primary IR confirmation |
| ADSK | Autodesk | FQ2 FY27 earnings | 2026-08-27 (T) | Aggregator projection |
| LULU | Lululemon | Q2 earnings | 2026-08-27 (T) | Aggregator; secondary mentions of 9/3–9/4 also seen, unreconciled. *Search results were partly contaminated by a similarly-named company (LVLU) — treat with caution* |
| BBY | Best Buy | FQ2 FY27 earnings | ~2026-08-27 (T) | Prior-year cadence only |
| BABA | Alibaba | FQ1 FY27 (June qtr) earnings | 2026-08-28 (E) | FMP earnings calendar |
| ULTA | Ulta Beauty | Q2 earnings | ~2026-08-28 (T) | Sources conflated 2025/2026 dates |
| PDD | PDD Holdings | Q2 earnings, BMO | 2026-08-31 (E) | Single aggregator |

**September 2026**

| Ticker | Name | Catalyst | Date | Source |
|--------|------|----------|------|--------|
| NIO | NIO | Q2 earnings | 2026-09-01 (E) | FMP earnings calendar |
| PANW | Palo Alto Networks | FQ4 FY26 earnings, AMC | 2026-09-01 (C) | PANW release via Yahoo Finance |
| MDT | Medtronic | FQ1 FY27 earnings, 05:45 CT | 2026-09-01 (C) | Medtronic announcement via StockTitan |
| MDB | MongoDB | FQ2 earnings, AMC | 2026-09-01 (C) | MongoDB IR release |
| AEO | American Eagle | Q2 earnings | 2026-09-02 (T) | Single aggregator |
| SNOW | Snowflake | FQ2 FY27 earnings, AMC | 2026-09-02 (C) | snowflake.com release |
| AVGO | Broadcom | FQ3 FY26 earnings, AMC, 17:00 ET call | 2026-09-02 (C) | broadcom.com release |
| DOCU | DocuSign | FQ2 FY27 earnings | 2026-09-03 (E) | FMP earnings calendar |
| ZS | Zscaler | FQ4 FY26 earnings, AMC | 2026-09-03 (C) | Zscaler/GlobeNewswire release |
| KR | Kroger | Q2 earnings | 2026-09-04 (T) | Single aggregator |
| ADBE | Adobe | FQ3 FY26 earnings | 2026-09-10 (E) | FMP earnings calendar |
| ORCL | Oracle | FQ1 FY27 earnings, AMC | 2026-09-14 (E) | Multi-site web synthesis; no primary IR page obtained |
| FDX | FedEx | FQ1 FY27 earnings | 2026-09-17 (E) | FMP earnings calendar — **feed carries a duplicate conflicting FDX entry at 2026-10-28; recorded as a data-quality flag, not two events** |
| COST | Costco | FQ4 FY26 earnings, AMC | 2026-09-24 (C) | Marked confirmed across sources + FMP |
| CCL | Carnival | FQ3 earnings | 2026-09-28 (E) | FMP earnings calendar |
| MU | Micron | FQ4 FY26 earnings, AMC | 2026-09-29 (C) | Marked confirmed |
| NKE | Nike | FQ1 FY27 earnings | 2026-09-29 (E) | FMP earnings calendar |

**October 2026 (Q3 season)**

| Ticker | Name | Catalyst | Date | Source |
|--------|------|----------|------|--------|
| PEP / DAL / TLRY | PepsiCo, Delta, Tilray | Q3 earnings | 2026-10-08 (E) | FMP earnings calendar |
| **JPM** | **JPMorgan Chase** | **Q3 earnings call, 08:30 ET** | **2026-10-13 (C)** | **jpmorganchase.com release** |
| WFC / GS / C / JNJ | Wells Fargo, Goldman, Citi, J&J | Q3 earnings | 2026-10-13 (E) | FMP earnings calendar |
| MS | Morgan Stanley | Q3 earnings | 2026-10-14 (T) | Aggregator |
| BAC | Bank of America | Q3 earnings | 2026-10-14 (E) | FMP earnings calendar |
| SCHW | Charles Schwab | Q3 earnings, BMO | 2026-10-15 (E) | Aggregator synthesis |
| TSM | TSMC | Q3 earnings | 2026-10-15 (E) | FMP earnings calendar |
| SLB | SLB | Q3 earnings | 2026-10-16 **or** 2026-10-23 (T) | Two aggregators disagree; unresolved |
| NFLX / GM / GE / LMT / KO / VZ | Netflix, GM, GE Aerospace, Lockheed, Coca-Cola, Verizon | Q3 earnings | 2026-10-20 (E) | FMP earnings calendar |
| IBM | IBM | Q3 earnings, AMC | 2026-10-21 (E) | Web synthesis |
| UAL | United Airlines | Q3 earnings | 2026-10-21 (E) | FMP earnings calendar |
| HON | Honeywell | Q3 earnings | 2026-10-22 (T) | Aggregator |
| AAL / F / NOK / INTC | American, Ford, Nokia, Intel | Q3 earnings | 2026-10-22 (E) | FMP earnings calendar |
| MA | Mastercard | Q3 earnings | 2026-10-22 (T) | Aggregator |
| AXP / HCA | AmEx (AMC), HCA | Q3 earnings | 2026-10-23 (E) | Aggregator marked confirmed / FMP |
| UNH / PYPL / CARR / V / SOFI | UnitedHealth, PayPal, Carrier, Visa, SoFi | Q3 / FQ4 earnings | 2026-10-27 (E) | FMP earnings calendar |
| MSFT | Microsoft | FQ1 FY27 earnings | 2026-10-27 **or** 2026-10-28 (T) | FMP says 10/28; one aggregator marks 10/27 "confirmed"; unresolved |
| TSLA | Tesla | Q3 earnings, AMC | 2026-10-28 (E) | FMP; one aggregator gives an unconfirmed 10/21–23 |
| BA / GOOGL / META / SBUX / T | Boeing, Alphabet, Meta, Starbucks, AT&T | Q3 / FQ4 earnings | 2026-10-28 (E) | FMP earnings calendar |
| AAPL / AMZN / RBLX / COIN / SIRI / RKT | Apple (FQ4, AMC), Amazon, Roblox, Coinbase, SiriusXM, Rocket | Q3 / FQ4 earnings | 2026-10-29 (E) | FMP earnings calendar |
| MRK | Merck | Q3 earnings | 2026-10-29 (T) | Aggregator |
| XOM / CVX / ABBV | Exxon, Chevron, AbbVie | Q3 earnings | 2026-10-30 (E) | FMP earnings calendar |

**November 2026 – February 2027**

| Ticker | Name | Catalyst | Date | Source |
|--------|------|----------|------|--------|
| PLTR / FUBO | Palantir, FuboTV | Q3 earnings | 2026-11-02 (E) | FMP earnings calendar |
| UBER / SHOP / AMD / PFE / PINS / RIVN | Uber, Shopify, AMD, Pfizer, Pinterest, Rivian | Q3 earnings | 2026-11-03 (E) | FMP earnings calendar |
| SNAP / ROKU / ET / ETSY / LCID / MGM / HOOD | Snap, Roku, Energy Transfer, Etsy, Lucid, MGM, Robinhood | Q3 earnings | 2026-11-04 (E) | FMP earnings calendar |
| MRNA | Moderna | Q3 earnings | 2026-11-05 (E) | FMP earnings calendar |
| SONY / RIOT | Sony (FQ2), Riot | Earnings | 2026-11-10 (E) | FMP earnings calendar |
| QCOM | Qualcomm | FQ4 FY26 earnings | 2026-11-11 (T) | Single aggregator |
| DIS | Disney | FQ4 FY26 earnings | 2026-11-12 (E) | FMP earnings calendar |
| **JPM** | **JPMorgan Chase** | **Q4 earnings call, 08:30 ET** | **2027-01-14 (C)** | **jpmorganchase.com release** |
| NFLX | Netflix | Q4 earnings | ~2027-01-20 (T) | Single aggregator snippet |
| AMZN | Amazon | Q4 earnings | ~2027-02-05 (T) | Aggregator estimate |

**Declared coverage gaps in 1A.1 — an omission below is an acknowledged absence of a *retrieved date*, never an assertion that no event exists.** No 2026-specific date was obtainable for **GIS, CPB, ACN** (all expected to report in the September window on prior-year cadence). The **December 2026 – February 2027** block is thin by necessity: only JPM has a company-confirmed date; **AAPL, TSLA, MSFT, GOOGL, META, BAC, WFC, C, GS** and the large retailers have announced nothing yet for that period. Semis/industrials not individually searched: **LRCX, AMAT, KLAC, NXPI, TXN**. Per-ticker market-cap/ADV screening was not run.

**CRM — an unreconciled conflict that W4 must not paper over.** Two internal records written on 2026-08-05 and 2026-08-07 (the `recheck-CRM-crpo-D-20260812` queue entry and the `Watchlist.md` A-queue row) state that **CRM printed FQ2 after the 2026-08-05 close**, with figures: adj EPS **$2.91 vs $2.78** consensus, FY revenue guide **raised to $41.0–41.3B** against $41.24B consensus, **+1.04% RTH and −5.58% after hours**. Against that, a StockTitan relay of a Salesforce IR item retrieved this session gives **CRM FQ2 earnings 2026-08-26 AMC**. These cannot both be right. **MEASURED:** the internal records carry specific printed figures, which a date-only aggregator entry does not. **INFERRED, and flagged as weakening the internal record:** a 2026-08-05 release would be only five days after a July-31 quarter end, an implausibly short reporting lag for this company. **Not verified against Salesforce's own IR page**, which no agent fetched directly this session. The existing `recheck-CRM-crpo-D-20260812` queue entry (due 2026-08-12) is the mechanism that will resolve it; nothing further is enqueued here. CRM is carried below at a **reduced** rank precisely because its catalyst position in the window is unresolved.

### 1A.2 — Product launches / product events

| Ticker | Name | Catalyst | Date | Source |
|--------|------|----------|------|--------|
| DIS | Disney | **D23: The Ultimate Disney Fan Event** — franchise/content slate reveals | 2026-08-14 → 08-16, Anaheim (C) | thewaltdisneycompany.com |
| AAPL | Apple | Autumn iPhone keynote (iPhone 18 Pro / first foldable), retail ~09-18 | ~2026-09-09 (T) | No Apple confirmation; consistent rumour cluster + historic first-week-of-September cadence |
| CRM | Salesforce | Dreamforce 2026 | 2026-09-15 (T) | Single secondary event tracker, not Salesforce-primary |
| QCOM | Qualcomm | **Snapdragon Summit 2026** — next flagship chipset unveil | 2026-09-22 → 09-24, Maui (C) | Qualcomm event page |
| NVDA | NVIDIA | **GTC Berlin 2026** | 2026-10-20 → 10-22 (C) | NVIDIA GTC official account |
| ADBE | Adobe | Adobe MAX 2026 | 2026-11-10 (T) | Single secondary tracker |
| **TTWO** | **Take-Two / Rockstar** | **Grand Theft Auto VI launch** (PS5, Xbox Series X/S); digital preload 11-12; preorders opened 06-25 | **2026-11-19 (C)** | Rockstar Newswire + Take-Two IR, corroborated by IGN |
| AMZN | Amazon / AWS | AWS re:Invent 2026 | 2026-11-30 → 12-04, Las Vegas (C) | aws.amazon.com events page |
| — | CES 2027 | Consumer Electronics Show | 2027-01-06 → 01-09, Las Vegas (C) | ces.tech + CTA |
| — | Detroit Auto Show 2027 | World debuts | 2027-01-14 → 01-24 (C) | detroitautoshow.com |
| — | LA Auto Show 2026 | World/NA debuts | 2026-11-20 → 11-29 (C) | laautoshow.com |
| — | Samsung Galaxy Unpacked (S27) | Flagship unveil | Late Jan / early Feb 2027 (T) | Rumour cycle; sources conflict between early January and mid-February |

*Ecosystem-adjacent, not itself a listed-equity catalyst: **OpenAI DevDay 2026, 2026-09-29, San Francisco (T)** — secondary aggregator only.*

### 1A.3 — Analyst / investor days & major industry conferences

| Ticker | Name | Catalyst | Date | Source |
|--------|------|----------|------|--------|
| INTU | Intuit | Investor Day 2026 | 2026-09-17 (C) | Carried forward from the 08-03 file's company-confirmed entry |
| — | Goldman Sachs Communacopia + Technology Conference | Major tech investor conference | 2026-09-09 (T) | Search-result snippet; not verified on Goldman's own site |
| ON | onsemi | **Financial Analyst Day 2026**, NYC | 2026-09-16 (C) | investor.onsemi.com |
| QCOM | Qualcomm | Snapdragon Summit (investor-relevant) | 2026-09-22 → 09-24 (C) | cross-listed from 1A.2 |
| AMZN | Amazon | AWS re:Invent (guidance-relevant cloud/AI event) | 2026-11-30 → 12-04 (C) | cross-listed from 1A.2 |
| — | **ASH Annual Meeting 2026** (hematology/oncology) | Data readouts material to heme-onc pipelines | 2026-12-12 → 12-15, New Orleans (C) | hematology.org |
| — | **45th J.P. Morgan Healthcare Conference** | The sector's principal guidance-setting event | **2027-01-11 → 01-14, San Francisco (C)** | jpmannualhealthcareconference.com + thebiocalendar.com |

*Gap: no in-window analyst day was found for the large semiconductor names (MU, AMD, INTC); Morgan Stanley TMT's 2026 edition was in March, outside the window. A per-sector conference sweep was not run to exhaustion.*

### 1A.4 — Regulatory decisions

**FDA — PDUFA / action dates, sponsors ≥ $2B, inside the window**

| Date | Ticker | Company (approx. cap) | Drug / indication | Type + designation | Conf. | Source |
|------|--------|------------------------|-------------------|--------------------|-------|--------|
| 2026-08-13 | LNTH | Lantheus (~$7.1B) | MK-6240 tau-PET, Alzheimer's dx | NDA, Fast Track | **C** | Lantheus IR |
| **2026-08-17** | **MRK** | **Merck (mega-cap)** | **Keytruda / Keytruda QLEX + Padcev, cisplatin-eligible MIBC** | **sBLA, Priority** | **C** | **merck.com — NEW this cycle; absent from the 08-03 file** |
| 2026-08-17 | BMY | Bristol Myers Squibb | Iberdomide + dara/dex, r/r multiple myeloma | NDA, Priority, Breakthrough | C | news.bms.com |
| 2026-08-23 | RARE | Ultragenyx (~$2.5–2.8B, borderline) | DTX401, GSD-Ia | BLA, Priority | C | ir.ultragenyx.com |
| 2026-08-25 | JAZZ | Jazz Pharmaceuticals (~$15.8B) | Ziihera + Tevimbra, 1L HER2+ gastric/GEJ | sBLA, Priority | C | investor.jazzpharma.com |
| 2026-08-27 | GILD | Gilead (mega-cap) | Bictegravir/lenacapavir, HIV-1 suppressed | NDA, Priority | C | gilead.com |
| ~2026-08-31 | REGN | Regeneron (mega-cap) | Garetosmab, FOP | BLA, Priority | **T** | Regeneron IR states only "**August 2026**"; the day-level date is aggregator-only |
| 2026-09-11 | TLX | Telix (~$3.4B ADR) | TLX101-Px (Pixclara), glioma imaging — **CRL resolution** | NDA, Orphan, Fast Track | C | telixpharma.com |
| **2026-09-18** | **NUVL** | **Nuvalent (~$9.8B)** | **Zidesamtinib, ROS1+ NSCLC (TKI pre-treated)** | **NDA, Priority, Breakthrough** | **C** | **Nuvalent PR — NEW this cycle** |
| 2026-09-19 | RARE | Ultragenyx | UX111, Sanfilippo A — **CRL resolution** | BLA, accelerated | C | ir.ultragenyx.com |
| **2026-09-22** | **IONS** | **Ionis (~$9B)** | **Zilganersen, Alexander disease** | **NDA, Priority, Breakthrough** | **C** | **ir.ionis.com — NEW this cycle** |
| **2026-09-23** | **GRAL** | **GRAIL (~$3.2B)** | **Galleri MCED test — device PMA AdComm**, not a drug PDUFA | Molecular & Clinical Genetics Panel | **C** | FDA via @US_FDA; RTTNews |
| 2026-09-26 | MIRM | Mirum (~$6.4B) | Zilurgisertib, FOP | NDA | T | Secondary aggregators only |
| 2026-09-30 | ROIV | Roivant/Priovant (~$25B) | Brepocitinib, dermatomyositis | NDA, Priority | **T/E** | Roivant's own release says only "**Q3 2026**"; the day is aggregator-only |
| 2026-09-30 | SRRK | Scholar Rock (~$6.2B) | Apitegromab, SMA | BLA | T | Two aggregators agree; no primary checked |
| 2026-10-20 **or** 10-23 | REGN | Regeneron | Pozelimab + cemdisiran, VEXAS | BLA, Priority | T | Sources conflict on the date; no primary located |
| Nov 2026 (undated) | REGN | Regeneron | Cemdisiran, generalised myasthenia gravis | NDA, Priority (PRV) | E | Regeneron IR: "**November 2026**", no day |
| 2026-11-14 | CYTK | Cytokinetics (~$10.7B) | MYQORZO (aficamten) sNDA, obstructive HCM | sNDA, Priority | C | ir.cytokinetics.com |
| 2026-11-14 | SMMT | Summit Therapeutics (~$12B) | Ivonescimab + chemo, EGFR-mut NSCLC post-TKI | BLA, Priority | C | Summit 8-K |
| 2026-11-27 | NUVL | Nuvalent | Neladalkib, ALK+ NSCLC (TKI pre-treated) | NDA, Priority | C | Nuvalent PR |
| 2026-11-27 | BBIO | BridgeBio (~$13–16.5B) | BBP-418, LGMD2I/R9 | NDA | T | Single aggregator |
| 2026-11-30 | VRTX | Vertex (mega-cap) | Povetacicept, IgA nephropathy | BLA | **T — DOWNGRADED** | Single aggregator. *The 08-03 file carried this as (C); no primary source supports that and it is corrected here* |
| 2026-12-22 | MLYS | Mineralys (~$2.2B, borderline) | Lorundrostat, uncontrolled/resistant hypertension | NDA | C | Company reporting |
| 2026-12-23 | GILD | Gilead | Anito-cel, r/r multiple myeloma | BLA | T | Single aggregator |
| **2026-12-27** | **PRAX** | **Praxis (~$8.5B)** | **Relutrigine, SCN2A/SCN8A DEE — date EXTENDED from 2026-09-27** after FDA classified additional sensitivity-analysis data a "major amendment" (announced 2026-06-29); no new studies requested, no safety/manufacturing issue cited | NDA, Priority | **C** | GlobeNewswire |
| 2026-12-30 | COGT | Cogent (~$6.6–7.3B) | Bezuclastinib, non-advanced systemic mastocytosis | NDA | T | Single aggregator |
| 2027-01-21 | DYN | Dyne (~$4.6–4.8B) | Z-rostudirsen, DMD exon-51 | BLA, Priority, accelerated | C | GlobeNewswire |
| 2027-01-29 | PRAX | Praxis | Ulixacaltamide, essential tremor | NDA | T | Single aggregator |

**Corrections and resolutions to the 08-03 file's FDA table — all verified this session:**
- **MRNA mRNA-1010 seasonal flu: APPROVED 2026-08-05** as **mFLUSIVA** — standard approval ages 50–64, accelerated approval (surrogate endpoint) for 65+ with a required post-marketing trial. Resolved, out of the window, and no longer a catalyst.
- **The "MRK Winrevair sNDA 2026-09-21 (C)" entry the 08-03 file carried — and ranked on — could not be corroborated and should be treated as WITHDRAWN.** The only Winrevair/ZENITH label-expansion sBLA traceable to a Merck primary source was **already approved in October 2025** (PDUFA 2025-10-25). Two aggregator scrapes carry the 09-21 date; no Merck source does. This directly affects the 08-03 file's PART 2A rank #31, which cited "Winrevair sBLA 9/21 (C)" as one of two stacked pipeline catalysts.
- **RARE UX111 (2026-09-19) has moved INSIDE the C window** as the window rolled forward; the 08-03 file recorded it as two days outside.
- Still undated at day level, and therefore not rankable as dated events: **TAK/PTGX rusfertide (Q3 2026)**, **ROIV brepocitinib (Q3 2026 per primary)**, **REGN garetosmab (August 2026 per primary)**, **REGN cemdisiran (November 2026 per primary)**.
- **Near-boundary, just past 2027-02-09:** SRPT (Amondys 45 + Vyondys 53 accelerated-to-traditional conversion) and BMRN (Voxzogo conversion), both **2027-02-28** — ~19 days outside. SRPT's market cap is reported anywhere from ~$1.6B to ~$2.4B across sources and could not be pinned down; its floor eligibility is genuinely unresolved.
- Excluded on the ≥$2B floor or on non-US listing, recorded so a later reader does not re-flag them: CAPR (~$237M), SVRA (~$1.1–1.5B), VNDA (~$310–430M), XSPRY (Nasdaq Stockholm), PharmaEssentia (TWSE), Advicenne (Euronext), Deciphera (delisted 2024), Zydus (India-listed). **ITM Isotope Technologies Munich (177Lu-edotreotide, PDUFA 2026-08-28)** could not be resolved either way — sources conflict on whether it completed a 2026 Nasdaq IPO or remains private.

**Non-FDA regulatory / legal decisions**

| Ticker | Matter | Catalyst | Date | Source |
|--------|--------|----------|------|--------|
| **Large-cap pharma (PFE, MRK, LLY, ABBV, BMY, JNJ et al.)** | **Section 232 patented-pharmaceutical tariff (100% duty)** | **Compliance / full-effect deadline for the 17 Annex III-named companies** | **2026-09-29 (C)** | CBP CSMS guidance 2026-07-30; Federal Register 91 FR 18183 |
| CHTR | Charter–Cox merger | Federal (DOJ/HSR) antitrust-clearance expiry — close by this date or refile | 2026-09-15 (C) | Charter's own CPUC filing |
| GOOGL | US v. Google search-monopoly appeal (D.C. Cir. 26-5023) | Google's reply brief due | 2026-09-29 (C) | D.C. Circuit docket via Courthouse News |
| GOOGL | Same | Oral argument | Not yet scheduled; estimated late 2026 / early 2027 (E) | Multiple outlets, all estimating |
| **AMZN** | **FTC v. Amazon antitrust** | **Bench trial begins** | **2027-02-09 (C)** — the exact last day of the window | MLex / Law360 on the W.D. Wash. amended scheduling order |
| UNP / NSC | Union Pacific–Norfolk Southern | STB merger review — supplemental filing made 07-27; proceeding continues | No decision date set (E) | stb.gov docket |
| COIN + crypto-exposed | Senate Digital Asset Market CLARITY Act | Motion-to-proceed vote | Week of 2026-09-15 (T) | CoinDesk 2026-08-08: "hanging by a thread," timeline explicitly uncertain |
| META | FTC v. Meta appeal | Appeal pending at D.C. Circuit | No argument or decision date located (gap) | AP / court reporting |
| AAPL | DOJ v. Apple smartphone monopoly | No trial date set; settlement talks reported active | No date (E) | Bloomberg / MacRumors, July 2026 |
| KR / ACI | Kroger–Albertsons $600M termination-fee suit (Del. Ch.) | Trial | ~October 2026 (T) | One low-quality secondary source; **not corroborated — do not rely on it** |

*Context, not a forward catalyst: the Supreme Court ruled 2026-02-20 (6–3) that IEEPA does not authorise the "Liberation Day" tariffs; refund litigation over ~$81B remains active with no scheduled decision date inside the window.*

### 1A.5 — Restructuring / structural events

| Ticker | Company | Catalyst | Date | Source |
|--------|---------|----------|------|--------|
| **AAPL** | **Apple** | **CEO transition — John Ternus succeeds Tim Cook (Cook becomes Executive Chairman); Ternus joins the board the same day** | **2026-09-01 (C)** | Board-approved date confirmed via CNBC/BBC/Variety, 2026-04-20 |
| HON | Honeywell | Spin-off of Aerospace Technologies (third leg after Solstice) | "Second half of 2026", no fixed day (E) | Honeywell investor release |
| WBD / PSKY | Warner Bros. Discovery / Paramount Skydance | **"Ticking fee" to WBD shareholders begins** if unclosed; outside date pushed to as late as June 2027 | Ticking fee starts 2026-09-30 (C) | CNBC, 2026-07-24 |
| KMB / KVUE | Kimberly-Clark / Kenvue | Acquisition — contractual outside date (walk-away trigger); expected close "H2 2026" | Outside date 2026-11-02 (C); close window H2 2026 (E) | SEC 424B3; kenvue.com |
| GPN | Global Payments / Worldpay | Outside date, extendable in 6-month increments while approvals pend | 2026-10-16 (C, as extended) | GPN 8-K — **unresolved: no source confirmed whether the deal has already closed before 2026-08-09** |
| CMC | Commercial Metals | $600M increase to the repurchase authorisation (~$717M total capacity) | Announced 2026-08-05 (C); program ongoing | CMC release via StockTitan |
| LULU | Lululemon | CEO transition — Heidi O'Neill appointed CEO | Effective 2026-09-08 (T) | Secondary aggregator only, not Lululemon-primary |
| BA | Boeing | 777X FAA certification / first delivery | Conflicting: originally targeted Oct 2026, reporting now spans late 2026 into 2027 (T) | Multiple aviation outlets, all disagreeing |

*Completed before the window and recorded so they are not re-flagged as pending: Solstice Advanced Materials spin (Oct 2025), DuPont/Qnity (Nov 2025), Comcast/Versant (2026-01-05), BD Biosciences–Waters (2026-02-09), Keurig Dr Pepper–JDE Peet's (Apr 2026), AT&T–EchoStar spectrum (2026-07-28). The Kroger–Albertsons merger itself was terminated 2024-12-11; only the fee litigation is live.*

---

## PART 1B — Strategy C universe catalyst calendar (45-day window, 2026-08-09 → 2026-09-23)

C's qualifying event types **only**: corporate earnings (company IR), FDA PDUFA (FDA calendar / company disclosure), FOMC (Fed calendar). No interpretation. **Router reminder: only an FOMC-catalyst thesis is router-eligible this cycle (HYBRID ACTIVATE, FOMC-only); every earnings and FDA entry below is router-PARKED and is divergence context, not actionable.**

### 1B.1 — FOMC

| Event | Catalyst | Date | Source |
|-------|----------|------|--------|
| **FOMC** | Federal Open Market Committee — meeting **2026-09-15/16**, decision **Wednesday 2026-09-16**, **WITH Summary of Economic Projections / dot plot** | **2026-09-16 (C)** — the only FOMC decision inside the window | federalreserve.gov/monetarypolicy/fomccalendars.htm, fetched 2026-08-09 |

Remaining meetings, confirmed off the same Fed page: **2026-10-27/28** (decision 10/28, no SEP) · **2026-12-08/09** (decision 12/09, SEP) · **2027-01-26/27** (decision 01/27, no SEP) · **2027-03-16/17** (decision 03/17, SEP).

**Dated macro releases between now and the 09-16 decision** (context for a C thesis, not themselves C-qualifying events) — every one from a primary calendar page fetched this session unless noted:

| Release | Reference period | Date | Source |
|---|---|---|---|
| **CPI** | July 2026 | **2026-08-12** | bls.gov/schedule/news_release/cpi.htm |
| **PPI** | July 2026 | **2026-08-13** | bls.gov/schedule/news_release/ppi.htm |
| Retail sales (advance) | July 2026 | 2026-08-14 | Census via web search (census.gov direct fetch 404'd) |
| FOMC minutes | 07-28/29 meeting | ~2026-08-19 (E) | **Inferred from the standard three-week lag; the Fed page is not yet live and this is NOT confirmed** |
| PCE / personal income | July 2026 | 2026-08-26 | bea.gov/news/schedule |
| Jackson Hole symposium | — | 2026-08-27 → 08-29 | Kansas City Fed via web search |
| Employment Situation | August 2026 | 2026-09-04 | BLS schedule |
| **CPI** | August 2026 | **2026-09-11** | bls.gov/schedule/news_release/cpi.htm |

Two full CPI prints and one further payroll print land between this file and the decision.

### 1B.2 — Corporate earnings inside the 45-day window

Same dated set as PART 1A.1 on or before 2026-09-23, restated for C's convenience: SE **(C)** 8/11 · CSCO (E) 8/12 · JD **(C)** 8/13 · HD **(C)** / BIDU (E) 8/18 · LOW **(C)** / TGT (E) / TJX **(C)** 8/19 · WMT (E) / ROST **(C)** / **DE (C)** 8/20 · ZM (E) / DKS **(C)** 8/25 · **NVDA (E)** / SNPS **(C)** / CRWD **(C)** 8/26 · BILI (E) / DG **(C)** / WDAY **(C)** / MRVL **(C)** / DLTR **(C)** / DELL (T) / ADSK (T) / LULU (T) / BBY (T) 8/27 · BABA (E) / ULTA (T) 8/28 · PDD (E) 8/31 · NIO (E) / PANW **(C)** / MDT **(C)** / MDB **(C)** 9/1 · AEO (T) / SNOW **(C)** / AVGO **(C)** 9/2 · DOCU (E) / ZS **(C)** 9/3 · KR (T) 9/4 · ADBE (E) 9/10 · ORCL (E) 9/14 · FDX (E) 9/17. Sources per 1A.1.

### 1B.3 — FDA PDUFA (sponsors ≥ $2B) inside the 45-day window

| Date | Ticker | Company | Drug / indication | Event | Conf. |
|------|--------|---------|-------------------|-------|-------|
| 2026-08-13 | LNTH | Lantheus (~$7.1B) | MK-6240 tau-PET | NDA action | **C** |
| **2026-08-17** | **MRK** | **Merck** | **Keytruda ± QLEX + Padcev, cisplatin-eligible MIBC** | **sBLA, Priority** | **C — NEW** |
| 2026-08-17 | BMY | Bristol Myers Squibb | Iberdomide, r/r myeloma | NDA, Priority | **C** |
| 2026-08-23 | RARE | Ultragenyx (~$2.5–2.8B) | DTX401, GSD-Ia | BLA, Priority | **C** |
| 2026-08-25 | JAZZ | Jazz (~$15.8B) | Ziihera, 1L HER2+ gastric/GEJ | sBLA, Priority | **C** |
| 2026-08-27 | GILD | Gilead | Bictegravir/lenacapavir HIV | NDA, Priority | **C** |
| ~2026-08-31 | REGN | Regeneron | Garetosmab, FOP | BLA, Priority | **T** (primary says "August 2026" only) |
| 2026-09-11 | TLX | Telix (~$3.4B) | TLX101-Px, recurrent glioma | NDA (CRL resolution) | **C** |
| **2026-09-18** | **NUVL** | **Nuvalent (~$9.8B)** | **Zidesamtinib, ROS1+ NSCLC** | **NDA, Priority** | **C — NEW** |
| **2026-09-19** | **RARE** | **Ultragenyx** | **UX111, Sanfilippo A** | **BLA (CRL resolution)** | **C — newly IN-window** |
| **2026-09-22** | **IONS** | **Ionis (~$9B)** | **Zilganersen, Alexander disease** | **NDA, Priority** | **C — NEW** |
| **2026-09-23** | **GRAL** | **GRAIL (~$3.2B)** | **Galleri MCED — device PMA AdComm**, not a drug PDUFA | Advisory committee | **C — NEW** |

**Resolved before the window opened:** MRNA mRNA-1010 **approved 2026-08-05** as mFLUSIVA. **Withdrawn as unverifiable:** the MRK Winrevair 09-21 entry (see 1A.4). **In-window but undated, and therefore not rankable:** TAK/PTGX rusfertide and ROIV brepocitinib, both "Q3 2026" per primary sources. **Unresolvable eligibility:** ITM (PDUFA 2026-08-28), US-listing status conflicting.

---

## PART 2A — Strategy A preliminary ranked shortlist (48 candidates)

W4 reads this section verbatim.

**ROUTING — read this before the table. Two gates apply to A, and both are now settled rather than pending.** (i) **Router:** A = **DO-NOT-ACTIVATE**, resolved (no longer sub judice) by `div-A-202607-1` on 2026-08-05 — so every name below routes to the `Watchlist.md` A-queue with reason "router gate; queued for next M1 ACTIVATE," and **no thesis-construction is enqueued this cycle.** (ii) **Capital:** A is also capital-disabled at **NAV $0.00** with outstanding regime-capital debt now **$3,888.45** (it was $1,889.37 on 08-03 — the debt roughly doubled as the sweep continued). Even a router flip must restore funding before any entry is fundable; the restore is mechanical on `trigger=regime_enable`, so the two gates lift together. **The next scheduled resolution path is M1a's 2026-09-01 re-scoring, not another divergence review** — this cycle's reviews are all closed.

Rankings are explicit so the queue is ordered by conviction of narrative-misalignment when the router next flips. Per candidate: (a) hypothesised mispricing direction, (b) supporting public documents, (c) catalyst date, (d) overlap with open positions / the A-queue, (e) tier. Direction is a *preliminary* synthesis hypothesis — full thesis construction (adversarial counter-argument attacking **size as well as direction**; immutable at-entry price target and thesis-completion criteria per Strategy.md Entry criterion 3) happens in W4-scheduled sessions.

**MEASUREMENT NOTE — what is and is not measured below.** Implied volatility, historical (realised) volatility and IV percentile are **live IBKR `get_price_snapshot` reads taken 2026-08-09**; because US markets are closed on a Sunday these reflect the **Friday 2026-08-07 close**, not a live tick. They are available for 15 names (NVDA, AVGO, MRVL, ORCL, PANW, CRWD, SNOW, WDAY, DELL, CRM, MDB, LULU, plus TLT/IEF/SPY) — where a row cites no volatility figure, none was obtained, and **no remembered number is substituted anywhere in this file.** **Analyst price targets are absent by policy for the second consecutive cycle**: both FMP routes returned plan-tier ACCESS DENIED, and carrying a remembered consensus forward would be exactly the fabrication the extraction discipline forbids.

**This cycle's re-ranking theme: the discriminator stopped being *which side of the AI-capex trade a name is on*, and became *whether the print's composition survives inspection*.** The 08-03 file's read — misalignment migrated from "hyperscalers vs their own capex" to "semiconductors vs the hyperscaler documents that validated their demand" — was tested twice this week and failed both times in the same way. **AMD beat revenue, beat EPS, guided Q3 above consensus, and fell 7–9%** because gross margin came in at 54% (non-GAAP 56%) against a 56% consensus. **DDOG beat, raised full-year guidance, and fell 17–19%** because it disclosed a Q3 usage decline from its largest customer. Neither name was punished for its position in the capex chain; both were punished for a second-order line item underneath a headline beat. Set against **PLTR +29%** (revenue +93%, US commercial +149%) and **SHOP +17–21%** (revenue +34%, GMV +32%) — both outright growth blowouts with nothing awkward underneath — the operative 2026-W32 question for every catalyst-driven long is **not "is this name a payer or a receiver," but "what is the line item underneath the beat that the market will find."** That reorders the shortlist more than any macro input this week.

**A second, cleaner discriminator landed on 08-05 and it cuts between the top two semis.** NVDA won the **exclusive SpaceX AI-compute socket** — the design win AMD lost — and was the sole Magnificent-7 gainer that session (+3.43%), with Melius sizing ~$200B of incremental-revenue visibility. AMD's own queue row records the loss alongside its beat, closing −7.04%. This is a *documented, dated competitive outcome* rather than a sentiment read, and it is the single strongest reason NVDA holds #1 while AMD falls out of the top ten.

**The honest counter-case is macro, and it got better for equities and worse for the thesis-selection process at the same time.** Better: the September hike is now priced at only ~36–43%, the S&P made a record close, breadth hit 72.76% (the highest in the recorded series), VIX printed 14.90, and credit tightened to 271bp HY OAS. Worse: that entire repricing rests on **one** labour print, **July CPI lands 2026-08-12 and PPI 2026-08-13** — inside three trading days of this file — and M1a's own July scoring states the energy-led June disinflation "will mechanically re-inflate the July headline print." ISM Services Prices Paid at 70.3 (vs 65.0 expected) already points that way. **A shortlist built on the post-payrolls tape is two prints away from being re-adjudicated.** Thesis construction, not this shortlist, is where that gets resolved — but W4 should not read the rankings below as though the macro were settled.

### TOP-10

| # | Ticker | Direction | Supporting public documents | Catalyst (date) | Overlap |
|---|--------|-----------|------------------------------|-----------------|---------|
| 1 | **NVDA** | Bullish | Won the **exclusive SpaceX AI-compute socket 08-05** (+3.43%, sole Mag-7 gainer; Melius sizes ~$200B incremental-revenue visibility) — a dated competitive outcome, not a sentiment read. FQ1'27 already printed rev **$81.62B +85% YoY**, DC **$75.2B (doubled)**, EPS $1.87. **Still unprinted**, and MEASURED implied vol is *not* elevated into it: **IV 39.8% vs HV 40.3%** (implied below realised), IV %ile 50.8 / 44.4 / 49.0 — mid-range implied uncertainty ahead of the largest unresolved print in the window. Counter, live and unresolved: the 07-27 "circular financing" scrutiny (Burry short) that also drove NBIS −12.65% | **FQ2 FY27 earnings 2026-08-26 (E — feed-only, no primary IR confirmation this session; W4 should re-verify)**; GTC Berlin 10-20/22 (C) | A-queue (5/9) |
| 2 | **MRVL** | Bullish | Custom-silicon ramp (Google TPU / Amazon Trainium2 design-win pipeline); FQ1'27 record net revenue **$2.418B +28% YoY**, above guide midpoint, Q2 guide **$2.7B ±5%** and accelerating. MEASURED: **IV 90.3% vs HV 99.8%** — implied materially *below* realised — with IV %ile only **23.8% at 13 weeks**. Cheap implied uncertainty into a company-confirmed print is the cleanest measured setup in the top tier | **FQ2 earnings 2026-08-27 (C — upgraded, company-confirmed)** | A-queue (5/25) |
| 3 | **AVGO** | Bullish | Custom-AI ASIC pipeline + VMware EBITDA per the FQ2 print; consensus captures only the base-case ASIC ramp, not the 2H26 acceleration tied to hyperscaler capex. MEASURED: **IV 75.1% vs HV 54.8%** — the largest implied-vol premium among confirmed-date large caps — IV %ile 68.3 / 76.2 / 87.6. *Stated plainly: for an equity entry that premium is an entry-timing caution, not an attraction; it is the options market pricing a large move, not evidence of direction* | **FQ3 earnings 2026-09-02 (C, AMC, company release)** | A-queue (5/9) |
| 4 | **ORCL** | Bullish (deep re-base) | The **~$7B, 10-year DoD software-consolidation award (07-27, initial 5-yr tranche $3.31B)** ratifies the OCI-bookings/RPO thesis *at exactly the layer the thesis predicted*, +4.27% on the day — this is the rarest kind of evidence, a prediction confirmed in its own terms rather than by proxy. MEASURED: IV 70.8% vs HV 72.3%, IV %ile 68.3 / 77.8 / 88.8 | FQ1 FY27 earnings 2026-09-14 (E — no primary IR page obtained) | A-queue (5/9) |
| 5 | **INTC** | Bullish | Q2: rev **$16.1B +25% YoY** (fastest in 15+ years), **DCAI +59%**, GM back to 42%, capex raised >$20B, management "cannot keep up with orders" — **unrefuted by any subsequent disclosure**. The headline "$11B GAAP net loss" was independently verified as a **non-cash CHIPS-escrow mark-to-market** (non-GAAP +$2.2B), i.e. the most-cited bear datapoint is an accounting artifact. Stock fell −7.89% at print and three further sessions on sector sympathy to $81.88 (07-29) | Q3 earnings 2026-10-22 (E) | A-queue (5/12) |
| 6 | **CAT** | Bullish — RATIFIED, runway contested | The single largest confirmed document set in the industrial cohort, printed 08-04: sales **$20.543B +24% YoY** (first-ever quarter above $20B), adj EPS **$8.17 vs $4.72** YoY, op margin 20.9% vs 17.3%, **backlog $72.1B +92% YoY**, Energy & Transportation / power generation driven by data-centre demand, FY guidance raised. The queue row was converted from a bare acknowledgment to a concrete thesis on 08-04. **Counter, explicit and unresolved: the valuation-reset caveat** — the beat is substantially in the price (closed 08-07 at $842.19), so thesis-runway compression is the live objection | Q3 earnings ~2026-10-20 (E) | A-queue (5/1) |
| 7 | **TTWO** | Bullish — **NEW to the shortlist** | **Grand Theft Auto VI launches 2026-11-19 (C)**, confirmed by Rockstar Newswire *and* Take-Two IR, with digital preload 11-12 and preorders opened 06-25. A dated, company-confirmed, single-event structural catalyst of unusual magnitude for a US-listed name — precisely the "product launch / structural narrative marker" Strategy A Entry criterion 1 enumerates, and **entirely absent from the 08-03 shortlist**. Counter, and it is a real one: this is the most-telegraphed consumer launch of the year, so "under-reflected in consensus" is the part a thesis must actually establish rather than assume | **GTA VI launch 2026-11-19 (C)** | — (new) |
| 8 | **NUVL** | Bullish — **NEW to the shortlist** | **Two company-confirmed Priority-Review PDUFAs inside the window on one ~$9.8B sponsor**: zidesamtinib (ROS1+ NSCLC, TKI-pretreated) **2026-09-18**, and neladalkib / NVL-655 (ALK+ NSCLC, TKI-pretreated) **2026-11-27** — both Breakthrough-designated, both traceable to Nuvalent's own releases. Stacked dated binaries where the supporting documents *are* FDA acceptance letters rather than an interpretive read of a transcript. Counter: two binary regulatory outcomes are two ways to be wrong, and A takes the full notional as capital-at-risk with no stop | **PDUFA 2026-09-18 (C)** and **2026-11-27 (C)** | — (new) |
| 9 | **GEV** | Bullish | Q2 (07-22): rev $11.1B +22%, **orders +88% to $24.2B**, backlog **$176B** including **116GW of gas-power reservations** and **>$5B of 2026 data-centre orders**, FY26 guides raised — the same AI-power-demand document set as CAT (#6) but earlier in its own price cycle, and without CAT's just-printed valuation reset | Q3 earnings ~2026-10-20 (E) | **Open D position** (correlation check required, not a bar) |
| 10 | **MU** | Bullish — counter strengthened, rank held not raised | The load-bearing evidence is a *customer's own disclosure*: QCOM's FQ4 guide-down explicitly cited **"unprecedented increases in memory pricing"** as a cost driver. Plus HBM3E/HBM4 mix shift and DRAM tightness. **Against it, and new this week:** the memory cohort de-rated two consecutive sessions (WDC −13.03% on 08-06 then −3.81%; SNDK −6.81% then −3.68%) against a rallying XLK (+1.42% on 08-07), while MU itself decoupled +1.31% on 08-06 — and CXMT's Shanghai capacity expansion is a genuine supply-side counter, not a sentiment one | **FQ4 FY26 earnings 2026-09-29 (C, AMC)** | A-queue (5/9) |

### 11–20

| # | Ticker | Direction | Supporting public documents | Catalyst (date) | Overlap |
|---|--------|-----------|------------------------------|-----------------|---------|
| 11 | **AMD** | **Direction CONTESTED — demoted from #3** | The 08-03 thesis ("MI400 shipped 07-23, roadmap risk converted to product") was **ratified on product and refuted on everything else at the 08-04 print**: revenue $11.5B beat by 2.2%, non-GAAP EPS $1.66 vs $1.62, Q3 guide $12.7–13.3B vs $12.5B consensus — **and the stock fell 7–9% on gross margin 54% / non-GAAP 56% against a 56% consensus.** Compounded by losing the exclusive SpaceX socket to NVDA the next session. Shipping the silicon was necessary and demonstrably not sufficient; the contested variable is margin structure, which no document in the queue row addresses | Q3 earnings 2026-11-03 (E) | A-queue (5/29) |
| 12 | **PANW** | Bullish | Platformization + CyberArk cross-sell (XSIAM/SASE/Cortex) per the FQ3 print. MEASURED: **IV 61.3% vs HV 51.8%**, IV %ile 71.4 / 84.9 / **92.4** — implied uncertainty near its 52-week ceiling into a company-confirmed date | **FQ4 FY26 earnings 2026-09-01 (C, AMC)** | A-queue (5/31) |
| 13 | **CRWD** | Bullish | Falcon Flex + Charlotte AI net-new-ARR re-acceleration under-modelled at consensus. MEASURED: **IV 51.5% vs HV 53.6%** (implied *below* realised), IV %ile 73.0 / 70.6 / 84.5 — a rare combination of high percentile and sub-realised absolute level | **FQ2 FY27 earnings 2026-08-26 (C, AMC, ir.crowdstrike.com)** | A-queue (5/31) |
| 14 | **NOW** | Bullish — ratified at print | Q2 (07-22) beat: rev **$3.99B +24%**, adj EPS **$0.90 vs $0.76–0.86** consensus, subscription rev +24.5%, cRPO +21.5%, FY26 guide raised. The print ratified the thesis in its own terms; the misalignment is that the tape de-rated it anyway | Q3 earnings ~2026-10-21 (E) | A-queue (5/29) |
| 15 | **SNOW** | Bullish — **but the new DDOG objection reads directly across** | FQ1 FY27 +33% AH on the beat plus the **$6B AWS commitment**; Day-1 +36.48% and held. MEASURED: IV 90.0% vs HV 86.9%, IV %ile **93.7 / 96.8 / 98.4** — the highest implied-vol percentile in the shortlist. **The counter is structural, not sentimental:** DDOG's 08-06 disclosure of a Q3 usage decline from its *largest customer* is a consumption-model concentration risk that SNOW shares by construction, and it produced −17 to −19% on a beat-and-raise | **FQ2 FY27 earnings 2026-09-02 (C, AMC, snowflake.com)** | A-queue (5/25) |
| 16 | **AAPL** | **REFRAMED — the prior thesis is refuted, a different one replaces it** | The 08-03 read was refuted at print: beat both lines, Cook called it the "strongest June quarter," soft forward guidance drove **−7.4%, the worst day in a year**, followed by a China Renaissance downgrade to Hold with a **$280 PT (08-04)** — the first sell-side adverse datapoint against the capex-discipline framing. What replaces it is a **structural narrative marker with a confirmed date**: the **CEO transition effective 2026-09-01**, John Ternus succeeding Tim Cook (Cook to Executive Chairman, Ternus joining the board the same day), board-approved and confirmed since April, plus the ~09-09 (T) iPhone keynote. Direction is genuinely open and is not asserted here | **CEO transition 2026-09-01 (C)**; iPhone event ~2026-09-09 (T); FQ4 earnings 2026-10-29 (E) | A-queue (5/2) |
| 17 | **DELL** | Bullish | AI-server backlog conversion: FQ1 FY27 revenue **+88% YoY**, **AI-server revenue +757%**, ISG margin floor visible, FY27 guide raised; Dell World AI-Factory announcements. MEASURED: IV 62.9% vs HV 56.1%, IV %ile 46.0 / 55.6 / 72.5. **Date risk is now a two-cycle pattern:** 2026-08-27 remains **(T)** with no primary IR confirmation, the second consecutive cycle it has failed primary verification | FQ2 FY27 earnings 2026-08-27 (T) | A-queue (5/17) |
| 18 | **CSCO** | Bullish | FQ3: record revenue **$15.84B +12% YoY**, **AI-infrastructure orders doubled $5B → $9B**, third consecutive guide raise, +12.96% Day-1 | FQ4 FY26 earnings 2026-08-12 (E) — **the nearest dated catalyst in the top 20** | A-queue (5/9) |
| 19 | **INTU** | Bullish — **DEMOTED from #8, and the demotion is the point** | Investor Day **2026-09-17 (C)** is a real, dated, company-confirmed disclosure event. But the A-queue row added for INTU on 08-03 states "Bullish" and **names no driver, no figure, and no mechanism at all** — it is the weakest-documented row on the entire 38-name queue. Ranking a name top-10 on the strength of *having a date* over-weights the calendar against the documents, which is the specific error Strategy A Entry criterion 2 exists to prevent. It stays on the shortlist; it does not stay in the top tier until a mechanism is written | Investor Day 2026-09-17 (C) | A-queue (8/3) |
| 20 | **HPE** | Bullish | FQ2 FY26 print +29–37% after hours on AI-server + GreenLake hybrid-cloud demand | FQ3 earnings ~2026-09-02 (E) | A-queue (5/29) |

### 21–48 (rest tier)

| # | Ticker | Direction | Supporting public documents / disposition | Catalyst (date) | Overlap |
|---|--------|-----------|-------------------------------------------|-----------------|---------|
| 21 | MSFT | Bullish — realised at print | Azure +43%, total cloud +27% to $59.3B, rev $90.01B / EPS $4.74 both beat → +8.5%. Misalignment closed at the print | FQ1 FY27 earnings 2026-10-27 **or** 10-28 (T — unresolved) | A-queue (7/5) |
| 22 | AMZN | Bullish — realised at print | AWS +36.7% YoY, fastest in 18 quarters; AI run-rate >$25B; rev $200.6B (+20%) → +15.32%. **New dated structural catalyst: the FTC antitrust bench trial begins 2027-02-09 (C)** — the exact last day of this window | Q3 earnings 2026-10-29 (E); **FTC trial 2027-02-09 (C)** | A-queue (7/12) + **open D position** |
| 23 | GOOGL | Bullish — realised, now legally dated | The post-print capex selloff fully retraced. New this week: the **UK Competition Appeal Tribunal certified an ad-dominance class action (08-06)**, assessed against the open D position's criteria and judged **NOT a breach** (a damages proceeding, not a structural remedy). US appeal reply brief **2026-09-29 (C)**; oral argument unscheduled | Q3 earnings 2026-10-28 (E); reply brief 2026-09-29 (C) | A-queue (7/5) + **open D position** |
| 24 | TSM | Bullish — **ELIGIBILITY UNRESOLVED for a second cycle** | FY26 growth guide >40% with capex raised, described in the A-queue as "the cleanest documents-vs-tape divergence in the universe." **Strategy A's instrument rule requires US-listed COMMON EQUITY and TSM is an ADR.** This was flagged on 08-03 and has not been resolved; W4 must resolve it before any A activation, not at staging time | Q3 earnings 2026-10-15 (E) | A-queue (7/19) + **open D position ×2** |
| 25 | META | Bullish — reframed | The 08-03 bullish thesis was refuted at print (EPS $6.18 vs $7.19 on $2.40B legal + $1.18B layoff charges, −9%). The charges are now *disclosed* rather than feared. FTC appeal pending at the D.C. Circuit with no schedule located | Q3 earnings 2026-10-28 (E) | A-queue (7/5); **also on the B watch-overflow list** — no A/B conflict while A is DNA and no B position is open, but W4 must re-check before any activation |
| 26 | PLTR | **Direction SUSPENDED — the bearish lean is REFUTED** | The 08-03 file ranked PLTR #41 bearish-lean into a print it could not see. The print landed 08-03 AMC: rev **$1.94B +93% YoY** (beat by ~$124M), adj EPS $0.41 vs $0.33–0.35, **US commercial +149%**, adj FCF $1.22B (63% margin), FY26 guide raised to $8.15–8.16B (82% growth) → **+29% on 08-04**. The multiple-based bear case was not merely unsupported, it was answered | Q3 earnings 2026-11-02 (E) | — |
| 27 | DDOG | **Direction CONTESTED — a NEW objection class was established** | Beat and raised (rev $1.12B +36% vs $1.08B; EPS $0.65 vs $0.58) and **fell 17–19%** on FCF margin 29% → 25% *and* a disclosed Q3 usage decline from its largest customer. That last item is a customer-concentration objection that did not previously exist in this file's taxonomy and that reads across to the whole consumption-billing cohort (SNOW, MDB) | Q3 earnings ~2026-11 (E) | A-queue (5/7) |
| 28 | QCOM | Bearish — largely realised | FQ4 guide $2.05 vs $2.35 street citing "unprecedented increases in memory pricing" and handset headwinds → −2.7%. Next dated catalyst is the product event, not the print | **Snapdragon Summit 2026-09-22/24 (C)**; FQ4 earnings 2026-11-11 (T) | A-queue (5/1) |
| 29 | LMT | Bullish | Q2 (07-23): sales +11%, EPS $7.94, FCF $2.9B, FY26 guide raised, **record $230B backlog including a $35B THAAD multiyear** | Q3 earnings 2026-10-20 (E) | — |
| 30 | BA | Bullish (recovery) | Q2: rev $24.6B (+8%) beat with a wider core loss; FCF +$631M ahead of guide; **backlog $715B**. 777X certification remains genuinely contested across sources (originally Oct 2026, reporting now spans late 2026 into 2027) | Q3 earnings 2026-10-28 (E); 777X certification (T) | — |
| 31 | MRK | Bullish — **thesis materially WEAKENED this cycle; read the correction** | The 08-03 rank rested on two stacked dated PDUFAs, **Winrevair 09-21 and I-DXd 10-10**. **The Winrevair 09-21 entry could not be corroborated against any Merck primary source and is withdrawn** — the only Winrevair/ZENITH sBLA traceable to Merck was already approved in October 2025. What survives, and is genuinely new, is a **company-confirmed Keytruda ± QLEX + Padcev sBLA action date 2026-08-17 (C, Priority)**. Against it: Q2 posted a **reported loss of $0.13/sh** on a $2.31 acquisition charge with the adj-EPS guide cut to $2.66–2.76 | **PDUFA 2026-08-17 (C)**; Section 232 pharma-tariff deadline 2026-09-29 (C); Q3 earnings 2026-10-29 (T) | A-queue |
| 32 | UBER | Bullish | Q2 rev $14.19–14.2B (+12%) ~in line, adj EPS $0.81 (+35%) beat, gross bookings +22% cc to $58.0B — **but the Q3 guide drove −3% to −5.29%** (unreconciled). Delivery Hero completion stated H2 2027 | Q3 earnings 2026-11-03 (E) | A-queue; **open D position** |
| 33 | VRTX | Bullish (non-AI diversifier) | Q2: rev $3.33B (+12.45%) beat by ~$110M, EPS $4.73 missed by $0.01–0.02, **FY26 guide raised to $13.1–13.2B**. **Correction: povetacicept IgAN 11-30 is DOWNGRADED (C) → (T)** — it rests on a single aggregator with no primary source, and the 08-03 file over-stated it. Journavx chronic-low-back-pain sNDA 12-05 per the A-queue row | Povetacicept BLA 2026-11-30 (T); Journavx sNDA 2026-12-05 | A-queue (7/5) |
| 34 | CYTK | Bullish — **NEW** | MYQORZO (aficamten) sNDA for obstructive HCM on the MAPLE-HCM data, **Priority Review, company-confirmed** | **PDUFA 2026-11-14 (C)** | — (new) |
| 35 | SMMT | Bullish — **NEW** | Ivonescimab + platinum chemo, EGFR-mutated NSCLC post-TKI, **Priority Review, confirmed via 8-K** | **PDUFA 2026-11-14 (C)** | — (new) |
| 36 | IONS | Bullish — **NEW** | Zilganersen for Alexander disease, **Priority Review + Breakthrough, confirmed on ir.ionis.com** | **PDUFA 2026-09-22 (C)** | — (new) |
| 37 | NTAP | Bullish | DataPelago acquisition (GPU-accelerated data processing). **The A-queue row names a thematic driver but cites no contract, deal or figure** — nothing checkable, which caps how high it can rank | FQ1 earnings 2026-09-02 | A-queue (5/29) |
| 38 | OKTA | Bullish | Agentic-AI identity/security adoption. **Same defect as #37 — a labelled narrative with no checkable specific in the queue row** | FQ2 earnings 2026-08-26 | A-queue (5/29) |
| 39 | WMT | Bullish — **now unratified at three consecutive checkpoints** | FQ1 FY27 revenue $175.7B (+6.1%) in line with a Q2 guide ~0.5% below street; then an **Oppenheimer downgrade to Perform with the $140 PT WITHDRAWN (08-04)** citing IRA pharmacy headwinds and street estimates above management's own guide. The tariff-pass-through thesis has not been supported at any checkpoint since it was queued | Q2 FY27 earnings 2026-08-20 (E) | A-queue (5/9) |
| 40 | HD | Bearish/neutral | FQ1 comps +0.6%, gross margin −75bps, OI −100bps, −2.49% — modest, not decisive, support for the housing-turnover-starvation case | **Q2 earnings 2026-08-18 (C)** | A-queue (5/9) |
| 41 | TGT | **Direction SUSPENDED — documentation row** | The queued bearish thesis was refuted at the prior print (net sales $25.4B, **comps +6%**, adj EPS $1.71 vs $1.46, FY sales-growth target doubled to 4%) | Q2 earnings 2026-08-19 (E) | A-queue (5/9) |
| 42 | AMAT | Bearish | **China began domestic immersion-DUV mass production (07-27, −3.61%)** — this re-supports the original "China WFE cliff" bear case that the FQ2 guide-lift (>20% → >30%) had marked refuted. A supply-side structural fact, not a sentiment read | No 2026 date located (gap) | A-queue (5/9) |
| 43 | NBIS | Bullish (highest-vol name on the list) | $775M GPU-infrastructure debt (07-17) funding a documented buildout. **Counter, and it attacks the thesis itself rather than the price:** −12.65% to $148.22 on renewed scrutiny of the Nvidia "circular financing" structure — NBIS rests specifically on Nvidia's $2B / 9.3% stake | Q2 earnings (E) | A-queue (5/13) |
| 44 | SMCI | Bullish (high-risk) | FQ4 preliminary release raised the GM guide to 15–17% from 8.2–8.4% with **>$60B new orders**, carrying an explicit management non-firm/cancellation caveat. The A-queue row itself names governance/accounting-remediation risk and cites no figures | FQ4 earnings (E) | A-queue (5/29) |
| 45 | IBM | Direction SUSPENDED — documentation row | The 07-22 print confirmed the pre-announced miss and added nothing new; the +7.34% quantum-foundry catalyst is the only positive datapoint on the row | Q3 earnings 2026-10-21 (E) | A-queue (5/29) |
| 46 | TSLA | Bearish — ratified, documentation row | Q2 landed every bearish leg (GAAP EPS $0.32 miss, op income −57%, op margin 1.4%, first negative FCF in 2+ years on record $5.79B capex). Thesis realised; a fresh entry needs an independent thesis | Q3 earnings 2026-10-28 (E) | A-queue |
| 47 | ADBE | Bearish | Creative Cloud deceleration + Firefly monetisation lag. **The cohort evidence is oscillating, not trending, and the row says so**: an 08-06 guidance-cohort de-rate (HUBS −19.10%, DDOG −19.03%) was itself reversed on 08-07 (TEAM +35.31%, TWLO +24.89%). **No ADBE-specific datapoint exists yet** | FQ3 earnings 2026-09-10 (E); MAX 2026-11-10 (T) | A-queue (5/9) |
| 48 | LLY | Bullish | Phase 3 retatrutide **TRIUMPH-2 (up to 20.8% weight loss) and TRIUMPH-3 (22.6%)** positive on 07-23; the same release moved the BLA filing to Q1 2027 for CMC documentation — a **timing, not safety or efficacy, issue**, and the 07-27 apparent conflict between those two facts was resolved 07-29 to a single source release. Also directly exposed to the **Section 232 100% patented-pharma tariff compliance deadline 2026-09-29 (C)** | Section 232 deadline 2026-09-29 (C); BLA filing Q1 2027 | A-queue (5/1) |

**Also on the 38-name A-queue and deliberately NOT shortlisted this cycle, with reason:** **AKAM** (the $1.8B / 7-year AI-cloud-infrastructure contract with a frontier-model provider is real and checkable, but no dated catalyst inside the window was located — it is a thesis without a calendar) and **CRM** (see the 1A.1 conflict note: its catalyst position in the window is genuinely unresolved between a 08-05 print recorded internally with figures and a 08-26 aggregator date, and ranking a name whose catalyst date is contested would propagate the ambiguity into W4's queue). Both stay queued; neither is ranked.

**Priority-tier summary.** **Top-10** = NVDA, MRVL, AVGO, ORCL, INTC, CAT, TTWO, NUVL, GEV, MU. The tier is no longer purely a semiconductor cohort: **three of the ten (TTWO, NUVL, and CAT in its converted form) rest on dated, company-confirmed, non-earnings catalysts** — a game launch, two Priority-Review PDUFAs and an industrial backlog — which is a deliberate broadening away from a shortlist that had become a single correlated AI-capex bet. Two of those three are new to the file.

**Changes vs 2026-W32 (08-03), same ISO week, six days apart:** AMD **#3 → #11** (beat-and-fall on gross margin; lost the SpaceX socket); INTU **#8 → #19** (dated event, no documented mechanism); MRVL #2 → #2 (date upgraded to company-confirmed); AVGO #7 → #3; ORCL #6 → #4; INTC #4 → #5; MU #5 → #10 (cohort de-rate is a genuine counter); META #9 → #25; DELL #10 → #17 (date failed primary verification a second time); PLTR **#41 → #26 with direction suspended** (bearish lean refuted at print); MRK #31 → #31 but with **one of its two ranked catalysts withdrawn as unverifiable**; VRTX #33 → #33 with its anchor catalyst downgraded (C) → (T). **New:** TTWO #7, NUVL #8, CYTK #34, SMMT #35, IONS #36. **Dropped:** UNP, GM, VZ (catalysts passed or out of window with no new document), NOW/SNOW/PANW/CRWD/CSCO/HPE retained but re-ordered.

---

## PART 2B — Strategy C preliminary ranked shortlist (14 event candidates)

W4 reads this section verbatim. **CRITICAL ROUTER GATE: C = HYBRID ACTIVATE (FOMC-only), resolved 2026-08-05 and no longer pending. Only candidate #1 (FOMC 2026-09-16) is router-eligible for a new C entry. Candidates #2–#14 are router-PARKED (DO-NOT-ACTIVATE) — divergence context only; W4 must NOT enqueue thesis-construction for them.**

**SIZING AND EXECUTABILITY — the material change this cycle.** There is **no flat 2% per-structure budget**; the flat rule was retired by Experiment_Parameters rev 18 / Strategy.md Rev 43, and the 2026-08-05 owner directive removed every numeric ceiling. Each thesis states its own AI-chosen risk budget, justified against the seven factors and adversarially attacked on **size as well as direction**; the retained options order-guard enforces `max_loss ≤ stated budget` and does not cap the budget. What has changed is the denominator: **C's NAV is $9,436.86 with all $9,436.86 available**, up from a position where the C section's standing conclusion partly rested on "no eligible structure fits at current portfolio size." **That deferral argument is now materially weaker than at any prior point in this record.** Whether a thesis clears is unchanged; a cleared thesis is now constructible at meaningful size.

**Overlap with open A positions: none open → no A/C conflict on any candidate below.**

**MEASURED market data.** All implied vol, historical (realised) vol, IV percentile and expiration data below are **live IBKR reads taken 2026-08-09**, reflecting the Friday 2026-08-07 close (US markets closed Sunday). **What was NOT obtained, stated plainly: no ATM-straddle expected-move figure for any name** — that requires live option-chain quotes which were not pulled this session, so every "implied move" style number is absent rather than estimated. IV/HV/IV-percentile are a proxy for event premium, not the expected move itself. **No strike-level premium or spacing was observed, so no structure-level constructibility claim is asserted for any candidate.**

| # | Event (ticker) | Type | Date | Hypothesised divergence (direction) | Supporting public documents | Executable within the budget? | Router / tier |
|---|----------------|------|------|--------------------------------------|------------------------------|--------------------------|---------------|
| **1** | **FOMC** | **FOMC** | **2026-09-16 (C)** | **The market repriced the September decision by roughly 20 points in a single session on a single data point, and the two things that argued the other way are both still standing.** July payrolls printed −23k against +80/83/95k consensus with ~103k of prior-month downward revisions (08-07), and September-hike pricing fell from roughly 56–62% to roughly **36–43%** (Polymarket 36% hike / 63% hold, first-party read 2026-08-09 07:31 UTC; Investing.com CME-derived 43.4% / 56.6%, page-dated 08-08). **Against that repricing, unrebutted:** (a) on 07-29 **three FOMC members dissented in favour of a hike** — Hammack, Kashkari, Logan — the first three-member dissent for an identical alternative since September 2016, and none has since retracted; (b) Chair Warsh has removed forward guidance and stated there is no soft inflation target, only 2 percent; (c) **July CPI lands 2026-08-12 and PPI 2026-08-13**, and M1a's own July scoring states the energy-led June disinflation "will mechanically re-inflate the July headline print"; (d) **ISM Services Prices Paid printed 70.3 vs 65.0 expected**, reaccelerating. **The hypothesised divergence is that the rates market has over-extrapolated one labour print across a decision that still has two CPI prints, one payroll print, the minutes and Jackson Hole in front of it — and that it is charging very little for the possibility.** **This is the measured part and it is the strongest fact in this file:** **TLT IV 9.97% vs HV 7.39%**, IV %ile 69.8 / 43.7 / **31.5** — implied vol on the long end sits in the bottom third of its 52-week range; **SPY IV 12.46% vs HV 14.07% — implied BELOW realised** — with IV %ile **3.2 / 1.6 / 17.9**, i.e. essentially at the floor of its 13- and 26-week ranges, three trading days before a CPI print and immediately after a record close. Cheap optionality into a dated, genuinely two-sided fulcrum is the setup; direction (long-vol vs directional-hawkish) is thesis-construction's call, not this file's | federalreserve.gov FOMC calendar (fetched 08-09, SEP confirmed for 09-16); BLS Employment Situation 08-07; bls.gov CPI/PPI schedules; Polymarket event page (08-09, $20.2M volume); Investing.com Fed Rate Monitor (08-08); ISM Services 08-05; `state.current_regime` M1a 2026-08-01 | **YES — and this is new.** C NAV/available **$9,436.86**. TLT, IEF and SPY all carry a **2026-09-18 regular monthly expiry**, the first standard expiration after the decision; SPY additionally has weeklies at 09-11, **09-16 (decision day)** and 09-25. Single-expiration structures only (multi-expiration calendars/diagonals are excluded by eligibility). **No strike-level quotes pulled → no specific structure is proposed here** | **ROUTER-ELIGIBLE — the only one. Top-5, rank 1** |
| 2 | AVGO earnings | Earnings | 2026-09-02 (C) | **The richest measured event premium among confirmed-date large caps: IV 75.1% vs HV 54.8% (ratio 1.37), IV %ile 68.3 / 76.2 / 87.6.** Implied vol is pricing a substantially larger move than the stock has actually delivered | broadcom.com release; IBKR snapshot 08-09 | Budget-feasible at current NAV; no chain data pulled | Router-PARKED. Top-5, rank 2 |
| 3 | MRVL earnings | Earnings | 2026-08-27 (C) | **The mirror-image setup and the cleanest cheap-optionality case on the list: IV 90.3% vs HV 99.8% (ratio 0.90 — implied BELOW realised), IV %ile only 23.8% at 13 weeks** into a company-confirmed print, on a name whose FQ1 was a record | Marvell announcement via StockTitan; IBKR snapshot 08-09 | Budget-feasible; no chain data pulled | Router-PARKED. Top-5, rank 3 |
| 4 | SNOW earnings | Earnings | 2026-09-02 (C) | **Highest implied-vol percentile in the file: IV %ile 93.7 / 96.8 / 98.4** (IV 90.0% vs HV 86.9%). Note the two-sided read — the DDOG largest-customer usage disclosure is a live, dated reason the implied premium may be *correctly* priced rather than rich | snowflake.com release; IBKR snapshot 08-09 | Budget-feasible; no chain data pulled | Router-PARKED. Top-5, rank 4 |
| 5 | NVDA earnings | Earnings | **2026-08-26 (E)** | Implied vol is *not* elevated into the largest unresolved print in the window: **IV 39.8% vs HV 40.3%**, IV %ile ~50.8 / 44.4 / 49.0 — mid-range, against demand documents that strengthened again on 08-05 (exclusive SpaceX socket). **Date caveat: 2026-08-26 is feed-only (E), not company-confirmed this session** | FMP earnings calendar; IBKR snapshot 08-09 | Budget-feasible; no chain data pulled | Router-PARKED. Top-5, rank 5 |
| 6 | LNTH PDUFA | FDA | 2026-08-13 (C) | Binary tau-PET NDA action, the **nearest dated binary in the window (four days out)**. The 08-03 file measured IV 9.29% vs HV 38.83% with IV percentile 0.0 at 13/26/52 weeks and correctly flagged it as *either the best divergence on the list or a data artifact*. **That measurement was NOT re-pulled this session and is therefore not restated as current** — an unverified anomaly is not evidence | Lantheus IR (date, C) | Budget-feasible; vol not re-measured | Router-PARKED |
| 7 | JAZZ PDUFA | FDA | 2026-08-25 (C) | Binary Priority sBLA (Ziihera + Tevimbra, 1L HER2+ gastric/GEJ) on a ~$15.8B sponsor — a clean, dated, single-outcome event. The 08-03 file measured a rich premium here; **vol not re-pulled this session, so no figure is carried forward** | investor.jazzpharma.com | Budget-feasible; vol not re-measured | Router-PARKED |
| 8 | RARE PDUFA ×2 | FDA | 2026-08-23 (C) **and 2026-09-19 (C)** | **Two confirmed binaries on the same sponsor inside one 45-day window** — DTX401 (GSD-Ia) then UX111 (Sanfilippo A, a CRL resolution), the second newly in-window as the window rolled. Sponsor is ~$2.5–2.8B, only just above the floor, which is itself a risk factor rather than a vol observation | ir.ultragenyx.com ×2 | Budget-feasible; vol not re-measured | Router-PARKED |
| 9 | GILD PDUFA | FDA | 2026-08-27 (C) | Binary Priority NDA action (bictegravir/lenacapavir, HIV-1 suppressed) on a mega-cap — the deepest-liquidity underlying among the FDA candidates | gilead.com | Budget-feasible; vol not re-measured | Router-PARKED |
| 10 | BMY PDUFA | FDA | 2026-08-17 (C) | Binary iberdomide approval (Priority + Breakthrough) on a mega-cap. The 08-03 file noted an FT report (08-02) that AstraZeneca had explored a ~$400B combination with BMY — **an M&A overhang that was not re-verified this session and is recorded as prior-cycle context, not current fact** | news.bms.com | Budget-feasible; vol not re-measured | Router-PARKED |
| 11 | MRK PDUFA | FDA | **2026-08-17 (C) — NEW** | Binary Priority sBLA action on Keytruda ± QLEX + Padcev in cisplatin-eligible MIBC — a **mega-cap oncology franchise-extension decision that was entirely absent from the 08-03 file**, landing the same day as BMY's | merck.com | Budget-feasible; vol not measured | Router-PARKED |
| 12 | NUVL PDUFA | FDA | **2026-09-18 (C) — NEW** | Binary Priority + Breakthrough NDA action (zidesamtinib, ROS1+ NSCLC) on a ~$9.8B sponsor, landing two days after the FOMC and on the same date as the first post-FOMC monthly option expiry | Nuvalent PR | Budget-feasible; vol not measured | Router-PARKED |
| 13 | PANW earnings | Earnings | 2026-09-01 (C) | **IV 61.3% vs HV 51.8% (ratio 1.18) with IV %ile 71.4 / 84.9 / 92.4** — implied uncertainty near its 52-week ceiling into a company-confirmed date | PANW release; IBKR snapshot 08-09 | Budget-feasible; no chain data pulled | Router-PARKED |
| 14 | ORCL earnings | Earnings | 2026-09-14 (E) | **IV 70.8% vs HV 72.3%** (implied below realised) with IV %ile 68.3 / 77.8 / 88.8 — high percentile, sub-realised absolute level, two days before the FOMC. Date is (E), feed/synthesis only | Web synthesis; IBKR snapshot 08-09 | Budget-feasible; no chain data pulled | Router-PARKED |

**C top-5:** **#1 FOMC 2026-09-16 (the only router-eligible candidate)**, then AVGO 09-02 and SNOW 09-02 as the richest measured *event premiums*, and MRVL 08-27 and NVDA 08-26 as the richest measured *cheap-optionality* cases — a genuine two-directional split in the measured data, which last cycle's file did not have. All four of #2–#5 are router-parked.

**Operative read for W4 — what changed since 08-03 and why it matters.** Three things moved, all in the same direction: **(i)** the FOMC candidate is no longer merely "two-sided and unadjudicated" — the market has taken a decisive side (roughly 36–43% hike, down ~20 points in a session) on a single labour print, while the hawkish counter-evidence (three dissents for a hike, no forward guidance, and two CPI prints plus PPI still to come) is entirely intact, which is a *specific, dateable* divergence rather than a general one; **(ii)** the measured cost of expressing it is unusually low — **SPY implied vol is below realised and sits at the 1.6th–3.2nd percentile of its 13- and 26-week ranges**, and TLT implied vol is in the bottom third of its 52-week range; **(iii)** the size constraint that has capped this section for cycles has lifted — **C holds $9,436.86, all available.** The existing `thesis-FOMC-C-20260908` queue entry (due 2026-09-08, enqueued by W4 2026-W32 from last cycle's PART 2B rank 1) is the standing mechanism and **is not duplicated here**; this file supplies the updated evidence that entry's thesis session should read, most of which did not exist when it was queued. **The nearest fulcrum is 2026-08-12/13 (CPI/PPI), inside three trading days** — if those prints resolve the tension one way, the divergence above may close before the 09-08 due date, and the thesis session should re-measure rather than inherit these numbers.

---

*Shortlists only. Full thesis construction per Strategy.md — adversarial counter-argument attacking size as well as direction; immutable at-entry price target and thesis-completion criteria for A; dual-path max-loss verification and a defined-risk single-expiration structure for C — happens in W4-scheduled sessions, not here.*

*Sources and provenance: federalreserve.gov FOMC calendar; bls.gov and bea.gov release schedules; company IR releases, 8-Ks and press releases as cited per row; FDA/sponsor primary sources cross-checked against RTTNews / checkrare / Dan Sfera aggregators with the aggregator-only rows explicitly labelled (T); BLS Employment Situation (08-07); ISM (08-03, 08-05); Polymarket and Investing.com for rate pricing; IBKR `get_price_snapshot` and `get_option_parameters` for all volatility and expiration data (2026-08-09); FMP earnings-calendar for the (E)-labelled dates; `state.current_regime`, `state.current_positions`, `analytics.strategy_nav`, `state.regime_capital_debt`, `state.strategy_capital_enablement`, `state.open_queue_detail` and `Watchlist.md` for internal state.*

***Data-quality disclosures for this run — recorded so a later reader can weigh the numbers correctly.***
1. ***Analyst price targets: UNAVAILABLE for all symbols, second consecutive cycle.*** *Both FMP routes returned plan-tier ACCESS DENIED. No remembered PT figure is carried anywhere in this file.*
2. ***No ATM-straddle expected-move figure was obtained for any candidate.*** *That requires live option-chain quotes, which were not pulled this session. Every IV/HV/IV-percentile figure is a proxy for event premium and is labelled as such; no "options imply ±X%" claim appears anywhere in this file, and their absence from PART 2B is deliberate rather than an oversight.*
3. ***Volatility data covers 15 symbols, not the full shortlist.*** *A broader IBKR sweep across 52 symbols was commissioned and had not returned at write time; rather than hold the file, rows without a volatility read simply carry none. The 08-03 file's figures for LNTH, JAZZ, RARE, GILD and BMY were **deliberately not carried forward** — a measurement six days stale is not a current measurement, and that file itself disclosed a transcription corruption affecting several rows in exactly that sweep.*
4. ***`mcp__FMP__quote`, `technicalIndicators`, and the per-symbol `earnings-company` endpoint all returned plan-tier ACCESS DENIED*** *— so per-ticker market-cap and ADV screening against the $2B / $10M floors was NOT run, and market caps quoted in 1A.4 come from third-party finance sites, approximate to the week.*
5. ***CME FedWatch could not be read first-party*** *(JS-rendered), and Kalshi's market page returned HTTP 429. A "61.9% hike" figure circulating in search results traced to no primary source and is used nowhere. Only the Polymarket first-party read and the Investing.com CME-derived monitor are quoted as live.*
6. ***Three unreconciled conflicts are carried forward deliberately rather than resolved by picking a side:*** *CRM's FQ2 date (internal 08-05 record with figures vs an 08-26 aggregator relay — see 1A.1); the FOMC-minutes release date (2026-08-19 is inferred from the standard three-week lag, not confirmed on a live Fed page); and the DLTR, MSFT, SLB, TSLA and LULU earnings-date conflicts flagged inline in 1A.1.*
7. ***Markets were closed at write time*** *(Sunday 2026-08-09). Every price and volatility figure reflects the Friday 2026-08-07 close and none is a live tick.*


2026-07-30
<!-- d1_scan_through_utc: 2026-07-30T22:30:00Z -->

# Daily Market Development Scan — 2026-07-30 (Thu, MT)

**Scan window:** 2026-07-29 16:27 MT → 2026-07-30 16:30 MT (≈24.0h, normal daily cadence; prior-run marker `2026-07-29T22:27:10Z` parsed cleanly, cross-checked against the `Daily.md` commit at 2026-07-29T22:40:05Z — the two agree to within 13 minutes, so no gap and no fallback needed). `state.routine_catchup_window` reports `window_days = 0.98`, `never_completed = false` — cadence-normal, no catch-up widening, no `CATCHUP` token.

**Tape summary.** **A violent, and violently narrow, snapback.** The index reversed almost the whole FOMC-day loss — S&P 500 **7,437.53 (+1.66%)**, Nasdaq Composite **25,122.18 (+2.78%)**, Dow **52,208.06 (+1.19%, +613.92)**, Russell 2000 **2,946.10 (+1.37%)**, **SPY 741.69 (+1.68%)** — but **two-thirds of S&P 500 constituents closed LOWER, the equal-weight S&P closed RED, and the S&P 500 ex-Information-Technology was DOWN on the day** (Barron's live blog, 2026-07-30). The entire index move is **Microsoft +15.51%** — the largest single-day market-cap gain for any stock in history, ~$491B — plus the semiconductor complex it dragged with it. SPY is still **below its 50dma (~744.7) for a 4th consecutive session**, above the 200dma (~699.5), and −2.46% from the 52-week high (760.40). **VIX 17.09 (−17.28%** from 20.66; intraday 17.01–20.08) — the whole FOMC fear spike unwound in one session, back **below both** its 50d (17.43) and 200d (18.74) averages. **The bond market did not join the party:** 2Y **4.23% (+1bp)**, 10Y **4.68% (+1bp)**, 30Y **5.21% (+1bp)** after touching **5.23% intraday, the highest since 2007**; traders price **~60% odds of a September HIKE** (NYT DealBook, 2026-07-30). Macro undershot: **Q2 advance GDP +1.5% annualized vs +2.1% consensus**, while **June headline PCE cooled to 3.7% YoY** (from 4.1%) and **core PCE to 3.3%** — both in line. **WTI ~$83.99 (+0.48%)**; Brent gave back roughly 1–1.5% of Wednesday's +7.9% despite a genuine widening of the Iran war. Gold ~$4,163 (+0.06%); DXY ~100.9–101, its first move above 100 in 2026. **The yen surged the most since 2022** — from a 40-year low of 163.94 to 158.55 — in what strategists called official intervention, one day before the BoJ meets. `hy_oas` **2.74** (FRED, June ref-month — unchanged, historically tight, no credit stress). Sector dispersion was the widest of this sequence (**7.81pp**): **Technology +5.42%** against **Communication Services −2.39%** and **Consumer Staples −2.07%** — yesterday's only green sector is today's second worst.

## TL;DR

- **Exits triggered: none.** Mechanical sweep clean on all 14 book rows + the connector union. **MDT's Strategy-B time-stop is Fri 2026-07-31 — tomorrow**, the one dated item in the book. MDT $85.74 vs $90 target; ISRG/B $353.00 vs $400 (9/18); MSCI $575.76 vs $615 (9/25); FTV $58.55 vs $61 (9/28). Kill sweep clean on a live-mark refresh: D ≈ −0.2% drawdown (improved from −1.6% on the AMZN/TSM prints), B ≈ −1.8%; nothing within 48pp of the −50% kill.
- **New entry candidates: 2 — FICO, ALNY** (both Strategy B, long, event day 2026-07-30, windows close ~2026-08-13). FICO is the stronger: a double beat down −17.01% on regulatory-competition *commentary*, not on a reported number.
- **Add candidates: 1 — AMZN (Strategy D), strengthened conviction.** Q2 moved all five invalidation criteria further from breach: AWS +37% YoY (fastest in 18 quarters, from 28% in Q1), AWS operating margin 39.4%, backlog ~$364B → ~$496B, Anthropic/OpenAI Trainium commitments expanding. 13 of 14 positions declined — **2 at the HARD GATE** (B:ISRG, B:MDT — `NOT_DISCRETELY_RECORDED_AT_ENTRY`).
- **Watchlist changes: none.**
- **Regime review: no review.** M1 runs in 4 days (2026-08-03) and will carry the one genuinely stale input — `shock_overlay='latent'` (as of 2026-07-01) against an Iran war that this week widened to Jordan, Iraq and Egypt.
- **⚠️ FTV watch item:** closed $58.55, **0.57% above** the unambiguous invalidation-3 trigger ($58.22 post-event intraday trough), on **2.9× average volume**, after probing to a fresh 13-week low of $57.48 intraday. Read as **NOT breached** — see RISK for the interpretation applied and why tomorrow's D1 must re-check it.

---

# DEVELOPMENTS

## 1. Market-wide breaking events

**(a) The Iran war widened to three new countries — and oil did not extend.** This is the day's most under-priced object.

- The IRGC launched **a ballistic-missile attack on a US base in Jordan**; President Trump said Iran will be "hit very hard" in response (Al Jazeera live blog, 2026-07-30).
- **Egypt was struck for the first time**, pulling a fourth state into the conflict (CNN, 2026-07-30).
- **Iraq condemned Tuesday's joint US–Saudi strikes**, with the Popular Mobilisation Forces saying **20 of its fighters were killed and 32 wounded** (Al Jazeera, 2026-07-30).
- **Iran struck and halted three oil tankers in the Strait of Hormuz** (Tasnim via CBS News live updates).
- CENTCOM ran a further operation **0000–0200 GMT Thursday** (Reuters/Marinelink, 2026-07-30).
- **Reaction:** Brent rose intraday to $91.80 (+1.17%) before fading; **WTI closed ~$83.99, +0.48%**, and Brent gave back roughly 1–1.5% of Wednesday's +7.91% settle. The week's oil tape has been pause (Tue −5%) → spike (Wed +6.6/+7.9%) → **flat-to-lower (Thu) on a geographic escalation**.

The divergence is the signal: a war that added Jordan, Egypt and a Hormuz tanker interdiction in 48 hours produced **no** oil follow-through. Either the market has decided the escalation is contained, or it is under-pricing it. Either way, `state.current_regime`'s `shock_overlay='latent'` — set 2026-07-01 on the reasoning that "the kinetic phase has paused and oil normalized" — is now **materially stale as a description of the conflict**, even though the price evidence it rests on has held. Routed to M1a (2026-08-03), not to an inter-monthly review (see REGIME CHECK).

**(b) Suspected Japanese FX intervention.** The yen "surged on Thursday against the U.S. dollar by the most since 2022, in what analysts said looked like official intervention by Tokyo," from a **40-year low of 163.94** to **158.55**, also falling over 2% against each of the euro and pound (Reuters, 2026-07-30; Barron's; WSJ puts the move at ~3% to a two-month high). Daisaku Ueno (Mitsubishi UFJ Morgan Stanley): *"It is hard to imagine anything other than currency intervention causing a drop of as much as 5 yen in such a short period of time."* The **BoJ meets Friday 2026-07-31**. A disorderly move at a 40-year extreme requiring official support is a live carry-unwind risk channel into global duration — noted, not yet acted on.

**(c) Bank of England held at 3.75%, 6–3, with three hike dissents** (BoE Monetary Policy Summary, 2026-07-30) — the second G7 central bank in two days to hold with a hawkish minority. Governor Bailey: *"Do not leave this room thinking that the BoE is edging towards a hike,"* adding the MPC is *"not talking about an insurance hike."* Dissenter Catherine Mann named the driver explicitly: *"The key change in the environment for my decision is the collapse of the U.S.-Iran Memorandum of Understanding, the widening of the Middle East conflict and the associated volatility in energy prices."* The Bank flagged an adverse scenario — a drawn-out war with oil above $100 — pushing UK CPI to **4.5% by mid-2027** (The Guardian, 2026-07-30).

No material bankruptcies, disasters, or unscheduled US enforcement actions in the window.

## 2. Scheduled events that resolved

**US macro (all 2026-07-30):**

| Release | Actual | Consensus | Prior |
|---|---|---|---|
| Q2 GDP, advance (annualized) | **+1.5%** | +2.1% | +2.1% (Q1) |
| GDP-embedded PCE price index (Q2) | 5.1% | — | 4.6% (Q1) |
| GDP-embedded core PCE (Q2) | 3.4% | — | 4.4% (Q1) |
| June PCE price index, YoY | **3.7%** | in line | 4.1% (May) |
| June core PCE, YoY | **3.3%** | in line | 3.4% (May) |
| June personal spending, MoM | +0.3% | — | +0.9% |
| June personal income, MoM | +0.2% | — | +0.7% |
| Personal saving rate | **2.7%** — lowest since June 2022 | — | — |
| Initial jobless claims (w/e 7/25) | 197k | ~200k | 188k |
| Continuing claims | 1,782k | — | 1,789k |

(Sources: BEA.gov, Reuters, CNBC, TradingEconomics, 2026-07-30.) The Q2 Employment Cost Index is **Friday 2026-07-31** — outside this window.

The shape matters: **growth undershot by 0.6pp while both PCE measures cooled**. That is the dovish-leaning combination — and the long end still made a 2007 high. The bond market is pricing the Fed's *reaction function*, not the data.

**Earnings — the megacap block.** The AI-capex question was put to four companies in 24 hours and answered four different ways:

- **MSFT** (AMC 7/29): revenue **$90.01B vs $87.62B** consensus (+17.7% YoY); EPS **$4.81 vs $4.24** est.; **Azure +43% cc** vs ~40% est.; **FY26 Azure revenue passed $100B for the first time**; capex $41B in the quarter, +69% YoY. CFO Amy Hood guided to further FY27 capex growth citing "demand signals across our portfolio." → **+15.51%**.
- **META** (AMC 7/29): EPS **$6.18 vs ~$7.17** consensus (miss); revenue **$60.80B (+28%)**, a beat; **Q3 revenue guide $61–64B**, low end below the $63.15B Street; **capex floor raised to $130–145B**; total expenses +55% YoY; **operating margin 43% → 31%**; **free cash flow $8.55B → $784M**. → **−7.95%**.
- **AMZN** (AMC 7/30, **inside the window**): revenue **$200.6B (+20%)**; **AWS $42.23B, +37% YoY**, beating $40.54B consensus; **AWS operating income $16.62B, margin 39.4%** vs $13.62B consensus; Q3 guide $197–202B. Jassy: *"AWS is booming, growing 36.7% year-over-year in Q2… our fastest growth in 18 quarters."* EPS $5.75 vs $1.82 est., flattered by a **$53.4B non-operating pre-tax gain primarily from its Anthropic investment**. TTM FCF swung to **−$7.6B** on $169B of TTM capex (+64%). → **+3.90% regular close, +13.87% including the after-hours print.**
- **AAPL** (AMC 7/30, inside the window): revenue **$109.42B vs $108.65B** est., iPhone +22%; **weak current-period guidance citing "supply constraints."** → −1.4% regular, **−8% extended**.

**Other prints:** SBUX (beat, comps +7.9%, FY26 EPS guide raised, +7–9% AH), HOOD (EPS $0.62 vs $0.44, revenue +32%, crypto revenue −38%, −1.6% AH), SOFI (adj revenue +43% to $1.2B, guidance held, −8.9%), COIN (revenue $1.22B, −19% YoY, missed $1.32B; loss $0.40/sh vs −$0.11 est.; record 10.3% volume share; −5% AH), RBLX (bookings +8% at the low end of guidance, Q3 bookings guided −14% to −18%), RIVN (revenue $1.658B, gross profit +$179M vs −$206M YoY), MA ($5.04 vs $4.78), BMY ($2.04 vs $1.60), REGN ($14.29 vs $10.21), CI ($7.78 vs $7.60), KKR ($1.63 vs $1.43), SO ($1.13 vs $1.01), MO ($1.48 vs $1.50, miss), Shell ($3.52 vs $3.18), SIRI (EPS $0.70 vs $0.78 miss, first positive Q2 self-pay net adds in four years, FY guidance raised), MGM (revenue $4.451B vs $4.465B, EPS $0.59 vs $0.579), PG (weak FQ4, FY27 guided a "transition year"), FICO, ALNY, MKTX, CORT, BHC, AXTI, GPI, RTO, SONO, QCOM, LRCX — treated in the screens below.

**FDA / other:** no PDUFA action date was confirmed for 2026-07-29 or 2026-07-30 (nearest identified: gedatolisib 7/17, atacicept 7/7, Capricor deramiocel 8/22 — all outside the window). No ECB or BoJ policy action in the window; the BoJ meets 7/31. No major antitrust or other regulatory ruling resolved.

## 3. Large single-name moves — AI-SIGNIFICANCE SCREEN (Operating_Protocols.md §19)

**Layer-1 population rail** (mechanical cost bound, never a significance claim): US-listed, market cap ≥ $2B, ≥2% close-to-close, event-attributable — **28 names surfaced**. SONO (−17.64%) was excluded at the rail on market cap (~$1.4–2.0B, borderline); XRX (+32.2%), TDOC (−28.3%) and TREE (−19.6%) likewise fall below $2B. **Layer-2 (the decider)** judges significance in each name's own volatility regime and event context.

**PASSED — significant:**

| Name | Move | Conv. | `legacy_rule_pass` | Reason |
|---|---:|---:|:---:|---|
| **MSFT** | +15.51% | 75 | yes | The largest single-day market-cap gain for any stock in history (~$491B). Azure +43% cc and the first $100B Azure year turned a negative-breadth tape into a +1.66% index day single-handedly. |
| **META** | −7.95% | 75 | yes | The mirror image on the *identical* question, resolved the same night: operating margin 43%→31%, FCF $8.55B→$784M, capex floor raised. MSFT and META together are the most information-dense object on the tape — the market did not de-rate AI capex, it de-rated **unmonetized** AI capex. |
| **FICO** | −17.01% | 60 | yes | A double beat (EPS $12.50 vs ~$10.80; revenue $692M vs $628.55M, +10.09%) down 17% on *CEO commentary* about FHFA "Lender Choice" enabling mortgage score-shopping. RBC cut its target 2400→1525 **while keeping Outperform** — the price moved on narrative, not on a reported number. |
| **ALNY** | −28.31% | 60 | yes | The largest decline on the tape and a new 52-week low, on an FY2026 product-revenue guidance cut citing ATTR-CM market headwinds. |
| **TSM** | +7.64% | 60 | yes | Held D position. A 7.6% move with **no TSM-specific news** — read-across from MSFT's capex alone (SOXX +8%). Significant because it is the direct negation of the position's invalidation-3 (structural AI-capex reset). |
| **AMZN** | +3.90% | 60 | **no** | Held D position; `below_spec_floor=true` on the regular close (the after-hours print carried it to +13.87%). Significant because AWS **accelerated** from 28% to 37% YoY at a 39.4% operating margin — every one of the position's five invalidation criteria moved further from breach at once. Context/add evidence only; never routed as a B candidate. |
| **MKTX** | +29.45% | 45 | yes | Record portfolio-trading ADV ($2.0B, +33% YoY) and record services revenue at a $5.7–9.4B name — significance real but the re-rate rests on disclosed information. |
| **AMAT** | +15.01% | 60 | yes | A ~$400B semi-cap name moving 15% on **another company's** earnings, with its own print not due until 8/13. Significant precisely *because* the move contains no name-level information: it measures how violently the whole AI-capex complex re-prices on one datapoint. |

**REJECTED — surfaced by the legacy rule, judged not significant** (the disagreement surface §19 exists to capture):

| Name | Move | Conv. | Reason |
|---|---:|---:|---|
| CORT | +27.29% | 45 | Revenue +31.7% and FY guidance raised to a $1.15B midpoint — a proportionate re-rate on real information. |
| BHC | +28.85% | 45 | EPS $1.26 vs $0.96, revenue +13% and raised guidance. Information, not overshoot. |
| AXTI | +26.97% | 45 | ~90% YoY revenue growth plus a Lumentum indium-phosphide supply agreement. Information. |
| LRCX | ~+17% | 45 | FQ4 beat, FQ1 guide above consensus, gross margin 52% — highest in 20 years. Information. |
| NBIS | +27.13% | 45 | No dated same-day catalyst identified; broad AI-infrastructure rotation. Same basis on which SMCI/DELL were rejected on 7/29. |
| IREN | +30.54% | 45 | AI-data-center / bitcoin-miner rotation with no name-level event; next earnings 8/27. |
| CIFR | +28.10% | 45 | Same rotation, no name-level event; next earnings 8/4. |
| RTO | −17.60% | 60 | North America organic growth of 1.1% with margin pressure is proportionate information — and a UK-domiciled ADR failing B instrument eligibility outright, the NOK/EDU basis. |
| GPI | −17.11% | 45 | Revenue $5.7B→$5.4B and continuing-ops net income $139.8M→$103.0M. Proportionate. |

**Agreement:** both **7**, ai_only **1**, rule_only **9**. Logged as one `entry_type='research-screen'` row (`screen='single-name-move'`).

## 4. Sector-level moves — AI-SIGNIFICANCE SCREEN (§19, same call)

Sector-ETF closes (IBKR near-close snapshots; FMP's cap-weighted sector endpoint remains plan-gated, so the ETF prints are the primary figures this run):

| Sector ETF | % | Sector ETF | % |
|---|---:|---|---:|
| **XLK** Technology | **+5.42** | XLB Materials | −0.37 |
| XLY Cons. Disc. | +2.62 | XLU Utilities | −0.51 |
| XLE Energy | +0.70 | XLRE Real Estate | −1.22 |
| XLF Financials | +0.56 | XLV Health Care | −1.65 |
| XLI Industrials | +0.52 | **XLP** Cons. Staples | **−2.07** |
| | | **XLC** Comm. Svcs. | **−2.39** |

**Dispersion: 7.81pp** (XLK +5.42 to XLC −2.39) — the widest of this sequence, and the second consecutive session of unusually wide dispersion after yesterday's ~3.2pp. Layer-1 rail: ≥1% at ETF level or notable dispersion → **6 sectors surfaced**.

**PASSED:**
- **Information Technology +5.42%** (conv. 75, `legacy_rule_pass=true`) — the largest one-day sector advance in over a year and the whole of the index move. MSFT +15.51%, AMAT +15.01%, LRCX ~+17%, NVDA +2.65%, SOXX +8%.
- **Communication Services −2.39%** (conv. 60, true) — META's −7.95% dominating a heavyweight-concentrated sector. Sits directly opposite XLK on the same AI-capex question, which is what makes it discriminating rather than beta.
- **Consumer Staples −2.07%** (conv. 60, true) — **yesterday's only green sector is today's second worst**, and unlike a pure rotation it has a name-level driver: PG's weak FQ4 and a FY27 "transition year" guide, with HSBC downgrading to Hold and cutting its target 182→149. A defensive bid that held alone through Wednesday's selloff and broke on Thursday is a cleaner risk-appetite read than the +1.66% index print.
- **Health Care −1.65%** (conv. 45, `legacy_rule_pass=false`) — below the old 2% bar, surfaced anyway because it is the only sector whose move traces to a single name's guidance cut (ALNY −28.31%) rather than to rotation.

**REJECTED:** **Consumer Discretionary +2.62%** (conv. 45, `legacy_rule_pass=true`) — clears the legacy bar, but on a day when tech rose 5.4% and the equal-weight index closed red, a +2.6% discretionary print is high-beta participation, not information.

**Agreement:** both **3**, ai_only **1**, rule_only **1**. Logged as one `entry_type='research-screen'` row (`screen='sector-move'`).

**Intra-industry-group divergence (Strategy-E evidence, not actionable — see OPPORTUNITY CHECK):** MSFT +15.51% against META −7.95% is a **~23pp one-session spread between two mega-cap platform businesses** on the same catalyst — the widest same-group divergence this file has recorded. Semi-cap (AMAT +15.0%, LRCX +17%) against memory and the prior week's losers is a second axis.

## 5. Notable commentary

- **Chair Warsh, on the hold** (Yahoo Finance interview, 2026-07-30): the decision *"was the farthest thing from inertia I can imagine,"* and he would *"not be constrained"* by traders betting on a September move. From the 7/29 press conference, still driving Thursday's tape: *"Market participants are learning to play the ball, not the referee… This is, in my view, a change for the better, and we're just getting started,"* and *"the five-plus years of inflation above target cannot be cured in nine weeks… This Fed will not waver"* (CNBC).
- **No on-the-record remarks from the three dissenters** (Hammack, Kashkari, Logan) were published in the window; their individual rationales remain unexplained, which is itself the next scheduled catalyst for the September-hike pricing.
- **Transmission datapoint:** Freddie Mac's 30-year fixed mortgage rate hit **6.66%** as of 2026-07-30, the highest since August 2025 (Yahoo Finance/AP).
- **Sell-side, MSFT:** Citi to $600 from $570 (Buy), calling the print "a solid rebuttal to the bear case"; Wells Fargo to $650 from $625; Bernstein to $647.
- **Sell-side, META:** Wells Fargo cut to **$640 from $835**, citing "limited visibility into AI monetization beyond advertising"; roughly ten firms cut targets overnight.
- **Zuckerberg, on the constraint** (Q2 call): *"There's nowhere near enough compute for all the demand"*; Meta has received compute-rental offers *"at a significant premium over what [Meta] paid for it."* CFO Susan Li said Meta expects to stay *"demand-constrained… including in our core business,"* with the build running *"into 2028 and beyond."* The market did not dispute the demand claim — it disputed the monetization timeline.
- **P&G CFO Andre Schulten** (FQ4 call, 7/30): fiscal 2027 will *"remain challenging due to commodity costs, transportation expenses, currency impacts and geopolitical uncertainty,"* guiding organic sales +1–3% and core EPS $6.89–7.11 including *"approximately $1 billion in after-tax cost headwinds."* This is the clearest corporate read-across of the day: input-cost pressure landing in FY27 guidance at the most defensive large-cap on the board.
- **Other rating actions (2026-07-30):** HUM downgraded to Market Perform (Raymond James); LVS to Hold (Argus); PG to Hold, PT 182→149 (HSBC); FVRR to Neutral, PT 26→13 (Goldman); DIS PT 145→135, Buy maintained (Citigroup, 7/29 — see RISK); WERN upgraded to Outperform (Baird); BE to Outperform (Mizuho); LMND to Market Perform (KBW); SFM to Overweight (JPMorgan); QURE to Outperform (Wolfe); SITE to Hold (Stifel).

---

# ANALYSIS — RISK TO EXISTING POSITIONS

## Mechanical exit-trigger sweep

Run over the **UNION** of `state.current_positions` (14 rows) and live `get_account_positions`, live marks from the IBKR connector.

| Position | Strategy | Shares | Cost/sh | Live mark | Conv. target | Time exit | Exit? |
|---|:--:|---:|---:|---:|---:|---|:--:|
| B:FTV:2026-07-29 | B | 1.6567 | 59.61 | **58.55** | 61.00 | 2026-09-28 | no |
| B:ISRG:2026-07-21 | B | 0.1388 | 352.46 | **353.00** | 400.00 | 2026-09-18 | no |
| B:MDT:2026-06-17 | B | 0.4852 | 79.01 | **85.74** | 90.00 | **2026-07-31** | no |
| B:MSCI:2026-07-27 | B | 0.0863 | 579.28 | **575.76** | 615.00 | 2026-09-25 | no |
| D:AMZN:2026-07-09 | D | 0.1554 | 241.24 | **258.06** | — | — | no |
| D:CRM:2026-07-09 | D | 0.2275 | 160.36 | **179.00** | — | — | no |
| D:DIS:2026-05-07 | D | 0.2822 | 111.32 | **96.10** | — | — | no |
| D:GOOGL:2026-07-09 | D | 0.1043 | 359.85 | **335.00** | — | — | no |
| D:GOOGL:2026-07-26 | D | 0.1534 | 327.84 | **335.00** | — | — | no |
| D:ISRG:2026-07-20 | D | 0.1091 | 349.51 | **353.00** | — | — | no |
| D:RTX:2026-04-27 | D | 0.1601 | 176.90 | **214.70** | — | 2027-04-27 | no |
| D:TSM:2026-07-21 | D | 0.0891 | 427.86 | **409.20** | — | — | no |
| D:TSM:2026-07-29 | D | 0.0659 | ~392.87 | **410.25** | — | — | no |
| D:UBER:2026-07-09 | D | 0.5156 | 73.21 | **70.20** | — | — | no |

**No convergence target hit. No time-based exit due.** **EXITS TRIGGERED: NONE.**

**MDT's time exit is tomorrow, Friday 2026-07-31** — the only dated mechanical event in the book. It is **not** triggered today (today 2026-07-30 < 2026-07-31), so it is deliberately *not* written into RECOMMENDED ACTIONS; tomorrow's D1 fires it and D2 converts it that evening for a Monday fill, which is the designed cadence. Flagged here so the handoff is explicit rather than inferred. MDT closed $85.74 (−2.06%), $4.26 short of the $90 target, so the time stop — not the target — will be the exit path.

**Two provisional rows pending D2a Step-0 reconciliation** (measured, not inferred, from the broker): **B:FTV:2026-07-29** filled today at a broker average of **$59.614** against the $59.54 staging reference the BigQuery row still carries; **D:TSM:2026-07-29** filled today at a **broker-derived ~$392.87** (IBKR blended TSM average $412.99 × 0.155 sh, less the reconciled 07-21 tranche's $38.122 basis) against the $372.70 staging reference in its row. Both are normal same-day staging-to-fill lag, not drift. Marks and per-share costs above use the broker figures for these two rows.

**Connector-union residue:** **HCA (0.0001 sh, $0.04) and IBM (0.0007 sh, $0.15)** again appear in the connector but not in `state.current_positions`. Both are fully-closed positions (HCA CLOSED 2026-06-29 on time-exit; IBM CLOSED 2026-05-27) leaving sub-penny fractional broker residue. Exit checks were run on both and are trivially clean. **Deliberately NOT raised as `position_reconciliation_lag`**, carrying forward the 2026-07-28/29 determination unchanged: that category means "awaiting a D2a Step-0 fill catch-up" and its resolver clears on an incoming fill matched by ticker; no fill is coming, so the alert would never resolve and would sit open permanently — exactly the noise `sp_raise_alert_once` exists to prevent. The residue belongs to the `analytics.account_reconciliation` residual surface. Flagged for D2a/W5, not alerted.

## Per-strategy kill-trigger sweep

`perf.kill_flags` as of 2026-07-29 close, with `current_drawdown` **unconditionally refreshed** against today's live marks (audit ITEM 16 — no judgment predicate on whether to refresh):

| Strategy | Engine dd (7/29) | Live-refreshed dd | Peak unit value | `drawdown_kill` | `runaway_review` | `gate_reached` | `interim_underperf_warning` |
|---|---:|---:|---:|:--:|:--:|:--:|:--:|
| **B** | −0.41% | **≈ −1.8%** | 1.142878 | false | false | false (8/22 closed trades) | false |
| **D** | −1.63% | **≈ −0.2%** | 1.029318 | false | false | false (0/30) | false |

Live refresh derivation (measured from connector `daily_pnl`, stated as an estimate because the authoritative recomputation is D2a's tonight): **D** gained ≈ +$5.17 on ≈ $362 of deployed capital (+1.4%) on the AMZN and TSM prints, lifting deployed unit value ≈ 1.0125 → ≈ 1.0270 against a 1.0293 peak; **B** lost ≈ −$3.22 on ≈ $237 deployed (−1.4%), taking it ≈ 1.1382 → ≈ 1.1227 against a 1.1429 peak. **Both are ~48 percentage points from the −50% drawdown kill.** No termination, no runaway-success review.

- **Interim underperformance warning:** `interim_underperf_warning = FALSE` for both strategies; both are at `deployed_days = 65`, short of the 90-day precondition. No alert raised. No open alert of this category exists to heal-resolve.
- **B open-book pairwise correlation** (`analytics.b_pairwise_correlation`): `n_positions = 4`, `n_pairs = 3`, `avg_offdiagonal_corr = NULL`, `min_overlap_days = NULL`. The `> 0.5 AND n_positions >= 2 AND min_overlap_days >= 40` test fails on the NULLs — B now holds four positions, but three of them (FTV 1 day, MSCI 3 days, ISRG 9 days) have too little history for a ≥40-day qualifying pair, so no mature pair exists yet. **No alert.** Inert by construction, not by luck; this check becomes live around mid-September as MSCI and ISRG mature.

`ops.alerts` holds **zero unresolved rows** at scan time. `sp_auto_resolve_alerts()` ran clean at pre-flight.

## Judgment-laden thesis-invalidation checks

Every open position was tested against its at-entry invalidation criteria using in-window evidence. **No criterion was breached on any position.** The substantive results:

**AMZN — all five criteria moved FURTHER from breach.** (1) AWS YoY <18% for 2 consecutive quarters: **+37%**, accelerating from 28% in Q1. (2) AWS operating margin <~30% for 2 consecutive quarters: **39.4%**, up from 37.7%. (3) AWS backlog declining sequentially: reportedly **~$364B → ~$496B** (secondary-sourced, direction unambiguous, exact figure not primary-verified against the 10-Q). (4) Anthropic/OpenAI commitments renegotiated down or churned: the 8-K describes Anthropic and OpenAI making "multi-year, multi-gigawatt commitments" to Trainium, with new Meta and OpenAI arrangements added in Q2 — expanding, not contracting. (5) Segment reporting restructured: unchanged. This is the single strongest evidence event in the book today and drives the only add flag below.

**TSM — invalidation-3 actively negated.** No TSM-specific disclosure in the window; the +7.64% is pure MSFT read-across. But criterion 3 is "structural AI-capex reset (hyperscaler/Nvidia order cuts; CoWoS utilization drop)," and today delivered its opposite: MSFT's Azure +43% with capex guided higher into FY27, and META raising its capex floor. Criteria 1 and 2 have no new evidence (last measured GM 67.7%, USD revenue +33.7% YoY, sub-7nm mix 77%, from the mid-July print). **NOT BREACHED.**

**FTV — the one close call, and it is close.** Criteria: (1) a sell-side downgrade or PT cut *explicitly citing the AHS margin-compression concern* — **none found** in any source reviewed, though the research also could not rule one out; (2) a further margin deterioration or a FY26 adj-EPS guide narrowed/cut below $2.95–3.05 — **no**, the guide was raised to that range on 7/29 and is unchanged; (3) *"a confirmed close below the post-event trough ($58.22 intraday / $59.54 close) on a SUBSEQUENT session with above-average volume."*

Criterion 3 requires an explicit reading, so it is stated here rather than left for a future session to re-derive. **Measured today:** FTV closed **$58.55**, traded to an intraday low of **$57.48** — a fresh 13-week low, below the prior 13-week low of $57.53 — on **8.787M shares against a 90-day average of ≈3.0M** (derived: IBKR `avg-90d-usd-volume` $177.76M ÷ ~$59), i.e. **2.9× average volume**. **Inferred (the interpretation applied):** the criterion says a *confirmed close* below the trough, and the word "confirmed" is doing work — its purpose is precisely to distinguish an intraday break that recovers from a closing break that holds. On that reading the trough level is **$58.22** (the lowest price reached post-event; the "$59.54 close" is the second annotation of the same event-day reference), FTV probed **below** it intraday and **closed back above** it, so the break is **not confirmed**. **Criterion 3: NOT BREACHED.** The alternative reading — trough = the $59.54 closing basis — would score today as a breach, but it would also make the criterion fire on a 1.7% next-session drift, which is inconsistent with sibling criteria that require a downgrade or a guidance cut, and with the position's own "Not exit-triggering" clause covering ordinary adverse mark-to-market without new information.

**FTV therefore stays open, by 0.57%** ($58.55 close vs the $58.22 threshold), on 2.9× volume, with the *substantive* question from yesterday's screen now answered against the thesis: the research **did** locate a real negative detail behind the −7.07% — Advanced Healthcare Solutions **adjusted EBITDA margin fell to 26.1% from 26.9% YoY and adjusted gross margin slipped**, on product mix and growth investments (gurufocus, 2026-07-29). That is second-order against a beat-and-raise, but it means the 7/29 move was **not** the "no identified negative detail" case the entry screen recorded. **Tomorrow's D1 must re-check criterion 3 first.** A close below $58.22 on continued heavy volume is a clean, unambiguous exit under the reading applied above.

**DIS** — no in-window 8-K or disclosure. The FCC/ABC license-review dispute remains at review-and-comment stage (former FCC commissioners filed a letter urging the agency to end the review, 2026-07-28 — before the window); **no final order and no Disney 8-K characterizing it as materially adverse**, so criterion 5 is NOT breached. Citigroup cut its price target 145→135 on 2026-07-29 while maintaining Buy — in-window, mildly negative, not an invalidation trigger. **Fiscal Q3 reports 2026-08-05**, and that print is the mechanism that tests criteria 1 and 2. **CRM** — no in-window disclosure; the −4.98% is continuation of the 2026-07-21 Morgan Stanley downgrade (Overweight→Equal Weight, PT 287→185, citing Agentforce at a $3.4B annualized run rate, ~7% of projected FY revenue) plus KeyBanc's July cut. Analyst opinion, not a criterion. **UBER** — no in-window disclosure; Q2 reports **2026-08-05**. The $14.8B Delivery Hero acquisition is a live forward risk to criterion 4 (Gross Bookings disclosure comparability) once it closes, not yet triggered. A reported Waymo/Phoenix exit **could not be date- or source-verified** and is recorded as unverified, not as fact. **GOOGL, RTX, ISRG, MDT, MSCI** — no material in-window company news; all criteria NO NEW EVIDENCE or NOT BREACHED.

## Watchlist candidates

No watchlist candidate's status changed materially in the window. The A queue is unchanged and remains blocked at the router (A = DO-NOT-ACTIVATE confirmed); the 2026-07-29 resolution of the LLY retatrutide conflict stands and needs no further action before M1 (2026-08-03). MU, NBIS, INTC and ADBE — all noted on 7/29 — moved with the AI complex today (NBIS +27.13% on rotation) with **no thesis-level new information**; deliberately not re-noted.

---

# ANALYSIS — OPPORTUNITY CHECK

Evaluated for every roster-active strategy carrying `review_cadence: reactive` in `strategy/roster.yaml` — **A, B, C, E** (D is `long_horizon` and excluded here; its adds are handled in the next section).

## Strategy B — 2 candidates

**FICO (Fair Isaac) — the stronger.** −17.01% close-to-close on event day 2026-07-30, ~$31.8B market cap, deeply liquid. Clears **entry criterion 1** (≥5% close-to-close on event day, `strategy/04_strategy_b.md`); the 10-trading-day window closes **~2026-08-13**. The criterion-2 shape is the cleanest available: Q2 **beat on both lines** (EPS $12.50 vs ~$10.80 est.; revenue $692M vs $628.55M, +10.09%) and the stock fell 17% on **management commentary** about the FHFA "Lender Choice" policy enabling mortgage-market score-shopping — a competitive-narrative concern, not a reported number. RBC cut its target from 2400 to 1525 **while keeping Outperform**, which is itself evidence that the sell-side read the move as a multiple event rather than an earnings event.

**Must defeat:** that the FHFA policy is a genuine, permanent impairment of FICO's mortgage-scoring pricing power rather than a sentiment overshoot — the VantageScore competitive opening is structural, and a monopoly-rent business losing its monopoly is *correctly* re-rated, not mispriced. If the thesis cannot separate a multiple compression that is warranted from one that is not, this dies at criterion 2 or 4. The thesis must also net out the day's Financials/Information-Services beta (XLF +0.56% — small, so most of the −17% is idiosyncratic, which favours the candidate).

**ALNY (Alnylam) — the weaker.** −28.31% close-to-close on event day 2026-07-30, ~$25–38B market cap, a new 52-week low. Clears criterion 1; window closes **~2026-08-13**. The largest decline on the tape.

**Must defeat:** this file's own consistent standard that an identified fundamental cause means information rather than sentiment — and ALNY has one, an explicit **FY2026 product-revenue guidance cut** citing ATTR-CM market headwinds. That is the same test that killed PPG on 7/29 and it applies with more force here, because a guidance cut at a commercial-stage biotech re-rates the forward revenue base directly. The candidate is surfaced because −28% is large even against a guidance trim, but it is flagged as lower conviction and should be expected to fail at criterion 4 unless the thesis can quantify the guide-down and show the de-rate exceeds it by a wide margin.

**Explicitly NOT routed as B candidates**, despite clearing the ≥5% floor: **MSFT (+15.51%), META (−7.95%), MKTX (+29.45%), CORT (+27.29%), BHC (+28.85%), AXTI (+26.97%), LRCX (~+17%), GPI (−17.11%)** — every one moved on a disclosed number (revenue, EPS, margin, guidance), which is criterion-4 information, not sentiment. **RTO (−17.60%)** additionally fails B instrument eligibility as a UK-domiciled ADR. **NBIS, IREN, CIFR** fail criterion 1 outright — a sector rotation is not a "public event." **AMZN (+3.90% regular)** is `below_spec_floor` and is a held D position; per §19 it is context and add evidence only, never a B route.

**Forward note (not an action):** **AMZN** and **AAPL** both printed after today's close, so their *event-day* close-to-close is measured on **Friday 2026-07-31** and belongs to tomorrow's D1 screen, not this one. AAPL's −8% extended-hours reaction to supply-constrained guidance is on track to clear the ≥5% floor; AMZN's +8.7% extended likewise. Neither is routed today.

## Strategy C — no candidate today, window opens in ~2 days

C is **HYBRID ACTIVATE (FOMC-only)**: new C entries are permitted only for FOMC catalysts meeting entry criteria 1–5; corporate-earnings, FDA-PDUFA and vol-directional theses remain DO-NOT-ACTIVATE. The next FOMC is **2026-09-15/16**, which is **47 days out** — just outside C's 45-day catalyst window. **The window opens 2026-08-01.** This is worth stating precisely because the setup is unusually well-formed: a genuinely contested meeting (three hike dissents, ~60% market-implied hike odds, an unexplained dissent bloc, and a chair publicly refusing to be "constrained" by market pricing) is exactly the kind of two-sided FOMC that C's defined-risk structures are designed for, and VIX at 17.09 makes the structures cheaper than they were 24 hours ago. Routed to the first D1 on or after 2026-08-01 to surface as a live candidate; no action today.

## Strategy A — no candidates

The A router is **DO-NOT-ACTIVATE (confirmed)** as of M4 2026-07 and nothing in the window flips it (see REGIME CHECK). Names continue to accumulate in the `Watchlist.md` A queue against the standing resolution trigger, "next M1 with A router ACTIVATE." No new name met the bar for queue addition today.

## Strategy E — evidence, not an entry

E is **ACTIVATE (substantive) + execution-feasibility-deferred**; the deferral gates any live entry at the current ~$1.9k per-strategy book size, so nothing here is actionable. It is recorded as evidence because today produced the widest divergences this file has logged: **MSFT +15.51% against META −7.95%, a ~23pp one-session spread between two mega-cap platform businesses resolving the same catalyst in opposite directions**; semi-cap (AMAT +15.0%, LRCX +17%) against the broader complex; and 7.81pp of sector dispersion with the equal-weight index red beneath a +1.66% cap-weighted print. The MSFT/META pair in particular is a textbook narrative-divergence setup, and it is being declined on **execution feasibility alone**, not on merit — which is precisely the cost the deferral was accepted to bear.

---

# ANALYSIS — ADD-CANDIDATE CHECK (Strategies A, B, D only — Rev 40)

All **14** open A/B/D positions evaluated. **1 flagged, 11 declined on merits, 2 declined at the HARD GATE.**

## FLAGGED

**AMZN — Strategy D — strengthened conviction.** Existing position `D:AMZN:2026-07-09` (entry 2026-07-09, 0.1554 sh @ $241.24/sh, thesis ref `events.decision_log` `c39e644a-9601-4faa-8b62-d522bf092dd3`, `events.position_events` `D:AMZN:2026-07-09`), mark $258.06, **+6.97% vs cost**.

**Trigger — strengthened conviction, not a dip.** The Q2 print reinforced the original thesis without replacing it: the thesis is an AWS-durability thesis, and AWS **accelerated from 28% to 37% YoY — its fastest in 18 quarters — at a 39.4% operating margin**, with backlog reportedly rising ~$364B → ~$496B and Anthropic/OpenAI Trainium commitments described as multi-year and multi-gigawatt. That is new information reinforcing the original read, which is exactly `strategy/06_strategy_d.md`'s trigger (b).

**HARD GATE — invalidation criteria confirmed UNBREACHED, all five,** measured today rather than inherited: (1) AWS YoY <18% two consecutive quarters — 37%, accelerating; (2) AWS operating margin <~30% two consecutive quarters — 39.4%; (3) AWS backlog sequential decline two consecutive quarters — rising; (4) Anthropic/OpenAI commitments renegotiated down or churned — expanding, with new Meta and OpenAI arrangements added; (5) metric-immutability, AWS segment reporting restructured — unchanged, still a standalone segment on the same metrics. `invalidation_criteria_evaluable = true` (criteria mirrored verbatim from the entry record by the bigquery/117 backfill, 2026-07-30).

**Cross-strategy exclusions clear:** AMZN is held only in Strategy D; no concurrent A or B position exists in the name, so the no-concurrent-A-and-B / A-and-C rules are satisfied. **Per-name envelope:** AMZN's $40.10 market value is ~2.1% of the ~$1,880 D sub-portfolio NAV against the ≤10% per-name aggregate Capital-at-Risk ceiling — ample headroom.

**Next step:** full thesis construction required in a separate session, same rigor as a first entry, per Strategy.md "Adding to an existing position." Sizing is the add's own AI-chosen risk budget under Rev 43, justified against the seven-factor list and adversarially attacked on size — **not** a fixed 2% tranche. **Must defeat:** that the stock has already re-rated +13.87% on this news, so the information is substantially in the price; and that the $53.4B non-operating Anthropic mark, not operations, carried the headline EPS beat, with TTM free cash flow swinging to **−$7.6B** on $169B of capex — the same unmonetized-capex concern that took META down 7.95% on the same night, applied to a company the market chose to reward instead. If the add cannot show why AMZN's capex is credited where META's is not, it should size small or decline.

## DECLINED AT THE HARD GATE (2)

Neither position can have "unbreached" affirmatively confirmed, so neither is eligible regardless of the merits — `invalidation_criteria_evaluable = false`:

- **B:ISRG:2026-07-21** (+0.15% vs cost) — `invalidation_status.status = 'NOT_DISCRETELY_RECORDED_AT_ENTRY'`.
- **B:MDT:2026-06-17** (+8.51% vs cost) — same marker; and separately moot, since its time exit is tomorrow.

Both are the honest marker `bigquery/117` wrote for the two Strategy B positions that genuinely recorded no discrete criteria at entry, because B exits mechanically on convergence target or time exit by design. This is the case a plain `invalidation_status IS NULL` test would miss entirely — since the 2026-07-30 backfill, that test reads FALSE for all 14 open positions and would report every one as evaluable. **The structural finding stands and is now measured rather than asserted: 2 of 14 open positions (14%) are ineligible for adds by record-keeping rather than by merit, and both are Strategy B.**

Worth recording as the counterpart: on 2026-07-28 **D:DIS and D:TSM** were declined at this same gate purely because their `invalidation_status` was NULL. The bigquery/117 backfill landed 2026-07-30 and both are **evaluable today** — DIS and both TSM tranches are declined below on merits, not on missing data. That specific gap has closed.

## DECLINED ON MERITS (11)

| Position | vs cost | Trigger shape | Why declined |
|---|---:|---|---|
| **B:FTV:2026-07-29** | −1.90% | dip-with-intact-thesis | One session old, filled this morning, and criterion 3 cleared by only 0.57% on 2.9× volume with the AHS margin negative now confirmed. Adding into an unresolved near-breach is the opposite of what the gate is for. |
| **B:MSCI:2026-07-27** | −0.61% | none | A 0.6% drawdown is not a dip; no new MSCI information in the window (Q2 was 7/21, outside it). |
| **D:CRM:2026-07-09** | +11.63% | dip-with-intact-thesis | The −4.98% is continuation of the 7/21 Morgan Stanley downgrade, whose substance (Agentforce at ~7% of revenue, "inflection may take longer") goes at criterion 1's mechanism without breaching it. Unresolved analyst thesis-challenge, still +11.6% above cost, next print not until Aug/Sept — not a strengthened-conviction case. |
| **D:DIS:2026-05-07** | −13.67% | dip-with-intact-thesis | The genuine add case on the board after AMZN, and declined on timing: **fiscal Q3 prints 2026-08-05**, six days out, and that single print tests two of the three primary criteria (SVOD margin, FY26 EPS guide). Adding blind into the event that resolves the thesis is not a dip trade. Citigroup's 7/29 PT cut 145→135 is a further reason to wait, not to size up. |
| **D:GOOGL:2026-07-09** | −6.91% | dip-with-intact-thesis | The dip that justified an add on this name **was already acted on 2026-07-26**, at $325.56 — a better basis than today's $335.00 — and no new GOOGL information has landed since. A third tranche four sessions later on an unchanged fact set is stacking, not a trigger. |
| **D:GOOGL:2026-07-26** | +2.18% | none | Same name, treated with the parent above. |
| **D:ISRG:2026-07-20** | +1.00% | none | No new evidence; last print 7/16, outside the window. (Held concurrently in B and D — permitted; only A-and-B and A-and-C are excluded.) |
| **D:RTX:2026-04-27** | +21.37% | none | No in-window evidence, no dip, +21% above cost. GTF backlog >8,000 engines and growing; the Airbus claim remains unquantified at arbitration stage. |
| **D:TSM:2026-07-21** | −4.36% | strengthened-conviction | Real trigger, already taken: the strengthened-conviction add was staged **yesterday** and filled today at ~$392.87, ~4% below the current mark. A same-week third tranche on the same MSFT-capex catalyst is stacking. |
| **D:TSM:2026-07-29** | +4.42% | none | Same name, treated with the parent above; one day old and not yet reconciled. |
| **D:UBER:2026-07-09** | −4.11% | dip-with-intact-thesis | **Q2 prints 2026-08-05**, six days out and untested against three of four criteria; the $14.8B Delivery Hero acquisition is an unresolved overhang with a live forward risk to criterion 4's disclosure comparability. Wait for the print. |

**Pattern worth surfacing:** three of the eleven declines (DIS, UBER, and to a lesser extent CRM) are declined for the *same* reason — **a Q2 print inside the next six days that tests the position's own primary invalidation criteria**. That is not eleven independent judgments; it is one calendar fact producing three. Both DIS and UBER report **2026-08-05**, so the 2026-08-05 and 2026-08-06 D1 runs will face a materially re-informed add decision on both names simultaneously.

Logged as **ONE** `entry_type='add-candidate-review'` `events.decision_log` row for the whole sweep, with the per-position `positions` array, `trigger_type` drawn from the pinned controlled vocabulary, `n_evaluated=14`, `n_flagged=1`, `n_declined_hard_gate=2`. Record-only; it gates nothing. This is the **first row of this entry_type**.

**⚠️ Write-contract / read-view mismatch found on this first write — alerted, not papered over.** **MEASURED:** `state.add_candidate_reviews` (`bigquery/116_decision_record_analyzability.sql`, line ~679) parses the JSON key `$.invalidation_status_null`, while the D1 slice's write contract — revised 2026-07-30, the same day — mandates **`$.invalidation_criteria_evaluable`**, with **inverted polarity** and a broader definition, and states explicitly: *"Do NOT implement this as `invalidation_status IS NULL`: since the 2026-07-30 backfill that is FALSE for all 14 open positions, so an IS-NULL test would report every position as evaluable and silently re-hide exactly the ambiguity this field exists to make legible."* This run wrote the **contract-mandated** key, so the view's `invalidation_status_null` column reads NULL for all 14 position rows — the one field the decision-record audit created this row to expose is blank on read. Every other column of the view parses correctly (verified: 14 rows, `flagged=1`, `declined_hard_gate=2`, `declined=11`). **INFERRED, not verified:** this looks like the plan text being revised after `116` was authored on the same day; that ordering was not checked against commit history.

**No correction row was written and nothing was rewritten.** `events.decision_log` is append-only, the row itself is correct and complete, and this is a read-view defect rather than a bad write — a `correction` row would misattribute the fault. Nor was the legacy key back-filled into the payload to make the view light up, which would have meant writing a field whose name asserts the exact IS-NULL semantics the contract forbids. Instead: `CALL ops.sp_raise_alert_once('warning','D1','schema_contract_drift', …)` — durable, deduped, owner-visible via `alert_emailer.gs`, and it survives this file being overwritten tomorrow, which the finding would not have done otherwise. **Until the view is amended, the field is queryable directly from `events.decision_log.fields`.**

---

# ANALYSIS — REGIME CHECK

**No inter-monthly router review recommended.** High bar; the bar was not cleared.

What was tested. **(1) B's HIGH-VIX exclusion:** VIX 17.09, back below both its 50d (17.43) and 200d (18.74) averages after a one-day −17.28% collapse — the exclusion is further from triggering than yesterday, not closer. **(2) SPY trend:** 741.69, still below the 50dma (~744.7) for a 4th session and above the 200dma (~699.5) — **NEUTRAL holds**, unchanged, and the A router's UP+HEALTHY clause still fails. **(3) Breadth:** two-thirds of constituents lower and the equal-weight index red argues breadth is *deteriorating* beneath the print, which if anything reinforces the current A DO-NOT-ACTIVATE / D-caution posture rather than challenging it. **(4) `policy_stance='hawkish'`:** confirmed and hardened — a 9–3 hold with three hike dissents, ~60% September hike odds, and the 30Y at a 2007 high. **(5) `inflation_trend='reaccelerating'`:** the first genuine counter-evidence in weeks — headline PCE decelerated 4.1%→3.7% and core 3.4%→3.3% — but a single month's in-line print is not a trend flip, and Q2's GDP-embedded PCE price index *rose* to 5.1% from 4.6%.

**The one input that is genuinely stale is `shock_overlay='latent'`**, set 2026-07-01 on the reasoning that "the kinetic phase has paused and oil normalized." The kinetic phase has emphatically not paused: this week added a ballistic-missile strike on a US base in Jordan, joint US–Saudi strikes on Iraq with 20 PMF deaths, a first strike on Egypt, and three tankers halted in the Strait of Hormuz. The *price* half of the reasoning still holds — oil closed roughly flat today and Brent gave back part of Wednesday's spike — which is why this is a stale description rather than a falsified state, and why it does not on its own clear the inter-monthly bar. **M1a runs 2026-08-03, four days out, and will re-derive `shock_overlay` from scratch on the full month's evidence.** Firing an inter-monthly review to pre-empt a scheduled re-derivation four days away would be process for its own sake. Routed to M1a as a flagged input; **default NO on ambiguity, as specified.**

---

# ANALYSIS — FRONTIER-LLM CAPABILITY CHECK

Thursday rotation slot (§6.1 battery: sycophancy / anchoring). The Hugging Face MCP server exposes no dedicated `paper_search` tool; `hf_fs search hf://papers` was used against the same arXiv-linked index. Exactly one paper fell inside the window.

**arXiv 2607.26981 — "OptimismBench: Forecasting Bias and the Alignment Effect in Language Model Judgment"** (published 2026-07-29). Elicits both P(success) and P(failure) for the same scenario and tests whether they sum to ~100%, detecting *signed* bias in model probability judgments. Across 16 models from 8 providers, 14 showed a systematic optimistic tilt; paired base-vs-chat comparisons indicate post-training sets the sign of the bias rather than removing it, and the effect survives prompt, temperature, perspective and self-debiasing ablations.

**Disposition: flagged, not captured.** It bears on `AI_Trading_Foundation.md` §2.13 (probabilistic miscalibration / asymmetric optimism), but as a complementary measurement rather than a contradiction: §2.13's specific numerical claims are untouched. Its one directionally interesting finding — that pessimism, not optimism, was the outlier specifically in one provider's frontier tier — is scoped to a single paper with no named model version, which is well short of the bar for a Tier-1 architectural change or a contradicted Tier-2 numeric. **No `[HF Frontier-LLM Capture]` decision_log entry written; no `state.strategy_candidates` row** (it is a bias-measurement benchmark, not a new strategy archetype or edge signal, so the materiality filter for candidate emission is not met). Default-silent on ambiguity, as specified. Recorded here so Q3's quarterly delta can pick the reference up if the finding replicates.

---

# PARK ALLOCATION CALL

**Current policy:** SGOV (risk tier 0), effective 2026-07-26. The park is **$8,952.93 of $9,432.16 net liquidation — 94.9% of the account.**

**Evidence gathered fresh this session** (a floor, not a ceiling): live VIX 17.09 (−17.28%, intraday 17.01–20.08, 50d 17.43, 200d 18.74); SPY 741.69 (+1.68%), 50dma ~744.7, 200dma ~699.5, −2.46% from the 52-week high, 4th consecutive close below the 50dma; `state.park_signal_daily` through 2026-07-29 (`spy_trend=NEUTRAL`, `dd_from_252d_high=−3.96%`); `hy_oas` 2.74 (FRED, June ref-month); `state.current_regime` FUNDAMENTAL_AXIS (`shock_overlay=latent`, `inflation_trend=reaccelerating`, `policy_stance=hawkish`, `growth_momentum=stable`, `risk_sentiment=neutral`); today's DEVELOPMENTS above. Sought beyond the listed floor: S&P 500 breadth internals (equal-weight and ex-Technology), the 30Y intraday high, September hike-odds pricing, and the yen intervention — each of which changed the call's reasoning and none of which is on the standard list.

- **`vehicle` — SGOV. KEEP.**
- **`conviction` — HIGH, `conviction_pct` 72.** (Down from 76 on 2026-07-29. The move is deliberate and is explained below rather than smoothed over.)
- **`rationale`** — Today produced the single best argument to re-risk that this sequence has offered: the VIX gave back the entire FOMC spike in one session, closing at 17.09, below both its 50d and 200d averages, and the index recovered nearly all of Wednesday's loss. I am declining it, because **the two runner-up vehicles are ruled out by the same day's evidence from opposite directions.** A re-risk to **VTI or VOO** (tier 4) would be buying an index whose *median constituent fell*: two-thirds of S&P 500 members closed lower, the equal-weight S&P closed red, and the S&P 500 ex-Information-Technology was down — the +1.66% print is Microsoft's ~$491B single-day gain and the chip complex it dragged, which is a one-stock event, not a broadening. A duration step to **GOVT or IEF** (tier 1) would be adding duration into a bear market the Fed just endorsed: the 30Y touched 5.23% intraday, its highest since 2007, and closed at 5.21% with the whole curve up 1bp *on a day when Q2 GDP undershot by 0.6pp and both PCE measures cooled* — when weak growth and softer inflation cannot rally the long end, duration is not being paid for the risk. **TLT** (tier 2) is the same trade with more convexity against it. **SGOV is the only rung on the menu indifferent to both failures**, and it collects the front-end yield that a 60%-odds September hike is actively repricing upward. Two dated binaries land inside 24 hours — the BoJ meets Friday against a yen that required suspected official intervention today, and the Q2 Employment Cost Index prints Friday morning — either of which can move the front end before a re-risk could be reversed.
- **`invalidation`** — A close **above the SPY 50dma (~744.7) accompanied by positive breadth** (equal-weight S&P and S&P-ex-Technology both green on the same session) **and a 30Y that stops making new highs** would flip this to a lateral or re-risk step toward AOR. Independently: `hy_oas` widening through ~3.5%, or a Strait of Hormuz closure that sustains Brent above $100, would hold SGOV regardless of what equities do.
- **`theater_check`** — **PASS.** The risk today is the inverse of yesterday's. Yesterday KEEP was easy: the tape was down 1.5%, VIX was up 13%, and an unresolved binary sat 18 hours out. Today the tape is up 1.66%, VIX collapsed 17%, and the binary resolved — so the *comfortable* answer is the one I gave yesterday, and repeating it is exactly how a KEEP becomes a default rather than a decision. I have therefore (a) named the strongest re-risk argument explicitly and at the top rather than at the end, (b) **lowered conviction from 76 to 72** to record that the volatility case genuinely weakened even as the breadth and duration cases strengthened, and (c) made the invalidation a **conjunction of three observables** — 50dma, breadth, 30Y — rather than a single soft condition, so a future session can score it rather than re-argue it. The premises were re-derived on today's close, not carried forward.

**Status: BOUND** (a KEEP is trivially BOUND — D2's PARK ALLOCATION CONVERSION no-ops when the called vehicle equals the current policy vehicle). `direction='keep'`.

Logged: `events.decision_log` `entry_type='park-allocation'`, `status='BOUND'`, `direction='keep'`, with the full `readings` evidence snapshot. Heartbeat written: `ops.heartbeat ('loop:park_allocator', 'SGOV call, status=BOUND')`.

---

# RECOMMENDED ACTIONS

- **New entry candidate — FICO, Strategy B (long).** −17.01% close-to-close on 2026-07-30, the event day, on a **double beat** (Q2 EPS $12.50 vs ~$10.80 consensus; revenue $692M vs $628.55M, +10.09%) with the decline driven by **CEO commentary** on the FHFA "Lender Choice" policy enabling mortgage score-shopping, not by any reported number — RBC cut its price target 2400→1525 **while maintaining Outperform**. Clears B entry criterion 1; window closes ~2026-08-13. ~$31.8B market cap, deeply liquid. Full thesis construction required in a separate session per Strategy.md. Higher conviction of the two. **Must defeat:** that the FHFA/VantageScore competitive opening is a permanent impairment of FICO's mortgage-scoring pricing power, in which case a −17% de-rate is correct pricing and the candidate dies at criterion 2 or 4; the thesis must also confirm the move is idiosyncratic rather than sector beta (XLF was +0.56% on the day, which favours the candidate).
- **New entry candidate — ALNY, Strategy B (long).** −28.31% close-to-close on 2026-07-30, the event day — the largest decline on the tape and a new 52-week low — on a **FY2026 product-revenue guidance cut** citing ATTR-CM market headwinds. Clears B entry criterion 1; window closes ~2026-08-13. Full thesis construction required in a separate session. Lower conviction of the two and flagged as such. **Must defeat:** this file's own consistent standard that an identified fundamental cause means information rather than sentiment — a guidance cut re-rates the forward revenue base directly, the same test that killed PPG on 7/29. Unless the thesis can quantify the guide-down and demonstrate the de-rate exceeds it by a wide margin, this is a NO-GO at criterion 4.
- **Add candidate — AMZN, Strategy D.** Second tranche onto `D:AMZN:2026-07-09` (entered 2026-07-09, 0.1554 sh @ $241.24/sh; thesis ref `events.decision_log` `c39e644a-9601-4faa-8b62-d522bf092dd3`). Trigger: **strengthened conviction** — the Q2 print reinforced the AWS-durability thesis without replacing it, with **AWS revenue $42.23B, +37% YoY, the fastest in 18 quarters** (from 28% in Q1) against a $40.54B consensus, and **AWS operating income $16.62B at a 39.4% margin** against a $13.62B consensus. **Invalidation criteria confirmed UNBREACHED, all five:** AWS YoY 37% (criterion 1 needs <18% for 2 consecutive quarters); AWS operating margin 39.4% (criterion 2 needs <~30%); backlog rising ~$364B→~$496B (criterion 3 needs a sequential decline); Anthropic and OpenAI Trainium commitments described as multi-year/multi-gigawatt and expanding, with new Meta and OpenAI arrangements added in Q2 (criterion 4); AWS still reported as a standalone segment on unchanged metrics (criterion 5). Criteria read from `state.current_positions.invalidation_status`, mirrored verbatim from the entry record by the bigquery/117 backfill and **assessed fresh today, not inherited**. Cross-strategy exclusions clear (AMZN held in D only). Per-name aggregate CaR headroom ample — $40.10 position against a ~10% ceiling on a ~$1,880 sub-portfolio. Full thesis construction required in a separate session, same rigor as a first entry, per Strategy.md "Adding to an existing position"; sizing is the add's own AI-chosen risk budget under Rev 43, not a fixed 2% tranche. **Must defeat:** that the stock already re-rated +13.87% on this news so the information is largely in the price; and that the headline EPS beat was carried by a **$53.4B non-operating gain primarily from the Anthropic investment** while TTM free cash flow swung to **−$7.6B** on $169B of capex — the identical unmonetized-capex concern that took META down 7.95% the same night. The thesis must explain why AMZN's capex earns credit where META's did not, or size small.

*No exits triggered. No watchlist updates. No router reviews recommended.*

```yaml d1_actions
- action: thesis
  ticker: FICO
  strategy: B
  detail: "-17.01% close-to-close on event day 2026-07-30 on a double beat (Q2 EPS 12.50 vs ~10.80 consensus, revenue 692M vs 628.55M +10.09%), with the decline driven by CEO commentary on the FHFA Lender Choice policy enabling mortgage score-shopping rather than any reported number; RBC cut its target 2400->1525 while maintaining Outperform; clears B entry criterion 1, window closes ~2026-08-13, ~31.8B market cap; higher conviction of the two - must defeat that the FHFA/VantageScore competitive opening permanently impairs FICO mortgage-scoring pricing power (in which case -17% is correct pricing and it dies at criterion 2 or 4), and must confirm the move is idiosyncratic rather than sector beta (XLF +0.56% on the day)"
- action: thesis
  ticker: ALNY
  strategy: B
  detail: "-28.31% close-to-close on event day 2026-07-30, the largest decline on the tape and a new 52-week low, on a FY2026 product-revenue guidance cut citing ATTR-CM market headwinds; clears B entry criterion 1, window closes ~2026-08-13; lower conviction of the two - must defeat the identified-cause standard that a guidance cut is information rather than sentiment (the same test that killed PPG on 2026-07-29), and unless the thesis quantifies the guide-down and shows the de-rate exceeds it by a wide margin this is a NO-GO at criterion 4"
- action: add
  ticker: AMZN
  strategy: D
  detail: "strengthened-conviction add onto D:AMZN:2026-07-09 (entry 2026-07-09, 0.1554 sh @ 241.24/sh, thesis ref decision_log c39e644a-9601-4faa-8b62-d522bf092dd3); Q2 reinforced the AWS-durability thesis without replacing it - AWS revenue 42.23B +37% YoY, fastest in 18 quarters vs 28% in Q1 and vs 40.54B consensus, AWS operating income 16.62B at a 39.4% margin vs 13.62B consensus; all five invalidation criteria confirmed UNBREACHED - AWS YoY 37% vs the <18% two-quarter bar, operating margin 39.4% vs the <~30% bar, backlog rising ~364B->~496B vs a sequential-decline bar, Anthropic and OpenAI Trainium commitments multi-year/multi-gigawatt and expanding with new Meta and OpenAI arrangements added, and AWS still a standalone segment on unchanged metrics; criteria read from state.current_positions.invalidation_status (bigquery/117 mirror) and assessed fresh today; cross-strategy exclusions clear, AMZN held in D only; per-name CaR headroom ample at a 40.10 position against a ~10% ceiling on a ~1880 sub-portfolio; sizing is an own AI-chosen risk budget under Rev 43, not a fixed 2% tranche; must defeat that the stock already re-rated +13.87% on this news and that the headline EPS beat was carried by a 53.4B non-operating Anthropic gain while TTM free cash flow swung to -7.6B on 169B of capex - the same unmonetized-capex concern that took META -7.95% the same night"
```

2026-09-09
<!-- d1_scan_through_utc: 2026-09-09T22:40:27Z -->

# Daily Market Development Scan — 2026-09-09 (Wed, MT)

**Scan window: 2026-09-08 16:40 MT → 2026-09-09 16:40 MT** (24.0h — an ordinary single-cycle window, no gap. Resolved from the prior `Daily.md`'s `<!-- d1_scan_through_utc: 2026-09-08T22:40:00Z -->` marker, cross-checked against that file's own commit at 2026-09-08T22:39:01Z; the two agree to within a minute. `state.routine_catchup_window` independently returns `window_start_ts = 2026-09-08T22:42:24Z`, `window_days = 0.98`, `never_completed = false` — same boundary, so no catch-up widening applies and no `CATCHUP[...]` token is owed.)

**ONE completed US trading session inside this window: Wednesday 2026-09-09.** `state.trading_day_today` gives `is_trading_day = true`, `last_trading_day = 2026-09-09`. Every close-to-close figure in this file is measured 2026-09-08 → 2026-09-09.

**Tape.** SPY 765.96 → 762.40 (**−0.4648%**), VOO 704.07 → 700.87 (−0.4545%), QQQ −0.2854%, DIA −0.7500%, IWM **−1.3676%**, SGOV +0.0100%. VIX 15.72 → **16.46** (+4.7074%). Brent 97.92 → **101.21** (+3.3600%), USO +2.6981%. 2Y 4.39 → 4.43, 10Y 4.80 → **4.83** (highest since October 2023), 30Y 5.25 → 5.28. Equity breadth ($S5TH) 60.63 → **56.85**. GLD +0.9079%, TLT −0.5718%, UUP −0.0357%, BITO −0.2846%. All equity/ETF/index figures are IBKR regular-session daily bars (`get_price_history`, `step='ONE_DAY'`, `outside_rth=false`), each verified carrying a 2026-09-09 bar stamped `13:30:00Z`.

**Nothing about this run is degraded, and that is measured rather than claimed.** 45 distinct single names and 25 ETFs/indices were put to IBKR for confirmation; **all but one resolved with a genuine 2026-09-09 regular-session bar. Zero symbol-level denials.** The single failure was MRO, which has no active US listing (acquired by ConocoPhillips in 2024) — a delisting, not gating. So every `surfaced_count` below is an affirmatively established figure, never a reported zero standing in for an unmeasured population.

---

## TL;DR

- **Exits triggered: none.** No mechanical trigger exists to fire (all 12 open tranches carry NULL `convergence_target` and NULL `time_exit_date`), and no Development breaches any thesis-invalidation criterion.
- **New entry candidates: 9** — Strategy B ×8 (TTAN, CASY, BRZE, TBBK, SIG, ASO, META, CMCSA), Strategy C ×1 (the 2026-09-16 FOMC).
- **Add candidates: none.** 12 open A/B/D tranches evaluated, 0 flagged, 3 declined at the HARD GATE (ISRG, RTX, UBER — breach status never assessed and no covering tranche).
- **Watchlist changes:** the 8 Strategy-B names above enter the B new-entry-candidate queue; no removes and no demotions.
- **Regime review: no review.** No router state is plausibly shifted; default-NO on ambiguity holds.
- **Park: BOUND KEEP at `target_f_pct` 25** (VOO 75% / SGOV 25%), MEDIUM 50 — three standing defensive axes all deepened but **zero entered**, and the ladder returns 25 on its own arithmetic.

---

## DEVELOPMENTS

### 1. Market-wide breaking events

**US–Iran escalation; Brent through $100 for the first time in over a month.** US Central Command struck and destroyed five Iranian oil tankers (M/T Kaviz, M/T Charminar, M/T Horizon 1 and M/T Riesco in the Gulf of Oman; M/T Derya near Kharg Island), retaliating for two prior Iranian missile attacks on a US Navy warship. Iran's IRGC responded with missile strikes on the Al Azraq base in Jordan, threatened tankers at Kuwaiti and Bahraini ports, and warned of an expanded maritime exclusion zone toward Chabahar. This followed Tuesday's Houthi missile and drone strikes on Saudi oil sites at Abha, Najran and Jazan.

- Sources: Al Jazeera, https://www.aljazeera.com/news/2026/9/9/us-destroys-five-iranian-tankers-iran-retaliates-with-attacks-on-jordan-base ; Forbes, https://www.forbes.com/sites/siladityaray/2026/09/09/oil-prices-cross-100-as-iran-war-escalates-amid-renewed-strikes-on-tankers ; Gulf News, https://gulfnews.com/world/mena/us-iran-tensions-escalate-washington-destroys-five-oil-tankers-jordan-intercepts-ballistic-missiles-1.500667960 ; USA Today, https://www.usatoday.com/story/news/world/2026/09/08/us-strikes-iran-destroys-5-oil-tankers-amid-escalating-war/91666127007
- **Dateline caveat, stated rather than resolved:** USA Today datelines the strikes 8 September while Al Jazeera, Gulf News and Forbes date the strikes and the Iranian response to early Wednesday 9 September. The scan window opens 18:40 ET Tuesday, so the event falls inside it or at its very edge on either reading. The exact minute is **not established**.
- **Observable reaction across asset classes (each figure measured here from IBKR bars unless attributed):** equities lower and broad — SPY −0.4648%, DIA −0.7500%, IWM −1.3676%, and 9 of 11 GICS sectors down. Commodities the clear mover — Brent +3.3600% to 101.21, USO +2.6981%; press reports an intraday print near $101 (Yahoo Finance) and AP reports Brent +3.4% on the day, which reconciles with the measured figure. Rates higher across the curve, 10Y +3bp to 4.83%. FX essentially inert — UUP −0.0357%. Gold +0.9079%, a modest bid. Crypto unmoved, BITO −0.2846%.
- **What the cross-asset reaction does NOT show is as informative as what it does:** there was no flight-to-safety bid. The dollar was flat, gold rose less than 1%, and long Treasuries FELL (TLT −0.5718%) rather than rallying. That is a market repricing an input-cost and discount-rate shock, not one pricing a systemic risk event.

**No other market-wide breaking event surfaced in the window** — no material bankruptcy, disaster, unscheduled enforcement action or central-bank surprise. Stated as a measured absence over the scan performed, not as a claim of exhaustiveness.

### 2. Scheduled events that resolved today

**EVENT-IDENTITY GATE applied.** Each result below was verified against reporting that names the fiscal period, and each name's price reaction was independently confirmed from IBKR regular-session bars rather than taken from the reporting.

- **ServiceTitan (TTAN) — Q2: −29.9828%.** Beat on both revenue and EPS; current-quarter revenue guidance came in slightly below consensus. (Benzinga; Motley Fool)
- **Casey's General Stores (CASY) — Q1: −14.2415%.** Beat on revenue, EPS and EBITDA; inside same-store sales growth of 3.2% missed expectations. FY inside-comp guide 2–5%. (Yahoo Finance, https://finance.yahoo.com/markets/stocks/articles/caseys-shares-slide-despite-earnings-150200709.html)
- **Braze (BRZE) — Q2: −21.7090%.** Revenue +26.2% YoY and beat; FCF margin fell to 9.6% from 12.7%, sequential customer adds slowed, RPO growth soft, Q3 EPS guidance weak. (StockStory)
- **Signet Jewelers (SIG) — Q2: +23.9624%.** EPS $2.19 against roughly $1.72 consensus; full-year guidance raised; same-store sales +2.2%. (Seeking Alpha)
- **Academy Sports & Outdoors (ASO) — Q2 FY26: +14.4045%.** Net sales roughly $1.60B, +3% YoY; top- and bottom-line beat; FY guidance raised. (Investing.com)

**Pending, not resolved — recorded as pending with confirmed scheduled dates, with no outcome figures populated:** **PPI Thursday 2026-09-10** and **CPI Friday 2026-09-11**, both ahead of the **15–16 September FOMC**. No major US macro release fell on 2026-09-09; FRED's release calendar shows only routine items (SOFR/EFFR, the gasoline and diesel update, the Quarterly Services Survey). Verified against https://fred.stlouisfed.org/releases/calendar.

### 3. Large single-name moves — AI-SIGNIFICANCE SCREEN (`screen='single-name-move'`)

Logged as one `entry_type='research-screen'` row, `events.decision_log` entry_id **`acc31c4a-2889-4583-a76a-0177ecd34dcf`**. `surfaced_count = 8` (= `ARRAY_LENGTH(passed)`), `rail_tally = 9`, `universe_measured = 45`. Agreement: `both` 8, `ai_only` 0, `rule_only` 2.

| Ticker | Move | Event | Conviction | `legacy_rule_pass` (≥5%) |
|---|---|---|---|---|
| META | **+6.5544%** | Launch of Muse, a paid personal AI agent ($20/$100 tiers) | 75 | true |
| TTAN | **−29.9828%** | Q2 double beat, next-quarter guide slightly light | 75 | true |
| SIG | **+23.9624%** | Q2 EPS $2.19 vs ~$1.72; FY guide raised | 60 | true |
| TBBK | **−22.3264%** | Chime acquiring rival BaaS partner Stride Bank ($590M); loses a named key client | 60 | true |
| BRZE | **−21.7090%** | Revenue beat, deteriorating unit economics, weak Q3 EPS guide | 60 | true |
| CASY | **−14.2415%** | Beat on three metrics, missed inside same-store comps | 60 | true |
| ASO | **+14.4045%** | Q2 beat, FY guide raised, buybacks | 45 | true |
| CMCSA | **−6.6084%** | CFO Jason Armstrong at Goldman Communacopia: Q3 broadband sub losses unlikely to improve YoY | 60 | true |

**Two discovery-vs-confirmation conflicts were resolved by measurement, in opposite directions, and both are recorded because either could have gone unnoticed.** **SIG**: two web sources described a 9–10% move; the IBKR bars read 82.67 → 102.48 = **+23.9624%**, and the bar governs. **INTC**: a web summary implied roughly +7% on a Northland upgrade; the bars read **+1.6943%**, which puts it BELOW the 2% rail and out of the population entirely. In one case the discovery figure understated a real candidate; in the other it would have manufactured one.

**ODD was excluded on a MEASURED cap, not an assumed one.** FMP `profile-symbol` returns marketCap **$0.939B**, less than half the $2B floor, and the row is demonstrably the right symbol on the right date because its `price` field 16.48 matches the IBKR 2026-09-09 close exactly. Per the standing guidance, `profile-symbol` was gone to FIRST for every uncertain cap; a `batch-market-cap` comma-list attempt failed `not_found`, so seven single-symbol calls were spent instead.

**TBBK's rail clearance is thin and is flagged rather than smoothed over:** $2.083B is only ~4% above the floor, inside the band where FMP's implied share count is not trustworthy to better than ~30%. It stays surfaced because the underlying event is unambiguous, but any sizing decision on it wants a second cap source first.

**Cleared the rails but deliberately NOT written up, each recorded with its reason** (`rejected_notable`): **CIFR** −8.6980% in a measured $6.913B name with **no identifiable catalyst** — and the obvious crypto-beta explanation fails on the same session's data, since BITO closed −0.28% and MARA +0.76%; **GRAB** −6.4615%, no catalyst identified because the discovery budget went to larger and better-evidenced names first; **BKNG** −3.8103%, a second consecutive large decline atop roughly −6.7% the prior session with no new catalyst — notable as a continuation rather than an event; **PCG** −4.2510%, already on the B watch overflow since 2026-09-06, with no name-specific catalyst and a move fully consistent with the day's duration repricing; **XOM** +2.2221%, the pure expected beta of the day's single macro event; and the three held names discussed below.

### 4. Sector-level moves — AI-SIGNIFICANCE SCREEN (`screen='sector-move'`)

Logged as one `entry_type='research-screen'` row. `surfaced_count = 7`, `rail_tally = 6`, `universe_measured = 11` (complete — all eleven sector ETFs measured, zero failures). Dispersion **2.3416pp**. One sector up, one exactly flat, nine down. Agreement: `both` 0, `ai_only` **7**, `rule_only` 0 — **no sector cleared the retired 2% legacy bar**, so every surfacing today is an AI-only judgment.

| Sector ETF | Move | Read | Conviction |
|---|---|---|---|
| XLI | **−1.5079%** | Worst sector; hit on both limbs at once — fuel cost from crude, cost of capital from the long end | 60 |
| XLY | −1.3422% | The consumer side of the same fuel channel; adds no independent mechanism | 45 |
| XLU | −1.1738% | Pure duration repricing on the day the 10Y printed a three-year high | 60 |
| XLP | **−1.1542%** | **The regime tell** — see below | 60 |
| XLRE | −1.1162% | Same duration channel as XLU, independently corroborating it | 60 |
| XLE | **+0.8337%** | The only sector up, and significant for its **shortfall** — see below | 60 |
| XLC | −0.6187% | Below the 1% rail, surfaced under §19's sub-net escape valve — see below | 60 |

**XLP is the regime tell, and it is why this screen matters today.** Consumer Staples is a DEFENSIVE sector and it fell MORE than the index (SPY −0.4648%) and more than Healthcare (XLV −0.3291%). On a genuine growth scare staples outperform. Staples underperforming while Energy leads is the signature of an **input-cost shock, not a demand shock** — and that distinction is directly load-bearing for how today's breadth collapse and the park call are read.

**XLE is significant for its shortfall, not its gain.** Brent rose +3.3600% through $100 on a genuine military escalation and USO closed +2.6981%, yet energy EQUITIES took only +0.83% of it. The equity market declined to extrapolate the oil move — restraint that argues the shock is being priced as transient rather than structural.

**XLC's near-flat headline conceals the move rather than reporting it.** META is roughly a 20% weight and rose +6.5544%, contributing on the order of +1.3pp; the sector still closed −0.62%, implying the rest of Communication Services fell on the order of **−2.4%**, with CMCSA −6.6084% and Charter at roughly −7% the visible mass.

**Not concluded: XLK closed at exactly 0.0000%**, to four decimal places, with no driver identified — recorded as an unexplained flat print rather than passed off as calm, and explicitly NOT attributed to META, which sits in Communication Services under GICS, not Technology.

**An FMP source conflict, resolved by measurement.** `sector-performance-snapshot` was run twice with `exchange` passed explicitly (it silently defaults to NASDAQ-only otherwise) and reported Energy DOWN on both scopes — NYSE −0.03%, NASDAQ −1.18% — while a web summary reported Energy UP +0.63%. The IBKR sector-ETF bar settles it: **XLE +0.8337%**. The FMP figures are unweighted averages of single-exchange listings, a different quantity from a cap-weighted sector ETF, so this is not really a contradiction and is not recorded as one.

### 5. Notable commentary

- **Reuters economist poll (2026-09-09).** 70% of economists (65 of 93) polled 4–9 September expect the fed funds rate held at 3.50–3.75% at the 15–16 September FOMC, **down from 90% expecting a hold in the August poll**. Santander's Stephen Stanley: a hike is "probable this month unless Friday's CPI release brings a substantial downside surprise." https://www.reuters.com/business/fed-hold-rates-steady-rest-2026-rising-number-analysts-see-least-one-hike-2026-09-09
- **Morningstar (2026-09-09).** Markets pricing roughly a **60% chance** of a 25bp hike on 16 September — down from 63% a week earlier, up from **44% a month earlier**. https://www.morningstar.com/economy/august-cpi-seen-cooling-will-it-prevent-fed-rate-hike
- **Treasury (2026-09-09).** Secretary Scott Bessent announced tripling the next bond buyback programme for 10–20-year securities, from $2B to $6B. The 10Y nonetheless closed higher at 4.83%. (Yahoo Finance live blog)
- **Goldman Sachs (Spencer Rogers), via Yahoo Finance.** 2026 convertible-bond issuance has already surpassed any prior full-year total (~$135bn YTD), driven mostly by high-yield smaller issuers but increasingly by AI-hyperscaler debt.
- **HSBC — flagged as probably OUTSIDE the window, not counted.** Nicole Inui raised the 2026 year-end S&P 500 target to 8,100 from 7,650 in a note "on Tuesday" (8 September); the source does not timestamp it relative to Tuesday's close, so it may predate the 22:40 UTC window start. Recorded for context only.

---

## ANALYSIS — RISK TO EXISTING POSITIONS

### Mechanical exit-trigger sweep

Run for **every** open position regardless of whether any Development fired, over the **UNION** of `state.current_positions` and live `get_account_positions`.

**Twelve open tranches across eight names, all Strategy D.** Strategies A, B, C and E hold nothing.

**No mechanical exit trigger can fire, and that is a property of the records rather than of today's prices: all twelve tranches carry `convergence_target = NULL` and `time_exit_date = NULL`.** There is no convergence target to reach and no time exit to come due. Stated explicitly so the "no exits" verdict is not mistaken for a check that ran and passed on price.

**Union reconciliation is exact — no RECONCILIATION-LAG POSITION exists.** The connector book and `state.current_positions` agree to four decimal places on every name: AMZN 0.3464 = 0.1910 + 0.1554; DIS 0.7244 = 0.2822 + 0.4422; GOOGL 0.2577 = 0.1534 + 0.1043; TSM 0.1550 = 0.0891 + 0.0659; GEV 0.1244, ISRG 0.1091, RTX 0.1601, UBER 0.5156 each single-tranche and exact. VOO and SGOV are park sleeves, not strategy positions. **No `position_reconciliation_lag` alert is owed** — an affirmative check, not an omission.

### Per-strategy kill-trigger sweep

`current_drawdown` was refreshed **unconditionally** against today's marks, as the rule requires — no judgment predicate was applied to decide whether to run it.

- **Strategy D.** `perf.kill_flags` as of 2026-09-08: `deployed_unit_value` 1.069068979, `peak_unit_value` 1.098110312, `current_drawdown` −2.6447%, `deployed_days` 93, `excess_vs_sgov` **+5.4843%**, `closed_trades` 1 of the 30-trade gate. Refreshing against today's IBKR closes: the D book fell from $548.93 to $540.71, a **−1.4967%** session, putting the refreshed unit value at ≈1.053068 and **refreshed drawdown at ≈−4.10%** against a −50% kill bar — **45.9pp of headroom. No drawdown kill.**
- **Runaway-success (#3):** deployed TWR is 1.053, nowhere near a double. Not flagged.
- **Interim underperformance warning:** `deployed_days` 93 clears the ≥90 leg, but `excess_vs_sgov` is **+5.48%**, not ≤ −15%. `interim_underperf_warning = FALSE`. No open alert of this category exists, so no heal-resolution `UPDATE` is owed either.
- **Strategy B** carries all flags false. Its `kill_flags` row is stamped 2026-08-18 and is three weeks stale — correctly so, because B holds no positions and the engine has had no new daily rows to compute from. Noted so the staleness is not later misread as a monitoring gap.
- **B open-book pairwise correlation:** `analytics.b_pairwise_correlation` returns `n_positions = 0`, so the `n_positions >= 2` term fails and the check is a structural no-op. **This is inertness, not a passing check** — stated because a silent no-op and a clean read look identical from the outside.
- Mark-to-market (#4) and foundation-change (#2) triggers are detected on M4 and Q3/A1 respectively, not here.

### Thesis-invalidation assessment

For each of the twelve tranches: **does any Development above trigger a judgment-laden invalidation criterion? NO, for all twelve — and the reason is structural rather than a close call.** Every criterion across all eight names is a **quarterly-reported fundamental metric**, and today's Developments were a geopolitical oil shock and a rates backup. None of the following moves on a session:

- **AMZN** — AWS revenue YoY <18% for 2 consecutive quarters; AWS operating margin <~30%; AWS backlog sequential decline; Anthropic/OpenAI commitments renegotiated down; metric immutability. **Unbreached.**
- **DIS** — Entertainment SVOD operating margin below 8% for 2 consecutive quarters (measured **~13%** at FQ3 FY26, a third consecutive quarter of expansion: 8.4% → 10.6% → ~13%); FY26 adjusted EPS growth guide cut to ≤6% (**affirmatively passed** — ~12% FY26 and double-digit FY27 reiterated); buyback below the $7B run-rate (**affirmatively passed** — target raised to ≥$9B from $8B); metric immutability (zero non-conforming reports; the announced Q1 FY2027 segment shift is the live forward risk, first testable ~Feb 2027); FCC regulatory escalation (**not engaged**, and an escalation-to-review trigger rather than an auto-invalidation in any case). **Unbreached.**
- **GEV** — total-company organic orders growth YoY below 15% for 2 consecutive quarters (entry-quarter reading **88%**, prior quarter 71%); metric immutability. **Unbreached.** Today's higher gas and oil prices are, if anything, supportive of gas-turbine capex.
- **GOOGL** — Cloud revenue YoY <20% for 2Q; Cloud margin contraction 2Q; Cloud RPO sequential decline 2Q; adverse structural remedy (the 7/23 EU DMA ruling was behavioral, and is the closest-watched leg). All four carry explicit per-criterion `unbreached` readings. **Unbreached.**
- **ISRG** — procedure growth <10% YoY 2Q; placements decline YoY 2Q; recurring revenue decoupling down from procedures; a competitor disclosing displacement of da Vinci at named large IDNs. **No breach identified**; ISRG rose +0.8798% today.
- **RTX** — adverse Airbus damages ruling >$2B; a new powder-metal-style quality event >$1B; GTF Advantage EIS slipping beyond Q1'27; backlog declining 2 consecutive quarters; FY26 FCF guide cut below $7.5B; **FY27 defense procurement cut ≥10% YoY**. **Unbreached** — and the day's developments run *toward* this thesis rather than against it, since a Middle East escalation makes a defense procurement cut less likely. RTX −0.6338%, outperforming the tape.
- **TSM** (both tranches) — gross margin <55% or USD revenue YoY <15% for 2Q; N2/A16 ramp pushed out or sub-7nm share declining 2Q; a structural AI-capex reset. **Unbreached.**
- **UBER** — gross bookings constant-currency YoY <~15% for 2Q; adjusted-EBITDA margin as a % of GB contracting YoY 2Q; Uber One membership stalling or declining sequentially; metric immutability. **Unbreached.** UBER fell −2.8032% and the plausible channel is the fuel shock, but **none of its four criteria is a fuel or price metric** — they are demand and margin metrics reported quarterly. Recorded as a watch item for the next print, explicitly not as an invalidation.

**Dividend-netting rule: inert this run, checked rather than assumed.** `state.price_level_criterion_drift` returns exactly one row (D:DIS:2026-08-05) and it carries `is_exit_criterion = false`, `actionable_price_level = false` and `has_dividend_drift = false` — the "45.00 notional" it picked up is a CaR sizing figure inside a *not-exit-triggering* clause, not a price level. **No open position has a price-level exit criterion**, so no price test was reported and none needed dividend adjustment.

### Watchlist candidates

**PCG** (B watch overflow since 2026-09-06) fell −4.2510% with no name-specific catalyst, fully consistent with the sector-wide duration repricing (XLU −1.1738%, XLRE −1.1162%). **Candidacy status unchanged** — a macro-beta move on an already-watched name is not a fresh qualifying event. **META** (A queue since 2026-07-05; B watch overflow since 2026-07-12) moved materially closer to candidacy and is routed below. **INTC** (A queue since 2026-05-12) was measured at +1.6943%, below the rail — no change. No other watchlist name registered a material change.

---

## ANALYSIS — OPPORTUNITY CHECK

Scoped to roster-active strategies with `review_cadence: reactive` in `strategy/roster.yaml` — **A, B, C and E**. (D carries `review_cadence: long_horizon` and is excluded here; it is in scope for the ADD check below.) Router state from `state.current_regime` as of 2026-09-03: **C = HYBRID ACTIVATE (FOMC-only)**, A/B/D/E = DO-NOT-ACTIVATE. D1 surfaces candidates; activation gating is D2's and M1b's, not this section's.

**Strategy B — eight candidates.** Every one is a significance-judged post-event move that **also clears B's frozen Entry criterion 1** (≥5% close-to-close on the event day, `strategy/04_strategy_b.md`), measured from IBKR regular-session bars: TTAN −29.98%, SIG +23.96%, TBBK −22.33%, BRZE −21.71%, CASY −14.24%, ASO +14.40%, CMCSA −6.61%, META +6.55%. Each requires full thesis construction in a separate session. Two notes carried forward rather than resolved here: **SIG and ASO are upside overreactions**, so fading them is a short-direction thesis, and D2 has historically declined B shorts (`Watchlist.md` short-direction tracking) — surfaced anyway, because the decline is D2's to make on the constructed thesis, not D1's to pre-empt. And **BRZE and TBBK may both be *correctly* repriced** — Braze's unit economics genuinely deteriorated, and Bancorp genuinely lost a named client — which is precisely the question thesis construction exists to answer.

Per the shared **"NO-GO records are context, not barriers"** rule, prior NO-GO entries on any of these names inform but do not pre-empt evaluation.

**Strategy C — one candidate: the 2026-09-16 FOMC.** C is the **sole capital-enabled strategy** and its activation is explicitly FOMC-only. The event is six days out and its probability has been materially repriced — hike odds ~44% a month ago, ~58–60% now, with CPI on Friday 2026-09-11 as the stated swing factor and the Reuters consensus for a hold falling from 90% to 70% in a month. A defined-risk structure around a genuinely two-sided, dateable, high-attention event is exactly C's designed setup. **Flagged with a caveat that is not decorative:** `ops.alerts` carries an open W5 finding (`strategy_c_criterion2_unreached_pattern`) that C has failed entry criterion 2 on five consecutive drains and has never deployed capital. Criterion 2 is assessed in thesis construction, not here — but a sixth consecutive failure would be a pattern worth W5's attention rather than another silent decline.

**Strategy A — no candidates.** No development in the window announced a *new* qualifying catalyst within a 6-month horizon on an A-eligible name. The 15–16 September FOMC is a macro event, not a name-level catalyst, and does not qualify.

**Strategy E — no candidates, and the near-miss is recorded because it is a genuine judgment call.** The day's largest divergence sits *inside* one GICS sector: META +6.5544% against CMCSA −6.6084% and Charter at roughly −7%, a >13pp same-session spread within Communication Services. That is real dispersion, but **META and the cable names are not in the same industry group** — social/AI advertising versus cable broadband — and an E pair needs a genuine shared factor for the divergence to mean-revert against. Surfacing it would be pattern-matching on a sector label. Declined on that ground, not on E's DO-NOT-ACTIVATE router state.

---

## ANALYSIS — ADD-CANDIDATE CHECK

Strategies **A, B and D only**. Twelve open tranches evaluated, **zero flagged**, **three declined at the HARD GATE**. Logged durably — including every decline — as one `entry_type='add-candidate-review'` row in `events.decision_log`.

`mark_vs_cost_pct` uses the pinned basis on **both** halves: numerator the IBKR regular-session daily-bar close for 2026-09-09, denominator **each tranche's own** `cost_basis / shares`, never the account-level blended `avg_price`. Neither `get_price_snapshot` nor `get_account_positions.market_price` was used — both were the measured failure mode on 2026-09-07.

| Tranche | `mark_vs_cost_pct` | Trigger | Disposition | `evaluable` |
|---|---|---|---|---|
| D:GOOGL:2026-07-09 | −8.1141% | dip-with-intact-thesis | declined | false |
| D:DIS:2026-05-07 | −6.4131% | dip-with-intact-thesis | declined | false |
| D:AMZN:2026-07-30 | −5.0031% | dip-with-intact-thesis | declined | **true** |
| D:UBER:2026-07-09 | −2.9059% | none | **declined_hard_gate** | false |
| D:GEV:2026-08-03 | −1.9451% | dip-with-intact-thesis | declined | **true** |
| D:DIS:2026-08-05 | +0.3802% | none | declined | **true** |
| D:GOOGL:2026-07-26 | +0.8561% | none | declined | **true** |
| D:ISRG:2026-07-20 | +1.0670% | none | **declined_hard_gate** | false |
| D:TSM:2026-07-21 | +1.7526% | none | declined | false |
| D:AMZN:2026-07-09 | +4.6243% | none | declined | false |
| D:TSM:2026-07-29 | +10.8116% | none | declined | **true** |
| D:RTX:2026-04-27 | +11.6740% | none | **declined_hard_gate** | false |

**The HARD GATE, and why the field agrees with it.** `invalidation_criteria_evaluable` is FALSE for **seven** tranches, every one via the third disjunct — `$.breach_status = 'NOT_ASSESSED_BY_THIS_BACKFILL'`. Not one of the twelve carries a `$.status` key at all, so the older two-disjunct rule would have returned TRUE for all twelve, *including the three this sweep declines*. The third disjunct is the entire reason the field and the gate agree today rather than contradicting each other.

Four of those seven are covered at **name** level by a sibling tranche carrying a fresh affirmative assessment — AMZN (07-30), DIS (08-05), GOOGL (07-26), TSM (07-29). **Three are covered nowhere: ISRG, RTX and UBER**, each a single tranche with no sibling to borrow from. They are structurally ineligible for an add regardless of merit, and this repeats until something writes a real assessment for them. **UBER is where that costs something today** — it is the only one of the three with an actual dip (−2.9059% below cost), so the gate declined the one position that would otherwise have been evaluated on its merits.

**Why the four genuine dips were all declined.** Today's drawdown was macro, not idiosyncratic: nine of eleven sectors lower, IWM −1.3676% against SPY −0.4648%, one identified driver. **Not one name-specific fact arrived for AMZN, DIS, GEV or GOOGL**, and every criterion their theses turn on is a quarterly fundamental that cannot move on a session — so there is no strengthened-conviction limb, and the dip limb is being asked to carry the whole case on price alone. **GOOGL is the one examined hardest and it argues the other way on inspection:** at −2.2786% against XLC −0.6187% the underperformance is genuinely idiosyncratic rather than beta, but **no catalyst was found for it**, and an unexplained relative decline is a reason to establish why before adding, not a reason to add. **GEV** moved the wrong way for its own story and is unexplained on the same terms. Finally, the portfolio context cuts against adding rather than for it: the park is deliberately holding a defensive sleeve at f=25 on three standing defensive axes with breadth in a third consecutive decline, and adding single-name equity risk on that same session would need a name-level case strong enough to override it. None of the four has one.

---

## ANALYSIS — REGIME CHECK

**No inter-monthly router review recommended.** High bar, default-NO on ambiguity, and nothing today clears it.

The day's developments deepened conditions the current router state already reflects rather than creating new ones. `shock_overlay` has read **acute** since 2026-09-01 — that is the input that flipped E from ACTIVATE to DO-NOT-ACTIVATE on 2026-09-03, and a further oil escalation reinforces the existing call rather than shifting it. C is already HYBRID ACTIVATE for exactly the FOMC that is drawing attention. A, B and D are DO-NOT-ACTIVATE and nothing today argues for activation.

**Two items recorded as observations, deliberately not as classifications:**

1. **Breadth at 56.85 is approaching territory where D2a's `EQUITY_BREADTH` HEALTHY/WEAK call could flip.** It read HEALTHY at 60.63 (09-08), 64.01 (09-04) and 66.40 (09-03). **The threshold decision is D2a's and this file does not apply it** — the vocabulary's "no AI classification" rule binds precisely there. D1's job was to fetch and pin the number, which it did; flagged so a flip on tonight's D2a run is expected rather than surprising.
2. **VIX_REGIME** last read NORMAL at 15.72 and today's 16.46 stays comfortably inside that band. No flip expected.

---

## EQUITY-BREADTH OBSERVATION

**Written: `events.regime_events`, `as_of_date = 2026-09-09`, `scope = 'TECHNICAL_INPUT'`, `key = 'EQUITY_BREADTH_PCT'`, `numeric_value = 56.85`, `value = 'Barchart $S5TH'`.**

**Source-dated, not inferred.** Barchart's page header states its own session verbatim — *"Quote Overview for Wed, Sep 9th, 2026"* — so the `date_attribution=inferred_post_close` fallback was not used and is not claimed. Published figure as received: `56.85-3.78(-6.23%)18:01 ET[INDEX]`. Session range open 58.25, low 56.26, high 58.84.

**Both settlement checks passed.** The unsettled tell is `Low == Close` plus an on-page stamp before 16:00 ET; here Low 56.26 ≠ Close 56.85 and the stamp is 18:01 ET. Barchart's Previous Close reads **60.63**, an exact match to this system's recorded 2026-09-08 value — a stronger self-check than the ~0.05pp agreement the 2026-08-25 note describes as ordinary noise.

**SINGLE USABLE SOURCE — disclosed, as the standing obligation requires and as Barchart's promotion to declared primary does not relieve.** EODData returned 57.45 but carried an on-page timestamp of *"09 Sep 26 15:58"*, before the close — the exact near-close unsettled value the 2026-08-18 finding documents — and was **rejected**, deliberately not counted as corroboration. StockCharts `$SPXA200R` returned a JS shell with no extractable data; Investing.com returned HTTP 404. A first rendering `web_fetch` of Barchart returned an empty shell; per the "an undated payload condemns THAT FETCH, not the SOURCE" rule the URL was re-tried on the other path (cache-busted `tavily_extract`, advanced depth), which succeeded — **the extract path produced the figure kept.**

**MacroMicro was deliberately NOT probed.** Under the 2026-09-06 W5 ruling it is a weekly re-probe riding on the **Sunday-anchored** week, i.e. the Sunday D1 fire; 2026-09-09 is a Wednesday, so no probe was due and none was spent.

---

## PARK ALLOCATION CALL

- **`vehicle`** — **VOO** (the majority sleeve; f=25 < 50 → the risk sleeve). **`target_f_pct` 25**, `risk_sleeve` VOO, `defensive_sleeve` SGOV. Direction: **KEEP**. Status: **BOUND**.
- **`conviction`** — **MEDIUM**, `conviction_pct` **50**.
- **`rationale`** — Three of six axes stand defensive (volatility: VIX 16.46 > the 15.00 bar and > its own 20d SMA 15.1715; breadth: 56.85 < 66; shock: `shock_overlay` acute and Brent 101.21 > 95), and **all three deepened today — but ZERO entered.** Every one of those moves deepened an axis that was already standing, and a standing state is never news. The increase gate is open only on volatility's 2026-09-08 entry, still inside its 2-session window. Raw cap and decay-confirmed cap agree at **75**; 0.50 × 75 = **37.5**, exactly equidistant between the 25 and 50 steps, so **the tie rounds DOWN to 25** — the ladder returns the position the book already holds, unaided, with **zero deviation steps taken**. The runner-up is f=50 and it loses on two measured disconfirmations. **Credit moved AWAY from stress**: HYG/IEF closed **+27.03bp above** its 20d SMA against a bar asking 50bp *below*, and it was +17.34bp yesterday — high yield firmed on a supposedly risk-off day, and credit is where a systemic event would show first. **The index never approached its trigger**: SPY 762.40 sits ABOVE its 50dma of 758.0246 and only −1.9900% from its 252-day high. The sector composition agrees — staples underperforming the index while energy leads, and energy equities taking only +0.83% of a +3.36% crude move, both say input-cost repricing rather than demand shock. Against that, this allocator is **0 for 2** on defensive excursions (−2.841pp, −1.019pp), the historical signal's mean forward edge is **−0.638pp** over 15 episodes winning 4 of 15, and the forward test stands at **episode 1 of 3**. Going deeper on deepening-but-not-entering evidence, with credit and index both dissenting, is precisely the trade that record punishes. Holding at 25 keeps a real defensive position sized to genuinely deteriorating internals without paying for conviction the disconfirming axes do not support.
- **`invalidation`** — **Symmetric and disjunctive, at the same bar in both directions.** **BACK TO f=0** on EITHER, one alone sufficing: volatility exits defensive (VIX below 15.00, **OR** below its own 20d SMA, currently 15.1715) — a single close does it, exactly as cheaply as a single close carried it in; **OR** breadth prints 66 or above. **DEEPER, to the 50 step**, if a THIRD axis ENTERS: index (SPY below its 50dma 758.02, or below roughly 754.55 = 3% under the 777.88 252-day high); **OR** credit (HYG/IEF at or below 0.852899, its SMA minus 50bp); **OR** rates on a genuine break (30Y sustained above 5.40, or a September hike priced above 85%). Volatility, breadth and shock **cannot** supply the third — all three already stand, so further deterioration in any of them deepens without creating an event. **Independently, the crisis override carries alone and same-day:** a single-session index move ≤ −2.5%, or VIX ≥ 28, lifts the cap to 100.
- **`theater_check`** — The rationale names the two facts that argue *against* the call it makes — credit moving further from stress, and the index never approaching its trigger — and lets them decide. The ladder arithmetic was computed before the conclusion was written and returned 25 unaided; no deviation was taken to reach a preferred number.

**Axis vintage — unusually clean this session.** `state.park_axis_daily` carries `axes_measured_today = 0` and all five testable axes at `measured_on = 2026-09-08`, the normal structural lag (D2a writes `events.signal_marks` at 22:40 UTC, after this run). **That did not constrain the call, because all six axes were independently re-measured this session** — volatility, index and credit from IBKR bars, breadth from the row this run wrote itself, shock from FMP BZUSD plus press corroboration, rates from date-pinned FMP treasury rates. **All six fresh readings CONFIRM the carried view; not one contradicts it.** `park_watch = true`, `watch_axis = volatility`, recorded on the mechanical `firing_count = 1` — stated precisely so it is not misread: **no axis entered defensive today.**

**One evidence-provenance correction, recorded rather than buried.** Yesterday's park record cites Brent 2026-09-08 at **99.39** from the FMP BZUSD series; that same series, re-read today, returns **97.92** for 2026-09-08 — and 97.92 for 2026-09-07 as well, to the cent, the signature of a carried-forward vendor row. The current series is the one that reconciles: 101.21/97.92 − 1 = **+3.36%**, matching AP's independently reported "Brent jumped 3.4%". Today's figure is used, with the revision disclosed. **The axis call is robust either way** — 97.92, 99.39 and 101.21 all clear the 95 threshold decisively — so nothing here turns on it. Raised as an `ops.alerts` info row against the owning surface (D2a STEP 1d, which writes `events.signal_marks` from this series), referencing the open D2a `signal_mark_captured_pre_close` finding of the same class. Note that today's own Brent read, taken ~22:25 UTC, is itself a pre-settlement read of the same kind and is stated as such.

**Known cosmetic defect in the logged row, disclosed rather than silently left:** in the park record's `fields.readings`, the XLRE reading (−1.1162, IBKR RTH close-to-close, as-of 2026-09-09) landed under a malformed key name rather than `xlre_move_pct`. The value, source and as-of date are all correct and the source string names XLRE explicitly, so the readings-provenance obligation is substantively met; it was not superseded because an append-only complete replacement of a ~20KB row to fix a key name is disproportionate to the defect.

---

## RECOMMENDED ACTIONS

**Exits triggered: none.** No mechanical trigger exists to fire (all twelve tranches carry NULL `convergence_target` and NULL `time_exit_date`), and no Development breaches any thesis-invalidation criterion on any of the twelve.

**Add candidates: none.** Twelve tranches evaluated, zero flagged, three declined at the HARD GATE.

**Router reviews recommended: none.**

**Watchlist updates:** the eight Strategy-B names below enter the *Strategy B new-entry candidates* queue as part of those same eight bullets — they are **not** separate actions. **No other watchlist adds, removes or demotions.**

**New entry candidates requiring full thesis construction in separate sessions — nine bullets, matching the nine entries in the block below:**

- **TTAN — Strategy B.** Post-event mispricing candidate: −29.9828% close-to-close on 2026-09-09 after a Q2 beat on both revenue and EPS, with only a slightly light next-quarter revenue guide. Clears B Entry criterion 1 (≥5%).
- **CASY — Strategy B.** Post-event mispricing candidate: −14.2415% after beating on revenue, EPS and EBITDA and missing only on inside same-store comps (+3.2%). Clears B Entry criterion 1.
- **BRZE — Strategy B.** Post-event candidate: −21.7090% on a revenue beat (+26.2% YoY) accompanied by genuinely deteriorating unit economics — thesis construction must test whether the repricing is warranted. Clears B Entry criterion 1.
- **TBBK — Strategy B.** Post-event candidate: −22.3264% on the loss of a named BaaS client (Chime acquiring Stride Bank, $590M) — a structural event, so the move may be correct. Market cap $2.083B is only ~4% above the $2B rail; second-source the cap before sizing. Clears B Entry criterion 1.
- **SIG — Strategy B.** Post-event candidate: +23.9624% on a Q2 EPS beat ($2.19 vs ~$1.72) and raised FY guidance. **Upside overreaction, so a fade is short-direction** — surfaced for D2 to decide, not pre-empted here. Clears B Entry criterion 1.
- **ASO — Strategy B.** Post-event candidate: +14.4045% on a Q2 beat and raised FY guidance. **Upside overreaction, short-direction**, same caveat as SIG. Clears B Entry criterion 1.
- **CMCSA — Strategy B.** Post-event candidate: −6.6084% on CFO guidance at the Goldman Communacopia conference that Q3 broadband subscriber losses will not improve YoY; complex-wide, with Charter down roughly 7% on the same remarks. Clears B Entry criterion 1.
- **META — Strategy B.** Post-event candidate: +6.5544% on the launch of Muse, a paid personal AI agent. Already on the A queue (2026-07-05) and the B watch overflow (2026-07-12); this is the first session it clears B Entry criterion 1 on its own event. **Upside move, short-direction fade** — same caveat as SIG and ASO.
- **FOMC 2026-09-16 — Strategy C.** Defined-risk structure around the 15–16 September FOMC, C's designated activation event and the sole capital-enabled strategy. Hike odds repriced from ~44% a month ago to ~58–60%, with CPI on 2026-09-11 the stated swing factor; the Reuters consensus for a hold fell from 90% to 70% in a month. Underlying is left to thesis construction, which must also assess entry criterion 2 — noting the open W5 finding that criterion 2 has failed on five consecutive drains.

```yaml d1_actions
- action: thesis
  ticker: TTAN
  strategy: B
  qualifying_event_date: 2026-09-09
  source_research_screen_id: acc31c4a-2889-4583-a76a-0177ecd34dcf
  detail: Q2 beat on revenue and EPS, -29.9828% on a slightly light next-quarter revenue guide; clears B Entry criterion 1 (>=5% close-to-close, IBKR RTH bars)
- action: thesis
  ticker: CASY
  strategy: B
  qualifying_event_date: 2026-09-09
  source_research_screen_id: acc31c4a-2889-4583-a76a-0177ecd34dcf
  detail: Q1 beat on revenue/EPS/EBITDA, -14.2415% on an inside same-store comp miss (+3.2%); clears B Entry criterion 1
- action: thesis
  ticker: BRZE
  strategy: B
  qualifying_event_date: 2026-09-09
  source_research_screen_id: acc31c4a-2889-4583-a76a-0177ecd34dcf
  detail: Q2 revenue beat +26.2% YoY with FCF margin 12.7% -> 9.6% and weak Q3 EPS guide, -21.7090%; clears B Entry criterion 1; repricing may be warranted
- action: thesis
  ticker: TBBK
  strategy: B
  qualifying_event_date: 2026-09-09
  source_research_screen_id: acc31c4a-2889-4583-a76a-0177ecd34dcf
  detail: -22.3264% on Chime acquiring BaaS rival Stride Bank ($590M), a named client loss; clears B Entry criterion 1; market cap $2.083B only ~4% above the $2B rail, second-source before sizing
- action: thesis
  ticker: SIG
  strategy: B
  qualifying_event_date: 2026-09-09
  source_research_screen_id: acc31c4a-2889-4583-a76a-0177ecd34dcf
  detail: +23.9624% on Q2 EPS $2.19 vs ~$1.72 and raised FY guide; clears B Entry criterion 1; upside overreaction so a fade is short-direction, left to D2
- action: thesis
  ticker: ASO
  strategy: B
  qualifying_event_date: 2026-09-09
  source_research_screen_id: acc31c4a-2889-4583-a76a-0177ecd34dcf
  detail: +14.4045% on a Q2 beat and raised FY guide; clears B Entry criterion 1; upside overreaction, short-direction, same caveat as SIG
- action: thesis
  ticker: CMCSA
  strategy: B
  qualifying_event_date: 2026-09-09
  source_research_screen_id: acc31c4a-2889-4583-a76a-0177ecd34dcf
  detail: -6.6084% on CFO guidance at Goldman Communacopia that Q3 broadband sub losses will not improve YoY; complex-wide with Charter ~-7%; clears B Entry criterion 1
- action: thesis
  ticker: META
  strategy: B
  qualifying_event_date: 2026-09-09
  source_research_screen_id: acc31c4a-2889-4583-a76a-0177ecd34dcf
  detail: +6.5544% on the launch of Muse, a paid personal AI agent; first session it clears B Entry criterion 1 on its own event; upside move so a fade is short-direction
- action: thesis
  ticker: n/a
  strategy: C
  qualifying_event_date: 2026-09-16
  source_research_screen_id: n/a
  detail: Defined-risk structure around the 2026-09-16 FOMC, C's designated activation event and the sole capital-enabled strategy; hike odds repriced ~44% to ~58-60% with CPI 2026-09-11 the swing factor; underlying and entry criterion 2 both left to thesis construction
```

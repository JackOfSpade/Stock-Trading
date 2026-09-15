2026-09-15
<!-- d1_scan_through_utc: 2026-09-15T22:15:00Z -->

# Daily Market Development Scan — 2026-09-15 (Tue, MT)

**Scan window: 2026-09-14 16:30 MT → 2026-09-15 16:10 MT** (23.7h — cadence-normal, no gap to state). Resolved from the prior `Daily.md`'s `<!-- d1_scan_through_utc: 2026-09-14T22:30:34Z -->` marker, cross-checked against that file's own commit at `2026-09-14T22:36:38Z` — the two agree to within six minutes. `state.routine_catchup_window` independently gives `window_days = 0.98`, so no `CATCHUP` token is owed. The git history is **not** shallow (1,453 commits), so the git leg of the window resolution is sound rather than merely silent. **ONE completed US trading session inside this window: Tuesday 2026-09-15.** `state.trading_day_today` gives `is_trading_day = true`, `last_trading_day = 2026-09-15`, `next_trading_day = 2026-09-16`. Every close-to-close figure in this file is measured **2026-09-14 → 2026-09-15**.

**Tape — a small index move sitting on top of a large repricing, and the gap between the two is the whole story.** SPY 760.88 → 757.39 (**−0.4587%**), VOO 699.30 → 696.20 (−0.4433%), QQQ −0.6543%, DIA −0.6216%, IWM **−0.9621%**, SGOV 100.53 flat. VIX 17.10 → **17.20** (+0.5848% — essentially unchanged). Brent (BZX6 front month) 105.68 → **108.75** (**+2.9050%**), USO **+3.3198%**. GLD +0.3334%, TLT −0.2718%, UUP +0.1775%, HYG −0.1910%, LQD −0.0192%, BITO −3.5815%. Equity breadth ($S5TH) 56.26 → **52.88**, a **−3.38pp** single-session fall. **Two of eleven GICS sectors higher**, cross-sector spread **3.9152pp** (XLE +2.1695% to XLY −1.7457%) against 4.0000pp yesterday — a second consecutive session of near-4pp dispersion under an index that moved less than half a percent.

All equity/ETF figures are IBKR regular-session daily bars (`get_price_history`, `step='ONE_DAY'`, `outside_rth=false`), every bar verified carrying a 2026-09-15 stamp of `13:30:00Z`. **Three documented exceptions, stated rather than hidden:** the ^VIX bar (contract 13455763, `IND`/CBOE) stamps `07:15:00Z` and carries `delayed:900` — an index-feed property, not an equity RTH bar; the Brent bar is a NYMEX future (BZX6, contract 339981284, `contract_month` 202611, last trading date 2026-09-30) carrying `delayed:600`; and the SGOV bar carries `delayed:900`.

**This run is NOT degraded, and that is measured rather than claimed.** 23 distinct single names and 24 index/ETF/future instruments were put to IBKR for confirmation; **all 47 returned a genuine 2026-09-15 regular-session bar. Zero symbol-level denials. Zero measurement failures.** Every `surfaced_count` in this file is an affirmatively established figure, never a reported zero standing in for an unmeasured population. Two names discovered on the FMP tape (SWMR, SPCX) could not be resolved by IBKR `search_contracts` at all and are named individually below rather than silently dropped.

**One data-integrity correction, made before anything was written.** A sub-agent pulling the sector series transposed XLU's price levels into the XLC row and then printed a self-contradicting retraction of its own correction. Both contracts were re-pulled directly by this session: XLC (322317077) 115.07 → 114.03 = −0.9038%; XLU (4215235) 41.82 → 41.32 = −1.1956%. The transposition affected only the displayed levels — both percentages were arithmetically correct — but the corrected levels are what is recorded, and the cross-sector spread and sector counts were recomputed against them rather than carried.

---

## TL;DR

- **Exits triggered: none.** No convergence target, no time exit, and no thesis-invalidation criterion met on any of the 12 open tranches.
- **New entry candidates: none routable.** A, B, D and E are all `DO-NOT-ACTIVATE`; C is `HYBRID ACTIVATE (FOMC-only)` and its lane is correctly queued at `thesis-FOMC-C-20261020` — tomorrow's FOMC was already drained NO-GO on 09-08 and re-confirmed 09-09.
- **Add candidates: none** (12 evaluated, 0 flagged, 3 declined at the HARD GATE — ISRG, RTX, UBER). GEV is the strongest case on the book and is declined only because D is capital-disabled.
- **Watchlist changes: none.** One live note: the A-queue XOM thesis (crude up, energy equities not following) began closing today, with no disposition change while A is DNA.
- **Regime review: no review.** Tomorrow's FOMC (~85–90% priced for the first hike since 2023) is the event that could warrant one; it has not resolved. SPY_TREND flips UP → NEUTRAL on today's close, one step from the DOWN that would close Strategy C.
- **Park: KEEP at f=50** (VOO 50% / SGOV 50%), MEDIUM 55, BOUND. **The increase gate OPENED today** — the index axis entered defensive — and the ladder still sizes to 50.

---

## DEVELOPMENTS

### 1. Market-wide breaking events

**Saudi East-West pipeline struck and shut; Brent through $108 and the 10Y through 5%.** Drones launched from Iraq struck Saudi Arabia's East-West pipeline — the strategic bypass around the Strait of Hormuz — forcing its shutdown, with industry estimates cited by Reuters putting as much as **4% of global oil supply** at risk. Yemen's Houthis launched a fresh attack on Saudi Arabia on Monday and reportedly advanced toward Perim Island near Bab el-Mandeb; a commercial vessel was attacked in the Strait of Hormuz; planned Gulf–Iran talks in Oman were abruptly postponed. Sources: Reuters (`reuters.com/world/asia-pacific/global-markets-global-markets-2026-09-15`), CNBC (`cnbc.com/2026/09/13/stock-futures-today-live-updates.html`).

*Observable reaction.* Brent front-month **105.68 → 108.75 (+2.9050%)** and USO **+3.3198%**, both IBKR-measured. **XLE +2.1695% was the only meaningful sector gainer of eleven.** The US 10-year touched **5.041% intraday**, reported as its highest since 2007; Germany's 10-year above 3.51%, Japan's 10-year back to 3% ahead of an expected BOJ hike Friday. Equities fell modestly (SPY −0.4587%). **Gold did not behave as a haven** — GLD only +0.3334% against a firmer dollar (UUP +0.1775%) — which is itself the tell that this is being priced as an inflation-and-rates event rather than a risk event.

**AI "pace the frontier" repricing entered its second session.** Anthropic's Dario Amodei published a 3,800-word essay arguing frontier labs must deliberately slow capability gains; OpenAI's Altman, Musk and DeepMind's Hassabis publicly backed it, and Altman said OpenAI would delay its IPO. The first-day reaction (Nvidia −3.4%, Broadcom −4.8%, SOX −5.9%) landed on **Monday 09-14, inside the PRIOR scan window**, and is not re-counted here. What falls in *this* window is the follow-through: AMZN −2.0194%, GOOGL −1.2622%, TSM −1.0191%, QQQ −0.6543%. Sources: Reuters (`reuters.com/business/what-amodei-altman-musk-have-said-about-ai-risks-stoking-doom-fears-2026-09-14`), AP, NYT.

This matters to the open book specifically, and is carried into the position analysis below rather than left as colour: **it is the first development in the life of either the AMZN or the TSM position that points directly at that position's own named invalidation mechanism.**

### 2. Scheduled events that resolved today

**EVENT-IDENTITY GATE applied to every item in this section.** Two calendar listings were rejected on primary-source verification rather than recorded.

**Empire State Manufacturing Index (September 2026) — RESOLVED.** Released by the NY Fed **Tuesday 2026-09-15, 08:30 ET**, reference period September 2026. Headline **7.6**, down from August's four-year high of **20.6**, missing consensus ~14.8–15. The sub-indices are worse than the headline: **new orders 17.3 → 2.0**, **shipments 11.7 → −3.2**, **prices paid up to 63.1**, employment 10.6, average workweek 17.0 near a five-year high. Source: NY Fed via WSJ/Dow Jones (`morningstar.com/news/dow-jones/202609153364/new-york-manufacturing-activity-decelerated-in-september`). Market reaction muted; attention was on tomorrow's Fed decision.

**Forgent Power Solutions (NYSE: FPS) — RESOLVED.** Reported **before market open 2026-09-15** for **fiscal Q4 and full-year 2026**: EPS $0.25 vs $0.24 consensus; revenue $461.7M vs $434.2M consensus. Market cap ≈$8–9.5B. Source: Business Wire release, "Forgent Reports Record Fourth Quarter and Full Year 2026 Results."

**FOMC — PENDING, has NOT resolved.** The meeting runs 09-15/09-16 with the decision, SEP and Chair Warsh's press conference all scheduled for **Wednesday 2026-09-16, 14:00/14:30 ET** — outside this window. A Reuters poll of 101 economists published 09-14 found **86 of 101 (85%) now expect a 25bp hike to 3.75–4.00%**, the first hike since July 2023 and a sharp reversal from the prior week's hold majority, driven by the 09-11 August CPI (+3.4% y/y headline, core +0.3% m/m — released outside this window). Cited pricing runs ~85–90%. **No outcome figures are recorded and no event-dependent criterion is assessed against it.** Source: Reuters (`reuters.com/business/fed-rate-hike-wednesday-now-likely-say-economists-least-one-more-follow-2026-09-14`).

**Import/Export Price Index (August 2026) — PENDING, rejected as a resolved event.** Secondary calendar aggregators listed it for 09-15; the BLS's own release schedule (`bls.gov/schedule/news_release/ximpim.htm`) confirms **Wednesday 2026-09-16, 08:30 ET**. Recorded as pending rather than relabelled.

**General Mills (GIS) — rejected, did not report today.** One earnings aggregator listed GIS as reporting BMO 09-15 at a $20.7B cap, which would have qualified. General Mills' own IR page confirms the Q1 FY2027 report date is **2026-09-23**. Excluded per the event-identity gate rather than relabelled.

**Below the $2B rail, recorded for completeness:** Dave & Buster's (PLAY) reported Q2 FY2026 after Monday's close (revenue miss, $12.5M net loss, stock −19.0083% today) but carries a ~$239M market cap; High Tide (HITI) reported Q3 FY2026 Monday after close at a ~$220M cap. Neither meets the population rail.

### 3. Large single-name moves — AI-SIGNIFICANCE SCREEN

Layer-1 rail: US-listed, market cap ≥ $2B, close-to-close ≥ 2% on 2026-09-15, attributable to an identifiable public event. **`universe_measured` = 23** distinct names confirmed via IBKR (15 from the discovery sweep, 8 from the open Strategy-D book swept independently). **`rail_tally` = 13. `surfaced_count` = 13 = `ARRAY_LENGTH(passed)`** — the two coincide this run because Layer-2 declined none of the names clearing the mechanical rail, which is an outcome and not a conflation of the two quantities.

Discovery legs: FMP `most-active`, `biggest-gainers` and `biggest-losers` all returned 50 rows; FMP `news` `general-news` and FMP `company` `market-cap` returned ACCESS DENIED — **both are STANDING tier facts already in the FMP TIER MATRIX and are deliberately not re-alerted**; `profile-symbol` returned a `marketCap` for every symbol tried, as the recorded escalation path prescribes.

| Ticker | Move | Conviction | Driver | ≥5% |
|---|---|---|---|---|
| SWKS | **+13.5503%** | 75 | CEO told an investor conference the $22B Qorvo merger has cleared all but two jurisdictions — a deal-completion-probability repricing in a name whose whole equity story is that deal | ✓ |
| ENVA | **−23.4254%** | 75 | Withdrew regulatory applications for the Grasshopper Bancorp acquisition, abandoning the bank-charter strategy while reaffirming guidance — a structural reversal, not an earnings miss | ✓ |
| ALHC | **−19.8609%** | 75 | At the Baird healthcare conference management flagged rising medical-cost headwinds and **declined to discuss 2027 Star ratings**; for a Medicare Advantage insurer the refusal is itself the information | ✓ |
| RIG | +8.9908% | 60 | ~$300M two-year ultra-deepwater drillship contract with ONGC; discounted because offshore drillers are high-beta to crude and crude rose 2.9% the same session | ✓ |
| BMNR | −8.3851% | 45 | Crypto-treasury mark-to-market as ETH fell on the stalled CLARITY Act counteroffer; informative about ETH and nothing else | ✓ |
| OPEN | −5.0179% | 60 | 10Y topping 5% drove a broad iBuyer selloff; OPEN is the purest rate-duration equity in the set and moved most of its peer group | ✓ |
| GRAB | −3.6424% | 60 | Announced a $1.49B purchase of 60% of Atome plus ~$900M of buyback completion **and fell** — the market rejecting the capital allocation | |
| SOFI | −3.2860% | 45 | 10Y near a 19-year high into the FOMC; clean rate transmission into fintech lending, idiosyncratically empty | |
| PATH | −2.9332% | 30 | Continued post-earnings drift from the Sept 9 print inside a broader tech pullback; no new catalyst in the window | |
| F | −2.5974% | 30 | Rate-sensitive autos on the same yield surge; no Ford-specific catalyst found, so scored and recorded as tape | |
| AAL | −2.5191% | 45 | Brent above $108 is a direct fuel-cost hit — the oil shock arriving in an earnings channel rather than in a commodity quote | |
| MARA | −2.2609% | 45 | Bitcoin toward ~$76–77K as the CLARITY Act stalled ahead of its vote | |
| AMZN | −2.0194% | 45 | Second-day AI-capex repricing plus the 10Y through 5%; bears on this position's own invalidation_4 without breaching it | |

**AMZN was added by this session, not by the discovery sweep, and the gap is worth recording.** AMZN closed 253.54 → 248.42 = −2.0194%, and FMP `profile-symbol` independently returned `changePercentage −2.01941` against the same 248.42 close — an exact cross-confirmation. Neither the percent-ranked nor the volume-ranked FMP list surfaced it, because a 2% move in a $2.67T name is neither a top-50 percent mover nor a top-50 volume name. It was caught only because the open-book sweep measures every held name every session. That is a structural blind spot in the discovery leg for exactly the mega-cap moves this screen most wants; it is recorded rather than alerted because the compensating control already exists and worked.

**Discovered and NOT surfaced — each named individually rather than dropped.** Failing the POPULATION rail, not Layer-2 judgment: **PLAY** −19.0083% (IBKR-confirmed, $239M cap), **FTRE** +13.3257% (IBKR-confirmed; FMP cap $1.876B sat within 30% of the rail so it was second-sourced across five independent sites at ~$1.55–1.75B — below rail), **BBNX** +14.9432% (IBKR-confirmed, $865M cap). **UNCONFIRMABLE:** **SWMR** (−28.3582% on FMP only; IBKR `search_contracts` returned zero results — a March-2026 IPO absent from the instrument database) and **SPCX** (−3.1455% on FMP only; zero IBKR results, apparently a synthetic pre-IPO tracker rather than listed common stock). A further tail of FMP gainers/losers rows — penny stocks, SPACs and leveraged single-stock ETPs on COIN/CRCL/XRP/BMNR — was screened out at discovery on share-price and float grounds without individual verification. **That population is not zero; it is unmeasured by design, and is stated as unmeasured.**

`entry_type='research-screen'`, `screen='single-name-move'` logged with `agreement` = `{both: 6, ai_only: 7, rule_only: 0}`. Verified after write against `state.research_screen_calls`: all 13 item rows carry a populated `name`, `metric_pct` and `conviction_pct`, and the three `agreement_*` columns read 6/7/0 — the `screen_fields_schema_drift` failure mode is closed for this run.

### 4. Sector-level moves — AI-SIGNIFICANCE SCREEN

All eleven SPDR sector ETFs measured; `universe_measured` = 11, `rail_tally` = 3, `surfaced_count` = 3.

| Sector | Move | Conviction | Judgment |
|---|---|---|---|
| **XLE** | **+2.1695%** | 75 | The only meaningful gainer, on a *physical* event — the Hormuz bypass pipeline struck and shut, up to 4% of global supply at risk — corroborated independently by Brent +2.9050% and USO +3.3198%. The acute shock overlay transmitting in real time, not a standing state re-narrated. |
| **XLY** | **−1.7457%** | 60 | Worst sector. Discretionary leading down with the 10Y near 5% and crude up 2.9% is the stagflationary squeeze in its most direct equity form — and it landed the same morning Empire State new orders collapsed 17.3 → 2.0 against prices paid of 63.1. Two independent instruments on the same channel is why it clears Layer-2 despite missing the retired 2% bar. |
| **XLU** | −1.1956% | 45 | A bond-proxy duration move carrying no sector-specific information, scored lowest for that reason. It earns its place as a *discriminator*: utilities and discretionary falling together while energy **rises** isolates rates-plus-oil and rules out generalised risk-off. |

Full measured set: XLE +2.1695, XLB +0.4753, XLV −0.0537, XLRE −0.1160, XLK −0.2930, XLF −0.3156, XLI −0.6356, XLP −0.8173, XLC −0.9038, XLU −1.1956, XLY −1.7457. Cross-sector spread **3.9152pp**, against 4.0000pp (09-14), 1.6285pp (09-11), 2.02pp (09-10). Dispersion is carried by the three named sectors and was not surfaced as a separate dispersion-only item, so no `legacy_rule_pass=false`-by-convention row is owed.

`entry_type='research-screen'`, `screen='sector-move'` logged with `agreement` = `{both: 1, ai_only: 2, rule_only: 0}`.

### 5. Notable commentary

- **Wall Street flipped to expecting a hike.** Reuters' post-CPI poll of 101 economists (09-14): 85% now expect 25bp Wednesday, a dramatic reversal from the prior week. BofA's Stephen Juneau said Warsh "boxed himself in"; BMO's Scott Anderson said the Fed's "inflation-fighting credentials are on the line."
- **UBS forecasts back-to-back hikes** in September *and* December (Pingle, Watt), framing Jackson Hole as having "thrown down the gauntlet" on inflation credibility.
- **Loretta Mester (CNBC, 09-15):** "no convincing evidence inflation is on a downward path back to 2%."
- **Goldman's George Cole** ("Why Global Bond Yields Are Surging," recorded 09-14) attributed the yield surge primarily to energy prices tied to the Iran conflict, and warned European and UK central banks are "running out of patience" treating the energy shock as transitory.
- **NEC Director Kevin Hassett (CNBC, 09-15):** the administration "wholeheartedly rejects" a government takeover of AI regulation — push-back on the pacing debate above.

No sell-side rating actions on large-cap names could be confirmed to this window from primary sources; undated aggregator pages were excluded rather than reported as unverified specifics.

---

## ANALYSIS — RISK TO EXISTING POSITIONS

### Mechanical exit-trigger sweep

**Union of `state.current_positions` and live `get_account_positions`.** BigQuery holds **12 open tranches across 8 names, all Strategy D**. The connector holds those same 8 names plus SGOV and VOO, which are the park book and not strategy positions. **No position exists in the connector and not in BigQuery**, so no `position_reconciliation_lag` alert is owed and none was raised.

**All 12 tranches carry `convergence_target = NULL` and `time_exit_date = NULL`**, so neither mechanical exit can fire on any of them. That is a property of Strategy D — no-stop, open-ended, running to thesis-invalidation — not a data gap.

**Dividend netting on a price-level criterion: checked and inapplicable.** `state.price_level_criterion_drift` returns exactly one row across the whole book, `D:DIS:2026-08-05`, and that row carries `is_exit_criterion = false`, `actionable_price_level = false` and `has_dividend_drift = false` — it is the "$45.00 notional" phrase inside the `not_exit_triggering` text, not a price-level exit criterion. No open position tests any criterion against a price level, so the mandatory netting step has nothing to net. Stated affirmatively because silence here is indistinguishable from not having looked.

### Per-strategy kill-trigger sweep

`perf.kill_flags` carries D at `as_of_date` 2026-09-14 and B at 2026-08-18 (B holds no positions, so its series stops). **All flags FALSE on both rows**: `drawdown_kill`, `runaway_review`, `m2m_underperf_review`, `gate_reached`, `interim_underperf_warning`.

**`current_drawdown` refreshed unconditionally against today's marks**, as the rule requires — no judgment predicate. Recomputed from today's IBKR closes across the 8 D names: the D book moved **535.2647 vs 540.0936 = −0.894%** on the session, taking deployed unit value ≈1.042457 against a peak of 1.098110, i.e. a drawdown of **≈−5.07%** (from −4.2117% at yesterday's close). The kill threshold is **−50%**. Nowhere near; **no drawdown kill**. Deployed TWR has not doubled, so **no runaway-success flag**; D has 1 closed trade against a 30-trade gate.

**`interim_underperf_warning`:** D has `deployed_days = 97` (≥90) but `excess_vs_sgov = +3.73%`, far from the −15% beta-adjusted bar, so FALSE. B is at 79 deployed days and does not reach the 90-day precondition. No open alert of this category exists on the board, so **no heal-resolution `UPDATE` is owed**.

**B open-book pairwise correlation:** `analytics.b_pairwise_correlation` returns `n_positions = 0`, so the `n_positions >= 2` guard fails and the check is a no-op. No alert.

### Thesis-invalidation assessment, per position

The Strategy D criteria are, without exception, **fundamental** — segment revenue growth, operating margins, backlog, guidance, regulatory remedies — and are measured at quarterly reports. Today's developments were macro: oil, rates, and a pre-FOMC repricing. **No criterion on any of the 12 tranches is met.** But two deserve more than a line.

**AMZN (−2.0194%) and TSM (−1.0191%) — the first development in either position's life that points at its own named invalidation mechanism.** `D:AMZN` invalidation_4 reads *"Anthropic/OpenAI commits renegotiated down/churned."* `D:TSM` invalidation_3 reads *"structural AI-capex reset (hyperscaler/Nvidia order cuts; CoWoS utilization drop)."* The pacing essay, the public backing from OpenAI/xAI/DeepMind, and OpenAI's IPO delay are an industry-wide argument for slowing frontier capability growth — which is the upstream of both criteria.

**Neither is breached, and the distinction is not a technicality.** Both criteria require a *counterparty action*: commitments actually renegotiated or churned; orders actually cut. Advocacy, and public agreement with advocacy, is neither, and no such action has been reported. **TSM is the more exposed of the two**, because its criterion names the capex channel explicitly while AMZN's names contract commitments one step removed from it. Recorded as a watch item for M3 and the next quarterly re-assessment. **This is not an exit flag and no exit is recommended.**

The remaining positions: **GEV** (+0.9203% today, after −8.62% yesterday) — criterion is total-company organic orders growth, untouched. **DIS** (−1.9984%) — SVOD margin, FY26 EPS guide, buyback pace, segment-reporting form, all untouched; the tranche's own record affirmatively passed criteria 2 and 3 at the Q3 FY26 checkpoint. **GOOGL** (−1.2622%) — Cloud revenue, margin, RPO and the structural-remedy criterion untouched. **RTX** (+0.0819%) — Airbus damages, powder-metal charges, GTF Advantage EIS, backlog, FCF guide, defense procurement, all untouched; worth noting the Middle East escalation is plausibly *supportive* of this thesis. **ISRG** (−0.2064%) and **UBER** (−1.6522%) — procedure growth / placements and gross-bookings / EBITDA-margin criteria respectively, untouched.

### Watchlist candidacy

**No change in disposition to any queued name.** One live note worth carrying: the A-queue **XOM** row added 2026-09-13 rests explicitly on the gap that "Brent rose +11.79% in four sessions while the equities levered to it did not follow — XLE −0.58% on the very session crude rose +6.34%." Today that gap began to close from the equity side: **XLE +2.1695%** on Brent +2.9050%. This strengthens the underlying observation rather than refuting it, and the same reading applies to the **CVX** row on the same seam. **No disposition change** — A remains DO-NOT-ACTIVATE and `capital_disabled`, and the resolution trigger for both rows is unchanged at "next M1/M4 with A router ACTIVATE."

---

## ANALYSIS — OPPORTUNITY CHECK

Reactive-cadence roster set, from `strategy/roster.yaml`: **A, B, C, E** (D carries `review_cadence: long_horizon`). Router state as of `div-*-202608-1`, 2026-09-03: **A DO-NOT-ACTIVATE, B DO-NOT-ACTIVATE, D DO-NOT-ACTIVATE, E DO-NOT-ACTIVATE, C HYBRID ACTIVATE (FOMC-only)**. C is the only capital-enabled strategy.

**No new entry candidate is routable, and the reasons are specific rather than blanket.**

**Strategy B.** Six names cleared B's frozen Entry criterion 1 (≥5% close-to-close on event day) on IBKR-measured closes: SWKS +13.5503%, ENVA −23.4254%, ALHC −19.8609%, RIG +8.9908%, BMNR −8.3851%, OPEN −5.0179%. On the merits ENVA and ALHC are the two most interesting — both are discrete, dateable, company-specific repricings of the kind B exists to exploit. **B is `DO-NOT-ACTIVATE` and `capital_disabled`** (the universal `shock_overlay=acute` override fired for a second consecutive month), so none is routed to thesis construction. They are recorded here and in the `research-screen` row as evidence, not as handoffs. The seven sub-5% names are `below_spec_floor` and are **context and SL1 ideation evidence only — never routed as B candidates** regardless of router state.

**Strategy C.** The only router-permitted lane, and it is correctly and deliberately already handled. Tomorrow's **2026-09-16 FOMC** is represented by a **terminal** queue row — `thesis-FOMC-C-20260908`, drained NO-GO by D2 on 09-08 and re-confirmed 09-09 (hike near 56% and genuinely two-sided; the decisive August CPI unreleased; SPY IV/HV at 1.235–1.363 arguing for selling vol while every affordable structure was a long-premium debit spread). The next event, the **2026-10-28 FOMC**, is queued open at `thesis-FOMC-C-20261020`. **No gap exists and nothing is owed here.** Subsequent evidence has hardened rather than weakened that NO-GO: hike odds have gone ~60% → 85–90% and the event is now roughly one-sided, which removes the divergence criterion 2 would need.

**Strategy A.** DNA and `capital_disabled`; the day's energy developments bear on the XOM/CVX queue rows as noted above but create no routable candidate.

**Strategy E.** DNA since 2026-09-04 and holds zero positions. Today's 3.9152pp cross-sector spread is exactly the dispersion E feeds on, and it is the second consecutive near-4pp session — recorded as evidence for the next M2 pair screen, not as a candidate.

---

## ANALYSIS — ADD-CANDIDATE CHECK

Scope is Strategies **A, B and D only**. The open book is 12 tranches, all D. **12 evaluated, 0 flagged, 3 declined at the HARD GATE.**

**Price basis, stated because this is the field that goes wrong quietly.** Every `mark_vs_cost_pct` numerator is today's IBKR regular-session daily-bar close; every denominator is **that tranche's own** `cost_basis / shares` from `state.current_positions` — never the account-level blended `avg_price`, never a snapshot. The connector position endpoint *was* read (it is the other half of the union sweep) and its marks were **not** used for this field: it served AMZN at 248.17 against a true close of 248.42 and GOOGL at 344.1627 against 344.98, exactly the staleness class pinned on 2026-09-07.

| Tranche | Mark vs cost | Disposition | Evaluable |
|---|---|---|---|
| D:AMZN:2026-07-09 | +2.9746% | declined | false |
| D:AMZN:2026-07-30 | −6.5011% | declined | true |
| D:DIS:2026-05-07 | −4.4009% | declined | false |
| D:DIS:2026-08-05 | +2.5385% | declined | true |
| D:GEV:2026-08-03 | **−8.9799%** | declined | true |
| D:GOOGL:2026-07-09 | −4.1318% | declined | false |
| D:GOOGL:2026-07-26 | +5.2270% | declined | true |
| D:ISRG:2026-07-20 | +7.9109% | **declined_hard_gate** | false |
| D:RTX:2026-04-27 | +10.5152% | **declined_hard_gate** | false |
| D:TSM:2026-07-21 | −3.2981% | declined | false |
| D:TSM:2026-07-29 | +5.3114% | declined | true |
| D:UBER:2026-07-09 | −2.4278% | **declined_hard_gate** | false |

**The HARD GATE.** Seven tranches carry `invalidation_status.breach_status = 'NOT_ASSESSED_BY_THIS_BACKFILL'`. Four of those seven — AMZN, DIS, GOOGL, TSM — are covered at NAME level by a later tranche carrying a fresh assessment, so their gate can clear and they are declined on the merits. **Three are covered nowhere in the record — ISRG, RTX and UBER — and are structurally ineligible for an add** because "unbreached" cannot be affirmatively confirmed. RTX is the instructive one: the Middle East escalation is plausibly *favourable* to its thesis, and that is precisely why an unconfirmable gate must still decline — a favourable read is not a substitute for an assessed criterion. This is a standing condition already owned by `ops.alerts` `3daf511e` (`add_gate_uncovered_breach_status`, info, open), which names **M3** as the routine that owns the substantive re-assessment. Nothing new is raised.

**GEV is the strongest add case on the book and it is declined for a reason that is not about GEV.** `D:GEV:2026-08-03` sits −8.9799% below cost after yesterday's 8.62% fall and today's +0.9203%. Its thesis is total-company organic orders growth, entry reading **88%** against a 15%-for-two-consecutive-quarters invalidation floor, and its own entry record names "short-term price action" as explicitly **not** exit-triggering. That is the textbook dip-against-intact-thesis and its `trigger_type` is recorded as such. It is declined because **Strategy D is `DO-NOT-ACTIVATE` and an add is a new tranche, i.e. a new entry** — the same review that set D to DNA said in terms that the open lots run to thesis-invalidation and only *new* entries are blocked. **This is a gated case, not a rejected one**, and it is recorded that way so a later session does not read the decline as a judgment on the merits.

**AMZN and TSM are declined on the merits, and that is the substantive finding of this sweep.** Both are below or near cost and both fell today — superficially the shape of a dip-with-intact-thesis. They are not, because the adverse price action arrived **with** news bearing on their own invalidation criteria, as set out in the risk section above. `trigger_type` is recorded as `none` for both, deliberately.

One `events.decision_log` row (`entry_type='add-candidate-review'`) carries the whole sweep including every decline, per the durable-log requirement.

---

## ANALYSIS — REGIME CHECK

**No inter-monthly router review is recommended.** Default-NO on ambiguity, and the bar is high.

The event that could warrant one — the **FOMC** — has not resolved; it lands tomorrow at 14:00 ET with ~85–90% priced for a 25bp hike. A hike that arrives as priced is not new information about the regime. A hike that arrives with a hawkish SEP, or a *hold* against 85–90% pricing, would be, and tomorrow's D1 will see it.

Two mechanical facts are recorded because the next D2a run will act on them and a reader should not be surprised:

1. **SPY_TREND flips UP → NEUTRAL on today's close.** The vocabulary requires close > 50dma AND 50dma > 200dma for UP; SPY closed **757.39 against a 50dma of 759.0606** (computed in-session from 49 curated closes through 09-14 plus today's close, because D2a has not yet written today's marks), while the 50dma remains well above the 200dma at 714.6947 — so NEUTRAL, not DOWN. **This is one step from the DOWN that would close Strategy C**, the only capital-enabled strategy, since C's router rule requires `SPY Trend != DOWN`. Flagged, not adjudicated: the classification is D2a's.
2. **Equity breadth 52.88 is 2.88pp above the 50 line** at which `EQUITY_BREADTH` flips HEALTHY → WEAK. Today's −3.38pp is the largest single-session decline in the stored series. Threshold application is D2a's.

The five `FUNDAMENTAL_AXIS` scores (decelerating growth, disinflating inflation, hawkish policy, risk-on sentiment, acute shock overlay) are the 2026-09-01 M1a readings and are carried, not re-scored here.

---

## EQUITY-BREADTH OBSERVATION

**Value: 52.88** for the **2026-09-15** session. Written to `events.regime_events` with `scope='TECHNICAL_INPUT'`, `key='EQUITY_BREADTH_PCT'`, `numeric_value=52.88`, `value='Barchart $S5TH'`.

**Two independent sources, agreeing exactly — this run did NOT reach its figure through a single source.** Barchart `$S5TH` (`barchart.com/stocks/quotes/$S5TH?cb=20260915`, the declared primary) published **52.88 −3.38 (−6.01%) at 18:08 ET**, i.e. post-close, under the on-page heading *"Quote Overview for Tue, Sep 15th, 2026"* — a source-stated as-of session, so **`date_attribution` is SOURCED, not `inferred_post_close`**. Its Previous Close read **56.26**, an exact match to the stored 09-14 value, so **no settlement revision is owed**. EODData's dated EOD table row "15 Sep 26" reads Open 51.88 / High 53.47 / Low 51.88 / **Close 52.88**, with its "14 Sep 26" (56.26) and "11 Sep 26" (56.46) rows both reconciling exactly to stored history. Agreement **0.00pp**, far inside the 5pp no-write bar.

**Settlement-lag tell checked and acted on.** EODData's separate top quote-marquee box read LAST **53.28** / PREV 56.26 stamped *"15 Sep 26 15:50"* — a **pre-close** timestamp contradicting the same page's own settled EOD row. **It was not used.** The dated table row is the settled value. Barchart's own Day Low (51.49) does not equal its Close (52.88), so the unsettled-bar tell is absent there too.

**Fetch provenance.** A plain `WebFetch` on the un-busted Barchart URL returned an empty JS shell and is recorded as a failed fetch, not a failed source; the figure came from `tavily_extract` at advanced depth on the cache-busted URL. Per the fetch-method rule, an undated or empty payload condemns *that fetch*, not the source.

**MacroMicro was deliberately not attempted.** Under the 2026-09-06 W5 ruling it is a weekly re-probe riding the **Sunday** D1 fire only, and today is Tuesday. No probe was due and none was spent.

---

## PARK ALLOCATION CALL

- **vehicle:** VOO — the majority sleeve at the f=50 tie, which resolves to the risk sleeve. Not a claim that the book is single-vehicle.
- **target_f_pct:** **50** (risk sleeve VOO 50% / defensive sleeve SGOV 50%). **direction: keep. status: BOUND.**
- **conviction:** **MEDIUM**, `conviction_pct` **55**.
- **rationale:** **The increase gate opened today and the ladder still sizes to 50.** The INDEX axis **entered** defensive this session — SPY closed 757.39 against a 50dma of **759.0606**, a breach of 1.6706pts / **0.2201%**, having closed 760.88 above a 758.9384 SMA yesterday. With volatility, breadth, rates and shock already standing, that satisfies the gate on both limbs and takes the standing count to **5**, raw cap `LEAST(100, 25×5)` = **100**. The decay-confirmed cap is also 100: the cap is *rising*, and stickiness governs only the downward step. Crisis override not engaged (index −0.4587% vs the −2.5% bar; VIX 17.20 vs the 28 bar). **So the gate is open, the cap is 100, and the answer is still 50** — suggested target = nearest step to `0.55 × 100 = 55`, and |55−50| = 5 against |55−75| = 20, so the step is 50, exactly where f already sits. No deviation taken. **The flip point is narrow and is disclosed rather than buried: a conviction of 63 or above would round to 75**, so this turns on whether conviction sits above or below ~62.5. It does not, because **the two axes that price the cost of risk both decline to confirm and one moves against the thesis**: VIX closed 17.20 vs 17.10, essentially unchanged on a day the tape is supposed to be de-rating; HYG/IEF closed **0.8630258 against a 20d SMA of 0.8585256, +0.5242%**, where the defensive limb needs −0.50%. High yield is not widening on an oil-and-rates shock, which is the cleanest available evidence the market is not pricing a solvency or growth event. The firing axis is also thin and has recently reversed — the directly comparable 2026-09-10 breach was 0.4158pts / 0.0548% and SPY was back at 764.29 by 09-11 — and today's intraday shape argues the same way (open 760.13, low 756.16, close 757.39, i.e. 1.23 off the low). And the decisive event is tomorrow: increasing the defensive weight today pays the spread to take a position into a binary already priced ~85–90% one way. **The bear case, at full strength:** breadth −3.38pp to 52.88 is the largest one-session fall in the series and sits 2.88pp above the WEAK line; the shock axis deepened *physically* (pipeline struck and shut, Brent +2.9050%, XLE the only sector meaningfully higher); nine of eleven sectors fell with discretionary worst on the morning Empire State new orders collapsed 17.3 → 2.0. That combination is why conviction is 55 and not 40. It is not a reason to move capital today, because **breadth and shock are both already counted as standing axes, and a standing state is not news** — the deterioration deepens conditions the current f=50 was already set against. VOO beats SGOV as the majority sleeve for the same reason it did yesterday: nothing in the confirming evidence has changed, only the count of axes that have not confirmed.
- **invalidation:** **A second independent axis ENTERING defensive flips this to a de-risk** — at the same single-confirmation bar this KEEP rests on, not a conjunctive checklist. The two live candidates are named: **credit**, if HYG/IEF turns down through −0.50% of its 20d SMA on a hawkish FOMC, or **volatility**, if VIX breaks meaningfully above its 15.6395 20-day mean. Breadth cannot supply it — already standing, and a standing axis cannot fire. Conversely, index recovering above its 50dma with VIX and credit still unconfirming argues **f=25** on the next re-decide. Decreases remain always allowed and never delayed.
- **theater_check:** **PASS.** The risk today was the reverse of the usual one — the ladder produced KEEP and a session could stop thinking there. Tested by naming the flip point (conviction 63 rounds to 75) and asking what would have reached it: a VIX or credit confirmation, neither of which arrived. The strongest bear evidence is stated at full strength and rejected on a named ground, not minimised.

**DE-RISK EVIDENCE CARDINALITY:** exactly **one** axis fired (index). `fields.park_watch = true`, `fields.watch_axis = 'index'`.

**MIXED VINTAGE / axis overrides.** `state.park_axis_daily` for 2026-09-15 reports standing 4 / firing 0 / cap 100 / `increase_gate_open` FALSE, with **all six axes carrying `measured_on = 2026-09-14` and `axes_measured_today = 0`** — structural, because D2a writes `events.signal_marks` at 22:40 UTC and this run is at 22:15 UTC. This session's live readings disagree on one axis and the disagreement is recorded in `fields.axis_overrides`: index is scored defensive **and** firing here against the panel's not-defensive. Note the direction — the override **upgrades** the mechanical picture, which the one-way ratchet forbids the *mechanical* count from doing to a session; it does not forbid a session's own fresh measurement. Nothing turns on it either way: **the call is KEEP under both the panel's shut gate and this session's open gate.**

**Live axis scoring (this session):** index **defensive, FIRING** (SPY 757.39 < 50dma 759.0606) · volatility defensive, standing (VIX 17.20 > 15 and > 20dma 15.6395) · breadth defensive, standing (52.88 < 66) · rates defensive, standing (10Y 4.97 ≥ 4.90, last settled measurement) · shock defensive, standing (`acute` + Brent 108.75 > 95) · **credit NOT defensive** (+0.5242% vs 20dma, needs −0.50%).

Park book: VOO 10.9027 sh @ 696.20 = $7,590.46; SGOV 74.8667 sh @ 100.53 = $7,526.35; park MV **$15,116.81**; `actual_f_pct` **49.7880%**. The staged `sweep-VOO-20260914` (0.0749 VOO, due today) appears unfilled as of the 16:10 MT connector read — ~$52 against a ~$15.1k park, under 0.2pp of f. D2a owns its reconciliation and nothing in this call depends on it.

Heartbeat written: `ops.heartbeat ('loop:park_allocator', 'VOO call, status=BOUND')`.

---

## FRONTIER-LLM CAPABILITY CHECK

Tuesday's prompt-injection battery, one `hf_fs` paper-search query as capped. Five hits returned, **none published inside the ~72h window** (most recent 2026-06-13, roughly three months stale). **NO CAPTURE**, and no strategy-archetype signal. Default-silent on ambiguity, as specified.

---

## RECOMMENDED ACTIONS

No recommended actions.

```yaml d1_actions
[]
```

---

## PROCESS NOTES

- **One finding recorded and referred rather than acted on** (`ops.alerts`, info, `park_derisk_cardinality_vs_graded_gate`). The DE-RISK EVIDENCE CARDINALITY rule (2026-09-03) says a de-risk converts only when **two** independent axes fire, and that one firing axis makes the call a WATCH. The GRADED ALLOCATION increase gate (2026-09-04) says **one** axis entering defensive plus a standing count ≥2 opens the gate. These disagree for exactly the one-firing-axis case, and the fleet has already acted on the looser reading: **D2's 2026-09-10 conversion from f=25 to f=50 fired on one axis (index) plus four standing** — a WATCH under the cardinality rule body, correct under the graded gate. The cardinality rule is marked "SUPERSEDED as the SIZING rule, RETAINED as its floor," with the floor restated parenthetically as a *standing*-axis claim narrower than its own body. Either resolution is defensible; leaving both live is not, because the control exists to prevent a repeat of the single-axis de-risk that cost a measured $214.32. **Nothing turned on it today** — this run met the graded gate and still called KEEP on the ladder arithmetic — which is why it is referred to W5's SPEC-DEFECT NOTICE INTAKE rather than resolved here.
- **Sub-agent output was verified, not trusted.** The sector pull arrived with XLU's price levels transposed into XLC and a self-contradicting retraction attached; both contracts were re-pulled before any write. The single-name discovery sweep missed AMZN, a rail-clearing move in a $2.67T name, because neither a percent-ranked nor a volume-ranked top-50 list contains it; it was recovered from the open-book sweep and independently cross-confirmed against FMP's own `changePercentage`.
- **Standing FMP tier denials were not re-alerted.** `news/general-news` and `company/market-cap` returned ACCESS DENIED; both are recorded standing facts in the FMP TIER MATRIX, and re-raising them is the alarm fatigue the alert discipline exists to prevent. `profile-symbol` returned for every symbol tried, as the recorded escalation path prescribes.

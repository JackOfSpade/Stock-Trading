2026-09-16
<!-- d1_scan_through_utc: 2026-09-16T22:31:18Z -->

# Daily Market Development Scan — 2026-09-16 (Wed, MT)

**Scan window: 2026-09-15 16:15 MT → 2026-09-16 16:31 MT** (24.3h — cadence-normal, no gap to state). Resolved from the prior `Daily.md`'s `<!-- d1_scan_through_utc: 2026-09-15T22:15:00Z -->` marker, cross-checked against that file's own commit at `2026-09-15T22:30:02Z` — the two agree to within fifteen minutes. `state.routine_catchup_window` independently gives `window_days = 0.98`, so no `CATCHUP` token is owed. The git history is **not** shallow (1,464 commits), so the git leg of the window resolution is sound rather than merely silent. **ONE completed US trading session inside this window: Wednesday 2026-09-16.** `state.trading_day_today` gives `is_trading_day = true`, `last_trading_day = 2026-09-16`, `next_trading_day = 2026-09-17`. Every close-to-close figure in this file is measured **2026-09-15 → 2026-09-16**.

**Tape — the Fed hiked, the index barely moved, and everything interesting happened underneath it.** The FOMC raised the target range 25bp to **3.75–4.00%**, its first hike since 2023. SPY 757.39 → **754.05** (**−0.4410%**), VOO 696.20 → 693.24 (−0.4252%). But the index print is the least informative number on the page: SPY traded as high as **761.62** after the 14:00 ET decision and closed at 754.05 against a **749.60** low, on **37.8M shares** versus a 22–27M recent norm. A post-decision pop sold into the close on heavy volume is the shape of this session. Beneath it: QQQ **+0.0256%** against DIA **−1.1531%** and IWM −0.4279%. VIX 17.20 → **17.71** (+2.9651%). Brent (BZX6) 108.75 → **105.83** (−2.6851%), USO −3.5154%. TLT **+0.2107%**, LQD +0.1630%, HYG +0.0510%, UUP +0.6379%, GLD −0.6114%, SGOV +0.0199%, BITO −0.0978%. Equity breadth ($S5TH) 52.88 → **50.09**, a **−2.79pp** fall and **−6.17pp** over three sessions. **Two of eleven GICS sectors higher**, one exactly flat, cross-sector spread **2.9857pp** (XLK +0.1034% to XLE −2.8823%) against 3.9152pp yesterday — a third consecutive session of wide dispersion, narrowing but still wide.

All equity/ETF figures are IBKR regular-session daily bars (`get_price_history`, `step='ONE_DAY'`, `outside_rth=false`), every bar verified carrying a 2026-09-16 stamp of `13:30:00Z`. **Two documented exceptions, stated rather than hidden:** the ^VIX bar (contract 13455763, `IND`/CBOE) stamps `07:15:00Z` and carries `delayed:900` — an index-feed property, not an equity RTH bar; and the Brent bar is a NYMEX future (BZX6, contract 339981284) carrying `delayed:600`.

**This run is NOT degraded, and that is measured rather than claimed.** 18 distinct single names and 26 index/ETF/future instruments were put to IBKR for confirmation; **all 44 returned a genuine 2026-09-16 regular-session bar. Zero symbol-level denials. Zero measurement failures.** Every `surfaced_count` in this file is an affirmatively established figure, never a reported zero standing in for an unmeasured population.

**Two data-provenance corrections, both made before anything was written.** (1) **Nine of the eleven sector-ETF contract ids carried into this run were wrong or invalid**, and one of them — `4215200`, carried as XLK — in fact resolves to **XLB** and returns a perfectly clean, correctly-stamped regular-session bar for the wrong instrument. A silently-wrong contract id is the dangerous shape: nothing downstream can detect it. All eleven were re-resolved via `search_contracts` before pricing, and two independent continuity checks confirm the corrected series — XLU's 2026-09-15 close of 41.32 and XLC's of 114.03 both match the 2026-09-15 file exactly. There is no canonical contract-id registry for these ETFs anywhere in the repo; that gap is recorded as `ops.alerts` `716d9ab3` (`sector_etf_contract_ids_unregistered`, info) naming W5 SPEC-DEFECT NOTICE INTAKE as owner, and is **not** fixed here. (2) Seven of the thirteen tape-frame contract ids were likewise wrong and were re-resolved the same way — including HYG, where the wrong id would have silently broken the park credit axis.

---

## TL;DR

- **Exits triggered: none.** No convergence target, no time exit, and no thesis-invalidation criterion met on any of the 12 open tranches. Nothing on this book carries a rate-sensitive or price-level criterion, so the hike touches none of them.
- **New entry candidates: 1 flagged, 0 routable.** JBHT **−13.3016%** on a dated Q3 cost warning clears Strategy B's frozen ≥5% floor decisively — index-only, because B is `DO-NOT-ACTIVATE`.
- **Add candidates: none** (12 evaluated, 0 flagged, 3 declined at the HARD GATE — ISRG, RTX, UBER). GEV is again the strongest case on the book and again declined only because D is capital-disabled.
- **Watchlist changes: 2** — add JBHT to the B new-entry index; annotate the A-queue XOM row, whose crude-up/energy-flat divergence closed today in the direction that **weakens** the thesis.
- **Regime review: no review.** The event that could have warranted one has now resolved exactly as priced; the router reads are unchanged and the bar for an inter-monthly review is deliberately high.
- **Park: KEEP at f=50** (VOO 50% / SGOV 50%), MEDIUM 55, BOUND. Five axes stand defensive and the increase gate is open — but **not one axis entered defensive today**, and credit is moving the other way.

---

## DEVELOPMENTS

### 1. Market-wide breaking events

**The FOMC decision is item 2 — it was scheduled, and it is recorded there.** Two genuinely unscheduled items in the window:

- **Crypto Clarity Act fails Senate cloture** (2026-09-15, ~15:00 ET — just outside the prior session's close, with its reaction carrying into 2026-09-16). The Digital Asset Market Clarity Act failed to reach the 60 votes needed on a motion to proceed. **Reported tallies differ by outlet and the discrepancy is recorded rather than resolved:** CoinDesk, The Hill and Politico report 49–50; CNBC's live report states "50 votes for and 49 against." All sources agree it failed. Sen. Lummis called it "over" for the bill this year. Stated reactions: bitcoin ~−3%, COIN −8%, CRCL −10% (CNBC, 2026-09-15). Our own measurement of the crypto complex **today** shows the reaction had already exhausted itself: BITO −0.0978%, essentially flat.
- **US–Iran conflict, ongoing rather than new.** A CBO estimate published this week puts the cost at ~$38bn through 2026-08-01, ~$3bn/month if it continues, and projects ~0.5pp added to Q1 2027 inflation. This is context for the `shock_overlay = acute` standing state, **not** a new shock inside the window, and it is deliberately not counted as such.

No other unscheduled market-wide shock — bankruptcy, disaster, new enforcement action — was found in the window.

### 2. Scheduled events that resolved

**FOMC, 2026-09-15/16 — the event of the session. Primary source: federalreserve.gov.**

- **Decision:** target range raised **25bp to 3-3/4 to 4 percent (3.75–4.00%)** from 3.50–3.75%. The **first hike since 2023**. Statement, Implementation Note and Projection Materials all released **2026-09-16, 14:00 ET** (`monetary20260916a.htm`, `fomcprojtabl20260916.htm`).
- **Vote: 12–0.** The statement as fetched does not enumerate names or dissents, unlike the March 2026 statement which named the Chair and listed a dissent. **That absence is recorded as an absence** — no roll call was independently confirmed.
- **Statement language (verbatim):** "Economic activity is expanding at a solid pace"; "Job gains have kept pace with the workforce, and the unemployment rate has changed little"; "Inflation remains elevated. Today's policy action will support a timelier return to the Committee's 2 percent goal"; "While uncertainty remains elevated owing, in part, to geopolitical developments, domestic spending has been resilient."
- **SEP / dot plot** (2026 → 2027 → 2028 → longer run): fed funds median **4.1 / 4.1 / 3.9 / 3.2**; real GDP 2.3 / 2.4 / 2.2 / 2.0 (June: 2.2 / 2.3 / 2.2); unemployment **4.1 / 4.1 / 4.1 / 4.2** (June: 4.3 / 4.3 / 4.2); PCE 3.7 / 2.3 / 2.1 / 2.0 (June: 3.6 / 2.3 / 2.0); core PCE 3.4 / 2.5 / 2.2 (June: 3.3 / 2.5 / 2.1). Per CNBC, 16 of 18 participants expect at least one more hike this year.
- **Press conference — and a correction to this file's own prior framing.** The presser was delivered by **Chair Kevin Warsh**, not Powell. Warsh: "We removed a dose of accommodation"; a September core PCE estimate of "about 3.2%"; "too many categories are still trending higher than the Fed's 2% inflation goal"; and on the test for stopping, "We must be confident that underlying inflation is moving toward our goal at sufficient speed" — a criterion that "has not been met." These are sourced from secondary reporting of the presser, **not** the verbatim Fed transcript, and are labelled as such.
- **Reaction, and why two wires disagree.** Reuters filed shortly after 14:00 ET that indexes were "mostly higher," S&P +0.3%; Zacks reported the S&P closing −0.5%. Both are right about different minutes. **The IBKR daily bar settles it:** SPY high 761.62, close 754.05, low 749.60, −0.4410% on 37.8M shares.

**Other resolved catalysts — a measured gap, not an assertion of absence.** FMP's earnings-calendar returned **zero rows** for 2026-09-15/16, and a broad search surfaced only sub-$2B names. **No ≥$2B-cap earnings resolution was confirmed in this window from a primary source, and no FDA PDUFA outcome was found.** That is a coverage gap in the discovery leg, stated as one; it is not a claim that none occurred.

### 3. Large single-name moves — AI-SIGNIFICANCE SCREEN

Layer-1 rail: US-listed, cap ≥ $2B, ≥2% close-to-close, identifiable public event. Layer-2 decides. Logged as `events.decision_log` `research-screen` (`screen='single-name-move'`), entry `873b8fad-0111-43e9-a015-1d252bb59dce`. **`surfaced_count` = 5 = `ARRAY_LENGTH(passed)`; `rail_tally` = 6; `universe_measured` = 18.** Agreement: both 2 / AI-only 3 / rule-only 3.

| Ticker | Move | Conviction | Event | `legacy_rule_pass` | `below_spec_floor` |
|---|---|---|---|---|---|
| **JBHT** | **−13.3016%** (273.05 → 236.73) | **75** | Warned at the Morgan Stanley Laguna Conference (2026-09-16) that Q3 earnings could fall **5–10% vs Q2** on rising purchased-transportation costs. Cap $22.2B. | true | false |
| **HBAN** | −5.5522% (16.75 → 15.82) | 60 | No name-specific news; the FOMC hike, transmitted specifically through regional-bank NIM and CRE credit. Cap $32.0B. | true | false |
| **GEV** | +4.7893% (882.81 → 925.09) | 60 | Three dated events — see below. Cap ~$246.2B. | false | true |
| **INTC** | +4.0251% (97.14 → 101.05) | 60 | Reuters-sourced report (2026-09-16) that SK Hynix and Intel are in early talks over first-ever US memory-chip production. Cap $509.7B. | false | true |
| **BAC** | −2.7218% (59.52 → 57.90) | 45 | Same FOMC event as HBAN. Cap $410.9B. | false | true |

**JBHT is the only genuine company-specific shock of the day and the highest-signal item on the board.** A $22.2B freight bellwether losing an eighth of its value on a **cost** warning rather than a demand warning is a real-economy margin read — and it lands on the same day the Fed restarted a hiking cycle into an economy the regime record already scores `growth_momentum = decelerating`.

**GEV** was discovered by this session's own open-book sweep, not by either external discovery leg — which is exactly why that sweep is unconditional. Three dated 2026-09-16 events: CEO Scott Strazik at Morgan Stanley Laguna citing "very strong and durable demand" and backlog reaching **$200B "very early in 2027"** against $176B at Q2; the **Vineyard Wind commercial-litigation settlement**, with GE Vernova withdrawing its notice of termination and both parties dismissing all claims (gevernova.com, Cambridge MA); and **Blue Energy's NRC construction-permit filing** for a BWRX-300 SMR at Port of Victoria, Texas. Partly a rebound from −8.6% on 2026-09-14 on AI-slowdown headlines.

**HBAN is surfaced for the signal but explicitly NOT routed as a Strategy B candidate**, despite clearing the ≥5% floor. B exploits mispricing of **company-specific** information; a sector-wide repricing on a macro print carries none to be mispriced. Mechanism fit is recorded as failing rather than smoothed, on the AMLX precedent.

**Rejected as notable.** **NU −2.6779%** ($66.9B) was surfaced with the FOMC as its stated driver on the ground that FMP classifies it "Banks – Regional." That is a classification artifact — NU is a LatAm digital bank whose economics are not set by the FOMC — so the attribution fails. A confidently wrong attribution is worse than none.

**Measured, cleared price and cap, no identifiable public event — named individually, never silently dropped.** CIFR +10.8019% ($6.8B) · RIG −6.7340% ($5.6B; coincident with Brent −2.6851% and USO −3.5154% but no dated name-specific catalyst) · PATH −4.2165% ($7.2B) · NOK +3.0488% ($54.8B) · SPCX +5.1501%. None clears the rail's event clause, so none is routed anywhere. **SPCX carries an FMP `profile-symbol` market cap of $1.97 TRILLION at a ~$150 share price, which is not credible on its face** — the binary ≥$2B call is unaffected either way, but the magnitude is explicitly not trusted. SPCX is separately notable as a **source-coverage change**: the 2026-09-15 run recorded it as unresolvable by IBKR `search_contracts`, and it resolved cleanly today.

**Excluded on the cap rail before any IBKR spend:** ALHC (−16.0077% per FMP, cap $1.81B — inside the ~30% second-source band, and the `market-cap` second source returned ACCESS DENIED, so the exclusion rests on `profile-symbol` alone and is recorded as such), BBNX (+15.34%, $0.998B), EAF (+13.74%, $0.211B).

**FMP tier surface:** `company/profile-symbol` returned a cap for all 15 symbols asked; `company/market-cap` denied. That is the **standing** recorded surface, not a move, so **no `fmp_quote_plan_gated` row is raised** — per the 2026-08-26 rule that closed the third re-raise in four days.

### 4. Sector-level moves — AI-SIGNIFICANCE SCREEN

Logged as `research-screen` (`screen='sector-move'`). **`surfaced_count` = 2 = `ARRAY_LENGTH(passed)`; `rail_tally` = 2; `universe_measured` = 11.** Agreement: both 1 / AI-only 1 / rule-only 0.

| Sector | Move | | Sector | Move |
|---|---|---|---|---|
| XLK Technology | +0.1034% | | XLRE Real Estate | −0.6037% |
| XLV Health Care | +0.0656% | | XLY Cons Disc | −0.6313% |
| XLU Utilities | 0.0000% | | XLB Materials | −0.7292% |
| XLI Industrials | −0.0829% | | XLC Comm Svcs | −0.9034% |
| XLP Cons Staples | −0.4777% | | **XLF Financials** | **−1.6183%** |
| | | | **XLE Energy** | **−2.8823%** |

**XLF −1.6183%, conviction 75 — the signal of the day, and the reason this screen matters more than the index print.** The Fed hiked, and financials were the second-worst major sector, regionals leading down (HBAN −5.5522%) and megacaps following (BAC −2.7218%). **A rate hike that sells banks is the tell.** The naive NIM read says a hike helps bank margins; the market instead priced the credit-and-growth side of a tightening cycle landing on an economy already scored `decelerating`. This is deliberately **not** treated as the park's credit axis firing — the mechanical credit test measures **+0.6253%** and refuses to confirm, and an equity-sector move is not a credit-spread reading. Two readings of adjacent things are not two axes.

**XLE −2.8823%, conviction 60 — and it closes a divergence this routine flagged one session ago.** Brent fell 108.75 → 105.83 (−2.6851%) after rising +2.9050% the prior session; USO −3.5154%. On 2026-09-15 D1 recorded that crude was rising while energy equities were not following, and carried it as a live note against the A-queue XOM thesis. **Today they followed — downward, with crude.** The divergence closed in the direction that weakens the thesis rather than confirming it, which is worth more than the sector move itself.

**Not surfaced, and why — the absence is informative.** The defensive complex did **not** behave like a defensive rotation: XLU exactly flat, XLV +0.0656%, and staples **down** (XLP −0.4777%). What worked was technology; what did not was cyclicals — energy, financials, materials, discretionary. Large-cap growth outperforming while cyclicals sell and defensives do nothing is a duration/growth-scare shape, **not** the classic risk-off rotation, and reading it as the latter would be the 2026-09-01 error (`bigquery/213`) in a new costume.

### 5. Notable commentary

- **Goldman Sachs Asset Management** (Kay Haigh, CIO Fixed Income): "Most FOMC members see a total of two hikes this year per the SEP, and it will likely skip October's meeting given its proximity to the midterm elections. One more hike this year in December is our base case, although this remains contingent on upcoming CPI reports and the path of energy prices."
- **Corpay** (Karl Schamotta): the hike "should go a long way toward restoring confidence in the Fed's commitment to fighting inflation, and help remove a major headwind keeping the dollar restrained." Our own measurement is consistent — UUP **+0.6379%**.
- **StoneX / Investing.com** (Matt Weller), pre-decision: a dot-plot median above 4.0% held through 2027 would read as a "hawkish hike"; flagged Warsh's break from "Powell-style forward guidance." The median printed **4.1 for both 2026 and 2027**.
- **GE Vernova** (CEO Scott Strazik, Morgan Stanley Laguna): "very strong and durable demand," 2030–2040 an "even better decade," backlog to $200B "very early in 2027." Recorded here and load-bearing in the add-candidate section below.

No sell-side research PDFs were fetched; the above are wire-compiled reaction quotes.

---

## ANALYSIS — RISK TO EXISTING POSITIONS

### MECHANICAL EXIT-TRIGGER SWEEP

**Twelve open tranches, all Strategy D. There is no open A, B, C or E position.** The union sweep of `state.current_positions` and live `get_account_positions` reconciles **exactly** on all eight names — AMZN 0.3464, DIS 0.7244, GEV 0.1244, GOOGL 0.2577, ISRG 0.1091, RTX 0.1601, TSM 0.1550, UBER 0.5156 — so there is **no reconciliation-lag position** and no `position_reconciliation_lag` alert is owed. The only other IBKR lines are the park sleeves VOO and SGOV, which are not strategy positions.

**Not one of the twelve carries a `convergence_target` or a `time_exit_date`** (both NULL on every row). The mechanical sweep therefore returns empty **by construction rather than by omission**, and that is stated so a later reader cannot mistake silence for an unchecked sweep. **No EXIT TRIGGERED.**

### PER-STRATEGY KILL-TRIGGER SWEEP

`perf.kill_flags`, with `current_drawdown` refreshed unconditionally against today's live marks:

| Strategy | Deployed days | Drawdown | `drawdown_kill` | `runaway_review` | `m2m_underperf_review` | `gate_reached` | `interim_underperf_warning` |
|---|---|---|---|---|---|---|---|
| D | 98 | −5.07% | false | false | false | false | **false** |
| B | 79 (as-of 2026-08-18) | −3.92% | false | false | false | false | **false** |

**No flag fires.** D's −5.07% drawdown is an order of magnitude inside the −50% mechanical kill. `interim_underperf_warning` is FALSE for both, so no `interim_underperf_warning` alert is raised and none is open to heal. B's engine row is stamped 2026-08-18 because B has held no position since; that is expected, not stale data.

**B open-book pairwise correlation:** `analytics.b_pairwise_correlation` returns `n_positions = 0`, so the `n_positions >= 2` term fails and the check is a **no-op**. (Note: prose elsewhere in the plan describes B as holding MDT. It does not — B holds nothing. The check is inert either way.)

### THESIS-INVALIDATION ASSESSMENT

**No Development above triggers any invalidation criterion on any of the twelve tranches, and the reason is structural rather than lucky.** The dominant development is a **discount-rate** event. Every invalidation criterion on this book is a company fundamental — segment growth, operating margin, backlog, orders, regulatory remedy — or a metric-immutability clause. **Not one is rate-sensitive, and not one names a price level.** RTX's entry record explicitly *dropped* a draft "stock breaks $130 on heavy volume" criterion as contradicting Strategy D's no-stop design. So there is no price-level criterion anywhere on this book, and the **DIVIDEND NETTING** rule has nothing to bite on this session — `state.price_level_criterion_drift` was not consulted because no criterion qualifies for it.

Per name, against today's developments:

- **AMZN** (−0.9903%): AWS growth/margin/backlog criteria — no AWS news in window. **NOT met.**
- **DIS** (+0.5356%): SVOD margin, FY26 EPS guide, buyback pace, metric-immutability, FCC escalation — no Disney news in window. **NOT met.**
- **GEV** (+4.7893%): primary metric is total-company organic orders growth YoY (88% at entry, 71% prior quarter) against a <15%-for-two-quarters invalidation. Today's CEO commentary **reinforces** it. **NOT met.** See the add section for the subtlety.
- **GOOGL** (−0.6116%): Cloud revenue/margin/RPO, adverse structural remedy — no news in window. **NOT met.**
- **ISRG** (+1.3602%): procedure growth, placements, recurring revenue, competitor displacement — no news in window. **NOT met.**
- **RTX** (+0.6803%): Airbus damages, powder-metal event, GTF Advantage EIS, backlog, FCF guide, defense procurement — no news in window. **NOT met.**
- **TSM** (+0.9595%): GM/revenue, N2/A16 ramp, structural AI-capex reset — no news in window. **NOT met.** Worth noting the AI-slowdown headlines of 2026-09-14 are the nearest thing to criterion 3 on the horizon; they are commentary, not a disclosed order cut, and do not engage it.
- **UBER** (−0.6440%): gross-bookings growth, EBITDA margin, Uber One, metric-immutability — no news in window. **NOT met.**

### WATCHLIST CANDIDATES

**One material change.** The **XOM** row (A queue, added 2026-09-13) rests on crude strength with energy equities not following. Today that divergence **closed in the unfavourable direction**: crude fell −2.69% and energy equities fell with it (XLE −2.8823%), so the gap narrowed by the energy side being right rather than by the equity side catching up. No disposition change — A remains `DO-NOT-ACTIVATE` — but the row needs the annotation. CVX and the rest of the 45-name A queue are unaffected and unchanged.

---

## ANALYSIS — OPPORTUNITY CHECK

Router state (`state.current_regime`, as-of 2026-09-03): **A, B, D, E = `DO-NOT-ACTIVATE`; C = `HYBRID ACTIVATE (FOMC-only)`.**

- **Strategy C.** C's only activation lane is FOMC, and **today's FOMC has now resolved.** It was already drained NO-GO on 2026-09-08 and re-confirmed 09-09; the next lane is queued as `thesis-FOMC-C-20261020` (pending, due 2026-10-20) — noting the GSAM read above that the Committee will likely **skip October** for midterm proximity, which is a live risk to that queue item's premise but not a D1 action. **No new C candidate.**
- **Strategy B — one candidate, not routable.** **JBHT −13.3016%** on a resolved, dated public event (2026-09-16 Morgan Stanley Laguna guidance warning) clears B's frozen Entry criterion 1 (≥5% close-to-close on event day) decisively. Deterministic identity checked on the **fields** `(item_type, strategy, ticker, qualifying_event_date)`, never on the key string: `events.queue_events` holds **no JBHT row at all**, open or terminal, so this is not a duplicate. Because B is `DO-NOT-ACTIVATE`, this goes to the **Strategy B new-entry candidates state index only** — no thesis construction routed, same router reason as FN/KLAR/BIDU. Qualifying event date **2026-09-16**; 10-trading-day B window anchored on the event date per the ANCHOR PIN. Originating screen: `873b8fad-0111-43e9-a015-1d252bb59dce`.
- **HBAN** clears the ≥5% floor but is **not** routed — see the mechanism-fit reasoning in Development 3.
- **Strategy A.** INTC's SK Hynix report is an announced catalyst within six months and would be A-eligible on mechanism, but INTC is **already on the A queue** (added 2026-05-12) and A is `DO-NOT-ACTIVATE`; adding a second row would be duplication. No new A candidate.
- **Strategy E.** The day's dispersion is sector-level and macro-driven (rates repricing financials, crude repricing energy), not the intra-industry-group narrative divergence E requires. **No E candidate.**

---

## ANALYSIS — ADD-CANDIDATE CHECK

Strategies A, B, D only. Twelve open D tranches evaluated, **0 flagged, 3 declined at the HARD GATE.** Logged in full as `events.decision_log` `add-candidate-review`; `state.add_candidate_reviews` parses all twelve item rows with the controlled `trigger_type` vocabulary intact.

**Price basis.** Every `mark_vs_cost_pct` numerator is the 2026-09-16 regular-session close; every denominator is **that tranche's own** `cost_basis / shares`, never the blended account `avg_price`. **This session has a live illustration of why that pin exists:** `get_account_positions` reported GEV `market_price` **933.00** against a true close of **925.09** — an after-hours print 0.86% above the close. Taken through the tranche arithmetic it would have moved D:GEV:2026-08-03 from −4.6206% to −3.7048%, a **0.92pp error** in the only durable per-tranche price record this sweep leaves.

**HARD GATE.** Seven tranches carry `breach_status = 'NOT_ASSESSED_BY_THIS_BACKFILL'` — the same seven as on 2026-09-06, unchanged. **Not one of the twelve carries a `$.status` key**, so `invalidation_criteria_evaluable` is decided by the **third disjunct**; the two-disjunct form would return TRUE for every position on the book including the three declined here, which is the inversion that disjunct exists to prevent. Four of the seven are covered at **name** level by a later tranche carrying a fresh assessment (AMZN 07-30, DIS 08-05, GOOGL 07-26, TSM 07-29). **Three are covered nowhere: ISRG, RTX, UBER** — structurally ineligible. `ops.alerts` `3daf511e` already carries this as an open notice naming M3 as the re-assessment owner, so it is **not** re-raised.

| Tranche | `mark_vs_cost_pct` | Trigger | Disposition | Evaluable |
|---|---|---|---|---|
| D:AMZN:2026-07-09 | +1.9548% | none | declined | false |
| D:AMZN:2026-07-30 | **−7.4270%** | dip-with-intact-thesis | declined | true |
| D:DIS:2026-05-07 | −3.8888% | dip-with-intact-thesis | declined | false |
| D:DIS:2026-08-05 | +3.0877% | none | declined | true |
| **D:GEV:2026-08-03** | **−4.6206%** | **strengthened-conviction** | **declined** | true |
| D:GOOGL:2026-07-09 | −4.7182% | dip-with-intact-thesis | declined | false |
| D:GOOGL:2026-07-26 | +4.5834% | none | declined | true |
| D:ISRG:2026-07-20 | +9.3786% | none | **declined_hard_gate** | false |
| D:RTX:2026-04-27 | +11.2670% | none | **declined_hard_gate** | false |
| D:TSM:2026-07-21 | −2.3702% | dip-with-intact-thesis | declined | false |
| D:TSM:2026-07-29 | +6.3217% | none | declined | true |
| D:UBER:2026-07-09 | −3.0561% | none | **declined_hard_gate** | false |

**Strategy D is `DO-NOT-ACTIVATE`, so no add can receive capital regardless of its case.** Every disposition is therefore a decline — but the reasoning is the record, so:

**GEV is the strongest case on the book, and one leg of today's news cuts *against* an add rather than for it.** It sits −4.6206% against cost on a day it rose +4.7893% on three dated company events. The CEO's commentary directly reinforces the thesis's own primary metric, and the Vineyard Wind settlement clears a Wind-segment overhang — noting the entry record explicitly lists "further Wind segment deterioration" among its **NOT exit-triggering** items, so that upside sits *outside* the thesis's metric rather than inside it. **The subtle point:** the thesis's COMPLETION criteria are **both** (a) backlog ≥ $200B **and** (b) trailing-4Q organic orders growth decelerated to ≤25% YoY. Guidance that leg (a) arrives *early* is the thesis advancing toward its own **completion** — runway compression, not runway extension. It reads as strengthened conviction in the thesis being **right**, and simultaneously as a shortening of the time left to be right in. Recorded as `strengthened-conviction`; declined on the router.

**RTX at +11.2670% is the best mark on the book and is still structurally ineligible** — which is precisely why this sweep records the gate rather than the P&L. **UBER is the one uncovered name sitting *below* cost**, so it is the single case where a dip argument would otherwise have been available; that is the concrete cost of the unassessed-breach-status gap.

---

## ANALYSIS — REGIME CHECK

**NO review recommended.** High bar; default NO on ambiguity — and this is not even ambiguous.

The FOMC was the one event that could plausibly have warranted an inter-monthly router review, and it **resolved essentially as priced**: a 25bp hike that was ~85–90% expected, on a 12–0 vote, with a dot plot the market had largely anticipated. A priced event resolving as priced is not new information about any strategy's activation state. Four of five strategies are already `DO-NOT-ACTIVATE`, so a review has nowhere to move them but toward activation, and nothing today argues for that: breadth *deteriorated* (50.09, −2.79pp), the index axis is defensive and deepening, and the only sector strength was a flat technology tape.

The honest counter-argument, stated rather than omitted: `policy_stance` is already scored **hawkish** and today confirmed it; `growth_momentum` is already **decelerating** and JBHT's cost warning plus the bank tape are consistent with that. **Both readings are confirmations of the standing regime, not changes to it** — and confirming a standing state is exactly what the 2026-09-01 record got wrong by treating it as news. The monthly M1a/M1b cycle is the right place for this, not an out-of-cycle M1R.

One mechanical note for D2a, observed not classified: **SPY_TREND** read `NEUTRAL` at 757.39 on 2026-09-15 against a 50dma of 759.06. Today SPY closed 754.05 against a 50dma of **759.1874** — below by 0.6767%, a materially deeper breach. The HEALTHY/WEAK and trend thresholds are D2a's to apply; this file only observes.

---

## EQUITY-BREADTH OBSERVATION

**`EQUITY_BREADTH_PCT` = 50.09 for `as_of_date` 2026-09-16.** Written to `events.regime_events` (`scope='TECHNICAL_INPUT'`), idempotent on `(as_of_date, scope, key)` — one row, verified no prior row existed for today.

- **Source: Barchart `$S5TH`**, `https://www.barchart.com/stocks/quotes/$s5th?cb=20260916`, cache-busted. Page header: `50.09 -2.79 (-5.28%) 17:59 ET [INDEX]`. **On-page as-of wording, verbatim: "Quote Overview for Wed, Sep 16th, 2026"** — source-dated, **not** `inferred_post_close`.
- **Fetch path is part of the provenance:** a rendering `WebFetch` on the identical URL returned a **blank page**; per the fetch-method rule that condemned *that fetch*, not the source, so the other path was retried and `tavily_extract` succeeded. The kept figure came from `tavily_extract`.
- **Previous Close read 52.88 — an exact match** to the stored 2026-09-15 value. Zero overnight revision, so no Previous-Close reconciliation is owed this session.
- **SINGLE USABLE SOURCE, and this run says so.** EODData `$S5TH` was reached (on `WebFetch`; `tavily_extract` failed with "Failed to fetch url") and returned **48.11** — but with on-page timestamp **"16 Sep 26 15:58"** and **Low == Close == 48.11**, the documented unsettled tell on **both** legs. It is recorded as reached-but-unusable, not as a cross-check, and the 1.98pt gap is **not** treated as a source disagreement. The >5pp no-row rule is therefore not engaged.
- **MacroMicro was deliberately not attempted.** The 2026-09-06 W5 ruling makes it a **weekly re-probe riding the Sunday D1 run**; today is Wednesday, so a fetch would have been forbidden spend.
- Trajectory: 56.26 (09-14) → 52.88 (09-15) → **50.09** (09-16), **−6.17pp over three sessions.**

---

## PARK ALLOCATION CALL

- **`vehicle`: VOO** — the **majority sleeve** at `target_f_pct = 50` (the f=50 tie resolves to the risk sleeve per the assignment rule; this is *not* a claim the book is single-vehicle). `risk_sleeve` VOO, `defensive_sleeve` SGOV.
- **`target_f_pct`: 50 — unchanged. Direction: KEEP. Status: BOUND.**
- **`conviction`: MEDIUM, `conviction_pct` 55.**
- **`rationale`:** Standing defensive count **5 of 6** testable axes → raw cap `LEAST(100, 25 × 5)` = **100**. The **decay-confirmed cap is also 100**, and that is computed rather than assumed: `park_axis_daily.cap_pct` has read 100 on **every** session from 09-10 through 09-16, so no step-down was ever in progress and the three-consecutive-readings rule has nothing to unwind. Suggested target = nearest step to `0.55 × 100 = 55`, and `|55−50| = 5` against `|55−75| = 20`, so the ladder sizes to **50** — today's opening f. The permitted ±1-step deviation to 75 is available and is **declined**.

  **The case FOR stepping to 75 is real and is stated first.** The Fed restarted a hiking cycle into an economy already scored `decelerating`; five axes stand defensive with the increase gate open and the cap at 100; the index breach deepened from 0.0548% below the 50dma on 09-10 to **0.6767%** today, and drawdown from the 252-session closing high (777.88) is now **−3.0635%**, which **clears the −3% limb** that failed at −2.5775% on 09-10; and the tape beneath a benign index print was ugly — a pop to 761.62 sold to a 754.05 close near the 749.60 low on 37.8M shares, with financials selling **on** a rate hike.

  **The case AGAINST wins, on four specific grounds.** (a) **Not one axis entered defensive today.** The single firing axis, index, entered on **2026-09-15** — the same event that already justified no change yesterday — and a 25bp hike ~85–90% priced going in is by construction mostly in the price. (b) **Credit, the most reliable risk-appetite axis on this panel, is moving the other way**: HYG/IEF = 0.8643227 against a 20d SMA of 0.8589514, **+0.6253%** where the test needs −0.50%, and it **improved** from +0.5242% yesterday. (c) **The long end declined to confirm** — the 30Y *fell* 1bp to 5.35% and TLT rose +0.2107%. The move was front-end only (2Y +7bp, curve 0.33 → 0.27), the shape of a credible inflation-fighting hike rather than a growth scare. (d) **The measured record does not flatter de-risking**: both closed defensive excursions of the AI era lost (−2.841pp, −1.019pp — 0-for-2), and across 15 historical episodes the defensive signal carried mean forward edge −0.638pp, winning 4 of 15. Reaching the 75 step needs conviction ≥ ~62.5; on this evidence I do not have it. **Why VOO/SGOV at 50/50 beats the runner-up (f=75):** the runner-up buys protection against a deterioration that four of six axes are currently *not* signalling, at a cost this allocator has measured itself paying twice.

  **Axis scoring — five of six measured by this session today, mechanical panel agrees, no overrides.** volatility DEFENSIVE (VIX 17.71 > 20d SMA 15.7715 and > 15) · breadth DEFENSIVE (50.09 < 66, written by this run minutes earlier — the one genuinely same-session axis) · index DEFENSIVE **and firing** (entered 09-15) · rates DEFENSIVE (FOMC +25bp; 10Y 5.01, 2Y 4.74, curve flattening) · shock DEFENSIVE (`shock_overlay = acute` as-of **2026-09-01** — a three-week-old **standing state, which is never news** — and Brent 105.83 > 95) · credit **NOT** defensive. `state.park_axis_daily` publishes standing 5 / firing 1 / cap 100 / gate open with `axes_measured_today = 0`, because D2a writes `events.signal_marks` at 16:41 MT, *after* this routine — structural, not an outage. My independent live readings **agree with the panel on every axis**, so `fields.axis_overrides` is empty and the one-way ratchet was not needed in either direction.

  **Rule interaction, stated rather than glossed.** The DE-RISK EVIDENCE CARDINALITY floor asks for **two** independent axes firing in the same session; today has **zero**. The graded increase gate asks for one axis entered within 2 sessions **and** standing ≥2, which **is** satisfied. The two rules disagree about whether an increase is licensed — the exact tension already open as `ops.alerts` `55d7e9a3`. It is **not** re-raised and needs no adjudication today, because **both readings land on the same answer**: the floor forbids an increase, and the ladder independently sizes to 50.

  Crisis override **not engaged**: session index move −0.4410% against the −2.5% bar; VIX 17.71 against the 28 bar.
- **`invalidation` (symmetric standard, both limbs at the same bar):** **Would RAISE f** — a *second* axis **entering** defensive in the same session, with credit the live candidate (specifically HYG/IEF crossing below its 20d SMA by more than 0.50%, a swing of >1.1pp from today); **or** an index break through the 200dma or drawdown past roughly −5%; **or** VIX holding ≥22. **Would LOWER f** — **any one** of: SPY reclaiming its 50dma (759.1874) on a close; breadth recovering above roughly 60; or the index axis simply exiting defensive. Deliberately **disjunctive and narratively judged** — I am not requiring three conjunctive conditions to re-risk when I did not require three to de-risk. That asymmetry is what made the park sticky in the 2026-07-31/08-02 episode and cost ~$265 of foregone return before the 08-03 call correctly overrode it. No later session is bound by this.
- **`theater_check`:** The conclusion is the **default**, and the arithmetic producing it (`0.55 × 100 = 55 → step 50`) was computed **before** the rationale was written. The strongest counter-case is stated in full and first, and the grounds for declining the step to 75 are **falsifiable against tomorrow's readings**: credit at +0.6253% and improving, the 30Y down 1bp, zero axes entering, 0-for-2 measured. If credit turns tomorrow, the call should change — and this note is what will make that legible.

Heartbeat written: `ops.heartbeat` `('loop:park_allocator', 'VOO call, status=BOUND')`.

---

## RECOMMENDED ACTIONS

- **Watchlist add — JBHT to the Strategy B new-entry candidates index** (state index only; **no** thesis construction routed, because B is `DO-NOT-ACTIVATE`). **−13.3016%** close-to-close (273.05 → 236.73, IBKR RTH daily bars, contract 270825) on the **2026-09-16** Morgan Stanley Laguna Conference warning that Q3 earnings could fall 5–10% vs Q2 on rising purchased-transportation costs. Clears B Entry criterion 1's frozen ≥5% floor decisively. **Qualifying event date 2026-09-16**; 10-trading-day B window anchored on the event date per the ANCHOR PIN. Originating D1 `research-screen` decision `873b8fad-0111-43e9-a015-1d252bb59dce`. Deterministic four-part identity checked on fields against both open and terminal `events.queue_events` — no JBHT row exists, so this is not a duplicate.
- **Watchlist annotation — XOM (Strategy A queue).** The crude-up/energy-equities-flat divergence this row was carrying **closed on 2026-09-16, unfavourably**: Brent fell −2.6851% (108.75 → 105.83) and energy equities fell with it (XLE −2.8823%), so the gap narrowed by the energy side being right rather than the equity side catching up. **No disposition change** — A remains `DO-NOT-ACTIVATE` — but the row's live note should record the resolution and its direction.

**No exits triggered. No add candidates flagged. No router review recommended.**

```yaml d1_actions
- action: watchlist
  ticker: JBHT
  strategy: B
  qualifying_event_date: 2026-09-16
  source_research_screen_id: 873b8fad-0111-43e9-a015-1d252bb59dce
  detail: >-
    ADD to the Strategy B new-entry candidates state index (index-only, no thesis construction
    routed, B router DO-NOT-ACTIVATE). -13.3016% close-to-close 273.05 -> 236.73, IBKR RTH daily
    bars contract 270825, on the 2026-09-16 Morgan Stanley Laguna Conference warning that Q3
    earnings could fall 5-10% vs Q2 on rising purchased-transportation costs. Clears B Entry
    criterion 1's frozen >=5% floor. 10-trading-day B window anchored on the qualifying event
    date 2026-09-16 per the ANCHOR PIN. Cap $22.2B (FMP profile-symbol).
- action: watchlist
  ticker: XOM
  strategy: A
  qualifying_event_date: n/a
  source_research_screen_id: n/a
  detail: >-
    ANNOTATE the existing A-queue XOM row (no disposition change; A remains DO-NOT-ACTIVATE).
    The crude-up / energy-equities-not-following divergence flagged on 2026-09-15 closed on
    2026-09-16 in the UNFAVOURABLE direction: Brent -2.6851% (108.75 -> 105.83) and XLE
    -2.8823%, i.e. the gap narrowed by the energy side being right rather than the equity side
    catching up. Record the resolution and its direction on the row's live note.
```

---

*Metered spend this run: 47 logged `ops.web_calls` rows — 19 Tavily (~20 credits, a floor), 21 FMP, 6 `web_fetch`, 1 HF. IBKR and BigQuery calls are free and are not billed telemetry.*

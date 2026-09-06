2026-09-06
<!-- d1_scan_through_utc: 2026-09-06T22:33:00Z -->

# Daily Market Development Scan — 2026-09-06 (Sun, MT)

**Scan window: 2026-09-03 16:32 MT → 2026-09-06 16:33 MT** (71.6h — a MULTI-SESSION GAP, stated explicitly per the >50h rule; resolved from the prior `Daily.md`'s `d1_scan_through_utc: 2026-09-03T22:32:00Z` marker, cross-checked against that file's commit at 2026-09-03T22:33:48Z — the two agree to within two minutes). **The gap is the cadence, not a miss:** D1 runs Sun–Thu, so Friday 2026-09-04 has no D1 slot of its own and Sunday's run legitimately covers it. **Exactly ONE completed trading session in window: Friday 2026-09-04.** Monday 2026-09-07 is Labor Day; `state.trading_day_today` gives `is_trading_day=false`, `last_trading_day=2026-09-04`, `next_trading_day=2026-09-08`.

`state.routine_catchup_window` gives `window_days = 2.98` against a daily cadence, so a **`CATCHUP[window_days=2.98]` token IS owed** and is carried on the completion row. The widened evidence window and the scan window resolve to the same boundary here (2026-09-03 ~22:32Z), so nothing is covered twice and nothing is dropped.

Pre-flight clean on the first attempt: BigQuery (`state.trading_day_today`) and IBKR (`get_account_summary` → NLV 15,837.41) both live; no retry ladder entered, no transient encountered. D1 stages no orders, so Calendar is exempt. Same-day double-run guard clear — zero D1 rows of any status for 2026-09-06 at guard time. D1 declares no upstream dependencies — no gate, **no `DEPWAIT` token**.

**GATE DISPOSITION.** D1 crafts no orders and reads no trading-enable gate, so nothing was raised at a gate and nothing is owed.

---

## TL;DR

- **Exits triggered: none.** All 12 open tranches are Strategy D, which carries no `convergence_target` and no `time_exit_date` by design; no thesis-invalidation criterion is engaged on any of the eight held names.
- **New entry candidates: none routed.** Three names cleared Strategy B's frozen ≥5% floor with a genuine event (GWRE, FICO, LULU) but B is `DO-NOT-ACTIVATE` and capital-disabled, so they land on the watchlist state index rather than as thesis handoffs.
- **Add candidates: none.** All 12 open A/B/D tranches evaluated; 9 declined on evidence, **3 declined at the HARD GATE** (ISRG, RTX, UBER — breach status never assessed anywhere in the record).
- **Watchlist changes: 3 adds** — GWRE, FICO, LULU to the Strategy-B new-entry candidate index, all with 2026-09-04 event dates and windows closing 2026-09-18.
- **Regime review: no.** The +162K payroll print is real evidence against the standing `growth_momentum = decelerating` score, but one month is not a regime break and M1R already ran clean this morning. Default-NO on ambiguity holds.
- **PARK: BOUND KEEP, VOO, `target_f_pct` 0.** The increase gate OPENED for the first time since 09-02 (standing 2 / firing 1 / cap 50) — and is declined, because only ONE axis actually fired.

---

## DEVELOPMENTS

### 1. Market-wide breaking events

**US–Iran escalation, and it happened AFTER the last close — the single most consequential item in this window.** On Friday 2026-09-04 US Defense Secretary Hegseth warned the US "will destroy" Iranian tankers if Iran attacked US ships. Iran then fired missiles at US Navy vessels, and **on Saturday 2026-09-05 CENTCOM confirmed it struck and destroyed three Iranian oil tankers near Kharg Island** ([RFE/RL live blog, entries timestamped 09:50 and 18:42 on 5.9.2026](https://www.rferl.org/a/iran-live-blog-trump-middle-east/33803414.html)). Iranian state media reported Iranian attacks on tankers and US-linked vessels in the Strait of Hormuz the same day ([Euronews, 2026-09-05](https://www.euronews.com/news/2026/09/05/iranian-media-report-us-strike-on-iranian-oil-tanker-near-kharg-island)).

**The market has not traded on any of this.** Friday's close preceded the tanker strikes; Monday is Labor Day. The next opportunity to price it is **Tuesday 2026-09-08** — two calendar days away. Brent already closed Friday at **96.28** (FMP `BZUSD`, pinned), *above* the 95 line the park's shock axis gates on, before the escalation.

**Observable reaction where one exists:** Brent 95.52 → 96.28 (+0.80%) on Friday itself. A widely-circulated third-party figure putting Friday's Brent settle at $91.35 is **contradicted by the pinned `BZUSD` series** and was not used; see the RIG/XLE contradiction recorded under the screens below. Nothing else in the window rises to a market-wide shock: no unscheduled enforcement action, material bankruptcy, or disaster surfaced.

### 2. Scheduled events that resolved in the window

**The August 2026 employment report, Friday 2026-09-04 pre-market — the session's organising event.**

| | |
|---|---|
| Nonfarm payrolls | **+162,000** against a ~53–75K consensus range |
| Unemployment rate | **4.1%**, unchanged |
| Revisions | June/July revised **up** a combined +55K |

**EVENT-IDENTITY GATE, honoured and its limit stated.** The BLS primary release page was **not retrievable** this run (a domain-restricted search of `bls.gov` returned only pre-2026 archived releases). The figures above are therefore **press-reported and NOT primary-source-confirmed**, carried consistently across three sources each explicitly dated 2026-09-04 ([CNBC](https://www.cnbc.com/2026/09/04/jobs-report-august-2026.html), [RealEstateNews](https://www.realestatenews.com/2026/09/04/strong-jobs-report-puts-focus-on-inflation-ahead-of-fed-meeting), [Chosun Biz](https://biz.chosun.com/en/en-international/2026/09/04/KDL4ZP2JARGQVDBT5HQS3QLWRY)). They are recorded with that provenance and are not treated as issuer-confirmed. **A trap worth naming:** the most common prior for "August jobs report" in general sources is a **2025** print of +22K / 4.3% — a different year, and not this event.

**This is a HIKE debate, not a cut debate.** The Fed funds target has been 3.50–3.75% since the start of 2026 and Chair Warsh's Jackson Hole remarks (2026-08-28) had already pushed hike odds up before this window. Governor Waller's 2026-09-03 remarks (inside the window) softened them — CME FedWatch reportedly fell ~63.2% → ~50.4% — and Friday's beat pushed them back up. **Reported post-data hike odds for the 2026-09-15/16 FOMC span ~50–68%** across four sources at different intraday timestamps (Chosun Biz ~50, [Investing.com](https://www.investing.com/analysis/gold-faces-fresh-pressure-as-payroll-surge-boosts-september-hike-odds-200687171) 58, RealEstateNews 60.4, Cointelegraph 68). **Recorded as a range, not a point** — the dispersion is snapshot timing, not a data conflict.

**FDA — one PDUFA resolved in window.** AstraZeneca's **Etcamah (camizestrant) was APPROVED on its 2026-09-04 PDUFA date** ([pdufa.bio calendar, marked "✓ Approved", page updated 2026-09-06](https://www.pdufa.bio/pdufa-calendar)). All other September PDUFA dates on that tracker (Telix 09-11, Nuvalent 09-18, Merck 09-21, Vera/Ionis 09-22, Incyte 09-26, several 09-30) are **PENDING and outside this window** — no outcome figures are populated for any of them.

**Earnings.** Two prints landed Thursday-after-close 09-03 and moved hard on Friday: **GWRE** (Q4 FY26 EPS $0.99 vs $0.85 est. — a beat — yet −19.93%) and **LULU** (Q2 comps −9%, revenue −4%, FY guide cut to $10.35–10.5B from $11–11.15B; −17.38%). Both are recorded under the single-name screen with IBKR-measured reactions. **A separate general earnings-calendar sweep found no other ≥$2B print in this exact window that could be stood behind, and that gap is stated rather than filled** — three searches returned generic, mis-dated or non-US results.

### 3. Large single-name moves — AI-SIGNIFICANCE SCREEN (Operating_Protocols.md §19)

**`universe_measured` 20 · `rail_tally` 20 · `surfaced_count` 10** (= `ARRAY_LENGTH(passed)`, per the 2026-08-30 pin — the rail arithmetic lives in `fields.rail_tally` / `fields.universe_measured`, not in this scalar). Agreement: **both 6 · ai_only 4 · rule_only 6.** Logged: `events.decision_log`, `entry_type='research-screen'`, `screen='single-name-move'`.

**Not a degraded run.** Every discovery leg returned; IBKR resolved and priced all 20 attempted names with **zero symbol-level denials**; every `metric_pct` is from an IBKR regular-session daily bar stamped `13:30:00Z`, never a snapshot.

**PASSED (10):**

| Ticker | Move | Conv. | Why it is significant |
|---|---|---|---|
| **FICO** | **−16.6829%** | **75** | FHFA directive opens GSE mortgage scoring to VantageScore — ends decades of FICO exclusivity. A **permanent moat change**, not a quarter. The most information-dense move of the session. |
| **GWRE** | **−19.9349%** | 60 | EPS beat ($0.99 vs $0.85) yet −20% on guidance/valuation reset — the archetypal beat-and-drop. Held at 60, not 75: part of the move is the same software de-rating that hit PATH/ASAN with no news at all. |
| **LULU** | **−17.3771%** | 60 | Comps −9%, revenue −4%, FY guide cut ~$700M, stock to pre-COVID levels. Genuine deterioration — information-driven, which is exactly what argues *against* a B long. |
| **TSLA** | **−5.9231%** | 60 | NHTSA opened an audit-query investigation into Cybercab robotaxi safety self-certification the day after the Austin launch; Cybercab update underwhelmed. ~$83B of value on an open-ended regulatory clock. |
| **MU** | **+6.0980%** | 60 | A $1.15T name up 6% anchors the day's dominant cross-current — the AI-memory/HBM shortage lifting semis ~3.4% *through* a hawkish rate print. |
| **IREN** | **+7.2749%** | 45 | Neocloud re-rating. The information is the **decoupling**: +7.3% on a day Bitcoin fell ~2%, i.e. repriced as AI infrastructure rather than as a miner. |
| **PCG** | +2.4356% | 45 | *below_spec_floor.* Partial retrace of the 2026-08-31 −20% wildfire-liability crash. Surfaced because PCG sits on the **current** 2026-09-06 B watch-overflow block with 09-14/09-16 legs. |
| **AAPL** | −2.5104% | 45 | *below_spec_floor.* ~**$118B** of value — the largest absolute move in the market. The cited Citi foldable-pricing note is far too thin for that magnitude, and that mismatch is the signal. |
| **INTC** | +4.5052% | 45 | *below_spec_floor.* Semi rally plus a same-day Zacks estimate-revision uptrend. Directional evidence on a live **A-queue** name (added 2026-05-12, 18A/14A foundry ramp). |
| **RIG** | −2.8239% | 30 | *below_spec_floor.* Surfaced **only as a measured contradiction** — see below. |

**REJECTED_NOTABLE (10, of which 6 cleared the legacy 5% bar):** **PATH −16.63%** and **ASAN −12.69%** — no company-specific catalyst for either; high-beta software moving on rate-driven multiple compression is factor flow, not name-level information. **NFLX −5.35%** — no discrete catalyst, no earnings until October. **BMNR −5.60%** — a bitcoin-treasury vehicle tracking BTC −2% with leverage; mechanical. **AEHR +13.10%** — no catalyst, and 13% is ordinary in AEHR's own regime. **BLTE +13.16%** — rejected as **UNATTRIBUTED rather than judged-noise, and the distinction matters**: the offered driver (H.C. Wainwright Buy, $45 PT) is inconsistent with a $193.61 close and was sourced to an aggregator page for a *different* company (TYRA). The move is IBKR-real; the stated cause is not evidence. Plus **SMCI +4.54%, KEEL +3.58%, PLUG +2.84%, NOK +2.66%**, all sub-legacy-bar sector beta or narrative drift.

**A CONTRADICTION, RECORDED RATHER THAN RESOLVED AWAY.** RIG (−2.82%) was reported as tracking crude **down** ~2.5% on 2026-09-04, and the energy sector fell 0.87% — while FMP's `BZUSD` series, *the exact series `bigquery/216` gates the park shock axis on*, has Brent **rising** 95.52 → 96.28 that session. Both cannot be right. The park call took `BZUSD` as authoritative (it is the named gating series, and its 2026-09-01 value of 94.65 independently matches this system's own prior record). The disagreement is logged in both screens so it is queryable rather than lost.

**Discovered but NOT confirmed — every one named, never rendered as absence.** Below the $2B cap rail on an FMP `profile-symbol` check: **OXM** $460.9M (real event — Q2 beat, guide cut, −15.7%), **NX** $1.05B (+22.2%), **TYRA** $1.71B (second-sourced at $1.5–2.06B across Yahoo/Robinhood/Morningstar, so genuinely below rail and not an FMP share-count artifact, checked per the ~30%-proximity caveat), **AIFU** $111M, **ALTI** $445M. Moved ≥2% but **NOT pursued on time budget** — explicitly not dropped for want of a second source: **MARA** (−2.5% on FMP most-active, plausible ≥$2B, plausible BTC-weakness event) — unmeasured, and stated as unmeasured. Excluded **by inspection without a check** (an inference, not a verified exclusion): ~70 sub-$1 / shell / SPAC / micro-cap-ADR tickers off the gainers-losers tails. Below the 2% rail: F +1.46, AAL +1.23, NU −1.98, CDE −1.89, PL −1.25, ATER +1.28, BTBT +0.61, AVGO +0.21, ONDS −0.13.

### 4. Sector-level moves — AI-SIGNIFICANCE SCREEN (§19)

**`universe_measured` 11 · `rail_tally` 3 · `surfaced_count` 5** (2 via the sub-net escape valve). Agreement: **both 0 · ai_only 5 · rule_only 0** — **zero sectors cleared the legacy ≥2% bar**, so on the old fixed rule this screen would have surfaced nothing at all. Logged as `screen='sector-move'`. All eleven measured from IBKR RTH daily bars.

| Sector ETF | 09-03 | 09-04 | Move |
|---|---|---|---|
| XLY Cons. Discretionary | 116.46 | 114.91 | **−1.3309%** |
| XLC Comm. Services | 113.38 | 112.03 | **−1.1907%** |
| XLV Health Care | 173.26 | 171.45 | **−1.0447%** |
| XLE Energy | 64.62 | 64.06 | −0.8668% |
| XLP Cons. Staples | 85.26 | 84.58 | −0.7976% |
| XLF Financials | 58.56 | 58.10 | −0.7855% |
| XLRE Real Estate | 44.25 | 43.93 | −0.7232% |
| XLB Materials | 52.62 | 52.44 | −0.3421% |
| XLU Utilities | 43.03 | 43.08 | +0.1162% |
| XLI Industrials | 174.56 | 175.27 | +0.4068% |
| XLK Info Technology | 185.97 | 187.28 | **+0.7044%** |

Benchmarks: SPY **770.19 (−0.3855%)**, VOO 708.01 (−0.3813%), QQQ +0.1798%, DIA −0.5309%, IWM +0.2778%, **RSP −0.4772%**, SGOV +0.0398%. (SPY and VOO agree to 0.004pp — a data-quality check that passed.)

**Counts COMPUTED from the eleven measured moves, not asserted: 3 higher, 8 lower.** Dispersion **2.0353pp**. Rail clearers (≥1%): XLY, XLC, XLV.

**It is NOT a defensive rotation** — XLV (−1.04%), XLP (−0.80%) and XLRE (−0.72%) were all firmly negative and only XLU managed +0.12%. **It is not risk-on either**: 3 of 11 advanced, and equal-weight **RSP underperformed cap-weight SPY by 0.092pp**, so the average constituent did worse than the index.

**The session's real signal is a SPLIT INSIDE GROWTH.** XLK was the best sector while XLC — its closest growth cousin, ~40% Meta+Alphabet — was second-worst: a **1.895pp gap** no cyclical-vs-defensive or growth-vs-value story explains. The market repriced the *discount rate* for software (GWRE −19.9%, PATH −16.6%, ASAN −12.7%) and the *earnings path* for silicon (PHLX Semi ~+3.4%, MU +6.10%, INTC +4.51%) on the same day, in opposite directions. XLK is surfaced sub-net for exactly this reason: a mechanical 1% bar cannot see a spread.

**XLY decomposes rather than aggregates** — it is essentially TSLA and LULU, both already surfaced individually. **XLV clears the rail but its driver was NOT FOUND** across two dedicated searches; it is surfaced at conviction 30 with the gap stated rather than back-filled with a plausible cause.

### 5. Notable commentary

- **Fed Gov. Christopher Waller, 2026-09-03** — data-dependent and moderate: would back a hold if disinflation continues, open to a hike if progress stalls. Moved CME hike odds down ~13pp before Friday's data reversed it.
- **NY Fed's Williams** tied rising bond yields to a strong economy (2026-09-02, just outside the window; included for continuity of the hike-odds narrative).
- **Jefferies** published a quantitative gold framework targeting **$4,650/oz by year-end**.
- **Bank of Canada** held at 2.25%, flagging tariff risk to growth (2026-09-02).
- Commentary broadly framed Friday as *"a hawkish jobs beat re-opening the hike debate right before the September 16 FOMC."*

---

## ANALYSIS — RISK TO EXISTING POSITIONS

### MECHANICAL EXIT-TRIGGER SWEEP — swept the UNION, zero triggers

**Union established first (self-improvement audit ITEM 14).** `state.current_positions` holds **12 open tranches across 8 names, all Strategy D**. Live IBKR `get_account_positions` returns the same 8 names plus the VOO park sleeve and a zero-quantity SGOV row. **Share counts reconcile EXACTLY on all eight:** AMZN 0.191+0.1554=0.3464 · DIS 0.2822+0.4422=0.7244 · GEV 0.1244 · GOOGL 0.1043+0.1534=0.2577 · ISRG 0.1091 · RTX 0.1601 · TSM 0.0659+0.0891=0.155 · UBER 0.5156.

**No position exists in the connector that is absent from BigQuery. ZERO reconciliation-lag positions; no `position_reconciliation_lag` alert is owed.**

**Convergence targets and time exits: all twelve tranches carry `convergence_target = NULL` and `time_exit_date = NULL`.** That is Strategy D operating as designed — a long-horizon, no-stop, open-ended-downside book whose exits are thesis-invalidation events, not price levels or dates. So the mechanical sweep is a **structural** no-trigger, not an unchecked one. **No `DIVIDEND NETTING` test is owed either**: that rule binds only a criterion naming a PRICE LEVEL, and no open position carries one.

**EXITS TRIGGERED: NONE.**

### PER-STRATEGY KILL-TRIGGER SWEEP

`perf.kill_flags` carries two strategies. **All flags FALSE on both.**

| | Strategy D (as_of 2026-09-03) | Strategy B (as_of 2026-08-18) |
|---|---|---|
| deployed unit value / peak | 1.06957 / 1.09811 | 1.18406 / 1.23243 |
| `current_drawdown` | **−2.599%** | −3.925% |
| `excess_vs_sgov` | **+5.586%** | +17.083% |
| deployed_days / closed_trades | 91 / 1 | 79 / 13 |
| drawdown_kill · runaway · m2m · interim_underperf | all FALSE | all FALSE |

**UNCONDITIONAL live-mark drawdown refresh — performed, not skipped, and quantified.** The engine row is Thursday's; D2a has not run since. Refreshed against Friday 2026-09-04 closes from the live IBKR book: Strategy D market value **$547.82** against cost **$542.56**, unrealized **+$5.26**, and the D book's own Friday P&L was **−$1.36** (AMZN −0.14, DIS −1.34, GEV +0.01, GOOGL −0.91, ISRG −0.34, RTX −0.21, TSM +1.70, UBER −0.13) — about **−0.25%** on market value. That moves the refreshed drawdown to roughly **−2.85%**, against a **−50%** kill threshold. **Not close, and now measured rather than assumed.**

- **Drawdown kill (#1):** NOT triggered. −2.85% refreshed vs −50%.
- **Runaway-success (#3):** NOT triggered. D's deployed TWR is 1.0696, nowhere near doubled.
- **Interim underperformance warning:** FALSE for both. D has cleared the 90-day mark (91 days) but `excess_vs_sgov` is **+5.586%**, comfortably above the −15% bar. **No `interim_underperf_warning` alert is owed, and none is open to heal-resolve.**
- **B open-book pairwise correlation (KL #12):** `analytics.b_pairwise_correlation` returns `n_positions = 0`. **A structural no-op, not a passed test** — B holds nothing at all, so `n_positions >= 2` fails on an empty book rather than on a low correlation. (Note for the record: the plan text still describes B as holding a single MDT position; the live book has been empty since.)

### Thesis-invalidation review, per open name

No Development in this window touches any Strategy-D invalidation metric. The theses are written against AWS growth/margin/backlog, Disney SVOD margin and buyback pace, GEV organic orders, Google Cloud revenue/margin/RPO, da Vinci procedure growth and placements, RTX backlog and FCF guide, TSMC gross margin and sub-7nm mix, and Uber gross bookings and Uber One. **The window's substance is one macro print and one geopolitical escalation. Neither is evidence on any of those metrics.**

| Name | Development bearing on it? | Criterion met? |
|---|---|---|
| AMZN (2 tranches) | None | **NO** — no AWS disclosure in window |
| DIS (2) | None | **NO** — all five criteria affirmatively unbreached at the Q3 FY26 checkpoint (SVOD margin ~13%, FY26 ~12% EPS growth reiterated, buyback raised to ≥$9B) |
| GEV | None | **NO** — organic orders 88% at entry against a 15%-for-2-quarters bar; enormous headroom |
| GOOGL (2) | Fell with long-duration growth (XLC −1.19%); **no Alphabet-specific catalyst found in two dedicated searches** | **NO** — factor flow, not Cloud information |
| ISRG | None | **NO** on evidence — but see the HARD GATE finding below |
| RTX | None | **NO** on evidence — but see the HARD GATE finding below |
| TSM (2) | Semi rally (+1.70 daily P&L, the book's best) | **NO** — sector beta, no TSMC disclosure |
| UBER | None | **NO** on evidence — but see the HARD GATE finding below |

### Watchlist candidates — status changes

**MU (+6.10%)** and **INTC (+4.51%)** are both live A-queue names and both moved materially on the AI-memory/semiconductor bid; that is **directional confirmation of their queued theses**, not a change of candidacy status — A remains `DO-NOT-ACTIVATE`, so neither moves closer to entry in any operative sense. **PCG (+2.44%)** sits on the current B watch-overflow block and partially retraced its 08-31 crash; candidacy **unchanged but better-supported**. No queued name was invalidated.

---

## ANALYSIS — OPPORTUNITY CHECK

Scoped to roster-active strategies carrying `review_cadence: reactive` — **A, B, C, E** (D is `long_horizon` and excluded here). Router state as of 2026-09-03: **A, B, D, E all `DO-NOT-ACTIVATE`; C is `HYBRID ACTIVATE (FOMC-only)`** — and per `ops.alerts` e2eb2990 the capital-enabled set is **`[C]`** with A, B, D, E all capital-disabled.

**Strategy B — three names clear the frozen ≥5% floor with a genuine qualifying event, none can be routed.**

| Ticker | Move | Criterion-1? | Criterion-3 convergence anchor | Disposition |
|---|---|---|---|---|
| **GWRE** | −19.93% | ✅ | Next earnings (Q1 FY27, ~Dec) — a strictly enumerated event inside 60d? **Borderline** | **Watchlist add.** The strongest B shape of the session: a beat that sold off 20%, which is precisely the over-/under-reaction question B exists to ask. |
| **FICO** | −16.68% | ✅ | **No clean 60-day anchor** — the FHFA outcome has no scheduled date | **Watchlist add**, with criterion 3 flagged as the weak leg. Also the most likely to be *correctly* priced: a permanent moat loss is information, and B wants mispricing. |
| **LULU** | −17.38% | ✅ | Next earnings (~Dec) | **Watchlist add.** Classic shape, but the guide cut is information-driven, which cuts against the thesis before it is written. |
| TSLA | −5.92% | ✅ | **None** — NHTSA timeline is open-ended | **Declined**, fails criterion 3. |
| MU | +6.10% | ✅ | — | **Declined.** A B thesis here is a *short* into an AI-memory shortage. B has never gone short (0 of ~108 theses) and D2 has declined short-direction B four times (SHOP, PYPL, CDW, MGM) on exactly this regime ground. |
| IREN | +7.27% | ✅ (magnitude) | **None** | **Declined** — a momentum re-rate, not a discrete public event with a convergence anchor. |

**No `thesis` action is emitted for any of the three, and that is deliberate.** A thesis handoff would create a queue item Strategy B cannot fund (capital-disabled, $0 NAV) and cannot trade (router `DO-NOT-ACTIVATE`). The **Strategy-B new-entry candidate state index in `Watchlist.md` is the designed venue for a router-gated period** — it is where every prior D1-sourced B cohort landed (the 08-18/08-20, 08-21, 08-24 and 08-25 cohorts). These three go there.

**Strategy C — the one live setup already exists, and it has a problem D1 does not own.** The **FOMC is 2026-09-15/16, ten days out**, squarely inside C's 45-day catalyst horizon, and C is the only capital-enabled, router-activated strategy. Queue item **`thesis-FOMC-C-20260908` (due 2026-09-08) already exists**; re-flagging it would duplicate it, so no new action is raised. **But D2 should read this before draining it on Tuesday:** per `ops.alerts` **e2eb2990** (W3, 2026-09-06), that item's own context asserts C can borrow an uncapped amount citing donor E with `donor_capacity` 15,309.94 and `is_fully_funded` TRUE — **measured on 2026-08-16, and false since E went capital-disabled on 2026-09-04.** `fn_nomadic_capital_restore_plan(C, 500.0)` now returns **zero rows**, and C holds **$23.64**. Friday's jobs beat is directly material to the thesis (hike odds ~50–68%), so the item is more live than ever — and less fundable. **This is out of D1's scope and already recorded by its owner; surfaced here only because D2 reads this file and acts on Tuesday.**

**Strategy A — no candidate.** A requires an identified catalyst within 6 months. Nothing in this window announces one. FICO's FHFA directive is a structural *loss*, not a forward catalyst, and A is long-only.

**Strategy E — no candidate, one piece of ideation evidence.** The XLK/XLC split (+0.70% vs −1.19%) and the semis-vs-software divergence (MU +6.10% / INTC +4.51% against PATH −16.63% / ASAN −12.69%) are the sharpest intra-growth dispersion in weeks. But E requires both legs in the **same GICS industry group (6-digit)** with trailing-252d correlation ≥0.5, and pair generation is M2's monthly job. **Recorded as E ideation context for M2, not raised as a D1 candidate.**

---

## ANALYSIS — ADD-CANDIDATE CHECK (Strategies A, B, D only)

**12 open tranches evaluated · 0 flagged · 9 declined · 3 declined at the HARD GATE.** Durably logged as one `events.decision_log` row, `entry_type='add-candidate-review'`, and verified to parse into `state.add_candidate_reviews` as 12 item rows with every column populated.

**Zero adds, for three independent reasons — any one sufficient:**

1. **Nothing in this window touches a Strategy-D thesis metric** (see the invalidation table above).
2. **The dips are ordinary mark-to-market, and each thesis says so in its own words.** The four negative tranches — GOOGL:2026-07-09 **−5.87%**, DIS:2026-05-07 **−5.40%**, GEV:2026-08-03 **−2.88%**, AMZN:2026-07-30 **−2.70%** — moved inside a −0.39% index session with no name-level news. D:DIS:2026-08-05's `not_exit_triggering` field reads *"ordinary adverse mark-to-market with no new information, or general market moves"*; D:GEV lists *"short-term price action"* the same way. **A move a thesis explicitly refuses to treat as exit evidence is not, by symmetry, add evidence.**
3. **D is router-gated OFF and capital-disabled** — context, not the reason. Reasons 1 and 2 stand on thesis evidence alone, and this sweep is record-only regardless.

### HARD GATE — 3 tranches structurally ineligible, and this is the finding of the sweep

**Seven of twelve tranches carry `invalidation_status.breach_status = 'NOT_ASSESSED_BY_THIS_BACKFILL'`** — the `bigquery/117` mirror transcribed each thesis's criteria verbatim but explicitly did not assess them: D:AMZN:2026-07-09, D:DIS:2026-05-07, D:GOOGL:2026-07-09, D:ISRG:2026-07-20, D:RTX:2026-04-27, D:TSM:2026-07-21, D:UBER:2026-07-09.

**Four of those seven are covered at NAME level** by a later tranche carrying a fresh assessment of the same inherited criteria — AMZN (07-30, all five re-verified against a six-quarter SEC-sourced AWS series), DIS (08-05, all five UNBREACHED at the Q3 FY26 checkpoint), GOOGL (07-26, a/b/c/d unbreached), TSM (07-29, UNBREACHED with measured GM 67.7% / USD rev +33.7% / sub-7nm 77%). GEV needs no inheritance (`assessed_fresh_not_inherited: true`).

**Three names have no fresh assessment anywhere in the record: ISRG, RTX, UBER.** Each is a single tranche whose only breach-status field says it was never assessed. Under the gate all three are ineligible for an add **regardless of how good a case might be made** — the same shape as the 2026-07-28 D:DIS/D:TSM finding this durable log exists to make countable. Notably **RTX is the book's best performer at +13.51%** and is barred by a record-keeping gap, not by its thesis.

**A defect in this record's own field contract, found while writing it and referred out rather than papered over.** `invalidation_criteria_evaluable` is defined FALSE when `invalidation_status IS NULL` **or** `$.status = 'NOT_DISCRETELY_RECORDED_AT_ENTRY'`. Applied literally — with the mandated `COALESCE(…, '')` wrapper so the healthy case yields TRUE not NULL — it returns **TRUE for all twelve, including the three just declined at the gate**, because none carries a `$.status` key at all while seven record the gap under a *different* key (`$.breach_status`) the rule never tests. **That is the same ambiguity the field exists to expose, re-hidden through a key the rule does not look at, and in the same direction as the IS-NULL mistake its own spec warns against.** The field was written per the rule **as specified** (silently redefining a contract mid-record is worse than reporting a known-limited one); the gap is carried in `disposition` and in `fields.breach_status_unassessed` / `breach_status_uncovered_names`, and referred to the owning spec surface at `ops.alerts` category **`add_review_evaluable_misses_breach_status`** with a proposed one-line fix.

### Per-tranche dispositions

| Tranche | Mark vs cost | Disposition |
|---|---|---|
| D:RTX:2026-04-27 | **+13.51%** | declined_hard_gate |
| D:TSM:2026-07-29 | +8.93% | declined |
| D:AMZN:2026-07-09 | +7.16% | declined |
| D:ISRG:2026-07-20 | +4.92% | declined_hard_gate |
| D:UBER:2026-07-09 | +3.41% | declined_hard_gate |
| D:GOOGL:2026-07-26 | +3.32% | declined |
| D:DIS:2026-08-05 | +1.47% | declined |
| D:TSM:2026-07-21 | +0.03% | declined |
| D:AMZN:2026-07-30 | −2.70% | declined |
| D:GEV:2026-08-03 | −2.88% | declined |
| D:DIS:2026-05-07 | −5.40% | declined |
| D:GOOGL:2026-07-09 | −5.87% | declined |

Marks are IBKR position marks read 2026-09-06 (Friday closes); cost per share is each tranche's own `cost_basis / shares`, commission included, so these understate gross price change very slightly and consistently.

---

## ANALYSIS — REGIME CHECK

**NO inter-monthly router review recommended.** High bar; default-NO on ambiguity — and this is genuinely ambiguous, so the argument on the other side is stated rather than suppressed.

`state.current_regime` FUNDAMENTAL_AXIS (as_of 2026-09-01) reads *decelerating growth + disinflation + hawkish tightening bias + risk-on + acute shock*. **Friday's print cuts directly against one of those five axes**: +162K payrolls against a ~53–75K consensus, with June/July revised **up** a combined 55K, is evidence against `growth_momentum = decelerating`, and it is not a marginal miss — it is roughly triple consensus.

**It still does not clear the bar, for reasons that are about evidence weight, not convenience:**
- **One month is one month.** A single payroll print — press-reported and not BLS-primary-confirmed this run — against a monthly-scored axis is exactly the sample size the monthly cadence exists to smooth. M1a re-scores ~2026-10-01.
- **M1R already ran twice this window** (2026-09-05 and 2026-09-06 07:14 MT), and both were clean gate no-ops with **zero open `PENDING_REGIME_REFRESH` items**. The out-of-cycle mechanism is live, was exercised hours ago, and found nothing.
- **Nothing about strategy ACTIVATION would change.** A, B, D and E are `DO-NOT-ACTIVATE` and capital-disabled; C is FOMC-activated and its catalyst is already queued. A `growth_momentum` re-score would have to flip several downstream gates before it moved a single order — it is a scoring question, not an activation one, this week.

**Recorded here so the next M1a inherits the observation rather than rediscovering it.** If the September print corroborates, the axis is stale and should be re-scored on cadence.

---

## EQUITY-BREADTH OBSERVATION

**Written: `events.regime_events`, `scope='TECHNICAL_INPUT'`, `key='EQUITY_BREADTH_PCT'`, `as_of_date = 2026-09-04`, `numeric_value = 64.01`, `value = 'EODData $S5TH'`.**

**Value 64.01% of S&P 500 constituents above their own 200-day SMA, for Friday 2026-09-04.** `date_attribution = source_dated` — **not** `inferred_post_close`; every source states its own session date, and this Sunday fetch sits >48h after the close, so settlement lag cannot apply.

**Three independent sources agree EXACTLY — max spread 0.00pp, against a 5pp no-write threshold:**
1. **EODData `$S5TH`**, direct cache-busted `WebFetch`, the only clean *direct* fetch of the four sources tried: *"Date: 04 Sep 26, Timestamp: 15:58, Open 63.81, High 64.81, Low 63.81, Close 64.01"*. The unsettled-bar tell does **not** apply — Low (63.81) ≠ Close (64.01).
2. **Investing.com** historical table: *"Sep 04, 2026 | Price 64.01 | Open 63.81 | High 64.81 | Low 63.81 | Change % −3.60%"* — identical OHLC.
3. **Barchart `$S5TH`**, search-index snippet only: *"64.01 −2.39 (−3.60%) 22:19 ET [INDEX]"* under its own header *"Barchart Opinion for Fri, Sep 4th, 2026"*.

**Prior session 66.40**, and Barchart's −2.39 point change backs out to exactly 66.40 — independent corroboration of the day-over-day step.

**Sources tried and FAILED, named rather than omitted.** **MacroMicro series 22718 — the designated PREFERRED PRIMARY — returned `Failed to fetch url` on a cache-busted `tavily_extract`. That is the SEVENTH consecutive failure since 2026-08-19.** Already recorded at `ops.alerts` **b4fe8d88** (`breadth_primary_source_persistently_unreachable`, open); **deliberately NOT re-raised** — an open alert on an unchanging condition is the alarm fatigue the fleet's alert discipline exists to prevent. **Barchart's direct `WebFetch` returned EMPTY content on both `/overview` and `/opinion`** (JS-render gate), so Barchart contributed via search snippet only and is **not** counted as a live-fetch source this run. Per the fetch-method-is-provenance rule, both Barchart paths were tried before writing it down.

**This number crosses a threshold, and it is the pivot of the park call below.** `bigquery/216` scores the breadth axis defensive at **< 66**. 2026-09-03 read 66.40 (not defensive); 64.01 is therefore an axis **ENTRY**, i.e. a firing. Writing this row is what flipped `state.park_axis_daily` for 2026-09-04 from `standing 1 / firing 0 / cap 25 / gate CLOSED` to **`standing 2 / firing 1 / cap 50 / gate OPEN`** — verified by re-reading the view after the write.

---

## PARK ALLOCATION CALL

**`vehicle`** — **VOO** (KEEP). `target_f_pct` **0** · risk sleeve VOO · defensive sleeve SGOV. `direction` **keep**. `status` **BOUND**. Position unchanged: 21.4714 sh VOO, $15,194.45, against account NLV $15,837.41.

**`conviction`** — **MEDIUM, `conviction_pct` 60.**

**`rationale`** — The mechanical increase gate **opened this session for the first time since 09-02**, and it opened because of a row this run wrote. `state.park_axis_daily` for 2026-09-04 now reads `standing_defensive_count = 2`, `firing_count = 1`, `cap_pct = 50`, `increase_gate_open = TRUE`. **I decline the increase, because only ONE axis actually fired.**

*Every one of the six axes was re-measured fresh this run* — necessary, because `axes_measured_today = 1` (only breadth is same-session; D2a does not run Friday or Saturday, so the four price-derived axes carry 09-03):

| Axis | Fresh 09-04 reading | Defensive? | Firing? |
|---|---|---|---|
| volatility | VIX **14.53** (IBKR, the spec's PRIMARY; prior 14.32) | NO — rule is >20d SMA **and** >15 | no |
| breadth | **64.01** (prior 66.40) | **YES** (<66) | **YES — entry** |
| index | SPY **770.19**, above 50dma 756.14 and 200dma 711.63; dd from 252d high **−0.989%** | NO (bar is −3%) | no |
| credit | no fresh HYG/IEF mark; `hy_oas` 2.85 (FRED, July) | NO | no |
| shock | overlay **acute** AND Brent **96.28** (FMP `BZUSD`, prior 95.52) | **YES**, and confirmed fresh | **no — standing since 09-02** |
| rates | 10Y **4.78** (+1bp), 30Y **5.24** (−1bp), 2Y **4.37** (+3bp), 2s10s +0.41 | NO | no |

**Every carried axis was confirmed by fresh measurement in the same direction the view already had** — so the count rests on measured data, not stale data. Two corrections the readings forced: third-party wraps put the 10Y at 4.79 "+2bp" and Brent settling at $91.35; the pinned series say the **30Y FELL 1bp** while the 2Y rose 3bp (a front-end bear-flattening, not a rates shock) and Brent **ROSE** to 96.28. Taking the prose figures would have scored rates as deteriorating and shock as healing — **both backwards.**

**Two axes stand defensive, but the second contributed no new information.** Shock entered on 09-02; a standing state is never news. The cardinality rule asks for **two independent axes firing in the same session** and that is not met. The ratchet is explicit that the mechanical count "may NEVER upgrade a KEEP into a conversion, nor a one-axis call into a two-axis one" — naming this exact scenario.

**The arithmetic I am declining, stated rather than omitted:** conviction 60% × cap 50 = **30** → nearest step = **25** (30 sits 5 from 25, 20 from 50) — roughly $3,800 to SGOV. **DECAY: f is at 0, the floor; the clamp runs downward toward the cap and 0 is under every cap, so no step is owed and none is taken.**

**Breadth alone does not carry it because breadth is oscillating on its own threshold, not breaking:** 08-31 66.20 (not-D) → 09-01 62.62 (D) → 09-02 64.21 (D) → 09-03 66.40 (not-D) → 09-04 64.01 (D). **Three crossings of the 66 line in five sessions.** The one genuine deterioration underneath — 8 of 11 sectors lower, RSP trailing SPY by 0.092pp — *is the same fact the breadth print reports*, which is precisely the double-count the cardinality rule refuses. And the record is unambiguous: 2026-09-01 fired on one axis, de-risked ~97% of NAV at MEDIUM-60, and cost **$214.32** in two sessions; both closed defensive excursions of the AI era lost ground (−2.841pp, −1.019pp); across 15 historical episodes the defensive signal averaged **−0.638pp** forward edge and won 4 of 15.

**This KEEP is not free, and the cost is named:** the park sits fully in VOO across two calendar days of **unpriced** Hormuz escalation (three Iranian tankers destroyed 09-05, Iranian attacks on Hormuz shipping the same day), with Brent already above the shock axis's line before it happened. That risk is accepted deliberately, because the alternative is the move this system has now measured losing twice.

**`invalidation`** — Disjunctive, and at the same bar as the evidence justifying full VOO, in **both** directions. This KEEP flips to a de-risk on the first session where a **second independent axis ENTERS defensive** alongside breadth — any one of: **volatility** (VIX >15 *and* above its own 20d SMA); **index** (SPY below the 50dma ~756, or >3% below the 252d high 777.88); **credit** (HYG/IEF ≥50bp under its 20d SMA); or **rates** on a genuine break rather than a range trip (30Y sustained above ~5.40%, or a September hike delivered or priced above ~85%). **Shock is explicitly excluded as the second axis** — already standing defensive, so a Brent gap deepens it without creating an event. Independently, the **crisis override carries alone and same-day**: a single-session index move ≤ −2.5% or VIX ≥ 28 lifts the cap to 100. **Symmetrically, nothing here binds a later session:** breadth simply printing ≥66 again retires the watch with no further evidence required — exactly as cheaply as it was raised.

**`theater_check`** — The rationale argues *against* the direction the mechanical gate just opened, and it names the one number a foregone-conclusion write-up would have quietly omitted (cap 50 × 60% = 30 → step 25). The KEEP's own cost — full equity exposure into an unpriced weekend escalation — is stated rather than buried.

`fields.park_watch = true`, `fields.watch_axis = 'breadth'`. Heartbeat written to `ops.heartbeat` (`source='loop:park_allocator'`).

---

## FRONTIER-LLM CAPABILITY CHECK

Ran (Sunday slot: long-context). **Nothing material** — all five results predate the 2026-09-03 window lower bound, so no `[HF Frontier-LLM Capture]` entry and no `state.strategy_candidates` row is owed. Reference-only regardless; D1 does not act on this today.

**One thing this closes.** `ops.alerts` **680bb77a** (`hf_paper_search_unreachable`) recorded three consecutive `hf_fs` timeouts on the 2026-09-03 run and named its own resolve condition: a first observation, explicitly not a standing constraint, escalating to OPS1 only if a later run reproduced the signature. **It did not — the call returned a full payload on the first attempt, zero timeouts, no ladder.** The alert is resolved on that evidence, not aged out.

---

## RECOMMENDED ACTIONS

**Three actions, all watchlist.** The empty categories are closed in the paragraph *below* the action list, deliberately as prose rather than as list items, so the bullet count here matches the `d1_actions` block exactly.

- **Watchlist add — GWRE (Strategy B new-entry candidate index).** Guidewire, qualifying event 2026-09-04, IBKR-measured **−19.9349%** close-to-close (202.86 → 162.42), clears B's frozen ≥5% floor. Q4 FY26 EPS $0.99 vs $0.85 estimate — a **beat** — that sold off 20% on a guidance/valuation reset; the over-/under-reaction question B exists to ask. 10-day entry window closes **2026-09-18**. Not routed as a thesis handoff: B is `DO-NOT-ACTIVATE` and capital-disabled. Source screen: `research-screen` / `single-name-move`, 2026-09-06.
- **Watchlist add — FICO (Strategy B new-entry candidate index).** Fair Isaac, qualifying event 2026-09-04, IBKR-measured **−16.6829%** (1118.93 → 932.26), clears the ≥5% floor. FHFA directive opening GSE mortgage scoring to VantageScore ends FICO's exclusivity. **Criterion 3 flagged as the weak leg on arrival** — the regulatory outcome has no scheduled date, so no clean 60-day convergence anchor exists, and a permanent moat loss is the kind of event B should suspect is *correctly* priced. Window closes **2026-09-18**. Not routed: B gated off.
- **Watchlist add — LULU (Strategy B new-entry candidate index).** Lululemon, qualifying event 2026-09-04, IBKR-measured **−17.3771%** (121.77 → 100.61), clears the ≥5% floor. Q2 comps −9%, revenue −4%, FY guide cut to $10.35–10.5B from $11–11.15B. Convergence anchor: next earnings (~Dec). Flagged on arrival as information-driven rather than sentiment-driven, which cuts against the thesis before it is written. Window closes **2026-09-18**. Not routed: B gated off.

**Closures, stated as prose so they are not counted as action bullets.** *Exits:* none exist to take — Strategy D carries no mechanical triggers by design and no invalidation criterion is engaged on any of the eight held names. *Adds:* none — all 12 open A/B/D tranches evaluated, 9 declined on evidence, 3 (ISRG, RTX, UBER) declined at the HARD GATE for breach status never assessed. *A entries:* none — no catalyst inside 6 months was announced in window. *C entries:* the one live FOMC setup is already queued as `thesis-FOMC-C-20260908`; re-flagging would duplicate it — **but D2 should read the `nomadic_borrow_blocked_unsignalled` note in the Opportunity Check above before draining it on Tuesday.** *E entries:* the semis-vs-software divergence is genuine but pair generation is M2's monthly job and E requires same-industry-group legs; recorded as M2 ideation. *Watchlist removes/demotions:* none owed. *Router review:* **no** — see the Regime Check for the `growth_momentum` argument on the other side and why it does not clear the bar.

**The park call above is a BOUND KEEP and changes nothing for D2** — `state.park_allocation_latest` returns `vehicle = VOO`, which equals today's `state.park_policy_current.vehicle`, so D2's PARK ALLOCATION CONVERSION step correctly no-ops.

```yaml d1_actions
- action: watchlist
  ticker: GWRE
  strategy: B
  qualifying_event_date: 2026-09-04
  source_research_screen_id: research-screen single-name-move 2026-09-06
  detail: ADD to Strategy-B new-entry candidate index — beat-and-drop, IBKR −19.9349% on 2026-09-04, clears the frozen ≥5% floor; 10-day window closes 2026-09-18; NOT routed as a thesis handoff because B is DO-NOT-ACTIVATE and capital-disabled
- action: watchlist
  ticker: FICO
  strategy: B
  qualifying_event_date: 2026-09-04
  source_research_screen_id: research-screen single-name-move 2026-09-06
  detail: ADD to Strategy-B new-entry candidate index — FHFA/VantageScore moat event, IBKR −16.6829% on 2026-09-04; criterion 3 flagged weak on arrival (no scheduled convergence anchor inside 60 days); window closes 2026-09-18; NOT routed, B gated off
- action: watchlist
  ticker: LULU
  strategy: B
  qualifying_event_date: 2026-09-04
  source_research_screen_id: research-screen single-name-move 2026-09-06
  detail: ADD to Strategy-B new-entry candidate index — Q2 miss plus FY guide cut, IBKR −17.3771% on 2026-09-04; flagged information-driven rather than sentiment-driven; window closes 2026-09-18; NOT routed, B gated off
```

---

## RUN NOTES

**Metered spend, reported honestly including its own defect.** 73 metered calls this run, batched into `ops.web_calls`: 42 Tavily (40 search, 2 extract, ~42 estimated credits), 28 FMP (3 `marketPerformance`, 25 `company/profile-symbol`) plus 2 orchestrator FMP calls (`economics/treasury-rates`, `commodity/BZUSD`), 3 Anthropic `web_fetch`, 1 HF `hf_fs`. **The SEARCH PROTOCOL was violated by the single-name sub-agent and the violation is recorded rather than smoothed over:** roughly **six** of its 17 searches were narrow siblings re-asking a subject already searched (FICO, IREN, Nokia, PG&E, Plug/Bitfarms, Lululemon), each of which a wider re-issue of the first search would have retired for the same one credit. Those rows are tagged `[SIBLING …]` in `ops.web_calls.target` so the W5 EXTERNAL-SPEND DIGEST can count them directly. The sector sub-agent did it correctly — its second search is tagged `[WIDENED re-issue …]`.

**Findings referred out of scope** (recorded, not fixed here): `add_review_evaluable_misses_breach_status` (info, owner W5 spec surface — a one-line disjunct fix is proposed in the alert payload). **Findings closed in scope:** today's two `research-screen` rows are written to the conforming key contract that `state.research_screen_calls` actually parses, verified by re-reading the view — every item row on both screens has `name`, `metric_pct`, `conviction`, `conviction_pct`, `reason`, `below_spec_floor` and `legacy_rule_pass` populated, plus `market_cap_usd` / `qualifying_event_date`, with `population_rail`, `legacy_rule` and all three `agreement.*` counts set. That closes `ops.alerts` a9013b97 (`screen_fields_schema_drift`, W2 2026-09-06) for this run's rows; the four drifted spellings it measured (`ticker`, `move_pct`, `significance_conviction`, `driver`) are not used.

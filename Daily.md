2026-09-08
<!-- d1_scan_through_utc: 2026-09-08T22:40:00Z -->

# Daily Market Development Scan — 2026-09-08 (Tue, MT)

**Scan window: 2026-09-07 16:20 MT → 2026-09-08 16:40 MT** (24.3h — an ordinary single-cycle window, no gap. Resolved from the prior `Daily.md`'s `<!-- d1_scan_through_utc: 2026-09-07T22:20:00Z -->` marker, cross-checked against that file's own commit at 2026-09-07T22:35:19Z; the two agree to within fifteen minutes, well inside one session's length.)

**ONE completed US trading session inside this window: Tuesday 2026-09-08, the first session after Labor Day.** `state.trading_day_today` gives `is_trading_day = true`, `last_trading_day = 2026-09-08`. The prior close is **2026-09-04** — every close-to-close figure in this file is measured 09-04 → 09-08, and 09-07 correctly appears in no series.

**Tape.** SPY 770.19 → 765.96 (**−0.5492%**), VOO −0.5665%, QQQ −0.0835%, DIA −1.1328%, IWM −0.4527%, SGOV +0.0100%. VIX 14.53 → **15.72** (+8.19%). Brent 96.28 → **99.39** (+3.2302%), WTI above $93. 2Y 4.37 → 4.39, 10Y 4.78 → **4.80**, 30Y 5.24 → 5.25. Equity breadth ($S5TH) 64.01 → **60.63**. All equity/ETF figures are IBKR regular-session daily bars (`get_price_history`, `step='ONE_DAY'`, `outside_rth=false`), every series carrying a 2026-09-08 bar stamped `13:30:00Z`.

**Nothing about this run is degraded, and that is measured rather than claimed.** 35 single names and 17 ETFs/indices were put to IBKR for confirmation; **all 52 resolved and all 52 carried a genuine 2026-09-08 regular-session bar. Zero confirmation failures, zero symbol-level denials.** So `surfaced_count` below is an affirmatively established figure, never a reported zero standing in for an unmeasured population.

`state.routine_catchup_window` gives D1 `window_days = 0.98` against a daily cadence — at the cadence-normal window, well under the 1.5× threshold — so **no `CATCHUP` token is owed** and none is carried. D1 declares no upstream dependencies, so **no `DEPWAIT` token**. Pre-flight clean on the first attempt: BigQuery and IBKR both live (NLV 15,763.13). Two BigQuery MCP calls dropped their `query` argument mid-run and succeeded verbatim on immediate retry — the known transient recorded in `ops.alerts` `0a752e9c` (OPS1, `transient_mcp_arg_drop_reads_as_nonwaitable`); it cost no wait and no ladder, so **no `RETRY` token**. Same-day double-run guard clear — zero D1 rows of any status for 2026-09-08 at guard time.

**GATE DISPOSITION.** `state.staging_halt_disposition` reads `trading_enabled = false`, `halt_reason` "marks_fresh/engine_fresh not both TRUE", `halt_is_prerefresh_artifact = true`, `gate_alert_action = 'defer_to_craft_site'`. This is the ordinary pre-refresh artifact: marks and engine cover 2026-09-04 = `marks_due_through`, and do not yet cover the 2026-09-08 session because D2a (16:41 MT) has not run. Every other gate term is green and `mechanical_enabled` is TRUE. D1 crafts no orders, so **nothing was raised at the gate and nothing is owed**.

---

## TL;DR

- **Exits triggered: none.** All 12 open tranches are Strategy D, which carries no `convergence_target` and no `time_exit_date` by design (both NULL on all 12); no thesis-invalidation criterion is engaged on any of the eight held names.
- **New entry candidates: none routed.** Seven names clear Strategy B's frozen Entry criterion 1 (≥5% close-to-close on an identified event day) — NVS, ROIV, GPCR, AMGN, INTC, BKNG, QBTS — and their identities are persisted in the screen record with `qualifying_event_date`. **None is routed**: B reads `DO-NOT-ACTIVATE` and holds no capital.
- **Add candidates: none.** All 12 open A/B/D tranches evaluated; 9 declined on evidence, **3 declined at the HARD GATE** (ISRG, RTX, UBER). Today that block bound on the two biggest dips in the book: ISRG −4.51% and UBER −3.47% are textbook dip-against-intact-thesis candidates and were declined anyway.
- **Watchlist changes: none.**
- **Regime review: no.** Hike odds firming to ~60–62% and a deepening Hormuz shock are both real; neither is a router-level change and the bar is deliberately high.
- **PARK: DE-RISK — `target_f_pct` 0 → 25, VOO/SGOV, MEDIUM 50, BOUND.** The volatility axis **ENTERED** defensive (VIX 15.72, clearing both the 15.00 bar and its own 20d SMA 15.1125), joining standing breadth and standing shock. This is the exact flip condition the 2026-09-06 record pre-declared. First conversion since the graded ladder went live on 2026-09-04.

---

## DEVELOPMENTS

### 1. Market-wide breaking events

**The Strait of Hormuz shock deepened materially over the holiday weekend, and it is the main macro channel in this window.**

- **Transit collapse.** Kpler vessel counts cited by Sky News put Tuesday commodity transits at **4**, against 10 the prior day and a 10-day average of **13**; Al Jazeera's live blog carries the same Kpler series at a ~10/day 10-day average, the lowest since May. Reuters separately counted 7 on Monday against 8 the day before. ([Reuters](https://www.reuters.com/world/middle-east/hormuz-traffic-slows-after-iran-threatens-retaliation-us-attacks-2026-09-08), [Al Jazeera](https://www.aljazeera.com/news/liveblog/2026/9/8/iran-war-live-qatar-warns-of-industrial-catastrophe-if-crisis-continues))
- **Iran announced a new Gulf "exclusion zone"** plus a new Hormuz shipping corridor, and threatened the US with new "Qassem Basir" missiles — SNSC chief Mohsen Rezaei. ([Reuters](https://www.reuters.com/world/middle-east/iran-says-it-plans-new-gulf-exclusion-zone-threatens-us-with-new-missiles-2026-09-08))
- **Qatar's foreign ministry** warned of "industrial catastrophe" if the strait does not stay open. (Al Jazeera, above)
- **Observable reaction.** Brent **96.28 → 99.39** (+3.2302%, FMP `BZUSD`, date-pinned), WTI above $93 — both multi-week highs. Energy was the best GICS sector (**XLE +1.1083%**) on a −0.55% tape. **Goldman Sachs raised its Brent and WTI forecasts** for December 2026 and 2027, citing disruption persisting into next year.

**Fed path repriced hawkish — a live repricing, not a scheduled resolution.**

- Market-implied odds of at least one 2026 hike are running **~60–62%** (a Polymarket 2026-hike market at ~62%; aggregator reporting of "September hike odds top 60%" anchored to the 2026-09-04 payrolls print of +162k). **A CME FedWatch figure explicitly timestamped to 2026-09-08 could not be pinned**, so this is recorded as a range from press sources rather than as a point.
- **Barclays turned hawkish**, now forecasting **two 25bp hikes in 2026** (September and December), reversing a prior no-change call, after Fed Chair Kevin Warsh's Jackson Hole remarks and sticky inflation.
- Treasuries bear-flattened modestly: 2Y +2bp to 4.39, 10Y +2bp to 4.80, 30Y +1bp to 5.25; 2s10s +0.41.
- **Next FOMC: 2026-09-17 — outside this window, not resolved, recorded as context only.**

**Not confirmed, and stated rather than guessed:** a 2026-09-08-dated 30Y close from a primary source (the FMP date-pinned series above is what is used); gold's direction (two sources conflict — one reports a rebound above $4,420 on a weaker dollar, another shows $4,400 down 1.71%); a DXY close; and whether the Fed's G.19 consumer-credit release actually published today.

### 2. Scheduled events that resolved today

**NFIB Small Business Optimism (August 2026) — CONFIRMED against the primary source.** Fell **1.1 points to 98.7**, above the 52-year average of 98.0. Released 2026-09-08 10:00 ET, reference period August 2026, per the NFIB press release itself and corroborated by the TradingEconomics calendar entry. ([NFIB](https://www.nfib.com/news/press-release/new-nfib-survey-main-street-optimism-cools-in-august-but-holds-above-long-term-average))

**Clinical readouts — the day's dominant event class, and the reason health care was the worst sector.**
- **Novartis (NVS)**: `del-desiran` **missed** its primary endpoint in the Phase 3 HARBOR trial (myotonic dystrophy DM1), compounding a same-week **pelacarsen** Phase 3 cardiovascular-outcomes miss. NVS **−13.9321%**.
- **Structure Therapeutics (GPCR)**: Phase 1/2a data for ACCG-2671 (amylin) and aleniglipron (GLP-1) read as underwhelming against incumbent obesity comparators despite positive issuer framing. **−14.7022%**.
- **Roivant (ROIV)**: positive Phase 2 `mosliciguat` data in pulmonary hypertension; H.C. Wainwright raised its target to $47. **+18.7518%**.
- **Ionis (IONS)** −2.3756% as pelacarsen's co-developer; **Amgen (AMGN) −10.0771%** on pure read-across to its own Lp(a) program `olpasiran`, with no news of its own.

**FDA — one filing milestone, one item verified OUT of window.** **Intellia (NTLA)** 8-K dated 2026-09-08: FDA **accepted** the BLA for lonvoguran ziclumeran in hereditary angioedema with **Priority Review**, PDUFA target **2027-03-10** — a filing acceptance, not an approval decision. Separately, a widely syndicated "FDA clears Etcamah (camizestrant)" item carries a 2026-09-08 aggregator date but the **actual accelerated approval was granted 2026-09-04**; excluded under the EVENT-IDENTITY GATE, and the check is recorded here so it is not re-chased.

**Earnings — no date-verified prints for $2B+ issuers were found inside the window.** Recorded as a genuine negative finding for a post-Labor-Day Tuesday, with the honest limit stated: no dedicated earnings-calendar endpoint was available to this scan (FMP bulk enumeration is plan-gated, `ops.alerts` `6c4004e3`), so this is "none found by news search", not "none exist".

**CPI and PPI — PENDING, confirmed scheduled for Thursday 2026-09-10 and Friday 2026-09-11.** No inflation print resolved today. **Fed G.19 consumer credit — unresolved**; nominally the fifth business day, but no release-day confirmation was obtainable. Recorded as pending, not populated.

### 3. Large single-name moves — AI-SIGNIFICANCE SCREEN (`screen='single-name-move'`)

**Layer-1 population rail:** US-listed, market cap ≥ $2B, ≥2% close-to-close on 2026-09-08 attributable to an identifiable public event. **35 names measured on IBKR RTH daily bars; 31 cleared the price and cap rails; 10 also carried an identified public event and were judged significant at Layer 2.** `surfaced_count = 10 = ARRAY_LENGTH(passed)`; `rail_tally = 10`; `universe_measured = 35`. Agreement: `both` 7 / `ai_only` 3 / `rule_only` 9.

| Ticker | Move | Conv | Event | legacy≥5% | <5% floor |
|---|---|---|---|---|---|
| NVS | −13.9321% | 75 | Dual Phase 3 failures (HARBOR del-desiran; pelacarsen CV outcomes) | ✓ | |
| ROIV | +18.7518% | 60 | Positive Phase 2 mosliciguat data + PT raise to $47 | ✓ | |
| GPCR | −14.7022% | 60 | Phase 1/2a obesity readouts judged underwhelming | ✓ | |
| AMGN | −10.0771% | 75 | Read-across: Lp(a) class failure hits olpasiran | ✓ | |
| INTC | +9.0501% | 60 | Bloomberg report of chip price increases next month | ✓ | |
| BKNG | −6.7205% | 45 | Conservative guidance + insider sales, into the rate repricing | ✓ | |
| QBTS | +6.5742% | 45 | Quantum sympathy to IonQ investor day | ✓ | |
| IONQ | +2.4038% | 60 | Investor Day: FY26 revenue guide raised to $450–460M post-SkyWater | | ✓ |
| IONS | −2.3756% | 45 | Own co-developed pelacarsen missed its Phase 3 endpoint | | ✓ |
| RGTI | +4.0132% | 30 | Quantum-peer sympathy to the IonQ event | | ✓ |

**Seven of the ten are one clinical cluster, and three of those seven are ONE root event** — the pelacarsen miss. The asymmetry is the informative part: Novartis −13.93%, Amgen −10.08% on no news of its own, Ionis only −2.38%. The market repriced the *mechanism*, not the two issuers who ran the trial. That is why AMGN is written at conviction 75 on a pure read-across while IONS sits at 45 — the significance ordering deliberately does not follow the price ordering.

**21 confirmed movers were DECLINED, each with a per-name disposition in `rejected_notable`, and every one for the same reason: a confirmed price move with no identified public event** — a failure of the rail's event leg, not its price or cap legs. **Nine of the 21 cleared the legacy 5% bar and were declined anyway** (`rule_only = 9`, the largest AI-vs-rule divergence this screen has recorded).

**Seven of those nine are one unexplained cluster and it deserves naming: SEI +16.29, SMR +15.26, CRWV +11.72, BE +9.63, NBIS +7.73, GLW +7.56, IREN +5.04** — an AI-power-infrastructure complex that moved together and hard with no name-specific catalyst found for any member. Corroborating tell: the 2× leveraged single-stock ETFs on INTC, GLW, NBIS, CRWV and BE all appeared independently in the gainers list at roughly double their underlyings. **This is the honest limit of the run — discovery found the move and did not find the cause**, and chasing it would have meant the per-ticker search sweep the SEARCH PROTOCOL forbids. Also declined for want of an event: PATH −7.77, NOK +6.18, GRAB −4.97, MARA +4.60, CIFR +4.34, F −4.24 (Canada's retaliatory tariffs effective today are a plausible channel but were *not* confirmed as Ford-specific), TSLA +3.97, PCG +3.64, GEV +3.12, AVGO +2.98; and NOW −4.99, CRM −3.90, ADBE −3.47, NVDA −2.01 as macro-attributed software/megacap-tech selling with no name-specific event.

**BMNR was measured on purpose** — `ops.alerts` `ed5e2e24` (W2) recorded that it had no disposition anywhere in D1's 2026-09-03 screen. It closed **−0.8010%** (24.97 → 24.77) and fails the 2% rail outright, so its absence from both arrays here is correct curation. **That does not close the alert**: the open item is a re-measure of the *2026-09-03* population, which belongs to a run scoped to that session.

**One honest provisional:** GPCR's cap reads $2.32B from FMP `profile-symbol`, 16% above the rail and inside the ±30% band where this spec asks for a second source. It was not second-sourced; the rail call is provisional for that one name.

### 4. Sector-level moves — AI-SIGNIFICANCE SCREEN (`screen='sector-move'`)

All eleven GICS sector SPDRs measured on IBKR RTH daily bars. **Computed, not asserted: 3 higher, 8 lower.** XLE +1.1083, XLU +0.8589, XLK +0.3151, XLRE −0.0683, XLC −0.4552, XLI −0.4850, XLP −0.6621, XLY −0.8006, XLB −0.9535, XLF −1.3769, XLV −2.5197. Dispersion 3.6280pp. `surfaced_count = 3`, `rail_tally = 3`, `universe_measured = 11`; agreement `both` 1 / `ai_only` 2 / `rule_only` 0.

- **XLV −2.5197% (conv 75, legacy ✓)** — the only sector past 2%, underperforming SPY by 1.97pp. It decomposes cleanly into four constituent clinical readouts, three of them one root event. A sector print that reduces to one falsified drug mechanism is high-information.
- **XLE +1.1083% (conv 60, legacy ✗)** — the shock axis surfacing in equities, on Brent +3.23% and the Hormuz transit collapse. Surfaced *below* the old 2% bar precisely because §19 Layer 2 exists to rank a named, deepening geopolitical channel above a larger beta-day sweep.
- **XLF −1.3769% (conv 45, legacy ✗)** — the rate path. Held at 45 because credit did **not** corroborate: HYG/IEF closed **17.34bp above** its own 20d SMA.

**This is explicitly NOT a defensive rotation, and saying so matters** because that is the reading the 2026-09-01 record got wrong in the other direction. Of the three defensive sectors only utilities rose; staples fell −0.66% and health care fell −2.52% *for a clinical reason with no macro content*. Technology was third-best and QQQ was nearly flat. DIA (−1.13%) underperforming IWM (−0.45%) locates the damage in large caps, consistent with the NVS/AMGN/BKNG cluster rather than broad de-risking. **XLU +0.8589% was considered and deliberately not surfaced** — it fails the 1% rail and no utilities-specific driver was found; recorded so the omission reads as a choice.

### 5. Notable commentary

- **José Torres (Interactive Brokers)**, in Barron's live coverage: inflation progress "is set to reverse if geopolitical tensions don't simmer"; WTI needs to fall below $90 to avoid a September print above 3.5% and an accompanying hike. ([Barron's](https://www.barrons.com/livecoverage/stock-market-news-today-090826))
- **Barclays** to two 25bp 2026 hikes (September and December), reversing its no-change call.
- **Goldman Sachs** raised Brent and WTI forecasts for December 2026 and 2027.
- **Neel Kashkari (Minneapolis Fed)**: the war could change the inflation outlook enough to force "potentially a series" of hikes. **Beth Hammack (Cleveland Fed)** dissented against the prior easing bias on outlook uncertainty.

---

## ANALYSIS — RISK TO EXISTING POSITIONS

### Mechanical exit-trigger sweep

Run for every open position, over the **union** of `state.current_positions` and live `get_account_positions`. `state.current_positions` holds **12 open tranches across 8 names, all Strategy D**. The connector returned exactly those 8 equity names plus the 21.4714-share VOO park position and nothing else — **no position is real in IBKR but absent from BigQuery, so no `position_reconciliation_lag` alert is owed.**

All 12 tranches carry `convergence_target` NULL and `time_exit_date` NULL — Strategy D by design — so **no mechanical exit could fire. Zero EXIT TRIGGERED flags.**

### Per-strategy kill-trigger sweep

`perf.kill_flags` read for both strategies with a row. `current_drawdown` was refreshed **unconditionally** against today's IBKR closes, not against connector position marks:

- **Strategy D** (engine `as_of_date` 2026-09-04): `deployed_unit_value` 1.067124, `peak_unit_value` 1.098110, engine drawdown **−2.82%**. Refreshed on today's closes the D book marked **547.93 → 548.93 (+0.182%)**, taking the unit value to ≈1.06907 and the drawdown to **≈−2.65%** — against a −50% kill bar. `drawdown_kill` FALSE, `runaway_review` FALSE (not doubled), `gate_reached` FALSE (1 closed trade of 30), `interim_underperf_warning` **FALSE** (deployed 92 days but beta-adjusted excess vs SGOV is **+5.30%**, far above the −15% bar).
- **Strategy B** (row `as_of_date` 2026-08-18): no open positions, all flags FALSE.
- **No kill or review flag fires. No alert is owed, and no HEAL-RESOLUTION is owed** — there is no open `interim_underperf_warning` alert to clear.

**B open-book pairwise correlation:** `analytics.b_pairwise_correlation` returns `n_positions = 0`, so the `n_positions >= 2` term fails and the check is a no-op. No `b_pairwise_corr_high` alert.

### Thesis-invalidation review

**No Development in this window engages any invalidation criterion on any of the eight held names.** The window's two structural events — the pelacarsen Lp(a) Phase 3 failure and the Hormuz escalation — touch no held name's mechanism. Per position:

| Position | Move today | Criterion engaged? |
|---|---|---|
| AMZN (2 tranches) | −0.5957% | **NO** — no AWS growth, margin, backlog or commit development |
| DIS (2 tranches) | −0.2374% | **NO** — SVOD margin, FY26 EPS guide and buyback pace all affirmatively passed at the Q3 FY26 print; segment-reporting immutability first tests ~Feb 2027 |
| GEV | +3.1169% | **NO** — no organic-orders-growth or disclosure development |
| GOOGL (2 tranches) | −0.0295% | **NO** — no Cloud revenue, margin, RPO or structural-remedy development |
| ISRG | **−4.5105%** | **NO** — see below |
| RTX | −0.9861% | **NO** — no Airbus ruling, quality event, GTF EIS slip, backlog or FCF development |
| TSM (2 tranches) | +2.3525% | **NO** — no GM, revenue, ramp or AI-capex-reset development |
| UBER | **−3.4715%** | **NO** — see below |

**ISRG −4.5105% and UBER −3.4715% are the two largest position-level declines in the book and both are explicitly examined rather than waved past.** ISRG moved *with* the day's worst sector (XLV −2.5197%, driven by clinical readouts at wholly unrelated issuers) and had no da Vinci procedure-growth, placement, recurring-revenue or competitive-displacement news; its invalidation-4 criterion ("competitor discloses displacing dV at named large IDNs") is **not engaged**. No UBER-specific catalyst was found in the window and no gross-bookings, EBITDA-margin or Uber One development occurred; nothing engages. Both are ordinary adverse mark-to-market, which each thesis's own "not exit-triggering" list names as exactly that.

**DIVIDEND NETTING (`state.price_level_criterion_drift`) — NOT ENGAGED this run.** No price-level criterion is being reported as met, so no raw close is being compared to a fixed level and no dividend adjustment is owed. Stated explicitly because the rule's failure mode is silent.

### Watchlist candidates

No Development in the window materially changes any queued candidate's status.

---

## ANALYSIS — OPPORTUNITY CHECK

Evaluated for every roster-active strategy with `review_cadence: reactive` — **A, B, C, E** (D is excluded via `long_horizon`).

- **Strategy B — seven names clear frozen Entry criterion 1, none is routed.** NVS (−13.93), ROIV (+18.75), GPCR (−14.70), AMGN (−10.08), INTC (+9.05), BKNG (−6.72), QBTS (+6.57) each moved ≥5% close-to-close on an **identified** event day. Each is persisted in the `research-screen` record with `qualifying_event_date = 2026-09-08` and its originating screen id, so a later session can pick any up without re-deriving it. **None becomes a thesis handoff**: `state.current_regime` STRATEGY_ACTIVATION reads B = `DO-NOT-ACTIVATE`, and B holds no capital (account cash $98.44; `ops.alerts` `be27644c` records A, B and D as debtor strategies against an empty enabled-donor set). Manufacturing queue rows for a strategy that cannot enter would go stale, not get acted on.
- **Strategy A — no candidate.** The window's catalysts are *resolved*, not forthcoming; a post-event failure is not a pre-event catalyst within six months.
- **Strategy C — no candidate.** Router reads `HYBRID ACTIVATE (FOMC-only)`. The 2026-09-17 FOMC is a standing scheduled event, not a newly announced qualifying catalyst, and firming hike odds change its pricing, not its existence.
- **Strategy E — no candidate.** The 3.6280pp sector dispersion and the intra-health-care spread (NVS −13.9 / AMGN −10.1 / IONS −2.4 against the sector's −2.5) are a genuine divergence, but it is a *resolved binary readout* rather than a narrative divergence expected to converge, which is what an E pair requires. E also reads `DO-NOT-ACTIVATE` and is unfunded. Recorded as context.

---

## ANALYSIS — ADD-CANDIDATE CHECK (A, B, D only)

**12 open A/B/D tranches evaluated — all Strategy D. 0 flagged, 3 declined at the HARD GATE, 9 declined on the evidence.** Durable record written to `events.decision_log` as one `add-candidate-review` row.

`mark_vs_cost_pct` uses the **2026-09-08 IBKR RTH daily-bar close** over **that tranche's own** `cost_basis / shares` — never the account-level blended `average_price`, never a snapshot (2026-09-07 pin):

| Position | mark vs cost | evaluable | Disposition |
|---|---|---|---|
| D:RTX:2026-04-27 | +12.3863% | **FALSE** | `declined_hard_gate` |
| D:TSM:2026-07-29 | +11.7381% | TRUE | declined |
| D:AMZN:2026-07-09 | +6.5187% | **FALSE** | declined |
| D:GOOGL:2026-07-26 | +3.2078% | TRUE | declined |
| D:TSM:2026-07-21 | +2.6034% | **FALSE** | declined |
| D:DIS:2026-08-05 | +1.2281% | TRUE | declined |
| D:ISRG:2026-07-20 | +0.1858% | **FALSE** | `declined_hard_gate` |
| D:GEV:2026-08-03 | +0.1448% | TRUE | declined |
| D:UBER:2026-07-09 | −0.1056% | **FALSE** | `declined_hard_gate` |
| D:AMZN:2026-07-30 | −3.2831% | TRUE | declined |
| D:DIS:2026-05-07 | −5.6226% | **FALSE** | declined |
| D:GOOGL:2026-07-09 | −5.9715% | **FALSE** | declined |

**The three HARD GATE declines are ISRG, RTX and UBER — the third consecutive sweep to decline the same three for the same structural reason.** Each carries `invalidation_status.breach_status = 'NOT_ASSESSED_BY_THIS_BACKFILL'`, and unlike AMZN, DIS, GOOGL and TSM, **none is covered at NAME level by a later tranche carrying a fresh assessment**. "Unbreached" therefore cannot be affirmatively confirmed anywhere in the durable record, and the gate is checked first, per candidate, and is the only gate.

**Today that block was not academic — it is exactly what bound.** ISRG (−4.51%) and UBER (−3.47%) are the two largest position-level declines in the book, both on no company-specific news, which is the textbook dip-against-intact-thesis shape this sweep exists to catch. Both were declined at the gate anyway.

**`invalidation_criteria_evaluable`: 7 of 12 FALSE**, applied with all three disjuncts including the 2026-09-06 `breach_status` disjunct and the COALESCE null-safety wrap. Under the superseded two-disjunct rule all 12 would read TRUE, since not one of the 12 carries a `$.status` key at all. Identical to the 2026-09-07 sweep, as it should be — nothing about those rows changed.

**Funding is recorded as context, not as a gate.** D reads `DO-NOT-ACTIVATE` and account cash is $98.44, so even a flagged add would have had no funding. No decline above rests on that.

---

## ANALYSIS — REGIME CHECK

**No inter-monthly router review recommended.** Default-NO on ambiguity holds, and the bar is deliberately high. Firming hike odds (~60–62%) and Barclays' move to two 2026 hikes are datapoints inside an axis already scored `policy_stance = hawkish`; the Hormuz escalation deepens an overlay already scored `shock_overlay = acute` since 2026-09-02. Breadth at 60.63 is deteriorating but well above any router threshold, SPY remains above both its 50dma and 200dma, and credit is not confirming. **Nothing here is a change in kind, only in degree, on axes already scored in that direction.**

---

## EQUITY-BREADTH OBSERVATION

**Written: `events.regime_events`, `scope='TECHNICAL_INPUT'`, `key='EQUITY_BREADTH_PCT'`, `as_of_date = 2026-09-08`, `numeric_value = 60.63`, `value = 'Barchart $S5TH'`.** Idempotent on `(as_of_date, scope, key)` — no prior row existed for this date.

- **Source and path**: `https://www.barchart.com/stocks/quotes/$S5TH` via `tavily_extract` at `extract_depth=advanced` with a cache-busting param. Page header as published: **"Quote Overview for Tue, Sep 8th, 2026"**, on-page stamp **17:20 ET** (post-close). Published fields: Last 60.63, Open 62.62, High 62.62, Low 60.43, **Previous Close 64.01**, change **−3.38 (−5.28%)**. `date_attribution = source_dated` — the post-close inference fallback was neither used nor needed.
- **Previous-Close self-check passes exactly.** Barchart's Previous Close 64.01 equals the value this key already carries for 2026-09-04 to the cent, and 64.01 − 3.38 = 60.63 reconciles internally.
- **SINGLE QUALIFYING SOURCE — disclosed as required.** EODData was pulled twice and **rejected** on the settlement-lag tell: on-page timestamp "08 Sep 26 15:58" (pre-16:00 ET) and the value moved between two near-simultaneous polls (62.42 vs 60.63). Recorded as weak corroboration only — and worth recording, since that second unsettled read carried Close 60.63 and Low 60.43, numerically identical to Barchart's Last and Day Low. Investing.com returned no S5TH value on either of two URLs; StockCharts renders client-side only. No two obtainable sources disagree by more than 5pp, so a row is written.
- **Rejected fetches, recorded so the omissions read as deliberate**: plain `WebFetch` on Barchart returned an empty JS shell on three URL variants; an **un-cache-busted** `tavily_extract` on the identical URL served a **~2026-08-20 vintage reading 70.31** — the stale-cache trap this step is written against, caught by the on-page date rather than by the number.
- **MacroMicro deliberately NOT probed.** Under the 2026-09-06 W5 ruling it is a **Sunday-anchored weekly re-probe**, and today is Tuesday. No probe was due; none was spent.
- **Material reading: breadth fell 3.38pp in a single session, the largest one-day decline this key has recorded.**

---

## ANALYSIS — FRONTIER-LLM CAPABILITY CHECK

Ran, silent, no output owed. One HF `hf_fs` paper-search query (Tuesday → the prompt-injection battery, `HF_Resource_Catalog.md` §6.1). Five results returned; **none published inside the ~24h window** (most recent 2025-11-25). No `AI_Trading_Foundation.md` item affected, no capture written, no `state.strategy_candidates` row. Default-silent, as expected on a normal day.

---

## PARK ALLOCATION CALL

**`vehicle`: VOO** (the majority sleeve) · **`conviction`: MEDIUM, `conviction_pct` 50** · **`direction`: de-risk** · **`status`: BOUND** · **`target_f_pct`: 0 → 25** (risk sleeve VOO 75%, defensive sleeve SGOV 25% — ≈ $3,779 of a $15,117 park).

**`rationale`.** A second independent axis **entered** defensive, and it is the one that was pre-declared. The 2026-09-06 record named the flip condition prospectively and checkably — *"flips to a de-risk on the FIRST session where a SECOND independent axis ENTERS defensive alongside breadth … volatility (VIX > 15 AND above its own 20d SMA)"* — and **both legs fired**: VIX closed **15.72** against the 15.00 bar and against its own 20d SMA of **15.1125**, having closed 14.53 and *not* defensive on 09-04. Hand-scored axes: **volatility** defensive, entered today; **breadth** defensive and standing (entered 09-04, re-measured today at a further −3.38pp to 60.63 vs the 66 bar); **shock** defensive and standing since 09-02, deepening (Brent 99.39 vs the 95 bar, +3.23% over the weekend) — a standing state is never news, so it supplies a standing count but no event; **index NOT defensive** (SPY 765.96 above its 50dma 757.5966, −1.5324% from the 777.88 high vs a −3% bar); **credit NOT defensive** (HYG/IEF 0.858507, **17.34bp above** its 20d SMA where the bar asks 50bp below); **rates NOT defensive** (30Y 5.25 vs the 5.40 bar; hike odds ~60–62% vs the 85% bar). **Standing count 3, one entry this session → increase gate open, cardinality floor cleared on two independent axes.**

*Why it beats the runner-up (KEEP at f=0):* KEEP was the right call on 2026-09-01 and 09-06 precisely because only one axis carried, and it saved money. That is no longer the state — a second, independent, pre-declared axis entered on its own terms while a third deepened. Holding f=0 now would mean the exit bar is materially harder to clear than the record says it should be, which is the stickiness the 2026-08-18 symmetric-standard note exists to prevent.

*The one arguable step, stated:* read strictly as "entered defensive **today**", only volatility fires and this is a one-axis WATCH. Read on the system's own operative definition — `is_firing` means *entered within 2 sessions*, which is what `firing_count` counts and what the gate consumes — breadth is also firing, and it is not a stale carry: it was re-measured today and got worse. The operative reading is taken; the strict one is recorded so the step reads as noticed, not glossed.

*Sizing, and why it does not turn on the cap dispute:* hand-scored standing count 3 → raw cap **75**. `state.park_axis_daily.cap_pct` reads **50** off a mechanical count of 2, because the volatility axis there is **carried from 09-04** — D2a writes `events.signal_marks` at 16:41 MT and had not run. Per the MIXED-VINTAGE rule the mechanical count may not block or demote a de-risk on an axis whose `measured_on` is not today; the disagreement is recorded in `fields.axis_overrides`. f is at the 0 floor and this call *increases* it, so the downward decay clamp does not bind and no step is owed. **Conviction 50 × cap 75 = 37.5, equidistant between the 25 and 50 steps → tie rounds DOWN → 25. Conviction 50 × cap 50 = 25.0 → 25. Both cap readings give f = 25**, so the call does not depend on resolving the dispute. No ±1-step deviation taken. Crisis override not engaged (index −0.5492% vs −2.5%; VIX 15.72 vs 28).

*Why conviction is 50 and not 60:* two of six axes actively decline to confirm — the index axis, the most direct read on whether the risk asset is actually breaking, is not defensive on either leg, and credit closed on the wrong side of its threshold. Against that, the forward-test record says this signal class has a **mean forward edge of −0.638pp** over 15 episodes (4 wins of 15), and both live defensive excursions of the AI era **lost** (−2.841pp, −1.019pp; 0-for-2). Honest confidence that defensiveness is right here is not above even. The evidence is real enough to act on and not strong enough to act big on — which is the case the graded ladder was built for. At f=25 an adverse round trip on the scale of 09-01→09-03 costs on the order of **$55**, against the **$214.32** that one cost at ~97% of NAV.

**`invalidation` (symmetric, disjunctive, same bar in both directions).** Back to **f = 0** on **either**, one alone sufficing: volatility exits defensive (VIX back below 15.00 **or** below its own 20d SMA — a single close does it, exactly as cheaply as a single close carried it in), **or** breadth prints ≥ 66. Neither is a conjunctive checklist, neither is harder to clear than the entry evidence, and decreasing f is always allowed and never delayed. **Deeper toward the cap** if a **third** axis enters: index (SPY below 757.60, or below ~754.5 = −3% from 777.88), credit (HYG/IEF ≤ 0.852736), or rates on a genuine break (30Y sustained above 5.40, or a September hike priced above 85%). **Shock cannot supply it** — already standing defensive, so a further Brent gap deepens it without creating an event. Crisis override carries alone and same-day.

**`theater_check`.** The rationale argues against its own conclusion in the two places it did not have to: the index axis is not defensive at all and credit closed 17.34bp on the wrong side. Those facts are why conviction is 50 rather than 60 and f is 25 rather than 50. A narrated foregone conclusion would have reached for the tape and the headlines and left the non-confirming axes out.

**Forward test:** this is **episode 1 of the 3** post-activation episodes W5's PARK FORWARD-TEST COUNTDOWN requires before re-evaluation. Logged as a running test, not a settled system.

---

## PROCESS NOTES

**An evidence-integrity defect was found and it is decisive for the park call.** The IBKR daily `^VIX` bar for **2026-09-04** now serves **close 15.30 against its own high 14.58 and low 13.80** — a close 0.72 *above* its own high, which is structurally impossible. All 20 other bars in the same pull are well-formed; exactly one is not. **The bar mutated after the fact**: the 2026-09-06 park record cites this identical IBKR call and pinned 14.53 for that date, and `events.signal_marks` independently holds 14.53. 14.53 sits inside the bar's own range and 15.30 does not. Third corroboration: 15.72 / 14.53 − 1 = **+8.19%**, matching an independent same-day report that VIX rose ~8%, where 15.30 would imply +2.75%, which no source carries. **Read off the corrupt bar, volatility would have scored 15.30 > 15 on 09-04 and today would be a *carried standing* axis rather than a same-session *entry* — the difference between a WATCH and this conversion.** Substituted 14.53 throughout and raised `ops.alerts` `ibkr_vix_daily_bar_close_outside_ohlc` (info; owner W5 for the spec, OPS1 for the connector manifest), with a suggested durable fix: assert `low ≤ close ≤ high` wherever an IBKR daily bar is consumed as a close.

**One durable record was corrected append-only.** The first `add-candidate-review` append (`5f6fb68f`) cited the `regime_restore_shortfall` alert by a **fabricated** id — only the `be27644c` prefix was real. Superseded by a complete replacement carrying the true id `be27644c-6953-4c93-a6f8-ec86f3a648de`, tagged `correction`, with `in_superseded_by` set; judgment and every figure byte-identical. No UPDATE, DELETE or MERGE was used. It was corrected rather than left standing because an invented identifier is the same assertion-class defect `bigquery/213` and `/214` exist to correct.

**Out-of-scope items observed and left with their owners, not chased:** `ops.alerts` `ed5e2e24` (W2) still wants a D1-side re-measure of the **2026-09-03** session population — a different session's scope; today's BMNR measurement does not close it. `ops.alerts` `6c4004e3` (W1) records FMP bulk earnings enumeration as plan-gated, which is the reason the "no $2B+ earnings prints" finding above is stated as a floor.

---

## RECOMMENDED ACTIONS

No recommended actions.

```yaml d1_actions
[]
```

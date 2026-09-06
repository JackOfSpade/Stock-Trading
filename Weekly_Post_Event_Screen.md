2026-W36

# Weekly Post-Event Screen — Strategy B (W2)

**Run:** 2026-09-06 (Sun, ISO week **2026-W36**, per `state.trading_day_today.today`; `is_trading_day=false`, `last_trading_day=2026-09-04`, `next_trading_day=2026-09-08` — 2026-09-07 is Labor Day). Every price figure in this file is a completed regular-session close measured from IBKR daily bars (`security_type=STK`, `step=ONE_DAY`, `outside_rth=false`, per Operating_Protocols.md §19 PRICE BASIS). No live, intraday or after-hours print is load-bearing anywhere.

**Same-day double-run guard: PASSED.** `ops.run_log` shows **0** `completed` and **0** `started` W2 rows for `run_date=2026-09-06` at guard time, so this is not a redundant re-invocation.

**Catch-up check — no widening owed.** `state.routine_catchup_window` for `W2`: `window_start_ts=2026-08-30T08:30:14Z`, `never_completed=false`, `window_days=6.98`. Against a 7-day weekly normal that is **1.00x**, under the 1.5x bar, so **no `CATCHUP` token is owed**. The intake watermark used below is that same `2026-08-30T08:30:14Z`.

**Marker note.** The prior file carried `2026-W35`; this one carries `2026-W36`. W2's Sunday-anchored period `[09-06, 09-12]` and the plain ISO week of today agree, so no aliasing caveat is owed. Sibling agreement: W1 landed `2026-W36` earlier this cycle (commit `b921875`).

---

## SCOPE OF THIS RUN — WHAT W2 DOES AND DOES NOT DO

W2 performs **zero market-wide discovery**. It does not pull broad price bars to enumerate movers, does not repeat an event search, and does not re-judge §19 significance. Its intake is the durable D1 record since W2's own last successful completion. This run therefore spawned **no discovery sub-agent** and made **no metered population pull** — the FMP earnings/dividend/IPO calendars were not queried at all, and the shared-population-pull steps in W2's own prompt body are, per the reconciliation note added 2026-08-17, dormant for W2 and binding only on routines that genuinely fan out for discovery.

**SCREEN MODE: INDEX (B router DO-NOT-ACTIVATE as of 2026-09-03).** Read `state.current_regime`, scope `STRATEGY_ACTIVATION`, key `B`: the value read is **`DO-NOT-ACTIVATE`**, divergence `div-B-202608-1`, `as_of_date=2026-09-03`, theater-check `DIVERGENT`. This is a **fresher gate reading than the prior two cycles used** — those read `div-B-202607-1` at `as_of 2026-08-05`; the 2026-09-03 divergence review re-adjudicated B and held the state. M1b's raw call was ACTIVATE; the universal `shock_overlay=acute` override fired for the second consecutive month and produced post-reconciliation DNA, and AR_orc upheld the override as validly fired on a satisfied precondition. PART 2 accordingly runs in **INDEX MODE**: per candidate it records ticker, qualifying event date, event-day move, window close, D1 origin id, a one-line factual event description and a rank, and it **skips** the four cost-carrying steps — the mispricing direction/magnitude read, the retrieved-comparables step, the information-versus-sentiment analysis, and the convergence-indicator enumeration.

**B's own router legs still pass independently and the block is entirely the override.** `SPY_TREND` UP (773.17), `VIX_REGIME` LOW (14.32), `EQUITY_BREADTH` HEALTHY (66.40), all as of 2026-09-03. `analytics.strategy_nav` for B: `nav 0.00`, `deployed_mv 0.00`, `available_funds 0.00`. That zero is **not** a durable safety property: `state.regime_capital_debt` shows B `outstanding_debt = 4973.25`, and a router flip is the same event that mechanically restores it pro-rata with no AI call and no human gate — which is exactly why the plan requires an ACTIVATE-but-unfunded B to have its analysis ready rather than deferred.

**A CORRECTION THIS RUN MADE TO ITS OWN INSTRUCTION.** W2's INDEX MODE limb said a router flip inside a candidate's window was something "on the scheduled path only M1a can do." That was stale from the moment Rev 48 landed on 2026-09-05. There are now **two** scheduled paths: M1a's monthly re-score, and an out-of-cycle path that can land on any Sun–Thu — D2a's RE-RISKING LIMB EVALUATION queues a `PENDING_REGIME_REFRESH` item, **M1R** drains it by re-scoring all five `FUNDAMENTAL_AXIS` axes blind at 07:00 MT, and D2 picks the newer-than-monthly row up the same evening and queues the affected router review, whose resolution is the activation write. The clause has been corrected in `Claude_Task_Plan.md` in this run's commit. **Measured today:** `state.open_queue_detail` carries **zero** open `PENDING_REGIME_REFRESH` items and the standing `FUNDAMENTAL_AXIS` snapshot is M1a's `as_of 2026-09-01` (`shock_overlay = acute`), so no out-of-cycle re-score is in flight right now. The path being open matters anyway — it is the difference between "a flip inside a 10-session window is nearly impossible" and "a flip inside a 10-session window is possible on any weekday," and index mode's whole premise rests on which of those is true.

**Fan-out that DID happen, and why it is not discovery.** Four Sonnet-5 sub-agents ran: one extracted the item table from five durable D1 `research-screen` decision rows (BigQuery reads only); one gathered exclusion state — open positions, existing B thesis-construction identities, the trading-day calendar, the B spec (BigQuery reads and repo files only); one pulled IBKR daily bars for the PRIOR cycle's 17-name cohort (follow-through measurement); one pulled IBKR daily bars for this cycle's 22-name intake. **None of the four was permitted a metered call, and none made one.** Opus-5 did the orchestration, the eligibility adjudication, the two date-conflict resolutions, the ranking and the cohort analysis.

**MEASURED EXTERNAL SPEND THIS RUN: ZERO. Zero Tavily credits, zero Anthropic `web_search`/`web_fetch` calls, zero FMP requests, zero HF requests.** Every fact in this file came from BigQuery, the IBKR connector, or repo files — all free. For contrast, the 2026-08-23 full-depth cycle logged **68** `ops.web_calls` rows for this same routine, and the 2026-08-30 index-mode cycle logged **0**. Per the shared "Metered external calls" rule part (d), a run that made no metered call correctly writes no `ops.web_calls` row — and this paragraph is the statement that the absence is a real zero, not an unreported run.

---

## WINDOW ARITHMETIC

B's frozen entry window is **10 trading sessions counting the event day as day 1** (Entry criterion 1, `strategy/04_strategy_b.md`: *"Public event occurred within the last 10 trading days, producing an immediate price reaction of ≥ 5% in either direction (measured as close-to-close move on event day)"*). Trading sessions confirmed against `state.market_calendar`: 08-27, 08-28, 08-31, 09-01, 09-02, 09-03, 09-04, 09-08, 09-09, 09-10, 09-11, 09-14, 09-15, 09-16, 09-17, 09-18 (09-05/06 = weekend, **09-07 = Labor Day**). The next session is **Tuesday 2026-09-08**.

| Qualifying event day | Window closes (day 10) | Sessions left from 2026-09-08 |
|---|---|---|
| 2026-08-27 | 2026-09-10 | **3** |
| 2026-08-28 | 2026-09-11 | **4** |
| 2026-08-31 | 2026-09-14 | **5** |
| 2026-09-01 | 2026-09-15 | **6** |
| 2026-09-02 | 2026-09-16 | **7** |
| 2026-09-03 | 2026-09-17 | **8** |

---

# PART 1 — D1-ORIGINATED POST-EVENT INTAKE (no market-wide re-screen)

## Intake source

Five durable D1 `entry_type='research-screen'`, `screen='single-name-move'` rows landed after the watermark, covering five consecutive trading sessions:

| Label | D1 origin `entry_id` | D1 run date | Session screened | `passed` | `rejected_notable` |
|---|---|---|---|---|---|
| S1 | `ec0c9a26-7602-4518-bee0-032de9551956` | 2026-08-30 | 2026-08-28 (Fri) | 13 | 3 |
| S2 | `0c8ece63-9a7d-4845-a803-0622b30490dc` | 2026-08-31 | 2026-08-31 (Mon) | 6 | 3 |
| S3 | `f1b8b782-35fb-4b00-836d-7c969e71977a` | 2026-09-01 | 2026-09-01 (Tue) | 9 | 7 |
| S4 | `1c3b3b46-0c4f-419f-b961-138993b0f255` | 2026-09-02 | 2026-09-02 (Wed) | 11 | 4 |
| S5 | `b606229e-1a83-455f-bcf8-cc9160dad805` | 2026-09-03 | 2026-09-03 (Thu) | 11 | 9 |

**Zero superseded rows in this window** — none of the five is named in any `superseded_by`, checked against the raw table per the correction-idempotency exception.

**THE 2026-09-04 (Fri) SESSION IS DELIBERATELY UNCOVERED AND THAT IS CORRECT.** D1 is `daily_sun_thu`; `ops.run_log` shows no D1 row for 09-04, 09-05 or 09-06 (its Sunday scan fires tonight at ~20:00 MT, long after this routine's 02:00 MT slot). PART 1 forbids W2 from covering the Friday/Saturday gap early with its own bar pulls, and this run did not. Any qualifying event on 2026-09-04 will reach W2 in the 2026-W37 cycle. Bars for 09-04 DO appear below, but only as the terminal point of the trajectory series for names already in the intake — never to discover a new one.

## Four-part identity dedupe — CLEAN, matched on the FIELDS not the key string

Per the 2026-08-23 KEY-FORMAT PIN, dedupe matched on `(analysis_type='thesis-construction', strategy='B', ticker, qualifying_event_date)`, never on the literal `item_key`. **Result: zero collisions.** `events.queue_events` holds 42 distinct Strategy-B thesis-construction identities since 2026-06-01 across 89 append-only rows, **every one of them terminal (`status='complete'`)** and **every one carrying a qualifying event date of 2026-07-31 or earlier**. This cycle's intake spans 2026-08-27..2026-09-03. The two sets cannot intersect, so no candidate below is a re-surfacing of an open or adjudicated identity.

**A MEASURED CAVEAT ON THE DEDUPE SURFACE ITSELF, recorded because it will bite when B is next active.** `events.queue_events` has no `qualifying_event_date` column, and no consistently populated JSON path for one either. On `status='complete'` rows `payload` is always NULL, so the event context is discarded at completion. On `status='pending'` rows the payload schema changed mid-period without a migration: June-vintage items bury the date as free-text prose inside `$.context` (CEG: *"Day-0 = 6/1"*), while items from the 2026-07-13 batch onward carry a structured `$.event_date`. So the field-based dedupe this routine is required to perform is only mechanically queryable for July-onward items; June-vintage ones require prose-mining. Not biting today (every relevant identity is July or earlier and terminal, and the windows cannot overlap), and not raised as an alert for that reason — recorded here so a future cycle facing an *open* B identity knows the surface is uneven before it trusts a NULL result.

## Items preserved from D1

D1 surfaced **50 `passed` items** across the five screens. **35 are rankable by B's frozen spec floor** (`below_spec_floor = false`, i.e. an event-day close-to-close move of ≥5%); **15 are context only**. All of D1's `ticker`, `qualifying_event_date`, event type/source, move, significance verdict, `legacy_rule_pass`, `below_spec_floor` and originating decision id are preserved below.

### PRICE-BASIS RECONCILIATION — ZERO CORRECTIONS OWED, THIRD CONSECUTIVE CYCLE

An independent IBKR pull (22 names, `ONE_DAY`, `outside_rth=false`, 22 bars each, issued in batches of ≤4 rather than one wide parallel batch per the 2026-08-20 shifted-response defect; all bar-date arrays identical within each batch, no re-pull needed, no missing bar anywhere) reproduces **every one** of D1's measured event-day magnitudes. Largest disagreement across all 26 reconciled figures: **0.0003 pp** (VSXY, D1 −13.1709% vs measured −13.1706%; FRVO 28.4136 vs 28.4135; CPB −6.9384 vs −6.9386). This was a by-product of the trajectory pull, not a re-screen, and this run did **not** recompute the moves to second-guess D1 — the closes were pulled for the cohort work and the agreement fell out.

### TWO DATE-ANCHOR CONFLICTS IN D1'S OWN RECORD, BOTH RESOLVED ON MEASUREMENT

**(1) CRDO and MDB — D1's S4 prose is off by one session, and the tape says so.** S4's `body_md` states that *"two surfaced names (CRDO, MDB) reported earnings AFTER today's close"* — today being the 2026-09-02 session it was screening. If true, the reactions to those reports would land on 09-03. **MEASURED:** CRDO 09-02 = **−20.0407%**, 09-03 = **−0.6355%**; MDB 09-02 = **−13.5441%**, 09-03 = **+2.4108%** (positive). The entire reaction is on 09-02 and 09-03 carries nothing resembling an earnings response, so the reports landed *before* the 09-02 open, not after its close. Both are anchored here to `qualifying_event_date = 2026-09-01` (release after the 09-01 close — the near-universal pattern for these issuers, and the same shape D1 established for DELL in the same screen). **This anchor is INFERRED, not measured:** what the bars establish is that the reaction is the 09-02 session; if either name in fact released pre-market on 09-02, its window runs one session longer, to 2026-09-16. The choice made here is the **conservative** one — it shortens each window by a session rather than lengthening it.

**(2) DELL — S4's reasoned prose governs over S5's bare field.** S4 states explicitly that DELL's FQ2 2027 release is dated 2026-09-01, before that screen's window opened at 18:22 ET, with the +15.8118% reaction on 09-02. S5's `fields.passed[DELL].qualifying_event_date` reads `2026-09-02` with no argument attached. **MEASURED:** DELL 09-01 = −6.8003%, 09-02 = **+15.8118%**, 09-03 = +4.9147%. The reaction session is unambiguously 09-02, which is consistent with both records; what separates them is the release date, and only S4 states one with a reason. DELL is anchored to **2026-09-01** (window closes 2026-09-15). Note that S5's DELL row is not a competing observation of the same event at all — it is a separate, *below-floor* record of the 09-03 drift session (+4.9146%), and it is carried in the context-only list below rather than as a candidate.

### Rankable — passes BOTH D1's §19 significance judgment AND B's ≥5% frozen spec floor

35 items. Ordered by screen, then by |move|.

| Ticker | Qualifying event date | Event-day move | Event type / source | D1 significance verdict | `legacy_rule_pass` | Origin | One-line factual event description |
|---|---|---|---|---|---|---|---|
| ESTC | 2026-08-27 | **+19.3098%** | earnings / company Q1 FY27 release | conviction 75 | TRUE | S1 | Q1 FY27 revenue $478M +15%, subscription $449M +15%, non-GAAP EPS $0.70, adj FCF $143M — beat guidance across all key metrics. |
| GAP | 2026-08-27 | **+12.9389%** | earnings / company Q2 FY26 release | conviction 60 | TRUE | S1 | Q2 FY26 net sales $3.7B −2% YoY, comps −1%, adj EPS $0.52, FY guide raised to ~$3.77–3.87B; Old Navy's first negative comp in ~3 years. |
| SOLS | 2026-08-28 | **+12.7618%** | earnings / secondary-sourced report | conviction 60 | TRUE | S1 | Q2 adj EPS $0.88 vs $0.77 and revenue $1.15B vs $1.08B, FY26 guide raised, $500M buyback authorized. |
| PYPL | 2026-08-28 | **−12.7054%** | M&A collapse / Bloomberg-sourced deal report | conviction 75 | TRUE | S1 | Stripe-led group with Advent abandoned a ~$50B take-private pursuit after the board rejected the offer as insufficient. |
| IREN | 2026-08-28 | −12.5339% | macro-crypto / BTC price action | conviction 60 | TRUE | S1 | Bitcoin round trip from ~$81.4k to below $78k plus the Warsh rates move. |
| MRVL | 2026-08-27 | **−10.2837%** | earnings / company Q2 FY27 release | conviction 75 | TRUE | S1 | Q2 FY27 beat (revenue $2.739B record +37% YoY, EPS $0.94) sold off on a softer FY28 guide and the Google AI-chip payoff pushed to FY2029. |
| IONQ | 2026-08-28 | −7.6778% | macro-rates / no company event | conviction 45 | TRUE | S1 | Rate-duration unwind in unprofitable long-horizon growth; D1's own words: "explicitly catalyst-free". |
| PCG | 2026-08-28 | **−7.5209%** | regulatory / CA legislature | conviction 75 | TRUE | S1 | CA legislative leaders rejected Newsom's wildfire-liability (subrogation) reform ahead of an Aug 31 deadline; volume ~387% above 3-month average. |
| COIN | 2026-08-28 | −6.3339% | macro-crypto / BTC price action | conviction 45 | TRUE | S1 | Same crypto-complex round trip as IREN, exchange-side expression. |
| EIX | 2026-08-31 | **−23.0725%** | legislative / CA SB 492 + Mizuho downgrade | conviction 75 | TRUE | S2 | CA SB 492 emerged without wildfire-liability protection for investor-owned utilities; Mizuho cut to Neutral $70 the same morning. Worst session since 2001. |
| PCG | 2026-08-31 | **−20.0602%** | legislative / same SB 492 story | conviction 75 | TRUE | S2 | Same SB 492 failure; second consecutive event-day decline (two-session compound ~−26.1%); bond spreads widened. |
| BMNR | 2026-08-31 | **+6.3866%** | company disclosure / PRNewswire | conviction 45 | TRUE | S2 | Same-day release: crypto/cash holdings $15.6B anchored by 5.90M ETH — and it rose 6.4% on a session spot BTC fell ~0.7% and ETH ~1.6%. |
| TSLA | 2026-08-31 | +5.5054% | scheduled-catalyst **anticipation** | conviction 60 | TRUE | S2 | Anticipation of the 09-03 invite-only Cybercab event plus Optimus entering Fremont production. D1 labels this "ANTICIPATION, not a resolved catalyst". |
| FRVO | 2026-09-01 | **+28.4135%** | corporate announcement / company PPA release | conviction 75 | TRUE | S3 | World's largest enhanced-geothermal power-purchase agreement announced, against a risk-off tape. |
| CRK | 2026-09-01 | **+11.0187%** | corporate announcement / company release | conviction 75 | TRUE | S3 | $1.65B SOCAR strategic partnership plus a $450M Haynesville drilling JV. |
| ONDS | 2026-09-01 | −8.0340% | positioning / no discrete event | conviction 45 | TRUE | S3 | Reversion off a 261%/1yr run despite a strong Q2 ($83.8M revenue) and a PT raise to $22.75. |
| BMNR | 2026-09-01 | −7.7029% | underlying-asset / ETH price move | conviction 60 | TRUE | S3 | Ethereum treasury asset traded ~$1,770 (−40% YTD). Flagged by D1 as `floor_cleared_without_discrete_event`. |
| PCG | 2026-09-01 | +5.9533% | legislative aftermath / BofA downgrade | conviction 60 | TRUE | S3 | Bounce after the 08-31 collapse; BofA cut to Neutral PT $13. Flagged by D1 as `floor_cleared_without_discrete_event`. |
| BTG | 2026-09-01 | −5.1095% | commodity-macro / gold pullback | conviction 45 | TRUE | S3 | Gold pullback on rising hike expectations and dollar strength; GLD −2.8574%. |
| CRDO | **2026-09-01** (inferred; reaction 09-02) | **−20.0407%** | earnings / company Q-print | conviction 75 | TRUE | S4 | Revenue +115% YoY and an EPS beat sold 20% lower on margin compression, customer concentration and a soft Q2 guide. |
| DELL | **2026-09-01** (release; reaction 09-02) | **+15.8118%** | earnings / company FQ2 2027 release | conviction 75 | TRUE | S4 | ISG +89%, $16.4B AI-optimised server revenue, FY guide raised to ~$192B revenue / $25.50 EPS. |
| MDB | **2026-09-01** (inferred; reaction 09-02) | **−13.5441%** | earnings / company beat-and-raise | conviction 60 | TRUE | S4 | Beat-and-raise (revenue +30% YoY, guide lifted to $2.99–3.03B) sold off on rising AI-infrastructure cost concerns. |
| IREN | 2026-09-02 | +7.5502% | analyst reiteration | conviction 45 | TRUE | S4 | AI-cloud pivot now >50% of quarterly revenue; D1 states the proximate attribution is a single analyst reiteration, not a company disclosure. |
| NU | 2026-09-02 (anchor NOT ESTABLISHED) | **+6.5007%** | earnings / company release | conviction 45 | TRUE | S4 | Record Q2 net income $1.1B (+49% YoY) and an R$45B Brazil deployment plan. |
| CDE | 2026-09-02 | +6.0396% | commodity-macro / gold price | conviction 45 | TRUE | S4 | Gold ~$4,377/oz on softer hike odds; D1 found no Coeur-specific news. |
| PLTR | 2026-09-02 | −5.8137% | positioning-rates / company news + macro | conviction 60 | TRUE | S4 | Fell on a session of POSITIVE company news (US Army TITAN contract, senior hire) with the 10Y at a ~3-year high. |
| PCG | 2026-09-02 (anchor NOT ESTABLISHED) | **−5.1920%** | legislative / SB 492 amendment + capex deferral | conviction 60 | TRUE | S4 | SB 492 amended to strip the insurer-suit bar, ~$2B of capex deferred, four analyst downgrades. |
| SNOW | 2026-09-02 (reaction 09-03) | **+16.5544%** | earnings / company Q2 FY2027 release | conviction 75 | TRUE | S5 | Q2 FY2027 beat (adj EPS $0.62 vs $0.45; revenue $1.55B vs ~$1.48–1.50B, +35% YoY); FY27 product-revenue guide raised to $6.07B. |
| VSXY | 2026-09-03 | **−13.1706%** | guidance / company Q3 outlook | conviction 60 | TRUE | S5 | Soft Q3 operating-income outlook ($10–20M); the prior quarter's income had been inflated by ~$140M of one-time tariff refunds. |
| CIEN | 2026-09-03 | **−10.3625%** | earnings / company Q3 FY2026 record beat | conviction 75 | TRUE | S5 | Record beat (adj EPS $2.11 vs $1.72; revenue $1.67B record vs $1.63B, +37% YoY) sold off 10.4%. |
| CPB | 2026-09-03 | **−6.9386%** | earnings / company Q4 FY2026 miss | conviction 45 | TRUE | S5 | Q4 FY2026 miss (revenue $2.1B vs ~$2.15B, organic −1%; adj EPS $0.39 vs $0.62 prior year) plus an FY27 guide for a further 17–24% EPS decline and a ~36% dividend cut. |
| TTC | 2026-09-03 | **−6.8381%** | earnings / company Q3 FY2026 beat | conviction 45 | TRUE | S5 | Q3 FY2026 beat (adj $1.33 vs $1.30; revenue $1.23B vs $1.19B) with FY26 guide raised — and sold off 6.8%. |
| P | 2026-09-03 | +6.1885% | analyst action / Susquehanna upgrade | conviction 45 | TRUE | S5 | Susquehanna upgrade to Positive from Neutral, PT $85→$120. |
| ORCL | 2026-09-03 | **+5.6878%** | sector sympathy / AI-infra cluster | conviction 60 | TRUE | S5 | AI-infrastructure re-rating alongside the DELL and HPE prints; D1 identified no ORCL-specific same-day release and states the attribution is partly INFERRED. |
| HPE | 2026-09-02 (reaction 09-03) | **+5.0357%** | earnings / company Q3 FY2026 beat | conviction 60 | TRUE | S5 | Q3 FY2026 beat (GAAP $1.06 / non-GAAP $1.11 vs ~$0.93–0.94; revenue $12.2B vs ~$12.05B, +34% YoY) on record AI-server demand. |

### Context only — `below_spec_floor = true` (<5% event-day move, not rankable per B's frozen spec)

15 items, preserved but never ranked: **NVDA** −4.5750% (08-28, financing-programme pause report), **AMZN** +3.9686% (08-28, AWS tripled its Nvidia GPU order to ~2M GPUs — held D name), **RIVN** −4.3452% (08-28, CFO resignation), **INTC** −2.8450% (08-28, MRVL read-through plus Altera sale reports), **SRE** −3.0957% (08-31, SB 492 diluted by non-California businesses), **SLB** +4.8317% (08-31, Brent +2.93% on Hormuz; D1 states attribution INFERRED not measured), **AAL** −3.5741% (09-01, jet-fuel cost on the oil spike), **NIO** −4.0189% (09-01, Q2 revenue miss on +69.1% YoY revenue, verified against the SEC 6-K), **AAPL** +2.6134% (09-01, D1 states the true driver is UNIDENTIFIED — the CEO transition was announced 2026-04-20 and only took effect here), **RTX** −2.1349% (09-02, held name down into an escalating conflict), **NVDA** +3.2055% (09-02; a $12.9B Hugging Face deal attribution rests on one uncorroborated snippet), **GEV** +2.6053% (09-02, held name, no catalyst found), **DELL** +4.9146% (09-03 drift session — see date-conflict resolution (2) above), **AVGO** −2.7448% (09-02, Q3 beat with a soft Q4 guide; cap unverified, ~$1.7T by inspection), **NTAP** +2.5502% (09-02, large beat with a *muted* reaction; cap unverified, ~$37B by inspection).

### Identities EXCLUDED before enrichment, with the ground — 13, every one on Entry criterion 1

Criterion 1 requires that a **public event occurred** and that it **produced** the price reaction. A move that clears 5% on macro beta, commodity transmission, index-complex co-movement, an analyst's opinion, or anticipation of a *future* event does not satisfy it. Every ground below is drawn from D1's own record or B's frozen spec — **no new research was performed to exclude any of them.**

| Ticker | Date | Move | Ground for exclusion |
|---|---|---|---|
| IREN | 08-28 | −12.5339% | Crypto-complex co-movement, no company event. Same class as the MARA/MSTR/HOOD exclusions of 2026-08-30. |
| IONQ | 08-28 | −7.6778% | D1's own words: "explicitly catalyst-free... the Warsh move as the mechanism." No event to anchor. |
| COIN | 08-28 | −6.3339% | Crypto-complex co-movement, exchange-side expression of the identical BTC round trip. |
| TSLA | 08-31 | +5.5054% | **Anticipation of a future event**, not an occurred one. Criterion 1's verb is "occurred"; D1 flags the distinction itself. |
| PCG | 09-01 | +5.9533% | D1's own `floor_cleared_without_discrete_event` flag — a bounce off the 08-31 collapse, no fresh event. |
| BMNR | 09-01 | −7.7029% | Same D1 flag; a move in the underlying treasury asset (ETH), not a company event. |
| ONDS | 09-01 | −8.0340% | "Positioning / no discrete event" per D1; a risk-appetite tell, and D1 says so. |
| BTG | 09-01 | −5.1095% | Commodity-macro (gold/rates), no company event. |
| PLTR | 09-02 | −5.8137% | The company news was POSITIVE and the move was negative; D1 attributes the move to the rates repricing, so the event did not produce the reaction. |
| IREN | 09-02 | +7.5502% | Analyst reiteration. Same class as the QBTS/SRE analyst-action exclusions of 2026-08-30. |
| CDE | 09-02 | +6.0396% | Commodity-macro; D1 records sector-level attribution only and found no Coeur-specific news. |
| ORCL | 09-03 | +5.6878% | Sympathy with the DELL/HPE prints; D1 identified no ORCL-specific release and marks the attribution partly INFERRED. |
| P | 09-03 | +6.1885% | Analyst action (Susquehanna upgrade). Separately, D1's own gloss of this ticker as "(Everpure, NYSE)" does not resolve against the description, so the entity identity is itself unsettled — recorded, not chased. |

**PCG's three rankable legs are ONE candidate, not three.** PCG clears the floor on 08-28 (−7.52%), 08-31 (−20.06%) and 09-02 (−5.19%), and by the letter of the four-part identity each is a distinct qualifying event. They are three dated legs of one continuing CA SB 492 legislative thread, and B would only ever hold one PCG position, so ranking them separately would triple-count a single thread. It is ranked **once**, at its most informative leg (08-31), and the 09-02 leg is recorded alongside because it carries the thread's eligibility out to **2026-09-16** — two sessions past the 08-31 leg's own close. EIX is a *different issuer* on the same thread and is therefore a genuinely separate candidate, not a duplicate.

**35 rankable − 13 excluded = 22 rankable-by-floor items, which collapse to 20 distinct candidates** once PCG's three legs are treated as one.

## Criterion 5 binds nothing this cycle, and one near-miss is worth naming

`state.current_positions` returns **12 open rows, every one Strategy D** (AMZN×2, DIS×2, GEV, GOOGL×2, ISRG, RTX, TSM×2, UBER). **Zero open Strategy A positions, zero open Strategy B positions.** Criterion 5 ("No A position currently open in the same name") therefore excludes nothing.

The near-miss: D1's S5 records a `watchlist_intersection` of `A:AVGO:2026-05-09`, `A:SNOW:2026-05-25`, `A:NTAP:2026-05-29`. **SNOW is ranked 6th below.** These are Watchlist *queue* rows, not open positions, and criterion 5 bars only an open position — the same reading the 2026-08-17 cycle applied when it declined to let 37 A-queue names gate AVGO or AMAT. SNOW stays eligible. Stating it because a reader scanning for a cross-strategy conflict will hit this intersection and should find the resolution already made rather than have to re-derive it.

## PRICE-LAYER COMPLETENESS BACKSTOP — one genuine miss found

The verification pull returns whole bar series, so per the shared rule they were scanned for ≥5% sessions inside the window that no D1 screen dispositioned. Most of what turns up is **second-day drift on an already-screened thread** — EIX +8.93% on 09-01 and −6.14% on 09-02, CRDO −8.65% on 09-01, CIEN −5.87% on 09-01, ESTC +7.31% on 09-03, FRVO −8.96% on 09-02 — which D1 legitimately declines at Layer 2 and did decline explicitly for EIX and PCG on 09-03. Those are not misses.

**One is.** **BMNR closed +14.7008% on 2026-09-03** — measured, its largest session in the whole window and more than double its own 08-31 qualifying move. S5 screened that session and BMNR appears in **neither** its `passed` array **nor** its `rejected_notable` array, so the move has **no disposition anywhere in the durable record**. BMNR is squarely inside D1's attention set (it screened the name on both 08-31 and 09-01) and at a ~$14.4B market cap it clears both the ≥2% move rail and the ≥$2B cap rail comfortably. This is the same class of gap as the COHR −7.99% miss of 2026-08-13 that the price layer, not the headline layer, caught.

**What this run does and does not conclude about it.** MEASURED: the move, its size, and its absence from both S5 arrays. NOT ESTABLISHED: its cause — identifying that would require exactly the metered discovery index mode and PART 1 both forbid, so it was not attempted. Because criterion 1 requires an *identified* public event, the 09-03 BMNR move is **not rankable as a new identity** this cycle; BMNR's 08-31 identity, which does have an identified event, remains rankable and is ranked below. **HONEST LIMIT on the finding itself:** BMNR surfaced only because it was already in this run's 22-name pull as an existing candidate. This was not a market sweep, and nothing here establishes that D1 missed anything else. Referred to D1 — see FINDINGS below.

A second candidate for this list was checked and **discarded**: S5's `headline_vs_measured_discrepancies` lists FIVE (headline +6%, measured −1.2835%, sign flip) with no entry in either array, but at −1.28% FIVE fails the ≥2% population rail outright, so its absence from a "notable rejections" list is correct curation, not a gap. Recording the check because the near-miss shape is identical and a future session should not re-raise it.

---

## POST-EVENT TRAJECTORY — the residual-thinness test

Index mode skips per-candidate enrichment but **keeps the cohort work in full**, because it costs little and it is the evidence series a future divergence review reads when it re-tests B's convergence assumption. This cycle runs **two** series. The second is new, and it changes the reading of the first.

`gap_intact_pct` = (close 2026-09-04 − pre-event close) / (event-day close − pre-event close) × 100. 100% means the whole event-day move is still in the price; 0% means it round-tripped exactly to the pre-event close; a negative value means it reversed clean through; above 100% means it extended.

### Series A — this cycle's 20 candidates, measured at 2026-09-04

| Ticker | Event day | Event-day move | Sessions elapsed | `gap_intact_pct` @ 09-04 |
|---|---|---|---|---|
| MRVL | 08-28 | −10.28% | 5 | **72%** |
| ESTC | 08-28 | +19.31% | 5 | **50%** |
| GAP | 08-28 | +12.94% | 5 | **61%** |
| PYPL | 08-28 | −12.71% | 5 | **83%** |
| SOLS | 08-28 | +12.76% | 5 | **103%** |
| EIX | 08-31 | −23.07% | 4 | **83%** |
| PCG | 08-31 | −20.06% | 4 | **69%** |
| BMNR | 08-31 | +6.39% | 4 | **77%** |
| FRVO | 09-01 | +28.41% | 3 | **64%** |
| CRK | 09-01 | +11.02% | 3 | **52%** |
| DELL | 09-02 | +15.81% | 2 | **148%** |
| CRDO | 09-02 | −20.04% | 2 | **87%** |
| MDB | 09-02 | −13.54% | 2 | **111%** |
| NU | 09-02 | +6.50% | 2 | **97%** |
| SNOW | 09-03 | +16.55% | 1 | **62%** |
| HPE | 09-03 | +5.04% | 1 | **7%** |
| CIEN | 09-03 | −10.36% | 1 | **90%** |
| VSXY | 09-03 | −13.17% | 1 | **83%** |
| CPB | 09-03 | −6.94% | 1 | **145%** |
| TTC | 09-03 | −6.84% | 1 | **86%** |

(Reaction-session convention: for names whose release preceded the reaction — MRVL/ESTC/GAP, DELL/CRDO/MDB, SNOW/HPE — "event day" here is the reaction session whose close-to-close move is the measured magnitude, and "sessions elapsed" counts from it. The *window* is still counted from the qualifying event date per the arithmetic table above; these are two different clocks and are deliberately not merged.)

Mean residual by elapsed session: **1 session 78.8%** (n=6) · **2 sessions 110.8%** (n=4) · **3 sessions 58.0%** (n=2) · **4 sessions 76.3%** (n=3) · **5 sessions 73.8%** (n=5).

### Series B — the PRIOR cycle's 17-name cohort, re-measured. This is the new instrument.

The 2026-08-30 cycle measured its cohort's residuals at the 2026-08-28 close and reported a headline finding: *"sorted by elapsed sessions the decay is monotone and fast."* The same 17 names, same method, measured again at 2026-09-04:

| Ticker | `gap_intact_pct` @ 08-28 (prior cycle) | `gap_intact_pct` @ 09-04 | Change |
|---|---|---|---|
| AAOI | 108% | **112%** | +4 |
| BBWI | −3% | **−21%** | −18 |
| BJ | −14% | **+37%** | +51 |
| BTDR | 86% | **344%** | **+258** |
| CRM | 108% | **115%** | +7 |
| CRWD | 75% | **62%** | −13 |
| DKS | 80% | **73%** | −7 |
| DNN | 69% | **78%** | +9 |
| MU | 60% | **−88%** | **−148** |
| NVDA | 43% | **113%** | +70 |
| OKTA | 83% | **94%** | +11 |
| RDDT | 3% | **18%** | +15 |
| SNDK | 108% | **−140%** | **−248** |
| STX | 37% | **1%** | −36 |
| TSLA | 20% | **50%** | +30 |
| VEEV | 85% | **81%** | −4 |
| WDC | 0% | **−33%** | −33 |

### What the cohort says

**FINDING 1 — the prior cycle's monotone-decay reading does not survive contact with a panel, and the reason is methodological.** MEASURED: of the 17 names, **9 residuals rose and 8 fell** over the four sessions from 08-28 to 09-04 — a coin flip, not decay. MEASURED: Series A shows no decay gradient either — mean residual runs 79% → 111% → 58% → 76% → 74% across 1 to 5 elapsed sessions, which is noise around ~75%, not a downward path. INFERRED, and this is the substantive point: the prior cycle read a **time path out of a cross-section**, comparing one name at 9 elapsed sessions against a different name at 6, and attributing the difference to elapsed time rather than to the names being different. This cycle is the first to hold the names fixed and vary only the date — a genuine panel — and the panel does not reproduce the effect. This is a correction to a prior cycle's inference, made on measurement, not a restatement of it.

**FINDING 2 — dispersion widens sharply with elapsed time, and that is the durable result.** MEASURED: at 08-28 the prior cohort's residuals spanned **−14% to +108%**, a 122pp range. Four sessions later the same 17 names span **−140% to +344%**, a **484pp range — roughly 4x wider**. The extremes are not marginal cases: SNDK's −6.45% event-day decline fully reversed and then some (1484.98 → 1740.00 by 09-04), MU's −5.83% likewise (932.86 → 1016.59), while BTDR's +9.01% gain extended to 3.4x its original size. INFERRED: on a 6–11 session horizon in this regime, a post-event move does not reliably converge, decay, or persist — it disperses. That is directly the question B's convergence assumption turns on, and it points at neither the "held-and-extended efficient-repricing" signature the 2026-08-23 cycle reported nor the "fast mean reversion" the 2026-08-30 cycle reported. Three cycles, three different readings, and the two earlier ones were each drawn from a single cross-section.

**FINDING 3 — a prior cycle's flagged hazard fired exactly as flagged, and B's router is the only reason it cost nothing.** The 2026-08-23 cycle ranked MRVL 5th and flagged it as an SP5 in-window-binary hazard: its own Q2 FY2027 call was ESTIMATED at 2026-08-27/28, *inside* that candidate's then-open entry window (which closed 2026-09-01), and the file called confirming that date "the highest-value outstanding fact." MEASURED: MRVL reported on 2026-08-27 and the reaction session closed **−10.2837%**. The hazard was real, it landed inside the window as predicted, and it was adverse. Nothing was at risk because B was router-gated and no thesis was ever enqueued. This is the first closed loop in the recorded lineage between a flagged in-window binary and its resolution, and it is a point in favour of the SP5 sub-pattern's discriminating power rather than against it.

**FINDING 4 — criterion 3 forecloses "next earnings release" for two-thirds of the ranked cohort, and the fraction is worth stating rather than rounding to "all".** DEDUCED from event structure, not looked up: **10 of the 15 ranked candidates have their own quarterly report (or, for VSXY, a quarterly outlook) AS the qualifying event** — MRVL, ESTC, GAP, SOLS, DELL, CRDO, MDB, SNOW, CIEN, VSXY. A company that just reported next reports roughly 90 days out, beyond criterion 3's 60-day convergence boundary (~2026-11-07 for an entry on 2026-09-08), so for those ten the enumerated event "next earnings release" is structurally unavailable and **each would require a numerical price target**. The remaining five ranked names are *not* earnings-anchored — FRVO (a PPA), CRK (a partnership/JV), EIX and PCG (legislative), PYPL (an M&A collapse) — and for them the next-report date is **NOT ESTABLISHED this run**, because establishing it is precisely the per-candidate research index mode skips. Two of those five are foreclosed on different grounds regardless: **a legislative outcome is not on criterion 3's closed list** (which admits only next earnings release, next FDA decision date, next FOMC meeting, or inclusion in the S&P 500 / Russell 1000 / Nasdaq 100), so EIX and PCG need a numerical target whatever their report dates. This sharpens rather than repeats the prior cycle's version of the finding: that cycle said W2's intake is "by construction dominated by names that just reported," which is true directionally but the measured fraction is **67%, not ~100%** — a third of this cohort came in on legislative, deal and contract events, and the composition claim should carry the number.

---

# PART 2 — RANKED SHORTLIST (INDEX MODE)

**SCREEN MODE: INDEX (B router DO-NOT-ACTIVATE as of 2026-09-03).** Per candidate this section records only ticker, qualifying event date, event-day move, window close, sessions remaining, a one-line factual event description, the originating D1 decision id, and a rank. The mispricing direction/magnitude read, the retrieved-comparables step, the information-versus-sentiment analysis and the convergence-indicator enumeration are **deliberately skipped**.

**Ranking basis, stated because index mode gives the reader nothing else to audit.** Ranking is by **|event-day close-to-close move|, descending** — and by nothing else. Rationale: criterion 1 is itself a magnitude threshold, so magnitude is the one dimension B's own mechanism privileges, and it is the only per-candidate quantity index mode is permitted to measure. Event-identity quality (criterion 1) and instrument/population eligibility are applied as **gates upstream of the ranking**, not as tie-breakers inside it — everything that failed them is in the exclusion table, not ranked lower. **The honest cost of a pure-magnitude rank, stated plainly:** it ignores window reachability, so ranks 5, 10 and 15 (ESTC, GAP, MRVL) each have only **3 sessions** left while the below-cap names CPB and TTC have **8**. A composite score would have hidden that trade-off inside a weighting nobody could audit; the "sessions left" column exposes it instead.

**Market-cap rail.** All 15 ranked names clear B's ≥$2B floor with wide margin — smallest is CRK at $4.71B, then FRVO $5.67B and VSXY $5.85B, all >2x the floor and therefore outside the ~25% band that Operating_Protocols.md's MARKET CAP BASIS clause requires be resolved from an issuer filing. D1's S4 screen carries **no `market_cap_usd` field at all** (see FINDINGS), so CRDO, MDB and PCG's 09-02 leg have no D1-stated cap; each is nonetheless unambiguously an order of magnitude above the floor by inspection, which is stated here as **INFERRED by inspection, not measured** — the same convention D1 itself used for AVGO and NTAP.

**Instrument eligibility.** Three ranked names are foreign-domiciled but trade as **US-listed ordinary/common shares, not depositary receipts**: CRDO (Cayman, Nasdaq — IBKR "CREDO TECHNOLOGY GROUP HOLDI"), and below the cap NU (Cayman, NYSE Class A — "NU HOLDINGS LTD/CAYMAN ISL-A"). Admitted on the ONON/KLAR precedent and distinguished from the BABA/FUTU/ARGX/JD/AZN/NVO exclusions, all of which are ADS/ADR structures. This is the standing unpinned line — see the owner question at the end.

## TOP-5

| # | Ticker | Qualifying event date | Event-day move | Window closes | Sessions left from 09-08 | One-line factual event description | D1 origin |
|---|---|---|---|---|---|---|---|
| **1** | **FRVO** | 2026-09-01 | **+28.4135%** | 2026-09-15 | **6** | Announced the world's largest enhanced-geothermal power-purchase agreement, against a risk-off tape. | `f1b8b782…` |
| **2** | **EIX** | 2026-08-31 | **−23.0725%** | 2026-09-14 | **5** | CA SB 492 emerged without wildfire-liability protection for investor-owned utilities; Mizuho cut to Neutral $70 the same morning. Worst session since 2001. | `0c8ece63…` |
| **3** | **PCG** | 2026-08-31 | **−20.0602%** | 2026-09-14 | **5** | Same SB 492 failure; second consecutive event-day decline, two-session compound ~−26.1%, bond spreads widened. | `0c8ece63…` |
| **4** | **CRDO** | 2026-09-01 *(inferred)* | **−20.0407%** | 2026-09-15 | **6** | Revenue +115% YoY and an EPS beat sold 20% lower on margin compression, customer concentration and a soft Q2 guide. | `1c3b3b46…` |
| **5** | **ESTC** | 2026-08-27 | **+19.3098%** | 2026-09-10 | **3** | Q1 FY27 revenue $478M +15%, subscription $449M +15%, non-GAAP EPS $0.70, adj FCF $143M — beat guidance across all key metrics. | `ec0c9a26…` |

Ranks 3 and 4 are separated by **0.02 pp** and should be read as tied. **PCG carries a second dated leg** (2026-09-02, −5.1920%, `1c3b3b46…`) which extends the thread's eligibility to **2026-09-16 (7 sessions)** — two past the 08-31 leg's own close. **ESTC is the least reachable name in the top tier**: 3 sessions.

## REST (ranked 6–15)

| # | Ticker | Qualifying event date | Event-day move | Window closes | Sessions left from 09-08 | One-line factual event description | D1 origin |
|---|---|---|---|---|---|---|---|
| 6 | SNOW | 2026-09-02 | **+16.5544%** | 2026-09-16 | **7** | Q2 FY2027 beat (adj EPS $0.62 vs $0.45; revenue $1.55B, +35% YoY); FY27 product-revenue guide raised to $6.07B from $5.84B. | `b606229e…` |
| 7 | DELL | 2026-09-01 | **+15.8118%** | 2026-09-15 | **6** | FQ2 2027: ISG +89%, $16.4B AI-optimised server revenue, FY guide raised to ~$192B revenue / $25.50 EPS. | `1c3b3b46…` |
| 8 | MDB | 2026-09-01 *(inferred)* | **−13.5441%** | 2026-09-15 | **6** | Beat-and-raise (revenue +30% YoY, guide lifted to $2.99–3.03B) sold off on rising AI-infrastructure cost concerns. | `1c3b3b46…` |
| 9 | VSXY | 2026-09-03 | **−13.1706%** | 2026-09-17 | **8** | Soft Q3 operating-income outlook ($10–20M); the prior quarter's income had been inflated by ~$140M of one-time tariff refunds. | `b606229e…` |
| 10 | GAP | 2026-08-27 | **+12.9389%** | 2026-09-10 | **3** | Q2 FY26 net sales $3.7B −2% YoY, comps −1%, adj EPS $0.52, FY guide raised; Old Navy's first negative comp in ~3 years. | `ec0c9a26…` |
| 11 | SOLS | 2026-08-28 | **+12.7618%** | 2026-09-11 | **4** | Q2 adj EPS $0.88 vs $0.77, revenue $1.15B vs $1.08B, FY26 guide raised, $500M buyback authorized. | `ec0c9a26…` |
| 12 | PYPL | 2026-08-28 | **−12.7054%** | 2026-09-11 | **4** | Stripe-led group with Advent abandoned a ~$50B take-private pursuit after the board rejected the offer as insufficient. | `ec0c9a26…` |
| 13 | CRK | 2026-09-01 | **+11.0187%** | 2026-09-15 | **6** | $1.65B SOCAR strategic partnership plus a $450M Haynesville drilling JV. | `f1b8b782…` |
| 14 | CIEN | 2026-09-03 | **−10.3625%** | 2026-09-17 | **8** | Record Q3 FY2026 beat (adj EPS $2.11 vs $1.72; revenue $1.67B record, +37% YoY) sold off 10.4%. | `b606229e…` |
| 15 | MRVL | 2026-08-27 | **−10.2837%** | 2026-09-10 | **3** | Q2 FY27 beat (revenue $2.739B record +37% YoY, EPS $0.94) sold off on a softer FY28 guide and the Google AI-chip payoff pushed to FY2029. | `ec0c9a26…` |

## BELOW THE CAP — five rankable items not in the 15

The cap of 15 is unchanged. These five are genuinely rankable — each clears B's ≥5% floor and each has an identified issuer event — and are excluded **only** by the cap, being the five smallest eligible magnitudes. Named so the exclusion is visible rather than silent, and because three of them hold longer windows than several ranked names.

| Ticker | Qualifying event date | Event-day move | Window closes | Sessions left | Ground |
|---|---|---|---|---|---|
| CPB | 2026-09-03 | −6.9386% | 2026-09-17 | **8** | 16th by magnitude. Longest window in the cohort. |
| TTC | 2026-09-03 | −6.8381% | 2026-09-17 | **8** | 17th by magnitude. Longest window in the cohort. |
| NU | 2026-09-02 *(anchor NOT ESTABLISHED)* | +6.5007% | 2026-09-16 | **7** | 18th by magnitude. Release timing not established, so the window may be one session shorter. |
| BMNR | 2026-08-31 | +6.3866% | 2026-09-14 | **5** | 19th by magnitude. See the price-layer finding above — its larger 09-03 move has no D1 disposition and is not rankable as a new identity. |
| HPE | 2026-09-02 | +5.0357% | 2026-09-16 | **7** | 20th by magnitude, and the narrowest clearance of the 5% floor in the whole eligible set. |

## ROUTING — no thesis-construction enqueue is owed, and W4 must not create one

B is **DO-NOT-ACTIVATE**. Per W4 §C the top-tier candidates route to `Watchlist.md`'s **"Strategy B watch overflow"** section marked **router-gated, not rank-gated**, and **no** `PENDING_ANALYSIS` thesis-construction row is enqueued. `analytics.strategy_nav` for B reads `nav 0.00 / deployed_mv 0.00 / available_funds 0.00`, so there is no capital to size against today regardless — though per the note in SCOPE that zero is a today-only fact, not a safety property.

**THE DRAIN CANNOT REACH ANY OF THESE 15, AND THIS RUN CAN STATE THAT WITH DATES.** M4 §A gained a "B FLIP TO ACTIVATE" limb on 2026-08-31 (commit `ea95ee7`) that drains overflow rows whose window is still open on the flip date — so the write-only-surface defect W4 reported on 2026-08-30 is genuinely closed. What remains open is the **cadence** gap already filed as `ops.alerts` info `022d6490-2500-4670-beb2-9f554056629a` (M4-discovered 2026-09-01, owning routine W5). Measured against this cycle's cohort it is sharper than that row states:

- Every window above closes between **2026-09-10 and 2026-09-17**. The next M4 fires ~**2026-10-01**. So even on a router flip tomorrow, M4's drain limb reaches **zero** of the 15 — all expire ungraded.
- The next W4 fires **2026-09-13**, and W4 §C converts only the *fresh* W2 intake it reads that day, not the overflow backlog. So the five candidates closing 09-10 and 09-11 — **ESTC, GAP, MRVL, SOLS, PYPL** — expire before any consumer of any kind next fires.

**This is recorded, not re-alerted.** `022d6490` is open, names its owner, and describes the same mechanism; raising a second info row for one condition is the alarm-fatigue pattern the INCIDENT INHERITANCE rule exists to prevent. The sharpening above is carried in this file and in this run's `post-event-enrichment` decision row so it reaches W5 through the surface W5 actually reads. **W2 does not propose a fix**: adding an off-cycle drain changes another routine's action set with capital consequences, and W4 §C assigns the router/window interaction to W5 and M1a explicitly.

---

## FINDINGS FOR D1 — two, both upstream, neither fixed here

Both are D1 screen-design defects. W2 is not D1's surface and does not touch it; both are filed as `ops.alerts` info rows naming D1 and their consuming surface, per the shared OUT-OF-SCOPE FINDINGS rule.

**F1 — `fields` schema drift across five consecutive `single-name-move` screens, and FOUR of the five land in W5's scorecard with a NULL ticker on every item.** MEASURED against `state.research_screen_calls`, the view W5's RESEARCH-SCREEN SCORECARD reads:

| Screen date | item rows | `name` populated | `metric_pct` populated | `conviction_pct` populated | `population_rail` / `legacy_rule` / `agreement_*` |
|---|---|---|---|---|---|
| 2026-08-30 | 16 | **0** | 16 | **0** | **all NULL** |
| 2026-08-31 | 9 | **0** | 9 | **0** | **all NULL** |
| 2026-09-01 | 16 | **0** | 16 | **0** | **all NULL** |
| **2026-09-02** | 15 | **15** | 15 | **15** | **all populated** |
| 2026-09-03 | 20 | **0** | **0** | **0** | **all NULL** |

The view's canonical per-item contract is `name` / `metric_pct` / `conviction` / `conviction_pct` / `reason` / `below_spec_floor` / `legacy_rule_pass`. **The 2026-09-02 screen is the only one of the five that conforms**; the others write `ticker` instead of `name`, `conviction` without `conviction_pct`, `driver` instead of `reason`, and 09-03 additionally writes `move_pct` instead of `metric_pct`. The top-level `population_rail`, `legacy_rule` and the three `agreement_*` counts are likewise present only on 09-02. **Consequence:** on four of the last five screening days the scorecard cannot attribute a single surfaced name, because the ticker column is NULL for every row. W5's 2026-08-30 run recorded that its screens-rejecting-winners check was **VACUOUS this cycle** — consistent with this cause, though this run did not establish causation and does not claim it. Note the inversion worth flagging to any later reader: 09-02 is the screen that *looks* anomalous item-by-item and is in fact the only correct one.

Separately and on the same row: the 09-02 screen carries **no `market_cap_usd` and no `qualifying_event_date` on any item**, which is what forced this run to infer the population-rail clearance for CRDO/MDB/PCG by inspection and to resolve the CRDO/MDB/DELL anchors from price bars rather than from the record.

**Not blocking:** W2 recovered everything it needed by reading `body_md` and the raw `fields` JSON directly. Filed rather than fixed because D1's screen-write contract is D1's surface.

**F2 — a ≥5% single-name move on a screened session with no disposition anywhere.** BMNR closed **+14.7008% on 2026-09-03** (measured on IBKR RTH daily bars). D1's S5 screened that session and BMNR appears in neither `passed` nor `rejected_notable`. BMNR was screened by D1 on both 08-31 and 09-01, clears the ≥2% move rail by 7x and the ≥$2B cap rail by ~7x at ~$14.4B. The move's cause is **NOT ESTABLISHED** here — identifying it would require the metered discovery W2 is forbidden — so this is a completeness report, not a candidate. Same class as the COHR −7.99% miss of 2026-08-13 that the price layer caught after the headline layer did not. **HONEST LIMIT:** found only because BMNR was already in this run's pull as an existing candidate; this was not a market sweep and nothing here establishes that anything else was missed.

---

## HONEST LIMITS OF THIS RUN

- **Index mode means no candidate below has been evaluated against B's entry criteria 2, 3 or 4.** No mispricing read, no retrieved comparables, no information-versus-sentiment analysis, no convergence indicators. Every rank is a magnitude ordering over items that passed criteria 1 and 5 — nothing more, and it must not be read as a conviction ordering.
- **Two qualifying-event anchors are INFERRED, not measured** (CRDO and MDB at 2026-09-01). The bars establish the reaction session; the release timing is inferred from the after-close reporting pattern and from D1's explicit establishment of the same date for DELL in the same screen. If either released pre-market on 09-02, its window runs one session longer than shown.
- **Two anchors are NOT ESTABLISHED at all** (NU, and PCG's 09-02 leg) because D1's 09-02 screen carries no `qualifying_event_date` field. Both are recorded at the measured reaction session and flagged in place.
- **Three market-cap clearances are by inspection, not measured** (CRDO, MDB, PCG's 09-02 leg), for the same reason. All three are an order of magnitude above the $2B floor, well outside the ~25% band that would require an issuer-filing derivation.
- **SOLS's event is secondary-sourced.** D1 records that the IR release was not fetched directly. Ranked 11th on that basis and labelled as such rather than treated as gate-verified to the standard of MRVL/ESTC/CIEN.
- **VSXY's symbol/description pairing is unresolved.** IBKR returns contract 502415513, NYSE, "VICTORIA'S SECRET & CO" under the symbol VSXY, while a Mexican cross-listing in the same result set carries the historical "VSCO" symbol. This was the only plausible US common-equity match and it is used, but the mismatch is flagged rather than smoothed. VSXY is ranked 9th and any session acting on it should re-resolve the contract first.
- **The 2026-09-04 session is uncovered by design** and any qualifying event on it is invisible to this cycle. D1's Sunday scan owns it.
- **Series B is a 17-name panel over four sessions, not a base rate.** Two cycles of cross-section plus one cycle of panel is not enough to settle B's convergence question; FINDING 1 corrects a prior *inference*, it does not establish the opposite claim.
- **No sub-pattern routing was performed.** `B_Sub_Pattern_Taxonomy.md` was read for reference, but routing a candidate against a documented sub-pattern is part of the criterion-4 adversarial step that index mode skips. The one sub-pattern claim made anywhere in this file is FINDING 3's SP5 observation, which is about a *prior* cycle's already-recorded flag resolving, not about any candidate here.

---

## OPEN QUESTION CARRIED FORWARD FOR THE OWNER — the ADR / ordinary-share line, fourth consecutive cycle

`strategy/04_strategy_b.md` says only **"US-listed common equity."** It does not distinguish a foreign issuer's US-listed *ordinary* shares from a *depositary receipt* over shares that trade primarily elsewhere, and every session re-derives the line from precedent. It decided real dispositions again this week: **CRDO** (Cayman-incorporated, Nasdaq ordinary shares) is ranked **4th**, and **NU** (Cayman-incorporated, NYSE Class A ordinary shares) sits just below the cap — both admitted on the ONON/KLAR precedent, both distinguished from the BABA, FUTU, ARGX, JD, AZN and NVO exclusions, which are ADS/ADR structures over a foreign primary listing.

The distinction being applied is **where the primary listing is**, not the filing form — the 2026-08-23 cycle established that the 20-F form is *not* a usable diagnostic, since both the excluded ARGX and the admitted ONON file it as foreign private issuers. That test has now held for four cycles and has never been written down. Pinning it is a `Strategy.md` change and B's machinery is spec-locked for its life, so it is an owner or SL-path decision, not one W2 may make. Raised again because a rule that decides top-5 membership on unwritten precedent is one session's differing reading away from an inconsistent roster.

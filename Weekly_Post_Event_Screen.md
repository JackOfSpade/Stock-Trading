2026-W35

# Weekly Post-Event Screen — Strategy B (W2)

**Run:** 2026-08-30 (Sun, ISO week **2026-W35**, per `state.trading_day_today.today`; `is_trading_day=false`, `last_trading_day=2026-08-28`, `next_trading_day=2026-08-31`). Every price figure in this file is a completed regular-session close. No live, intraday or after-hours print is load-bearing anywhere.

**Same-day double-run guard: PASSED.** `ops.run_log` shows **0** `completed` and **0** `started` W2 rows for `run_date=2026-08-30`, so this is not a redundant re-invocation.

**Catch-up check — no widening owed.** `state.routine_catchup_window` for `W2`: `window_start_ts=2026-08-23T09:52:46Z`, `never_completed=false`, `window_days=6.98`. Against a 7-day normal weekly look-back that is **1.00x**, under the 1.5x bar, so **no `CATCHUP` token is owed**. The intake watermark used below is that same `2026-08-23T09:52:46Z`.

**Marker note.** The prior file carried `2026-W34`; this one carries `2026-W35`. Unlike the previous two cycles (which both legitimately stamped W34 from opposite ends of one ISO week), this cycle's Sunday-anchored period `[08-30, 09-05]` and its ISO week `2026-W35` agree, so no aliasing caveat is owed this run.

---

## SCOPE OF THIS RUN — WHAT W2 DOES AND DOES NOT DO

W2 performs **zero market-wide discovery**. It does not pull broad price bars to enumerate movers, does not repeat an event search, and does not re-judge §19 significance. Its intake is the durable D1 record since W2's own last successful completion. This run therefore spawned **no discovery sub-agent** and made **no metered population pull** — the FMP earnings/dividend/IPO calendars were not queried at all, and the shared-population-pull steps in W2's own prompt body are, per the reconciliation note added 2026-08-17, dormant for W2 and binding only on routines that genuinely do fan out for discovery.

**SCREEN MODE: INDEX (B router DO-NOT-ACTIVATE as of 2026-08-05).** This is the **first W2 cycle to run under the ROUTER GATE limb added 2026-08-24**, and it is the single largest change from the prior three cycles. Read `state.current_regime`, scope `STRATEGY_ACTIVATION`, key `B`: the value read is **`DO-NOT-ACTIVATE`**, divergence `div-B-202607-1`, `as_of_date=2026-08-05`, theater-check `DIVERGENT`. The router therefore bars every NEW B entry for the whole of each candidate's 10-trading-day window, and no candidate surfaced this run can reach an entry unless the router flips inside that window — which on the scheduled path only M1a can do. PART 2 accordingly runs in **INDEX MODE**: per-candidate it records ticker, qualifying event date, event-day move, window close, D1 origin id, a one-line factual event description and a rank, and it **skips** the four steps that carry this routine's per-candidate research cost — the mispricing direction/magnitude read, the retrieved-comparables step, the information-versus-sentiment analysis, and the convergence-indicator enumeration.

**Why that limb exists, restated from this run's own evidence.** Three consecutive router-gated cycles (2026-08-09, 08-17, 08-23) produced 15 full-depth candidate analyses and **not one was ever evaluated against B's entry criteria**; every window expired ungraded. This run's own intake confirms the pattern held a fourth time: the 2026-08-23 cycle's twelve ranked candidates were never enqueued, and by this run's last completed session their windows are spent or nearly so. The cohort-level work is **not** skipped — it is below, in full — because it costs little and is the evidence series a future divergence review reads when it re-tests B's convergence assumption.

**Fan-out that DID happen, and why it is not discovery.** Three Sonnet-5 sub-agents ran: one extracted the item table from five durable D1 `research-screen` decision rows (BigQuery reads only), one gathered exclusion state — open positions, existing B thesis-construction identities, the trading-day calendar (BigQuery reads only), and one pulled IBKR daily bars for the ranked cohort's trajectory test. **None of the three was permitted a metered call, and none made one.**

**MEASURED EXTERNAL SPEND THIS RUN: ZERO. Zero Tavily credits, zero Anthropic `web_search`/`web_fetch` calls, zero FMP requests, zero HF requests.** Index mode removed the enrichment steps that generate this routine's web volume, and the intake is entirely warehouse-resident. For contrast, the 2026-08-23 full-depth cycle logged **68** `ops.web_calls` rows for the same routine. Per the shared "Metered external calls" rule part (d), a run that made no metered call correctly writes no `ops.web_calls` row — and this file is the statement that the absence is a real zero, not an unreported run.

---

## WINDOW ARITHMETIC

B's frozen entry window is **10 trading sessions counting the event day as day 1** (Entry criterion 1, `strategy/04_strategy_b.md`). Trading sessions confirmed against `state.market_calendar`: 08-20, 08-21, 08-24, 08-25, 08-26, 08-27, 08-28, 08-31, 09-01, 09-02, 09-03, 09-04, 09-08 (09-05/06/07 = weekend + Labor Day). The next session is **Monday 2026-08-31**.

| Qualifying event day | Window closes (day 10) | Sessions left from 2026-08-31 |
|---|---|---|
| 2026-08-20 | 2026-09-02 | **3** |
| 2026-08-21 | 2026-09-03 | **4** |
| 2026-08-24 | 2026-09-04 | **5** |
| 2026-08-25 | 2026-09-08 | **6** |
| 2026-08-27 | 2026-09-10 | **8** |

**Carry-forward from the prior cycle is OUT OF THIS RUN'S INTAKE and was deliberately not re-enriched.** The 2026-08-23 file ranked 12 candidates on event days 8/17–8/20 (top-5 KLAR, WMT, AAP, FN, MRVL). Those items originate in D1 rows *before* this run's watermark, so PART 1 does not readmit them; their windows closed 2026-08-28 through 2026-09-02. **None was ever enqueued for thesis construction** — B has been DO-NOT-ACTIVATE throughout — which is the fourth consecutive cycle where that is true, and the direct evidence behind this run's index mode.

---

# PART 1 — D1-ORIGINATED POST-EVENT INTAKE (no market-wide re-screen)

## Intake source

Five operative D1 `entry_type='research-screen'`, `screen='single-name-move'` rows landed inside the watermark window. All five are un-superseded; no correction rows exist in this window (unlike the prior cycle, which had three).

| Tag | D1 decision id | D1 run date | Qualifying session screened | Surfaced |
|---|---|---|---|---|
| S1 | `00280ce2-7903-4ac8-8b58-c76885d82915` | 2026-08-23 (Sun) | **Friday 2026-08-21** (+ one 08-20 carry-in) | 11 |
| S2 | `4d30f5d9-9789-4bc8-9f47-c1059b6997f2` | 2026-08-24 | 2026-08-24 | 17 enumerated (`surfaced_count` field says 25 — see below) |
| S3 | `e57ba539-f24c-4718-9f19-da8e7248d158` | 2026-08-25 | 2026-08-25 | 9 |
| S4 | `a066efab-1fa6-4025-9379-f9a6df16ce21` | 2026-08-26 | 2026-08-26 | **0** (DEGRADED) |
| S5 | `25d669ed-fb32-4c3d-92f7-16d59c143535` | 2026-08-27 | 2026-08-27 | 17 |

**S1's qualifying date is NOT its run date, and this was verified rather than assumed.** D1's Sunday scan screens the prior Friday. S1's own body states *"Friday's (2026-08-21) movers decompose almost entirely into three group drivers"*, so its qualifying session is **2026-08-21**, not 2026-08-23. One S1 item carries a different date again: **BTDR's own record states "The qualifying day was 2026-08-20 and the 08-20 screen missed it"**, so BTDR is anchored to 08-20 and has the shortest window in the intake. **AAOI is the third date-anchoring exception**: S2 surfaced it on the 08-24 session but its own field pins `qualifying_event_date=2026-08-21` — the ATM 8-K filing date — with 08-24 recorded as the reaction session, per the Watchlist ANCHOR PIN. Anchoring AAOI to its reaction session instead would have overstated its remaining window by one session.

**The 2026-08-28 (Friday) session is NOT covered here, by design.** D1 runs Sun–Thu; its last completed screen is 2026-08-27 and its Sunday scan for 2026-08-30 had not fired at this run's start (`ops.run_log`: zero D1 rows for 2026-08-30). W2's own prompt body assigns the Friday/Saturday gap to that Sunday scan and forbids W2 from covering it early with its own bar pulls. Any qualifying 8/28 event enters through **next** week's W2, with a window that is by then one session shorter. This is the same disposition as the prior cycle and it is not a coverage defect.

**S4 (2026-08-26) contributed zero items, and that is a real hole, not an empty day.** S4 has no `passed[]` key at all; `surfaced_count=0`. Its coverage note records FMP `quote` + `news` plan-gated all session, FMP `company`/`chart` failing in a quota-exhaustion shape, and third-party quote pages serving silently stale Aug 18–24 caches with no staleness flag. ~12 candidate large-caps (ACN, BSX, CVNA, LLY, MRK, HOOD, SMCI, COIN, VRT, NTAP, DELL, GLW) could not be confirmed to a sourced regular-session close and were, in D1's own words, *"excluded, not reported … They are not evidence of absence; they are unmeasured."* **Consequence for this file: the 2026-08-26 session is a blind spot in this intake.** Any name that had a qualifying ≥5% event that day is missing from PART 2 and its window (closing 2026-09-09) will expire without W2 ever having seen it. W2 must not repair this with its own bar pulls; it is recorded as a finding for D1 below.

## Four-part identity dedupe — CLEAN

Checked `events.queue_events` (open **and** terminal) and `events.decision_log` for `analysis_type='thesis-construction'` + `strategy='B'` + ticker + `qualifying_event_date`, **matching on the FIELDS, never on the key string** (KEY-FORMAT PIN, corrected 2026-08-23 by W4). No ticker-only deduplication was used anywhere.

**No identity for any candidate below exists in either surface.** Every Strategy-B thesis-construction identity opened since 2026-08-01 is terminal: the five 2026-08-03 queue items (CARR, AAPL, LII, GDDY, VRT, all `status='complete'`, all NO-GO) and the fourteen `events.decision_log` rows dated 2026-08-03 through 2026-08-05 (BTSG, ALHC, VRT, LII, AAPL, TGTX, GDDY, VCYT, RDDT, SRAD, CARR, CTRI, CVS, DVA). **Every one carries a qualifying event date in July**, so none collides with this run's 08-20→08-27 window. There is no open (`status='pending'`) Strategy-B thesis-construction item anywhere.

**One near-collision worth naming: RDDT.** RDDT was adjudicated NO-GO on **2026-08-03** on a July qualifying event. It re-enters this run's intake on a **new and distinct** qualifying event (2026-08-25, the Meta-Hatch report). Under the four-part identity that is a different item and it remains eligible — a later distinct event on a name already seen is not a duplicate. Its prior NO-GO is context, not a barrier ("NO-GO records are context, not barriers"), and it is carried into PART 2 with that history attached.

## Items preserved from D1

D1's figures are preserved verbatim. **This run did not recompute a single event-day move and did not revisit a single D1 significance verdict** — both are forbidden to W2. All 5 screens measured on IBKR `get_price_history` step=ONE_DAY, `outside_rth=false` regular-session daily bars; S5 additionally cross-checked NVDA against an FMP quote on identical closes.

### Rankable — passes BOTH D1's §19 significance judgment AND B's frozen spec floor (≥5% event-day move)

| Ticker | Qualifying event date | Move | D1 conviction | `legacy_rule_pass` | `below_spec_floor` | D1 origin |
|---|---|---|---|---|---|---|
| DKS | 2026-08-25 | **−30.68%** | 75 | true | false | S3 |
| OKTA | 2026-08-27 | **+28.63%** | 60 | true | false | S5 |
| CRM | 2026-08-27 | **+22.58%** | 75 | true | false | S5 |
| CRWD | 2026-08-27 | **+20.50%** | 60 | true | false | S5 |
| VEEV | 2026-08-27 | +15.20% | 60 | true | false | S5 |
| UEC | 2026-08-21 | +14.44% | 45 | true | false | S1 |
| AAOI | **2026-08-21** (8-K date; 08-24 reaction) | −13.77% | 60 | true | false | S2 |
| HOOD | 2026-08-21 | +13.70% | 60 | true | false | S1 |
| WEN | 2026-08-27 | −13.50% | 45 | true | false | S5 |
| PANW | 2026-08-27 | +12.83% | 45 | true | false | S5 |
| MSTR | 2026-08-27 | +11.54% | 30 | true | false | S5 |
| DNN | 2026-08-21 | +11.46% | 60 | true | false | S1 |
| NOW | 2026-08-27 | +10.04% | 45 | true | false | S5 |
| FUTU | 2026-08-21 | +9.68% | 45 | true | false | S1 |
| BTDR | **2026-08-20** | +9.01% | 60 | true | false | S1 |
| NVDA | 2026-08-27 | +8.74% | 75 | true | false | S5 |
| BABA | 2026-08-21 | −8.57% | 75 | true | false | S1 |
| QBTS | 2026-08-21 | +8.46% | 60 | true | false | S1 |
| BBWI | 2026-08-25 | −8.29% | 60 | true | false | S3 |
| STX | 2026-08-24 | −6.51% | 60 | true | false | S2 |
| SNDK | 2026-08-24 | −6.45% | 60 | true | false | S2 |
| RDDT | 2026-08-25 | +6.39% | 60 | true | false | S3 |
| MU | 2026-08-24 | −5.83% | 75 | true | false | S2 |
| MARA | 2026-08-27 | +5.79% | 30 | true | false | S5 |
| BJ | 2026-08-21 | +5.61% | 60 | true | false | S1 |
| WDC | 2026-08-24 | −5.24% | 60 | true | false | S2 |
| SRE | 2026-08-21 | −5.14% | 60 | true | false | S1 |
| TSLA | 2026-08-21 | +5.14% | 60 | true | false | S1 |

**28 rankable items — the largest W2 intake on record** (the prior three cycles ran 12, 15 and 12). The driver is arithmetic, not a regime change: the 08-27 session alone contributed 10 names clearing the 5% floor because a synchronised software/cyber earnings block reported into it.

### Context only — `below_spec_floor=true` (<5% event-day move, not rankable per spec)

Twenty-six further items were surfaced by D1 as AI-significant but fall below B's frozen 5% floor and are therefore **context, never rankable**: NVDA, HOOD, COIN, TSLA, AMD, INTC, MSTR, WMT, TGT, AVGO, COST, UNH (S2, 08-24); TGT, MRK, DELL, CVNA, NOK, FCX (S3, 08-25); PLTR, INTC, DLTR, BABA, HPQ, SMCI, IREN (S5, 08-27); AEP (S1, 08-21). Note the shape: the same tickers recur across sessions on different dates and in opposite directions — **TSLA +5.14% on 08-21 then −3.83% on 08-24; INTC −3.12% on 08-24 then +4.36% on 08-27; MSTR +2.83% on 08-24 then +11.54% on 08-27; TGT +2.69% on 08-24 then −3.78% on 08-25; BABA −8.57% on 08-21 then −2.94% on 08-27.** These are five distinct items under the four-part identity, not five duplicates, and only the ones clearing 5% are rankable.

### Identities EXCLUDED before enrichment, with the ground

Eleven of the 28 rankable items are excluded before any enrichment. Every ground below is drawn from **D1's own recorded text or from B's frozen spec** — no new research was performed to establish any of them.

| Ticker | Move | Ground | Precedent |
|---|---|---|---|
| **BABA** | −8.57% | **Instrument eligibility.** NYSE-listed ADS; ordinary shares trade on HKEX. B admits US-listed common equity. | Same ground as BIDU, BNTX, ARGX (excluded 2026-08-17 / 08-23) |
| **FUTU** | +9.68% | **Instrument eligibility.** Nasdaq-listed ADS. D1 additionally records the move as *"unexplained delayed repricing"* whose own event day (08-20) moved only +3.02%, below floor. | Same |
| **WEN** | −13.50% | **Population rail unresolved.** D1's own record states the screen *"does NOT assert WEN is in the population"* — implied cap ~$1.6B against the $2B floor, and FMP per-symbol market-cap and secFilings are both denied on this tier. Not measured here; index mode does not spend a call to resolve it. | Exactly the WOLF disposition (2026-08-23, measured $1.37B) |
| **QBTS** | +8.46% | **Criterion 1 — no qualifying issuer event.** The driver is a BMO *initiation* at Outperform/$35 PT; RGTI and IONQ moved on the same note. An analyst action is not among criterion 1's event types. | CRWD and IOVA excluded 2026-08-23 on "analyst opinion only" / "analyst PT cluster only" |
| **SRE** | −5.14% | **Criterion 1 + sector-wide.** A coverage-wide Morgan Stanley utility PT cut hitting SRE and 7 sibling names; **D1 itself declined it as sector-wide, not single-name.** | Same |
| **UEC** | +14.44% | **Criterion 1 — no company-specific event.** D1: *"No company-specific event found; moved with uranium-sector strength alongside DNN."* | ISRG excluded 2026-08-23, "no qualifying event" |
| **HOOD** | +13.70% | **Criterion 1 — no company-specific event.** D1 records a ~$3.3B crypto-proxy short squeeze on BTC above $77K with no individual catalyst (and CIFR moved −8.40% *against* the complex on the same day). | Same |
| **MSTR** | +11.54% | **Criterion 1 — beta, not information.** D1: *"co-moved with IBIT/ETHA/BITO/MARA with no company-specific event found; beta, not information."* | Same |
| **MARA** | +5.79% | **Criterion 1 — same crypto-complex co-movement, no company event identified.** | Same |
| **PANW** | +12.83% | **Criterion 1 — attribution not established.** D1: *"its OWN catalyst was not confirmed this run — recorded as probable halo rather than asserted as an event-driven move."* | Same |
| **NOW** | +10.04% | **Criterion 1 — attribution not established.** D1: *"own catalyst and report timing not independently confirmed."* | Same |

**Expired B windows: none.** Every intake item's window closes 2026-09-02 or later.
**Names with an open Strategy A position: none.** `state.current_positions` holds 12 open rows and **every one is Strategy D** (AMZN ×2, DIS ×2, GEV, GOOGL ×2, ISRG, RTX, TSM ×2, UBER). There are zero open A positions and zero open B positions — Strategy B has been flat since MSCI closed 2026-08-18 — so criterion 5 excludes nothing this run.

**One cross-strategy fact that is NOT an exclusion but must travel with the item: CRM.** This book held **D:CRM** and D2 exited it on a correctly-measured −20bp YoY operating-margin breach; that exit **filled at the open of the very 2026-08-27 session in which CRM closed +22.58%** on a revenue beat, raised FY27 guide and a $2.6B Anthropic-stake gain. Criterion 5 bars only a concurrent open **A** position, and the D position is closed, so CRM is formally eligible for B. It is nonetheless the one item in this intake where a thesis pass would be constructing a long case on a name this framework sold hours earlier on its own invalidation criteria, and any future pass must confront that directly rather than discover it late.

---

## POST-EVENT TRAJECTORY — the residual-thinness test

Cohort-level work, computed across the whole eligible intake — the 15 ranked names plus the two below-cap items (BTDR, DNN) — rather than per candidate. Index mode does **not** silence this. IBKR `get_price_history`, `security_type=STK`, `step=ONE_DAY`, `outside_rth=false`, 22 regular-session bars per name, all stamped `13:30:00Z`; every ticker returned a bar for 2026-08-28 and no contract was ambiguous. **"Gap still intact"** is `(08-28 close − pre-event close) ÷ (event-day close − pre-event close)`: 100% means the whole event move is still there, 0% means it has fully round-tripped, and above 100% means the move extended.

**PRICE-BASIS RECONCILIATION — ZERO CORRECTIONS OWED, and this is a real check rather than a formality.** These bars were pulled independently of D1's, and **every one of the 17 event-day moves recomputes to D1's recorded figure** — DKS −30.68%, CRM +22.58%, OKTA +28.63%, CRWD +20.50%, VEEV +15.20%, AAOI −13.77%, NVDA +8.74%, BBWI −8.29%, STX −6.51%, SNDK −6.45%, RDDT +6.39%, MU −5.83%, BJ +5.61%, WDC −5.24%, TSLA +5.14%, DNN +11.46%, BTDR +8.31% on its 08-20 qualifying day. W2 did not recompute these to second-guess D1 and does not revisit its verdicts; the closes were pulled for the trajectory and the agreement fell out of it.

| Ticker | Sessions elapsed since event | Pre-event close | Event-day close | 2026-08-28 close | Move since event day | **Gap still intact** | Shape |
|---|---|---|---|---|---|---|---|
| **CRM** | 1 | 205.62 | 252.05 | 256.00 | +1.57% | **108%** | held and extended |
| **OKTA** | 1 | 134.42 | 172.91 | 166.23 | −3.86% | **83%** | mild give-back |
| **CRWD** | 1 | 189.18 | 227.96 | 218.40 | −4.19% | **75%** | give-back |
| **VEEV** | 1 | 244.91 | 282.13 | 276.69 | −1.93% | **85%** | mild give-back |
| **NVDA** | 1 | 209.66 | 227.98 | 217.55 | −4.57% | **43%** | **over half the gap gone in one session** |
| **DKS** | 3 | 179.33 | 124.31 | 135.09 | **+8.67%** | **80%** | three consecutive up-closes; bounce underway |
| **BBWI** | 3 | 19.17 | 17.58 | 19.22 | **+9.33%** | **−3%** | **fully round-tripped, and through the pre-event close** |
| **RDDT** | 3 | 152.70 | 162.45 | 153.00 | −5.82% | **3%** | fully round-tripped |
| **MU** | 4 | 966.78 | 910.43 | 932.86 | +2.46% | **60%** | partial recovery |
| **SNDK** | 4 | 1596.08 | 1493.12 | 1484.98 | −0.55% | **108%** | extended |
| **STX** | 4 | 850.00 | 794.65 | 829.76 | **+4.42%** | **37%** | most of the gap recovered |
| **WDC** | 4 | 459.44 | 435.38 | 459.45 | **+5.53%** | **0%** | **exactly back to the pre-event close** |
| **AAOI** | 4 (from the 08-24 reaction) | 124.82 | 107.63 | 106.23 | −1.30% | **108%** | extended |
| **TSLA** | 5 | 345.13 | 362.86 | 348.75 | −3.89% | **20%** | mostly round-tripped |
| **BJ** | 5 | 91.30 | 96.42 | 90.60 | −6.04% | **−14%** | **round-tripped below the pre-event close** |
| **DNN** | 5 | 3.14 | 3.50 | 3.39 | −3.14% | **69%** | partial give-back |
| **BTDR** | 6 | 9.63 | 10.43 | 10.32 | −1.05% | **86%** | held |

**AAOI is measured off its reaction session, not its anchor date, and the distinction is load-bearing.** Its qualifying event date is 2026-08-21 (the ATM 8-K), but the 08-21 session moved only −3.32%; the −13.77% D1 recorded is the 08-24 reaction. The gap measured here is therefore the 124.82 → 107.63 reaction gap. Measuring from the 08-21 close instead would have shown a −14.89% "move since event day" and implied the reaction was still building, which is the opposite of what happened.

### What the cohort says

**Read against this framework's own precedent, a gap that has already closed kills the edge** (VRT was declined at 86–99% retraced, DHR at 79%). **Five of the seventeen are at or past that bar after less than a week: BJ (−14%), BBWI (−3%), WDC (0%), RDDT (3%), TSLA (20%).** Two more — NVDA (43%) and STX (37%) — are well past halfway. That is a materially faster convergence cohort than the prior cycle's, which reported "unusually fat" residuals and nothing disqualified for thinness.

**The elapsed-session confound is real and cuts against over-reading the fast names.** The five 08-27 reporters have had exactly **one** session, so their 43–108% band says almost nothing about eventual convergence; NVDA's 43% is striking precisely because it took one session, not because 43% is low. Conversely BJ, TSLA, WDC, BBWI and RDDT have had 3–5 sessions and are done — those are the real round-trips.

**The finding that matters for B's mechanism, stated so a future divergence review can test it.** Sorting by elapsed sessions rather than by name, **the convergence is monotone**: the 1-session block averages ~79% intact, the 3-session block ~27%, the 4-session block ~78% (dragged up entirely by the two extenders SNDK and AAOI; the other two, WDC and STX, are at 0% and 37%), and the 5–6 session block ~57% (dragged up by BTDR's 86%; BJ and TSLA are at −14% and 20%). **Post-event moves in this cohort are decaying inside the 10-session entry window, not persisting** — which is the mean-reversion signature B's fundamental question asks about ("is the current environment one in which event reactions show measurable mean reversion at 2–8 week horizons?"), and it is the opposite of the prior cycle's read, where "held and extended" dominated and argued the market was still absorbing information.

**Three names extended rather than decayed, and all three have a supply or policy driver rather than a pure earnings surprise:** AAOI (108%, a dilution overhang that continues to press), SNDK (108%, the CXMT/Samsung policy report), CRM (108%, one session only). The clean earnings-surprise names are the ones giving it back.

**The blunt consequence: the two weeks in which B's screen has produced its fattest intake are also the two weeks in which the router has held it shut.** This run cannot act on that and does not propose to — the DNA is a valid override, adjudicated adversarially, and W2 has no authority over it. But the trajectory series above is the evidence, and it now points the other way from the 2026-08-23 series, so it is recorded plainly rather than left implicit.

---

# PART 2 — RANKED SHORTLIST (INDEX MODE)

**SCREEN MODE: INDEX (B router DO-NOT-ACTIVATE as of 2026-08-05).**

**⚠ ROUTING STATUS — READ BEFORE CONVERTING ANYTHING. This PART 2 is a RESEARCH INDEX, not a staging list, and this cycle it is deliberately thinner than a full-depth one.**

- **Strategy B is `DO-NOT-ACTIVATE`.** `state.current_regime`, scope `STRATEGY_ACTIVATION`, key `B`, value `DO-NOT-ACTIVATE`, divergence `div-B-202607-1`, `as_of_date=2026-08-05`, theater-check `DIVERGENT`. The DNA is produced entirely by the universal `shock_overlay=acute` reconciliation override, not by B's own legs. It blocks **new B entries only**; existing B positions run to their own mechanical exits — and there are none open.
- **B's own router legs pass independently, and have loosened further.** As of 2026-08-27: `SPY_TREND = UP` (771.10) and `VIX_REGIME = LOW` (14.51). B's activation rule is `SPY Trend ≠ DOWN AND VIX ≠ HIGH`, so both legs hold with room; VIX has moved 16.01 (08-20) → 14.51 (08-27), further from the HIGH exclusion. **The gate holding B shut is entirely the shock-overlay override, and nothing in B's own machinery.**
- **B has no capital.** `analytics.strategy_nav` for B: `deployed_mv = 0`, `nav = 0`, `available_funds = 0`, `sizing_base_2pct = 0`, `deposits = −18.22`, `realized_pnl = 17.45`. Roster state is `ADOPTED`/`is_active=true`, so this is a capital condition, not a lifecycle one. Even were the DNA lifted on Monday, there is nothing to size against.

**W4 must not enqueue these as staged entries while the DNA stands.** Route this shortlist to `Watchlist.md`'s "Strategy B watch overflow" section marked **router-gated, not rank-gated** — these are the *best* candidates of the week, not the leftovers, and none has been analysed against B's criteria. The prior three cycles reached the same disposition; expect the same here.

## Calibration prior for the reader

`events.decision_log` Strategy-B `thesis-construction` rows since 2026-06-01: **3 GO** (FTV 2026-07-29, MSCI 2026-07-27, MTZ 2026-08-03 — the last staged but halted on `trading_enabled=FALSE`) against **79 NO-GO** and 1 NO-ACTION. The dominant NO-GO grounds are criterion 4 information-driven (SP4a/SP4c families) and SP1 sell-side bull-ratification of an up-mover. **Eleven of the fifteen names below are up-movers on their own earnings beats — squarely inside the SP1/SP4 families.** That is not a reason to decline them in advance ("NO-GO records are context, not barriers"), but it is the base rate any future thesis pass should be honest about, and it is materially less favourable than the prior cycle's cohort, which was decliner-weighted.

## Ranking basis (stated, because index mode gives the reader nothing else to audit)

Rank is research priority if the router flips inside a window — not conviction, and not a mispricing estimate, neither of which this mode computes. The ordering weighs, in order: (1) **event quality** — issuer-disclosed and resolved (earnings/guidance) outranks policy/regulatory, which outranks a third-party report; (2) **magnitude** of the reaction; (3) **sessions remaining**; (4) **independence** — four names on one shared catalyst are one bet, so they are spread down the order rather than clustered at the top.

## TOP-5

| # | Ticker | Qualifying event date | Event-day move | Window closes | Sessions left from 08-31 | One-line factual event description | D1 origin |
|---|---|---|---|---|---|---|---|
| **1** | **DKS** | 2026-08-25 | **−30.68%** | 2026-09-08 | **6** | Q2 FY2026 miss on both lines plus an FY guide cut on both lines, reported BMO 08-25; Foot Locker pro-forma comps −3.6%; worst session since 2023 on 12.4x volume. | `e57ba539…` |
| **2** | **CRM** | 2026-08-27 | **+22.58%** | 2026-09-10 | **8** | Revenue beat, raised FY27 guide, disclosed a $2.6B Anthropic-stake gain. | `25d669ed…` |
| **3** | **OKTA** | 2026-08-27 | **+28.63%** | 2026-09-10 | **8** | FQ2 FY2027 beat (revenue $805M, +11% YoY) with raised FY guidance; largest percentage move on the tape. | `25d669ed…` |
| **4** | **CRWD** | 2026-08-27 | **+20.50%** | 2026-09-10 | **8** | Q2 FY2027 revenue $1.47B (+26% YoY), ARR $5.84B (+25%), raised net-new-ARR outlook by 630bps. | `25d669ed…` |
| **5** | **AAOI** | **2026-08-21** | **−13.77%** | 2026-09-03 | **4** | 8-K filed 08-21 for a $600M ATM equity offering; sold off on dilution despite a record Q2 (revenue $191.9M, data-centre +140%, non-GAAP profitable). | `4d30f5d9…` |

**Why these five.** DKS is the cohort's cleanest B shape by a wide margin — the largest dislocation, issuer-disclosed and fully resolved, on a name whose reaction propagated a measurable contagion cone into TGT/KSS/BBWI, which is precisely the "reaction size versus information content" question B exists to ask. CRM, OKTA and CRWD are the three largest issuer-disclosed up-moves with the longest windows in the intake, and each reported its own numbers rather than riding a complex. AAOI is ranked fifth only because of its 4-session window: on shape it is the most interesting item here — a **record** quarter sold off on a **financing** disclosure, which is a textbook information-versus-sentiment separation and the one item in the cohort where the mispricing question has an obvious axis.

## REST (ranked 6–15)

| # | Ticker | Qualifying event date | Event-day move | Window closes | Sessions left | One-line factual event description | D1 origin |
|---|---|---|---|---|---|---|---|
| 6 | VEEV | 2026-08-27 | +15.20% | 2026-09-10 | 8 | Q2 beat with raised FY27 guidance; third independent reporter in the vertical-software complex moving on its own numbers. | `25d669ed…` |
| 7 | NVDA | 2026-08-27 | +8.74% | 2026-09-10 | 8 | FQ2 FY2027 beat with a Q3 guide of $108.0B ±2% against ~$104B consensus; primary-verified against nvidianews.nvidia.com. | `25d669ed…` |
| 8 | BBWI | 2026-08-25 | −8.29% | 2026-09-08 | 6 | Gapped down on the DKS guidance cut and never traded above its open — positioning ahead of BBWI's own print, not new information about BBWI. | `e57ba539…` |
| 9 | MU | 2026-08-24 | −5.83% | 2026-09-04 | 5 | Reports the administration may permit Apple to source memory from China's CXMT ahead of a Xi visit, plus a weak Samsung dividend/guidance signal. | `4d30f5d9…` |
| 10 | RDDT | 2026-08-25 | +6.39% | 2026-09-08 | 6 | The Information reported Meta is building a consumer AI agent (Hatch) trained to browse and act on Reddit — a competitor's unshipped product, not an issuer disclosure. | `e57ba539…` |
| 11 | TSLA | 2026-08-21 | +5.14% | 2026-09-03 | 4 | Nevada regulator cleared up to 5,000 driverless robotaxis in Las Vegas. | `00280ce2…` |
| 12 | SNDK | 2026-08-24 | −6.45% | 2026-09-04 | 5 | Same CXMT/Samsung memory-complex catalyst as MU; purest expression of it, and the stock was +505% YTD into the session. | `4d30f5d9…` |
| 13 | STX | 2026-08-24 | −6.51% | 2026-09-04 | 5 | Same CXMT/Samsung catalyst; D1 records attribution as partly technical (profit-taking, insider-sale overhang). | `4d30f5d9…` |
| 14 | WDC | 2026-08-24 | −5.24% | 2026-09-04 | 5 | Same CXMT/Samsung memory-complex catalyst; fourth expression of it. | `4d30f5d9…` |
| 15 | BJ | 2026-08-21 | +5.61% | 2026-09-03 | 4 | Q2 FY27 beat on both lines (EPS $1.36 vs ~$1.16–1.17; revenue $6.09B vs ~$5.97B), reported BMO 08-21. | `00280ce2…` |

**Ranked 8 carries a specific hazard worth naming at index depth**, because it changes what a thesis pass must confirm first rather than what it would conclude: **BBWI's own earnings print falls inside its entry window.** D1 records the 08-25 move as positioning *"ahead of BBWI's own print"*. That is a Sub-Pattern 5 in-window binary catalyst — the exact ground on which SNDK (2026-07-27) and AMD (2026-07-27) were both declined. Confirming BBWI's report date is the single highest-value fact outstanding on this shortlist.

**Ranked 9, 12, 13, 14 are ONE catalyst, not four candidates.** MU, SNDK, STX and WDC all moved on the same CXMT/Samsung memory-complex report on the same session. They are ranked separately because each is a distinct item under the four-part identity, but a future pass that took more than one of them would be sizing a single macro/policy bet four times. They are deliberately spread through the order rather than occupying ranks 6–9.

## BELOW THE CAP — two rankable items not in the 15

The cap is 15 (unchanged) and 17 eligible items survived exclusion. The two that fall out, with the ground:

- **BTDR** (+9.01%, qualifying event day **2026-08-20**, window closes 2026-09-02, **3 sessions left**). A carry-in from a session D1's own 08-20 screen missed and its 08-23 screen recovered. It has the shortest window in the entire intake, and on a router-gated cycle a 3-session window has no realistic path to an entry.
- **DNN** (+11.46%, 2026-08-21, window closes 2026-09-03, 4 sessions left). **Population-rail eligibility is not established.** D1 surfaced it on a real issuer event (a shift to full-scale construction at the Phoenix ISR uranium mine after approvals), but no market-cap figure against B's $2B floor exists in D1's record for it, and index mode does not spend a call to resolve one. Recorded as unresolved rather than asserted either way — the same discipline D1 applied to WEN.

## COHORT-WIDE STRUCTURAL FINDING — criterion 3 forecloses "next earnings release" for essentially the whole cohort, and this time it is deducible rather than looked up

B Entry criterion 3 requires convergence **within 60 days of entry** and admits only (a) a numerical price level or (b) one of exactly four named events. An entry on the next session (2026-08-31) puts the 60-day boundary at approximately **2026-10-30**.

**The deduction, which needs no earnings-date lookup and is therefore free of the estimate risk that qualified this finding on 2026-08-23:** eleven of the fifteen ranked names (DKS, CRM, OKTA, CRWD, VEEV, NVDA, AAOI, BJ, and — through their own recent prints — SNDK, STX, WDC) had their qualifying event **be their own quarterly report, delivered inside 2026-08-21…08-27**. A company that has just reported does not report again for roughly a quarter, which lands past **2026-10-30** in every case. The enumerated-event branch is therefore structurally unavailable for them, and it is unavailable *because* of the very fact that made them candidates.

**Consequence, binding on every thesis W4 ever hands to D2 from this file: each one needs a NUMERICAL PRICE TARGET.** And per the PRICE-LEVEL CRITERION DRAFTING RULE, any such level must be written as a `$`-prefixed two-decimal figure and must carry `price_level_ref_date` inside `invalidation_status` — the ISO date of the close it was read from. This is the **third consecutive cycle** to reach this conclusion (2026-08-09 and 2026-08-23 both did), and it recurs for a structural reason rather than a coincidental one: W2's intake is by construction dominated by names that just reported, so its candidates are systematically at the *far* end of their own reporting cycle. **That is a standing property of this screen, not a feature of late August**, and it is worth recording as such — the prior two cycles attributed it to "the late-August gap between reporting seasons," which is the weaker explanation and predicts the effect would fade in mid-season. It will not.

**Four names sit outside that deduction and are the only ones where an enumerated event could be live:**
- **MU** — its qualifying event was a policy report, not its own print, and Micron's fiscal Q4 ends in August with a report customarily in **late September**, i.e. *inside* both the 60-day boundary and (comfortably) past the entry window. This is the one name in the cohort where "next earnings release" may be a usable convergence target. **Estimated, not confirmed** — confirming it is the second-highest-value fact on this list.
- **BBWI** — its own print appears to fall *inside* the 10-session entry window, which makes it an SP5 hazard rather than a convergence target (above).
- **TSLA** — qualifying event was regulatory; next report ~late October, borderline against 2026-10-30. **Estimated.**
- **RDDT** — qualifying event was a third-party report; next report ~early November, likely just outside. **Estimated.**

No candidate has a dated FDA decision, and no index-inclusion event is in play for any of them.

## COHORT-WIDE STRUCTURAL FINDING #2 — the intake's composition has inverted, and it matters for B's own mechanism

The prior cycle's cohort was decliner-weighted and its residuals were unusually fat. **This one is the opposite: 10 of the 15 ranked names are UP-movers, and 8 of those 10 rose on their own earnings beat-and-raise.** B's mechanism is fading an over-sized reaction, and its router is long-biased *by construction* (`strategy/04_strategy_b.md`, Rev 36: the regimes where fading a pop would be safer — DOWN / HIGH-VIX — are exactly the ones the router excludes). So a cohort that is 2/3 up-movers is a cohort where B's *tradeable* half is the smaller one, regardless of the DNA. Combined with the calibration prior above — SP1 sell-side bull-ratification of an up-mover being one of the two dominant NO-GO families — **a full-depth pass on this week's cohort would most likely have produced a large number of NO-GOs on the up-movers and found its real candidates among the decliners (DKS, AAOI, BBWI, and the memory complex).** That is a testable claim and it is recorded here so a future divergence review can check it against what actually happened, rather than being reconstructed after the fact.

**The trajectory section above already gives it a partial grade, and the grade is mixed.** Of the four decliner candidates that prediction favours, **AAOI extended (108% intact) — consistent with a real under-reaction still building — while BBWI fully round-tripped inside three sessions (−3% intact), meaning its mispricing converged completely and unenterably fast**, and DKS has begun a bounce with 80% still open. Of the up-movers the prediction disfavours, BJ, RDDT and TSLA all round-tripped, which is what "the reaction was over-sized" looks like *after the fact* — so the up-mover half was not uniformly efficient either. **The honest reading is that this week's cohort was fast-converging on both sides**, which is a statement about the convergence horizon rather than about direction, and it is a cleaner signal for the divergence question than the direction claim is.

---

## FINDINGS FOR D1 / W5 — two, both upstream, neither fixed here

**(1) The 2026-08-26 session was never screened, and one full B window will expire without W2 ever seeing it. Owner: D1.** S4 surfaced zero attributable movers, not because the tape was quiet but because every price source it had was either plan-gated (FMP `quote`/`news`), quota-shaped (FMP `company`/`chart`) or silently stale (third-party quote pages serving Aug 18–24 caches with no staleness flag). D1 handled it exactly right — it named the ~12 unconfirmable large-caps and refused to report them as absent — but the downstream consequence lands here: **any name with a qualifying ≥5% event on 2026-08-26 is missing from this file, and its 10-session window (closing 2026-09-09) will expire ungraded.** W2 cannot repair this; covering it would be exactly the market-wide bar pull PART 1 forbids. The durable fix is upstream and is about D1's price-source redundancy on a day when FMP is gated — most likely the Tavily escape the "Metered external calls" rule part (a) explicitly endorses for this case ("spending a credit to keep evidence complete is efficient"), which S4's own coverage note does not record having tried. Recorded, not fixed.

**(2) S2's `surfaced_count` field disagrees with its own `passed[]` array — 25 versus 17. Owner: D1.** The 2026-08-24 screen's `fields.surfaced_count` reads **25** while the enumerated `passed[]` array holds **17** items. Every other screen in this window agrees exactly (S1 11/11, S5 17/17). This is a metadata defect, not an evidence one — W2 ranked off the enumerated array, which is the object that carries the per-item fields, so nothing in this file is wrong because of it. But `state.research_screen_calls` (`bigquery/96_research_screener.sql`) parses **both** the `surfaced_count` scalar and the per-item array, and W5's RESEARCH-SCREEN SCORECARD reads that view — so a screen whose stated count exceeds its enumerated items will overstate D1's surfacing rate in the scorecard by 8 items for that call. Worth one look at whether the 8 missing names were dropped from the array or the count was written from a pre-filter tally. Recorded, not fixed.

---

## HONEST LIMITS OF THIS RUN

- **This file contains no mispricing judgment about any candidate, and that is the mode working, not a shortfall.** INDEX MODE deliberately skips the mispricing direction/magnitude read, the retrieved-comparables step, the information-versus-sentiment analysis, and the convergence-indicator enumeration. A reader looking for "is DKS over-sold?" will not find an answer here and must not infer one from the rank — **rank is research priority, not conviction.** Nothing in PART 2 has been evaluated against B's entry criteria.
- **No comparable historical reactions were retrieved for any name.** Criterion 2 requires them *retrieved, not recalled*, and index mode does not perform that step at all. This is a deliberate omission, not a failed search — contrast the 2026-08-23 cycle, which searched for them and came up empty on 7 of 12 names anyway.
- **Four next-earnings positions in the criterion-3 finding are estimates** (MU, TSLA, RDDT, and BBWI's in-window print). The eleven-name deduction that they are the exception to is *not* an estimate — it follows from the qualifying event itself.
- **Two eligibility questions are left explicitly unresolved rather than guessed:** DNN's market cap against the $2B floor, and WEN's (~$1.6B implied, per D1's own non-assertion). Both would cost a metered call to settle and neither can change a disposition while B is DO-NOT-ACTIVATE.
- **The 2026-08-26 blind spot above is a real gap in this cohort's completeness**, and the 2026-08-28 session is uncovered by design. Neither is repaired here.
- **D1's own population figures are floors, not totals**, and this file inherits that ceiling: S5 states *"FLOOR NOT TOTAL — the true ≥2% population is materially larger, since ~115 US reporters spanned the two-day window against which FMP earnings-calendar returned only 2"*; S2 and S3 describe bounded sweeps of 79 and 21 measured names respectively. **This file's 28-item rankable set is therefore a floor on the week's qualifying B population, not the population.**
- **No `strategy/` or `strategy_math/` file was modified.** `strategy/04_strategy_b.md` and `01_shared_regime_vocabulary.md` were read for entry criteria and eligibility only, per W2's slice map. No other strategy slice was loaded.
- **No transient failures, no retries owed, no `RETRY` token.** BigQuery and IBKR were live throughout; no metered surface was touched at all.

## OPEN QUESTION CARRIED FORWARD FOR THE OWNER — the ADR line decided two more names, and this is now the third consecutive cycle it has been load-bearing

The instrument-eligibility rule in `strategy/04_strategy_b.md` says only **"US-listed common equity."** It excluded **BABA** (−8.57%, D1 conviction 75 — this week's *second-highest-conviction* rankable item) and **FUTU** (+9.68%) this run, on the same reconstruction-from-precedent that excluded BIDU, BNTX and ARGX and admitted ONON and KLAR in the two prior cycles. The workable tests remain the exchange's own security description, the presence of a separate home-market ordinary listing, and an F-6 registration naming a depositary bank; the **20-F form is not dispositive** and reading it as one gets the answer backwards.

**What is new this cycle is the cost.** BABA is not a marginal name — D1 scored it at 75 conviction on a cleanly-attributed FQ1-27 EPS miss, one of only five 75-conviction items in the entire intake. A rule that removes a top-quartile candidate every week, is written nowhere, and is re-derived by each session from precedent is a rule that will eventually be re-derived differently. **Pinning it is a `Strategy.md` change, and Strategy B's machinery is spec-locked and immutable, so this is an owner/SL-path decision and W2 may not make it.** It has now changed a disposition in three consecutive cycles.

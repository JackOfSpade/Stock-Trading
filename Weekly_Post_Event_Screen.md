2026-W34

# Weekly Post-Event Screen — Strategy B (W2)

**Run:** 2026-08-23 (Sun, ISO week **2026-W34**, per `state.trading_day_today.today`; `is_trading_day=false`, `last_trading_day=2026-08-21`, `next_trading_day=2026-08-24`). The last *completed* regular session is Friday **2026-08-21**, and every price figure in this file is a completed regular-session close. No live, intraday or after-hours print is load-bearing anywhere.

**⚠ THIS FILE CARRIES THE SAME MARKER AS THE PREVIOUS ONE — `2026-W34` — AND THAT IS CORRECT, NOT A FAILED OVERWRITE.** The prior W2 cycle ran Monday **2026-08-17** and stamped `2026-W34`; this cycle runs Sunday **2026-08-23**, which is the *last* day of the same ISO week. The file-write convention pins the weekly marker to the ISO week of **today's run date** (`scripts/check_cadence_marker.py:131`, `d.isocalendar()`), so both runs legitimately stamp W34. They are nonetheless **two distinct cycles**, because the cadence period W2 is actually scheduled on is `weekly_sun` — Sunday-anchored (`bigquery/114_period_aware_dependency_gate.sql`:123) — and the two runs fall in different Sunday-anchored periods: 08-17 sits in **[08-16, 08-22]**, today sits in **[08-23, 08-29]**. This is the exact Mon-vs-Sun anchor mismatch the Observability section's "WHY THE MARKER CANNOT BE THE PROOF ON ITS OWN" paragraph documents, seen from the W2 side rather than the W4 side. A downstream reader must not infer from the repeated marker that W2 skipped a cycle or re-wrote a stale file.

**Catch-up check — no widening owed.** `state.routine_catchup_window`: `routine='W2'`, `monitor_class='weekly_sun'`, `last_completed_ts=2026-08-17T10:55:23Z`, `never_completed=false`, `window_days=5.88`. Against a 7-day normal weekly look-back that is **0.84x**, well under the 1.5x bar, so **no `CATCHUP` token is owed**. The intake watermark used below is that same `2026-08-17T10:55:23Z` timestamp.

**Same-day double-run guard: PASSED.** `ops.run_log` shows **0** `completed` W2 rows and **0** `started` rows for `run_date=2026-08-23`, so this is not a redundant re-invocation.

---

## SCOPE OF THIS RUN — WHAT W2 DOES AND DOES NOT DO

W2 performs **zero market-wide discovery**. It does not pull broad price bars, enumerate movers, repeat an event search, or re-judge §19 significance. Its intake is the durable D1 record since W2's own last successful completion. This run therefore spawned **no discovery sub-agent** and made **no metered population pull** — the FMP earnings/dividend/IPO calendars were not queried at all, and the shared-population-pull steps in W2's own prompt body are, per the reconciliation note added 2026-08-17, dormant for W2 and binding only on routines that genuinely do fan out for discovery.

**Fan-out that DID happen, and why it is not discovery.** Seven Sonnet-5 sub-agents ran *one named candidate each* (or a pair), doing B-specific enrichment — filings, transcripts, collaboration terms, eligibility adjudication, comparable retrieval — plus one further sub-agent that did nothing but pull IBKR daily bars for the 12 ranked names. Each agent carried an explicit call budget and an explicit instruction on what to do on exhaustion. This is the "different slice per sub-agent" case the shared **"One shared pull, not N independent ones"** rule expressly permits; it is not the 2026-08-17 failure mode, where 15 agents each independently rebuilt the same Layer-1 population.

**MEASURED EXTERNAL SPEND THIS RUN: 68 calls, all on the FREE Anthropic `web_search`/`web_fetch` surface. Zero Tavily credits. Zero FMP requests. Zero HF requests.** The free surface proved adequate for every question asked, so no escape to a metered surface was needed; the ordering rule ("ask the free surface first, escape the moment it is inadequate") was followed and never triggered an escape. FMP was affirmatively *excluded* from every sub-agent brief, both because its free tier has now silently dropped symbols from batch calls on three consecutive D1 sessions and because its 250/day cap is account-wide and shared with the rest of the fleet.

---

## WINDOW ARITHMETIC

B's frozen entry window is **10 trading sessions counting the event day as day 1** (Entry criterion 1, `strategy/04_strategy_b.md`). Trading sessions confirmed against `state.market_calendar`: 08-17, 08-18, 08-19, 08-20, 08-21, 08-24, 08-25, 08-26, 08-27, 08-28, 08-31, 09-01, 09-02. The next session is **Monday 2026-08-24**.

| Qualifying event day | Window closes (day 10) | Sessions left from 2026-08-24 |
|---|---|---|
| 2026-08-17 | 2026-08-28 | **5** |
| 2026-08-18 | 2026-08-31 | **6** |
| 2026-08-19 | 2026-09-01 | **7** |
| 2026-08-20 | 2026-09-02 | **8** |

**Carry-forward from the prior cycle is OUT OF THIS RUN'S INTAKE and was deliberately not re-enriched.** The 2026-08-17 file ranked 15 candidates on event days 8/6–8/14; per that run's own record its top-5 (CSCO, BLLN, TPR, YETI, ACM) sat on the 8/12–8/14 cohort, whose windows close 8/25–8/27, leaving **2–4 sessions** from 8/24. Those items originate in D1 rows *before* this run's watermark, so PART 1 does not readmit them, and none was ever enqueued for thesis construction (B has been DO-NOT-ACTIVATE throughout). They are named here for W4's benefit and for nothing else; no bar was pulled for any of them.

---

# PART 1 — D1-ORIGINATED POST-EVENT INTAKE (no market-wide re-screen)

## Intake source

Four operative D1 `entry_type='research-screen'`, `screen='single-name-move'` rows landed inside the watermark window. Three further rows are superseded and were correctly excluded (a correction row names the row it replaces, so the *named* row is the obsolete one):

| D1 decision id | Event date | Status | Surfaced |
|---|---|---|---|
| `18a92005-c9a4-4dd8-82e3-50c8321d3f3b` | 2026-08-17 | operative (correction; supersedes `d3e115ae…`) | 19 |
| `9394d515-766e-4019-bf47-033411833690` | 2026-08-18 | operative | 46 |
| `125445a7-9f8e-4052-8226-b29b5f4b2efa` | 2026-08-19 | operative | 55 |
| `64ea0fce-333a-4b7e-8e65-0555bd758f4f` | 2026-08-20 | operative (correction; supersedes `bc9a1f62…`) | 15 |

**The 2026-08-21 (Friday) session is NOT covered here, by design.** D1 runs Sun–Thu; its last completed run is 2026-08-20 and its Sunday scan for 2026-08-23 had not fired at this run's start (`ops.run_log`: zero D1 rows for 2026-08-23). W2's own prompt body assigns the Friday/Saturday gap to that Sunday scan and forbids W2 from covering it early with its own bar pulls. Any qualifying 8/21 event will therefore enter through **next** week's W2, with a window that is by then 1 session shorter.

## Four-part identity dedupe — CLEAN

Checked `events.queue_events` (open **and** terminal) and `events.decision_log` for `analysis_type='thesis-construction'` + `strategy='B'` + ticker + `qualifying_event_date`. **No identity for any candidate below exists in either surface.** The most recent Strategy-B thesis-construction records anywhere are dated **2026-08-05** (CVS, DVA) and the most recent B queue enqueues **2026-08-03** (VRT, LII, CARR, AAPL, GDDY). No ticker-only deduplication was used; a later distinct event on a name already seen remains eligible.

**⚠ PROCESS DEFECT FOUND WHILE PERFORMING THAT DEDUPE — recorded, not fixed here; owner is W4.** W2's own prompt body and D1's screens both construct the dedupe identity as `thesis-B-<ticker>-<YYYY-MM-DD>` (D1's 2026-08-20 `b_routing` field literally enumerates `thesis-B-WMT-2026-08-20`, `thesis-B-AAP-2026-08-20`, …). **Every live row actually written to `events.queue_events` uses the opposite construction — `thesis-<TICKER>-B-<YYYYMMDD>`** (`thesis-CARR-B-20260803`, `thesis-ISRG-B-20260719`, `thesis-MSCI-B-20260726`, …). A session that performs the documented check as a literal string match would find nothing, *always*, and would conclude "no prior identity" even for an item already enqueued — a false-negative dedupe that would duplicate a thesis and, downstream, a position. This run avoided it by matching on `(strategy, ticker, event date)` rather than on the key string, which is why the CLEAN verdict above is trustworthy. **It is not biting today** — B is DO-NOT-ACTIVATE and nothing has been enqueued since 2026-08-03 — which is exactly why it is worth fixing before it can. W4 owns the enqueue-key format; the W2/D1 slice text owns the specification. Not fixed in this run because changing an enqueue key format is a W4 change with downstream D2 consumers, not a W2 one.

## Items preserved from D1 (ticker · qualifying event date · event type/source · move · D1 verdict · flags · origin id)

Every field below is **carried forward from D1 verbatim**. The move was not recomputed and the significance verdict was not revisited.

| # | Ticker | Qualifying event date | Event type / source | Close-to-close move | D1 verdict | `legacy_rule_pass` | `below_spec_floor` | Origin D1 id |
|---|---|---|---|---|---|---|---|---|
| 1 | **WMT** | 2026-08-20 | Q2 FY27 earnings, 06:00 CT, primary-source confirmed | **−9.15%** | passed, HIGH 75 | true | false | `64ea0fce…` |
| 2 | **AAP** | 2026-08-20 | Q2 2026 earnings, pre-market, Business Wire | **−24.55%** | passed, MEDIUM 60 | true | false | `64ea0fce…` |
| 3 | **DE** | 2026-08-20 | Q3 FY2026 earnings | **+6.94%** | passed, MEDIUM 60 | true | false | `64ea0fce…` |
| 4 | **MRVL** | 2026-08-19 | 8-K, Google warrant 58,970,907 sh @ $206.58; confirmed on SEC EDGAR | **+9.85%** | passed, 60 | true | false | `64ea0fce…` |
| 5 | **NDSN** | 2026-08-19 | Record Q3 FY2026, released after the close; confirmed vs IR + 8-K | **+8.00%** | passed, MEDIUM 60 | true | false | `64ea0fce…` |
| 6 | **MRNA** | 2026-08-19 | Phase 3 INTerpath-001 readout (mRNA cancer therapy) | **+177.03%** | passed, HIGH 75 | true | false | `125445a7…` |
| 7 | **MRK** | 2026-08-19 | Same INTerpath-001 readout (50/50 partner) | **+12.60%** | passed, HIGH 75 | true | false | `125445a7…` |
| 8 | **EL** | 2026-08-19 | FY2026 Q4 earnings beat, dated and resolved | **+16.30%** | passed, MEDIUM 60 | true | false | `125445a7…` |
| 9 | **CVNA** | 2026-08-19 | Hunterbrook report off newly obtained Delaware filings | **+8.37%** | passed, MEDIUM 60 | true | false | `125445a7…` |
| 10 | **FN** | 2026-08-18 | Q4 FY2026 earnings + Sept-quarter guide + $56.7M securities loss | **−19.38%** | passed, HIGH 75 | true | false | `9394d515…` |
| 11 | **KLAR** | 2026-08-18 | FY26 GMV/revenue guidance cut | **−22.81%** | passed, MEDIUM 60 | true | false | `9394d515…` |
| 12 | **AMLX** | 2026-08-18 | Phase 3 LUCIDITY topline | **+63.83%** | passed, MEDIUM 45 | true | false | `9394d515…` |

### Identities EXCLUDED before enrichment, with the ground

| Ticker | D1 event date | D1 move | Ground for exclusion |
|---|---|---|---|
| **WOLF** | 2026-08-19 | −9.42% | **Population rail — market cap $1.37B, below B's $2B floor.** See the finding below; D1 ranked it #2 with the cap explicitly unverified. |
| **ARGX** | 2026-08-17 | +16.04% | **Instrument eligibility — Nasdaq ARGX is an American Depositary Share.** Ordinary shares trade on Euronext Brussels. Same structure as the excluded JD / AZN / NVO; distinct from the admitted ONON. |
| **CBRS** | 2026-08-17 | +15.07% | **Event identity — all three cited legs are misdated.** See the finding below. No qualifying public event occurred on 2026-08-17. |
| **BIDU** | 2026-08-18 | −12.73% | Instrument eligibility — Cayman/Beijing ADR, excluded on the same basis as JD. |
| **BNTX** | 2026-08-19 | +21.96% | ADR, *and* no BNTX-specific event (D1: mechanistic read-across only). |
| **UGI** | 2026-08-18 | +9.41% | Mechanism — unsolicited KKR takeover bid; bid-anchored, not a B mechanism (MGM 2026-06-01 precedent). |
| **CRWD** | 2026-08-19 | −5.30% | Analyst action only (Cantor PT cut, rating maintained). Opinion is not a qualifying event; SP6 family. |
| **IOVA** | 2026-08-20 | +12.52% | Driver is a 2026-08-20 sell-side PT cluster, not an earnings event; opinion, not substance. |
| **STLD** | 2026-08-19 | −7.53% | D1 declined it itself: the tariff report is **reported but not resolved**; B requires a resolved event. |
| **ISRG** | 2026-08-20 | −5.84% | No qualifying public event exists (D1's own finding). Held D position; D-trigger material, not B. |
| Theme legs on 08-17/08-18 (SNDK, AMAT, NOW, WDC, COHR, CRDO, TER, ONTO, VIAV, SITM, AEIS, VICR, LITE, BE, CIEN, MU, VRT, APH, NRG, KLAC, ETN, FTAI, TLN, GEV, DELL, TEM, TWST, CRM) | various | various | No own qualifying public event — sympathy/theme participation. D1 attributes each to the complex, not to a company disclosure. |

Also excluded and worth naming: **expired windows** — none. Every item in the intake has ≥5 sessions of window left. **Open Strategy A positions** — none exist (`state.current_positions` holds 13 open positions, all Strategy D: GEV, AMZN ×2, ISRG, TSM ×2, DIS ×2, GOOGL ×2, UBER, RTX, CRM). **Entry criterion 5 (no A position in the same name) therefore binds nothing this cycle**, and the Watchlist A-queue is a queue, not a position, so it does not gate anything here either.

---

## PRICE-BASIS RECONCILIATION — ZERO CORRECTIONS OWED

An independent IBKR pull (`get_price_history`, `step=ONE_DAY`, `outside_rth=false`, bars identified by their own date fields, issued in batches of 4 rather than one wide parallel batch) reproduces **every** D1-recorded magnitude in the intake table:

| Ticker | Pre-event close | Event-day close | Recomputed | D1 recorded | Δ |
|---|---|---|---|---|---|
| WMT | 114.30 (08-19) | 103.84 (08-20) | −9.15% | −9.15% | 0.00pp |
| AAP | 56.18 (08-19) | 42.39 (08-20) | −24.55% | −24.55% | 0.00pp |
| DE | 580.63 (08-19) | 620.94 (08-20) | +6.94% | +6.94% | 0.00pp |
| MRVL | 216.00 (08-18) | 237.27 (08-19) | +9.85% | +9.85% | 0.00pp |
| NDSN | 309.92 (08-19) | 334.70 (08-20) | +8.00% | +8.00% | 0.00pp |
| MRNA | 62.96 (08-18) | 174.38 (08-19) | +176.97% | +177.03% | 0.06pp |
| MRK | 135.17 (08-18) | 152.20 (08-19) | +12.60% | +12.60% | 0.00pp |
| EL | 84.27 (08-18) | 98.01 (08-19) | +16.31% | +16.30% | 0.01pp |
| CVNA | 65.00 (08-18) | 70.44 (08-19) | +8.37% | +8.37% | 0.00pp |
| FN | 598.58 (08-17) | 482.59 (08-18) | −19.38% | −19.38% | 0.00pp |
| KLAR | 19.51 (08-17) | 15.06 (08-18) | −22.81% | −22.81% | 0.00pp |
| CBRS | 218.98 (08-14) | 251.98 (08-17) | +15.07% | +15.07% | 0.00pp |

This is the **second consecutive cycle owing no price-basis correction**, against a lineage (COIN / GLW / UPS / CCJ / INSP) in which week-late magnitude fixes were routine. The reconciliation is a *by-product* of the trajectory pull below, not a re-screen: no move was re-judged and no significance verdict was revisited. AMLX was not in this pull (it entered the rankable set only after its eligibility resolved), so its +63.83% stands on D1's measurement alone.

## POST-EVENT TRAJECTORY — the residual-thinness test

How much of the event-day gap is still open, measured to the last completed session (2026-08-21):

| Ticker | Event-day close | 2026-08-21 close | Move since event day | Gap still intact | Shape |
|---|---|---|---|---|---|
| **AAP** | 42.39 | 42.58 | +0.45% | **~98.6%** | flat; no bounce |
| **WMT** | 103.84 | 103.70 | −0.13% | **100%** | extended slightly |
| **FN** | 482.59 | 436.67 | **−9.51%** | **>100%** | extended 3 sessions running |
| **KLAR** | 15.06 | 14.33 | **−4.85%** | **>100%** | extended, stabilising 08-21 (+2.36%) |
| **MRVL** | 237.27 | 237.04 | −0.10% | **~99%** | day-2 continuation (+5.79%) fully round-tripped; event gap defended |
| **NDSN** | 334.70 | 332.24 | −0.73% | ~90% | mild give-back |
| **CVNA** | 70.44 | 69.91 | −0.75% | ~90% | mild give-back |
| **MRNA** | 174.38 | 145.13 | −16.77% | ~73% | −23.55% then +8.86%; volatile, majority intact |
| **MRK** | 152.20 | 152.55 | +0.23% | **>100%** | held and extended to a new high |
| **EL** | 98.01 | 101.94 | **+4.01%** | **>100%** | held and extended to a new high |
| **DE** | 620.94 | 647.47 | **+4.27%** | **>100%** | held and extended |
| **CBRS** | 251.98 | 196.13 | **−22.16%** | **fully reversed, and then some** | round-tripped below the pre-event close |

Read against this framework's own precedent: a gap that has already closed kills the edge (VRT was declined at 86–99% retraced, DHR at 79%), so **nothing in this cohort is disqualified for thinness** — the residuals are unusually fat. But the converse cuts the other way and is the more important reading this week: **"held and extended" is the efficient-repricing signature, not the under-reaction signature** (the VZ 2026-07-27 NO-GO turned on exactly this). MRK, EL, DE and — in the negative direction — FN and KLAR are all extending in the direction of their event, which argues the market is still absorbing information rather than correcting an overshoot.

---

## FINDINGS FOR D1 / W5 — three, all upstream, none fixed here

**(1) WOLF was ranked #2 among D1's own B candidates on an unverified market cap, and it fails the floor.** D1's 2026-08-20 screen recorded WOLF at `mechanism_rank: 2` — "genuine divergence, distressed underlying" — while stating in the same row that "Market cap NOT verifiable this run" and, in `fmp_defect`, that AAP and WOLF "remain the genuinely borderline pair whose population-rail eligibility is ASSERTED ON JUDGMENT, not measured." **Measured this run: $1.37B at $25.76/share (stockanalysis.com, dated 2026-08-21), corroborated by two further aggregators in a $1.43–1.65B band. Every figure is materially below B's $2B floor; none is near it.** The judgment call went the wrong way. The paired name resolves the other way: **AAP is $2.57B (dated 2026-08-21) and clears**, though not by much. This is a population-rail correction, not a significance one — D1's read of the WOLF *event* (a beat that fell 9.42%) may well have been right, and the name is simply outside B's universe. **Owner: D1's population rail.** The mechanism is not D1's judgment but FMP's free tier, which returned 3 rows for an 18-symbol batch with HTTP 200 and no marker for the 15 it dropped, for the third consecutive session.

**(2) The EVENT-IDENTITY GATE missed a third instance in the same screen that documented its own base rate — and CBRS is it.** D1's 2026-08-17 screen ran an explicit event-identity gate, caught two names (AMAT, NOW), and recorded a candid base rate: "2 of ~13 individually-attributed names (~15%) carried a real, well-sourced event attached to the WRONG DATE." **CBRS is a third, uncaught, in the same screen.** All three legs D1 cited as "all dated 2026-08-17" are misdated: the Morgan Stanley Overweight reiteration is dated **2026-08-13** (and is opinion, so it would not qualify on any date); the OpenAI hardware relationship is the **April 2026** $20B/750MW compute deal, stale by ~4 months; and the Tiger Global stake is a **Schedule 13G filed 2026-08-14** disclosing a position built in Q2 — a passive filing on the standard lag, not news. The actual proximate driver on 8/17 was a *Wedbush* note re-reading the April deal through a new model SKU: analyst interpretation of old substance. **The price agrees with the finding rather than with the attribution** — CBRS gave the entire +15.07% back within one session and closed 2026-08-21 at 196.13, **10.4% below its pre-event close**, the only full round-trip in the cohort. Worth noting for the gate's design: the two catches D1 *did* make were both flagged by an internally inconsistent quoted number (a $775 target on a $117.70 stock). CBRS offered no such arithmetic tell — three separately-sourced items simply share a date — so the tell that works is not available for this shape, and date-verification against the originating source is the only defence. **Owner: D1.**

**(3) AMLX's readout was characterised in a way that would mislead a downstream reader.** D1's 2026-08-18 screen recorded AMLX (+63.83%) as "positive Phase 3 LUCIDITY topline — a real resolved binary event, but a biotech readout sits outside every currently active strategy mechanism." Two corrections. First, LUCIDITY is **avexitide in post-bariatric hypoglycemia**, not an ALS trial — Amylyx's ALS asset was discontinued in 2024 and this is a separate GLP-1-receptor-antagonist programme; the trial is N=78, the FDA-agreed primary endpoint (composite rate of Level 2/3 hypoglycaemic events) was met with a 55% reduction at **p=0.000003**. Second, and more consequential for routing: **a resolved binary readout is squarely inside B's mechanism** — B's Entry criterion 1 names "FDA decision" among its qualifying event types, and this framework has constructed B theses on exactly this shape before (IONS 2026-07-12, BBIO 2026-07-12). The name belongs in B's intake, which is where this run has put it. **Owner: D1's routing language.** A separate, live fact that any thesis pass must carry: Amylyx priced an **upsized $350M secondary at $35.50 on 2026-08-19**, 14.09M shares, *inside* the entry window — a dilution/supply event of the kind the BBIO NO-GO (SP4e) turned on.

---

# PART 2 — RANKED SHORTLIST

**⚠ ROUTING STATUS — READ BEFORE CONVERTING ANYTHING. This PART 2 is a RESEARCH PRIORITY LIST, not a staging list.**

- **Strategy B is `DO-NOT-ACTIVATE`.** `events.regime_events`, scope `STRATEGY_ACTIVATION`, key `B`, divergence `div-B-202607-1`, resolved 2026-08-05, theater-check DIVERGENT. The DNA is produced entirely by the **universal `shock_overlay=acute` reconciliation override**, not by B's own legs. It blocks **new B entries only**; existing B positions run to their own mechanical exits.
- **B's own router legs pass independently.** As of 2026-08-20: `SPY_TREND = UP` (762.60 > 50d 750.94 > 200d 707.13) and `VIX_REGIME = NORMAL` (16.01). B's activation rule is `SPY Trend ≠ DOWN AND VIX ≠ HIGH`, so both legs hold. Note the VIX flip: 2026-08-19 read LOW (14.89), 2026-08-20 NORMAL (16.01). Still comfortably inside B's admissible band.
- **B has no capital.** `analytics.strategy_nav`: strategy B `deployed_mv = 0`, `nav = 0`, `available_funds = 0`, `deposits = −18.22`. Even were the DNA lifted tomorrow, there is nothing to size against.

**W4 must not enqueue these as staged entries while the DNA stands.** The prior two cycles reached the same conclusion and the prior cycle's 15 candidates were correspondingly never enqueued; expect the same disposition here.

## COHORT-WIDE STRUCTURAL FINDING — criterion 3 forecloses "next earnings release" for 11 of 12

B Entry criterion 3 requires convergence **within 60 days of entry**, and admits only (a) a numerical price level or (b) one of exactly four named events. An entry on the next session (2026-08-24) puts the 60-day boundary at approximately **2026-10-23**. Checked per name, the next earnings release falls **outside** that boundary for every candidate except MRVL — WMT ~19 Nov, AAP ~mid-Nov, DE ~late Nov, NDSN ~early Dec, FN ~mid-late Nov, KLAR ~mid-Nov, MRNA ~early Nov, EL ~early Nov, CVNA **29 Oct (~67 days)**, MRK ~late Oct (borderline, unconfirmed), AMLX ~early Nov. No candidate has a dated FDA decision (neither MRNA nor AMLX has filed; there is no PDUFA date to name), and no index-inclusion event is in play.

**Consequence, binding on every thesis W4 hands to D2: each one needs a NUMERICAL PRICE TARGET.** The enumerated-event branch is unavailable across the cohort. This is the same finding the 2026-08-09 cycle reached by the same arithmetic, and it recurs because the screen window sits in the late-August gap between reporting seasons.

**MRVL is the exception and its exception is adverse.** Its Q2 FY2027 call is estimated at **~2026-08-27/28** — three or four sessions away, i.e. *inside* the 10-session entry window. That is not a usable convergence target; it is a **Sub-Pattern 5 in-window binary catalyst**, the precise ground on which SNDK (2026-07-27, "Aug-5 print inside window") and AMD (2026-07-27, "an Aug-4 print inside the window") were both declined. The date is estimated, not confirmed, and confirming it is the single highest-value fact for any MRVL pass.

## Calibration prior for the reader

`events.decision_log` Strategy-B thesis-construction rows since 2026-06-01: **3 GO** (FTV 2026-07-29, MSCI 2026-07-27, MTZ 2026-08-03 — the last staged but halted on `trading_enabled=FALSE`) against ~57 NO-GO. The dominant NO-GO grounds are **criterion 4, information-driven** (SP4a/SP4c families, PatternN cross-sectional confirmation) and **SP1 sell-side bull-ratification** of an up-mover. Nine of the twelve candidates below sit in one of those two families. That is not a reason to decline them in advance — the "NO-GO records are context, not barriers" rule applies, and a documented sub-pattern raises the bar rather than auto-rejecting — but it is the base rate a thesis pass should be honest about.

---

## TOP-5

### 1. KLAR — Klarna Group plc · qualifying event 2026-08-18 · **−22.81%** · 6 sessions left · D1 origin `9394d515…`

- **(a) Hypothesised mispricing — OVER-SOLD, tentatively ~10–15 points of the move.** This is the only candidate in the cohort where the magnitude asymmetry is quantified rather than asserted.
- **(b) Supporting public information.** The quarter itself **beat**: revenue $1.04B, +27% YoY, ahead of consensus, and EPS +$0.01 against −$0.05 expected. The guidance cut that drove the move is mid-single-digit at the midpoint — GMV to $149–151B from "over $155B" (≈3.2% off the prior floor), revenue to $4.08–4.16B from "above $4.34B" (≈5.1% at the midpoint). **Management attributed ~$600M of the GMV reduction to FX translation** — roughly half the total cut — with the remainder "a more measured view of primarily German volumes." A −22.81% reaction against a ~3–5% guide trim, half of it currency, on a beating quarter, is a large asymmetry by any reading.
- **(c) Information vs sentiment — leans SENTIMENT, with one real complication.** A guidance cut is information by construction, so the mispricing claim has to be about magnitude, and on magnitude the case is genuinely strong. The complication is that **CFO and CMO departures were announced in the same session** — a second, independent information event that legitimises part of the excess reaction and cannot be cleanly separated from the guidance arithmetic with what is on file. Whether those departures are planned succession or for cause is the fact that decides this name.
- **(d) Comparables — NOT RETRIEVED.** A targeted search for a recently-IPO'd fintech cutting first-year guidance returned Fiserv, FinVolution and nCino, none of which matches (legacy issuers, or a ~5.8% move). Reported as a gap rather than filled with a recalled analogue. **This is the single largest evidentiary hole in the top-ranked name.**
- **(e) Convergence indicators.** German retail-sales monthly prints; EUR/USD stabilisation (isolates the FX-attributed $600M); the Q3 print against the new $149–151B / $4.08–4.16B guide; CFO/CMO successor announcements and stated reasons; peer BNPL reads (Affirm, PayPal Pay-in-4) to separate sector from company.
- **(f) Convergence target.** Numerical price level required — Q3 lands ~mid-November, outside 60 days.
- **(g) Eligibility — RESOLVED IN ITS FAVOUR THIS RUN.** **KLAR is ordinary shares directly listed on the NYSE, not an ADR/ADS.** Klarna Group plc IPO'd 2025-09-10 at $40.00, selling 34,311,274 **ordinary** shares; two classes (ordinary 1 vote, Class B 10 votes); it files 20-F as a foreign private issuer, but the *listed security* is ordinary equity. That places it with the admitted ONON and apart from the excluded JD/AZN/NVO. Market cap comfortably above $2B (sources conflict on the exact figure and none is cited as reliable). 30-day dollar volume clears $10M on any plausible arithmetic, though no single internally-consistent dated source was obtained.
- **(h) Confidence: MODERATE (~50–55%).** The asymmetry is clean; the missing base rate and the unresolved CFO/CMO question are what cap it.

### 2. WMT — Walmart · qualifying event 2026-08-20 · **−9.15%** · 8 sessions left · D1 origin `64ea0fce…`

- **(a) Hypothesised mispricing — NONE FOUND.** Ranked second on *quality of the setup for a thesis pass*, not on expected outcome.
- **(b) Supporting public information.** A genuine beat-and-raise: adj EPS $0.81 vs $0.74, revenue $187.9B vs $186.6–186.7B, FY guidance raised to +4.0–5.0% cc sales and +7.0–8.5% cc adj operating income. What moved the stock is forward: **US comps +2.6% against ~3.7–3.8% consensus and +4.6% a year ago** (slowest in 6+ years, including an 80bp health-and-wellness headwind), and a **Q3 guide of adj EPS $0.62–0.64 against $0.68 consensus** — a miss. CFO Rainey disclosed the quarter's margin was boosted by a **$2.9B tariff refund**, a one-time item, so reported earnings quality is weaker than the headline.
- **(c) Information vs sentiment — INFORMATION-DRIVEN, high confidence.** Three independent forward-looking negatives (comp deceleration below consensus in the core business, a below-consensus Q3 profit guide, and a headline partly manufactured by a non-recurring refund) is a coherent bundle, not an overreaction to a single scary line. **The precedent is unanimous against this shape**: CARR (2026-08-03) was a beat-and-raise sold off on a CFO-guided Q3 margin step-down — NO-GO, SP4a; CVS (2026-08-05) was a genuine beat-and-raise sold off on information management itself supplied — NO-GO. WMT is the same family.
- **(d) Comparables — NOT RETRIEVED as *prior* dated instances.** The only analogue obtained is contemporaneous: **Target**, reporting the same week, beat with EPS $4.11 of which ~$1.65 (≈40%) came from the same tariff-refund dynamic, and guided ex-refund ($8.25–9.25) well below headline ($9.90–10.90). That establishes the refund-inflation is sector-wide this quarter, but at three days old it carries no forward path.
- **(e) Convergence indicators.** Target / Costco / Home Depot subsequent comps (is deceleration sector-wide or WMT-specific); consumer-spending and gas-price data; how the 10-Q characterises the refund; the actual Q3 print against the +3.0–3.75% / $0.62–0.64 guide; FY28 estimate-revision trend.
- **(f) Convergence target.** Numerical price level required — Q3 ~19 Nov is outside 60 days.
- **(g) Eligibility.** Passes trivially on all three tests.
- **(h) Confidence: HIGH on the information-driven read.** It would move if the comp deceleration proved a mechanical, reversible pharmacy-reimbursement artefact rather than demand.

### 3. AAP — Advance Auto Parts · qualifying event 2026-08-20 · **−24.55%** · 8 sessions left · D1 origin `64ea0fce…`

- **(a) Hypothesised mispricing — NONE FOUND; arguably the market is being generous.** The largest magnitude in the cohort and the fattest residual (~98.6% intact), which is why it ranks third despite an adverse read.
- **(b) Supporting public information.** Adj EPS $1.03 vs $0.81 consensus **contains $26M of tariff refunds worth ~$0.31**, disclosed and sized by management. Strip it and adj EPS is ≈**$0.72, an ~11% MISS**. Revenue $2.0B missed ~$2.04B; comps **−0.5%** with DIY deceleration worst in the final four weeks (management's own words); FY26 sales guidance reaffirmed at $8.485–8.575B against ~$8.58B consensus; store openings cut to 30–35 from 40–45. One datapoint cuts the other way — FY26 adj EPS guidance was *raised* to $2.60–3.30 from $2.40–3.10 — but management tied that to the refund and to reduced capex ambition, not to unit economics.
- **(c) Information vs sentiment — INFORMATION-DRIVEN.** A beat that exists only because of a named non-recurring item, sitting on a revenue miss, negative comps, a below-consensus reaffirm and a trimmed store plan, is the textbook criterion-4 failure. The open question a thesis pass should actually test is narrower and quantitative: **is −24.55% proportionate to an ~11% ex-refund EPS miss?** That is not answered here.
- **(d) Comparables — NOT RETRIEVED.** Searches returned only contemporaneous 2026 names. Named as an open gap.
- **(e) Convergence indicators.** October/November DIY commentary; AutoZone and O'Reilly prints (category demand vs AAP execution); the 10-Q's treatment of the $26M refund; ex-refund consensus revisions; pace against the revised 30–35 store plan; short-interest change.
- **(f) Convergence target.** Numerical price level required — Q3 ~mid-Nov is outside 60 days.
- **(g) Eligibility — resolved, and it is the thin one.** **$2.57B (stockanalysis.com, dated 2026-08-21)** clears the $2B floor but not by much; undated aggregator figures ranged $2.56–3.68B and were not relied on. A second dated confirmation is worth having before any entry, and the floor is tested at entry, not at screen time.
- **(h) Confidence: HIGH (~70–75%) on the information-driven read.**

### 4. FN — Fabrinet · qualifying event 2026-08-18 · **−19.38%** · 6 sessions left · D1 origin `9394d515…`

- **(a) Hypothesised mispricing — tentatively over-sold by ~5–10 points, LOW confidence and explicitly not established.**
- **(b) Supporting public information.** Q4 FY2026 (quarter ended 2026-06-26) was a **record**: revenue $1.316B, +45% YoY, above guidance; non-GAAP EPS $4.10, above guidance. The Q1 FY2027 guide is **$1.375–1.425B revenue and $4.10–4.25 non-GAAP EPS** — a midpoint ~**+6.4% sequentially above** the record just delivered, i.e. **not an absolute cut**. The "deceleration" therefore rests on a YoY growth-rate slowdown from +45%, and **the year-ago comparable and the consensus revenue figure could not be sourced** — which means the central claim is unverified. Separately, the $56.7M securities loss is ~**0.18% of the pre-event market cap** and cannot mechanically account for a meaningful share of a 19.38% move; it is a non-operating distraction, not the driver.
- **(c) Information vs sentiment — LEANS INFORMATION-DRIVEN, and the trajectory reinforces it.** FN fell a further **−9.51% across the three sessions after the event day** with no bounce, and the whole optics complex de-rated with it (COHR −12.75%, LITE −9.87%, CIEN −8.91% on 08-18, all without events of their own). **Cross-sectional confirmation of a negative-direction move is the literal PatternN signature**, on which this framework's record is unbroken — GLW, AMKR, SANM, TSLA, RDDT, ACN, GIL all NO-GO. Three dated same-shape precedents in the four weeks before FN's own print point the same way: **GLW 2026-07-28** (beat, guided below, −12%, led an optical rout), **COHR ~2026-08-12/13** (clean beat, fell anyway; sources disagree on magnitude, ~4.94% vs ~12%), and **AAOI** (record revenue, EPS beat, still fell ~3.62%). None has a retrieved 2–8-week forward path.
- **(d)–(e) Convergence indicators.** Whether COHR/LITE/CIEN mean-revert *together* over 2–4 weeks (a flow signature) or stay down (a genuine demand reassessment); sell-side re-underwriting of FY27 hyperscaler-capex optics content; FN's own September-quarter print against the $1.375–1.425B guide.
- **(f) Convergence target.** Numerical price level required — Q1 FY27 ~mid-late Nov. *(A search returning "Aug 24, 2026" as FN's next earnings date is internally inconsistent with its 8/17–8/18 print and was discarded as a stale scrape.)*
- **(g) Eligibility.** NYSE-listed **ordinary shares** of a Cayman-incorporated issuer, directly listed since 2010-06-25 — not an ADR, so the ONON carve-out applies. Market cap ~$25.87B. ADV clears $10M by an order of magnitude.
- **(h) Confidence: LOW-MODERATE.** The one fact that would settle it — the September-quarter guide against consensus, not against the delivered quarter — is exactly the fact that could not be sourced. **That is why it ranks fourth rather than being declined outright.**

### 5. MRVL — Marvell Technology · qualifying event 2026-08-19 · **+9.85%** · 7 sessions left · D1 origin `64ea0fce…`

- **(a) Hypothesised mispricing — OVER-BOUGHT by at most ~3–6 points of the ~+16.2% two-day cumulative. The arithmetic gap is the widest in the cohort; the tradeable expression is the problem.**
- **(b) Supporting public information, read off the 8-K itself** (filed 2026-08-19, accession 0001193125-26-356217). Warrant for up to **58,970,907 shares at $206.58**, against a commercial agreement signed 2026-07-29. **Vesting is almost entirely contingent:** only **1,360,867 shares (~2.3% of the warrant, ~0.16% of shares outstanding)** vest unconditionally, in equal quarterly instalments over year one. The remaining ~57.6M vest in **240 tranches of $500M each**, tied to discretionary Google purchases from Q3 FY2027 through FY2033 — **full vesting requires $120B of cumulative purchases** against a company that does ~$8–9B of total annual revenue. **No minimum purchase commitment.** Full-exercise dilution ≈6.7%; near-certain dilution ≈0.16%.
- **(c) Information vs sentiment — MAJORITY INFORMATION, with a real premium on top.** The hard, unconditional value is ≈**1.36M sh × $30.69 ≈ $42M**, against a one-day market-value gain of ~**$18.6–21B**. Even the *entire* warrant at full undiscounted notional (~$12.2B, contingent, unvested, no floor, over 6.5 years) is smaller than the single-day gain. Against that: the filing genuinely resolves a live uncertainty — whether Google is diversifying TPU silicon beyond Broadcom — and the vesting structure is itself a directional signal of intent. Two dated comparables both favour continuation over fade: **AMD/OpenAI warrant, 2025-10-06** (+23.7% day one, +58.3% over October, no fade) and **Broadcom/OpenAI, 2025-10-13** (+~10% day one, though a later financing-related partial reversal is reported and could not be dated).
- **(d) The trajectory is the most informative datapoint on this name.** The day-2 continuation (+5.79% to 251.01) **round-tripped entirely** on 08-21 (237.04), while the event-day gap itself held ~99% intact. The market faded its own follow-through and defended the re-rating.
- **(e) Convergence indicators.** Any S-3 registering warrant shares for resale (near-term exercise intent); Custom Products revenue attributed to Google on the call; analyst FY2027/2028 revisions; Broadcom's commentary on whether its TPU position is eroding; Alphabet management commentary.
- **(f) Convergence target — FORECLOSED IN PRACTICE.** See the cohort finding: MRVL's own Q2 FY2027 call is estimated **~2026-08-27/28, inside the entry window** — an SP5 in-window binary, the exact SNDK/AMD decline ground, not a usable target.
- **(g) Eligibility.** NASDAQ common equity; market cap ~$168–213B across sources; ADV not in doubt.
- **(h) Confidence: LOW-MODERATE on the mispricing; MODERATE-HIGH that it must not be expressed as a short.** The only expression consistent with the arithmetic is a fade, and B is long-biased by construction: **0 of ~108 theses through 2026-06-22 produced a short entry, and every declined short subsequently held or extended.** Ranked fifth on analytical interest; structurally close to foreclosed.

---

## REST (ranked 6–12)

### 6. MRNA — Moderna · qualifying event 2026-08-19 · **+177.03%** · 7 sessions left · D1 origin `125445a7…`
Largest single-name move this screen has ever recorded, and **criterion 3 forecloses it**. The readout is real and strong: Phase 3 INTerpath-001, intismeran autogene + KEYTRUDA vs KEYTRUDA alone, **N=1,137**, resected Stage IIB–IV melanoma, randomised 2:1, met primary (RFS) and key secondary (DMFS) at a pre-specified interim. **But the companies disclosed no hazard ratio and no p-value** — full data are held for an unnamed upcoming medical meeting — and **no BLA has been filed**, so there is no dated FDA decision to name. Q3 earnings land ~early November, outside 60 days. With no admissible convergence target, a GO is unreachable regardless of direction, which is the BTSG 2026-08-03 disposition ("criterion 3 foreclosed on the closed list"). Information-driven besides: 127.7M shares against ~2–4M on prior days is broad repositioning, not a thin-float squeeze, and nothing negative emerged on 08-20 to make the −23.55% give-back a correction rather than profit-taking (it then re-rallied +8.86% on 08-21, leaving ~73% of the event gain intact). Balance-sheet context a thesis pass must carry: cash and investments **$6.9B** at Q2 2026, FY26 year-end guided to $4.7–5.2B after a **$950M litigation settlement paid July 2026**, on Q2 revenue of $145M. **Comparables were sought and the base-rate question is unanswered** — no retrieved case is simultaneously Phase 3, >100% in a session, and carries a confirmed 2–8-week path; Madrigal (2022-12-05) and Akero (Feb 2024, Phase 2b) were found without forward data, and Intellia's first-in-vivo-CRISPR Phase 3 (2026-04-27) moved only +35%, which itself says +177% is large even among genuine platform-validation events. A prior MRNA B NO-GO exists (2026-07-12, SP10) on a **different** event identity; it does not dedupe this one.

### 7. EL — Estée Lauder · qualifying event 2026-08-19 · **+16.30%** · 7 sessions left · D1 origin `125445a7…`
The cleanest post-event *shape* of its session and, on the trajectory, the clearest efficient-repricing signature: EL **extended to 101.94 on 08-21**, +20.97% cumulative and a fresh high. A correction to the intake framing matters here — the "+3% organic" figure is the **full-year FY2026** number; the *quarterly* organic figure was **+5%**, the fourth consecutive quarter of acceleration, which is what the market reacted to. Q4 revenue $3.63B vs $3.54B street; adj EPS $0.39 against a depressed $0.09 year-ago base; gross margin +360bp to 75.5%; a sixth consecutive quarter of China mainland share gains. The load-bearing item is forward: **FY27 operating margin guided 12.7–13.5% against FY26's 11.2%**, ending three consecutive years of revenue decline. Against that, the FY27 EPS guide midpoint (~$3.23) beats consensus by only ~1.4%, so a +16% move is substantially multiple re-rating — the "under-react for a year, over-react in one day" shape. Verdict leans information-driven on the strength of a dated, guided margin step-change; held-and-extended argues the same way (the VZ NO-GO ground). Note for the taxonomy: **EL is the named exemplar of Sub-Pattern 7 (TEAM+V/MDLZ-Hybrid, "EL Pattern")** in `B_Sub_Pattern_Taxonomy.md`, so this name has prior form worth reading before a pass. Comparables not retrieved (only sub-threshold: Mondelez/Kellogg 2017 +5.5–6.5%, P&G 2018 +6.8%). Convergence: numerical target required; Q1 FY27 ~early Nov is ~70+ days out.

### 8. MRK — Merck · qualifying event 2026-08-19 · **+12.60%** · 7 sessions left · D1 origin `125445a7…`
Same catalyst as MRNA. **The decisive number is public and it is the collaboration economics: Merck and Moderna split costs and profits 50/50 worldwide** on intismeran (Merck exercised its option in 2022 for $250M, atop a $200M upfront). A +12.60% move on a ~$380B base is ≈**+$48B of market value**, which a melanoma-only NPV cannot support on its own — so the market is pricing read-through to the other INTerpath tumour programmes plus mitigation of the **KEYTRUDA loss-of-exclusivity cliff** (core compound patent expires December 2028; retrieved revenue-at-risk estimates range $25B to $31.7B, and the range is reported rather than resolved). Whether $48B is proportionate to that combined read-through is not established, and is the question a pass must answer. Trajectory argues efficient repricing: held and made a **new high at 152.55 on 08-21**. One dated comparable, and it is a caution rather than support: **AstraZeneca/Daiichi DESTINY-Breast04** — universally called practice-changing, standing ovation at ASCO 2022, and AZN nonetheless fell ~3.58% the following Monday because the run-up had pre-priced it. Only one comparable was secured against the two to four requested. Convergence: Q3 ~late October sits at or just past the 60-day line and could not be confirmed; treat "next earnings release" as non-compliant until dated.

### 9. NDSN — Nordson · qualifying event 2026-08-19 · **+8.00%** · 7 sessions left · D1 origin `64ea0fce…`
B's weakest mechanism class by the strategy's own definition — a beat-and-raise that rose — and the arithmetic says the market got it about right. Adj EPS $3.25 (record, +19% YoY) vs ~$3.09; revenue $817.7M (record, +10%) vs ~$779.4M; EBITDA record $262M at 32% margin; FY26 guidance raised to $3,035–3,075M sales and $11.80–12.00 adj EPS (from December's $2,830–2,950M / $10.80–11.50). The guide-raise adds roughly $42–50M of annual earnings power (~56M diluted shares), worth ~$0.85–1.25B at a 20–25x industrial multiple, against an implied ~$1.3B one-day market-value gain — proportionate, with a modest forward premium for the **+35% backlog** (ATS +31%; CEO Nagarajan on the 2026-08-20 call: "order entry momentum continued to accelerate"). The open question is backlog durability: semiconductor/electronics-linked backlogs are cyclical and capex pull-forward is a live risk. Worth flagging a thematic coupling — NDSN's ATS surge and MRVL's re-rating are both riding the same AI/semiconductor-capex impulse in the same week, which is a correlation W4 should see even though it changes neither verdict. Comparables materially incomplete: Quanta Services retrieved with no reaction data; Chart Industries Q1 2025 with **conflicting** day-of figures (+14.7% intraday vs +1.09% premarket) and no forward path.

### 10. CVNA — Carvana · qualifying event 2026-08-19 · **+8.37%** · 7 sessions left · D1 origin `125445a7…`
An unusual and instructive B case: the "event" is a **research report correcting a market misapprehension**, not a company action, so its information content is bounded and knowable. Hunterbrook published 2026-08-18 off Delaware financing-statement filings showing Mark Walter's ~4% (~$2B, ~30M shares) stake is pledged to Citigroup against derivatives and margin loans under an agreement amended February 2024, July 2025 and **June 23 2026** — i.e. it cannot be quickly force-sold. Quantifying the overhang: CVNA fell ~14% across 08-17 and 08-18; the 08-17 leg (−7.28%) was already ruled non-informative profit-taking, so the fear-specific leg is roughly the residual ~6–7% — and **+8.37% is a full-to-slightly-more-than-full reversal of it**. If the pop merely undid the overhang, the market got it right and there is no fresh mispricing, which is the conclusion here. Two residual items keep it from being a clean decline. First, a **broader TWG-Global-level liquidity concern (~$7.6B of commitments, per Eric Jackson) is not addressed** by a report scoped to the CVNA pledge alone, and could still be unpriced. Second — material and unresolved — **Hunterbrook's disclosure status could not be established**: hntrbrk.com and a Seeking Alpha write-up both returned HTTP 403, and Hunterbrook operates a disclosed trading affiliate, so whether this is information or promotion is genuinely open. Convergence: Q3 is **2026-10-29**, ~67 days out — outside 60 days, though closest of the cohort.

### 11. DE — Deere · qualifying event 2026-08-20 · **+6.94%** · 8 sessions left · D1 origin `64ea0fce…`
B's weakest class again, and the trajectory is the most adverse in the cohort for an over-reaction thesis: DE **extended a further +4.27% on 08-21 to 647.47**, +11.51% cumulative, with no give-back at all. Q3 net income $1.379B ($5.10/sh) vs ~$4.70 consensus; equipment-operations sales $11.0B vs ~$10.73B; FY net income guidance raised to $4.75–5.00B; **Construction & Forestry sales +18% to $3.6B with operating margin expanding to 12.1% from 7.7%**, carried by infrastructure and data-centre demand; volume 2.01M vs ~795K. Management's own framing is that FY2026 is "the bottom of the ag equipment cycle" — a claim, not a fact, but one corroborated cross-sectionally by CNH beating and raising on 2026-08-03 and by Caterpillar's strength. The cross-check that cuts against a sector-wide mispricing read: **AGCO cut guidance in the same window**, so the re-rating is not uniform. One dated comparable with a partial forward path: **CNH surged as much as 17% intraday to $11.95 on 2026-08-03 and by 2026-08-20 was grinding in a $10.25–10.95 range** — most of the pop faded — though the later figures are inconsistent across aggregators and the fade magnitude should be treated as directional only.

### 12. AMLX — Amylyx Pharmaceuticals · qualifying event 2026-08-18 · **+63.83%** · 6 sessions left · D1 origin `9394d515…`
Eligible and information-driven, with two structural problems. **Eligibility resolves in its favour: $4.31B at $38.66 (stockanalysis.com, dated 2026-08-21), clearing the $2B floor by more than 2x** — against a pre-event cap of roughly $1.3–2.0B, so the floor is cleared *because of* the event, which is worth stating plainly since B tests the floor at entry. 30-day dollar volume is **UNVERIFIED** — not fetched, very likely satisfied, not asserted. The readout is as clean as binary catalysts get: avexitide in post-bariatric hypoglycaemia, N=78, randomised double-blind placebo-controlled, **FDA-agreed** primary endpoint (composite Level 2/3 hypoglycaemic-event rate) met with a **55% reduction, p=0.000003**, secondaries also met. Under B's default assumption that is presumptively correct pricing, and no mispricing was established in either direction. The two problems: **no NDA has been filed, so there is no dated FDA decision to name as a convergence target**, leaving only a numerical price level that the missing comparables cannot support; and an **upsized $350M secondary priced 2026-08-19 at $35.50 (14.09M shares), inside the entry window** — a dilution/supply event of exactly the kind the BBIO NO-GO (SP4e) turned on. Comparables were deliberately not retrieved for this name; the call budget went to the ARGX listing question and this market-cap question, both of which were decision-changing and both of which resolved.

---

## HONEST LIMITS OF THIS RUN

- **Comparable historical reactions are the systematic weak point of this cycle.** B Entry criterion 2 requires comparables **retrieved, not recalled**, and for **7 of 12** names none were obtained: KLAR, AAP, EL, CVNA and MRNA-with-a-forward-path outright, plus NDSN and MRK where what was retrieved is incomplete or internally inconsistent. Every sub-agent was instructed to say so rather than supply a remembered analogue, and every one did. This is reported as a gap in the evidence, not smoothed over — and it means no candidate here carries a genuine base rate for its shape.
- **Four next-earnings dates are estimates, not confirmations** (WMT, DE, NDSN, FN), and **MRVL's is both estimated and decisive** — if its call really is 2026-08-27/28 that is an in-window binary. Confirming it is the highest-value single fact outstanding.
- **AMLX's 30-day dollar volume is unverified**, and its +63.83% is the one magnitude in the rankable set not independently reconciled against IBKR bars this run (it entered the set after its eligibility resolved).
- **AAP's market cap clears the floor by only ~$570M** on a single dated source; conflicting undated aggregator figures spanned $2.56–3.68B and were not relied on. Worth a second dated confirmation before entry.
- **Source conflicts left unresolved rather than smoothed:** COHR's own event-day magnitude (~4.94% vs ~12%); Chart Industries' reaction to Q1 2025 (+14.7% intraday vs +1.09% premarket); Merck's KEYTRUDA revenue-at-risk ($25B vs $31.7B); KLAR's market cap (implied $3.4B vs implied $17–18B across two search threads) and its dollar-volume figures (16.97M vs 6.76M shares, with a quoted $28.32M that reconciles with neither).
- **Two primary sources were unreachable:** the Hunterbrook report itself and a Seeking Alpha write-up of it (both HTTP 403), leaving Hunterbrook's trading-disclosure status open; and Fabrinet's GlobeNewswire release 503'd, so the $56.7M securities loss and the September-quarter consensus figure rest on the intake record rather than on a freshly-read filing.
- **No `strategy/` or `strategy_math/` file was read for editing or modified.** `strategy/04_strategy_b.md` and `01_shared_regime_vocabulary.md` were read for entry criteria and eligibility only, per W2's slice map.
- **No transient failures, no retries owed, no `RETRY` token.** BigQuery, IBKR and the web surface were all live throughout.

## OPEN QUESTION CARRIED FORWARD FOR THE OWNER — the ADR line is now doing real work, twice in two weeks

The prior cycle raised this and it decided **two** names this week, in opposite directions. **ARGX was EXCLUDED** — Nasdaq's own security description titles the listing "argenx SE American Depositary Shares (ARGX)" and the ordinary shares trade on Euronext Brussels, making it structurally identical to the excluded JD/AZN/NVO. **KLAR was ADMITTED** — Klarna Group plc's IPO sold *ordinary* shares directly onto the NYSE with no depositary wrapper, making it structurally identical to the admitted ONON. One diagnostic that must NOT be used, because it fails: **the 20-F filing form is not dispositive** — both ARGX (an ADR issuer) and ONON (a direct-ordinary issuer) file 20-F as foreign private issuers, so anyone reading "files 20-F" as an ADR tell will get it backwards. The workable tests are the exchange's own security description, the presence of a separate home-market ordinary listing, and an F-6 registration naming a depositary bank. **This rule is currently reconstructed from precedent by each session rather than written into `strategy/04_strategy_b.md`'s instrument-eligibility list, which says only "US-listed common equity."** It has now changed the disposition of a top-5-eligible name (KLAR, ranked #1) and a 16%-mover (ARGX) inside a single cycle, and it should be pinned in the spec rather than re-derived. Pinning it is a Strategy.md change, and Strategy B's machinery is spec-locked and immutable — so this is an owner/SL-path decision, not something W2 may do.

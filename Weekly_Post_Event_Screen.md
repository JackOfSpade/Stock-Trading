2026-W37

# Weekly Post-Event Screen — Strategy B (W2)

**Run date:** 2026-09-13 (Sunday) · **Routine:** W2, deep research · **Marker:** 2026-W37
**Intake watermark:** 2026-09-06T08:44:25Z (this routine's own prior completion) · **Catch-up window:** 6.97 days = 1.00x the weekly norm, so no `CATCHUP` token is owed.

**SCREEN MODE: INDEX (B router DO-NOT-ACTIVATE as of 2026-09-03).**

---

## SCOPE OF THIS RUN — WHAT W2 DOES AND DOES NOT DO

W2 performs **zero market-wide discovery**. It does not pull broad price bars to find movers, does not enumerate a population, does not repeat an event search, and does not re-judge D1's §19 significance verdicts. Its intake is the durable D1 `research-screen` / `single-name-move` record since W2's own last completion; its job is B-specific eligibility, ranking and enrichment on top of that record.

The 2026-09-11 (Friday) session is **deliberately uncovered** by this run and that is correct, not a gap in it. D1 runs Sun–Thu; the last D1 screen in this window covers the 2026-09-10 session, and D1's Sunday scan (tonight, after W2) owns 09-11. PART 1 forbids W2 covering that gap with its own bar pulls. Two names D1 explicitly handed forward sit in that session — **ORCL** (FQ1 FY27 printed after the 09-10 close) and **ADBE** — and they belong to the next D1, not to this file.

**Router gate, read FIRST per the 2026-08-24 limb.** `state.current_regime` scope `STRATEGY_ACTIVATION` key `B` = **DO-NOT-ACTIVATE**, divergence `div-B-202608-1`, `as_of` 2026-09-03, theater-check DIVERGENT. Identical reading to the prior cycle — the 2026-09-03 divergence review re-adjudicated B and held it (M1b raw call ACTIVATE, overridden by the universal `shock_overlay=acute` rule for the second consecutive month). So PART 2 runs in **INDEX MODE**: per eligible item this file records only ticker, qualifying event date, event-day close-to-close move, window close date, sessions remaining, a one-line factual event description, the originating D1 decision id, and a rank. The mispricing direction/magnitude read, the retrieved-comparables step, the information-versus-sentiment analysis and the convergence-indicator enumeration are **deliberately skipped**. The cohort-level work is kept in full.

**No out-of-cycle flip is in flight.** MEASURED: zero open `PENDING_REGIME_REFRESH` items anywhere in `events.queue_events` (and none in that queue's whole history), and the standing `FUNDAMENTAL_AXIS` snapshot is `as_of` 2026-09-01 with `shock_overlay = acute` — nothing newer than the monthly M1a re-score. Both scheduled paths to a flip (M1a monthly; D2a's re-risking limb → M1R → D2's router review) remain open, but neither is currently moving.

**B's capital, stated because it is a today-only fact, not a bar.** `analytics.strategy_nav` for B: nav 0, deployed_mv 0, available_funds 0. `state.regime_capital_debt` for B: swept out 4,973.25, restored 0, **outstanding 4,973.25** — restorable pro-rata on a flip with no gate. An ACTIVATE-but-unfunded B would still get full-depth analysis; the zero NAV is not why this run is in index mode. (The open W5 `regime_restore_shortfall` warning notes the donor set is currently empty; that is W5's item, not W2's.)

---

## WINDOW ARITHMETIC

Convention, unchanged and re-verified against the prior file's published closes: the qualifying event day counts as session 1, and the entry window closes on the **10th trading day inclusive**. 2026-09-07 was Labor Day; 2026-09-11 is the last completed session.

| Qualifying event date | Window closes | Sessions remaining after today |
|---|---|---|
| 2026-09-04 | 2026-09-18 | 5 |
| 2026-09-08 | 2026-09-21 | 6 |
| 2026-09-09 | 2026-09-22 | 7 |
| 2026-09-10 | 2026-09-23 | 8 |

Where a release preceded the reaction (COO, AEO, NAVN — reported after the 09-09 close, reacted 09-10), the **window** runs from the qualifying event date while the **measured magnitude** is the reaction session's close-to-close move. Two different clocks, deliberately not merged.

---

# PART 1 — D1-ORIGINATED POST-EVENT INTAKE (no market-wide re-screen)

## Intake source

Five operative D1 `entry_type='research-screen'`, `screen='single-name-move'` rows landed after the watermark. Zero superseded rows in the window.

| D1 entry id | D1 run date | Session screened | Passed | Rejected-notable |
|---|---|---|---|---|
| `8ba82a4c-a983-4d95-8fb1-a9fff9cf5159` | 2026-09-06 | 2026-09-04 | 10 | 10 |
| `f9b75f38-a66b-4d98-822f-903aaad949f6` | 2026-09-07 | **none — Labor Day** | 0 | 0 |
| `a4ce03b2-a971-4103-93b5-aabf7b8764b5` | 2026-09-08 | 2026-09-08 | 10 | 21 |
| `acc31c4a-2889-4583-a76a-0177ecd34dcf` | 2026-09-09 | 2026-09-09 | 8 | 9 |
| `7d717e9f-c609-4166-8487-e965a2faff13` | 2026-09-10 | 2026-09-10 | 16 | 8 |

**44 passed item-rows, 41 distinct tickers** (AAPL twice, INTC three times — three genuinely distinct sessions and events, not duplicates). The 2026-09-07 row is a **measured-empty** screen, not a degraded one: it records `no_session_in_window = true`, names the run that already screened 09-04, and states the once-only rule ("a session is screened once, by the run whose window contains it"). Reading it as a missed day would be wrong.

Of the 44 passed rows, **31 clear B's frozen spec floor** (≥5% event-day move, `strategy/04_strategy_b.md` Entry criterion 1; `legacy_rule_pass = true`, `below_spec_floor = false`) and are rankable. The other **13 are context only** and are listed as such below.

## Four-part identity dedupe — CLEAN, matched on the FIELDS, never on the key string

Per the 2026-08-23 KEY-FORMAT PIN, matched on `(analysis_type='thesis-construction', strategy='B', ticker, qualifying_event_date)` rather than on a constructed `thesis-<TICKER>-B-<YYYYMMDD>` string.

MEASURED: `events.queue_events` holds 86 raw append-only Strategy-B thesis-construction rows resolving to **42 distinct identities, every one terminal** (`complete` is the max-`event_ts` row for all 42, zero exceptions). Every identity with an extractable date carries one of **2026-07-31 or earlier**, against an intake spanning 2026-09-04..09-10 — the sets cannot intersect.

Six identities (ANF, AVGO, CPRI, CRWD, HPE, OKTA, all early June) have **no extractable date at all** — they have no `pending` row, only a `complete` row with a NULL payload. That gap does not bite this cycle for a reason worth stating plainly rather than assuming: **none of those six tickers appears anywhere in this intake**, so the dedupe verdict does not depend on dates that cannot be recovered. A future cycle whose intake does contain one of them cannot resolve it from `queue_events` and must fall back on `events.decision_log`.

The payload schema has **three** variants, not the two the prior cycle recorded: June-era items bury the date in `$.context` prose; a late-June batch carries it under `$.day0` or an `$.event` prose key; July-13-onward carries a structured `$.event_date`. `events.queue_events` has **no `qualifying_event_date` column** (confirmed against `INFORMATION_SCHEMA`, not inferred from a NULL result), so the field-based dedupe this routine is required to perform remains only partly machine-queryable. This sharpens, rather than repeats, the prior cycle's version of the same observation.

## Prior NO-GO records on names in this intake — context, not barriers

This is the first cycle in the lineage to check the intake against the full `events.decision_log` Strategy-B thesis history rather than the queue alone, and it changes what the file can say. MEASURED — eight prior B thesis-construction decisions exist on names in this intake, every identity distinct from this cycle's by event date:

| Ticker | Prior decision | Date | Ground recorded then |
|---|---|---|---|
| **FICO** | NO-GO | 2026-07-30 | criterion 4 — information-driven structural repricing of mortgage-scores pricing power |
| **TSLA** | NO-GO | 2026-07-26 | criterion 4 — information-driven structural repricing |
| **INTC** | NO-GO ×5 | 04-27, 05-12, 06-08, 06-21, 07-26 | criterion 4 on four of five; the most-screened B name in the record |
| **LULU** | NO-GO | 2026-06-08 | — |
| **META** | **GO** | 2026-05-01 | MEDIUM conviction — the only GO among these names |
| MU / ORCL / RDDT | NO-GO | 06-28 / 06-21 / 08-03 | (all three are excluded this cycle on other grounds) |

**FICO is the one that matters and it is nearly the same question.** Its 2026-07-30 NO-GO was reasoned on mortgage-score pricing power being *information-driven structural repricing*, and its 2026-09-04 qualifying event is the FHFA directive that ends FICO's GSE scoring exclusivity — the same thread, one level more concrete. Per the shared rule this is **context, not a barrier**: a prior NO-GO tells a future session what to look at, not what to conclude, and a decisive new fact can flip it. What it does mean is that FICO's criterion-4 step is not a fresh question, and a full-depth pass should start from that record rather than rediscover it. INTC's five-for-five NO-GO history is the same signal at lower intensity.

## Items preserved from D1

Every field below is preserved from D1's own record. Where D1's record is silent the cell says so; nothing here is re-derived, and D1's significance verdicts are not revisited.

### PRICE-BASIS RECONCILIATION — ZERO CORRECTIONS OWED, FOURTH CONSECUTIVE CYCLE

An independent IBKR pull (`STK`, `ONE_DAY`, `outside_rth=false`, batches of at most 4 per the 2026-08-20 shifted-response defect) covering all 22 eligible names returned a complete 7-session series each, every bar stamped 13:30:00Z, no missing bar, no ambiguous contract left unresolved, no two series identical. **All 22 event-day magnitudes reproduce D1's recorded figures**; the largest disagreement across the set is **0.0010 pp** (TSLA −5.9224% measured vs −5.9231% recorded). This run did not recompute the moves to second-guess D1 — the closes were pulled for the cohort work and the agreement fell out of them.

A second, larger reconciliation fell out of the panel pull: **all 37 residual figures published by the two prior cycles reproduce exactly** on an independent pull of the same names (cohort-1 at 08-28 and 09-04, cohort-2 at 09-04 — see the trajectory section). Two prior cycles' arithmetic is therefore independently confirmed, not merely carried forward.

### Rankable — passes BOTH D1's §19 significance judgment AND B's ≥5% frozen spec floor (31 items)

Listed by source screen. Magnitudes are D1's, confirmed on this run's independent bars.

**From the 2026-09-04 session** (`8ba82a4c`): FICO −16.68%, GWRE −19.93%, LULU −17.38%, TSLA −5.92%, MU +6.10%, IREN +7.27%.
**From the 2026-09-08 session** (`a4ce03b2`): NVS −13.93%, ROIV +18.75%, GPCR −14.70%, AMGN −10.08%, INTC +9.05%, BKNG −6.72%, QBTS +6.57%.
**From the 2026-09-09 session** (`acc31c4a`): META +6.55%, TTAN −29.98%, SIG +23.96%, TBBK −22.33%, BRZE −21.71%, CASY −14.24%, ASO +14.40%, CMCSA −6.61%.
**From the 2026-09-10 session** (`7d717e9f`): COO −14.67%, AEO −13.97%, NAVN −21.75%, SCCO −7.23%, FCX −6.59%, INTC −5.57%, ORCL −5.38%, LRCX −5.65%, CIFR −5.68%, RDDT +6.08%.

### Context only — `below_spec_floor = true` (<5% event-day move, not rankable per B's frozen spec) — 13 items

PCG +2.44%, AAPL −2.51%, INTC +4.51%, RIG −2.82% (09-04) · IONQ +2.40%, IONS −2.38%, RGTI +4.01% (09-08) · AAPL +3.56%, ELV +4.98%, M −4.70%, CHTR +4.98%, AVAV +4.45%, AGNC −3.04% (09-10).

Two are worth naming because they invert the usual reading. **IONQ** (+2.40%) is the name that actually *had* the event — a FY2026 revenue guide raised to $450–460M — while the names that cleared the floor on it (QBTS +6.57%, RGTI +4.01%) moved on sympathy. And **M** (Macy's) beat and raised guidance and still fell 4.70%, which is the shape B exists to look at, one third of a percentage point below the floor that would have made it rankable. Neither is eligible; B's floor is frozen spec and this run does not bend it.

### Identities EXCLUDED before enrichment, with the ground — 9, every ground drawn from D1's own record or B's frozen spec

| Ticker | Move | Ground for exclusion |
|---|---|---|
| **NVS** | −13.93% | **Instrument eligibility.** Novartis AG is a Swiss issuer whose US line is a depositary receipt over shares trading primarily on SIX. `strategy/04_strategy_b.md` admits only US-listed common equity — the same ground as the standing AZN / NVO / JD / BABA / FUTU / ARGX exclusions. |
| **ORCL** | −5.38% | **D1's own record.** Its FQ1 FY27 print landed *after* the 09-10 close; D1 states outright "ORCL IS DELIBERATELY NOT A STRATEGY-B CANDIDATE", its reaction session is 2026-09-11 and the next D1 owns it. The 09-10 decline is pre-earnings de-risking, not a reaction to a completed public event. |
| **INTC** (09-10 leg) | −5.57% | **No issuer event.** D1 records profit-taking after a multi-session rally plus the rate-driven semi selloff. The 09-08 INTC leg (+9.05%, Bloomberg price-raise report) is a genuine event and is the one carried; this is a distinct identity and it fails criterion 1 on the event half. |
| **LRCX** | −5.65% | **No issuer event.** D1: "same rate channel", deepest of the semi-cap-equipment complex. |
| **CIFR** | −5.68% | **No issuer event.** D1: crypto/AI-DC complex risk-off, driver shared with MARA and IREN and counted once. |
| **MU** | +6.10% | **No issuer event.** D1 types it "sector narrative" — the AI-memory / DRAM-HBM shortage anchor. |
| **IREN** | +7.27% | **No issuer event.** D1: a re-rating/decoupling narrative (up while BTC fell ~2%), no discrete issuer item. |
| **QBTS** | +6.57% | **No issuer event.** D1 types it "sympathy (quantum cluster)" to IonQ's investor-day raise. The event belongs to IONQ, which moved +2.40% and is below the floor. |
| **RDDT** | +6.08% | **Analyst action only.** The driver is a Piper Sandler note on third-party monthly user growth, not an issuer disclosure — the ground on which QBTS and SRE were excluded on 2026-08-30, and the SP6 sub-pattern shape. Distinct from RDDT's 2026-08-25 identity; excluded on event type, not on dedupe. |

**22 items survive to PART 2.**

## Eligibility flags carried, NOT treated as exclusions — three names

Per the MARKET CAP BASIS rule (Operating_Protocols.md §290), a name whose cap estimate sits within ~25% of the $2B floor is not decided until shares outstanding is re-derived from the issuer's own most recent filing. That is a metered / EDGAR path, and it is exactly the per-candidate research index mode does not spend. So these three are **ranked with the flag visible** rather than silently admitted or silently dropped:

- **TBBK** — D1 measures $2.083B, ~4% above the floor, and flags it itself as wanting a second source before sizing. Rail clearance **UNVERIFIED this run**.
- **AEO** — D1 measures $2.437B and states explicitly that it "sits inside the ~30% band around the $2B rail where FMP implied share count is not trustworthy". Rail clearance **UNVERIFIED this run**.
- **GPCR** — D1 measures $2.32B and calls the rail call **provisional for that one name** in its own text.

None of the three is excluded on this basis, because an unverified clearance is not a measured failure — the contrast is WOLF (2026-08-30), which was excluded only after being *measured* at $1.37B. If B flips inside any of these three windows, resolving the cap is the first step of the full-depth pass, not an optional one.

## Criterion 5 binds nothing this cycle

MEASURED: `state.current_positions` holds **12 open positions, every one Strategy D** (AMZN ×2, DIS ×2, GEV, GOOGL ×2, ISRG, RTX, TSM ×2, UBER). There are **zero open Strategy A positions and zero open Strategy B positions** — B has been flat since MSCI closed on 2026-08-18. No candidate is excluded by the A/B same-name rule, and none of the 22 overlaps the open D book in any case.

## PRICE-LAYER COMPLETENESS BACKSTOP

The verification pull returned full bar series for 22 eligible names plus the 37 panel names, and was scanned for any ≥3% session inside the window that no D1 screen reported. The material one is **HPE: +12.44% on 2026-09-11** (55.22 → 62.09), the largest single-session move anywhere in the 59-name pull and roughly two and a half times its own 2026-09-03 earnings reaction. It falls in the 09-11 session, which **no D1 screen has covered yet** — D1's Sunday scan tonight owns it — so this is a forward hand-off, not a miss, and it is named here so that the next cycle can check the disposition rather than rediscover the move. Nothing else in the pull clears 3% inside a screened session without a D1 disposition.

Note the second-order effect: HPE was a below-cap candidate of the prior cycle on a 2026-09-03 event whose window is still open to 2026-09-16, and its residual is now contaminated by a second, larger, unrelated event (see the trajectory section, where it is reported and then set aside).

---

## POST-EVENT TRAJECTORY — the residual-thinness test

Index mode skips per-candidate enrichment but **keeps the cohort work in full**, because it costs little and it is the evidence series a future divergence review reads when it re-tests B's convergence assumption.

`gap_intact_pct` = (close 2026-09-11 − pre-event close) / (event-day close − pre-event close) × 100. 100% means the whole event-day move is still in the price; 0% means it round-tripped exactly; negative means it reversed clean through; above 100% means it extended.

**This cycle is the first with a THREE-point panel.** Cohort-1 (the 2026-08-30 cycle's 17 names) has now been measured at 08-28, 09-04 and 09-11 — 1–6, 5–10 and 11–15 elapsed sessions. Cohort-2 (the 2026-09-06 cycle's 20 names) has two points, 09-04 and 09-11. Every prior published figure was recomputed from an independent pull and **all 37 reproduce exactly**, so the three series are on one arithmetic.

### Series A — this cycle's 22 eligible names, measured at 2026-09-11

| Ticker | Reaction session | Event-day move | Sessions elapsed | `gap_intact_pct` @ 09-11 |
|---|---|---|---|---|
| FICO | 09-04 | −16.68% | 4 | **72%** |
| GWRE | 09-04 | −19.93% | 4 | **153%** |
| LULU | 09-04 | −17.38% | 4 | **108%** |
| TSLA | 09-04 | −5.92% | 4 | **49%** |
| ROIV | 09-08 | +18.75% | 3 | **90%** |
| GPCR | 09-08 | −14.70% | 3 | **125%** |
| AMGN | 09-08 | −10.08% | 3 | **136%** |
| BKNG | 09-08 | −6.72% | 3 | **149%** |
| INTC | 09-08 | +9.05% | 3 | **82%** |
| META | 09-09 | +6.55% | 2 | **86%** |
| TTAN | 09-09 | −29.98% | 2 | **110%** |
| SIG | 09-09 | +23.96% | 2 | **89%** |
| TBBK | 09-09 | −22.33% | 2 | **96%** |
| BRZE | 09-09 | −21.71% | 2 | **97%** |
| CASY | 09-09 | −14.24% | 2 | **113%** |
| ASO | 09-09 | +14.40% | 2 | **165%** |
| CMCSA | 09-09 | −6.61% | 2 | **65%** |
| COO | 09-10 | −14.67% | 1 | **103%** |
| AEO | 09-10 | −13.97% | 1 | **79%** |
| NAVN | 09-10 | −21.75% | 1 | **87%** |
| SCCO | 09-10 | −7.23% | 1 | **104%** |
| FCX | 09-10 | −6.59% | 1 | **103%** |

Mean residual by elapsed session: **1 session 95.1%** (n=5) · **2 sessions 102.6%** (n=8) · **3 sessions 116.4%** (n=5) · **4 sessions 95.4%** (n=4). Cohort mean **102.7%**, sd **29.0**, range 49%–165% (116 pp).

### Series B — cohort-2 (the 2026-09-06 cycle's 20 names), second observation

| Ticker | @ 09-04 (prior cycle) | @ 09-11 | Change |
|---|---|---|---|
| MRVL | 72% | **22%** | −50 |
| ESTC | 50% | **−2%** | −52 |
| GAP | 61% | **27%** | −34 |
| PYPL | 83% | **99%** | +16 |
| SOLS | 103% | **72%** | −31 |
| EIX | 83% | **88%** | +5 |
| PCG | 69% | **84%** | +15 |
| BMNR | 77% | **81%** | +4 |
| FRVO | 64% | **5%** | −59 |
| CRK | 52% | **22%** | −30 |
| DELL | 148% | **212%** | +64 |
| CRDO | 87% | **106%** | +19 |
| MDB | 111% | **122%** | +11 |
| NU | 97% | **17%** | −80 |
| SNOW | 62% | **46%** | −16 |
| HPE | 7% | **393%** | *(contaminated — see below)* |
| CIEN | 90% | **13%** | −77 |
| VSXY | 83% | **82%** | −1 |
| CPB | 145% | **168%** | +23 |
| TTC | 86% | **95%** | +9 |

**HPE is excluded from every statistic below.** Its 09-11 residual is not a measurement of its 09-03 earnings reaction at all — a second, larger, unrelated event moved it +12.44% that session (see the completeness backstop above). Leaving it in would have made this cycle's headline dispersion figure a report about one contaminated observation.

### Series C — cohort-1 (the 2026-08-30 cycle's 17 names), THIRD observation

| Ticker | @ 08-28 | @ 09-04 | @ 09-11 |
|---|---|---|---|
| AAOI | 108% | 112% | **113%** |
| BBWI | −3% | −21% | **38%** |
| BJ | −14% | 37% | **4%** |
| BTDR | 86% | 344% | **291%** |
| CRM | 108% | 115% | **91%** |
| CRWD | 75% | 62% | **45%** |
| DKS | 80% | 73% | **81%** |
| DNN | 69% | 78% | **−33%** |
| MU | 60% | −88% | **−15%** |
| NVDA | 43% | 113% | **47%** |
| OKTA | 83% | 94% | **83%** |
| RDDT | 3% | 18% | **52%** |
| SNDK | 108% | −140% | **−36%** |
| STX | 37% | 1% | **36%** |
| TSLA | 20% | 50% | **115%** |
| VEEV | 85% | 81% | **47%** |
| WDC | 0% | −33% | **51%** |

### What the cohort says

**FINDING 1 — the coin flip REPLICATES on an independent cohort, and the 2026-08-30 "monotone decay" reading is now refuted twice.** MEASURED: over the five sessions from 09-04 to 09-11, cohort-2's residuals rose for **9** names and fell for **10** among the 19 uncontaminated names (including HPE, which rose, it is 10 and 10). The prior cycle found 9 up / 8 down on cohort-1 over a different four-session interval. Two independent cohorts, two different intervals, two coin flips. MEASURED on Series A as well: this cycle's own cross-section shows no gradient either — 95% → 103% → 116% → 95% across 1 to 4 elapsed sessions. The prior cycle established that the decay claim did not survive a panel; this one establishes that its absence is reproducible rather than a property of the particular four sessions it happened to measure.

**FINDING 2 — dispersion widens in WEEK TWO and then stops, and the prior cycle's "4x" magnitude was outlier-driven.** This is a correction to a prior cycle's own headline, made on measurement, and it cuts two ways.

MEASURED, standard deviation of `gap_intact_pct` by elapsed horizon:

| Cohort | 1–6 sessions | 5–10 sessions | 11–15 sessions |
|---|---|---|---|
| cohort-1 (n=17) | **41.7** (@08-28) | **104.1** (@09-04) | **74.8** (@09-11) |
| cohort-2 (n=19, HPE excl.) | **27.0** (@09-04) | **57.0** (@09-11) | — |
| this cycle (n=22) | **29.0** (@09-11, 1–4 sessions) | — | — |

The widening from week one to week two is **real and now replicated** — cohort-1 ×2.5, cohort-2 ×2.1 — and it survives removing the two extreme names the prior cycle named: with BTDR and SNDK dropped, cohort-1's sd still goes 41.2 → 60.2 (+46%). What does **not** survive is the magnitude and the implied monotonicity. The prior cycle reported the *range* widening from 122 pp to 484 pp, "roughly 4x"; measured a week later the same 17 names span **327 pp**, so the range **contracted by a third** while elapsed time went on increasing, and BTDR alone accounted for roughly half the 09-04 variance. Range is the wrong statistic for this question — one name moves it — and "widens with elapsed time" should be read as "widens through week two, then plateaus", not as a monotone law.

**FINDING 3 — the durable result is that the cohort MEAN does not move at all, and this is the sharpest thing the lineage has said about B's mechanism.** MEASURED, mean `gap_intact_pct`:

- cohort-1: **55.8%** @ 1–6 sessions → **52.7%** @ 5–10 → **59.4%** @ 11–15. Flat across fifteen sessions.
- cohort-2 (HPE excl.): **85.4%** @ 1–5 → **71.5%** @ 6–10.
- this cycle: **102.7%** @ 1–4 sessions.

Within a cohort the average residual is essentially unchanged over every horizon measured, up to three weeks. Between cohorts the *level* differs a lot (56% / 85% / 103%), which is a statement about what kind of week produced the events, not about elapsed time.

INFERRED, and this is the substantive point: **B's edge cannot come from generic mean-reversion of the event-day move, because on these three cohorts the event-day move does not on average revert at all.** Whatever fraction of the move is going to be given back is given back almost immediately — inside the first session or two, before W2's intake even reaches the candidate — and the remainder is sticky for at least three weeks. That makes B a **selection** problem rather than a **timing** problem: the strategy's return has to come from identifying *which individual names* mis-reacted, not from being long the average post-event residual. Criterion 2 (over- or under-sized *relative to fundamental implications*) already frames it that way; this is the first measurement in the lineage that says the alternative reading is unavailable. Three cohorts, 59 names, one regime — a direction, not a base rate.

**FINDING 4 — a candidate finding, CHECKED AND REFUTED.** The obvious next hypothesis from Series B is that *negative* reactions persist while *positive* ones fade: cohort-2 at 09-11 splits **87.9% mean residual for the 10 down-movers against 53.3% for the 9 up-movers** (HPE excluded), a 35-pp gap in the direction the behavioural literature would predict. It does not replicate. Cohort-1 measured on the same date splits the **opposite** way — **38.3%** for its 7 down-movers against **74.2%** for its 10 up-movers. Two cohorts, same measurement date, opposite signs, 7–10 names per cell. Recorded as refuted so that a later cycle does not re-derive it from one cohort and report it as a signature.

**FINDING 5 — criterion 3 forecloses "next earnings release" for exactly two-thirds of the ranked cohort again, but the FDA limb is live for the first time.** DEDUCED from event structure, not looked up: **10 of the 15 ranked candidates have their own quarterly report AS the qualifying event** — GWRE, LULU, TTAN, SIG, BRZE, CASY, ASO, COO, AEO, NAVN. A company that has just reported next reports roughly 90 days out, past criterion 3's 60-day convergence boundary, so for those ten the enumerated event "next earnings release" is structurally unavailable and each would require a **numerical price target**. That is 67%, identical to the prior cycle's fraction on a completely different cohort, which strengthens the structural reading: W2's intake is dominated by names that just reported *by construction*, not by where the calendar happens to sit.

What is new is the other five. **Three of them are clinical-event names — ROIV, GPCR and AMGN — and "next FDA decision date" is on criterion 3's closed list.** This is the first cohort in the recorded lineage where that limb is even potentially reachable; the 2026-08-23 cycle's two biotech candidates (MRNA, AMLX) had no filed application and therefore no PDUFA date to name. Whether a *dated* decision actually exists for any of the three is per-candidate research index mode skips, so this is flagged as the highest-value outstanding fact in this file rather than asserted. The remaining two non-earnings names are TBBK (a customer's acquisition of a rival) and FICO (a regulatory directive) — neither is on the closed list, so both need a numerical target regardless.

---

# PART 2 — RANKED SHORTLIST (INDEX MODE)

**SCREEN MODE: INDEX (B router DO-NOT-ACTIVATE as of 2026-09-03).**

**Ranking rule, stated so it is reproducible:** rank is **absolute event-day magnitude**, nothing else. Eligibility flags are carried as a visible column rather than folded into the rank, so that the ordering can be checked against the measured moves without knowing this session's judgment. **Rank is a magnitude ordering, not a conviction ordering** — no candidate here has been evaluated against criteria 2, 3 or 4, because those are precisely the steps index mode skips.

## TOP-5

| # | Ticker | Qualifying event | Move | Window closes | Sessions left | D1 origin | Event (one line) | Flags |
|---|---|---|---|---|---|---|---|---|
| 1 | **TTAN** | 2026-09-09 | **−29.98%** | 2026-09-22 | 7 | `acc31c4a` | Beat on revenue and EPS, then −30% on a next-quarter guide below consensus. | — |
| 2 | **SIG** | 2026-09-09 | **+23.96%** | 2026-09-22 | 7 | `acc31c4a` | Q2 EPS $2.19 vs ~$1.72 est, FY guide raised, SSS +2.2%. | — |
| 3 | **TBBK** | 2026-09-09 | **−22.33%** | 2026-09-22 | 7 | `acc31c4a` | Chime to acquire rival BaaS partner Stride Bank for $590M — a structural client-loss event. | cap rail UNVERIFIED (~4% above floor) |
| 4 | **NAVN** | 2026-09-09 | **−21.75%** | 2026-09-22 | 7 | `7d717e9f` | FQ2 FY27 beat-and-raise met with −21.7% on a widening GAAP loss; recent IPO. Reported after the 09-09 close, reacted 09-10. | — |
| 5 | **BRZE** | 2026-09-09 | **−21.71%** | 2026-09-22 | 7 | `acc31c4a` | Revenue +26.2% YoY but FCF margin 12.7% → 9.6% and a weak Q3 guide. | — |

## REST (ranked 6–15)

| # | Ticker | Qualifying event | Move | Window closes | Sessions left | D1 origin | Event (one line) | Flags |
|---|---|---|---|---|---|---|---|---|
| 6 | **GWRE** | 2026-09-04 | −19.93% | 2026-09-18 | 5 | `8ba82a4c` | Q4 FY26 EPS $0.99 vs $0.85 est (a beat), −20% on guidance and valuation reset. | — |
| 7 | **ROIV** | 2026-09-08 | +18.75% | 2026-09-21 | 6 | `a4ce03b2` | Positive Phase 2 mosliciguat data plus an HC Wainwright target raise to $47. | FDA limb may be live |
| 8 | **LULU** | 2026-09-04 | −17.38% | 2026-09-18 | 5 | `8ba82a4c` | Comps −9%, revenue −4%, FY guide cut to $10.35–10.5B from $11–11.15B. | prior NO-GO 2026-06-08 |
| 9 | **FICO** | 2026-09-04 | −16.68% | 2026-09-18 | 5 | `8ba82a4c` | FHFA directive opens GSE mortgage scoring to VantageScore, ending FICO's exclusivity. | prior NO-GO 2026-07-30 on the same thread |
| 10 | **GPCR** | 2026-09-08 | −14.70% | 2026-09-21 | 6 | `a4ce03b2` | ACCG-2671 / aleniglipron Phase 1/2a readout judged underwhelming against incumbents. | cap rail PROVISIONAL (D1's own word); FDA limb may be live |
| 11 | **COO** | 2026-09-09 | −14.67% | 2026-09-22 | 7 | `7d717e9f` | FQ3 revenue miss $1.066B vs ~$1.098B, FY guide cut on CooperVision destocking. Reported after the 09-09 close. | — |
| 12 | **ASO** | 2026-09-09 | +14.40% | 2026-09-22 | 7 | `acc31c4a` | Net sales ~$1.60B, +3% YoY, a beat with the FY guide raised and buybacks. | — |
| 13 | **CASY** | 2026-09-09 | −14.24% | 2026-09-22 | 7 | `acc31c4a` | Beat on revenue, EPS and EBITDA but inside-store SSS +3.2% missed. | cap by inspection, not measured |
| 14 | **AEO** | 2026-09-09 | −13.97% | 2026-09-22 | 7 | `7d717e9f` | Comp-sales miss overwhelmed an EPS/revenue beat and a tariff-refund-boosted guide raise. Reported after the 09-09 close. | cap rail UNVERIFIED (inside the ±30% band) |
| 15 | **AMGN** | 2026-09-08 | −10.08% | 2026-09-21 | 6 | `a4ce03b2` | Read-across: class peer of pelacarsen (olpasiran) repriced on Novartis's CV-outcomes failure. | FDA limb may be live |

## BELOW THE CAP — seven eligible items, carried with the same fields so nothing is lost

The 15-cap is a full-depth cost control; in index mode the marginal cost of one more row is close to zero and these seven are otherwise identical in kind to the fifteen above. They are recorded in full rather than dropped, and they are **not** ranked.

| Ticker | Qualifying event | Move | Window closes | Sessions left | D1 origin | Event (one line) |
|---|---|---|---|---|---|---|
| INTC | 2026-09-08 | +9.05% | 2026-09-21 | 6 | `a4ce03b2` | Bloomberg report that Intel may raise chip prices next month. (Five prior B NO-GOs on this name.) |
| SCCO | 2026-09-10 | −7.23% | 2026-09-23 | 8 | `7d717e9f` | Copper retreat on White House indecision over a refined-copper tariff. |
| BKNG | 2026-09-08 | −6.72% | 2026-09-21 | 6 | `a4ce03b2` | Conservative forward guidance plus insider sales into a rate repricing. |
| CMCSA | 2026-09-09 | −6.61% | 2026-09-22 | 7 | `acc31c4a` | CFO conference remarks: Q3 broadband subscriber losses unlikely to improve YoY. |
| FCX | 2026-09-10 | −6.59% | 2026-09-23 | 8 | `7d717e9f` | Same copper-tariff driver as SCCO, the sector's other liquid pure-play. |
| META | 2026-09-09 | +6.55% | 2026-09-22 | 7 | `acc31c4a` | Muse paid AI agent launched at $20 / $100 tiers — a revenue-model event. (Prior B **GO**, 2026-05-01.) |
| TSLA | 2026-09-04 | −5.92% | 2026-09-18 | 5 | `8ba82a4c` | NHTSA audit query on Cybercab self-certification plus an underwhelming Cybercab update. (Prior NO-GO 2026-07-26.) |

---

## ROUTING — no thesis-construction enqueue is owed, and W4 must not create one

B is **DO-NOT-ACTIVATE**, so the router bars every new B entry for the whole of each candidate's 10-trading-day window. Per W4 §C this shortlist routes to `Watchlist.md`'s **"Strategy B watch overflow"** section marked **router-gated, not rank-gated**.

**THE DRAIN CANNOT REACH ANY OF THE 22, and the dates say so exactly.** Every window here closes between **2026-09-18 and 2026-09-23**. The next W4 is **today** and converts only the fresh intake it reads today — under a DO-NOT-ACTIVATE router that means routing to overflow, not enqueuing. M4's B-drain limb (added 2026-08-31) is `monthly_ftd` and next fires **~2026-10-01**, after the last of these windows has closed. So on today's arithmetic **zero** of the 22 can reach any consumer before expiry, and that holds even if the router flips tomorrow, because a flip changes activation and not the M4 cadence.

This is the **sixth consecutive router-gated cycle** and the **third consecutive index-mode cycle**. It SHARPENS the open `b_overflow_drain_cadence_gap` alert (`022d6490`, M4-owned, raised 2026-09-01) rather than being a new condition, so it is recorded here and in this run's decision row and **deliberately NOT re-alerted** — a second row for one standing condition is the alarm fatigue INCIDENT INHERITANCE exists to prevent. W2 proposes no fix: W4 §C assigns the router/window interaction to W5 and M1a.

---

## FINDINGS FOR D1 — one, upstream, not fixed here

**F1 — `screen_fields_schema_drift` has recurred in a new shape, two days after D1 closed the old one.** The prior cycle raised `a9013b97` for item rows carrying NULL `ticker` / `conviction_pct` / `market_cap_usd` / `qualifying_event_date`; D1 acted on it, wrote an explicit `schema_conformance_note` into its 2026-09-06 screen, and that alert is now **resolved** (2026-09-07 — so the prior file's "open" framing was accurate when written and is simply stale now). MEASURED on the five screens in this intake:

- the **2026-09-08** screen's `rejected_notable` array: **21 of 21** rows omit the `conviction_pct` and `below_spec_floor` keys *entirely* (not NULL — absent), **21 of 21** carry `qualifying_event_date = NULL`, and **11 of 21** carry `market_cap_usd = NULL`;
- the **2026-09-09** screen: **3 of 8 passed** rows and **7 of 9 rejected** rows carry `market_cap_usd = NULL` (the three passed ones disclosed via a `market_cap_note` string, which is honest but is still a NULL on the numeric field);
- the **2026-09-10** screen: clean at item level, but the top-level `degraded` key is **absent** where the other four rows carry it explicitly.

Two things make this worth filing rather than absorbing. First, it is **structurally different from the closed defect** — missing keys and nulled dates rather than drifted spellings — so a check written against the old shape would pass. Second, it is concentrated almost entirely in `rejected_notable`, which W2 does not rank from; the consumer it actually reaches is **W5's RESEARCH-SCREEN SCORECARD** via `state.research_screen_calls`, whose agreement counts are computed over both arms. Filed as an `ops.alerts` info row naming D1 as owner. **Not fixed here** — D1's screen-record schema is D1's surface, and this run has no authority over it.

The previous cycle's second D1 finding, `screen_move_no_disposition` (`ed5e2e24`, the BMNR 09-03 case), is **still open** and is not re-raised. Nothing in this intake bears on it either way.

---

## HONEST LIMITS OF THIS RUN

- **No candidate has been evaluated against criteria 2, 3 or 4.** Every rank is a magnitude ordering over items that passed criteria 1 and 5. It must not be read as a conviction ordering, and the prior-NO-GO flags on FICO, LULU, TSLA and INTC are context for a future full-depth pass, never a verdict reached here.
- **Three market-cap rail clearances are UNVERIFIED or PROVISIONAL** (TBBK, AEO, GPCR) and three more are cleared **by inspection rather than measured** in D1's own record (META, CASY, CMCSA). Resolving the first three requires the issuer's own filed share count, which is a metered path index mode does not spend.
- **The instrument-eligibility line decided one disposition again.** NVS is excluded as a depositary receipt; ROIV and GPCR are foreign-domiciled names admitted on the ONON / KLAR / CRDO / NU precedent. That precedent has never been written down (see the open question below).
- **Sub-pattern routing was not performed.** It is part of the criterion-4 step index mode skips. RDDT's exclusion cites SP6 by shape, not by a taxonomy walk.
- **The cohort findings are three cohorts in one regime, 59 names, not a base rate.** FINDING 3 in particular states a *direction* — the mean residual does not decay — over horizons of at most 15 sessions, on cohorts drawn from four consecutive weeks of a single acute-shock regime. It is evidence for a future divergence review to weigh, not a parameter to act on, and W2 claims no authority over B's machinery.
- **One panel observation is contaminated and is excluded, not smoothed:** HPE's 09-11 residual (393%) measures a new event, not the decay of its 09-03 one.
- **Per-name next-report and PDUFA dates are NOT established.** FINDING 5's claim that the FDA limb of criterion 3 is live for ROIV, GPCR and AMGN is a statement that the limb is *reachable in principle* for clinical-event names; whether a dated decision exists for any of the three is unestablished and is flagged as this file's highest-value outstanding fact.

---

## OPEN QUESTION CARRIED FORWARD FOR THE OWNER — the ADR / ordinary-share line, fifth consecutive cycle

`strategy/04_strategy_b.md` says only **"US-listed common equity"**. It does not distinguish a foreign issuer's US-listed *ordinary or common shares* from a *depositary receipt* over shares trading primarily elsewhere. That unwritten distinction decided real dispositions again this week: **NVS excluded** (Swiss issuer, depositary receipt, −13.93% on a double clinical failure — a large, cleanly attributed move that would otherwise rank 10th), while **ROIV** and **GPCR** are admitted as US-listed shares of foreign-domiciled issuers on the same precedent that admitted ONON, KLAR, CRDO and NU and excluded BABA, FUTU, ARGX, JD, AZN and NVO.

The test has now held five cycles and has never been written down, so every session re-derives it from precedent. Note also that the obvious mechanical proxy does **not** work: the 20-F filing form is not a usable diagnostic, since both the excluded ARGX and the admitted ONON file 20-F as foreign private issuers.

Pinning it is a `Strategy.md` change, and Strategy B's machinery is spec-locked and immutable for the strategy's life, so it is an **owner or SL-path decision** and not one W2 may make.

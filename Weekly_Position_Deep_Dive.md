2026-W39

# W3 — Open-Position Deep-Dive (Strategies A, B, C, E)

**Run:** Sunday 2026-09-27 · **Evidence window:** 2026-09-20 09:18:48 UTC → 2026-09-27 09:09 UTC (this routine's own last `completed` run → now; `state.routine_catchup_window` `window_days = 6.99`, `never_completed` FALSE, cadence-normal against the 10.5-day 1.5× weekly bar — no missed period, no catch-up sub-section owed, no `CATCHUP` token).

**NO `WEEKLY-THESIS-ACTION` FLAG.** No hold / weekly-thesis-action / further-research recommendation is issued, because there is no open in-scope position to issue one on. No `immediate_action_flagged` alert is owed and none is raised.

**Marker.** `2026-W39` is the plain ISO week of the run date (Sun 2026-09-27 is day 7 of the Mon 09-21 → Sun 09-27 week). W1 (`96d42f1`) and W2 (`32c0e92`) both stamped `2026-W39` earlier today, so all three weekly files agree and W4's upstream-freshness read matches.

**Scope, derived not assumed.** In-scope = roster-active strategies with `review_cadence: reactive`. Read this run from `strategy/roster.yaml` and `state.strategy_roster` (all five of A–E `ADOPTED` / `is_active`; `reactive` for A, B, C, E; `long_horizon` for D). So the set is **A, B, C, E** — unchanged, and no SISA graduate has been registered that would widen it. D's 12 open tranches belong to M3's monthly deep-dive and are untouched here.

---

## HEADLINE — the price leg came the closest it has ever come to firing, a four-day blockade took it back out, and the target did not move

`state.current_positions` returns **12 open rows and all 12 are Strategy D**. A, B, C and E hold nothing. That is the **sixth** consecutive weekly cycle with an empty in-scope book, and Steps 1, 2, 3, 5 and 6 are vacuous in consequence — stated at the bottom rather than silently dropped.

Step 4 is not vacuous, and this was the most eventful week of the acute run on both of the axes that gate every in-scope strategy.

| | 2026-09-20 W3 reading | 2026-09-27 W3 reading | direction |
|---|---|---|---|
| Brent peak (running max since acute-run start) | 108.75 (09-15) | **108.75 (09-15)** | **unchanged — no ratchet** |
| Retrace trigger (baseline + 50% of elevation) | 96.74 | **96.74** | **unchanged** |
| Brent, warehouse last held session | 104.82 (09-17) | **106.60 (09-24)** | rose |
| Brent, last trading session (externally sourced) | 103.87 (09-18) | **104.32 (09-25)** | +0.43% |
| Further decline required for leg (ii), on the external session | −6.86% | **−7.27%** | slightly further |
| Best point reached inside the week | — | **98.53 close (09-22), −1.82% from clearing** | **closest of the entire run** |
| Leg (i) quiet-clock anchor | 2026-09-15 (contested) | **2026-09-23** (W1, this cycle) | **reset by a new event** |
| Earliest date leg (i) can pass | 2026-10-06 | **2026-10-14** | **further** |
| `leg_c_technical` | TRUE | **FALSE** | **flipped** |

**Three things are new in kind, not merely in degree.**

**1. The price leg came within 1.79 points of clearing, and then a new supply event undid it — but the target did not move.** On **2026-09-22** Brent closed **98.53** against a trigger of **96.74**: a further **−1.82%** would have satisfied leg (ii) outright, and **42.55%** of the required 50% retracement had been achieved. That is by a wide margin the closest the price leg has come in the whole acute run (best prior reading: 20.32% last cycle). The Libyan El Sharara blockade then reversed it — 103.08 on 09-23, 106.60 on 09-24 — and the required decline widened to −9.25% on the warehouse's own last session.

**The consequential detail is what did *not* happen.** The rally topped at a **106.60** close, **2.15 below the 108.75 peak — it stopped 1.98% short of re-ratcheting the trigger.** Contrast 2026-09-15, when a new high lifted the trigger 96.18 → 96.74 and permanently consumed 0.56 of the prior decline. Last cycle's file established the ratchet as the operative mechanic and predicted it would keep eating progress; **this is the first cycle of the run in which a major up-move did not trigger it at all.** The whole of this week's setback is therefore recoverable by price alone, which is a structurally different kind of setback from the 09-15 one. That distinction is invisible to any single daily run and is the clearest instance this cycle of what W3 is for.

**2. `leg_c_technical` flipped TRUE → FALSE, and it flipped on the exact axis this routine flagged as a 0.09pp near-miss one week ago.** Equity breadth went `HEALTHY` → `WEAK` and has fallen every session since. The re-risking limb went from 2 of 3 legs armed to **1 of 3** (`leg_a_dwell` TRUE; `leg_b_price_leg` FALSE; `leg_c_technical` FALSE). Detail and the self-correction it forces are in §4b.

**3. An owner withdrawal of roughly $2,700 left the book on 2026-09-23, and it came out of the capital this routine has called "stranded" for five cycles.** It was detected within one session by three independent tripwires and adjudicated correctly. What it demonstrates is not a fault but an asymmetry — E's idle balance is an *eligible source for a withdrawal* and an *ineligible source for a Strategy C borrow*, and the discriminating term is a single SQL predicate. §4d.

Nothing in this file scores or re-scores any regime axis.

---

## THE EMPTY BOOK, RE-ESTABLISHED INDEPENDENTLY

Measured this run, not carried forward from the prior file:

- `state.current_positions`: 12 rows, strategy `D` on all 12 (AMZN ×2, DIS ×2, GOOGL ×2, TSM ×2, GEV, ISRG, RTX, UBER).
- `events.position_events` across **all** recorded history returns exactly two strategies: **B** (41 events, 2026-04-27 → 2026-08-18) and **D** (34 events, 2026-04-27 → 2026-09-14). **A, C and E have never produced a single position event.**
- B's last event is the terminal `CLOSE` of `B:MSCI:2026-07-27` on **2026-08-18**. Counted against `state.market_calendar` this run, B has been flat **40 calendar days / 27 trading days** — last week's 33/22 advanced by exactly seven calendar and five trading days, not a restatement.

**The caveat that has not stopped being true.** An "empty book" verdict on A, C and E is weaker in kind than the same verdict on B: A, C and E have *never opened a position*, whereas B genuinely went flat. Saying "no thesis drifted this week" about a strategy that has never held a thesis is not a finding about that strategy's health.

### Why the book is empty — the causes, re-measured from `state.strategy_capital_enablement` and `state.rerisking_limb_status`

| Strategy | Activation | Capital | NAV | Binding cause today |
|---|---|---|---|---|
| **A** | `DO-NOT-ACTIVATE` | disabled | $0.00 | Universal `shock_overlay = acute` override. W1 re-derives the router gate at **2026-11-02**, third consecutive cycle. |
| **B** | `DO-NOT-ACTIVATE` | disabled | $0.00 | Same override. 5th consecutive INDEX-MODE cycle (W2). |
| **C** | `HYBRID ACTIVATE (FOMC-only)` | **enabled** | **$19.49** | The only open door. Blocked by affordability, and the bind tightened this week — see the C section. |
| **E** | `DO-NOT-ACTIVATE` | disabled | **$12,672.77** | Same override, adjudicated on the merits for E on 2026-09-03 (`div-E-202608-1`). Holds **95.70%** of the book's $13,241.55 total NAV, idle. |

All five `state.rerisking_limb_status` rows carry identical leg values and differ only in `activation_state`; `sql_limbs_fired` is FALSE for every strategy.

---

## STEP 4 — SECTOR AND MACRO CONTEXT (the only step with in-scope content)

### 4a. The shock overlay, measured against its own published exit

The rubric is `strategy/09_regime_scoring_strategy_blind_monthly.md` §Shock / overlay grading rubric (Rev 48, 2026-09-05, owner directive). **The file took zero commits inside this window** (`git log --since=2026-09-20` on both it and `Strategy.md`: none), so it is unchanged and simply being measured against. Verbatim:

> **De-escalation from `acute` to `latent` is REQUIRED, not optional, once both legs hold.** Downgrade when BOTH are true, each dated and measured in the row rationale: **(i) zero new qualifying events for 15 consecutive trading days; and (ii) Brent has retraced at least 50% of the shock elevation, i.e. it now sits at or below the baseline-to-peak midpoint.** Either leg failing keeps the grade at `acute`.

#### Leg (ii) — FAILS, after the nearest miss of the run

Read from `state.rerisking_limb_status` (`bigquery/224`, itself uncommitted this window), all five terms identical across every strategy row:

- `brent_baseline` **84.73** — median of the 60-trading-day window strictly before the acute run start (**43 observations**, 2026-06-01 → 2026-07-31; the series begins 2026-06-01, so the short window is by construction, not by fault, and the rubric requires N be stated)
- `brent_peak` **108.75**, set **2026-09-15** — **unchanged from last cycle**
- `brent_retrace_trigger` **96.74** = `84.73 + 0.5 × (108.75 − 84.73)` — reproduced by hand, matches the view exactly
- `brent_current` **106.60**, `brent_as_of` **2026-09-24**
- `leg_b_basis` **`not_retraced`**, `leg_b_price_leg` **FALSE**

The path this week, from `state.signal_marks_curated` (`BZUSD`; the curated view, never the raw table, per the rubric's own SOURCE TRAP pin):

```
09-17 104.82
09-18 103.87   ← last cycle's externally-sourced figure; now ingested, EXACT match
09-21 100.34
09-22  98.53   ← run's nearest approach: 1.79 above the 96.74 trigger, −1.82% from clearing
09-23 103.08   ← Libya El Sharara blockade, +4.62%
09-24 106.60   ← +3.42%; highest close since the 09-15 peak, and 2.15 BELOW it
09-25 104.32   ← EXTERNALLY SOURCED (see Coverage); warehouse does not hold it
```

**Required decline for leg (ii):** **−7.27%** on Friday's externally-sourced close, **−9.25%** on the warehouse's own last held session. Last cycle the comparable figures were −6.86% and −7.71%. **Like for like against the last externally-known session, Brent is essentially where it was seven days ago — 103.87 then, 104.32 now, +0.43% — and the entire week's drama is in the path, not the endpoint.**

Retracement achieved, against the 50% required: **42.55%** at the 09-22 close, **8.95%** at the warehouse's 09-24, **18.44%** at Friday's 104.32. (Last cycle's best was 20.32%.)

**Why the non-ratchet is the load-bearing fact and not a technicality.** Because the trigger is defined off a *running maximum*, an up-move that sets a new high raises the bar permanently, while an up-move that does not is pure price and fully reversible. This week's +8.19% two-session rally was the second kind. Had it closed 2.16 higher on 09-24, the trigger would have ratcheted to ≈96.68 + the elevation increment and part of the 09-22 progress would have been destroyed rather than merely given back. **It did not, so leg (ii)'s distance today is a price statement and nothing more.** Stating this is also the return-path check on last cycle's prediction that "every new high raises the retracement target": the mechanic is real, and this is the first cycle in which it was *not* triggered — which is evidence for the mechanic's description, not against it.

**One measurement note, reconciling a small difference with W1.** W1 reports the 09-22 approach as **1.85%** and this file as **−1.82%**. Both are right and they measure different things: 1.79 / 96.74 = 1.85% expresses the gap as a fraction of the *trigger*; 1.79 / 98.53 = 1.82% is the *decline from spot* that leg (ii) actually required. The second is the figure comparable to the −7.27% / −9.25% quoted above, so this file uses it. No disagreement, and neither number is in error.

#### Leg (i) — FAILS, and the anchor moved again, for the second time in three cycles

**The clock reset to 2026-09-23.** W1 2026-W39 (`events.decision_log` `4e7da75e`, this morning) adjudicated the **armed-group blockade of Libya's El Sharara field** — roughly a third of Libyan output — together with a White-House-backed proposal to ban US diesel exports, as a qualifying shock-cluster member, superseding 2026-09-15 as the anchor. D1's 09-23 sector screen (`e01d9ca6`) recorded the same event as that session's driver, with XLE the sole gaining GICS sector at +0.9550%.

**W3's addition is to test that call against the rubric's own written inclusion criteria, which neither D1 nor W1 quoted — and the test both confirms the conclusion and undercuts the ground W1 led with.** The rubric defines a qualifying event as a dated development that (i) meets input category 4's criteria — *an effect on global trade flows, an oil price move > $5/bbl attributable to the shock channel, a widening in sovereign credit spreads, or a major currency move > 2% against USD* — **and** (ii) is attributable to a named geopolitical or trade channel.

- **W1's first stated ground was the size of the crude move.** On the rubric's per-session reading that ground **fails**: Brent moved 98.53 → 103.08 on 09-23, **+4.55/bbl — below the $5/bbl test.** It clears $5 only by aggregating 09-23 and 09-24 into one +8.07/bbl move, and the rubric states no measurement window for that test.
- **The event qualifies anyway, on a leg W1 did not cite.** A blockade of ~⅓ of a producer's output is plainly "an effect on global trade flows," which is an independent alternative in category 4 and needs no price arithmetic at all. Limb (ii) is satisfied twice over: a Libyan armed-group blockade is a named geopolitical channel and a US diesel-export-ban proposal is a named trade channel.

**So the conclusion holds and the reasoning should be the trade-flows leg, not the price leg.** Recorded because a future run re-deriving this from W1's prose would inherit the weaker argument.

**2026-09-24 correctly does NOT qualify, and the rubric says so directly.** Daily.md's 09-24 entry attributes that session's ~+3.6% to US–Iran escalation (a UN-podium threat; reports of Iran downing US drones) and W1 treats it as follow-through. Against the rubric: the crude move was **+3.52/bbl, below $5**; no physical flow disruption was reported; and the rubric excludes "narrative escalation with no measurable leg … regardless of salience." W1's judgement was reached on framing; the rubric reaches it on the test. They agree.

**Where that puts the clock**, measured directly against `state.market_calendar` this run:

| candidate anchor | 15th quiet trading day | position of the 2026-10-01 M1a scoring |
|---|---|---|
| 2026-09-11 (external dating of the Saudi shutdown) | 2026-10-02 | 14th of 15 — fails |
| 2026-09-15 (D1's record; last cycle's published anchor) | 2026-10-06 | 12th of 15 — fails |
| **2026-09-23 (W1, live this cycle)** | **2026-10-14** | **6th of 15 — fails** |

**Leg (i) fails at the 2026-10-01 scoring under every candidate anchor, and leg (ii) fails by 7.27%, so the overlay stays `acute` under every reading available.** The first scheduled scoring at which leg (i) *could* pass is **2026-11-02** — which is also the router gate W1 published, for the third consecutive cycle. The gate is therefore unchanged and `Weekly_Catalyst_Calendar.md` needs no correction.

**Last week's filed anchor discrepancy went moot inside one cycle — and not because anyone settled it.** `6081d304` (filed by this routine 2026-09-20) recorded that the rubric has no written rule for dating a qualifying event, and that 09-11 and 09-15 were two trading days apart. Leg (i) turns only on the *most recent* qualifying event, so 09-23 supersedes both and the 09-11-vs-09-15 dispute is now unreachable. **That is supersession, not resolution, and it is the strongest evidence yet that the gap is worth closing:** the dispute did not go away, it recurred on the very next event, and it recurred on a bigger scale. The live ambiguity today — does 09-23 qualify? — separates **2026-10-06 from 2026-10-14, a six-trading-day window**, against two trading days last cycle. No scheduled M1a/M1b falls inside it. An **M1R out-of-cycle re-score, which fires on a limb rather than on a calendar, does fall inside it**, and would be decided by which surface it happened to read. See **FILED THIS RUN**.

**The blockade is already over, and the rubric's asymmetry is doing exactly what it was written to do.** Externally sourced (no internal routine has observed the weekend): the El Sharara valve was **reopened the evening of 2026-09-26** and Libya's NOC reported crude pumping resumed; the NOC warned twice that it "may be compelled to declare force majeure" but **no source confirms a declaration was made**. Separately, UNSMIL warned on **2026-09-26** that disruption of Libyan oil infrastructure "may constitute grounds for sanctions." **Neither is a new qualifying event**: a reopening is de-escalation, and a warning of possible future sanctions is not a sanction and carries no measurable leg. So a four-day blockade, already resolved, buys a fifteen-trading-day quiet clock running to 2026-10-14. **That is the rubric's "fast to raise and slow to lower" asymmetry operating as designed — it is stated in the rubric as a deliberate choice — and it is recorded here so a later run does not mistake it for a defect.** The UNSMIL judgement is recorded so a later run can overturn it on better sourcing rather than re-derive it.

### 4b. The technical plane flipped — on the exact axis this routine flagged one week ago, and the "recovery" this file reported never happened

Re-established from `events.regime_events` (`scope='TECHNICAL_SIGNAL'`), latest reading **2026-09-24**:

| Axis | Value (2026-09-24) | Label | Margin |
|---|---|---|---|
| `VIX_REGIME` | 15.67 | `NORMAL` | 9.33 below the `HIGH` line at 25 |
| `SPY_TREND` | 767.18 vs 50dma 761.1532, 200dma 718.0134 | `UP` | +0.792% above the 50dma |
| `EQUITY_BREADTH` | **45.12** | **`WEAK`** | **4.88pp BELOW the 50 line** |

`leg_c_technical` reads **FALSE** on the single failing conjunct.

**Last week this file reported the breadth slide as a near-miss that recovered. It did not recover, and the sentence was wrong at the moment it was written.** The full series:

```
09-14 56.26 HEALTHY
09-15 52.88 HEALTHY
09-16 50.09 HEALTHY   ← last week's "0.09pp near-miss"
09-17 51.09 HEALTHY   ← last week's latest reading; the file called this a recovery
09-18 49.50 WEAK      ← the flip. Session traded 09-18; ingested by D2a AFTER W3 wrote on 09-20
09-21 49.50 WEAK
09-22 49.70 WEAK
09-23 47.71 WEAK
09-24 45.12 WEAK
```

Last week's file said the chain "stopped 0.09pp short of mattering, then recovered." **By the time that was written the 09-18 session had already closed at 49.50 — below the line — and the warehouse simply had not ingested it yet** (`marks_due_through` was 2026-09-17 against a `last_trading_day` of 2026-09-18, a fact that file stated correctly on three other series and did not extend to breadth, because it had no 09-18 breadth figure at all and correctly claimed none). So the *finding* — that this was the class of slow-burn cumulative fact W3 exists to surface — was vindicated one session later. The *reassurance attached to it* was an artifact of ingest lag, not of the tape. **Both halves are stated because reporting only the vindication would be the more flattering half and the less useful one.**

**This is also the concrete case for the W3 spec's own "externally source the unobserved session" carve-out, and the case that the carve-out was applied too narrowly.** Last week's run externally sourced Brent, VIX and SPY for 09-18 and did not source breadth. Had it done so the flip would have been caught on the day it happened rather than six days later. Breadth is a Barchart `$S5TH` read (`events.regime_events` `scope='TECHNICAL_INPUT'`), i.e. externally sourceable in principle — but it is also the one input that can flip a leg on a threshold, which makes it the *most* consequential of the four, not the least. **This run does not source it for 09-25 either** — see Coverage for why that is an honest limit rather than a repeat.

**An apparent contradiction worth one line, because it looks alarming and is not.** The same breadth series that reads `WEAK` to the regime vocabulary at a threshold of 50 read `DEFENSIVE` to the park allocator v4 at a threshold of 66 throughout — including while it was labelled `HEALTHY`. Two consumers, two thresholds, one measurement. This is why the park's 2026-09-23 call could record "three axes standing defensive" and "zero axes entering" in the same breath: breadth had been park-defensive for weeks, so the regime-vocabulary flip produced no park *transition*. Not a disagreement and not a defect.

**VIX confirms an inference last week labelled as one.** Last week's file wrote that the externally-sourced 09-18 close of 14.81 "would score `LOW` for the first time in this episode … INFERRED from an externally-sourced close applied to a published threshold, not measured by the warehouse, and D2a owns the label." The warehouse now holds **09-18 `LOW` 14.81** — the inference was correct, correctly labelled, and is now confirmed. The episode ran three sessions (09-18 14.81 `LOW`, 09-21 14.87 `LOW`, 09-22 14.21 `LOW`) before returning to `NORMAL` on 09-23 (15.18) and 09-24 (15.67). `VIX_REGIME` carries a same-day correction row on 09-21, explicitly self-tagged as superseding that run's own earlier row at the identical value 14.87 — a metadata correction, not a value change.

### 4c. Rates, not crude, drove the equity tape — and the two moved together, which is what `acute` asserts

From `events.regime_events` `scope='TECHNICAL_INPUT'` (`TREASURY_10Y`, FMP treasury-rates year10):

```
09-18 5.01   09-21 4.96   09-22 4.96   09-23 5.11   09-24 5.18
```

**+22bp across 09-22 → 09-24, coincident with the crude rally**, and Friday's externally-sourced 10Y is 5.17 with the 2Y at 4.81. D1's own screens read the same tape independently: 09-23's single-name run concluded "a rates shock explains almost all of it," and 09-24 recorded materials falling on a session when Brent rose ~3.6% and XLE rose +0.3688% — a rate-driven de-rating overwhelming a commodity tailwind.

**That co-movement is the transmission leg the `acute` grade asserts, and it is worth naming because it is the thing that actually argues for the grade.** Leg (ii) is a price test and leg (i) is a recency test; neither of them measures whether the shock is still *propagating*. The long end backing up 22bp alongside an oil supply event is a measurable market leg still pricing the named channel, which is precisely the rubric's `acute` transmission condition. No scoring act is performed here; this is evidence offered for the one whose job it is.

SPY finished the week at **771.35** (externally sourced), up from 761.69 on 09-18 — **+1.27%** — having traded 773.50 / 773.38 / 767.81 / 767.18 through Monday–Thursday. So the index rose on the week while breadth fell 49.50 → 45.12: **the advance narrowed materially, which is exactly the divergence the breadth axis exists to detect**, and it is the mechanism behind the `leg_c_technical` flip rather than an unrelated coincidence.

**Market-implied odds for the 2026-10-28 FOMC** shifted toward a second consecutive hike during the week: one cleanly dated source (Investing.com Fed Rate Monitor, reading stamped 2026-09-21) moved from 45.2% hike / 49.6% hold a week earlier to **59.7% hike / 40.3% hold**. Two other aggregators were checked; one could not be parsed unambiguously and one is internally inconsistent with the confirmed 09-16 hike and is **not relied on**. Recorded as single-sourced-and-dated, and it matters only through Strategy C — see below.

**Not obtained, stated rather than omitted:** XLE's weekly return (the FMP account's plan tier denies chart access for that symbol on two endpoints — two calls spent, no data), and the actual prints-versus-consensus for the week's jobless claims, durable goods and consumer confidence. The next PCE report and the Q2 GDP third estimate are both scheduled **2026-09-30**, outside this window. No finding in this file rests on either gap.

### 4d. The book lost ~$2,700 to an owner withdrawal, and it exposed an asymmetry in the capital rail

**What happened, from the alert records rather than from inference.** `state.book_drawdown_watch` and four D2a/D1 alerts, all raised 2026-09-21 → 09-24, all now **resolved** except one:

- `unregistered_park_liquidation` (D2a, `e3d3b4f1`, 09-21): two live working park-vehicle SELL orders at IBKR "with no staged-order registry row and no crafted instruction."
- `park_unexplained_liquidation` (D1, `5c04fcb8`, 09-22): "Park sleeves were liquidated pro-rata at the 2026-09-22 open by orders NO routine in this system staged."
- `large_market_move` (D2a, `b608c947`, 09-24): "Day-over-day NAV moved −17.57% (prior_nav 15916.57 → today_nlv 13119.86, −2796.71) … but the MARKET-MOVE TERM residual is only **0.35 against a 318.33 tolerance**, so this is NOT connector corruption: it is an external WITHDRAWAL of ~2700.00 (candidate wd-2026-09-23, first pass) plus −89.46 park and −6.79 equity mark-to-market."
- `book_drawdown_soft_breach` (D2a, `c04e9c6b`, 09-24): D2 new-entry staging paused.

**The system got this right and the record should say so plainly.** A −17.57% overnight NAV move is exactly the shape of a connector-corruption incident, and the residual arithmetic distinguished a genuine cash withdrawal from a bad feed within one session, without halting. **The soft breach has since cleared**: `state.book_drawdown_watch` as of 2026-09-24 reads `current_nav` 13,096.90, `peak_nav` 13,519.78, `capital_base` 13,217.25, `drawdown_from_peak` **−3.1995%**, and `breach_soft` / `breach_hard` / `drawdown_breach` all **FALSE**. So D2 new-entry staging is **not** currently paused — a reader coming to the 09-24 alert cold would reasonably assume otherwise.

**The part that is W3's to carry.** For five cycles this routine has described E's balance as stranded, idle and safe — last week's words were "Nothing moves, which is the safe outcome." **That characterization is now incomplete, and the withdrawal is what makes it so.** Measured from two governing surfaces this run:

- `state.withdrawal_capacity`: **E `is_donor` TRUE, cap $12,672.77**, `capital_disabled` **TRUE**; C `is_donor` TRUE, cap $19.49; A and B excluded for "no idle cash"; D "bears a share by NAV but holds no idle cash — clamps to zero". `total_donor_capacity` **$12,692.26**.
- `state.nomadic_borrow_capacity_watch`: borrower **C**, `donor_capacity_total` **0**, `donor_count` **0**, `borrow_blocked` **TRUE**.

**Those two rows are not in conflict, and the single term that separates them is `capital_enabled`.** The borrow view requires a donor to be capital-enabled (`WHERE e.capital_enabled`, `bigquery/246` and its dbt twin `dbt/models/state/nomadic_borrow_capacity_watch.sql`); the withdrawal view carries no such predicate and lists E as a donor while reporting `capital_disabled` TRUE in the adjacent column. Both are correct for their own purpose — you can withdraw a disabled strategy's idle cash; you should not let a disabled strategy underwrite an active one's risk.

**But the consequence, stated at its true weight: the same $12,672.77 can leave the book and cannot cross to the only strategy permitted to trade.** Until this week that was a theoretical asymmetry. On 2026-09-23 it was exercised, in the direction that shrinks the pool: ~$2,700 — **17.5% of E's balance** — went out the withdrawal door, while C's reachable capital over the same week fell $23.64 → $19.49 and its borrow channel read zero donors throughout. The pool is not merely idle; it is the pool the owner draws from, and it is the pool C cannot reach.

**W3 adjudicates none of this and proposes no change.** It is D2a's and the capital rail's surface, the live condition is already instrumented by `nomadic_borrow_blocked` (`71d484fa`, D2a, 2026-09-23, **open**) and `regime_sweep_blocked` (`b40cb3e6`, D2a, 2026-09-06, **open**), and the four incident alerts are resolved. **Do NOT re-file any of them.**

---

## STRATEGY C — the two binds moved in opposite directions, and the binding one is now unambiguously capital

**What already happened, terminal and not to be re-opened.** `thesis-FOMC-C-20260908` was drained **NO-GO by D2 on 2026-09-08** — the sixth consecutive criterion-failure in the C-FOMC series per the live queue payload, which also records that **Strategy C has never deployed capital**. W4 correctly declined to re-mint the 2026-09-16 FOMC. No routine evaluated a fresh C opportunity around the hike, and none should have.

**The live item, which W3 must not duplicate.** `thesis-FOMC-C-20261020` sits `pending` on `PENDING_ANALYSIS`, due **2026-10-20**, for the **2026-10-28** decision. **D2 owns the GO/NO-GO.**

**W1's measurements this cycle** (SPY, 2026-10-30 expiry, ATM strike 771 against a 771.35 spot):

| | 2026-09-20 cycle | 2026-09-27 cycle | direction |
|---|---|---|---|
| Reachable capital | $23.64 | **$19.49** | **−17.6%** |
| ATM straddle cost | $26.96 /share | **$2,458 /contract** (≈126× reachable capital) | — |
| Implied vol | 12.84% | **12.7813%** | flat |
| IV / HV30 (the spec window) | 1.47 | **1.309** | **cheaper** |
| IV / HV20 | 1.40 | **1.188** | **cheaper** |
| IV / HV10 | — | **1.080** | near fair |
| Realized-vol term structure | — | **HV10 11.83 > HV20 10.76 > HV30 9.76 — INVERTED** | realized vol rising |

**W3's slow-burn addition, and it is a change in which constraint binds.** Last cycle this file argued the affordability bind was tightening while the September drain's one C-favourable factor (two-sidedness in the rate decision) had disappeared. This cycle the two binds **moved in opposite directions**:

- **The pricing bind loosened.** Implied is still rich to realized on every window, but the premium collapsed from 1.47 to 1.309 on the spec window and sits at **1.080 at the ten-day horizon** — within 8% of fair. Realized vol is rising *into* implied, which is the term structure that precedes a genuinely fairly-priced event.
- **The capital bind tightened, on both ends at once.** Reachable capital fell 17.6% to $19.49; the borrow channel that could supplement it read `donor_capacity_total` 0 and `donor_count` 0 all week (`71d484fa`, open since 09-23); and W1's own correction this morning (`5f7dd45c`) establishes that C's affordability is bounded by the blocked borrow, not by on-book NAV.

**The conclusion that follows, and it is the sharpest thing this file can hand to D2's 2026-10-20 pass: Strategy C cannot be unblocked by the vol surface improving.** A straddle at $2,458 against $19.49 of reachable capital fails by a factor of 126, and would fail by a factor of ~96 even if implied collapsed to realized. The constraint is not that options are expensive; it is that the strategy has nineteen dollars. That distinction was arguable while IV/HV sat at 1.47 — a richness argument could plausibly have been the binding one. At 1.080 it is not arguable any more. **This is context for D2 and nothing else: W3 crafts nothing, enqueues nothing, adjudicates nothing, and does not pre-empt that decision.**

**One correction to this file's own prior characterization of the entry criteria, made from the governing surface.** Last cycle this file wrote that "Criterion 2 requires an *affirmative, sourced, quantified divergence from market pricing*." Read from `strategy/05_strategy_c.md` §Entry criteria, criterion 2 requires a directional thesis **synthesized from four named source classes** (last 4 earnings transcripts, last 10-Q and 10-K, retrieved sell-side synthesis, sector peer context), *retrieved not recalled*, and **reconstructible from primary public sources** without leaning on analyst-laundered private-information-class signals. The divergence-from-options-pricing framing belongs to the strategy's **edge statement**, not to criterion 2. The looser paraphrase happens to point the same way for a rate event, but it is not what the criterion says, and a future run reasoning from it would be reasoning from this file rather than from the slice.

**The macro read-through, held at its true weight.** Market-implied odds moving to ~60% for an October hike (§4c) further reduces two-sidedness relative to the 56/44 split that made September "genuinely two-sided for the first time." That compounds the direction last cycle identified. It is, however, now the *second*-order problem: a thesis that cleared every criterion would still be unaffordable.

---

## STRATEGIES A, B AND E — no position, no thesis, and what did happen

- **A.** Router `DO-NOT-ACTIVATE`, 6th consecutive cycle; capital-disabled; NAV $0.00. W1 re-derived the gate at **2026-11-02** for the third cycle running. Its top-10 shortlist this cycle (TTWO, NVDA, VRTX, FSLR, CAT, XOM, AVGO, CVX, CSCO, AMD) carries **XOM and CVX as `SPENT-BY-GATE` despite rising conviction** — both on the supply-shock seam. W1's strongest new theses of the cycle (DAL/UAL/AAL/CCL, bearish on the oil and diesel shock) remain **DIRECTION-INADMISSIBLE** under A's long-only rail for a third cycle, and W1 notes they route to B — where B's router also reads `DO-NOT-ACTIVATE`, "so the idea is carried and acted on nowhere." That is a structural decline, not a discretionary one, and it is now the third consecutive cycle in which the shock that blocks A is also the source of A's best available ideas.
- **B.** Router `DO-NOT-ACTIVATE`, 5th consecutive INDEX-MODE cycle; NAV $0.00; flat 40 calendar / 27 trading days. W2 ranked **15 names at the cap** and routed all to Watchlist.md under `Router-gated, not rank-gated.` W2's own new observation is worth carrying: this is **the first cycle in which the scheduled router-flip path (M1a/M1b/M4, all firing 2026-10-01) lands inside 12 of 15 candidate windows** — previously every cohort expired before any reachable flip. Two re-screens are open and due today (`rescreen-IONQ-B-20260927`, `rescreen-ORCL-B-20260927`); D2 owns them. W2 also filed `d1_below_spec_floor_contradicts_own_anchor_prose` (`62775339`, info, 2026-09-27) — its surface, not re-flagged here. **None of it touches a position, because B has none.**
- **E.** `DO-NOT-ACTIVATE`, capital-disabled since 2026-09-04. **No `events.decision_log` row names strategy E anywhere in this window** — no pair surfaced, none was declined, nothing was evaluated. E's entire footprint this cycle is its balance sheet, covered in §4d.
- **E's idle capital remains the book's dominant fact and is already instrumented.** `state.regime_capital_sync_pending` still returns exactly one row — `SWEEP / E / 12672.77 / counterparty NULL / blocked_no_recipient TRUE / blocked_reason 'no_eligible_recipient'`. **95.70%** of the book's $13,241.55 NAV sits behind a deactivated strategy with nowhere to go. `regime_sweep_blocked` (`b40cb3e6`, D2a, 2026-09-06) is open and owned. **Do NOT re-file.**

---

## CORRECTING THIS ROUTINE'S OWN PRIOR FILE

Per the MEASURE-FROM-THE-GOVERNING-SURFACE rule, every quantity restated here was re-read from the surface that owns it. Four corrections, two confirmations, one vindication with a caveat.

1. **"A three-session slide that stopped 0.09pp short of mattering, then recovered" — WRONG, and the correction is §4b's subject.** Breadth broke through on 09-18 and has fallen every session since to 45.12. The session had already traded when that sentence was written; the warehouse had not ingested it. The finding was right and the reassurance was an ingest-lag artifact.
2. **"Externally the 10Y was still ~4.94% at Friday's close" — WRONG by 7bp, and wrong in the same shape three other routines got caught on this week.** The warehouse holds **5.01** for 2026-09-18; 4.94 is the **09-17** value. That is last week's run quoting the prior session's print as the current one — precisely the error D2 filed against D1's park call (`9ce935ae`, `park_call_brent_day_move_self_contradictory`) and W1 filed against D1's Brent prose (`4d135348`, `d1_brent_prose_quotes_prior_session_settle`) inside this same window. **Three routines, one window, one error shape, and this file is the third.** Both D1 instances are already filed by their finders; this one is corrected here and is not a fourth filing.
3. **"96.4% / 96.44% of book NAV stranded behind E" → 95.70%**, re-measured from `state.withdrawal_capacity` `nav_share` (12,672.77 / 13,241.55). The *share* barely moved; the *pool* fell $2,695.62 on a withdrawal. Reporting only the percentage would have hidden the entire event, which is why §4d states the dollars.
4. **"E holds $15,368.39" → $12,672.77** and **"the book's $15,936.22 total NAV" → $13,241.55.** Not this routine's error — both were correct on their date — but stated as a correction rather than a silent substitution, because the delta is the finding.
5. **CONFIRMED: last week's three externally-sourced 09-18 closes were exact.** Brent 103.87, VIX 14.81 and SPY 761.69 all match the warehouse's subsequently-ingested values to the digit, and the VIX `LOW` label the file *inferred* and labelled as an inference is the label D2a wrote. **Three for three.** That is evidence about a *procedure*, not just three numbers, and it is why this run sources 09-25 the same way.
6. **CONFIRMED: the 09-04 Brent restatement hazard did not recur, for a second consecutive window.** `events.signal_marks` queried directly for every `BZUSD` row with `mark_date >= 2026-09-15`: **eight dates, eight rows, exactly one per date, no duplicates.** The hazard filed as `82c99515` is real and remains open; it did not fire. Stating the negative result matters as much as the positive one — a filed finding that quietly stops recurring looks identical to one nobody checked.
7. **Last cycle's trigger of 96.74 is re-verified and did NOT move.** `84.73 + 0.5 × (108.75 − 84.73) = 96.74` reproduces exactly against an unchanged peak. Last cycle this file predicted the ratchet would keep raising it; this cycle it did not fire, and §4a explains why that confirms the mechanic rather than contradicting it.

---

## COVERAGE STATED HONESTLY

**D1 coverage is complete for the window, with one degraded day and one genuine gap on adjacent routines.** D1 logged `completed` on **2026-09-20, 09-21, 09-22, 09-23 and 09-24** — the full `daily_sun_thu` set. The **09-21 fire ran degraded** (BigQuery de-authed mid-run; commit `a922a89`, decision_log `a922a89`), and that day's `add-candidate-review` records all 12 D tranches `declined_hard_gate` on an unreadable `invalidation_status` rather than on the merits. **D2, D2a and D3 have no completed row for 2026-09-21** — D3 halted on its D2 gate, AR_orc halted on its AR_att dependency, and D2 for 09-21 was caught up pre-open on 09-22 (`e8fb3657`, converting the 09-21 Daily.md). OPS0 failed on 09-20 and D3 ran its STEP 1+2 inline as fallback the same day (`81d8203e`). **None of it touches an in-scope position, because there are none** — but it is the reason this window's alert count moved the way it did, and saying so is cheaper than leaving a reader to reconstruct it.

D1's daily invalidation sweep evaluated the D book on every scanned day — "12 tranches evaluated, 0 flagged" on 09-20, 09-22, 09-23 and 09-24 — which is M3's surface, not this one.

**Friday 2026-09-25 is a full trading session no internal routine has yet observed, and that is structural, not a fault.** `state.freshness` reads `marks_due_through` **2026-09-24** against `last_trading_day` **2026-09-25**; the daily tier is `daily_sun_thu`, so Friday is absorbed by today's D1/D2a fire, which runs *after* this one. This is the exact condition the W3 spec's 2026-09-13 clause anticipates, and **externally sourcing that session is required, not the forbidden re-source.** Done, labelled, and — new this cycle — **cross-checked against an overlapping session rather than merely flagged**:

- **The external feed was validated on 2026-09-24, a date the warehouse holds.** FMP returned Brent **106.60**, VIX **15.67** and SPY **767.18** for 09-24 — all three exactly equal to `state.signal_marks_curated`. A feed that reproduces the warehouse to the digit on the overlapping session is materially better evidence for its 09-25 figures than a bare "single-sourced" caveat, and this check cost nothing.
- **Brent 2026-09-25 = 104.32** (FMP). **Effectively single-sourced for the settlement print**: a cross-source attempt returned only intraday quotes ($105.32 and ~$105.90, both dated 09-25 at different times of day) that are not stated ICE settlements and do not resolve to a clean check. **Under any of the three figures leg (ii) fails.** No new high was made — 104.32 < 106.60 < 108.75 — so the trigger did not ratchet.
- **VIX 2026-09-25 = 14.87** (FMP only). Below the 15 line, so `VIX_REGIME` would score `LOW`. **INFERRED from an externally-sourced close applied to a published threshold; D2a owns the label.** It does not move `leg_c_technical`, which requires only VIX ≠ `HIGH`.
- **SPY 2026-09-25 = 771.35**, 10Y **5.17%**, 2Y **4.81%** (FMP only). This run does **not** recompute the 50-day SMA for 09-25 and makes **no claim** about Friday's `SPY_TREND` label.
- **Breadth for 2026-09-25 was NOT sourced, and that is a deliberate and arguable choice.** §4b argues breadth is the most consequential of the four precisely because it sits on a threshold. It was not sourced here because it would take a separate Barchart `$S5TH` fetch outside the budget already spent, and because **nothing turns on it today**: breadth would have to rise 45.12 → ≥50.00 in a single session to restore `leg_c_technical`, a 10.8% one-day move the series has not produced in this window. The choice is recorded rather than buried so a later run can judge it differently.

**System state at write time.** `state.system_health.all_green = TRUE`, **zero open criticals**, **105 open alerts (85 info, 20 warning)** — up from 69 (59 info, 10 warning) last cycle, with open *warnings doubling in one week*. Most of the increase is the 09-20/09-21 outage cluster (`routine_run_failed` ×5, `queue_driven_missed_fire` ×3) plus W5's own three `spec_defect_notice_stalled` rows and a `spec_defect_backlog_undrained`. That is OPS0's and W5's surface and is already alarmed on both; it is noted here only because it bears directly on where this run files its finding. `state.trading_enabled = FALSE` with `halt_reason` *"state.freshness marks_fresh/engine_fresh not both TRUE"*; `state.staging_halt_disposition` reads `halt_is_prerefresh_artifact = TRUE`, `gate_alert_action = 'defer_to_craft_site'`, `mechanical_enabled = TRUE`, `marks_current` and `engine_current` both TRUE — the documented pre-refresh artifact for a Sunday fire. **W3 crafts no orders, so per the PRE-REFRESH HALT DISPOSITION rule it raises nothing at all.**

**Metered spend.** One external sub-agent, hard budget 12 calls, **12 used** — 6 Tavily searches and 6 FMP calls, of which **2 FMP calls failed on plan-tier access denial** (XLE chart, both endpoints) and returned nothing. All 12 are written to `ops.web_calls` including the two failures, with the failure reason recorded. **The per-call timestamps are approximate to within the sub-agent's run window (~09:12–09:18 UTC): the agent reported it had no wall-clock access and returned relative ordering only, and recording an approximation is better than inventing precision it did not have.** No finding in this file rests on either failed call; the XLE gap is stated in §4c rather than papered over.

---

## OBSERVED, NOT ADJUDICATED — recorded so a future run does not re-flag them

- **`shock_rubric_brent_peak_revisable` (`82c99515`, W3, 2026-09-13) — still OPEN.** Re-checked substantively this run (correction 6 above): the hazard did not recur for a second consecutive window. **Do not re-file.**
- **`shock_leg_i_event_anchor_undated` (`6081d304`, W3, 2026-09-20) — still OPEN, unadjudicated, one week on.** Extended rather than duplicated — see FILED THIS RUN.
- **`d1_qualifying_event_date_anchor_unspecified` (`03b8f773`, D2, 2026-09-16) — still OPEN.** The Strategy-B-window sibling of the same root. Cross-referenced, not duplicated.
- **`nomadic_borrow_blocked` (`71d484fa`, D2a, 2026-09-23) and `nomadic_borrow_blocked_unsignalled` (`6f04ff75`, D2, 2026-09-07) — both OPEN.** Together they own the entire §4d borrow-side condition. **Do not re-file.**
- **`regime_sweep_blocked` (`b40cb3e6`, D2a, 2026-09-06) — OPEN**, covering E's blocked sweep. Owned.
- **`park_call_brent_day_move_self_contradictory` (`9ce935ae`, D2, 2026-09-23) and `d1_brent_prose_quotes_prior_session_settle` (`4d135348`, W1, 2026-09-27) — both OPEN**, and W1 already marks the second as mergeable with the first. This file's own instance of the same error shape is corrected above and adds no third filing.
- **The four withdrawal-incident alerts are RESOLVED** (`e3d3b4f1`, `5c04fcb8`, `b608c947`, `c04e9c6b`) and the drawdown gate has cleared. Recorded in §4d because the resolved state is not obvious from the alerts alone.
- **W5's own intake is alarming as blocked**: `spec_defect_backlog_undrained` (`cce77a41`) plus three `spec_defect_notice_stalled` rows (`c96b42e5`, `6f444586`, `ee81138f`), all W5, all open. Directly relevant to this run's filing decision — see below. W5's surface.
- **Strategy A's `analytics.strategy_nav` row is entirely zero including `deposits`**, unlike every sibling. Unchanged for a fourth cycle; `state.withdrawal_capacity` gives A the exclusion reason "no idle cash," which is consistent with A having been capital-disabled and swept. Not measured to a conclusion, not escalated.
- **`sweep-VOO-20260924` sits `pending` in `state.open_orders`** with a 2026-09-25 entry window and one open `staged_order_awaiting_confirm` warning (`3b8aad21`). `state.staged_order_reconciliation_overdue` is **empty**, so the 120h clock has not fired. D2a's surface; a park action, not an A–E position.

---

## FILED THIS RUN — one finding, extending the one this routine filed last week

**The shock rubric's qualifying-event test is underspecified in a second, adjacent way, and the exposure this routine called "purely prospective and narrow" seven days ago has tripled in width without being adjudicated.**

MEASURED this session, not relayed. Two things, on one clause of one surface:

**(a) The `> $5/bbl` inclusion test states no measurement window, and that decided a live qualification this week.** The rubric admits an event on, among other alternatives, "an oil price move > $5/bbl attributable to the shock channel." The 2026-09-23 Libya blockade moved Brent **+4.55/bbl on its own session** (98.53 → 103.08) and **+8.07/bbl across 09-23 and 09-24** (98.53 → 106.60). The first fails the test and the second passes it, and nothing in the rubric says which is the right reading. The event qualifies regardless — via the independent "effect on global trade flows" alternative, per §4a — **so nothing is wrong today.** The exposure is an event with a price leg and no flow leg: a sanctions headline, an OPEC signal, a currency move. For such an event the window choice *is* the qualification.

**(b) The dating gap filed as `6081d304` recurred on the very next event, and the window it opens is now six trading days, not two.** Last week's row recorded two candidate anchors two trading days apart and judged the exposure narrow. Leg (i) turns only on the most recent qualifying event, so 2026-09-23 superseded that dispute outright — **moot by supersession, not by resolution.** Today's live question is whether 09-23 qualifies, which separates a leg-(i) expiry of **2026-10-06** from **2026-10-14**. No scheduled `monthly_ftd` scoring falls in that window (2026-10-01 fails under every anchor; the next is 2026-11-02, after both). **An M1R out-of-cycle re-score fires on a limb rather than on a calendar and does fall inside it**, and would be decided by which surface it happened to read — against a rubric whose de-escalation is **REQUIRED, not discretionary**, once both legs hold.

**Filed as an `ops.alerts` `info` row — **`11bbd3b7-d9f6-40e2-9101-6642c412d379`**, `source='W3'`, category `shock_leg_i_qualifying_event_test_underspecified` — naming `strategy/09_regime_scoring_strategy_blind_monthly.md` §Shock / overlay grading rubric as the owning surface and W5 (SPEC-DEFECT NOTICE INTAKE) as the nearest owning routine.** The row asks W5 explicitly to **dispose it together with `6081d304` as one defect on one clause**, because they are the dating and magnitude halves of the same missing test and fixing either alone leaves the other live.

**De-dup performed before filing, and the venue's health checked rather than assumed — with a different answer than last week's.** `ops.alerts` is append-only through `sp_raise_alert`; there is no amend procedure, so "add evidence to the existing open row" is not mechanically available and one merged-by-request row is the closest honest equivalent to it. Last week this routine wrote *"Venue consumer verified, not assumed: W5's SPEC-DEFECT NOTICE INTAKE demonstrably drained W3's own info row `e2eb2990`."* **That claim needs updating: seven days later `6081d304` is still open and W5 has raised `spec_defect_backlog_undrained` and three `spec_defect_notice_stalled` warnings against its own intake.** The venue is the right one and remains the only designated one — a run-log note is explicitly not a venue — but it is currently congested, and filing into it with that stated is more useful than filing into it silently.

**What W3 did NOT do, stated explicitly:** it did not score or re-score any regime axis; did not touch `bigquery/224`, the rubric, `Strategy.md` or any slice; did not correct or contradict W1's published gate date and did not edit `Weekly_Catalyst_Calendar.md`; did not adjudicate whether 2026-09-23 qualifies (it measured the rubric's own test against it and reported both legs); did not edit a queue item; did not craft, block or size anything; did not adjudicate `thesis-FOMC-C-20261020`; did not re-file any of the nine findings already open and named above; did not touch the capital rail or propose a change to it; and did not decide whether C should be funded.

---

## STEPS 1–6, DISPOSED

Stated rather than omitted, so "missing" is never mistaken for "skipped."

1. **Current thesis status** — no thesis in scope. Vacuous.
2. **Competitive landscape** — no position whose peers matter. Vacuous.
3. **Fundamental developments** — no position to accrue evidence against. Vacuous.
4. **Sector and macro context** — the only step with in-scope content, discharged in full by §4a (shock overlay, both legs, against the rubric's own inclusion test), §4b (the technical-plane flip and this file's own prior error about it), §4c (rates, breadth divergence, October FOMC pricing), §4d (the withdrawal and the capital-rail asymmetry), and the Strategy C section.
5. **Thesis-invalidation signals** — no criteria live in scope. Vacuous. (D1 evaluated the D book's criteria on every scanned day; that is M3's surface.)
6. **Time-to-thesis-resolution** — no resolution window open. Vacuous. Per spec W3 checks no convergence targets, time-exit dates or option-expiry mechanics in any case: D1's connector sweep is the sole detector, D2 the sole converter.

---

## WHAT W4 OWES ON THIS FILE — nothing, stated affirmatively

- **No `WEEKLY-THESIS-ACTION` flag.** No hold, no weekly-thesis-action, no further-research recommendation — there is no open in-scope position to carry one. No `immediate_action_flagged` alert is owed and none is raised.
- **Zero queue-convertible items.** No research-deferral checkpoint, no thesis action for D2 to revalidate.
- **Cross-strategy deconfliction is vacuous** with zero open in-scope positions. Noted only for shape: several of W1's A-queue names overlap open Strategy D tranches — not a conflict, since A holds nothing and is double-blocked, and A and D are separate mandates permitted to hold the same name.
- **The C FOMC lane already has its live item and W4 must not re-mint it.** `thesis-FOMC-C-20261020` is `pending` on `PENDING_ANALYSIS`, due 2026-10-20, for the 2026-10-28 decision; D2 owns the GO/NO-GO. The September FOMC is terminal.
- **The shock-overlay measurement is evidence, not a referral.** W4 need not convert it and **must not route it to M1a** (blinding).
- **W1's published gate of 2026-11-02 is NOT invalidated by the anchor move.** Checked this run: 2026-11-02 holds under all three candidate anchors, because both candidate leg-(i) expiries (2026-10-06 and 2026-10-14) fall between the 2026-10-01 and 2026-11-02 `monthly_ftd` scorings. `Weekly_Catalyst_Calendar.md` needs no correction and W4 should not treat it as suspect.
- **One `ops.alerts` info row was raised by this run** (`11bbd3b7-d9f6-40e2-9101-6642c412d379`, `shock_leg_i_qualifying_event_test_underspecified`). It is a spec-defect notice for W5's intake, not a W4 conversion.
- **B's two open re-screens (`rescreen-IONQ-B-20260927`, `rescreen-ORCL-B-20260927`) are due today and belong to D2**, not to W4 and not to this file.

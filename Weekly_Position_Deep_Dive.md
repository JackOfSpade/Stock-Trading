2026-W36

# W3 — Open-Position Deep-Dive (Strategies A, B, C, E)

**Run:** Sunday 2026-09-06 · **Evidence window:** 2026-08-30 09:17 UTC → 2026-09-06 (this routine's own last `completed` run → now; `state.routine_catchup_window` `window_days = 6.99`, cadence-normal against the 10.5-day 1.5× weekly bar — no catch-up sub-section owed, no missed period, no `CATCHUP` token).

**NO `WEEKLY-THESIS-ACTION` FLAG.** No hold / weekly-thesis-action / further-research recommendation is issued, because there is no open in-scope position to issue one on.

**Marker.** `2026-W36` is the plain ISO week of the run date (Sun 2026-09-06 is day 7 of the Mon 08-31 → Sun 09-06 week). W1 (`b921875`) and W2 (`3fa0da9`) both stamped `2026-W36` earlier today, so all three weekly files agree and W4's upstream-freshness read matches. Unlike the 08-23 and 08-30 cycles this marker does not repeat the prior file (`2026-W35`).

---

## HEADLINE — the in-scope book is empty for the third consecutive week, and the reason changed completely

Zero open positions exist in any roster-active `review_cadence: reactive` strategy (A, B, C, E). D is out of scope by `review_cadence: long_horizon` and is M3's monthly deep-dive; its 12 tranches are untouched here.

**But the emptiness is no longer the same fact it was.** For the last two cycles Strategy E was the one strategy that was both router-ACTIVATE and meaningfully funded — the book's single genuine "no qualifying setup" case, and the only place a position could have come from. In the seven days covered here, **both halves of that changed on the same day:**

1. **E produced its first-ever GO on the merits** (`EFX/TRU`, 2026-09-03) — after four months and zero prior merits-GOs.
2. **E's router closed** the same day (`div-E-202608-1`, 2026-09-03, ACTIVATE → DO-NOT-ACTIVATE), and the thesis was declined on the gate.

So the book is empty this week not because nothing qualified, but because the one thing that qualified arrived on the day the door shut. **Every strategy in the book is now router-closed to new entries except C**, which is HYBRID ACTIVATE for FOMC only and holds **$23.64**.

### The empty book, re-established independently this week

Not carried forward from 08-30. Five lines, all measured this session, all agreeing:

| # | Line of evidence | Result |
|---|---|---|
| 1 | `state.current_positions` | 12 rows, **all `strategy='D'`**. Zero A/B/C/E rows. |
| 2 | Latest-event-per-`position_key` off raw `events.position_events`, compared case-insensitively | 13 in-scope keys, **all `B`, all `CLOSE`/`CLOSED`**. Non-closed count **0**. `SELECT DISTINCT strategy` over the whole table returns only `B` and `D` — not a casing artifact. |
| 3 | `events.position_events WHERE event_ts >= 2026-08-30` | **Zero rows, all strategies.** Not one book event of any kind in the window, in scope or out. |
| 4 | `analytics.strategy_nav` | `deployed_mv = 0` for A, B, C **and** E. |
| 5 | **Live broker cross-check** (IBKR `get_account_positions` / `get_account_orders`) | 8 equity lines + the park vehicles. Every equity line reconciles share-for-share to a Strategy D tranche sum (AMZN .3464, DIS .7244, GEV .1244, GOOGL .2577, ISRG .1091, RTX .1601, TSM .1550, UBER .5156). **Zero working orders. No broker line unattributable to D or the park.** |

**The same caveat as prior cycles, restated because it has not stopped being true.** A, C and E have **zero rows in `events.position_events` across all recorded history** — they have never opened a position, rather than having gone flat. Only **B** genuinely went flat (13 keys, last close 2026-08-03). An empty-book verdict on a strategy that has never traded is a weaker statement in kind, and is stated that way.

---

## WHY THE BOOK IS EMPTY — the causes table, materially changed from last week

| | Router state | Capital | Cause |
|---|---|---|---|
| **A** | DO-NOT-ACTIVATE (`div-A-202608-1`, held 2026-09-03, third consecutive cycle) | NAV **$0.00**, `outstanding_debt` $3,888.45 | **Double-blocked.** 23-name watchlist parked, router-gated. Next scheduled chance is the 2026-10-01 M1a/M1b re-score. |
| **B** | DO-NOT-ACTIVATE (`div-B-202608-1`, held 2026-09-03) — entirely the universal `shock_overlay=acute` override; B's own legs (SPY UP, VIX LOW 14.32, breadth HEALTHY 66.40) all pass | NAV **$0.00**, `outstanding_debt` $4,973.25 | Blocked by an override external to B's own machinery. W2 ran in INDEX MODE accordingly. |
| **C** | **HYBRID ACTIVATE, FOMC-only** — the only strategy the router permits to trade | NAV **$23.64** | **Flat by design, and now materially under-capitalised — see the finding below.** Its one live candidate is `thesis-FOMC-C-20260908` (FOMC 2026-09-16), due 2026-09-08, still `pending`. |
| **E** | **DO-NOT-ACTIVATE — STATE CHANGE 2026-09-03**, the only change in the five-review cohort | NAV **$15,368.39** (96.4% of the $15,941.28 book), available $15,368.39 | **Closed on the day its first merits-GO arrived.** |

`state.entry_staging_allowed`: `entries_allowed = TRUE`, `block_reason` NULL. `perf.kill_flags`: rows only for B and D, **every boolean FALSE on both**. `ops.arsenal_control` enabled, not frozen. **Nothing was blocked at the capital or kill gate this week** — the emptiness is router state, plus C's balance.

---

## THE E FLIP — and the mechanical shape that produced it

**E was closed by its own case getting better.** This is not a figure of speech; it is the mechanism.

- E carries **no strategy-specific reconciliation override** (unlike A's `decelerating AND hawkish` rule or D's `reaccelerating AND hawkish`). The only rule that can force E's raw ACTIVATE to DNA is the universal one: *"If M1a scores `shock_overlay = acute` AND M1b returns ACTIVATE for any strategy → override to DO-NOT-ACTIVATE for that strategy."*
- That override is **conditioned on a raw ACTIVATE**. Through August, M1b's raw fundamental call on E was not ACTIVATE, so the override had nothing to bite on, and E carried an operative ACTIVATE from `div-E-202607-1` (2026-08-05).
- On 2026-09-01 M1b's raw call for E **flipped to ACTIVATE** — a genuine improvement, credited substantially to M2's own August measurement (60d correlation exceeding 252d in 66 of 89 pairs, 74%). That flip is what armed the override, **which fired on E for the first time ever**, and the net result was DO-NOT-ACTIVATE.

So a strategy whose raw call is negative passes through the override untouched and can carry an ACTIVATE state; a strategy whose raw call turns positive gets closed. **M4 named this in advance** — its 2026-09-01 carry-forward row reads *"NO NET FLIP, but the BASIS INVERTED and this is the consequential row of the cycle."* AR_orc then upheld the override on four grounds, including that the rule text admits no market-neutral carve-out and that disapplying it on E while upholding it on B in the same fire would be exactly the asymmetry it condemns elsewhere. Seven weaknesses graded (3 Tier 1 / 2 Tier 2 / 2 Tier 3), theater-check DIVERGENT.

**W3 records the shape and does not re-litigate the verdict — and specifically does not re-file the general question, because it is already queued with a drainer.** `events.queue_events` carries `otr-router-shock-override-2026` (`PENDING_REVIEW`, `out-of-table-resolution`, due **2026-09-08**), landed by Rev 48 R3 out of `div-B-202608-1`'s referral, carrying precisely the two limbs Rev 48 does *not* discharge: **horizon scaling** and a **per-strategy transmission term**. Its recorded conservative default is HOLD — the override stands as written. That is the correct venue for "should a uniform shock override catch a market-neutral strategy," and it has a due date two days out. Nothing owed here.

---

## E's FIRST MERITS-GO — the four-month calibration question, answered and then retired

Two E pair theses were drained by D2 on 2026-09-03. They are the first real evidence about whether E's criteria discriminate, and they point in opposite directions — which is the point.

| Pair | Verdict | Ground |
|---|---|---|
| **DY/EME** | **NO-GO on the merits** | Criterion 2 fails on a compound case. Explicitly *not* a conservative-default decline — "the analysis ran in full and reached NO-GO on its own." 252d correlation 0.5477 (clears the 0.50 floor by 0.048, inside estimation noise); EME's +19.3% was a genuine beat-and-raise re-rating; catalysts mostly undated. The item's own `honest_risk` re-test precondition came back **positive for the anti-thesis** — four further sell-side target cuts, not the one cited. |
| **EFX/TRU** | **GO on the merits, MEDIUM, 60 — NO ENTRY** | 252d correlation **0.8450**, vols within 1pp, borrow GC at 0.27% annualised, all five criteria PASS. Declined on the item's own `conservative_default`, which required affirmative resolution of *both* named blockers; `state.trading_enabled` had cleared to TRUE, but `div-E-202608-1` had **not yet landed an orchestrator row** when D2 read it. One of two affirmative. The rule fired. |

**Nothing was lost to the timing.** The review D2 was waiting on resolved DO-NOT-ACTIVATE later the same day, so a D2 that had waited would have been barred anyway. The decline is robust to the sequencing, and that is worth stating plainly rather than leaving as an open "what if."

**The calibration question this file has carried for two cycles is now retired — and it was already resolved before last week's file re-affirmed it.** Both prior W3 cycles left with W5 the question *"is a ≥95th-percentile dispersion anchor with zero entries in four months correctly calibrated, or unsatisfiable?"* Measured this run against the governing text rather than against the prior file:

- That anchor **never existed in canonical `Strategy.md` or in `strategy_math/strategy_e.py`**. E's Entry criterion 3 has always read *"L–S correlation over trailing 252 trading days ≥ 0.5; beta-adjusted leg sizing."* The percentile requirement existed only in `strategy/08_pre_mortems.md`'s prose, introduced at rev 2 via SL2's documentary-only route and enforced as a hard NO-GO gate anyway — including against TLN/VST on 2026-08-18, which passed the real criterion 3 at 0.7824 correlation and was declined at the 65.1st percentile.
- **The owner decided on 2026-08-25: DROP** (pre-mortem rev 13, `Strategy.md` Rev 47). The percentile is still computed and recorded as `percentile_at_entry` and still drives the Pair-prioritization *ranking*, but **it gates nothing.**

So the two 09-03 theses scoring criterion 3 on the correlation floor alone were **correct**, not inconsistent with the TLN/VST precedent — the spec changed between them. And the answer to the question as posed is: **E's criteria are satisfiable, and the threshold the question was actually about no longer exists.**

**Held to its true weight, which is modest.** One MEDIUM/60 GO is not evidence that E's criteria are well-calibrated. The EFX/TRU analysis itself found that the pair's supporting arithmetic **did not reproduce**: the payload's "reconverging on schedule" rested on a 3-month spread of −6.54pp, and D2 measured −9.68pp on 63 trading days and −11.26pp on an exact calendar quarter — TRU's lead 50–70% wider than stated, with the number swinging from −3pp to −14pp across a two-week band of plausible window anchors. The sensitivity, not any single figure, was the finding. One merits-GO and one merits-NO-GO in a single day is the first genuine discrimination E's criteria have shown; it is not a calibration verdict.

---

## THE SUBSTANTIVE ANALYSIS — the shock overlay now has a written exit, and it is not close to being met

Steps 1–6 are per-position and vacuous on an empty book. The question that determines whether the book *stays* empty is whether `shock_overlay = acute` — the single value holding A, B, D and E shut — still holds. **This week, for the first time, that question has a published, owner-directed answer procedure and an in-warehouse series to run it on**, both landed by Rev 48 on 2026-09-05, after the last W3 ran.

### The rubric's REQUIRED de-escalation test

From `strategy/09_regime_scoring_strategy_blind_monthly.md` §"Shock / overlay grading rubric": *"De-escalation from `acute` to `latent` is REQUIRED, not optional, once both legs hold... (i) zero new qualifying events for 15 consecutive trading days; and (ii) Brent has retraced at least 50% of the shock elevation... Either leg failing keeps the grade at `acute`."* Escalation is immediate and the asymmetry is deliberate.

### Leg (ii), measured — FAILS, and is moving the wrong way

Anchors read from `state.rerisking_limb_status`, which computes the rubric's triplet off `state.signal_marks_curated` (`ticker='BZUSD'`) — the CURATED view the rubric pins, never the raw table:

| Quantity | Value |
|---|---|
| Pre-shock baseline | **84.73** (43 observations, 2026-06-01 → 2026-07-31 — the rubric's short-history fallback, count recorded as it requires) |
| Acute-run start | 2026-08-01 |
| Peak close since | **95.63** (2026-09-02) |
| Shock elevation | 10.90 |
| **Retrace trigger** (baseline + 50%) | **90.18** |
| Current close | **95.55** (2026-09-04) |
| Verdict | **95.55 > 90.18 — `leg_b_basis = 'not_retraced'`, by 5.37** |

Brent would need to fall **−5.6%** from the last print for leg (ii) to hold. It has done the opposite: **+8.5% in four sessions**, 88.10 (08-28) → 95.55 (09-04), setting a **new closing high for the entire acute run** at 95.63 on 09-02, above the prior 94.39 of 08-21. The price leg is not merely un-retraced; it is at its most elevated point since the shock began.

**A mechanical property worth stating, because it is not obvious and it matters: the trigger ratchets.** The peak is a running maximum, so every new high raises the retracement target — the trigger moved 89.56 → 90.18 between 08-28 and 09-04 purely because Brent made new highs. A partial pullback after a new high does not restore the prior position; the test then demands half of the *new, larger* elevation. This is correct behaviour (a worsening shock should be harder to de-escalate) and it is stated here so it is not later mistaken for the test drifting.

### Leg (i) — CANNOT BE EVALUATED from any in-warehouse source, and this is the real gap

The rubric's leg (i) turns on *the date of the most recent qualifying event*. **No warehouse table records qualifying-event dates** — there is no `events.geopolitical_events`, no `qualifying_event` column anywhere across the `events`/`state`/`ops` datasets. The only available proxy, `shock_acute_run_start = 2026-08-01`, marks when the *axis value* began its run, which the rubric treats as a distinct fact from the most recent qualifying event. That date lives only in M1a's narrative rationale.

**This changes no conclusion** — the legs are conjunctive and leg (ii) fails outright, so the test is not satisfied regardless. It is recorded because a rubric whose second leg is unmeasurable from the warehouse will be evaluated on prose every time, which is precisely the failure mode the rest of Rev 48 was written to close. Not filed as a defect: the rubric is one day old, its rationale-recording duty (*"the date of the most recent qualifying event; the baseline / peak / current Brent triplet; which legs held"*) is exactly the mechanism that will surface this at the next scoring, and the 2026-10-01 M1a is the first scoring bound by it.

### The re-risking limb — armed, and blocked on the same leg

`state.rerisking_limb_status`, measured this run:

| Strategy | Run start | Dwell (trading days) | leg (a) dwell ≥15 | leg (c) technical | leg (b) price | `sql_limbs_fired` |
|---|---|---|---|---|---|---|
| A | 2026-04-22 | 94 (left-censored) | TRUE | TRUE | FALSE | **FALSE** |
| B | 2026-08-05 | **22** | TRUE | TRUE | FALSE | **FALSE** |
| D | 2026-08-05 | **22** | TRUE | TRUE | FALSE | **FALSE** |
| E | 2026-09-03 | 1 | FALSE | TRUE | FALSE | **FALSE** |
| C | — (not DNA) | — | FALSE | TRUE | FALSE | **FALSE** |

**B and D clear the dwell leg with seven days to spare** (22 against a 15-day threshold), and the technical leg passes for all five. **Leg (b) — the identical price arithmetic as rubric leg (ii) — is the sole binding constraint fleet-wide.** So the entire out-of-cycle re-risking path now hangs on one number: Brent at or below 90.18.

Consistent with that, `events.queue_events` has **never held a `PENDING_REGIME_REFRESH` row**, and **M1R ran for the first time on 2026-09-05** (a registration-day artifact, fired Saturday because its trigger was created that day), found zero open items, and correctly no-opped with `rows_written=0`.

**FINDING: `acute` is not merely still defensible — the evidence for it has strengthened materially since the last review, and the published exit is further away than it was a week ago.** No case for a regime change exists on the measured evidence, and none is made here. **No alert is raised on this**, and none is owed: W3 does not score the axis, the owning re-score paths (M1a 2026-10-01, or M1R on a limb firing) read this same series independently, and M1a is strategy-blind by hard file boundary so a finding framed around which strategies are held out must not be routed to it.

---

## CORRECTING THIS ROUTINE'S OWN PRIOR FILE — the price leg, and the method behind it

Last week's file concluded that the price leg had *"largely mean-reverted"*, that Brent was *"~two-thirds retraced"*, and that the overlay's two legs *"now disagree."* Measured this week against the system's own anchors, **that reading has been overturned by the tape, and the way it was reached was fragile.**

**What was right, stated first.** Its individual price observations were accurate. Against the curated series now available: it reported Brent 88.29 for 2026-08-28 (actual close **88.10**, 0.2% off), and $78.17 for the 2026-07-08 pre-shock reference (actual close **78.02**, 0.2% off). Its $105 intraday peak for 07-23 is not contradicted by that day's **100.69** close. The data were not the problem.

**What was fragile.** It chose its own anchors — a single-day pre-shock close and a July *intraday* high — and computed a retracement fraction off them. The system's rubric uses a 43-observation median baseline (84.73), closes only, and a peak measured from the acute-run start (2026-08-01, so the July high is outside the window entirely). Different anchors, different arithmetic, and a conclusion that could not be checked against anything the system itself holds.

**What the honest retrospective shows — and it is not a simple "wrong."** Run the rubric's own arithmetic on the data that file had (peak-through-08-28 = 94.39, elevation 9.66, trigger 89.56, Brent 88.10): the price leg **was** retraced on 2026-08-28, by 1.46. Its qualitative verdict was defensible, and arguably correct, on the day. **It was then reversed within three sessions**, and the file offered no way for a reader to see how narrow the margin was, because the margin was never computed against the binding threshold.

**Fair to that run: the substrate did not exist.** `bigquery/217_brent_signal_feed.sql` landed **2026-09-04** and the rubric on **2026-09-05** — five and six days after it ran. Web-sourcing was its only option, and the same is true of M1a's 2026-09-01 scoring. Neither is a lapse.

**But the pattern across three cycles is W3's own, and it is the fixable part.** Three consecutive W3 cycles have propagated a quantitative claim taken from prose rather than from the governing surface: the treasury-rate misread (asserted 08-17, re-raised 08-23, refuted 08-23); this Brent retracement (08-30); and the E "≥95th-percentile anchor" question, re-affirmed as open on 08-30 **five days after the owner had dropped it**, in a file that cited the very revision series that closed it. The root cause is single and specific: **reasoning from this routine's own prior file instead of re-reading the governing spec or the warehouse series.** Both surfaces now exist. `Claude_Task_Plan.md`'s W3 section is amended in this run's commit to bind the next run to them — the same in-section self-correction W2 made to its own INDEX MODE clause this cycle.

---

## COVERAGE STATED HONESTLY

D1 ran and completed on **2026-08-30, 08-31, 09-01, 09-02 and 09-03** — five of five expected days. Verified **mechanically**, not by raw row count: `state.cadence_expected_history` returns **no row** with `expected AND in_service AND rows_logged = 0` for any date from 2026-08-28 through 2026-09-05. This is the check W1's own 2026-08-23 `cadence_outage` false positive existed for, and W1 ran it again this cycle against a fresh instance of the same claim.

- **2026-09-04 (Friday) is a full trading session no internal routine has yet observed.** The daily tier is `daily_sun_thu`; Friday is structurally outside it. Today's D1 Sunday scan covers it, and has not fired yet — `Daily.md`'s marker is still **2026-09-03**. W1 and W2 both state the same and both decline to cover it early, correctly: doing so would duplicate D1's scan hours before it runs.
- **With an empty in-scope book this changes no conclusion**, but this file claims no coverage it does not have. Note that the newest Brent print used above, 2026-09-04, *is* in the warehouse — the signal-marks ingest and D1's narrative scan are separate paths.

---

## OBSERVED, NOT ADJUDICATED — recorded so a future run does not re-flag them

- **96.4% of book NAV is stranded, and this is already fully instrumented — do NOT re-file it.** `state.regime_capital_sync_pending` returns exactly one row: `SWEEP / E / 15368.39 / counterparty NULL / blocked_no_recipient TRUE / blocked_reason 'no_eligible_recipient'`. Nothing moves, which is the safe outcome. AR_orc raised `capital_enablement_single_strategy` on 09-03; it was measured and closed on 09-04 by `bigquery/215` (superseded by `bigquery/223`), which added the blocked signal, registered `regime_sweep_blocked` in `ops.alert_policy` and wired a D2a handler. The commit states the residual plainly: *"The right answer to 'the whole book routes behind one narrowly-scoped strategy' is an owner decision about the roster."* Owned, signalled, and not W3's to decide.
- **`state.trading_enabled = FALSE`** with `halt_reason` *"state.freshness marks_fresh/engine_fresh not both TRUE"*. `state.staging_halt_disposition` reads `halt_is_prerefresh_artifact = TRUE`, `gate_alert_action = 'defer_to_craft_site'`, `mechanical_enabled = TRUE`, `marks_current`/`engine_current` both TRUE — the documented pre-refresh artifact (marks cover 09-03; 09-04 has had no D2a slot). **W3 crafts no orders, so per the PRE-REFRESH HALT DISPOSITION rule it raises nothing at all.** `state.system_health.all_green = TRUE`, zero open criticals.
- **Three queue items two days past `due_date` (2026-09-04), none a defect.** `premortem-C-2026-a3` (attacker-complete, awaiting AR_orc) and the paired `parkswitch-SGOV-sell-20260903` / `parkswitch-VOO-buy-20260903` DAY orders (awaiting D2a). All three came due on the Friday nobody runs; AR_orc and D2a both fire tonight. This is the documented Thu→Sun catch-up shape.
- **The park ledger is behind the broker, expectedly.** IBKR shows the 09-03 SGOV→VOO switch fully filled (VOO 21.4714, SGOV 0) while both legs still read `pending` in `state.open_orders`. Same Fri/Sat mechanism; D2a's next reconciliation is tonight. Flagged only because a broker-vs-ledger mismatch is otherwise exactly the shape that looks alarming to a fresh reader. The park is D1/D2/D2a's surface, not W3's.
- **One open `warning`: `ci_finding` (2026-09-06)**, listing six unresolved `live-sql-parity` guard findings including `state.regime_capital_sync_pending` — consistent with the 09-04 apply of `bigquery/215`/`223`. Already on the board with an owner; not re-filed, and not W3's surface.
- **M1a's 2026-09-01 Brent figures do not reconcile with the curated series, and this is a pre-substrate artifact, not a live defect.** Its rationale records *"Brent ranged 83.55 to 93.73... and closed at 93.03, ABOVE the July close."* The curated series gives August closes ranging 79.36–94.39 with 08-31 at **90.49** against a 07-31 close of **87.93**. **The directional claim is correct** (90.49 > 87.93); the specific levels are not the series the rubric now pins. M1a scored on 09-01, three days before `bigquery/217` landed, so it had no in-warehouse series either. From 2026-09-05 M1a's read grant includes `BZUSD`, and the rubric's rationale-recording duty binds from the 2026-10-01 scoring. **No alert; nothing to fix retroactively.**
- **A's `analytics.strategy_nav` row is entirely zero including `deposits`**, unlike its four adopted siblings. Consistent with A having been capital-disabled and swept (`outstanding_debt` $3,888.45 records what left), so this is very likely the sweep ledger working as designed rather than a missing allocation. Not measured to a conclusion this run and not escalated — recorded so it is not mistaken for a fresh anomaly.

---

## FILED THIS RUN — one finding, on a surface W3 does not own

**Strategy C — the only strategy the router permits to trade — has $23.64 and a borrow rail whose donor set is empty, and nothing anywhere says so.**

Measured directly this session, not relayed:

- `analytics.fn_nomadic_capital_restore_plan('C', 500.0)` returns **zero rows**. C is nomadic and by design *"holds NO exclusive standing capital"* (`Operating_Protocols.md` §16), borrowing pro-rata at trade time from donors matching `capital_enabled AND != C AND NOT nomadic AND available_funds > 0`.
- `state.strategy_capital_enablement`: **only C is `capital_enabled`**; A, B, D and E are all `capital_disabled` as of 2026-09-04. C is itself nomadic and excluded as its own donor, so **the donor set is empty and the function returns an empty result set for any amount.**
- C's own residual is **$23.64**, unswept only because it sits below the $25 de-minimis *movement* floor (a minimum transfer size, not a reserve, and not an entry gate).

**This is safe but silent, and the silence is the defect.** §16 already requires the caller to *"refuse to craft on `is_fully_funded = FALSE`, not merely on an empty plan"* — so D2 should decline rather than mis-size, and no capital is at risk. But this is the exact asymmetry `bigquery/215` closed on the regime rail four days ago, in the opposite direction: an empty view is indistinguishable from the healthy steady state. `ops.alert_policy` registers `nomadic_sweep_blocked` and `regime_sweep_blocked` — **there is no borrow-side category at all.**

**And there is a dated, concrete instance two days out.** The live queue item `thesis-FOMC-C-20260908` (due **2026-09-08**, FOMC 2026-09-16) carries, in its own context, a measurement asserting the opposite: *"C can now borrow an UNCAPPED amount at order-craft time (`fn_nomadic_capital_restore_plan(C, 5000)` returns donor E, donor_capacity 15309.94, is_fully_funded TRUE)."* That was true when written on 2026-08-16. **E went `capital_disabled` on 2026-09-04 and nothing has revisited the item since.** D2 drains it in two days against text that points the wrong way. §16's live re-check should catch it; the item's own note should not have to be caught.

Filed per the OUT-OF-SCOPE FINDINGS rule as an `ops.alerts` **`info`** row, `source='W3'`, category `nomadic_borrow_blocked_unsignalled`, naming the surface and the nearest owning routine — the venue W5's SPEC-DEFECT NOTICE INTAKE drains. **What W3 did NOT do, stated explicitly:** it did not edit the queue item, did not touch the capital rail or any `bigquery/*.sql`, did not craft, block or size anything, and did not decide whether C should be funded. Those are D2's, D2a's and the owner's calls.

---

## STEPS 1–6, DISPOSED

Stated rather than omitted, so "missing" is never mistaken for "skipped."

1. **Current thesis status** — no thesis in scope. Vacuous.
2. **Competitive landscape** — no position whose peers matter. Vacuous.
3. **Fundamental developments** — no position to accrue evidence against. Vacuous.
4. **Sector and macro context** — the only step with in-scope content, discharged in full by the shock-overlay measurement above.
5. **Thesis-invalidation signals** — no criteria live. Vacuous. (D1 covered the D book's criteria on every scanned day; out of scope.)
6. **Time-to-thesis-resolution** — no resolution window open. Vacuous. Per spec W3 checks no convergence targets, time-exit dates or option-expiry mechanics in any case: D1's connector sweep is the sole detector, D2 the sole converter.

---

## WHAT W4 OWES ON THIS FILE — nothing, stated affirmatively

- **No `WEEKLY-THESIS-ACTION` flag.** No hold, no weekly-thesis-action, no further-research recommendation — there is no open in-scope position to carry one.
- **Zero queue-convertible items.** No research-deferral checkpoint, no thesis action for D2 to revalidate.
- **Cross-strategy deconfliction is vacuous** with zero open in-scope positions. Noted only for shape: GOOGL and GEV appear on W1's Strategy-A shortlist while both are open Strategy D positions — not a conflict (A has no positions and is double-blocked), and A and D are separate mandates that may hold the same name.
- **The C FOMC thesis is already enqueued** as `thesis-FOMC-C-20260908` and **must not be duplicated** — W1 states this too, and the 2026-08-30 W4 run handled it correctly by matching rather than minting.
- **The shock-overlay measurement is evidence, not a referral.** W4 need not convert it and **must not route it to M1a** (blinding).
- **One `ops.alerts` info row was raised by this run** (`nomadic_borrow_blocked_unsignalled`). It is a spec-defect notice for W5's intake, not a W4 conversion.

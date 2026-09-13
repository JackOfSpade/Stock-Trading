2026-W37

# W3 — Open-Position Deep-Dive (Strategies A, B, C, E)

**Run:** Sunday 2026-09-13 · **Evidence window:** 2026-09-06 09:31:29 UTC → 2026-09-13 (this routine's own last `completed` run → now; `state.routine_catchup_window` `window_days = 6.98`, cadence-normal against the 10.5-day 1.5× weekly bar — no missed period, no catch-up sub-section owed, no `CATCHUP` token).

**NO `WEEKLY-THESIS-ACTION` FLAG.** No hold / weekly-thesis-action / further-research recommendation is issued, because there is no open in-scope position to issue one on.

**Marker.** `2026-W37` is the plain ISO week of the run date (Sun 2026-09-13 is day 7 of the Mon 09-07 → Sun 09-13 week). W1 (`f5ce3d5`) and W2 (`d3c24a0`, `98fdc74`) both stamped `2026-W37` earlier today, so all three weekly files agree and W4's upstream-freshness read matches.

**Scope, derived not assumed.** In-scope = roster-active strategies with `review_cadence: reactive`. Read from `state.strategy_roster` (A, B, C, D, E all `ADOPTED`; F, G, H `REJECTED`, not roster-active) and `strategy/roster.yaml` (`reactive` for A, B, C, E; `long_horizon` for D). So the set is **A, B, C, E** — unchanged, and D's 12 tranches are M3's monthly deep-dive, untouched here.

---

## HEADLINE — the book is empty for a fourth week, and the reason has hardened into arithmetic

Zero open positions exist in any in-scope strategy. But the finding of this cycle is not the empty book; it is **what happened to the one number the whole book's re-opening hangs on.**

Last week this file reported the shock overlay's published exit as failing on its price leg by 5.37, needing a −5.6% move in Brent. In the seven days covered here **the shock escalated sharply**: Brent closed **107.63** on 2026-09-10, a new high for the entire acute run, and the shock elevation **more than doubled** — 10.90 → 22.90. The retrace trigger ratcheted 90.18 → **96.18**. The required fall went from −5.6% to **−10.6%**.

And the second leg, which last week was recorded as *unmeasurable from the warehouse*, is this week **affirmatively failed**: there is a dated cluster of new qualifying shock events inside the window, the most recent on **2026-09-11 — the last trading day.** The 15-trading-day quiet clock has been reset to **zero**.

**The consequence is mechanical and worth stating first, because nothing else in this file is as load-bearing:**

> **M1a's 2026-10-01 scoring cannot de-escalate the shock overlay, no matter what Brent does between now and then.** Only **14** trading days separate 2026-09-11 from 2026-10-01 (counted in `state.market_calendar`); leg (i) requires **15**; the legs are conjunctive. The 15th trading day after the last qualifying event is **2026-10-02** — the day *after* the next scheduled scoring. So A, B, D and E are router-closed to new entries through at least the 2026-10-01 cycle as a matter of calendar arithmetic, not of judgment, and the out-of-cycle re-risking limb cannot fire either.

C remains the only strategy the router permits to trade, on **$23.64**.

### The empty book, re-established independently this week

Not carried forward from 09-06. Five lines, all measured this session, all agreeing:

| # | Line of evidence | Result |
|---|---|---|
| 1 | `state.current_positions` | 12 rows, **all `strategy='D'`**. Zero A/B/C/E rows. |
| 2 | Latest-event-per-`position_key` off raw `events.position_events`, compared case-insensitively | 13 in-scope keys, **all `B`, all `CLOSED`**. Non-closed count **0**. `SELECT DISTINCT strategy` over the whole 74-row table returns only `B` and `D` — not a casing artifact. |
| 3 | `events.position_events WHERE event_ts >= 2026-09-06` | **Zero rows, all strategies.** Not one book event of any kind in the window, in scope or out. |
| 4 | `analytics.strategy_nav` | `deployed_mv = 0` for A, B, C **and** E. |
| 5 | **Live broker cross-check** (IBKR `get_account_positions` / `get_account_orders`) | 8 equity lines + 2 park vehicles. Every equity line reconciles share-for-share to a Strategy D tranche sum (AMZN .3464, DIS .7244, GEV .1244, GOOGL .2577, ISRG .1091, RTX .1601, TSM .1550, UBER .5156). Park: SGOV 74.8667, VOO 10.8278. **Zero working orders. No broker line unattributable to D or the park.** |

**The same caveat as prior cycles, restated because it has not stopped being true.** A, C and E have **zero rows in `events.position_events` across all recorded history** — they have never opened a position, rather than having gone flat. Only **B** genuinely went flat. An empty-book verdict on a strategy that has never traded is a weaker statement in kind, and is stated that way.

**One prior-file figure corrected by re-measurement.** Last week's file dated B's flattening to a "last close 2026-08-03." Measured this run, the last in-scope position event is the terminal `CLOSE` of `B:MSCI:2026-07-27` on **2026-08-18** (D2a STEP 0 fill reconciliation; the row's own note ends *"Strategy B now holds ZERO open positions"*). B has therefore been flat **26** days, not 41. Nothing downstream turns on it — but this is the routine's own prior prose being re-established against the table rather than restated, which is the discipline this section exists to enforce.

---

## WHY THE BOOK IS EMPTY — the causes table

| | Router state | Capital | Cause |
|---|---|---|---|
| **A** | DO-NOT-ACTIVATE (`div-A-202608-1`, held 2026-09-03; DNA run open since 2026-04-22, dwell **98** trading days, left-censored) | NAV **$0.00** | **Double-blocked.** 41-name A-queue parked in `Watchlist.md`, router-gated. Next scheduled chance is the 2026-10-01 M1a/M1b re-score — which, per the headline, cannot clear the overlay. |
| **B** | DO-NOT-ACTIVATE (held 2026-09-03) — entirely the universal `shock_overlay=acute` override; dwell **26** | NAV **$0.00** | Blocked by an override external to B's own machinery. W2 ran in INDEX MODE for a third consecutive cycle accordingly. |
| **C** | **HYBRID ACTIVATE, FOMC-only** — the only strategy the router permits to trade | NAV **$23.64**, `sizing_base_2pct` **$0.47** | **Flat by design and materially under-capitalised.** Its FOMC candidate was drained NO-GO on 2026-09-08 — see the C section below. |
| **E** | DO-NOT-ACTIVATE (state change 2026-09-03, adjudicated last cycle); dwell **5** | NAV **$15,368.39** (96.47% of the $15,931.45 book) | Closed on the day its first merits-GO arrived. Unchanged this week; not re-litigated here. |

`state.entry_staging_allowed`: `entries_allowed = TRUE`, `block_reason` NULL. `perf.kill_flags`: rows only for B and D, **every boolean FALSE on both** (D: `deployed_days` 95, `closed_trades` 1, drawdown −4.34%, `excess_vs_sgov` +3.62%, β̂ 0.933, α 0.221 annualised). `state.strategy_capital_enablement`: **only C is `capital_enabled`**; A, B, D and E all `capital_disabled` since 2026-09-04T01:03:40Z. **Nothing was blocked at the capital or kill gate this week** — the emptiness is router state, plus C's balance.

Book NAV re-measured: A $0.00 + B $0.00 + C $23.64 + D $539.42 + E $15,368.39 = **$15,931.45** (last week $15,941.28; the difference is D's mark).

---

## THE SUBSTANTIVE ANALYSIS — the shock overlay, measured against its own published exit

Steps 1–6 are per-position and vacuous on an empty book. The question that determines whether the book *stays* empty is whether `shock_overlay = acute` still holds. Rev 48 (2026-09-05) gave that question a required answer procedure; this is the first W3 cycle to run it end to end.

### The rubric's REQUIRED de-escalation test

From `strategy/09_regime_scoring_strategy_blind_monthly.md` §"Shock / overlay grading rubric" (**unchanged in the window** — verified, the file has no commit since 2026-09-05):

> **De-escalation from `acute` to `latent` is REQUIRED, not optional, once both legs hold.** Downgrade when BOTH are true, each dated and measured in the row rationale: (i) zero new qualifying events for 15 consecutive trading days; and (ii) Brent has retraced at least 50% of the shock elevation, i.e. it now sits at or below the baseline-to-peak midpoint. Either leg failing keeps the grade at `acute`.

Escalation is immediate with no dwell requirement, and the rubric states that asymmetry is deliberate.

### Leg (ii), measured — FAILS, and the gap has more than doubled

Anchors read from `state.rerisking_limb_status`, which computes the rubric's triplet off `state.signal_marks_curated` (`ticker='BZUSD'`) — the CURATED view the rubric pins, never the raw table:

| Quantity | This week | Last week | Change |
|---|---|---|---|
| Pre-shock baseline | **84.73** (43 obs, 2026-06-01 → 2026-07-31 — the rubric's short-history fallback, count recorded as it requires) | 84.73 | — |
| Acute-run start | 2026-08-01 | 2026-08-01 | — |
| Peak close since | **107.63** (2026-09-10) | 95.63 (09-02) | **+12.00** |
| Shock elevation | **22.90** | 10.90 | **+110%** |
| **Retrace trigger** (baseline + 50%) | **96.18** | 90.18 | **+6.00** |
| Current close | **107.63** (2026-09-10) | 95.55 (09-04) | — |
| Verdict | **107.63 > 96.18 — `leg_b_basis = 'not_retraced'`, by 11.45** | not_retraced, by 5.37 | **worse** |

**Peak equals current**: Brent is sitting at the most elevated point of the entire acute run. The path, from the curated series:

`88.10` (08-28) → `90.49` → `94.65` → `95.63` → `95.52` → `96.28` (09-04) → `99.39` (09-08) → `101.21` (09-09) → **`107.63`** (09-10)

That is **+22.2% in nine sessions**, including **+6.34% on 09-10 alone**. Brent must now fall **−10.63%** from the last warehouse print for leg (ii) to hold.

**How large a fall that is, measured against the series' own history** (71 observations, 2026-06-01 → 2026-09-10): the worst single-day move ever recorded in this series is **−8.70%** and the worst 5-day is **−14.55%**. So the required retrace **exceeds the largest one-day decline the series has ever printed**; a five-session close is inside historical range but would take the worst such stretch on record. This is context, not a forecast — the point is that leg (ii) is not a near-miss.

**The trigger ratchets, and this cycle demonstrates it.** The peak is a running maximum, so every new high raises the retracement target. The trigger moved 90.18 → 96.18 purely because Brent made new highs; a partial pullback after a new high does not restore the prior position, because the test then demands half of the *new, larger* elevation. Correct behaviour — a worsening shock should be harder to de-escalate — and stated so it is not later mistaken for the test drifting.

### Leg (i), measured — FAILS OUTRIGHT. This is the part that changed in kind, not degree.

Last week this file recorded leg (i) as unevaluable: *"No warehouse table records qualifying-event dates."* **That remains true of the warehouse, and it is still true that leg (i) has no in-warehouse source.** What was wrong was the implied conclusion that the leg therefore cannot be evaluated at all. It can — off-warehouse, at metered cost — and this run did it, because with leg (ii) escalating rather than retracing, leg (i)'s clock became the quantity that fixes the *earliest possible* exit date.

The rubric defines the test precisely, and the definition is **conjunctive**:

> **Qualifying shock event.** A dated development that (i) meets input category 4's structured inclusion criteria above — an effect on global trade flows, an oil price move > $5/bbl attributable to the shock channel, a widening in sovereign credit spreads, or a major currency move > 2% against USD — and (ii) is attributable to a named geopolitical or trade channel. Narrative escalation with no measurable leg, undated commentary, and developments failing category 4's criteria are not qualifying events regardless of salience.

**Dated developments inside the window, each attributable to a named channel** (all EXTERNALLY SOURCED — no warehouse holds these; sources and dates given because the rubric's own bar is *dated*):

| Date | Development | Source (date) |
|---|---|---|
| 2026-09-05 | US struck three Iranian oil tankers | CBS News (pub. 09-08) |
| 2026-09-09 | Iran (IRGC) said it attacked 10 ships near the Strait of Hormuz | Al Jazeera (09-10) |
| 2026-09-09/10 | US struck five Iranian oil tankers — an escalation on the ~3-tanker strike days earlier | Al Jazeera; ABC News Australia (both 09-10) |
| 2026-09-10 | Houthis seized the Yemeni port of Mocha | Al Jazeera (09-10) |
| **2026-09-11** | **Saudi East–West pipeline (7 mb/d, the principal Hormuz-bypass route) hit by drones from Iraq** | Buttondown *Fair Value* (09-12) |
| ~2026-09-11/12 | Houthi forces captured Perim Island at Bab al-Mandeb | Buttondown *Fair Value* (09-12) |

The **measurable-leg conjunct is satisfied with room to spare**: Brent rose **+$11.35** from the 09-04 close (96.28) to the 09-10 close (107.63), and **+$6.42 on 09-10 alone** — both far above the rubric's $5/bbl bar — and the channel is named (the Iran/US/Israel conflict; Houthi Red Sea interdiction). Independently, the IEA's *Oil Market Report – September 2026* records ICE Brent at ~$105 "at time of writing," **up $21/bbl since Aug 1**, with North Sea Dated spiking to **$113.48 on 2026-09-09**.

**So the most recent qualifying event is 2026-09-11, which is the last trading day** (`state.market_calendar`: 09-11 `is_trading_day = true`; 09-12 and 09-13 are not sessions). **Zero trading days of quiet have elapsed against a requirement of 15.** The 15th trading day after 2026-09-11 is **2026-10-02**; the next scheduled scoring is **2026-10-01**, which is **14** trading days out. Hence the headline: the 2026-10-01 scoring is arithmetically incapable of de-escalating this axis, and any further qualifying event restarts the count from scratch.

**Two honest limits on the above.** (a) This is a **W3 measurement offered as evidence, not a scoring act** — M1a owns the axis and must run the test itself under the rubric's rationale-recording duty. (b) The two 09-11/09-12 items rest on a **single source** (a newsletter recap); the sub-agent flagged a second, lower-quality source as consistent but it is not relied on. That single-sourcing does **not** change the verdict, because the 09-09/09-10 cluster is multiply sourced and is itself inside the 15-day window — leg (i) fails on the corroborated events alone, and the 09-11 pipeline strike only moves the earliest-possible exit date from 2026-09-30 to 2026-10-02, both of which are past 2026-10-01.

### Leg (i)'s measurability gap — unchanged, deliberately still not filed

The gap last week recorded is real and stands: leg (i) has no warehouse source, so every evaluation of it is an off-warehouse research act, reproducible only by spending credits again. What this run adds is a sharper statement of it — the leg is **evaluable but not warehouse-derivable**, which is a different and more actionable finding than "unmeasurable."

**Still not filed as a defect, and the reason is unchanged and still operative:** the rubric's rationale-recording duty (*"the date of the most recent qualifying event; the baseline / peak / current Brent triplet; which legs held"*) is exactly the mechanism that surfaces this, and **the 2026-10-01 M1a is still the first scoring bound by it** — that scoring has not happened yet. Filing now would pre-empt a mechanism the prior cycle correctly identified, and would re-file a finding a prior cycle consciously left unfiled with a named trigger. Recorded here for that scoring to inherit.

### The re-risking limb — armed on two legs, blocked on the same third

`state.rerisking_limb_status`, measured this run:

| Strategy | DNA run start | Dwell (trading days) | leg (a) dwell ≥15 | leg (c) technical | leg (b) price | `sql_limbs_fired` |
|---|---|---|---|---|---|---|
| A | 2026-04-22 | 98 (left-censored) | TRUE | TRUE | FALSE | **FALSE** |
| B | 2026-08-05 | **26** | TRUE | TRUE | FALSE | **FALSE** |
| D | 2026-08-05 | **26** | TRUE | TRUE | FALSE | **FALSE** |
| E | 2026-09-03 | 5 | FALSE | TRUE | FALSE | **FALSE** |
| C | — (not DNA) | — | FALSE | TRUE | FALSE | **FALSE** |

A, B and D clear the dwell leg comfortably, and the technical leg passes for all five. **Leg (b) — the identical price arithmetic as rubric leg (ii) — remains the sole binding constraint fleet-wide.** Consistent with that, `events.queue_events` has still never held a `PENDING_REGIME_REFRESH` row, and M1R has found zero open items on every fire.

### The technical plane is still passing — but its margin narrowed on all three axes at once

This is new this week and it matters, because leg (c) and two strategies' own router rules read the same three values. From `events.regime_events`:

| Axis | 09-04 | 09-08 | 09-09 | 09-10 |
|---|---|---|---|---|
| `VIX_REGIME` | **LOW** 14.53 | **NORMAL** 15.72 | NORMAL 16.46 | NORMAL **17.84** |
| `SPY_TREND` | UP 770.19 | UP 765.96 | UP 762.40 | **NEUTRAL** 757.83 |
| `EQUITY_BREADTH` | HEALTHY 64.01 | HEALTHY 60.63 | HEALTHY 56.85 | HEALTHY **54.67** |

Two labelled state changes: **VIX_REGIME LOW → NORMAL** (09-08) and **SPY_TREND UP → NEUTRAL** (09-10, caused solely by SPY closing 0.4158 below its own 50d SMA; the 50d/200d relationship is unchanged and still strongly positive). Breadth held its HEALTHY label through four consecutive declining readings but now sits **4.67pp above the WEAK boundary** of 50.

**Why this is decision-relevant rather than merely descriptive:**

- **Leg (c)** requires `VIX ≠ HIGH AND SPY ≠ DOWN AND Breadth = HEALTHY`. All three still pass, but every one of them moved toward its failure boundary in the same week. If breadth breaks 50 or SPY turns DOWN, the re-risking limb loses leg (c) as well, and the book is blocked on two legs instead of one.
- **Strategy E's own router rule** is the same conjunction (`SPY ≠ DOWN AND VIX ≠ HIGH AND Breadth = HEALTHY`), and **Strategy C's** is `SPY Trend ≠ DOWN`. SPY is now **NEUTRAL**, one step from DOWN. **A SPY_TREND flip to DOWN would close C — the only strategy currently permitted to trade at all.** That is the single most consequential technical threshold in the book right now, and it is 0.4158 points of SPY away from having already moved once.

None of this is a regime call; M1a and M1b own the axes. It is recorded because the book's entire re-opening path, and its one open door, now sit close to thresholds that were comfortable a week ago.

### The system's own allocator agrees, and that is corroboration worth naming

The park allocator de-risked **twice** inside this window, unprompted by anything in this file: target risk-sleeve fraction 0 → 25% on 2026-09-08 (`c915970c`, MEDIUM 50) and 25% → 50% on 2026-09-10 (`a383d21d`, MEDIUM 55), rotating ~$3.78k of a ~$15.09k park from VOO into SGOV on the second step. One week ago the park was 100% VOO. The broker now shows **VOO 10.8278 / SGOV 74.8667**, roughly 50/50.

That is an independent, mechanically-graded read of the same macro deterioration this section measures, produced by a different routine on different inputs. It does not change any W3 conclusion and the park is D1/D2/D2a's surface — but a shock reading that the capital allocator is independently acting on is stronger evidence than one only this file sees.

**FINDING: `acute` is correct, both legs of the published exit now fail, and the exit is further away than at any point in the run.** No case for a regime change exists on the measured evidence, and none is made here. **No alert is raised and none is owed**: W3 does not score the axis; the owning re-score paths (M1a 2026-10-01, M1R on a limb firing) read this same series independently; and M1a is strategy-blind by hard file boundary, so a finding framed around which strategies are held out must not be routed to it.

---

## STRATEGY C — the only open door, and what the oil shock did to it

C has no open position, so steps 1–6 stay vacuous for it. But step 4 names C's implied-volatility regime explicitly, and it moved materially this week.

**What already happened, terminal and not to be re-opened.** `thesis-FOMC-C-20260908` was **drained NO-GO by D2 on 2026-09-08** — the fifth consecutive NO-GO in the C-FOMC series. Its grounds: the 2026-09-16 hike was priced near **56%**, genuinely two-sided for the first time; the decisive input (August CPI, due 2026-09-11) was unreleased, so any directional view was *"a bet on an unpublished print"*; and SPY IV/HV stood at **1.235** — rich, arguing for *selling* vol, while every structure affordable inside a $23.64 budget was a long-premium debit spread. Executability itself **passed** (5 verticals buildable).

**What has changed since that drain, and it hardens the NO-GO rather than softening it.** The oil shock transmitted straight into the rates complex:

- The 10-year Treasury reached its highest intraday level since October 2023, **above 4.9%** (WSJ, 2026-09-10).
- Fed-hike odds for the 09-15/16 FOMC moved from **~60%** (CME FedWatch via Barron's, 09-08) to **~75%** after the August PPI print (Investing.com), which showed diesel **+24.1% m/m** and transportation & warehousing **+2.3%**.

So the meeting that was "two-sided for the first time" at ~56% has moved decisively toward a hike. For C that raises event-implied vol into the meeting — i.e. raises the cost of exactly the long-premium structures its $23.64 budget was already unable to carry economically. **The drained NO-GO's reasoning is strengthened by subsequent evidence, not undermined by it.** W1 reports today that C's $23.64 NAV explains the drain streak, and that a second FOMC now sits in the window unenterable on tenor.

**W3 crafts nothing, enqueues nothing, and must not duplicate the terminal item.** D2 owns the C-FOMC lane. This is context for its next pass.

**One sector read-through worth a line, because it cuts the other way.** XLE gained only **+0.3%** against Brent's ~+17.6% monthly move (Buttondown, 09-12), where energy equities typically run a beta near 1.5 to crude. The equity market is not pricing this crude move as persistent. Held at its true weight: that is one data point from one source, and it argues for humility about extrapolating the shock — not against the measured fact that the overlay's exit conditions fail today.

---

## CORRECTING THIS ROUTINE'S OWN PRIOR FILE — and a measured exoneration

The MEASURE-FROM-THE-GOVERNING-SURFACE rule this routine wrote into its own spec last week worked. Three of its four checks came back clean, and the one discrepancy it surfaced turns out **not** to be a prior-run error at all.

**1. The Brent 09-04 close: 95.55 last week, 96.28 now — a SERIES RESTATEMENT, not a misread.** Measured in the raw table, `events.signal_marks` holds **two** rows for `BZUSD` 2026-09-04:

| close | `ingest_ts` | `row_uid` |
|---|---|---|
| 95.55 | 2026-09-04 | `b91369d6-8759-4f3d-8c14-56dec7b97f56` |
| **96.28** | **2026-09-06 22:51 UTC** | `26508c7e-9a10-4cf9-9850-f02785d3a20a` |

The curated view surfaces the later row. The restatement landed **13h20m after last week's W3 completed** (09:31:29 UTC). That run read 95.55 from the correct governing surface at the correct time; the surface itself moved afterwards. **The prior run is exonerated on this figure** — and per the rule, the claim is re-measured anyway rather than kept.

**2. A mechanical consequence of (1) that is not obvious, and is the one thing filed this run.** Because `brent_peak` is a running maximum over a **revisable** series, a restatement moves the peak — and therefore the retrace trigger — **retroactively**. Applying the 96.28 restatement to last week's window raises that run's peak from 95.63 to 96.28 and its trigger from **90.18 to 90.51**. Neither reading changes the verdict (95.55 > 90.18 and 96.28 > 90.51 both fail), so nothing here is an incident. But the general property is real: `state.rerisking_limb_status` recomputes live every day off the current series, so a *downward* restatement of the peak could retroactively satisfy leg (ii) for a date already scored, with no record that the threshold moved. Filed as an `ops.alerts` info row — see FILED THIS RUN.

**3. The E "≥95th-percentile divergence anchor" question: confirmed closed, third cycle running, and re-verified against the spec rather than the file.** `strategy/08_pre_mortems.md` has **no commit inside this window**; its current top revision for E is **rev 15 (2026-08-30)**, and rev 15 changed no entry criterion, exit rule, threshold, indicator or router rule — documentary route only. Rev 13 (2026-08-25, owner directive) is what dropped the percentile as an entry gate; `Strategy.md` is at **Rev 48** and its Strategy E section is **byte-unchanged in the window**. The percentile is still computed and recorded as `percentile_at_entry` and still drives pair *ranking*, but **it gates nothing**. Not re-raised.

**4. Leg (i) "cannot be evaluated" → evaluated, and failed.** Recorded above as an upgrade of the prior claim, not a correction of an error: the prior statement about the *warehouse* was and is accurate.

**No spec amendment beyond one clarifying clause is owed this cycle, and that restraint is deliberate.** Last cycle's amendment is working — it is what made this run re-read the pre-mortem instead of restating the percentile question, and what made it check `ingest_ts` instead of assuming the prior file was wrong. The single clause added to `Claude_Task_Plan.md` in this run's commit closes an ambiguity this run actually hit: the warehouse-first rule binds only where the warehouse **holds** the quantity for the date in question, so externally sourcing the one trading session the marks do not yet cover is required rather than forbidden — and a figure differing from the prior file is not by itself that file's error, because `ingest_ts` may explain it.

---

## COVERAGE STATED HONESTLY

D1 ran and completed on **2026-09-06, 09-07, 09-08, 09-09 and 09-10** — five of five expected days (09-07 was Labor Day, and D1's own records for it read "ZERO US TRADING SESSIONS IN WINDOW"). Verified **mechanically**, not by raw row count: `state.cadence_expected_history` returns **no row** with `expected AND in_service AND rows_logged = 0` for any *completed* day from 2026-09-04 through 2026-09-13. The only rows matching that filter are dated **today**, for routines whose cadence expects them today and which have not fired yet — the day is not over, and that is not a miss. 09-11 and 09-12 correctly show `expected = FALSE` for the `daily_sun_thu` class.

- **2026-09-11 (Friday) is a full trading session no internal routine has observed.** `Daily.md`'s marker is **2026-09-10**; `events.daily_marks` / the curated signal series stop at 09-10 (`marks_due_through = 2026-09-10`). The daily tier is `daily_sun_thu`, so Friday is structurally outside it; today's D1 Sunday scan covers it and has not fired yet. W1 and W2 both landed earlier today and both state the same.
- **Unlike last cycle, the gap is closed for the one quantity that mattered.** Brent's 09-11 close was **externally sourced at ~$104.61 (−2.81%)**, corroborated by two independent sources (PSU Connect; Buttondown *Fair Value*, which reports *"Brent at $104.61 is down 2.8% Friday but up 9.5% on the week and 17.6% on the month"*). **Taking that figure, leg (ii) still fails by 8.43** — so the unobserved session changes no conclusion, and this file does not have to rest on "we cannot see Friday." A third source's claim of "~$108 on the 12th" is **not established** and is discarded: ICE Brent does not trade Saturdays.
- VIX likewise pulled back on the Friday (to **15.84**, −11.2% intraday, per the same recap), which does not move the NORMAL label.

---

## OBSERVED, NOT ADJUDICATED — recorded so a future run does not re-flag them

- **The C nomadic-borrow defect is ALREADY OPEN on the board — do NOT re-file it.** Re-measured this run: `analytics.fn_nomadic_capital_restore_plan('C', 500.0)` returns **zero rows**; only C is `capital_enabled` and C is itself nomadic and excluded as its own donor, so the donor set is empty. **The loop from last week's filing worked and is documented:** W3's info row `e2eb2990` was drained by W5, routed to queue item `nomadic-borrow-recheck-C-20260906`, and closed by D2 on 2026-09-07 with disposition **"CONDITION CONFIRMED PERSISTENT"** (zero rows at all six sizes 100–5000; donor capacity $0.00). D2 then raised the durable form itself — **`6f04ff75-f81e-4736-9e5a-7a688b4a5fda`, `nomadic_borrow_blocked_unsignalled`, open since 2026-09-07T23:29:51** — noting the asymmetry against the sweep rail has *widened* now that D2a has a `nomadic_sweep_blocked` close path. Owned, signalled, persistent; re-filing would duplicate.
- **The stale funding text W3 flagged last week was fixed within a day.** D2 re-emitted `thesis-FOMC-C-20260908` on 2026-09-06T23:21:50 *specifically* to correct the stale assertion that C could borrow an uncapped amount, then drained it 09-08. The finding W3 filed as an info row reached a consumer and changed a live queue item's text before it was acted on.
- **`otr-router-shock-override-2026` was drained HOLD by AR_orc on 2026-09-09**, as last week's file predicted it would be. The HOLD explicitly *"does NOT discharge `resolves_when` — the design question is recorded as UNDECIDED, not affirmed"*, with no binding effect (Strategy.md unchanged, no capital moved), and AR_orc filed its own follow-up notice `otr_hold_verdict_has_no_resurfacing_path`. Clean loop; **W3 owes nothing here and specifically does not re-file the general "should a uniform shock override catch a market-neutral strategy" question.**
- **`premortem-C-2026-a3` cycle 18 closed SUFFICIENT** on 2026-09-06T23:22:32 (zero Tier-1 findings survived verification; the cycle-5 soft cap fired acceptance). No new cycle open. Resolved.
- **96.4% of book NAV is stranded behind E, and this is fully instrumented — do NOT re-file it.** `state.regime_capital_sync_pending` still returns exactly one row: `SWEEP / E / 15368.39 / counterparty NULL / blocked_no_recipient TRUE / blocked_reason 'no_eligible_recipient'`. Nothing moves, which is the safe outcome. D2a's `regime_sweep_blocked` warning `b40cb3e6` (2026-09-06) is open and owned. The residual is an owner decision about the roster, not W3's.
- **The park ledger is behind the broker again, same documented shape.** Both 09-10 legs (`park-derisk-buy-SGOV-20260910`, `park-derisk-sell-VOO-20260910`) still read `pending` in `state.open_orders` with `entry_window_close = 2026-09-11`, now passed, and the scheduled staging-cap check has two open `staged_order_awaiting_confirm` warnings (`af617125`, `6931b175`, both 2026-09-11 05:25). **MEASURED:** the broker holds SGOV 74.8667 and VOO 10.8278. **INFERRED, and flagged as inference:** that is consistent with *both* graded rounds having filled (2 × the staged 37.4492 SGOV = 74.8984, against 74.8667 actual), which would make this a reconciliation lag rather than a lost order — but W3 did not match fills to orders and does not adjudicate it. D2a owns Step 0 reconciliation; `bigquery/233`/`234` landed inside this window precisely to surface dead-on-arrival windows. Flagged only because a broker-vs-ledger mismatch is otherwise exactly the shape that looks alarming to a fresh reader.
- **A related sweep expired unfilled:** `sweep-VOO-20260908` expired on 2026-09-09 with its conservative default applied (`44bc4e49`, MECHANICAL). D1/D2's surface.
- **W5's two open warnings are consistent with the park churn and are owned.** `wash_sale_exposure` (VOO, ~$107.73 disallowed, `37263083`) and `regime_restore_shortfall` ($13,291.72 debt against $0 donor capacity, `be27644c`), both 2026-09-07. The wash-sale exposure is the arithmetic consequence of rotating VOO out on 09-08/09-10 having rotated it *in* on 09-03; W5 owns it.
- **`state.trading_enabled = FALSE`** with `halt_reason` *"state.freshness marks_fresh/engine_fresh not both TRUE"*. `state.staging_halt_disposition` reads `halt_is_prerefresh_artifact = TRUE`, `gate_alert_action = 'defer_to_craft_site'`, `mechanical_enabled = TRUE`, `marks_current`/`engine_current` both TRUE — the documented pre-refresh artifact (marks cover 09-10 = `marks_due_through`; `last_trading_day` is 09-11, which no D2a slot has yet had the chance to ingest). **W3 crafts no orders, so per the PRE-REFRESH HALT DISPOSITION rule it raises nothing at all.** `state.system_health.all_green = TRUE`, **zero open criticals**, 54 open alerts (49 info, 5 warning — all five named above or already owned).
- **A provider-token case drift in `ops.web_calls`**, observed while tallying this run's own telemetry: D2a wrote `provider = 'FMP'` on 2026-09-08 where every other row uses canonical lowercase `fmp`. `bigquery/203` folds case on read in all three consuming views, so this is already repaired downstream and no counter is wrong today. Recorded, not filed — D2a's surface, and the existing normalisation covers it.
- **A's `analytics.strategy_nav` row is entirely zero including `deposits`**, unlike its siblings — consistent with A having been capital-disabled and swept. Unchanged from last week, not measured to a conclusion this run, not escalated.

---

## FILED THIS RUN — one finding, on a surface W3 does not own

**The shock rubric's Brent peak — and therefore its retrace trigger — is computed off a series that can be restated after the fact, so leg (ii)'s verdict for a past date is not stable.**

Measured directly this session, not relayed: `events.signal_marks` holds two `BZUSD` rows for 2026-09-04 — 95.55 ingested 2026-09-04 and **96.28 ingested 2026-09-06 22:51 UTC** (`row_uid` `26508c7e-…`), the later of which the curated view surfaces. Because `brent_peak` is a running maximum and `state.rerisking_limb_status` recomputes live each day, that restatement silently raised last week's effective trigger from 90.18 to 90.51. A restatement in the other direction could retroactively *satisfy* leg (ii) for a date already scored — and de-escalation is **REQUIRED**, not discretionary, once both legs hold.

The rubric's rationale-recording duty pins the triplet as recorded *at scoring time*, which mitigates the audit problem but does not make the SQL limb's verdict stable between scorings. **Nothing is wrong today**: neither reading changed any verdict, past or present.

Filed per the OUT-OF-SCOPE FINDINGS rule as an `ops.alerts` **`info`** row, `source='W3'`, category `shock_rubric_brent_peak_revisable`, naming the surface (`strategy/09_regime_scoring_strategy_blind_monthly.md` §Shock / overlay grading rubric, plus `bigquery/224_rerisking_limb_status.sql`) and the nearest owning routine (M1a). **Venue consumer verified, not assumed:** W5's SPEC-DEFECT NOTICE INTAKE demonstrably drained W3's own info row inside this very window (`e2eb2990` → `nomadic-borrow-recheck-C-20260906` → D2, 2026-09-06/07). The finding is framed purely around series revisability and peak arithmetic, with no reference to which strategies are held out, so it does not collide with M1a's strategy-blind file boundary.

**What W3 did NOT do, stated explicitly:** it did not score or re-score any regime axis, did not touch `bigquery/224` or the rubric file, did not edit a queue item, did not craft, block or size anything, did not re-file the three findings already open (`nomadic_borrow_blocked_unsignalled`, `regime_sweep_blocked`, the leg-(i) measurability gap), and did not decide whether C should be funded.

---

## STEPS 1–6, DISPOSED

Stated rather than omitted, so "missing" is never mistaken for "skipped."

1. **Current thesis status** — no thesis in scope. Vacuous.
2. **Competitive landscape** — no position whose peers matter. Vacuous.
3. **Fundamental developments** — no position to accrue evidence against. Vacuous.
4. **Sector and macro context** — the only step with in-scope content, discharged in full by the shock-overlay measurement, the technical-plane narrowing, and the Strategy C implied-vol section above.
5. **Thesis-invalidation signals** — no criteria live. Vacuous. (D1 covered the D book's criteria on every scanned day — "12 open tranches evaluated, 0 flagged" on each of 09-06 through 09-10; out of scope here.)
6. **Time-to-thesis-resolution** — no resolution window open. Vacuous. Per spec W3 checks no convergence targets, time-exit dates or option-expiry mechanics in any case: D1's connector sweep is the sole detector, D2 the sole converter.

---

## WHAT W4 OWES ON THIS FILE — nothing, stated affirmatively

- **No `WEEKLY-THESIS-ACTION` flag.** No hold, no weekly-thesis-action, no further-research recommendation — there is no open in-scope position to carry one.
- **Zero queue-convertible items.** No research-deferral checkpoint, no thesis action for D2 to revalidate.
- **Cross-strategy deconfliction is vacuous** with zero open in-scope positions. Noted only for shape: names on W1's A-queue overlap open Strategy D tranches (GOOGL, GEV, AMZN, TSM among them) — not a conflict, since A has no positions and is double-blocked, and A and D are separate mandates permitted to hold the same name.
- **The C FOMC thesis is TERMINAL, not pending.** `thesis-FOMC-C-20260908` was drained NO-GO on 2026-09-08 — unlike last cycle, there is no live C item to avoid duplicating. Any new C candidate is W1's to shortlist and W4's §D to enqueue on its own terms, under C's `SPY Trend ≠ DOWN` router rule, which is now one step from failing.
- **The shock-overlay measurement is evidence, not a referral.** W4 need not convert it and **must not route it to M1a** (blinding).
- **One `ops.alerts` info row was raised by this run** (`shock_rubric_brent_peak_revisable`). It is a spec-defect notice for W5's intake, not a W4 conversion.

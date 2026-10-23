# Symmetric shock / refresh design (Strategy.md Rev 52)

*Owner directive, interactive session, 2026-10-22.* The owner's words: "I want an overhaul. The speed/rules to raise and lower should be equal for all." The owner then chose, from the options offered:

- **Scope:** the shock / overlay grading rubric AND the out-of-cycle refresh (scenario 3's de-risking triggers vs its re-risking limb). The one-directional reconciliation overrides (Strategy.md `### Router activation rule` "Operative effect", and the reconciliation rules under the router) are **out of scope and unchanged**.
- **Speed:** fast both ways. No dwell, no quiet window and no confirmation window in either direction. A grade or trigger moves at the first scoring or run whose measurement reads the other way.
- **Oil plateau:** add a plateau re-base, so a new, stable level of oil stops counting as an ongoing shock. The same rule applies whether the plateau sits above or below the old baseline.

This file is the single source for the Rev 52 change across `Strategy.md`, `bigquery/263_shock_price_leg_status.sql` and `Claude_Task_Plan.md`. Where they disagree, this file wins until the change lands.

## Why

Rev 48 (2026-09-05, owner directive) wrote the rubric to give `acute` an exit. That exit was deliberately slower than the entry: any one qualifying event raised `acute` at once, while lowering needed 15 quiet trading days AND a 50% Brent retrace. `none` needed 60 quiet days. The only evidence cited was a three-scoring calibration (07-01 `latent`, 08-01 `acute`, 09-01 `acute`) showing the rubric reproduced past judgment; no measurement supported the asymmetry itself. Scenario 3 had the same shape: any ONE deterioration trigger fired a refresh, but re-risking needed ALL THREE legs plus a 15-trading-day dwell ("fast to protect and slow to re-engage"). Rev 52 replaces both with symmetric rules.

## 1. Shock / overlay grading rubric (Strategy.md `### Shock / overlay grading rubric`)

**Unchanged:** the qualifying shock event definition, the pre-shock baseline definition (including the `state.signal_marks_curated` / `BZUSD` source trap) and the shock elevation definition, apart from the plateau re-base below. Also unchanged: the rationale-recording duty (now also recording any re-base), the revisable-series rule (the triplet recorded at scoring time anchors the verdict) and the token set `none / latent / acute`.

**New: qualifying resolution event (the mirror of a qualifying shock event).** A dated development that:

- (i) meets input category 4's structured criteria in the reverse direction: trade flows restored, an oil price move greater than $5/bbl DOWN attributable to the channel's resolution, a narrowing in sovereign credit spreads, or a major currency reversing more than 2% against USD; AND
- (ii) is attributable to the resolution of the named channel: a ceasefire or settlement in force, a blockade lifted, a tariff regime removed, or a sanctions posture settled.

Narrative de-escalation with no measurable leg is not a qualifying resolution, mirroring the rule for escalation (per 2.4). A price move is read over the same two-session window the plan already uses for a qualifying event.

**Shock structure.** The first qualifying event opens a structure. A qualifying resolution event of that structure's channel closes it.

**New: plateau re-base (symmetric).** The re-base fires when BOTH of these hold:

- (a) all of Brent's trailing 10 trading-day closes, including the scoring session, lie within ±5% of their own median. Read the stored curated `BZUSD` series as recorded; a front-month roll gap is not adjusted.
- (b) no qualifying (escalation) event is dated within those 10 sessions.

When it fires, the baseline becomes that 10-session median and the shock elevation is set to ZERO, so the price leg reads NOT ELEVATED. It stays zero until the next qualifying event. After that event, the elevation is the peak close since that event minus the re-based baseline.

The re-base applies whether the plateau sits above or below the prior baseline. It is a re-measurement, not a grade change on its own. The rationale records the window, its median and N.

**Legs.** Each leg is read on the scoring date alone. Each has ONE threshold, applied identically whichever grade the axis currently holds.

- *Price leg* ELEVATED ⇔ the elevation is greater than 0 AND the current Brent close is at or above baseline + 50% of the elevation (the midpoint). This one threshold replaces both Rev 48's "Brent still pricing the channel" transmission reading and its 50%-retrace downgrade leg, so up and down use the same line.
- *Sovereign-spread leg* and *FX leg*: ACTIVE ⇔ measured AND attributed to the named channel per category 4's thresholds, as the axis already records them. A leg that cannot be measured is NOT active (current practice, see the 2026-10-01 scoring).

**Grades.**

- `acute` ⇔ a structure is open AND at least one leg is ELEVATED or ACTIVE.
- `latent` ⇔ a structure is open AND no leg is elevated or active.
- `none` ⇔ no structure is open.

A qualifying shock event while the axis reads `none` opens a structure; the grade then follows from the legs read on the scoring date: `acute` if any leg is ELEVATED or ACTIVE, otherwise `latent`.

**Retired:**

- the 15-trading-day event-recency leg of `acute`;
- the 15-quiet-day + 50%-retrace downgrade requirement;
- the 60-quiet-day condition for `none`;
- the "Escalation is immediate, and the asymmetry is deliberate" paragraph.

Replace that paragraph with a symmetry statement: every transition, in either direction, uses the same test and takes effect at the first scoring (M1a monthly, or M1R out-of-cycle) whose measurement reads the other way. There is no dwell, quiet period or confirmation window in either direction.

**Incomplete evidence is symmetric too.** If a scoring cannot complete the event sweep that a leg or a re-base needs, the axis keeps its STANDING value, whatever it is. It does not default to `acute`, and it does not default to lower.

**Calibration.** Rev 48's own calibration clause says a rubric that re-grades history differently is a new rule that must be argued as one. Rev 52 IS a new rule, argued by the owner directive above. It is not claimed to reproduce the axis's history, and no previously scored grade is re-graded (the revisable-series rule still applies). The adoption-day measurement is recorded in the Rev 52 changelog, not in the rubric, so the blind scorer is never handed a triplet it did not measure.

**Adoption-day measurement (goes in the Rev 52 CHANGELOG paragraph only, never in the rubric section):**

| Item | Value |
|---|---|
| Baseline | 87.20 (the 10-01 scoring's value) |
| Peak | 109.86 on 2026-10-16 (exceeds the 108.75 the 10-01 triplet used) |
| Midpoint | 98.53 |
| Current | 108.82 (2026-10-21) |
| Plateau window | 2026-10-08..2026-10-21, closes 104.28 to 109.86 |
| Plateau median | 106.125 (band 100.82 to 111.43) |

The price leg is ELEVATED unless the re-base fires. All ten closes lie inside the band, so price half (a) holds; whether the re-base fires turns on half (b), whether a qualifying event is dated 2026-10-08..10-21, which is the scorer's judgment. Equal speeds alone would therefore not have lowered the 2026-10-21 grade.

## 2. Out-of-cycle refresh (Strategy.md `### Pre-mortem: Regime router` → §6, scenarios 1 and 3)

Every trigger gets a mirror. ANY ONE trigger, in either direction, makes an out-of-cycle fundamental refresh permitted and required (disjunctive both ways).

| De-risking trigger (existing unless marked new) | Mirror re-risking trigger (new) |
|---|---|
| VIX Regime crosses NORMAL→HIGH (`vix_regime_high`) | VIX Regime leaves HIGH (`vix_regime_exit_high`) |
| SPY Trend flips to DOWN (`spy_trend_down`) | SPY Trend leaves DOWN (`spy_trend_exit_down`) |
| Qualifying geopolitical event (`geopolitical_qualifying_event`, D1-flagged, when standing is NOT `acute`) | Qualifying resolution event (`geopolitical_qualifying_resolution`, D1-flagged, when standing is `acute` or `latent`) |
| NEW: shock price leg turns ELEVATED while standing `shock_overlay = latent` (`shock_price_leg_entry`) | Shock price leg turns NOT ELEVATED while standing `shock_overlay = acute` (`shock_price_leg_exit`) |
| Scenario 1: breadth falls more than 10 points month over month (`breadth_mom_drop_gt10`) | Breadth rises more than 10 points month over month (`breadth_mom_rise_gt10`) |
| Scenario 1: VIX rises more than 5 points over 30 days, ending in NORMAL (`vix_drift_gt5_ending_normal`) | VIX falls more than 5 points over 30 days, ending outside HIGH from a start outside HIGH (`vix_drift_down_gt5`); a fall that starts in HIGH belongs to `vix_regime_exit_high` |

**Price-leg pair gating (review fix).**

- `shock_price_leg_entry` fires only under a standing `latent`. Under `acute` the axis cannot rise further.
- `shock_price_leg_exit` fires only under a standing `acute`, where it asks whether the axis should lower to `latent`. Under `latent` the price leg cannot lower the grade (below `latent` needs a qualifying resolution event), so the exit does not fire there: each price-leg trigger fires only in the state whose grade it can move.

**Which price-leg runs fire (review fixes, rounds 3 and 4; replaces the round-2 re-arm wording).** A price-leg run is the unbroken sequence of proxy sessions reading one half's condition.

**The scorer read session** is the last `BZUSD` session strictly before the latest `shock_overlay` scoring row's `as_of_date` (M1a or M1R) that was ALREADY STORED when that scoring was written: its `state.signal_marks_curated` `ingest_ts` is at or before that row's `event_ts`. Both halves bind:

- A scoring cannot read a session at or after its own `as_of_date`. M1a fires before the open and can finish the next day: the `as_of_date` 2026-10-01 row, written 2026-10-02, recorded current 98.03 for 2026-09-30.
- A scoring cannot read a close that is not yet stored. A Sunday M1R (13:00 UTC) cannot see Friday's close, which D2a ingests at about 22:40 UTC that Sunday.
- A restated mark carries a later `ingest_ts`, so it can only move the read session earlier, toward firing.
- Validated live (read-only, 2026-10-23): the real latest scoring (`as_of_date` 2026-10-01) gives 2026-09-30; a simulated Sunday 2026-10-18 M1R gives 2026-10-15; a simulated Monday 2026-10-19 M1R gives 2026-10-16.

**The run rule.**

1. A run that began at or before the scorer read session was read by that scoring.
   - Under a standing `acute`, the EXIT RE-ARMS 10 trading sessions after the scorer read session if that same run is still going. A scoring can HOLD `acute` because a qualifying event sits inside the plateau window; when that event leaves the window, the plateau's event half can clear with no new price signal. A re-score that again holds `acute` moves the scorer read session forward, so the re-arm costs at most one re-score per 10 sessions.
   - Otherwise (the entry under `latent`), the run it read is answered and does not fire again.
2. ANY run that began after the scorer read session fires at its start, including a new exit run that starts inside the 10-session re-arm window after an earlier read run ended.

**The four shock-axis triggers are refresh-only, in both directions (owner decision, round 3).** `geopolitical_qualifying_event`, `geopolitical_qualifying_resolution`, `shock_price_leg_entry` and `shock_price_leg_exit` get NO same-evening router review and NO activation, state or call write from D2.

- D2 writes only the trigger's LOG entry: its `router-review` row, with `fields.measured_trigger`, `trigger_run_start` and `trigger_direction`, tagged refresh-only. D2a's REFRESH REQUEST queues the blind M1R re-score as before.
- Activation changes only when that re-score actually moves `shock_overlay`, through D2 ROUTER EVERY-RUN DUTIES (ii), the SCORED OUT-OF-CYCLE `FUNDAMENTAL_AXIS` CHANGE path (about two sessions after the trigger).
- Why: the shock axis is graded only by the blind scorer. Under `acute` a re-engaging review could not activate a bound strategy until the re-score anyway, so same-evening protection made raising faster than lowering. Refresh-only makes both directions wait for the same re-score.
- Consequence, stated plainly: before Rev 52 a D1 qualifying-geopolitical-event flag got a same-evening protective review. It no longer does.
- A general D1 `router_review` flag about a development that is NOT a qualifying shock or resolution event keeps its existing item-4 review path, unchanged.
- The round-2 lapse of an unconfirmed de-risking shock trigger's protective calls is DELETED: with no same-evening shock review, there are no such calls to lapse.

These rules live in the router pre-mortem's scenario 3 and in D2 only, never in the blind rubric section.

**Retired:** the Rev 46 / Rev 48 re-risking limb's conjunctive structure, its leg (a) 15-trading-day DO-NOT-ACTIVATE dwell, and its legs (b) and (c) as joint conditions.

**Unchanged:**

- "REFRESH, never a flip". A refresh re-runs the blind M1a machinery via M1R.
- The M1a/M1b blinded split.
- D2a stays the sole writer of `PENDING_REGIME_REFRESH`.
- Reconciliation overrides stay one-directional and out of scope. While `shock_overlay = acute`, the Shock Transmission Register still binds A–D, so a re-engaging review cannot activate them.

**Same-evening router review (D2 item 4), symmetric: the eight technical-plane triggers only.** It applies to `vix_regime_high` / `vix_regime_exit_high`, `spy_trend_down` / `spy_trend_exit_down`, `breadth_mom_drop_gt10` / `breadth_mom_rise_gt10` and `vix_drift_gt5_ending_normal` / `vix_drift_down_gt5`, never to the four shock-axis triggers above. A de-risking trigger scopes the review to strategies NOT at DO-NOT-ACTIVATE, with the existing protect-direction pins (unchanged). A re-risking trigger scopes it to strategies AT DO-NOT-ACTIVATE (the `bigquery/98` predicate).

A re-engaging review keeps the same rails, mirrored:

- It never writes ACTIVATE for a strategy whose own technical line reads DO-NOT-ACTIVATE.
- It never writes ACTIVATE where a reconciliation rule binds on the standing `FUNDAMENTAL_AXIS` values. For `acute`, that means `state.shock_transmission_status.override_applies` = TRUE.
- Where the technical line reads ACTIVATE but the standing fundamental call is DO-NOT-ACTIVATE, it does NOT resolve that in-session. It uses the existing daily technical-flip divergence path (`divergence-review` enqueue / held state), exactly as pin (2) does in the protect direction.

Every serviced trigger, reviewed or refresh-only, in either direction, logs one `router-review` decision-log row (the idempotency key) and feeds D2a's refresh request on its next run.

## 3. SQL: `state.shock_price_leg_status` (bigquery/263_shock_price_leg_status.sql)

A read-only view: the mechanical price half of the rubric, used as a refresh TRIGGER proxy only. The scorer's recorded triplet stays authoritative for the grade. There is one row per `BZUSD` `mark_date` (from `state.signal_marks_curated`, never the raw table) from the structure anchor through the latest mark.

**Anchor.** Read `events.regime_events` scope `FUNDAMENTAL_AXIS` key `shock_overlay`, latest row per `as_of_date`, with `bigquery/01`'s `ORDER BY event_ts DESC, event_id DESC` tiebreaker.

- The anchor is the first `as_of_date` of the most recent `acute` run inside the current non-`none` run.
- If that run contains no `acute`, the anchor is the start of the current non-`none` run.
- If the latest value is `none`, the view returns zero rows.

**Baseline.** The median of the 60 `BZUSD` closes strictly before the anchor, or of all available closes if fewer than 60 (this is `bigquery/224`'s convention). With zero baseline observations, the view returns zero rows.

**Columns:**

- `mark_date`
- `shock_overlay_state` (the latest value, the same on every row)
- `structure_anchor`, `brent_baseline`, `brent_baseline_obs`
- `brent_close`
- `brent_peak` (running max from the anchor through this `mark_date`)
- `brent_midpoint` (baseline + 0.5 × (peak − baseline))
- `plateau_median`, `plateau_obs` (the trailing ≤10 BZUSD rows including this one, computed over the FULL curated series before the rows are filtered to `mark_date >= structure_anchor`, so the first rows after the anchor still see a full window)
- `plateau_band_holds` (TRUE only when `plateau_obs` = 10 AND every close in the window is within ±5% of `plateau_median`)
- `price_leg_elevated` (`brent_peak > brent_baseline AND brent_close >= brent_midpoint AND NOT plateau_band_holds`)
- `basis` (`'plateau_band'` when the band holds, else `'no_elevation'` when peak ≤ baseline, else `'elevated'` / `'retraced'`)

**Known proxy gaps, stated in the file header:**

- The view anchors at the `acute` run start. M1a anchors at the first qualifying event, so the 2026-10 baselines differ (about 84.7 vs 87.20).
- The plateau's event half (b) is not SQL-measurable. The view applies the price half only, so on any one session it errs toward firing a refresh. A false positive costs one blind re-score. The event half can still clear with no new price signal, so under `acute` D2 re-arms a still-running exit 10 sessions after the scorer read session (§2).
- Stale anchor under `latent`: the view keeps the most recent `acute` run's anchor, baseline and peak. An entry false positive this causes costs one blind re-score, which rejects it. The trigger is refresh-only, so it writes no activation in the meantime.

**Consumers (V19).**

- D2 item 4's DETECT query, for the triggers: the exit under a standing `acute` only, the entry under `latent` only, both under the run rule in §2. A run that began at or before the scorer read session (§2's definition) was read by that scoring and does not fire again, except that under `acute` the exit re-arms 10 trading sessions after the read session if that same run is still going. ANY run that began after the read session fires at its start, including a new exit run that starts inside the re-arm window after an earlier read run ended.
- W3, for reporting only: its MEASURE FROM THE GOVERNING SURFACE paragraph reads the view as the mechanical price-leg proxy between scorings. It drives no trigger and no grade.

`state.rerisking_limb_status` (`bigquery/224`) is RETIRED. No consumer reads it after Rev 52. It stays defined live (it is not dropped), so apply-in-order replay and live parity are unaffected. It carries an appended retirement marker that names `bigquery/263` and Rev 52.

## Blinding (binding on every edit)

M1a and M1R are strategy-blind. Routines read the WHOLE `Claude_Task_Plan.md`, and M1a/M1R load `strategy/09_regime_scoring_strategy_blind_monthly.md`.

- In Strategy.md's `## Regime scoring (strategy-blind, monthly)` section (which includes the rubric), and in the M1a and M1R sections of `Claude_Task_Plan.md`, never mention strategy codes as strategies, activation states or calls, the Shock Transmission Register or its bindings, reconciliation overrides, positions, capital, D2's review scope, or any consequence of a grade for a strategy.
- Those facts belong in the router pre-mortem's scenario 3 (Strategy.md) and in D1/D2/D2a/W1 (plan) only.
- Never quote a non-blind routine's verdicts or values into a blind section as evidence.

## 4. Fleet instructions (Claude_Task_Plan.md)

- **D2 item 4**: the measured-trigger DETECT query gains the mirror triggers and the shock price-leg triggers, using the same run-start and serviced-once semantics, plus the price-leg pair's gating and the run rule in §2 (the scorer read session as §2 defines it: the last `BZUSD` session strictly before the latest scoring row's `as_of_date` whose curated `ingest_ts` is at or before that row's `event_ts`; the exit's re-arm under `acute` while that same run is still going; any run that began after the read session fires at its start, even inside the re-arm window). The four shock-axis triggers are refresh-only: a log row only, no SERVICE and no activation write; activation follows a moved `shock_overlay` through ROUTER EVERY-RUN DUTIES (ii). SERVICE, scoped per direction with the re-engaging rails, covers the eight technical-plane triggers only. The round-2 protective-call lapse is deleted. The "fast to protect and slow to re-engage" framing is superseded.
- **D1 REGIME CHECK**: it can also flag a qualifying resolution event, which D2 logs as the refresh-only trigger `geopolitical_qualifying_resolution`. A qualifying shock event flag (`geopolitical_qualifying_event`) is refresh-only too, so it no longer gets a same-evening protective review.
- **D2a**:
  - The RE-RISKING LIMB EVALUATION substep is retired. It no longer reads `state.rerisking_limb_status` or raises `rerisking_limb_fired`.
  - The DE-RISKING REFRESH REQUEST substep becomes a single REFRESH REQUEST for every measured trigger in both directions.
- **M1a, and M1R (STEP 2 / 2a)**: score `shock_overlay` per the Rev 52 rubric. An incomplete event sweep holds the STANDING value only where the unswept sessions could change the grade (no longer "holds `acute`").
- **M1R STEP 1b**:
  - The deferral is keyed to M1a's actual monthly run, not to the calendar: M1R defers whenever M1a has no completed run this month, on any day of the month.
  - The covered path uses the covering snapshot's cut instant, `LEAST(MAX(event_ts), TIMESTAMP(as_of_date, 'America/New_York'))`, never its write time alone.
- **D3 queue-staleness scan, clause (e)**:
  - For a `PENDING_REGIME_REFRESH` item, D3 does not count those M1R deferral days through the month's third trading day (the period grace day), then counts them normally.
  - D3 never counts a day whose owner slot precedes the item's creation.
- **M1R event sweep**: states the anchor-candidate rule and where the sweep window starts.
- **M1a**: pins the FX-leg test; M1R applies the same test by reference. The FX reference close is anchor-dependent where anchor candidates could change the structure's first qualifying event.
- **W1**: counts only completed M1b runs.
- **M1R STEP 4**: keeps resolving any legacy open `rerisking_limb_fired` rows.
- **Any routine that derived a gate date from `state.rerisking_limb_status`**: the gate date becomes the earlier of the next scheduled M1a/M1b re-score and the due date of any open `PENDING_REGIME_REFRESH` item.
- Historical run outputs (`Daily.md`, `Weekly_*.md`, `Watchlist.md`, `OWNER_ACTIONS.md`, `ops/spikes/`) are records and are not edited.

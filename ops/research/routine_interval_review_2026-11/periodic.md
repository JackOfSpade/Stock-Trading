# Interval review, periodic group (2026-11-03)

Group: M1a, M1b, M2, M3, M4, M5, SL1, SL4, Q1, Q2, Q3, Q4, A1, A2, A3.

## Bottom line

KEEP every interval. No cron change is proposed.

- The group is about 3.3 h of the fleet's 105 h in 60 days, after correcting the SL1 figure below. Even halving all of it saves under 2%.
- Most of the saving available here already landed on 2026-11-02 as the owner's ROUTER-GATED SCAN RULE. It applies to M2 PART 2, M4 section E, Q2 and Q4 section A. It has not run yet, so its saving is an estimate until 2026-12-01 (M2) and 2027-01-02 (Q2).
- Lengthening a period would increase harm from a failure that already recurs. Scheduled fires went missing in 2 of the last 4 monthly cycles and 2 of the last 2 quarterly cycles.

## Correction to the supplied table

SL1 "2.1 h" is an artifact. SL1 ran twice on Denver run_date 2026-10-19, and the second run appears to have paired with the first run's `started` row, hitting the 2 h cap (inferred). Pairing each terminal row with its nearest preceding `started` gives 6.6 + 3.7 + 5.5 = 15.8 min, or about 0.26 h. Group total falls from about 5.1 h to about 3.3 h.

## What I measured

All queries ran through execute_sql_readonly on stock-trading-498512.

| Measure | Source | Result |
|---|---|---|
| Every terminal run and note since 2026-06-01 | `ops.run_log`, routine in group, status != started | 15 routines read |
| Run minutes | terminal row minus nearest prior `started` | table below |
| Axis moves per cycle | `events.regime_events`, scope FUNDAMENTAL_AXIS | 2, 3, 2, 3, 1 of 5 axes moved across the five cycles from 06-01 to 11-01 |
| M1R re-scores | same, 10-28 and 11-02 | 0 axes moved on both (M1R is outside this group) |
| Router state | `state.current_regime` STRATEGY_ACTIVATION | A, B, D, E DO-NOT-ACTIVATE; C HYBRID (FOMC-only) |
| Fills by strategy | `events.trade_fills` | B 34, D 16, every other strategy 0, so E has never traded |
| E theses | `events.decision_log`, strategy E | thesis-construction: NO-GO on all 10 current rows |
| Candidates all-time | `state.strategy_candidates` | 4 (F, G, H, I), all REJECTED; sources SL1, SL1, A1, owner; none from Q1, Q3 or D1 |
| Retirement signals | `events.decision_log` entry_type `strategy-retirement-signal` | 0 rows all-time |
| CRM exit | `events.decision_log`, ticker CRM | D2 staged it 2026-08-26 on the print, 6 days before the next M3 |
| Register staleness | `state.shock_transmission_status` | `gate_max_age_days` NULL on every row; every row binds with no gate |
| Period monitor | `state.cadence_period_watch` | all sampled rows `period_missed` FALSE |
| Alerts | `ops.alerts`, source in group, since 06-01 | `missing_dependency` critical: M1b 3, M4 3, M5 2, SL4 2, SL1 1 |
| Slice size | `wc -c task_plan/*.md` | shared preamble 198,904 bytes in every slice |

### Runs and minutes (completed unless marked)

| Routine | Minutes per run |
|---|---|
| M1a | 8.6, 20.9, 15.7, 14.3, 7.3 |
| M1b | 2.1, 11.4, 13.9, 5.3, 10.5; halted 54.5 and 60.0, mostly dependency polling |
| M2 | 19.8, 47.1, 104.5, 62.2, 27.9, 35.4 |
| M3 | 11.3, 18.3, 21.7, 19.8, 8.8, 12.3 (plus one 0.0 re-trigger no-op on 07-01) |
| M4 | 2.6, 11.9, 13.2, 8.8, 6.3 |
| M5 | 4.5, 7.2, 8.4, 3.7, 3.7 |
| SL4 | 3.1, 6.4, 8.5, 3.5, 4.2 |
| SL1 | 14.9, 17.9, 3.0, 6.6, 3.7, 5.5 |
| Q1 | 12.4, 10.7 |
| Q2 | 14.5, 21.7 |
| Q3 | 13.4, 16.9 |
| Q4 | 6.8, 6.5 |
| A1 | 73.4, 151.6 |
| A2 | 22.9 |
| A3 | 17.9 |

## Findings across the group

### Missed fires make longer periods riskier

- M1a produced no run on 2026-08-01 or 2026-10-01. Each time M1b, M4, M5 and SL4 halted, and the chain was re-run 1-2 days later.
- Q4 has no 2026-10-02 row and completed 10-06. SL1's quarterly fire was missed on 07-02 and 10-02.
- Today a missed monthly fire costs days. At a quarterly cadence the same miss would leave a stale period if catch-up also failed.
- M4, Q4, A3 and SL4 are never auto-refired, so they rely on a manual catch-up.

### Dependency changes are not cron-only

Any period change touches all of these:

- `ops/cadence.yaml`, including `monitor_class`
- `bigquery/24_cadence_period_watch.sql` and `bigquery/114_period_aware_dependency_gate.sql` (generated lists)
- `bigquery/31` and `bigquery/59` catch-up lists when catchup_safe
- `ops/triggers.json` (generated) and `ops/routine_backup.json`
- the live trigger, `Claude_Task_Plan.md` and the regenerated slices

Two specific traps:

- `sp_assert_deps` windows period dependencies by period. Moving Q1 or Q3 to semiannual would halt SL1 in any uncovered quarter, unless SL1's `depends_on` changes as well.
- M4 reads the M1b, M2 and M3 markers for the current month, so none of those three can skip a month without changing M4's freshness check.

### No-op cost is not a useful lever here

These routines rarely fire with nothing to do. Of the 14 completed monthly-chain runs in 60 days (M1a to M5 plus SL4), the only 0-row runs are the 2 M1b rows, and those are 0 by design because M1b's output is a repo file. Own sections range from 7.6 KB to 47 KB on top of the 199 KB preamble. That preamble matters far more for the fleet's daily no-op routines than for these.

## Per routine

### M1a, monthly, 245,829 bytes: KEEP

- Measured: at least one axis moved in all five cycles, 11 of 25 axis readings in total.
- Breaks if longer: the router reads a stale regime, and M1R cannot substitute. M1R runs only when a trigger is serviced and does no macro ingest, and it reproduced the standing values both times.
- Worst case: a stale regime silently holds strategies in the wrong activation state for up to a quarter. This affects money.

### M1b, monthly, 207,724 bytes: KEEP

- The 0-row reading is a proxy failure. M1b writes `Monthly_Fundamental.md`, which M4 consumes.
- Its raw calls changed materially: E flipped to ACTIVATE on 09-01, and D flipped away from ACTIVATE on 11-01.
- Worst case: activation calls lag regime moves, and M4 halts on its dependency.

### M2, monthly, 207,266 bytes: KEEP the cron; use the landed gate

- Measured: 78-83 metered web calls plus about 400 IBKR calls per run. It is the most expensive monthly routine at 1.1 h per 60 days.
- Payoff so far is low: E has 0 fills and its thesis rows are all NO-GO.
- The right lever already exists. Since 2026-11-02, a GATED E does no PART 2 research. E is currently GATED, so 12-01 should be the first cheaper run.
- Estimate: about 30% saved while E stays gated, based on 5 of 13 workers on 11-01 being PART 2 research. UNVERIFIED until 12-01.
- PART 1 is named "never gated" router evidence by that same owner directive, so I do not propose cutting it. Nothing trips on its staleness today because `gate_max_age_days` is NULL, but `bigquery/257` fails closed if a future register row sets an age gate.
- Worst case if the cron were cut: a stale pair list at an E re-enable, and M4's marker check would halt.

### M3, monthly, 206,944 bytes: KEEP

- Measured: all HOLD and 0 at-entry breaches in the five latest cycles. The one exit (CRM) was caught by D2 on the print, not by M3.
- That argues M3 is not the primary fast check, but it remains the only review of multi-year thesis drivers for D. W3 covers A, B, C and E only.
- Print-free windows are already cheaper: 11.3 and 8.8 min on the quarter-start cycles against about 20 min on 09-01 and 08-03.
- The owner rule lists held-position work as never gated.
- Worst case: a slow thesis break that no at-entry criterion captures, on 8 real positions, stays unseen for up to a quarter. Silent, and it affects money.

### M4, monthly, 242,154 bytes: KEEP

- Measured: 9-15 rows per cycle, with 3 or 5 divergence reviews queued each month. No orders crafted in the 09-01, 10-02 or 11-01 notes I read.
- Its value is conversion plus section H (30-trade and m2m gates) and the pre-mortem walk, which M5 checks.
- Section E is already gated.
- Worst case: divergence reviews and pre-mortem loci are skipped for months.

### M5, monthly, 210,685 bytes: KEEP

- 3.7 min per run, BigQuery only. Its horizon is 21 trading days, so a longer interval would leave most of the period unforecast.
- Advisory only, but M4 section H reads it and it holds the walk-presence check on M4.
- Worst case: lost early warning and an unnoticed missing pre-mortem walk. Saving would be under 0.1 h per 60 days.

### SL1, monthly, 227,093 bytes: KEEP (owner decision 2026-10-25)

- One monthly fire so far (11-02, 5.5 min, 25 rows, 2 leads opened). Too thin to judge, and 4 of 4 candidates rejected is the default-REJECT rail working.
- Worst case: the owner's chosen candidate rate is undone on one data point.

### SL4, monthly, 210,232 bytes: KEEP

- Measured: 0 proposals in 5 completed runs, and 0 retirement-signal rows all-time.
- Edge decay needs a signal sustained for 2 or more quarters, so quarterly would be defensible on signal grounds.
- But the saving is about 0.07 h per 60 days, against lockstep edits to monitor class, generated lists, trigger and plan. Not worth it.
- Mechanical kill triggers do not depend on SL4.
- Worst case if cut: a dominated strategy lingers up to 3 months longer.

### Q1, quarterly, 208,315 bytes: KEEP

- Backward-looking factbase with no actions, and 0 candidates ever. Semiannual is thinkable, but it saves about 0.1 h and requires an SL1 dependency edit, or SL1 halts.
- Worst case: SL1 fails closed for a quarter.

### Q2, quarterly, 207,281 bytes: KEEP the cron; use the landed gate

- With D GATED, Q2 now skips PART 1 and PART 2 and carries the shortlist forward.
- Estimate: about 90% saved while D stays gated. UNVERIFIED until 2027-01-02.

### Q3, quarterly, 218,220 bytes: KEEP

- Drives the model-version and foundation-change protocol. 7 rows on 07-01 and 152 on 10-02 (row composition not checked).
- Worst case: a foundation or model change goes unassessed for six months.

### Q4, quarterly, 220,520 bytes: KEEP

- 6.5-6.8 min. Section A is gated. It also holds the step E trigger audit and foundation-change conversion.
- Not auto-refired, and it already slipped to 10-06.
- Worst case: foundation assessments and the audit slide by a quarter.

### A1, A2, A3, annual, 228,954 / 206,479 / 218,799 bytes: KEEP

- Each has only one real cycle (07-27/28, off-slot). The first scheduled fire is 2027-01-01, about 5 months later, and that gap is a side effect of the late first run.
- UNVERIFIED: whether a 5-month re-run is worthwhile. A one-off shift could save A1's 73-152 min, but the plan's anniversary wording leaves this to the owner, and I did not assess its dependency effects, so I am not proposing it.

## Worth the owner's attention, but not interval changes

1. **Advisory tail routines can hold the trading gate.** On 2026-10-02, M4's note records `state.trading_enabled_mechanical` FALSE on 2 open criticals, the `missing_dependency` alerts from M5 and SL4. Those two routines stage no orders. I did not assess a fix.
2. **Day-1 crons fire before month-start data.** The M chain fires on calendar day 1, including weekends. M1R's 11-02 rationale says October ISM and jobs were still unreleased. M1a's own alert `m1a_calendar_day1_cron_precedes_month_end_marks` is related. This is a timing question, not a frequency one.
3. **Monthly divergence reviews drive AR load.** M4 queued 5 reviews on 08-03, 09-01 and 11-01, and notes call them one regime disagreement "refracted five ways". The AR reviewer should weigh this, since the cost lands in AR_att and AR_orc rather than here.

## UNVERIFIED

- Token cost per routine. Run minutes are only a rough proxy.
- Actual savings from the ROUTER-GATED rule, which has not run.
- Whether Q4 and SL1's 10-02 misses share a cause with M1a's 10-01 miss. M1a's note infers a fleet-wide trigger touch; I did not check that.
- The `missing_dependency` counts come from `ops.alerts` source attribution only.

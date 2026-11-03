# Interval review, group AR_att / AR_orc / SL2 / SL3 / SL5 (2026-11-03)

Read-only review. Nothing was changed except this file. These are proposals, and none of them is applied.

## Bottom line

| Routine | Current | Proposed | Lever | Real-work days in 60d |
|---|---|---|---|---|
| AR_att | Sun-Thu, 00:00 UTC | KEEP | early-exit gate | 7 of 41 (17%) |
| AR_orc | Sun-Thu, 00:35 UTC | KEEP | early-exit gate | 6 of 39 (15%) |
| SL2 | Sun-Thu, 01:05 UTC | KEEP | move the existing fast path above the preamble | 4 of 40 (10%) |
| SL3 | Sun-Thu, 02:00 UTC | KEEP | zero-member early-exit gate | 0 member-days; 40 heartbeats |
| SL5 | Sun-Thu, 01:25 UTC | Mon and Thu Denver (`25 1 * * 2,5`) | both | 0 of 38 |

The supplied 60-day hours overstate what a cron cut can save from here on. Two changes already cut no-op cost:

- **After 2026-09-27:** quiet-day self-audit runs stopped. The last notes of the form "no-op on the queue, not a no-op run" are dated 09-27. The fleet model changed on 09-28. The cause is UNVERIFIED; the timing is only a coincidence I measured.
- **2026-10-30, commit fb45138f:** the plan was condensed. The shared preamble went from 345,680 to 196,675 bytes, SL3's slice from 713,939 to about 265K, and SL5's from 549,337 to about 256K.

Logged started-to-completed time, summed:

| Routine | 09-04..10-07 | 10-08..11-02 (26d) | Forward rate per 60d | Table figure |
|---|---|---|---|---|
| AR_att | 1.97h | 0.51h | about 1.2h | 4.3h |
| AR_orc | 3.70h | 2.48h, or 0.48h without one 380-min outlier | about 1.1h | 7.9h |
| SL2 | 5.62h | 0.33h | about 0.8h | 6.0h |
| SL3 | 4.19h | 1.18h | about 2.7h | 6.9h |
| SL5 | 3.71h | 0.25h | about 0.6h | 5.7h |
| Total | 19.2h | 4.75h | about 6.4h | 30.8h |

My started-to-completed pairing (`LAG` over `log_ts`) sums to 23.9h over 60d against the table's 30.8h. The table's method is unknown to me, so that gap is unreconciled. The direction and the era split are not affected.

The remaining no-op cost is mostly not in the logged window. Each fire loads about 196 KB of shared preamble plus its routine section **before** it reaches any gate:

| Routine | Slice bytes | Routine section bytes |
|---|---|---|
| AR_att | 255,129 | 56,225 |
| AR_orc | 342,345 | 143,441 |
| SL2 | 254,779 | 55,875 |
| SL3 | 267,491 | 68,587 |
| SL5 | 259,055 | 60,151 |

At roughly 4 bytes per token that is about 65-85K tokens per fire, carried in context on every later turn. This is an estimate. Per-fire token counts are UNVERIFIED, and so is whether a session actually reads the whole preamble. A gate on the first lines of the slice is therefore the main lever for this group.

## Measured work

**Queue activity** comes from `events.queue_events`, grouped by Denver date, status and `COALESCE(payload.review_type, item_type)`, since 2026-09-04. I cross-checked it against `ops.run_log` notes.

- **AR_att attack days:** 09-08, 10-05, 10-06, 10-20, 10-21, 10-26, 11-02.
- **AR_orc grading days:** 09-06, 09-09, 10-06, 10-07, 10-22, 10-27. Five more entries come due on 11-03. The 10-25 fire closed notices but graded nothing.
- **SL2 drain days:** 09-07, 09-14, 10-05, 11-02.
- **SL5:** `ops.roster_change_log` has 0 rows ever. `PENDING_ROSTER` has 0 rows ever. Every note reads no mutations due. Its 60 days had no work at all, and neither has its whole history on those two surfaces.
- **SL3:** every note reports 0 SHADOW, 0 PAPER and 0 PROBE members. `state.strategy_roster` today shows A-E ADOPTED and F-I REJECTED. There were no transitions. A few fires raised spec notices, for example the k_incubate literal on 11-01.

**Weekday of real work, since 2026-08-09:**

| Routine and event | Sun | Mon | Tue | Wed | Thu |
|---|---|---|---|---|---|
| AR_att `attacker-complete` days | 1 | 4 | 5 | 3 | 2 |
| AR_orc `complete` days | 4 | 1 | 4 | 3 | 3 |
| SL2 `complete` days | 1 | 6 | 1 | 1 | 1 |

AR_orc's Sunday is a working day. Items attacked on Thursday have an orchestrator due date on Friday, and no routine fires until Sunday.

**Latest no-op fires, 10-25 to 11-02:**

| Routine | Logged minutes per quiet fire | Cron to done, median last 4 weeks |
|---|---|---|
| AR_att | 0.3-1.0 | 12.4 min |
| AR_orc | 0.4-1.5 | 3.1 min |
| SL2 | 0.2-1.1 | 3.1 min |
| SL5 | 0.8-1.4 | 3.5 min |
| SL3 | 2.4-7.8 | 16.4 min |

Cron-to-started medians are 7.8 min for AR_att and 12.2 for SL3, both top-of-hour crons, against 2.0-2.6 for the three crons at :05, :25 and :35. That is mostly platform delay. BigQuery job counts per window were 3-10 on most quiet fires, but overlapping routines such as D3 contaminate them, so I treat them as a rough proxy only (`JOBS_BY_PROJECT`, label `goog-mcp-server`).

**Divergence-review hold time** (first `pending` to `complete`, same table):

- Monthly batches: 2.4 days in July and August.
- 2026-09 batch: 4.7 days. It was enqueued on a Friday.
- `div-E-202610-1`: 3.0 days. `div-A-202610-1`: 2.0 days. Both are daily technical flips, and AR_orc missed 10-21 in that window.
- Open now: 8 `PENDING_REVIEW` items, made up of 5 November divergence reviews and 3 pre-mortems.

**Missed fires:** `ops.alerts` `queue_driven_missed_fire` shows misses on 09-17, 09-21, 09-28, 10-21 and 10-22. These routines are `catchup_safe: false`, so a missed slot waits for the next cron. Fewer slots would make each miss cost more.

## Routine by routine

### AR_att: KEEP Sun-Thu, add a gate

- **What breaks at a longer interval:** this is the first half of a two-phase review. AR_orc's due predicate needs `attacker-complete`, which only AR_att can write, so a delay here passes straight through to the verdict.
- **Dependency:** `sp_assert_deps('AR_orc',['AR_att'],<today>)` matches the exact day, with midnight grace only. AR_orc's day-set must be a subset of AR_att's.
- **Money:** D2 treats `DO-NOT-ACTIVATE — PENDING <div-id>` as gated (task_plan/D2.md, the `STRATEGY_ACTIVATION` read). A slower attacker keeps a strategy out of entries for longer. A Mon/Thu schedule would stretch the 2-3 day hold to about 4-7 days, for 3-5 strategies a month plus daily flips.
- **No-op cost:** STEP 0 join, due scan, RESIDUAL SWEEP and heal, all of which fit in one or two queries. There is no fast path today.
- **Lever:** a gate at the top of the slice. Any hit, scan error or unreadable lane falls through to the full section. The gate must keep the CONNECTOR-DOWN rule that a halted fire never prints the quiet line, and must still measure all three quiet-day grounds.
- **Saving:** cron 0%. Logged hours about 25% of the forward rate, capped at 29% because quiet fires are only 0.15h of 0.51h. Most of the saving is pre-start tokens, UNVERIFIED.

### AR_orc: KEEP Sun-Thu, add a gate

This is the most capital-adjacent routine in the group.

- **Binding outputs:** `divergence-review` writes activation state immediately. `m2m-termination` TERMINATE crafts close orders and moves capital. `strategy-retirement` is also binding (task_plan/AR_orc.md, Steps 3.5 and 4). No m2m-termination or strategy-retirement close appears in the 60-day queue table.
- **Trading-gate path:** STEP 0.5 is the automated way out of an echo-suspect park, whose open critical blocks `state.trading_enabled`. A longer interval lengthens that block. No scheduled fire has taken this branch as of the slice's 2026-09-16 measurement, so the exposure is structural.
- **Timing:** AR_orc at 18:35 MT runs after D2, so a verdict binds for the next day's D2. Each slot lost adds about a trading day of hold.
- **No-op cost:** the largest routine section in the group at 143 KB, read on 85% of fires. Quiet fires pass five conjuncts plus a NOTICE-CLOSE pass.
- **Lever:** a gate, with the dependency gate and pre-flight kept ahead of it and every binding path untouched.
- **Saving:** cron 0%. About 35% of forward logged hours excluding the outlier. The 380-min window on 10-22 is unexplained, UNVERIFIED, and I excluded it from that figure.
- **Worst case if cut:** a de-risking or termination verdict lands days late, or a trading block stays open days longer.

### SL2: KEEP Sun-Thu, relocate the existing fast path

- **Latency:** no orders or capital on any route (per the slice). A delay only slows drafting. It does compound, because each `strategy-revise` feeds another AR cycle, and premortem-C has reached cycle 18. Whether every revise route is free of any capital effect is UNVERIFIED.
- **Already gated:** the QUIET-RUN FAST PATH landed 10-30, and quiet fires log 0.2-0.3 min. The path sits inside the routine section, after the 196 KB preamble, so it saves only the routine-section read.
- **Why not cut the cron:** there were 4 real drains in 60 days, each feeding the review chain, and the forward logged cost is about 0.8h per 60d. A cut buys little beyond what relocating the gate gets without adding latency. Dropping only Sunday is defensible (1 of 10 active days) but saves one fire a week.
- **Saving:** cron 0%. About 10% of forward logged hours, plus pre-start tokens, UNVERIFIED.

### SL3: KEEP Sun-Thu, add a zero-member gate

- **Monitoring:** this is the only `daily_sun_thu` routine in the group. It is alarmed by `state.cadence_watch`, and that class's `missed_run` is CRITICAL, which feeds the trading gate. A Mon/Thu schedule has no existing class. It would need a new `monitor_class`, generated-region changes, `scripts/check_cron_dst_safety.py` (`EVENING_WINDOW_ROUTINE_IDS`) and OPS0/OPS2 catch-up changes. That is the 2026-08-08 class of migration, and a mistake halts order staging.
- **Dependency:** `sp_assert_deps('SL3',['D2a'],<today>)` is same-day.
- **The population can return:** rev 21 restored SHADOW and PAPER on 10-25. A cron can't follow the population, and flipping crons as members come and go would be a fragile control. Its STEP 1 catch-up loop would tolerate gaps, since each member keeps its own day set, so data capture is not the blocker.
- **No-op cost:** the highest in the group at 2.4-7.8 min. With zero members it still reads all of STEPS 1-4 and R1-R4.
- **Lever:** after the double-run guard, kill-switch, D2a gate and start-log, count SHADOW, PAPER and PROBE members. At zero, skip to a compact STEP 5 with the coverage read, `probe_funding_stalled`, referral re-resolve and heartbeat. The heartbeat stays because W5's meta-heartbeat check reads it.
- **Saving:** cron 0%. About 60% of forward logged hours, assuming a median near 1.2 min against 3.4 today. This is an estimate.
- **Worst case if the gate is wrong:** a member is misread as zero and a forward-test day slips, with no capital at risk. STEP 1's loop re-covers it on the next correct fire. The gate must fail toward the full path.

### SL5: Mon and Thu Denver, and a gate

- **Why this one:** no work in 60 days, nothing depends on it (no `depends_on` entry names SL5), and I found no money path through its lag.
- **Safety path verified:** `state.strategy_roster` derives from `events.strategy_lifecycle`, which D2 and AR_orc write when they terminate. Closing a terminated strategy does not wait for SL5. SL5's part is the repo roster and fanout.
- **Added latency:** SHADOW registration, zero capital, up to 4 days. `probe-register` and `adopt-register`, up to 4 days inside a 60-day-plus pipeline.
- **Safety benefit:** SL5's FATAL dependency gate raised a `missing_dependency` critical on 2026-09-21/22 on an idle day, and open criticals feed the trading gate. Fewer fires mean fewer such criticals.
- **New cost:** after a TERMINATED or PROBE transition, `scripts/check_live_roster_parity.py` in the daily `live-sql-parity` job can go red until the next SL5 fire, for up to 4 days. Today the same night's fire closes that gap. How a red run surfaces was not traced, UNVERIFIED.
- **Saving:** cron 60% of fires. With the gate, about 70% of forward logged hours (about 0.4h per 60d) plus pre-start tokens. If the owner would rather avoid the lockstep below, the gate alone captures most of the token saving with no latency change.
- **Reassess:** at the first SHADOW registration. "Zero so far" reflects an empty pipeline, and rev 21 can refill it.

**SL5 lockstep, if adopted:**

- `ops/cadence.yaml`: schedule, `cron_utc` and the daily-tier comments.
- `scripts/gen_routine_lists.py`, then the generated regions in `bigquery/241` and `bigquery/132`, re-applied live. `ops/triggers.json` carries only `monitor_class`.
- `ops/routine_backup.json` and the live trigger. OPS0 STEP 3 sweep can push it, but a manual save makes it effective at once.
- `Claude_Task_Plan.md` and regenerated slices: the SL5 "fires Sun-Thu" line and the inventory row.
- D3's OWNER-ELIGIBLE-DAY paragraph, which states all five owners fire Sun-Thu and which `scripts/check_cadence_consistency.py` mirrors (`QUEUE_DRIVEN_OWNERS`).
- `tests/test_gen_routine_lists.py` and `tests/test_cadence_consistency.py` fixtures. Per project notes, the generator's targets need both fixtures patched.
- `bigquery/132`'s 9-day net still works: the normal gap is 4 days, and one miss makes 7.
- `bigquery/241` must list the new `denver_dow` of `[2,5]` (Monday and Thursday), or it raises false misses.

## Shared gate design

- **Placement:** generate it in `scripts/split_task_plan.py` above the shared preamble of the slice, and carry the exact calls it needs (pre-flight, kill-switch and dependency gates, start and terminal log) so the session need not read the preamble first.
- **Exit rule:** quiet only on a measured empty result. Anything else, including an error, leaves the gate for the full slice.
- **Prior art:** M1R, SL2 and OPS2 already have fast paths from fb45138f, all placed below the preamble.
- **Approval:** this is a fleet-instruction edit, so per project notes it needs the owner's explicit OK in chat.
- **Not to do:** the review-lane producer check in AR_att's and AR_orc's quiet-day notes must survive, or the note loses its producer-side basis.

## Settled decisions checked

- No per-push conversion is proposed.
- No human gate is added to strategy add or delete.
- No owner-directed protection is removed. The heartbeat, kill-switch and dependency gates all stay.
- SL1's monthly cadence is outside this group and untouched.

## UNVERIFIED

- Per-fire and per-routine token cost, and how much of a slice a session actually reads.
- The cause of the late-September drop in quiet-fire cost.
- The 380-min AR_orc window on 10-22.
- The method behind the supplied hours table, against my 23.9h.
- Whether the live triggers match `ops/cadence.yaml` today. I read no RemoteTrigger data.
- Forward-rate figures rest on 26 days. Saving percentages are estimates, not measurements.
- How a red `check_live_roster_parity.py` run surfaces.

## Queries and files

- `ops.run_log`: per-routine rows and notes since 2026-09-04, with started-to-completed pairing by `LAG(log_ts)` and an era split at 2026-10-08.
- `events.queue_events`: queues `PENDING_REVIEW`, `PENDING_DRAFT`, `PENDING_ROSTER`, by date, status and weekday; divergence-review open durations.
- `ops.alerts`: `queue_driven_missed_fire`, and categories by source.
- `ops.roster_change_log`, `events.strategy_lifecycle`, `state.strategy_roster` and its view definition, `state.current_regime`, `state.open_queue`, `state.decision_log_current`.
- `region-us.INFORMATION_SCHEMA.JOBS_BY_PROJECT`, label `goog-mcp-server`.
- `ops/cadence.yaml`, `task_plan/{AR_att,AR_orc,SL2,SL3,SL5,D2,D3,W5}.md`, `Claude_Task_Plan.md`, `bigquery/48`, `132`, `241`, `254`, `scripts/check_cadence_consistency.py`, `scripts/check_cron_dst_safety.py`, `scripts/check_live_roster_parity.py`, commit fb45138f.

# Skeptic pass: SL5 and W3 proposals (2026-11-03)

Read-only. This file is the only write. Nothing is applied.

## Verdicts

| ID | Proposed | Verdict | What should happen instead |
|---|---|---|---|
| SL5 | Mon and Thu Denver, plus an early-exit gate | WEAKENED | KEEP the Sun-Thu cron for now. Take the gate, and call `sp_score_theater` before it reads readiness. If the owner still wants a cron cut, use Sun and Wed, not Mon and Thu. |
| W3 | Weekly cron, plus a stub on an empty book | WEAKENED | KEEP the full run. If the owner wants the gate, it must also require no A/B/C/E position events since the last W3, and must keep Step 4 or accept losing it knowingly. |

Neither change endangers the gates or orders. Both save under 1% of fleet logged hours. Each rests on a premise that the data contradicts in part.

## SL5

### Claims that hold

- **No roster work.** `ops.roster_change_log` has 0 rows, `PENDING_ROSTER` has 0 rows ever, and `events.strategy_lifecycle` has 0 TERMINATED rows. `state.strategy_adoption_readiness` returns 0 rows. Run notes agree.
- **Exact-day gate.** `sp_assert_deps` treats AR_orc as strict: same `run_date`, or yesterday only before 12:00 Denver. Mon and Thu are inside AR_orc's day set, so the gate passes when AR_orc completed.
- **Day numbering.** Cron dow `2,5` at 01:25 UTC is Mon and Thu Denver, and `denver_dow [2,5]` is correct in BigQuery numbering. `gen_routine_lists.py` derives this from the cron.
- **Declared dependants.** No `depends_on` in `ops/cadence.yaml` names SL5.
- **Termination capital.** `Experiment_Parameters.md`, "Strategy termination and capital redistribution", says the termination handler redistributes inline. `state.active_strategy_codes` derives from lifecycle. So the capital path does not wait for SL5, even though the slice calls branch (3) "the branch that releases a strategy's capital". That slice wording is loose.
- **Criticals do not last longer.** `sp_auto_resolve_alerts` Rule 1 (`bigquery/255`) resolves `missing_dependency` when the dep completes or the run date ages out. A rarer SL5 does not stretch an open critical. The claimed benefit is real but small: 1 SL5 `missing_dependency` critical in the last 60 days (09-21, open 514 min).

### Claims that fail or are overstated

1. **"Worst case 7 days with one missed slot" is understated. Replay shows 10 days.**
   - Measured misses, 09-04 to 11-02, from `ops.run_log` completed rows:

     | Denver day | Slots | SL5 misses | AR_orc misses |
     |---|---|---|---|
     | Sun | 9 | 0 | 0 |
     | Mon | 9 | 2 (09-21, 09-28) | 2 |
     | Tue | 8 | 0 | 0 |
     | Wed | 8 | 1 (10-21) | 1 |
     | Thu | 8 | 2 (09-17, 10-22) | 0 |

   - Four of the 5 misses fall on the proposed days, so 4 of 17 proposed slots (24%) were lost, against 1 of 25 on the other days. With n=5 this is not significant (hypergeometric p about 0.08), so I do not claim a Monday and Thursday effect.
   - Consecutive misses did happen. Thu 09-17 and Mon 09-21 were both lost. Under the proposal the fires would be Mon 09-14, then Thu 09-24: a 10-day gap.
   - That gap crosses the 9-day `queue_driven_silent` threshold, a warning (`bigquery/132`). The lifecycle report's "normal gap 4, one miss 7" did not replay this.
   - SL5 is `catchup_safe: false`, so a missed slot waits for the next cron.

2. **"No money path runs through its lag" contradicts the proposal's own worst case.**
   - `probe-register` stamps `immutable_since`, which makes a strategy capital-eligible (`task_plan/SL5.md`, branch (2)). First PROBE capital starts up to 4 days later, or 10 on replay. This is a delay to a small ramp floor, not a loss.
   - The proposal omits branch (4), `adopt-register`. `state.strategy_ramp` scales its cap on score and reaches full at score 1.0 (`bigquery/259`), so a late ADOPTED row does not appear to withhold capital.
   - How a score slipping below 1.0 during the wait is handled is UNVERIFIED.

3. **"Nothing depends on it" is true for declared dependencies only.**
   - SL5 is the primary caller of `ops.sp_score_theater`. Of 15 `analytics.theater_judge` rows scored in 60 days, 4 landed in SL5's 19:27 slot (09-06, 09-09, 10-07, 10-27).
   - Those are pre-mortem, out-of-table and prose-regression reviews. Binding types score in AR_orc Step 3.5. W5 is the weekly backstop, so a later score looks harmless.
   - No gate reading these non-adoption scores was found in the files I grepped. A complete reader list is UNVERIFIED.

4. **The gate has a silent trap the proposal does not mention.**
   - `strategy_adoption_readiness` uses `COALESCE(judge_independent, FALSE)`. An unscored SUFFICIENT adoption reads `ready = FALSE`.
   - A gate that reads readiness before calling `sp_score_theater` exits quiet on a real adoption. Nothing alerts, and only W5's weekly score would release it.
   - The gate must run the score first. It must also keep the kill-switch gate, the dependency gate and STEP 0, and read all three inputs. The slice says "no due queue task" alone is not a no-op.

5. **The roster-parity detail is partly wrong, and the surfacing is now traced.**
   - Only TERMINATED opens a gap, because D2 or AR_orc write that row. SL5 writes PROBE itself, and live apply comes last, so PROBE opens no gap.
   - `check_live_roster_parity.py` fails the job at about 07:10 UTC. Today the same evening's SL5 closes the gap before that. Under the proposal it could stay red for up to 4 days, or longer after a miss.
   - This step has no issue or `ops.ci_findings` delivery, unlike SQL parity, in `live-sql-parity.yml`. The red run is the only signal I found. Any GitHub failure email is UNVERIFIED. A red that is expected after each termination teaches the reader to ignore a real drift check.

6. **A D2 guard during the repo lag is UNVERIFIED.** After a termination, `Strategy.md` and `roster.yaml` would still show the code for days while live does not. A grep of the D2 section for `is_active`, `active_strategy_codes` and `strategy_roster` found no explicit order-craft guard on a terminated code. That grep is not proof of absence. Today's exposure is at most the same evening. The proposal stretches it to days. The event has happened 0 times.

### Size of the prize

- Forward logged SL5 cost is about 0.6h per 60d (lifecycle report, 26-day sample). A 60% cron cut saves about 0.36h, or about 0.3% of the 105h.
- The stronger argument is tokens. A cron cut certainly removes 60% of fires and their pre-start reading. Per-fire tokens are UNVERIFIED.
- A gate's token saving is also UNVERIFIED. The trigger says "Read Claude_Task_Plan.md. Perform SL5", which routes to the slice, and whether a session stops at the top of a 259 KB file is not measured.
- The lockstep is larger than a list of files. `check_cadence_consistency.py` check Q asserts that all five owners fire Sun-Thu, and D3's OWNER-ELIGIBLE-DAY paragraph states it as a premise. Both need rewriting for a per-owner day set, and D3's stale scan is LLM-read prose with 14 replayed alerts behind it. Live SQL (`241`, `132`) must be re-applied too.
- SL1 opened 2 leads and advanced 2 on 11-02, so reassessment may not be far off. Reverting means the same lockstep again.

### Recommendation

KEEP the cron. Take the gate after measuring what a no-op fire actually reads. If tokens per fire prove material and the owner wants the cut, use Sun and Wed: gaps of 3 and 4 days, 1 miss in 17 slots on this sample, and both days are inside AR_orc's set. Say why in the plan: the choice rests on 5 events and is only a tiebreak. Fleet-instruction edits need the owner's OK in chat.

## W3

### Claims that hold

- **Book empty.** `state.current_positions` is 12 rows, all D. The latest A/B/C/E event is the MSCI CLOSE on 2026-08-18 (`events.position_events`). The 11-01 note and file call this the eleventh cycle.
- **Downstream mechanics.** W4 sections A, B and E act only on per-position flags, so a flagless stub does nothing there. `sp_assert_deps` for W4 needs only a W3 `completed` row in the week. `check_cadence_marker.py` needs the marker when the file changes. A stub satisfies all of these.
- **Self-correcting.** A position open on Sunday takes the full path.

### Claims that fail or are overstated

1. **The empty-book run is not doing vacuous work.** Steps 1, 2, 3, 5 and 6 are already skipped and cost almost nothing. What the gate removes is Step 4.
   - `rows_written` on these runs is almost entirely `ops.web_calls`: 9 of 9 on 11-01, 18 of 18 on 10-18, 14 of 15 on 10-25. So W3 still does 9-18 external lookups a week. The weekly report's "mostly info alerts/notes" is wrong.
   - `ops.alerts` with source W3: 8 notices across 7 of the 9 cycles from 09-06 to 11-01. Of those, 4 were fixed in the plan or by owner decision (09-13, 09-20, 09-27, 10-25), 2 were routed or corrected (09-06, 10-04), and 2 were superseded by Rev 52.
   - Almost all of them concern the shock rubric. The `shock_overlay = acute` override holds A, B and E at DO-NOT-ACTIVATE, so these are spec fixes close to a money gate. No measured P&L effect is attributed to any of them.
   - The stream is thinning: 10-18 and 11-01 raised none.

2. **The fairness point against Step 4.** The spec words Step 4 "per position", so on an empty book it is arguably out of spec. W3's value here is unplanned behaviour. The 18 KB file has no reader for it: W4 uses only flags and recommendations, D2 has the file out of scope (`bigquery/197` header), and the 11-01 file explicitly "does not file" its Brent roll inference. So the value travels through notices only. W1 PART 2A also covers the price leg in part. That is a real argument for trimming the prose, not for silence.

3. **The stated worst case already happened, and it was W3's best finding.**
   - MSCI closed 08-18. W3 on 08-23 saw an empty book and raised `criterion_dividend_distortion`, a warning: the exit's breach disappears once the ex-dividend is netted out. It was confirmed and fixed the same day, with `bigquery/197` as the mechanical fix.
   - A gate on "book empty" alone would have skipped that review.
   - `weekly.md` includes a no-position-events limb, but the proposal as written does not. The limb is mandatory.

4. **The saving is overstated.**
   - Logged minutes from `ops.run_log`: 26.6, 16.9, 13.1, 18.1, 10.7, 11.3, 10.2, 14.5, 6.4. The last five average 10.4 min, or about 1.5h per 60d, not 2.1h.
   - A stub still reads the slice, commits, opens its own PR, waits on exact-head checks, dispatches the merge and confirms it. The 11-01 full run did all of this in 6.4 min. OPS0 STEP 4(f) also needs the commit as landing evidence.
   - My estimate is a saving of 0.6-0.9h per 60d, under 1% of fleet. The 4-5 min stub floor behind it is an estimate, UNVERIFIED. Token savings are likely larger than time savings, since Step 4 and the governing reads go. That is UNVERIFIED too.

### Recommendation

KEEP the full weekly run for now. The saving is under an hour, and the loss would be silent, since nothing would report a notice that was never raised. Reassess after 2-3 more cycles if notices stay at zero. If the owner wants a cut now, keep the cron and require both an empty book and no A/B/C/E position events since the last W3 completion. Replace the stub's "macro line from D1 records" with a bounded Step 4, or state plainly that the shock-rubric audit is being dropped and name who picks it up. Fall through to the full path on any query error. Needs owner OK, `Claude_Task_Plan.md` and regenerated slices.

## Larger savings the reviewers missed or set aside

1. **Shared preamble: the largest lever I can see.** 198,904 bytes sit in every slice, over 587 completed fires in the 60-day table. At 4 bytes per token that is about 50K tokens per fire and about 29M tokens before any work, if it is all read. Whether it is read in full is UNVERIFIED. Trading and lifecycle mention it for gate placement. No report sizes a role-scoped preamble. Measure actual reads first. Risk: shared rules may silently stop binding, so the split needs CI support.
2. **Trigger suffix on every fire.** `ops/routine_backup.json` appends "Spawn Sonnet 5.5 model sub-agents" and "Do not give final response until you have resolved every issue" to SL5's prompt, including on no-op fires. Whether all fleet prompts carry it, and what it costs, are UNVERIFIED.
3. **W2 is bigger than W3 and was set aside.** W2 is 3.1h against W3's 2.1h, runs about 21.6 min in INDEX MODE for a DO-NOT-ACTIVATE, `capital_disabled` Strategy B, and `weekly.md` gives it only an unmeasured 0-30%. Step timing is the measurement to get.

## Sources

- **BigQuery (read-only):** `ops.run_log` (W3, SL5, SL1, AR_orc); `ops.alerts` (source W3, SL5 mentions); `ops.roster_change_log`; `events.queue_events`; `events.strategy_lifecycle`; `events.position_events`; `state.current_positions`; `state.strategy_adoption_readiness`; `state.open_queue`; `analytics.theater_judge`; `ops.web_calls`.
- **SQL:** `bigquery/205` (`sp_assert_deps`), `255` (auto-resolve), `241`, `132`, `259`, `266`, `11`, `143`.
- **Plan:** `task_plan/SL5.md`, `W3.md`, `W4.md`, `D2.md`, `D3.md`, `SL3.md`, `AR_orc.md`, `W5.md`; `Experiment_Parameters.md`; `Weekly_Position_Deep_Dive.md`.
- **Scripts and config:** `ops/cadence.yaml`, `ops/routine_backup.json`, `ops/triggers.json`, `scripts/check_cadence_consistency.py`, `scripts/check_cadence_marker.py`, `scripts/check_live_roster_parity.py`, `scripts/gen_routine_lists.py`, `.github/workflows/live-sql-parity.yml`.
- **Sibling reports:** `lifecycle.md`, `weekly.md`; `trading.md`, `ops.md` and `periodic.md` by grep only.
- **Not read:** live RemoteTrigger state. Whether live triggers match `ops/routine_backup.json` is UNVERIFIED.

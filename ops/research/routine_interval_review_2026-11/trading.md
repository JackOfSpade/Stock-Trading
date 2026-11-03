# Interval review, group D1 / D2a / D2 / D3 / M1R (2026-11-03)

Read-only review. Sources: ops/cadence.yaml, task_plan/{D1,D2a,D2,D3,M1R}.md, ops/routine_backup.json, bigquery/12_cadence_monitor.sql, bigquery/173_freshness_cadence_aware.sql, Daily.md git history, ops.run_log, ops.alerts, ops.web_calls, events.queue_events, events.decision_log, events.regime_events, events.parking_events, events.trade_fills, state.market_calendar.

## Verdict

KEEP all five crons. This chain is one unit: D1 and D2a feed D2, D2 feeds D3, and D2a's refresh request feeds M1R. The usable savings are inside the runs, and they are small.

| Routine | Current | Proposed | Lever | Hours saved | Slice bytes |
|---|---|---|---|---|---|
| D1 | Sun-Thu 22:00Z | KEEP | early-exit gate, zero-session days only | about 3% | 317,531 |
| D2a | Sun-Thu 22:40Z | KEEP | none | 0% | 318,763 |
| D2 | Sun-Thu 23:15Z | KEEP | early-exit gate, skip index-row re-measure while B is gated | 10-25%, UNVERIFIED | 302,847 |
| D3 | Sun-Thu 00:45Z (Mon-Fri UTC) | KEEP | optional: narrow the golden-check flag set | 0-10%, UNVERIFIED | 327,770 |
| M1R | Sun-Thu 13:00Z | KEEP | none; fast path landed 2026-10-30 | 0% of hours, tokens UNVERIFIED | 228,211 |

## Facts that change how the 60-day table reads

1. The 60-day window mixes two regimes, split at about 2026-10-05 to 10-15. Medians from started-to-terminal pairs on session_id:

   | Routine | Before 10-05 Mon-Thu median (min) | 10-05 on Mon-Thu median (min) | Hours, last 4 weeks |
   |---|---|---|---|
   | D1 | 25.9 | 28.1 | 10.55 |
   | D2 | 13.7 | 7.2 | 3.50 |
   | D2a | 14.6 | 8.4 | 2.95 |
   | D3 | 7.3 | 2.65 | 3.05 |
   | M1R | 2.75 | 0.35 | 0.32 |

   The prompt condensation (fb45138f, 2026-10-30) and the router-gated rule (e5846c9f, 2026-11-02) are too new to show in these numbers. My pairing gives lower 60-day totals than the brief (D1 19.7h, D2 7.8h, D2a 8.4h, D3 6.2h, M1R 1.56h), because unpaired rows drop out.

2. The quiet is a regime fact, not a structural one. A, B, D and E have read DO-NOT-ACTIVATE since at least 09-04, and C reads HYBRID FOMC-only (events.regime_events, scope STRATEGY_ACTIVATION). events.trade_fills has 0 rows since 09-04. All capital movement in the window was park legs (events.parking_events: 40 rows on 13 days). The park went VOO-only on 10-15 (bigquery/256), and the only order staged since is D2a's cover on 10-26. Low activity measured here does not predict low activity after the router re-enables a strategy.

3. Run time understates cost. A started row can come after the slice has been read, so pre-start reading is invisible. M1R no-ops show about 0.3 min started-to-completed but complete a median 11 min after cron. That gap mixes scheduler jitter and reading, and I could not separate them (UNVERIFIED). Each slice carries the same 198,934-byte shared preamble (199,494 for M1R), roughly 50k tokens if read whole. Whether a session reads it whole is UNVERIFIED.

## Why a cron cut fails for D1, D2 and D3

- `ops.sp_assert_deps` (bigquery/12) requires a same-run_date completion, with only a pre-noon grace for the prior day. D2 depends on [D1, D2a] and D3 on [D2].
- A skipped D1 therefore raises a `missing_dependency` critical against D2 unless D2's deps also change. That critical can halt staging through `state.trading_enabled`. The 2026-10-21 D2 halt shows the path live.
- All are `daily_sun_thu` in state.cadence_watch, so a deliberate skip reads as `missed_run` CRITICAL unless the class changes.
- A new cadence class would touch: ops/cadence.yaml, bigquery/12, bigquery/24 if period-shaped, bigquery/31 and 59 catch-up lists, scripts/check_cadence_consistency.py (classes, check K, evening guard IDs), scripts/check_cron_dst_safety.py, bigquery/173 `marks_due_through`, live triggers, ops/routine_backup.json, Claude_Task_Plan.md and regenerated slices.
- OPS0 STEP 1b is retired (task_plan/OPS0.md), so it adds no constraint. OPS0's D3 reads and D3's OPS0 watchdog fallback still do.

## D1, Market Development Scan

Measured from Daily.md `d1_actions` across 41 runs since 09-04 (git show per commit, parsed):
- 399 watchlist, 16 thesis, 2 router_review, 0 exit, 0 entry, 0 add.
- Non-watchlist actions on 5 of 41 runs (09-09, 09-10, 09-13, 09-17, 09-23), none after 09-23.
- Watchlist volume jumped: 133 items over 34 runs through 10-22, then 266 over the 7 runs from 10-23 to 11-01. Peak was 80 on 10-29.
- These rows are index-only because B is disabled. Most D1 output in the last two weeks cannot reach capital today.
- D1 spends the most on external calls: 3,376 ops.web_calls over 42 days, falling from 78-109 a day on 10-19..21 to 22-51 a day since 10-26.

The case for cutting is real. Sunday's 72-hour scan costs only about 12% more than a one-session scan (31.4 vs 28.1 min), so fixed cost dominates and 3 runs a week would save nearly 40%. It is also the largest single line, at about 8 hours over 60 days. I still reject it:

- D1 is the only writer of `EQUITY_BREADTH_PCT`. The D1 slice records that trackers return a number without a reliable as-of date, and that date pinning relies on post-close inference. A skipped session is probably not recoverable (backfill not tested, UNVERIFIED). D2's measured triggers read this series.
- D1 produces Strategy.md's two geopolitical refresh triggers, and these feed D2a, M1R and the router. Those are the events where a day's delay matters most. The owner's 11-02 rule lists REGIME CHECK and breadth as never gated.
- D1 is the news read on 12 held D tranches. It logged 0 exits in the window, but a missed thesis break would be silent and would cost money. Mechanical kill flags do not read news.
- The J paper book is pre-registered with Sonnet readers each run. Marks self-heal, but headline intake is capped at 48 hours, so a longer gap drops stories. Readiness needs 30 realized calls.
- The owner set the gated-scan scope yesterday, keeping the research-screen row and new-entry work at this cadence for the gated case. The first gated run (11-02) took 28.8 min with 164 rows and 28 web calls, which is one sample. Re-measure this before considering anything further.

Early-exit lever, zero-session days:
- D1 ran 23.9 min and wrote 45 rows on Labor Day (09-07), when its note says no session occurred. That is about the normal run cost.
- state.market_calendar shows 10 of the next 262 fire days have no new session (query on `cal_date`): Thu 11-26, Sun 12-27, Sun 01-03, Mon 01-18, Mon 02-15, Sun 03-28, Mon 05-31, Sun 06-20, Mon 07-05, Mon 09-06.
- Proposal: on those days keep the run-log rows, REGIME CHECK and geopolitical triggers, held-position developments, park pin check and paper-book steps. Skip the single-name and sector screens and the add sweep. Saves about 3% of D1 hours.
- It must not move the next run's scan-window start in a way that drops the skipped screens. If the anchor is the prior Daily.md stamp, this needs an explicit exception.

Worst case if wrong: a holiday-weekend development reaches a screen one session later. No held-position coverage is lost, and D2 has no market to act in until the next open anyway.

Lockstep for the lever: Claude_Task_Plan.md, regenerated slices (scripts/split_task_plan.py --check). No cron or monitor change. New plan rules need the owner's explicit OK.

## D2a, Broker Reconcile and Snapshot

- Marks written on 40 of 41 runs (median 14-25 rows). The exception, 09-07, is the holiday with no new marks.
- Real events in the window: park fills mirrored on 13 days, `trading_halted` 3, `regime_sweep_blocked` 3, `unregistered_park_liquidation` 1, `book_drawdown_soft_breach` 1, `large_market_move` 1, `owner_confirmation_stale` 1.
- It stages orders itself: park-sweep on 5 days and the park-cover on 10-26, which funded a $600 withdrawal that had left settled cash at -$587.87.
- Sole writer of events.daily_marks and perf.strategy_daily. state.freshness and the book drawdown watch read these (bigquery/173), and the -50% kill is the only sizing backstop.
- Sole producer of PENDING_REGIME_REFRESH.

Marks can backfill from dated bars (bigquery/173 notes this). Cash tripwire and reconciliation timing cannot, and the 2026-08-14 false staleness critical shows what happens when this cadence moves without its consumers.

No early-exit: there is no empty case, since every run has marks to write and a broker to check. The holiday run is already cheap in rows, and its hours are not worth the risk of a safety bypass.

Worst case if cut: a stale book, a late cash or drawdown signal, or a freshness halt. Money-affecting and possibly silent. KEEP.

## D2, Daily Action Conversion

- Zero rows does not mean no work. Notes for 8 zero-row runs from 10-06 to 10-18 show Watchlist commits, closed-window annotation, queue drains and router duties. rows_written excludes repo output. On 10-07 D2 drained 17 Q4 items.
- Order staging: 7 evenings in 42 runs (09-08, 09-10, 09-17, 09-22, 09-29, 10-05, 10-14), all park legs, none since 10-15 because the park is VOO-only. That rate will not return unless the router re-enables a strategy.
- Evening-before-open staging is the point of D2. A Thursday or Sunday miss loses the Friday or Monday open. catchup_safe is false because it crafts off live quotes.
- ROUTER EVERY-RUN DUTIES (measured triggers, unanswered FUNDAMENTAL_AXIS row, technical-flip clause) run every evening whatever D1 flagged. M1R's re-score is picked up the same evening.
- The slice already has an early exit (EARLY-EXIT IS NOT A `d1_actions` TEST, pinned 09-01 after D2 nearly skipped a switch of 96.6% of the account). Do not loosen it.

Early-exit lever, index rows:
- The binding re-measure I found (QUALIFYING-MOVE RE-MEASUREMENT) applies to thesis construction. Notes show D2 also re-measuring index-only rows name by name on IBKR, sequentially. 24 of 42 notes mention re-measurement, and every instance I read reproduced D1 exactly.
- I grepped the section but did not read all of it, so the claim that no other rule requires the index-row re-measure is UNVERIFIED.
- D1 router-gated mode keeps IBKR confirmation, so this is a second pull while B cannot take capital. At 44-80 rows a day it could become D2's main variable cost.
- Proposal: while B is GATED, do not re-measure index-only rows, or batch them in one scripted pull. The thesis-time re-measure stays and still protects capital (ORCL 09-14 is its reason).

Estimated 10-25% of D2 hours, UNVERIFIED because per-step timing does not exist. Worst case: a wrong move figure sits in the index and the W2 trajectory series until thesis time, with no capital effect. W2 data quality is the real exposure, so the owner should decide, and a batched pull is the safer form.

## D3, Calendar and Queue Hygiene

Hours are low now: completion a median 4 min after cron over the last 4 weeks (quartiles 3-9), 3.05 hours in total.

Measured work (run_log notes, ops.alerts, events.queue_events; note regexes are rough, so I read the excerpts):
- Open-order reconciliation had rows on a minority of nights (09-09, 09-14, 09-29, 09-30, 10-14, 10-26 confirmed from notes). RE-CRAFTED appears on 09-08 and 09-17.
- Golden check: 2 flips in 60 days. KT-05 on 10-20 was CONFIRMED DRIFT, and AR_orc changed the fixture on 10-22 after the Experiment_Parameters rev 20 change. PA-07 on 10-06 was a false positive. D3 is the only remaining live evaluator since golden-prose-daily was retired on 08-30.
- `ops0_missed_fallback` 3, `queue_item_stale` 1, `catchup_refire_blocked` 1.
- Spec corrections on several September nights, fewer since. Most recent notes say REPO OUTPUT: NONE.

All-clear nights are valuable here. D3 is a pre-open check on staged orders, with PRE-FILL INVALIDATION RE-CHECK as the last point before an invalidated entry fills. Deleting an un-tapped instruction is explicitly allowed even under a halt. It also watches OPS0, and OPS0 reads D3's outcome.

Optional lever: flag counts were large on some nights (14-32 of 36, then 26 and 30 of 30). They run high when Claude_Task_Plan.md moves, including for hunks like SL3 log appends. Excluding append-only hunks from the flag set might save 0-10%, UNVERIFIED. It would have to keep flagging real prose changes such as the KT-05 one, so replay it against both flips first. I would not move the check to weekly: KT-05 was caught in a day, and the saving is minutes.

Worst case if the cron were cut: a staged order reaches the open with an invalidated thesis, or a dead OPS0 stays unnoticed longer. KEEP.

## M1R, Out-of-cycle Regime Re-score

Queue history (events.queue_events, all time): 2 items, regime-refresh-20261027 and -20261101. Both drained the next morning, and both ended "no axis moved". So 2 actionable days of 40 fires.

That rate is misleading. Rev 52 (10-22) widened the producer to both directions, and the 2 items came within about 8 D2a runs since then. The 60-day rate describes the old producer.

Cost of no-ops: the QUIET-RUN FAST PATH is live (fb45138f, 10-30). Last 4 weeks: 19 runs, 0.32 hours, median 0.35 min. A move to 3 fires a week saves at most about 40% of a very small number (under 0.2 hours per 4 weeks by this measure) and adds up to 2 days of latency to an item the owner built to fix stale `acute` readings. Thursday-evening items already wait until Sunday. Monitoring would also need changes in bigquery/241 and 132, ops/triggers.json, check Q, and D3's owner-eligible slot table with its clauses (b) and (e).

Possible token lever, not recommended yet: the fast path sits after the 199KB preamble, so a no-op may still read 50k tokens. It cannot simply move above the preamble, because it cites shared Observability wording. Measuring actual reads comes first (UNVERIFIED). The blinding rules also bind, so a trigger-level gate needs care, and trigger edits need the owner's OK.

Separate question for the owner, outside this review: two re-scores in 6 days, each moving no axis, may mean the trigger is sensitive. Too few samples to say.

Worst case if cut: a shock change sits unscored for days while D2 reads a stale axis. KEEP.

## Queries

- Durations: pair `ops.run_log` by routine and session_id, MIN started to MAX terminal, capped at 2h, split at 2026-10-05. Pairing on run_id returned nothing.
- Wall time: terminal log_ts minus cron slot, 0-240 min, run_date >= 2026-10-05.
- Actions: `git log --since=2026-09-04 -- Daily.md`, then `git show <h>:Daily.md`, newest commit per date, parsing the ```yaml d1_actions block.
- Orders: events.queue_events, queue = ORDER_STAGED, status = pending; source taken from the note prefix.
- Refresh: events.queue_events, queue = PENDING_REGIME_REFRESH.
- Golden: events.queue_events, item_type = prose-regression.
- Alerts: ops.alerts by source, severity, category since 2026-09-04.
- Web calls: ops.web_calls by routine, run_date.
- Zero-session days: state.market_calendar, Sun-Thu fire days 2026-11-03..2027-11-03; on Sundays the test is the prior Friday's session.
- Slice split: `grep -n "^## <ID>\. "` then byte counts of the head.

## UNVERIFIED

- Per-routine tokens, how much of a slice a session actually reads, and how much of M1R's post-cron gap is jitter.
- D2 and D3 lever savings. No per-step timing exists.
- Whether any rule beyond the thesis-time one requires D2's index-row re-measure.
- Whether a missed breadth session can be backfilled from any source.
- Why watchlist volume jumped at 10-23. I did not trace the cause; the 11-01 note shows 2,137 names measured.
- Effect of the 11-02 router-gated rule (one run only). Re-measure after about 10 runs.
- Live trigger crons. I used ops/cadence.yaml and ops/routine_backup.json and did not read RemoteTrigger, per the brief.

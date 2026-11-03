# Weekly group interval review: W1, W2, W3, W4, W5 (2026-11-03)

Read-only. Sources: ops/cadence.yaml (W1..W5 blocks), task_plan/W1..W5.md (sections starting at "## Wn."), ops.run_log (rows 2026-09-04..11-01 via execute_sql_readonly), events.queue_events.

## Slice sizes (bytes, whole file / routine section only)
W1 227042 / 27901; W2 225981 / 26840; W3 209205 / 10064; W4 216565 / 17424; W5 261380 / 62239.

## Schedule and chain (cadence.yaml)
W1 Sun 07:30 UTC, W2 08:00, W3 09:00, W4 09:30 (depends_on W1,W2,W3), W5 Mon 05:00 UTC (= Sun 23:00 MDT, depends_on W4). All weekly_sun, catchup_safe true.
Gate: bigquery/114 period-aware sp_assert_deps, satisfied by any completion in that Sunday week. Skipping a week for W1/W2/W3 makes W4 raise missing_dependency, so every-other-week is NOT cron-only for W1-W4. period_watch (bigquery/24), OPS0 catch-up, routine_catchup_window (10.5d = 1.5x weekly bar), check_cadence_marker.py (ISO-week marker in line 1), ops/triggers.json, routine_backup.json, Claude_Task_Plan.md and slices all assume weekly.

## Measured (last 9 Sundays, 2026-09-06..11-01; 9/9 completed for W1-W4, W5 9/10 with 1 platform rate-limit kill 09-20 then caught up by OPS2)
Query: SELECT routine,run_date,status,rows_written,note FROM ops.run_log WHERE routine IN ('W1'..'W5') AND run_date>=2026-09-01.
Median rows: W1 63 (range 19-204, mostly ops.web_calls rows), W2 2, W3 13, W4 3, W5 36.
Task-given hours: W5 3.6, W1 3.6, W2 3.1, W3 2.1, W4 1.5 = 13.9h of ~105h (13%).
Queue output (events.queue_events since 09-04, items from weekly handoff): 49 "Strategy A queue" pending rows over 5 distinct days, 3 thesis-construction (3 days), 1 re-screen. So W4/W1 hand D2 real queue work on roughly half of weeks.

## Per routine

### W1 Catalyst Calendar (A 6-month, C 45-day windows)
- Breaks at longer interval: C window is 45 days and C/A earnings dates move; the calendar is overwritten whole each week. Biweekly would leave a stale forward calendar for up to 14 days, and C catalysts inside 14 days are exactly the ones that matter. Downstream: W4 reads it for A/C shortlists and Strategy A queue (49 pending rows). Dependency gate on W4 would fail on off weeks.
- Measured work: every run found real work (63 median rows, calendar rewritten with new windows each time, 9/9 new content). Not a no-op routine; no all-clear pattern.
- No-op cost: the double-run guard already exits first on same-day re-fire. There is no "nothing changed" exit because something always changed (window rolls).
- Already trimmed: D1 boundary rule (reuse D1 records, no second news scan) is in the slice.
- Recommendation: KEEP weekly. Hours saved 0%. Worst case if cut to biweekly: stale C catalyst dates for a week, W4 dependency halt (critical alert) on off weeks.

### W2 Post-Event Enrichment (Strategy B)
- State: INDEX MODE for 10 consecutive cycles because B is router DO-NOT-ACTIVATE and capital_disabled. Router gate already skips per-candidate enrichment; still does cohort-level trajectory/thinness work, which is the running evidence series on B convergence. Rows 1-6, but runtime median 21.6 min (task figures), spend zero on metered APIs.
- Each cycle had 5-7 new D1 single-name-move rows and hundreds of passed items, i.e. intake is non-empty every week, so a "nothing new" exit never fires.
- Breaks at longer interval: W4 depends on W2 (gate), B 10-trading-day post-event window is short, so if B re-activates (router flips) a biweekly cadence would lose half the windows. Router flips are decided by AR_orc/div reviews and can occur any week.
- Recommendation: KEEP cron. Possible later lever (early-exit/slimming, not cron): if router stays DO-NOT-ACTIVATE and unchanged, skip the sub-agent fan-out for intake and do only the cohort metric. UNVERIFIED how many of the 21.6 minutes is intake vs cohort work (no per-step timing in run_log). Hours saved estimate for that lever: 0-30% of W2 hours (UNVERIFIED), worst case a missed router-flip day is detected by D1/D2, not W2, so low.

### W3 Open-Position Deep-Dive (A,B,C,E)
- Measured: in-scope book empty (12 open rows, all Strategy D, which is excluded via long_horizon and covered by M3) for at least 9 consecutive cycles (W3 notes 10-04: "7th consecutive", 10-18: "9th"). Steps 1,2,3,5,6 vacuous; step 4 (sector/macro) carries. Rows written 9-18 (mostly info alerts/notes), median 13 min, 2.1h/60d. No weekly-thesis-action flag in any of the recent runs I read.
- The slice has no early-exit for an empty in-scope book (grep of the W3 section for empty/vacuous/no open: no hits), so it pays the full read of Strategy.md, Experiment_Parameters.md, Operating_Protocols.md and the guard before reaching the vacuous steps.
- Dependencies: W4 reads Weekly_Position_Deep_Dive.md and expects the ISO-week marker; W4 section A turns weekly-thesis-action flags into PENDING_ANALYSIS for D2. The file must still be written each week with the marker so sp_assert_deps and check_cadence_marker pass. So the lever is an early-exit gate, not the cron.
- Proposed gate: after the double-run guard, query state.current_positions joined to roster review_cadence='reactive'; if zero in-scope open rows AND zero events.position_events for A/B/C/E since last W3 completion, write the stub file (marker line + "empty in-scope book, steps vacuous, step 4 macro line from D1 records") and log completed. Keeps the file and gate contract.
- Worst case if wrong: a position that opens and closes entirely inside one week is not weekly-reviewed (D1 and D2 daily mechanics still cover exits and invalidation). Slow-burn drift on a book that is empty cannot exist. Position opened in-week and still open Sunday triggers the full path.
- Recommendation: KEEP weekly cron; add empty-book early-exit gate. Hours saved: about 50-65% of W3's 2.1h (about 1.1-1.4h), approx 1.2% of fleet hours. Risk: low. Needs lockstep: Claude_Task_Plan.md plus regenerate slices (split_task_plan.py), owner OK for fleet-instruction edits per memory feedback_fleet_instruction_edits_need_explicit_ok.

### W4 Weekly Research Handoff
- Queue-only, idempotent, 9.7 min median, rows 1-17. Hands D2: Strategy A queue rows (49 pending over 5 of 9 weeks), thesis-construction (3), re-screen (1), weekly-thesis actions (0 observed).
- Depends on W1/W2/W3 same week; W5 depends on it. W4 deliberately lands early Sunday so D2 drains it (cadence.yaml comment). Its own comment says latency is about 1 day, negligible against B 10-day window.
- Breaks at longer interval: A queue fed by W1 would lag; every dependency/period gate above.
- Recommendation: KEEP. Cheapest routine in the group; savings would be under 1h and tied to W1-W3.

### W5 Factbase and Analytics Consolidation
- Largest (3.6h, 62KB section). Real work every week: median 36 rows (decision_log walk of 67-84 entries, sub-pattern taxonomy, embeddings, vocabulary drift watch, nogo_shadow price fetches when horizon 21d elapses, market-calendar auto-extend which has not fired, horizon 2029-12-25). All metered spend zero; runs as Opus orchestrator with about 7 Sonnet sub-agents.
- Observed reliability: it is the Sunday-23:00 run and hit a platform five-hour rate limit on 09-20 (failed), and OPS2 hosted it inline as catch-up on 09-21 and again 10-26. So shifting W5 to fortnightly is partially exercised: not a failure mode for outputs, but it competes for quota with the Sunday daily chain.
- Zero Strategy B sub-pattern instances extracted in the windows I read (B router-gated), so the taxonomy step is low-yield now; the decision_log walk, embeddings and vocabulary watch still produce rows.
- Breaks at fortnightly: nogo_shadow forward_price fetches stamp the fetch date, so late fetches lengthen the measured horizon (bias, currently 0 elapsed so no present cost); sub-pattern extraction lags a week; W5 closes the loop on D3-adjacent vocabulary drift (silent failure, hard to notice). Period-gate: weekly_sun bucket in bigquery/114 and period_watch would flag the skipped week unless cadence.yaml, trigger, routine_backup.json, plan and slices all move (not cron-only).
- UNVERIFIED: whether any consumer requires embeddings fresher than a week (grep found no freshness view on analytics.decision_embeddings keyed on W5).
- Recommendation: KEEP for now. If the owner wants savings, the candidate is every-other-week with the same gate changes, saving about 50% of W5 hours (about 1.8h, 1.7% of fleet) with a silent-failure worst case (drift/taxonomy lag) affecting analytics, not orders or kill checks. Evidence is thin because the decision_log walk finds 67-84 entries per week, so I do not recommend it.

## Summary
Only a W3 early-exit gate is justified (empty in-scope book 9+ weeks). Everything else is KEEP: W1-W4 are chained by period-aware dependency gates and feed D2 queue work; W5 does real work weekly and a longer interval buys little (1.7% of fleet) with silent-failure risk.

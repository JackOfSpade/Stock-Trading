# Interval review, group OPS0 / OPS1 / OPS2 (2026-11-03)

Sources: ops/cadence.yaml (OPS0/OPS1/OPS2 blocks), task_plan/OPS{0,1,2}.md (275288 / 217945 / 224990 bytes), ops.run_log (60d, completed), ops.alerts (since 2026-09-04), Claude_Task_Plan.md-derived slice text.

## Measured
- run_log 60d completed: OPS0 37 (+1 failed), 21 with <=2 rows, median 2; OPS1 42, 0 <=2, median 127; OPS2 37, 33 <=2, median 2. Medians 3.3/3.3/3.0 min. Combined ~10.4 h of ~105 h (about 10%).
- OPS2 days with real work (note review since 09-04): 09-21 (1 inline), 09-28 (1 inline + 1 deferred), 10-06 (SL1), 10-20 (OPS1), 10-21 (2 inline + 1 deferred), 10-26 (hosted W5) = about 6-7 of 37 (~18%). Rest are empty-feed verified no-ops.
- OPS0 STEP 1 readiness empty (heartbeat only) on nearly every run; real refire days: 10-22 (3 misses; RemoteTrigger absent headless -> blocked alerts), 09-21/22. Alerts since 09-04: catchup_refire_blocked 13, catchup_caught_up 8, stranded_branch* 3.
- OPS1: connector_reauth_needed alerts in 60d = 0 (queried ops.alerts); connector_tool_added 20, connector_tool_enumeration_failed 2. OPS1 itself was missed 2026-10-20 and 10-21 and was caught up by OPS2 (catchup_caught_up alerts).
- Not verified: per-run token cost, and whether OPS0 STEP 4 clone dominates its 3.3 min (UNVERIFIED).

## Dependencies
- All three depends_on: [] by design; monitor_class daily_sun_thu feeds state.cadence_watch / missed_run. Lowering any cadence changes cadence_watch expectations, bigquery view logic, OPS0 STEP 1b/2b, ops/triggers.json (generated), routine_backup.json, live trigger, plan + slices.
- OPS2 (22:15 MT) must run after 21:00 MT needs_attention deadline and before OPS0 (22:30); OPS0 reads D3 outcome. OPS2 hosts W5/SL1 catch-ups (10-06, 10-26), so its cadence bounds period-routine recovery.
- OPS1 FMP ^VIX probe is exactly 1 of 250 free req/day; its ops.web_calls row is the negative control for telemetry (cadence.yaml comment).

## Levers
- OPS2 already has a QUIET-RUN FAST PATH (BigQuery-only preflight, skip STEP 2) per its slice; the early-exit lever is spent. Cron change would save <=10% of 3.2 h while removing recovery of OPS1/SL3/period routines the same night.
- OPS0: landing sweep (STEP 4) and Sunday trigger sweep are the heavy parts; a gate to skip git clone when no claude/* branch older than 6h exists is plausible but UNVERIFIED as saving; PR-based landing (2026-10-20) may reduce stranding, not measured.
- OPS1: unconditional, fixed cost, detection-only; value is hours of lead before 16:10 MT cadence.

## Recommendations
- OPS0 KEEP (daily Sun-Thu 04:30Z). Watchdog for everything else; worst case if reduced: a missed D1/D3/SL3 is not refired for 2 days and cadence_watch false-alarms.
- OPS1 KEEP. Auth expiry costs a halted evening (2026-07-19 incident); 0 reauth in 60d is the system working, plus 20 vendor tool-drift alerts caught.
- OPS2 KEEP. Estimated saving from any change ~0-10% of ~3.2 h; worst case: unrecovered misses, W5/SL1 slip.

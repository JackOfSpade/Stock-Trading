-- Catch-up in-flight guard: match a running routine by ROUTINE, not by (routine, today).
-- Project: stock-trading-498512. SUPERSEDES the state.catchup_available and
-- state.period_catchup_available view definitions in bigquery/90_catchup_inprogress_guard.sql
-- (which itself superseded bigquery/31 and bigquery/59). Every other object in those files is
-- unchanged; state.catchup_refire_readiness (bigquery/59, re-anchored by bigquery/112) reads these two
-- views, so the widened exclusion propagates to OPS0 STEP 1 and OPS2 STEP 1 with no edit of its own.
-- Idempotent (CREATE OR REPLACE VIEW). Apply after bigquery/90 (and 112).
--
-- WHY (2026-08-19, interactive triage of the OPS2 `catchup_executor_headroom` alert, alert_id
-- e9bd72c4-845a-41e8-aef3-4acef9181588; the class is registered in ops.alert_policy by bigquery/182).
--
-- THE GUARD'S PURPOSE, unchanged: bigquery/90 exists so OPS0's 22:30 MT sweep does not refire a
-- routine that is at that moment RUNNING — a double-run duplicates writes into the append-only
-- events.decision_log / events.queue_events and risks a same-branch git clobber. It defines "in
-- flight" as: the latest ops.run_log row for that routine is a 'started' with log_ts inside the last
-- 3 hours (so a completed/failed/halted row supersedes it, and a >3h-old 'started' is a dead session
-- that SHOULD be refired). That definition is correct and is kept verbatim below.
--
-- THE DEFECT is the JOIN, not the definition: `LEFT JOIN in_flight f ON f.routine = w.routine AND
-- f.run_date = w.today`. It can only ever see an in-flight run whose run_date is TODAY. bigquery/90's
-- own comment states the assumption outright — "a period routine's run_date is the calendar day it
-- runs, not its period_start". That holds for a routine running itself. It does NOT reliably hold for
-- a routine being HOSTED INLINE by OPS2, because task_plan/OPS2.md STEP 2 item 5 contradicts itself
-- about which date the hosted routine logs: the governing clause says to honour "X's own gates,
-- blinding, scope, and run-logging" (and every routine's own generated slice hardcodes
-- `sp_routine_start('<ID>', <today, America/Denver>, ...)`), while sub-bullet (c) RUN-LOG IDENTITY
-- says X's slice logs `ops.sp_log_run('X', <as_of>, ...)` — and `<as_of>` is `period_start` for a
-- period-tier miss (state.catchup_refire_readiness, bigquery/112). Under the second reading the
-- hosted 'started' row lands under period_start, the join cannot match, and OPS0 emails the operator
-- an actionable "blocked, re-run manually" alert for a routine OPS2 is at that moment successfully
-- catching up — inverting OPS0's "emails only the residual" invariant. The window is real and narrow:
-- OPS2 fires 22:15 MT, OPS0 sweeps 22:30 MT, and single routines take 17-29 min (p90/max on the
-- longest-tailed routines is higher still), so OPS2 is essentially always mid-execution when OPS0
-- sweeps. It has never actually fired only because every night since OPS2 went live 2026-07-27 has had
-- an empty miss feed.
--
-- THE PROSE AMBIGUITY IS FIXED SEPARATELY AND IS THE PRIMARY FIX: Claude_Task_Plan.md's OPS2 STEP 2
-- item 5 (c) and item 6 now pin `run_date = <today, America/Denver>` explicitly and state that
-- `<as_of>`/`period_start` belongs to ops.catchup_refire_log.miss_key ONLY. That alone restores the
-- guard. This file exists so the guard STOPS DEPENDING ON THAT CONVENTION BEING HONOURED — the same
-- defence-in-depth posture as OPS2's own STEP 2.1 scope guardrail, which re-checks an exclusion the
-- readiness view already applies. A prose contract that must be transcribed correctly by a future
-- session, in a class of bug whose failure mode is silent, is exactly the thing to back with a
-- mechanical guard. (ops.alert_policy's `catchup_executor_headroom` resolve_rule names this remedy
-- verbatim: "the bigquery/90 in_flight join widened to match a hosted routine as_of".)
--
-- THE CHANGE, precisely: drop `AND f.run_date = w.today` from both joins, and reduce in_flight to
-- DISTINCT routine so the LEFT JOIN cannot fan out when a routine holds fresh 'started' rows under
-- more than one run_date. The per-(routine, run_date) latest-row-wins pick is UNCHANGED — the
-- widening is on which partitions are allowed to answer, not on what counts as in flight.
--
-- THIS IS A PURE WIDENING — it can only ever ADD an exclusion, never remove one. Everything bigquery/90
-- excluded today is still excluded (a fresh 'started' under today's run_date still matches; the join
-- simply no longer also demands run_date = today). The only new exclusions are routines holding a
-- fresh 'started' under some OTHER run_date, and there is no case where refiring one of those is
-- correct:
--   * a routine hosted inline by OPS2 under period_start — the case this fixes;
--   * a manual/backfilled run logged under a past run_date and still inside the 3h window;
--   * a routine that started a catch-up for a prior period while its current period is also missed —
--     refiring a SECOND concurrent session of the same routine is precisely the harm bigquery/90 exists
--     to prevent, so suppressing it is the intended behaviour, not a regression.
-- The 3h freshness bound remains the backstop that keeps this from latching: a dead session stops
-- suppressing catch-up 3h after its last log line, exactly as before, under any run_date.
--
-- NOT CHANGED, deliberately: the hand-maintained catchup_safe_routines / catchup_safe_period_routines
-- UNNEST lists are reproduced verbatim from bigquery/90 (which reproduced them from bigquery/31 and
-- bigquery/59). They are INERT DUPLICATES for query purposes only — scripts/check_cadence_consistency.py
-- check K parses the copies inside bigquery/31 and bigquery/59, never these. Keeping them byte-identical
-- here is what makes that safe; changing catch-up scope is a bigquery/31 + bigquery/59 edit, not this one.

-- ===== state.catchup_available (supersedes bigquery/90, which superseded bigquery/31) =====
CREATE OR REPLACE VIEW `stock-trading-498512.state.catchup_available` AS
WITH catchup_safe_routines AS (
  SELECT routine FROM UNNEST(['D1', 'D3', 'OPS1', 'SL3']) AS routine
),
in_flight AS (
  -- Latest ops.run_log row per (routine, run_date); "in flight" iff that latest row is a fresh
  -- 'started' (log_ts within the last 3h). DISTINCT routine because the consumer joins on routine
  -- alone now — see this file's header.
  SELECT DISTINCT routine
  FROM (
    SELECT routine, run_date, status, log_ts,
      ROW_NUMBER() OVER (PARTITION BY routine, run_date ORDER BY log_ts DESC) AS rn
    FROM `stock-trading-498512.ops.run_log`
  )
  WHERE rn = 1
    AND status = 'started'
    AND log_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 3 HOUR)
)
SELECT w.routine, w.schedule, w.today
FROM `stock-trading-498512.state.cadence_watch` w
JOIN catchup_safe_routines s USING (routine)
LEFT JOIN in_flight f ON f.routine = w.routine
WHERE w.needs_attention
  AND f.routine IS NULL;

-- ===== state.period_catchup_available (supersedes bigquery/90, which superseded bigquery/59) =====
CREATE OR REPLACE VIEW `stock-trading-498512.state.period_catchup_available` AS
WITH catchup_safe_period_routines AS (
  SELECT routine FROM UNNEST([
    'W1', 'W2', 'W3', 'W4', 'W5',              -- weekly research/enrichment/handoff/consolidation
    'M1a', 'M1b', 'M2', 'M3', 'M5',             -- monthly research/consolidation (M4 excluded — action-conversion)
    'Q1', 'Q2', 'Q3', 'SL1',                    -- quarterly research/consolidation (Q4 excluded — action-conversion)
    'A1', 'A2'                                  -- annual research (A3 excluded — action-conversion)
    -- SL4 (monthly) deliberately excluded: a discretionary-retirement PROPOSAL is capital-adjacent
    -- enough to warrant the existing human-visible alert only, matching M4/Q4/A3's treatment.
  ]) AS routine
),
in_flight AS (
  -- Same latest-row-wins in-flight pick as state.catchup_available above. The run_date equality that
  -- used to be on the JOIN is gone: a period-tier routine normally logs run_date = the calendar day it
  -- runs, but one HOSTED INLINE by OPS2 may log it under period_start, and either way a fresh 'started'
  -- row means a session for this routine is running right now.
  SELECT DISTINCT routine
  FROM (
    SELECT routine, run_date, status, log_ts,
      ROW_NUMBER() OVER (PARTITION BY routine, run_date ORDER BY log_ts DESC) AS rn
    FROM `stock-trading-498512.ops.run_log`
  )
  WHERE rn = 1
    AND status = 'started'
    AND log_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 3 HOUR)
)
SELECT w.routine, w.monitor_class, w.today, w.period_start, w.grace_deadline
FROM `stock-trading-498512.state.cadence_period_watch` w
JOIN catchup_safe_period_routines s USING (routine)
LEFT JOIN in_flight f ON f.routine = w.routine
WHERE w.period_missed
  AND f.routine IS NULL;

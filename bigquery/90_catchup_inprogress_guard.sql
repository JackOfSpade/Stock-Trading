-- Catch-up in-progress guard: exclude an in-flight routine from the refire feed (2026-07-18
-- adversarial review of the DEPENDENCY-WAIT WINDOW v2). Project: stock-trading-498512.
-- SUPERSEDES the state.catchup_available view definition in bigquery/31_catchup_notify.sql AND the
-- state.period_catchup_available view definition in bigquery/59_catchup_autofire.sql. Every OTHER
-- object in both of those files (bigquery/31 has none besides that view; bigquery/59's
-- ops.catchup_refire_log TABLE, state.catchup_refire_readiness VIEW, and state.catchup_refire_failures
-- VIEW) is UNCHANGED and remains canonical there — this file does not touch them, and
-- state.catchup_refire_readiness reads the two views redefined below, so the new exclusion
-- propagates through it without any edit of its own. Apply after bigquery/31, bigquery/59.
--
-- PROBLEM: state.catchup_available / state.period_catchup_available flag a routine whose expected
-- run is missing so OPS0 (Cadence Watchdog) can auto-refire it. Both views only ever counted
-- COMPLETIONS — a routine legitimately mid-DEPENDENCY-WAIT past its 21:00 MT deadline (logged
-- 'started', now polling its own dependency every ~10 min per Claude_Task_Plan.md's DEPENDENCY-WAIT
-- WINDOW) has no completed row yet, so it was indistinguishable from a routine that never ran at all
-- — OPS0 would refire it at 22:30 while the original session is still running, double-running it
-- (duplicate events.decision_log/events.queue_events writes, a same-branch git clobber risk).
--
-- FIX: exclude a routine whose LATEST ops.run_log row for (routine, the view's own current day —
-- `today`, which both state.cadence_watch and state.cadence_period_watch already carry) is
-- status='started' with log_ts within the last 3 HOURS. That is "fresh started, no terminal row
-- since" — computed as the latest-row-wins pick (ORDER BY log_ts DESC, LIMIT 1 via the in_flight CTE
-- below) rather than a bare EXISTS-any-started-row check, so:
--   * a routine whose started row is later followed by a 'completed'/'failed'/'halted' row is NEVER
--     excluded (the terminal row is the latest, so it fails the in_flight WHERE status='started'
--     filter) — it stays refireable, exactly as before this file.
--   * a 'started' row OLDER than 3h with no terminal row after it (a dead session — the routine
--     crashed or the harness was killed mid-run) is NOT excluded either (it fails the in_flight
--     WHERE log_ts >= NOW-3h filter) — state.stalled_runs territory, and refire proceeds, matching
--     the spec's explicit "do NOT exclude" case.
-- Every other column, join, and filter below is copied byte-for-byte from bigquery/31's
-- state.catchup_available and bigquery/59's state.period_catchup_available, INCLUDING their
-- hand-maintained catchup_safe_routines / catchup_safe_period_routines UNNEST lists (kept here only
-- because a view's full CTE chain must be reproduced to add a LEFT JOIN exclusion — the actual
-- source-of-truth copies scripts/check_cadence_consistency.py's check K parses are still the ones
-- literally inside bigquery/31_catchup_notify.sql and bigquery/59_catchup_autofire.sql; this file's
-- copies are inert duplicates for query purposes only, never read by that check).

-- ===== state.catchup_available (supersedes bigquery/31) =====
CREATE OR REPLACE VIEW `stock-trading-498512.state.catchup_available` AS
WITH catchup_safe_routines AS (
  SELECT routine FROM UNNEST(['D1', 'D3', 'OPS1', 'SL3']) AS routine
),
in_flight AS (
  -- Latest ops.run_log row per (routine, run_date); "in flight" iff that latest row is a fresh
  -- 'started' (log_ts within the last 3h) — see FIX above.
  SELECT routine, run_date
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
LEFT JOIN in_flight f ON f.routine = w.routine AND f.run_date = w.today
WHERE w.needs_attention
  AND f.routine IS NULL;

-- ===== state.period_catchup_available (supersedes bigquery/59) =====
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
  -- Same latest-row-wins in-flight pick as state.catchup_available above, joined on `today` (the
  -- current day a period-tier routine would actually log `run_date` as when it starts — a period
  -- routine's run_date is the calendar day it runs, not its period_start, which can be days/weeks
  -- earlier) rather than period_start.
  SELECT routine, run_date
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
LEFT JOIN in_flight f ON f.routine = w.routine AND f.run_date = w.today
WHERE w.period_missed
  AND f.routine IS NULL;

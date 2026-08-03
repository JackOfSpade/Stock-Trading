-- Process-constant autotune: cadence_watch daily deadline 21:00 -> 21:45 America/Denver.
-- SUPERSEDES the `state.cadence_watch` view in bigquery/113_never_completed_watch_fix.sql (which in turn
-- superseded 48_cadence_monitor_unbounded.sql and 12_cadence_monitor.sql). Nothing else in 113 changes:
-- state.cadence_period_watch and its 21:00:00 PERIOD-grace literals are a DIFFERENT constant and are
-- deliberately untouched here. Apply AFTER bigquery/113. Idempotent (CREATE OR REPLACE); safe to re-run.
--
-- WHY (W5 2026-08-03, self-improvement loop `process_reliability`, active_auto per ops/autonomy_levels.yaml):
-- the loop's readiness view state.process_reliability_readiness returned ready_for_change = TRUE for D1, D2
-- and D3 on deadline_key 'cadence_watch_deadline_local' -- the deadline-threat pattern held on the three
-- most-recent consecutive W5 cycles (2026-07-19, 2026-07-26, 2026-08-03), all of which are POST the
-- bigquery/89 metric redefinition, so the W5 v2 discount (2) streak-restart rule is satisfied and the
-- streak is valid evidence. Observed 90-day p90 completion minute-of-day at the time of change:
--   D1  1279 (21:19 MT)  19 min PAST the old 21:00 deadline
--   D2  1266 (21:06 MT)   6 min PAST
--   D2a 1289 (21:29 MT)  29 min PAST  (streak 1 of 3 -- NOT ready, no change-log row written for it)
--   D3  1224 (20:24 MT)  36 min before, inside the ~90-min plausibly-threatens band
-- W5 v2 discount (1) does not apply: every one of these routines reported total_wait_minutes = 0.0 and
-- n_dep_waits = 0 (D3 had 3 dep-waits but 0.0 wait minutes), so none of the lateness is explained by
-- deliberate DEPENDENCY-WAIT/retry protocol waiting -- there is no wait time to discount out.
--
-- WHY 21:45 AND NOT LATER -- the binding ceiling is the WINTER scheduled cadence_check:
-- bigquery/scheduled_queries/cadence_check.sql runs at 05:15 UTC. That is 23:15 MDT in summer but
-- 22:15 MST in winter. state.cadence_watch.needs_attention only alarms once Denver wall-clock has passed
-- this deadline, so the deadline MUST stay strictly before the scheduled run IN EVERY SEASON or a
-- genuinely missed routine stops firing its critical for the whole winter half of the year. 21:45 keeps
-- 30 minutes of margin against the 22:15 MST run while clearing the worst observed p90 (D2a's 21:29) by
-- 16 minutes and D1's 21:19 by 26. Anything from ~22:15 onward silently disarms the dead-man's switch in
-- winter and must never be chosen. (Two repo comments understate this ceiling by 30 min -- see the header
-- correction landed alongside this file in bigquery/scheduled_queries/cadence_check.sql.)
--
-- KNOWN LIMITATION, RECORDED DELIBERATELY (raised as a `process_constant_ceiling` warning by this same W5
-- run): threat_pattern is a TWO-SIDED ~90-minute band around the deadline, so clearing the band for D1
-- (p90 1279) would require a deadline of >= 22:49 -- past the winter ceiling above and therefore not
-- permissible. D1/D2/D2a consequently remain inside the band at 21:45, which means
-- state.process_constant_oos_watch (bigquery/72) is expected to read degraded_revert = TRUE after three
-- post-change W5 cycles and auto-REVERT this constant to 21:00. That is the fail-safe behaving exactly as
-- designed -- the relaxation is chasing a fat LATE TAIL (p50s are 16:28 / 17:21 / 16:33 / 18:38 MT, all
-- comfortably inside 21:00), not a shifted centre. A durable fix belongs on the routines' completion times
-- or on the band definition, NOT on further loosening this deadline.
--
-- KEEP IN SYNC: ops/cadence.yaml `cadence_watch_deadline_local` and the DATETIME(e.today, TIME '..')
-- literal in bigquery/12_cadence_monitor.sql -- scripts/check_cadence_consistency.py check D parses those
-- two and fails the build if they disagree. Both were updated to 21:45 in the same commit as this file.

-- ===== state.cadence_watch (supersedes 113_never_completed_watch_fix.sql's view; daily tier) =====
CREATE OR REPLACE VIEW `stock-trading-498512.state.cadence_watch` AS
WITH watch AS (
  SELECT
    e.routine,
    e.schedule,
    e.today,
    -- monitored = has EVER completed (unchanged column, no rolling window -- bigquery/48's fix stays).
    EXISTS(SELECT 1 FROM `stock-trading-498512.ops.run_log` r
           WHERE r.routine = e.routine AND r.status = 'completed') AS monitored,
    EXISTS(SELECT 1 FROM `stock-trading-498512.ops.run_log` r
           WHERE r.routine = e.routine AND r.status = 'completed'
             AND r.run_date = e.today) AS ran_completed_today
  FROM `stock-trading-498512.state.cadence_expected_today` e
)
SELECT
  e.routine,
  e.schedule,
  e.today,
  e.monitored,
  e.ran_completed_today,
  -- `monitored` precondition stays REMOVED from the alarm predicate (bigquery/113's fix).
  -- CHANGED HERE: TIME '21:00:00' -> TIME '21:45:00'.
  (e.schedule IN ('daily_trading','daily_all')
   AND NOT e.ran_completed_today
   AND DATETIME(CURRENT_TIMESTAMP(), 'America/Denver') >= DATETIME(e.today, TIME '21:45:00')
  ) AS needs_attention,
  CURRENT_TIMESTAMP() AS checked_at
FROM watch e;

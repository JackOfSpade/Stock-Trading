-- ITEM: cadence dead-man's switch self-silences after 14 days of continuous outage (2026-07-14
-- self-improvement audit, finding sql-early#1).
--
-- BUG: bigquery/12_cadence_monitor.sql's state.cadence_watch.monitored and ops.sp_assert_deps' first
-- EXISTS both require a 'completed' run within the trailing 14 days before treating a routine as
-- "monitored" (self-bootstrapping so a routine that has never adopted run-logging can't false-alarm).
-- But this ALSO means: if a routine that WAS logging stops completing for MORE than 14 consecutive
-- days (e.g. its trigger silently deleted -- exactly the SPOF state.trigger_attestation's own header
-- worries about), on day 15 `monitored` flips to FALSE. state.cadence_watch.needs_attention then
-- permanently stops alarming for that routine (until it next completes -- which it won't, since it's
-- broken), and ops.sp_assert_deps stops listing it in `missing`, so a downstream action routine that
-- gates on it (e.g. D2 gating on D1) is no longer FATAL-blocked and stages on top of a silently-broken
-- upstream. This is the exact multi-week-outage case a dead-man's switch exists to catch.
--
-- Contrast: state.trigger_attestation (bigquery/18_stack_review_fixes.sql) already uses "monitored =
-- it has EVER completed" (no rolling window) for the same reason, and deliberately defers daily-
-- routine coverage to state.cadence_watch ("Daily routines are omitted (already alarmed by
-- state.cadence_watch)") -- a deferral this bug did not actually honor beyond 14 days.
--
-- FIX (this file): remove the 14-day bound from ONLY the first/"monitored" EXISTS clause in both
-- objects below. Everything else -- the grace window, the 21:00 Denver deadline guard, the midnight-
-- crossing grace in ops.sp_assert_deps -- is copied verbatim, unchanged. This is a strict SUPERSET
-- fix: any routine that was already monitored under the old 14-day rule stays monitored; a routine
-- broken for >14 days now correctly stays monitored (and can alarm/gate) instead of going silent.
--
-- SUPERSEDES the state.cadence_watch VIEW and ops.sp_assert_deps PROCEDURE definitions in
-- bigquery/12_cadence_monitor.sql. Apply after 12_cadence_monitor.sql, 38_run_log_selfheal.sql (the
-- sp_backfill_run_log_from_markers call inside sp_assert_deps), and after 46_weekly_benchmarks.sql
-- (highest-numbered file at time of writing).

CREATE OR REPLACE VIEW `stock-trading-498512.state.cadence_watch` AS
WITH watch AS (
  SELECT
    e.routine,
    e.schedule,
    e.today,
    -- monitored = the routine has EVER logged a completed run (no rolling window -- see file header;
    -- was `AND r.run_date >= DATE_SUB(e.today, INTERVAL 14 DAY)`, which silenced the alarm after 14
    -- days of continuous outage for a previously-monitored routine).
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
  (e.schedule IN ('daily_trading','daily_all')
   AND e.monitored
   AND NOT e.ran_completed_today
   AND DATETIME(CURRENT_TIMESTAMP(), 'America/Denver') >= DATETIME(e.today, TIME '21:00:00')
  ) AS needs_attention,
  CURRENT_TIMESTAMP() AS checked_at
FROM watch e;

CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_assert_deps`(
  in_routine STRING, in_deps ARRAY<STRING>, in_run_date DATE
)
BEGIN
  DECLARE missing STRING;

  BEGIN
    CALL `stock-trading-498512.ops.sp_backfill_run_log_from_markers`();
  EXCEPTION WHEN ERROR THEN SELECT @@error.message;
  END;

  SET missing = (
    SELECT STRING_AGG(d, ', ' ORDER BY d)
    FROM UNNEST(in_deps) AS d
    WHERE EXISTS (  -- d is a monitored routine (has EVER adopted run-logging -- no rolling window,
                    -- see file header)
            SELECT 1 FROM `stock-trading-498512.ops.run_log` r
            WHERE r.routine = d AND r.status = 'completed')
      AND NOT EXISTS (  -- ...but it did not complete for this run_date, nor (within the
                        -- midnight-crossing grace window below) for the day before it
            SELECT 1 FROM `stock-trading-498512.ops.run_log` r
            WHERE r.routine = d AND r.status = 'completed'
              AND (
                r.run_date = in_run_date
                OR (
                  r.run_date = DATE_SUB(in_run_date, INTERVAL 1 DAY)
                  AND DATETIME(CURRENT_TIMESTAMP(), 'America/Denver') < DATETIME(in_run_date, TIME '12:00:00')
                )
              ))
  );
  IF missing IS NOT NULL AND missing != '' THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', in_routine, 'missing_dependency',
      FORMAT('%s blocked: upstream not completed for %t: %s', in_routine, in_run_date, missing),
      TO_JSON_STRING(STRUCT(in_routine AS routine, CAST(in_run_date AS STRING) AS run_date, missing AS missing_deps)));
    RAISE USING MESSAGE = FORMAT(
      '%s dependency check FAILED (run_date %t): missing completed upstream: %s', in_routine, in_run_date, missing);
  END IF;
END;

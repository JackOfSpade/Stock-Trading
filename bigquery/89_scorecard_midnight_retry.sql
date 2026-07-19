-- Routine-health scorecard: midnight-safe completion metric + retry/dep-wait telemetry columns
-- (2026-07-18, owner directive TRANSIENT-FAILURE WAIT-AND-RETRY + DEPENDENCY-WAIT WINDOW v2).
-- Project: stock-trading-498512. SUPERSEDES bigquery/27_process_reliability.sql's
-- analytics.routine_health_scorecard definition (kept there, unmodified, for DR-rebuild
-- apply-in-order reference only — see the superseded marker added to that file's header. Do NOT
-- re-apply bigquery/27's CREATE OR REPLACE VIEW live in isolation; this file is now canonical).
--
-- Apply after bigquery/88_retry_telemetry.sql. The RETRY COLUMNS join below reads
-- state.retry_telemetry (bigquery/88); BigQuery does not verify a view's referenced objects exist
-- until query time, so applying this file before 88 is live would still succeed at CREATE time, but
-- every query against this view would then fail with "Not found: state.retry_telemetry" until 88 is
-- applied. Apply 88 first, then this file.
--
-- PROBLEM (two independent, additive fixes to bigquery/27's scorecard):
--  (a) MIDNIGHT WRAP: p50_/p90_completion_minute_of_day was computed from
--      TIME(log_ts,'America/Denver') minutes-since-midnight-OF-log_ts's-OWN-calendar-day — a routine
--      that legitimately completes at 00:15 the day AFTER its run_date (e.g. after riding out a
--      DEPENDENCY-WAIT window past 21:00 MT) reads as minute 15, indistinguishable from a genuinely
--      on-time 00:15 AM completion, instead of minute 1455. This silently hid exactly the
--      late-completion drift the scorecard exists to surface to W5's PROCESS-RELIABILITY REVIEW.
--  (b) NO RETRY VISIBILITY: bigquery/88_retry_telemetry.sql now parses the RETRY[...]/DEPWAIT[...]/
--      INCIDENT[...] tokens routines append to ops.run_log.note, but nothing rolled that up
--      per-routine for W5 to read alongside the existing completion/failure counts.
--
-- FIX:
--  (a) Replace the TIME(...)-of-log_ts minutes-of-day with
--      DATETIME_DIFF(DATETIME(log_ts,'America/Denver'), DATETIME(run_date), MINUTE) — minutes
--      elapsed since MIDNIGHT OF THE OPERATING DAY (run_date), not of log_ts's own calendar date.
--      Same units (minutes), same column names (p50_/p90_completion_minute_of_day); a past-midnight
--      completion now correctly reads > 1440 instead of wrapping. Every other column/semantic is kept
--      byte-compatible with bigquery/27.
--  (b) LEFT JOIN a per-routine aggregate of state.retry_telemetry (bigquery/88), adding
--      n_retry_events, n_retries_exhausted, n_dep_waits, n_dep_wait_futile, n_active_refires,
--      total_wait_minutes — all COALESCEd to 0 for a routine with no telemetry rows in the window
--      (the common case today; INERT ON APPLY until routines start emitting tokens).

CREATE OR REPLACE VIEW `stock-trading-498512.analytics.routine_health_scorecard` AS
WITH runs AS (
  SELECT routine, run_date, status, log_ts,
    -- MIDNIGHT FIX (bigquery/89): minutes elapsed since midnight of run_date (the operating day),
    -- NOT minutes-of-day of log_ts's own calendar date — see PROBLEM (a) above. A completion that
    -- lands the calendar day after run_date now reads > 1440 instead of wrapping near zero.
    DATETIME_DIFF(DATETIME(log_ts, 'America/Denver'), DATETIME(run_date), MINUTE) AS completion_minute_of_day
  FROM `stock-trading-498512.ops.run_log`
  WHERE run_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 90 DAY)
),
per_routine AS (
  SELECT
    routine,
    COUNT(*) AS n_log_rows_90d,
    COUNTIF(status = 'completed') AS n_completed_90d,
    COUNTIF(status = 'failed') AS n_failed_90d,
    COUNTIF(status = 'halted') AS n_halted_90d,
    -- p50/p90 completion minutes since midnight of run_date (America/Denver), completed runs only,
    -- last 90 days. Midnight-safe as of bigquery/89 (values > 1440 possible for past-midnight
    -- completions) — see PROBLEM/FIX (a) above.
    APPROX_QUANTILES(IF(status = 'completed', completion_minute_of_day, NULL), 100)[OFFSET(50)] AS p50_completion_minute_of_day,
    APPROX_QUANTILES(IF(status = 'completed', completion_minute_of_day, NULL), 100)[OFFSET(90)] AS p90_completion_minute_of_day
  FROM runs
  GROUP BY routine
),
dep_gate_aborts AS (
  -- A dep-gate abort (ops.sp_assert_deps RAISE) logs no run_log row for that attempt (the RAISE fires
  -- before sp_routine_end) — it is visible only as an ops.alerts 'missing_dependency' row. Surfaced
  -- here by count so a routine whose upstream is chronically late shows up without a run_log row to
  -- join on.
  SELECT source AS routine, COUNT(*) AS n_dep_gate_aborts_90d
  FROM `stock-trading-498512.ops.alerts`
  WHERE category = 'missing_dependency'
    AND alert_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 90 DAY)
  GROUP BY source
),
retry_agg AS (
  -- Per-routine rollup of state.retry_telemetry (bigquery/88) over the same 90-day token history the
  -- view already carries (retry_telemetry's own window is likewise 90 days, so no re-filtering here).
  SELECT
    routine,
    COUNTIF(token_type = 'RETRY') AS n_retry_events,
    COUNTIF(token_type = 'RETRY' AND outcome = 'exhausted') AS n_retries_exhausted,
    COUNTIF(token_type = 'DEPWAIT') AS n_dep_waits,
    COUNTIF(token_type = 'DEPWAIT' AND outcome = 'futile') AS n_dep_wait_futile,
    COUNTIF(token_type = 'DEPWAIT' AND refired IS NOT NULL AND refired != 'none') AS n_active_refires,
    ROUND(SUM(IF(token_type IN ('RETRY', 'DEPWAIT'), waited_s, NULL)) / 60) AS total_wait_minutes
  FROM `stock-trading-498512.state.retry_telemetry`
  GROUP BY routine
)
SELECT
  p.routine,
  p.n_log_rows_90d,
  p.n_completed_90d, p.n_failed_90d, p.n_halted_90d,
  p.p50_completion_minute_of_day, p.p90_completion_minute_of_day,
  COALESCE(d.n_dep_gate_aborts_90d, 0) AS n_dep_gate_aborts_90d,
  COALESCE(r.n_retry_events, 0) AS n_retry_events,
  COALESCE(r.n_retries_exhausted, 0) AS n_retries_exhausted,
  COALESCE(r.n_dep_waits, 0) AS n_dep_waits,
  COALESCE(r.n_dep_wait_futile, 0) AS n_dep_wait_futile,
  COALESCE(r.n_active_refires, 0) AS n_active_refires,
  COALESCE(r.total_wait_minutes, 0) AS total_wait_minutes,
  (p.n_log_rows_90d >= 20) AS min_n_met
FROM per_routine p
LEFT JOIN dep_gate_aborts d USING (routine)
LEFT JOIN retry_agg r USING (routine)
ORDER BY p.routine;

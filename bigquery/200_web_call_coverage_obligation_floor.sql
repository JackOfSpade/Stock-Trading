-- ===== 200: state.web_call_coverage — pre-obligation floor for ops.web_calls telemetry =====
-- (2026-08-26, alert triage — alerts 1826885e, d0e4711c, 6f3eb667, e07edd58, ops_note f9de517a.)
--
-- WHY: ops.web_calls and the obligation to log metered external calls were introduced on 2026-08-17
-- (bigquery/174_web_call_telemetry.sql). state.web_call_coverage (bigquery/191_web_call_coverage.sql)
-- queries completed runs across a trailing 45-day window without an obligation floor date. Lower-
-- frequency routines like SL1 (quarterly) and M1a, M2, M3 (monthly) last executed on 2026-08-01 /
-- 2026-08-03 — prior to the introduction of ops.web_calls. Because their latest completed run in the
-- window carried 0 ops.web_calls rows, OPS0 STEP 5 repeatedly raised false-positive
-- web_call_coverage_gap warnings on every daily sweep.
--
-- THE FIX: Floor `run_date` at GREATEST(DATE_SUB(CURRENT_DATE("America/Denver"), INTERVAL 45 DAY), DATE '2026-08-17')
-- in both CTEs (runs and logged). Completed runs prior to 2026-08-17 are not evaluated for web_calls
-- compliance because the table and obligation did not exist when those runs executed.
--
-- SUPERSEDES `state.web_call_coverage` in bigquery/191_web_call_coverage.sql.
-- Apply after bigquery/191_web_call_coverage.sql. Defines exactly one view; creates, redefines
-- or drops nothing else.

CREATE OR REPLACE VIEW `stock-trading-498512.state.web_call_coverage` AS
WITH runs AS (
  SELECT routine, run_date
  FROM `stock-trading-498512.ops.run_log`
  WHERE status = 'completed'
    AND run_date >= GREATEST(DATE_SUB(CURRENT_DATE("America/Denver"), INTERVAL 45 DAY), DATE '2026-08-17')
  GROUP BY routine, run_date
),
logged AS (
  SELECT routine, run_date, COUNT(*) AS logged_row_count
  FROM `stock-trading-498512.ops.web_calls`
  WHERE run_date >= GREATEST(DATE_SUB(CURRENT_DATE("America/Denver"), INTERVAL 45 DAY), DATE '2026-08-17')
  GROUP BY routine, run_date
)
SELECT
  r.routine,
  r.run_date,
  COALESCE(l.logged_row_count, 0) AS logged_row_count,
  r.routine IN ('D1','D2a','W1','W2','W3','W5','M1a','M2','M3','Q2','Q3','SL1','OPS1','OPS2')
    AS expected_metered,
  -- PROVEN gap: a completed run of a routine the prose obliges to log, with zero rows logged for
  -- that (routine, run_date). This is the only column OPS0's STEP 5 raise reads.
  (r.routine IN ('D1','D2a','W1','W2','W3','W5','M1a','M2','M3','Q2','Q3','SL1','OPS1','OPS2')
     AND l.routine IS NULL) AS missing_telemetry,
  CURRENT_TIMESTAMP() AS checked_at
FROM runs r
LEFT JOIN logged l
  ON l.routine = r.routine AND l.run_date = r.run_date;

-- Process-reliability scorecard — the template self-improvement loop (2026-07-03, self-improvement
-- audit WO-6). Project: stock-trading-498512. Apply after 10_observability.sql (ops.run_log).
--
-- STATUS: DORMANT per ops/autonomy_levels.yaml (loop id `process_reliability`). This file builds ONLY
-- the measurement view — the sensor. No routine reads this to change behavior yet. The loop's own
-- natural gate (>=3 consecutive weeks of data / N>=20 run_log rows per routine, see the W5 spec in
-- Claude_Task_Plan.md) is what governs when a human should consider promoting it past `dormant` in
-- ops/autonomy_levels.yaml — that promotion is a deliberate, evidenced, separate decision, not
-- something this view or its consumer triggers automatically.
--
-- WHY THIS IS THE SAFEST SELF-IMPROVEMENT LOOP TO BUILD FIRST: it reads ops.run_log, which is
-- high-N and grows every routine-day (unlike the 8-closed-trade P&L sample), and its change surface
-- is a bounded, version-controlled PROCESS CONSTANT (a cadence deadline, a stalled-run threshold) —
-- it never touches strategy/P&L math. This is the pattern every other loop in the audit should copy.

CREATE OR REPLACE VIEW `stock-trading-498512.analytics.routine_health_scorecard` AS
WITH runs AS (
  SELECT routine, run_date, status, log_ts,
    TIME(log_ts, 'America/Denver') AS completion_time_of_day_mt
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
    -- p50/p90 completion time-of-day (America/Denver), completed runs only, last 90 days.
    APPROX_QUANTILES(IF(status = 'completed', TIME_DIFF(completion_time_of_day_mt, TIME '00:00:00', MINUTE), NULL), 100)[OFFSET(50)] AS p50_completion_minute_of_day,
    APPROX_QUANTILES(IF(status = 'completed', TIME_DIFF(completion_time_of_day_mt, TIME '00:00:00', MINUTE), NULL), 100)[OFFSET(90)] AS p90_completion_minute_of_day
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
)
SELECT
  p.routine,
  p.n_log_rows_90d,
  p.n_completed_90d, p.n_failed_90d, p.n_halted_90d,
  p.p50_completion_minute_of_day, p.p90_completion_minute_of_day,
  COALESCE(d.n_dep_gate_aborts_90d, 0) AS n_dep_gate_aborts_90d,
  -- The loop's own minimum-observation floor: >=20 log rows in the window (~3 weeks for a daily
  -- routine). Below this, W5 should log the observation but propose NO change.
  (p.n_log_rows_90d >= 20) AS min_n_met
FROM per_routine p
LEFT JOIN dep_gate_aborts d USING (routine)
ORDER BY p.routine;

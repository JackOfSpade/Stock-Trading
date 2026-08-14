-- Process-reliability scorecard — the template self-improvement loop (2026-07-03, self-improvement
-- audit WO-6). Project: stock-trading-498512. Apply after 10_observability.sql (ops.run_log).
--
-- STATUS: active_auto per ops/autonomy_levels.yaml (loop id `process_reliability`; rev 2026-07-10b,
-- round-2 autonomy conversion, owner directive + explicit confirmation). This file builds the
-- measurement view — the sensor. W5 (Claude_Task_Plan.md) reads it every cycle and SELF-APPLIES a
-- bounded process-constant change, with no human review, once the loop's own natural data-sufficiency
-- gate fires (state.process_reliability_readiness.ready_for_change = TRUE: >=3 consecutive weeks of
-- data / N>=20 run_log rows per routine AND a 3-consecutive-cycle deadline-threat persistence — see
-- bigquery/37_self_improvement_autonomy.sql). The gate is unchanged; only the human-merged-PR
-- requirement was removed.
--
-- WHY THIS IS THE SAFEST SELF-IMPROVEMENT LOOP TO BUILD FIRST: it reads ops.run_log, which is
-- high-N and grows every routine-day (unlike the 8-closed-trade P&L sample), and its change surface
-- is a bounded, version-controlled PROCESS CONSTANT (a cadence deadline, a stalled-run threshold) —
-- it never touches strategy/P&L math. This is the pattern every other loop in the audit should copy.
--
-- SUPERSEDED (2026-07-18): analytics.routine_health_scorecard is now defined canonically in
-- bigquery/89_scorecard_midnight_retry.sql — apply that file, not this one. bigquery/89 fixes a
-- midnight-wrap bug in the completion-minute-of-day metric below and adds retry/dependency-wait
-- telemetry columns; the CREATE OR REPLACE VIEW statement immediately below is kept here,
-- unmodified, for DR-rebuild apply-in-order reference only. DO NOT re-apply it live in isolation.
-- SUPERSEDED AGAIN (2026-08-14): bigquery/89 above has itself been superseded — the current
-- canonical definition of analytics.routine_health_scorecard is now bigquery/171_scorecard_routine_
-- id_normalization.sql, which normalizes the routine id with REPLACE(routine, '·', '_') so the
-- legacy U+00B7 middle-dot ids AR·att/AR·orc fold onto canonical AR_att/AR_orc instead of appearing
-- as separate rows. The CREATE OR REPLACE VIEW statement immediately below remains kept here,
-- unmodified, for DR-rebuild apply-in-order reference only. DO NOT re-apply it live in isolation.

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

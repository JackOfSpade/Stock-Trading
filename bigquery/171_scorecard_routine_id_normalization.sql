-- 171_scorecard_routine_id_normalization.sql (2026-08-14)
-- Project: stock-trading-498512. Apply after 170_run_log_note_write_time_guard.sql.
-- Redefines analytics.routine_health_scorecard (canonical since bigquery/89, which superseded
-- bigquery/27). No procedure changes, no scheduled-query version bump.
--
-- ===== WHY =====
-- Surfaced during the 2026-08-13 D2a run_log_note_missing triage (alert
-- c26afde4-fdc3-4799-996b-390a42826f4d) and fixed on owner instruction to close every gap the audit
-- found, not only the one that alerted.
--
-- ops.run_log holds TWO spellings for two routines: the canonical ASCII AR_att/AR_orc, and a legacy
-- AR·att/AR·orc using U+00B7 MIDDLE DOT (hex c2b7), written 2026-06-19..2026-07-01 and never since.
-- Commit 9b0bd18 (2026-07-01, RUNBOOK §28) standardised the ids to ASCII after agents mis-transcribed
-- the middle dot twice; that fix landed and stuck — no middle-dot row exists in the 44 days since, and
-- the two join-key consumers that needed to tolerate the legacy rows (state.instruction_drift and
-- state.routine_catchup_window) were normalised at the time. THIS view was not, and it groups on the
-- raw column, so AR_att and AR_orc still appear as FOUR rows rather than two while the legacy rows
-- remain inside its rolling 90-day window (they age out ~2026-09-29):
--     AR_att  n_log_rows_90d=72   AR·att  n_log_rows_90d=18
--     AR_orc  n_log_rows_90d=72   AR·orc  n_log_rows_90d=26
--
-- ===== WHAT THIS IS AND IS NOT =====
-- It is a correctness defect in the SENSOR: n_log_rows_90d, the completion percentiles and
-- n_dep_gate_aborts_90d are all understated for AR_att/AR_orc. It is NOT currently mistuning anything,
-- and that was verified rather than assumed before writing this file. The scorecard's only real
-- consumer is W5's autonomous process_reliability loop, which acts only where a routine's p90 sits near
-- a version-controlled deadline; the sole such constant, cadence_watch_deadline_local (21:00 MT), is
-- scoped to the DAILY routines D1/D2/D3. AR_att/AR_orc are monitor_class queue_driven, excluded from
-- state.cadence_watch entirely, and carry no deadline for W5 to tune against — so
-- state.process_reliability_readiness (WHERE deadline_key IS NOT NULL) filters them out however the
-- rows group. min_n_met does not flip either: the ASCII rows alone already clear the n>=20 floor.
-- Fixed because a monitoring sensor that miscounts is worth correcting on its own terms.
--
-- ===== WHY NOT THE EXISTING NORMALIZATION EXPRESSION =====
-- state.instruction_drift and state.routine_catchup_window both use REGEXP_REPLACE(routine,
-- r'[·._-]', ''). That is correct THERE and wrong HERE, and the difference is not stylistic. In both of
-- those views the stripped form is used only as an internal JOIN/PARTITION key and is never returned:
-- routine_catchup_window outputs r.routine, instruction_drift outputs COALESCE(c.routine, li.routine).
-- A key is allowed to be non-canonical. This view's `routine` is an OUTPUT column that W5 writes into
-- ops.process_reliability_observations.routine, which state.process_reliability_readiness keys on as
-- (routine, deadline_key) — so strip-all would emit 'ARatt'/'ARorc', ids that match nothing in
-- ops/cadence.yaml or ops.routine_catalog, and would break that keying to fix a display bug.
-- REPLACE(routine, '·', '_') instead maps each legacy id onto its own canonical spelling.
--
-- BLAST RADIUS, measured across all 37 distinct routine labels in ops.run_log: exactly two labels
-- change (AR·att -> AR_att, AR·orc -> AR_orc) and the other 35 are byte-identical before and after.
-- No label contains a middle dot other than those two. The substitution is also applied to the
-- ops.alerts.source and state.retry_telemetry.routine join keys below; both are verified to contain
-- ZERO middle-dot rows today, so those two are measured no-ops, applied defensively so a legacy
-- spelling arriving in either upstream cannot silently reopen the same split.
--
-- SUPERSEDED LIVE by bigquery/177_backfill_note_regex_survives_correction.sql — current single
-- source of truth for analytics.routine_health_scorecard. 177 hardens the is_backfilled note-regex
-- (below) to also match a later human correction of a backfilled row's note, which can legitimately
-- prepend text ahead of the "auto-backfilled..." token this view's REGEXP_CONTAINS anchors on. The
-- CREATE OR REPLACE VIEW statement immediately below is kept here, unmodified, for DR-rebuild
-- apply-in-order reference only. DO NOT re-apply it live in isolation.

CREATE OR REPLACE VIEW `stock-trading-498512.analytics.routine_health_scorecard` AS
WITH runs AS (
  SELECT REPLACE(routine, '·', '_') AS routine, run_date, status, log_ts,
    -- MIDNIGHT FIX (bigquery/89): minutes elapsed since midnight of run_date (the operating day),
    -- NOT minutes-of-day of log_ts's own calendar date — see PROBLEM (a) above. A completion that
    -- lands the calendar day after run_date now reads > 1440 instead of wrapping near zero.
    DATETIME_DIFF(DATETIME(log_ts, 'America/Denver'), DATETIME(run_date), MINUTE) AS completion_minute_of_day,
    -- BACKFILLED-ROW FLAG (2026-08-04). A backfilled row's log_ts is the moment the BACKFILL ran, not
    -- when the routine finished — ops.sp_backfill_run_log_from_markers (bigquery/38) is invoked from
    -- cadence_check.sql at ~05:15 UTC (22:15-23:15 MT), and hand-backfills are written whenever a human
    -- or routine noticed. Such a row carries NO information about completion time, so including it in the
    -- percentiles below does not merely add noise, it manufactures a late tail out of nothing.
    -- MEASURED 2026-08-04: D1's trailing-90d p90 was 1275 min (21:15 MT) with these rows in and 1006 min
    -- (16:46 MT) with them out, against a p50 of 978 — and that phantom p90 is what drove W5's
    -- process_reliability loop to autotune cadence_watch_deadline_local 21:00 -> 21:45, a change its own
    -- ceiling alert (b7922945) then correctly reported could never clear the signal that triggered it.
    -- The fix belongs HERE, at the reader, not at the writer: writing an "honest" log_ts in bigquery/38
    -- was evaluated and rejected the same day, because log_ts is load-bearing for the SAME-DAY DOUBLE-RUN
    -- GUARD (a pre-noon log_ts would stop the evening cohort counting a prior completion) and because a
    -- writer-side fix could not repair rows already written. See bigquery/38's header for the full note.
    --
    -- ANCHORED PREFIX, NOT A BARE 'backfill' SEARCH — this distinction is the whole correctness of the
    -- flag. A loose LIKE '%backfill%' also matches ordinary runs whose note merely DISCUSSES backfilling
    -- (measured 2026-08-04: 6 such D2 rows and 1 D3 row, e.g. "no backfill snapshots" and "D2 completed
    -- via marker backfill"), which would silently delete 7 genuine completions from the distribution.
    -- Anchoring on the leading token matches the 4 note forms an actual backfill writes
    -- ("auto-backfilled from commit marker...", "auto-backfilled from git evidence...", "Backfilled: ...",
    -- "Backfilled post-hoc ...") and nothing else: verified 9 D1 / 1 D2 / 1 D3 matches, 0 false positives.
    -- Any new backfill writer MUST keep that prefix, or its rows will silently re-enter these percentiles.
    REGEXP_CONTAINS(COALESCE(note, ''), r'(?i)^(auto-)?backfilled') AS is_backfilled
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
    -- completions) — see PROBLEM/FIX (a) above. Backfilled rows are EXCLUDED as of 2026-08-04 — their
    -- log_ts is backfill time, not completion time; see the is_backfilled comment in `runs` above.
    -- n_backfilled_excluded_90d is surfaced so the exclusion is never silent (a dropped-rows count a
    -- reader can see beats a percentile that quietly moved).
    APPROX_QUANTILES(IF(status = 'completed' AND NOT is_backfilled, completion_minute_of_day, NULL), 100)[OFFSET(50)] AS p50_completion_minute_of_day,
    APPROX_QUANTILES(IF(status = 'completed' AND NOT is_backfilled, completion_minute_of_day, NULL), 100)[OFFSET(90)] AS p90_completion_minute_of_day,
    COUNTIF(status = 'completed' AND is_backfilled) AS n_backfilled_excluded_90d
  FROM runs
  GROUP BY routine
),
dep_gate_aborts AS (
  -- A dep-gate abort (ops.sp_assert_deps RAISE) logs no run_log row for that attempt (the RAISE fires
  -- before sp_routine_end) — it is visible only as an ops.alerts 'missing_dependency' row. Surfaced
  -- here by count so a routine whose upstream is chronically late shows up without a run_log row to
  -- join on.
  SELECT REPLACE(source, '·', '_') AS routine, COUNT(*) AS n_dep_gate_aborts_90d
  FROM `stock-trading-498512.ops.alerts`
  WHERE category = 'missing_dependency'
    AND alert_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 90 DAY)
  GROUP BY REPLACE(source, '·', '_')
),
retry_agg AS (
  -- Per-routine rollup of state.retry_telemetry (bigquery/88) over the same 90-day token history the
  -- view already carries (retry_telemetry's own window is likewise 90 days, so no re-filtering here).
  SELECT
    REPLACE(routine, '·', '_') AS routine,
    COUNTIF(token_type = 'RETRY') AS n_retry_events,
    COUNTIF(token_type = 'RETRY' AND outcome = 'exhausted') AS n_retries_exhausted,
    COUNTIF(token_type = 'DEPWAIT') AS n_dep_waits,
    COUNTIF(token_type = 'DEPWAIT' AND outcome = 'futile') AS n_dep_wait_futile,
    COUNTIF(token_type = 'DEPWAIT' AND refired IS NOT NULL AND refired != 'none') AS n_active_refires,
    ROUND(SUM(IF(token_type IN ('RETRY', 'DEPWAIT'), waited_s, NULL)) / 60) AS total_wait_minutes
  FROM `stock-trading-498512.state.retry_telemetry`
  GROUP BY REPLACE(routine, '·', '_')
)
SELECT
  p.routine,
  p.n_log_rows_90d,
  p.n_completed_90d, p.n_failed_90d, p.n_halted_90d,
  -- Surfaced so the backfilled-row exclusion is never silent: a reader comparing n_completed_90d
  -- against this can see exactly how many completions were held out of the percentiles below.
  p.n_backfilled_excluded_90d,
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

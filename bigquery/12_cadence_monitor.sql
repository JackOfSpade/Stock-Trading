-- BigQuery cadence monitor + dependency enforcement (fixes A3 + C1). Project: stock-trading-498512.
-- Closes two gaps the stack review found:
--   * A3 — ops/cadence.yaml is described as "the source of truth for WHAT runs WHEN ... so the
--     freshness monitor has something to check missed runs against," but NOTHING read it. This
--     encodes the cadence in SQL and surfaces, per operating day, which routines were EXPECTED and
--     whether they logged a 'completed' run (state.cadence_watch).
--   * C1 — inter-routine dependencies (D1->D2->D3, W1/W2/W3->W4, M1b/M2/M3->M4, ...) were enforced
--     ONLY by schedule timing. ops.sp_assert_deps lets an action routine HARD-FAIL (alert + RAISE)
--     if an upstream routine has not logged 'completed' for the operating day, instead of silently
--     running on stale inputs.
--
-- Depends on 09_market_calendar.sql (state.trading_day_today / state.market_calendar) and
-- 10_observability.sql (ops.run_log, ops.sp_raise_alert_once). Idempotent (OR REPLACE). Apply via
-- the BigQuery MCP execute_sql AFTER 09 and 10.
--
-- SELF-BOOTSTRAPPING (the key design choice): most routines do not yet self-log (the run-logging
-- convention is instruction-only and was being skipped — that is why ops.run_log was empty). If the
-- monitor alerted on every routine that never logs, it would false-alarm constantly. So a routine is
-- "monitored" ONLY once it has logged >=1 'completed' run in the last 14 days. A routine therefore
-- enters the watched set automatically the first time it adopts sp_routine_start/end, and a SUBSEQUENT
-- missed run is then detected. (As of 2026-06-19 the D1/D2/D3/AR routines have adopted the wrappers and
-- are logging, so they are monitored.)

-- ===== state.cadence_expected_today — which routine IDs are due on the current operating day =====
-- Encodes ops/cadence.yaml's schedules. America/Denver operating day via state.trading_day_today.
--   daily_trading  : every trading day              (D1, D2)
--   daily_all      : every calendar day             (D3 — queue/calendar upkeep incl. non-trading days)
--   weekly_sun     : Sundays                         (W1..W5)
--   monthly_ftd    : first TRADING day of the month  (M1a,M1b,M2,M3,M4,M5)
--   quarterly_ftd  : first TRADING day of the quarter (Q1..Q4)
--   annual_ftd     : first TRADING day of the year    (A1..A3)
-- The queue-driven adversarial routines (AR_att / AR_orc) fire only if a review is due,
-- which is NOT derivable from the calendar, so they are intentionally NOT listed as calendar-expected.
CREATE OR REPLACE VIEW `stock-trading-498512.state.cadence_expected_today` AS
WITH t AS (
  SELECT
    td.today,
    td.is_trading_day,
    EXTRACT(DAYOFWEEK FROM td.today) AS dow,   -- 1 = Sunday
    td.today = (SELECT MIN(cal_date) FROM `stock-trading-498512.state.market_calendar`
                WHERE is_trading_day AND DATE_TRUNC(cal_date, MONTH)   = DATE_TRUNC(td.today, MONTH))   AS is_ftd_month,
    td.today = (SELECT MIN(cal_date) FROM `stock-trading-498512.state.market_calendar`
                WHERE is_trading_day AND DATE_TRUNC(cal_date, QUARTER) = DATE_TRUNC(td.today, QUARTER)) AS is_ftd_quarter,
    td.today = (SELECT MIN(cal_date) FROM `stock-trading-498512.state.market_calendar`
                WHERE is_trading_day AND DATE_TRUNC(cal_date, YEAR)    = DATE_TRUNC(td.today, YEAR))    AS is_ftd_year
  FROM `stock-trading-498512.state.trading_day_today` td
),
routines AS (
  SELECT * FROM UNNEST([
    STRUCT('D1'  AS routine, 'daily_trading' AS schedule),
    STRUCT('D2'  AS routine, 'daily_trading' AS schedule),
    STRUCT('D3'  AS routine, 'daily_all'     AS schedule),
    STRUCT('W1'  AS routine, 'weekly_sun'    AS schedule),
    STRUCT('W2'  AS routine, 'weekly_sun'    AS schedule),
    STRUCT('W3'  AS routine, 'weekly_sun'    AS schedule),
    STRUCT('W4'  AS routine, 'weekly_sun'    AS schedule),
    STRUCT('W5'  AS routine, 'weekly_sun'    AS schedule),
    STRUCT('M1a' AS routine, 'monthly_ftd'   AS schedule),
    STRUCT('M1b' AS routine, 'monthly_ftd'   AS schedule),
    STRUCT('M2'  AS routine, 'monthly_ftd'   AS schedule),
    STRUCT('M3'  AS routine, 'monthly_ftd'   AS schedule),
    STRUCT('M4'  AS routine, 'monthly_ftd'   AS schedule),
    STRUCT('M5'  AS routine, 'monthly_ftd'   AS schedule),
    STRUCT('Q1'  AS routine, 'quarterly_ftd' AS schedule),
    STRUCT('Q2'  AS routine, 'quarterly_ftd' AS schedule),
    STRUCT('Q3'  AS routine, 'quarterly_ftd' AS schedule),
    STRUCT('Q4'  AS routine, 'quarterly_ftd' AS schedule),
    STRUCT('A1'  AS routine, 'annual_ftd'    AS schedule),
    STRUCT('A2'  AS routine, 'annual_ftd'    AS schedule),
    STRUCT('A3'  AS routine, 'annual_ftd'    AS schedule)
  ])
)
SELECT r.routine, r.schedule, t.today
FROM routines r, t
WHERE CASE r.schedule
        WHEN 'daily_trading' THEN t.is_trading_day
        WHEN 'daily_all'     THEN TRUE
        WHEN 'weekly_sun'    THEN t.dow = 1
        WHEN 'monthly_ftd'   THEN t.is_ftd_month
        WHEN 'quarterly_ftd' THEN t.is_ftd_quarter
        WHEN 'annual_ftd'    THEN t.is_ftd_year
        ELSE FALSE
      END;

-- ===== state.cadence_watch — expected vs logged for the operating day (observability + alert input) =====
-- needs_attention (the alarm signal) fires ONLY for routines that are (a) a DAILY routine (D1/D2/D3 —
-- unambiguous run-day) AND (b) expected today AND (c) already in the monitored set (logged a 'completed'
-- run in the last 14 days) AND (d) have not logged 'completed' today AND (e) Denver-time is past the
-- routines' after-close completion deadline (the DEADLINE GUARD — see below). Non-daily routines are
-- shown for observation but excluded from the alarm (their predicted day can mismatch the real trigger).
CREATE OR REPLACE VIEW `stock-trading-498512.state.cadence_watch` AS
SELECT
  e.routine,
  e.schedule,
  e.today,
  -- monitored = the routine has demonstrably adopted run-logging recently, so a gap is meaningful
  EXISTS(SELECT 1 FROM `stock-trading-498512.ops.run_log` r
         WHERE r.routine = e.routine AND r.status = 'completed'
           AND r.run_date >= DATE_SUB(e.today, INTERVAL 14 DAY)) AS monitored,
  EXISTS(SELECT 1 FROM `stock-trading-498512.ops.run_log` r
         WHERE r.routine = e.routine AND r.status = 'completed'
           AND r.run_date = e.today) AS ran_completed_today,
  -- needs_attention = the ALARM signal (drives cadence_check.sql + the dashboard panel). Scoped to the
  -- DAILY routines only (D1/D2/D3): their expected run-day is unambiguous. The weekly/monthly/quarterly/
  -- annual predictions (Sunday / first-trading-day) are inferred and may not match the real trigger day
  -- (e.g. weeklies run "Sunday OR Monday"), which would false-alarm once such a routine becomes monitored.
  -- Those rows stay VISIBLE here (with monitored/ran_completed_today) for manual observation, but do not
  -- raise — promote them into the alarm set only after confirming their exact trigger day.
  (e.schedule IN ('daily_trading','daily_all')
   AND EXISTS(SELECT 1 FROM `stock-trading-498512.ops.run_log` r
          WHERE r.routine = e.routine AND r.status = 'completed'
            AND r.run_date >= DATE_SUB(e.today, INTERVAL 14 DAY))
   AND NOT EXISTS(SELECT 1 FROM `stock-trading-498512.ops.run_log` r
                  WHERE r.routine = e.routine AND r.status = 'completed'
                    AND r.run_date = e.today)
   -- DEADLINE GUARD (2026-06-25): only alarm AFTER the daily routines' real after-close completion
   -- deadline has passed in America/Denver. Without this, ANY execution of this view / cadence_check.sql
   -- BEFORE the routines have run today (an off-schedule, manual, or duplicate run) flags D1/D2/D3 as
   -- "missed" merely because it is not yet their time — the exact 2026-06-21 (12:00 MT) and 2026-06-24
   -- (09:37 MT) morning false-positive CRITICALs (RUNBOOK §20 follow-up). 21:00 Denver is comfortably
   -- past the latest observed completion (D2 ~17:47, D3 ~18:36) yet well before the 23:15 Denver
   -- (05:15 UTC) SCHEDULED cadence_check run, so a GENUINELY missed routine still fires critical at the
   -- scheduled run. Computed in the America/Denver named zone ⇒ DST-safe (no hardcoded UTC offset). Pure
   -- wall-clock, NOT gated on is_trading_day, so D3's daily_all miss-detection still works on
   -- weekends/holidays (D3 runs every calendar day).
   AND DATETIME(CURRENT_TIMESTAMP(), 'America/Denver') >= DATETIME(e.today, TIME '21:00:00')
  ) AS needs_attention,
  CURRENT_TIMESTAMP() AS checked_at
FROM `stock-trading-498512.state.cadence_expected_today` e;

-- ===== ops.sp_assert_deps — hard dependency gate for action routines (C1) =====
-- An action routine calls this at START with its upstream routine IDs. If a MONITORED upstream (one that
-- has logged a 'completed' run in the last 14 days) has NOT logged 'completed' for in_run_date, it raises
-- a durable alert AND a RAISE error so the routine halts instead of running on stale inputs.
-- Example (D2): CALL ops.sp_assert_deps('D2', ['D1'], <denver_today>);
--
-- SELF-BOOTSTRAPPING (same philosophy as state.cadence_watch): a dep that has NOT adopted run-logging
-- yet (no completed run in 14 days) is treated as satisfied, so turning the gate on can never block a
-- routine merely because an upstream doesn't self-log. The gate goes live for a dependency pair exactly
-- when the upstream starts logging via sp_routine_start/end — so it is safe to enable everywhere now.
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_assert_deps`(
  in_routine STRING, in_deps ARRAY<STRING>, in_run_date DATE
)
BEGIN
  DECLARE missing STRING;
  SET missing = (
    SELECT STRING_AGG(d, ', ' ORDER BY d)
    FROM UNNEST(in_deps) AS d
    WHERE EXISTS (  -- d is a monitored routine (has adopted run-logging recently)
            SELECT 1 FROM `stock-trading-498512.ops.run_log` r
            WHERE r.routine = d AND r.status = 'completed'
              AND r.run_date >= DATE_SUB(in_run_date, INTERVAL 14 DAY))
      AND NOT EXISTS (  -- ...but it did not complete for this run_date
            SELECT 1 FROM `stock-trading-498512.ops.run_log` r
            WHERE r.routine = d AND r.run_date = in_run_date AND r.status = 'completed')
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

-- ===== ops.sp_routine_start / sp_routine_end — BEST-EFFORT run-logging (never gate, never abort) =====
-- SAFETY MODEL (so a logging mistake can NEVER break a routine — there are no legacy callers, this is
-- the one canonical form): these procedures ONLY log; they do NOT gate. Callers wrap them in a
-- best-effort block (Claude_Task_Plan.md "Observability" gives the exact copy-paste template), so ANY
-- error in the call — wrong arity, transient, type — is swallowed and the routine's real work proceeds.
-- The dependency GATE is a SEPARATE, deliberately-FATAL call: ops.sp_assert_deps, which action routines
-- make FIRST and do NOT wrap (a missing upstream must abort). Keeping the gate out of sp_routine_start
-- is what lets the log call be wrapped without defanging the gate.
-- sp_routine_start captures the verbatim trigger instruction -> ops.run_log.instruction ->
-- state.routine_last_instruction. Adopting these auto-enrolls the routine into cadence monitoring (A3).
--   GATE  (action routines, FATAL, not wrapped): CALL ops.sp_assert_deps('D2', ['D1'], <denver_today>);
--   START (best-effort): CALL ops.sp_routine_start('D2', <denver_today>, <session>, <branch>,
--            'Read Claude_Task_Plan.md. Perform D2. Daily Action Conversion — regular routine.');
--   END   (best-effort): CALL ops.sp_routine_end('D2', <denver_today>, 'completed', <session>, <branch>, <rows>, NULL, <note>);
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_routine_start`(
  in_routine STRING, in_run_date DATE, in_session STRING, in_branch STRING, in_instruction STRING
)
BEGIN
  INSERT INTO `stock-trading-498512.ops.run_log`
    (routine, run_date, status, session_id, branch, instruction)
  VALUES (in_routine, in_run_date, 'started', in_session, in_branch, in_instruction);
END;

CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_routine_end`(
  in_routine STRING, in_run_date DATE, in_status STRING, in_session STRING, in_branch STRING,
  in_rows INT64, in_error STRING, in_note STRING
)
BEGIN
  CALL `stock-trading-498512.ops.sp_log_run`(in_routine, in_run_date, in_status, in_session, in_branch, in_rows, in_error, in_note);
END;

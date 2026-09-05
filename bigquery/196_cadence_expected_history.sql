-- ===== 196: state.cadence_expected_history + state.fleet_blackout_days =====
-- (2026-08-23 — closes the recurrence path behind W1's false FLEET-WIDE OUTAGE alert, f6ff58ee.)
--
-- WHAT HAPPENED. On 2026-08-23 W1's pre-flight observed ZERO ops.run_log rows on 2026-08-21 and
-- 2026-08-22 and raised a WARNING claiming a "FLEET-WIDE SCHEDULED-TRIGGER OUTAGE" on both days.
-- It was a FALSE POSITIVE: 08-21 was a Friday and 08-22 a Saturday, and since the 2026-08-08
-- daily-tier consolidation NO routine in the fleet is scheduled on either day (ops/cadence.yaml's
-- `monitor_class: daily_sun_thu`). W3 refuted and resolved it the same day. The alert reached the
-- operator's inbox before that refutation, which is the cost this file exists to prevent.
--
-- WHY THE EXISTING MACHINERY DID NOT PREVENT IT — the actual defect, and it is NOT a missing
-- predicate. state.cadence_expected_today (bigquery/12) already encodes the rule correctly:
-- `WHEN 'daily_sun_thu' THEN t.dow NOT IN (6, 7)`. state.cadence_watch and ops.sp_sq_cadence_check
-- both build on it and were, correctly, SILENT across 08-21/08-22 — there was nothing to miss.
-- The hole is that every one of those objects is TODAY-ONLY: they join state.trading_day_today,
-- which is `SELECT CURRENT_DATE('America/Denver')` (bigquery/09_market_calendar.sql:134). A session
-- looking BACKWARD at two already-elapsed days therefore has no cadence-aware object it can query
-- at all, so it falls back to counting raw ops.run_log rows -- and a raw row count cannot tell an
-- expected-idle Friday apart from a real outage. W1 did exactly that, and nothing was available to
-- correct it. This file supplies the missing retrospective form.
--
-- THE GENERIC LESSON, stated because it is the reusable half: a monitor that is correct but
-- evaluable only for `today` leaves every retrospective question unanswerable, and an unanswerable
-- question gets answered by improvisation. Prospective correctness is not sufficient; the same
-- predicate has to be reachable for a past date, or a future session re-derives it wrongly.
--
-- NO ROUTINE-LIST DUPLICATION, DELIBERATELY. bigquery/12/15/24/105/114/132 each carry a
-- marker-delimited GENERATED routine list maintained by scripts/gen_routine_lists.py, and
-- scripts/check_cadence_consistency.py diffs them against ops/cadence.yaml. This file adds NO
-- seventh generated region: it reads (routine, monitor_class) from state.routine_catchup_window
-- (bigquery/105), which already carries the FULL roster including the 4 queue_driven ids and is
-- already generator-maintained and CI-checked. One less list to drift.
--
-- KNOWN AND ACCEPTED LIMITATION -- TODAY'S CADENCE IS APPLIED RETROACTIVELY. The (routine ->
-- monitor_class) map is read live from state.routine_catchup_window, so a date BEFORE a cadence
-- change is evaluated against the CURRENT cadence, not the one in force at the time. MEASURED
-- example: 2026-08-07 was a Friday BEFORE the 2026-08-08 daily-tier consolidation; 24 rows were
-- logged that day, yet this view reports expected_routines = 0 for it, because today's daily_sun_thu
-- map says no routine is scheduled on a Friday.
-- FOR EVERY CADENCE CHANGE MADE SO FAR the error runs in the SAFE direction -- the 2026-08-08 change
-- NARROWED the day-set, so applying today's map backwards can only UNDER-state what was expected, and
-- state.fleet_blackout_days can therefore miss a historical outage but not invent one. State that as
-- the empirical fact it is, NOT as a property this SQL enforces (corrected 2026-08-23 in review): a
-- future cadence change that WIDENS a routine's day-set would, applied retroactively, mark a
-- legitimately-idle historical day as expected and could manufacture exactly the false positive this
-- file exists to prevent. If you ever widen a monitor_class day-set, re-read this view's output over
-- the affected history before trusting it. Do NOT pre-emptively "fix" this by back-versioning the
-- cadence map unless a real question needs that -- a false negative on a 3-month-old Friday costs
-- nothing, and the back-versioning machinery would be a standing maintenance burden.
--
-- Additive -- new objects, supersedes nothing.

-- ===== state.cadence_expected_history -- was routine R expected on past date D, and did it run? =====
-- The retrospective twin of state.cadence_expected_today. Same monitor_class predicates, evaluated
-- per calendar date over a trailing 90-day window instead of only for CURRENT_DATE.
--
-- queue_driven routines (AR_att/AR_orc/SL2/SL5/M1R) appear with expected = FALSE on every date, exactly
-- as they are excluded from state.cadence_expected_today: their firing day is not calendar-derivable
-- (they fire only when a queue entry is due), so "expected" is undefined for them and they must never
-- contribute to a blackout verdict. state.queue_driven_silence_watch (bigquery/132) is their monitor.
CREATE OR REPLACE VIEW `stock-trading-498512.state.cadence_expected_history` AS
WITH bounds AS (
  SELECT CURRENT_DATE('America/Denver') AS today_denver
),
cal AS (
  -- FTD flags are computed with window functions over the FULL market calendar, then the trailing
  -- window is applied BELOW. Order matters: partitioning after a 90-day filter would make the first
  -- surviving trading day of a truncated month look like that month's first trading day. Computing
  -- over the whole calendar first makes the flags independent of the window.
  --
  -- (bigquery/12 states the same three flags as correlated scalar subqueries. That form is only legal
  -- there because state.trading_day_today is a ONE-ROW view; against a multi-row date spine BigQuery
  -- rejects it -- "Correlated subqueries that reference other tables are not supported unless they can
  -- be de-correlated". These window functions are the de-correlated equivalent, verified 2026-08-23 to
  -- return the identical flags.)
  SELECT
    mc.cal_date,
    mc.is_trading_day,
    EXTRACT(DAYOFWEEK FROM mc.cal_date) AS dow,   -- 1 = Sunday .. 7 = Saturday (BigQuery convention)
    mc.cal_date = MIN(IF(mc.is_trading_day, mc.cal_date, NULL)) OVER (PARTITION BY DATE_TRUNC(mc.cal_date, MONTH))   AS is_ftd_month,
    mc.cal_date = MIN(IF(mc.is_trading_day, mc.cal_date, NULL)) OVER (PARTITION BY DATE_TRUNC(mc.cal_date, QUARTER)) AS is_ftd_quarter,
    mc.cal_date = MIN(IF(mc.is_trading_day, mc.cal_date, NULL)) OVER (PARTITION BY DATE_TRUNC(mc.cal_date, YEAR))    AS is_ftd_year
  FROM `stock-trading-498512.state.market_calendar` mc
),
days AS (
  SELECT c.* FROM cal c, bounds b
  WHERE c.cal_date BETWEEN DATE_SUB(b.today_denver, INTERVAL 90 DAY) AND b.today_denver
),
routines AS (
  -- FULL roster incl. queue_driven, straight from the generator-maintained bigquery/105 view.
  SELECT DISTINCT routine, monitor_class FROM `stock-trading-498512.state.routine_catchup_window`
),
first_seen AS (
  -- SELF-BOOTSTRAPPING GUARD, and deliberately NOT the 14-day "monitored" window state.cadence_watch
  -- uses. A routine counts as in-service from its FIRST EVER completed run onward, permanently. A
  -- trailing-window definition would quietly un-monitor a routine during a long outage -- i.e. the
  -- longer the outage, the less this view would report -- which is the opposite of what a blackout
  -- detector must do. Once in service, always expected on its cadence days.
  SELECT routine, MIN(run_date) AS first_completed_date
  FROM `stock-trading-498512.ops.run_log`
  WHERE status = 'completed'
  GROUP BY routine
),
logged AS (
  SELECT run_date, routine,
         COUNT(*)                                        AS rows_logged,
         COUNTIF(status = 'completed')                   AS completed_rows,
         LOGICAL_OR(status IN ('failed', 'halted'))      AS had_terminal_failure
  FROM `stock-trading-498512.ops.run_log`
  WHERE run_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 90 DAY)
  GROUP BY run_date, routine
)
SELECT
  d.cal_date                                   AS run_date,
  r.routine,
  r.monitor_class,
  d.is_trading_day,
  d.dow,
  -- IN SERVICE on this date (had already logged a first completed run on or before it).
  COALESCE(fs.first_completed_date <= d.cal_date, FALSE) AS in_service,
  -- EXPECTED: byte-for-byte the same CASE as state.cadence_expected_today (bigquery/12), evaluated
  -- against this row's date instead of CURRENT_DATE. Keep these two in step -- if bigquery/12's
  -- predicate ever changes, change it here in the same pass.
  CASE r.monitor_class
    WHEN 'daily_trading' THEN d.is_trading_day
    WHEN 'daily_all'     THEN TRUE
    WHEN 'daily_sun_thu' THEN d.dow NOT IN (6, 7)   -- 6 = Friday, 7 = Saturday; NOT trading-day gated
    WHEN 'weekly_sun'    THEN d.dow = 1
    WHEN 'monthly_ftd'   THEN d.is_ftd_month
    WHEN 'quarterly_ftd' THEN d.is_ftd_quarter
    WHEN 'annual_ftd'    THEN d.is_ftd_year
    ELSE FALSE                                       -- queue_driven: not calendar-derivable
  END                                          AS expected,
  COALESCE(l.rows_logged, 0)                   AS rows_logged,
  COALESCE(l.completed_rows, 0)                AS completed_rows,
  COALESCE(l.had_terminal_failure, FALSE)      AS had_terminal_failure,
  CURRENT_TIMESTAMP()                          AS checked_at
FROM days d
CROSS JOIN routines r
LEFT JOIN first_seen fs ON fs.routine = r.routine
LEFT JOIN logged l      ON l.routine = r.routine AND l.run_date = d.cal_date;

-- ===== state.fleet_blackout_days -- the ONLY honest answer to "was there a fleet outage?" =====
-- ZERO ROWS = no fleet-wide blackout in the trailing 90 days. That is the whole contract, and it is
-- the same "expect zero rows" idiom as state.cadence_watch WHERE needs_attention and
-- state.strategy_funds_deficit.
--
-- A date qualifies ONLY when at least one in-service routine was EXPECTED on it and NOT ONE routine
-- logged a row of any status. A Friday or Saturday under the daily_sun_thu consolidation has zero
-- expected routines, so it can never qualify no matter how empty ops.run_log is -- which is exactly
-- the discrimination W1 could not make on 2026-08-23.
--
-- TODAY IS EXCLUDED (`< today_denver`), not an oversight: the current operating day is still in
-- progress, and its routines legitimately have not run yet at, say, 06:00 Denver. Including it would
-- make this view report a blackout every single morning -- reintroducing the false-alarm class it
-- exists to remove. The in-progress day is state.cadence_watch's job (it owns the after-close
-- DEADLINE GUARD); this view owns only already-elapsed days.
--
-- THE `HAVING` COUNTS ONLY THE EXPECTED ROUTINES' OWN ROWS -- corrected 2026-08-23 in review, and the
-- uncorrected form was a real masking bug, not a nicety. The first draft required `SUM(rows_logged) = 0`
-- across EVERY routine on the date. But the 4 `queue_driven` routines (AR_att/AR_orc/SL2/SL5) carry
-- `expected = FALSE` permanently while still logging on essentially every operating day, and
-- `ops.sp_backfill_run_log_from_markers` (bigquery/38, called from ops.sp_sq_cadence_check) inserts
-- stray `completed` rows for isolated logging failures -- 9 such backfills in under two months. Either
-- one alone holds the all-routine sum above zero, so a day on which EVERY expected routine died would
-- have been silently masked and this detector would have been close to unreachable. It now asks the
-- question it means to ask: did any routine that was EXPECTED on this date log anything at all?
CREATE OR REPLACE VIEW `stock-trading-498512.state.fleet_blackout_days` AS
SELECT
  run_date,
  ANY_VALUE(dow)                                                            AS dow,
  ANY_VALUE(is_trading_day)                                                 AS is_trading_day,
  COUNTIF(expected AND in_service)                                          AS expected_routines,
  STRING_AGG(IF(expected AND in_service, routine, NULL), ',' ORDER BY routine) AS expected_routine_ids,
  SUM(IF(expected AND in_service, rows_logged, 0))                          AS rows_logged_by_expected,
  -- Diagnostic only, deliberately NOT in the HAVING: what the rest of the fleet (queue-driven and
  -- not-expected-today routines) logged that date. A non-zero value here alongside a blackout row
  -- means the scheduler was alive but the expected cohort did not run -- a different fault than a
  -- total platform outage, and worth seeing.
  SUM(IF(expected AND in_service, 0, rows_logged))                          AS rows_logged_by_others,
  CURRENT_TIMESTAMP()                                                       AS checked_at
FROM `stock-trading-498512.state.cadence_expected_history`
WHERE run_date < CURRENT_DATE('America/Denver')
GROUP BY run_date
HAVING COUNTIF(expected AND in_service) > 0
   AND SUM(IF(expected AND in_service, rows_logged, 0)) = 0
ORDER BY run_date DESC;

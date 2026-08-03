-- NEVER-COMPLETED dead-man's-switch blind spot (2026-07-27 interactive-session audit, triggered by
-- alerts 56aeef9c-8ce9-4eeb-a2af-63b900d5343e (SL1) / 7d585732-75bf-43e6-bfbb-84143a5cd4ba (SL4)).
-- Project: stock-trading-498512. Apply after 24_cadence_period_watch.sql, 48_cadence_monitor_unbounded.sql,
-- 90_catchup_inprogress_guard.sql.
--
-- PROBLEM: both state.cadence_watch.needs_attention (daily tier) and state.cadence_period_watch.
-- period_missed (period tier) require `monitored` -- the routine has EVER logged a completed run --
-- before they will alarm. Intent per 12/24's own headers: self-bootstrapping, so a routine that has
-- never adopted run-logging at all can't false-alarm. But this ALSO permanently hides a routine that
-- HAS a live, enabled trigger and genuinely has never once completed -- not just during a bootstrap
-- window, forever, since `monitored` can never become TRUE without a completion the alarm itself would
-- have produced. Verified live 2026-07-27: SL1 (quarterly) and SL4 (monthly) were trigger-created
-- 2026-07-10 (the SISA conversion) AFTER their only in-period cron fire date had already passed (SL1's
-- Jul-2 quarterly slot, SL4's Jul-1 monthly slot), so each silently rolled to its NEXT cycle (SL1->Oct 2,
-- SL4->Aug 1) with zero mechanical alarm anywhere. SL2's queue-driven daily fire noticed this ad hoc
-- (36 consecutive PENDING_DRAFT no-ops prompted it to check ops.run_log directly) and raised the two
-- alerts above -- a real catch, but a one-off LLM judgment call, not a mechanical guarantee, and it does
-- not generalize to a future never-yet-fired routine.
--
-- FIX: drop the `monitored` precondition from `needs_attention` (daily) and `period_missed` (period)
-- only. Each now alarms whenever the current day/period's deadline has passed with zero completions
-- in-window, REGARDLESS of all-time completion history. The `monitored` COLUMN itself is unchanged in
-- both views (still exposed for visibility, still "has ever completed", still consistent with
-- state.trigger_attestation's identical convention) -- only the alarm predicate's precondition is
-- dropped. Strict superset: every routine that already alarmed under the old rule alarms identically
-- (monitored was already TRUE for all of them); the only behavior change is a never-completed routine
-- can now alarm too.
--
-- BLAST RADIUS (checked live 2026-07-27): 0 of the daily-tier routines (D1/D2/D2a/D3/OPS0/OPS1/OPS2/SL3)
-- are affected today -- all have long completion histories; this half of the fix is purely preventive
-- for a future daily routine addition hitting the identical first-cycle gap. 5 of 19 period-tier
-- routines have zero completions ever -- SL1, SL4 (created 2026-07-10) and A1, A2, A3 (created
-- 2026-05-09, next_run_at 2027-01-02 -- the same bug, just older and lower-urgency, never flagged
-- before now). All 5 will newly alarm `period_missed=TRUE` (warning severity only -- period_missed /
-- missed_run / routine_stalled are the sole alarm classes here; every capital-affecting alert category
-- is untouched, and state.system_health.all_green keys only on open CRITICALs). Of those,
-- state.period_catchup_available's catchup_safe_period_routines list (bigquery/90, UNCHANGED by this
-- file) already includes SL1/A1/A2 (research-only, no live-order-crafting) -- OPS2's next run
-- (~21:15 MT) auto-catches-up all three inline, exactly as designed. SL4 and A3 are NOT catchup_safe
-- (capital-adjacent proposal / action-conversion) and stay human-visible-alert-only, unchanged from
-- today's SL4 treatment -- OPS0/OPS2 will never auto-fire them.
--
-- SUPERSEDES the state.cadence_watch VIEW definition in 48_cadence_monitor_unbounded.sql (48's
-- ops.sp_assert_deps PROCEDURE redefinition is UNCHANGED and remains canonical there -- this file does
-- not touch dependency-gate semantics, only the two ALARM views) and the state.cadence_period_watch VIEW
-- definition in 24_cadence_period_watch.sql. Neither source file's parsed literals change: 12's deadline
-- TIME literal, 24's period_grace_days literals, and both files' `routines`/`cadence_expected_today`
-- STRUCT rows are exactly what scripts/check_cadence_consistency.py parses, and this file reproduces
-- them byte-for-byte unchanged (do NOT hand-edit the copies below -- edit ops/cadence.yaml +
-- 12/24 + re-run scripts/gen_routine_lists.py --write, then mirror here). Every object built on top
-- (bigquery/31/90's state.catchup_available, bigquery/90's state.period_catchup_available,
-- bigquery/59/112's state.catchup_refire_readiness) reads `needs_attention`/`period_missed` by name
-- with no logic of its own to change -- the fix propagates through automatically, no edit needed there.

-- ===== state.cadence_watch (supersedes 48_cadence_monitor_unbounded.sql's view; daily tier) =====
-- SUPERSEDED LIVE by bigquery/129_cadence_watch_deadline_autotune.sql — current single source of truth
-- for this VIEW. 129 changes ONLY the deadline literal (TIME '21:00:00' -> TIME '21:45:00'), autotuned by
-- W5 2026-08-03 under the process_reliability self-improvement loop; this file's own fix (dropping the
-- `monitored` precondition from `needs_attention`) is carried forward unchanged in 129. The
-- state.cadence_period_watch view further down THIS file is NOT superseded by 129 and remains canonical
-- here — its TIME '21:00:00' literals are the period-grace deadlines, a DIFFERENT constant that 129 does
-- not touch. Kept here for DR-rebuild apply-in-order reference only. DO NOT re-apply this CREATE VIEW
-- statement live in isolation — doing so silently reverts 129's deadline back to 21:00.
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
  -- FIX (this file): `monitored` precondition REMOVED from the alarm predicate -- see header. Was:
  --   e.schedule IN (...) AND e.monitored AND NOT e.ran_completed_today AND deadline passed
  (e.schedule IN ('daily_trading','daily_all')
   AND NOT e.ran_completed_today
   AND DATETIME(CURRENT_TIMESTAMP(), 'America/Denver') >= DATETIME(e.today, TIME '21:00:00')
  ) AS needs_attention,
  CURRENT_TIMESTAMP() AS checked_at
FROM watch e;

-- ===== state.cadence_period_watch (supersedes 24_cadence_period_watch.sql's view; period tier) =====
CREATE OR REPLACE VIEW `stock-trading-498512.state.cadence_period_watch` AS
WITH t AS (SELECT today FROM `stock-trading-498512.state.trading_day_today`),
periods AS (
  SELECT
    today,
    DATE_SUB(today, INTERVAL (EXTRACT(DAYOFWEEK FROM today) - 1) DAY) AS week_start,
    DATE_TRUNC(today, MONTH)   AS month_start,
    DATE_TRUNC(today, QUARTER) AS quarter_start,
    DATE_TRUNC(today, YEAR)    AS year_start
  FROM t
),
nth AS (
  SELECT
    p.*,
    (SELECT cal_date FROM `stock-trading-498512.state.market_calendar`
       WHERE is_trading_day AND DATE_TRUNC(cal_date, MONTH) = p.month_start
       ORDER BY cal_date LIMIT 1 OFFSET 2) AS month_grace_day,
    (SELECT cal_date FROM `stock-trading-498512.state.market_calendar`
       WHERE is_trading_day AND DATE_TRUNC(cal_date, QUARTER) = p.quarter_start
       ORDER BY cal_date LIMIT 1 OFFSET 2) AS quarter_grace_day,
    (SELECT cal_date FROM `stock-trading-498512.state.market_calendar`
       WHERE is_trading_day AND DATE_TRUNC(cal_date, YEAR) = p.year_start
       ORDER BY cal_date LIMIT 1 OFFSET 4) AS year_grace_day
  FROM periods p
),
routines AS (
  -- BYTE-FOR-BYTE copy of 24_cadence_period_watch.sql's `routines` CTE -- that file's copy, not this
  -- one, is what scripts/check_cadence_consistency.py's check J actually parses. Do NOT hand-edit --
  -- edit ops/cadence.yaml + 24_cadence_period_watch.sql + re-run scripts/gen_routine_lists.py --write,
  -- then mirror here (same discipline bigquery/90 already applies to its own inert duplicate).
  SELECT * FROM UNNEST([
    STRUCT('W1' AS routine, 'weekly_sun' AS monitor_class),
    STRUCT('W2' AS routine, 'weekly_sun' AS monitor_class),
    STRUCT('W3' AS routine, 'weekly_sun' AS monitor_class),
    STRUCT('W4' AS routine, 'weekly_sun' AS monitor_class),
    STRUCT('W5' AS routine, 'weekly_sun' AS monitor_class),
    STRUCT('M1a' AS routine, 'monthly_ftd' AS monitor_class),
    STRUCT('M1b' AS routine, 'monthly_ftd' AS monitor_class),
    STRUCT('M2' AS routine, 'monthly_ftd' AS monitor_class),
    STRUCT('M3' AS routine, 'monthly_ftd' AS monitor_class),
    STRUCT('M4' AS routine, 'monthly_ftd' AS monitor_class),
    STRUCT('M5' AS routine, 'monthly_ftd' AS monitor_class),
    STRUCT('SL4' AS routine, 'monthly_ftd' AS monitor_class),
    STRUCT('Q1' AS routine, 'quarterly_ftd' AS monitor_class),
    STRUCT('Q2' AS routine, 'quarterly_ftd' AS monitor_class),
    STRUCT('Q3' AS routine, 'quarterly_ftd' AS monitor_class),
    STRUCT('Q4' AS routine, 'quarterly_ftd' AS monitor_class),
    STRUCT('SL1' AS routine, 'quarterly_ftd' AS monitor_class),
    STRUCT('A1' AS routine, 'annual_ftd' AS monitor_class),
    STRUCT('A2' AS routine, 'annual_ftd' AS monitor_class),
    STRUCT('A3' AS routine, 'annual_ftd' AS monitor_class)
  ])
),
joined AS (
  SELECT
    r.routine, r.monitor_class, n.today,
    CASE r.monitor_class
      WHEN 'weekly_sun'    THEN n.week_start
      WHEN 'monthly_ftd'   THEN n.month_start
      WHEN 'quarterly_ftd' THEN n.quarter_start
      WHEN 'annual_ftd'    THEN n.year_start
    END AS period_start,
    CASE r.monitor_class
      WHEN 'weekly_sun'    THEN DATETIME(DATE_ADD(n.week_start, INTERVAL 1 DAY), TIME '21:00:00')
      WHEN 'monthly_ftd'   THEN DATETIME(n.month_grace_day, TIME '21:00:00')
      WHEN 'quarterly_ftd' THEN DATETIME(n.quarter_grace_day, TIME '21:00:00')
      WHEN 'annual_ftd'    THEN DATETIME(n.year_grace_day, TIME '21:00:00')
    END AS grace_deadline
  FROM routines r, nth n
)
SELECT
  j.routine, j.monitor_class, j.today, j.period_start, j.grace_deadline,
  EXISTS(SELECT 1 FROM `stock-trading-498512.ops.run_log` rl
         WHERE rl.routine = j.routine AND rl.status = 'completed') AS monitored,
  EXISTS(SELECT 1 FROM `stock-trading-498512.ops.run_log` rl
         WHERE rl.routine = j.routine AND rl.status = 'completed'
           AND rl.run_date >= j.period_start AND rl.run_date <= j.today) AS ran_completed_this_period,
  (
    -- FIX (this file): `monitored` precondition REMOVED -- see header. Was:
    --   EXISTS(...status='completed') AND NOT EXISTS(...this period...) AND deadline passed
    NOT EXISTS(SELECT 1 FROM `stock-trading-498512.ops.run_log` rl
                   WHERE rl.routine = j.routine AND rl.status = 'completed'
                     AND rl.run_date >= j.period_start AND rl.run_date <= j.today)
    AND DATETIME(CURRENT_TIMESTAMP(), 'America/Denver') >= j.grace_deadline
  ) AS period_missed,
  CURRENT_TIMESTAMP() AS checked_at
FROM joined j;

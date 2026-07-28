-- Same-period miss alarm for weekly/monthly/quarterly/annual routines (2026-07-03, self-improvement
-- audit WO-1 / B-6-obs). Project: stock-trading-498512. Apply after 09_market_calendar.sql,
-- 10_observability.sql, 12_cadence_monitor.sql, 18_stack_review_fixes.sql (state.trigger_attestation).
--
-- PROBLEM: state.cadence_watch.needs_attention alarms DAILY routines only (12_cadence_monitor.sql) —
-- a missed weekly/monthly/quarterly/annual routine is caught only by state.trigger_attestation's
-- coarse 14/70/200/400-day windows, so a missed single Sunday W-routine can go unflagged ~2 weeks.
-- FIX: per-period tracking with a GRACE DEADLINE placed strictly AFTER the documented tolerance
-- (weeklies run "Sunday OR Monday" per cadence.yaml commentary) so a routine that ran on its normal
-- day never alarms, but a genuine miss is caught within roughly one extra day, not weeks. WARNING
-- severity (not RAISE) — a missed weekly is not a same-night trading halt. Grace-hour constant (21:00
-- MT) matches the existing daily deadline guard (state.cadence_watch) for consistency; grace-DAY
-- offsets (weekly:+1, monthly/quarterly:+2 additional trading days beyond FTD, annual:+4) are declared
-- in ops/cadence.yaml `period_grace_days` and mirrored here — scripts/check_cadence_consistency.py
-- (CI) asserts they agree, the same discipline as the existing deadline-literal check.

-- SUPERSEDED LIVE by bigquery/113_never_completed_watch_fix.sql (2026-07-27 interactive-session audit,
-- alerts 56aeef9c/7d585732) — current single source of truth for this VIEW. 113 drops the `monitored`
-- (has-ever-completed) precondition from `period_missed` so a routine that has NEVER completed can still
-- alarm once its current period's grace deadline passes — the gate below hid SL1/SL4 (SISA, trigger-
-- created 2026-07-10 after their only in-period cron slot had already passed) from every dead-man's
-- switch permanently, not just during bootstrap. This file's `routines` CTE + period_grace_days literals
-- (what scripts/check_cadence_consistency.py actually parses) are UNCHANGED and remain canonical here —
-- 113 carries a byte-for-byte copy for its own self-contained CTE chain only. Kept here, unmodified, for
-- DR-rebuild apply-in-order reference only. DO NOT re-apply this CREATE statement live in isolation.
CREATE OR REPLACE VIEW `stock-trading-498512.state.cadence_period_watch` AS
WITH t AS (SELECT today FROM `stock-trading-498512.state.trading_day_today`),
periods AS (
  SELECT
    today,
    -- Sunday that starts the week containing today (BigQuery DAYOFWEEK: 1=Sunday..7=Saturday,
    -- so DOW-1 is exactly the day-offset back to that week's Sunday). Verified against live dates.
    DATE_SUB(today, INTERVAL (EXTRACT(DAYOFWEEK FROM today) - 1) DAY) AS week_start,
    DATE_TRUNC(today, MONTH)   AS month_start,
    DATE_TRUNC(today, QUARTER) AS quarter_start,
    DATE_TRUNC(today, YEAR)    AS year_start
  FROM t
),
-- Nth trading day within the current period, per class (0-indexed OFFSET: 2 = 3rd trading day).
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
  -- Routine notes relocated here (ABOVE the generated region) by the ARCH-3 Item 30b normalization
  -- (2026-07-16, scripts/gen_routine_lists.py --write) -- the generator does not preserve inline
  -- comments between rows:
  --   SL4 (rev 2026-07-10 — SISA arsenal autonomy conversion).
  --   SL1 (rev 2026-07-10 — SISA); SL3 daily + SL2/SL5 queue-driven are not period-tracked here.
  --
  -- GENERATED (scripts/gen_routine_lists.py --write, ARCH-3 Item 30b, 2026-07-16) from
  -- ops/cadence.yaml: one row per routine whose monitor_class is a period class (weekly_sun /
  -- monthly_ftd / quarterly_ftd / annual_ftd), cadence.yaml file order, every row fully labelled
  -- (scripts/check_cadence_consistency.py's check J requires the labelled form). Do NOT hand-edit the
  -- marked region below -- edit ops/cadence.yaml and re-run `python scripts/gen_routine_lists.py
  -- --write`. CI step `gen_routine_lists.py --check` verifies this region is byte-current.
  SELECT * FROM UNNEST([
-- BEGIN GENERATED ROUTINE LIST (scripts/gen_routine_lists.py --write; do not hand-edit)
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
  -- END GENERATED ROUTINE LIST
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
      -- weekly tolerance is documented as "Sunday OR Monday" -> grace = Monday 21:00 MT.
      WHEN 'weekly_sun'    THEN DATETIME(DATE_ADD(n.week_start, INTERVAL 1 DAY), TIME '21:00:00')
      WHEN 'monthly_ftd'   THEN DATETIME(n.month_grace_day, TIME '21:00:00')
      WHEN 'quarterly_ftd' THEN DATETIME(n.quarter_grace_day, TIME '21:00:00')
      WHEN 'annual_ftd'    THEN DATETIME(n.year_grace_day, TIME '21:00:00')
    END AS grace_deadline
  FROM routines r, nth n
)
SELECT
  j.routine, j.monitor_class, j.today, j.period_start, j.grace_deadline,
  -- monitored = has EVER logged >=1 completed run (same definition as state.trigger_attestation,
  -- for consistency) -- a routine that has never adopted logging cannot false-alarm here.
  EXISTS(SELECT 1 FROM `stock-trading-498512.ops.run_log` rl
         WHERE rl.routine = j.routine AND rl.status = 'completed') AS monitored,
  EXISTS(SELECT 1 FROM `stock-trading-498512.ops.run_log` rl
         WHERE rl.routine = j.routine AND rl.status = 'completed'
           AND rl.run_date >= j.period_start AND rl.run_date <= j.today) AS ran_completed_this_period,
  (
    EXISTS(SELECT 1 FROM `stock-trading-498512.ops.run_log` rl
           WHERE rl.routine = j.routine AND rl.status = 'completed')
    AND NOT EXISTS(SELECT 1 FROM `stock-trading-498512.ops.run_log` rl
                   WHERE rl.routine = j.routine AND rl.status = 'completed'
                     AND rl.run_date >= j.period_start AND rl.run_date <= j.today)
    AND DATETIME(CURRENT_TIMESTAMP(), 'America/Denver') >= j.grace_deadline
  ) AS period_missed,
  CURRENT_TIMESTAMP() AS checked_at
FROM joined j;

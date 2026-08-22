-- Parallel-run dbt port of bigquery/113_never_completed_watch_fix.sql:state.cadence_period_watch — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
WITH t AS (SELECT today FROM {{ ref('trading_day_today') }}),
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
    (SELECT cal_date FROM {{ ref('market_calendar') }}
       WHERE is_trading_day AND DATE_TRUNC(cal_date, MONTH) = p.month_start
       ORDER BY cal_date LIMIT 1 OFFSET 2) AS month_grace_day,
    (SELECT cal_date FROM {{ ref('market_calendar') }}
       WHERE is_trading_day AND DATE_TRUNC(cal_date, QUARTER) = p.quarter_start
       ORDER BY cal_date LIMIT 1 OFFSET 2) AS quarter_grace_day,
    (SELECT cal_date FROM {{ ref('market_calendar') }}
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
  EXISTS(SELECT 1 FROM {{ source('ops', 'run_log') }} rl
         WHERE rl.routine = j.routine AND rl.status = 'completed') AS monitored,
  EXISTS(SELECT 1 FROM {{ source('ops', 'run_log') }} rl
         WHERE rl.routine = j.routine AND rl.status = 'completed'
           AND rl.run_date >= j.period_start AND rl.run_date <= j.today) AS ran_completed_this_period,
  (
    -- FIX (this file): `monitored` precondition REMOVED -- see header. Was:
    --   EXISTS(...status='completed') AND NOT EXISTS(...this period...) AND deadline passed
    NOT EXISTS(SELECT 1 FROM {{ source('ops', 'run_log') }} rl
                   WHERE rl.routine = j.routine AND rl.status = 'completed'
                     AND rl.run_date >= j.period_start AND rl.run_date <= j.today)
    AND DATETIME(CURRENT_TIMESTAMP(), 'America/Denver') >= j.grace_deadline
  ) AS period_missed,
  CURRENT_TIMESTAMP() AS checked_at
FROM joined j

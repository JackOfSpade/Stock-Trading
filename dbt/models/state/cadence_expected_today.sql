-- Parallel-run dbt port of bigquery/12_cadence_monitor.sql:state.cadence_expected_today — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
WITH t AS (
  SELECT
    td.today,
    td.is_trading_day,
    EXTRACT(DAYOFWEEK FROM td.today) AS dow,   -- 1 = Sunday
    td.today = (SELECT MIN(cal_date) FROM {{ ref('market_calendar') }}
                WHERE is_trading_day AND DATE_TRUNC(cal_date, MONTH)   = DATE_TRUNC(td.today, MONTH))   AS is_ftd_month,
    td.today = (SELECT MIN(cal_date) FROM {{ ref('market_calendar') }}
                WHERE is_trading_day AND DATE_TRUNC(cal_date, QUARTER) = DATE_TRUNC(td.today, QUARTER)) AS is_ftd_quarter,
    td.today = (SELECT MIN(cal_date) FROM {{ ref('market_calendar') }}
                WHERE is_trading_day AND DATE_TRUNC(cal_date, YEAR)    = DATE_TRUNC(td.today, YEAR))    AS is_ftd_year
  FROM {{ ref('trading_day_today') }} td
),
routines AS (
  -- GENERATED (scripts/gen_routine_lists.py --write, ARCH-3 Item 30b, 2026-07-16) from
  -- ops/cadence.yaml: one row per calendar-class routine (monitor_class != queue_driven), in
  -- cadence.yaml file order. Do NOT hand-edit the marked region below -- edit ops/cadence.yaml and
  -- re-run `python scripts/gen_routine_lists.py --write`. scripts/check_cadence_consistency.py's
  -- check A verifies this region agrees with ops/cadence.yaml's (id -> monitor_class) map; the CI
  -- step `python scripts/gen_routine_lists.py --check` verifies it is byte-current.
  --
  -- Routine notes relocated here (ABOVE the generated region) by that same normalization commit --
  -- the generator does not preserve inline comments between rows:
  --   D2a (added 2026-07-03, self-improvement audit WO-3): NOT YET ACTIVE, no live web-UI trigger yet
  --   (see the Claude_Task_Plan.md "## D2a." banner). Safe to list here pre-cutover -- self-bootstrapping
  --   means it can never alarm until it logs a first completed run.
  --   OPS0 (added 2026-07-15, self-improvement audit — CONFIRMED GAP catchup-notify-no-auto-refire).
  --   Self-bootstrapping, same as every routine here: cannot alarm until it logs a first completed
  --   run, so safe to register before its live trigger exists.
  --   SISA strategy-lifecycle routines (rev 2026-07-10 — Strategy Arsenal autonomy conversion, owner
  --   directive). Only the calendar-scheduled SL routines register here (self-bootstrapping, so none can
  --   alarm until it logs a first completed run); the queue-driven SL2/SL5 are intentionally NOT listed
  --   (same rule as AR_att/AR_orc — their firing day is not calendar-derivable).
  SELECT * FROM UNNEST([
-- BEGIN GENERATED ROUTINE LIST (scripts/gen_routine_lists.py --write; do not hand-edit)
    STRUCT('D1' AS routine, 'daily_sun_thu' AS schedule),
    STRUCT('D2a' AS routine, 'daily_sun_thu' AS schedule),
    STRUCT('D2' AS routine, 'daily_sun_thu' AS schedule),
    STRUCT('D3' AS routine, 'daily_sun_thu' AS schedule),
    STRUCT('OPS0' AS routine, 'daily_sun_thu' AS schedule),
    STRUCT('OPS1' AS routine, 'daily_sun_thu' AS schedule),
    STRUCT('OPS2' AS routine, 'daily_sun_thu' AS schedule),
    STRUCT('SL3' AS routine, 'daily_sun_thu' AS schedule),
    STRUCT('W1' AS routine, 'weekly_sun' AS schedule),
    STRUCT('W2' AS routine, 'weekly_sun' AS schedule),
    STRUCT('W3' AS routine, 'weekly_sun' AS schedule),
    STRUCT('W4' AS routine, 'weekly_sun' AS schedule),
    STRUCT('W5' AS routine, 'weekly_sun' AS schedule),
    STRUCT('M1a' AS routine, 'monthly_ftd' AS schedule),
    STRUCT('M1b' AS routine, 'monthly_ftd' AS schedule),
    STRUCT('M2' AS routine, 'monthly_ftd' AS schedule),
    STRUCT('M3' AS routine, 'monthly_ftd' AS schedule),
    STRUCT('M4' AS routine, 'monthly_ftd' AS schedule),
    STRUCT('M5' AS routine, 'monthly_ftd' AS schedule),
    STRUCT('SL4' AS routine, 'monthly_ftd' AS schedule),
    STRUCT('Q1' AS routine, 'quarterly_ftd' AS schedule),
    STRUCT('Q2' AS routine, 'quarterly_ftd' AS schedule),
    STRUCT('Q3' AS routine, 'quarterly_ftd' AS schedule),
    STRUCT('Q4' AS routine, 'quarterly_ftd' AS schedule),
    STRUCT('SL1' AS routine, 'quarterly_ftd' AS schedule),
    STRUCT('A1' AS routine, 'annual_ftd' AS schedule),
    STRUCT('A2' AS routine, 'annual_ftd' AS schedule),
    STRUCT('A3' AS routine, 'annual_ftd' AS schedule)
  -- END GENERATED ROUTINE LIST
  ])
)
SELECT r.routine, r.schedule, t.today
FROM routines r, t
WHERE CASE r.schedule
        WHEN 'daily_trading' THEN t.is_trading_day
        WHEN 'daily_all'     THEN TRUE
        -- daily_sun_thu (added 2026-08-08, daily-tier Fri/Sat consolidation): t.dow is
        -- EXTRACT(DAYOFWEEK FROM td.today) above, BigQuery convention 1=Sunday..7=Saturday, so
        -- 6=Friday and 7=Saturday -- deliberately NOT gated on t.is_trading_day (unlike
        -- daily_trading above), since these routines fire and self-heal on non-trading days too
        -- (ops/cadence.yaml's DAILY-TIER FRI/SAT CONSOLIDATION note).
        WHEN 'daily_sun_thu' THEN t.dow NOT IN (6, 7)
        WHEN 'weekly_sun'    THEN t.dow = 1
        WHEN 'monthly_ftd'   THEN t.is_ftd_month
        WHEN 'quarterly_ftd' THEN t.is_ftd_quarter
        WHEN 'annual_ftd'    THEN t.is_ftd_year
        ELSE FALSE
      END

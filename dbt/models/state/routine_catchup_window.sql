-- Parallel-run dbt port of bigquery/105_routine_catchup_window.sql:state.routine_catchup_window — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH routines AS (
  -- GENERATED (scripts/gen_routine_lists.py --write, from ops/cadence.yaml, file order), ALL 32 ids
  -- incl. the 4 queue_driven ones. Do NOT hand-edit -- see header note above.
  SELECT * FROM UNNEST([
    -- BEGIN GENERATED ROUTINE LIST (scripts/gen_routine_lists.py --write; do not hand-edit)
    STRUCT('D1' AS routine, 'daily_sun_thu' AS monitor_class),
    STRUCT('D2a' AS routine, 'daily_sun_thu' AS monitor_class),
    STRUCT('D2' AS routine, 'daily_sun_thu' AS monitor_class),
    STRUCT('D3' AS routine, 'daily_sun_thu' AS monitor_class),
    STRUCT('OPS0' AS routine, 'daily_sun_thu' AS monitor_class),
    STRUCT('OPS1' AS routine, 'daily_sun_thu' AS monitor_class),
    STRUCT('OPS2' AS routine, 'daily_sun_thu' AS monitor_class),
    STRUCT('SL3' AS routine, 'daily_sun_thu' AS monitor_class),
    STRUCT('AR_att' AS routine, 'queue_driven' AS monitor_class),
    STRUCT('AR_orc' AS routine, 'queue_driven' AS monitor_class),
    STRUCT('SL2' AS routine, 'queue_driven' AS monitor_class),
    STRUCT('SL5' AS routine, 'queue_driven' AS monitor_class),
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
last_completed AS (
  -- Latest 'completed' log_ts per routine, id-separator-normalized (RUNBOOK §28 convention) so legacy
  -- AR·att/AR·orc middle-dot rows fold onto the current AR_att/AR_orc keys instead of being invisible.
  SELECT
    REGEXP_REPLACE(routine, r'[·._-]', '') AS routine_norm,
    MAX(log_ts) AS last_completed_ts
  FROM {{ source('ops', 'run_log') }}
  WHERE status = 'completed'
  GROUP BY routine_norm
),
joined AS (
  SELECT
    r.routine,
    r.monitor_class,
    lc.last_completed_ts,
    lc.last_completed_ts IS NULL AS never_completed,
    -- Cadence-default fallback, in whole days -- used only when never_completed. queue_driven's fallback
    -- (1 day) is a design choice, not a named class in the brief -- see header note.
    CASE r.monitor_class
      WHEN 'daily_trading' THEN 1
      WHEN 'daily_all'     THEN 1
      -- daily_sun_thu ADDED 2026-08-08 (daily-tier Fri/Sat consolidation, ops/cadence.yaml): D1/D2a/D2/
      -- D3/OPS0/OPS1/OPS2/SL3 moved off daily_trading/daily_all onto this class. The maximum SCHEDULED
      -- gap between two consecutive fire days is Thursday -> Sunday = 3 calendar days (Fri/Sat skipped
      -- by design), vs. 1 for a true every-day class -- a never-completed routine's fallback window
      -- must span that gap or a first-ever-run catch-up read would start mid-gap and silently miss the
      -- Friday/Saturday evidence that never fires under the new schedule anyway, but also miss Thursday's.
      WHEN 'daily_sun_thu' THEN 3
      WHEN 'weekly_sun'    THEN 7
      WHEN 'monthly_ftd'   THEN 31
      WHEN 'quarterly_ftd' THEN 92
      WHEN 'annual_ftd'    THEN 366
      WHEN 'queue_driven'  THEN 1
      ELSE 31   -- defensive: an unrecognized class should never occur (routines CTE is closed/generated)
    END AS fallback_days
  FROM routines r
  LEFT JOIN last_completed lc
    ON lc.routine_norm = REGEXP_REPLACE(r.routine, r'[·._-]', '')
)
SELECT
  routine,
  monitor_class,
  last_completed_ts,
  never_completed,
  fallback_days,
  -- The raw cadence-default fallback instant (always computed, for transparency/debugging), independent
  -- of whether it actually gets used below.
  TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL fallback_days DAY) AS cadence_fallback_window_start_ts,
  -- The window every routine actually reads: its own last completion, or the cadence fallback if it has
  -- never completed.
  COALESCE(
    last_completed_ts,
    TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL fallback_days DAY)
  ) AS window_start_ts,
  -- Elapsed size of that window in (fractional) days, for quick human/dashboard reading.
  ROUND(
    TIMESTAMP_DIFF(
      CURRENT_TIMESTAMP(),
      COALESCE(last_completed_ts, TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL fallback_days DAY)),
      MINUTE
    ) / 1440.0, 2
  ) AS window_days,
  CURRENT_TIMESTAMP() AS checked_at
FROM joined
ORDER BY routine

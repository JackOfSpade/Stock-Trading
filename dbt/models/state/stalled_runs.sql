-- Parallel-run dbt port of bigquery/148_audit_2026_08_08_fixes.sql:state.stalled_runs — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH cls AS (
  -- fast tier (~6h): daily, adversarial, and action-conversion routines (same-day work).
  -- slow tier (~18h): deep-research weeklies/monthlies/quarterlies/annuals (longer legitimate runtime).
  -- AR ids are ASCII AR_att/AR_orc (2026-07-01, RUNBOOK §28), matching ops/cadence.yaml + the plan table.
  -- (This threshold table joins ops.run_log by EXACT id — USING(routine) — so future AR runs must self-log
  -- the ASCII id to be classified here; legacy middle-dot 'started' rows age out of the 7-day window.)
  -- D2a (added 2026-07-03, self-improvement audit WO-3): NOT YET ACTIVE, no live web-UI trigger yet;
  -- listed here so once it starts logging it is already correctly classified fast-tier.
  SELECT * FROM UNNEST([
    STRUCT('D1' AS routine, 6 AS min_stale_hours), STRUCT('D2a', 6), STRUCT('D2', 6), STRUCT('D3', 6),
    -- OPS0/OPS1/OPS2 added (2026-08-08 audit of the 2026-08-08 canonical bodies): all three are in
    -- ops/cadence.yaml and log 'started' rows via ops.sp_routine_start, but this table was last edited
    -- 2026-07-10, before OPS0/OPS1/OPS2 existed (created 2026-07-15/07-19/07-27) — so a hung OPS0/OPS1/
    -- OPS2 never raised routine_stalled no matter how long it hung.
    STRUCT('OPS0', 6), STRUCT('OPS1', 6), STRUCT('OPS2', 6),
    STRUCT('AR_att', 6), STRUCT('AR_orc', 6),
    STRUCT('W4', 6), STRUCT('M4', 6), STRUCT('Q4', 6), STRUCT('A3', 6),
    -- SISA fast tier (rev 2026-07-10): SL3 daily monitor, SL4 monthly scanner, SL5 registrar — all
    -- same-day work (no multi-hour deep research), so a >6h 'started' with no terminal row is stalled.
    STRUCT('SL3', 6), STRUCT('SL4', 6), STRUCT('SL5', 6),
    STRUCT('W1', 18), STRUCT('W2', 18), STRUCT('W3', 18), STRUCT('W5', 18),
    STRUCT('M1a', 18), STRUCT('M1b', 18), STRUCT('M2', 18), STRUCT('M3', 18), STRUCT('M5', 18),
    STRUCT('Q1', 18), STRUCT('Q2', 18), STRUCT('Q3', 18),
    STRUCT('A1', 18), STRUCT('A2', 18),
    -- SISA slow tier (rev 2026-07-10): SL1 quarterly deep-research synthesis + SL2 authoring/revision
    -- are legitimately long-running (like the deep-research weeklies/monthlies), so 18h before stalled.
    STRUCT('SL1', 18), STRUCT('SL2', 18)
  ])
),
started AS (
  SELECT routine, run_date, MAX(log_ts) AS last_started_ts
  FROM {{ source('ops', 'run_log') }}
  WHERE status = 'started'
    AND run_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY)
  GROUP BY routine, run_date
),
terminal AS (
  SELECT DISTINCT routine, run_date
  FROM {{ source('ops', 'run_log') }}
  WHERE status IN ('completed', 'failed', 'halted')
    AND run_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY)
)
SELECT
  s.routine, s.run_date, s.last_started_ts,
  TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), s.last_started_ts, HOUR) AS hours_since_started,
  c.min_stale_hours,
  CURRENT_TIMESTAMP() AS checked_at
FROM started s
JOIN cls c USING (routine)   -- classify (and bound to) known routines; an unknown id is not flagged
LEFT JOIN terminal t USING (routine, run_date)
WHERE t.routine IS NULL
  AND TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), s.last_started_ts, HOUR) >= c.min_stale_hours

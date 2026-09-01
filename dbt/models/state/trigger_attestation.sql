-- Parallel-run dbt port of bigquery/18_stack_review_fixes.sql:state.trigger_attestation — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH cls AS (
  -- max_gap_days ≈ ~2 cadence periods (annual ≈ 1 year + slack). Coarse thresholds, NOT exact
  -- schedules, so they do not need to track ops/cadence.yaml precisely. Daily routines are omitted
  -- (already alarmed by state.cadence_watch); AR_att/AR_orc are queue-driven (no calendar prediction).
  SELECT * FROM UNNEST([
    STRUCT('W1'  AS routine,  14 AS max_gap_days), STRUCT('W2', 14), STRUCT('W3', 14),
    STRUCT('W4', 14),                              STRUCT('W5', 14),
    STRUCT('M1a', 70), STRUCT('M1b', 70), STRUCT('M2', 70), STRUCT('M3', 70),
    STRUCT('M4', 70),  STRUCT('M5', 70),
    STRUCT('SL4', 70),   -- SL4 monthly discretionary-retirement scanner (rev 2026-07-10 — SISA)
    STRUCT('Q1', 200), STRUCT('Q2', 200), STRUCT('Q3', 200), STRUCT('Q4', 200),
    STRUCT('SL1', 200),   -- SL1 quarterly candidate synthesis/qualification (rev 2026-07-10 — SISA). SL3 is
                          -- daily (already alarmed by cadence_watch) and SL2/SL5 are queue-driven (no
                          -- calendar prediction), so — like the daily/AR routines — they are omitted here.
    STRUCT('A1', 400), STRUCT('A2', 400), STRUCT('A3', 400)
  ])
),
lastrun AS (
  SELECT routine, MAX(run_date) AS last_completed
  FROM {{ source('ops', 'run_log') }}
  WHERE status = 'completed'
  GROUP BY routine
),
td AS (SELECT today FROM {{ ref('trading_day_today') }})
SELECT
  c.routine,
  c.max_gap_days,
  l.last_completed,
  td.today,
  DATE_DIFF(td.today, l.last_completed, DAY) AS days_since_completed,
  (l.last_completed IS NOT NULL) AS monitored,
  COALESCE(l.last_completed IS NOT NULL
           AND DATE_DIFF(td.today, l.last_completed, DAY) > c.max_gap_days, FALSE) AS overdue,
  CURRENT_TIMESTAMP() AS checked_at
FROM cls c
CROSS JOIN td
LEFT JOIN lastrun l ON l.routine = c.routine

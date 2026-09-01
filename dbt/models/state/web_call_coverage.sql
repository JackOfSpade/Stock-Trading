-- Parallel-run dbt port of bigquery/200_web_call_coverage_obligation_floor.sql:state.web_call_coverage — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH runs AS (
  SELECT routine, run_date
  FROM {{ source('ops', 'run_log') }}
  WHERE status = 'completed'
    AND run_date >= GREATEST(DATE_SUB(CURRENT_DATE("America/Denver"), INTERVAL 45 DAY), DATE '2026-08-17')
  GROUP BY routine, run_date
),
logged AS (
  SELECT routine, run_date, COUNT(*) AS logged_row_count
  FROM {{ source('ops', 'web_calls') }}
  WHERE run_date >= GREATEST(DATE_SUB(CURRENT_DATE("America/Denver"), INTERVAL 45 DAY), DATE '2026-08-17')
  GROUP BY routine, run_date
)
SELECT
  r.routine,
  r.run_date,
  COALESCE(l.logged_row_count, 0) AS logged_row_count,
  r.routine IN ('D1','D2a','W1','W2','W3','W5','M1a','M2','M3','Q2','Q3','SL1','OPS1','OPS2')
    AS expected_metered,
  -- PROVEN gap: a completed run of a routine the prose obliges to log, with zero rows logged for
  -- that (routine, run_date). This is the only column OPS0's STEP 5 raise reads.
  (r.routine IN ('D1','D2a','W1','W2','W3','W5','M1a','M2','M3','Q2','Q3','SL1','OPS1','OPS2')
     AND l.routine IS NULL) AS missing_telemetry,
  CURRENT_TIMESTAMP() AS checked_at
FROM runs r
LEFT JOIN logged l
  ON l.routine = r.routine AND l.run_date = r.run_date

-- Parallel-run dbt port of bigquery/132_queue_driven_silence_watch.sql:state.queue_driven_silence_watch — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH routines AS (
  SELECT * FROM UNNEST([
-- BEGIN GENERATED ROUTINE LIST (scripts/gen_routine_lists.py --write; do not hand-edit)
    STRUCT('AR_att' AS routine, 'queue_driven' AS monitor_class),
    STRUCT('AR_orc' AS routine, 'queue_driven' AS monitor_class),
    STRUCT('SL2' AS routine, 'queue_driven' AS monitor_class),
    STRUCT('SL5' AS routine, 'queue_driven' AS monitor_class)
  -- END GENERATED ROUTINE LIST
  ])
),
last_completed AS (
  SELECT routine, MAX(run_date) AS last_run_date
  FROM {{ source('ops', 'run_log') }}
  WHERE status = 'completed'
  GROUP BY routine
)
SELECT
  r.routine,
  r.monitor_class,
  CURRENT_DATE('America/Denver') AS today,
  l.last_run_date,
  DATE_DIFF(CURRENT_DATE('America/Denver'), l.last_run_date, DAY) AS days_silent,
  9 AS silence_threshold_days,
  -- COALESCE -> TRUE so a routine with NO completed run ever is reported silent rather than NULL.
  -- Same fail-LOUD posture as state.freshness: a missing source must alarm, never read as green.
  COALESCE(DATE_DIFF(CURRENT_DATE('America/Denver'), l.last_run_date, DAY) >= 9, TRUE) AS is_silent,
  (l.last_run_date IS NULL) AS never_completed,
  CURRENT_TIMESTAMP() AS checked_at
FROM routines r
LEFT JOIN last_completed l ON l.routine = r.routine
ORDER BY r.routine

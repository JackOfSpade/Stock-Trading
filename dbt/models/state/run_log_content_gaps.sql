-- Parallel-run dbt port of bigquery/147_run_log_content_quality.sql:state.run_log_content_gaps — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
SELECT
  routine,
  run_date,
  status,
  log_ts,
  run_id,
  CURRENT_TIMESTAMP() AS checked_at
FROM {{ source('ops', 'run_log') }}
WHERE run_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 3 DAY)
  AND status IN ('completed', 'failed', 'halted')
  AND (note IS NULL OR TRIM(note) = '')

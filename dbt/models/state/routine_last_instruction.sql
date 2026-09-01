-- Parallel-run dbt port of bigquery/10_observability.sql:state.routine_last_instruction — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
SELECT routine, instruction, run_date, log_ts
FROM {{ source('ops', 'run_log') }}
WHERE instruction IS NOT NULL
  AND instruction LIKE 'Read Claude_Task_Plan.md. Perform %'
QUALIFY ROW_NUMBER() OVER (PARTITION BY routine ORDER BY log_ts DESC) = 1

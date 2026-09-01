-- Parallel-run dbt port of bigquery/144_decision_log_correction_consumers.sql:analytics.weekly_nogos — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
SELECT ticker, strategy, entry_date
FROM {{ source('state_external', 'decision_log_current') }}
WHERE entry_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY)
  AND UPPER(decision) = 'NO-GO' AND ticker IS NOT NULL
ORDER BY entry_date DESC LIMIT 8

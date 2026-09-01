-- Parallel-run dbt port of bigquery/11_theater_judge.sql:analytics.theater_check_calibration — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
SELECT
  COUNT(*) AS scored_reviews,
  COUNTIF(judge_independent) AS judged_independent,
  COUNTIF(NOT judge_independent) AS judged_theater,
  ROUND(SAFE_DIVIDE(COUNTIF(agrees_with_self_cert), COUNT(*)), 3) AS self_cert_agreement_rate
FROM {{ source('analytics_external', 'theater_judge') }}

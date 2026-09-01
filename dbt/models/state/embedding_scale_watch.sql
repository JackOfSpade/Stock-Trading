-- Parallel-run dbt port of bigquery/18_stack_review_fixes.sql:state.embedding_scale_watch — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH n AS (SELECT COUNT(*) AS decision_log_rows FROM {{ source('events', 'decision_log') }}),
e AS (SELECT COUNT(*) AS embedding_rows FROM {{ source('analytics_external', 'decision_embeddings') }})
SELECT
  n.decision_log_rows,
  e.embedding_rows,
  5000 AS vector_index_threshold,
  GREATEST(0, 5000 - e.embedding_rows) AS rows_to_index_threshold,
  e.embedding_rows >= 4000 AS approaching_index_threshold,
  CURRENT_TIMESTAMP() AS checked_at
FROM n, e

-- Parallel-run dbt port of bigquery/143_adversarial_review_correction_path.sql:state.adversarial_reviews_current — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
SELECT *
FROM {{ source('events', 'adversarial_reviews') }}
WHERE event_id NOT IN (
  SELECT superseded_by
  FROM {{ source('events', 'adversarial_reviews') }}
  WHERE superseded_by IS NOT NULL
)

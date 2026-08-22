-- Parallel-run dbt port of bigquery/141_append_only_halt_scope.sql:state.append_only_integrity_haltable — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
SELECT * FROM {{ ref('append_only_integrity') }}
WHERE NOT (statement_type = 'UPDATE' AND target_table = 'adversarial_reviews')

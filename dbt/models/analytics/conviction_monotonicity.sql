-- Parallel-run dbt port of bigquery/26_process_metrics.sql:analytics.conviction_monotonicity — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
SELECT
  strategy, conviction, conviction_ordinal,
  COUNT(*) AS n_closed,
  ROUND(AVG(realized_pnl), 3) AS avg_realized_pnl,
  COUNTIF(was_profitable) AS n_wins,
  (COUNT(*) >= 5) AS min_n_met   -- directional even below this; a per-tier floor for "worth reading at all"
FROM {{ ref('conviction_features') }}
WHERE position_closed AND conviction_ordinal IS NOT NULL
GROUP BY strategy, conviction, conviction_ordinal
ORDER BY strategy, conviction_ordinal

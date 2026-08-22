-- Parallel-run dbt port of bigquery/37_self_improvement_autonomy.sql:state.execution_quality_readiness — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
WITH agg AS (
  SELECT COUNT(*) AS n, COUNTIF(adverse_slippage_bps > 0) AS n_adv, COUNTIF(adverse_slippage_bps < 0) AS n_fav
  FROM {{ ref('execution_quality') }}
  WHERE adverse_slippage_bps IS NOT NULL
)
SELECT
  agg.n AS n_nonsgov_fills_measured,
  agg.n_adv AS n_adverse,
  agg.n_fav AS n_favorable,
  (agg.n >= 8 AND (agg.n_adv = agg.n OR agg.n_fav = agg.n)) AS consistent_sign_signal,
  (agg.n >= 8 AND (agg.n_adv = agg.n OR agg.n_fav = agg.n)) AS ready_for_change
FROM agg

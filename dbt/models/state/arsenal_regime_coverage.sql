-- Parallel-run dbt port of bigquery/35_strategy_arsenal.sql:state.arsenal_regime_coverage — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
WITH cells AS (
  SELECT spy_trend, vix_regime, CONCAT(spy_trend, '/', vix_regime) AS regime_cell
  FROM UNNEST(['UP','NEUTRAL','DOWN']) AS spy_trend
  CROSS JOIN UNNEST(['LOW','NORMAL','HIGH']) AS vix_regime
),
demonstrated AS (
  SELECT p.strategy_code, p.regime_cell, LOGICAL_OR(p.excess >= 0) AS positive_excess
  FROM {{ source('analytics_external', 'strategy_incubation_perf') }} p
  WHERE p.phase = 'paper' AND p.regime_cell IS NOT NULL
  GROUP BY p.strategy_code, p.regime_cell
),
cov AS (
  SELECT d.regime_cell,
    COUNTIF(r.is_active AND d.positive_excess) AS covered_active_count,
    COUNTIF(r.is_incubating AND d.positive_excess) AS covered_incubating_count
  FROM demonstrated d
  JOIN {{ source('state_external', 'strategy_roster') }} r ON r.strategy_code = d.strategy_code
  GROUP BY d.regime_cell
)
SELECT
  c.regime_cell, c.spy_trend, c.vix_regime,
  COALESCE(cov.covered_active_count, 0) AS covered_active_count,
  COALESCE(cov.covered_incubating_count, 0) AS covered_incubating_count,
  COALESCE(cov.covered_active_count, 0) = 0 AS is_gap
FROM cells c LEFT JOIN cov ON cov.regime_cell = c.regime_cell

-- Parallel-run dbt port of bigquery/267_paper_regime_coverage_gate.sql:state.arsenal_regime_coverage — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
-- Provenance: first ported 2026-08-22 (dbt view-coverage burn-down), when this view had no dbt
-- presence and no row-level parity protection; re-ported 2026-10-25 from bigquery/267.
WITH cells AS (
  SELECT spy_trend, vix_regime, CONCAT(spy_trend, '/', vix_regime) AS regime_cell
  FROM UNNEST(['UP','NEUTRAL','DOWN']) AS spy_trend
  CROSS JOIN UNNEST(['LOW','NORMAL','HIGH']) AS vix_regime
),
demonstrated AS (
  SELECT p.strategy_code, p.regime_cell, p.demonstrated AS positive_excess
  FROM {{ ref('strategy_paper_regime_cells') }} p
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

-- Parallel-run dbt port of bigquery/26_process_metrics.sql:analytics.forecast_bias — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
--
-- Extended 2026-09-14 in lockstep with bigquery/239_process_scorecard_above_band_coverage.sql (alert
-- 8e8747ed-c8b0-4e87-8d4c-79c23bee765f): adds pct_above_band, mirroring pct_below_band exactly. No
-- new ref()/source() needed — same base table, one new SELECT-list expression.
SELECT
  strategy,
  COUNT(*) AS n_forecast_points,
  COUNTIF(below_band) AS n_below_band,
  COUNTIF(above_band) AS n_above_band,
  COUNTIF(NOT below_band AND NOT above_band) AS n_in_band,
  ROUND(SAFE_DIVIDE(COUNTIF(below_band), COUNT(*)), 3) AS pct_below_band,
  ROUND(SAFE_DIVIDE(COUNTIF(above_band), COUNT(*)), 3) AS pct_above_band,
  (COUNT(*) >= 8) AS min_n_met
FROM {{ ref('twr_forecast_vs_actual_all_vintages') }}
GROUP BY strategy

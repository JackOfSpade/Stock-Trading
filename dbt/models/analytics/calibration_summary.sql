-- Parallel-run dbt port of bigquery/04_analytics.sql:analytics.calibration_summary — canonical source is that file until owner cutover.
-- Cold-start-SAFE calibration: per conviction tier, closed count / win-rate / avg realized P&L.
-- Works at any N (sparse now). This is what the routine reads for conviction-calibration UNTIL
-- the gated BQML conviction model is trustworthy.

SELECT COALESCE(conviction,'(unscored)') AS conviction, ANY_VALUE(conviction_ordinal) AS ord,
  COUNT(*) AS go_theses, COUNTIF(position_closed) AS closed, COUNTIF(was_profitable) AS wins,
  ROUND(SAFE_DIVIDE(COUNTIF(was_profitable), COUNTIF(position_closed)), 3) AS win_rate,
  ROUND(AVG(IF(position_closed, realized_pnl, NULL)), 3) AS avg_realized_pnl
FROM {{ ref('conviction_features') }}
GROUP BY conviction ORDER BY ord

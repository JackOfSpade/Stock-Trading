-- Parallel-run dbt port of bigquery/25_calibration_shrinkage.sql:analytics.calibration_shrunk —
-- canonical source is that file until owner cutover. Self-improvement audit S-2/B-2 (2026-07-03):
-- Beta-Binomial shrinkage (fixed Beta(2,2) prior, NOT the pooled sample rate — see the canonical
-- file's header for why) + Wilson 95% interval + a trustworthy_edge hard gate. Supersedes reading
-- calibration_summary.win_rate alone; deprecates the gated BQML conviction_model entirely.

WITH base AS (
  SELECT COALESCE(conviction, '(unscored)') AS conviction, ANY_VALUE(conviction_ordinal) AS ord,
    COUNT(*) AS go_theses, COUNTIF(position_closed) AS closed, COUNTIF(was_profitable) AS wins
  FROM {{ ref('conviction_features') }}
  GROUP BY conviction
),
prior AS (SELECT 2.0 AS prior_a, 2.0 AS prior_b),
wilson AS (
  SELECT b.*, p.prior_a, p.prior_b,
    SAFE_DIVIDE(b.wins, b.closed) AS p_hat,
    SAFE_DIVIDE(SAFE_DIVIDE(b.wins, b.closed) + (1.96*1.96)/(2*b.closed), 1 + (1.96*1.96)/b.closed) AS wilson_center,
    SAFE_DIVIDE(
      1.96 * SQRT(SAFE_DIVIDE(SAFE_DIVIDE(b.wins, b.closed) * (1 - SAFE_DIVIDE(b.wins, b.closed)), b.closed)
                  + (1.96*1.96)/(4*b.closed*b.closed)),
      1 + (1.96*1.96)/b.closed
    ) AS wilson_margin
  FROM base b, prior p
)
SELECT
  conviction, ord, go_theses, closed, wins,
  ROUND(p_hat, 3) AS win_rate,
  ROUND(SAFE_DIVIDE(wins + prior_a, closed + prior_a + prior_b), 3) AS win_rate_shrunk,
  ROUND(GREATEST(0.0, COALESCE(wilson_center - wilson_margin, 0.0)), 3) AS wilson_low,
  ROUND(LEAST(1.0, COALESCE(wilson_center + wilson_margin, 1.0)), 3) AS wilson_high,
  (closed >= 15 AND COALESCE(wilson_center - wilson_margin, 0.0) > 0.55) AS trustworthy_edge
FROM wilson
ORDER BY ord

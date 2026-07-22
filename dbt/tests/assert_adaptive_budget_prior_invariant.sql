-- Singular test (passes when ZERO rows): analytics.calibration_return_shrunk's two load-bearing
-- invariants for the self-activating φ·α adaptive shortfall budget (bigquery/103_adaptive_shortfall_
-- budget.sql, 2026-07-22):
--   (a) N=0 REPRODUCES THE PRIOR EXACTLY. A strategy with n_closed=0 closed campaigns (4 of 5 as of
--       this file's authoring) must have budget_bps == prior_bps, within a 0.01 bps floating-point
--       tolerance — this is what makes the cutover a NO-OP today: analytics.fn_order_guard's shortfall
--       gate must reject/pass exactly the same orders it did under the old fixed CASE until a strategy
--       actually closes its first campaign.
--   (b) THE CLAMP ALWAYS HOLDS. Every row's budget_bps must be within [0.5x, 2.0x] its own prior_bps —
--       one lucky or unlucky campaign, or a still-thin sample, can never send the adaptive budget
--       outside that range. Floating-point tolerance (1e-6 relative) on the clamp boundary, since
--       budget_bps and prior_bps are computed via different arithmetic paths (GREATEST/LEAST vs. a
--       literal multiply).
--
-- Added 2026-07-22 alongside bigquery/103_adaptive_shortfall_budget.sql / dbt/models/analytics/
-- calibration_return_shrunk.sql. Returns the offending row(s) with both conditions' evaluated values so
-- a failure is immediately diagnosable.

SELECT strategy, n_closed, prior_bps, budget_bps,
  ABS(budget_bps - prior_bps) AS abs_diff_from_prior,
  (n_closed = 0 AND ABS(budget_bps - prior_bps) >= 0.01) AS violates_n0_reproduces_prior,
  (budget_bps < 0.5 * prior_bps - 1e-6 OR budget_bps > 2.0 * prior_bps + 1e-6) AS violates_clamp
FROM {{ ref('calibration_return_shrunk') }}
WHERE (n_closed = 0 AND ABS(budget_bps - prior_bps) >= 0.01)
   OR (budget_bps < 0.5 * prior_bps - 1e-6 OR budget_bps > 2.0 * prior_bps + 1e-6)

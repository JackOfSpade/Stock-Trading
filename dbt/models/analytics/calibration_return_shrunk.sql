-- Parallel-run dbt port of bigquery/103_adaptive_shortfall_budget.sql:analytics.
-- calibration_return_shrunk -- canonical source is that file until owner cutover.
--
-- Per-strategy adaptive shortfall-budget input for analytics.fn_order_guard's self-activating φ·α
-- adaptive budget (owner-directed research pass 2026-07-22): n_closed closed campaigns (analytics.
-- position_campaigns), mean realized RETURN per closed campaign (NOT win-rate -- calibration_shrunk
-- exposes win-rate, the wrong statistic for a dollar-cost budget), the fixed prior_bps (today's
-- D150/A100/B·E50/C25 holding-horizon mapping, PRESERVED as the shrinkage prior), and budget_bps =
-- phi*alpha_shrunk (bps), CLAMPED to [0.5x, 2.0x] the prior. TUNABLE: phi=0.20 (spend at most 1/5 of
-- expected edge on execution cost), k=15 (shrinkage strength in pseudo-campaigns). INVARIANT (see
-- dbt/tests/assert_adaptive_budget_prior_invariant.sql): at n_closed=0, budget_bps == prior_bps
-- EXACTLY -- zero behavior change until a strategy closes its first campaign.

WITH priors AS (
  SELECT strategy, prior_bps FROM UNNEST([
    STRUCT('A' AS strategy, 100.0 AS prior_bps), STRUCT('B' AS strategy, 50.0 AS prior_bps),
    STRUCT('C' AS strategy, 25.0 AS prior_bps), STRUCT('D' AS strategy, 150.0 AS prior_bps),
    STRUCT('E' AS strategy, 50.0 AS prior_bps)
  ])
),
camp AS (
  -- realized RETURN per CLOSED campaign = realized_pnl / cost_basis; cost_basis approx as
  -- entry_price*total_shares_bought (EXACT for single-entry = 100% of history today).
  SELECT strategy, COUNT(*) AS n_closed,
    AVG(SAFE_DIVIDE(CAST(realized_pnl AS FLOAT64),
        NULLIF(CAST(entry_price AS FLOAT64) * CAST(total_shares_bought AS FLOAT64), 0))) AS mean_return
  FROM {{ ref('position_campaigns') }}
  WHERE exit_date IS NOT NULL
  GROUP BY strategy
),
calc AS (
  SELECT p.strategy, p.prior_bps, COALESCE(c.n_closed,0) AS n_closed, c.mean_return,
    (p.prior_bps/10000.0)/0.20 AS prior_alpha,                        -- TUNABLE: phi=0.20
    ((COALESCE(c.n_closed,0)*COALESCE(c.mean_return,0.0)) + (15.0*((p.prior_bps/10000.0)/0.20)))
      / (COALESCE(c.n_closed,0)+15.0) AS alpha_shrunk                 -- TUNABLE: k=15 shrinkage strength
  FROM priors p LEFT JOIN camp c ON c.strategy = p.strategy
)
SELECT strategy, n_closed, mean_return, prior_bps, prior_alpha, alpha_shrunk,
  GREATEST(0.5*prior_bps, LEAST(2.0*prior_bps, 0.20*alpha_shrunk*10000.0)) AS budget_bps  -- TUNABLE clamp: [0.5x, 2.0x] prior
FROM calc

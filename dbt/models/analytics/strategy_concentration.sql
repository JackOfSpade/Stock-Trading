-- Parallel-run dbt port of bigquery/140_strategy_concentration.sql:analytics.strategy_concentration — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH by_name AS (
  SELECT
    strategy,
    ticker,
    SUM(cost_basis) AS name_cost_basis,   -- summed across tranches: a multi-tranche name counts ONCE,
                                          -- the same aggregation the retired per-name envelope used
    MIN(shares)     AS min_shares         -- negative on any leg => a short is present in this strategy
  FROM {{ ref('current_positions') }}
  WHERE strategy IS NOT NULL
  GROUP BY strategy, ticker
),
ranked AS (
  SELECT
    strategy,
    ticker,
    name_cost_basis,
    min_shares,
    ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY name_cost_basis DESC, ticker) AS rn,
    SUM(name_cost_basis) OVER (PARTITION BY strategy) AS deployed_cost_basis,
    COUNT(*)             OVER (PARTITION BY strategy) AS n_names,
    MIN(min_shares)      OVER (PARTITION BY strategy) AS strategy_min_shares
  FROM by_name
)
SELECT
  r.strategy,
  CURRENT_DATE('America/Denver') AS as_of_date,
  r.n_names,
  r.ticker                              AS largest_name,
  ROUND(r.name_cost_basis, 2)           AS largest_name_cost_basis,
  ROUND(n.nav, 2)                       AS strategy_nav,
  -- THE metric: largest single name as a share of the strategy portfolio. No threshold attaches.
  ROUND(100 * SAFE_DIVIDE(r.name_cost_basis, n.nav), 2)      AS largest_name_share_pct,
  ROUND(100 * SAFE_DIVIDE(r.deployed_cost_basis, n.nav), 2)  AS deployed_share_pct,
  -- Herfindahl over names, on deployed capital: 1.0 = a single position IS the book, ~1/n = even.
  ROUND(
    (SELECT SUM(POW(SAFE_DIVIDE(b.name_cost_basis, r.deployed_cost_basis), 2))
     FROM by_name b WHERE b.strategy = r.strategy), 4)       AS name_hhi,
  CASE
    WHEN r.strategy = 'C'            THEN 'APPROXIMATE-OPTIONS: CaR is max_loss, not cost basis'
    WHEN r.strategy_min_shares < 0   THEN 'APPROXIMATE-SHORT-LEG: CaR is notional x stop distance for the short side'
    ELSE 'EXACT-LONG-EQUITY: no stop-loss, so cost basis IS Capital at Risk'
  END                                   AS basis_fidelity
FROM ranked r
JOIN {{ ref('strategy_nav') }} n USING (strategy)
WHERE r.rn = 1

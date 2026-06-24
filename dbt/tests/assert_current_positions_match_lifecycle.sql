-- Singular test (passes when ZERO rows): the two open-position representations must agree on open
-- shares per (strategy, ticker) within tolerance (stack review 2026-06-24, RUNBOOK §25 B4).
--
-- Rationale: state.current_positions (← events.position_events, the path analytics.strategy_nav reads
-- for the 2%-sizing base) and analytics.position_lifecycle (← authoritative state.trade_fills_curated,
-- the path the TWR engine / §13 read) are independent. They can diverge with NO existing monitor
-- watching position_events. SUM on both sides absorbs leg-splits; the 0.01-share tolerance ignores
-- sub-cent dividend-reinvest fractions (the live ~$0.20 drift) while catching a whole position present
-- in one representation but not the other. This is the dbt mirror of state.position_reconciliation.

WITH cp AS (
  SELECT strategy, ticker, SUM(shares) AS s
  FROM {{ ref('current_positions') }}
  WHERE strategy IS NOT NULL AND ticker IS NOT NULL
  GROUP BY strategy, ticker
),
lc AS (
  SELECT strategy, ticker, SUM(shares) AS s
  FROM {{ ref('position_lifecycle') }}
  WHERE exit_date IS NULL AND strategy IS NOT NULL AND ticker IS NOT NULL
  GROUP BY strategy, ticker
)
SELECT strategy, ticker, COALESCE(cp.s, 0) AS current_positions_shares, COALESCE(lc.s, 0) AS lifecycle_open_shares
FROM cp FULL OUTER JOIN lc USING (strategy, ticker)
WHERE ABS(COALESCE(cp.s, 0) - COALESCE(lc.s, 0)) > 0.01

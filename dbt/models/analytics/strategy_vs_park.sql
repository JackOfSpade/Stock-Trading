-- Parallel-run dbt port of bigquery/21_strategy_vs_park.sql:analytics.strategy_vs_park — canonical source is that file until owner cutover.
-- Latest verdict row per ever-deployed strategy. 7d-ago anchor: nearest row to
-- CURRENT_DATE−7 (America/Denver — the operating plane; display tz never leaks into SQL
-- windows), deterministic tie-break toward the NEWER row (same pattern as
-- state.account_nav_7d_ago) — a Monday-holiday week produces real two-row ties, and this
-- view is independently evaluated by dbt-parity against the live view, so a
-- nondeterministic pick would show up as spurious drift.
--
-- NET-OF-COMMISSION VISIBILITY (2026-07-03, self-improvement audit S-4): edge_dollars_cum_net is
-- additive-only (gross stays the kill-gate headline per the owner's documented commission policy,
-- 03_twr_engine.sql) so the commission drag is visible on an ongoing basis.

WITH latest AS (
  SELECT strategy, as_of_date, edge_dollars_cum
  FROM {{ ref('strategy_vs_park_daily') }}
  QUALIFY ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY as_of_date DESC) = 1
),
wk_ago AS (
  SELECT strategy, edge_dollars_cum AS edge_dollars_cum_7d_ago
  FROM {{ ref('strategy_vs_park_daily') }}
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY strategy
    ORDER BY ABS(DATE_DIFF(as_of_date, DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 7 DAY), DAY)),
             as_of_date DESC
  ) = 1
),
firsts AS (
  SELECT strategy, MIN(as_of_date) AS first_deployed_date
  FROM {{ ref('strategy_vs_park_daily') }}
  GROUP BY strategy
),
comm AS (
  SELECT strategy, SUM(commission) AS commissions_to_date
  FROM {{ ref('trade_fills_curated') }}
  WHERE ticker != 'SGOV' AND strategy IS NOT NULL
  GROUP BY strategy
)
SELECT
  l.strategy, l.as_of_date, l.edge_dollars_cum,
  l.edge_dollars_cum - w.edge_dollars_cum_7d_ago AS edge_dollars_wk,
  f.first_deployed_date,
  c.commissions_to_date,
  l.edge_dollars_cum - COALESCE(c.commissions_to_date, 0) AS edge_dollars_cum_net
FROM latest l
JOIN wk_ago w USING (strategy)
JOIN firsts f USING (strategy)
LEFT JOIN comm c USING (strategy)

-- Parallel-run dbt port of bigquery/21_strategy_vs_park.sql:analytics.park_baseline — canonical source is that file until owner cutover.
-- One row: "what would parking everything have earned" — the weekly email's hero scale
-- anchor. Anchored on strategy_vs_park_daily (not perf.strategy_daily directly, which is
-- rebuilt via a non-atomic DELETE+INSERT in ops.sp_recompute_engine — a mid-recompute read
-- would transiently see an empty table). park_dollars_approx uses current total sleeve NAV
-- as the base rather than duplicating the deposit literal hardcoded in strategy_nav.

WITH f AS (
  SELECT MIN(as_of_date) AS first_deployed_date
  FROM {{ ref('strategy_vs_park_daily') }}
),
p AS (
  SELECT EXP(SUM(LN(1 + sg.r_sgov))) - 1 AS park_return
  FROM {{ ref('sgov_daily_return') }} sg, f
  WHERE sg.as_of_date >= f.first_deployed_date
)
SELECT
  f.first_deployed_date,
  p.park_return,
  (SELECT SUM(nav) FROM {{ ref('strategy_nav') }}) * p.park_return
    AS park_dollars_approx
FROM f, p

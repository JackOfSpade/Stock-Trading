-- Parallel-run dbt port of bigquery/202_sweep_recipient_weights_nomadic_exclusion.sql:state.sweep_recipient_weights — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH enabled AS (
  SELECT e.strategy_code
  FROM {{ ref('strategy_capital_enablement') }} e
  JOIN {{ source('state_external', 'strategy_roster') }} r ON r.strategy_code = e.strategy_code
  WHERE e.capital_enabled AND r.is_active
    -- ADDED (bigquery/202, 2026-08-30): nomadic exclusion, so this view's recipient set is
    -- predicate-identical to state.regime_capital_sync_pending's `enabled_recipients` (bigquery/168
    -- FIX 7). A NOMADIC strategy holds no exclusive standing capital (Operating_Protocols.md §16), so
    -- it is not an eligible sweep RECIPIENT and must never be handed a tilt share.
    AND e.strategy_code NOT IN (
      SELECT strategy_code FROM {{ source('state_external', 'strategy_declared_frequency') }}
      WHERE is_low_frequency_by_design AND strategy_code IS NOT NULL
    )
),
-- Days in the trailing 180 on which each strategy held at least one non-dust open position.
-- Written as an explicit JOIN, not a correlated subquery: BigQuery rejects a subquery that references
-- another table from the outer query ("Correlated subqueries that reference other tables are not
-- supported unless they can be de-correlated"), which the obvious EXISTS formulation of this trips.
cal AS (
  SELECT dt FROM UNNEST(GENERATE_DATE_ARRAY(
    DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 179 DAY),
    CURRENT_DATE('America/Denver'))) AS dt
),
lots AS (
  SELECT strategy, entry_date,
    -- An open lot is deployed through today, so its effective exit is today, not NULL.
    COALESCE(exit_date, CURRENT_DATE('America/Denver')) AS eff_exit
  FROM {{ ref('position_lifecycle') }}
  WHERE NOT COALESCE(is_dust, FALSE)
),
days AS (
  -- LEFT JOINs throughout so a strategy that has never deployed yields COUNT(DISTINCT NULL) = 0
  -- rather than dropping out of the result entirely.
  SELECT en.strategy_code, COUNT(DISTINCT c.dt) AS deployed_days_180
  FROM enabled en
  LEFT JOIN lots l ON l.strategy = en.strategy_code
  LEFT JOIN cal c ON c.dt >= l.entry_date AND c.dt <= l.eff_exit
  GROUP BY en.strategy_code
),
scored AS (
  SELECT strategy_code,
    deployed_days_180,
    ROUND(deployed_days_180 / 180.0, 4) AS capacity_ratio,
    -- Map [0,1] capacity onto the sanctioned [0.5x, 2x] band. A never-deploying recipient lands on the
    -- FLOOR (0.5x), never zero -- §16's band says "never $0", and a strategy that simply has not found
    -- a qualifying setup yet must not be defunded for it.
    ROUND(0.5 + 1.5 * (deployed_days_180 / 180.0), 4) AS raw_multiplier
  FROM days
)
SELECT
  strategy_code,
  deployed_days_180,
  capacity_ratio,
  LEAST(2.0, GREATEST(0.5, raw_multiplier)) AS band_multiplier,
  COUNT(*) OVER () AS n_recipients,
  -- Normalised share of whatever amount is being swept. Sums to 1.0 across recipients.
  SAFE_DIVIDE(
    LEAST(2.0, GREATEST(0.5, raw_multiplier)),
    SUM(LEAST(2.0, GREATEST(0.5, raw_multiplier))) OVER ()
  ) AS sweep_share,
  -- The equal share, for comparison. When these two agree the weight is doing nothing, which is the
  -- expected and correct state whenever recipients are indistinguishable.
  SAFE_DIVIDE(1.0, COUNT(*) OVER ()) AS equal_share
FROM scored

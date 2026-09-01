-- Parallel-run dbt port of bigquery/168_nomadic_capital_fixes.sql:state.strategy_nomadic_status — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH roster AS (
  SELECT strategy_code
  FROM {{ source('state_external', 'strategy_roster') }}
  WHERE is_active
),
nav AS (
  SELECT strategy, deposits, nav, deployed_mv, available_funds
  FROM {{ ref('strategy_nav') }}
),
-- Confirmed-fill open lots only, dust-excluded (bigquery/125's audited is_dust, NULL failing open as
-- non-dust) -- the same predicate every other position_lifecycle reader uses. This is a FILLS-based
-- signal and deliberately does NOT see pending orders; that is what the reserved CTE below is for.
deploy AS (
  SELECT strategy AS strategy_code, COUNTIF(exit_date IS NULL) AS open_positions
  FROM {{ ref('position_lifecycle') }}
  WHERE NOT COALESCE(is_dust, FALSE)
  GROUP BY strategy
),
-- Cash a pending staged BUY already needs. state.open_orders is latest-row-per-item_key and already
-- filtered to status='pending'; its reserved_cash is BUY-only, OCC-aware (x100 on option contracts)
-- and includes the 0.35 commission buffer. Mirrors Operating_Protocols.md §13's park-sweep free_cash.
reserved AS (
  SELECT strategy AS strategy_code, SUM(COALESCE(reserved_cash, 0)) AS reserved_cash_total
  FROM {{ ref('open_orders') }}
  WHERE strategy IS NOT NULL
  GROUP BY strategy
)
SELECT
  r.strategy_code,
  ROUND(COALESCE(n.available_funds, 0), 2)                        AS idle_capital,
  ROUND(COALESCE(n.nav, 0), 2)                                    AS nav,
  ROUND(COALESCE(n.deployed_mv, 0), 2)                            AS deployed_mv,
  COALESCE(d.open_positions, 0)                                   AS open_positions,
  ROUND(COALESCE(rv.reserved_cash_total, 0), 2)                   AS reserved_cash_total,
  COALESCE(ce.capital_enabled, FALSE)                             AS capital_enabled,
  f.declared_frequency_text,
  COALESCE(f.is_low_frequency_by_design, FALSE)                   AS is_nomadic,
  -- What is genuinely free to move: idle cash NET of anything a pending buy already claims.
  GREATEST(
    CAST(0 AS NUMERIC),
    ROUND(COALESCE(n.available_funds, 0) - COALESCE(rv.reserved_cash_total, 0), 2)
  )                                                                AS sweepable_amount,
  (
    COALESCE(f.is_low_frequency_by_design, FALSE)
    -- Capital-DISABLED strategies are the regime mechanism's business (bigquery/98); never let two
    -- mechanisms contend for the same dollars. A nomadic strategy still shows is_nomadic=TRUE here
    -- while disabled -- that is the whole point of FIX 1 -- it just does not sweep on this path.
    AND COALESCE(ce.capital_enabled, FALSE)
    AND COALESCE(d.open_positions, 0) = 0
    AND GREATEST(
          CAST(0 AS NUMERIC),
          ROUND(COALESCE(n.available_funds, 0) - COALESCE(rv.reserved_cash_total, 0), 2)
        ) > 0
  )                                                                AS sweep_now
FROM roster r
LEFT JOIN nav n  ON n.strategy = r.strategy_code
LEFT JOIN deploy d ON d.strategy_code = r.strategy_code
LEFT JOIN reserved rv ON rv.strategy_code = r.strategy_code
LEFT JOIN {{ ref('strategy_capital_enablement') }} ce ON ce.strategy_code = r.strategy_code
LEFT JOIN {{ source('state_external', 'strategy_declared_frequency') }} f ON f.strategy_code = r.strategy_code

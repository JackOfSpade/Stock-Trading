-- Parallel-run dbt port of bigquery/14_weekly_report.sql:state.open_positions_summary — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH latest_close AS (
  SELECT ticker, close, mark_date FROM {{ ref('daily_marks_curated') }}
  QUALIFY ROW_NUMBER() OVER (PARTITION BY ticker ORDER BY mark_date DESC) = 1
)
SELECT
  cp.strategy, cp.ticker, cp.shares, cp.cost_basis,
  lc.close AS mark, lc.mark_date,
  ROUND(cp.shares * lc.close, 2) AS market_value,
  SAFE_DIVIDE(cp.shares * lc.close - cp.cost_basis, cp.cost_basis) AS unrealized_pct,
  cp.convergence_target, cp.time_exit_date
FROM {{ ref('current_positions') }} cp
LEFT JOIN latest_close lc ON lc.ticker = cp.ticker
WHERE cp.status = 'OPEN' AND cp.ticker != 'SGOV'
ORDER BY cp.strategy, cp.ticker

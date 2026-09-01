-- Parallel-run dbt port of bigquery/167_nomadic_capital.sql:state.nomadic_capital_ledger — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH swept AS (
  SELECT strategy, -SUM(amount) AS swept_out_total
  FROM {{ source('events', 'cash_flows') }}
  WHERE source = 'nomadic_capital_sweep' AND amount < 0
  GROUP BY strategy
),
restored AS (
  SELECT strategy, SUM(amount) AS restored_total
  FROM {{ source('events', 'cash_flows') }}
  WHERE source = 'nomadic_capital_restore' AND amount > 0
  GROUP BY strategy
)
SELECT
  r.strategy_code                                             AS strategy,
  COALESCE(sw.swept_out_total, 0)                             AS swept_out_total,
  COALESCE(rs.restored_total, 0)                               AS restored_total,
  -- Positive: this strategy has more swept-out than restored (owed capital sitting with others).
  -- Negative: this strategy has borrowed more than it ever had swept from it (owes its own future
  -- proceeds back). Zero: fully squared up. Deliberately NOT GREATEST(0, ...) — see header point 3.
  COALESCE(sw.swept_out_total, 0) - COALESCE(rs.restored_total, 0) AS net_position
FROM {{ source('state_external', 'strategy_roster') }} r
LEFT JOIN swept    sw ON sw.strategy = r.strategy_code
LEFT JOIN restored rs ON rs.strategy = r.strategy_code

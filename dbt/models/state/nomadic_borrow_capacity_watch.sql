-- Parallel-run dbt port of bigquery/246_nomadic_borrow_blocked_alert.sql:state.nomadic_borrow_capacity_watch — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
WITH nomadic_strategies AS (
  SELECT strategy_code
  FROM {{ ref('strategy_nomadic_status') }}
  WHERE is_nomadic AND capital_enabled
),
nav AS (
  SELECT strategy, available_funds FROM {{ ref('strategy_nav') }}
),
low_freq AS (
  SELECT strategy_code FROM {{ source('state_external', 'strategy_declared_frequency') }}
  WHERE is_low_frequency_by_design
),
donors AS (
  -- Same eligibility predicate as fn_nomadic_capital_restore_plan's own `donors` CTE above, applied
  -- per potential borrower rather than for one parameterized call.
  SELECT ns.strategy_code AS borrower, e.strategy_code AS donor_strategy, nv.available_funds AS donor_capacity
  FROM nomadic_strategies ns
  CROSS JOIN {{ ref('strategy_capital_enablement') }} e
  JOIN nav nv ON nv.strategy = e.strategy_code
  WHERE e.capital_enabled
    AND e.strategy_code != ns.strategy_code
    AND e.strategy_code NOT IN (SELECT strategy_code FROM low_freq)
    AND nv.available_funds > 0
)
SELECT
  ns.strategy_code                                       AS strategy,
  COALESCE(SUM(d.donor_capacity), CAST(0 AS NUMERIC))    AS donor_capacity_total,
  COUNT(d.donor_strategy)                                AS donor_count,
  COALESCE(SUM(d.donor_capacity), CAST(0 AS NUMERIC)) <= 0 AS borrow_blocked
FROM nomadic_strategies ns
LEFT JOIN donors d ON d.borrower = ns.strategy_code
GROUP BY ns.strategy_code

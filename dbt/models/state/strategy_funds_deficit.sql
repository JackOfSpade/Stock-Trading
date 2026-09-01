-- Parallel-run dbt port of bigquery/181_funds_deficit_exempt_any_fully_swept_strategy.sql:state.strategy_funds_deficit — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
SELECT
  n.strategy,
  ROUND(n.available_funds, 2) AS available_funds,
  ROUND(n.deposits, 2)        AS deposits,
  ROUND(n.nav, 2)             AS nav,
  ROUND(n.deployed_mv, 2)     AS deployed_mv,
  COALESCE(f.is_low_frequency_by_design, FALSE) AS is_nomadic,
  CASE
    -- Both deposits<0 branches ALSO require nav<0 (added 2026-08-18, interactive audit). Without it a
    -- row admitted by the FIRST WHERE arm (available_funds<0, i.e. over-deployed) that happens to carry
    -- deposits<0 and nav>=0 -- a fully-swept strategy later funded into a position -- was labelled
    -- 'negative deposits AND negative NAV ... genuine misallocation' while its NAV was non-negative.
    -- That is the same false label this file exists to remove, one WHERE-arm over: the CASE has to
    -- mirror the arm that admitted the row, or it asserts a fact the row does not carry. The ELSE now
    -- correctly and exclusively describes the available_funds<0 arm.
    WHEN ROUND(n.deposits, 2) < 0 AND ROUND(n.nav, 2) < 0 AND COALESCE(f.is_low_frequency_by_design, FALSE)
      THEN 'NOMADIC strategy with negative deposits AND negative NAV - this is NOT the benign swept-out-own-P&L case (which is expected and exempted); investigate as a genuine misallocation'
    WHEN ROUND(n.deposits, 2) < 0 AND ROUND(n.nav, 2) < 0
      THEN 'negative deposits AND negative NAV - the negative deposit base is NOT covered by this strategy own accumulated gains, so it is not the benign fully-swept case; investigate as a genuine misallocation'
    ELSE 'deployed market value exceeds this strategy booked NAV'
  END AS likely_cause
FROM {{ ref('strategy_nav') }} n
LEFT JOIN {{ source('state_external', 'strategy_declared_frequency') }} f ON f.strategy_code = n.strategy
WHERE ROUND(n.available_funds, 2) < 0
   -- deposits<0 fires for EVERY strategy whose NAV is ALSO negative (the genuine-misallocation
   -- signature). It is exempted ONLY when nav >= 0, i.e. when the negative deposits is exactly the
   -- retained-own-P&L artefact that ANY full sweep produces by design -- the nomadic sweep
   -- (bigquery/167/168) and the regime-capital sweep (bigquery/98) alike. bigquery/168's FIX 9 keyed
   -- this on the nomadic classification; 2026-08-18 showed the regime-capital path reaches the same
   -- benign state, so it is keyed on the arithmetic instead.
   OR (ROUND(n.deposits, 2) < 0 AND ROUND(n.nav, 2) < 0)

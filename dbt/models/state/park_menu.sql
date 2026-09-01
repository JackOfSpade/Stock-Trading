-- Parallel-run dbt port of bigquery/92_park_allocator.sql:state.park_menu — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
SELECT * FROM UNNEST([
  STRUCT('CASH' AS ticker, 'cash'              AS asset_class, 0 AS risk_tier),
  STRUCT('SGOV' AS ticker, 'tbill'             AS asset_class, 0 AS risk_tier),
  STRUCT('GOVT' AS ticker, 'govt_broad'        AS asset_class, 1 AS risk_tier),
  STRUCT('IEF'  AS ticker, 'govt_intermediate' AS asset_class, 1 AS risk_tier),
  STRUCT('MUB'  AS ticker, 'muni'              AS asset_class, 1 AS risk_tier),
  STRUCT('LQD'  AS ticker, 'ig_corp'           AS asset_class, 2 AS risk_tier),
  STRUCT('TLT'  AS ticker, 'govt_long'         AS asset_class, 2 AS risk_tier),
  STRUCT('HYG'  AS ticker, 'high_yield'        AS asset_class, 3 AS risk_tier),
  STRUCT('PFF'  AS ticker, 'preferred'         AS asset_class, 3 AS risk_tier),
  STRUCT('AOR'  AS ticker, 'balanced'          AS asset_class, 3 AS risk_tier),
  STRUCT('VOO'  AS ticker, 'equity_sp500'      AS asset_class, 4 AS risk_tier),
  STRUCT('VTI'  AS ticker, 'equity_total'      AS asset_class, 4 AS risk_tier)
])

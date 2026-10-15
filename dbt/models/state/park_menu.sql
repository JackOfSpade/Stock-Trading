-- Parallel-run dbt port of bigquery/256_park_voo_only.sql:state.park_menu — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
SELECT * FROM UNNEST([
  STRUCT('VOO' AS ticker, 'equity_sp500' AS asset_class, 4 AS risk_tier)
])

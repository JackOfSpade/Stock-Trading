-- Parallel-run dbt port of bigquery/238_nogo_counterfactual_vehicle_aware.sql:analytics.nogo_counterfactual_by_primary — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
SELECT
  COALESCE(sub_pattern_primary, '(unclassified)') AS sub_pattern_primary,
  COUNT(*) AS n_shadowed,
  COUNTIF(closed_out) AS n_closed_out,
  COUNTIF(closed_out AND would_nogo_have_been_correct_long_framing) AS n_correct,
  COUNTIF(closed_out AND NOT would_nogo_have_been_correct_long_framing) AS n_incorrect,
  -- Guards against the exact silent-zero that hid bigquery/152's DEFECT 1: a closed row whose excess
  -- return could not be computed is counted here rather than vanishing between n_correct and n_incorrect.
  COUNTIF(closed_out AND would_nogo_have_been_correct_long_framing IS NULL) AS n_closed_unscored,
  -- Legacy SGOV-benchmarked counts, carried alongside so a reader can see exactly how much of any tally
  -- is attributable to the 2026-09-13 benchmark correction rather than to new evidence.
  COUNTIF(closed_out AND would_nogo_have_been_correct_vs_sgov) AS n_correct_vs_sgov,
  COUNTIF(closed_out AND NOT would_nogo_have_been_correct_vs_sgov) AS n_incorrect_vs_sgov,
  (COUNTIF(closed_out AND would_nogo_have_been_correct_long_framing IS NOT NULL) >= 5) AS min_n_met
FROM {{ ref('nogo_counterfactual') }}
GROUP BY sub_pattern_primary
ORDER BY n_shadowed DESC

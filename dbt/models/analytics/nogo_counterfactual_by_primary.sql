-- Parallel-run dbt port of bigquery/152_nogo_counterfactual_asof_and_primary_grouping.sql:analytics.nogo_counterfactual_by_primary — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
SELECT
  COALESCE(sub_pattern_primary, '(unclassified)') AS sub_pattern_primary,
  COUNT(*) AS n_shadowed,
  COUNTIF(closed_out) AS n_closed_out,
  COUNTIF(closed_out AND would_nogo_have_been_correct_long_framing) AS n_correct,
  COUNTIF(closed_out AND NOT would_nogo_have_been_correct_long_framing) AS n_incorrect,
  -- Guards against the exact silent-zero that hid DEFECT 1: a closed row whose excess return could not be
  -- computed is counted here rather than vanishing between n_correct and n_incorrect.
  COUNTIF(closed_out AND would_nogo_have_been_correct_long_framing IS NULL) AS n_closed_unscored,
  (COUNTIF(closed_out AND would_nogo_have_been_correct_long_framing IS NOT NULL) >= 5) AS min_n_met
FROM {{ ref('nogo_counterfactual') }}
GROUP BY sub_pattern_primary
ORDER BY n_shadowed DESC

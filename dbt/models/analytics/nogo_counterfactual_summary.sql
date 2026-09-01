-- Parallel-run dbt port of bigquery/28_nogo_shadow.sql:analytics.nogo_counterfactual_summary — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
SELECT
  COALESCE(sub_pattern, '(unclassified)') AS sub_pattern,
  COUNT(*) AS n_shadowed,
  COUNTIF(closed_out) AS n_closed_out,
  COUNTIF(closed_out AND would_nogo_have_been_correct_long_framing) AS n_correct,
  COUNTIF(closed_out AND NOT would_nogo_have_been_correct_long_framing) AS n_incorrect,
  -- Directional-only flag; a below-chance tally is a candidate for a human taxonomy review, never an
  -- automatic demotion (small-sample multiple-testing risk across many sub-patterns).
  (COUNTIF(closed_out) >= 5) AS min_n_met
FROM {{ ref('nogo_counterfactual') }}
GROUP BY sub_pattern
ORDER BY n_shadowed DESC

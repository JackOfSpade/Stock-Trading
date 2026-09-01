-- Parallel-run dbt port of bigquery/116_decision_record_analyzability.sql:analytics.thesis_outcome_summary — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
SELECT
  strategy,
  COALESCE(sub_pattern, '(unclassified)') AS sub_pattern,
  COUNT(*) AS n_theses,
  COUNTIF(position_closed) AS n_closed,
  COUNTIF(position_closed AND was_profitable) AS n_profitable,
  COUNTIF(position_closed AND NOT was_profitable) AS n_unprofitable,
  -- Directional-only floor; below it, the tally is a data point, never a trigger (min_n=15 per the
  -- architect recommendation's own stated floor -- 3x nogo_counterfactual_summary's min_n=5, since a real
  -- position's realized P&L carries more weight per observation than a counterfactual SGOV-vs-price delta).
  (COUNTIF(position_closed) >= 15) AS min_n_met
FROM {{ ref('thesis_outcomes') }}
WHERE is_go_family
GROUP BY strategy, sub_pattern
ORDER BY strategy, n_theses DESC

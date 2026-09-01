-- Parallel-run dbt port of bigquery/116_decision_record_analyzability.sql:analytics.conviction_pct_calibration — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH scored AS (
  SELECT
    -- Decile buckets on the NORMALIZED value, so the 7 fraction-scale rows land in the right bucket
    -- instead of reading as ~1%.
    CAST(FLOOR(conviction_pct_normalized / 10) * 10 AS INT64) AS pct_bucket_low,
    position_closed, was_profitable, conviction_pct_normalized
  FROM {{ ref('conviction_features') }}
  WHERE conviction_pct_normalized IS NOT NULL
)
SELECT
  pct_bucket_low,
  pct_bucket_low + 10 AS pct_bucket_high,
  COUNT(*) AS n_theses,
  COUNTIF(position_closed) AS closed,
  COUNTIF(was_profitable) AS wins,
  ROUND(AVG(conviction_pct_normalized), 2) AS mean_stated_pct,
  -- The calibration comparison itself: stated confidence vs realized frequency, both as percentages.
  ROUND(100 * SAFE_DIVIDE(COUNTIF(was_profitable), COUNTIF(position_closed)), 2) AS realized_win_pct,
  ROUND(100 * SAFE_DIVIDE(COUNTIF(was_profitable), COUNTIF(position_closed)) - AVG(conviction_pct_normalized), 2)
    AS calibration_gap_pct,   -- >0 = under-confident, <0 = over-confident. NULL until closed>0.
  (COUNTIF(position_closed) >= 15) AS min_n_met
FROM scored
GROUP BY pct_bucket_low
ORDER BY pct_bucket_low

-- Parallel-run dbt port of bigquery/83_correlation_controls.sql:analytics.b_pairwise_correlation — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH b_pos AS (
  SELECT DISTINCT ticker
  FROM {{ ref('current_positions') }}
  WHERE strategy = 'B' AND ticker IS NOT NULL
),
rets AS (
  SELECT ticker, mark_date,
    SAFE_DIVIDE(close, LAG(close) OVER (PARTITION BY ticker ORDER BY mark_date)) - 1 AS r
  FROM {{ ref('daily_marks_curated') }}
  WHERE ticker IN (SELECT ticker FROM b_pos)
    AND mark_date >= DATE_SUB(CURRENT_DATE('America/New_York'), INTERVAL 90 DAY)
),
pairs AS (
  SELECT a.ticker AS t1, b.ticker AS t2, a.r AS r1, b.r AS r2
  FROM rets a JOIN rets b ON a.mark_date = b.mark_date AND a.ticker < b.ticker
  WHERE a.r IS NOT NULL AND b.r IS NOT NULL
),
pair_corr AS (
  SELECT t1, t2, CORR(r1, r2) AS corr, COUNT(*) AS overlap_days
  FROM pairs GROUP BY t1, t2
)
SELECT
  (SELECT COUNT(*) FROM b_pos) AS n_positions,
  (SELECT COUNT(*) FROM pair_corr) AS n_pairs,
  (SELECT AVG(corr) FROM pair_corr WHERE overlap_days >= 40) AS avg_offdiagonal_corr,
  -- min over the SAME >=40-day population as AVG/MAX (2026-07-18 audit): an unfiltered global MIN
  -- let a single fresh position drag min_overlap_days below D1's `min_overlap_days >= 40` AND-term
  -- and suppress the KL #12 alert for the WHOLE book — the exact routine state (2 mature correlated
  -- positions + 1 new one) the control exists for. NULL when no qualifying pair exists, which still
  -- correctly fails D1's condition (no mature evidence -> no alert).
  (SELECT MIN(overlap_days) FROM pair_corr WHERE overlap_days >= 40) AS min_overlap_days,
  (SELECT MAX(corr) FROM pair_corr WHERE overlap_days >= 40) AS max_pairwise_corr,
  CURRENT_TIMESTAMP() AS computed_at

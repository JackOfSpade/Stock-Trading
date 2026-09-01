-- Parallel-run dbt port of bigquery/92_park_allocator.sql:state.mark_discontinuity_watch — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH watched AS (
  SELECT DISTINCT ticker FROM {{ ref('current_positions') }} WHERE ticker IS NOT NULL
  UNION DISTINCT SELECT 'SGOV' UNION DISTINCT SELECT 'VOO'  UNION DISTINCT SELECT 'SPY'
  UNION DISTINCT SELECT 'GOVT' UNION DISTINCT SELECT 'IEF'  UNION DISTINCT SELECT 'TLT'
  UNION DISTINCT SELECT 'LQD'  UNION DISTINCT SELECT 'MUB'  UNION DISTINCT SELECT 'HYG'
  UNION DISTINCT SELECT 'PFF'  UNION DISTINCT SELECT 'AOR'  UNION DISTINCT SELECT 'VTI'
),
combined_marks AS (
  SELECT ticker, mark_date, close, dividend, split_ratio, 1 AS src_priority
  FROM {{ ref('daily_marks_curated') }}
  WHERE ticker IN (SELECT ticker FROM watched)
  UNION ALL
  SELECT ticker, mark_date, close, dividend, split_ratio, 2 AS src_priority
  FROM {{ source('state_external', 'signal_marks_curated') }}
  WHERE ticker IN (SELECT ticker FROM watched)
),
marks AS (
  SELECT ticker, mark_date, close, dividend, split_ratio
  FROM combined_marks
  QUALIFY ROW_NUMBER() OVER (PARTITION BY ticker, mark_date ORDER BY src_priority) = 1
),
seq AS (
  SELECT ticker, mark_date, close,
         COALESCE(dividend, 0) AS dividend,
         COALESCE(NULLIF(split_ratio, 0), 1) AS split_ratio,
         LAG(close) OVER (PARTITION BY ticker ORDER BY mark_date) AS prev_close
  FROM marks
)
SELECT
  ticker, mark_date, close, prev_close, split_ratio, dividend,
  SAFE_DIVIDE(close, prev_close) - 1 AS raw_move,
  (prev_close IS NOT NULL
   AND ABS(SAFE_DIVIDE(close, prev_close) - 1) > 0.25   -- >25% day-over-day jump
   AND split_ratio = 1                                  -- NOT a recorded split (the engine handles that)
   AND ABS(SAFE_DIVIDE(dividend, prev_close)) < 0.25     -- NOT explained by a same-day dividend
  ) AS is_discontinuity
FROM seq

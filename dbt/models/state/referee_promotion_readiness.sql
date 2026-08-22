-- Parallel-run dbt port of bigquery/143_adversarial_review_correction_path.sql:state.referee_promotion_readiness — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
WITH first_ref AS (
  -- MIN(event_ts) = the actual INSERTION time of the earliest referee_gemini row, deliberately NOT its
  -- review_date (bigquery/44 backdates review_date to the original attacker submission; keying the
  -- 90-day burn-in on it would satisfy the quarter clock retroactively — see bigquery/84's note).
  SELECT MIN(event_ts) AS first_referee_ts, COUNT(*) AS referee_rows
  FROM {{ ref('adversarial_reviews_current') }}
  WHERE role = 'referee_gemini'
),
concur_rollup AS (
  SELECT COALESCE(n_scored, 0) AS n_scored, concurrence_rate
  FROM {{ ref('referee_concurrence_calibration') }}
  WHERE review_type = '__ALL__'
),
class_breadth AS (
  -- Distinct review_types with a non-trivial per-class sample (n_scored >= 2). Empty calibration
  -- => COUNT(*)=0 => the bar stays FALSE — fail-closed, same as every other bar here.
  SELECT COUNT(*) AS n_types_with_evidence
  FROM {{ ref('referee_concurrence_calibration') }}
  WHERE review_type != '__ALL__' AND n_scored >= 2
)
SELECT
  fr.first_referee_ts,
  fr.referee_rows,
  r.n_scored,
  r.concurrence_rate,
  cb.n_types_with_evidence,
  TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), fr.first_referee_ts, DAY) AS days_since_first_referee,
  (fr.first_referee_ts IS NOT NULL
   AND TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), fr.first_referee_ts, DAY) >= 90) AS quarter_elapsed,
  (r.n_scored >= 6) AS sample_floor_met,
  (COALESCE(r.concurrence_rate, 0.0) >= 0.80) AS concurrence_met,
  (cb.n_types_with_evidence >= 2) AS class_breadth_met,
  NOT EXISTS (SELECT 1 FROM {{ source('ops', 'loop_promotion_log') }} pl
              WHERE pl.loop_id = 'cross_model_referee_independence' AND pl.to_stage = 'active_auto') AS not_already_promoted,
  (fr.first_referee_ts IS NOT NULL
   AND TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), fr.first_referee_ts, DAY) >= 90
   AND r.n_scored >= 6
   AND COALESCE(r.concurrence_rate, 0.0) >= 0.80
   AND cb.n_types_with_evidence >= 2
   AND NOT EXISTS (SELECT 1 FROM {{ source('ops', 'loop_promotion_log') }} pl
                   WHERE pl.loop_id = 'cross_model_referee_independence' AND pl.to_stage = 'active_auto')) AS ready_for_promotion
FROM first_ref fr CROSS JOIN concur_rollup r CROSS JOIN class_breadth cb

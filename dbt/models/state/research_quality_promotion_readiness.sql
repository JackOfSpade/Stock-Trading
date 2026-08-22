-- Parallel-run dbt port of bigquery/71_research_quality_promotion.sql:state.research_quality_promotion_readiness — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
WITH ranked AS (
  SELECT strategy, sub_pattern, cycle_date, min_n_met,
         ROW_NUMBER() OVER (PARTITION BY strategy, sub_pattern ORDER BY cycle_date DESC) AS rn
  FROM {{ source('ops', 'research_quality_observations') }}
), t3 AS (
  SELECT strategy, sub_pattern, COUNT(*) AS n_recent_cycles, COUNTIF(min_n_met) AS n_recent_met
  FROM ranked WHERE rn <= 3 GROUP BY 1, 2
)
SELECT strategy, sub_pattern, n_recent_cycles, n_recent_met,
  (n_recent_cycles >= 3 AND n_recent_met = 3) AS persistence_met,
  NOT EXISTS (SELECT 1 FROM {{ source('ops', 'loop_promotion_log') }} pl
              WHERE pl.loop_id = 'research_quality_feedback' AND pl.to_stage = 'active_auto') AS not_already_promoted,
  (n_recent_cycles >= 3 AND n_recent_met = 3
   AND NOT EXISTS (SELECT 1 FROM {{ source('ops', 'loop_promotion_log') }} pl
                   WHERE pl.loop_id = 'research_quality_feedback' AND pl.to_stage = 'active_auto')) AS ready_for_promotion
FROM t3

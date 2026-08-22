-- Parallel-run dbt port of bigquery/143_adversarial_review_correction_path.sql:state.foundation_change_termination_readiness — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
WITH orch AS (
  SELECT strategy AS strategy_code, review_id, verdict AS orch_verdict,
         ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY review_date DESC, cycle_number DESC, event_ts DESC) AS rn
  FROM {{ ref('adversarial_reviews_current') }}
  WHERE review_type = 'foundation-change-assessment' AND role = 'orchestrator'
),
referee AS (
  SELECT review_id, verdict AS referee_verdict
  FROM {{ ref('adversarial_reviews_current') }}
  WHERE review_type = 'foundation-change-assessment' AND role = 'referee_gemini'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY review_id ORDER BY cycle_number DESC, review_date DESC, event_ts DESC) = 1
)
SELECT
  o.strategy_code, o.review_id, o.orch_verdict, ref.referee_verdict,
  o.orch_verdict = 'TERMINATE' AS orchestrator_terminate,
  COALESCE(ref.referee_verdict, 'MISSING') = 'TERMINATE' AS referee_concurs,
  NOT EXISTS (SELECT 1 FROM {{ source('ops', 'roster_change_log') }} cl
              WHERE cl.strategy_code = o.strategy_code AND cl.to_state = 'TERMINATED'
                AND cl.note LIKE 'foundation-change%') AS not_already_transitioned,
  (o.orch_verdict = 'TERMINATE'
   AND COALESCE(ref.referee_verdict, 'MISSING') = 'TERMINATE'
   AND NOT EXISTS (SELECT 1 FROM {{ source('ops', 'roster_change_log') }} cl
                   WHERE cl.strategy_code = o.strategy_code AND cl.to_state = 'TERMINATED'
                     AND cl.note LIKE 'foundation-change%')) AS ready
FROM orch o
LEFT JOIN referee ref ON ref.review_id = o.review_id
WHERE o.rn = 1

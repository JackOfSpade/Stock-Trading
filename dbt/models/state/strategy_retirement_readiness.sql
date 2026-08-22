-- Parallel-run dbt port of bigquery/143_adversarial_review_correction_path.sql:state.strategy_retirement_readiness — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
WITH orch AS (
  SELECT strategy AS strategy_code, verdict AS orch_verdict, review_id,
         ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY review_date DESC, cycle_number DESC, event_ts DESC) AS rn
  FROM {{ ref('adversarial_reviews_current') }}
  WHERE review_type = 'strategy-retirement' AND role = 'orchestrator'
),
referee AS (
  -- Paired to the orchestrator by review_id (like the foundation_change_termination_readiness sibling
  -- below), NOT by strategy_code — pairing by strategy alone let a STALE referee_gemini verdict from an
  -- earlier, different retirement review satisfy referee_concurs against a NEW orchestrator verdict
  -- (adversarial self-audit fix, rev 2026-07-11).
  SELECT review_id, verdict AS referee_verdict
  FROM {{ ref('adversarial_reviews_current') }}
  WHERE review_type = 'strategy-retirement' AND role = 'referee_gemini'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY review_id ORDER BY cycle_number DESC, review_date DESC, event_ts DESC) = 1
),
rails AS (SELECT * FROM {{ ref('arsenal_rails') }}),
ars AS (SELECT enabled, incubation_frozen FROM {{ ref('arsenal_enabled') }})
SELECT
  r.strategy_code,
  o.orch_verdict,
  ref.referee_verdict,
  COALESCE(o.orch_verdict, 'MISSING') = 'RETIRE' AS orchestrator_retire,
  COALESCE(ref.referee_verdict, 'MISSING') = 'RETIRE' AS referee_concurs,
  rails.active_count > rails.n_min AS floor_ok,
  (ars.enabled AND NOT ars.incubation_frozen) AS arsenal_ok,
  NOT EXISTS (SELECT 1 FROM {{ source('ops', 'roster_change_log') }} cl
              WHERE cl.strategy_code = r.strategy_code AND cl.to_state = 'TERMINATED') AS not_already_transitioned,
  (COALESCE(o.orch_verdict, 'MISSING') = 'RETIRE'
   AND COALESCE(ref.referee_verdict, 'MISSING') = 'RETIRE'
   AND rails.active_count > rails.n_min
   AND ars.enabled AND NOT ars.incubation_frozen
   AND NOT EXISTS (SELECT 1 FROM {{ source('ops', 'roster_change_log') }} cl
                   WHERE cl.strategy_code = r.strategy_code AND cl.to_state = 'TERMINATED')) AS ready
FROM {{ source('state_external', 'strategy_roster') }} r
LEFT JOIN orch o ON o.strategy_code = r.strategy_code AND o.rn = 1
LEFT JOIN referee ref ON ref.review_id = o.review_id
CROSS JOIN rails CROSS JOIN ars
WHERE r.current_state = 'RETIREMENT_PROPOSED'

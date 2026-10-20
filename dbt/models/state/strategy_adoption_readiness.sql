-- Parallel-run dbt port of bigquery/259_live_ramp.sql:state.strategy_adoption_readiness — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
WITH latest_verdict AS (
  SELECT strategy AS strategy_code, verdict, review_id
  FROM {{ ref('adversarial_reviews_current') }}
  WHERE review_type = 'strategy-adoption' AND role = 'orchestrator'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY review_date DESC, cycle_number DESC, event_ts DESC) = 1
),
theater AS (
  SELECT review_id, judge_independent
  FROM {{ source('analytics_external', 'theater_judge') }}
),
rails AS (SELECT * FROM {{ ref('arsenal_rails') }}),
ars AS (SELECT enabled, incubation_frozen FROM {{ ref('arsenal_enabled') }})
SELECT
  r.strategy_code,
  v.verdict,
  v.verdict = 'SUFFICIENT' AS review_sufficient,
  COALESCE(t.judge_independent, FALSE) AS theater_ok,
  NOT rails.incubation_cap_reached AS caps_ok,
  NOT rails.at_ceiling AS ceiling_ok,
  (ars.enabled AND NOT ars.incubation_frozen) AS arsenal_ok,
  NOT EXISTS (SELECT 1 FROM {{ source('ops', 'roster_change_log') }} cl
              WHERE cl.change_key = CONCAT(r.strategy_code, ':UNDER_REVIEW->PROBE')) AS not_already_transitioned,
  (v.verdict = 'SUFFICIENT'
   AND COALESCE(t.judge_independent, FALSE)
   AND NOT rails.incubation_cap_reached
   AND NOT rails.at_ceiling
   AND ars.enabled AND NOT ars.incubation_frozen
   AND NOT EXISTS (SELECT 1 FROM {{ source('ops', 'roster_change_log') }} cl
                   WHERE cl.change_key = CONCAT(r.strategy_code, ':UNDER_REVIEW->PROBE'))) AS ready
FROM {{ source('state_external', 'strategy_roster') }} r
JOIN latest_verdict v USING (strategy_code)
LEFT JOIN theater t ON t.review_id = v.review_id
CROSS JOIN rails CROSS JOIN ars
WHERE r.current_state = 'UNDER_REVIEW'

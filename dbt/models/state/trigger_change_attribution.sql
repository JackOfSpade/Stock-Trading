-- Parallel-run dbt port of bigquery/195_trigger_change_attribution.sql:state.trigger_change_attribution — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH obs AS (
  SELECT
    routine, trigger_id, instruction, api_updated_at, observed_ts, observed_by,
    LAG(instruction)    OVER w AS prev_instruction,
    LAG(observed_ts)    OVER w AS prev_observed_ts,
    LAG(api_updated_at) OVER w AS prev_api_updated_at,
    LAG(observed_by)    OVER w AS prev_observed_by
  FROM {{ source('ops', 'trigger_observations') }}
  WINDOW w AS (PARTITION BY routine ORDER BY observed_ts)
),
changes AS (
  SELECT * FROM obs
  -- prev IS NULL => this routine's first-ever observation: a baseline, not a change.
  WHERE prev_observed_ts IS NOT NULL
    AND COALESCE(instruction, '') != COALESCE(prev_instruction, '')
)
SELECT
  c.routine,
  c.trigger_id,
  c.prev_observed_ts        AS changed_after,       -- the change happened strictly inside
  c.observed_ts             AS changed_by_at_latest, -- this bracket
  c.prev_api_updated_at,
  c.api_updated_at,
  c.prev_instruction,
  c.instruction             AS new_instruction,
  c.prev_observed_by        AS bracket_opened_by,
  c.observed_by             AS bracket_closed_by,
  i.actor                   AS attributed_to,       -- THE ANSWER: who declared this change
  i.reason                  AS attributed_reason,
  i.intent_ts               AS attributed_intent_ts,
  i.retroactive             AS attribution_is_retroactive,
  CASE
    WHEN i.actor IS NULL THEN 'none'
    WHEN i.intended_instruction IS NOT NULL AND i.intended_instruction = c.instruction THEN 'exact-text'
    ELSE 'routine-and-field'
  END                       AS match_strength,
  (i.actor IS NULL)         AS unattributed,        -- the alertable condition
  CURRENT_TIMESTAMP()       AS checked_at
FROM changes c
LEFT JOIN {{ source('ops', 'trigger_change_intents') }} i
  ON  i.routine   = c.routine
  AND i.field     = 'instruction'
  AND i.intent_ts <= c.observed_ts
  AND i.intent_ts >  c.prev_observed_ts
  AND (i.intended_instruction IS NULL OR i.intended_instruction = c.instruction)
-- One row per change: if several intents match, keep the strongest/most recent claim.
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY c.routine, c.observed_ts
  ORDER BY (i.intended_instruction = c.instruction) DESC NULLS LAST, i.intent_ts DESC) = 1

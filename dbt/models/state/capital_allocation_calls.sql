-- Parallel-run dbt port of bigquery/144_decision_log_correction_consumers.sql:state.capital_allocation_calls — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH calls AS (
  SELECT
    entry_id,
    entry_date,
    event_ts,
    body_md                                                        AS rationale,
    JSON_VALUE(fields, '$.trigger')                                AS trigger,
    JSON_VALUE(fields, '$.conviction')                             AS conviction,
    SAFE_CAST(JSON_VALUE(fields, '$.conviction_pct') AS NUMERIC)   AS conviction_pct,
    SAFE_CAST(JSON_VALUE(fields, '$.is_default_equal') AS BOOL)    AS is_default_equal,
    JSON_VALUE(fields, '$.winner_code')                            AS winner_code,
    JSON_VALUE(fields, '$.runner_up_code')                         AS runner_up_code,
    SAFE_CAST(JSON_VALUE(fields, '$.total_dollars') AS NUMERIC)    AS total_dollars,
    JSON_VALUE(fields, '$.invalidation')                           AS invalidation,
    JSON_VALUE(fields, '$.theater_check')                          AS theater_check,
    JSON_QUERY_ARRAY(fields, '$.allocations')                      AS allocations
  FROM {{ source('state_external', 'decision_log_current') }}
  WHERE entry_type = 'capital-allocation'
)
-- One row per {call, survivor}. W5's CAPITAL-ALLOCATION SCORECARD bullet (Claude_Task_Plan.md) reads
-- `deviation_pct` — the call's own equal-split counterfactual, computed from THIS call's own
-- allocations-array length (the active-survivor count AS OF that historical call), never a live join
-- back to state.strategy_roster's CURRENT membership, which could differ from what this call actually
-- saw (a later termination/adoption must never revise an earlier call's counterfactual — the same
-- as-of-the-flow's-own-date discipline bigquery/22_cash_flows.sql's analytics.strategy_nav uses for
-- historical equal-split divisors).
SELECT
  entry_id,
  entry_date,
  event_ts,
  trigger,
  conviction,
  conviction_pct,
  is_default_equal,
  winner_code,
  runner_up_code,
  total_dollars,
  invalidation,
  theater_check,
  rationale,
  JSON_VALUE(alloc, '$.strategy_code')                                                  AS strategy_code,
  SAFE_CAST(JSON_VALUE(alloc, '$.pct') AS NUMERIC)                                        AS pct,
  SAFE_CAST(JSON_VALUE(alloc, '$.dollars') AS NUMERIC)                                    AS dollars,
  100.0 / ARRAY_LENGTH(allocations)                                                       AS equal_share_pct,
  SAFE_CAST(JSON_VALUE(alloc, '$.pct') AS NUMERIC) - (100.0 / ARRAY_LENGTH(allocations))  AS deviation_pct
FROM calls, UNNEST(allocations) AS alloc

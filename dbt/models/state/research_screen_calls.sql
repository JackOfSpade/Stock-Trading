-- Parallel-run dbt port of bigquery/122_decision_correction_append_only.sql:state.research_screen_calls — canonical source is that file until
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
    body_md                                                          AS rationale,
    JSON_VALUE(fields, '$.routine')                                  AS routine,
    JSON_VALUE(fields, '$.screen')                                   AS screen,
    JSON_VALUE(fields, '$.population_rail')                          AS population_rail,
    SAFE_CAST(JSON_VALUE(fields, '$.surfaced_count') AS INT64)       AS surfaced_count,
    JSON_VALUE(fields, '$.legacy_rule')                              AS legacy_rule,
    SAFE_CAST(JSON_VALUE(fields, '$.agreement.both') AS INT64)       AS agreement_both,
    SAFE_CAST(JSON_VALUE(fields, '$.agreement.ai_only') AS INT64)    AS agreement_ai_only,
    SAFE_CAST(JSON_VALUE(fields, '$.agreement.rule_only') AS INT64)  AS agreement_rule_only,
    JSON_QUERY_ARRAY(fields, '$.passed')                             AS passed,
    JSON_QUERY_ARRAY(fields, '$.rejected_notable')                   AS rejected_notable
  FROM {{ source('events', 'decision_log') }}
  WHERE entry_type = 'research-screen'
    AND entry_id NOT IN (
      SELECT superseded_by
      FROM {{ source('events', 'decision_log') }}
      WHERE superseded_by IS NOT NULL
    )
)
SELECT
  entry_id, entry_date, event_ts, routine, screen, population_rail, surfaced_count, legacy_rule,
  agreement_both, agreement_ai_only, agreement_rule_only, rationale,
  'passed'                                                      AS side,
  JSON_VALUE(item, '$.name')                                    AS name,
  SAFE_CAST(JSON_VALUE(item, '$.metric_pct') AS NUMERIC)        AS metric_pct,
  JSON_VALUE(item, '$.conviction')                              AS conviction,
  SAFE_CAST(JSON_VALUE(item, '$.conviction_pct') AS NUMERIC)    AS conviction_pct,
  JSON_VALUE(item, '$.reason')                                  AS reason,
  SAFE_CAST(JSON_VALUE(item, '$.below_spec_floor') AS BOOL)     AS below_spec_floor,
  SAFE_CAST(JSON_VALUE(item, '$.legacy_rule_pass') AS BOOL)     AS legacy_rule_pass
FROM calls, UNNEST(passed) AS item

UNION ALL

SELECT
  entry_id, entry_date, event_ts, routine, screen, population_rail, surfaced_count, legacy_rule,
  agreement_both, agreement_ai_only, agreement_rule_only, rationale,
  'rejected_notable'                                             AS side,
  JSON_VALUE(item, '$.name')                                    AS name,
  SAFE_CAST(JSON_VALUE(item, '$.metric_pct') AS NUMERIC)        AS metric_pct,
  JSON_VALUE(item, '$.conviction')                              AS conviction,
  SAFE_CAST(JSON_VALUE(item, '$.conviction_pct') AS NUMERIC)    AS conviction_pct,
  JSON_VALUE(item, '$.reason')                                  AS reason,
  SAFE_CAST(JSON_VALUE(item, '$.below_spec_floor') AS BOOL)     AS below_spec_floor,
  SAFE_CAST(JSON_VALUE(item, '$.legacy_rule_pass') AS BOOL)     AS legacy_rule_pass
FROM calls, UNNEST(rejected_notable) AS item

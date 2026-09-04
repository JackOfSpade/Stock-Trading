-- Parallel-run dbt port of bigquery/222_park_allocation_recent_graded_fields.sql:state.park_allocation_recent — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
SELECT
  entry_id,
  entry_date,
  event_ts,
  decision,
  title,
  JSON_VALUE(fields, '$.vehicle')                               AS vehicle,
  JSON_VALUE(fields, '$.conviction')                            AS conviction,
  SAFE_CAST(JSON_VALUE(fields, '$.conviction_pct') AS NUMERIC)  AS conviction_pct,
  JSON_VALUE(fields, '$.direction')                             AS direction,
  JSON_VALUE(fields, '$.status')                                AS status,
  -- v4 graded fields (bigquery/222).
  SAFE_CAST(JSON_VALUE(fields, '$.target_f_pct') AS INT64)      AS target_f_pct,
  JSON_VALUE(fields, '$.risk_sleeve')                           AS risk_sleeve,
  JSON_VALUE(fields, '$.defensive_sleeve')                      AS defensive_sleeve,
  -- The evidence snapshot D2's recompute-and-refuse step must read.
  JSON_QUERY(fields, '$.readings')                              AS readings,
  JSON_VALUE(fields, '$.status') IS NOT NULL                    AS is_call
FROM {{ source('state_external', 'decision_log_current') }}
WHERE entry_type = 'park-allocation'
ORDER BY event_ts DESC
LIMIT 25

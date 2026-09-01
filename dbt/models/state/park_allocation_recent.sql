-- Parallel-run dbt port of bigquery/144_decision_log_correction_consumers.sql:state.park_allocation_recent — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
SELECT
  entry_id,
  entry_date,
  event_ts,
  decision,
  title,
  JSON_VALUE(fields, '$.vehicle')                               AS vehicle,
  JSON_VALUE(fields, '$.conviction')                            AS conviction,
  SAFE_CAST(JSON_VALUE(fields, '$.conviction_pct') AS NUMERIC)  AS conviction_pct,
  JSON_VALUE(fields, '$.direction')                             AS direction,  -- 'de-risk' | 're-risk' | 'lateral' | 'keep'
  JSON_VALUE(fields, '$.status')                                AS status,     -- 'PENDING' | 'BOUND' | 'RECORD_ONLY'
  -- CALL-SHAPE FLAG (2026-08-04, alert c5044046-53da-4d91-be8d-4002d1882ec0). Every real D1 park call -- KEEP,
  -- DE-RISK and SWITCH alike -- carries a status; a row without one is some other kind of park event (today:
  -- D2a's COVER/sweep staging note) that happens to share this entry_type. Consumers that need "the standing
  -- allocation call" must filter on this; state.park_allocation_latest below does.
  JSON_VALUE(fields, '$.status') IS NOT NULL                    AS is_call
FROM {{ source('state_external', 'decision_log_current') }}
WHERE entry_type = 'park-allocation'
ORDER BY event_ts DESC
LIMIT 25

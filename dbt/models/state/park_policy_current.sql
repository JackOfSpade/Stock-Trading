-- Parallel-run dbt port of bigquery/220_park_two_sleeve_book.sql:state.park_policy_current — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
WITH latest AS (
  SELECT vehicle, effective_date, note, target_f_pct, risk_sleeve, defensive_sleeve
  FROM {{ source('events', 'park_policy_changes') }}
  QUALIFY ROW_NUMBER() OVER (ORDER BY event_ts DESC) = 1
),
marker AS (
  SELECT COUNT(*) > 0 AS graded_enabled
  FROM {{ source('events', 'park_policy_changes') }}
  WHERE note LIKE 'PARK-V4-SCHEMA-VERSION%'
)
SELECT
  l.vehicle,
  l.effective_date,
  l.note,
  -- Legacy rows carry no target_f_pct; they mean what they always meant.
  COALESCE(l.target_f_pct, IF(l.vehicle = 'VOO', 0, 100))            AS target_f_pct,
  COALESCE(l.risk_sleeve, 'VOO')                                     AS risk_sleeve,
  COALESCE(l.defensive_sleeve, IF(l.vehicle = 'VOO', 'SGOV', l.vehicle)) AS defensive_sleeve,
  m.graded_enabled
FROM latest l CROSS JOIN marker m

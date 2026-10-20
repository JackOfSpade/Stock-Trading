-- Parallel-run dbt port of bigquery/260_guard_waivers.sql:state.guard_waivers_open — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
WITH td AS (
  SELECT today FROM {{ ref('trading_day_today') }}
),
granted AS (
  SELECT waiver_id, routine, guard, run_date, actor AS granted_by, note AS reason, event_ts AS granted_ts
  FROM {{ source('ops', 'guard_waivers') }}
  WHERE event = 'GRANTED'
),
closed AS (
  SELECT DISTINCT waiver_id
  FROM {{ source('ops', 'guard_waivers') }}
  WHERE event IN ('CONSUMED', 'REVOKED')
)
SELECT g.waiver_id, g.routine, g.guard, g.run_date, g.granted_by, g.reason, g.granted_ts
FROM granted g
CROSS JOIN td
LEFT JOIN closed c USING (waiver_id)
WHERE c.waiver_id IS NULL
  AND g.run_date = td.today

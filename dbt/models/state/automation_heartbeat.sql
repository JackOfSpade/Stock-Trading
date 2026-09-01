-- Parallel-run dbt port of bigquery/106_retire_dashboard_heartbeat.sql:state.automation_heartbeat — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH expected AS (
  SELECT * FROM UNNEST([
    STRUCT('alert_emailer' AS source, 8   AS max_age_hours),   -- polls every ~2h; stale after ~4 misses (jitter-tolerant)
    STRUCT('weekly_report' AS source, 216 AS max_age_hours)    -- weekly; stale after ~9 days (1 missed week + slack)
  ])
),
last AS (
  SELECT source, MAX(beat_ts) AS last_beat_ts
  FROM {{ source('ops', 'heartbeat') }}
  -- A 'poll-error' beat (alert_emailer.gs beat_(false) on a PERSISTENT BigQuery failure) is NOT proof
  -- of life; excluding it from the liveness MAX lets a sustained emailer outage age out and trip the
  -- DTS instead of the error-beat keeping the source "fresh" forever (2026-07-18 audit). Kept in
  -- lockstep with bigquery/16_automation_health.sql's identical `last` CTE.
  WHERE note IS DISTINCT FROM 'poll-error'
  GROUP BY source
)
SELECT
  e.source,
  e.max_age_hours,
  l.last_beat_ts,
  TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), l.last_beat_ts, HOUR) AS age_hours,
  (l.last_beat_ts IS NOT NULL) AS monitored,
  COALESCE(l.last_beat_ts IS NOT NULL
           AND TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), l.last_beat_ts, HOUR) > e.max_age_hours, FALSE) AS stale,
  CURRENT_TIMESTAMP() AS checked_at
FROM expected e
LEFT JOIN last l USING (source)

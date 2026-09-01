-- Parallel-run dbt port of bigquery/63_scheduled_query_version_registry.sql:state.scheduled_query_version_drift — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH latest_beat AS (
  SELECT
    SUBSTR(source, 4) AS sq_name,   -- strip the 'sq:' prefix
    ARRAY_AGG(beat_ts ORDER BY beat_ts DESC LIMIT 1)[SAFE_OFFSET(0)] AS last_beat_ts,
    ARRAY_AGG(version ORDER BY beat_ts DESC LIMIT 1)[SAFE_OFFSET(0)] AS last_reported_version,
    LOGICAL_OR(version IS NOT NULL AND TRIM(version) != '') AS ever_reported_version
  FROM {{ source('ops', 'heartbeat') }}
  WHERE STARTS_WITH(source, 'sq:')
  GROUP BY source
)
SELECT
  e.sq_name,
  e.expected_version,
  e.expected_interval_hours,
  lb.last_reported_version,
  lb.last_beat_ts,
  COALESCE(lb.ever_reported_version, FALSE) AS monitored,
  COALESCE(lb.ever_reported_version, FALSE)
    AND (lb.last_reported_version IS NULL
         OR TRIM(lb.last_reported_version) = ''
         OR lb.last_reported_version != e.expected_version) AS drift,
  -- MON H5 (2026-07-17) beat-AGE dead-man. GRACE_FACTOR = 1.5 (a daily query tolerates one missed run
  -- before flagging; weekly ~10.5d; monthly ~46d — the monthly restore_drill is additionally covered by
  -- restore_stale's own >40d critical, so a generous grace here just avoids false fires on the backstop).
  --   * stale_beat: a query that HAS beaten (monitored) but whose last beat is older than interval x grace
  --     — it was running and silently stopped. NULL expected_interval_hours (unseeded) can never fire.
  (COALESCE(lb.ever_reported_version, FALSE)
   AND e.expected_interval_hours IS NOT NULL
   AND lb.last_beat_ts < TIMESTAMP_SUB(CURRENT_TIMESTAMP(),
                                       INTERVAL CAST(e.expected_interval_hours * 1.5 AS INT64) HOUR)) AS stale_beat,
  --   * never_beat_overdue: a query registered (updated_ts) more than its own cadence-scaled grace ago
  --     that has NEVER beaten — the self-bootstrapping grace so a freshly-registered query stays quiet
  --     until it has had a real chance to fire at least once (matching the state.script_version_drift /
  --     automation_heartbeat convention: no alarm until first beat unless the never-beat state itself
  --     persists past the grace window). FIXED (2026-07-25): this used to be a flat 7 days regardless of
  --     cadence, same GRACE_FACTOR=1.5 scaling as stale_beat above -- but for a MONTHLY query (interval
  --     744h) that flat floor fires every night for ~24 days after registration despite the query never
  --     having had a chance to run yet (verified live: fire_drill_order_guard / restore_drill both
  --     registered 2026-07-17, both monthly-1st-of-month, both correctly never-beaten-yet, both wrongly
  --     flagged never_beat_overdue starting 2026-07-24 -- the scheduled_query_stale alert this fix
  --     resolves). Now GREATEST(7 days, interval_hours * 1.5) -- daily/weekly queries keep effectively the
  --     same (or the already-more-correct stale_beat-matching) grace; a monthly query gets ~46.5 days,
  --     comfortably past its next real firing before ever alarming.
  (NOT COALESCE(lb.ever_reported_version, FALSE)
   AND e.updated_ts < TIMESTAMP_SUB(CURRENT_TIMESTAMP(),
       INTERVAL CAST(GREATEST(7 * 24, COALESCE(e.expected_interval_hours, 0) * 1.5) AS INT64) HOUR)) AS never_beat_overdue,
  CURRENT_TIMESTAMP() AS checked_at
FROM {{ source('state_external', 'expected_scheduled_query_versions') }} e
LEFT JOIN latest_beat lb ON lb.sq_name = e.sq_name

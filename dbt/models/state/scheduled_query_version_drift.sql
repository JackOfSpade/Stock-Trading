-- Parallel-run dbt port of bigquery/232_sq_version_drift_bootstrap_grace.sql:state.scheduled_query_version_drift — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
-- PROVENANCE (hand-written, restored after the 2026-09-09 regeneration per the line above):
-- this port was added 2026-09-01 in the dbt view-coverage burn-down, when the view had NO dbt
-- presence at all and scripts/check_dbt_view_coverage.py reported it uncovered. Its canonical
-- source moved bigquery/63 -> bigquery/232 on 2026-09-09, when the `drift` term gained the
-- cadence-aware bootstrap grace its two sibling terms already had; regenerating from the new
-- canonical is what this file's 2026-09-09 change is.
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
  -- BOOTSTRAP GRACE (2026-09-09, bigquery/232): the `last_beat_ts >= updated_ts` conjunct. A version
  -- mismatch is only EVIDENCE of drift once the query has beaten at least once since the registry row
  -- was bumped; before that the reported version is stale by construction. Without it, bumping a
  -- MONTHLY query (interval 744h) raised this warning every night for the ~23 days until its next
  -- run -- and because the category is on cadence_check's #14 auto-age allowlist, that became a
  -- weekly raise/age/re-raise email cycle rather than one open row. Measured on the live board
  -- 2026-09-09: alert e0cb2898 for fire_drill_alert_lifecycle, registry v4 (2026-09-08 16:10:20),
  -- live procedure DDL v4, heartbeat v3 from 2026-09-01 -- nothing drifted, the query simply had not
  -- run yet. COALESCE guards a NULL updated_ts: without it the comparison would yield NULL and
  -- silently disable drift detection for that row, which is the failure this term must never have.
  -- The two sibling terms below already carry cadence-aware graces; this one did not, and that
  -- asymmetry -- not the grace value -- was the defect. See this file's header for the measurement
  -- showing all 11 other registered queries already satisfy this conjunct, so it costs no coverage.
  COALESCE(lb.ever_reported_version, FALSE)
    AND lb.last_beat_ts >= COALESCE(e.updated_ts, TIMESTAMP '1970-01-01 00:00:00 UTC')
    AND (lb.last_reported_version IS NULL
         OR TRIM(lb.last_reported_version) = ''
         OR lb.last_reported_version != e.expected_version) AS drift,
  -- MON H5 (2026-07-17) beat-AGE dead-man. GRACE_FACTOR = 1.5 (a daily query tolerates one missed run
  -- before flagging; weekly ~10.5d; monthly ~46d — the monthly restore_drill is additionally covered by
  -- restore_stale's own >40d critical, so a generous grace here just avoids false fires on the backstop).
  -- CORRECTED 2026-09-30 (bigquery/249; comment-only, no code change): the "a daily query tolerates one
  -- missed run" clause above is FALSE for the daily queries. ops.sp_sq_cadence_check runs at 05:15 UTC,
  -- BEFORE the 05:25-05:40 beats of the daily queries, so at 05:15 a daily query's newest beat is
  -- yesterday's, and a SINGLE skipped daily run is seen at ~47.75h old at the next 05:15 pass -- past the
  -- 36h limit (24h x 1.5) -- and DOES raise the next morning (backup_events_export, 2026-09-29 run skipped,
  -- alert 715b5439 raised 2026-09-30 05:17). That is intended and unchanged: one missed backup SHOULD
  -- warn. Only this sentence was wrong. The weekly/monthly figures are unaffected.
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

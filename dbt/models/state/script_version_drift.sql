-- Parallel-run dbt port of bigquery/43_script_version_registry.sql:state.script_version_drift — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH latest_beat AS (
  SELECT
    source AS script_name,
    ARRAY_AGG(beat_ts ORDER BY beat_ts DESC LIMIT 1)[SAFE_OFFSET(0)] AS last_beat_ts,
    -- BUG FIX (rev 2026-07-11, adversarial self-audit): this MUST NOT use IGNORE NULLS. The point of
    -- last_reported_version is "what did the MOST RECENT beat actually report" -- if that beat's own
    -- version is NULL (a regression: a broken/partial re-paste, or the SCRIPT_VERSION const dropped),
    -- IGNORE NULLS would silently fall back to an OLDER beat's non-NULL version instead, masking the
    -- exact regression this view exists to catch and directly contradicting the header's own documented
    -- fail-closed guarantee ("a later beat that regresses to NULL/blank... is drift=TRUE, never silently
    -- ignored"). Without IGNORE NULLS, ARRAY_AGG's default NULL-inclusive behavior correctly surfaces a
    -- NULL here when the latest beat's version genuinely is NULL.
    ARRAY_AGG(version ORDER BY beat_ts DESC LIMIT 1)[SAFE_OFFSET(0)] AS last_reported_version,
    -- has this source EVER reported a non-blank version (arms monitoring independent of the latest beat)
    LOGICAL_OR(version IS NOT NULL AND TRIM(version) != '') AS ever_reported_version
  FROM {{ source('ops', 'heartbeat') }}
  GROUP BY source
)
SELECT
  e.script_name,
  e.expected_version,
  lb.last_reported_version,
  lb.last_beat_ts,
  COALESCE(lb.ever_reported_version, FALSE) AS monitored,
  COALESCE(lb.ever_reported_version, FALSE)
    AND (lb.last_reported_version IS NULL
         OR TRIM(lb.last_reported_version) = ''
         OR lb.last_reported_version != e.expected_version) AS drift,
  CURRENT_TIMESTAMP() AS checked_at
FROM {{ source('state_external', 'expected_script_versions') }} e
LEFT JOIN latest_beat lb ON lb.script_name = e.script_name

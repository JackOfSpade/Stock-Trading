-- Parallel-run dbt port of bigquery/20_user_prefs.sql:state.user_tz — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
SELECT
  COALESCE(
    (SELECT pref_value FROM {{ source('ops', 'user_prefs') }}
     WHERE pref_key = 'display_tz'
     ORDER BY updated_ts DESC LIMIT 1),
    'America/Denver'
  ) AS tz,
  (SELECT MAX(updated_ts) FROM {{ source('ops', 'user_prefs') }} WHERE pref_key = 'display_tz') AS detected_ts

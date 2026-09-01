-- Parallel-run dbt port of bigquery/37_self_improvement_autonomy.sql:state.active_playbook — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
SELECT playbook_key, delta_text, update_ts, theater_review_id, independent_sessions, git_commit
FROM {{ source('events', 'playbook_updates') }}
QUALIFY ROW_NUMBER() OVER (PARTITION BY playbook_key ORDER BY update_ts DESC) = 1

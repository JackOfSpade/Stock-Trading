-- Parallel-run dbt port of bigquery/14_weekly_report.sql:state.account_nav_7d_ago — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
SELECT nav, snapshot_date
FROM {{ source('ops', 'account_snapshot') }}
QUALIFY ROW_NUMBER() OVER (
  ORDER BY ABS(DATE_DIFF(snapshot_date,
    DATE_SUB((SELECT MAX(snapshot_date) FROM {{ source('ops', 'account_snapshot') }}), INTERVAL 7 DAY),
    DAY)),
    snapshot_date DESC
) = 1

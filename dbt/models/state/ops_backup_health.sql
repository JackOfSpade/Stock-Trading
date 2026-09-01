-- Parallel-run dbt port of bigquery/16_automation_health.sql:state.ops_backup_health — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH b AS (
  SELECT MAX(run_date) AS last_backup_date, MAX(backup_ts) AS last_backup_ts
  FROM {{ source('ops', 'backup_log') }}
  WHERE COALESCE(dataset, 'events') = 'ops'
),
td AS (SELECT today FROM {{ ref('trading_day_today') }})
SELECT
  b.last_backup_date,
  b.last_backup_ts,
  td.today,
  (b.last_backup_date IS NOT NULL) AS monitored,
  COALESCE(b.last_backup_date IS NOT NULL
           AND b.last_backup_date < DATE_SUB(td.today, INTERVAL 2 DAY), FALSE) AS stale,
  CURRENT_TIMESTAMP() AS checked_at
FROM b, td

-- Parallel-run dbt port of bigquery/17_restore_drill.sql:state.restore_health — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
WITH latest AS (
  SELECT drill_date, drill_ts, all_passed, fidelity_ok
  FROM {{ source('ops', 'drill_log') }}
  QUALIFY ROW_NUMBER() OVER (ORDER BY drill_ts DESC) = 1
),
-- Aggregate the (0-or-1-row) latest into a guaranteed single row (NULLs when no drill has logged),
-- mirroring state.backup_health — robust without relying on FULL JOIN semantics.
d AS (
  SELECT MAX(drill_date) AS last_drill_date, MAX(drill_ts) AS last_drill_ts,
         ANY_VALUE(all_passed) AS last_drill_passed, ANY_VALUE(fidelity_ok) AS last_drill_fidelity_ok
  FROM latest
),
td AS (SELECT today FROM {{ ref('trading_day_today') }})
SELECT
  d.last_drill_date,
  d.last_drill_ts,
  d.last_drill_passed,
  d.last_drill_fidelity_ok,
  td.today,
  (d.last_drill_date IS NOT NULL) AS monitored,
  COALESCE(d.last_drill_date IS NOT NULL
           AND (d.last_drill_date < DATE_SUB(td.today, INTERVAL 40 DAY) OR NOT d.last_drill_passed), FALSE) AS stale,
  CURRENT_TIMESTAMP() AS checked_at
FROM d, td

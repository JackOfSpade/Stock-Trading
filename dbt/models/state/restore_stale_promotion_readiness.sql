-- Parallel-run dbt port of bigquery/45_monitor_promotion.sql:state.restore_stale_promotion_readiness — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
WITH rh AS (SELECT monitored, last_drill_passed, last_drill_date FROM {{ ref('restore_health') }})
SELECT
  rh.monitored, rh.last_drill_passed, rh.last_drill_date,
  NOT EXISTS (SELECT 1 FROM {{ source('ops', 'monitor_promotion_log') }} pl WHERE pl.check_id = 'restore_stale') AS not_already_promoted,
  (COALESCE(rh.monitored, FALSE) AND COALESCE(rh.last_drill_passed, FALSE)
   AND NOT EXISTS (SELECT 1 FROM {{ source('ops', 'monitor_promotion_log') }} pl WHERE pl.check_id = 'restore_stale')) AS ready
FROM rh

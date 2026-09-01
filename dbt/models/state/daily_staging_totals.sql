-- Parallel-run dbt port of bigquery/109_retire_daily_staging_cap.sql:state.daily_staging_totals — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH today_staged AS (
  SELECT
    item_key,
    CAST(JSON_VALUE(payload, '$.qty') AS NUMERIC) * CAST(JSON_VALUE(payload, '$.limit_price') AS NUMERIC) AS notional
  FROM {{ source('events', 'queue_events') }}
  WHERE queue = 'ORDER_STAGED'
    AND DATE(event_ts, 'America/Denver') = CURRENT_DATE('America/Denver')
  QUALIFY ROW_NUMBER() OVER (PARTITION BY item_key ORDER BY event_ts DESC) = 1
)
SELECT
  (SELECT COUNT(DISTINCT item_key) FROM today_staged) AS orders_staged_today,
  (SELECT ROUND(SUM(notional), 2) FROM today_staged) AS notional_staged_today

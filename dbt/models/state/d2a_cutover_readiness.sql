-- Parallel-run dbt port of bigquery/32_d2a_cutover_readiness.sql:state.d2a_cutover_readiness — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
WITH qualifying AS (
  SELECT DISTINCT r.run_date
  FROM {{ source('ops', 'run_log') }} r
  JOIN {{ ref('market_calendar') }} c
    ON c.cal_date = r.run_date AND c.is_trading_day
  WHERE r.routine = 'D2a' AND r.status = 'completed'
)
SELECT
  (SELECT COUNT(*) FROM qualifying) AS qualifying_trading_day_runs,
  NOT EXISTS(SELECT 1 FROM {{ source('ops', 'd2a_cutover_log') }}) AS cutover_still_pending,
  (SELECT COUNT(*) FROM qualifying) >= 3
    AND NOT EXISTS(SELECT 1 FROM {{ source('ops', 'd2a_cutover_log') }}) AS ready_for_cutover

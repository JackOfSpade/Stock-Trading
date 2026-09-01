-- Parallel-run dbt port of bigquery/203_web_call_provider_normalise.sql:state.fmp_daily_budget — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH fmp AS (
  SELECT run_date, COUNT(*) AS logged_fmp_requests
  FROM {{ source('ops', 'web_calls') }}
  WHERE LOWER(TRIM(provider)) = 'fmp'
    AND run_date >= DATE_SUB(CURRENT_DATE("America/Denver"), INTERVAL 45 DAY)
  GROUP BY run_date
),
fanout AS (
  SELECT run_date, COUNT(DISTINCT routine) AS fan_out_routines_completed
  FROM {{ source('ops', 'run_log') }}
  WHERE status = 'completed'
    AND routine IN ('D1','W1','M2','Q2','A1')
    AND run_date >= DATE_SUB(CURRENT_DATE("America/Denver"), INTERVAL 45 DAY)
  GROUP BY run_date
)
SELECT
  run_date,
  COALESCE(f.logged_fmp_requests, 0) AS logged_fmp_requests,
  250 AS daily_cap,
  ROUND(COALESCE(f.logged_fmp_requests, 0) / 250 * 100, 1) AS pct_consumed,
  COALESCE(fo.fan_out_routines_completed, 0) AS fan_out_routines_completed,
  COALESCE(fo.fan_out_routines_completed, 0) > 1 AS fan_out_day,
  CURRENT_TIMESTAMP() AS checked_at
FROM fmp f
FULL OUTER JOIN fanout fo USING (run_date)

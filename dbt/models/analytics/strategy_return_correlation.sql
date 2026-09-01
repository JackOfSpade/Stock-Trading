-- Parallel-run dbt port of bigquery/83_correlation_controls.sql:analytics.strategy_return_correlation — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH r AS (
  SELECT strategy, as_of_date, r_deployed
  FROM {{ ref('strategy_daily_returns') }}
  WHERE as_of_date >= DATE_SUB(CURRENT_DATE('America/New_York'), INTERVAL 90 DAY)
    AND r_deployed IS NOT NULL
)
SELECT a.strategy AS strategy_a, b.strategy AS strategy_b,
       CORR(a.r_deployed, b.r_deployed) AS corr,
       COUNT(*) AS overlap_days
FROM r a JOIN r b ON a.as_of_date = b.as_of_date AND a.strategy < b.strategy
GROUP BY a.strategy, b.strategy

-- Parallel-run dbt port of bigquery/39_beta_adjusted_alpha.sql:analytics.spy_daily_return — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH s AS (
  SELECT mark_date, close, COALESCE(dividend, 0) AS dividend,
         LAG(close) OVER (ORDER BY mark_date) AS prev_close
  FROM {{ ref('daily_marks_curated') }}
  WHERE ticker = 'SPY'
)
SELECT mark_date AS as_of_date, SAFE_DIVIDE(close + dividend - prev_close, prev_close) AS r_spy
FROM s WHERE prev_close IS NOT NULL

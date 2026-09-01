-- Parallel-run dbt port of bigquery/203_web_call_provider_normalise.sql:state.web_spend_month — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH normalised AS (
  -- Provider vocabulary folded here, ONCE, so every downstream term in this view agrees on what a
  -- provider IS (bigquery/203). Case-only variants and `huggingface` collapse onto the canonical
  -- token; anything else passes through lowercased and stays visible as its own row.
  SELECT
    run_date,
    routine,
    session_id,
    depth,
    credits,
    credits_reported,
    CASE
      WHEN LOWER(TRIM(provider)) = 'huggingface' THEN 'hf'
      ELSE LOWER(TRIM(provider))
    END AS provider
  FROM {{ source('ops', 'web_calls') }}
  WHERE run_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 180 DAY)
),
per_cell AS (
  SELECT
    DATE_TRUNC(run_date, MONTH)                       AS month_start,
    provider,
    routine,
    COUNT(*)                                          AS n_calls,
    COUNT(DISTINCT session_id)                        AS run_covered,
    SUM(credits)                                      AS credits,
    COUNTIF(credits_reported)                         AS n_calls_provider_reported,
    COUNTIF(provider = 'tavily' AND LOWER(TRIM(depth)) IN ('advanced', 'pro')) AS n_priced_upgrade
  FROM normalised
  GROUP BY month_start, provider, routine
),
-- Terminal rows only: ops.run_log writes a paired started + terminal row per run, so counting every
-- row would double the denominator and make coverage look half as complete as it is.
runs AS (
  SELECT
    DATE_TRUNC(run_date, MONTH) AS month_start,
    routine,
    COUNT(*)                    AS runs_in_month
  FROM {{ source('ops', 'run_log') }}
  WHERE run_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 180 DAY)
    AND status IN ('completed', 'failed', 'halted')
  GROUP BY month_start, routine
)
SELECT
  c.month_start,
  c.provider,
  c.routine,
  c.n_calls,
  c.credits,
  c.n_calls_provider_reported,
  c.n_priced_upgrade,
  c.run_covered,
  r.runs_in_month,
  c.run_covered < r.runs_in_month AS has_unreported_runs
FROM per_cell c
LEFT JOIN runs r
  ON r.month_start = c.month_start AND r.routine = c.routine
ORDER BY c.month_start DESC, c.provider, c.credits DESC

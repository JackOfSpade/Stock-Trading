-- Parallel-run dbt port of bigquery/203_web_call_provider_normalise.sql:state.web_duplicate_targets — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH normalised AS (
  SELECT
    CASE
      WHEN LOWER(TRIM(provider)) = 'huggingface' THEN 'hf'
      ELSE LOWER(TRIM(provider))
    END AS provider,
    tool,
    routine,
    run_date,
    credits,
    target,
    CASE
      WHEN REGEXP_CONTAINS(LOWER(TRIM(target)), r'^https?://') THEN
        -- URL: drop scheme, leading www., the entire query string, and any trailing slash.
        REGEXP_REPLACE(
          REGEXP_REPLACE(
            REGEXP_REPLACE(LOWER(TRIM(target)), r'^https?://(www\.)?', ''),
            r'\?.*$', ''),
          r'/+$', '')
      ELSE
        -- Free-text query: collapse internal whitespace so trivial spacing differences do not
        -- masquerade as distinct questions.
        REGEXP_REPLACE(LOWER(TRIM(target)), r'\s+', ' ')
    END AS target_norm
  FROM {{ source('ops', 'web_calls') }}
  WHERE run_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 90 DAY)
    AND target IS NOT NULL
    AND TRIM(target) != ''
)
SELECT
  provider,
  target_norm,
  COUNT(*)                                   AS n_fetches,
  COUNT(DISTINCT routine)                    AS n_routines,
  COUNT(DISTINCT run_date)                   AS n_distinct_days,
  ARRAY_AGG(DISTINCT routine ORDER BY routine) AS routines,
  ARRAY_AGG(DISTINCT tool ORDER BY tool)     AS tools,
  MIN(run_date)                              AS first_fetched,
  MAX(run_date)                              AS last_fetched,
  SUM(credits)                               AS credits_total,
  -- Credits attributable to the REPEATS only: everything past the first fetch. This is the
  -- recoverable number -- the first fetch was never waste. The per-fetch average divides by the
  -- count of rows that actually CARRY a credit figure, not by COUNT(*): a row with NULL credits
  -- contributes nothing to SUM, so dividing by COUNT(*) would understate the average and thus
  -- overstate the recoverable amount. SAFE_DIVIDE covers the all-NULL case.
  SUM(credits) - SAFE_DIVIDE(SUM(credits), COUNTIF(credits IS NOT NULL)) AS credits_on_repeats,
  COUNT(DISTINCT routine) > 1                AS is_cross_routine
FROM normalised
GROUP BY provider, target_norm
HAVING COUNT(*) > 1
ORDER BY credits_on_repeats DESC, n_fetches DESC

-- Parallel-run dbt port of bigquery/201_instruction_drift_dash_normalize.sql:state.instruction_drift — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH li AS (
  SELECT routine, instruction, run_date
  FROM {{ ref('routine_last_instruction') }}
  -- collapse id-separator-punctuation variants of the SAME routine to its most recent run
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY REGEXP_REPLACE(routine, r'[·._-]', '')
    ORDER BY run_date DESC, log_ts DESC) = 1
),
j AS (
  SELECT
    COALESCE(c.routine, li.routine) AS routine,
    c.canonical_instruction,
    li.instruction AS live_instruction,
    li.run_date    AS live_last_seen,
    c.canonical_since,
    -- Whitespace-normalized PREFIX match (bigquery/115) PLUS em/en-dash folding (bigquery/201).
    -- Order of normalization: first fold em/en-dashes (—, –) to ASCII hyphens, then collapse
    -- whitespace. Normalizing BOTH sides keeps the comparison symmetric. A trailing operator
    -- addendum still passes; wrong routine number / heading / type-tag / truncation / prepended
    -- text still fails.
    (c.routine IS NOT NULL AND li.instruction IS NOT NULL
       AND NOT STARTS_WITH(
             TRIM(REGEXP_REPLACE(REGEXP_REPLACE(li.instruction, r'[—–]', '-'), r'\s+', ' ')),
             TRIM(REGEXP_REPLACE(REGEXP_REPLACE(c.canonical_instruction, r'[—–]', '-'), r'\s+', ' ')))) AS text_mismatch,
    -- Staleness gate from bigquery/183: a sample logged no later than canonical_since cannot be
    -- evidence about the CURRENT live trigger in either direction.
    (c.canonical_since IS NOT NULL AND li.run_date IS NOT NULL
       AND li.run_date <= c.canonical_since) AS sample_predates_canonical,
    (c.routine IS NULL) AS unknown_routine
  FROM {{ source('ops', 'routine_catalog') }} c
  FULL OUTER JOIN li
    ON REGEXP_REPLACE(li.routine, r'[·._-]', '') = REGEXP_REPLACE(c.routine, r'[·._-]', '')
)
SELECT
  routine,
  canonical_instruction,
  live_instruction,
  live_last_seen,
  canonical_since,
  sample_predates_canonical,
  -- PROVEN drift: the texts differ AND the sample is new enough to be evidence about the live
  -- trigger. This is the ONLY column the cadence_check raise site reads.
  (text_mismatch AND NOT sample_predates_canonical) AS drifted,
  -- Texts differ but the sample predates the canonical change — reported, never raised.
  (text_mismatch AND sample_predates_canonical) AS drift_unproven,
  unknown_routine,
  CURRENT_TIMESTAMP() AS checked_at
FROM j

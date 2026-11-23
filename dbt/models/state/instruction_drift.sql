-- Parallel-run dbt port of bigquery/280_instruction_drift_full_text.sql:state.instruction_drift — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
-- Provenance (hand-kept): port added 2026-09-01 (dbt view-coverage burn-down) from
-- bigquery/201; REPOINTED to bigquery/280 on 2026-11-23 when that file superseded the view with the
-- full-text comparison (adds ref('routine_canonical_full_instruction') and source('ops', 'run_log')).
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
    -- CORE-LINE CHECK, unchanged from bigquery/201: whitespace-normalized PREFIX match (bigquery/115)
    -- plus em/en-dash folding. A trailing addendum passes; wrong routine number / heading / type-tag /
    -- truncation / prepended text fails.
    (c.routine IS NOT NULL AND li.instruction IS NOT NULL
       AND NOT STARTS_WITH(
             TRIM(REGEXP_REPLACE(REGEXP_REPLACE(li.instruction, r'[—–]', '-'), r'\s+', ' ')),
             TRIM(REGEXP_REPLACE(REGEXP_REPLACE(c.canonical_instruction, r'[—–]', '-'), r'\s+', ' ')))) AS text_mismatch,
    -- Staleness gate from bigquery/183, unchanged.
    (c.canonical_since IS NOT NULL AND li.run_date IS NOT NULL
       AND li.run_date <= c.canonical_since) AS sample_predates_canonical,
    (c.routine IS NULL) AS unknown_routine,
    -- FULL-TEXT CHECK inputs (bigquery/280). The core check's dash + whitespace normalization, plus
    -- QUOTE FOLDING (' " ` and the curly quotes dropped): agents must escape the canonical's apostrophes
    -- ("run's", "routine's") inside the sp_routine_start SQL literal, and dropping one is the obvious
    -- workaround — a transcription slip, not a trigger difference.
    REGEXP_REPLACE(COALESCE(c.routine, li.routine), r'[·._-]', '') AS rkey,
    f.canonical_full_since,
    TRIM(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(li.instruction, r'[—–]', '-'),
      r'[\x{27}\x{22}\x{60}\x{2018}\x{2019}\x{201C}\x{201D}]', ''), r'\s+', ' ')) AS live_cmp,
    TRIM(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(f.canonical_full_instruction, r'[—–]', '-'),
      r'[\x{27}\x{22}\x{60}\x{2018}\x{2019}\x{201C}\x{201D}]', ''), r'\s+', ' ')) AS full_cmp,
    TRIM(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(f.superseded_full_instruction, r'[—–]', '-'),
      r'[\x{27}\x{22}\x{60}\x{2018}\x{2019}\x{201C}\x{201D}]', ''), r'\s+', ' ')) AS sup_cmp
  FROM {{ source('ops', 'routine_catalog') }} c
  FULL OUTER JOIN li
    ON REGEXP_REPLACE(li.routine, r'[·._-]', '') = REGEXP_REPLACE(c.routine, r'[·._-]', '')
  LEFT JOIN {{ ref('routine_canonical_full_instruction') }} f
    ON REGEXP_REPLACE(f.routine, r'[·._-]', '') = REGEXP_REPLACE(COALESCE(c.routine, li.routine), r'[·._-]', '')
),
-- CORROBORATION: how many logged trigger samples (same filter as state.routine_last_instruction) dated
-- AFTER canonical_full_since carry exactly the newest sample's folded text. A stale live trigger is
-- transcribed identically run after run; a one-off transcription slip is not.
corr AS (
  SELECT j.rkey, COUNT(*) AS n_identical_since
  FROM j
  JOIN {{ source('ops', 'run_log') }} r
    ON REGEXP_REPLACE(r.routine, r'[·._-]', '') = j.rkey
   AND r.run_date > j.canonical_full_since
   AND r.instruction IS NOT NULL
   AND r.instruction LIKE 'Read Claude_Task_Plan.md. Perform %'
   AND TRIM(REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(r.instruction, r'[—–]', '-'),
         r'[\x{27}\x{22}\x{60}\x{2018}\x{2019}\x{201C}\x{201D}]', ''), r'\s+', ' ')) = j.live_cmp
  WHERE j.live_cmp IS NOT NULL AND j.full_cmp IS NOT NULL AND j.live_cmp != j.full_cmp
  GROUP BY j.rkey
),
k AS (
  SELECT
    j.*,
    COALESCE(corr.n_identical_since, 0) AS n_identical_since,
    -- The newest sample IS the text this routine's canonical replaced: proof of an un-rolled-out trigger
    -- at any length.
    COALESCE(sup_cmp IS NOT NULL AND live_cmp = sup_cmp, FALSE) AS matches_superseded_full,
    -- Is the sample evidence about the full text: the superseded text exactly, or a COMPLETE
    -- transcription (shape (b) in the header) rather than core-only (a) or a placeholder summary (c)?
    -- The pattern is scripts/gen_routine_lists.py PLACEHOLDER_PATTERN, verbatim.
    COALESCE(
      full_cmp IS NOT NULL AND live_cmp IS NOT NULL
        AND ((sup_cmp IS NOT NULL AND live_cmp = sup_cmp)
             OR (LENGTH(live_cmp) >= 0.85 * LENGTH(full_cmp)
                 AND NOT REGEXP_CONTAINS(live_instruction, r'(?i)\[\s*(\.\.\.|…)|\[[^\]]*(paragraph|guard|omitted|truncated|elided|abridged|redacted|snip|per trigger|per stored|verbatim)[^\]]*\]'))),
      FALSE) AS full_text_evidence,
    -- Staleness gate for the full text: same `<=` boundary rule as sample_predates_canonical.
    COALESCE(canonical_full_since IS NOT NULL AND live_last_seen IS NOT NULL
               AND live_last_seen <= canonical_full_since, FALSE) AS full_sample_predates_canonical
  FROM j
  LEFT JOIN corr USING (rkey)
),
m AS (
  SELECT
    k.*,
    (full_text_evidence AND live_cmp != full_cmp) AS full_text_mismatch,
    (full_text_evidence AND live_cmp != full_cmp
       AND (matches_superseded_full OR n_identical_since >= 2)) AS full_text_corroborated
  FROM k
),
d AS (
  SELECT
    m.*,
    (text_mismatch AND NOT sample_predates_canonical) AS core_drift,
    (full_text_corroborated AND NOT full_sample_predates_canonical) AS full_drift
  FROM m
)
SELECT
  routine,
  canonical_instruction,
  live_instruction,
  live_last_seen,
  canonical_since,
  sample_predates_canonical,
  -- PROVEN drift: the core line differs on an evidential sample (bigquery/201, unchanged) OR the
  -- full text differs on a sample newer than canonical_full_since AND that difference is corroborated
  -- (equals the superseded canonical, or seen identically in >= 2 samples since canonical_full_since).
  -- This is the ONLY column the cadence_check raise site reads (with unknown_routine).
  (core_drift OR full_drift) AS drifted,
  -- A mismatch that is reported, never raised: the sample predates the relevant canonical change, or
  -- (full text only) the difference is not yet corroborated.
  (NOT (core_drift OR full_drift)
     AND ((text_mismatch AND sample_predates_canonical) OR full_text_mismatch)) AS drift_unproven,
  unknown_routine,
  CURRENT_TIMESTAMP() AS checked_at,
  -- Appended by bigquery/280 (after every column bigquery/201 published):
  full_text_evidence,
  full_text_mismatch,
  canonical_full_since,
  full_sample_predates_canonical,
  matches_superseded_full,
  full_text_corroborated
FROM d

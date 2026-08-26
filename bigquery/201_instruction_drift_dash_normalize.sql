-- ===== 201: state.instruction_drift — em/en-dash normalization =====
-- (2026-08-26, alert triage — alert b0b8113d-4e8c-4153-be69-0767cdecbc68.)
--
-- WHY. The live OPS0 trigger uses an em-dash (U+2014) in "Perform OPS0 — regular routine."
-- bigquery/183 (state.instruction_drift) applies a whitespace-normalized PREFIX match per
-- bigquery/115. The OPS0 run logged on 2026-08-25 transcribed the em-dash as an ASCII hyphen
-- ("Perform OPS0 - regular routine."), so STARTS_WITH failed and the alert fired.
--
-- This is the same root class as the 2026-07-29 newline-normalization fix (bigquery/115):
-- the live trigger is correct; a transcription artefact in ops.run_log.instruction is not
-- evidence of a real drift. The REJECTED_ALTERNATIVE note in bigquery/183's header documents
-- the prior rejection of dash-folding in a different context (ad-hoc title matching against a
-- then-canonical title-bearing format); the rejection there was about masking a title that was
-- the INTENTIONAL canonical form. Here, the em-dash IS the canonical form (the decoupled short
-- instructions use it universally), and folding it closes a class of false positives that the
-- 2026-08-17 decoupling commit INTRODUCED (every routine now says "— regular routine." or
-- "— deep research." with an em-dash, and a future transcription artefact on any routine can
-- trigger the same false alarm).
--
-- THE FIX: add a REGEXP_REPLACE(…, r'[—–]', '-') step to both sides BEFORE the whitespace
-- normalization. This is a normalization, not a masking fix:
--   * A wrong routine number/heading/type-tag/truncation/prepended text still fails.
--   * An em-dash vs ASCII hyphen in the canonical instruction no longer fires.
--   * The operator-addendum pass rule from bigquery/115 is preserved.
--   * The staleness gate from bigquery/183 is preserved.
--
-- SYNTHETIC NEGATIVE CONTROLS (confirmed BEFORE applying):
--   "Read Claude_Task_Plan.md. Perform OPS9 — regular routine."  → FAILS (wrong number)
--   "Read Claude_Task_Plan.md. Perform OPS0 - deep research."    → FAILS (wrong type-tag)
--   "Read Claude_Task_Plan.md. Perform OPS0."                    → FAILS (missing type)
--   "Perform OPS0 — regular routine."                            → FAILS (missing prefix)
--   "Read Claude_Task_Plan.md. Perform OPS0 — regular routine."  → PASSES (exact canonical)
--   "Read Claude_Task_Plan.md. Perform OPS0 - regular routine."  → PASSES (hyphen variant)
--   "Read Claude_Task_Plan.md. Perform OPS0 — regular routine.\n\nSpawn Sonnet…" → PASSES (addendum)
--   "Read Claude_Task_Plan.md. Perform OPS0 - regular routine. Spawn Sonnet…"    → PASSES (addendum)
--
-- SUPERSEDES `state.instruction_drift` in bigquery/183_instruction_drift_stale_sample.sql
-- (which itself superseded bigquery/115 and bigquery/15). Apply after bigquery/183.
-- Defines exactly one view; creates, redefines or drops nothing else.

CREATE OR REPLACE VIEW `stock-trading-498512.state.instruction_drift` AS
WITH li AS (
  SELECT routine, instruction, run_date
  FROM `stock-trading-498512.state.routine_last_instruction`
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
  FROM `stock-trading-498512.ops.routine_catalog` c
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
FROM j;

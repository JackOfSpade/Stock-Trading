-- Routine catalog + web-UI trigger drift detector (W2). Project: stock-trading-498512.
-- The schedule + trigger instruction for each routine live ONLY in the Claude-Code-on-Web UI —
-- unversioned, invisible, a silent single point of failure (a typo'd/edited trigger would point a
-- routine at the wrong section or pass the wrong instruction, and nothing would notice). This closes
-- the loop: ops.routine_catalog holds the CANONICAL instruction per routine (the exact string
-- scripts/print_routines.py reconstructs from Claude_Task_Plan.md + ops/cadence.yaml), and
-- state.instruction_drift diffs it against the LIVE trigger text each routine actually logged
-- (state.routine_last_instruction ← ops.run_log.instruction, set by ops.sp_routine_start).
-- cadence_check.sql raises an alert on any drift. Idempotent (OR REPLACE). Apply after 10/12.
--
-- KEEP IN SYNC: when a routine heading changes in Claude_Task_Plan.md, regenerate this seed from
-- `python scripts/print_routines.py` (the canonical_instruction is "Read Claude_Task_Plan.md.
-- Perform <heading>." verbatim) and re-apply. A mismatch here vs the live trigger is the alarm.

CREATE OR REPLACE TABLE `stock-trading-498512.ops.routine_catalog` AS
SELECT routine, canonical_instruction
FROM UNNEST([
-- Routine notes relocated here (ABOVE the generated region) by the ARCH-3 Item 30b normalization
-- (2026-07-16, scripts/gen_routine_lists.py --write) -- the generator does not preserve inline
-- comments between rows:
--   D2a (added 2026-07-03, self-improvement audit WO-3): NOT YET ACTIVE, no live web-UI trigger yet.
--   OPS0 (added 2026-07-15, self-improvement audit — CONFIRMED GAP catchup-notify-no-auto-refire):
--   NOT YET ACTIVE, no live web-UI trigger yet (owner action to create one; self-bootstrapping in the
--   meantime, same as D2a's precedent above).
--   The adversarial routines self-log under the abbreviated ids AR_att / AR_orc (ASCII,
--   standardized 2026-07-01 — RUNBOOK §28 — from the earlier non-ASCII middle-dot AR·att/AR·orc an
--   agent kept mis-transcribing). Same ids in the Claude_Task_Plan.md routine table + ops/cadence.yaml.
--   The separator-normalized join below folds the LEGACY middle-dot ops.run_log rows onto these keys,
--   so the historical partitions do NOT resurface as unknown_routine after the id switch.
--   SISA strategy-lifecycle routines (rev 2026-07-10 — Strategy Arsenal autonomy conversion, owner
--   directive). canonical_instruction MUST be byte-identical to the Claude_Task_Plan.md SL headings
--   that scripts/print_routines.py reconstructs (shape 'Read Claude_Task_Plan.md. Perform SL<n>. <name>
--   — <type>.') — coordinate with the Claude_Task_Plan.md routine-table edits (same names/em-dash/type
--   tag). All five register here (the catalog is id-keyed, not schedule-keyed) so instruction_drift
--   covers the queue-driven SL2/SL5 as well as SL1/SL3/SL4.
--
-- GENERATED (scripts/gen_routine_lists.py --write, ARCH-3 Item 30b, 2026-07-16) from ops/cadence.yaml
-- + Claude_Task_Plan.md headings: one row per routine (ALL 32, cadence.yaml file order), instruction
-- text derived from the matching plan heading exactly as check_cadence_consistency.py's check B
-- derives it. Do NOT hand-edit the marked region below -- edit ops/cadence.yaml / the plan heading and
-- re-run `python scripts/gen_routine_lists.py --write`. CI step `gen_routine_lists.py --check` verifies
-- this region is byte-current.
-- BEGIN GENERATED ROUTINE LIST (scripts/gen_routine_lists.py --write; do not hand-edit)
  STRUCT('D1' AS routine, 'Read Claude_Task_Plan.md. Perform D1 — deep research.' AS canonical_instruction),
  STRUCT('D2a' AS routine, 'Read Claude_Task_Plan.md. Perform D2a — regular routine.' AS canonical_instruction),
  STRUCT('D2' AS routine, 'Read Claude_Task_Plan.md. Perform D2 — regular routine.' AS canonical_instruction),
  STRUCT('D3' AS routine, 'Read Claude_Task_Plan.md. Perform D3 — regular routine.' AS canonical_instruction),
  STRUCT('OPS0' AS routine, 'Read Claude_Task_Plan.md. Perform OPS0 — regular routine.' AS canonical_instruction),
  STRUCT('OPS1' AS routine, 'Read Claude_Task_Plan.md. Perform OPS1 — regular routine.' AS canonical_instruction),
  STRUCT('OPS2' AS routine, 'Read Claude_Task_Plan.md. Perform OPS2 — regular routine.' AS canonical_instruction),
  STRUCT('SL3' AS routine, 'Read Claude_Task_Plan.md. Perform SL3 — regular routine.' AS canonical_instruction),
  STRUCT('AR_att' AS routine, 'Read Claude_Task_Plan.md. Perform Adversarial Review Attacker — regular routine.' AS canonical_instruction),
  STRUCT('AR_orc' AS routine, 'Read Claude_Task_Plan.md. Perform Adversarial Review Orchestrator — regular routine.' AS canonical_instruction),
  STRUCT('SL2' AS routine, 'Read Claude_Task_Plan.md. Perform SL2 — regular routine.' AS canonical_instruction),
  STRUCT('SL5' AS routine, 'Read Claude_Task_Plan.md. Perform SL5 — regular routine.' AS canonical_instruction),
  STRUCT('W1' AS routine, 'Read Claude_Task_Plan.md. Perform W1 — deep research.' AS canonical_instruction),
  STRUCT('W2' AS routine, 'Read Claude_Task_Plan.md. Perform W2 — deep research.' AS canonical_instruction),
  STRUCT('W3' AS routine, 'Read Claude_Task_Plan.md. Perform W3 — deep research.' AS canonical_instruction),
  STRUCT('W4' AS routine, 'Read Claude_Task_Plan.md. Perform W4 — regular routine.' AS canonical_instruction),
  STRUCT('W5' AS routine, 'Read Claude_Task_Plan.md. Perform W5 — regular routine.' AS canonical_instruction),
  STRUCT('M1a' AS routine, 'Read Claude_Task_Plan.md. Perform M1a — deep research.' AS canonical_instruction),
  STRUCT('M1b' AS routine, 'Read Claude_Task_Plan.md. Perform M1b — regular routine.' AS canonical_instruction),
  STRUCT('M2' AS routine, 'Read Claude_Task_Plan.md. Perform M2 — deep research.' AS canonical_instruction),
  STRUCT('M3' AS routine, 'Read Claude_Task_Plan.md. Perform M3 — deep research.' AS canonical_instruction),
  STRUCT('M4' AS routine, 'Read Claude_Task_Plan.md. Perform M4 — regular routine.' AS canonical_instruction),
  STRUCT('M5' AS routine, 'Read Claude_Task_Plan.md. Perform M5 — regular routine.' AS canonical_instruction),
  STRUCT('SL4' AS routine, 'Read Claude_Task_Plan.md. Perform SL4 — regular routine.' AS canonical_instruction),
  STRUCT('Q1' AS routine, 'Read Claude_Task_Plan.md. Perform Q1 — deep research.' AS canonical_instruction),
  STRUCT('Q2' AS routine, 'Read Claude_Task_Plan.md. Perform Q2 — deep research.' AS canonical_instruction),
  STRUCT('Q3' AS routine, 'Read Claude_Task_Plan.md. Perform Q3 — deep research.' AS canonical_instruction),
  STRUCT('Q4' AS routine, 'Read Claude_Task_Plan.md. Perform Q4 — regular routine.' AS canonical_instruction),
  STRUCT('SL1' AS routine, 'Read Claude_Task_Plan.md. Perform SL1 — deep research.' AS canonical_instruction),
  STRUCT('A1' AS routine, 'Read Claude_Task_Plan.md. Perform A1 — deep research.' AS canonical_instruction),
  STRUCT('A2' AS routine, 'Read Claude_Task_Plan.md. Perform A2 — deep research.' AS canonical_instruction),
  STRUCT('A3' AS routine, 'Read Claude_Task_Plan.md. Perform A3 — regular routine.' AS canonical_instruction)
  -- END GENERATED ROUTINE LIST
]);

-- state.instruction_drift — canonical vs live trigger text per routine.
-- drifted = the routine HAS logged a trigger instruction (so it is live/monitored) AND that live
-- text differs from the canonical. A routine that has never logged (live_instruction NULL) is NOT
-- drifted — same self-bootstrapping philosophy as state.cadence_watch (no false alarms on routines
-- that haven't adopted run-logging yet). unknown_routine flags a logged routine absent from the
-- catalog (a new/renamed routine the catalog hasn't been regenerated for).
-- NOTE (2026-06-22, RUNBOOK §22): "live" comes from state.routine_last_instruction, which since the W5
-- false-alarm only counts instructions of the canonical `Read Claude_Task_Plan.md. Perform …` trigger
-- shape — so an ad-hoc/one-off session that reuses a routine id and logs a free-form task note no longer
-- shadows the real trigger and false-trips this view. A real typo'd/edited trigger still drifts here.
-- ID-SEPARATOR NORMALIZATION (2026-06-30, RUNBOOK §28): the catalog↔live join matches on a separator-
-- NORMALIZED id, so a routine logged with a different id PUNCTUATION than its catalog key is treated as
-- the SAME routine rather than a spurious unknown_routine. Motivating case: the adversarial routines were
-- keyed under a non-ASCII middle dot — `AR·att`/`AR·orc` (U+00B7) — that a session had to hand-transcribe
-- from the Claude_Task_Plan.md routine table into ops.sp_routine_start; on 2026-06-29 the AR Attacker run
-- logged `AR_att` (ASCII underscore) instead — identical, correct instruction text, just the separator
-- swapped. On 2026-07-01 the canonical ids were STANDARDIZED to ASCII `AR_att`/`AR_orc` (RUNBOOK §28
-- follow-up) to remove that fragility at the source; this normalization is KEPT to (1) fold the LEGACY
-- middle-dot ops.run_log rows (2026-06-20…28) onto the new ASCII keys so the historical partitions do not
-- resurface as unknown_routine after the switch, and (2) guard against any future punctuation slip. Because
-- state.routine_last_instruction keeps the all-time-latest row PER DISTINCT id (no window), an un-normalized
-- stray partition would otherwise flag unknown_routine FOREVER and re-fire the warning every day (it does
-- not self-heal). REGEXP_REPLACE(id, r'[·._-]', '') maps the separator set so
-- `AR·att`/`AR_att`/`AR.att`/`AR-att` all collapse to one key (verified: real ids D1/W5/M1a/… are
-- separator-free and unaffected — no collisions). This narrowly suppresses the COSMETIC id-punctuation
-- false positive ONLY: the instruction-TEXT drift check below (drifted = live text != canonical text) is
-- UNCHANGED, so a genuinely wrong heading/number/type-tag still drifts, and a genuinely new/renamed
-- routine (different alphanumeric stem) still flags unknown_routine. The live side is re-deduped to one
-- row per normalized key (latest run) so a routine that logged under two spellings shows a single current
-- row reported under its canonical (catalog) id. Durable root-cause discussion + alternatives: RUNBOOK §28.
-- ADDENDUM-INVARIANT FIRST-LINE COMPARISON (2026-07-20, wording updated 2026-07-26 -- owner switched the
-- addendum's model references from Fable 5 to Opus 5, and the routines' own `model` field to
-- claude-opus-5): the live web-UI trigger message is now ALWAYS the canonical heading line PLUS a standing
-- operator addendum (as of 2026-07-26: "Spawn Sonnet 5 model sub-agents to do the grunt work. Save your
-- processing (Opus 5) for design/analysis/orchestration work only."), separated from the heading by a
-- blank line. sp_routine_start logs that FULL
-- verbatim text by design (bigquery/10_observability.sql: "captures the verbatim trigger text"), so once
-- a routine's live trigger carries the addendum its live_instruction differs from ops.routine_catalog's
-- single-line canonical_instruction PERMANENTLY -- not a one-time drift, a standing false positive.
-- Confirmed empirically 2026-07-19/20 (scheduled.cadence/instruction_drift, OPS0/W1/W2): those three
-- fired only because their MOST RECENT logged run happened to carry the addendum; W4/W5's ops.run_log
-- shows the identical addendum on an OLDER row that a later, addendum-free run superseded, so they read
-- clean today by accident of ordering, not because they're structurally different -- this population
-- rotates through whichever routine was most recently triggered and will keep growing as the operator
-- appends the same boilerplate to every trigger in turn (OPS1's first-ever log, 2026-07-20, has no
-- addendum yet -- it is simply next in line, not exempt). The addendum carries ZERO routing information
-- (a delegation/model-selection instruction to the session, not a "what to do" instruction), so it is not
-- part of what this detector exists to catch (file header above: "a typo'd/edited trigger would point a
-- routine at the wrong section or pass the wrong instruction").
-- FIX: compare only the FIRST LINE of live_instruction (REGEXP_EXTRACT(..., r'^[^\n]*')) against
-- canonical_instruction -- canonical_instruction is always a single line and the addendum is always
-- separated from the heading by an actual blank-line newline, never just extra whitespace. live_instruction
-- itself (the payload column consumed by bigquery/75_scheduled_query_wrappers.sql's alert message) is left
-- as the full raw verbatim text -- only the EQUALITY CHECK is narrowed, so a real alert's payload still
-- shows the operator the complete live trigger for diagnosis.
-- Alternatives considered and rejected:
--   (a) store the addendum in ops.routine_catalog and compare full text -- brittle: the addendum is
--       operator-owned free text with no versioning of its own, changes independently of the routine
--       roster, and re-diverging it from the catalog every time the operator edits boilerplate is exactly
--       the class of silent-drift risk this detector exists to prevent, not something to absorb into it.
--   (b) normalize whitespace only (trim/collapse spaces) -- insufficient: the addendum is ~30 words of
--       additional sentence content, not whitespace; no amount of whitespace normalization removes it.
--   (c) prefix-match (live_instruction STARTS WITH canonical_instruction) -- weaker than first-line
--       comparison: it would also silently accept a heading with a typo'd/truncated tail concatenated
--       straight onto the canonical text with NO separating newline, as long as the canonical prefix
--       matched. First-line-via-newline still requires an EXACT, complete match of everything up to the
--       first newline, so a truncated or run-on heading (no blank line inserted) still fails it --
--       empirically real: the 2026-06-28 W5 row logged `...Factbase & Analytics Consolidation` with the
--       ` — regular routine.` suffix dropped and no addendum at all (RUNBOOK §22/§30); first-line
--       comparison still flags that, and a synthetic wrong-routine-number / wrong-type-tag / truncated
--       instruction was verified (read-only, 2026-07-20) to still drift under this fix.
-- This does NOT touch unknown_routine (a routine absent from the catalog still flags regardless of its
-- instruction text) and does NOT weaken the type-suffix check RUNBOOK §22 explicitly protects (the
-- ` — deep research.` / ` — regular routine.` tag is INSIDE the first line, still compared verbatim).
-- SUPERSEDED LIVE by bigquery/115_instruction_drift_whitespace_normalize.sql (2026-07-29) — current
-- single source of truth for this VIEW. 115 replaces the first-line-only equality below with a
-- WHITESPACE-NORMALIZED PREFIX match: this check reads ops.run_log.instruction (what the routine
-- transcribed), not the live trigger, so a session that copied its trigger with the newlines collapsed
-- to a space produced a single-line instruction and false-fired `trigger_drift` against a CORRECT
-- trigger (SL3, 2026-07-28 — live trigger verified right via RemoteTrigger get). Wrong routine number /
-- heading / type-tag / truncation / prepended text are all still caught. This file's ops.routine_catalog
-- TABLE and its generated STRUCT rows are UNCHANGED and remain canonical here. Kept below, unmodified,
-- for DR-rebuild apply-in-order reference only. DO NOT re-apply this CREATE VIEW statement live in
-- isolation.
CREATE OR REPLACE VIEW `stock-trading-498512.state.instruction_drift` AS
WITH li AS (
  SELECT routine, instruction, run_date
  FROM `stock-trading-498512.state.routine_last_instruction`
  -- collapse id-separator-punctuation variants of the SAME routine to its most recent run
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY REGEXP_REPLACE(routine, r'[·._-]', '')
    ORDER BY run_date DESC, log_ts DESC) = 1
)
SELECT
  COALESCE(c.routine, li.routine) AS routine,
  c.canonical_instruction,
  li.instruction AS live_instruction,
  li.run_date    AS live_last_seen,
  (c.routine IS NOT NULL AND li.instruction IS NOT NULL
     -- first-line-only equality (2026-07-20, see comment block above) -- everything up to the first
     -- newline, which excludes the operator's standing post-heading addendum but still requires an
     -- exact match of the routine number / heading text / type-tag.
     AND REGEXP_EXTRACT(li.instruction, r'^[^\n]*') != c.canonical_instruction) AS drifted,
  (c.routine IS NULL) AS unknown_routine,
  CURRENT_TIMESTAMP() AS checked_at
FROM `stock-trading-498512.ops.routine_catalog` c
FULL OUTER JOIN li
  ON REGEXP_REPLACE(li.routine, r'[·._-]', '') = REGEXP_REPLACE(c.routine, r'[·._-]', '');

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
  STRUCT('D1'  AS routine, 'Read Claude_Task_Plan.md. Perform D1. Market Development Scan — deep research.' AS canonical_instruction),
  STRUCT('D2',  'Read Claude_Task_Plan.md. Perform D2. Daily Action Conversion — regular routine.'),
  STRUCT('D3',  'Read Claude_Task_Plan.md. Perform D3. Calendar Hygiene — regular routine.'),
  STRUCT('W1',  'Read Claude_Task_Plan.md. Perform W1. Catalyst Calendar (Strategies A and C) — deep research.'),
  STRUCT('W2',  'Read Claude_Task_Plan.md. Perform W2. Post-Event Screen (Strategy B) — deep research.'),
  STRUCT('W3',  'Read Claude_Task_Plan.md. Perform W3. Open-Position Deep-Dive (Strategies A, B, C, E) — deep research.'),
  STRUCT('W4',  'Read Claude_Task_Plan.md. Perform W4. Weekly Action Conversion — regular routine.'),
  STRUCT('W5',  'Read Claude_Task_Plan.md. Perform W5. Factbase & Analytics Consolidation — regular routine.'),
  STRUCT('M1a', 'Read Claude_Task_Plan.md. Perform M1a. Strategy-Blind Regime Scoring — deep research.'),
  STRUCT('M1b', 'Read Claude_Task_Plan.md. Perform M1b. Strategy Mapping and Activation Calls — regular routine.'),
  STRUCT('M2',  'Read Claude_Task_Plan.md. Perform M2. E Pair Divergence Screen — deep research.'),
  STRUCT('M3',  'Read Claude_Task_Plan.md. Perform M3. D Position Deep-Dive — deep research.'),
  STRUCT('M4',  'Read Claude_Task_Plan.md. Perform M4. Monthly Action Conversion — regular routine.'),
  STRUCT('M5',  'Read Claude_Task_Plan.md. Perform M5. Deployed-TWR & Macro Forecast — regular routine.'),
  -- The adversarial routines self-log under the abbreviated ids AR_att / AR_orc (ASCII,
  -- standardized 2026-07-01 — RUNBOOK §28 — from the earlier non-ASCII middle-dot AR·att/AR·orc an
  -- agent kept mis-transcribing). Same ids in the Claude_Task_Plan.md routine table + ops/cadence.yaml.
  -- The separator-normalized join below folds the LEGACY middle-dot ops.run_log rows onto these keys,
  -- so the historical partitions do NOT resurface as unknown_routine after the id switch.
  STRUCT('AR_att',  'Read Claude_Task_Plan.md. Perform Adversarial Review Attacker — regular routine.'),
  STRUCT('AR_orc',  'Read Claude_Task_Plan.md. Perform Adversarial Review Orchestrator — regular routine.'),
  STRUCT('Q1',  'Read Claude_Task_Plan.md. Perform Q1. Regime Retrospective — deep research.'),
  STRUCT('Q2',  'Read Claude_Task_Plan.md. Perform Q2. D Long-Horizon Candidates — deep research.'),
  STRUCT('Q3',  'Read Claude_Task_Plan.md. Perform Q3. AI Foundation Quarterly Delta — deep research.'),
  STRUCT('Q4',  'Read Claude_Task_Plan.md. Perform Q4. Quarterly Action Conversion — regular routine.'),
  STRUCT('A1',  'Read Claude_Task_Plan.md. Perform A1. AI Foundation Annual Full Re-Derivation — deep research.'),
  STRUCT('A2',  'Read Claude_Task_Plan.md. Perform A2. Per-Strategy Constraint Audit — deep research.'),
  STRUCT('A3',  'Read Claude_Task_Plan.md. Perform A3. Annual Action Conversion — regular routine.')
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
     AND li.instruction != c.canonical_instruction) AS drifted,
  (c.routine IS NULL) AS unknown_routine,
  CURRENT_TIMESTAMP() AS checked_at
FROM `stock-trading-498512.ops.routine_catalog` c
FULL OUTER JOIN li
  ON REGEXP_REPLACE(li.routine, r'[·._-]', '') = REGEXP_REPLACE(c.routine, r'[·._-]', '');

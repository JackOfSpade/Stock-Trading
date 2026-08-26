-- INSTRUCTION-DRIFT WHITESPACE NORMALIZATION (2026-07-29 interactive session; surfaced by alert
-- cb7bb9fd-e511-4c30-b454-585bd87bd735, "Trigger drift: ... SL3"). Project: stock-trading-498512.
-- Apply after 15_routine_catalog.sql.
--
-- PROBLEM: state.instruction_drift compares FIRST-LINE-ONLY equality (rev 2026-07-20) —
-- `REGEXP_EXTRACT(live, r'^[^\n]*') != canonical`. That form exists to tolerate the operator's
-- standing post-heading addendum ("Spawn Sonnet 5 model sub-agents to do the grunt work. …"), which is
-- separated from the canonical first line by a BLANK LINE in every live trigger. It silently assumes
-- the addendum is still newline-separated by the time the check sees it — and the check does NOT see
-- the live trigger. It sees `ops.run_log.instruction`, i.e. what the ROUTINE ITSELF transcribed when it
-- called sp_routine_start. A session that copies its trigger text with the newlines collapsed to a
-- space produces a single-line instruction, first-line-only equality fails, and a `trigger_drift`
-- WARNING fires against a trigger that is in fact CORRECT.
--
-- MEASURED, 2026-07-29: SL3 alerted `instruction_drift`. `RemoteTrigger get trig_01U8YmUoro5oiigaqq9jGbcp`
-- shows the LIVE trigger carries the proper "…— regular routine.\n\nSpawn Sonnet 5…" form — no config
-- drift whatsoever. But SL3's 2026-07-28 run logged that same text space-joined onto one line, and
-- state.routine_last_instruction takes the LATEST run's transcription, so the view compared a flattened
-- string against the canonical and flagged it. SL3's own 2026-07-20..07-27 runs logged only the first
-- line and never drifted — so this is per-run transcription luck, not a config change. It can hit ANY
-- routine carrying the addendum (OPS1, W1, W2, W3, AR_att all do), and it clears only if some later run
-- happens to transcribe it differently. A monitor whose entire value is signal quality must not emit a
-- warning that is non-deterministic in this way.
--
-- FIX: compare on WHITESPACE-NORMALIZED PREFIX — collapse every run of whitespace to a single space on
-- BOTH sides, then require the canonical instruction to be a PREFIX of the live one. Semantics move
-- from "the live first line must equal canonical" to the thing actually intended: "the live instruction
-- must BEGIN with the canonical instruction." Whether the addendum is newline- or space-separated
-- stops mattering, because a separator is whitespace either way.
--
-- STILL CAUGHT (verified by 7 synthetic negative controls before applying, all PASS): wrong routine
-- number (SL4 vs SL3), wrong heading text, wrong type-tag (`— deep research.` vs `— regular routine.`),
-- a TRUNCATED instruction, and PREPENDED text (canonical no longer at the start). The canonical string
-- always ends with the type-tag sentence, so prefix-matching still pins the routine number, the full
-- heading text, and the type tag exactly — the three things this check exists to protect (RUNBOOK §22).
--
-- WHAT IT DELIBERATELY STOPS CATCHING: extra text appended to the canonical first line ON THE SAME LINE.
-- That is precisely the benign addendum case above, and it was never a drift class anyone wanted
-- flagged — the 2026-07-20 first-line rule was itself introduced to exclude the addendum and merely
-- picked a separator-dependent way to do it.
--
-- VERIFIED against live data before applying: across all 32 catalog routines the ONLY verdict change is
-- SL3 flipping drifted TRUE -> FALSE. No routine flips FALSE -> TRUE.
--
-- SUPERSEDES the state.instruction_drift VIEW in 15_routine_catalog.sql (that file's
-- ops.routine_catalog TABLE + its generated STRUCT rows are UNCHANGED and remain canonical there —
-- this file does not touch them).

-- SUPERSEDED LIVE by bigquery/201_instruction_drift_dash_normalize.sql (2026-08-26) — current
-- single source of truth for state.instruction_drift. Supersession chain: 2026-07-29 this file
-- introduced the whitespace-normalized PREFIX match; 2026-08-19 bigquery/183 added the staleness
-- gate; 2026-08-26 bigquery/201 added em/en-dash folding (r'[—–]' → '-') before the whitespace
-- normalization. Apply bigquery/201 — do NOT re-apply the CREATE OR REPLACE VIEW below live in
-- isolation. Kept here, unmodified, for DR-rebuild apply-in-order reference only.

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
     -- whitespace-normalized PREFIX match (2026-07-29, this file; was first-line-only equality, which
     -- false-fired whenever a routine transcribed its trigger with the newlines collapsed). Normalizing
     -- BOTH sides keeps the comparison symmetric even if a future canonical heading gains odd spacing.
     AND NOT STARTS_WITH(
           TRIM(REGEXP_REPLACE(li.instruction, r'\s+', ' ')),
           TRIM(REGEXP_REPLACE(c.canonical_instruction, r'\s+', ' ')))) AS drifted,
  (c.routine IS NULL) AS unknown_routine,
  CURRENT_TIMESTAMP() AS checked_at
FROM `stock-trading-498512.ops.routine_catalog` c
FULL OUTER JOIN li
  ON REGEXP_REPLACE(li.routine, r'[·._-]', '') = REGEXP_REPLACE(c.routine, r'[·._-]', '');

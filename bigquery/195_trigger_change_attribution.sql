-- ===== 195: trigger-change ATTRIBUTION — make an out-of-band trigger edit answerable =====
-- (2026-08-21, owner-directed, follow-on to bigquery/194 / commit fdd5cbe.)
--
-- THE PROBLEM. The claude.ai routines API exposes `updated_at` on a trigger but carries NO
-- actor/author field anywhere in its response, so the platform can tell us WHEN a trigger prompt
-- changed and never WHO changed it. Observed 2026-08-21: a browser session read the fleet, saw all 32
-- triggers updated inside a 09:57-10:10 UTC window ~20s apart, and could not establish from the API
-- whether that was the operator, another session, or something scheduled. (It was an earlier browser
-- session's own queue driver running an authorized rollout.) fdd5cbe recorded that as a limitation.
-- This file REMOVES the limitation on our side instead of documenting it.
--
-- THE MECHANISM — attribution by DECLARED INTENT plus OBSERVATION BRACKETING. We cannot add a column
-- to the vendor's API, so we add the column to OUR record of it:
--   1. ops.trigger_observations  — append-only snapshot of a trigger's live config, written every time
--      any agent reads it, carrying `observed_by`: WHICH actor did the reading. Consecutive rows for a
--      routine bracket every change into a known interval.
--   2. ops.trigger_change_intents — append-only DECLARATION written BEFORE a write, carrying `actor`,
--      the intended instruction, the field, and a reason. An authorized writer says what it is about
--      to do; an unauthorized or accidental one does not.
--   3. state.trigger_change_attribution — joins the two: every observed change is either matched to a
--      declared intent (`attributed_to` = that actor) or flagged `unattributed`.
-- An unattributed change is now a POSITIVE, alertable finding rather than an unanswerable question.
-- That is the real security property: authorized edits are attributed, and anything else stands out.
--
-- HONEST LIMITS, stated so nobody over-reads this:
--   * Resolution is bounded by observation frequency. OPS0 STEP 3 sweeps every routine on Sundays, so
--     an unattributed change is caught within a week; ANY other session that reads triggers may also
--     write observations, and each one narrows the bracket. More observers = finer resolution.
--   * It attributes to a DECLARED actor, not to an authenticated one. A hostile actor holding the same
--     credentials could file a false intent. This is a DETECTIVE control against accident, drift and
--     unannounced edits — the same posture as bigquery/scheduled_queries/safety_critical_dml_watch.sql,
--     which its header already explains cannot prevent, only catch.
--   * `api_updated_at` is recorded because it is the one temporal fact the vendor gives; the change
--     detector does NOT depend on it (a vendor that stopped populating it changes nothing here).

-- APPLIED LIVE 2026-08-21 in the same pass, together with a BASELINE SEED: one observation row per
-- fleet routine (32), observed_by='interactive:2018ca1c', carrying each trigger's verbatim live
-- instruction, api_updated_at, cron and enabled state as read from the routines API. Each seeded
-- instruction was verified sha256-identical to ops/routine_backup.json's canonical text for that
-- routine (32/32) -- a mistyped baseline would otherwise fake a change on the next sweep. Seeded so
-- attribution is live from the NEXT sweep rather than the one after it. A retroactive intent row (32,
-- retroactive=TRUE) records the owner-directed 2026-08-21 09:57-10:10 UTC rollout that prompted this
-- file; it brackets no change, because those observations are the first this system holds.
-- End-to-end tested on a synthetic __TEST__ routine before seeding: a declared change resolved to
-- attributed_to='OPS0' / match_strength='exact-text' / unattributed=FALSE, an undeclared one to
-- attributed_to=NULL / unattributed=TRUE. The synthetic rows were deleted afterwards; the tables hold
-- real observations only.

-- ---------------------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.trigger_observations` (
  observed_ts     TIMESTAMP DEFAULT CURRENT_TIMESTAMP() OPTIONS(description="When this observation was taken."),
  routine         STRING NOT NULL OPTIONS(description="Routine id, e.g. OPS0 -- matches ops.run_log.routine."),
  trigger_id      STRING          OPTIONS(description="Live trigger id (trig_...), as in ops/trigger_ids.json."),
  instruction     STRING          OPTIONS(description="The FULL live instruction text as read from the API, verbatim -- core one-liner plus the standing operator paragraphs. Stored in full, not hashed, so a change can be DIFFED and not merely detected."),
  api_updated_at  TIMESTAMP       OPTIONS(description="The vendor's own updated_at for this trigger. Recorded for corroboration only; change detection does not depend on it."),
  cron_expression STRING          OPTIONS(description="Live schedule, verbatim."),
  enabled         BOOL            OPTIONS(description="Live enabled state."),
  observed_by     STRING NOT NULL OPTIONS(description="THE ATTRIBUTION COLUMN. Which actor took this observation: a routine id ('OPS0','Q4'), or 'interactive:<short session ref>', or 'browser:<short session ref>'. Never blank -- an anonymous observation is worth less than none."),
  source          STRING          OPTIONS(description="How it was read, e.g. 'RemoteTrigger get' or 'routines API list'.")
) PARTITION BY DATE(observed_ts) CLUSTER BY routine
OPTIONS(description='Append-only snapshot of live routine-trigger config, one row per routine per read. Consecutive rows bracket every config change into a known interval; observed_by records who looked. Substrate for state.trigger_change_attribution.');

CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.trigger_change_intents` (
  intent_ts        TIMESTAMP DEFAULT CURRENT_TIMESTAMP() OPTIONS(description="When the intent was declared -- MUST be written BEFORE the update call."),
  routine          STRING NOT NULL OPTIONS(description="Routine id whose trigger is about to change."),
  trigger_id       STRING          OPTIONS(description="Live trigger id."),
  actor            STRING NOT NULL OPTIONS(description="THE ATTRIBUTION COLUMN. Who is making the change: a routine id ('OPS0','Q4'), 'interactive:<ref>', 'browser:<ref>', or 'operator'."),
  field            STRING NOT NULL OPTIONS(description="instruction | schedule | allowed_tools | enabled."),
  intended_instruction STRING      OPTIONS(description="For field='instruction': the exact text about to be written, so the resulting observation can be matched to this intent rather than merely to its timing."),
  reason           STRING          OPTIONS(description="Why -- free text, e.g. 'OPS0 STEP 3 instruction-drift self-correct' or an owner directive reference."),
  session_ref      STRING          OPTIONS(description="Session/run reference for cross-checking against ops.run_log."),
  retroactive      BOOL            OPTIONS(description="TRUE when filed AFTER the fact to record a known-authorized historical change. Kept explicit so a backfilled attribution can never be mistaken for a contemporaneous declaration.")
) PARTITION BY DATE(intent_ts) CLUSTER BY routine
OPTIONS(description='Append-only declaration of an intended routine-trigger change, written BEFORE the write. An observed change with no matching intent is what state.trigger_change_attribution flags as unattributed.');

-- ---------------------------------------------------------------------------------------------
-- Writer helpers. Routines call these rather than hand-rolling INSERTs (same reason ops.sp_raise_alert
-- and ops.sp_log_decision exist): one contract, no malformed rows, and observed_by/actor cannot be
-- silently omitted because they are required arguments.
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_record_trigger_observation`(
  in_routine STRING, in_trigger_id STRING, in_instruction STRING, in_api_updated_at TIMESTAMP,
  in_cron STRING, in_enabled BOOL, in_observed_by STRING, in_source STRING)
BEGIN
  IF in_routine IS NULL OR in_observed_by IS NULL OR TRIM(in_observed_by) = '' THEN
    RAISE USING MESSAGE = 'sp_record_trigger_observation: routine and observed_by are both required -- an anonymous observation cannot attribute anything.';
  END IF;
  INSERT INTO `stock-trading-498512.ops.trigger_observations`
    (routine, trigger_id, instruction, api_updated_at, cron_expression, enabled, observed_by, source)
  VALUES (in_routine, in_trigger_id, in_instruction, in_api_updated_at, in_cron, in_enabled, in_observed_by, in_source);
END;

CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_declare_trigger_change_intent`(
  in_routine STRING, in_trigger_id STRING, in_actor STRING, in_field STRING,
  in_intended_instruction STRING, in_reason STRING, in_session_ref STRING, in_retroactive BOOL)
BEGIN
  IF in_routine IS NULL OR in_actor IS NULL OR TRIM(in_actor) = '' OR in_field IS NULL THEN
    RAISE USING MESSAGE = 'sp_declare_trigger_change_intent: routine, actor and field are all required.';
  END IF;
  INSERT INTO `stock-trading-498512.ops.trigger_change_intents`
    (routine, trigger_id, actor, field, intended_instruction, reason, session_ref, retroactive)
  VALUES (in_routine, in_trigger_id, in_actor, in_field, in_intended_instruction, in_reason, in_session_ref,
          COALESCE(in_retroactive, FALSE));
END;

-- ---------------------------------------------------------------------------------------------
-- state.trigger_change_attribution — every OBSERVED change, with its actor or an unattributed flag.
--
-- A "change" is a difference in the live instruction text between two consecutive observations of the
-- same routine. Keyed on the TEXT, not on api_updated_at: the vendor's timestamp also moves for edits
-- we do not care about (a rename, a schedule tweak) and would move for a no-op re-save, whereas the
-- instruction text is the thing the sweep enforces and the thing that changes routine behaviour.
-- api_updated_at rides along as corroboration.
--
-- MATCHING RULE: an intent attributes a change when it names the same routine, targets the instruction
-- field, was declared at or before the observation that first saw the new text, AND either declared
-- the exact resulting text or declared no text at all (a writer that names the routine and field but
-- not the payload still attributes -- it is a weaker claim, surfaced as `match_strength`).
-- The window opens at the PREVIOUS observation, so an intent filed long before an unrelated later
-- change cannot silently absorb it.
CREATE OR REPLACE VIEW `stock-trading-498512.state.trigger_change_attribution` AS
WITH obs AS (
  SELECT
    routine, trigger_id, instruction, api_updated_at, observed_ts, observed_by,
    LAG(instruction)    OVER w AS prev_instruction,
    LAG(observed_ts)    OVER w AS prev_observed_ts,
    LAG(api_updated_at) OVER w AS prev_api_updated_at,
    LAG(observed_by)    OVER w AS prev_observed_by
  FROM `stock-trading-498512.ops.trigger_observations`
  WINDOW w AS (PARTITION BY routine ORDER BY observed_ts)
),
changes AS (
  SELECT * FROM obs
  -- prev IS NULL => this routine's first-ever observation: a baseline, not a change.
  WHERE prev_observed_ts IS NOT NULL
    AND COALESCE(instruction, '') != COALESCE(prev_instruction, '')
)
SELECT
  c.routine,
  c.trigger_id,
  c.prev_observed_ts        AS changed_after,       -- the change happened strictly inside
  c.observed_ts             AS changed_by_at_latest, -- this bracket
  c.prev_api_updated_at,
  c.api_updated_at,
  c.prev_instruction,
  c.instruction             AS new_instruction,
  c.prev_observed_by        AS bracket_opened_by,
  c.observed_by             AS bracket_closed_by,
  i.actor                   AS attributed_to,       -- THE ANSWER: who declared this change
  i.reason                  AS attributed_reason,
  i.intent_ts               AS attributed_intent_ts,
  i.retroactive             AS attribution_is_retroactive,
  CASE
    WHEN i.actor IS NULL THEN 'none'
    WHEN i.intended_instruction IS NOT NULL AND i.intended_instruction = c.instruction THEN 'exact-text'
    ELSE 'routine-and-field'
  END                       AS match_strength,
  (i.actor IS NULL)         AS unattributed,        -- the alertable condition
  CURRENT_TIMESTAMP()       AS checked_at
FROM changes c
LEFT JOIN `stock-trading-498512.ops.trigger_change_intents` i
  ON  i.routine   = c.routine
  AND i.field     = 'instruction'
  AND i.intent_ts <= c.observed_ts
  AND i.intent_ts >  c.prev_observed_ts
  AND (i.intended_instruction IS NULL OR i.intended_instruction = c.instruction)
-- One row per change: if several intents match, keep the strongest/most recent claim.
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY c.routine, c.observed_ts
  ORDER BY (i.intended_instruction = c.instruction) DESC NULLS LAST, i.intent_ts DESC) = 1;

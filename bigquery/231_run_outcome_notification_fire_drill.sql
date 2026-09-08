-- 231_run_outcome_notification_fire_drill.sql (2026-09-08)
-- Project: stock-trading-498512. Apply after 230_run_outcome_notification.sql.
--
-- SUPERSEDES bigquery/230's definition of state.run_log_unalerted_problems (adds a FIRE_DRILL%
-- exclusion) and bigquery/134's definition of ops.sp_sq_fire_drill_alert_lifecycle (SQ_VERSION
-- v3 -> v4, wires in the new drill below). Every other object in 230 and 134 is UNCHANGED and
-- deliberately NOT re-issued here -- per bigquery/47's header rule, re-applying an old file's CREATE
-- in isolation is the exact action that caused the 47 regression.
--
-- ============================ WHY (FIX 3, DESIGN_followups.md, 2026-09-08) ============================
-- bigquery/230_run_outcome_notification.sql gave the routine fleet a mechanical failed/warning-run
-- notification path (P1: ops.sp_log_run write-time escalation; P2: ops.sp_report_run_issue; P3: the
-- state.run_log_unalerted_problems backstop view). That path has NEVER been exercised end to end --
-- it shipped with no drill, unlike every other alert-lifecycle mechanism in this repo. An untested
-- breaker is theater (the exact reasoning bigquery/34's sp_fire_drill_alert_latch header already
-- states for the auto-resolve rules). This file closes that gap the same way the other four were
-- closed: a synthetic, self-cleaning drill wired into the existing monthly schedule.
--
-- MEASURED before writing this file (2026-09-08 investigation; not re-derived here):
--
-- F1. FOUR fire drills already exist, using FIVE distinct anti-pollution techniques:
--     * ops.sp_fire_drill_order_guard (bigquery/104_options_defined_risk_and_order_guard_v4.sql:166-219)
--       -- writes ONLY an ops.run_log row on success; raises a critical ONLY on failure. Zero
--       ops.alerts rows in its entire history.
--     * ops.sp_fire_drill_alert_latch (bigquery/34_alert_lifecycle.sql:233-256) -- INSERTs a real
--       critical tagged payload.synthetic=TRUE, resolves it, LEAVES it. Live: 8 rows, EVERY ONE with
--       notified_ts populated -- it emails the owner a [TEST]-labelled mail every month.
--     * ops.sp_fire_drill_alert_resolve (bigquery/34_alert_lifecycle.sql:275-312) -- INSERTs a
--       synthetic run_log + alerts row, then UNCONDITIONALLY DELETEs BOTH before the verdict. Live:
--       zero rows ever. No synthetic tag -- timing-only protection.
--     * ops.sp_fire_drill_roster_notice (bigquery/134_roster_change_notifications.sql:383-457) --
--       INSERTs synthetic=TRUE, stamps notified_ts, UNCONDITIONALLY DELETEs, all wrapped in its own
--       BEGIN...EXCEPTION so even an abort still cleans up. Live: zero rows ever. THE BEST TEMPLATE,
--       and the one this file's drill (Part A below) is modelled on directly: same outer
--       BEGIN...EXCEPTION cleanup guard, same unconditional-cleanup-before-verdict ordering, same
--       sp_raise_alert (never _once) failure path.
-- F2. All four existing drills raise on failure with ops.sp_raise_alert -- NOT _once -- at severity
--     CRITICAL, so a broken breaker is loud and undeduped rather than silently swallowed by the same
--     dedup mechanism a healthy drill would rely on.
-- F3. Invocation is TWO monthly BigQuery scheduled queries on the 1st: fire_drill_order_guard
--     (06:10 UTC) and fire_drill_alert_lifecycle (06:20 UTC). The latter calls latch + resolve +
--     roster_notice today via the wrapper ops.sp_sq_fire_drill_alert_lifecycle
--     (bigquery/134_roster_change_notifications.sql:471-474) -- Part C below adds this file's new
--     drill as that wrapper's fourth CALL, on the SAME existing schedule. An unwired drill is theatre.
-- F4. ops/monitoring/alert_emailer.gs keys delivery on notified_ts IS NULL and NEVER on resolved, so
--     pre-stamping notified_ts deterministically excludes a row from EMAIL forever. It does NOT block
--     scripts/alert_relay.py's ntfy push, which has no notified_ts term (it selects NOT resolved
--     within a 130-minute window). DELETION is the only thing that covers both channels -- which is
--     why Part A's cleanup step (4) stamps notified_ts and THEN deletes, never stamps alone.
-- F5. ops.alerts is NOT under the append-only guard (that scope is fixed to events.* tables). DELETE
--     FROM ops.alerts is sanctioned and already practised live by two of the four existing drills.
-- F6. A warning-severity alert row does not perturb state.system_health.open_critical_alerts,
--     state.trading_enabled.blocking_criticals, or the weekly digest -- all three gate on CRITICAL
--     only. That is why F2/Part A's failure verdict is critical (it is the notifier itself that is
--     broken, at most once a month) while P1/P2's own per-run categories correctly stay warning
--     (C1 in bigquery/230 -- a single failed routine run must never self-inflict a trading halt).
-- F7. state.run_log_unalerted_problems is proven NON-VACUOUS by counterfactual (a positive control
--     flags, a negative control does not); its host block in ops.sp_sq_cadence_check is syntactically
--     sound on both empty and non-empty input. Part B below changes only its WHERE clause (one
--     added predicate); nothing about that proof is touched.
--
-- ===== PART A -- ops.sp_fire_drill_run_outcome_notification(), new =====
-- Exercises, in one procedure, per DESIGN_followups.md FIX 3 steps 1-6:
--   (1) P1 -- CALL ops.sp_log_run(..., 'failed', ...) with a synthetic error_msg, then assert a
--       routine_run_failed alert whose payload names this drill's routine exists.
--   (2) P2 -- CALL ops.sp_report_run_issue(...) with a VALID issue_key + summary, then assert a
--       routine_run_warning alert carrying that issue_key exists.
--   (3) Both of ops.sp_report_run_issue's refusal floors (blank issue_key; a summary under 30
--       non-blank chars) actually RAISE, each proven in its OWN BEGIN...EXCEPTION WHEN ERROR THEN
--       SET <flag> = TRUE; END block -- a floor that silently stopped refusing would let a
--       placeholder report pass as real, exactly what bigquery/230's REFUSAL STYLE section
--       (ops.sp_report_run_issue's header) exists to prevent.
--   (4) CLEAN UP UNCONDITIONALLY, BEFORE the verdict, inside its own BEGIN...EXCEPTION (the
--       roster_notice shape, F1): stamp notified_ts on the drill's alert rows (blocks EMAIL per F4),
--       then DELETE them, then DELETE the synthetic ops.run_log rows (routine = drill id AND status
--       <> 'completed'). Deletion is what covers the ntfy push too (F4) -- stamping alone would not.
--   (5) VERDICT: on any failed assertion, CALL ops.sp_raise_alert (NOT _once, per F2) at severity
--       CRITICAL, category run_outcome_fire_drill_failed. Critical is correct here specifically
--       because this drill firing at most monthly and failing means the operator is BLIND to every
--       routine failure until it is fixed -- not in tension with P1/P2's own warning-only categories
--       (F6), which govern the per-run outcome, not the notifier's own health.
--   (6) On success, log the audit row ops.sp_log_run(..., 'completed', ...) LAST, after cleanup --
--       'completed' so step (4)'s DELETE (which spares 'completed') keeps it as the durable record,
--       and so it cannot itself feed back into P1's own escalation (a completed row with a blank
--       error_msg raises nothing) or re-trigger this backstop.
--
-- The drill's own routine id, 'FIRE_DRILL_RUN_OUTCOME', matches the FIRE_DRILL% pattern Part B's
-- exclusion (below) and bigquery/172/186/205/227's sibling exclusion on state.run_log_unpaired_terminal
-- both key on, so it is structurally invisible to every other run_log-based backstop in the repo, not
-- just to Part B's -- the same "call ops.sp_log_run directly, never sp_routine_start" shape those
-- files already special-case for FIRE_DRILL% generally.
--
-- ===== PART B -- state.run_log_unalerted_problems, superseded =====
-- Adds ONE predicate (AND r.routine NOT LIKE 'FIRE_DRILL%') plus its justification comment to the
-- canonical body copied verbatim from bigquery/230 -- nothing else in the view changes. Rationale: if
-- Part A's drill ever aborts BETWEEN step (1)'s synthetic 'failed' INSERT and step (4)'s unconditional
-- cleanup, that row would otherwise sit in this view's 14-day window and make P3 cry wolf about a
-- drill, not a real routine failure. This makes the drill structurally safe rather than relying on
-- cleanup always succeeding -- the identical reasoning bigquery/172_run_log_unpaired_terminal.sql,
-- 186_monitor_promoted_autoage.sql, 205_alert_message_stability.sql and
-- 227_alert_message_stability_ordering.sql already apply to state.run_log_unpaired_terminal's FIRE_DRILL%
-- / SELFHEAL_RUN_LOG exclusion; this view was the one sibling left unprotected. See Part B's own
-- inline comment (immediately above the new predicate, below) for the exact wording, matched to that
-- chain's convention.
--
-- C5 dbt COVERAGE. state.run_log_unalerted_problems already has a dbt port
-- (dbt/models/state/run_log_unalerted_problems.sql, from bigquery/230). Its body changes here, so it
-- is regenerated in the SAME change via scripts/gen_dbt_port.py (never hand-edited) -- see this
-- task's own verification log for the regenerate + `dbt compile` + verify_dbt_port.py steps.
--
-- ===== PART C -- ops.sp_sq_fire_drill_alert_lifecycle, superseded, SQ_VERSION v3 -> v4 =====
-- Body generated by PROGRAMMATIC exact-string replacement against the live v3 body
-- (bigquery/134_roster_change_notifications.sql:468-474), never retyped (script kept alongside this
-- landing for reproducibility). EXACTLY TWO replacements, each verified to match its anchor in the
-- v3 body EXACTLY ONCE before this file was written (see this task's own return value for the
-- replacement counts):
--   (a) the heartbeat literal 'v3' -> 'v4';
--   (b) a new CALL ops.sp_fire_drill_run_outcome_notification(); inserted immediately after the
--       existing CALL ops.sp_fire_drill_roster_notice(); line, before END; -- so the new drill runs
--       fourth, after the three existing ones, on the SAME 06:20 UTC monthly schedule (F3). No other
--       drill logic changed.
-- The matching bigquery/63_scheduled_query_version_registry.sql row (sq_name='fire_drill_alert_lifecycle')
-- is bumped v3 -> v4 in the SAME change (scripts/check_sq_version_registry.py enforces this pairing),
-- marked STAGED / NOT YET APPLIED per that file's own partial-apply-trap convention, since this
-- landing does not apply anything live (per this task's own constraints).
--
-- ===== SUPERSESSION =====
-- Every SUPERSEDED object gets a marker appended pointing at this file, in the SAME change, per
-- scripts/check_superseded_markers.py's rule that a pointer at a now-superseded INTERMEDIATE file
-- does not satisfy the check: bigquery/230 (state.run_log_unalerted_problems) and bigquery/134
-- (ops.sp_sq_fire_drill_alert_lifecycle). Every other object in both files is untouched and keeps
-- whatever canonical/superseded status it already had.
-- ============================================================================

-- ============================================================================
-- ops.sp_fire_drill_run_outcome_notification -- PART A. Proves the run-outcome notification path
-- (bigquery/230: P1 ops.sp_log_run write-time escalation, P2 ops.sp_report_run_issue, and both of
-- P2's refusal floors) actually delivers, and cleans up unconditionally so a monthly drill can never
-- leave a synthetic alert or run_log row live. See this file's own header (PART A) for the six-step
-- design and the F1-F7 evidence it is built on.
-- ============================================================================
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_fire_drill_run_outcome_notification`()
BEGIN
  DECLARE drill_routine STRING DEFAULT 'FIRE_DRILL_RUN_OUTCOME';
  DECLARE drill_date DATE DEFAULT CURRENT_DATE('America/Denver');
  DECLARE test_issue_key STRING DEFAULT 'fire_drill_synthetic_issue';
  DECLARE p1_alert_found BOOL DEFAULT FALSE;
  DECLARE p2_alert_found BOOL DEFAULT FALSE;
  DECLARE floor_blank_key_raised BOOL DEFAULT FALSE;
  DECLARE floor_short_summary_raised BOOL DEFAULT FALSE;

  -- EXCEPTION-GUARDED (same reason as ops.sp_fire_drill_roster_notice, F1): without this, a throw
  -- anywhere below would abort at that statement and neither the verdict nor the cleanup that
  -- precedes it would ever run, leaving a synthetic 'failed' run_log row and synthetic alert rows
  -- live with no failure signal anywhere anyone watches.
  BEGIN

  -- (1) Exercise P1 (ops.sp_log_run's write-time escalation, bigquery/230): log a synthetic FAILED
  -- run and assert the mechanical routine_run_failed alert followed.
  CALL `stock-trading-498512.ops.sp_log_run`(
    drill_routine, drill_date, 'failed', NULL, NULL, NULL,
    'FIRE DRILL synthetic failure -- exercising P1 write-time escalation (ops.sp_log_run), auto-cleaned.',
    'FIRE DRILL synthetic run -- see ops.sp_fire_drill_run_outcome_notification. Auto-cleaned before this drill completes.');

  SET p1_alert_found = EXISTS (
    SELECT 1 FROM `stock-trading-498512.ops.alerts`
    WHERE category = 'routine_run_failed'
      AND JSON_VALUE(payload, '$.routine') = drill_routine
      AND JSON_VALUE(payload, '$.run_date') = CAST(drill_date AS STRING));

  -- (2) Exercise P2 (ops.sp_report_run_issue, bigquery/230): a VALID issue_key + summary must raise a
  -- routine_run_warning alert carrying that issue_key.
  CALL `stock-trading-498512.ops.sp_report_run_issue`(
    drill_routine, drill_date, test_issue_key,
    'FIRE DRILL synthetic in-run issue -- exercising P2 (ops.sp_report_run_issue), auto-cleaned.',
    NULL);

  SET p2_alert_found = EXISTS (
    SELECT 1 FROM `stock-trading-498512.ops.alerts`
    WHERE category = 'routine_run_warning'
      AND JSON_VALUE(payload, '$.routine') = drill_routine
      AND JSON_VALUE(payload, '$.run_date') = CAST(drill_date AS STRING)
      AND JSON_VALUE(payload, '$.issue_key') = test_issue_key);

  -- (3a) Floor 1 -- a blank issue_key MUST RAISE. If it silently stopped refusing, this call would
  -- fall through and INSERT a real alert with issue_key='' -- step (4)'s cleanup below is scoped to
  -- ANY alert matching this drill's routine identity, category-wide, so that stray row is still
  -- caught regardless of which way this assertion goes.
  BEGIN
    CALL `stock-trading-498512.ops.sp_report_run_issue`(
      drill_routine, drill_date, '',
      'FIRE DRILL negative-control summary, deliberately long enough to clear the 30-char floor on its own.',
      NULL);
  EXCEPTION WHEN ERROR THEN
    SET floor_blank_key_raised = TRUE;
  END;

  -- (3b) Floor 2 -- a summary under 30 non-blank characters MUST RAISE, with a VALID issue_key so the
  -- raise can only be attributed to the summary floor.
  BEGIN
    CALL `stock-trading-498512.ops.sp_report_run_issue`(
      drill_routine, drill_date, 'fire_drill_short_summary_floor_test', 'too short', NULL);
  EXCEPTION WHEN ERROR THEN
    SET floor_short_summary_raised = TRUE;
  END;

  -- (4) CLEAN UP UNCONDITIONALLY, BEFORE the verdict (roster_notice's shape, F1). Stamp notified_ts
  -- first (blocks alert_emailer.gs delivery per F4), THEN delete -- deletion is what also covers
  -- scripts/alert_relay.py's ntfy push, which has no notified_ts term at all (F4). Matched by this
  -- drill's routine identity in the payload, not by a captured alert_id, because sp_raise_alert(_once)
  -- generates alert_id itself -- unlike sp_fire_drill_alert_latch/_resolve, which INSERT directly and
  -- so can pin a known id.
  --
  -- EACH statement below is wrapped in its OWN BEGIN...EXCEPTION, unlike ops.sp_fire_drill_roster_notice
  -- (bigquery/134), whose step (e) cleanup is a SINGLE DELETE and so has nothing to bundle in the first
  -- place. This drill's cleanup is three sequential statements against two tables -- without a per-
  -- statement guard, one transient failure (e.g. the UPDATE) would abort this BEGIN block before the two
  -- DELETEs run, falling through to the outer EXCEPTION handler below, which repeats all three anyway and
  -- reports the drill as ABORTED rather than surfacing its true pass/fail verdict. Isolating each
  -- statement here means a single transient cleanup failure can no longer mask the actual P1/P2/floor
  -- assertion results computed above.
  BEGIN
    UPDATE `stock-trading-498512.ops.alerts`
    SET notified_ts = CURRENT_TIMESTAMP()
    WHERE category IN ('routine_run_failed', 'routine_run_warning')
      AND JSON_VALUE(payload, '$.routine') = drill_routine
      AND notified_ts IS NULL;
  EXCEPTION WHEN ERROR THEN
    SELECT @@error.message;
  END;

  BEGIN
    DELETE FROM `stock-trading-498512.ops.alerts`
    WHERE category IN ('routine_run_failed', 'routine_run_warning')
      AND JSON_VALUE(payload, '$.routine') = drill_routine;
  EXCEPTION WHEN ERROR THEN
    SELECT @@error.message;
  END;

  BEGIN
    DELETE FROM `stock-trading-498512.ops.run_log`
    WHERE routine = drill_routine AND status <> 'completed';
  EXCEPTION WHEN ERROR THEN
    SELECT @@error.message;
  END;

  -- (5) VERDICT.
  IF NOT p1_alert_found OR NOT p2_alert_found
     OR NOT floor_blank_key_raised OR NOT floor_short_summary_raised THEN
    CALL `stock-trading-498512.ops.sp_raise_alert`(
      'critical', 'ops.sp_fire_drill_run_outcome_notification', 'run_outcome_fire_drill_failed',
      CONCAT(
        'The run-outcome-notification fire drill FAILED (p1_alert_found=', CAST(p1_alert_found AS STRING),
        ', p2_alert_found=', CAST(p2_alert_found AS STRING),
        ', floor_blank_key_raised=', CAST(floor_blank_key_raised AS STRING),
        ', floor_short_summary_raised=', CAST(floor_short_summary_raised AS STRING),
        '). The mechanical link from a failed/halted run (ops.sp_log_run, P1) or an in-run issue ',
        'report (ops.sp_report_run_issue, P2) to an owner-facing alert may be broken, or one of P2\'s ',
        'two refusal floors (blank issue_key; summary under 30 non-blank chars) may have silently ',
        'stopped refusing. Investigate ops.sp_log_run and ops.sp_report_run_issue (bigquery/230) ',
        'before trusting the run-outcome notification path.'),
      TO_JSON_STRING(STRUCT(
        drill_routine AS drill_id, drill_date AS run_date,
        p1_alert_found AS p1_alert_found, p2_alert_found AS p2_alert_found,
        floor_blank_key_raised AS floor_blank_key_raised,
        floor_short_summary_raised AS floor_short_summary_raised)));
  ELSE
    -- (6) LAST, after cleanup -- 'completed' so step (4)'s DELETE (which spares 'completed') keeps
    -- this as the durable record, and so this row itself cannot feed P1's escalation (blank error_msg
    -- on a completed row raises nothing) or this drill's own Part B FIRE_DRILL% exclusion is moot
    -- either way since the routine is excluded from state.run_log_unalerted_problems entirely.
    CALL `stock-trading-498512.ops.sp_log_run`(
      drill_routine, drill_date, 'completed', NULL, NULL, 1, NULL,
      'P1 write-time escalation, P2 issue reporting, and both ops.sp_report_run_issue refusal floors all fired correctly this run; synthetic alert and run_log rows were cleaned up before this record was written.');
  END IF;

  EXCEPTION WHEN ERROR THEN
    -- Clean up first, unconditionally: a stranded synthetic row is a fake run-outcome alert sitting in
    -- a live alert table, or a fake failed run sitting in ops.run_log. Warning-severity alert rows
    -- cannot halt trading (F6) and a stray 'failed' run_log row for a FIRE_DRILL% routine is excluded
    -- from every consumer that matters (Part B; the run_log_unpaired_terminal chain) -- but leaving
    -- either behind would still be wrong, and this drill is the thing supposed to prove this path is
    -- trustworthy.
    --
    -- EACH statement below is wrapped in its OWN BEGIN...EXCEPTION, the same isolation applied to step
    -- (4)'s main-path cleanup above and, in spirit, to the outer BEGIN...EXCEPTION this whole procedure
    -- is already modelled on from ops.sp_fire_drill_roster_notice (bigquery/134). roster_notice's own
    -- cleanup never needed this -- its step (e) is a single DELETE, nothing to bundle. Here, we are
    -- ALREADY inside the abort handler with no further net beneath it: if the UPDATE below threw
    -- unguarded, the two DELETEs would never run AND the CALL ops.sp_raise_alert below would never run
    -- either, so a routine failing for a completely unrelated reason (a transient, a quota) would
    -- silently strand a synthetic alert/run_log row with NO failure notification anywhere -- the exact
    -- defect this guarding closes. Isolating each statement guarantees the other two cleanup statements,
    -- and the final CALL ops.sp_raise_alert, still run even if one (or all three) of these throw.
    BEGIN
      UPDATE `stock-trading-498512.ops.alerts`
      SET notified_ts = CURRENT_TIMESTAMP()
      WHERE category IN ('routine_run_failed', 'routine_run_warning')
        AND JSON_VALUE(payload, '$.routine') = drill_routine
        AND notified_ts IS NULL;
    EXCEPTION WHEN ERROR THEN
      SELECT @@error.message;
    END;

    BEGIN
      DELETE FROM `stock-trading-498512.ops.alerts`
      WHERE category IN ('routine_run_failed', 'routine_run_warning')
        AND JSON_VALUE(payload, '$.routine') = drill_routine;
    EXCEPTION WHEN ERROR THEN
      SELECT @@error.message;
    END;

    BEGIN
      DELETE FROM `stock-trading-498512.ops.run_log`
      WHERE routine = drill_routine AND status <> 'completed';
    EXCEPTION WHEN ERROR THEN
      SELECT @@error.message;
    END;

    CALL `stock-trading-498512.ops.sp_raise_alert`(
      'critical', 'ops.sp_fire_drill_run_outcome_notification', 'run_outcome_fire_drill_failed',
      CONCAT('The run-outcome-notification fire drill ABORTED with an error: ', @@error.message,
             '. The run-failure/in-run-issue notification path is UNPROVEN until this drill passes -- ',
             'do not assume a failed or halted routine run, or an in-run issue report, would reach ',
             'an alert or the inbox.'),
      TO_JSON_STRING(STRUCT(drill_routine AS drill_id, @@error.message AS error_message, 'aborted' AS failure_mode)));
  END;
END;

-- ============================================================================
-- state.run_log_unalerted_problems — P3. Independent witness for P1's own write-time escalation.
--
-- WHY THIS EXISTS AT ALL. P1 (ops.sp_log_run above) raises routine_run_failed / routine_run_warning
-- from INSIDE a BEGIN...EXCEPTION WHEN ERROR THEN...END best-effort block, by design (C8 -- an
-- alerting failure must never propagate out of run logging, and the terminal run_log row has already
-- landed unconditionally by the time that block runs). The direct cost of that design is that a raise
-- which itself throws (a malformed payload, a transient BigQuery error, a future edit that breaks the
-- CONCAT) is SILENT: the EXCEPTION handler swallows it and nothing downstream is told. This view is
-- what re-checks, from OUTSIDE that handler, whether every terminal problem row actually got an
-- alert -- exactly the same "swallowed raise" concern bigquery/170's own header already accepted for
-- the blank-note guard's identical BEGIN...EXCEPTION shape, closed here for the run-outcome case.
--
-- WHAT COUNTS AS A "PROBLEM" ROW, matching P1's own two trigger conditions exactly (so this view can
-- never flag a row P1 was never even supposed to alert on): a terminal ops.run_log row in the
-- trailing 14 days that is EITHER status IN ('failed', 'halted') OR (status = 'completed' AND its
-- error_msg is non-blank after TRIM). 14 days, not P1's own incident day, deliberately WIDER than the
-- 3-day window bigquery/147's run_log_note_missing / bigquery/172's run_log_start_row_missing use for
-- their own record-only sweeps: those two are audit-hygiene checks on a gap that heals only by
-- happening to not recur, while this view exists specifically to catch a SWALLOWED raise -- a rarer
-- event that deserves a longer look-back before this backstop gives up on a row, at negligible cost
-- (ops.run_log's INSERT is append-only and the view is a plain filtered SELECT, not an aggregate
-- whose cost scales with window width in any way that matters here).
--
-- THE ANTI-JOIN, AND WHY IT CANNOT CRY WOLF. NOT EXISTS an ops.alerts row in
-- ('routine_run_failed', 'routine_run_warning') whose payload names the SAME (routine, run_date) --
-- matched on JSON_VALUE(payload, '$.routine') = run_log.routine AND
-- JSON_VALUE(payload, '$.run_date') = CAST(run_log.run_date AS STRING). PAYLOAD, deliberately, NOT
-- the alert's message text: both P1 and P2 (ops.sp_report_run_issue) write routine/run_date verbatim
-- into their payload as an exact STRING/DATE-cast pair (see each procedure's TO_JSON_STRING(STRUCT(...))
-- call above), so this is an EXACT equality match with no risk of the substring collision a
-- message-text LIKE match would carry -- e.g. a routine literally named 'D2' would falsely match
-- inside an alert raised for 'D2a' under a LIKE '%D2%' scheme; exact payload-field equality cannot.
-- Matched WITHOUT any `NOT a.resolved` filter and against BOTH categories -- keying on "no alert EVER
-- raised", not "no OPEN alert", is the single load-bearing design choice in this whole view: both
-- routine_run_failed and routine_run_warning sit on ops.sp_sq_cadence_check's number 14 auto-age
-- allowlist (added in the SAME change as this view) and so CLOSE THEMSELVES after 7 days by design
-- (C3 -- they are receipts for a past event, not a re-checkable condition). An anti-join scoped to
-- `NOT resolved` would therefore make this backstop re-fire on every routine, HEALTHY auto-age
-- closure of the very alert it exists to confirm was raised -- crying wolf nightly on the normal
-- lifecycle of its own evidence, for every problem row still inside this view's 14-day window when
-- its alert ages out at 7 days. Matching on "ever raised, resolved or not" makes a genuinely
-- successful P1/P2 raise permanently satisfy this anti-join regardless of what auto-age does to it
-- afterward, so the ONLY way a row appears here is if no alert was ever recorded for it at all.
CREATE OR REPLACE VIEW `stock-trading-498512.state.run_log_unalerted_problems` AS
SELECT
  r.run_id,
  r.routine,
  r.run_date,
  r.status,
  r.log_ts,
  SUBSTR(TRIM(COALESCE(r.error_msg, '')), 1, 400) AS error_detail,
  CURRENT_TIMESTAMP() AS checked_at
FROM `stock-trading-498512.ops.run_log` r
WHERE r.run_date >= DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 14 DAY)
  -- FIX 3 addition (bigquery/231_run_outcome_notification_fire_drill.sql, 2026-09-08). FIRE_DRILL%
  -- rows are EXCLUDED here, not merely cleaned up after the drill runs -- so
  -- ops.sp_fire_drill_run_outcome_notification (bigquery/231) aborting BETWEEN inserting its
  -- synthetic 'failed' row (P1 exercise) and its own unconditional cleanup cannot make this
  -- backstop cry wolf about a stray drill row. Every other run_log-based check in this repo
  -- already special-cases FIRE_DRILL% for the identical reason (state.run_log_unpaired_terminal's
  -- chain: bigquery/172_run_log_unpaired_terminal.sql, 186_monitor_promoted_autoage.sql,
  -- 205_alert_message_stability.sql, 227_alert_message_stability_ordering.sql) -- this view was the
  -- one left unprotected, closed here.
  AND r.routine NOT LIKE 'FIRE_DRILL%'
  AND (
    r.status IN ('failed', 'halted')
    OR (r.status = 'completed' AND TRIM(COALESCE(r.error_msg, '')) != '')
  )
  AND NOT EXISTS (
    SELECT 1
    FROM `stock-trading-498512.ops.alerts` a
    -- CATEGORY IS PAIRED TO THE ROW'S STATUS CLASS, not left as a two-element IN (...) — corrected
    -- 2026-09-08 during this file's own adversarial review, before landing. With a bare
    -- `category IN ('routine_run_failed','routine_run_warning')`, a routine that HALTED and then
    -- re-ran and logged `completed` with an `error_msg` on the SAME day had its second row's
    -- witness satisfied by the FIRST row's `routine_run_failed` alert — so a genuinely swallowed
    -- `routine_run_warning` raise (the exact thing this view exists to catch) read as covered.
    -- P1 raises `routine_run_failed` for failed/halted and `routine_run_warning` for
    -- completed-with-error, so the witness must ask for the category that row should have produced.
    WHERE a.category = IF(r.status IN ('failed', 'halted'), 'routine_run_failed', 'routine_run_warning')
    -- P1-SOURCED ALERTS ONLY. ops.sp_report_run_issue (P2 above) also raises `routine_run_warning`
    -- for a (routine, run_date), and its payload is the ONLY one of the two that carries
    -- `issue_key` — so that key is the discriminator. A routine voluntarily reporting an in-run
    -- issue is not evidence that sp_log_run's MECHANICAL raise fired, and letting a P2 row satisfy
    -- this witness would mask precisely the swallowed-raise case (C8) this view is the third
    -- independent check for.
      AND JSON_VALUE(a.payload, '$.issue_key') IS NULL
      AND JSON_VALUE(a.payload, '$.routine') = r.routine
      AND JSON_VALUE(a.payload, '$.run_date') = CAST(r.run_date AS STRING)
    -- DELIBERATELY NOT KEYED ON run_id, though P1's payload carries one and an exact per-row match
    -- looks stricter. `sp_raise_alert_once` dedups on (category, message): two identical failures
    -- of the same routine on the same day render the SAME message, so the second raise is
    -- correctly SUPPRESSED and no alert ever carries the second run_id. A run_id-keyed witness
    -- would therefore flag that second row as unalerted every night for 14 days — a permanently-red
    -- advisory, which this repo treats as broken (feedback: a permanently-red advisory is broken).
    -- One alert per (routine, run_date, status class) IS the intended delivery, and this predicate
    -- asks exactly that question.
    -- NOT filtered on `NOT resolved`: P1's alerts auto-age out after 7 days (#14 allowlist), and
    -- keying on open-ness would make this view re-raise forever once they close.
  );

-- ============================================================================
-- ops.sp_sq_fire_drill_alert_lifecycle — PART C. SUPERSEDES bigquery/134's definition. SQ_VERSION
-- v3 -> v4. Body generated by PROGRAMMATIC exact-string replacement against the live v3 body
-- (bigquery/134_roster_change_notifications.sql:468-474), never retyped -- EXACTLY TWO replacements:
-- the heartbeat literal 'v3' -> 'v4', and a new CALL ops.sp_fire_drill_run_outcome_notification();
-- inserted immediately after the existing CALL ops.sp_fire_drill_roster_notice(); line, before END;.
-- No other drill logic changed. Runs monthly (~06:20 UTC on the 1st) via the frozen one-line console
-- body in bigquery/scheduled_queries/fire_drill_alert_lifecycle.sql -- that file needs NO re-paste,
-- since it already just CALLs this wrapper.
-- The matching expected-version bump lives in bigquery/63_scheduled_query_version_registry.sql
-- (sq_name='fire_drill_alert_lifecycle', v3 -> v4); apply that MERGE too, or
-- state.scheduled_query_version_drift reports a drift on the next cadence_check pass (self-healing
-- since bigquery/111 added the category to the #14 auto-age list, but avoidable noise).
-- ============================================================================
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_sq_fire_drill_alert_lifecycle`()
BEGIN
  CALL `stock-trading-498512.ops.sp_beat_heartbeat`('sq:fire_drill_alert_lifecycle', 'v4', 'fire_drill_alert_lifecycle.sql ran');
  CALL `stock-trading-498512.ops.sp_fire_drill_alert_latch`();
  CALL `stock-trading-498512.ops.sp_fire_drill_alert_resolve`();
  CALL `stock-trading-498512.ops.sp_fire_drill_roster_notice`();
  CALL `stock-trading-498512.ops.sp_fire_drill_run_outcome_notification`();
END;

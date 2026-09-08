-- 170_run_log_note_write_time_guard.sql (2026-08-14)
-- Project: stock-trading-498512. Apply after 169_position_metadata_carry_forward.sql.
-- Touches ops.sp_log_run (rewritten) and adds ops.sp_amend_run_note (new). No view changes, no
-- scheduled-query version bump -- ops.sp_sq_cadence_check is NOT edited here, so bigquery/63 stays at
-- cadence_check v19 and there is no partial-apply pair to reconcile.
--
-- ===== WHY =====
-- Alert c26afde4-fdc3-4799-996b-390a42826f4d, run_log_note_missing, raised 2026-08-13 23:15:56 MT for
-- D2a/2026-08-13. Investigated 2026-08-14.
--
-- The run itself was healthy. D2a wrote a complete, monotonically-timestamped chain that day: park
-- sweep sweep-VOO-20260813 crafted 16:56:47 MT (the 2026-08-12 sweep deferred by the IBKR snapshot
-- outage, recovering), ops.account_snapshot nav=16219.78 at 16:56:29, 13 daily_marks + 13 signal_marks,
-- 4 TECHNICAL_SIGNAL regime_events at 16:57:31, perf.strategy_daily recompute at 16:58:32 -- all inside
-- the 16:52:58-17:01:50 window, all with sane values. rows_written=26 ties out exactly as 0 fills +
-- 13 daily_marks + 13 signal_marks. Nothing was lost except the account of it.
--
-- The proximate cause is not inferred, it is the literal statement text from JOBS_BY_PROJECT:
--   CALL `stock-trading-498512.ops.sp_log_run`(
--     'D2a', DATE '2026-08-13', 'completed', 'session_01AvRB6bohcmasxxTSuVHPLy',
--     'detached-62fccc3', 26, NULL, NULL);
-- The session typed the SQL keyword NULL into the 8th (note) argument and the procedure accepted it
-- silently. There was no error, no retry, no escaping failure, no partial insert -- one clean job.
--
-- ===== WHAT WAS ACTUALLY MISSING =====
-- Two independent holes, both closed (the prose half lands in Claude_Task_Plan.md in the same commit):
--
--   1. PROSE. D2 and D2a each carry a routine-local "RUN LOGGING (every run)" bullet, ~580 lines (D2a)
--      and ~1,550 lines (D2) AFTER the OPERATING MODEL preamble rule that makes <note> mandatory. Both
--      local bullets named only rows_written and were silent on <note>. That local bullet is the text a
--      session actually re-reads at the moment it logs. D1 and D3 have no such duplicate bullet -- and
--      D2+D2a produced 8 of the 11 blank-note terminal rows in the trailing 120 days (11 of 567 overall,
--      all in D1/D2/D2a). Both bullets now spell out the 8-argument terminal call.
--
--   2. MECHANISM. ops.sp_log_run had zero validation: a bare INSERT of its arguments. ops.run_log.note
--      is nullable and BigQuery has no CHECK constraints, so the procedure body was the only place this
--      could ever be enforced, and it enforced nothing. The sole existing control -- bigquery/147s
--      state.run_log_content_gaps + the run_log_note_missing warning inside ops.sp_sq_cadence_check --
--      is detection-only and runs at 23:15 MT, up to ~6h after the offending write, by which time the
--      session that could explain the run is gone. That is why bigquery/147s header calls the gap
--      "NOT REPAIRABLE after the fact"; the fix below is what makes it repairable, by moving the signal
--      to write time while the session is still alive.
--
-- ===== WHY THIS DOES NOT RAISE =====
-- The obvious hardening is IF note is blank THEN RAISE, refusing the write. That is REJECTED here, and
-- deliberately, because it inverts severity on a capital-affecting path:
--   * A refused terminal write leaves the routine with a started row and no terminal row.
--   * state.cadence_watch then reports the routine as not-completed-today, and ops.sp_sq_cadence_check
--     raises missed_run at CRITICAL.
--   * state.trading_enabled reads open criticals. A missing NOTE -- an audit-hygiene defect the detector
--     itself classifies as record-only, explicitly not a reason to halt anything -- would become a
--     trading halt.
--   * ops.sp_auto_resolve_alerts Rule 2 clears missed_run off ops.run_log evidence, which is exactly the
--     row the RAISE suppressed, so it would not self-heal; and D2a commits nothing most days, so
--     ops.sp_backfill_run_log_from_markers has no commit marker to recover from either.
-- This project has already paid for that class of mistake once: the 2026-08-04 dust false positive, a
-- $0.20 rounding artifact, halted all trading. A note is worth less than that, not more.
--
-- So the row ALWAYS lands. What changes is that the blank note stops being silent:
--   (a) the SAME run_log_note_missing alert the nightly check would have raised is raised NOW, at write
--       time. sp_raise_alert_once dedups on (category, message) while unresolved and the message string
--       below is byte-identical to the one in ops.sp_sq_cadence_check, so the write-time raise and the
--       23:15 raise COLLAPSE ONTO ONE ROW rather than producing two. The message is also literally true
--       from here: a row written just now is trivially "in the trailing 3 days". If that string is ever
--       edited in ops.sp_sq_cadence_check, edit it here in the same commit or the two paths will start
--       opening separate alerts.
--   (b) the caller gets a result set it cannot miss, naming the run_id and the exact repair call.
-- The note column is left genuinely NULL. state.run_log_content_gaps still sees this row exactly as it
-- does today -- no sentinel string, no placeholder, nothing that would make the existing detector read
-- green on a row that is still blank. The detector is not weakened, softened, or worked around.

-- SUPERSEDED (2026-09-08) by bigquery/230_run_outcome_notification.sql, the current canonical
-- definition of ops.sp_log_run. 230 leaves the unconditional INSERT (C8) and the existing blank-note
-- guard byte-identical, and adds -- AFTER the guard, in its own BEGIN...EXCEPTION WHEN ERROR
-- THEN...END best-effort block -- a write-time escalation: a terminal row logging failed/halted
-- raises routine_run_failed, and a completed row carrying a non-blank error_msg raises
-- routine_run_warning (both severity 'warning', never critical -- C1). See bigquery/230's header for
-- the owner directive and the audit that motivated it. Kept here, unmodified, for DR-rebuild
-- apply-in-order reference only. DO NOT re-apply this CREATE statement live in isolation.
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_log_run`(
  in_routine STRING, in_run_date DATE, in_status STRING, in_session STRING,
  in_branch STRING, in_rows INT64, in_error STRING, in_note STRING)
BEGIN
  DECLARE note_missing BOOL DEFAULT FALSE;
  -- Generated HERE, before the INSERT, and written explicitly into the run_id column rather than left
  -- to that column's GENERATE_UUID() default. This is the only reason the column is named in the INSERT
  -- list at all, and it is load-bearing: it is what lets the guard below name THIS row with certainty.
  -- The rejected alternative was to let the default fire and then re-read the row back with
  -- (routine, run_date, status, note IS blank) ORDER BY log_ts DESC LIMIT 1. That re-read is a
  -- heuristic, not an identity: ops.run_log holds 33 historical duplicate (routine, run_date, status)
  -- terminal tuples, the INSERT and the re-read are separate BigQuery jobs with no transaction spanning
  -- them, and two sessions terminal-logging the same tuple with blank notes in that window would make
  -- the re-read return the OTHER session's row -- telling a session to repair a row that is not its own
  -- while its own stays blank. No such double-blank pair has ever occurred, but the ambiguity costs
  -- nothing to delete outright, so it is deleted rather than documented.
  DECLARE logged_run_id STRING DEFAULT GENERATE_UUID();

  -- UNCONDITIONAL AND FIRST. Every later statement in this procedure is advisory. Nothing below may
  -- prevent, delay or condition this INSERT -- see the WHY THIS DOES NOT RAISE header note.
  INSERT INTO `stock-trading-498512.ops.run_log`
    (run_id, routine, run_date, status, session_id, branch, rows_written, error_msg, note)
  VALUES (logged_run_id, in_routine, in_run_date, in_status, in_session, in_branch, in_rows, in_error, in_note);

  -- 'started' rows legitimately carry no note (the narrative belongs on the paired terminal row), so the
  -- guard is scoped to terminal statuses only. A NULL in_status yields NULL here, and IF NULL takes the
  -- false branch -- correct, since a NULL status is not a terminal status.
  SET note_missing = (
    in_status IN ('completed', 'failed', 'halted')
    AND (in_note IS NULL OR TRIM(in_note) = '')
  );

  IF note_missing THEN
    -- Best-effort. An alerting failure must never propagate out of run logging: the row above has
    -- already landed and the caller-visible notice below is the backstop that does not depend on
    -- ops.alerts being writable at all.
    BEGIN
      CALL `stock-trading-498512.ops.sp_raise_alert_once`(
        'warning', 'ops.sp_log_run', 'run_log_note_missing',
        'Terminal run_log row(s) with no note in the trailing 3 days — a routine logged completed/failed/halted without recording what it did. See payload for the affected routine/run_date rows.',
        TO_JSON_STRING([STRUCT(
          in_routine AS routine,
          in_run_date AS run_date,
          in_status AS status,
          logged_run_id AS run_id)]));
    EXCEPTION WHEN ERROR THEN
      SELECT @@error.message AS sp_log_run_alert_error;
    END;

    -- The whole point of moving this to write time: the session is STILL ALIVE and still holds the only
    -- copy of its own reasoning. Say so, name the row, and give the exact call that repairs it.
    SELECT
      CONCAT(
        'BLANK NOTE ON A TERMINAL run_log ROW. The row was written (it is never withheld), but ',
        in_routine, '/', CAST(in_run_date AS STRING), ' status=', in_status,
        ' recorded NO account of what this run did. <note> is MANDATORY on completed/failed/halted ',
        '— see the OPERATING MODEL preamble in Claude_Task_Plan.md. A no-op run needs it MORE than a ',
        'busy one, because "nothing happened" and "the run was abbreviated and did not notice" are ',
        'indistinguishable without it. REPAIR THIS NOW, in this session, while you still remember the ',
        'run — nobody can reconstruct your reasoning after it ends: ',
        'CALL `stock-trading-498512.ops.sp_amend_run_note`("', logged_run_id,
        '", "<your real narrative note>");'
      ) AS sp_log_run_warning;
  END IF;
END;

-- ops.sp_amend_run_note -- the ONLY sanctioned way to put a note on a terminal row after the fact, and
-- deliberately a narrow one. It exists so that the write-time notice above has a repair action that is
-- auditable and bounded, instead of leaving each session to compose its own raw UPDATE against
-- ops.run_log (which is not under the append-only guard -- events.* only, per state.append_only_integrity
-- and RUNBOOK §30 -- and so would otherwise be unconstrained).
--
-- THIS IS NOT A HISTORY-REWRITING TOOL, and is built so it cannot become one:
--   * FILL-ONLY. The predicate requires the note to be blank right now, in both the guard and the UPDATE
--     WHERE clause. A row that already has a note can never be altered through here, so no existing
--     account can be overwritten, softened or contradicted.
--   * TERMINAL ROWS ONLY. 'started' rows are not eligible; their blank note is correct.
--   * SIX HOURS. log_ts must be within 6h of now. This is the load-bearing constraint and it is time-
--     based, not calendar-based, on purpose: it encodes "the routine repairing its own row while its
--     session is still running", which is the only case where the note can be a truthful first-person
--     account. Every routine in this fleet completes far inside 6h. A later session finding an old blank
--     note CANNOT use this procedure, and must not: it would be reconstructing facts from the tables and
--     presenting them as the routine's own reasoning, which is a different and worse thing than a hole.
--     The D2a/2026-08-13 row that prompted this file is ~20h old and is therefore, correctly, out of
--     reach of it -- that row stays blank and its alert ages out on the bigquery/147 #14 sweep, exactly
--     as that file intends.
--   * 40-CHARACTER FLOOR. A placeholder that merely defeats the detector is worse than the blank it
--     replaces, because the blank is at least honest. The floor is far below the 71-char minimum of any
--     genuine terminal note measured across the trailing 120 days, so it can only catch degenerate input.
--   * STAMPED. The amendment is recorded in the note itself. The stamp is APPENDED, never prepended:
--     bigquery/89 excludes self-healed rows from the routine-health completion percentiles with a regex
--     anchored on '^(auto-)?backfilled', and a prefix here would sit in front of exactly the text that
--     regex inspects.
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_amend_run_note`(
  in_run_id STRING, in_note STRING)
BEGIN
  DECLARE eligible BOOL DEFAULT FALSE;

  IF in_note IS NULL OR LENGTH(TRIM(in_note)) < 40 THEN
    RAISE USING MESSAGE =
      'ops.sp_amend_run_note REFUSED: in_note must be a real narrative of at least 40 characters. A placeholder that only silences the detector is worse than the blank note it replaces.';
  END IF;

  SET eligible = EXISTS (
    SELECT 1
    FROM `stock-trading-498512.ops.run_log`
    WHERE run_id = in_run_id
      AND status IN ('completed', 'failed', 'halted')
      AND (note IS NULL OR TRIM(note) = '')
      AND log_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 6 HOUR));

  IF NOT eligible THEN
    RAISE USING MESSAGE =
      'ops.sp_amend_run_note REFUSED: no eligible row. The target run_id must exist, be a terminal row (completed/failed/halted), still have a blank note, and have been logged within the last 6 hours. This procedure fills a hole left by the run that is still in progress; it does not rewrite history, and it cannot supply a first-person account for a session that has already ended.';
  END IF;

  UPDATE `stock-trading-498512.ops.run_log`
  SET note = CONCAT(
    in_note,
    FORMAT(
      ' [NOTE AMENDED %s MT via ops.sp_amend_run_note (bigquery/170): the terminal row was first written with a blank note and this narrative was supplied by the same run, in-session, within the 6h window.]',
      FORMAT_TIMESTAMP('%F %T', CURRENT_TIMESTAMP(), 'America/Denver')))
  WHERE run_id = in_run_id
    AND status IN ('completed', 'failed', 'halted')
    AND (note IS NULL OR TRIM(note) = '')
    AND log_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 6 HOUR);
END;

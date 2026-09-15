-- ============================================================================
-- 230 — RUN-OUTCOME NOTIFICATION: give the remote-routine fleet a mechanical, no-agent-cooperation
--       path from "a run failed / completed with a warning" to the owner's inbox, instead of the
--       chat-only reporting the owner had to ask for a replacement for (2026-09-08).
--
-- Project: stock-trading-498512. Apply after 229_staged_order_confirm_notice.sql.
--
-- OWNER DIRECTIVE (2026-09-08, verbatim): "for the remote routines, they have a pathway to send me
-- an email for any incomplete runs or even if run is complete but there are warnings or errors? if
-- not, we should add that feature rather than just having them paste those in chat (since chat won't
-- be read or monitored)".
--
-- ===== WHAT A 34-AGENT AUDIT MEASURED BEFORE THIS FILE WAS WRITTEN (2026-09-08; not re-derived) =====
--
-- FACT 1 — the INCOMPLETE-run half already works, but BY CONSEQUENCE, not by construction. All 52
-- ops.run_log rows with status IN ('failed','halted') in the trailing 90d had >=1 matching ops.alerts
-- row that WAS emailed (notified_ts NOT NULL) -- 100%. That coverage comes from three independent
-- things happening to line up (a routine's own cause-specific alert, missed_run CRITICAL from
-- state.cadence_watch, routine_stalled WARNING from state.stalled_runs), and NONE of them is a
-- dedicated "your run failed" notice.
--
-- FACT 2 — there is NO mechanical link between a failed run and an alert. ops.sp_log_run (canonical
-- body bigquery/170_run_log_note_write_time_guard.sql before this file) branches on exactly ONE
-- thing: whether note is blank. It never inspects in_status and never inspects in_error. The pairing
-- "raise an alert AND log halted" was PROSE ONLY (Claude_Task_Plan.md) -- nothing anywhere
-- cross-referenced a failed/halted run_log row against an alert row.
--
-- FACT 3 — ops.run_log.error_msg was WRITE-ONLY. Confirmed by an exhaustive grep across bigquery/,
-- dbt/, scripts/, ops/*.gs: no view, procedure, scheduled query, dbt model, python script or .gs file
-- ever read it. A routine could log a perfect diagnostic and it reached nobody.
--
-- FACT 4 — the COMPLETED-with-warnings half had NO channel at all. <note> prose is consumed only as
-- presence/absence (bigquery/147 + bigquery/170 check for BLANK, never content); ops/cadence.yaml
-- said so outright ("Nothing consumes run_log prose"). Live keyword scan: 476 of 765 'completed' rows
-- in the trailing 90d contained problem language (error/failed/warning/skipped/stale/degraded/...)
-- with no alert raised for any of them.
--
-- FACT 5 — severity 'info' reaches NOTHING. 104 of 104 info alerts raised in the trailing 90d have
-- notified_ts IS NULL -- alert_emailer.gs's SEVERITIES list and scripts/alert_relay.py both filter it
-- out before delivery.
--
-- FACT 6 — cadence detection latency. missed_run and routine_stalled are BOTH evaluated only by the
-- single daily ~05:15 UTC cadence_check scheduled query, so a routine that dies mid-morning can wait
-- up to ~17-19h for any email via that path alone.
--
-- ===== THE FIX, FOUR PIECES, ALL IN THIS ONE FILE =====
--
-- P1 (ops.sp_log_run, rewritten) — closes FACT 2 + FACT 3. A best-effort block, added AFTER the
-- existing blank-note guard and in its OWN BEGIN...EXCEPTION WHEN ERROR THEN...END (never the guard's
-- handler -- an alerting failure in one must never take the other down, and the unconditional INSERT
-- above both stays first and untouched, C8): a terminal row logging failed/halted raises
-- routine_run_failed; a completed row carrying a non-blank error_msg raises routine_run_warning. This
-- needs ZERO agent cooperation -- every routine already calls sp_log_run, so a session that hard-stops
-- in a way no hand-written hard-stop list anticipated, or that dies near a usage-limit cutoff without
-- its own sp_raise_alert call, is now covered mechanically instead of by prose discipline.
--
-- P2 (ops.sp_report_run_issue, new) — closes FACT 4, and is the actual replacement for "paste it in
-- chat". A routine that completes normally but wants to report an in-run issue (a rate-limit, a
-- degraded connector, a calendar-vs-currentDate disagreement) calls this instead of leaving it in a
-- note nobody reads or a chat transcript nobody monitors. Severity is FIXED at 'warning' -- not a
-- caller-supplied parameter -- which removes the accidental-trading-halt footgun (C1) entirely: there
-- is no argument a caller could pass that turns this into a halt.
--
-- P3 (state.run_log_unalerted_problems, new view) — the backstop for the one place P1 can still go
-- silent: its own BEGIN...EXCEPTION handler (C8) swallows a raise that itself throws. This view is an
-- INDEPENDENT WITNESS, evaluated from OUTSIDE that handler on the next cadence_check pass, over
-- whether every terminal problem row in the trailing 14 days ever got a matching alert AT ALL --
-- keyed on "no alert EVER raised" (resolved or not), never "no OPEN alert", because P1's own
-- categories sit on the number 14 auto-age allowlist and would otherwise re-trip this backstop every
-- time a healthy alert aged out on schedule. See the view's own header for the exact anti-join.
--
-- P4 (ops.sp_sq_cadence_check, v21 -> v22) — wires P3's independent witness into the nightly sweep:
-- adds the three new categories to the number 14 auto-age allowlist (C3 -- these are RECEIPTS for a
-- past event, the same monitor_promoted shape bigquery/186 established, with no re-checkable "it
-- healed" condition, so an ops.alert_policy resolve_rule is the wrong tool) and a new record-only
-- WARNING block reading state.run_log_unalerted_problems, placed immediately before the consolidated
-- RAISE. Generated by PROGRAMMATIC EXACT-STRING REPLACEMENT against bigquery/227's live v21 body (C6)
-- -- three edits, each verified to match its anchor EXACTLY ONCE before being shipped (see this
-- file's landing notes / the task return value for the replacement counts). The paired
-- bigquery/63_scheduled_query_version_registry.sql MERGE-seed row for cadence_check is bumped to v22
-- IN THE SAME CHANGE, procedure first -- the convention every prior cadence_check bump in this repo
-- follows (bigquery/63's own git_note is the single source of that history; see its v6 entry, added
-- by bigquery/229, for the most recent worked example). Applying only the registry row would set
-- expected_version='v22' while a live v21 procedure keeps beating 'v21', raising a nightly
-- scheduled_query_version_drift warning until the pair is reconciled -- the partial-apply trap
-- bigquery/63's header documents throughout.
--
-- ===== DESIGN CONSTRAINTS HONORED (verbatim labels from the design review this file implements) =====
--
-- C1 SEVERITY IS 'warning', NEVER 'critical', on every new category. An open critical feeds
--    state.trading_enabled's blocking_criticals (bigquery/107 lineage) and halts order staging
--    fleet-wide; a failed W3 or SL5 run has nothing to do with capital safety. missed_run already
--    covers the capital-relevant daily-tier case at critical and is untouched here.
--
-- C2 MESSAGE DEDUP STABILITY, AND THE ONE PLACE THIS FILE DELIBERATELY TRADES IT AWAY.
--    sp_raise_alert_once dedups on EXACT (category, message) equality over unresolved rows
--    (bigquery/10_observability.sql). P1's and P2's messages embed (routine, run_date, status) /
--    (routine, run_date, issue_key) -- stable for the incident -- AND ALSO the caller-supplied
--    <detail> / <summary> free text. That second half is NOT stable, and saying otherwise would be
--    a falsehood in a file whose own registry note (bigquery/63, v18) exists to retract one.
--
--    THE DEDUP UNIT IS THEREFORE "one alert per DISTINCT REPORTED REASON", not "one per (routine,
--    run_date)". This is a deliberate trade, not an oversight, and it is FORCED: ops/monitoring/
--    alert_emailer.gs renders `payload` ONLY for the six ROSTER_NOTICE_CATEGORIES, so for every
--    category in this file the MESSAGE is the only text that reaches the owner's inbox. Detail in
--    the payload would satisfy dedup perfectly and email the owner "D2 logged halted for run_date
--    2026-09-08." with no way to learn why -- which is precisely the thing the 2026-09-08 owner
--    directive asked to fix. An informative email is the requirement; per-(routine, run_date)
--    dedup is not.
--
--    MEASURED COST, so nobody re-litigates this on intuition: over the 52 failed/halted rows in
--    ops.run_log's whole history, exactly THREE (routine, run_date, status) tuples were logged
--    twice with DIFFERENT error_msg text (D2/2026-07-08, D3/2026-07-14, D3/2026-07-25) -- about
--    1.5 per month. In each, the two texts were genuinely different diagnoses of two different
--    attempts (D2/2026-07-08: "blocking criticals missed_run(07-07)+staleness" vs "3 open critical
--    alerts (missed_run 07-08 [D1/D2/D3])"), so the second email carried real information rather
--    than repeating the first. That is the whole exposure: at most a second, differently-worded
--    email on the rare same-day re-log.
--
--    DO NOT "FIX" THIS BY MOVING <detail> INTO THE PAYLOAD. It looks like the bigquery/205 pattern
--    and it is not: 205's sites are DETECTOR alerts whose message names a stable CONDITION the
--    operator then queries for detail, whereas these three categories exist to BE the operator's
--    notification. Moving the detail out silences the email while leaving the alert row looking
--    healthy -- the exact "corrections must land where the reader actually reads" failure this
--    repo has hit before. The genuine no-counter/no-timestamp/no-unordered-aggregate rule still
--    binds the STABLE half of every message here, and nothing embeds an aggregate except:
--    The one STRING_AGG this file adds (P4's run_log_problem_unalerted block) carries a
--    TOTAL order -- (routine, run_date, status, run_id), run_id being a per-INSERT GENERATE_UUID() -- per
--    bigquery/227's own STRING_AGG-ordering rule, the exact rule this file's own P4 edit is landing
--    inside of.
--
-- C3 CLOSURE PATH is the cadence_check number 14 auto-age allowlist, NOT an ops.alert_policy row, for
--    all three new categories (routine_run_failed, routine_run_warning, run_log_problem_unalerted).
--    Each is a RECEIPT FOR A PAST EVENT (the run failed; that fact is permanent) with no mechanically
--    re-checkable "it healed" condition -- exactly the monitor_promoted shape bigquery/186 already
--    established, and the durable record is ops.run_log itself; ops.alerts is only the announcement.
--
-- C4 PUSH POLICY. This file is BigQuery-side only and does not touch scripts/alert_relay.py's
--    NO_PUSH_CATEGORIES (frozen, per-CLAUDE.md, to exactly the six roster categories) or any push
--    routing -- that is a separate change to alert_relay.py (P5 of the design this file implements),
--    outside this file's scope.
--
-- C5 dbt COVERAGE. state.run_log_unalerted_problems is a new state.* view, so
--    scripts/check_dbt_view_coverage.py (BLOCKING, zero backlog) requires a dbt model. Generated by
--    scripts/gen_dbt_port.py (never hand-written) in the SAME change; NOT added to
--    dbt/parity_live_scope.yml (that file's own rule: "the default answer for a newly ported view is
--    NO").
--
-- C6 VERSION LOCK. See the P4 paragraph above.
--
-- C8 sp_log_run's INSERT stays UNCONDITIONAL AND FIRST; the existing blank-note guard is left
--    BYTE-IDENTICAL (this file's ops.sp_log_run body is a PROGRAMMATIC exact-string replacement
--    against bigquery/170's, never retyped). All new logic sits AFTER the guard, in its own
--    BEGIN...EXCEPTION WHEN ERROR THEN...END block, so an alerting failure can never propagate out of
--    run logging.
--
-- ===== SUPERSESSION =====
-- This file is the new single source of truth for ops.sp_log_run (supersedes
-- bigquery/170_run_log_note_write_time_guard.sql for THAT object only -- bigquery/170's
-- ops.sp_amend_run_note is UNTOUCHED and remains canonical there) and for ops.sp_sq_cadence_check
-- (supersedes bigquery/227_alert_message_stability_ordering.sql, SQ_VERSION v21 -> v22, the tail of
-- the chain 75 -> 111 -> 120 -> 128 -> 132 -> 142 -> 147 -> 149 -> 150 -> 153 -> 157 -> 159 -> 172 ->
-- 186 -> 205 -> 227 -> 230). Every file in both chains (bigquery/10 + 170 for sp_log_run; the full
-- cadence_check chain above) gets a new SUPERSEDED marker appended pointing at this file, in the same
-- change, or scripts/check_superseded_markers.py fails the build -- per that checker's rule that a
-- pointer at a now-superseded INTERMEDIATE file does not satisfy the check; the OLD marker on each
-- file (pointing at whichever file was canonical before) is left untouched as the historical record
-- of that earlier transition, never edited in place.
-- ============================================================================

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

  -- ================================================================================================
  -- WRITE-TIME FAILURE/WARNING ESCALATION (P1, bigquery/230_run_outcome_notification.sql, 2026-09-08
  -- owner directive -- "for the remote routines, [is there] a pathway to send me an email for any
  -- incomplete runs or even if run is complete but there are warnings or errors?"). MEASURED before
  -- shipping (34-agent audit, 2026-09-08): every one of ops.sp_log_run's 8 arguments was already
  -- validated for the blank-note case above, but in_status/in_error were never inspected at all -- the
  -- pairing "raise an alert AND log failed/halted" was PROSE ONLY (Claude_Task_Plan.md), and
  -- error_msg was WRITE-ONLY across the entire tree (no view/procedure/script ever read it). A session
  -- that hard-stops in a way its own hard-stop list did not anticipate, or dies near a usage-limit
  -- cutoff having logged 'failed' with no sp_raise_alert call of its own, was covered by NOTHING
  -- mechanical -- only by the incidental overlap of missed_run / routine_stalled / a routine's own
  -- cause-specific alert, which FACT 1 of that audit found covers 100% of the trailing-90d
  -- failed/halted rows by CONSEQUENCE, not by construction.
  --
  -- SEVERITY IS 'warning', NEVER 'critical' (C1). An open critical feeds state.trading_enabled's
  -- blocking_criticals (bigquery/107) and halts order staging fleet-wide -- a failed W3 or SL5 run has
  -- nothing to do with capital safety, and making run-failure critical would mean any routine failure
  -- anywhere self-inflicts a trading outage. missed_run already covers the capital-relevant daily-tier
  -- case at critical and is untouched by this block.
  --
  -- CLOSURE PATH is the cadence_check number 14 auto-age allowlist (bigquery/227 -> 230), NOT an
  -- ops.alert_policy row (C3): both categories below are RECEIPTS FOR A PAST EVENT (the run failed;
  -- that fact is permanent) with no mechanically re-checkable "it healed" condition, exactly the
  -- monitor_promoted shape bigquery/186 already established -- see that file's header and this file's
  -- own header for why an ops.alert_policy resolve_rule is the wrong tool for a receipt.
  --
  -- BEST-EFFORT, in its OWN BEGIN...EXCEPTION block, deliberately separate from the blank-note guard's
  -- BEGIN...EXCEPTION above (C8 -- an alerting failure must never propagate out of run logging; the
  -- INSERT above has already landed regardless of anything below it). A THIRD, independent witness
  -- exists for the case where THIS raise itself throws silently inside this handler:
  -- state.run_log_unalerted_problems (bigquery/230, P3) re-checks from OUTSIDE this swallowing block,
  -- on the next cadence_check pass, whether every terminal problem row in the trailing 14 days ever
  -- got a matching alert at all.
  --
  -- MESSAGE CARRIES routine/run_date/status PLUS <detail>. Re-logging a terminal row with the SAME
  -- reported text dedups; re-logging it with a DIFFERENT reason mints a second alert and a second
  -- email, because <detail> is part of the message and therefore part of sp_raise_alert_once's key.
  -- That is intended and is argued in full at C2 above (the email renders `message` only, so detail
  -- has to live there; measured exposure is ~1.5 same-day re-logs per month, each carrying a
  -- genuinely different diagnosis). Read C2 before changing this line. <detail> falls back error_msg -> note -> a fixed
  -- literal, truncated to 400 chars, and is data flowing through CONCAT/SUBSTR at runtime -- not a
  -- literal typed into this file's own source text -- so an apostrophe inside a routine's real error
  -- text cannot break this statement the way one typed directly into a SQL string literal would
  -- (feedback_bigquery_file_conventions.md trap: GoogleSQL rejects '' as an apostrophe escape).
  BEGIN
    DECLARE v_detail STRING;
    SET v_detail = CASE
      WHEN TRIM(COALESCE(in_error, '')) != '' THEN SUBSTR(TRIM(in_error), 1, 400)
      WHEN TRIM(COALESCE(in_note, '')) != '' THEN SUBSTR(TRIM(in_note), 1, 400)
      ELSE 'no error_msg or note recorded'
    END;

    IF in_status IN ('failed', 'halted') THEN
      CALL `stock-trading-498512.ops.sp_raise_alert_once`(
        'warning', in_routine, 'routine_run_failed',
        CONCAT(in_routine, ' logged ', in_status, ' for run_date ', CAST(in_run_date AS STRING),
               ' — the run did not complete. Reported: ', v_detail),
        TO_JSON_STRING(STRUCT(
          in_routine AS routine, in_run_date AS run_date, in_status AS status,
          logged_run_id AS run_id, in_session AS session_id, in_branch AS branch,
          in_rows AS rows_written, in_error AS error_msg, in_note AS note)));
    ELSEIF in_status = 'completed' AND TRIM(COALESCE(in_error, '')) != '' THEN
      CALL `stock-trading-498512.ops.sp_raise_alert_once`(
        'warning', in_routine, 'routine_run_warning',
        CONCAT(in_routine, ' completed run_date ', CAST(in_run_date AS STRING),
               ' but recorded an error: ', v_detail),
        TO_JSON_STRING(STRUCT(
          in_routine AS routine, in_run_date AS run_date, in_status AS status,
          logged_run_id AS run_id, in_session AS session_id, in_branch AS branch,
          in_rows AS rows_written, in_error AS error_msg, in_note AS note)));
    END IF;
  EXCEPTION WHEN ERROR THEN
    SELECT @@error.message AS sp_log_run_escalation_error;
  END;
END;

-- ============================================================================
-- ops.sp_report_run_issue — P2. The sanctioned channel for "the run completed, but something was
-- off" -- the actual replacement for pasting an observation into chat, which the owner directive
-- above states plainly reaches nobody ("chat won't be read or monitored"). A routine that would
-- previously have written this into <note> (a RECORD nobody reads for content, only for
-- presence/absence -- bigquery/147 + this file's own P1) or into its own chat output now calls this
-- instead, and the observation reaches the owner's inbox the same way every other alert does.
--
-- SEVERITY IS FIXED AT 'warning' -- deliberately NOT a caller-supplied parameter (C1). This is the
-- load-bearing design choice: there is no argument combination a routine could pass that turns an
-- in-run observation into a trading halt. A genuine hard-stop still goes through the existing
-- cause-specific ops.sp_raise_alert_once call with ITS OWN category (missing_dependency,
-- trading_halted, connector, bq_quota_exhausted, ...) -- this procedure is explicitly NOT for that,
-- and callers that need CRITICAL keep using the mechanism they already have.
--
-- REFUSAL STYLE matches ops.sp_amend_run_note (bigquery/170): RAISE with a message naming the
-- procedure, the word REFUSED, and the reason the floor exists -- so a caller sees a loud, specific
-- rejection rather than a silent no-op or a degraded alert.
--
--   * in_issue_key blank/whitespace, or > 64 chars -> REFUSED. This is the sp_raise_alert_once dedup
--     key (folded into the message below), so a blank key can never dedup against itself and a long,
--     instance-specific key defeats the dedup this procedure exists to provide. issue_key MUST name
--     the KIND of issue (e.g. 'fmp_rate_limited'), never the instance (never
--     'fmp_rate_limited_at_14:32') -- an instance-keyed value re-mints a fresh alert (and a fresh
--     email) on every occurrence, which is the exact alert-fatigue defect
--     bigquery/229_staged_order_confirm_notice.sql's item_key convention was written to avoid, and
--     this procedure deliberately copies that convention rather than re-deriving a worse one.
--   * in_summary shorter than 30 non-blank characters -> REFUSED, same reasoning as
--     ops.sp_amend_run_note's 40-character floor: a placeholder that only satisfies the signature is
--     worse than silence, because it looks like a report when it is not one. (30, not 40: a summary
--     is one sentence describing an OBSERVATION, not a first-person narrative of an entire run, so
--     the floor is set lower on purpose -- both floors exist for the identical reason, not the
--     identical number.)
--
-- CATEGORY IS 'routine_run_warning' -- SHARED with P1's completed-with-error case directly above
-- (ops.sp_log_run). One category, one number 14 auto-age allowlist entry, one mental model for "the
-- run was fine but flag this"; issue_key is what distinguishes one instance of it from another inside
-- the message, exactly as item_key distinguishes staged_order_awaiting_confirm instances in
-- bigquery/229.
--
-- MESSAGE embeds (routine, run_date, issue_key, summary) -- the incident key per C2 is (routine,
-- run_date, issue_key); summary text is included because, unlike P1's write-time escalation (which
-- fires unconditionally off existing run_log columns a caller cannot author), this procedure's whole
-- purpose is to carry a HUMAN-WRITTEN account to the inbox, so the account itself belongs in the
-- owner-facing message, not buried in a payload field alert_emailer.gs never renders for a
-- non-roster category (Claude_Task_Plan.md's payload-rendering clause, restated in
-- bigquery/229_staged_order_confirm_notice.sql's header). A caller that changes summary wording
-- between calls for the SAME issue_key on the SAME day will mint a second alert -- an accepted,
-- narrow cost (this procedure is meant to be called once per genuine issue per run, not polled), and
-- strictly better than the alternative of silently swallowing a materially different second report
-- under a stale first message.
--
-- in_payload_json is passed through, parsed, and nested under a `payload` key alongside the
-- structured routine/run_date/issue_key/summary fields -- so a querying session gets both the
-- identity fields every other alert in this file carries AND whatever caller-supplied structured
-- detail (a URL, a numeric threshold, a raw API error) the routine wants to attach, without that
-- detail ever needing to be dedup-stable (payload is never compared by sp_raise_alert_once).
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_report_run_issue`(
  in_routine STRING, in_run_date DATE, in_issue_key STRING, in_summary STRING, in_payload_json STRING)
BEGIN
  IF in_issue_key IS NULL OR TRIM(in_issue_key) = '' THEN
    RAISE USING MESSAGE =
      'ops.sp_report_run_issue REFUSED: in_issue_key must be a non-blank string naming the KIND of issue (e.g. fmp_rate_limited), not the instance -- it is the sp_raise_alert_once dedup key folded into the alert message, and a blank key can never dedup against itself.';
  END IF;

  IF LENGTH(in_issue_key) > 64 THEN
    RAISE USING MESSAGE =
      'ops.sp_report_run_issue REFUSED: in_issue_key must be 64 characters or fewer. A long, instance-specific key defeats the dedup this procedure exists to provide -- name the KIND of issue, not the occurrence.';
  END IF;

  IF in_summary IS NULL OR LENGTH(TRIM(in_summary)) < 30 THEN
    RAISE USING MESSAGE =
      'ops.sp_report_run_issue REFUSED: in_summary must be a real account of at least 30 non-blank characters. A placeholder that only satisfies the signature is worse than silence, because it looks like a report -- same reasoning as ops.sp_amend_run_note (bigquery/170_run_log_note_write_time_guard.sql).';
  END IF;

  CALL `stock-trading-498512.ops.sp_raise_alert_once`(
    'warning', in_routine, 'routine_run_warning',
    FORMAT('%s reported an in-run issue on run_date %s [%s]: %s',
           in_routine, CAST(in_run_date AS STRING), in_issue_key, in_summary),
    TO_JSON_STRING(STRUCT(
      in_routine AS routine, in_run_date AS run_date, in_issue_key AS issue_key,
      in_summary AS summary, SAFE.PARSE_JSON(COALESCE(in_payload_json, 'null')) AS payload)));
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
--
-- SUPERSEDED LIVE by bigquery/231_run_outcome_notification_fire_drill.sql — current single source of
-- truth for state.run_log_unalerted_problems. 231 adds exactly ONE predicate (AND r.routine NOT LIKE
-- 'FIRE_DRILL%') plus its own justification comment, so the new ops.sp_fire_drill_run_outcome_notification
-- drill (231, same file) cannot make this backstop cry wolf about its own synthetic rows if it ever
-- aborts before its unconditional cleanup runs — the same protection bigquery/172/186/205/227 already
-- give state.run_log_unpaired_terminal. Nothing else about this view changes. The CREATE OR REPLACE
-- VIEW statement immediately below is kept here, unmodified, for DR-rebuild apply-in-order reference
-- only. DO NOT re-apply it live in isolation: it would revert 231's FIRE_DRILL% exclusion, and Part A
-- of 231's own drill would then be its own false positive against this exact view. Marker added
-- 2026-09-08.
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
-- ops.sp_sq_cadence_check — P4. SQ_VERSION v21 -> v22. Generated by PROGRAMMATIC EXACT-STRING
-- REPLACEMENT against the live v21 body in bigquery/227_alert_message_stability_ordering.sql (C6),
-- never retyped. EXACTLY THREE edits, each verified to match its anchor in the v21 body EXACTLY ONCE
-- before this file was written (see the task's return value for the replacement counts, and the
-- generator script kept alongside this landing for reproducibility):
--   (a) the heartbeat literal 'v21' -> 'v22';
--   (b) the number 14 auto-age allowlist gains 'routine_run_failed', 'routine_run_warning' and
--       'run_log_problem_unalerted', with a new justification comment matching this list's existing
--       per-entry documentation convention (see the comment directly above the widened IN (...) list
--       below);
--   (c) a new record-only WARNING block, inserted immediately before the file's single consolidated
--       RAISE, reading the new state.run_log_unalerted_problems view (P3 above) and raising
--       run_log_problem_unalerted with a STRING_AGG ordered by (routine, run_date, status, run_id) -- a TOTAL
--       order per this same procedure's own STRING_AGG-ordering rule (the rule bigquery/227 itself
--       exists to state and enforce four other call sites against).
-- No predicate, threshold, severity or control flow on any EXISTING check in this procedure is
-- touched. Every comment, check and RAISE below this point, up to the new block near the end, is
-- BYTE-IDENTICAL to the live v21 body.
-- RE-POINTED (2026-09-15): the CURRENT canonical definition of this procedure is
-- bigquery/241_queue_driven_per_day_missed_fire.sql, which SUPERSEDES every earlier copy including this
-- one. 241 carries the bigquery/230 body forward BYTE-IDENTICAL except exactly three edits: the
-- heartbeat literal v22 -> v23; two categories (queue_driven_missed_fire,
-- queue_driven_missed_fire_check_failed) appended to the number 14 auto-age allowlist; and one new
-- best-effort block appended after the queue_driven_silent check, raising a per-DAY missed-fire WARNING
-- from the new state.queue_driven_missed_fire_watch view. That closes the single-skipped-day case the
-- 9-day state.queue_driven_silence_watch threshold structurally cannot see and state.cadence_watch
-- never covers, because monitor_class=queue_driven is filtered out of state.cadence_expected_today
-- before the generated UNNEST literal is written (M1R logged nothing for 2026-09-14 and nothing
-- alerted). No predicate, threshold, exclusion or severity of any EXISTING check in this procedure
-- moves, and both new categories are severity warning so neither can contribute to blocking_criticals.
-- Any pointer ABOVE naming an earlier file is kept exactly as written, as history; THIS paragraph is
-- the live pointer. Kept here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT
-- re-apply this CREATE live in isolation.
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_sq_cadence_check`()
BEGIN
  DECLARE raise_msg STRING DEFAULT '';
  CALL `stock-trading-498512.ops.sp_beat_heartbeat`('sq:cadence_check', 'v22', 'cadence_check.sql ran');

  -- RUNBOOK section 38 self-heal (ITEM 3, bigquery/38_run_log_selfheal.sql): backfill any
  -- ops.run_log completion row whose routine already has a landed-commit marker in
  -- ops.routine_commit_markers, BEFORE evaluating missed_run/missing_dependency below, so a
  -- landed-but-unlogged strand self-heals the same night instead of tripping the dead-man's
  -- switch. (This proc also calls sp_auto_resolve_alerts() itself once it backfills anything,
  -- so the general call right below is defense-in-depth for unrelated alerts, not redundant
  -- plumbing.) Best-effort: never let a resolver bug break the cadence dead-man's switch itself.
  BEGIN
    CALL `stock-trading-498512.ops.sp_backfill_run_log_from_markers`();
  EXCEPTION WHEN ERROR THEN SELECT @@error.message;
  END;

  -- Mechanized alert auto-resolve (WP2, defense-in-depth alongside the routine-level call above).
  -- Best-effort: never let a resolver bug break the cadence dead-man's switch itself.
  BEGIN
    CALL `stock-trading-498512.ops.sp_auto_resolve_alerts`();
  EXCEPTION WHEN ERROR THEN SELECT @@error.message;
  END;

  -- Auto-resolve STALE self-healing WARNING rows (2026-06-28, #14) so the weekly digest's "N open alerts"
  -- reflects live issues, not warnings the owner never manually closed (e.g. a 4-day-old self-healed
  -- instruction_drift warning keeping the digest red). Targets only the self-CLEARING classes, warning
  -- severity, older than 7 days. A condition that is STILL true is simply re-raised by the checks below
  -- (sp_raise_alert_once), so this can only durably clear a row whose underlying condition has actually
  -- healed. Critical rows and the persistent-DRIFT classes (position_drift / ddl_drift /
  -- append_only_violation / restore_fidelity) are deliberately left untouched. Runs first, before any RAISE
  -- (which would abort the script). all_green keys only on open CRITICAL alerts, so this is purely a
  -- digest-quality fix, not a dead-man's-switch change.
  UPDATE `stock-trading-498512.ops.alerts`
  SET resolved = TRUE,
      resolved_ts = CURRENT_TIMESTAMP(),
      resolved_note = CONCAT('auto-aged (>7d self-healing warning/info; cadence_check.sql #14). ', COALESCE(resolved_note, ''))
  WHERE NOT resolved
    AND severity IN ('warning', 'info')
    -- trigger_missing added 2026-07-04 (audit finding): its message used to embed a daily-changing
    -- day-count, defeating sp_raise_alert_once's dedup and letting undeduped rows accumulate
    -- indefinitely since it was the one self-healing class missing from this auto-age list. The
    -- message fix below (stable text) restores real dedup; this stays as defense-in-depth.
    -- immediate_action_flagged + process_scorecard_signal added 2026-07-16 (consumption-closure): point-in-time W3/M3/W5 signals, consumed autonomously by W4/M4 within days; 7-day age-out stops forever-open dashboard rows. A persisting condition is simply re-raised.
    -- scheduled_query_version_drift added 2026-07-27 (bigquery/111): the SAME self-healing shape as
    -- scheduled_query_stale directly above. A version marker only reports what a scheduled query said
    -- the LAST time it ran, so a mid-day wrapper bump leaves the prior version as the freshest beat
    -- until that query's own next run -- and this proc evaluates ~05:15 UTC, ahead of most of them
    -- (daily_staging_cap_check ~05:25). The gap is therefore a routine bootstrapping-window race that
    -- heals itself within one cycle, exactly like a resumed beat, but it was the one such class absent
    -- from this list -- so every wrapper version bump left a permanently-open row needing a manual
    -- UPDATE (embed_pending 2026-07-17/18; daily_staging_cap_check v3->v4 2026-07-27, alert 0c2b631a).
    -- A STILL-drifted query is simply re-raised by the scheduled_query_version_drift check below, so a
    -- genuinely unapplied wrapper cannot be aged away silently.
    -- scheduled_query_stale + ci_findings_bridge_stale + control_plane_insert added 2026-07-17 (MON H2/H4/H5): self-healing warnings (a resumed beat / a re-armed bridge / an aged-out control INSERT event stop being true) whose stable-message rows would otherwise linger open after the condition heals; a STILL-true condition is simply re-raised below (bridge_stale/scheduled_query_stale in THIS proc, control_plane_insert by safety_critical_dml_watch).
    -- 'stranded_session' REMOVED 2026-07-29, because the Operating_Protocols.md §17 never-pushed-branch
    -- detector that raised it was RETIRED 2026-07-29 (commit a9a029b) and nothing in the tree can raise
    -- the category any more -- verified 2026-07-30: every remaining mention is either an auto-age
    -- allowlist (here and bigquery/75's superseded copy) or RUNBOOK prose describing one. A dead entry in
    -- a fail-closed allowlist reads as coverage that does not exist; dropped with §17.
    -- CORRECTION 2026-07-30: this comment previously justified the removal by asserting the category "was
    -- never once raised anywhere in this repo's entire git history" and "existed only in this allowlist".
    -- Both are FALSE, and the live table is the authority: ops.alerts holds exactly one stranded_session
    -- row -- raised 2026-06-24 22:41:49 by D2 for session sess-d1-20260624 (RUNBOOK §20 never-pushed
    -- strand) -- and THIS auto-age rule is what resolved it, on 2026-07-02 05:15:10, with
    -- resolved_note 'auto-aged (>7d self-healing warning; cadence_check.sql #14)'. So the entry was live
    -- coverage that demonstrably fired once; it is dead only PROSPECTIVELY, now that its raiser is gone.
    -- The removal stands (nothing can raise it, and the one historical row is long resolved, so no open
    -- alert is stranded by dropping it) -- but do not re-derive "never raised" from the old wording.
    -- CAUTION for any future allowlist edit: before dropping a category from this FAIL-CLOSED list,
    -- query ops.alerts for OPEN rows in it. An open row in a removed category never auto-ages again.
    -- connector_tool_inventory_stale added 2026-08-08 (same v16 change that adds the check block below,
    -- bigquery/151_connector_tool_inventory.sql): the identical self-healing shape as scheduled_query_
    -- version_drift / script_version_drift above -- state.connector_tool_inventory_stale reports only what
    -- the LAST enumeration run observed, so once OPS1 resumes a trustworthy sweep the condition clears on
    -- its own. It has no ops.alert_policy row either, so leaving it off this list would reproduce the exact
    -- connector/strategy_revised bug this file exists to fix, for a third category, in the same commit.
    -- monitor_promoted added 2026-08-19 (bigquery/186, by the D3 run that had just raised one) -- the SAME
    -- structural bug as strategy_revised, which bigquery/150 added and bigquery/159 finally made effective.
    -- It is an info-severity COMPLETED-ACTION RECORD ("check X promoted WARNING->CRITICAL, no owner action
    -- required"), so at info severity it is filtered out of both alert_emailer.gs's and scripts/
    -- alert_relay.py's notification queries before ever reaching notified_ts, and Rule 5's on-delivery
    -- resolve path never sees it. It also has no ops.alert_policy row. Between those two facts NO automated
    -- mechanism could ever close one, and the live table proves the cost was already being paid by hand:
    -- all three prior rows (ddl_drift 2026-07-12, park_allocator/ddl_drift 2026-07-26, b3_trading_enabled_
    -- drift 2026-08-03) were each closed manually in a later interactive triage session, days after the
    -- change they announced had completed. SAFER TO AGE OUT THAN ANY OTHER ENTRY ON THIS LIST: a promotion
    -- is idempotent by construction (ops.monitor_promotion_log makes the readiness view's
    -- not_already_promoted FALSE forever after), so unlike every self-healing class above there is no
    -- underlying condition that could still be true and no re-raise to rely on -- the row is a receipt for
    -- something already done, and aging it can hide nothing. The promotion itself stays permanently
    -- queryable in ops.monitor_promotion_log and events.decision_log (entry_type='monitor-promotion'),
    -- which are the durable records; ops.alerts is only the announcement.
    -- routine_run_failed / routine_run_warning / run_log_problem_unalerted added 2026-09-08
    -- (bigquery/230_run_outcome_notification.sql, owner directive on run-outcome notification). Same
    -- RECEIPT-FOR-A-PAST-EVENT shape as monitor_promoted directly above, not the self-healing-transient
    -- shape most of this list is: the run that failed, or the run-time issue that was reported, is a
    -- permanent fact about ops.run_log -- there is no mechanically re-checkable "it healed" condition
    -- for ops.sp_auto_resolve_alerts to verify, so a resolve_rule / ops.alert_policy row is the wrong
    -- tool (C3, bigquery/230's design doc). The durable record is ops.run_log itself; ops.alerts here
    -- is only the announcement, exactly as the comment above already argues for monitor_promoted.
    AND category IN ('instruction_drift', 'calendar_runway_low', 'routine_stalled', 'trigger_missing', 'immediate_action_flagged', 'process_scorecard_signal', 'scheduled_query_stale', 'ci_findings_bridge_stale', 'control_plane_insert', 'scheduled_query_version_drift', 'script_version_drift', 'queue_driven_silent', 'run_log_note_missing', 'run_log_start_row_missing', 'connector', 'strategy_revised', 'connector_tool_inventory_stale', 'account_snapshot_gap', 'trigger_drift_corrected', 'monitor_promoted', 'routine_run_failed', 'routine_run_warning', 'run_log_problem_unalerted')
    AND alert_ts < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY);

  -- missed_run (critical) — a monitored routine expected today did not complete.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.cadence_watch` WHERE needs_attention) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.cadence', 'missed_run',
      CONCAT('Cadence check: monitored routine(s) expected today did not complete: ',
             (SELECT STRING_AGG(routine, ', ' ORDER BY routine)
              FROM `stock-trading-498512.state.cadence_watch` WHERE needs_attention)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(routine, schedule, today)))
       FROM `stock-trading-498512.state.cadence_watch` WHERE needs_attention));
    SET raise_msg = raise_msg || CONCAT('[missed_run] ',
      (SELECT STRING_AGG(routine, ', ' ORDER BY routine)
       FROM `stock-trading-498512.state.cadence_watch` WHERE needs_attention), '; ');
  END IF;

  -- queue_driven_silent (warning) — a queue_driven routine has logged no completed run for longer
  -- than any gap in its own history. THIS IS THE ONLY NET THAT COVERS THEM: monitor_class
  -- queue_driven is excluded from state.cadence_expected_today, which BOTH state.cadence_watch and
  -- state.cadence_period_watch are built on, so AR_att/AR_orc/SL2/SL5 have never had a cadence
  -- signal of any kind. Measured 2026-08-03: SL2 and SL5 went dark after 2026-07-30 when their
  -- triggers were disabled, and NOTHING alerted on the silence — the only surfacing was D3's
  -- queue_item_stale, a downstream symptom whose own text had to flag the root cause as INFERRED
  -- because it could not verify it.
  --
  -- WARNING, deliberately NOT critical, and it must stay that way. state.trading_enabled ANDs
  -- `blocking_criticals = 0`, so a critical here would HALT ORDER STAGING every time a SISA
  -- lifecycle routine went quiet. That is exactly the failure mode of the 2026-08-01..03 incident
  -- this file's sibling (bigquery/130) exists to prevent; do not promote this category.
  --
  -- Record-only, like instruction_drift: does NOT append to raise_msg and so does not contribute to
  -- the DTS failure-email RAISE. Auto-ages after 7d via the allowlist above and re-raises on the
  -- next run while the condition persists.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.queue_driven_silence_watch` WHERE is_silent) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'queue_driven_silent',
      CONCAT('Queue-driven routine(s) silent past threshold — these sit OUTSIDE the cadence nets, so a disabled or dead trigger here produces no other signal. Check the trigger is enabled in claude.ai before assuming an empty queue: ',
             (SELECT STRING_AGG(routine, ', ' ORDER BY routine)
              FROM `stock-trading-498512.state.queue_driven_silence_watch` WHERE is_silent)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(routine, last_run_date, days_silent,
                                              silence_threshold_days, never_completed) ORDER BY routine))
       FROM `stock-trading-498512.state.queue_driven_silence_watch` WHERE is_silent));
  END IF;

  -- backup_stale (critical) — events.* GCS backup has not logged a success in >2 days (16_automation_health.sql).
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.backup_health` WHERE stale) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.cadence', 'backup_stale',
      'Backup check: events.* GCS backup has not logged a successful run in >2 days',
      (SELECT TO_JSON_STRING(t) FROM `stock-trading-498512.state.backup_health` t));
    SET raise_msg = raise_msg || (SELECT CONCAT('[backup_stale] last_backup_date=',
      CAST(last_backup_date AS STRING), '; ') FROM `stock-trading-498512.state.backup_health`);
  END IF;

  -- ops_backup_stale (critical, 2026-06-28 #2) — the ops.* (audit/control-plane) GCS backup has gone
  -- silent (>2 days). ops.* is IRREPLACEABLE append-only history with no upstream, so a stalled ops
  -- backup is as serious as a stalled events backup. Self-bootstrapping (state.ops_backup_health.monitored).
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.ops_backup_health` WHERE stale) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.cadence', 'ops_backup_stale',
      'Backup check: ops.* (audit/control-plane) GCS backup has not logged a successful run in >2 days',
      (SELECT TO_JSON_STRING(t) FROM `stock-trading-498512.state.ops_backup_health` t));
    SET raise_msg = raise_msg || (SELECT CONCAT('[ops_backup_stale] last_backup_date=',
      CAST(last_backup_date AS STRING), '; ') FROM `stock-trading-498512.state.ops_backup_health`);
  END IF;

  -- automation_heartbeat (critical) — an out-of-band Apps Script went silent (16_automation_health.sql).
  -- Delivered via THIS query's DTS failure-email, NOT via the (possibly-dead) alert emailer.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.automation_heartbeat` WHERE stale) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.cadence', 'automation_heartbeat',
      CONCAT('Heartbeat check: out-of-band automation went silent: ',
             (SELECT STRING_AGG(source, ', ' ORDER BY source)
              FROM `stock-trading-498512.state.automation_heartbeat` WHERE stale)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(source, age_hours, max_age_hours, CAST(last_beat_ts AS STRING) AS last_beat_ts)))
       FROM `stock-trading-498512.state.automation_heartbeat` WHERE stale));
    SET raise_msg = raise_msg || CONCAT('[automation_heartbeat] ',
      (SELECT STRING_AGG(source, ', ' ORDER BY source)
       FROM `stock-trading-498512.state.automation_heartbeat` WHERE stale), '; ');
  END IF;

  -- instruction_drift (WARNING, non-raising). The schedule/instruction live only in the web UI;
  -- state.instruction_drift (bigquery/15_routine_catalog.sql) diffs each routine's LIVE logged trigger
  -- against the canonical catalog. A drift is a config bug to fix, not a halt — so it records but does
  -- NOT contribute to the RAISE.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.instruction_drift` WHERE drifted OR unknown_routine) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'instruction_drift',
      CONCAT('Trigger drift: routine(s) whose live web-UI trigger differs from the canonical catalog: ',
             (SELECT STRING_AGG(routine, ', ' ORDER BY routine)
              FROM `stock-trading-498512.state.instruction_drift` WHERE drifted OR unknown_routine)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(routine, drifted, unknown_routine, live_instruction, canonical_instruction)))
       FROM `stock-trading-498512.state.instruction_drift` WHERE drifted OR unknown_routine));
  END IF;

  -- ====================================================================================
  -- 2026-06-24 stack-review additions (all WARNING, record-only — like instruction_drift —
  -- so they NEVER flip all_green and NEVER add to the DTS RAISE; delivered by the alert
  -- emailer / out-of-band relay, which both forward 'warning' rows). They reference views in
  -- bigquery/18_stack_review_fixes.sql — APPLY 18 BEFORE re-pasting this query. All read only
  -- ops.run_log + state views (no extra IAM); the JOBS-based append-only guard lives in the
  -- separate integrity_check.sql (it needs roles/bigquery.resourceViewer). RUNBOOK §25.
  -- ====================================================================================

  -- trigger_missing (D2) — a calendar-predictable routine the cadence ALARM deliberately excludes
  -- (weekly/monthly/quarterly/annual) has logged NO completed run across its cadence window: a DELETED
  -- (vs edited) web-UI trigger, which instruction_drift cannot see (it needs a run to log). Self-
  -- bootstrapping: only flags routines that have completed before (state.trigger_attestation.monitored).
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.trigger_attestation` WHERE overdue) THEN
    -- Message kept STABLE (2026-07-04 audit finding): embedding days_since_completed (which changes
    -- daily while a routine stays overdue) defeated sp_raise_alert_once's exact-match dedup, creating
    -- a fresh open alert row every day the condition persisted. Per-routine day counts are still fully
    -- visible in the payload below.
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'trigger_missing',
      CONCAT('Trigger attestation: routine(s) overdue beyond their cadence window (deleted/disabled web-UI trigger?): ',
             (SELECT STRING_AGG(routine, ', ' ORDER BY routine)
              FROM `stock-trading-498512.state.trigger_attestation` WHERE overdue),
             '. See payload for per-routine day counts.'),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(routine, days_since_completed, max_gap_days, last_completed)))
       FROM `stock-trading-498512.state.trigger_attestation` WHERE overdue));
  END IF;

  -- period_missed (warning, 2026-07-03 self-improvement audit WO-1/B-6-obs) — a weekly/monthly/quarterly/
  -- annual routine has not logged 'completed' anywhere in the CURRENT period (ISO week / month / quarter /
  -- year) and Denver wall-clock is past that period's grace deadline (bigquery/24_cadence_period_watch.sql
  -- — placed strictly after the documented Sun-or-Mon weekly tolerance / the 3rd-or-5th trading day for
  -- longer periods). Closes the gap where trigger_missing's coarse 14/70/200/400-day window could leave a
  -- single missed weekly routine unflagged for up to ~2 weeks. Self-bootstrapping (state.cadence_period_
  -- watch.monitored) and WARNING-only (a missed weekly is not a same-night trading halt) — promote to a
  -- RAISE-contributing critical only after a clean period confirms no false fire.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.cadence_period_watch` WHERE period_missed) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'period_missed',
      CONCAT('Cadence period check: routine(s) have not completed in the current period past their grace deadline: ',
             (SELECT STRING_AGG(CONCAT(routine, ' (', monitor_class, ', period ', CAST(period_start AS STRING), ')'), ', ' ORDER BY routine)
              FROM `stock-trading-498512.state.cadence_period_watch` WHERE period_missed)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(routine, monitor_class, period_start, grace_deadline)))
       FROM `stock-trading-498512.state.cadence_period_watch` WHERE period_missed));
  END IF;

  -- routine_stalled (marginal) — a routine logged 'started' but never a terminal status past its per-class
  -- threshold (2026-06-28 #11: now ALL run-logged routines, not just D1/D2/D3): a session that died after
  -- sp_routine_start but before sp_routine_end (the run-log-blind slice).
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.stalled_runs`) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'routine_stalled',
      CONCAT('Stalled run(s): a routine started but never logged a terminal status: ',
             (SELECT STRING_AGG(CONCAT(routine, '/', CAST(run_date AS STRING)), ', ' ORDER BY routine, run_date)
              FROM `stock-trading-498512.state.stalled_runs`)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(routine, run_date, hours_since_started)))
       FROM `stock-trading-498512.state.stalled_runs`));
  END IF;

  -- run_log_note_missing (audit of the 2026-08-07 daily runs) — a routine logged a TERMINAL row
  -- (completed/failed/halted) carrying NO note, so the run left no account of itself. ops.run_log.note is
  -- the ONLY durable narrative record of what a routine decided and why: the routine's own reasoning is
  -- otherwise unrecoverable once the session ends. MEASURED before shipping this check, over the trailing
  -- 30 days: 8 terminal rows of 368 (~0.27/day) — rare enough that each firing means something, which is
  -- why this is scoped to the note gap and NOT extended to a missing `instruction`. An absent instruction
  -- looks similar but is NOT the same signal: 322 of 324 completed rows legitimately carry no instruction
  -- (it belongs on the paired 'started' row), and 46 of 330 'started' rows lack one, so alarming on it
  -- would fire ~14% of the time and train the operator to ignore this category.
  --
  -- WHY IT MATTERS, from the run that prompted it: D2/2026-08-07 logged completed with note NULL, ran
  -- 5m34s against a 12-22min norm, and logged rows_written=5 while writing exactly ONE BigQuery row —
  -- the other 4 were Watchlist.md ticker edits counted as though they were rows. The work itself was
  -- substantively correct (its decision_log entry and commit 77c8c85 both check out), so nothing was
  -- broken; but an abbreviated run left no explanation of itself and no monitor noticed, because nothing
  -- in this stack has ever read run_log.note or rows_written. This is that reader.
  --
  -- RECORD-ONLY (no raise_msg join), deliberately: a missing note is an audit-hygiene defect, not a
  -- reason to fail the nightly check or halt anything. It is also NOT REPAIRABLE after the fact — the row
  -- is history and ops.run_log is not rewritten — so the category is in the #14 auto-age allowlist above
  -- and closes itself once the 3-day view window rolls past the offending row.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.run_log_content_gaps`) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'run_log_note_missing',
      -- DEDUP-CRITICAL — the message is a FIXED STRING and must stay one. sp_raise_alert_once dedups on
      -- exact (category, message) while the prior row is unresolved, so ANY per-row detail here (the
      -- routine/date list, or even a count) changes the text every time the 3-day window's membership
      -- shifts — a gap entering OR an older one aging out — and opens a NEW row each time instead of
      -- collapsing onto one. Walked against the real 30-day history, an aggregated message would have
      -- produced 6 distinct open rows for the 4 gaps between 07-08 and 07-18. Same convention as the
      -- trigger_missing / calendar_runway_low / probe_funding_stalled / scheduled_query_stale blocks
      -- in this procedure: identity in the message, detail in the payload only.
      'Terminal run_log row(s) with no note in the trailing 3 days — a routine logged completed/failed/halted without recording what it did. See payload for the affected routine/run_date rows.',
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(routine, run_date, status, run_id)))
       FROM `stock-trading-498512.state.run_log_content_gaps`));
  END IF;

  -- run_log_start_row_missing — a routine logged a TERMINAL row for a run_date with no paired
  -- 'started' row. Sibling of run_log_note_missing above and deliberately the same shape: record-only
  -- (no raise_msg join), fixed message, detail in the payload, 3-day window, #14 auto-age allowlist.
  --
  -- WHAT IT CATCHES that nothing else did. state.stalled_runs is the mirror check — started with no
  -- terminal — and ops.run_log has no key linking the two rows (run_id is GENERATE_UUID() per INSERT;
  -- the pair is only (routine, run_date)), so a terminal row whose start was never logged was covered
  -- by no monitor at all. It matters because the 'started' row is where `instruction` lives: without
  -- it state.routine_last_instruction has no sample for that run, so state.instruction_drift is blind
  -- to a drifted web-UI trigger for exactly that day, and state.stalled_runs can never see the run.
  --
  -- MEASURED over the trailing 120 days before shipping: 2 firings, both on 2026-07-18 (SL2 and D3,
  -- both 'halted'), i.e. ~0.017/day. That is an order of magnitude quieter than run_log_note_missing
  -- was at its own ship date (~0.27/day), so it clears the bar this file's v13 note sets: a check that
  -- fires often enough to be ignored is worse than no check.
  --
  -- TWO EXCLUSIONS, both load-bearing — WITHOUT THEM this fires 12 times instead of 2, and the noise
  -- would be entirely false positives:
  --   * FIRE_DRILL% / SELFHEAL_RUN_LOG call ops.sp_log_run DIRECTLY and never call sp_routine_start.
  --     They are procedures recording that they fired, not sessions with a start. 30 such rows in 120d.
  --   * Rows written by ops.sp_backfill_run_log_from_markers (RUNBOOK §38 self-heal) reconstruct a
  --     COMPLETED row from a git commit marker for a run that never logged anything — so a missing
  --     'started' row is the PREMISE of that mechanism, not a defect in it. Matched on the same
  --     '^(auto-)?backfilled' prefix bigquery/89 already anchors on; keep the two in step if either
  --     changes. These accounted for every one of the 9 apparent D1 cases in the raw 120-day count.
  --
  -- The routine-id comparison is separator-normalised, matching state.instruction_drift and
  -- state.routine_catchup_window, so the legacy middle-dot ids (AR·att/AR·orc, written 2026-06-19..
  -- 2026-07-01) fold onto their ASCII form instead of pairing a terminal row against nothing.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.run_log_unpaired_terminal`) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'run_log_start_row_missing',
      -- DEDUP-CRITICAL — fixed string, same convention and same reason as the run_log_note_missing
      -- block directly above: per-row detail here would open a new alert row every time the 3-day
      -- window's membership shifts, instead of collapsing onto one.
      'Terminal run_log row(s) with no paired started row in the trailing 3 days — a routine logged completed/failed/halted for a run_date it never logged a start for. See payload for the affected routine/run_date rows.',
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(routine, run_date, status, run_id)))
       FROM `stock-trading-498512.state.run_log_unpaired_terminal`));
  END IF;

  -- position_drift (B4) — the two open-position representations (state.current_positions vs
  -- analytics.position_lifecycle) disagree on open shares beyond tolerance for some (strategy,ticker).
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.position_reconciliation` WHERE drifted) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'position_drift',
      CONCAT('Position reconciliation: current_positions vs position_lifecycle open-share drift: ',
             (SELECT STRING_AGG(CONCAT(strategy, ':', ticker), ', ' ORDER BY strategy, ticker)
              FROM `stock-trading-498512.state.position_reconciliation` WHERE drifted)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(strategy, ticker, current_positions_shares, lifecycle_open_shares, share_diff)))
       FROM `stock-trading-498512.state.position_reconciliation` WHERE drifted));
  END IF;

  -- calendar_runway_low (FMP auto-extend liveness) — the trading-calendar horizon has fallen below the
  -- W5 FMP auto-extend trigger and stayed there, an EARLY signal the auto-extend (likely the FMP grant)
  -- is failing, well before the calendar exhausts and the freshness COALESCE→FALSE backstop trips.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.market_calendar_horizon` WHERE runway_low) THEN
    -- Message kept STABLE (2026-07-04 audit finding): embedding days_of_runway/calendar_through (both
    -- change daily while the condition persists) defeated sp_raise_alert_once's exact-match dedup,
    -- creating a fresh open alert row every day the runway stayed low. Full detail is still in the
    -- payload below.
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'calendar_runway_low',
      'Market-calendar runway low — W5 FMP auto-extend may be failing. See payload for runway/through-date detail.',
      (SELECT TO_JSON_STRING(t) FROM `stock-trading-498512.state.market_calendar_horizon` t));
  END IF;

  -- ====================================================================================
  -- 2026-06-28 stack-review #2 additions (originally all WARNING, record-only. restore_stale was PROMOTED
  -- to CRITICAL + RAISE-contributing on 2026-07-11, and ddl_drift on 2026-07-26, each by D3's
  -- monitor-promotion self-flip once its readiness view fired — ITEM 24).
  -- Reference views in bigquery/17_restore_drill.sql (state.restore_health) and
  -- bigquery/19_stack_review_fixes_2.sql (state.ddl_drift) — APPLY 17 + 19 BEFORE re-pasting this query.
  -- ====================================================================================

  -- restore_stale (CRITICAL as of 2026-07-11, promoted from warning per ITEM 24 — see the self-flip note
  -- at the IF block below; #4) — the monthly restore drill has not completed in >40 days OR its last run
  -- did not pass. A drill that writes nothing on success is otherwise invisible (state.restore_health off
  -- ops.drill_log). A silently-paused DR drill means "DR verified monthly" is a belief, not a fact. (A dead
  -- drill SCHEDULER is additionally caught by the Cloud Monitoring absence policy in monitoring.tf.)
  -- MONITOR-PROMOTION HISTORY (ITEM 24, 2026-07-11): logged UNCONDITIONALLY (pass or fail), regardless of
  -- whether the WARNING below fires -- state.ddl_drift_promotion_readiness / state.restore_stale_
  -- promotion_readiness (bigquery/45_monitor_promotion.sql) need this history to evaluate "N consecutive
  -- clean runs", which the plain live views above cannot provide on their own.
  -- BUG FIX (rev 2026-07-11, adversarial self-audit): MERGE upsert, not plain INSERT -- a plain INSERT
  -- let a same-day re-run of this query (off-schedule/manual/duplicate, the exact class the 2026-06-25
  -- cadence deadline-guard fix already had to account for) write a second row for the same (check_id,
  -- check_date), which the NOT-ENFORCED primary key does not prevent -- breaking the "14 consecutive
  -- DISTINCT logged days" promotion bar this history table exists to support (bigquery/45's readiness
  -- views also defend against any pre-existing duplicate independently).
  MERGE `stock-trading-498512.ops.monitor_health_history` T
  USING (
    SELECT 'restore_stale' AS check_id, CURRENT_DATE('America/Denver') AS check_date,
           NOT COALESCE(stale, TRUE) AS clean
    FROM `stock-trading-498512.state.restore_health`
  ) S
  ON T.check_id = S.check_id AND T.check_date = S.check_date
  WHEN MATCHED THEN
    UPDATE SET clean = S.clean, logged_ts = CURRENT_TIMESTAMP()
  WHEN NOT MATCHED THEN
    INSERT (check_id, check_date, clean) VALUES (S.check_id, S.check_date, S.clean);

  -- PROMOTED WARNING->CRITICAL (2026-07-11, D3 monitor-promotion self-flip per ITEM 24): once
  -- state.restore_stale_promotion_readiness.ready=TRUE (monitored=TRUE AND last drill passed — the
  -- RUNBOOK's own stated bar), D3 self-applies this promotion. Now a RAISE-contributing critical,
  -- wired into raise_msg like backup_stale/automation_heartbeat above (a silently-stale DR drill is a
  -- capital-safety fact, not a buried warning). ops.monitor_promotion_log guards idempotency.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.restore_health` WHERE stale) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.cadence', 'restore_stale',
      (SELECT CONCAT('Restore-drill health: last drill ', CAST(last_drill_date AS STRING),
                     ' (passed=', CAST(last_drill_passed AS STRING), ') — stale or failing')
       FROM `stock-trading-498512.state.restore_health`),
      (SELECT TO_JSON_STRING(t) FROM `stock-trading-498512.state.restore_health` t));
    SET raise_msg = raise_msg || (SELECT CONCAT('[restore_stale] last_drill=',
      CAST(last_drill_date AS STRING), ' passed=', CAST(last_drill_passed AS STRING), '; ')
      FROM `stock-trading-498512.state.restore_health`);
  END IF;

  -- ddl_drift (CRITICAL as of 2026-07-26, promoted from warning per ITEM 24 — D3 monitor-promotion
  -- self-flip once state.ddl_drift_promotion_readiness.ready=TRUE (14 consecutive clean logged days);
  -- #7) — a live events.* audit table's STRUCTURE (NOT NULL / type / partition /
  -- cluster) diverged from the canonical bigquery/01_schema.sql spec (a silent out-of-band ALTER the
  -- idempotent CREATE-IF-NOT-EXISTS spec will not re-assert; invisible to the DML-only append_only_integrity
  -- and to dbt not_null DATA tests). Now a RAISE-contributing critical, wired into raise_msg like
  -- restore_stale above. ops.monitor_promotion_log guards idempotency.
  -- BUG FIX (rev 2026-07-11, adversarial self-audit): MERGE upsert, same rationale as the restore_stale
  -- write above.
  MERGE `stock-trading-498512.ops.monitor_health_history` T
  USING (
    SELECT 'ddl_drift' AS check_id, CURRENT_DATE('America/Denver') AS check_date,
           NOT EXISTS (SELECT 1 FROM `stock-trading-498512.state.ddl_drift`) AS clean
  ) S
  ON T.check_id = S.check_id AND T.check_date = S.check_date
  WHEN MATCHED THEN
    UPDATE SET clean = S.clean, logged_ts = CURRENT_TIMESTAMP()
  WHEN NOT MATCHED THEN
    INSERT (check_id, check_date, clean) VALUES (S.check_id, S.check_date, S.clean);

  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.ddl_drift`) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.cadence', 'ddl_drift',
      CONCAT('DDL drift: events.* base-table structure differs from bigquery/01_schema.sql: ',
             (SELECT STRING_AGG(CONCAT(table_name, '.', column_name, ' [', drift_reasons, ']'), '; '
                     ORDER BY table_name, column_name)
              FROM `stock-trading-498512.state.ddl_drift`)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(table_name, column_name, drift_reasons, expected_type, live_type)))
       FROM `stock-trading-498512.state.ddl_drift`));
    SET raise_msg = raise_msg || CONCAT('[ddl_drift] ',
      (SELECT STRING_AGG(CONCAT(table_name, '.', column_name, ' [', drift_reasons, ']'), '; '
              ORDER BY table_name, column_name)
       FROM `stock-trading-498512.state.ddl_drift`), '; ');
  END IF;

  -- b3_trading_enabled_drift (warning, self-improvement audit 2026-07-15 -- CONFIRMED GAP
  -- dbt-b3-coverage-advisory-only). state.b3_trading_enabled_check (bigquery/64_b3_live_invariants.sql)
  -- recomputes state.trading_enabled's formula independently and flags LIVE drift -- the exact
  -- 2026-07-11 incident class (an in-place scheduled-query re-apply silently clobbered a gate
  -- AND-term for days with zero CI/live signal, bigquery/47_trading_enabled_resync.sql), now checked
  -- daily instead of only in an advisory-only dbt test.
  -- MONITOR-PROMOTION HISTORY for b3_trading_enabled_drift (MON M2, 2026-07-17). Mirrors the
  -- ddl_drift/restore_stale MERGE-upsert above and the append_only_integrity one in integrity_check.sql
  -- (ITEM 24/31): logged UNCONDITIONALLY every run (clean = zero drift rows in
  -- state.b3_trading_enabled_check) so state.b3_promotion_readiness (bigquery/79_b3_promotion.sql) can
  -- evaluate the 14-consecutive-clean-DISTINCT-day bar the plain live view cannot provide on its own —
  -- bigquery/64's header promised this promotion path but nothing wrote the history until now. MERGE
  -- (not INSERT) so a same-day off-schedule/manual re-run never double-logs one day (same rationale as
  -- the ddl_drift/restore_stale writes). Does NOT change this check's alerting: still the WARNING-only
  -- IF block below. Because b3_trading_enabled_drift lives in THIS file (which HAS the raise_msg
  -- accumulator, unlike append_only_integrity), D3's MONITOR-PROMOTION SELF-FLIP promotes it by flipping
  -- the 'warning' literal below to 'critical' AND appending to raise_msg — see bigquery/79's header.
  MERGE `stock-trading-498512.ops.monitor_health_history` T
  USING (
    SELECT 'b3_trading_enabled_drift' AS check_id, CURRENT_DATE('America/Denver') AS check_date,
           NOT EXISTS (SELECT 1 FROM `stock-trading-498512.state.b3_trading_enabled_check` WHERE drift) AS clean
  ) S
  ON T.check_id = S.check_id AND T.check_date = S.check_date
  WHEN MATCHED THEN
    UPDATE SET clean = S.clean, logged_ts = CURRENT_TIMESTAMP()
  WHEN NOT MATCHED THEN
    INSERT (check_id, check_date, clean) VALUES (S.check_id, S.check_date, S.clean);

  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.b3_trading_enabled_check` WHERE drift) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.cadence', 'b3_trading_enabled_drift',
      (SELECT CONCAT('state.trading_enabled formula drift: live=', CAST(live_value AS STRING),
                     ' but independently-recomputed expected=', CAST(expected_value AS STRING),
                     ' -- a gate AND-term may have been silently clobbered (see bigquery/47_trading_enabled_resync.sql)')
       FROM `stock-trading-498512.state.b3_trading_enabled_check`),
      (SELECT TO_JSON_STRING(t) FROM `stock-trading-498512.state.b3_trading_enabled_check` t));
    SET raise_msg = raise_msg || (SELECT CONCAT('[b3_trading_enabled_drift] live=', CAST(live_value AS STRING),
      ' expected=', CAST(expected_value AS STRING), '; ') FROM `stock-trading-498512.state.b3_trading_enabled_check`);
  END IF;

  -- backup_per_table_row_drop (warning, self-improvement audit 2026-07-15 -- CONFIRMED GAP
  -- backup-per-table-rows-write-only). state.backup_per_table_health (bigquery/65_backup_per_table_
  -- health.sql) was write-only (RUNBOOK B2's per-table row-count evidence, INSERTed but never read).
  -- Every backed-up table is append-only by design, so a day-over-day row-count DROP can only mean an
  -- out-of-band deletion or a backup-query regression -- never legitimate activity.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.backup_per_table_health` WHERE row_count_dropped) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'backup_per_table_row_drop',
      CONCAT('Backup per-table row-count DROP detected (append-only table(s) should never shrink): ',
             (SELECT STRING_AGG(CONCAT(dataset, '.', table_name), ', ' ORDER BY dataset, table_name)
              FROM `stock-trading-498512.state.backup_per_table_health` WHERE row_count_dropped)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(dataset, table_name, prior_run_date, prior_rows, latest_run_date, latest_rows)))
       FROM `stock-trading-498512.state.backup_per_table_health` WHERE row_count_dropped));
  END IF;

  -- script_version_drift (warning, item 23 -- Apps Script drift detection). A deployed .gs (alert_emailer
  -- / weekly_report) is running a version other than the repo's expected one, or has stopped reporting a
  -- version at all after previously doing so -- almost always a Claude-side .gs fix that was never re-
  -- pasted by the owner (script.google.com is unreachable from Claude). Self-bootstrapping
  -- (state.script_version_drift.monitored) so this never fires before the owner has pasted the version-
  -- emitting .gs diff at least once. Delivered via THIS query's DTS failure-email path is deliberately
  -- NOT used for delivery (kept WARNING, record-only, like instruction_drift/ddl_drift) since alert_emailer
  -- itself is one of the two monitored scripts -- routing this alarm through it would be circular; the
  -- warning still reaches the owner via the alert emailer's own periodic poll of ops.alerts, which is a
  -- SEPARATE mechanism from "this script being the delivery channel for its own drift" (see 43_script_
  -- version_registry.sql header). Staged-rollout WARNING until a clean baseline confirms no false fire,
  -- matching the ddl_drift / restore_stale precedent above.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.script_version_drift` WHERE drift) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'script_version_drift',
      CONCAT('Script version drift: deployed Apps Script(s) running an unexpected/missing version: ',
             (SELECT STRING_AGG(CONCAT(script_name, ' (expected ', expected_version, ', reported ',
                     COALESCE(last_reported_version, 'NONE'), ')'), ', ' ORDER BY script_name)
              FROM `stock-trading-498512.state.script_version_drift` WHERE drift)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(script_name, expected_version, last_reported_version, last_beat_ts)))
       FROM `stock-trading-498512.state.script_version_drift` WHERE drift));
  END IF;

  -- scheduled_query_version_drift (warning, consumption-closure audit 2026-07-16 -- bigquery/63's
  -- drift view previously had NO automated reader anywhere; verbatim mirror of the script_version_drift
  -- block directly above, same self-bootstrapping convention: monitored=FALSE rows can never fire.
  -- Self-reference caveat: this block cannot report THIS query's own regression -- a regressed body
  -- lacks the block -- so Claude_Task_Plan.md's D3 UNWIRED-MONITOR BRIDGE bullet also raises this
  -- category for cadence_check itself (self-retiring once this body's own heartbeat matches v5 —
  -- comment updated 2026-07-16 by the ARCH-1 wrapper migration's v4->v5 bump; no logic change).
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.scheduled_query_version_drift` WHERE drift) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`('warning','scheduled.cadence','scheduled_query_version_drift',
      CONCAT('Scheduled-query body drift (live console body != repo SQ_VERSION): ',
        (SELECT STRING_AGG(CONCAT(sq_name,' (expected ',expected_version,', reported ',COALESCE(last_reported_version,'NONE'),')'), ', ' ORDER BY sq_name)
         FROM `stock-trading-498512.state.scheduled_query_version_drift` WHERE drift)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(sq_name, expected_version, last_reported_version, CAST(last_beat_ts AS STRING) AS last_beat_ts)))
       FROM `stock-trading-498512.state.scheduled_query_version_drift` WHERE drift));
  END IF;

  -- process_constant_evidence_invalidated (warning, bigquery/142_cadence_deadline_revert_and_evidence_
  -- drift.sql, 2026-08-06). state.process_constant_evidence_drift re-validates an ALREADY-APPLIED W5
  -- process_reliability autotune against the metric-view predicate set its justification depended on,
  -- recomputed as of TODAY — closing a gap state.process_constant_oos_watch (bigquery/72) structurally
  -- cannot reach: that fail-safe only detects that the change did not work (a persisted POST-change
  -- threat); this detects that the evidence was never real (a persisted PRE-change threat manufactured
  -- by a metric formula later corrected — see bigquery/89, 2026-08-04, backfilled-row exclusion, which
  -- is exactly what happened to the D1 2026-08-03 cadence_watch_deadline_local autotune; see bigquery/142
  -- header for the full account). Record-only, like instruction_drift/ddl_drift/ci_finding above: does
  -- NOT join raise_msg (an invalidated-evidence finding needs human adjudication — re-read the view,
  -- decide whether to revert the constant or accept the change on other grounds — it is not a same-night
  -- trading halt). Deliberately ABSENT from the #14 auto-age allowlist above: unlike a self-healing
  -- transient, a genuinely invalidated evidence trail does not become false again on its own, so this must
  -- stay open until a human closes it by hand — see ops.alert_policy.resolve_rule for this category
  -- (bigquery/142).
  -- BEST-EFFORT GUARD, same pattern this procedure already applies to sp_backfill_run_log_from_markers
  -- and sp_auto_resolve_alerts above. BigQuery binds a procedure's referenced objects LAZILY, at CALL
  -- time rather than CREATE time, so applying this v12 body BEFORE bigquery/142's Statement 2 would not
  -- fail on creation — it would abort the NEXT nightly run mid-body with `Not found:
  -- state.process_constant_evidence_drift`, silently killing every check BELOW this point
  -- (scheduled_query_stale, probe_funding_stalled, cash_flows_backfill_broken, ci_finding,
  -- ci_findings_bridge_stale, constant_tuning_loop_heartbeat_missing, park_allocator heartbeat) for that
  -- run and every run after. Applying the file top to bottom makes that impossible, but a partial or
  -- reordered apply must never be able to take down the fleet's dead-man switch over one advisory check.
  BEGIN
    IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.process_constant_evidence_drift` WHERE evidence_invalidated) THEN
      CALL `stock-trading-498512.ops.sp_raise_alert_once`(
        'warning', 'scheduled.cadence', 'process_constant_evidence_invalidated',
        CONCAT('Process-constant autotune evidence INVALIDATED by a later metric-formula correction — ',
               '90-day trailing p90 completion-minute-of-day; see payload for the persisted vs recomputed threat streaks: ',
               (SELECT STRING_AGG(
                  CONCAT(routine, '/', deadline_key, ' change ', old_value, '->', new_value),
                  '; ' ORDER BY routine, deadline_key, change_key, old_value, new_value)
                FROM `stock-trading-498512.state.process_constant_evidence_drift` WHERE evidence_invalidated)),
        (SELECT TO_JSON_STRING(ARRAY_AGG(t))
         FROM `stock-trading-498512.state.process_constant_evidence_drift` t WHERE evidence_invalidated));
    END IF;
  EXCEPTION WHEN ERROR THEN SELECT @@error.message;
  END;

  -- scheduled_query_stale (warning, MON H5, 2026-07-17). state.scheduled_query_version_drift detects only
  -- a VERSION mismatch among sources that have EVER beaten; a DTS config that silently STOPS forever (7 of
  -- the 12 can), or one registered but never once beaten, is invisible to it — nothing watched beat AGE.
  -- bigquery/63 now carries expected_interval_hours per query + a grace factor and exposes two new columns:
  --   * stale_beat        — monitored (has beaten >=1x) AND last_beat_ts older than interval x grace.
  --   * never_beat_overdue — NOT monitored AND the registry row was declared > 7 days ago (self-
  --                          bootstrapping grace: a freshly-registered query stays quiet for a week).
  -- Record-only, no RAISE (promotion-eligible via the bigquery/45 ladder later, like ddl_drift): a stalled
  -- scheduled query is also caught by its own DTS email-on-failure and the Cloud Monitoring absence policy;
  -- this is the in-band, digest-visible backstop. DEDUP-CRITICAL: the message lists ONLY sq_names +
  -- which failure mode (stable while the stalled set is stable, per the order_guard_omitted convention);
  -- daily-changing ages live ONLY in the JSON payload.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.scheduled_query_version_drift` WHERE stale_beat OR never_beat_overdue) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`('warning','scheduled.cadence','scheduled_query_stale',
      CONCAT('Scheduled-query beat-age dead-man — DTS config(s) overdue past their expected interval (x grace) or never-beat window: ',
        (SELECT STRING_AGG(CONCAT(sq_name, IF(never_beat_overdue, ' (NEVER beat)', ' (stale beat)')), ', ' ORDER BY sq_name)
         FROM `stock-trading-498512.state.scheduled_query_version_drift` WHERE stale_beat OR never_beat_overdue)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(sq_name, monitored, stale_beat, never_beat_overdue, expected_interval_hours, CAST(last_beat_ts AS STRING) AS last_beat_ts) ORDER BY sq_name))
       FROM `stock-trading-498512.state.scheduled_query_version_drift` WHERE stale_beat OR never_beat_overdue));
  END IF;

  -- probe_funding_stalled (warning, consumption-closure audit 2026-07-16) -- state.strategy_probe_
  -- funding_stalled (bigquery/62_probe_stake_funding.sql) flags a PROBE-phase newcomer frozen below
  -- the $2,000 floor for >=90 days; previously had no automated reader at all.
  -- DEDUP-CRITICAL: message lists ONLY strategy codes (stable while the stalled set is stable); the
  -- daily-changing numbers (funding_gap_dollars, days_since_probe_entry) live ONLY in the JSON
  -- payload, because ops.sp_raise_alert_once dedups on exact unresolved (category, message) -- a
  -- day-counter in the message would insert a new unresolved warning row + email EVERY night per
  -- stalled newcomer.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.strategy_probe_funding_stalled`) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`('warning','scheduled.cadence','probe_funding_stalled',
      CONCAT('PROBE newcomer(s) frozen below the $2,000 floor >=90 days: ',
        (SELECT STRING_AGG(strategy_code, ', ' ORDER BY strategy_code)
         FROM `stock-trading-498512.state.strategy_probe_funding_stalled`),
        ' — a deposit (sanctioned residual touch) or FIFO redistribution priority check is needed; per-strategy gap/days in payload'),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(strategy_code, funding_gap_dollars, days_since_probe_entry)))
       FROM `stock-trading-498512.state.strategy_probe_funding_stalled`));
  END IF;

  -- cash_flows_backfill_broken (warning, consumption-closure audit 2026-07-16) -- state.cash_flows_
  -- backfill_check (bigquery/68_cash_flows_backfill_check_dated.sql, date-scoped redefinition of the
  -- bigquery/22 apply-time gate) flags a backdated/duplicate/typo events.cash_flows row dated
  -- <= 2026-07-03 that shifts the NAV/sizing baseline every downstream consumer relies on. A future
  -- legitimate deposit cannot flip this (view is date-scoped), so it is now safe to poll nightly.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.cash_flows_backfill_check` WHERE NOT reconciled) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`('warning','scheduled.cadence','cash_flows_backfill_broken',
      'events.cash_flows rows dated <= 2026-07-03 no longer sum to the 9446.86 seed total — a backdated/duplicate/typo flow has shifted the NAV/sizing baseline; investigate before trusting analytics.strategy_nav (bigquery/68)',
      (SELECT TO_JSON_STRING(t) FROM `stock-trading-498512.state.cash_flows_backfill_check` t));
  END IF;

  -- ci_finding (warning, self-improvement audit 2026-07-16, CC-1 -- CI-findings consumption-closure
  -- bridge, bigquery/67_ci_findings_bridge.sql). Four CI guards (live-sql-parity, keyless-sa-audit,
  -- wif-binding-audit, guard-config-audit) each open/refresh a deduped GitHub issue on a finding, but
  -- nothing previously read those issues -- this closes the loop by raising/auto-resolving off
  -- state.ci_findings_open, so a finding reaches the monitored alert-emailer channel even on a day
  -- nobody manually reads GitHub Issues. AUTO-RESOLVE FIRST (matching the RECORD-THEN-RAISE convention
  -- above): once state.ci_findings_open is empty, clear any still-open ci_finding alert -- this also
  -- covers the case where the underlying workflow's next clean run wrote its unconditional resolved
  -- row (see live-sql-parity.yml's "Close finding issue if resolved" step) after a manually-closed GH
  -- issue would otherwise have stranded it. Record-only (does NOT join raise_msg), matching
  -- script_version_drift / ddl_drift / restore_stale above -- an open CI finding is a config/drift bug
  -- to fix, not a trading halt.
  UPDATE `stock-trading-498512.ops.alerts`
     SET resolved = TRUE, resolved_ts = CURRENT_TIMESTAMP(),
         resolved_note = CONCAT('auto-resolved: state.ci_findings_open empty. ', COALESCE(resolved_note, ''))
   WHERE NOT resolved AND category = 'ci_finding'
     AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.state.ci_findings_open`);

  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.ci_findings_open`) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'ci_finding',
      CONCAT('Open CI guard finding(s): ',
             (SELECT STRING_AGG(CONCAT(workflow, '/', finding_key), ', ' ORDER BY workflow, finding_key)
              FROM `stock-trading-498512.state.ci_findings_open`)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(workflow, finding_key, CAST(finding_ts AS STRING) AS finding_ts, detail, run_url)))
       FROM `stock-trading-498512.state.ci_findings_open`));
  END IF;

  -- ci_findings_bridge_stale (warning, MON H2, 2026-07-17). The ci_finding block above only ever fires
  -- when the bridge DELIVERS a finding — but ops.ci_findings is the DECLARED single delivery path for
  -- live-sql-parity drift (bigquery/67 / Claude_Task_Plan.md D3), and a DEAD bridge is indistinguishable
  -- from a clean one: zero rows reads identically to "no drift" while objects could sit drifted invisibly.
  -- As of 2026-07-17 the bridge has delivered ZERO live-sql-parity rows EVER (the workflow's INSERT was
  -- swallowed by `|| echo ::warning::` inside an otherwise-green run — fixed in live-sql-parity.yml this
  -- same pass). This dead-man fires when the newest live-sql-parity finding_ts is older than ~40h (the
  -- daily workflow cadence + one missed run of grace) OR — critically — when NONE has EVER been delivered
  -- (MAX over empty = NULL; COALESCE to the epoch makes the never-delivered state fire, which is the
  -- current state and exactly the never-armed failure the swallowed INSERT produced). Record-only, does
  -- NOT join raise_msg (a stalled plumbing bridge is a config fix, not a trading halt), matching
  -- ci_finding/ddl_drift. DEDUP-CRITICAL: the message is fully static (no timestamps/counts); detail is in
  -- the payload — so a persisting dead bridge dedups to a single open warning, not a fresh row every run.
  IF (
    SELECT COALESCE(MAX(finding_ts), TIMESTAMP '1970-01-01 00:00:00 UTC')
             < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 40 HOUR)
    FROM `stock-trading-498512.ops.ci_findings`
    WHERE workflow = 'live-sql-parity'
  ) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'ci_findings_bridge_stale',
      'ops.ci_findings has NO live-sql-parity row newer than ~40h (or none has EVER been delivered) — the DECLARED single delivery path for live-sql-parity drift (bigquery/67) may be dead. A dead bridge reads identically to "no drift", so drifted objects could sit unsurfaced. Verify the daily live-sql-parity.yml run: the WIF vars (GCP_WIF_PROVIDER/SERVICE_ACCOUNT) must be set AND the gh-ci-runner@ dataEditor grant on ops.ci_findings must be live, and the INSERT step must now fail-loud on error (fixed 2026-07-17). See payload for row count / last finding_ts.',
      (SELECT TO_JSON_STRING(STRUCT(
         (SELECT COUNT(*) FROM `stock-trading-498512.ops.ci_findings` WHERE workflow = 'live-sql-parity') AS live_sql_parity_rows,
         (SELECT CAST(MAX(finding_ts) AS STRING) FROM `stock-trading-498512.ops.ci_findings` WHERE workflow = 'live-sql-parity') AS last_finding_ts,
         CAST(CURRENT_TIMESTAMP() AS STRING) AS checked_at))));
  END IF;

  -- constant_tuning_loop_heartbeat_missing (warning, item 11 -- self-improvement audit 2026-07-11).
  -- meta_monitoring_heartbeat (ops/autonomy_levels.yaml) documents every active_auto/shadow loop should
  -- write an "evaluated this cycle" heartbeat with a scheduled-query dead-man's switch alerting on
  -- absence -- LIVE today for strategy_arsenal (SL1/SL3/SL4) but the four constant-tuning loops
  -- (process_reliability, strategy_playbook, execution_quality_tuning, calibration_parameter_carveout)
  -- had NEITHER a heartbeat write NOR a routine that ever evaluated them at all until Claude_Task_Plan.md's
  -- W5 section was extended (item 11) to write ops.heartbeat(source='loop:<id>') every W5 firing,
  -- regardless of whether that loop's own readiness view fired. cross_model_referee_independence (added
  -- 2026-07-15, promoted dormant->shadow) joins the same list, same W5 bullet pattern. Self-bootstrapping:
  -- a loop with ZERO ops.heartbeat rows ever (never yet evaluated even once post-deployment) does not
  -- alarm -- only a loop that HAS reported at least once and then goes quiet trips this, exactly the
  -- state.script_version_drift / instruction_drift self-bootstrapping convention above. W5 runs weekly;
  -- the ~10-day window tolerates one missed cycle before alarming. Staged-rollout WARNING (record-only),
  -- matching every other self-bootstrapping monitor in this file. park_allocator (added 2026-07-26, PARK
  -- v3 immediate-binding redesign, shadow->active_auto) joins this list too, per
  -- scripts/check_autonomy_consistency.py's coverage requirement -- but its REAL primary coverage is the
  -- dedicated, tighter, trading-day-aware block immediately below (this flat 10-calendar-day window is a
  -- required belt-and-suspenders membership for a loop whose actual cadence is daily, not weekly).
  IF EXISTS (
    SELECT 1 FROM UNNEST(['loop:process_reliability','loop:strategy_playbook',
                           'loop:execution_quality_tuning','loop:calibration_parameter_carveout',
                           'loop:cross_model_referee_independence','loop:research_quality_feedback',
                           'loop:park_allocator']) AS loop_source
    WHERE EXISTS (SELECT 1 FROM `stock-trading-498512.ops.heartbeat` h WHERE h.source = loop_source)
      AND NOT EXISTS (
        SELECT 1 FROM `stock-trading-498512.ops.heartbeat` h
        WHERE h.source = loop_source AND h.beat_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 10 DAY))
  ) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'constant_tuning_loop_heartbeat_missing',
      CONCAT('Constant-tuning loop(s) previously reporting a weekly W5 heartbeat have gone quiet >10 days: ',
             (SELECT STRING_AGG(loop_source, ', ' ORDER BY loop_source)
              FROM UNNEST(['loop:process_reliability','loop:strategy_playbook',
                            'loop:execution_quality_tuning','loop:calibration_parameter_carveout',
                            'loop:cross_model_referee_independence','loop:research_quality_feedback',
                            'loop:park_allocator']) AS loop_source
              WHERE EXISTS (SELECT 1 FROM `stock-trading-498512.ops.heartbeat` h WHERE h.source = loop_source)
                AND NOT EXISTS (
                  SELECT 1 FROM `stock-trading-498512.ops.heartbeat` h
                  WHERE h.source = loop_source AND h.beat_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 10 DAY)))),
      TO_JSON_STRING(STRUCT(CURRENT_TIMESTAMP() AS checked_at)));
  END IF;

  -- park_allocator daily-heartbeat staleness (warning, PARK v3 immediate-binding redesign, owner
  -- directive 2026-07-26). loop:park_allocator (ops/autonomy_levels.yaml) converted shadow->active_auto
  -- in this same change and is written DAILY by D1's PARK ALLOCATION CALL (every trading day) -- NOT
  -- weekly like the constant-tuning loops in the generic block above. Folding it only into that block's
  -- flat 10-CALENDAR-day window would be semantically wrong two ways: (1) 10 calendar days is far looser
  -- than appropriate for a nominally-daily loop; (2) because D1's daily beat and W5's own weekly
  -- belt-and-suspenders beat write the IDENTICAL heartbeat source, a real multi-day D1 outage could be
  -- invisibly papered over by W5's once-a-week write resetting the shared clock before the generic
  -- 10-day window ever trips -- defeating the point of watching a daily loop at all. This dedicated block
  -- uses a TRADING-day count via state.market_calendar (same idiom as bigquery/92_park_allocator.sql's
  -- 2026-07-19 park_switch_budget cooldown fix and bigquery/76_owner_confirmation_liveness.sql's
  -- trading_days_since_last_fill -- NOT a naive calendar-day DATE_DIFF, the exact bug class that fix
  -- removed) and a tighter >=3-trading-day threshold. Self-bootstrapping: park_last_beat IS NULL (no
  -- heartbeat row ever) skips the whole block -- no alarm before the loop's first-ever beat; park_allocator
  -- has beaten daily since 2026-07-19, so this arms immediately on apply. Deliberately expressed via a
  -- scalar `source = 'loop:park_allocator'` equality, NEVER an UNNEST(['loop:...']) literal -- adding a
  -- THIRD, single-member UNNEST literal here would shrink
  -- scripts/check_autonomy_consistency.py's cadence_detection_loops() intersection-of-UNNEST-lists to
  -- {park_allocator} alone and false-flag every other constant-tuning loop above as unmonitored. Reuses
  -- the same category ('constant_tuning_loop_heartbeat_missing') as the generic block so it rides the
  -- same emailer/auto-resolve wiring; sp_raise_alert_once dedups on (category, message), so the message
  -- text below is held stable (keyed on the frozen last-beat timestamp, not on the day this check runs)
  -- while the staleness persists, and is distinct from the generic block's message (which never names
  -- park_allocator, since park_allocator's own beats keep it out of that block's stale-source list under
  -- normal operation).
  BEGIN
    DECLARE park_last_beat TIMESTAMP;
    DECLARE park_trading_days_since_beat INT64;
    SET park_last_beat = (
      SELECT MAX(beat_ts) FROM `stock-trading-498512.ops.heartbeat` WHERE source = 'loop:park_allocator');
    IF park_last_beat IS NOT NULL THEN
      SET park_trading_days_since_beat = (
        SELECT COUNT(*)
        FROM `stock-trading-498512.state.market_calendar` mc
        WHERE mc.is_trading_day
          AND mc.cal_date > DATE(park_last_beat, 'America/Denver')
          AND mc.cal_date <= (SELECT last_trading_day FROM `stock-trading-498512.state.trading_day_today`));
      IF park_trading_days_since_beat >= 3 THEN
        CALL `stock-trading-498512.ops.sp_raise_alert_once`(
          'warning', 'scheduled.cadence', 'constant_tuning_loop_heartbeat_missing',
          CONCAT('loop:park_allocator (active_auto, daily D1 heartbeat) has gone quiet >=3 trading days ',
                 '-- last beat ', CAST(park_last_beat AS STRING), '. This is the DEDICATED trading-day-aware ',
                 'check (not the flat 10-calendar-day window above) because D1 writes this heartbeat every ',
                 'trading day, not weekly.'),
          TO_JSON_STRING(STRUCT(park_last_beat AS last_beat,
                                 park_trading_days_since_beat AS trading_days_since_beat,
                                 CURRENT_TIMESTAMP() AS checked_at)));
      END IF;
    END IF;
  END;

  -- Connector tool-inventory staleness (2026-08-08, bigquery/151_connector_tool_inventory.sql).
  -- OPS1's TOOL-INVENTORY DRIFT CHECK diffs the live per-connector tool roster against
  -- ops/connector_tools.yaml so a vendor-added tool -- which arrives as ask/needs-approval in the
  -- claude.ai connectors UI and would silently stall an unattended routine that calls it -- is caught
  -- the morning it appears. That check is SELF-REPORTED, and a self-reported check cannot detect its
  -- own omission: OPS1 could complete normally, log a clean note, and simply never have run the step
  -- (prompt drift, a skipped sub-agent, a truncated session). This block is the independent witness.
  -- It reads only the observation table's recency, so it stays true regardless of what OPS1 claims.
  -- RECORD-ONLY, WARNING, self-healing: once OPS1 resumes a trustworthy sweep the underlying condition
  -- clears on its own, so this category is in the #14 auto-age allowlist above (it has no ops.alert_
  -- policy row) rather than getting its own resolve-on-heal UPDATE, matching the connector /
  -- strategy_revised / script_version_drift convention this file already uses.
  -- DEDUP-CRITICAL: the message lists ONLY the affected connector names (stable while the stale set
  -- itself is stable, matching the trigger_missing / probe_funding_stalled / scheduled_query_stale
  -- convention elsewhere in this procedure) -- days_stale changes daily while a connector stays stale
  -- and lives in the payload only, per the exact bug this file's own #14 comment records for
  -- trigger_missing ("its message used to embed a daily-changing day-count, defeating
  -- sp_raise_alert_once's dedup").
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.connector_tool_inventory_stale`) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'connector_tool_inventory_stale',
      CONCAT('Connector tool-inventory observations are stale for: ',
             (SELECT STRING_AGG(connector, ', ' ORDER BY connector)
              FROM `stock-trading-498512.state.connector_tool_inventory_stale`),
             '. OPS1 completed without recording a trustworthy tool sweep, so the morning clean bill of health for connector tool drift is void. See payload for per-connector day counts.'),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(connector, last_good_run_date, days_stale) ORDER BY connector))
       FROM `stock-trading-498512.state.connector_tool_inventory_stale`));
  END IF;

  -- Account-snapshot gap watch (2026-08-08, bigquery/153_account_snapshot_gap_watch.sql). ops.
  -- account_snapshot holds one measured NAV/cash row per snapshot_date, written by D2a Step 0b for a
  -- single day per run -- there is no loop, so a trading day D2a does not run on is missing until it is
  -- explicitly backfilled (2026-07-23/24, the two days that prompted this file, were backfilled
  -- 2026-08-09 and the view is empty again). state.book_drawdown_watch's flow-adjusted peak_gain (bigquery/78) is a running MAX over
  -- whatever snapshot_date rows exist, so a missing day's NAV never enters that max -- if the gap day
  -- was a peak, peak_gain (and therefore peak_nav) is PERMANENTLY UNDERSTATED, and the -15% soft /
  -- -40% hard drawdown breaker under-triggers -- the fail-dangerous direction. snapshot_stale
  -- (bigquery/78) only catches a missing TODAY; it is structurally blind to a historical gap. BACKFILL
  -- IS POSSIBLE (v18, 2026-08-09 -- this REPLACES the v17 claim that it was impossible and must not be
  -- attempted). get_pa_performance_all_periods returns parallel dates[]/nav[] arrays per period, about a
  -- year of daily NAV, and D2a Step 0b already calls it but keeps only the last element. The v17 claim
  -- came from over-generalising events.cash_flows' 2026-08-05 deposit note, which correctly records that
  -- IBKR has no cash-transaction/statement ITEMISATION endpoint -- a different, narrower thing. Only nav
  -- is recoverable this way; cash/TWR columns are absent from that response and must stay NULL. This
  -- block is DETECTION plus a RECOVERY POINTER: a record-only WARNING naming every trading day between
  -- the first and last
  -- ops.account_snapshot row that has no row of its own (state.account_snapshot_gap,
  -- bigquery/153_account_snapshot_gap_watch.sql). RECORD-ONLY, WARNING, NEVER a halt -- does NOT join
  -- raise_msg, and bigquery/153's redefinition of state.book_drawdown_watch adds an OBSERVABILITY-ONLY
  -- peak_window_gap_days column with no new gate term, so state.trading_enabled behaves exactly as it
  -- did before this file. SELF-HEALING SHAPE for auto-age purposes, now genuinely
  -- so rather than only nominally (a gap day is no longer permanent): the check re-evaluates state.account_snapshot_gap fresh every run and simply re-raises
  -- (same stable message, deduped) for as long as it is non-empty, exactly like connector_tool_
  -- inventory_stale above -- it has no ops.alert_policy row, so it rides the #14 auto-age allowlist
  -- below (added alongside connector / strategy_revised / connector_tool_inventory_stale) rather than
  -- sitting open forever once raised.
  -- DEDUP-CRITICAL: the message lists ONLY the gap dates -- stable while the gap set is stable, which
  -- it is except when a NEW day goes missing. NOTE (v18): the set CAN now shrink, because gap days are
  -- backfillable (see this file's header); a shrink changes the message and therefore starts a NEW
  -- alert row rather than deduping onto the old one -- harmless, since the usual shrink is to empty,
  -- which raises nothing at all. Day counts and the surrounding prior/next NAV context live in the payload
  -- only, per the trigger_missing / probe_funding_stalled / connector_tool_inventory_stale convention
  -- elsewhere in this procedure.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.account_snapshot_gap`) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'account_snapshot_gap',
      CONCAT('ops.account_snapshot is missing a snapshot on trading day(s) that D2a never wrote -- the flow-adjusted peak in state.book_drawdown_watch may be understated until they are filled. THESE ARE RECOVERABLE: IBKR get_pa_performance_all_periods returns parallel dates[]/nav[] arrays (1M/YTD/1Y) covering roughly a year, so the missing nav can be read straight out of the endpoint D2a Step 0b already calls -- insert with source=ibkr-pa-history-backfill and leave cash/TWR columns NULL (they are not in that response). Gap day(s): ',
             (SELECT STRING_AGG(CAST(gap_date AS STRING), ', ' ORDER BY gap_date)
              FROM `stock-trading-498512.state.account_snapshot_gap`),
             '. See payload for per-gap surrounding NAV context.'),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(gap_date, prior_snapshot_date, prior_nav, next_snapshot_date, next_nav) ORDER BY gap_date))
       FROM `stock-trading-498512.state.account_snapshot_gap`));
  END IF;

  -- run_log_problem_unalerted (warning, record-only, bigquery/230_run_outcome_notification.sql,
  -- 2026-09-08 -- P4/P3 of the run-outcome-notification design). state.run_log_unalerted_problems is
  -- the INDEPENDENT WITNESS for ops.sp_log_run's own write-time escalation (P1 of the same design):
  -- that escalation raises routine_run_failed / routine_run_warning from INSIDE a
  -- BEGIN...EXCEPTION WHEN ERROR THEN...END best-effort block (C8 -- an alerting failure must never
  -- propagate out of run logging), so a write-time raise that itself throws is SILENT -- the terminal
  -- run_log row still lands (unconditional, C8), but nobody is ever told. This block re-checks, from
  -- outside that swallowing handler, whether every terminal problem row in the trailing 14 days
  -- (failed/halted, or completed with a non-blank error_msg) has EVER had a matching
  -- routine_run_failed/routine_run_warning alert -- resolved or not. Keying on EVER RAISED rather than
  -- OPEN is load-bearing: those two categories sit on the number 14 auto-age allowlist directly above
  -- (added in the SAME change as this block) and so close themselves after 7 days: an open-only anti-
  -- join would make THIS check re-fire on every one of those routine, self-healed closures, which is
  -- exactly the false-positive-every-night failure mode this comment's own review process rejects
  -- everywhere else in this file (see the STRING_AGG-ordering rule this whole file exists to enforce).
  -- RECORD-ONLY, WARNING, deliberately NOT joined to raise_msg: a routine that failed to log its own
  -- account of itself is a notification-plumbing defect, not a same-night trading halt, and an open
  -- CRITICAL here would feed state.trading_enabled's blocking_criticals (bigquery/107) the same way
  -- every other record-only block in this procedure is careful not to.
  -- DEDUP-CRITICAL, same convention this whole file enforces (see the file header): the message lists
  -- routine/run_date/status TRIPLES with a TOTAL order over EVERY field the message prints --
  -- (routine, run_date, status, run_id). status is included in the ORDER BY, not just the message,
  -- on purpose: scripts/check_alert_message_stability.py's rule (bigquery/227's own rule) requires
  -- the ORDER BY key to be a SUPERSET of every printed field, checkable from the call site alone,
  -- rather than resting on the (also true here) semantic argument that run_id alone already makes
  -- the row order unique -- run_id is a per-INSERT GENERATE_UUID(), included as the final tiebreaker
  -- so two distinct terminal problem rows for the same (routine, run_date, status) still sort
  -- deterministically. An unchanged open set therefore re-renders as the identical string and
  -- collapses onto one alert row instead of permuting into a fresh one every run.
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.run_log_unalerted_problems`) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.cadence', 'run_log_problem_unalerted',
      CONCAT('ops.sp_log_run reported a problem (failed/halted, or completed with a recorded error) ',
             'for the run(s) below, but no routine_run_failed/routine_run_warning alert was ever ',
             'raised for it -- the write-time escalation in ops.sp_log_run (bigquery/230) may have ',
             'thrown inside its own best-effort handler. See payload for the recorded error/note ',
             'detail. Affected routine/run_date/status: ',
             (SELECT STRING_AGG(
                CONCAT(routine, '/', CAST(run_date AS STRING), ' (', status, ')'), ', '
                ORDER BY routine, run_date, status, run_id)
              FROM `stock-trading-498512.state.run_log_unalerted_problems`)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(
          STRUCT(routine, run_date, status, run_id, error_detail)
          -- `status` is in this ORDER BY purely so it matches the message STRING_AGG above. The
          -- payload is NEVER part of sp_raise_alert_once's dedup key (it compares category+message
          -- only), so this has no functional effect -- but run_id already makes both orders total,
          -- and two adjacent aggregates over the same rows ordering differently reads as a defect
          -- to every future auditor who checks (two independent reviewers flagged it on the day
          -- this landed). Agreeing costs one word.
          ORDER BY routine, run_date, status, run_id))
       FROM `stock-trading-498512.state.run_log_unalerted_problems`));
  END IF;

  -- Single consolidated RAISE so the DTS failure-email fires once, AFTER every condition is recorded.
  IF raise_msg != '' THEN
    RAISE USING MESSAGE = CONCAT('STOCK-TRADING cadence/backup/heartbeat check FAILED — ', raise_msg);
  END IF;
END;

-- ============================================================================
-- REGISTRY BUMP. bigquery/63_scheduled_query_version_registry.sql's `cadence_check` MERGE-seed row
-- is bumped to expected_version='v22' (git_note extended with a v22 entry describing exactly the
-- three edits above) IN THIS SAME CHANGE, per C6 and scripts/check_sq_version_registry.py. That file
-- is the single source of the registry seed for every `ops.sp_sq_<name>` wrapper (see its own header
-- for why -- every prior cadence_check bump, v6 through v21, is a hand-edit to that same MERGE row,
-- never a duplicate per-file MERGE statement), so it is edited directly rather than reproduced here.
-- ============================================================================

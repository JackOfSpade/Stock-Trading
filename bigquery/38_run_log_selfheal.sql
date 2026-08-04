-- ops.run_log auto-backfill layer A — the RUNBOOK §38 2026-07-08 landed-but-unlogged stranding, made
-- self-healing (ITEM 3). Project: stock-trading-498512.
--
-- WHY: §38 documents a failure mode distinct from the §20 pre-push race: a routine's REAL output lands
-- on origin/main (git commit is proof) but the session dies in the separate, later BigQuery MCP call
-- before ops.sp_routine_end ever runs, so ops.run_log gets ZERO rows for that (routine, run_date) — not
-- 'started', not 'completed', nothing. ops.sp_assert_deps then FATAL-halts every downstream routine on
-- a dependency that, in truth, already delivered. Until this file, the only recovery was a human
-- cross-checking git vs BigQuery by hand and backfilling ops.run_log manually (§38's own account of the
-- 2026-07-08/09 unwind). This file makes that recovery MECHANICAL:
--   (a) ops.routine_commit_markers  — a durable marker that a routine's output commit landed on main,
--       written by CI (auto-merge-claude.yml) at merge time, independent of the routine's own session
--       ever reaching its ops.run_log completion write.
--   (b) state.run_log_selfheal_candidates — (routine, run_date) pairs that HAVE a landed-commit marker
--       but NO completed ops.run_log row: the exact §38 gap, expressed as an objective view.
--   (c) ops.sp_backfill_run_log_from_markers() — inserts the missing 'completed' ops.run_log row for
--       every candidate (note documents the git evidence) and then calls the EXISTING
--       ops.sp_auto_resolve_alerts() (34_alert_lifecycle.sql) so missing_dependency / missed_run /
--       routine_stalled / staleness clear off that fresh evidence in the same call — precisely the
--       "honest ops.run_log backfill alone should be sufficient" recovery path §38 already documents as
--       the intended mechanism, just triggered by a marker instead of a human.
--
-- MECHANICAL, NOT A GATE-WEAKENER: this NEVER invents a completed run — it only asserts what git
-- already proves (a commit landed on main under a parseable routine-id + run-date commit subject). No
-- human review/approval step is added anywhere (CLAUDE.md "Settled decisions"); the compensating
-- control is the marker itself (objective git evidence) plus the pre-existing fail-closed
-- ops.alert_policy allowlist in 34_alert_lifecycle.sql, unchanged by this file.
--
-- WHO WRITES THE MARKER / WHO CALLS THE PROC (both wired out-of-band from this file — see the shared
-- shared_edits spec that accompanies this file, NOT applied here):
--   * .github/workflows/auto-merge-claude.yml inserts one ops.routine_commit_markers row per merged
--     branch whose tip commit subject matches the canonical "<ROUTINE> <Heading> <YYYY-MM-DD>..."
--     convention, via the read-only-today gh-ci-runner WIF identity (needs a NARROW, table-scoped
--     dataEditor grant added for this one table only — see owner_actions).
--   * bigquery/scheduled_queries/cadence_check.sql CALLs ops.sp_backfill_run_log_from_markers() BEFORE
--     it evaluates missed_run/missing_dependency, so a landed-but-unlogged strand self-heals the same
--     night the dead-man's switch would otherwise fire on it.
--
-- APPLY ORDER: depends on 10_observability.sql (ops.run_log, ops.sp_log_run) and 34_alert_lifecycle.sql
-- (ops.sp_auto_resolve_alerts, ops.alert_policy). Apply after 34, i.e. after 37 in numeric order, via
-- the BigQuery MCP execute_sql. Idempotent (CREATE TABLE IF NOT EXISTS / CREATE OR REPLACE VIEW/
-- PROCEDURE); safe to re-run. ops.sp_backfill_run_log_from_markers() is ALSO idempotent at the DML
-- level, by construction, not by a separate "already backfilled" marker: state.run_log_selfheal_
-- candidates NOT-EXISTS-checks ops.run_log for a completed row at query time, so the instant this
-- procedure inserts one, that (routine, run_date) pair drops out of the candidate set — a second call,
-- same session or a later one, finds nothing left to insert for it.

-- ===== ops.routine_commit_markers — "this routine's output commit landed on main" =====
CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.routine_commit_markers` (
  routine STRING NOT NULL,        -- 'D1','D2',...,'M5','Q3','A1',... — same domain as ops.run_log.routine
  run_date DATE NOT NULL,         -- operating day (America/Denver) parsed from the commit subject
  git_commit STRING NOT NULL,     -- full SHA of the merged commit on main — the actual evidence
  commit_subject STRING,          -- verbatim commit subject the routine/run_date were parsed from (audit trail)
  marked_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  source STRING NOT NULL          -- 'auto-merge-claude.yml' | 'manual' | ... — who wrote this marker
) PARTITION BY run_date CLUSTER BY routine
OPTIONS(description='Durable marker that a routine real-output commit landed on origin/main, written independently of whether that routine ever wrote its own ops.run_log completion row (RUNBOOK §38 self-heal, ITEM 3). CI (auto-merge-claude.yml) is the intended writer, keyed off the merged commit subject. A row here for (routine, run_date) is git-verifiable evidence the routine actually produced output that day, even if ops.run_log never got a completed row for it.');

-- ===== state.run_log_selfheal_candidates — marker present, completed run_log row absent =====
-- Fail-closed by construction: routine/run_date/git_commit are NOT NULL on the marker table, so an
-- incomplete/garbled marker row simply cannot be written in the first place (no NULL-match false
-- positive risk here), and the NOT EXISTS below only ever narrows the candidate set, never widens it —
-- a missing/unreadable ops.run_log (e.g. a transient read error surfacing as an empty result) makes
-- NOT EXISTS TRUE and the pair looks like a candidate, exactly the fail-closed-toward-recovery posture
-- this file exists to provide (the alternative failure mode — silently deciding NOT to backfill a truly
-- missing completion — is the status quo bug being fixed, not a safety property to preserve).
CREATE OR REPLACE VIEW `stock-trading-498512.state.run_log_selfheal_candidates` AS
WITH latest_marker AS (
  -- One row per (routine, run_date): if CI ever double-writes a marker (retry, re-run), the most
  -- recent marked_ts wins — harmless, since all markers for the same pair attest the same git fact.
  SELECT routine, run_date, git_commit, commit_subject, marked_ts, source
  FROM `stock-trading-498512.ops.routine_commit_markers`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY routine, run_date ORDER BY marked_ts DESC) = 1
)
SELECT
  lm.routine,
  lm.run_date,
  lm.git_commit,
  lm.commit_subject,
  lm.marked_ts,
  lm.source
FROM latest_marker lm
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.ops.run_log` r
  WHERE r.routine = lm.routine AND r.run_date = lm.run_date AND r.status = 'completed'
);

-- ===== ops.sp_backfill_run_log_from_markers — mechanical self-heal, called from cadence_check.sql =====
-- Best-effort by contract with its caller (cadence_check.sql wraps every CALL to a self-heal/auto-
-- resolve procedure in its own BEGIN/EXCEPTION so a bug in here can never break the dead-man's switch
-- itself — see that file's existing sp_auto_resolve_alerts wrapping for the pattern this mirrors).
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_backfill_run_log_from_markers`()
BEGIN
  DECLARE backfilled_count INT64 DEFAULT 0;

  -- One INSERT ... SELECT reads state.run_log_selfheal_candidates exactly once and commits atomically,
  -- so within a single call every candidate is backfilled exactly once. rows_written is left NULL
  -- (the marker proves output landed, not how many rows) and branch is 'main' (the marker only exists
  -- because the commit is already merged there) — both honestly reflect what a git commit can and
  -- cannot attest, matching the honest-backfill discipline §38 asks for over a guessed value.
  --
  -- log_ts IS DELIBERATELY NOT SET HERE — it falls to ops.run_log's `DEFAULT CURRENT_TIMESTAMP()`, i.e.
  -- the moment the backfill ran. That is the LITERAL truth for this column ("when this row was logged")
  -- and it is intentionally left alone, because log_ts is load-bearing for a safety gate.
  --
  -- REJECTED ALTERNATIVE, and why (evaluated and reverted 2026-08-04, same session that proposed it).
  -- Backfilled rows DO pollute every completion-time distribution built off log_ts — this procedure runs
  -- from cadence_check.sql at ~05:15 UTC (22:15-23:15 MT), so each backfilled row lands a synthetic
  -- ~21:00-23:00 MT "completion". MEASURED 2026-08-04: D1's trailing-90d p90 is 1275 min (21:15 MT) with
  -- these rows in, and 1006 min (16:46 MT) with them out — the "fat late tail" that drove W5's
  -- process_reliability loop to autotune cadence_watch_deadline_local 21:00 -> 21:45 is mostly artifact.
  -- The tempting fix is to write an honest log_ts here (marked_ts). It is WRONG, on two counts:
  --   (1) marked_ts can PRECEDE run_date's midnight, making analytics.routine_health_scorecard's
  --       completion_minute_of_day NEGATIVE. Live example on 2026-08-04: marker (SL2, run_date
  --       2026-08-04, marked_ts 2026-08-03 19:44 MT) would compute -256.
  --   (2) It would weaken the SAME-DAY DOUBLE-RUN GUARD. The evening cohort (D1/D2/D2a/D3/SL3) counts a
  --       prior completion only when DATETIME(log_ts,'America/Denver') >= today 12:00. A backfill-time
  --       log_ts is ALWAYS after noon, so it always suppresses a duplicate run; a marked_ts can be BEFORE
  --       noon (live example: the D3 2026-08-03 marker at 04:34 MT), which would stop the guard counting
  --       it and open a double-run window that is structurally impossible today.
  -- The pollution is therefore fixed where it actually belongs — at the READER, not the writer: the
  -- scorecard now excludes backfilled rows from its completion-time percentiles (bigquery/89). That fix
  -- is also RETROACTIVE, which writing an honest log_ts here would not have been (existing rows keep
  -- their old timestamps, so the poisoned p90 would have persisted until they aged out of the 90d window).
  --
  -- If you change the note format below, update bigquery/89's exclusion regex in the same commit — it
  -- anchors on the '^(auto-)?backfilled' prefix, which is what makes a genuine backfill distinguishable
  -- from a normal run whose note merely MENTIONS backfilling (6 such D2 rows exist; they must NOT be
  -- excluded).
  INSERT INTO `stock-trading-498512.ops.run_log`
    (routine, run_date, status, session_id, branch, rows_written, error_msg, note)
  SELECT
    routine, run_date, 'completed', NULL, 'main', NULL, NULL,
    FORMAT('auto-backfilled from commit marker (ops.sp_backfill_run_log_from_markers, RUNBOOK §38 self-heal): git_commit=%s, commit_subject=%s, source=%s',
           git_commit, COALESCE(commit_subject, '(none)'), source)
  FROM `stock-trading-498512.state.run_log_selfheal_candidates`;

  SET backfilled_count = @@row_count;

  IF backfilled_count > 0 THEN
    -- Rules 1-3 of ops.sp_auto_resolve_alerts (34_alert_lifecycle.sql) clear missing_dependency /
    -- missed_run / routine_stalled directly off ops.run_log evidence -- the rows just inserted above --
    -- and Rule 4 (staleness) then finds zero other open criticals and self-clears too. This is exactly
    -- the recovery path RUNBOOK §38 already documents as sufficient once the honest ops.run_log rows
    -- exist ("no manual ops.alerts UPDATE needed at all"). Best-effort: a resolver bug must never
    -- swallow the backfill rows that already, unconditionally, landed above.
    BEGIN
      CALL `stock-trading-498512.ops.sp_auto_resolve_alerts`();
    EXCEPTION WHEN ERROR THEN
      SELECT @@error.message;
    END;

    -- Best-effort audit trail row (mirrors ops.sp_fire_drill_alert_latch's own FIRE_DRILL_ALERT_LATCH
    -- convention). 'SELFHEAL_RUN_LOG' is not in state.cadence_expected_today's enumerated routine list,
    -- so this can never itself become a cadence-monitored routine or be mistaken for a real one.
    BEGIN
      CALL `stock-trading-498512.ops.sp_log_run`(
        'SELFHEAL_RUN_LOG', CURRENT_DATE('America/Denver'), 'completed', NULL, NULL, backfilled_count, NULL,
        FORMAT('ops.sp_backfill_run_log_from_markers backfilled %d run_log row(s) from ops.routine_commit_markers.', backfilled_count));
    EXCEPTION WHEN ERROR THEN
      SELECT @@error.message;
    END;
  END IF;
END;

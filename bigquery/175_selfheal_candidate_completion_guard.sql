-- 175_selfheal_candidate_completion_guard.sql (2026-08-17, W5)
--
-- SUPERSEDED LIVE 2026-09-03 by bigquery/210_selfheal_inflight_guard.sql — that file is the current
-- single source of truth for the state.run_log_selfheal_candidates VIEW BODY. It carries the
-- latest_marker CTE and the halt regex below forward byte-identical and adds two terms: (TERM 2) no
-- terminal run_log row of ANY status, widening this file's 'completed'-only test so a run that HALTS
-- cannot be healed into a completion — the class alert 7144dbf6 named and that the commit-subject
-- regex structurally cannot catch, because the commit is written BEFORE the halt exists to describe;
-- and (TERM 1) no in-flight session, deferring the heal while a live 'started' row is younger than
-- the repo-wide 3h dead-run proxy. Kept here, unmodified, for DR-rebuild apply-in-order reference
-- only. DO NOT re-apply this CREATE statement live in isolation — doing so restores the path that
-- minted a 'completed' over a still-running SL2 on 2026-09-02 and a still-running SL3 on 2026-08-20.
-- The PROSE below is NOT superseded and is not duplicated in 210: this file remains the canonical
-- home of the halt-regex rationale, the write-side-CI-guard vs read-side-backstop argument, the SCOPE
-- note, the 2026-08-18 CORRECTION, the known-accepted W4 false positive, and the BIAS paragraph.
-- Project: stock-trading-498512. Apply after 174_web_call_telemetry.sql.
--
-- SUPERSEDES bigquery/38_run_log_selfheal.sql's definition of state.run_log_selfheal_candidates.
-- Nothing else in 38 changes: ops.routine_commit_markers (table) and
-- ops.sp_backfill_run_log_from_markers (procedure) are untouched and still canonical there. The
-- procedure reads this view, so narrowing the view is sufficient to change what it backfills.
--
-- ===== WHY =====
-- A ops.routine_commit_markers row asserts "this routine's OUTPUT commit landed on main", and
-- ops.sp_backfill_run_log_from_markers turns that assertion into a 'completed' ops.run_log row with no
-- further test. The marker is written by .github/workflows/auto-merge-claude.yml from the merged
-- commit's SUBJECT alone, via marker_routine_from_subject / marker_run_date_from_subject
-- (scripts/auto_merge_decision.sh). Those two functions answer "which routine and date does this
-- subject NAME" — never "did a routine RUN produce this commit". Two commit classes therefore minted
-- phantom completions, both observed live:
--
--   (A) A routine's own HALT commit. "W5 2026-08-16: HALT at pre-flight — BigQuery connector
--       de-authorized" parses to routine=W5, run_date=2026-08-16. That commit's own body reads
--       "HALTED W5 cleanly. No factbase edits, no writes." It was recorded as a completed run.
--   (B) A NON-routine commit whose subject merely BEGINS with a routine token. The operator's
--       "W5 weekend timing optimization, plus routine-scope CI guard and cadence cleanup"
--       (author 3615459+JackOfSpade@users.noreply.github.com, 2026-08-17) is a commit ABOUT W5, not
--       BY W5; with no date in the subject the run_date fallback attributed it to its own commit day.
--
-- MEASURED HARM (W5, 2026-08-17). Those two rows made W5 read 'completed' on both 2026-08-16 and
-- 2026-08-17, which defeated TWO independent recovery mechanisms at once:
--   1. The cadence dead-man's switch saw ran_completed_this_period=TRUE, so it could never raise
--      period_missed and W5 could never reach OPS0 auto-refire readiness. OPS0 logged exactly this
--      diagnosis on 2026-08-16 (events.decision_log, entry_type='cadence-watchdog-finding',
--      "a halted run reads completed, permanently blinding its dead-man switch") and could do nothing
--      about it, because the blinding row was upstream of everything OPS0 reads.
--   2. state.routine_catchup_window collapsed W5's evidence reach from 8.3 days to 0.07 — the
--      CATCH-UP EVIDENCE WINDOW protocol, whose entire purpose is to widen a routine's reach to cover
--      missed periods, was disarmed by the very rows that recorded the misses.
-- Net: two consecutive W5 cycles lost with nothing alarming, and a measurable data cost — 21
-- events.nogo_shadow rows sat past their close-out horizon because W5 is their only close-out writer.
-- The miss surfaced only because W4 flagged it in prose for a human to read.
--
-- THIS IS A RECURRING FAMILY, NOT A ONE-OFF. auto-merge-claude.yml's own inline comment records the
-- same phantom-completion outcome on 2026-08-04, when an SL2 commit's UTC-rendered fallback date
-- produced a 'completed' row for a run that never happened and blinded
-- state.queue_driven_silence_watch — the detector added the day before to catch SL2 going quiet.
-- That fix corrected the DATE limb. The 2026-08-17 CI fix (marker_author_is_routine +
-- marker_subject_declares_no_completion, both unit-tested in tests/test_auto_merge_logic.sh) closes
-- the "was this a routine output commit at all" limb at the WRITE side.
--
-- ===== WHY A SECOND LAYER HERE, AT THE READ SIDE =====
-- The CI guard cannot be the only control, for a reason visible in the data: ops.routine_commit_markers
-- accepts rows with source='manual', and three such rows exist today (D1, 2026-07-11/12/13). A manual
-- insert bypasses auto-merge-claude.yml entirely, so no write-side guard in that workflow can see it.
-- This view is the read-side backstop that a hand-written marker still has to pass.
--
-- SCOPE — deliberately the HALT class only. A commit subject can self-declare that its run did not
-- complete; it cannot declare its own authorship, because ops.routine_commit_markers has no author
-- column. Adding one was considered and REJECTED as disproportionate: the write-side guard already
-- blocks class (B) going forward, this view's own regex permanently suppresses class (A), and a
-- schema change plus a CI change plus a backfill would buy retroactive coverage of a set that is
-- already fully covered by those two guards. If a future audit finds class (B) recurring through a
-- path that bypasses CI, add the column then — with evidence, not ahead of it.
--
-- CORRECTION 2026-08-18 (interactive audit). The paragraph above previously read "the two existing
-- class-(B)/(A) marker rows are deleted by this file's companion DML ... a set that is, after the
-- delete, empty." That was never true of what actually ran. ONE row was deleted — the class-(B)
-- operator commit ("W5 weekend timing optimization…", 60f338e), confirmed absent from live
-- ops.routine_commit_markers. The class-(A) row (W5/2026-08-16, commit 3bd39e13, subject "W5
-- 2026-08-16: HALT at pre-flight — BigQuery connector de-authorized") is STILL LIVE, and W5's own
-- 2026-08-17 run note says so in its own count ("2 DELETEs: 1 phantom run_log row, 1 bad commit
-- marker" — one marker, not two). The header claim is corrected rather than the row deleted: the
-- marker is a truthful record that that commit landed, and this view's regex already filters it out
-- of candidacy permanently, so deleting it would mutate live data purely to make a comment accurate.
-- The load-bearing justification for rejecting an author column is the two guards, not an empty set.
--
-- KNOWN, ACCEPTED FALSE POSITIVE of the halt regex, recorded so a future audit does not re-derive it
-- as a defect: ops.routine_commit_markers also holds W4/2026-08-03, subject "W4 2026-W32: Weekly
-- Action Conversion — MTZ exit confirmed but halted; 6 theses queued". That "halted" describes a
-- TRADING order, not the run — W4 completed normally and already carries a genuine started→completed
-- run_log pair, so the suppression costs nothing. It is nonetheless a true instance of the regex
-- matching run-completion vocabulary in a non-run-status sentence. NOT tightened, deliberately:
-- scripts/auto_merge_decision.sh's BIAS paragraph settles this trade-off explicitly — both guards
-- fail toward NOT writing/backfilling, because a missing marker degrades to the loud path
-- (missing_dependency + the gate's git-evidence fallback) while a false marker silently blinds a
-- dead-man's switch, which is what cost two W5 cycles. A narrower regex would trade a recoverable
-- noisy miss for a chance at the silent failure this whole file exists to prevent.
--
-- BIAS: this guard fails toward NOT backfilling. That asymmetry is deliberate and matches the
-- write-side guard's. A MISSING backfill degrades to the pre-existing loud path — ops.sp_assert_deps
-- raises missing_dependency and the dependency gate's git-evidence fallback still applies, so a human
-- or a downstream routine finds out. A FALSE backfill silently blinds dead-man's switches, which is
-- what cost two cycles here. A noisy miss is recoverable; a silent false completion is not.
--
-- NOT A GATE-WEAKENER: the genuine §38 case is untouched. Verified against the live table while
-- writing this — OPS1's 2026-08-16 marker (commit 8f3ebae8, authored noreply@anthropic.com, editing
-- ops/connector_tools.yaml, which IS OPS1's real output) is a true landed-but-unlogged strand, and it
-- still backfills after this change. So do all six D1 markers. Only halt-declaring subjects drop out.
--
-- Idempotent (CREATE OR REPLACE VIEW); safe to re-run.
-- CORRECTION 2026-09-03 (interactive triage). This header previously ended "No dbt port exists for
-- this view, so no dbt-parity mirror is owed." That was true when written and is now FALSE:
-- dbt/models/state/run_log_selfheal_candidates.sql was added 2026-09-01 by the dbt view-coverage
-- burn-down, is generated mechanically by scripts/gen_dbt_port.py, and is proved by
-- scripts/verify_dbt_port.py on every CI run. Any change to this view's body therefore DOES owe a
-- regenerated port. (It is NOT in dbt/parity_live_scope.yml, so no live EXCEPT comparison is owed —
-- but token-identity to the canonical body is.) Retired here rather than deleted, per the standing
-- rule that a landed header is corrected in place with a dated line, never silently rewritten.

-- ===== state.run_log_selfheal_candidates — marker present, completed run_log row absent, AND the
-- ===== marker's own commit subject does not declare the run a non-completion.
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
)
-- THE 2026-08-17 GUARD. Word-boundary matched on the halt/abort vocabulary the halt-commit convention
-- actually uses, so an ordinary output subject cannot trip it (verified: "asphalt" does not match, and
-- neither does any live D1/D2/W5 output subject in the table today). A NULL commit_subject is treated
-- as NOT declaring a halt — it stays a candidate, preserving the fail-toward-recovery posture that
-- bigquery/38's header states for the NOT EXISTS term above; the guard only ever removes a row on
-- POSITIVE evidence that the commit announced a non-completion.
-- Keep this pattern in sync with marker_subject_declares_no_completion in scripts/auto_merge_decision.sh.
AND NOT REGEXP_CONTAINS(
      UPPER(COALESCE(lm.commit_subject, '')),
      r'\b(HALT|HALTS|HALTED|HALTING|ABORT|ABORTS|ABORTED|ABORTING)\b'
    );

-- 210_selfheal_inflight_guard.sql (2026-09-03, interactive triage)
-- Project: stock-trading-498512. Apply after 209_owner_confirmation_park_tap_liveness.sql.
--
-- SUPERSEDES bigquery/175_selfheal_candidate_completion_guard.sql's definition of
-- state.run_log_selfheal_candidates (which itself superseded bigquery/38_run_log_selfheal.sql's).
-- Chain: 38 -> 175 -> 210. Nothing else moves: ops.routine_commit_markers (table) and
-- ops.sp_backfill_run_log_from_markers (procedure) stay canonical in bigquery/38, and 175 stays the
-- canonical home of the HALT-regex rationale, the CI-guard/read-side-backstop argument, the SCOPE
-- note, the 2026-08-18 CORRECTION and the BIAS paragraph. The procedure reads this view, so
-- narrowing the view is sufficient to change what it backfills -- 175's own framing, unchanged.
--
-- ===== WHAT TRIGGERED THIS =====
-- ops.alerts info row 7144dbf6-f3fe-4679-b2fa-ae31c8897b5f (OPS2, 'selfheal_backfills_inflight_run',
-- raised 2026-09-03 04:20 UTC). 175's candidacy test asks two questions -- "is there a completed row"
-- and "does the commit subject declare a halt" -- and NEITHER asks whether the session that wrote the
-- commit is STILL RUNNING. A routine lands its output commit BEFORE it writes its own terminal row,
-- so between those two writes it is, by 175's test, a backfill candidate. ops.sp_backfill_run_log_
-- from_markers then mints a 'completed' row over a live run.
--
-- ===== MEASURED, NOT INFERRED =====
-- Every auto-backfill this system has ever performed (11 rows, ops.run_log note prefix
-- '^(auto-)?backfilled'), each evaluated at ITS OWN heal instant against the run_log rows that
-- existed at that instant:
--
--   routine/run_date   heal (MT)      live 'started' at heal   terminal rows   the run's own terminal
--   D1/2026-07-11..16  (6 rows)       none                     0               none  <- genuine strand
--   D2/2026-07-19      03:11          none                     0               halted 17:21 (+849m)
--   OPS1/2026-08-16    17:27          none                     0               none  <- genuine strand
--   SL3/2026-08-20     22:22          20:04  (age 137 min)     0               completed 23:49 (+87m)
--   D1/2026-08-23      23:15          none                     0               none  <- genuine strand
--   SL2/2026-09-02     19:27          19:11  (age  15 min)     0               completed 19:31  (+4m)
--
-- EXACTLY TWO of the eleven had a live 'started' row (non-NULL session_id, no terminal row yet) at
-- heal time, and BOTH were premature -- the run wrote its own honest terminal row 87 and 4 minutes
-- later. The other nine had none. So "is there an open in-flight session" separates the premature
-- heals from the genuine ones perfectly on the whole history, with no tuned constant doing the work.
--
-- ===== TERM 1 -- IN-FLIGHT DEFERRAL =====
-- Exclude a (routine, run_date) whose newest 'started' row carries a non-NULL session_id and is
-- younger than THREE HOURS. Three hours is not invented here: it is the repo-wide in-flight /
-- dead-run proxy, cited as such in Claude_Task_Plan.md's shared-rules bullet "QUIESCENCE REBUTTAL to
-- the 3h in-flight rule" ("the same constant as the 'repo-wide dead-run criterion' the dust-order
-- mutex cites"). Replayed at the two realized instants: SL2 age 15 min and SL3 age 137 min are both
-- inside it, so both premature mints are prevented; all nine genuine heals have no live 'started' row
-- at all and are untouched.
-- The bound is what keeps this a DEFERRAL rather than a suppression. A session that truly dies after
-- writing 'started' ages past 3h and heals on the next call -- ops.sp_backfill_run_log_from_markers
-- is called nightly from bigquery/scheduled_queries/cadence_check.sql (~22:15 MT), and again from
-- OPS2 STEP 0 and D3's self-heal step -- so the worst case is one cycle late, never never.
-- NOTE the deliberate absence of a marked_ts-vs-started_ts comparison. Deferring only when the marker
-- POSTDATES the session start was considered and dropped: minting a 'completed' over a demonstrably
-- live run is wrong regardless of which came first, and the extra term only ever re-opens that door.
-- HONEST COST, stated rather than discovered later: a routine still in flight at cadence_check time
-- with its commit already landed no longer has its missed_run pre-empted by a synthetic completion,
-- so that night's dead-man's switch can raise a transient missed_run which clears the moment the run
-- writes its real terminal row (ops.sp_auto_resolve_alerts Rule 2 reads run_log evidence directly).
-- On the measured history that is at most the SL3/2026-08-20 instance -- roughly one transient alert
-- in two months. This is exactly the trade 175's own BIAS paragraph already settles in this
-- direction: "A noisy miss is recoverable; a silent false completion is not."
--
-- ===== TERM 2 -- ANY TERMINAL ROW, NOT JUST 'completed' =====
-- 175 (and 38 before it) tested only for a 'completed' row. ops.run_log's status vocabulary is
-- completed / halted / failed / started (721 / 45 / 7 / 721 rows live), so a run that HALTS leaves a
-- terminal row that this view did not look at -- and the marker then heals the halt into a
-- 'completed'. That is the precise class alert 7144dbf6 names and that 175's commit-subject regex
-- structurally cannot catch: "a live session that commits an intermediate artifact and then
-- legitimately halts on a LATER gate (trading halt, order-guard block, cash tripwire) gets a false
-- completed, and the commit-subject regex cannot catch it because the commit was written BEFORE the
-- halt existed to describe."
-- COLLATERAL ON ALL HISTORY: exactly three marker pairs have a halted/failed row -- D2/2026-07-19,
-- D2/2026-07-26 and W5/2026-08-16. The first two already carry a genuine 'completed' row and were
-- already excluded; the third is the 2026-08-16 W5 case 175's regex already suppresses permanently.
-- So TERM 2 changes NOTHING on any row that has ever existed, and closes the class going forward.
-- IDEMPOTENCY IS PRESERVED, and by the same construction 38's header relies on: the backfilled row is
-- itself status='completed', so it counts in n_terminal and the pair drops out of the candidate set
-- the instant it lands.
--
-- ===== SHAPE =====
-- 175's correlated NOT EXISTS is replaced by a LEFT JOIN onto a pre-aggregated per-(routine, run_date)
-- CTE. Not cosmetic: TERM 1 needs an inequality, and BigQuery rejects a correlated subquery whose
-- condition is an inequality it cannot de-correlate -- the same limit bigquery/194's CRITICAL 1
-- comment documents and that dbt/tests/assert_open_orders_no_stale_pending.sql's guard (2) was already
-- written as an anti-join to avoid. The latest_marker CTE and the halt regex are carried forward
-- BYTE-IDENTICAL from 175.
--
-- APPLY: idempotent (CREATE OR REPLACE VIEW); safe to re-run. state.run_log_selfheal_candidates
-- returns 0 rows immediately before and after this apply, so this is a no-live-change apply.
-- A dbt port DOES exist for this view -- dbt/models/state/run_log_selfheal_candidates.sql, added
-- 2026-09-01 by the dbt view-coverage burn-down. (bigquery/175's header still says "No dbt port
-- exists for this view"; that sentence was true when written and is now retired by a dated correction
-- appended to 175.) Regenerate the port with scripts/gen_dbt_port.py and prove it with
-- scripts/verify_dbt_port.py -- never hand-edit it.

CREATE OR REPLACE VIEW `stock-trading-498512.state.run_log_selfheal_candidates` AS
WITH latest_marker AS (
  -- One row per (routine, run_date): if CI ever double-writes a marker (retry, re-run), the most
  -- recent marked_ts wins — harmless, since all markers for the same pair attest the same git fact.
  SELECT routine, run_date, git_commit, commit_subject, marked_ts, source
  FROM `stock-trading-498512.ops.routine_commit_markers`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY routine, run_date ORDER BY marked_ts DESC) = 1
),
run_state AS (
  -- Pre-aggregated so the two guards below are plain scalar comparisons on a joined row rather than
  -- correlated subqueries (see the SHAPE note in the header).
  -- n_terminal counts the BACKFILLED 'completed' row too, which is what preserves idempotency.
  -- last_live_started_ts ignores session_id IS NULL rows: the backfill writes session_id NULL, so a
  -- backfilled row can never be mistaken for evidence of a live session.
  SELECT
    routine,
    run_date,
    COUNTIF(status IN ('completed', 'halted', 'failed'))                        AS n_terminal,
    MAX(IF(status = 'started' AND session_id IS NOT NULL, log_ts, NULL))        AS last_live_started_ts
  FROM `stock-trading-498512.ops.run_log`
  GROUP BY routine, run_date
)
SELECT
  lm.routine,
  lm.run_date,
  lm.git_commit,
  lm.commit_subject,
  lm.marked_ts,
  lm.source
FROM latest_marker lm
LEFT JOIN run_state rs
  ON rs.routine = lm.routine AND rs.run_date = lm.run_date
-- TERM 2 (2026-09-03): no terminal row of ANY kind. Widened from 38/175's 'completed'-only test —
-- a halted/failed run has already recorded its own honest outcome and must never be overwritten by a
-- marker-derived 'completed'. A missing rs row (no ops.run_log rows at all for the pair) COALESCEs to
-- 0 and stays a candidate, preserving 38's fail-toward-recovery posture for the never-logged strand.
WHERE COALESCE(rs.n_terminal, 0) = 0
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
      )
-- TERM 1 (2026-09-03): not demonstrably in flight. Defer while the newest 'started' row for this pair
-- carries a real session_id and is younger than the repo-wide 3h dead-run proxy. This DELAYS a heal,
-- it never cancels one: once the started row ages past 3h the pair is a candidate again and the next
-- nightly caller heals it.
  AND NOT (
        rs.last_live_started_ts IS NOT NULL
    AND rs.last_live_started_ts > TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 3 HOUR)
      );

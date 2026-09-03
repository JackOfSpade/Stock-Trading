-- PROVENANCE (hand-maintained above the generated body; scripts/gen_dbt_port.py replaces this block
-- on every regeneration, so it is restored by hand each time — see the generated header below).
-- Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence, so
-- scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- REPOINTED 2026-09-03 from bigquery/175 to bigquery/210_selfheal_inflight_guard.sql, which adds the
-- two terms that stop ops.sp_backfill_run_log_from_markers minting a 'completed' over a run that is
-- still in flight (TERM 1, the repo-wide 3h dead-run proxy) or over one that already recorded a
-- halted/failed outcome (TERM 2). Not in dbt/parity_live_scope.yml, so no live EXCEPT comparison is
-- owed — but token-identity to the canonical body is, and CI proves it on every run.
-- Parallel-run dbt port of bigquery/210_selfheal_inflight_guard.sql:state.run_log_selfheal_candidates — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
WITH latest_marker AS (
  -- One row per (routine, run_date): if CI ever double-writes a marker (retry, re-run), the most
  -- recent marked_ts wins — harmless, since all markers for the same pair attest the same git fact.
  SELECT routine, run_date, git_commit, commit_subject, marked_ts, source
  FROM {{ source('ops', 'routine_commit_markers') }}
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
  FROM {{ source('ops', 'run_log') }}
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
      )

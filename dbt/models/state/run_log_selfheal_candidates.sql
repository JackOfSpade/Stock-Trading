-- Parallel-run dbt port of bigquery/175_selfheal_candidate_completion_guard.sql:state.run_log_selfheal_candidates — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH latest_marker AS (
  -- One row per (routine, run_date): if CI ever double-writes a marker (retry, re-run), the most
  -- recent marked_ts wins — harmless, since all markers for the same pair attest the same git fact.
  SELECT routine, run_date, git_commit, commit_subject, marked_ts, source
  FROM {{ source('ops', 'routine_commit_markers') }}
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
  SELECT 1 FROM {{ source('ops', 'run_log') }} r
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
    )

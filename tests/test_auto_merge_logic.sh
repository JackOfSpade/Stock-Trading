#!/usr/bin/env bash
# Functional tests for scripts/auto_merge_decision.sh — the CI-gate + delete-safety predicates that
# .github/workflows/auto-merge-claude.yml sources to decide whether a branch merges to main
# and whether a merged branch is safe to delete (2026-07-04, code-quality audit).
#
# This sources the SAME functions the production workflow sources (not a reimplementation) and
# exercises them against a scratch git repo with fixture branches/commits, plus canned `gh api` JSON
# for the CI-conclusion parsing. Wired into ci.yml's `test` job.
#
# Scenarios covered (per the audit finding — this logic previously had zero functional coverage,
# only actionlint/shellcheck syntax-level checks):
#   * a red-CI branch must be skipped (not merged)
#   * a green-CI branch must be allowed to merge
#   * a branch whose tip advanced AFTER a merge decision was made must NOT be treated as safe to delete
#   * a branch with no CI run yet must be skipped, fail-closed (not treated as green)
#
# Run:  bash tests/test_auto_merge_logic.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../scripts/auto_merge_decision.sh
source "$ROOT/scripts/auto_merge_decision.sh"

fail=0
pass_count=0

assert_true() {   # assert_true <description> <command...>
  local desc="$1"; shift
  if "$@"; then
    echo "PASS: $desc"
    pass_count=$((pass_count + 1))
  else
    echo "FAIL: $desc (expected success/true, got failure)"
    fail=1
  fi
}

assert_false() {  # assert_false <description> <command...>
  local desc="$1"; shift
  if ! "$@"; then
    echo "PASS: $desc"
    pass_count=$((pass_count + 1))
  else
    echo "FAIL: $desc (expected failure/false, got success)"
    fail=1
  fi
}

assert_eq() {     # assert_eq <description> <actual> <expected>
  local desc="$1" actual="$2" expected="$3"
  if [ "$actual" = "$expected" ]; then
    echo "PASS: $desc"
    pass_count=$((pass_count + 1))
  else
    echo "FAIL: $desc (expected '$expected', got '$actual')"
    fail=1
  fi
}

# ---- ci_conclusion_from_json / is_ci_green: the fail-closed CI gate ------------------------

conclusion="$(ci_conclusion_from_json '{"workflow_runs":[{"conclusion":"success"}]}')"
assert_eq "green-CI JSON parses to 'success'" "$conclusion" "success"
assert_true "green-CI branch: is_ci_green must allow the merge" is_ci_green "$conclusion"

conclusion="$(ci_conclusion_from_json '{"workflow_runs":[{"conclusion":"failure"}]}')"
assert_eq "red-CI JSON parses to 'failure'" "$conclusion" "failure"
assert_false "red-CI branch: is_ci_green must SKIP the merge" is_ci_green "$conclusion"

conclusion="$(ci_conclusion_from_json '{"workflow_runs":[]}')"
assert_eq "no-CI-run-yet JSON parses to 'none'" "$conclusion" "none"
assert_false "branch with no CI run yet: is_ci_green must SKIP, fail-closed" is_ci_green "$conclusion"

conclusion="$(ci_conclusion_from_json '')"
assert_eq "empty/failed API response parses to 'error'" "$conclusion" "error"
assert_false "gh api failure: is_ci_green must SKIP, fail-closed" is_ci_green "$conclusion"

conclusion="$(ci_conclusion_from_json '{"workflow_runs":[{"status":"in_progress","conclusion":null}]}')"
assert_false "in-progress CI: is_ci_green must SKIP until it completes" is_ci_green "$conclusion"

# ---- is_secondary_gate_satisfied: the path-gated Golden Scenarios schema-validate gate (BUG FIX,
# rev 2026-07-11 adversarial self-audit — this workflow used to never check golden-scenarios.yml at
# all, so a failing HARD GATE job had zero effect on whether a commit merged) ------------------------

conclusion="$(ci_conclusion_from_json '{"workflow_runs":[{"conclusion":"success"}]}')"
assert_true "green golden-scenarios run: is_secondary_gate_satisfied must allow the merge" \
  is_secondary_gate_satisfied "$conclusion"

conclusion="$(ci_conclusion_from_json '{"workflow_runs":[{"conclusion":"failure"}]}')"
assert_false "red golden-scenarios run (schema-validate failed): is_secondary_gate_satisfied must SKIP the merge" \
  is_secondary_gate_satisfied "$conclusion"

conclusion="$(ci_conclusion_from_json '{"workflow_runs":[]}')"
assert_eq "no matching golden-scenarios run parses to 'none'" "$conclusion" "none"
assert_true "no golden-scenarios run at all (path filter excluded this commit): is_secondary_gate_satisfied must NOT block — most commits never touch the gated paths" \
  is_secondary_gate_satisfied "$conclusion"

conclusion="$(ci_conclusion_from_json '')"
assert_false "gh api failure querying golden-scenarios: is_secondary_gate_satisfied must SKIP, fail-closed (an API error is not the same fact as 'legitimately did not run')" \
  is_secondary_gate_satisfied "$conclusion"

conclusion="$(ci_conclusion_from_json '{"workflow_runs":[{"status":"in_progress","conclusion":null}]}')"
assert_false "in-progress golden-scenarios run: is_secondary_gate_satisfied must SKIP until it completes" \
  is_secondary_gate_satisfied "$conclusion"

# BUG FIX regression (2026-07-14 audit finding): a non-empty but ERROR-SHAPED API response (no
# workflow_runs array at all, e.g. gh api's stdout on an HTTP error) used to parse to "none" —
# identical to a legitimate zero-runs response — silently satisfying is_secondary_gate_satisfied
# instead of blocking the merge like a real API error must.
conclusion="$(ci_conclusion_from_json '{"message":"Not Found"}')"
assert_eq "malformed/error-shaped JSON (missing workflow_runs) parses to 'error', not 'none'" "$conclusion" "error"
assert_false "is_secondary_gate_satisfied must NOT treat a malformed API response as satisfied" is_secondary_gate_satisfied "$conclusion"

# ---- is_ancestor_of: already-merged + re-confirm-before-delete, against a scratch git repo --

SCRATCH="$(mktemp -d)"
cleanup() { cd "$ROOT" 2>/dev/null || true; rm -rf "$SCRATCH"; }
trap cleanup EXIT

cd "$SCRATCH"
git init -q -b main
git config user.name "test"
git config user.email "test@example.com"
echo "seed" > f.txt
git add f.txt
git commit -q -m "seed"

# A branch fully merged into main: already-merged check (and delete-safety) must see it as an ancestor.
git checkout -q -b merged-branch
echo "merged change" >> f.txt
git commit -q -am "merged change"
git checkout -q main
git merge -q --no-ff merged-branch -m "merge merged-branch"
assert_true "a branch merged into main IS an ancestor (already-merged / safe-to-delete)" \
  is_ancestor_of merged-branch main

# A branch whose tip advances AFTER the merge decision (a push landing during the merge window) must
# NOT look like an ancestor, so the re-confirm-before-delete check must refuse to delete it.
git checkout -q -b advances-after-merge
echo "v1" >> f.txt
git commit -q -am "v1"
git checkout -q main
git merge -q --no-ff advances-after-merge -m "merge advances-after-merge (decision point)"
git checkout -q advances-after-merge
echo "v2 pushed during the merge window" >> f.txt
git commit -q -am "v2 pushed during the merge window"
git checkout -q main
assert_false "a branch that advanced AFTER the merge decision is NOT an ancestor — must NOT be deleted" \
  is_ancestor_of advances-after-merge main

# An unmerged branch must not be mistaken for "already merged, just clean up".
git checkout -q -b unmerged-branch
echo "unmerged" >> f.txt
git commit -q -am "unmerged"
git checkout -q main
assert_false "an unmerged branch is NOT an ancestor of main — must attempt a real merge, not skip as already-merged" \
  is_ancestor_of unmerged-branch main

# ---- ci_run_id_from_json / ci_run_attempt_from_json / should_retry_failed_ci: the one-shot,
# content-free CI retry (2026-07-15, self-improvement audit — CONFIRMED GAP
# red-ci-merge-conflict-no-remediation) ------------------------------------------------------

run_id="$(ci_run_id_from_json '{"workflow_runs":[{"id":12345,"conclusion":"failure","run_attempt":1}]}')"
assert_eq "run id parses from a real run" "$run_id" "12345"

attempt="$(ci_run_attempt_from_json '{"workflow_runs":[{"id":12345,"conclusion":"failure","run_attempt":1}]}')"
assert_eq "run_attempt parses from a real run" "$attempt" "1"

run_id="$(ci_run_id_from_json '{"workflow_runs":[]}')"
assert_eq "no matching run: run id is empty" "$run_id" ""

run_id="$(ci_run_id_from_json '')"
assert_eq "gh api failure: run id is empty (fail closed, no retry attempted)" "$run_id" ""

# Sibling fail-closed coverage for the run-metadata parsers, restoring parity with ci_conclusion_from_json's
# full input matrix above (2026-07-17 parallel refactor — Part-E test-coverage gap). ci_run_attempt_from_json
# gates should_retry_failed_ci (which fires ONLY when run_attempt == "1"), so its "" result — never a number,
# never "null" — on no-run / API-failure / error-shaped input is the load-bearing guarantee that a wrongful
# retry can't fire against the main-merge automation. It was asserted only on the happy path; pin the rest.
attempt="$(ci_run_attempt_from_json '{"workflow_runs":[]}')"
assert_eq "no matching run: run_attempt is empty (fail closed — should_retry can't see '1')" "$attempt" ""
attempt="$(ci_run_attempt_from_json '')"
assert_eq "gh api failure: run_attempt is empty (fail closed, no retry)" "$attempt" ""
# Error-shaped body (no workflow_runs array, e.g. gh api's stdout on an HTTP error). Each parser carries its
# OWN copy of the (.workflow_runs|type)!="array" guard, so ci_conclusion_from_json's malformed test above does
# NOT cover these two — assert them directly.
attempt="$(ci_run_attempt_from_json '{"message":"Not Found"}')"
assert_eq "error-shaped JSON (missing workflow_runs): run_attempt is empty, not a bogus number" "$attempt" ""
run_id="$(ci_run_id_from_json '{"message":"Not Found"}')"
assert_eq "error-shaped JSON (missing workflow_runs): run id is empty, not a bogus id" "$run_id" ""

# End-to-end lock: the parser's actual no-run output, piped straight into the predicate, must NOT trigger a
# retry. The should_retry assertions below feed hardcoded "1"/"" literals, leaving the parser->predicate
# wiring unpinned — a future edit that made the parser emit "1" for a no-run state would slip through them.
assert_false "no-run run_attempt piped into should_retry_failed_ci must NOT retry (fail closed end-to-end)" \
  should_retry_failed_ci "failure" "$(ci_run_attempt_from_json '{"workflow_runs":[]}')"

assert_true "first-attempt genuine failure: should_retry_failed_ci allows ONE retry" \
  should_retry_failed_ci "failure" "1"
assert_false "second-attempt failure (already retried once): should_retry_failed_ci must NOT retry again" \
  should_retry_failed_ci "failure" "2"
assert_false "in-progress run: should_retry_failed_ci must NOT retry (not a terminal failure)" \
  should_retry_failed_ci "in_progress" "1"
assert_false "no-run-yet ('none'): should_retry_failed_ci must NOT retry" \
  should_retry_failed_ci "none" "1"
assert_false "API error: should_retry_failed_ci must NOT retry" \
  should_retry_failed_ci "error" "1"
assert_false "missing run_attempt (empty string): should_retry_failed_ci must NOT retry" \
  should_retry_failed_ci "failure" ""

# ---- ci_run_created_at_from_json / should_redispatch_stuck_secondary_gate: the stuck-secondary-gate
# one-shot re-dispatch (2026-08-19). OBSERVED TWICE, both stuck permanently: run 32215104789
# (branch claude/sl3-2026-08-18, created_at 2026-08-19T04:15:35Z, still "queued" ~17h later — the
# open ops.ci_findings stranded_branch row as of this writing) and a run from
# fix/alert-triage-2026-08-04 (created_at 2026-08-06T16:39:13Z, still "queued" 13 days later;
# branch since deleted). Every OTHER golden-scenarios run in both windows completed in 2-6 minutes.
# should_retry_failed_ci (above) cannot cover this: nothing failed, and "queued" is non-terminal.
# The remediation the predicate below gates is a fresh `gh workflow run golden-scenarios.yml --ref
# <branch>` dispatch, NOT a `gh run rerun` of the stuck run itself — MEASURED live against run
# 32215104789 (2026-08-19): `gh run rerun` fails ("cannot be rerun; This workflow is already
# running", exit 1) and `gh run cancel` also fails (HTTP 500) on a never-dispatched "queued" run,
# but `gh workflow run --ref` succeeds and creates a new run (32272701107) against the same
# head_sha — sufficient because the workflow's own CI-gate query is per_page=1 (most-recent-run-
# for-this-SHA), so the new run's conclusion is what gets read once it completes; the zombie run's
# perpetual "queued" status becomes irrelevant. See scripts/auto_merge_decision.sh's comment above
# should_redispatch_stuck_secondary_gate for the full detail. --------------------------------------

created_at="$(ci_run_created_at_from_json '{"workflow_runs":[{"id":32215104789,"conclusion":null,"status":"queued","run_attempt":1,"created_at":"2026-08-19T04:15:35Z"}]}')"
assert_eq "created_at parses from a real run" "$created_at" "2026-08-19T04:15:35Z"

created_at="$(ci_run_created_at_from_json '{"workflow_runs":[]}')"
assert_eq "no matching run: created_at is empty" "$created_at" ""

created_at="$(ci_run_created_at_from_json '')"
assert_eq "gh api failure: created_at is empty (fail closed, no redispatch attempted)" "$created_at" ""

# Error-shaped body (no workflow_runs array, e.g. gh api's stdout on an HTTP error) — mirrors the
# equivalent ci_run_id_from_json / ci_run_attempt_from_json coverage above; each parser carries its
# own copy of the (.workflow_runs|type)!="array" guard.
created_at="$(ci_run_created_at_from_json '{"message":"Not Found"}')"
assert_eq "error-shaped JSON (missing workflow_runs): created_at is empty, not a bogus timestamp" "$created_at" ""

# Fixed, deterministic clock for the age predicate — NOT `date` with no arguments, so this test
# never flakes on wall-clock timing or on which machine/timezone runs it. NOW_EPOCH's UTC rendering
# is 2026-08-19T12:00:00Z; STUCK_CREATED_AT is 61 minutes earlier (over the 60-minute threshold),
# FRESH_CREATED_AT is 5 minutes earlier (under it — ordinary queue latency, must NOT fire).
NOW_EPOCH=1787140800
STUCK_CREATED_AT="2026-08-19T10:59:00Z"   # 61 minutes before NOW_EPOCH (3660s > 3600s threshold)
FRESH_CREATED_AT="2026-08-19T11:55:00Z"   # 5 minutes before NOW_EPOCH (300s, well under threshold)

assert_true "queued 61+ min on attempt 1: should_redispatch_stuck_secondary_gate fires" \
  should_redispatch_stuck_secondary_gate "queued" "1" "$STUCK_CREATED_AT" "$NOW_EPOCH"

assert_false "in_progress (a run actually executing is not stuck): should_redispatch_stuck_secondary_gate must NOT fire" \
  should_redispatch_stuck_secondary_gate "in_progress" "1" "$STUCK_CREATED_AT" "$NOW_EPOCH"

assert_false "queued but already retried once (attempt 2): should_redispatch_stuck_secondary_gate must NOT fire again" \
  should_redispatch_stuck_secondary_gate "queued" "2" "$STUCK_CREATED_AT" "$NOW_EPOCH"

assert_false "queued only 5 minutes (normal queue latency, golden-scenarios usually finishes in 2-6 min): should_redispatch_stuck_secondary_gate must NOT fire" \
  should_redispatch_stuck_secondary_gate "queued" "1" "$FRESH_CREATED_AT" "$NOW_EPOCH"

assert_false "success conclusion: should_redispatch_stuck_secondary_gate must NOT fire (nothing to repair)" \
  should_redispatch_stuck_secondary_gate "success" "1" "$STUCK_CREATED_AT" "$NOW_EPOCH"
assert_false "failure conclusion: should_redispatch_stuck_secondary_gate must NOT fire (that is should_retry_failed_ci's job, not this predicate's — different workflow, different retry)" \
  should_redispatch_stuck_secondary_gate "failure" "1" "$STUCK_CREATED_AT" "$NOW_EPOCH"
assert_false "'none' conclusion (no matching run at all): should_redispatch_stuck_secondary_gate must NOT fire" \
  should_redispatch_stuck_secondary_gate "none" "1" "$STUCK_CREATED_AT" "$NOW_EPOCH"
assert_false "'error' conclusion (gh api call itself failed): should_redispatch_stuck_secondary_gate must NOT fire" \
  should_redispatch_stuck_secondary_gate "error" "1" "$STUCK_CREATED_AT" "$NOW_EPOCH"

# ---- RUNBOOK §38 marker fields: routine + run_date extraction (2026-07-29) -----------------
# Regression guard for the fleet-wide marker hole: requiring a full YYYY-MM-DD *in the subject*
# meant only D1/D2/W5 ever produced ops.routine_commit_markers rows, which silently limited
# ops.sp_backfill_run_log_from_markers to those same three routines.

# routine extraction — the conventions actually used by the fleet
assert_eq "routine: ISO-dated daily convention" \
  "$(marker_routine_from_subject 'D1 Market Development Scan 2026-07-28')" "D1"
assert_eq "routine: year-only annual convention (was silently unmarked before the fix)" \
  "$(marker_routine_from_subject 'A1 2026: annual foundation re-derivation')" "A1"
assert_eq "routine: colon-suffixed id is recognised" \
  "$(marker_routine_from_subject 'SL5: register newcomer')" "SL5"
assert_eq "routine: multi-char underscore id" \
  "$(marker_routine_from_subject 'AR_orc adjudicate queue')" "AR_orc"
assert_eq "routine: two-char suffixed id is not confused with its prefix" \
  "$(marker_routine_from_subject 'D2a Broker Reconcile 2026-07-28')" "D2a"

# non-routine subjects must yield NOTHING, so no marker row is written for human/merge commits
assert_eq "routine: a human branch subject yields no routine" \
  "$(marker_routine_from_subject 'Landing hardening: checkpoint pushes, halt-path save')" ""
assert_eq "routine: an auto-merge commit subject yields no routine" \
  "$(marker_routine_from_subject 'Merge origin/main into landing-hardening')" ""
assert_eq "routine: an unknown token that merely looks like an id yields no routine" \
  "$(marker_routine_from_subject 'D9 not a real routine 2026-07-28')" ""
assert_eq "routine: empty subject yields no routine" \
  "$(marker_routine_from_subject '')" ""

# run_date — a subject-embedded ISO date stays authoritative (no regression for D1/D2/W5)
assert_eq "run_date: subject ISO date wins over the fallback" \
  "$(marker_run_date_from_subject 'D1 Market Development Scan 2026-07-28' '2026-07-29')" "2026-07-28"
assert_eq "run_date: first ISO date wins when the subject carries several" \
  "$(marker_run_date_from_subject 'D3 sweep 2026-07-28 covering 2026-07-27' '2026-07-29')" "2026-07-28"
# ...and the commit's own author date is used when the subject has no full date
assert_eq "run_date: year-only subject falls back to the commit author date" \
  "$(marker_run_date_from_subject 'A1 2026: annual foundation re-derivation' '2026-07-28')" "2026-07-28"
assert_eq "run_date: no date anywhere yields empty (caller then skips the row)" \
  "$(marker_run_date_from_subject 'A1 2026: annual foundation re-derivation' '')" ""
# word-boundary anchors: a date glued inside another token (no boundary before it) must NOT match
assert_eq "run_date: a date glued inside another token is skipped, real date still found" \
  "$(marker_run_date_from_subject 'D2 rebalance v42026-07-15 sync 2026-07-28' '2026-01-01')" "2026-07-28"

# ---- RUNBOOK §38 marker WRITE guards: phantom-completion classes (2026-08-17, W5) ----------------
# Regression guard for two commit classes that parsed to a valid routine+date but were NOT routine
# output, so ops.sp_backfill_run_log_from_markers minted a 'completed' ops.run_log row for a run that
# never happened. Measured harm (W5, 2026-08-17): W5 read completed on both 2026-08-16 and 2026-08-17,
# blinding its cadence dead-man's switch AND collapsing state.routine_catchup_window from 8.3d to 0.07d.

# (A) authorship — only routine sessions author routine output commits
assert_true "author: routine container identity is accepted" \
  marker_author_is_routine 'noreply@anthropic.com'
assert_false "author: operator GitHub web-UI commit is NOT a routine output commit" \
  marker_author_is_routine '3615459+JackOfSpade@users.noreply.github.com'
assert_false "author: operator local commit is NOT a routine output commit" \
  marker_author_is_routine 'jack@mac.home'
assert_false "author: auto-merge bot is NOT a routine output commit" \
  marker_author_is_routine 'actions@github.com'
assert_false "author: empty author yields no marker" \
  marker_author_is_routine ''
# the near-miss that motivates suffix-matching rather than an exact-address pin
assert_true "author: a future harness identity on the same domain still counts as routine" \
  marker_author_is_routine 'claude-routine@anthropic.com'

# (B) halt/abort subjects — a routine documenting its OWN failure must not be marked completed
assert_true "no-completion: the live 2026-08-16 W5 halt commit is rejected" \
  marker_subject_declares_no_completion 'W5 2026-08-16: HALT at pre-flight — BigQuery connector de-authorized'
assert_true "no-completion: lowercase halted is rejected" \
  marker_subject_declares_no_completion 'D2 2026-08-16: halted on a stale freshness gate'
assert_true "no-completion: abort vocabulary is rejected" \
  marker_subject_declares_no_completion 'AR_orc 2026-08-16: aborted, dependency gate unsatisfied'
# ordinary output subjects must survive — the guard is narrow by design
assert_false "no-completion: an ordinary daily output subject is unaffected" \
  marker_subject_declares_no_completion 'D1 Market Development Scan 2026-07-28'
assert_false "no-completion: a real W5 output subject is unaffected" \
  marker_subject_declares_no_completion 'W5 2026-08-03: factbase consolidation, 16 sub-pattern instances'
assert_false "no-completion: substring 'halt' inside a longer word does not trip the guard" \
  marker_subject_declares_no_completion 'D1 Market Development Scan 2026-08-17 — asphalt makers rally'
assert_false "no-completion: empty subject is not a halt declaration" \
  marker_subject_declares_no_completion ''

echo
if [ "$fail" -ne 0 ]; then
  echo "auto_merge_decision tests: FAILED"
  exit 1
fi
echo "auto_merge_decision tests: all $pass_count assertions passed"

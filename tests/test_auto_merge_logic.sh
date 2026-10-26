#!/usr/bin/env bash
# Functional tests for scripts/auto_merge_decision.sh — the RUNBOOK §38 commit-marker helpers that
# scripts/write_routine_commit_markers.sh sources after a selected PR merges. Sources the SAME
# functions production sources (not a reimplementation).
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

# MEASURED OVER-SUPPRESSION, pinned as assert_TRUE because over-suppressing is the DESIGNED-SAFE
# direction (2026-09-04 quality pass). Walking this repo's whole history through
# marker_author_is_routine + marker_routine_from_subject yields 447 candidate commits and 8
# suppressions; the four below are COMPLETED runs whose subjects merely mention a halt, not halt
# declarations. They are asserted here — rather than "fixed" — because scripts/auto_merge_decision.sh's
# BIAS paragraph makes the asymmetry explicit: a missing marker degrades to the loud path (and the
# suppression is announced via ::notice:: in auto-merge-claude.yml), whereas a FALSE marker silently
# blinds the cadence dead-man's switch — the failure that cost two W5 cycles. A narrower alternation
# that would recover two of these was evaluated and rejected in the same pass (it stops matching
# genuine declarations like "aborting on connector failure"); see that function's CORRECTION note.
# These four exist so the deliberate behavior cannot drift silently in either direction.
assert_true "no-completion (accepted over-suppression): 'halting' describing a FIX, not a halt" \
  marker_subject_declares_no_completion "AR_orc: stop a routine's own decision write from halting its own gate"
assert_true "no-completion (accepted over-suppression): \\b matches inside the hyphen compound 'trading-halt'" \
  marker_subject_declares_no_completion 'W4 2026-W30: 6 PENDING_ANALYSIS entries, no exits; trading-halt root cause re-diagnosed'
assert_true "no-completion (accepted over-suppression): a completed run REPORTING a trading halt" \
  marker_subject_declares_no_completion 'D2a Broker Reconcile & Snapshot 2026-07-07 — reconciled, engine fresh; trading gate RED (halt)'
assert_true "no-completion (accepted over-suppression): 'halted' describing a POSITION, not the run" \
  marker_subject_declares_no_completion 'W4 2026-W32: Weekly Action Conversion — MTZ exit confirmed but halted; 6 theses queued'

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

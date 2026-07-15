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

echo
if [ "$fail" -ne 0 ]; then
  echo "auto_merge_decision tests: FAILED"
  exit 1
fi
echo "auto_merge_decision tests: all $pass_count assertions passed"

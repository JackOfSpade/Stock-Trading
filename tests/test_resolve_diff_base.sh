#!/usr/bin/env bash
# Functional tests for scripts/resolve_diff_base.sh — the diff-base precedence chain
# ci.yml's `dbt-parity` and `sql-validate` path gates source to decide what range of commits
# to diff against when scoping their checks (2026-07-26, codebase audit — de-duplication).
#
# This sources the SAME function the production workflow sources (not a reimplementation) and
# exercises it against a scratch git repo with fixture branches/commits + a real local "origin"
# remote, mirroring tests/test_auto_merge_logic.sh's testing approach for the sibling extracted
# script (scripts/auto_merge_decision.sh).
#
# Scenarios covered (per the unit — this logic was previously only exercisable by pushing to CI,
# and had ALREADY needed two follow-on correctness fixes, rev 2026-07-20 and 2026-07-20b, each
# applied twice by hand across the two now-deleted duplicate copies):
#   * pull_request event -> PR_BASE, unconditionally (never touches PUSH_BEFORE/merge-base at all)
#   * push to a non-main branch -> merge-base(HEAD, origin/main), even when PUSH_BEFORE also
#     resolves (rev 2026-07-20b, Finding 1 — a second push on an open branch must still diff the
#     WHOLE branch against main, not just the latest push's delta)
#   * push to main -> PUSH_BEFORE, NOT merge-base (which would degenerate to HEAD on main and
#     vacuously skip)
#   * the zero-SHA-on-ref-creation case that motivated rev 2026-07-20: PUSH_BEFORE is the all-
#     zeroes SHA (unresolvable) on a brand-new non-main branch -> falls back to merge-base
#   * push to main whose PUSH_BEFORE is itself unresolvable (e.g. a force-push) -> falls back to
#     merge-base(HEAD, origin/main) instead of leaving base empty
#   * nothing resolvable at all (no origin/main, no valid PUSH_BEFORE, non-pull_request) -> prints
#     NOTHING (empty stdout) — callers each apply their OWN fail-open policy on that, which this
#     script deliberately does not decide (see its header)
#
# Run:  bash tests/test_resolve_diff_base.sh
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=../scripts/resolve_diff_base.sh
source "$ROOT/scripts/resolve_diff_base.sh"

fail=0
pass_count=0

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

# ---- scratch repo + a REAL local "origin" remote --------------------------------------------
# resolve_diff_base does its own `git fetch --quiet origin +refs/heads/main:refs/remotes/origin/main`,
# so an actual remote named "origin" is needed (not just a hand-placed refs/remotes/origin/main) —
# otherwise the fetch's failure mode itself would never be exercised.

SCRATCH="$(mktemp -d)"
cleanup() { cd "$ROOT" 2>/dev/null || true; rm -rf "$SCRATCH"; }
trap cleanup EXIT

# "origin" is a bare-ish local repo the scratch clone pushes to, so `git fetch origin main`
# behaves exactly like it would against GitHub — a real network-free local remote, not a stub.
ORIGIN="$SCRATCH/origin.git"
WORK="$SCRATCH/work"
git init -q -b main --bare "$ORIGIN"

git init -q -b main "$WORK"
cd "$WORK"
git config user.name "test"
git config user.email "test@example.com"
git remote add origin "$ORIGIN"

echo "seed" > f.txt
git add f.txt
git commit -q -m "seed"
git push -q origin main
main_seed_sha="$(git rev-parse HEAD)"

# ---- 1. pull_request event: PR_BASE wins unconditionally, no git plumbing at all ------------
# Deliberately pass a bogus PUSH_BEFORE/HEAD_SHA/REF_NAME to prove the pull_request branch never
# even looks at them.
base="$(resolve_diff_base "pull_request" "$main_seed_sha" "not-a-sha" "not-a-sha" "not-a-branch")"
assert_eq "pull_request event resolves to PR_BASE" "$base" "$main_seed_sha"

# ---- 2. push to a non-main branch: merge-base(HEAD, origin/main), even though PUSH_BEFORE also
# resolves (rev 2026-07-20b, Finding 1 — a second push on an open branch must re-diff the WHOLE
# branch against main, not just since the branch's own prior tip) -----------------------------

git checkout -q -b feature
echo "feature commit 1" >> f.txt
git commit -q -am "feature commit 1"
feature_c1="$(git rev-parse HEAD)"
echo "feature commit 2" >> f.txt
git commit -q -am "feature commit 2"
feature_c2="$(git rev-parse HEAD)"

# PUSH_BEFORE is feature_c1 (a real, resolvable commit — the branch's own prior tip) but the
# non-main push path must still prefer merge-base(HEAD, origin/main), i.e. main_seed_sha, so the
# whole branch (both commits) is in scope, not just the delta since commit1.
base="$(resolve_diff_base "push" "" "$feature_c1" "$feature_c2" "feature")"
assert_eq "push to non-main branch: merge-base(HEAD, origin/main) wins over a resolvable PUSH_BEFORE" \
  "$base" "$main_seed_sha"

# ---- 3. the zero-SHA-on-ref-creation case (rev 2026-07-20): PUSH_BEFORE is the all-zeroes SHA on
# a BRAND-NEW non-main branch -> falls back to merge-base(HEAD, origin/main) ------------------

zero_sha="0000000000000000000000000000000000000000"
base="$(resolve_diff_base "push" "" "$zero_sha" "$feature_c1" "feature")"
assert_eq "push, ref-creation zero-SHA PUSH_BEFORE on a non-main branch: falls back to merge-base" \
  "$base" "$main_seed_sha"

# ---- 4. push to main: PUSH_BEFORE wins, NOT merge-base (which would degenerate to HEAD on main
# once origin/main is fetched — an empty, vacuously-skipping diff) ----------------------------

git checkout -q main
git merge -q --no-ff feature -m "merge feature"
git push -q origin main
main_after_merge="$(git rev-parse HEAD)"

base="$(resolve_diff_base "push" "" "$main_seed_sha" "$main_after_merge" "main")"
assert_eq "push to main: PUSH_BEFORE wins over merge-base (which would degenerate to HEAD on main)" \
  "$base" "$main_seed_sha"

# ---- 5. push to main whose PUSH_BEFORE is itself unresolvable (e.g. a force-push) -> falls back
# to merge-base(HEAD, origin/main) instead of leaving base empty ------------------------------

base="$(resolve_diff_base "push" "" "$zero_sha" "$main_after_merge" "main")"
assert_eq "push to main, unresolvable PUSH_BEFORE (force-push): falls back to merge-base" \
  "$base" "$main_after_merge"

# ---- 6. fail-open case: nothing resolvable at all (no PUSH_BEFORE, no origin remote at all) ->
# prints NOTHING; the caller's OWN fail-open policy decides what that means, not this script ---

NO_ORIGIN="$SCRATCH/no_origin"
git init -q -b main "$NO_ORIGIN"
cd "$NO_ORIGIN"
git config user.name "test"
git config user.email "test@example.com"
echo "seed" > f.txt
git add f.txt
git commit -q -m "seed"
head_sha="$(git rev-parse HEAD)"
# No `origin` remote configured at all: the internal `git fetch` fails silently (|| true) and
# merge-base has nothing to compare against, so both branches of the precedence chain that try
# merge-base come up empty. PUSH_BEFORE is also unresolvable (the zero SHA).
base="$(resolve_diff_base "push" "" "$zero_sha" "$head_sha" "feature-with-no-origin")"
assert_eq "nothing resolvable (no origin remote, no valid PUSH_BEFORE): prints empty, not a guess" \
  "$base" ""

base="$(resolve_diff_base "push" "" "$zero_sha" "$head_sha" "main")"
assert_eq "push to main, nothing resolvable (no origin remote either): prints empty, not a guess" \
  "$base" ""

cd "$ROOT"

echo
if [ "$fail" -ne 0 ]; then
  echo "resolve_diff_base tests: FAILED"
  exit 1
fi
echo "resolve_diff_base tests: all $pass_count assertions passed"

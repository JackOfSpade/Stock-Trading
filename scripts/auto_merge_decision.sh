#!/usr/bin/env bash
# Sourceable decision helpers for .github/workflows/auto-merge-claude.yml (extracted 2026-07-04,
# code-quality audit).
#
# WHY: the merge/CI-gate/delete decision logic that decides whether routine output reaches `main` had
# ZERO functional test coverage — only actionlint/shellcheck (syntax-level) touched it (see ci.yml's
# shell-lint job comment). This factors the two decision PREDICATES that are cleanly extractable —
# "is this SHA's CI green?" (fail-closed) and "is this ref already merged into that one?" — into
# functions the workflow `source`s directly, so production and tests run the IDENTICAL implementation
# (no shadow copy to drift). tests/test_auto_merge_logic.sh exercises these against a scratch git repo
# plus canned `gh api` JSON, and is wired into ci.yml's `test` job.
#
# NOT extracted: the git plumbing around these predicates (fetch/checkout/merge/push, the
# conflict-PR path, the branch listing/filtering) stays inline in the workflow. It is a thin, mostly
# linear sequence of git/gh calls that reads clearly in place; re-plumbing GITHUB_OUTPUT/exit-code
# control flow through another layer of indirection would add risk to the most consequential
# automation in the repo for little marginal safety over what actionlint+shellcheck already catch.

# ci_conclusion_from_json <json> — given the JSON body of
# `gh api repos/<repo>/actions/workflows/ci.yml/runs?head_sha=<sha>&per_page=1` (or "" / unparseable
# JSON, e.g. from a failed API call), print the conclusion of the most recent run:
#   - "success" / "failure" / "in_progress" / ... — a real run's conclusion.
#   - "none"    — valid JSON but no matching run yet (new commit; CI hasn't started/finished).
#   - "error"   — the API call failed, or returned empty/unparseable JSON.
# Requires `jq`. NOTE: jq treats a completely empty stdin as "no output, exit 0" (not an error), so an
# empty/missing `$1` is checked explicitly rather than relying on jq's own exit code for that case.
ci_conclusion_from_json() {
  local out
  if [ -n "$1" ] \
     && out="$(printf '%s' "$1" | jq -r '.workflow_runs[0].conclusion // "none"' 2>/dev/null)" \
     && [ -n "$out" ]; then
    printf '%s\n' "$out"
  else
    echo "error"
  fi
}

# is_ci_green <conclusion> — fail-closed: ONLY an exact "success" counts as green. Any other value
# (in-progress, failure, "none", "error") is NOT green, so a missing/ambiguous CI result blocks the
# merge instead of silently defaulting to allow.
is_ci_green() {
  [ "$1" = "success" ]
}

# is_ancestor_of <maybe-ancestor-ref> <descendant-ref> — true (exit 0) if the first ref's commit is
# reachable from the second, i.e. the first is already merged into the second. Used both for "already
# contained in main, just clean up" and for the re-confirm-before-delete ancestry check (a branch whose
# tip advanced after the merge decision was made must NOT look like an ancestor, so it must NOT be
# deleted).
is_ancestor_of() {
  git merge-base --is-ancestor "$1" "$2"
}

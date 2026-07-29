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
  # BUG FIX (2026-07-14 audit finding): jq's `null[0]` also evaluates to null, so a JSON object
  # with NO `workflow_runs` array at all (e.g. `{"message":"Not Found"}`, what a failed `gh api`
  # call's stdout looks like on an HTTP error) used to parse to "none" — identical to a
  # legitimate zero-runs response — silently satisfying is_secondary_gate_satisfied instead of
  # blocking the merge as an API error must. The `(.workflow_runs | type) != "array"` guard now
  # requires workflow_runs to actually be an array before treating it as a real (possibly empty)
  # result.
  if [ -n "$1" ] \
     && out="$(printf '%s' "$1" | jq -r 'if (.workflow_runs | type) != "array" then "error" else (.workflow_runs[0] as $r | if $r == null then "none" else ($r.conclusion // $r.status // "unknown") end) end' 2>/dev/null)" \
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

# is_secondary_gate_satisfied <conclusion> — BUG FIX (rev 2026-07-11, adversarial self-audit): like
# is_ci_green, but for an OPTIONAL, PATH-GATED secondary workflow (golden-scenarios.yml's schema-validate
# HARD GATE job, which only runs when Strategy.md/Operating_Protocols.md/Claude_Task_Plan.md/the golden
# fixtures themselves change). Before this fix, auto-merge-claude.yml never checked this workflow's
# status at all, so a failing schema-validate run (meant to catch a rotted golden-scenario fixture) had
# ZERO effect on whether the offending commit merged — the HARD GATE was decorative. Unlike is_ci_green,
# "none" (no matching run for this SHA) counts as SATISFIED here, because most commits legitimately never
# trigger this path-gated workflow at all — treating "none" as a block would wedge auto-merge on every
# unrelated commit. Still fail-closed for everything else: an explicit "failure", "in_progress", or
# "error" (the API call itself failed) blocks the merge exactly like is_ci_green does.
is_secondary_gate_satisfied() {
  [ "$1" = "success" ] || [ "$1" = "none" ]
}

# is_ancestor_of <maybe-ancestor-ref> <descendant-ref> — true (exit 0) if the first ref's commit is
# reachable from the second, i.e. the first is already merged into the second. Used both for "already
# contained in main, just clean up" and for the re-confirm-before-delete ancestry check (a branch whose
# tip advanced after the merge decision was made must NOT look like an ancestor, so it must NOT be
# deleted).
is_ancestor_of() {
  git merge-base --is-ancestor "$1" "$2"
}

# ci_run_id_from_json <json> — the numeric id of the most recent run (for gh api/gh run rerun
# targeting), or "" if none/unparseable. Companion to ci_conclusion_from_json (2026-07-15,
# self-improvement audit — CONFIRMED GAP red-ci-merge-conflict-no-remediation).
ci_run_id_from_json() {
  local out
  if [ -n "$1" ] \
     && out="$(printf '%s' "$1" | jq -r 'if (.workflow_runs | type) != "array" then "" else (.workflow_runs[0] as $r | if $r == null then "" else ($r.id // "") end) end' 2>/dev/null)"; then
    printf '%s\n' "$out"
  else
    printf '\n'
  fi
}

# ci_run_attempt_from_json <json> — the run_attempt of the most recent run (GitHub's own retry
# counter — 1 for a never-retried run), or "" if none/unparseable/missing.
ci_run_attempt_from_json() {
  local out
  if [ -n "$1" ] \
     && out="$(printf '%s' "$1" | jq -r 'if (.workflow_runs | type) != "array" then "" else (.workflow_runs[0] as $r | if $r == null then "" else ($r.run_attempt // "") end) end' 2>/dev/null)"; then
    printf '%s\n' "$out"
  else
    printf '\n'
  fi
}

# should_retry_failed_ci <conclusion> <run_attempt> — true (exit 0) only for a GENUINE terminal
# failure ("failure", never "in_progress"/"none"/"error"/"cancelled"/etc.) on its FIRST attempt
# (run_attempt == "1"). Bounds this to exactly ONE automatic retry ever per run: GitHub increments
# run_attempt on every rerun, so a re-run that fails again reads run_attempt=2 and is never retried
# again — a content-free, self-limiting retry for transient/flaky CI (2026-07-15, self-improvement
# audit). A real code bug just fails again on attempt 2 and falls through to the existing
# stranded-branch-check.yml alert path unchanged; this never touches branch content.
should_retry_failed_ci() {
  [ "$1" = "failure" ] && [ "$2" = "1" ]
}

# ---- RUNBOOK §38 commit-marker field extraction (extracted + FIXED 2026-07-29) ----------------
# WHY THESE EXIST: the marker fields used to be parsed by two inline greps in
# auto-merge-claude.yml, untested, and REQUIRED BOTH a routine token AND a full YYYY-MM-DD in the
# commit subject before writing an ops.routine_commit_markers row. Verified 2026-07-29: that gate
# meant the table had only EVER received rows for D1, D2 and W5 — the three routines whose commit
# convention happens to embed a full ISO date ("D1 Market Development Scan 2026-07-28"). Routines
# writing e.g. "A1 2026: annual foundation re-derivation" carry only a YEAR, so A1/A2/A3 landed real
# commits on main and got no marker at all. Because ops.sp_backfill_run_log_from_markers (RUNBOOK
# §38 layer A) reads this table, that self-heal had likewise only ever been able to repair those same
# three routines — a silent, fleet-wide hole in the "commit landed but run_log missing" recovery path.
# Extracted here as PURE string functions so tests/test_auto_merge_logic.sh covers the production
# implementation directly (same rationale as the predicates above).

# marker_routine_from_subject <subject> — print the leading routine id if the subject starts with a
# known routine token, else print nothing. The token may be followed by whitespace OR punctuation
# (":", ".", ",", "-"), so "SL5: register newcomer" is recognised as well as "D1 Market Scan ...".
# A non-routine subject ("Landing hardening: ...", "Merge origin/main into ...") prints nothing, which
# is what suppresses marker rows for human/non-routine branches.
# The allowlist assignment below keeps the exact literal shape that
# scripts/check_cadence_consistency.py's check H greps for — that guard asserts every id in
# ops/cadence.yaml is accepted here, so a newly-added routine cannot be silently skipped by the
# §38 marker-write. Do NOT rewrite it into a case statement or a different quoting style without
# updating AUTO_MERGE_ROUTINE_RE / AUTO_MERGE_DECISION_SH and AUTO_MERGE_YML in that script. NOTE: do not restate
# that literal's shape anywhere in a comment — the checker's own pattern would match the comment
# first and silently validate a placeholder instead of the real allowlist.
marker_routine_from_subject() {
  local token routine_re
  routine_re='^(D1|D2a|D2|D3|OPS0|OPS1|OPS2|W[1-5]|M1a|M1b|M[2-5]|Q[1-4]|A[1-3]|SL[1-5]|AR_att|AR_orc)$'
  token="$(printf '%s' "${1:-}" | grep -oE '^[A-Za-z][A-Za-z0-9_]*' || true)"
  if [ -n "$token" ] && [[ "$token" =~ $routine_re ]]; then
    printf '%s\n' "$token"
  else
    printf '\n'
  fi
}

# marker_run_date_from_subject <subject> <fallback_iso_date> — print the run_date for the marker row:
# a full YYYY-MM-DD embedded in the subject when present (authoritative — preserves the existing
# D1/D2/W5 behaviour exactly), otherwise the supplied fallback. The caller passes the COMMIT's own
# author date (`git log -1 --format=%as`), which is the date the routine actually made the commit in
# its own timezone — not the merge date, which can roll past midnight UTC and misattribute an evening
# routine's run to the following day. Prints nothing if neither source yields a date, and the caller
# then skips the row rather than inventing one.
marker_run_date_from_subject() {
  local in_subject
  in_subject="$(printf '%s' "${1:-}" | grep -oE '\b[0-9]{4}-[0-9]{2}-[0-9]{2}\b' | head -1 || true)"
  if [ -n "$in_subject" ]; then
    printf '%s\n' "$in_subject"
  else
    printf '%s\n' "${2:-}"
  fi
}

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

# ci_run_created_at_from_json <json> — the created_at ISO-8601 timestamp of the most recent run
# (GitHub's dispatch-time field, e.g. "2026-08-19T04:15:35Z"), or "" if none/unparseable/missing.
# Companion to ci_run_id_from_json / ci_run_attempt_from_json (same jq-guard shape); feeds
# should_redispatch_stuck_secondary_gate's age computation below (2026-08-19, stuck-secondary-gate
# self-heal).
ci_run_created_at_from_json() {
  local out
  if [ -n "$1" ] \
     && out="$(printf '%s' "$1" | jq -r 'if (.workflow_runs | type) != "array" then "" else (.workflow_runs[0] as $r | if $r == null then "" else ($r.created_at // "") end) end' 2>/dev/null)"; then
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

# ---- Stuck secondary-gate one-shot re-dispatch (2026-08-19) -----------------------------------
# WHY: is_secondary_gate_satisfied correctly blocks the merge on a matched-but-non-success
# golden-scenarios run (queued/in_progress/failure/error all fail it). But ci_conclusion_from_json
# falls back to `.status` when `.conclusion` is null, so a run GitHub never dispatches to a runner
# (status stays "queued" forever — a rare Actions-platform glitch, not a code failure) reads as
# "queued" and blocks the branch PERMANENTLY: nothing in the repo ever moves a run out of "queued",
# so is_secondary_gate_satisfied never flips true and the branch is stranded with no remediation.
# should_retry_failed_ci (above) cannot cover this: nothing failed (there is no terminal "failure"),
# and "queued" is non-terminal.
#
# OBSERVED TWICE, both unresolved as of this writing: run 32215104789 (branch
# claude/sl3-2026-08-18, created_at 2026-08-19T04:15:35Z) — still "queued" ~17h later, and the
# reason ops.ci_findings currently carries an open stranded_branch row; and a run from
# fix/alert-triage-2026-08-04 (created_at 2026-08-06T16:39:13Z) — still "queued" 13 days later
# (branch since deleted). Every OTHER golden-scenarios run in both windows completed in 2-6
# minutes, so this is a rare platform glitch that never self-resolves, not ordinary queue latency.
#
# THE REMEDIATION IS workflow_dispatch, NOT `gh run rerun` — MEASURED LIVE against the stuck run
# above, 2026-08-19, before landing this (an earlier version of this self-heal called `gh run
# rerun` and would have been permanently inert):
#   * `gh run rerun 32215104789` -> "run 32215104789 cannot be rerun; This workflow is already
#     running" (exit 1). GitHub refuses to rerun a run that is not in a terminal state, and a
#     never-dispatched "queued" run never reaches one — this call can NEVER succeed for this
#     failure mode, so a self-heal built on it would always hit its own fallback and do nothing.
#   * `gh run cancel 32215104789` -> "HTTP 500: Failed to cancel workflow run" (exit 1). These
#     zombie runs cannot even be cancelled, so cancel-then-rerun is not a usable fallback either.
#   * `gh workflow run golden-scenarios.yml --ref claude/sl3-2026-08-18` -> SUCCEEDED, creating a
#     brand-new run (32272701107, event=workflow_dispatch) against the SAME head_sha as the stuck
#     run (golden-scenarios.yml already declares `workflow_dispatch:` in its `on:` block, so it
#     needs no workflow change to accept this).
# WHY A FRESH DISPATCH IS SUFFICIENT even though the zombie run itself is never touched: the
# workflow's own CI-gate query is `.../golden-scenarios.yml/runs?head_sha=$sha&per_page=1` —
# per_page=1 returns the MOST RECENT run for that SHA. Once the dispatched run completes,
# ci_conclusion_from_json reads ITS conclusion, not the zombie's; the zombie can stay "queued"
# forever with zero effect on the gate. golden-scenarios.yml's `concurrency: group:
# golden-scenarios-${{ github.ref }}` (`cancel-in-progress: true`) is scoped per-branch, so this
# dispatch cannot collide with a run on any other branch.
#
# should_redispatch_stuck_secondary_gate mirrors should_retry_failed_ci's shape (a pure,
# self-limiting predicate the workflow gates a remediation call on) but with a different trigger
# AND a different remediation action, true (exit 0) ONLY when ALL hold:
#   * conclusion is EXACTLY "queued" — deliberately NOT "in_progress": a run actually executing on
#     a runner is not stuck, and dispatching a duplicate would race a real in-flight run.
#   * run_attempt is "1" — the same GitHub-incremented idempotency counter should_retry_failed_ci
#     relies on. Note this counter belongs to the STUCK run being observed, not to the dispatched
#     one (workflow_dispatch always starts its own new run at attempt 1) — it still bounds this to
#     firing at most ONCE per stuck run, because a second sweep sees the newly-dispatched run (not
#     this same stuck run) as golden-scenarios.yml's now-most-recent run for the SHA.
#   * the run's age (now_epoch - created_at_iso) exceeds STUCK_SECONDARY_GATE_THRESHOLD_SECONDS (60
#     minutes) — comfortably above the measured 2-6 minute normal completion time, so this can never
#     race a run that is merely still queueing normally or the workflow's own concurrency group.
# This is a REPAIR ATTEMPT, not a gate weakening: is_secondary_gate_satisfied still blocks the
# merge itself, unchanged, on this and every subsequent run until the dispatched run actually
# completes green.
#
# Pure string/arith function — no gh/network/clock calls inside. now_epoch is supplied by the
# caller (production: `date -u +%s` in the workflow step, the same idiom stranded-branch-check.yml
# already uses for its own age computation; tests: a literal/computed epoch), so
# tests/test_auto_merge_logic.sh exercises this deterministically. created_at_iso is converted via
# iso8601_to_epoch_utc below, which invokes the `date` binary only to PARSE the given timestamp
# string — it never reads the actual wall clock, so it adds no non-determinism.
STUCK_SECONDARY_GATE_THRESHOLD_SECONDS=3600

# iso8601_to_epoch_utc <iso8601> — GitHub's workflow-run `created_at` is always UTC, fixed-format,
# no fractional seconds (e.g. "2026-08-19T04:15:35Z"). Tries GNU `date -d` first (production runs
# on ubuntu-latest); falls back to BSD `date -j -f` (this repo's local test runs on macOS) — both
# parse the identical string to the identical epoch second (verified 2026-08-19). Prints nothing
# and returns non-zero on unparseable/empty input.
iso8601_to_epoch_utc() {
  [ -n "${1:-}" ] || return 1
  date -u -d "$1" +%s 2>/dev/null || date -j -u -f '%Y-%m-%dT%H:%M:%SZ' "$1" +%s 2>/dev/null
}

should_redispatch_stuck_secondary_gate() {
  local conclusion="${1:-}" run_attempt="${2:-}" created_at_iso="${3:-}" now_epoch="${4:-}"
  local created_epoch age
  [ "$conclusion" = "queued" ] || return 1
  [ "$run_attempt" = "1" ] || return 1
  case "$now_epoch" in ''|*[!0-9]*) return 1 ;; esac
  created_epoch="$(iso8601_to_epoch_utc "$created_at_iso")" || return 1
  case "$created_epoch" in ''|*[!0-9]*) return 1 ;; esac
  age=$(( now_epoch - created_epoch ))
  [ "$age" -gt "$STUCK_SECONDARY_GATE_THRESHOLD_SECONDS" ]
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
# D1/D2/W5 behaviour exactly), otherwise the supplied fallback. The caller passes the commit's author
# date rendered in America/Denver (`TZ=America/Denver git log -1 --date=short-local --format=%ad`),
# i.e. the OPERATING-plane calendar date on which the routine actually made the commit — not the merge
# date, and not the commit's own recorded offset. CORRECTED 2026-08-04: the caller previously passed
# `--format=%as`, which renders in the commit's OWN offset; routine containers commit in UTC, so an
# evening-slot routine's commit came back dated TOMORROW — reintroducing precisely the midnight-UTC
# misattribution this fallback exists to prevent. Prints nothing if neither source yields a date, and
# the caller then skips the row rather than inventing one.
marker_run_date_from_subject() {
  local in_subject
  in_subject="$(printf '%s' "${1:-}" | grep -oE '\b[0-9]{4}-[0-9]{2}-[0-9]{2}\b' | head -1 || true)"
  if [ -n "$in_subject" ]; then
    printf '%s\n' "$in_subject"
  else
    printf '%s\n' "${2:-}"
  fi
}

# ---- Marker WRITE guards (added 2026-08-17, W5) --------------------------------------------------
# WHY: a ops.routine_commit_markers row asserts "this routine's OUTPUT commit landed on main", and
# ops.sp_backfill_run_log_from_markers turns that assertion into a 'completed' ops.run_log row. The two
# functions above decide WHICH routine/date a subject names; neither can tell whether the commit was
# produced BY a routine run at all. Two commit classes therefore minted phantom completions:
#
#   (A) A routine's own HALT commit. When a routine correctly follows the connector-pre-flight halt
#       branch it commits a record of the halt — e.g. "W5 2026-08-16: HALT at pre-flight — BigQuery
#       connector de-authorized", a commit whose own body states "HALTED W5 cleanly. No factbase edits,
#       no writes." That subject parses to routine=W5, run_date=2026-08-16 and was marked as output.
#       The perverse result: the better a routine documents its own failure, the more certainly it is
#       recorded as having succeeded.
#   (B) A NON-routine commit whose subject merely begins with a routine token. The operator's
#       "W5 weekend timing optimization, plus routine-scope CI guard and cadence cleanup" (author
#       3615459+JackOfSpade@users.noreply.github.com, 2026-08-17) is a commit ABOUT W5, not BY W5; with
#       no date in the subject the run_date fallback attributed it to the commit's own day.
#
# MEASURED HARM (2026-08-17, W5): those two rows made W5 read as completed on both 08-16 and 08-17, so
# the cadence dead-man's switch saw ran_completed_this_period=TRUE and could never raise period_missed
# or reach OPS0 auto-refire readiness (OPS0 logged exactly this diagnosis on 2026-08-16), AND
# state.routine_catchup_window collapsed W5's evidence reach from 8.3 days to 0.07 — the catch-up
# protocol that exists to cover missed periods was disarmed by the very rows recording the miss. Two
# W5 cycles were lost with nothing alarming; W4 had to flag it in prose.
#
# THIS IS A RECURRING FAMILY, NOT A ONE-OFF: the workflow's own inline comment records the same
# phantom-completion outcome on 2026-08-04, when an SL2 commit's UTC-rendered fallback date blinded
# state.queue_driven_silence_watch. That fix corrected the DATE limb; these two guards close the
# "was this a routine output commit at all?" limb.
#
# BIAS: both guards fail toward NOT writing a marker. That asymmetry is deliberate — a MISSING marker
# degrades to the pre-existing loud path (sp_assert_deps raises missing_dependency and the gate's
# git-evidence fallback still applies), whereas a FALSE marker silently blinds dead-man's switches.
# A noisy miss is recoverable; a silent false completion is what cost two cycles here.

# marker_author_is_routine <author_email> — true when a commit was authored by a routine session.
# Routine containers commit as `Claude <noreply@anthropic.com>`; VERIFIED against every routine commit
# in the 2026-07/08 window. Operator commits (GitHub web UI `…@users.noreply.github.com`, local
# `jack@mac.home`) and the auto-merge bot are all outside this domain — the same authorship split
# CLAUDE.md's stop-hook note already documents. Suffix-matched rather than pinned to the exact address
# so a harness identity change degrades to "still recognised" rather than "every marker suppressed".
marker_author_is_routine() {
  case "${1:-}" in
    *"@anthropic.com") return 0 ;;
    *) return 1 ;;
  esac
}

# marker_subject_declares_no_completion <subject> — true when a commit subject AFFIRMATIVELY states the
# run did not complete, so no marker should be written no matter how well-formed the id/date are.
# Deliberately narrow: it matches only the halt/abort vocabulary the halt-commit convention actually
# uses, as whole words, so an ordinary output subject cannot trip it. It is a BACKSTOP, never the
# authoritative completion signal — that remains the routine's own ops.sp_routine_end write.
marker_subject_declares_no_completion() {
  printf '%s' "${1:-}" | grep -qiE '\b(halt|halts|halted|halting|abort|aborts|aborted|aborting)\b'
}

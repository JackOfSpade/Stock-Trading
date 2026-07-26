#!/usr/bin/env bash
# Sourceable diff-base resolution for ci.yml's `dbt-parity` and `sql-validate` path gates
# (extracted 2026-07-26, codebase audit — de-duplication). Mirrors the precedent set by
# scripts/auto_merge_decision.sh: production and tests source the SAME implementation (no
# shadow copy to drift), and tests/test_resolve_diff_base.sh exercises it against a scratch
# git repo, wired into ci.yml's `test` job.
#
# WHY THIS WAS EXTRACTED: dbt-parity and sql-validate each carried their OWN verbatim copy of
# this ~15-line precedence chain (sql-validate's own comment admitted it "mirrors dbt-parity's
# guard step above verbatim in structure"). Nothing checked the two copies stayed in sync, and
# the chain had ALREADY needed two follow-on correctness fixes (2026-07-20, 2026-07-20b) that
# each had to be hand-applied twice in the same file — exactly the drift risk a single source of
# truth removes. This is a straight lift with NO behavior change; both call sites' own downstream
# path filter (bigquery/**|dbt/** vs bigquery/*.sql|bigquery/scheduled_queries/*.sql) stays in the
# job, only the base-SHA resolution itself moved.
#
# HISTORY (condensed from the two call sites' now-superseded inline comments — both revisions
# applied identically here, once):
#
#   rev 2026-07-20 (Actions-cost audit): github.event.before is the all-zeroes SHA on every push
#   that CREATES a new branch — the overwhelming majority of pushes in this repo's workflow —
#   which made a naive "$PUSH_BEFORE" unresolvable and fell straight into a fail-open branch that
#   ran the full (expensive) check regardless of whether anything relevant actually changed.
#   Measured: ~1,100-1,200 wasted billable minutes/month, ~76% of the repo's Actions bill. FIX:
#   when PUSH_BEFORE is empty/unresolvable, fall back to merge-base(HEAD, origin/main) — a new
#   branch then diffs correctly against only its own commits since it forked from main.
#
#   rev 2026-07-20b (adversarial review of a7bed46, Finding 1): the 2026-07-20 fix above always
#   preferred PUSH_BEFORE over merge-base for ANY push event, falling to merge-base only when
#   PUSH_BEFORE itself was unresolvable. That's wrong for a SECOND (or later) push to an
#   already-open branch: PUSH_BEFORE resolves fine (it's the branch's own prior tip), so
#   merge-base was never tried, and the diff covered only the latest push's delta — not the whole
#   branch-vs-main range a tip-SHA merge gate actually needs (auto-merge-claude.yml matches on the
#   exact tip SHA's CI run). Concretely: commit1 touches a gated path (pushed), commit2 is
#   unrelated (pushed) -> at tip commit2 the old logic saw PUSH_BEFORE=commit1, diffed
#   commit1..commit2 = nothing relevant, and skipped — even though `git diff main commit2` still
#   contains commit1's change, and THAT untested change is what lands on main. FIX: branch the
#   base choice on which ref this push is TO (REF_NAME), not just on whether PUSH_BEFORE happens
#   to resolve:
#     1. pull_request        -> PR_BASE
#     2. push, ref != main   -> merge-base(HEAD, origin/main), falling back to PUSH_BEFORE
#     3. push, ref == main   -> PUSH_BEFORE, falling back to merge-base(HEAD, origin/main)
#     4. nothing resolvable  -> print nothing (caller decides its own fail-open policy)
#   On a non-default branch, merge-base(HEAD, origin/main) is the right question — it re-diffs the
#   WHOLE branch against main on every push, so a later unrelated push still sees an earlier push's
#   gated-path change. This deliberately WIDENS the diff on multi-push branches; correct-over-cheap
#   for a merge gate, and the dominant single-push-per-branch case is unaffected. On main itself,
#   merge-base(HEAD, origin/main) would degenerate to HEAD (origin/main already includes this push
#   once fetched) — an empty diff, i.e. a NEW vacuous-skip bug — so a push to main keeps
#   PUSH_BEFORE as primary and only falls back to merge-base if PUSH_BEFORE is itself unresolvable
#   (e.g. force-push, first push to main).
#
#   Also (rev 2026-07-20b, Finding 3): the origin/main fetch is explicit and refspec-independent
#   (+refs/heads/main:refs/remotes/origin/main) instead of relying on the caller's fetch-depth: 0
#   wildcard refspec as a side effect — `git fetch origin main` alone only populates FETCH_HEAD
#   under a narrow single-branch refspec, which would silently regress merge-base resolution to
#   always-unresolvable if fetch-depth ever changes. Kept INSIDE this function (not left to the
#   caller) precisely so it cannot be accidentally dropped from one call site the way the rest of
#   this chain was duplicated in the first place.
#
# Requires the caller's checkout to have used fetch-depth: 0 (both dbt-parity and sql-validate
# already set this) so origin/main and the merge-base are resolvable at all.

# resolve_diff_base <EVENT_NAME> <PR_BASE> <PUSH_BEFORE> <HEAD_SHA> <REF_NAME> — prints the
# resolved base SHA to stdout if (and only if) it resolves to a real commit object; prints
# NOTHING (empty stdout) otherwise. This function makes NO fail-open/fail-closed policy decision
# itself — dbt-parity's "nothing resolvable" response (run the full check) and sql-validate's
# (validate every bigquery/*.sql file) are each its own caller's business, not this function's.
# Folding the final "$base" validity check in here (previously duplicated a THIRD time at each
# call site, after the precedence chain itself) means a caller only ever needs `[ -n "$base" ]`.
resolve_diff_base() {
  local event_name="$1" pr_base="$2" push_before="$3" head_sha="$4" ref_name="$5"
  local base=""

  if [ "$event_name" = "pull_request" ]; then
    base="$pr_base"
  elif [ "$ref_name" = "main" ]; then
    base="$push_before"
    if [ -z "$base" ] || ! git cat-file -e "${base}^{commit}" 2>/dev/null; then
      git fetch --quiet origin +refs/heads/main:refs/remotes/origin/main 2>/dev/null || true
      base="$(git merge-base "$head_sha" origin/main 2>/dev/null || true)"
    fi
  else
    git fetch --quiet origin +refs/heads/main:refs/remotes/origin/main 2>/dev/null || true
    base="$(git merge-base "$head_sha" origin/main 2>/dev/null || true)"
    if [ -z "$base" ] || ! git cat-file -e "${base}^{commit}" 2>/dev/null; then
      base="$push_before"
    fi
  fi

  if [ -n "$base" ] && git cat-file -e "${base}^{commit}" 2>/dev/null; then
    printf '%s\n' "$base"
  fi
  # else: print nothing. Do NOT `exit`/`return 1` here — this is sourced into a caller's own
  # `run:` block (some of which use `set -e`), and a non-zero return would abort that block
  # instead of letting the caller read empty stdout and take its own fail-open path.
}

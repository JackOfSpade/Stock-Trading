#!/bin/bash
# SessionStart hook — align the harness-assigned branch to latest origin/main.
#
# Companion to .github/workflows/auto-merge-claude.yml: routines push their
# assigned `claude/<suffix>` branch at session end, and the Action merges it
# into main server-side (and deletes the merged branch). To start each
# routine from the latest committed state, we hard-reset the assigned branch
# to origin/main here.
#
# We deliberately STAY on the harness-assigned branch (do NOT checkout main)
# so the harness's end-of-session push targets the assigned branch — the
# only push target the harness allows.
#
# Best-effort: never block session start on git failures.

set -uo pipefail

# Only run in Claude Code on the Web (remote) sessions. Local CLI dev uses
# normal git workflow.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

# CLAUDE_PROJECT_DIR is set by the harness to the repo root.
cd "${CLAUDE_PROJECT_DIR:-$(pwd)}" || exit 0

# Need a remote to fetch from.
if [ -z "$(git remote 2>/dev/null)" ]; then
  exit 0
fi

# Best-effort fetch.
if ! git fetch origin main >/dev/null 2>&1; then
  echo "[session-start] git fetch origin main failed; staying on current state" >&2
  exit 0
fi

# DEEPEN A SHALLOW CLONE (added 2026-09-08, closing the fleet-wide
# `shallow_clone_git_attribution` warning SL2 raised that day).
#
# The routine container clones this repo SHALLOW — measured twice, independently:
# 2026-08-03 by OPS0 (boundary f5bbade, 65 commits reachable from origin/main; 972
# after --unshallow) and 2026-09-08 by SL2 (boundary e4e611c dated 2026-09-01, 83
# commits). Both boundaries sit ~7 days back, so the harness appears to clone with a
# time-bounded shallow window rather than a fixed depth; either way the truncation is
# the container's default, not something a routine chose.
#
# Why this must be repaired HERE rather than left to each routine. On a shallow clone
# the history commands do not ERROR — they return confidently WRONG answers that are
# shaped exactly like real ones: `git log -S/-G/-L`, `git blame`, `git log --follow`,
# `git log --since` and `git merge-base --is-ancestor` all resolve every pre-boundary
# change onto the boundary commit and print a `--- /dev/null` header. That has already
# produced a false `unlanded_completed_run` alert (OPS0 2026-08-03) and a false commit
# attribution (SL2 2026-09-08, which concluded an M2 commit had landed a fix it had
# not). Repairing it once, mechanically, at session start needs zero cooperation from
# the routine — the same reasoning bigquery/230 used to put run-outcome alerting inside
# ops.sp_log_run instead of in prose every routine has to remember.
#
# Cost, measured 2026-09-08 against this repo at 1390 commits: `git fetch --unshallow`
# takes ~4.7 s and grows .git from ~5.6 MB to ~26 MB. This is the routine container's
# own network, NOT a GitHub Actions runner, so it bills no Actions minutes and the
# CLAUDE.md push-batching economics do not apply to it.
#
# Guarded on `--is-shallow-repository` because `git fetch --unshallow` on a COMPLETE
# repository is a hard error (`fatal: --unshallow on a complete repository does not
# make sense`) — running it unconditionally would print a scary failure on every
# healthy session. Best-effort like everything else in this hook: a deepen that fails
# leaves the clone exactly as shallow as it already was and never blocks session start.
# The prose backstop is Claude_Task_Plan.md §Execution environment "HISTORY-DEPTH
# PRECHECK", which still requires a routine to ASK before trusting history — precisely
# because this deepen can fail.
if [ "$(git rev-parse --is-shallow-repository 2>/dev/null)" = "true" ]; then
  if git fetch --unshallow origin >/dev/null 2>&1; then
    echo "[session-start] deepened shallow clone to full history ($(git rev-list --count HEAD 2>/dev/null || echo '?') commits reachable from HEAD)." >&2
  else
    echo "[session-start] WARNING: git fetch --unshallow origin failed; history is still SHALLOW. Treat git log -S/-L, git blame, git log --since and git merge-base --is-ancestor as INCONCLUSIVE this session (Claude_Task_Plan.md, HISTORY-DEPTH PRECHECK)." >&2
  fi
fi

unmerged="$(git rev-list --count origin/main..HEAD 2>/dev/null || echo 0)"
if [ "${unmerged:-0}" != "0" ]; then
  echo "[session-start] WARNING: ${unmerged} commit(s) on $(git rev-parse --abbrev-ref HEAD 2>/dev/null) not in origin/main; resetting anyway (recoverable via reflog or the origin branch)." >&2
fi

# Hard-reset the current (harness-assigned) branch to origin/main so the
# routine starts from the latest committed state. Safe here: the assigned
# branch is fresh per session and has no work to preserve.
if ! git reset --hard origin/main >/dev/null 2>&1; then
  echo "[session-start] git reset --hard origin/main failed" >&2
  exit 0
fi

exit 0

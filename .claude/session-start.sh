#!/bin/bash
# SessionStart hook — put every routine session on `main`.
#
# Per Claude_Task_Plan.md "Branch and state propagation": this project's
# routines work directly on main, overriding the harness's per-session
# `claude/<suffix>` feature branch. This hook makes that deterministic by
# checking out main at session start so subsequent reads see latest state
# from prior routines.
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

# Need a remote to fetch from. If absent (e.g., local resume of a cached
# container with no github source), bail.
if [ -z "$(git remote 2>/dev/null)" ]; then
  exit 0
fi

# Best-effort fetch.
git fetch origin main >/dev/null 2>&1 || true

# Switch to main. If a stash or in-progress merge prevents it, leave the
# session on whatever branch the harness chose and let Claude / the routine
# resolve.
if ! git checkout main >/dev/null 2>&1; then
  echo "[session-start] Could not checkout main; staying on current branch" >&2
  exit 0
fi

# Fast-forward to origin/main. If main has diverged locally for some reason,
# do not auto-rebase here — let the routine handle conflicts via the
# concurrency rule in Claude_Task_Plan.md.
git pull --ff-only origin main >/dev/null 2>&1 || true

exit 0

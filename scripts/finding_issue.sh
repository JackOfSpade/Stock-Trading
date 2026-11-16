#!/usr/bin/env bash
# Shared "one open GitHub issue per finding" helper for the scheduled guard workflows (2026-11-16).
#
# WHY. Eight workflows hand-copied the same block -- `gh issue list` by title prefix, then comment
# (or edit) the open issue or create one, and the mirror-image comment-and-close on recovery: 16
# copies. Two defects came with the copies:
#
#   1. THE SECONDARY CHANNEL GATED THE PRIMARY ONE. A `run:` block has errexit ON, and in six
#      workflows these `gh` calls ran unguarded BEFORE scripts/ci_finding.sh. A transient GitHub
#      Issues failure therefore aborted the step before the ops.ci_findings row was written -- and
#      that row is the only path to the owner's email. This helper NEVER fails its caller: every
#      `gh` failure is a `::warning::` and exit 0, so the bridge write after it always runs.
#   2. `gh issue list` returns 30 issues by default, so with more than 30 open issues the dedup
#      lookup could miss the existing one and open a duplicate every run. --limit is raised here.
#
# Usage:
#   scripts/finding_issue.sh open  <title-prefix> <title> <body-file> [comment|edit]
#       An open issue whose title starts with <title-prefix> gets <body-file> as a new comment
#       (default) or as its replaced body (`edit`); otherwise a new issue titled <title> is created.
#   scripts/finding_issue.sh close <title-prefix> <comment>
#       Comments on and closes the open issue whose title starts with <title-prefix>, if any.
#
# Reads GITHUB_REPOSITORY (set by Actions) and needs GH_TOKEN in the step's env, as before.
set -uo pipefail

mode="${1:-}"
prefix="${2:-}"
repo="${GITHUB_REPOSITORY:-}"
if [ -z "$mode" ] || [ -z "$prefix" ] || [ -z "$repo" ]; then
  echo "::warning::finding_issue.sh: usage: open <title-prefix> <title> <body-file> [comment|edit] | close <title-prefix> <comment> (GITHUB_REPOSITORY must be set) — issue step skipped."
  exit 0
fi

# The prefix reaches jq as DATA (--arg), never spliced into the filter text. pipefail makes a `gh`
# failure fail the whole pipeline, so "could not list" is never mistaken for "no open issue".
if ! existing=$(gh issue list --repo "$repo" --state open --limit 500 --json number,title \
      | jq -r --arg p "$prefix" '[.[] | select(.title | startswith($p))][0].number // empty'); then
  echo "::warning::finding_issue.sh: could not list open issues (transient gh failure?) — the '$prefix' issue was not updated this run."
  exit 0
fi

case "$mode" in
  open)
    title="${3:-}"
    body_file="${4:-}"
    how="${5:-comment}"
    if [ -z "$title" ] || [ ! -f "$body_file" ]; then
      echo "::warning::finding_issue.sh open: missing title or body file ('$body_file') — issue step skipped."
      exit 0
    fi
    if [ -z "$existing" ]; then
      gh issue create --repo "$repo" --title "$title" --body-file "$body_file" \
        || echo "::warning::finding_issue.sh: could not create the '$title' issue (transient gh failure?)."
    elif [ "$how" = "edit" ]; then
      gh issue edit "$existing" --repo "$repo" --body-file "$body_file" \
        && echo "Issue #$existing already open; body refreshed." \
        || echo "::warning::finding_issue.sh: could not refresh issue #$existing — it stays open with a stale body."
    else
      gh issue comment "$existing" --repo "$repo" --body-file "$body_file" \
        && echo "Updated existing issue #$existing." \
        || echo "::warning::finding_issue.sh: could not comment on issue #$existing."
    fi
    ;;
  close)
    comment="${3:-}"
    if [ -z "$existing" ]; then
      echo "No open '$prefix' issue to close."
    else
      gh issue close "$existing" --repo "$repo" --comment "$comment" \
        && echo "Closed issue #$existing." \
        || echo "::warning::finding_issue.sh: could not close issue #$existing — close it by hand if this repeats."
    fi
    ;;
  *)
    echo "::warning::finding_issue.sh: unknown mode '$mode' — issue step skipped."
    ;;
esac
exit 0

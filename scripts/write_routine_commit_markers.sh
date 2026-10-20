#!/usr/bin/env bash
# Preserve RUNBOOK section 38 landing evidence for one verified, explicitly selected PR.
# Git operations inspect only the supplied landed range; this script never checks out,
# enumerates, merges, pushes, or deletes branches. The caller supplies the actual merge
# commit reported by GitHub after the merge, and fetches that object without checking it out.
set -euo pipefail

if [ "$#" -ne 3 ]; then
  echo 'Usage: write_routine_commit_markers.sh <base_sha> <head_sha> <merge_sha>' >&2
  exit 1
fi
base_sha="$1"
head_sha="$2"
merge_sha="$3"
for sha in "$base_sha" "$head_sha" "$merge_sha"; do
  if ! [[ "$sha" =~ ^[0-9a-f]{40}$ ]]; then
    echo 'Refusing marker write: each selected merge identifier must be a full commit SHA.' >&2
    exit 1
  fi
done

# A --merge PR result must have exactly the validated main and selected PR head
# as its two parents. Do not mark an arbitrary range supplied by a stale caller.
parents="$(git show --no-patch --format=%P "$merge_sha")"
if [ "$parents" != "$base_sha $head_sha" ]; then
  echo 'Refusing marker write: landed merge parents do not match the selected base/head.' >&2
  exit 1
fi
if ! git merge-base --is-ancestor "$base_sha" "$head_sha"; then
  echo 'Refusing marker write: the selected PR does not contain its validated main base.' >&2
  exit 1
fi
commits="$(git rev-list --reverse --no-merges "$base_sha..$head_sha")"

# These existing, independently tested guards retain the routine allowlist,
# Anthropic author guard, halt/abort suppression and America/Denver fallback.
# Source the trusted checked-out policy, never files from the selected PR objects.
policy_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# shellcheck source=scripts/auto_merge_decision.sh
source "$policy_root/scripts/auto_merge_decision.sh"

while IFS= read -r sha; do
  [ -n "$sha" ] || continue
  subject="$(git log -1 --format=%s "$sha")"
  author_email="$(git log -1 --format=%ae "$sha")"
  commit_date="$(TZ=America/Denver git log -1 --date=short-local --format=%ad "$sha")"
  routine="$(marker_routine_from_subject "$subject")"
  run_date="$(marker_run_date_from_subject "$subject" "$commit_date")"
  if [ -z "$routine" ] || [ -z "$run_date" ]; then
    continue
  fi
  if ! marker_author_is_routine "$author_email" \
     || marker_subject_declares_no_completion "$subject"; then
    echo "::notice::routine_commit_markers row SUPPRESSED for $sha ($routine $run_date) -- not a routine output commit (author='$author_email', subject='$subject')."
    continue
  fi

  # Preserve the original typed parameter binding and source contract. Failures
  # remain best-effort: a cloud outage cannot undo or fail a completed PR merge.
  # shellcheck disable=SC2016 # BigQuery backticks and @p_* remain literal SQL.
  bq query --project_id=stock-trading-498512 --use_legacy_sql=false --nouse_cache \
    --parameter="p_routine:STRING:${routine}" \
    --parameter="p_run_date:DATE:${run_date}" \
    --parameter="p_git_commit:STRING:${sha}" \
    --parameter="p_commit_subject:STRING:${subject}" \
    'INSERT INTO `stock-trading-498512.ops.routine_commit_markers` (routine, run_date, git_commit, commit_subject, source) VALUES (@p_routine, @p_run_date, @p_git_commit, @p_commit_subject, "auto-merge-claude.yml")' \
    || echo "::warning::routine_commit_markers insert failed for $sha ($routine $run_date) -- section 38 self-heal will not see this run; the completed PR merge is unaffected."
done <<< "$commits"

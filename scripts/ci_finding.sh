#!/usr/bin/env bash
# Shared ops.ci_findings row writer (2026-08-31, code-quality pass — shell-workflows#0).
#
# WHY: `bq query --project_id=... --use_legacy_sql=false --parameter=... 'INSERT INTO
# ops.ci_findings (workflow, finding_key, status, detail, run_url) VALUES (...)'` was hand-typed
# across 9 workflow files (25 call sites), differing only in workflow name, finding_key, status,
# and detail -- the exact "same logic copy-pasted" pattern scripts/notify_webhook.sh and
# scripts/resolve_diff_base.sh were already extracted to stop (see notify_webhook.sh's own
# header). This consolidates the single-row VALUES(...) shape of that idiom, mirroring
# notify_webhook.sh's precedent: a small standalone script, invoked positionally, with its exact
# argv pinned by tests/test_ci_finding.sh via a PATH-stubbed `bq`.
#
# SCOPE, DELIBERATELY NARROW: only the literal single-row VALUES(...) insert (open or resolved,
# for a KNOWN finding_key) is covered. Several call sites instead run an
# `INSERT ... SELECT ... FROM state.ci_findings_open WHERE workflow = ... [AND finding_key = ...]`
# auto-resolve query -- a structurally different statement (it resolves whatever rows are
# currently open, not one caller-known row) -- or carry an extra `ARRAY<STRING>` exclude-list
# parameter (live-sql-parity.yml's per-object auto-resolve). Those sites were left untouched by
# the 2026-08-31 pass; see that pass's notes for the exact per-site list and why each was skipped.
#
# Usage:  scripts/ci_finding.sh <workflow> <finding_key> <status> <detail>
#
# run_url is NOT a parameter -- every one of the 25 call sites builds it identically as
# `${{ github.server_url }}/${{ github.repository }}/actions/runs/${{ github.run_id }}`, which is
# exactly GitHub Actions' own default env vars GITHUB_SERVER_URL / GITHUB_REPOSITORY /
# GITHUB_RUN_ID (https://docs.github.com/actions/learn-github-actions/variables#default-
# environment-variables), present in every job with no `env:` wiring needed. Computing it here
# removes a 5th positional arg every caller would otherwise have to pass identically.
#
# Unlike notify_webhook.sh (which always swallows a curl failure into a `::warning::` and exits
# 0 -- every one of ITS callers wanted best-effort), this script does NOT swallow a bq failure:
# the 25 call sites disagree on fail-loud vs fail-soft (live-sql-parity.yml / sql-dryrun-sweep.yml
# / stranded-branch-check.yml `exit 1` a DRIFT run on a failed INSERT so a dead bridge is never
# invisible inside a red run; the audit-guard workflows `|| echo ::warning::` instead, since a
# best-effort webhook/GH-issue path already covers delivery there). That split is deliberate per
# workflow, not something to unify -- so this script just runs the bq query and exits with ITS
# exit status, exactly like the inline `bq query ...` call it replaces; the caller still decides
# what a non-zero exit means by wrapping this call the same way it wrapped the old one.
set -euo pipefail

# BUG FIX (2026-08-31 code-quality pass): the original per-arg `${N:?msg}` form fires on an EMPTY
# string, not just an UNSET/omitted arg -- `:?` is bash's null-OR-unset check. That's wrong for
# `detail`: the inline `bq query --parameter="p_detail:STRING:${detail}" ...` call this script
# replaced accepted an empty detail as a perfectly valid STRING parameter and inserted the row, but
# `${4:?...}` instead aborted before bq was ever invoked -- silently dropping an ops.ci_findings row
# that used to get written (reachable today: sql-dryrun-sweep.yml's `check_sql_dryrun.py | tee
# sweep.txt` with no `2>&1` leaves sweep.txt empty if the checker dies before printing, so
# `detail=$(head -c 4000 sweep.txt)` is ""). A real usage error (wrong ARG COUNT) is a separate
# concern from an individual arg's VALUE being the empty string, so check `$#` once up front and
# plain-assign the four args -- an empty detail now reaches bq exactly like the inline call did.
if [ "$#" -ne 4 ]; then
  echo "Usage: ci_finding.sh <workflow> <finding_key> <status> <detail>" >&2
  exit 1
fi
workflow="$1"
finding_key="$2"
status="$3"
detail="$4"

run_url="${GITHUB_SERVER_URL}/${GITHUB_REPOSITORY}/actions/runs/${GITHUB_RUN_ID}"

# shellcheck disable=SC2016 # single-quoted intentionally: the backtick-quoted BigQuery identifier
# and @p_* named parameters must stay literal, not shell-expanded.
bq query --project_id=stock-trading-498512 --use_legacy_sql=false \
  --parameter="p_workflow:STRING:${workflow}" \
  --parameter="p_key:STRING:${finding_key}" \
  --parameter="p_status:STRING:${status}" \
  --parameter="p_detail:STRING:${detail}" \
  --parameter="p_url:STRING:${run_url}" \
  'INSERT INTO `stock-trading-498512.ops.ci_findings` (workflow, finding_key, status, detail, run_url) VALUES (@p_workflow, @p_key, @p_status, @p_detail, @p_url)'

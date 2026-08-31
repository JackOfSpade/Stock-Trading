#!/usr/bin/env bash
# Sourceable bq CSV-query helpers, shared by scripts/backup_events.sh, scripts/restore_drill.sh,
# and scripts/state_snapshot.sh (extracted 2026-08-31, code-quality pass — shell-workflows#1).
#
# WHY: all three scripts hand-typed the identical
# `bq --project_id="$PROJECT" query --use_legacy_sql=false --format=csv --quiet --headless
# --max_rows=100000 "<sql>"` invocation, and two of them (backup_events.sh, restore_drill.sh) also
# hand-typed the identical events.* table-enumeration query on top of it. backup_events.sh's own
# comment already said this "Matches restore_drill.sh's own table-enumeration query exactly" — the
# author already knew the two copies had to stay byte-identical, with nothing but that comment
# enforcing it. Mirrors the scripts/resolve_diff_base.sh precedent: production sources ONE
# implementation instead of hand-synced copies (see that file's header for the drift incidents
# that made the case for extraction there — the same class of bug this closes off here).
#
# --max_rows=100000: bq's own CLI default is 100 rows, which would silently drop the
# alphabetically-last tables/rows once a result set grows past 100 — see backup_events.sh's
# original 2026-07-14 finding. Keep this generous; do not tune it down without re-checking that
# finding first.
#
# Not `set -euo pipefail` here on purpose: this file is sourced into a caller that already sets
# its own shell options (all three current callers use `set -euo pipefail`), and bash options are
# shell-wide, not per-function — a function defined here runs under whatever options are active in
# the sourcing shell at call time. Setting options in this file would be redundant at best and,
# for a future caller with different needs, surprising. Same convention as resolve_diff_base.sh.

# bq_csv_query <project> <sql> — runs the query and prints its RAW CSV output (header row
# included) to stdout. state_snapshot.sh's dump() wants the header — its output is a
# human-diffable CSV file meant to be committed to git — so it calls this directly rather than
# going through bq_csv_query_headless below.
bq_csv_query() {
  local project="$1" sql="$2"
  bq --project_id="$project" query --use_legacy_sql=false --format=csv --quiet --headless \
     --max_rows=100000 "$sql"
}

# bq_csv_query_headless <project> <sql> — same query, header row stripped: a plain list of values,
# one per line, ready for a `for` loop or a direct command substitution. What backup_events.sh's
# TABLES= assignment and restore_drill.sh's bqq() wrapper both actually want.
bq_csv_query_headless() {
  bq_csv_query "$1" "$2" | tail -n +2
}

# bq_list_events_tables <project> — every BASE TABLE in the events dataset (the append-only
# substrate), via INFORMATION_SCHEMA rather than `bq ls`'s human-readable text output (immune to a
# future bq CLI output-format change) — shared verbatim by backup_events.sh and restore_drill.sh,
# which must enumerate the identical table set for a backup and its restore drill to be
# comparable at all.
bq_list_events_tables() {
  local project="$1"
  bq_csv_query_headless "$project" \
    "SELECT table_name FROM \`${project}.events.INFORMATION_SCHEMA.TABLES\` WHERE table_type='BASE TABLE' ORDER BY table_name"
}

#!/usr/bin/env bash
# Backup RESTORE drill — prove the events.* GCS Parquet backups are actually restorable.
# =====================================================================================
# A backup you have never restored is a hope, not a backup. scheduled_queries/backup_events_export.sql
# writes daily Parquet to gs://stock-trading-backups/events/<table>/dt=<DATE>/ and ops.backup_log now
# records that it ran (bigquery/16_automation_health.sql), but neither proves the snapshots LOAD BACK.
# This drill loads a dated snapshot of every events.* table into a throwaway scratch dataset and
# sanity-checks the restored row counts against the live tables. Run it periodically (e.g. quarterly)
# from Cloud Shell or anywhere the `bq` CLI is authenticated as a principal with read on the bucket +
# BigQuery job/data access. See ops/RUNBOOK.md §3.
#
# Usage:
#   scripts/restore_drill.sh                 # restore the latest available daily snapshot
#   DATE=2026-06-21 scripts/restore_drill.sh # restore a specific dt=<DATE> snapshot
#   KEEP=1 scripts/restore_drill.sh          # don't drop the scratch dataset afterwards (inspect it)
#
# Env: PROJECT (default stock-trading-498512), BUCKET (default gs://stock-trading-backups),
#      SCRATCH (default events_restore_drill_adhoc), DATE (default = newest dt= partition found in the bucket).
#
# WHY THE DEFAULT SCRATCH IS *_adhoc AND NOT `events_restore_drill` (2026-09-04 quality pass):
# `events_restore_drill` is NOT a throwaway name — it is owned by the AUTOMATED monthly drill
# (ops.sp_restore_drill, bigquery/17_restore_drill.sql, scheduled via
# bigquery/scheduled_queries/restore_drill.sql). That dataset is PRE-CREATED once by hand and carries a
# dataset-SCOPED `roles/bigquery.dataEditor` grant to bq-scheduler@ (ops/RUNBOOK.md §3) precisely so the
# scheduled-query identity never needs project-level dataEditor; the procedure body only does
# `LOAD DATA OVERWRITE ...events_restore_drill.<table>` and deliberately never creates or drops it
# ("Scratch tables persist between runs (overwritten each run) by design, so no dataset-delete
# permission is needed"). Dropping a BigQuery dataset destroys its dataset-level ACL along with it, and
# the `bq mk --force` below re-creates the dataset WITHOUT re-applying that grant — so this ad-hoc
# script defaulting to the shared name and then cleaning up would permanently disarm the monthly DR
# drill: every table would fall into sp_restore_drill's per-table `EXCEPTION WHEN ERROR` handler ->
# `failed != ''` -> a critical `scheduled.restore_drill` ops.alerts row (itself a trading-gate input),
# until the operator re-ran the console GRANT by hand. The cleanup branch at the bottom therefore also
# REFUSES to drop that name even when it is passed explicitly.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=bq_csv.sh
source "$SCRIPT_DIR/bq_csv.sh"

PROJECT="${PROJECT:-stock-trading-498512}"
BUCKET="${BUCKET:-gs://stock-trading-backups}"
BUCKET="${BUCKET%/}"
# Default is *_adhoc, NOT the automated drill's pre-created, IAM-granted `events_restore_drill` —
# see the "WHY THE DEFAULT SCRATCH IS *_adhoc" note in the header above before changing this.
SCRATCH="${SCRATCH:-events_restore_drill_adhoc}"
KEEP="${KEEP:-0}"

command -v bq >/dev/null || { echo "bq CLI not found (install Google Cloud SDK)"; exit 1; }
command -v gcloud >/dev/null || { echo "gcloud CLI not found (install Google Cloud SDK)"; exit 1; }

# bqq(): thin wrapper kept local (used below for the per-table restored/live COUNT(*) queries) --
# delegates to the shared bq_csv_query_headless (scripts/bq_csv.sh, extracted 2026-08-31 --
# shell-workflows#1), which is the exact invocation this used to hand-type inline.
bqq() { bq_csv_query_headless "$PROJECT" "$1"; }

# resolve_backup_date(bucket, table...): the newest dt= partition present ACROSS ALL tables named,
# tolerating any individual table having zero snapshots. Kept as a standalone function (2026-09-02,
# rather than left inlined) specifically so it is unit-testable against a stubbed `gcloud` in isolation
# from live GCS/BigQuery access -- see tests/test_restore_drill.sh (2026-09-04: this citation read
# `tests/test_restore_drill_date_resolution.sh`, a filename that has never existed in this repo's
# history -- it was wrong on the day it landed, not rename rot; ci.yml and auto-merge-claude.yml both
# run `bash tests/test_restore_drill.sh`), which exercises the
# exact bug this replaced: a table that sorts alphabetically first but whose OWN daily EXTRACT has
# started silently erroring (bigquery/scheduled_queries/backup_events_export.sql isolates each table's
# export in its own BEGIN/EXCEPTION block precisely so this can happen to one table while every other
# table keeps exporting fine) must never anchor the whole drill's DATE at its own stale last-good day
# while a fresher snapshot sits unexamined on a later table.
#
# A running max, not "stop at the first table with ANY partition" (that was the 2026-08-08 fix, and it
# undershot -- see the call site below for the full history). A table with NO snapshot at all (a
# brand-new table with no backup written yet) simply never raises the max, preserving the ORIGINAL
# (pre-2026-08-08) fix's tolerance for that case.
resolve_backup_date() {
  local bucket="$1"; shift
  local d date=""
  for t in "$@"; do
    d="$(gcloud storage ls "$bucket/events/$t/" 2>/dev/null \
           | sed -n 's#.*/dt=\([0-9-]\{10\}\)/.*#\1#p' | sort -u | tail -1 || true)"
    if [ -n "$d" ] && { [ -z "$date" ] || [[ "$d" > "$date" ]]; }; then
      date="$d"
    fi
  done
  printf '%s' "$date"
}

# Tables to restore = every base table in the live events dataset.
# NOTE (codebase audit 2026-07-26): do NOT rewrite this back to `mapfile -t TABLES < <(bq_list_events_tables ...)`.
# Under `set -euo pipefail`, bash only checks mapfile's OWN exit status here, not the process
# substitution's -- a failing query (bad PROJECT, revoked IAM, etc.) would NOT trip `set -e` and
# the drill would silently fall through to the empty-array guard below instead of aborting loudly
# with the underlying `bq` error. Confirmed empirically: `f(){ echo line1; return 1; }; mapfile -t
# ARR < <(f)` does not abort. Its sibling scripts/backup_events.sh already uses the direct-
# assignment idiom below for the identical query -- both now literally the same
# bq_list_events_tables() call (2026-08-31, shell-workflows#1) -- which DOES propagate a failure
# straight into `set -e`. Mirror it here so both scripts fail closed the same way.
TABLES_RAW="$(bq_list_events_tables "$PROJECT")"
# Check the raw string BEFORE mapfile, not just the array after: `mapfile -t TABLES <<< ""` does
# NOT yield a zero-length array -- the here-string appends a trailing newline, so bash reads one
# empty line and TABLES ends up with count=1 containing "" (verified empirically, codebase audit
# 2026-07-26). Checking `${#TABLES[@]}` alone would have silently defeated the very guard this is
# meant to be a second layer for, on the exact "empty dataset / wrong PROJECT" case it exists to
# catch.
[ -n "$TABLES_RAW" ] || { echo "no events.* base tables found; aborting"; exit 1; }
mapfile -t TABLES <<< "$TABLES_RAW"
# Empty-array guard kept as a SECOND layer (belt-and-suspenders with the -n check above), not a
# replacement: a query that succeeds with zero rows (empty dataset, wrong PROJECT) still needs to
# abort rather than report a false "OK" over zero tables, same failure mode backup_events.sh's
# 2026-07-14 audit finding covers.
[ "${#TABLES[@]}" -gt 0 ] || { echo "no events.* base tables found; aborting"; exit 1; }

# Resolve the snapshot date: newest dt= partition present ACROSS ALL TABLES, unless DATE is pinned.
# 2026-09-02: was "walk TABLES in order and stop at the first one that yields a partition" (the
# 2026-08-08 fix, which itself replaced an even earlier bug where TABLES[0] alone -- whatever sorts
# alphabetically first -- having zero snapshots aborted the whole script). That 2026-08-08 fix
# undershot: it still `break`s at the FIRST table with ANY partition, so a table with snapshots that
# are merely STALE (see resolve_backup_date's own comment, above, for why that is a real, designed
# failure mode of the backup job this drill validates) silently anchors DATE at its own old last-good
# day if it happens to sort first alphabetically -- every fresher snapshot on every other table is
# never even examined. Now a running max via resolve_backup_date, which keeps the original fix's
# tolerance for a table with NO snapshot at all while no longer letting a stale-but-nonempty one cap
# the whole drill. Bonus: a genuinely-stale table now correctly shows as "LOAD FAILED" in the per-table
# report below (its dt=<true max> partition won't exist) instead of silently "passing" at its own stale
# date.
if [ -z "${DATE:-}" ]; then
  DATE="$(resolve_backup_date "$BUCKET" "${TABLES[@]}")"
fi
[ -n "${DATE:-}" ] || { echo "could not resolve a backup date under $BUCKET/events/ for any table; pass DATE=YYYY-MM-DD"; exit 1; }

echo "Restore drill: project=$PROJECT  bucket=$BUCKET  dt=$DATE  scratch=$SCRATCH"
bq --project_id="$PROJECT" mk --force --dataset --location=US "$PROJECT:$SCRATCH" >/dev/null 2>&1 || true

rc=0
printf '%-26s %12s %12s   %s\n' "TABLE" "RESTORED" "LIVE" "STATUS"
for t in "${TABLES[@]}"; do
  uri="$BUCKET/events/$t/dt=$DATE/*.parquet"
  if ! bq --project_id="$PROJECT" load --source_format=PARQUET --replace "$SCRATCH.$t" "$uri" >/dev/null 2>&1; then
    printf '%-26s %12s %12s   %s\n' "$t" "-" "-" "LOAD FAILED ($uri)"; rc=1; continue
  fi
  # Guarded exactly like the `bq load` above (quality pass 2026-08-22). These were bare command
  # substitutions, so under `set -euo pipefail` a single transient BigQuery error (a
  # rateLimitExceeded, a token refresh blip) on either COUNT aborted the WHOLE drill: no STATUS row
  # for this table, no PASS/FAIL summary, every remaining table unchecked, and — because the script
  # died before its cleanup — the scratch dataset left behind in the project. Reproduced with a
  # stubbed `bq` that fails only the first COUNT: the run printed the header row, then the raw bq
  # error, and exited 1 with the scratch dataset still present. A flaky COUNT now behaves like a
  # flaky load: reported in the table, counted in rc, non-fatal to the rest of the run.
  # CORRECTION (2026-09-04 quality pass): that repro note originally named the leftover dataset as
  # `$PROJECT:events_restore_drill` and framed leaving it behind as the bad outcome. Both halves were
  # wrong, and the inverted mental model is exactly what produced this file's SCRATCH-default bug —
  # the genuinely destructive outcome is DROPPING that shared, IAM-granted dataset (header note),
  # not leaking a throwaway one. The leftover dataset is only the observable symptom of the abort
  # this guard fixes; and the default scratch is now `events_restore_drill_adhoc`, so it is that
  # name, not the automated drill's, that a leak would leave behind.
  if ! restored="$(bqq "SELECT COUNT(*) FROM \`$PROJECT.$SCRATCH.$t\`")"; then
    printf '%-26s %12s %12s   %s\n' "$t" "-" "-" "QUERY FAILED (restored count)"; rc=1; continue
  fi
  if ! live="$(bqq "SELECT COUNT(*) FROM \`$PROJECT.events.$t\`")"; then
    printf '%-26s %12s %12s   %s\n' "$t" "$restored" "-" "QUERY FAILED (live count)"; rc=1; continue
  fi
  status="ok"
  # append-only tables grow, so restored (a past snapshot) must never EXCEED live; and must be non-empty
  # UNLESS the live table is itself empty (a genuinely-empty table restoring to 0 is fine).
  if [ "${restored:-0}" -eq 0 ] && [ "${live:-0}" -gt 0 ]; then status="EMPTY (suspicious)"; rc=1
  elif [ "${restored:-0}" -gt "${live:-0}" ]; then status="RESTORED>LIVE (corruption?)"; rc=1; fi
  printf '%-26s %12s %12s   %s\n' "$t" "$restored" "$live" "$status"
done

# Checked BEFORE the KEEP branch (2026-09-04 quality pass) so an explicit
# `SCRATCH=events_restore_drill` override is never even HANDED the "drop with: bq rm -r -f -d ..."
# hint the KEEP branch prints. That dataset is the automated monthly drill's pre-created,
# dataset-scoped-IAM-granted one (see the header note): dropping it takes bq-scheduler@'s
# `roles/bigquery.dataEditor` grant with it and disarms ops.sp_restore_drill until the operator
# re-runs the console GRANT by hand. REUSING it is otherwise harmless, which is why this guards the
# drop rather than rejecting the name outright — the `bq mk --force` above is a NO-OP on an existing
# dataset (-f suppresses the already-exists error; it does not recreate the dataset or touch its ACL),
# and the per-table `bq load --replace` overwrites exactly the tables the monthly drill itself
# overwrites on every run.
if [ "$SCRATCH" = "events_restore_drill" ]; then
  echo "Scratch dataset kept: $PROJECT:$SCRATCH — NOT dropping it; it is the pre-created dataset"
  echo "  ops.sp_restore_drill depends on (bigquery/17_restore_drill.sql), and its dataset-scoped"
  echo "  bq-scheduler@ dataEditor grant would be destroyed along with it."
elif [ "$KEEP" = "1" ]; then
  echo "Scratch dataset kept: $PROJECT:$SCRATCH (drop with: bq rm -r -f -d $PROJECT:$SCRATCH)"
else
  bq --project_id="$PROJECT" rm -r -f -d "$PROJECT:$SCRATCH" >/dev/null 2>&1 || true
fi

[ "$rc" -eq 0 ] && echo "RESTORE DRILL: OK — all tables restored from dt=$DATE." \
                || echo "RESTORE DRILL: FAILED — see rows above."
exit "$rc"

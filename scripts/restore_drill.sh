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
#      SCRATCH (default events_restore_drill), DATE (default = newest dt= partition found in the bucket).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=bq_csv.sh
source "$SCRIPT_DIR/bq_csv.sh"

PROJECT="${PROJECT:-stock-trading-498512}"
BUCKET="${BUCKET:-gs://stock-trading-backups}"
BUCKET="${BUCKET%/}"
SCRATCH="${SCRATCH:-events_restore_drill}"
KEEP="${KEEP:-0}"

command -v bq >/dev/null || { echo "bq CLI not found (install Google Cloud SDK)"; exit 1; }
command -v gcloud >/dev/null || { echo "gcloud CLI not found (install Google Cloud SDK)"; exit 1; }

# bqq(): thin wrapper kept local (used below for the per-table restored/live COUNT(*) queries) --
# delegates to the shared bq_csv_query_headless (scripts/bq_csv.sh, extracted 2026-08-31 --
# shell-workflows#1), which is the exact invocation this used to hand-type inline.
bqq() { bq_csv_query_headless "$PROJECT" "$1"; }

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

# Resolve the snapshot date: newest dt= partition present, unless DATE is pinned. Walk TABLES in
# order and stop at the first one that yields a partition -- NOT just TABLES[0] (2026-08-08 fix).
# TABLES[0] is whatever sorts alphabetically first in events.*, so a newly-added table with no
# backup written yet, or a one-off gap in that single table, made DATE resolve empty even though
# every other table had a perfectly good snapshot to restore from.
if [ -z "${DATE:-}" ]; then
  for t in "${TABLES[@]}"; do
    DATE="$(gcloud storage ls "$BUCKET/events/$t/" 2>/dev/null \
              | sed -n 's#.*/dt=\([0-9-]\{10\}\)/.*#\1#p' | sort -u | tail -1 || true)"
    [ -n "${DATE:-}" ] && break
  done
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
  # error, and exited 1 with `$PROJECT:events_restore_drill` still present. A flaky COUNT now
  # behaves like a flaky load: reported in the table, counted in rc, non-fatal to the rest of the run.
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

if [ "$KEEP" = "1" ]; then
  echo "Scratch dataset kept: $PROJECT:$SCRATCH (drop with: bq rm -r -f -d $PROJECT:$SCRATCH)"
else
  bq --project_id="$PROJECT" rm -r -f -d "$PROJECT:$SCRATCH" >/dev/null 2>&1 || true
fi

[ "$rc" -eq 0 ] && echo "RESTORE DRILL: OK — all tables restored from dt=$DATE." \
                || echo "RESTORE DRILL: FAILED — see rows above."
exit "$rc"

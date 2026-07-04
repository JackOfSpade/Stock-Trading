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

PROJECT="${PROJECT:-stock-trading-498512}"
BUCKET="${BUCKET:-gs://stock-trading-backups}"
SCRATCH="${SCRATCH:-events_restore_drill}"
KEEP="${KEEP:-0}"

bqq() { bq --project_id="$PROJECT" query --use_legacy_sql=false --format=csv --quiet --headless --max_rows=100000 "$1" | tail -n +2; }

# Tables to restore = every base table in the live events dataset.
mapfile -t TABLES < <(bqq "SELECT table_name FROM \`$PROJECT.events.INFORMATION_SCHEMA.TABLES\` WHERE table_type='BASE TABLE' ORDER BY table_name")
[ "${#TABLES[@]}" -gt 0 ] || { echo "no events.* base tables found; aborting"; exit 1; }

# Resolve the snapshot date: newest dt= partition present for the first table, unless DATE is pinned.
if [ -z "${DATE:-}" ]; then
  DATE="$(gsutil ls "$BUCKET/events/${TABLES[0]}/" 2>/dev/null \
            | sed -n 's#.*/dt=\([0-9-]\{10\}\)/.*#\1#p' | sort -u | tail -1 || true)"
fi
[ -n "${DATE:-}" ] || { echo "could not resolve a backup date under $BUCKET/events/${TABLES[0]}/; pass DATE=YYYY-MM-DD"; exit 1; }

echo "Restore drill: project=$PROJECT  bucket=$BUCKET  dt=$DATE  scratch=$SCRATCH"
bq --project_id="$PROJECT" mk --force --dataset --location=US "$PROJECT:$SCRATCH" >/dev/null 2>&1 || true

rc=0
printf '%-26s %12s %12s   %s\n' "TABLE" "RESTORED" "LIVE" "STATUS"
for t in "${TABLES[@]}"; do
  uri="$BUCKET/events/$t/dt=$DATE/*.parquet"
  if ! bq --project_id="$PROJECT" load --source_format=PARQUET --replace "$SCRATCH.$t" "$uri" >/dev/null 2>&1; then
    printf '%-26s %12s %12s   %s\n' "$t" "-" "-" "LOAD FAILED ($uri)"; rc=1; continue
  fi
  restored="$(bqq "SELECT COUNT(*) FROM \`$PROJECT.$SCRATCH.$t\`")"
  live="$(bqq "SELECT COUNT(*) FROM \`$PROJECT.events.$t\`")"
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

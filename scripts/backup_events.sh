#!/usr/bin/env bash
# Back up the append-only event store to GCS (P2-1).
#
# WHY: after the 2026-06-06 cutover, ALL operational state lives in BigQuery and the .md
# mirrors were retired. events.* is the durable source of truth (everything else rebuilds
# from it), but there are NO snapshots beyond BigQuery's default 7-day time travel. This
# exports each events.* table to Parquet in GCS so the substrate survives a bad procedure
# run, an accidental DROP, or project loss.
#
# Run from anywhere with the bq/gcloud CLIs authenticated (owner machine, Cloud Shell, or a
# scheduled Cloud Run job). Schedule daily via Cloud Scheduler -> see ops/RUNBOOK.md.
#
# Usage:  BUCKET=gs://my-bucket scripts/backup_events.sh
set -euo pipefail

PROJECT="${PROJECT:-stock-trading-498512}"
BUCKET="${BUCKET:?Set BUCKET, e.g. BUCKET=gs://stock-trading-backups}"
STAMP="$(date -u +%Y%m%d)"
DEST="${BUCKET%/}/events/${STAMP}"

command -v bq >/dev/null || { echo "bq CLI not found (install Google Cloud SDK)"; exit 1; }

# Every table in the append-only events dataset (the irreplaceable substrate).
TABLES="$(bq --project_id="$PROJECT" ls --max_results=1000 "${PROJECT}:events" \
          | awk 'NR>2 && $2=="TABLE"{print $1}')"

echo "Backing up events.* -> ${DEST}/"
for t in $TABLES; do
  echo "  extract events.${t}"
  bq --project_id="$PROJECT" extract \
     --destination_format=PARQUET \
     --compression=SNAPPY \
     "${PROJECT}:events.${t}" \
     "${DEST}/${t}-*.parquet"
done

echo "Done. Restore with: bq load --source_format=PARQUET events.<table> '${DEST}/<table>-*.parquet'"
echo "TIP: set a GCS lifecycle rule (e.g. keep 90 daily, then monthly) — see ops/RUNBOOK.md."

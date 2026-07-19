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
STAMP="$(date -u +%Y-%m-%d)"

command -v bq >/dev/null || { echo "bq CLI not found (install Google Cloud SDK)"; exit 1; }

# Every table in the append-only events dataset (the irreplaceable substrate).
# INFORMATION_SCHEMA.TABLES, not `bq ls`'s human-readable text output -- immune to a future bq
# CLI output-format change (header-count/column-order), unlike the columnar-text-parse this
# replaced. Matches restore_drill.sh's own table-enumeration query exactly, including the explicit
# --max_rows: bq's built-in default is 100 rows, which would silently drop the alphabetically-last
# tables once the dataset grows past 100 -- the same silent-incompleteness class the guard below
# exists for.
TABLES="$(bq --project_id="$PROJECT" query --use_legacy_sql=false --format=csv --quiet --headless \
          --max_rows=100000 \
          "SELECT table_name FROM \`${PROJECT}.events.INFORMATION_SCHEMA.TABLES\` WHERE table_type='BASE TABLE' ORDER BY table_name" \
          | tail -n +2)"

# A genuinely-empty events dataset, a wrong PROJECT, or a query that succeeds with zero rows
# would otherwise silently back up ZERO tables and still print "Done." with exit 0 (2026-07-14
# audit finding). A real permission or query failure now trips `set -e`/`pipefail` directly via
# bq's own non-zero exit code before this guard is even reached, since the pipeline runs under
# `set -euo pipefail`.
[ -n "$TABLES" ] || { echo "no events.* base tables found via INFORMATION_SCHEMA.TABLES (check PROJECT=$PROJECT or IAM list/query permission); aborting rather than reporting a false 'Done.'"; exit 1; }

# Per-table dt=<date> layout — SAME as the production scheduled export
# (bigquery/scheduled_queries/backup_events_export.sql) and scripts/restore_drill.sh, so an ad-hoc
# snapshot from this script is discoverable/loadable by restore_drill.sh without any translation.
echo "Backing up events.* -> ${BUCKET%/}/events/<table>/dt=${STAMP}/"
for t in $TABLES; do
  DEST="${BUCKET%/}/events/${t}/dt=${STAMP}"
  echo "  extract events.${t} -> ${DEST}/"
  bq --project_id="$PROJECT" extract \
     --destination_format=PARQUET \
     --compression=SNAPPY \
     "${PROJECT}:events.${t}" \
     "${DEST}/*.parquet"
done

echo "Done. Restore one table with: bq load --source_format=PARQUET events.<table> '${BUCKET%/}/events/<table>/dt=${STAMP}/*.parquet'"
echo "Or verify + load every table at once: DATE=${STAMP} BUCKET=${BUCKET} scripts/restore_drill.sh"
echo "TIP: set a GCS lifecycle rule (e.g. keep 90 daily, then monthly) — see ops/RUNBOOK.md."

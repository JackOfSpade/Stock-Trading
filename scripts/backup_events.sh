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

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=bq_csv.sh
source "$SCRIPT_DIR/bq_csv.sh"

PROJECT="${PROJECT:-stock-trading-498512}"
BUCKET="${BUCKET:?Set BUCKET, e.g. BUCKET=gs://stock-trading-backups}"
# dt= is the OPERATING-plane day key, not a display timestamp — CLAUDE.md's timezone-planes note
# ("A date boundary there is the partition key for records, not a display preference"). The production
# export this script claims layout parity with formats its uri from `CURRENT_DATE('America/Denver')`
# and stamps ops.backup_log.run_date on the same plane (ops.sp_sq_backup_events_export,
# bigquery/75_scheduled_query_wrappers.sql), and ops.sp_restore_drill pins its drill_date from
# MAX(run_date) there. This was `date -u`, which disagrees with Denver (UTC-6/-7) for the whole
# ~17:00/18:00 MT -> midnight MT window: an evening ad-hoc snapshot was MISLABELLED under TOMORROW's
# dt=, so it no longer denoted the operating-plane day it actually captured — which is the one thing
# that key means to ops.backup_log.run_date, to sp_restore_drill's drill_date, and to the
# `DATE=${STAMP} ... scripts/restore_drill.sh` hint this script prints at the end. (Sharing the prefix
# with the scheduled export means an ad-hoc snapshot is overwritten by that day's scheduled run
# either way — overwrite=true; what the pin fixes is which day's snapshot it claims to be.)
# `TZ=...` here is a literal pin to the existing operating-plane pin, NOT a runtime timezone lookup —
# it makes this script obey that settled decision instead of diverging from it.
STAMP="$(TZ=America/Denver date +%Y-%m-%d)"

command -v bq >/dev/null || { echo "bq CLI not found (install Google Cloud SDK)"; exit 1; }

# Every table in the append-only events dataset (the irreplaceable substrate).
# INFORMATION_SCHEMA.TABLES, not `bq ls`'s human-readable text output -- immune to a future bq
# CLI output-format change (header-count/column-order), unlike the columnar-text-parse this
# replaced. bq_list_events_tables() (scripts/bq_csv.sh, extracted 2026-08-31 -- shell-workflows#1)
# is the SAME function scripts/restore_drill.sh calls for its own table enumeration, so the two
# scripts can no longer drift the way a hand-copied comment promise could not actually prevent;
# see that file's header for the --max_rows=100000 rationale (bq's built-in default is 100 rows,
# which would silently drop the alphabetically-last tables once the dataset grows past 100 -- the
# same silent-incompleteness class the guard below exists for).
TABLES="$(bq_list_events_tables "$PROJECT")"

# A genuinely-empty events dataset, a wrong PROJECT, or a query that succeeds with zero rows
# would otherwise silently back up ZERO tables and still print "Done." with exit 0 (2026-07-14
# audit finding). A real permission or query failure now trips `set -e`/`pipefail` directly via
# bq's own non-zero exit code before this guard is even reached, since the pipeline runs under
# `set -euo pipefail`.
[ -n "$TABLES" ] || { echo "no events.* base tables found via INFORMATION_SCHEMA.TABLES (check PROJECT=$PROJECT or IAM list/query permission); aborting rather than reporting a false 'Done.'"; exit 1; }

# Per-table dt=<date> layout — SAME as the production scheduled export
# (bigquery/scheduled_queries/backup_events_export.sql) and scripts/restore_drill.sh, so an ad-hoc
# snapshot from this script is discoverable/loadable by restore_drill.sh without any translation.
#
# 2026-09-04 quality pass — this loop was `bq extract --destination_format=PARQUET` per table, which
# is NOT the layout the comment above claims parity with. Two independent defects, the first of which
# (per this repo's OWN measurement of the identical table set, recorded in that export's header — the
# fix was made read-only, without a live `bq` run) hit the very first table enumerated:
#
#  (1) JSON COLUMNS. The production export's header records the measured reason it is not a plain
#      extract: "Parquet cannot serialize BigQuery's native JSON type ('Type JSON is not currently
#      supported for parquet' — and a dry-run does NOT catch this, since it never serializes)", so it
#      emits each JSON column as TO_JSON_STRING(col) AS col, lossless and round-trippable via
#      PARSE_JSON on restore. `bq extract` has no projection, so that mitigation was unavailable here.
#      Five of the 25 events base tables carry native JSON columns (bigquery/01_schema.sql:
#      adversarial_reviews.weaknesses, decision_log.fields, position_events.invalidation_status,
#      queue_events.payload, trade_fills.raw — re-counted 2026-09-04 against 01_schema.sql plus every
#      later `ADD COLUMN ... JSON`, which adds none to events) — and bq_list_events_tables() orders by
#      table_name, so `adversarial_reviews` was the FIRST table extracted and, with no per-table
#      isolation, `set -euo pipefail` aborted the whole run with ZERO tables backed up. And should
#      BigQuery ever add JSON->Parquet extract support, the residual defect is unchanged in kind: the
#      extract wrote a DIFFERENT schema (native JSON vs the stringified form) into the same
#      `events/<table>/dt=<date>/*.parquet` prefix that scripts/restore_drill.sh and
#      ops.sp_restore_drill both glob, and that ops/RUNBOOK.md §3's restore recipe assumes is
#      stringified ("re-parse: SELECT * REPLACE(SAFE.PARSE_JSON(<col>) AS <col>) ...").
#  (2) NO PER-TABLE ISOLATION. The production export wraps each table in its own BEGIN/EXCEPTION "so
#      one failing table can't abort the rest of the run"; here a single transient failure killed the
#      backup at that table. This is the same paired-mechanism drift scripts/restore_drill.sh's own
#      2026-08-22 fix closed on its COUNT queries ("a flaky COUNT now behaves like a flaky load ...
#      non-fatal to the rest of the run"); the shell equivalent of BEGIN/EXCEPTION is the `if ! ...;
#      then failed=...; continue; fi` below, with a loud non-zero exit at the end.
#
# COST/IAM CHANGE, stated deliberately rather than left implicit: `bq extract` submits a free EXTRACT
# job needing bigquery.tables.export; `EXPORT DATA` is a billed QUERY job that scans each events table
# and needs jobs.create + data read. In a cost-sensitive repo that is a real change — it is accepted
# because it is the only way to get the JSON projection, and the production export already pays
# exactly this every day, so layout parity (the whole point of this script) requires paying it too.
#
# The per-table column list is built by a subquery kept INSIDE the BigQuery statement via
# EXECUTE IMMEDIATE FORMAT — a faithful port of ops.sp_sq_backup_events_export
# (bigquery/75_scheduled_query_wrappers.sql). It is deliberately NOT round-tripped through the shell
# via bq_csv.sh's helpers: `bq query --format=csv` would wrap the STRING_AGG result in double quotes
# (it contains ', ' separators), and the generated statement would be malformed. Keeping it in SQL
# also means the list stays correct as columns/tables change, exactly as the production export's own
# comment promises.
echo "Backing up events.* -> ${BUCKET%/}/events/<table>/dt=${STAMP}/"
failed=""
for t in $TABLES; do
  DEST="${BUCKET%/}/events/${t}/dt=${STAMP}"
  echo "  export events.${t} -> ${DEST}/"
  if ! bq --project_id="$PROJECT" query --use_legacy_sql=false --quiet --headless "
    EXECUTE IMMEDIATE FORMAT(\"\"\"
      EXPORT DATA OPTIONS(
        uri='${DEST}/*.parquet',
        format='PARQUET', compression='SNAPPY', overwrite=true
      ) AS SELECT %s FROM \`${PROJECT}.events.${t}\`
    \"\"\",
      -- per-table column list: JSON -> TO_JSON_STRING(col) AS col; everything else verbatim
      (SELECT STRING_AGG(
                IF(data_type = 'JSON',
                   FORMAT('TO_JSON_STRING(\`%s\`) AS \`%s\`', column_name, column_name),
                   FORMAT('\`%s\`', column_name)),
                ', ' ORDER BY ordinal_position)
       FROM \`${PROJECT}.events.INFORMATION_SCHEMA.COLUMNS\`
       WHERE table_name = '${t}'))
  " >/dev/null; then
    echo "  !! export FAILED for events.${t} (continuing with the remaining tables)" >&2
    failed="${failed} ${t}"
    continue
  fi
done

# Loud, non-zero exit on any failure: a partial backup must never print a bare "Done." with exit 0 —
# the same false-success failure mode the empty-TABLES guard above exists for (2026-07-14 finding).
if [ -n "$failed" ]; then
  echo "BACKUP INCOMPLETE — these tables did NOT export:${failed}" >&2
  echo "Every other table was written to ${BUCKET%/}/events/<table>/dt=${STAMP}/ (per-table isolation)." >&2
  exit 1
fi

echo "Done. Restore one table with: bq load --source_format=PARQUET events.<table> '${BUCKET%/}/events/<table>/dt=${STAMP}/*.parquet'"
echo "  (JSON columns come back as STRING — re-parse with: SELECT * REPLACE(SAFE.PARSE_JSON(<col>) AS <col>) ... — see ops/RUNBOOK.md §3.)"
echo "Or verify + load every table at once: DATE=${STAMP} BUCKET=${BUCKET} scripts/restore_drill.sh"
echo "TIP: set a GCS lifecycle rule (e.g. keep 90 daily, then monthly) — see ops/RUNBOOK.md."

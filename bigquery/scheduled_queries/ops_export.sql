-- SCHEDULED QUERY (2026-06-28 stack review #2, #2): back up the ops.* control-plane / audit dataset to
-- GCS — the sibling of backup_events_export.sql. NO Cloud Run job, NO downloadable key.
--
-- WHY THIS EXISTS. backup_events_export.sql backs up events.* on the premise "everything else rebuilds
-- from events.*". That holds for state/perf/analytics (derived views) but NOT for ops.* base tables:
--   * ops.run_log         — the entire "what ran when" audit trail (no upstream)
--   * ops.alerts          — every raised/resolved alert + notified_ts (no upstream)
--   * ops.backup_log      — the backup markers the restore drill anchors on (no upstream)
--   * ops.heartbeat       — Apps Script liveness beats (no upstream)
--   * ops.account_snapshot — weekly NAV/TWR (softer: partially re-derivable from IBKR, but cheap to keep)
--   * ops.drill_log       — restore-drill liveness markers (no upstream)
-- The operating model permits out-of-band console/MCP mutation and only 7-day time-travel protects ops.*,
-- so an accidental ops drop would permanently erase the audit trail AND the DR anchor. This closes that
-- single-point-of-loss. Kept SEPARATE from the events export so an ops-export failure can never abort the
-- irreplaceable events.* backup.
--
-- Exports every BASE TABLE in `ops` to gs://stock-trading-backups/ops/<table>/dt=<date>/ as Snappy
-- Parquet (overwrite=true → same-day re-run idempotent; the bucket's >400d lifecycle ages snapshots out).
-- Skips ops.* objects that are NOT base tables (procedures, the text_embed/gemini remote models, views).
-- JSON columns (ops.alerts.payload) are emitted via TO_JSON_STRING — Parquet cannot serialize native JSON;
-- re-parse with PARSE_JSON on restore (same convention as the events export). Per-table isolation so one
-- failing table cannot abort the rest. On full success, logs an ops.backup_log marker with dataset='ops'
-- (state.ops_backup_health / cadence_check.sql detect a silently-stalled ops backup).
--
-- ONE-TIME SETUP (ops/RUNBOOK.md §3): create as a daily scheduled query (~05:35 UTC, after the events
-- export at ~05:30; Location US; no destination table), under the SAME identity as the events backup
-- (bq-scheduler@; it already holds roles/storage.objectAdmin on gs://stock-trading-backups). Enable
-- "Send email on failure". APPLY ORDER: bigquery/16_automation_health.sql (adds backup_log.dataset +
-- state.ops_backup_health) must be applied BEFORE creating this query.
--
-- Restore an ops table (JSON columns come back as STRING):
--   bq load --source_format=PARQUET --replace ops_restore.<table> \
--     'gs://stock-trading-backups/ops/<table>/dt=<YYYY-MM-DD>/*.parquet'
--   -- DDL-first (faithful) restore: see ops/RUNBOOK.md §3 "DDL-first restore".
-- SQ_NAME: ops_export  SQ_VERSION: v1 (self-improvement audit 2026-07-15, scheduled-query
-- body-drift detection — bigquery/63_scheduled_query_version_registry.sql). Bump SQ_VERSION here AND
-- state.expected_scheduled_query_versions' matching row on any future edit to this file's body.
BEGIN
  DECLARE failed STRING DEFAULT '';
  DECLARE n_ok INT64 DEFAULT 0;
  DECLARE row_json STRING DEFAULT '';
  DECLARE tbl_rows INT64;
  CALL `stock-trading-498512.ops.sp_beat_heartbeat`('sq:ops_export', 'v1', 'ops_export.sql ran');

  FOR rec IN (
    SELECT table_name
    FROM `stock-trading-498512.ops.INFORMATION_SCHEMA.TABLES`
    WHERE table_type = 'BASE TABLE'   -- excludes procedures, remote models (text_embed/gemini), and views
    ORDER BY table_name
  ) DO
    BEGIN
      EXECUTE IMMEDIATE FORMAT("""
        EXPORT DATA OPTIONS(
          uri='gs://stock-trading-backups/ops/%s/dt=%s/*.parquet',
          format='PARQUET', compression='SNAPPY', overwrite=true
        ) AS SELECT %s FROM `stock-trading-498512.ops.%s`
      """,
        rec.table_name,
        CAST(CURRENT_DATE('America/Denver') AS STRING),
        (SELECT STRING_AGG(
                  IF(data_type = 'JSON',
                     FORMAT('TO_JSON_STRING(`%s`) AS `%s`', column_name, column_name),
                     FORMAT('`%s`', column_name)),
                  ', ' ORDER BY ordinal_position)
         FROM `stock-trading-498512.ops.INFORMATION_SCHEMA.COLUMNS`
         WHERE table_name = rec.table_name),
        rec.table_name);
      SET n_ok = n_ok + 1;
      EXECUTE IMMEDIATE FORMAT(
        "SELECT COUNT(*) FROM `stock-trading-498512.ops.%s`", rec.table_name) INTO tbl_rows;
      SET row_json = row_json || FORMAT('%s"%s":%d', IF(row_json = '', '', ','), rec.table_name, tbl_rows);
    EXCEPTION WHEN ERROR THEN
      SET failed = failed || FORMAT('%s (%s); ', rec.table_name, @@error.message);
    END;
  END FOR;

  IF failed != '' THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.backup', 'ops_backup_export',
      CONCAT('ops backup: some tables failed to export: ', failed),
      TO_JSON_STRING(STRUCT(failed AS failed_tables)));
    RAISE USING MESSAGE = CONCAT('ops-backup-daily: table export failures: ', failed);
  ELSE
    -- dataset='ops' marker so state.ops_backup_health (16_automation_health.sql) can detect a stalled
    -- ops backup. SAFE.PARSE_JSON so a malformed map degrades to NULL rather than aborting the marker.
    INSERT INTO `stock-trading-498512.ops.backup_log` (run_date, tables_exported, per_table_rows, dataset, note)
    VALUES (CURRENT_DATE('America/Denver'), n_ok,
            SAFE.PARSE_JSON('{' || row_json || '}'), 'ops', 'ops.* export OK');
  END IF;
END;

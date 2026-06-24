-- SCHEDULED QUERY (P2-1): back up the entire append-only event store to GCS — NO Cloud Run job,
-- NO downloadable key. Runs as the scheduled query's own identity straight from BigQuery.
--
-- Exports every base table in `events` to gs://stock-trading-backups/events/<table>/dt=<date>/ as
-- Snappy Parquet. overwrite=true makes a same-day re-run idempotent; the bucket's >400d lifecycle
-- ages old snapshots out.
--
-- TWO robustness details (learned from the first live run):
--  (1) Parquet cannot serialize BigQuery's native JSON type ("Type JSON is not currently supported
--      for parquet" — and a dry-run does NOT catch this, since it never serializes). So each table's
--      JSON columns are emitted with TO_JSON_STRING(...) — lossless, round-trippable via PARSE_JSON
--      on restore. The column list is built per-table from INFORMATION_SCHEMA.COLUMNS, so it stays
--      correct as columns/tables change. (JSON cols today: adversarial_reviews.weaknesses,
--      decision_log.fields, position_events.invalidation_status, queue_events.payload, trade_fills.raw.)
--  (2) Each table's export is isolated in its own BEGIN/EXCEPTION, so one failing table can't abort
--      the rest of the run. Failures are collected, written to ops.alerts, and re-raised at the end
--      so the scheduled query's "email on failure" still fires.
--
-- ONE-TIME SETUP (ops/RUNBOOK.md §3): create as a daily scheduled query (~05:30 UTC, Location US,
-- no destination table) under the OWNER's own credentials — the owner already owns the bucket, so
-- no IAM grant is needed. (A dedicated SA would instead need roles/storage.objectAdmin on the bucket.)
--
-- Restore a table (JSON columns come back as STRING):
--   bq load --source_format=PARQUET --replace events_restore.<table> \
--     'gs://stock-trading-backups/events/<table>/dt=<YYYY-MM-DD>/*.parquet'
--   -- for tables with JSON cols, re-parse: SELECT * REPLACE(SAFE.PARSE_JSON(<col>) AS <col>) ...
BEGIN
  DECLARE failed STRING DEFAULT '';
  DECLARE n_ok INT64 DEFAULT 0;   -- tables exported successfully this run (-> ops.backup_log marker)
  DECLARE row_json STRING DEFAULT '';  -- accumulates {"table": rows, ...} per exported table (B2)
  DECLARE tbl_rows INT64;

  FOR rec IN (
    SELECT table_name
    FROM `stock-trading-498512.events.INFORMATION_SCHEMA.TABLES`
    WHERE table_type = 'BASE TABLE'
    ORDER BY table_name
  ) DO
    BEGIN
      EXECUTE IMMEDIATE FORMAT("""
        EXPORT DATA OPTIONS(
          uri='gs://stock-trading-backups/events/%s/dt=%s/*.parquet',
          format='PARQUET', compression='SNAPPY', overwrite=true
        ) AS SELECT %s FROM `stock-trading-498512.events.%s`
      """,
        rec.table_name,
        CAST(CURRENT_DATE('America/Denver') AS STRING),
        -- per-table column list: JSON -> TO_JSON_STRING(col) AS col; everything else verbatim
        (SELECT STRING_AGG(
                  IF(data_type = 'JSON',
                     FORMAT('TO_JSON_STRING(`%s`) AS `%s`', column_name, column_name),
                     FORMAT('`%s`', column_name)),
                  ', ' ORDER BY ordinal_position)
         FROM `stock-trading-498512.events.INFORMATION_SCHEMA.COLUMNS`
         WHERE table_name = rec.table_name),
        rec.table_name);
      SET n_ok = n_ok + 1;   -- counted only if the EXPORT above succeeded (else we jump to EXCEPTION)
      -- B2: record this table's source row count in the backup marker (per_table_rows). EXPORT DATA is
      -- atomic — a non-empty source either fully exports or RAISEs — so this is the row-count evidence
      -- the §3 restore drill asserts, captured at WRITE time: auditable day-over-day (an append-only
      -- table's count only grows; a drop = deletion or a future predicate regression) and a forensic
      -- anchor for a restore. (hf_capability_captures = 0 is legitimately empty.)
      EXECUTE IMMEDIATE FORMAT(
        "SELECT COUNT(*) FROM `stock-trading-498512.events.%s`", rec.table_name) INTO tbl_rows;
      SET row_json = row_json || FORMAT('%s"%s":%d', IF(row_json = '', '', ','), rec.table_name, tbl_rows);
    EXCEPTION WHEN ERROR THEN
      -- isolate the failure; keep backing up the remaining tables
      SET failed = failed || FORMAT('%s (%s); ', rec.table_name, @@error.message);
    END;
  END FOR;

  -- Surface any failures: durable alert + RAISE so the scheduled query's email-on-failure fires.
  IF failed != '' THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.backup', 'backup_export',
      CONCAT('events backup: some tables failed to export: ', failed),
      TO_JSON_STRING(STRUCT(failed AS failed_tables)));
    RAISE USING MESSAGE = CONCAT('events-backup-daily: table export failures: ', failed);
  ELSE
    -- Success marker (bigquery/16_automation_health.sql): records that the backup ran, so
    -- state.backup_health / cadence_check.sql can detect a SILENTLY-STALLED backup (one that simply
    -- stops running) — which the data-side freshness switch cannot see. Only on a full-success run.
    -- per_table_rows carries the B2 per-table source counts (bigquery/18_stack_review_fixes.sql adds
    -- the column; apply 18 before re-pasting this query). SAFE.PARSE_JSON so a malformed map degrades
    -- to NULL rather than aborting the marker write.
    INSERT INTO `stock-trading-498512.ops.backup_log` (run_date, tables_exported, per_table_rows, note)
    VALUES (CURRENT_DATE('America/Denver'), n_ok,
            SAFE.PARSE_JSON('{' || row_json || '}'), 'events.* export OK');
  END IF;
END;

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
  END IF;
END;

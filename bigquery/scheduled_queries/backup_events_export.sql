-- SCHEDULED QUERY (P2-1): back up the entire append-only event store to GCS — NO Cloud Run job,
-- NO downloadable key. Runs as the scheduled query's own identity straight from BigQuery.
--
-- Exports every base table in `events` to gs://stock-trading-backups/events/<table>/dt=<date>/ as
-- Snappy Parquet. `overwrite=true` makes a same-day re-run idempotent. The GCS lifecycle rule
-- (delete > 400 days) ages old snapshots out.
--
-- ONE-TIME SETUP (ops/RUNBOOK.md §3):
--   * Grant the scheduled query's service account roles/storage.objectAdmin on the bucket
--     (BigQuery DTS → the query's SA, or the project's BigQuery service agent).
--   * Schedule: daily ~05:30 UTC (after the freshness check); Location US; no destination table.
--
-- Restore a table:  bq load --source_format=PARQUET events.<table> \
--                     'gs://stock-trading-backups/events/<table>/dt=<YYYY-MM-DD>/*.parquet'
FOR rec IN (
  SELECT table_name
  FROM `stock-trading-498512.events.INFORMATION_SCHEMA.TABLES`
  WHERE table_type = 'BASE TABLE'
) DO
  EXECUTE IMMEDIATE FORMAT("""
    EXPORT DATA OPTIONS(
      uri='gs://stock-trading-backups/events/%s/dt=%s/*.parquet',
      format='PARQUET', compression='SNAPPY', overwrite=true
    ) AS SELECT * FROM `stock-trading-498512.events.%s`
  """, rec.table_name, CAST(CURRENT_DATE('America/Denver') AS STRING), rec.table_name);
END FOR;

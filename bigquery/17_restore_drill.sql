-- Backup RESTORE-drill procedure (DR verification). Project: stock-trading-498512.
-- A backup you have never restored is a hope, not a backup. scheduled_queries/backup_events_export.sql
-- writes daily Parquet to gs://stock-trading-backups and logs an ops.backup_log marker (16); this
-- procedure proves those snapshots actually LOAD BACK: it loads the latest logged snapshot of every
-- events.* base table into the events_restore_drill scratch dataset, sanity-checks restored row counts
-- against live, and RAISEs (+ alert) on any table that fails to restore / restores empty (when live is
-- non-empty) / restores MORE rows than live (append-only only grows -> corruption signal).
--
-- LEAST PRIVILEGE (2026-06-22): the drill loads into a PRE-CREATED scratch dataset and does NOT
-- create/drop it, so the scheduled-query identity (bq-scheduler@) needs only:
--   * roles/storage.objectViewer on gs://stock-trading-backups (read the backups), and
--   * roles/bigquery.dataEditor on the events_restore_drill dataset ONLY (load the scratch tables).
-- It deliberately does NOT need project-level dataEditor — bq-scheduler@ must never get write on the
-- append-only events.* source of truth. One-time setup (idempotent; already applied 2026-06-22):
--   CREATE SCHEMA IF NOT EXISTS `stock-trading-498512.events_restore_drill` OPTIONS(location='US');
--   GRANT `roles/bigquery.dataEditor` ON SCHEMA `stock-trading-498512.events_restore_drill`
--     TO "serviceAccount:bq-scheduler@stock-trading-498512.iam.gserviceaccount.com";
-- The bucket grant is GCS IAM (not SQL) — granted in the console (ops/RUNBOOK.md §3). Scratch tables
-- persist between runs (overwritten each run) by design, so no dataset-delete permission is needed.
--
-- Depends on 10_observability.sql (ops.sp_raise_alert_once) + 16_automation_health.sql (ops.backup_log)
-- + the pre-created events_restore_drill dataset. Idempotent (OR REPLACE). Apply after 16 via the
-- BigQuery MCP execute_sql. Validated end-to-end 2026-06-22: all 12 events.* tables restored from the
-- dt=2026-06-21 snapshot at exact row-count parity.
--
-- SELF-BOOTSTRAPPING: the drill date is read from ops.backup_log (the success marker), so before the
-- updated backup query has logged a marker the procedure RETURNs immediately (a no-op) — it never
-- false-fails on a missing snapshot.
--
-- SCHEDULE IT: scheduled_queries/restore_drill.sql CALLs this, monthly. Ad-hoc shell equivalent:
-- scripts/restore_drill.sh.

CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_restore_drill`()
BEGIN
  DECLARE drill_date DATE;
  DECLARE failed STRING DEFAULT '';
  DECLARE tested INT64 DEFAULT 0;
  DECLARE restored INT64 DEFAULT 0;
  DECLARE live INT64 DEFAULT 0;

  SET drill_date = (SELECT MAX(run_date) FROM `stock-trading-498512.ops.backup_log`);
  IF drill_date IS NULL THEN
    RETURN;  -- self-bootstrapping: no backup marker yet, nothing to verify
  END IF;

  FOR rec IN (
    SELECT table_name FROM `stock-trading-498512.events.INFORMATION_SCHEMA.TABLES`
    WHERE table_type = 'BASE TABLE' ORDER BY table_name
  ) DO
    BEGIN
      -- LOAD DATA OVERWRITE creates/replaces the scratch table; needs only dataEditor on the scratch dataset.
      EXECUTE IMMEDIATE FORMAT(
        "LOAD DATA OVERWRITE `stock-trading-498512.events_restore_drill.%s` FROM FILES (format='PARQUET', uris=['gs://stock-trading-backups/events/%s/dt=%s/*.parquet'])",
        rec.table_name, rec.table_name, CAST(drill_date AS STRING));
      EXECUTE IMMEDIATE FORMAT("SELECT COUNT(*) FROM `stock-trading-498512.events_restore_drill.%s`", rec.table_name) INTO restored;
      EXECUTE IMMEDIATE FORMAT("SELECT COUNT(*) FROM `stock-trading-498512.events.%s`", rec.table_name) INTO live;
      SET tested = tested + 1;
      -- a past snapshot must restore, must never EXCEED live (append-only only grows), and must be
      -- non-empty UNLESS the live table is itself empty (a genuinely-empty table restoring to 0 is fine).
      IF (restored = 0 AND live > 0) OR restored > live THEN
        SET failed = failed || FORMAT('%s(restored=%d,live=%d); ', rec.table_name, restored, live);
      END IF;
    EXCEPTION WHEN ERROR THEN
      SET failed = failed || FORMAT('%s(%s); ', rec.table_name, @@error.message);
    END;
  END FOR;

  IF failed != '' THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.restore_drill', 'restore_drill',
      CONCAT('Backup restore drill FAILED for dt=', CAST(drill_date AS STRING), ': ', failed),
      TO_JSON_STRING(STRUCT(CAST(drill_date AS STRING) AS drill_date, tested AS tables_tested, failed AS failures)));
    RAISE USING MESSAGE = CONCAT('STOCK-TRADING restore drill FAILED (dt=', CAST(drill_date AS STRING), '): ', failed);
  END IF;
END;

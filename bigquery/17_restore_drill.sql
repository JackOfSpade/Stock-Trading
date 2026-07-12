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
--
-- 2026-06-28 stack review #2 additions (#4 + #13):
--   * LIVENESS — the drill now writes an ops.drill_log marker on EVERY completion (pass AND fail), so a
--     silently-paused monthly drill is itself detectable (state.restore_health; cadence_check warning). A
--     drill that writes nothing on success is invisible: you believe DR is verified monthly when it has not
--     run in months. (Asymmetric with state.backup_health until now.)
--   * TYPED-RESTORE FIDELITY (record-only WARNING) — the count-only loop proves data PRESENCE but a
--     Parquet-inferred LOAD drops NOT NULL/partition/cluster and can coerce NUMERIC→FLOAT. One representative
--     table per run is restored into a CANONICAL-SCHEMA typed table (CREATE TABLE LIKE the live table, then
--     re-parse stringified JSON) to prove the backup fits the real schema, not just the inferred one. A
--     mismatch raises a 'warning' (NOT the critical RAISE) — staged-rollout discipline, so a fidelity
--     heuristic can never storm the critical DR channel.

-- ===== ops.drill_log — one row per restore-drill completion (liveness marker) =====
CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.drill_log` (
  drill_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  drill_date DATE NOT NULL,          -- the events snapshot date the drill verified
  tables_tested INT64,
  all_passed BOOL,                   -- count-fidelity result (the critical check)
  fidelity_ok BOOL,                  -- typed-restore fidelity result (record-only)
  note STRING
) PARTITION BY drill_date
OPTIONS(description='One row per ops.sp_restore_drill() completion (success AND failure). Source for state.restore_health — catches a silently-paused monthly restore drill the backup-side markers cannot see.');

CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_restore_drill`()
BEGIN
  DECLARE drill_date DATE;
  DECLARE failed STRING DEFAULT '';
  DECLARE fidelity_failed STRING DEFAULT '';   -- typed-restore fidelity issues (record-only WARNING, NOT the RAISE)
  DECLARE tested INT64 DEFAULT 0;
  DECLARE restored INT64 DEFAULT 0;
  DECLARE live INT64 DEFAULT 0;
  DECLARE typed_rows INT64;
  DECLARE typed_live INT64;
  DECLARE fidelity_table STRING DEFAULT 'trade_fills';  -- representative: NUMERIC (price/commission) + JSON (raw)
  DECLARE json_replace STRING;

  -- Pin the drill to the EVENTS snapshot (COALESCE handles pre-2026-06-28 NULL-dataset rows). Without this
  -- the new ops.* backup markers (dataset='ops', ops_export.sql) could shift the drill date to a day that
  -- has an ops snapshot but not yet an events one.
  SET drill_date = (
    SELECT MAX(run_date) FROM `stock-trading-498512.ops.backup_log`
    WHERE COALESCE(dataset, 'events') = 'events'
  );
  IF drill_date IS NULL THEN
    RETURN;  -- self-bootstrapping: no events backup marker yet, nothing to verify
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
      -- a past snapshot must restore, must never be EMPTY unless the live table itself is empty (a
      -- genuinely-empty table restoring to 0 is fine). The "must never EXCEED live" growth check only
      -- applies to the IMMUTABLE AUDIT-TRUTH tables (same watch-list as state.append_only_integrity,
      -- bigquery/18_stack_review_fixes.sql) — reference/market-data feeds (daily_marks, option_marks,
      -- market_holidays, macro_fred, macro_series, ...) are legitimately maintained by in-place
      -- DELETE+re-insert/MERGE, so a net-reducing re-ingest there is expected, not corruption (adversarial
      -- self-audit fix, rev 2026-07-11 — the un-scoped version raised a false CRITICAL DR alarm on those).
      IF (restored = 0 AND live > 0)
         OR (restored > live AND rec.table_name IN
             ('decision_log', 'position_events', 'trade_fills', 'regime_events',
              'queue_events', 'adversarial_reviews', 'parking_events', 'hf_capability_captures')) THEN
        SET failed = failed || FORMAT('%s(restored=%d,live=%d); ', rec.table_name, restored, live);
      END IF;
    EXCEPTION WHEN ERROR THEN
      SET failed = failed || FORMAT('%s(%s); ', rec.table_name, @@error.message);
    END;
  END FOR;

  -- ---- Typed-restore fidelity (one representative table, record-only WARNING; #13) ----
  -- Prove the backup fits the CANONICAL schema, not just the Parquet-inferred one: build a typed table via
  -- CREATE TABLE LIKE the live table (carries NOT NULL / partition / cluster / NUMERIC types), then INSERT
  -- the inferred restore re-parsing stringified JSON. If the inferred data does NOT fit the canonical schema
  -- (NUMERIC coerced to FLOAT, a NULL in a NOT NULL column, JSON unparseable), the INSERT or the row-count
  -- assert fails -> fidelity_failed, which becomes a 'warning' (never the critical RAISE). Wrapped so it can
  -- never make the drill worse than the proven count-only check.
  BEGIN
    SET json_replace = (
      SELECT IF(COUNT(*) = 0, '',
                CONCAT(' REPLACE(',
                       STRING_AGG(FORMAT('SAFE.PARSE_JSON(`%s`) AS `%s`', column_name, column_name), ', '),
                       ')'))
      FROM `stock-trading-498512.events.INFORMATION_SCHEMA.COLUMNS`
      WHERE table_name = fidelity_table AND data_type = 'JSON'
    );
    EXECUTE IMMEDIATE FORMAT(
      "CREATE OR REPLACE TABLE `stock-trading-498512.events_restore_drill.%s__typed` LIKE `stock-trading-498512.events.%s`",
      fidelity_table, fidelity_table);
    EXECUTE IMMEDIATE FORMAT(
      "INSERT INTO `stock-trading-498512.events_restore_drill.%s__typed` SELECT *%s FROM `stock-trading-498512.events_restore_drill.%s`",
      fidelity_table, json_replace, fidelity_table);
    EXECUTE IMMEDIATE FORMAT("SELECT COUNT(*) FROM `stock-trading-498512.events_restore_drill.%s__typed`", fidelity_table) INTO typed_rows;
    EXECUTE IMMEDIATE FORMAT("SELECT COUNT(*) FROM `stock-trading-498512.events_restore_drill.%s`", fidelity_table) INTO typed_live;
    IF typed_rows != typed_live THEN
      SET fidelity_failed = FORMAT('%s: typed-restore row mismatch (typed=%d, inferred=%d)', fidelity_table, typed_rows, typed_live);
    END IF;
  EXCEPTION WHEN ERROR THEN
    SET fidelity_failed = FORMAT('%s: typed restore failed — backup does not fit canonical schema (%s)', fidelity_table, @@error.message);
  END;

  -- LIVENESS marker on EVERY completion (pass AND fail), written BEFORE any RAISE so a failing drill is
  -- still recorded as having RUN (state.restore_health watches this — catches a silently-paused drill).
  INSERT INTO `stock-trading-498512.ops.drill_log` (drill_date, tables_tested, all_passed, fidelity_ok, note)
  VALUES (drill_date, tested, failed = '', fidelity_failed = '',
          CASE WHEN failed = '' AND fidelity_failed = '' THEN 'restore drill OK'
               ELSE TRIM(CONCAT(IF(failed = '', '', CONCAT('COUNT FAIL: ', failed)), ' ',
                                IF(fidelity_failed = '', '', CONCAT('FIDELITY: ', fidelity_failed)))) END);

  -- Typed-restore fidelity issue: record-only WARNING (delivered by the emailer/relay; never the critical RAISE).
  IF fidelity_failed != '' THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.restore_drill', 'restore_fidelity',
      CONCAT('Restore-drill typed-fidelity warning for dt=', CAST(drill_date AS STRING), ': ', fidelity_failed),
      TO_JSON_STRING(STRUCT(CAST(drill_date AS STRING) AS drill_date, fidelity_failed AS fidelity)));
  END IF;

  IF failed != '' THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.restore_drill', 'restore_drill',
      CONCAT('Backup restore drill FAILED for dt=', CAST(drill_date AS STRING), ': ', failed),
      TO_JSON_STRING(STRUCT(CAST(drill_date AS STRING) AS drill_date, tested AS tables_tested, failed AS failures)));
    RAISE USING MESSAGE = CONCAT('STOCK-TRADING restore drill FAILED (dt=', CAST(drill_date AS STRING), '): ', failed);
  END IF;
END;

-- ===== state.restore_health — has the monthly restore drill run recently + did it pass? =====
-- 2026-06-28 stack review #2 (#4). The restore drill writes nothing on a clean run, so a silently-paused
-- monthly schedule leaves you believing DR is verified when it has not run in months. This reads
-- ops.drill_log: stale = the last drill completed > ~40 days ago (monthly + slack) OR the most recent drill
-- did not pass its count check. Self-bootstrapping (monitored only once a drill has logged). cadence_check
-- RAISEs on stale; a Cloud Monitoring absence policy (monitoring.tf) additionally catches a dead scheduler.
CREATE OR REPLACE VIEW `stock-trading-498512.state.restore_health` AS
WITH latest AS (
  SELECT drill_date, drill_ts, all_passed, fidelity_ok
  FROM `stock-trading-498512.ops.drill_log`
  QUALIFY ROW_NUMBER() OVER (ORDER BY drill_ts DESC) = 1
),
-- Aggregate the (0-or-1-row) latest into a guaranteed single row (NULLs when no drill has logged),
-- mirroring state.backup_health — robust without relying on FULL JOIN semantics.
d AS (
  SELECT MAX(drill_date) AS last_drill_date, MAX(drill_ts) AS last_drill_ts,
         ANY_VALUE(all_passed) AS last_drill_passed, ANY_VALUE(fidelity_ok) AS last_drill_fidelity_ok
  FROM latest
),
td AS (SELECT today FROM `stock-trading-498512.state.trading_day_today`)
SELECT
  d.last_drill_date,
  d.last_drill_ts,
  d.last_drill_passed,
  d.last_drill_fidelity_ok,
  td.today,
  (d.last_drill_date IS NOT NULL) AS monitored,
  COALESCE(d.last_drill_date IS NOT NULL
           AND (d.last_drill_date < DATE_SUB(td.today, INTERVAL 40 DAY) OR NOT d.last_drill_passed), FALSE) AS stale,
  CURRENT_TIMESTAMP() AS checked_at
FROM d, td;

-- ===== 279: state.backup_per_table_health -- a table that expires its own rows is not append-only =====
-- Project: stock-trading-498512. Apply after 278. ONE statement: CREATE OR REPLACE VIEW
-- state.backup_per_table_health. SUPERSEDES the definition in bigquery/65_backup_per_table_health.sql.
-- (2026-11-17, interactive triage of backup_per_table_row_drop, ops.alerts 1ef79974.)
--
-- ===== THE DEFECT =====
-- bigquery/65 flags any day-over-day row-count drop, on the premise that every backed-up table is
-- append-only. The ops export (bigquery/75) backs up EVERY base table in the dataset, and since
-- bigquery/271 (2026-10-29) that includes ops.decision_call_parts: a staging table created with
-- partition_expiration_days=14, so BigQuery itself deletes each day's partition two weeks later.
-- MEASURED 2026-11-17: 38 -> 36 rows (2026-11-14 -> 2026-11-15) and 36 -> 31 (-> 2026-11-16) while
-- new parts were still being staged, and the oldest surviving staged_ts partition is 2026-11-04,
-- the edge of the 14-day window. The warning would have re-fired for as long as D1 keeps staging split calls.
--
-- ===== THE FIX =====
-- A table that carries a row-expiry option (partition_expiration_days, or a table-level
-- expiration_timestamp) is reported with ttl_exempt = TRUE and never sets row_count_dropped. The
-- exemption is read from INFORMATION_SCHEMA.TABLE_OPTIONS, never from a name list, so it follows
-- the table's own declared lifecycle. MEASURED 2026-11-17: decision_call_parts is the only table
-- in ops or events with either option, so no other table's verdict moves.
--
-- ===== BLAST RADIUS =====
-- Output columns are 65's plus ttl_exempt (inserted before checked_at). The one reader,
-- ops.sp_cadence_check's backup_per_table_row_drop block (bigquery/241), selects columns by name
-- and filters on row_count_dropped, so it needs no change.
CREATE OR REPLACE VIEW `stock-trading-498512.state.backup_per_table_health` AS
WITH ranked AS (
  SELECT COALESCE(dataset, 'events') AS dataset, run_date, per_table_rows,
    ROW_NUMBER() OVER (PARTITION BY COALESCE(dataset, 'events') ORDER BY run_date DESC) AS rn
  FROM `stock-trading-498512.ops.backup_log`
  WHERE per_table_rows IS NOT NULL
),
latest AS (SELECT dataset, run_date, per_table_rows FROM ranked WHERE rn = 1),
prior AS (SELECT dataset, run_date, per_table_rows FROM ranked WHERE rn = 2),
unnested_latest AS (
  SELECT l.dataset, l.run_date AS latest_run_date, k AS table_name,
    INT64(l.per_table_rows[k]) AS latest_rows
  FROM latest l, UNNEST(JSON_KEYS(l.per_table_rows)) AS k
),
unnested_prior AS (
  SELECT p.dataset, p.run_date AS prior_run_date, k AS table_name,
    INT64(p.per_table_rows[k]) AS prior_rows
  FROM prior p, UNNEST(JSON_KEYS(p.per_table_rows)) AS k
),
ttl_tables AS (
  SELECT DISTINCT table_schema AS dataset, table_name
  FROM `stock-trading-498512.ops.INFORMATION_SCHEMA.TABLE_OPTIONS`
  WHERE option_name IN ('partition_expiration_days', 'expiration_timestamp')
  UNION DISTINCT
  SELECT DISTINCT table_schema AS dataset, table_name
  FROM `stock-trading-498512.events.INFORMATION_SCHEMA.TABLE_OPTIONS`
  WHERE option_name IN ('partition_expiration_days', 'expiration_timestamp')
)
SELECT
  ul.dataset, ul.table_name, ul.latest_run_date, ul.latest_rows,
  up.prior_run_date, up.prior_rows,
  (up.prior_rows IS NOT NULL AND ul.latest_rows < up.prior_rows AND tt.table_name IS NULL) AS row_count_dropped,
  (tt.table_name IS NOT NULL) AS ttl_exempt,
  CURRENT_TIMESTAMP() AS checked_at
FROM unnested_latest ul
LEFT JOIN unnested_prior up ON up.dataset = ul.dataset AND up.table_name = ul.table_name
LEFT JOIN ttl_tables tt ON tt.dataset = ul.dataset AND tt.table_name = ul.table_name;

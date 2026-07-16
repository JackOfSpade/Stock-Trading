-- Backup per-table row-count health (self-improvement audit 2026-07-15 — CONFIRMED GAP
-- backup-per-table-rows-write-only). Project: stock-trading-498512. Apply after
-- 18_stack_review_fixes.sql (adds ops.backup_log.per_table_rows), 16_automation_health.sql.
--
-- WHY: RUNBOOK §25 B2 added `ops.backup_log.per_table_rows` (a {table: rows} JSON map) specifically so
-- a stalled/shrinking per-table export is "auditable day-over-day." It is INSERTed by
-- backup_events_export.sql and ops_export.sql but was never SELECTed by any view, procedure, or
-- scheduled query — the existing backup-staleness monitors (state.backup_health / state.ops_backup_health)
-- only check whether *a* backup marker landed recently, not whether any INDIVIDUAL table's row count
-- failed to grow or, worse, DROPPED (every table backed up here is append-only by design — this
-- repo's own repeated theme — so a row-count drop can only mean an out-of-band deletion or a backup
-- query regression, never legitimate activity).
--
-- ===== state.backup_per_table_health — day-over-day per-table row-count comparison =====
-- Compares the two MOST RECENT logged per_table_rows snapshots per (dataset, table). A brand-new
-- table, a flat count, or a growing count never fires; only a genuine DROP does. Self-bootstrapping:
-- a table with no prior snapshot to compare against (prior_rows IS NULL) never flags — there is
-- nothing to compare, not a finding.
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
)
SELECT
  ul.dataset, ul.table_name, ul.latest_run_date, ul.latest_rows,
  up.prior_run_date, up.prior_rows,
  (up.prior_rows IS NOT NULL AND ul.latest_rows < up.prior_rows) AS row_count_dropped,
  CURRENT_TIMESTAMP() AS checked_at
FROM unnested_latest ul
LEFT JOIN unnested_prior up ON up.dataset = ul.dataset AND up.table_name = ul.table_name;

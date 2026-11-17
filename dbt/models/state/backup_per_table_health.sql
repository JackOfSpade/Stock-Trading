-- Parallel-run dbt port of bigquery/279_backup_row_drop_ttl_exempt.sql:state.backup_per_table_health — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
WITH ranked AS (
  SELECT COALESCE(dataset, 'events') AS dataset, run_date, per_table_rows,
    ROW_NUMBER() OVER (PARTITION BY COALESCE(dataset, 'events') ORDER BY run_date DESC) AS rn
  FROM {{ source('ops', 'backup_log') }}
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
LEFT JOIN ttl_tables tt ON tt.dataset = ul.dataset AND tt.table_name = ul.table_name

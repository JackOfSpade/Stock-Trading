-- Stack-review fixes #2 (2026-06-28). Project: stock-trading-498512.
-- Additive, idempotent. Implements the genuinely-new deltas from the 2026-06-28 workflow/storage/automation
-- review that don't belong inside an existing file. Apply via the BigQuery MCP execute_sql AFTER 09/10/12/
-- 15/16/17/18, and BEFORE re-pasting scheduled_queries/cadence_check.sql (which now also reads
-- state.ddl_drift / state.restore_health / state.ops_backup_health).
--
-- Contents:
--   #7  state.ddl_drift — live events.* base-table STRUCTURE vs the canonical bigquery/01_schema.sql spec
--
-- (The other 2026-06-28 objects live in their cohesive home files: state.ops_backup_health in 16,
--  ops.drill_log + state.restore_health in 17, the generalized state.stalled_runs in 18.)

-- ============================================================================
-- #7 — state.ddl_drift (base-table DDL drift detector).
-- The project already closed drift SPOFs for VIEW LOGIC (dbt-parity CI), out-of-band DML
-- (state.append_only_integrity), and TRIGGERS (state.instruction_drift) — but left BASE-TABLE STRUCTURE
-- undetected. Out-of-band ALTER via console/MCP IS the operating model (10_observability.sql ships a live
-- ALTER ADD COLUMN; 16/18/this file do too), and the canonical spec is idempotent CREATE ... IF NOT EXISTS,
-- which will NOT re-assert a drifted constraint on an existing table. So a silently-dropped NOT NULL, a
-- changed partition/cluster key, or a coerced column TYPE on an immutable audit table would go unseen — the
-- dbt not_null/unique DATA tests cannot catch nullability-without-null-rows, type, or partition/cluster.
--
-- This diffs the LIVE structure (INFORMATION_SCHEMA.COLUMNS) against a hand-encoded EXPECTED spec derived
-- from bigquery/01_schema.sql, for the 8 IMMUTABLE AUDIT tables (same scope as append_only_integrity).
-- It checks the load-bearing, structurally-significant columns: declared NOT NULL, the partition column,
-- the clustering columns (+ ordinal), and the type of each. Empty result = no drift.
--
-- MAINTENANCE: the `expected` UNNEST below is the canonical spec mirror — keep it in sync with
-- bigquery/01_schema.sql whenever a watched audit table's NOT NULL / PARTITION BY / CLUSTER BY / column
-- type changes (a deliberate change updates BOTH this list and 01_schema; an UNINTENDED live change is
-- exactly what this view should then flag). Reference/market-data feeds (market_holidays, daily_marks,
-- macro_*) are deliberately OUT of scope — they are maintained in place by design.
--
-- POSTURE — STAGED ROLLOUT (record-only WARNING, NO RAISE; like append_only_integrity / position_drift).
-- cadence_check.sql records a deduped 'warning' (delivered by the emailer/relay) but does NOT flip all_green
-- or storm the DTS email. VERIFY the baseline is clean (0 rows) after applying before relying on it; promote
-- to critical+RAISE only once a clean baseline holds (and consider whether is_partitioning_column reporting
-- for the DATE(timestamp) partitions matches the spec on your BigQuery — adjust the spec if a benign diff
-- shows up at baseline).
CREATE OR REPLACE VIEW `stock-trading-498512.state.ddl_drift` AS
WITH expected AS (
  -- (table, column, expected type, NOT NULL?, partition col?, clustering ordinal or NULL)
  SELECT * FROM UNNEST([
    -- decision_log: PARTITION BY entry_date; CLUSTER BY strategy, entry_type, ticker
    STRUCT('decision_log' AS table_name, 'entry_date' AS column_name, 'DATE'      AS data_type, TRUE  AS not_null, TRUE  AS is_partition, CAST(NULL AS INT64) AS cluster_pos),
    STRUCT('decision_log', 'entry_type', 'STRING', TRUE,  FALSE, 2),
    STRUCT('decision_log', 'strategy',   'STRING', FALSE, FALSE, 1),
    STRUCT('decision_log', 'ticker',     'STRING', FALSE, FALSE, 3),
    -- trade_fills: PARTITION BY DATE(fill_ts); CLUSTER BY strategy, ticker
    STRUCT('trade_fills', 'trade_id', 'STRING',    TRUE,  FALSE, CAST(NULL AS INT64)),
    STRUCT('trade_fills', 'fill_ts',  'TIMESTAMP', FALSE, TRUE,  CAST(NULL AS INT64)),
    STRUCT('trade_fills', 'strategy', 'STRING',    FALSE, FALSE, 1),
    STRUCT('trade_fills', 'ticker',   'STRING',    FALSE, FALSE, 2),
    -- position_events: PARTITION BY DATE(event_ts); CLUSTER BY strategy, ticker, event_type
    STRUCT('position_events', 'position_key', 'STRING',    TRUE,  FALSE, CAST(NULL AS INT64)),
    STRUCT('position_events', 'event_type',   'STRING',    TRUE,  FALSE, 3),
    STRUCT('position_events', 'event_ts',     'TIMESTAMP', FALSE, TRUE,  CAST(NULL AS INT64)),
    STRUCT('position_events', 'strategy',     'STRING',    FALSE, FALSE, 1),
    STRUCT('position_events', 'ticker',       'STRING',    FALSE, FALSE, 2),
    -- regime_events: PARTITION BY as_of_date; CLUSTER BY scope, key
    STRUCT('regime_events', 'as_of_date', 'DATE',   TRUE, TRUE,  CAST(NULL AS INT64)),
    STRUCT('regime_events', 'scope',      'STRING', TRUE, FALSE, 1),
    STRUCT('regime_events', 'key',        'STRING', TRUE, FALSE, 2),
    -- queue_events: PARTITION BY DATE(event_ts); CLUSTER BY queue, status
    STRUCT('queue_events', 'queue',    'STRING',    TRUE, FALSE, 1),
    STRUCT('queue_events', 'item_key', 'STRING',    TRUE, FALSE, CAST(NULL AS INT64)),
    STRUCT('queue_events', 'status',   'STRING',    TRUE, FALSE, 2),
    STRUCT('queue_events', 'event_ts', 'TIMESTAMP', FALSE, TRUE, CAST(NULL AS INT64)),
    -- adversarial_reviews: PARTITION BY review_date; CLUSTER BY review_type, strategy
    STRUCT('adversarial_reviews', 'review_id',   'STRING', TRUE,  FALSE, CAST(NULL AS INT64)),
    STRUCT('adversarial_reviews', 'review_date', 'DATE',   FALSE, TRUE,  CAST(NULL AS INT64)),
    STRUCT('adversarial_reviews', 'review_type', 'STRING', FALSE, FALSE, 1),
    STRUCT('adversarial_reviews', 'strategy',    'STRING', FALSE, FALSE, 2),
    -- parking_events: PARTITION BY action_date; CLUSTER BY strategy, action
    STRUCT('parking_events', 'action_date', 'DATE',   TRUE,  TRUE,  CAST(NULL AS INT64)),
    STRUCT('parking_events', 'strategy',    'STRING', FALSE, FALSE, 1),
    STRUCT('parking_events', 'action',      'STRING', FALSE, FALSE, 2),
    -- hf_capability_captures: PARTITION BY capture_date; no clustering
    STRUCT('hf_capability_captures', 'capture_date', 'DATE', TRUE, TRUE, CAST(NULL AS INT64))
  ])
),
live AS (
  SELECT table_name, column_name, data_type, is_nullable, is_partitioning_column, clustering_ordinal_position
  FROM `stock-trading-498512.events.INFORMATION_SCHEMA.COLUMNS`
  WHERE table_name IN ('decision_log','trade_fills','position_events','regime_events',
                       'queue_events','adversarial_reviews','parking_events','hf_capability_captures')
)
SELECT * FROM (
  SELECT
    e.table_name,
    e.column_name,
    ARRAY_TO_STRING([
      IF(l.column_name IS NULL, 'COLUMN MISSING', NULL),
      IF(l.column_name IS NOT NULL AND l.data_type != e.data_type,
         FORMAT('type %s != expected %s', l.data_type, e.data_type), NULL),
      IF(l.column_name IS NOT NULL AND e.not_null AND l.is_nullable = 'YES',
         'NOT NULL dropped', NULL),
      IF(l.column_name IS NOT NULL AND e.is_partition AND COALESCE(l.is_partitioning_column, 'NO') != 'YES',
         'partition column changed', NULL),
      IF(l.column_name IS NOT NULL AND e.cluster_pos IS NOT NULL
         AND COALESCE(l.clustering_ordinal_position, -1) != e.cluster_pos,
         FORMAT('clustering position changed (live %d, expected %d)',
                COALESCE(l.clustering_ordinal_position, -1), e.cluster_pos), NULL)
    ], '; ') AS drift_reasons,
    e.data_type   AS expected_type,
    l.data_type   AS live_type,
    e.not_null    AS expected_not_null,
    l.is_nullable AS live_is_nullable,
    CURRENT_TIMESTAMP() AS checked_at
  FROM expected e
  LEFT JOIN live l USING (table_name, column_name)
)
WHERE drift_reasons != '';

-- Parallel-run dbt port of bigquery/19_stack_review_fixes_2.sql:state.ddl_drift — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
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
WHERE drift_reasons != ''

-- Parallel-run dbt port of bigquery/01_schema.sql:state.trade_fills_curated — canonical source is that file until owner cutover.
-- Dedup view: latest ingest per trade_id. trade_fills' idempotency-by-trade_id contract
-- cannot be enforced on an append-only table; a re-ingested fill would otherwise shift
-- leg_seq pairing or create phantom positions downstream. ALL fill consumers read this view.

SELECT *
FROM {{ source('events', 'trade_fills') }}
QUALIFY ROW_NUMBER() OVER (PARTITION BY trade_id ORDER BY ingest_ts DESC) = 1

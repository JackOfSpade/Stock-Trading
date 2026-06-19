-- Parallel-run dbt port of bigquery/03_twr_engine.sql:state.daily_marks_curated — canonical source is that file until owner cutover.
-- Dedup view (latest ingest wins per ticker/day). D2's ingest contract is idempotent on
-- (mark_date, ticker), but an append-only table cannot enforce that — a re-ingested day
-- (crashed / re-run session) would create duplicate mark rows that the engine joins would
-- DOUBLE-COUNT (mv summed twice, LAG over duplicate dates), silently corrupting r_deployed
-- / r_sgov. ALL mark consumers read THIS view, never the raw table. (See the
-- unique_combination_of_columns(ticker, mark_date) test — the TWR double-count guard.)

SELECT *
FROM {{ source('events', 'daily_marks') }}
QUALIFY ROW_NUMBER() OVER (PARTITION BY ticker, mark_date ORDER BY ingest_ts DESC) = 1

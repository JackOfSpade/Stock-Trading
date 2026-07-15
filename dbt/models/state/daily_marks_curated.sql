-- Parallel-run dbt port of bigquery/53_curated_view_tiebreak_fix.sql:state.daily_marks_curated —
-- canonical source is that file until owner cutover (originally 03_twr_engine.sql; updated
-- 2026-07-14 to add the row_uid secondary tiebreaker — see 53's header for why).
-- Dedup view (latest ingest wins per ticker/day). D2's ingest contract is idempotent on
-- (mark_date, ticker), but an append-only table cannot enforce that — a re-ingested day
-- (crashed / re-run session) would create duplicate mark rows that the engine joins would
-- DOUBLE-COUNT (mv summed twice, LAG over duplicate dates), silently corrupting r_deployed
-- / r_sgov. ALL mark consumers read THIS view, never the raw table. (See the
-- unique_combination_of_columns(ticker, mark_date) test — the TWR double-count guard.)
-- row_uid disambiguates an exact ingest_ts tie (same-statement multi-row INSERT, since
-- CURRENT_TIMESTAMP() evaluates once per query) — ROW_NUMBER()'s pick among ties is otherwise
-- undefined per BigQuery's docs.

SELECT *
FROM {{ source('events', 'daily_marks') }}
QUALIFY ROW_NUMBER() OVER (PARTITION BY ticker, mark_date ORDER BY ingest_ts DESC, row_uid DESC) = 1

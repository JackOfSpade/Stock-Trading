-- Parallel-run dbt port of bigquery/40_options_marks.sql:state.option_marks_curated — canonical source is that file until owner cutover.
-- Dedup view (latest ingest wins per occ_symbol/day). Mirrors daily_marks_curated's guard exactly:
-- a re-ingested day would otherwise DOUBLE-COUNT an option position's marked value.

SELECT *
FROM {{ source('events', 'option_marks') }}
QUALIFY ROW_NUMBER() OVER (PARTITION BY occ_symbol, mark_date ORDER BY ingest_ts DESC) = 1

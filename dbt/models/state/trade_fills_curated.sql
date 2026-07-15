-- Parallel-run dbt port of bigquery/53_curated_view_tiebreak_fix.sql:state.trade_fills_curated —
-- canonical source is that file until owner cutover (originally 01_schema.sql; updated 2026-07-14
-- to add trade_id as a secondary tiebreaker, defense-in-depth alongside daily_marks_curated's
-- row_uid fix — see 53's header).
-- Dedup view: latest ingest per trade_id. trade_fills' idempotency-by-trade_id contract
-- cannot be enforced on an append-only table; a re-ingested fill would otherwise shift
-- leg_seq pairing or create phantom positions downstream. ALL fill consumers read this view.

SELECT *
FROM {{ source('events', 'trade_fills') }}
QUALIFY ROW_NUMBER() OVER (PARTITION BY trade_id ORDER BY ingest_ts DESC, trade_id DESC) = 1

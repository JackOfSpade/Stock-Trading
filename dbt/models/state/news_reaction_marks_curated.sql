-- Parallel-run dbt port of bigquery/261_news_reaction_paper_book.sql:state.news_reaction_marks_curated — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
SELECT * FROM {{ source('events', 'news_reaction_marks') }}
QUALIFY ROW_NUMBER() OVER (PARTITION BY ticker, mark_date ORDER BY ingest_ts DESC, row_uid DESC) = 1

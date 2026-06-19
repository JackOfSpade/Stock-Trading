-- Singular test (passes when ZERO rows): the curated marks view must collapse every duplicate
-- (ticker, mark_date) so the TWR engine cannot double-count a re-ingested day.
--
-- Rationale (bigquery/03_twr_engine.sql state.daily_marks_curated): D2's ingest is "idempotent on
-- (mark_date, ticker)", but an append-only table can't enforce that — a crashed/re-run session can
-- append a second mark row for the same ticker/day. The engine joins would then sum mv twice and LAG
-- over duplicate dates, silently corrupting r_deployed / r_sgov (and the SGOV benchmark). The curated
-- view dedups via QUALIFY ROW_NUMBER() ORDER BY ingest_ts DESC. This test asserts the contract end to
-- end: the count of DISTINCT (ticker, mark_date) in the RAW table equals the curated row count. If
-- they differ, the dedup is not collapsing duplicates and the TWR is at double-count risk.

WITH raw_distinct AS (
  SELECT COUNT(*) AS n
  FROM (SELECT DISTINCT ticker, mark_date FROM {{ source('events', 'daily_marks') }})
),
curated AS (
  SELECT COUNT(*) AS n FROM {{ ref('daily_marks_curated') }}
)
SELECT raw_distinct.n AS raw_distinct_rows, curated.n AS curated_rows
FROM raw_distinct, curated
WHERE raw_distinct.n <> curated.n

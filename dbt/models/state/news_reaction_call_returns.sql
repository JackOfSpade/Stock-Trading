-- Parallel-run dbt port of bigquery/261_news_reaction_paper_book.sql:state.news_reaction_call_returns — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
WITH marks AS (
  SELECT
    ticker, mark_date, open_px,
    ROW_NUMBER() OVER (PARTITION BY ticker ORDER BY mark_date) AS seq
  FROM {{ ref('news_reaction_marks_curated') }}
),
spy AS (
  SELECT mark_date, open_px
  FROM {{ ref('news_reaction_marks_curated') }}
  WHERE ticker = 'SPY'
),
entry AS (
  SELECT c.call_id, MIN(m.mark_date) AS entry_date
  FROM {{ source('events', 'news_reaction_calls') }} c
  JOIN marks m
    ON m.ticker = c.ticker AND m.mark_date > c.call_date
  GROUP BY c.call_id
),
legs AS (
  SELECT
    c.*,
    e.entry_date,
    me.open_px AS entry_open,
    me.seq AS entry_seq
  FROM {{ source('events', 'news_reaction_calls') }} c
  LEFT JOIN entry e ON e.call_id = c.call_id
  LEFT JOIN marks me ON me.ticker = c.ticker AND me.mark_date = e.entry_date
),
priced AS (
  SELECT
    l.*,
    x1.mark_date AS exit_date_1d, x1.open_px AS exit_open_1d,
    x3.mark_date AS exit_date_3d, x3.open_px AS exit_open_3d,
    x5.mark_date AS exit_date_5d, x5.open_px AS exit_open_5d,
    s0.open_px AS spy_entry_open,
    s1.open_px AS spy_exit_open_1d,
    s3.open_px AS spy_exit_open_3d,
    s5.open_px AS spy_exit_open_5d
  FROM legs l
  LEFT JOIN marks x1 ON x1.ticker = l.ticker AND x1.seq = l.entry_seq + 1
  LEFT JOIN marks x3 ON x3.ticker = l.ticker AND x3.seq = l.entry_seq + 3
  LEFT JOIN marks x5 ON x5.ticker = l.ticker AND x5.seq = l.entry_seq + 5
  LEFT JOIN spy s0 ON s0.mark_date = l.entry_date
  LEFT JOIN spy s1 ON s1.mark_date = x1.mark_date
  LEFT JOIN spy s3 ON s3.mark_date = x3.mark_date
  LEFT JOIN spy s5 ON s5.mark_date = x5.mark_date
),
rets AS (
  SELECT
    p.*,
    SAFE_DIVIDE(CAST(exit_open_1d AS FLOAT64), CAST(entry_open AS FLOAT64)) - 1 AS ret_1d,
    SAFE_DIVIDE(CAST(exit_open_3d AS FLOAT64), CAST(entry_open AS FLOAT64)) - 1 AS ret_3d,
    SAFE_DIVIDE(CAST(exit_open_5d AS FLOAT64), CAST(entry_open AS FLOAT64)) - 1 AS ret_5d,
    SAFE_DIVIDE(CAST(spy_exit_open_1d AS FLOAT64), CAST(spy_entry_open AS FLOAT64)) - 1 AS spy_ret_1d,
    SAFE_DIVIDE(CAST(spy_exit_open_3d AS FLOAT64), CAST(spy_entry_open AS FLOAT64)) - 1 AS spy_ret_3d,
    SAFE_DIVIDE(CAST(spy_exit_open_5d AS FLOAT64), CAST(spy_entry_open AS FLOAT64)) - 1 AS spy_ret_5d
  FROM priced p
)
SELECT
  call_id, call_ts, call_date, lead_id, ticker, headline_hash, headline, published_ts, source, source_url,
  direction, agreement_score, k, votes_json, horizon_days, scorer_routine, scorer_session, note,
  entry_date,
  entry_open,
  CASE horizon_days WHEN 1 THEN exit_date_1d WHEN 3 THEN exit_date_3d WHEN 5 THEN exit_date_5d END AS exit_date,
  ret_1d, ret_3d, ret_5d,
  spy_ret_1d, spy_ret_3d, spy_ret_5d,
  CASE horizon_days WHEN 1 THEN ret_1d WHEN 3 THEN ret_3d WHEN 5 THEN ret_5d END AS realized_return,
  CASE horizon_days WHEN 1 THEN spy_ret_1d WHEN 3 THEN spy_ret_3d WHEN 5 THEN spy_ret_5d END AS realized_spy_return
FROM rets

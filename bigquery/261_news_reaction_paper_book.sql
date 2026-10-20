-- bigquery/261_news_reaction_paper_book.sql — NEWS-REACTION PAPER BOOK for the J research lead (2026-10-20).
-- Project: stock-trading-498512. Apply after 260_guard_waivers.sql.
--
-- WHY. SL1's 2026-10-19 UPDATED event on lead interactive-2026-10-news-reaction-confidence-gated-long-short
-- named a prospective paper book as the first step. The published edge is gated on token-probability
-- confidence the deployed model does not expose, so this book measures a different, pre-registered proxy:
-- agreement across k = 5 independent blind reads. Pre-registration record and every constant used here:
-- ops/research/news_reaction_paper_book_2026-10.md (universe, agreement gate 0.8, 1-day open-to-open
-- horizon, 20 bp round-trip cost, readiness n_realized >= 30 AND net_mu > 0). Changing any constant
-- re-opens the book. This is NOT a forward-test phase; nothing here stages an order.
--
-- SHAPE. ops.news_reaction_universe (40 UNIVERSE tickers + SPY BENCHMARK, seeded once);
-- events.news_reaction_marks (append-only Nasdaq open/close marks) read through
-- state.news_reaction_marks_curated (latest ingest per ticker/day, row_uid tiebreak);
-- events.news_reaction_calls (append-only, one row per call_date/ticker/headline_hash);
-- state.news_reaction_call_returns (open-to-open returns at 1/3/5 trading days plus SPY over the same dates);
-- state.news_reaction_paper_book_readiness (one row per lead_id, the ready flag D1 reads).
--
-- WHO WRITES. D1's NEWS-REACTION PAPER BOOK step writes events.news_reaction_marks and
-- events.news_reaction_calls. ops.news_reaction_universe is written only by this file's schema-time seed.
-- When readiness flips, D1 enqueues a PENDING_QUALIFICATION item (lane registered by bigquery/262) that
-- SL1 drains.
--
-- APPLY: live via the BigQuery MCP, after 260 and before 262, together with the generated dbt mirrors
-- (the two events tables are declared dbt sources). Every statement is re-appliable: CREATE TABLE IF NOT
-- EXISTS, CREATE OR REPLACE VIEW, and a NOT-EXISTS-guarded seed.

-- ===== ops.news_reaction_universe =====
CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.news_reaction_universe` (
  ticker      STRING NOT NULL,   -- symbol as quoted by Nasdaq
  role        STRING NOT NULL,   -- 'UNIVERSE' (scored) | 'BENCHMARK' (SPY, never scored)
  added_date  DATE   NOT NULL,   -- pre-registration date
  note        STRING
)
OPTIONS (description = 'News-reaction paper book universe (ops/research/news_reaction_paper_book_2026-10.md section 2; bigquery/261). 40 liquid US large caps with role UNIVERSE plus SPY with role BENCHMARK. Fixed at pre-registration; seeded only by the schema-time INSERT in bigquery/261. D1 reads it.');

-- Seed: the 40 pre-registered UNIVERSE tickers plus the SPY benchmark. Idempotent on ticker.
INSERT INTO `stock-trading-498512.ops.news_reaction_universe` (ticker, role, added_date, note)
SELECT r.ticker, r.role, DATE '2026-10-20', r.note
FROM UNNEST([
  STRUCT('AAPL' AS ticker, 'UNIVERSE' AS role, 'pre-registered 2026-10-20' AS note),
  STRUCT('MSFT', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('NVDA', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('AMZN', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('GOOGL', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('META', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('TSLA', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('AVGO', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('JPM', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('BAC', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('GS', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('V', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('MA', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('UNH', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('LLY', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('JNJ', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('PFE', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('MRK', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('ABBV', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('XOM', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('CVX', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('COP', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('CAT', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('DE', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('BA', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('GE', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('HON', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('UPS', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('WMT', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('COST', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('HD', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('NKE', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('MCD', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('DIS', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('NFLX', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('CRM', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('ORCL', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('AMD', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('INTC', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('QCOM', 'UNIVERSE', 'pre-registered 2026-10-20'),
  STRUCT('SPY', 'BENCHMARK', 'benchmark only, never scored')
]) AS r
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.ops.news_reaction_universe` x
  WHERE x.ticker = r.ticker
);

-- ===== events.news_reaction_marks =====
CREATE TABLE IF NOT EXISTS `stock-trading-498512.events.news_reaction_marks` (
  mark_date  DATE      NOT NULL,                                -- trading date of the bar
  ticker     STRING    NOT NULL,
  open_px    NUMERIC,                                           -- split-adjusted open
  close_px   NUMERIC,                                           -- split-adjusted close
  source     STRING    DEFAULT 'nasdaq-historical' NOT NULL,
  ingest_ts  TIMESTAMP DEFAULT CURRENT_TIMESTAMP() NOT NULL,
  row_uid    STRING    DEFAULT GENERATE_UUID() NOT NULL         -- tiebreak for an exact ingest_ts tie
)
PARTITION BY mark_date
CLUSTER BY ticker
OPTIONS (description = 'News-reaction paper book price marks (bigquery/261): daily open and close for the 40 UNIVERSE tickers plus SPY, ingested by D1 from Nasdaq historical. Append-only. Deliberately SEPARATE from events.daily_marks (the deployed-TWR engine input, held tickers only, spec-frozen) and from events.signal_marks (the park menu); neither may be widened to this universe. Consumers read state.news_reaction_marks_curated, never this raw table.');

-- ===== state.news_reaction_marks_curated =====
-- Latest ingest wins per ticker/day, row_uid secondary tiebreak -- same pattern as
-- state.signal_marks_curated (bigquery/91).
CREATE OR REPLACE VIEW `stock-trading-498512.state.news_reaction_marks_curated` AS
SELECT * FROM `stock-trading-498512.events.news_reaction_marks`
QUALIFY ROW_NUMBER() OVER (PARTITION BY ticker, mark_date ORDER BY ingest_ts DESC, row_uid DESC) = 1;

-- ===== events.news_reaction_calls =====
-- Append-only. Idempotency key is (call_date, ticker, headline_hash); D1 NOT-EXISTS-guards every INSERT on it.
CREATE TABLE IF NOT EXISTS `stock-trading-498512.events.news_reaction_calls` (
  call_id          STRING    DEFAULT GENERATE_UUID() NOT NULL,
  call_ts          TIMESTAMP DEFAULT CURRENT_TIMESTAMP() NOT NULL,
  call_date        DATE      NOT NULL,   -- America/Denver date of the scoring run
  lead_id          STRING    NOT NULL,   -- the research lead this book serves
  ticker           STRING    NOT NULL,
  headline_hash    STRING    NOT NULL,   -- SHA256 hex of the lower-cased, whitespace-collapsed headline
  headline         STRING    NOT NULL,
  published_ts     TIMESTAMP,
  source           STRING    NOT NULL,   -- headline feed, e.g. google-news-rss | nasdaq-rss
  source_url       STRING,
  direction        STRING    NOT NULL,   -- the modal vote: UP | DOWN | FLAT
  agreement_score  NUMERIC   NOT NULL,   -- modal share of the k votes (0.2 .. 1.0)
  k                INT64     NOT NULL,   -- number of independent blind reads (5)
  votes_json       JSON,                 -- the k raw votes
  horizon_days     INT64     NOT NULL,   -- pre-registered horizon in trading days (1)
  scorer_routine   STRING    NOT NULL,   -- 'D1'
  scorer_session   STRING,
  note             STRING
)
PARTITION BY call_date
CLUSTER BY ticker, lead_id
OPTIONS (description = 'News-reaction paper book calls (bigquery/261; ops/research/news_reaction_paper_book_2026-10.md). Append-only, one row per (call_date, ticker, headline_hash), written by D1. direction is the modal vote of k independent blind reads; agreement_score is the modal share. Read by state.news_reaction_call_returns.');

-- ===== state.news_reaction_call_returns =====
-- Plain CTEs and JOINs only: BigQuery rejects correlated subqueries that reference a joined view.
CREATE OR REPLACE VIEW `stock-trading-498512.state.news_reaction_call_returns` AS
WITH marks AS (
  SELECT
    ticker, mark_date, open_px,
    ROW_NUMBER() OVER (PARTITION BY ticker ORDER BY mark_date) AS seq
  FROM `stock-trading-498512.state.news_reaction_marks_curated`
),
spy AS (
  SELECT mark_date, open_px
  FROM `stock-trading-498512.state.news_reaction_marks_curated`
  WHERE ticker = 'SPY'
),
entry AS (
  SELECT c.call_id, MIN(m.mark_date) AS entry_date
  FROM `stock-trading-498512.events.news_reaction_calls` c
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
  FROM `stock-trading-498512.events.news_reaction_calls` c
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
FROM rets;

-- ===== state.news_reaction_paper_book_readiness =====
-- One row per lead_id. Constants are the pre-registered literals (memo section 1); changing one re-opens the book.
CREATE OR REPLACE VIEW `stock-trading-498512.state.news_reaction_paper_book_readiness` AS
WITH consts AS (
  SELECT 0.8 AS agreement_gate, 0.002 AS cost_round_trip, 30 AS n_min
),
flagged AS (
  SELECT
    r.*,
    (r.direction = 'UP' AND CAST(r.agreement_score AS FLOAT64) >= cst.agreement_gate) AS long_gated,
    (r.direction = 'DOWN' AND CAST(r.agreement_score AS FLOAT64) >= cst.agreement_gate) AS short_gated
  FROM `stock-trading-498512.state.news_reaction_call_returns` r
  CROSS JOIN consts cst
),
agg AS (
  SELECT
    lead_id,
    MAX(horizon_days) AS horizon_days,
    COUNT(*) AS n_calls_total,
    COUNTIF(long_gated) AS n_long_gated,
    COUNTIF(long_gated AND realized_return IS NOT NULL) AS n_realized,
    AVG(IF(long_gated, realized_return, NULL)) AS gross_mu,
    AVG(IF(long_gated, realized_return - realized_spy_return, NULL)) AS excess_vs_spy_mu,
    SAFE_DIVIDE(COUNTIF(long_gated AND realized_return > 0),
                COUNTIF(long_gated AND realized_return IS NOT NULL)) AS hit_rate,
    COUNTIF(short_gated) AS n_short_gated,
    AVG(IF(short_gated, realized_return, NULL)) AS short_gross_mu,
    MIN(call_date) AS first_call_date,
    MAX(call_date) AS last_call_date
  FROM flagged
  GROUP BY lead_id
)
SELECT
  a.lead_id,
  cst.agreement_gate,
  cst.cost_round_trip,
  cst.n_min,
  a.horizon_days,
  a.n_calls_total,
  a.n_long_gated,
  a.n_realized,
  a.gross_mu,
  a.gross_mu - cst.cost_round_trip AS net_mu,
  a.excess_vs_spy_mu,
  a.hit_rate,
  a.n_short_gated,
  a.short_gross_mu,
  a.first_call_date,
  a.last_call_date,
  DATE_DIFF(CURRENT_DATE('America/Denver'), a.last_call_date, DAY) AS days_since_last_call,
  COALESCE(a.n_realized >= cst.n_min AND (a.gross_mu - cst.cost_round_trip) > 0, FALSE) AS ready
FROM agg a
CROSS JOIN consts cst;

-- VERIFICATION (run after apply; read-only).
-- SELECT role, COUNT(*) FROM `stock-trading-498512.ops.news_reaction_universe` GROUP BY role;
--   -- expect UNIVERSE 40, BENCHMARK 1.
-- SELECT * FROM `stock-trading-498512.state.news_reaction_paper_book_readiness`;
--   -- zero rows until D1 writes its first call; ready is never NULL once a row exists.
-- NOTE: double-dash line comments only. A trailing C-style block comment after the last statement
-- causes permanent live-sql-parity drift -- never introduce one here.

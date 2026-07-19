-- Parallel-run dbt port of bigquery/93_park_accounting.sql:analytics.park_nav_daily — canonical
-- source is that file until owner cutover. The park's own daily-chained NAV/TWR, vehicle-
-- generalized across the 12-ticker AI Park Allocator menu (PARK_ROUTER_DESIGN.md v2 §9).
--
-- close/dividend for each ever-held park ticker prefer {{ ref('daily_marks_curated') }} over the
-- new signal_marks_curated view (SGOV/VOO/SPY already live in daily_marks_curated; the other menu
-- tickers live only in signal_marks_curated until/unless a strategy ever trades one directly) — a
-- src_priority pick, not a scalar COALESCE, so dividend travels with whichever source's close won.
-- state.signal_marks_curated is declared as a state_external source (dbt does not yet own it — see
-- sources.yml) — it is bigquery/91_park_signal_layer.sql's curated view, out of scope for this
-- dbt-port pass, same as state.park_rule_shadow below in park_counterfactuals.sql.

WITH held_tickers AS (
  SELECT DISTINCT ticker
  FROM {{ source('events', 'parking_events') }}
  WHERE ticker IS NOT NULL
),

combined_marks AS (
  SELECT ticker, mark_date, close, COALESCE(dividend, 0) AS dividend, 1 AS src_priority
  FROM {{ ref('daily_marks_curated') }}
  UNION ALL
  SELECT ticker, mark_date, close, COALESCE(dividend, 0) AS dividend, 2 AS src_priority
  FROM {{ source('state_external', 'signal_marks_curated') }}
),
marks AS (
  SELECT cm.ticker, cm.mark_date, cm.close, cm.dividend
  FROM combined_marks cm
  JOIN held_tickers h USING (ticker)
  QUALIFY ROW_NUMBER() OVER (PARTITION BY cm.ticker, cm.mark_date ORDER BY cm.src_priority) = 1
),

-- Date axis: every date on which at least one ever-held park ticker has a mark, from the SGOV
-- founding date forward — deliberately NOT "every calendar trading day" (matches the
-- voo_cumulative/sgov_cumulative precedent of an axis derived from real rows, never a generated
-- calendar).
axis AS (
  SELECT DISTINCT mark_date AS as_of_date
  FROM marks
  WHERE mark_date >= DATE '2026-04-17'
),

-- Signed per-ticker share delta per (ticker, action_date) — BUY/DIVIDEND_REINVEST/RECON_ADJUST(+),
-- SELL(-), the same CASE as state.park_position (bigquery/54), grouped by day so a switch's same-day
-- SELL-old + BUY-new legs net correctly before the running total.
park_events_daily AS (
  SELECT ticker, action_date,
    SUM(CASE action
          WHEN 'BUY' THEN shares
          WHEN 'DIVIDEND_REINVEST' THEN shares
          WHEN 'RECON_ADJUST' THEN shares
          WHEN 'SELL' THEN -shares
          ELSE 0 END) AS shares_delta
  FROM {{ source('events', 'parking_events') }}
  WHERE ticker IS NOT NULL
  GROUP BY ticker, action_date
),
cum_shares AS (
  SELECT ticker, action_date,
    SUM(shares_delta) OVER (
      PARTITION BY ticker ORDER BY action_date
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS shares_cum
  FROM park_events_daily
),

-- Cumulative shares AS OF each axis date (inclusive of that date's own activity).
shares_asof AS (
  SELECT a.as_of_date, c.ticker, c.shares_cum
  FROM axis a
  JOIN cum_shares c ON c.action_date <= a.as_of_date
  QUALIFY ROW_NUMBER() OVER (PARTITION BY a.as_of_date, c.ticker ORDER BY c.action_date DESC) = 1
),

-- Shares held GOING INTO each axis date (i.e., as of the PRIOR axis date) — house TWR convention
-- (bigquery/03_twr_engine.sql): a same-day trade is a flow, not a return event.
shares_prev AS (
  SELECT as_of_date, ticker,
    COALESCE(LAG(shares_cum) OVER (PARTITION BY ticker ORDER BY as_of_date), 0) AS shares_prev
  FROM shares_asof
),

-- Per-ticker daily TOTAL return (close + dividend vs prior close), LAG'd over THAT TICKER's own
-- native mark_date sequence (not the union axis) — same convention as voo_daily_return.sql /
-- sgov_daily_return.sql, so a gap in one ticker's marks never corrupts another ticker's return.
ticker_returns AS (
  SELECT ticker, mark_date AS as_of_date,
    LAG(close) OVER (PARTITION BY ticker ORDER BY mark_date) AS prev_close,
    SAFE_DIVIDE(
      close + dividend - LAG(close) OVER (PARTITION BY ticker ORDER BY mark_date),
      LAG(close) OVER (PARTITION BY ticker ORDER BY mark_date)) AS r
  FROM marks
),

-- park_mv(t) = SUM(shares_asof(t) * close(t)) across every ticker with a same-day mark. KNOWN LIMIT
-- (documented, not an active bug, same note as the bigquery/93 original): a same-day mark gap on the
-- currently-held ticker while some OTHER ever-held ticker still has a mark that day silently drops
-- that ticker's contribution for that one day.
mv AS (
  SELECT sa.as_of_date, SUM(sa.shares_cum * m.close) AS park_mv
  FROM shares_asof sa
  JOIN marks m ON m.ticker = sa.ticker AND m.mark_date = sa.as_of_date
  GROUP BY sa.as_of_date
),

-- Value-weighted daily return across every ticker held going into the day — the same
-- "capital-weighted, compounded" combination rule deployed_book_vs_benchmarks.sql uses for its book
-- leg. GREATEST(...,-0.9999) floors a single-ticker return before it enters the weighted sum.
daily_ret AS (
  SELECT sp.as_of_date,
    SAFE_DIVIDE(
      SUM(COALESCE(sp.shares_prev, 0) * COALESCE(tr.prev_close, 0)
          * COALESCE(GREATEST(tr.r, -0.9999), 0)),
      NULLIF(SUM(COALESCE(sp.shares_prev, 0) * COALESCE(tr.prev_close, 0)), 0)
    ) AS daily_return
  FROM shares_prev sp
  LEFT JOIN ticker_returns tr ON tr.ticker = sp.ticker AND tr.as_of_date = sp.as_of_date
  GROUP BY sp.as_of_date
),

-- Policy vehicle in effect AS OF each axis date — thresholds on effective_date (not event_ts): the
-- SGOV founding row's effective_date (2026-04-17) predates its retroactive event_ts (~2026-07-15,
-- inserted by bigquery/54's cutover migration), so an event_ts-only filter would wrongly return
-- vehicle=NULL for the whole 2026-04-17..2026-07-14 window. event_ts DESC is still the tiebreak among
-- rows sharing an effective_date (bigquery/93's DEVIATION #1 note — see that file's header).
policy_asof AS (
  SELECT a.as_of_date, p.vehicle
  FROM axis a
  JOIN {{ source('events', 'park_policy_changes') }} p
    ON p.effective_date <= a.as_of_date
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY a.as_of_date ORDER BY p.effective_date DESC, p.event_ts DESC) = 1
)
SELECT
  a.as_of_date,
  pa.vehicle,
  ROUND(COALESCE(mv.park_mv, 0), 2)          AS park_mv,
  COALESCE(dr.daily_return, 0)                AS daily_return,
  -- twr_index: chained via SUM(LN(1+r)) with COALESCE(r,0) on gap days — the voo_cumulative
  -- precedent — the level survives a gap and resumes correctly on the next real return.
  EXP(SUM(LN(1 + COALESCE(dr.daily_return, 0))) OVER (ORDER BY a.as_of_date)) - 1 AS twr_index
FROM axis a
LEFT JOIN mv          ON mv.as_of_date = a.as_of_date
LEFT JOIN daily_ret dr ON dr.as_of_date = a.as_of_date
LEFT JOIN policy_asof pa ON pa.as_of_date = a.as_of_date

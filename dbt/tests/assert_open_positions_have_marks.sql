-- Singular test (passes when ZERO rows): every OPEN non-SGOV position has a RECENT curated daily mark.
-- 2026-06-28 stack review #2 (#12). state.freshness only checks MAX(mark_date) over the WHOLE daily_marks
-- table, so a single held name silently missing its mark (an IBKR empty/stale bar with no FMP fallback)
-- understates that strategy's r_deployed with no per-name visibility — while the SGOV benchmark side already
-- has a forward-fill completeness guard (bigquery/03_twr_engine.sql). This flags an open position with NO
-- state.daily_marks_curated row in the last ~5 trading days (a name gone dark), using a 7-calendar-day
-- window to avoid exact-trading-day brittleness. SGOV is excluded
-- (benchmark/parking, marked on its own path). The REAL-TIME guard is D2's per-name completeness check +
-- the FMP fallback (Claude_Task_Plan.md D2 step 1); this is the standing CI mirror (advisory `dbt test`).
--
-- JUST-OPENED POSITIONS (2026-11-17, interactive triage of ci_finding b3-invariants, ops.alerts 32564bef).
-- The 7-day window never tolerated a just-opened position, although this header used to say it did: a
-- never-held name has no mark at all until the first session after its OPEN is marked. Staging writes
-- a PROVISIONAL OPEN the evening before the entry session, so the 07:10 UTC run that follows saw every
-- new name as dark. MEASURED: 14 Strategy B names staged 2026-11-16 00:05 UTC failed the 07:27 UTC run
-- and all 14 were marked at that day's close; a replay of this predicate over 2026-07-01..2026-11-17
-- fired on exactly two mornings (2026-07-28, 2026-11-16), both of this kind, and on neither with the
-- guard below. A position is now held to the test only once the marks table holds a session dated
-- AFTER the New York date of its first OPEN, i.e. a session it was open for has been marked.
WITH first_open AS (
  SELECT position_key, DATE(MIN(event_ts), 'America/New_York') AS first_open_date
  FROM {{ source('events', 'position_events') }}
  GROUP BY position_key
),
latest_session AS (
  SELECT MAX(mark_date) AS max_mark_date FROM {{ ref('daily_marks_curated') }}
)
SELECT p.ticker, p.strategy, t.last_trading_day
FROM {{ ref('current_positions') }} p
CROSS JOIN {{ ref('trading_day_today') }} t
CROSS JOIN latest_session ls
JOIN first_open fo ON fo.position_key = p.position_key
WHERE p.ticker IS NOT NULL
  AND p.ticker != 'SGOV'
  -- OCC-format option tickers are marked on state.option_marks_curated (bigquery/40_options_marks.sql),
  -- NEVER on daily_marks_curated; their same-day-mark completeness is guarded by state.option_mark_anomalies.
  -- Without this exclusion an open Strategy-C option position spuriously fails this daily-mark test.
  AND NOT REGEXP_CONTAINS(p.ticker, r'^[A-Z]{1,6} *[0-9]{6}[CP][0-9]{8}$')
  AND ls.max_mark_date > fo.first_open_date
  AND NOT EXISTS (
    SELECT 1
    FROM {{ ref('daily_marks_curated') }} m
    WHERE m.ticker = p.ticker
      AND m.mark_date >= DATE_SUB(t.last_trading_day, INTERVAL 7 DAY)
  )

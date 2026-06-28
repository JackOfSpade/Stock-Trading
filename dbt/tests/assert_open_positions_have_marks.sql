-- Singular test (passes when ZERO rows): every OPEN non-SGOV position has a RECENT curated daily mark.
-- 2026-06-28 stack review #2 (#12). state.freshness only checks MAX(mark_date) over the WHOLE daily_marks
-- table, so a single held name silently missing its mark (an IBKR empty/stale bar with no FMP fallback)
-- understates that strategy's r_deployed with no per-name visibility — while the SGOV benchmark side already
-- has a forward-fill completeness guard (bigquery/03_twr_engine.sql). This flags an open position with NO
-- state.daily_marks_curated row in the last ~5 trading days (a name gone dark), using a 7-calendar-day
-- window to tolerate a just-opened position and avoid exact-trading-day brittleness. SGOV is excluded
-- (benchmark/parking, marked on its own path). The REAL-TIME guard is D2's per-name completeness check +
-- the FMP fallback (Claude_Task_Plan.md D2 step 1); this is the standing CI mirror (advisory `dbt test`).
SELECT p.ticker, p.strategy, t.last_trading_day
FROM {{ ref('current_positions') }} p
CROSS JOIN {{ ref('trading_day_today') }} t
WHERE p.ticker IS NOT NULL
  AND p.ticker != 'SGOV'
  AND NOT EXISTS (
    SELECT 1
    FROM {{ ref('daily_marks_curated') }} m
    WHERE m.ticker = p.ticker
      AND m.mark_date >= DATE_SUB(t.last_trading_day, INTERVAL 7 DAY)
  )

-- Fix state.catchup_refire_readiness's period-tier as_of column (OPS2 adversarial review 2026-07-27,
-- part of the OPS2 Catch-up Executor go-live self-audit). Project: stock-trading-498512.
-- Apply after bigquery/59, bigquery/90.
--
-- SUPERSEDES the state.catchup_refire_readiness view definition in bigquery/59_catchup_autofire.sql.
-- Every OTHER object in that file (the ops.catchup_refire_log TABLE and the
-- state.catchup_refire_failures VIEW) is UNCHANGED and remains canonical there — this file redefines
-- ONLY state.catchup_refire_readiness.
--
-- PROBLEM: this changeset added OPS2 (Claude_Task_Plan.md "## OPS2. Catch-up Executor"), whose STEP 2
-- bounds work at "at most N=4 misses per run, oldest first (`ORDER BY as_of ASC` — the view's real
-- date column, NOT the compound miss_key string...)". That text relies on `as_of` being a genuine
-- per-row chronological signal for BOTH daily and period misses. It is for daily misses (`as_of =
-- today`, one row per calendar day) but was NOT for period misses: bigquery/59's `period_misses` CTE
-- emitted `today AS as_of` — the CURRENT run's date — for every period-tier row, discarding the
-- `period_start` column `state.period_catchup_available` already carries (and which the row's own
-- `miss_key` already encodes via `CONCAT(routine, '|', CAST(period_start AS STRING))`). Every
-- outstanding period-tier miss (W1/W2/W3/W5, M1a/M1b/M2/M3/M5, Q1/Q2/Q3/SL1, A1/A2) therefore ties on
-- an identical as_of within one query execution regardless of how stale each one's true period_start
-- actually is — so on a day with more than OPS2's N=4 cap of outstanding period-tier misses, `ORDER BY
-- as_of ASC` cannot distinguish a genuinely ancient miss (e.g. A1, period_start months ago) from a
-- merely-days-old one (e.g. a W-tier miss), and whichever loses the (unspecified) UNION-order tie-break
-- can be perpetually deferred even though OPS2's stated intent is exactly to guarantee the oldest
-- backlog item gets processed first. (Not itself a correctness gap for OPS0, which has never bounded
-- or ordered its own re-fire loop — this only bites the new oldest-first BOUND OPS2 introduces.)
--
-- FIX: period_misses now selects `period_start AS as_of`, matching the daily-tier CTEs' convention of
-- `as_of` = the row's own chronological anchor date, not the read-time `today`. OPS0's residual email
-- and every other consumer of state.catchup_refire_readiness is unaffected — as_of was never displayed
-- or gated on elsewhere, only newly relied on for ordering by OPS2's STEP 2.
CREATE OR REPLACE VIEW `stock-trading-498512.state.catchup_refire_readiness` AS
WITH daily_misses AS (
  SELECT
    CONCAT(routine, '|', CAST(today AS STRING)) AS miss_key,
    routine, 'daily' AS tier, today AS as_of
  FROM `stock-trading-498512.state.catchup_available`
),
period_misses AS (
  SELECT
    CONCAT(routine, '|', CAST(period_start AS STRING)) AS miss_key,
    routine, 'period' AS tier, period_start AS as_of
  FROM `stock-trading-498512.state.period_catchup_available`
),
yesterday_daily_misses AS (
  SELECT
    CONCAT(routine_id, '|', CAST(y.yday AS STRING)) AS miss_key,
    routine_id AS routine, 'daily' AS tier, y.yday AS as_of
  FROM UNNEST(['D1', 'D3', 'SL3']) AS routine_id
  CROSS JOIN (SELECT today, DATE_SUB(today, INTERVAL 1 DAY) AS yday
              FROM `stock-trading-498512.state.trading_day_today`) y
  -- D1/SL3 are daily_trading (bigquery/12): only expected if yesterday was a trading day; D3 is daily_all
  LEFT JOIN `stock-trading-498512.state.market_calendar` mc
    ON mc.cal_date = y.yday AND mc.is_trading_day
  -- suppressed when TODAY's miss row for the same routine is already pending in daily_misses (after
  -- 21:00 MT a routine that missed both days would otherwise emit two rows and get its trigger fired
  -- twice in one OPS0 sweep; the refire produces the new day's output either way, so the today-row
  -- alone suffices) -- LEFT JOIN + IS NULL (not NOT EXISTS against the daily_misses CTE): see
  -- bigquery/59's BUG FIX note (2026-07-17) this file otherwise reproduces byte-for-byte.
  LEFT JOIN daily_misses dm ON dm.routine = routine_id
  WHERE (routine_id = 'D3' OR mc.cal_date IS NOT NULL)
    -- monitored guard, same convention as state.cadence_watch (has EVER completed)
    AND EXISTS (SELECT 1 FROM `stock-trading-498512.ops.run_log` rl
                WHERE rl.routine = routine_id AND rl.status = 'completed')
    -- actually missed yesterday
    AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.run_log` rl
                    WHERE rl.routine = routine_id AND rl.status = 'completed'
                      AND rl.run_date = y.yday)
    -- suppressed once TODAY's run completed (D1/D3/SL3 are non-cumulative; a same-day run supersedes)
    AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.run_log` rl
                    WHERE rl.routine = routine_id AND rl.status = 'completed'
                      AND rl.run_date = y.today)
    AND dm.routine IS NULL
),
all_misses AS (
  SELECT * FROM daily_misses
  UNION ALL SELECT * FROM period_misses
  UNION ALL SELECT * FROM yesterday_daily_misses
)
SELECT m.miss_key, m.routine, m.tier, m.as_of
FROM all_misses m
LEFT JOIN `stock-trading-498512.ops.catchup_refire_log` l ON l.miss_key = m.miss_key
WHERE l.miss_key IS NULL;

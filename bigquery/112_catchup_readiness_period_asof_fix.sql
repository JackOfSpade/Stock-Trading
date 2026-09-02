-- Fix state.catchup_refire_readiness's period-tier as_of column (OPS2 adversarial review 2026-07-27,
-- part of the OPS2 Catch-up Executor go-live self-audit). Project: stock-trading-498512.
-- Apply after bigquery/59, bigquery/90.
--
-- SUPERSEDED LIVE by bigquery/208_yesterday_tier_ops1_coverage.sql (2026-09-02) — that file is the
-- current single source of truth for state.catchup_refire_readiness. It carries EVERYTHING below
-- forward byte-identical except yesterday_daily_misses' hand-maintained routine list, which goes
-- from ['D1', 'D3', 'SL3'] to ['D1', 'D3', 'OPS1', 'SL3']: OPS1 joined the catchup-safe daily tier
-- on 2026-07-19 (ops/cadence.yaml `catchup_safe: true`, and both bigquery/31 and bigquery/90 list
-- it), but this file's 2026-08-08 widening copied the older 3-id list forward unchanged, so OPS1
-- was silently excluded from the compound-miss recovery bridge. Kept here, unmodified, for
-- DR-rebuild apply-in-order reference only. DO NOT re-apply this CREATE statement live in
-- isolation — doing so reverts OPS1 out of the yesterday tier again.
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
-- outstanding period-tier miss (W1/W2/W3/W4/W5, M1a/M1b/M2/M3/M5, Q1/Q2/Q3/SL1, A1/A2) therefore ties on
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
--
-- YESTERDAY-TIER WIDENED (2026-08-08, daily-tier Fri/Sat consolidation onto Sunday, ops/cadence.yaml).
-- yesterday_daily_misses below was sized for a 1-CALENDAR-DAY OPS0 outage: D1/D3/SL3/OPS0 all fired
-- every calendar day, so `today` and D3's next run were never more than 1 day apart, and literal
-- `DATE_SUB(today, INTERVAL 1 DAY)` was always the routines' own last EXPECTED firing day too. OPS0
-- (like D3, D1, SL3) is now itself paused Friday/Saturday (monitor_class: daily_sun_thu,
-- bigquery/12_cadence_monitor.sql), which GUARANTEES a 2-day gap every week: if OPS0 misses Thursday
-- evening, D3's own next run is Sunday (D3 also skips Fri/Sat), and on that Sunday literal
-- `today - 1` = Saturday — a day none of D1/D3/SL3 was EVER expected to fire, so the "actually missed
-- yesterday" check below would always read FALSE against Saturday, and Thursday's real, unrecovered
-- miss would become PERMANENTLY invisible to this bridge, forever, every single week. Fixed by
-- replacing the literal `yday = today - 1` with the most recent Sunday-Thursday calendar day strictly
-- before `today` (`last_expected_day` below) — the same GENERATE_DATE_ARRAY + DAYOFWEEK NOT IN (6, 7)
-- construction D3's own OPS0 WATCHDOG-FALLBACK bullet (Claude_Task_Plan.md, ## D3) uses to resolve
-- OPS0's last expected day, applied here to D1/D3/SL3 instead. On every day OTHER than Sunday this
-- reduces to the original `today - 1` (Mon-Thu's and Saturday's calendar-yesterday-or-Thursday-anchor
-- is never itself a Friday/Saturday needing a further skip back), so the fix only changes behavior on
-- a Sunday (or a Saturday read, pre-cron-migration) read, off the actual skip-day set rather than a
-- hardcoded day count.
--
-- SIMPLIFICATION ALONGSIDE THE FIX: D1/D3/SL3 previously needed DIFFERENT gating here because they
-- carried different monitor_class values (D1/SL3 were daily_trading — trading-day-gated; D3 was
-- daily_all — not gated), hence the old per-row `LEFT JOIN state.market_calendar ... AND
-- mc.is_trading_day` plus the `WHERE (routine_id = 'D3' OR mc.cal_date IS NOT NULL)` special-case. All
-- three now share monitor_class: daily_sun_thu, which is UNCONDITIONALLY not trading-day-gated (see
-- bigquery/12's CASE), so that per-routine distinction no longer exists and the trading-day join is
-- removed entirely — `last_expected_day` is computed identically for all three routines below.
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
    CONCAT(routine_id, '|', CAST(y.last_expected_day AS STRING)) AS miss_key,
    routine_id AS routine, 'daily' AS tier, y.last_expected_day AS as_of
  FROM UNNEST(['D1', 'D3', 'SL3']) AS routine_id
  -- last_expected_day = the most recent Sunday-Thursday calendar day strictly before `today` (2026-08-08
  -- fix -- see the header note above). BigQuery DAYOFWEEK convention 1=Sunday..7=Saturday, so 6=Friday
  -- and 7=Saturday are excluded, matching bigquery/12's daily_sun_thu CASE and D3's own OPS0
  -- WATCHDOG-FALLBACK bullet exactly. The 7-day lookback window is generous padding (the real answer is
  -- always within 1-3 days back); GROUP BY today collapses state.trading_day_today's single row back
  -- down to one output row after the UNNEST cross join.
  CROSS JOIN (
    SELECT today, MAX(cal_date) AS last_expected_day
    FROM `stock-trading-498512.state.trading_day_today`,
         UNNEST(GENERATE_DATE_ARRAY(DATE_SUB(today, INTERVAL 7 DAY), DATE_SUB(today, INTERVAL 1 DAY))) AS cal_date
    WHERE EXTRACT(DAYOFWEEK FROM cal_date) NOT IN (6, 7)
    GROUP BY today
  ) y
  -- D1/D3/SL3 are all monitor_class: daily_sun_thu as of 2026-08-08 (bigquery/12) -- UNCONDITIONALLY
  -- not trading-day-gated (unlike the old daily_trading/daily_all split), so no market_calendar /
  -- is_trading_day join is needed any more; last_expected_day above already IS each routine's correct
  -- expectation.
  -- suppressed when TODAY's miss row for the same routine is already pending in daily_misses (after
  -- 21:00 MT a routine that missed both days would otherwise emit two rows and get its trigger fired
  -- twice in one OPS0 sweep; the refire produces the new day's output either way, so the today-row
  -- alone suffices) -- LEFT JOIN + IS NULL (not NOT EXISTS against the daily_misses CTE): see
  -- bigquery/59's BUG FIX note (2026-07-17) this file otherwise reproduces byte-for-byte.
  LEFT JOIN daily_misses dm ON dm.routine = routine_id
  WHERE
    -- monitored guard, same convention as state.cadence_watch (has EVER completed)
    EXISTS (SELECT 1 FROM `stock-trading-498512.ops.run_log` rl
                WHERE rl.routine = routine_id AND rl.status = 'completed')
    -- actually missed its last expected day
    AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.run_log` rl
                    WHERE rl.routine = routine_id AND rl.status = 'completed'
                      AND rl.run_date = y.last_expected_day)
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

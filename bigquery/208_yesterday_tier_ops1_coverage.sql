-- 208_yesterday_tier_ops1_coverage.sql (2026-09-02)
-- Project: stock-trading-498512.
--
-- SUPERSEDES the state.catchup_refire_readiness view definition in
-- bigquery/112_catchup_readiness_period_asof_fix.sql (which itself superseded the definition in
-- bigquery/59_catchup_autofire.sql). Every OTHER object in either of those files is UNCHANGED and
-- remains canonical where it is -- this file redefines ONLY state.catchup_refire_readiness.
-- Apply after bigquery/59, bigquery/90, bigquery/112.
--
-- ONE CHANGE: yesterday_daily_misses' hand-maintained routine list goes from
-- UNNEST(['D1', 'D3', 'SL3']) to UNNEST(['D1', 'D3', 'OPS1', 'SL3']). Nothing else in the view
-- changes: the daily_misses / period_misses CTEs, the last_expected_day Sunday-Thursday resolution
-- (bigquery/112's 2026-08-08 fix), the period-tier `period_start AS as_of` column (bigquery/112's
-- 2026-07-27 fix), the three run_log EXISTS/NOT EXISTS guards, the daily_misses LEFT JOIN
-- suppression and the catchup_refire_log anti-join are all carried forward byte-identical.
--
-- WHY. The list is a DRIFTED hand-copy, and the drift was measured live, not inferred. ops/cadence.yaml
-- declares OPS1 `monitor_class: daily_sun_thu`, `catchup_safe: true` ("a late probe still helps; a
-- missed one is covered next morning"), so the catchup-safe daily tier is {D1, D3, OPS1, SL3}. The
-- repo's other two copies of that tier already agree: bigquery/31_catchup_notify.sql:48 and
-- bigquery/90_catchup_inprogress_guard.sql:50 both read ['D1', 'D3', 'OPS1', 'SL3']. Only this
-- "yesterday tier" bridge -- added in bigquery/59, carried forward verbatim by bigquery/112's
-- 2026-08-08 widening -- was never updated when OPS1 joined the tier (2026-07-19), and bigquery/59's
-- own comment above the list still claims it is "hand-maintained in lockstep with bigquery/31's
-- [D1,D3,SL3]" -- a claim that stopped being true the day bigquery/31 gained OPS1. Verified against
-- LIVE state.catchup_refire_readiness's DDL on 2026-09-02: the deployed view reads
-- UNNEST(['D1', 'D3', 'SL3']), so the gap is in production, not only in the repo.
--
-- WHAT IT COSTS TODAY. This CTE is the bridge D3's OPS0-WATCHDOG-FALLBACK step relies on to recover a
-- COMPOUND miss: the routine missed its last expected day AND OPS0 (the same-day catch-up executor)
-- also missed, so nothing re-fired it that evening. daily_misses only ever carries TODAY's misses;
-- yesterday_daily_misses is the only path by which a previous day's unrecovered miss re-enters
-- state.catchup_refire_readiness at all. With OPS1 absent from the list, an OPS1 miss on a Sunday-
-- Thursday day that OPS0 also missed is never synthesized into the readiness view, so OPS0's STEP 2
-- re-fire never sees a row for it and OPS1 is silently never auto-recovered for that day -- while
-- ops/cadence.yaml, bigquery/31 and bigquery/90 all say it should be. The miss is NOT invisible to
-- the operator (state.cadence_watch still raises its own missed_run CRITICAL independently); it is
-- only the AUTOMATED recovery that no-ops, which is the failure mode this bridge exists to prevent.
-- Fri/Sat consolidation makes the window worse, not better: D3's next run after a Thursday miss can
-- be the following Sunday, so the unrecovered day sits for up to three calendar days.
--
-- WHY WIDENING IS THE SAFE DIRECTION. Adding a routine here cannot cause a spurious re-fire: every
-- row still has to clear all three run_log guards (has EVER completed; did NOT complete on
-- last_expected_day; has NOT completed today), the daily_misses LEFT JOIN suppression, and the
-- ops.catchup_refire_log anti-join that makes each miss_key fire at most once ever. A routine that
-- ran normally produces no row. The change only makes OPS1 eligible for the same recovery the other
-- three catchup_safe daily routines have had since bigquery/59.
--
-- MACHINE-CHECKED FROM NOW ON. scripts/check_cadence_consistency.py's check K previously validated
-- only the FIRST `UNNEST([...]) AS routine` bracket per file, which is bigquery/31's daily list and
-- bigquery/59's period list -- this second bracket was structurally invisible to CI, which is why it
-- could drift for six weeks in a repo that gates on cadence single-sourcing. Check K now resolves the
-- CANONICAL file for state.catchup_refire_readiness (this file) and bigquery/90's guard list, and
-- asserts both against the same ops/cadence.yaml-derived catchup-safe daily set it already asserts
-- bigquery/31 against, so this class of drift fails the build instead of sitting in production.
--
-- NOT CHANGED, DELIBERATELY. No new alert category, no ops.alert_policy row, no run_log or
-- catchup_refire_log write, and no change to OPS0's or OPS2's own step text -- both already read this
-- view and neither needed to know the list grew. bigquery/59's and bigquery/112's bytes below the
-- header are untouched, per the apply-in-order/supersede-only discipline; their headers gain a
-- SUPERSEDED pointer to this file, which is how scripts/check_superseded_markers.py requires a
-- superseded definition to be marked.

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
  FROM UNNEST(['D1', 'D3', 'OPS1', 'SL3']) AS routine_id
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
  -- D1/D3/OPS1/SL3 are all monitor_class: daily_sun_thu (bigquery/12; OPS1 added to this list 2026-09-02
  -- by this file) -- UNCONDITIONALLY not trading-day-gated (unlike the old daily_trading/daily_all
  -- split), so no market_calendar / is_trading_day join is needed any more; last_expected_day above
  -- already IS each routine's correct expectation.
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
    -- suppressed once TODAY's run completed (D1/D3/OPS1/SL3 are non-cumulative; a same-day run
    -- supersedes -- ops/cadence.yaml records the same property for OPS1: "a late probe still helps;
    -- a missed one is covered next morning")
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

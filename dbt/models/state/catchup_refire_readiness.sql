-- Parallel-run dbt port of bigquery/208_yesterday_tier_ops1_coverage.sql:state.catchup_refire_readiness — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
-- REPOINTED 2026-09-02 from bigquery/112 to bigquery/208_yesterday_tier_ops1_coverage.sql, which
-- supersedes 112's definition of this view: yesterday_daily_misses' hand-maintained routine list
-- gains OPS1 (it joined the catchup-safe daily tier 2026-07-19 per ops/cadence.yaml, and both
-- bigquery/31 and bigquery/90 already listed it -- only this bridge was never updated). Mirrored
-- here in the same change that applied 208 live, so the dbt port never lags the canonical body --
-- a drifted mirror is what strands every subsequent SQL branch on the dbt-parity gate.
WITH daily_misses AS (
  SELECT
    CONCAT(routine, '|', CAST(today AS STRING)) AS miss_key,
    routine, 'daily' AS tier, today AS as_of
  FROM {{ ref('catchup_available') }}
),
period_misses AS (
  SELECT
    CONCAT(routine, '|', CAST(period_start AS STRING)) AS miss_key,
    routine, 'period' AS tier, period_start AS as_of
  FROM {{ ref('period_catchup_available') }}
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
    FROM {{ ref('trading_day_today') }},
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
    EXISTS (SELECT 1 FROM {{ source('ops', 'run_log') }} rl
                WHERE rl.routine = routine_id AND rl.status = 'completed')
    -- actually missed its last expected day
    AND NOT EXISTS (SELECT 1 FROM {{ source('ops', 'run_log') }} rl
                    WHERE rl.routine = routine_id AND rl.status = 'completed'
                      AND rl.run_date = y.last_expected_day)
    -- suppressed once TODAY's run completed (D1/D3/OPS1/SL3 are non-cumulative; a same-day run
    -- supersedes -- ops/cadence.yaml records the same property for OPS1: "a late probe still helps;
    -- a missed one is covered next morning")
    AND NOT EXISTS (SELECT 1 FROM {{ source('ops', 'run_log') }} rl
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
LEFT JOIN {{ source('ops', 'catchup_refire_log') }} l ON l.miss_key = m.miss_key
WHERE l.miss_key IS NULL

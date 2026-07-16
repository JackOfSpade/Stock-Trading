-- Catch-up AUTO-REFIRE (self-improvement audit 2026-07-15 — CONFIRMED GAP catchup-notify-no-auto-
-- refire; Architect recommendation #1, "the missing meta-repair layer"). Project: stock-trading-498512.
-- Apply after 09_market_calendar.sql, 12_cadence_monitor.sql, 24_cadence_period_watch.sql.
--
-- PROBLEM: state.catchup_available (bigquery/31) flags a D1/D3/SL3 miss that is safe to recover late
-- (no live-order-crafting / intraday-price dependency — a late run reproduces exactly what a same-day
-- run would have). Its only consumer was scripts/alert_relay.py::relay_catchup, which POSTs a webhook
-- telling a HUMAN to "fire its trigger whenever convenient." Verified live 2026-07-13/14: D2 halted
-- twice on 2026-07-13 (missing_dependency, then trading_halted) and never completed that day — nothing
-- ever re-fired it; the day's Daily.md recommendations were simply lost. Verified in-repo: the
-- RemoteTrigger API's `run` action is never invoked programmatically anywhere in this codebase — every
-- reference is a comment/docstring describing a session calling it MANUALLY (ops/cadence.yaml:322,
-- the 2026-07-12 W2/W4 no-show recovery).
--
-- FIX: this file is the READINESS/IDEMPOTENCY substrate. The routine that actually reads it and calls
-- RemoteTrigger is OPS0 (Claude_Task_Plan.md "## OPS0. Cadence Watchdog") — a session cannot call an
-- external API from a scheduled SQL query, so the auto-refire ACTION lives in a routine, not here.
--
-- SCOPE, deliberately narrow (safety-conscious first version, matches bigquery/31's own catchup-safe
-- discipline exactly): OPS0 only ever re-fires the DAILY tier (D1/D3/SL3, via state.catchup_available)
-- and the PERIOD tier defined below (weekly/monthly/quarterly/annual routines that carry no live-order-
-- crafting or intraday-price dependency). It NEVER re-fires D2/D2a (daily) or W4/M4/Q4/A3/SL4 (period,
-- excluded below) — those keep their existing human-visible missed_run/period_missed alert only, exactly
-- as bigquery/31 already excludes D2/D2a from state.catchup_available for the identical reason ("harmless
-- to execute late, but does not recover the value a same-day run would have had — a late run isn't
-- unsafe, but silently implying 'no rush' about live order-crafting would be").
--
-- IDEMPOTENCY: ops.catchup_refire_log — presence of ANY row for a given miss_key means OPS0 has already
-- attempted (or need not re-attempt) that specific miss; it never re-fires the same miss twice in one
-- day. A NEW miss (new routine, or the SAME routine on a LATER day/period) gets a fresh miss_key.

-- ===== ops.catchup_refire_log — idempotency + audit trail for every auto-refire attempt =====
CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.catchup_refire_log` (
  miss_key STRING NOT NULL,           -- e.g. 'D1|2026-07-13' (daily) or 'W2|2026-W28' (period)
  routine STRING NOT NULL,
  tier STRING NOT NULL,               -- 'daily' | 'period'
  attempted_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  trigger_id STRING,                  -- ops/trigger_ids.json id used, if one existed at attempt time
  outcome STRING,                     -- 'refired' | 'no_trigger_id' (couldn't find a live trigger id)
  note STRING
) PARTITION BY DATE(attempted_ts) CLUSTER BY routine
OPTIONS(description='Idempotency + audit trail for OPS0 Cadence Watchdog auto-refire attempts (self-improvement audit 2026-07-15). One row per (miss_key) attempt; presence of any row for a miss_key means never re-attempted again.');

-- ===== state.period_catchup_available — the PERIOD-tier sibling of state.catchup_available =====
-- Built off state.cadence_period_watch.period_missed the same way bigquery/31 builds off
-- state.cadence_watch.needs_attention. catchup_safe_period_routines excludes every ACTION-CONVERSION
-- routine (W4, M4, Q4, A3) and the discretionary-retirement scanner SL4 (monthly, capital-adjacent
-- proposal path) for the identical D2/D2a rationale bigquery/31 already documents — a hand-maintained
-- list, deliberately NOT derived from monitor_class (which classifies by schedule SHAPE, not by
-- order-crafting/capital-adjacency). Update it if a period routine's scope changes.
CREATE OR REPLACE VIEW `stock-trading-498512.state.period_catchup_available` AS
WITH catchup_safe_period_routines AS (
  SELECT routine FROM UNNEST([
    'W1', 'W2', 'W3', 'W5',                    -- weekly research/consolidation (W4 excluded — action-conversion)
    'M1a', 'M1b', 'M2', 'M3', 'M5',             -- monthly research/consolidation (M4 excluded — action-conversion)
    'Q1', 'Q2', 'Q3', 'SL1',                    -- quarterly research/consolidation (Q4 excluded — action-conversion)
    'A1', 'A2'                                  -- annual research (A3 excluded — action-conversion)
    -- SL4 (monthly) deliberately excluded: a discretionary-retirement PROPOSAL is capital-adjacent
    -- enough to warrant the existing human-visible alert only, matching M4/Q4/A3's treatment.
  ]) AS routine
)
SELECT w.routine, w.monitor_class, w.today, w.period_start, w.grace_deadline
FROM `stock-trading-498512.state.cadence_period_watch` w
JOIN catchup_safe_period_routines s USING (routine)
WHERE w.period_missed;

-- ===== state.catchup_refire_readiness — UNION of both tiers, minus already-attempted misses =====
-- miss_key: daily = '<routine>|<today>' (matches state.catchup_available's one-row-per-day shape);
-- period = '<routine>|<period_start>' (a period is uniquely identified by its start date across all
-- four period classes, so no separate week/month/quarter/year discriminator is needed).
--
-- YESTERDAY-TIER (resilience audit 2026-07-16 — "who watches the watcher"): state.catchup_available
-- is same-day-only (needs_attention evaluates only the current operating day and flips at 21:00 MT,
-- bigquery/48_cadence_monitor_unbounded.sql:52-59), so an OPS0 that no-shows or slips past local
-- midnight (the 2026-07-13/14 5-7h evening-delay class) loses that day's daily-tier misses forever —
-- by the next morning the miss rows have vanished from state.catchup_available. yesterday_daily_misses
-- below keeps YESTERDAY's unrecovered D1/D3/SL3 misses visible one extra day so D3's OPS0-WATCHDOG-
-- FALLBACK bullet (Claude_Task_Plan.md, ## D3) can sweep them. ops.catchup_refire_log still caps every
-- miss_key at one attempt ever. Routine list hand-maintained in lockstep with bigquery/31's
-- ['D1','D3','SL3'] (the same catchup-safe daily set — D2/D2a are deliberately excluded).
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
    routine, 'period' AS tier, today AS as_of
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
  WHERE (routine_id = 'D3' OR EXISTS (
          SELECT 1 FROM `stock-trading-498512.state.market_calendar` c
          WHERE c.cal_date = y.yday AND c.is_trading_day))
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
    -- suppressed when TODAY's miss row for the same routine is already pending in daily_misses (after
    -- 21:00 MT a routine that missed both days would otherwise emit two rows and get its trigger fired
    -- twice in one OPS0 sweep; the refire produces the new day's output either way, so the today-row
    -- alone suffices)
    AND NOT EXISTS (SELECT 1 FROM daily_misses dm WHERE dm.routine = routine_id)
),
all_misses AS (
  SELECT * FROM daily_misses
  UNION ALL SELECT * FROM period_misses
  UNION ALL SELECT * FROM yesterday_daily_misses
)
SELECT m.miss_key, m.routine, m.tier, m.as_of
FROM all_misses m
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.ops.catchup_refire_log` l WHERE l.miss_key = m.miss_key
);

-- ===== state.catchup_refire_failures — misses OPS0 attempted but had no live trigger_id for =====
-- Visibility-only (not itself an alert source here — OPS0 raises the alert at attempt time via
-- ops.sp_raise_alert, per its own routine text). A non-empty result means ops/trigger_ids.json is
-- missing an entry for a routine that otherwise would have been auto-refired.
CREATE OR REPLACE VIEW `stock-trading-498512.state.catchup_refire_failures` AS
SELECT miss_key, routine, tier, attempted_ts, note
FROM `stock-trading-498512.ops.catchup_refire_log`
WHERE outcome = 'no_trigger_id'
  AND DATE(attempted_ts) = CURRENT_DATE('America/Denver');

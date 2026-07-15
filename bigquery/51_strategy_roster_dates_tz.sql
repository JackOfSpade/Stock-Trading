-- ITEM: state.strategy_roster.adopted_date/retired_date truncate event_ts to a UTC date instead of
-- America/Denver — same bug class RUNBOOK §41 just fixed in ops.sp_assert_deps (2026-07-14
-- self-improvement audit, finding sql-late#3).
--
-- BUG: bigquery/35_strategy_arsenal.sql's `stamps` CTE computes
-- `MIN(IF(to_state = 'ADOPTED', DATE(event_ts), NULL)) AS adopted_date` and the symmetric
-- `retired_date` — a bare `DATE(event_ts)` with no timezone argument truncates to the UTC calendar
-- date. `event_ts` is `DEFAULT CURRENT_TIMESTAMP()`, written whenever SL5 (the sole roster-membership
-- writer) inserts an ADOPTED/TERMINATED row during its normal Denver-evening run cadence. Any SL5
-- write between roughly 18:00 and 23:59 America/Denver rolls to the next UTC calendar day, so
-- adopted_date/retired_date can be misdated by +1 day relative to the Denver operating day the
-- transition actually represents — exactly the class of bug already fixed elsewhere in this repo
-- (analytics.position_lifecycle's entry_date/exit_date explicitly use
-- `DATE(fill_ts, 'America/New_York')`, NOT the bare UTC-default form, for the identical reason; and
-- RUNBOOK §41 just fixed the same midnight-crossing class in ops.sp_assert_deps). These dates feed
-- bigquery/22_cash_flows.sql's deposit-split attribution
-- (`a.adopted_date <= cf.flow_date AND (a.retired_date IS NULL OR a.retired_date > cf.flow_date)`).
--
-- The founding A-E rows are NOT exposed to this bug — their ADOPTED row uses the literal
-- `TIMESTAMP(DATE '2026-04-23')` seed (midnight UTC) tagged `driver_routine = 'seed-2026-07-10'`, so
-- a naive uniform substitution to `DATE(event_ts, 'America/Denver')` would shift THEIR adopted_date
-- to 2026-04-22 (a real regression, since strategy/roster.yaml's checked-in literal and the current
-- live value are both 2026-04-23). The fix below therefore keys off `driver_routine` to preserve the
-- founding batch's literal day while correcting the derivation for every real SL1-SL5-driven
-- transition going forward.
--
-- SUPERSEDES the state.strategy_roster VIEW definition in bigquery/35_strategy_arsenal.sql. No dbt
-- mirror exists (state.strategy_roster is a declared dbt SOURCE, not a model — no dbt edit needed).
-- Apply after 35_strategy_arsenal.sql, 46_weekly_benchmarks.sql.
CREATE OR REPLACE VIEW `stock-trading-498512.state.strategy_roster` AS
WITH latest AS (
  SELECT strategy_code, to_state AS current_state, event_ts AS state_since,
         driver_routine, review_id, git_commit
  FROM `stock-trading-498512.events.strategy_lifecycle`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY strategy_code ORDER BY event_ts DESC, event_id DESC) = 1
),
stamps AS (
  SELECT strategy_code,
    MIN(IF(to_state IN ('SHADOW','PAPER','PROBE','ADOPTED'), event_ts, NULL)) AS spec_locked_since,
    MIN(IF(to_state IN ('PROBE','ADOPTED'), event_ts, NULL)) AS immutable_since,
    MIN(IF(to_state = 'ADOPTED',
           IF(driver_routine LIKE 'seed-%', DATE(event_ts), DATE(event_ts, 'America/Denver')),
           NULL)) AS adopted_date,
    MAX(IF(to_state = 'TERMINATED',
           IF(driver_routine LIKE 'seed-%', DATE(event_ts), DATE(event_ts, 'America/Denver')),
           NULL)) AS retired_date
  FROM `stock-trading-498512.events.strategy_lifecycle`
  GROUP BY strategy_code
)
SELECT
  l.strategy_code,
  l.current_state,
  l.current_state IN ('PROBE','ADOPTED') AS is_active,
  l.current_state IN ('SHADOW','PAPER')  AS is_incubating,
  s.spec_locked_since,
  s.immutable_since,
  s.adopted_date,
  s.retired_date,
  l.state_since,
  l.driver_routine,
  l.review_id,
  l.git_commit
FROM latest l JOIN stamps s USING (strategy_code);

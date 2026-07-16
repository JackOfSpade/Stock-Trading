-- ITEM: RETIREMENT_PROPOSED strategies silently drop out of is_active during their own retirement
-- review (loop-completeness audit 2026-07-16, finding LC-1).
--
-- BUG: SL4 STEP 2 writes a RETIREMENT_PROPOSED events.strategy_lifecycle row at proposal time, which
-- flips state.strategy_roster.current_state to RETIREMENT_PROPOSED for that strategy. Because
-- is_active = current_state IN ('PROBE','ADOPTED'), the strategy reads is_active = FALSE for the
-- entire adversarial-review window — and Claude_Task_Plan.md's M4 §H kill-trigger/gate evaluation
-- explicitly iterates 'state.strategy_roster where is_active', so the one strategy under
-- edge-decay/redundancy suspicion is silently excluded from kill-trigger evaluation during its own
-- review. It also disappears from state.active_strategy_codes and state.arsenal_rails.active_count
-- while under review — but a retirement PROPOSAL is default-KEEP (SL4 STEP 2 conservative_default =
-- 'KEEP'; the strategy has NOT been retired, only nominated for adversarial review), so it must stay
-- counted and monitored exactly like any other ADOPTED strategy until an affirmative RETIRE verdict
-- actually terminates it.
--
-- SUPERSEDES the state.strategy_roster VIEW definition in bigquery/51_strategy_roster_dates_tz.sql
-- (51 is the live-deployed definition — verified 2026-07-16 via state.INFORMATION_SCHEMA.VIEWS:
-- Denver-TZ adopted_date/retired_date derivation present; do NOT copy bigquery/35_strategy_arsenal.sql's
-- superseded original copy). Copied verbatim from bigquery/51, changing ONLY the is_active line to add
-- RETIREMENT_PROPOSED. is_incubating is untouched (SHADOW/PAPER only — RETIREMENT_PROPOSED is never an
-- incubation state). No dbt model edit: analytics.strategy_nav keys off immutable_since
-- (bigquery/22_cash_flows.sql:100-107), not is_active; state.strategy_roster is a declared dbt SOURCE,
-- not a model, so scripts/check_roster_consistency.py needs no edit (it compares strategy/roster.yaml's
-- roster_state against bigquery/35's parsed seed rows — SL4/AR_orc lifecycle rows are live-only, and
-- roster.yaml stays roster_state=adopted throughout a review window).
--
-- Apply after 51_strategy_roster_dates_tz.sql.
-- ============================================================================
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
  l.current_state IN ('PROBE','ADOPTED','RETIREMENT_PROPOSED') AS is_active,
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

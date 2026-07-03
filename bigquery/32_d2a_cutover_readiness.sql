-- D2a autonomous cutover readiness (self-improvement audit follow-up, 2026-07-03). Project:
-- stock-trading-498512. Apply after 01_schema.sql (ops.run_log) + 09_market_calendar.sql
-- (state.market_calendar).
--
-- WHY: D2a's first live run (2026-07-03, a market HOLIDAY) ended its chat output by asking "Reply if
-- you'd like me to complete the cutover" — but Claude_Task_Plan.md documents throughout, in dozens of
-- places, "routine chat is unmonitored"; that question will never be read by anyone, so the cutover
-- would simply never happen. This closes the gap the SAME way every other human-facing signal in this
-- system already is: an objective, code-checkable threshold the routine evaluates and acts on itself,
-- with NO chat question and NO reply required — genuinely autonomous, not a dead-end escalation.
--
-- A single early success is deliberately NOT sufficient evidence, and today's run does not count at
-- all: it landed on a market holiday, so it exercised only the no-new-fills / no-sweep-needed path. The
-- harder paths this cutover actually needs confidence in — real fill reconciliation, SGOV sweep/cover
-- crafting under analytics.fn_order_guard, and the TWR engine ingesting freshly-ingested marks — only run
-- on an actual trading day. The threshold below counts DISTINCT TRADING-DAY completed runs only.
-- Written exactly once, by D2a itself, the run it performs the autonomous cutover. Presence of ANY row
-- is the durable idempotency check — a BigQuery marker, not a prose/grep read of Claude_Task_Plan.md,
-- so re-running this check can never accidentally re-trigger (or fail to detect) the cutover.
CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.d2a_cutover_log` (
  cutover_id STRING DEFAULT GENERATE_UUID(),
  cutover_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  qualifying_trading_day_runs INT64,
  git_commit STRING,
  note STRING
) OPTIONS(description='Written once, by D2a itself, on the run it autonomously performs the D2/D2a dependency cutover. Presence of any row means the cutover is done. Self-improvement audit follow-up, 2026-07-03.');

CREATE OR REPLACE VIEW `stock-trading-498512.state.d2a_cutover_readiness` AS
WITH qualifying AS (
  SELECT DISTINCT r.run_date
  FROM `stock-trading-498512.ops.run_log` r
  JOIN `stock-trading-498512.state.market_calendar` c
    ON c.cal_date = r.run_date AND c.is_trading_day
  WHERE r.routine = 'D2a' AND r.status = 'completed'
)
SELECT
  (SELECT COUNT(*) FROM qualifying) AS qualifying_trading_day_runs,
  NOT EXISTS(SELECT 1 FROM `stock-trading-498512.ops.d2a_cutover_log`) AS cutover_still_pending,
  (SELECT COUNT(*) FROM qualifying) >= 3
    AND NOT EXISTS(SELECT 1 FROM `stock-trading-498512.ops.d2a_cutover_log`) AS ready_for_cutover;

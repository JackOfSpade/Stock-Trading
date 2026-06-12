-- state.daily_briefing — the "what needs attention today" view the agent reads at the
-- start of D1/D2 instead of loading files. Assembles due queue work, firing kill-triggers,
-- and time-based exits from the component views. Project: stock-trading-498512.
--
-- The exit-trigger price sweep (live mark vs convergence_target) and the §13 cash/SGOV
-- reconciliation delta are added at D2 runtime once the day's connector marks are inserted
-- into events.daily_marks; this view covers the parts computable from stored state.
-- "Today" is the experiment's operating day, America/Denver (the runbooks' due
-- contract is "due_date <= today (America/Denver)", Claude_Task_Plan.md D2 Step 1;
-- M5 stamps run_date the same way). Bare CURRENT_DATE() is UTC and rolls over at
-- ~17:00-18:00 Denver, surfacing tomorrow's items as due in any evening session.
CREATE OR REPLACE VIEW `stock-trading-498512.state.daily_briefing` AS
SELECT 'QUEUE_DUE' AS category, item_key AS item, strategy, due_date AS as_of,
       CONCAT(queue, ': ', COALESCE(item_type,''), ' ', COALESCE(ticker,'')) AS detail
FROM `stock-trading-498512.state.open_queue`
WHERE due_date <= CURRENT_DATE('America/Denver')
UNION ALL
SELECT 'KILL_FLAG', strategy, strategy, as_of_date,
       CONCAT('drawdown_kill=', CAST(drawdown_kill AS STRING),
              ' runaway=', CAST(runaway_review AS STRING),
              ' m2m=', CAST(m2m_underperf_review AS STRING))
FROM `stock-trading-498512.perf.kill_flags`
WHERE drawdown_kill OR runaway_review OR m2m_underperf_review
UNION ALL
-- Time-based exits apply only to A/B/C/E (D is long-horizon, no time exit per Strategy.md).
-- (This rule-based filter is also robust to a migration parse artifact where a D position
--  picked up a stray date in its "Time-based exit: None..." field.)
SELECT 'TIME_EXIT', position_key, strategy, time_exit_date,
       CONCAT(ticker, ' time-exit ', CAST(time_exit_date AS STRING))
FROM `stock-trading-498512.state.current_positions`
-- status='OPEN' guard (consistent with analytics.strategy_nav) so a non-CLOSE
-- but non-open latest event doesn't raise a spurious time-exit alert.
WHERE strategy <> 'D' AND time_exit_date <= CURRENT_DATE('America/Denver') AND status = 'OPEN';

-- Briefing inputs the agent also reads directly (all built):
--   state.current_positions, state.current_regime (technical+activation+fundamental axes),
--   perf.kill_flags, analytics.find_precedents('<new thesis>') for semantic precedent.

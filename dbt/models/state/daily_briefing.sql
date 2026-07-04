-- Parallel-run dbt port of bigquery/05_state_briefing.sql:state.daily_briefing — canonical source is that file until owner cutover.
-- "What needs attention today": due queue work + firing kill-triggers + time-based exits,
-- assembled from the component models. The exit-trigger price sweep + §13 reconciliation
-- delta are added at D2 runtime once the day's marks are inserted; this view covers the
-- parts computable from stored state.
--
-- "Today" is the experiment's operating day, America/Denver (the runbooks' due contract is
-- due_date <= today (America/Denver)). Bare CURRENT_DATE() is UTC and rolls over ~17:00-18:00
-- Denver, surfacing tomorrow's items as due in any evening session.

SELECT 'QUEUE_DUE' AS category, item_key AS item, strategy, due_date AS as_of,
       CONCAT(queue, ': ', COALESCE(item_type,''), ' ', COALESCE(ticker,'')) AS detail
FROM {{ ref('open_queue') }}
WHERE due_date <= CURRENT_DATE('America/Denver')

UNION ALL

SELECT 'KILL_FLAG', strategy, strategy, as_of_date,
       CONCAT('drawdown_kill=', CAST(drawdown_kill AS STRING),
              ' runaway=', CAST(runaway_review AS STRING),
              ' m2m=', CAST(m2m_underperf_review AS STRING),
              ' interim_underperf=', CAST(interim_underperf_warning AS STRING))
FROM {{ ref('kill_flags') }}
-- interim_underperf_warning added 2026-07-04 (audit finding) — see bigquery/05_state_briefing.sql.
WHERE drawdown_kill OR runaway_review OR m2m_underperf_review OR interim_underperf_warning

UNION ALL

-- Time-based exits apply only to A/B/C/E (D is long-horizon, no time exit per Strategy.md).
-- status='OPEN' guard (consistent with analytics.strategy_nav) so a non-CLOSE but non-open
-- latest event doesn't raise a spurious time-exit alert.
SELECT 'TIME_EXIT', position_key, strategy, time_exit_date,
       CONCAT(ticker, ' time-exit ', CAST(time_exit_date AS STRING))
FROM {{ ref('current_positions') }}
WHERE strategy <> 'D' AND time_exit_date <= CURRENT_DATE('America/Denver') AND status = 'OPEN'

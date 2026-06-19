-- Parallel-run dbt port of bigquery/10_observability.sql:state.freshness — canonical source is that file until owner cutover.
-- The dead-man's switch: are marks / engine / D2 current vs the last trading day?
--
-- COALESCE(...) -> FALSE so the switch fails LOUD, never silent: if a source table is empty
-- or last_trading_day is NULL (calendar range exhausted), a bare `>=` would yield NULL ->
-- all_green NULL -> the freshness check's `IF NOT all_green` would NOT fire. FALSE makes it alert.

WITH ltd AS (SELECT last_trading_day, is_trading_day, today FROM {{ ref('trading_day_today') }}),
m  AS (SELECT MAX(mark_date)   AS v FROM {{ source('events', 'daily_marks') }}),
e  AS (SELECT MAX(as_of_date)  AS v FROM {{ source('perf', 'strategy_daily') }}),
d  AS (SELECT MAX(entry_date)  AS v FROM {{ source('events', 'decision_log') }}),
d2 AS (SELECT MAX(run_date)    AS v FROM {{ source('ops', 'run_log') }} WHERE routine = 'D2' AND status = 'completed')
SELECT
  (SELECT last_trading_day FROM ltd) AS last_trading_day,
  (SELECT v FROM m)  AS last_mark_date,
  (SELECT v FROM e)  AS engine_through,
  (SELECT v FROM d)  AS last_decision_date,
  (SELECT v FROM d2) AS last_d2_run_date,
  COALESCE((SELECT v FROM m) >= (SELECT last_trading_day FROM ltd), FALSE) AS marks_fresh,
  COALESCE((SELECT v FROM e) >= (SELECT last_trading_day FROM ltd), FALSE) AS engine_fresh,
  COALESCE((SELECT v FROM d2) >= (SELECT last_trading_day FROM ltd), FALSE) AS d2_ran_last_trading_day,
  CURRENT_TIMESTAMP() AS checked_at

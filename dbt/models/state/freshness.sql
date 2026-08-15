-- Parallel-run dbt port of bigquery/10_observability.sql:state.freshness, as superseded by
-- bigquery/173_freshness_cadence_aware.sql — canonical source is that file until owner cutover.
-- The dead-man's switch: are marks / engine / D2 current vs the last trading day?
--
-- COALESCE(...) -> FALSE so the switch fails LOUD, never silent: if a source table is empty
-- or last_trading_day is NULL (calendar range exhausted), a bare `>=` would yield NULL ->
-- all_green NULL -> the freshness check's `IF NOT all_green` would NOT fire. FALSE makes it alert.
--
-- CADENCE-AWARE pair added 2026-08-15 (bigquery/173): marks_due_through / marks_current /
-- engine_current expect coverage only of trading days a SCHEDULED D2a run (cron 40 22 * * 0,1,2,3,4)
-- has already had the opportunity to ingest. Under the 2026-08-08 Sun-Thu consolidation the daily
-- tier skips Friday/Saturday and backfills Friday on its Sunday run, so the older
-- marks_fresh/engine_fresh basis was structurally unsatisfiable every weekend. Both pairs are kept:
-- the trading gates in bigquery/107 read the stricter marks_fresh/engine_fresh, the daily_freshness_check
-- dead-man reads the cadence-aware pair. See bigquery/173's header for the full derivation.

WITH ltd AS (SELECT last_trading_day, is_trading_day, today FROM {{ ref('trading_day_today') }}),
slot AS (
  SELECT MAX(sd) AS last_elapsed_slot_date
  FROM UNNEST(GENERATE_DATE_ARRAY(DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 28 DAY),
                                  CURRENT_DATE('America/Denver'))) AS sd
  WHERE EXTRACT(DAYOFWEEK FROM sd) NOT IN (6, 7)
    AND TIMESTAMP(DATETIME(sd, TIME '22:40:00')) <= CURRENT_TIMESTAMP()
),
due AS (
  SELECT MAX(mc.cal_date) AS v
  FROM {{ ref('market_calendar') }} mc
  WHERE mc.is_trading_day
    AND mc.cal_date <= (SELECT last_elapsed_slot_date FROM slot)
),
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
  (SELECT v FROM due) AS marks_due_through,
  COALESCE((SELECT v FROM m) >= (SELECT last_trading_day FROM ltd), FALSE) AS marks_fresh,
  COALESCE((SELECT v FROM e) >= (SELECT last_trading_day FROM ltd), FALSE) AS engine_fresh,
  COALESCE((SELECT v FROM d2) >= (SELECT last_trading_day FROM ltd), FALSE) AS d2_ran_last_trading_day,
  COALESCE((SELECT v FROM m) >= (SELECT v FROM due), FALSE) AS marks_current,
  COALESCE((SELECT v FROM e) >= (SELECT v FROM due), FALSE) AS engine_current,
  CURRENT_TIMESTAMP() AS checked_at

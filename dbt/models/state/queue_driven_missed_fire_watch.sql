-- Parallel-run dbt port of bigquery/241_queue_driven_per_day_missed_fire.sql:state.queue_driven_missed_fire_watch — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
WITH routines AS (
  SELECT * FROM UNNEST([
-- BEGIN GENERATED ROUTINE LIST (scripts/gen_routine_lists.py --write; do not hand-edit)
    STRUCT('AR_att' AS routine, 'queue_driven' AS monitor_class, [1,2,3,4,5] AS denver_dow),
    STRUCT('AR_orc' AS routine, 'queue_driven' AS monitor_class, [1,2,3,4,5] AS denver_dow),
    STRUCT('SL2' AS routine, 'queue_driven' AS monitor_class, [1,2,3,4,5] AS denver_dow),
    STRUCT('SL5' AS routine, 'queue_driven' AS monitor_class, [1,2,3,4,5] AS denver_dow),
    STRUCT('M1R' AS routine, 'queue_driven' AS monitor_class, [1,2,3,4,5] AS denver_dow)
  -- END GENERATED ROUTINE LIST
  ])
),
t AS (
  SELECT today FROM {{ ref('trading_day_today') }}
),
-- ADOPTION FLOOR, strict >. A routine is never expected on or before the date of its own first
-- ops.run_log row: that row is typically a mid-day seed/manual run made when the routine was
-- registered, on a day its cron had already passed or had not yet fired, so counting that day would
-- flag a miss that never existed. Strict > rather than >= for the reason the DATE-grain join note
-- gives -- a >= on a DATE admits the boundary day itself, which is exactly the ambiguous one.
first_seen AS (
  SELECT routine, MIN(run_date) AS first_run_date
  FROM {{ source('ops', 'run_log') }}
  GROUP BY routine
),
completed AS (
  SELECT DISTINCT routine, run_date
  FROM {{ source('ops', 'run_log') }}
  WHERE status = 'completed'
),
-- The expectation window ends YESTERDAY (Denver): today is never flagged, because these routines
-- fire anywhere from 13:00 UTC (M1R, same Denver day) to 01:25 UTC (SL5, previous Denver day) and a
-- slot that has not come round yet is not a miss. It starts 5 days back -- see the procedure-side
-- comment in this same file for why 5 is bounded above by the 7-day auto-age and must not be widened
-- past 6. denver_dow is BigQuery EXTRACT(DAYOFWEEK) numbering, 1 = Sunday .. 7 = Saturday, and is
-- GENERATED from each routine own expected_trigger.cron_utc in ops/cadence.yaml rather than assumed:
-- all five spell Denver Sun-Thu today, but by two different UTC shapes (M1R fires 13:00 UTC on the
-- same Denver day; the other four fire 00:00-01:25 UTC on the NEXT UTC day, which is the PREVIOUS
-- Denver day), so a hardcoded shared day-set would misdate a future retime by one day.
expected AS (
  SELECT r.routine, r.monitor_class, d AS expected_date
  FROM routines AS r
  CROSS JOIN UNNEST(r.denver_dow) AS wanted_dow
  CROSS JOIN t
  CROSS JOIN UNNEST(GENERATE_DATE_ARRAY(DATE_SUB(t.today, INTERVAL 5 DAY),
                                        DATE_SUB(t.today, INTERVAL 1 DAY))) AS d
  WHERE EXTRACT(DAYOFWEEK FROM d) = wanted_dow
)
SELECT
  e.routine,
  e.monitor_class,
  e.expected_date,
  f.first_run_date,
  DATE_DIFF(t.today, e.expected_date, DAY) AS days_ago,
  t.today AS checked_on
FROM expected AS e
JOIN first_seen AS f ON f.routine = e.routine
CROSS JOIN t
LEFT JOIN completed AS c ON c.routine = e.routine AND c.run_date = e.expected_date
WHERE c.run_date IS NULL
  AND e.expected_date > f.first_run_date

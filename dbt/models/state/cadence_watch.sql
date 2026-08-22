-- Parallel-run dbt port of bigquery/142_cadence_deadline_revert_and_evidence_drift.sql:state.cadence_watch — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
WITH watch AS (
  SELECT
    e.routine,
    e.schedule,
    e.today,
    -- monitored = has EVER completed (unchanged column, no rolling window -- bigquery/48's fix stays).
    EXISTS(SELECT 1 FROM {{ source('ops', 'run_log') }} r
           WHERE r.routine = e.routine AND r.status = 'completed') AS monitored,
    EXISTS(SELECT 1 FROM {{ source('ops', 'run_log') }} r
           WHERE r.routine = e.routine AND r.status = 'completed'
             AND r.run_date = e.today) AS ran_completed_today
  FROM {{ ref('cadence_expected_today') }} e
)
SELECT
  e.routine,
  e.schedule,
  e.today,
  e.monitored,
  e.ran_completed_today,
  -- `monitored` precondition stays REMOVED from the alarm predicate (bigquery/113's fix).
  -- CHANGED HERE (bigquery/142, 2026-08-06): TIME '21:45:00' -> TIME '21:00:00' — REVERT of the 129
  -- autotune. The evidence that justified the D1 change was manufactured by a backfilled-row artifact
  -- that bigquery/89 later excluded (see the header of bigquery/142 for the full account); the evidence
  -- for D2 and D3 was genuine, but cadence_watch_deadline_local is one shared constant across all three
  -- routines, not set per routine, so all three revert together.
  -- 'daily_sun_thu' ADDED 2026-08-08 (daily-tier Fri/Sat consolidation onto Sunday, ops/cadence.yaml):
  -- D1/D2a/D2/D3/OPS0/OPS1/OPS2/SL3 moved off daily_trading/daily_all onto this new class. A genuinely
  -- missed Sun-Thu run MUST still raise a CRITICAL through this same alarm predicate -- omitting the
  -- new class here would have silently disarmed needs_attention for the entire daily tier the moment
  -- ops/cadence.yaml's monitor_class fields changed, even though state.cadence_expected_today (12_
  -- cadence_monitor.sql) already expects these routines correctly under the new class.
  (e.schedule IN ('daily_trading','daily_all','daily_sun_thu')
   AND NOT e.ran_completed_today
   AND DATETIME(CURRENT_TIMESTAMP(), 'America/Denver') >= DATETIME(e.today, TIME '21:00:00')
  ) AS needs_attention,
  CURRENT_TIMESTAMP() AS checked_at
FROM watch e

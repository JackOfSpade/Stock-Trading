-- Parallel-run dbt port of bigquery/274_period_catchup_dependency_halt.sql:state.period_catchup_available — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
WITH catchup_safe_period_routines AS (
  SELECT routine FROM UNNEST([
    'W1', 'W2', 'W3', 'W4', 'W5',              -- weekly research/enrichment/handoff/consolidation
    'M1a', 'M1b', 'M2', 'M3', 'M5',             -- monthly research/consolidation (M4 excluded — action-conversion)
    'Q1', 'Q2', 'Q3', 'SL1',                    -- quarterly research/consolidation (Q4 excluded — action-conversion)
    'A1', 'A2'                                  -- annual research (A3 excluded — action-conversion)
    -- SL4 (monthly) deliberately excluded: a discretionary-retirement PROPOSAL is capital-adjacent
    -- enough to warrant the existing human-visible alert only, matching M4/Q4/A3's treatment.
  ]) AS routine
),
in_flight AS (
  -- Same latest-row-wins in-flight pick as state.catchup_available above. The run_date equality that
  -- used to be on the JOIN is gone: a period-tier routine normally logs run_date = the calendar day it
  -- runs, but one HOSTED INLINE by OPS2 may log it under period_start, and either way a fresh 'started'
  -- row means a session for this routine is running right now.
  SELECT DISTINCT routine
  FROM (
    SELECT routine, run_date, status, log_ts,
      ROW_NUMBER() OVER (PARTITION BY routine, run_date ORDER BY log_ts DESC) AS rn
    FROM {{ source('ops', 'run_log') }}
  )
  WHERE rn = 1
    AND status = 'started'
    AND log_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 3 HOUR)
),
-- A catchup_safe routine a downstream routine has already halted on. Its own miss cannot wait for grace:
-- the halt's missing_dependency critical blocks trading in the meantime. The 2-hour age lets a merely
-- late upstream finish first, and own IS NULL keeps a blocked middle link from firing before its root.
open_dep_alerts AS (
  SELECT source, alert_ts, JSON_VALUE(payload, '$.missing_deps') AS deps
  FROM {{ source('ops', 'alerts') }}
  WHERE category = 'missing_dependency' AND NOT COALESCE(resolved, FALSE)
),
halted_upstream AS (
  SELECT n.routine
  FROM (
    SELECT TRIM(d) AS routine, o.alert_ts
    FROM open_dep_alerts o, UNNEST(SPLIT(o.deps, ',')) AS d
    WHERE o.alert_ts <= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 2 HOUR)
  ) n
  JOIN {{ ref('cadence_period_watch') }} w ON w.routine = n.routine
  LEFT JOIN open_dep_alerts own ON own.source = n.routine
  WHERE n.alert_ts >= TIMESTAMP(w.period_start, 'America/Denver')
    AND own.source IS NULL
  GROUP BY n.routine
)
SELECT w.routine, w.monitor_class, w.today, w.period_start, w.grace_deadline
FROM {{ ref('cadence_period_watch') }} w
JOIN catchup_safe_period_routines s USING (routine)
LEFT JOIN in_flight f ON f.routine = w.routine
LEFT JOIN halted_upstream h ON h.routine = w.routine
WHERE (w.period_missed OR (h.routine IS NOT NULL AND NOT w.ran_completed_this_period))
  AND f.routine IS NULL

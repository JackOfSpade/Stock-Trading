-- Surface a catchup_safe period miss before grace once a downstream routine has already halted on it.
-- Project: stock-trading-498512. SUPERSEDES state.period_catchup_available from
-- bigquery/184_inflight_guard_hosted_runs.sql (that file's state.catchup_available stays canonical).
-- Idempotent (CREATE OR REPLACE VIEW). Apply after 184. state.cadence_period_watch and period_missed are
-- untouched, and state.catchup_refire_readiness (bigquery/208) reads this view with no edit of its own.
--
-- WHY (2026-11-02, interactive owner session, closing ops.alerts 87d07347, OPS2's
-- period_catchup_grace_outlasts_dependency_halt). period_missed stays FALSE until grace, the 3rd trading
-- day. M1a's trigger never fired on 2026-08-01 or 2026-10-01; M1b then halted and missing_dependency
-- criticals held trading, while OPS0 and OPS2 could not see the miss until grace days later. Both times a
-- human re-run ended it. A blocked routine's own repair cannot help a headless session with no RemoteTrigger.
--
-- WHAT CHANGED. Only the final WHERE and two CTEs. catchup_safe_period_routines stays verbatim, so M4, Q4,
-- A3 and SL4 remain excluded. REPLAYED over every missing_dependency alert ever raised: it would have
-- surfaced M1a on 2026-08-01 and 2026-10-01 and W4 on 2026-07-19, and no routine that was merely late.
-- Recovery still takes one link per overnight pass: M1b resurfaces once its own alert auto-resolves.

CREATE OR REPLACE VIEW `stock-trading-498512.state.period_catchup_available` AS
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
    FROM `stock-trading-498512.ops.run_log`
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
  FROM `stock-trading-498512.ops.alerts`
  WHERE category = 'missing_dependency' AND NOT COALESCE(resolved, FALSE)
),
halted_upstream AS (
  SELECT n.routine
  FROM (
    SELECT TRIM(d) AS routine, o.alert_ts
    FROM open_dep_alerts o, UNNEST(SPLIT(o.deps, ',')) AS d
    WHERE o.alert_ts <= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 2 HOUR)
  ) n
  JOIN `stock-trading-498512.state.cadence_period_watch` w ON w.routine = n.routine
  LEFT JOIN open_dep_alerts own ON own.source = n.routine
  WHERE n.alert_ts >= TIMESTAMP(w.period_start, 'America/Denver')
    AND own.source IS NULL
  GROUP BY n.routine
)
SELECT w.routine, w.monitor_class, w.today, w.period_start, w.grace_deadline
FROM `stock-trading-498512.state.cadence_period_watch` w
JOIN catchup_safe_period_routines s USING (routine)
LEFT JOIN in_flight f ON f.routine = w.routine
LEFT JOIN halted_upstream h ON h.routine = w.routine
WHERE (w.period_missed OR (h.routine IS NOT NULL AND NOT w.ran_completed_this_period))
  AND f.routine IS NULL;

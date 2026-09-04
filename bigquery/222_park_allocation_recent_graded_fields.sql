-- 222_park_allocation_recent_graded_fields.sql (2026-09-04) — PARK ALLOCATOR v4.
-- Project: stock-trading-498512. Surfaces the graded-call fields on state.park_allocation_recent so
-- D2 can actually read what D1 is told to write. Apply after 221.
--
-- SUPERSEDES the definition of state.park_allocation_recent in
-- bigquery/144_decision_log_correction_consumers.sql (chain: 135 -> 144 -> 222). 144 keeps
-- state.decision_log_current and everything else it defines. NOT a successor to bigquery/92 —
-- bigquery/README.md pins that file as DR-reference-only.
--
-- ============================ WHY ================================================================
-- D1's PARK ALLOCATION CALL step tells the session to log target_f_pct / risk_sleeve /
-- defensive_sleeve into the decision row's `fields` JSON. D2's conversion step is told to read
-- state.park_allocation_latest and compare TARGET WEIGHTS. But the view projected only
-- entry_id, entry_date, event_ts, decision, title, vehicle, conviction, conviction_pct, direction,
-- status, is_call — none of the three. A session following the prose had NO SOURCE on the view it
-- was told to read for the values the INSERT demands, and the realistic failure mode is not a loud
-- error but IMPROVISATION: target_f_pct is NULLABLE, and state.park_policy_current resolves a NULL
-- as IF(vehicle='VOO', 0, 100) — so on an f=75 call (majority sleeve = the DEFENSIVE one) a NULL
-- write silently resolves to f=100 and over-executes ~$3.8k of a ~$15.3k park.
-- `readings` is surfaced in the same pass because D2's EVIDENCE RECOMPUTE step must recompute the
-- rationale's counts from it, and it was equally invisible.
--
-- state.park_allocation_latest is `SELECT * FROM state.park_allocation_recent WHERE is_call
-- ORDER BY event_ts DESC LIMIT 1`, so it inherits these columns automatically — do NOT redefine it.
--
-- is_call SEMANTICS ARE UNCHANGED and must stay that way: JSON_VALUE(fields,'$.status') IS NOT NULL.
-- That predicate is what keeps correction notes and excursion-outcome rows from being mistaken for
-- today's call (bigquery/213, 214 and the design doc's trap #1). Nothing here widens it.
--
-- LEGACY ROWS: every pre-v4 park-allocation row has no target_f_pct in `fields`, so these columns
-- come back NULL for them. That is correct and must not be COALESCEd here — the binary-era meaning
-- of those rows lives in state.park_policy_current's own legacy mapping, and duplicating it in the
-- call view would give two different answers to the same question.

CREATE OR REPLACE VIEW `stock-trading-498512.state.park_allocation_recent` AS
SELECT
  entry_id,
  entry_date,
  event_ts,
  decision,
  title,
  JSON_VALUE(fields, '$.vehicle')                               AS vehicle,
  JSON_VALUE(fields, '$.conviction')                            AS conviction,
  SAFE_CAST(JSON_VALUE(fields, '$.conviction_pct') AS NUMERIC)  AS conviction_pct,
  JSON_VALUE(fields, '$.direction')                             AS direction,
  JSON_VALUE(fields, '$.status')                                AS status,
  -- v4 graded fields (bigquery/222).
  SAFE_CAST(JSON_VALUE(fields, '$.target_f_pct') AS INT64)      AS target_f_pct,
  JSON_VALUE(fields, '$.risk_sleeve')                           AS risk_sleeve,
  JSON_VALUE(fields, '$.defensive_sleeve')                      AS defensive_sleeve,
  -- The evidence snapshot D2's recompute-and-refuse step must read.
  JSON_QUERY(fields, '$.readings')                              AS readings,
  JSON_VALUE(fields, '$.status') IS NOT NULL                    AS is_call
FROM `stock-trading-498512.state.decision_log_current`
WHERE entry_type = 'park-allocation'
ORDER BY event_ts DESC
LIMIT 25;

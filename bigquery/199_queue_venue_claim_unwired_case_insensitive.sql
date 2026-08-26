-- bigquery/199_queue_venue_claim_unwired_case_insensitive.sql
-- ============================================================================================
-- NORMALIZE STATUS FILTER IN `state.queue_venue_claim_unwired` TO NON-TERMINAL SET
-- (2026-08-25 — alert triage following AR_att warning alert ffd14d5c `handoff_contract_unpinned`).
--
-- THE BUG
-- -------
-- bigquery/160 and bigquery/180 defined candidate selection in `state.queue_venue_claim_unwired` with:
--     WHERE l.status = 'pending'
--
-- That exact-literal equality filter caused the detector to be blind to non-terminal queue rows
-- carrying alternative or uppercase status values (such as 'OPEN', 'open', or 'attacker-complete').
--
-- On 2026-08-24/25, three ad-hoc `ops-defect` rows were inserted into `events.queue_events` under
-- queue `PENDING_REVIEW` carrying `status = 'OPEN'` and naming `payload.owning_routine = 'OPS0'` (2 rows)
-- and `'D2a'` (1 row). Since PENDING_REVIEW is drained solely by [AR_att, AR_orc], these were invalid
-- venue claims. However, because their status was 'OPEN' rather than 'pending',
-- `state.queue_venue_claim_unwired` completely filtered them out and failed to alert.
--
-- AR_att discovered this during its 2026-08-25 run and raised alert ffd14d5c to notify the system.
--
-- THE FIX
-- -------
-- Align candidate selection in `state.queue_venue_claim_unwired` with `state.open_queue_detail`'s
-- battle-tested, case-normalized non-terminal filter:
--     WHERE UPPER(l.status) NOT IN ('COMPLETE','SUPERSEDED','DROPPED',
--                                   'FILLED','EXPIRED','ABANDONED')
--
-- This ensures any non-terminal queue row making an unwired venue claim or using an invalid
-- `analysis_type` is caught regardless of status casing ('pending', 'PENDING', 'OPEN', 'open', etc.).
--
-- SUPERSEDES `state.queue_venue_claim_unwired` in bigquery/180_probe_register_queue_lane.sql (and
-- bigquery/160_queue_venue_claim_detector.sql). Allowed map (including PENDING_ROSTER -> SL5 from 180),
-- tie-breaking logic, and analysis_type enums remain intact.
-- ============================================================================================

CREATE OR REPLACE VIEW `stock-trading-498512.state.queue_venue_claim_unwired` AS
WITH latest AS (
  SELECT
    queue, item_key, item_type, status, strategy, ticker, due_date, conservative_default,
    payload, event_ts AS latest_event_ts
  FROM `stock-trading-498512.events.queue_events`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY queue, item_key ORDER BY event_ts DESC, event_id DESC) = 1
),
first_seen AS (
  SELECT item_key, MIN(event_ts) AS first_seen_ts
  FROM `stock-trading-498512.events.queue_events`
  GROUP BY item_key
),
allowed_map AS (
  SELECT * FROM UNNEST([
    STRUCT('PENDING_ANALYSIS' AS queue, ['D2'] AS allowed_drainers),
    STRUCT('PENDING_REVIEW'   AS queue, ['AR_att', 'AR_orc'] AS allowed_drainers),
    STRUCT('PENDING_DRAFT'    AS queue, ['SL2'] AS allowed_drainers),
    STRUCT('PENDING_ROSTER'   AS queue, ['SL5'] AS allowed_drainers)
  ])
),
candidates AS (
  SELECT
    l.item_key, l.queue, l.item_type, l.strategy, l.ticker, l.due_date, l.conservative_default,
    JSON_VALUE(l.payload, '$.analysis_type') AS analysis_type,
    COALESCE(
      JSON_VALUE(l.payload, '$.resolving_venue'),
      JSON_VALUE(l.payload, '$.owning_routine'),
      JSON_VALUE(l.payload, '$.escalation_routine')
    ) AS claimed_venue,
    am.allowed_drainers,
    fs.first_seen_ts
  FROM latest l
  LEFT JOIN allowed_map am ON am.queue = l.queue
  LEFT JOIN first_seen fs ON fs.item_key = l.item_key
  WHERE UPPER(l.status) NOT IN ('COMPLETE','SUPERSEDED','DROPPED',
                                'FILLED','EXPIRED','ABANDONED')
)
-- Finding class (a): unwired_venue.
SELECT
  item_key, queue,
  'unwired_venue' AS finding_class,
  claimed_venue,
  ARRAY_TO_STRING(COALESCE(allowed_drainers, []), ', ') AS allowed_drainers,
  analysis_type, due_date, conservative_default, strategy, ticker, first_seen_ts,
  CONCAT(
    item_key, ' (', queue, '): payload claims a resolving venue of ', claimed_venue,
    ', but the only routine(s) that actually drain ', queue, ' are [',
    ARRAY_TO_STRING(COALESCE(allowed_drainers, []), ', '),
    IF(allowed_drainers IS NULL, '] -- this queue has no declared venue concept at all', ']'),
    ' -- this claim cannot be honored by anything in the system and misleads a future reader into ',
    'believing a review that will never happen is scheduled to happen.'
  ) AS message
FROM candidates
WHERE claimed_venue IS NOT NULL
  AND (allowed_drainers IS NULL OR claimed_venue NOT IN UNNEST(allowed_drainers))

UNION ALL

-- Finding class (b): unknown_analysis_type.
SELECT
  item_key, queue,
  'unknown_analysis_type' AS finding_class,
  CAST(NULL AS STRING) AS claimed_venue,
  ARRAY_TO_STRING(COALESCE(allowed_drainers, []), ', ') AS allowed_drainers,
  analysis_type, due_date, conservative_default, strategy, ticker, first_seen_ts,
  CONCAT(
    item_key, ' (', queue, '): payload.analysis_type = ', analysis_type,
    ' is outside the documented enum at Claude_Task_Plan.md:285 (thesis-construction | re-screen | ',
    'research-deferral-checkpoint | foundation-change-assessment | constraint-relaxation-review | ',
    'criteria-coverage-review | criterion-recheck) -- either fold it into the documented enum or ',
    'correct the ad-hoc value.'
  ) AS message
FROM candidates
WHERE analysis_type IS NOT NULL
  AND analysis_type NOT IN (
    'thesis-construction', 're-screen', 'research-deferral-checkpoint',
    'foundation-change-assessment', 'constraint-relaxation-review',
    'criteria-coverage-review',
    'criterion-recheck'
  );

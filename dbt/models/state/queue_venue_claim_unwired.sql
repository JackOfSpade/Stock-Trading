-- Parallel-run dbt port of bigquery/199_queue_venue_claim_status_normalisation.sql:state.queue_venue_claim_unwired — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH latest AS (
  -- Latest status per (queue, item_key), same idiom as state.open_queue_detail
  -- (bigquery/01_schema.sql:148-153) -- partitioning by (queue, item_key) rather than item_key alone
  -- matches that view's own defensive choice in case an item_key is ever reused across queues.
  --
  -- SECONDARY TIEBREAKER (event_id DESC) ADDED 2026-08-10, DIVERGING from open_queue_detail's own
  -- (event_ts-only) ORDER BY -- adversarial review of this file. open_queue_detail's idiom is NOT
  -- provably safe against a same-instant tie: state.current_regime (bigquery/01_schema.sql, a few
  -- lines below open_queue_detail) hits the IDENTICAL latest-wins-over-an-append-only-events-table
  -- shape and its own QUALIFY carries `event_id DESC` specifically because "two events can share
  -- (as_of_date, event_ts) for the same (scope, key) (e.g. STRATEGY_ACTIVATION C on 2026-06-03), and
  -- without it ROW_NUMBER picks one arbitrarily, so the resolved regime could flip between query
  -- runs" -- and queue_events uses the exact same write shape as regime_events (event_id STRING
  -- DEFAULT GENERATE_UUID(), event_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP() -- bigquery/01_schema.sql
  -- lines 58-59 (regime_events) vs 71-72 (queue_events); verified 2026-08-10 -- the file's line 42-43
  -- holds the unrelated events.position_events table's matching columns, a third sibling with the
  -- identical shape, not a citation for either table named here), so a multi-row INSERT ... SELECT
  -- batch (BigQuery evaluates
  -- CURRENT_TIMESTAMP() once per statement, not once per row) can produce two queue_events rows for
  -- the SAME (queue, item_key) sharing one event_ts exactly as it already has for regime_events.
  -- EMPIRICALLY REPRODUCED 2026-08-10 (read-only synthetic query, no write): a 'pending' row carrying
  -- an unwired resolving_venue claim and a 'complete' row for the same synthetic (queue, item_key) at
  -- an IDENTICAL literal event_ts flip which one QUALIFY ROW_NUMBER()...ORDER BY event_ts DESC picks
  -- as "latest" purely based on which row is listed first in the input -- i.e. exactly the
  -- nondeterminism state.current_regime's comment warns about, not a hypothetical. No live
  -- events.queue_events row pair currently collides on event_ts (checked 2026-08-10: zero
  -- (queue,item_key) groups share an exact event_ts today), so this does not change today's result --
  -- it forecloses a real, demonstrated-elsewhere bug class before this alerting view's first genuine
  -- tie, rather than after. event_id has no temporal meaning (GENERATE_UUID()), so this does not
  -- recover TRUE chronological order on a tie -- it only makes the pick STABLE and reproducible run to
  -- run, which is exactly what current_regime's own fix settles for.
  SELECT
    queue, item_key, item_type, status, strategy, ticker, due_date, conservative_default,
    payload, event_ts AS latest_event_ts
  FROM {{ source('events', 'queue_events') }}
  QUALIFY ROW_NUMBER() OVER (PARTITION BY queue, item_key ORDER BY event_ts DESC, event_id DESC) = 1
),
first_seen AS (
  -- Original enqueue time per item_key, across the item's WHOLE history (a re-enqueued
  -- PENDING_REVIEW cycle -- e.g. an echo-suspect cool-off requeue, Claude_Task_Plan.md's Step 3.5 --
  -- reuses the same item_key with a fresh row, so this must scan the raw table, not `latest`).
  SELECT item_key, MIN(event_ts) AS first_seen_ts
  FROM {{ source('events', 'queue_events') }}
  GROUP BY item_key
),
allowed_map AS (
  -- THE reviewable queue -> real-drainer map. Verified 2026-08-10 against ops/cadence.yaml +
  -- Claude_Task_Plan.md -- see the file header for the exact citations per row. A queue absent from
  -- this UNNEST (WATCHLIST, ORDER_STAGED) joins to NULL below and is treated as "no legitimate venue
  -- claim is possible on this lane at all" -- any claim there is unconditionally unwired.
  SELECT * FROM UNNEST([
    STRUCT('PENDING_ANALYSIS' AS queue, ['D2'] AS allowed_drainers),
    STRUCT('PENDING_REVIEW'   AS queue, ['AR_att', 'AR_orc'] AS allowed_drainers),
    STRUCT('PENDING_DRAFT'    AS queue, ['SL2'] AS allowed_drainers),
    -- PENDING_ROSTER added 2026-08-18 (bigquery/180, SL5 diligence sweep). The SL3 -> SL5
    -- PAPER->PROBE handoff names this lane with drainer SL5 as of the same change; before it, that
    -- handoff pinned NO queue value on either side. Registering the lane here is load-bearing, not
    -- bookkeeping: a queue absent from this map joins to NULL below and is treated as "no legitimate
    -- venue claim is possible on this lane at all", so a CORRECT resolving_venue='SL5' payload on a
    -- probe-register row would have been reported as an unwired claim the moment SISA's first
    -- graduation wrote one. Citations: Claude_Task_Plan.md SL3 STEP 3 (PAPER->PROBE line, producer)
    -- and SL5's dispatch-scan sentence (consumer); ops/cadence.yaml lists SL5 monitor_class
    -- queue_driven, the same producer/consumer evidence standard the three rows above were verified
    -- against on 2026-08-10.
    STRUCT('PENDING_ROSTER'   AS queue, ['SL5'] AS allowed_drainers)
  ])
),
candidates AS (
  SELECT
    l.item_key, l.queue, l.item_type, l.strategy, l.ticker, l.due_date, l.conservative_default,
    JSON_VALUE(l.payload, '$.analysis_type') AS analysis_type,
    -- First non-null of the three ad-hoc keys the two founding incidents actually used. A row is
    -- never expected to carry more than one of the three (each incident used exactly one), but
    -- COALESCE keeps the detector correct even if a future item names more than one.
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
  -- CASE-NORMALIZED TERMINAL-STATUS FILTER (bigquery/199, 2026-08-25, D3), replacing the
  -- case-sensitive `l.status = 'pending'` this CTE carried from bigquery/160 through /180.
  -- Identical in form and rationale to state.open_queue_detail's own filter on this same
  -- column (bigquery/01_schema.sql:195-196), whose inline comment records that the
  -- agent-written status column has already drifted case once. Three live PENDING_REVIEW
  -- rows carrying the non-vocabulary token 'OPEN' were invisible to the old predicate --
  -- see this file's header for the measurement. A row is a candidate unless it has
  -- demonstrably finished; 'filled'/'expired'/'abandoned' are the ORDER_STAGED terminals.
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
    'criteria-coverage-review',  -- legitimised 2026-08-10, concurrent session, see file header
    'criterion-recheck'  -- legitimised 2026-08-10, same-day follow-up session: found un-enumerated in
                          -- item_key 'recheck-CRM-crpo-D-20260812' (queue PENDING_ANALYSIS, enqueued
                          -- by D2 2026-08-05 at D1's explicit request, due 2026-08-12) by this
                          -- detector's own founding validation pass, above. Same reasoning as
                          -- criteria-coverage-review: D2's drain predicate never gates on
                          -- analysis_type, so this carried no operational risk -- the enum was simply
                          -- incomplete. See Claude_Task_Plan.md's analysis_type enum (line 285 as of
                          -- 2026-08-10), which now documents both values under one dated parenthetical.
  )

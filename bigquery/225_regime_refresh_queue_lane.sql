-- ============================================================================================
-- 225_regime_refresh_queue_lane.sql (2026-09-05, owner-directed shock-override package, item R2)
--
-- ONE CHANGE: `state.queue_venue_claim_unwired`'s `allowed_map` gains a fifth lane,
-- `PENDING_REGIME_REFRESH -> ['M1R']`. Nothing else in the view changes: both finding classes, the
-- (queue,item_key)+event_id tiebreaker, the four existing lanes, the case-normalized terminal-status
-- filter from bigquery/199 and the analysis_type enum are carried forward byte-identical.
--
-- WHY THE LANE HAS TO BE REGISTERED HERE, IN THE SAME CHANGE THAT CREATES IT. This view treats a
-- queue that is ABSENT from allowed_map as one where "no legitimate venue claim is possible on this
-- lane at all" -- its own comment, and the reason bigquery/180 had to register PENDING_ROSTER before
-- SISA's first graduation wrote a row. The re-risking limb (Strategy.md Section 6 scenario 3, Rev 46,
-- rewired by this package's R2) has D2a enqueue an out-of-cycle regime-refresh item that M1R drains.
-- If D2a's payload names M1R as the resolving venue -- which it should, so the item says who will act
-- on it -- and the lane is unregistered, D3's VENUE-CLAIM HONORING CHECK raises
-- `queue_venue_claim_unwired` against a perfectly correct row, on the FIRST item ever written. The
-- alternative (write the item with no venue claim at all, so the detector stays silent) buys silence
-- by removing the fact the detector exists to check, and is exactly the shape this repo has already
-- rejected once.
--
-- LANE VOCABULARY: the queue literal is `PENDING_REGIME_REFRESH` and the item_key convention is
-- `regime-refresh-YYYYMMDD`, matching the PENDING_* naming of the four existing drain-to-completion
-- lanes (WATCHLIST and ORDER_STAGED are the two deliberately-absent non-lanes, recorded in
-- ops/handoff_contracts.yaml's excluded_queues). Terminal status is `complete`, the same token the
-- other four lanes close on. This file is the machine-readable half; ops/handoff_contracts.yaml's
-- queue_lanes entry is the prose half, and scripts/check_handoff_contracts.py CHECK A asserts the two
-- stay set-identical in both directions -- a lane in one and not the other is a named FAIL.
--
-- WHY A WHOLE-VIEW SUPERSEDE FOR A ONE-ROW UNNEST. bigquery/*.sql is apply-in-order and
-- supersede-only: there is no in-place edit of a landed definition, and the allowed_map is a literal
-- inside the view body, not a table anything can INSERT into. bigquery/180 registered its lane the
-- same way. scripts/check_handoff_contracts.py's resolve_allowed_map_source() finds this file by
-- resolving the HIGHEST-numbered file that CREATEs the view -- it pins no filename -- so the checker
-- follows the supersede automatically.
--
-- NOT CHANGED, DELIBERATELY: no new alert category and no new raise site (D3 already reads this view
-- every run and raises `queue_venue_claim_unwired` per row; that category's ops.alert_policy row stays
-- canonical in bigquery/160), no change to state.open_queue_detail, no queue row rewritten,
-- and no relaxation of the terminal-status predicate bigquery/199 landed.
--
-- SUPERSEDES `state.queue_venue_claim_unwired` in bigquery/199_queue_venue_claim_status_normalisation.sql
-- (chain: 160 -> 180 -> 199 -> 225). All three prior definition sites' markers are repointed here in
-- the same commit. Do NOT re-apply any of them in isolation: doing so drops this lane, and 160's or
-- 180's would additionally revert the case-normalized status filter that bigquery/199 exists to hold.
--
-- APPLY: live via the BigQuery MCP, after 224, together with the regenerated dbt mirror
-- (dbt/models/state/queue_venue_claim_unwired.sql) and the ops/handoff_contracts.yaml entry.
-- Defines exactly one view; creates, redefines or drops nothing else.
-- ============================================================================================

CREATE OR REPLACE VIEW `stock-trading-498512.state.queue_venue_claim_unwired` AS
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
  FROM `stock-trading-498512.events.queue_events`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY queue, item_key ORDER BY event_ts DESC, event_id DESC) = 1
),
first_seen AS (
  -- Original enqueue time per item_key, across the item's WHOLE history (a re-enqueued
  -- PENDING_REVIEW cycle -- e.g. an echo-suspect cool-off requeue, Claude_Task_Plan.md's Step 3.5 --
  -- reuses the same item_key with a fresh row, so this must scan the raw table, not `latest`).
  SELECT item_key, MIN(event_ts) AS first_seen_ts
  FROM `stock-trading-498512.events.queue_events`
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
    STRUCT('PENDING_ROSTER'   AS queue, ['SL5'] AS allowed_drainers),
    -- PENDING_REGIME_REFRESH added 2026-09-05 (bigquery/225, the shock-override package's R2 limb
    -- wiring). D2a's re-risking-limb substep enqueues one `regime-refresh-YYYYMMDD` item on this lane
    -- when state.rerisking_limb_status reports a fired limb; M1R (Out-of-cycle Regime Re-score) is its
    -- only drainer and closes it at status = complete. Registering the lane is load-bearing for the
    -- same reason bigquery/180's row was: a queue absent from this map joins to NULL below and is
    -- treated as "no legitimate venue claim is possible on this lane at all", so a CORRECT
    -- resolving_venue='M1R' payload would be reported as an unwired claim on the very first item D2a
    -- writes. Citations: Claude_Task_Plan.md D2a's RE-RISKING LIMB substep (producer) and M1R's own
    -- section (consumer, with the terminal close); ops/cadence.yaml lists M1R monitor_class
    -- queue_driven, the same producer/consumer evidence standard the four rows above were verified
    -- against; ops/handoff_contracts.yaml carries the matching queue_lanes entry, which
    -- scripts/check_handoff_contracts.py asserts stays set-identical to this UNNEST.
    STRUCT('PENDING_REGIME_REFRESH' AS queue, ['M1R'] AS allowed_drainers)
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
  );

-- VERIFICATION (run after apply; read-only).
-- SELECT * FROM `stock-trading-498512.state.queue_venue_claim_unwired`;
--   -- ZERO rows, both before and after -- verified read-only on 2026-09-05 by replaying this file's
--   -- body and EXCEPT-DISTINCT-ing it against the live view in both directions (0 and 0). This is a
--   -- no-change apply BY CONSTRUCTION: the file adds a lane to allowed_map and events.queue_events
--   -- holds no PENDING_REGIME_REFRESH row yet, so no candidate row's LEFT JOIN result can move.
-- NOTE: double-dash line comments only. A trailing C-style block comment placed after this file's
-- last statement causes permanent live-sql-parity drift -- never introduce one here.

-- bigquery/180_probe_register_queue_lane.sql
-- ============================================================================================
-- REGISTER THE `PENDING_ROSTER` QUEUE LANE (the SL3 -> SL5 probe-register handoff)
-- Authored by SL5, 2026-08-18, during its own diligence sweep on a no-op cycle.
--
-- WHY
-- ---
-- SL5 is the SOLE writer of roster MEMBERSHIP and dispatches on exactly three inputs. Two of them
-- are signals, not queue rows (branch (1) SHADOW-register reads state.strategy_adoption_readiness;
-- branch (3) TERMINATED-deregister reads a TERMINATED events.strategy_lifecycle row). The third,
-- branch (2) PROBE-register, is the one real cross-routine QUEUE handoff in the SISA lifecycle: SL3
-- enqueues it when a PAPER candidate clears its graduation gate, and SL5 drains it.
--
-- That handoff was UNDER-SPECIFIED on BOTH sides. SL3 STEP 3 named `item_type='probe-register'` plus
-- a `trigger_context=strategy_code` that is not a column of events.queue_events at all, and SL5's
-- dispatch sentence said only "Scan the queue". Meanwhile `queue` and `item_key` are NOT NULL with
-- no default (bigquery/01_schema.sql), so an implementing session MUST supply a lane string and had
-- nothing to copy. Two independent sessions -- SL3's fire and SL5's, days or weeks apart, with no
-- shared chat memory -- would each have invented one. When they disagree, SL3 logs a successful
-- graduation enqueue, SL5 finds nothing, and the arsenal's first PAPER->PROBE promotion stalls
-- silently: no alert, no red gate, and both run_log rows read 'completed'.
--
-- This is the same defect SHAPE as the AR_orc -> SL2 revision-routing gap that cost two SL2 fires on
-- 2026-08-16 (alert ar_orc_revision_unrouted, fixed 2026-08-17, commit d66da71) -- an unstated
-- concrete value on a cross-routine handoff. The difference is timing: that one was found AFTER it
-- fired; this one is closed before SL5's route (2) has ever run once (ops.roster_change_log has 0
-- rows as of this file -- SL5 has never applied a roster mutation).
--
-- WHAT THIS FILE DOES
-- -------------------
-- The prose fix (pinning queue/item_key/item_type/status/strategy/due_date on the producer side and
-- naming the lane on the consumer side) lands in Claude_Task_Plan.md in the same commit. This file
-- carries the ONE SQL-side consequence of choosing a lane name: registering `PENDING_ROSTER` ->
-- ['SL5'] in state.queue_venue_claim_unwired's canonical queue -> real-drainer map.
--
-- That registration is load-bearing rather than cosmetic. bigquery/160's allowed_map documents its
-- own fail-closed semantics: "A queue absent from this UNNEST (WATCHLIST, ORDER_STAGED) joins to
-- NULL below and is treated as 'no legitimate venue claim is possible on this lane at all' -- any
-- claim there is unconditionally unwired." So without this row, the FIRST probe-register item that
-- carried a perfectly correct `resolving_venue='SL5'` payload would be reported by the detector as
-- an unwired venue claim -- a false positive manufactured on the single highest-stakes row in the
-- whole arsenal pipeline, at the exact moment a strategy is about to take real capital.
--
-- SUPERSEDES `state.queue_venue_claim_unwired` in bigquery/160_queue_venue_claim_detector.sql. The
-- view body below is byte-identical to 160's except for the one added STRUCT (and its comment) in
-- allowed_map; both finding classes, the (queue,item_key)+event_id tiebreaker, the pending-only
-- filter and the analysis_type enum are unchanged. 160's ops.alert_policy INSERT is NOT repeated
-- here -- that row already exists and its resolve_rule is unaffected by adding a lane.
--
-- NOT CHANGED, DELIBERATELY: no new alert category, no raise site, no auto-resolve rule, no change
-- to state.open_queue_detail (which has no lane whitelist -- verified: any `queue` value flows
-- through it, so PENDING_ROSTER needs no plumbing there), and no BigQuery credential anywhere new.
-- This is a one-row map extension plus prose.
--
-- Apply after bigquery/160_queue_venue_claim_detector.sql. Defines exactly one view; creates,
-- redefines or drops nothing else.
--
-- SUPERSEDED LIVE by bigquery/225_regime_refresh_queue_lane.sql (2026-09-05) — that file is the
-- CURRENT canonical definition of state.queue_venue_claim_unwired. It carries the PENDING_ROSTER ->
-- ['SL5'] lane added below forward unchanged and adds a fifth, PENDING_REGIME_REFRESH -> ['M1R'].
-- HISTORY, no longer a current-truth claim: the intermediate link is
-- bigquery/199_queue_venue_claim_status_normalisation.sql (2026-08-25, D3), which replaced the
-- `candidates` CTE's case-sensitive `WHERE l.status = 'pending'` with state.open_queue_detail's
-- case-normalized terminal-status exclusion. Do NOT re-apply this file's view in isolation: the
-- pending-only predicate below was measured blind to three live PENDING_REVIEW rows carrying the
-- non-vocabulary status token 'OPEN', each with a genuinely unwired venue claim, so restoring it
-- re-blinds the detector to every non-`pending` non-terminal token, and drops the M1R lane besides.
-- See bigquery/199's header for the measurement.
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
  WHERE l.status = 'pending'
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

-- ============================================================================================
-- ops.alert_policy registration for `handoff_contract_unpinned`.
--
-- ACCIDENT-OF-ABSENCE DISCIPLINE, same as premortem_live_gate_defect (bigquery/158),
-- prompt_injection_attempt (bigquery/138), append_only_violation (bigquery/139) and
-- queue_venue_claim_unwired (bigquery/160): the class gets a written resolve rule at its first
-- finding rather than after its second, so no future session has to invent one.
--
-- The class GENERALIZES beyond this file's specific fix. Two instances are already on record:
--   * AR_orc -> SL2 revision routing -- the due_date offset was unspecified on both sides, drifted
--     on 2026-08-16, and cost two SL2 fires as no-ops (alert ar_orc_revision_unrouted, remediated
--     2026-08-17, commit d66da71). Found AFTER it fired.
--   * SL3 -> SL5 probe-register -- `queue` and `item_key` (both NOT NULL, no default) named on
--     NEITHER side. Found BEFORE it fired, by this file's change; SL5's route (2) has never run.
-- Both share one shape: a cross-routine handoff whose prose leaves a REQUIRED value to the
-- implementing session's invention, in a system where producer and consumer are separate sessions
-- with no shared memory. The failure is silent by construction -- both sides log 'completed'.
--
-- Guarded by NOT EXISTS so re-applying this file is idempotent (same shape as bigquery/160's row).
-- ============================================================================================
INSERT INTO `stock-trading-498512.ops.alert_policy` (category, latching, resolve_rule, note)
SELECT p.category, p.latching, p.resolve_rule, p.note
FROM UNNEST([
  STRUCT(
    'handoff_contract_unpinned' AS category,
    FALSE AS latching,
    CONCAT(
      'EVIDENCE-BASED, REPO-VERIFIABLE resolve -- NOT covered by any ops.sp_auto_resolve_alerts rule ',
      '(those are hardcoded to missing_dependency/missed_run/routine_stalled/catchup_refire_blocked/',
      'staleness), so latching=FALSE only SANCTIONS the resolve below under the fail-closed allowlist; ',
      'it does not perform it. Resolve when BOTH sides of the handoff named in payload.handoff pin the ',
      'SAME concrete values for every required column: read the producer prose at payload.producer_ref ',
      'and the consumer prose at payload.consumer_ref and confirm they agree. For a finding raised by ',
      'the same session that fixed it, that is already true at raise time and the row exists to DELIVER ',
      'the notice -- so the NEXT cycle of the raising routine confirms from the repo and resolves with ',
      'UPDATE ops.alerts SET resolved=TRUE, resolved_ts=CURRENT_TIMESTAMP(), resolved_note=<the two ',
      'refs re-read + verdict> scoped by alert_id. NEVER resolve on age: this class is silent by ',
      'construction (both routines log completed), so an aged-out row is indistinguishable from a ',
      'fixed one -- the same aging-alert trap phantom_run_completion documents. Never resolve on a ',
      'DIFFERENT handoff -- per-handoff evidence, same discipline as queue_venue_claim_unwired.'
    ) AS resolve_rule,
    CONCAT(
      'HANDOFF-INTEGRITY CLASS, registered 2026-08-18 by SL5 on a no-op cycle, after its own diligence ',
      'sweep found the SL3 -> SL5 probe-register handoff pinned NO queue/item_key value on either side ',
      'while both columns are NOT NULL with no default (bigquery/01_schema.sql). CONDITION: a ',
      'cross-routine handoff leaves a REQUIRED field to the implementing session to invent. Producer ',
      'and consumer are separate sessions with no shared chat memory, so two independent inventions ',
      'disagree and the handoff drops the item with BOTH run_log rows reading completed -- no alert, ',
      'no red gate, nothing to notice. Prior instance: ar_orc_revision_unrouted (AR_orc -> SL2 due_date ',
      'offset, drifted 2026-08-16, two SL2 no-op fires, fixed 2026-08-17 commit d66da71) -- that one ',
      'was found after firing; the founding instance for THIS row was found before. WARNING, never ',
      'critical: an open critical sets state.trading_enabled=FALSE (bigquery/107) and an unpinned prose ',
      'contract is not a reason to halt order staging -- escalate to critical only if an unpinned ',
      'handoff is found to have actually dropped a capital-affecting item. Never info: alert_emailer.gs ',
      'and alert_relay.py both filter info out, so an info raise would be invisible by construction.'
    ) AS note
  )
]) AS p
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.ops.alert_policy` e WHERE e.category = p.category
);

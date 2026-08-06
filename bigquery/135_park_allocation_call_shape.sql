-- 135_park_allocation_call_shape.sql (2026-08-04)
-- Project: stock-trading-498512. Apply AFTER 92_park_allocator.sql (and 108_park_allocator_immediate_binding.sql,
-- which dropped state.park_switch_budget / state.park_allocator_promotion_readiness -- neither is touched here).
--
-- FIXES alert c5044046-53da-4d91-be8d-4002d1882ec0 (WARNING, D2, park_router, 2026-08-03 17:26 MT).
--
-- WHAT HAPPENED. D1's real park call landed 2026-08-03 16:36 MT (entry_id 6ca0c839-686e-48d4-a3b7-fe7716d2efff:
-- SWITCH SGOV->VOO, status BOUND, MEDIUM 60). Eighteen minutes later, at 16:54 MT, D2a logged its park-COVER
-- staging note (entry_id 237d0efc-02bf-47e3-8269-354a395a0ace, decision COVER, "Park COVER staged -- SELL 2.2398
-- SGOV against a -224.5681 realized unfunded debit") under the SAME entry_type='park-allocation'. That row is not
-- a call: its vehicle, status, conviction and direction are all NULL. state.park_allocation_recent filtered ONLY
-- on entry_type, with no predicate on row SHAPE, and state.park_allocation_latest is a bare ORDER BY event_ts
-- DESC LIMIT 1 over it -- so _latest returned the COVER row and D1's actual SWITCH became invisible.
--
-- WHY THIS IS THE DANGEROUS FAILURE MODE. A D2 reading _latest mechanically sees status NULL -- neither HOLD nor
-- BOUND -- and so executes NO conversion at all, on a park switch worth 92.5% of NLV ($8,754.41), with NOTHING to
-- alert on: no error, no exception, just a silently skipped reallocation. D2 2026-08-03 caught the shadowing
-- in-session and fell back to D1's row by entry_id, and the switch executed correctly (events.park_policy_changes
-- adc830c8, 17:35 MT) -- so nothing was mis-traded. But that recovery depended on a human-equivalent noticing,
-- not on the mechanism. This file removes the dependence on noticing.
--
-- VERIFIED LIVE 2026-08-04 (read-only, before this change):
--   * state.park_allocation_latest STILL returns the COVER row right now -- the defect is live, not historical
--     (no park-allocation row has landed since 2026-08-03 16:54 MT).
--   * The COVER row is the ONLY non-call row in all 16 entry_type='park-allocation' rows ever written.
--   * All 15 genuine calls carry a non-NULL fields.status: BOUND x10, RECORD_ONLY x5. None has ever been NULL.
--     So keying "is this a call?" off status IS NOT NULL drops nothing real, historically or today.
--   * decision vocabulary actually observed on calls is KEEP / DE-RISK / SWITCH (plus COVER on the non-call row).
--     RE-RISK and LATERAL are NOT decision values -- they live in fields.direction. This is exactly why the
--     predicate below keys off status (which PARK_ROUTER_DESIGN.md pins to a closed set) rather than off a
--     hand-maintained decision allowlist, which would silently drop a call the day the vocabulary grows.
--
-- DESIGN NOTE -- WHY NOT SIMPLY FILTER THE NON-CALL ROWS OUT OF _recent. Dropping rows at the _recent layer
-- closes the shadowing, but introduces a new silent failure in the opposite direction: a genuine call written
-- with a malformed/missing status would vanish, and _latest would then return the PREVIOUS day's call as though
-- it were current -- a stale-read that looks perfectly well-formed to the consumer, which is strictly worse than
-- today's loud NULL. So instead: _recent KEEPS every row and gains an explicit is_call flag (full auditability
-- preserved -- cover rows stay visible to anyone reading the park history), and only _latest, the view whose
-- entire contract is "the current standing call", filters on it. No row is ever silently discarded.
--
-- SCOPE: consumers of entry_type='park-allocation' are exactly these two views (verified by grep: the other two
-- readers in bigquery/92 are DROPPED live by bigquery/108 and survive only as DR-rebuild reference). No
-- procedure, dbt model or analytics view reads this entry_type, so this change is contained to the read path.

-- =====================================================================================================
-- state.park_allocation_recent -- SUPERSEDES bigquery/92_park_allocator.sql's definition.
-- Every column and comment below is unchanged from 92 except: (1) the new is_call flag, (2) LIMIT 10 -> 25.
-- The LIMIT is raised because _latest now filters this view's output: at 10 rows, a run of non-call rows could
-- in principle push every genuine call off the end and leave _latest empty. 25 keeps roughly five weeks of
-- daily calls in scope, so the filter can never starve on any realistic cover-row rate.
-- =====================================================================================================
-- SUPERSEDED LIVE by bigquery/144_decision_log_correction_consumers.sql — current single source of truth
-- for this object. Kept here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT re-apply
-- this CREATE statement live in isolation: it reads events.decision_log directly BEFORE its LIMIT 25, so an obsolete row could consume a slot
-- and, via state.park_allocation_latest, shadow the standing park call.
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
  JSON_VALUE(fields, '$.direction')                             AS direction,  -- 'de-risk' | 're-risk' | 'lateral' | 'keep'
  JSON_VALUE(fields, '$.status')                                AS status,     -- 'PENDING' | 'BOUND' | 'RECORD_ONLY'
  -- CALL-SHAPE FLAG (2026-08-04, alert c5044046-53da-4d91-be8d-4002d1882ec0). Every real D1 park call -- KEEP,
  -- DE-RISK and SWITCH alike -- carries a status; a row without one is some other kind of park event (today:
  -- D2a's COVER/sweep staging note) that happens to share this entry_type. Consumers that need "the standing
  -- allocation call" must filter on this; state.park_allocation_latest below does.
  JSON_VALUE(fields, '$.status') IS NOT NULL                    AS is_call
FROM `stock-trading-498512.events.decision_log`
WHERE entry_type = 'park-allocation'
ORDER BY event_ts DESC
LIMIT 25;

-- Top-of-stack convenience view (the current standing park-allocation CALL).
-- Now filters to call-shaped rows: a non-call row sharing this entry_type must never be able to shadow the
-- standing call, which is what happened on 2026-08-03 (see this file's header).
CREATE OR REPLACE VIEW `stock-trading-498512.state.park_allocation_latest` AS
SELECT * FROM `stock-trading-498512.state.park_allocation_recent`
WHERE is_call
ORDER BY event_ts DESC
LIMIT 1;

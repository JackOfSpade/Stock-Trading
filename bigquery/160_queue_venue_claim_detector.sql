-- Detector for a fabricated queue-item "resolving venue" claim, plus an undocumented analysis_type
-- value. Project: stock-trading-498512.
--
-- WHY THIS EXISTS (investigation dated 2026-08-10). events.queue_events has NO first-class column
-- naming which routine will resolve an item -- schema is event_id, event_ts, queue, item_key,
-- item_type, status, strategy, ticker, due_date, conservative_default, artifact_path, payload JSON,
-- note (bigquery/01_schema.sql:70-82). Two rows enqueued in August 2026 nonetheless asserted a
-- resolving venue INSIDE the untyped payload JSON, each inventing its own ad-hoc key:
--   * item_key 'research-deferral-GEV-D-20260809' (enqueued by M4 2026-08-03): payload
--     '"resolving_venue":"W5"' plus a rationale claiming M3 instructs due_date to fall on the next W5
--     run. No such instruction exists anywhere in M3's or M4's prompt body.
--   * item_key 'criteria-coverage-GOOGL-D-20260809' (enqueued by D2 2026-08-05): payload
--     '"owning_routine":"W3","escalation_routine":"Q3","analysis_type":"criteria-coverage-review"'.
-- Both items were queue='PENDING_ANALYSIS'. W2 reads queue history only to deduplicate its D1-originated
-- enrichment intake, and W4 idempotently writes PENDING_ANALYSIS handoffs; neither drains the queue.
-- W1/W3/W5 have no queue handling. D2 is the SOLE drainer of PENDING_ANALYSIS, stated in
-- Claude_Task_Plan.md at multiple sites (lines 62, 112, 116,
-- 295/297 as of 2026-08-10: "D2 (Daily Action Conversion) is the daily drainer... reads state.open_queue
-- (queue PENDING_ANALYSIS) and processes every entry with status: pending and due_date <= today").
-- (This comment previously cited "283-285, 455" -- 283-285 was correct only pre-2026-08-10, before a
-- concurrent same-day Gate B rewrite shifted this section down by 12 lines; 455 was already wrong even
-- pre-rewrite, an over-count landing on unrelated Decision_Log.md archival prose -- corrected here.)
-- D2's drain
-- predicate never reads any venue field. Both venue claims were therefore unhonorable fiction from the
-- moment they were written -- W5/W3/Q3 were never going to see either item under any name. Both items
-- were in fact drained by D2 on their due date (2026-08-09 GEV, per the D2 run that produced this
-- investigation; 2026-08-09/2026-08-10-adjacent GOOGL) and resolved correctly on the evidence actually
-- available, so no wrong action resulted this time -- but nothing in the system mechanically catches
-- this class, and a false venue claim misleads a future reader (human or routine) into believing a
-- domain-expert weekly/quarterly session reviewed an item when none ever could have. Exhaustively
-- searched 2026-08-10: zero hits for resolving_venue / owning_routine / escalation_routine anywhere in
-- bigquery/, scripts/, ops/, Claude_Task_Plan.md outside those two payload blobs.
--
-- THE QUEUE -> REAL-DRAINER MAP, verified against ops/cadence.yaml + Claude_Task_Plan.md on 2026-08-10
-- (see the `allowed_map` CTE below for the encoded form):
--   * PENDING_ANALYSIS -> D2 only. Claude_Task_Plan.md's "### Draining the queue" section (line 295 as
--     of 2026-08-10; the paragraph beginning "D2 (Daily Action Conversion) is the daily drainer" at line
--     297, cited alongside lines 62, 112, 116 above) names no other reader. ops/cadence.yaml:198
--     (`id: D2`) is the routine's sole registration; no other routine's cadence.yaml block or
--     Claude_Task_Plan.md section (`## D2. Daily Action Conversion`, line 1671 as of 2026-08-10) reads
--     PENDING_ANALYSIS.
--   * PENDING_REVIEW -> AR_att, AR_orc. Claude_Task_Plan.md, line 2670 as of 2026-08-10 ("Structured
--     adversarial reviews... are executed by a small set of generic routines that read entries from the
--     PENDING_REVIEW queue (state.open_queue / events.queue_events)... Triggering routines... enqueue
--     entries; they never invoke a review prompt directly.") -- the "small set" is exactly these two,
--     confirmed by ops/cadence.yaml:403 (`id: AR_att`) and :415 (`id: AR_orc`, `depends_on: [AR_att]`),
--     both `monitor_class: queue_driven`, gated on a PENDING_REVIEW entry being due.
--   * PENDING_DRAFT -> SL2 only. Claude_Task_Plan.md, line 3373 as of 2026-08-10 (`## SL2. Strategy
--     Draft, Revise & Post-mortem`) + line 3375 ("Queue-driven (fires Sun-Thu; no-ops unless a
--     PENDING_DRAFT item is due). The dedicated autonomous EDITORIAL routine of the lifecycle") +
--     line 3384 ("Scan PENDING_DRAFT for
--     the oldest due item and dispatch by item_type"). ops/cadence.yaml:445 (`id: SL2`) is the sole
--     registration reading PENDING_DRAFT; SL5 (roster mutation) reads AR_orc's verdict, never the
--     PENDING_DRAFT queue itself.
--   * WATCHLIST and ORDER_STAGED are deliberately OUTSIDE this map (mapped to an empty allowed-drainer
--     array below, so ANY venue-claim key found there is unconditionally unwired): WATCHLIST is
--     Strategy A's own persistent candidate list, drained inline by D1/D2/W1 as part of their ordinary
--     per-run walk, not by a due-date/venue handoff mechanism at all; ORDER_STAGED is the persist-and-
--     wait staged-order registry (state.open_orders), reconciled continuously by D2/D2a Step 0, again
--     with no venue concept. A payload asserting a resolving venue on either lane would be exactly as
--     unhonorable as the two founding incidents and this view treats it identically.
--
-- STATEMENT 1 -- state.queue_venue_claim_unwired. Surfaces every ACTIONABLE (latest status = 'pending')
-- queue row making a claim nothing in the system can honor, in two finding classes so one alert can
-- carry both:
--   (a) unwired_venue -- payload.resolving_venue / payload.owning_routine / payload.escalation_routine
--       names a routine that is NOT in that row's queue's real-drainer set above.
--   (b) unknown_analysis_type -- payload.analysis_type is outside the documented enum at
--       Claude_Task_Plan.md:285 (`thesis-construction | re-screen | research-deferral-checkpoint |
--       foundation-change-assessment | constraint-relaxation-review`) PLUS two values legitimised
--       2026-08-10: `criteria-coverage-review` (a concurrent session, sixth documented value, the exact
--       string 'criteria-coverage-GOOGL-D-20260809' carried in its own payload, above) and
--       `criterion-recheck` (a same-day follow-up session, seventh documented value -- this detector's
--       OWN founding validation pass below surfaced item_key 'recheck-CRM-crpo-D-20260812' using it
--       un-enumerated; see the allowlist comment in the `unknown_analysis_type` branch below and
--       Claude_Task_Plan.md's analysis_type enum, both updated the same session).
-- Latest-status resolution mirrors the house idiom in bigquery/01_schema.sql's state.open_queue_detail
-- (QUALIFY ROW_NUMBER() OVER (PARTITION BY queue, item_key ORDER BY event_ts DESC, event_id DESC) = 1,
-- the `event_id DESC` tiebreaker added below) rather than a
-- naive `WHERE status='pending'` on the raw append-only table -- queue_events carries one row per
-- status TRANSITION, so a completed item has BOTH a pending row (often the only one carrying the venue
-- claim) and a later complete row; filtering the raw table would resurface every historical item
-- forever. Verified live 2026-08-10 (read-only query against events.queue_events): both founding items'
-- LATEST row has status='complete' and this view returns zero rows for either item_key. Scoped strictly
-- to `status = 'pending'` (not "any non-terminal status") because PENDING_REVIEW's intermediate
-- 'attacker-complete' state is a routine, expected mid-cycle status -- see the exception carved out in
-- Claude_Task_Plan.md's `PENDING_REVIEW` (adversarial-review) exception paragraph (line 1799 as of
-- 2026-08-10) for D3's own due-date staleness scan -- not an unresolved actionable item in
-- the sense this detector cares about.
--
-- first_seen_ts is MIN(event_ts) across the item_key's ENTIRE history (a separate scan of the raw
-- table, since the latest-wins projection only keeps the newest row) -- for a PENDING_REVIEW item that
-- has cycled through multiple `pending` rows (a re-enqueued attacker/orchestrator cycle reuses the same
-- item_key with a fresh row, e.g. Claude_Task_Plan.md's echo-suspect cool-off requeue), this is the
-- item's original enqueue time, not the most recent cycle's.
--
-- LIVE VALIDATION (2026-08-10, read-only queries against events.queue_events): of the 5 currently-
-- pending PENDING_ANALYSIS rows, 5 PENDING_DRAFT rows (the premortem-{A,B,C,D,E}-2026-a3 SL2 revise
-- batch) and dozens of pending WATCHLIST rows, NONE carries a resolving_venue/owning_routine/
-- escalation_routine payload key -- finding class (a) is genuinely zero rows today. Finding class (b)
-- is NOT zero: item_key 'recheck-CRM-crpo-D-20260812' (queue PENDING_ANALYSIS, enqueued by D2
-- 2026-08-05 on D1's explicit request per its own note field, due 2026-08-12) carries
-- payload.analysis_type = 'criterion-recheck', a value absent from the documented enum and from every
-- other file in this repo (grepped 2026-08-10: zero other hits for the string "criterion-recheck").
-- Unlike the two founding incidents this item makes NO venue claim at all -- D2's drain predicate keys
-- only on status/due_date, so 'criterion-recheck' cannot misdirect the drain the way 'resolving_venue'
-- could -- but it is a real, live instance of exactly the documentation-drift class finding (b) exists
-- to catch (an ad-hoc analysis_type invented in the field that was never folded back into the
-- documented enum), and this file does NOT special-case it into the allowlist: doing so on a detector's
-- OWN founding validation pass would be tuning the view to force zero rather than reporting what it
-- found. Whether 'criterion-recheck' should become a 7th documented enum value (it is a coherent,
-- self-contained pattern: D1 defers a single not-yet-measurable invalidation criterion to the queue
-- with a conservative non-exit default, distinct from a full re-screen or a research-deferral
-- checkpoint) is a Claude_Task_Plan.md prose decision for a future session, out of scope for this file.
--
-- RESOLVED SAME DAY (2026-08-10, same-day follow-up session -- explicit task decision, not a
-- from-scratch relitigation): the open question immediately above was answered yes. Identical
-- reasoning to `criteria-coverage-review`'s own legitimisation applies -- D2's drain predicate never
-- gates on analysis_type (confirmed above), so an unenumerated value here carries no operational risk,
-- and raising a warning alert on legitimate in-flight work would be crying wolf on a board that is
-- itself a trading-gate input (a stale/spurious CRITICAL on this board has previously halted order
-- staging for an unrelated reason -- see the alert-cascade precedent this reasoning leans on). Both
-- Claude_Task_Plan.md's analysis_type enum (line 285 as of 2026-08-10, one dated parenthetical now
-- covering both values) and this file's own `unknown_analysis_type` allowlist below now document
-- 'criterion-recheck' alongside 'criteria-coverage-review'. Re-verified live 2026-08-10 after both
-- edits: state.queue_venue_claim_unwired returns ZERO rows (both finding classes). This is NOT the
-- view being tuned to force zero -- the documentation gap finding class (b) exists to catch is what
-- got closed; a genuinely new, still-undocumented analysis_type value will continue to surface here
-- exactly as designed.
--
-- STATEMENT 2 registers category 'queue_venue_claim_unwired' in ops.alert_policy, mirroring
-- bigquery/158_premortem_live_gate_defect_policy.sql's INSERT ... WHERE NOT EXISTS idempotent pattern
-- exactly, but with the OPPOSITE lifecycle: latching = FALSE (158's premortem_live_gate_defect is a
-- Markdown adjudication no view can re-check; this category is a live view membership test that clears
-- itself the moment the offending row leaves the view). CORRECTION (2026-08-10, same-session adversarial
-- review): this comment originally said no raise call against this view existed yet anywhere in
-- Claude_Task_Plan.md and that wiring one was "left to a future change." That was true only relative to
-- this file's own edit in isolation -- a concurrent session in the SAME task wired the call the sentence
-- below already names as "the natural fit": D3's QUEUE HYGIENE step now carries a VENUE-CLAIM HONORING
-- CHECK bullet (Claude_Task_Plan.md, immediately after the `queue_item_stale` HEAL-RESOLUTION paragraph,
-- currently lines 1795/1797) that reads this view every D3 cycle and calls
-- `ops.sp_raise_alert_once('warning','D3','queue_venue_claim_unwired', <message>, <TO_JSON_STRING(row)>)`
-- per row -- non-gating, explicitly stated to never halt D3. This registration therefore stops being
-- "proactive infrastructure ahead of its wiring" (the posture bigquery/149-153's headers describe for
-- still-unwired sibling categories) the moment both files land together; this file still defines NO
-- views/procedures beyond the one CREATE OR REPLACE VIEW and touches NO scheduled-query procedure, so
-- scripts/check_sq_version_registry.py has nothing to enforce here.
--
-- GAP FOUND AND CLOSED BY THIS SAME ADVERSARIAL REVIEW (2026-08-10, both halves same session). As
-- first landed, the VENUE-CLAIM HONORING CHECK paragraph the RAISE call above lives in had the RAISE
-- but NO heal-resolution clause -- unlike the `queue_item_stale` paragraph immediately above it, which
-- explicitly ends "HEAL-RESOLUTION: when a previously-flagged item is drained ... resolve its open
-- queue_item_stale alert via ... UPDATE ops.alerts SET resolved=TRUE ...". That meant nothing in
-- Claude_Task_Plan.md would ever have run the resolve_rule column's described "re-check the view for
-- the SAME item_key/finding_class, then UPDATE ops.alerts" step below -- Rules 1-4 of
-- ops.sp_auto_resolve_alerts don't cover this category either (documented two paragraphs down) -- so
-- an alert this category raised would have sat open on the board PERMANENTLY once the underlying item
-- was fixed, contradicting the latching=FALSE registration below, which exists specifically to sanction
-- a mechanical resolve. Closed the same session, in Claude_Task_Plan.md itself (not in this file): the
-- VENUE-CLAIM HONORING CHECK paragraph now carries its own HEAL-RESOLUTION sentence, keyed on the
-- `(item_key, finding_class)` pair exactly as the resolve_rule text below describes, mirroring
-- `queue_item_stale`'s ITEM 17 precedent. Verified 2026-08-10: `python3 scripts/split_task_plan.py
-- --check` and the full checker matrix (prose invariants, cadence consistency, gen_routine_lists) all
-- exit 0 after the fix.
-- latching = FALSE only unlocks this category for a routine-owned or mechanical resolve to be
-- SANCTIONED under ops.alert_policy's fail-closed allowlist (bigquery/34_alert_lifecycle.sql) -- it
-- does NOT, by itself, cause ops.sp_auto_resolve_alerts to clear a row: that procedure's Rules 1-4 are
-- hardcoded to the four categories missing_dependency/missed_run/routine_stalled/staleness only (see
-- its CREATE OR REPLACE PROCEDURE body, most recently bigquery/148_audit_2026_08_08_fixes.sql), none of
-- which name this category, and this file does not add a fifth rule (that would mean editing
-- ops.sp_auto_resolve_alerts, out of scope for this file and not a scheduled-query procedure but still
-- a shared object well beyond a one-file additive change). The resolve_rule text below therefore
-- describes the intended EVIDENCE-BASED, ROUTINE-OWNED resolve -- re-check this view for the same
-- item_key and UPDATE ops.alerts directly -- exactly the 'queue_item_stale' HEAL-RESOLUTION precedent
-- (Claude_Task_Plan.md line 1795 as of 2026-08-10, "ITEM 17 precedent"), with one deliberate difference: queue_item_stale
-- stays permanently ABSENT from ops.alert_policy by design (that section's own words), while this
-- category IS registered per this task's explicit instruction -- so a future reader must not assume
-- registration alone makes it self-clearing; the routine-owned check is what does.
--
-- Apply after bigquery/01_schema.sql (events.queue_events, state.open_queue_detail) and
-- bigquery/34_alert_lifecycle.sql (ops.alert_policy). Defines exactly one view and adds exactly one
-- ops.alert_policy row; no other object is created, redefined, or dropped.

-- SUPERSEDED LIVE by bigquery/225_regime_refresh_queue_lane.sql (2026-09-05) — that file is the
-- CURRENT canonical definition of state.queue_venue_claim_unwired. Chain: this file ->
-- bigquery/180_probe_register_queue_lane.sql (2026-08-18, adds the PENDING_ROSTER -> ['SL5'] lane to
-- allowed_map for the SL3 -> SL5 probe-register handoff) -> bigquery/199_queue_venue_claim_status_normalisation.sql
-- (2026-08-25, replaces the `candidates` CTE's case-sensitive `status = 'pending'` filter with
-- open_queue_detail's case-normalized terminal-status exclusion) -> bigquery/225 (2026-09-05, adds the
-- PENDING_REGIME_REFRESH -> ['M1R'] lane for the re-risking limb's out-of-cycle regime-refresh item).
-- Do NOT re-apply this file's view in isolation: doing so reverts ALL THREE changes at once — it
-- silently drops both added lanes (a lane missing from allowed_map is treated as "no legitimate venue
-- claim is possible here", so the first correct resolving_venue='SL5' probe-register row, or
-- resolving_venue='M1R' regime-refresh row, would be flagged as unwired), AND it re-blinds the
-- detector to every non-`pending` non-terminal status token, which is the condition bigquery/199
-- exists to end. The ops.alert_policy INSERT further down in THIS file remains canonical and is not
-- superseded.
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
    STRUCT('PENDING_DRAFT'    AS queue, ['SL2'] AS allowed_drainers)
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

INSERT INTO `stock-trading-498512.ops.alert_policy` (category, latching, resolve_rule, note)
SELECT p.category, p.latching, p.resolve_rule, p.note
FROM UNNEST([
  STRUCT(
    'queue_venue_claim_unwired' AS category,
    FALSE AS latching,
    CONCAT(
      'SELF-RESOLVING, view-membership condition -- NOT covered by any of ops.sp_auto_resolve_alerts ',
      'existing Rules 1-4 (those are hardcoded to missing_dependency/missed_run/routine_stalled/',
      'staleness only), so this row does not clear itself automatically merely by being registered ',
      'non-latching; latching=FALSE only SANCTIONS the resolve below under the fail-closed allowlist ',
      '(bigquery/34_alert_lifecycle.sql). D3 QUEUE HYGIENE (Claude_Task_Plan.md, VENUE-CLAIM HONORING ',
      'CHECK bullet, line 1797 as of 2026-08-10) is the owner -- its own HEAL-RESOLUTION sentence, ',
      'added 2026-08-10 mirroring the queue_item_stale ITEM 17 precedent immediately above it, ',
      're-checks the view for the SAME (item_key, finding_class) pair each cycle: SELECT 1 FROM ',
      'state.queue_venue_claim_unwired WHERE item_key = <payload item_key> AND finding_class = ',
      '<payload finding_class>. If that returns no row -- the item reached a terminal status, the ',
      'venue-claim payload key was corrected to name a real drainer, or the analysis_type value was ',
      'corrected or folded into the documented enum -- resolve with UPDATE ops.alerts SET ',
      'resolved=TRUE, resolved_ts=CURRENT_TIMESTAMP(), resolved_note=\'view no longer returns this ',
      'item_key/finding_class\' WHERE category=\'queue_venue_claim_unwired\' AND NOT resolved AND ',
      'JSON_VALUE(payload,\'$.item_key\')=<item_key> AND JSON_VALUE(payload,\'$.finding_class\')=',
      '<finding_class>. Never resolve on age or on a different item_key -- this is an evidence-based, ',
      'per-item resolve, same discipline as queue_item_stale, not a generic auto-age.'
    ) AS resolve_rule,
    CONCAT(
      'QUEUE-INTEGRITY CLASS, registered 2026-08-10 by proactive investigation (no firing yet as of ',
      'registration) -- events.queue_events has no first-class resolving-venue column, and two rows ',
      'enqueued in August 2026 (research-deferral-GEV-D-20260809 by M4; criteria-coverage-GOOGL-D-',
      '20260809 by D2) each invented an ad-hoc payload key (resolving_venue / owning_routine + ',
      'escalation_routine) naming a routine -- W5, W3, Q3 respectively -- that has never read ',
      'events.queue_events/state.open_queue anywhere in this repo and so could never have honored the ',
      'claim; the queue lane in question, PENDING_ANALYSIS, is drained solely by D2 ',
      '(Claude_Task_Plan.md lines 62/112/116/295/297 as of 2026-08-10). Both items were in fact drained correctly ',
      'by D2 on their due date -- no wrong action resulted -- but the false claim would have misled a ',
      'future reader into believing a domain-expert weekly/quarterly review was scheduled when none ',
      'was. Detector: state.queue_venue_claim_unwired (bigquery/160), which also independently flags ',
      'an undocumented payload.analysis_type value (finding_class=unknown_analysis_type) against the ',
      'enum at Claude_Task_Plan.md:285 -- founding validation 2026-08-10 already surfaced one live ',
      'instance, recheck-CRM-crpo-D-20260812 (analysis_type=criterion-recheck, enqueued by D2 on D1 ',
      'request 2026-08-05), a genuine documentation-drift case distinct from the two venue incidents -- ',
      'same-day follow-up session legitimised it identically to criteria-coverage-review, folding it ',
      'into both the documented enum and the unknown_analysis_type allowlist in this same file, so ',
      'this specific instance no longer appears in the view; the category stays registered for a ',
      'future genuinely-undocumented value. ',
      'Raise at warning, not critical, if a raise site is ever wired: an open critical sets ',
      'state.trading_enabled=FALSE (bigquery/107_halt_echo_missed_run_gate.sql among others), and a ',
      'misleading venue claim or an undocumented taxonomy value is not a reason to halt order staging ',
      '-- both founding incidents drained correctly on the merits regardless of the claim. Sibling ',
      'proactive-registration classes: premortem_live_gate_defect (bigquery/158), ',
      'prompt_injection_attempt (bigquery/138), append_only_violation (bigquery/139) -- this row keeps ',
      'that same accident-of-absence discipline for a class discovered before its first firing rather ',
      'than after.'
    ) AS note
  )
]) AS p
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.ops.alert_policy` e WHERE e.category = p.category
);

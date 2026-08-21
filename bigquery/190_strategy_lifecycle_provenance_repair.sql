-- events.strategy_lifecycle provenance repair + detector for the two defect classes it exposed.
-- Project: stock-trading-498512. Written by the alert-triage session of 2026-08-21, immediately after
-- closing the last open handoff_contract_unpinned notice (alert 0e9703ec, SL5 STEP 0 heal executed out
-- of band against fdab1db). Both defects were found by the step-4 "no capital affected" sweep that
-- notice required -- i.e. by reading the table the branch-(3) contract governs, not by a routine.
--
-- WHY:
--   * MISSING CREATION ROW (REPAIRED BELOW). Strategy H carried exactly ONE events.strategy_lifecycle
--     row -- CANDIDATE -> REJECTED, 2026-08-03 22:11:05.030884Z, driver_routine 'SL1' -- and no row
--     recording it ENTERING candidacy. Claude_Task_Plan.md SL1 STEP 2 pins "a CANDIDATE
--     events.strategy_lifecycle row (to_state=CANDIDATE, driver_routine='SL1')" as part of emitting a
--     candidate, and SL1's 2026-07-27 run wrote exactly that row for BOTH F and G. Its 2026-08-03 run
--     wrote H's REJECTED transition without the row it transitions FROM, so H's earliest row declares
--     from_state='CANDIDATE' for a state the log never records the code entering.
--     state.strategy_roster.current_state reads the LATEST row per code and therefore reads 'REJECTED'
--     correctly -- which is precisely why this survived: the OUTCOME is right and only the provenance
--     is absent, so nothing downstream ever disagreed and no gate ever went red.
--   * AMBIGUOUS LATEST ROW (DETECTED, NOT REWRITTEN -- see ACCEPTED HISTORICAL on the view below).
--     F and G each carry their CANDIDATE and REJECTED rows at the IDENTICAL event_ts, to the
--     microsecond: 2026-07-28 06:10:29.279889Z, all four rows. state.strategy_roster
--     (bigquery/35_strategy_arsenal.sql:301-307) resolves the current state with
--     QUALIFY ROW_NUMBER() OVER (PARTITION BY strategy_code ORDER BY event_ts DESC, event_id DESC) = 1,
--     so on an event_ts tie the winner is decided by event_id -- a GENERATE_UUID() value, i.e. an
--     arbitrary one. MEASURED live 2026-08-21: F resolves REJECTED (7c2b31f2...) over CANDIDATE
--     (323f9437...), G resolves REJECTED (9a6b23f1...) over CANDIDATE (325a281f...). Both happen to
--     sort the right way. Had either UUID sorted the other way, state.strategy_roster would report a
--     default-REJECTED candidate as CANDIDATE -- reopening a code whose 90-day archetype cooldown is
--     keyed off the REJECTED row (bigquery/133_sl1_research_leads_and_record_corrections.sql). The
--     roster is correct today by luck, not by construction. The luck is stable (event_id never
--     changes, so the tiebreak is deterministic and F/G are terminal), which is why the two live pairs
--     are ACCEPTED rather than rewritten -- events.strategy_lifecycle is append-only and
--     state.append_only_integrity halts on an out-of-band UPDATE. Recurrence is what gets prevented,
--     in prose (SL1 STEP 2, same commit) and mechanically (the detector below).
--
-- WHY NOT bigquery/35. That file's header mandates that "every subsequent SL5 adoption/termination
-- MUST append its own guarded, idempotent INSERT here", because check_roster_consistency.py R-A parses
-- THAT FILE ONLY (scripts/check_roster_consistency.py:200 ARSENAL_SQL, :774 seed_active_codes) to build
-- the seed side of its comparison. That mandate is scoped to roster-ACTIVE transitions: R-A's
-- ACTIVE_STATES_SQL is {PROBE, ADOPTED}, and CANDIDATE/REJECTED rows are outside it. Consistently,
-- F's, G's and H's live CANDIDATE/REJECTED rows have NEVER been mirrored into bigquery/35 -- it holds
-- exactly one INSERT, the founding A-E seed. This repair is an SL1-era candidate-provenance
-- correction, not an SL5 adoption or termination, so it lands here and R-A is unaffected either way.
--   Do NOT "fix" this by moving the INSERT into bigquery/35: that would put a non-roster-active row
-- into the file whose sole documented purpose is the R-A active-set comparison.
--
-- Depends on bigquery/35 (events.strategy_lifecycle DDL + state.strategy_roster), bigquery/34
-- (ops.alert_policy fail-closed allowlist), bigquery/10 (ops.sp_raise_alert_once).
-- Creates one VIEW; both INSERTs are NOT-EXISTS-guarded. Idempotent; safe to re-run.

-- ============================================================================
-- 1. REPAIR -- H's missing NULL -> CANDIDATE creation row.
--
-- event_ts is BACKDATED to 22:11:04 UTC, ~1.03s BEFORE H's existing REJECTED row
-- (22:11:05.030884Z), for two independent reasons:
--   (a) state.strategy_roster picks the latest row per code. A row stamped CURRENT_TIMESTAMP() would
--       make H's current_state read CANDIDATE -- reopening a rejected candidate and bypassing the
--       archetype cooldown. Backdating is what keeps H reading REJECTED. Asserted at the end of this
--       file.
--   (b) It is stamped STRICTLY BEFORE rather than EQUAL to the REJECTED row precisely so it does not
--       create a third instance of the ambiguous-latest defect class documented above. F and G show
--       what an equal stamp costs.
-- The exact emission instant was never recorded, so this is a reconstruction, not a recovered fact --
-- hence driver_routine 'repair-2026-08-21' rather than 'SL1'. An audit reading this row must be able
-- to tell it was authored by a repair and not by the routine whose write was missed; the founding
-- batch uses the same convention ('seed-2026-07-10'). Nothing in the repo validates driver_routine
-- against a domain (verified 2026-08-21: no accepted_values, no CHECK, no python check), so the
-- honest value is free to be the honest one.
-- Guard is SEMANTIC (strategy_code + to_state), not batch-keyed: if a real SL1 CANDIDATE row for H
-- ever turns up, this must stay a no-op rather than duplicate it.
-- ============================================================================
INSERT INTO `stock-trading-498512.events.strategy_lifecycle`
  (event_ts, strategy_code, from_state, to_state, driver_routine, note)
SELECT TIMESTAMP '2026-08-03 22:11:04+00', code, CAST(NULL AS STRING), 'CANDIDATE', 'repair-2026-08-21',
  -- Triple-quoted: BigQuery does NOT read '' as an escaped apostrophe inside a single-quoted string
  -- (it reads two adjacent literals and errors "concatenated string literals must be separated"),
  -- so any note carrying an apostrophe uses the ''' form -- the same idiom bigquery/133 uses.
  '''PROVENANCE REPAIR (2026-08-21, bigquery/190): reconstructed creation row for candidate H. SL1 STEP 2 pins a CANDIDATE lifecycle row (to_state=CANDIDATE, driver_routine=SL1) on every candidate emission and SL1 wrote one for both F and G on 2026-07-28, but its 2026-08-03 run wrote H's CANDIDATE->REJECTED transition (event_id 2927f80f-9890-4da9-a4ae-84c4a821ba18, 22:11:05.030884Z) with no row recording H entering candidacy. Backdated ~1s before that REJECTED row so H's current_state stays REJECTED and so this row does not tie with it. Reconstruction, not a recovered fact: the true emission instant was never recorded, hence driver_routine=repair-2026-08-21 rather than SL1. H remains REJECTED with its original 90-day archetype cooldown intact; this row adds provenance only and reopens nothing.'''
FROM UNNEST(['H']) AS code   -- supplies the FROM the NOT-EXISTS guard needs; founding-seed idiom
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.events.strategy_lifecycle`
  WHERE strategy_code = 'H' AND to_state = 'CANDIDATE');

-- ============================================================================
-- 2. DETECTOR -- state.strategy_lifecycle_provenance
--
-- bigquery/35's own DDL comment observed that "no check validates lifecycle chaining
-- (state.append_only_integrity polices UPDATE/DELETE on append-only tables, not state adjacency)".
-- That was accurate, and it is what let H's gap sit unnoticed for 18 days. This view is the narrowest
-- check that would have caught it, plus the sibling ordering defect found alongside it.
--
-- DELIBERATELY NOT a general adjacency check. bigquery/35 documents that SL2 STEP 5 collapses the
-- AUTHORING work phase into ONE row written from_state='AUTHORING', to_state='UNDER_REVIEW', whose
-- from_state does NOT chain to the prior row's to_state ('QUALIFYING') -- a sanctioned shape. A
-- general chaining check would flag that forever. CLASS 1 anchors on a code's EARLIEST row only,
-- which the AUTHORING row can never be, so the sanctioned shape is structurally exempt rather than
-- exempted by a special case that could rot.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.strategy_lifecycle_provenance` AS
WITH ranked AS (
  SELECT
    strategy_code, event_id, event_ts, from_state, to_state, driver_routine,
    ROW_NUMBER()  OVER (PARTITION BY strategy_code ORDER BY event_ts ASC, event_id ASC) AS rn_earliest,
    COUNT(*)      OVER (PARTITION BY strategy_code, event_ts)                           AS n_at_this_ts,
    MAX(event_ts) OVER (PARTITION BY strategy_code)                                     AS latest_ts
  FROM `stock-trading-498512.events.strategy_lifecycle`
),
findings AS (
  -- CLASS 1 -- the code's earliest row already declares a from_state, so the log never records the
  -- code entering the state it claims to be leaving. H's defect, repaired above.
  SELECT 'missing_creation_row' AS finding_class,
         strategy_code, event_id, event_ts, from_state, to_state, driver_routine,
         CONCAT('events.strategy_lifecycle: earliest row for strategy ', strategy_code,
                ' declares from_state=', IFNULL(from_state, 'NULL'),
                ' but no row records ', strategy_code, ' entering that state',
                ' -- the creation row was never written') AS message
  FROM ranked
  WHERE rn_earliest = 1 AND from_state IS NOT NULL

  UNION ALL

  -- CLASS 2 -- two or more rows tie at the code's latest event_ts, so
  -- state.strategy_roster.current_state is settled by the event_id (UUID) tiebreak rather than by the
  -- order the writing routine intended. F/G's defect.
  SELECT 'ambiguous_latest_row',
         strategy_code, event_id, event_ts, from_state, to_state, driver_routine,
         CONCAT('events.strategy_lifecycle: ', CAST(n_at_this_ts AS STRING), ' rows for strategy ',
                strategy_code, ' share the latest event_ts (', CAST(event_ts AS STRING),
                ') -- state.strategy_roster.current_state is decided by the event_id UUID tiebreak,',
                ' not by the intended transition order') AS message
  FROM ranked
  WHERE event_ts = latest_ts AND n_at_this_ts > 1
)
SELECT
  f.*,
  -- ACCEPTED HISTORICAL -- pinned to the exact (code, microsecond) of the two 2026-07-28 SL1 pairs.
  -- Both are terminal REJECTED candidates whose tiebreak demonstrably resolves the RIGHT way and
  -- cannot change (event_id is immutable and no further row will ever be written for a rejected
  -- code), and the table is append-only so they cannot be restamped. Pinned narrowly by timestamp
  -- rather than by code alone so that a NEW tie on F or G would still alert. Do NOT widen this.
  (f.finding_class = 'ambiguous_latest_row'
   AND f.strategy_code IN ('F', 'G')
   AND f.event_ts = TIMESTAMP '2026-07-28 06:10:29.279889+00') AS accepted_historical
FROM findings f;

-- ============================================================================
-- 3. POLICY -- register lifecycle_provenance_gap in the fail-closed allowlist.
-- An unregistered category latches by construction (bigquery/34_alert_lifecycle.sql), which would
-- demand a human resolve on a class the SISA posture wants mechanical -- the same reason the
-- branch-(3) fanout-completeness findings were recorded under an existing category rather than a new
-- one (see alert 0e9703ec's payload).
-- ============================================================================
INSERT INTO `stock-trading-498512.ops.alert_policy` (category, latching, resolve_rule, note)
SELECT p.category, p.latching, p.resolve_rule, p.note
FROM UNNEST([
  STRUCT(
    'lifecycle_provenance_gap' AS category,
    FALSE AS latching,
    CONCAT(
      'SELF-RESOLVING, view-membership condition -- NOT covered by any of ops.sp_auto_resolve_alerts ',
      'existing rules (those are hardcoded to missing_dependency/missed_run/routine_stalled/',
      'catchup_refire_blocked/staleness plus the roster-notice rule), so this row does not clear ',
      'itself automatically merely by being registered non-latching; latching=FALSE only SANCTIONS ',
      'the resolve below under the fail-closed allowlist (bigquery/34_alert_lifecycle.sql). D3 QUEUE ',
      'HYGIENE is the owner -- its LIFECYCLE-PROVENANCE CHECK bullet (sibling to ',
      'queue_venue_claim_unwired and cash_flow_source_unknown in the same step) polls ',
      'state.strategy_lifecycle_provenance and, when a previously-flagged (strategy_code, ',
      'finding_class) pair no longer appears with accepted_historical = FALSE, resolves the open ',
      'alert scoped by that pair. Evidence is the view no longer returning the pair. NEVER resolve on ',
      'age: a missing creation row is silent by construction -- the outcome stays correct and only ',
      'provenance is absent -- so an aged-out row is indistinguishable from a repaired one.'
    ) AS resolve_rule,
    CONCAT(
      'LIFECYCLE-INTEGRITY CLASS, registered 2026-08-21 by the alert-triage session that repaired ',
      'the missing CANDIDATE creation row for strategy H (bigquery/190). Two finding classes: ',
      'missing_creation_row (the earliest events.strategy_lifecycle row for a code declares a ',
      'from_state the log never records it entering -- H, 2026-08-03, repaired) and ',
      'ambiguous_latest_row (rows tie at the latest event_ts for a code, so ',
      'state.strategy_roster.current_state is settled by the ',
      'event_id UUID tiebreak -- F and G, 2026-07-28, ACCEPTED HISTORICAL on the view and therefore ',
      'never alerted). Recurrence is prevented in prose at SL1 STEP 2 (same commit), which now pins ',
      'both the creation row and strictly-increasing event_ts within one batch.'
    ) AS note
  )
]) AS p
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.ops.alert_policy` e WHERE e.category = p.category);

-- ============================================================================
-- 4. VERIFY -- fail loudly if the repair did not land exactly as intended (bigquery/133 precedent).
-- ============================================================================
ASSERT (SELECT COUNT(*) FROM `stock-trading-498512.events.strategy_lifecycle`
        WHERE strategy_code = 'H' AND to_state = 'CANDIDATE') = 1
  AS 'bigquery/190: expected exactly one H CANDIDATE row after repair';

ASSERT (SELECT current_state FROM `stock-trading-498512.state.strategy_roster`
        WHERE strategy_code = 'H') = 'REJECTED'
  AS 'bigquery/190: repair moved H off REJECTED -- the backdated event_ts failed to stay behind the REJECTED row';

ASSERT (SELECT COUNT(*) FROM `stock-trading-498512.state.strategy_lifecycle_provenance`
        WHERE finding_class = 'missing_creation_row') = 0
  AS 'bigquery/190: missing_creation_row findings remain after repair';

ASSERT (SELECT COUNT(*) FROM `stock-trading-498512.state.strategy_lifecycle_provenance`
        WHERE NOT accepted_historical) = 0
  AS 'bigquery/190: unaccepted lifecycle-provenance findings remain -- investigate before landing';

-- 214_park_reentry_breadth_count_correction.sql (2026-09-04)
-- Project: stock-trading-498512. Correct a mis-stated consecutive-session COUNT inside the
-- 2026-09-03 PARK ALLOCATION CALL record, WITHOUT superseding it.
-- Apply after 122_decision_correction_append_only.sql, 133_..._record_corrections.sql and
-- 213_park_derisk_record_correction.sql (whose header this file follows in form and reasoning).
-- Creates NO object -- CALL only, so scripts/check_live_sql_parity.py is unaffected by construction.
--
-- DUPLICATE PREFIX, DELIBERATE AND HARMLESS -- do NOT renumber either file. There is a twin
-- `214_account_fee_recording.sql`, landed by a concurrent session the same evening (it was authored as
-- 213, collided with 213_park_derisk_record_correction.sql, and was renumbered to 214 while this file
-- was being written -- the same independent "pick the next number" race CLAUDE.md documents for the
-- 114_* and 185_* pairs). The pair is SAFE by the test CLAUDE.md sets: the two files touch DISJOINT
-- objects, and in the strongest possible form -- the twin creates/replaces views
-- (state.cash_flow_source_unknown, state.book_drawdown_watch, state.cash_flows_backfill_check) while
-- THIS file creates no object at all and only appends one events.decision_log row. Apply-in-order
-- replay therefore reaches the same end state in either order, and lexical sort makes that order
-- deterministic regardless. Renumbering this file would additionally FALSIFY an already-immutable
-- record: the correction row written below cites "bigquery/214" in its body_md, and events.* is
-- append-only, so the citation cannot be edited afterwards.


--
-- ============================ WHY ================================================================
-- events.decision_log entry_id feb07fa0-59fe-48d7-a052-52ebb7269828 (D1 2026-09-03 PARK ALLOCATION
-- CALL, SWITCH SGOV -> VOO, MEDIUM 60) scores re-entry clause (a) as cleared partly because breadth
-- is "a third consecutive improving session (62.62 -> 64.21 -> 66.40)".
--
-- Measured from events.regime_events key='EQUITY_BREADTH_PCT' (the authoritative daily series, written
-- by D1's EQUITY-BREADTH OBSERVATION step and read by D2a STEP 1e):
--   2026-08-31  66.20   step -2.58
--   2026-09-01  62.62   step -3.58   <- the de-risk session; breadth FELL
--   2026-09-02  64.21   step +1.59   <- improvement 1
--   2026-09-03  66.40   step +2.19   <- improvement 2
-- Three readings span TWO improvements, and the session immediately before them (09-01) was the
-- largest single-session NARROWING in the series. So it is the SECOND consecutive improving session,
-- not the third.
--
-- ============================ WHY THIS ONE IS NOT LOAD-BEARING ==================================
-- Stated plainly so a future reader does not over-correct: the DECISION is unaffected and stands.
-- The inherited clause (a), written by the 2026-09-01 call, reads "breadth stabilising two sessions,
-- or any reading back above ~66". BOTH limbs are genuinely satisfied by the measured series:
--   * "stabilising two sessions" -> 09-02 (+1.59) and 09-03 (+2.19) are two consecutive improvements;
--   * "any reading back above ~66" -> 66.40 > 66.
-- The clause asked for TWO and got TWO. The record overstates the count while describing a condition
-- that genuinely cleared, so clause (a) is correctly scored CLEARED and the 09-03 re-risk is NOT
-- retracted, NOT weakened in its conclusion, and NOT reopened by this note.
--
-- ============================ WHY IT IS STILL WORTH RECORDING ===================================
-- This is the SECOND count in two consecutive park records overstated in the direction of the call.
-- bigquery/213 corrected the 2026-09-01 de-risk record ("eight of eleven GICS sectors lower";
-- measured seven, with all three defensives plus energy higher, making the corrected pattern
-- defensive rotation). That one WAS load-bearing. This one is not. The PATTERN across the pair is the
-- finding, and it is the strongest available argument for the DE-RISK EVIDENCE CARDINALITY rule
-- (Claude_Task_Plan.md D1 PARK ALLOCATION CALL, Operating_Protocols.md 13.F, fixture PA-07): if a
-- single cited statistic in these records is not reliable to one unit, then no SINGLE statistic
-- should be able to move ~97% of NAV on its own. Recording only the load-bearing error and silently
-- dropping the harmless one would understate that pattern to exactly the degree that makes it look
-- like an isolated slip rather than a class.
--
-- ============================ WHY A NOTE AND NOT A SUPERSEDING REPLACEMENT ======================
-- The same hazard as bigquery/213, and here it is STRICTLY WORSE, because feb07fa0 is not a historical
-- row -- at the time of writing it IS state.park_allocation_latest, the CURRENT call. Recall:
--   state.park_allocation_latest = SELECT * FROM state.park_allocation_recent
--                                  WHERE is_call ORDER BY event_ts DESC LIMIT 1
-- A superseding replacement would therefore REWRITE THE LIVE CALL that D2's PARK ALLOCATION CONVERSION
-- step reads and that the currently-staged SGOV -> VOO instruction pair derives from, and would
-- simultaneously drop the original out of state.decision_log_current. Use the standalone
-- entry_type='correction' note form (bigquery/122's non-replacement carve-out), which
-- state.park_allocation_recent never sees because it filters entry_type='park-allocation'.
-- FUTURE SESSIONS: do not convert this note into a superseding row. See 213's header for the full
-- argument and the view definitions to re-read first.
--
-- ============================ RE-APPLY SAFETY ===================================================
-- ops.sp_log_decision mints a fresh UUID per call, so an unguarded DR re-apply would DUPLICATE this
-- note. The IF NOT EXISTS guard keys on the refs entry naming the target, exactly as 213 does.
-- Idempotent: re-running this file is a no-op. The file-level raw events.decision_log reads (the guard
-- and the superseded_by assertion) are allowlisted in scripts/check_superseded_by_discipline.py with
-- the same reason 213 carries.

IF NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.events.decision_log`
  WHERE entry_type = 'correction'
    AND 'decision:feb07fa0-59fe-48d7-a052-52ebb7269828' IN UNNEST(refs)
) THEN
  CALL `stock-trading-498512.ops.sp_log_decision`(
    DATE '2026-09-04',
    'correction',
    NULL,
    NULL,
    'CORRECTED',
    NULL,
    NULL,
    NULL,
    r"""Recorded even though it changes no decision: suppressing the harmless twin of a load-bearing error would make a two-record pattern look like an isolated slip.""",
    r"""CORRECTION 2026-09-04 - the 2026-09-03 park re-risk record calls breadth a third consecutive improving session; measured, it is the second (the clause it clears asked for two, so the decision stands)""",
    r"""CORRECTION NOTE, NOT A REPLACEMENT. This does NOT supersede events.decision_log entry_id feb07fa0-59fe-48d7-a052-52ebb7269828 (D1 2026-09-03 PARK ALLOCATION CALL, SWITCH SGOV -> VOO, MEDIUM 60) and deliberately leaves superseded_by NULL. See bigquery/214 header and bigquery/213 for why the superseding form is unsafe here - feb07fa0 is at time of writing state.park_allocation_latest, the CURRENT call D2 reads, so a superseding row would rewrite the live call and the staged instruction pair derived from it.

THE DEFECT. The record scores re-entry clause (a) partly on breadth being "a third consecutive improving session (62.62 -> 64.21 -> 66.40)". Measured from events.regime_events key=EQUITY_BREADTH_PCT: 2026-08-31 66.20 (step -2.58), 2026-09-01 62.62 (step -3.58), 2026-09-02 64.21 (step +1.59), 2026-09-03 66.40 (step +2.19). Three readings span TWO improvements, and the session immediately preceding them was the largest single-session NARROWING in the series. It is the SECOND consecutive improving session, not the third.

THE DECISION IS UNAFFECTED AND STANDS. The inherited clause (a), written by the 2026-09-01 call, reads "breadth stabilising two sessions, or any reading back above ~66". Both limbs are genuinely satisfied: 09-02 and 09-03 are two consecutive improvements, and 66.40 is above 66. The clause asked for TWO and got TWO. Clause (a) is correctly scored CLEARED. The 2026-09-03 re-risk is NOT retracted, NOT weakened, and NOT reopened by this note. A reader who takes this correction as grounds to revisit that call has over-read it.

WHY RECORD IT AT ALL. This is the SECOND count in two consecutive park records overstated in the direction of the call. bigquery/213 corrected the 2026-09-01 de-risk record, which stated eight of eleven GICS sector ETFs closed lower when seven did, with all three defensives plus energy higher - making the corrected pattern defensive rotation rather than indiscriminate repricing. THAT one was load-bearing; this one is not. The PATTERN across the pair is the finding, and it is the strongest available argument for the DE-RISK EVIDENCE CARDINALITY rule (Claude_Task_Plan.md D1 PARK ALLOCATION CALL, Operating_Protocols.md 13.F, golden fixture PA-07): if a single cited statistic in these records is not reliable to one unit, no SINGLE statistic should be able to move roughly 97 percent of NAV on its own. Recording only the load-bearing error would understate that pattern precisely to the degree that makes it look like an isolated slip rather than a class.

CONTEXT. Found while answering an owner question about what broke the thesis behind the 2026-09-01 VOO -> SGOV de-risk, during the same interactive audit of the 09-01 to 09-03 round trip that produced bigquery/213 and the cardinality rule. The breadth series was pulled from events.regime_events rather than from either record prose, which is what surfaced the miscount.""",
    r"""{"corrected_claim":"a third consecutive improving session","measured":"the second consecutive improving session","series_source":"events.regime_events key=EQUITY_BREADTH_PCT","breadth_2026_08_31":66.20,"breadth_2026_09_01":62.62,"breadth_2026_09_02":64.21,"breadth_2026_09_03":66.40,"improvements_in_run":2,"clause_a_required":"stabilising two sessions OR any reading above ~66","clause_a_cleared":true,"load_bearing":false,"decision_retracted":false,"target_entry_id":"feb07fa0-59fe-48d7-a052-52ebb7269828","target_entry_date":"2026-09-03","target_entry_type":"park-allocation","supersedes_target":false,"sibling_correction":"bigquery/213"}""",
    ['decision:feb07fa0-59fe-48d7-a052-52ebb7269828','decision:5722994d-d798-468b-a8da-fdd9e6e13b60'],
    ['correction','park-allocation-record','measurement','park_allocator','non-load-bearing'],
    NULL,
    'interactive 2026-09-03 park round-trip audit'
  );
END IF;

-- Post-condition: exactly one such note, not superseding anything, and the corrected target must
-- REMAIN the live park call (this correction must not have disturbed what D2 reads).
ASSERT (
  SELECT COUNT(*) = 1 AND LOGICAL_AND(superseded_by IS NULL)
  FROM `stock-trading-498512.events.decision_log`
  WHERE entry_type = 'correction'
    AND 'decision:feb07fa0-59fe-48d7-a052-52ebb7269828' IN UNNEST(refs)
) AS 'park re-entry breadth-count note: expected exactly one row, with superseded_by NULL.';

ASSERT (
  SELECT entry_id = 'feb07fa0-59fe-48d7-a052-52ebb7269828'
  FROM `stock-trading-498512.state.park_allocation_latest`
) AS 'the 2026-09-03 call must REMAIN state.park_allocation_latest after this note lands.';

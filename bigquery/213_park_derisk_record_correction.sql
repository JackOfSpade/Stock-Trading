-- 213_park_derisk_record_correction.sql (2026-09-03)
-- Project: stock-trading-498512. Correct ONE mis-measured supporting statistic inside the
-- 2026-09-01 PARK ALLOCATION CALL record, WITHOUT superseding that record.
-- Apply after 122_decision_correction_append_only.sql (the correction convention),
-- 133_sl1_research_leads_and_record_corrections.sql (the IF NOT EXISTS re-apply guard pattern this
-- file copies) and 212_park_scorecard_ai_era_rebase.sql. Creates NO object -- CALL only, so
-- scripts/check_live_sql_parity.py has nothing to compare here and is unaffected by construction.
--
-- ============================ WHY ================================================================
-- events.decision_log entry_id 5722994d-d798-468b-a8da-fdd9e6e13b60 (D1 2026-09-01 PARK ALLOCATION
-- CALL, SWITCH VOO -> SGOV, MEDIUM 60) states that EIGHT of eleven GICS sector ETFs closed lower.
-- Measured this session: SEVEN closed lower, FOUR closed higher.
--   down  XLY -1.72, XLK -1.53, XLI -1.37, XLB -1.18, XLF -0.88, XLC -0.52, XLRE -0.16
--   up    XLE +1.27, XLU +0.78, XLV +0.66, XLP +0.32
-- Robust across extended hours, the Vanguard sector family, and FMP.
--
-- The miscount runs in the FLATTERING direction. The figure was recruited to support a claim of
-- broad, indiscriminate repricing; corrected, the pattern is DEFENSIVE ROTATION (all three defensive
-- sectors plus energy higher), which is WEAKER support for that claim. It is also the only figure in
-- that entry carrying no named provenance, in an entry that pins contract IDs and date ranges on
-- everything else. Every OTHER measurement in that record reproduces exactly -- including the 10Y at
-- 4.79 described as a 20-month high (last print at or above 4.79 was 2025-01-13; the runner-up across
-- the whole span is 4.67 on 2026-05-19). The de-risk is NOT retracted; only the weight of one
-- corroborating leg changes.
--
-- ============================ WHY A NOTE AND NOT A SUPERSEDING REPLACEMENT =======================
-- bigquery/122 permits both forms and reserves the standalone entry_type='correction' row for a
-- "non-replacement note". This is that case, and here the replacement form is actively DANGEROUS.
-- Both live view definitions were read before choosing (do the same before revisiting):
--
--   state.park_allocation_latest = SELECT * FROM state.park_allocation_recent
--                                  WHERE is_call ORDER BY event_ts DESC LIMIT 1
--   state.park_allocation_recent = ... FROM state.decision_log_current
--                                  WHERE entry_type = 'park-allocation'
--                                  is_call := JSON_VALUE(fields,'$.status') IS NOT NULL
--
-- A superseding park-allocation replacement carrying status='BOUND' would:
--   (a) take the NEWEST event_ts and therefore BECOME state.park_allocation_latest -- which D2's
--       PARK ALLOCATION CONVERSION step reads as the CURRENT call. That is a stale VOO -> SGOV
--       de-risk, and D2 would convert it: a real trade, undoing the 2026-09-03 re-risk and producing
--       a second, entirely spurious round trip on top of the one this whole audit was about; AND
--   (b) simultaneously drop the original 2026-09-01 call out of state.decision_log_current (readers
--       exclude the row NAMED by superseded_by), erasing it from the every-day calibration record
--       that the "log every call, including KEEP days" rule exists to build.
-- Omitting `status` to dodge (a) still causes (b). A correction note has NEITHER failure mode,
-- because park_allocation_recent filters entry_type='park-allocation' and never sees this row.
-- VERIFIED LIVE after the CALL below ran: state.park_allocation_latest still returns
-- feb07fa0-59fe-48d7-a052-52ebb7269828 (the 2026-09-03 re-risk, VOO, BOUND), the 2026-09-01 call is
-- still present in park_allocation_recent with is_call=TRUE, and state.embedding_health reports
-- 0 missing / 0 error / 0 dup, is_healthy=TRUE.
--
-- ============================ CONTEXT ============================================================
-- Found during an interactive-session audit of the 2026-09-01 -> 2026-09-03 VOO -> SGOV -> VOO park
-- round trip. Measured cost 214.32 USD to the 09-03 close (foregone VOO appreciation 215.61 against
-- 3.03 SGOV carry and 1.75 commissions; execution was clean and slippage was 12.88 FAVORABLE), plus
-- 107.73 USD of the 149.18 USD realized loss disallowed as a wash sale (state.wash_sale_exposure),
-- with the 09-04 rebuy capturing essentially the remainder. The STRUCTURAL finding from that audit
-- landed separately and is NOT in this file: the DE-RISK EVIDENCE CARDINALITY rule (a de-risk
-- converts only when at least two INDEPENDENT evidence axes fire; the 09-01 exit fired on ONE,
-- breadth, while the 09-03 re-entry required TWO) in Claude_Task_Plan.md's D1 PARK ALLOCATION CALL
-- step and Operating_Protocols.md 13.F, with golden fixture PA-07.
--
-- ============================ RE-APPLY SAFETY ===================================================
-- sp_log_decision mints a fresh UUID per call, so an unguarded re-apply during a DR rebuild would
-- DUPLICATE this note. The IF NOT EXISTS guard below keys on the refs entry naming the target,
-- mirroring bigquery/133's guard (which keys on superseded_by -- unavailable here precisely because
-- this row deliberately does not set it). Idempotent: re-running this file is a no-op.

IF NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.events.decision_log`
  WHERE entry_type = 'correction'
    AND 'decision:5722994d-d798-468b-a8da-fdd9e6e13b60' IN UNNEST(refs)
) THEN
  CALL `stock-trading-498512.ops.sp_log_decision`(
    DATE '2026-09-03',
    'correction',
    NULL,
    NULL,
    'CORRECTED',
    NULL,
    NULL,
    NULL,
    r"""The correction is stated against its own interest: the corrected count WEAKENS the case the original number was recruited to support, and the de-risk it corrects is explicitly NOT retracted.""",
    r"""CORRECTION 2026-09-03 - the 2026-09-01 park de-risk record overstates its sector-breadth statistic (states eight of eleven lower; measured seven)""",
    r"""CORRECTION NOTE, NOT A REPLACEMENT. This does NOT supersede events.decision_log entry_id 5722994d-d798-468b-a8da-fdd9e6e13b60 (D1 2026-09-01 PARK ALLOCATION CALL, SWITCH VOO -> SGOV, MEDIUM 60) and deliberately leaves superseded_by NULL. Reason: the DECISION that row records is not withdrawn, the call bound and converted as logged, and the park movement it produced is real history. Exactly ONE supporting statistic inside its body_md is wrong. Per bigquery/122_decision_correction_append_only.sql, a standalone entry_type=correction row is the sanctioned mechanism for a non-replacement note; a superseding replacement was considered and REJECTED here for a concrete safety reason recorded below.

THE DEFECT. The 2026-09-01 record states that EIGHT of eleven GICS sector ETFs closed lower. Measured: SEVEN closed lower and FOUR closed higher. Down - XLY -1.72, XLK -1.53, XLI -1.37, XLB -1.18, XLF -0.88, XLC -0.52, XLRE -0.16. Up - XLE +1.27, XLU +0.78, XLV +0.66, XLP +0.32. Robust across extended hours, the Vanguard sector family, and FMP.

WHY IT MATTERS, stated against the interest of this correction. The miscount runs in the FLATTERING direction: the figure was recruited to support a claim of broad, indiscriminate repricing. Corrected, the pattern is DEFENSIVE ROTATION - all three defensive sectors plus energy higher - which is WEAKER support for that claim, not stronger. It is also the only figure in that entry carrying no named provenance, in an entry that pins contract IDs and date ranges on everything else.

WHAT IS NOT AFFECTED. Every other measurement in that record reproduces exactly, including the 10Y at 4.79 described as a 20-month high (verified: the last print at or above 4.79 was 2025-01-13, and the runner-up across the whole span is 4.67 on 2026-05-19). The de-risk remains defensible on its own terms and is NOT retracted. What this correction changes is the WEIGHT of one corroborating leg, never the direction of the call.

WHY NOT A SUPERSEDING REPLACEMENT - a live safety finding worth recording. state.park_allocation_latest is defined as SELECT * FROM state.park_allocation_recent WHERE is_call ORDER BY event_ts DESC LIMIT 1, and is_call is JSON_VALUE(fields, $.status) IS NOT NULL over state.decision_log_current. A superseding park-allocation replacement carrying status=BOUND would therefore (a) take the newest event_ts and become park_allocation_latest, which D2 reads as the CURRENT call - a stale VOO -> SGOV de-risk that D2 would convert, undoing the 2026-09-03 re-risk and producing a second, entirely spurious round trip - and (b) simultaneously drop the original 2026-09-01 call out of decision_log_current, erasing it from the every-day calibration record the log-every-call rule exists to build. Omitting status to dodge (a) still causes (b). A correction note has NEITHER failure mode, because park_allocation_recent filters entry_type=park-allocation and never sees this row. FUTURE SESSIONS: do not convert this note into a superseding row without re-reading those two view definitions first.

CONTEXT. Found during an interactive-session audit of the 2026-09-01 -> 2026-09-03 VOO -> SGOV -> VOO park round trip (measured cost 214.32 USD to the 09-03 close: foregone VOO appreciation 215.61 against 3.03 SGOV carry and 1.75 commissions; plus 107.73 USD of the 149.18 USD realized loss disallowed as a wash sale per state.wash_sale_exposure, with the 09-04 rebuy capturing the remainder). The STRUCTURAL finding from that audit landed separately as the DE-RISK EVIDENCE CARDINALITY rule (a de-risk converts only when at least two INDEPENDENT evidence axes fire; the 09-01 exit fired on ONE, breadth, while the 09-03 re-entry required TWO) in Claude_Task_Plan.md D1 PARK ALLOCATION CALL and Operating_Protocols.md 13.F, with golden fixture PA-07.""",
    r"""{"corrected_claim":"eight of eleven GICS sector ETFs closed lower","measured":"seven lower, four higher","sectors_down":{"XLY":-1.72,"XLK":-1.53,"XLI":-1.37,"XLB":-1.18,"XLF":-0.88,"XLC":-0.52,"XLRE":-0.16},"sectors_up":{"XLE":1.27,"XLU":0.78,"XLV":0.66,"XLP":0.32},"target_entry_id":"5722994d-d798-468b-a8da-fdd9e6e13b60","target_entry_date":"2026-09-01","target_entry_type":"park-allocation","supersedes_target":false,"decision_retracted":false,"corrected_pattern":"defensive rotation"}""",
    ['decision:5722994d-d798-468b-a8da-fdd9e6e13b60'],
    ['correction','park-allocation-record','measurement','park_allocator'],
    NULL,
    'interactive 2026-09-03 park round-trip audit'
  );
END IF;

-- Post-condition: exactly one such correction note exists, it does NOT supersede anything, and the
-- corrected target is still readable as a live park call.
ASSERT (
  SELECT COUNT(*) = 1 AND LOGICAL_AND(superseded_by IS NULL)
  FROM `stock-trading-498512.events.decision_log`
  WHERE entry_type = 'correction'
    AND 'decision:5722994d-d798-468b-a8da-fdd9e6e13b60' IN UNNEST(refs)
) AS 'park de-risk correction note: expected exactly one row, with superseded_by NULL.';

ASSERT (
  SELECT COUNT(*) = 1
  FROM `stock-trading-498512.state.park_allocation_recent`
  WHERE entry_date = DATE '2026-09-01' AND is_call
) AS 'the corrected 2026-09-01 park call must remain visible as a call (the note must not supersede it).';

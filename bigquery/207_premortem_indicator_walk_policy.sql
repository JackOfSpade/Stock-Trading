-- 207_premortem_indicator_walk_policy.sql (2026-09-01)
-- Project: stock-trading-498512. Register `premortem_indicator_walk_missing` in ops.alert_policy.
-- Purely additive, NOT EXISTS-guarded. Creates no object; redefines no procedure; does not touch
-- ops.sp_sq_cadence_check, so bigquery/63's SQ_VERSION registry is unaffected.
--
-- WHY: lands with Claude_Task_Plan.md M4 section I (PRE-MORTEM OWNER-ASSIGNED CHECK WALK) and M5's
-- WALK-PRESENCE CHECK, closing ops.alerts premortem_live_gate_defect
-- 6c670d35-c44a-416d-b3e6-73209e66fc3f (AR_orc, premortem-C-2026-a3 cycle 17). M5 is the only
-- routine with a FATAL sp_assert_deps gate on M4, so it is the one surface that can see a skipped
-- STEP inside a COMPLETED run; state.cadence_watch sees only a missing RUN.
--
-- WHY PRE-REGISTERED: ops.alert_policy is FAIL-CLOSED (bigquery/34_alert_lifecycle.sql) -- a
-- category absent from it has no auto-resolve rule and latches until a human UPDATE. bigquery/204's
-- header records the house discipline: "Every comparably-recent category ... was pre-registered with
-- a resolve rule in the same change that started emitting it." Emitting without registering would
-- recreate the exact defect 204 just cleaned up.
--
-- WHY latching = FALSE: the clear signal is mechanically checkable -- the receipt either exists for
-- the month or it does not. This must not become a permanently-red advisory nobody can close.
-- ops.sp_auto_resolve_alerts' rules are hardcoded and do not cover this condition, so latching=FALSE
-- SANCTIONS the routine-owned resolve described below; it does not self-clear.
--
-- WHY warning: `critical` enters the blocking_criticals term that closes state.trading_enabled, so a
-- missing AUDIT RECEIPT would halt order staging including exits. `info` is filtered out of both
-- notification paths (scripts/alert_relay.py and ops/monitoring/alert_emailer.gs both take
-- severity IN ('critical','warning')). Warning is the only severity that is both visible and
-- non-blocking. Do NOT promote it later: as of registration, Strategy C and Strategy E have zero
-- rows in state.current_positions, zero rows ever in events.position_events, and zero fills ever in
-- events.trade_fills, so the loci this watches are documentary verification with no live exposure.

INSERT INTO `stock-trading-498512.ops.alert_policy` (category, latching, resolve_rule, note)
SELECT p.category, p.latching, p.resolve_rule, p.note
FROM UNNEST([
  STRUCT(
    'premortem_indicator_walk_missing' AS category,
    FALSE AS latching,
    CONCAT(
      'ROUTINE-OWNED, evidence-based, and REACHABLE BY A BACKFILL -- read the next two sentences ',
      'together or the rule looks unsatisfiable. Resolve a row ONLY when an events.decision_log row ',
      'with entry_type = "premortem-indicator-walk" carries payload.covers_period_start EQUAL to ',
      'this row payload.period_start. That receipt is normally written in the named month itself; ',
      'when the month was missed it is written LATER as an explicit BACKFILL walk, which is why the ',
      'rule keys on covers_period_start (the month the walk COVERS) and never on entry_date (the ',
      'day it was written). Record the entry_id of that receipt in resolved_note. Do NOT resolve on ',
      'age, do NOT resolve on a later-month receipt that does not name this period in ',
      'covers_period_start, and do NOT resolve by editing the detector: the receipt is the artifact, ',
      'this alert is only its absence. The owning surface is Claude_Task_Plan.md M4 section I, whose ',
      'CLOSE YOUR OWN PRIOR NOTICE limb performs that backfill walk and then closes the row. ',
      'WHY THE BACKFILL LIMB EXISTS: M4 and M5 both fire on the 1st (0 15 and 0 16 UTC) and M4 is ',
      'catchup_safe false and on the never-re-fire list, so the next M4 cycle is the FOLLOWING ',
      'month; keyed on entry_date this row could never be closed by anything, and because ',
      'sp_raise_alert_once dedups on unresolved (category, message) with a deliberately FIXED ',
      'message, one stuck row would silence every later firing. A vacuous walk still owes a receipt ',
      '-- the Owner: M4 loci state that a review with no new C theses or E pairs is recorded as ',
      'such and is NOT a miss, which makes the recording the obligation precisely when the ',
      'substance is empty.') AS resolve_rule,
    CONCAT(
      'PRE-MORTEM TRANSMISSION CLASS, registered 2026-09-01 alongside Claude_Task_Plan.md M4 ',
      'section I and the M5 WALK-PRESENCE CHECK, closing premortem_live_gate_defect ',
      '6c670d35-c44a-416d-b3e6-73209e66fc3f. Raised at warning by M5 when M4 completed a monthly ',
      'period with no premortem-indicator-walk receipt. NEVER FIRED AS OF REGISTRATION: this is ',
      'pre-registration ahead of the first M5 cycle that could emit it, not a response to a live ',
      'incident. Message stability is load-bearing: sp_raise_alert_once dedups on exact ',
      '(category, message) text, so M5 keeps the message fixed and carries period_start and ',
      'm4_run_date in the JSON payload. Do not raise this at critical -- see the file header.') AS note
  )
]) AS p
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.ops.alert_policy` e WHERE e.category = p.category);

-- ============================================================================
-- VERIFY -- fail loudly if the registration did not land exactly as intended (bigquery/133/190/204).
-- ============================================================================
ASSERT (
  SELECT COUNT(*) = 1 AND LOGICAL_AND(NOT latching)
  FROM `stock-trading-498512.ops.alert_policy`
  WHERE category = 'premortem_indicator_walk_missing'
) AS 'premortem_indicator_walk_missing must be registered exactly once, non-latching';
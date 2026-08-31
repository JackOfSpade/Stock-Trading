-- Register `probe_funding_stalled` in ops.alert_policy — the one emitted-but-unregistered category.
-- Project: stock-trading-498512. Written by W5 2026-08-30, adjudicating SL3's 2026-08-26 referral
-- (events.decision_log ops-note 8555992d, "alert category probe_funding_stalled is unregistered in
-- ops.alert_policy and therefore latches with no resolve rule"). SL3 named W5/the owner as the owning
-- surface and declined to fix it from an incubation-monitor fire; W5's SPEC-DEFECT NOTICE INTAKE step
-- is the venue that adjudicates exactly this, so this is that adjudication.
--
-- WHY:
--   * MEASURED live 2026-08-30, confirming SL3's 2026-08-26 measurement is still true:
--     `SELECT COUNT(*) FROM ops.alert_policy WHERE category='probe_funding_stalled'` returns 0,
--     against 34 registered categories, while THIRTEEN scheduled-cadence files carry the raise site
--     `IF EXISTS (SELECT 1 FROM state.strategy_probe_funding_stalled) THEN CALL
--     ops.sp_raise_alert_once('warning','scheduled.cadence','probe_funding_stalled', ...)`
--     (bigquery/75, 111, 120, 128, 132, 142, 147, 150, 153, 157, 159, 172, 186) and SL3 STEP 5 pins
--     the same raise in prose (Claude_Task_Plan.md, task_plan/SL3.md).
--   * ops.alert_policy is FAIL-CLOSED by design (bigquery/34_alert_lifecycle.sql): a category absent
--     from it has no auto-resolve rule, so ops.sp_auto_resolve_alerts() can never clear it. A probe
--     funding stall would therefore stay open until a human ran an UPDATE — including after the owner
--     deposit landed and the stall had verifiably cleared. That is the inverse of the intended
--     lifecycle for a condition with a clean, mechanically checkable clear signal (the row simply
--     leaves state.strategy_probe_funding_stalled when funding_gap_dollars returns to 0), which is
--     precisely the shape this table exists to encode.
--   * ACCIDENT OF ABSENCE, not a deliberate omission. Every comparably-recent category —
--     premortem_live_gate_defect, queue_venue_claim_unwired, handoff_contract_unpinned,
--     lifecycle_provenance_gap, premortem_preamble_stale, append_only_violation,
--     artifact_version_drift, prompt_injection_attempt — was pre-registered with a resolve rule in the
--     same change that started emitting it, and several of those rows' own `note` fields cite that
--     precedent explicitly. bigquery/62_probe_stake_funding.sql's header and SL3 STEP 5 both reference
--     the category, but no policy row was ever written.
--
-- WHY IT IS SAFE TO LAND FROM A W5 FIRE, where SL3 correctly judged it out of scope for its own:
--   The blast radius SL3 was right to respect is the blast radius of CHANGING an existing category's
--   lifecycle. This change cannot touch one. It is purely additive, guarded by NOT EXISTS, and applies
--   to a category that has NEVER been raised: `SELECT COUNT(*) FROM ops.alerts WHERE
--   category='probe_funding_stalled'` = 0, because state.strategy_probe_funding_stalled holds 0 rows
--   and no strategy has ever reached PROBE (state.strategy_roster: 5 ADOPTED, 0 incubating,
--   analytics.strategy_incubation_perf empty). So there is no live alert whose behaviour this can
--   change, and no other category's row is read or written. Pre-registration before the first firing
--   is the whole point — the same "closed before first firing" discipline SL3 itself applied to the
--   SHADOW->PAPER marker (2026-08-19) and the PAPER stuck-flag widening (2026-08-20).
--
-- NON-LATCHING is deliberate and is NOT a weakening. Per bigquery/34's fail-closed allowlist,
-- latching=FALSE only SANCTIONS the evidence-based resolve described below; it does not make the row
-- self-clear, because ops.sp_auto_resolve_alerts' hardcoded rules do not cover this condition. The
-- alert still requires positive evidence that the stall cleared before anyone may close it. Note also
-- that this category is raised at `warning`, never `info` — SL3 STEP 5 already specifies that, and it
-- matters because both alert_emailer.gs and scripts/alert_relay.py filter `info` out, so an info-level
-- funding stall would be invisible to the operator by construction. Do NOT raise it at `critical`
-- either: every trading gate counts severity='critical' only, so a critical here would halt order
-- staging over a newcomer's funding shortfall that affects no live position.
-- ============================================================================
INSERT INTO `stock-trading-498512.ops.alert_policy` (category, latching, resolve_rule, note)
SELECT p.category, p.latching, p.resolve_rule, p.note
FROM UNNEST([
  STRUCT(
    'probe_funding_stalled' AS category,
    FALSE AS latching,
    CONCAT(
      'ROUTINE-OWNED, evidence-based resolve; NOT covered by any ops.sp_auto_resolve_alerts rule ',
      '(those are hardcoded to missing_dependency/missed_run/routine_stalled/catchup_refire_blocked/',
      'staleness plus the roster-notice rule), so this row does NOT clear itself merely by being ',
      'registered non-latching; latching=FALSE only SANCTIONS the resolve below under the ',
      'fail-closed allowlist (bigquery/34_alert_lifecycle.sql). SL3 (Incubation Monitor) is the owner ',
      '— it is the routine whose STEP 5 raises this category, it runs daily, and it already reads ',
      'state.strategy_probe_funding_stalled every fire. On any SL3 run where a strategy_code that ',
      'has an open probe_funding_stalled alert NO LONGER appears in state.strategy_probe_funding_stalled ',
      '(the funding gap closed — the owner deposit landed, or the probe was withdrawn), resolve it: ',
      'UPDATE ops.alerts SET resolved=TRUE, resolved_ts=CURRENT_TIMESTAMP(), resolved_note=<the ',
      'strategy_code + what closed the gap + the SL3 run date> WHERE alert_id=<id> AND NOT resolved. ',
      'SCOPE BY alert_id, resolved against the ONE strategy_code just re-verified — never a blanket ',
      'clear of the category, since two strategies can stall independently. NEVER RESOLVE ON AGE: an ',
      'aged-out row is indistinguishable from a genuinely-funded one, and the whole condition is a ',
      'newcomer sitting below its stake floor waiting for capital that may simply never have arrived ',
      '— the phantom_run_completion aging-alert trap in exactly the place it would cost the most.'
    ) AS resolve_rule,
    CONCAT(
      'ARSENAL-FUNDING CLASS, registered 2026-08-30 by W5 adjudicating SL3 referral 8555992d ',
      '(events.decision_log ops-note, 2026-08-26). Raised at warning by SL3 STEP 5 and by the ',
      'scheduled cadence_check for any row of state.strategy_probe_funding_stalled ',
      '(bigquery/62_probe_stake_funding.sql: a PROBE newcomer stuck below the $2,000 stake floor with ',
      'days_since_probe_entry >= 90). NEVER FIRED AS OF REGISTRATION: 0 rows in ops.alerts, 0 rows in ',
      'the source view, 0 strategies have ever reached PROBE — this is pre-registration ahead of the ',
      'first PAPER->PROBE graduation, not a response to a live incident. Interacts with the ',
      'message-stability fix SL3 landed in prose on 2026-08-26: sp_raise_alert_once dedups on the ',
      'exact (category, message) text, so SL3 keeps the message stable per strategy_code and carries ',
      'the varying funding_gap_dollars in the JSON payload — without that, a stall would have raised ',
      'a fresh row every day and, unregistered, EVERY ONE of them would have latched permanently.'
    ) AS note
  )
]) AS p
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.ops.alert_policy` e WHERE e.category = p.category);

-- ============================================================================
-- VERIFY — fail loudly if the registration did not land exactly as intended (bigquery/133/190 precedent).
-- ============================================================================
ASSERT (
  SELECT COUNT(*) = 1 AND LOGICAL_AND(NOT latching)
  FROM `stock-trading-498512.ops.alert_policy`
  WHERE category = 'probe_funding_stalled'
) AS 'probe_funding_stalled must be registered exactly once, non-latching';

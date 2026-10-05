-- ops.alert_policy rows for SL3's two incubation-notice classes: strategy_paper_promoted, strategy_incubation_culled.
-- Project: stock-trading-498512. Registers policy only — CREATES NO OBJECT, REPLACES NO PROCEDURE.
-- CLOSES ops.alerts eab79055-396b-4c9a-9f9e-1f5d439f0d42 (SL3 incubation_notice_category_unregistered, 2026-09-15),
-- adjudicated by W5 SPEC-DEFECT NOTICE INTAKE 2026-10-04. Copies the bigquery/185 shape (SL2 notice classes) and
-- bigquery/204 precedent. Claude_Task_Plan.md SL3 STEP 5 pins both literals (info severity, per-transition notice).
--
-- Both are INFO audit rows, never delivered (alert_emailer.gs / alert_relay.py filter info), so they never reach
-- notified_ts and ops.sp_auto_resolve_alerts Rule 5 cannot close them; no #14 auto-age entry names them.
-- DO NOT add either literal to the bigquery/134 Rule 5 IN list: it would be permanently inert and would falsely
-- classify a zero-capital promotion / a cull as roster-MEMBERSHIP changes. Severity stays info by design.
-- Idempotent: INSERT ... WHERE NOT EXISTS.
INSERT INTO `stock-trading-498512.ops.alert_policy` (category, latching, resolve_rule, note)
SELECT category, latching, resolve_rule, note FROM UNNEST([
  STRUCT('strategy_paper_promoted' AS category, FALSE AS latching,
    'ROUTINE/W5-OWNED resolve, NO mechanical backstop: info rows never reach notified_ts (Rule 5 cannot see them) and the category is absent from the #14 auto-age list. SL3 raises one per SHADOW->PAPER promotion; once the matching events.strategy_lifecycle row and ops.roster_change_log marker are verifiably committed, resolve by hand (or W5 SPEC-DEFECT NOTICE INTAKE does) with UPDATE ops.alerts SET resolved=TRUE, resolved_ts=CURRENT_TIMESTAMP(), resolved_note=<strategy code + lifecycle row>, scoped by alert_id. NEVER promote to warning and NEVER add to the bigquery/134 Rule 5 list.' AS resolve_rule,
    'SISA INCUBATION NOTICE, NEVER YET RAISED (zero rows at registration; zero strategies have entered SHADOW/PAPER). Raised by SL3 STEP 5 (Claude_Task_Plan.md) on every SHADOW->PAPER promotion — a zero-capital stage, not a roster-membership change, hence info and not one of the six warning ROSTER-CHANGE categories. Never critical. Registered 2026-10-04 (bigquery/251) before first firing, by W5 on SL3 referral eab79055.' AS note),
  STRUCT('strategy_incubation_culled' AS category, FALSE AS latching,
    'ROUTINE/W5-OWNED resolve, NO mechanical backstop: same reasoning as strategy_paper_promoted. SL3 raises one per incubation cull (SHADOW/PAPER member removed before capital); once the lifecycle row and roster_change_log marker are committed, resolve by hand (or via W5 SPEC-DEFECT NOTICE INTAKE) with UPDATE ops.alerts ... scoped by alert_id and citing the strategy code. NEVER promote to warning and NEVER add to the bigquery/134 Rule 5 list.' AS resolve_rule,
    'SISA INCUBATION NOTICE, NEVER YET RAISED. Raised by SL3 STEP 5 (Claude_Task_Plan.md) on every incubation cull of a zero-capital member. Info by design; never critical (an open critical sets state.trading_enabled=FALSE, bigquery/176, and a cull of a zero-capital candidate is no reason to halt staging). Registered 2026-10-04 (bigquery/251) before first firing, by W5 on SL3 referral eab79055.' AS note)
]) AS s
WHERE NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.alert_policy` p WHERE p.category = s.category);

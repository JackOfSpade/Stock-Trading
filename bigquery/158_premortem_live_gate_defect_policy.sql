-- Register the premortem_live_gate_defect alert class in ops.alert_policy. Project: stock-trading-498512.
--
-- WHY: AR_orc raised `premortem_live_gate_defect` for the first time on 2026-08-09 (alert
-- cbf79d95-92c7-458d-8ac1-5a705d10a487, review premortem-C-2026-a3 cycle 11, TIER 1 DEFECT) and the
-- category has NO row in ops.alert_policy -- the same accident-of-absence gap bigquery/138 closed for
-- prompt_injection_attempt and bigquery/139 closed for append_only_violation. The category also does
-- not appear at any pre-specified ops.sp_raise_alert / sp_raise_alert_once call site in
-- Claude_Task_Plan.md: the orchestrator composed it ad hoc from its own escalation step. So the class
-- had neither a declared lifecycle nor a written resolve rule.
--
-- latching = TRUE is the honest declaration of the behaviour that already existed. ops.alert_policy is
-- a FAIL-CLOSED allowlist (bigquery/34_alert_lifecycle.sql) and ops.sp_auto_resolve_alerts gates every
-- rule on `category IN (SELECT category FROM ops.alert_policy WHERE NOT latching)`, so an UNREGISTERED
-- category is already unreachable by the mechanical resolver; this row makes that a double lock and
-- attaches the missing resolve_rule text. Registering it latching = FALSE would be the actively wrong
-- choice: "does the live gate prose still overclaim what the code verifies" is an adjudication across
-- version-controlled Markdown, not a condition any BigQuery view can re-check.
--
-- THE STRUCTURAL TRAP THIS CLASS CARRIES, and the reason the resolve_rule is worded as it is:
-- an AR_orc cycle reviews ONE artifact_path, and the SL2 revise item it enqueues inherits that same
-- artifact_path. SL2 task spec grants write access only to the named strategy section of
-- strategy/08_pre_mortems.md and explicitly forbids altering entry/exit rules, thresholds, indicators,
-- router rules or kill criteria. So when the orchestrator finds the SAME defect ALSO present in frozen
-- strategy machinery -- as cycle 11 did, naming Strategy C entry criterion 4 as the most severe site --
-- nothing in the review lineage can reach it, and no other routine scans live strategy-spec prose.
-- Draining the queue item therefore makes the pre-mortem internally consistent while the live gate text
-- keeps overclaiming, which reads like closure and is not. Closing this alert on the queue item alone is
-- the specific mistake to avoid.
--
-- FOUNDING CASE (cycle 11, 2026-08-09): entry criterion 4 claimed closed-form vs Monte Carlo dual-path
-- verification of max loss INCLUDING the early-assignment cascade, while c_options_math.py
-- verify_max_loss_dual_path covers only the base max-loss and cascade_max_loss is single-path. Closed
-- 2026-08-10 by Rev 44 (owner-authorized interactive session) across strategy/00_preamble.md, the
-- Strategy C eligibility rule, entry criterion 4, the classical-method-delegation bullets,
-- Experiment_Parameters.md and c_options_math.py, with spec_hash recomputed for all five strategies.
-- The same investigation found a LIVE gap the alert had classified blocks_trading=false: the
-- Claude_Task_Plan.md options ORDER-GUARD CHECK fed analytics.fn_order_guard_options a base-only
-- max_loss_dollars and never invoked cascade_max_loss, which had zero production callers repo-wide.
-- That is why screen (b) below asks whether the prose describes a check the executed path performs.
--
-- Defines NO views or procedures -- one registry INSERT, guarded by NOT EXISTS so re-apply is
-- idempotent. Does NOT redefine ops.sp_auto_resolve_alerts (bigquery/148 remains current) and adds no
-- auto-resolve rule. Apply after bigquery/34_alert_lifecycle.sql (which creates ops.alert_policy).

INSERT INTO `stock-trading-498512.ops.alert_policy` (category, latching, resolve_rule, note)
SELECT p.category, p.latching, p.resolve_rule, p.note
FROM UNNEST([
  STRUCT(
    'premortem_live_gate_defect' AS category,
    TRUE AS latching,
    CONCAT(
      'NEVER auto-resolves -- an adjudication over version-controlled Markdown, not a condition a ',
      'view can re-check. Close by hand only, after all four: (a) READ THE ORCHESTRATOR VERDICT, not ',
      'just the alert message -- events.adversarial_reviews for the payload review_id, cycle ',
      'payload.cycle_number, gives the full finding list; the alert message usually names one site ',
      'and the verdict names more. (b) For EACH named site, check the EXECUTED path, not only the ',
      'prose: if the text describes a verification, confirm some production caller actually performs ',
      'it (grep for the function repo-wide -- a helper with only docstring, __main__ self-test and ',
      'tests callers is NOT wired). A prose defect sitting on top of an unwired check is a live ',
      'control gap, not documentation, regardless of what payload.blocks_trading says. (c) Check ',
      'whether any named site lies OUTSIDE payload.artifact_path. The enqueued SL2 revise item ',
      'inherits that artifact_path and SL2 may not edit entry/exit rules, thresholds, indicators, ',
      'router rules or kill criteria -- so a site in frozen strategy machinery (Strategy.md and its ',
      'generated strategy/ slices) can NEVER be fixed by that lineage and needs an owner-directed ',
      'Rev-N edit with spec_hash recomputed. Do NOT close this alert merely because the queue item ',
      'drained. (d) State in the note which sites were fixed, by what mechanism, and which remain ',
      'with what tracking. Resolve with UPDATE ops.alerts SET resolved=TRUE, ',
      'resolved_note=<sites + mechanism + residual>, scoped by alert_id.'
    ) AS resolve_rule,
    CONCAT(
      'ADVERSARIAL-REVIEW CLASS, first raised 2026-08-09 by AR_orc (alert cbf79d95, review ',
      'premortem-C-2026-a3 cycle 11); registered here 2026-08-10 after that first firing revealed the ',
      'class had no ops.alert_policy row and no pre-specified raise site in Claude_Task_Plan.md. Raise ',
      'at warning, not critical: an open critical sets state.trading_enabled=FALSE (bigquery/107), and ',
      'a stale or overclaiming spec description is not a reason to halt order staging -- escalate to ',
      'critical only if the defect is found to have let a real order through a gate it should not ',
      'have. Sibling classes registered the same way for the same accident-of-absence reason: ',
      'prompt_injection_attempt (bigquery/138), append_only_violation (bigquery/139). The founding ',
      'case is written up in the header of this file; its most reusable lesson is that ',
      'events.queue_events.artifact_path is BINDING on what the review lineage can repair, so an ',
      'orchestrator finding outside it is escalation-only by construction and this alert IS that ',
      'escalation path.'
    ) AS note
  )
]) AS p
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.ops.alert_policy` e WHERE e.category = p.category
);

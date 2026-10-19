-- ops.alert_policy row for AR_orc's router-amendment-review notice: router_amendment_action_required.
-- Project: stock-trading-498512. Apply after 257_shock_transmission_register.sql. Registers policy only --
-- CREATES NO OBJECT, REPLACES NO PROCEDURE. Copies the bigquery/251 shape. Idempotent: INSERT ... WHERE NOT EXISTS.
--
-- WHY (owner directive 2026-10-19, interactive session: "auto do this and email me if action can be taken").
-- premortem-router-2026-a1 (attacker due 2026-10-20, orchestrator due 2026-10-21) reviews the Rev 50 Shock
-- Transmission Register amendment in strategy/02_regime_router.md -- a surface no routine may write (SL2 route (B)
-- covers candidate drafts and strategy/08_pre_mortems.md only). AR_orc's generic pre-mortem REVISION REQUIRED branch
-- would enqueue an SL2 strategy-revise row that can never drain, so the verdict (for example: B should move from
-- BINDS to an exemption with a gate) would sit unread in events.decision_log with no email. Claude_Task_Plan.md
-- AR_orc Step 4 now carries a router-scoped clause: on REVISION REQUIRED it skips the SL2 enqueue and raises this
-- WARNING via ops.sp_raise_alert_once with a fixed message (review id + cycle numbers only; defects and the
-- recommended register changes travel in the payload). warning, not info: the owner must act (land the revision,
-- re-enqueue the next cycle), so under the 2026-09-07 RULE 2 it is emailed by alert_emailer.gs AND pushed by
-- scripts/alert_relay.py. Do NOT add it to NO_PUSH_CATEGORIES or EMAIL_ONLY_CATEGORIES.
--
-- CLOSE PATH (condition-keyed, sited in AR_orc's NOTICE-CLOSE PASS at the due scan, every fire): resolved once
-- events.queue_events holds a PENDING_REVIEW row for the same item_key (payload.review_id) with a higher
-- cycle_number than the alerted one, i.e. the owner landed the revision and re-enqueued. A declined revision is
-- resolved by hand with a resolved_note. Never critical (an open critical sets state.trading_enabled=FALSE,
-- bigquery/176, and a documentary verdict is no reason to halt staging). NEVER add to the bigquery/134 Rule 5 list.
INSERT INTO `stock-trading-498512.ops.alert_policy` (category, latching, resolve_rule, note)
SELECT category, latching, resolve_rule, note FROM UNNEST([
  STRUCT('router_amendment_action_required' AS category, FALSE AS latching,
    'CONDITION-KEYED close by AR_orc NOTICE-CLOSE PASS on every fire (Claude_Task_Plan.md): resolve once events.queue_events holds a PENDING_REVIEW row whose item_key = payload.review_id and whose payload.cycle_number is HIGHER than the alerted payload.cycle_number, i.e. the owner landed the revision and re-enqueued the next cycle. A declined revision is resolved by hand with a resolved_note. Not fire-cadence: the action happens outside the routine. NEVER promote to critical; NEVER add to the bigquery/134 Rule 5 list or to the relay suppression tuples.' AS resolve_rule,
    'ROUTER AMENDMENT REVIEW NOTICE, NEVER YET RAISED (zero rows at registration). Raised by AR_orc Step 4 router clause on a REVISION REQUIRED verdict for a pre-mortem whose payload.strategy = router (artifact strategy/02_regime_router.md, a surface no routine may write). Warning by design: the owner must land the revision and re-enqueue, so it is emailed AND pushed. Registered 2026-10-19 (bigquery/258) before first firing, by the interactive owner session that enqueued premortem-router-2026-a1.' AS note)
]) AS s
WHERE NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.alert_policy` p WHERE p.category = s.category);

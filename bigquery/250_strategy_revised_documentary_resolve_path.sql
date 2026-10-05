-- 250_strategy_revised_documentary_resolve_path.sql
-- Closes ops.alerts 624825e3-052f-4d1b-aa24-c26eb4c6ecdb (SL2, premortem_revised_resolve_rule_unsatisfiable),
-- adjudicated by W5 SPEC-DEFECT NOTICE INTAKE 2026-10-04.
--
-- DEFECT: the strategy_revised resolve_rule (bigquery/185) named, as its PRIMARY resolve evidence, an
-- events.queue_events PENDING_REVIEW row for the item_key at the incremented cycle. For a no-cycle DOCUMENTARY
-- revision (SL2 route (B) task routed from an alert, review thread already closed at SUFFICIENT, re-enqueue
-- would reopen it) that row is never written -> unsatisfiable by construction; MEASURED twice in 8 days
-- (1baf9da6 B rev 13; C rev 19), each rescued by a hand-written RESOLVE_EVIDENCE_FOR_THIS_ROW payload key,
-- with the 7-day age backstop as the only fallback.
-- FIX: append a first-class alternative evidence path. Documentation prose only: no alert is raised or
-- resolved, no latching flag or predicate changes. Idempotent (guarded by the marker text).
UPDATE `stock-trading-498512.ops.alert_policy`
SET resolve_rule = CONCAT(resolve_rule,
      ' (3) DOCUMENTARY-REVISION EVIDENCE (added 2026-10-04 by W5, closing alert 624825e3): for a no-cycle ',
      'documentary revision -- a route (B) task routed from an alert rather than from an AR_orc REVISION REQUIRED ',
      'verdict, whose review thread is already closed at SUFFICIENT and must NOT be re-enqueued -- the PENDING_REVIEW ',
      'row in (2) is not expected and its absence is NOT a reason to leave the row open or to close it on age. The ',
      'first-class alternative evidence is ALL THREE of: (a) the drained PENDING_DRAFT events.queue_events item for ',
      'that item_key has a terminal complete row; (b) the artifact revision marker at the stated commit is merged to ',
      'main; (c) scripts/check_roster_consistency.py R-F is green on the recomputed spec_hash. Resolve scoped by ',
      'alert_id with resolved_note naming those three. A hand-written RESOLVE_EVIDENCE_FOR_THIS_ROW payload key is ',
      'no longer required.'),
    updated_ts = CURRENT_TIMESTAMP()
WHERE category = 'strategy_revised'
  AND resolve_rule NOT LIKE '%DOCUMENTARY-REVISION EVIDENCE%';

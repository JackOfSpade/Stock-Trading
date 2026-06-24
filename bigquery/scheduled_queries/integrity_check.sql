-- SCHEDULED QUERY (stack review 2026-06-24, RUNBOOK §25 B3): append-only INTEGRITY dead-man's switch.
-- Separate from cadence_check.sql because this one reads INFORMATION_SCHEMA.JOBS_BY_PROJECT (all
-- identities' DML jobs), which needs bigquery.jobs.listAll — granted via roles/bigquery.resourceViewer
-- on this query's run-as SA (job METADATA only, never table data). Keeping it isolated means the core
-- cadence_check.sql keeps working with no new IAM, and a missing grant only affects THIS query.
--
-- WHAT IT CATCHES: the immutable AUDIT TRAIL (decision_log/position_events/trade_fills/regime_events/
-- queue_events/adversarial_reviews/parking_events/hf_capability_captures) is INSERT-only truth
-- (RUNBOOK §21); corrections are new rows + superseded_by. state.append_only_integrity
-- (bigquery/18_stack_review_fixes.sql) surfaces any out-of-band UPDATE/DELETE/MERGE/TRUNCATE on those
-- tables in the last 2 days, suppressing the ONE sanctioned exception (a W5 decision_log.sub_pattern
-- UPDATE). The reference/market-data feeds (market_holidays MERGE, daily_marks re-ingest, macro_*) are
-- deliberately OUT of scope — they are maintained in place by design.
--
-- POSTURE — STAGED ROLLOUT (record-only WARNING, NO RAISE). It records a deduped 'warning' ops.alerts
-- row (delivered by the alert emailer / out-of-band relay — both forward warnings) but does NOT RAISE,
-- so a heuristic false positive on this novel monitor cannot flip all_green or storm the DTS email.
-- Baseline verified clean (0 rows) 2026-06-24. PROMOTE to critical+RAISE here once a clean baseline is
-- confirmed over time (change 'warning'→'critical' and add a RAISE, like cadence_check's pattern).
--
-- email-on-failure SHOULD be enabled: this query RAISEs nothing on a violation, so the only failure is
-- the QUERY itself erroring — which means the resourceViewer grant lapsed or view 18 isn't applied.
-- That failure-email is the signal to re-grant / re-apply.
--
-- TIMING: daily, any time (it looks back 2 days). ~05:20 UTC sits with the other control-plane checks.
-- APPLY ORDER: bigquery/18_stack_review_fixes.sql must be applied BEFORE creating this query, and the
-- run-as SA must hold roles/bigquery.resourceViewer. See ops/RUNBOOK.md §25.
BEGIN
  IF EXISTS (SELECT 1 FROM `stock-trading-498512.state.append_only_integrity`) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.integrity', 'append_only_violation',
      CONCAT('Append-only integrity: out-of-band UPDATE/DELETE/MERGE on immutable events.* table(s): ',
             (SELECT STRING_AGG(DISTINCT CONCAT(statement_type, ' ', target_table), ', ' ORDER BY CONCAT(statement_type, ' ', target_table))
              FROM `stock-trading-498512.state.append_only_integrity`)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(job_id, user_email, statement_type, target_table, query_preview)))
       FROM `stock-trading-498512.state.append_only_integrity`));
  END IF;
END;

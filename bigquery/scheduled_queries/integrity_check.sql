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
-- PROMOTION IS NOW MECHANIZED (self-improvement audit ITEM 31, 2026-07-15) — see the MERGE block below
-- + bigquery/57_append_only_integrity_promotion.sql + Claude_Task_Plan.md's D3 MONITOR-PROMOTION
-- SELF-FLIP step. Nothing to do here manually; do not hand-promote this outside that mechanism.
--
-- email-on-failure SHOULD be enabled: this query RAISEs nothing on a violation, so the only failure is
-- the QUERY itself erroring — which means the resourceViewer grant lapsed or view 18 isn't applied.
-- That failure-email is the signal to re-grant / re-apply.
--
-- TIMING: daily, any time (it looks back 2 days). ~05:20 UTC sits with the other control-plane checks.
-- APPLY ORDER: bigquery/18_stack_review_fixes.sql must be applied BEFORE creating this query, and the
-- run-as SA must hold roles/bigquery.resourceViewer. See ops/RUNBOOK.md §25. ALSO apply
-- bigquery/45_monitor_promotion.sql (creates ops.monitor_health_history, the table the MERGE just below
-- targets) and bigquery/57_append_only_integrity_promotion.sql (the promotion-readiness view that reads
-- it) before re-pasting this updated body — self-improvement audit ITEM 31, 2026-07-15.
BEGIN
  -- MONITOR-PROMOTION HISTORY (self-improvement audit ITEM 31, 2026-07-15): logged UNCONDITIONALLY
  -- (pass or fail) every run, mirroring cadence_check.sql's ddl_drift/restore_stale MERGE-upsert
  -- pattern (bigquery/45_monitor_promotion.sql, ITEM 24) — state.append_only_integrity_promotion_
  -- readiness (bigquery/57_append_only_integrity_promotion.sql) needs this history to evaluate "14
  -- consecutive clean logged days", which state.append_only_integrity (a today-only, 2-day-lookback
  -- snapshot) cannot provide on its own. This does NOT change this query's alerting behavior at all —
  -- still WARNING-only, no RAISE, until D3's MONITOR-PROMOTION SELF-FLIP later promotes it (see
  -- bigquery/57's header for the exact future promoted body). MERGE, not INSERT, so a same-day re-run
  -- never double-logs one day (same rationale as cadence_check.sql's 2026-07-11 adversarial-self-audit
  -- fix).
  MERGE `stock-trading-498512.ops.monitor_health_history` T
  USING (
    SELECT 'append_only_integrity' AS check_id, CURRENT_DATE('America/Denver') AS check_date,
           NOT EXISTS (SELECT 1 FROM `stock-trading-498512.state.append_only_integrity`) AS clean
  ) S
  ON T.check_id = S.check_id AND T.check_date = S.check_date
  WHEN MATCHED THEN
    UPDATE SET clean = S.clean, logged_ts = CURRENT_TIMESTAMP()
  WHEN NOT MATCHED THEN
    INSERT (check_id, check_date, clean) VALUES (S.check_id, S.check_date, S.clean);

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

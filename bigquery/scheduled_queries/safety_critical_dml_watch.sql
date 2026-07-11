-- SCHEDULED QUERY (2026-07-11, self-improvement audit ITEM 6): safety-critical DML watch.
--
-- WHY THIS EXISTS. Every routine (D1..D3, W*, M*, Q*, A*, SL1..SL5) shares ONE owner-OAuth principal
-- (RUNBOOK ops/RUNBOOK.md §15) with full BigQuery DML rights. The mechanical gates that make the
-- system safe to run autonomously — ops.trading_control (the halt-all gate every staging routine is
-- FATAL-gated on, bigquery/23_trading_control.sql), ops.arsenal_control (the SISA kill-switch every
-- SL routine is FATAL-gated on, bigquery/35_strategy_arsenal.sql), events.strategy_lifecycle (the sole
-- audit trail state.strategy_roster reads latest-row-per-strategy_code from), and perf.strategy_daily
-- (the deployed-TWR engine's authoritative output that state.system_health / perf.kill_flags / every
-- mechanical kill trigger reads directly) — are each designed to be mutated ONLY by INSERT (an
-- append-only control/audit row) or, for perf.strategy_daily, by the ONE named nightly rebuild
-- procedure. Nothing in IAM stops a raw UPDATE/DELETE/MERGE/TRUNCATE against any of them under the
-- shared OAuth, and the only existing detector, state.append_only_integrity (bigquery/18_stack_review_
-- fixes.sql), is a broader, WARNING-only, staged-rollout sweep of the events.* audit trail that does
-- not cover ops.trading_control / ops.arsenal_control / perf.strategy_daily at all. This query is that
-- missing, narrow, CRITICAL, FAIL-LOUD watcher for exactly those four tables.
--
-- THIS IS A DETECTIVE CONTROL, NOT PREVENTION. It catches a bypass AFTER THE FACT (next run, <=24h
-- later) and fails loud (RAISE + a durable critical ops.alerts row) — it cannot stop the mutation from
-- happening. A full IAM re-scope (per-routine service accounts, column/row-level security, or a
-- write-mediating API in front of these four tables) is the real fix and is DEFERRED — it needs a
-- self-hosted MCP (the managed BigQuery MCP connector runs as the single owner OAuth grant by
-- construction; see the RUNBOOK §15 credential table). Do NOT re-propose an IAM re-scope here without
-- that prerequisite, and do not treat this scheduled query as a substitute for it — it is the
-- compensating control for the shared-OAuth finding (ITEM 6), sized to what is achievable today.
--
-- SCOPE — exactly 4 tables (not a general events.* sweep; see the header of state.append_only_
-- integrity / integrity_check.sql for that broader, separate, WARNING-only advisory):
--   ops.trading_control        halt-all gate (ops.sp_assert_trading_enabled FATAL-gates every staging
--                               routine on it). Sanctioned path: INSERT only (manual override note,
--                               bigquery/23_trading_control.sql header).
--   ops.arsenal_control        SISA kill-switch (ops.sp_assert_arsenal_enabled FATAL-gates SL1..SL5).
--                               Sanctioned path: INSERT only (bigquery/35_strategy_arsenal.sql header).
--   events.strategy_lifecycle  append-only roster-transition log; state.strategy_roster reads its
--                               latest row per strategy_code. Sanctioned path: INSERT only.
--   perf.strategy_daily        deployed-TWR engine output. Sanctioned path: the nightly wholesale
--                               rebuild inside ops.sp_recompute_engine() (bigquery/03_twr_engine.sql) —
--                               a DELETE FROM ... WHERE TRUE immediately followed by a re-INSERT (INSERT
--                               is not a watched statement_type). This is the ONE sanctioned exception,
--                               suppressed below by an exact query-text match — same heuristic-caveat
--                               posture as state.append_only_integrity's W5 sub_pattern suppression: an
--                               adversary who ALREADY holds the shared OAuth could in principle craft an
--                               identical literal string to evade it. If the live query text ever fails
--                               to match this pattern exactly (formatting drift), the FAIL DIRECTION is
--                               safe — the legitimate nightly rebuild would then alert instead of being
--                               silently missed, extra noise rather than a missed detection. Any OTHER
--                               DELETE/UPDATE/MERGE/TRUNCATE on perf.strategy_daily (a different WHERE
--                               clause, a partial delete, an UPDATE) still fires.
--
-- ops.alerts IS DELIBERATELY EXCLUDED from this blanket watcher (called out explicitly, since it is the
-- obvious "5th safety-critical table" a reader might expect here). ops.alerts.resolved / resolved_ts /
-- resolved_note / notified_ts are updated by legitimate, FREQUENT, wanted in-place UPDATEs
-- (ops.sp_auto_resolve_alerts, the alert_emailer/relay stamping notified_ts, an operator resolving a
-- row — bigquery/10_observability.sql / 18_stack_review_fixes.sql / 34_alert_lifecycle.sql). What would
-- actually be dangerous is an UPDATE touching a RESOLUTION-EXCLUDED column (severity / message / payload
-- / source / category / alert_ts) — but that is not reliably parseable from INFORMATION_SCHEMA.JOBS_
-- BY_PROJECT job text (same limitation state.append_only_integrity's own header documents for its query-
-- text heuristics). Rather than ship a heuristic that either misses a real payload-tamper or storms on
-- every ordinary resolve, ops.alerts is excluded here entirely and flagged as a known residual gap, not
-- an oversight.
--
-- POSTURE — CRITICAL + RAISE on any hit (no staged rollout, unlike integrity_check.sql's WARNING-only
-- posture). This is a small, high-stakes, hand-picked table set with a single sanctioned mutation
-- pattern each, so a false positive here is far less likely than on the broad events.* sweep, and the
-- blast radius of a real hit (a silently altered halt gate / kill-switch / roster truth / engine truth)
-- justifies failing loud immediately rather than warming up on a clean baseline first. RAISE fires
-- BigQuery's built-in "Send email notifications on failure" (an identity-independent channel — same
-- posture as cadence_check.sql / delivery_canary.sql), on top of the durable critical ops.alerts row
-- (dedup via ops.sp_raise_alert_once on (category, message), so a persistent condition across runs does
-- not pile up duplicate rows; the message text is kept STABLE — no per-run job_id/timestamp folded in,
-- full detail rides the payload — matching the 2026-07-04 audit-finding pattern already applied to
-- trigger_missing / calendar_runway_low / trading_halted / arsenal_disabled).
--
-- WINDOW: last 24h, successful DML jobs only (state='DONE', error_result IS NULL — a FAILED UPDATE/
-- DELETE/MERGE/TRUNCATE never mutated anything and is not a violation). Every scheduled query in this
-- directory runs at most once/day (bigquery/scheduled_queries/README.md), so a 24h lookback has no
-- detection gap at daily cadence.
--
-- IAM: reads INFORMATION_SCHEMA.JOBS_BY_PROJECT (ALL identities' job METADATA, never table data) —
-- needs bigquery.jobs.listAll, granted via roles/bigquery.resourceViewer on the run-as SA, the SAME
-- grant integrity_check.sql already needs (RUNBOOK §25/§27). If this query's run-as SA is bq-scheduler@
-- and integrity_check.sql is already live under that SA, no NEW grant is required.
--
-- APPLY ORDER: no new BigQuery DDL to apply first — this script only queries INFORMATION_SCHEMA and
-- calls ops.sp_raise_alert_once (already defined in bigquery/10_observability.sql). Idempotent /
-- re-runnable (record-then-RAISE, same shape as cadence_check.sql / delivery_canary.sql). Distinct
-- from, and complementary to, the broad advisory state.append_only_integrity sweep (bigquery/
-- 18_stack_review_fixes.sql / bigquery/scheduled_queries/integrity_check.sql): that one is WARNING-only
-- staged-rollout coverage of the whole events.* audit-truth table set; this one is a narrow, CRITICAL,
-- RAISE-ing watch of the 4 tables where a bypass has the single highest blast radius in the system
-- (halt gate / kill-switch / roster truth / engine truth). See owner_actions / RUNBOOK §15 for the
-- console steps to create this scheduled query and the companion Cloud Monitoring policy.
BEGIN
  -- Computed once, reused below (same "compute once, reuse" discipline as state.system_health's
  -- alerts_summary CTE) — avoids scanning INFORMATION_SCHEMA three times for one check.
  CREATE TEMP TABLE hits AS
  SELECT
    job_id,
    user_email,
    statement_type,
    destination_table.dataset_id AS target_dataset,
    destination_table.table_id   AS target_table,
    creation_time,
    SUBSTR(query, 0, 400) AS query_preview
  FROM `stock-trading-498512`.`region-us`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
  WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 24 HOUR)
    AND state = 'DONE'
    AND error_result IS NULL
    AND statement_type IN ('UPDATE', 'DELETE', 'MERGE', 'TRUNCATE_TABLE')
    -- exactly the 4 safety-critical tables (ops.alerts deliberately excluded — see header).
    AND (
      (destination_table.dataset_id = 'ops'    AND destination_table.table_id = 'trading_control')
      OR (destination_table.dataset_id = 'ops'    AND destination_table.table_id = 'arsenal_control')
      OR (destination_table.dataset_id = 'events' AND destination_table.table_id = 'strategy_lifecycle')
      OR (destination_table.dataset_id = 'perf'   AND destination_table.table_id = 'strategy_daily')
    )
    -- ONE sanctioned exception: ops.sp_recompute_engine()'s nightly wholesale rebuild of
    -- perf.strategy_daily (03_twr_engine.sql) — an exact-text DELETE FROM ... WHERE TRUE with no other
    -- condition. Any other DELETE/UPDATE/MERGE/TRUNCATE on this table still fires. See header caveat.
    AND NOT (
      destination_table.dataset_id = 'perf' AND destination_table.table_id = 'strategy_daily'
      AND statement_type = 'DELETE'
      AND REGEXP_CONTAINS(
            query,
            r'(?i)^\s*delete\s+from\s+`?stock-trading-498512\.perf\.strategy_daily`?\s+where\s+true\s*;?\s*$'
          )
    );

  IF EXISTS (SELECT 1 FROM hits) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.safety_critical_dml', 'safety_critical_dml',
      CONCAT(
        'Safety-critical DML watch: out-of-band UPDATE/DELETE/MERGE/TRUNCATE detected on a safety-',
        'critical table in the last 24h (ops.trading_control / ops.arsenal_control / ',
        'events.strategy_lifecycle / perf.strategy_daily). See payload for job/table detail. This is a ',
        'DETECTIVE control (RUNBOOK item 6 / §15 shared-OAuth finding) — the mutation already happened; ',
        'investigate the job_id/user_email in the payload and, if unauthorized, restore the affected ',
        'table from its last known-good state (see the backup/restore-drill machinery, RUNBOOK §2/§27) ',
        'and reset the affected control table via a fresh sanctioned INSERT.'),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(
          job_id, user_email, statement_type, target_dataset, target_table, creation_time, query_preview
        ) ORDER BY creation_time))
       FROM hits));
    RAISE USING MESSAGE = CONCAT(
      'STOCK-TRADING safety-critical DML watch FAILED — out-of-band UPDATE/DELETE/MERGE/TRUNCATE on ',
      (SELECT STRING_AGG(DISTINCT CONCAT(statement_type, ' ', target_dataset, '.', target_table), ', '
              ORDER BY CONCAT(statement_type, ' ', target_dataset, '.', target_table))
       FROM hits),
      ' in the last 24h. See ops.alerts (category=safety_critical_dml) for job_id/user_email detail.');
  END IF;
END;

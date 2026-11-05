-- bigquery/275_append_only_resolved_jobs_disposition.sql (2026-11-05)
-- Project: stock-trading-498512. Apply after bigquery/162. SUPERSEDES state.append_only_integrity from
-- bigquery/162_append_only_watchlist_cash_flows.sql, whose marker points here. That file's other work
-- stays canonical there. state.append_only_integrity_haltable (bigquery/141) reads this view unedited.
--
-- WHY (interactive triage of ops.alerts fc2832b4, the first CRITICAL append_only_violation since the
-- bigquery/185 promotion). The detector scans a rolling 2-day job window, runs daily, and
-- sp_raise_alert_once dedups only while the alert is unresolved. So every job is seen by two runs, and
-- resolving the first alert guarantees one identical echo. While the class was a WARNING the echo was a
-- nuisance, closed by reference. Since promotion it is a fresh blocking critical: job
-- job_zriTmH-_-QDO5rjRcaFb9IcOqpfA would have re-blocked order staging from 2026-11-06 07:40 UTC until a
-- human closed it again, with no email-free path and no closer.
--
-- WHAT CHANGED. One predicate. The job ids already sit in the alert payload, and ops.alert_policy says
-- this category never auto-resolves, so a resolved row IS the human adjudication of exactly the jobs it
-- lists. No new table, no carve-out by table or statement type. MEASURED live before writing: the view
-- returned 1 row, and 0 with this predicate. 12 resolved alerts carry 38 job ids.
--
-- Idempotent. The alert_policy UPDATE sits before the CREATE so it cannot fold into the view's parity body.

UPDATE `stock-trading-498512.ops.alert_policy`
SET resolve_rule = REPLACE(resolve_rule,
      'so resolving a row whose jobs are still inside that window re-arms exactly one more identical raise per remaining night. State the predicted recurrence in the note (precedent: 4353777f then afdc096d; 58da7e8f then 94ce1df2) so the echo can be closed by reference instead of re-investigated.',
      'and bigquery/275 excludes every job named in a RESOLVED row of this category from the detector, so resolving is final for exactly the job ids in the payload and no echo follows. A raise after 2026-11-05 is therefore a new job. Resolve only after (a) to (c): a careless resolve permanently silences those jobs.'),
    updated_ts = CURRENT_TIMESTAMP()
WHERE category = 'append_only_violation';

CREATE OR REPLACE VIEW `stock-trading-498512.state.append_only_integrity` AS
SELECT
  job_id,
  user_email,
  statement_type,
  destination_table.dataset_id AS target_dataset,
  destination_table.table_id   AS target_table,
  creation_time,
  end_time,
  SUBSTR(query, 0, 400) AS query_preview
FROM `stock-trading-498512`.`region-us`.INFORMATION_SCHEMA.JOBS_BY_PROJECT
WHERE creation_time >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 2 DAY)
  AND state = 'DONE'
  AND error_result IS NULL
  AND statement_type IN ('UPDATE', 'DELETE', 'MERGE', 'TRUNCATE_TABLE')
  AND destination_table.dataset_id = 'events'
  -- AUDIT-TRUTH watch-list only (reference/market-data feeds deliberately excluded — see header).
  -- cash_flows / cash_flow_candidates added 2026-08-10 (bigquery/162): the money ledger and its
  -- two-phase staging table are append-only audit truth, not a refreshed feed.
  AND destination_table.table_id IN (
    'decision_log', 'position_events', 'trade_fills', 'regime_events',
    'queue_events', 'adversarial_reviews', 'parking_events', 'hf_capability_captures',
    'cash_flows', 'cash_flow_candidates'
  )
  -- Suppress the ONE sanctioned exception: an UPDATE that sets ONLY decision_log.sub_pattern, on a
  -- day W5 (the taxonomy owner) logged a completed run. Anything else — any other column, any other
  -- watched table, any DELETE/MERGE/TRUNCATE — is a violation.
  AND NOT (
    statement_type = 'UPDATE'
    AND destination_table.table_id = 'decision_log'
    AND REGEXP_CONTAINS(query, r'(?i)set\s+sub_pattern\s*=')
    AND NOT REGEXP_CONTAINS(query,
          r'(?i)set[\s\S]*\b(decision|conviction|conviction_pct|body_md|title|entry_type|entry_date|strategy|ticker|fields|refs|tags|theater_check)\b\s*=')
    AND EXISTS (
      SELECT 1 FROM `stock-trading-498512.ops.run_log` r
      WHERE r.routine = 'W5' AND r.status = 'completed'
        AND r.run_date = DATE(creation_time, 'America/Denver')
    )
  )
  -- A job named in a RESOLVED append_only_violation has been adjudicated by hand: do not re-raise it
  -- (bigquery/275). A job in no resolved alert still raises, so a NEW violation is unaffected.
  AND job_id NOT IN (
    SELECT JSON_VALUE(item, '$.job_id')
    FROM `stock-trading-498512.ops.alerts` a, UNNEST(JSON_QUERY_ARRAY(a.payload)) AS item
    WHERE a.category = 'append_only_violation' AND a.resolved
      AND JSON_VALUE(item, '$.job_id') IS NOT NULL
  );

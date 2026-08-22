-- Parallel-run dbt port of bigquery/162_append_only_watchlist_cash_flows.sql:state.append_only_integrity — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
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
      SELECT 1 FROM {{ source('ops', 'run_log') }} r
      WHERE r.routine = 'W5' AND r.status = 'completed'
        AND r.run_date = DATE(creation_time, 'America/Denver')
    )
  )

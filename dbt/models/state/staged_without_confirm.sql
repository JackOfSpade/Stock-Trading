-- Parallel-run dbt port of bigquery/148_audit_2026_08_08_fixes.sql:state.staged_without_confirm — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
SELECT
  o.item_key, o.ticker, o.side, o.entry_window_close, o.staged_ts,
  c.snapshot_ts AS last_attested_ts,
  c.confirm_event_found,
  CASE
    WHEN c.snapshot_id IS NULL THEN 'never_attested'
    WHEN NOT c.confirm_event_found THEN 'confirm_event_missing'
    ELSE 'attestation_stale'
  END AS flag_reason
FROM {{ ref('open_orders') }} o
LEFT JOIN {{ ref('confirm_event_latest') }} c USING (item_key)
WHERE LOWER(o.status) = 'pending'
  AND o.instruction_id IS NULL   -- craftability scoping (2026-07-20): see header note above
  AND o.staged_ts < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 HOUR)
  AND (c.snapshot_id IS NULL
       OR NOT c.confirm_event_found
       OR c.snapshot_ts < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 30 HOUR))

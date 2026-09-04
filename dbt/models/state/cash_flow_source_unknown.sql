-- Parallel-run dbt port of bigquery/214_account_fee_recording.sql:state.cash_flow_source_unknown — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
SELECT
  event_id, flow_date, flow_type, amount, strategy, source, ingest_ts,
  CASE
    WHEN source IS NULL THEN 'source is NULL - every write path must tag its provenance'
    WHEN source = 'unspecified' THEN 'source left at the column DEFAULT - the writer did not tag this row'
    WHEN source = 'D2' THEN 'source is the RETIRED pre-2026-08-10 default - the writer did not tag this row and was stamped D2'
    ELSE 'source is not in the sanctioned set - either a new movement mechanism that must be added to bigquery/163, or a typo'
  END AS finding,
  SUBSTR(COALESCE(note, ''), 0, 300) AS note_preview
FROM {{ source('events', 'cash_flows') }}
WHERE ingest_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 14 DAY)
  AND (
    source IS NULL
    OR NOT (
    source IN (
      'regime_capital_sweep', 'regime_capital_restore', 'external_withdrawal',
      'termination_redistribution', 'connector-reconciliation',
      'nomadic_capital_sweep',   -- bigquery/167 (renamed from capital_dormancy_sweep)
      'nomadic_capital_restore', -- bigquery/167 (renamed from capital_dormancy_restore)
      'account_fee'              -- bigquery/213 (recurring IBKR account / market-data fee)
    )
    OR source LIKE 'backfill-%'
    )
  )

-- Parallel-run dbt port of bigquery/148_audit_2026_08_08_fixes.sql:state.cash_flows_backfill_check — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
SELECT
  (SELECT ROUND(SUM(amount), 2) FROM {{ source('events', 'cash_flows') }}
   WHERE flow_date <= DATE '2026-07-03') AS cash_flows_total_asof_backfill,
  CAST(9446.86 AS NUMERIC) AS expected_total,
  COALESCE((SELECT ROUND(SUM(amount), 2) FROM {{ source('events', 'cash_flows') }}
            WHERE flow_date <= DATE '2026-07-03') = CAST(9446.86 AS NUMERIC), FALSE) AS reconciled

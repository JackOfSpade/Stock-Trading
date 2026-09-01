-- Parallel-run dbt port of bigquery/161_withdrawal_after_the_fact.sql:state.cash_flow_candidates_open — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
SELECT candidate_key, observed_date, direction, amount, evidence, note, source, event_ts,
  DATE_DIFF(CURRENT_DATE('America/Denver'), observed_date, DAY) AS days_open
FROM (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY candidate_key ORDER BY event_ts DESC, candidate_id) AS rn
  FROM {{ source('events', 'cash_flow_candidates') }}
)
WHERE rn = 1 AND status = 'open'

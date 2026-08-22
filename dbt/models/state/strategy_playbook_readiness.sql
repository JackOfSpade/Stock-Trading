-- Parallel-run dbt port of bigquery/37_self_improvement_autonomy.sql:state.strategy_playbook_readiness — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
WITH edge AS (
  SELECT COUNTIF(trustworthy_edge) AS n_trustworthy
  FROM {{ ref('calibration_shrunk') }}
),
proc AS (
  -- BUG FIX (rev 2026-07-10b, code-review finding #8): dvr_ok/fb_ok used ANY_VALUE(min_n_met) over
  -- declared_vs_realized/forecast_bias, which each return ONE ROW PER STRATEGY — ANY_VALUE with no
  -- filter/aggregation picks an arbitrary single strategy's flag, not "any strategy meets the bar".
  -- Now consistent with cm_ok's COUNTIF(...)>0 "any strategy" semantics.
  SELECT
    (SELECT COUNTIF(min_n_met) FROM {{ ref('conviction_monotonicity') }}) > 0 AS cm_ok,
    (SELECT COUNTIF(min_n_met) FROM {{ ref('declared_vs_realized') }}) > 0 AS dvr_ok,
    (SELECT COUNTIF(min_n_met) FROM {{ ref('forecast_bias') }}) > 0 AS fb_ok
)
SELECT
  edge.n_trustworthy,
  edge.n_trustworthy > 0 AS edge_ok,
  (CAST(proc.cm_ok AS INT64) + CAST(proc.dvr_ok AS INT64) + CAST(proc.fb_ok AS INT64)) AS n_process_min_n_met,
  (CAST(proc.cm_ok AS INT64) + CAST(proc.dvr_ok AS INT64) + CAST(proc.fb_ok AS INT64)) >= 2 AS process_ok,
  (edge.n_trustworthy > 0
   AND (CAST(proc.cm_ok AS INT64) + CAST(proc.dvr_ok AS INT64) + CAST(proc.fb_ok AS INT64)) >= 2) AS ready_for_change
FROM edge CROSS JOIN proc

-- Parallel-run dbt port of bigquery/60_shadow_stuck_cull.sql:state.strategy_shadow_readiness — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
WITH agg AS (
  SELECT strategy_code,
    COUNT(DISTINCT incubation_day) AS shadow_days,
    SUM(signals_generated) AS signals_generated,
    SUM(scaffolding_faults) AS scaffolding_faults
  FROM {{ source('analytics_external', 'strategy_incubation_perf') }}
  WHERE phase = 'shadow'
  GROUP BY strategy_code
),
freq AS (
  SELECT candidate_code AS strategy_code, declared_annual_roundtrips,
    CASE WHEN declared_annual_roundtrips IS NULL OR declared_annual_roundtrips >= 10 THEN 10
         ELSE GREATEST(3, CAST(CEIL(declared_annual_roundtrips / 2) AS INT64))
    END AS annualized_rate_floor
  FROM {{ source('state_external', 'strategy_candidates') }}
  -- Defense-in-depth (2026-07-18 audit, mirrors state.strategy_paper_readiness's freq): candidate_code
  -- has no enforced uniqueness and four independent routines write NEW rows; a duplicate would fan out
  -- the LEFT JOIN into duplicate readiness rows and corrupt the `ready`/`stuck` booleans. Newest wins.
  QUALIFY ROW_NUMBER() OVER (PARTITION BY candidate_code ORDER BY created_ts DESC) = 1
),
ars AS (SELECT enabled, incubation_frozen FROM {{ ref('arsenal_enabled') }})
SELECT
  r.strategy_code,
  COALESCE(a.shadow_days, 0) AS shadow_days,
  COALESCE(a.signals_generated, 0) AS signals_generated,
  COALESCE(a.scaffolding_faults, 0) AS scaffolding_faults,
  fr.declared_annual_roundtrips,
  GREATEST(30, CAST(CEIL(COALESCE(fr.annualized_rate_floor, 10) * (20.0 / 252.0) * 15) AS INT64)) AS signal_rate_ceiling,
  COALESCE(a.shadow_days, 0) >= 20 AS days_met,
  (COALESCE(a.signals_generated, 0) >= 1
   AND COALESCE(a.signals_generated, 0) <=
       GREATEST(30, CAST(CEIL(COALESCE(fr.annualized_rate_floor, 10) * (20.0 / 252.0) * 15) AS INT64))
  ) AS signal_rate_ok,
  COALESCE(a.scaffolding_faults, 0) = 0 AS scaffolding_ok,
  (ars.enabled AND NOT ars.incubation_frozen) AS arsenal_ok,
  NOT EXISTS (SELECT 1 FROM {{ source('ops', 'roster_change_log') }} cl
              WHERE cl.change_key = CONCAT(r.strategy_code, ':SHADOW->PAPER')) AS not_already_transitioned,
  -- stuck (2026-07-15, mirrors PAPER's ITEM 9 `stuck` exactly): shadow_days has run long enough
  -- (>=400) that continuing to wait is no longer reasonable, independent of `ready` below — read by
  -- Claude_Task_Plan.md SL3 STEP 4's new SHADOW TIME-CULL, not itself a component of `ready` (a stuck
  -- candidate is culled to REJECTED, not promoted). Covers all three SHADOW dead-ends in one flag:
  -- signal_rate_ok FALSE because the floor (>=1) never cleared, OR because the ceiling was breached
  -- (a broken signal path firing spuriously), OR scaffolding_ok FALSE (a scaffolding fault never
  -- cleared).
  (COALESCE(a.shadow_days, 0) >= 400
   AND NOT (
     (COALESCE(a.signals_generated, 0) >= 1
      AND COALESCE(a.signals_generated, 0) <=
          GREATEST(30, CAST(CEIL(COALESCE(fr.annualized_rate_floor, 10) * (20.0 / 252.0) * 15) AS INT64)))
     AND COALESCE(a.scaffolding_faults, 0) = 0
   )) AS stuck,
  (COALESCE(a.shadow_days, 0) >= 20
   AND COALESCE(a.signals_generated, 0) >= 1
   AND COALESCE(a.signals_generated, 0) <=
       GREATEST(30, CAST(CEIL(COALESCE(fr.annualized_rate_floor, 10) * (20.0 / 252.0) * 15) AS INT64))
   AND COALESCE(a.scaffolding_faults, 0) = 0
   AND ars.enabled AND NOT ars.incubation_frozen
   AND NOT EXISTS (SELECT 1 FROM {{ source('ops', 'roster_change_log') }} cl
                   WHERE cl.change_key = CONCAT(r.strategy_code, ':SHADOW->PAPER'))) AS ready
FROM {{ source('state_external', 'strategy_roster') }} r
LEFT JOIN agg a USING (strategy_code)
LEFT JOIN freq fr USING (strategy_code)
CROSS JOIN ars
WHERE r.current_state = 'SHADOW'

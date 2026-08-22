-- Parallel-run dbt port of bigquery/37_self_improvement_autonomy.sql:state.calibration_param_readiness — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
WITH reg AS (
  SELECT r.param_key, r.conviction_tier, r.current_value, r.implied_rate
  FROM {{ source('state_external', 'calibration_param_registry') }} r
),
cal AS (
  SELECT conviction, wilson_low, wilson_high, closed, trustworthy_edge
  FROM {{ ref('calibration_shrunk') }}
),
joined AS (
  SELECT
    reg.param_key, reg.conviction_tier, reg.current_value, reg.implied_rate,
    cal.wilson_low, cal.wilson_high, cal.closed,
    (reg.implied_rate < cal.wilson_low OR reg.implied_rate > cal.wilson_high) AS interval_excludes_anchor,
    EXISTS (SELECT 1 FROM {{ source('state_external', 'param_change_provenance') }} pv
            WHERE pv.param_key = reg.param_key AND pv.change_type = 'SHADOW' AND pv.shadow_ok) AS shadow_proven,
    NOT EXISTS (SELECT 1 FROM {{ source('state_external', 'param_change_provenance') }} pv
                WHERE pv.param_key = reg.param_key AND pv.change_type = 'CHANGE'
                  AND pv.new_value = CAST(reg.implied_rate AS STRING)) AS not_already_changed
  FROM reg
  LEFT JOIN cal ON cal.conviction = reg.conviction_tier
)
SELECT
  param_key, conviction_tier, current_value, implied_rate, wilson_low, wilson_high,
  interval_excludes_anchor, shadow_proven, not_already_changed,
  (interval_excludes_anchor AND closed >= 15 AND shadow_proven AND not_already_changed) AS ready_for_change,
  (SELECT COALESCE(MAX(degraded_revert), FALSE)
     FROM {{ ref('param_oos_degradation') }} d WHERE d.param_key = joined.param_key) AS auto_revert_due
FROM joined

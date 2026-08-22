-- Parallel-run dbt port of bigquery/37_self_improvement_autonomy.sql:state.param_oos_degradation — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
WITH live_change AS (
  SELECT param_key, new_value, change_ts,
    CAST(JSON_VALUE(trigger_evidence_json, '$.implied_rate') AS FLOAT64) AS pre_change_implied_rate
  FROM {{ source('state_external', 'param_change_provenance') }}
  WHERE change_type = 'CHANGE'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY param_key ORDER BY change_ts DESC) = 1
),
reg AS (SELECT param_key, conviction_tier FROM {{ source('state_external', 'calibration_param_registry') }}),
post AS (
  -- realized win-rate on the mapped tier, ENTERED on/after the change (see fix note above)
  SELECT r.param_key,
    COUNTIF(cf.was_profitable) AS wins_post,
    COUNTIF(cf.position_closed) AS closed_post
  FROM live_change lc
  JOIN reg r USING (param_key)
  JOIN {{ ref('conviction_features') }} cf
    ON cf.conviction = r.conviction_tier
   AND cf.position_closed
   AND cf.entry_date >= DATE(lc.change_ts, 'America/Denver')
  GROUP BY r.param_key
)
SELECT
  lc.param_key,
  lc.pre_change_implied_rate,
  p.wins_post, p.closed_post,
  ROUND(SAFE_DIVIDE(p.wins_post, p.closed_post), 3) AS realized_rate_post,
  -- degraded (auto-REVERT trigger): >=10 post-change closed trades AND realized materially (>0.10) below
  -- the anchor the change moved away from. Default-not-revert: below the N floor reads FALSE (no revert on
  -- noise), matching the "never ratchet on a wide interval" discipline.
  (p.closed_post >= 10
   AND SAFE_DIVIDE(p.wins_post, p.closed_post) < lc.pre_change_implied_rate - 0.10) AS degraded_revert
FROM live_change lc
LEFT JOIN post p USING (param_key)

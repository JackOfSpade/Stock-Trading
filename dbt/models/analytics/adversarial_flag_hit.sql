-- Parallel-run dbt port of bigquery/42_adversarial_flag_hit.sql:analytics.adversarial_flag_hit — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH latest_outcome AS (
  SELECT * FROM {{ source('events', 'premortem_flag_outcomes') }}
  QUALIFY ROW_NUMBER() OVER (PARTITION BY flag_id ORDER BY outcome_judged_ts DESC) = 1
)
SELECT
  f.strategy_code,
  f.tier,
  COUNT(*) AS n_flags_registered,
  COUNTIF(o.flag_id IS NOT NULL) AS n_judged,
  COUNTIF(o.trigger_fired) AS n_trigger_fired,
  COUNTIF(o.trigger_fired AND o.fired_before_loss) AS n_fired_before_loss,
  ROUND(SAFE_DIVIDE(COUNTIF(o.trigger_fired), COUNTIF(o.flag_id IS NOT NULL)), 3) AS trigger_fire_rate,
  ROUND(SAFE_DIVIDE(COUNTIF(o.trigger_fired AND o.fired_before_loss), COUNTIF(o.trigger_fired)), 3) AS predictive_catch_rate,
  (COUNTIF(o.flag_id IS NOT NULL) >= 5) AS min_n_met
FROM {{ source('events', 'premortem_flags') }} f
LEFT JOIN latest_outcome o ON o.flag_id = f.flag_id
GROUP BY f.strategy_code, f.tier
ORDER BY f.strategy_code, f.tier

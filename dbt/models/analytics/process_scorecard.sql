-- Parallel-run dbt port of bigquery/26_process_metrics.sql:analytics.process_scorecard — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
--
-- Extended 2026-09-14 in lockstep with bigquery/239_process_scorecard_above_band_coverage.sql (alert
-- 8e8747ed-c8b0-4e87-8d4c-79c23bee765f): adds forecast_pct_above_band, mirroring forecast_pct_below_band
-- exactly. No new ref()/source() needed — same ref('forecast_bias'), one new subquery column.
SELECT
  s AS strategy,
  (SELECT COUNT(*) FROM {{ ref('conviction_monotonicity') }} m WHERE m.strategy = s) AS conviction_tiers_observed,
  (SELECT ANY_VALUE(min_n_met) FROM {{ ref('declared_vs_realized') }} d WHERE d.strategy = s) AS declared_vs_realized_min_n_met,
  (SELECT go_minus_opened FROM {{ ref('declared_vs_realized') }} d WHERE d.strategy = s) AS go_minus_opened,
  (SELECT pct_below_band FROM {{ ref('forecast_bias') }} f WHERE f.strategy = s) AS forecast_pct_below_band,
  (SELECT pct_above_band FROM {{ ref('forecast_bias') }} f WHERE f.strategy = s) AS forecast_pct_above_band,
  (SELECT COALESCE(min_n_met, FALSE) FROM {{ ref('forecast_bias') }} f WHERE f.strategy = s) AS forecast_min_n_met
-- roster-derived enumeration (rev 2026-07-10 — Strategy Arsenal autonomy conversion, owner directive):
-- the scorecard rolls up the currently-active strategies, not the bare ['A'..'E'] literal.
-- check_roster_consistency.py asserts no bare literal remains here; state.active_strategy_codes is
-- defined in bigquery/35_strategy_arsenal.sql, which must be applied before this file.
FROM UNNEST(ARRAY(SELECT strategy_code FROM {{ source('state_external', 'active_strategy_codes') }})) s

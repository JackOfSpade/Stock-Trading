-- Adds pct_above_band (analytics.forecast_bias) and forecast_pct_above_band (analytics.process_scorecard)
-- alongside the below-band columns those two views already carry. Project: stock-trading-498512. Apply
-- after bigquery/26_process_metrics.sql (both views' prior definitions).
--
-- WHY (alert 8e8747ed-c8b0-4e87-8d4c-79c23bee765f, category forecast_above_band_unsurfaced, MEASURED
-- 2026-09-01, reconfirmed live 2026-09-14 with two more weeks of D evidence): forecast_bias already
-- computed n_above_band / n_in_band internally but only ever exposed pct_below_band as a ratio, and
-- process_scorecard pulled only that one ratio through as forecast_pct_below_band. 2026-09-01: B 40
-- forecast points, 0 below-band, 21 above (52.5%); D 43 points, 0 below, 22 above (51.2%) -- a
-- persistent one-sided skew, not the ~5% a nominal 90% interval implies. The consequence is not
-- cosmetic: the same flat central forecast path that lets a rising equity curve exit the top of the
-- band also pins pi_lower well under the live trajectory, so the below-band downside read -- the only
-- limb of M5 that can raise an alert -- is desensitised, and a 0-below-band reading alone reads as
-- weak evidence of health, not strong.
--
-- ADDITIVE ONLY: both new columns are read-only ratios computed identically to the existing ones
-- (SAFE_DIVIDE over the same COUNT(*) denominator, ROUND to 3 places); no trigger/alert semantics
-- change anywhere, matching bigquery/06_forecast.sql's "advisory only -- never a trigger" framing for
-- this whole signal family. forecast_min_n_met is unchanged and continues to gate BOTH ratios, since
-- both come from the same forecast_bias row; state.strategy_playbook_readiness's fb_ok (bigquery/37,
-- COUNTIF(min_n_met) > 0 over the whole view) is unaffected by an added column -- verified 2026-09-14.
--
-- dbt lockstep: dbt/models/analytics/forecast_bias.sql and dbt/models/analytics/process_scorecard.sql
-- are parallel-run mechanical ports of these two views (dbt/README.md) and are updated in the SAME
-- commit with the identical new lines, then re-verified by scripts/verify_dbt_port.py -- required
-- because CI's dbt_guard step runs with continue-on-error=false while repo var DBT_PARITY=block
-- (confirmed live 2026-09-14 via `gh variable list`), i.e. an unmirrored port-drift here is a hard
-- merge-blocking CI failure, not an advisory one.
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.forecast_bias` AS
SELECT
  strategy,
  COUNT(*) AS n_forecast_points,
  COUNTIF(below_band) AS n_below_band,
  COUNTIF(above_band) AS n_above_band,
  COUNTIF(NOT below_band AND NOT above_band) AS n_in_band,
  ROUND(SAFE_DIVIDE(COUNTIF(below_band), COUNT(*)), 3) AS pct_below_band,
  ROUND(SAFE_DIVIDE(COUNTIF(above_band), COUNT(*)), 3) AS pct_above_band,
  (COUNT(*) >= 8) AS min_n_met
FROM `stock-trading-498512.analytics.twr_forecast_vs_actual_all_vintages`
GROUP BY strategy;

CREATE OR REPLACE VIEW `stock-trading-498512.analytics.process_scorecard` AS
SELECT
  s AS strategy,
  (SELECT COUNT(*) FROM `stock-trading-498512.analytics.conviction_monotonicity` m WHERE m.strategy = s) AS conviction_tiers_observed,
  (SELECT ANY_VALUE(min_n_met) FROM `stock-trading-498512.analytics.declared_vs_realized` d WHERE d.strategy = s) AS declared_vs_realized_min_n_met,
  (SELECT go_minus_opened FROM `stock-trading-498512.analytics.declared_vs_realized` d WHERE d.strategy = s) AS go_minus_opened,
  (SELECT pct_below_band FROM `stock-trading-498512.analytics.forecast_bias` f WHERE f.strategy = s) AS forecast_pct_below_band,
  (SELECT pct_above_band FROM `stock-trading-498512.analytics.forecast_bias` f WHERE f.strategy = s) AS forecast_pct_above_band,
  (SELECT COALESCE(min_n_met, FALSE) FROM `stock-trading-498512.analytics.forecast_bias` f WHERE f.strategy = s) AS forecast_min_n_met
-- roster-derived enumeration (rev 2026-07-10 — Strategy Arsenal autonomy conversion, owner directive):
-- the scorecard rolls up the currently-active strategies, not the bare ['A'..'E'] literal.
-- check_roster_consistency.py asserts no bare literal remains here; state.active_strategy_codes is
-- defined in bigquery/35_strategy_arsenal.sql, which must be applied before this file.
FROM UNNEST(ARRAY(SELECT strategy_code FROM `stock-trading-498512.state.active_strategy_codes`)) s;

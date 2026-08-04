-- Process-metrics scorecard — decision-quality signals valid at N=8 (2026-07-03, self-improvement
-- audit S-7/B-9). Project: stock-trading-498512. Apply after 04_analytics.sql (conviction_features) +
-- 06_forecast.sql (twr_forecast_vs_actual_all_vintages -- forecast_bias reads the all-vintages view,
-- ITEM 21 fix 2026-07-11).
--
-- WHY: the only active learning signal is P&L on rare closes (8 B, 0 D), so any parameter fit is years
-- out and would overfit. But PROCESS signals accrue much faster (per decision / per forecast point, not
-- per rare close): whether stated conviction rank-orders realized outcomes, whether the routine's
-- declared intent (GO theses) matches what actually got staged, and whether the monthly TWR forecast is
-- biased. None of these fit a parameter — they are read-only diagnostics reported as raw counts, never
-- p-values, each carrying an explicit min-N floor (`min_n_met`) so a thin cell reads as "not enough data"
-- rather than a false signal. NOT included here: an "adversarial_flag_hit" catch-rate metric (did a
-- pre-registered adversarial-review flag predict a realized loss) — that needs an LLM judgment made
-- ONCE at close time from the ORIGINAL review text (to avoid hindsight relabeling) and a new logged
-- field, which is a routine-instruction change, not a pure-SQL view; deferred as documented future work.

-- ===== analytics.conviction_monotonicity — does higher conviction rank-order higher realized P&L? =====
-- Reported as raw per-tier counts + avg P&L, NEVER a p-value or a single pass/fail boolean — at ~1-3
-- closed trades per tier this is directional-only, for a human/LLM to read qualitatively alongside the
-- Operating_Protocols §8 conviction-calibration ladder, not an automated trigger.
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.conviction_monotonicity` AS
SELECT
  strategy, conviction, conviction_ordinal,
  COUNT(*) AS n_closed,
  ROUND(AVG(realized_pnl), 3) AS avg_realized_pnl,
  COUNTIF(was_profitable) AS n_wins,
  (COUNT(*) >= 5) AS min_n_met   -- directional even below this; a per-tier floor for "worth reading at all"
FROM `stock-trading-498512.analytics.conviction_features`
WHERE position_closed AND conviction_ordinal IS NOT NULL
GROUP BY strategy, conviction, conviction_ordinal
ORDER BY strategy, conviction_ordinal;

-- ===== analytics.declared_vs_realized — GO decisions vs positions actually opened, per strategy =====
-- A large gap (many GO decisions, few OPEN position_events) flags either a staging pipeline problem
-- (guard blocks, order-craft failures) or a pattern of GO decisions that don't survive to execution —
-- both worth a human look, neither actionable from this view alone.
--
-- SUPERSEDED LIVE by bigquery/131_declared_vs_realized_distinct_positions.sql — current single
-- source of truth for this object (chain: 26 -> 118 -> 131). The go_theses CTE below re-derives its own count with an exact-string
-- `entry_type = 'thesis-construction' AND decision = 'GO'` filter; bigquery/116 fixed that exact bug
-- class in thesis_outcomes/conviction_features/thesis_outcome_summary but MISSED this sibling view, so
-- from 2026-07-30 the two paths silently diverged (this one reported 19 GO theses vs the corrected 21,
-- dropping B:ISRG f90e7c15 and D:GOOGL fd464178). 118 reads analytics.thesis_outcomes WHERE
-- is_go_family instead, so the vocabulary lives in ONE place. Kept here, unmodified, for DR-rebuild
-- apply-in-order reference only. DO NOT re-apply this CREATE statement live in isolation.
--
-- SUPERSEDED LIVE by bigquery/136_declared_vs_realized_orphan_sides.sql (2026-08-04) — current single
-- source of truth for this object. The chain is 26 -> 118 -> 131 (COUNT(DISTINCT position_key)) -> 136
-- (adds n_go_theses_without_position / n_positions_without_go_thesis); each intermediate file carries
-- its own marker. Name 136, not 118, when looking for the live definition.
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.declared_vs_realized` AS
WITH go_theses AS (
  SELECT strategy, COUNT(*) AS go_count
  FROM `stock-trading-498512.events.decision_log`
  WHERE entry_type = 'thesis-construction' AND decision = 'GO'
  GROUP BY strategy
),
opened AS (
  SELECT strategy, COUNT(*) AS opened_count
  FROM `stock-trading-498512.events.position_events`
  WHERE event_type = 'OPEN'
  GROUP BY strategy
)
SELECT
  COALESCE(g.strategy, o.strategy) AS strategy,
  COALESCE(g.go_count, 0) AS go_theses,
  COALESCE(o.opened_count, 0) AS positions_opened,
  COALESCE(g.go_count, 0) - COALESCE(o.opened_count, 0) AS go_minus_opened,
  (COALESCE(g.go_count, 0) >= 5) AS min_n_met
FROM go_theses g
FULL OUTER JOIN opened o USING (strategy);

-- ===== analytics.forecast_bias — is the monthly TWR AI.FORECAST systematically biased? =====
-- Rolling tally of realized-vs-forecast-band outcomes, accumulated across ALL forecast vintages
-- (bigquery/06_forecast.sql analytics.twr_forecast_vs_actual_all_vintages). A sustained skew toward
-- below_band (realized consistently worse than forecast) or above_band flags the forecast itself as
-- biased -- advisory, per its own design (06_forecast.sql: "never a trigger"). Self-bootstrapping:
-- zero rows until M5 has run at least twice (one run to forecast, one elapsed period to compare).
-- FIX (ITEM 21, 2026-07-11): previously read the single-latest-vintage twr_forecast_vs_actual, so this
-- tally reset to ~zero on every M5 run and could never accumulate enough evidence to catch a
-- persistently biased forecaster. Now reads the all-vintages view -- append-only, so the tally only
-- grows across M5 runs, same fail-closed min_n_met>=8 floor as before.
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.forecast_bias` AS
SELECT
  strategy,
  COUNT(*) AS n_forecast_points,
  COUNTIF(below_band) AS n_below_band,
  COUNTIF(above_band) AS n_above_band,
  COUNTIF(NOT below_band AND NOT above_band) AS n_in_band,
  ROUND(SAFE_DIVIDE(COUNTIF(below_band), COUNT(*)), 3) AS pct_below_band,
  (COUNT(*) >= 8) AS min_n_met
FROM `stock-trading-498512.analytics.twr_forecast_vs_actual_all_vintages`
GROUP BY strategy;

-- ===== analytics.process_scorecard — one-row-per-strategy rollup for the weekly/monthly read =====
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.process_scorecard` AS
SELECT
  s AS strategy,
  (SELECT COUNT(*) FROM `stock-trading-498512.analytics.conviction_monotonicity` m WHERE m.strategy = s) AS conviction_tiers_observed,
  (SELECT ANY_VALUE(min_n_met) FROM `stock-trading-498512.analytics.declared_vs_realized` d WHERE d.strategy = s) AS declared_vs_realized_min_n_met,
  (SELECT go_minus_opened FROM `stock-trading-498512.analytics.declared_vs_realized` d WHERE d.strategy = s) AS go_minus_opened,
  (SELECT pct_below_band FROM `stock-trading-498512.analytics.forecast_bias` f WHERE f.strategy = s) AS forecast_pct_below_band,
  (SELECT COALESCE(min_n_met, FALSE) FROM `stock-trading-498512.analytics.forecast_bias` f WHERE f.strategy = s) AS forecast_min_n_met
-- roster-derived enumeration (rev 2026-07-10 — Strategy Arsenal autonomy conversion, owner directive):
-- the scorecard rolls up the currently-active strategies, not the bare ['A'..'E'] literal.
-- check_roster_consistency.py asserts no bare literal remains here; state.active_strategy_codes is
-- defined in bigquery/35_strategy_arsenal.sql, which must be applied before this file.
FROM UNNEST(ARRAY(SELECT strategy_code FROM `stock-trading-498512.state.active_strategy_codes`)) s;

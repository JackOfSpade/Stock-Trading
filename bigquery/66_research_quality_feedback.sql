-- GO-side outcome-attribution summary (self-improvement audit 2026-07-15, architecture recommendation
-- "Architect#4" — 5th self-improvement loop, research-quality feedback). Project: stock-trading-498512.
-- Apply after 04_analytics.sql (analytics.thesis_outcomes).
--
-- WHY: `events.nogo_shadow` / `analytics.nogo_counterfactual_summary` (bigquery/28_nogo_shadow.sql)
-- already close the loop for NO-GO decisions (what would have happened if we'd bought). There was no
-- GO-side counterpart. Investigated before building anything: `analytics.thesis_outcomes`
-- (bigquery/04_analytics.sql, mirrored in dbt/models/analytics/thesis_outcomes.sql) ALREADY joins every
-- GO/NO-GO thesis-construction decision to its real eventual outcome (`was_profitable`, `realized_pnl`,
-- `regime_state`) — the outcome-ATTRIBUTION mechanism this recommendation asked for already exists and
-- is NOT rebuilt here. What was actually missing is the AGGREGATION layer: a per-(strategy, sub_pattern)
-- tally an operator/routine can read at a glance, exactly analogous to `nogo_counterfactual_summary`'s
-- per-sub-pattern tally over `nogo_counterfactual`. That aggregation is the one thing this file adds.
--
-- SCOPE, deliberately conservative (mirrors the `cross_model_referee_independence` SHADOW-stage build in
-- bigquery/61_cross_model_referee_shadow.sql): this ships the MEASUREMENT view only. It does NOT ship a
-- `state.research_quality_readiness` / self-apply mechanism, because the architect recommendation's
-- "persistent above-/below-chance signal on ONE pre-declared, version-controlled knob" presupposes a
-- specific research-criterion constant to tune — no such knob is identified or version-controlled today,
-- and inventing one to wire a fake auto-apply path would be exactly the kind of unfounded self-modifying
-- change the audit's own sequencing discipline (data gate before mechanism) warns against. Building a
-- `ready_for_change` stub that can never legitimately read TRUE is worse than not building it: it invites
-- a later routine to treat it as real gating logic. Registering + wiring the SHADOW read is enough for now;
-- promotion to a knob-specific active_auto readiness view is explicit future work (see
-- ops/autonomy_levels.yaml loop `research_quality_feedback`, gate_to_next_stage).
--
-- ALSO NEVER "a rate to act on" (mirrors nogo_counterfactual_summary's own comment verbatim): at current
-- volume (~9 closed GO theses account-wide as of 2026-07-15) any per-sub-pattern win rate is noise: report
-- raw counts, gated by `min_n_met`, never a computed rate a routine reads as a trigger.

-- ===== analytics.thesis_outcome_summary — per-(strategy, sub_pattern) GO-thesis outcome tally =====
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.thesis_outcome_summary` AS
SELECT
  strategy,
  COALESCE(sub_pattern, '(unclassified)') AS sub_pattern,
  COUNT(*) AS n_theses,
  COUNTIF(position_closed) AS n_closed,
  COUNTIF(position_closed AND was_profitable) AS n_profitable,
  COUNTIF(position_closed AND NOT was_profitable) AS n_unprofitable,
  -- Directional-only floor; below it, the tally is a data point, never a trigger (min_n=15 per the
  -- architect recommendation's own stated floor — 3x nogo_counterfactual_summary's min_n=5, since a real
  -- position's realized P&L carries more weight per observation than a counterfactual SGOV-vs-price delta).
  (COUNTIF(position_closed) >= 15) AS min_n_met
FROM `stock-trading-498512.analytics.thesis_outcomes`
WHERE decision = 'GO'
GROUP BY strategy, sub_pattern
ORDER BY strategy, n_theses DESC;

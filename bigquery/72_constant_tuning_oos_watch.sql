-- Post-change OOS degradation + auto-revert substrate for the process_reliability and
-- execution_quality_tuning loops (loop-completeness audit 2026-07-16) — mirrors
-- state.param_oos_degradation (bigquery/37_self_improvement_autonomy.sql) exactly; revert is
-- always the fail-safe direction (tighter deadline / prior exec rule). Apply AFTER 37.
-- NOTE: exec watch keys on ops.exec_rule_change_log.rule_name — W5 MUST populate rule_name on
-- every change row (a NULL rule_name never joins and the watch reads not-degraded); same for
-- routine+deadline_key on ops.process_constant_change_log. Idempotent (CREATE OR REPLACE);
-- safe to re-run.

-- View A: process_reliability loop OOS watch + auto-revert
CREATE OR REPLACE VIEW `stock-trading-498512.state.process_constant_oos_watch` AS
WITH last_change AS (
  SELECT routine, deadline_key, change_key, change_ts, old_value, new_value
  FROM `stock-trading-498512.ops.process_constant_change_log`
  WHERE NOT ENDS_WITH(change_key, ':REVERT') AND routine IS NOT NULL AND deadline_key IS NOT NULL
  QUALIFY ROW_NUMBER() OVER (PARTITION BY routine, deadline_key ORDER BY change_ts DESC) = 1
),
post AS (
  SELECT lc.routine, lc.deadline_key,
    COUNT(*) AS n_cycles, COUNTIF(o.threat_pattern) AS n_threat
  FROM last_change lc
  JOIN `stock-trading-498512.ops.process_reliability_observations` o
    ON o.routine = lc.routine AND o.deadline_key = lc.deadline_key
   AND TIMESTAMP(o.cycle_date) > lc.change_ts
  GROUP BY 1, 2
)
SELECT lc.*,
  COALESCE(p.n_cycles, 0) AS n_post_cycles,
  COALESCE(p.n_threat, 0) AS n_post_threat,
  (COALESCE(p.n_cycles, 0) >= 3 AND COALESCE(p.n_threat, 0) >= 2
   AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.process_constant_change_log` r
                   WHERE r.change_key = CONCAT(lc.change_key, ':REVERT'))) AS degraded_revert
FROM last_change lc
LEFT JOIN post p ON p.routine = lc.routine AND p.deadline_key = lc.deadline_key;
-- degraded = same (routine, deadline_key) shows threat_pattern on >=2 of the first 3+ post-change W5
-- cycles: the relaxation is chasing a drifting routine; reverting restores the tighter fail-safe
-- deadline so the cadence watchdog alarms instead of being quietly loosened. Default-not-revert below
-- the 3-cycle floor (mirrors param_oos_degradation's >=10-closed-trades discipline). TIMESTAMP(cycle_date)
-- is UTC midnight, so the day-of-change cycle is excluded (conservative).

-- View B: execution_quality_tuning loop OOS watch + auto-revert
CREATE OR REPLACE VIEW `stock-trading-498512.state.exec_rule_oos_watch` AS
WITH last_change AS (
  SELECT change_key, rule_name, change_ts, old_value, new_value
  FROM `stock-trading-498512.ops.exec_rule_change_log`
  WHERE NOT ENDS_WITH(change_key, ':REVERT') AND rule_name IS NOT NULL
  QUALIFY ROW_NUMBER() OVER (PARTITION BY rule_name ORDER BY change_ts DESC) = 1
),
pre AS (
  SELECT lc.rule_name, AVG(q.adverse_slippage_bps) AS avg_pre
  FROM last_change lc
  JOIN `stock-trading-498512.analytics.execution_quality` q
    ON q.fill_ts < lc.change_ts
  WHERE q.adverse_slippage_bps IS NOT NULL
  GROUP BY 1
),
post AS (
  SELECT lc.rule_name, COUNT(*) AS n_post, AVG(q.adverse_slippage_bps) AS avg_post
  FROM last_change lc
  JOIN `stock-trading-498512.analytics.execution_quality` q
    ON q.fill_ts >= lc.change_ts
  WHERE q.adverse_slippage_bps IS NOT NULL
  GROUP BY 1
)
SELECT lc.*, pre.avg_pre, post.n_post, post.avg_post,
  (COALESCE(post.n_post, 0) >= 8
   AND post.avg_post > COALESCE(pre.avg_pre, 0) + 10
   AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.exec_rule_change_log` r
                   WHERE r.change_key = CONCAT(lc.change_key, ':REVERT'))) AS degraded_revert
FROM last_change lc
LEFT JOIN pre ON pre.rule_name = lc.rule_name
LEFT JOIN post ON post.rule_name = lc.rule_name;
-- degraded = >=8 post-change measured fills AND mean adverse slippage >10 bps worse than the all-time
-- pre-change mean (COALESCE 0 baseline if no pre fills). Default-not-revert below the 8-fill floor.
-- rule_name NOT NULL filter: a change row missing rule_name can never arm this watch — hence the header
-- mandate that W5 populate it.

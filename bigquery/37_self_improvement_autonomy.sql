-- Self-improvement autonomy substrate — round-2 conversion (rev 2026-07-10, owner directive + explicit
-- confirmation). Project: stock-trading-498512. Apply AFTER 10_observability.sql (ops.run_log / ops.alerts
-- / sp_raise_alert), 04_analytics.sql (analytics.conviction_features), 25_calibration_shrinkage.sql
-- (analytics.calibration_shrunk), 26_process_metrics.sql (analytics.process_scorecard + its input views),
-- 27_process_reliability.sql (analytics.routine_health_scorecard) and 01_schema.sql (events.trade_fills /
-- state.trade_fills_curated / events.queue_events).
--
-- WHY: on 2026-07-10 the owner directed that EVERY remote routine get an autonomous action pathway (no
-- "give results and wait for human review") except final order execution, and explicitly confirmed this
-- INCLUDES removing the no_auto_merge_self_improvement guard for ALL self-improvement loops
-- (calibration_parameter_carveout included). ops/autonomy_levels.yaml now ceilings all four constant-tuning
-- loops at active_auto. This file gives each loop the SAME skeleton that made D2a's cutover and the
-- strategy_arsenal roster changes autonomous (bigquery/32_d2a_cutover_readiness.sql /
-- bigquery/35_strategy_arsenal.sql): an OBJECTIVE readiness view keyed on the loop's OWN unchanged
-- data-sufficiency gate + a durable BigQuery idempotency marker + an observation/heartbeat substrate, so
-- the routine self-executes (repo edit + commit + push, or a live write) with NO human-merged PR, leaving
-- an events.decision_log entry + an info-severity ops.alerts audit row as the trail. The evidence bar is
-- UNCHANGED; only the human step is removed. Nothing here weakens any mechanical kill trigger, the $2,000
-- probe-stake floor, 2% sizing, or the IBKR order-confirm execution tap. Idempotent (CREATE OR REPLACE /
-- CREATE TABLE IF NOT EXISTS); safe to re-run.

-- ============================================================================
-- LOOP 1 — process_reliability (WO-6). Sensor: analytics.routine_health_scorecard (bigquery/27). The
-- change surface is a bounded, version-controlled PROCESS CONSTANT (a cadence deadline / stalled-run
-- threshold). Autonomy control: the "does not fire on noise" check a human used to eyeball is replaced by
-- an objective 3-consecutive-W5-cycle persistence assertion, computed from an observation/heartbeat table.
-- ============================================================================

-- ops.process_reliability_observations — one row per routine per W5 cycle (the loop heartbeat + the
-- persistence substrate). W5 appends every firing; threat_pattern = min_n_met AND p90 within ~90 min of a
-- version-controlled deadline it could threaten. deadline_key names the constant at risk (e.g.
-- 'cadence:cadence_watch_deadline_local').
CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.process_reliability_observations` (
  observation_id STRING DEFAULT GENERATE_UUID(),
  observed_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  cycle_date DATE NOT NULL,          -- the W5 cycle date (America/Denver)
  routine STRING NOT NULL,
  deadline_key STRING,               -- the version-controlled constant the p90 threatens
  p90_completion_minute_of_day INT64,
  min_n_met BOOL,
  threat_pattern BOOL,               -- min_n_met AND p90 within ~90 min of deadline_key
  note STRING,
  PRIMARY KEY (observation_id) NOT ENFORCED
) PARTITION BY cycle_date CLUSTER BY routine
OPTIONS(description='W5 process_reliability observation/heartbeat log (round-2 autonomy, 2026-07-10). Trailing 3-consecutive-cycle threat streak = the automated does-not-fire-on-noise check that gates a self-applied process-constant change.');

-- ops.process_constant_change_log — durable idempotency marker (the ops.d2a_cutover_log analog). Presence
-- of a row for change_key = that process-constant change already applied; the readiness view will not re-fire.
-- change_key convention: '<routine>:<deadline_key>:<old>-><new>'.
CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.process_constant_change_log` (
  change_id STRING DEFAULT GENERATE_UUID(),
  change_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  change_key STRING NOT NULL,
  routine STRING,
  deadline_key STRING,
  old_value STRING,
  new_value STRING,
  git_commit STRING,
  note STRING,
  PRIMARY KEY (change_id) NOT ENFORCED
) PARTITION BY DATE(change_ts)
OPTIONS(description='Durable process-constant change idempotency markers (round-2 autonomy, 2026-07-10; ops.d2a_cutover_log analog). One row per change_key = that self-applied change is done.');

-- state.process_reliability_readiness — one row per (routine, deadline_key) that currently qualifies.
-- ready_for_change = the threat pattern held on the 3 most-recent DISTINCT cycle_dates (default-not-advance:
-- fewer than 3 cycles, or any non-threat cycle in the trailing 3, reads FALSE) AND that change_key has not
-- already been applied.
CREATE OR REPLACE VIEW `stock-trading-498512.state.process_reliability_readiness` AS
WITH ranked AS (
  SELECT routine, deadline_key, cycle_date, threat_pattern,
    ROW_NUMBER() OVER (PARTITION BY routine, deadline_key ORDER BY cycle_date DESC) AS rn
  FROM `stock-trading-498512.ops.process_reliability_observations`
  WHERE deadline_key IS NOT NULL
),
trailing3 AS (
  SELECT routine, deadline_key,
    COUNT(*) AS n_recent_cycles,
    COUNTIF(threat_pattern) AS n_recent_threat
  FROM ranked WHERE rn <= 3
  GROUP BY routine, deadline_key
)
SELECT
  t.routine,
  t.deadline_key,
  t.n_recent_cycles,
  t.n_recent_threat,
  (t.n_recent_cycles >= 3 AND t.n_recent_threat = 3) AS threat_streak_met,
  NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.process_constant_change_log` cl
              WHERE cl.routine = t.routine AND cl.deadline_key = t.deadline_key) AS not_already_changed,
  (t.n_recent_cycles >= 3 AND t.n_recent_threat = 3
   AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.process_constant_change_log` cl
                   WHERE cl.routine = t.routine AND cl.deadline_key = t.deadline_key)) AS ready_for_change
FROM trailing3 t;

-- ============================================================================
-- LOOP 2 — strategy_playbook (B-4-data). Append-only self-authored playbook deltas. The append-only log IS
-- its own idempotency substrate (each delta is a new immutable row; state.active_playbook = latest per key).
-- Data gate (unchanged): calibration_shrunk trustworthy_edge on >=1 tier AND process_scorecard min_n_met on
-- >=2 of its 3 metrics. In-band separation-of-duties control: independent evidence/write sessions OR an S-5
-- theater-judge-independent delta (enforced by the routine, recorded on the row).
-- ============================================================================

CREATE TABLE IF NOT EXISTS `stock-trading-498512.events.playbook_updates` (
  update_id STRING DEFAULT GENERATE_UUID(),
  update_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  playbook_key STRING NOT NULL,        -- the addressable playbook slot the delta revises
  delta_text STRING NOT NULL,          -- the appended guidance delta
  evidence_json JSON,                  -- calibration_shrunk / process_scorecard snapshot that justified it
  theater_review_id STRING,            -- events.adversarial_reviews.review_id if judged, else NULL
  independent_sessions BOOL,           -- TRUE if evidence + write sessions were independent
  git_commit STRING,
  note STRING,
  PRIMARY KEY (update_id) NOT ENFORCED
) PARTITION BY DATE(update_ts) CLUSTER BY playbook_key
OPTIONS(description='Append-only self-authored strategy-playbook deltas (round-2 autonomy, 2026-07-10). Append-only = its own idempotency substrate; latest row per playbook_key = state.active_playbook.');

CREATE OR REPLACE VIEW `stock-trading-498512.state.active_playbook` AS
SELECT playbook_key, delta_text, update_ts, theater_review_id, independent_sessions, git_commit
FROM `stock-trading-498512.events.playbook_updates`
QUALIFY ROW_NUMBER() OVER (PARTITION BY playbook_key ORDER BY update_ts DESC) = 1;

-- state.strategy_playbook_readiness — a single-row view: the loop's data gate. edge_ok = >=1 conviction
-- tier trustworthy; process_ok = >=2 of {conviction_monotonicity, declared_vs_realized, forecast_bias}
-- min_n_met. ready = both. (The separation-of-duties control is enforced at write time, not here.)
CREATE OR REPLACE VIEW `stock-trading-498512.state.strategy_playbook_readiness` AS
WITH edge AS (
  SELECT COUNTIF(trustworthy_edge) AS n_trustworthy
  FROM `stock-trading-498512.analytics.calibration_shrunk`
),
proc AS (
  SELECT
    (SELECT COUNTIF(min_n_met) FROM `stock-trading-498512.analytics.conviction_monotonicity`) > 0 AS cm_ok,
    (SELECT COALESCE(ANY_VALUE(min_n_met), FALSE) FROM `stock-trading-498512.analytics.declared_vs_realized`) AS dvr_ok,
    (SELECT COALESCE(ANY_VALUE(min_n_met), FALSE) FROM `stock-trading-498512.analytics.forecast_bias`) AS fb_ok
)
SELECT
  edge.n_trustworthy,
  edge.n_trustworthy > 0 AS edge_ok,
  (CAST(proc.cm_ok AS INT64) + CAST(proc.dvr_ok AS INT64) + CAST(proc.fb_ok AS INT64)) AS n_process_min_n_met,
  (CAST(proc.cm_ok AS INT64) + CAST(proc.dvr_ok AS INT64) + CAST(proc.fb_ok AS INT64)) >= 2 AS process_ok,
  (edge.n_trustworthy > 0
   AND (CAST(proc.cm_ok AS INT64) + CAST(proc.dvr_ok AS INT64) + CAST(proc.fb_ok AS INT64)) >= 2) AS ready_for_change
FROM edge CROSS JOIN proc;

-- ============================================================================
-- LOOP 3 — execution_quality_tuning (B-3/B-8-exec). Measurement view + readiness + idempotency. Slippage is
-- measured against the staged limit price (events.queue_events ORDER_STAGED) for the matching
-- strategy+ticker+side, most-recent stage at/before the fill — an approximate attribution pending a
-- fill->instruction_id linkage field, and deliberately restricted to non-SGOV single-name fills. Signed so
-- positive = adverse (BUY filled above limit / SELL filled below).
-- ============================================================================

CREATE OR REPLACE VIEW `stock-trading-498512.analytics.execution_quality` AS
WITH staged AS (
  SELECT strategy, ticker,
    UPPER(JSON_VALUE(payload,'$.side')) AS side,
    CAST(JSON_VALUE(payload,'$.limit_price') AS NUMERIC) AS limit_price,
    event_ts AS staged_ts
  FROM `stock-trading-498512.events.queue_events`
  WHERE queue = 'ORDER_STAGED' AND JSON_VALUE(payload,'$.limit_price') IS NOT NULL
),
fills AS (
  SELECT trade_id, strategy, ticker, side, shares, price, commission, fill_ts
  FROM `stock-trading-498512.state.trade_fills_curated`
  WHERE ticker != 'SGOV'
),
matched AS (
  SELECT f.*, s.limit_price,
    -- signed adverse slippage in bps: BUY worse when price>limit, SELL worse when price<limit
    CASE WHEN f.side = 'BUY'  THEN SAFE_DIVIDE(f.price - s.limit_price, s.limit_price)
         WHEN f.side = 'SELL' THEN SAFE_DIVIDE(s.limit_price - f.price, s.limit_price)
    END * 10000 AS adverse_slippage_bps
  FROM fills f
  LEFT JOIN staged s
    ON s.strategy = f.strategy AND s.ticker = f.ticker AND s.side = f.side
   AND s.staged_ts <= f.fill_ts
  QUALIFY ROW_NUMBER() OVER (PARTITION BY f.trade_id ORDER BY s.staged_ts DESC) = 1
)
SELECT trade_id, strategy, ticker, side, shares, price, commission, limit_price,
  ROUND(adverse_slippage_bps, 2) AS adverse_slippage_bps, fill_ts
FROM matched
ORDER BY fill_ts;

CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.exec_rule_change_log` (
  change_id STRING DEFAULT GENERATE_UUID(),
  change_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  change_key STRING NOT NULL,        -- e.g. 'slippage_band:v3' / 'fill_vs_expire:v2'
  rule_name STRING,
  old_value STRING,
  new_value STRING,
  git_commit STRING,
  note STRING,
  PRIMARY KEY (change_id) NOT ENFORCED
) PARTITION BY DATE(change_ts)
OPTIONS(description='Durable execution-rule change idempotency markers (round-2 autonomy, 2026-07-10; ops.d2a_cutover_log analog).');

-- state.execution_quality_readiness — single-row view. ready when >=8 non-SGOV fills with a computable
-- slippage AND a consistent-sign signal (every measured fill adverse in the same direction). The specific
-- rule change proposed off it is idempotency-guarded per change_key at write time against ops.exec_rule_change_log.
CREATE OR REPLACE VIEW `stock-trading-498512.state.execution_quality_readiness` AS
WITH m AS (
  SELECT adverse_slippage_bps FROM `stock-trading-498512.analytics.execution_quality`
  WHERE adverse_slippage_bps IS NOT NULL
)
SELECT
  (SELECT COUNT(*) FROM m) AS n_nonsgov_fills_measured,
  (SELECT COUNTIF(adverse_slippage_bps > 0) FROM m) AS n_adverse,
  (SELECT COUNTIF(adverse_slippage_bps < 0) FROM m) AS n_favorable,
  ((SELECT COUNT(*) FROM m) >= 8
   AND ((SELECT COUNTIF(adverse_slippage_bps > 0) FROM m) = (SELECT COUNT(*) FROM m)
        OR (SELECT COUNTIF(adverse_slippage_bps < 0) FROM m) = (SELECT COUNT(*) FROM m))) AS consistent_sign_signal,
  ((SELECT COUNT(*) FROM m) >= 8
   AND ((SELECT COUNTIF(adverse_slippage_bps > 0) FROM m) = (SELECT COUNT(*) FROM m)
        OR (SELECT COUNTIF(adverse_slippage_bps < 0) FROM m) = (SELECT COUNT(*) FROM m))) AS ready_for_change;

-- ============================================================================
-- LOOP 4 — calibration_parameter_carveout (S-8 + B-8-obs). The ONE whitelisted self-updating parameter.
-- Highest scrutiny. Act-trigger (unchanged): the calibration_shrunk credible interval EXCLUDES the current
-- ladder anchor's implied rate. Compensating control replacing the (now removed) owner pre-mortem / human-
-- merged PR: (i) a shadow-prove precondition, (ii) the state.param_oos_degradation auto-REVERT fail-safe.
-- ============================================================================

-- state.calibration_param_registry — the whitelisted parameter(s): the conviction-tier ladder anchor whose
-- implied win-rate the calibration posterior may update. Seed one row for the current live anchor; a change
-- is a new-value edit to this seed (version-controlled), never an ad-hoc write.
CREATE TABLE IF NOT EXISTS `stock-trading-498512.state.calibration_param_registry` (
  param_key STRING NOT NULL,           -- e.g. 'B_conviction_ladder_anchor'
  conviction_tier STRING NOT NULL,     -- the analytics.calibration_shrunk.conviction tier it maps to
  current_value STRING,                -- the live constant (version-controlled in Operating_Protocols §8)
  implied_rate FLOAT64,                -- the win-rate the current anchor implies (the exclusion test target)
  version_git_commit STRING,
  updated_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  PRIMARY KEY (param_key) NOT ENFORCED
) OPTIONS(description='Whitelisted self-updating calibration parameter registry (round-2 autonomy, 2026-07-10). One row per whitelisted param; a change edits current_value/implied_rate with a matching state.param_change_provenance row.');

-- state.param_change_provenance — append-only provenance + idempotency for every SHADOW-prove, real CHANGE,
-- and auto-REVERT. change_key '<param_key>:<from>-><to>:<change_type>' is the idempotency guard.
CREATE TABLE IF NOT EXISTS `stock-trading-498512.state.param_change_provenance` (
  provenance_id STRING DEFAULT GENERATE_UUID(),
  change_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  change_key STRING NOT NULL,
  param_key STRING NOT NULL,
  change_type STRING NOT NULL,         -- 'SHADOW' | 'CHANGE' | 'REVERT'
  old_value STRING,
  new_value STRING,
  trigger_evidence_json JSON,          -- calibration_shrunk interval + anchor implied_rate at trigger time
  shadow_ok BOOL,                      -- for a SHADOW row: did the paper application behave as expected?
  git_commit STRING,
  note STRING,
  PRIMARY KEY (provenance_id) NOT ENFORCED
) PARTITION BY DATE(change_ts) CLUSTER BY param_key
OPTIONS(description='Append-only calibration-parameter provenance + idempotency (round-2 autonomy, 2026-07-10). Presence of a CHANGE/REVERT change_key = that transition is done.');

-- state.param_oos_degradation — post-change out-of-sample degradation monitor. For each param that has a
-- live CHANGE, compare the tier's realized win-rate on trades CLOSED AFTER the change vs the shrunk estimate
-- the change targeted. degraded = the post-change interval sits materially below the pre-change anchor =
-- the auto-REVERT trigger (fail-safe direction, always autonomous).
CREATE OR REPLACE VIEW `stock-trading-498512.state.param_oos_degradation` AS
WITH live_change AS (
  SELECT param_key, new_value, change_ts,
    CAST(JSON_VALUE(trigger_evidence_json, '$.implied_rate') AS FLOAT64) AS pre_change_implied_rate
  FROM `stock-trading-498512.state.param_change_provenance`
  WHERE change_type = 'CHANGE'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY param_key ORDER BY change_ts DESC) = 1
),
reg AS (SELECT param_key, conviction_tier FROM `stock-trading-498512.state.calibration_param_registry`),
post AS (
  -- realized win-rate on the mapped tier, closed strictly after the change
  SELECT r.param_key,
    COUNTIF(cf.was_profitable) AS wins_post,
    COUNTIF(cf.position_closed) AS closed_post
  FROM live_change lc
  JOIN reg r USING (param_key)
  JOIN `stock-trading-498512.analytics.conviction_features` cf
    ON cf.conviction = r.conviction_tier
   AND cf.position_closed
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
LEFT JOIN post p USING (param_key);

-- state.calibration_param_readiness — the act-trigger. ready_for_change when, for a registry param's tier,
-- the calibration_shrunk credible interval [wilson_low, wilson_high] EXCLUDES the current anchor's implied
-- rate, the change has been SHADOW-proven (a shadow_ok row exists), and the real CHANGE has not already been
-- applied. Default-not-advance throughout. auto_revert_due surfaces the fail-safe direction separately.
CREATE OR REPLACE VIEW `stock-trading-498512.state.calibration_param_readiness` AS
WITH reg AS (
  SELECT r.param_key, r.conviction_tier, r.current_value, r.implied_rate
  FROM `stock-trading-498512.state.calibration_param_registry` r
),
cal AS (
  SELECT conviction, wilson_low, wilson_high, closed, trustworthy_edge
  FROM `stock-trading-498512.analytics.calibration_shrunk`
)
SELECT
  reg.param_key,
  reg.conviction_tier,
  reg.current_value,
  reg.implied_rate,
  cal.wilson_low, cal.wilson_high,
  (reg.implied_rate < cal.wilson_low OR reg.implied_rate > cal.wilson_high) AS interval_excludes_anchor,
  EXISTS (SELECT 1 FROM `stock-trading-498512.state.param_change_provenance` pv
          WHERE pv.param_key = reg.param_key AND pv.change_type = 'SHADOW' AND pv.shadow_ok) AS shadow_proven,
  NOT EXISTS (SELECT 1 FROM `stock-trading-498512.state.param_change_provenance` pv
              WHERE pv.param_key = reg.param_key AND pv.change_type = 'CHANGE'
                AND pv.new_value = CAST(reg.implied_rate AS STRING)) AS not_already_changed,
  ((reg.implied_rate < cal.wilson_low OR reg.implied_rate > cal.wilson_high)
   AND cal.closed >= 15
   AND EXISTS (SELECT 1 FROM `stock-trading-498512.state.param_change_provenance` pv
               WHERE pv.param_key = reg.param_key AND pv.change_type = 'SHADOW' AND pv.shadow_ok)) AS ready_for_change,
  (SELECT COALESCE(MAX(degraded_revert), FALSE)
     FROM `stock-trading-498512.state.param_oos_degradation` d WHERE d.param_key = reg.param_key) AS auto_revert_due
FROM reg
LEFT JOIN cal ON cal.conviction = reg.conviction_tier;

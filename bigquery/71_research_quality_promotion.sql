-- Loop-completeness audit 2026-07-16 (LC-4, other parts — the cadence_check.sql dead-man-list
-- addition for 'loop:research_quality_feedback' was already done by the cadence_v4 pass; see
-- bigquery/75_scheduled_query_wrappers.sql ops.sp_sq_cadence_check for that half).
--
-- Completes the research_quality_feedback loop's PERSISTENCE SUBSTRATE + PROMOTION READINESS:
-- previously the SHADOW -> ACTIVE_AUTO gate required "3+ consecutive W5 cycles" of a persisted
-- min_n_met=TRUE signal, but analytics.thesis_outcome_summary (bigquery/66) is a current-state
-- tally with no history, and no routine was assigned to detect persistence or execute the
-- promotion ("Both (1) and (2) are future, separately-committed edits" — no owner). This file
-- adds the per-cycle observation log (ops.process_reliability_observations analog, bigquery/37)
-- and the readiness view W5 now owns reading (Claude_Task_Plan.md's RESEARCH-QUALITY FEEDBACK
-- bullet). Apply after 66_research_quality_feedback.sql.
--
-- ops.loop_promotion_log UNIFIED SCHEMA (shared with any sibling loop-promotion work in this same
-- audit pass, e.g. LC-3's cross_model_referee promotion substrate) — CREATE TABLE IF NOT EXISTS
-- makes whichever file applies first the creator and any other a harmless no-op.
--
-- SUPERSEDED LIVE by bigquery/84_referee_promotion.sql — current single source of truth for
-- ops.loop_promotion_log. The schema below carries forward BYTE-IDENTICAL: 84's own header calls its
-- copy a "Verbatim mirror of bigquery/71's block so this file is self-contained and apply-order-
-- tolerant" — CREATE TABLE IF NOT EXISTS means whichever of the two applies first creates the table
-- and the other is a harmless no-op, so there is no behavior to re-derive here, only which file to
-- treat as authoritative for future edits to the shape. Any future schema change lands as a NEW file
-- that supersedes 84, never as an edit to either definition in place. Kept here, unmodified, for
-- DR-rebuild apply-in-order reference only.

CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.loop_promotion_log` (
  promotion_id STRING DEFAULT GENERATE_UUID(),
  promoted_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  loop_id STRING NOT NULL,
  from_stage STRING NOT NULL,
  to_stage STRING NOT NULL,
  git_commit STRING,
  evidence_json STRING,
  note STRING,
  PRIMARY KEY (promotion_id) NOT ENFORCED
)
PARTITION BY DATE(promoted_ts)
OPTIONS(description='Durable idempotency marker for ops/autonomy_levels.yaml stage promotions (loop-completeness audit 2026-07-16; ops.process_constant_change_log / ops.param_change_provenance analog). One row per executed promotion; readiness views test row-absence for a given (loop_id, to_stage) to stay fail-closed and single-shot.');

-- (B) Per-cycle observation log — the persistence substrate this loop was missing.
-- Mirrors ops.process_reliability_observations (bigquery/37_self_improvement_autonomy.sql).
CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.research_quality_observations` (
  observation_id STRING DEFAULT GENERATE_UUID(),
  observed_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  cycle_date DATE NOT NULL,
  strategy STRING NOT NULL,
  sub_pattern STRING,
  n_theses INT64,
  n_closed INT64,
  n_profitable INT64,
  min_n_met BOOL,
  note STRING,
  PRIMARY KEY (observation_id) NOT ENFORCED
)
PARTITION BY cycle_date
CLUSTER BY strategy
OPTIONS(description='W5 research_quality_feedback per-cycle observation log (loop-completeness audit 2026-07-16; ops.process_reliability_observations analog, bigquery/37). One row per (strategy, sub_pattern) cell with n_closed>=1, written every W5 cycle. Trailing 3-consecutive-W5-cycle min_n_met persistence on a given cell is the promotion trigger read by state.research_quality_promotion_readiness below.');

-- (C) Promotion readiness — fail-closed (zero observation rows today => zero readiness rows).
CREATE OR REPLACE VIEW `stock-trading-498512.state.research_quality_promotion_readiness` AS
WITH ranked AS (
  SELECT strategy, sub_pattern, cycle_date, min_n_met,
         ROW_NUMBER() OVER (PARTITION BY strategy, sub_pattern ORDER BY cycle_date DESC) AS rn
  FROM `stock-trading-498512.ops.research_quality_observations`
), t3 AS (
  SELECT strategy, sub_pattern, COUNT(*) AS n_recent_cycles, COUNTIF(min_n_met) AS n_recent_met
  FROM ranked WHERE rn <= 3 GROUP BY 1, 2
)
SELECT strategy, sub_pattern, n_recent_cycles, n_recent_met,
  (n_recent_cycles >= 3 AND n_recent_met = 3) AS persistence_met,
  NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.loop_promotion_log` pl
              WHERE pl.loop_id = 'research_quality_feedback' AND pl.to_stage = 'active_auto') AS not_already_promoted,
  (n_recent_cycles >= 3 AND n_recent_met = 3
   AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.loop_promotion_log` pl
                   WHERE pl.loop_id = 'research_quality_feedback' AND pl.to_stage = 'active_auto')) AS ready_for_promotion
FROM t3;
-- Returns ZERO ROWS until ops.research_quality_observations has been written to at least once
-- (no row => not-ready, fail-closed) — the observation-writing half of the W5 bullet (Claude_Task_
-- Plan.md's RESEARCH-QUALITY FEEDBACK bullet) is what arms this view. persistence_met requires
-- 3 of the 3 most-recent cycles for a given (strategy, sub_pattern) cell to show min_n_met=TRUE;
-- not_already_promoted keys ops.loop_promotion_log on (loop_id='research_quality_feedback',
-- to_stage='active_auto') so a completed promotion permanently disarms re-firing (single-shot,
-- same idempotency pattern as every other loop-promotion readiness view in this audit pass).

-- Apply the whole file live via the BigQuery MCP (execute_sql), same apply-in-order discipline as
-- bigquery/01..70. [NOT applied live by this commit — local-only implementation round, 2026-07-16;
-- see OWNER_ACTIONS.md.]

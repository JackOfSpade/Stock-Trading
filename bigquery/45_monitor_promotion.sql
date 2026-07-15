-- Monitor-promotion readiness substrate (ITEM 24, self-improvement audit 2026-07-11; finding M-6).
-- Project: stock-trading-498512. Apply after 19_stack_review_fixes_2.sql (state.ddl_drift) and
-- 17_restore_drill.sql (state.restore_health, ops.drill_log).
--
-- WHY: this codebase invented the self-bootstrapping/objective-readiness-view pattern SPECIFICALLY to
-- remove human judgment calls from state transitions (state.d2a_cutover_readiness; every SISA
-- strategy_*_readiness view; ops/autonomy_levels.yaml's whole ladder) -- yet its OWN internal
-- monitoring-promotion ladder (ops/RUNBOOK.md "PROMOTION LADDER") still bottomed out in a human
-- calendar click: ddl_drift -> critical and restore_stale -> critical were each gated on a
-- "[Claude] Review" calendar event (2026-07-14 / 2026-08-04). If the owner dismissed or never acted on
-- those events, a real out-of-band DDL mutation or a stale restore drill would surface only as a buried
-- WARNING line forever, never block anything. (dbt-parity's promotion is already handled via the
-- vars.DBT_PARITY repo setting -- out of scope here, not a calendar-gated case.)
--
-- DESIGN: state.ddl_drift and state.restore_health are LIVE views with no history -- "N consecutive
-- clean runs" cannot be evaluated against a view that only ever shows today's snapshot. This file adds
-- the missing history substrate (ops.monitor_health_history, written unconditionally by cadence_check.sql
-- every run) + two readiness views + a durable idempotency marker, exactly the D2a-cutover skeleton this
-- project reuses everywhere else. Claude_Task_Plan.md's D3 (Calendar & Queue Hygiene) reads both
-- readiness views and self-flips the WARNING->CRITICAL literal in cadence_check.sql when ready --
-- REPO-SIDE only (commit + push, auto-merge on green CI); the LIVE scheduled query still needs the
-- owner's normal console re-paste to take effect, exactly like every other edit to a scheduled query's
-- body in this codebase (bigquery/README.md's stated convention) -- D3 raises an info alert naming the
-- re-paste as the remaining step, it does not claim to have silently changed live behavior. No human
-- REVIEW/APPROVAL step -- the owner's remaining action is mechanical (paste the file D3 already wrote and
-- CI-validated), not a judgment call. Idempotent (CREATE TABLE IF NOT EXISTS / CREATE OR REPLACE VIEW);
-- safe to re-run.
--
-- SIBLING EXTENSION (self-improvement audit ITEM 31, 2026-07-15): bigquery/57_append_only_integrity_
-- promotion.sql gives state.append_only_integrity/integrity_check.sql this SAME self-flip mechanism --
-- it was the one staged-rollout monitor never wired into this ladder. It reuses ops.monitor_health_
-- history/ops.monitor_promotion_log defined here verbatim (a third check_id value; no new tables) but
-- its D3 edit TARGET is bigquery/scheduled_queries/integrity_check.sql, not cadence_check.sql -- a
-- separate scheduled query with no raise_msg accumulator of its own. See that file's header for detail.

-- ============================================================================
-- ops.monitor_health_history — one row per (check_id, check_date), written UNCONDITIONALLY by
-- cadence_check.sql every run (pass or fail) so "N consecutive clean runs" is actually computable.
-- ============================================================================
CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.monitor_health_history` (
  check_id STRING NOT NULL,      -- 'ddl_drift' | 'restore_stale'
  check_date DATE NOT NULL,      -- America/Denver operating day of the cadence_check run
  clean BOOL NOT NULL,           -- TRUE = no drift/staleness detected this run
  logged_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  PRIMARY KEY (check_id, check_date) NOT ENFORCED
) PARTITION BY check_date CLUSTER BY check_id
OPTIONS(description='Daily-logged health history for staged-rollout monitors (ITEM 24, 2026-07-11). Written unconditionally every cadence_check.sql run -- the substrate state.ddl_drift/state.restore_health (both plain live views with no history) cannot provide on their own.');

-- ============================================================================
-- ops.monitor_promotion_log — durable idempotency marker (the ops.d2a_cutover_log analog). Presence of a
-- row for check_id = that monitor already promoted to CRITICAL; the readiness view will not re-fire.
-- ============================================================================
CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.monitor_promotion_log` (
  promotion_id STRING DEFAULT GENERATE_UUID(),
  promotion_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  check_id STRING NOT NULL,
  evidence_json JSON,
  git_commit STRING,
  note STRING,
  PRIMARY KEY (promotion_id) NOT ENFORCED
) PARTITION BY DATE(promotion_ts)
OPTIONS(description='Durable monitor-promotion idempotency markers (ITEM 24, 2026-07-11; ops.d2a_cutover_log analog). One row per check_id = that WARNING-to-CRITICAL promotion already applied.');

-- ============================================================================
-- state.ddl_drift_promotion_readiness — ready once 14 consecutive DISTINCT logged days are clean (the
-- RUNBOOK's own stated "~1-2 weeks of clean daily cadence_check runs" bar) AND not already promoted.
-- Fail-closed: fewer than 14 logged days, or any non-clean day in the trailing 14, reads FALSE.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.ddl_drift_promotion_readiness` AS
WITH by_day AS (
  -- BUG FIX (rev 2026-07-11, adversarial self-audit): dedupe to ONE row per check_date BEFORE ranking.
  -- cadence_check.sql now upserts (MERGE) so a same-day re-run should never create a second row for one
  -- day going forward, but this view defends independently against any duplicate already in the table
  -- (or any future write path that regresses to a plain INSERT) -- ranking raw, non-deduplicated ROWS
  -- would let a trailing-14-ROW window span FEWER than 14 actual distinct calendar days, promoting a day
  -- or more early than the "14 consecutive DISTINCT logged days" bar this view's own header states.
  -- Fail-closed on the (should-be-impossible-post-upsert) same-day-multi-row case: a day counts clean
  -- only if EVERY logged row that day was clean.
  SELECT check_date, LOGICAL_AND(clean) AS clean
  FROM `stock-trading-498512.ops.monitor_health_history`
  WHERE check_id = 'ddl_drift'
  GROUP BY check_date
),
ranked AS (
  SELECT check_date, clean,
    ROW_NUMBER() OVER (ORDER BY check_date DESC) AS rn
  FROM by_day
),
trailing14 AS (
  SELECT COUNT(*) AS n_recent, COUNTIF(clean) AS n_recent_clean
  FROM ranked WHERE rn <= 14
)
SELECT
  t.n_recent, t.n_recent_clean,
  (t.n_recent >= 14 AND t.n_recent_clean = 14) AS baseline_met,
  NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.monitor_promotion_log` pl WHERE pl.check_id = 'ddl_drift') AS not_already_promoted,
  (t.n_recent >= 14 AND t.n_recent_clean = 14
   AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.monitor_promotion_log` pl WHERE pl.check_id = 'ddl_drift')) AS ready
FROM trailing14 t;

-- ============================================================================
-- state.restore_stale_promotion_readiness — ready once state.restore_health.monitored=TRUE (>=1 drill has
-- ever logged) AND that drill passed (the RUNBOOK's own stated bar: ">=1 successful drill logs an
-- ops.drill_log marker") AND not already promoted. Different shape than ddl_drift's streak-count bar,
-- matching each monitor's own documented promotion criterion, not a copy-pasted one-size threshold.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.restore_stale_promotion_readiness` AS
WITH rh AS (SELECT monitored, last_drill_passed, last_drill_date FROM `stock-trading-498512.state.restore_health`)
SELECT
  rh.monitored, rh.last_drill_passed, rh.last_drill_date,
  NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.monitor_promotion_log` pl WHERE pl.check_id = 'restore_stale') AS not_already_promoted,
  (COALESCE(rh.monitored, FALSE) AND COALESCE(rh.last_drill_passed, FALSE)
   AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.monitor_promotion_log` pl WHERE pl.check_id = 'restore_stale')) AS ready
FROM rh;

-- Cross-model referee SHADOW -> ACTIVE_AUTO promotion readiness (DEF-3/DEF-5 follow-up pass, 2026-07-17).
-- Project: stock-trading-498512. Apply after 44_cross_model_referee.sql (ops.sp_score_cross_model_referee,
-- events.adversarial_reviews role='referee_gemini'), 61_cross_model_referee_shadow.sql
-- (analytics.referee_concurrence_calibration) and 71_research_quality_promotion.sql (shared
-- ops.loop_promotion_log). NEW FILE — supersedes nothing.
--
-- PROBLEM: ops/autonomy_levels.yaml's cross_model_referee_independence loop was PROMOTED dormant->shadow
-- on 2026-07-15 (bigquery/61), with the register's gate_to_next_stage stating SHADOW -> ACTIVE_AUTO
-- requires "ONE FULL QUARTERLY CYCLE of observed concurrence" before folding referee_concurs into the
-- SISA readiness views as a fail-closed AND-condition. But — exactly the LC-4 gap bigquery/71 fixed for
-- research_quality_feedback — NO view ever expressed that quarterly-burn-in criterion as a machine-
-- readable readiness signal, and no loop_promotion_log idempotency marker gated it. The loop could run
-- in SHADOW forever with no defined, single-shot promotion trigger. (DEF-5 Part 1, bigquery/44 + 61, is
-- the paired half: it widened the referee's SCORED set to 'divergence-review' so the calibration this
-- view reads finally accrues evidence — previously it was permanently empty.)
--
-- FIX: state.referee_promotion_readiness below, mirroring state.research_quality_promotion_readiness
-- (bigquery/71) EXACTLY in shape and idempotency discipline: fail-closed (no referee rows / empty
-- calibration => ready_for_promotion=FALSE), declared quantitative bars, and a NOT EXISTS
-- loop_promotion_log(loop_id='cross_model_referee_independence', to_stage='active_auto') single-shot
-- guard so a completed promotion permanently disarms re-firing. NON-GATING: this view is RECORD-ONLY.
-- Nothing here changes a SISA readiness view or any live decision. The future ACTIVE_AUTO promotion
-- (folding referee_concurs into state.strategy_adoption_readiness / strategy_retirement_readiness /
-- foundation_change_termination_readiness) is a SEPARATE, evidence-cited edit that a W5 PROMOTION CHECK
-- executes only once this view reads ready_for_promotion=TRUE and writes the loop_promotion_log row in
-- the same transaction — no human PR/chat gate, the compensating control is the observed concurrence
-- evidence itself (CLAUDE.md "Settled decisions"; identical posture to every sibling loop-promotion view).
--
-- DECLARED PROMOTION BARS (SHADOW -> ACTIVE_AUTO), all three required simultaneously + the single-shot guard:
--   * quarter_elapsed    — >= 90 days since the FIRST referee_gemini row was INSERTED (event_ts, NOT
--                          review_date; see the first_ref CTE note) == "one full quarterly cycle".
--   * sample_floor_met   — the __ALL__ concurrence rollup has n_scored >= 6 paired reviews. 6 is the
--                          declared floor: it matches the ~6 historical divergence-review pairs DEF-5
--                          Part 1 unlocks, so the concurrence_rate below is computed over a non-trivial
--                          sample rather than one lucky pair. The 90-day event_ts clock is what forces
--                          the sample to actually span a quarter; this floor just guarantees it is not
--                          empty. (Adjustable upward in a future evidence-based edit — a declared bar,
--                          exactly like bigquery/71's >=15-closed-thesis / 3-consecutive-cycle bars.)
--   * concurrence_met    — the __ALL__ rollup concurrence_rate >= 0.80. Declared threshold: high enough
--                          that folding referee_concurs in as a fail-closed AND-condition will not
--                          spuriously BLOCK legitimate decisions (a referee that disagreed with the
--                          orchestrator > 20% of the time is too noisy to gate capital on), while still
--                          below the ~0.95 SAME-MODEL theater-check agreement we EXPECT a genuinely
--                          cross-model family referee to fall short of (that independence is the point).
--                          Also adjustable by the spike doc / a future evidence-cited edit.
--
-- INERT ON APPLY: as of 2026-07-17 there are ZERO referee_gemini rows (the scorer had nothing to score
-- until DEF-5 Part 1), so first_referee_ts IS NULL and n_scored=0 -> ready_for_promotion=FALSE. Even after
-- the first scoring run the 90-day clock cannot elapse until ~2026-10 at the earliest. Fail-closed by
-- construction, not by a flag.

-- ops.loop_promotion_log UNIFIED SCHEMA (shared with bigquery/71 / any sibling loop-promotion work) —
-- CREATE TABLE IF NOT EXISTS makes whichever file applies first the creator and any other a harmless
-- no-op. Verbatim mirror of bigquery/71's block so this file is self-contained and apply-order-tolerant.
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

-- Promotion readiness — fail-closed (no referee rows / empty calibration => ready_for_promotion=FALSE).
-- SUPERSEDED LIVE by bigquery/87_referee_promotion_class_breadth.sql — current single source of truth
-- for state.referee_promotion_readiness (adds the class_breadth_met bar: >=2 distinct review_types
-- with evidence, so single-class pooled evidence cannot clear the promotion). Kept here, unmodified,
-- for DR-rebuild apply-in-order reference only. DO NOT re-apply this CREATE statement live in isolation.
CREATE OR REPLACE VIEW `stock-trading-498512.state.referee_promotion_readiness` AS
WITH first_ref AS (
  -- MIN(event_ts) = the actual INSERTION time of the earliest referee_gemini row, deliberately NOT its
  -- review_date. ops.sp_score_cross_model_referee (bigquery/44) copies g.review_date from the ORIGINAL
  -- attacker submission, so a freshly-scored referee_gemini row carries a BACKDATED review_date (the
  -- June/July divergence-review dates). Keying the 90-day burn-in on review_date would let the ~6
  -- historical pairs satisfy the quarter clock RETROACTIVELY the instant they are first scored —
  -- contradicting the register's "evidence starts accruing now, not retroactively" (ops/autonomy_levels.yaml
  -- cross_model_referee_independence, 2026-07-15). event_ts is the append time, so the clock starts when
  -- scoring actually begins. Empty table => MIN() = NULL => fail-closed.
  SELECT MIN(event_ts) AS first_referee_ts, COUNT(*) AS referee_rows
  FROM `stock-trading-498512.events.adversarial_reviews`
  WHERE role = 'referee_gemini'
),
concur_rollup AS (
  -- The cross-review-type __ALL__ concurrence rollup — always exactly one row (analytics.referee_
  -- concurrence_calibration's `overall` CTE aggregates over possibly-zero paired rows, yielding
  -- n_scored=0 / concurrence_rate=NULL when empty). COALESCE keeps the bars FALSE, never NULL.
  -- (CTE named concur_rollup, NOT `rollup` — ROLLUP is a reserved keyword and cannot name a CTE.)
  SELECT COALESCE(n_scored, 0) AS n_scored, concurrence_rate
  FROM `stock-trading-498512.analytics.referee_concurrence_calibration`
  WHERE review_type = '__ALL__'
)
SELECT
  fr.first_referee_ts,
  fr.referee_rows,
  r.n_scored,
  r.concurrence_rate,
  TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), fr.first_referee_ts, DAY) AS days_since_first_referee,
  (fr.first_referee_ts IS NOT NULL
   AND TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), fr.first_referee_ts, DAY) >= 90) AS quarter_elapsed,
  (r.n_scored >= 6) AS sample_floor_met,
  (COALESCE(r.concurrence_rate, 0.0) >= 0.80) AS concurrence_met,
  NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.loop_promotion_log` pl
              WHERE pl.loop_id = 'cross_model_referee_independence' AND pl.to_stage = 'active_auto') AS not_already_promoted,
  (fr.first_referee_ts IS NOT NULL
   AND TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), fr.first_referee_ts, DAY) >= 90
   AND r.n_scored >= 6
   AND COALESCE(r.concurrence_rate, 0.0) >= 0.80
   AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.loop_promotion_log` pl
                   WHERE pl.loop_id = 'cross_model_referee_independence' AND pl.to_stage = 'active_auto')) AS ready_for_promotion
FROM first_ref fr CROSS JOIN concur_rollup r;
-- Returns exactly one row. ready_for_promotion stays FALSE until (a) >=90 days of observed referee
-- scoring (event_ts clock), (b) >=6 paired scored reviews in the __ALL__ rollup, and (c) concurrence_rate
-- >=0.80 — AND no cross_model_referee_independence->active_auto row already exists in ops.loop_promotion_log
-- (single-shot). Same fail-closed + single-shot idempotency shape as state.research_quality_promotion_
-- readiness (bigquery/71) and every other loop-promotion readiness view in that audit pass.

-- Apply the whole file live via the BigQuery MCP (execute_sql), same apply-in-order discipline as
-- bigquery/01..83. [NOT applied live by this commit — local-only implementation round, 2026-07-17;
-- record-only / SHADOW, INERT on apply. See OWNER_ACTIONS.md.]

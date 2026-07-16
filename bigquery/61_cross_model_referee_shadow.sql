-- Cross-model referee DORMANT -> SHADOW promotion (self-improvement audit 2026-07-15 — CONFIRMED GAP
-- cross-model-referee-dormant). Project: stock-trading-498512. Apply after
-- 44_cross_model_referee.sql.
--
-- PROBLEM: bigquery/44_cross_model_referee.sql built ops.sp_score_cross_model_referee() plus two
-- dormant readiness views, but its own header states plainly: "Nothing calls
-- ops.sp_score_cross_model_referee() on a schedule yet, and NO readiness view's `ready` column reads
-- referee_verdict yet." ops/autonomy_levels.yaml's `cross_model_referee_independence` loop names W5 as
-- the candidate caller ("mirroring its existing S-5 adversarial-independence-audit bullet") but nothing
-- ever built that bullet — the loop could not accrue its own promotion evidence.
--
-- FIX: implement exactly the DORMANT -> SHADOW promotion ops/autonomy_levels.yaml already specifies —
-- record-only, non-gating. A new W5 bullet (Claude_Task_Plan.md) best-effort-calls
-- ops.sp_score_cross_model_referee() every weekly cycle and reads this view, logging a decision_log
-- record. NO readiness view (state.strategy_adoption_readiness / state.strategy_retirement_readiness /
-- state.foundation_change_termination_readiness) is changed by this file — live SISA decisions remain
-- fully unaffected. Per the register's own gate_to_next_stage: SHADOW -> ACTIVE_AUTO requires ONE FULL
-- QUARTERLY CYCLE of observed concurrence before folding referee_concurs into those readiness views as
-- a fail-closed AND-condition — a future, separately-committed change, not this one.
--
-- ===== analytics.referee_concurrence_calibration — per-review_type + rollup concurrence =====
-- Compares the orchestrator's self-certified verdict against the independent cross-model referee's
-- verdict (events.adversarial_reviews role='orchestrator' vs role='referee_gemini', paired by
-- review_id). Verdict vocabularies differ slightly by review_type in free text (e.g. a
-- strategy-adoption orchestrator verdict reads something like "SUFFICIENT" or "TIER 1 DEFECT —
-- REVISION REQUIRED", while the referee is prompted for the terser SUFFICIENT/INSUFFICIENT) — both
-- sides are normalized to a small canonical vocabulary before comparing, so a phrasing difference alone
-- never counts as disagreement. Empty until ops.sp_score_cross_model_referee() has scored at least one
-- paired review (self-bootstrapping, same as analytics.theater_check_calibration).
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.referee_concurrence_calibration` AS
WITH normalized AS (
  SELECT
    review_id, role, review_type,
    CASE
      WHEN UPPER(verdict) LIKE '%RETIRE%' THEN 'RETIRE'
      WHEN UPPER(verdict) LIKE '%KEEP%' THEN 'KEEP'
      WHEN UPPER(verdict) LIKE '%TERMINATE%' THEN 'TERMINATE'
      WHEN UPPER(verdict) LIKE '%CONSTRAINT%' THEN 'CONSTRAINT_RELAXATION'
      WHEN UPPER(verdict) LIKE '%CONTINUE%' THEN 'CONTINUE'
      -- INSUFFICIENT / REVISION-REQUIRED before the bare SUFFICIENT check below, so
      -- "TIER 1 DEFECT — REVISION REQUIRED" (which contains neither literal word "INSUFFICIENT") still
      -- normalizes to the referee's INSUFFICIENT vocabulary rather than falling through to OTHER.
      WHEN UPPER(verdict) LIKE '%INSUFFICIENT%' OR UPPER(verdict) LIKE '%REVISION%' THEN 'INSUFFICIENT'
      WHEN UPPER(verdict) LIKE '%SUFFICIENT%' THEN 'SUFFICIENT'
      ELSE 'OTHER'
    END AS verdict_norm
  FROM `stock-trading-498512.events.adversarial_reviews`
  WHERE review_type IN ('strategy-adoption', 'strategy-retirement', 'foundation-change-assessment')
    AND role IN ('orchestrator', 'referee_gemini')
),
paired AS (
  SELECT o.review_id, o.review_type,
    o.verdict_norm AS orchestrator_verdict_norm, r.verdict_norm AS referee_verdict_norm,
    (o.verdict_norm = r.verdict_norm) AS concurs
  FROM normalized o
  JOIN normalized r ON o.review_id = r.review_id AND o.role = 'orchestrator' AND r.role = 'referee_gemini'
),
by_type AS (
  SELECT review_type, COUNT(*) AS n_scored, COUNTIF(concurs) AS n_concur,
    SAFE_DIVIDE(COUNTIF(concurs), COUNT(*)) AS concurrence_rate
  FROM paired
  GROUP BY review_type
),
overall AS (
  SELECT '__ALL__' AS review_type, COUNT(*) AS n_scored, COUNTIF(concurs) AS n_concur,
    SAFE_DIVIDE(COUNTIF(concurs), COUNT(*)) AS concurrence_rate
  FROM paired
)
SELECT * FROM by_type
UNION ALL
SELECT * FROM overall;

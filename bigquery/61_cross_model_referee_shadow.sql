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
--
-- DIVERGENCE-REVIEW SCORING ADDED (DEF-5 Part 1, 2026-07-17). 'divergence-review' joins the scored
-- review_type set here AND in bigquery/44's ops.sp_score_cross_model_referee IN-list. As of 2026-07-17
-- the three previously-scored irreversible classes (strategy-adoption / strategy-retirement /
-- foundation-change-assessment) have produced ZERO attacker rows, so the referee had NOTHING to score
-- and this calibration was permanently empty (the __ALL__ rollup read n_scored=0). Divergence-review —
-- the D1/D2 router adversarial STEP-0 that lifts/reinstates a per-strategy new-entry block — already has
-- ~6 historical attacker+orchestrator pairs (2026-06-02 .. 2026-07-06) plus a roughly monthly stream, so
-- widening the scored set finally gives the SHADOW loop real concurrence evidence to accrue.
-- SCOPE NOTE (deliberate): the referee loop is in SHADOW (record-only, non-gating — no readiness view's
-- `ready` column reads referee_verdict yet), so widening its SCORED set changes NO live behavior and is
-- safe. Divergence-review DOES bind capital (an ACTIVATE lifts a new-entry block; DO-NOT-ACTIVATE keeps
-- it), unlike the three strictly-irreversible classes, but that binding is REVERSIBLE (a later cycle can
-- re-impose the block) — it is nonetheless a legitimate cross-model-independence target: an
-- orchestrator that mis-lifts a block on a weak divergence case deploys real capital, exactly the
-- single-model-fragility this referee exists to cross-check. Documenting the reversibility so a future
-- audit does not mistake this for scope-creep into a class the design meant to exclude.
-- SUPERSEDED LIVE by bigquery/143_adversarial_review_correction_path.sql — that file is the current
-- single source of truth for analytics.referee_concurrence_calibration. Kept here, unmodified, for
-- DR-rebuild apply-in-order reference only. DO NOT re-apply this CREATE statement live in isolation:
-- `normalized` below has NO dedup and `paired` self-joins it ON review_id alone, so a second
-- orchestrator or referee row for one review_id multiplies COUNT(*) n_scored — the literal input to
-- state.referee_promotion_readiness's sample_floor_met (>=6) and concurrence_met (>=0.80) bars.
-- 143 adds a per-(review_id, role) QUALIFY inside `normalized` and reads
-- state.adversarial_reviews_current. The verdict-normalization CASE is byte-identical in 143.
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.referee_concurrence_calibration` AS
WITH normalized AS (
  SELECT
    review_id, role, review_type,
    CASE
      -- divergence-review vocabulary (DEF-5 Part 1, 2026-07-17): ACTIVATE / DO-NOT-ACTIVATE / HYBRID.
      -- SCOPED to review_type='divergence-review' AND ANCHORED to the LEADING decision token
      -- (^[^A-Z]* skips leading spaces / markdown '**' / quotes before the token) rather than a bare
      -- substring match. This deviates from a naive '%DO-NOT-ACTIVATE%'/'%DNA%'-before-'%ACTIVATE%'
      -- substring ordering ON PURPOSE: the live orchestrator divergence-review verdicts are verbose
      -- free-text whose REASONING embeds the word "DNA" while the DECISION is ACTIVATE — e.g.
      -- "ACTIVATE (binding, UNCHANGED). Post-reconciliation DNA is override-manufactured on a raw call
      -- that ROSE to ACTIVATE...". A bare '%DNA%' test (checked before ACTIVATE) misnormalizes ALL FOUR
      -- such ACTIVATE decisions to DO_NOT_ACTIVATE (VERIFIED against the 6 live orchestrator rows,
      -- 2026-07-17), which would falsely record disagreement and understate concurrence on a metric that
      -- gates a capital-binding promotion. Anchoring to the leading token fixes that while preserving the
      -- required ordering (HYBRID first — "HYBRID ACTIVATE" contains ACTIVATE; DO-NOT-ACTIVATE / DNA
      -- before the bare ACTIVATE fallback). Scoping to the review_type keeps a SISA verdict that happens
      -- to contain the word "activate" in prose from cross-normalizing into this vocabulary.
      WHEN review_type = 'divergence-review' AND REGEXP_CONTAINS(UPPER(verdict), r'^[^A-Z]*HYBRID') THEN 'HYBRID'
      WHEN review_type = 'divergence-review' AND REGEXP_CONTAINS(UPPER(verdict), r'^[^A-Z]*DO[ -]?NOT[ -]?ACTIVATE') THEN 'DO_NOT_ACTIVATE'
      WHEN review_type = 'divergence-review' AND REGEXP_CONTAINS(UPPER(verdict), r'^[^A-Z]*DNA\b') THEN 'DO_NOT_ACTIVATE'
      WHEN review_type = 'divergence-review' AND UPPER(verdict) LIKE '%ACTIVATE%' THEN 'ACTIVATE'
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
  WHERE review_type IN ('strategy-adoption', 'strategy-retirement', 'foundation-change-assessment', 'divergence-review')
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

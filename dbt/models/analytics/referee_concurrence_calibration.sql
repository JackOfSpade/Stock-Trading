-- Parallel-run dbt port of bigquery/143_adversarial_review_correction_path.sql:analytics.referee_concurrence_calibration — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
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
  FROM {{ ref('adversarial_reviews_current') }}
  WHERE review_type IN ('strategy-adoption', 'strategy-retirement', 'foundation-change-assessment', 'divergence-review')
    AND role IN ('orchestrator', 'referee_gemini')
  -- ONE row per (review_id, role), newest cycle. Without this, `paired` below self-joins on review_id
  -- alone and an extra orchestrator or referee row multiplies COUNT(*) n_scored -- which is the literal
  -- input to state.referee_promotion_readiness's sample_floor_met (>=6) and concurrence_met (>=0.80).
  QUALIFY ROW_NUMBER() OVER (PARTITION BY review_id, role ORDER BY cycle_number DESC, review_date DESC, event_ts DESC) = 1
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
SELECT * FROM overall

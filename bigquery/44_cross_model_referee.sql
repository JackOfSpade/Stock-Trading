-- Cross-model adversarial-independence substrate (ITEM 27, 2026-07-11 self-improvement audit; redesign
-- move 6). Project: stock-trading-498512. Apply after 11_theater_judge.sql (ops.gemini) and
-- 35_strategy_arsenal.sql (events.adversarial_reviews, state.arsenal_rails, state.arsenal_enabled,
-- ops.roster_change_log). Idempotent (CREATE OR REPLACE); safe to re-run.
--
-- WHY: the SISA adversarial-review architecture's "independence" (AR_att vs AR_orc, and the theater
-- judge that checks it) all runs on the SAME model weights, differing only by context-window isolation
-- — a fragility the project's own docs concede (AI_Trading_Foundation.md 2.24; the theater-check
-- calibration's ~0.95 self-cert-vs-judge agreement flagged in BigQuery_System_Redesign_v2.md). This file
-- adds a genuinely cross-model-family referee (Gemini via the existing ops.gemini Vertex remote model —
-- ALREADY provisioned and billed against, in production use by ops.sp_score_theater() since 2026-06-06,
-- so this is zero new credential/integration surface) for the three IRREVERSIBLE decision classes:
-- strategy-adoption, strategy-retirement, foundation-change-assessment (TERMINATE branch only).
--
-- STAGED, DORMANT (see ops/spikes/cross-model-adversarial-independence-2026Q3.md §6 for the full design
-- + ops/autonomy_levels.yaml loop cross_model_referee_independence): this file creates the objects only.
-- Nothing calls ops.sp_score_cross_model_referee() on a schedule yet, and NO readiness view's `ready`
-- column reads referee_verdict yet — state.strategy_adoption_readiness (bigquery/35_strategy_arsenal.sql)
-- is UNCHANGED by this file; item 7's theater-judge condition (a DIFFERENT, already-live mechanism) is
-- the only new AND-condition added to it in this remediation pass. Promoting THIS loop to shadow (a
-- routine starts calling the procedure + reporting concurrence, still non-gating) and then to active_auto
-- (the readiness-view AND-condition goes live) requires a burn-in quarter of observed referee/orchestrator
-- concurrence per the spike doc — a future, separately-committed change, not this one. No human
-- review/approval/chat step is anywhere in that future promotion path either (CLAUDE.md "Settled
-- decisions"): the compensating control is the observed concurrence-rate evidence, exactly like every
-- other SISA readiness-view promotion in this register.
--
-- state.strategy_retirement_readiness and state.foundation_change_termination_readiness below are
-- likewise dormant: fail-closed by construction (a strategy/review with no referee_gemini row yet reads
-- COALESCE(...,'MISSING') != 'RETIRE'/'TERMINATE', so `ready` is FALSE), and nothing currently reads their
-- `ready` column — SL5's retirement-execution path and D2/AR_orc's foundation-change TERMINATE handler
-- both still act on the orchestrator verdict alone, unchanged by this file. Wiring either consumer to
-- require `ready` is a separate future change (also gated on the same burn-in criterion).

-- ============================================================================
-- ops.sp_score_cross_model_referee — direct structural analog of ops.sp_score_theater()
-- (bigquery/11_theater_judge.sql). Generates ONE fresh, blinded verdict per not-yet-refereed
-- attacker submission via AI.GENERATE_TABLE(MODEL ops.gemini, ...) — the referee sees ONLY the
-- attacker's case (role='attacker'), never the orchestrator's text, so it cannot echo it. Writes a new
-- role='referee_gemini' row into events.adversarial_reviews (zero schema change — role is an
-- unconstrained STRING, exactly how theater_judge's own scoring works against the same table).
-- Idempotent: NOT EXISTS + MERGE ... WHEN NOT MATCHED THEN INSERT only, never UPDATE/DELETE — a review
-- already refereed is never re-scored, matching the append-only-verdict discipline every other
-- events.adversarial_reviews row follows.
-- ============================================================================
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_score_cross_model_referee`()
BEGIN
  MERGE `stock-trading-498512.events.adversarial_reviews` T
  USING (
    SELECT
      g.review_id, 'referee_gemini' AS role, g.review_type, g.strategy, g.review_date, g.cycle_number,
      g.verdict_out AS verdict,
      CAST(NULL AS STRING) AS theater_check,
      TO_JSON(STRUCT(g.reasoning AS reasoning)) AS weaknesses,
      CAST(NULL AS STRING) AS artifact_path,
      g.reasoning AS body_md
    FROM AI.GENERATE_TABLE(
      MODEL `stock-trading-498512.ops.gemini`,
      (
        SELECT a.review_id, a.review_type, a.strategy, a.review_date, a.cycle_number,
          CONCAT(
            'You are an INDEPENDENT cross-model referee for an IRREVERSIBLE autonomous-trading-system ',
            'decision. You have NOT seen any other reviewer opinion or verdict -- form your own from ',
            'first principles against the case below only. Return the SAME verdict vocabulary the review ',
            'type uses (SUFFICIENT/INSUFFICIENT for strategy-adoption; RETIRE/KEEP for strategy-retirement; ',
            'TERMINATE/CONTINUE/CONSTRAINT_RELAXATION for foundation-change-assessment). Default on genuine ',
            'ambiguity: ',
            CASE a.review_type
              WHEN 'strategy-adoption' THEN 'INSUFFICIENT (reject)'
              WHEN 'strategy-retirement' THEN 'KEEP'
              ELSE 'CONTINUE' END,
            '.\n\nReview type: ', a.review_type,
            '\n\n=== CASE (attacker submission only -- no orchestrator text shown) ===\n',
            SUBSTR(COALESCE(a.body_md,''), 1, 6000)
          ) AS prompt
        FROM `stock-trading-498512.events.adversarial_reviews` a
        WHERE a.role = 'attacker'
          AND a.review_type IN ('strategy-adoption','strategy-retirement','foundation-change-assessment')
          AND NOT EXISTS (
            SELECT 1 FROM `stock-trading-498512.events.adversarial_reviews` r
            WHERE r.review_id = a.review_id AND r.role = 'referee_gemini')
      ),
      STRUCT('verdict_out STRING, reasoning STRING' AS output_schema, 0.0 AS temperature)
    ) g
  ) S
  ON T.review_id = S.review_id AND T.role = S.role
  WHEN NOT MATCHED THEN INSERT
    (review_id, role, review_type, strategy, review_date, cycle_number, verdict, theater_check, weaknesses, artifact_path, body_md)
    VALUES (S.review_id, S.role, S.review_type, S.strategy, S.review_date, S.cycle_number, S.verdict, S.theater_check, S.weaknesses, S.artifact_path, S.body_md);
END;

-- ============================================================================
-- state.strategy_retirement_readiness — DORMANT (see file header). NEW view, not yet consumed by SL5's
-- retirement-execution path. Fourth sibling to strategy_adoption_readiness / strategy_shadow_readiness /
-- strategy_paper_readiness (bigquery/35_strategy_arsenal.sql), closing the gap where SL5 today reads the
-- AR_orc strategy-retirement verdict directly with no dedicated readiness view. Fail-closed by
-- construction: a strategy with no referee_gemini row reads referee_verdict='MISSING', so `ready` is
-- FALSE regardless of the orchestrator's own verdict.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.strategy_retirement_readiness` AS
WITH orch AS (
  SELECT strategy AS strategy_code, verdict AS orch_verdict, review_id,
         ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY review_date DESC, event_ts DESC) AS rn
  FROM `stock-trading-498512.events.adversarial_reviews`
  WHERE review_type = 'strategy-retirement' AND role = 'orchestrator'
),
referee AS (
  -- Paired to the orchestrator by review_id (like the foundation_change_termination_readiness sibling
  -- below), NOT by strategy_code — pairing by strategy alone let a STALE referee_gemini verdict from an
  -- earlier, different retirement review satisfy referee_concurs against a NEW orchestrator verdict
  -- (adversarial self-audit fix, rev 2026-07-11).
  SELECT review_id, verdict AS referee_verdict
  FROM `stock-trading-498512.events.adversarial_reviews`
  WHERE review_type = 'strategy-retirement' AND role = 'referee_gemini'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY review_id ORDER BY review_date DESC, event_ts DESC) = 1
),
rails AS (SELECT * FROM `stock-trading-498512.state.arsenal_rails`),
ars AS (SELECT enabled, incubation_frozen FROM `stock-trading-498512.state.arsenal_enabled`)
SELECT
  r.strategy_code,
  o.orch_verdict,
  ref.referee_verdict,
  COALESCE(o.orch_verdict, 'MISSING') = 'RETIRE' AS orchestrator_retire,
  COALESCE(ref.referee_verdict, 'MISSING') = 'RETIRE' AS referee_concurs,
  rails.active_count > rails.n_min AS floor_ok,
  (ars.enabled AND NOT ars.incubation_frozen) AS arsenal_ok,
  NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.roster_change_log` cl
              WHERE cl.strategy_code = r.strategy_code AND cl.to_state = 'TERMINATED') AS not_already_transitioned,
  (COALESCE(o.orch_verdict, 'MISSING') = 'RETIRE'
   AND COALESCE(ref.referee_verdict, 'MISSING') = 'RETIRE'
   AND rails.active_count > rails.n_min
   AND ars.enabled AND NOT ars.incubation_frozen
   AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.roster_change_log` cl
                   WHERE cl.strategy_code = r.strategy_code AND cl.to_state = 'TERMINATED')) AS ready
FROM `stock-trading-498512.state.strategy_roster` r
LEFT JOIN orch o ON o.strategy_code = r.strategy_code AND o.rn = 1
LEFT JOIN referee ref ON ref.review_id = o.review_id
CROSS JOIN rails CROSS JOIN ars
WHERE r.current_state = 'RETIREMENT_PROPOSED';

-- ============================================================================
-- state.foundation_change_termination_readiness — DORMANT (see file header). Gates ONLY the TERMINATE
-- branch of a per-strategy foundation-change-assessment (CONTINUE/CONSTRAINT_RELAXATION are fail-safe
-- directions and stay ungated, same discipline as calibration_parameter_carveout's auto-REVERT). Depends
-- on the foundation-change-assessment routine (Part 5 mechanical-criteria framework, A2/A3/Q3) being
-- extended to write an events.adversarial_reviews role='orchestrator' row for review_type=
-- 'foundation-change-assessment' -- a Claude_Task_Plan.md procedure-text change, NOT a new credential,
-- and not made by this file. Until that lands this view returns zero rows for any strategy -- fail-closed
-- by construction, not by a flag.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.foundation_change_termination_readiness` AS
WITH orch AS (
  SELECT strategy AS strategy_code, review_id, verdict AS orch_verdict,
         ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY review_date DESC, event_ts DESC) AS rn
  FROM `stock-trading-498512.events.adversarial_reviews`
  WHERE review_type = 'foundation-change-assessment' AND role = 'orchestrator'
),
referee AS (
  SELECT review_id, verdict AS referee_verdict
  FROM `stock-trading-498512.events.adversarial_reviews`
  WHERE review_type = 'foundation-change-assessment' AND role = 'referee_gemini'
)
SELECT
  o.strategy_code, o.review_id, o.orch_verdict, ref.referee_verdict,
  o.orch_verdict = 'TERMINATE' AS orchestrator_terminate,
  COALESCE(ref.referee_verdict, 'MISSING') = 'TERMINATE' AS referee_concurs,
  NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.roster_change_log` cl
              WHERE cl.strategy_code = o.strategy_code AND cl.to_state = 'TERMINATED'
                AND cl.note LIKE 'foundation-change%') AS not_already_transitioned,
  (o.orch_verdict = 'TERMINATE'
   AND COALESCE(ref.referee_verdict, 'MISSING') = 'TERMINATE'
   AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.roster_change_log` cl
                   WHERE cl.strategy_code = o.strategy_code AND cl.to_state = 'TERMINATED'
                     AND cl.note LIKE 'foundation-change%')) AS ready
FROM orch o
LEFT JOIN referee ref USING (review_id)
WHERE o.rn = 1;

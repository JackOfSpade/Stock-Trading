-- BigQuery adversarial-independence judge (P3-2). Project: stock-trading-498512.
-- Replaces the ORCHESTRATOR's SELF-CERTIFIED theater_check (CONVERGENT/DIVERGENT) with an
-- objective LLM judge, and replaces the raw full-transcript cosine in analytics.theater_independence
-- (found "topically saturated ~0.95-0.97 ... NOT a sharp CONVERGENT detector", 04_analytics.sql).
-- Uses the SAME validated pattern as the ticker backfill: AI.GENERATE_TABLE over MODEL ops.gemini.
-- On-demand (a procedure that MERGEs, like ops.sp_embed_pending) so it never bills on a plain SELECT.
-- Depends on 02_ai_layer.sql (ops.gemini) + events.adversarial_reviews. Idempotent.

-- ===== Result store =====
CREATE TABLE IF NOT EXISTS `stock-trading-498512.analytics.theater_judge` (
  review_id STRING NOT NULL,
  strategy STRING, review_type STRING, review_date DATE,
  self_certified STRING,        -- the orchestrator's own theater_check flag
  judge_independent BOOL,       -- judge: did the orchestrator raise INDEPENDENT disagreement?
  judge_reason STRING,
  agrees_with_self_cert BOOL,   -- does the judge corroborate the self-certified flag?
  model STRING DEFAULT 'gemini-2.5-flash', scored_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  PRIMARY KEY (review_id) NOT ENFORCED
) OPTIONS(description='Objective adversarial-independence judgement per review (attacker vs orchestrator). Refreshed by ops.sp_score_theater().');

-- ===== ops.sp_score_theater() — judge every not-yet-scored paired review =====
-- Pairs the attacker + orchestrator rows of each review_id, asks Gemini whether the orchestrator
-- surfaced INDEPENDENT disagreement (vs merely echoing the attacker = theater), and MERGEs the verdict.
-- Self-healing + re-run-safe: only scores reviews that have BOTH roles and are not already scored.
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_score_theater`()
BEGIN
  MERGE `stock-trading-498512.analytics.theater_judge` T
  USING (
    SELECT g.review_id, g.strategy, g.review_type, g.review_date, g.self_certified,
           g.independent AS judge_independent, g.reason AS judge_reason,
           -- self-cert "claims independence" = DIVERGENT or MIXED (partial independence); CONVERGENT = theater.
           -- So agree when that claim matches the judge: (DIVERGENT|MIXED) = independent. (MIXED must count
           -- as independence-consistent, else a MIXED review the judge finds independent is mis-scored as a
           -- disagreement.)
           ((UPPER(g.self_certified) LIKE '%DIVERGENT%' OR UPPER(g.self_certified) LIKE '%MIXED%') = g.independent) AS agrees_with_self_cert
    FROM AI.GENERATE_TABLE(
      MODEL `stock-trading-498512.ops.gemini`,
      (
        SELECT a.review_id, o.strategy, o.review_type, o.review_date,
               o.theater_check AS self_certified,
               CONCAT(
                 'Two adversarial reviewers examined the same artifact. The ATTACKER argues the bear/defect case; ',
                 'the ORCHESTRATOR independently adjudicates. Question: did the ORCHESTRATOR surface INDEPENDENT ',
                 'disagreement — substantive points the attacker did NOT make, or a verdict reached via reasoning ',
                 'that diverges from the attacker — rather than merely restating/agreeing with the attacker (which ',
                 'would be "theater")? Return independent=TRUE only for genuine independent reasoning.\n\n',
                 '=== ATTACKER (verdict: ', COALESCE(a.verdict,''), ') ===\n', SUBSTR(COALESCE(a.body_md,''), 1, 4000),
                 '\n\n=== ORCHESTRATOR (verdict: ', COALESCE(o.verdict,''), ') ===\n', SUBSTR(COALESCE(o.body_md,''), 1, 4000)
               ) AS prompt
        FROM `stock-trading-498512.events.adversarial_reviews` a
        JOIN `stock-trading-498512.events.adversarial_reviews` o
          ON a.review_id = o.review_id AND a.role = 'attacker' AND o.role = 'orchestrator'
        WHERE NOT EXISTS (
          SELECT 1 FROM `stock-trading-498512.analytics.theater_judge` tj WHERE tj.review_id = a.review_id)
      ),
      STRUCT('independent BOOL, reason STRING' AS output_schema, 0.0 AS temperature)
    ) g
  ) S
  ON T.review_id = S.review_id
  WHEN NOT MATCHED THEN INSERT
    (review_id, strategy, review_type, review_date, self_certified, judge_independent, judge_reason, agrees_with_self_cert)
    VALUES (S.review_id, S.strategy, S.review_type, S.review_date, S.self_certified, S.judge_independent, S.judge_reason, S.agrees_with_self_cert);
END;

-- ===== analytics.theater_check_calibration — self-cert vs objective judge =====
-- Tracks how often the orchestrator's self-certified theater_check matches the objective judge.
-- A low agreement rate means self-certification is unreliable (the architectural weakness the
-- analysis flagged). Empty until ops.sp_score_theater() runs over scored reviews.
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.theater_check_calibration` AS
SELECT
  COUNT(*) AS scored_reviews,
  COUNTIF(judge_independent) AS judged_independent,
  COUNTIF(NOT judge_independent) AS judged_theater,
  ROUND(SAFE_DIVIDE(COUNTIF(agrees_with_self_cert), COUNT(*)), 3) AS self_cert_agreement_rate
FROM `stock-trading-498512.analytics.theater_judge`;

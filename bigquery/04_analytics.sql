-- BigQuery analytics layer — part 2 (regime scoring + adversarial independence).
-- Project: stock-trading-498512. Builds on 01_schema.sql + 02_ai_layer.sql.

-- ===== Monthly fundamental regime scoring (M1a 5-axis scores) =====
-- Migrated from Monthly_Fundamental_RegimeScore.md into regime_events with a new
-- scope='FUNDAMENTAL_AXIS', so the conviction/calibration layer can regime-condition
-- outcomes on the 5 axes. (Loaded 2026-06-05 for the May 2026 cycle; see INSERT in
-- the migration history. Going forward, M1a writes one row per axis per month.)
-- Keys: growth_momentum, inflation_trend, policy_stance, risk_sentiment, shock_overlay,
--       _integrative. Values are the categorical scores (decelerating, reaccelerating, ...).
-- state.current_regime already surfaces these as the latest per (scope,key).

-- ===== Adversarial-review independence (theater-check measurement) =====
-- Embeds each attacker + orchestrator transcript, then scores attacker-vs-orchestrator
-- semantic similarity per review. Operationalizes router pre-mortem indicators 9.2/9.4.
CREATE OR REPLACE TABLE `stock-trading-498512.analytics.review_embeddings` AS
SELECT review_id, role, strategy, theater_check, verdict, review_date,
       ml_generate_embedding_result AS embedding
FROM ML.GENERATE_EMBEDDING(
  MODEL `stock-trading-498512.ops.text_embed`,
  (SELECT review_id, role, strategy, theater_check, verdict, review_date,
          SUBSTR(body_md, 1, 6000) AS content
   FROM `stock-trading-498512.events.adversarial_reviews`),
  STRUCT(TRUE AS flatten_json_output, 'SEMANTIC_SIMILARITY' AS task_type));

CREATE OR REPLACE VIEW `stock-trading-498512.analytics.theater_independence` AS
WITH a AS (SELECT review_id, strategy, embedding FROM `stock-trading-498512.analytics.review_embeddings` WHERE role='attacker'),
     o AS (SELECT review_id, theater_check, verdict, embedding FROM `stock-trading-498512.analytics.review_embeddings` WHERE role='orchestrator')
SELECT a.review_id, a.strategy, o.theater_check,
       ROUND(1 - ML.DISTANCE(a.embedding, o.embedding, 'COSINE'), 4) AS attacker_orch_similarity,
       o.verdict
FROM a JOIN o USING (review_id);

-- FINDING (2026-06-05): full-transcript similarity is topically saturated (~0.95-0.97 across
-- all 3 reviews regardless of theater-check flag), so raw cosine is NOT a sharp CONVERGENT
-- detector. P2 refinement: embed only the verdict/reasoning sections, OR add an
-- AI.GENERATE_BOOL("did the orchestrator surface independent disagreement?") judge over the
-- paired transcripts and track its rate vs the self-certified theater_check flag.

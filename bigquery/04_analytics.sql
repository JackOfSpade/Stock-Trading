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

-- ===== decision_log.ticker backfill (2026-06-06) =====
-- The decision_log migration left ticker NULL (the parser never extracted it). Backfill from the
-- title: (1) "Strategy X — TICKER (..." / "EXCHANGE: TICKER" clean formats, plus (2) for GO entries,
-- match the known traded-ticker set (false-positive-free). This populates ALL 10 GO theses
-- (IBM/HCA/META/ZBRA/BRC/TJX/AZO/MDT/RTX/DIS) + the clean-format NO-GO subset, which is what
-- thesis_outcomes needs. The freeform NO-GO titles ("INTU session", "post-WHR-NO-GO MT, FLEX
-- session", ...) that a regex can't safely parse (would false-positive on FY27/MT/GO) were then
-- backfilled via AI.GENERATE_TABLE (Gemini `ops.gemini`; see 02_ai_layer.sql) -- 68/68 valid
-- extractions correct, 0 false positives, primary-ticker disambiguation correct. Coverage: 97/112
-- theses (the rest are genuinely multi-ticker / session-end entries -> correctly NULL). The
-- DECISION-LOG PARSER must add ticker extraction going forward so new entries land tickered.
-- (NB: BURL's GO was folded into a NO-GO entry, so it has no thesis row -- a known gap; its +0.87
-- realized P&L is in trade_fills regardless.)
UPDATE `stock-trading-498512.events.decision_log`
SET ticker = COALESCE(
  REGEXP_EXTRACT(title, r'Strategy [A-E] [—-] ([A-Z]{1,5})\b'),
  REGEXP_EXTRACT(title, r'(?:NASDAQ|NYSE|NYSEARCA|AMEX|BATS)\s*:\s*([A-Z]{1,5})'),
  IF(decision='GO', REGEXP_EXTRACT(title, r'\b(IBM|HCA|META|ZBRA|BRC|TJX|AZO|BURL|RTX|DIS)\b'), NULL))
WHERE ticker IS NULL;

-- ===== analytics.thesis_outcomes — the conviction/calibration foundation =====
-- One row per thesis-construction decision, joined to its position outcome (realized P&L from the
-- curated fills) + the prevailing fundamental regime. `was_profitable` is the supervised label for
-- the future conviction model -- NULL until the position CLOSES (open positions are unknown, not
-- "unprofitable"; the buy fill's realized_pnl=0 must not be read as a loss). As of 2026-06-06 the
-- 3 closed B GO theses (IBM/META/BRC) are 3/3 profitable gross -- the first calibration signal;
-- the conviction model itself stays deferred until ~30 closed trades.
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.thesis_outcomes` AS
WITH theses AS (
  SELECT entry_id, entry_date, strategy, ticker, conviction, sub_pattern, decision, title
  FROM `stock-trading-498512.events.decision_log`
  WHERE entry_type = 'thesis-construction'
),
fund AS (
  SELECT key AS axis, value, as_of_date,
         ROW_NUMBER() OVER (PARTITION BY key ORDER BY as_of_date DESC) rn
  FROM `stock-trading-498512.events.regime_events` WHERE scope='FUNDAMENTAL_AXIS'
),
regime_now AS (SELECT MAX(IF(axis='_integrative', value, NULL)) AS regime_state FROM fund WHERE rn=1),
outcome AS (
  SELECT strategy, ticker, SUM(realized_pnl) AS realized_pnl, COUNT(*) AS fills
  FROM `stock-trading-498512.state.trade_fills_curated`
  GROUP BY strategy, ticker
)
SELECT
  t.entry_id, t.entry_date, t.strategy, t.ticker, t.decision, t.conviction, t.sub_pattern,
  (SELECT regime_state FROM regime_now) AS regime_state,
  pl.exit_date IS NOT NULL AS position_closed,
  IF(pl.exit_date IS NOT NULL, o.realized_pnl, NULL) AS realized_pnl,
  CASE WHEN pl.exit_date IS NULL THEN NULL          -- position still open -> outcome unknown (not a loss)
       WHEN o.realized_pnl IS NULL THEN NULL
       ELSE o.realized_pnl > 0 END AS was_profitable,
  t.title
FROM theses t
LEFT JOIN `stock-trading-498512.analytics.position_lifecycle` pl
  ON pl.strategy = t.strategy AND pl.ticker = t.ticker
LEFT JOIN outcome o ON o.strategy = t.strategy AND o.ticker = t.ticker;

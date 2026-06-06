-- BigQuery AI layer for the Stock-Trading experiment (v2 redesign §6/§7).
-- Project: stock-trading-498512. Requires the us.vertex Cloud-resource connection
-- (CLOUD_RESOURCE) with roles/aiplatform.user granted to its service account.
-- Vertex-billed (embeddings ~$0.025/1M chars); gated/batched. Re-run safe (OR REPLACE).

-- ===== Remote embedding model =====
CREATE OR REPLACE MODEL `stock-trading-498512.ops.text_embed`
  REMOTE WITH CONNECTION `stock-trading-498512.us.vertex`
  OPTIONS (ENDPOINT = 'text-embedding-005');   -- 768-dim; upgrade to gemini-embedding-001 if desired

-- ===== Remote text-generation model (Gemini) — extraction / LLM-judge tasks =====
CREATE OR REPLACE MODEL `stock-trading-498512.ops.gemini`
  REMOTE WITH CONNECTION `stock-trading-498512.us.vertex`
  OPTIONS (ENDPOINT = 'gemini-2.5-flash');

-- decision_log.ticker AI backfill (2026-06-06). The migration left ticker NULL; a regex first caught
-- the clean "Strategy X — TICKER" / "EXCHANGE: TICKER" / GO traded-ticker formats, then AI.GENERATE_TABLE
-- (Gemini) extracted the PRIMARY ticker from the freeform NO-GO titles a regex can't safely parse
-- (e.g. "post-WHR-NO-GO MT, FLEX session" -> FLEX, not WHR). 68/68 valid extractions correct, 0 false
-- positives; multi-ticker/batch/non-stock titles correctly return NONE. Coverage 97/112 theses (the
-- rest are genuinely multi-ticker/session-end entries). The decision-log PARSER should call this so
-- new entries land tickered. Reproduce:
--   CREATE OR REPLACE TABLE `stock-trading-498512.ops.ticker_backfill` AS
--   SELECT entry_id, UPPER(TRIM(ticker_out)) AS tk FROM AI.GENERATE_TABLE(
--     MODEL `stock-trading-498512.ops.gemini`,
--     (SELECT entry_id, CONCAT('Return the SINGLE primary US stock ticker (1-5 uppercase letters) ',
--        'this entry is about, or NONE if multi-stock / not about one stock. Title: ', title) AS prompt
--      FROM `stock-trading-498512.events.decision_log` WHERE ticker IS NULL AND entry_type='thesis-construction'),
--     STRUCT('ticker_out STRING' AS output_schema, 0.0 AS temperature));
--   UPDATE `stock-trading-498512.events.decision_log` d SET ticker=b.tk
--     FROM `stock-trading-498512.ops.ticker_backfill` b
--    WHERE d.entry_id=b.entry_id AND d.ticker IS NULL AND REGEXP_CONTAINS(b.tk,r'^[A-Z]{1,5}$') AND b.tk!='NONE';

-- ===== Decision embeddings (semantic precedent layer) =====
-- Embeds title + a token-safe body excerpt (SUBSTR 6000 chars ≈ <2048 tokens).
-- Bodies up to ~74k chars exist; the embedding model caps input, and the front of each
-- entry carries the decision + reasoning, so a leading excerpt is the right retrieval key.
CREATE OR REPLACE TABLE `stock-trading-498512.analytics.decision_embeddings` AS
SELECT
  entry_id, entry_date, strategy, entry_type, sub_pattern, decision, conviction, ticker, title,
  ml_generate_embedding_result AS embedding,
  ml_generate_embedding_status AS embed_status
FROM ML.GENERATE_EMBEDDING(
  MODEL `stock-trading-498512.ops.text_embed`,
  (SELECT entry_id, entry_date, strategy, entry_type, sub_pattern, decision, conviction, ticker, title,
          SUBSTR(CONCAT(COALESCE(title,''), '\n', COALESCE(body_md,'')), 1, 6000) AS content
   FROM `stock-trading-498512.events.decision_log`),
  STRUCT(TRUE AS flatten_json_output, 'RETRIEVAL_DOCUMENT' AS task_type));
-- Validated: 221/221 rows, 0 failures, all 768-dim.

-- NOTE: no VECTOR INDEX is created — BigQuery requires >= 5,000 rows to build/use one,
-- and brute-force VECTOR_SEARCH over 221 rows scans ~KB and is instant. Add an IVF/COSINE
-- index once events.decision_log passes ~5k rows:
--   CREATE VECTOR INDEX decision_idx ON analytics.decision_embeddings(embedding)
--     OPTIONS(index_type='IVF', distance_type='COSINE');

-- ===== Reusable precedent search (table function) =====
-- top_k must be a literal inside VECTOR_SEARCH, so this returns a fixed top-10;
-- callers LIMIT further:  SELECT * FROM analytics.find_precedents('…') ORDER BY distance LIMIT 5
CREATE OR REPLACE TABLE FUNCTION `stock-trading-498512.analytics.find_precedents`(query_text STRING)
AS (
  SELECT base.entry_id, base.entry_date, base.strategy, base.entry_type, base.sub_pattern,
         base.decision, base.conviction, base.ticker, base.title, ROUND(distance, 4) AS distance
  FROM VECTOR_SEARCH(
    TABLE `stock-trading-498512.analytics.decision_embeddings`, 'embedding',
    (SELECT ml_generate_embedding_result AS embedding FROM ML.GENERATE_EMBEDDING(
       MODEL `stock-trading-498512.ops.text_embed`,
       (SELECT query_text AS content),
       STRUCT(TRUE AS flatten_json_output, 'RETRIEVAL_QUERY' AS task_type))),
    top_k => 10, distance_type => 'COSINE')
);

-- ===== Incremental re-embedding (for the daily refresh procedure) =====
-- Embeds only decision_log rows not yet embedded; cheap (pennies) at one-entry-per-day cadence.
-- INSERT INTO `stock-trading-498512.analytics.decision_embeddings`
-- SELECT entry_id, entry_date, strategy, entry_type, sub_pattern, decision, conviction, ticker, title,
--        ml_generate_embedding_result, ml_generate_embedding_status
-- FROM ML.GENERATE_EMBEDDING(
--   MODEL `stock-trading-498512.ops.text_embed`,
--   (SELECT entry_id, entry_date, strategy, entry_type, sub_pattern, decision, conviction, ticker, title,
--           SUBSTR(CONCAT(COALESCE(title,''),'\n',COALESCE(body_md,'')),1,6000) AS content
--    FROM `stock-trading-498512.events.decision_log`
--    WHERE entry_id NOT IN (SELECT entry_id FROM `stock-trading-498512.analytics.decision_embeddings`)),
--   STRUCT(TRUE AS flatten_json_output, 'RETRIEVAL_DOCUMENT' AS task_type));

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

-- ===== Incremental re-embedding — ops.sp_embed_pending() =====
-- The canonical incremental embedder (was a hand-run INSERT; now a real, idempotent procedure so
-- new decision rows can never be left unembedded — see ops.sp_log_decision in 08_ops_procedures.sql,
-- which calls this in the same call as the decision INSERT). Embeds only decision_log rows not
-- already OK-embedded, and RETRIES previously errored/empty rows (the NOT-IN excludes only good
-- ones). MERGE makes it re-run-safe; a no-op (cheap) when nothing is pending. Pennies at the
-- one-entry-per-day cadence. ml_generate_embedding_status = '' is BigQuery's success sentinel.
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_embed_pending`()
BEGIN
  MERGE `stock-trading-498512.analytics.decision_embeddings` T
  USING (
    SELECT entry_id, entry_date, strategy, entry_type, sub_pattern, decision, conviction, ticker, title,
           ml_generate_embedding_result AS embedding,
           ml_generate_embedding_status AS embed_status
    FROM ML.GENERATE_EMBEDDING(
      MODEL `stock-trading-498512.ops.text_embed`,
      (SELECT entry_id, entry_date, strategy, entry_type, sub_pattern, decision, conviction, ticker, title,
              SUBSTR(CONCAT(COALESCE(title,''),'\n',COALESCE(body_md,'')),1,6000) AS content
       FROM `stock-trading-498512.events.decision_log` dl
       -- NOT EXISTS anti-join (NULL-safe): a NULL entry_id anywhere in the
       -- embeddings table would make a NOT IN (...) predicate return zero rows
       -- and silently embed nothing.
       WHERE NOT EXISTS (
         SELECT 1 FROM `stock-trading-498512.analytics.decision_embeddings` e
         WHERE e.entry_id = dl.entry_id AND e.embed_status = '' AND ARRAY_LENGTH(e.embedding) > 0)),
      STRUCT(TRUE AS flatten_json_output, 'RETRIEVAL_DOCUMENT' AS task_type))
  ) S
  ON T.entry_id = S.entry_id
  WHEN MATCHED THEN UPDATE SET
    entry_date = S.entry_date, strategy = S.strategy, entry_type = S.entry_type,
    sub_pattern = S.sub_pattern, decision = S.decision, conviction = S.conviction,
    ticker = S.ticker, title = S.title, embedding = S.embedding, embed_status = S.embed_status
  WHEN NOT MATCHED THEN INSERT
    (entry_id, entry_date, strategy, entry_type, sub_pattern, decision, conviction, ticker, title, embedding, embed_status)
    VALUES (S.entry_id, S.entry_date, S.strategy, S.entry_type, S.sub_pattern, S.decision, S.conviction, S.ticker, S.title, S.embedding, S.embed_status);
END;

-- ===== Embedding drift monitor — state.embedding_health =====
-- One SELECT replaces the manual count-compare. is_healthy = every decision_log row has a valid
-- embedding (none missing, none errored). Interprets the '' = success sentinel for human/agent use.
--   SELECT * FROM state.embedding_health;   -- expect is_healthy = TRUE, missing_rows = error_rows = 0
CREATE OR REPLACE VIEW `stock-trading-498512.state.embedding_health` AS
WITH dl AS (SELECT COUNT(*) AS log_rows FROM `stock-trading-498512.events.decision_log`),
emb AS (
  SELECT COUNT(*) AS embedding_rows,
         COUNTIF(embed_status = '' AND ARRAY_LENGTH(embedding) > 0) AS ok_rows,
         COUNTIF(NOT (embed_status = '' AND ARRAY_LENGTH(embedding) > 0)) AS error_rows
  FROM `stock-trading-498512.analytics.decision_embeddings`),
miss AS (
  SELECT COUNTIF(e.entry_id IS NULL) AS missing_rows
  FROM `stock-trading-498512.events.decision_log` dl
  LEFT JOIN `stock-trading-498512.analytics.decision_embeddings` e USING (entry_id))
SELECT dl.log_rows, emb.embedding_rows, emb.ok_rows, emb.error_rows, miss.missing_rows,
       (miss.missing_rows = 0 AND emb.error_rows = 0) AS is_healthy,
       CURRENT_TIMESTAMP() AS checked_at
FROM dl, emb, miss;

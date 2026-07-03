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
-- Embeds title + a body excerpt sized to the embedding model's input budget (SUBSTR 8000 chars ≈ the
-- ~2048-token cap of text-embedding-005; raised from 6000 on 2026-06-22 to capture more of each
-- prose-heavy entry). The front of each entry carries the decision + reasoning, so a leading excerpt is
-- the right single-vector retrieval key. LIMITATION: bodies up to ~74k chars exist, so any content past
-- the model's token cap is still NOT embedded — full long-body coverage needs CHUNKING (one embedding
-- row per (entry_id, chunk_index); find_precedents would dedup to the best chunk per entry, and
-- state.embedding_health would key on (entry_id, chunk_index)). That upgrade — and the optional move to
-- gemini-embedding-001 for higher retrieval quality — is specified in ops/RUNBOOK.md §23; it reshapes
-- this table + the health monitor + find_precedents, so it is staged as a deliberate, separately-applied
-- change rather than folded in here. KEEP THE TWO `content` EXPRESSIONS BELOW IDENTICAL (this CREATE and
-- ops.sp_embed_pending) so a full rebuild and an incremental top-up embed the same text.
-- CHUNKED (2026-07-03, self-improvement audit B-8-data — implements the ops/RUNBOOK.md §23 plan).
-- One embedding row per (entry_id, chunk_index): the full title+body content is split into ~6,000-char
-- chunks (title lands in chunk 0 since it is prepended to the content before chunking); previously only
-- the first 8,000 chars were embedded, silently degrading retrieval on exactly the richest, most
-- detailed theses (bodies up to ~74k chars exist). Cut over 2026-07-03 via a scratch-table rebuild,
-- diffed against the live table, then swapped in (RUNBOOK's own recommended validation procedure) —
-- 289 decision_log rows -> 825 embedding rows, 0 errors.
CREATE OR REPLACE TABLE `stock-trading-498512.analytics.decision_embeddings` AS
WITH src AS (
  SELECT entry_id, entry_date, strategy, entry_type, sub_pattern, decision, conviction, ticker, title,
         CONCAT(COALESCE(title,''), '\n', COALESCE(body_md,'')) AS full_content
  FROM `stock-trading-498512.events.decision_log`
),
chunked AS (
  SELECT entry_id, entry_date, strategy, entry_type, sub_pattern, decision, conviction, ticker, title,
         chunk_index,
         SUBSTR(full_content, chunk_index * 6000 + 1, 6000) AS content
  FROM src, UNNEST(GENERATE_ARRAY(0, GREATEST(0, CAST(CEIL(LENGTH(full_content) / 6000.0) AS INT64) - 1))) AS chunk_index
)
SELECT entry_id, entry_date, strategy, entry_type, sub_pattern, decision, conviction, ticker, title,
       chunk_index,
       ml_generate_embedding_result AS embedding,
       ml_generate_embedding_status AS embed_status
FROM ML.GENERATE_EMBEDDING(
  MODEL `stock-trading-498512.ops.text_embed`,
  (SELECT entry_id, entry_date, strategy, entry_type, sub_pattern, decision, conviction, ticker, title, chunk_index, content FROM chunked),
  STRUCT(TRUE AS flatten_json_output, 'RETRIEVAL_DOCUMENT' AS task_type));
-- Validated 2026-07-03: 825/825 chunk rows, 0 failures, all entries have a chunk_index=0 row.

-- NOTE: no VECTOR INDEX is created — BigQuery requires >= 5,000 rows to build/use one; brute-force
-- VECTOR_SEARCH over 825 rows is instant. state.embedding_scale_watch tracks analytics.
-- decision_embeddings' row count (not events.decision_log's) against the 5,000-row threshold, since
-- chunking means the embeddings table now grows faster than the source log. Add an IVF/COSINE index
-- once it approaches 5k:
--   CREATE VECTOR INDEX decision_idx ON analytics.decision_embeddings(embedding)
--     OPTIONS(index_type='IVF', distance_type='COSINE');

-- ===== Reusable precedent search (table function) — CHUNKED base version =====
-- Searches top_k=>30 CHUNKS, keeps the single best (lowest-distance) chunk per entry_id, returns the
-- best 10 distinct entries (RUNBOOK §23's dedup-to-best-chunk plan; self-improvement audit B-8-data).
-- OUTCOME ANNOTATION (self-improvement audit S-6) is layered on top of THIS definition in
-- bigquery/29_precedent_outcomes.sql, not here — that redefinition LEFT JOINs analytics.thesis_
-- outcomes / nogo_counterfactual / calibration_shrunk, which are defined in files 04/25/28 (later in
-- DR-rebuild order than this file); defining the outcome-annotated version here would make a fresh
-- rebuild fail (file 02 would reference tables that don't exist until files 04/25/28 run). Callers
-- always get the outcome-annotated version once 29 has applied — this base definition only exists so
-- 02 is self-contained and DR-rebuildable on its own.
CREATE OR REPLACE TABLE FUNCTION `stock-trading-498512.analytics.find_precedents`(query_text STRING)
AS (
  SELECT base.entry_id, base.entry_date, base.strategy, base.entry_type, base.sub_pattern,
         base.decision, base.conviction, base.ticker, base.title, distance
  FROM VECTOR_SEARCH(
    TABLE `stock-trading-498512.analytics.decision_embeddings`, 'embedding',
    (SELECT ml_generate_embedding_result AS embedding FROM ML.GENERATE_EMBEDDING(
       MODEL `stock-trading-498512.ops.text_embed`,
       (SELECT query_text AS content),
       STRUCT(TRUE AS flatten_json_output, 'RETRIEVAL_QUERY' AS task_type))),
    top_k => 30, distance_type => 'COSINE')
  QUALIFY ROW_NUMBER() OVER (PARTITION BY base.entry_id ORDER BY distance) = 1
  ORDER BY distance
  LIMIT 10
);

-- ===== Incremental re-embedding — ops.sp_embed_pending() =====
-- The canonical incremental embedder (was a hand-run INSERT; now a real, idempotent procedure so
-- new decision rows can never be left unembedded — see ops.sp_log_decision in 08_ops_procedures.sql,
-- which calls this in the same call as the decision INSERT). CHUNKED (self-improvement audit B-8-data):
-- an entry is "pending" if its chunk_index=0 row is missing/errored (a cheap proxy for "never chunked
-- at all" or "chunk 0 itself failed"); MERGE keys on (entry_id, chunk_index) so re-running never
-- duplicates a chunk. Re-run safe; a no-op (cheap) when nothing is pending.
-- ml_generate_embedding_status = '' is BigQuery's success sentinel.
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_embed_pending`()
BEGIN
  MERGE `stock-trading-498512.analytics.decision_embeddings` T
  USING (
    WITH src AS (
      SELECT entry_id, entry_date, strategy, entry_type, sub_pattern, decision, conviction, ticker, title,
             CONCAT(COALESCE(title,''), '\n', COALESCE(body_md,'')) AS full_content
      FROM `stock-trading-498512.events.decision_log` dl
      WHERE NOT EXISTS (
        SELECT 1 FROM `stock-trading-498512.analytics.decision_embeddings` e
        WHERE e.entry_id = dl.entry_id AND e.chunk_index = 0 AND e.embed_status = '' AND ARRAY_LENGTH(e.embedding) > 0)
    ),
    chunked AS (
      SELECT entry_id, entry_date, strategy, entry_type, sub_pattern, decision, conviction, ticker, title,
             chunk_index,
             SUBSTR(full_content, chunk_index * 6000 + 1, 6000) AS content
      FROM src, UNNEST(GENERATE_ARRAY(0, GREATEST(0, CAST(CEIL(LENGTH(full_content) / 6000.0) AS INT64) - 1))) AS chunk_index
    )
    SELECT entry_id, entry_date, strategy, entry_type, sub_pattern, decision, conviction, ticker, title,
           chunk_index,
           ml_generate_embedding_result AS embedding,
           ml_generate_embedding_status AS embed_status
    FROM ML.GENERATE_EMBEDDING(
      MODEL `stock-trading-498512.ops.text_embed`,
      (SELECT entry_id, entry_date, strategy, entry_type, sub_pattern, decision, conviction, ticker, title, chunk_index, content FROM chunked),
      STRUCT(TRUE AS flatten_json_output, 'RETRIEVAL_DOCUMENT' AS task_type))
  ) S
  ON T.entry_id = S.entry_id AND T.chunk_index = S.chunk_index
  WHEN MATCHED THEN UPDATE SET
    entry_date = S.entry_date, strategy = S.strategy, entry_type = S.entry_type,
    sub_pattern = S.sub_pattern, decision = S.decision, conviction = S.conviction,
    ticker = S.ticker, title = S.title, embedding = S.embedding, embed_status = S.embed_status
  WHEN NOT MATCHED THEN INSERT
    (entry_id, entry_date, strategy, entry_type, sub_pattern, decision, conviction, ticker, title, chunk_index, embedding, embed_status)
    VALUES (S.entry_id, S.entry_date, S.strategy, S.entry_type, S.sub_pattern, S.decision, S.conviction, S.ticker, S.title, S.chunk_index, S.embedding, S.embed_status);
END;

-- ===== Embedding drift monitor — state.embedding_health =====
-- CHUNKED (self-improvement audit B-8-data): is_healthy = every decision_log entry has >=1 ok chunk AND
-- zero errored chunks (a partially-failed entry must not silently read healthy via its surviving chunk
-- 0), plus per-(entry_id,chunk_index) uniqueness (multiple chunks per entry are now EXPECTED, so the
-- old "exactly one row per entry_id" dup check would misfire on every multi-chunk entry).
-- Interprets the '' = success sentinel for human/agent use.
--   SELECT * FROM state.embedding_health;   -- expect is_healthy = TRUE; missing/error/dup all 0
CREATE OR REPLACE VIEW `stock-trading-498512.state.embedding_health` AS
WITH dl AS (SELECT COUNT(*) AS log_rows FROM `stock-trading-498512.events.decision_log`),
emb AS (
  SELECT COUNT(*) AS embedding_rows,
         COUNTIF(embed_status = '' AND ARRAY_LENGTH(embedding) > 0) AS ok_rows,
         COUNTIF(NOT (embed_status = '' AND ARRAY_LENGTH(embedding) > 0)) AS error_rows,
         COUNT(*) - COUNT(DISTINCT CONCAT(entry_id, ':', CAST(chunk_index AS STRING))) AS dup_rows
  FROM `stock-trading-498512.analytics.decision_embeddings`),
per_entry AS (
  SELECT entry_id,
    COUNTIF(embed_status = '' AND ARRAY_LENGTH(embedding) > 0) AS ok_chunks,
    COUNTIF(NOT (embed_status = '' AND ARRAY_LENGTH(embedding) > 0)) AS bad_chunks
  FROM `stock-trading-498512.analytics.decision_embeddings`
  GROUP BY entry_id
),
miss AS (
  SELECT COUNTIF(pe.entry_id IS NULL OR pe.ok_chunks = 0 OR pe.bad_chunks > 0) AS missing_rows
  FROM `stock-trading-498512.events.decision_log` dl
  LEFT JOIN per_entry pe USING (entry_id))
SELECT dl.log_rows, emb.embedding_rows, emb.ok_rows, emb.error_rows, miss.missing_rows, emb.dup_rows,
       (miss.missing_rows = 0 AND emb.error_rows = 0 AND emb.dup_rows = 0) AS is_healthy,
       CURRENT_TIMESTAMP() AS checked_at
FROM dl, emb, miss;

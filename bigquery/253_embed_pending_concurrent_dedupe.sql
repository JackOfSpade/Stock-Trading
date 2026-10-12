-- 253_embed_pending_concurrent_dedupe.sql (2026-10-11, W5 SPEC-DEFECT NOTICE INTAKE)
-- SUPERSEDES the ops.sp_embed_pending() definition in 02_ai_layer.sql (live body was identical to it).
-- Closes D2a's `embedding_duplicate_root_cause` (alert 82c27f0b-58dd-4150-9f26-50b37f657d2b) and
-- `embedding_duplicate_recurrence` (alert 3c3171ee-3d6b-48cb-80d1-f4fd8356eb70).
-- ROOT CAUSE (read off the procedure): the MERGE keys on (entry_id, chunk_index) but BigQuery has no
-- unique constraint, and ML.GENERATE_EMBEDDING is slow. ops.sp_log_decision calls this procedure inline after
-- every INSERT, and the procedure embeds EVERY pending entry, not only the caller's own. Two overlapping
-- sp_log_decision calls (W5 and its hosted/parallel loops log many entries back to back) therefore both read
-- the same just-inserted entry as NOT MATCHED and both INSERT it: one byte-identical duplicate chunk. It is
-- not a double-call of one session and not systematic (exactly one entry per occurrence: W5 2026-09-21 and 2026-10-04).
-- FIX: after the MERGE, collapse any (entry_id, chunk_index) with more than one row to one (preferring a
-- healthy embed_status=''), inside the same never-rethrow handler. No transaction: if DELETE succeeds and the
-- re-INSERT fails, the chunk is simply 'pending' again and the next call re-embeds it (self-healing), so
-- the repair cannot lose a decision. analytics.decision_embeddings is DERIVED and outside the DML watch scope.
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_embed_pending`()
BEGIN
  MERGE `stock-trading-498512.analytics.decision_embeddings` T
  USING (
    WITH src AS (
      SELECT entry_id, entry_date, strategy, entry_type, sub_pattern, decision, conviction, ticker, title,
             CONCAT(COALESCE(title,''), '\n', COALESCE(body_md,'')) AS full_content
      FROM `stock-trading-498512.events.decision_log` dl
      WHERE (
        -- Missing/errored chunk 0 (never fully chunked, or chunk 0 itself failed).
        NOT EXISTS (
          SELECT 1 FROM `stock-trading-498512.analytics.decision_embeddings` e
          WHERE e.entry_id = dl.entry_id AND e.chunk_index = 0 AND e.embed_status = '' AND ARRAY_LENGTH(e.embedding) > 0)
        -- Broadened 2026-07-04 (audit finding): chunk 0 succeeding used to permanently mask a LATER
        -- chunk (index >= 1) that errored — that entry was never re-selected here even though
        -- state.embedding_health's per_entry logic below already flags it unhealthy (bad_chunks > 0)
        -- forever. Catch any entry with at least one non-ok chunk, not just a bad/missing chunk 0.
        OR EXISTS (
          SELECT 1 FROM `stock-trading-498512.analytics.decision_embeddings` e
          WHERE e.entry_id = dl.entry_id AND NOT (e.embed_status = '' AND ARRAY_LENGTH(e.embedding) > 0))
      )
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

  -- Concurrent-call dedupe (253). Never rethrow: embeddings are a derived index.
  BEGIN
    CREATE TEMP TABLE _emb_keep AS
    SELECT * EXCEPT (rn, c) FROM (
      SELECT e.*, ROW_NUMBER() OVER (PARTITION BY entry_id, chunk_index ORDER BY IF(embed_status = '' AND ARRAY_LENGTH(embedding) > 0, 0, 1)) AS rn,
             COUNT(*) OVER (PARTITION BY entry_id, chunk_index) AS c
      FROM `stock-trading-498512.analytics.decision_embeddings` e)
    WHERE c > 1 AND rn = 1;
    IF (SELECT COUNT(*) FROM _emb_keep) > 0 THEN
      -- DELETE + re-INSERT inside ONE transaction (W5 orchestrator review, 2026-10-11): unwrapped, a
      -- failed INSERT or a concurrent caller's DELETE would silently drop every kept chunk, and the
      -- never-rethrow handler below would hide it. A conflicting concurrent transaction aborts and
      -- rolls back here instead, leaving the duplicates for the next call to fold.
      BEGIN
        BEGIN TRANSACTION;
        DELETE FROM `stock-trading-498512.analytics.decision_embeddings` T
        WHERE EXISTS (SELECT 1 FROM _emb_keep k WHERE k.entry_id = T.entry_id AND k.chunk_index = T.chunk_index);
        INSERT INTO `stock-trading-498512.analytics.decision_embeddings`
          (entry_id, entry_date, strategy, entry_type, sub_pattern, decision, conviction, ticker, title, chunk_index, embedding, embed_status)
        SELECT entry_id, entry_date, strategy, entry_type, sub_pattern, decision, conviction, ticker, title, chunk_index, embedding, embed_status FROM _emb_keep;
        COMMIT TRANSACTION;
      EXCEPTION WHEN ERROR THEN
        ROLLBACK TRANSACTION;
        SELECT FORMAT('sp_embed_pending: dedupe rolled back (%s)', @@error.message) AS warning;
      END;
    END IF;
    DROP TABLE IF EXISTS _emb_keep;
  EXCEPTION WHEN ERROR THEN
    SELECT FORMAT('sp_embed_pending: dedupe skipped (%s)', @@error.message) AS warning;
  END;
END;

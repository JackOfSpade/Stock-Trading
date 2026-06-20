-- Ops stored procedures for the Stock-Trading experiment. Project: stock-trading-498512.
-- Depends on 02_ai_layer.sql (ops.sp_embed_pending, ops.text_embed model). Re-run safe (OR REPLACE).

-- ===== ops.sp_log_decision — atomic "log a decision + embed it" =====
-- One CALL appends the decision row to the append-only events.decision_log AND (re)builds its
-- embedding, so a decision can NEVER be logged unembedded (this closes the straggler window that
-- existed while embedding was a separate, hand-run step). entry_id / event_ts come from the table's
-- column DEFAULTs (GENERATE_UUID / CURRENT_TIMESTAMP); pass NULLs for unused optional fields.
--
-- Design note — why not a hard transaction: the decision_log is the append-only source of truth;
-- the embedding is a DERIVED retrieval index. We must never discard a durable decision just because
-- the (Vertex-billed, remote) embedding step hiccups. So the INSERT always commits, and the embed
-- runs in the same call wrapped in an exception handler that never rethrows. Any row left unembedded
-- is visible in state.embedding_health and self-heals on the next sp_embed_pending() / sp_log_decision().
--
-- Usage (replaces the raw INSERT + manual incremental-embed pattern):
--   CALL `stock-trading-498512.ops.sp_log_decision`(
--     DATE '2026-06-07', 'thesis-construction', 'B', 'CEG', 'NO-GO', 'low', NUMERIC '40',
--     'SP6', NULL, 'Strategy B — CEG …', '<full body_md markdown>',
--     '{"convergence_target": 300}', ['decision:2026-06-01-CEG'], ['strategyB','no-go'],
--     NULL, 'D2 2026-06-07');
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_log_decision`(
  in_entry_date DATE, in_entry_type STRING, in_strategy STRING, in_ticker STRING,
  in_decision STRING, in_conviction STRING, in_conviction_pct NUMERIC,
  in_sub_pattern STRING, in_theater_check STRING, in_title STRING, in_body_md STRING,
  in_fields_json STRING, in_refs ARRAY<STRING>, in_tags ARRAY<STRING>,
  in_superseded_by STRING, in_source_session STRING
)
BEGIN
  -- 1) Durable append of the decision (source of truth; must always persist).
  INSERT INTO `stock-trading-498512.events.decision_log`
    (entry_date, entry_type, strategy, ticker, decision, conviction, conviction_pct,
     sub_pattern, theater_check, title, body_md, fields, refs, tags, superseded_by, source_session)
  VALUES
    (in_entry_date, in_entry_type, in_strategy, in_ticker, in_decision, in_conviction, in_conviction_pct,
     in_sub_pattern, in_theater_check, in_title, in_body_md,
     SAFE.PARSE_JSON(in_fields_json), in_refs, in_tags, in_superseded_by, in_source_session);

  -- 2) Build the embedding in the SAME call. Never let an embedding failure discard the decision.
  BEGIN
    CALL `stock-trading-498512.ops.sp_embed_pending`();
  EXCEPTION WHEN ERROR THEN
    SELECT FORMAT('sp_log_decision: decision persisted; embedding deferred (%s)', @@error.message) AS warning;
  END;
END;

-- ===== ops.sp_daily_refresh — the v2 design's "D2 Step 0 → one CALL" (recompute + embed) =====
-- PRECONDITION: D2 must have already ingested the day's marks into events.daily_marks (connector-
-- dependent, agent-side — a pure SQL procedure can't reach the IBKR connector). This then runs the
-- SQL-only daily steps: recompute the deployed-TWR engine (ops.sp_recompute_engine, defined in
-- 03_twr_engine.sql) and catch up any pending decision embeddings (ops.sp_embed_pending). Idempotent;
-- safe to re-run. Validated 2026-06-07: reproduces the engine state bit-for-bit + leaves embeddings healthy.
-- Single-writer note: the recompute is a wholesale DELETE+INSERT on perf.strategy_daily; if two
-- sessions could run it at once, serialize them (BigQuery may abort one with a concurrent-update error
-- — re-run). The scheduled-query option (see bigquery/README.md) avoids this by running it once daily.
--
-- RUN-LOGGING (A2, revised 2026-06-19): D2's run is logged by the ROUTINE via ops.sp_routine_start /
-- ops.sp_routine_end (the global Observability convention) — now demonstrably adopted in production.
-- This procedure does NOT self-log. (It briefly did, as the A2 bootstrap when run_log was empty, but
-- that duplicated the routine's 'completed' row AND wrote it mid-D2 at the engine-refresh step, so it
-- meant "data refreshed", not "full D2 done".) Dropping the self-log weakens no alarm: data currency is
-- proven independently by state.freshness.marks_fresh / engine_fresh, which read events.daily_marks /
-- perf.strategy_daily directly and are what gate state.system_health.all_green. d2_ran_last_trading_day
-- (informational; not in all_green) now reflects the routine's true end-of-run completion.
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_daily_refresh`()
BEGIN
  CALL `stock-trading-498512.ops.sp_recompute_engine`();
  CALL `stock-trading-498512.ops.sp_embed_pending`();
END;

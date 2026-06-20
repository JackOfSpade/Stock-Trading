-- BigQuery observability / control plane (P0-2, P0-4, P1-1, P3-3). Project: stock-trading-498512.
-- The system's data/execution planes are solid; this adds the missing control plane:
--   * ops.run_log         — every routine logs that it ran (P1-1) -> the dead-man's-switch input
--   * ops.alerts          — durable sink for hard-stops/anomalies (P0-4)
--   * state.freshness      — are marks/engine current vs the last trading day? (P0-2)
--   * state.system_health  — one-row green/red rollup (freshness + embeddings + kills + alerts)
--   * state.gate_watch     — conviction-model 30-closed-trade gate proximity (P3-3, watch-only)
-- Depends on 09_market_calendar.sql (state.trading_day_today) + existing state.embedding_health,
-- perf.kill_flags. Idempotent. Apply after 09 via the BigQuery MCP execute_sql.

-- ===== ops.run_log — "did the routine actually run?" =====
CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.run_log` (
  run_id STRING DEFAULT GENERATE_UUID(),
  log_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  routine STRING NOT NULL,            -- 'D1','D2',...,'M5','Q3','A1','AR-attacker',...
  run_date DATE NOT NULL,             -- operating day (America/Denver) the routine ran for
  status STRING NOT NULL,             -- 'started' | 'completed' | 'failed' | 'halted'
  session_id STRING, branch STRING,
  rows_written INT64, error_msg STRING, note STRING,
  instruction STRING                  -- verbatim trigger instruction the session received (set on the
                                      -- 'started' row via ops.sp_routine_start) — lets you verify the
                                      -- live web-UI trigger text by query, no screenshots needed
) PARTITION BY run_date CLUSTER BY routine, status
OPTIONS(description='One row per routine run (started/completed/failed/halted). Source for the freshness dead-man switch + an audit of what ran when. instruction captures the verbatim trigger text.');

-- ===== state.routine_last_instruction — the live trigger text each routine last received =====
-- Verify every routine's web-UI trigger instruction by query instead of screenshotting it. Compare
-- against the canonical instruction printed by scripts/print_routines.py to catch a drifted/typo'd
-- trigger. (Populated once routines pass their instruction to ops.sp_routine_start.)
CREATE OR REPLACE VIEW `stock-trading-498512.state.routine_last_instruction` AS
SELECT routine, instruction, run_date, log_ts
FROM `stock-trading-498512.ops.run_log`
WHERE instruction IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY routine ORDER BY log_ts DESC) = 1;

-- Routines call this at start ('started') and end ('completed'/'failed'/'halted').
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_log_run`(
  in_routine STRING, in_run_date DATE, in_status STRING,
  in_session STRING, in_branch STRING, in_rows INT64, in_error STRING, in_note STRING
)
BEGIN
  INSERT INTO `stock-trading-498512.ops.run_log`
    (routine, run_date, status, session_id, branch, rows_written, error_msg, note)
  VALUES (in_routine, in_run_date, in_status, in_session, in_branch, in_rows, in_error, in_note);
END;

-- ===== ops.alerts — durable hard-stop / anomaly sink (P0-4) =====
-- "Routine chat is unmonitored" (Claude_Task_Plan §): a hard-stop (cash tripwire >$1,
-- dual-path max-loss disagreement, embedding unhealthy, merge conflict, stale data) was
-- previously silent until a human happened to look. Routines now CALL ops.sp_raise_alert
-- AND (agent-side) create a "[Claude] ATTENTION" calendar event. The daily freshness
-- scheduled query also raises alerts here (see bigquery/scheduled_queries/).
CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.alerts` (
  alert_id STRING DEFAULT GENERATE_UUID(),
  alert_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  severity STRING NOT NULL,           -- 'info' | 'warning' | 'critical'
  source STRING NOT NULL,             -- routine or job that raised it
  category STRING,                    -- 'staleness' | 'cash_tripwire' | 'dual_path' | 'embedding' | 'merge_conflict' | ...
  message STRING NOT NULL,
  payload JSON,
  resolved BOOL DEFAULT FALSE,
  resolved_ts TIMESTAMP, resolved_note STRING
) PARTITION BY DATE(alert_ts) CLUSTER BY severity, resolved
OPTIONS(description='Durable alert sink for hard-stops/anomalies. Wire a Pub/Sub or Cloud Monitoring notification on unresolved critical rows — see ops/RUNBOOK.md.');

CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_raise_alert`(
  in_severity STRING, in_source STRING, in_category STRING, in_message STRING, in_payload_json STRING
)
BEGIN
  INSERT INTO `stock-trading-498512.ops.alerts` (severity, source, category, message, payload)
  VALUES (in_severity, in_source, in_category, in_message, SAFE.PARSE_JSON(in_payload_json));
END;

-- Idempotent alert: only raises if no identical unresolved (category, message) already open,
-- so a daily check re-running doesn't pile up duplicate staleness rows.
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_raise_alert_once`(
  in_severity STRING, in_source STRING, in_category STRING, in_message STRING, in_payload_json STRING
)
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM `stock-trading-498512.ops.alerts`
    WHERE NOT resolved AND category = in_category AND message = in_message
  ) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert`(in_severity, in_source, in_category, in_message, in_payload_json);
  END IF;
END;

-- ===== state.freshness — marks/engine current vs the last trading day? (P0-2) =====
CREATE OR REPLACE VIEW `stock-trading-498512.state.freshness` AS
WITH ltd AS (SELECT last_trading_day, is_trading_day, today FROM `stock-trading-498512.state.trading_day_today`),
m  AS (SELECT MAX(mark_date)   AS v FROM `stock-trading-498512.events.daily_marks`),
e  AS (SELECT MAX(as_of_date)  AS v FROM `stock-trading-498512.perf.strategy_daily`),
d  AS (SELECT MAX(entry_date)  AS v FROM `stock-trading-498512.events.decision_log`),
d2 AS (SELECT MAX(run_date)    AS v FROM `stock-trading-498512.ops.run_log` WHERE routine = 'D2' AND status = 'completed')
SELECT
  (SELECT last_trading_day FROM ltd) AS last_trading_day,
  (SELECT v FROM m)  AS last_mark_date,
  (SELECT v FROM e)  AS engine_through,
  (SELECT v FROM d)  AS last_decision_date,
  (SELECT v FROM d2) AS last_d2_run_date,
  -- COALESCE -> FALSE so the dead-man's switch fails LOUD, never silent: if a source table is
  -- empty, or last_trading_day is NULL (e.g. the market_calendar range is exhausted post-2028),
  -- a bare `>=` would yield NULL -> all_green NULL -> the freshness check's `IF NOT all_green`
  -- would NOT fire. FALSE instead makes it alert (and nags to extend the calendar).
  COALESCE((SELECT v FROM m) >= (SELECT last_trading_day FROM ltd), FALSE) AS marks_fresh,
  COALESCE((SELECT v FROM e) >= (SELECT last_trading_day FROM ltd), FALSE) AS engine_fresh,
  COALESCE((SELECT v FROM d2) >= (SELECT last_trading_day FROM ltd), FALSE) AS d2_ran_last_trading_day,
  CURRENT_TIMESTAMP() AS checked_at;

-- ===== state.system_health — one-row green/red rollup =====
CREATE OR REPLACE VIEW `stock-trading-498512.state.system_health` AS
SELECT
  f.last_trading_day, f.last_mark_date, f.engine_through,
  f.marks_fresh, f.engine_fresh, f.d2_ran_last_trading_day,
  eh.is_healthy AS embeddings_healthy,
  (SELECT COUNTIF(NOT resolved AND severity = 'critical') FROM `stock-trading-498512.ops.alerts`) AS open_critical_alerts,
  (SELECT COUNTIF(NOT resolved) FROM `stock-trading-498512.ops.alerts`) AS open_alerts,
  (SELECT COUNTIF(drawdown_kill OR runaway_review OR m2m_underperf_review) FROM `stock-trading-498512.perf.kill_flags`) AS firing_kill_flags,
  (f.marks_fresh AND f.engine_fresh AND eh.is_healthy
     AND (SELECT COUNTIF(NOT resolved AND severity = 'critical') FROM `stock-trading-498512.ops.alerts`) = 0
  ) AS all_green,
  CURRENT_TIMESTAMP() AS checked_at
FROM `stock-trading-498512.state.freshness` f, `stock-trading-498512.state.embedding_health` eh;

-- ===== state.gate_watch — conviction-model 30-closed-trade gate proximity (P3-3) =====
-- The conviction model auto-trains at >=30 closed GO trades (currently far below). This is the
-- WATCH recommendation from the analysis: don't build the model now (single-class / overfits),
-- just surface proximity so M4/M5 know when to revisit. Advisory only.
CREATE OR REPLACE VIEW `stock-trading-498512.state.gate_watch` AS
SELECT
  strategy, closed_trades, gate_reached,
  GREATEST(0, 30 - closed_trades) AS closed_to_gate,
  closed_trades >= 25 AS approaching_gate
FROM `stock-trading-498512.perf.kill_flags`
ORDER BY closed_trades DESC;

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
  routine STRING NOT NULL,            -- 'D1','D2',...,'M5','Q3','A1','AR_att','AR_orc',...
  run_date DATE NOT NULL,             -- operating day (America/Denver) the routine ran for
  status STRING NOT NULL,             -- 'started' | 'completed' | 'failed' | 'halted'
  session_id STRING, branch STRING,
  rows_written INT64, error_msg STRING, note STRING,
  instruction STRING                  -- verbatim trigger instruction the session received (set on the
                                      -- 'started' row via ops.sp_routine_start) — lets you verify the
                                      -- live web-UI trigger text by query, no screenshots needed
) PARTITION BY run_date CLUSTER BY routine, status
OPTIONS(description='One row per routine run (started/completed/failed/halted). Source for the freshness dead-man switch + an audit of what ran when. instruction captures the verbatim trigger text.');

-- Idempotent upgrade: CREATE TABLE IF NOT EXISTS will NOT add a new column to an already-existing
-- run_log, so re-applying this file to a pre-existing table needs the explicit ALTER (no-op once present).
ALTER TABLE `stock-trading-498512.ops.run_log` ADD COLUMN IF NOT EXISTS instruction STRING;

-- ===== state.routine_last_instruction — the live trigger text each routine last received =====
-- Verify every routine's web-UI trigger instruction by query instead of screenshotting it. Compare
-- against the canonical instruction printed by scripts/print_routines.py to catch a drifted/typo'd
-- trigger. (Populated once routines pass their instruction to ops.sp_routine_start.)
--
-- SCHEDULED-TRIGGER-SHAPED ONLY (added 2026-06-22, RUNBOOK §22): a routine's "live trigger" is defined
-- ONLY by instructions with the canonical web-UI trigger shape `Read Claude_Task_Plan.md. Perform %`.
-- WHY: an ad-hoc / one-off session that legitimately reuses a routine id (e.g. W5 — the taxonomy owner —
-- running a one-time §20/§21 remediation) logs a task-specific instruction; without this filter that
-- free-form note shadows the real trigger (most-recent-wins) and FALSE-trips state.instruction_drift.
-- That is exactly the 2026-06-22 W5 instruction_drift false alarm. The verbatim web-UI trigger ALWAYS
-- has the shape below, so a genuinely typo'd/edited trigger (wrong routine #, heading text, or
-- deep-research/regular tag) still lands INSIDE this shape and is still caught — only non-trigger notes
-- are excluded. Trade-off: a trigger rewritten to NOT start with this prefix reads as "no live trigger"
-- (live NULL → not drifted) rather than drift; that is acceptable and visible — a routine that ran today
-- yet shows a NULL live trigger here is itself a yellow flag. The durable behavioural guard is the
-- convention (Claude_Task_Plan.md "Observability"): ad-hoc reuses still log the VERBATIM scheduled trigger.
CREATE OR REPLACE VIEW `stock-trading-498512.state.routine_last_instruction` AS
SELECT routine, instruction, run_date, log_ts
FROM `stock-trading-498512.ops.run_log`
WHERE instruction IS NOT NULL
  AND instruction LIKE 'Read Claude_Task_Plan.md. Perform %'
QUALIFY ROW_NUMBER() OVER (PARTITION BY routine ORDER BY log_ts DESC) = 1;

-- Routines call this at start ('started') and end ('completed'/'failed'/'halted').
--
-- SUPERSEDED 2026-08-14 — the canonical definition of ops.sp_log_run is now in
-- bigquery/170_run_log_note_write_time_guard.sql. DO NOT RE-APPLY THE VERSION BELOW.
-- The body below has no validation at all, so a routine that passes NULL in the 8th (note) argument
-- on a TERMINAL row is accepted silently and the run leaves no account of itself — which is exactly
-- what D2a did on 2026-08-13 (alert c26afde4-fdc3-4799-996b-390a42826f4d) and D2 on 2026-08-07.
-- bigquery/170 keeps this INSERT first and UNCONDITIONAL (it must never withhold a run row — a missing
-- terminal row escalates into a missed_run CRITICAL and thence into the trading gate) and adds, AFTER
-- it, a write-time blank-note detector that raises the run_log_note_missing alert immediately and tells
-- the still-live session how to repair the row via ops.sp_amend_run_note. The only change to the INSERT
-- itself is that bigquery/170 names run_id in the column list and supplies a pre-generated
-- GENERATE_UUID() value, instead of letting the column default fire, so the guard can identify the row
-- it just wrote without a heuristic re-read. Column semantics are otherwise unchanged.
-- Re-applying this file in isolation would silently drop that guard and restore the silent-NULL path.
-- SUPERSEDED (2026-09-08) by bigquery/230_run_outcome_notification.sql, the current canonical
-- definition of ops.sp_log_run. 230 leaves the unconditional INSERT (C8) and the existing blank-note
-- guard byte-identical, and adds -- AFTER the guard, in its own BEGIN...EXCEPTION WHEN ERROR
-- THEN...END best-effort block -- a write-time escalation: a terminal row logging failed/halted
-- raises routine_run_failed, and a completed row carrying a non-blank error_msg raises
-- routine_run_warning (both severity 'warning', never critical -- C1). See bigquery/230's header for
-- the owner directive and the audit that motivated it. Kept here, unmodified, for DR-rebuild
-- apply-in-order reference only. DO NOT re-apply this CREATE statement live in isolation.
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
--
-- SUPERSEDED LIVE by bigquery/173_freshness_cadence_aware.sql — current single source of truth for
-- this object. 173 makes the freshness dead-man cadence-aware for the Sun-Thu daily tier, adding
-- marks_due_through / marks_current / engine_current columns (every column below is unchanged). Kept
-- here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT re-apply this CREATE
-- statement live in isolation.
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
  -- empty, or last_trading_day is NULL (e.g. state.market_calendar's GENERATE_DATE_ARRAY upper
  -- bound -- 2030-12-31 per bigquery/09_market_calendar.sql -- is reached because the W5
  -- auto-extend routine has stopped running; the separate holiday-seed accuracy runs out after
  -- 2029 and causes a different symptom -- a real holiday silently misclassified as a trading
  -- day, not a NULL last_trading_day), a bare `>=` would yield NULL -> all_green NULL -> the
  -- freshness check's `IF NOT all_green` would NOT fire. FALSE instead makes it alert (and nags
  -- to extend the calendar).
  COALESCE((SELECT v FROM m) >= (SELECT last_trading_day FROM ltd), FALSE) AS marks_fresh,
  COALESCE((SELECT v FROM e) >= (SELECT last_trading_day FROM ltd), FALSE) AS engine_fresh,
  COALESCE((SELECT v FROM d2) >= (SELECT last_trading_day FROM ltd), FALSE) AS d2_ran_last_trading_day,
  CURRENT_TIMESTAMP() AS checked_at;

-- ===== state.system_health — one-row green/red rollup =====
-- NOTE: this definition is immediately superseded live by bigquery/23_trading_control.sql's
-- later CREATE OR REPLACE VIEW of the same object (which adds position_drift_detected to
-- all_green) — kept here, in numeric-apply order, for the DR-rebuild/reference sequence.
-- Kept structurally in sync with that later definition where they overlap.
--
-- SUPERSEDED LIVE by bigquery/173_freshness_cadence_aware.sql — current single source of truth for
-- this object (supersedes bigquery/23's later definition below in turn). 173 makes the freshness
-- dead-man cadence-aware for the Sun-Thu daily tier, folding state.freshness's new marks_due_through /
-- marks_current / engine_current columns into all_green in place of marks_fresh/engine_fresh. Kept
-- here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT re-apply this CREATE
-- statement live in isolation.
CREATE OR REPLACE VIEW `stock-trading-498512.state.system_health` AS
WITH alerts_summary AS (
  -- Computed once and reused below (2026-07-04 audit finding: open_critical_alerts and the
  -- identical subquery embedded in all_green were two hand-kept copies of the same COUNTIF).
  SELECT
    COUNTIF(NOT resolved AND severity = 'critical') AS open_critical_alerts,
    COUNTIF(NOT resolved) AS open_alerts
  FROM `stock-trading-498512.ops.alerts`
)
SELECT
  f.last_trading_day, f.last_mark_date, f.engine_through,
  f.marks_fresh, f.engine_fresh, f.d2_ran_last_trading_day,
  eh.is_healthy AS embeddings_healthy,
  a.open_critical_alerts,
  a.open_alerts,
  (SELECT COUNTIF(drawdown_kill OR runaway_review OR m2m_underperf_review) FROM `stock-trading-498512.perf.kill_flags`) AS firing_kill_flags,
  (f.marks_fresh AND f.engine_fresh AND eh.is_healthy AND a.open_critical_alerts = 0) AS all_green,
  CURRENT_TIMESTAMP() AS checked_at
FROM `stock-trading-498512.state.freshness` f, `stock-trading-498512.state.embedding_health` eh, alerts_summary a;

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

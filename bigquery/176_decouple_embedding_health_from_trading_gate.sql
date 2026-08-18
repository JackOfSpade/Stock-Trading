-- 176_decouple_embedding_health_from_trading_gate.sql (2026-08-17)
-- Project: stock-trading-498512. Apply after 175_selfheal_candidate_completion_guard.sql.
--
-- SUPERSEDES bigquery/107's definitions of state.trading_enabled, state.trading_enabled_mechanical
-- and state.b3_trading_enabled_check (the three-object subset of 107's "four" that read
-- embedding_health; ops.sp_auto_resolve_alerts is untouched here — see WHY NOT below). Per 47's/107's
-- own header rule, any future change to this gate cluster must land as a NEW numbered file that
-- supersedes THIS one — never re-apply an earlier file's CREATE OR REPLACE for these objects alone.
--
-- ============================ WHY ============================
-- AR_orc 2026-08-17 (commit a54a763, merged) caught a live instance of a previously undocumented race:
-- ops.sp_log_decision (bigquery/116) commits a decision_log row first and embeds it afterwards inside
-- an exception handler that never rethrows, so a slow or transiently-failed embed leaves
-- state.embedding_health.is_healthy = FALSE for a real but unbounded window (observed live 96s;
-- worst case is bounded only by the next opportunistic ops.sp_embed_pending() call anywhere in the
-- fleet, which can be hours). Every one of this file's three views folded that flag into the
-- capital-safety trading-enable boolean with zero grace period, so that transient window raised a
-- human-latching trading_halted critical — and AR_orc's own m2m-termination path writes its
-- termination decision row immediately BEFORE its inline gate re-check, making AR_orc the most
-- exposed site of all: capable of withholding the close orders and capital redistribution on a
-- strategy it had just terminated. a54a763 mitigated this on the READ side only, for AR_orc's own two
-- call sites (Claude_Task_Plan.md, best-effort CALL sp_embed_pending() before a trading-enable read) —
-- deliberately NOT the gate SQL itself, flagging it at warning under category gate_ordering
-- (ops.alerts 816f7e25) as "needs an owner or W5 decision", since a live-SQL change to a fleet-wide
-- capital gate is not a queue-drain routine's call to make.
--
-- OWNER DECISION (2026-08-17, interactive session responding to the forwarded gate_ordering alert):
-- decouple embedding health from the trading-halt gate entirely, rather than add a grace-period
-- tolerance or extend the read-side sp_embed_pending() prose fix to every other call site one at a
-- time. Rationale, per ops.sp_log_decision's own header comment (bigquery/116): "the embedding is a
-- DERIVED retrieval index" over decisions that are ALREADY durably logged in events.decision_log
-- regardless of embed outcome — an unhealthy embedding pipeline degrades future find_precedents
-- retrieval quality, it does not put capital, an open position, or a pending order at risk. That is a
-- categorically different signal than the fail-closed terms this gate exists to enforce (a live
-- halt_all flag, stale marks/engine, an open non-echo critical, position-reconciliation drift, a hard
-- drawdown breach). Folding it into the SAME boolean meant a transient AI-infra hiccup could halt
-- trading exactly like a genuine risk breach, and every call site that ever reads state.trading_enabled
-- (not just AR_orc's own two, already-patched sites) inherited that exposure.
--
-- embedding_health remains fully visible, just non-blocking: state.system_health.embeddings_healthy
-- (bigquery/173, unchanged by this file — its own comment already documents `all_green` as
-- display-only, since 107 was current) continues to surface it for the dashboard/weekly-email
-- operational-health narrative. This file's change is narrowly the removal of eh.is_healthy as a
-- BLOCKING term of the trading-enable gate cluster.
--
-- WHY NOT ops.sp_auto_resolve_alerts / bigquery/94's catchup_refire_blocked resolve check: both
-- separately read state.embedding_health.is_healthy inside a "would this staleness/catchup alert
-- genuinely clear right now" heuristic (live_would_clear) — a housekeeping decision about whether to
-- mark an ALREADY-RAISED, ALREADY-NON-BLOCKING alert resolved, not a capital-blocking gate. Leaving
-- embedding health in that heuristic only makes the auto-resolver marginally more conservative about
-- calling a staleness alert genuinely healed; it cannot itself halt trading, so it is out of scope for
-- this decision and is UNCHANGED.
--
-- ============================ WHAT CHANGES vs 107 ============================
-- state.trading_enabled: drops the `eh` CTE, the `AND COALESCE(eh.is_healthy, FALSE)` boolean term,
-- and the `WHEN NOT COALESCE(eh.is_healthy, FALSE)` halt_reason branch. Every other term (halt_all,
-- freshness, blocking criticals incl. both halt-echo exclusions, position-reconciliation drift, the
-- two drawdown-watch terms) is byte-identical to 107.
-- state.trading_enabled_mechanical: drops the `AND COALESCE(health.embeddings_healthy, FALSE)` boolean
-- term and its halt_reason branch; the `health` CTE now selects only position_drift_detected (the one
-- column still used). Everything else byte-identical to 107.
-- state.b3_trading_enabled_check: its `expected` CTE must track state.trading_enabled's new formula or
-- it would false-fire permanent drift (same rule 107's own header states for why this view exists) —
-- drops `eh` from `expected` the same way. Everything else byte-identical to 107.
--
-- Record: events.decision_log (this session) resolves ops.alerts 816f7e25 (AR_orc gate_ordering).

-- ===== state.trading_enabled — REDEFINED (SUPERSEDES bigquery/107) =====
CREATE OR REPLACE VIEW `stock-trading-498512.state.trading_enabled` AS
WITH ctrl AS (
  SELECT ARRAY_AGG(STRUCT(halt_all, reason, mode) ORDER BY control_ts DESC LIMIT 1)[SAFE_OFFSET(0)] AS latest
  FROM `stock-trading-498512.ops.trading_control`
),
f AS (SELECT marks_fresh, engine_fresh FROM `stock-trading-498512.state.freshness`),
halt_echo_md AS (
  -- missing_dependency alerts that are pure fallout of a same-day, still-open trading halt:
  -- every dep in payload.missing_deps has an OPEN trading_halted alert (source = dep) whose
  -- Denver date equals this alert's payload.run_date. Fail-closed: any parse failure or
  -- unmatched dep keeps the alert blocking, and a NULL alert_id is excluded outright — left
  -- in, it would make the downstream blocking-criticals NOT IN return NULL for every row and
  -- fail the gate OPEN. Delimiter ', ' matches sp_assert_deps' STRING_AGG(d, ', ') and
  -- sp_auto_resolve_alerts Rule 1's SPLIT.
  SELECT a.alert_id
  FROM `stock-trading-498512.ops.alerts` a,
       UNNEST(SPLIT(JSON_VALUE(a.payload, '$.missing_deps'), ', ')) AS dep
  LEFT JOIN `stock-trading-498512.ops.alerts` th
    ON th.category = 'trading_halted'
   AND NOT th.resolved
   AND th.source = dep
   AND DATE(th.alert_ts, 'America/Denver') =
       SAFE.PARSE_DATE('%Y-%m-%d', JSON_VALUE(a.payload, '$.run_date'))
  WHERE a.alert_id IS NOT NULL
    AND NOT a.resolved
    AND a.severity = 'critical'
    AND a.category = 'missing_dependency'
  GROUP BY a.alert_id
  HAVING LOGICAL_AND(th.alert_id IS NOT NULL)
),
halt_echo_mr AS (
  -- 'missed_run' critical alerts that are pure fallout of an already-known trading-gate halt. See
  -- bigquery/107's header for the full predicate + rationale. (A) reuses Rule 2's own completion test;
  -- (B) correlates the routine's latest halted attempt to a trading_halted alert within 24h.
  SELECT a.alert_id
  FROM `stock-trading-498512.ops.alerts` a,
       UNNEST(JSON_QUERY_ARRAY(a.payload)) AS item
  LEFT JOIN `stock-trading-498512.ops.run_log` r
    ON r.routine = JSON_VALUE(item, '$.routine') AND r.status = 'completed'
       AND r.run_date >= SAFE.PARSE_DATE('%Y-%m-%d', JSON_VALUE(item, '$.today'))
  LEFT JOIN (
    SELECT routine, MAX(log_ts) AS last_halt_ts
    FROM `stock-trading-498512.ops.run_log`
    WHERE status = 'halted'
    GROUP BY routine
  ) hr ON hr.routine = JSON_VALUE(item, '$.routine')
  LEFT JOIN `stock-trading-498512.ops.alerts` th
    ON th.category = 'trading_halted'
       AND hr.last_halt_ts IS NOT NULL
       AND ABS(TIMESTAMP_DIFF(th.alert_ts, hr.last_halt_ts, HOUR)) <= 24
  WHERE a.alert_id IS NOT NULL
    AND NOT a.resolved
    AND a.severity = 'critical'
    AND a.category = 'missed_run'
  GROUP BY a.alert_id
  HAVING LOGICAL_AND(r.routine IS NOT NULL OR th.alert_id IS NOT NULL)
),
al AS (
  SELECT COUNTIF(NOT resolved AND severity = 'critical'
    AND category NOT IN ('trading_halted', 'staleness')
    AND alert_id NOT IN (SELECT alert_id FROM halt_echo_md)
    AND alert_id NOT IN (SELECT alert_id FROM halt_echo_mr)) AS blocking_criticals
  FROM `stock-trading-498512.ops.alerts`
),
pr AS (SELECT COALESCE(LOGICAL_OR(drifted), FALSE) AS drift FROM `stock-trading-498512.state.position_reconciliation`),
dd AS (SELECT breach_hard, drawdown_from_peak, snapshot_stale FROM `stock-trading-498512.state.book_drawdown_watch`)
SELECT
  NOT COALESCE(ctrl.latest.halt_all, FALSE)
  AND COALESCE(f.marks_fresh, FALSE)
  AND COALESCE(f.engine_fresh, FALSE)
  AND al.blocking_criticals = 0
  AND NOT pr.drift
  AND NOT COALESCE(dd.breach_hard, FALSE)
  AND NOT COALESCE(dd.snapshot_stale, FALSE) AS trading_enabled,
  CASE
    WHEN COALESCE(ctrl.latest.halt_all, FALSE) THEN
      FORMAT('halt_all (mode=%s): %s', COALESCE(ctrl.latest.mode, '?'), COALESCE(ctrl.latest.reason, 'no reason logged'))
    WHEN NOT COALESCE(f.marks_fresh, FALSE) OR NOT COALESCE(f.engine_fresh, FALSE) THEN
      'state.freshness marks_fresh/engine_fresh not both TRUE'
    WHEN al.blocking_criticals != 0 THEN
      FORMAT('%d open critical alert(s) (excluding trading_halted/staleness/halt-echo dependency+missed_run gate echoes) — see ops.alerts', al.blocking_criticals)
    WHEN pr.drift THEN
      'state.position_reconciliation drift detected'
    WHEN COALESCE(dd.breach_hard, FALSE) THEN
      FORMAT('book NAV drawdown %.2f%% from flow-adjusted peak exceeds the -40%% CATASTROPHE circuit-breaker (full halt); the -15%% soft tier pauses new entries only', dd.drawdown_from_peak * 100)
    WHEN COALESCE(dd.snapshot_stale, FALSE) THEN
      'state.book_drawdown_watch.snapshot_stale = TRUE (ops.account_snapshot not refreshed for the current trading day — the breaker cannot trust its own peak/current NAV comparison; ITEM 16, 2026-07-11)'
    ELSE NULL
  END AS halt_reason
FROM ctrl, f, al, pr, dd;

-- ===== state.trading_enabled_mechanical — REDEFINED (SUPERSEDES bigquery/107) =====
-- Still deliberately excludes marks_fresh/engine_fresh (D2a's own same-run-circular term, per 33's
-- header). `health` now selects only position_drift_detected (embeddings_healthy is no longer read).
CREATE OR REPLACE VIEW `stock-trading-498512.state.trading_enabled_mechanical` AS
WITH ctrl AS (
  SELECT ARRAY_AGG(STRUCT(halt_all, reason, mode) ORDER BY control_ts DESC LIMIT 1)[SAFE_OFFSET(0)] AS latest
  FROM `stock-trading-498512.ops.trading_control`
),
health AS (
  SELECT position_drift_detected
  FROM `stock-trading-498512.state.system_health`
),
halt_echo_md AS (
  SELECT a.alert_id
  FROM `stock-trading-498512.ops.alerts` a,
       UNNEST(SPLIT(JSON_VALUE(a.payload, '$.missing_deps'), ', ')) AS dep
  LEFT JOIN `stock-trading-498512.ops.alerts` th
    ON th.category = 'trading_halted'
   AND NOT th.resolved
   AND th.source = dep
   AND DATE(th.alert_ts, 'America/Denver') =
       SAFE.PARSE_DATE('%Y-%m-%d', JSON_VALUE(a.payload, '$.run_date'))
  WHERE a.alert_id IS NOT NULL
    AND NOT a.resolved
    AND a.severity = 'critical'
    AND a.category = 'missing_dependency'
  GROUP BY a.alert_id
  HAVING LOGICAL_AND(th.alert_id IS NOT NULL)
),
halt_echo_mr AS (
  SELECT a.alert_id
  FROM `stock-trading-498512.ops.alerts` a,
       UNNEST(JSON_QUERY_ARRAY(a.payload)) AS item
  LEFT JOIN `stock-trading-498512.ops.run_log` r
    ON r.routine = JSON_VALUE(item, '$.routine') AND r.status = 'completed'
       AND r.run_date >= SAFE.PARSE_DATE('%Y-%m-%d', JSON_VALUE(item, '$.today'))
  LEFT JOIN (
    SELECT routine, MAX(log_ts) AS last_halt_ts
    FROM `stock-trading-498512.ops.run_log`
    WHERE status = 'halted'
    GROUP BY routine
  ) hr ON hr.routine = JSON_VALUE(item, '$.routine')
  LEFT JOIN `stock-trading-498512.ops.alerts` th
    ON th.category = 'trading_halted'
       AND hr.last_halt_ts IS NOT NULL
       AND ABS(TIMESTAMP_DIFF(th.alert_ts, hr.last_halt_ts, HOUR)) <= 24
  WHERE a.alert_id IS NOT NULL
    AND NOT a.resolved
    AND a.severity = 'critical'
    AND a.category = 'missed_run'
  GROUP BY a.alert_id
  HAVING LOGICAL_AND(r.routine IS NOT NULL OR th.alert_id IS NOT NULL)
),
al AS (
  SELECT COUNTIF(NOT resolved AND severity = 'critical'
    AND category NOT IN ('trading_halted', 'staleness')
    AND alert_id NOT IN (SELECT alert_id FROM halt_echo_md)
    AND alert_id NOT IN (SELECT alert_id FROM halt_echo_mr)) AS blocking_criticals
  FROM `stock-trading-498512.ops.alerts`
),
dd AS (SELECT breach_hard, drawdown_from_peak FROM `stock-trading-498512.state.book_drawdown_watch`)
SELECT
  NOT COALESCE(ctrl.latest.halt_all, FALSE)
  AND al.blocking_criticals = 0
  AND NOT COALESCE(health.position_drift_detected, TRUE)
  AND NOT COALESCE(dd.breach_hard, FALSE) AS trading_enabled,
  CASE
    WHEN COALESCE(ctrl.latest.halt_all, FALSE) THEN
      FORMAT('halt_all (mode=%s): %s', COALESCE(ctrl.latest.mode, '?'), COALESCE(ctrl.latest.reason, 'no reason logged'))
    WHEN al.blocking_criticals != 0 THEN
      FORMAT('%d open critical alert(s) (excluding trading_halted/staleness/halt-echo dependency+missed_run gate echoes) — see ops.alerts', al.blocking_criticals)
    WHEN COALESCE(health.position_drift_detected, TRUE) THEN
      'state.position_reconciliation drift detected'
    WHEN COALESCE(dd.breach_hard, FALSE) THEN
      FORMAT('book NAV drawdown %.2f%% from flow-adjusted peak exceeds the -40%% CATASTROPHE circuit-breaker (full halt)', dd.drawdown_from_peak * 100)
    ELSE NULL
  END AS halt_reason
FROM ctrl, health, al, dd;

-- ===== state.b3_trading_enabled_check — REDEFINED (SUPERSEDES bigquery/107) =====
-- The live formula self-check must track the gate it mirrors, or it false-fires drift (107's own
-- header rule) — `expected` drops `eh` the same way state.trading_enabled above does.
CREATE OR REPLACE VIEW `stock-trading-498512.state.b3_trading_enabled_check` AS
WITH ctrl AS (
  SELECT ARRAY_AGG(STRUCT(halt_all) ORDER BY control_ts DESC LIMIT 1)[SAFE_OFFSET(0)] AS latest
  FROM `stock-trading-498512.ops.trading_control`
),
f AS (SELECT marks_fresh, engine_fresh FROM `stock-trading-498512.state.freshness`),
halt_echo_md AS (
  SELECT a.alert_id
  FROM `stock-trading-498512.ops.alerts` a,
       UNNEST(SPLIT(JSON_VALUE(a.payload, '$.missing_deps'), ', ')) AS dep
  LEFT JOIN `stock-trading-498512.ops.alerts` th
    ON th.category = 'trading_halted'
   AND NOT th.resolved
   AND th.source = dep
   AND DATE(th.alert_ts, 'America/Denver') =
       SAFE.PARSE_DATE('%Y-%m-%d', JSON_VALUE(a.payload, '$.run_date'))
  WHERE a.alert_id IS NOT NULL
    AND NOT a.resolved
    AND a.severity = 'critical'
    AND a.category = 'missing_dependency'
  GROUP BY a.alert_id
  HAVING LOGICAL_AND(th.alert_id IS NOT NULL)
),
halt_echo_mr AS (
  SELECT a.alert_id
  FROM `stock-trading-498512.ops.alerts` a,
       UNNEST(JSON_QUERY_ARRAY(a.payload)) AS item
  LEFT JOIN `stock-trading-498512.ops.run_log` r
    ON r.routine = JSON_VALUE(item, '$.routine') AND r.status = 'completed'
       AND r.run_date >= SAFE.PARSE_DATE('%Y-%m-%d', JSON_VALUE(item, '$.today'))
  LEFT JOIN (
    SELECT routine, MAX(log_ts) AS last_halt_ts
    FROM `stock-trading-498512.ops.run_log`
    WHERE status = 'halted'
    GROUP BY routine
  ) hr ON hr.routine = JSON_VALUE(item, '$.routine')
  LEFT JOIN `stock-trading-498512.ops.alerts` th
    ON th.category = 'trading_halted'
       AND hr.last_halt_ts IS NOT NULL
       AND ABS(TIMESTAMP_DIFF(th.alert_ts, hr.last_halt_ts, HOUR)) <= 24
  WHERE a.alert_id IS NOT NULL
    AND NOT a.resolved
    AND a.severity = 'critical'
    AND a.category = 'missed_run'
  GROUP BY a.alert_id
  HAVING LOGICAL_AND(r.routine IS NOT NULL OR th.alert_id IS NOT NULL)
),
al AS (
  SELECT COUNTIF(NOT resolved AND severity = 'critical'
    AND category NOT IN ('trading_halted', 'staleness')
    AND alert_id NOT IN (SELECT alert_id FROM halt_echo_md)
    AND alert_id NOT IN (SELECT alert_id FROM halt_echo_mr)) AS blocking_criticals
  FROM `stock-trading-498512.ops.alerts`
),
pr AS (SELECT COALESCE(LOGICAL_OR(drifted), FALSE) AS drift FROM `stock-trading-498512.state.position_reconciliation`),
dd AS (SELECT breach_hard, snapshot_stale FROM `stock-trading-498512.state.book_drawdown_watch`),
expected AS (
  SELECT
    NOT COALESCE(ctrl.latest.halt_all, FALSE)
    AND COALESCE(f.marks_fresh, FALSE)
    AND COALESCE(f.engine_fresh, FALSE)
    AND al.blocking_criticals = 0
    AND NOT pr.drift
    AND NOT COALESCE(dd.breach_hard, FALSE)
    AND NOT COALESCE(dd.snapshot_stale, FALSE) AS v
  FROM ctrl, f, al, pr, dd
)
SELECT
  t.trading_enabled AS live_value,
  e.v AS expected_value,
  (t.trading_enabled IS DISTINCT FROM e.v) AS drift,
  CURRENT_TIMESTAMP() AS checked_at
FROM `stock-trading-498512.state.trading_enabled` t, expected e;

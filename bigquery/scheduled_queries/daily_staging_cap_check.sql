-- SCHEDULED QUERY (2026-07-04 audit finding): wires up state.daily_staging_totals
-- (bigquery/23_trading_control.sql), which was computed but read by nothing — a per-order guard
-- (analytics.fn_order_guard) cannot stop a runaway session staging many small in-band orders; this is
-- that missing daily-aggregate backstop actually being checked.
--
-- POSTURE: RECORD-ONLY WARNING (no RAISE) — same staged-rollout posture as integrity_check.sql. A
-- breach means "review today's staging before crafting one more", not a proven hard failure of any one
-- order, so it should not flip all_green or storm the DTS failure-email until a clean baseline is
-- confirmed. Promote to critical + RAISE later if desired (cadence_check.sql's pattern).
--
-- TIMING: any time during/after the trading day; ~05:25 UTC sits with the other daily control-plane
-- checks (after D2 has staged the day's orders). APPLY ORDER: bigquery/23_trading_control.sql must be
-- applied first.
-- SQ_NAME: daily_staging_cap_check  SQ_VERSION: v1 (self-improvement audit 2026-07-15, scheduled-query
-- body-drift detection — bigquery/63_scheduled_query_version_registry.sql). Bump SQ_VERSION here AND
-- state.expected_scheduled_query_versions' matching row on any future edit to this file's body.
BEGIN
  CALL `stock-trading-498512.ops.sp_beat_heartbeat`('sq:daily_staging_cap_check', 'v1', 'daily_staging_cap_check.sql ran');

  IF (SELECT daily_cap_breach FROM `stock-trading-498512.state.daily_staging_totals`) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'scheduled.staging_cap', 'staging_cap_breach',
      'Daily staging cap check: today\'s staged orders exceed the daily notional/order-count cap.',
      (SELECT TO_JSON_STRING(t) FROM `stock-trading-498512.state.daily_staging_totals` t));
  END IF;

  -- order_guard_omitted (CRITICAL, not staged-rollout -- ITEM 15, self-improvement audit 2026-07-11).
  -- fn_order_guard / fn_order_guard_options is a per-order obligation on the calling routine, with no
  -- mechanical enforcement possible (no BigQuery stored procedure can gate a call to a DIFFERENT MCP
  -- tool, create_order_instruction) -- compliance depended entirely on the routine's markdown instructions
  -- being followed verbatim. state.open_orders.guard_passed (bigquery/01_schema.sql) now surfaces whether
  -- the guard's own result was embedded in the ORDER_STAGED payload; a row STAGED TODAY with guard_passed
  -- IS NULL means either the guard never ran, or it ran and the routine didn't record it -- either way
  -- the safety envelope was bypassed for that order, not merely undocumented. Unlike the daily_cap_breach
  -- check above (a soft "review before crafting more" signal), a missing guard record is unambiguous --
  -- CRITICAL immediately, no staged-rollout warning period.
  --
  -- QUERIES events.queue_events DIRECTLY, NOT state.open_orders (adversarial self-audit fix, rev
  -- 2026-07-11): state.open_orders is a PENDING-ONLY view (WHERE status='pending'), so an order staged
  -- WITHOUT the guard that then FILLED or was reconciled the same Denver day drops out of it before this
  -- check runs at ~05:25 UTC -- exactly the worst case this control exists to catch (capital deployed
  -- outside the risk envelope) silently escaping detection. queue_events is append-only: the original
  -- 'pending' ORDER_STAGED row for an order staged today is never overwritten by its later terminal-status
  -- row (a separate row, same item_key), so filtering the raw table on status='pending' still finds every
  -- staging event from today regardless of what happened to the order afterward.
  -- MESSAGE EMBEDS THE AFFECTED item_keys (adversarial self-audit fix, rev 2026-07-11): ops.sp_raise_alert_once
  -- dedupes on (category, message) WHERE NOT resolved (bigquery/10_observability.sql). A fully static message
  -- would mean that once this CRITICAL opens and is left unresolved, a LATER day's guard-omission on a
  -- DIFFERENT, newly-affected order would silently fail to re-alert (the dedup guard blocks the INSERT before
  -- the fresh payload evidence is even recorded) -- exactly the kind of new information this check exists to
  -- surface. Embedding the sorted, comma-joined item_keys makes the message (and so the dedup key) change
  -- whenever the SET of affected orders changes, while an unchanged set (the same still-open omission, re-
  -- evaluated on a later run) still correctly dedupes to a single alert, not a new one every run.
  IF EXISTS (
    SELECT 1 FROM `stock-trading-498512.events.queue_events`
    WHERE queue = 'ORDER_STAGED' AND LOWER(status) = 'pending'
      AND DATE(event_ts, 'America/Denver') = CURRENT_DATE('America/Denver')
      AND JSON_VALUE(payload, '$.guard_passed') IS NULL
  ) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.staging_cap', 'order_guard_omitted',
      (SELECT FORMAT(
          'One or more orders staged today have no recorded fn_order_guard/fn_order_guard_options result -- the pre-craft risk envelope may have been bypassed for these orders: %s.',
          -- COALESCE defends against FORMAT('%s', NULL) returning a hard SQL NULL (verified) if this ever
          -- somehow evaluated over zero rows despite the IF EXISTS above having matched -- ops.alerts.message
          -- is NOT NULL, so an unguarded NULL here would error the whole scheduled query (adversarial
          -- self-audit fix, rev 2026-07-11; confirmed not currently reachable -- this predicate is
          -- byte-identical to the IF EXISTS guard and events.queue_events is append-only -- but free to close).
          COALESCE(STRING_AGG(DISTINCT item_key, ', ' ORDER BY item_key), 'UNKNOWN'))
       FROM `stock-trading-498512.events.queue_events`
       WHERE queue = 'ORDER_STAGED' AND LOWER(status) = 'pending'
         AND DATE(event_ts, 'America/Denver') = CURRENT_DATE('America/Denver')
         AND JSON_VALUE(payload, '$.guard_passed') IS NULL),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(
          item_key, strategy, ticker,
          UPPER(JSON_VALUE(payload, '$.side')) AS side,
          CAST(JSON_VALUE(payload, '$.qty') AS NUMERIC) AS qty,
          CAST(JSON_VALUE(payload, '$.limit_price') AS NUMERIC) AS limit_price,
          event_ts AS staged_ts)))
       FROM `stock-trading-498512.events.queue_events`
       WHERE queue = 'ORDER_STAGED' AND LOWER(status) = 'pending'
         AND DATE(event_ts, 'America/Denver') = CURRENT_DATE('America/Denver')
         AND JSON_VALUE(payload, '$.guard_passed') IS NULL));
  END IF;
END;

-- SCHEDULED QUERY (2026-07-04 audit finding): wires up ops.sp_fire_drill_order_guard
-- (bigquery/23_trading_control.sql), which was never scheduled — unlike its explicit model, the
-- monthly backup restore drill (bigquery/17_restore_drill.sql / scheduled_queries/restore_drill.sql).
-- An untested breaker is theater; this proves analytics.fn_order_guard still rejects a deliberately
-- oversized / off-band / negative-qty test order every cycle. Read-only against real tables; never
-- crafts a real order or writes to ops.trading_control (see the procedure's own header).
--
-- NOTIFICATION: the procedure itself raises a critical alert (via ops.sp_raise_alert, not _once, since
-- a failed fire drill must never silently dedupe away) if the guard fails to reject any of the 3 test
-- cases; email-on-failure is not required to catch that (it's a durable ops.alerts row), but enabling
-- it costs nothing extra and catches the query itself erroring (e.g. a signature change).
--
-- SCHEDULE: monthly is plenty (e.g. 06:10 UTC on the 1st, just after restore_drill.sql's 06:00 UTC —
-- both are "prove the safety net works" drills). Location US, no destination. APPLY ORDER:
-- bigquery/23_trading_control.sql (the procedure) must be applied first.
-- SQ_NAME: fire_drill_order_guard  SQ_VERSION: v1 (self-improvement audit 2026-07-15, scheduled-query
-- body-drift detection — bigquery/63_scheduled_query_version_registry.sql). Bump SQ_VERSION here AND
-- state.expected_scheduled_query_versions' matching row on any future edit to this file's body.
CALL `stock-trading-498512.ops.sp_beat_heartbeat`('sq:fire_drill_order_guard', 'v1', 'fire_drill_order_guard.sql ran');
CALL `stock-trading-498512.ops.sp_fire_drill_order_guard`();

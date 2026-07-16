-- SCHEDULED QUERY (P0-3): keep decision-log embeddings fresh with no active session.
-- ops.sp_embed_pending() is idempotent, self-healing, and costs pennies at the
-- ~1-entry/day cadence. Without this it only runs when a routine calls it.
--
-- Set up (BigQuery Studio -> Scheduled queries -> Create):
--   Schedule: daily ~06:00 UTC (BigQuery schedules are UTC; timing is irrelevant — idempotent)
--   Location: US     Project: stock-trading-498512
--   (No destination table.)  See ops/RUNBOOK.md "Scheduled queries".
-- SQ_NAME: embed_pending  SQ_VERSION: v1 (self-improvement audit 2026-07-15, scheduled-query
-- body-drift detection — bigquery/63_scheduled_query_version_registry.sql). Bump SQ_VERSION here AND
-- state.expected_scheduled_query_versions' matching row on any future edit to this file's body.
CALL `stock-trading-498512.ops.sp_beat_heartbeat`('sq:embed_pending', 'v1', 'embed_pending.sql ran');
CALL `stock-trading-498512.ops.sp_embed_pending`();

-- SCHEDULED QUERY (P0-3): keep decision-log embeddings fresh with no active session.
-- ops.sp_embed_pending() is idempotent, self-healing, and costs pennies at the
-- ~1-entry/day cadence. Without this it only runs when a routine calls it.
--
-- Set up (BigQuery Studio -> Scheduled queries -> Create):
--   Schedule: daily ~06:00 UTC (BigQuery schedules are UTC; timing is irrelevant — idempotent)
--   Location: US     Project: stock-trading-498512
--   (No destination table.)  See ops/RUNBOOK.md "Scheduled queries".
CALL `stock-trading-498512.ops.sp_embed_pending`();

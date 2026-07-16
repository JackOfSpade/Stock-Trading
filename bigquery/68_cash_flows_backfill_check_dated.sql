-- Date-scoped redefinition of state.cash_flows_backfill_check (consumption-closure audit 2026-07-16,
-- CC-3). Project: stock-trading-498512. Apply after 22_cash_flows.sql.
--
-- WHY: bigquery/22_cash_flows.sql's original state.cash_flows_backfill_check compares the SUM of
-- ALL events.cash_flows rows to the 9446.86 backfill-seed literal -- an apply-time gate meant to be
-- read once, by hand, right after the 2026-07-03 backfill landed. It was never wired to anything
-- automated, and it CANNOT be wired as-written: any future legitimate deposit/withdrawal (a single
-- INSERT per Operating_Protocols.md §13.C) would immediately flip `reconciled` to FALSE forever, so
-- polling it from cadence_check.sql would false-fire on ordinary account activity. This redefinition
-- DATE-SCOPES the comparison to `flow_date <= DATE '2026-07-03'` (the backfill's own effective date) so
-- it keeps testing exactly what it always tested -- "did the 2026-07-03 backfill reproduce the
-- pre-existing $9,446.86 total exactly" -- while becoming safe to poll nightly: a backdated, duplicate,
-- or typo'd flow dated on/before the cutover (which WOULD corrupt the NAV baseline every downstream
-- consumer relies on) still flips it to FALSE, but a legitimate future deposit provably cannot, since
-- it is dated after the cutover and excluded from the SUM by construction.
--
-- VERIFIED LIVE 2026-07-16: zero events.cash_flows rows exist with flow_date > 2026-07-03, so the
-- scoped and unscoped totals are identical (both 9446.86) as of this file's creation -- this
-- redefinition is semantics-preserving on apply day, not a silent behavior change.
--
-- Same view name as bigquery/22_cash_flows.sql's CREATE OR REPLACE VIEW (retroactive-redefine
-- convention, same pattern as bigquery/18/19_stack_review_fixes*.sql) -- this file's body is the
-- one that should be live after both are applied in order.
CREATE OR REPLACE VIEW `stock-trading-498512.state.cash_flows_backfill_check` AS
SELECT
  (SELECT ROUND(SUM(amount), 2) FROM `stock-trading-498512.events.cash_flows`
   WHERE flow_date <= DATE '2026-07-03') AS cash_flows_total_asof_backfill,
  CAST(9446.86 AS NUMERIC) AS expected_total,
  (SELECT ROUND(SUM(amount), 2) FROM `stock-trading-498512.events.cash_flows`
   WHERE flow_date <= DATE '2026-07-03') = CAST(9446.86 AS NUMERIC) AS reconciled;

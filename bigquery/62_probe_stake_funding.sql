-- Probe-stake funding gap tracking (self-improvement audit 2026-07-15 — CONFIRMED GAP
-- probe-stake-floor-prose-only, second half; the first half — analytics.strategy_nav's
-- capital-eligibility deadlock — is fixed in bigquery/22_cash_flows.sql this same session). Project:
-- stock-trading-498512. Apply after 22_cash_flows.sql, 35_strategy_arsenal.sql.
--
-- PROBLEM: Experiment_Parameters.md's "New strategy funding (probe stake)" section + the "Pending
-- newcomer" glossary entry document a real policy — a newcomer starts FROZEN (non-trading, zero
-- booked allocation) and has FIRST CLAIM (priority over the standard equal split) on incoming
-- deposits AND termination-redistribution capital until its booked allocation reaches the $2,000
-- probe-stake floor, at which point it unfreezes. SL5's PROBE-register step and D2's termination
-- procedure both already reference "the existing probe-stake funding queue" / "fill any pending
-- newcomer strategies to their $2,000 probe-stake floor (FIFO, oldest first)" as if a concrete
-- mechanism existed — verified live 2026-07-15: no such object exists anywhere in bigquery/, dbt/, or
-- scripts/. The policy was real, documented, referenced by name — but not implemented.
--
-- FIX, deliberately SAFETY-CONSCIOUS (this repo's live order-guard function,
-- analytics.fn_order_guard, gates every strategy's real order flow including the 5 live A-E
-- strategies — this file does NOT touch it, to keep zero blast radius on current live trading):
--   1. state.strategy_probe_funding_gap (below) — the objective, queryable "who's owed floor top-up,
--      how much, in what FIFO order" signal, reading analytics.strategy_nav.deposits (already fixed
--      this session to include a PROBE strategy's booked allocation from its own immutable_since
--      onward, not just post-ADOPTED).
--   2. The DEPOSIT-ROUTING decision (which cash_flows rows get strategy-tagged to a pending newcomer
--      vs left NULL for the standard equal split) stays exactly where it already lives —
--      Operating_Protocols.md §13.C's single-INSERT deposit-recording instruction — now pointed at
--      this view instead of being pure prose. No change to the cash_flows table/strategy_nav's
--      equal-split logic itself; "first claim" is implemented entirely by WHICH deposits get tagged,
--      reusing the existing, already-CI-guarded strategy-tag convention.
--   3. The FROZEN (non-trading) half of the policy is enforced as an EXPLICIT pre-check inside D1's/
--      D2's own order-crafting flow for a PROBE-phase strategy specifically (Claude_Task_Plan.md) —
--      NOT inside analytics.fn_order_guard, which every strategy (including live A-E) calls today.
--      Zero behavioral change for any currently-active strategy; a real, correctly-scoped freeze for
--      a future newcomer whose funding_gap_dollars > 0.
--
-- ===== state.strategy_probe_funding_gap — objective floor-funding status, FIFO order =====
-- Empty whenever no strategy is in PROBE (true for the current 5-strategy roster; every strategy is
-- ADOPTED). Self-bootstrapping: nothing alarms until a real PROBE strategy exists.
CREATE OR REPLACE VIEW `stock-trading-498512.state.strategy_probe_funding_gap` AS
SELECT
  r.strategy_code,
  r.immutable_since AS probe_entry_ts,
  COALESCE(nav.deposits, 0) AS booked_allocation,
  GREATEST(0, 2000 - COALESCE(nav.deposits, 0)) AS funding_gap_dollars,
  COALESCE(nav.deposits, 0) >= 2000 AS floor_met,
  TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), r.immutable_since, DAY) AS days_since_probe_entry
FROM `stock-trading-498512.state.strategy_roster` r
LEFT JOIN `stock-trading-498512.analytics.strategy_nav` nav ON nav.strategy = r.strategy_code
WHERE r.current_state = 'PROBE';
-- FIFO consumption order: ORDER BY probe_entry_ts ASC (view output order is not guaranteed by
-- BigQuery — callers that need strict FIFO must ORDER BY explicitly, same discipline as every other
-- queue-drain read in this codebase, e.g. D3's "oldest due" pattern).

-- ===== state.strategy_probe_funding_stalled — a pending newcomer stuck below floor too long =====
-- CALIBRATION NOTE: 90 days is a reasoned starting placeholder, not calibrated against real deposit
-- cadence history (this account's deposits are irregular, owner-initiated events with no fixed
-- schedule — there is no historical inter-deposit-interval data to calibrate against as of
-- 2026-07-15). The system can PRIORITIZE existing/incoming deposits toward a newcomer but cannot
-- manufacture money it doesn't have; this alert's purpose is to surface "a newcomer has been frozen a
-- long time — is a deposit needed / is the floor-priority routing instruction actually being
-- followed?" to the owner, not to imply a bug fixes itself. Re-tune the 90-day constant once real
-- deposit-cadence data exists.
CREATE OR REPLACE VIEW `stock-trading-498512.state.strategy_probe_funding_stalled` AS
SELECT strategy_code, probe_entry_ts, booked_allocation, funding_gap_dollars, days_since_probe_entry
FROM `stock-trading-498512.state.strategy_probe_funding_gap`
WHERE NOT floor_met AND days_since_probe_entry >= 90;

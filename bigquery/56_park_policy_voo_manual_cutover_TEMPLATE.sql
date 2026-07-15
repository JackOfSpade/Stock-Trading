-- bigquery/56_park_policy_voo_manual_cutover_TEMPLATE.sql
-- TEMPLATE, NOT auto-applied by this migration and NOT part of the apply-in-order sequence.
-- Run this ONCE, live, via the BigQuery MCP, on the SAME DAY the owner executes the manual IBKR
-- "sell all SGOV, buy VOO" transfer (Operating_Protocols.md §13's "2026-07-15 SGOV→VOO cutover
-- itself" checklist). This is the single action that flips state.park_policy_current from SGOV to
-- VOO and therefore the D2a sweep/tripwire, analytics.fn_order_guard's price band, and every
-- vehicle-aware view — no other code change is needed.
--
-- BEFORE running: fill in the 5 placeholders below from the actual IBKR fill confirmations
-- (get_account_trades). Do not guess — use the real fill prices/commissions/timestamps.
--   <TRANSFER_DATE>        e.g. DATE '2026-07-22'  -- the actual trading day of the transfer
--   <SGOV_SELL_SHARES>     the exact SGOV share count sold (get_account_positions showed ~92.0612
--                          as of 2026-07-15; re-verify same-day before filling this in)
--   <SGOV_SELL_PRICE>      actual fill price per share
--   <SGOV_SELL_COMMISSION> actual commission charged
--   <VOO_BUY_SHARES>       the exact VOO share count bought (fractional OK — ~13.3 sh at VOO's
--                          2026-07-15 price of ~$693.79; re-derive from the actual SGOV proceeds
--                          and the actual VOO fill price, not this stale estimate)
--   <VOO_BUY_PRICE>        actual fill price per share
--   <VOO_BUY_COMMISSION>   actual commission charged (UNVERIFIED whether this is $0 or follows
--                          SGOV's ~1%-of-value schedule — see Operating_Protocols.md §13's VOO
--                          commission-model note; record whatever IBKR actually charged)
--   <ORDER_ID_SELL> / <ORDER_ID_BUY>  the connector's order/instruction ids, for the audit trail

-- 1) Flip the live park policy. Everything downstream (state.park_policy_current,
--    state.park_position_current, state.park_reconciliation, analytics.fn_order_guard's price
--    band) reads this automatically -- no other statement in this file is what does the "cutover";
--    this INSERT is.
INSERT INTO `stock-trading-498512.events.park_policy_changes` (effective_date, vehicle, note)
VALUES (
  <TRANSFER_DATE>,
  'VOO',
  'Owner-executed manual IBKR transfer: sold all SGOV, bought VOO. Owner directive 2026-07-15 (events.decision_log). This row is what activates the VOO parking-vehicle cutover -- see bigquery/54_park_policy_voo_cutover.sql.'
);

-- 2) Record the two conversion legs in events.parking_events, so state.park_position /
--    state.park_reconciliation reconcile exactly against the connector's post-transfer holdings.
INSERT INTO `stock-trading-498512.events.parking_events`
  (action_date, strategy, action, ticker, shares, price, commission, gross, order_id, note)
VALUES
  (<TRANSFER_DATE>, NULL, 'SELL', 'SGOV', <SGOV_SELL_SHARES>, <SGOV_SELL_PRICE>, <SGOV_SELL_COMMISSION>,
   <SGOV_SELL_SHARES> * <SGOV_SELL_PRICE>, '<ORDER_ID_SELL>',
   'Owner-directed SGOV->VOO parking-vehicle cutover (2026-07-15 owner directive) -- full SGOV liquidation.'),
  (<TRANSFER_DATE>, NULL, 'BUY', 'VOO', <VOO_BUY_SHARES>, <VOO_BUY_PRICE>, <VOO_BUY_COMMISSION>,
   <VOO_BUY_SHARES> * <VOO_BUY_PRICE>, '<ORDER_ID_BUY>',
   'Owner-directed SGOV->VOO parking-vehicle cutover (2026-07-15 owner directive) -- initial VOO park position.');

-- 3) Verify: state.park_policy_current should now read VOO, and state.park_reconciliation should
--    show a park_ticker of VOO whose events_park_shares/events_park_market_value are within ~$1 of
--    the connector's live VOO holding (get_account_positions, contract_id 136155102). Run both as
--    a sanity check before trusting the next D2a run's tripwire.
-- SELECT * FROM `stock-trading-498512.state.park_policy_current`;
-- SELECT * FROM `stock-trading-498512.state.park_reconciliation`;

-- 4) Append a dated bullet to Operating_Protocols.md §13's Revision history and
--    ops/RUNBOOK.md §42 confirming the cutover executed (date, share counts, any tripwire result),
--    and update Claude_Task_Plan.md:271's cached contract_id list note if VOO's contract_id ever
--    needs re-resolving. Not required for the system to function -- state.park_policy_current is
--    already the live source of truth the moment step 1 lands -- but keeps the docs from claiming
--    "not yet executed" after it has been.

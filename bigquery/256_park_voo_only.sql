-- bigquery/256_park_voo_only.sql (2026-10-15)
-- Project: stock-trading-498512. Apply after bigquery/220_park_two_sleeve_book.sql (state.park_policy_current,
-- state.park_position_current) and bigquery/92_park_allocator.sql (the state.park_menu this file supersedes).
--
-- OWNER DIRECTIVE 2026-10-15 (interactive session): "lets simplify and just park idle cash in VOO, no more
-- SGOV" + "change remote routines so they no longer waste compute on whether to go SGOV or VOO".
-- The park is now VOO-ONLY, permanently. The AI park allocator's VOO-vs-defensive-sleeve decision (D1 PARK
-- ALLOCATION CALL, D2 PARK ALLOCATION CONVERSION, the graded v4 ladder) is RETIRED. Idle-cash SWEEPS into
-- VOO and COVERS out of VOO (Operating_Protocols.md §13.E) are unchanged.
--
-- ===== WHY (measured in the same session) =====
-- Every completed defensive excursion since the 2026-09-02 binary switch bought VOO back HIGHER than it
-- sold it, or flat: 09-02 out 700.87 -> 09-04 in 709.89; 09-09 out 702.41 -> 09-18 in 701.80; 09-11 out
-- 703.08 -> 09-23 in 712.24; 09-30 out 705.93 -> 10-06 in 715.28 (IBKR fills), ~$275 of whipsaw on a
-- ~$12.5k park plus repeated wash-sale disallowances. Structural, not luck: every axis compares a close
-- against a 20/50-day average and executes at the next open, so in a range-bound tape the switch sells
-- after down closes and re-buys after rallies. A 1993-2026 SPY backtest of the same family (close vs
-- 20dma) returned 3.66%/yr against 10.86% buy-and-hold; the v4 activation's own four-arm result had
-- never-switch VOO first (+4.73%) over the ladder (+3.00%). The park is ~96% of NAV with strategy draws of
-- $30-$115 each, so it is long-horizon capital in practice. The owner declined the slower crash-brake
-- variant (DD>=15% AND <200dma) in favour of plain VOO.
--
-- ===== FOUR STATEMENTS =====
--   1. events.park_policy_changes: VOO in BOTH sleeves at target_f_pct 0. Live policy before this file
--      was f=25 (D2 2026-10-14 conversion 09fabb1b, VOO 75 / SGOV 25) while the account held 0 SGOV.
--      Naming VOO as the defensive sleeve too is the "degenerate but legal" both-sleeves-same-ticker case
--      state.park_position_current's targets_dedup was written for: it collapses to ONE target row, VOO
--      at 100, so SGOV is no longer a target sleeve at any weight and any SGOV ever held again surfaces
--      as a residual (is_policy_vehicle FALSE) that §13.E's stranded-leg rule liquidates into VOO.
--      This row DOES reach the book (feedback: park correction rows can trigger a trade) - deliberately:
--      it sets target = what is held, so the convergence band reads 0pp and nothing is crafted.
--   2. events.queue_events: the two legs D2 staged 2026-10-14 (park-derisk-sell-VOO-20261014 /
--      park-derisk-buy-SGOV-20261014, IBKR instructions 100/101) go to terminal 'abandoned' - the owner
--      is not confirming them and deletes the instructions. Without this row they would stay 'pending' in
--      state.open_orders and D2 Step 0 would re-craft them.
--   3. events.decision_log: the owner-directive record.
--   4. state.park_menu: VOO only. D2's and §13.E's first rail is a menu-membership check, so this makes a
--      conversion into SGOV (or any other vehicle) mechanically refused even if stale prose ever proposed
--      one. Last in the file so check_live_sql_parity's extract_body() sees only trailing -- lines.
-- Idempotent: 1-3 are NOT EXISTS-guarded; 4 is CREATE OR REPLACE.

INSERT INTO `stock-trading-498512.events.park_policy_changes`
  (event_id, event_ts, effective_date, vehicle, note, target_f_pct, risk_sleeve, defensive_sleeve)
SELECT GENERATE_UUID(), CURRENT_TIMESTAMP(), DATE '2026-10-15', 'VOO',
  'PARK-VOO-ONLY 2026-10-15 - OWNER DIRECTIVE (interactive session): the park is held 100% in VOO permanently; '
  || 'the AI park allocator VOO-vs-defensive-sleeve decision is RETIRED (bigquery/256). Supersedes the D2 '
  || '2026-10-14 graded de-risk 09fabb1b (f 0 -> 25), whose two legs the owner declined unconfirmed. '
  || 'VOO is named in BOTH sleeves at target_f_pct 0, so state.park_position_current carries one target '
  || 'row (VOO 100) and no SGOV sleeve at any weight. Target equals holdings (VOO 17.7307, SGOV 0): no order.',
  0, 'VOO', 'VOO'
FROM (SELECT 1)
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.events.park_policy_changes` WHERE note LIKE 'PARK-VOO-ONLY%');

INSERT INTO `stock-trading-498512.events.queue_events`
  (event_id, event_ts, queue, item_key, item_type, status, strategy, ticker, due_date,
   conservative_default, artifact_path, payload, note)
SELECT GENERATE_UUID(), CURRENT_TIMESTAMP(), q.queue, q.item_key, q.item_type, 'abandoned', q.strategy, q.ticker,
  q.due_date, q.conservative_default, q.artifact_path,
  JSON_SET(q.payload, '$.abandon_reason',
    'owner declined 2026-10-15: park is VOO-only (bigquery/256); IBKR instruction deleted unconfirmed'),
  'ABANDONED 2026-10-15 by owner directive (bigquery/256): park retired to VOO-only, this leg of the '
  || 'D2 2026-10-14 graded de-risk is not to be confirmed, re-crafted, or re-staged.'
FROM (
  SELECT * FROM `stock-trading-498512.events.queue_events`
  WHERE queue = 'ORDER_STAGED'
    AND item_key IN ('park-derisk-sell-VOO-20261014', 'park-derisk-buy-SGOV-20261014')
  QUALIFY ROW_NUMBER() OVER (PARTITION BY item_key ORDER BY event_ts DESC) = 1
) q
WHERE LOWER(q.status) = 'pending';

INSERT INTO `stock-trading-498512.events.decision_log`
  (entry_id, event_ts, entry_date, entry_type, decision, title, body_md, fields, refs, tags, source_session)
SELECT GENERATE_UUID(), CURRENT_TIMESTAMP(), DATE '2026-10-15', 'owner-directive', 'PARK_VOO_ONLY_ALLOCATOR_RETIRED',
  'Owner directive 2026-10-15: idle cash parks in VOO only; the AI park allocator (SGOV/VOO decision) is retired',
  '''In an interactive session the owner asked whether the park was "chasing VOO" - swapping into VOO after it popped and out after it dipped. Measured: every completed defensive excursion since 2026-09-02 bought VOO back higher than it sold it, or flat (09-02 700.87 -> 09-04 709.89; 09-09 702.41 -> 09-18 701.80; 09-11 703.08 -> 09-23 712.24; 09-30 705.93 -> 10-06 715.28), ~$275 of whipsaw plus repeated wash-sale disallowances. The mechanism is structural: every evidence axis compares a close with a 20/50-day average and trades at the next open, so a range-bound tape is sold after down closes and re-bought after rallies. A 1993-2026 SPY backtest of that family returned 3.66%/yr against 10.86% buy-and-hold; a slow crash brake (drawdown >= 15% AND below the 200dma) returned 10.56% with a -20% worst drawdown versus -55%. Given the park is ~96% of NAV and strategy draws are $30-$115, the owner chose plain VOO, no SGOV, and asked that the routines stop spending compute on the decision.

**Implemented (bigquery/256):** policy pinned to VOO in both sleeves at target_f_pct 0; the 2026-10-14 de-risk legs (IBKR instructions 100/101) abandoned unconfirmed; state.park_menu reduced to VOO. In Claude_Task_Plan.md: D1's PARK ALLOCATION CALL is replaced by a PARK PIN CHECK (read state.park_policy_current, confirm VOO in both sleeves at target_f_pct 0, write the loop:park_allocator heartbeat) with no evidence gathering, no call and no park-allocation decision_log row; D2's PARK ALLOCATION CONVERSION is retired; D2a's park-menu signal ingest is trimmed to the instruments other consumers read (^VIX, SPY, Brent) and the park-only TREASURY_10Y write is dropped; W5's park scorecard and forward-test countdown are retired. Sweeps into VOO and covers out of VOO (Operating_Protocols.md section 13.E) are unchanged.

**Do not re-propose** a defensive sleeve, a graded ladder, or a signal-driven VOO/SGOV switch without a new owner directive. A withdrawal the owner names in advance is a funding decision, not a park-allocation one.''',
  JSON '{"policy_before": {"target_f_pct": 25, "risk_sleeve": "VOO", "defensive_sleeve": "SGOV", "event_id": "09fabb1b-429b-4c20-9b0e-fe32949b8027"}, "policy_after": {"target_f_pct": 0, "risk_sleeve": "VOO", "defensive_sleeve": "VOO"}, "abandoned_item_keys": ["park-derisk-sell-VOO-20261014", "park-derisk-buy-SGOV-20261014"], "ibkr_instruction_ids": ["100", "101"], "holdings_at_directive": {"VOO": 17.7307, "SGOV": 0}}',
  ['bigquery/256_park_voo_only.sql', 'events.park_policy_changes:09fabb1b-429b-4c20-9b0e-fe32949b8027'],
  ['park', 'owner-directive', 'park-voo-only'],
  'interactive-2026-10-15'
FROM (SELECT 1)
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.state.decision_log_current`
  WHERE entry_type = 'owner-directive' AND decision = 'PARK_VOO_ONLY_ALLOCATOR_RETIRED');

-- state.park_menu: VOO only (supersedes bigquery/92's 12-row menu). risk_tier is retained for shape
-- compatibility; with a single vehicle no switch direction can be classified, which is the point.
CREATE OR REPLACE VIEW `stock-trading-498512.state.park_menu` AS
SELECT * FROM UNNEST([
  STRUCT('VOO' AS ticker, 'equity_sp500' AS asset_class, 4 AS risk_tier)
]);

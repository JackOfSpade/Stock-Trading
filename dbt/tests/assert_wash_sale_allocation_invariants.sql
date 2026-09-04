-- Singular test (passes when ZERO rows): the wash-sale allocation invariants that bigquery/219
-- cannot assert in-file.
--
-- WHY THIS LIVES HERE AND NOT AS AN ASSERT IN bigquery/219. That file's post-conditions were written
-- as ASSERT statements, and BigQuery rejects them outright: "WITH RECURSIVE is not supported in
-- ASSERT statements". state.wash_sale_exposure became recursive on 2026-09-04 when the joint
-- allocation walk replaced a per-lot running sum, so the ASSERTs became unrunnable the moment the
-- fix landed. Deleting them would have left the fix unguarded, so they moved to the repo's existing
-- singular-test mechanism instead.
--
-- WHAT IS BEING GUARDED. Two independent defects were fixed in 219 and each has a value that pins it:
--   * SIBLING-LEG OWN-BASIS. An exchange-split park SELL lands as several parking_events rows, each
--     its own sell_trade_id. bigquery/178 excluded only the lots FIFO-assigned to THAT leg, so the
--     same sale's other legs' basis lots were counted as external replacements -- manufacturing a
--     wash sale out of an ordinary full liquidation. 13 of the 14 lots listed against the 2026-09-02
--     sale were that sale's own basis.
--   * ALLOCATION STARVATION. The first cut allocated each lot against a running sum of FULL
--     close_shares, so a lot was booked consumed by an earlier close that had already been satisfied
--     by other lots. The 2026-07-27 group read $51.36 against a correct $77.18 with 26.7739 shares of
--     supply against 13.4048 of demand. Under-reporting a wash sale is the UNSAFE direction.
--
-- WHY 2026-09-02 IS ZERO -- TWO MECHANISMS, NOT ONE (corrected 2026-09-04). Do NOT restate this as
-- "there is no external replacement": the view's own replacement_trades contradicts that. Lot
-- 129b0405 (0.8477 sh) IS a genuine external candidate and still appears on all five 09-02 legs at
-- offset -29. It contributes nothing because the JOINT allocation walk already consumed it in full at
-- the earlier 2026-07-27 close, where the same lot qualifies at offset +8. So this row guards the
-- sibling-leg exclusion AND the shared-pool ordering together, which is why it is worth keeping even
-- though its expected value is the trivial one.
--
-- THE 09-02 ROW EXPIRES BY DESIGN. Its expectation flips the moment the staged 2026-09-04 VOO rebuy
-- fills -- that purchase IS a genuine replacement within 30 days, and the figure becomes ~$107.73
-- (repo FIFO, losing legs only; NOT the -$149.18 IBKR average-cost figure, which is a different basis
-- method -- see 219's header). When that happens, RE-PIN the expected value here to the newly
-- measured one; do NOT delete the check. The 07-27 expectation is historical and should not move.
--
-- THE STRATEGY-ARM GUARD IS PINNED ON QUANTITY, NOT ON THE DISALLOWED DOLLAR (re-pinned 2026-09-04).
-- It used to assert HCA 2026-06-29 -> $0.00. That could not fail: 219 is monotone non-increasing
-- against 178, and that row was ALREADY at the 0.00 floor (0.0642 sh x 0.0001 replacement -> $0.0048,
-- which rounds to 0.00), so the only direction 219 can move it is the one the assert already
-- accepted. Pinning the SHARE quantities instead gives it real resolution -- the trip threshold is
-- 0.00010364 shares. Note the framing correction too: the shared-pool change is deliberately
-- CROSS-SOURCE and DOES apply to strategy rows; this guards that the live strategy arm is unchanged
-- in fact, not that it is out of scope by construction.

WITH expectations AS (
  SELECT DATE '2026-09-02' AS close_date, 'VOO' AS ticker, NUMERIC '0'  AS expected_disallowed
  UNION ALL
  SELECT DATE '2026-07-27',               'VOO',            NUMERIC '77.18'
),
actual AS (
  SELECT close_date, ticker, ROUND(SUM(estimated_disallowed_loss), 2) AS disallowed
  FROM {{ source('state', 'wash_sale_exposure') }}
  GROUP BY close_date, ticker
),
park_failures AS (
  SELECT FORMAT('park %t %s', e.close_date, e.ticker)          AS check_name,
         FORMAT('%t', e.expected_disallowed)                   AS expected,
         FORMAT('%t', COALESCE(a.disallowed, NUMERIC '0'))     AS actual
  FROM expectations e
  LEFT JOIN actual a USING (close_date, ticker)
  WHERE COALESCE(a.disallowed, NUMERIC '0') != e.expected_disallowed
),
strategy_arm AS (
  SELECT COUNT(*) AS n_rows,
         COALESCE(SUM(capped_replacement_shares), NUMERIC '0') AS sum_capped
  FROM {{ source('state', 'wash_sale_exposure') }}
  WHERE close_strategy != 'PARK'
),
strategy_failures AS (
  SELECT 'strategy arm untouched'                              AS check_name,
         '4 rows / 0.0001 capped sh'                           AS expected,
         FORMAT('%d rows / %t capped sh', n_rows, sum_capped)  AS actual
  FROM strategy_arm
  WHERE n_rows != 4 OR sum_capped != NUMERIC '0.0001'
)
SELECT * FROM park_failures
UNION ALL
SELECT * FROM strategy_failures

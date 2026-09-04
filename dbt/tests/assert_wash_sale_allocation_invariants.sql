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
-- WHAT IS BEING GUARDED. Two independent defects were fixed in 219, and each has its own check here:
--   * SIBLING-LEG OWN-BASIS (check 1). An exchange-split park SELL lands as several parking_events
--     rows, each its own sell_trade_id. bigquery/178 excluded only the lots FIFO-assigned to THAT
--     leg, so the same sale's other legs' basis lots were counted as external replacements --
--     manufacturing a wash sale out of an ordinary full liquidation. 13 of the 14 lots listed against
--     the 2026-09-02 sale were that sale's own basis.
--   * ALLOCATION STARVATION (check 2). The first cut allocated each lot against a running sum of FULL
--     close_shares, so a lot was booked consumed by an earlier close that had already been satisfied
--     by other lots. The 2026-07-27 group read $51.36 against a correct $77.18 with 26.7739 shares of
--     supply against 13.4048 of demand. Under-reporting a wash sale is the UNSAFE direction.
--
-- CHECK 1 IS PINNED ON THE DEFECT, NOT ON A DOLLAR VALUE -- deliberately (2026-09-04). The obvious
-- pin, "2026-09-02 disallowed = $0.00", is a FILL-DEPENDENT receipt with a known expiry: the staged
-- 09-04 VOO rebuy IS a genuine replacement within 30 days, so the moment D2a records it the correct
-- answer jumps from $0.00 to ~$107.73 and a $0.00 pin turns CI red on a working system. (The rebuy
-- filled at the broker on 2026-09-04; repo ingest follows in that session's D2a.) Asserting instead
-- that NO LOT OF THE SALE'S OWN BASIS EVER APPEARS AS ITS OWN REPLACEMENT states the actual
-- invariant, holds identically before and after the rebuy, and cannot be satisfied by the bug: under
-- bigquery/178 this check returns 13 leaked lots, under 219 it returns 0.
--
-- WHY 2026-09-02 WAS ZERO PRE-FILL -- TWO MECHANISMS, NOT ONE. Do NOT restate it as "there is no
-- external replacement": the view's own replacement_trades contradicts that. Lot 129b0405 (0.8477 sh)
-- IS a genuine external candidate and appears on all five 09-02 legs at offset -29. It contributed
-- nothing because the JOINT allocation walk had already consumed it in full at the earlier 2026-07-27
-- close, where the same lot qualifies at offset +8.
--
-- CHECK 2 IS STABLE ACROSS THE REBUY. The 07-27 replacement window closes 2026-08-26, so a 09-04
-- purchase is outside it and cannot move that group. It is historical and should not change.
--
-- CHECK 3, THE STRATEGY ARM, IS PINNED ON QUANTITY, NOT ON THE DISALLOWED DOLLAR (re-pinned
-- 2026-09-04). It used to assert HCA 2026-06-29 -> $0.00. That could not fail: 219 is monotone
-- non-increasing against 178, and that row was ALREADY at the 0.00 floor (0.0642 sh x 0.0001
-- replacement -> $0.0048, which rounds to 0.00), so the only direction 219 can move it is the one the
-- assert already accepted. Pinning the SHARE quantities instead gives it real resolution -- the trip
-- threshold is 0.00010364 shares, and the wrong-pin case was verified to fire. Note the framing
-- correction too: the shared-pool change is deliberately CROSS-SOURCE and DOES apply to strategy
-- rows; this guards that the live strategy arm is unchanged in fact, not that it is out of scope by
-- construction. The 09-04 VOO rebuy cannot reach it -- the pool is restricted to matching tickers.

WITH own_basis AS (
  -- Every buy-lot that the 2026-09-02 liquidation itself consumed.
  SELECT DISTINCT buy_trade_id
  FROM {{ ref('park_tax_lots') }}
  WHERE exit_date = DATE '2026-09-02'
),
own_basis_leak AS (
  SELECT COUNT(*) AS n
  FROM {{ ref('wash_sale_exposure') }} w,
       UNNEST(w.replacement_trades) r
  JOIN own_basis o ON o.buy_trade_id = r.replacement_trade_id
  WHERE w.close_date = DATE '2026-09-02'
),
check_own_basis AS (
  SELECT 'sibling-leg own basis (2026-09-02)'   AS check_name,
         '0 own-basis lots as replacements'     AS expected,
         FORMAT('%d leaked', n)                 AS actual
  FROM own_basis_leak
  WHERE n != 0
),
actual_0727 AS (
  SELECT ROUND(SUM(estimated_disallowed_loss), 2) AS disallowed
  FROM {{ ref('wash_sale_exposure') }}
  WHERE close_date = DATE '2026-07-27' AND ticker = 'VOO'
),
check_starvation AS (
  SELECT 'allocation starvation (2026-07-27 VOO)' AS check_name,
         '77.18'                                  AS expected,
         FORMAT('%t', COALESCE(disallowed, NUMERIC '0')) AS actual
  FROM actual_0727
  WHERE COALESCE(disallowed, NUMERIC '0') != NUMERIC '77.18'
),
strategy_arm AS (
  SELECT COUNT(*) AS n_rows,
         COALESCE(SUM(capped_replacement_shares), NUMERIC '0') AS sum_capped
  FROM {{ ref('wash_sale_exposure') }}
  WHERE close_strategy != 'PARK'
),
check_strategy AS (
  SELECT 'strategy arm untouched'                              AS check_name,
         '4 rows / 0.0001 capped sh'                           AS expected,
         FORMAT('%d rows / %t capped sh', n_rows, sum_capped)  AS actual
  FROM strategy_arm
  WHERE n_rows != 4 OR sum_capped != NUMERIC '0.0001'
)
SELECT * FROM check_own_basis
UNION ALL
SELECT * FROM check_starvation
UNION ALL
SELECT * FROM check_strategy

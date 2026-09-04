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
--     same sale's other legs' basis lots were counted as external replacements — manufacturing a
--     wash sale out of an ordinary full liquidation. 13 of the 14 lots listed against the 2026-09-02
--     sale were that sale's own basis. Correct pre-rebuy exposure is ZERO.
--   * ALLOCATION STARVATION. The first cut allocated each lot against a running sum of FULL
--     close_shares, so a lot was booked consumed by an earlier close that had already been satisfied
--     by other lots. The 2026-07-27 group read $51.36 against a correct $77.18 with 26.7739 shares of
--     supply against 13.4048 of demand. Under-reporting a wash sale is the UNSAFE direction.
--
-- BOTH ROWS EXPIRE BY DESIGN. The 09-02 expectation flips the moment the staged 2026-09-04 VOO rebuy
-- fills — that purchase IS a genuine replacement within 30 days, and the figure becomes ~$107.73.
-- When that happens, RE-PIN the expected value here to the newly measured one; do NOT delete the
-- check. The 07-27 expectation is historical and should not move.

WITH expectations AS (
  SELECT DATE '2026-09-02' AS close_date, 'VOO' AS ticker, NUMERIC '0'     AS expected_disallowed
  UNION ALL
  SELECT DATE '2026-07-27',               'VOO',            NUMERIC '77.18'
  UNION ALL
  SELECT DATE '2026-06-29',               'HCA',            NUMERIC '0'
),
actual AS (
  SELECT close_date, ticker, ROUND(SUM(estimated_disallowed_loss), 2) AS disallowed
  FROM {{ source('state', 'wash_sale_exposure') }}
  GROUP BY close_date, ticker
)
SELECT e.close_date, e.ticker, e.expected_disallowed, a.disallowed
FROM expectations e
LEFT JOIN actual a USING (close_date, ticker)
WHERE COALESCE(a.disallowed, NUMERIC '0') != e.expected_disallowed

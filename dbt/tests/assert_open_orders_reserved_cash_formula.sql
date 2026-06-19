-- Singular test (passes when ZERO rows): for BUY staged orders, reserved_cash must equal the
-- documented formula ROUND(qty*limit_price + 0.35, 2).
--
-- Rationale (bigquery/01_schema.sql state.open_orders): the +0.35 is the commission pad so a
-- staged BUY reserves slightly MORE than notional, never less — protecting §13 free_cash. If the
-- view's CASE expression ever drifts from this formula, a sweep could under-reserve and de-fund a
-- staged entry (the 2026-06-08 MDT class of bug). Only BUYs reserve cash; SELLs reserve 0 and are
-- excluded. Rows with NULL qty/limit_price are excluded (they can't form the comparison and would
-- surface as a separate not_null concern, not a formula drift).

SELECT item_key, qty, limit_price, reserved_cash,
       ROUND(qty * limit_price + 0.35, 2) AS expected_reserved_cash
FROM {{ ref('open_orders') }}
WHERE side = 'BUY'
  AND qty IS NOT NULL
  AND limit_price IS NOT NULL
  AND reserved_cash <> ROUND(qty * limit_price + 0.35, 2)

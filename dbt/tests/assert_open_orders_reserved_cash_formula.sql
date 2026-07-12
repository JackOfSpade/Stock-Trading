-- Singular test (passes when ZERO rows): for BUY staged orders, reserved_cash must equal the
-- documented formula ROUND(qty*limit_price*multiplier + 0.35, 2), where multiplier is 100 for an
-- OCC-format option ticker and 1 otherwise.
--
-- Rationale (bigquery/01_schema.sql state.open_orders): the +0.35 is the commission pad so a
-- staged BUY reserves slightly MORE than notional, never less — protecting §13 free_cash. The x100
-- options multiplier (adversarial self-audit fix, rev 2026-07-11) reflects that options stage in
-- CONTRACTS with a per-share-premium limit_price, so a debit fill actually consumes
-- premium*100*contracts — omitting it under-reserved a pending Strategy C options entry by ~100x. If
-- the view's CASE expression ever drifts from this formula, a sweep could under-reserve and de-fund a
-- staged entry (the 2026-06-08 MDT class of bug). Only BUYs reserve cash; SELLs reserve 0 and are
-- excluded. Rows with NULL qty/limit_price are excluded (they can't form the comparison and would
-- surface as a separate not_null concern, not a formula drift).

SELECT item_key, qty, limit_price, reserved_cash,
       ROUND(qty * limit_price
             * IF(REGEXP_CONTAINS(ticker, r'^[A-Z]{1,6} *[0-9]{6}[CP][0-9]{8}$'), 100, 1)
             + 0.35, 2) AS expected_reserved_cash
FROM {{ ref('open_orders') }}
WHERE side = 'BUY'
  AND qty IS NOT NULL
  AND limit_price IS NOT NULL
  AND reserved_cash <> ROUND(qty * limit_price
             * IF(REGEXP_CONTAINS(ticker, r'^[A-Z]{1,6} *[0-9]{6}[CP][0-9]{8}$'), 100, 1)
             + 0.35, 2)

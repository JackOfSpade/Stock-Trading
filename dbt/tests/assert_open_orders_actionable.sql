-- Singular test (passes when ZERO rows): every pending staged order is well-formed enough to
-- become a real, confirmable order — a valid side (BUY/SELL) and a positive quantity. A malformed
-- registry row can never be crafted/confirmed yet still occupies the slot and (for a BUY) reserves
-- cash, so it silently breaks the order-intent invariant (pending staged order ⇔ exactly one live
-- confirm event). limit_price/instruction_id are intentionally NOT required here: MARKET orders
-- carry no limit, and options/other non-craftable orders carry a manual block with no instruction_id.
SELECT item_key, ticker, side, qty
FROM {{ ref('open_orders') }}
WHERE side NOT IN ('BUY', 'SELL') OR qty IS NULL OR qty <= 0

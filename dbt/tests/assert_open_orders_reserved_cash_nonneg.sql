-- Singular test (passes when ZERO rows): reserved_cash must be >= 0 for every staged order.
--
-- Rationale (bigquery/01_schema.sql state.open_orders): reserved_cash is the cash a still-
-- pending BUY consumes if it fills (resting SELL reserves nothing). §13.E free_cash subtracts
-- SUM(reserved_cash) so a sweep can never de-fund a staged entry — the exact failure that
-- silently de-funded the 2026-06-08 MDT entry. A negative reservation would *add* free cash and
-- re-open that hole, so any negative reserved_cash is a hard error.

SELECT item_key, side, qty, limit_price, reserved_cash
FROM {{ ref('open_orders') }}
WHERE reserved_cash < 0

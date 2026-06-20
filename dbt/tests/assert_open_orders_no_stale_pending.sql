-- Singular test (passes when ZERO rows): no ORDER_STAGED row stays 'pending' past its
-- entry-window close. state.open_orders already filters to status='pending'; a pending row whose
-- entry_window_close is in the past is an ORPHAN — the D2/D3 persist-and-wait sweep must either
-- re-craft it (window still open) or set it terminal (expired/filled). A stale pending row keeps
-- cash reserved (§13.E reserved_cash) and shadows the confirm-order slot, which is exactly the
-- order-intent invariant the 2026-06-08 MDT near-miss motivated (every pending staged order must
-- map to a live, current confirm event). entry_window_close NULL = no deadline (a resting exit) —
-- exempt. "today" is the America/Denver trading day (state.trading_day_today), never CURRENT_DATE.
SELECT o.item_key, o.ticker, o.side, o.entry_window_close, t.today
FROM {{ ref('open_orders') }} o
CROSS JOIN {{ ref('trading_day_today') }} t
WHERE o.entry_window_close IS NOT NULL
  AND o.entry_window_close < t.today

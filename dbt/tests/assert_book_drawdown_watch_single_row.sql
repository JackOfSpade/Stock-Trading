-- Singular test (passes when ZERO rows): state.book_drawdown_watch must return EXACTLY ONE row.
-- Added 2026-07-04 (audit finding, HIGH): the model is deliberately self-bootstrapping via ARRAY_AGG
-- aggregates (not a QUALIFY-filtered row) specifically so it can never silently vanish and break the
-- state.trading_enabled join it feeds.

SELECT COUNT(*) AS n
FROM {{ ref('book_drawdown_watch') }}
HAVING COUNT(*) <> 1

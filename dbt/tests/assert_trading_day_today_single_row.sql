-- Singular test (passes when ZERO rows): state.trading_day_today must return EXACTLY ONE row.
--
-- Rationale (bigquery/09_market_calendar.sql): this is the single authoritative "today / last /
-- next trading day" source; state.freshness joins to its single row. More than one row (a calendar
-- duplicate) or zero rows would corrupt last_trading_day and the whole freshness chain.

SELECT COUNT(*) AS n
FROM {{ ref('trading_day_today') }}
HAVING COUNT(*) <> 1

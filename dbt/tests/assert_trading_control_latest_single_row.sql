-- Singular test (passes when ZERO rows): state.trading_control_latest must return EXACTLY ONE row.
-- Added 2026-07-04 (audit finding, HIGH): ops.trading_control is seeded exactly once and is never
-- expected to be empty; a 0-or->1-row result here would make sp_assert_trading_enabled's SELECT INTO
-- fail in the wrong direction for a safety gate (see bigquery/23_trading_control.sql's own comment).

SELECT COUNT(*) AS n
FROM {{ ref('trading_control_latest') }}
HAVING COUNT(*) <> 1

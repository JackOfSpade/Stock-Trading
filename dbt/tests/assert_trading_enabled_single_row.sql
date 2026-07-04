-- Singular test (passes when ZERO rows): state.trading_enabled must return EXACTLY ONE row.
-- Added 2026-07-04 (audit finding, HIGH): a CROSS JOIN of ctrl x health x dd that ever fans out to 0
-- or >1 rows would make sp_assert_trading_enabled's SELECT INTO fail in the wrong direction for the
-- pre-order-staging safety gate — see bigquery/23_trading_control.sql.

SELECT COUNT(*) AS n
FROM {{ ref('trading_enabled') }}
HAVING COUNT(*) <> 1

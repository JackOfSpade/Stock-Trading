-- Singular test (passes when ZERO rows): state.trading_enabled_mechanical must return EXACTLY ONE
-- row. Added 2026-07-14 (audit finding, HIGH) — mirrors assert_trading_enabled_single_row.sql; a
-- CROSS JOIN of ctrl x health x al x dd that ever fans out to 0 or >1 rows would make
-- sp_assert_trading_enabled_mechanical's SELECT INTO fail in the wrong direction for the D2a
-- pre-stage safety gate — see bigquery/33_gate_ordering_fix.sql / bigquery/34_alert_lifecycle.sql.

SELECT COUNT(*) AS n
FROM {{ ref('trading_enabled_mechanical') }}
HAVING COUNT(*) <> 1

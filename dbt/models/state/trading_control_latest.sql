-- Parallel-run dbt port of bigquery/23_trading_control.sql:state.trading_control_latest — canonical
-- source is that file until owner cutover. Added 2026-07-04 (audit finding, HIGH severity): the
-- trading-halt gate had ZERO dbt parity/test coverage, unlike almost every other state/analytics
-- object in the project.
SELECT control_id, control_ts, halt_all, mode, reason, set_by
FROM {{ source('ops', 'trading_control') }}
QUALIFY ROW_NUMBER() OVER (ORDER BY control_ts DESC) = 1

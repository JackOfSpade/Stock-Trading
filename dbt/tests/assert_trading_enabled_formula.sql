-- Recomputes state.trading_enabled's boolean formula independently from its upstream sources and
-- fails (returns rows) if the materialized dbt model disagrees. Added 2026-07-14 (audit finding,
-- HIGH) — the existing assert_trading_enabled_single_row.sql only checks CARDINALITY, never the
-- actual formula, so a dropped/mis-ANDed gate term (exactly the 2026-07-11 regression where
-- 23_trading_control.sql was re-applied in isolation and clobbered 34_alert_lifecycle.sql's
-- trading_halted exclusion — see bigquery/47_trading_enabled_resync.sql) has zero compensating
-- test coverage on the LIVE view side. This test guards the dbt MIRROR specifically: if the dbt
-- model (dbt/models/state/trading_enabled.sql) itself drifts from its own upstream sources, this
-- fails independently of row-level parity against the live view. Advisory only — dbt test never
-- blocks CI/auto-merge (see .github/workflows/ci.yml's "dbt test" step).
WITH expected AS (
  SELECT
    NOT COALESCE((SELECT ARRAY_AGG(halt_all ORDER BY control_ts DESC LIMIT 1)[SAFE_OFFSET(0)]
                  FROM {{ source('ops', 'trading_control') }}), FALSE)
    AND (SELECT marks_fresh AND engine_fresh FROM {{ ref('freshness') }})
    AND (SELECT is_healthy FROM {{ source('state_external', 'embedding_health') }})
    AND (SELECT COUNTIF(NOT resolved AND severity = 'critical' AND category != 'trading_halted') = 0
         FROM `stock-trading-498512.ops.alerts`)
    AND NOT COALESCE((SELECT LOGICAL_OR(drifted) FROM `stock-trading-498512.state.position_reconciliation`), FALSE)
    AND NOT COALESCE((SELECT drawdown_breach FROM {{ ref('book_drawdown_watch') }}), FALSE)
    AND NOT COALESCE((SELECT snapshot_stale FROM {{ ref('book_drawdown_watch') }}), FALSE) AS v
)
SELECT t.trading_enabled, e.v AS expected
FROM {{ ref('trading_enabled') }} t, expected e
WHERE t.trading_enabled != e.v

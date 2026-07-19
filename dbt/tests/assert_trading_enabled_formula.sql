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
WITH halt_echo_md AS (
  -- missing_dependency alerts that are pure fallout of a same-day, still-open trading halt:
  -- every dep in payload.missing_deps has an OPEN trading_halted alert (source = dep) whose
  -- Denver date equals this alert's payload.run_date. Fail-closed: any parse failure or
  -- unmatched dep keeps the alert blocking, and a NULL alert_id is excluded outright — left
  -- in, it would make the downstream blocking-criticals NOT IN return NULL for every row and
  -- fail the gate OPEN. Delimiter ', ' matches sp_assert_deps' STRING_AGG(d, ', ') and
  -- sp_auto_resolve_alerts Rule 1's SPLIT.
  SELECT a.alert_id
  FROM `stock-trading-498512.ops.alerts` a,
       UNNEST(SPLIT(JSON_VALUE(a.payload, '$.missing_deps'), ', ')) AS dep
  LEFT JOIN `stock-trading-498512.ops.alerts` th
    ON th.category = 'trading_halted'
   AND NOT th.resolved
   AND th.source = dep
   AND DATE(th.alert_ts, 'America/Denver') =
       SAFE.PARSE_DATE('%Y-%m-%d', JSON_VALUE(a.payload, '$.run_date'))
  WHERE a.alert_id IS NOT NULL
    AND NOT a.resolved
    AND a.severity = 'critical'
    AND a.category = 'missing_dependency'
  GROUP BY a.alert_id
  HAVING LOGICAL_AND(th.alert_id IS NOT NULL)
),
expected AS (
  SELECT
    NOT COALESCE((SELECT ARRAY_AGG(halt_all ORDER BY control_ts DESC LIMIT 1)[SAFE_OFFSET(0)]
                  FROM {{ source('ops', 'trading_control') }}), FALSE)
    AND (SELECT marks_fresh AND engine_fresh FROM {{ ref('freshness') }})
    AND (SELECT is_healthy FROM {{ source('state_external', 'embedding_health') }})
    AND (SELECT COUNTIF(NOT resolved AND severity = 'critical' AND category NOT IN ('trading_halted', 'staleness')
                 AND alert_id NOT IN (SELECT alert_id FROM halt_echo_md)) = 0
         FROM `stock-trading-498512.ops.alerts`)
    AND NOT COALESCE((SELECT LOGICAL_OR(drifted) FROM `stock-trading-498512.state.position_reconciliation`), FALSE)
    AND NOT COALESCE((SELECT breach_hard FROM {{ ref('book_drawdown_watch') }}), FALSE)
    AND NOT COALESCE((SELECT snapshot_stale FROM {{ ref('book_drawdown_watch') }}), FALSE) AS v
)
SELECT t.trading_enabled, e.v AS expected
FROM {{ ref('trading_enabled') }} t, expected e
WHERE t.trading_enabled != e.v

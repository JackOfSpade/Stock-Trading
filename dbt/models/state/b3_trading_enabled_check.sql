-- Parallel-run dbt port of bigquery/176_decouple_embedding_health_from_trading_gate.sql:state.b3_trading_enabled_check — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
-- DEDUPLICATED 2026-08-31 (code-quality pass, dbt#2): halt_echo_md/halt_echo_mr now come from the
-- shared dbt/macros/halt_echo.sql macro instead of a hand-copied CTE pair with the same LOGIC as
-- trading_enabled.sql / trading_enabled_mechanical.sql. CORRECTION (same pass): this file's pre-dedup
-- copy of the pair carried ZERO inline comments (`git show HEAD:dbt/models/state/
-- b3_trading_enabled_check.sql`), while the other two carried the macro's ~10-line rationale block —
-- so the three were never byte-identical, and this file's compiled output GAINS those ~10 comment
-- lines now (verified with `dbt compile --target ci`); the executable SQL is unchanged.
WITH ctrl AS (
  SELECT ARRAY_AGG(STRUCT(halt_all) ORDER BY control_ts DESC LIMIT 1)[SAFE_OFFSET(0)] AS latest
  FROM {{ source('ops', 'trading_control') }}
),
f AS (SELECT marks_fresh, engine_fresh FROM {{ ref('freshness') }}),
{{ halt_echo() }}
al AS (
  SELECT COUNTIF(NOT resolved AND severity = 'critical'
    AND category NOT IN ('trading_halted', 'staleness')
    AND alert_id NOT IN (SELECT alert_id FROM halt_echo_md)
    AND alert_id NOT IN (SELECT alert_id FROM halt_echo_mr)) AS blocking_criticals
  FROM {{ source('ops', 'alerts') }}
),
pr AS (SELECT COALESCE(LOGICAL_OR(drifted), FALSE) AS drift FROM {{ ref('position_reconciliation') }}),
dd AS (SELECT breach_hard, snapshot_stale FROM {{ ref('book_drawdown_watch') }}),
expected AS (
  SELECT
    NOT COALESCE(ctrl.latest.halt_all, FALSE)
    AND COALESCE(f.marks_fresh, FALSE)
    AND COALESCE(f.engine_fresh, FALSE)
    AND al.blocking_criticals = 0
    AND NOT pr.drift
    AND NOT COALESCE(dd.breach_hard, FALSE)
    AND NOT COALESCE(dd.snapshot_stale, FALSE) AS v
  FROM ctrl, f, al, pr, dd
)
SELECT
  t.trading_enabled AS live_value,
  e.v AS expected_value,
  (t.trading_enabled IS DISTINCT FROM e.v) AS drift,
  CURRENT_TIMESTAMP() AS checked_at
FROM {{ ref('trading_enabled') }} t, expected e

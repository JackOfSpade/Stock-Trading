-- Parallel-run dbt port of bigquery/23_trading_control.sql:state.trading_enabled — canonical source
-- is that file until owner cutover. Added 2026-07-04 (audit finding, HIGH severity) — see
-- trading_control_latest.sql for why. The machine-readable gate: sp_assert_trading_enabled reads this
-- before every order-staging step.
WITH ctrl AS (
  SELECT ARRAY_AGG(STRUCT(halt_all, reason, mode) ORDER BY control_ts DESC LIMIT 1)[SAFE_OFFSET(0)] AS latest
  FROM {{ source('ops', 'trading_control') }}
),
health AS (SELECT all_green FROM {{ ref('system_health') }}),
dd AS (SELECT drawdown_breach, drawdown_from_peak FROM {{ ref('book_drawdown_watch') }})
SELECT
  NOT COALESCE(ctrl.latest.halt_all, FALSE)
  AND COALESCE(health.all_green, FALSE)
  AND NOT COALESCE(dd.drawdown_breach, FALSE) AS trading_enabled,
  CASE
    WHEN COALESCE(ctrl.latest.halt_all, FALSE) THEN
      FORMAT('halt_all (mode=%s): %s', COALESCE(ctrl.latest.mode, '?'), COALESCE(ctrl.latest.reason, 'no reason logged'))
    WHEN NOT COALESCE(health.all_green, FALSE) THEN
      'state.system_health.all_green = FALSE (freshness / open critical alert / embedding / firing kill-flag issue)'
    WHEN COALESCE(dd.drawdown_breach, FALSE) THEN
      FORMAT('book NAV drawdown %.2f%% from trailing peak exceeds the -15%% circuit-breaker threshold', dd.drawdown_from_peak * 100)
    ELSE NULL
  END AS halt_reason
FROM ctrl, health, dd

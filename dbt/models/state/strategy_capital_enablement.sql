-- Parallel-run dbt port of bigquery/98_regime_capital_enablement.sql:state.strategy_capital_enablement — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH td AS (
  SELECT today FROM {{ ref('trading_day_today') }}
),
qualifying AS (
  SELECT re.key AS strategy_code, re.value, re.event_ts
  FROM {{ source('events', 'regime_events') }} re
  CROSS JOIN td
  WHERE re.scope = 'STRATEGY_ACTIVATION'
    AND DATE(re.event_ts, 'America/Denver') < td.today
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY re.key
    ORDER BY re.as_of_date DESC, re.event_ts DESC, re.event_id DESC
  ) = 1
)
SELECT
  r.strategy_code,
  q.value                                                      AS latest_activation_value,
  q.event_ts                                                   AS latest_activation_ts,
  COALESCE(UPPER(q.value) LIKE '%DO-NOT-ACTIVATE%', FALSE)     AS capital_disabled,
  NOT COALESCE(UPPER(q.value) LIKE '%DO-NOT-ACTIVATE%', FALSE) AS capital_enabled
FROM {{ source('state_external', 'strategy_roster') }} r
LEFT JOIN qualifying q ON q.strategy_code = r.strategy_code
WHERE r.is_active

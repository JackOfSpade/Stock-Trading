-- Parallel-run dbt port of bigquery/126_dust_operational_hardening.sql:state.strategy_probe_progress — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH probe AS (
  SELECT strategy_code, immutable_since
  FROM {{ source('state_external', 'strategy_roster') }}
  WHERE current_state = 'PROBE'
),
trades AS (
  SELECT strategy AS strategy_code, closed_trades
  FROM {{ source('perf', 'strategy_daily') }}
  QUALIFY ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY as_of_date DESC) = 1
),
openpos AS (
  SELECT strategy AS strategy_code, COUNT(*) AS n_open
  FROM {{ ref('position_lifecycle') }}
  WHERE exit_date IS NULL AND NOT COALESCE(is_dust, FALSE)
  GROUP BY 1
)
SELECT
  p.strategy_code,
  DATE_DIFF(CURRENT_DATE('America/Denver'), DATE(p.immutable_since, 'America/Denver'), DAY) AS probe_days,
  COALESCE(fg.funding_gap_dollars, 0) AS funding_gap_dollars,
  COALESCE(t.closed_trades, 0) AS closed_trades,
  COALESCE(o.n_open, 0) AS n_open_positions,
  (DATE_DIFF(CURRENT_DATE('America/Denver'), DATE(p.immutable_since, 'America/Denver'), DAY) >= 400
   AND COALESCE(fg.funding_gap_dollars, 0) = 0
   AND COALESCE(t.closed_trades, 0) = 0
   AND COALESCE(o.n_open, 0) = 0
   AND NOT EXISTS (
     SELECT 1
     FROM {{ source('ops', 'roster_change_log') }} cl
     WHERE cl.strategy_code = p.strategy_code
       AND cl.to_state = 'RETIREMENT_PROPOSED'
       AND cl.change_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 90 DAY)
   )) AS stuck
FROM probe p
LEFT JOIN {{ ref('strategy_probe_funding_gap') }} fg USING (strategy_code)
LEFT JOIN trades t USING (strategy_code)
LEFT JOIN openpos o USING (strategy_code)

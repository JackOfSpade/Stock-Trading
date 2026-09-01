-- Parallel-run dbt port of bigquery/155_snapshot_and_option_anomaly_d2a_gate.sql:state.option_mark_anomalies — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH option_positions AS (
  SELECT l.strategy, l.position_key, l.ticker, l.entry_date, l.exit_date
  FROM {{ ref('position_lifecycle') }} l
  WHERE l.strategy IS NOT NULL
    AND `stock-trading-498512.analytics.fn_is_occ_option_symbol`(l.ticker)
),
-- CALENDAR FIX (bigquery/154, 2026-08-08): sourced from state.market_calendar's is_trading_day flag,
-- a physical fact about NYSE trading days, instead of a D2a-cadence-dependent proxy table (kept).
-- SAME-DAY GUARD ADDED (bigquery/155, 2026-08-08): TODAY is only a candidate day once D2a has actually
-- completed a run covering it — otherwise every open option position reads as an anomaly from
-- 00:00 MT until D2a's ~16:40 MT write, every single trading day. A day strictly in the past remains an
-- unconditional candidate (unchanged from 154), which is exactly what lets a real Friday gap (D2a's
-- Sun-Thu-only cadence, ops/cadence.yaml) keep showing up once Friday is over — this guard narrows the
-- SAME-DAY false-positive window only, it does not restore the Friday blindness 154 fixed.
trading_days AS (
  SELECT cal_date AS mark_date
  FROM {{ ref('market_calendar') }}
  WHERE is_trading_day
    AND cal_date <= CURRENT_DATE('America/Denver')
    AND (
      cal_date < CURRENT_DATE('America/Denver')
      OR EXISTS (
        SELECT 1 FROM {{ source('ops', 'run_log') }}
        WHERE routine = 'D2a' AND status = 'completed' AND run_date >= cal_date
      )
    )
),
expected AS (
  SELECT p.strategy, p.position_key, p.ticker, td.mark_date
  FROM option_positions p
  JOIN trading_days td
    ON td.mark_date >= p.entry_date
   AND (p.exit_date IS NULL OR td.mark_date <= p.exit_date)
)
SELECT e.strategy, e.position_key, e.ticker AS occ_symbol, e.mark_date
FROM expected e
LEFT JOIN {{ ref('option_marks_curated') }} om
  ON om.occ_symbol = e.ticker AND om.mark_date = e.mark_date
WHERE om.occ_symbol IS NULL

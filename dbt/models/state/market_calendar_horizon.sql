-- Parallel-run dbt port of bigquery/18_stack_review_fixes.sql:state.market_calendar_horizon — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH h AS (
  SELECT MAX(cal_date) AS calendar_through
  FROM {{ ref('market_calendar') }}
),
td AS (SELECT today FROM {{ ref('trading_day_today') }})
SELECT
  h.calendar_through,
  td.today,
  DATE_DIFF(h.calendar_through, td.today, DAY) AS days_of_runway,
  -- warn well below the ~120-day auto-extend trigger, so this only fires once W5's FMP extend has
  -- demonstrably failed to keep ahead (not on a single missed extend).
  COALESCE(DATE_DIFF(h.calendar_through, td.today, DAY) < 100, TRUE) AS runway_low,
  CURRENT_TIMESTAMP() AS checked_at
FROM h, td

-- Parallel-run dbt port of bigquery/153_account_snapshot_gap_watch.sql:state.account_snapshot_gap — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH snaps AS (
  SELECT snapshot_date, nav
  FROM {{ source('ops', 'account_snapshot') }}
  QUALIFY ROW_NUMBER() OVER (PARTITION BY snapshot_date ORDER BY ingest_ts DESC) = 1
),
bounds AS (
  SELECT MIN(snapshot_date) AS min_snapshot_date, MAX(snapshot_date) AS max_snapshot_date
  FROM snaps
),
-- Bounded scan: only trading days STRICTLY WITHIN the window ops.account_snapshot already claims to
-- cover (its own MIN..MAX). state.market_calendar spans 2023-01-01..2030-12-31, but this WHERE keeps
-- the join to a handful of rows (the trailing history the book has been live for), not the full range —
-- and a day before the first snapshot or after the most recent one is never a "gap" by construction, it
-- is simply outside the book's history yet.
trading_days AS (
  SELECT mc.cal_date
  FROM {{ ref('market_calendar') }} mc, bounds b
  WHERE mc.is_trading_day
    AND mc.cal_date >= b.min_snapshot_date
    AND mc.cal_date <= b.max_snapshot_date
),
-- LEFT JOIN onto the (small) snaps set: every trading day in the bounded window, with nav = NULL on a
-- gap day.
timeline AS (
  SELECT td.cal_date, s.nav
  FROM trading_days td
  LEFT JOIN snaps s ON s.snapshot_date = td.cal_date
),
-- Surrounding NAV context via IGNORE NULLS navigation functions, NOT a correlated subquery: an
-- ORDER-BY/LIMIT-1 correlated subquery against `snaps` (the first version of this view, caught by this
-- file's own dry-run/ad-hoc verification before it ever reached BigQuery) is rejected outright —
-- "Correlated subqueries that reference other tables are not supported unless they can be
-- de-correlated" — because BigQuery cannot rewrite an ORDER BY + LIMIT correlated subquery into a JOIN.
-- LAST_VALUE/FIRST_VALUE ... IGNORE NULLS over an ORDER BY cal_date window has no such restriction and
-- reads only the small per-window row set already materialized by `timeline` above.
annotated AS (
  SELECT
    cal_date,
    nav,
    LAST_VALUE(IF(nav IS NOT NULL, cal_date, NULL) IGNORE NULLS) OVER (
      ORDER BY cal_date ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS prior_snapshot_date,
    LAST_VALUE(IF(nav IS NOT NULL, nav, NULL) IGNORE NULLS) OVER (
      ORDER BY cal_date ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS prior_nav,
    FIRST_VALUE(IF(nav IS NOT NULL, cal_date, NULL) IGNORE NULLS) OVER (
      ORDER BY cal_date ROWS BETWEEN 1 FOLLOWING AND UNBOUNDED FOLLOWING) AS next_snapshot_date,
    FIRST_VALUE(IF(nav IS NOT NULL, nav, NULL) IGNORE NULLS) OVER (
      ORDER BY cal_date ROWS BETWEEN 1 FOLLOWING AND UNBOUNDED FOLLOWING) AS next_nav
  FROM timeline
)
SELECT
  cal_date AS gap_date,
  prior_snapshot_date,
  prior_nav,
  next_snapshot_date,
  next_nav,
  CURRENT_TIMESTAMP() AS checked_at
FROM annotated
WHERE nav IS NULL

-- Parallel-run dbt port of bigquery/23_trading_control.sql:state.book_drawdown_watch — canonical
-- source is that file until owner cutover. Added 2026-07-04 (audit finding, HIGH severity) — see
-- trading_control_latest.sql for why.
WITH snaps AS (
  SELECT snapshot_date, nav
  FROM {{ source('ops', 'account_snapshot') }}
  QUALIFY ROW_NUMBER() OVER (PARTITION BY snapshot_date ORDER BY ingest_ts DESC) = 1
),
peaked AS (
  SELECT snapshot_date, nav,
    MAX(nav) OVER (ORDER BY snapshot_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS peak_nav
  FROM snaps
),
agg AS (
  SELECT COUNT(*) AS n_snapshots,
    ARRAY_AGG(STRUCT(snapshot_date, nav, peak_nav) ORDER BY snapshot_date DESC LIMIT 1)[SAFE_OFFSET(0)] AS latest
  FROM peaked
)
SELECT
  agg.latest.snapshot_date AS as_of_date,
  agg.latest.nav AS current_nav,
  agg.latest.peak_nav AS peak_nav,
  SAFE_DIVIDE(agg.latest.nav, agg.latest.peak_nav) - 1 AS drawdown_from_peak,
  agg.n_snapshots,
  (agg.n_snapshots >= 5 AND SAFE_DIVIDE(agg.latest.nav, agg.latest.peak_nav) - 1 <= -0.15) AS drawdown_breach
FROM agg

-- Parallel-run dbt port of bigquery/23_trading_control.sql:state.book_drawdown_watch — canonical
-- source is that file until owner cutover. Added 2026-07-04 (audit finding, HIGH severity) — see
-- trading_control_latest.sql for why.
-- snapshot_stale added (rev 2026-07-11, ITEM 16 self-improvement audit; adversarial self-audit fix —
-- this column was missing from the dbt mirror entirely, which made scripts/dbt_parity.py's row-level
-- compare error out on the column and get silently reported as "skipped" rather than "diffs", masking
-- the drift class this parity check exists to catch. See bigquery/23_trading_control.sql for the
-- live definition this mirrors.).
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
),
ltd AS (SELECT last_trading_day FROM {{ ref('trading_day_today') }})
SELECT
  agg.latest.snapshot_date AS as_of_date,
  agg.latest.nav AS current_nav,
  agg.latest.peak_nav AS peak_nav,
  SAFE_DIVIDE(agg.latest.nav, agg.latest.peak_nav) - 1 AS drawdown_from_peak,
  agg.n_snapshots,
  (agg.n_snapshots > 0 AND agg.latest.snapshot_date < ltd.last_trading_day) AS snapshot_stale,
  (agg.n_snapshots >= 5 AND SAFE_DIVIDE(agg.latest.nav, agg.latest.peak_nav) - 1 <= -0.15) AS drawdown_breach
FROM agg CROSS JOIN ltd

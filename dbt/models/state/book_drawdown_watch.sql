-- Parallel-run dbt port of state.book_drawdown_watch — canonical source is
-- bigquery/78_book_drawdown_rebase_and_staleness_gate.sql until owner cutover (was 23; rebased
-- 2026-07-17 whole-system audit finding C1). Mirrors the flow-adjusted, two-tier breaker: drawdown
-- measured on flow-neutral trading gain (nav - cumulative external flows) so deposits/withdrawals
-- cannot ratchet the peak or fake a breach; breach_soft (-15%) = entries-only, breach_hard (-40%) =
-- gate full-halt. drawdown_breach retained as a backward-compat alias == breach_hard. See the live
-- file for the full rationale. Keep this byte-aligned with 78 or scripts/dbt_parity.py fails closed.
WITH snaps AS (
  SELECT snapshot_date, nav
  FROM {{ source('ops', 'account_snapshot') }}
  QUALIFY ROW_NUMBER() OVER (PARTITION BY snapshot_date ORDER BY ingest_ts DESC) = 1
),
flowed AS (
  SELECT s.snapshot_date, s.nav,
    COALESCE((SELECT SUM(cf.amount) FROM `stock-trading-498512.events.cash_flows` cf
              WHERE cf.flow_date <= s.snapshot_date), 0) AS cum_flows
  FROM snaps s
),
gained AS (
  SELECT snapshot_date, nav, cum_flows, nav - cum_flows AS gain,
    MAX(nav - cum_flows) OVER (ORDER BY snapshot_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS peak_gain
  FROM flowed
),
agg AS (
  SELECT COUNT(*) AS n_snapshots,
    ARRAY_AGG(STRUCT(snapshot_date, nav, cum_flows, gain, peak_gain) ORDER BY snapshot_date DESC LIMIT 1)[SAFE_OFFSET(0)] AS latest
  FROM gained
),
ltd AS (SELECT last_trading_day FROM {{ ref('trading_day_today') }})
SELECT
  agg.latest.snapshot_date AS as_of_date,
  agg.latest.nav AS current_nav,
  agg.latest.peak_gain + agg.latest.cum_flows AS peak_nav,
  agg.latest.cum_flows AS capital_base,
  SAFE_DIVIDE(agg.latest.gain - agg.latest.peak_gain, NULLIF(agg.latest.cum_flows, 0)) AS drawdown_from_peak,
  agg.n_snapshots,
  (agg.n_snapshots > 0 AND agg.latest.snapshot_date < ltd.last_trading_day) AS snapshot_stale,
  (agg.n_snapshots >= 5 AND SAFE_DIVIDE(agg.latest.gain - agg.latest.peak_gain, NULLIF(agg.latest.cum_flows, 0)) <= -0.15) AS breach_soft,
  (agg.n_snapshots >= 5 AND SAFE_DIVIDE(agg.latest.gain - agg.latest.peak_gain, NULLIF(agg.latest.cum_flows, 0)) <= -0.40) AS breach_hard,
  (agg.n_snapshots >= 5 AND SAFE_DIVIDE(agg.latest.gain - agg.latest.peak_gain, NULLIF(agg.latest.cum_flows, 0)) <= -0.40) AS drawdown_breach
FROM agg CROSS JOIN ltd

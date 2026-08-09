-- Parallel-run dbt port of state.book_drawdown_watch — canonical source is
-- bigquery/155_snapshot_and_option_anomaly_d2a_gate.sql (which supersedes bigquery/153, which
-- superseded bigquery/78) until owner cutover (was 23; rebased 2026-07-17 whole-system audit finding
-- C1). Mirrors the flow-adjusted, two-tier breaker: drawdown
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
  -- Third AND-term added by bigquery/155 (2026-08-08): without it the two-term test fires TRUE every
  -- Friday/Saturday from 2026-08-14 onward, because D2a (account_snapshot's only writer) is now
  -- Sun-Thu-only while Friday stays a real trading day — a DESIGNED cadence gap, not a fault. A
  -- genuine D2a outage is still caught: no 'completed' row at all is caught by state.cadence_watch's
  -- missed_run CRITICAL, and a completed-but-silently-empty Step 0b still makes this EXISTS TRUE.
  (agg.n_snapshots > 0
   AND agg.latest.snapshot_date < ltd.last_trading_day
   AND EXISTS (SELECT 1 FROM `stock-trading-498512.ops.run_log`
               WHERE routine = 'D2a' AND status = 'completed'
                 AND run_date >= ltd.last_trading_day)) AS snapshot_stale,
  (agg.n_snapshots >= 5 AND SAFE_DIVIDE(agg.latest.gain - agg.latest.peak_gain, NULLIF(agg.latest.cum_flows, 0)) <= -0.15) AS breach_soft,
  (agg.n_snapshots >= 5 AND SAFE_DIVIDE(agg.latest.gain - agg.latest.peak_gain, NULLIF(agg.latest.cum_flows, 0)) <= -0.40) AS breach_hard,
  (agg.n_snapshots >= 5 AND SAFE_DIVIDE(agg.latest.gain - agg.latest.peak_gain, NULLIF(agg.latest.cum_flows, 0)) <= -0.40) AS drawdown_breach,
  -- account_snapshot_gap watch, bigquery/153 (2026-08-08): count of trading days between the first and
  -- last ops.account_snapshot row that never got a snapshot. OBSERVABILITY ONLY: does NOT feed
  -- breach_soft/breach_hard/snapshot_stale/drawdown_breach and does NOT gate state.trading_enabled.
  -- Omitting this column is what made dbt-parity SKIP this model instead of comparing it (BigQuery's
  -- "Name X not found inside Y" phrasing missed scripts/dbt_parity.py's SCHEMA_DRIFT_MARKERS list).
  (SELECT COUNT(*) FROM `stock-trading-498512.state.account_snapshot_gap`) AS peak_window_gap_days
FROM agg CROSS JOIN ltd

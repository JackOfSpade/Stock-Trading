-- ===== 265: state.book_drawdown_watch -- snapshot_stale must not count a PRE-OPEN D2a run =====
-- Project: stock-trading-498512. Apply after 264. ONE statement: CREATE OR REPLACE VIEW state.book_drawdown_watch.
-- SUPERSEDES the definition in bigquery/214_account_fee_recording.sql (chain: 78 -> 153 -> 155 -> 214 -> 265).
-- The view body is 214's, extracted mechanically; the ONLY change is one appended AND-term inside the
-- snapshot_stale EXISTS guard. Every other column, threshold and CTE is byte-identical.
--
-- ===== THE DEFECT (found 2026-10-23, interactive owner session, from alert 38b1edac) =====
-- bigquery/155 added the EXISTS guard so that a day D2a was never scheduled to serve (Friday, under the
-- Sun-Thu cadence) is not read as a stale snapshot: snapshot_stale needs a COMPLETED D2a with
-- run_date >= last_trading_day. The PRE-OPEN SLOT LIMB (Claude_Task_Plan.md D2a, added 2026-10-11, AFTER
-- 155) breaks that proxy. A catch-up D2a that fires before the open is stamped run_date = today by spec,
-- but pins its snapshot to the PRIOR completed session, because today has not closed. So it satisfies
-- the guard while leaving snapshot_date < last_trading_day, and snapshot_stale reads TRUE for a snapshot
-- that is exactly as current as it can be.
--
-- MEASURED 2026-10-23. Completed D2a rows finishing before their own run_date 16:00 ET close: 3 ever
-- (2026-07-11, a Saturday and not a trading day, so harmless; 2026-09-22 and 2026-10-23). On 2026-09-22
-- (a Tuesday) the evening D2a cleared it the same day. On 2026-10-23 (a FRIDAY, which has no evening
-- D2a slot) it holds until the Sunday 22:40 UTC run, about 62 hours.
--
-- CONSEQUENCE. state.trading_enabled was FALSE through that window ANYWAY, because marks_fresh expects
-- the unclosed session, so no order was blocked that would otherwise have staged. The harm is in the
-- ALERT. state.staging_halt_disposition (bigquery/206) term 4 requires NOT snapshot_stale, so the halt
-- was classified as a genuine halt (gate_alert_action raise_critical) instead of the pre-refresh
-- artifact it was (defer_to_craft_site), and D2a raised a CRITICAL trading_halted email for it.
--
-- ===== THE FIX =====
-- The completed D2a row must also have been logged at or after 16:00 America/New_York on
-- last_trading_day: the earliest moment a post-close snapshot of that session can exist. An early-close
-- session (13:00 ET) is still served correctly, since the regular slot fires at 22:40 UTC. A genuine D2a
-- failure is still caught exactly as before: a post-close run that completes without refreshing the
-- snapshot still makes the EXISTS TRUE, and no completed run at all is state.cadence_watch missed_run.
-- This can only make snapshot_stale FALSE in the pre-close window, where marks_fresh holds
-- state.trading_enabled FALSE regardless, so the gate verdict itself does not change.
--
-- MIRROR: dbt/models/state/book_drawdown_watch.sql carries the same term (scripts/dbt_parity.py).
--
-- ===== VERIFICATION (read-only, 2026-10-23 ~18:20 UTC) =====
-- Before: snapshot_stale TRUE (as_of_date 2026-10-22, last_trading_day 2026-10-23), disposition raise_critical.
-- The new guard alone evaluated FALSE at the same instant, so after apply snapshot_stale reads FALSE
-- and state.staging_halt_disposition reads defer_to_craft_site.
CREATE OR REPLACE VIEW `stock-trading-498512.state.book_drawdown_watch` AS
WITH snaps AS (
  SELECT snapshot_date, nav
  FROM `stock-trading-498512.ops.account_snapshot`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY snapshot_date ORDER BY ingest_ts DESC) = 1
),
flowed AS (
  SELECT
    s.snapshot_date,
    s.nav,
    -- cumulative net external flows (deposits +, withdrawals -) up to and including this snapshot.
    -- bigquery/214: source='account_fee' is EXCLUDED. A recurring account/market-data fee is an
    -- EXPENSE of running the book, not an external capital movement, so it must stay inside the
    -- flow-neutral trading gain rather than neutralising itself out of it.
    COALESCE((
      SELECT SUM(cf.amount)
      FROM `stock-trading-498512.events.cash_flows` cf
      WHERE cf.flow_date <= s.snapshot_date
        AND COALESCE(cf.source, '') <> 'account_fee'
    ), 0) AS cum_flows
  FROM snaps s
),
gained AS (
  SELECT
    snapshot_date, nav, cum_flows,
    nav - cum_flows AS gain,
    MAX(nav - cum_flows) OVER (ORDER BY snapshot_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS peak_gain
  FROM flowed
),
agg AS (
  SELECT COUNT(*) AS n_snapshots,
    ARRAY_AGG(STRUCT(snapshot_date, nav, cum_flows, gain, peak_gain) ORDER BY snapshot_date DESC LIMIT 1)[SAFE_OFFSET(0)] AS latest
  FROM gained
),
ltd AS (SELECT last_trading_day FROM `stock-trading-498512.state.trading_day_today`)
SELECT
  agg.latest.snapshot_date AS as_of_date,
  agg.latest.nav AS current_nav,
  agg.latest.peak_gain + agg.latest.cum_flows AS peak_nav,
  agg.latest.cum_flows AS capital_base,
  SAFE_DIVIDE(agg.latest.gain - agg.latest.peak_gain, NULLIF(agg.latest.cum_flows, 0)) AS drawdown_from_peak,
  agg.n_snapshots,
  (agg.n_snapshots > 0
   AND agg.latest.snapshot_date < ltd.last_trading_day
   AND EXISTS (SELECT 1 FROM `stock-trading-498512.ops.run_log`
               WHERE routine = 'D2a' AND status = 'completed'
                 AND run_date >= ltd.last_trading_day
                 -- bigquery/265: the run must have FINISHED after last_trading_day's 16:00 ET close.
                 -- A PRE-OPEN SLOT LIMB run is stamped run_date = today but writes the PRIOR session's
                 -- snapshot by spec, so it never had the opportunity this guard is testing for.
                 AND log_ts >= TIMESTAMP(DATETIME(ltd.last_trading_day, TIME '16:00:00'), 'America/New_York'))) AS snapshot_stale,
  (agg.n_snapshots >= 5 AND SAFE_DIVIDE(agg.latest.gain - agg.latest.peak_gain, NULLIF(agg.latest.cum_flows, 0)) <= -0.15) AS breach_soft,
  (agg.n_snapshots >= 5 AND SAFE_DIVIDE(agg.latest.gain - agg.latest.peak_gain, NULLIF(agg.latest.cum_flows, 0)) <= -0.40) AS breach_hard,
  (agg.n_snapshots >= 5 AND SAFE_DIVIDE(agg.latest.gain - agg.latest.peak_gain, NULLIF(agg.latest.cum_flows, 0)) <= -0.40) AS drawdown_breach,
  (SELECT COUNT(*) FROM `stock-trading-498512.state.account_snapshot_gap`) AS peak_window_gap_days
FROM agg CROSS JOIN ltd;

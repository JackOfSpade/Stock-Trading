-- 155_snapshot_and_option_anomaly_d2a_gate.sql (2026-08-08)
-- Project: stock-trading-498512. Apply after 09_market_calendar.sql (state.market_calendar,
-- state.trading_day_today), 01_schema.sql (ops.run_log), 153_account_snapshot_gap_watch.sql
-- (state.book_drawdown_watch), 154_option_mark_anomalies_calendar_fix.sql (state.option_mark_anomalies).
--
-- SUPERSEDES state.book_drawdown_watch from bigquery/153_account_snapshot_gap_watch.sql (see the
-- SUPERSEDED marker left there pointing here, same commit) and state.option_mark_anomalies from
-- bigquery/154_option_mark_anomalies_calendar_fix.sql (same). This is the current single source of
-- truth for both objects. Keep 153/154 for DR-rebuild apply-in-order history; do not re-apply their
-- definitions of these two objects in isolation. 153's other two statements (state.account_snapshot_gap,
-- ops.sp_sq_cadence_check) are UNTOUCHED and remain canonical there.
--
-- ============================ THE BUG (confirmed live, 2026-08-08) ================================
-- The 2026-08-08 daily-tier Fri/Sat consolidation (ops/cadence.yaml) moved D2a to a Sunday-Thursday-only
-- cron (`40 22 * * 0,1,2,3,4`) — Friday is no longer a day D2a runs at all, even though Friday remains a
-- real NYSE trading day (state.market_calendar.is_trading_day = TRUE). D2a Step 0b is
-- ops.account_snapshot's ONLY writer, one row per snapshot_date, no loop, no backfill (bigquery/153's own
-- header). Two downstream checks derived a "has today's data arrived yet" test from that fact, and both
-- read a DESIGNED Friday/Saturday gap as though it were a genuine same-day fault:
--
--   (1) state.book_drawdown_watch.snapshot_stale (bigquery/153:188, carried forward unchanged from
--       bigquery/78) —
--           (agg.n_snapshots > 0 AND agg.latest.snapshot_date < ltd.last_trading_day)
--       From Friday 00:00 MT (last_trading_day flips to Friday at midnight, snapshot still Thursday-dated)
--       until D2a's Sunday ~16:40 MT run, this is TRUE. It ANDs directly into state.trading_enabled
--       (bigquery/107_halt_echo_missed_run_gate.sql, confirmed the current effective owner below) via
--       `NOT COALESCE(dd.snapshot_stale, FALSE)` — so from 2026-08-14 onward this halts ALL order staging
--       for ~64 hours every single week, with halt_reason misleadingly reading "ops.account_snapshot not
--       refreshed for the current trading day" when nothing is actually broken. Not cosmetic: monthly/
--       quarterly/annual routines fire on fixed calendar days and gate on trading_enabled, and 2026-10-02
--       (quarterly tier, day 2 of Oct) is a Friday.
--
--   (2) state.option_mark_anomalies (bigquery/154's `trading_days` CTE) —
--           WHERE is_trading_day AND cal_date <= CURRENT_DATE('America/Denver')
--       includes TODAY unconditionally. On any Sun-Thu trading day, D2a doesn't write option marks until
--       ~16:40 MT, so every open option position reads as an anomaly from 00:00-16:40 MT — the OLD
--       (`daily_marks_curated`-sourced) calendar never had this problem, because today's own row only
--       ever appeared in that source AFTER D2a wrote it, so "today" was never a candidate day until it was
--       actually resolvable. 154 fixed the STRUCTURAL blindness to Friday (a real, permanent gap that
--       SHOULD be flagged) but in doing so widened the same-day false-positive window from a few minutes
--       (an unlucky query timed right at the D2a boundary) to most of a day, every day.
--
-- Both bugs are the same shape: "has D2a had the OPPORTUNITY to write this yet" was conflated with "does
-- the row exist yet". The fix anchors both checks on the same predicate — an actual completed D2a run —
-- instead of on elapsed wall-clock or a proxy table's own write cadence.
--
-- ============================ THE FIX ============================
-- (a) state.book_drawdown_watch.snapshot_stale gains a third AND-term: the staleness only counts once
--     D2a has ACTUALLY completed a run covering the current last_trading_day —
--         (agg.n_snapshots > 0
--          AND agg.latest.snapshot_date < ltd.last_trading_day
--          AND EXISTS (SELECT 1 FROM `stock-trading-498512.ops.run_log`
--                      WHERE routine = 'D2a' AND status = 'completed'
--                        AND run_date >= ltd.last_trading_day)) AS snapshot_stale
--     Every other column (as_of_date, current_nav, peak_nav, capital_base, drawdown_from_peak,
--     n_snapshots, breach_soft, breach_hard, drawdown_breach, peak_window_gap_days) and every other
--     threshold is BYTE-IDENTICAL to bigquery/153.
-- (b) state.option_mark_anomalies' `trading_days` CTE keeps 154's market_calendar source (the Friday
--     blindness fix stays — Friday SHOULD keep showing as a real gap once it is genuinely in the past)
--     but no longer treats TODAY as a candidate day until D2a has had its opportunity to write it:
--         AND (cal_date < CURRENT_DATE('America/Denver')
--              OR EXISTS (SELECT 1 FROM `stock-trading-498512.ops.run_log`
--                         WHERE routine = 'D2a' AND status = 'completed' AND run_date >= cal_date))
--     A past trading day is unconditionally a candidate (unchanged from 154 — this is exactly what makes
--     Friday correctly show up as a gap once Friday is over, the behavior 154 exists to add). Only TODAY
--     is additionally gated on D2a's own completion. A safety-net detector does not need same-day
--     resolution (RUNBOOK precedent: missed_run/period_missed are themselves next-day-or-later signals).
--
-- ============================ THIS RELAXES A FAIL-CLOSED TRADING GATE — COMPENSATING CONTROL ==========
-- (a) is a genuine relaxation of state.trading_enabled: a condition that used to halt trading
-- (last_trading_day's snapshot missing) no longer does, for the specific case where D2a was never
-- SCHEDULED to have written it yet. This is safe because a D2a that does not run AT ALL — the actual
-- fault this gate exists to catch — is independently caught: state.cadence_watch.needs_attention fires
-- CRITICAL 'missed_run' for D2a (monitor_class daily_sun_thu is in bigquery/142's needs_attention
-- schedule IN-list, confirmed live below) once Denver wall-clock passes 21:00 on a day D2a was expected
-- and has not logged 'completed' — and that critical independently blocks trading through
-- blocking_criticals in the SAME view, with no dependency on snapshot_stale at all. This relaxation
-- removes the halt ONLY for the case where D2a was never scheduled to run (Friday/Saturday); it does not
-- weaken detection of an actual D2a outage on a day D2a WAS supposed to run — see WALKTHROUGH, last row,
-- for the case where D2a completes but Step 0b itself silently fails to write a row: still caught STALE.
-- (b) is advisory-only (state.option_mark_anomalies feeds ops.sp_recompute_engine's WARNING-only
-- option_anomaly_count check, per bigquery/154's header) — narrowing its false-positive window is a
-- precision improvement, not a gate change, and does not touch state.trading_enabled at all.
--
-- ============================ WALKTHROUGH (state.book_drawdown_watch.snapshot_stale) ============
-- Denver wall-clock, D2a's actual Sun-Thu 16:40 MT schedule (ops/cadence.yaml):
--   Fri 2026-08-14, any time: last_trading_day=Fri 08-14, latest snapshot=Thu 08-13 (n_snapshots>0,
--     08-13 < 08-14 TRUE), D2a has no 'completed' run with run_date >= 08-14 (D2a never fires Friday)
--     -> EXISTS FALSE -> snapshot_stale = FALSE. NOT stale — dark by design, correctly not halting.
--   Sat 2026-08-15, any time: last_trading_day still Fri 08-14 (Saturday is not a trading day, so
--     trading_day_today does not advance it), same snapshot/EXISTS state as Friday -> FALSE. NOT stale.
--   Sun 2026-08-16, AFTER D2a's ~16:40 MT run: D2a Step 0b stamps snapshot_date =
--     state.trading_day_today.last_trading_day AS OF THAT RUN (task_plan/D2a.md, 2026-08-08 fix — Sunday
--     is not itself a trading day, so last_trading_day at Sunday's run is still Friday) -> latest
--     snapshot_date = Fri 08-14 = last_trading_day -> second AND-term (08-14 < 08-14) is FALSE regardless
--     of EXISTS -> snapshot_stale = FALSE. NOT stale.
--   Mon 2026-08-17, 10:00 MT, BEFORE D2a's 16:40 run: last_trading_day flips to Mon 08-17 at midnight,
--     latest snapshot still Fri 08-14 (08-14 < 08-17 TRUE), D2a has no 'completed' run with
--     run_date >= 08-17 yet (today's run hasn't happened) -> EXISTS FALSE -> snapshot_stale = FALSE. NOT
--     stale — Monday's snapshot is not due until D2a actually runs, same logic as any Sun-Thu morning.
--   Mon 2026-08-17, 17:00 MT, AFTER D2a's run: latest snapshot = Mon 08-17 = last_trading_day -> second
--     AND-term FALSE -> snapshot_stale = FALSE. NOT stale.
--   Tue 2026-08-18, D2a fires and logs 'completed' but Step 0b itself silently fails to write a row
--     (a genuine fault, NOT a schedule gap): last_trading_day=Tue 08-18, latest snapshot still Mon 08-17
--     (08-17 < 08-18 TRUE), D2a DOES have a 'completed' run_log row with run_date=08-18 (>= 08-18) ->
--     EXISTS TRUE -> snapshot_stale = TRUE. STALE — the genuine fault is still caught, because this
--     predicate only excuses a day D2a was never scheduled for, not a day D2a ran and still failed to
--     produce a row. (If D2a instead fails hard enough to never log 'completed' at all, that is the
--     "D2a did not run" case covered by the missed_run compensating control above, not by this term.)
--
-- LIVE-VERIFIED 2026-08-08 (today is Saturday; ad hoc read-only query against live tables, both the OLD
-- and NEW expressions evaluated side by side):
--   as_of_date = 2026-08-07, last_trading_day = 2026-08-07 (both equal — today IS the trading-day-today's
--   own last_trading_day, so the Fri/Sat gap has not opened yet as of this exact run)
--   old_snapshot_stale = FALSE, new_snapshot_stale = FALSE — IDENTICAL. This change is provably a no-op
--   against present live state; the walkthrough above is what proves it matters starting 2026-08-14.
--
-- ============================ VERIFICATION (run after apply; read-only) ============================
-- 1. SELECT * FROM `stock-trading-498512.state.book_drawdown_watch`;
--    -> expect the same 11 columns as bigquery/153, snapshot_stale = FALSE today (2026-08-08), matching
--       the live-verified figures above.
-- 2. SELECT * FROM `stock-trading-498512.state.option_mark_anomalies`;
--    -> expect 0 rows today (2026-08-08 — Strategy C holds no open option position live, same as
--       bigquery/154's own verification).
-- 3. state.trading_enabled / state.trading_enabled_mechanical / state.b3_trading_enabled_check
--    (bigquery/107, UNCHANGED by this file) all read only the named `snapshot_stale` column from
--    state.book_drawdown_watch — never SELECT * — so this redefinition changes their live behavior
--    exactly as intended and nothing else in that gate cluster is touched.

-- ===== state.book_drawdown_watch (SUPERSEDES bigquery/153) =====
-- Byte-for-byte reproduction of bigquery/153's view body (itself byte-for-byte over bigquery/78's,
-- extracted mechanically) with exactly one change: snapshot_stale gains the D2a-opportunity EXISTS
-- guard described above. Every other column, threshold and CTE is unchanged.
-- SUPERSEDED LIVE by bigquery/214_account_fee_recording.sql -- current single source of truth for
-- this object. Kept here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT
-- re-apply this CREATE statement live in isolation. 214 excludes source='account_fee' from the flowed CTE's cum_flows: a recurring account/market-data
-- fee is an EXPENSE, not an external capital movement, and since ops.account_snapshot.nav is
-- connector-sourced it ALREADY reflects the fee -- so without the exclusion, booking fee rows into
-- events.cash_flows would drop cum_flows by the same amount and newly hide fees from the -15%/-40%
-- breaker. Every other line of the view is byte-identical to the definition below.
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
    COALESCE((
      SELECT SUM(cf.amount)
      FROM `stock-trading-498512.events.cash_flows` cf
      WHERE cf.flow_date <= s.snapshot_date
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
  -- flow-adjusted peak, expressed in today's capital terms (peak trading-gain + current deposited
  -- capital) so dashboards keep a NAV-scale "peak" number; equals raw MAX(nav) when flows are constant.
  agg.latest.peak_gain + agg.latest.cum_flows AS peak_nav,
  agg.latest.cum_flows AS capital_base,
  SAFE_DIVIDE(agg.latest.gain - agg.latest.peak_gain, NULLIF(agg.latest.cum_flows, 0)) AS drawdown_from_peak,
  agg.n_snapshots,
  -- CHANGED HERE (bigquery/155, 2026-08-08): the ORIGINAL two-term test
  -- (agg.latest.snapshot_date < ltd.last_trading_day) fires TRUE for every Friday/Saturday from
  -- 2026-08-14 onward, because D2a (account_snapshot's only writer) is now Sun-Thu-only while Friday
  -- stays a real trading day — a DESIGNED cadence gap, not a fault. The new third AND-term requires an
  -- actual completed D2a run covering last_trading_day before treating the gap as stale, so a day D2a
  -- was never scheduled to run no longer halts state.trading_enabled. A genuine D2a outage remains
  -- caught: (i) if D2a never logs 'completed' at all, state.cadence_watch's missed_run CRITICAL
  -- independently blocks trading via blocking_criticals; (ii) if D2a logs 'completed' but Step 0b itself
  -- silently fails to write a row, this EXISTS is still TRUE (D2a DID complete for last_trading_day) and
  -- snapshot_stale still correctly evaluates TRUE. See this file's header WALKTHROUGH for both cases
  -- worked through explicitly, and the live proof that today's (2026-08-08) value is unchanged (FALSE).
  (agg.n_snapshots > 0
   AND agg.latest.snapshot_date < ltd.last_trading_day
   AND EXISTS (SELECT 1 FROM `stock-trading-498512.ops.run_log`
               WHERE routine = 'D2a' AND status = 'completed'
                 AND run_date >= ltd.last_trading_day)) AS snapshot_stale,
  -- soft tier (-15%): entries-only, via state.entry_staging_allowed. NOT a gate term.
  (agg.n_snapshots >= 5 AND SAFE_DIVIDE(agg.latest.gain - agg.latest.peak_gain, NULLIF(agg.latest.cum_flows, 0)) <= -0.15) AS breach_soft,
  -- hard tier (-40%): genuine catastrophe — the gate AND-term (full halt).
  (agg.n_snapshots >= 5 AND SAFE_DIVIDE(agg.latest.gain - agg.latest.peak_gain, NULLIF(agg.latest.cum_flows, 0)) <= -0.40) AS breach_hard,
  -- backward-compat alias for pre-78 consumers (23/33/34/64 DR-apply-order copies): drawdown_breach
  -- now means the HARD tier (the term that still hard-halts the gates). New code should read breach_hard.
  (agg.n_snapshots >= 5 AND SAFE_DIVIDE(agg.latest.gain - agg.latest.peak_gain, NULLIF(agg.latest.cum_flows, 0)) <= -0.40) AS drawdown_breach,
  -- account_snapshot_gap watch, bigquery/153 (2026-08-08): count of trading days between the
  -- first and last ops.account_snapshot row that never got a snapshot (D2a Step 0b writes only
  -- 'today', no loop, no backfill -- see state.account_snapshot_gap). OBSERVABILITY ONLY: does
  -- NOT feed breach_soft/breach_hard/snapshot_stale/drawdown_breach and does NOT gate
  -- state.trading_enabled -- purely a witness that peak_nav/peak_gain above may be understated.
  (SELECT COUNT(*) FROM `stock-trading-498512.state.account_snapshot_gap`) AS peak_window_gap_days
FROM agg CROSS JOIN ltd;

-- ===== state.option_mark_anomalies (SUPERSEDES bigquery/154) =====
-- Byte-for-byte reproduction of bigquery/154's view body with exactly one change: the `trading_days`
-- CTE's WHERE clause gains a D2a-opportunity guard on TODAY specifically (see header (b) above). Past
-- days are unconditionally candidates, unchanged from 154 — Friday still correctly shows up as a real
-- gap once Friday is over. Every other CTE, join and output column is unchanged.
CREATE OR REPLACE VIEW `stock-trading-498512.state.option_mark_anomalies` AS
WITH option_positions AS (
  SELECT l.strategy, l.position_key, l.ticker, l.entry_date, l.exit_date
  FROM `stock-trading-498512.analytics.position_lifecycle` l
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
  FROM `stock-trading-498512.state.market_calendar`
  WHERE is_trading_day
    AND cal_date <= CURRENT_DATE('America/Denver')
    AND (
      cal_date < CURRENT_DATE('America/Denver')
      OR EXISTS (
        SELECT 1 FROM `stock-trading-498512.ops.run_log`
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
LEFT JOIN `stock-trading-498512.state.option_marks_curated` om
  ON om.occ_symbol = e.ticker AND om.mark_date = e.mark_date
WHERE om.occ_symbol IS NULL;

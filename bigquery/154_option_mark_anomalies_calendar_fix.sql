-- 154_option_mark_anomalies_calendar_fix.sql (2026-08-08)
-- Project: stock-trading-498512. Apply after 09_market_calendar.sql (state.market_calendar),
-- 40_options_marks.sql (analytics.fn_is_occ_option_symbol, analytics.position_lifecycle dependency,
-- state.option_marks_curated).
--
-- SUPERSEDES state.option_mark_anomalies from bigquery/40_options_marks.sql (see the SUPERSEDED marker
-- left there pointing here, same commit). This is the current single source of truth for this view.
-- Keep 40 for DR-rebuild apply-in-order history; do not re-apply its definition of this object in
-- isolation. Nothing else in bigquery/40 is touched — events.option_marks, state.option_marks_curated,
-- analytics.fn_is_occ_option_symbol, analytics.strategy_daily_returns and ops.sp_recompute_engine
-- (itself already superseded onward to bigquery/124) are all UNCHANGED.
--
-- ===== THE BUG (confirmed live, 2026-08-08) =====
-- state.option_mark_anomalies is the designated safety-net detector for a missing option mark
-- (bigquery/40's own header: "a missing/bad option mark must never single-handedly fire a mechanical
-- kill trigger on garbage data"). Its `trading_days` CTE built the candidate calendar from
--     SELECT DISTINCT mark_date FROM state.daily_marks_curated
-- state.daily_marks_curated is written by D2a, which as of 2026-08-08 fires Sunday-Thursday ONLY
-- (ops/cadence.yaml). A Friday therefore never appears as a candidate mark_date, so `expected` never
-- generates a Friday row for any open option position, and the LEFT JOIN ... WHERE om.occ_symbol IS
-- NULL anomaly check can NEVER see a Friday gap — the detector is structurally blind to exactly the
-- condition class it exists to catch, because its own calendar shares the cadence of the gap it is
-- supposed to monitor. This is not a rare edge case: every Friday a Strategy-C option position is open
-- is silently unmonitored, permanently (a past Friday's absence from daily_marks_curated can never
-- retroactively appear).
--
-- TIMING NOTE (live-verified 2026-08-08 while writing this file): D2a's Sun-Thu-only cron
-- (`0,1,2,3,4` in ops/cadence.yaml's cron_utc) landed EARLIER TODAY, in the same push that moved
-- D1/D2a/D2/D3/SL3/OPS0/OPS1/OPS2 to `monitor_class: daily_sun_thu`. daily_marks_curated therefore
-- still HAS rows for the three most recent Fridays (2026-07-24, 2026-07-31, 2026-08-07 all present,
-- ingested under the pre-cutover daily schedule) -- a trailing-window query run today will NOT yet show
-- a live gap on daily_marks_curated's own stock-mark coverage. That is expected and does not change the
-- diagnosis: the vacuity is PROSPECTIVE, starting the first Friday D2a does not run under the new cron
-- (2026-08-14) -- from then on no NEW Friday mark_date row is ever written to daily_marks_curated again,
-- and the old `trading_days` CTE would never see it. events.option_marks/state.option_marks_curated are
-- separately confirmed EMPTY today (0 rows -- Strategy C, the only options-only lane, currently holds no
-- open option position; verified live) so there is no historical option-mark data to retroactively
-- confirm the gap against either way -- this fix closes the detector before the first post-cutover
-- Friday it would otherwise have missed, not after the fact.
--
-- COMPOUNDING FACTOR — net coverage was ZERO, not degraded. dbt/tests/assert_open_positions_have_marks
-- (bigquery/40's own header cross-reference) deliberately EXCLUDES OCC-format option tickers from its
-- own 7-day daily_marks_curated staleness check, with the comment "their same-day-mark completeness is
-- guarded by state.option_mark_anomalies" (dbt/tests/assert_open_positions_have_marks.sql:15-18). That
-- exclusion is correct in principle (an option's marks live in option_marks_curated, never
-- daily_marks_curated, so the dbt test's own daily_marks_curated EXISTS-check would always spuriously
-- fail an option position) but it means the dbt test is NOT a backstop for this bug -- it hands the
-- entire responsibility to state.option_mark_anomalies, which this file's WHY section shows was itself
-- blind on Fridays. Between the two, a held option position's Friday mark gap had exactly zero
-- detectors watching it before this fix.
--
-- THE GENERAL LESSON (see the sibling sweep below): a detector whose own candidate calendar is sourced
-- from a table that shares the cadence of the very gap it is meant to catch is structurally vacuous on
-- every day that table's writer does not run — it can only ever confirm days its writer already
-- covered, which is exactly backwards for a coverage monitor. The correct calendar source for "what
-- days SHOULD this thing have a mark" is state.market_calendar (WHERE is_trading_day), a physical fact
-- about NYSE trading days that has no dependency on any BigQuery routine's own run cadence.
--
-- ===== THE FIX =====
-- `trading_days` now derives from state.market_calendar WHERE is_trading_day, bounded to
-- cal_date <= CURRENT_DATE('America/Denver') (OPERATING plane, matching every other cadence/gate call
-- site in this codebase -- state.market_calendar's own generated range runs through 2030, and nothing
-- past "today" can meaningfully be "expected but missing" yet). The `expected` CTE's per-position JOIN
-- condition is UNCHANGED in shape (td.mark_date >= p.entry_date AND (p.exit_date IS NULL OR
-- td.mark_date <= p.exit_date)) -- it already bounded the candidate day range to each option position's
-- own lifetime (entry_date .. exit_date), so switching the calendar source cannot make this view scan
-- the full 2023-2030 market_calendar range per position; the JOIN's own bounds do that work, exactly as
-- they did before. For a still-open position (exit_date IS NULL) that bound is effectively "through
-- today" via the CURRENT_DATE cap on `trading_days` itself, so an open position can never generate a
-- future-dated "anomaly" for a trading day that has not happened yet.
--
-- Every other column, join, filter and output shape is BYTE-IDENTICAL to bigquery/40's definition:
-- same 4 output columns (strategy, position_key, occ_symbol, mark_date), same LEFT JOIN state.
-- option_marks_curated anomaly predicate, same consumer (ops.sp_recompute_engine's warning-only
-- option_anomaly_count check, unchanged, bigquery/124). This file changes exactly one CTE's source
-- table; nothing about the view's shape, semantics, or downstream contract changes.
--
-- ===== SIBLING SWEEP (2026-08-08) — the bug CLASS, not just this one instance =====
-- Grepped the entire bigquery/*.sql and dbt/ trees for every reference to state.daily_marks_curated,
-- state.signal_marks_curated and state.option_marks_curated (the three D2a/D2a-cadence-written curated
-- views), plus every `SELECT DISTINCT <date> FROM ...` / `trading_days AS (` / `calendar_days AS (`
-- pattern in bigquery/*.sql, looking for any OTHER place deriving a trading-day CALENDAR (a candidate
-- list used to check something else for a GAP) from one of those tables instead of from
-- state.market_calendar. Result: bigquery/40_options_marks.sql:144-146 (fixed by this file) was the
-- ONLY instance of this pattern found anywhere in the codebase. Specifically checked and ruled out:
--   * Every other daily_marks_curated / signal_marks_curated / option_marks_curated reference (~40
--     hits across bigquery/03, 04, 07, 13, 14, 22, 28, 39, 46, 53, 54, 82, 83, 91, 92, 93, 125, 127,
--     152 and dbt/tests/assert_open_positions_have_marks.sql, assert_sgov_no_double_count.sql,
--     assert_drip_dust_twr_exclusion_synthetic.sql) is a plain JOIN or correlated-subquery fetching a
--     ticker's CLOSE/DIVIDEND price on a given date -- consuming the table for its price data, never
--     using it as a stand-in calendar to test a different table for missing rows.
--   * bigquery/46_weekly_benchmarks.sql:73 (analytics.voo_cumulative `axis` CTE) and
--     bigquery/93_park_accounting.sql:128 (`axis` CTE) each build a DISTINCT date axis from their own
--     already-assembled marks/returns series, purely to drive a chained cumulative-return chart series
--     over whatever days that series actually has data for -- explicitly documented as "deliberately
--     NOT every calendar trading day" (bigquery/93:124-126, citing the voo_cumulative precedent). These
--     are display axes over real rows, not gap detectors checking a DIFFERENT table for missing
--     coverage, so the vacuity failure mode does not apply to them.
--   * bigquery/21_strategy_vs_park.sql:188 (`SELECT DISTINCT as_of_date FROM analytics.strategy_vs_
--     park_daily`) is the same display-axis pattern one level upstream of 46's axis CTE above.
--   * bigquery/23/78_book_drawdown_rebase_and_staleness_gate.sql/153_account_snapshot_gap_watch.sql's
--     state.book_drawdown_watch runs its peak_gain window `MAX(...) OVER (ORDER BY snapshot_date ROWS
--     ...)` directly over ops.account_snapshot's OWN rows (a running max over whatever days exist, not
--     a synthetic calendar checked against a second table) -- this is the SAME underlying "D2a doesn't
--     run every day so a gap silently understates a peak" failure mode, but it was already
--     independently found and fixed same-day by bigquery/153_account_snapshot_gap_watch.sql's
--     state.account_snapshot_gap view, which correctly derives its trading-day list from
--     state.market_calendar (bigquery/153:97-102) rather than from any D2a-written table. No new
--     action needed there; cited here only to confirm the class-level fix precedent already exists and
--     this file follows the same corrected pattern.
--   * bigquery/32_d2a_cutover_readiness.sql:30 and bigquery/148_audit_2026_08_08_fixes.sql:209 /
--     bigquery/18_stack_review_fixes.sql:308 (`SELECT DISTINCT routine, run_date`) enumerate DISTINCT
--     (routine, run_date) pairs already present in ops.run_log for routine-cadence bookkeeping -- not a
--     trading-day calendar at all, unrelated to this bug class.
-- Conclusion: this file closes the only live instance of the pattern. Any FUTURE view/check that needs
-- a "what days should X exist" calendar must derive it from state.market_calendar (WHERE
-- is_trading_day), never from another table's own write cadence, exactly as this fix and bigquery/153
-- both now do.

-- ============================================================================
-- state.option_mark_anomalies (SUPERSEDES bigquery/40_options_marks.sql) -- ANOMALY GUARD (ITEM 12).
-- Flags every (strategy, position_key, held_date) where an OCC-format position was open on a REAL NYSE
-- trading day (state.market_calendar, not a D2a-cadence-dependent proxy) but
-- analytics.strategy_daily_returns' option_held branch has NO matching row for it that day (no
-- option_marks_curated entry yet, or the join otherwise missed it) -- the exact case that must NOT
-- silently zero-value or null-corrupt the TWR chain. Self-bootstrapping: empty until the first option
-- position + a genuinely missing mark co-occur.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.option_mark_anomalies` AS
WITH option_positions AS (
  SELECT l.strategy, l.position_key, l.ticker, l.entry_date, l.exit_date
  FROM `stock-trading-498512.analytics.position_lifecycle` l
  WHERE l.strategy IS NOT NULL
    AND `stock-trading-498512.analytics.fn_is_occ_option_symbol`(l.ticker)
),
-- CALENDAR FIX (bigquery/154, 2026-08-08): sourced from state.market_calendar's is_trading_day flag --
-- a physical fact about NYSE trading days -- instead of `SELECT DISTINCT mark_date FROM state.daily_
-- marks_curated`, which shares D2a's own Sunday-Thursday run cadence and could therefore never surface
-- a Friday gap (see this file's header for the full derivation). Bounded to
-- cal_date <= CURRENT_DATE('America/Denver') (OPERATING plane) so a not-yet-happened future trading day
-- is never treated as an "expected" mark; the per-position lifetime bound below (entry_date..exit_date)
-- keeps the JOIN from ever scanning the full 2023-2030 calendar range per position.
trading_days AS (
  SELECT cal_date AS mark_date
  FROM `stock-trading-498512.state.market_calendar`
  WHERE is_trading_day
    AND cal_date <= CURRENT_DATE('America/Denver')
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

-- VERIFICATION (run after apply; read-only).
-- NOTE: double-dash line comments only. A trailing C-style block comment placed after this file's last
-- CREATE causes permanent live-sql-parity drift -- never introduce one here.
--
-- 1. The view runs and returns the same shape as before (4 columns), 0 rows today (2026-08-08 --
--    Strategy C, the only options-only lane, holds no open option positions live):
--    SELECT * FROM `stock-trading-498512.state.option_mark_anomalies`;
--    -> expect 0 rows.
--
-- 2. Proof the calendar source actually changed, and an honest read of WHEN the old source's
--    under-count becomes observable. Compare the new market_calendar-derived trading day count against
--    the old daily_marks_curated-derived one over a trailing window that spans at least one Friday.
--    SELECT
--      (SELECT COUNT(*) FROM `stock-trading-498512.state.market_calendar`
--       WHERE is_trading_day AND cal_date BETWEEN DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 13 DAY)
--                                              AND CURRENT_DATE('America/Denver')) AS market_calendar_days,
--      (SELECT COUNT(DISTINCT mark_date) FROM `stock-trading-498512.state.daily_marks_curated`
--       WHERE mark_date BETWEEN DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 13 DAY)
--                            AND CURRENT_DATE('America/Denver')) AS daily_marks_curated_days;
--    -> LIVE-RUN RESULT 2026-08-08: both columns read 10 (EQUAL, not strictly greater) -- this is
--    EXPECTED, not a falsification of the bug: per the TIMING NOTE above, D2a's Sun-Thu cron landed
--    only earlier today, so every Friday in this trailing window (07-24, 07-31, 08-07) was still
--    ingested under the OLD daily schedule and already has a daily_marks_curated row. Re-run this same
--    query on or after 2026-08-15 (the day after the first Friday under the new cron, 2026-08-14, with
--    no D2a run): market_calendar_days must then read STRICTLY GREATER than daily_marks_curated_days,
--    confirming the old source would have under-counted from that point forward. The structural proof
--    that does not depend on waiting a week: ops/cadence.yaml's D2a entry now reads
--    `cron_utc: "40 22 * * 0,1,2,3,4"` (dow 0-4 = Sun-Thu only, Friday=5/Saturday=6 excluded) --
--    grep ops/cadence.yaml for `id: D2a` and confirm the cron_utc dow-list omits 5 and 6.
--
-- 3. ops.sp_recompute_engine (bigquery/124, unchanged by this file) still reads this view by name only
--    (`SELECT COUNT(*) FROM state.option_mark_anomalies`) -- no shape dependency beyond row count, so
--    this fix cannot break that consumer regardless of which days it now flags.

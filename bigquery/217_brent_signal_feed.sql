-- 217_brent_signal_feed.sql (2026-09-04) — PARK ALLOCATOR v4, PHASE 1.
-- Project: stock-trading-498512. Backfills Brent crude (ticker BZUSD) into events.signal_marks so
-- the SHOCK axis of state.park_axis_daily (bigquery/216) becomes testable. Apply after 216.
--
-- WHY THIS EXISTS. 216's shock axis needs BOTH limbs — state.park_signal_daily.shock_overlay='acute'
-- AND a commodity PRICE limb (Brent > 95). The overlay alone standing for weeks is a LEVEL, never an
-- EVENT: shock_overlay read 'acute' every session 2026-08-14..09-03, and the 2026-09-01 de-risk record
-- counted that three-week-old state as same-session deterioration. The price limb is what makes the
-- axis able to distinguish "a shock exists" from "the shock got worse today". Without a Brent series
-- the axis can never fire, silently capping the ladder while the design claims six axes.
--
-- SOURCE AND VERIFICATION. FMP `commodity` / commodities-historical-price-eod-light, symbol BZUSD —
-- reachable on the CURRENT plan tier (verified 2026-09-04). The series
-- cross-validates against a primary record written independently of it: BZUSD prints 94.65 on
-- 2026-09-01, exactly the figure D1's own 09-01 PARK ALLOCATION CALL cites ("Brent +4.60% to 94.65,
-- within $0.35 of a named trigger level"), and prints 95.52 on 09-03, consistent with that session's
-- clause (c) being scored NOT CLEARED on "Brent above $95".
--
-- CORRECTED 2026-09-13. The parenthetical above previously continued "note FMP `economics` is NOT,
-- which is why the rates axis stays UNTESTABLE — standing vendor constraint, do NOT re-alert it".
-- That was FALSE: FMP economics/treasury-rates is NOT plan-gated, re-probed live 2026-09-13 for the
-- very date cited (2026-09-04 → year10 4.78, year2 4.37), and D2a called it successfully that same
-- day. The rates axis is stood down only because the 10Y lands as free text in
-- events.regime_events.rationale with no numeric column to join on. Full account: bigquery/216's
-- header and PARK_ALLOCATOR_V4_DESIGN.md §"Phase-1 data decision".
--
-- WINDOW — 2026-06-01 .. 2026-09-04, and this boundary is principled rather than convenient.
-- state.park_signal_daily.shock_overlay is non-NULL only from 2026-06-01 (67 rows, 24 of them
-- 'acute'; measured this session). Before that date the shock axis is untestable no matter what
-- Brent history exists, because its overlay limb has no reading — so backfilling earlier Brent would
-- add rows that can never change an axis state. The series starts where the axis can first be
-- evaluated.
--
-- TRADING DAYS ONLY. Brent trades on some dates the equity market does not (the vendor returns
-- Sundays such as 2026-06-07 / 06-14 / 06-21 / 06-28 / 07-05 / 07-12). 216 joins its axes on
-- state.market_calendar trading days, so a non-trading row would be inert — but events.signal_marks
-- holds one row per TRADING day for every other ticker, and quietly breaking that invariant for one
-- ticker is how a future window function silently mis-counts. The INSERT therefore joins
-- state.market_calendar and lands trading days only.
--
-- NOT A NEW ROUTINE, NOT A NEW CRON (design doc §0.4). Ongoing daily capture rides D2a's existing
-- STEP 1d signal-marks ingest, which already writes ^VIX and the menu tickers to this same table;
-- BZUSD is one more ticker on that pass. Nothing here schedules anything.
--
-- TABLE-DESCRIPTION NOTE, deliberately NOT acted on: bigquery/91's OPTIONS(description=...) on
-- events.signal_marks enumerates "the 12-ticker park menu plus SPY plus ^VIX" and so now understates
-- the ticker set. It is left alone on purpose — state.signal_marks_curated applies NO ticker filter
-- (it is a bare dedupe, verified live), so nothing reads that prose as a constraint, and rewriting a
-- landed table's OPTIONS to fix a comment would put the live table definition out of step with its
-- canonical file for a purely cosmetic gain. Recorded here instead.
--
-- RE-APPLY SAFETY. ops-style guard: the INSERT is skipped entirely if any BZUSD row already exists,
-- so a DR rebuild replaying this file is a no-op rather than a duplicate-producing second load.
-- (state.signal_marks_curated would dedupe duplicates by ingest_ts anyway, but silently carrying two
-- physical rows per day is the kind of thing that survives until someone counts raw rows.)

IF NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.events.signal_marks` WHERE ticker = 'BZUSD'
) THEN
  INSERT INTO `stock-trading-498512.events.signal_marks`
    (mark_date, ticker, close, dividend, split_ratio, source, ingest_ts, row_uid)
  SELECT v.d, 'BZUSD', v.px, NUMERIC '0', NUMERIC '1', 'FMP', CURRENT_TIMESTAMP(), GENERATE_UUID()
  FROM UNNEST([
    STRUCT(DATE '2026-06-01' AS d, NUMERIC '94.98' AS px), STRUCT(DATE '2026-06-02', NUMERIC '96.00'),
    STRUCT(DATE '2026-06-03', NUMERIC '97.81'), STRUCT(DATE '2026-06-04', NUMERIC '95.03'),
    STRUCT(DATE '2026-06-05', NUMERIC '93.09'), STRUCT(DATE '2026-06-07', NUMERIC '96.37'),
    STRUCT(DATE '2026-06-08', NUMERIC '94.25'), STRUCT(DATE '2026-06-09', NUMERIC '91.45'),
    STRUCT(DATE '2026-06-10', NUMERIC '93.10'), STRUCT(DATE '2026-06-11', NUMERIC '90.38'),
    STRUCT(DATE '2026-06-12', NUMERIC '87.33'), STRUCT(DATE '2026-06-14', NUMERIC '83.30'),
    STRUCT(DATE '2026-06-15', NUMERIC '83.17'), STRUCT(DATE '2026-06-16', NUMERIC '78.96'),
    STRUCT(DATE '2026-06-17', NUMERIC '79.55'), STRUCT(DATE '2026-06-18', NUMERIC '79.85'),
    STRUCT(DATE '2026-06-19', NUMERIC '77.90'), STRUCT(DATE '2026-06-21', NUMERIC '79.36'),
    STRUCT(DATE '2026-06-22', NUMERIC '77.90'), STRUCT(DATE '2026-06-23', NUMERIC '77.08'),
    STRUCT(DATE '2026-06-24', NUMERIC '73.74'), STRUCT(DATE '2026-06-25', NUMERIC '75.26'),
    STRUCT(DATE '2026-06-26', NUMERIC '71.99'), STRUCT(DATE '2026-06-28', NUMERIC '73.18'),
    STRUCT(DATE '2026-06-29', NUMERIC '73.91'), STRUCT(DATE '2026-06-30', NUMERIC '72.95'),
    STRUCT(DATE '2026-07-01', NUMERIC '71.57'), STRUCT(DATE '2026-07-02', NUMERIC '71.80'),
    STRUCT(DATE '2026-07-03', NUMERIC '71.99'), STRUCT(DATE '2026-07-05', NUMERIC '71.60'),
    STRUCT(DATE '2026-07-06', NUMERIC '71.99'), STRUCT(DATE '2026-07-07', NUMERIC '74.16'),
    STRUCT(DATE '2026-07-08', NUMERIC '78.02'), STRUCT(DATE '2026-07-09', NUMERIC '76.30'),
    STRUCT(DATE '2026-07-10', NUMERIC '76.01'), STRUCT(DATE '2026-07-12', NUMERIC '78.56'),
    STRUCT(DATE '2026-07-13', NUMERIC '83.30'), STRUCT(DATE '2026-07-14', NUMERIC '84.73'),
    STRUCT(DATE '2026-07-15', NUMERIC '84.95'), STRUCT(DATE '2026-07-16', NUMERIC '84.23'),
    STRUCT(DATE '2026-07-17', NUMERIC '88.10'), STRUCT(DATE '2026-07-20', NUMERIC '89.22'),
    STRUCT(DATE '2026-07-21', NUMERIC '91.01'), STRUCT(DATE '2026-07-22', NUMERIC '94.07'),
    STRUCT(DATE '2026-07-23', NUMERIC '100.69'), STRUCT(DATE '2026-07-24', NUMERIC '96.78'),
    STRUCT(DATE '2026-07-27', NUMERIC '88.36'), STRUCT(DATE '2026-07-28', NUMERIC '84.09'),
    STRUCT(DATE '2026-07-29', NUMERIC '90.74'), STRUCT(DATE '2026-07-30', NUMERIC '86.88'),
    STRUCT(DATE '2026-07-31', NUMERIC '87.93'), STRUCT(DATE '2026-08-03', NUMERIC '83.77'),
    STRUCT(DATE '2026-08-04', NUMERIC '79.36'), STRUCT(DATE '2026-08-05', NUMERIC '79.45'),
    STRUCT(DATE '2026-08-06', NUMERIC '82.49'), STRUCT(DATE '2026-08-07', NUMERIC '83.55'),
    STRUCT(DATE '2026-08-10', NUMERIC '87.72'), STRUCT(DATE '2026-08-11', NUMERIC '88.91'),
    STRUCT(DATE '2026-08-12', NUMERIC '88.98'), STRUCT(DATE '2026-08-13', NUMERIC '87.07'),
    STRUCT(DATE '2026-08-14', NUMERIC '88.52'), STRUCT(DATE '2026-08-17', NUMERIC '90.87'),
    STRUCT(DATE '2026-08-18', NUMERIC '91.02'), STRUCT(DATE '2026-08-19', NUMERIC '91.62'),
    STRUCT(DATE '2026-08-20', NUMERIC '93.78'), STRUCT(DATE '2026-08-21', NUMERIC '94.39'),
    STRUCT(DATE '2026-08-24', NUMERIC '92.17'), STRUCT(DATE '2026-08-25', NUMERIC '88.58'),
    STRUCT(DATE '2026-08-26', NUMERIC '87.84'), STRUCT(DATE '2026-08-27', NUMERIC '88.52'),
    STRUCT(DATE '2026-08-28', NUMERIC '88.10'), STRUCT(DATE '2026-08-31', NUMERIC '90.49'),
    STRUCT(DATE '2026-09-01', NUMERIC '94.65'), STRUCT(DATE '2026-09-02', NUMERIC '95.63'),
    STRUCT(DATE '2026-09-03', NUMERIC '95.52'), STRUCT(DATE '2026-09-04', NUMERIC '95.55')
  ]) AS v
  JOIN `stock-trading-498512.state.market_calendar` c
    ON c.cal_date = v.d AND c.is_trading_day;
END IF;

-- Post-conditions: the anchor value D1 cited independently, and the trading-day invariant.
ASSERT (
  SELECT close = NUMERIC '94.65'
  FROM `stock-trading-498512.state.signal_marks_curated`
  WHERE ticker = 'BZUSD' AND mark_date = DATE '2026-09-01'
) AS 'Brent backfill: 2026-09-01 must be 94.65, the value D1 cited independently in its 09-01 record.';

ASSERT (
  SELECT COUNT(*) = 0
  FROM `stock-trading-498512.events.signal_marks` s
  LEFT JOIN `stock-trading-498512.state.market_calendar` c ON c.cal_date = s.mark_date
  WHERE s.ticker = 'BZUSD' AND NOT COALESCE(c.is_trading_day, FALSE)
) AS 'Brent backfill: every BZUSD row must fall on a market_calendar trading day.';

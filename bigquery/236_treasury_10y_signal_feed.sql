-- 236_treasury_10y_signal_feed.sql (2026-09-13) — PARK ALLOCATOR v4: the RATES axis feed.
-- Project: stock-trading-498512. Backfills the daily 10-year Treasury yield into
-- events.regime_events so state.park_axis_daily (bigquery/216) can read it. Apply after 216.
-- Sibling of bigquery/217 (the Brent/shock feed) and deliberately built to the same shape.
--
-- WHY THIS EXISTS. The park v4 six-axis design (PARK_ALLOCATOR_V4_DESIGN.md §2.2) specifies a RATES
-- axis firing at 10Y >= 4.90. It has been stood down as UNTESTABLE since 2026-09-04 on the premise
-- that "FMP economics is plan-gated (ACCESS DENIED)". THAT PREMISE WAS FALSE — refuted and corrected
-- 2026-09-13 (commit f61aa59). FMP economics/treasury-rates works on the current tier and D2a has in
-- fact been calling it successfully every trading day. The real and much smaller gap was that the
-- 10Y it returns was only ever recorded as FREE TEXT inside events.regime_events.rationale (scope
-- TECHNICAL_SIGNAL, key SUSTAINED_INVERSION), with no numeric column the axis view could join on.
-- This file closes that gap for history; D2a STEP 1e writes the row going forward.
--
-- SHAPE. scope='TECHNICAL_INPUT', key='TREASURY_10Y', numeric_value=<10Y yield>. This mirrors
-- EQUITY_BREADTH_PCT exactly — the OTHER non-price axis, which bigquery/216's `breadth` CTE already
-- reads as `WHERE key = '...' AND numeric_value IS NOT NULL`. Using the identical scope/key/numeric
-- convention means the rates CTE is a copy of the breadth CTE with one literal changed, rather than a
-- new access pattern.
--
-- SOURCE AND VERIFICATION. FMP `economics` / `treasury-rates`, field `year10`, pulled 2026-09-13 in
-- five calls spanning 2025-07-18..2026-09-11 (the endpoint returns ~63 rows per request). The series
-- cross-validates against a record written independently of it: 2026-09-04 prints 4.78, exactly the
-- figure D2a's own events.regime_events SUSTAINED_INVERSION row for that date cites in its rationale
-- ("year10 = 4.78, year2 = 4.37") — i.e. the same number, from the same endpoint, recorded by a
-- different routine on the day.
--
-- WINDOW — 2025-07-18 .. 2026-09-11, matching bigquery/216's `sessions` CTE lower bound exactly.
-- This is deliberate and load-bearing, NOT convenience: analytics.park_ladder_shadow derives
-- `ladder_start_date` as the first date on which ALL LIVE AXES are measurable, so a rates series that
-- began later than 2025-07-18 would drag ladder_start_date forward and silently truncate the replay
-- for every other axis. Backfilling the full window keeps ladder_start_date where it is.
--
-- CALENDAR ASYMMETRY — the trap this file's JOIN exists to close. The Treasury and the equity market
-- do NOT keep the same holidays, so the two calendars disagree in BOTH directions over this window:
--   * 3 equity trading days have NO Treasury quote — 2025-10-13 (Columbus Day) and 2025-11-11
--     (Veterans Day), when the bond market is shut but equities trade, plus 2025-10-16, a vendor gap
--     with no holiday explanation. On those days the rates axis reads NULL and carries its last
--     measured level forward under 216's FREEZE semantics. That is correct behaviour, not a defect:
--     three isolated single-session gaps are far inside the >20-session backstop.
--   * 1 Treasury date is NOT an equity trading day — 2026-04-03 (Good Friday). It is present in the
--     VALUES list below and is dropped by the `JOIN state.market_calendar ... AND c.is_trading_day`,
--     exactly as bigquery/217 does. Do NOT remove that join: 216's header documents at length how a
--     vendor date the equity calendar lacks silently shifts every ROWS-based window in the view.
-- Net: 288 quotes in, 287 rows written, over 290 trading sessions.
--
-- RE-APPLY SAFETY. Same ops-style guard as 217: the INSERT is skipped entirely if ANY TREASURY_10Y
-- row already exists, so re-running this file during a DR rebuild is a no-op rather than a duplicate.
-- events.regime_events is append-only and has no natural key to MERGE on.

BEGIN
IF NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.events.regime_events` WHERE key = 'TREASURY_10Y'
) THEN
  INSERT INTO `stock-trading-498512.events.regime_events`
    (event_id, event_ts, as_of_date, scope, key, value, numeric_value, rationale, source_review_ref)
  SELECT
    GENERATE_UUID(), CURRENT_TIMESTAMP(), v.d, 'TECHNICAL_INPUT', 'TREASURY_10Y',
    'FMP treasury-rates year10', v.y10,
    'Backfill from FMP economics/treasury-rates field `year10`, pulled 2026-09-13 (bigquery/236). Cross-validated: 2026-09-04 = 4.78 matches the figure D2a independently recorded in its own SUSTAINED_INVERSION rationale for that date.',
    'bigquery/236 RATES-axis backfill 2026-09-13'
  FROM UNNEST([
    STRUCT(DATE '2025-07-18' AS d, NUMERIC '4.44' AS y10), STRUCT(DATE '2025-07-21', NUMERIC '4.38'),
    STRUCT(DATE '2025-07-22', NUMERIC '4.35'), STRUCT(DATE '2025-07-23', NUMERIC '4.40'),
    STRUCT(DATE '2025-07-24', NUMERIC '4.43'), STRUCT(DATE '2025-07-25', NUMERIC '4.40'),
    STRUCT(DATE '2025-07-28', NUMERIC '4.42'), STRUCT(DATE '2025-07-29', NUMERIC '4.34'),
    STRUCT(DATE '2025-07-30', NUMERIC '4.38'), STRUCT(DATE '2025-07-31', NUMERIC '4.37'),
    STRUCT(DATE '2025-08-01', NUMERIC '4.23'), STRUCT(DATE '2025-08-04', NUMERIC '4.22'),
    STRUCT(DATE '2025-08-05', NUMERIC '4.22'), STRUCT(DATE '2025-08-06', NUMERIC '4.22'),
    STRUCT(DATE '2025-08-07', NUMERIC '4.23'), STRUCT(DATE '2025-08-08', NUMERIC '4.27'),
    STRUCT(DATE '2025-08-11', NUMERIC '4.27'), STRUCT(DATE '2025-08-12', NUMERIC '4.29'),
    STRUCT(DATE '2025-08-13', NUMERIC '4.24'), STRUCT(DATE '2025-08-14', NUMERIC '4.29'),
    STRUCT(DATE '2025-08-15', NUMERIC '4.33'), STRUCT(DATE '2025-08-18', NUMERIC '4.34'),
    STRUCT(DATE '2025-08-19', NUMERIC '4.30'), STRUCT(DATE '2025-08-20', NUMERIC '4.29'),
    STRUCT(DATE '2025-08-21', NUMERIC '4.33'), STRUCT(DATE '2025-08-22', NUMERIC '4.26'),
    STRUCT(DATE '2025-08-25', NUMERIC '4.28'), STRUCT(DATE '2025-08-26', NUMERIC '4.26'),
    STRUCT(DATE '2025-08-27', NUMERIC '4.24'), STRUCT(DATE '2025-08-28', NUMERIC '4.22'),
    STRUCT(DATE '2025-08-29', NUMERIC '4.23'), STRUCT(DATE '2025-09-02', NUMERIC '4.28'),
    STRUCT(DATE '2025-09-03', NUMERIC '4.22'), STRUCT(DATE '2025-09-04', NUMERIC '4.17'),
    STRUCT(DATE '2025-09-05', NUMERIC '4.10'), STRUCT(DATE '2025-09-08', NUMERIC '4.05'),
    STRUCT(DATE '2025-09-09', NUMERIC '4.08'), STRUCT(DATE '2025-09-10', NUMERIC '4.04'),
    STRUCT(DATE '2025-09-11', NUMERIC '4.01'), STRUCT(DATE '2025-09-12', NUMERIC '4.06'),
    STRUCT(DATE '2025-09-15', NUMERIC '4.05'), STRUCT(DATE '2025-09-16', NUMERIC '4.04'),
    STRUCT(DATE '2025-09-17', NUMERIC '4.06'), STRUCT(DATE '2025-09-18', NUMERIC '4.11'),
    STRUCT(DATE '2025-09-19', NUMERIC '4.14'), STRUCT(DATE '2025-09-22', NUMERIC '4.15'),
    STRUCT(DATE '2025-09-23', NUMERIC '4.12'), STRUCT(DATE '2025-09-24', NUMERIC '4.16'),
    STRUCT(DATE '2025-09-25', NUMERIC '4.18'), STRUCT(DATE '2025-09-26', NUMERIC '4.20'),
    STRUCT(DATE '2025-09-29', NUMERIC '4.15'), STRUCT(DATE '2025-09-30', NUMERIC '4.16'),
    STRUCT(DATE '2025-10-01', NUMERIC '4.12'), STRUCT(DATE '2025-10-02', NUMERIC '4.10'),
    STRUCT(DATE '2025-10-03', NUMERIC '4.13'), STRUCT(DATE '2025-10-06', NUMERIC '4.18'),
    STRUCT(DATE '2025-10-07', NUMERIC '4.14'), STRUCT(DATE '2025-10-08', NUMERIC '4.13'),
    STRUCT(DATE '2025-10-09', NUMERIC '4.14'), STRUCT(DATE '2025-10-10', NUMERIC '4.05'),
    STRUCT(DATE '2025-10-14', NUMERIC '4.03'), STRUCT(DATE '2025-10-15', NUMERIC '4.05'),
    STRUCT(DATE '2025-10-17', NUMERIC '4.02'), STRUCT(DATE '2025-10-20', NUMERIC '4.00'),
    STRUCT(DATE '2025-10-21', NUMERIC '3.98'), STRUCT(DATE '2025-10-22', NUMERIC '3.97'),
    STRUCT(DATE '2025-10-23', NUMERIC '4.01'), STRUCT(DATE '2025-10-24', NUMERIC '4.02'),
    STRUCT(DATE '2025-10-27', NUMERIC '4.01'), STRUCT(DATE '2025-10-28', NUMERIC '3.99'),
    STRUCT(DATE '2025-10-29', NUMERIC '4.08'), STRUCT(DATE '2025-10-30', NUMERIC '4.11'),
    STRUCT(DATE '2025-10-31', NUMERIC '4.11'), STRUCT(DATE '2025-11-03', NUMERIC '4.13'),
    STRUCT(DATE '2025-11-04', NUMERIC '4.10'), STRUCT(DATE '2025-11-05', NUMERIC '4.17'),
    STRUCT(DATE '2025-11-06', NUMERIC '4.11'), STRUCT(DATE '2025-11-07', NUMERIC '4.11'),
    STRUCT(DATE '2025-11-10', NUMERIC '4.13'), STRUCT(DATE '2025-11-12', NUMERIC '4.08'),
    STRUCT(DATE '2025-11-13', NUMERIC '4.11'), STRUCT(DATE '2025-11-14', NUMERIC '4.14'),
    STRUCT(DATE '2025-11-17', NUMERIC '4.13'), STRUCT(DATE '2025-11-18', NUMERIC '4.12'),
    STRUCT(DATE '2025-11-19', NUMERIC '4.13'), STRUCT(DATE '2025-11-20', NUMERIC '4.10'),
    STRUCT(DATE '2025-11-21', NUMERIC '4.06'), STRUCT(DATE '2025-11-24', NUMERIC '4.04'),
    STRUCT(DATE '2025-11-25', NUMERIC '4.01'), STRUCT(DATE '2025-11-26', NUMERIC '4.00'),
    STRUCT(DATE '2025-11-28', NUMERIC '4.02'), STRUCT(DATE '2025-12-01', NUMERIC '4.09'),
    STRUCT(DATE '2025-12-02', NUMERIC '4.09'), STRUCT(DATE '2025-12-03', NUMERIC '4.06'),
    STRUCT(DATE '2025-12-04', NUMERIC '4.11'), STRUCT(DATE '2025-12-05', NUMERIC '4.14'),
    STRUCT(DATE '2025-12-08', NUMERIC '4.17'), STRUCT(DATE '2025-12-09', NUMERIC '4.18'),
    STRUCT(DATE '2025-12-10', NUMERIC '4.13'), STRUCT(DATE '2025-12-11', NUMERIC '4.14'),
    STRUCT(DATE '2025-12-12', NUMERIC '4.19'), STRUCT(DATE '2025-12-15', NUMERIC '4.18'),
    STRUCT(DATE '2025-12-16', NUMERIC '4.15'), STRUCT(DATE '2025-12-17', NUMERIC '4.16'),
    STRUCT(DATE '2025-12-18', NUMERIC '4.12'), STRUCT(DATE '2025-12-19', NUMERIC '4.16'),
    STRUCT(DATE '2025-12-22', NUMERIC '4.17'), STRUCT(DATE '2025-12-23', NUMERIC '4.18'),
    STRUCT(DATE '2025-12-24', NUMERIC '4.15'), STRUCT(DATE '2025-12-26', NUMERIC '4.14'),
    STRUCT(DATE '2025-12-29', NUMERIC '4.12'), STRUCT(DATE '2025-12-30', NUMERIC '4.14'),
    STRUCT(DATE '2025-12-31', NUMERIC '4.18'), STRUCT(DATE '2026-01-02', NUMERIC '4.19'),
    STRUCT(DATE '2026-01-05', NUMERIC '4.17'), STRUCT(DATE '2026-01-06', NUMERIC '4.18'),
    STRUCT(DATE '2026-01-07', NUMERIC '4.15'), STRUCT(DATE '2026-01-08', NUMERIC '4.19'),
    STRUCT(DATE '2026-01-09', NUMERIC '4.18'), STRUCT(DATE '2026-01-12', NUMERIC '4.19'),
    STRUCT(DATE '2026-01-13', NUMERIC '4.18'), STRUCT(DATE '2026-01-14', NUMERIC '4.15'),
    STRUCT(DATE '2026-01-15', NUMERIC '4.17'), STRUCT(DATE '2026-01-16', NUMERIC '4.24'),
    STRUCT(DATE '2026-01-20', NUMERIC '4.30'), STRUCT(DATE '2026-01-21', NUMERIC '4.26'),
    STRUCT(DATE '2026-01-22', NUMERIC '4.26'), STRUCT(DATE '2026-01-23', NUMERIC '4.24'),
    STRUCT(DATE '2026-01-26', NUMERIC '4.22'), STRUCT(DATE '2026-01-27', NUMERIC '4.24'),
    STRUCT(DATE '2026-01-28', NUMERIC '4.26'), STRUCT(DATE '2026-01-29', NUMERIC '4.24'),
    STRUCT(DATE '2026-01-30', NUMERIC '4.26'), STRUCT(DATE '2026-02-02', NUMERIC '4.29'),
    STRUCT(DATE '2026-02-03', NUMERIC '4.28'), STRUCT(DATE '2026-02-04', NUMERIC '4.29'),
    STRUCT(DATE '2026-02-05', NUMERIC '4.21'), STRUCT(DATE '2026-02-06', NUMERIC '4.22'),
    STRUCT(DATE '2026-02-09', NUMERIC '4.22'), STRUCT(DATE '2026-02-10', NUMERIC '4.16'),
    STRUCT(DATE '2026-02-11', NUMERIC '4.18'), STRUCT(DATE '2026-02-12', NUMERIC '4.09'),
    STRUCT(DATE '2026-02-13', NUMERIC '4.04'), STRUCT(DATE '2026-02-17', NUMERIC '4.05'),
    STRUCT(DATE '2026-02-18', NUMERIC '4.09'), STRUCT(DATE '2026-02-19', NUMERIC '4.08'),
    STRUCT(DATE '2026-02-20', NUMERIC '4.08'), STRUCT(DATE '2026-02-23', NUMERIC '4.03'),
    STRUCT(DATE '2026-02-24', NUMERIC '4.04'), STRUCT(DATE '2026-02-25', NUMERIC '4.05'),
    STRUCT(DATE '2026-02-26', NUMERIC '4.02'), STRUCT(DATE '2026-02-27', NUMERIC '3.97'),
    STRUCT(DATE '2026-03-02', NUMERIC '4.05'), STRUCT(DATE '2026-03-03', NUMERIC '4.06'),
    STRUCT(DATE '2026-03-04', NUMERIC '4.09'), STRUCT(DATE '2026-03-05', NUMERIC '4.13'),
    STRUCT(DATE '2026-03-06', NUMERIC '4.15'), STRUCT(DATE '2026-03-09', NUMERIC '4.12'),
    STRUCT(DATE '2026-03-10', NUMERIC '4.15'), STRUCT(DATE '2026-03-11', NUMERIC '4.21'),
    STRUCT(DATE '2026-03-12', NUMERIC '4.27'), STRUCT(DATE '2026-03-13', NUMERIC '4.28'),
    STRUCT(DATE '2026-03-16', NUMERIC '4.23'), STRUCT(DATE '2026-03-17', NUMERIC '4.20'),
    STRUCT(DATE '2026-03-18', NUMERIC '4.26'), STRUCT(DATE '2026-03-19', NUMERIC '4.25'),
    STRUCT(DATE '2026-03-20', NUMERIC '4.39'), STRUCT(DATE '2026-03-23', NUMERIC '4.34'),
    STRUCT(DATE '2026-03-24', NUMERIC '4.39'), STRUCT(DATE '2026-03-25', NUMERIC '4.33'),
    STRUCT(DATE '2026-03-26', NUMERIC '4.42'), STRUCT(DATE '2026-03-27', NUMERIC '4.44'),
    STRUCT(DATE '2026-03-30', NUMERIC '4.35'), STRUCT(DATE '2026-03-31', NUMERIC '4.30'),
    STRUCT(DATE '2026-04-01', NUMERIC '4.33'), STRUCT(DATE '2026-04-02', NUMERIC '4.31'),
    STRUCT(DATE '2026-04-03', NUMERIC '4.35'), STRUCT(DATE '2026-04-06', NUMERIC '4.34'),
    STRUCT(DATE '2026-04-07', NUMERIC '4.33'), STRUCT(DATE '2026-04-08', NUMERIC '4.29'),
    STRUCT(DATE '2026-04-09', NUMERIC '4.29'), STRUCT(DATE '2026-04-10', NUMERIC '4.31'),
    STRUCT(DATE '2026-04-13', NUMERIC '4.30'), STRUCT(DATE '2026-04-14', NUMERIC '4.26'),
    STRUCT(DATE '2026-04-15', NUMERIC '4.29'), STRUCT(DATE '2026-04-16', NUMERIC '4.32'),
    STRUCT(DATE '2026-04-17', NUMERIC '4.26'), STRUCT(DATE '2026-04-20', NUMERIC '4.26'),
    STRUCT(DATE '2026-04-21', NUMERIC '4.30'), STRUCT(DATE '2026-04-22', NUMERIC '4.30'),
    STRUCT(DATE '2026-04-23', NUMERIC '4.34'), STRUCT(DATE '2026-04-24', NUMERIC '4.31'),
    STRUCT(DATE '2026-04-27', NUMERIC '4.35'), STRUCT(DATE '2026-04-28', NUMERIC '4.36'),
    STRUCT(DATE '2026-04-29', NUMERIC '4.42'), STRUCT(DATE '2026-04-30', NUMERIC '4.40'),
    STRUCT(DATE '2026-05-01', NUMERIC '4.39'), STRUCT(DATE '2026-05-04', NUMERIC '4.45'),
    STRUCT(DATE '2026-05-05', NUMERIC '4.43'), STRUCT(DATE '2026-05-06', NUMERIC '4.36'),
    STRUCT(DATE '2026-05-07', NUMERIC '4.41'), STRUCT(DATE '2026-05-08', NUMERIC '4.38'),
    STRUCT(DATE '2026-05-11', NUMERIC '4.42'), STRUCT(DATE '2026-05-12', NUMERIC '4.46'),
    STRUCT(DATE '2026-05-13', NUMERIC '4.46'), STRUCT(DATE '2026-05-14', NUMERIC '4.47'),
    STRUCT(DATE '2026-05-15', NUMERIC '4.59'), STRUCT(DATE '2026-05-18', NUMERIC '4.61'),
    STRUCT(DATE '2026-05-19', NUMERIC '4.67'), STRUCT(DATE '2026-05-20', NUMERIC '4.57'),
    STRUCT(DATE '2026-05-21', NUMERIC '4.57'), STRUCT(DATE '2026-05-22', NUMERIC '4.56'),
    STRUCT(DATE '2026-05-26', NUMERIC '4.50'), STRUCT(DATE '2026-05-27', NUMERIC '4.48'),
    STRUCT(DATE '2026-05-28', NUMERIC '4.45'), STRUCT(DATE '2026-05-29', NUMERIC '4.45'),
    STRUCT(DATE '2026-06-01', NUMERIC '4.47'), STRUCT(DATE '2026-06-02', NUMERIC '4.46'),
    STRUCT(DATE '2026-06-03', NUMERIC '4.49'), STRUCT(DATE '2026-06-04', NUMERIC '4.47'),
    STRUCT(DATE '2026-06-05', NUMERIC '4.55'), STRUCT(DATE '2026-06-08', NUMERIC '4.56'),
    STRUCT(DATE '2026-06-09', NUMERIC '4.53'), STRUCT(DATE '2026-06-10', NUMERIC '4.55'),
    STRUCT(DATE '2026-06-11', NUMERIC '4.45'), STRUCT(DATE '2026-06-12', NUMERIC '4.48'),
    STRUCT(DATE '2026-06-15', NUMERIC '4.47'), STRUCT(DATE '2026-06-16', NUMERIC '4.43'),
    STRUCT(DATE '2026-06-17', NUMERIC '4.49'), STRUCT(DATE '2026-06-18', NUMERIC '4.46'),
    STRUCT(DATE '2026-06-22', NUMERIC '4.51'), STRUCT(DATE '2026-06-23', NUMERIC '4.50'),
    STRUCT(DATE '2026-06-24', NUMERIC '4.41'), STRUCT(DATE '2026-06-25', NUMERIC '4.40'),
    STRUCT(DATE '2026-06-26', NUMERIC '4.38'), STRUCT(DATE '2026-06-29', NUMERIC '4.38'),
    STRUCT(DATE '2026-06-30', NUMERIC '4.44'), STRUCT(DATE '2026-07-01', NUMERIC '4.48'),
    STRUCT(DATE '2026-07-02', NUMERIC '4.49'), STRUCT(DATE '2026-07-06', NUMERIC '4.48'),
    STRUCT(DATE '2026-07-07', NUMERIC '4.55'), STRUCT(DATE '2026-07-08', NUMERIC '4.56'),
    STRUCT(DATE '2026-07-09', NUMERIC '4.54'), STRUCT(DATE '2026-07-10', NUMERIC '4.56'),
    STRUCT(DATE '2026-07-13', NUMERIC '4.62'), STRUCT(DATE '2026-07-14', NUMERIC '4.58'),
    STRUCT(DATE '2026-07-15', NUMERIC '4.55'), STRUCT(DATE '2026-07-16', NUMERIC '4.57'),
    STRUCT(DATE '2026-07-17', NUMERIC '4.55'), STRUCT(DATE '2026-07-20', NUMERIC '4.60'),
    STRUCT(DATE '2026-07-21', NUMERIC '4.63'), STRUCT(DATE '2026-07-22', NUMERIC '4.67'),
    STRUCT(DATE '2026-07-23', NUMERIC '4.71'), STRUCT(DATE '2026-07-24', NUMERIC '4.69'),
    STRUCT(DATE '2026-07-27', NUMERIC '4.65'), STRUCT(DATE '2026-07-28', NUMERIC '4.61'),
    STRUCT(DATE '2026-07-29', NUMERIC '4.67'), STRUCT(DATE '2026-07-30', NUMERIC '4.68'),
    STRUCT(DATE '2026-07-31', NUMERIC '4.75'), STRUCT(DATE '2026-08-03', NUMERIC '4.70'),
    STRUCT(DATE '2026-08-04', NUMERIC '4.63'), STRUCT(DATE '2026-08-05', NUMERIC '4.63'),
    STRUCT(DATE '2026-08-06', NUMERIC '4.69'), STRUCT(DATE '2026-08-07', NUMERIC '4.65'),
    STRUCT(DATE '2026-08-10', NUMERIC '4.72'), STRUCT(DATE '2026-08-11', NUMERIC '4.70'),
    STRUCT(DATE '2026-08-12', NUMERIC '4.68'), STRUCT(DATE '2026-08-13', NUMERIC '4.63'),
    STRUCT(DATE '2026-08-14', NUMERIC '4.68'), STRUCT(DATE '2026-08-17', NUMERIC '4.72'),
    STRUCT(DATE '2026-08-18', NUMERIC '4.71'), STRUCT(DATE '2026-08-19', NUMERIC '4.65'),
    STRUCT(DATE '2026-08-20', NUMERIC '4.69'), STRUCT(DATE '2026-08-21', NUMERIC '4.74'),
    STRUCT(DATE '2026-08-24', NUMERIC '4.70'), STRUCT(DATE '2026-08-25', NUMERIC '4.64'),
    STRUCT(DATE '2026-08-26', NUMERIC '4.66'), STRUCT(DATE '2026-08-27', NUMERIC '4.67'),
    STRUCT(DATE '2026-08-28', NUMERIC '4.73'), STRUCT(DATE '2026-08-31', NUMERIC '4.75'),
    STRUCT(DATE '2026-09-01', NUMERIC '4.79'), STRUCT(DATE '2026-09-02', NUMERIC '4.79'),
    STRUCT(DATE '2026-09-03', NUMERIC '4.77'), STRUCT(DATE '2026-09-04', NUMERIC '4.78'),
    STRUCT(DATE '2026-09-08', NUMERIC '4.80'), STRUCT(DATE '2026-09-09', NUMERIC '4.83'),
    STRUCT(DATE '2026-09-10', NUMERIC '4.95'), STRUCT(DATE '2026-09-11', NUMERIC '4.96')
  ]) AS v
  JOIN `stock-trading-498512.state.market_calendar` c
    ON c.cal_date = v.d AND c.is_trading_day;
END IF;
END;

-- Post-conditions. (1) the independently-corroborated anchor value; (2) the trading-day invariant
-- that the JOIN above exists to enforce; (3) the window lower bound park_ladder_shadow depends on.
ASSERT (
  SELECT numeric_value = NUMERIC '4.78'
  FROM `stock-trading-498512.events.regime_events`
  WHERE key = 'TREASURY_10Y' AND as_of_date = DATE '2026-09-04'
) AS 'TREASURY_10Y backfill: 2026-09-04 must be 4.78, the value D2a cited independently in its own SUSTAINED_INVERSION rationale that day.';

ASSERT (
  SELECT COUNT(*) = 0
  FROM `stock-trading-498512.events.regime_events` r
  LEFT JOIN `stock-trading-498512.state.market_calendar` c ON c.cal_date = r.as_of_date
  WHERE r.key = 'TREASURY_10Y' AND NOT COALESCE(c.is_trading_day, FALSE)
) AS 'TREASURY_10Y backfill: every row must fall on a market_calendar trading day (2026-04-03 Good Friday is the case this catches).';

ASSERT (
  SELECT MIN(as_of_date) = DATE '2025-07-18'
  FROM `stock-trading-498512.events.regime_events`
  WHERE key = 'TREASURY_10Y'
) AS 'TREASURY_10Y backfill: must reach back to 2025-07-18, bigquery/216 sessions-CTE start, or park_ladder_shadow.ladder_start_date drags forward.';

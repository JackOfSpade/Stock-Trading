-- 216_park_axis_daily.sql (2026-09-04) — PARK ALLOCATOR v4, PHASE 1 (record-only).
-- Project: stock-trading-498512. Creates state.park_axis_daily: the mechanical six-axis state
-- machine that PARK_ALLOCATOR_V4_DESIGN.md §2.2 specifies. Apply after 215.
--
-- RECORD-ONLY BY CONSTRUCTION. Nothing reads this view to move capital. Phase 1 ships the
-- measurement substrate and the evidence clock ONLY; the ladder does not bind until Phase 3, which
-- is held behind owner word plus a written checklist (§4). Until then the operative rail remains the
-- landed binary DE-RISK EVIDENCE CARDINALITY rule (Claude_Task_Plan.md D1, Operating_Protocols.md
-- §13.F, golden fixture PA-07). Do not wire this into any gate.
--
-- ============================ GRAIN AND SESSION DEFINITION ======================================
-- One row per (as_of_date, axis). as_of_date ranges over TRADING DAYS from state.market_calendar
-- (is_trading_day), per §2.7's pinned SESSION convention: a session is a trading day, and each D1 run
-- is the session for the last trading day <= its run date (Sunday's run is Friday's session). Every
-- N-session rule below counts in THIS index, never in run-dates — otherwise a holiday week such as
-- Labor Day 2026-09-07 gives two D1 runs sharing one session.
--
-- ============================ THE SIX AXES, AND WHICH ARE LIVE =================================
-- Phase-1 data decision, MEASURED 2026-09-04 (design doc §2.2), not assumed:
--   volatility  LIVE   ^VIX > its 20d SMA AND ^VIX > 15.
--   breadth     LIVE   events.regime_events EQUITY_BREADTH_PCT < 66. Series starts 2026-08-05.
--   index       LIVE   SPY < 50dma OR dd_from_252d_high < -0.03.
--   credit      LIVE   HYG/IEF ratio >= 50bp BELOW its own 20d SMA (calibration below).
--   shock       PENDING FEED  shock_overlay='acute' AND Brent > 95. Brent (FMP commodity 'BZUSD')
--                             is verified reachable on the current plan and cross-validates against
--                             D1's own 09-01 record (94.65), but is NOT yet ingested. Until a
--                             BZUSD row exists in state.signal_marks_curated this axis reports
--                             testable=FALSE and contributes to NEITHER count — it activates
--                             automatically when the feed lands, with no change to this file.
--   rates       UNTESTABLE    FMP economics is plan-gated (ACCESS DENIED, verified 2026-09-04) and
--                             no in-house daily 10Y series exists. Documented property, not a gap.
--                             The hike-odds limb launches OFF. DO NOT raise a fresh
--                             fmp_quote_plan_gated alert for this — standing vendor constraint.
--
-- SIGN TRAP (design doc §0.9): dd_from_252d_high is stored NEGATIVE. The index limb is dd < -0.03,
-- never "drawdown > 3%". A wrong sign yields a plausible-looking inverted axis.
--
-- SOURCE TRAP (design doc §0.6 / §2.7, bigquery/91): every price series here reads
-- state.signal_marks_curated, NEVER events.signal_marks. The raw table carries a ^VIX/2026-08-27
-- duplicate (connector + FMP, 253s apart) which shifts the 09-02 vol margin from 0.04 to 0.07 and
-- would fail this design's own acceptance test.
--
-- ============================ CREDIT AXIS CALIBRATION (measured, not chosen) ===================
-- The HY-OAS proxy is HYG/IEF: when credit stress rises, high yield falls against treasuries.
-- Measured over the 266 sessions with a full 20d window (2025-07-18..2026-09-03):
--     bare ratio < SMA20        fires 36.1% of days  -- REJECTED, that is a coin flip, not stress
--     ratio <= SMA20 - 25bp     fires 20.7%
--     ratio <= SMA20 - 50bp     fires 14.3%          -- ADOPTED
--     ratio <= SMA20 - 75bp     fires  9.8%
--     ratio <= SMA20 - 100bp    fires  5.6%
-- Comparators on the same window: volatility fires 44.4%, index fires 21.1%. -50bp puts credit at
-- 14.3%, sensibly BELOW index weakness — credit stress should be rarer than a soft tape — while
-- staying frequent enough to carry information. Deviation SD is 0.503%, so -50bp is ~1 SD: a real
-- excursion, not noise. Resulting 3-axis standing distribution (vol+index+credit, the three with
-- long history): 0 axes 49.2% | 1 axis 28.2% | 2 axes 16.2% | 3 axes 6.4% — i.e. the ladder would
-- be ENGAGED (standing>=2) on 22.6% of days. Recorded because it is the number the Phase-3
-- ratification must weigh: on the measured record defensive positioning has been value-destructive
-- (both closed excursions lost; AI trails never-switch VOO by 357.7bp), so an axis set that engages
-- a fifth of the time is a cost the shadow must price BEFORE anything binds.
--
-- ============================ LEVEL vs EVENT, FREEZE SEMANTICS =================================
-- LEVEL = is this axis defensive on this session, from its last MEASURED reading.
-- EVENT (is_firing) = the axis ENTERED defensive within the last 2 sessions, measured in the session
--   index. A standing state is NOT an event -- that distinction is the whole point (shock_overlay
--   read 'acute' every day 08-14..09-03 and was counted as same-session news in the 09-01 record).
-- A carried level is never re-stamped fresh: measured_on holds the date the reading actually came
-- from, and sessions_since_measured counts forward from it. An axis that has NEVER been measured
-- contributes to neither count. Breadth carries forward at most 2 sessions, then goes UNTESTABLE
-- (§2.7 pinned convention).
--
-- standing_defensive_count / firing_count / testable_axes / cap are computed per as_of_date and
-- repeated on every axis row for that date, so one view answers both the per-axis and the
-- date-level question without a second object. cap = LEAST(100, 25 * standing) per §2.3's table.
-- The ENTRY GATE (>=1 fresh firing AND standing>=2), conviction sizing, the crisis override, the
-- decay confirmation and the clamp are all LADDER rules and live in the shadow (bigquery/218),
-- never here: this view reports STATE, not decisions.

CREATE OR REPLACE VIEW `stock-trading-498512.state.park_axis_daily` AS
WITH sessions AS (
  SELECT cal_date AS as_of_date
  FROM `stock-trading-498512.state.market_calendar`
  WHERE is_trading_day
    AND cal_date BETWEEN DATE '2025-07-18' AND CURRENT_DATE('America/Denver')
),
px AS (
  SELECT mark_date,
         MAX(IF(ticker = '^VIX',  close, NULL)) AS vix,
         MAX(IF(ticker = 'HYG',   close, NULL)) AS hyg,
         MAX(IF(ticker = 'IEF',   close, NULL)) AS ief,
         MAX(IF(ticker = 'BZUSD', close, NULL)) AS brent
  FROM `stock-trading-498512.state.signal_marks_curated`
  WHERE ticker IN ('^VIX', 'HYG', 'IEF', 'BZUSD')
  GROUP BY mark_date
),
-- Rolling windows are computed over MEASURED rows only, so a missing session never silently
-- shortens a 20-session average.
px_w AS (
  SELECT mark_date, vix, hyg, ief, brent,
         AVG(vix) OVER w20 AS vix_sma20,
         COUNT(vix) OVER w20 AS vix_n,
         SAFE_DIVIDE(hyg, ief) AS credit_ratio,
         AVG(SAFE_DIVIDE(hyg, ief)) OVER w20 AS credit_sma20,
         COUNT(SAFE_DIVIDE(hyg, ief)) OVER w20 AS credit_n
  FROM px
  WINDOW w20 AS (ORDER BY mark_date ROWS BETWEEN 19 PRECEDING AND CURRENT ROW)
),
breadth AS (
  SELECT as_of_date AS mark_date, numeric_value AS breadth_pct
  FROM `stock-trading-498512.events.regime_events`
  WHERE key = 'EQUITY_BREADTH_PCT' AND numeric_value IS NOT NULL
),
-- One row per session per axis, carrying the RAW (possibly NULL) reading for that session.
raw AS (
  SELECT s.as_of_date, axis,
         CASE axis
           WHEN 'volatility' THEN IF(p.vix_n = 20 AND p.vix IS NOT NULL,
                                     CAST(p.vix > p.vix_sma20 AND p.vix > 15 AS INT64), NULL)
           WHEN 'breadth'    THEN IF(b.breadth_pct IS NOT NULL,
                                     CAST(b.breadth_pct < 66 AS INT64), NULL)
           WHEN 'index'      THEN IF(g.spy_close IS NOT NULL AND g.spy_50dma IS NOT NULL,
                                     CAST(g.spy_close < g.spy_50dma
                                          OR g.dd_from_252d_high < -0.03 AS INT64), NULL)
           WHEN 'credit'     THEN IF(p.credit_n = 20 AND p.credit_ratio IS NOT NULL,
                                     CAST(SAFE_DIVIDE(p.credit_ratio, p.credit_sma20) - 1
                                          <= -0.0050 AS INT64), NULL)
           -- Shock needs BOTH limbs: the standing overlay alone is never a defensive level.
           WHEN 'shock'      THEN IF(p.brent IS NOT NULL AND g.shock_overlay IS NOT NULL,
                                     CAST(g.shock_overlay = 'acute' AND p.brent > 95 AS INT64), NULL)
           WHEN 'rates'      THEN NULL   -- no daily 10Y series reachable; see header
         END AS raw_level
  FROM sessions s
  CROSS JOIN UNNEST(['volatility','breadth','index','credit','shock','rates']) AS axis
  LEFT JOIN px_w p ON p.mark_date = s.as_of_date
  LEFT JOIN breadth b ON b.mark_date = s.as_of_date
  LEFT JOIN `stock-trading-498512.state.park_signal_daily` g ON g.mark_date = s.as_of_date
),
-- Session index per axis, and last-measured carry-forward.
idx AS (
  SELECT as_of_date, axis, raw_level,
         ROW_NUMBER() OVER (PARTITION BY axis ORDER BY as_of_date) AS sess_i,
         LAST_VALUE(IF(raw_level IS NULL, NULL, as_of_date) IGNORE NULLS)
           OVER (PARTITION BY axis ORDER BY as_of_date
                 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS measured_on,
         LAST_VALUE(raw_level IGNORE NULLS)
           OVER (PARTITION BY axis ORDER BY as_of_date
                 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS carried_level,
         LAST_VALUE(IF(raw_level IS NULL, NULL, sess_i_inner) IGNORE NULLS)
           OVER (PARTITION BY axis ORDER BY as_of_date
                 ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS measured_sess_i
  FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY axis ORDER BY as_of_date) AS sess_i_inner FROM raw)
),
staleness AS (
  SELECT as_of_date, axis, raw_level, measured_on, carried_level,
         sess_i - measured_sess_i AS sessions_since_measured,
         -- Breadth carries forward at most 2 sessions (pinned convention); every other axis carries
         -- indefinitely under FREEZE semantics until the >20-session backstop in §2.3.
         CASE
           WHEN carried_level IS NULL THEN FALSE
           WHEN axis = 'breadth' AND sess_i - measured_sess_i > 2 THEN FALSE
           ELSE TRUE
         END AS testable
  FROM idx
),
lvl AS (
  SELECT as_of_date, axis, raw_level, measured_on, sessions_since_measured, testable,
         IF(testable, carried_level, NULL) AS level_int
  FROM staleness
),
-- EVENT: entered defensive within the last 2 sessions, in the axis's own session index.
ev AS (
  SELECT *,
         LAG(level_int, 1) OVER (PARTITION BY axis ORDER BY as_of_date) AS lvl_1,
         LAG(level_int, 2) OVER (PARTITION BY axis ORDER BY as_of_date) AS lvl_2,
         LAG(level_int, 3) OVER (PARTITION BY axis ORDER BY as_of_date) AS lvl_3
  FROM lvl
),
flagged AS (
  SELECT as_of_date, axis, measured_on, sessions_since_measured, testable, level_int,
         COALESCE(level_int = 1, FALSE) AS is_defensive,
         -- Fired this session, or one session ago: a 0->1 transition in either position.
         COALESCE(
           (level_int = 1 AND COALESCE(lvl_1, 0) = 0)
           OR (lvl_1 = 1 AND COALESCE(lvl_2, 0) = 0 AND level_int = 1),
           FALSE) AS is_firing
  FROM ev
)
SELECT
  as_of_date,
  axis,
  testable,
  measured_on,
  sessions_since_measured,
  is_defensive,
  is_firing,
  -- Date-level aggregates, repeated on every axis row for that date.
  COUNTIF(is_defensive) OVER d AS standing_defensive_count,
  COUNTIF(is_firing)    OVER d AS firing_count,
  COUNTIF(testable)     OVER d AS testable_axes,
  LEAST(100, 25 * COUNTIF(is_defensive) OVER d) AS cap_pct,
  -- The entry gate is reported for convenience but binds nothing in Phase 1 (§2.3).
  (COUNTIF(is_firing) OVER d >= 1 AND COUNTIF(is_defensive) OVER d >= 2) AS increase_gate_open,
  -- Axis-set fingerprint, so a stale acceptance table is self-evident rather than something an
  -- implementer reconciles by adjusting axis definitions (§2.2 re-pin rule).
  STRING_AGG(IF(testable, axis, NULL), '+')
    OVER (PARTITION BY as_of_date ORDER BY axis
          ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS axis_set_fingerprint
FROM flagged
WINDOW d AS (PARTITION BY as_of_date);

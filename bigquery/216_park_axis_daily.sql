-- 216_park_axis_daily.sql (2026-09-04) — PARK ALLOCATOR v4, PHASE 1 (record-only).
-- Project: stock-trading-498512. Creates state.park_axis_daily: the mechanical six-axis state
-- machine that PARK_ALLOCATOR_V4_DESIGN.md §2.2 specifies. Apply after 215.
--
-- PHASE 3 ACTIVATED 2026-09-04 by owner directive: the graded ladder now sizes LIVE idle capital.
-- The activation marker is in bigquery/221; the mechanical pin is state.park_policy_current.
-- graded_enabled. The Phase-1 framing below is RETAINED DELIBERATELY as the record of what was
-- measured BEFORE activation -- do not delete it, and do not read it as current scope.
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
--   shock       LIVE   shock_overlay='acute' AND Brent > 95. Brent (FMP commodity 'BZUSD') was
--                      ingested by bigquery/217 and D2a STEP 1d writes it each trading day.
--                      (This line read "PENDING FEED ... is NOT yet ingested" until 2026-09-13; that
--                      was stale, not wrong-at-the-time — the feed landed in c0a6c61 and the axis has
--                      been in state.park_axis_daily's axis_set_fingerprint ever since. Corrected in
--                      the same pass that landed rates, since a "which axes are live" block that
--                      misreports a live axis is the same defect class twice over.)
--   rates       LIVE          10Y >= 4.90, from events.regime_events (scope TECHNICAL_INPUT, key
--                             TREASURY_10Y, numeric_value). History backfilled 2025-07-18..2026-09-11
--                             by bigquery/236; D2a STEP 1e writes the row each trading day. The
--                             hike-odds limb stays OFF (design doc S2.2) so this axis is single-limb.
--
--                             LANDED 2026-09-13, closing a nine-day stand-down that rested on a FALSE
--                             premise. This block previously read "FMP economics is plan-gated (ACCESS
--                             DENIED, verified 2026-09-04)" and instructed future sessions not to
--                             re-raise fmp_quote_plan_gated for it -- a do-not-re-investigate note that
--                             made the error self-sealing. FMP economics/treasury-rates was never
--                             gated: re-probed live 2026-09-13 for the very date cited as the denial,
--                             it returned a full payload (2026-09-04: year10 4.78, year2 4.37), and
--                             D2a's OWN events.regime_events SUSTAINED_INVERSION row for 2026-09-04
--                             records that same successful call with those same two figures. The real
--                             gap was only that the 10Y landed as free text in `rationale` with no
--                             numeric column to join on. See PARK_ALLOCATOR_V4_DESIGN.md's
--                             "rates -> not landed YET" bullet (corrected) and RUNBOOK notes.
--
--                             CALENDAR ASYMMETRY -- the Treasury and equity calendars disagree BOTH
--                             ways over the backfilled window. Three equity sessions have NO Treasury
--                             quote (2025-10-13 Columbus Day, 2025-11-11 Veterans Day -- bond market
--                             shut, equities open -- plus a 2025-10-16 vendor gap): the axis reads NULL
--                             and FREEZES on those, well inside the >20-session backstop. And
--                             2026-04-03 (Good Friday) is a Treasury date that is NOT an equity
--                             session; bigquery/236's `JOIN state.market_calendar ... is_trading_day`
--                             drops it, which is why 288 quotes became 287 rows. This is the same trap
--                             the SESSION-ANCHORED note below describes for price marks -- and the
--                             reason the rates CTE is joined FROM `sessions`, never driven by its own
--                             date set.
--
--                             THRESHOLD PROVENANCE -- read before "tuning" this. Unlike credit (whose
--                             -50bp level came from the explicit REJECTED/ADOPTED firing-rate sweep
--                             recorded below), 10Y >= 4.90 was specified in S2.2 with NO firing-rate or
--                             distributional evidence, while the series was believed unreachable. On
--                             the 288 quotes backfilled it fires on just 2 sessions -- 2026-09-10
--                             (4.95) and 2026-09-11 (4.96) -- i.e. 0.69%, against volatility 44.4%,
--                             index 21.1% and credit 14.3%. That rarity is FLAGGED, deliberately NOT
--                             corrected here: the threshold is a SPEC decision and S2.7's re-pin rule
--                             forbids tuning an axis definition to move the numbers. Changing 4.90 is
--                             an owner call, made in the design doc first.
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
-- SESSION-ANCHORED, NOT TICKER-ANCHORED. Grouping the raw marks by mark_date makes the row set the
-- UNION of the four tickers' dates, and the 20-row windows below are ROWS-based — so ANY date one
-- ticker has and another lacks silently shifts every other ticker's window. Measured 2026-09-04:
-- 286 distinct mark_dates against 285 trading sessions, with 1 Brent-only date and 2 dates missing
-- ^VIX. Because the axes guard on COUNT(...) OVER w20 = 20, the effect is not a wrong number but a
-- BLANKED axis — volatility and credit go UNTESTABLE for up to 19 sessions after each intruding
-- date, which silently lowers standing_defensive_count and can hold the ladder disengaged.
-- Anchoring to the sessions CTE makes the row set exactly the trading days, so a vendor date the
-- equity calendar does not have can never perturb another ticker's lookback.
px AS (
  SELECT s.as_of_date AS mark_date,
         MAX(IF(m.ticker = '^VIX',  m.close, NULL)) AS vix,
         MAX(IF(m.ticker = 'HYG',   m.close, NULL)) AS hyg,
         MAX(IF(m.ticker = 'IEF',   m.close, NULL)) AS ief,
         MAX(IF(m.ticker = 'BZUSD', m.close, NULL)) AS brent
  FROM sessions s
  LEFT JOIN `stock-trading-498512.state.signal_marks_curated` m
    ON m.mark_date = s.as_of_date
   AND m.ticker IN ('^VIX', 'HYG', 'IEF', 'BZUSD')
  GROUP BY s.as_of_date
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
-- RATES (landed 2026-09-13, bigquery/236). Deliberately the SAME shape as `breadth` above — the other
-- non-price axis — so both non-price axes read events.regime_events through one idiom. numeric_value
-- is NUMERIC, so the >= 4.90 test below is exact decimal comparison, not float.
rates AS (
  SELECT as_of_date AS mark_date, numeric_value AS y10_pct
  FROM `stock-trading-498512.events.regime_events`
  WHERE key = 'TREASURY_10Y' AND numeric_value IS NOT NULL
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
           -- Single-limb by design: the hike-odds limb launches OFF (§2.2), so the LEVEL is the
           -- 10Y alone. NULL on a session with no Treasury quote (bond holidays with equities open)
           -- so the axis goes unmeasured and FREEZES, rather than reading as "not defensive".
           WHEN 'rates'      THEN IF(rt.y10_pct IS NOT NULL,
                                     CAST(rt.y10_pct >= NUMERIC '4.90' AS INT64), NULL)
         END AS raw_level
  FROM sessions s
  CROSS JOIN UNNEST(['volatility','breadth','index','credit','shock','rates']) AS axis
  LEFT JOIN px_w p ON p.mark_date = s.as_of_date
  LEFT JOIN breadth b ON b.mark_date = s.as_of_date
  LEFT JOIN rates rt ON rt.mark_date = s.as_of_date
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
         -- Breadth carries forward at most 2 sessions (pinned convention). Every other axis carries
         -- under FREEZE semantics up to the >20-SESSION BACKSTOP (§2.3) — which is IMPLEMENTED HERE,
         -- not merely referenced. It was missing until 2026-09-04 and its absence was a liveness
         -- defect, not a cosmetic one: a frozen-DEFENSIVE axis pinned standing_defensive_count >= 1
         -- forever, which floors cap_pct at 25, which pins the ladder's f at 25, which means the
         -- engagement episode NEVER ENDS, which means analytics.park_episode_log never opens a new
         -- episode, which means state.park_reevaluation_due.episodes_since_activation is stuck at 0
         -- and the owner is NEVER emailed the re-evaluation reminder. The whole point of that
         -- reminder is that the owner said they would not otherwise remember.
         CASE
           WHEN carried_level IS NULL THEN FALSE
           WHEN axis = 'breadth' AND sess_i - measured_sess_i > 2 THEN FALSE
           WHEN sess_i - measured_sess_i > 20 THEN FALSE
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
-- EVENT DETECTION. The naive form LAGs level_int and COALESCEs a NULL (untestable) neighbour to 0,
-- which reads "I do not know" as "was not defensive" and so manufactures a PHANTOM ENTRY when an
-- axis goes UNTESTABLE while defensive and comes back still defensive. That axis never exited, so it
-- never entered — reporting a firing there contradicts this file's own rule that a standing state is
-- not an event, and a phantom firing raises firing_count, which can open increase_gate_open and let
-- the ladder RAISE f on no new information. Fixed by comparing against the last KNOWN level rather
-- than the last row: prev_known_level skips untestable gaps entirely.
-- FIRST-EVER MEASUREMENT IS NOT AN EVENT: prev_known_level IS NULL yields no firing. That is a
-- deliberate spec choice and it governs a PENDING-FEED axis activating (the shock axis when
-- bigquery/217 landed BZUSD).
ev AS (
  SELECT *,
         LAST_VALUE(level_int IGNORE NULLS) OVER (
           PARTITION BY axis ORDER BY as_of_date
           ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING) AS prev_known_level
  FROM lvl
),
entered AS (
  SELECT *, COALESCE(level_int = 1 AND prev_known_level = 0, FALSE) AS entered_defensive
  FROM ev
),
flagged AS (
  SELECT as_of_date, axis, measured_on, sessions_since_measured, testable, level_int, raw_level,
         COALESCE(level_int = 1, FALSE) AS is_defensive,
         -- Fired this session, or the session before: the design's 2-session event window.
         COALESCE(
           entered_defensive
           OR (LAG(entered_defensive) OVER (PARTITION BY axis ORDER BY as_of_date)
               AND level_int = 1),
           FALSE) AS is_firing
  FROM entered
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
  -- MIXED VINTAGE, EXPOSED AS DATA (2026-09-04). `testable` counts axes with a USABLE level,
  -- carried or fresh; this counts only those MEASURED TODAY. The two differ on a live D1 read by
  -- construction, not by accident: ops.run_log has D1 at 16:12-16:36 MT and D2a from 16:41 MT, and
  -- D2a STEP 1d is what writes events.signal_marks. So at D1's read moment volatility, credit,
  -- index and shock are ALWAYS one session stale, and only breadth is same-session (D1 writes
  -- EQUITY_BREADTH_PCT itself, mid-run, before the park call). analytics.park_ladder_shadow runs
  -- retrospectively and therefore scores every session at full vintage, which the live path can
  -- never do -- see 218's BLIND SPOTS. Do NOT gate on this column: a freshness gate here would
  -- blank four axes every session and disengage the ladder permanently.
  COUNTIF(raw_level IS NOT NULL) OVER d AS axes_measured_today,
  LEAST(100, 25 * COUNTIF(is_defensive) OVER d) AS cap_pct,
  -- The entry gate. As of the 2026-09-04 activation this BINDS: D1's GRADED ALLOCATION step may not
  -- increase f unless it is open (§2.3). It remains a NECESSARY condition, never a trigger.
  (COUNTIF(is_firing) OVER d >= 1 AND COUNTIF(is_defensive) OVER d >= 2) AS increase_gate_open,
  -- Axis-set fingerprint, so a stale acceptance table is self-evident rather than something an
  -- implementer reconciles by adjusting axis definitions (§2.2 re-pin rule).
  STRING_AGG(IF(testable, axis, NULL), '+')
    OVER (PARTITION BY as_of_date ORDER BY axis
          ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS axis_set_fingerprint
FROM flagged
WINDOW d AS (PARTITION BY as_of_date);

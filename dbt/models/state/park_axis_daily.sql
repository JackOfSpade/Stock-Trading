-- Parallel-run dbt port of bigquery/216_park_axis_daily.sql:state.park_axis_daily — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
WITH sessions AS (
  SELECT cal_date AS as_of_date
  FROM {{ ref('market_calendar') }}
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
  LEFT JOIN {{ source('state_external', 'signal_marks_curated') }} m
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
  FROM {{ source('events', 'regime_events') }}
  WHERE key = 'EQUITY_BREADTH_PCT' AND numeric_value IS NOT NULL
),
-- RATES (landed 2026-09-13, bigquery/236). Deliberately the SAME shape as `breadth` above — the other
-- non-price axis — so both non-price axes read events.regime_events through one idiom. numeric_value
-- is NUMERIC, so the >= 4.90 test below is exact decimal comparison, not float.
rates AS (
  SELECT as_of_date AS mark_date, numeric_value AS y10_pct
  FROM {{ source('events', 'regime_events') }}
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
  LEFT JOIN {{ ref('park_signal_daily') }} g ON g.mark_date = s.as_of_date
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
WINDOW d AS (PARTITION BY as_of_date)

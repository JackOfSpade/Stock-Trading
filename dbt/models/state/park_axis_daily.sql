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
px AS (
  SELECT mark_date,
         MAX(IF(ticker = '^VIX',  close, NULL)) AS vix,
         MAX(IF(ticker = 'HYG',   close, NULL)) AS hyg,
         MAX(IF(ticker = 'IEF',   close, NULL)) AS ief,
         MAX(IF(ticker = 'BZUSD', close, NULL)) AS brent
  FROM {{ source('state_external', 'signal_marks_curated') }}
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
  FROM {{ source('events', 'regime_events') }}
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
WINDOW d AS (PARTITION BY as_of_date)

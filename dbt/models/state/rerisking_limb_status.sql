-- Parallel-run dbt port of bigquery/224_rerisking_limb_status.sql:state.rerisking_limb_status — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
WITH latest_per_day AS (
  -- One activation reading per (strategy, day). bigquery/01_schema.sql's tiebreaker.
  SELECT key AS strategy, as_of_date, value
  FROM {{ source('events', 'regime_events') }}
  WHERE scope = 'STRATEGY_ACTIVATION'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY key, as_of_date
                             ORDER BY event_ts DESC, event_id DESC) = 1
),
observed AS (
  -- A blank value is a non-observation, not a state change: dropping it keeps a stray empty row from
  -- splitting a run in two. None survives the dedup above today (two exist in the raw table, both on
  -- 2026-06-03, both outranked by a later row the same day) -- this guard is here so a future tie
  -- cannot silently reset a dwell clock.
  SELECT
    strategy,
    as_of_date,
    value AS activation_value,
    COALESCE(UPPER(value) LIKE '%DO-NOT-ACTIVATE%', FALSE) AS is_dna
  FROM latest_per_day
  WHERE TRIM(COALESCE(value, '')) != ''
),
first_observed AS (
  SELECT strategy, MIN(as_of_date) AS first_observed_date FROM observed GROUP BY strategy
),
seq AS (
  SELECT *, LAG(is_dna) OVER (PARTITION BY strategy ORDER BY as_of_date) AS prev_is_dna
  FROM observed
),
marked AS (
  -- Gaps and islands: a new run starts at the first row and at every change of is_dna.
  SELECT *, COUNTIF(prev_is_dna IS NULL OR prev_is_dna != is_dna) OVER (
      PARTITION BY strategy ORDER BY as_of_date
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS run_id
  FROM seq
),
runs AS (
  SELECT strategy, is_dna, run_id,
         MIN(as_of_date) AS run_start,
         MAX(as_of_date) AS last_reaffirmed,
         COUNT(*)        AS observations
  FROM marked
  GROUP BY strategy, is_dna, run_id
),
current_run AS (
  SELECT * FROM runs
  QUALIFY ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY run_start DESC) = 1
),
latest_value AS (
  SELECT strategy, activation_value
  FROM observed
  QUALIFY ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY as_of_date DESC) = 1
),
cal AS (
  SELECT cal_date FROM {{ ref('market_calendar') }}
  WHERE is_trading_day AND cal_date <= CURRENT_DATE('America/Denver')
),
tech_floor AS (
  -- Leg (c)'s staleness floor: the 5th-most-recent trading day on or before today. A technical plane
  -- last written before this is frozen, not benign -- see the header's LEG (c) paragraph.
  SELECT MIN(cal_date) AS stale_floor
  FROM (SELECT cal_date FROM cal ORDER BY cal_date DESC LIMIT 5)
),
dwell AS (
  -- CROSS JOIN + COUNTIF rather than a correlated scalar subquery: BigQuery rejects a correlated
  -- subquery that references another table unless it can de-correlate it. Exclusive of run_start --
  -- the day the run began is day zero, so B's 2026-08-05 run reads 22 on 2026-09-05.
  SELECT c.strategy, c.is_dna, c.run_start, c.last_reaffirmed, c.observations,
         COUNTIF(cal.cal_date > c.run_start) AS dwell_trading_days
  FROM current_run c
  CROSS JOIN cal
  GROUP BY c.strategy, c.is_dna, c.run_start, c.last_reaffirmed, c.observations
),
tech AS (
  -- Latest TECHNICAL_SIGNAL plane. state.current_regime is already latest-per-(scope, key), and it
  -- carries no recency bound of its own -- hence MIN, the OLDEST of the three keys, so a stale key is
  -- visible rather than masked by a fresh sibling.
  SELECT
    MAX(IF(key = 'VIX_REGIME',      value, NULL)) AS vix_regime,
    MAX(IF(key = 'SPY_TREND',       value, NULL)) AS spy_trend,
    MAX(IF(key = 'EQUITY_BREADTH',  value, NULL)) AS equity_breadth,
    MIN(IF(key IN ('VIX_REGIME', 'SPY_TREND', 'EQUITY_BREADTH'), as_of_date, NULL)) AS technical_as_of,
    (SELECT stale_floor FROM tech_floor) AS technical_stale_floor
  FROM {{ ref('current_regime') }}
  WHERE scope = 'TECHNICAL_SIGNAL'
),
shock_per_day AS (
  SELECT as_of_date, value
  FROM {{ source('events', 'regime_events') }}
  WHERE scope = 'FUNDAMENTAL_AXIS' AND key = 'shock_overlay'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY as_of_date
                             ORDER BY event_ts DESC, event_id DESC) = 1
),
shock_seq AS (
  SELECT *, LAG(value) OVER (ORDER BY as_of_date) AS prev_value FROM shock_per_day
),
shock_marked AS (
  SELECT *, COUNTIF(prev_value IS NULL OR prev_value != value) OVER (
      ORDER BY as_of_date
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS run_id
  FROM shock_seq
),
shock_runs AS (
  SELECT value, run_id, MIN(as_of_date) AS run_start FROM shock_marked GROUP BY value, run_id
),
shock_current AS (
  SELECT * FROM shock_runs QUALIFY ROW_NUMBER() OVER (ORDER BY run_start DESC) = 1
),
brent AS (
  -- bigquery/217 backfilled Brent front-month closes as events.signal_marks ticker='BZUSD'; the
  -- curated view is the deduped reader surface and carries no ticker filter of its own. Restricted to
  -- trading days so the 60-observation window is 60 SESSIONS, matching R1's definition.
  SELECT m.mark_date, m.close
  FROM {{ source('state_external', 'signal_marks_curated') }} m
  JOIN {{ ref('market_calendar') }} c
    ON c.cal_date = m.mark_date AND c.is_trading_day
  WHERE m.ticker = 'BZUSD'
),
brent_baseline_window AS (
  SELECT b.mark_date, b.close
  FROM brent b
  CROSS JOIN shock_current s
  WHERE s.value = 'acute' AND b.mark_date < s.run_start
  QUALIFY ROW_NUMBER() OVER (ORDER BY b.mark_date DESC) <= 60
),
price_leg AS (
  -- Scalar subqueries, not CROSS JOINs: every one of these relations is legitimately EMPTY in a
  -- reachable state (no acute run, no Brent rows), and a CROSS JOIN onto an empty relation would drop
  -- every strategy row from the view rather than reporting an unmeasurable leg.
  SELECT
    (SELECT value      FROM shock_current)                    AS shock_overlay_state,
    (SELECT run_start  FROM shock_current WHERE value = 'acute') AS shock_acute_run_start,
    (SELECT PERCENTILE_CONT(close, 0.5) OVER () FROM brent_baseline_window LIMIT 1) AS brent_baseline,
    (SELECT COUNT(*)        FROM brent_baseline_window)       AS brent_baseline_obs,
    (SELECT MIN(mark_date)  FROM brent_baseline_window)       AS brent_baseline_from,
    (SELECT MAX(mark_date)  FROM brent_baseline_window)       AS brent_baseline_to,
    (SELECT MAX(b.close) FROM brent b
      WHERE b.mark_date >= (SELECT run_start FROM shock_current WHERE value = 'acute')) AS brent_peak,
    (SELECT close      FROM brent ORDER BY mark_date DESC LIMIT 1) AS brent_current,
    (SELECT MAX(mark_date) FROM brent)                        AS brent_as_of
),
price_leg_scored AS (
  SELECT
    p.*,
    p.brent_baseline + 0.5 * (p.brent_peak - p.brent_baseline) AS brent_retrace_trigger,
    CASE
      WHEN p.shock_acute_run_start IS NULL                     THEN 'no_acute_shock_run'
      WHEN p.brent_baseline IS NULL OR p.brent_current IS NULL THEN 'no_brent_data'
      WHEN p.brent_peak <= p.brent_baseline                    THEN 'no_elevation'
      WHEN p.brent_current <= p.brent_baseline + 0.5 * (p.brent_peak - p.brent_baseline)
                                                               THEN 'retraced'
      ELSE 'not_retraced'
    END AS leg_b_basis
  FROM price_leg p
)
SELECT
  r.strategy_code                                    AS strategy,
  lv.activation_value                                AS activation_state,
  d.is_dna                                           AS is_do_not_activate,
  -- Run fields are NULL unless the CURRENT run is a DO-NOT-ACTIVATE run. The limb is about parked
  -- capital, and printing "92 trading days" beside an ACTIVATE strategy invites exactly the misreading
  -- this file exists to remove.
  IF(d.is_dna, d.run_start,          NULL)           AS dna_run_start,
  IF(d.is_dna, d.last_reaffirmed,    NULL)           AS last_reaffirmed,
  IF(d.is_dna, d.observations,       NULL)           AS observations_in_run,
  IF(d.is_dna, d.dwell_trading_days, NULL)           AS dwell_trading_days,
  IF(d.is_dna, d.run_start = fo.first_observed_date, NULL) AS dwell_left_censored,
  COALESCE(d.is_dna AND d.dwell_trading_days >= 15, FALSE) AS leg_a_dwell,
  t.vix_regime,
  t.spy_trend,
  t.equity_breadth,
  t.technical_as_of,
  t.technical_stale_floor,
  COALESCE(t.vix_regime != 'HIGH' AND t.spy_trend != 'DOWN' AND t.equity_breadth = 'HEALTHY'
             AND t.technical_as_of >= t.technical_stale_floor,
           FALSE)                                    AS leg_c_technical,
  p.shock_overlay_state,
  p.shock_acute_run_start,
  p.brent_baseline,
  p.brent_baseline_obs,
  p.brent_baseline_from,
  p.brent_baseline_to,
  p.brent_peak,
  p.brent_current,
  p.brent_retrace_trigger,
  p.brent_as_of,
  p.leg_b_basis,
  p.leg_b_basis IN ('retraced', 'no_elevation', 'no_acute_shock_run', 'no_brent_data') AS leg_b_price_leg,
  COALESCE(d.is_dna AND d.dwell_trading_days >= 15, FALSE)
    AND COALESCE(t.vix_regime != 'HIGH' AND t.spy_trend != 'DOWN' AND t.equity_breadth = 'HEALTHY'
                   AND t.technical_as_of >= t.technical_stale_floor,
                 FALSE)
    AND p.leg_b_basis IN ('retraced', 'no_elevation', 'no_acute_shock_run', 'no_brent_data')
    AND COALESCE(p.shock_overlay_state = 'acute', FALSE)
                                                     AS sql_limbs_fired,
  CURRENT_DATE('America/Denver')                     AS as_of_denver
-- LEFT JOIN on the activation side, matching bigquery/98's own `LEFT JOIN qualifying` + COALESCE
-- shape: an active roster member with NO STRATEGY_ACTIVATION row yet (a freshly adopted strategy
-- between its roster write and its first router call) must still appear here, with NULL run fields
-- and leg_a FALSE, rather than silently vanishing from a view a routine reads as the whole roster.
FROM {{ source('state_external', 'strategy_roster') }} r
LEFT JOIN dwell d          ON d.strategy = r.strategy_code
LEFT JOIN first_observed fo ON fo.strategy = r.strategy_code
LEFT JOIN latest_value lv  ON lv.strategy = r.strategy_code
CROSS JOIN tech t
CROSS JOIN price_leg_scored p
WHERE r.is_active
ORDER BY r.strategy_code

-- ===== 224: state.rerisking_limb_status -- the re-risking limb's SQL-measurable legs, measured =====
-- (2026-09-05, owner-directed shock-override package, item R2(b). Companion to the Strategy.md
-- Section 6 scenario-3 dwell-clock correction landed in the same change.)
--
-- WHAT THIS IS FOR. Strategy.md's Rev 46 "Re-risking limb" (2026-08-24) says a strategy parked at
-- DO-NOT-ACTIVATE should get an out-of-cycle regime REFRESH -- never a flip -- once three legs hold:
--   (a) it has stood at DO-NOT-ACTIVATE for >= 15 consecutive trading days;
--   (b) the shock that parked it has measurably faded;
--   (c) the technical plane is simultaneously benign.
-- Legs (a) and (c) are arithmetic. Half of leg (b) is arithmetic too. This view computes those three
-- and reports them as SEPARATE booleans, so a consumer can never mistake the SQL-measurable subset for
-- the whole limb.
--
-- THE DWELL CLOCK IS THE POINT OF THIS FILE. Rev 46's text measures dwell from "the latest row per
-- strategy ... elapsed since that row's as_of_date". MEASURED against live data on 2026-09-05, that
-- reading returns ONE trading day for every strategy on the roster, because AR_orc re-affirmed all
-- five STRATEGY_ACTIVATION rows on 2026-09-03 -- a no-change re-affirmation resets the clock. Strategy
-- B's real run began 2026-08-05: the 15-day threshold was crossed on 2026-08-26, the literal reading
-- peaked at 18 trading days on 2026-08-31, and M4's 2026-09-01 re-affirmation zeroed it, then AR_orc's
-- 2026-09-03 row zeroed it again. Condition (a) was therefore reachable for about 4 trading days out
-- of a 22-day run, and ANY intra-month re-affirmation erases it entirely. This view counts trading
-- days from the START of the current unbroken run instead; re-affirmation rows EXTEND a run and never
-- reset it.
--
-- MEASURED OUTPUT ON THE DAY OF WRITING (2026-09-05, America/Denver), for the record:
--   A  DO-NOT-ACTIVATE  run from 2026-04-22  dwell 94  LEFT-CENSORED  leg_a TRUE
--   B  DO-NOT-ACTIVATE  run from 2026-08-05  dwell 22                 leg_a TRUE
--   C  HYBRID ACTIVATE  (not DO-NOT-ACTIVATE -- run fields NULL)      leg_a FALSE
--   D  DO-NOT-ACTIVATE  run from 2026-08-05  dwell 22                 leg_a TRUE
--   E  DO-NOT-ACTIVATE  run from 2026-09-03  dwell 1                  leg_a FALSE
--   leg_c_technical TRUE for all (VIX_REGIME LOW, SPY_TREND UP, EQUITY_BREADTH HEALTHY, oldest key
--   2026-09-03, inside a staleness floor of 2026-08-31); shock_overlay_state 'acute'; leg_b_price_leg
--   FALSE (baseline 84.73 over 43 observations, peak 95.63, current 95.55, trigger 90.18).
-- So on day one this view fires leg (a) for three of five strategies and nothing at all for the
-- conjunction -- which is the expected, correct shape: the price leg has not retraced.
--
-- WHY THE DNA PREDICATE IS bigquery/98'S, VERBATIM. `UPPER(value) LIKE '%DO-NOT-ACTIVATE%'` is the
-- exact test state.strategy_capital_enablement uses to decide whether a strategy is CAPITAL-DISABLED.
-- Using it here means dwell counts capital-disabled days as the capital rail itself defines them, and
-- the two can never disagree about what "parked" means. It also survives the held-state convention on
-- the raw values, which exact equality does not: live STRATEGY_ACTIVATION values include
-- `DO-NOT-ACTIVATE (confirmed)`, `DO-NOT-ACTIVATE -- PENDING div-A-202607-1`,
-- `ACTIVATE (pending foundation-change gate)` and a backticked/unbackticked PENDING form, so an
-- equality test would shatter every run into one-day fragments.
--
-- DEDUP BEFORE RUN DETECTION, on (key, as_of_date), ORDER BY event_ts DESC, event_id DESC. Three
-- (strategy, as_of_date) groups carry more than one row, all on 2026-06-03 (two rows for C at an
-- IDENTICAL event_ts, and three each for D and E). That is bigquery/01_schema.sql's own tiebreaker for
-- state.current_regime, recorded there with the reason: "without it ROW_NUMBER picks one arbitrarily,
-- so the resolved regime could flip between query runs." A run boundary that moves between query runs
-- would make the dwell clock non-reproducible, which is worse than the bug being fixed.
--
-- LEFT-CENSORING IS EXPOSED, NOT PAPERED OVER. Every strategy's history in events.regime_events begins
-- 2026-04-22, and Strategy A's DO-NOT-ACTIVATE run begins on that same first row -- so A's 94 trading
-- days is a LOWER BOUND, not a measurement. `dwell_left_censored` says so per row. A consumer that
-- prints "94 trading days" as a fact is asserting something the data cannot support; a consumer that
-- reads leg_a_dwell is fine either way, since a lower bound already clears a 15-day floor.
--
-- LEG (b) IS THE PRICE LEG ONLY, AND IT IS BIASED TO FIRE. Rev 46's leg (b) is "a dated, MEASURED
-- reversal in its own primary inputs, not a narrative re-reading" -- an M1a judgment. The half that IS
-- computable is R1's retracement test: anchor a baseline at the START of the current `acute`
-- shock_overlay run (60-trading-day median of Brent front-month closes ending the session BEFORE it),
-- take the peak close since, and fire when the current close has fallen back to or below the midpoint.
-- The event-recency half stays with the scorer at re-score time. Where the price leg CANNOT speak it
-- returns TRUE rather than FALSE (`leg_b_basis` says which branch was taken): no acute shock run, no
-- elevation above baseline, or no Brent data at all. The asymmetry is deliberate and cheap in one
-- direction only -- a false positive costs one blind re-score that lands `acute` again, a false
-- negative costs weeks of a strategy parked on a shock that has already faded.
--
-- LEG (c) FAILS CLOSED ON ABSENCE *AND* ON STALENESS, and the two asymmetries are not in conflict:
-- "the technical plane is benign" is not something a missing reading establishes, while leg (b)'s
-- fail-open covers a leg that is genuinely half-prose. Absence is not the only way the plane goes
-- dark, though. state.current_regime is latest-per-(scope, key) with NO recency bound, so a stalled
-- D1/D2 pipeline does not leave a HOLE -- it serves the last benign reading indefinitely (measured:
-- TECHNICAL_SIGNAL as_of_dates run 2026-06-03, then 2026-07-31, then daily from 2026-08-03, so
-- current_regime served 2026-06-03 values as "current" for eight weeks). So leg (c) additionally
-- requires the OLDEST of the three keys to be dated within the last 5 trading days
-- (state.market_calendar), and `technical_as_of` is the MIN across the three keys, not the MAX, so one
-- fresh key cannot mask two stale ones. Five trading days absorbs D1/D2's Fri/Sat skip and a holiday
-- week. This floor is a backstop inside the limb, NOT a liveness monitor: the daily freshness and
-- cadence dead-man switches remain the primary net for a stalled technical plane, and all this does is
-- stop a frozen plane from voting "benign".
--
-- THE LIMB IS DEFINITIONALLY SCOPED TO A STANDING `acute` STATE, so `sql_limbs_fired` carries that as
-- a fourth conjunct (`shock_overlay_state = 'acute'`). Leg (b)'s premise is that the shock which
-- parked the strategy has measurably faded; once the axis no longer reads `acute` there is no such
-- shock to fade and nothing for a refresh to re-measure. Without the conjunct the fail-open branches
-- above become a trap: the moment a re-score moves shock_overlay off `acute`, `shock_acute_run_start`
-- goes NULL, `leg_b_basis` becomes 'no_acute_shock_run' (vacuously TRUE) while leg (a) and leg (c)
-- stay TRUE for any still-parked strategy, and the limb self-sustains a 5-trading-day re-queue loop
-- forever -- nothing downstream can clear it, since a re-score never touches activation. PROVEN by
-- read-only replay during the 2026-09-05 adversarial review: injecting one hypothetical
-- shock_overlay='latent' row (exactly what a re-score can write) latched sql_limbs_fired TRUE for A, B
-- and D. `leg_b_basis`, the three leg booleans and `shock_overlay_state` all stay exposed, so the row
-- still says which branch it took.
--
-- NO COLUMN IS NAMED `eligible`. The three legs are separate booleans plus their conjunction,
-- `sql_limbs_fired`, whose name says what it is: the SQL-expressible subset fired. It is NOT the
-- limb's full condition and must never be read as authorising a flip. The limb triggers a REFRESH
-- (D2a queues an out-of-cycle re-score; M1R performs it, blind); it does not authorise any daily
-- routine to score a fundamental axis itself, and the M1a/M1b blinded split is unchanged.
--
-- APPLY: live via the BigQuery MCP, together with the generated dbt mirror
-- (dbt/models/state/rerisking_limb_status.sql). Apply after 223. Read-only view; no writer, no
-- alert registration -- D2a's substep is what reads it.

-- ===== state.rerisking_limb_status =====
CREATE OR REPLACE VIEW `stock-trading-498512.state.rerisking_limb_status` AS
WITH latest_per_day AS (
  -- One activation reading per (strategy, day). bigquery/01_schema.sql's tiebreaker.
  SELECT key AS strategy, as_of_date, value
  FROM `stock-trading-498512.events.regime_events`
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
  SELECT cal_date FROM `stock-trading-498512.state.market_calendar`
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
  FROM `stock-trading-498512.state.current_regime`
  WHERE scope = 'TECHNICAL_SIGNAL'
),
shock_per_day AS (
  SELECT as_of_date, value
  FROM `stock-trading-498512.events.regime_events`
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
  FROM `stock-trading-498512.state.signal_marks_curated` m
  JOIN `stock-trading-498512.state.market_calendar` c
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
FROM `stock-trading-498512.state.strategy_roster` r
LEFT JOIN dwell d          ON d.strategy = r.strategy_code
LEFT JOIN first_observed fo ON fo.strategy = r.strategy_code
LEFT JOIN latest_value lv  ON lv.strategy = r.strategy_code
CROSS JOIN tech t
CROSS JOIN price_leg_scored p
WHERE r.is_active
ORDER BY r.strategy_code;

-- VERIFICATION (run after apply; read-only).
-- SELECT strategy, activation_state, dna_run_start, dwell_trading_days, dwell_left_censored,
--        leg_a_dwell, leg_c_technical, leg_b_price_leg, leg_b_basis, sql_limbs_fired
-- FROM `stock-trading-498512.state.rerisking_limb_status` ORDER BY strategy;
--   -- 2026-09-05 (Denver): A dwell 94 LEFT-CENSORED leg_a TRUE; B and D dwell 22 leg_a TRUE;
--   -- C not DO-NOT-ACTIVATE (run fields NULL) leg_a FALSE; E dwell 1 leg_a FALSE. leg_c_technical
--   -- TRUE for all five (technical_as_of 2026-09-03 vs technical_stale_floor 2026-08-31).
--   -- leg_b_basis 'not_retraced' -> leg_b_price_leg FALSE, so sql_limbs_fired is FALSE for every
--   -- strategy on the day this landed.
-- NOTE: double-dash line comments only. A trailing C-style block comment placed after this file's
-- last statement causes permanent live-sql-parity drift -- never introduce one here.

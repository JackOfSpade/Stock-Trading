-- Parallel-run dbt port of bigquery/263_shock_price_leg_status.sql:state.shock_price_leg_status — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
WITH shock_per_day AS (
  -- One shock_overlay reading per as_of_date. bigquery/01_schema.sql's tiebreaker.
  SELECT as_of_date, value
  FROM {{ source('events', 'regime_events') }}
  WHERE scope = 'FUNDAMENTAL_AXIS' AND key = 'shock_overlay'
  QUALIFY ROW_NUMBER() OVER (PARTITION BY as_of_date
                             ORDER BY event_ts DESC, event_id DESC) = 1
),
shock_observed AS (
  -- A blank value is a non-observation, not a grade change (bigquery/224's guard, applied here).
  SELECT as_of_date, value, value = 'none' AS is_none
  FROM shock_per_day
  WHERE TRIM(COALESCE(value, '')) != ''
),
shock_seq AS (
  SELECT *,
         LAG(value)   OVER (ORDER BY as_of_date) AS prev_value,
         LAG(is_none) OVER (ORDER BY as_of_date) AS prev_is_none
  FROM shock_observed
),
shock_marked AS (
  -- Gaps and islands twice over: value_run_id breaks at every grade change, structure_run_id only
  -- at a none <-> non-none boundary. A structure boundary is always a grade change too, so every
  -- value run lies wholly inside one structure run.
  SELECT *,
         COUNTIF(prev_value IS NULL OR prev_value != value) OVER (
             ORDER BY as_of_date
             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS value_run_id,
         COUNTIF(prev_is_none IS NULL OR prev_is_none != is_none) OVER (
             ORDER BY as_of_date
             ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS structure_run_id
  FROM shock_seq
),
shock_latest AS (
  SELECT value AS shock_overlay_state, is_none, structure_run_id
  FROM shock_marked
  QUALIFY ROW_NUMBER() OVER (ORDER BY as_of_date DESC) = 1
),
value_runs AS (
  SELECT value, value_run_id, structure_run_id, MIN(as_of_date) AS run_start
  FROM shock_marked
  GROUP BY value, value_run_id, structure_run_id
),
anchor AS (
  -- Zero rows when the latest reading is `none` (WHERE + GROUP BY over nothing) or when there is no
  -- reading at all. Otherwise: the start of the most recent `acute` run inside the current non-none
  -- run, else the start of that non-none run.
  SELECT
    sl.shock_overlay_state,
    COALESCE(MAX(IF(vr.value = 'acute', vr.run_start, NULL)), MIN(vr.run_start)) AS structure_anchor
  FROM shock_latest sl
  JOIN value_runs vr ON vr.structure_run_id = sl.structure_run_id
  WHERE NOT sl.is_none
  GROUP BY sl.shock_overlay_state
),
brent AS (
  -- Curated reader surface only, never the raw events.signal_marks table. Trading days only, so a
  -- 60-row window is 60 SESSIONS (bigquery/224's convention). A NULL close is not an observation.
  SELECT m.mark_date, m.close
  FROM {{ source('state_external', 'signal_marks_curated') }} m
  JOIN {{ ref('market_calendar') }} c
    ON c.cal_date = m.mark_date AND c.is_trading_day
  WHERE m.ticker = 'BZUSD' AND m.close IS NOT NULL
),
brent_plateau AS (
  -- Trailing <=10-session window over the FULL series, BEFORE the anchor filter below, so the first
  -- rows after the anchor still see a full window.
  SELECT
    mark_date,
    close,
    ARRAY_AGG(close) OVER w AS plateau_closes,
    COUNT(*)         OVER w AS plateau_obs,
    MIN(close)       OVER w AS plateau_min,
    MAX(close)       OVER w AS plateau_max
  FROM brent
  WINDOW w AS (ORDER BY mark_date ROWS BETWEEN 9 PRECEDING AND CURRENT ROW)
),
brent_plateau_median AS (
  -- A window PERCENTILE_CONT takes no frame, so the window is collected as an array and its median
  -- taken over UNNEST -- the same PERCENTILE_CONT the baseline uses. Kept on a single-relation
  -- source so the correlated subquery never sits over a JOIN.
  SELECT
    p.*,
    (SELECT PERCENTILE_CONT(x, NUMERIC '0.5') OVER () FROM UNNEST(p.plateau_closes) AS x LIMIT 1)
      AS plateau_median
  FROM brent_plateau p
),
baseline_window AS (
  SELECT b.mark_date, b.close
  FROM brent b
  CROSS JOIN anchor a
  WHERE b.mark_date < a.structure_anchor
  QUALIFY ROW_NUMBER() OVER (ORDER BY b.mark_date DESC) <= 60
),
baseline AS (
  -- One row always (an aggregate with no GROUP BY): brent_baseline_obs = 0 on an empty window, which
  -- the WHERE in `anchored` turns into zero output rows.
  SELECT ANY_VALUE(med) AS brent_baseline, COUNT(*) AS brent_baseline_obs
  FROM (SELECT PERCENTILE_CONT(close, NUMERIC '0.5') OVER () AS med FROM baseline_window)
),
anchored AS (
  -- WHERE runs before the window, so brent_peak is the running max from the anchor, not from the
  -- start of the series.
  SELECT
    p.mark_date,
    a.shock_overlay_state,
    a.structure_anchor,
    bl.brent_baseline,
    bl.brent_baseline_obs,
    p.close AS brent_close,
    MAX(p.close) OVER (ORDER BY p.mark_date
                       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS brent_peak,
    p.plateau_median,
    p.plateau_obs,
    p.plateau_min,
    p.plateau_max
  FROM brent_plateau_median p
  CROSS JOIN anchor a
  CROSS JOIN baseline bl
  WHERE p.mark_date >= a.structure_anchor AND bl.brent_baseline_obs > 0
),
scored AS (
  SELECT
    *,
    brent_baseline + (brent_peak - brent_baseline) / 2 AS brent_midpoint,
    COALESCE(plateau_obs = 10
               AND plateau_min >= NUMERIC '0.95' * plateau_median
               AND plateau_max <= NUMERIC '1.05' * plateau_median,
             FALSE)                                    AS plateau_band_holds
  FROM anchored
)
SELECT
  mark_date,
  shock_overlay_state,
  structure_anchor,
  brent_baseline,
  brent_baseline_obs,
  brent_close,
  brent_peak,
  brent_midpoint,
  plateau_median,
  plateau_obs,
  plateau_band_holds,
  brent_peak > brent_baseline AND brent_close >= brent_midpoint AND NOT plateau_band_holds
                                                       AS price_leg_elevated,
  CASE
    WHEN plateau_band_holds             THEN 'plateau_band'
    WHEN brent_peak <= brent_baseline   THEN 'no_elevation'
    WHEN brent_close >= brent_midpoint  THEN 'elevated'
    ELSE 'retraced'
  END                                                  AS basis
FROM scored
ORDER BY mark_date

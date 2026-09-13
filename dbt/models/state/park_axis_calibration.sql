-- Parallel-run dbt port of bigquery/237_park_axis_calibration.sql:state.park_axis_calibration — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
WITH ranked AS (
  SELECT axis, as_of_date, testable, is_defensive, is_firing,
         ROW_NUMBER() OVER (PARTITION BY axis ORDER BY as_of_date DESC) AS rn
  FROM {{ ref('park_axis_daily') }}
),
win AS (
  SELECT * FROM ranked WHERE rn <= 252
)
SELECT
  axis,
  COUNT(*)                                    AS sessions_in_window,
  COUNTIF(testable)                           AS testable_sessions,
  COUNTIF(is_defensive)                       AS defensive_sessions,
  COUNTIF(is_firing)                          AS firing_sessions,
  ROUND(SAFE_DIVIDE(COUNTIF(is_defensive), NULLIF(COUNTIF(testable), 0)) * 100, 2)
                                              AS defensive_pct_of_testable,
  MIN(as_of_date)                             AS window_start,
  MAX(as_of_date)                             AS window_end,
  -- Degenerate ONLY at the extremes, and only once the axis has a meaningful testable sample:
  -- fewer than 60 testable sessions is a young or recently-blanked axis, not a dead one.
  (COUNTIF(testable) >= 60
     AND (COUNTIF(is_defensive) = 0 OR COUNTIF(is_defensive) = COUNTIF(testable)))
                                              AS degenerate,
  CASE
    WHEN COUNTIF(testable) < 60 THEN 'insufficient-sample'
    WHEN COUNTIF(is_defensive) = 0 THEN 'DEAD: never defensive in the trailing window - threshold may have drifted out of reach of the current regime'
    WHEN COUNTIF(is_defensive) = COUNTIF(testable) THEN 'PINNED: defensive on every testable session - threshold may have been overtaken by the current regime'
    ELSE 'ok'
  END                                         AS verdict,
  CURRENT_TIMESTAMP()                         AS checked_at
FROM win
GROUP BY axis

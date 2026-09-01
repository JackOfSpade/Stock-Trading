-- Parallel-run dbt port of bigquery/91_park_signal_layer.sql:state.park_signal_daily — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH spy AS (
  SELECT mark_date, close AS spy_close
  FROM {{ source('state_external', 'signal_marks_curated') }}
  WHERE ticker = 'SPY'
),
spy_windowed AS (
  SELECT
    mark_date, spy_close,
    AVG(spy_close) OVER (ORDER BY mark_date ROWS BETWEEN 49  PRECEDING AND CURRENT ROW) AS spy_50dma_raw,
    COUNT(*)       OVER (ORDER BY mark_date ROWS BETWEEN 49  PRECEDING AND CURRENT ROW) AS n50,
    AVG(spy_close) OVER (ORDER BY mark_date ROWS BETWEEN 199 PRECEDING AND CURRENT ROW) AS spy_200dma_raw,
    COUNT(*)       OVER (ORDER BY mark_date ROWS BETWEEN 199 PRECEDING AND CURRENT ROW) AS n200,
    -- trailing 252-obs high INCLUDING the current row -- day 1 of history correctly yields dd=0
    -- (today's close IS the trailing high on day 1), not an error or a fabricated floor; no
    -- separate obs-count gate here (unlike the DMAs) because the task spec does not ask for one and
    -- the degenerate early-history value is honest, not misleading.
    MAX(spy_close) OVER (ORDER BY mark_date ROWS BETWEEN 251 PRECEDING AND CURRENT ROW) AS spy_252d_high
  FROM spy
),
spy_dma AS (
  SELECT
    mark_date, spy_close, spy_252d_high,
    IF(n50  >= 50,  spy_50dma_raw,  NULL) AS spy_50dma,
    IF(n200 >= 200, spy_200dma_raw, NULL) AS spy_200dma
  FROM spy_windowed
),
vix_all AS (
  SELECT mark_date, close AS vix_close
  FROM {{ source('state_external', 'signal_marks_curated') }}
  WHERE ticker = '^VIX'
),
vix_asof3 AS (
  -- Decorrelated as-of join: for every SPY mark_date, the up-to-3 most recent ^VIX closes on or
  -- before that date. LEFT JOIN so a SPY date preceding any ^VIX history still gets a row (an empty
  -- array after IGNORE NULLS), never a dropped mark_date.
  SELECT
    sd.mark_date,
    ARRAY_AGG(v.vix_close IGNORE NULLS ORDER BY v.mark_date DESC LIMIT 3) AS last3_vix
  FROM spy_dma sd
  LEFT JOIN vix_all v ON v.mark_date <= sd.mark_date
  GROUP BY sd.mark_date
),
regime_axis AS (
  SELECT event_id, event_ts, as_of_date, key, value
  FROM {{ source('events', 'regime_events') }}
  WHERE scope = 'FUNDAMENTAL_AXIS'
    AND key IN ('shock_overlay', 'inflation_trend', 'growth_momentum', 'policy_stance', 'risk_sentiment')
),
regime_asof AS (
  SELECT sd.mark_date, ra.key, ra.value
  FROM spy_dma sd
  JOIN regime_axis ra ON ra.as_of_date <= sd.mark_date
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY sd.mark_date, ra.key
    ORDER BY ra.as_of_date DESC, ra.event_ts DESC, ra.event_id DESC
  ) = 1
),
regime_pivot AS (
  SELECT
    mark_date,
    MAX(IF(key = 'shock_overlay',   value, NULL)) AS shock_overlay,
    MAX(IF(key = 'inflation_trend', value, NULL)) AS inflation_trend,
    MAX(IF(key = 'growth_momentum', value, NULL)) AS growth_momentum,
    MAX(IF(key = 'policy_stance',   value, NULL)) AS policy_stance,
    MAX(IF(key = 'risk_sentiment',  value, NULL)) AS risk_sentiment
  FROM regime_asof
  GROUP BY mark_date
)
SELECT
  sd.mark_date,
  vx.vix_close,
  CASE WHEN ARRAY_LENGTH(v3.last3_vix) = 3
    THEN (SELECT arr[OFFSET(1)] FROM (SELECT ARRAY_AGG(x ORDER BY x) AS arr FROM UNNEST(v3.last3_vix) AS x))
    ELSE NULL
  END                                                                     AS vix_med3,
  sd.spy_close,
  sd.spy_50dma,
  sd.spy_200dma,
  CASE
    WHEN sd.spy_50dma IS NULL OR sd.spy_200dma IS NULL THEN NULL
    WHEN sd.spy_close > sd.spy_50dma AND sd.spy_50dma > sd.spy_200dma THEN 'UP'
    WHEN sd.spy_close < sd.spy_50dma AND sd.spy_50dma < sd.spy_200dma THEN 'DOWN'
    ELSE 'NEUTRAL'
  END                                                                     AS spy_trend,
  SAFE_DIVIDE(sd.spy_close, sd.spy_252d_high) - 1                        AS dd_from_252d_high,
  rp.shock_overlay,
  rp.inflation_trend,
  rp.growth_momentum,
  rp.policy_stance,
  rp.risk_sentiment
FROM spy_dma sd
LEFT JOIN vix_all vx      ON vx.mark_date = sd.mark_date
LEFT JOIN vix_asof3 v3    ON v3.mark_date = sd.mark_date
LEFT JOIN regime_pivot rp ON rp.mark_date = sd.mark_date
ORDER BY sd.mark_date

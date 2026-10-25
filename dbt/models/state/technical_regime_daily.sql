-- Parallel-run dbt port of bigquery/267_paper_regime_coverage_gate.sql:state.technical_regime_daily — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
WITH latest AS (
  SELECT as_of_date, key, value, event_ts
  FROM {{ source('events', 'regime_events') }}
  WHERE scope = 'TECHNICAL_SIGNAL' AND key IN ('SPY_TREND', 'VIX_REGIME')
  QUALIFY ROW_NUMBER() OVER (PARTITION BY as_of_date, key ORDER BY event_ts DESC, event_id DESC) = 1
),
pivoted AS (
  SELECT as_of_date,
    MAX(IF(key = 'SPY_TREND', value, NULL)) AS spy_trend,
    MAX(IF(key = 'VIX_REGIME', value, NULL)) AS vix_regime,
    MAX(event_ts) AS latest_event_ts
  FROM latest
  GROUP BY as_of_date
)
SELECT
  as_of_date, spy_trend, vix_regime,
  IF(spy_trend IN ('UP', 'NEUTRAL', 'DOWN') AND vix_regime IN ('LOW', 'NORMAL', 'HIGH'),
     CONCAT(spy_trend, '/', vix_regime), NULL) AS regime_cell,
  latest_event_ts
FROM pivoted

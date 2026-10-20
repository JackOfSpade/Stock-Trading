-- Parallel-run dbt port of bigquery/259_live_ramp.sql:state.strategy_ramp_calibration — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
WITH params AS (
  SELECT * FROM {{ source('ops', 'strategy_ramp_params') }}
  QUALIFY ROW_NUMBER() OVER (PARTITION BY strategy_code ORDER BY effective_ts DESC) = 1
),
at_cal AS (
  SELECT t.strategy_code, t.score_after AS score_at_calibration, t.cum_llr AS cum_llr_at_calibration
  FROM {{ ref('strategy_ramp_trades') }} t
  JOIN params p USING (strategy_code)
  WHERE t.idx = p.calibration_trades
),
latest AS (
  SELECT strategy_code, MAX(idx) AS trades_n, ARRAY_AGG(score_after ORDER BY idx DESC LIMIT 1)[OFFSET(0)] AS score_now
  FROM {{ ref('strategy_ramp_trades') }}
  GROUP BY strategy_code
)
SELECT
  p.strategy_code,
  r.current_state,
  p.effective_ts            AS params_effective_ts,
  p.source_routine,
  p.opening_score,
  p.rubric_json,
  p.calibration_trades,
  COALESCE(lt.trades_n, 0)  AS trades_n,
  COALESCE(lt.score_now, p.opening_score) AS score_now,
  c.score_at_calibration,
  c.cum_llr_at_calibration,
  c.score_at_calibration IS NOT NULL AS calibration_reached,
  c.score_at_calibration - p.opening_score AS realized_minus_opening
FROM params p
JOIN {{ source('state_external', 'strategy_roster') }} r USING (strategy_code)
LEFT JOIN at_cal c USING (strategy_code)
LEFT JOIN latest lt USING (strategy_code)

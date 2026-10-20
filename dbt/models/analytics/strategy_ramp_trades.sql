-- Parallel-run dbt port of bigquery/259_live_ramp.sql:analytics.strategy_ramp_trades — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
WITH params AS (
  SELECT * FROM {{ source('ops', 'strategy_ramp_params') }}
  QUALIFY ROW_NUMBER() OVER (PARTITION BY strategy_code ORDER BY effective_ts DESC) = 1
),
roster AS (
  SELECT strategy_code, current_state, immutable_since FROM {{ source('state_external', 'strategy_roster') }}
),
trades AS (
  SELECT
    c.strategy AS strategy_code,
    c.campaign_key,
    c.entry_date,
    c.exit_date,
    CAST(SAFE_DIVIDE(c.realized_pnl, c.entry_price * c.total_shares_bought) AS FLOAT64) AS r   -- the campaign columns are NUMERIC; the UDF struct field is FLOAT64
  FROM {{ ref('position_campaigns') }} c
  JOIN roster ro ON ro.strategy_code = c.strategy
  WHERE c.exit_date IS NOT NULL
    AND COALESCE(c.open_shares, 0) = 0
    AND NOT COALESCE(c.is_dust, FALSE)
    AND c.entry_price IS NOT NULL AND c.total_shares_bought IS NOT NULL AND c.total_shares_bought > 0
    AND (ro.immutable_since IS NULL OR c.entry_date >= DATE(ro.immutable_since, 'America/Denver'))
),
agg AS (
  SELECT strategy_code,
         ARRAY_AGG(STRUCT(campaign_key AS key, CAST(entry_date AS STRING) AS entry_date,
                          CAST(exit_date AS STRING) AS exit_date, r)
                   ORDER BY exit_date, entry_date, campaign_key) AS trades
  FROM trades
  WHERE r IS NOT NULL
  GROUP BY strategy_code
)
SELECT
  p.strategy_code,
  CAST(path.idx AS INT64)        AS idx,
  path.key                       AS campaign_key,
  path.r                         AS realized_return,
  path.w                         AS overlap_weight,
  CAST(path.n_overlap AS INT64)  AS n_overlap,
  path.llr,
  path.cum_llr,
  path.surprise,
  path.inc                       AS increment,
  path.score_after,
  path.evidence_kill,
  path.evidence_confirmed
FROM params p
JOIN agg a USING (strategy_code),   -- inner: a strategy with params but no closed trade has no path rows (state.strategy_ramp LEFT JOINs this view, so it still reads opening_score); BigQuery cannot IFNULL a typed empty array against ARRAY_AGG's struct type
UNNEST(`stock-trading-498512.analytics.fn_ramp_path`(
  a.trades,
  p.mu_per_trade, p.sigma_per_trade, p.opening_score, p.tail_loss_5pct,
  CAST(p.calibration_trades AS FLOAT64), p.loss_asymmetry, p.surprise_cut, CAST(p.surprise_window_trades AS FLOAT64),
  p.sprt_alpha, p.sprt_beta)) AS path

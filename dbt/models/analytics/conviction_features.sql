-- Parallel-run dbt port of bigquery/04_analytics.sql:analytics.conviction_features — canonical source is that file until owner cutover.
-- The supervised conviction layer's feature view: GO theses with conviction mapped to an
-- ordinal. BUILT NOW but its OUTPUTS are GATED until >=30 closed GO trades (overfit risk).

SELECT entry_id, entry_date, strategy, ticker, decision, conviction,
  CASE UPPER(conviction)
    WHEN 'LOW' THEN 1 WHEN 'MEDIUM-LOW' THEN 2 WHEN 'MEDIUM' THEN 3
    WHEN 'MEDIUM-HIGH' THEN 4 WHEN 'HIGH' THEN 5 WHEN 'HIGHEST' THEN 6 ELSE NULL END AS conviction_ordinal,
  sub_pattern, regime_state, position_closed, realized_pnl, was_profitable
FROM {{ ref('thesis_outcomes') }}
WHERE decision = 'GO'

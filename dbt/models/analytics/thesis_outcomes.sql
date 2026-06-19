-- Parallel-run dbt port of bigquery/04_analytics.sql:analytics.thesis_outcomes — canonical source is that file until owner cutover.
-- One row per thesis-construction decision, joined to its position outcome (realized P&L from
-- the curated fills) + the prevailing fundamental regime. `was_profitable` is the supervised
-- label for the future conviction model — NULL until the position CLOSES (open positions are
-- unknown, not "unprofitable"; a buy fill's realized_pnl=0 must not read as a loss).
-- Each thesis pairs to ITS round-trip (nearest entry_date), not a ticker-wide SUM.

WITH theses AS (
  SELECT entry_id, entry_date, strategy, ticker, conviction, sub_pattern, decision, title
  FROM {{ source('events', 'decision_log') }}
  WHERE entry_type = 'thesis-construction'
),
fund AS (
  SELECT key AS axis, value, as_of_date,
         ROW_NUMBER() OVER (PARTITION BY key ORDER BY as_of_date DESC) rn
  FROM {{ source('events', 'regime_events') }} WHERE scope='FUNDAMENTAL_AXIS'
),
regime_now AS (SELECT MAX(IF(axis='_integrative', value, NULL)) AS regime_state FROM fund WHERE rn=1)
SELECT
  t.entry_id, t.entry_date, t.strategy, t.ticker, t.decision, t.conviction, t.sub_pattern,
  (SELECT regime_state FROM regime_now) AS regime_state,
  pl.exit_date IS NOT NULL AS position_closed,
  IF(pl.exit_date IS NOT NULL, pl.realized_pnl, NULL) AS realized_pnl,
  CASE WHEN pl.exit_date IS NULL THEN NULL          -- still open -> outcome unknown (not a loss)
       WHEN pl.realized_pnl IS NULL THEN NULL
       ELSE pl.realized_pnl > 0 END AS was_profitable,
  t.title
FROM theses t
LEFT JOIN {{ ref('position_lifecycle') }} pl
  ON pl.strategy = t.strategy AND pl.ticker = t.ticker
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY t.entry_id
  ORDER BY ABS(DATE_DIFF(pl.entry_date, t.entry_date, DAY)) NULLS LAST
) = 1

-- Parallel-run dbt port of bigquery/102_pyramid_aware_lifecycle.sql:analytics.thesis_outcomes —
-- canonical source is that file until owner cutover.
-- One row per thesis-construction decision, joined to its position outcome (realized P&L from
-- the curated fills) + the prevailing fundamental regime. `was_profitable` is the supervised
-- label for the future conviction model — NULL until the position CLOSES (open positions are
-- unknown, not "unprofitable"; a buy fill's realized_pnl=0 must not read as a loss).
-- Each thesis pairs to ITS campaign (nearest entry_date), not a ticker-wide SUM.
--
-- REGIME-AS-OF FIX (2026-07-03, self-improvement audit S-1/B-1): regime_state is the regime in
-- effect ON OR BEFORE entry_date, NOT the single latest value — the prior form back-stamped the
-- current regime onto every historical thesis (look-ahead leakage). Decorrelated join + QUALIFY
-- (BigQuery views do not support a same-row correlated subquery against another table).
--
-- REBUILT 2026-07-21 (pyramid-aware accounting rebuild): the LEFT JOIN target + the QUALIFY
-- nearest-entry_date window moved from position_lifecycle (Tier-1 lots) to position_campaigns
-- (Tier-2 campaigns) — a pyramid add's own thesis-construction entry legitimately maps to the SAME
-- campaign as the position's original entry, not a separate per-lot row. All other columns/semantics
-- unchanged.

WITH theses AS (
  SELECT entry_id, entry_date, strategy, ticker, conviction, sub_pattern, decision, title
  FROM {{ source('events', 'decision_log') }}
  WHERE entry_type = 'thesis-construction'
),
regime_axis AS (
  SELECT value AS regime_state, as_of_date
  FROM {{ source('events', 'regime_events') }}
  WHERE scope='FUNDAMENTAL_AXIS' AND key='_integrative'
),
thesis_regime AS (
  SELECT t.entry_id, ra.regime_state
  FROM theses t
  LEFT JOIN regime_axis ra ON ra.as_of_date <= t.entry_date
  QUALIFY ROW_NUMBER() OVER (PARTITION BY t.entry_id ORDER BY ra.as_of_date DESC) = 1
)
SELECT
  t.entry_id, t.entry_date, t.strategy, t.ticker, t.decision, t.conviction, t.sub_pattern,
  tr.regime_state,
  pc.exit_date IS NOT NULL AS position_closed,
  IF(pc.exit_date IS NOT NULL, pc.realized_pnl, NULL) AS realized_pnl,
  CASE WHEN pc.exit_date IS NULL THEN NULL          -- still open -> outcome unknown (not a loss)
       WHEN pc.realized_pnl IS NULL THEN NULL
       ELSE pc.realized_pnl > 0 END AS was_profitable,
  t.title
FROM theses t
LEFT JOIN thesis_regime tr ON tr.entry_id = t.entry_id
LEFT JOIN {{ ref('position_campaigns') }} pc
  ON pc.strategy = t.strategy AND pc.ticker = t.ticker
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY t.entry_id
  ORDER BY ABS(DATE_DIFF(pc.entry_date, t.entry_date, DAY)) NULLS LAST
) = 1

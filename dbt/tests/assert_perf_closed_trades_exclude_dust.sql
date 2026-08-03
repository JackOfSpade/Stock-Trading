-- Every persisted closed-trade count must match cumulative non-dust closed campaigns.
-- Returns rows only on failure.

SELECT p.as_of_date, p.strategy, p.closed_trades,
  COUNTIF(c.exit_date IS NOT NULL AND NOT COALESCE(c.is_dust, FALSE)) AS expected_closed_trades
FROM {{ source('perf', 'strategy_daily') }} p
LEFT JOIN {{ ref('position_campaigns') }} c
  ON c.strategy = p.strategy AND c.exit_date <= p.as_of_date
GROUP BY p.as_of_date, p.strategy, p.closed_trades
HAVING p.closed_trades != expected_closed_trades

-- Parallel-run dbt port of bigquery/03_twr_engine.sql:analytics.strategy_daily_returns — canonical source is that file until owner cutover.
-- Value-weighted daily deployed TOTAL returns per strategy, GROSS of commissions (the
-- PROFITABILITY metric; commissions are a scale artifact at ~$30 positions, tracked exactly
-- + separately in cash/NAV). Flow-immune.
--   entry day: prev_mv = shares*entry_price (baseline at MARKET cost, no comm)
--   exit  day: mv      = shares*exit_price  (GROSS proceeds, no comm)
--   interior:  mv = shares*close ; prev_mv = LAG(mv)
-- Dividends (total return) enter the numerator. Fill-price boundaries matter (BURL bought
-- 303.00 but CLOSED 323.83 on entry day; a close-baseline would mis-state it).

WITH held AS (
  SELECT m.mark_date, l.strategy, l.position_key, l.shares, l.entry_price,
         l.shares * IF(m.mark_date = l.exit_date, l.exit_price, m.close) AS mv,  -- gross; exit at fill price
         l.shares * COALESCE(m.dividend,0) AS div_cash
  FROM {{ ref('position_lifecycle') }} l
  JOIN {{ ref('daily_marks_curated') }} m
    ON m.ticker = l.ticker
   AND m.mark_date >= l.entry_date
   AND (l.exit_date IS NULL OR m.mark_date <= l.exit_date)
  WHERE l.strategy IS NOT NULL
),
lagged AS (
  SELECT mark_date, strategy, position_key, mv, div_cash,
         COALESCE(LAG(mv) OVER (PARTITION BY position_key ORDER BY mark_date),
                  shares*entry_price) AS prev_mv   -- entry-day baseline: market cost (no commission)
  FROM held
)
SELECT mark_date AS as_of_date, strategy,
       SAFE_DIVIDE(SUM(mv + div_cash) - SUM(prev_mv), SUM(prev_mv)) AS r_deployed,
       -- deployed dollars marked that day (Σ prev_mv); feeds analytics.strategy_vs_park_daily
       SUM(prev_mv) AS deployed_capital,
       COUNT(*) AS n_positions
FROM lagged
GROUP BY mark_date, strategy

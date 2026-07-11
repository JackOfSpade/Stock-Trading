-- Parallel-run dbt port of bigquery/40_options_marks.sql:analytics.strategy_daily_returns (rebuilt there,
-- not bigquery/03_twr_engine.sql, as of ITEM 12 2026-07-11) — canonical source is that file until owner cutover.
-- Value-weighted daily deployed TOTAL returns per strategy, GROSS of commissions (the
-- PROFITABILITY metric; commissions are a scale artifact at ~$30 positions, tracked exactly
-- + separately in cash/NAV). Flow-immune.
--   entry day: prev_mv = shares*entry_price (baseline at MARKET cost, no comm)
--   exit  day: mv      = shares*exit_price  (GROSS proceeds, no comm)
--   interior:  mv = shares*close ; prev_mv = LAG(mv)
-- Dividends (total return) enter the numerator. Fill-price boundaries matter (BURL bought
-- 303.00 but CLOSED 323.83 on entry day; a close-baseline would mis-state it).
--
-- OPTION-AWARE VALUATION (ITEM 12, self-improvement audit 2026-07-11): a leg whose ticker is an OCC
-- option symbol is valued at `contracts * multiplier * premium_close` against option_marks_curated
-- instead of `shares * close` against daily_marks_curated. The OCC-format regex below is a literal copy
-- of the live analytics.fn_is_occ_option_symbol UDF (bigquery/40) — dbt models cannot reference a
-- hand-created BigQuery routine, so this must be kept in sync by hand if that UDF's pattern ever changes.

WITH equity_held AS (
  SELECT m.mark_date, l.strategy, l.position_key, l.shares, l.entry_price,
         l.shares * IF(m.mark_date = l.exit_date, l.exit_price, m.close) AS mv,  -- gross; exit at fill price
         l.shares * COALESCE(m.dividend,0) AS div_cash
  FROM {{ ref('position_lifecycle') }} l
  JOIN {{ ref('daily_marks_curated') }} m
    ON m.ticker = l.ticker
   AND m.mark_date >= l.entry_date
   AND (l.exit_date IS NULL OR m.mark_date <= l.exit_date)
  WHERE l.strategy IS NOT NULL
    AND NOT REGEXP_CONTAINS(l.ticker, r'^[A-Z]{1,6} *[0-9]{6}[CP][0-9]{8}$')
),
option_held AS (
  SELECT om.mark_date, l.strategy, l.position_key, l.shares, l.entry_price,
         l.shares * om.multiplier * IF(om.mark_date = l.exit_date, l.exit_price, om.premium_close) AS mv,
         CAST(0 AS NUMERIC) AS div_cash
  FROM {{ ref('position_lifecycle') }} l
  JOIN {{ ref('option_marks_curated') }} om
    ON om.occ_symbol = l.ticker
   AND om.mark_date >= l.entry_date
   AND (l.exit_date IS NULL OR om.mark_date <= l.exit_date)
  WHERE l.strategy IS NOT NULL
    AND REGEXP_CONTAINS(l.ticker, r'^[A-Z]{1,6} *[0-9]{6}[CP][0-9]{8}$')
),
held AS (
  SELECT * FROM equity_held
  UNION ALL
  SELECT * FROM option_held
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

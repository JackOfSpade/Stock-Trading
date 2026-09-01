-- Parallel-run dbt port of bigquery/125_dust_excluded_from_twr.sql:analytics.strategy_daily_returns — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH equity_marked AS (
  SELECT m.mark_date, l.strategy, l.position_key, l.shares, l.entry_price, l.exit_price, l.exit_date,
         CAST(1 AS INT64) AS multiplier, m.close, COALESCE(m.dividend, 0) AS dividend,
         COALESCE(NULLIF(m.split_ratio, 0), 1) AS day_split
  FROM {{ ref('position_lifecycle') }} l
  JOIN {{ ref('daily_marks_curated') }} m
    ON m.ticker = l.ticker
   AND m.mark_date >= l.entry_date
   AND (l.exit_date IS NULL OR m.mark_date <= l.exit_date)
  WHERE l.strategy IS NOT NULL
    AND NOT COALESCE(l.is_dust, FALSE)
    AND NOT `stock-trading-498512.analytics.fn_is_occ_option_symbol`(l.ticker)
),
equity_runprod AS (
  SELECT *, EXP(SUM(LN(day_split)) OVER (
    PARTITION BY position_key ORDER BY mark_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)) AS rp
  FROM equity_marked
),
equity_held AS (
  SELECT mark_date, strategy, position_key, shares, entry_price, multiplier,
    shares * eff * IF(mark_date = exit_date, exit_price, close) AS mv,
    shares * eff * dividend AS div_cash
  FROM (
    SELECT *, SAFE_DIVIDE(rp,
      FIRST_VALUE(rp) OVER (PARTITION BY position_key ORDER BY mark_date)) AS eff
    FROM equity_runprod
  )
),
option_held AS (
  SELECT om.mark_date, l.strategy, l.position_key, l.shares, l.entry_price,
         om.multiplier,
         l.shares * om.multiplier * IF(om.mark_date = l.exit_date, l.exit_price, om.premium_close) AS mv,
         CAST(0 AS NUMERIC) AS div_cash
  FROM {{ ref('position_lifecycle') }} l
  JOIN {{ ref('option_marks_curated') }} om
    ON om.occ_symbol = l.ticker
   AND om.mark_date >= l.entry_date
   AND (l.exit_date IS NULL OR om.mark_date <= l.exit_date)
  WHERE l.strategy IS NOT NULL
    AND NOT COALESCE(l.is_dust, FALSE)
    AND `stock-trading-498512.analytics.fn_is_occ_option_symbol`(l.ticker)
),
held AS (
  SELECT * FROM equity_held
  UNION ALL
  SELECT * FROM option_held
),
lagged AS (
  SELECT mark_date, strategy, position_key, mv, div_cash,
         COALESCE(LAG(mv) OVER (PARTITION BY position_key ORDER BY mark_date),
                  shares * multiplier * entry_price) AS prev_mv
  FROM held
)
SELECT mark_date AS as_of_date, strategy,
       SAFE_DIVIDE(SUM(mv + div_cash) - SUM(prev_mv), SUM(prev_mv)) AS r_deployed,
       SUM(prev_mv) AS deployed_capital,
       COUNT(*) AS n_positions
FROM lagged
GROUP BY mark_date, strategy

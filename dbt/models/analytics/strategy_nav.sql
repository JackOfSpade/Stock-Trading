-- Parallel-run dbt port of bigquery/04_analytics.sql:analytics.strategy_nav — canonical source is that file until owner cutover.
-- Per-strategy NAV / 2%-sizing base. NAV = equal-split deposits ($1889.372/strategy = $9446.86/5)
-- + realized P&L (curated fills) + unrealized (open positions at latest close) + held-stock
-- dividends. Gives sizing_base_2pct (~$37.7/strategy) + available-funds (NAV - deployed MV).
-- NOTE: the shared SGOV park is held at deposit par here (Σ NAV ~0.2% light vs connector NLV);
-- the SGOV park is account-level (no per-strategy split — see state.sgov_reconciliation / §13);
-- per-strategy budget = available_funds below.

WITH dep AS (SELECT s AS strategy, CAST(1889.372 AS NUMERIC) AS deposits FROM UNNEST(['A','B','C','D','E']) s),
realized AS (SELECT strategy, SUM(realized_pnl) AS realized_pnl FROM {{ ref('trade_fills_curated') }} GROUP BY strategy),
latest_close AS (SELECT ticker, close FROM {{ ref('daily_marks_curated') }}
  QUALIFY ROW_NUMBER() OVER (PARTITION BY ticker ORDER BY mark_date DESC)=1),
open_pos AS (SELECT cp.strategy, SUM(cp.shares*lc.close) AS open_mv, SUM(cp.cost_basis) AS open_cost
  FROM {{ ref('current_positions') }} cp JOIN latest_close lc USING (ticker)
  WHERE cp.status='OPEN' GROUP BY cp.strategy),
divs AS (SELECT l.strategy, SUM(l.shares*m.dividend) AS dividends
  FROM {{ ref('position_lifecycle') }} l
  JOIN {{ ref('daily_marks_curated') }} m ON m.ticker=l.ticker AND m.dividend IS NOT NULL
   AND m.mark_date>=l.entry_date AND (l.exit_date IS NULL OR m.mark_date<=l.exit_date)
  GROUP BY l.strategy)
SELECT d.strategy, d.deposits,
  ROUND(COALESCE(r.realized_pnl,0),2) AS realized_pnl,
  ROUND(COALESCE(o.open_mv-o.open_cost,0),2) AS unrealized_pnl,
  ROUND(COALESCE(dv.dividends,0),2) AS dividends_held,
  ROUND(COALESCE(o.open_mv,0),2) AS deployed_mv,
  ROUND(d.deposits+COALESCE(r.realized_pnl,0)+COALESCE(o.open_mv-o.open_cost,0)+COALESCE(dv.dividends,0),2) AS nav,
  ROUND(d.deposits+COALESCE(r.realized_pnl,0)+COALESCE(o.open_mv-o.open_cost,0)+COALESCE(dv.dividends,0)-COALESCE(o.open_mv,0),2) AS available_funds,
  ROUND(0.02*(d.deposits+COALESCE(r.realized_pnl,0)+COALESCE(o.open_mv-o.open_cost,0)+COALESCE(dv.dividends,0)),2) AS sizing_base_2pct
FROM dep d LEFT JOIN realized r USING(strategy) LEFT JOIN open_pos o USING(strategy) LEFT JOIN divs dv USING(strategy)

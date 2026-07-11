-- Parallel-run dbt port of bigquery/22_cash_flows.sql:analytics.strategy_nav (redefined there,
-- supersedes the earlier hardcoded-literal version) — canonical source is that file until owner cutover.
-- Per-strategy NAV / 2%-sizing base. NAV = equal-split deposits (events.cash_flows, self-improvement
-- audit B-1-exec — a strategy-tagged flow attributes to that strategy only) + realized P&L (curated
-- fills) + unrealized (open positions at latest close) + held-stock dividends. Gives sizing_base_2pct
-- (~$37.7/strategy) + available-funds (NAV - deployed MV).
-- NOTE: the shared SGOV park is held at deposit par here (Σ NAV ~0.2% light vs connector NLV);
-- the SGOV park is account-level (no per-strategy split — see state.sgov_reconciliation / §13);
-- per-strategy budget = available_funds below.

-- (rev 2026-07-10 — Strategy Arsenal autonomy conversion, owner directive; rev 2026-07-10b — bug fix,
-- code-review finding #1, mirroring the bigquery/22_cash_flows.sql fix exactly so dbt-parity's
-- EXCEPT-DISTINCT still matches the live analytics.strategy_nav.) BUG FIX: enumerating `active` as
-- CURRENTLY is_active meant a terminated strategy's history vanished from the rollup, and the
-- equal-split divisor for HISTORICAL flows was recomputed off the current active count -- retroactively
-- re-splitting old deposits among fewer survivors the moment any strategy terminates. FIX: `active` now
-- enumerates every EVER-ADOPTED strategy (including terminated), and the equal-split eligibility test
-- uses BOTH adopted_date and retired_date evaluated AS OF THE FLOW'S OWN DATE -- a fixed historical fact
-- a later termination can never revise.
WITH active AS (
  SELECT strategy_code AS s, adopted_date, retired_date
  FROM {{ source('state_external', 'strategy_roster') }}
  WHERE adopted_date IS NOT NULL
),
dep AS (
  SELECT a.s AS strategy,
    SUM(CASE
          WHEN cf.strategy = a.s THEN cf.amount
          WHEN cf.strategy IS NULL AND a.adopted_date <= cf.flow_date
               AND (a.retired_date IS NULL OR a.retired_date > cf.flow_date)
            THEN cf.amount / (SELECT COUNT(*) FROM active a2
                               WHERE a2.adopted_date <= cf.flow_date
                                 AND (a2.retired_date IS NULL OR a2.retired_date > cf.flow_date))
          ELSE 0 END) AS deposits
  FROM active a
  CROSS JOIN {{ source('events', 'cash_flows') }} cf
  GROUP BY a.s
),
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

-- Strategy NAV DRIP-dust exclusion (2026-08-02).
-- Project: stock-trading-498512. Apply AFTER 125_dust_excluded_from_twr.sql.
--
-- SUPERSEDES analytics.strategy_nav from bigquery/22_cash_flows.sql (see the SUPERSEDED marker left
-- there pointing here). This is the current single source of truth for this view. Keep 22 for
-- DR-rebuild history; do not re-apply its definition of this object in isolation.
--
-- WHAT THIS FIXES. bigquery/125 appended an audited is_dust column to analytics.position_lifecycle
-- and is filtered by every other reader: bigquery/125's own analytics.strategy_daily_returns rebuild,
-- and bigquery/126's state.position_reconciliation and state.strategy_probe_progress. This view's
-- `divs` CTE was the one reader left reading position_lifecycle unconditionally -- it summed
-- l.shares*m.dividend over every lot, dust included, so a DRIP-dust lot's sub-cent dividend income
-- flowed into dividends_held, then into nav, available_funds, and sizing_base_2pct. Verified before
-- writing this file: the sibling `open_pos` CTE reads state.current_positions, not
-- position_lifecycle, and current_positions is already dust-blind by construction (the 2026-07-20
-- D2a Step 0 $1 materiality gate never lets dust reach it) -- so `divs` was the ONLY leak in this
-- view, and this is the last known dust leak in the analytics layer.
--
-- THE FIX. Exactly one predicate added to the `divs` CTE: `AND NOT COALESCE(l.is_dust, FALSE)`, NULL
-- failing open as non-dust so a real lot can never be silently dropped. Nothing else in the view --
-- no other CTE, no formatting -- changed; the body below is byte-for-byte bigquery/22's current
-- definition with that one predicate inserted.
--
-- IMPACT, EXPECTED. Dust is $0.23 of position value total (bigquery/123's header); the dividend
-- contribution of that is sub-cent. Only strategy B ever held dust (B:IBM:2, B:HCA:2); D's
-- dividends_held (RTX/DIS legitimate DRIP on open positions, not dust) must not move at all, and no
-- strategy's deposits / realized_pnl / unrealized_pnl / deployed_mv should move -- those columns do
-- not derive from `divs`.
--
-- Companion decision record: events.decision_log entry_id d154fcec-d434-4c4a-8f27-89b16be6e166
-- (2026-08-02 correction, the same entry bigquery/123/124/125/126 cite).
--
-- Parallel-run dbt port updated in lockstep (scripts/dbt_parity.py compares live view output to the
-- dbt model, so these MUST land together): dbt/models/analytics/strategy_nav.sql.

CREATE OR REPLACE VIEW `stock-trading-498512.analytics.strategy_nav` AS
WITH active AS (
  -- EVERY strategy that has ever reached PROBE or ADOPTED (including terminated), with its
  -- capital-eligibility date + retired_date, so a termination never drops a strategy's history from
  -- the rollup and never revises a past flow's split, AND a PROBE-phase newcomer is included from its
  -- first PROBE trade onward, not only once it later clears the 30-trade gate into ADOPTED.
  SELECT strategy_code AS s, DATE(immutable_since, 'America/Denver') AS capital_eligible_date, retired_date
  FROM `stock-trading-498512.state.strategy_roster`
  WHERE immutable_since IS NOT NULL
),
dep AS (
  SELECT a.s AS strategy,
    SUM(CASE
          WHEN cf.strategy = a.s THEN cf.amount
          -- NULL-strategy (equal-split) flow: allocate only to strategies that were capital-eligible
          -- AS OF THAT FLOW'S DATE -- reached PROBE/ADOPTED on/before it, and not yet retired (or
          -- retired strictly after it) -- divided by the count of exactly those. This is a fixed
          -- historical fact: a strategy that terminates LATER can never change how an EARLIER flow was
          -- split.
          WHEN cf.strategy IS NULL AND a.capital_eligible_date <= cf.flow_date
               AND (a.retired_date IS NULL OR a.retired_date > cf.flow_date)
            THEN cf.amount / (SELECT COUNT(*) FROM active a2
                               WHERE a2.capital_eligible_date <= cf.flow_date
                                 AND (a2.retired_date IS NULL OR a2.retired_date > cf.flow_date))
          ELSE 0 END) AS deposits
  FROM active a
  CROSS JOIN `stock-trading-498512.events.cash_flows` cf
  GROUP BY a.s
),
realized AS (SELECT strategy, SUM(realized_pnl) AS realized_pnl FROM `stock-trading-498512.state.trade_fills_curated` GROUP BY strategy),
latest_close AS (SELECT ticker, close FROM `stock-trading-498512.state.daily_marks_curated`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY ticker ORDER BY mark_date DESC)=1),
open_pos AS (SELECT cp.strategy, SUM(cp.shares*lc.close) AS open_mv, SUM(cp.cost_basis) AS open_cost
  FROM `stock-trading-498512.state.current_positions` cp JOIN latest_close lc USING (ticker)
  WHERE cp.status='OPEN' GROUP BY cp.strategy),
divs AS (SELECT l.strategy, SUM(l.shares*m.dividend) AS dividends
  FROM `stock-trading-498512.analytics.position_lifecycle` l
  JOIN `stock-trading-498512.state.daily_marks_curated` m ON m.ticker=l.ticker AND m.dividend IS NOT NULL
   AND m.mark_date>=l.entry_date AND (l.exit_date IS NULL OR m.mark_date<=l.exit_date)
   AND NOT COALESCE(l.is_dust, FALSE)
  GROUP BY l.strategy)
SELECT d.strategy, d.deposits,
  ROUND(COALESCE(r.realized_pnl,0),2) AS realized_pnl,
  ROUND(COALESCE(o.open_mv-o.open_cost,0),2) AS unrealized_pnl,
  ROUND(COALESCE(dv.dividends,0),2) AS dividends_held,
  ROUND(COALESCE(o.open_mv,0),2) AS deployed_mv,
  ROUND(d.deposits+COALESCE(r.realized_pnl,0)+COALESCE(o.open_mv-o.open_cost,0)+COALESCE(dv.dividends,0),2) AS nav,
  ROUND(d.deposits+COALESCE(r.realized_pnl,0)+COALESCE(o.open_mv-o.open_cost,0)+COALESCE(dv.dividends,0)-COALESCE(o.open_mv,0),2) AS available_funds,
  -- LEGACY REFERENCE FIGURE as of Strategy.md Rev 43 / Experiment_Parameters.md rev 18 (owner directive
  -- 2026-07-28). The fixed 2%-per-position rule this column encoded is RETIRED: sizing is now a per-thesis
  -- AI-chosen Capital-at-Risk budget, so there is no single scalar that is "the" position size for a strategy.
  -- This column is RETAINED, unchanged in arithmetic, because (a) it is a pure display/reference read for the
  -- weekly report, strategy_scorecard and the ops dashboard -- NO order guard reads it any more (every
  -- 1.5x-sizing rail that did was stripped live by bigquery/104_strip_pretrade_rails.sql, 2026-07-22), and
  -- (b) 2%-of-NAV remains a useful order-of-magnitude yardstick for a typical thesis. DO NOT treat it as a
  -- cap, a budget, or an entitlement. There is NO binding numeric sizing control any more: the per-name
  -- (<=10% CaR) and per-strategy-deployed (<=75% CaR) envelopes were RETIRED by owner directive 2026-08-05
  -- (Experiment_Parameters.md rev 19), so sizing is bounded only by the per-thesis judgment plus its
  -- seven-factor justification and mandatory adversarial size attack -- none of which is precomputable here.
  -- That makes it MORE important, not less, that nothing reads this column as a limit.
  ROUND(0.02*(d.deposits+COALESCE(r.realized_pnl,0)+COALESCE(o.open_mv-o.open_cost,0)+COALESCE(dv.dividends,0)),2) AS sizing_base_2pct
FROM dep d LEFT JOIN realized r USING(strategy) LEFT JOIN open_pos o USING(strategy) LEFT JOIN divs dv USING(strategy);


-- VERIFICATION (run after apply).
-- NOTE: double-dash line comments only. A trailing C-style block comment placed after this file's last
-- CREATE causes permanent live-sql-parity drift -- never introduce one here.
--
-- 1. Only dividends_held (and columns derived from it: nav, available_funds, sizing_base_2pct) may
--    move, and only for strategy B, by a sub-cent amount:
--    SELECT * FROM `stock-trading-498512.analytics.strategy_nav` ORDER BY strategy;
--    -> diff against the pre-apply baseline: deposits / realized_pnl / unrealized_pnl / deployed_mv
--    unchanged for every strategy; strategy D unchanged in every column (D never held dust).
--
-- 2. The excluded amount is exactly the dust lots' dividend contribution:
--    SELECT l.strategy, SUM(l.shares*m.dividend) AS dust_dividends_excluded
--    FROM `stock-trading-498512.analytics.position_lifecycle` l
--    JOIN `stock-trading-498512.state.daily_marks_curated` m ON m.ticker=l.ticker
--      AND m.dividend IS NOT NULL AND m.mark_date>=l.entry_date
--      AND (l.exit_date IS NULL OR m.mark_date<=l.exit_date)
--    WHERE COALESCE(l.is_dust, FALSE)
--    GROUP BY l.strategy;
--    -> expect a single strategy B row, sub-cent.

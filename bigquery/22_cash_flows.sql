-- Event-source deposits/withdrawals — kills the hardcoded NAV literals (2026-07-03, self-improvement
-- audit B-1-exec). Project: stock-trading-498512. Apply after 04_analytics.sql + 21_strategy_vs_park.sql.
--
-- PROBLEM: the events-side NAV identity (analytics.strategy_nav), the §13 $1 cash tripwire baseline,
-- and the 2%-sizing base all rested on hardcoded literals CAST(9446.86) / CAST(1889.372 * 5 strategies)
-- in bigquery/04_analytics.sql. A real deposit/withdrawal would silently corrupt all three until a
-- human edited two SQL literals and shipped a PR — the most brittle manual-edit SPOF in the system.
--
-- FIX: events.cash_flows is the new append-only source; analytics.strategy_nav and
-- analytics.account_reconciliation are redefined HERE (not by editing 04_analytics.sql in place) so
-- the DR-rebuild order (apply 01..N in sequence) still lands on the corrected version — the same
-- pattern bigquery/18_stack_review_fixes.sql / 19_stack_review_fixes_2.sql use for retroactive fixes.
-- A future deposit/withdrawal is now a single INSERT (Operating_Protocols §13.C), not a code edit.

-- ===== events.cash_flows =====
CREATE TABLE IF NOT EXISTS `stock-trading-498512.events.cash_flows` (
  event_id STRING DEFAULT GENERATE_UUID(),
  flow_date DATE NOT NULL,
  flow_type STRING NOT NULL,   -- 'DEPOSIT' | 'WITHDRAWAL'
  amount NUMERIC NOT NULL,     -- signed: +deposit, -withdrawal
  strategy STRING,             -- NULL = equal-split across active strategies (standing methodology,
                                -- Operating_Protocols §13.C); non-NULL only if the operator states an
                                -- allocation for that specific flow.
  note STRING,
  source STRING DEFAULT 'D2',
  ingest_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  PRIMARY KEY (event_id) NOT ENFORCED
) PARTITION BY flow_date
OPTIONS(description='Append-only deposit/withdrawal ledger. Source of truth for total NAV deposits and the §13 cash-tripwire baseline — replaces the hardcoded literals in analytics.strategy_nav / analytics.account_reconciliation. A new flow is a single INSERT (Operating_Protocols §13.C), never a code edit.');

-- ===== Backfill: reproduce the existing $9,446.86 total exactly =====
-- Two documented components (events.decision_log): the account's initial funding (inception cycle
-- 2026-04-23) and a $2,500 supplemental deposit first observed as an IBKR Funds-on-Hold anomaly on
-- 2026-04-28 and confirmed as a deposit (not a settlement hold) on 2026-05-07
-- (Operating_Protocols.md: "the Apr 28->May 7 $2,500 precedent"). The initial-funding amount is
-- reconstructed as the residual (9446.86 - 2500.00 = 6946.86) against the total-deposits literal
-- that has been live since 04_analytics.sql's strategy_nav / account_reconciliation views — NOT
-- independently re-verified against a raw IBKR transfer ledger (no such connector tool exists here).
-- Both rows predate the first thesis-construction decision (2026-04-25), so the exact intra-window
-- seed date has no effect on any historical P&L/TWR calculation. The SUM=9446.86 assertion below
-- gates this backfill: if it fails, the literal removal further down must NOT be treated as applied.
INSERT INTO `stock-trading-498512.events.cash_flows` (flow_date, flow_type, amount, strategy, note, source)
SELECT * FROM UNNEST([
  STRUCT(DATE '2026-04-23' AS flow_date, 'DEPOSIT' AS flow_type, CAST(6946.86 AS NUMERIC) AS amount,
    CAST(NULL AS STRING) AS strategy,
    'Backfill: initial account funding, reconstructed as the residual after netting the documented 2026-05-07 $2,500 supplemental deposit against the pre-existing total-deposits literal (bigquery/04_analytics.sql). Exact seed date/amount not independently re-verified against a raw IBKR transfer ledger.' AS note,
    'backfill-2026-07-03' AS source),
  STRUCT(DATE '2026-05-07', 'DEPOSIT', CAST(2500.00 AS NUMERIC), CAST(NULL AS STRING),
    'Backfill: the $2,500 supplemental deposit documented in events.decision_log (Apr 28 Funds-on-Hold anomaly observed; confirmed as a deposit, not a settlement hold, on May 7 -- Operating_Protocols.md "Apr 28->May 7 $2,500 precedent").',
    'backfill-2026-07-03')
])
WHERE NOT EXISTS (SELECT 1 FROM `stock-trading-498512.events.cash_flows` WHERE source = 'backfill-2026-07-03');

-- ===== Reconciliation gate: SUM must equal the pre-existing 9446.86 literal exactly =====
-- If this ever returns a row, the backfill above does NOT reproduce history and the redefined views
-- below would shift the NAV/tripwire/sizing baseline on first read -- STOP and investigate before
-- relying on analytics.strategy_nav / analytics.account_reconciliation.
CREATE OR REPLACE VIEW `stock-trading-498512.state.cash_flows_backfill_check` AS
SELECT
  (SELECT ROUND(SUM(amount), 2) FROM `stock-trading-498512.events.cash_flows`) AS cash_flows_total,
  CAST(9446.86 AS NUMERIC) AS expected_total,
  (SELECT ROUND(SUM(amount), 2) FROM `stock-trading-498512.events.cash_flows`) = CAST(9446.86 AS NUMERIC) AS reconciled;

-- ===== analytics.strategy_nav — redefined to read events.cash_flows, not the hardcoded literal =====
-- (rev 2026-07-10 — Strategy Arsenal autonomy conversion, owner directive.) The per-strategy set + the
-- equal-split divisor are now ROSTER-DERIVED, not the bare ['A'..'E'] / 5 literals: the strategies are
-- enumerated from state.strategy_roster (is_active), and a NULL-strategy (equal-split) flow divides by
-- the AS-OF-FLOW-DATE active count — the strategies active AND adopted on/before that flow's date. This
-- is both a de-hardcode (roster membership is now versioned policy) AND a latent-correctness fix (the
-- old /5 kept splitting into 5 even after a termination). It NATURALLY returns 5 for the founding flows
-- (all five were adopted 2026-04-23), so no historical per-strategy attribution or 2%-sizing base moves.
-- A strategy-tagged flow still attributes to that strategy only. scripts/check_roster_consistency.py
-- asserts no bare ['A'..'E'] literal / no /5 divisor remains here. NOTE (apply order): this view now
-- reads state.strategy_roster (bigquery/35_strategy_arsenal.sql), so 35 must be applied BEFORE this file.
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.strategy_nav` AS
WITH active AS (
  -- roster-derived enumeration + each active strategy's adopted_date (rev 2026-07-10 — SISA).
  SELECT strategy_code AS s, adopted_date
  FROM `stock-trading-498512.state.strategy_roster`
  WHERE is_active
),
dep AS (
  SELECT a.s AS strategy,
    SUM(CASE
          WHEN cf.strategy = a.s THEN cf.amount
          -- NULL-strategy (equal-split) flow: allocate only to strategies active AND adopted on/before
          -- the flow date, divided by the count of exactly those (the as-of-flow-date active count).
          WHEN cf.strategy IS NULL AND a.adopted_date <= cf.flow_date
            THEN cf.amount / (SELECT COUNT(*) FROM active a2 WHERE a2.adopted_date <= cf.flow_date)
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
  GROUP BY l.strategy)
SELECT d.strategy, d.deposits,
  ROUND(COALESCE(r.realized_pnl,0),2) AS realized_pnl,
  ROUND(COALESCE(o.open_mv-o.open_cost,0),2) AS unrealized_pnl,
  ROUND(COALESCE(dv.dividends,0),2) AS dividends_held,
  ROUND(COALESCE(o.open_mv,0),2) AS deployed_mv,
  ROUND(d.deposits+COALESCE(r.realized_pnl,0)+COALESCE(o.open_mv-o.open_cost,0)+COALESCE(dv.dividends,0),2) AS nav,
  ROUND(d.deposits+COALESCE(r.realized_pnl,0)+COALESCE(o.open_mv-o.open_cost,0)+COALESCE(dv.dividends,0)-COALESCE(o.open_mv,0),2) AS available_funds,
  ROUND(0.02*(d.deposits+COALESCE(r.realized_pnl,0)+COALESCE(o.open_mv-o.open_cost,0)+COALESCE(dv.dividends,0)),2) AS sizing_base_2pct
FROM dep d LEFT JOIN realized r USING(strategy) LEFT JOIN open_pos o USING(strategy) LEFT JOIN divs dv USING(strategy);

-- ===== analytics.account_reconciliation — redefined to read events.cash_flows =====
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.account_reconciliation` AS
SELECT
  (SELECT ROUND(SUM(amount),2) FROM `stock-trading-498512.events.cash_flows`) AS total_deposits,
  (SELECT ROUND(SUM(realized_pnl),2) FROM `stock-trading-498512.state.trade_fills_curated`) AS strategy_realized_pnl,
  (SELECT ROUND(SUM(nav),2) FROM `stock-trading-498512.analytics.strategy_nav`) AS events_side_nav_total,
  (SELECT ROUND(SUM(deployed_mv),2) FROM `stock-trading-498512.analytics.strategy_nav`) AS deployed_total,
  (SELECT ROUND(SUM(available_funds),2) FROM `stock-trading-498512.analytics.strategy_nav`) AS undeployed_total;

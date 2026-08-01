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
  strategy STRING,             -- NULL = equal-split across active strategies (standing default,
                                -- Operating_Protocols §13.C); non-NULL for an operator-stated allocation
                                -- for that specific flow, OR (2026-07-19, AI_DECISION_REDESIGN.md §3
                                -- Redesign A) one row per active strategy carrying its AI-allocated
                                -- share at MEDIUM+ conviction (Operating_Protocols §16) — same
                                -- per-strategy-row shape the PENDING-NEWCOMER FIFO fill already uses.
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
-- (rev 2026-07-10 — Strategy Arsenal autonomy conversion, owner directive; rev 2026-07-10b — bug fix,
-- code-review finding #1.) The per-strategy set + the equal-split divisor are ROSTER-DERIVED, not the
-- bare ['A'..'E'] / 5 literals. BUG FIX: the original version enumerated `active` as CURRENTLY is_active
-- (state.strategy_roster.is_active), which meant (a) a terminated strategy's entire row -- realized P&L,
-- open positions, dividends -- silently vanished from this view and from analytics.account_reconciliation,
-- and (b) the equal-split divisor for HISTORICAL flows was recomputed off the CURRENT active count, so
-- terminating any founding strategy retroactively re-split the two founding NULL-strategy deposits among
-- fewer survivors, inflating every survivor's historical deposits/NAV/2%-sizing-base for money that
-- predated the termination. FIX: `active` now enumerates every EVER-ADOPTED strategy code (including
-- terminated ones, via `adopted_date IS NOT NULL`) so nothing drops out of the rollup, and the equal-split
-- eligibility test uses BOTH `adopted_date` and `retired_date` evaluated AS OF THE FLOW'S OWN DATE (a
-- fixed historical fact a later termination can never revise) instead of "is active right now". This
-- still returns 5 for the founding flows today (no strategy has terminated yet) and preserves the
-- SUM(deposits)==SUM(cash_flows) reconciliation identity unconditionally, for any roster size or
-- termination history. A strategy-tagged flow still attributes to that strategy only, forever (unaffected
-- by this fix). scripts/check_roster_consistency.py asserts no bare ['A'..'E'] literal / no /5 divisor
-- remains here. NOTE (apply order): this view reads state.strategy_roster (bigquery/35_strategy_arsenal.sql),
-- so 35 must be applied BEFORE this file.
--
-- rev 2026-07-15 (self-improvement audit, CONFIRMED GAP probe-stake-floor-prose-only): the
-- capital-eligibility gate below was keyed off `adopted_date` (set only on the ADOPTED transition,
-- which itself only fires after the 30-trade gate clears) instead of `immutable_since` (set at the
-- FIRST PROBE-or-ADOPTED transition — state.strategy_roster's own header comment). A live newcomer in
-- PROBE (the phase between roster registration and the 30-trade gate) therefore had NO row in this
-- view at all: zero deposits, zero NAV, zero sizing_base_2pct — a real structural deadlock, since a
-- PROBE strategy needs sizing_base_2pct to craft its first sized trade, needs 30 closed trades to
-- clear the gate, and needs the gate to clear before adopted_date is ever set. Verified live
-- (2026-07-15) that swapping to `DATE(immutable_since, 'America/Denver')` produces a BYTE-IDENTICAL
-- result for all 5 current strategies (EXCEPT DISTINCT against the live view returned zero rows) —
-- immutable_since equals adopted_date for the founding batch (seeded straight into ADOPTED, no
-- separate PROBE row), so this is a zero-behavioral-change-today fix that only changes behavior for
-- a future PROBE strategy.
-- The CTE's own column alias is renamed `capital_eligible_date` (no longer synonymous with
-- "adopted_date") for clarity; `retired_date`/every other column is unchanged.
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
  -- cap, a budget, or an entitlement. The binding sizing controls are now the per-name (<=10% CaR) and
  -- per-strategy-deployed (<=75% CaR) envelopes, which are book-level aggregates over open positions and
  -- are therefore checked at trade-craft time against the live book, not precomputed here.
  ROUND(0.02*(d.deposits+COALESCE(r.realized_pnl,0)+COALESCE(o.open_mv-o.open_cost,0)+COALESCE(dv.dividends,0)),2) AS sizing_base_2pct
FROM dep d LEFT JOIN realized r USING(strategy) LEFT JOIN open_pos o USING(strategy) LEFT JOIN divs dv USING(strategy);

-- ===== analytics.account_reconciliation — redefined to read events.cash_flows =====
-- SUPERSEDED LIVE by bigquery/93_park_accounting.sql — current single source of truth for
-- this object. Kept here, unmodified, for DR-rebuild apply-in-order reference only.
-- DO NOT re-apply this CREATE statement live in isolation. bigquery/93 preserves every column
-- below byte-identical and adds park_unrealized + residual_after_park (PARK_ROUTER_DESIGN.md v2 §9,
-- the AI Park Allocator's vehicle-aware reconciliation).
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.account_reconciliation` AS
SELECT
  (SELECT ROUND(SUM(amount),2) FROM `stock-trading-498512.events.cash_flows`) AS total_deposits,
  (SELECT ROUND(SUM(realized_pnl),2) FROM `stock-trading-498512.state.trade_fills_curated`) AS strategy_realized_pnl,
  (SELECT ROUND(SUM(nav),2) FROM `stock-trading-498512.analytics.strategy_nav`) AS events_side_nav_total,
  (SELECT ROUND(SUM(deployed_mv),2) FROM `stock-trading-498512.analytics.strategy_nav`) AS deployed_total,
  (SELECT ROUND(SUM(available_funds),2) FROM `stock-trading-498512.analytics.strategy_nav`) AS undeployed_total;

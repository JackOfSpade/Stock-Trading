-- bigquery/54_park_policy_voo_cutover.sql
-- Owner directive 2026-07-15: idle capital parking switches from SGOV to VOO. This file lands the
-- SCHEMA/PLUMBING for that switch WITHOUT flipping it live -- the cutover activates only when the
-- owner's manual IBKR "sell all SGOV, buy VOO" transfer actually executes and its two matching
-- events.parking_events rows + the events.park_policy_changes VOO row are inserted (a separate,
-- later, one-time live INSERT -- see bigquery/55_park_policy_voo_seed.sql's header and the runbook
-- entry this migration's decision_log row points to). Every statement below is either purely
-- additive or verified behavior-preserving against TODAY's live state (park vehicle = SGOV, zero
-- VOO parking_events rows) -- re-running this file is idempotent (CREATE OR REPLACE / IF NOT EXISTS
-- / guarded INSERT throughout) and safe to apply before the manual transfer.
--
-- SCOPE NOTE (do not extend without an explicit owner directive): this migration touches the
-- PARKING VEHICLE only. It does NOT touch perf.strategy_daily.excess_vs_sgov, perf.kill_flags,
-- state.strategy_retirement_candidacy, state.strategy_paper_readiness, analytics.sgov_daily_return,
-- analytics.nogo_counterfactual, or ops.sp_recompute_engine -- SGOV remains the sole sanctioned
-- kill/gate benchmark (bigquery/39_beta_adjusted_alpha.sql, bigquery/46_weekly_benchmarks.sql
-- headers). SGOV's own daily mark ingestion (Claude_Task_Plan.md D2a) must keep running forever,
-- park-vehicle switch or not, because that benchmark still needs it.
--
-- DESIGN: event-sourced cutover (events.park_policy_changes), NOT a hardcoded cutover-date CASE.
-- The owner's manual transfer date is unknown at authoring time; a hardcoded date would need a
-- follow-up SQL edit the moment the transfer happens, reinstating exactly the "hardcoded-literal
-- SPOF" 22_cash_flows.sql already eliminated once for cash flows. Instead, state.park_policy_current
-- always reflects the LATEST row in events.park_policy_changes, so the actual live INSERT on the
-- transfer day (not a code deploy) is what flips every downstream view/function.
--
-- Deliberately DOES NOT widen the SGOV-only defensive filters (ticker != 'SGOV' in
-- analytics.position_lifecycle, analytics.tax_lots, analytics.execution_quality,
-- state.open_positions_summary, analytics.strategy_vs_park's comm CTE, etc.) to also exclude VOO.
-- SGOV could never legitimately be a strategy's own directional position, so a blanket exclusion was
-- always safe defense-in-depth -- VOO is an ordinary, popular, liquid ETF a strategy COULD
-- legitimately trade as a real thesis (none does today, confirmed via repo-wide search, but nothing
-- prevents it going forward). Blanket-excluding VOO there would silently drop a future strategy's
-- real P&L from the deployed-TWR engine -- a silent correctness bug, not a crash, with no test to
-- catch it. Instead this file relies on the NEW detective test
-- dbt/tests/assert_no_park_ticker_in_strategy_positions.sql (same commit) to catch a leaked
-- park-sweep fill for EITHER vehicle after the fact, the way the 2026-06-30 SGOV leak (RUNBOOK §29)
-- was eventually caught -- without ever silently discarding real strategy data.
--
-- Apply after bigquery/01_schema.sql (events.parking_events), 13_sgov_reconciliation.sql (the views
-- this supersedes), 23_trading_control.sql (analytics.fn_order_guard), 03_twr_engine.sql
-- (state.daily_marks_curated). Apply via the BigQuery MCP execute_sql, in order top to bottom.

-- ===== events.parking_events — add a ticker column, backfill history as SGOV =====
-- Every one of the 22 live rows (2026-04-23 -> 2026-07-10, confirmed live) is genuinely SGOV --
-- "history before the cutover date was genuinely SGOV; do not rewrite it" (owner directive) is
-- satisfied by a straight backfill, not a date-gated CASE. No DEFAULT clause (deliberately) -- a
-- static default can't be correct both before and after cutover; every future INSERT (the D2a
-- sweep/cover step) must pass ticker explicitly from state.park_policy_current going forward.
-- Two-statement split (ADD COLUMN, then a separate UPDATE) -- NOT because this hits BigQuery's
-- defaulted-ADD-COLUMN limitation (bigquery/53_curated_view_tiebreak_fix.sql; this ADD COLUMN has no
-- DEFAULT so that specific limitation doesn't apply here) but because a bare ADD COLUMN + backfill
-- is simplest as two plain statements and mirrors that file's now-established two-statement pattern
-- for schema changes on an existing live table.
ALTER TABLE `stock-trading-498512.events.parking_events`
  ADD COLUMN IF NOT EXISTS ticker STRING;

UPDATE `stock-trading-498512.events.parking_events`
SET ticker = 'SGOV'
WHERE ticker IS NULL;

ALTER TABLE `stock-trading-498512.events.parking_events`
  SET OPTIONS (description = 'Idle-capital parking activity for per-strategy cash attribution (§13 tripwire). ticker (added 2026-07-15) distinguishes which vehicle a row parked into -- SGOV historically, per state.park_policy_current going forward (owner directive: parking vehicle switches to VOO). All rows before the 2026-07-15 migration are backfilled ticker=SGOV, which is correct -- the account genuinely held nothing else.');

-- ===== events.park_policy_changes — the event-sourced "what vehicle is idle cash parked in, as of
-- when" log. One row per policy change; state.park_policy_current always reads the latest. =====
CREATE TABLE IF NOT EXISTS `stock-trading-498512.events.park_policy_changes` (
  event_id STRING DEFAULT GENERATE_UUID(),
  event_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  effective_date DATE NOT NULL,
  vehicle STRING NOT NULL,     -- 'SGOV' | 'VOO' -- the ticker new idle cash sweeps into as of effective_date
  note STRING,
  PRIMARY KEY (event_id) NOT ENFORCED
) OPTIONS(description='Event-sourced idle-capital parking-vehicle policy. state.park_policy_current reads the latest row by effective_date. Founding row (SGOV, 2026-04-17) seeded below; the VOO row is inserted LATER, live, on the actual date of the owner\'s manual IBKR SGOV->VOO transfer -- never hardcoded here (owner directive 2026-07-15).');

-- Founding row: SGOV has been the park vehicle since deployed capital began (2026-04-17, matching
-- events.daily_marks' SGOV coverage start). Guarded so re-applying this file is a no-op once seeded.
INSERT INTO `stock-trading-498512.events.park_policy_changes` (effective_date, vehicle, note)
SELECT * FROM (
  SELECT DATE '2026-04-17' AS effective_date, 'SGOV' AS vehicle,
         'Founding park policy -- SGOV was the idle-capital vehicle from the start of this account\'s trading history. Seeded by bigquery/54_park_policy_voo_cutover.sql.' AS note
)
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.events.park_policy_changes` WHERE vehicle = 'SGOV' AND effective_date = DATE '2026-04-17'
);

-- ===== state.park_policy_current — the single row every vehicle-aware consumer reads =====
-- BUG FIX (2026-07-15, caught in post-implementation review, not yet triggered live): the original
-- version ordered by `effective_date DESC` (a hand-typed, operator-supplied TARGET date -- see
-- bigquery/56's <TRANSFER_DATE> placeholder), not by insertion/transition time. This repo has an
-- established house rule against exactly that pattern (bigquery/01_schema.sql's queue_events.due_date
-- discussion: "the discriminator must be the TRANSITION time... ordering by [a target date] lets an
-- older 'created' event outrank a later one -- use event_ts DESC, the actual INSERT-time transition
-- order"). Under the original ORDER BY, a forward-dated or mistyped effective_date on the real VOO
-- cutover INSERT would make that row "current" immediately, ahead of the operator's intent, while a
-- correctly-dated-but-later-inserted correction row would lose the tiebreak. Ordering by event_ts DESC
-- instead means whichever row was actually inserted last always wins, matching this file's own stated
-- design goal ("the actual live INSERT on the transfer day... is what flips every downstream view") and
-- requiring no change to bigquery/55/56 or any caller. effective_date is kept as a plain descriptive
-- column (still NOT NULL, still owner-supplied for the audit trail) -- it is simply no longer the
-- selection key.
-- SUPERSEDED LIVE by bigquery/220_park_two_sleeve_book.sql (2026-09-04) — current single source of
-- truth for this object. 220 generalizes the park book from ONE vehicle to TWO SLEEVES with a
-- defensive fraction f: events.park_policy_changes gains target_f_pct / risk_sleeve /
-- defensive_sleeve (additive, legacy rows map VOO->f=0 and anything-else->f=100), and
-- is_policy_vehicle is REDEFINED as `target_weight_pct > 0` so §13.E's stranded-leg rule stops
-- treating the second sleeve as a leg to liquidate. Kept here, unmodified, for DR-rebuild
-- apply-in-order reference only.
-- DO NOT re-apply this CREATE statement live in isolation.
CREATE OR REPLACE VIEW `stock-trading-498512.state.park_policy_current` AS
SELECT vehicle, effective_date, note
FROM `stock-trading-498512.events.park_policy_changes`
QUALIFY ROW_NUMBER() OVER (ORDER BY event_ts DESC) = 1;

-- ===== state.park_position / state.park_position_current — vehicle-aware successor to
-- state.sgov_position. GROUP BY ticker so a SGOV-era share/cash total is never summed together with
-- a VOO-era one (different price scales -- ~$100/sh SGOV vs ~$560/sh VOO -- summing shares across
-- vehicles would be meaningless). Same signed-rollup logic as state.sgov_position
-- (13_sgov_reconciliation.sql), generalized off the new ticker column. =====
CREATE OR REPLACE VIEW `stock-trading-498512.state.park_position` AS
SELECT
  ticker,
  SUM(CASE action WHEN 'BUY' THEN shares
                  WHEN 'DIVIDEND_REINVEST' THEN shares
                  WHEN 'RECON_ADJUST' THEN shares  -- signed delta (+/-)
                  WHEN 'SELL' THEN -shares
                  ELSE 0 END)                                              AS events_shares,
  SUM(IF(action = 'BUY',  shares, 0))                                      AS buy_shares,
  SUM(IF(action = 'SELL', shares, 0))                                      AS sell_shares,
  SUM(IF(action = 'DIVIDEND_REINVEST', shares, 0))                         AS drip_shares,
  ROUND(SUM(CASE action
              WHEN 'BUY'  THEN -(gross + COALESCE(commission, 0))
              WHEN 'SELL' THEN  (gross - COALESCE(commission, 0))
              ELSE 0 END), 4)                                             AS events_park_net_cash,
  ROUND(SUM(COALESCE(commission, 0)), 4)                                  AS parking_commissions_total,
  COUNT(*)                                                                 AS parking_event_count,
  MAX(action_date)                                                         AS last_parking_date
FROM `stock-trading-498512.events.parking_events`
GROUP BY ticker;

-- BUG FIX (2026-07-15, caught in post-implementation review, not yet triggered live): the original
-- version JOINed FROM park_position (only produces a row per ticker that already has
-- events.parking_events history) INTO park_policy_current -- a default INNER join. On the real cutover,
-- state.park_policy_current flips to VOO via a single INSERT (bigquery/56 step 1) that lands BEFORE the
-- matching SGOV-sell/VOO-buy legs are recorded into events.parking_events (bigquery/56 step 2, gated on
-- real IBKR fill confirmations arriving) -- during that gap, or for longer if step 2 lags, park_position
-- has no VOO group yet, so the INNER JOIN produced ZERO rows. state.park_reconciliation is built
-- directly on this view, so it went from "flags a discrepancy" to "silently vanishes" at exactly the
-- moment (a fresh cutover) it matters most -- reintroducing the failure mode the frozen
-- state.sgov_reconciliation view (below, and originally bigquery/13_sgov_reconciliation.sql) explicitly
-- uses a LEFT JOIN to avoid ("this view feeds the §13 hard-stop, so it must never silently return zero
-- rows"). Fixed by driving FROM the always-exactly-one-row park_policy_current and LEFT JOINing OUT to
-- park_position, with COALESCE(...,0) on the numeric columns -- this guarantees exactly one output row
-- naming the current vehicle even when it has zero recorded events yet, with 0s (not NULLs) making the
-- "nothing recorded for this vehicle" state an explicit, visible discrepancy rather than an absent view.
--
-- HISTORICAL (no longer the current truth — see the SUPERSEDED LIVE banner above): this object was
-- first superseded by bigquery/92_park_allocator.sql, which was then the single source of truth for this
-- object. bigquery/92 generalizes this single-vehicle-only definition to one row per above-dust
-- ticker in state.park_position (plus is_policy_vehicle), for the multi-instrument park menu
-- (PARK_ROUTER_DESIGN.md), while PRESERVING this view's zero-row-gap LEFT-JOIN fix and every column
-- below. Kept here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT re-apply this
-- CREATE statement live in isolation — it would silently drop is_policy_vehicle and any residual
-- switch-in-progress ticker row bigquery/92 added.
-- SUPERSEDED LIVE by bigquery/220_park_two_sleeve_book.sql (2026-09-04) — current single source of
-- truth for this object. 220 generalizes the park book from ONE vehicle to TWO SLEEVES with a
-- defensive fraction f: events.park_policy_changes gains target_f_pct / risk_sleeve /
-- defensive_sleeve (additive, legacy rows map VOO->f=0 and anything-else->f=100), and
-- is_policy_vehicle is REDEFINED as `target_weight_pct > 0` so §13.E's stranded-leg rule stops
-- treating the second sleeve as a leg to liquidate. Kept here, unmodified, for DR-rebuild
-- apply-in-order reference only.
-- DO NOT re-apply this CREATE statement live in isolation.
CREATE OR REPLACE VIEW `stock-trading-498512.state.park_position_current` AS
SELECT
  cur.vehicle                                AS ticker,
  COALESCE(pp.events_shares, 0)               AS events_shares,
  COALESCE(pp.buy_shares, 0)                  AS buy_shares,
  COALESCE(pp.sell_shares, 0)                 AS sell_shares,
  COALESCE(pp.drip_shares, 0)                 AS drip_shares,
  COALESCE(pp.events_park_net_cash, 0)        AS events_park_net_cash,
  COALESCE(pp.parking_commissions_total, 0)   AS parking_commissions_total,
  COALESCE(pp.parking_event_count, 0)         AS parking_event_count,
  pp.last_parking_date                        AS last_parking_date
FROM `stock-trading-498512.state.park_policy_current` cur
LEFT JOIN `stock-trading-498512.state.park_position` pp ON pp.ticker = cur.vehicle;

-- ===== state.park_reconciliation — vehicle-aware successor to state.sgov_reconciliation, always
-- reconciling whichever ticker is the CURRENT park policy (D2 Step 0 / §13.A reads this going
-- forward instead of the frozen state.sgov_reconciliation below). =====
--
-- HISTORY (no longer the current-truth claim — see the live banner below): bigquery/92_park_allocator.sql
-- generalizes this to one row per state.park_position_current ticker (plural when a switch is
-- converging) and marks each against COALESCE(daily_marks_curated, signal_marks_curated), while
-- PRESERVING every column name below (park_ticker, events_park_shares, ..., park_mark_fresh,
-- checked_at) and adding only is_policy_vehicle. 92 has since itself been superseded (see below).
--
-- SUPERSEDED LIVE by bigquery/173_freshness_cadence_aware.sql — current single source of truth for
-- this object (supersedes bigquery/92 above in turn). 173 repoints park_mark_fresh from
-- last_trading_day to marks_due_through, so a Sun-Thu-daily-tier weekend gap no longer reads as
-- staleness; every other column is unchanged. Kept here, unmodified, for DR-rebuild apply-in-order
-- reference only. DO NOT re-apply this CREATE statement live in isolation.
CREATE OR REPLACE VIEW `stock-trading-498512.state.park_reconciliation` AS
WITH p AS (SELECT * FROM `stock-trading-498512.state.park_position_current`),
mark AS (
  SELECT dmc.close AS park_close, dmc.mark_date AS park_mark_date
  FROM `stock-trading-498512.state.daily_marks_curated` dmc, p
  WHERE dmc.ticker = p.ticker
  QUALIFY ROW_NUMBER() OVER (ORDER BY dmc.mark_date DESC) = 1
)
SELECT
  p.ticker AS park_ticker,
  p.events_shares AS events_park_shares,
  p.buy_shares, p.sell_shares, p.drip_shares,
  p.events_park_net_cash,
  p.parking_commissions_total,
  mark.park_close,
  mark.park_mark_date,
  ROUND(p.events_shares * mark.park_close, 2)                              AS events_park_market_value,
  COALESCE(mark.park_mark_date >= (SELECT last_trading_day FROM `stock-trading-498512.state.trading_day_today`),
           FALSE)                                                          AS park_mark_fresh,
  CURRENT_TIMESTAMP()                                                      AS checked_at
FROM p LEFT JOIN mark ON TRUE;

-- ===== state.sgov_position / state.sgov_reconciliation — SUPERSEDED, frozen to SGOV-only history =====
-- Adding an explicit ticker filter freezes these two views as the permanent SGOV-era historical
-- record. BEHAVIOR-PRESERVING TODAY: every parking_events row is still ticker='SGOV' until the
-- owner's manual transfer, so this WHERE clause changes nothing live right now -- it only prevents a
-- FUTURE VOO parking_events row from silently blending into what these SGOV-named views report.
-- D2 Step 0 / Operating_Protocols.md §13.A should read state.park_reconciliation (above) going
-- forward; these two names are kept working, unrenamed, so any reference this migration's authors
-- missed does not silently break.
-- ORPHAN-DOC (self-improvement audit 2026-07-16 cleanup pass): frozen post-VOO-cutover, no runtime
-- reader by design — confirmed via Operating_Protocols.md §13 and ops/RUNBOOK.md's cutover notes
-- (2026-07-15). Not a candidate for removal; it's the permanent pre-cutover SGOV-only historical
-- record, same "retain, don't delete" convention as elsewhere in this repo.
CREATE OR REPLACE VIEW `stock-trading-498512.state.sgov_position` AS
SELECT
  events_shares AS events_sgov_shares, buy_shares, sell_shares, drip_shares,
  events_park_net_cash, parking_commissions_total, parking_event_count, last_parking_date
FROM `stock-trading-498512.state.park_position`
WHERE ticker = 'SGOV';

CREATE OR REPLACE VIEW `stock-trading-498512.state.sgov_reconciliation` AS
WITH p AS (SELECT * FROM `stock-trading-498512.state.sgov_position`),
mark AS (
  SELECT close AS sgov_close, mark_date AS sgov_mark_date
  FROM `stock-trading-498512.state.daily_marks_curated`
  WHERE ticker = 'SGOV'
  QUALIFY ROW_NUMBER() OVER (ORDER BY mark_date DESC) = 1
)
SELECT
  p.events_sgov_shares, p.buy_shares, p.sell_shares, p.drip_shares,
  p.events_park_net_cash, p.parking_commissions_total,
  mark.sgov_close, mark.sgov_mark_date,
  ROUND(p.events_sgov_shares * mark.sgov_close, 2)                         AS events_sgov_market_value,
  COALESCE(mark.sgov_mark_date >= (SELECT last_trading_day FROM `stock-trading-498512.state.trading_day_today`),
           FALSE)                                                          AS sgov_mark_fresh,
  CURRENT_TIMESTAMP()                                                      AS checked_at
FROM p LEFT JOIN mark ON TRUE;

-- ===== analytics.fn_order_guard — p_is_sgov renamed p_is_park; price band now VEHICLE-CONDITIONAL,
-- read live from state.park_policy_current, so this function needs NO further code change on the
-- day the park vehicle actually cuts over =====
-- BEHAVIOR-PRESERVING TODAY: state.park_policy_current resolves to 'SGOV' until the owner's VOO row
-- lands, so every p_is_park=TRUE call gets EXACTLY the same 0.2% band + 1.10x-NAV backstop it gets
-- today. Only the PARAMETER NAME changes (p_is_sgov -> p_is_park) -- arity/position are UNCHANGED,
-- so every existing positional call site (Claude_Task_Plan.md's D2/D2a/D3/M4/Q4/A1/A3 order-guard
-- steps, dbt/tests/assert_fn_order_guard_fire_drill.sql, ops.sp_fire_drill_order_guard) keeps working
-- with no edit required for correctness (prose references to "is_sgov" are updated for accuracy in
-- the same commit as a courtesy, not because the call shape changed).
-- SGOV's 0.2% band is calibrated to a near-zero-volatility T-bill fund; a real equity index (VOO)
-- needs the wider 0.5% equity band -- reusing 0.2% for VOO park orders would cause spurious guard
-- rejections on ordinary VOO price moves. The 1.10x-NAV notional backstop is vehicle-agnostic
-- (a plausible-magnitude check, not a volatility check) and is unchanged for either vehicle.
--
-- SUPERSEDED LIVE by bigquery/104_strip_pretrade_rails.sql (2026-07-22 — all liquidity + sizing
-- pre-trade rails stripped; only market-only + malformed-input sanity remain). 104 is the CURRENT single
-- source of truth for this object. Lineage: 104 superseded bigquery/103_adaptive_shortfall_budget.sql
-- (2026-07-22 φ·α adaptive shortfall budget, now retired), which superseded
-- bigquery/100_market_only_order_guard.sql (2026-07-21 owner directive — market-only + expected-
-- implementation-shortfall liquidity gate), which in turn superseded bigquery/99, which had superseded
-- this definition. Kept here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT re-apply
-- this CREATE OR REPLACE TABLE FUNCTION statement live in isolation — doing so would revert to the retired
-- park price band and reintroduce every pre-trade rail 104 removed.
CREATE OR REPLACE TABLE FUNCTION `stock-trading-498512.analytics.fn_order_guard`(
  p_strategy STRING, p_side STRING, p_qty NUMERIC, p_limit_price NUMERIC, p_last_price NUMERIC, p_is_park BOOL
) AS (
  WITH base AS (
    SELECT
      p_qty * p_limit_price AS notional,
      (SELECT sizing_base_2pct FROM `stock-trading-498512.analytics.strategy_nav` WHERE strategy = p_strategy) AS sizing_base,
      (SELECT nav FROM `stock-trading-498512.state.account_latest`) AS account_nav,
      SAFE_DIVIDE(ABS(p_limit_price - p_last_price), NULLIF(p_last_price, 0)) AS pct_off_last,
      COALESCE((SELECT vehicle FROM `stock-trading-498512.state.park_policy_current`), 'SGOV') AS park_vehicle
  ),
  checks AS (
    SELECT
      ARRAY_CONCAT(
        IF(p_qty IS NULL OR p_qty <= 0, ['qty must be > 0'], []),
        IF(p_limit_price IS NULL OR p_limit_price <= 0, ['limit_price must be > 0'], []),
        IF(NOT p_is_park AND base.sizing_base IS NOT NULL AND base.notional > 1.5 * base.sizing_base,
           [FORMAT('notional %.2f exceeds 1.5x sizing_base_2pct (%.2f) for strategy %s', base.notional, 1.5 * base.sizing_base, p_strategy)], []),
        IF(NOT p_is_park AND base.notional > 50,
           [FORMAT('notional %.2f exceeds the $50 absolute backstop (current book size)', base.notional)], []),
        IF(NOT p_is_park AND base.pct_off_last IS NOT NULL AND base.pct_off_last > 0.005,
           [FORMAT('limit %.4f is %.2f%% off last %.4f (equity band is 0.5%%)', p_limit_price, base.pct_off_last * 100, p_last_price)], []),
        IF(p_is_park AND base.park_vehicle = 'SGOV' AND base.pct_off_last IS NOT NULL AND base.pct_off_last > 0.002,
           [FORMAT('park (SGOV) limit %.4f is %.2f%% off last %.4f (SGOV band is 0.2%%)', p_limit_price, base.pct_off_last * 100, p_last_price)], []),
        IF(p_is_park AND base.park_vehicle != 'SGOV' AND base.pct_off_last IS NOT NULL AND base.pct_off_last > 0.005,
           [FORMAT('park (%s) limit %.4f is %.2f%% off last %.4f (non-SGOV park band is 0.5%%)', base.park_vehicle, p_limit_price, base.pct_off_last * 100, p_last_price)], []),
        IF(p_is_park AND base.account_nav IS NOT NULL AND base.notional > 1.10 * base.account_nav,
           [FORMAT('park notional %.2f exceeds 1.10x the latest known account NAV (%.2f) — implausible magnitude for a sweep/cover', base.notional, 1.10 * base.account_nav)], [])
      ) AS reasons
    FROM base
  )
  SELECT ARRAY_LENGTH(reasons) = 0 AS passed, reasons
  FROM checks
);

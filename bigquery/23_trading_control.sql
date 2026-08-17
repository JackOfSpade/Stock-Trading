-- Safety floor — machine-readable trading-enable gate + deterministic pre-craft order guard
-- (2026-07-03, self-improvement audit B-1-obs / B-2-exec / NEW-1 / NEW-2 / NEW-3). Project:
-- stock-trading-498512. Apply after 10_observability.sql (state.system_health) + 22_cash_flows.sql
-- (analytics.strategy_nav) + 14_weekly_report.sql (ops.account_snapshot).
--
-- WHY THIS EXISTS: every existing safety signal (state.system_health.all_green, perf.kill_flags,
-- state.position_reconciliation) is a health READOUT — nothing in the order-staging path (D2/D3/
-- M4/Q4/A1/A3) is REQUIRED to read it before crafting an order, and nothing automatically halts
-- staging on an anomaly. This file makes "halt all trading" a fact a routine mechanically obeys
-- (ops.sp_assert_trading_enabled, called FATAL before staging — same pattern as
-- ops.sp_assert_deps, 12_cadence_monitor.sql), plus a deterministic pre-craft risk envelope
-- (analytics.fn_order_guard) so an LLM arithmetic/attribution slip cannot silently produce a
-- fat-fingered or oversized order. Trip conditions deliberately key on signals that CAN fire on an
-- 8-closed-trade, one-month-old book (freshness, critical alerts, connector/position drift, a
-- book-level NAV drawdown) — NOT on perf.kill_flags, whose thresholds (unit value >=2, 756 deployed
-- days) are mathematically unreachable at this age. That is the difference between a breaker that
-- can actually fire and theater.
--
-- A false trip only costs opportunity (staging pauses for a day), never capital — the human confirm
-- tap remains the sole execute authority regardless (create_order_instruction cannot execute,
-- Operating_Protocols.md). Manual override: `INSERT INTO ops.trading_control (halt_all, mode, reason,
-- set_by) VALUES (FALSE, 'manual', '<reason>', 'operator')` to clear an auto-halt, or `(TRUE, ...)`
-- to halt manually. An AUTO halt should NOT be cleared by a bare flip back to FALSE without a human
-- reviewing why it fired first — see the note on state.trading_control_latest below.

-- ===== ops.trading_control — append-only halt-all control (single reconciled schema) =====
CREATE TABLE IF NOT EXISTS `stock-trading-498512.ops.trading_control` (
  control_id STRING DEFAULT GENERATE_UUID(),
  control_ts TIMESTAMP DEFAULT CURRENT_TIMESTAMP(),
  halt_all BOOL NOT NULL,
  mode STRING NOT NULL,        -- 'manual' (operator-set) | 'auto' (a monitor/breaker set it)
  reason STRING,
  set_by STRING,               -- routine id, or 'operator'
  PRIMARY KEY (control_id) NOT ENFORCED
) PARTITION BY DATE(control_ts)
OPTIONS(description='Append-only halt-all control. Latest row by control_ts wins (state.trading_control_latest). Seeded halt_all=FALSE so the gate starts in a known-open state.');

-- Seed exactly once so the table is never empty (state.trading_enabled below assumes >=1 row).
INSERT INTO `stock-trading-498512.ops.trading_control` (halt_all, mode, reason, set_by)
SELECT FALSE, 'manual', 'Initial seed — trading-enable gate activated (self-improvement audit B-1-obs, 2026-07-03).', 'backfill-2026-07-03'
FROM (SELECT 1)
WHERE NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.trading_control`);

-- Human/dashboard-facing latest-control view. NOTE (asymmetric halt/resume, risk-officer critique):
-- an AUTO halt (mode='auto') should be reviewed by a human before clearing, not silently cleared by
-- the next green tick of whatever tripped it — that discipline lives in the RUNBOOK / operator
-- procedure (an auto halt is cleared by an explicit manual INSERT, never by another automated row),
-- not enforced in SQL here (SQL cannot distinguish "a human read this" from "a script did").
CREATE OR REPLACE VIEW `stock-trading-498512.state.trading_control_latest` AS
SELECT control_id, control_ts, halt_all, mode, reason, set_by
FROM `stock-trading-498512.ops.trading_control`
QUALIFY ROW_NUMBER() OVER (ORDER BY control_ts DESC) = 1;

-- ===== state.book_drawdown_watch — book-level NAV drawdown breaker input =====
-- Self-bootstrapping (ALWAYS exactly one row, even with zero/sparse ops.account_snapshot history —
-- via aggregates, not QUALIFY-filtered rows, so it can never silently vanish and break the trading_
-- enabled join). Fewer than 5 snapshots -> not enough peak history to trust; defaults to no breach.
-- -15% is a first-cut POLICY INVARIANT (not fitted to the trade sample) meant to be reviewed by the
-- owner as the book grows; see Experiment_Parameters.md for the versioned record of this constant.
--
-- snapshot_stale (ITEM 16, self-improvement audit 2026-07-11): unlike state.freshness's
-- marks_fresh/engine_fresh, this view previously had NO recency check on ops.account_snapshot's latest
-- row — a stalled D2a (the sole writer) would leave this breaker silently trusting arbitrarily old data
-- forever, with nothing surfacing the staleness itself. snapshot_stale = latest snapshot older than the
-- current last_trading_day; folded into state.trading_enabled below so a stalled D2a visibly and
-- mechanically fails the book-level breaker closed instead of silently trusting stale data. Defense-in-
-- depth: D2a's own outage already trips cadence_watch's missed_run critical (which independently forces
-- state.system_health.all_green=FALSE and thus trading_enabled=FALSE) — this is the direct, same-signal
-- path so the drawdown breaker's own staleness is legible without having to reason through that indirection.
CREATE OR REPLACE VIEW `stock-trading-498512.state.book_drawdown_watch` AS
WITH snaps AS (
  SELECT snapshot_date, nav
  FROM `stock-trading-498512.ops.account_snapshot`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY snapshot_date ORDER BY ingest_ts DESC) = 1
),
peaked AS (
  SELECT snapshot_date, nav,
    MAX(nav) OVER (ORDER BY snapshot_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS peak_nav
  FROM snaps
),
agg AS (
  SELECT COUNT(*) AS n_snapshots,
    ARRAY_AGG(STRUCT(snapshot_date, nav, peak_nav) ORDER BY snapshot_date DESC LIMIT 1)[SAFE_OFFSET(0)] AS latest
  FROM peaked
),
ltd AS (SELECT last_trading_day FROM `stock-trading-498512.state.trading_day_today`)
SELECT
  agg.latest.snapshot_date AS as_of_date,
  agg.latest.nav AS current_nav,
  agg.latest.peak_nav AS peak_nav,
  SAFE_DIVIDE(agg.latest.nav, agg.latest.peak_nav) - 1 AS drawdown_from_peak,
  agg.n_snapshots,
  (agg.n_snapshots > 0 AND agg.latest.snapshot_date < ltd.last_trading_day) AS snapshot_stale,
  (agg.n_snapshots >= 5 AND SAFE_DIVIDE(agg.latest.nav, agg.latest.peak_nav) - 1 <= -0.15) AS drawdown_breach
FROM agg CROSS JOIN ltd;

-- ===== state.trading_enabled — the machine-readable gate =====
-- Robust to an unseeded/empty ops.trading_control (defensive; should not occur post-deployment
-- since this file seeds it above) via the same ARRAY_AGG single-row-guarantee pattern as
-- book_drawdown_watch, so this view can NEVER return zero rows — sp_assert_trading_enabled below
-- depends on that (a zero-row SELECT INTO would null out its variables and fail OPEN, the wrong
-- direction for a safety gate).
--
-- SUPERSEDED LIVE by bigquery/47_trading_enabled_resync.sql (2026-07-14), 47 in turn by
-- bigquery/78_book_drawdown_rebase_and_staleness_gate.sql (2026-07-17, verified against the
-- deployed view 2026-07-18), 78 in turn by bigquery/97_halt_echo_dependency_gate.sql
-- (2026-07-19, halt-echo missing_dependency exclusion), and 97 in turn by
-- bigquery/107_halt_echo_missed_run_gate.sql (2026-07-26, halt-echo missed_run exclusion) — 107 is
-- the CURRENT single source of truth for this gate. Kept here, unmodified, for DR-rebuild
-- apply-in-order reference only. DO NOT re-apply this CREATE OR REPLACE VIEW statement live in
-- isolation — doing so on 2026-07-11 (commit e82cc96, adding the snapshot_stale term below) silently
-- clobbered 34_alert_lifecycle.sql's already-deployed trading_halted exclusion fix and reintroduced
-- a self-latching gate for 3+ days before it was caught. See 107 (not 47/78/97 — all three are
-- themselves superseded).
CREATE OR REPLACE VIEW `stock-trading-498512.state.trading_enabled` AS
WITH ctrl AS (
  SELECT ARRAY_AGG(STRUCT(halt_all, reason, mode) ORDER BY control_ts DESC LIMIT 1)[SAFE_OFFSET(0)] AS latest
  FROM `stock-trading-498512.ops.trading_control`
),
health AS (SELECT all_green FROM `stock-trading-498512.state.system_health`),
dd AS (SELECT drawdown_breach, drawdown_from_peak, snapshot_stale FROM `stock-trading-498512.state.book_drawdown_watch`)
SELECT
  NOT COALESCE(ctrl.latest.halt_all, FALSE)
  AND COALESCE(health.all_green, FALSE)
  AND NOT COALESCE(dd.drawdown_breach, FALSE)
  AND NOT COALESCE(dd.snapshot_stale, FALSE) AS trading_enabled,
  CASE
    WHEN COALESCE(ctrl.latest.halt_all, FALSE) THEN
      FORMAT('halt_all (mode=%s): %s', COALESCE(ctrl.latest.mode, '?'), COALESCE(ctrl.latest.reason, 'no reason logged'))
    WHEN NOT COALESCE(health.all_green, FALSE) THEN
      'state.system_health.all_green = FALSE (freshness / open critical alert / embedding / firing kill-flag issue)'
    WHEN COALESCE(dd.drawdown_breach, FALSE) THEN
      FORMAT('book NAV drawdown %.2f%% from trailing peak exceeds the -15%% circuit-breaker threshold', dd.drawdown_from_peak * 100)
    WHEN COALESCE(dd.snapshot_stale, FALSE) THEN
      'state.book_drawdown_watch.snapshot_stale = TRUE (ops.account_snapshot has not been refreshed for the current trading day -- the book-level drawdown breaker cannot trust its own peak/current NAV comparison; ITEM 16, 2026-07-11)'
    ELSE NULL
  END AS halt_reason
FROM ctrl, health, dd;

-- ===== ops.sp_assert_trading_enabled — FATAL pre-stage gate (mirrors ops.sp_assert_deps) =====
-- CALL this BEFORE crafting any order (D2/D3/M4/Q4/A1/A3 staging steps). Raises + records a
-- critical alert and ABORTS the routine when trading is halted; a self-healed halt (all_green
-- returns TRUE, drawdown clears) makes this pass again automatically on the next call — the
-- ASYMMETRY (manual review before clearing an AUTO halt) is an operator-procedure discipline, not
-- something this procedure enforces, since an auto halt_all=TRUE row is itself just data; clearing
-- it requires a NEW manual-mode row, which only a human/console action produces.
-- SUPERSEDED BY bigquery/85_gate_selfheal_repo_catchup.sql (2026-07-18). 85 is identical to the body
-- below EXCEPT that it adds the 2026-07-17 stale-echo self-heal resolver (a best-effort
-- ops.sp_auto_resolve_alerts() call) ahead of the halt decision — a fix that went live 2026-07-17 but
-- was never written back here, so the repo silently disagreed with production until the live-sql-parity
-- comparator was fixed 2026-07-18. Kept here unmodified for apply-in-order reference only. DO NOT
-- re-apply this statement live in isolation: it would REVERT the resolver and reintroduce the D2a
-- whole-day trading halt on an already-healed `staleness` critical (same accident class as bigquery/47's
-- ROOT CAUSE).
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_assert_trading_enabled`(in_routine STRING)
BEGIN
  DECLARE v_enabled BOOL;
  DECLARE v_reason STRING;
  SET (v_enabled, v_reason) = (
    SELECT AS STRUCT trading_enabled, halt_reason FROM `stock-trading-498512.state.trading_enabled`
  );
  IF NOT v_enabled THEN
    -- Message kept STABLE, not folding in in_routine or v_reason (2026-07-04 audit finding, cross-
    -- cutting): v_reason embeds a daily-changing drawdown % and in_routine differs per caller
    -- (D2/D2a/M4/Q4/A3) — either one varying the `message` text defeats sp_raise_alert_once's
    -- exact-match (category, message) dedup, so a SUSTAINED halt on this single highest-stakes gate
    -- would accumulate a fresh unresolved critical alert per day/routine instead of deduping to one,
    -- with no auto-resolve path. The dynamic detail still reaches the operator via the payload (and
    -- via the RAISE message below, which is per-call and not subject to alert dedup).
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', in_routine, 'trading_halted',
      'Order staging blocked: trading is HALTED. See payload for the triggering routine and reason.',
      TO_JSON_STRING(STRUCT(in_routine AS routine, v_reason AS halt_reason)));
    RAISE USING MESSAGE = FORMAT(
      '%s: trading_enabled=FALSE (%s) — order staging aborted. Investigate state.trading_enabled / state.trading_control_latest before retrying.',
      in_routine, COALESCE(v_reason, 'unspecified'));
  END IF;
END;

-- ===== analytics.fn_order_guard — deterministic pre-craft risk envelope =====
-- Table function: SELECT * FROM analytics.fn_order_guard(strategy, side, qty, limit_price, last_price,
-- is_sgov) BEFORE every create_order_instruction call (D2/D3/M4/Q4/A1/A3 staging steps). If
-- passed=FALSE, do NOT craft the order — raise ops.sp_raise_alert_once('critical', <routine>,
-- 'order_guard_block', <reasons>) and skip. Thresholds are POLICY INVARIANTS derived from the 2%
-- sizing sleeve and a %-off-last fat-finger band — NOT fitted to the closed-trade sample — so they
-- are valid at N=1 and scale with book growth via sizing_base_2pct rather than a fixed dollar figure
-- (the $50 check is an absolute backstop for the CURRENT tiny book size; review upward as NAV grows).
--
-- SUPERSEDED LIVE by bigquery/104_strip_pretrade_rails.sql (2026-07-22 — all pre-trade rails stripped
-- except market-only; see bigquery/104). 104 is the CURRENT single source of truth for this object — it
-- superseded bigquery/103_adaptive_shortfall_budget.sql's self-activating φ·α adaptive shortfall budget,
-- which had superseded bigquery/100_market_only_order_guard.sql (2026-07-21 owner directive — market-only
-- cutover: every order is now MARKET, the equity price band/advisory it fed is REMOVED entirely, and a
-- DYNAMIC EXPECTED-SHORTFALL liquidity gate takes its place: a $1M minimum-ADV floor, a 10% ADV
-- participation cap, and a half-spread + Almgren-Thum-Hauptmann-Li 2005 impact estimate compared to a
-- per-strategy budget), which in turn had superseded bigquery/99_ai_limit_decision_order_guard.sql
-- (2026-07-20 owner directive — the equity price band converted from a hard block to an AI-judgment
-- advisory; the third returned column, `advisories`, and the LIMIT DECISION protocol it fed, both now
-- retired), which in turn superseded bigquery/54_park_policy_voo_cutover.sql, which had superseded the
-- definition below. Kept here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT re-apply
-- this CREATE OR REPLACE TABLE FUNCTION statement live in isolation — doing so would revert the
-- vehicle-conditional park bands (bigquery/54), reintroduce the pre-2026-07-20 hard equity-band block
-- bigquery/99 removed, reintroduce limit-order behavior bigquery/100's market-only cutover retired, drop
-- the self-activating adaptive shortfall budget bigquery/103 introduced, AND reintroduce every liquidity/
-- sizing pre-trade rail bigquery/104 stripped.
CREATE OR REPLACE TABLE FUNCTION `stock-trading-498512.analytics.fn_order_guard`(
  p_strategy STRING, p_side STRING, p_qty NUMERIC, p_limit_price NUMERIC, p_last_price NUMERIC, p_is_sgov BOOL
) AS (
  WITH base AS (
    SELECT
      p_qty * p_limit_price AS notional,
      (SELECT sizing_base_2pct FROM `stock-trading-498512.analytics.strategy_nav` WHERE strategy = p_strategy) AS sizing_base,
      -- Latest known account-level NAV (2026-07-04 audit finding): SGOV sweep/cover orders are sized
      -- by hand (floor_to_4dp/ceil_to_4dp arithmetic, Operating_Protocols.md §13.E) against the WHOLE
      -- book, not one strategy's 2%-sizing sleeve, so the strategy-scoped notional/sizing_base check
      -- below is deliberately excluded for SGOV — but that left SGOV orders with NO magnitude bound at
      -- all besides the 0.2% price-band check. account_nav gives SGOV a real (if generous) backstop.
      (SELECT nav FROM `stock-trading-498512.state.account_latest`) AS account_nav,
      SAFE_DIVIDE(ABS(p_limit_price - p_last_price), NULLIF(p_last_price, 0)) AS pct_off_last
  ),
  checks AS (
    SELECT
      ARRAY_CONCAT(
        IF(p_qty IS NULL OR p_qty <= 0, ['qty must be > 0'], []),
        IF(p_limit_price IS NULL OR p_limit_price <= 0, ['limit_price must be > 0'], []),
        IF(NOT p_is_sgov AND base.sizing_base IS NOT NULL AND base.notional > 1.5 * base.sizing_base,
           [FORMAT('notional %.2f exceeds 1.5x sizing_base_2pct (%.2f) for strategy %s', base.notional, 1.5 * base.sizing_base, p_strategy)], []),
        IF(NOT p_is_sgov AND base.notional > 50,
           [FORMAT('notional %.2f exceeds the $50 absolute backstop (current book size)', base.notional)], []),
        IF(NOT p_is_sgov AND base.pct_off_last IS NOT NULL AND base.pct_off_last > 0.005,
           [FORMAT('limit %.4f is %.2f%% off last %.4f (equity band is 0.5%%)', p_limit_price, base.pct_off_last * 100, p_last_price)], []),
        IF(p_is_sgov AND base.pct_off_last IS NOT NULL AND base.pct_off_last > 0.002,
           [FORMAT('SGOV limit %.4f is %.2f%% off last %.4f (SGOV band is 0.2%%)', p_limit_price, base.pct_off_last * 100, p_last_price)], []),
        -- SGOV notional magnitude backstop (2026-07-04 audit finding, HIGH): a decimal/quantity slip in
        -- the hand-computed sweep/cover math had no automated check besides the 0.2% price band. 1.10x
        -- the latest known account NAV gives ample room for a genuine full-book sweep (SGOV can
        -- legitimately hold ~100% of NAV) while still catching an order sized to buy/sell materially
        -- more SGOV than the entire account is worth. Skips cleanly (no check) if account_latest has no
        -- row yet, same defensive style as the sizing_base check above.
        IF(p_is_sgov AND base.account_nav IS NOT NULL AND base.notional > 1.10 * base.account_nav,
           [FORMAT('SGOV notional %.2f exceeds 1.10x the latest known account NAV (%.2f) — implausible magnitude for a sweep/cover', base.notional, 1.10 * base.account_nav)], [])
      ) AS reasons
    FROM base
  )
  SELECT ARRAY_LENGTH(reasons) = 0 AS passed, reasons
  FROM checks
);

-- ===== analytics.fn_order_guard_options — options-specific pre-craft risk envelope (self-improvement
-- audit ITEM 13, 2026-07-11) =====
-- fn_order_guard above is notional/price-band shaped for equities; an option's limit_price is a
-- per-share PREMIUM (a wholly different scale than a stock's notional), so it cannot sensibly gate an
-- options order. This checks the structure's MAX LOSS instead — the natural risk unit for a defined-risk
-- options structure (Strategy C: "Defined-risk options structures around known events") — against the
-- SAME 1.5x sizing_base_2pct bound fn_order_guard uses for equity notional, keeping options sized
-- consistently with every other strategy's 2%-of-sub-portfolio rule. p_max_loss_dollars MUST be computed
-- by the calling routine via c_options_math.py's verify_max_loss_dual_path BEFORE this call — a NULL or
-- non-positive max_loss_dollars is rejected outright (an UnboundedMaxLossError structure must never reach
-- this guard; c_options_math.py itself refuses to proceed on one, so passing NULL/0 here means that
-- refusal was skipped upstream, which is itself the bug this check catches).
--
-- SUPERSEDED LIVE by bigquery/104_strip_pretrade_rails.sql (2026-07-22 — all pre-trade rails stripped
-- except market-only; see bigquery/104). 104 is the CURRENT single source of truth for this object — it
-- superseded bigquery/100_market_only_order_guard.sql (2026-07-21 owner directive — market-only cutover:
-- this object was previously unmarked here because bigquery/99 never touched it — an option's premium
-- has no equity-style price band to convert — but 100 redefined it, renaming `p_limit_premium` to
-- `p_ref_premium` and adding an order_type=MARKET check plus an options liquidity hard gate, open_interest
-- floor and spread-vs-mid cap; 104 in turn drops that liquidity hard gate and the sizing cap, retaining
-- only order_type=MARKET + sanity + the defined-risk max_loss rail). Kept here, unmodified, for
-- DR-rebuild apply-in-order reference only. DO NOT re-apply this CREATE OR REPLACE TABLE FUNCTION
-- statement live in isolation — doing so would revert to the 5-arg signature and reintroduce the
-- options liquidity hard gate and sizing cap bigquery/104 stripped.
CREATE OR REPLACE TABLE FUNCTION `stock-trading-498512.analytics.fn_order_guard_options`(
  p_strategy STRING, p_side STRING, p_contracts NUMERIC, p_limit_premium NUMERIC, p_max_loss_dollars NUMERIC
) AS (
  WITH base AS (
    SELECT
      p_max_loss_dollars AS max_loss,
      (SELECT sizing_base_2pct FROM `stock-trading-498512.analytics.strategy_nav` WHERE strategy = p_strategy) AS sizing_base
  ),
  checks AS (
    SELECT
      ARRAY_CONCAT(
        IF(p_contracts IS NULL OR p_contracts <= 0, ['contracts must be > 0'], []),
        IF(p_limit_premium IS NULL OR p_limit_premium <= 0, ['limit_premium must be > 0'], []),
        IF(p_max_loss_dollars IS NULL OR p_max_loss_dollars <= 0,
           ['max_loss_dollars must be a positive, DEFINED-risk bound -- an unbounded-max-loss structure must never reach this guard; compute it via c_options_math.py verify_max_loss_dual_path before calling'], []),
        IF(base.sizing_base IS NOT NULL AND base.max_loss IS NOT NULL AND base.max_loss > 1.5 * base.sizing_base,
           [FORMAT('max_loss %.2f exceeds 1.5x sizing_base_2pct (%.2f) for strategy %s', base.max_loss, 1.5 * base.sizing_base, p_strategy)], [])
      ) AS reasons
    FROM base
  )
  SELECT ARRAY_LENGTH(reasons) = 0 AS passed, reasons
  FROM checks
);

-- ===== state.daily_staging_totals — aggregate daily notional + order-count cap input =====
-- A per-order guard (fn_order_guard) cannot stop a runaway staging MANY small in-band orders. This
-- surfaces TODAY's (America/Denver operating day) total staged count + notional across ALL routines
-- so a routine can check it before crafting one more. Caps expressed as a MULTIPLE of the combined
-- 2%-sizing base (scales with book growth) plus a floor order count — policy invariants, not fitted.
--
-- SUPERSEDED LIVE by bigquery/109_retire_daily_staging_cap.sql (owner directive 2026-07-26 — the daily
-- order-count/notional cap is retired; the view now exposes only the raw orders_staged_today /
-- notional_staged_today counters). 109 is the CURRENT single source of truth for this object. Kept
-- here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT re-apply this CREATE OR
-- REPLACE VIEW statement live in isolation — doing so would reintroduce the retired daily_cap_breach
-- warning alert and its now-removed max_daily_notional/max_daily_orders fields.
CREATE OR REPLACE VIEW `stock-trading-498512.state.daily_staging_totals` AS
WITH today_staged AS (
  -- events.queue_events is an append-only status-TRANSITION log: one ORDER_STAGED item_key gets
  -- multiple rows over its life (pending, then filled/expired/abandoned, or a same-day re-craft with a
  -- re-priced limit_price). Take the LATEST row per item_key (QUALIFY ROW_NUMBER() ... DESC = 1) so an
  -- order staged-then-reconciled OR re-priced the SAME day is counted once, at its CURRENT notional, not
  -- once per transition row (adversarial self-audit fix, rev 2026-07-11 — the un-deduped version
  -- double-counted notional vs the COUNT(DISTINCT item_key) order count below) and not at a stale
  -- pre-re-craft price (adversarial self-audit fix, rev 2026-07-12 — a same-day GROUP BY + MAX(notional)
  -- picks the highest historical notional for that item_key, not the current one, silently overstating
  -- notional_staged_today whenever a re-craft re-prices DOWN; matches the "latest row wins" convention
  -- already used by state.open_orders / state.open_queue).
  SELECT
    item_key,
    CAST(JSON_VALUE(payload, '$.qty') AS NUMERIC) * CAST(JSON_VALUE(payload, '$.limit_price') AS NUMERIC) AS notional
  FROM `stock-trading-498512.events.queue_events`
  WHERE queue = 'ORDER_STAGED'
    AND DATE(event_ts, 'America/Denver') = CURRENT_DATE('America/Denver')
  QUALIFY ROW_NUMBER() OVER (PARTITION BY item_key ORDER BY event_ts DESC) = 1
),
cap AS (
  SELECT SUM(sizing_base_2pct) AS combined_sizing_base FROM `stock-trading-498512.analytics.strategy_nav`
)
SELECT
  (SELECT COUNT(DISTINCT item_key) FROM today_staged) AS orders_staged_today,
  (SELECT ROUND(SUM(notional), 2) FROM today_staged) AS notional_staged_today,
  ROUND(10 * cap.combined_sizing_base, 2) AS max_daily_notional,
  15 AS max_daily_orders,
  ((SELECT COUNT(DISTINCT item_key) FROM today_staged) > 15
    OR (SELECT COALESCE(SUM(notional), 0) FROM today_staged) > 10 * cap.combined_sizing_base) AS daily_cap_breach
FROM cap;

-- ===== ops.sp_fire_drill_order_guard — proves the order guard actually rejects a bad order =====
-- An untested breaker is theater (same discipline as the existing backup restore drills,
-- bigquery/17_restore_drill.sql). Call periodically (e.g. monthly, alongside the restore drill) or
-- ad hoc after any edit to fn_order_guard / trading_control. Read-only against real tables (queries
-- analytics.strategy_nav for a real sizing_base so the deliberately-oversized test order is
-- guaranteed over the 1.5x/$50 threshold) but NEVER crafts a real order or writes to trading_control.
--
-- SUPERSEDED LIVE by bigquery/104_strip_pretrade_rails.sql (2026-07-22 — all pre-trade rails stripped
-- except market-only; see bigquery/104). 104 is the CURRENT single source of truth for this object — it
-- superseded bigquery/103_adaptive_shortfall_budget.sql's self-activating φ·α adaptive shortfall budget,
-- which had superseded bigquery/100_market_only_order_guard.sql (2026-07-21 owner directive — market-only
-- cutover), which rewrote the drill to the 9-arg (equity) / 8-arg (options) fn_order_guard/
-- fn_order_guard_options contract: 14 cases total (9 equity incl. 2 park + 5 options, each incl. GOOD-PASS
-- cases asserting passed=TRUE), covering order_type=MARKET enforcement and the dynamic expected-shortfall
-- liquidity gate (equity: $1M minimum-ADV floor, 10% participation cap, half-spread + Almgren-Thum-
-- Hauptmann-Li 2005 impact vs. a per-strategy bps budget; options: open-interest / spread-pct cap,
-- unchanged from the first draft). 100 in turn superseded bigquery/99_ai_limit_decision_order_guard.sql
-- (2026-07-20 owner directive), which had updated the offband fire-drill case (test vector + pass/fail
-- assertion) to prove the equity price-band-advisory contract — that case, and its advisory contract, are
-- now retired along with the price band itself. 104 in turn rewrote the drill again to the 5-arg (equity)
-- / 6-arg (options) signature and a smaller 10-case set proving the STRIP (two cases assert a
-- previously-would-reject large order now PASSES). Kept here, unmodified, for DR-rebuild apply-in-order
-- reference only. DO NOT re-apply this CREATE OR REPLACE PROCEDURE statement live in isolation — doing so
-- would revert the fire drill to asserting a stale pre-2026-07-22 contract, which none of bigquery/99's,
-- bigquery/100's, bigquery/103's, nor bigquery/104's fn_order_guard satisfies, so the drill would misfire
-- CRITICAL against a correctly-working guard (and would call the guard functions with the wrong, stale
-- arity entirely).
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_fire_drill_order_guard`()
BEGIN
  DECLARE v_passed_oversize BOOL;
  DECLARE v_passed_offband BOOL;
  DECLARE v_passed_negative BOOL;
  DECLARE v_passed_opt_maxloss BOOL;
  DECLARE v_passed_opt_null BOOL;
  DECLARE v_passed_opt_negative BOOL;

  -- (1) An absurdly oversized notional (10,000 shares @ $500) must be rejected.
  SET v_passed_oversize = (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`('B', 'BUY', 10000, 500.00, 500.00, FALSE));
  -- (2) A limit 50% off last must be rejected (equity band is 0.5%).
  SET v_passed_offband = (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`('B', 'BUY', 1, 150.00, 100.00, FALSE));
  -- (3) A non-positive qty must be rejected.
  SET v_passed_negative = (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`('B', 'BUY', -1, 100.00, 100.00, FALSE));
  -- (4) OPTIONS (ITEM 13, 2026-07-11): an absurdly oversized max_loss (10,000 * $50 = $500,000) must be rejected.
  SET v_passed_opt_maxloss = (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard_options`('C', 'BUY', 10000, 1.00, 500000.00));
  -- (5) A NULL max_loss (the UnboundedMaxLossError-not-caught-upstream case) must be rejected.
  SET v_passed_opt_null = (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard_options`('C', 'BUY', 1, 1.00, CAST(NULL AS NUMERIC)));
  -- (6) A non-positive contract count must be rejected.
  SET v_passed_opt_negative = (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard_options`('C', 'BUY', -1, 1.00, 10.00));

  IF v_passed_oversize OR v_passed_offband OR v_passed_negative
     OR v_passed_opt_maxloss OR v_passed_opt_null OR v_passed_opt_negative THEN
    CALL `stock-trading-498512.ops.sp_raise_alert`(
      'critical', 'ops.sp_fire_drill_order_guard', 'order_guard_fire_drill_failed',
      'The order-guard fire drill found analytics.fn_order_guard or fn_order_guard_options passing an order it MUST reject. The pre-craft risk envelope is not load-bearing — investigate immediately before trusting it to block a bad order.',
      TO_JSON_STRING(STRUCT(v_passed_oversize AS oversize_passed, v_passed_offband AS offband_passed, v_passed_negative AS negative_qty_passed,
        v_passed_opt_maxloss AS opt_maxloss_passed, v_passed_opt_null AS opt_null_maxloss_passed, v_passed_opt_negative AS opt_negative_contracts_passed)));
  ELSE
    CALL `stock-trading-498512.ops.sp_log_run`('FIRE_DRILL_ORDER_GUARD', CURRENT_DATE('America/Denver'), 'completed', NULL, NULL, 6, NULL, 'All 6 order-guard fire-drill cases (3 equity + 3 options, ITEM 13) correctly rejected.');
  END IF;
END;

-- ===== state.system_health — promote position_reconciliation drift to BLOCKING (2026-07-03,
-- self-improvement audit B-5-exec / B-6-data) =====
-- Was advisory-only (18_stack_review_fixes.sql): a missed CLOSE event leaves a phantom open
-- position in state.current_positions (the path analytics.strategy_nav / 2%-sizing reads) while
-- analytics.position_lifecycle (the authoritative fills-derived path) has already closed it — this
-- silently mis-sizes every future entry while the board stays green. Redefined here (not by editing
-- 10_observability.sql in place) because position_reconciliation is defined in 18_*.sql, which is
-- applied AFTER 10 in the DR-rebuild order — same "fix in a later file" pattern as 22_cash_flows.sql.
-- Verified live (2026-07-03): zero drifted rows before this promotion, so it does not flip all_green.
--
-- SUPERSEDED LIVE by bigquery/173_freshness_cadence_aware.sql — current single source of truth for
-- this object. 173 makes the freshness dead-man cadence-aware for the Sun-Thu daily tier, folding
-- state.freshness's new marks_due_through / marks_current / engine_current columns into all_green in
-- place of marks_fresh/engine_fresh. Kept here, unmodified, for DR-rebuild apply-in-order reference
-- only. DO NOT re-apply this CREATE statement live in isolation.
CREATE OR REPLACE VIEW `stock-trading-498512.state.system_health` AS
WITH alerts_summary AS (
  -- Computed once and reused below (2026-07-04 audit finding: open_critical_alerts and the
  -- identical subquery embedded in all_green were two hand-kept copies of the same COUNTIF,
  -- requiring them to be kept in sync by hand in this load-bearing one-row health rollup).
  SELECT
    COUNTIF(NOT resolved AND severity = 'critical') AS open_critical_alerts,
    COUNTIF(NOT resolved) AS open_alerts
  FROM `stock-trading-498512.ops.alerts`
)
SELECT
  f.last_trading_day, f.last_mark_date, f.engine_through,
  f.marks_fresh, f.engine_fresh, f.d2_ran_last_trading_day,
  eh.is_healthy AS embeddings_healthy,
  a.open_critical_alerts,
  a.open_alerts,
  (SELECT COUNTIF(drawdown_kill OR runaway_review OR m2m_underperf_review) FROM `stock-trading-498512.perf.kill_flags`) AS firing_kill_flags,
  COALESCE((SELECT LOGICAL_OR(drifted) FROM `stock-trading-498512.state.position_reconciliation`), FALSE) AS position_drift_detected,
  (f.marks_fresh AND f.engine_fresh AND eh.is_healthy
     AND a.open_critical_alerts = 0
     AND NOT COALESCE((SELECT LOGICAL_OR(drifted) FROM `stock-trading-498512.state.position_reconciliation`), FALSE)
  ) AS all_green,
  CURRENT_TIMESTAMP() AS checked_at
FROM `stock-trading-498512.state.freshness` f, `stock-trading-498512.state.embedding_health` eh, alerts_summary a;

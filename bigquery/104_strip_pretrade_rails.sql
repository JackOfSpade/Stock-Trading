-- bigquery/104_strip_pretrade_rails.sql — STRIP ALL PRE-TRADE RAILS EXCEPT MARKET-ONLY (owner directive
-- 2026-07-22). The AI now has full freedom to market-buy/-sell on thesis and market conditions,
-- REGARDLESS of current price and slippage. Every liquidity, participation, and SIZING gate is removed
-- from analytics.fn_order_guard; the ONLY remaining equity rail is "order_type must be MARKET" plus
-- malformed-input sanity (qty > 0, ref_price > 0). analytics.fn_order_guard_options keeps market-only +
-- sanity + the DEFINED-RISK requirement (max_loss must be defined and positive — owner directive: this
-- is an unbounded-loss-prevention rail, NOT a liquidity/sizing rail, so it is deliberately retained),
-- but drops its sizing cap and its open-interest/spread liquidity legs. The owner's per-order IBKR
-- confirm-tap is now the sole discretionary backstop, by explicit owner directive.
--
-- WHY. Two owner directives, both 2026-07-22, in one interactive session:
--   (1) "I do not want buy/sell restrictions due to liquidity anymore. remove all that. full freedom on
--       market buy/sell due to market conditions and thesis regardless of current price and slippage."
--   (2) When asked to confirm the boundary (keep the fat-finger sizing rails, or strip everything except
--       market-only): "strip everything except market orders only." When asked specifically whether the
--       OPTIONS defined-risk (bounded max_loss) requirement — a different risk class than liquidity —
--       should also go: "Keep defined-risk requirement."
-- This retires, in one step, the ENTIRE liquidity/execution-cost apparatus built over 2026-07-21..22:
--   * the Almgren-Thum-Hauptmann-Li (2005) expected-implementation-shortfall gate (half-spread + 0.142 *
--     sigma_daily * participation^0.6) and its per-strategy horizon budget (100_market_only_order_guard.sql);
--   * the self-activating φ·α adaptive shortfall budget and its analytics.calibration_return_shrunk view
--     (103_adaptive_shortfall_budget.sql — committed the same week; DROPPED here, its dbt model/test
--     deleted in the same change);
--   * the $1,000,000 minimum-ADV tail-trap floor, the 10% ADV participation (metaorder) cap, and the
--     ADV/spread/sigma "cannot confirm liquidity" rejects;
--   * the options open-interest floor and quoted-spread cap;
-- AND ALSO the fat-finger SIZING rails that were NOT liquidity but were explicitly included in the owner's
-- "strip everything" directive:
--   * the 1.5x sizing_base_2pct notional cap (equity) and the 1.5x sizing_base_2pct max_loss cap (options);
--   * the $50 absolute notional backstop (equity);
--   * the park 1.10x-account-NAV magnitude backstop (park orders are now treated identically to any other
--     market order — market-only + sanity — so the p_is_park parameter is removed entirely).
-- What remains is intentionally minimal: an order the guard passes is simply "a well-formed MARKET order"
-- (and, for options, one whose downside is a computed, positive, bounded number). Everything else —
-- whether the name is liquid, whether the size is prudent, whether the slippage is acceptable — is now
-- the AI's thesis/market-conditions judgment plus the owner's confirm-tap, not a mechanical pre-trade gate.
--
-- WHAT CHANGES (SIGNATURE ARITY CHANGE again; every call site must be updated — see the Claude_Task_Plan.md
-- "Crafting an order" / D2 exit / D2a re-craft / D3 re-craft / park-sweep steps and Operating_Protocols.md
-- §11 "Order-craft discipline" / §13 park sweep-cover, all updated in this same fleet pass):
--   analytics.fn_order_guard
--     OLD (103): (p_strategy, p_side, p_qty, p_ref_price, p_is_park, p_order_type, p_adv_usd,
--                 p_spread_bps, p_sigma_daily) -> (passed, reasons)
--     NEW (104): (p_strategy, p_side, p_qty, p_ref_price, p_order_type)                 -> (passed, reasons)
--     Drops p_is_park (park no longer has any distinct rail), p_adv_usd, p_spread_bps, p_sigma_daily.
--     p_strategy/p_side are RETAINED but not read by any check — they are informational context the caller
--     already passes and the staged-order registry records alongside the guard verdict; keeping them keeps
--     the call shape and the guard_passed/guard_reasons audit trail coherent. Checks kept: qty > 0,
--     ref_price > 0, order_type IN ('MARKET','MKT'). No strategy_nav / account_latest lookup remains.
--   analytics.fn_order_guard_options
--     OLD (100): (p_strategy, p_side, p_contracts, p_ref_premium, p_max_loss_dollars, p_order_type,
--                 p_open_interest, p_spread_pct) -> (passed, reasons)
--     NEW (104): (p_strategy, p_side, p_contracts, p_ref_premium, p_max_loss_dollars, p_order_type) -> (passed, reasons)
--     Drops p_open_interest, p_spread_pct (the options liquidity legs). Also drops the 1.5x sizing_base_2pct
--     max_loss cap (a sizing rail, stripped per the owner directive) — so the strategy_nav lookup is gone.
--     Checks kept: contracts > 0, ref_premium > 0, max_loss_dollars defined AND positive (the RETAINED
--     defined-risk / unbounded-loss-prevention rail), order_type IN ('MARKET','MKT').
--   ops.sp_fire_drill_order_guard — full rewrite to the two new signatures and a smaller case set (10
--     cases, down from 14). It now also proves the STRIP actually happened, not merely that the guard still
--     rejects malformed orders: two GOOD-PASS cases exercise orders the PRIOR guard would have REJECTED on a
--     now-removed sizing rail (a $5,000,000-notional equity MARKET order; a $500,000-max_loss options MARKET
--     order) and assert passed=TRUE. Read-only, never crafts a real order, never writes ops.trading_control —
--     same discipline as every prior version, and it no longer needs to read analytics.strategy_nav (there
--     is no sizing threshold left to size a test vector against).
--   analytics.calibration_return_shrunk — DROPPED (DROP VIEW IF EXISTS below). Its only consumer was the
--     shortfall budget, which no longer exists. Its dbt port (dbt/models/analytics/calibration_return_shrunk.sql),
--     that model's dbt/models/analytics/schema.yml block, and dbt/tests/assert_adaptive_budget_prior_invariant.sql
--     are deleted in the same change (a dbt ref() to a deleted model fails compilation, so they go together).
--
-- WHAT IS **NOT** IN THIS FILE. Partial-sell support (owner's second 2026-07-22 directive — "support
-- partial selling of positions") requires NO order-guard SQL change: a partial sell is just a SELL with
-- qty < the open position, which the guard's (now sizing-free) checks already pass, and the fills-derived
-- FIFO-lot + campaign accounting (bigquery/102_pyramid_aware_lifecycle.sql) already resolves partial exits
-- correctly (verified by hand-trace + dbt/tests/assert_pyramid_synthetic_fifo_campaign.sql's PEX fixture).
-- The partial-sell work is entirely in the procedural/prose layer (Claude_Task_Plan.md D2/D2a — the new
-- events.position_events event_type='ADJUST' reduce-but-stay-OPEN reconciliation path — Strategy.md
-- per-strategy trim rules, roster.yaml spec_hash bumps), landed in the same fleet pass but not here.
--
-- SUPERSEDES (this is now the single canonical definition for these objects; the SUPERSEDED-LIVE markers in
-- bigquery/23, 99, 100, and 103 are all repointed to bigquery/104 in this same change, per
-- scripts/check_superseded_markers.py's rule that EVERY lower-numbered definition must carry a supersed*
-- word AND a pointer to the CURRENT canonical file — 104 — not merely to an intermediate one):
--   analytics.fn_order_guard          (TABLE FUNCTION) — was 103_adaptive_shortfall_budget.sql:133
--   analytics.fn_order_guard_options  (TABLE FUNCTION) — was 100_market_only_order_guard.sql:228
--   ops.sp_fire_drill_order_guard     (PROCEDURE)      — was 103_adaptive_shortfall_budget.sql:200
--   analytics.calibration_return_shrunk (VIEW)         — was 103_adaptive_shortfall_budget.sql:94 — DROPPED
--
-- PROVENANCE. The kept checks are byte-derived from bigquery/103 (equity qty/ref_price sanity + order_type
-- rail) and bigquery/100/23 (options contracts/ref_premium/max_loss-defined sanity + order_type rail);
-- everything liquidity- and sizing-related is DELETED, not modified. calibration_return_shrunk and the
-- shortfall/participation/ADV math have no successor object — they are simply gone.
--
-- Apply AFTER bigquery/103_adaptive_shortfall_budget.sql (the definitions this file supersedes/drops).
-- Apply via the BigQuery MCP execute_sql. DR-rebuild apply-in-order: applying 104 makes 103's fn_order_guard
-- / sp_fire_drill_order_guard live objects immediately superseded and drops calibration_return_shrunk.

-- ===== analytics.fn_order_guard — MARKET-ONLY + malformed-input sanity ONLY (owner directive 2026-07-22:
-- "strip everything except market orders only"). All liquidity legs (ADV floor, participation cap,
-- spread/sigma, Almgren expected-shortfall vs φ·α budget) and all sizing legs (1.5x sizing_base notional
-- cap, $50 backstop, park 1.10x-NAV backstop) are REMOVED. p_is_park and the p_adv_usd/p_spread_bps/
-- p_sigma_daily liquidity inputs are removed from the signature. =====
CREATE OR REPLACE TABLE FUNCTION `stock-trading-498512.analytics.fn_order_guard`(
  p_strategy STRING, p_side STRING, p_qty NUMERIC, p_ref_price NUMERIC, p_order_type STRING
) AS (
  WITH checks AS (
    SELECT ARRAY_CONCAT(
      IF(p_qty IS NULL OR p_qty <= 0, ['qty must be > 0'], []),
      IF(p_ref_price IS NULL OR p_ref_price <= 0, ['ref_price must be > 0'], []),
      IF(UPPER(COALESCE(p_order_type,'')) NOT IN ('MARKET','MKT'),
         [FORMAT('order_type must be MARKET (market-only policy, owner directive 2026-07-21; all liquidity + sizing pre-trade rails removed 2026-07-22); got %s', COALESCE(p_order_type,'NULL'))], [])
    ) AS reasons
  )
  SELECT ARRAY_LENGTH(reasons) = 0 AS passed, reasons FROM checks
);

-- ===== analytics.fn_order_guard_options — MARKET-ONLY + sanity + RETAINED DEFINED-RISK requirement (owner
-- directive 2026-07-22: strip liquidity + sizing, but "Keep defined-risk requirement"). The open-interest
-- floor, quoted-spread cap, and the 1.5x sizing_base_2pct max_loss cap are REMOVED (so no strategy_nav
-- lookup remains); contracts/ref_premium sanity, the order_type=MARKET rail, and the max_loss-must-be-
-- defined-and-positive rail (unbounded-loss prevention — a risk class distinct from liquidity/sizing, kept
-- by explicit owner directive) are retained. =====
CREATE OR REPLACE TABLE FUNCTION `stock-trading-498512.analytics.fn_order_guard_options`(
  p_strategy STRING, p_side STRING, p_contracts NUMERIC, p_ref_premium NUMERIC, p_max_loss_dollars NUMERIC,
  p_order_type STRING
) AS (
  WITH checks AS (
    SELECT ARRAY_CONCAT(
      IF(p_contracts IS NULL OR p_contracts <= 0, ['contracts must be > 0'], []),
      IF(p_ref_premium IS NULL OR p_ref_premium <= 0, ['ref_premium must be > 0'], []),
      IF(p_max_loss_dollars IS NULL OR p_max_loss_dollars <= 0,
         ['max_loss_dollars must be a positive, DEFINED-risk bound -- compute via c_options_math.py verify_max_loss_dual_path before calling (defined-risk / unbounded-loss-prevention rail retained by owner directive 2026-07-22)'], []),
      IF(UPPER(COALESCE(p_order_type,'')) NOT IN ('MARKET','MKT'),
         [FORMAT('order_type must be MARKET (market-only policy, owner directive 2026-07-21); got %s', COALESCE(p_order_type,'NULL'))], [])
    ) AS reasons
  )
  SELECT ARRAY_LENGTH(reasons) = 0 AS passed, reasons FROM checks
);

-- ===== analytics.calibration_return_shrunk — DROPPED. Introduced by bigquery/103 solely to feed the φ·α
-- adaptive shortfall budget; with the shortfall gate removed it has no consumer. DROP (not CREATE OR
-- REPLACE) — there is no successor object. Parity-safe: scripts/check_live_sql_parity.py only reads CREATE
-- statements and treats a genuinely-dropped-live object as a non-fatal missing_live skip, never a DRIFT. =====
DROP VIEW IF EXISTS `stock-trading-498512.analytics.calibration_return_shrunk`;

-- ===== ops.sp_fire_drill_order_guard — v4: proves the market-only + sanity + (options) defined-risk
-- contract after the 2026-07-22 rail strip (was bigquery/103:200 -> bigquery/100:301 -> bigquery/99 ->
-- bigquery/23). Read-only against the two table functions, NEVER crafts a real order, NEVER writes
-- ops.trading_control. No analytics.strategy_nav read (no sizing threshold left to size a vector against).
--
-- 10 cases (down from 14): 5 equity + 5 options.
--   EQUITY (fn_order_guard 5-arg: strategy, side, qty, ref_price, order_type):
--     (1) order_type='LIMIT'                    -> REJECT (market-only rail).
--     (2) qty=-1                                -> REJECT (qty sanity).
--     (3) ref_price=0                           -> REJECT (ref_price sanity).
--     (4) clean small MARKET order              -> PASS.
--     (5) $5,000,000-notional MARKET order      -> PASS. PROVES THE STRIP: 10,000 sh @ $500 would have been
--         rejected by the (now-removed) 1.5x-sizing / $50 backstop; with those rails gone it must PASS.
--   OPTIONS (fn_order_guard_options 6-arg: strategy, side, contracts, ref_premium, max_loss_dollars, order_type):
--     (6) max_loss NULL                         -> REJECT (RETAINED defined-risk rail).
--     (7) order_type='LIMIT'                    -> REJECT (market-only rail).
--     (8) contracts=-1                          -> REJECT (contracts sanity).
--     (9) clean small MARKET order              -> PASS.
--    (10) $500,000 DEFINED max_loss MARKET order -> PASS. PROVES THE STRIP: would have been rejected by the
--         (now-removed) 1.5x-sizing max_loss cap; with defined-risk kept but the sizing cap gone it must PASS.
-- FAILURE = any must-reject case passed, OR any must-pass case failed. =====
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_fire_drill_order_guard`()
BEGIN
  DECLARE v_eq_limit_type      BOOL;  -- (1) LIMIT -> must REJECT.
  DECLARE v_eq_negative_qty    BOOL;  -- (2) qty=-1 -> must REJECT.
  DECLARE v_eq_bad_ref         BOOL;  -- (3) ref_price=0 -> must REJECT.
  DECLARE v_eq_good_pass       BOOL;  -- (4) clean small MARKET -> must PASS.
  DECLARE v_eq_large_pass      BOOL;  -- (5) $5M-notional MARKET -> must PASS (proves sizing strip).

  DECLARE v_opt_null_ml        BOOL;  -- (6) max_loss NULL -> must REJECT (defined-risk kept).
  DECLARE v_opt_limit_type     BOOL;  -- (7) LIMIT -> must REJECT.
  DECLARE v_opt_bad_contracts  BOOL;  -- (8) contracts=-1 -> must REJECT.
  DECLARE v_opt_good_pass      BOOL;  -- (9) clean small MARKET -> must PASS.
  DECLARE v_opt_large_pass     BOOL;  -- (10) $500k DEFINED max_loss MARKET -> must PASS (proves sizing strip).

  SET v_eq_limit_type = (
    SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`('B', 'BUY', NUMERIC '0.1', 150.00, 'LIMIT'));
  SET v_eq_negative_qty = (
    SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`('B', 'BUY', -1, 100.00, 'MARKET'));
  SET v_eq_bad_ref = (
    SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`('B', 'BUY', NUMERIC '0.1', 0, 'MARKET'));
  SET v_eq_good_pass = (
    SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`('B', 'BUY', NUMERIC '0.1', 150.00, 'MARKET'));
  SET v_eq_large_pass = (
    SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`('B', 'BUY', 10000, 500.00, 'MARKET'));

  SET v_opt_null_ml = (
    SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard_options`('C', 'BUY', 1, 1.00, CAST(NULL AS NUMERIC), 'MARKET'));
  SET v_opt_limit_type = (
    SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard_options`('C', 'BUY', 1, 1.00, 10.00, 'LIMIT'));
  SET v_opt_bad_contracts = (
    SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard_options`('C', 'BUY', -1, 1.00, 10.00, 'MARKET'));
  SET v_opt_good_pass = (
    SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard_options`('C', 'BUY', 1, 1.00, 10.00, 'MARKET'));
  SET v_opt_large_pass = (
    SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard_options`('C', 'BUY', 10000, 1.00, 500000.00, 'MARKET'));

  IF v_eq_limit_type OR v_eq_negative_qty OR v_eq_bad_ref OR NOT v_eq_good_pass OR NOT v_eq_large_pass
     OR v_opt_null_ml OR v_opt_limit_type OR v_opt_bad_contracts OR NOT v_opt_good_pass OR NOT v_opt_large_pass THEN
    CALL `stock-trading-498512.ops.sp_raise_alert`(
      'critical', 'ops.sp_fire_drill_order_guard', 'order_guard_fire_drill_failed',
      'The market-only order-guard fire drill (owner directive 2026-07-22, bigquery/104_strip_pretrade_rails.sql -- all liquidity + sizing pre-trade rails removed, only market-only + malformed-input sanity + the options defined-risk rail remain) found a regression: either a must-reject case (non-MARKET order_type, non-positive qty/contracts/ref_price, or an options order with a NULL/non-positive max_loss) incorrectly returned passed=TRUE, or one of the must-PASS cases (a clean MARKET order, or -- critically -- a large-notional / large-defined-max_loss MARKET order that the PRE-STRIP guard would have rejected on a now-removed sizing rail) incorrectly returned passed=FALSE. See payload for which case(s) failed. The pre-craft guard is not behaving as the post-strip contract requires -- investigate before trusting it.',
      TO_JSON_STRING(STRUCT(
        v_eq_limit_type AS eq_limit_order_type_passed, v_eq_negative_qty AS eq_negative_qty_passed,
        v_eq_bad_ref AS eq_bad_ref_price_passed, v_eq_good_pass AS eq_good_pass_passed,
        v_eq_large_pass AS eq_large_notional_pass_passed,
        v_opt_null_ml AS opt_null_maxloss_passed, v_opt_limit_type AS opt_limit_order_type_passed,
        v_opt_bad_contracts AS opt_negative_contracts_passed, v_opt_good_pass AS opt_good_pass_passed,
        v_opt_large_pass AS opt_large_maxloss_pass_passed)));
  ELSE
    CALL `stock-trading-498512.ops.sp_log_run`(
      'FIRE_DRILL_ORDER_GUARD', CURRENT_DATE('America/Denver'), 'completed', NULL, NULL, 10, NULL,
      'All 10 order-guard fire-drill cases (5 equity + 5 options, owner directive 2026-07-22 -- bigquery/104_strip_pretrade_rails.sql) correctly asserted: every must-reject case (non-MARKET order_type, non-positive qty/contracts/ref_price, NULL/non-positive options max_loss) rejected, and every must-PASS case passed -- including the two STRIP-PROOF cases (a $5M-notional equity MARKET order and a $500k-defined-max_loss options MARKET order, both of which the pre-2026-07-22 guard would have rejected on the now-removed 1.5x-sizing / $50 rails). Never crafted a real order or wrote to ops.trading_control.');
  END IF;
END;

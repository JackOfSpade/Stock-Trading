-- bigquery/99_ai_limit_decision_order_guard.sql — LIMIT DECISION: the equity price-band check
-- converts from a HARD BLOCK to an AI-judgment ADVISORY (owner directive 2026-07-20).
--
-- WHY. The pre-2026-07-20 `analytics.fn_order_guard` treated the equity (non-park) 0.5%-off-last
-- band exactly like every other check here: `passed=FALSE` + a mandatory `order_guard_block` critical
-- alert, with no craft permitted past it. That rigid "never-chase" band is a PRICE-DISCIPLINE
-- preference, not a risk control (unlike qty/limit sanity, the 1.5x sizing cap, the $50 notional
-- backstop, or the park bands/1.10x-NAV magnitude check — every one of which bounds an actual capital
-- or fat-finger exposure). Trigger: `entry-TSM-D-20260717` (Strategy D, persist-and-wait BUY,
-- `events.decision_log` 0edb56ed / Watchlist.md) hit `order_guard_block` on a re-craft over a 0.92%
-- gap between the resting limit and a live quote — a single-digit-percent move on a name with an
-- unchanged, GO-quality thesis and time still left in its entry window — and the HARD block halted
-- staging on it outright, with no mechanism to accept the gap on judgment even when the thesis
-- clearly still warranted the entry. The band's INTENT (do not blindly chase into an adverse move) is
-- legitimate; making it a rigid, non-overridable trigger conflated "worth flagging" with "must abort,"
-- exactly the deterministic-trigger failure mode `Operating_Protocols.md`'s ITEM 19 / capital-
-- allocation judgment redesigns (`AI_DECISION_REDESIGN.md`) already moved off of for other decisions.
--
-- WHAT CHANGES. `passed`/`reasons` now cover HARD rails ONLY: qty>0, limit>0, the 1.5x sizing_base
-- cap, the $50 notional backstop, the park bands (SGOV 0.2% / non-SGOV 0.5%), and the park 1.10x-NAV
-- magnitude check — every one of those is UNCHANGED and still returns `passed=FALSE` +
-- `order_guard_block` exactly as before (a hard failure still means do-NOT-craft). The equity
-- (non-park) 0.5%-off-last band is REMOVED from `reasons` and instead emitted on a NEW third returned
-- column, `advisories` (ARRAY<STRING>, empty when nothing applies) — an equity limit >0.5% off last
-- now still returns `passed=TRUE` (assuming every hard rail clears) with a single advisory string in
-- it. `analytics.fn_order_guard_options` is untouched by this migration — it has no price-band check
-- (its own header already explains why: an option's limit_price is a per-share premium, not a
-- notional-comparable price, so the equity band never applied to it).
--
-- advisories NEVER blocks and NEVER alerts. There is no `order_guard_block`, `sp_raise_alert[_once]`,
-- or any other side effect tied to a non-empty `advisories` — it is purely a signal for the caller to
-- weigh. The consuming protocol — what a routine DOES with a non-empty `advisories` array at craft or
-- re-craft time (RAISE the limit toward/through the market, HOLD it as a patient rest level, LOWER it,
-- or ABANDON the entry — always by fresh judgment, never a deterministic default, always logged) — is
-- the **"LIMIT DECISION"** block in `Claude_Task_Plan.md`'s preamble (the "Crafting an order
-- (equity/ETF)" section, immediately after that section's craft steps, and mirrored in D2a's
-- persist-and-wait re-craft step). This file is the SQL substrate only; do not re-derive or duplicate
-- the decision protocol's prose here — read it there.
--
-- SCOPE. This migration touches `analytics.fn_order_guard` and `ops.sp_fire_drill_order_guard` only.
-- It does NOT touch `analytics.fn_order_guard_options` (no price band to convert), the park bands, the
-- 1.10x-NAV park magnitude check, `state.daily_staging_totals`, or any other object in
-- `23_trading_control.sql` / `54_park_policy_voo_cutover.sql` — those stay exactly as defined there.
--
-- PROVENANCE / HOW THIS WAS BUILT. `fn_order_guard`'s body below is copied EXACTLY (fully-qualified
-- names, identical signature `p_strategy STRING, p_side STRING, p_qty NUMERIC, p_limit_price NUMERIC,
-- p_last_price NUMERIC, p_is_park BOOL` — same arity/position as today, so every existing positional
-- call site keeps working with no call-shape change) from `bigquery/54_park_policy_voo_cutover.sql`
-- (the current canonical definition, itself superseding `23_trading_control.sql`'s original), with
-- ONLY: (1) the equity-band `IF` removed from the `reasons` ARRAY_CONCAT, and (2) a second `checks`
-- CTE column, `advisories`, added alongside `reasons`. `ops.sp_fire_drill_order_guard`'s body is
-- copied from `bigquery/23_trading_control.sql:308` (its sole prior definition) with ONLY the offband
-- case's test vector and pass/fail assertion updated to prove the NEW contract (see that procedure's
-- own comment below) — the other 5 fire-drill cases, and the drill's read-only / never-crafts-a-real-
-- order / never-writes-`ops.trading_control` design, are UNCHANGED.
--
-- SUPERSEDES (this is now the single canonical definition for both objects — see the SUPERSEDED
-- markers left in `23_trading_control.sql` and `54_park_policy_voo_cutover.sql` pointing back here):
--   analytics.fn_order_guard          (TABLE FUNCTION) — was `54_park_policy_voo_cutover.sql:254`
--   ops.sp_fire_drill_order_guard     (PROCEDURE)      — was `23_trading_control.sql:308`
--
-- Apply after `54_park_policy_voo_cutover.sql` (park-vehicle-conditional bands this migration
-- preserves verbatim) and `23_trading_control.sql` (the fire-drill procedure + its scheduled-query
-- wrapper, `ops.sp_sq_fire_drill_order_guard` in `bigquery/75_scheduled_query_wrappers.sql`, which
-- simply CALLs this procedure by name and needs no edit). Apply via the BigQuery MCP execute_sql.

-- ===== analytics.fn_order_guard — equity price-band check demoted to advisory (owner directive
-- 2026-07-20). Park bands, sizing/notional/qty-sanity hard rails all UNCHANGED from
-- bigquery/54_park_policy_voo_cutover.sql — see this file's header for exactly what changed. =====
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
        IF(p_is_park AND base.park_vehicle = 'SGOV' AND base.pct_off_last IS NOT NULL AND base.pct_off_last > 0.002,
           [FORMAT('park (SGOV) limit %.4f is %.2f%% off last %.4f (SGOV band is 0.2%%)', p_limit_price, base.pct_off_last * 100, p_last_price)], []),
        IF(p_is_park AND base.park_vehicle != 'SGOV' AND base.pct_off_last IS NOT NULL AND base.pct_off_last > 0.005,
           [FORMAT('park (%s) limit %.4f is %.2f%% off last %.4f (non-SGOV park band is 0.5%%)', base.park_vehicle, p_limit_price, base.pct_off_last * 100, p_last_price)], []),
        IF(p_is_park AND base.account_nav IS NOT NULL AND base.notional > 1.10 * base.account_nav,
           [FORMAT('park notional %.2f exceeds 1.10x the latest known account NAV (%.2f) — implausible magnitude for a sweep/cover', base.notional, 1.10 * base.account_nav)], [])
      ) AS reasons,
      -- ADVISORY (owner directive 2026-07-20 — was a HARD reasons-array entry; see file header). Never
      -- blocks, never alerts. Feeds the LIMIT DECISION (RAISE/HOLD/LOWER/ABANDON) prose in
      -- Claude_Task_Plan.md's preamble — read it there, this is the SQL substrate only.
      IF(NOT p_is_park AND base.pct_off_last IS NOT NULL AND base.pct_off_last > 0.005,
         [FORMAT('ADVISORY: limit %.4f is %.2f%% off last %.4f (equity reference band 0.5%%) — feed the LIMIT DECISION (RAISE/HOLD/LOWER/ABANDON), never a block', p_limit_price, base.pct_off_last * 100, p_last_price)], []) AS advisories
    FROM base
  )
  SELECT ARRAY_LENGTH(reasons) = 0 AS passed, reasons, advisories
  FROM checks
);

-- ===== ops.sp_fire_drill_order_guard — v2: proves the HARD rails still reject, and the advisory
-- fires instead of blocking (owner directive 2026-07-20; was bigquery/23_trading_control.sql:308) =====
-- Same discipline as before (bigquery/17_restore_drill.sql-style breaker drill): read-only against
-- real tables (queries analytics.strategy_nav for a real sizing_base so the deliberately-oversized
-- test order is guaranteed over the 1.5x/$50 threshold), NEVER crafts a real order, NEVER writes to
-- ops.trading_control. Call periodically (scheduled monthly via
-- bigquery/scheduled_queries/fire_drill_order_guard.sql -> ops.sp_sq_fire_drill_order_guard, which
-- just CALLs this procedure by name and needed no edit for this migration) or ad hoc after any edit to
-- fn_order_guard / trading_control.
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_fire_drill_order_guard`()
BEGIN
  DECLARE v_passed_oversize BOOL;
  DECLARE v_offband_ok BOOL;
  DECLARE v_passed_negative BOOL;
  DECLARE v_passed_opt_maxloss BOOL;
  DECLARE v_passed_opt_null BOOL;
  DECLARE v_passed_opt_negative BOOL;

  -- (1) An absurdly oversized notional (10,000 shares @ $500) must be rejected.
  SET v_passed_oversize = (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`('B', 'BUY', 10000, 500.00, 500.00, FALSE));
  -- (2) ADVISORY CONTRACT (v2, owner directive 2026-07-20): a limit 50% off last must NOT be blocked
  -- (the equity band is advisory now) but MUST still surface exactly one advisory for the LIMIT
  -- DECISION to weigh. The OLD vector ('B','BUY',1,150.00,100.00,FALSE) never isolated the band on its
  -- own -- at notional $150 (1 sh @ $150) it also tripped the $50 absolute backstop, so a bare
  -- `passed` assertion couldn't distinguish "band correctly demoted" from "backstop still firing
  -- for an unrelated reason." Replaced with qty NUMERIC '0.1' -> notional $15, comfortably under both
  -- the $50 backstop and any plausible 1.5x sizing_base, isolating the price-band case cleanly; last
  -- price $100 vs limit $150 is still the same 50%-off-last this drill has always tested.
  SET v_offband_ok = (
    SELECT passed AND ARRAY_LENGTH(advisories) >= 1
    FROM `stock-trading-498512.analytics.fn_order_guard`('B', 'BUY', NUMERIC '0.1', 150.00, 100.00, FALSE));
  -- (3) A non-positive qty must be rejected.
  SET v_passed_negative = (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`('B', 'BUY', -1, 100.00, 100.00, FALSE));
  -- (4) OPTIONS (ITEM 13, 2026-07-11): an absurdly oversized max_loss (10,000 * $50 = $500,000) must be rejected.
  SET v_passed_opt_maxloss = (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard_options`('C', 'BUY', 10000, 1.00, 500000.00));
  -- (5) A NULL max_loss (the UnboundedMaxLossError-not-caught-upstream case) must be rejected.
  SET v_passed_opt_null = (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard_options`('C', 'BUY', 1, 1.00, CAST(NULL AS NUMERIC)));
  -- (6) A non-positive contract count must be rejected.
  SET v_passed_opt_negative = (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard_options`('C', 'BUY', -1, 1.00, 10.00));

  -- FAILURE = a hard-block regression (any of the 5 must-reject cases passed) OR an advisory
  -- regression (case 2 got hard-blocked again -- the pre-2026-07-20 behavior silently reintroduced --
  -- or passed with zero advisories -- the LIMIT DECISION would have nothing to weigh, an equally
  -- silent regression in the other direction).
  IF v_passed_oversize OR NOT v_offband_ok OR v_passed_negative
     OR v_passed_opt_maxloss OR v_passed_opt_null OR v_passed_opt_negative THEN
    CALL `stock-trading-498512.ops.sp_raise_alert`(
      'critical', 'ops.sp_fire_drill_order_guard', 'order_guard_fire_drill_failed',
      'The order-guard fire drill found a hard-block regression (analytics.fn_order_guard or fn_order_guard_options passed an order it MUST reject) or an advisory regression (the equity price-band case did not come back passed=TRUE with >=1 advisory, as the 2026-07-20 LIMIT DECISION redesign requires -- bigquery/99_ai_limit_decision_order_guard.sql). The pre-craft risk envelope and/or its advisory feed is not load-bearing -- investigate immediately before trusting it.',
      TO_JSON_STRING(STRUCT(v_passed_oversize AS oversize_passed, v_offband_ok AS offband_ok, v_passed_negative AS negative_qty_passed,
        v_passed_opt_maxloss AS opt_maxloss_passed, v_passed_opt_null AS opt_null_maxloss_passed, v_passed_opt_negative AS opt_negative_contracts_passed)));
  ELSE
    CALL `stock-trading-498512.ops.sp_log_run`('FIRE_DRILL_ORDER_GUARD', CURRENT_DATE('America/Denver'), 'completed', NULL, NULL, 6, NULL, 'All 6 order-guard fire-drill cases (2 hard-block equity + 1 advisory-contract equity + 3 options, ITEM 13/2026-07-20 LIMIT DECISION) correctly asserted. Never crafted a real order or wrote to ops.trading_control.');
  END IF;
END;

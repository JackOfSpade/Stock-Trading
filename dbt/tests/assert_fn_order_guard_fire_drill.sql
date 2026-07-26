-- Singular test (passes when ZERO rows): analytics.fn_order_guard / fn_order_guard_options must
-- reject every must-reject case and PASS every must-PASS case, under the NEW post-2026-07-22-strip
-- contract (bigquery/104_strip_pretrade_rails.sql). There is NO `advisories` column -- the LIMIT
-- DECISION advisory contract (bigquery/99_ai_limit_decision_order_guard.sql, 2026-07-20) retired
-- along with limit orders themselves, so this test asserts plain passed=TRUE/FALSE only.
--
-- Added 2026-07-04 (audit finding, HIGH-severity test-gap): fn_order_guard is a PARAMETERIZED
-- BigQuery table function, so it cannot be added to the standard row-parity mechanism
-- (scripts/dbt_parity.py diffs one dbt model against one live view by name — there is no fixed row
-- set to diff for a function of its call arguments). This ports ops.sp_fire_drill_order_guard's
-- exact fire-drill cases (bigquery/104_strip_pretrade_rails.sql, was
-- bigquery/100_market_only_order_guard.sql, was bigquery/99_ai_limit_decision_order_guard.sql, and
-- bigquery/23_trading_control.sql before that) as a dbt test instead, extending the existing
-- parity/test-coverage pattern to this object on its own terms rather than proposing dbt own it.
-- Read-only: fn_order_guard(_options) itself never crafts an order or writes to ops.trading_control.
--
-- v3 (2026-07-21, market-only cutover, SPEC v1): both functions grew from 6 to 8 positional args —
-- p_order_type (must be 'MARKET'/'MKT') and a liquidity-gate pair were added, and p_last_price
-- folded away (the single remaining price arg, p_ref_price / p_ref_premium, is a REFERENCE price
-- only — see dbt/models/state/schema.yml's open_orders.limit_price description).
--
-- v4 (2026-07-21, SPEC v2 — same-day owner revision): the equity liquidity gate replaced a flat
-- dollar-ADV floor + flat spread cap with an EXPECTED IMPLEMENTATION SHORTFALL gate (Almgren-Thum-
-- Hauptmann-Li 2005), adding a 9th positional arg p_sigma_daily to analytics.fn_order_guard.
--
-- v5 (2026-07-22, bigquery/103_adaptive_shortfall_budget.sql — self-activating φ·α adaptive shortfall
-- budget): analytics.fn_order_guard's fixed per-strategy CASE budget_bps was replaced by a lookup into
-- analytics.calibration_return_shrunk, clamped to [0.5x, 2.0x] the old fixed value.
--
-- v6 (2026-07-22, bigquery/104_strip_pretrade_rails.sql — owner directive: "strip everything except
-- market orders only" / options "keep defined-risk requirement"): BOTH signatures SHRANK. ALL
-- liquidity and sizing rails are gone:
--   analytics.fn_order_guard(strategy, side, qty, ref_price, order_type)                    -- 5 args
--     (dropped p_is_park, p_adv_usd, p_spread_bps, p_sigma_daily — the entire Almgren shortfall gate
--     and φ·α adaptive budget, the $1M ADV floor, the 10% ADV participation cap, the 1.5x sizing_
--     base_2pct notional cap, the $50 backstop, and the park 1.10x-NAV backstop are all removed).
--   analytics.fn_order_guard_options(strategy, side, contracts, ref_premium, max_loss_dollars,
--     order_type)                                                                            -- 6 args
--     (dropped p_open_interest, p_spread_pct — the options liquidity legs — and the 1.5x sizing_
--     base_2pct max_loss cap; the max_loss-must-be-defined-and-positive rail is RETAINED, by explicit
--     owner directive, as an unbounded-loss-prevention rail distinct from liquidity/sizing).
-- All liquidity + sizing REJECT cases (adv_null, adv_below_1m_floor, shortfall_exceeds_budget, the
-- 1.5x/$50 equity oversize case, the park cases, and the options opt_low_oi / opt_oversized_maxloss
-- cases) are DELETED — those rails no longer exist, so there is nothing left to reject on. Only
-- market-only + malformed-input sanity (+ options defined-risk) survive, mirrored 1:1 from
-- ops.sp_fire_drill_order_guard's 10-case set (5 equity + 5 options): two of the ten are GOOD-PASS
-- cases that the PRE-STRIP guard would have REJECTED on a now-removed sizing rail — a $5,000,000-
-- notional equity MARKET order (10,000 sh @ $500) and a $500,000-defined-max_loss options MARKET
-- order (10,000 contracts) — and both must now PASS, proving the strip actually happened.
-- The first STRUCT's field aliases (case_name, passed) set the array's schema; later elements are
-- matched positionally and don't need their own aliases. BigQuery does NOT infer a scalar subquery's
-- own column alias for an unnamed STRUCT field (it gets a generic f0_) -- hence the explicit AS passed
-- below, without which the outer WHERE passed / SELECT passed can't resolve the column at all.
SELECT case_name, passed
FROM UNNEST([
  -- ===== EQUITY: analytics.fn_order_guard(strategy, side, qty, ref_price, order_type) — 5 args =====
  STRUCT('order_type_limit' AS case_name,
    (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`('B', 'BUY', NUMERIC '0.1', 150.00, 'LIMIT')) AS passed),
  STRUCT('negative_qty',
    (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`('B', 'BUY', -1, 100.00, 'MARKET'))),
  STRUCT('bad_ref_price',
    (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`('B', 'BUY', NUMERIC '0.1', 0, 'MARKET'))),
  STRUCT('good_pass_equity',
    (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`('B', 'BUY', NUMERIC '0.1', 150.00, 'MARKET'))),
  STRUCT('large_notional_pass_equity',
    (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`('B', 'BUY', 10000, 500.00, 'MARKET'))),  -- $5M notional; PRE-STRIP guard would have rejected on the now-removed 1.5x/$50 sizing rails -- must PASS now.
  -- ===== OPTIONS: analytics.fn_order_guard_options(strategy, side, contracts, ref_premium,
  -- max_loss_dollars, order_type) — 6 args =====
  STRUCT('opt_null_maxloss',
    (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard_options`('C', 'BUY', 1, 1.00, CAST(NULL AS NUMERIC), 'MARKET'))),
  STRUCT('opt_order_type_limit',
    (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard_options`('C', 'BUY', 1, 1.00, 10.00, 'LIMIT'))),
  STRUCT('opt_negative_contracts',
    (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard_options`('C', 'BUY', -1, 1.00, 10.00, 'MARKET'))),
  STRUCT('good_pass_options',
    (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard_options`('C', 'BUY', 1, 1.00, 10.00, 'MARKET'))),
  STRUCT('large_maxloss_pass_options',
    (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard_options`('C', 'BUY', 10000, 1.00, 500000.00, 'MARKET')))  -- $500k defined max_loss; PRE-STRIP guard would have rejected on the now-removed 1.5x sizing_base_2pct max_loss cap -- must PASS now.
])
WHERE
  -- every must-reject case that PASSED is a failure.
  (case_name NOT IN ('good_pass_equity', 'large_notional_pass_equity', 'good_pass_options', 'large_maxloss_pass_options') AND passed)
  -- either GOOD-PASS case that did NOT pass is a failure.
  OR (case_name IN ('good_pass_equity', 'large_notional_pass_equity', 'good_pass_options', 'large_maxloss_pass_options') AND NOT passed)

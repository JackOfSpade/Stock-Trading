-- Singular test (passes when ZERO rows): analytics.fn_order_guard / fn_order_guard_options must
-- reject every must-reject case and PASS the two GOOD-PASS cases (one equity, one options), under
-- the NEW market-only + EXPECTED-IMPLEMENTATION-SHORTFALL liquidity-gate contract
-- (bigquery/100_market_only_order_guard.sql, owner directive 2026-07-21, SPEC v2). There is NO
-- `advisories` column anymore -- the LIMIT DECISION advisory contract
-- (bigquery/99_ai_limit_decision_order_guard.sql, 2026-07-20) retired along with limit orders
-- themselves, so this test asserts plain passed=TRUE/FALSE only.
--
-- Added 2026-07-04 (audit finding, HIGH-severity test-gap): fn_order_guard is a PARAMETERIZED
-- BigQuery table function, so it cannot be added to the standard row-parity mechanism
-- (scripts/dbt_parity.py diffs one dbt model against one live view by name — there is no fixed row
-- set to diff for a function of its call arguments). This ports ops.sp_fire_drill_order_guard's
-- exact fire-drill cases (bigquery/100_market_only_order_guard.sql, was
-- bigquery/99_ai_limit_decision_order_guard.sql, and bigquery/23_trading_control.sql before that)
-- as a dbt test instead, extending the existing parity/test-coverage pattern to this object on its
-- own terms rather than proposing dbt own it. Read-only: fn_order_guard(_options) itself never
-- crafts an order or writes to ops.trading_control.
--
-- v3 (2026-07-21, market-only cutover, SPEC v1): both functions grew from 6 to 8 positional args —
-- p_order_type (must be 'MARKET'/'MKT') and a liquidity-gate pair were added, and p_last_price
-- folded away (the single remaining price arg, p_ref_price / p_ref_premium, is a REFERENCE price
-- only — see dbt/models/state/schema.yml's open_orders.limit_price description).
--
-- v4 (2026-07-21, SPEC v2 — same-day owner revision): the equity liquidity gate replaced a flat
-- dollar-ADV floor + flat spread cap with an EXPECTED IMPLEMENTATION SHORTFALL gate (Almgren-Thum-
-- Hauptmann-Li 2005: expected_shortfall_bps = spread_bps/2 + 0.142*sigma_daily*participation^0.6*1e4,
-- compared against a horizon-scaled per-strategy budget), adding a 9th positional arg p_sigma_daily
-- to analytics.fn_order_guard. Equity cases below were rewritten to exercise the new rejects
-- (ADV<$1M floor, expected-shortfall-exceeds-budget) in place of the old flat $10M-floor / flat-
-- spread-cap cases. The options guard signature/logic is UNCHANGED by SPEC v2 (still 8 args, still
-- a pragmatic OI/spread_pct floor, not a shortfall model) — options case vectors are unchanged
-- except a same-session BUG FIX: p_spread_pct is a FRACTION of mid (the guard checks `> 0.10`), so
-- the prior literal `2` (200%) accidentally made the good-pass case a would-be reject; the correct
-- in-band value is `0.02` (2%), now used in all 5 options rows.
--
-- v5 (2026-07-22, bigquery/103_adaptive_shortfall_budget.sql — self-activating φ·α adaptive shortfall
-- budget): analytics.fn_order_guard's fixed per-strategy CASE budget_bps is replaced by a lookup into
-- analytics.calibration_return_shrunk, clamped to [0.5x, 2.0x] the old fixed value (now the shrinkage
-- PRIOR). The `shortfall_exceeds_budget` case's spread widens from 150 to 700 bps so its 350 bps
-- half-spread exceeds the MAXIMUM possible clamped adaptive budget for strategy B (2x its 50 bps
-- prior = 100 bps) regardless of what alpha_shrunk resolves to — the old 150 bps vector's ~75 bps
-- half-spread was only safely over B's FIXED 50 bps budget, not over an adaptive ceiling that can now
-- range up to 2x the prior.
SELECT case_name, passed
FROM UNNEST([
  -- ===== EQUITY: analytics.fn_order_guard(strategy, side, qty, ref_price, is_park, order_type,
  -- adv_usd, spread_bps, sigma_daily) — SPEC v2, 9 args =====
  STRUCT('oversize' AS case_name,
    (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`('B', 'BUY', 10000, 500.00, FALSE, 'MARKET', 50000000, 5, 0.02)) AS passed),
  STRUCT('order_type_limit',
    (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`('B', 'BUY', 0.1, 150.00, FALSE, 'LIMIT', 50000000, 5, 0.02))),
  STRUCT('adv_null',
    (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`('B', 'BUY', 0.1, 150.00, FALSE, 'MARKET', CAST(NULL AS NUMERIC), 5, 0.02))),
  STRUCT('adv_below_1m_floor',
    (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`('B', 'BUY', 0.1, 150.00, FALSE, 'MARKET', 500000, 5, 0.02))),
  STRUCT('shortfall_exceeds_budget',
    (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`('B', 'BUY', 0.1, 150.00, FALSE, 'MARKET', 50000000, 700, 0.02))),
  STRUCT('negative_qty',
    (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`('B', 'BUY', -1, 100.00, FALSE, 'MARKET', 50000000, 5, 0.02))),
  STRUCT('good_pass_equity',
    (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`('B', 'BUY', 0.1, 150.00, FALSE, 'MARKET', 50000000, 5, 0.02))),
  STRUCT('park_good_pass',
    (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`(NULL, 'BUY', NUMERIC '1', 100.00, TRUE, 'MARKET', CAST(NULL AS NUMERIC), CAST(NULL AS NUMERIC), CAST(NULL AS NUMERIC)))),  -- park order exempt from the liquidity gate; small notional
  STRUCT('park_nav_reject',
    (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`(NULL, 'BUY', 1000000, 100.00, TRUE, 'MARKET', CAST(NULL AS NUMERIC), CAST(NULL AS NUMERIC), CAST(NULL AS NUMERIC)))),  -- notional $100M > 1.10x account NAV -> park NAV backstop rejects
  -- ===== OPTIONS: analytics.fn_order_guard_options(strategy, side, contracts, ref_premium,
  -- max_loss_dollars, order_type, open_interest, spread_pct) — UNCHANGED by SPEC v2, 8 args;
  -- spread_pct is a FRACTION of mid (0.02 = 2%), not a percent-as-integer =====
  STRUCT('opt_oversized_maxloss',
    (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard_options`('C', 'BUY', 10000, 1.00, 500000.00, 'MARKET', 1000, 0.02))),
  STRUCT('opt_null_maxloss',
    (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard_options`('C', 'BUY', 1, 1.00, CAST(NULL AS NUMERIC), 'MARKET', 1000, 0.02))),
  STRUCT('opt_order_type_limit',
    (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard_options`('C', 'BUY', 1, 1.00, 10.00, 'LIMIT', 1000, 0.02))),
  STRUCT('opt_low_oi',
    (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard_options`('C', 'BUY', 1, 1.00, 10.00, 'MARKET', 100, 0.02))),
  STRUCT('good_pass_options',
    (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard_options`('C', 'BUY', 1, 1.00, 10.00, 'MARKET', 1000, 0.02)))
])
WHERE
  -- every must-reject case that PASSED is a failure.
  (case_name NOT IN ('good_pass_equity', 'good_pass_options', 'park_good_pass') AND passed)
  -- either GOOD-PASS case that did NOT pass is a failure.
  OR (case_name IN ('good_pass_equity', 'good_pass_options', 'park_good_pass') AND NOT passed)

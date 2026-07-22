-- bigquery/103_adaptive_shortfall_budget.sql — SELF-ACTIVATING φ·α ADAPTIVE SHORTFALL BUDGET:
-- analytics.fn_order_guard's per-strategy expected-shortfall budget stops being a FIXED provisional
-- constant (D150/A100/C25/else50 bps) and becomes an edge-relative budget that shrinks toward each
-- strategy's own realized-return edge as closed campaigns accrue (owner-directed research pass
-- 2026-07-22, based on bigquery/102_pyramid_aware_lifecycle.sql's analytics.position_campaigns).
--
-- WHY. bigquery/100's expected-shortfall gate (Almgren-Thum-Hauptmann-Li 2005) compares the estimated
-- cost of crossing the spread against a per-strategy budget that was, by its own file header's
-- admission, "PROVISIONAL ... owner to revisit as flow accrues" — a holding-horizon guess (D 150 / A
-- 100 / C 25 / else 50 bps), not a measured number. The deep-research optimal-execution principle this
-- gate is already built on motivates a cleaner rule: a rational trader should tolerate execution cost
-- up to some fraction phi of the edge a trade is expected to capture — cost <= phi * expected-edge —
-- not a fixed horizon-shaped guess. phi=0.20 here (spend at most a fifth of expected edge getting in).
-- The obstacle is data: this system's closed-campaign history is thin (analytics.position_campaigns is
-- brand new — 2026-07-21 — and as of this file's authoring 4 of the 5 strategies show n_closed=0), and
-- analytics.calibration_shrunk exposes WIN-RATE, not realized RETURN — the wrong statistic for a
-- dollar-cost budget. This file therefore computes realized RETURN per closed campaign directly off
-- position_campaigns and shrinks it hard toward the OLD fixed budget AS THE PRIOR (Bayesian shrinkage,
-- strength k=15 "pseudo-campaigns"), so the adaptive budget is a mathematical no-op today and only
-- starts to move once real flow accrues — self-activating, not a second manual cutover.
--
-- WHAT CHANGES.
--   analytics.calibration_return_shrunk (NEW VIEW) — one row per strategy: n_closed campaigns, mean
--   realized return per closed campaign, the fixed prior_bps (today's D150/A100/B·E50/C25 mapping,
--   PRESERVED verbatim as the shrinkage PRIOR, not replaced), prior_alpha (prior_bps re-expressed as an
--   alpha assuming phi=0.20: alpha = (prior_bps/10000)/phi), alpha_shrunk (n_closed real observations
--   blended with k=15 pseudo-observations of prior_alpha), and budget_bps = phi*alpha_shrunk*10000,
--   CLAMPED to [0.5x, 2.0x] the prior_bps so one lucky/unlucky campaign, or a still-thin sample, can
--   never send the budget outside a sane range. At n_closed=0 the blended average collapses to exactly
--   prior_alpha (see the view's own comment and the SINGLE-ENTRY-style algebra note below it), so
--   budget_bps == prior_bps EXACTLY — ZERO behavior change today for any strategy with no closed
--   campaigns yet.
--   analytics.fn_order_guard — a ONE-LINE swap of the fixed CASE budget_bps expression for
--   COALESCE(calibration_return_shrunk lookup, the same old CASE kept as a defensive fallback for a
--   strategy that somehow has no view row). Every other check, leg, and comment in the function body is
--   BYTE-FOR-BYTE identical to bigquery/100_market_only_order_guard.sql (including the PR#24 SAFE.POW
--   negative-participation guard). budget_bps is now FLOAT64 instead of INT64 (e.g. 44.3, not 44) — the
--   shortfall reject message's `CAST(cost.budget_bps AS INT64)` already handles that; no other message
--   or check needed a type-aware edit.
--   ops.sp_fire_drill_order_guard — the equity SHORTFALL must-reject case (v_eq_shortfall) widens its
--   quoted-spread test vector from 150 bps to 700 bps, so its 350 bps half-spread exceeds the MAXIMUM
--   possible clamped adaptive budget (2x the prior; for strategy B, whose prior is 50 bps, that ceiling
--   is 100 bps) regardless of what alpha_shrunk happens to resolve to. The old 150 bps vector's ~75 bps
--   half-spread was only safely over B's FIXED 50 bps budget, not over an adaptive ceiling that can now
--   range up to 2x the prior. All 13 other cases (incl. the equity good-pass at spread 5, both park
--   cases, and all 5 options cases) are UNCHANGED — they already clear/beat any budget in the
--   [0.5x,2x] clamp range.
--
-- SUPERSEDES (this is now the single canonical definition for these two objects — see the SUPERSEDED
-- markers left in `100_market_only_order_guard.sql` pointing here):
--   analytics.fn_order_guard          (TABLE FUNCTION) — was `100_market_only_order_guard.sql:166`
--                                      (100 itself superseded `99_ai_limit_decision_order_guard.sql`,
--                                      which superseded `54_park_policy_voo_cutover.sql` /
--                                      `23_trading_control.sql`)
--   ops.sp_fire_drill_order_guard     (PROCEDURE)      — was `100_market_only_order_guard.sql:297`
--                                      (100 itself superseded `99_ai_limit_decision_order_guard.sql`,
--                                      which superseded `23_trading_control.sql`)
-- analytics.fn_order_guard_options is NOT touched by this file — the options liquidity gate is a
-- pragmatic open-interest/spread floor, not a shortfall-vs-budget comparison, so there is no budget to
-- make adaptive there. analytics.calibration_return_shrunk is a NEW object (no prior definition to
-- supersede).
--
-- SCOPE. This file touches only `analytics.calibration_return_shrunk` (new), `analytics.fn_order_guard`,
-- and `ops.sp_fire_drill_order_guard`. It does not touch `analytics.fn_order_guard_options`,
-- `analytics.calibration_shrunk` (a different, win-rate-based view — untouched), or any call site that
-- invokes `fn_order_guard` — the guard's CALL SHAPE is unchanged (still 9 positional args); the routine
-- does not compute or pass an adaptive budget, the guard derives it internally from p_strategy.
--
-- Apply after `102_pyramid_aware_lifecycle.sql` (analytics.position_campaigns, this file's realized-
-- return source) and `100_market_only_order_guard.sql` (the fn_order_guard / sp_fire_drill_order_guard
-- definitions this file supersedes). Apply via the BigQuery MCP execute_sql.
--
-- Prereqs: analytics.position_campaigns (bigquery/102_pyramid_aware_lifecycle.sql), analytics.
-- strategy_nav / state.account_latest (unchanged sizing/NAV lookups fn_order_guard already used),
-- ops.sp_raise_alert / ops.sp_log_run (bigquery/08_ops_procedures.sql).

-- ===== analytics.calibration_return_shrunk — NEW: per-strategy adaptive shortfall-budget input. One
-- row per strategy (A-E): n_closed closed campaigns (analytics.position_campaigns), mean realized
-- RETURN per closed campaign (NOT win-rate — analytics.calibration_shrunk exposes win-rate, the wrong
-- statistic for a dollar-cost budget), the fixed prior_bps (today's D150/A100/B·E50/C25 holding-horizon
-- mapping, PRESERVED as the shrinkage prior, not replaced), and budget_bps — the phi*alpha_shrunk (in
-- bps) that analytics.fn_order_guard now reads directly. TUNABLE constants (owner to revisit as flow
-- accrues, same posture as the fixed budget this replaces): phi=0.20 (spend at most 1/5 of expected edge
-- on execution cost), k=15 (shrinkage strength in "pseudo-campaigns" — roughly how many REAL closed
-- campaigns are needed before the adaptive budget moves meaningfully off the prior), and a clamp of
-- [0.5x, 2.0x] the prior (floor/ceiling so one lucky or unlucky campaign, or a still-thin sample, can
-- never push the budget outside a sane range).
-- INVARIANT (enforced by dbt/tests/assert_adaptive_budget_prior_invariant.sql): at n_closed=0, the
-- blended average is exactly (0*mean_return + 15*prior_alpha) / (0+15) == prior_alpha, and
-- 0.20*prior_alpha*10000 == prior_bps algebraically (prior_alpha is DEFINED as (prior_bps/10000)/0.20,
-- so multiplying back by 0.20*10000 exactly undoes it) — so budget_bps == prior_bps EXACTLY at n=0, and
-- the GREATEST/LEAST clamp is a no-op there too (prior_bps is always within [0.5x,2x] of itself). ZERO
-- behavior change until a strategy closes its first campaign.
-- DROPPED by bigquery/104_strip_pretrade_rails.sql (2026-07-22 — owner directive: all liquidity + sizing
-- pre-trade rails stripped, including the shortfall gate this view fed; DROP VIEW, no successor object).
-- Kept here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT re-create this view live —
-- 104 drops it. =====
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.calibration_return_shrunk` AS
WITH priors AS (
  SELECT strategy, prior_bps FROM UNNEST([
    STRUCT('A' AS strategy, 100.0 AS prior_bps), STRUCT('B' AS strategy, 50.0 AS prior_bps),
    STRUCT('C' AS strategy, 25.0 AS prior_bps), STRUCT('D' AS strategy, 150.0 AS prior_bps),
    STRUCT('E' AS strategy, 50.0 AS prior_bps)
  ])
),
camp AS (
  -- realized RETURN per CLOSED campaign = realized_pnl / cost_basis; cost_basis approx as
  -- entry_price*total_shares_bought (EXACT for single-entry = 100% of history today).
  SELECT strategy, COUNT(*) AS n_closed,
    AVG(SAFE_DIVIDE(CAST(realized_pnl AS FLOAT64),
        NULLIF(CAST(entry_price AS FLOAT64) * CAST(total_shares_bought AS FLOAT64), 0))) AS mean_return
  FROM `stock-trading-498512.analytics.position_campaigns`
  WHERE exit_date IS NOT NULL
  GROUP BY strategy
),
calc AS (
  SELECT p.strategy, p.prior_bps, COALESCE(c.n_closed,0) AS n_closed, c.mean_return,
    (p.prior_bps/10000.0)/0.20 AS prior_alpha,                        -- TUNABLE: phi=0.20
    ((COALESCE(c.n_closed,0)*COALESCE(c.mean_return,0.0)) + (15.0*((p.prior_bps/10000.0)/0.20)))
      / (COALESCE(c.n_closed,0)+15.0) AS alpha_shrunk                 -- TUNABLE: k=15 shrinkage strength
  FROM priors p LEFT JOIN camp c ON c.strategy = p.strategy
)
SELECT strategy, n_closed, mean_return, prior_bps, prior_alpha, alpha_shrunk,
  GREATEST(0.5*prior_bps, LEAST(2.0*prior_bps, 0.20*alpha_shrunk*10000.0)) AS budget_bps  -- TUNABLE clamp: [0.5x, 2.0x] prior
FROM calc;

-- ===== analytics.fn_order_guard — supersedes bigquery/100_market_only_order_guard.sql. Body is
-- BYTE-FOR-BYTE identical to that file's definition (qty/ref-price sanity, the MARKET-only order_type
-- rail, the 1.5x sizing_base cap, the $50 notional backstop, the park 1.10x-NAV magnitude check, the
-- $1M ADV floor, the 10% participation cap, the Almgren-Thum-Hauptmann-Li expected-shortfall formula
-- incl. the PR#24 SAFE.POW negative-participation guard, and the park exemption) EXCEPT ONE line:
-- budget_bps now resolves from analytics.calibration_return_shrunk (the self-activating φ·α adaptive
-- budget this file introduces) instead of the fixed CASE, with that same fixed CASE kept as a defensive
-- COALESCE fallback for a strategy that somehow has no view row. budget_bps is FLOAT64 now, not INT64
-- (e.g. 44.3) — the shortfall reject message's `CAST(cost.budget_bps AS INT64)` below already handles
-- that.
-- SUPERSEDED LIVE by bigquery/104_strip_pretrade_rails.sql (2026-07-22 — all liquidity + sizing pre-trade
-- rails stripped; only market-only + malformed-input sanity remain). 104 is the CURRENT single source of
-- truth for this object. Kept here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT
-- re-apply this CREATE statement live in isolation. =====
CREATE OR REPLACE TABLE FUNCTION `stock-trading-498512.analytics.fn_order_guard`(
  p_strategy STRING, p_side STRING, p_qty NUMERIC, p_ref_price NUMERIC, p_is_park BOOL,
  p_order_type STRING, p_adv_usd NUMERIC, p_spread_bps NUMERIC, p_sigma_daily NUMERIC
) AS (
  WITH base AS (
    SELECT
      p_qty * p_ref_price AS notional,
      (SELECT sizing_base_2pct FROM `stock-trading-498512.analytics.strategy_nav` WHERE strategy = p_strategy) AS sizing_base,
      (SELECT nav FROM `stock-trading-498512.state.account_latest`) AS account_nav,
      SAFE_DIVIDE(p_qty * p_ref_price, NULLIF(p_adv_usd, 0)) AS participation,
      COALESCE(
        (SELECT budget_bps FROM `stock-trading-498512.analytics.calibration_return_shrunk` WHERE strategy = p_strategy),
        (CASE p_strategy WHEN 'D' THEN 150 WHEN 'A' THEN 100 WHEN 'C' THEN 25 ELSE 50 END)
      ) AS budget_bps
  ),
  cost AS (
    SELECT base.*,
      -- SAFE.POW (not POW): participation is < 0 whenever notional < 0 (a bad negative-qty or
      -- negative-ref_price input the checks CTE rejects below). BigQuery throws on a negative base
      -- raised to a fractional power, and this WITH expression is evaluated for EVERY row BEFORE the
      -- qty>0/ref_price>0 rejects apply — so a plain POW would make the whole function ERROR on a
      -- negative-qty call instead of returning passed=FALSE. SAFE.POW returns NULL there; shortfall_bps
      -- becomes NULL, its own reject is skipped (IS NOT NULL guard, line below), and the qty/ref reject fires.
      (p_spread_bps / 2) + 0.142 * p_sigma_daily * SAFE.POW(base.participation, 0.6) * 10000 AS shortfall_bps
    FROM base
  ),
  checks AS (
    SELECT ARRAY_CONCAT(
      IF(p_qty IS NULL OR p_qty <= 0, ['qty must be > 0'], []),
      IF(p_ref_price IS NULL OR p_ref_price <= 0, ['ref_price must be > 0'], []),
      IF(UPPER(COALESCE(p_order_type,'')) NOT IN ('MARKET','MKT'),
         [FORMAT('order_type must be MARKET (market-only policy, owner directive 2026-07-21); got %s', COALESCE(p_order_type,'NULL'))], []),
      IF(NOT p_is_park AND cost.sizing_base IS NOT NULL AND cost.notional > 1.5 * cost.sizing_base,
         [FORMAT('notional %.2f exceeds 1.5x sizing_base_2pct (%.2f) for strategy %s', cost.notional, 1.5*cost.sizing_base, p_strategy)], []),
      IF(NOT p_is_park AND cost.notional > 50,
         [FORMAT('notional %.2f exceeds the $50 absolute backstop (current book size)', cost.notional)], []),
      IF(p_is_park AND cost.account_nav IS NOT NULL AND cost.notional > 1.10 * cost.account_nav,
         [FORMAT('park notional %.2f exceeds 1.10x the latest known account NAV (%.2f) -- implausible magnitude for a sweep/cover', cost.notional, 1.10*cost.account_nav)], []),
      IF(NOT p_is_park AND p_adv_usd IS NULL,
         ['ADV unknown -- cannot confirm market-order liquidity; do not trade (avg-90d-usd-volume, or get_price_history volume*close; >=20 trading days required)'], []),
      IF(NOT p_is_park AND p_adv_usd IS NOT NULL AND p_adv_usd < 1000000,
         [FORMAT('30-day dollar ADV %.0f is below the $1,000,000 minimum-ADV tail-trap floor', p_adv_usd)], []),
      IF(NOT p_is_park AND cost.participation IS NOT NULL AND cost.participation > 0.10,
         [FORMAT('order is %.1f%% of dollar ADV -- exceeds the 10%% metaorder cap (convex-impact risk)', cost.participation*100)], []),
      IF(NOT p_is_park AND (p_spread_bps IS NULL OR p_sigma_daily IS NULL),
         ['cannot compute expected shortfall -- quoted spread or daily volatility is unknown; do not trade'], []),
      IF(NOT p_is_park AND (p_spread_bps < 0 OR p_sigma_daily < 0),
         ['quoted spread or daily volatility is negative -- the quote appears crossed/corrupted (bid>ask) or the data is invalid; do not trade'], []),
      IF(NOT p_is_park AND cost.shortfall_bps IS NOT NULL AND cost.shortfall_bps > cost.budget_bps,
         [FORMAT('expected implementation shortfall %.1f bps exceeds the %d bps horizon budget for strategy %s (half-spread + 0.142*sigma_daily*participation^0.6)', cost.shortfall_bps, CAST(cost.budget_bps AS INT64), p_strategy)], [])
    ) AS reasons
    FROM cost
  )
  SELECT ARRAY_LENGTH(reasons) = 0 AS passed, reasons FROM checks
);

-- ===== ops.sp_fire_drill_order_guard — supersedes bigquery/100_market_only_order_guard.sql. Body is
-- otherwise BYTE-FOR-BYTE identical to that file's v3 (14 cases: 9 equity incl. 2 park + 5 options) —
-- see that file's own header for the full case-by-case rationale, which is unchanged. ONE case changes:
-- v_eq_shortfall's quoted-spread test vector widens from 150 bps to 700 bps, so its 350 bps half-spread
-- exceeds the MAXIMUM possible clamped adaptive budget (2x the prior; for strategy B, whose prior is 50
-- bps, that ceiling is 100 bps) regardless of what analytics.calibration_return_shrunk resolves
-- budget_bps to — the old 150 bps vector's ~75 bps half-spread was only safely over B's FIXED 50 bps
-- budget, not over an adaptive ceiling that can now range up to 2x the prior. All 13 other cases (incl.
-- the equity good-pass at spread 5, both park cases, and all 5 options cases) are UNCHANGED — they
-- already clear/beat any budget in the [0.5x,2x] clamp range. Read-only, never crafts a real order,
-- never writes ops.trading_control — same discipline as every prior version of this drill.
-- SUPERSEDED LIVE by bigquery/104_strip_pretrade_rails.sql (2026-07-22 — all liquidity + sizing pre-trade
-- rails stripped; only market-only + malformed-input sanity remain). 104 is the CURRENT single source of
-- truth for this object. Kept here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT
-- re-apply this CREATE statement live in isolation. =====
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_fire_drill_order_guard`()
BEGIN
  -- EQUITY (fn_order_guard, market-only + expected-shortfall 9-arg signature: strategy, side, qty,
  -- ref_price, is_park, order_type, adv_usd, spread_bps, sigma_daily).
  DECLARE v_eq_oversized     BOOL;  -- (1) 10,000 sh @ $500 -> must REJECT (1.5x sizing / $50 backstop).
  DECLARE v_eq_limit_type    BOOL;  -- (2) order_type='LIMIT' -> must REJECT (market-only hard gate).
  DECLARE v_eq_unknown_adv   BOOL;  -- (3) ADV NULL (unconfirmable liquidity) -> must REJECT.
  DECLARE v_eq_illiquid_adv  BOOL;  -- (4) ADV $500,000 < the $1,000,000 minimum-ADV tail-trap floor -> must REJECT.
  DECLARE v_eq_shortfall     BOOL;  -- (5) 700 bps quoted spread -> 350 bps half-spread exceeds any clamped adaptive budget ([0.5x,2x] the prior) -> must REJECT.
  DECLARE v_eq_negative_qty  BOOL;  -- (6) qty=-1 -> must REJECT (qty sanity, pre-existing rail).
  DECLARE v_eq_good_pass     BOOL;  -- (7) GOOD PASS: liquid ($50M ADV), tight spread (5 bps), low vol (2% daily sigma), tiny $15 order -> expected shortfall ~2.5 bps, well under budget -> must be TRUE.
  DECLARE v_eq_park_good_pass BOOL; -- (8) park order exempt from the liquidity gate (NULL adv/spread/sigma OK), small notional -> must PASS.
  DECLARE v_eq_park_nav_reject BOOL; -- (9) park notional $100M > 1.10x account NAV -> must REJECT (park NAV backstop).

  -- OPTIONS (fn_order_guard_options, market-only 8-arg signature: strategy, side, contracts,
  -- ref_premium, max_loss_dollars, order_type, open_interest, spread_pct) -- UNCHANGED from
  -- bigquery/100; only the equity guard's shortfall budget source changed in this revision.
  DECLARE v_opt_oversized_ml BOOL;  -- (10) max_loss $500,000 -> must REJECT (1.5x sizing cap, pre-existing rail).
  DECLARE v_opt_null_ml      BOOL;  -- (11) max_loss NULL (unbounded-risk not caught upstream) -> must REJECT (pre-existing rail).
  DECLARE v_opt_limit_type   BOOL;  -- (12) order_type='LIMIT' -> must REJECT (market-only hard gate).
  DECLARE v_opt_low_oi       BOOL;  -- (13) open_interest 100 < the 500-contract floor -> must REJECT.
  DECLARE v_opt_good_pass    BOOL;  -- (14) GOOD PASS: clean, liquid, in-band MARKET order -> must be TRUE.

  SET v_eq_oversized = (
    SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`(
      'B', 'BUY', 10000, 500.00, FALSE, 'MARKET', 50000000, 5, NUMERIC '0.02'));
  SET v_eq_limit_type = (
    SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`(
      'B', 'BUY', NUMERIC '0.1', 150.00, FALSE, 'LIMIT', 50000000, 5, NUMERIC '0.02'));
  SET v_eq_unknown_adv = (
    SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`(
      'B', 'BUY', NUMERIC '0.1', 150.00, FALSE, 'MARKET', CAST(NULL AS NUMERIC), 5, NUMERIC '0.02'));
  SET v_eq_illiquid_adv = (
    SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`(
      'B', 'BUY', NUMERIC '0.1', 150.00, FALSE, 'MARKET', 500000, 5, NUMERIC '0.02'));
  SET v_eq_shortfall = (
    SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`(
      'B', 'BUY', NUMERIC '0.1', 150.00, FALSE, 'MARKET', 50000000, 700, NUMERIC '0.02'));
  SET v_eq_negative_qty = (
    SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`(
      'B', 'BUY', -1, 100.00, FALSE, 'MARKET', 50000000, 5, NUMERIC '0.02'));
  SET v_eq_good_pass = (
    SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`(
      'B', 'BUY', NUMERIC '0.1', 150.00, FALSE, 'MARKET', 50000000, 5, NUMERIC '0.02'));
  SET v_eq_park_good_pass = (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`(
    NULL, 'BUY', NUMERIC '1', 100.00, TRUE, 'MARKET', CAST(NULL AS NUMERIC), CAST(NULL AS NUMERIC), CAST(NULL AS NUMERIC)));  -- park order exempt from liquidity gate (NULL adv/spread/sigma OK), small notional -> must PASS
  SET v_eq_park_nav_reject = (SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard`(
    NULL, 'BUY', 1000000, 100.00, TRUE, 'MARKET', CAST(NULL AS NUMERIC), CAST(NULL AS NUMERIC), CAST(NULL AS NUMERIC)));  -- notional $100M > 1.10x account NAV -> park NAV backstop must REJECT

  SET v_opt_oversized_ml = (
    SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard_options`(
      'C', 'BUY', 10000, 1.00, 500000.00, 'MARKET', 1000, NUMERIC '0.02'));
  SET v_opt_null_ml = (
    SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard_options`(
      'C', 'BUY', 1, 1.00, CAST(NULL AS NUMERIC), 'MARKET', 1000, NUMERIC '0.02'));
  SET v_opt_limit_type = (
    SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard_options`(
      'C', 'BUY', 1, 1.00, 10.00, 'LIMIT', 1000, NUMERIC '0.02'));
  SET v_opt_low_oi = (
    SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard_options`(
      'C', 'BUY', 1, 1.00, 10.00, 'MARKET', 100, NUMERIC '0.02'));
  SET v_opt_good_pass = (
    SELECT passed FROM `stock-trading-498512.analytics.fn_order_guard_options`(
      'C', 'BUY', 1, 1.00, 10.00, 'MARKET', 1000, NUMERIC '0.02'));

  -- FAILURE = any must-reject case incorrectly passed, OR any GOOD-PASS case incorrectly failed.
  IF v_eq_oversized OR v_eq_limit_type OR v_eq_unknown_adv OR v_eq_illiquid_adv OR v_eq_shortfall
     OR v_eq_negative_qty OR NOT v_eq_good_pass
     OR NOT v_eq_park_good_pass OR v_eq_park_nav_reject
     OR v_opt_oversized_ml OR v_opt_null_ml OR v_opt_limit_type OR v_opt_low_oi OR NOT v_opt_good_pass THEN
    CALL `stock-trading-498512.ops.sp_raise_alert`(
      'critical', 'ops.sp_fire_drill_order_guard', 'order_guard_fire_drill_failed',
      'The market-only order-guard fire drill (owner directive 2026-07-21, bigquery/100_market_only_order_guard.sql; equity shortfall case widened for the self-activating adaptive budget, bigquery/103_adaptive_shortfall_budget.sql) found a regression: either a must-reject case (oversized notional/max_loss, non-MARKET order_type, unknown or sub-$1M ADV, expected implementation shortfall over the strategy adaptive budget, low open interest, non-positive qty/contracts, NULL max_loss, or a park notional over 1.10x account NAV) incorrectly returned passed=TRUE, or one of the GOOD-PASS cases (a clean, liquid, in-band MARKET order -- equity, equity-park, or options) incorrectly returned passed=FALSE. See payload for which case(s) failed. The pre-craft risk envelope and/or its expected-shortfall liquidity gate is not load-bearing -- investigate immediately before trusting it to block a bad order or admit a good one.',
      TO_JSON_STRING(STRUCT(
        v_eq_oversized AS eq_oversized_passed, v_eq_limit_type AS eq_limit_order_type_passed,
        v_eq_unknown_adv AS eq_unknown_adv_passed, v_eq_illiquid_adv AS eq_illiquid_adv_passed,
        v_eq_shortfall AS eq_shortfall_over_budget_passed, v_eq_negative_qty AS eq_negative_qty_passed,
        v_eq_good_pass AS eq_good_pass_passed,
        v_eq_park_good_pass AS eq_park_good_pass_passed, v_eq_park_nav_reject AS eq_park_nav_reject_passed,
        v_opt_oversized_ml AS opt_oversized_maxloss_passed, v_opt_null_ml AS opt_null_maxloss_passed,
        v_opt_limit_type AS opt_limit_order_type_passed, v_opt_low_oi AS opt_low_oi_passed,
        v_opt_good_pass AS opt_good_pass_passed)));
  ELSE
    CALL `stock-trading-498512.ops.sp_log_run`(
      'FIRE_DRILL_ORDER_GUARD', CURRENT_DATE('America/Denver'), 'completed', NULL, NULL, 14, NULL,
      'All 14 market-only order-guard fire-drill cases (9 equity incl. 2 park + 5 options, owner directive 2026-07-21 -- bigquery/100_market_only_order_guard.sql) correctly asserted: every must-reject case (oversized notional/max_loss, non-MARKET order_type, unknown or sub-$1M ADV, expected shortfall over the strategy adaptive budget, low open interest, non-positive qty/contracts, NULL max_loss, park notional over 1.10x account NAV) rejected, and every GOOD-PASS case (equity, equity-park, and options -- clean MARKET orders clearing the applicable liquidity gate) passed. Equity shortfall case (5) now proves robustness under the self-activating adaptive per-strategy budget (analytics.calibration_return_shrunk, bigquery/103_adaptive_shortfall_budget.sql, phi=0.20/k=15/clamp [0.5x,2x] the prior): a 700bps quoted spread produces a 350bps half-spread that exceeds the budget regardless of which clamped adaptive value it resolves to. Never crafted a real order or wrote to ops.trading_control.');
  END IF;
END;

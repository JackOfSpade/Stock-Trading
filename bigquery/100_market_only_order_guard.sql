-- bigquery/100_market_only_order_guard.sql — MARKET-ONLY CUTOVER: retire limit orders system-wide,
-- convert liquidity from an advisory into a HARD, EXPECTED-SHORTFALL GATE (owner directive
-- 2026-07-21, two directives same day — see REVISION NOTE below).
--
-- WHY. The 2026-07-20 LIMIT DECISION redesign (`99_ai_limit_decision_order_guard.sql`) kept the
-- resting-DAY-limit / marketable-limit convention and merely softened its equity price-band check
-- from a hard block into an AI-judgment advisory (RAISE/HOLD/LOWER/ABANDON). One day later the owner
-- directed a bigger change: the AI stops setting limit prices at all. Every IBKR order instruction the
-- AI generates is now a MARKET order (`order_type='MARKET'`, `time_in_force='DAY'`) — entries, exits,
-- park sweeps/covers, and options alike. This retires the marketable-limit convention, the
-- persist-and-wait resting-limit model, the entire 2026-07-20 LIMIT DECISION (RAISE/HOLD/LOWER/ABANDON)
-- framework, and the >0.5%-off-last equity price-band advisory it introduced — there is no limit price
-- left to chase, hold, lower, or abandon. In exchange, a name too illiquid/costly to absorb a market
-- order without materially moving against the book is now a BAD PICK, not a fallback-to-limit case:
-- liquidity becomes a HARD, pre-craft GATE (no marketable-limit fallback exists anymore to soften a
-- rejection).
--
-- REVISION NOTE (same day, second owner directive, incorporating deep research): the first cut of this
-- gate (drafted earlier the same session, never applied live) used a fixed dollar-ADV floor
-- ($10M/$20M by strategy) plus a flat 50 bps quoted-spread cap. The owner replaced that before this
-- file was ever applied: a flat spread cap is structurally wrong — too tight for liquid,
-- low-volatility names (falsely rejects a fine order) and too loose for volatile ones (admits a costly
-- one) — and a fixed dollar-ADV floor doesn't scale with order size. The replacement below folds
-- quoted spread AND market impact into one expected-cost estimate, compares it against a per-strategy,
-- holding-horizon-scaled budget, and keeps two structural backstops (a hard minimum-ADV floor as a
-- tail-trap, and a participation cap on metaorder size). This is the ONLY version of
-- `analytics.fn_order_guard` ever written to this file — the fixed-number draft was never applied live
-- and left no artifact to supersede.
--
-- THE GATE (equity/ETF, non-park). Inputs the calling routine computes live and passes in:
--   ref_price    = last (or bid/ask mid); notional = qty * ref_price.
--   adv_usd      = dollar ADV. Primary: get_price_snapshot `avg-90d-usd-volume`. Fallback:
--                  get_price_history volume*close. PROXY PROTOCOL: require >=20 valid trading days;
--                  for names with 20-90 days of history use the 5-DAY MEDIAN dollar volume (median,
--                  not mean, to resist spikes), capping any single index-reconstitution-type spike at
--                  2x median; if truly no volume data, pass NULL (guard rejects). <20 days -> defer.
--   spread_bps   = (ask-bid)/mid * 10000 (the FULL quoted spread; the guard halves it internally).
--   sigma_daily  = daily return volatility as a DECIMAL fraction. From get_price_snapshot
--                  `historical_vol` (30d, annualized) as historical_vol/SQRT(252), or the stdev of
--                  ~20 daily returns from get_price_history.
-- The guard computes, per Almgren, Thum, Hauptmann & Li (2005) — the empirically-calibrated
-- square-root-law temporary-impact model (eta=0.142, beta=0.6 power law on participation):
--   participation           = notional / adv_usd
--   expected_shortfall_bps  = (spread_bps / 2) + 0.142 * sigma_daily * participation^0.6 * 10000
-- and rejects if that shortfall exceeds a per-strategy, HOLDING-HORIZON-SCALED budget (a strategy that
-- holds longer amortizes entry slippage over more time, so it can tolerate a costlier entry):
-- D (very-long horizon) 150 bps, A (long) 100 bps, C (short) 25 bps, else (B/E, medium) 50 bps —
-- `CASE p_strategy WHEN 'D' THEN 150 WHEN 'A' THEN 100 WHEN 'C' THEN 25 ELSE 50 END` in the SQL below
-- (PROVISIONAL per-strategy mapping from the holding-horizon evidence; owner to revisit as flow accrues).
-- Two structural backstops remain independent of the shortfall math: a hard $1,000,000 minimum-ADV
-- floor (a tail-trap for names whose ADV estimate itself is unreliable at the low end, regardless of
-- what the shortfall formula would compute) and a 10% ADV participation cap (guards against convex
-- impact on a large metaorder — the sqrt-law understates cost once a single order dominates a day's
-- volume). Park vehicles (`p_is_park=TRUE`) are exempt from ALL of the ADV/spread/shortfall math
-- (SGOV/VOO are definitionally liquid) — they keep only qty/ref-price sanity, the order_type=MARKET
-- check every order gets, and the pre-existing 1.10x-account-NAV magnitude backstop.
--
-- WHAT CHANGES.
--   analytics.fn_order_guard — SIGNATURE ARITY CHANGE (deliberate; every call site must be updated,
--   not just this file — see Claude_Task_Plan.md's "Crafting an order (equity/ETF)" / D2a re-craft /
--   park-sweep / D2 exit-craft steps and Operating_Protocols.md's "Order-craft discipline", both
--   updated in this same fleet pass):
--     OLD (99): (p_strategy, p_side, p_qty, p_limit_price, p_last_price, p_is_park) -> (passed, reasons, advisories)
--     NEW (100): (p_strategy, p_side, p_qty, p_ref_price, p_is_park, p_order_type, p_adv_usd,
--                 p_spread_bps, p_sigma_daily) -> (passed, reasons)   -- 2-column return; advisories is GONE
--   `p_limit_price`/`p_last_price` collapse into a single `p_ref_price` — the live reference price
--   (last, or bid/ask mid) the craft records into the staged payload's `limit_price` field for
--   reserved-cash / notional-guard purposes ONLY (state.open_orders / state.daily_staging_totals both
--   read `payload.limit_price` — that field name is UNCHANGED so neither view needs a schema edit; only
--   its meaning changes from "order limit" to "reference price"). The equity 0.5%-off-last price-band
--   check (hard block pre-2026-07-20, advisory as of 99) is REMOVED entirely — there is no limit to
--   compare against a reference price anymore. New hard-gate legs replace it (see THE GATE above for
--   the full derivation):
--     (1) order_type must be MARKET (or MKT) — any other value is a hard reject.
--     (2) ADV unknown (NULL) — can't confirm liquidity, don't trade.
--     (3) ADV below the $1,000,000 minimum-ADV tail-trap floor (structural backstop, not per-strategy).
--     (4) participation (notional / ADV) exceeds 10% — metaorder convex-impact cap.
--     (5) spread_bps or sigma_daily unknown — can't compute expected shortfall, don't trade.
--     (6) expected implementation shortfall (half-spread + 0.142*sigma_daily*participation^0.6, in bps)
--         exceeds the calling strategy's holding-horizon-scaled budget (D 150 / A 100 / C 25 / else 50
--         bps).
--   Park vehicles are exempt from (2)-(6) only, not (1).
--
--   analytics.fn_order_guard_options — also an ARITY CHANGE, UNCHANGED from the first (fixed-number)
--   draft of this file — a full options implementation-shortfall model is explicitly OUT OF SCOPE for
--   this pass (flagged in the function's own header below); it keeps the simple, conservative
--   liquidity gate:
--     OLD (23, untouched by 99): (p_strategy, p_side, p_contracts, p_limit_premium, p_max_loss_dollars) -> (passed, reasons)
--     NEW (100): (p_strategy, p_side, p_contracts, p_ref_premium, p_max_loss_dollars, p_order_type,
--                 p_open_interest, p_spread_pct) -> (passed, reasons)
--   `p_limit_premium` renames to `p_ref_premium` (same reference-price-not-a-limit reasoning as above).
--   All prior hard rails (contracts>0, ref_premium>0, max_loss positive-and-defined, 1.5x sizing_base
--   cap) are byte-identical. Two NEW hard-gate legs (owner-flagged TUNABLE DEFAULTS — conservative
--   starting points for a market order on what can be a multi-leg options structure; owner should
--   revisit as options flow accrues): order_type must be MARKET/MKT; open_interest must be known and
--   >=500 contracts; quoted spread (as a fraction of mid) must not exceed 0.10 (10%) when known.
--
--   ops.sp_fire_drill_order_guard — full rewrite to the new 9-arg (equity) / 8-arg (options) contract:
--   9 equity cases (6 non-park must-reject + 1 non-park GOOD-PASS + 1 park GOOD-PASS + 1 park
--   must-reject, asserting `passed=TRUE`/`passed=FALSE` as applicable) and 5 options cases
--   (4 must-reject + 1 GOOD-PASS asserting `passed=TRUE`) — 14 total, up from the prior 6. The 6
--   non-park equity must-reject cases exercise: oversized notional, non-MARKET order_type, unknown ADV,
--   ADV below the $1M floor, expected shortfall exceeding the strategy's horizon budget (a wide-spread
--   vector), and non-positive qty. The 2 park equity cases cover BOTH directions of the park exemption:
--   a clean small-notional park order (NULL adv/spread/sigma) must PASS despite the liquidity gate being
--   entirely inapplicable to it, and an oversized park order (notional > 1.10x account NAV) must still
--   REJECT on the pre-existing park-NAV magnitude backstop, which the liquidity-gate exemption does NOT
--   touch. A standalone participation>10% case is intentionally NOT included (see the procedure's own
--   comment for why — the $50 notional backstop trips first at this book size); the 10% cap is still
--   present in the guard and implicitly exercised (no case breaches it).
--   Read-only, never crafts a real order, never writes ops.trading_control — same discipline as every
--   prior version of this drill.
--
-- SCOPE. This file touches `analytics.fn_order_guard`, `analytics.fn_order_guard_options`, and
-- `ops.sp_fire_drill_order_guard` only. It does NOT touch `ops.trading_control` / `state.trading_enabled`
-- (23_trading_control.sql, unchanged), `state.daily_staging_totals` (23, unchanged — still reads
-- `payload.limit_price`, which stays populated as the reference price so this view needs no edit), or
-- `54_park_policy_voo_cutover.sql` (its vehicle-conditional price bands are simply never called again —
-- no object there is redefined or dropped by this file). The retirement of the LIMIT DECISION prose
-- itself (Claude_Task_Plan.md preamble) and every call-site update (D2/D2a/D3/W4/M4/Q4/A1/A3 craft
-- steps, incl. computing and passing sigma_daily) live in Claude_Task_Plan.md / Operating_Protocols.md,
-- not here — this file is the SQL substrate only.
--
-- PROVENANCE / HOW THIS WAS BUILT. `fn_order_guard`'s qty/ref-price sanity, the 1.5x sizing_base cap,
-- the $50 absolute notional backstop, and the park 1.10x-NAV magnitude check are byte-identical to
-- `99_ai_limit_decision_order_guard.sql` (which itself carried them byte-identical from
-- `54_park_policy_voo_cutover.sql`). Everything liquidity-related is NEW in this file, per the
-- Almgren-Thum-Hauptmann-Li (2005) expected-shortfall formulation in THE GATE above — there is no
-- prior "liquidity" object of any kind to derive it from (99/54/23 all used a flat equity price band,
-- a wholly different mechanism). `fn_order_guard_options`'s body is derived from
-- `23_trading_control.sql`'s definition (99 never touched it): `p_limit_premium` renames to
-- `p_ref_premium`; the contracts/ref_premium/max_loss sanity checks and the 1.5x sizing_base cap are
-- byte-identical to 23; add `p_order_type` (MARKET-only) and `p_open_interest`/`p_spread_pct` (the
-- options liquidity hard gate — a conservative pragmatic gate, NOT an implementation-shortfall model;
-- out of scope for this pass) as new parameters. `ops.sp_fire_drill_order_guard`'s body is a full
-- rewrite proving the new contract — see the procedure's own comment below for the 14 cases and, in
-- particular, a documented interpretation call flagged for owner/orchestrator review (options
-- test-vector spread scaling).
--
-- SUPERSEDES (this is now the single canonical definition for all three objects — see the SUPERSEDED
-- markers left in `99_ai_limit_decision_order_guard.sql` and `23_trading_control.sql` pointing here):
--   analytics.fn_order_guard          (TABLE FUNCTION) — was `99_ai_limit_decision_order_guard.sql:70`
--                                      (99 itself superseded `54_park_policy_voo_cutover.sql`, which
--                                      superseded `23_trading_control.sql:195`)
--   analytics.fn_order_guard_options  (TABLE FUNCTION) — was `23_trading_control.sql:250` (never
--                                      touched by 99 — no price band to convert; this file is its FIRST
--                                      supersession)
--   ops.sp_fire_drill_order_guard     (PROCEDURE)      — was `99_ai_limit_decision_order_guard.sql:117`
--                                      (99 itself superseded `23_trading_control.sql:326`)
--
-- Apply after `99_ai_limit_decision_order_guard.sql` (DR-rebuild apply-in-order: this file's header
-- documents what it replaces from 99, so 99 must already exist when reasoning about the chain, even
-- though applying 100 makes 99's live objects immediately superseded again). Apply via the BigQuery MCP
-- execute_sql.

-- ===== analytics.fn_order_guard — deterministic pre-craft risk envelope, MARKET-ONLY + DYNAMIC
-- EXPECTED-SHORTFALL LIQUIDITY GATE (owner directive 2026-07-21). qty/ref-price sanity, the 1.5x
-- sizing_base cap, the $50 notional backstop, and the park 1.10x-NAV magnitude check are UNCHANGED
-- from `99_ai_limit_decision_order_guard.sql`. The equity price band (hard block pre-2026-07-20,
-- advisory as of 99) is REMOVED — no limit price exists to band anymore. NEW: order_type must be
-- MARKET; a $1,000,000 minimum-ADV floor and a 10% ADV participation cap are structural backstops; and
-- the core liquidity check is an EXPECTED IMPLEMENTATION SHORTFALL (half-spread + Almgren-Thum-
-- Hauptmann-Li 2005 temporary impact, eta=0.142/beta=0.6) compared against a per-strategy, holding-
-- horizon-scaled budget (D 150 / A 100 / C 25 / else 50 bps). See this file's header (THE GATE) for
-- the full derivation. =====
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
      (CASE p_strategy WHEN 'D' THEN 150 WHEN 'A' THEN 100 WHEN 'C' THEN 25 ELSE 50 END) AS budget_bps
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

-- ===== analytics.fn_order_guard_options — options-specific pre-craft risk envelope, MARKET-ONLY (owner
-- directive 2026-07-21). Contracts/ref_premium/max_loss sanity and the 1.5x sizing_base cap over
-- max_loss are UNCHANGED from `23_trading_control.sql` (99 never touched this object — an option's
-- premium has no equity-style price band). NEW: order_type must be MARKET, and a liquidity hard gate
-- (open-interest floor, spread-vs-mid cap) — owner-flagged TUNABLE DEFAULTS, conservative starting
-- points for a market order on a multi-leg options structure; revisit as options flow accrues. See this
-- file's header for the full WHY/WHAT CHANGES. =====
CREATE OR REPLACE TABLE FUNCTION `stock-trading-498512.analytics.fn_order_guard_options`(
  p_strategy STRING, p_side STRING, p_contracts NUMERIC, p_ref_premium NUMERIC, p_max_loss_dollars NUMERIC,
  p_order_type STRING, p_open_interest NUMERIC, p_spread_pct NUMERIC
) AS (
  WITH base AS (
    SELECT p_max_loss_dollars AS max_loss,
      (SELECT sizing_base_2pct FROM `stock-trading-498512.analytics.strategy_nav` WHERE strategy = p_strategy) AS sizing_base
  ),
  checks AS (
    SELECT ARRAY_CONCAT(
      IF(p_contracts IS NULL OR p_contracts <= 0, ['contracts must be > 0'], []),
      IF(p_ref_premium IS NULL OR p_ref_premium <= 0, ['ref_premium must be > 0'], []),
      IF(p_max_loss_dollars IS NULL OR p_max_loss_dollars <= 0,
         ['max_loss_dollars must be a positive, DEFINED-risk bound -- compute via c_options_math.py verify_max_loss_dual_path before calling'], []),
      IF(base.sizing_base IS NOT NULL AND base.max_loss IS NOT NULL AND base.max_loss > 1.5 * base.sizing_base,
         [FORMAT('max_loss %.2f exceeds 1.5x sizing_base_2pct (%.2f) for strategy %s', base.max_loss, 1.5*base.sizing_base, p_strategy)], []),
      IF(UPPER(COALESCE(p_order_type,'')) NOT IN ('MARKET','MKT'),
         [FORMAT('order_type must be MARKET (market-only policy, owner directive 2026-07-21); got %s', COALESCE(p_order_type,'NULL'))], []),
      IF(p_open_interest IS NULL OR p_open_interest < 500,
         [FORMAT('option open interest %s is unknown or below the 500-contract floor — too illiquid for a market order', COALESCE(CAST(p_open_interest AS STRING),'NULL'))], []),
      IF(p_spread_pct IS NULL OR p_spread_pct < 0 OR p_spread_pct > 0.10,
         ['option quoted spread (as a fraction of mid) is unknown, negative, or exceeds the 10% cap -- too illiquid/unreliable for a market order'], [])
    ) AS reasons FROM base
  )
  SELECT ARRAY_LENGTH(reasons) = 0 AS passed, reasons FROM checks
);

-- ===== ops.sp_fire_drill_order_guard — v3: proves the market-only + liquidity-hard-gate contract
-- (owner directive 2026-07-21; was `99_ai_limit_decision_order_guard.sql:117`, which in turn was
-- `23_trading_control.sql:326`) =====
-- Same discipline as every prior version (bigquery/17_restore_drill.sql-style breaker drill): read-only
-- against real tables (queries analytics.strategy_nav for a real sizing_base so the deliberately-
-- oversized test orders are guaranteed over the 1.5x/$50 threshold), NEVER crafts a real order, NEVER
-- writes to ops.trading_control. Call periodically (scheduled monthly via
-- bigquery/scheduled_queries/fire_drill_order_guard.sql -> ops.sp_sq_fire_drill_order_guard, which just
-- CALLs this procedure by name and needs no edit for this migration) or ad hoc after any edit to
-- fn_order_guard / fn_order_guard_options / trading_control.
--
-- 14 cases total (up from 6 pre-2026-07-21): 9 equity (6 non-park must-reject + 1 non-park GOOD-PASS +
-- 1 park GOOD-PASS + 1 park must-reject) and 5 options (4 must-reject + 1 GOOD-PASS asserting
-- passed=TRUE). Every must-reject case isolates exactly ONE new-or-existing hard rail on an otherwise-
-- clean order (mirrors the isolation discipline 99's header established for its own offband case):
-- oversized notional/max_loss, non-MARKET order_type, unknown ADV, ADV below the $1M tail-trap floor, an
-- expected shortfall over the strategy's horizon budget, low open interest, non-positive qty/contracts/
-- NULL max_loss, and (the park must-reject case) a park notional exceeding 1.10x account NAV. Equity
-- park coverage is NOT zero: the two park cases exercise BOTH directions of the park exemption — a
-- clean, small-notional park order (NULL adv/spread/sigma) must PASS despite the liquidity gate being
-- entirely inapplicable to a park vehicle, and an oversized park order must still REJECT on the
-- pre-existing 1.10x-NAV magnitude backstop, which the liquidity-gate exemption does NOT touch. The
-- three GOOD-PASS cases (non-park equity, park equity, options) prove a clean, liquid, in-band MARKET
-- order is NOT falsely rejected by the new liquidity gate (or, for the park case, by the NAV backstop) —
-- the failure mode a pure "does it reject bad orders" drill can't see on its own. A standalone
-- participation>10% case is intentionally NOT included: at the current book size, 10% of even the
-- smallest ADV a case here uses ($500,000) is $50,000 notional, which the $50 absolute notional
-- backstop already rejects on its own long before participation could reach 10% — there is no order
-- size that is simultaneously small enough to clear the $50/1.5x-sizing backstops and large enough to
-- breach the 10% participation cap at any plausible test-vector ADV. The 10% cap stays live in the
-- guard for when the book scales; revisit adding an isolated case once sizing_base_2pct grows enough
-- to make one constructible.
--
-- NOTE FOR OWNER/ORCHESTRATOR REVIEW (interpretation call made in this file, flagging per SISA/audit
-- discipline rather than silently guessing): the options liquidity-gate spread parameter,
-- `p_spread_pct`, is a FRACTION of mid (the function body above compares it to the literal 0.10 = 10%
-- threshold and formats it as `p_spread_pct*100` for display — e.g. 0.02 displays "2.0%"). The options
-- test vectors below therefore use NUMERIC '0.02' (a tight, in-band 2% spread) for every options case,
-- INCLUDING the 4 must-reject cases, where the vector's own targeted defect (oversized max_loss / NULL
-- max_loss / LIMIT order_type / low open interest) is what drives the reject — the spread value is held
-- constant and in-band across all 5 options cases so each case isolates exactly one condition, the same
-- discipline the equity cases use (ADV pinned at 50,000,000 and spread pinned at 5 bps except where one
-- of those two IS the case under test). This keeps case (14)'s GOOD-PASS meaningful: it is only a true
-- positive if every dimension, including spread, is genuinely in-band.
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_fire_drill_order_guard`()
BEGIN
  -- EQUITY (fn_order_guard, market-only + expected-shortfall 9-arg signature: strategy, side, qty,
  -- ref_price, is_park, order_type, adv_usd, spread_bps, sigma_daily).
  DECLARE v_eq_oversized     BOOL;  -- (1) 10,000 sh @ $500 -> must REJECT (1.5x sizing / $50 backstop).
  DECLARE v_eq_limit_type    BOOL;  -- (2) order_type='LIMIT' -> must REJECT (market-only hard gate).
  DECLARE v_eq_unknown_adv   BOOL;  -- (3) ADV NULL (unconfirmable liquidity) -> must REJECT.
  DECLARE v_eq_illiquid_adv  BOOL;  -- (4) ADV $500,000 < the $1,000,000 minimum-ADV tail-trap floor -> must REJECT.
  DECLARE v_eq_shortfall     BOOL;  -- (5) 150 bps quoted spread -> ~75 bps half-spread alone exceeds strategy B's 50 bps MEDIUM-horizon shortfall budget -> must REJECT.
  DECLARE v_eq_negative_qty  BOOL;  -- (6) qty=-1 -> must REJECT (qty sanity, pre-existing rail).
  DECLARE v_eq_good_pass     BOOL;  -- (7) GOOD PASS: liquid ($50M ADV), tight spread (5 bps), low vol (2% daily sigma), tiny $15 order -> expected shortfall ~2.5 bps, well under budget -> must be TRUE.
  DECLARE v_eq_park_good_pass BOOL; -- (8) park order exempt from the liquidity gate (NULL adv/spread/sigma OK), small notional -> must PASS.
  DECLARE v_eq_park_nav_reject BOOL; -- (9) park notional $100M > 1.10x account NAV -> must REJECT (park NAV backstop).

  -- OPTIONS (fn_order_guard_options, market-only 8-arg signature: strategy, side, contracts,
  -- ref_premium, max_loss_dollars, order_type, open_interest, spread_pct) -- UNCHANGED from the
  -- fixed-number draft; only the equity guard's liquidity math changed in this revision.
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
      'B', 'BUY', NUMERIC '0.1', 150.00, FALSE, 'MARKET', 50000000, 150, NUMERIC '0.02'));
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
      'The market-only order-guard fire drill (owner directive 2026-07-21, bigquery/100_market_only_order_guard.sql) found a regression: either a must-reject case (oversized notional/max_loss, non-MARKET order_type, unknown or sub-$1M ADV, expected implementation shortfall over the strategy horizon budget, low open interest, non-positive qty/contracts, NULL max_loss, or a park notional over 1.10x account NAV) incorrectly returned passed=TRUE, or one of the GOOD-PASS cases (a clean, liquid, in-band MARKET order -- equity, equity-park, or options) incorrectly returned passed=FALSE. See payload for which case(s) failed. The pre-craft risk envelope and/or its expected-shortfall liquidity gate is not load-bearing -- investigate immediately before trusting it to block a bad order or admit a good one.',
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
      'All 14 market-only order-guard fire-drill cases (9 equity incl. 2 park + 5 options, owner directive 2026-07-21 -- bigquery/100_market_only_order_guard.sql) correctly asserted: every must-reject case (oversized notional/max_loss, non-MARKET order_type, unknown or sub-$1M ADV, expected shortfall over the strategy horizon budget, low open interest, non-positive qty/contracts, NULL max_loss, park notional over 1.10x account NAV) rejected, and every GOOD-PASS case (equity, equity-park, and options -- clean MARKET orders clearing the applicable liquidity gate) passed. Never crafted a real order or wrote to ops.trading_control.');
  END IF;
END;

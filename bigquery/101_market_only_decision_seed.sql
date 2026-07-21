-- bigquery/101_market_only_decision_seed.sql
-- ONE-TIME SEED — the events.decision_log OWNER-DIRECTIVE entry recording the 2026-07-21
-- market-only order cutover: every IBKR order this system generates becomes MARKET (no limit
-- orders anywhere — entries, exits, park/sweep, options), the 2026-07-20 LIMIT DECISION
-- (RAISE/HOLD/LOWER/ABANDON) and the equity price-band advisory retire, and illiquidity becomes a
-- HARD pre-trade gate instead of a chase decision. This is the "source decision" that
-- bigquery/100_market_only_order_guard.sql's header, the market_only_orders prose invariant
-- (ops/prose_invariants.yaml), and AI_DECISION_REDESIGN.md's follow-up note point back to.
--
-- NOT idempotent DDL. Unlike bigquery/01..99 (CREATE OR REPLACE, safe to re-apply in order), this
-- file writes a DURABLE decision row via ops.sp_log_decision (which also embeds it). It is
-- therefore GUARDED by a NOT-EXISTS check so re-running is a no-op, but it is NOT part of the
-- apply-in-order idempotent sequence and does NOT need to run on every DR restore. Apply it ONCE,
-- live, via the BigQuery MCP, AFTER bigquery/100_market_only_order_guard.sql (the objects this
-- decision authorizes).
--
-- Prereqs: events.decision_log (bigquery/01_schema.sql), ops.sp_log_decision
-- (bigquery/08_ops_procedures.sql), and bigquery/100_market_only_order_guard.sql (the SQL substrate
-- this directive authorizes — analytics.fn_order_guard's new 9-arg market-only + expected-
-- implementation-shortfall liquidity-gate contract, and fn_order_guard_options / ops.sp_fire_drill_
-- order_guard's new 8-arg market-only contract).

IF NOT EXISTS (
  SELECT 1
  FROM `stock-trading-498512.events.decision_log`
  WHERE entry_type = 'owner-directive'
    AND entry_date = DATE '2026-07-21'
    AND title LIKE 'Owner directive 2026-07-21 — Market-only order cutover%'
) THEN
  CALL `stock-trading-498512.ops.sp_log_decision`(
    DATE '2026-07-21',                                        -- in_entry_date
    'owner-directive',                                        -- in_entry_type
    NULL,                                                     -- in_strategy (system-wide, not per-strategy)
    NULL,                                                     -- in_ticker
    'AUTHORIZED',                                             -- in_decision
    NULL,                                                     -- in_conviction
    NULL,                                                     -- in_conviction_pct
    NULL,                                                     -- in_sub_pattern
    NULL,                                                     -- in_theater_check
    'Owner directive 2026-07-21 — Market-only order cutover (limit orders retired; liquidity hard gate added)',  -- in_title
    r"""**Owner directive (2026-07-21).** The ONLY IBKR order instructions this system generates are **MARKET** orders (BUY or SELL): `order_type='MARKET'`, `time_in_force='DAY'`, no `limit_price` argument transmitted. This applies system-wide — entries, exits, park/sweep, and options — with no exceptions and no marketable-limit fallback.

**What retires.** This directive RETIRES: (1) the "marketable limit" convention and the resting-DAY-limit model; (2) the 2026-07-20 owner-directed LIMIT DECISION (RAISE / HOLD / LOWER / ABANDON judgment on a resting limit — `bigquery/99_ai_limit_decision_order_guard.sql`, itself only one day old) — with no limit price to raise, hold, or lower, that judgment has nothing left to decide; (3) the equity >0.5%-off-last price-band advisory that fed it. Park price bands become vacuous (no limit is ever sent) and retire with them; the park 1.10x-NAV magnitude backstop is UNCHANGED and stays.

**Money-safety carried forward unchanged.** Even though the transmitted order is MARKET, the craft still records the live REFERENCE price (last, or bid/ask mid) into the staged payload's existing `limit_price` field — `state.open_orders` (reserved_cash) and `state.daily_staging_totals` (notional) both read `payload.limit_price` unchanged, so reserved-cash and notional-cap math needed ZERO schema change. `analytics.fn_order_guard` receives this same value as its reference price and additionally now enforces `order_type='MARKET'` as a hard rail.

**Liquidity is now a HARD GATE, not a fallback (the actual risk control a limit price used to provide) — and, same-day, an OWNER REVISION replaced a flat dollar-ADV floor + flat spread cap with an expected-implementation-shortfall liquidity gate (Almgren-Thum-Hauptmann-Li 2005: half-spread + 0.142*sigma_daily*participation^0.6; horizon-scaled budget D150/A100/C25/else50 bps; 10% ADV metaorder cap; $1M minimum-ADV floor; ADV proxy protocol; options OI>=500 / spread<=10%).** A flat dollar floor and a flat spread cap are structurally wrong: too tight for liquid low-volatility names, too loose for volatile ones, and a flat spread cap is toxic for mega-caps (a wide-looking spread on a large, calm name is not actually costly to cross) while needlessly rejecting naturally-wide small-caps. If a name is too COSTLY to trade at market, it is a BAD PICK and must not be entered — there is no marketable-limit fallback to fall back to. Encoded in `analytics.fn_order_guard` / `fn_order_guard_options` (`bigquery/100_market_only_order_guard.sql`):
- `expected_shortfall_bps = spread_bps/2 + 0.142 * sigma_daily * participation^0.6 * 10000`, where `participation = notional / adv_usd` (eta=0.142, beta=0.6 — the Almgren et al. 2005 temporary-impact power law; half-spread is the direct crossing cost, the second term is market impact).
- REJECT if the expected shortfall exceeds a horizon-scaled per-strategy budget (longer holding horizon amortizes impact over more time, so tolerates more entry slippage): strategy D 150 bps, A 100 bps, C 25 bps, else (B, E, and any future strategy) 50 bps — provisional pending the orchestrator's final holding-horizon extraction.
- REJECT if participation > 10% of ADV (metaorder / convex-impact risk), if ADV is unknown/NULL, or if ADV is below a $1,000,000 minimum-ADV tail-trap floor.
- REJECT if spread_bps or sigma_daily cannot be computed (the expected shortfall itself would be unknown).
- ADV PROXY PROTOCOL: primary source `avg-90d-usd-volume`; requires >=20 valid trading days of history; names with 20-90 days use the 5-day MEDIAN dollar volume (median, not mean, to resist spikes), capped at 2x median for any single index-reconstitution-type spike; fewer than 20 days defers/rejects.
- Park vehicles (SGOV/VOO) are exempt from the shortfall gate (definitionally liquid); they keep only the 1.10x-NAV magnitude backstop, qty/reference-price sanity, and the order_type=MARKET rail.
- Options: a separate, pragmatic (non-shortfall) gate — reject if open_interest is unknown or < 500 contracts, or if spread_pct (of mid) > 10%. Flagged as conservative starting-point defaults for owner review — a full options shortfall model is out of scope; multi-leg options structures are more sensitive to market-order slippage than single-leg equity.

**Supersedes.** `bigquery/100_market_only_order_guard.sql` is now the single canonical definition of `analytics.fn_order_guard`, `analytics.fn_order_guard_options`, and `ops.sp_fire_drill_order_guard`, superseding `bigquery/99_ai_limit_decision_order_guard.sql` (which itself superseded `bigquery/54_park_policy_voo_cutover.sql` / `bigquery/23_trading_control.sql`) — see the SUPERSEDED markers left in those files pointing here. Claude_Task_Plan.md and Operating_Protocols.md's order-craft, re-craft, and exit sections are rewritten to the market-only + liquidity-gate protocol in the same revision; `ops/prose_invariants.yaml`'s `market_only_orders` invariant guards against re-introducing limit-order language in those two routine-executed files going forward.""",  -- in_body_md
    '{"scope":"every IBKR order this system generates — entries, exits, park/sweep, options","order_type":"MARKET","time_in_force":"DAY","retired":["marketable-limit convention","resting-DAY-limit model","2026-07-20 LIMIT DECISION (RAISE/HOLD/LOWER/ABANDON)","equity >0.5%-off-last price-band advisory","flat dollar-ADV floor + flat spread cap (SPEC v1, superseded same-day by SPEC v2)"],"unchanged":["park 1.10x-NAV magnitude backstop","reference-price recording in payload.limit_price for reserved_cash/notional"],"liquidity_gate":{"model":"expected-implementation-shortfall (Almgren-Thum-Hauptmann-Li 2005)","formula":"expected_shortfall_bps = spread_bps/2 + eta*sigma_daily*participation^0.6*1e4","eta":0.142,"beta":0.6,"budget_bps_by_strategy":{"D":150,"A":100,"B":50,"C":25,"E":50,"default":50},"participation_cap_pct_of_adv":0.10,"adv_floor_usd":1000000,"adv_unknown":"reject","adv_proxy_protocol":"avg-90d-usd-volume primary; >=20 valid trading days required; 5-day median dollar volume for 20-90-day names, capped at 2x median for a single spike; <20 days defer/reject","options_open_interest_floor":500,"options_spread_pct_cap":0.10,"park_exempt":true},"supersedes":"bigquery/99_ai_limit_decision_order_guard.sql","canonical_sql":"bigquery/100_market_only_order_guard.sql"}',  -- in_fields_json
    ['bigquery/100_market_only_order_guard.sql', 'bigquery/99_ai_limit_decision_order_guard.sql', 'Claude_Task_Plan.md', 'Operating_Protocols.md', 'ops/prose_invariants.yaml#market_only_orders'],  -- in_refs
    ['owner-directive', 'market-only', 'order-guard', 'liquidity-gate', 'expected-shortfall', 'governance', 'limit-decision-retired'],  -- in_tags
    NULL,                                                     -- in_superseded_by
    'owner-directive 2026-07-21'                              -- in_source_session
  );
END IF;

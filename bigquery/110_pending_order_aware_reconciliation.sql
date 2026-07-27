-- Pending-order-aware position reconciliation (incident 2026-07-26/27, alert 7ef50e04 /
-- INCIDENT[ref=423ecc02-fdb7-4f47-9445-d8c79d399e8c]). Project: stock-trading-498512.
-- Apply AFTER 109_retire_daily_staging_cap.sql. This file is the NEW single source of truth for
-- `state.position_reconciliation`; it SUPERSEDES the definition of THAT ONE VIEW in
-- bigquery/18_stack_review_fixes.sql:130-153 (18 defines ~10 other, unrelated, still-canonical
-- objects — state.append_only_integrity, state.trigger_attestation, state.go_without_order,
-- state.stalled_runs, … — none of which this file touches or supersedes).
-- Per bigquery/47's header rule (restated by 97 and 107 for the gate cluster this view feeds), any
-- future change to this view must land as a NEW numbered file that supersedes THIS one — never
-- re-apply bigquery/18's CREATE OR REPLACE for this object in isolation.
--
-- ============================ WHY (the 2026-07-26/27 halt) ============================
-- state.position_reconciliation compares two open-share representations that are written at
-- DIFFERENT points in an order's life:
--   * state.current_positions (bigquery/01_schema.sql:129-133) — latest-wins over
--     events.position_events, and D2 writes the OPEN row for a new entry or a pyramid add
--     AT ORDER-STAGING TIME, not at fill (Claude_Task_Plan.md "2. NEW ENTRY CANDIDATES" /
--     "2a. ADD CANDIDATES": "on a GO, the OPEN lifecycle event to events.position_events" and
--     "write a new OPEN events.position_events row with position_key = <strategy>:<ticker>:<add_date>
--     (add_date = this add's staging date)").
--   * analytics.position_lifecycle (bigquery/102_pyramid_aware_lifecycle.sql) — FIFO lots derived
--     purely from state.trade_fills_curated, i.e. it only ever sees shares that ACTUALLY FILLED.
-- So from the moment a BUY is staged until the moment its fill is reconciled, current_positions
-- legitimately LEADS position_lifecycle by exactly the working order's quantity. The old predicate
-- (ABS(share_diff) > 0.01, a flat share tolerance with no order awareness) reads that expected,
-- transient, fully-explained gap as a data-integrity DRIFT — indistinguishable, to it, from the
-- phantom-open-position bug it was actually built to catch (bigquery/23_trading_control.sql:402-410).
--
-- The consequence is not cosmetic. `drifted` is LOGICAL_OR'd account-wide into
-- state.system_health.all_green (bigquery/23_trading_control.sql:428-432) and, since the 2026-07-03
-- B-5-exec/B-6-data promotion, directly into state.trading_enabled's `AND NOT pr.drift` term
-- (bigquery/107_halt_echo_missed_run_gate.sql:173,181) and state.trading_enabled_mechanical's
-- (via system_health.position_drift_detected). ops.sp_assert_trading_enabled /
-- _mechanical (bigquery/85_gate_selfheal_repo_catchup.sql:48-114) then RAISE, aborting the calling
-- routine. Observed live 2026-07-26: ONE pending order (D:GOOGL add-tranche BUY 0.1534,
-- IBKR #84254447, owner-CONFIRMED, status NEW, staged 2026-07-26 00:49:46 MT) produced
-- current_positions 0.2577 vs position_lifecycle 0.1043, share_diff 0.1534 — ~15x the 0.01
-- tolerance — and halted the 2026-07-26 evening D2 run. That was the SECOND consecutive evening D2
-- was blocked, but NOT the same root cause as the first: the 07-25 halt was 4 unrelated open
-- criticals (missed_run / missing_dependency / automation_heartbeat, since resolved), nothing to do
-- with position_reconciliation or GOOGL — the GOOGL order did not even exist yet at that halt (it
-- was staged the following morning, 00:49:46 MT). This file addresses only the 07-26 cause. The
-- 07-26 halt left 6 due PENDING_ANALYSIS theses undrained (all due_date 2026-07-26, two with entry
-- windows closing 2026-07-28); the 07-25 halt did not, since none of those items was due — or had
-- even been enqueued — a day earlier. Because a fill is the ONLY thing that can clear the GOOGL
-- drift, that condition provably cannot self-heal on a non-trading day: 2026-07-26 was a Sunday.
--
-- WORSE — IT IS SELF-LATCHING. The only writer that can close the gap is D2a STEP 0's broker
-- reconciliation (events.trade_fills -> analytics.position_lifecycle), and D2a's own
-- ops.sp_assert_trading_enabled_mechanical('D2a') gate reads this same drift term. A strict reading
-- of that gate ("FATAL ... before anything else") aborts D2a BEFORE Step 0, so the fill that would
-- clear the drift is never reconciled and the halt never lifts. The companion prose change in
-- Claude_Task_Plan.md (D2a) removes that ambiguity on the routine side; this file removes the
-- false trigger on the data side.
--
-- ============================ THE SUPPRESS-ONLY PREDICATE ============================
-- A positive share_diff (current_positions ahead of lifecycle) is EXPLAINED, and suppressed, only
-- to the extent it is covered by that (strategy,ticker)'s still-working BUY quantity in
-- state.open_orders. Formally:
--     residual_share_diff = IF(share_diff > 0, GREATEST(share_diff - pending_buy_shares, 0), share_diff)
--     drifted             = ABS(residual_share_diff) > 0.01
-- Four properties this buys, each deliberate:
--   (1) SUPPRESS-ONLY, never additive. The GREATEST(..., 0) floor plus the `share_diff > 0` guard
--       make |residual_share_diff| <= |share_diff| identically. This predicate can only ever move a
--       row from drifted toward not-drifted; it is arithmetically incapable of MANUFACTURING drift
--       where the raw diff was clean. That property is what makes it safe to consult a second,
--       independently-written table (state.open_orders) from inside a load-bearing safety gate —
--       a bug in the pending term degrades to "the old behavior", never to a spurious halt.
--   (2) BOUNDED masking, not blanket exemption. Only the pending quantity is netted, not the whole
--       row: a genuine 5-share phantom sitting behind a 0.15-share working BUY still leaves ~5
--       shares of residual and still trips the gate. Contrast a naive "a pending order exists ->
--       ignore this ticker" carve-out, which would blind the gate to arbitrarily large real drift.
--   (3) PARTIAL-FILL TOLERANT. The bound is `<=` the pending quantity, not an exact match: when a
--       fractional MARKET order fills partway, lifecycle catches up while state.open_orders still
--       carries the original payload qty, so the residual goes NEGATIVE and clamps to 0 rather than
--       flipping the row back to drifted mid-fill.
--   (4) BUY-SIDE ONLY, by construction. A staged EXIT writes only an exit-pending ANNOTATION to
--       events.position_events; event_type='CLOSE' — the only thing state.current_positions filters
--       on — is written by D2a STEP 0 at FILL time, never at staging. So a pending SELL structurally
--       cannot depress current_positions ahead of lifecycle and needs no netting term; adding one
--       would be the single way to break property (1).
--
-- STALENESS BOUND (a pending row must not suppress forever). A row qualifies only if it is either
-- still inside its own entry window (entry_window_close >= today MT) or was (re-)staged within the
-- last 7 days. state.open_orders is already pending-only — a fill/expiry writes a terminal-status
-- queue_events row and the latest-wins projection drops it (bigquery/01_schema.sql:237-242) — and
-- the DAY-only TIF discipline re-crafts every live order each session, refreshing staged_ts. The
-- 7-day arm therefore catches the case that registry hygiene cannot: D2a itself stopping, so orders
-- neither fill nor expire. Both arms are present deliberately, so the bound holds whether or not a
-- given re-craft writes a fresh queue_events row.
--
-- NULL-STRATEGY PARK LEGS ARE EXCLUDED, same as the two existing CTEs. Park orders (the live
-- park-derisk-VOO / park-rerisk-SGOV pair) carry strategy=NULL and never reach
-- events.position_events or analytics.position_lifecycle at all — park fills route to
-- events.parking_events, and position_lifecycle additionally hard-filters ticker != 'SGOV'
-- (RUNBOOK §29). Keeping `strategy IS NOT NULL AND ticker IS NOT NULL` on the pending CTE means a
-- park leg can never introduce a (NULL, 'SGOV') reconciliation group that does not exist today.
--
-- COLUMN CONTRACT. All 7 original columns keep their names, types, and meanings — share_diff is
-- still the RAW difference and `drifted` is still the gate's boolean — so every consumer keeps
-- working unchanged: state.system_health (bigquery/23:428,431), state.trading_enabled +
-- state.trading_enabled_mechanical + state.b3_trading_enabled_check + ops.sp_auto_resolve_alerts
-- (bigquery/107:173,194,288,363,559), dbt/models/state/{system_health,trading_enabled}.sql, and
-- ops.sp_sq_cadence_check's advisory `position_drift` warning
-- (bigquery/75_scheduled_query_wrappers.sql:290-297, which destructures the
-- 5 non-checked_at columns by name). No consumer anywhere in the repo does SELECT * against this
-- view, so the five ADDED columns (pending_buy_shares, pending_buy_item_keys, residual_share_diff,
-- drifted_raw, explained_by_pending_buy) are additive-safe. drifted_raw is the pre-2026-07-27
-- predicate, retained verbatim so an audit can always see what the old gate WOULD have said.

CREATE OR REPLACE VIEW `stock-trading-498512.state.position_reconciliation` AS
WITH cp AS (
  SELECT strategy, ticker, SUM(shares) AS current_positions_shares
  FROM `stock-trading-498512.state.current_positions`
  WHERE strategy IS NOT NULL AND ticker IS NOT NULL
  GROUP BY strategy, ticker
),
lc AS (
  SELECT strategy, ticker, SUM(shares) AS lifecycle_open_shares
  FROM `stock-trading-498512.analytics.position_lifecycle`
  WHERE exit_date IS NULL AND strategy IS NOT NULL AND ticker IS NOT NULL
  GROUP BY strategy, ticker
),
-- Still-working BUY quantity per (strategy,ticker). state.open_orders is already filtered to
-- status='pending' (bigquery/01_schema.sql:242); side is the UPPER()'d payload side, so a NULL
-- side is excluded by the equality. qty > 0 is defensive: a malformed negative qty would otherwise
-- widen the suppression window rather than narrow it.
pend AS (
  SELECT
    strategy,
    ticker,
    SUM(qty)             AS pending_buy_shares,
    ARRAY_AGG(item_key ORDER BY item_key) AS pending_buy_item_keys
  FROM `stock-trading-498512.state.open_orders`
  WHERE side = 'BUY'
    AND qty > 0
    AND strategy IS NOT NULL AND ticker IS NOT NULL
    AND (
      -- still inside its own entry window …
      (entry_window_close IS NOT NULL AND entry_window_close >= CURRENT_DATE('America/Denver'))
      -- … or (re-)staged recently enough to still be a live, daily-re-crafted intent.
      OR staged_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
    )
  GROUP BY strategy, ticker
),
joined AS (
  SELECT
    strategy,
    ticker,
    COALESCE(cp.current_positions_shares, 0) AS current_positions_shares,
    COALESCE(lc.lifecycle_open_shares, 0)    AS lifecycle_open_shares,
    COALESCE(cp.current_positions_shares, 0) - COALESCE(lc.lifecycle_open_shares, 0) AS share_diff
  FROM cp FULL OUTER JOIN lc USING (strategy, ticker)
),
-- LEFT JOIN, never FULL OUTER: a pending BUY on a (strategy,ticker) with no position on EITHER side
-- must not conjure a reconciliation row that does not otherwise exist.
netted AS (
  SELECT
    j.strategy,
    j.ticker,
    j.current_positions_shares,
    j.lifecycle_open_shares,
    j.share_diff,
    COALESCE(p.pending_buy_shares, CAST(0 AS NUMERIC))     AS pending_buy_shares,
    COALESCE(p.pending_buy_item_keys, [])                  AS pending_buy_item_keys,
    IF(j.share_diff > 0,
       GREATEST(j.share_diff - COALESCE(p.pending_buy_shares, CAST(0 AS NUMERIC)), CAST(0 AS NUMERIC)),
       j.share_diff)                                       AS residual_share_diff
  FROM joined j
  LEFT JOIN pend p USING (strategy, ticker)
)
SELECT
  strategy,
  ticker,
  current_positions_shares,
  lifecycle_open_shares,
  share_diff,
  pending_buy_shares,
  pending_buy_item_keys,
  residual_share_diff,
  -- The pre-2026-07-27 predicate, kept for observability/audit: what the old gate would have said.
  ABS(share_diff) > 0.01 AS drifted_raw,
  -- TRUE exactly when the old predicate fired and the new one does not — i.e. this row is a benign
  -- staged-but-unfilled BUY lag. This is the flag D2a/D3/W4 should cite before escalating anything.
  ABS(share_diff) > 0.01 AND ABS(residual_share_diff) <= 0.01 AS explained_by_pending_buy,
  -- tolerance 0.01 share, unchanged from bigquery/18: ignores fractional dividend-reinvest noise;
  -- catches a whole position present in one representation but not the other (a real 2%-sleeve
  -- position is >0.1 share). What changed is only WHICH difference is measured against it.
  ABS(residual_share_diff) > 0.01 AS drifted,
  CURRENT_TIMESTAMP() AS checked_at
FROM netted;

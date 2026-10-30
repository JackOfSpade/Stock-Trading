# D2a — Claude_Task_Plan.md history archive

**HISTORY ONLY — NOT INSTRUCTIONS.** Nothing in this file binds any routine, and no routine needs to read it to do its job. Each entry is the full original text of a `Claude_Task_Plan.md` paragraph as it stood on 2026-10-30, kept for its incident evidence and reasoning; the plan now carries a condensed, rules-only version that points here. Where the two differ, the plan wins. Superseded, retired or since-corrected instructions appear here exactly as they were written; never execute them from this file.

## H-D2a-01 — For that ordinary path, write the position lifecycle event to events.position_events (an OPEN on an entry — r

_Moved verbatim from `Claude_Task_Plan.md` (D2a, was line 1212) on 2026-10-30. Historical record only; the binding rule is the condensed text in the plan._

  For that ordinary path, write the position lifecycle event to `events.position_events` (an OPEN on an entry — **reusing the SAME `position_key` the staging step recorded in the order's `payload.position_key` (STAGING-OPEN KEY INVARIANT, item 2), so this fill OPEN SUPERSEDES that order's staging-time provisional OPEN for that key rather than minting a SECOND row that would strand the provisional as a phantom on a SUCCESSFUL fill; mint a fresh key here ONLY for a legacy order that recorded no `payload.position_key`, i.e. one that wrote no staging OPEN** — with `cost_basis = shares×price +
  commission`, contract_id, convergence_target / time_exit_date / conviction / source_thesis_ref **and
  `invalidation_status`** from the staging entry — **this field list is a MINIMUM, not a closed set: the
  superseding row must reproduce EVERY column the provisional row populated, because the raw lifecycle event
  is latest-row-wins; `state.current_positions` carries forward only `invalidation_status` and `ltcg_date`, so
  every other omitted column is immediately destroyed live and every omission corrupts the raw audit record**
  (see "Shared rules referenced across prompts" → "An omitted field is a destroyed field"; the same
  obligation binds the `CLOSE` arm below, D2's exit-staging `EXIT_PENDING` write, and every `ADJUST`).
  `invalidation_status` is called out by name because it is the one field with no other source — it is
  assessed once at staging time and exists nowhere else, so dropping it is unrecoverable except by an
  append-only echo-forward repair; it is carried **byte-identical**, never re-derived and never re-stamped.
  Omitting it silently flips `invalidation_criteria_evaluable` FALSE and makes the position structurally
  ineligible for adds (this is exactly what happened to `D:GEV:2026-08-03`, `ops.alerts` 07125db5, repaired by
  `bigquery/137`) — **`source_thesis_ref` is the bare `events.decision_log.entry_id` UUID of the authorizing
  thesis, NOT a human label like `'D2 2026-07-17 TSM D GO'`** (see "Decision-log lifecycle" → CURRENT ERA
  discipline 3: `analytics.thesis_outcomes` now prefers this FK over its nearest-entry_date heuristic, and a
  prose value silently forfeits that and falls back to date-guessing); **a CLOSE on an exit — which carries the SAME field obligation as the OPEN arm above and is not exempt for being terminal: echo every column the position's current `state.current_positions` row populated, `invalidation_status` included, so the immutable criteria survive into the closed record that W5 calibration and any post-hoc thesis review read. This arm is where `B:MDT:2026-06-17` lost the `NOT_DISCRETELY_RECORDED_AT_ENTRY` marker `bigquery/117` had written for it.**). For ordinary fills,
  flip the affected position ORDER-STAGED→OPEN / exit-pending→CLOSED, and
  set the matching `state.open_orders` `ORDER_STAGED` row terminal `filled` (§11); update strategy sector counts
  and any KL #12 event membership; write the GO/close decision via **`CALL ops.sp_log_decision(...)`** (appends
  `events.decision_log` + embeds in the same call — verify any time via `state.embedding_health`, `is_healthy =
  TRUE`). Realized P&L comes from the connector's `realized_pnl` field — never inferred; aggregate exchange-split
  partials by `order_id`. **Resolve any open `termination_close_staged` alert this fill satisfies** (match via
  `state.open_orders.instruction_id`, same as the ORDER-STAGED→CLOSED flip above): `UPDATE ops.alerts SET
  resolved=TRUE, resolved_ts=CURRENT_TIMESTAMP(), resolved_note='closed by fill <trade_id>' WHERE
  category='termination_close_staged' AND NOT resolved AND JSON_VALUE(payload,'$.instruction_id') = <this fill's
  originating instruction_id>`. **Resolve any open `position_reconciliation_lag` alert this fill closes** (bug
  fix, 2026-07-21 — the 2026-07-20 root-cause fix landed this clause only in the "IBKR connector usage"
  *operational-summary* section, whose own header names Operating_Protocols.md §11 as canonical — neither §11 nor
  this, the actual STEP 0 bullet D2a executes, ever carried it, so it silently never ran; confirmed live same-day:
  D2a completed 2026-07-21 and correctly wrote both the ISRG and TSM reconciling fills below, D3's later run
  attested "positions match connector," yet both alerts stayed `resolved=false` until manually closed):
  `UPDATE ops.alerts SET resolved=TRUE, resolved_ts=CURRENT_TIMESTAMP(), resolved_note='closed by fill <trade_id>:
  now reconciled into state.current_positions' WHERE category='position_reconciliation_lag' AND NOT resolved AND
  JSON_VALUE(payload,'$.ticker') = <this fill's ticker>` — **match by ticker ONLY, never also require
  `payload.strategy` equality** (the strategy-scoped match was the second half of the same bug: D1 raises this
  alert, and guesses a strategy attribution, BEFORE reconciliation runs, so a name that turns out to be a genuine
  independent entry under a *different* strategy bucket than D1 guessed — e.g. 2026-07-21's ISRG, D1 assumed a
  strategy-D duplicate re-craft but the reconciled fill correctly opened a separate strategy-B position — would
  never match a strategy-scoped condition even with the clause correctly wired in). **Park mechanical
  sweep/cover/DRIP fills are recorded to `events.parking_events`
  (with `ticker` = the current park vehicle), NOT `events.trade_fills`** (see the cash-flattening bullet);
  `state.park_reconciliation` reconciles events-side park shares to the connector holding — `SELECT vehicle
  FROM state.park_policy_current` for which ticker/contract_id is live right now (SGOV 424099317, VOO
  136155102 — §13; `state.sgov_reconciliation` is FROZEN to SGOV-only history as of the 2026-07-15 cutover
  and no longer the live reconciliation basis).
- **Partial-sell reconciliation — FIFO across tranches (owner directive 2026-07-22 — supports the D2 "Exit
  sizing" rule's PARTIAL sell/trim option; not a liquidity/sizing rail, a bookkeeping procedure).** A SELL
  fill that does NOT zero the (strategy,ticker) position (the connector's post-fill holding for that ticker
  is still > 0) must NOT be booked as a full CLOSE. Apply the sold shares FIFO across the position's open
  tranches (mirroring `analytics.position_lifecycle`, the fills-derived truth — oldest open tranche consumed
  first): write a CLOSE `events.position_events` row for each tranche FULLY consumed by the sale, and for the
  single tranche partially consumed at the FIFO boundary write an `event_type='ADJUST'` row (**NOT** `'CLOSE'`)
  with **`status='OPEN'`** — the EXACT literal string `'OPEN'` (several live views — `analytics.strategy_nav`,
  `state.daily_briefing`, `weekly_report` — filter on `status='OPEN'`; any other label silently drops the
  residual from NAV/sizing/briefing) — `shares` = that tranche's remaining shares after the sale, `cost_basis`
  reduced proportionally (`remaining_shares / original_shares × original cost_basis`). Realized P&L keeps
  flowing from `events.trade_fills` (connector `realized_pnl`) exactly as today — the ADJUST row records only
  the reduced OPEN state, not realized P&L. `state.current_positions` (latest non-CLOSE row per `position_key`)
  then shows the reduced position automatically. Tranches the FIFO cursor never reaches are left untouched.
- **Fill-to-ORDER_STAGED matching, partial-sell-aware.** Partial sells make two pending SELL rows for the same
  (ticker, contract_id, side) more likely (a trim order + a later full-exit order). When resolving a fill
  against pending `state.open_orders` rows (the ORDER-STAGED→OPEN/exit-pending→CLOSED flip above), prefer
  matching the connector order/instruction reference to the specific `ORDER_STAGED` row's
  `payload.instruction_id` (with a qty-consistency check: fill qty <= that row's staged qty) BEFORE falling
  back to the coarse (ticker, contract_id, side) match.
- **Post-close DRIP dust — audited STK-only liquidation (2026-08-02 hardening).** This is NOT a generic
  "connector position absent from state" liquidation. Every run, start from every positive connector holding
  absent from `state.current_positions`, including residuals whose fills were reconciled on an earlier run.
  Prove its source with an executable fill-residual test: for the exact contract, apply every later SELL FIFO to
  earlier BUYs in `(fill_ts,trade_id)` order; the remaining quantities of candidate BUY fills must sum exactly
  to connector `P.quantity` (within the connector's stated quantity precision), each candidate must be after the
  strategy/ticker's last terminal CLOSE, have no matching BUY `ORDER_STAGED`/source-order reference, and carry
  affirmative reinvestment evidence (`raw.exchange='IBDRIPUS'` or `raw.note` contains DRIP/dividend-reinvestment
  language). A mere historical BUY on the same contract is never provenance. Any missing/ambiguous linkage routes
  to `position_mirror_gap`, never this path.

## H-D2a-02 — Liquidate each classified residual by this deterministic procedure:

_Moved verbatim from `Claude_Task_Plan.md` (D2a, was line 1318) on 2026-10-30. Historical record only; the binding rule is the condensed text in the plan._

  Liquidate each classified residual by this deterministic procedure:
  1. **HALT + CONFLICT GATES.** Use the carried `state.trading_enabled_mechanical` verdict. Audited dust is
     excluded from `state.position_reconciliation` by bigquery/126, so a >0.01-share dust lot cannot halt the
     only path that clears itself; unrelated health failures still block a new craft. If FALSE, do not create a
     NEW instruction or queue row. Also do not act while ANY other pending `state.open_orders` SELL, pending
     instruction, or live/working SELL exists for the contract, dust or ordinary. The only allowed pending row
     is this exact `item_key`, handled by step 2; ambiguity is a no-action diagnostic.
     **ADOPTION OF AN UNREGISTERED DUST LIQUIDATION — PRE-FILL PATH ONLY (2026-08-02).** SCOPE, corrected
     same day: this block handles an unregistered order seen while it is still LIVE/WORKING, i.e. before it
     fills. It canNOT be the fix for an order that has ALREADY filled — this dust loop only iterates
     residuals still present as a positive connector holding, and by the time D2a next runs (22:40 UTC, hours
     after the open) a filled liquidation has both zeroed that holding and gone terminal, so neither this
     loop nor this block would be reached. The post-fill case is handled EARLIER in this step, pre-insert, by
     the fill-reconciliation bullet's never-registered arm — which is where it must be, because the strategy
     attribution has to be correct at INSERT time into append-only `events.trade_fills`. Keep both: this one
     registers a pending order so step 2 can track it; that one attributes an already-filled one. A dust-liquidation SELL can exist at the connector with NO
     `events.queue_events` row: the operator tapped an instruction D2a did not stage, an instruction was
     crafted before this registry existed, or the order was placed by hand. In that case the guard above
     matches ("a live/working SELL exists for the contract") and would classify it as ambiguity and do
     nothing — so step 2 never runs, no `liquidation-fill` is ever logged, the SELL never joins the dust FIFO
     lane, and the source BUY stays OPEN in `analytics.position_lifecycle` FOREVER while the broker is flat.
     That is not benign: the residual stays permanently unresolved, which via D2's UNRESOLVED-DUST RE-ENTRY
     GATE permanently blocks any future BUY re-entry into that contract. ADOPT instead of declining, when ALL
     of these hold: (a) the observed SELL's `contract_id` joins to exactly ONE `fill_role='source-buy'` row in
     `analytics.dust_classified_fills` (via that row's `trade_id` in `state.trade_fills_curated`), yielding its
     `dust_id`, `source_trade_id` and source `strategy` — zero or 2+ matches is genuine ambiguity, keep the
     no-action diagnostic; (b) the order is `side='SELL'`, security type `STK`; (c) its quantity does not
     exceed the outstanding residual for that `dust_id`. Then acquire the same step-5 mutex (serializing the
     registry write; no connector call is made, so release immediately after the queue write), append an
     `ORDER_STAGED` queue row reconstructed from the observed order with the payload shape step 5 writes plus
     `adopted:true` and `adopted_order_id:<connector order id>`, and set `instruction_id` NULL — the step-3
     ATTEMPT CAP counts DISTINCT non-null `payload.instruction_id`, and an order D2a did not craft must not
     consume its own retry budget. Then continue into step 2, which reconciles the pending/filled order
     normally and emits the `liquidation-fill` record that `analytics.dust_classified_fills` needs.
     Record the adoption in the run's decision log so a reconstructed row is never mistaken for a staged one.
  2. **RECONCILE THIS DUST REGISTRY ROW.** Read `get_order_instructions`, `get_account_orders`, fills, and the
     latest `events.queue_events` row for exact `item_key`. A matching pending instruction or live SELL means
     do nothing. Reconciled matching SELL fills set the row terminal `filled` only when their aggregate quantity
     reaches the staged quantity; a partial fill keeps the row pending for the
     remaining live order. Before continuing generic fill mirroring, every exact partial or complete dust SELL
     fill logs `{record_type:'liquidation-fill',classification:'dust',dust_id,liquidation_trade_id}` idempotently,
     and its `events.trade_fills.strategy` is the common source strategy from `F[]` (never NULL or guessed).
     A completed item additionally logs `disposition='filled'`, `dust_id`, and the exact
     `liquidation_trade_ids:[...]` array. `analytics.dust_classified_fills` uses those ids to put source BUYs and
     liquidation SELLs in the same isolated FIFO lane. Write no strategy-position OPEN/CLOSE/ADJUST event. If the prior instruction is absent from both
     connector reads, no fill exists, and `P` remains, append an `expired` row for the same item key before retry.
     If the exact connector holding is gone, terminal the item independently of fill matching and record whether
     closure was `matched-fill`, `manual`, or `external`; never infer a strategy position event.
  3. **ATTEMPT CAP BY RESIDUAL.** Count DISTINCT non-null `payload.instruction_id` values in `events.queue_events`
     where `queue='ORDER_STAGED'`, `item_key` is exact, and `payload.order_class='drip-dust-liquidation'`. At
     three, create no fourth instruction; terminal the row `abandoned` and raise `dust_liquidation_failed` with
     `dust_id`, anchor/source trade ids, contract id, ticker, positive shares, current value, and attempts. A later dust
     fill in the same ticker has a different anchor/item key and starts at attempt 1.
  4. **FRESH RE-CHECK + STANDARD GUARD.** Immediately re-read `P`, the FIFO residual equation, and every
     eligibility condition. Require a current realtime `get_price_snapshot` with non-empty bid/ask and fresh
     timestamp under Operating Protocol §11. A settled close or connector mark is diagnostic only and NEVER
     authorizes a MARKET craft; outside a live executable session, defer without consuming an attempt and raise
     a noncritical due-next-RTH diagnostic. Run
     `analytics.fn_order_guard(NULL,'SELL',P.quantity,<ref_price>,'MARKET')`. On failure, do not craft and
     raise `order_guard_block`; quantity is exactly the current positive `P.quantity`, never cached or absolute.
  5. **SERIALIZED CRAFT + DURABLE STAGE.** Set `claim_token` to this D2a run's non-null `session_id` already
     passed to `ops.sp_routine_start` (do not generate an unrelated UUID), call
     `ops.sp_acquire_dust_order_mutex(claim_token,item_key,claimed)` (bigquery/126), and proceed only when
     `claimed=TRUE`. This pre-seeded singleton row is the concurrency control; an `events.queue_events` item-key
     precheck is not one because BigQuery primary keys are NOT ENFORCED. While holding the lease, re-read the
     exact item row and connector instructions/orders once more. Any competing SELL or changed quantity releases
     the mutex and defers. Then, BEFORE the external call, append a recoverable `events.queue_events` row with
     `queue='ORDER_STAGED'`, `status='crafting'`, `item_type='drip-dust-liquidation'`, exact `item_key`, and the
     full dust/source/contract/qty/guard/`claim_session_id` payload but no instruction id. Re-read the mutex and require
     it still carries this token immediately before create. On a guard pass, call
     `create_order_instruction(P.contract_id,'SELL',P.quantity, order_type='MARKET',time_in_force='DAY')`, then
     INSERT a pending `events.queue_events` row with
     `queue='ORDER_STAGED'`, `item_type='drip-dust-liquidation'`, exact `item_key`, ticker, and payload
     `{order_class:'drip-dust-liquidation', dust_id, anchor_trade_id, source_trade_ids:[...], source_strategy, contract_id, side:'SELL', qty,
     limit_price:<ref_price>, tif:'DAY', instruction_id, attempt, guard_passed, guard_reasons}`. Finally log one
     `entry_type='drip-dust'` disposition row carrying the same identifiers and `disposition='staged'`.
     Staging atomicity applies: create failure terminals the crafting row `expired` and fails the run; if the
     pending-row INSERT fails after create, immediately `delete_order_instruction(instruction_id)`, terminal the
     crafting row only after deletion is confirmed, raise critical `staging`, and fail the
     run; if only the decision log fails after the queue write, retain the recoverable registry row, raise
     critical `staging`, and do not log the run completed. Release with
     `ops.sp_release_dust_order_mutex(claim_token,item_key)` only after the queue write (or after cleanup on every
     failure path). Expiry is diagnostic, not permission for `sp_acquire_dust_order_mutex` to steal the lock.
     A later run joins `claim_session_id` directly to `ops.run_log.session_id` and first reconciles any stale
     `crafting` row: **(A)** recover a uniquely matching connector instruction
     into a pending row, **(B)** terminal an exact post-claim fill while recording its trade id(s), or **(C)**—only when the old
     runner has a terminal status OR its latest row is only `started` from >3 hours ago (the repo-wide dead-run
     criterion), the lease is expired, and connector instructions/orders/fills are all absent—append
     `expired`, call `ops.sp_recover_expired_dust_order_mutex(visible_owner_token,visible_item_key,released)`,
     require `released=TRUE`, and retry. Otherwise it blocks and raises `staging`.
     **Branches (A) and (B) MUST release the mutex as well (adversarial-review finding, 2026-08-02 — the
     original wording attached the unlock to (C) alone).** Each of them has just read the connector and
     established what actually became of the order, which is precisely the precondition the
     `sp_acquire_dust_order_mutex` body demands before a stale owner may be cleared; so each MUST call
     `ops.sp_release_dust_order_mutex(visible_owner_token,visible_item_key)` once its own recovery write has
     committed. Use `sp_release_...`, **NOT** `sp_recover_expired_...`: the latter additionally requires
     `lease_expires_at <= CURRENT_TIMESTAMP()`, so inside the 10-minute lease window it silently no-ops and
     leaves the lock held. Without this, a process death between a successful `create_order_instruction` and
     the pending-row INSERT strands `owner_token` on the dead session permanently — the singleton is ONE
     global row and expiry is deliberately not self-healing (stealing on expiry would let two runs each stage
     a SELL for the same residual), so every later run for EVERY ticker gets `claimed=FALSE` and falls through
     to the `staging` alert above until an operator clears it by hand.

## H-D2a-03 — The currentvalue test is authoritative only at classification/craft time; analytics reads the persisted

_Moved verbatim from `Claude_Task_Plan.md` (D2a, was line 1421) on 2026-10-30. Historical record only; the binding rule is the condensed text in the plan._

  The current-value test is authoritative only at classification/craft time; analytics reads the persisted
  source-fill fact rather than recomputing historical BUY notional, so the flag is immutable after liquidation.
  Dust is excluded from thesis pairing, closed-trade/gate counters, deployed TWR, and deployed-day accumulation
  (bigquery/123/124/125/126). Heal `dust_liquidation_failed` by exact `dust_id` once the exact connector holding
  disappears, recording matched/manual/external closure even if no staged SELL fill matches. Heal
  `position_mirror_gap` only when the exact contract is mirrored or
  absent — becoming cheap is not proof of DRIP provenance. DRIP is account-wide OFF as of 2026-08-02; this path
  remains the fail-safe if it recurs.
- Read (do not transcribe) live positions, cash, and net-liquidation from `get_account_positions` +
  `get_account_summary` + `get_account_balances`; reconcile account-level drift (dividends, fees, splits) to the
  connector truth while preserving per-strategy cost-basis attribution (`get_price_history` with
  `include_corporate_actions: true` + the DRIP/dividend rows). Marks/market-values/unrealized-P&L are NOT written
  into the events-side state — only cost-basis + strategy allocation are; live marks flow through
  `events.daily_marks` into the TWR engine (below).
- **Connector-sanity band on net-liquidation.** Compare this session's `get_account_summary` net-liquidation to
  `state.account_latest.nav` (the prior snapshot — D2a runs before its own Step 0b, so today's row does not
  exist yet: a clean prior baseline; under the Fri/Sat-skip daily-tier schedule this is not always literally
  *yesterday's* — see Step 0b below). **Stale-baseline awareness (owner directive 2026-07-25 CATCH-UP
  EVIDENCE WINDOW) — when D2a has AT LEAST ONE missed trading day since its own last successful completion:**
  **D2A MISSED-TRADING-DAY COUNT (bug fix, 2026-08-08, corrected same day, and 2026-09-14 — the predicate this bullet, the
  MARKET-MOVE TERM below, and step 1's `daily_marks` missed-day backfill further down this section all now
  share).** **Anchor on `run_date`, never on a completion timestamp (correction, 2026-08-08 — the version
  that first landed earlier the same day anchored on `DATE(last_completed_ts, 'America/Denver')` and was
  wrong).** `ops.run_log.run_date` is the routine's OWN declaration of which trading day it processed —
  written once, at logging time, and invariant to how long the run took or when it happened to finish.
  `log_ts` is not: a run that CROSSES LOCAL MIDNIGHT lands `DATE(log_ts, 'America/Denver')` one calendar
  day AFTER the trading day the run actually covered, silently re-dating a long (or midnight-adjacent) run
  onto the following day. Confirmed live in `ops.run_log`: D2a's Sunday 2026-08-02 run started 23:56 MT and
  completed 00:06 MT the next day — `run_date = 2026-08-02` but `DATE(log_ts, 'America/Denver') =
  2026-08-03`. Simulating both predicates across every historical D2a completion shows this is not merely
  theoretical: the run that started 2026-08-03 (Monday) computed `missed_trading_days = 0` under the OLD
  `log_ts`-anchored predicate — silently suppressing the stale-baseline check — vs. the correct `1` under
  the `run_date`-anchored fix below (every non-midnight-crossing day in the same trace agrees old-vs-new,
  confirming this is specifically a midnight-crossing bug, not a general miscount).
  ```sql
  SELECT COUNT(*) AS missed_trading_days
  FROM `stock-trading-498512.state.market_calendar` mc
  WHERE mc.is_trading_day
    AND mc.cal_date > COALESCE(
          (SELECT MAX(IF(log_ts < TIMESTAMP(DATETIME(run_date, TIME '16:00:00'), 'America/New_York'),
                         DATE_SUB(run_date, INTERVAL 1 DAY), run_date))
             FROM `stock-trading-498512.ops.run_log`
            WHERE routine = 'D2a' AND status = 'completed'),
          DATE((SELECT cadence_fallback_window_start_ts FROM `stock-trading-498512.state.routine_catchup_window`
                WHERE routine = 'D2a'), 'America/Denver')
        )
    AND mc.cal_date < (SELECT today FROM `stock-trading-498512.state.trading_day_today`)
  ```
  **PRE-OPEN COVERAGE ANCHOR (fixed 2026-10-25, interactive owner session, from D1 alert `2b09297f` and
  info `d2a_missed_day_predicate_blind_to_preopen_catchup`).** The anchor is the last session a completed
  D2a actually COVERED, not its raw `run_date`. A PRE-OPEN SLOT LIMB row (logged before its `run_date`'s
  16:00 `America/New_York` close) is stamped `run_date` = today but ingests only the prior completed
  session, so it covers through `run_date - 1`; every other row covers its own `run_date`. The
  trading-day half of the limb predicate is deliberately omitted: on a non-trading `run_date` the bounds
  `> run_date - 1` and `> run_date` select the same trading days, and a `market_calendar` join inside
  this scalar subquery is rejected by BigQuery as an un-de-correlatable correlated subquery (tested). Measured: D2a's 2026-10-23 02:47 MT pre-open
  catch-up stamped `run_date` 2026-10-23 while marks stopped at 2026-10-22, so the Sunday 2026-10-25 run
  read `missed_trading_days = 0` and skipped the stale-baseline annotation and full-gap MARKET-MOVE TERM for
  Friday 10-23 (its ordinary `last_trading_day` ingest still wrote the 10-23 marks). The corrected anchor
  reads 1. Replaying both forms at every D2a start since 2026-08-01 changes ONLY that run; a pre-open row
  followed by the same day's post-close run (2026-09-22) is unaffected because `MAX` picks the evening row.
  Same `log_ts` vs 16:00 ET test as `bigquery/265_snapshot_stale_preopen_guard.sql`. The `cadence_watch`
  dead-man is deliberately NOT changed: the pre-open limb on a Friday fills the missed THURSDAY slot, and
  Friday has no D2a slot at all (Sun-Thu cron), so there was no "10-23 evening slot" to miss; and
  `state.freshness.marks_current` reading TRUE through Saturday is its designed cadence-aware behavior
  (`marks_due_through` advances to Friday only once Sunday's 22:40 UTC slot elapses).
  **Never-completed guard:** the inner `MAX(...)` subquery returns `NULL` exactly when D2a has never
  logged a `completed` row — the identical condition `state.routine_catchup_window.never_completed` names
  for this routine (both derive from the same `ops.run_log` `status='completed'` predicate) — so falling
  through the `COALESCE` to that view's own `cadence_fallback_window_start_ts` (the `daily_sun_thu`
  cadence-sized fallback, 3 days) on a bare `NULL` is the correct guard, not a coincidence: it reuses the
  SAME never-completed fallback every other CATCH-UP EVIDENCE WINDOW consumer in this file already falls
  back to, rather than inventing a second one. D2a has run continuously since inception, so this path is a
  defensive floor, not a case expected to fire.

## H-D2a-04 — gated on missed_trading_days = 1 (never 1) — on a read failure against ops.run_log /

_Moved verbatim from `Claude_Task_Plan.md` (D2a, was line 1521) on 2026-10-30. Historical record only; the binding rule is the condensed text in the plan._

  gated on `missed_trading_days >= 1` (never `> 1`) — on a read failure against `ops.run_log` /
  `state.market_calendar` / `state.trading_day_today`, fall back to `days since D2a's
  own last completed ops.run_log run > 0`. **Why a count, not the raw `state.routine_catchup_window.window_days`
  figure the old wording ("spans MORE than 1 trading day") cited:** that column is CONTINUOUS CALENDAR time
  (`TIMESTAMP_DIFF(...)/1440.0`, `bigquery/105_routine_catchup_window.sql`), not a trading-day count, and the
  two now disagree exactly on the case the Fri/Sat schedule change makes routine: a Thursday→Sunday gap is
  `window_days` ≈ 3.0 (it spans Fri/Sat/Sun) but exactly ONE missed trading day (Friday). Read literally as
  "more than 1 trading day," the old wording never fired on that single Friday; read against the ~3.0
  calendar-day figure it always would have — an ambiguity this file can no longer leave standing now that a
  Thu→Sun gap is the WEEKLY NORMAL CASE, not a rare outage. **When `missed_trading_days >= 1`:** this baseline
  is that many trading days stale, not a true prior-session snapshot — annotate the actual day-count gap in the
  alert/decision note below and let the MARKET-MOVE TERM's `expected_ΔNAV` sum the mechanical mark-to-market
  move across the FULL gap (not a single day) before judging the residual, so a genuine multi-day catch-up — or
  the now-routine Thu→Sun weekly gap — doesn't misclassify as connector corruption. If the day-over-day change exceeds **±15%** and is NOT fully explained
  by what this session reconciled (a fill's realized P&L, a dividend, a deposit/withdrawal, a confirmed split) —
  **NOR by ordinary mark-to-market movement of the held book** — treat it as a candidate connector-corruption
  signal, but apply the **MARKET-MOVE TERM** below before halting.
  - **MARKET-MOVE TERM — crash-day escape hatch (finding DEF-1, 2026-07-17).** Market MOVEMENT was absent from
    the escape list above, so a genuine crash / melt-up day (the book is now ~97% VOO equity) would exceed ±15%
    and latch a FALSE `connector_sanity` critical on the exact day a real move happens — the day kill-trigger
    exits must stage. This mirrors the engine-verification bullet's "absent a matching large market move" carve-out
    further down this section. Compute the expected mark-to-market ΔNAV **mechanically** (no session judgment —
    ITEM-16 safe): `expected_ΔNAV = Σ_held ( shares × (today get_price_snapshot − yesterday events.daily_marks
    close) ) + park_shares × Δ(park-vehicle price) + reconciled_flows`, where `reconciled_flows` is the SAME
    signed fills'-realized-P&L / dividend / deposit-withdrawal / confirmed-split cash the escape list already
    covers (when `missed_trading_days >= 1` per the D2A MISSED-TRADING-DAY COUNT clause above,
    "yesterday" here is the last `events.daily_marks` close as of D2a's last successful completion, not
    literally the calendar day before today — consistent with the marks backfill below). Then take the
    **RESIDUAL** `|ΔNLV − expected_ΔNAV|` and branch:
    - **RESIDUAL within tolerance** (`<= max($50, 2% × prior_nav)`): the ±15% move is real market P&L, not
      connector corruption. Do **NOT** halt — `CALL ops.sp_raise_alert('warning','D2a','large_market_move',
      <one-line with prior_nav/today_nlv/pct_change/expected_ΔNAV/residual>, <JSON: prior_nav, today_nlv,
      pct_change, expected_delta_nav, residual>)` and **CONTINUE** the routine normally: marks ingest, the kill
      sweep, and exit staging all proceed (this is precisely the day they matter most).
    - **RESIDUAL exceeds tolerance** (a genuinely unexplained gap — the connector-corruption signature this band
      exists to catch): HALT exactly like the cash tripwire — `CALL ops.sp_raise_alert('critical','D2a',
      'connector_sanity', <one-line with prior_nav/today_nlv/pct_change/expected_ΔNAV/residual>, <JSON>)` and
      `CALL ops.sp_log_run('D2a', <today>, 'halted', …, error_msg=<message>)` — do not sweep/size/stage or let
      Step 0b write today's snapshot.
  `connector_sanity` stays **latching-critical** for a genuine residual; the market-move term suppresses ONLY the
  false halt where the whole ±15% swing reconciles to mechanically-computed real book P&L. Trust the connector's
  day-to-day story, not any single number, unverified.
- **Staged-order registry reconciliation (`state.open_orders`; §11; run after fill reconciliation, before the
  §13 cash steps).** **GUARD — read before touching this step (2026-07-20 forensic investigation): this
  step is deliberately UNCONDITIONAL on `entries_halted`/`state.entry_staging_allowed`, for BOTH entries
  and exits — it is item_type-AGNOSTIC and re-crafts any still-pending row regardless of side. ONLY D2's
  "NEW ENTRY CANDIDATES" step consults those gates. Do NOT "helpfully" add an `entries_halted`/
  `entries_allowed` check into this step to match the (imprecise) "exit re-craft is unaffected" phrasing
  that used to appear elsewhere — doing so would create a REAL, self-sustaining DEADLOCK: entries paused
  ⇒ this step stops re-crafting the paused entries ⇒ they never fill ⇒ entries stay paused forever. See
  `bigquery/76_owner_confirmation_liveness.sql`'s SCOPE comment for the corrected wording.** For each
  **DUST EXCEPTION:** exclude `item_type='drip-dust-liquidation'` from ALL generic filled detection,
  daily re-craft, and expiry branches. The exact-source dust procedure above alone matches its exact instruction
  id, aggregate staged quantity, and connector holding; a coarse ticker/contract/side fill could otherwise
  terminal it on an unrelated manual partial SELL. Apply **(a) filled** only to every still-pending NON-DUST row
  by inserting a `queue_events` `filled` row when its normal matching rule succeeds. The executable NON-DUST
  predicate is `COALESCE(item_type,'') <> 'drip-dust-liquidation'`, never bare `item_type <> ...`, because
  legacy ordinary rows may have NULL `item_type` and must remain in the generic loop.
  For non-dust rows only: **(b) window still open + unfilled** (`entry_window_close >= today` MT) — **BOUNDARY CASE, `entry_window_close = today` (2026-09-10): this branch SELECTS the row for re-evaluation; it does not authorize writing a window that is already past.** This step runs POST-CLOSE, so the re-craft reaches the NEXT session S, and Operating_Protocols.md §11's `entry_window_close` rule requires the new row's window to be `>= S`. Two lawful outcomes, and this branch's own ENTER/EXIT/ABANDON judgment picks between them: if the intent genuinely extends to S, **ADVANCE** the window to at least S and re-craft (what `sweep-SGOV-20260702` did on 2026-07-06/07/08 — same `item_key`, window rolled 07-07 → 07-08 → 07-09); if it does not, the order has used its full window — set the row terminal and log it, do not re-craft. What is never lawful is CARRYING a now-past window forward unchanged: that writes a born-dead row, `state.staged_order_window_invalid` flags it, and the next reconciliation expires it under (c) regardless. Measured over the complete history 2026-09-10 — 12 re-craft rows across 4 `item_key`s — no run has ever violated this: the one fixed-deadline thesis entry (`stage-MDT-B-20260603`, re-crafted 6× carrying window 2026-06-17) FILLED on its final window day, and the one open-ended sweep advanced. This is written down because the predicate alone does not imply it, not because a run got it wrong. — **ORDER-GUARD CHECK first, every
  re-craft, not just the original entry (self-improvement audit finding, 2026-07-11 — a persisting order's
  qty/ref_price may have changed since its original staging, and `state.open_orders` only ever
  shows the LATEST `ORDER_STAGED` row per `item_key`, so an un-re-validated re-craft would silently overwrite
  the original guard result with a blank one):** `SELECT * FROM analytics.fn_order_guard(<strategy>, <side>,
  <qty>, <ref_price>, 'MARKET')` (or `fn_order_guard_options(<strategy>, <side>, <contracts>, <ref_premium>,
  <max_loss_dollars>, 'MARKET')` for an options leg — market-only + malformed-input sanity only, owner
  directive 2026-07-22, `bigquery/104_strip_pretrade_rails.sql`). If
  `passed = FALSE`, do NOT re-craft — `CALL ops.sp_raise_alert_once('critical','D2a','order_guard_block',
  '<routine> — order guard rejected a staged order: <guard-reasons>; see payload for the order fields', <JSON>)`
  (**MESSAGE PINNED 2026-09-07:** `<guard-reasons>` is the DISTINCT reason codes, ASCENDING, comma-joined, no spaces —
  same pin as the sibling `order_guard_block` sites; an unordered join permutes and re-raises a CRITICAL.) (the order is malformed — non-MARKET, non-positive qty/ref_price, or, for
  options, an undefined max_loss), leave the row `pending` for next session's re-evaluation (the persist-and-wait
  intent is not dropped, but a malformed re-craft is not sent either). If
  `passed = TRUE`: a re-craft simply re-runs the ENTER/EXIT-vs-ABANDON judgment (preamble ENTRY/EXIT DECISION) and,
  if ENTER (or EXIT/TRIM for an exit row), **FIRST call `delete_order_instruction(prior_instruction_id)`** — where `prior_instruction_id` is this row's CURRENT `payload.instruction_id`, i.e. the instruction this re-craft is about to supersede — an orphaned prior instruction stays live and tap-confirmable by the operator even after being superseded (`state.open_orders` shows only the LATEST `ORDER_STAGED` row per `item_key`, so the superseded instruction id is never looked at again once the new row is written, and it is not swept by the stale-instruction GC below, which only fires once the order DAY has passed) and would execute an unintended duplicate order if tapped alongside the fresh one — THEN re-stages a fresh MARKET instruction for the current session (re-pull `get_price_snapshot` for the
  live reference price; there is no limit to re-price) — an
  ABANDON sets the row terminal instead of re-crafting (writing its compensating CLOSE FIRST per the PHANTOM-CLOSE RULE at the end of this bullet, if this BUY wrote a staging-time provisional OPEN),
  `create_order_instruction(contract_id, side, quantity, order_type='MARKET', time_in_force='DAY')` (no `limit_price` argument transmitted), write a new `ORDER_STAGED` `pending` row with the updated `payload.instruction_id`,
  same `item_key`, **`payload.position_key` carried forward UNCHANGED from the current row if present** (a re-craft must NEVER drop or re-mint it — `state.open_orders` shows only the LATEST `ORDER_STAGED` row per `item_key`, so if the re-craft omitted it, D2a's PHANTOM-CLOSE and Step 0's fill-supersede would read a NULL key off the newest row and lose the tie to this order's staging-time provisional OPEN; STAGING-OPEN KEY INVARIANT, item 2/2a), **`guard_passed`/`guard_reasons` from the
  check just run** (so a re-craft's payload proves the guard ran exactly like the original entry's does — closes
  the false `order_guard_omitted` CRITICAL that a re-craft omitting this would otherwise trip on EVERY still-open
  persist-and-wait order, EVERY session — and lets the daily-staging-cap backstop recompute the market-only guard
  verdict from the payload's own side/qty/ref_price, with no liquidity inputs left to store), and
  create/repair the 07:00-MT confirm event for a non-craftable order); **(c) window closed + unfilled**
  (`entry_window_close < today`) — **MIS-SET WINDOW CHECK FIRST (2026-09-10) — a row reaching this branch has NOT
  necessarily had its session.** Before treating this as an expiry, `SELECT * FROM state.staged_order_window_invalid`
  (`bigquery/233_staged_order_window_dead_on_arrival.sql`) and look for this `item_key`. **If that SELECT fails
  because the view does not exist, treat the row as NOT listed and proceed with the ordinary expiry below** — the
  view is created by that file and this branch must degrade to its pre-2026-09-10 behaviour rather than stall a
  reconciliation on a missing dependency. A row listed there was staged
  at or AFTER the close of the very session its `entry_window_close` names, so it never had a tradable session inside
  its own window — that window is a MIS-STAMPED DATE, not a deadline that opened, ran and passed. Recording it as the
  `conservative_default` expiry reports "this order had its chance and missed it" for what was actually "this order
  never had a chance", and nothing downstream can tell the two apart afterwards. Instead re-derive the intent's REAL
  deadline and branch on that: if the intent still stands, take branch (b) above — same `item_key`, ORDER-GUARD CHECK
  first, prior instruction deleted, every payload carry-forward rule of (b) — writing `due_date` per
  Operating_Protocols.md §11's `entry_window_close` rule, i.e. `>= state.trading_day_today.next_trading_day` for a
  post-close craft; if it does not still stand, expire it here deliberately. Either way `CALL ops.sp_log_decision(...)`
  must say WHICH of the two it was and that the window was mis-stamped, never the bare conservative default. This
  cannot loop: a repaired row's window is a session strictly after its own craft, so it is not in that view on the next
  pass and the `staged_order_window_dead_on_arrival` alert self-clears. **It also stops the re-notification churn at
  the source, via the §13 cash reservation rather than via this branch** — the new date-suffixed sweep row is minted by
  the §13.E park-sweep craft step later in this same run, not here, and that step sizes off
  `free_cash = settled_cash − reserved_cash`; a repaired row stays `pending`, so its reservation stays earmarked and
  free_cash falls below the +$25 sweep floor instead of funding a fresh `item_key` (2026-09-09, concretely: expiring
  `sweep-VOO-20260908` released $98.44, taking free_cash to $108.299 and minting `sweep-VOO-20260909`; had it been
  repaired, free_cash would have been $9.86 and no new sweep — hence no second email and push — would have been
  crafted at all). Only once the row is confirmed NOT to be in that view — a genuine window that opened, ran and closed
  unfilled — proceed with the expiry: write the compensating CLOSE per the PHANTOM-CLOSE RULE below FIRST (if this BUY wrote a staging-time provisional OPEN), then set terminal `expired` and **`CALL ops.sp_log_decision(...)`** (the
  `conservative_default`). A row's reserved cash stays earmarked until it is terminal. **PHANTOM-CLOSE RULE (2026-07-27, `INCIDENT[ref=423ecc02-fdb7-4f47-9445-d8c79d399e8c]` — closes RUNBOOK §47's "known remaining gap"; applies to the ABANDON clause in (b) and the EXPIRE clause in (c) alike).** A BUY row that wrote a staging-time provisional OPEN `events.position_events` row — recognizable because its `ORDER_STAGED` payload carries a non-null `position_key` (every `add-tranche`; and any first entry that pre-writes its OPEN on the GO per item 2's staging-OPEN invariant) — and then goes terminal `expired`/`abandoned` UNFILLED would otherwise strand that OPEN row in `state.current_positions` forever (latest-wins per `position_key`, `event_type <> 'CLOSE'`, `bigquery/01_schema.sql:129-133`), because `bigquery/110` stops explaining it the instant the order leaves `state.open_orders` (`pending_buy_shares` → 0, so `residual_share_diff` reverts to the raw `share_diff`): a permanent, correctly-detected-but-un-clearable `position_reconciliation` drift and a permanent trading halt. To net it out, BEFORE flipping the row terminal: read `K = JSON_VALUE(payload,'$.position_key')`; if `K IS NOT NULL` **and** `K` is currently a live non-CLOSE row in `state.current_positions`, `INSERT INTO events.position_events` one compensating row — `position_key = K`, `event_type = 'CLOSE'`, `status = 'CLOSED'`, `event_ts = CURRENT_TIMESTAMP()` (strictly later than the OPEN, so latest-wins resolves `K` to the CLOSE and `state.current_positions` drops it), `strategy`/`ticker`/`contract_id`/`shares`/`cost_basis` **and `invalidation_status` (plus every other column that OPEN row populated — this list is a MINIMUM, see "Shared rules referenced across prompts" → "An omitted field is a destroyed field"; omitting a column here DESTROYS it, because this row becomes latest-wins for `K`)** copied verbatim from that current_positions OPEN row, `note = 'compensating CLOSE: ORDER_STAGED <item_key> terminal <expired|abandoned> unfilled — nets out staging-time provisional OPEN; INCIDENT[ref=423ecc02-fdb7-4f47-9445-d8c79d399e8c]'`. This can only ever REMOVE a genuinely-unbacked tranche: reaching (b)-ABANDON or (c)-EXPIRE means the order NEVER filled — any fill, even a partial, matches branch (a) above and is routed to Step 0 fill reconciliation, never here — so `K`'s shares sit in `state.current_positions` but in NO `analytics.position_lifecycle` open lot. Belt-and-suspenders (guards a bug elsewhere; impossible under the never-filled invariant): if closing `K` would drop `(strategy,ticker)`'s `SUM(state.current_positions.shares)` BELOW its `analytics.position_lifecycle` open-share total, do NOT write the CLOSE — `CALL ops.sp_raise_alert_once('warning','D2a','phantom_close_skipped', 'refused compensating CLOSE for '||K||': would undercount lifecycle — investigate', TO_JSON_STRING(STRUCT(<item_key> AS item_key, K AS position_key, <strategy> AS strategy, <ticker> AS ticker)))` and leave the row for a human. Park legs (`strategy IS NULL`) never reach `events.position_events` and are out of scope.
- **OPEN WITHDRAWAL CANDIDATES — mandatory second pass before residual assessment (2026-08-12
  missed-consumption incident).** Immediately after the fresh account/balance reads, and BEFORE the
  cash/park tripwire below computes or attributes this session's residual, always
  `SELECT * FROM state.cash_flow_candidates_open ORDER BY observed_date, candidate_key` and adjudicate EVERY
  returned row against those fresh connector balances. A zero current-session residual does not mean there is
  no candidate: on 2026-08-12 D2a wrote exactly that conclusion while `wd-2026-08-11` was still open, leaving
  the $3,525 withdrawal unbooked and the false −18.2% soft-drawdown entry halt live. For each row, either call
  `ops.sp_record_withdrawal` with that row's own key/date or append its retraction; log the key and disposition.
  Do not start the tripwire/residual calculation until the query's original result set is fully consumed.
- **Cash/park balance reconciliation — tripwire (every run, before any sizing/staging; full procedure
  Operating_Protocols.md §13).** First, `SELECT vehicle FROM state.park_policy_current` — this is "the park"
  for every step below (SGOV through the 2026-07-15 cutover; VOO from the owner's manual transfer forward).
  Compute expected park shares + cash (Σ per-strategy park-allocation +
  cash residuals from `analytics.account_reconciliation`, + `state.park_reconciliation` for park shares) vs live
  park-vehicle shares (`get_account_positions`, contract_id per the current vehicle — SGOV 424099317, VOO
  136155102) + live cash (`get_account_balances`), netting out
  commissions/realized-P&L of fills reconciled this run. Attribute every non-zero residual per the §13 decision-tree
  (dividend/interest, deposit/withdrawal, standalone fee, commission-on-fill, operator park-sale-to-cover, or
  genuinely unexplained → log + flag + conservative hold, never silently absorb). A residual that stays UNEXPLAINED
  and exceeds ~$1 is a hard STOP — `CALL ops.sp_raise_alert('critical','D2a','cash_tripwire', <one-line message>,
  <JSON: residual, connector evidence>)` + `CALL ops.sp_log_run('D2a', <today>, 'halted', …, error_msg=<message>)`;
  resolve before sizing or staging. (Note: VOO's per-share price is roughly 5-7x SGOV's, so the same ~$1 dollar
  tolerance is a proportionally tighter share-count margin once VOO is the park vehicle — expected, not a bug.)
- **External withdrawal — TWO-PASS detection, then pro-rata to NAV clamped to idle cash (owner directive 2026-08-10;
  full procedure Operating_Protocols.md §13.C, machinery `bigquery/161_withdrawal_after_the_fact.sql`).**
  A withdrawal is NEVER declared in advance and is NEVER committed on the session that first sees it.
  When the tripwire above attributes an unexplained cash DECREASE to a probable withdrawal (per §13.B
  cause-finding — no matching trade, no corporate action, and corroborated by
  `get_pa_performance_all_periods` showing a flow-adjusted TWR near zero across the NAV move):
  **FIRST PASS —** `INSERT` a row into `events.cash_flow_candidates` (`status='open'`,
  `direction='WITHDRAWAL'`, signed negative `amount`, `evidence` = balances before/after + the TWR
  reading) and treat that residual as EXPLAINED-PENDING, so it does NOT trip the `cash_tripwire` hard
  STOP above and does NOT halt this session. **SECOND PASS (next session) —** re-read the connector.
  Cash still gone → `CALL ops.sp_record_withdrawal(<positive magnitude>, <flow_date>, <note>,
  <candidate_key>)`, which is the ONLY sanctioned write path (it allocates pro-rata to
  `analytics.strategy_nav.nav`, clamps each strategy to its own `available_funds` and redistributes
  whatever it cannot absorb, writes one `strategy`-tagged row per donor, refuses rather than spilling
  if it exceeds total idle capacity, zero-weights a sub-floor PROBE newcomer, and is idempotent per
  `candidate_key`). Cash returned → append `status='retracted'`; it was a settlement
  hold, which is the Apr 28→May 7 $2,500 precedent caught a pass earlier. **Never hand-write the
  `events.cash_flows` rows for a withdrawal, and never record one as a bare `strategy` NULL row** —
  that equal-split debits strategies holding no idle cash and the withdrawal direction has no
  self-heal (`bigquery/98`'s compensating sweep keys on `available_funds >= 25`, surplus-only).
- **Strategy idle-balance deficit check (backstop, `bigquery/161`).**
  `SELECT * FROM state.strategy_funds_deficit` — expect zero rows. Any row means a cash flow was
  allocated to a strategy that did not hold the money (negative `deposits`) or a strategy is deployed
  beyond its booked NAV. Raise `CALL ops.sp_raise_alert_once('warning','D2a','strategy_funds_deficit',
  '<strategy> — strategy funds deficit; see payload for the amount', <JSON rows>)`
  (**MESSAGE PINNED 2026-09-07:** `<one-line message>` was free-form. Keyed on the SINGLE strategy code, one open
  row per deficit strategy — deliberately matching this category's own registered `resolve_rule`, which closes
  "when state.strategy_funds_deficit returns no rows FOR THE NAMED STRATEGY"; a set-keyed message could not be
  closed by that rule at all.)
  **HEAL, FROM THIS SAME READ (added 2026-09-07 — `bigquery/161` registered this category `latching = FALSE`
  promising exactly that auto-resolve, and nothing implemented it; the same defect, in the same file, as the three
  D2a siblings fixed on 2026-09-06 and the two W5 capital categories fixed alongside this).** For each strategy
  that has NO row in the read you just did: `UPDATE ops.alerts SET resolved = TRUE, resolved_ts = CURRENT_TIMESTAMP(),
  resolved_note = 'condition healed: state.strategy_funds_deficit no longer returns a row for this strategy
  (healed by D2a)' WHERE category = 'strategy_funds_deficit' AND NOT resolved AND STARTS_WITH(message, '<strategy> — strategy funds deficit')`.
  Per-strategy prefix match, never a category-wide UPDATE — the same reason spelled out at W5's `capital_stranded` heal.. Deliberately a WARNING, not a critical: a critical would enter
  the `blocking_criticals` term of the halt gate and freeze all order staging including exits, which
  is disproportionate for a bookkeeping-integrity signal. Non-latching — it auto-resolves when the
  deficit clears.
- **Owner-confirmation liveness gate (completeness-critic N-2, 2026-07-16) — the absence model for the
  one sanctioned human touch.** `SELECT * FROM state.owner_confirmation_liveness`
  (current body `bigquery/269_owner_confirmation_pending_age.sql`; chain 76 -> 209 -> 211 -> 269; 209 remains
  the canonical home of the park-tap argument below, and 76 of this gate's SCOPE note and its
  `ops.trading_control` usage convention). **PARK CONFIRM-TAPS COUNT (2026-09-02).**
  `trading_days_since_last_fill` measures from the LATER of the last `events.trade_fills` fill and the
  last `events.parking_events` `BUY`/`SELL` `action_date`, because a park sweep / cover / switch leg is an
  owner confirm-tap on the same IBKR surface as any other order (Operating_Protocols.md §13.E, "the
  operator still taps to confirm") and is recorded ONLY in `parking_events` (§13.D, §13.E step 5/6). Do NOT
  narrow it back to `trade_fills` alone: both times this gate has ever fired — 2026-07-19 and 2026-09-02 —
  it was that blindness, not a real absence, and it is self-sustaining because D2a's own mandatory §13.E
  sweep craft re-arms `n_pending_instructions` every evening the book is parked. `last_park_fill_date` and
  `last_owner_tap_date` are on the view so the reading is auditable. **AND AN AUTOMATIC DRIP IS NOT A TAP,
  ON EITHER SIDE.** `events.parking_events` `DIVIDEND_REINVEST` / `RECON_ADJUST` are excluded by the
  BUY/SELL allowlist, and `events.trade_fills` rows with `order_id = '0'` — IBKR's automatic reinvests,
  5 of 50 rows, no broker order id because the owner placed no order — are excluded too. The owner tapped
  nothing on those days; counting them would report responsiveness that did not happen. Inert today
  (newest such row 2026-07-23, account on Receive Cash since 2026-08-02) but re-armable per §13.C. If `entries_halted = TRUE` (>=1 `state.open_orders`
  row still `pending` AND `trading_days_pending_untapped >= 3` — a staged instruction has waited 3+ trading
  days with no owner confirm-tap of any kind). **THE CLOCK STARTS WHEN SOMETHING IS WAITING (2026-10-27).**
  `trading_days_pending_untapped` counts from the LATER of `last_owner_tap_date` and
  `oldest_pending_staged_date` (the FIRST `ORDER_STAGED` row of the longest-waiting pending item_key,
  stable across re-crafts). Do NOT gate on `trading_days_since_last_fill` again: it banks quiet days with
  nothing to tap, so the first craft after a quiet stretch tripped the gate the evening it was staged —
  every one of the four fires before 2026-10-27 was that artifact, and replaying every `ORDER_STAGED`
  item_key showed each instruction was tapped within one trading day. `trading_days_since_last_fill` stays on
  the view and in the marker reason / payload as context only: (a) OPEN THE MARKER — keyed on the
  CONTROL-ROW state, never on an alert existing: `INSERT INTO ops.trading_control (halt_all, mode, reason,
  set_by) SELECT FALSE, 'entries_halted', '<n_pending_instructions> pending instruction(s),
  <trading_days_since_last_fill> trading days since the last reconciled fill', 'D2a' FROM UNNEST([1]) AS _t
  WHERE NOT EXISTS (SELECT 1 FROM ops.trading_control o WHERE o.mode = 'entries_halted' AND NOT EXISTS
  (SELECT 1 FROM ops.trading_control c WHERE c.mode = 'entries_halted_cleared' AND c.control_ts > o.control_ts))
  AND NOT COALESCE((SELECT halt_all FROM ops.trading_control ORDER BY control_ts DESC LIMIT 1), FALSE)` — an
  AUDIT-TRAIL row only (`halt_all` stays `FALSE`; see the HALT-ROW GUARD below and that file's header for why
  this must never flip `halt_all`). The guard keys on THIS LANE being closed rather than on alert absence: an
  alert resolved out of band while `entries_halted` is still TRUE would otherwise let the next run open a
  SECOND marker for the same episode. Then, and only if no unresolved `owner_confirmation_stale` alert already
  exists — that condition is load-bearing on the RAISE and stays, because the message below embeds two counters
  that change run to run and would defeat `sp_raise_alert_once`'s (category, message) dedup —
  `CALL ops.sp_raise_alert_once('warning','D2a','owner_confirmation_stale', 'Owner confirm-tap
  liveness: pending instructions are not being tapped — see payload for the pending count and the trading
  days since the last fill. D2 NEW-ENTRY staging (fresh GO decisions only) is paused; already-staged orders —
  entries and exits alike — keep re-crafting daily, unaffected.', <JSON:
  n_pending_instructions, trading_days_pending_untapped, oldest_pending_staged_date,
  trading_days_since_last_fill, last_fill_ts, last_park_fill_date, last_owner_tap_date>)` — carry BOTH tap sources in the payload, so a reader can tell a genuine absence
  from a measurement artifact without re-querying. D2's "2. NEW ENTRY CANDIDATES"
  step reads this same view before crafting any new entry and skips staging (logging the GO as
  staged-but-paused, same pattern as the PENDING-NEWCOMER FROZEN CHECK) while `entries_halted = TRUE`;
  this routine's own Staged-order registry reconciliation above (§11) — which re-crafts ANY already-staged
  pending row, entries and exits alike — is completely unaffected either way.
  If `entries_halted = FALSE`, run the two arms below INDEPENDENTLY — the audit-trail close is keyed on the
  CONTROL-ROW state, never on an alert existing (2026-08-27 D2a finding): the only `owner_confirmation_stale`
  alert ever raised was resolved out of band by an interactive session the next morning, which left its paired
  `mode='entries_halted'` row open with no later run able to satisfy an alert-conditioned close — and nothing
  else in the system emits that close.
  (i) ALERT RESOLVE — only when an unresolved `owner_confirmation_stale` alert exists (the gate has since
  cleared — auto-clears with no operator action): `UPDATE ops.alerts SET resolved = TRUE, resolved_ts =
  CURRENT_TIMESTAMP(), resolved_note = 'auto-resolved: state.owner_confirmation_liveness.entries_halted is
  now FALSE — <name what actually cleared it: the owner confirm-tap, strategy or park, or the other change>'
  WHERE category = 'owner_confirmation_stale' AND NOT resolved`. Correctly alert-scoped: with no alert open
  there is nothing to resolve. TWO CORRECTIONS (2026-09-02 triage of `owner_confirmation_stale` 5cd75118).
  `resolved_ts` was OMITTED from this arm while the sibling `book_drawdown_soft_breach` HEAL below AND W5's
  SPEC-DEFECT NOTICE INTAKE branch 1 both set it — so this arm alone left a resolved row with a NULL
  `resolved_ts`. And the note asserted "a fill was reconciled" UNCONDITIONALLY, which is a FALSE RECEIPT
  whenever anything else cleared the gate: on 2026-09-02 what cleared it was
  `bigquery/209_owner_confirmation_park_tap_liveness.sql` correcting the measurement, with no new fill at
  all. Write what actually cleared it — a receipt that names the wrong cause is worse than none, because a
  later reader trusts it.
  (ii) AUDIT-TRAIL CLOSE — fires whenever the marker lane is still OPEN (some `mode='entries_halted'` row has
  no LATER `mode='entries_halted_cleared'` row), whether or not an alert exists or ever did: `INSERT INTO
  ops.trading_control (halt_all, mode, reason, set_by) SELECT FALSE, 'entries_halted_cleared', '<WHAT ACTUALLY
  cleared it — the owner confirm-tap (strategy fill OR park fill), or the other change that did, never assume a
  fill; plus the control_id of the entries_halted row being closed>', 'D2a' FROM UNNEST([1]) AS _t
  WHERE EXISTS (SELECT 1 FROM ops.trading_control o WHERE o.mode = 'entries_halted' AND NOT EXISTS
  (SELECT 1 FROM ops.trading_control c WHERE c.mode = 'entries_halted_cleared' AND c.control_ts > o.control_ts))
  AND NOT COALESCE((SELECT halt_all FROM ops.trading_control ORDER BY control_ts DESC LIMIT 1), FALSE)`. Keying
  the guard on the open marker is what makes the write idempotent: once the close lands the lane is matched, so
  a retry, a second run the same day, and every run until `entries_halted` next goes TRUE are all no-ops —
  whereas a same-DAY-existence guard would still write a fresh close on every later flip-day. `FROM UNNEST([1])`
  is load-bearing, not noise (GoogleSQL rejects a literal-only SELECT carrying a WHERE — the same note as in
  `bigquery/151_connector_tool_inventory.sql`).
  **HALT-ROW GUARD (both arms).** Every row this bullet writes carries `halt_all = FALSE`, and the
  `AND NOT COALESCE((SELECT halt_all ...), FALSE)` term in both INSERTs is what makes that safe rather than
  merely conventional. The "ops.trading_control usage convention for this gate" block in
  `bigquery/76_owner_confirmation_liveness.sql` claims a `halt_all=FALSE` marker "can NEVER interact with that
  global latest-row selection, by construction"; that holds in ONE DIRECTION ONLY. No consumer of
  `state.trading_control_latest` / `state.trading_enabled` / `state.trading_enabled_mechanical` filters by
  `mode` — each reads `halt_all` off the single latest row by `control_ts` — so a marker landing after a
  genuine `halt_all=TRUE` row would itself read as an un-halt of the whole book. That is exactly what
  `bigquery/23_trading_control.sql`'s header forbids ("an auto halt is cleared by an explicit manual INSERT,
  never by another automated row") and records as not enforced in SQL; the guard enforces it here. Nothing is
  lost by deferring — because both arms are state-keyed, a write skipped under a halt is simply made by the
  next run after the halt clears.
  **IF THIS BULLET'S OWN SPEC LOOKS WRONG WHILE YOU ARE EXECUTING IT, FILE IT — do not just narrate it in the
  run-log note or the row's `reason`.** That is the shared OUT-OF-SCOPE FINDINGS rule (§Observability) applied to
  the site that produced it: on 2026-08-27 this exact bullet's alert-conditioned close was diagnosed correctly by
  D2a and recorded only in a `reason` string, so nothing consumed it. Write the `ops.alerts` `info` row naming the
  owning surface, then proceed. This is in-band,
  fail-safe, and reversible — it does not touch `state.trading_enabled`/`halt_all`-the-mechanism, the
  mechanical kill triggers, the IBKR confirm-tap requirement itself, or deposits.
- **Book soft-drawdown surfacing (record-only — finding C1, 2026-07-17 book-drawdown rebase).** After
  Step 0b's account snapshot (which is what makes `state.book_drawdown_watch` current for today),
  `SELECT book_drawdown_soft_breach, block_reason FROM state.entry_staging_allowed`
  (`bigquery/78_book_drawdown_rebase_and_staleness_gate.sql`). If `book_drawdown_soft_breach = TRUE`
  (the flow-adjusted book NAV is >= 15% below its high-water trading gain — the entries-only SOFT tier,
  NOT the -40% catastrophe hard-halt), `CALL ops.sp_raise_alert_once('warning','D2a','book_drawdown_soft_breach',
  'Book drawdown soft breach — D2 NEW-entry staging is paused; exits, kill-trigger terminations and park
  cover are unaffected. See payload for drawdown_from_peak, capital_base and as_of_date.', <JSON: drawdown_from_peak, capital_base, as_of_date>)`
  (**MESSAGE PINNED 2026-09-07**, prose message-stability sweep: `<block_reason>` was free-form, and this is a
  book-level condition with no per-entity identity, so the whole message is now fixed — exactly one open row while
  the breach persists, which is what the next sentence already claimed happened.). This is a RECORD-ONLY warning,
  exactly parallel to the `owner_confirmation_stale` warning above: it surfaces that D2's NEW-entry
  staging is paused via `state.entry_staging_allowed.entries_allowed` (consumed by D2's ENTRY-STAGING
  GATE) — it does NOT halt exits, kill-trigger terminations, or park cover, and does NOT flip
  `halt_all`. `sp_raise_alert_once` dedups on the unresolved (category, message), so a persisting
  breach does not re-email daily. HEAL: when `book_drawdown_soft_breach` reads FALSE and an unresolved
  alert of this category exists, `UPDATE ops.alerts SET resolved=TRUE, resolved_ts=CURRENT_TIMESTAMP(),
  resolved_note='condition healed — book NAV recovered above the -15% soft threshold' WHERE
  category='book_drawdown_soft_breach' AND NOT resolved` (the same evidence-based routine-owned resolve
  as the `interim_underperf_warning`/`termination_close_staged` precedents). Inert today (verified
  2026-07-17: `breach_soft = FALSE`, drawdown ~-0.63%).
- **SNAPSHOT-SURFACE CIRCUIT BREAKER (2026-08-12, D2a partial-connector incident).** Before calculating a park sweep or cover, request the current park vehicle's `get_price_snapshot`. On a transient-looking tool error, retry that request once after a short backoff; on a non-transient error, do not retry. If an attempt yields a structurally valid response, first perform the narrow recovery step: read unresolved `source='D2a' AND category='connector'` alerts for this surface and resolve by exact `alert_id` only (a) structured `connector='IBKR' AND surface='get_price_snapshot' AND (scope='account-wide' OR (scope='symbol-specific' AND symbols contains the current park vehicle))`, plus (b) the legacy 2026-08-12 shape `failing_method='get_price_snapshot'`; the successful target-symbol read proves those conditions clear. Then, if the response has a usable side of the book (ask for a BUY sweep, bid for a SELL cover), continue below. If the park vehicle still has no structurally valid snapshot after the allowed attempt(s), the sweep/cover is **always deferred**: probe SPY once (or QQQ if SPY is itself the park vehicle) only to classify the scope. If the independent probe also errors, classify `get_price_snapshot` account-wide unavailable and `CALL ops.sp_raise_alert_once('warning','D2a','connector', 'IBKR get_price_snapshot unavailable for <park vehicle> and <probe symbol>; park sweep/cover deferred — account reconciliation and historical marks continued', <JSON: connector="IBKR", surface="get_price_snapshot", symbols:[<park vehicle>,<probe symbol>], scope="account-wide", free_cash, bridge_adjusted_settled_cash, park_attempts:<1 or 2>, error_verbatim>)`. If the independent probe succeeds, classify the failure as park-symbol-specific and raise the same narrowly scoped warning with `scope="symbol-specific"`, `symbols:[<park vehicle>]`, and `successful_probe=<probe symbol>`; do not craft from the probe symbol's price. In either failure branch, log the deferred amount in this run's note and **skip only the sweep/cover for this run**. Do not use history, prior close, web data, or a cached price to size or authorize a MARKET park instruction; do not set a terminal registry state; the same cash is re-evaluated next run after a fresh successful park-vehicle snapshot. A valid park snapshot with an empty/stale executable side is the ordinary no-liquidity branch: defer this craft without treating the connector as down. This circuit breaker does not abort fill reconciliation, account snapshotting, or `get_price_history` mark ingestion, whose connector reads have separately succeeded.
- **Cash flattening — auto-craft the park sweep/cover (§13.E).** **TRADING-ENABLE RE-CHECK (2026-07-27, `INCIDENT[ref=423ecc02-fdb7-4f47-9445-d8c79d399e8c]`) — apply BEFORE crafting:** if the `state.trading_enabled_mechanical` verdict carried forward from this routine's TRADING-ENABLE GATE reads FALSE, do NOT craft and do NOT write an `ORDER_STAGED` row — record the skip via `CALL ops.sp_log_decision(...)` citing `halt_reason` and continue; the sweep is re-evaluated next run. This is the one craft site D2a owns, and it is exactly what that gate paragraph names as blocked — restated here because a rule stated only at the top of the routine is not a control. (It does NOT cover the staged-order registry's daily RE-CRAFT of an already-staged, owner-confirmed pending order further below — that is deliberately unconditional; see the gate paragraph.) **ORDER-GUARD CHECK next — `SELECT * FROM
  analytics.fn_order_guard(NULL, '<BUY|SELL>', <qty>, <ref_price>, 'MARKET')` (park now uses the SAME 5-arg
  guard as any other order — no park distinction, owner directive 2026-07-22, `bigquery/104_strip_pretrade_rails.sql`:
  market-only + qty/ref-price sanity only. The former park-exemption framing, the 1.10×-NAV magnitude backstop, and
  the already-retired per-vehicle price band are ALL gone — there is no limit price to band and no park-specific
  rail left to apply). If
  `passed = FALSE`, do NOT craft — `CALL ops.sp_raise_alert_once('critical','D2a',
  'order_guard_block', '<routine> — order guard rejected a staged order: <guard-reasons>; see payload for the order fields', <JSON>)` (**MESSAGE PINNED 2026-09-07:** `<reasons joined>` named no join order, so the same rejection permutes between runs and re-raises — on a CRITICAL. `<guard-reasons>` is the DISTINCT reason codes, sorted ASCENDING, joined by a single comma with NO spaces) and skip this sweep/cover for the session. If `passed = TRUE`,
  embed `guard_passed`/`guard_reasons` from this check into the `ORDER_STAGED` row's payload when the sweep/cover is
  staged below, per the "Crafting an order (equity/ETF)" guard-result-embedding step convention — cited by
  name, not by step number, so a future renumbering of that procedure cannot silently orphan this
  reference again (it was left pointing at a stale "(4)" by the 2026-08-11 NOMADIC-BORROW insertion) —
  (self-improvement audit ITEM 15,
  2026-07-11 — this call site was the one gap the original ITEM 15 rollout missed: every historical park
  sweep/cover payload lacked `guard_passed` entirely, which is harmless under the OLD pending-only
  `order_guard_omitted` check but became a guaranteed false CRITICAL once that check was broadened, adversarial
  self-audit finding rev 2026-07-11, to also catch same-day-filled orders — park sweeps/covers routinely fill the
  same day).** On **settled** cash:
  `free_cash = settled_cash − Σ reserved_cash from state.open_orders` (the durable registry — plus any live unfilled
  BUY not represented there). **Sweep** if `free_cash ≥ +$25` → BUY the current park vehicle sized DOWN
  `floor_to_4dp((free_cash − comm_buffer)/ask)`. **Cover** if `bridge_adjusted_settled_cash ≤ −$5` (a *realized, unfunded* debit) → SELL the
  current park vehicle sized UP `ceil_to_4dp((|bridge_adjusted_settled_cash| + comm_buffer)/bid)`, capped at the vehicle
  held. `bridge_adjusted_settled_cash = settled_cash + Σ expected_net_proceeds(paired SELLs that have FILLED but not
  yet SETTLED)` — MANDATORY (owner directive 2026-07-26, Operating_Protocols.md §13.E step 4). NEVER trigger or size a
  cover off raw `settled_cash`: a paired rotation's BUY deliberately fills on margin one settlement cycle before its
  funding SELL lands, so the raw figure reads a debit of order the full switch notional, and covering it would SELL the
  brand-new policy vehicle and partially unwind the switch D2 just made.
  `comm_buffer` per Operating_Protocols.md §13's Commission model — SGOV: `min(1% × trade_value, $0.35)`
  (empirically confirmed); VOO: **the SAME formula, CONFIRMED 2026-09-25** — both arms of it are now directly
  observed on VOO (cap arm across 21 park orders, order-level gross $38.48–$15,340.63, all at $0.35 plus a small
  positive residual; 1% arm by `sweep-VOO-20260924`, $33.554223 gross → $0.335798 = 1.0008%, the first VOO order
  ever below the ~$35 arm boundary). A sweep is by construction a $25–$35 order, so it lands on the **1% arm**, not
  the cap. Still take the LARGER of this estimate and the connector's latest per-order commission from
  `get_account_trades`: every measured residual is positive, so the formula slightly under-states. Do NOT revive the
  retired 2026-07-15 reading that VOO is on a different (≈0.0038%, "tiered per-share") schedule — that was a cap-arm
  observation misread; see Operating_Protocols.md §13's **Commission model — VOO** note. Otherwise no action (a $0…−$5 debit is left on margin). This sweep/cover is now the BACKSTOP for BOTH legs of a switch (D2 crafts both in-session): it re-crafts either leg whose DAY order expired unfilled and deploys whatever residual the haircut left behind. Order:
  contract_id per the current vehicle (above), TIF **DAY**, `order_type='MARKET'` (no `limit_price` argument
  transmitted); record the live reference price (last, or bid/ask mid) in the staged payload's `limit_price` field
  for cash-reservation/notional purposes only; record the
  instruction `id` + a 07:00 confirm event — **not** a `events.parking_events` row yet (Operating_Protocols.md
  §13 step 5/6: that row is inserted only once the order fills, one row per fill; a 2026-07-21 D2a adjudication
  found a staging-time placeholder row double-counted park shares and tripped the append-only-integrity monitor
  when the stray rows had to be deleted — `events.decision_log` 636ece45-6006-4e66-b143-1b6e64b0c3dd);
  attribute to the owning strategy(ies) per §13.C so Σ per-strategy park allocation = connector park-vehicle
  holding and Σ per-strategy cash ≈ $0. Never sweep cash a pending buy needs.
  **SUNDAY / NO-SESSION SLOT — the sweep DEFERS, it does not craft off the settled close (written down 2026-09-13, D2a, the first run on which this branch actually fired).** D2a's Sunday slot sits on a day with NO market session at all, so `get_price_snapshot` for the park vehicle returns a STRUCTURALLY VALID response — `top-status` `REALTIME`, a populated `prior-close` — whose `bid-ask` object is EMPTY and whose `last` carries `is_close: true`, i.e. Friday's settled close. There is therefore no `ask` to size `floor_to_4dp((free_cash − comm_buffer)/ask)` against. This is the SNAPSHOT-SURFACE CIRCUIT BREAKER's **ordinary no-liquidity branch**, not a connector failure: **defer the sweep/cover, write NO `ORDER_STAGED` row, call NO `create_order_instruction`, set NO terminal registry state, raise NO `connector` alert** (the connector answered correctly; the market is shut), record the deferred amount via `CALL ops.sp_log_decision(...)` and in `<note>`, and re-evaluate the same cash next run against a fresh snapshot. **Do NOT craft from the settled close, the prior close, or a connector mark** — Operating_Protocols.md §11 forbids exactly that, and the `limit_price` field's "record the live reference price (last, or bid/ask mid)" allowance above is a *notional/cash-reservation* record on an order that is being sent, never an authorization to send one with no live book behind it. The deferral self-heals in one day and costs nothing structural: D2a's Mon–Thu slot is 16:40 MT / 18:40 ET, INSIDE the 16:00–20:00 ET extended session, where a live two-sided book exists — which is why, measured over 2026-08-01..2026-09-13, every park sweep/cover ever staged was staged Monday–Thursday and not one was ever staged on a Sunday (Sundays appear in that registry only as `filled` reconciliations of weekday crafts). Before 2026-09-13 no Sunday run had ever cleared the +$25 floor, so this was an unexercised branch rather than settled practice; it is written down here — at the craft site, not only in the circuit-breaker paragraph, whose wording frames the empty executable side as a within-session liquidity condition rather than as a whole day without a session — so a Sunday session reads the answer instead of re-deriving it. **This is NOT a defect to "fix" by moving D2a's Sunday slot, adding a Monday-morning pre-open craft path, or sizing off a stale mark:** the cash simply waits one day, and the alternative is a MARKET order priced off a figure no one can trade at.
- Note still-working / partial orders from `get_account_orders` and leave them exit-pending / ORDER-STAGED (the
  persist-and-wait re-craft is handled by the registry reconciliation above). For any crafted instruction in
  `get_order_instructions` whose order day has passed unconfirmed, or whose position Step 0 just closed, call
  `delete_order_instruction` to clear it.
- REGIME-CAPITAL SYNC (owner directive 2026-07-19 — Regime-Capital Enablement; canonical rails
  Operating_Protocols.md §16 REGIME-CAPITAL SYNC + §13.C; schema `bigquery/98_regime_capital_enablement.sql`;
  substep reconstructed by W5 2026-07-19 — the implementing session's plan edit was stranded unpushed). LAST
  thing in Step 0, after fills/attribution/flattening: `SELECT * FROM state.regime_capital_sync_pending`.
  **HEAL FIRST, FROM THIS SAME READ, BEFORE YOU BRANCH (added 2026-09-07 — `ops.alert_policy` promised this and
  nothing performed it).** Both `regime_sweep_blocked` and `regime_restore_blocked` are registered `latching = FALSE`
  with a `resolve_rule` that opens "Auto-resolves when `state.regime_capital_sync_pending` stops returning …" and
  closes "**D2a re-evaluates the condition each run**" — but until this clause landed this substep implemented only
  the RAISE side, so a healed condition sat unresolved on the board forever behind an owner-only manual `UPDATE`.
  From the rows you just read: if **no `SWEEP` row has `blocked_no_recipient = TRUE`** and an unresolved
  `regime_sweep_blocked` alert exists → `UPDATE ops.alerts SET resolved=TRUE, resolved_ts=CURRENT_TIMESTAMP(),
  resolved_note='condition healed: state.regime_capital_sync_pending no longer returns a SWEEP row with
  blocked_no_recipient TRUE — <name what actually cleared it: a router re-enable, a roster change, or the holder
  dropping below the $25 de-minimis floor>' WHERE category='regime_sweep_blocked' AND NOT resolved`. INDEPENDENTLY —
  **and NOT by the same absence test, which would be wrong for RESTORE** — resolve `regime_restore_blocked` only on
  POSITIVE evidence: either the view now returns a `RESTORE` row with `blocked_no_recipient = FALSE` (the restore is
  fundable again), OR `state.regime_capital_debt` shows the debtor no longer carrying outstanding regime debt (it was
  repaid by some other path). Then the same `UPDATE` with `category='regime_restore_blocked'` and the RESTORE wording,
  naming which of the two cleared it.
  **WHY RESTORE IS NOT SYMMETRIC WITH SWEEP, and why "no blocked row" must NOT be read as healed here.** For SWEEP
  the two branches really are an exact partition (`sweep_blocked` on `NOT EXISTS (enabled_recipients)` versus
  `sweep_rows` on the CROSS JOIN over the same `sweep_candidates`), and the candidate population emptying IS a
  genuine heal — the registered `resolve_rule` says so outright ("or when the capital-disabled strategy holding the
  cash drops below the $25 de-minimis floor"). RESTORE has no such partition: `restore_blocked` fires only at
  `payable = 0` and `restore_rows` only at `payable >= LEAST(25, outstanding_debt)`, so the band
  `0 < payable < LEAST(25, outstanding_debt)` emits **NO ROW AT ALL** — `bigquery/223`'s own header names this a
  DELIBERATE RESIDUAL that "this file does NOT report". In that band the debt is still fully outstanding and the
  alert's pinned message ("the eligible donor set cannot fund the de-minimis floor, so nothing moved") is still
  literally TRUE, yet a bare absence test would read it as healed and close the only row on the board saying so.
  Absence of a RESTORE row is AMBIGUOUS — debt repaid, or throttled — and only `state.regime_capital_debt`
  disambiguates it. This is deliberately STRICTER than the category's registered `resolve_rule`, whose "holds
  positive available_funds again" phrasing would close the throttled band; where the two disagree, prefer leaving a
  true alert open over closing it, and note that `regime_restore_blocked` has never fired (zero rows ever), so this
  is a forward-looking correctness choice with no live row affected. Same evidence-based
  routine-owned resolve as the `owner_confirmation_stale` and `book_drawdown_soft_breach` clauses above. Scoping by
  category ALONE is safe here for a reason specific to these two: both messages are PINNED literals, so
  `sp_raise_alert_once`'s `(category, message)` dedup makes at most ONE unresolved row per category possible by
  construction (verified live: one row total across both categories, ever). That argument does NOT generalise — a
  category whose message interpolates a varying value can hold several open rows at once, and category-scoped
  resolves are wrong for those.
  **THIS IS AUTHORISED, and a future session must not revert it on a correct-looking reading of the shared rules.**
  The shared INCIDENT INHERITANCE bullet says "every capital-affecting class stays human-only per the fail-closed
  allowlist", and read alone that sentence forbids the UPDATE above. It is the DEFAULT for categories carrying no
  registered rule, not a blanket prohibition — exactly the point SL3's `probe_funding_stalled` pin already
  adjudicated for a structurally identical category: "Where a category carries its own registered rule, that rule
  governs; the two-category sentence is the DEFAULT for categories that carry none." `bigquery/34_alert_lifecycle.sql`
  built `ops.alert_policy` for precisely this, and all three categories here are registered `latching = FALSE` with a
  `resolve_rule` — two of them naming D2a outright. Verified live besides: `ops.sp_auto_resolve_alerts` is hardcoded
  to `missing_dependency`/`missed_run`/`routine_stalled`/`catchup_refire_blocked`/`staleness` plus the roster notices
  and touches none of these three, so there is no second resolver to fight with.
  **DO NOT MOVE THIS INSIDE THE "Empty" BRANCH — that would be a VACUOUS fix, and it is the obvious place to put
  it.** The blocked and healthy shapes of a given strategy are COMPLEMENTARY branches of this same view over the
  same population, keyed on the same predicate: `sweep_blocked` fires `WHERE NOT EXISTS (SELECT 1 FROM
  enabled_recipients)` and `sweep_rows` populates the moment that relation is non-empty, so a heal flips
  `blocked_no_recipient` TRUE→FALSE **without the view ever returning zero rows** (for RESTORE the shapes are NOT complementary — see the
  asymmetry paragraph above — but the same "never returns zero rows" hazard applies to its healthy branch). Concretely, on the live
  founding case: today the view returns one row, `SWEEP`/E/15368.39/`blocked_no_recipient = TRUE`; the moment any
  non-nomadic strategy becomes capital-enabled while E still holds ≥ $25 idle, it returns one row,
  `SWEEP`/E/`blocked_no_recipient = FALSE` — non-empty at both instants, genuinely healed, and an
  empty-branch-only heal would never fire. **Read the FLAG, never the row count.** And do not re-`SELECT`: evaluate
  the heal and the raise branches from ONE read, per the ONE MOVEMENT PER READ discipline this substep already
  follows — a second read can observe a different snapshot and resolve an alert the raise branch is about to
  re-assert.
  Empty (the steady state) → no-op, nothing to log — apart from the heal above, which is evaluated either way.
  Non-empty:
  - `control_enabled = FALSE` (the `ops.capital_control` kill-switch) → log a one-line `events.decision_log`
    note recording what WOULD have moved, and move nothing.
  - **`blocked_no_recipient = TRUE` on a `SWEEP` row** (`bigquery/215`; capital to sweep, but EVERY capital-enabled
    strategy is itself nomadic, so there is nowhere legal to put it) → move nothing and `CALL
    ops.sp_raise_alert_once('warning','D2a','regime_sweep_blocked', <the EXACT STABLE message below>,
    <JSON payload>)`. **PIN THE MESSAGE — it is `sp_raise_alert_once`'s dedup key, so any varying value
    in it raises a NEW alert EVERY run.** Use verbatim, with no interpolation: `'Regime sweep blocked:
    a capital-disabled strategy holds sweepable idle cash, but every capital-enabled strategy is
    nomadic, so there is no eligible recipient and nothing moved. Strategies and amounts in payload.'`
    The varying figures — `strategy`, `amount`, the capital-enabled set, NAV share — go in the PAYLOAD,
    never the message. This condition persists for as long as the router leaves the roster deactivated
    (it is not self-clearing in a session), so an interpolated message would emit one warning per day
    indefinitely — the permanently-red-advisory failure this fleet has hit before. Exactly the sibling handler
    of the nomadic bullet below, and it exists for the same reason: without it the view returns ZERO
    rows and a whole-roster deactivation is **indistinguishable from the healthy empty-view steady
    state**, so do NOT treat it as a no-op. Founding case, measured 2026-09-03: AR_orc `div-E-202608-1`
    moved E to DO-NOT-ACTIVATE, leaving nomadic C as the sole capital-enabled strategy and **$15,368.39
    — 96.7% of book NAV — owed a sweep with no eligible recipient**. Do NOT "unblock" it by widening
    the recipient set; `capital_enabled AND NOT nomadic` is load-bearing (`bigquery/168` FIX 7, and
    `sweep_recipient_view_drift` records what happened the last time the set was taken from elsewhere).
    The correct response is an owner decision about the roster.
  - **`blocked_no_recipient = TRUE` on a `RESTORE` row** (`bigquery/223`, which supersedes `bigquery/215` for this
    view; a debtor strategy is capital-enabled again and owed a restore, but the eligible donor set cannot fund
    even the de-minimis floor — `payable = 0` — so there is nothing to move) → move nothing and `CALL
    ops.sp_raise_alert_once('warning','D2a','regime_restore_blocked', <the EXACT STABLE message below>, <JSON
    payload>)`. **ITS OWN CATEGORY AND ITS OWN MESSAGE — never reuse the sweep pair above.** `sp_raise_alert_once`
    dedups on `(category, message)` while unresolved, so a restore raised under the sweep category and the
    sweep-worded message would be SILENTLY SWALLOWED by an already-open sweep alert — the restore would never
    reach the board at all, and the sweep message ("a capital-disabled strategy holds sweepable idle cash") is
    factually wrong about a restore besides. **PIN THE MESSAGE**, same dedup-key rule as the sweep bullet above;
    use verbatim, with no interpolation: `'Regime restore blocked: a debtor strategy is capital-enabled again and
    owed a restore, but the eligible donor set cannot fund the de-minimis floor, so nothing moved. Strategies and
    amounts in payload.'` The varying figures — `strategy`, `outstanding_debt`, the donor set and its capacity,
    and the row's own `blocked_reason` (`'no_eligible_recipient'` when the debtor is the only eligible recipient
    or there is none at all, `'no_donor_capacity'` when eligible recipients exist but hold no available funds) —
    go in the PAYLOAD, never the message. Carry `blocked_reason`: it is the one field that says WHICH of the two
    configurations blocked the restore, and the pinned message deliberately cannot, so without it the payload
    leaves the reader to re-derive it from the donor set by hand. Same rationale as its sweep sibling: `bigquery/223` emits this row
    precisely so a blocked restore is distinguishable from the healthy empty-view steady state, so do NOT treat
    it as a no-op. The gap it closes (found 2026-09-05): `bigquery/215`'s guard was `NOT EXISTS (SELECT 1 FROM
    enabled_recipients)`, which misses the case where the only capital-enabled non-nomadic strategy IS the debtor
    — the donor CTE excludes self, `payable` computes 0, the restore row is dropped by the `>= LEAST(25,
    outstanding_debt)` floor, and nothing surfaces anywhere.
  - SWEEP rows (a capital-disabled strategy with `available_funds ≥ $25`): **THE RECIPIENT SET IS THE
    `counterparty_strategy` VALUES `state.regime_capital_sync_pending` ITSELF RETURNS — that view is the
    sole authority on recipient ELIGIBILITY (`bigquery/168` FIX 7: `capital_enabled AND NOT nomadic`).
    NEVER take the recipient set from the weight view; it supplies only the SHARES among an
    already-eligible set.** A nomadic strategy holds no exclusive standing capital ever
    (Operating_Protocols.md §16), so it is not an eligible recipient — reading the set from the weight
    view credited nomadic C twice (27.86 on 2026-08-12, swept back out the same run; 23.68 on
    2026-08-18, still held), which is what `ops.alerts` `sweep_recipient_view_drift` recorded on
    2026-08-27. Having fixed the set, apply the MECHANICAL CAPACITY
    WEIGHT (`state.sweep_recipient_weights`, `bigquery/164` as superseded by `bigquery/202`) — `SELECT strategy_code, sweep_share,
    equal_share, band_multiplier, capacity_ratio, deployed_days_180 FROM state.sweep_recipient_weights`
    and set each recipient's amount to `ROUND(swept_amount * sweep_share, 2)`, with the LAST recipient row
    absorbing the rounding residual so the double-entry is exactly $0-sum (the same penny convention the
    2026-08-06 sweep used). **Why this replaces the old default-EQUAL read:** §16 permits a [0.5×, 2×]
    tilt but reaches it only through an AI capital-allocation call at MEDIUM+ conviction, and **D2a
    carries NO analysis by design** — so every unattended sweep fell back to an equal split, permanently
    (2026-08-05 and 2026-08-06 both did; the only tilted sweep ever, 2026-07-19, ran in an interactive
    session on owner instruction). The weight needs no judgment: it is the share of the trailing 180 days
    each recipient actually held a position, mapped onto §16's band. **No band-fitting pass is needed** —
    `band_multiplier` is already clamped to `[0.5, 2.0]` in SQL before normalisation, so every
    `sweep_share / equal_share` ratio is inside the sanctioned band by construction. **It keys on
    deployment CAPACITY, never on P&L** (§16 rejects merit-weighting a short, noisy sample), and it
    degenerates to exactly the equal split when recipients are indistinguishable — so it can never be
    worse than the old behaviour. **Fall back to DEFAULT-EQUAL** (the view's own `equal_share`, or the
    view's `counterparty_baseline_amount` if `state.sweep_recipient_weights` returns no rows or its
    `sweep_share` values do not sum to 1.0 ± 0.0001) and say so in the note. **If the weight view and
    the pending view disagree about the recipient SET** — they must not after `bigquery/202` gave the
    weight view the same nomadic exclusion, so this is now a tripwire rather than an expected branch —
    drop any weight row for a strategy absent from the pending view's recipient set, renormalise the
    surviving `sweep_share` values to sum to 1.0, use the result, and raise
    `ops.sp_raise_alert_once('info','D2a','sweep_recipient_view_drift', ...)` naming both sets. A weight
    row for an ineligible recipient is an eligibility BUG in the weight view, never a tilt to be honoured. Then write the atomic $0-sum
    **`flow_type` (NOT NULL, no default) FOLLOWS THE SIGN OF `amount`, NEVER WHETHER MONEY CROSSED THE ACCOUNT BOUNDARY — pinned 2026-08-19; binds EVERY `events.cash_flows` writer (D2, D2a, AR_orc).** An internal double-entry writes BOTH values: `'WITHDRAWAL'` on the negative donor leg and `'DEPOSIT'` on the positive recipient leg. MEASURED on the live ledger: `regime_capital_sweep` holds 16 `DEPOSIT` + 6 `WITHDRAWAL` rows and `nomadic_capital_sweep` 1 of each — no third value has ever been written, and the column's only documented domain is `'DEPOSIT' | 'WITHDRAWAL'` (`bigquery/22_cash_flows.sql`:19). Inventing a `'TRANSFER'`-style third value for an internal move would be the intuitive reading and is WRONG: `analytics.strategy_nav` and the §13 cash-tripwire baseline sum the two documented values only, so a third would silently vanish from booked deposits and NAV. The column name appeared nowhere in this document until this pin.

### Pass 2 input — q0342, 2026-10-30

_The newly removed second-pass text is retained in this verbatim input; history only._

**Why a count, not the raw `state.routine_catchup_window.window_days`
  figure the old wording ("spans MORE than 1 trading day") cited:**
  gated on `missed_trading_days >= 1` (never `> 1`) — on a read failure against `ops.run_log` /
  `state.market_calendar` / `state.trading_day_today`, fall back to `days since D2a's
  own last completed ops.run_log run > 0`. `state.routine_catchup_window.window_days` (`TIMESTAMP_DIFF(...)/1440.0`, `bigquery/105_routine_catchup_window.sql`) measures continuous CALENDAR time, not missed trading days; never substitute it. **When `missed_trading_days >= 1`:** this baseline
  is that many trading days stale, not a true prior-session snapshot — annotate the actual day-count gap in the
  alert/decision note below and let the MARKET-MOVE TERM's `expected_ΔNAV` sum the mechanical mark-to-market
  move across the FULL gap (not a single day) before judging the residual, so a genuine multi-day catch-up — or
  the now-routine Thu→Sun weekly gap — doesn't misclassify as connector corruption. If the day-over-day change exceeds **±15%** and is NOT fully explained
  by what this session reconciled (a fill's realized P&L, a dividend, a deposit/withdrawal, a confirmed split) —
  **NOR by ordinary mark-to-market movement of the held book** — treat it as a candidate connector-corruption
  signal, but apply the **MARKET-MOVE TERM** below before halting.
  - **MARKET-MOVE TERM — crash-day escape hatch.** A real crash/melt-up must not false-halt the kill-exit path. Compute the expected mark-to-market ΔNAV **mechanically** (no session judgment —
    ITEM-16 safe): `expected_ΔNAV = Σ_held ( shares × (today get_price_snapshot − yesterday events.daily_marks
    close) ) + park_shares × Δ(park-vehicle price) + reconciled_flows`, where `reconciled_flows` is the SAME
    signed fills'-realized-P&L / dividend / deposit-withdrawal / confirmed-split cash the escape list already
    covers (when `missed_trading_days >= 1` per the D2A MISSED-TRADING-DAY COUNT clause above,
    "yesterday" here is the last `events.daily_marks` close as of D2a's last successful completion, not
    literally the calendar day before today — consistent with the marks backfill below). Then take the
    **RESIDUAL** `|ΔNLV − expected_ΔNAV|` and branch:
    - **RESIDUAL within tolerance** (`<= max($50, 2% × prior_nav)`): the ±15% move is real market P&L, not
      connector corruption. Do **NOT** halt — `CALL ops.sp_raise_alert('warning','D2a','large_market_move',
      <one-line with prior_nav/today_nlv/pct_change/expected_ΔNAV/residual>, <JSON: prior_nav, today_nlv,
      pct_change, expected_delta_nav, residual>)` and **CONTINUE** the routine normally: marks ingest, the kill
      sweep, and exit staging all proceed (this is precisely the day they matter most).
    - **RESIDUAL exceeds tolerance** (a genuinely unexplained gap — the connector-corruption signature this band
      exists to catch): HALT exactly like the cash tripwire — `CALL ops.sp_raise_alert('critical','D2a',
      'connector_sanity', <one-line with prior_nav/today_nlv/pct_change/expected_ΔNAV/residual>, <JSON>)` and
      `CALL ops.sp_log_run('D2a', <today>, 'halted', …, error_msg=<message>)` — do not sweep/size/stage or let
      Step 0b write today's snapshot.
  `connector_sanity` stays **latching-critical** for a genuine residual; the market-move term suppresses ONLY the
  false halt where the whole ±15% swing reconciles to mechanically-computed real book P&L. Trust the connector's
  day-to-day story, not any single number, unverified.
- **Staged-order registry reconciliation (`state.open_orders`; §11; run after fill reconciliation, before the
  §13 cash steps).** **GUARD — read before touching this step: this
  step is deliberately UNCONDITIONAL on `entries_halted`/`state.entry_staging_allowed`, for BOTH entries
  and exits — it is item_type-AGNOSTIC and re-crafts any still-pending row regardless of side. ONLY D2's
  "NEW ENTRY CANDIDATES" step consults those gates. Do NOT "helpfully" add an `entries_halted`/
  `entries_allowed` check into this step to match the (imprecise) "exit re-craft is unaffected" phrasing
  that used to appear elsewhere — paused entries must keep re-crafting to avoid a self-sustaining deadlock. See
  `bigquery/76_owner_confirmation_liveness.sql`'s SCOPE comment for the corrected wording.** For each
  **DUST EXCEPTION:** exclude `item_type='drip-dust-liquidation'` from ALL generic filled detection,
  daily re-craft, and expiry branches. The exact-source dust procedure above alone matches its exact instruction
  id, aggregate staged quantity, and connector holding; a coarse ticker/contract/side fill could otherwise
  terminal it on an unrelated manual partial SELL. Apply **(a) filled** only to every still-pending NON-DUST row
  by inserting a `queue_events` `filled` row when its normal matching rule succeeds. The executable NON-DUST
  predicate is `COALESCE(item_type,'') <> 'drip-dust-liquidation'`, never bare `item_type <> ...`, because
  legacy ordinary rows may have NULL `item_type` and must remain in the generic loop.
  For non-dust rows only: **(b) window still open + unfilled** (`entry_window_close >= today` MT) — **BOUNDARY CASE, `entry_window_close = today`: this branch SELECTS the row for re-evaluation; it does not authorize writing a window that is already past.** This step runs POST-CLOSE, so the re-craft reaches the NEXT session S, and Operating_Protocols.md §11's `entry_window_close` rule requires the new row's window to be `>= S`. Two lawful outcomes, and this branch's own ENTER/EXIT/ABANDON judgment picks between them: if the intent genuinely extends to S, **ADVANCE** the window to at least S and re-craft; if it does not, the order has used its full window — set the row terminal and log it, do not re-craft. What is never lawful is CARRYING a now-past window forward unchanged: that writes a born-dead row, `state.staged_order_window_invalid` flags it, and the next reconciliation expires it under (c) regardless. — **ORDER-GUARD CHECK first, every
  re-craft, not just the original entry (qty/ref_price can change; validate the latest row):** `SELECT * FROM analytics.fn_order_guard(<strategy>, <side>,
  <qty>, <ref_price>, 'MARKET')` (or `fn_order_guard_options(<strategy>, <side>, <contracts>, <ref_premium>,
  <max_loss_dollars>, 'MARKET')` for an options leg — market-only + malformed-input sanity only, owner
  directive 2026-07-22, `bigquery/104_strip_pretrade_rails.sql`). If
  `passed = FALSE`, do NOT re-craft — `CALL ops.sp_raise_alert_once('critical','D2a','order_guard_block',
  '<routine> — order guard rejected a staged order: <guard-reasons>; see payload for the order fields', <JSON>)`
  (**MESSAGE PINNED 2026-09-07:** `<guard-reasons>` is the DISTINCT reason codes, ASCENDING, comma-joined, no spaces —
  same pin as the sibling `order_guard_block` sites; an unordered join permutes and re-raises a CRITICAL.) (the order is malformed — non-MARKET, non-positive qty/ref_price, or, for
  options, an undefined max_loss), leave the row `pending` for next session's re-evaluation (the persist-and-wait
  intent is not dropped, but a malformed re-craft is not sent either). If
  `passed = TRUE`: a re-craft simply re-runs the ENTER/EXIT-vs-ABANDON judgment (preamble ENTRY/EXIT DECISION) and,
  if ENTER (or EXIT/TRIM for an exit row), **FIRST call `delete_order_instruction(prior_instruction_id)`** — where `prior_instruction_id` is this row's CURRENT `payload.instruction_id`, i.e. the instruction this re-craft is about to supersede — superseded instructions remain tap-confirmable until explicitly deleted — THEN re-stages a fresh MARKET instruction for the current session (re-pull `get_price_snapshot` for the
  live reference price; there is no limit to re-price) — an
  ABANDON sets the row terminal instead of re-crafting (writing its compensating CLOSE FIRST per the PHANTOM-CLOSE RULE at the end of this bullet, if this BUY wrote a staging-time provisional OPEN),
  `create_order_instruction(contract_id, side, quantity, order_type='MARKET', time_in_force='DAY')` (no `limit_price` argument transmitted), write a new `ORDER_STAGED` `pending` row with the updated `payload.instruction_id`,
  same `item_key`, **`payload.position_key` carried forward UNCHANGED from the current row if present** (a re-craft must NEVER drop or re-mint it — `state.open_orders` shows only the LATEST `ORDER_STAGED` row per `item_key`, so if the re-craft omitted it, D2a's PHANTOM-CLOSE and Step 0's fill-supersede would read a NULL key off the newest row and lose the tie to this order's staging-time provisional OPEN; STAGING-OPEN KEY INVARIANT, item 2/2a), **`guard_passed`/`guard_reasons` from the
  check just run** (including the fields needed by `order_guard_omitted` and the daily-staging-cap backstop), and
  create/repair the 07:00-MT confirm event for a non-craftable order); **(c) window closed + unfilled**
  (`entry_window_close < today`) — **MIS-SET WINDOW CHECK FIRST — a row reaching this branch may never have had its session.** Before treating this as an expiry, `SELECT * FROM state.staged_order_window_invalid`
  (`bigquery/233_staged_order_window_dead_on_arrival.sql`) and look for this `item_key`. **If that SELECT fails
  because the view does not exist, treat the row as NOT listed and proceed with the ordinary expiry below** — the
  view is created by that file and this branch must degrade to its pre-2026-09-10 behaviour rather than stall a
  reconciliation on a missing dependency. A row listed there was staged
  at or AFTER the close of the very session its `entry_window_close` names, so it never had a tradable session inside
  its own window — that window is a MIS-STAMPED DATE, not a deadline that opened, ran and passed. Recording it as the
  `conservative_default` expiry reports "this order had its chance and missed it" for what was actually "this order
  never had a chance", and nothing downstream can tell the two apart afterwards. Instead re-derive the intent's REAL
  deadline and branch on that: if the intent still stands, take branch (b) above — same `item_key`, ORDER-GUARD CHECK
  first, prior instruction deleted, every payload carry-forward rule of (b) — writing `due_date` per
  Operating_Protocols.md §11's `entry_window_close` rule, i.e. `>= state.trading_day_today.next_trading_day` for a
  post-close craft; if it does not still stand, expire it here deliberately. Either way `CALL ops.sp_log_decision(...)`
  must say WHICH of the two it was and that the window was mis-stamped, never the bare conservative default. This
  cannot loop: a repaired row's window is a session strictly after its own craft, so it is not in that view on the next
  pass and the `staged_order_window_dead_on_arrival` alert self-clears. A repaired pending row retains its §13 cash reservation (`free_cash = settled_cash − reserved_cash`), preventing a fresh date-suffixed sweep item from spending it again. Only once the row is confirmed NOT to be in that view — a genuine window that opened, ran and closed
  unfilled — proceed with the expiry: write the compensating CLOSE per the PHANTOM-CLOSE RULE below FIRST (if this BUY wrote a staging-time provisional OPEN), then set terminal `expired` and **`CALL ops.sp_log_decision(...)`** (the
  `conservative_default`). A row's reserved cash stays earmarked until it is terminal. **PHANTOM-CLOSE RULE (applies to ABANDON in (b) and EXPIRE in (c)).** A BUY row that wrote a staging-time provisional OPEN `events.position_events` row — recognizable because its `ORDER_STAGED` payload carries a non-null `position_key` (every `add-tranche`; and any first entry that pre-writes its OPEN on the GO per item 2's staging-OPEN invariant) — and then expires/abandons UNFILLED needs a compensating CLOSE to prevent a permanent phantom and reconciliation halt. To net it out, BEFORE flipping the row terminal: read `K = JSON_VALUE(payload,'$.position_key')`; if `K IS NOT NULL` **and** `K` is currently a live non-CLOSE row in `state.current_positions`, `INSERT INTO events.position_events` one compensating row — `position_key = K`, `event_type = 'CLOSE'`, `status = 'CLOSED'`, `event_ts = CURRENT_TIMESTAMP()` (strictly later than the OPEN, so latest-wins resolves `K` to the CLOSE and `state.current_positions` drops it), `strategy`/`ticker`/`contract_id`/`shares`/`cost_basis` **and `invalidation_status` (plus every other column that OPEN row populated — this list is a MINIMUM, see "Shared rules referenced across prompts" → "An omitted field is a destroyed field"; omitting a column here DESTROYS it, because this row becomes latest-wins for `K`)** copied verbatim from that current_positions OPEN row, `note = 'compensating CLOSE: ORDER_STAGED <item_key> terminal <expired|abandoned> unfilled — nets out staging-time provisional OPEN; INCIDENT[ref=423ecc02-fdb7-4f47-9445-d8c79d399e8c]'`. This can only ever REMOVE a genuinely-unbacked tranche: reaching (b)-ABANDON or (c)-EXPIRE means the order NEVER filled — any fill, even a partial, matches branch (a) above and is routed to Step 0 fill reconciliation, never here — so `K`'s shares sit in `state.current_positions` but in NO `analytics.position_lifecycle` open lot. Belt-and-suspenders (guards a bug elsewhere; impossible under the never-filled invariant): if closing `K` would drop `(strategy,ticker)`'s `SUM(state.current_positions.shares)` BELOW its `analytics.position_lifecycle` open-share total, do NOT write the CLOSE — `CALL ops.sp_raise_alert_once('warning','D2a','phantom_close_skipped', 'refused compensating CLOSE for '||K||': would undercount lifecycle — investigate', TO_JSON_STRING(STRUCT(<item_key> AS item_key, K AS position_key, <strategy> AS strategy, <ticker> AS ticker)))` and leave the row for a human. Park legs (`strategy IS NULL`) never reach `events.position_events` and are out of scope.
- **OPEN WITHDRAWAL CANDIDATES — mandatory second pass before residual assessment (2026-08-12
  missed-consumption incident).** Immediately after the fresh account/balance reads, and BEFORE the
  cash/park tripwire below computes or attributes this session's residual, always
  `SELECT * FROM state.cash_flow_candidates_open ORDER BY observed_date, candidate_key` and adjudicate EVERY
  returned row against those fresh connector balances. A zero current-session residual does not discharge an open candidate. For each row, either call
  `ops.sp_record_withdrawal` with that row's own key/date or append its retraction; log the key and disposition.
  Do not start the tripwire/residual calculation until the query's original result set is fully consumed.
- **Cash/park balance reconciliation — tripwire (every run, before any sizing/staging; full procedure
  Operating_Protocols.md §13).** First, `SELECT vehicle FROM state.park_policy_current` — this is "the park"
  for every step below (SGOV through the 2026-07-15 cutover; VOO from the owner's manual transfer forward).
  Compute expected park shares + cash (Σ per-strategy park-allocation +
  cash residuals from `analytics.account_reconciliation`, + `state.park_reconciliation` for park shares) vs live
  park-vehicle shares (`get_account_positions`, contract_id per the current vehicle — SGOV 424099317, VOO
  136155102) + live cash (`get_account_balances`), netting out
  commissions/realized-P&L of fills reconciled this run. Attribute every non-zero residual per the §13 decision-tree
  (dividend/interest, deposit/withdrawal, standalone fee, commission-on-fill, operator park-sale-to-cover, or
  genuinely unexplained → log + flag + conservative hold, never silently absorb). A residual that stays UNEXPLAINED
  and exceeds ~$1 is a hard STOP — `CALL ops.sp_raise_alert('critical','D2a','cash_tripwire', <one-line message>,
  <JSON: residual, connector evidence>)` + `CALL ops.sp_log_run('D2a', <today>, 'halted', …, error_msg=<message>)`;
  resolve before sizing or staging. (Note: VOO's per-share price is roughly 5-7x SGOV's, so the same ~$1 dollar
  tolerance is a proportionally tighter share-count margin once VOO is the park vehicle — expected, not a bug.)
- **External withdrawal — TWO-PASS detection, then pro-rata to NAV clamped to idle cash (full procedure Operating_Protocols.md §13.C, machinery `bigquery/161_withdrawal_after_the_fact.sql`).**
  A withdrawal is NEVER declared in advance and is NEVER committed on the session that first sees it.
  When the tripwire above attributes an unexplained cash DECREASE to a probable withdrawal (per §13.B
  cause-finding — no matching trade, no corporate action, and corroborated by
  `get_pa_performance_all_periods` showing a flow-adjusted TWR near zero across the NAV move):
  **FIRST PASS —** `INSERT` a row into `events.cash_flow_candidates` (`status='open'`,
  `direction='WITHDRAWAL'`, signed negative `amount`, `evidence` = balances before/after + the TWR
  reading) and treat that residual as EXPLAINED-PENDING, so it does NOT trip the `cash_tripwire` hard
  STOP above and does NOT halt this session. **SECOND PASS (next session) —** re-read the connector.
  Cash still gone → `CALL ops.sp_record_withdrawal(<positive magnitude>, <flow_date>, <note>,
  <candidate_key>)`, which is the ONLY sanctioned write path (it allocates pro-rata to
  `analytics.strategy_nav.nav`, clamps each strategy to its own `available_funds` and redistributes
  whatever it cannot absorb, writes one `strategy`-tagged row per donor, refuses rather than spilling
  if it exceeds total idle capacity, zero-weights a sub-floor PROBE newcomer, and is idempotent per
  `candidate_key`). Cash returned → append `status='retracted'`; it was a settlement
  hold. **Never hand-write the
  `events.cash_flows` rows for a withdrawal, and never record one as a bare `strategy` NULL row** —
  that equal-split debits strategies holding no idle cash and the withdrawal direction has no
  self-heal (`bigquery/98`'s compensating sweep keys on `available_funds >= 25`, surplus-only).
- **Strategy idle-balance deficit check (backstop, `bigquery/161`).**
  `SELECT * FROM state.strategy_funds_deficit` — expect zero rows. Any row means a cash flow was
  allocated to a strategy that did not hold the money (negative `deposits`) or a strategy is deployed
  beyond its booked NAV. Raise `CALL ops.sp_raise_alert_once('warning','D2a','strategy_funds_deficit',
  '<strategy> — strategy funds deficit; see payload for the amount', <JSON rows>)`
  (key the fixed message on the SINGLE strategy code, one open row per strategy, matching its registered `resolve_rule`).
  **HEAL, FROM THIS SAME READ.** For each strategy
  that has NO row in the read you just did: `UPDATE ops.alerts SET resolved = TRUE, resolved_ts = CURRENT_TIMESTAMP(),
  resolved_note = 'condition healed: state.strategy_funds_deficit no longer returns a row for this strategy
  (healed by D2a)' WHERE category = 'strategy_funds_deficit' AND NOT resolved AND STARTS_WITH(message, '<strategy> — strategy funds deficit')`.
  Per-strategy prefix match, never a category-wide UPDATE — the same reason spelled out at W5's `capital_stranded` heal.. Deliberately a WARNING, not a critical: a critical would enter
  the `blocking_criticals` term of the halt gate and freeze all order staging including exits, which
  is disproportionate for a bookkeeping-integrity signal. Non-latching — it auto-resolves when the
  deficit clears.
- **Owner-confirmation liveness gate — the absence model for the
  one sanctioned human touch.** `SELECT * FROM state.owner_confirmation_liveness`
  (current body `bigquery/269_owner_confirmation_pending_age.sql`; chain 76 -> 209 -> 211 -> 269; 209 remains
  the canonical home of the park-tap argument below, and 76 of this gate's SCOPE note and its
  `ops.trading_control` usage convention). **PARK CONFIRM-TAPS COUNT.**
  `trading_days_since_last_fill` measures from the LATER of the last `events.trade_fills` fill and the
  last `events.parking_events` `BUY`/`SELL` `action_date`, because a park sweep / cover / switch leg is an
  owner confirm-tap on the same IBKR surface as any other order (Operating_Protocols.md §13.E, "the
  operator still taps to confirm") and is recorded ONLY in `parking_events` (§13.D, §13.E step 5/6). Do NOT
  narrow it back to `trade_fills` alone because park fills are owner taps too. `last_park_fill_date` and
  `last_owner_tap_date` are on the view so the reading is auditable. **AND AN AUTOMATIC DRIP IS NOT A TAP,
  ON EITHER SIDE.** `events.parking_events` `DIVIDEND_REINVEST` / `RECON_ADJUST` are excluded by the
  BUY/SELL allowlist, and `events.trade_fills` rows with `order_id = '0'` — IBKR's automatic reinvests,
  5 of 50 rows, no broker order id because the owner placed no order — are excluded too. The owner tapped
  nothing on those days; counting them would report responsiveness that did not happen. If `entries_halted = TRUE` (>=1 `state.open_orders`
  row still `pending` AND `trading_days_pending_untapped >= 3` — a staged instruction has waited 3+ trading
  days with no owner confirm-tap of any kind). **THE CLOCK STARTS WHEN SOMETHING IS WAITING.**
  `trading_days_pending_untapped` counts from the LATER of `last_owner_tap_date` and
  `oldest_pending_staged_date` (the FIRST `ORDER_STAGED` row of the longest-waiting pending item_key,
  stable across re-crafts). Do NOT gate on `trading_days_since_last_fill` again: it banks quiet days with
  nothing to tap, and must not count them against a newly staged instruction. `trading_days_since_last_fill` stays on
  the view and in the marker reason / payload as context only: (a) OPEN THE MARKER — keyed on the
  CONTROL-ROW state, never on an alert existing: `INSERT INTO ops.trading_control (halt_all, mode, reason,
  set_by) SELECT FALSE, 'entries_halted', '<n_pending_instructions> pending instruction(s),
  <trading_days_since_last_fill> trading days since the last reconciled fill', 'D2a' FROM UNNEST([1]) AS _t
  WHERE NOT EXISTS (SELECT 1 FROM ops.trading_control o WHERE o.mode = 'entries_halted' AND NOT EXISTS
  (SELECT 1 FROM ops.trading_control c WHERE c.mode = 'entries_halted_cleared' AND c.control_ts > o.control_ts))
  AND NOT COALESCE((SELECT halt_all FROM ops.trading_control ORDER BY control_ts DESC LIMIT 1), FALSE)` — an
  AUDIT-TRAIL row only (`halt_all` stays `FALSE`; see the HALT-ROW GUARD below and that file's header for why
  this must never flip `halt_all`). The guard keys on THIS LANE being closed rather than on alert absence: an
  alert resolved out of band while `entries_halted` is still TRUE would otherwise let the next run open a
  SECOND marker for the same episode. Then, and only if no unresolved `owner_confirmation_stale` alert already
  exists — that condition is load-bearing on the RAISE and stays, because the message below embeds two counters
  that change run to run and would defeat `sp_raise_alert_once`'s (category, message) dedup —
  `CALL ops.sp_raise_alert_once('warning','D2a','owner_confirmation_stale', 'Owner confirm-tap
  liveness: pending instructions are not being tapped — see payload for the pending count and the trading
  days since the last fill. D2 NEW-ENTRY staging (fresh GO decisions only) is paused; already-staged orders —
  entries and exits alike — keep re-crafting daily, unaffected.', <JSON:
  n_pending_instructions, trading_days_pending_untapped, oldest_pending_staged_date,
  trading_days_since_last_fill, last_fill_ts, last_park_fill_date, last_owner_tap_date>)` — carry BOTH tap sources in the payload, so a reader can tell a genuine absence
  from a measurement artifact without re-querying. D2's "2. NEW ENTRY CANDIDATES"
  step reads this same view before crafting any new entry and skips staging (logging the GO as
  staged-but-paused, same pattern as the PENDING-NEWCOMER FROZEN CHECK) while `entries_halted = TRUE`;
  this routine's own Staged-order registry reconciliation above (§11) — which re-crafts ANY already-staged
  pending row, entries and exits alike — is completely unaffected either way.
  If `entries_halted = FALSE`, run the two arms below INDEPENDENTLY — the audit-trail close is keyed on the
  CONTROL-ROW state, never on an alert existing; alert absence must not leave its marker open.
  (i) ALERT RESOLVE — only when an unresolved `owner_confirmation_stale` alert exists (the gate has since
  cleared — auto-clears with no operator action): `UPDATE ops.alerts SET resolved = TRUE, resolved_ts =
  CURRENT_TIMESTAMP(), resolved_note = 'auto-resolved: state.owner_confirmation_liveness.entries_halted is
  now FALSE — <name what actually cleared it: the owner confirm-tap, strategy or park, or the other change>'
  WHERE category = 'owner_confirmation_stale' AND NOT resolved`. Correctly alert-scoped: with no alert open
  there is nothing to resolve. Name the actual cause; never assert a fill without evidence.
  (ii) AUDIT-TRAIL CLOSE — fires whenever the marker lane is still OPEN (some `mode='entries_halted'` row has
  no LATER `mode='entries_halted_cleared'` row), whether or not an alert exists or ever did: `INSERT INTO
  ops.trading_control (halt_all, mode, reason, set_by) SELECT FALSE, 'entries_halted_cleared', '<WHAT ACTUALLY
  cleared it — the owner confirm-tap (strategy fill OR park fill), or the other change that did, never assume a
  fill; plus the control_id of the entries_halted row being closed>', 'D2a' FROM UNNEST([1]) AS _t
  WHERE EXISTS (SELECT 1 FROM ops.trading_control o WHERE o.mode = 'entries_halted' AND NOT EXISTS
  (SELECT 1 FROM ops.trading_control c WHERE c.mode = 'entries_halted_cleared' AND c.control_ts > o.control_ts))
  AND NOT COALESCE((SELECT halt_all FROM ops.trading_control ORDER BY control_ts DESC LIMIT 1), FALSE)`. Keying
  the guard on the open marker is what makes the write idempotent: once the close lands the lane is matched, so
  a retry, a second run the same day, and every run until `entries_halted` next goes TRUE are all no-ops —
  whereas a same-DAY-existence guard would still write a fresh close on every later flip-day. `FROM UNNEST([1])`
  is load-bearing, not noise (GoogleSQL rejects a literal-only SELECT carrying a WHERE — the same note as in
  `bigquery/151_connector_tool_inventory.sql`).
  **HALT-ROW GUARD (both arms).** Every row this bullet writes carries `halt_all = FALSE`, and the
  `AND NOT COALESCE((SELECT halt_all ...), FALSE)` term in both INSERTs is what makes that safe rather than
  merely conventional. The "ops.trading_control usage convention for this gate" block in
  `bigquery/76_owner_confirmation_liveness.sql` claims a `halt_all=FALSE` marker "can NEVER interact with that
  global latest-row selection, by construction"; that holds in ONE DIRECTION ONLY. No consumer of
  `state.trading_control_latest` / `state.trading_enabled` / `state.trading_enabled_mechanical` filters by
  `mode` — each reads `halt_all` off the single latest row by `control_ts` — so a marker landing after a
  genuine `halt_all=TRUE` row would itself read as an un-halt of the whole book. That is exactly what
  `bigquery/23_trading_control.sql`'s header forbids ("an auto halt is cleared by an explicit manual INSERT,
  never by another automated row") and records as not enforced in SQL; the guard enforces it here. Nothing is
  lost by deferring — because both arms are state-keyed, a write skipped under a halt is simply made by the
  next run after the halt clears.
  **IF THIS BULLET'S OWN SPEC LOOKS WRONG WHILE YOU ARE EXECUTING IT, FILE IT — do not just narrate it in the
  run-log note or the row's `reason`.** That is the shared OUT-OF-SCOPE FINDINGS rule (§Observability) applied here. Write the `ops.alerts` `info` row naming the
  owning surface, then proceed. This is in-band,
  fail-safe, and reversible — it does not touch `state.trading_enabled`/`halt_all`-the-mechanism, the
  mechanical kill triggers, the IBKR confirm-tap requirement itself, or deposits.
- **Book soft-drawdown surfacing (record-only).** After
  Step 0b's account snapshot (which is what makes `state.book_drawdown_watch` current for today),
  `SELECT book_drawdown_soft_breach, block_reason FROM state.entry_staging_allowed`
  (`bigquery/78_book_drawdown_rebase_and_staleness_gate.sql`). If `book_drawdown_soft_breach = TRUE`
  (the flow-adjusted book NAV is >= 15% below its high-water trading gain — the entries-only SOFT tier,
  NOT the -40% catastrophe hard-halt), `CALL ops.sp_raise_alert_once('warning','D2a','book_drawdown_soft_breach',
  'Book drawdown soft breach — D2 NEW-entry staging is paused; exits, kill-trigger terminations and park
  cover are unaffected. See payload for drawdown_from_peak, capital_base and as_of_date.', <JSON: drawdown_from_peak, capital_base, as_of_date>)`
  Keep the message fixed so a persisting breach has one open row. This is a RECORD-ONLY warning,
  exactly parallel to the `owner_confirmation_stale` warning above: it surfaces that D2's NEW-entry
  staging is paused via `state.entry_staging_allowed.entries_allowed` (consumed by D2's ENTRY-STAGING
  GATE) — it does NOT halt exits, kill-trigger terminations, or park cover, and does NOT flip
  `halt_all`. `sp_raise_alert_once` dedups on the unresolved (category, message), so a persisting
  breach does not re-email daily. HEAL: when `book_drawdown_soft_breach` reads FALSE and an unresolved
  alert of this category exists, `UPDATE ops.alerts SET resolved=TRUE, resolved_ts=CURRENT_TIMESTAMP(),
  resolved_note='condition healed — book NAV recovered above the -15% soft threshold' WHERE
  category='book_drawdown_soft_breach' AND NOT resolved` (the same evidence-based routine-owned resolve
  as the `interim_underperf_warning`/`termination_close_staged` precedents).
- **SNAPSHOT-SURFACE CIRCUIT BREAKER.** Before calculating a park sweep or cover, request the current park vehicle's `get_price_snapshot`. On a transient-looking tool error, retry that request once after a short backoff; on a non-transient error, do not retry. If an attempt yields a structurally valid response, first perform the narrow recovery step: read unresolved `source='D2a' AND category='connector'` alerts for this surface and resolve by exact `alert_id` only (a) structured `connector='IBKR' AND surface='get_price_snapshot' AND (scope='account-wide' OR (scope='symbol-specific' AND symbols contains the current park vehicle))`, plus (b) the legacy 2026-08-12 shape `failing_method='get_price_snapshot'`; the successful target-symbol read proves those conditions clear. Then, if the response has a usable side of the book (ask for a BUY sweep, bid for a SELL cover), continue below. If the park vehicle still has no structurally valid snapshot after the allowed attempt(s), the sweep/cover is **always deferred**: probe SPY once (or QQQ if SPY is itself the park vehicle) only to classify the scope. If the independent probe also errors, classify `get_price_snapshot` account-wide unavailable and `CALL ops.sp_raise_alert_once('warning','D2a','connector', 'IBKR get_price_snapshot unavailable for <park vehicle> and <probe symbol>; park sweep/cover deferred — account reconciliation and historical marks continued', <JSON: connector="IBKR", surface="get_price_snapshot", symbols:[<park vehicle>,<probe symbol>], scope="account-wide", free_cash, bridge_adjusted_settled_cash, park_attempts:<1 or 2>, error_verbatim>)`. If the independent probe succeeds, classify the failure as park-symbol-specific and raise the same narrowly scoped warning with `scope="symbol-specific"`, `symbols:[<park vehicle>]`, and `successful_probe=<probe symbol>`; do not craft from the probe symbol's price. In either failure branch, log the deferred amount in this run's note and **skip only the sweep/cover for this run**. Do not use history, prior close, web data, or a cached price to size or authorize a MARKET park instruction; do not set a terminal registry state; the same cash is re-evaluated next run after a fresh successful park-vehicle snapshot. A valid park snapshot with an empty/stale executable side is the ordinary no-liquidity branch: defer this craft without treating the connector as down. This circuit breaker does not abort fill reconciliation, account snapshotting, or `get_price_history` mark ingestion, whose connector reads have separately succeeded.
- **Cash flattening — auto-craft the park sweep/cover (§13.E).** **TRADING-ENABLE RE-CHECK — apply BEFORE crafting:** if the `state.trading_enabled_mechanical` verdict carried forward from this routine's TRADING-ENABLE GATE reads FALSE, do NOT craft and do NOT write an `ORDER_STAGED` row — record the skip via `CALL ops.sp_log_decision(...)` citing `halt_reason` and continue; the sweep is re-evaluated next run. This is the one craft site D2a owns, and it is exactly what that gate paragraph names as blocked — restated here because a rule stated only at the top of the routine is not a control. (It does NOT cover the staged-order registry's daily RE-CRAFT of an already-staged, owner-confirmed pending order further below — that is deliberately unconditional; see the gate paragraph.) **ORDER-GUARD CHECK next — `SELECT * FROM
  analytics.fn_order_guard(NULL, '<BUY|SELL>', <qty>, <ref_price>, 'MARKET')` (park now uses the SAME 5-arg
  guard as any other order — no park distinction, owner directive 2026-07-22, `bigquery/104_strip_pretrade_rails.sql`:
  market-only + qty/ref-price sanity only. The former park-exemption framing, the 1.10×-NAV magnitude backstop, and
  the already-retired per-vehicle price band are ALL gone — there is no limit price to band and no park-specific
  rail left to apply). If
  `passed = FALSE`, do NOT craft — `CALL ops.sp_raise_alert_once('critical','D2a',
  'order_guard_block', '<routine> — order guard rejected a staged order: <guard-reasons>; see payload for the order fields', <JSON>)` (**MESSAGE PINNED 2026-09-07:** `<reasons joined>` named no join order, so the same rejection permutes between runs and re-raises — on a CRITICAL. `<guard-reasons>` is the DISTINCT reason codes, sorted ASCENDING, joined by a single comma with NO spaces) and skip this sweep/cover for the session. If `passed = TRUE`,
  embed `guard_passed`/`guard_reasons` from this check into the `ORDER_STAGED` row's payload when the sweep/cover is
  staged below, per the "Crafting an order (equity/ETF)" guard-result-embedding step convention — cited by
  name, not step number, to survive renumbering.** On **settled** cash:
  `free_cash = settled_cash − Σ reserved_cash from state.open_orders` (the durable registry — plus any live unfilled
  BUY not represented there). **Sweep** if `free_cash ≥ +$25` → BUY the current park vehicle sized DOWN
  `floor_to_4dp((free_cash − comm_buffer)/ask)`. **Cover** if `bridge_adjusted_settled_cash ≤ −$5` (a *realized, unfunded* debit) → SELL the
  current park vehicle sized UP `ceil_to_4dp((|bridge_adjusted_settled_cash| + comm_buffer)/bid)`, capped at the vehicle
  held. `bridge_adjusted_settled_cash = settled_cash + Σ expected_net_proceeds(paired SELLs that have FILLED but not
  yet SETTLED)` — MANDATORY (owner directive 2026-07-26, Operating_Protocols.md §13.E step 4). NEVER trigger or size a
  cover off raw `settled_cash`: a paired rotation's BUY deliberately fills on margin one settlement cycle before its
  funding SELL lands, so the raw figure reads a debit of order the full switch notional, and covering it would SELL the
  brand-new policy vehicle and partially unwind the switch D2 just made.
  `comm_buffer` per Operating_Protocols.md §13's Commission model — SGOV: `min(1% × trade_value, $0.35)`
 ; VOO: **the SAME formula.** A sweep is by construction a $25–$35 order, so it lands on the **1% arm**, not
  the cap. Still take the LARGER of this estimate and the connector's latest per-order commission from
  `get_account_trades`; the formula slightly under-states. Do NOT revive the
  retired 2026-07-15 reading that VOO is on a different (≈0.0038%, "tiered per-share") schedule — that was a cap-arm
  observation misread; see Operating_Protocols.md §13's **Commission model — VOO** note. Otherwise no action (a $0…−$5 debit is left on margin). This sweep/cover is now the BACKSTOP for BOTH legs of a switch (D2 crafts both in-session): it re-crafts either leg whose DAY order expired unfilled and deploys whatever residual the haircut left behind. Order:
  contract_id per the current vehicle (above), TIF **DAY**, `order_type='MARKET'` (no `limit_price` argument
  transmitted); record the live reference price (last, or bid/ask mid) in the staged payload's `limit_price` field
  for cash-reservation/notional purposes only; record the
  instruction `id` + a 07:00 confirm event — **not** a `events.parking_events` row yet (Operating_Protocols.md
  §13 step 5/6: that row is inserted only once the order fills, one row per fill);
  attribute to the owning strategy(ies) per §13.C so Σ per-strategy park allocation = connector park-vehicle
  holding and Σ per-strategy cash ≈ $0. Never sweep cash a pending buy needs.
  **SUNDAY / NO-SESSION SLOT — the sweep DEFERS, it does not craft off the settled close).** D2a's Sunday slot sits on a day with NO market session at all, so `get_price_snapshot` for the park vehicle returns a STRUCTURALLY VALID response — `top-status` `REALTIME`, a populated `prior-close` — whose `bid-ask` object is EMPTY and whose `last` carries `is_close: true`, i.e. Friday's settled close. There is therefore no `ask` to size `floor_to_4dp((free_cash − comm_buffer)/ask)` against. This is the SNAPSHOT-SURFACE CIRCUIT BREAKER's **ordinary no-liquidity branch**, not a connector failure: **defer the sweep/cover, write NO `ORDER_STAGED` row, call NO `create_order_instruction`, set NO terminal registry state, raise NO `connector` alert** (the connector answered correctly; the market is shut), record the deferred amount via `CALL ops.sp_log_decision(...)` and in `<note>`, and re-evaluate the same cash next run against a fresh snapshot. **Do NOT craft from the settled close, the prior close, or a connector mark** — Operating_Protocols.md §11 forbids exactly that, and the `limit_price` field's "record the live reference price (last, or bid/ask mid)" allowance above is a *notional/cash-reservation* record on an order that is being sent, never an authorization to send one with no live book behind it. D2a's Mon–Thu slot is 16:40 MT / 18:40 ET, inside the 16:00–20:00 ET extended session with a live book. **This is NOT a defect to "fix" by moving D2a's Sunday slot, adding a Monday-morning pre-open craft path, or sizing off a stale mark:** the cash simply waits one day, and the alternative is a MARKET order priced off a figure no one can trade at.
- Note still-working / partial orders from `get_account_orders` and leave them exit-pending / ORDER-STAGED (the
  persist-and-wait re-craft is handled by the registry reconciliation above). For any crafted instruction in
  `get_order_instructions` whose order day has passed unconfirmed, or whose position Step 0 just closed, call
  `delete_order_instruction` to clear it.
- REGIME-CAPITAL SYNC (Operating_Protocols.md §16 REGIME-CAPITAL SYNC + §13.C; `bigquery/98_regime_capital_enablement.sql`). LAST
  thing in Step 0, after fills/attribution/flattening: `SELECT * FROM state.regime_capital_sync_pending`.
  **HEAL FIRST, FROM THIS SAME READ, BEFORE YOU BRANCH.** `regime_sweep_blocked` and `regime_restore_blocked` have registered non-latching D2a-owned resolve rules. From the rows you just read: if **no `SWEEP` row has `blocked_no_recipient = TRUE`** and an unresolved
  `regime_sweep_blocked` alert exists → `UPDATE ops.alerts SET resolved=TRUE, resolved_ts=CURRENT_TIMESTAMP(),
  resolved_note='condition healed: state.regime_capital_sync_pending no longer returns a SWEEP row with
  blocked_no_recipient TRUE — <name what actually cleared it: a router re-enable, a roster change, or the holder
  dropping below the $25 de-minimis floor>' WHERE category='regime_sweep_blocked' AND NOT resolved`. INDEPENDENTLY —
  **and NOT by the same absence test, which would be wrong for RESTORE** — resolve `regime_restore_blocked` only on
  POSITIVE evidence: either the view now returns a `RESTORE` row with `blocked_no_recipient = FALSE` (the restore is
  fundable again), OR `state.regime_capital_debt` shows the debtor no longer carrying outstanding regime debt (it was
  repaid by some other path). Then the same `UPDATE` with `category='regime_restore_blocked'` and the RESTORE wording,
  naming which of the two cleared it.
  **WHY RESTORE IS NOT SYMMETRIC WITH SWEEP, and why "no blocked row" must NOT be read as healed here.** For SWEEP
  the two branches really are an exact partition (`sweep_blocked` on `NOT EXISTS (enabled_recipients)` versus
  `sweep_rows` on the CROSS JOIN over the same `sweep_candidates`), and the candidate population emptying IS a
  genuine heal — the registered `resolve_rule` says so outright ("or when the capital-disabled strategy holding the
  cash drops below the $25 de-minimis floor"). RESTORE has no such partition: `restore_blocked` fires only at
  `payable = 0` and `restore_rows` only at `payable >= LEAST(25, outstanding_debt)`, so the band
  `0 < payable < LEAST(25, outstanding_debt)` emits **NO ROW AT ALL** — `bigquery/223`'s own header names this a
  DELIBERATE RESIDUAL that "this file does NOT report". In that band the debt is still fully outstanding and the
  alert's pinned message ("the eligible donor set cannot fund the de-minimis floor, so nothing moved") is still
  literally TRUE, yet a bare absence test would read it as healed and close the only row on the board saying so.
  Absence of a RESTORE row is AMBIGUOUS — debt repaid, or throttled — and only `state.regime_capital_debt`
  disambiguates it. This is deliberately STRICTER than the category's registered `resolve_rule`, whose "holds
  positive available_funds again" phrasing would close the throttled band; where the two disagree, prefer leaving a
  true alert open over closing it,. Same evidence-based
  routine-owned resolve as the `owner_confirmation_stale` and `book_drawdown_soft_breach` clauses above. Scoping by
  category ALONE is safe here for a reason specific to these two: both messages are PINNED literals, so
  `sp_raise_alert_once`'s `(category, message)` dedup makes at most ONE unresolved row per category possible by
  construction. That argument does NOT generalise — a
  category whose message interpolates a varying value can hold several open rows at once, and category-scoped
  resolves are wrong for those.
  **THIS IS AUTHORISED, and a future session must not revert it on a correct-looking reading of the shared rules.**
  The shared INCIDENT INHERITANCE bullet says "every capital-affecting class stays human-only per the fail-closed
  allowlist", and read alone that sentence forbids the UPDATE above. It is the DEFAULT for categories carrying no
  registered rule, not a blanket prohibition — exactly the point SL3's `probe_funding_stalled` pin already
  adjudicated for a structurally identical category: "Where a category carries its own registered rule, that rule
  governs; the two-category sentence is the DEFAULT for categories that carry none." `bigquery/34_alert_lifecycle.sql`
  built `ops.alert_policy` for precisely this, and all three categories here are registered `latching = FALSE` with a
  `resolve_rule` — two of them naming D2a outright. `ops.sp_auto_resolve_alerts` handles `missing_dependency`/`missed_run`/`routine_stalled`/`catchup_refire_blocked`/`staleness` plus roster notices, not these categories.
  **DO NOT MOVE THIS INSIDE THE "Empty" BRANCH — that would be a VACUOUS fix, and it is the obvious place to put
  it.** The blocked and healthy shapes of a given strategy are COMPLEMENTARY branches of this same view over the
  same population, keyed on the same predicate: `sweep_blocked` fires `WHERE NOT EXISTS (SELECT 1 FROM
  enabled_recipients)` and `sweep_rows` populates the moment that relation is non-empty, so a heal flips
  `blocked_no_recipient` TRUE→FALSE **without the view ever returning zero rows** (for RESTORE the shapes are NOT complementary — see the
  asymmetry paragraph above — but the same "never returns zero rows" hazard applies to its healthy branch).  **Read the FLAG, never the row count.** And do not re-`SELECT`: evaluate
  the heal and the raise branches from ONE read, per the ONE MOVEMENT PER READ discipline this substep already
  follows — a second read can observe a different snapshot and resolve an alert the raise branch is about to
  re-assert.
  Empty (the steady state) → no-op, nothing to log — apart from the heal above, which is evaluated either way.
  Non-empty:
  - `control_enabled = FALSE` (the `ops.capital_control` kill-switch) → log a one-line `events.decision_log`
    note recording what WOULD have moved, and move nothing.
  - **`blocked_no_recipient = TRUE` on a `SWEEP` row** (`bigquery/215`; capital to sweep, but EVERY capital-enabled
    strategy is itself nomadic, so there is nowhere legal to put it) → move nothing and `CALL
    ops.sp_raise_alert_once('warning','D2a','regime_sweep_blocked', <the EXACT STABLE message below>,
    <JSON payload>)`. **PIN THE MESSAGE — it is `sp_raise_alert_once`'s dedup key, so any varying value
    in it raises a NEW alert EVERY run.** Use verbatim, with no interpolation: `'Regime sweep blocked:
    a capital-disabled strategy holds sweepable idle cash, but every capital-enabled strategy is
    nomadic, so there is no eligible recipient and nothing moved. Strategies and amounts in payload.'`
    The varying figures — `strategy`, `amount`, the capital-enabled set, NAV share — go in the PAYLOAD,
    never the message. This condition persists for as long as the router leaves the roster deactivated
    (it is not self-clearing in a session), so an interpolated message would emit one warning per day
    indefinitely — the permanently-red-advisory failure this fleet has hit before. Exactly the sibling handler
    of the nomadic bullet below, and it exists for the same reason: without it the view returns ZERO
    rows and a whole-roster deactivation is **indistinguishable from the healthy empty-view steady
    state**, so do NOT treat it as a no-op.  Do NOT "unblock" it by widening
    the recipient set; `capital_enabled AND NOT nomadic` is load-bearing (`bigquery/168` FIX 7, and
    `sweep_recipient_view_drift` records what happened the last time the set was taken from elsewhere).
    The correct response is an owner decision about the roster.
  - **`blocked_no_recipient = TRUE` on a `RESTORE` row** (`bigquery/223`, which supersedes `bigquery/215` for this
    view; a debtor strategy is capital-enabled again and owed a restore, but the eligible donor set cannot fund
    even the de-minimis floor — `payable = 0` — so there is nothing to move) → move nothing and `CALL
    ops.sp_raise_alert_once('warning','D2a','regime_restore_blocked', <the EXACT STABLE message below>, <JSON
    payload>)`. **ITS OWN CATEGORY AND ITS OWN MESSAGE — never reuse the sweep pair above.** `sp_raise_alert_once`
    dedups on `(category, message)` while unresolved, so a restore raised under the sweep category and the
    sweep-worded message would be SILENTLY SWALLOWED by an already-open sweep alert — the restore would never
    reach the board at all, and the sweep message ("a capital-disabled strategy holds sweepable idle cash") is
    factually wrong about a restore besides. **PIN THE MESSAGE**, same dedup-key rule as the sweep bullet above;
    use verbatim, with no interpolation: `'Regime restore blocked: a debtor strategy is capital-enabled again and
    owed a restore, but the eligible donor set cannot fund the de-minimis floor, so nothing moved. Strategies and
    amounts in payload.'` The varying figures — `strategy`, `outstanding_debt`, the donor set and its capacity,
    and the row's own `blocked_reason` (`'no_eligible_recipient'` when the debtor is the only eligible recipient
    or there is none at all, `'no_donor_capacity'` when eligible recipients exist but hold no available funds) —
    go in the PAYLOAD, never the message. Carry `blocked_reason`: it is the one field that says WHICH of the two
    configurations blocked the restore, and the pinned message deliberately cannot, so without it the payload
    leaves the reader to re-derive it from the donor set by hand. Same rationale as its sweep sibling: `bigquery/223` emits this row
    precisely so a blocked restore is distinguishable from the healthy empty-view steady state, so do NOT treat
    it as a no-op.
  - SWEEP rows (a capital-disabled strategy with `available_funds ≥ $25`): **THE RECIPIENT SET IS THE
    `counterparty_strategy` VALUES `state.regime_capital_sync_pending` ITSELF RETURNS — that view is the
    sole authority on recipient ELIGIBILITY (`bigquery/168` FIX 7: `capital_enabled AND NOT nomadic`).
    NEVER take the recipient set from the weight view; it supplies only the SHARES among an
    already-eligible set.** A nomadic strategy holds no exclusive standing capital ever
    (Operating_Protocols.md §16), so it is not an eligible recipient; the weight view supplies weights, not eligibility. Having fixed the set, apply the MECHANICAL CAPACITY
    WEIGHT (`state.sweep_recipient_weights`, `bigquery/164` as superseded by `bigquery/202`) — `SELECT strategy_code, sweep_share,
    equal_share, band_multiplier, capacity_ratio, deployed_days_180 FROM state.sweep_recipient_weights`
    and set each recipient's amount to `ROUND(swept_amount * sweep_share, 2)`, with the LAST recipient row
    absorbing the rounding residual so the double-entry is exactly $0-sum. **Why this replaces the old default-EQUAL read:** §16 permits a [0.5×, 2×]
    tilt but reaches it only through an AI capital-allocation call at MEDIUM+ conviction, and **D2a
    carries NO analysis by design** — so every unattended sweep fell back to an equal split, permanently
   . The weight needs no judgment: it is the share of the trailing 180 days
    each recipient actually held a position, mapped onto §16's band. **No band-fitting pass is needed** —
    `band_multiplier` is already clamped to `[0.5, 2.0]` in SQL before normalisation, so every
    `sweep_share / equal_share` ratio is inside the sanctioned band by construction. **It keys on
    deployment CAPACITY, never on P&L** (§16 rejects merit-weighting a short, noisy sample), and it
    degenerates to exactly the equal split when recipients are indistinguishable — so it can never be
    worse than the old behaviour. **Fall back to DEFAULT-EQUAL** (the view's own `equal_share`, or the
    view's `counterparty_baseline_amount` if `state.sweep_recipient_weights` returns no rows or its
    `sweep_share` values do not sum to 1.0 ± 0.0001) and say so in the note. **If the weight view and
    the pending view disagree about the recipient SET** — they must not after `bigquery/202` gave the
    weight view the same nomadic exclusion, so this is now a tripwire rather than an expected branch —
    drop any weight row for a strategy absent from the pending view's recipient set, renormalise the
    surviving `sweep_share` values to sum to 1.0, use the result, and raise
    `ops.sp_raise_alert_once('info','D2a','sweep_recipient_view_drift', ...)` naming both sets. A weight
    row for an ineligible recipient is an eligibility BUG in the weight view, never a tilt to be honoured. Then write the atomic $0-sum
    **`flow_type` (NOT NULL, no default) FOLLOWS THE SIGN OF `amount`, NEVER WHETHER MONEY CROSSED THE ACCOUNT BOUNDARY; binds EVERY `events.cash_flows` writer (D2, D2a, AR_orc).** An internal double-entry writes BOTH values: `'WITHDRAWAL'` on the negative donor leg and `'DEPOSIT'` on the positive recipient leg. The documented domain is `'DEPOSIT' | 'WITHDRAWAL'` (`bigquery/22_cash_flows.sql`:19). Inventing a `'TRANSFER'`-style third value for an internal move would be the intuitive reading and is WRONG: `analytics.strategy_nav` and the §13 cash-tripwire baseline sum the two documented values only, so a third would silently vanish from booked deposits and NAV. *(Pre-2026-10-30 history and evidence for this rule: `ops/plan_history/D2a.md` § H-D2a-04.)*

## H-D2a-05 — events.cash_flows doubleentry on one flow_date tagged source='regime_capital_sweep' (one negative

_Moved verbatim from `Claude_Task_Plan.md` (D2a, was line 2006) on 2026-10-30. Historical record only; the binding rule is the condensed text in the plan._

    `events.cash_flows` double-entry on one flow_date tagged `source='regime_capital_sweep'` (one negative
    row for the swept strategy, positive rows per recipient) and `CALL ops.sp_log_decision(...,
    entry_type='capital-allocation', ...)` per §16 Logging, with `fields` JSON carrying
    `is_default_equal=false`, `conviction='MECHANICAL'`, `conviction_pct=null`,
    `weight_source='state.sweep_recipient_weights'`, `winner_code`/`runner_up_code` = the highest and
    second-highest `sweep_share`, a `rationale` quoting each recipient's `capacity_ratio` and
    `deployed_days_180`, and a `theater_check` stating plainly that no judgment was exercised — this is
    arithmetic over deployment history, not an AI call. Each recipient's `note` should name its
    `sweep_share`, `band_multiplier`, `capacity_ratio` and `deployed_days_180`, the source view, and any
    penny adjustment, matching the house style of the 2026-08-06 rows.
  - RESTORE rows (a debtor strategy back to capital-enabled, per `state.regime_capital_debt`): MECHANICAL, no
    AI call — write the `source='regime_capital_restore'` double-entry using the view's pro-rata donor
    amounts; log a one-line `events.decision_log` note (`trigger='regime_enable'` context).
  - ONE MOVEMENT PER READ: after writing any sweep or restore, re-`SELECT` the pending view before acting
    again (multi-RESTORE stale-snapshot defect, 2026-07-19 adversarial review) — at most one movement's rows
    between reads.
- NOMADIC STRATEGY CAPITAL — SWEEP half (owner directive 2026-08-11; canonical rails
  Operating_Protocols.md §16 NOMADIC STRATEGY CAPITAL; schema `bigquery/167_nomadic_capital.sql` as fixed by
  `bigquery/168_nomadic_capital_fixes.sql`). A strategy declared ≤1 trade/month is classified NOMADIC
  **permanently** (`state.strategy_nomadic_status.is_nomadic`, sourced from
  `state.strategy_declared_frequency`) and holds no exclusive standing capital. Runs immediately after
  REGIME-CAPITAL SYNC above, same Step 0 position. `SELECT * FROM state.nomadic_capital_sync_pending`.
  **HEAL FIRST, FROM THIS SAME READ, BEFORE YOU BRANCH (added 2026-09-07, the exact sibling of the regime heal
  above and landed with it so the pair cannot drift again).** `nomadic_sweep_blocked` is registered
  `latching = FALSE` with a `resolve_rule` opening "Auto-resolves when `state.nomadic_capital_sync_pending` stops
  emitting a `blocked_no_recipient` row" — and, unlike its two regime siblings, that rule names no resolver at all.
  **D2a is the resolver**: D2a is the only routine that reads this view, so it is the only routine that can ever
  observe the heal. If **no row has `blocked_no_recipient = TRUE`** and an unresolved `nomadic_sweep_blocked` alert
  exists → `UPDATE ops.alerts SET resolved=TRUE, resolved_ts=CURRENT_TIMESTAMP(), resolved_note='condition healed:
  state.nomadic_capital_sync_pending no longer emits a blocked_no_recipient row — <name what actually cleared it: a
  capital-enabled non-nomadic strategy exists again, or the nomadic strategy fell below the $25 floor>' WHERE
  category='nomadic_sweep_blocked' AND NOT resolved`. **The same "Empty branch" trap applies verbatim and is why
  this sits above the branch:** this view's `blocked` CTE (`WHERE NOT EXISTS (SELECT 1 FROM weights)`) and its
  `allocated` CTE (`CROSS JOIN weights`) are complementary over the same sweeping population, so the heal is a flag
  flip, not a drop to zero rows. Read the FLAG, never the row count, and read it once.
  Empty (the steady state) → no-op, nothing to log — apart from the heal above, which is evaluated either way.
  Non-empty:
  - `control_enabled = FALSE` (the `ops.capital_nomad_control` kill-switch — separate from
    `ops.capital_control` above) → log a one-line `events.decision_log` note recording what WOULD have
    moved, and move nothing.
  - **`blocked_no_recipient = TRUE`** (capital to sweep, but every capital-enabled strategy is itself
    nomadic, so there is nowhere legal to put it) → move nothing and `CALL ops.sp_raise_alert_once('warning',
    'D2a','nomadic_sweep_blocked', <the EXACT STABLE message below>, <JSON payload>)`. This row exists
    specifically so a blocked sweep is distinguishable from the healthy empty-view steady state; do NOT treat
    it as a no-op.
    **PIN THE MESSAGE (2026-09-07 — until now this site carried a literal `...` where the message argument
    goes, while BOTH regime siblings above were pinned verbatim).** `sp_raise_alert_once` dedups on
    `(category, message)` by exact string equality, so an improvised message interpolating the strategy or the
    amount raises a NEW warning EVERY run — and this condition does NOT self-clear within a session, so that
    is one fresh email per day indefinitely: the permanently-red-advisory failure this fleet has hit before,
    and the exact trap the regime bullet above spells out. It has never manifested only because
    `nomadic_sweep_blocked` has never once fired (verified live: zero rows in `ops.alerts`, ever) — an
    unfired-and-therefore-untested raise site, not a safe one. Use verbatim, with no interpolation:
    `'Nomadic sweep blocked: a nomadic strategy holds sweepable idle cash, but every capital-enabled strategy
    is itself nomadic, so there is no eligible recipient and nothing moved. Strategies and amounts in
    payload.'` Deliberately DISTINCT wording from the regime sweep message, for the reason `bigquery/223`
    gives for splitting the restore category out: two blocked conditions sharing one message would let an
    already-open row of the other kind silently swallow this one. The varying figures — `strategy`, `amount`,
    the capital-enabled set — go in the PAYLOAD, never the message.
  - SWEEP rows only — this view never carries a BORROW row; borrowing is on-demand at order-craft time,
    not a daily standing check (Operating_Protocols.md §16 explains why). Write the atomic $0-sum
    `events.cash_flows` double-entry (per the `flow_type` sign rule pinned at the regime-sweep bullet above: `'WITHDRAWAL'` on the negative leg, `'DEPOSIT'` on the positive one) on one flow_date tagged `source='nomadic_capital_sweep'`: one negative
    row for the nomadic strategy at `amount`, one positive row per counterparty at its `counterparty_amount`.
    **Use the view's `counterparty_amount` verbatim and do NOT re-round it** — the view already applies the
    last-row-absorbs-the-residual rule, so `SUM(counterparty_amount)` equals `amount` to the cent by
    construction; re-rounding would reintroduce the very drift that rule removes. Then `CALL
    ops.sp_log_decision(..., entry_type='capital-allocation', ...)` per §16 Logging with `fields` JSON
    carrying `trigger='nomadic_capital_sweep'`, `conviction='MECHANICAL'`, `conviction_pct=null`, and a
    `rationale` naming the swept strategy's `declared_frequency_text`.
  - `amount` is the strategy's `sweepable_amount`, which is already NET of
    `state.open_orders.reserved_cash` — cash a pending staged BUY needs is never swept (bigquery/168 FIX 2,
    the same "never sweep cash a pending buy needs" rule §13 applies to the park sweep). A ≥$25 de-minimis
    movement floor applies (same figure as the regime sweep); below it the balance simply waits.
  - ONE MOVEMENT PER READ, same discipline as REGIME-CAPITAL SYNC above.
- NOMADIC STRATEGY CAPITAL — BORROW-CAPACITY WATCH (found and built 2026-09-22, interactive session
  investigating a Strategy C spec-defect notice — owner-approved same day; canonical rails
  Operating_Protocols.md §16 NOMADIC STRATEGY CAPITAL; schema `bigquery/246_nomadic_borrow_blocked_alert.sql`).
  A standing, daily EARLY-WARNING monitor over the on-demand nomadic-BORROW mechanism — it does not itself
  borrow anything and does not touch the crafting-time NOMADIC-BORROW CHECK
  (`analytics.fn_nomadic_capital_restore_plan`), which remains on-demand at order-craft time only, exactly as
  the SWEEP-half bullet above states ("this view never carries a BORROW row; borrowing is on-demand at
  order-craft time, not a daily standing check"). This substep does not change that — it answers a different
  question daily, before any craft is attempted: does a currently-nomadic, capital-enabled strategy have ANY
  funded donor to draw from right now, so a genuine zero-donor state is visible in advance rather than only
  discoverable the moment a routine tries and fails to borrow. Runs immediately after NOMADIC STRATEGY CAPITAL
  — SWEEP half above, same Step 0 position. `SELECT * FROM state.nomadic_borrow_capacity_watch` (one row per
  currently-nomadic + capital-enabled strategy; `donor_capacity_total` sums every OTHER capital-enabled,
  non-nomadic strategy's available funds; `borrow_blocked = TRUE` when that total is `<= 0`, i.e. every other
  capital-enabled strategy is itself at $0 or capital-disabled).
  **HEAL FIRST, FROM THIS SAME READ, BEFORE YOU BRANCH (same discipline as the SWEEP-half heal immediately
  above, for the same reason: `nomadic_borrow_blocked` is registered `latching = FALSE` with a `resolve_rule`
  naming no resolver but D2a, since D2a is the only routine that reads this view).** If **no row has
  `borrow_blocked = TRUE`** and an unresolved `nomadic_borrow_blocked` alert exists → `UPDATE ops.alerts SET
  resolved=TRUE, resolved_ts=CURRENT_TIMESTAMP(), resolved_note='condition healed:
  state.nomadic_borrow_capacity_watch no longer reports any borrow_blocked=TRUE row — <name what actually
  cleared it: a capital-enabled non-nomadic strategy regained funded capacity, a router re-enable, or a roster
  change>' WHERE category='nomadic_borrow_blocked' AND NOT resolved`. Read the FLAG (whether ANY row is
  `borrow_blocked = TRUE`), never the row count, same "Empty branch" trap as the SWEEP-half heal: a genuinely
  healed state does not necessarily return zero rows, it returns rows with the flag flipped FALSE.
  Empty or all `borrow_blocked = FALSE` (the steady state) → no-op, nothing to log — apart from the heal
  above, which is evaluated either way.
  - Any row with **`borrow_blocked = TRUE`** → `CALL ops.sp_raise_alert_once('warning','D2a',
    'nomadic_borrow_blocked', <the EXACT STABLE message below>, <JSON payload>)` — ONE call per run,
    aggregating every `borrow_blocked = TRUE` row into the payload, never one call per row:
    `sp_raise_alert_once` dedups on `(category, message)` by exact string equality and this message is
    pinned with no interpolation, so a second call this run would simply be swallowed by the first and
    silently drop every strategy after it from the payload. This row exists so a blocked borrow-capacity
    state is distinguishable from the healthy steady state; do NOT treat it as a no-op.
    **PIN THE MESSAGE, same rule as every sibling in this substep.** Use verbatim, with no interpolation:
    `'Nomadic borrow-capacity watch: a nomadic strategy currently has zero funded donor capacity to draw an
    on-demand capital borrow from, because every other capital-enabled strategy is itself at $0 available
    funds or capital-disabled. Strategies and capacity in payload.'` Deliberately DISTINCT wording from
    `nomadic_sweep_blocked` and both regime-blocked messages, for the reason `bigquery/223` gives for
    splitting `regime_restore_blocked` out: a shared message would let an already-open row of a different
    category silently swallow this one. The varying figures — `strategy`, `donor_capacity_total`,
    `donor_count` per blocked strategy — go in the PAYLOAD, never the message.
  - WARNING, never critical, same reason as `nomadic_sweep_blocked`'s own registration (`bigquery/168`):
    a critical enters `blocking_criticals` (`bigquery/176_decouple_embedding_health_from_trading_gate.sql` —
    NOT `bigquery/107`, which carries a live `SUPERSEDED LIVE (2026-08-17)` banner pointing at 176) and halts
    ALL order staging fleet-wide. A capacity WATCH must never halt trading: no capital has moved, none is at
    risk, and no borrow has even been attempted — this is advance notice that a future on-demand borrow would
    currently fail, nothing more.
  - This bullet raises a WATCH only — it never moves money and never gates a craft. The actual borrow event,
    when a nomadic strategy's order notional exceeds its `available_funds`, is still decided solely at
    craft-time by the existing NOMADIC-BORROW CHECK against `analytics.fn_nomadic_capital_restore_plan`'s
    live result, not by this daily view's reading (which can go stale intraday as capital moves).
- RE-RISKING LIMB EVALUATION — **RETIRED (Rev 52, owner directive 2026-10-22, interactive session).** Rev 52 made
  Strategy.md's out-of-cycle refresh rule disjunctive in BOTH directions (§ "Pre-mortem: Regime router" → §6
  Misclassification scenarios, scenarios 1 and 3): every de-risking trigger has a mirror re-risking trigger, and ANY
  ONE of them makes the refresh permitted and required, so the Rev 46 / Rev 48 limb's conjunction (a 15-trading-day
  DO-NOT-ACTIVATE dwell, a measured reversal of the binding override axis and a benign technical plane, all at once)
  is gone. D2a no longer reads `state.rerisking_limb_status` (`bigquery/224`, retired by Rev 52 and left defined
  live under an appended retirement marker naming `bigquery/263`, so apply-in-order replay and live parity are
  unaffected) and no longer raises `rerisking_limb_fired`; M1R STEP 4 still resolves any legacy open row of that
  category by `alert_id`. The limb's role passes to D2 item 4's mirror triggers (its MEASURED OUT-OF-CYCLE REFRESH
  TRIGGER bullet; `shock_price_leg_exit`, read from `state.shock_price_leg_status`, `bigquery/263`, is the measured
  successor of the limb's Brent price leg) plus the REFRESH REQUEST below, which inherits the limb's lane, INSERT
  shape and strategy-blind item text. Of the limb's two scoping rulings, the no-macro-release ruling now binds the
  REFRESH REQUEST below, and the acute-only wiring of leg (b) lapsed with the leg. The substep's 2026-09-05 text is
  in git history.
- REFRESH REQUEST (added 2026-10-19 as the DE-RISKING REFRESH REQUEST, interactive owner session triaging the
  2026-10-19 alert emails; generalized to every measured trigger in both directions by Rev 52, owner directive
  2026-10-22, interactive session; canonical rail Strategy.md § "Pre-mortem: Regime router" → §6 Misclassification
  scenarios, scenarios 1 and 3, which make an out-of-cycle FUNDAMENTAL refresh "permitted and required" on ANY ONE
  trigger, in either direction). **MECHANICAL, no AI call; D2a stays the SOLE writer of `PENDING_REGIME_REFRESH`.**
  It is Step 0's last substep and runs after the two capital substeps above; its position relative to them is not
  load-bearing, because it moves nothing: it never scores a regime, never reads roster membership or activation
  intent, and may write ONE queue row. D2 item 4 detects every trigger the same evening it sees it: its MEASURED
  OUT-OF-CYCLE REFRESH TRIGGER bullet (the technical-plane triggers `vix_regime_high`, `spy_trend_down`,
  `breadth_mom_drop_gt10` and `vix_drift_gt5_ending_normal` and their mirrors `vix_regime_exit_high`,
  `spy_trend_exit_down`, `breadth_mom_rise_gt10` and `vix_drift_down_gt5`, plus the shock price-leg pair
  `shock_price_leg_entry` / `shock_price_leg_exit`), and a D1 flag on a qualifying geopolitical event
  (`geopolitical_qualifying_event`) or a qualifying resolution event (`geopolitical_qualifying_resolution`). It
  services a technical-plane trigger with a same-evening review, and gives each of the four shock-axis triggers (the
  price-leg pair and the two D1 flags) a refresh-only entry with no review (review fix, Rev 52, owner directive
  2026-10-22, interactive session). Either way it logs one `router-review` entry per trigger run carrying
  `fields.measured_trigger` and `fields.trigger_run_start`. Neither the review nor the refresh-only entry is the
  refresh, because Strategy.md's scenario 3 ("REFRESH, never a flip", kept for both directions by Rev 52) defines a
  refresh as re-running the M1a/M1b machinery and authorises no daily routine to score an axis. This substep turns
  each such entry, whichever direction its trigger points and whether or not it was reviewed, into the blind
  re-score. Read ONLY the two trigger fields, never the entry's per-strategy outcome:
  `WITH t AS (SELECT JSON_VALUE(fields, '$.measured_trigger') AS measured_trigger, JSON_VALUE(fields,
  '$.trigger_run_start') AS trigger_run_start, MIN(event_ts) AS logged_ts FROM events.decision_log WHERE
  entry_type = 'router-review' AND JSON_VALUE(fields, '$.measured_trigger') IS NOT NULL AND entry_date >=
  DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 14 DAY) GROUP BY 1, 2) SELECT t.measured_trigger,
  t.trigger_run_start, t.logged_ts FROM t WHERE NOT EXISTS (SELECT 1 FROM events.queue_events q WHERE q.queue =
  'PENDING_REGIME_REFRESH' AND q.item_type = 'regime-refresh' AND COALESCE(SAFE_CAST(JSON_VALUE(q.payload,
  '$.covered_by_snapshot_ts') AS TIMESTAMP), q.event_ts) >= t.logged_ts)`
  A row means a serviced or refresh-only trigger with no refresh requested or completed since D2 logged it. Zero
  rows is the steady state (it returned zero on 2026-10-19, and in this form on 2026-10-23). A refresh written OR
  completed after the entry already covers it, since M1R scores on post-trigger data either way. That is why the
  test is any `regime-refresh` row at or after `logged_ts`, not a match on the trigger pair. **ONE EXCEPTION, READ
  FROM THE PAYLOAD (review fix, Rev 52, owner directive 2026-10-22, interactive session).** A row M1R writes closing
  an item as covered by a monthly snapshot (its STEP 1b (ii)) counts at the covering snapshot's CUT INSTANT,
  `payload.covered_by_snapshot_ts`, never at its own `event_ts`. Since the round-4 review fix (Rev 52, owner
  directive 2026-10-22, interactive session) M1R writes that field as `LEAST(MAX(event_ts), TIMESTAMP(as_of_date,
  'America/New_York'))`, not the snapshot's last write, because the snapshot saw data only up to the session before
  its `as_of_date`; the `COALESCE` comparison above is unchanged and now compares against that cut. So the close
  answers only triggers logged before the cut, and a trigger logged after it while the item was still open
  (absorbed by the DEDUP below) gets its own refresh on the next run. A row
  without the field (every pending row and every re-score close) counts at its `event_ts`. This substep does not
  re-derive trigger runs, so D2 item 4's ON-OR-AFTER SERVICED tolerance needs no counterpart here: each entry is
  read as logged. W1's CATALYST-GATE input (c) runs this query verbatim. On one or more rows:
  - **DEDUP: AN OPEN ITEM ABSORBS THE REQUEST.** If a `regime-refresh` item is already open — `SELECT item_key FROM
    state.open_queue_detail WHERE queue = 'PENDING_REGIME_REFRESH' AND item_type = 'regime-refresh'` returns any row
    — no-op, and name it in `<note>`. That item's re-score lands after the trigger, and its completion row satisfies
    the test above. Without this check two open items would race for one drain.
  - Otherwise write ONE item covering every returned row: `INSERT INTO events.queue_events` with `queue =
    'PENDING_REGIME_REFRESH'`, `item_key = 'regime-refresh-YYYYMMDD'` (today, America/Denver — one item per day at
    most, so the key is its own idempotency guard), `item_type = 'regime-refresh'`, `status = 'pending'`, `due_date
    = <today>`, `conservative_default = 'no re-score; the standing monthly FUNDAMENTAL_AXIS snapshot remains in
    force'`, and `payload` carrying `resolving_venue = 'M1R'`, `trigger_class = 'measured-trigger'` and the returned
    `measured_trigger` / `trigger_run_start` pairs. The lane is registered (`allowed_map` in whichever
    `bigquery/*.sql` currently defines `state.queue_venue_claim_unwired`, plus `ops/handoff_contracts.yaml`
    `queue_lanes`); do NOT write this row into a lane that is not registered in BOTH, or D3's VENUE-CLAIM HONORING
    CHECK reports it unwired on the very first firing.
  - **THE ITEM TEXT IS STRATEGY-BLIND AND DIRECTION-NEUTRAL — name the condition class, never a strategy.** M1R
    drains this row and M1R is strategy-blind by construction (it re-runs M1a's OUTPUT 2), so the row it reads must
    not leak roster identity: leave the `strategy` column NULL, and keep strategy codes, activation states and
    per-strategy outcomes out of `note` and `payload` alike. The `note` also does not say which way the trigger
    points, for example `note = 'An out-of-cycle refresh trigger fired (named in payload); the standing monthly
    FUNDAMENTAL_AXIS snapshot may be stale. Re-score the 5 axes out of cycle.'` The per-strategy detail belongs in
    D2's entries and in D2a's own `<note>`, neither of which M1R reads.
  - **NO COMPLETED-ITEM COOLDOWN.** The retired limb's 5-trading-day dedup leg stopped a STANDING condition from
    re-queuing every evening. It does not apply here: each row is a new, dated trigger run, already deduplicated by
    the test above and by D2 item 4's SERVICED ONCE PER RUN rule, so a trigger that holds for weeks still produces
    one refresh, and a new trigger run that starts after a completed re-score gets its own.
  - Raise NO alert. Nothing here needs the owner, and the record is the queue row plus D2's entry. M1R drains the
    item with its existing steps unchanged, and D2 item 4's A SCORED OUT-OF-CYCLE `FUNDAMENTAL_AXIS` CHANGE bullet
    brings the re-score into activation the same evening M1R writes it.
  - **THE REFRESH REQUEST HAS NO MACRO-RELEASE TRIGGER, DELIBERATELY — do not add one (ruled 2026-10-19 for the
    retired limb, W5 SPEC-DEFECT NOTICE INTAKE adjudicated by an interactive owner session, closing D2's
    `fundamental_axis_has_no_macro_print_detector`, alert `2622b6cf-0b0b-4d64-97de-1bf5cdd2c67e`; carried over to
    this substep by Rev 52).** A trigger queuing `regime-refresh` on a primary macro release (for example a
    D1-recorded print contradicting a standing `growth_momentum` or `inflation_trend`) was proposed and rejected on
    measurement. For growth and inflation, M1R's Read access scope admits only the substrate M1a's OUTPUT 1 already
    ingested, plus `^VIX` and `BZUSD` (its STEP 2a event sweep and currency closes are not a macro ingest), so the
    re-score such a trigger queued would not be permitted to read the print that queued it: a vacuous refresh that
    still spends a full M1R run from the shared weekly quota. Widening M1R to ingest the print is one of its
    NON-GOALS, and carrying the print inside the queue item would let a non-blind producer choose what evidence the
    blind scorer sees. The mid-month channel for such a release is D1's ANALYSIS — REGIME CHECK into D2's item 4
    (its bullet "A PRIMARY MACRO RELEASE THAT CONTRADICTS A STANDING ..."). The same measurement is why no
    re-risking mirror reads a macro reversal: a refresh cannot lift the growth+policy or inflation+policy
    reconciliation rule before M1a's next monthly ingest (measured 2026-10-19: `events.macro_series` ingest days
    since 2026-08-01 were exactly 2026-08-03, 2026-09-01 and 2026-10-02), so D2 item 4's rail (2r) holds such a
    strategy until then.

### Pass 2 input — q0343, 2026-10-30

_The newly removed second-pass text is retained in this verbatim input; history only._

    `events.cash_flows` double-entry on one flow_date tagged `source='regime_capital_sweep'` (one negative
    row for the swept strategy, positive rows per recipient) and `CALL ops.sp_log_decision(...,
    entry_type='capital-allocation', ...)` per §16 Logging, with `fields` JSON carrying
    `is_default_equal=false`, `conviction='MECHANICAL'`, `conviction_pct=null`,
    `weight_source='state.sweep_recipient_weights'`, `winner_code`/`runner_up_code` = the highest and
    second-highest `sweep_share`, a `rationale` quoting each recipient's `capacity_ratio` and
    `deployed_days_180`, and a `theater_check` stating plainly that no judgment was exercised — this is
    arithmetic over deployment history, not an AI call. Each recipient's `note` should name its
    `sweep_share`, `band_multiplier`, `capacity_ratio` and `deployed_days_180`, the source view, and any
    penny adjustment.
  - RESTORE rows (a debtor strategy back to capital-enabled, per `state.regime_capital_debt`): MECHANICAL, no
    AI call — write the `source='regime_capital_restore'` double-entry using the view's pro-rata donor
    amounts; log a one-line `events.decision_log` note (`trigger='regime_enable'` context).
  - ONE MOVEMENT PER READ: after writing any sweep or restore, re-`SELECT` the pending view before acting
    again — at most one movement's rows
    between reads.
- NOMADIC STRATEGY CAPITAL — SWEEP half (canonical rails
  Operating_Protocols.md §16 NOMADIC STRATEGY CAPITAL; schema `bigquery/167_nomadic_capital.sql` as fixed by
  `bigquery/168_nomadic_capital_fixes.sql`). A strategy declared ≤1 trade/month is classified NOMADIC
  **permanently** (`state.strategy_nomadic_status.is_nomadic`, sourced from
  `state.strategy_declared_frequency`) and holds no exclusive standing capital. Runs immediately after
  REGIME-CAPITAL SYNC above, same Step 0 position. `SELECT * FROM state.nomadic_capital_sync_pending`.
  **HEAL FIRST, FROM THIS SAME READ, BEFORE YOU BRANCH.** `nomadic_sweep_blocked` is registered `latching = FALSE` with a `resolve_rule`. **D2a is the resolver**: D2a is the only routine that reads this view, so it is the only routine that can ever
  observe the heal. If **no row has `blocked_no_recipient = TRUE`** and an unresolved `nomadic_sweep_blocked` alert
  exists → `UPDATE ops.alerts SET resolved=TRUE, resolved_ts=CURRENT_TIMESTAMP(), resolved_note='condition healed:
  state.nomadic_capital_sync_pending no longer emits a blocked_no_recipient row — <name what actually cleared it: a
  capital-enabled non-nomadic strategy exists again, or the nomadic strategy fell below the $25 floor>' WHERE
  category='nomadic_sweep_blocked' AND NOT resolved`. **The same "Empty branch" trap applies verbatim and is why
  this sits above the branch:** this view's `blocked` CTE (`WHERE NOT EXISTS (SELECT 1 FROM weights)`) and its
  `allocated` CTE (`CROSS JOIN weights`) are complementary over the same sweeping population, so the heal is a flag
  flip, not a drop to zero rows. Read the FLAG, never the row count, and read it once.
  Empty (the steady state) → no-op, nothing to log — apart from the heal above, which is evaluated either way.
  Non-empty:
  - `control_enabled = FALSE` (the `ops.capital_nomad_control` kill-switch — separate from
    `ops.capital_control` above) → log a one-line `events.decision_log` note recording what WOULD have
    moved, and move nothing.
  - **`blocked_no_recipient = TRUE`** (capital to sweep, but every capital-enabled strategy is itself
    nomadic, so there is nowhere legal to put it) → move nothing and `CALL ops.sp_raise_alert_once('warning',
    'D2a','nomadic_sweep_blocked', <the EXACT STABLE message below>, <JSON payload>)`. This row exists
    specifically so a blocked sweep is distinguishable from the healthy empty-view steady state; do NOT treat
    it as a no-op.
    **PIN THE MESSAGE.** `sp_raise_alert_once` dedups on exact `(category, message)`; put varying figures only in payload, or persistence re-mints daily alerts. Use verbatim, with no interpolation:
    `'Nomadic sweep blocked: a nomadic strategy holds sweepable idle cash, but every capital-enabled strategy
    is itself nomadic, so there is no eligible recipient and nothing moved. Strategies and amounts in
    payload.'` Deliberately DISTINCT wording from the regime sweep message, for the reason `bigquery/223`
    gives for splitting the restore category out: two blocked conditions sharing one message would let an
    already-open row of the other kind silently swallow this one. The varying figures — `strategy`, `amount`,
    the capital-enabled set — go in the PAYLOAD, never the message.
  - SWEEP rows only — this view never carries a BORROW row; borrowing is on-demand at order-craft time,
    not a daily standing check (Operating_Protocols.md §16 explains why). Write the atomic $0-sum
    `events.cash_flows` double-entry (per the `flow_type` sign rule pinned at the regime-sweep bullet above: `'WITHDRAWAL'` on the negative leg, `'DEPOSIT'` on the positive one) on one flow_date tagged `source='nomadic_capital_sweep'`: one negative
    row for the nomadic strategy at `amount`, one positive row per counterparty at its `counterparty_amount`.
    **Use the view's `counterparty_amount` verbatim and do NOT re-round it** — the view already applies the
    last-row-absorbs-the-residual rule, so `SUM(counterparty_amount)` equals `amount` to the cent by
    construction; re-rounding would reintroduce the very drift that rule removes. Then `CALL
    ops.sp_log_decision(..., entry_type='capital-allocation', ...)` per §16 Logging with `fields` JSON
    carrying `trigger='nomadic_capital_sweep'`, `conviction='MECHANICAL'`, `conviction_pct=null`, and a
    `rationale` naming the swept strategy's `declared_frequency_text`.
  - `amount` is the strategy's `sweepable_amount`, which is already NET of
    `state.open_orders.reserved_cash` — cash a pending staged BUY needs is never swept (bigquery/168 FIX 2,
    the same "never sweep cash a pending buy needs" rule §13 applies to the park sweep). A ≥$25 de-minimis
    movement floor applies (same figure as the regime sweep); below it the balance simply waits.
  - ONE MOVEMENT PER READ, same discipline as REGIME-CAPITAL SYNC above.
- NOMADIC STRATEGY CAPITAL — BORROW-CAPACITY WATCH (Operating_Protocols.md §16 NOMADIC STRATEGY CAPITAL; `bigquery/246_nomadic_borrow_blocked_alert.sql`).
  A standing, daily EARLY-WARNING monitor over the on-demand nomadic-BORROW mechanism — it does not itself
  borrow anything and does not touch the crafting-time NOMADIC-BORROW CHECK
  (`analytics.fn_nomadic_capital_restore_plan`), which remains on-demand at order-craft time only, exactly as
  the SWEEP-half bullet above states ("this view never carries a BORROW row; borrowing is on-demand at
  order-craft time, not a daily standing check"). This substep does not change that — it answers a different
  question daily, before any craft is attempted: does a currently-nomadic, capital-enabled strategy have ANY
  funded donor to draw from right now, so a genuine zero-donor state is visible in advance rather than only
  discoverable the moment a routine tries and fails to borrow. Runs immediately after NOMADIC STRATEGY CAPITAL
  — SWEEP half above, same Step 0 position. `SELECT * FROM state.nomadic_borrow_capacity_watch` (one row per
  currently-nomadic + capital-enabled strategy; `donor_capacity_total` sums every OTHER capital-enabled,
  non-nomadic strategy's available funds; `borrow_blocked = TRUE` when that total is `<= 0`, i.e. every other
  capital-enabled strategy is itself at $0 or capital-disabled).
  **HEAL FIRST, FROM THIS SAME READ, BEFORE YOU BRANCH (same discipline as the SWEEP-half heal immediately
  above, for the same reason: `nomadic_borrow_blocked` is registered `latching = FALSE` with a `resolve_rule`
  naming no resolver but D2a, since D2a is the only routine that reads this view).** If **no row has
  `borrow_blocked = TRUE`** and an unresolved `nomadic_borrow_blocked` alert exists → `UPDATE ops.alerts SET
  resolved=TRUE, resolved_ts=CURRENT_TIMESTAMP(), resolved_note='condition healed:
  state.nomadic_borrow_capacity_watch no longer reports any borrow_blocked=TRUE row — <name what actually
  cleared it: a capital-enabled non-nomadic strategy regained funded capacity, a router re-enable, or a roster
  change>' WHERE category='nomadic_borrow_blocked' AND NOT resolved`. Read the FLAG (whether ANY row is
  `borrow_blocked = TRUE`), never the row count, same "Empty branch" trap as the SWEEP-half heal: a genuinely
  healed state does not necessarily return zero rows, it returns rows with the flag flipped FALSE.
  Empty or all `borrow_blocked = FALSE` (the steady state) → no-op, nothing to log — apart from the heal
  above, which is evaluated either way.
  - Any row with **`borrow_blocked = TRUE`** → `CALL ops.sp_raise_alert_once('warning','D2a',
    'nomadic_borrow_blocked', <the EXACT STABLE message below>, <JSON payload>)` — ONE call per run,
    aggregating every `borrow_blocked = TRUE` row into the payload, never one call per row:
    `sp_raise_alert_once` dedups on `(category, message)` by exact string equality and this message is
    pinned with no interpolation, so a second call this run would simply be swallowed by the first and
    silently drop every strategy after it from the payload. This row exists so a blocked borrow-capacity
    state is distinguishable from the healthy steady state; do NOT treat it as a no-op.
    **PIN THE MESSAGE, same rule as every sibling in this substep.** Use verbatim, with no interpolation:
    `'Nomadic borrow-capacity watch: a nomadic strategy currently has zero funded donor capacity to draw an
    on-demand capital borrow from, because every other capital-enabled strategy is itself at $0 available
    funds or capital-disabled. Strategies and capacity in payload.'` Deliberately DISTINCT wording from
    `nomadic_sweep_blocked` and both regime-blocked messages, for the reason `bigquery/223` gives for
    splitting `regime_restore_blocked` out: a shared message would let an already-open row of a different
    category silently swallow this one. The varying figures — `strategy`, `donor_capacity_total`,
    `donor_count` per blocked strategy — go in the PAYLOAD, never the message.
  - WARNING, never critical, same reason as `nomadic_sweep_blocked`'s own registration (`bigquery/168`):
    a critical enters `blocking_criticals` (`bigquery/176_decouple_embedding_health_from_trading_gate.sql` —
    NOT `bigquery/107`, which carries a live `SUPERSEDED LIVE (2026-08-17)` banner pointing at 176) and halts
    ALL order staging fleet-wide. A capacity WATCH must never halt trading: no capital has moved, none is at
    risk, and no borrow has even been attempted — this is advance notice that a future on-demand borrow would
    currently fail, nothing more.
  - This bullet raises a WATCH only — it never moves money and never gates a craft. The actual borrow event,
    when a nomadic strategy's order notional exceeds its `available_funds`, is still decided solely at
    craft-time by the existing NOMADIC-BORROW CHECK against `analytics.fn_nomadic_capital_restore_plan`'s
    live result, not by this daily view's reading (which can go stale intraday as capital moves).
- RE-RISKING LIMB EVALUATION — **RETIRED (Rev 52).** Rev 52 made
  Strategy.md's out-of-cycle refresh rule disjunctive in BOTH directions (§ "Pre-mortem: Regime router" → §6
  Misclassification scenarios, scenarios 1 and 3): every de-risking trigger has a mirror re-risking trigger, and ANY
  ONE of them makes the refresh permitted and required, so the Rev 46 / Rev 48 limb's conjunction (a 15-trading-day
  DO-NOT-ACTIVATE dwell, a measured reversal of the binding override axis and a benign technical plane, all at once)
  is gone. D2a no longer reads `state.rerisking_limb_status` (`bigquery/224`, retired by Rev 52 and left defined
  live under an appended retirement marker naming `bigquery/263`, so apply-in-order replay and live parity are
  unaffected) and no longer raises `rerisking_limb_fired`; M1R STEP 4 still resolves any legacy open row of that
  category by `alert_id`. The limb's role passes to D2 item 4's mirror triggers (its MEASURED OUT-OF-CYCLE REFRESH
  TRIGGER bullet; `shock_price_leg_exit`, read from `state.shock_price_leg_status`, `bigquery/263`, is the measured
  successor of the limb's Brent price leg) plus the REFRESH REQUEST below, which inherits the limb's lane, INSERT
  shape and strategy-blind item text. Of the limb's two scoping rulings, the no-macro-release ruling now binds the
  REFRESH REQUEST below, and the acute-only wiring of leg (b) lapsed with the leg.
- REFRESH REQUEST (Strategy.md § "Pre-mortem: Regime router" → §6 Misclassification scenarios, scenarios 1 and 3: refresh required on ANY ONE trigger in either direction). **MECHANICAL, no AI call; D2a stays the SOLE writer of `PENDING_REGIME_REFRESH`.**
  It is Step 0's last substep and runs after the two capital substeps above; its position relative to them is not
  load-bearing, because it moves nothing: it never scores a regime, never reads roster membership or activation
  intent, and may write ONE queue row. D2 item 4 detects every trigger the same evening it sees it: its MEASURED
  OUT-OF-CYCLE REFRESH TRIGGER bullet (the technical-plane triggers `vix_regime_high`, `spy_trend_down`,
  `breadth_mom_drop_gt10` and `vix_drift_gt5_ending_normal` and their mirrors `vix_regime_exit_high`,
  `spy_trend_exit_down`, `breadth_mom_rise_gt10` and `vix_drift_down_gt5`, plus the shock price-leg pair
  `shock_price_leg_entry` / `shock_price_leg_exit`), and a D1 flag on a qualifying geopolitical event
  (`geopolitical_qualifying_event`) or a qualifying resolution event (`geopolitical_qualifying_resolution`). It
  services a technical-plane trigger with a same-evening review, and gives each of the four shock-axis triggers (the
  price-leg pair and the two D1 flags) a refresh-only entry with no review (Rev 52). Either way it logs one `router-review` entry per trigger run carrying
  `fields.measured_trigger` and `fields.trigger_run_start`. Neither the review nor the refresh-only entry is the
  refresh, because Strategy.md's scenario 3 ("REFRESH, never a flip", kept for both directions by Rev 52) defines a
  refresh as re-running the M1a/M1b machinery and authorises no daily routine to score an axis. This substep turns
  each such entry, whichever direction its trigger points and whether or not it was reviewed, into the blind
  re-score. Read ONLY the two trigger fields, never the entry's per-strategy outcome:
  `WITH t AS (SELECT JSON_VALUE(fields, '$.measured_trigger') AS measured_trigger, JSON_VALUE(fields,
  '$.trigger_run_start') AS trigger_run_start, MIN(event_ts) AS logged_ts FROM events.decision_log WHERE
  entry_type = 'router-review' AND JSON_VALUE(fields, '$.measured_trigger') IS NOT NULL AND entry_date >=
  DATE_SUB(CURRENT_DATE('America/Denver'), INTERVAL 14 DAY) GROUP BY 1, 2) SELECT t.measured_trigger,
  t.trigger_run_start, t.logged_ts FROM t WHERE NOT EXISTS (SELECT 1 FROM events.queue_events q WHERE q.queue =
  'PENDING_REGIME_REFRESH' AND q.item_type = 'regime-refresh' AND COALESCE(SAFE_CAST(JSON_VALUE(q.payload,
  '$.covered_by_snapshot_ts') AS TIMESTAMP), q.event_ts) >= t.logged_ts)`
  A row means a serviced or refresh-only trigger with no refresh requested or completed since D2 logged it. Zero
  rows is the steady state. A refresh written OR
  completed after the entry already covers it, since M1R scores on post-trigger data either way. That is why the
  test is any `regime-refresh` row at or after `logged_ts`, not a match on the trigger pair. **ONE EXCEPTION, READ
  FROM THE PAYLOAD (Rev 52).** A row M1R writes closing
  an item as covered by a monthly snapshot (its STEP 1b (ii)) counts at the covering snapshot's CUT INSTANT,
  `payload.covered_by_snapshot_ts`, never at its own `event_ts`. M1R writes that field as `LEAST(MAX(event_ts), TIMESTAMP(as_of_date,
  'America/New_York'))`, not the snapshot's last write, because the snapshot saw data only up to the session before
  its `as_of_date`; the `COALESCE` comparison above is unchanged and now compares against that cut. So the close
  answers only triggers logged before the cut, and a trigger logged after it while the item was still open
  (absorbed by the DEDUP below) gets its own refresh on the next run. A row
  without the field (every pending row and every re-score close) counts at its `event_ts`. This substep does not
  re-derive trigger runs, so D2 item 4's ON-OR-AFTER SERVICED tolerance needs no counterpart here: each entry is
  read as logged. W1's CATALYST-GATE input (c) runs this query verbatim. On one or more rows:
  - **DEDUP: AN OPEN ITEM ABSORBS THE REQUEST.** If a `regime-refresh` item is already open — `SELECT item_key FROM
    state.open_queue_detail WHERE queue = 'PENDING_REGIME_REFRESH' AND item_type = 'regime-refresh'` returns any row
    — no-op, and name it in `<note>`. That item's re-score lands after the trigger, and its completion row satisfies
    the test above. Without this check two open items would race for one drain.
  - Otherwise write ONE item covering every returned row: `INSERT INTO events.queue_events` with `queue =
    'PENDING_REGIME_REFRESH'`, `item_key = 'regime-refresh-YYYYMMDD'` (today, America/Denver — one item per day at
    most, so the key is its own idempotency guard), `item_type = 'regime-refresh'`, `status = 'pending'`, `due_date
    = <today>`, `conservative_default = 'no re-score; the standing monthly FUNDAMENTAL_AXIS snapshot remains in
    force'`, and `payload` carrying `resolving_venue = 'M1R'`, `trigger_class = 'measured-trigger'` and the returned
    `measured_trigger` / `trigger_run_start` pairs. The lane is registered (`allowed_map` in whichever
    `bigquery/*.sql` currently defines `state.queue_venue_claim_unwired`, plus `ops/handoff_contracts.yaml`
    `queue_lanes`); do NOT write this row into a lane that is not registered in BOTH, or D3's VENUE-CLAIM HONORING
    CHECK reports it unwired on the very first firing.
  - **THE ITEM TEXT IS STRATEGY-BLIND AND DIRECTION-NEUTRAL — name the condition class, never a strategy.** M1R
    drains this row and M1R is strategy-blind by construction (it re-runs M1a's OUTPUT 2), so the row it reads must
    not leak roster identity: leave the `strategy` column NULL, and keep strategy codes, activation states and
    per-strategy outcomes out of `note` and `payload` alike. The `note` also does not say which way the trigger
    points, for example `note = 'An out-of-cycle refresh trigger fired (named in payload); the standing monthly
    FUNDAMENTAL_AXIS snapshot may be stale. Re-score the 5 axes out of cycle.'` The per-strategy detail belongs in
    D2's entries and in D2a's own `<note>`, neither of which M1R reads.
  - **NO COMPLETED-ITEM COOLDOWN.** The retired limb's 5-trading-day dedup leg stopped a STANDING condition from
    re-queuing every evening. It does not apply here: each row is a new, dated trigger run, already deduplicated by
    the test above and by D2 item 4's SERVICED ONCE PER RUN rule, so a trigger that holds for weeks still produces
    one refresh, and a new trigger run that starts after a completed re-score gets its own.
  - Raise NO alert. Nothing here needs the owner, and the record is the queue row plus D2's entry. M1R drains the
    item with its existing steps unchanged, and D2 item 4's A SCORED OUT-OF-CYCLE `FUNDAMENTAL_AXIS` CHANGE bullet
    brings the re-score into activation the same evening M1R writes it.
  - **THE REFRESH REQUEST HAS NO MACRO-RELEASE TRIGGER, DELIBERATELY — do not add one.** A trigger queuing `regime-refresh` on a primary macro release (for example a
    D1-recorded print contradicting a standing `growth_momentum` or `inflation_trend`) was proposed and rejected on
    measurement. For growth and inflation, M1R's Read access scope admits only the substrate M1a's OUTPUT 1 already
    ingested, plus `^VIX` and `BZUSD` (its STEP 2a event sweep and currency closes are not a macro ingest), so the
    re-score such a trigger queued would not be permitted to read the print that queued it: a vacuous refresh that
    still spends a full M1R run from the shared weekly quota. Widening M1R to ingest the print is one of its
    NON-GOALS, and carrying the print inside the queue item would let a non-blind producer choose what evidence the
    blind scorer sees. The mid-month channel for such a release is D1's ANALYSIS — REGIME CHECK into D2's item 4
    (its bullet "A PRIMARY MACRO RELEASE THAT CONTRADICTS A STANDING ..."). The same measurement is why no
    re-risking mirror reads a macro reversal: a refresh cannot lift the growth+policy or inflation+policy
    reconciliation rule before M1a's next monthly ingest, so D2 item 4's rail (2r) holds such a
    strategy until then. *(Pre-2026-10-30 history and evidence for this rule: `ops/plan_history/D2a.md` § H-D2a-05.)*

## H-D2a-06 — snapshot_date = state.trading_day_today.last_trading_day (bug fix, 20260808 — no longer the literal

_Moved verbatim from `Claude_Task_Plan.md` (D2a, was line 2240) on 2026-10-30. Historical record only; the binding rule is the condensed text in the plan._

- **`snapshot_date` = `state.trading_day_today.last_trading_day`** (bug fix, 2026-08-08 — no longer the literal
  `today` this bullet used before the daily-tier fleet's Fri/Sat schedule change). On a trading day
  `last_trading_day` already equals `today` (`bigquery/09_market_calendar.sql`'s `state.trading_day_today`
  definition self-includes today whenever `is_trading_day`), so this is a single assignment, not an IF branch —
  it reduces to the old `today` behavior on every day D2a used to run, and only diverges on the days that are
  new: once D2a stops firing Friday and Saturday, its next run (Sunday) would otherwise stamp a Sunday-dated
  row while Friday, the actual trading day, got NO row, ever — `ops.account_snapshot` has no loop and no
  backfill (see `bigquery/153_account_snapshot_gap_watch.sql`'s header for the two already-observed permanent
  gap days, 2026-07-23/24, this exact failure mode produced) — and `state.account_snapshot_gap` (bigquery/153,
  live) would then flag that permanent hole EVERY week by design, forever, not just once.
- the `get_account_summary`
  fields; **the FULL park book market value, summed ACROSS BOTH SLEEVES, from `get_account_positions`**
  (contract_ids SGOV 424099317 and VOO 136155102) written into the `sgov_market_value` column
  (column name kept as-is post-2026-07-15 cutover — it holds the whole park book, not literally SGOV;
  renaming it is a separate, lower-priority schema cleanup, not required for correctness);
  and the cps-array TWRs. **TWO-SLEEVE CORRECTION (added 2026-09-27, W5 SPEC-DEFECT NOTICE INTAKE, closing
  D2a's `snapshot_park_value_ambiguous_under_graded_book`, alert `2cdee4b4-41ba-4886-b1d6-0a2f8aa07299`).**
  The prior "CURRENT park vehicle's market value" wording was unambiguous only while the park was
  single-vehicle; since graded allocation went live 2026-09-04 the park is a TWO-SLEEVE book and
  `state.park_policy_current` names only the MAJORITY sleeve — it is a majority-sleeve LABEL, never the
  value source, and a literal single-vehicle reading writes one sleeve and silently drops the other.
  MEASURED 2026-09-09: majority sleeve (VOO) $11,290.72, minority sleeve (SGOV) $3,760.08, full two-sleeve
  book $15,050.80 (target minority weight 25%) — a majority-sleeve-only write would have understated the
  park by 24.98%.
- **`source`** (bug fix, 2026-08-08 — this column already exists, `source STRING DEFAULT 'D2-connector'`,
  `bigquery/14_weekly_report.sql:107`; NO schema change). **Write `source = 'D2a-connector'` EXPLICITLY for a
  genuine same-day read (`snapshot_date = today`) — do NOT fall through to the column DEFAULT (wording
  corrected 2026-08-20, D2a; the prior text here said "leave it at that default" and that instruction has
  been wrong since the D2/D2a cutover).** MEASURED on the live table that day: `ops.account_snapshot` holds
  25 `'D2a-connector'` rows spanning 2026-07-03 → 2026-08-19 (every row for the last ~7 weeks, and the only
  value in current use), against 18 legacy `'D2-connector'` rows ending 2026-08-06 and 7 bare `'connector'`
  rows ending 2026-08-05. So the DEFAULT this bullet used to point at is BOTH stale — `'D2-connector'` names
  D2, which has not written this table since the 2026-07-09 cutover made D2a its sole writer — and contrary
  to what 25 consecutive sessions actually did. A future session following the old wording literally would
  have silently reintroduced the pre-cutover token and broken the run of rows, for no benefit: the
  carried-vs-same-day distinction this field exists to carry is served by the `-carried` suffix below, not by
  which of the two same-day tokens is used. Naming the writer correctly also keeps the same-day and carried
  tokens on one `D2a-` prefix, so a single `LIKE 'D2a-connector%'` matches every row this routine has written.
  **When `snapshot_date` is back-dated (today is NOT itself a trading day), set
  `source = 'D2a-connector-carried'` instead** — a distinct, greppable token so a later reader of
  `ops.account_snapshot` (or a session diagnosing a `book_drawdown_watch`/TWR discrepancy) can tell a
  weekend-carried read apart from a measurement genuinely taken as of that trading day's own close, without
  cross-referencing `ops.run_log` timestamps to reconstruct which case produced the row.
- **PRE-OPEN SLOT LIMB — a D2a fire BEFORE the session it would otherwise stamp (added 2026-10-11, W5 SPEC-DEFECT NOTICE INTAKE, closing D2a's `d2a_pre_open_slot_unspecified`, alert `532f53b2-5504-43e4-909f-0cc072b79870`).** The `last_trading_day` assignment above is sound only AFTER today's close; the regular slot is post-close (`ops/cadence.yaml` D2a `cron_utc "40 22 * * 0,1,2,3,4"`, 16:40 MT) but a catch-up fire after an outage can land pre-open (measured: 2026-09-22 03:46 MT, ~3.7h before the open). **Predicate:** `state.trading_day_today.is_trading_day` AND the current `America/New_York` time is before that session's 16:00 close. When it holds, pin all three dates to the **last COMPLETED session** (the trading day before today), not to `last_trading_day`: (1) `snapshot_date` = that completed session, `source = 'D2a-connector-carried'` (the carried token's semantics — a read taken outside that session's close, TWR columns measured at the query instant — describe this case even though its stated trigger says "today is NOT itself a trading day"); (2) MARKS — ingest that completed session only, write NO row for today and raise NO `mark_gap` (a missing bar for a close that does not exist yet is not a gap, and the FMP-fallback trigger "no bar OR a bar older than `last_trading_day`" is read against the completed session here, not against today); a vendor bar already dated today (e.g. BZUSD) is NOT ingested — that is the `signal_mark_captured_pre_close` defect; (3) `technical_signal` `as_of_date` = that completed session. Writing the completed session's snapshot leaves the one-row-per-`snapshot_date` idempotency skip free for the same evening's genuine post-close read. The SAME-DAY DOUBLE-RUN GUARD needs no change (its noon-MT threshold excludes a ~04:00 MT completion). Do NOT fix this by moving or deleting the slot: the off-cadence fire is what recovered the missed day.
- **Two caveats a carried read does NOT paper over — record them, do not treat the row as equivalent to a
  same-day read:**
  (i) **The TWR columns measure the wrong window; NAV/cash do not.** `get_pa_performance_all_periods`'s period
  TWRs are computed relative to the QUERY INSTANT, not the stamped `snapshot_date` — a Sunday read's `twr_1d`
  is the return over the trailing ~24h ending Sunday (mostly a closed weekend), not the return over Friday's
  actual trading session a Friday-evening read would have measured. `nav`/`total_cash`/`buying_power`/
  `available_funds`/`gross_position_value`/`sgov_market_value` carry over CLEANLY (the book does not trade over
  a weekend it is parked through, so Friday's close IS what a Sunday read sees for those fields) — the TWR
  columns (`twr_1d`, `twr_7d`, `twr_mtd`, `twr_ytd`, `twr_1y`) do not, and must never be read as if they were
  measured as of `snapshot_date`'s close.
  (ii) **Weekend cash movement is possible even though the book does not trade.** Interest accrual or an
  ex-/pay-date on a held or park vehicle could in principle post between Friday's close and the Sunday read,
  moving `total_cash`/`available_funds` by a small amount that neither Friday's own numbers nor caveat (i)
  above would explain — a real, if usually small, source of drift between what a genuine Friday-evening run
  would have written and what the Sunday carry-forward actually captures.
- **A THIRD caveat that is NOT about carrying — it applies to EVERY row this step writes, a genuine
  same-day read included (added 2026-08-30, closing D2a's INFO `snapshot_marking_basis` alert):**
  (iii) **`nav` is marked AFTER HOURS; the deployed book is marked at the REGULAR-SESSION close — the two
  disagree on a big extended-session day and NEITHER is wrong.** D2a's slot is 16:40 MT / 18:40 ET
  (`ops/cadence.yaml` D2a `expected_trigger.cron_utc: "40 22 * * 0,1,2,3,4"`), inside the 16:00-20:00 ET
  extended session, so `get_account_summary`'s net-liquidation — hence `nav`, `gross_position_value` and
  `sgov_market_value` — carries AFTER-HOURS prints, while `events.daily_marks.close` (ingested by this
  routine's own PER-STRATEGY PERFORMANCE MAINTENANCE step below, and read through
  `state.daily_marks_curated` by BOTH `analytics.strategy_daily_returns` → `perf.strategy_daily` and
  `analytics.strategy_nav`'s `latest_close`) is the IBKR REGULAR-SESSION daily bar — the same
  `outside_rth=false` basis Operating_Protocols.md §19 PRICE BASIS pins for D1's close-to-close screens.
  **MEASURED 2026-08-26:** `nav` moved +$104.21 day-over-day (15961.47 → 16065.68) while the SAME book
  repriced at regular-session closes moved about +$4 — CRM printed 231.37 after hours on an earnings
  release against the 205.62 regular-session close this routine actually ingested (session high 206.44),
  and the VOO park printed 708.51 against its ingested 704.20 close, on a flat tape (SPY 765.91 → 766.08,
  +0.02%). Substantially the whole recorded move was the extended session. **This is STRUCTURAL, not a
  defect and not new** — D2a has run in a post-close evening slot since the 2026-07-09 cutover (16:20 MT
  then, 16:40 MT since the 2026-08-01 re-spacing), so EVERY same-day row on `ops.account_snapshot` carries
  this basis and day-over-day `nav` comparisons stay apples-to-apples. What it forbids is the CROSS-BASIS
  read: **do NOT diff a single day's `ops.account_snapshot.nav` against `analytics.strategy_nav` /
  `perf.strategy_daily` / any other `state.daily_marks_curated`-derived book value and treat the residual
  as a reconciliation break, a mark gap, or a drift finding.** On an earnings night that residual IS the
  extended session. Attribute a same-day gap to the after-hours tape FIRST — re-read that day's bars with
  `get_price_history` at `outside_rth=false` — before opening any investigation, and never "correct"
  either figure toward the other: they answer different questions, and both are per spec.
- One row per `snapshot_date` (latest ingest wins via `state.account_latest`; **skip if a row for the resolved
  `snapshot_date` already exists** — the same idempotency as before, now keyed on the possibly back-dated date,
  not literally today's date). Wrap best-effort so a
snapshot failure never aborts D2a — it feeds a report, not trading. (`bigquery/14_weekly_report.sql`.)

## H-D2a-07 — PERSTRATEGY PERFORMANCE MAINTENANCE (deployedTWR engine; run after fill reconciliation, daily, while connector

_Moved verbatim from `Claude_Task_Plan.md` (D2a, was line 2329) on 2026-10-30. Historical record only; the binding rule is the condensed text in the plan._

PER-STRATEGY PERFORMANCE MAINTENANCE (deployed-TWR engine; run after fill reconciliation, daily, while connector
marks are fresh; method in bigquery/03_twr_engine.sql + Operating_Protocols.md §14). The authoritative engine is
the BigQuery value-weighted daily TOTAL-return TWR (`events.daily_marks` → `analytics.strategy_daily_returns` +
`analytics.sgov_daily_return` → `perf.strategy_daily` → `perf.kill_flags`). Requires the BigQuery MCP connector.
1. **Ingest today's marks (TOTAL-return source).** For each held ticker + SGOV + SPY + VOO (self-improvement
   audit ITEM 10, 2026-07-11 — SPY is tracked UNCONDITIONALLY, regardless of holdings, exactly like SGOV: it is
   the market-beta benchmark `analytics.strategy_beta` regresses every strategy's daily deployed return against,
   `bigquery/39_beta_adjusted_alpha.sql`; VOO added 2026-07-13, owner directive — the weekly email's second,
   purely informational benchmark, `bigquery/46_weekly_benchmarks.sql` — tracked unconditionally the same way),
   pull `get_price_history(
   include_corporate_actions: true)` and `INSERT INTO events.daily_marks (mark_date, ticker, close, dividend,
   split_ratio, source)`: today's close, any ex-div cash dividend/share, split_ratio (split-adjusted at ingest),
   `source='connector'`. Idempotent on (mark_date, ticker). **Missed-day backfill (owner directive 2026-07-25
   CATCH-UP EVIDENCE WINDOW — see Observability § above; same call, wider date range):** if
   `missed_trading_days >= 1` since D2a's own last successful completion (D2A MISSED-TRADING-DAY COUNT, Step 0
   connector-sanity band above — the corrected trading-day-count predicate against `state.market_calendar`,
   not the ambiguous "more than 1 trading day" reading of `state.routine_catchup_window.window_days`'s raw
   CALENDAR-day figure that used to gate this bullet), pull `get_price_history` over the full missed-trading-day
   range (not just today) and
   `INSERT` one row per (ticker, missed trading day) exactly as above — idempotent on (mark_date, ticker), so a
   backfill re-run is safe; this closes the gap SL3's own catch-up signal/simulated-fill generation depends on
   (see SL3), and is what lets a Sunday run recover Friday's marks once the daily-tier fleet stops firing
   Friday/Saturday. **FMP fallback (2026-06-28 #12):** if `get_price_history`
   returns no bar — or a bar older than `state.trading_day_today.last_trading_day` — fall back to the FMP connector
   (`mcp__FMP__quote` for the close; `mcp__FMP__chart` to confirm the dated bar / ex-div) and INSERT with
   `source='FMP-fallback'` (best-effort; prefer IBKR when present). On a systematic per-name IBKR gap, `CALL
   ops.sp_raise_alert('warning','D2a','mark_gap', ...)`. **Completeness check:** after ingest, assert (a) every
   OPEN position (`state.current_positions`, ex-SGOV) AND (b) each of the unconditional benchmark tickers
   (SGOV, SPY, VOO — added 2026-07-13, so a silent VOO/SPY ingest stop is caught the same way a held-position
   gap is, instead of going unnoticed the way SPY's history did before this date) has a `state.daily_marks_curated`
   row for EVERY trading day in the window back to D2a's own last successful completion (not only
   `last_trading_day` — owner directive 2026-07-25 CATCH-UP EVIDENCE WINDOW); on a gap neither source filled, carry the prior mark forward explicitly (mirroring
   the SGOV forward-fill) AND `CALL ops.sp_raise_alert('warning','D2a','mark_gap', ...)`. Standing CI detector:
   dbt test `dbt/tests/assert_open_positions_have_marks.sql` (held positions only — the benchmark-ticker leg of
   this check is D2a-side only, not yet mirrored into a dbt test).
1b. **Ingest today's option marks (self-improvement audit ITEM 12, 2026-07-11 — `bigquery/40_options_marks.sql`).**
   For each held position whose ticker is an OCC option symbol (`analytics.fn_is_occ_option_symbol`; today only
   possible for Strategy C, which is roster-ADOPTED with an active router path — not hypothetical), pull the
   contract's daily premium via `mcp__Interactive_Brokers_IBKR__get_option_data`, falling back to an FMP options
   quote if IBKR returns nothing, and `INSERT INTO events.option_marks (mark_date, occ_symbol, underlying, strike,
   expiry, option_right, premium_close, multiplier, source)`: `occ_symbol` = the exact ticker string on the fill
   (`events.trade_fills.ticker` — the join key `analytics.strategy_daily_returns` uses), `multiplier=100` (US
   equity options; c_options_math.py's own convention) unless the contract's actual multiplier differs (record it
   if so), `source='connector'` or `'FMP-fallback'`. Idempotent on (mark_date, occ_symbol). This is a SEPARATE
   ingest branch from step 1 above (equity/SGOV/SPY/VOO) — option contracts are never pulled via `get_price_history`.
   After ingest, read `state.option_mark_anomalies`: any row there means a held option position is STILL missing
   its mark for today — `CALL ops.sp_raise_alert('warning','D2a','option_mark_missing', ...)`. Do NOT
   fabricate/carry-forward an option premium the way step 1 forward-fills an equity gap (option premiums move too
   fast near expiry for a stale carry-forward to be a safe substitute) — `ops.sp_recompute_engine()` (step 2 below)
   already excludes an unmarked option-day from the TWR chain rather than mis-valuing it.
   **MISSED-DAY BACKFILL (bug fix, 2026-08-08 — supersedes the "FRIDAY-PREMIUM CLIFF — DOCUMENTED, NOT FIXED"
   posture this note carried earlier the same day; modelled on step 1's `daily_marks` missed-day backfill
   above).** The premise above (SPOT-only, no historical form) was correct for `get_option_data`/its FMP
   fallback but incomplete: `get_price_history` DOES return historical option bars — it only rejects
   `step="ONE_DAY"`. Verified live against two independent contracts (not a replay of a single probe): SPY
   SEP 18 '26 775 Call (contract_id 793211359) and, independently, QQQ OCT 16 '26 725 Put (contract_id
   867926161). Both reject `step="ONE_DAY"` with `{"error":"No historical market data available"}`; both
   return full dated hourly OHLCV on `step="ONE_HOUR"`, `period="ONE_WEEK"`. Both cross-validate exactly
   against a same-moment spot read — SPY's last bar closed 13.80 against `get_price_snapshot`'s `last.price`
   of 13.80; QQQ's last bar closed 25.76 against a snapshot of 25.76 — confirming the hourly path reproduces
   the connector's own last-traded price, not a model, and both contracts' daily bar grids run 13:30Z-20:00Z
   each session day (9:30am-4:00pm America/New_York under EDT), confirming the bars are session-aligned.
   **Trigger**: the same `missed_trading_days >= 1` predicate as step 1's `daily_marks` backfill (D2A
   MISSED-TRADING-DAY COUNT, Step 0 connector-sanity band above) — not redefined here. **Per open option
   position** (same `analytics.fn_is_occ_option_symbol`-filtered set as the spot ingest above):
   `get_price_history(contract_id=<the fill's numeric call_contract_id/put_contract_id>, security_type="OPT",
   step="ONE_HOUR", period="ONE_WEEK", outside_rth=false, exchange="SMART")` — `ONE_WEEK` comfortably spans
   the routine Thu->Sun 3-day gap with margin; on a wider gap, widen `period` proportionally, up to
   `ONE_MONTH` — this account's own option-history retention reaches roughly a month, so an outage longer
   than that cannot be recovered by this path either. **Deriving the daily close from hourly bars — the part
   that must be done carefully.** For each missed trading day, take the close of the LAST returned bar whose
   `time` falls at or before that day's regular-session close — **16:00 America/New_York**. Compute that
   cutoff FROM the America/New_York wall-clock time at ingest, never a hardcoded UTC hour: 16:00
   America/New_York is 20:00Z under EDT but 21:00Z under EST, so a hardcoded `20:00Z` cutoff silently admits
   or drops an hour of bars — and silently shifts the derived close — across every DST changeover. This is
   the same MARKET-plane discipline `bigquery/20_user_prefs.sql` pins for every other session-close
   computation in this repo (America/New_York, never a bare UTC offset). **Provenance**:
   `events.option_marks.source` (`bigquery/40_options_marks.sql`) already exists and needs no schema change —
   write `source='connector-backfill'` for a row this path produces, a third token distinct from the spot
   ingest's `'connector'` (same-day IBKR spot) and `'FMP-fallback'` (spot fallback), so a backfilled close is
   always distinguishable from a same-day live read. **Illiquidity**: a thinly-traded contract can print NO
   bar at all on a given day; if the response has no bar for a missed date, leave that date UNMARKED — never
   fabricate, never carry forward the prior close, never model one (extending, not replacing, the "Do NOT
   fabricate/carry-forward" sentence above) — `ops.sp_recompute_engine()` already excludes an unmarked
   option-day from the TWR chain rather than mis-valuing it, and that stays the correct fallback here too.

## H-D2a-08 — EXPIRYDAY TERMINAL MARK (bug fix, 20260808 — closes the zerotradeexpiry residual above without a

_Moved verbatim from `Claude_Task_Plan.md` (D2a, was line 2442) on 2026-10-30. Historical record only; the binding rule is the condensed text in the plan._

   **EXPIRY-DAY TERMINAL MARK (bug fix, 2026-08-08 — closes the zero-trade-expiry residual above without a
   market quote at all).** At expiration an option's value is not unknown, it is DEFINITIONAL — a contractual
   fact, not a market observation, so it needs no bar and (unlike the hourly path above) no historical query
   against the OPTION contract itself, which sidesteps the untested post-expiry boundary noted just above
   entirely. **Trigger**: a held option position whose `expiry` — read from its own CARRY-FORWARD source
   below, not re-derived — falls inside the missed-trading-day range (same D2A MISSED-TRADING-DAY COUNT
   predicate as the rest of this step, not redefined here) OR whose `expiry` equals
   `state.trading_day_today.today` — a carve-out added 2026-09-14, closing
   `d2a_missed_day_predicate_counts_today`: the corrected predicate above now excludes today from the
   general missed-day range, but a same-day, zero-trade expiry still needs a terminal mark the day it
   happens, so this OR-branch is evaluated independent of `missed_trading_days`. **CARRY-FORWARD, not parsing (correction,
   2026-08-08 — live schema check found the first version of this note wrong; see MULTIPLIER below).**
   `events.option_marks` STORES `strike`, `expiry`, `option_right`, AND `multiplier` as genuine per-row
   columns (`bigquery/40_options_marks.sql`'s `CREATE TABLE`, confirmed against the live table schema),
   populated from the connector response at the same-day spot ingest above — not defaulted, not assumed.
   Any position reaching its own expiry day while still open has necessarily been marked on an earlier day
   (the spot ingest runs every session Strategy C holds it), so `SELECT strike, expiry, option_right,
   multiplier FROM state.option_marks_curated WHERE occ_symbol = <ticker> ORDER BY mark_date DESC LIMIT 1` is
   the authoritative source for all four fields this rule needs — read the stored columns; do **not**
   re-derive them from the OCC ticker string. Why: a value captured from the connector at ingest is MEASURED;
   a value re-parsed from a symbol string later is a RE-DERIVATION that can silently disagree with it (a
   padding/format edge case, a non-standard root, a data-entry-adjacent symbol) with nothing to catch the
   mismatch — carrying the already-measured value forward has no such failure mode. **Determine moneyness**:
   recover the UNDERLYING's close on the expiry date via the ordinary EQUITY dated-bar path —
   `get_price_history(contract_id=<underlying's own contract_id>, security_type="STK", step="ONE_DAY",
   period=<spanning the gap>)`, the exact call step 1's own `daily_marks` missed-day backfill already makes
   for every held ticker; equities have always supported `step="ONE_DAY"` (only the OPTION contract rejects
   it, per the discovery this rewrite opened with) — and compare that close to the carried-forward `strike`.
   **OTM -> write `premium_close = 0`**: the contract expired worthless, which is a contractual fact, not an
   estimate. **ITM -> write `premium_close = |underlying_close − strike|`** — a PER-SHARE intrinsic value, on
   the exact same basis every other `premium_close` row already carries (`bigquery/125_dust_excluded_from_twr.sql`'s
   `option_held` CTE values a position at `contracts × multiplier × premium_close`; the multiplier scaling
   happens THERE, downstream, using the row's own carried-forward `multiplier` — this rule writes the
   per-share figure only and needs no multiplier arithmetic of its own) — and cross-check against
   `events.trade_fills`: if an assignment/exercise fill already reconciled for this position on/near expiry,
   the FILL's own recorded price is authoritative for `exit_price` (`analytics.position_lifecycle` already
   sources `exit_price` from the fill independently of `option_marks`); this computed intrinsic value is then
   only a sanity check against that fill (flag a mismatch beyond a few cents — commission/settlement rounding
   aside — as an `option_mark_missing`-class warning, not a silent overwrite), or it fills the mark for a day
   the fill's own settlement record doesn't otherwise cover — never a replacement for a fill that exists.
   **Provenance**: token `source='expiry-terminal'` — distinct from `'connector-backfill'` (a market
   observation, hourly-bar-derived) and from `'connector'`/`'FMP-fallback'` (same-day spot reads), since this
   row is DERIVED-BY-CONTRACT from a carried-forward strike + the underlying's close, not observed from any
   option quote, and a future reader must be able to tell the three apart at a glance. **The one genuine edge
   case, stated honestly: pin risk.** When the underlying's close sits AT or extremely near the strike,
   exercise is discretionary — assignment is not automatic exactly at parity, and the holder's own
   after-hours exercise decision (or the OCC's automatic-exercise threshold) can go either way — so moneyness
   at the 4pm close does NOT mechanically determine the outcome the way it does away from the strike. In this
   narrow band, do NOT compute a terminal mark from moneyness at all: defer to the actual assignment/exercise
   fill in `events.trade_fills` if one exists; if none exists yet (reconciliation lag), leave the date
   UNMARKED rather than guess — this is the one sub-case where "definitional, not a model" does not fully
   hold, and the existing illiquidity/never-fabricate rule still governs it exactly as it governs a genuinely
   quoteless day. **The one genuinely uncovered case: same-day open-and-expire inside the gap.** A 0DTE
   structure both OPENED and EXPIRING on a single day that falls inside the missed range (e.g., staged and
   filled on the skipped Friday itself) has NO prior `events.option_marks` row to carry `strike`/`expiry`/
   `option_right`/`multiplier` forward from — CARRY-FORWARD above is empty for it, and parsing the OCC ticker
   is deliberately not built as a fallback here either (see PARSING below). Defer instead to the reconciled
   fill in `events.trade_fills` for that position (`analytics.position_lifecycle` already sources its
   `exit_price`/accounting from the fill independently of `option_marks`); if no fill exists there either,
   leave the date unmarked. Do not parse, do not guess.

## H-D2a-09 — Currently dormant (unchanged fact from the note this supersedes): Strategy C — the only strategy this

_Moved verbatim from `Claude_Task_Plan.md` (D2a, was line 2532) on 2026-10-30. Historical record only; the binding rule is the condensed text in the plan._

   **Currently dormant** (unchanged fact from the note this supersedes): Strategy C — the only strategy this
   branch can ever apply to (`analytics.fn_is_occ_option_symbol`, above) — holds ZERO open positions as of
   2026-08-08 (verified: `SELECT * FROM state.current_positions WHERE strategy='C' AND status='OPEN'` returns
   no rows), so this backfill has nothing to ingest today. Unlike the note it supersedes, that is no longer
   "the cliff cannot bite because nothing is exposed to it" — it is "the mechanism is now built and will run
   the next time `missed_trading_days >= 1` finds an open Strategy C option position," which the SISA
   graduation pipeline (or a HYBRID ACTIVATE FOMC-only qualifying event, C's live router path today) could
   produce at any time.
1c. **MARK-DISCONTINUITY TRIPWIRE + SPLIT-ADJUST (finding C2, 2026-07-17 split-aware engine — `bigquery/82_split_aware_engine.sql`; watched-set extended to the full park menu 2026-07-19, `bigquery/92_park_allocator.sql`).** After the equity/benchmark (step 1) and option (step 1b) marks are ingested — and BEFORE the engine recompute (step 2), so a bad mark cannot drive a phantom termination — read `state.mark_discontinuity_watch` (the held-position + full 12-ticker park menu (+ SPY) benchmark tickers, sourced from COALESCE(`state.daily_marks_curated`, `state.signal_marks_curated`) so the 9 menu tickers whose closes land only in `signal_marks_curated` are actually watched, not just SGOV/VOO/SPY; it flags a >25% day-over-day `close` move on the latest `mark_date` that is NOT a recorded split (`split_ratio = 1`) and NOT explained by a same-day dividend):
   - **Bad-print / missed-split CRITICAL:** for any row with `is_discontinuity = TRUE` on today's `mark_date` (`= state.trading_day_today.last_trading_day`), `CALL ops.sp_raise_alert('critical','D2a','mark_discontinuity', CONCAT(ticker,' moved ',CAST(ROUND(raw_move*100,1) AS STRING),'% day-over-day (',CAST(prev_close AS STRING),'->',CAST(close AS STRING),') with no recorded split or dividend'), '<JSON: ticker, mark_date, close, prev_close, raw_move, split_ratio, dividend>')`. Being a NON-excluded CRITICAL it forces `state.system_health.all_green = FALSE` (holding `state.trading_enabled` FALSE), which **BLOCKS D2's rigid STRATEGY TERMINATION conversion (step 5) until the mark is adjudicated** — a REAL split gets its `split_ratio` recorded (clearing the flag; the split-aware engine then handles it), a BAD print gets corrected and re-reconciled next run. Do NOT let a -50% phantom drawdown from an unrecorded split auto-terminate a strategy — this tripwire is exactly that guard (the existing LN-domain clamp only fires at -99.99%, ~200x too coarse; see 82's header).
   - **Recorded-split share-sync:** for any held ticker whose latest `state.daily_marks_curated` row carries `split_ratio != 1` (a CORRECTLY-recorded split — NOT flagged above; `analytics.strategy_daily_returns`'s `eff_split_since_entry` already keeps its mv/dividend continuous), write an `events.position_events` row (`event_type='SPLIT_ADJUST'`, the ticker, the `split_ratio`, `mark_date`) — **echoing EVERY other column forward verbatim from the position's current `state.current_positions` row and changing only `shares` (and `cost_basis`/`convergence_target` per the split ratio): this row becomes latest-wins for the `position_key`, so any column left out of it is DESTROYED, including `invalidation_status`** (see "Shared rules referenced across prompts" → "An omitted field is a destroyed field") — so the position's share count is synced to the post-split basis and the audit trail records the corporate action. Idempotent — NOT-EXISTS on (`position_key`/ticker, `event_type='SPLIT_ADJUST'`, `mark_date`) before insert (the `ops.roster_change_log` pattern), since D2a may re-run same-day.
   Inert today (verified 2026-07-17: zero `is_discontinuity` flags across all held+benchmark mark history, latest mark 2026-07-17; no held ticker carries `split_ratio != 1`).
1d. **SIGNAL INGEST (`bigquery/91_park_signal_layer.sql`; built 2026-07-18 as the park-allocator evidence layer — **TRIMMED 2026-10-15** when the park went VOO-only, `bigquery/256`: the park-menu tickers are no longer ingested, only the three series other consumers read — SPY and `^VIX` for step 1e's `SPY_TREND`/`VIX_REGIME`, and `BZUSD` for the shock-overlay rubric's Brent triplet (M1a, M1R) and `state.shock_price_leg_status` (`bigquery/263`, D2 item 4's shock price-leg triggers; until Rev 52, owner directive 2026-10-22, interactive session, the retired `state.rerisking_limb_status`)).** A separate, ISOLATED ingest branch from step 1 above — writes to **`events.signal_marks`, NEVER `events.daily_marks`** (the spec-frozen TWR-engine / kill-flag / thin-SPY-beta consumers of `daily_marks` must stay untouched, and this new evidence layer must never contaminate them — the design's own grounding note). For SPY, `^VIX` and `BZUSD` ONLY: pull the day's close. **Do NOT ingest SGOV, GOVT, IEF, TLT, LQD, MUB, HYG, PFF, AOR, VOO or VTI here any more** (retired 2026-10-15 — their only consumers were the retired park call and W5 park scorecard; VOO and SGOV still reach `events.daily_marks` through step 1).
   - **`^VIX`: FMP `chart` (`historical-price-eod-light`, `symbol='^VIX'`) is PRIMARY — a DATED-BAR pull, not
     `mcp__FMP__quote`** (bug fix, 2026-08-08 — `quote` is a SPOT read with no history at all, so it cannot
     recover a missed day; verified live the same day, `chart`'s `historical-price-eod-light` endpoint returns
     one row per trading day with its own `date` field, e.g. a query run 2026-08-08 correctly returned dated
     rows for 2026-08-03 through 2026-08-07 with no 2026-08-08 row, since Saturday has no VIX print). No IBKR
     series exists for the index under the plain `get_price_history` call every other ticker below uses
     (no daily VIX series exists under a PLAIN `get_price_history` call; IBKR DOES return one for
     `contract_id=13455763` with `security_type='IND'`, `exchange='CBOE'`, `step='ONE_DAY'`, which the
     retired D1 PARK ALLOCATION CALL used as its PRIMARY VIX source from 2026-08-24. This ingest
     predates that discovery; FMP stays primary here).
     **`source` for a `^VIX` row is the literal token `'FMP'`, NEVER `'FMP-fallback'` (pinned 2026-09-02, D2a).**
     FMP is this ticker's PRIMARY, so `'FMP-fallback'` — which everywhere else in this step means *IBKR was
     primary and failed* — is factually wrong for it, and this bullet had never named a token at all. Measured
     that day on `state.signal_marks_curated`: the daily `^VIX` ingest had drifted across BOTH values with no
     rule, 19 rows `'FMP-fallback'` (2026-07-20..2026-08-31) against 14 rows `'FMP'` (2026-07-31..2026-09-02),
     interleaved day to day. The already-landed rows stay as they are (`events.*` is append-only and the split
     is cosmetic); write `'FMP'` from here on so the fallback token keeps meaning what it means.
     **`mark_date` is the RETURNED BAR's own `date` field, NEVER `state.trading_day_today.today`** — on a
     Sunday run recovering Friday's close, the bar's `date` is Friday, and that is what `mark_date` must carry;
     stamping `today` would silently misdate the close as a Sunday reading that never existed.
   - **SPY: IBKR `get_price_history` is PRIMARY, FMP fallback** (`mcp__FMP__quote`/`mcp__FMP__chart`) — same fallback convention as step 1's `daily_marks` ingest above.
   - **`BZUSD` (Brent crude) — FMP `mcp__FMP__commodity` `commodities-historical-price-eod-light`, symbol `BZUSD`, is the ONLY source (added 2026-09-04, park v4 Phase 1; `bigquery/217_brent_signal_feed.sql` seeded 2026-06-01..09-04).** Brent is not an IBKR menu instrument, so there is no IBKR primary here and no fallback — if FMP's commodity endpoint is unavailable, ingest NOTHING for `BZUSD` that day and let `state.park_axis_daily`'s freeze semantics carry the last measured shock level rather than inventing one. Record `dividend=0`, `split_ratio=1`, `source='FMP'`. **PRE-CLOSE GUARD, SCOPED TO OFF-CADENCE LOADS ONLY (added 2026-09-14, closing `signal_mark_captured_pre_close`, alert `10a9ca27-1158-4b3d-ace4-620d4e1c6639` — corrects that notice's own suggested fix, a bare `mark_date < CURRENT_DATE` INSERT-time filter, which was verified live to also reject D2a's ordinary Sun-Thu pull and was NOT applied): a one-time historical backfill/seed SQL file for `BZUSD` (the `bigquery/217_brent_signal_feed.sql` pattern) or any other manually-triggered, out-of-band load of this ticker — including a manual re-run of the FIRST-INGEST DEEP PULL bullet below, run outside D2a's own schedule — must set its date window's upper bound no later than the trading day BEFORE the date the load itself is executed, leaving that trailing date for D2a's own next STEP 1d pass to capture at its normal time. D2a's OWN regular Sun-Thu ~16:41 MT execution — its ordinary same-day pull and its MISSED-DAY BACKFILL clause below alike — needs NO guard and this rule must never gate either: MEASURED against `events.signal_marks`, not inferred. The incident print (`mark_date`=2026-09-04, 95.55, later restated 96.28) has `ingest_ts` 2026-09-04 06:56 UTC / 02:56 EDT, matching `bigquery/217`'s one-time seed (committed 03:11 EDT) — not a D2a firing; D2a does not run Friday evenings at all (Sun-Thu), and 09-04's close was instead captured correctly two days later by the ordinary Sunday 09-06 MISSED-DAY BACKFILL, well after that Friday's session had closed. The identical Friday→Sunday pattern recurred harmlessly on 09-11→09-13 with a single, never-restated row, alongside three plain same-evening captures (09-08, 09-09, 09-10) — four ordinary-cadence captures with zero premature reads between them. Do not carry forward the claim that Brent "has no settled close at any D2a run time" — this same data contradicts it; the exposure is confined to an off-cadence capture, never the daily routine. This is orthogonal to TRADING DAYS ONLY below (which ticker-dates get a row at all, not when in the day one may be captured) and to the idempotent-on-`(mark_date, ticker)` INSERT convention above, which is what let 09-04's bad print be silently superseded rather than requiring a manual repair.** **AND THE VENDOR REVISES THIS SERIES AFTER PUBLICATION, SO NO SAME-EVENING `BZUSD` READ IS A SETTLED CLOSE — CITE IT AS PROVISIONAL (added 2026-09-21, W5 SPEC-DEFECT NOTICE INTAKE, closing D1's `fmp_bzusd_settled_value_revised`, alert `fe9e134e-2fa0-4ac1-80ee-da8fdfa2c4af`).** The PRE-CLOSE GUARD above covers a value captured BEFORE the session closed. This is the strictly later failure: a value captured after the close, and correct-looking at the time, that the vendor subsequently RESTATES. MEASURED by D1 2026-09-09: the FMP `BZUSD` series re-read that day returned **97.92** for `2026-09-08`, while the 2026-09-08 D1 park record cites **99.39** from that same endpoint — a figure already written into a durable decision record and no longer reproducible from its own cited source. The revised row additionally duplicated the 2026-09-07 price to the cent with a near-identical volume, the signature of a carried-forward vendor row rather than an independent settle. Nothing turned on it (97.92, 99.39 and 101.21 all clear the 95 shock threshold decisively), and the ordinary idempotent-on-`(mark_date, ticker)` ingest already supersedes a superseded print without manual repair — so **this changes no ingest behaviour and adds no guard to D2a's own pull.** What it changes is CITATION: any routine quoting a `BZUSD` value for the CURRENT date — D1's park rationale, M1a/M1R's shock-overlay triplet, W3's rubric legs — must label it provisional and must not treat a later disagreement with it as a defect in the earlier record. Where the decision turns on the exact level rather than on clearing a threshold by a margin, re-read the value on a subsequent session before relying on it. `state.signal_marks_curated` remains the surface of record precisely because it carries the restatement.  **TRADING DAYS ONLY:** Brent trades on some dates the equity market does not (the vendor returns Sundays), and every other ticker in this table is one-row-per-trading-day — filter on `state.market_calendar.is_trading_day` before INSERT, or a future window function silently mis-counts. This limb is what makes the park v4 SHOCK axis testable: `shock_overlay='acute'` ALONE is a standing state, not an event (it read `acute` every session 2026-08-14..09-03), so the axis requires a commodity PRICE limb to distinguish "a shock exists" from "the shock got worse today". **Do NOT raise an `fmp_quote_plan_gated` row if this endpoint denies** — the FMP TIER MATRIX rule above governs, and `commodity` was measured WORKING on the current tier 2026-09-04 while `economics` was measured DENIED.
   - `INSERT INTO events.signal_marks (mark_date, ticker, close, dividend, split_ratio, source)` — carry the day's dividend (0 if none) and split ratio (1 if none) from the corporate-actions pull, same convention as step 1's `daily_marks` ingest (total-return fidelity for the W5 counterfactual indices depends on the dividend column; `^VIX` is always dividend=0/split=1). Idempotent on `(mark_date, ticker)` — the curated view's latest-ingest-wins dedup absorbs a re-ingest.
   - **FIRST-INGEST DEEP PULL (self-healing backfill):** if a ticker has ZERO rows in `state.signal_marks_curated` (first-ever ingest, a ticker newly added to the menu, or a prior backfill gap), pull **~1 year of daily history** for it in this step instead of just the day's close, batched ≤200 rows per INSERT. The downstream views (`state.park_rule_shadow`, `analytics.park_counterfactuals`, `state.mark_discontinuity_watch`) recompute retroactively the moment history lands, so coverage self-completes without a manual backfill session.
   - **MISSED-DAY BACKFILL (bug fix, 2026-08-08 — this ingest previously had no gap-widening at all for a
     ticker that already has history).** Modeled on step 1's `daily_marks` missed-day backfill above, same
     corrected predicate (D2A MISSED-TRADING-DAY COUNT, Step 0 connector-sanity band above): if
     `missed_trading_days >= 1` since D2a's own last successful completion, pull the day's close (per-ticker
     source above) for EVERY missed trading day in the gap, not just today, and `INSERT` one row per (ticker,
     missed trading day) exactly as above — idempotent on `(mark_date, ticker)`, so a backfill re-run is safe.
     This is what lets a Sunday D2a run recover Friday's close for SPY, `^VIX` and `BZUSD` once the
     daily-tier fleet stops firing Friday/Saturday — without it, only a ticker with literally ZERO history ever
     backfilled (the FIRST-INGEST DEEP PULL bullet above), and every already-established ticker would carry a
     permanent, silent, Friday-shaped hole in `events.signal_marks` every single week.
   - Several of these tickers (SGOV, VOO, SPY) are ALSO ingested into `events.daily_marks` by step 1 above, for unrelated reasons (TWR engine, park reconciliation, beta) — this is intentional duplication across two isolated tables, not redundant work to consolidate. Never cross-read `signal_marks` into a TWR/kill-flag computation, and never cross-read `daily_marks` into the park allocator's evidence base — where "evidence base" is the derived-view layer (`state.park_signal_daily` / `park_rule_shadow` / `park_counterfactuals`), i.e. this binds the INGEST PIPELINE, not the reader. A D1 park-call session remains free to consult `events.daily_marks`, or anything else, per D1's floor-not-ceiling evidence list.
   - Best-effort — a connector hiccup here must never abort D2a (this feeds step 1e's router keys and D2 item 4's shock price-leg triggers, not the trading-enable gate or any capital decision).
1e. **TECHNICAL_SIGNAL WRITE — the router's technical half (assigned here 2026-08-03; Operating_Protocols.md §15's write column).** D2a owns this because step 1d already ingests the exact series two of the four keys need, and because `strategy/01_shared_regime_vocabulary.md` requires the technical half of the router to be **mechanically computable with no AI classification** — a threshold computation, not a judgement, so it belongs in the mechanical daily ingest and NOT in D1/D2's discretionary `STRATEGY_ACTIVATION` router-review write. Compute all four vocabulary keys for the last completed session and `INSERT INTO events.regime_events (as_of_date, scope, key, value, numeric_value, rationale, source_review_ref)` with `scope='TECHNICAL_SIGNAL'`, one row per key. Apply the vocabulary's thresholds VERBATIM — they are immutable and this step must never reinterpret them:
   - **`SPY_TREND`** — from `state.signal_marks_curated` SPY closes (step 1d already ingests them, and its FIRST-INGEST DEEP PULL guarantees ≥1y of history, which is what makes the 200-day window available): `UP` if close > 50d SMA AND 50d SMA > 200d SMA; `DOWN` if close < 50d SMA AND 50d SMA < 200d SMA; `NEUTRAL` otherwise. Assert both windows are FULL (exactly 50 and 200 closes) — on a short window write NO row rather than a row computed on a partial window, and say so in `<note>`.
   - **`VIX_REGIME`** — from the `^VIX` close step 1d just ingested: `LOW` < 15; `NORMAL` 15–25 inclusive; `HIGH` > 25. Carry the close in `numeric_value`.
   - **`SUSTAINED_INVERSION`** — needs 10Y/2Y Treasury yields, which are currently pulled only MONTHLY by M1a into `state.macro_fred_latest`; pull them daily here (`mcp__FMP__economics` `treasury-rates`, the same endpoint M1a uses) **with `from_date`/`to_date` BOTH PINNED to the date you are writing the row for, and read `year10` / `year2` (added 2026-08-23 — M1a's own use of this identical endpoint already carries this rule and learned it the hard way; this step never restated it).** An UNPINNED call returns the endpoint's latest available row, which is not necessarily the date you are stamping: M1a records a 2026-07 defect where exactly that returned a stale prior-day value that propagated into `analytics.deployed_twr_forecast` and produced a false M5 calibration-breach alert. It has already bitten D2a too — the 2026-08-13 `events.regime_events` row (`f379e103`) records that the FMP read had to be *“fetched with an explicit from/to range after the default-window call omitted the last two days”*, i.e. a session caught the staleness by hand because the spec did not require pinning. **Read the tenor columns BY NAME, never by column position:** the payload carries `month1/month2/month3/month6/year1/year2/year3/year5/year7/year10/year20/year30`, and Treasury.gov's own table interleaves extra bill columns, so positional reading silently returns the wrong tenor. That is not hypothetical — W3's 2026-08-17 note reported a phantom 17bp/36bp FMP-vs-Treasury.gov discrepancy that was re-measured to zero on 2026-08-23: its “10Y=4.51” was the **7-year** and its “2Y=3.81” was the **2-MONTH** bill. FMP reproduces Treasury.gov's par curve exactly (2026-08-14: 2Y 4.17, 10Y 4.68, verified against home.treasury.gov on all seven trading days 08-12..08-20). Yield Curve State is `INVERTED` if 10Y < 2Y else `NORMAL`; the flag is `SUSTAINED` only if the curve has been INVERTED for ≥ 18 consecutive months, else `NOT-SUSTAINED`. **THE 18-MONTH HISTORY CANNOT BE PULLED IN ONE CALL — THE ENDPOINT TRUNCATES SILENTLY (added 2026-09-21, W5 SPEC-DEFECT NOTICE INTAKE, closing D2a's `treasury_range_call_silently_truncates`, alert `30532f31-2302-4213-88e0-3ac80c63fbf9`).** The pinned same-day read above works and is unaffected; what was never specified is how to obtain the ≥18-consecutive-month history the `SUSTAINED` promotion requires. MEASURED 2026-09-08 by D2a: a single `treasury-rates` call with `from_date=2025-01-01`, `to_date=2026-09-08` returned **61 rows reaching back only to 2026-06-10 (~3 months)** — with **no error and no truncation marker of any kind**. A session that trusted one wide call would therefore read NOT-SUSTAINED off an ABSENCE of data while believing it had measured a non-inverted history, and nothing in the response distinguishes the two. **So: never infer inversion history from a single wide-range call.** When the same-day read returns `INVERTED` and the `SUSTAINED` test therefore becomes live, pull the history as successive pinned windows of **≤ 3 months each**, walking back from today until either 18 consecutive inverted months are established or a NORMAL month is found, and **assert each window actually returned rows spanning the dates you asked for** — a window that comes back short is an incomplete read, not a gap in the curve. If the chunked walk cannot be completed this run, write `NOT-SUSTAINED` only when the same-day curve is NORMAL (where it is correct on the same-day read alone, since the promotion can apply only to an already-INVERTED curve); on an INVERTED same-day curve with an incomplete history, record the flag as UNDETERMINED in the rationale rather than asserting NOT-SUSTAINED from missing data. **This was not blocking when found and is not a live error today:** the 2026-09-08 curve was NORMAL (10Y 4.80 > 2Y 4.39), so the same-day read alone settled it. The rule exists so the first genuinely inverted curve is not silently mis-flagged. The same caveat binds **M1a**, which uses this identical endpoint. **Do NOT write a separate `TREASURY_10Y` row any more** (retired 2026-10-15 with the park allocator, `bigquery/256`: its only reader was `state.park_axis_daily`'s rates axis).
   - **`EQUITY_BREADTH`** — % of S&P 500 constituents closing above their OWN 200-day SMA; `HEALTHY` ≥ 50%, `WEAK` < 50%. **Read the observation D1 writes; apply the threshold here. Do not fetch it yourself and do not fake it.**
     - **SOURCE OF RECORD (rev 2026-08-05):** `SELECT numeric_value, as_of_date, rationale FROM events.regime_events WHERE scope = 'TECHNICAL_INPUT' AND key = 'EQUITY_BREADTH_PCT' ORDER BY as_of_date DESC LIMIT 1` — D1 writes that row daily (see D1's EQUITY-BREADTH OBSERVATION step). **Ordering works without a dependency edge on a normal day, not on every day (corrected 2026-10-19, owner decision in an interactive session: wire Strategy.md's daily technical-flip divergence clause literally).** D1 fires 16:00 MT and D2a 16:40 MT (`ops/cadence.yaml`), so on a normal day the same session's observation is already there. When D1 writes after this step (a late or catch-up D1), this step carries the previous reading under the clause below, and D2, which `depends_on` D1, then runs with the fresher reading already in `events.regime_events`. Measured over the 51 sessions with a D1 reading (2026-08-05 to 2026-10-16), the stored signal used the same-session reading on 49. On the 2026-08-14 session this step wrote at 2026-08-16 18:07 MT from the 08-13 reading, D1 wrote the 08-14 reading at 19:21 MT, and D2 ran at 19:46 MT; both readings were HEALTHY. The 2026-09-21 session is a different case: BigQuery was de-authed that evening, this step's catch-up (2026-09-22 03:52 MT) and D2's (04:18 MT) found no 09-21 reading at all, and D1 back-filled it at 2026-09-22 16:15 MT, so the carry was the best reading in the warehouse whenever any routine read it. Do not re-threshold a past row when a late reading lands: no consumer reads a past session's `EQUITY_BREADTH` signal for a decision (D2 item 4's DETECT reads `TECHNICAL_INPUT` for both breadth triggers, SL3's `regime_cell` reads only `SPY_TREND` and `VIX_REGIME`, and `state.rerisking_limb_status`, which read the latest plane, was retired by Rev 52). The same-evening case is handled where the value is used, by D2's **BREADTH LEG FRESHER THAN ITS SIGNAL** rule (ROUTER EVERY-RUN DUTIES; AR_orc's moot test cites it), which thresholds the same-session reading when one exists. This step is unchanged and stays the only writer of `TECHNICAL_SIGNAL`. D2a deliberately keeps `depends_on: []` — if D1 missed or its fetch failed, D2a still runs and degrades through the carry-forward clause below rather than blocking the whole broker reconcile on a breadth number. Apply `HEALTHY` ≥ 50 / `WEAK` < 50 to its `numeric_value` and write the result to `TECHNICAL_SIGNAL`. **The threshold application is this step's job and stays mechanical; the measurement is not.** Set `source_review_ref` to `'D1 EQUITY-BREADTH OBSERVATION as_of <that row as_of_date>'`.
     - **IF D1'S ROW IS ABSENT OR STALE — carry forward, but make the staleness MACHINE-READABLE, not just prose.** Carry the last observation, and put the **measurement age in days** in the `<note>` and in `rationale` as the literal token `breadth_measurement_age_days=<N>`, where N is `as_of_date` of this row minus the `as_of_date` of the underlying D1 observation. **When N > 5, also `CALL ops.sp_raise_alert('warning','D2a','technical_signal_stale','EQUITY_BREADTH carried <N> days since last measurement', ...)`.** *Why this clause exists:* before 2026-08-05 the carried value was re-stamped with a fresh `as_of_date` every single day while the underlying figure stayed frozen — 67 was written on 07-31, 08-03 and 08-04 off one measurement — which defeats the freshness signal the "write every trading day" rule below is built on: `as_of_date` advanced while the fact behind it did not, and nothing mechanical could tell the difference. Prose self-disclosure in `rationale` is not enough; a consumer reading `state.current_regime` sees only a fresh date.
     - **PROVENANCE CORRECTION (2026-08-05).** This clause previously said to carry "the most recent **independently-measured** value (M1a's monthly `risk_sentiment` rationale reports this figure)". **That characterization was wrong and is retired.** M1a's spec never asks for a breadth figure at all (its Section 6 covers only VIX / credit / USD / yield curve), no `events.regime_events` row ever named a source for the number, the reported window was not stable across runs (May 2026 reported "~54% above **50-day**", June reported none, July reported "~67% above **200-day**"), and since constituent enumeration is impossible on both connectors M1a cannot have measured it mechanically. It was an **unsourced figure**, not a measurement. **Never route an M1a prose figure into this key again** — that also violated `strategy/01_shared_regime_vocabulary.md`'s rule that the technical half carry no AI classification, by importing a number from the AI-scored fundamental half.
<!-- connector-tools-checker: ignore-start -->
     - **What is and is not blocked for a FROM-SCRATCH computation (measured 2026-08-03 against both live connectors — do not re-probe from scratch):**
     - **PRICES ARE NOT THE BLOCKER — IBKR covers them well.** `get_price_history(contract_id, security_type='STK', step='ONE_DAY', period='ONE_YEAR', outside_rth=false)` returns **250 daily OHLCV bars in ONE call** (verified on AAPL, conid 265598), which is more than the 200 the SMA needs. IBKR is also already this stack's PRIMARY mark source, so it is the right price leg — not FMP.
     - **ENUMERATION IS THE BLOCKER.** Nothing available can list the ~500 constituents. IBKR's tool surface (34 tools) has no ETF-holdings, index-components, screener or market-scanner tool at all; `search_contracts` resolves S&P *sector* indices (`S5FINL`) but returns EMPTY for every breadth-index symbol tried (`S5TH`, `S5FI`, `MMTH`, `SPXA200R`) and for the keywords `breadth` and `advance decline`, so there is no one-call pre-computed breadth instrument either. On FMP, every enumeration route is plan-gated: `directory` and `technicalIndicators` need Starter+, `indexes` and `quote` need Premium+, `etfAndMutualFunds` (SPY holdings — the obvious constituent list) needs Ultimate+. Only `chart` and `economics` are open.
     - **AMENDED 2026-08-19 (re-probed live after the 2026-08-17 `Limit Reach` day made every endpoint unmeasurable) — the free tier is WIDER than this paragraph says, and it still does not solve enumeration.** Three corrections. **(1) `marketPerformance` is OPEN on free** and was never in the 2026-08-03 sweep: `biggest-gainers`, `biggest-losers`, `most-active` and `sector-performance-snapshot` all returned real data, over a symbol universe far wider than the per-symbol allow-list (they return names like `EL`, `TWST`, `TEM`, `BNTX` that the per-symbol endpoints deny). **"FULL market" originally said here is corrected for `sector-performance-snapshot` specifically (2026-08-27): with no `exchange` argument it silently returns NASDAQ-only, not a blend — see the shared "Metered external calls" rule's silent-failure (iii). The movers endpoints are unaffected by that particular defect; their own limitation is (2) below.** So `chart` + `economics` is no longer the whole free surface. **(2) It is still not an enumeration route, for a reason that matters more than the gating:** the movers endpoints return a FIXED TOP 50 ranked by percent move, with no `limit`/paging and no market-cap field. Measured 2026-08-19, that list bottomed out at **+16.80% (gainers) / −13.81% (losers)** — so it reaches roughly the top 0.5% of moves, NOT a `>=2%` population, and it is dominated by micro-caps, SPAC rights and leveraged ETFs. **`COHR` at −7.99% would NOT have appeared in it** — i.e. the endpoint most likely to be proposed as the fix for the 2026-08-17 evidence loss would not have caught the very name that was lost. Do not treat the free movers feed as a substitute for a `>=$2B / >=2%` screen; it is a tail-risk radar, not a population. **(3) The free tier also restricts the SYMBOL UNIVERSE, not just the endpoint list** — `company`/`analyst`/`quote` per-symbol calls serve an allow-list (AAPL MSFT NVDA GOOGL AMZN META TSLA MRNA INTC PFE SOFI JPM XOM WMT V UNH JNJ SPY confirmed permitted; COHR BNTX TEM EL LZB TWST MRVL NBIS MSTR HD PG QQQ confirmed denied). It is not a market-cap cut: HD and PG are denied while SOFI is permitted, and SPY is permitted while QQQ is denied. **This also corrects the sentence above: `quote` does NOT need Premium+** — it returns real data on free for an allow-listed symbol (AAPL came back with `marketCap` AND `changePercentage` in ONE call) and is denied at the SYMBOL level otherwise; per FMP's own comparison table its full US coverage begins at **Starter**. Nothing in this repo or in BigQuery holds a constituent universe either (D1's screens run off sector ETFs and event-attributable moves, not membership).
     - **`get_price_snapshot` has no moving-average field.** Its `market_data_names` enum is fully enumerated in the tool schema and the closest entry is `misc_statistics` (13/26/52-week high/low) — there is no `priceAvg200` shortcut on the IBKR side.
     - **NO ENDPOINT ON EITHER CONNECTOR BATCHES.** `get_price_history` and `get_price_snapshot` each take a single `contract_id`; FMP `chart` takes a single `symbol`. So a sweep is one call per name, and each history response is ~10KB.
     - **⚠️ THE PARAGRAPH BELOW IS SUPERSEDED (2026-08-05) — kept because its measurements are still accurate, but its CONCLUSION is not.** Everything it says about IBKR/FMP enumeration being blocked remains true and is worth not re-probing. What it got wrong is treating self-computation as the only route, and therefore framing this as an owner *cost* decision (~500 calls/trading day). **It never considered fetching a PUBLISHED, pre-aggregated breadth number — one call, no enumeration.** That is now the adopted mechanism (D1 observes → D2a classifies, above). The `$S5TH` probe recorded below returned empty *through IBKR `search_contracts`*, which rules out quoting it as an IBKR instrument — it does **not** rule out reading the published value, and Q1 already did exactly that on 2026-07-01, citing StreetStats and Barchart `$S5TH` for the ~62–63% quarter-end figure. Do not cite the paragraph below as grounds to reopen the ~500-call build.
     - **THEREFORE the shape of the fix, if the owner wants it built, is:** (1) treat MEMBERSHIP as a slow-moving VERSIONED ARTIFACT, not a feed — it changes ~20×/year, so a checked-in `ops/sp500_constituents.yaml` (symbol + resolved IBKR conid, refreshed on a quarterly cadence with drift detection) removes the gated-endpoint dependency entirely and is the only piece that actually needs a decision; (2) one-time backfill of ~500 `get_price_history` calls into a `signal_marks`-style table; (3) daily, fetch only each name's LATEST close and compute the 200d SMA and the ≥50% count **in SQL**, so no agent ever holds 500 price series in context. Step (3) is still ~500 calls per trading day with no batching available — that call volume, not the metric, is the reason this is an owner decision rather than something a routine should quietly start doing.
<!-- connector-tools-checker: ignore-end -->
   - **Write EVERY trading day, even when no value changed.** `as_of_date` is then a freshness signal as well as a value, so a dead-man's switch can tell "unchanged" apart from "nobody is writing this" — the exact distinction whose absence let this scope sit unwritten for 61 days (2026-06-03 → 2026-08-03) while `state.current_regime` kept serving the stale rows as current. Idempotent on `(as_of_date, scope, key)` since D2a may re-run same-day.
   - **NOT best-effort in the same sense as 1d.** A failure here does not abort D2a, but it must be recorded: the router's whole technical half — every M1b divergence flag and every daily technical flip D2 acts on — reads these four rows. On failure log it in `<note>` and `CALL ops.sp_raise_alert('warning','D2a','technical_signal_stale', ...)`. **Precedent for why this matters:** M1b 2026-08-03 found the orphaned `SPY_TREND` row still reading `NEUTRAL` from 2026-06-03 when the measured value was `UP`, which had silently suppressed a real Strategy-A divergence; `VIX_REGIME` had never been written at all and every consumer had been deriving it ad hoc from whatever VIX close M1a happened to quote in prose.
2. **Recompute the engine + embed (one call): `CALL ops.sp_daily_refresh()`** — runs `ops.sp_recompute_engine()`
   (a state-free `DELETE`+`INSERT` that rebuilds the full `perf.strategy_daily` series from `events.daily_marks` +
   the views) **and** `ops.sp_embed_pending()` in a single idempotent call. The full recompute is trivially cheap
   and absorbs any late mark/fill correction, so D2a re-runs it wholesale. `perf.kill_flags` then reads the latest row.
3. **Verify the engine row (no ledger to mirror).** The latest `perf.strategy_daily` row (`deployed_unit_value`,
   `peak_unit_value`, `current_drawdown`, `sgov_index`, `excess_vs_sgov`, `deployed_days`, `closed_trades`, `gate_n`,
   `as_of_date` = today MT) IS the record. Trust `perf.strategy_daily`, but if a day's `r_deployed` exceeds ±15% or `deployed_unit_value` leaves (0.3, 3.0)
absent a matching large market move — those signal a bad mark or an unreconciled fill, not real performance —
do NOT dead-end this in chat (unmonitored): `CALL ops.sp_raise_alert('warning','D2a','engine_mark_anomaly','<metric + value + date>','<JSON>')` so it reaches the monitored channel alongside the cash-tripwire / connector-sanity alerts on this same routine, and hold the suspect mark for re-reconciliation on the next run (rev 2026-07-10 — round-2 conversion).

### Pass 2 input — q0352, 2026-10-30

_The newly removed second-pass text is retained in this verbatim input; history only._

1d. **SIGNAL INGEST (`bigquery/91_park_signal_layer.sql`; `bigquery/256` trimmed the retired park-menu ingest; SPY/`^VIX` serve step 1e, BZUSD serves M1a/M1R and `state.shock_price_leg_status`, `bigquery/263`; `state.rerisking_limb_status` is retired).** A separate, ISOLATED ingest branch from step 1 above — writes to **`events.signal_marks`, NEVER `events.daily_marks`** (the spec-frozen TWR-engine / kill-flag / thin-SPY-beta consumers of `daily_marks` must stay untouched, and this new evidence layer must never contaminate them — the design's own grounding note). For SPY, `^VIX` and `BZUSD` ONLY: pull the day's close. **Do NOT ingest SGOV, GOVT, IEF, TLT, LQD, MUB, HYG, PFF, AOR, VOO or VTI here any more** (VOO and SGOV still reach `events.daily_marks` through step 1).
   - **`^VIX`: FMP `chart` (`historical-price-eod-light`, `symbol='^VIX'`) is PRIMARY — a DATED-BAR pull, not
     `mcp__FMP__quote`** (`quote` is spot-only and cannot recover a missed day). No IBKR
     series exists for the index under the plain `get_price_history` call every other ticker below uses
     (no daily VIX series exists under a PLAIN `get_price_history` call; IBKR DOES return one for
     `contract_id=13455763` with `security_type='IND'`, `exchange='CBOE'`, `step='ONE_DAY'`, which the
     retired D1 PARK ALLOCATION CALL used as its PRIMARY VIX source from 2026-08-24. This ingest
     predates that discovery; FMP stays primary here).
     **`source` for a `^VIX` row is the literal token `'FMP'`, NEVER `'FMP-fallback'`.**
     FMP is this ticker's PRIMARY, so `'FMP-fallback'` — which everywhere else in this step means *IBKR was
     primary and failed* — is factually wrong for it. Leave already-landed rows untouched (append-only), and write `'FMP'` from here on so the fallback token keeps meaning what it means.
     **`mark_date` is the RETURNED BAR's own `date` field, NEVER `state.trading_day_today.today`** — on a
     Sunday run recovering Friday's close, the bar's `date` is Friday, and that is what `mark_date` must carry;
     stamping `today` would silently misdate the close as a Sunday reading that never existed.
   - **SPY: IBKR `get_price_history` is PRIMARY, FMP fallback** (`mcp__FMP__quote`/`mcp__FMP__chart`) — same fallback convention as step 1's `daily_marks` ingest above.
   - **`BZUSD` (Brent crude) — FMP `mcp__FMP__commodity` `commodities-historical-price-eod-light`, symbol `BZUSD`, is the ONLY source (`bigquery/217_brent_signal_feed.sql`).** Brent is not an IBKR menu instrument, so there is no IBKR primary here and no fallback — if FMP's commodity endpoint is unavailable, ingest NOTHING for `BZUSD` that day and let `state.park_axis_daily`'s freeze semantics carry the last measured shock level rather than inventing one. Record `dividend=0`, `split_ratio=1`, `source='FMP'`. **PRE-CLOSE GUARD, SCOPED TO OFF-CADENCE LOADS ONLY: a one-time historical backfill/seed SQL file for `BZUSD` (the `bigquery/217_brent_signal_feed.sql` pattern) or any other manually-triggered, out-of-band load of this ticker — including a manual re-run of the FIRST-INGEST DEEP PULL bullet below, run outside D2a's own schedule — must set its date window's upper bound no later than the trading day BEFORE the date the load itself is executed, leaving that trailing date for D2a's own next STEP 1d pass to capture at its normal time. D2a's OWN regular Sun-Thu ~16:41 MT execution — its ordinary same-day pull and its MISSED-DAY BACKFILL clause below alike — needs NO guard and this rule must never gate either. Do not carry forward the claim that Brent "has no settled close at any D2a run time"; exposure is off-cadence capture, never the regular daily pull. This is orthogonal to TRADING DAYS ONLY below (which ticker-dates get a row at all, not when in the day one may be captured) and to the idempotent-on-`(mark_date, ticker)` INSERT convention above, which is what let 09-04's bad print be silently superseded rather than requiring a manual repair.** **AND THE VENDOR REVISES THIS SERIES AFTER PUBLICATION, SO NO SAME-EVENING `BZUSD` READ IS A SETTLED CLOSE — CITE IT AS PROVISIONAL.** The PRE-CLOSE GUARD above covers a value captured BEFORE the session closed. This is the strictly later failure: a value captured after the close, and correct-looking at the time, that the vendor subsequently RESTATES. The vendor can restate a correct-looking after-close read; latest-ingest-wins already supersedes it, so **this changes no ingest behaviour and adds no guard to D2a's own pull.** What it changes is CITATION: any routine quoting a `BZUSD` value for the CURRENT date — D1's park rationale, M1a/M1R's shock-overlay triplet, W3's rubric legs — must label it provisional and must not treat a later disagreement with it as a defect in the earlier record. Where the decision turns on the exact level rather than on clearing a threshold by a margin, re-read the value on a subsequent session before relying on it. `state.signal_marks_curated` remains the surface of record precisely because it carries the restatement.  **TRADING DAYS ONLY:** Brent trades on some dates the equity market does not (the vendor returns Sundays), and every other ticker in this table is one-row-per-trading-day — filter on `state.market_calendar.is_trading_day` before INSERT, or a future window function silently mis-counts. This limb is what makes the park v4 SHOCK axis testable: `shock_overlay='acute'` ALONE is a standing state, not an event , so the axis requires a commodity PRICE limb to distinguish "a shock exists" from "the shock got worse today". **Do NOT raise an `fmp_quote_plan_gated` row if this endpoint denies** — the FMP TIER MATRIX rule governs; `commodity` is a working current-tier surface, unlike denied `economics`.
   - `INSERT INTO events.signal_marks (mark_date, ticker, close, dividend, split_ratio, source)` — carry the day's dividend (0 if none) and split ratio (1 if none) from the corporate-actions pull, same convention as step 1's `daily_marks` ingest (total-return fidelity for the W5 counterfactual indices depends on the dividend column; `^VIX` is always dividend=0/split=1). Idempotent on `(mark_date, ticker)` — the curated view's latest-ingest-wins dedup absorbs a re-ingest.
   - **FIRST-INGEST DEEP PULL (self-healing backfill):** if a ticker has ZERO rows in `state.signal_marks_curated` (first-ever ingest, a ticker newly added to the menu, or a prior backfill gap), pull **~1 year of daily history** for it in this step instead of just the day's close, batched ≤200 rows per INSERT. The downstream views (`state.park_rule_shadow`, `analytics.park_counterfactuals`, `state.mark_discontinuity_watch`) recompute retroactively the moment history lands, so coverage self-completes without a manual backfill session.
   - **MISSED-DAY BACKFILL.** Modeled on step 1's `daily_marks` missed-day backfill above, same
     corrected predicate (D2A MISSED-TRADING-DAY COUNT, Step 0 connector-sanity band above): if
     `missed_trading_days >= 1` since D2a's own last successful completion, pull the day's close (per-ticker
     source above) for EVERY missed trading day in the gap, not just today, and `INSERT` one row per (ticker,
     missed trading day) exactly as above — idempotent on `(mark_date, ticker)`, so a backfill re-run is safe.
     This is what lets a Sunday D2a run recover Friday's close for SPY, `^VIX` and `BZUSD` once the
     daily-tier fleet stops firing Friday/Saturday — without it, only a ticker with literally ZERO history ever
     backfilled (the FIRST-INGEST DEEP PULL bullet above), and every already-established ticker would carry a
     permanent, silent, Friday-shaped hole in `events.signal_marks` every single week.
   - Several of these tickers (SGOV, VOO, SPY) are ALSO ingested into `events.daily_marks` by step 1 above, for unrelated reasons (TWR engine, park reconciliation, beta) — this is intentional duplication across two isolated tables, not redundant work to consolidate. Never cross-read `signal_marks` into a TWR/kill-flag computation, and never cross-read `daily_marks` into the park allocator's evidence base — where "evidence base" is the derived-view layer (`state.park_signal_daily` / `park_rule_shadow` / `park_counterfactuals`), i.e. this binds the INGEST PIPELINE, not the reader. A D1 park-call session remains free to consult `events.daily_marks`, or anything else, per D1's floor-not-ceiling evidence list.
   - Best-effort — a connector hiccup here must never abort D2a (this feeds step 1e's router keys and D2 item 4's shock price-leg triggers, not the trading-enable gate or any capital decision).
1e. **TECHNICAL_SIGNAL WRITE — the router's technical half (Operating_Protocols.md §15 write column).** D2a owns this because step 1d already ingests the exact series two of the four keys need, and because `strategy/01_shared_regime_vocabulary.md` requires the technical half of the router to be **mechanically computable with no AI classification** — a threshold computation, not a judgement, so it belongs in the mechanical daily ingest and NOT in D1/D2's discretionary `STRATEGY_ACTIVATION` router-review write. Compute all four vocabulary keys for the last completed session and `INSERT INTO events.regime_events (as_of_date, scope, key, value, numeric_value, rationale, source_review_ref)` with `scope='TECHNICAL_SIGNAL'`, one row per key. Apply the vocabulary's thresholds VERBATIM — they are immutable and this step must never reinterpret them:
   - **`SPY_TREND`** — from `state.signal_marks_curated` SPY closes (step 1d already ingests them, and its FIRST-INGEST DEEP PULL guarantees ≥1y of history, which is what makes the 200-day window available): `UP` if close > 50d SMA AND 50d SMA > 200d SMA; `DOWN` if close < 50d SMA AND 50d SMA < 200d SMA; `NEUTRAL` otherwise. Assert both windows are FULL (exactly 50 and 200 closes) — on a short window write NO row rather than a row computed on a partial window, and say so in `<note>`.
   - **`VIX_REGIME`** — from the `^VIX` close step 1d just ingested: `LOW` < 15; `NORMAL` 15–25 inclusive; `HIGH` > 25. Carry the close in `numeric_value`.
   - **`SUSTAINED_INVERSION`** — needs 10Y/2Y Treasury yields, which are currently pulled only MONTHLY by M1a into `state.macro_fred_latest`; pull them daily here (`mcp__FMP__economics` `treasury-rates`, the same endpoint M1a uses) **with `from_date`/`to_date` BOTH PINNED to the date you are writing the row for, and read `year10` / `year2`.** An unpinned call can return a stale prior-day curve. **Read the tenor columns BY NAME, never by column position:** the payload carries `month1/month2/month3/month6/year1/year2/year3/year5/year7/year10/year20/year30`, and Treasury.gov's own table interleaves extra bill columns, so positional reading silently returns the wrong tenor. FMP reproduces Treasury.gov's par curve; use named tenors. Yield Curve State is `INVERTED` if 10Y < 2Y else `NORMAL`; the flag is `SUSTAINED` only if the curve has been INVERTED for ≥ 18 consecutive months, else `NOT-SUSTAINED`. **THE 18-MONTH HISTORY CANNOT BE PULLED IN ONE CALL — THE ENDPOINT TRUNCATES SILENTLY.** A wide `treasury-rates` response can silently contain only ~3 months without a truncation marker. **So: never infer inversion history from a single wide-range call.** When the same-day read returns `INVERTED` and the `SUSTAINED` test therefore becomes live, pull the history as successive pinned windows of **≤ 3 months each**, walking back from today until either 18 consecutive inverted months are established or a NORMAL month is found, and **assert each window actually returned rows spanning the dates you asked for** — a window that comes back short is an incomplete read, not a gap in the curve. If the chunked walk cannot be completed this run, write `NOT-SUSTAINED` only when the same-day curve is NORMAL (where it is correct on the same-day read alone, since the promotion can apply only to an already-INVERTED curve); on an INVERTED same-day curve with an incomplete history, record the flag as UNDETERMINED in the rationale rather than asserting NOT-SUSTAINED from missing data. The same caveat binds **M1a**, which uses this identical endpoint. **Do NOT write a separate `TREASURY_10Y` row any more** (`bigquery/256`; retired park rates-axis input).
   - **`EQUITY_BREADTH`** — % of S&P 500 constituents closing above their OWN 200-day SMA; `HEALTHY` ≥ 50%, `WEAK` < 50%. **Read the observation D1 writes; apply the threshold here. Do not fetch it yourself and do not fake it.**
     - **SOURCE OF RECORD:** `SELECT numeric_value, as_of_date, rationale FROM events.regime_events WHERE scope = 'TECHNICAL_INPUT' AND key = 'EQUITY_BREADTH_PCT' ORDER BY as_of_date DESC LIMIT 1` — D1 writes that row daily (see D1's EQUITY-BREADTH OBSERVATION step). **Ordering works without a dependency edge on a normal day, not on every day.** D1 fires 16:00 MT and D2a 16:40 MT (`ops/cadence.yaml`), so on a normal day the same session's observation is already there. When D1 writes after this step (a late or catch-up D1), this step carries the previous reading under the clause below, and D2, which `depends_on` D1, then runs with the fresher reading already in `events.regime_events`.  Do not re-threshold a past row when a late reading lands: no consumer reads a past session's `EQUITY_BREADTH` signal for a decision (D2 item 4's DETECT reads `TECHNICAL_INPUT` for both breadth triggers, SL3's `regime_cell` reads only `SPY_TREND` and `VIX_REGIME`, and `state.rerisking_limb_status`, which read the latest plane, was retired by Rev 52). The same-evening case is handled where the value is used, by D2's **BREADTH LEG FRESHER THAN ITS SIGNAL** rule (ROUTER EVERY-RUN DUTIES; AR_orc's moot test cites it), which thresholds the same-session reading when one exists. This step is unchanged and stays the only writer of `TECHNICAL_SIGNAL`. D2a deliberately keeps `depends_on: []` — if D1 missed or its fetch failed, D2a still runs and degrades through the carry-forward clause below rather than blocking the whole broker reconcile on a breadth number. Apply `HEALTHY` ≥ 50 / `WEAK` < 50 to its `numeric_value` and write the result to `TECHNICAL_SIGNAL`. **The threshold application is this step's job and stays mechanical; the measurement is not.** Set `source_review_ref` to `'D1 EQUITY-BREADTH OBSERVATION as_of <that row as_of_date>'`.
     - **IF D1'S ROW IS ABSENT OR STALE — carry forward, but make the staleness MACHINE-READABLE, not just prose.** Carry the last observation, and put the **measurement age in days** in the `<note>` and in `rationale` as the literal token `breadth_measurement_age_days=<N>`, where N is `as_of_date` of this row minus the `as_of_date` of the underlying D1 observation. **When N > 5, also `CALL ops.sp_raise_alert('warning','D2a','technical_signal_stale','EQUITY_BREADTH carried <N> days since last measurement', ...)`.** Fresh `as_of_date` must not conceal stale underlying measurement.
     - **PROVENANCE CORRECTION.** M1a does not measure breadth; its prose figure is unsourced. **Never route an M1a prose figure into this key again** — that also violated `strategy/01_shared_regime_vocabulary.md`'s rule that the technical half carry no AI classification, by importing a number from the AI-scored fundamental half.
<!-- connector-tools-checker: ignore-start -->
     - **What is and is not blocked for a FROM-SCRATCH computation — do not re-probe from scratch:**
     - **PRICES ARE NOT THE BLOCKER — IBKR covers them well.** `get_price_history(contract_id, security_type='STK', step='ONE_DAY', period='ONE_YEAR', outside_rth=false)` supplies the daily bars for a 200-day SMA; IBKR is the primary price source.
     - **ENUMERATION IS THE BLOCKER.** Neither connector nor the repo/BigQuery holds a constituent universe. IBKR has no constituent/holdings/screener tool or available breadth instrument; FMP enumeration is plan-gated. FMP `marketPerformance` (`biggest-gainers`, `biggest-losers`, `most-active`, `sector-performance-snapshot`) is open, but movers are fixed top-50, unpaged and lack market cap: tail radar, never a `>=$2B / >=2%` population. Without `exchange`, `sector-performance-snapshot` is NASDAQ-only. FMP `company`/`analyst`/`quote` are symbol-allow-listed, not a market-cap cut; full US `quote` coverage begins at Starter. Do not assume only `chart`/`economics` are open.
     - **`get_price_snapshot` has no moving-average field.** `market_data_names` / `misc_statistics` contain no `priceAvg200` shortcut.
     - **NO ENDPOINT ON EITHER CONNECTOR BATCHES.** IBKR history/snapshot take one `contract_id`; FMP `chart` takes one `symbol`. A self-computed sweep needs one call per name.
     - **The ~500-call self-computation proposal is SUPERSEDED — do not reopen it from these enumeration limits.** The adopted route is one published pre-aggregated breadth reading: D1 observes, D2a classifies. An empty `$S5TH` IBKR `search_contracts` result does not prohibit reading its published value.
     - The FMP free surface is wider than `chart`/`economics`, but endpoint access and per-symbol access are separate; neither supplies constituent enumeration.
     - The historical ~500-call versioned-membership/backfill/daily-SQL proposal is superseded by published breadth; do not execute it as current instructions.
<!-- connector-tools-checker: ignore-end -->
   - **Write EVERY trading day, even when no value changed.** `as_of_date` is then a freshness signal as well as a value, so a dead-man's switch can tell "unchanged" apart from "nobody is writing this" (unchanged is distinct from unwritten). Idempotent on `(as_of_date, scope, key)` since D2a may re-run same-day.
   - **NOT best-effort in the same sense as 1d.** A failure here does not abort D2a, but it must be recorded: the router's whole technical half — every M1b divergence flag and every daily technical flip D2 acts on — reads these four rows. On failure log it in `<note>` and `CALL ops.sp_raise_alert('warning','D2a','technical_signal_stale', ...)`.
2. **Recompute the engine + embed (one call): `CALL ops.sp_daily_refresh()`** — runs `ops.sp_recompute_engine()`
   (a state-free `DELETE`+`INSERT` that rebuilds the full `perf.strategy_daily` series from `events.daily_marks` +
   the views) **and** `ops.sp_embed_pending()` in a single idempotent call. The full recompute is trivially cheap
   and absorbs any late mark/fill correction, so D2a re-runs it wholesale. `perf.kill_flags` then reads the latest row.
3. **Verify the engine row (no ledger to mirror).** The latest `perf.strategy_daily` row (`deployed_unit_value`,
   `peak_unit_value`, `current_drawdown`, `sgov_index`, `excess_vs_sgov`, `deployed_days`, `closed_trades`, `gate_n`,
   `as_of_date` = today MT) IS the record. Trust `perf.strategy_daily`, but if a day's `r_deployed` exceeds ±15% or `deployed_unit_value` leaves (0.3, 3.0)
absent a matching large market move — those signal a bad mark or an unreconciled fill, not real performance —
do NOT dead-end this in chat (unmonitored): `CALL ops.sp_raise_alert('warning','D2a','engine_mark_anomaly','<metric + value + date>','<JSON>')` so it reaches the monitored channel alongside the cash-tripwire / connector-sanity alerts on this same routine, and hold the suspect mark for re-reconciliation on the next run. *(Pre-2026-10-30 history and evidence for this rule: `ops/plan_history/D2a.md` § H-D2a-09.)*


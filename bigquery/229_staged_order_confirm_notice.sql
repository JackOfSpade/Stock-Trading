-- Staged-order confirm notice -- give the one push that had no email an email (2026-09-07).
-- Project: stock-trading-498512.
--
-- OWNER DIRECTIVE (2026-09-07), two rules, both about notification policy rather than trading:
--   1. every ntfy push must be accompanied by an email to the owner Gmail, if it is not already;
--   2. ntfy is for things that need the owner to DO something -- no "everything is fine" pings.
--
-- This file is rule 1's only BigQuery-side piece. The audit behind it found exactly one push with no
-- email counterpart anywhere in the system: alert-relay.yml's daily 13:05 UTC `orders` mode, which
-- read state.open_orders and POSTed straight to ntfy. It could not be fixed on the push side. There
-- is precisely one email channel in this system -- ops.alerts -> ops/monitoring/alert_emailer.gs,
-- polling Gmail every 2h under the owner's own Google identity -- and a GitHub Actions job cannot
-- reach it or any other mail path:
--   * no SMTP/mail secret exists (repo secrets are ALERT_WEBHOOK_URL + OFFSITE_BACKUP_GCS, nothing else),
--   * no mail-sending Action is used by any workflow,
--   * ntfy.sh's own `Email:` forwarding header is REJECTED on this topic -- probed live 2026-09-07,
--     HTTP 400 {"code":40053,"error":"anonymous email sending is not allowed"}; it now requires an
--     authenticated ntfy account, which a capability-URL topic deliberately is not,
--   * and the relay runs as the READ-ONLY WIF SA, whose only ops write grant is table-scoped to
--     ops.ci_findings -- a CI-guard findings table drained by D3's CI-FINDINGS ADJUDICATION, which is
--     the wrong queue for a trading-order reminder and would mislead that consumer.
-- So the fix is structural, not cosmetic: stop pushing a bare view and make the fact an ALERT. An
-- ops.alerts row reaches email by construction, and alert_relay.py's `alerts` mode relays it to ntfy
-- for free -- one row, both channels, instead of one push and no email. The daily `orders` cron is
-- retired in the same change (see .github/workflows/alert-relay.yml and scripts/alert_relay.py).
--
-- Rule 2 is served by the same design: the retired push re-listed EVERY unreconciled order EVERY day,
-- including craftable ones the owner had already confirmed in IBKR days earlier, because `pending` in
-- state.open_orders means "not yet filled AND reconciled" and never "not yet confirmed". The
-- replacement raises ONE alert per order, keyed on item_key alone, so a NEW order to confirm alerts
-- and an unchanged pile stays quiet. See the long comment on the new block inside the procedure.
--
-- WHAT THIS FILE CHANGES, precisely:
--   * CREATE OR REPLACE PROCEDURE ops.sp_sq_daily_staging_cap_check -- carried forward BYTE-IDENTICAL
--     from bigquery/75_scheduled_query_wrappers.sql except (a) the heartbeat literal v5 -> v6, and
--     (b) the new staged_order_awaiting_confirm block appended at the end. The two existing checks
--     (order_guard_omitted CRITICAL, order_guard_verdict_mismatch CRITICAL) are untouched -- no
--     predicate, threshold, exclusion or severity of either is altered by this file.
--   * ops.alert_policy -- registers the new category non-latching so it is allowed to auto-resolve.
--
-- NO TRADING BEHAVIOR CHANGES. Nothing here stages, cancels, sizes or gates an order. The new alert is
-- severity 'warning', and every trading gate (state.trading_enabled / _mechanical,
-- state.system_health.all_green, ops.sp_assert_trading_enabled*) counts severity = 'critical' ONLY
-- (bigquery/107_halt_echo_missed_run_gate.sql), so it cannot contribute to a halt.
--
-- APPLY ORDER: after bigquery/75_scheduled_query_wrappers.sql (defines the procedure this supersedes),
-- bigquery/34_alert_lifecycle.sql (ops.alert_policy), bigquery/10_observability.sql
-- (ops.sp_raise_alert_once) and bigquery/01_schema.sql (state.open_orders). Idempotent, safe to
-- re-apply: the CREATE OR REPLACE is total and the alert_policy INSERT is guarded on NOT EXISTS.
--
-- LOCKSTEP: the heartbeat literal below is v6; bigquery/63_scheduled_query_version_registry.sql's
-- `daily_staging_cap_check` row is bumped to v6 in the same change. scripts/check_sq_version_registry.py
-- fails CI if they disagree, and a landed mismatch raises a nightly scheduled_query_version_drift
-- WARNING that has no ops.alert_policy row and so can never auto-resolve (that exact bug already
-- happened once, 2026-08-04 commit 0b9fd49, and took two days to notice).
-- =====================================================================================================

CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_sq_daily_staging_cap_check`()
BEGIN
  CALL `stock-trading-498512.ops.sp_beat_heartbeat`('sq:daily_staging_cap_check', 'v6', 'daily_staging_cap_check.sql ran');

  -- ===================================================================================================
  -- staged_order_awaiting_confirm (WARNING) -- added 2026-09-07, owner directive on notification policy.
  --
  -- WHY IT LIVES HERE AND NOT IN THE RELAY. Until today the "you have a staged order sitting there"
  -- notice was a push-only GitHub Action: alert-relay.yml's daily 13:05 UTC `orders` mode, reading
  -- state.open_orders and POSTing straight to ntfy. That made it the ONE operator-facing notice in the
  -- whole system with no email counterpart of any kind -- neither Apps Script queries state.open_orders,
  -- and GitHub Actions cannot send mail (no SMTP secret exists, no mail action is used anywhere, and
  -- ntfy.sh rejects its own Email: forwarding header on an anonymous topic with HTTP 400). The only
  -- email channel that exists is ops.alerts -> ops/monitoring/alert_emailer.gs, so the only way to give
  -- this notice an email is to make it an ALERT. Raising it here does that and gets the push for free:
  -- alert_relay.py's `alerts` mode already relays every unresolved warning, so one row now reaches BOTH
  -- channels instead of one row reaching neither and a separate push reaching one.
  --
  -- WHY THIS PROCEDURE. daily_staging_cap_check runs DAILY at ~05:25 UTC, 7 days a week, and already
  -- owns the two other staged-order checks in this file -- so the notice lands before the US session on
  -- the same schedule the retired push used, with no new scheduled query, no new cron, and no new
  -- Actions minutes. D3 was the other candidate and is the wrong one: its cron is Mon-Fri 00:45 UTC
  -- (Sun-Thu evening Denver), so an order staged Thursday would wait until Sunday for its notice.
  --
  -- ONE ALERT PER ORDER, KEYED ON item_key ALONE -- this is the load-bearing design choice, and the
  -- reason the message carries the item_key and NOTHING ELSE. sp_raise_alert_once dedups on exact
  -- (category, message) equality over unresolved rows, so the message IS the dedup key:
  --   * item_key is stable across a persist-and-wait RE-CRAFT (Operating_Protocols.md 11 -- an unfilled
  --     DAY order is re-crafted every session under the SAME item_key, as a NEW events.queue_events row).
  --     Ticker/side/qty/limit_price are NOT: a re-craft can move qty or the reference price. Putting any
  --     of them in the message would mint a fresh alert -- and a fresh email and push -- on every daily
  --     re-craft of an order the operator already confirmed, which is exactly the alert-fatigue defect
  --     that got the old daily push retired. They go in the payload, which is never compared.
  --   * A genuinely NEW order gets a NEW item_key, so it gets its own alert, its own email and its own
  --     push, on the day it is staged. An unchanged pile stays silent. A pile that SHRINKS (one order
  --     fills, the rest still pending) raises nothing new -- an order filling needs no notification.
  --     A set-valued message (the STRING_AGG idiom the sibling order_guard_omitted check above uses)
  --     would have re-alerted on every one of those shrink events; per-order does not. That is the
  --     whole reason this check does not copy its sibling's shape.
  --
  -- SEVERITY IS DELIBERATELY warning, NEVER critical. state.trading_enabled / _mechanical /
  -- system_health.all_green and ops.sp_assert_trading_enabled* all count severity = 'critical' ONLY
  -- (bigquery/107_halt_echo_missed_run_gate.sql), so a warning can never contribute to a halt. A
  -- critical here would HALT ALL ORDER STAGING -- exits included -- over the routine fact that an order
  -- is waiting to fill, which is the normal state of the system on any day D2 staged something. The
  -- same mistake at 'critical' already halted staging once over ~$0.20 of adopted dust (see the
  -- ADOPTED-DUST EXCLUSION paragraph above); do not repeat it here.
  --
  -- AUTO-RESOLVE FIRST, THEN RAISE -- same ordering and idiom as the ci_finding block in
  -- ops.sp_sq_cadence_check. Resolving first means a still-true condition re-opens cleanly on the same
  -- run (sp_raise_alert_once only dedups against UNRESOLVED rows), while a healed one closes with no
  -- human UPDATE ever needed.
  --
  -- FAIL-CLOSED RESOLVE. The predicate resolves a row only when its item_key is BOTH readable AND
  -- positively absent from state.open_orders. A row whose payload cannot be read stays OPEN and
  -- visible rather than being silently closed -- the same polarity rule the ADOPTED-DUST exclusion
  -- above states for its own guard ("an exclusion on a safety check must never be able to evaluate to
  -- NULL"). NOT EXISTS rather than NOT IN for the same reason: NOT IN against a subquery containing a
  -- single NULL evaluates to NULL for every row and would resolve nothing, silently.
  --
  -- ORDERING AND BEST-EFFORT WRAPPER -- both directions of a shared-fate hazard, closed deliberately
  -- (2026-09-07, adversarial self-review of this same file before it landed). This block shares a
  -- procedure with two order-guard CRITICAL checks, and sp_beat_heartbeat fires as statement ONE --
  -- so a runtime error anywhere in the body leaves a FRESH beat behind while the rest of the
  -- procedure never runs, which is invisible to the beat-age dead-man's switch, and this scheduled
  -- query has no email-on-failure configured (bigquery/scheduled_queries/README.md: "no RAISE -- job
  -- never fails" describes the DESIGN, not a guarantee against a runtime fault). Two consequences,
  -- and this block is positioned and wrapped to defeat both:
  --   * IT RUNS FIRST, ahead of the two order-guard checks, so a fault in EITHER of them cannot
  --     silently swallow the staged-order notice. That was the live regression risk of moving this
  --     notice out of its own independent GitHub Actions job and into a shared procedure body: as the
  --     LAST block it inherited the failure probability of everything above it, which is strictly
  --     worse coverage than the push it replaced.
  --   * IT IS BEST-EFFORT, so the reverse cannot happen either. This block is OBSERVABILITY; the two
  --     checks below are SAFETY (order_guard_omitted / order_guard_verdict_mismatch are CRITICAL and
  --     are the only detective backstop on a bypassed pre-trade risk envelope). Running first without
  --     a handler would let a fault in a mere notification abort the procedure before either safety
  --     check ran -- trading exactly the risk this hardening is meant to remove for a worse one. Same
  --     rule as Claude_Task_Plan.md's run-logging template: "logging must not abort the routine".
  -- The failure is NOT swallowed silently: a fault raises its own staged_order_notice_failed warning,
  -- which self-heals on the next clean pass, so the machinery going dark is itself reportable and its
  -- closure path is reachable without a human UPDATE. The raise sits OUTSIDE the handler (driven off a
  -- captured variable) so it does not depend on @@error scope inside an exception block; if THAT call
  -- fails the procedure fails loudly, which is correct and is no new exposure -- the two checks below
  -- write to the same ops.alerts table and would fail identically.
  BEGIN
    DECLARE v_notice_err STRING DEFAULT NULL;

    BEGIN
    UPDATE `stock-trading-498512.ops.alerts` a
       SET resolved = TRUE,
           resolved_ts = CURRENT_TIMESTAMP(),
           resolved_note = CONCAT('auto-resolved: this staged order is no longer pending in state.open_orders (filled and reconciled, cancelled, or expired). Notification-only alert, nothing to act on (ops.sp_sq_daily_staging_cap_check). ', COALESCE(resolved_note, ''))
     WHERE NOT a.resolved
       AND a.category = 'staged_order_awaiting_confirm'
       AND JSON_VALUE(a.payload, '$.item_key') IS NOT NULL
       AND NOT EXISTS (
         SELECT 1 FROM `stock-trading-498512.state.open_orders` o
         WHERE o.item_key = JSON_VALUE(a.payload, '$.item_key'));

    -- Column list is explicit and deliberately EXCLUDES convergence_target: that column is a hard
    -- CAST(... AS NUMERIC) in state.open_orders (bigquery/01_schema.sql), and on 2026-07-26 a ticker
    -- string written into that payload field made every SELECT * against the view fail with "Invalid
    -- NUMERIC value". This check must not be takeable down by an unrelated malformed payload field.
    FOR rec IN (
      SELECT item_key, strategy, ticker, side, qty, limit_price, entry_window_close,
             instruction_id, staged_ts
      FROM `stock-trading-498512.state.open_orders`
      ORDER BY item_key
    ) DO
      CALL `stock-trading-498512.ops.sp_raise_alert_once`(
        'warning', 'scheduled.staging_cap', 'staged_order_awaiting_confirm',
        -- MESSAGE CARRIES item_key AND NOTHING ELSE -- see the dedup paragraph above before adding a
        -- ticker, a quantity, a price or a count here. Every one of those re-mints the alert on a
        -- re-craft. It still stands alone as a complete sentence, per the preamble message contract.
        -- Apostrophes are avoided throughout: GoogleSQL rejects '' as an apostrophe escape, and a
        -- template carrying one raises NOTHING rather than raising a degraded alert.
        FORMAT('Staged order awaiting fill and reconciliation: %s. Registry status pending means NOT YET FILLED AND RECONCILED, not unconfirmed -- this check has no live IBKR read and cannot tell those apart. A craftable order (instruction_id set) went to IBKR at staging and its confirm surface is the IBKR order notification itself; only a manual-entry order (instruction_id NULL) has a [Claude] Confirm order calendar event to tap. See payload for ticker, side, qty, reference price, window and instruction_id.', rec.item_key),
        TO_JSON_STRING(STRUCT(
          rec.item_key AS item_key,
          rec.strategy AS strategy,
          rec.ticker AS ticker,
          rec.side AS side,
          rec.qty AS qty,
          -- REFERENCE price, not an order price: since the market-only cutover (bigquery/100/101) every
          -- live order is MARKET and payload.limit_price is kept only for reserved-cash / notional math.
          rec.limit_price AS ref_price,
          CAST(rec.entry_window_close AS STRING) AS window_close,
          rec.instruction_id AS instruction_id,
          rec.instruction_id IS NULL AS needs_calendar_tap,
          CAST(rec.staged_ts AS STRING) AS staged_ts)));
    END FOR;

    EXCEPTION WHEN ERROR THEN
      SET v_notice_err = @@error.message;
    END;

    IF v_notice_err IS NOT NULL THEN
      -- STABLE message (no error text, no counts) -- sp_raise_alert_once dedups on exact
      -- (category, message), so interpolating the failure text here would open a fresh row on every
      -- distinct error string. The error goes in the payload.
      CALL `stock-trading-498512.ops.sp_raise_alert_once`(
        'warning', 'scheduled.staging_cap', 'staged_order_notice_failed',
        'The staged-order confirm notice block in ops.sp_sq_daily_staging_cap_check raised an error and did not run this pass, so no staged_order_awaiting_confirm alert was evaluated today and the operator got neither the email nor the push for any order waiting to fill. The two order-guard CRITICAL checks in the same procedure are unaffected (this block is best-effort by construction and runs before them). See payload for the error message.',
        TO_JSON_STRING(STRUCT(v_notice_err AS error_message)));
    ELSE
      -- Self-healing closure (reachable without a human UPDATE), matching the auto-resolve-then-raise
      -- idiom used for ci_finding in ops.sp_sq_cadence_check.
      UPDATE `stock-trading-498512.ops.alerts`
         SET resolved = TRUE, resolved_ts = CURRENT_TIMESTAMP(),
             resolved_note = CONCAT('auto-resolved: the staged-order confirm notice block completed cleanly on a later pass of ops.sp_sq_daily_staging_cap_check. ', COALESCE(resolved_note, ''))
       WHERE NOT resolved AND category = 'staged_order_notice_failed';
    END IF;
  END;

  -- order_guard_omitted (CRITICAL, not staged-rollout -- ITEM 15, self-improvement audit 2026-07-11).
  -- fn_order_guard / fn_order_guard_options is a per-order obligation on the calling routine, with no
  -- mechanical enforcement possible (no BigQuery stored procedure can gate a call to a DIFFERENT MCP
  -- tool, create_order_instruction) -- compliance depended entirely on the routine's markdown instructions
  -- being followed verbatim. state.open_orders.guard_passed (bigquery/01_schema.sql) now surfaces whether
  -- the guard's own result was embedded in the ORDER_STAGED payload; a row STAGED TODAY with guard_passed
  -- IS NULL means either the guard never ran, or it ran and the routine didn't record it -- either way
  -- the safety envelope was bypassed for that order, not merely undocumented. Unlike a soft aggregate-
  -- level warning (the now-retired daily_cap_breach check, bigquery/109_retire_daily_staging_cap.sql --
  -- 2026-07-26), a missing guard record is unambiguous -- CRITICAL immediately, no staged-rollout
  -- warning period.
  --
  -- QUERIES events.queue_events DIRECTLY, NOT state.open_orders (adversarial self-audit fix, rev
  -- 2026-07-11): state.open_orders is a PENDING-ONLY view (WHERE status='pending'), so an order staged
  -- WITHOUT the guard that then FILLED or was reconciled the same Denver day drops out of it before this
  -- check runs at ~05:25 UTC -- exactly the worst case this control exists to catch (capital deployed
  -- outside the risk envelope) silently escaping detection. queue_events is append-only: the original
  -- 'pending' ORDER_STAGED row for an order staged today is never overwritten by its later terminal-status
  -- row (a separate row, same item_key), so filtering the raw table on status='pending' still finds every
  -- staging event from today regardless of what happened to the order afterward.
  -- MESSAGE EMBEDS THE AFFECTED item_keys (adversarial self-audit fix, rev 2026-07-11): ops.sp_raise_alert_once
  -- dedupes on (category, message) WHERE NOT resolved (bigquery/10_observability.sql). A fully static message
  -- would mean that once this CRITICAL opens and is left unresolved, a LATER day's guard-omission on a
  -- DIFFERENT, newly-affected order would silently fail to re-alert (the dedup guard blocks the INSERT before
  -- the fresh payload evidence is even recorded) -- exactly the kind of new information this check exists to
  -- surface. Embedding the sorted, comma-joined item_keys makes the message (and so the dedup key) change
  -- whenever the SET of affected orders changes, while an unchanged set (the same still-open omission, re-
  -- evaluated on a later run) still correctly dedupes to a single alert, not a new one every run.
  --
  -- ADOPTED-DUST EXCLUSION (2026-08-04, alert ebfbff4e-f491-4763-81a9-ef360744cbc5 -- this check's FIRST
  -- ever firing, and a false positive). The premise above -- "guard_passed IS NULL means the guard never ran
  -- or the routine didn't record it, either way the envelope was bypassed" -- has exactly one legitimate
  -- exception, and it is not a bypass at all: an ADOPTED dust liquidation. Per Claude_Task_Plan.md's
  -- "ADOPTION OF AN UNREGISTERED DUST LIQUIDATION — PRE-FILL PATH ONLY (2026-08-02)" branch, a dust SELL can
  -- already be live at the connector with no queue_events row (operator-tapped, pre-registry, or hand-placed);
  -- D2a ADOPTS it rather than declining. D2a never calls create_order_instruction for such an order, so there
  -- is NO pre-craft moment at which fn_order_guard could have been called -- and D2a records that honestly as
  -- guard_passed=NULL with guard_reasons=[n/a - adopted, not crafted by D2a], never as a fabricated TRUE.
  -- Flagging that honest, self-documented null as a bypassed risk envelope is a category error, and an
  -- expensive one: order_guard_omitted is CRITICAL, and an open CRITICAL is itself a trading-gate input
  -- (state.trading_enabled_mechanical's blocking_criticals branch), so the false positive HALTED all order
  -- staging over two adopted dust SELLs totalling ~$0.20 of risk-REDUCING notional (IBM 0.0007sh, HCA 0.0001sh).
  -- The exclusion is deliberately narrow -- item_type='drip-dust-liquidation' AND payload.adopted='true'
  -- TOGETHER. A NORMAL D2a-CRAFTED dust SELL (same item_type, adopted absent/false) still runs the spec's
  -- STANDARD GUARD step and must still be caught here if its guard_passed is missing; and payload.adopted is
  -- written on no other order class (verified live 2026-08-04), so this cannot become a loophole elsewhere.
  --
  -- WRAPPED IN COALESCE(..., FALSE) DELIBERATELY -- this is a fail-CLOSED exclusion, and the bare form is a
  -- LIVE FAIL-OPEN BUG (caught in same-session self-review, 2026-08-04, before it could bite). Written bare as
  -- `AND NOT (item_type = '...' AND JSON_VALUE(...) = 'true')`, the inner AND evaluates to NULL whenever
  -- item_type IS NULL, NOT NULL is NULL, and WHERE NULL DROPS THE ROW -- silently excluding it from a CRITICAL
  -- detector. events.queue_events DOES carry ORDER_STAGED rows with NULL item_type (verified live: item_key
  -- 'entry-TSM-D-20260717', 2026-07-20, 1 of 82 ORDER_STAGED rows), so this is reachable, not theoretical: a
  -- future NULL-item_type order staged WITHOUT a guard -- precisely the bypass this check exists to catch --
  -- would have been swallowed. COALESCE(..., FALSE) makes the exclusion fire ONLY when both conjuncts are
  -- provably TRUE; anything unknown stays IN the detector and gets flagged. When adding any future exclusion
  -- here, keep that polarity: an exclusion on a safety check must never be able to evaluate to NULL.
  IF EXISTS (
    SELECT 1 FROM `stock-trading-498512.events.queue_events`
    WHERE queue = 'ORDER_STAGED' AND LOWER(status) = 'pending'
      AND DATE(event_ts, 'America/Denver') = CURRENT_DATE('America/Denver')
      AND JSON_VALUE(payload, '$.guard_passed') IS NULL
      -- ADOPTED-DUST EXCLUSION -- see the paragraph above. Kept byte-identical across all three
      -- predicates below so the message/payload can never disagree with this gate.
      AND NOT COALESCE(item_type = 'drip-dust-liquidation' AND JSON_VALUE(payload, '$.adopted') = 'true', FALSE)
  ) THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'scheduled.staging_cap', 'order_guard_omitted',
      (SELECT FORMAT(
          'One or more orders staged today have no recorded fn_order_guard/fn_order_guard_options result -- the pre-craft risk envelope may have been bypassed for these orders: %s.',
          -- COALESCE defends against FORMAT('%s', NULL) returning a hard SQL NULL (verified) if this ever
          -- somehow evaluated over zero rows despite the IF EXISTS above having matched -- ops.alerts.message
          -- is NOT NULL, so an unguarded NULL here would error the whole scheduled query (adversarial
          -- self-audit fix, rev 2026-07-11; confirmed not currently reachable -- this predicate is
          -- byte-identical to the IF EXISTS guard and events.queue_events is append-only -- but free to close).
          COALESCE(STRING_AGG(DISTINCT item_key, ', ' ORDER BY item_key), 'UNKNOWN'))
       FROM `stock-trading-498512.events.queue_events`
       WHERE queue = 'ORDER_STAGED' AND LOWER(status) = 'pending'
         AND DATE(event_ts, 'America/Denver') = CURRENT_DATE('America/Denver')
         AND JSON_VALUE(payload, '$.guard_passed') IS NULL
         AND NOT COALESCE(item_type = 'drip-dust-liquidation' AND JSON_VALUE(payload, '$.adopted') = 'true', FALSE)),
      (SELECT TO_JSON_STRING(ARRAY_AGG(STRUCT(
          item_key, strategy, ticker,
          UPPER(JSON_VALUE(payload, '$.side')) AS side,
          CAST(JSON_VALUE(payload, '$.qty') AS NUMERIC) AS qty,
          CAST(JSON_VALUE(payload, '$.limit_price') AS NUMERIC) AS limit_price,
          event_ts AS staged_ts)))
       FROM `stock-trading-498512.events.queue_events`
       WHERE queue = 'ORDER_STAGED' AND LOWER(status) = 'pending'
         AND DATE(event_ts, 'America/Denver') = CURRENT_DATE('America/Denver')
         AND JSON_VALUE(payload, '$.guard_passed') IS NULL
         AND NOT COALESCE(item_type = 'drip-dust-liquidation' AND JSON_VALUE(payload, '$.adopted') = 'true', FALSE)));
  END IF;

  -- order_guard_verdict_mismatch (CRITICAL, DEF-3 order-guard TRUTHFULNESS backstop -- defense-in-depth,
  -- 2026-07-17; recompute updated 2026-07-22 for the pre-trade-rail strip, bigquery/104_strip_pretrade_
  -- rails.sql). The order_guard_omitted check directly above is the sole detective backstop, but it only
  -- verifies that payload.guard_passed IS PRESENT -- never that it is TRUTHFUL. A routine could stage an
  -- order carrying guard_passed=true beside a malformed qty/limit_price/order_type the guard would
  -- actually REJECT, and order_guard_omitted (which keys only on the field's presence) would wave it
  -- through. This check RECOMPUTES the market-only, 5-arg analytics.fn_order_guard (owner directive
  -- 2026-07-22, bigquery/104_strip_pretrade_rails.sql -- ALL liquidity + sizing pre-trade rails removed;
  -- was the 9-arg expected-shortfall guard of bigquery/100_market_only_order_guard.sql) from each row's
  -- OWN payload: strategy, side, qty, limit_price (passed as p_ref_price -- there is no limit price left
  -- to band against), order_type hardcoded to 'MARKET' (this recompute always checks what a market-only
  -- order must have been). There are no liquidity inputs left to read: adv_usd/spread_bps/sigma_daily and
  -- p_is_park are no longer guard parameters at all (the ADV/participation/expected-shortfall gate and the
  -- park 1.10x-NAV magnitude backstop are both gone) -- every staged equity/park row is recomputed
  -- identically, a market-only + qty/ref-price sanity check, with no park-vs-non-park distinction left to
  -- draw. RAISEs CRITICAL when the recomputed verdict is FALSE (the guard would have rejected), whether
  -- the row carried a forged guard_passed=true, an honest guard_passed=false the routine staged anyway, or
  -- no guard record at all.
  --
  -- HONEST LIMITATION (read before trusting this as a gate). BigQuery has NO independent source of order
  -- truth: the REAL order goes to IBKR via a DIFFERENT MCP tool (create_order_instruction) that no
  -- BigQuery stored procedure can see or gate (the same 'no SP can gate a call to a different MCP tool'
  -- limitation the order_guard_omitted header states). This recompute therefore catches an INCONSISTENT
  -- forgery -- guard_passed=true left beside HONEST qty/limit_price/order_type the guard would reject, a
  -- guard that returned FALSE but the order was staged, or a guard never called on a malformed order -- but
  -- it CANNOT catch a fully-COHERENT forgery that ALSO fakes qty/limit_price in the payload to match the
  -- fabricated guard_passed=true (the recompute would then read the faked-consistent numbers and pass). It
  -- raises the bar (an attacker must now forge the order fields consistently, not just the flag); it is NOT
  -- a complete gate. Queries events.queue_events DIRECTLY (append-only), same rationale as
  -- order_guard_omitted: a same-day-filled order must not drop out of a pending-only view before this runs.
  BEGIN
    DECLARE mismatch_keys STRING DEFAULT '';
    DECLARE mismatch_json STRING DEFAULT '';
    DECLARE v_passed BOOL;
    DECLARE v_reasons STRING;
    FOR rec IN (
      SELECT
        item_key,
        strategy,
        COALESCE(UPPER(JSON_VALUE(payload, '$.side')), 'BUY') AS side,
        SAFE_CAST(JSON_VALUE(payload, '$.qty') AS NUMERIC) AS qty,
        SAFE_CAST(JSON_VALUE(payload, '$.limit_price') AS NUMERIC) AS limit_price,
        JSON_VALUE(payload, '$.guard_passed') AS recorded_guard_passed
      FROM `stock-trading-498512.events.queue_events`
      WHERE queue = 'ORDER_STAGED' AND LOWER(status) = 'pending'
        AND DATE(event_ts, 'America/Denver') = CURRENT_DATE('America/Denver')
        -- qty/limit_price IS NOT NULL both sanity-filters malformed payloads AND is the only remaining
        -- thing that distinguishes an equity ORDER_STAGED row (qty/limit_price) from an options one
        -- (contracts/ref_premium/max_loss_dollars -- a different payload shape this recompute does not
        -- touch, left to order_guard_omitted's presence-only check above). No adv/liquidity/park-based
        -- eligibility filter remains -- with no liquidity or park-NAV rail left (owner directive
        -- 2026-07-22, bigquery/104_strip_pretrade_rails.sql), every staged equity/park row is recomputed
        -- identically, so there is no longer a distinct eligibility condition to gate the recompute on.
        AND SAFE_CAST(JSON_VALUE(payload, '$.qty') AS NUMERIC) IS NOT NULL
        AND SAFE_CAST(JSON_VALUE(payload, '$.limit_price') AS NUMERIC) IS NOT NULL
    ) DO
      -- Per-row recompute. rec.* are scripting-variable field accesses (constant per iteration), a valid
      -- table-function argument form (verified: fn_order_guard accepts non-constant scalar arguments).
      -- order_type is hardcoded to 'MARKET' -- this recompute always checks what a market-only order must
      -- have been (owner directive 2026-07-21, bigquery/100_market_only_order_guard.sql), independent of
      -- whatever order_type (if any) the original payload recorded. The guard call itself is the 5-arg
      -- bigquery/104_strip_pretrade_rails.sql signature (owner directive 2026-07-22): no is_park / adv_usd
      -- / spread_bps / sigma_daily arguments remain to pass.
      SET (v_passed, v_reasons) = (
        SELECT AS STRUCT passed, TO_JSON_STRING(reasons)
        FROM `stock-trading-498512.analytics.fn_order_guard`(
          rec.strategy, rec.side, rec.qty, rec.limit_price, 'MARKET')
      );
      IF NOT COALESCE(v_passed, FALSE) THEN
        SET mismatch_keys = mismatch_keys || IF(mismatch_keys = '', '', ', ') || rec.item_key;
        SET mismatch_json = mismatch_json || IF(mismatch_json = '', '', ',') ||
          TO_JSON_STRING(STRUCT(
            rec.item_key AS item_key, rec.strategy AS strategy, rec.side AS side,
            rec.qty AS qty, rec.limit_price AS limit_price,
            rec.recorded_guard_passed AS recorded_guard_passed,
            v_passed AS recomputed_passed, v_reasons AS recomputed_reasons));
      END IF;
    END FOR;
    -- DEDUP-CRITICAL, same convention as order_guard_omitted above: the message embeds the sorted set of
    -- affected item_keys so ops.sp_raise_alert_once's (category, message) dedup re-alerts when the SET of
    -- offending orders changes, but collapses an unchanged still-open mismatch to one row. mismatch_keys is
    -- accumulated in the FOR loop's own iteration order (item_key); daily-changing detail lives in payload.
    IF mismatch_keys != '' THEN
      CALL `stock-trading-498512.ops.sp_raise_alert_once`(
        'critical', 'scheduled.staging_cap', 'order_guard_verdict_mismatch',
        CONCAT('Order-guard verdict RECOMPUTE mismatch -- order(s) staged today whose OWN payload ',
               '(strategy/qty/limit_price) independently re-run through analytics.fn_order_guard return ',
               'FALSE (the guard would REJECT), yet the order was staged -- in some cases beside a recorded ',
               'guard_passed=true. This is an INCONSISTENT order-guard record (a forged/omitted guard left ',
               'beside honest order fields), not merely an undocumented one: ', mismatch_keys,
               '. See payload for per-order recomputed reasons.'),
        CONCAT('[', mismatch_json, ']'));
    END IF;
  END;

END;

-- =====================================================================================================
-- ops.alert_policy -- register staged_order_awaiting_confirm as NON-LATCHING.
--
-- ops.alert_policy is a FAIL-CLOSED allowlist: a category ABSENT from it is latching by construction
-- and ops.sp_auto_resolve_alerts will never touch it. Registration here does not itself resolve
-- anything -- every rule in sp_auto_resolve_alerts is hardcoded to a specific category and none of
-- them covers this one. The actual resolve is the in-procedure UPDATE above, which runs each daily
-- pass. This row is what SANCTIONS that mechanical close and documents it where an auditor reading
-- the alert board will look, exactly as bigquery/223 does for regime_restore_blocked.
--
-- Guarded on NOT EXISTS per-category (bigquery/223 / bigquery/204 shape), NOT on the whole-table
-- emptiness guard bigquery/34's original seed used -- that one only ever fires once, on an empty
-- table, and would silently no-op here.
--
-- The SELECT ... FROM UNNEST([...]) shape is required rather than SELECT <literals> WHERE NOT EXISTS:
-- a WHERE with no FROM is illegal GoogleSQL, and is what broke bigquery/133 live.
-- =====================================================================================================
INSERT INTO `stock-trading-498512.ops.alert_policy` (category, latching, resolve_rule, note)
SELECT p.category, p.latching, p.resolve_rule, p.note
FROM UNNEST([
  STRUCT('staged_order_awaiting_confirm' AS category, FALSE AS latching,
         'Auto-resolves in-procedure: ops.sp_sq_daily_staging_cap_check (bigquery/229_staged_order_confirm_notice.sql) closes the row on its next daily pass once the item_key named in payload.item_key is no longer present in state.open_orders -- i.e. the order filled and reconciled, was cancelled, or expired. NOT covered by any ops.sp_auto_resolve_alerts rule (those are hardcoded to missing_dependency / missed_run / routine_stalled / catchup_refire_blocked / staleness / the six roster notices), and NOT on the cadence_check 7-day auto-age list; latching=FALSE only SANCTIONS the mechanical close. The resolve is fail-closed: a row whose payload.item_key cannot be read stays OPEN rather than being silently closed.' AS resolve_rule,
         'STAGED-ORDER CONFIRM NOTICE, registered 2026-09-07 alongside the check that raises it. Notification-only: it reports that a staged order is waiting to fill and reconcile, which is the normal state of the book on any day D2 staged something -- it is NOT a fault and needs no human UPDATE. Deliberately warning, never critical: every trading gate counts criticals only, so a critical here would halt ALL order staging (exits included) over routine activity. Replaces the retired alert-relay.yml `orders` push (daily 13:05 UTC), which had no email counterpart at all; routing the fact through ops.alerts is what gives it one, via alert_emailer.gs. One alert per item_key, and the message carries the item_key and nothing else, so a persist-and-wait re-craft (same item_key, possibly new qty/ref price) does NOT mint a duplicate notice.' AS note)
]) AS p
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.ops.alert_policy` e WHERE e.category = p.category
);

-- Staged-order notice auto-resolve: de-correlate the read that made it fail every day (2026-09-11).
-- Project: stock-trading-498512.
--
-- THE INCIDENT. bigquery/233_staged_order_window_dead_on_arrival.sql went live between the 2026-09-10
-- and 2026-09-11 05:25 UTC runs of ops.sp_sq_daily_staging_cap_check (ops.heartbeat records the first
-- 'v7' beat at 2026-09-11T05:25:04Z). On that FIRST run the new staged_order_window_dead_on_arrival
-- AUTO-RESOLVE statement failed, verbatim:
--     Query error: Correlated subqueries that reference other tables are not supported unless they can
--     be de-correlated, such as by transforming them into an efficient JOIN.
--     at [stock-trading-498512.ops.sp_sq_daily_staging_cap_check:154:5]
-- and the block's best-effort handler turned that into the first-ever
-- WARNING scheduled.staging_cap / staged_order_notice_failed (alert d0bf2568, 2026-09-11T05:25:18Z).
--
-- 233's OWN DESIGN HELD UP, and that is worth recording before the defect is described. The
-- statement-level job trace for that run (INFORMATION_SCHEMA.JOBS_BY_PROJECT, child jobs of the
-- 05:25 UTC script, read 2026-09-11) shows the block behaved exactly as 233's header said it would:
--     _0  INSERT ops.heartbeat                                              DONE
--     _1  UPDATE ops.alerts   -- staged_order_awaiting_confirm RESOLVE      DONE
--     _2  SELECT state.open_orders -- awaiting-confirm FOR cursor           DONE
--     _3.._6  sp_raise_alert_once x2 -- both awaiting-confirm notices RAISED DONE
--     _7  UPDATE ops.alerts   -- window_dead_on_arrival RESOLVE   error_reason="invalidQuery"  <-- HERE
--     _8/_9  sp_raise_alert_once -- staged_order_notice_failed RAISED        DONE
--     _10.._13 order_guard_omitted predicate + verdict-mismatch recompute x2 DONE, clean
-- So: (a) the OLDER notice -- staged_order_awaiting_confirm -- completed in full BEFORE the new
-- statement ran and was not harmed, which is precisely the "POSITION IS LOAD-BEARING" ordering 233
-- argued for; (b) the two order-guard CRITICAL checks both ran and evaluated cleanly, because the
-- block is best-effort and runs ahead of them; and (c) the machinery going dark was itself reported
-- within one day by a real, stable, dedup-safe alert. The only thing 233 got wrong was one SQL shape.
--
-- THE DEFECT, precisely. The auto-resolve read its key set with a CORRELATED NOT EXISTS whose inner
-- source is state.staged_order_window_invalid -- a VIEW CONTAINING A LEFT JOIN (to
-- state.market_calendar, for the 13:00-vs-16:00 ET early-close instant). BigQuery can only admit a
-- correlated subquery it can rewrite into a join, and it cannot do that through a joined view, so the
-- statement is rejected at ANALYSIS time. That makes this a deterministic, data-independent failure:
-- it did not depend on any row existing, it could never have "worked on a good day", and it re-fails
-- identically on every future run. state.staged_order_window_invalid was EMPTY on 2026-09-11 and the
-- statement still failed.
--
-- WHY THE SIBLING NEVER HAD THIS PROBLEM, and what the actual discriminator is. The
-- staged_order_awaiting_confirm resolve directly above is the SAME statement shape -- correlated
-- NOT EXISTS on JSON_VALUE(a.payload, '$.item_key') -- and has run cleanly since 2026-09-07. Measured
-- by dry-run across every correlated subquery in the live substrate (2026-09-11, 9 found):
--     state.open_orders            QUALIFY ROW_NUMBER() window function, NO join   -> PASSES
--     state.connector_tool_drift   UNION ALL of two SELECTs, NO join               -> PASSES
--     state.ci_findings_open       ROW_NUMBER() + LEFT JOIN + inner JOIN           -> PASSES, but its
--                                  NOT EXISTS is UNcorrelated (a flat "is the view empty" test), so
--                                  there is nothing to de-correlate in the first place
--     state.staged_order_window_invalid  LEFT JOIN, correlated                     -> FAILS
-- So neither a window function nor a UNION ALL defeats de-correlation, and a joined view is harmless
-- as long as the subquery is NOT correlated. The failing combination is specifically
-- CORRELATION + AN INNER SOURCE THAT CONTAINS A JOIN. Do not reduce this to "avoid correlated
-- subqueries" -- that would be cargo cult, and eight of the nine are fine.
--
-- THE FIX. Read the view ONCE into an ARRAY<STRING> scripting variable, then test membership against
-- UNNEST of that variable. UNNEST of a scripting variable is not a table reference at all, so the
-- planner has nothing to de-correlate and the inner source's shape stops mattering permanently --
-- state.staged_order_window_invalid can gain any join, CTE or window function later without
-- re-breaking this statement. Verified by dry-run INSIDE a CREATE PROCEDURE body (strict_mode, which
-- is the validation that actually runs at apply): accepted.
--
-- PRIOR ART IN THIS REPO, and why this file does NOT copy it. This is the SECOND time this exact
-- BigQuery limitation has bitten here. The first was state.catchup_refire_readiness (commit ff08a8b,
-- 2026-07-17; the account survives in bigquery/59_catchup_autofire.sql's header): a correlated
-- NOT EXISTS against a CTE stacked beside other correlated subqueries, same verbatim error, and it
-- was "Rewritten as LEFT JOIN + IS NULL (the standard BigQuery workaround for this exact
-- limitation)". That idiom is right THERE and wrong HERE, for a structural reason worth stating so
-- the two do not get reconciled by someone later: 59's object is a VIEW -- a SELECT, where an
-- anti-join is directly expressible. This one is a DML UPDATE, and GoogleSQL UPDATE has no FROM/JOIN
-- clause to hang a LEFT JOIN off; the nearest translation is to move the anti-join into an
-- UNcorrelated `item_key IN/NOT IN (SELECT ... LEFT JOIN ... WHERE ... IS NULL)`, which lands back on
-- NOT IN and its NULL trap -- the thing 229 and 233 deliberately wrote around. Pre-materializing into
-- an array is the DML-shaped form of the same anti-join. A THIRD working idiom also exists in the live
-- substrate for reference -- ops.sp_sq_safety_critical_dml_watch splits one inequality-correlated
-- EXISTS into two uncorrelated ones joined by AND. All three are legitimate; pick by statement kind.
-- ALSO NOTE bigquery/59's other observation, which is exactly why this defect could land: that bug
-- "only surfaces the first time anyone actually reads the view", i.e. at QUERY time, not at CREATE
-- time. A PROCEDURE behaves differently and better -- CREATE OR REPLACE PROCEDURE validates its body
-- in strict_mode and WOULD have rejected this statement at apply time, which is precisely the check
-- the leading-DDL suppression described below disabled.
--
-- WHY `NOT EXISTS (SELECT 1 FROM UNNEST(...))` AND NOT `NOT IN UNNEST(...)`. Both de-correlate and
-- both were dry-run and accepted. NOT EXISTS is chosen because it keeps 233's and 229's documented
-- NULL-safety idiom intact rather than arguing around it: those headers state, correctly, that "NOT IN
-- against a subquery containing a single NULL evaluates to NULL for every row and would resolve
-- nothing, silently", and NOT EXISTS is structurally two-valued -- it can never return NULL no matter
-- what the array holds. The array is ALSO built NULL-free (WHERE item_key IS NOT NULL) so the property
-- holds twice over, by construction and by value. Switching to NOT IN would have made a statement
-- whose safety depends on an invariant maintained somewhere else; this one does not.
--
-- FAIL-CLOSED POLARITY IS PRESERVED EXACTLY, which is the property that matters for a resolve on a
-- notice the operator may need to act on. A row is still closed ONLY when its item_key is BOTH
-- readable (JSON_VALUE(...) IS NOT NULL, unchanged) AND positively absent from the key set. An
-- unreadable payload still leaves the row OPEN and visible. And a FAULT reading the view still throws
-- into the same best-effort handler it always did, because the SET sits INSIDE that block -- it does
-- not quietly degrade to "resolve nothing" or, worse, "resolve everything". An empty view resolves
-- every open row, which is correct and is the healthy steady state.
--
-- WHAT IS *NOT* CHANGED HERE, deliberately. The working staged_order_awaiting_confirm resolve keeps
-- its correlated NOT EXISTS against state.open_orders, byte-identical. It is correct today (measured
-- above, not assumed), and speculatively rewriting a working statement inside a procedure that also
-- carries two CRITICAL order-guard checks buys nothing this file's real protection does not already
-- buy. Its residual hazard is narrow and now written down: IF state.open_orders ever gains a JOIN,
-- that statement will start failing exactly the way this one did, and because it is the FIRST
-- statement in the best-effort block it would take BOTH notices down with it, not one. Anyone adding
-- a join to state.open_orders should convert that resolve to the same pre-materialized shape in the
-- same change. The durable, class-wide guard is scripts/check_sql_dryrun.py's new per-statement pass
-- (landed with this file), which dry-runs each statement AFTER the first DDL individually and blocks
-- on this exact analysis error -- so a future instance is caught mechanically rather than by anyone
-- remembering this paragraph.
--
-- HOW THIS REACHED LIVE GREEN -- the landing-gate gap, measured and closed in this same change.
-- bigquery/233 creates a VIEW and then a PROCEDURE in one file, and the whole file is applied and
-- validated as ONE multi-statement script. BigQuery stops SEMANTICALLY analysing a script after its
-- first DDL statement (this repo's own verified limitation, check_sql_dryrun.py's "KNOWN, VERIFIED
-- LIMITATION" section, 2026-08-03), so the leading CREATE VIEW suppressed body validation of the
-- CREATE PROCEDURE behind it. Reproduced both directions on 2026-09-11:
--     CREATE PROCEDURE <bad body>                        alone  -> dry run FAILS, naming this error
--                                                                  ("Error validating procedure body")
--     CREATE VIEW ...; CREATE PROCEDURE <same bad body>  script -> dry run CLEAN
-- That is why check_sql_dryrun.py passed, and it is also why BigQuery ACCEPTED the CREATE at apply
-- time: an un-executable body was stored because nothing ever validated it on its own. The fix is to
-- dry-run the blinded statements individually, which is what this change adds to that checker.
--
-- LOCKSTEP: the heartbeat literal below is v8; bigquery/63_scheduled_query_version_registry.sql's
-- `daily_staging_cap_check` row is bumped to v8 in this same change. scripts/check_sq_version_registry.py
-- fails CI if they disagree, and a landed mismatch raises a nightly scheduled_query_version_drift
-- WARNING that has no ops.alert_policy row and so can never auto-resolve.
--
-- SCOPE: this file changes ONE statement's shape and the heartbeat literal. No predicate, threshold,
-- exclusion, severity, message or payload anywhere in the procedure moves -- both notices keep their
-- categories and their exact message templates (so sp_raise_alert_once dedup behaviour is unchanged,
-- and the already-open alerts from 2026-09-11 are the same rows these statements will resolve), and
-- the two order-guard CRITICAL checks (order_guard_omitted / order_guard_verdict_mismatch) are carried
-- forward byte-identical. No trading behaviour changes. state.staged_order_window_invalid is NOT
-- redefined here, so dbt/models/state/staged_order_window_invalid.sql stays valid as generated.
--
-- EXPECTED EFFECT ON APPLY: the next pass completes the whole block, so the ELSE branch auto-resolves
-- staged_order_notice_failed (d0bf2568) with no human UPDATE, and staged_order_window_dead_on_arrival
-- becomes able to both raise and resolve for the first time. Until then that WARNING re-opens daily --
-- the root cause is a query-shape defect, not a transient, so it cannot self-heal on its own.
-- =====================================================================================================
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_sq_daily_staging_cap_check`()
BEGIN
  CALL `stock-trading-498512.ops.sp_beat_heartbeat`('sq:daily_staging_cap_check', 'v8', 'daily_staging_cap_check.sql ran');

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
    -- PRE-MATERIALIZED KEY SET -- the fix this file exists for (2026-09-11). The
    -- staged_order_window_dead_on_arrival auto-resolve below used to read its key set with a
    -- CORRELATED `NOT EXISTS (SELECT 1 FROM state.staged_order_window_invalid w WHERE w.item_key =
    -- JSON_VALUE(a.payload, '$.item_key'))`. BigQuery REJECTS that at query-analysis time:
    --     Correlated subqueries that reference other tables are not supported unless they can be
    --     de-correlated, such as by transforming them into an efficient JOIN.
    -- The statement therefore failed on EVERY run, deterministically, from the moment bigquery/233
    -- went live -- see this file's header for the full incident. Reading the view ONCE into an
    -- ARRAY<STRING> and testing membership against UNNEST of that array removes the correlation
    -- entirely: UNNEST of a scripting variable is not a table reference, so there is nothing left
    -- for the planner to fail to de-correlate. Populated inside the best-effort block below (not
    -- here), so a fault READING the view is still caught by that block's handler exactly as before.
    -- Capacity is a non-issue: a BigQuery scripting variable holds up to 1 MB and state.open_orders
    -- is the set of orders still PENDING -- single digits in this system's whole history.
    DECLARE v_dead_window_keys ARRAY<STRING> DEFAULT [];

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

    -- staged_order_window_dead_on_arrival -- auto-resolve, same fail-closed shape and same
    -- resolve-before-raise ordering as the sibling above.
    --
    -- POSITION IS LOAD-BEARING, DO NOT MOVE THIS ABOVE THE awaiting-confirm FOR LOOP (adversarial
    -- self-review of this file, 2026-09-10 -- the first cut had it there and it was a real coverage
    -- regression against bigquery/229). This is the FIRST statement in the block that reads the NEW
    -- view. Everything belonging to staged_order_awaiting_confirm -- its resolve AND its raise --
    -- now completes BEFORE it. In 229 that resolve and raise were adjacent with nothing between
    -- them; splicing a new dependency in between would mean a fault reading
    -- state.staged_order_window_invalid (the view absent, dropped, or unreadable -- and it is not
    -- live until this very file is applied) throws into the shared handler BEFORE the
    -- awaiting-confirm notice is raised, silently costing that day's notice for an order whose only
    -- confirm surface may be a calendar tap. A NEW feature must not be able to take down the
    -- OLDER notice it was merely appended beside; ordered this way it cannot. TWO distinct healings close this row and
    -- the single NOT EXISTS covers both, because state.staged_order_window_invalid encodes the whole
    -- predicate: (1) the row went terminal (filled / expired / abandoned) and left state.open_orders,
    -- or (2) its entry_window_close was REPAIRED FORWARD to a session the order can still trade in
    -- (Claude_Task_Plan.md STEP 0 branch (c), MIS-SET WINDOW REPAIR). Neither healing needs a human
    -- UPDATE. Fail-closed: a row whose payload.item_key cannot be read stays OPEN rather than being
    -- silently closed, and NOT EXISTS rather than NOT IN so a single NULL cannot make every row
    -- evaluate NULL and resolve nothing.
    -- READ THE VIEW ONCE, HERE, into v_dead_window_keys -- then the UPDATE below tests membership
    -- against UNNEST of that array instead of correlating a subquery into the view. This SET is the
    -- FIRST statement in the block that touches state.staged_order_window_invalid, and it sits where
    -- the old correlated UPDATE sat: AFTER the awaiting-confirm resolve AND its FOR loop, never
    -- before them. That ordering is the load-bearing property the comment above restates -- a fault
    -- reading this NEW view must not be able to cost the OLDER staged_order_awaiting_confirm notice
    -- its day. Keep the SET and the UPDATE adjacent and in this order if either is ever edited.
    -- DISTINCT because only membership is tested; WHERE item_key IS NOT NULL so the array can never
    -- contain a NULL element, which is what keeps the NOT EXISTS below a strict two-valued test.
    SET v_dead_window_keys = ARRAY(
      SELECT DISTINCT item_key
      FROM `stock-trading-498512.state.staged_order_window_invalid`
      WHERE item_key IS NOT NULL);

    UPDATE `stock-trading-498512.ops.alerts` a
       SET resolved = TRUE,
           resolved_ts = CURRENT_TIMESTAMP(),
           resolved_note = CONCAT('auto-resolved: this staged order no longer has an entry window that closed before it was staged -- either the row went terminal and left state.open_orders, or its entry_window_close was repaired forward to a session it can still trade in (ops.sp_sq_daily_staging_cap_check). ', COALESCE(resolved_note, ''))
     WHERE NOT a.resolved
       AND a.category = 'staged_order_window_dead_on_arrival'
       AND JSON_VALUE(a.payload, '$.item_key') IS NOT NULL
       AND NOT EXISTS (
         SELECT 1 FROM UNNEST(v_dead_window_keys) AS k
         WHERE k = JSON_VALUE(a.payload, '$.item_key'));

    -- ===================================================================================================
    -- staged_order_window_dead_on_arrival (WARNING) -- added 2026-09-10, bigquery/233.
    --
    -- WHAT IT CATCHES. An ORDER_STAGED row whose entry_window_close names a session that had ALREADY
    -- CLOSED at the moment the order was staged -- overwhelmingly a post-close craft (D2a stages at
    -- ~16:5x MT) that stamped the window with the CRAFT day instead of the session the DAY instruction
    -- will actually reach. Such a row is born outside its own window and can never trade inside it.
    --
    -- WHY IT MATTERS, precisely -- this is NOT a cosmetic date. entry_window_close is the field D2a
    -- STEP 0 branches on (Claude_Task_Plan.md / task_plan/D2a.md, "staged-order registry reconciliation"):
    --   branch (b) window still open + unfilled (entry_window_close >= today) -> RE-CRAFT under the
    --              SAME item_key -- the persist-and-wait policy (Operating_Protocols.md 11).
    --   branch (c) window closed + unfilled (entry_window_close < today)      -> TERMINAL expired.
    -- A born-dead window makes branch (b) UNREACHABLE for that row by construction: it is already in
    -- the past at the next reconciliation, so the row is terminally expired after a single session
    -- instead of persisting. The intent the staged-order registry exists to make durable -- "a staged
    -- order leaves the registry only by filling or by a logged terminal decision, never by a silent
    -- drop" -- is silently downgraded to abandon-after-one-session, with a correctly-formed decision
    -- log entry that reads as a normal expiry. Nothing else in the system distinguishes the two.
    --
    -- MEASURED, not hypothetical (live queue_events, read 2026-09-10): EIGHT still-pending stagings
    -- carried a window that had already closed -- cover-VOO-20260720, cover-VOO-20260721,
    -- sweep-SGOV-20260727, cover-SGOV-20260728, sweep-VOO-20260908, park-derisk-sell-VOO-20260908,
    -- park-derisk-buy-SGOV-20260908, sweep-VOO-20260909 -- 8 of 67 post-close stagings. The one that
    -- bit: sweep-VOO-20260908 (BUY 0.1393 VOO, staged 2026-09-08 22:53 UTC, window 2026-09-08) did not
    -- fill on the 09-09 open and was terminally expired by D2a 2026-09-09 under branch (c) rather than
    -- re-crafted, and a fresh sweep-VOO-20260909 was minted in its place. Because the park sweep names
    -- its item_key by DATE, the replacement is a NEW item_key -- so it minted a NEW
    -- staged_order_awaiting_confirm row, a NEW email and a NEW ntfy push, for what is materially the
    -- same waiting sweep. That is precisely the alert-fatigue defect the sibling block above was
    -- designed to prevent, re-entering through the item_key channel instead of the message channel.
    --
    -- SEVERITY IS warning, NEVER critical -- same reasoning as the sibling above, verbatim: every
    -- trading gate (state.trading_enabled / _mechanical, state.system_health.all_green,
    -- ops.sp_assert_trading_enabled*) counts severity = 'critical' ONLY (bigquery/107), so a critical
    -- here would HALT ALL ORDER STAGING over a mis-stamped date field on one order.
    --
    -- MESSAGE CARRIES item_key AND NOTHING ELSE, for the same dedup reason the sibling documents at
    -- length: sp_raise_alert_once dedups on exact (category, message), and item_key is the only field
    -- stable across a re-craft. The dates go in the payload, which is never compared. Apostrophes are
    -- avoided throughout -- GoogleSQL rejects '' as an apostrophe escape and a template carrying one
    -- raises NOTHING rather than a degraded alert.
    --
    -- THE PREDICATE LIVES IN A VIEW (state.staged_order_window_invalid, defined above), not inline
    -- here, so the RAISE below and the RESOLVE above cannot drift apart -- the classic failure mode
    -- of a resolve whose predicate is a hand-maintained negation of the raise. It is also what D2a
    -- reads mechanically at STEP 0 to detect a mis-set window instead of re-deriving the arithmetic.
    -- ===================================================================================================
    FOR rec IN (
      SELECT item_key, strategy, ticker, side, qty, limit_price, entry_window_close,
             window_close_instant, instruction_id, staged_ts
      FROM `stock-trading-498512.state.staged_order_window_invalid`
      ORDER BY item_key
    ) DO
      CALL `stock-trading-498512.ops.sp_raise_alert_once`(
        'warning', 'scheduled.staging_cap', 'staged_order_window_dead_on_arrival',
        FORMAT('Staged order was born outside its own entry window: %s. It was staged at or after the close of the very session its entry_window_close names, so it can never trade inside that window. At the next D2a STEP 0 staged-order registry reconciliation this row matches branch (c) WINDOW CLOSED plus UNFILLED instead of branch (b) WINDOW STILL OPEN, so it is terminally expired after a single session rather than re-crafted under the same item_key, and the persist-and-wait policy is skipped without anything else in the system recording that it was. A DAY instruction crafted after the close reaches the NEXT trading session, so a post-close craft must set entry_window_close to at least state.trading_day_today.next_trading_day, never the craft day. Repair the window forward or set the row terminal deliberately; see payload for the staged timestamp, the window, and the instant that window closed.', rec.item_key),
        TO_JSON_STRING(STRUCT(
          rec.item_key AS item_key,
          rec.strategy AS strategy,
          rec.ticker AS ticker,
          rec.side AS side,
          rec.qty AS qty,
          rec.limit_price AS ref_price,
          CAST(rec.entry_window_close AS STRING) AS window_close,
          CAST(rec.window_close_instant AS STRING) AS window_close_instant,
          CAST(rec.staged_ts AS STRING) AS staged_ts,
          rec.instruction_id AS instruction_id)));
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
        'The staged-order notice block in ops.sp_sq_daily_staging_cap_check raised an error and stopped part-way this pass, so ONE OR BOTH of the two notices it evaluates may not have been raised today -- staged_order_awaiting_confirm for an order waiting to fill, and staged_order_window_dead_on_arrival for an order staged outside its own entry window. The block runs the two in that order and each statement commits independently, so the first may have completed before the fault; treat both as unverified for today rather than assuming either ran. The two order-guard CRITICAL checks in the same procedure are unaffected (this block is best-effort by construction and runs before them). See payload for the error message.',
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

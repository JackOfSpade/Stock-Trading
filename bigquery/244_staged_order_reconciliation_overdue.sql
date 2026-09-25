-- =====================================================================================================
-- 244. state.staged_order_reconciliation_overdue -- a staged order nobody has reconciled in far longer
--      than any healthy cadence can explain, plus its ops.alert_policy registration.
--
-- WHY THIS EXISTS (interactive triage 2026-09-20, the quota outage recorded in ops/RUNBOOK.md section 53).
-- state.open_orders rows are cleared by exactly one mechanism: D2a STEP 0 appends a terminal-status
-- events.queue_events row for the item_key (filled / expired / abandoned). If D2a stops reconciling a
-- given row -- whether because D2a is not running at all, or because it runs but its fill-matching never
-- resolves that particular item_key -- the row sits pending FOREVER. Nothing in the system escalates:
--
--   * staged_order_awaiting_confirm (bigquery/229, live head bigquery/234) raises ONCE per item_key and is
--     then permanently silent. sp_raise_alert_once dedups on exact (category, message) and that message
--     carries the item_key and nothing else -- deliberately, so a daily persist-and-wait re-craft does not
--     re-mint it. The consequence is that an order pending 1 day and an order pending 100 days produce the
--     IDENTICAL single open row, same warning severity, with no re-notification ever.
--   * staged_order_window_dead_on_arrival (bigquery/233) tests staged_ts >= window_close_instant -- a BIRTH
--     defect, evaluated against the staging moment and never re-evaluated. A row legitimately staged inside
--     an open window can never enter that view no matter how long it then sits.
--   * dbt/tests/assert_open_orders_no_stale_pending.sql is STRUCTURALLY SILENT in exactly this case: its
--     guard requires state.freshness.last_d2_run_date > entry_window_close, and if the reconciling routine
--     stops running that watermark FREEZES below every newly-staged row's window. Deliberate ("if the fleet
--     is down ... this test stays silent instead of alarming") -- but it means the fleet being down is the
--     one condition it cannot report.
--   * The ~7-day pending_buy_shares unmask in state.position_reconciliation (bigquery/126) does eventually
--     force visibility, but only for a BUY that carries a position_key, and only as a blunt account-wide
--     halt via state.trading_enabled's NOT pr.drift term -- never a targeted notice. It does NOT cover a
--     stalled SELL, and it does NOT cover a PARK leg at all: park fills route to events.parking_events and
--     never reach state.current_positions, so a park leg has NO backstop whatsoever. The 2026-09-17 park
--     re-risk pair that prompted this file is precisely that class.
--
--     PRECISION CORRECTION 2026-09-25 (interactive triage of the staged_order_awaiting_confirm alert for
--     sweep-VOO-20260924; this file's conclusion is UNCHANGED and this view is still needed -- only the
--     phrase "NO backstop whatsoever" above is too strong, and it is left in place so this correction reads
--     against it). That phrase is right about state.position_reconciliation, which is what the bullet is
--     about, but wrong read as a system-wide claim, and a future session must not conclude from it that park
--     drift is unmonitored and go build a second monitor for it. Operating_Protocols.md section 13.A's
--     balance tripwire DOES cover park: its EXPECTED side reads state.park_reconciliation
--     (events_park_shares / events_park_market_value, park_mark_fresh as the staleness guard) and compares it
--     against the connector's live get_account_positions, with any unexplained residual over ~$1 a hard STOP
--     raising a CRITICAL cash_tripwire. Verified live 2026-09-25: state.park_reconciliation returns a
--     populated VOO row (events_park_shares 17.7177, market value 12526.24, park_mark_fresh TRUE).
--
--     WHAT 13.A DOES NOT COVER -- and therefore why this view still has to exist -- is the OTHER half of the
--     failure mode. Split it in two:
--       (a) D2a never records the fill at all. Events-side park shares then lag the connector, 13.A's
--           tripwire fires, and the drift is caught. For today's order that gap would be 0.0474 sh ~ $33.51,
--           roughly 33x the ~$1 threshold -- comfortably detected.
--       (b) D2a writes the events.parking_events row but never appends the terminal events.queue_events row
--           for the item_key. Park shares now MATCH, so 13.A is clean by construction and can never fire,
--           while state.open_orders keeps the row `pending` forever. NOTHING else escalates (b) -- that is
--           precisely this view's remit, and 13.A's existence does not narrow it.
--     Note also that 13.A runs inside D2 Step 0 (cron Sun-Thu), so on a whole-fleet outage neither mechanism
--     fires; they share that limitation rather than backstopping each other through it.
--
-- THRESHOLD -- 120 hours, derived, not guessed. D2a's cron is `40 22 * * 0,1,2,3,4` (Sun-Thu; 22:40 UTC is
-- the same America/Denver calendar day year-round). Its inter-run gaps are 24h Sun->Mon..Wed->Thu and
-- 72h Thu->Sun, the Friday/Saturday skip being the only multi-day one. So the WORST-CASE LEGITIMATE wait
-- for a first reconciliation opportunity is ~72h: an order that becomes pending just after Thursday's
-- registry walk waits until Sunday's. 120h clears that by two full days, so this view cannot fire on a
-- healthy schedule -- it fires only when D2a has missed at least one of its OWN scheduled slots, or has
-- run without resolving the row. Do NOT lower this below 72h without re-deriving it from D2a's live cron;
-- do NOT raise it without noting that every extra day is a day the book stays wrong in silence.
--
-- DELIBERATELY A VIEW, NOT A NEW BLOCK IN ops.sp_sq_daily_staging_cap_check. That procedure also carries
-- the two order-guard CRITICALs (order_guard_omitted / order_guard_verdict_mismatch), which are the only
-- detective backstop on a bypassed pre-trade risk envelope. Re-issuing it to add an observability notice
-- puts that backstop at risk for no gain: OPS0 STEP 2c reads this view daily and owns both the raise and
-- the fail-closed resolve. A new view is additive -- nothing reads it until that step does.
--
-- Explicit column list, never SELECT *: state.open_orders.convergence_target is a hard CAST(... AS NUMERIC)
-- (bigquery/01_schema.sql) and on 2026-07-26 a ticker string in that payload field made every SELECT *
-- against the view fail with "Invalid NUMERIC value". This view must not be takeable down by an unrelated
-- malformed payload field -- the same reasoning bigquery/234 applies to its own FOR-loop column list.
-- =====================================================================================================

CREATE OR REPLACE VIEW `stock-trading-498512.state.staged_order_reconciliation_overdue` AS
SELECT
  o.item_key,
  o.strategy,
  o.ticker,
  o.side,
  o.qty,
  o.instruction_id,
  o.entry_window_close,
  o.staged_ts,
  TIMESTAMP_DIFF(CURRENT_TIMESTAMP(), o.staged_ts, HOUR) AS pending_hours,
  -- Surfaced so a reader of the row never has to re-derive the rule, and so the OPS0 payload can carry
  -- the threshold that was actually in force when the alert was raised.
  120 AS overdue_threshold_hours,
  -- A crafted order (instruction_id recorded at staging) has NO other liveness owner: the 30-hour
  -- state.staged_without_confirm check (bigquery/148) is scoped `AND o.instruction_id IS NULL`, i.e.
  -- manual-entry rows only, and says so outright -- "liveness of the crafted instruction itself is NOT
  -- this view's job". TRUE here means D2a is the single owner and D2a has not done it.
  o.instruction_id IS NOT NULL AS crafted_order,
  CURRENT_TIMESTAMP() AS checked_at
FROM `stock-trading-498512.state.open_orders` o
WHERE o.staged_ts < TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 120 HOUR);

-- ===== ops.alert_policy -- register the category (guarded insert, one row) ============================
-- ops.alert_policy is a FAIL-CLOSED allowlist (bigquery/34_alert_lifecycle.sql): an unregistered category
-- is latching by construction as far as every generic resolver is concerned, which would strand this row
-- open forever once raised. latching=FALSE here SANCTIONS the mechanical close OPS0 STEP 2c performs; no
-- ops.sp_auto_resolve_alerts rule covers it and it is NOT on the cadence_check 7-day auto-age list, which
-- is correct -- an age-out would be self-defeating for an alert whose entire subject IS elapsed time.
INSERT INTO `stock-trading-498512.ops.alert_policy` (category, latching, resolve_rule, updated_ts, note)
-- Guarded-insert idiom copied from bigquery/94_catchup_refire_blocked_policy.sql: the row set must come
-- from UNNEST([STRUCT(...)]), never a bare constant SELECT -- GoogleSQL rejects `SELECT <consts> WHERE ...`
-- outright ("Query without FROM clause cannot have a WHERE clause"), so the WHERE NOT EXISTS guard that
-- makes this file safe to re-apply in a DR rebuild needs a real FROM to attach to. Verified by dry-run
-- against live BigQuery before landing, per the rule that check_sql_dryrun goes blind after the first DDL.
SELECT * FROM UNNEST([STRUCT(
  'staged_order_reconciliation_overdue' AS category,
  FALSE AS latching,
  'Auto-resolves in-procedure-equivalent: OPS0 STEP 2c closes the row on its next run once the item_key named in payload.item_key is no longer present in state.staged_order_reconciliation_overdue (bigquery/244) -- which happens when D2a finally appends a terminal-status row for it (filled / expired / abandoned) and it leaves state.open_orders. NOT covered by any ops.sp_auto_resolve_alerts rule, and DELIBERATELY NOT on the cadence_check 7-day auto-age list: this alert measures elapsed non-reconciliation, so closing it on age would close it for being exactly what it reports. The resolve is fail-closed -- a row whose payload.item_key cannot be read stays OPEN rather than being silently closed.' AS resolve_rule,
  CURRENT_TIMESTAMP() AS updated_ts,
  'Registered 2026-09-20 (ops/RUNBOOK.md section 53 addendum). Threshold 120h is derived from D2a cron 40 22 * * 0,1,2,3,4: worst-case legitimate wait for a first reconciliation opportunity is the 72h Thu->Sun gap.' AS note)])
WHERE NOT EXISTS (
  SELECT 1 FROM `stock-trading-498512.ops.alert_policy`
  WHERE category = 'staged_order_reconciliation_overdue');

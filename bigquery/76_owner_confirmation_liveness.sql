-- Owner-confirmation liveness — absence model for the system's one sanctioned human dependency
-- (completeness-critic finding N-2, 2026-07-16). Project: stock-trading-498512.
-- Apply after 01_schema.sql (state.open_orders), 09_market_calendar.sql (state.market_calendar /
-- state.trading_day_today), 23_trading_control.sql (ops.trading_control), 34_alert_lifecycle.sql
-- (ops.alert_policy / ops.sp_raise_alert_once).
--
-- WHY THIS EXISTS. The IBKR order-confirm tap is the system's one sanctioned human touch (every other
-- add/delete/order-craft path is autonomous per CLAUDE.md's SISA note). Per-order staleness is already
-- detected (D3's `missed_confirmation` critical, `bigquery/30_confirm_attestation.sql`), but nothing
-- models the AGGREGATE absence: under the DAY-only TIF policy (Operating_Protocols.md §11) every open
-- position's exit needs a fresh tap each session (no resting server-side stop), so if the operator goes
-- dark for several trading days while D2/D2a keep re-crafting persist-and-wait entries, the system just
-- keeps staging NEW entries on top of an already-unconfirmed pile, with only unread per-order emails as
-- the signal. This view is the mechanically-checkable "how long has it actually been since ANY tap
-- landed a fill, while something is still waiting on one" fact; the Claude_Task_Plan.md D2a bullet
-- paired with it turns that fact into a fail-safe, reversible, entries-only staging pause.
--
-- SCOPE (deliberately narrow, per the critic finding): does NOT touch state.trading_enabled / halt_all,
-- the mechanical kill triggers, the IBKR confirm-tap requirement itself, or deposits. It only gates
-- NEW-entry staging in D2 (section "2. NEW ENTRY CANDIDATES") — Step 0's registry reconciliation (§11)
-- is completely unaffected, exactly as it must be: an unconfirmed pile is a reason to stop ADDING to it,
-- never a reason to stop trying to get OUT of it. PRECISION NOTE (2026-07-20 forensic investigation):
-- that reconciliation step is item_type-AGNOSTIC — it re-crafts ANY still-pending staged row daily,
-- ENTRIES AND EXITS ALIKE, not "exits only." Earlier wording here said "exit re-craft is unaffected,"
-- which is true but incomplete, and was read by the owner as implying pending ENTRIES would stop
-- re-crafting too (they do not — only FRESH GO decisions in D2's own "NEW ENTRY CANDIDATES" step are
-- paused). See Claude_Task_Plan.md's guard comment atop that reconciliation step for the full rationale
-- and the deadlock hazard of "fixing" this the wrong way.

-- ===== state.owner_confirmation_liveness — the absence-model view =====
-- Self-bootstrapping / never zero-row (single-row aggregate via scalar subqueries, same pattern as
-- state.book_drawdown_watch / state.daily_staging_totals): a genuinely empty events.trade_fills (day
-- one, or a data-layer outage) reads as "maximally stale" (999 trading days), NOT as "confirms are
-- current" — fail-safe by construction, matching this file's own halt-on-doubt design intent.
-- entries_halted=TRUE gates ONLY new-entry staging (Claude_Task_Plan.md D2 "NEW ENTRY CANDIDATES") —
-- the registry reconciliation step (§11) that re-crafts already-staged pending rows, entries and exits
-- alike, is unaffected (see the SCOPE note above — do not read "exit re-craft" narrowly here). Auto-
-- clears the moment a fill lands (trading_days_since_last_fill resets to 0 the next time this view is
-- queried — no manual clear step, no write needed to un-halt).
CREATE OR REPLACE VIEW `stock-trading-498512.state.owner_confirmation_liveness` AS
WITH pending AS (
  SELECT COUNT(*) AS n_pending_instructions
  FROM `stock-trading-498512.state.open_orders`
  WHERE status = 'pending'
),
last_fill AS (
  SELECT MAX(fill_ts) AS last_fill_ts
  FROM `stock-trading-498512.events.trade_fills`
),
ltd AS (
  SELECT last_trading_day FROM `stock-trading-498512.state.trading_day_today`
),
stale AS (
  SELECT
    CASE
      WHEN lf.last_fill_ts IS NULL THEN 999  -- no fill has EVER been recorded — fail-safe maximally stale
      ELSE (
        SELECT COUNT(*)
        FROM `stock-trading-498512.state.market_calendar` mc
        WHERE mc.is_trading_day
          AND mc.cal_date > DATE(lf.last_fill_ts, 'America/Denver')
          AND mc.cal_date <= ltd.last_trading_day
      )
    END AS trading_days_since_last_fill
  FROM last_fill lf, ltd
)
SELECT
  p.n_pending_instructions,
  lf.last_fill_ts,
  s.trading_days_since_last_fill,
  ltd.last_trading_day AS as_of_trading_day,
  -- entries_halted: >=1 pending staged instruction (something IS waiting on a tap) AND >=3 trading
  -- days have elapsed with zero fills reconciled. 3 trading days is a POLICY INVARIANT (not fitted) —
  -- long enough that a single busy/traveling day never false-trips, short enough that a real multi-day
  -- absence is caught well before a week-plus pile-up. Review alongside book growth like the other
  -- policy invariants in bigquery/23_trading_control.sql.
  (p.n_pending_instructions > 0 AND s.trading_days_since_last_fill >= 3) AS entries_halted
FROM pending p, last_fill lf, stale s, ltd;

-- ===== ops.trading_control usage convention for this gate (documentation only — no schema change) =====
-- Existing `mode` values (bigquery/23_trading_control.sql): 'manual' (operator-set) | 'auto' (a
-- monitor/breaker set it) — both used with EITHER halt_all=TRUE (a real halt) or halt_all=FALSE (an
-- operator manually clearing a prior auto-halt; see 23's own header comment). This gate reuses the same
-- free-form STRING column with a THIRD, additive value, `mode='entries_halted'`, ALWAYS paired with
-- `halt_all=FALSE` — it is an AUDIT-TRAIL marker only (proof of when/why the entries-only pause fired),
-- never the mechanism the pause itself runs on. state.owner_confirmation_liveness.entries_halted (above)
-- is recomputed fresh from events.trade_fills / state.open_orders every time it is read — it does NOT
-- depend on the latest row of ops.trading_control the way state.trading_enabled's halt_all reading does.
-- This is a deliberate design choice, not an oversight: ops.trading_control's state.trading_control_latest
-- / state.trading_enabled consumers pick the SINGLE latest row by control_ts across ALL modes — if this
-- gate's marker row were the mechanism itself (e.g. by setting halt_all=TRUE), an unrelated LATER
-- 'entries_halted' marker row could silently outrank and clobber a genuine, still-open 'auto' halt_all
-- row from an earlier real breaker trip (or vice versa) purely by insertion order, exactly the "silently
-- clobbered a live fix" class of risk CLAUDE.md's Terraform note and bigquery/47's header both warn
-- about elsewhere in this file set. Keeping halt_all=FALSE on every 'entries_halted' row means this
-- gate can NEVER interact with that global latest-row selection, by construction — see the
-- Claude_Task_Plan.md D2a bullet for the exact INSERT/UPDATE + alert-raise/resolve text using this
-- convention.
--
-- ops.alert_policy seed (bigquery/34_alert_lifecycle.sql): 'owner_confirmation_stale' is intentionally
-- LEFT ABSENT here (stays latching=TRUE, the fail-closed default) — this alert is resolved directly by
-- the D2a routine-text bullet the moment entries_halted next reads FALSE (a fill lands), not by
-- ops.sp_auto_resolve_alerts, so it does not need (and should not get) a resolve_rule row here.


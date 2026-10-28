-- 269_owner_confirmation_pending_age.sql (2026-10-27, interactive triage)
-- Project: stock-trading-498512. Apply after 268_paper_regime_cells_carry_forward.sql.
--
-- SUPERSEDES the state.owner_confirmation_liveness VIEW BODY in
-- bigquery/211_owner_confirmation_pending_case_fold.sql. Chain: 76 -> 209 -> 211 -> 269.
-- 209 remains the canonical home of the PARK-TAP argument and the DRIP exclusion; 211 of the
-- LOWER(status) fold; 76 of the SCOPE note and the "ops.trading_control usage convention for this
-- gate" block that ops/prose_invariants.yaml names as a source_of_truth. Only the body moves.
--
-- ONE CHANGE: entries_halted counts how long a PENDING instruction has gone untapped, not how long
-- the book has gone without a fill.
--
--   -  (n_pending_instructions > 0 AND trading_days_since_last_fill >= 3)
--   +  (n_pending_instructions > 0 AND trading_days_pending_untapped >= 3)
--
-- trading_days_pending_untapped counts trading days after the LATER of (a) the last owner tap and
-- (b) the date the oldest still-pending instruction was FIRST staged, up to the last trading day.
--
-- THE DEFECT (alert 8f0a42b1, D2a 2026-10-26). The old counter started at the last tap, so every
-- quiet stretch with no orders at all banked "untapped" days. The first instruction crafted after
-- the quiet stretch then tripped the gate the same evening it was staged, before the owner had any
-- chance to tap it. On 2026-10-26 D2a crafted park cover cover-VOO-20261026 at 22:45Z, read
-- 1 pending / 14 trading days since the last tap (2026-10-06), opened entries_halted marker
-- ea2d1dcd, raised owner_confirmation_stale 0ea720d4, and paused D2 new entries that night. The
-- instruction was zero trading days old. The 14 days were days with NOTHING to tap.
--
-- BACKTEST, not inference. Replayed over every events.queue_events ORDER_STAGED item_key from
-- 2026-07-10 to today: every instruction ever staged was filled within ONE trading day of its first
-- staging (worst case a Friday stage filled Monday/Tuesday). So the old predicate's four fires were
-- ALL false: 2026-07-19 (entry-TSM/ISRG staged Fri 07-17, filled 07-20/21), the marker closed
-- 2026-08-27 (exit-CRM staged 08-26, filled 08-27), 2026-09-02 (D2a's own sweep crafted minutes
-- earlier) and 2026-10-26 (D2a's own cover crafted minutes earlier). The new predicate fires on none
-- of them, and would still fire on a real lapse: an instruction staged on day X and untapped through
-- X+3 trading days halts exactly as before.
--
-- WHY FIRST-STAGED, NOT staged_ts. state.open_orders.staged_ts is the LATEST ORDER_STAGED row per
-- item_key, and a persist-and-wait re-craft writes a fresh row under the SAME item_key every day
-- (e.g. stage-MDT-B-20260603: 8 rows over 8 days). Using staged_ts would reset the clock on every
-- re-craft and the gate could never fire -- fail OPEN. MIN(event_ts) over all ORDER_STAGED rows
-- for the item_key is stable across re-crafts.
--
-- WHY MIN over pending items. The longest-waiting instruction decides. Taking the oldest is the
-- fail-safe direction: it can only make the count larger.
--
-- WHY the later of the two dates. A tap AFTER the oldest pending item was staged (on some other
-- order) is positive evidence the owner is responsive, so the count restarts from it -- the same
-- reading the old predicate gave any tap.
--
-- trading_days_since_last_fill is KEPT, unchanged, because D2a writes it into the marker reason and
-- the alert payload and state.entry_staging_allowed formats it into block_reason. It no longer
-- drives the halt. last_fill_ts / last_park_fill_date / last_owner_tap_date are also unchanged.
--
-- The 999 fail-safe now applies when neither a tap nor a pending date exists -- and with no pending
-- instruction entries_halted is FALSE regardless, so it is unreachable in a halting state.
--
-- APPLY: idempotent (CREATE OR REPLACE VIEW). dbt/models/state/owner_confirmation_liveness.sql is
-- regenerated from this body with scripts/gen_dbt_port.py and proved with scripts/verify_dbt_port.py;
-- the model is in dbt/parity_live_scope.yml, so the daily live-sql-parity run reports drift if the
-- live apply is skipped.

CREATE OR REPLACE VIEW `stock-trading-498512.state.owner_confirmation_liveness` AS
WITH pending AS (
  SELECT COUNT(*) AS n_pending_instructions
  FROM `stock-trading-498512.state.open_orders`
  -- LOWER(): see the header. state.open_orders already filters LOWER(status)='pending' and
  -- projects the RAW status, so a case-variant value survives the source view and would be
  -- silently dropped by a case-SENSITIVE re-filter here — in the fail-OPEN direction.
  WHERE LOWER(status) = 'pending'
),
oldest_pending AS (
  -- First-staged date of the longest-waiting pending instruction. MIN(event_ts) over EVERY
  -- ORDER_STAGED row for the item_key, never open_orders.staged_ts: a re-craft writes a new row
  -- under the same item_key daily and would reset the clock (see the header).
  SELECT MIN(DATE(q.event_ts, 'America/Denver')) AS oldest_pending_staged_date
  FROM `stock-trading-498512.events.queue_events` q
  WHERE q.queue = 'ORDER_STAGED'
    AND q.item_key IN (
      SELECT item_key FROM `stock-trading-498512.state.open_orders` WHERE LOWER(status) = 'pending'
    )
),
last_fill AS (
  -- Strategy-trade fills, EXCLUDING IBKR's automatic dividend reinvestment (order_id '0' — no broker
  -- order id because the owner placed no order and tapped nothing; see change (2) in the header, and
  -- note this is the exact counterpart of the park source's DIVIDEND_REINVEST exclusion below).
  -- COALESCE, never a bare <>: a bare inequality would silently drop a NULL order_id row.
  -- last_fill_ts stays an output column — D2a's owner-confirmation bullet puts it in the
  -- owner_confirmation_stale alert payload — and now means "last owner-tapped STRATEGY fill";
  -- last_fill_date is its America/Denver operating-plane date, which is what the counter compares.
  SELECT MAX(fill_ts) AS last_fill_ts, MAX(DATE(fill_ts, 'America/Denver')) AS last_fill_date
  FROM `stock-trading-498512.events.trade_fills`
  WHERE COALESCE(order_id, '') <> '0'
),
last_park AS (
  -- Park fills. action_date is the FILL date (event_ts is the write time -- see the header); the
  -- BUY/SELL allowlist keeps DIVIDEND_REINVEST (automatic DRIP) and RECON_ADJUST (bookkeeping) out,
  -- since neither evidences an owner tap.
  SELECT MAX(action_date) AS last_park_fill_date
  FROM `stock-trading-498512.events.parking_events`
  WHERE action IN ('BUY', 'SELL')
),
ltd AS (
  SELECT last_trading_day FROM `stock-trading-498512.state.trading_day_today`
),
tap AS (
  -- MAX over UNNEST, never GREATEST(): GREATEST returns NULL if ANY argument is NULL, which would
  -- send a book with fills in only one of the two tables straight to the 999 fail-safe.
  SELECT
    (SELECT MAX(d) FROM UNNEST([lf.last_fill_date, lp.last_park_fill_date]) AS d) AS last_owner_tap_date,
    (SELECT MAX(d) FROM UNNEST([lf.last_fill_date, lp.last_park_fill_date, op.oldest_pending_staged_date]) AS d)
      AS untapped_clock_start
  FROM last_fill lf, last_park lp, oldest_pending op
),
stale AS (
  SELECT
    CASE
      WHEN t.last_owner_tap_date IS NULL THEN 999  -- neither table has EVER recorded a fill — fail-safe maximally stale
      ELSE (
        SELECT COUNT(*)
        FROM `stock-trading-498512.state.market_calendar` mc
        WHERE mc.is_trading_day
          AND mc.cal_date > t.last_owner_tap_date
          AND mc.cal_date <= ltd.last_trading_day
      )
    END AS trading_days_since_last_fill,
    CASE
      WHEN t.untapped_clock_start IS NULL THEN 999  -- no tap and no pending date — fail-safe maximally stale
      ELSE (
        SELECT COUNT(*)
        FROM `stock-trading-498512.state.market_calendar` mc
        WHERE mc.is_trading_day
          AND mc.cal_date > t.untapped_clock_start
          AND mc.cal_date <= ltd.last_trading_day
      )
    END AS trading_days_pending_untapped
  FROM tap t, ltd
)
SELECT
  p.n_pending_instructions,
  lf.last_fill_ts,
  lp.last_park_fill_date,
  t.last_owner_tap_date,
  s.trading_days_since_last_fill,
  ltd.last_trading_day AS as_of_trading_day,
  op.oldest_pending_staged_date,
  s.trading_days_pending_untapped,
  -- entries_halted: >=1 pending staged instruction AND >=3 trading days that instruction has waited
  -- with no owner confirm-tap of ANY kind, strategy or park (see the header for why the clock starts
  -- at the later of the last tap and the oldest pending instruction's first staging).
  (p.n_pending_instructions > 0 AND s.trading_days_pending_untapped >= 3) AS entries_halted
FROM pending p, oldest_pending op, last_fill lf, last_park lp, tap t, stale s, ltd;

-- 211_owner_confirmation_pending_case_fold.sql (2026-09-03, interactive triage)
-- Project: stock-trading-498512. Apply after 210_selfheal_inflight_guard.sql.
--
-- SUPERSEDES the state.owner_confirmation_liveness VIEW BODY in
-- bigquery/209_owner_confirmation_park_tap_liveness.sql (which superseded bigquery/76's).
-- Chain: 76 -> 209 -> 211. 209 remains the canonical home of the PARK-TAP argument, the DRIP
-- exclusion rationale and the action_date-not-event_ts reasoning; 76 remains the canonical home of
-- the SCOPE note and the "ops.trading_control usage convention for this gate" block that
-- ops/prose_invariants.yaml names as a source_of_truth. Read all three together; only the body moves.
--
-- ONE CHANGE, one word: the `pending` CTE's re-filter becomes case-insensitive.
--
--   -  WHERE status = 'pending'
--   +  WHERE LOWER(status) = 'pending'
--
-- WHY. state.open_orders (bigquery/01_schema.sql, still the canonical definition -- no later file
-- redefines it) ends `WHERE LOWER(status) = 'pending'` and projects the RAW `status` column. So the
-- SOURCE view is case-insensitive and its OUTPUT is not normalised. This view then re-filters that
-- already-filtered set with a case-SENSITIVE equality, and a 'Pending'/'PENDING' row -- admitted by
-- the source -- is silently dropped here.
--
-- THE DIRECTION IS THE POINT. n_pending_instructions is one of the two conjuncts of
-- `entries_halted = (n_pending_instructions > 0 AND trading_days_since_last_fill >= 3)`. Dropping a
-- row can only LOWER the count, and lowering the count can only make the halt LESS likely -- so the
-- divergence fails OPEN on a gate whose entire job is to halt new-entry staging when the operator has
-- stopped confirming orders. A gate that is wrong in the permissive direction is the one kind of
-- wrong this gate must not be.
--
-- BLAST RADIUS TODAY: ZERO, and that is not a reason to leave it. All 113 ORDER_STAGED rows ever
-- written carry a lowercase status (63 'pending', 50 'filled'); the value is written by routine SQL
-- from a fixed vocabulary (bigquery/01_schema.sql: "statuses pending|filled|expired|abandoned"), not
-- by a human or a connector. It is inert until the first hand-written or differently-cased INSERT,
-- which is the "inert today is a countdown" class this repo fixes on sight rather than after.
--
-- HOW IT SURVIVED 209. 209's header says "Every other term is carried forward byte-identical: the
-- pending count, ...". That is true and it is exactly how the term was re-endorsed without being
-- re-examined -- carrying a term forward verbatim proves it unchanged, never that it is right. Noted
-- here so the next file to carry this body forward reads the terms rather than the diff.
--
-- APPLY: idempotent (CREATE OR REPLACE VIEW); safe to re-run. Verified before and after: the view
-- returns the identical single row (n_pending_instructions = 1, entries_halted = FALSE), because
-- every live row is already lowercase. dbt/models/state/owner_confirmation_liveness.sql must be
-- REGENERATED from this body with scripts/gen_dbt_port.py (never hand-edited) and proved with
-- scripts/verify_dbt_port.py -- this model IS listed in dbt/parity_live_scope.yml, so the daily
-- 07:10 UTC live-sql-parity run compares it against live and will report drift if the apply is
-- skipped.

CREATE OR REPLACE VIEW `stock-trading-498512.state.owner_confirmation_liveness` AS
WITH pending AS (
  SELECT COUNT(*) AS n_pending_instructions
  FROM `stock-trading-498512.state.open_orders`
  -- LOWER(): see the header. state.open_orders already filters LOWER(status)='pending' and
  -- projects the RAW status, so a case-variant value survives the source view and would be
  -- silently dropped by a case-SENSITIVE re-filter here — in the fail-OPEN direction.
  WHERE LOWER(status) = 'pending'
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
  SELECT (SELECT MAX(d) FROM UNNEST([lf.last_fill_date, lp.last_park_fill_date]) AS d) AS last_owner_tap_date
  FROM last_fill lf, last_park lp
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
    END AS trading_days_since_last_fill
  FROM tap t, ltd
)
SELECT
  p.n_pending_instructions,
  lf.last_fill_ts,
  lp.last_park_fill_date,
  t.last_owner_tap_date,
  s.trading_days_since_last_fill,
  ltd.last_trading_day AS as_of_trading_day,
  -- entries_halted: unchanged predicate — >=1 pending staged instruction (something IS waiting on a
  -- tap) AND >=3 trading days elapsed with zero owner confirm-taps of ANY kind, strategy or park.
  (p.n_pending_instructions > 0 AND s.trading_days_since_last_fill >= 3) AS entries_halted
FROM pending p, last_fill lf, last_park lp, tap t, stale s, ltd;

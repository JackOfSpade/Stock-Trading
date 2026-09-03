-- 209_owner_confirmation_park_tap_liveness.sql (2026-09-02)
-- Project: stock-trading-498512.
--
-- SUPERSEDES the state.owner_confirmation_liveness view definition in
-- bigquery/76_owner_confirmation_liveness.sql. That file is unchanged below its header and remains
-- the canonical home of this gate's DESIGN PROSE -- the SCOPE note and the "ops.trading_control
-- usage convention for this gate" block (the latter is named as a source_of_truth by
-- ops/prose_invariants.yaml's trading_control halt-row-guard rule, and is NOT restated here).
-- Only the VIEW BODY moves to this file. Apply after bigquery/76.
--
-- TWO CHANGES, both to WHAT COUNTS AS AN OWNER TAP, neither to how much staleness is tolerated.
--
-- (1) THE PARK SOURCE (the reported defect). The "last owner confirm-tap" the staleness counter
--     measures from is no longer MAX(fill_ts) over events.trade_fills ALONE. It is now the LATER of
--     that and MAX(action_date) over events.parking_events rows whose action is BUY or SELL. Two new
--     columns (last_park_fill_date, last_owner_tap_date) expose both sides so the reading is
--     auditable rather than implicit.
--
-- (2) DRIP IS NOT A TAP, ON BOTH SIDES (found reviewing (1), fixed here rather than left as a
--     follow-up). (1) alone would have shipped an internal contradiction: this file argues below that
--     an automatic dividend reinvest is not an owner tap and excludes DIVIDEND_REINVEST from the park
--     source, while the strategy source counted the IDENTICAL class. IBKR's automatic DRIP reinvests
--     land in events.trade_fills as ordinary rows, distinguished by a literal order_id of '0' -- no
--     broker order id, because the owner placed no order and tapped nothing. MEASURED over all 50
--     rows: exactly 5 carry order_id '0' (2026-06-11 IBM 0.0007, 06-12 RTX 0.0006, 07-01 HCA 0.0001,
--     07-20 MDT 0.0042, 07-23 DIS 0.0022 -- all sub-cent fractional BUYs on dividend payers) and the
--     other 45 carry a real broker order id; none is NULL. Note raw.exchange = 'IBDRIPUS' is NOT a
--     usable discriminator -- it is present on only 3 of the 5 (RTX's raw is NULL outright, HCA's raw
--     has no exchange key) -- so key on order_id, which is 5 of 5.
--     BLAST RADIUS TODAY: ZERO. The newest DRIP row is 2026-07-23 and the newest real fill is
--     2026-08-27, so MAX(fill_ts) is unmoved and last_fill_ts does not change. Counter-factually the
--     filter would have crossed the >=3 threshold on two days, 2026-06-15 and 2026-06-16, both BEFORE
--     this gate existed (2026-07-17). Dormant, not dead: the account went to Receive Cash on
--     2026-08-02 (Operating_Protocols.md §13.C), which is an account-level ELECTION that can be
--     changed, and §13.C requires a fresh DRIP-or-cash determination at each new park vehicle's first
--     dividend -- so this re-arms without warning. Fixed while inert, per the standing rule that
--     inert-today is a countdown.
--     FAILURE DIRECTIONS, checked rather than assumed. A future DRIP carrying order_id '0' is
--     correctly excluded. A future DRIP carrying a REAL order id is counted as a tap -- which is
--     exactly today's behaviour, so no regression is introduced. A genuine owner-tapped fill somehow
--     carrying order_id '0' would be excluded, which OVER-reports staleness, the fail-safe direction.
--     So this is a strict improvement on the current body in the safe direction, with no new unsafe
--     path. The predicate is COALESCE(order_id, '') <> '0', never a bare <> : a bare inequality drops
--     a NULL order_id row silently (GoogleSQL three-valued logic), and a NULL order id is unknown
--     provenance, NOT evidence of DRIP -- keeping it preserves the current reading for that case
--     instead of inventing a new false-halt path, which is the very failure this file exists to close.
--
-- Every other term is carried forward byte-identical: the pending count, the 999 never-any-fill
-- bootstrap, the strictly-after trading-day count against state.market_calendar, the America/Denver
-- operating plane, the >=1-pending AND >=3-trading-days entries_halted predicate, the column names
-- entries_halted / trading_days_since_last_fill / n_pending_instructions / last_fill_ts /
-- as_of_trading_day, and the single-row scalar-subquery shape.
--
-- WHY. events.parking_events is where park (cash-parking vehicle) fills are recorded, and they are
-- recorded THERE AND NOWHERE ELSE: Operating_Protocols.md 13.E step 5 says a crafted sweep/cover
-- "do NOT insert a events.parking_events row yet", step 6 says "Once the order actually fills,
-- insert the events.parking_events row for it -- the FIRST and ONLY row for this action", and 13.D
-- says strategy-trade fills go to events.trade_fills "as usual". So the two tables partition the
-- fill universe; neither is a superset of the other.
--
-- A park fill is an OWNER CONFIRM-TAP by the same mechanism as any other fill. Operating_Protocols.md
-- 13.E "Connector limits / safety": "create_order_instruction does not execute -- the operator still
-- taps to confirm (11), so a mis-sized sweep is caught at the confirm gate." A park sweep, a park
-- cover, a park-switch leg and an operator-placed park SELL are all tap-then-fill on the same IBKR
-- surface as a strategy entry. Measuring owner liveness while structurally excluding an entire class
-- of the owner's taps is the defect: the signal that exists to answer "is the operator still tapping"
-- could not see taps that demonstrably happened.
--
-- MEASURED, not inferred (2026-09-02, D2a's own filing -- ops.alerts info
-- owner_confirmation_liveness_park_tap_blind, and re-measured independently in the session that wrote
-- this file). The operator tapped and filled BOTH VOO->SGOV park-switch legs at the 2026-09-02 open
-- (instructions 100 and 101; ten events.parking_events rows, order_ids 1850320382 / 1850320454) and a
-- park sweep on 2026-08-28. The view still read trading_days_since_last_fill = 4 off last_fill_ts
-- 2026-08-27T13:31:48Z (a CRM exit), n_pending_instructions = 1, entries_halted = TRUE -- so
-- state.entry_staging_allowed.entries_allowed read FALSE and D2's NEW-ENTRY staging was paused on a
-- day the owner had confirmed two orders hours earlier.
--
-- IT IS SELF-SUSTAINING, which is what makes it worth a file rather than a note. D2a's mandatory 13.E
-- sweep craft is what took n_pending_instructions from 0 to 1 in that same run (free_cash 88.85 over
-- the +$25 floor), re-arming the gate's first term; and because only a NON-park fill could reset the
-- counter, the second term could only grow. A book that is parked and has no strategy fills -- the
-- normal state whenever the regime router is not admitting entries -- re-arms this gate every evening
-- it sweeps, and stays halted until a strategy trade happens, which is precisely the thing the halt
-- was preventing.
--
-- BOTH EPISODES EVER RECORDED WERE THIS BUG. Reconstructed per trading day over 2026-07-01..2026-09-02
-- by replaying events.queue_events ORDER_STAGED latest-status-as-of-day for the pending term against
-- state.market_calendar and both fill tables, so this compares the WHOLE entries_halted predicate, not
-- just the counter: entries_halted reads TRUE on SEVEN trading days under the old body (07-08, 07-17,
-- 08-11, 08-17, 08-26, 09-01, 09-02) and on TWO under this one (07-08, 08-26). The five that flip are
-- 07-17, 08-11, 08-17, 09-01 and 09-02. The two that SURVIVE are genuine owner silences and must:
-- on 08-26 the owner had been dark since 08-19 (5 trading days on either reading) and tapped the CRM
-- exit the next morning. State that split precisely -- the counter alone differs on far more days than
-- the gate does, and quoting the counter's difference as if it were averted halts would overstate this.
--
-- The 2026-07-19 ops.trading_control marker row 8b0c45d6 ("2 pending instruction(s), 6 trading days
-- since the last reconciled fill") is the 07-17 reading: 6 under the old formula, 2 under this one,
-- because the 2026-07-15 owner-executed SGOV->VOO cutover -- the single largest confirm-tap in the
-- book's history -- landed entirely in events.parking_events. That marker then stayed open until
-- 2026-08-27. Marker d67d339c (2026-09-02) is the second and reads 0 under this one. So this gate has
-- fired exactly twice in its life, and both firings were false positives of this defect.
--
-- WHY action_date AND NOT event_ts. events.parking_events has no fill-timestamp column. event_ts is
-- the D2a WRITE time and action_date is the FILL date, and they diverge: the 2026-08-28 sweep fill is
-- action_date 2026-08-28 / event_ts 2026-08-30 ("Mirrored on the SUNDAY run"), the 2026-08-14 fill was
-- written 2026-08-16, and all ten 2026-09-02 rows share one event_ts while their notes record fills at
-- 13:30:00-13:30:05Z. Over all 66 rows action_date NEVER exceeds DATE(event_ts) in either the UTC or
-- the Denver plane, and is never NULL (dbt asserts not_null on it).
--
-- QUANTIFY THE LAG HONESTLY, because a bare maximum here would mislead a future session in BOTH
-- directions. Over the whole table the max write lag is 43 days -- but every lag above 4 days is a
-- 2026-04/05 row from the one historical backfill (13 rows, lag 7-43d), NOT operational behaviour, so
-- do NOT read this as a six-week blind spot. In the operational era (>= 2026-06-01, 53 rows) the lag
-- is ZERO on 47 and at most 4 days, and the only two recent cases are Friday fills mirrored on the
-- Sunday run at +2 days (2026-08-14, 2026-08-28) -- the fleet is Sun-Thu, so a Friday fill's row is
-- written Sunday. That +2 is small but NOT negligible against a 3-trading-day threshold, which is
-- exactly why the fill DATE and not the write time is the right key. Using event_ts would date a tap
-- LATER than it happened, i.e. under-report staleness -- the anti-fail-safe direction. This corrects
-- the "GREATEST over ... events.parking_events fill time" shape D2a's own notice suggested: there is
-- no such column, and the nearest one is the wrong one.
--
-- TIMEZONE. action_date needs no plane conversion and gets none. It is already a trading date, and a
-- park fill is an RTH fill (13:30-21:00Z), which is the same calendar date in UTC, America/New_York
-- and America/Denver alike -- so the comparison against state.market_calendar.cal_date is exact, not
-- approximate. The trade_fills side keeps its existing DATE(fill_ts, 'America/Denver') conversion
-- verbatim; America/Denver is the pinned OPERATING plane (CLAUDE.md timezone-planes decision,
-- bigquery/20_user_prefs.sql) and nothing here makes it dynamic.
--
-- WHY AN ALLOWLIST (action IN ('BUY','SELL')) AND NOT AN EXCLUSION LIST. Operating_Protocols.md 13.D
-- names the vocabulary as BUY / SELL / DIVIDEND_REINVEST; RECON_ADJUST is the fourth value in live
-- data (13.D's connector-is-truth correction row). Neither of the two non-order values is an owner
-- tap: both DIVIDEND_REINVEST rows are IBKR's automatic IBDRIPUS reinvest, and the single
-- RECON_ADJUST is a signed bookkeeping alignment to the connector holding -- counting either would
-- silently report the owner as responsive on a day they did nothing. An allowlist also fails in the
-- SAFE direction if the vocabulary ever grows: an unrecognised future action is simply not counted,
-- which OVER-reports staleness, matching this gate's halt-on-doubt design. An exclusion list would
-- fail the other way.
--
-- WHAT IS DELIBERATELY NOT CHANGED.
--   * n_pending_instructions still counts EVERY pending state.open_orders row, park rows included.
--     D2a's notice offered excluding park-class pendings as an alternative shape; it is rejected. A
--     pending park sweep genuinely IS an instruction waiting on an owner tap, so excluding it would
--     blind the gate to the real absence case where the only thing waiting is a park order. Fixing
--     the measurement is sufficient -- with park fills counted, a tapped sweep resets the counter the
--     next morning and the loop cannot sustain itself. Fixing both would weaken the gate for no gain.
--   * The 3-trading-day threshold is untouched (bigquery/76 records it as a POLICY INVARIANT, not a
--     fitted number). This file corrects what is measured, never how much is tolerated.
--   * halt_all, state.trading_enabled, state.trading_enabled_mechanical, the mechanical kill
--     triggers, the IBKR confirm-tap requirement itself and deposits are all untouched, exactly as
--     bigquery/76's SCOPE note requires. The only downstream effect is on
--     state.entry_staging_allowed.entries_allowed (bigquery/205), which reads three of this view's
--     columns and needs no edit of its own.
--   * No new alert category and no ops.alert_policy row. owner_confirmation_stale keeps its
--     latching=TRUE default and is still resolved by the D2a bullet's own arm (i).
--   * THE CLOCK STAYS GLOBAL, not anchored to the oldest pending row's staging time. Surfaced by an
--     adversarial reviewer of this file and deliberately left alone. Because the two terms are
--     independent, the gate can fire on an instruction staged minutes earlier -- measured: on ALL SIX
--     halt days (07-17, 08-11, 08-17, 08-26, 09-01, 09-02) every pending row had been staged that same
--     evening, so this is the normal case here rather than an edge one. Anchoring
--     the clock to "the oldest pending has been WAITING >= 3 trading days" would mean a freshly staged
--     order could never trip this gate no matter how long the owner had been silent, which is the
--     opposite of what an absence model is for. The predicate reads "the owner has been silent for 3+
--     trading days AND something now needs them", and once park taps are counted that silence is a
--     sound signal (park BUY/SELL is 63 rows across 29 distinct fill dates against 50 strategy fills
--     across 34 -- roughly half of all owner taps were the invisible half). Changing it would be a
--     policy change to a documented POLICY INVARIANT, not a defect fix, and belongs to the owner.
--
-- FAIL-SAFE BOOTSTRAP PRESERVED. The 999 sentinel now fires only when BOTH sources are empty, which
-- is the correct generalisation: day one, or a data-layer outage that takes out both tables, still
-- reads as maximally stale rather than as "confirms are current". MAX over UNNEST is used rather than
-- GREATEST() precisely for this -- GoogleSQL's GREATEST returns NULL if ANY argument is NULL, so a
-- book that had park fills but no strategy fills yet (or the reverse) would collapse to the 999
-- branch and hard-halt entries on a perfectly live signal. MAX ignores NULLs and is NULL only when
-- every input is.

CREATE OR REPLACE VIEW `stock-trading-498512.state.owner_confirmation_liveness` AS
WITH pending AS (
  SELECT COUNT(*) AS n_pending_instructions
  FROM `stock-trading-498512.state.open_orders`
  WHERE status = 'pending'
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

-- APPLY STATE — see the commit that lands this file. Verification performed before applying:
--   SELECT * FROM state.owner_confirmation_liveness  -- pre:  4 days stale, entries_halted TRUE
--   (this body, run as a plain SELECT)               -- post: 0 days stale, entries_halted FALSE
--   SELECT * FROM state.entry_staging_allowed        -- entries_allowed must return to TRUE
-- scripts/check_live_sql_parity.py is the authority on repo==live; re-run it rather than trusting
-- this note if the two ever disagree.

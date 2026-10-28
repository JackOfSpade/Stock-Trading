-- PROVENANCE (hand-maintained above the generated body; scripts/gen_dbt_port.py replaces this block
-- on every regeneration, so it is restored by hand each time — see the generated header below).
-- Added 2026-08-22 (dbt view-coverage burn-down): this view had NO dbt presence at all, so
-- scripts/dbt_parity.py had nothing to compare and it carried ZERO row-level parity protection.
-- REPOINTED 2026-09-02 from bigquery/76 to bigquery/209_owner_confirmation_park_tap_liveness.sql:
-- the staleness counter's "last owner confirm-tap" became the later of MAX(events.trade_fills.fill_ts)
-- and MAX(events.parking_events.action_date) over BUY/SELL rows, because park fills are recorded ONLY
-- to events.parking_events yet are owner confirm-taps on the same IBKR surface; and IBKR's automatic
-- DRIP reinvests (order_id '0') stopped counting as taps on the strategy side, matching the park
-- side's DIVIDEND_REINVEST exclusion.
-- REPOINTED 2026-09-03 to bigquery/211_owner_confirmation_pending_case_fold.sql: the `pending` CTE
-- re-filters LOWER(status) = 'pending'. state.open_orders already filters LOWER(status) and projects
-- the RAW status, so the case-sensitive re-filter could drop a row the source admitted — and since
-- n_pending_instructions is a conjunct of entries_halted, that failed OPEN on a gate whose job is to
-- halt. Inert today (all 113 ORDER_STAGED rows ever are lowercase).
-- REPOINTED 2026-10-27 to bigquery/269_owner_confirmation_pending_age.sql: entries_halted now counts
-- trading days a PENDING instruction has waited untapped (from the later of the last tap and the
-- oldest pending item's FIRST ORDER_STAGED date), not days since the last fill — the old counter
-- banked quiet no-order days and tripped the gate the evening a fresh craft was staged (alert
-- 8f0a42b1). trading_days_since_last_fill is kept as an output column.
-- Parallel-run dbt port of bigquery/269_owner_confirmation_pending_age.sql:state.owner_confirmation_liveness — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
WITH pending AS (
  SELECT COUNT(*) AS n_pending_instructions
  FROM {{ ref('open_orders') }}
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
  FROM {{ source('events', 'queue_events') }} q
  WHERE q.queue = 'ORDER_STAGED'
    AND q.item_key IN (
      SELECT item_key FROM {{ ref('open_orders') }} WHERE LOWER(status) = 'pending'
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
  FROM {{ source('events', 'trade_fills') }}
  WHERE COALESCE(order_id, '') <> '0'
),
last_park AS (
  -- Park fills. action_date is the FILL date (event_ts is the write time -- see the header); the
  -- BUY/SELL allowlist keeps DIVIDEND_REINVEST (automatic DRIP) and RECON_ADJUST (bookkeeping) out,
  -- since neither evidences an owner tap.
  SELECT MAX(action_date) AS last_park_fill_date
  FROM {{ source('events', 'parking_events') }}
  WHERE action IN ('BUY', 'SELL')
),
ltd AS (
  SELECT last_trading_day FROM {{ ref('trading_day_today') }}
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
        FROM {{ ref('market_calendar') }} mc
        WHERE mc.is_trading_day
          AND mc.cal_date > t.last_owner_tap_date
          AND mc.cal_date <= ltd.last_trading_day
      )
    END AS trading_days_since_last_fill,
    CASE
      WHEN t.untapped_clock_start IS NULL THEN 999  -- no tap and no pending date — fail-safe maximally stale
      ELSE (
        SELECT COUNT(*)
        FROM {{ ref('market_calendar') }} mc
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
FROM pending p, oldest_pending op, last_fill lf, last_park lp, tap t, stale s, ltd

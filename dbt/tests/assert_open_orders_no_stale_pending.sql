-- Singular test (passes when ZERO rows): no ORDER_STAGED row stays 'pending' past its
-- entry-window close. state.open_orders already filters to status='pending'; a pending row whose
-- entry_window_close is in the past is an ORPHAN — the D2/D3 persist-and-wait sweep must either
-- re-craft it (window still open) or set it terminal (expired/filled). A stale pending row keeps
-- cash reserved (§13.E reserved_cash) and shadows the confirm-order slot, which is exactly the
-- order-intent invariant the 2026-06-08 MDT near-miss motivated (every pending staged order must
-- map to a live, current confirm event). entry_window_close NULL = no deadline (a resting exit) —
-- exempt. "today" is the America/Denver trading day (state.trading_day_today), never CURRENT_DATE.
--
-- RECONCILIATION-LAG GUARDS (added 2026-08-03, W4 2026-W32 finding). `status='pending'` is a
-- RECONCILIATION state, NOT a broker state: a row stays 'pending' from craft until D2a Step 0 / D2
-- Step 0 reconciles it, so an order that genuinely FILLED still reads 'pending' here until that runs.
-- Flagging on "past window + still pending" alone therefore reports an ORPHAN THE SWEEP MUST RESOLVE
-- in the one situation where there is nothing to resolve and no sweep running — the position exists
-- and only the registry write is outstanding. That is the same registry-vs-broker confusion behind
-- the 2026-08-03 MTZ near-miss, and it would have manufactured false failures across the
-- 2026-07-31..08-02 manual fleet pause, i.e. precisely when a trustworthy signal is least affordable.
-- Two independent guards, because they cover different halves of the problem:
--
--   (1) SWEEP-HAD-ITS-CHANCE. Only flag once a D2 reconciliation cycle has actually completed AFTER
--       the window closed (state.freshness.last_d2_run_date). If the fleet is down, stalled, or
--       simply has not reached its evening slot, last_d2_run_date does not advance and this test
--       stays silent instead of alarming about work nobody was scheduled to do yet. It re-arms by
--       itself the moment the fleet catches up, so a genuine orphan is still caught — just not
--       blamed on an outage. NULL last_d2_run_date (never run) never flags.
--   (2) ALREADY-FILLED. Exempt a row with a matching fill at or after its staging timestamp — the
--       reconciled-but-not-terminal'd case, where D2a ingested the fill but the ORDER_STAGED row was
--       never flipped. Note this guard is deliberately NOT sufficient on its own: events.trade_fills
--       is itself populated BY D2a Step 0, so during the outage that guard (1) covers there are no
--       fill rows to match against and this exemption is inert. Guard (1) is what makes the outage
--       case safe; guard (2) catches the partial-reconciliation bug that guard (1) would let through.
--
--       PARK ARM ADDED 2026-09-02 (park-tap blindness class sweep, alongside bigquery/209). Guard (2)
--       matched ONLY state.trade_fills_curated, while park sweep / cover / switch fills are recorded to
--       events.parking_events (Operating_Protocols.md §13.D, §13.E step 5/6) — so for every one of the
--       20 park ORDER_STAGED item_keys this registry has ever held, guard (2) was STRUCTURALLY
--       incapable of exempting them, whether or not they filled. Say that precisely rather than
--       "park fills never reach trade_fills", which is one row short of true: state.trade_fills_curated
--       holds EXACTLY ONE park-ticker row over its whole history — the 2026-06-30 RUNBOOK §29 SGOV
--       leak, which the sibling assert_no_park_ticker_in_strategy_positions.sql carves out by trade_id.
--       It cannot rescue guard (2) either, because guard (2) also requires f.fill_ts >= s.staged_ts and
--       a side match, so a lone 2026-06-30 row can never exempt a later park order. Either way this was
--       not "rarely matches" — it was never going to match. Only guard (1) kept it quiet,
--       and guard (1) is a timing accident, not a correctness argument: the nearest miss on record is
--       sweep-VOO-20260827 (window close 2026-08-28), which sat `pending` until the 2026-08-30 flip
--       and escaped only because D2 is Sun-Thu and its last completed run_date was still 2026-08-27.
--       A park order whose window closes on a Thursday it FILLS, whose Thursday-evening D2a flip
--       fails, is then flagged by Sunday's D2 run: guard (1) satisfied, guard (2) unable to exempt,
--       test fails on an order that demonstrably filled. Live today this test returns 0 rows — this
--       arm closes a reachable false positive, it does not change any current verdict. Matching key
--       is ticker + action + action_date, because events.parking_events carries no contract_id, and
--       action_date is the FILL date (event_ts is the WRITE time — see bigquery/209's header).
--
--       GRAIN CORRECTION 2026-09-03 (interactive triage; the arm shipped 2026-09-02 with `>=`).
--       The strategy arm gets its "the fill must not pre-date the order" safety free, at TIMESTAMP
--       grain, from `f.fill_ts >= s.staged_ts`. events.parking_events carries NO fill timestamp —
--       action_date is a DATE — so the park arm's join is DATE-grain, and `>=` there means "a fill
--       ANYWHERE ON the staging day exempts", including one that filled hours BEFORE the order was
--       staged. That is not the same predicate; it is a weaker one, and it was already false-negative
--       on the only row in the live registry: sweep-SGOV-20260902 (staged 2026-09-02 16:59 MT) was
--       exempted by the two parkswitch-SGOV-buy-20260901 second-leg fills (order_id 1850320454) that
--       filled at 07:30 MT the same morning — ~9.5h before it existed. So the arm added to close a
--       false positive had opened a false NEGATIVE on its first live row. The predicate is now a
--       STRICT `>`.
--       LOSSLESS ON ALL HISTORY, measured rather than argued: of the 23 park ORDER_STAGED item_keys
--       this registry has ever held, 9 have a same-Denver-date park match; 8 of those 9 also have a
--       LATER-day match (3-14 rows each) and stay exempt under `>`. The 9th is sweep-SGOV-20260902,
--       whose only matches are the false ones above. So `>` removes exactly one exemption and it is
--       the wrong one.
--       WHY `>` is safe at DATE grain and not merely tighter: park orders are staged in the EVENING.
--       All 23 items were staged 05:06-18:43 MT and only two before the 14:00 MT close — both on
--       Sunday 2026-07-26, a non-trading day that cannot produce a same-day fill. A same-Denver-date
--       park fill therefore belongs to a DIFFERENT order, which is exactly what the live case shows.
--       RESIDUAL, stated rather than hidden: a park order staged BEFORE the open on a trading day and
--       filled that same day, whose ORDER_STAGED row was then never flipped, would now be flagged.
--       That has never happened (0 of 23), and it is the fail-SAFE direction — a noisy flag is
--       triaged, a silently-missed orphan keeps cash reserved and shadows the confirm slot, which is
--       the whole reason this test exists.
--       ALTERNATIVE REJECTED ON MEASUREMENT, not taste: matching `REGEXP_CONTAINS(p.note, s.item_key)`
--       is an exact link (D2a writes the registry item_key into the park note). Measured across all 23
--       items, the number of park rows that the note-link would exempt but `>` would not is ZERO for
--       every item — it buys nothing today and adds a free-text regex surface, so it is not added.
--
-- A row with a closed window, no matching fill, and a D2 cycle since the close is still a genuine
-- orphan and still fails — which is the case this test exists to catch. See Operating_Protocols.md
-- §11 and "The registry is not the broker" in Claude_Task_Plan.md's Shared rules.

WITH staged AS (
  SELECT o.item_key, o.ticker, o.side, o.contract_id, o.staged_ts, o.entry_window_close, t.today
  FROM {{ ref('open_orders') }} o
  CROSS JOIN {{ ref('trading_day_today') }} t
  CROSS JOIN {{ ref('freshness') }} fr
  WHERE o.entry_window_close IS NOT NULL
    AND o.entry_window_close < t.today
    -- guard (1): a reconciliation cycle has completed since the window closed
    AND fr.last_d2_run_date IS NOT NULL
    AND fr.last_d2_run_date > o.entry_window_close
),

-- guard (2), as an anti-join rather than a correlated NOT EXISTS: BigQuery rejects correlated
-- subqueries it cannot de-correlate, and an equality/inequality mix like this is that shape.
-- Match on contract_id when the payload carried one (the reliable key), else fall back to ticker.
filled AS (
  SELECT DISTINCT s.item_key
  FROM staged s
  JOIN {{ ref('trade_fills_curated') }} f
    ON UPPER(f.side) = s.side
   AND f.fill_ts >= s.staged_ts
   AND (
         (s.contract_id IS NOT NULL AND f.contract_id = s.contract_id)
      OR (s.contract_id IS NULL AND f.ticker = s.ticker)
       )

  UNION DISTINCT

  -- park arm (see the PARK ARM note above): a park sweep/cover/switch leg's fill lands ONLY here.
  SELECT DISTINCT s.item_key
  FROM staged s
  JOIN {{ source('events', 'parking_events') }} p
    ON UPPER(p.action) = s.side
   AND p.ticker = s.ticker
   AND p.action_date >  DATE(s.staged_ts, 'America/Denver')
)

SELECT s.item_key, s.ticker, s.side, s.entry_window_close, s.today
FROM staged s
LEFT JOIN filled fl USING (item_key)
WHERE fl.item_key IS NULL

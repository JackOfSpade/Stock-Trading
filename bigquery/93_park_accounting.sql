-- bigquery/93_park_accounting.sql
-- Accounting + evaluation substrate for the AI Park Allocator (PARK_ROUTER_DESIGN.md v2 §9).
-- Project: stock-trading-498512. Apply after bigquery/92 (which itself applies after bigquery/91) --
-- this file's rule_index leg reads state.park_rule_shadow (92, keyed by `mark_date` -- confirmed
-- against 92's live text, see the rule_leg CTE's own note below) and both analytics.park_nav_daily and
-- analytics.park_counterfactuals read state.signal_marks_curated (91's curated view over the new
-- events.signal_marks table -- ticker/mark_date/close/dividend/split_ratio, an exact shape-mirror of
-- state.daily_marks_curated per 91's own header; both object names confirmed against 91's/92's actual
-- text, authored by parallel sibling tasks and landed in this same working tree partway through this
-- file's authoring). Views only (CREATE OR REPLACE VIEW throughout) -- idempotent, no new event
-- tables, no seed rows, safe to re-apply. Before 91/92 land, a reference to either object dry-runs as
-- "Not found" / "Unrecognized name", which scripts/check_sql_dryrun.py explicitly TOLERATES
-- (parse-class errors only block) -- applying 93 before 91/92 exist live is a routine intra-change
-- dependency, not a CI break. Full 3-statement syntax verified via `bq query --dry_run` against live
-- BigQuery with stand-ins for signal_marks_curated/park_rule_shadow (2026-07-18) -- 0 errors.
--
-- PROBLEM: the park went from a single frozen SGOV-then-VOO vehicle (bigquery/54) to an AI-directed
-- daily allocation call across a 12-ticker menu (PARK_ROUTER_DESIGN.md §4). Nothing in the repo prices
-- park performance as a chained daily return, benchmarks the AI's calls against alternatives, or marks
-- the park's own unrealized P&L into the account-wide reconciliation -- analytics.park_baseline
-- (bigquery/21) is retained-but-superseded and hardcoded to SGOV's return regardless of vehicle, and
-- analytics.account_reconciliation (bigquery/22) has no park-aware column at all.
--
-- FIX (three views):
--   1. analytics.park_nav_daily     -- the park's own daily-chained TWR, vehicle-generalized, single
--      source of truth for "how has the AI's actual book done."
--   2. analytics.park_counterfactuals -- SGOV / VOO / v1-rule-shadow / AI, same date axis, four chained
--      total-return indices -- PARK_ROUTER_DESIGN.md §9's three-way evaluation benchmark.
--   3. analytics.account_reconciliation -- SUPERSEDES bigquery/22's definition (marker added there,
--      same commit). Every existing output column is preserved byte-identical; two columns are added
--      (park_unrealized, residual_after_park) so the park's own mark-to-market P&L -- which the
--      events-side strategy_nav rollup has no way to see, since park carries no per-strategy
--      attribution -- is visible instead of silently living inside the account's existing
--      events-vs-live reconciliation gap.
--
-- CASH EXCLUSION (applies to all three views): unswept cash is NORMALLY <= $25 (the D2a
-- sweep/cover step, Operating_Protocols.md §13.E) and is NEVER counted as park exposure here --
-- park_nav_daily's park_mv and park_counterfactuals' indices are 100% instrument-based (shares *
-- close), and account_reconciliation's park_unrealized is likewise instrument-only; state.account_latest
-- .total_cash is read ONLY for the reconciliation's residual math (a separate concern from "what is the
-- park invested in"), never added into a park_mv/index figure.
--
-- KNOWN, BOUNDED EXCEPTION TO THE <= $25 ASSUMPTION -- PAIRED-ROTATION SETTLEMENT BRIDGE (owner
-- directive 2026-07-26, Operating_Protocols.md 13.E PAIRED-ROTATION EXCEPTION). D2 now crafts BOTH
-- legs of a park switch in one session, sizing the incoming vehicle's BUY off the EXPECTED proceeds of
-- the outgoing vehicle's SELL. For ONE settlement cycle (T+1) the account therefore carries a
-- deliberate transient cash balance of order the full switch notional -- thousands of dollars, not the
-- <= $25 this exclusion was written against. DELIBERATELY NOT FIXED IN SQL: these three views are
-- instrument-based by design ("what is the park invested in"), and folding a transiting settlement
-- balance into park_mv would conflate exposure with cash-in-flight and corrupt the counterfactual
-- indices they exist to compare against. The bridge is self-extinguishing (both legs settle within one
-- cycle) and is fully visible elsewhere -- the two ORDER_STAGED legs, events.parking_events fills, and
-- 13.C's paired-rotation attribution branch. CONSEQUENCE TO KNOW: if a park TWR measurement date falls
-- INSIDE a bridge window, park_nav_daily's park_mv understates or overstates the book for that one day
-- (the outgoing vehicle already sold, the incoming one not yet settled). W5's PARK SCORECARD must note
-- any measurement window overlapping a switch date rather than treat that day's TWR point as clean.
--
-- DEVIATION #1 FROM PARK_ROUTER_DESIGN.md's LITERAL PHRASING -- "vehicle = policy vehicle as-of date
-- (events.park_policy_changes, as-of by event_ts)": implemented instead by thresholding on
-- effective_date (event_ts DESC only as the TIEBREAK among rows sharing an effective_date), not by
-- thresholding on event_ts itself. Reason: events.park_policy_changes' SGOV founding row
-- (effective_date='2026-04-17') was inserted RETROACTIVELY during the 2026-07-15
-- bigquery/54_park_policy_voo_cutover.sql migration -- its event_ts is ~2026-07-15, not 2026-04-17
-- (confirmed live). A literal "event_ts <= as_of_date" filter would therefore return ZERO matching
-- rows -- and so vehicle=NULL -- for every axis date in 2026-04-17..2026-07-14, which is wrong: the
-- account genuinely held SGOV that whole time. effective_date is the column that actually carries
-- retroactive historical meaning for a point-in-time reconstruction; event_ts DESC as the tiebreak
-- preserves the SAME "latest insert wins" spirit as bigquery/54's documented state.park_policy_current
-- fix (scoped per as-of-date here instead of globally). Going forward, PARK_ROUTER_DESIGN.md §3's daily
-- D2 conversion inserts same-day, so effective_date and event_ts stay in lockstep and this distinction
-- is moot for any new row -- it only matters for this one retroactive founding-row artifact. See the
-- policy_asof CTE in analytics.park_nav_daily below for the implementation.
--
-- DEVIATION #2 -- LIVE-VERIFIED, NOT A CALCULATION CHOICE: PARK_ROUTER_DESIGN.md's grounding section
-- (via the recon it cites) frames the account_reconciliation gap as "today's ~$50 gap being exactly
-- park unrealized P&L." Queried live (2026-07-18, readonly): undeployed_total=9205.97,
-- state.park_reconciliation.events_park_market_value=9157.76, state.account_latest.total_cash=0.63 =>
-- the RAW residual (undeployed_total - park_mv - cash) = +47.58. Park's own unrealized P&L, computed
-- per this file's literal spec (current park MV - cost basis derived from events.parking_events'
-- net cash for the VOO leg, -9254.0886) = 9157.76 - 9254.0886 = -96.33. These do NOT satisfy
-- "raw residual == -park_unrealized" (47.58 != 96.33) -- park_unrealized is independently confirmed
-- correct by hand (13.4048 sh * (683.17 - 690.33) entry-to-mark price move ~= -95.98, +/- commission,
-- matches -96.33). So the design doc's "$50 gap IS park unrealized P&L" claim does not hold precisely
-- against live numbers as of this writing -- the original recon (§4 of recon_parking.md) had in fact
-- already characterized that ~$48 gap as generic "rounding/timing," not park MTM, before this task's
-- design doc re-characterized it. residual_after_park is still implemented exactly as specified
-- (existing raw residual, netted against park_unrealized: residual - park_unrealized) because that is
-- the literal, well-defined, useful computation the task names -- it remains meaningful as an ongoing
-- drift signal (its magnitude/trend over time, not a one-time "does it hit zero today" check) even
-- though it does not zero out today. Flagged here per HARD RULES rather than silently forcing a sign
-- or formula choice to make today's numbers look reconciled.

-- ===== analytics.park_nav_daily -- the park's own daily-chained NAV/TWR, vehicle-generalized =====
-- SUPERSEDED LIVE by bigquery/179_park_twr_fill_anchored.sql (2026-08-18): this definition marks a
-- vehicle switch at the CLOSE, but every park order fills at the OPEN (MARKET/DAY, 13:30:0X UTC), so
-- each of the three switch days in park history mis-attributes a full session's return to the OUTGOING
-- vehicle -- understating the AI by 0.490pp / 0.784pp / 1.391pp on 07-15 / 07-27 / 08-04 and inverting
-- two of the three legs of W5's PARK SCORECARD verdict. The `shares_prev` comment below cites
-- 03_twr_engine.sql as the "House TWR convention" for treating a same-day trade as a pure flow; that
-- citation is BACKWARDS -- 03_twr_engine.sql lines 100-110 anchor BOTH boundary days at the fill price
-- ("Fill-price boundaries matter: BURL was bought 303.00 but CLOSED 323.83 on entry day"). bigquery/179
-- brings the park onto that house convention. Do not edit this view body; it is DR-rebuild reference.
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.park_nav_daily` AS
WITH held_tickers AS (
  SELECT DISTINCT ticker
  FROM `stock-trading-498512.events.parking_events`
  WHERE ticker IS NOT NULL
),

-- Combined price/dividend series for every ticker the park has EVER held, daily_marks_curated
-- preferred over signal_marks_curated on a same (ticker, mark_date) row (src_priority tiebreak) --
-- this is the "close = COALESCE(daily_marks_curated close, signal_marks_curated close)" rule from the
-- approved spec, implemented as a priority pick (not a scalar COALESCE) so dividend travels with
-- whichever source's close won. SGOV/VOO/SPY live in daily_marks_curated; the other menu tickers
-- (GOVT/IEF/TLT/LQD/MUB/HYG/PFF/AOR/VTI) live only in signal_marks_curated until/unless a strategy
-- ever trades one directly.
combined_marks AS (
  SELECT ticker, mark_date, close, COALESCE(dividend, 0) AS dividend, 1 AS src_priority
  FROM `stock-trading-498512.state.daily_marks_curated`
  UNION ALL
  SELECT ticker, mark_date, close, COALESCE(dividend, 0) AS dividend, 2 AS src_priority
  FROM `stock-trading-498512.state.signal_marks_curated`
),
marks AS (
  SELECT cm.ticker, cm.mark_date, cm.close, cm.dividend
  FROM combined_marks cm
  JOIN held_tickers h USING (ticker)
  QUALIFY ROW_NUMBER() OVER (PARTITION BY cm.ticker, cm.mark_date ORDER BY cm.src_priority) = 1
),

-- Date axis: every date on which at least one ever-held park ticker has a mark, from the SGOV
-- founding date forward -- "mark dates available for park-held tickers" per the approved spec,
-- deliberately NOT "every calendar trading day," so the axis is exactly as dense as the real price
-- data (matching the voo_cumulative/sgov_cumulative precedent of deriving an axis from real rows,
-- never a generated calendar).
axis AS (
  SELECT DISTINCT mark_date AS as_of_date
  FROM marks
  WHERE mark_date >= DATE '2026-04-17'
),

-- Signed per-ticker share delta per (ticker, action_date) -- the exact BUY/DIVIDEND_REINVEST/
-- RECON_ADJUST(+), SELL(-) CASE from state.park_position (bigquery/54), grouped by day so a switch's
-- same-day SELL-old + BUY-new legs net correctly before the running total.
park_events_daily AS (
  SELECT ticker, action_date,
    SUM(CASE action
          WHEN 'BUY' THEN shares
          WHEN 'DIVIDEND_REINVEST' THEN shares
          WHEN 'RECON_ADJUST' THEN shares
          WHEN 'SELL' THEN -shares
          ELSE 0 END) AS shares_delta
  FROM `stock-trading-498512.events.parking_events`
  WHERE ticker IS NOT NULL
  GROUP BY ticker, action_date
),
cum_shares AS (
  SELECT ticker, action_date,
    SUM(shares_delta) OVER (
      PARTITION BY ticker ORDER BY action_date
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS shares_cum
  FROM park_events_daily
),

-- Cumulative shares AS OF each axis date (inclusive of that date's own activity) -- the basis for
-- park_mv. A ticker with no action on/before a given axis date has no row here (correctly contributes
-- $0 -- never touched yet).
shares_asof AS (
  SELECT a.as_of_date, c.ticker, c.shares_cum
  FROM axis a
  JOIN cum_shares c ON c.action_date <= a.as_of_date
  QUALIFY ROW_NUMBER() OVER (PARTITION BY a.as_of_date, c.ticker ORDER BY c.action_date DESC) = 1
),

-- Shares held GOING INTO each axis date (i.e., as of the PRIOR axis date) -- the exposure base for
-- that date's return leg. House TWR convention (03_twr_engine.sql): a same-day trade is a flow, not a
-- return event -- the day of a switch's SELL/BUY still prices against the OLD vehicle's move (full
-- exposure was carried into that morning); the NEW vehicle only starts contributing return the NEXT
-- axis date. The first day a ticker is ever bought has no earlier row -> COALESCE to 0 (no exposure
-- coming in, correctly zero return contribution that day).
shares_prev AS (
  SELECT as_of_date, ticker,
    COALESCE(LAG(shares_cum) OVER (PARTITION BY ticker ORDER BY as_of_date), 0) AS shares_prev
  FROM shares_asof
),

-- Per-ticker daily TOTAL return (close + dividend vs prior close), LAG'd over THAT TICKER's own
-- native mark_date sequence (not the union axis) -- same convention as analytics.voo_daily_return /
-- analytics.spy_daily_return, so a gap in one ticker's marks never corrupts another ticker's return.
ticker_returns AS (
  SELECT ticker, mark_date AS as_of_date,
    LAG(close) OVER (PARTITION BY ticker ORDER BY mark_date) AS prev_close,
    SAFE_DIVIDE(
      close + dividend - LAG(close) OVER (PARTITION BY ticker ORDER BY mark_date),
      LAG(close) OVER (PARTITION BY ticker ORDER BY mark_date)) AS r
  FROM marks
),

-- park_mv(t) = SUM(shares_asof(t) * close(t)) across every ticker with a same-day mark. KNOWN LIMIT
-- (documented, not an active bug): if the currently-held ticker has a same-day mark GAP while some
-- OTHER ever-held ticker still has a mark that day (keeping the date on the axis), that ticker's
-- contribution silently drops from the sum for that one day. SGOV and VOO have both had contiguous
-- daily marks throughout (verified live, 2026-07-18: 63/63 rows each since 2026-04-17) -- a latent
-- edge case only, not observed.
mv AS (
  SELECT sa.as_of_date, SUM(sa.shares_cum * m.close) AS park_mv
  FROM shares_asof sa
  JOIN marks m ON m.ticker = sa.ticker AND m.mark_date = sa.as_of_date
  GROUP BY sa.as_of_date
),

-- Value-weighted daily return across every ticker held going into the day -- the same
-- "capital-weighted, compounded" combination rule analytics.deployed_book_vs_benchmarks (bigquery/46)
-- uses for its book leg. Missing weight/return (no prior exposure that ticker, or a same-day mark gap)
-- contributes 0/0 -- the voo_cumulative "COALESCE(r,0) on gap days" convention, applied per ticker.
-- GREATEST(...,-0.9999) floors a single-ticker return before it enters the weighted sum (mirrors
-- bigquery/46's LN-input floor; defends the LN(1+r) chain below against a bad/implausible print).
daily_ret AS (
  SELECT sp.as_of_date,
    SAFE_DIVIDE(
      SUM(COALESCE(sp.shares_prev, 0) * COALESCE(tr.prev_close, 0)
          * COALESCE(GREATEST(tr.r, -0.9999), 0)),
      NULLIF(SUM(COALESCE(sp.shares_prev, 0) * COALESCE(tr.prev_close, 0)), 0)
    ) AS daily_return
  FROM shares_prev sp
  LEFT JOIN ticker_returns tr ON tr.ticker = sp.ticker AND tr.as_of_date = sp.as_of_date
  GROUP BY sp.as_of_date
),

-- Policy vehicle in effect AS OF each axis date -- see DEVIATION #1 at the top of this file:
-- thresholds on effective_date (not event_ts), event_ts DESC only as the tiebreak among rows sharing
-- an effective_date.
policy_asof AS (
  SELECT a.as_of_date, p.vehicle
  FROM axis a
  JOIN `stock-trading-498512.events.park_policy_changes` p
    ON p.effective_date <= a.as_of_date
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY a.as_of_date ORDER BY p.effective_date DESC, p.event_ts DESC) = 1
)
SELECT
  a.as_of_date,
  pa.vehicle,
  ROUND(COALESCE(mv.park_mv, 0), 2)          AS park_mv,
  COALESCE(dr.daily_return, 0)                AS daily_return,
  -- twr_index: chained via SUM(LN(1+r)) with COALESCE(r,0) on gap days -- the voo_cumulative
  -- precedent (bigquery/46) -- the level survives a gap and resumes correctly on the next real return.
  EXP(SUM(LN(1 + COALESCE(dr.daily_return, 0))) OVER (ORDER BY a.as_of_date)) - 1 AS twr_index
FROM axis a
LEFT JOIN mv          ON mv.as_of_date = a.as_of_date
LEFT JOIN daily_ret dr ON dr.as_of_date = a.as_of_date
LEFT JOIN policy_asof pa ON pa.as_of_date = a.as_of_date;

-- ===== analytics.park_counterfactuals -- SGOV / VOO / v1-rule-shadow / AI, same axis, four chained
-- total-return indices (PARK_ROUTER_DESIGN.md §9's three-way evaluation benchmark) =====
-- SUPERSEDED LIVE by bigquery/179_park_twr_fill_anchored.sql (2026-08-18), for two reasons: (1)
-- ai_index inherits analytics.park_nav_daily's switch-day marking bias (see that view's note above);
-- (2) `rule_leg` below joins `prs.mark_date = a.as_of_date`, paying the v1 rule shadow day d's own
-- close-to-close return for a classification state.park_rule_shadow derives from day d's OWN closing
-- signals -- an acausal look-ahead the AI's real decide-after-close / execute-next-open switches can
-- never have. bigquery/179 lags the shadow's vehicle by one axis position (measured effect on the
-- published level at 2026-08-17: rule_index -0.827% -> +0.303%). sgov_leg/voo_leg are correct as-is
-- and are carried over byte-identical. Do not edit this view body; it is DR-rebuild reference.
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.park_counterfactuals` AS
WITH axis AS (
  -- Reuses analytics.park_nav_daily's own date list verbatim -- guarantees the "same date axis" the
  -- spec calls for with no risk of independently re-deriving a slightly different one.
  SELECT as_of_date FROM `stock-trading-498512.analytics.park_nav_daily`
),

-- ===== SGOV leg -- byte-parallel to analytics.sgov_cumulative (bigquery/21): forward-fill convention
-- (a missing SGOV mark repeats the last known RATE -- correct for a cash-like accrual). =====
sgov_leg AS (
  SELECT a.as_of_date,
    COALESCE(
      sg.r_sgov,
      LAST_VALUE(sg.r_sgov IGNORE NULLS) OVER (
        ORDER BY a.as_of_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
      0) AS r_sgov
  FROM axis a
  LEFT JOIN `stock-trading-498512.analytics.sgov_daily_return` sg USING (as_of_date)
),
sgov_cum AS (
  SELECT as_of_date, EXP(SUM(LN(1 + r_sgov)) OVER (ORDER BY as_of_date)) - 1 AS sgov_index
  FROM sgov_leg
),

-- ===== VOO leg -- byte-parallel to analytics.voo_cumulative (bigquery/46), including its
-- NULL-on-gap display discipline (level still chains internally via COALESCE(r_voo,0)). =====
voo_leg AS (
  SELECT a.as_of_date, v.r_voo,
    MIN(CASE WHEN v.r_voo IS NOT NULL THEN a.as_of_date END) OVER () AS first_voo_date
  FROM axis a
  LEFT JOIN `stock-trading-498512.analytics.voo_daily_return` v USING (as_of_date)
),
voo_cum AS (
  SELECT as_of_date,
    CASE WHEN first_voo_date IS NULL OR as_of_date < first_voo_date THEN NULL
         WHEN r_voo IS NULL THEN NULL
         ELSE EXP(SUM(LN(1 + GREATEST(COALESCE(r_voo, 0), -0.9999)))
                  OVER (ORDER BY as_of_date)) - 1
    END AS voo_index
  FROM voo_leg
),

-- ===== Rule-shadow leg -- v1's deterministic regime->vehicle table, running record-only
-- (state.park_rule_shadow, bigquery/92). rule_vehicle can be ANY menu ticker (incl. ones that live
-- only in signal_marks_curated, e.g. TLT/LQD/...), so this needs the same combined-marks +
-- per-ticker-return construction as analytics.park_nav_daily above -- duplicated here rather than
-- shared (a BigQuery view's WITH chain cannot span two separate CREATE VIEW statements; same "inert
-- duplicate CTE" convention bigquery/90 uses for its copies of 31's/59's CTEs). Per the approved spec:
-- NULL rule_vehicle (no state.park_rule_shadow row for a date, or a recorded CASH call) -> r=0 carry,
-- via the LEFT JOINs + COALESCE below -- no special-case needed for CASH specifically, since a ticker
-- literally named 'CASH' simply never matches any marks row either. =====
rule_marks AS (
  SELECT ticker, mark_date, close, COALESCE(dividend, 0) AS dividend, 1 AS src_priority
  FROM `stock-trading-498512.state.daily_marks_curated`
  UNION ALL
  SELECT ticker, mark_date, close, COALESCE(dividend, 0) AS dividend, 2 AS src_priority
  FROM `stock-trading-498512.state.signal_marks_curated`
),
rule_marks_curated AS (
  SELECT ticker, mark_date, close, dividend
  FROM rule_marks
  QUALIFY ROW_NUMBER() OVER (PARTITION BY ticker, mark_date ORDER BY src_priority) = 1
),
rule_ticker_returns AS (
  SELECT ticker, mark_date AS as_of_date,
    SAFE_DIVIDE(
      close + dividend - LAG(close) OVER (PARTITION BY ticker ORDER BY mark_date),
      LAG(close) OVER (PARTITION BY ticker ORDER BY mark_date)) AS r
  FROM rule_marks_curated
),
rule_leg AS (
  -- NOTE: state.park_rule_shadow's date column is `mark_date` (bigquery/92, confirmed live in this
  -- session), not `as_of_date` -- joined here on that name explicitly rather than assumed.
  SELECT a.as_of_date,
    COALESCE(GREATEST(rtr.r, -0.9999), 0) AS r_rule
  FROM axis a
  LEFT JOIN `stock-trading-498512.state.park_rule_shadow` prs ON prs.mark_date = a.as_of_date
  LEFT JOIN rule_ticker_returns rtr
    ON rtr.ticker = prs.rule_vehicle AND rtr.as_of_date = a.as_of_date
),
rule_cum AS (
  SELECT as_of_date, EXP(SUM(LN(1 + r_rule)) OVER (ORDER BY as_of_date)) - 1 AS rule_index
  FROM rule_leg
)
SELECT
  a.as_of_date,
  sc.sgov_index,
  vc.voo_index,
  rc.rule_index,
  -- ai_index = analytics.park_nav_daily.twr_index joined by date, per the approved spec.
  pnd.twr_index AS ai_index
FROM axis a
LEFT JOIN sgov_cum sc USING (as_of_date)
LEFT JOIN voo_cum  vc USING (as_of_date)
LEFT JOIN rule_cum rc USING (as_of_date)
LEFT JOIN `stock-trading-498512.analytics.park_nav_daily` pnd USING (as_of_date);

-- ===== analytics.account_reconciliation -- SUPERSEDES bigquery/22_cash_flows.sql's definition (marker
-- added there, same commit). Every existing output column (total_deposits, strategy_realized_pnl,
-- events_side_nav_total, deployed_total, undeployed_total) is preserved byte-identical -- each is the
-- exact same correlated scalar subquery bigquery/22 uses. Two columns are added. =====
--
-- SUPERSEDED LIVE by bigquery/156_park_residual_sign_fix.sql -- current single source of truth for
-- this object. Kept here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT re-apply
-- this CREATE statement live in isolation: residual_after_park below has a SIGN ERROR (subtracts
-- park_unrealized where the DEVIATION #2 identity two paragraphs above it -- "raw residual ==
-- -park_unrealized" -- requires it to be ADDED), confirmed live 2026-08-08 (reports -245.54 where the
-- correct figure is -54.65). bigquery/156's header carries the full derivation and worked proof.
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.account_reconciliation` AS
WITH park_marks AS (
  SELECT ticker, mark_date, close FROM `stock-trading-498512.state.daily_marks_curated`
  UNION ALL
  SELECT ticker, mark_date, close FROM `stock-trading-498512.state.signal_marks_curated`
),
-- Latest available close per ticker (daily_marks_curated preferred via mark_date recency -- both
-- sources ingest daily, so "most recent mark_date" is the right tiebreak here; a true same-day tie
-- between the two sources for the SAME ticker/date is not expected in practice since a ticker lives in
-- exactly one source at a time (menu tickers not also strategy-held), but ORDER BY mark_date DESC
-- alone resolves any such tie arbitrarily-but-deterministically, matching this view's existing
-- correlated-subquery style rather than adding an explicit src_priority column for a case that should
-- not arise).
park_latest_close AS (
  SELECT ticker, close
  FROM park_marks
  QUALIFY ROW_NUMBER() OVER (PARTITION BY ticker ORDER BY mark_date DESC) = 1
),
-- Full-history signed share count + net cash per ticker, same CASE as state.park_position
-- (bigquery/54), generalized across every ticker the park has EVER held (not just the current policy
-- vehicle) so a mid-convergence dual-holding (PARK_ROUTER_DESIGN.md §5: "any park-book ticker != policy
-- vehicle above dust -> craft full SELL") is captured correctly, not just the officially-current one.
park_positions AS (
  SELECT ticker,
    SUM(CASE action
          WHEN 'BUY' THEN shares
          WHEN 'DIVIDEND_REINVEST' THEN shares
          WHEN 'RECON_ADJUST' THEN shares
          WHEN 'SELL' THEN -shares
          ELSE 0 END) AS shares,
    SUM(CASE action
          WHEN 'BUY'  THEN -(gross + COALESCE(commission, 0))
          WHEN 'SELL' THEN  (gross - COALESCE(commission, 0))
          ELSE 0 END) AS net_cash
  FROM `stock-trading-498512.events.parking_events`
  WHERE ticker IS NOT NULL
  GROUP BY ticker
),
-- Current park market value + cost basis, dust-guarded (ABS(shares) > 0.0005 -- aligned to the
-- >0.0005 dust floor used elsewhere in the park substrate: bigquery/92's park_position_current and
-- Operating_Protocols.md §13.E's stranded-leg rule; was 0.0001 here, LOW finding 2026-07-19) so a
-- fully-exited historical vehicle (e.g. SGOV, post-2026-07-15 cutover -- net shares ~0) does not
-- contribute. LEFT JOIN (was INNER -- HIGH finding 2026-07-19): an above-dust ticker with no mark
-- yet (e.g. a menu ticker just switched into, before its first signal_marks_curated/daily_marks_
-- curated close lands) must not silently vanish from park_unrealized -- it still HAS a cost basis
-- (net_cash is independent of marks); COALESCE(lc.close, 0) below means it contributes $0 market
-- value (NULL-safe, not a dropped row) until a real mark exists, mirroring bigquery/92's
-- park_reconciliation LEFT-JOIN-safe pattern. A bare aggregate with no GROUP BY always returns
-- exactly one row (SUM over zero matching rows is NULL, not zero rows), so this CTE never breaks
-- account_reconciliation's existing single-row contract even if every park ticker were somehow
-- dust-guarded out.
park_now AS (
  SELECT
    SUM(pp.shares * COALESCE(lc.close, 0))   AS park_mv_now,
    SUM(-pp.net_cash)                         AS park_cost_basis
  FROM park_positions pp
  LEFT JOIN park_latest_close lc USING (ticker)
  WHERE ABS(pp.shares) > 0.0005
)
SELECT
  (SELECT ROUND(SUM(amount), 2) FROM `stock-trading-498512.events.cash_flows`)                    AS total_deposits,
  (SELECT ROUND(SUM(realized_pnl), 2) FROM `stock-trading-498512.state.trade_fills_curated`)      AS strategy_realized_pnl,
  (SELECT ROUND(SUM(nav), 2) FROM `stock-trading-498512.analytics.strategy_nav`)                  AS events_side_nav_total,
  (SELECT ROUND(SUM(deployed_mv), 2) FROM `stock-trading-498512.analytics.strategy_nav`)          AS deployed_total,
  (SELECT ROUND(SUM(available_funds), 2) FROM `stock-trading-498512.analytics.strategy_nav`)      AS undeployed_total,
  -- park_unrealized = current park market value - park cost basis (both derived from
  -- events.parking_events + marks, per the approved spec). See DEVIATION #2 at the top of this file:
  -- live-verified 2026-07-18 at approximately -96.33 (VOO's price has drifted slightly below its
  -- 2026-07-15 acquisition cost).
  ROUND(COALESCE(pn.park_mv_now, 0) - COALESCE(pn.park_cost_basis, 0), 2)                         AS park_unrealized,
  -- residual_after_park = the existing events-vs-live residual (undeployed_total - park MV - cash),
  -- with park_unrealized explicitly netted out (subtracted): the raw gap MINUS the portion this file
  -- now separately attributes to the park's own mark-to-market move. See DEVIATION #2: live-verified
  -- 2026-07-18, this does NOT converge to ~0 with today's numbers (raw residual +47.58 vs
  -- park_unrealized -96.33) -- the design doc's "the ~$50 gap IS park unrealized P&L" framing does not
  -- hold precisely today. The column is still exactly what the approved spec names and remains a
  -- useful ongoing drift signal independent of that one framing claim.
  ROUND(
    (
      (SELECT SUM(available_funds) FROM `stock-trading-498512.analytics.strategy_nav`)
      - COALESCE(pn.park_mv_now, 0)
      - COALESCE((SELECT total_cash FROM `stock-trading-498512.state.account_latest`), 0)
    ) - (COALESCE(pn.park_mv_now, 0) - COALESCE(pn.park_cost_basis, 0))
  , 2)                                                                                             AS residual_after_park
FROM park_now pn;

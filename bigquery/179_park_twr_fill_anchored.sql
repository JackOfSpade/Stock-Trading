-- Park performance measurement integrity (2026-08-18, interactive session). Project: stock-trading-498512.
--
-- WHY. The operator asked whether the 2026-08-18 VOO dip could have been timed, or whether the
-- idle-capital allocation logic is broken. The allocator itself turned out to be sound; its
-- SCORECARD did not. Two independent measurement defects were found in the park's own
-- self-assessment chain, both verified live this session against view DDL, raw rows, and raw price
-- marks. Together they invert the headline verdict W5 has published every week since 2026-07-19.
--
-- ============================================================================
-- DEFECT 1 (this file, object 1) -- analytics.park_nav_daily marks a vehicle switch at the CLOSE,
-- but every park order actually fills at the OPEN.
-- ============================================================================
-- bigquery/93_park_accounting.sql's `daily_ret` weights each ticker's CLOSE-TO-CLOSE return by
-- `shares_prev` (= LAG(shares_cum), the shares held going into the day). That is only correct if the
-- day's trade lands at the CLOSE valuation point. It does not: D2 stages park legs MARKET/DAY and
-- D2a records every fill at 13:30:0X UTC -- the market OPEN -- verified across all three switches in
-- park history (events.parking_events). So on a switch day the OUTGOING vehicle is credited with its
-- full close-to-close move (though it was sold hours earlier at the open) and the INCOMING vehicle is
-- credited with NOTHING (shares_prev = 0), only starting to accrue the next day off that day's close.
--
-- The in-line comment at bigquery/93 lines 166-171 justifies this as the "House TWR convention
-- (03_twr_engine.sql): a same-day trade is a flow, not a return event". That citation is factually
-- backwards. bigquery/03_twr_engine.sql lines 100-105 state the OPPOSITE and say why:
--     entry day: prev_mv = shares*entry_price   (baseline at MARKET cost, no comm)
--     exit  day: mv      = shares*exit_price    (GROSS proceeds, no comm)
--     "Fill-price boundaries matter: BURL was bought 303.00 but CLOSED 323.83 on entry day;
--      a close-baseline would mis-state it badly."
-- and line 110 implements it: `IF(m.mark_date = l.exit_date, l.exit_price, m.close)`. The house
-- engine already anchors BOTH boundary days at the fill price. This file brings the park onto that
-- same convention, so the fix REMOVES an inconsistency rather than introducing a new convention.
--
-- MEASURED ERROR (all three switches; recomputed three independent ways this session, agreeing to
-- ~0.01pp -- fill-weighted arithmetic, live daily_return column, and a hand-chained reconstruction):
--   2026-07-15 SGOV->VOO : model -0.50774%  vs corrected -0.01746%  ->  model understates 0.490pp
--   2026-07-27 VOO->SGOV : model +0.02503%  vs corrected +0.80893%  ->  model understates 0.784pp
--   2026-08-04 SGOV->VOO : model +0.00996%  vs corrected +1.40126%  ->  model understates 1.391pp
-- The error is confined to the switch date itself -- day t+1 already prices off day t's close under
-- either convention, so there is no spillover and no need to touch any other date.
--
-- CONSEQUENCE (the reason this is not cosmetic). analytics.park_counterfactuals.ai_index IS
-- park_nav_daily.twr_index, and W5's PARK SCORECARD grades the AI allocator against three
-- benchmarks off that column. The three benchmark series are each computed from clean, never-switching
-- close-to-close chains, so ONLY the AI's own series carries this penalty -- an asymmetry precisely in
-- the comparison the scorecard exists to make. Published standings at 2026-08-17 vs corrected --
-- both columns MEASURED by running each corrected view body against live data this session, not
-- estimated by applying a correction factor to the published level:
--     ai_index   -1.019%  ->  +1.531%   AI goes from trailing to BEATING SGOV (+33bp)
--     sgov_index +1.200%   (unchanged -- never switches, so neither defect can touch it)
--     rule_index -0.827%  ->  +0.303%   corrected by DEFECT 2 below; AI still beats it (+123bp)
--     voo_index  +9.126%   (unchanged)  AI still TRAILS VOO by ~760bp -- a real opportunity cost
--                                   of being out 2026-07-27..08-04 while VOO rallied, NOT an artifact
-- Per-day deltas measured on the switch dates: 07-15 +49.3bp, 07-27 +78.3bp, 08-04 +131.8bp; and
-- confirmed ZERO on adjacent non-switch dates (07-16, 08-17), i.e. no spillover, as predicted.
-- The two same-vehicle flow days move only slightly: 08-06 sweep -1.7bp, 08-11 withdrawal +4.6bp.
-- Five consecutive park-scorecard decision_log entries (2026-07-19 .. 2026-08-17) concluded the AI
-- "trails ALL THREE benchmarks including the rejected rule table". Two of those three legs are
-- artifacts. The one that survives (trails VOO) is genuine and is NOT softened by this file.
--
-- Note also that bigquery/93's own header (line 56) already required "W5's PARK SCORECARD must note
-- any measurement window overlapping a switch date rather than treat that day's TWR point as clean."
-- No W5 park-scorecard entry has ever carried that caveat -- so the documented weaker mitigation was
-- not happening either. With this fix the caveat is no longer needed for switch days.
--
-- SCOPE OF THE REDEFINITION. Fill-price anchoring is applied UNIFORMLY to every day with park
-- activity, not special-cased to switch days, because that is the house convention and because a
-- same-vehicle sweep has the identical (smaller) issue: capital deployed at the open earns
-- fill->close, not nothing. Worked example, the 2026-08-06 deposit-funded sweep: 14.0906 sh bought at
-- wavg 707.8224 against a 706.40 close, so the new money lost 0.201% intraday -- the old convention
-- recorded that day as a flat VOO close-to-close -0.170%, the corrected one as -0.186%. Direction and
-- magnitude are both small for sweeps; the switch days are where it matters. RECON_ADJUST is treated
-- as arriving AT the close (zero return contribution, zero capital at risk): it is a 13.D bookkeeping
-- correction against the connector's authoritative holding, not a market transaction, and carries no
-- real per-share price.
--
-- ============================================================================
-- DEFECT 2 (this file, object 2) -- park_counterfactuals.rule_index has a LOOK-AHEAD advantage the
-- AI's real switches can never have.
-- ============================================================================
-- state.park_rule_shadow (bigquery/92 lines 299-330) picks each day's rule_vehicle from
-- state.park_signal_daily columns for that SAME mark_date -- vix_close, spy_close, spy_200dma,
-- dd_from_252d_high, shock_overlay -- all end-of-day-d values, knowable only after day d closes.
-- bigquery/93's `rule_leg` then joins `prs.mark_date = a.as_of_date` and credits the shadow with day
-- d's OWN close-to-close return. Earning day d's return requires being positioned before day d
-- opens, so the benchmark is being paid for a decision it could not have made in time.
--
-- Demonstrated live: the shadow flipped VOO->SGOV on 2026-08-03 driven by 08-03's own close
-- (shock_overlay='acute'), and rule_index moved only +0.0165% that day (SGOV-like) instead of VOO's
-- actual +1.4199%. Measured effect of the lag fix on the published level at 2026-08-17:
-- rule_index -0.827% -> +0.303%, i.e. the look-ahead had been UNDER-stating the shadow by ~113bp. So
-- in this instance the look-ahead HURT the shadow -- the direction is not systematically favourable,
-- which is exactly why it must be fixed rather than argued about: an acausal benchmark is simply not
-- a benchmark. This file lags the vehicle by one axis position, so day d-1's classification governs
-- day d's return -- matching the decide-after-close / execute-next-open cadence the AI itself runs
-- (events.park_policy_changes: 07-26 effective -> 07-27 fill; 08-03 effective -> 08-04 fill).
--
-- Residual, deliberately NOT modelled: the shadow still transacts at a close while the AI transacts
-- at an open, and pays no commission. A record-only benchmark has no fill price to anchor to, so this
-- is inherent to the construct, not fixable here. It is now a ~1-2bp-per-switch asymmetry instead of
-- a full-session one. sgov_index/voo_index need no change -- they never switch, so neither defect
-- can touch them (verified: both reproduce independently from raw price+dividend data).
--
-- ============================================================================
-- RECORD-ONLY. Both views are measurement surfaces. They gate nothing, size nothing, trigger no kill,
-- and feed no order path -- `grep -rn "park_nav_daily\|park_counterfactuals"` reaches only W5's
-- PARK SCORECARD read, analytics.park_baseline, and this file. Correcting them changes no trade,
-- past or future; it changes what the system believes about its own park judgment.
--
-- NOT APPLIED LIVE BY THIS SESSION (interactive session -- operator approves apply/push separately;
-- CLAUDE.md "Interactive sessions must ASK"). SUPERSEDES the analytics.park_nav_daily and
-- analytics.park_counterfactuals definitions in bigquery/93_park_accounting.sql (that file's headers
-- updated in the same commit, per bigquery/README.md supersede discipline). Apply after
-- bigquery/93_park_accounting.sql and bigquery/156_park_residual_sign_fix.sql. After applying, W5's
-- next PARK SCORECARD will re-derive and should log a correction entry noting the prior five entries
-- were computed under the switch-day bias.

-- ============================================================================
-- analytics.park_nav_daily -- REDEFINED: fill-anchored boundary pricing (house convention,
-- bigquery/03_twr_engine.sql). Column shape UNCHANGED (as_of_date, vehicle, park_mv, daily_return,
-- twr_index) so every existing reader is unaffected.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.park_nav_daily` AS
WITH held_tickers AS (
  SELECT DISTINCT ticker
  FROM `stock-trading-498512.events.parking_events`
  WHERE ticker IS NOT NULL
),
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
axis AS (
  SELECT DISTINCT mark_date AS as_of_date
  FROM marks
  WHERE mark_date >= DATE '2026-04-17'
),
-- Per-ticker, per-day traded legs at their ACTUAL fill prices. Share-weighted average price per
-- (ticker, day, direction) -- a day with several partials (the 08-04 re-entry had five) collapses to
-- one wavg, which is exactly the price the book transacted at in aggregate. RECON_ADJUST is excluded
-- from both directions (bookkeeping correction, no real price -- see file header); it still moves
-- shares via park_events_daily below, it just contributes no return and no capital at risk.
traded_legs AS (
  SELECT ticker, action_date,
    SUM(IF(action = 'SELL', shares, 0))                                   AS shares_sold,
    SAFE_DIVIDE(SUM(IF(action = 'SELL', shares * price, 0)),
                NULLIF(SUM(IF(action = 'SELL', shares, 0)), 0))           AS sell_price,
    SUM(IF(action IN ('BUY', 'DIVIDEND_REINVEST'), shares, 0))            AS shares_bought,
    SAFE_DIVIDE(SUM(IF(action IN ('BUY', 'DIVIDEND_REINVEST'), shares * price, 0)),
                NULLIF(SUM(IF(action IN ('BUY', 'DIVIDEND_REINVEST'), shares, 0)), 0)) AS buy_price
  FROM `stock-trading-498512.events.parking_events`
  WHERE ticker IS NOT NULL AND shares IS NOT NULL AND price IS NOT NULL
  GROUP BY ticker, action_date
),
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
shares_asof AS (
  SELECT a.as_of_date, c.ticker, c.shares_cum
  FROM axis a
  JOIN cum_shares c ON c.action_date <= a.as_of_date
  QUALIFY ROW_NUMBER() OVER (PARTITION BY a.as_of_date, c.ticker ORDER BY c.action_date DESC) = 1
),
shares_prev AS (
  SELECT as_of_date, ticker,
    COALESCE(LAG(shares_cum) OVER (PARTITION BY ticker ORDER BY as_of_date), 0) AS shares_prev
  FROM shares_asof
),
-- Per-ticker daily TOTAL return (close + dividend vs prior close), LAG'd over THAT TICKER's own
-- native mark_date sequence -- unchanged from bigquery/93. Used for shares carried through the whole
-- session; the traded legs below price off their own fills instead.
ticker_returns AS (
  SELECT ticker, mark_date AS as_of_date, close, dividend,
    LAG(close) OVER (PARTITION BY ticker ORDER BY mark_date) AS prev_close,
    SAFE_DIVIDE(
      close + dividend - LAG(close) OVER (PARTITION BY ticker ORDER BY mark_date),
      LAG(close) OVER (PARTITION BY ticker ORDER BY mark_date)) AS r
  FROM marks
),
mv AS (
  SELECT sa.as_of_date, SUM(sa.shares_cum * m.close) AS park_mv
  FROM shares_asof sa
  JOIN marks m ON m.ticker = sa.ticker AND m.mark_date = sa.as_of_date
  GROUP BY sa.as_of_date
),
-- Dollar P&L and capital-at-risk per (day, ticker), decomposed into three legs:
--   carried  : shares held from the prior close and NOT sold today -> full close-to-close total return
--   sold     : shares disposed at the open -> prior close -> actual sell fill only
--   bought   : shares acquired at the open -> actual buy fill -> today's close
-- Dividends attach to the carried leg only. A share bought ON an ex-date does not receive that
-- distribution (the price has already adjusted), and a share sold at the open of an ex-date is an
-- immaterial edge case never yet realised in park history -- so both traded legs price on price alone.
leg_pnl AS (
  SELECT
    sp.as_of_date, sp.ticker,
    GREATEST(sp.shares_prev - COALESCE(tl.shares_sold, 0), 0)             AS shares_carried,
    COALESCE(tl.shares_sold, 0)                                            AS shares_sold,
    COALESCE(tl.shares_bought, 0)                                          AS shares_bought,
    tr.prev_close, tr.close, tr.dividend, tl.sell_price, tl.buy_price,
    -- carried leg
    GREATEST(sp.shares_prev - COALESCE(tl.shares_sold, 0), 0)
      * COALESCE(tr.close + tr.dividend - tr.prev_close, 0)                AS pnl_carried,
    -- sold leg (prior close -> fill). Needs BOTH a fill price and a prior close to be meaningful.
    IF(tl.sell_price IS NOT NULL AND tr.prev_close IS NOT NULL,
       COALESCE(tl.shares_sold, 0) * (tl.sell_price - tr.prev_close), 0)   AS pnl_sold,
    -- bought leg (fill -> close)
    IF(tl.buy_price IS NOT NULL AND tr.close IS NOT NULL,
       COALESCE(tl.shares_bought, 0) * (tr.close - tl.buy_price), 0)       AS pnl_bought,
    -- capital carried into the day at its prior close
    sp.shares_prev * COALESCE(tr.prev_close, 0)                            AS cap_bod,
    -- notional actually transacted today, used to separate internal rotation from external inflow
    COALESCE(tl.shares_sold, 0) * COALESCE(tl.sell_price, 0)               AS sold_notional,
    COALESCE(tl.shares_bought, 0) * COALESCE(tl.buy_price, 0)              AS bought_notional
  FROM shares_prev sp
  LEFT JOIN ticker_returns tr ON tr.ticker = sp.ticker AND tr.as_of_date = sp.as_of_date
  LEFT JOIN traded_legs   tl ON tl.ticker = sp.ticker AND tl.action_date = sp.as_of_date
),
-- Roll up to the park. The return BASE is the park's beginning-of-day value plus any capital that
-- genuinely entered from OUTSIDE the park today (a deposit- or dividend-funded sweep), weighted 1.0
-- because it was deployed at the open. Capital that merely ROTATED between vehicles inside the park
-- (a switch: today's buys funded by today's sells) must NOT be added -- counting it would double the
-- base and halve the day's return. LEAST(buys, sells) is that internal rotation; only the excess of
-- buys over sells is a true external inflow.
daily_ret AS (
  SELECT
    as_of_date,
    SAFE_DIVIDE(
      SUM(pnl_carried + pnl_sold + pnl_bought),
      NULLIF(SUM(cap_bod)
             + GREATEST(SUM(bought_notional) - SUM(sold_notional), 0), 0)
    ) AS daily_return
  FROM leg_pnl
  GROUP BY as_of_date
),
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

-- ============================================================================
-- analytics.park_counterfactuals -- REDEFINED: rule_index vehicle lagged one axis position so the
-- shadow is CAUSAL (decide on day d-1's close, earn day d's return), matching the AI's own
-- decide-after-close / execute-next-open cadence. Column shape UNCHANGED (as_of_date, sgov_index,
-- voo_index, rule_index, ai_index). sgov_leg / voo_leg are byte-identical to bigquery/93.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.park_counterfactuals` AS
WITH axis AS (
  SELECT as_of_date FROM `stock-trading-498512.analytics.park_nav_daily`
),
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
-- The prior AXIS date (not calendar date) for each day -- so a Monday's return is governed by the
-- preceding Friday's classification, with no weekend hole and no assumption of contiguous dates.
axis_prev AS (
  SELECT as_of_date,
    LAG(as_of_date) OVER (ORDER BY as_of_date) AS prev_as_of_date
  FROM axis
),
rule_leg AS (
  -- state.park_rule_shadow's date column is `mark_date` (bigquery/92), not `as_of_date`.
  -- LAGGED join (this file's DEFECT 2 fix): day d-1's rule_vehicle governs day d's return, because
  -- park_rule_shadow classifies from day d-1's OWN closing signals and could not have been acted on
  -- before day d opened. bigquery/93 joined prs.mark_date = a.as_of_date, paying the shadow for a
  -- same-day decision -- an acausal advantage the AI's real, lagged switches never get.
  SELECT ap.as_of_date,
    COALESCE(GREATEST(rtr.r, -0.9999), 0) AS r_rule
  FROM axis_prev ap
  LEFT JOIN `stock-trading-498512.state.park_rule_shadow` prs
    ON prs.mark_date = ap.prev_as_of_date
  LEFT JOIN rule_ticker_returns rtr
    ON rtr.ticker = prs.rule_vehicle AND rtr.as_of_date = ap.as_of_date
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
  -- ai_index = analytics.park_nav_daily.twr_index joined by date, per the approved spec -- now
  -- fill-anchored (this file's DEFECT 1 fix), so it is measured on the same footing as the benchmarks.
  pnd.twr_index AS ai_index
FROM axis a
LEFT JOIN sgov_cum sc USING (as_of_date)
LEFT JOIN voo_cum  vc USING (as_of_date)
LEFT JOIN rule_cum rc USING (as_of_date)
LEFT JOIN `stock-trading-498512.analytics.park_nav_daily` pnd USING (as_of_date)
;

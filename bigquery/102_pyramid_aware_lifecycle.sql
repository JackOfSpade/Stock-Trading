-- Pyramid-aware accounting rebuild (owner directive 2026-07-20, "allow adds for A/B/D"). Project:
-- stock-trading-498512. Apply after bigquery/101_market_only_decision_seed.sql.
--
-- WHY. analytics.position_lifecycle (bigquery/03_twr_engine.sql) pairs the Nth BUY of a
-- (strategy,ticker) to the Nth SELL via ROW_NUMBER() leg_seq. That is correct ONLY when every
-- position is a single entry / single exit. The moment a strategy adds to a winner (a pyramid: 2+
-- BUYs before the matching SELL(s)) OR re-enters a name after a full round-trip, leg_seq pairing can
-- break two ways:
--   (1) an add-leg with no matching Nth SELL is LEFT-JOIN-NULL on exit_date forever -- it would read
--       as "still open" even after the strategy has fully exited the name (a partial-exit sale
--       silently dropped from realized P&L, corrupting analytics.strategy_daily_returns' TWR, both
--       kill-flag checks that gate off `exit_date IS NOT NULL`, and the 30-trade calibration gate).
--   (2) a SECOND full round-trip on the SAME (strategy,ticker) shifts every subsequent leg_seq by
--       one, mis-pairing an unrelated later BUY to an earlier SELL's leg_seq slot.
-- The PRECONDITION (2+ BUYs on one (strategy,ticker)) is already live: confirmed 2026-07-21 via a
-- live read-only query, strategy B has 2 BUYs/1 SELL on both HCA and IBM, and 2 BUYs/0 SELLs on MDT;
-- strategy D has 2 BUYs/0 SELLs on RTX. Also confirmed live: TODAY's actual closed_trades count is
-- NOT yet wrong for either strategy (B=8, D=0, identical under both the old lot-level COUNT and the
-- new campaign-level COUNT) -- HCA/IBM's two BUYs are a full close-then-fresh-re-entry (sequential,
-- non-overlapping), which ROW_NUMBER pairs correctly "by luck" of fill-order alignment, and MDT/RTX
-- have 0 SELLs yet so nothing has been mis-dropped. Both bug classes are real and already reachable
-- (this system already carries multi-BUY (strategy,ticker) pairs), but neither has fired incorrect
-- output YET -- they are latent, one interleaved add-then-partial-exit or one second full round-trip
-- away from firing, and firing silently (no error, just a wrong closed_trades / gate_n / TWR number).
-- This file closes that gap before "allow adds" (the owner directive this ships under) makes
-- deliberate, frequent pyramiding routine instead of incidental.
--
-- WHAT. Two-tier accounting, reusing the FIFO cumulative-interval-overlap technique from
-- bigquery/41_tax_lots.sql / bigquery/50_short_sale_tax_lots.sql (already validated live for exactly
-- this kind of many-BUY-to-many-SELL matching problem):
--   TIER 1 analytics.position_lifecycle (THIS FILE) -- FIFO LOTS, partitioned by (strategy,ticker)
--     (unlike tax_lots' account-wide ticker-only partition -- the per-strategy wall stays, matching
--     the object this supersedes). Every lot is the overlap between one BUY's cumulative-share
--     interval and one SELL's, in fill-time order; an unconsumed BUY tail is an OPEN lot. A pyramid
--     add's shares that are later partially sold now correctly split into a CLOSED lot (the sold
--     portion) + an OPEN lot (the rest) instead of one leg being dropped. EXACT SAME 12 output
--     columns (names + types) as the superseded view -- every downstream consumer (strategy_daily_
--     returns, option_mark_anomalies, kill_flags via sp_recompute_engine) keeps working unchanged.
--   TIER 2 analytics.position_campaigns (NEW) -- CAMPAIGNS: a running signed-share position per
--     (strategy,ticker); a campaign runs from the first BUY that takes the position from flat (0) to
--     non-flat, through every add/partial-exit, to the fill that returns it to flat (close) or to the
--     latest fill if still open. A pyramid with 2 adds + 1 partial exit + 1 final exit is ONE
--     campaign, not up to 4 disconnected lots. This is what "a trade" means for closed_trades /
--     gate_n / thesis_outcomes going forward -- a partial-exit pyramid must count as ONE closed trade
--     toward the 30-trade calibration gate, not fan out per lot.
--   ops.sp_recompute_engine -- REBUILD, byte-for-byte identical to the current canonical body
--     (bigquery/40_options_marks.sql:167-233) except the closed_trades / gate_n subqueries now COUNT
--     off analytics.position_campaigns instead of analytics.position_lifecycle (campaign-level closed
--     count). perf.strategy_daily's deployed_unit_value/current_drawdown/excess_vs_sgov are UNCHANGED
--     (those flow from analytics.strategy_daily_returns, which reads Tier-1 lots and needs no edit --
--     lots already carry correct entry/exit dates+prices per share, which is all TWR needs).
--   analytics.thesis_outcomes -- REBUILD, identical to the current canonical body
--     (bigquery/04_analytics.sql:88-125) except the LEFT JOIN target + the QUALIFY nearest-entry_date
--     window move from analytics.position_lifecycle to analytics.position_campaigns -- a pyramid add's
--     own thesis-construction entry legitimately maps to the SAME campaign as the position's original
--     entry, not a separate lot-level row.
--
-- SCOPE. Long-only-correct ONLY. Strategy E's short-sale mislabeling (bigquery/50_short_sale_tax_
-- lots.sql's fix -- chronological entry/exit, not hardcoded BUY=entry/SELL=exit) is DEFERRED here,
-- unchanged from today's analytics.position_lifecycle (which has never handled shorts correctly
-- either -- see 50's header). Tier 2's campaign-open detection (COUNTIF(prev=0 AND cur!=0)) also
-- assumes a campaign always OPENS with a BUY (running_shares 0 -> positive); a short campaign
-- (0 -> negative via a SELL) is not distinguished from noise here and is left for a future file, same
-- as Tier 1.
--
-- SUPERSEDES: analytics.position_lifecycle + ops.sp_recompute_engine from bigquery/03_twr_engine.sql;
-- ops.sp_recompute_engine from bigquery/40_options_marks.sql; analytics.thesis_outcomes from
-- bigquery/04_analytics.sql. Per the supersede-only discipline (scripts/check_superseded_markers.py),
-- those four definitions are left unmodified with a marker comment pointing here -- see the separate
-- edits to 03_twr_engine.sql / 40_options_marks.sql / 04_analytics.sql. analytics.position_campaigns
-- is a NEW object (no prior definition to supersede).
--
-- Prereqs: state.trade_fills_curated (bigquery/01_schema.sql, tiebreak-fixed by
-- bigquery/53_curated_view_tiebreak_fix.sql), analytics.strategy_daily_returns /
-- analytics.sgov_daily_return (bigquery/82_split_aware_engine.sql is the live canonical for
-- strategy_daily_returns -- untouched by this file), state.option_mark_anomalies
-- (bigquery/40_options_marks.sql), ops.sp_raise_alert_once (bigquery/08_ops_procedures.sql),
-- events.decision_log / events.regime_events (bigquery/01_schema.sql).

-- ============================================================================
-- TIER 1: analytics.position_lifecycle -- FIFO LOTS per (strategy,ticker)
-- Column types verified against the CURRENT LIVE view (analytics.position_lifecycle, INFORMATION_
-- SCHEMA.COLUMNS, read 2026-07-21) and state.trade_fills_curated's DDL (bigquery/01_schema.sql):
-- shares/price/commission/realized_pnl are all NUMERIC there, so every arithmetic expression below
-- (products of NUMERIC values and SAFE_DIVIDE() over them, which is also NUMERIC-in/NUMERIC-out)
-- stays NUMERIC end to end -- see the file-level report for the full 12-column type derivation.
-- SGOV EXCLUSION preserved verbatim in both base CTEs (buys/
-- sells), matching the superseded view's SGOV-contamination rationale (bigquery/03_twr_engine.sql:49-
-- 55): a stray SGOV fill in trade_fills must never become a deployed lifecycle lot. entry_date/
-- exit_date use DATE(fill_ts,'America/New_York') for the same reason as the superseded view -- the
-- EXCHANGE TRADING DATE the daily-marks join and every downstream DATE_DIFF/window keys on.
--
-- SUPERSEDED LIVE by bigquery/125_dust_excluded_from_twr.sql (2026-08-02), which appends the audited
-- fill-level is_dust flag used to exclude orphan DRIP lots from deployed TWR. Kept here for apply-order
-- history only; do not re-apply this definition in isolation.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.position_lifecycle` AS
WITH buys AS (
  SELECT trade_id, strategy, ticker, contract_id, fill_ts, price, shares, commission,
    -- cum_start = total BUY shares in this (strategy,ticker) strictly before this fill (FIFO entry
    -- order) -- identical construct to bigquery/41_tax_lots.sql's `buys.cum_start`, just partitioned
    -- by (strategy,ticker) instead of ticker-only (the per-strategy wall this view preserves).
    COALESCE(SUM(shares) OVER (PARTITION BY strategy, ticker ORDER BY fill_ts, trade_id
      ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS cum_start
  FROM `stock-trading-498512.state.trade_fills_curated`
  WHERE side = 'BUY' AND ticker != 'SGOV' AND shares IS NOT NULL AND shares > 0
),
sells AS (
  SELECT trade_id, strategy, ticker, fill_ts, price, shares, commission, realized_pnl,
    COALESCE(SUM(shares) OVER (PARTITION BY strategy, ticker ORDER BY fill_ts, trade_id
      ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS cum_start
  FROM `stock-trading-498512.state.trade_fills_curated`
  WHERE side = 'SELL' AND ticker != 'SGOV' AND shares IS NOT NULL AND shares > 0
),
-- Every (buy, sell) pair on the same (strategy,ticker) whose cumulative-share intervals overlap; the
-- overlap width is the FIFO-matched share count between that specific buy lot and that specific sell
-- fill -- correct regardless of how buys/sells interleave in time (a pyramid add, then a partial
-- exit, then another add, then the final exit, all resolve correctly with no procedural loop).
matched AS (
  SELECT b.strategy, b.ticker, b.contract_id,
    b.trade_id AS buy_trade_id, b.fill_ts AS buy_fill_ts, b.price AS buy_price,
    b.shares AS buy_shares, b.commission AS buy_commission,
    s.trade_id AS sell_trade_id, s.fill_ts AS sell_fill_ts, s.price AS sell_price,
    s.shares AS sell_shares, s.commission AS sell_commission, s.realized_pnl AS sell_realized_pnl,
    LEAST(b.cum_start + b.shares, s.cum_start + s.shares) - GREATEST(b.cum_start, s.cum_start) AS shares_matched
  FROM buys b
  JOIN sells s ON s.strategy = b.strategy AND s.ticker = b.ticker
  WHERE LEAST(b.cum_start + b.shares, s.cum_start + s.shares) > GREATEST(b.cum_start, s.cum_start)
),
-- Portion of each BUY not yet consumed by any SELL to date = still-open shares of that lot.
buy_matched_totals AS (
  SELECT strategy, ticker, buy_trade_id, SUM(shares_matched) AS total_matched
  FROM matched
  GROUP BY 1, 2, 3
),
open_tail AS (
  -- NOTE: aliased explicitly (buy_trade_id/buy_fill_ts/buy_price/buy_shares/buy_commission), NOT a
  -- bare `b.*` -- the OPEN-lot SELECT below reads those buy_-prefixed names (same convention as the
  -- `matched` CTE above); a bare `b.*` would carry buys' raw column names (trade_id/fill_ts/price/
  -- shares/commission) instead and the OPEN-lot SELECT would fail with "Unrecognized name".
  SELECT
    b.strategy, b.ticker, b.contract_id,
    b.trade_id AS buy_trade_id, b.fill_ts AS buy_fill_ts, b.price AS buy_price,
    b.shares AS buy_shares, b.commission AS buy_commission,
    b.shares - COALESCE(t.total_matched, 0) AS open_shares
  FROM buys b
  LEFT JOIN buy_matched_totals t
    ON t.strategy = b.strategy AND t.ticker = b.ticker AND t.buy_trade_id = b.trade_id
  WHERE b.shares - COALESCE(t.total_matched, 0) > 0.0000001   -- guard FP noise on fractional-share fills
)
-- CLOSED lot pieces (a buy interval matched to a sell interval). NOTE: entry_commission/
-- exit_commission/realized_pnl are NOT wrapped in ROUND(...,4) (unlike bigquery/41_tax_lots.sql's
-- CLOSED-lot projection, which prices whole-cent equities) -- this system trades fractional shares
-- down to ~1/100 of a share (verified live 2026-07-21: e.g. AZO shares=0.0121), so commission/
-- realized_pnl are prorated to 6-8 decimal places, not 2. Rounding to 4 decimals is LOSSY on real
-- data and breaks the single-entry byte-identical regression below (confirmed live: with ROUND(...,4)
-- every one of the 6 real single-entry positions differed from today's view on these 3 columns;
-- without it, 0 differences). NUMERIC arithmetic already has a fixed max scale of 9 decimal digits,
-- so no explicit rounding is needed to keep the column NUMERIC-typed.
SELECT
  CONCAT(strategy, ':', ticker, ':', buy_trade_id, ':', sell_trade_id) AS position_key,
  strategy, ticker, contract_id,
  shares_matched AS shares,
  DATE(buy_fill_ts, 'America/New_York') AS entry_date,
  buy_price AS entry_price,
  shares_matched * SAFE_DIVIDE(buy_commission, NULLIF(buy_shares, 0)) AS entry_commission,
  DATE(sell_fill_ts, 'America/New_York') AS exit_date,
  sell_price AS exit_price,
  shares_matched * SAFE_DIVIDE(sell_commission, NULLIF(sell_shares, 0)) AS exit_commission,
  sell_realized_pnl * SAFE_DIVIDE(shares_matched, NULLIF(sell_shares, 0)) AS realized_pnl
FROM matched
UNION ALL
-- OPEN lot remainder (a BUY, or the un-sold tail of one, with no sell yet).
SELECT
  CONCAT(strategy, ':', ticker, ':', buy_trade_id, ':OPEN') AS position_key,
  strategy, ticker, contract_id,
  open_shares AS shares,
  DATE(buy_fill_ts, 'America/New_York') AS entry_date,
  buy_price AS entry_price,
  open_shares * SAFE_DIVIDE(buy_commission, NULLIF(buy_shares, 0)) AS entry_commission,
  CAST(NULL AS DATE) AS exit_date,
  CAST(NULL AS NUMERIC) AS exit_price,
  CAST(NULL AS NUMERIC) AS exit_commission,
  CAST(NULL AS NUMERIC) AS realized_pnl
FROM open_tail;
-- SINGLE-ENTRY REGRESSION (a (strategy,ticker) with exactly 1 BUY + 1 SELL, fully matched): both
-- fills' cum_start = 0 (empty preceding-window COALESCEs to 0), so shares_matched =
-- LEAST(0+buy_shares, 0+sell_shares) - GREATEST(0,0) = MIN(buy_shares, sell_shares) = the full fill
-- size (a real single-entry position always has buy_shares == sell_shares). `matched` therefore
-- yields exactly ONE row, buy_matched_totals.total_matched == buy_shares for that buy, so open_tail's
-- WHERE excludes it (0 is not > epsilon) -- exactly ONE lot total, byte-identical on EVERY substantive
-- column to today's leg-pairing output: shares/entry_date/entry_price/exit_date/exit_price pass
-- through unchanged, and entry_commission/exit_commission/realized_pnl's `x * SAFE_DIVIDE(matched,
-- matched)` is `x * 1.000000000` -- NUMERIC division of a value by itself is exact (no rounding
-- artifact), so the product reproduces x exactly. VERIFIED LIVE 2026-07-21: this exact SQL, run
-- read-only (no object created) and EXCEPT-DISTINCT-compared against the CURRENT live analytics.
-- position_lifecycle view for the 6 real (strategy,ticker) pairs with exactly 1 BUY + 1 SELL today
-- (B:AZO, B:BRC, B:BURL, B:META, B:TJX, B:ZBRA), returned 0 rows different in both directions.
-- Only position_key's literal STRING changes shape (now keyed by buy_trade_id:sell_trade_id instead
-- of entry_date:leg_seq) -- the column's NAME and TYPE (STRING) are unchanged and it is still unique
-- per lot, which is its only load-bearing property downstream (strategy_daily_returns' LAG window
-- partitions on it).

-- ============================================================================
-- TIER 2 (NEW): analytics.position_campaigns -- CAMPAIGNS per (strategy,ticker): a running
-- signed-share position; a campaign spans the first BUY that takes it from flat (0) to non-flat
-- through every add/partial-exit fill until it returns to flat (closed) or the book's latest fill
-- (still open). Long-only-correct (see file header SCOPE note): a campaign is detected opening on a
-- 0->nonzero transition, which for this system's traded book is always a BUY. SGOV excluded verbatim.
--
-- SUPERSEDED LIVE by bigquery/116_decision_record_analyzability.sql — current single source of truth
-- for this object: now carries the opening fill's source_thesis_ref forward as opening_thesis_ref —
-- the FK thesis_outcomes needs, which this GROUP BY dropped entirely. Additive only; row count and
-- grouping unchanged. Kept here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT
-- re-apply this CREATE statement live in isolation.
--
-- SUPERSEDED AGAIN, LIVE, by bigquery/123_drip_dust_campaign_exclusion.sql (2026-08-02) — 116 above is
-- itself no longer canonical; 123 is the current single source of truth for this object (appends an
-- is_dust column flagging post-close DRIP-dust campaigns, e.g. B:IBM:2 / B:HCA:2, that can never
-- close). See bigquery/123, not 116. Kept here, unmodified, for DR-rebuild apply-in-order reference
-- only. DO NOT re-apply this CREATE statement live in isolation.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.position_campaigns` AS
WITH fills AS (
  SELECT trade_id, strategy, ticker, contract_id,
    DATE(fill_ts, 'America/New_York') AS fill_date, fill_ts,
    side, price, shares, commission, realized_pnl,
    IF(side = 'BUY', shares, -shares) AS signed_shares
  FROM `stock-trading-498512.state.trade_fills_curated`
  WHERE ticker != 'SGOV' AND shares IS NOT NULL AND shares > 0
),
running AS (
  SELECT *,
    SUM(signed_shares) OVER w AS running_shares,
    -- prev_running_shares = the running position BEFORE this fill; COALESCE to 0 for each
    -- (strategy,ticker)'s very first fill (empty preceding-window), same construct as Tier 1's
    -- cum_start.
    COALESCE(SUM(signed_shares) OVER (PARTITION BY strategy, ticker ORDER BY fill_ts, trade_id
      ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS prev_running_shares
  FROM fills
  WINDOW w AS (PARTITION BY strategy, ticker ORDER BY fill_ts, trade_id
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
),
seqd AS (
  SELECT *,
    -- campaign_seq increments exactly at a 0->nonzero transition (a NEW campaign's opening fill) and
    -- otherwise holds -- every fill from that opening fill through the fill that returns the position
    -- to 0 (inclusive) shares the same campaign_seq.
    COUNTIF(prev_running_shares = 0 AND running_shares != 0) OVER (
      PARTITION BY strategy, ticker ORDER BY fill_ts, trade_id
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS campaign_seq
  FROM running
),
tagged AS (
  SELECT *,
    -- The opening fill's contract_id/price, taken once per campaign via a window function ordered
    -- the same way campaign_seq was computed -- constant across every row of the campaign, so
    -- ANY_VALUE() after GROUP BY below is safe (not an arbitrary pick).
    FIRST_VALUE(contract_id) OVER (PARTITION BY strategy, ticker, campaign_seq ORDER BY fill_ts, trade_id) AS campaign_contract_id,
    FIRST_VALUE(price) OVER (PARTITION BY strategy, ticker, campaign_seq ORDER BY fill_ts, trade_id) AS campaign_entry_price,
    -- The ENDING running_shares of the campaign (0 if closed, nonzero if still open) -- the running
    -- position at the campaign's LAST fill by fill order.
    LAST_VALUE(running_shares) OVER (PARTITION BY strategy, ticker, campaign_seq ORDER BY fill_ts, trade_id
      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS campaign_open_shares,
    -- The price of the fill that brought running_shares back to 0 (the closing fill), if any --
    -- within one campaign_seq group this condition can be true for at most one row (the terminal
    -- fill; hitting 0 mid-campaign would itself start a NEW campaign_seq on the next nonzero fill).
    LAST_VALUE(IF(running_shares = 0, price, NULL) IGNORE NULLS) OVER (
      PARTITION BY strategy, ticker, campaign_seq ORDER BY fill_ts, trade_id
      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS campaign_exit_price
  FROM seqd
)
SELECT
  CONCAT(strategy, ':', ticker, ':', CAST(campaign_seq AS STRING)) AS campaign_key,
  strategy, ticker,
  ANY_VALUE(campaign_contract_id) AS contract_id,
  MIN(fill_date) AS entry_date,
  ANY_VALUE(campaign_entry_price) AS entry_price,
  MAX(IF(running_shares = 0, fill_date, NULL)) AS exit_date,
  ANY_VALUE(campaign_exit_price) AS exit_price,
  SUM(IF(side = 'SELL', realized_pnl, 0)) AS realized_pnl,
  SUM(IF(side = 'BUY', shares, 0)) AS total_shares_bought,
  SUM(IF(side = 'SELL', shares, 0)) AS total_shares_sold,
  ANY_VALUE(campaign_open_shares) AS open_shares,
  SUM(commission) AS total_commission,
  COUNTIF(side = 'BUY') AS n_buy_fills,
  COUNTIF(side = 'SELL') AS n_sell_fills
FROM tagged
GROUP BY strategy, ticker, campaign_seq;
-- SINGLE-ENTRY REGRESSION: 1 BUY (signed +N) then 1 SELL (signed -N, fully closing). Row 1 (BUY):
-- prev_running_shares=0, running_shares=N!=0 -> campaign_seq=1. Row 2 (SELL): running_shares=0,
-- prev_running_shares=N!=0 -> the 0->nonzero condition is false, so the cumulative COUNTIF stays at
-- 1 -- both fills land in the SAME campaign_seq=1 group -> ONE campaign row. entry_date/entry_price
-- come from the BUY (FIRST_VALUE by fill order); exit_date/exit_price come from the SELL (the row
-- where running_shares=0); realized_pnl sums the SELL's realized_pnl (the BUY contributes 0);
-- open_shares = LAST_VALUE(running_shares) over the full campaign = 0 (closed). Exactly the same
-- "one round-trip = one trade" shape the old engine produced for a single-entry position, generalized
-- correctly to the pyramid case.

-- ============================================================================
-- ops.sp_recompute_engine -- REBUILD. Byte-for-byte identical to the current canonical body
-- (bigquery/40_options_marks.sql:167-233, itself byte-for-byte identical to bigquery/03_twr_
-- engine.sql's original except for the option_mark_anomalies warning block) with ONE change: the
-- closed_trades / gate_n subqueries now COUNT off analytics.position_campaigns instead of analytics.
-- position_lifecycle, so a partial-exit pyramid counts as ONE closed trade (campaign-level), not one
-- per matched lot. Nothing else in this procedure changed -- keep bigquery/03/40/102's comments in
-- sync if any of the three is ever edited again (per bigquery/40's own note).
--
-- SUPERSEDED LIVE by bigquery/124_dust_excluded_from_closed_trades.sql (2026-08-02 -- closed_trades /
-- gate_n now also filter out post-close DRIP-dust campaigns via AND NOT l.is_dust). 124 is the CURRENT
-- single source of truth for this object. Kept here, unmodified, for DR-rebuild apply-in-order
-- reference only. DO NOT re-apply this CREATE statement live in isolation.
-- ============================================================================
CREATE OR REPLACE PROCEDURE `stock-trading-498512.ops.sp_recompute_engine`()
BEGIN
  DECLARE bad_mark_count INT64;
  DECLARE option_anomaly_count INT64;

  SET option_anomaly_count = (SELECT COUNT(*) FROM `stock-trading-498512.state.option_mark_anomalies`);
  IF option_anomaly_count > 0 THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'warning', 'ops.sp_recompute_engine', 'option_mark_missing',
      'One or more held option-format positions are missing a same-day option mark -- those strategy-days are excluded from the TWR chain (not zero-valued), not a silent corruption, but the underlying mark gap needs D2a follow-up.',
      TO_JSON_STRING(STRUCT(option_anomaly_count AS anomaly_count, CURRENT_TIMESTAMP() AS detected_ts)));
  END IF;

  SET bad_mark_count = (
    SELECT COUNT(*)
    FROM `stock-trading-498512.analytics.strategy_daily_returns` sdr
    LEFT JOIN `stock-trading-498512.analytics.sgov_daily_return` sg USING (as_of_date)
    WHERE sdr.r_deployed <= -0.9999 OR sg.r_sgov <= -0.9999
  );
  IF bad_mark_count > 0 THEN
    CALL `stock-trading-498512.ops.sp_raise_alert_once`(
      'critical', 'ops.sp_recompute_engine', 'twr_bad_mark',
      'A strategy-day had r_deployed or r_sgov <= -99.99% -- clamped to avoid NULL-corrupting the TWR chain; underlying mark likely bad, needs correction.',
      TO_JSON_STRING(STRUCT(bad_mark_count AS bad_mark_count, CURRENT_TIMESTAMP() AS detected_ts)));
  END IF;

  BEGIN TRANSACTION;

  DELETE FROM `stock-trading-498512.perf.strategy_daily` WHERE TRUE;
  INSERT INTO `stock-trading-498512.perf.strategy_daily`
  (as_of_date, strategy, deployed_unit_value, peak_unit_value, current_drawdown, sgov_index, excess_vs_sgov, deployed_days, closed_trades, gate_n, method, note)
  WITH r AS (
    SELECT sdr.as_of_date, sdr.strategy,
      GREATEST(sdr.r_deployed, -0.9999) AS r_deployed,
      GREATEST(COALESCE(
        sg.r_sgov,
        LAST_VALUE(sg.r_sgov IGNORE NULLS) OVER (
          PARTITION BY sdr.strategy ORDER BY sdr.as_of_date
          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW),
        0), -0.9999) AS r_sgov
    FROM `stock-trading-498512.analytics.strategy_daily_returns` sdr
    LEFT JOIN `stock-trading-498512.analytics.sgov_daily_return` sg USING (as_of_date)
  ),
  chained AS (
    SELECT as_of_date, strategy,
      EXP(SUM(LN(1+r_deployed)) OVER w) AS duv,
      EXP(SUM(LN(1+r_sgov)) OVER w) AS sgovidx,
      ROW_NUMBER() OVER w AS dday
    FROM r WINDOW w AS (PARTITION BY strategy ORDER BY as_of_date)
  ),
  peaked AS (
    SELECT *, GREATEST(1.0, MAX(duv) OVER (PARTITION BY strategy ORDER BY as_of_date)) AS peak
    FROM chained
  )
  SELECT p.as_of_date, p.strategy,
    CAST(p.duv AS NUMERIC), CAST(p.peak AS NUMERIC), CAST(p.duv/p.peak-1 AS NUMERIC),
    CAST(p.sgovidx AS NUMERIC), CAST(p.duv/p.sgovidx-1 AS NUMERIC), p.dday,
    -- Repointed to analytics.position_campaigns (Tier 2): campaign-level closed count, so a
    -- partial-exit pyramid counts as ONE closed trade, not one per FIFO lot.
    (SELECT COUNT(*) FROM `stock-trading-498512.analytics.position_campaigns` l
       WHERE l.strategy=p.strategy AND l.exit_date IS NOT NULL AND l.exit_date<=p.as_of_date),
    GREATEST(0, 30 - (SELECT COUNT(*) FROM `stock-trading-498512.analytics.position_campaigns` l
       WHERE l.strategy=p.strategy AND l.exit_date IS NOT NULL AND l.exit_date<=p.as_of_date)),
    'value-weighted-daily-TWR-gross-v3',
    'PROFITABILITY metric: GROSS of commissions (scale artifact at ~$30 positions), total return, SGOV actual total-return benchmark. Cash/NAV accounting tracks commissions exactly + separately.'
  FROM peaked p;

  COMMIT TRANSACTION;
END;

-- ============================================================================
-- analytics.thesis_outcomes -- REBUILD. Identical to the current canonical body (bigquery/04_
-- analytics.sql:88-125) except the LEFT JOIN target + the QUALIFY nearest-entry_date window move
-- from analytics.position_lifecycle to analytics.position_campaigns -- a pyramid add's own
-- thesis-construction entry legitimately maps to the SAME campaign as the position's original entry
-- (both are the same round-trip at the campaign level), not a separate per-lot row. All other columns
-- and semantics (regime-as-of join, was_profitable NULL-until-closed) are unchanged.
--
-- SUPERSEDED LIVE by bigquery/116_decision_record_analyzability.sql — current single source of truth
-- for this object: entry_type now tolerates the 'thesis' synonym (a 2026-07-20..22 logging drift
-- silently hid 14 real rows from every calibration view); the position-campaign join is now guarded
-- to GO-family decisions so a NO-GO can never inherit a position outcome; pairing prefers a real FK
-- (position_campaigns.opening_thesis_ref) over nearest-date; conviction_pct + normalized added. Kept
-- here, unmodified, for DR-rebuild apply-in-order reference only. DO NOT re-apply this CREATE
-- statement live in isolation.
--
-- SUPERSEDED AGAIN, LIVE, by bigquery/123_drip_dust_campaign_exclusion.sql (2026-08-02) — 116 above is
-- itself no longer canonical; 123 is the current single source of truth for this object (the campaign
-- join now also excludes post-close DRIP-dust campaigns via `AND NOT pc.is_dust`, so a GO thesis can
-- never mis-pair to a sub-dollar phantom campaign). See bigquery/123, not 116. Kept here, unmodified,
-- for DR-rebuild apply-in-order reference only. DO NOT re-apply this CREATE statement live in
-- isolation.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.thesis_outcomes` AS
WITH theses AS (
  SELECT entry_id, entry_date, strategy, ticker, conviction, sub_pattern, decision, title
  FROM `stock-trading-498512.events.decision_log`
  WHERE entry_type = 'thesis-construction'
),
regime_axis AS (
  SELECT value AS regime_state, as_of_date
  FROM `stock-trading-498512.events.regime_events`
  WHERE scope='FUNDAMENTAL_AXIS' AND key='_integrative'
),
thesis_regime AS (
  SELECT t.entry_id, ra.regime_state
  FROM theses t
  LEFT JOIN regime_axis ra ON ra.as_of_date <= t.entry_date
  QUALIFY ROW_NUMBER() OVER (PARTITION BY t.entry_id ORDER BY ra.as_of_date DESC) = 1
)
SELECT
  t.entry_id, t.entry_date, t.strategy, t.ticker, t.decision, t.conviction, t.sub_pattern,
  tr.regime_state,
  pc.exit_date IS NOT NULL AS position_closed,
  IF(pc.exit_date IS NOT NULL, pc.realized_pnl, NULL) AS realized_pnl,
  CASE WHEN pc.exit_date IS NULL THEN NULL          -- position still open -> outcome unknown (not a loss)
       WHEN pc.realized_pnl IS NULL THEN NULL
       ELSE pc.realized_pnl > 0 END AS was_profitable,
  t.title
FROM theses t
LEFT JOIN thesis_regime tr ON tr.entry_id = t.entry_id
LEFT JOIN `stock-trading-498512.analytics.position_campaigns` pc
  ON pc.strategy = t.strategy AND pc.ticker = t.ticker
-- Pair each thesis to ITS campaign: a re-traded ticker has >1 campaign, so pick the one whose
-- entry_date is nearest the thesis date and take realized_pnl from THAT campaign (an add's own
-- thesis-construction entry legitimately maps to the same campaign as the position's original entry
-- -- the old ticker-wide SUM over all fills conflated round-trips; per-lot conflated an add with its
-- own thesis row instead of the campaign's).
QUALIFY ROW_NUMBER() OVER (
  PARTITION BY t.entry_id
  ORDER BY ABS(DATE_DIFF(pc.entry_date, t.entry_date, DAY)) NULLS LAST
) = 1;

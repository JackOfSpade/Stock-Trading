-- bigquery/152_park_residual_sign_fix.sql (2026-08-08)
-- Project: stock-trading-498512. Apply after bigquery/93_park_accounting.sql (which itself supersedes
-- bigquery/22_cash_flows.sql, which supersedes bigquery/04_analytics.sql, for this same object).
--
-- SUPERSEDES analytics.account_reconciliation from bigquery/93_park_accounting.sql (see the SUPERSEDED
-- marker left there pointing here, same commit). This is the current single source of truth for this
-- view. Keep 93 for DR-rebuild history; do not re-apply its definition of this object in isolation.
-- bigquery/93's other two views (analytics.park_nav_daily, analytics.park_counterfactuals) are
-- UNTOUCHED and remain canonical there -- this file redefines account_reconciliation only.
--
-- ============================ THE BUG (confirmed live, 2026-08-08) ================================
-- residual_after_park SUBTRACTS park_unrealized when the identity bigquery/93 itself derives requires
-- it to be ADDED. bigquery/93's own DEVIATION #2 note (top of that file) states the identity in prose
-- almost verbatim -- "raw residual == -park_unrealized" -- and that note is CORRECT. The arithmetic a
-- few dozen lines below it does not implement what the prose says.
--
-- THE DERIVATION.
--   * undeployed_total = SUM(analytics.strategy_nav.available_funds) is a CASH/COST-basis residual.
--     Per bigquery/127_strategy_nav_dust_exclusion.sql's canonical strategy_nav definition:
--       available_funds = deposits + realized_pnl + (open_mv - open_cost) + dividends - open_mv
--                        = deposits + realized_pnl + dividends - open_cost
--     open_mv cancels out algebraically -- available_funds NEVER reads a current market price for
--     anything, park included. It is a pure cost-basis figure, with no separate "park" line item of
--     its own (the park's cost sits inside `deposits`/flows like any other undeployed cash).
--   * raw = undeployed_total - park_mv - cash, where park_mv (park_now.park_mv_now below) is the
--     park's CURRENT MARKET value. So `raw` nets a COST-basis total against a MARKET-basis park
--     holding: it starts from a figure that implicitly still carries the park at cost, then subtracts
--     the park out at MARKET. The mismatch this manufactures is exactly the park's own unrealized
--     P&L, with a sign flip: raw ~= -park_unrealized (park_mv - park_cost_basis), modulo the account's
--     normal few-dollar reconciliation noise (rounding, in-flight settlement, timing).
--   * Therefore the portion of `raw` that the park's own MTM EXPLAINS is exactly -park_unrealized, and
--     the unexplained remainder -- what residual_after_park is supposed to report -- is
--         raw - (-park_unrealized) = raw + park_unrealized.
--   * bigquery/93's formula instead computes raw - park_unrealized. Given raw ~= -park_unrealized
--     already, that reduces to approximately -2*park_unrealized: it DOUBLES the park term (nets it in
--     the wrong direction) instead of cancelling it, and can NEVER converge to ~0 while the park
--     carries any nonzero unrealized P&L, no matter how clean the rest of the account's books are.
--
-- LIVE PROOF (read-only, re-verified 2026-08-08 while writing this file):
--     undeployed_total = 18779.23   (SUM(analytics.strategy_nav.available_funds))
--     park_mv           = 18929.55   (park_now.park_mv_now: current park shares * latest close)
--     cash              = -0.22      (state.account_latest.total_cash)
--     park_unrealized   = 95.45      (park_mv - park_cost_basis; matches IBKR's own VOO
--                                      unrealized_pnl of 95.4457 to the cent)
--     raw = undeployed_total - park_mv - cash = 18779.23 - 18929.55 - (-0.22) = -150.10
--           (confirms raw ~= -park_unrealized: -150.10 vs -95.45 -- the ~$55 gap between them is
--            ordinary reconciliation noise, not this bug, and is exactly what residual_after_park is
--            SUPPOSED to surface once the park's own MTM is correctly netted out)
--     CURRENT (buggy):       raw - park_unrealized = -150.10 - 95.45 = -245.54
--     CORRECTED (this file): raw + park_unrealized = -150.10 + 95.45 = -54.65
-- -245.54 is what analytics.account_reconciliation reports live today; -54.65 is what it should
-- report. The corrected figure is SMALLER in magnitude, not larger -- exactly the direction
-- bigquery/93's own DEVIATION #2 was hoping to see and did not, because of this sign error, not
-- because of a framing problem in PARK_ROUTER_DESIGN.md.
--
-- WHY THIS WAS MISDIAGNOSED. bigquery/93's DEVIATION #2 note found that the design doc's "the gap IS
-- park unrealized P&L" framing did not hold precisely against live numbers, and recorded that as an
-- accepted, documented non-convergence -- "the design doc's framing does not hold" -- rather than as a
-- bug in this view. It was a bug: the raw == -park_unrealized identity that same note states IS the
-- framing holding (up to ordinary reconciliation noise); the SUBTRACTION a few lines later just
-- implements the wrong sign against it. This file corrects the arithmetic; it does not relitigate or
-- revise the framing discussion in DEVIATION #2, which was fine on its own terms.
--
-- THE FIX. Exactly one sign flipped, in exactly one place: residual_after_park's outer arithmetic
-- changes from `raw - (park_mv - park_cost_basis)` to `raw + (park_mv - park_cost_basis)` -- i.e. the
-- trailing `-` immediately before the second parenthesized term becomes `+` (equivalently,
-- `... ) + park_unrealized`). Nothing else in the view -- no other CTE, no other column, no
-- formatting -- changed; the body below is byte-for-byte bigquery/93's current definition of this view
-- with that one operator swapped, plus this one column's own inline comment reworded so it no longer
-- repeats the misdiagnosis (bigquery/93's DEVIATION #2 remains, unmodified, as the historical record of
-- how this was first found and mis-explained).
--
-- IMPACT, EXPECTED. Every other column (total_deposits, strategy_realized_pnl, events_side_nav_total,
-- deployed_total, undeployed_total, park_unrealized) is unchanged -- none of them touch this
-- arithmetic. Only residual_after_park moves, from -245.54 to -54.65 as of 2026-08-08. It will still
-- not read exactly 0 (the remaining ~$55 is genuine reconciliation noise -- rounding/timing/settlement
-- drift, the same character of gap the original recon in recon_parking.md characterized before
-- PARK_ROUTER_DESIGN.md's design doc re-characterized it) -- but it is now the CORRECT unexplained
-- residual instead of one that structurally could never approach zero.

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
  -- events.parking_events + marks, per the approved spec). See DEVIATION #2 at the top of
  -- bigquery/93_park_accounting.sql: live-verified 2026-07-18 at approximately -96.33 (VOO's price had
  -- drifted slightly below its 2026-07-15 acquisition cost); live-verified again 2026-08-08 at +95.45
  -- (VOO's price has since risen above cost) while writing bigquery/152_park_residual_sign_fix.sql.
  -- This column's own expression and comment are UNCHANGED from bigquery/93 -- only residual_after_park
  -- below is fixed by that file.
  ROUND(COALESCE(pn.park_mv_now, 0) - COALESCE(pn.park_cost_basis, 0), 2)                         AS park_unrealized,
  -- residual_after_park = the events-vs-live residual (undeployed_total - park MV - cash), ADJUSTED to
  -- remove the portion explained by the park's own mark-to-market move. undeployed_total
  -- (analytics.strategy_nav.available_funds) is a COST-basis figure -- it never reads a current
  -- price -- while park_mv above is MARKET-basis, so raw == -park_unrealized (modulo ordinary
  -- reconciliation noise: rounding, in-flight settlement, timing). The park's own MTM is therefore
  -- CANCELLED by ADDING park_unrealized back, not by subtracting it a second time. See
  -- bigquery/152_park_residual_sign_fix.sql's header for the full derivation and live worked proof.
  -- SIGN FIX (bigquery/152, 2026-08-08): bigquery/93_park_accounting.sql's original formula here
  -- SUBTRACTED park_unrealized, which doubles the park term instead of cancelling it and can never
  -- converge to ~0 while the park holds any unrealized P&L -- live-verified same-day numbers: -245.54
  -- (old, buggy) vs -54.65 (corrected). bigquery/93's own DEVIATION #2 recorded that exact
  -- non-convergence and misdiagnosed it as a framing problem with PARK_ROUTER_DESIGN.md rather than as
  -- this sign error; DEVIATION #2 is left unmodified there as the historical record.
  ROUND(
    (
      (SELECT SUM(available_funds) FROM `stock-trading-498512.analytics.strategy_nav`)
      - COALESCE(pn.park_mv_now, 0)
      - COALESCE((SELECT total_cash FROM `stock-trading-498512.state.account_latest`), 0)
    ) + (COALESCE(pn.park_mv_now, 0) - COALESCE(pn.park_cost_basis, 0))
  , 2)                                                                                             AS residual_after_park
FROM park_now pn;

-- VERIFICATION (run after apply; read-only).
-- NOTE: double-dash line comments only. A trailing C-style block comment placed after this file's last
-- CREATE causes permanent live-sql-parity drift -- never introduce one here.
--
-- 1. Every column except residual_after_park is byte-for-byte unchanged from the pre-apply baseline:
--    SELECT * FROM `stock-trading-498512.analytics.account_reconciliation`;
--    -> total_deposits / strategy_realized_pnl / events_side_nav_total / deployed_total /
--    undeployed_total / park_unrealized must all match the pre-apply values exactly.
--
-- 2. residual_after_park now equals raw + park_unrealized, not raw - park_unrealized:
--    SELECT
--      park_unrealized,
--      residual_after_park,
--      residual_after_park - park_unrealized AS implied_raw,                 -- should be ~ -150.10
--      residual_after_park + 2 * park_unrealized AS old_buggy_value_would_be -- the discarded figure
--    FROM `stock-trading-498512.analytics.account_reconciliation`;
--    -> as of 2026-08-08: park_unrealized ~= 95.45, residual_after_park ~= -54.65 (was -245.54
--    pre-fix), implied_raw ~= -150.10, old_buggy_value_would_be ~= -245.54.
--
-- 3. The identity this fix relies on (raw ~= -park_unrealized) still holds within normal noise --
--    query #2 above already proves this directly (implied_raw vs -park_unrealized, both derivable from
--    that one result row): they should sit within a few dollars of each other, never off by roughly
--    2x park_unrealized, which would be the signature of the old (pre-152) bug reappearing.

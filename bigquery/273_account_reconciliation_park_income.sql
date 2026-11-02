-- Explain the standing residual_after_park figure instead of leaving it unattributed.
-- Project: stock-trading-498512. SUPERSEDES analytics.account_reconciliation from
-- bigquery/156_park_residual_sign_fix.sql. Idempotent (CREATE OR REPLACE VIEW). Apply after 156.
--
-- WHY (2026-11-02, interactive owner session, closing ops.alerts 574fed62, D2a's
-- park_realized_pnl_absent_from_strategy_nav). That notice blamed park realized P&L. It is wrong: realized
-- P&L sits in both available_funds' park cost basis and the live cash, and cancels out of the residual.
-- Measured live 2026-11-02: residual_after_park -112.60 = +29.34 (SGOV net outflow the dust guard drops)
-- - 144.03 (park dividend income no ledger records) + 2.09 of noise.
--
-- WHAT CHANGED. Three diagnostic columns are appended. Every existing column, residual_after_park
-- included, is byte-identical, and analytics.strategy_nav is untouched, so no sizing or sweep amount moves.
-- A strategy_nav term was rejected: it would change available_funds, withdrawal capacity and fee clamps
-- for income that belongs to no strategy. Nothing gates on the new columns.

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
),
-- park_exited: net cash of park tickers fully exited, which park_now's dust guard drops from
-- park_cost_basis even though that outflow really left the account.
park_exited AS (
  SELECT COALESCE(SUM(-net_cash), 0) AS exited_net_outflow
  FROM park_positions
  WHERE ABS(shares) <= 0.0005
),
park_signed AS (
  SELECT ticker, action_date,
    CASE action
      WHEN 'BUY' THEN shares
      WHEN 'DIVIDEND_REINVEST' THEN shares
      WHEN 'RECON_ADJUST' THEN shares
      WHEN 'SELL' THEN -shares
      ELSE 0 END AS sh
  FROM `stock-trading-498512.events.parking_events`
  WHERE ticker IS NOT NULL
),
park_div_marks AS (
  SELECT ticker, mark_date, MAX(dividend) AS dividend
  FROM (
    SELECT ticker, mark_date, dividend FROM `stock-trading-498512.state.daily_marks_curated` WHERE dividend > 0
    UNION ALL
    SELECT ticker, mark_date, dividend FROM `stock-trading-498512.state.signal_marks_curated` WHERE dividend > 0
  )
  GROUP BY ticker, mark_date
),
-- park_income: per-share dividend on each ex-date x park shares held before it. An ESTIMATE from marks,
-- because no ledger records park dividends; ex-date to pay-date lag makes it briefly lead the cash.
park_income AS (
  SELECT COALESCE(SUM(dm.dividend * GREATEST(COALESCE(
      (SELECT SUM(ps.sh) FROM park_signed ps
       WHERE ps.ticker = dm.ticker AND ps.action_date < dm.mark_date), 0), 0)), 0) AS income_est
  FROM park_div_marks dm
  WHERE dm.ticker IN (SELECT ticker FROM park_signed)
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
  -- (VOO's price has since risen above cost) while writing bigquery/156_park_residual_sign_fix.sql.
  -- This column's own expression and comment are UNCHANGED from bigquery/93 -- only residual_after_park
  -- below is fixed by that file.
  ROUND(COALESCE(pn.park_mv_now, 0) - COALESCE(pn.park_cost_basis, 0), 2)                         AS park_unrealized,
  -- residual_after_park = the events-vs-live residual (undeployed_total - park MV - cash), ADJUSTED to
  -- remove the portion explained by the park's own mark-to-market move. undeployed_total
  -- (analytics.strategy_nav.available_funds) is a COST-basis figure -- it never reads a current
  -- price -- while park_mv above is MARKET-basis, so raw == -park_unrealized (modulo ordinary
  -- reconciliation noise: rounding, in-flight settlement, timing). The park's own MTM is therefore
  -- CANCELLED by ADDING park_unrealized back, not by subtracting it a second time. See
  -- bigquery/156_park_residual_sign_fix.sql's header for the full derivation and live worked proof.
  -- SIGN FIX (bigquery/156, 2026-08-08): bigquery/93_park_accounting.sql's original formula here
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
  , 2)                                                                                             AS residual_after_park,
  ROUND(pe.exited_net_outflow, 2)                                                                  AS park_exited_net_outflow,
  ROUND(pi.income_est, 2)                                                                          AS park_income_est,
  ROUND(
    (
      (SELECT SUM(available_funds) FROM `stock-trading-498512.analytics.strategy_nav`)
      - COALESCE(pn.park_mv_now, 0)
      - COALESCE((SELECT total_cash FROM `stock-trading-498512.state.account_latest`), 0)
    ) + (COALESCE(pn.park_mv_now, 0) - COALESCE(pn.park_cost_basis, 0))
    - pe.exited_net_outflow + pi.income_est
  , 2)                                                                                             AS residual_unexplained
FROM park_now pn
CROSS JOIN park_exited pe
CROSS JOIN park_income pi;

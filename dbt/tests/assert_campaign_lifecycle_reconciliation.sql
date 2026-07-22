-- Singular test (passes when ZERO rows): for every CLOSED campaign (analytics.position_campaigns,
-- exit_date IS NOT NULL), its constituent analytics.position_lifecycle lots must reconcile:
--   (1) NO lot entered inside the campaign's [entry_date, exit_date] window is still open
--       (exit_date IS NULL) -- and at least one lot must exist at all (a total dropout would
--       otherwise vanish silently under an inner join, not fail).
--   (2) the CLOSED lots' shares sum to the campaign's total_shares_sold.
--   (3) the CLOSED lots' realized_pnl sums to the campaign's realized_pnl (within a cent).
--
-- WHY THIS CATCHES THE REGRESSION THIS SYSTEM ALREADY SHIPPED ONCE (bigquery/102_pyramid_aware_
-- lifecycle.sql header): the superseded ROW_NUMBER() leg_seq pairing (bigquery/03_twr_engine.sql)
-- paired the Nth BUY to the Nth SELL. A pyramid (2+ BUYs before the matching SELL(s)) then left the
-- add-leg's BUY permanently unpaired -- LEFT JOIN NULL on exit_date forever -- even after a later
-- combined SELL had fully flattened the position. Tier 2 (position_campaigns) detects "flat"
-- independently of Tier 1's lot pairing, purely from the running signed-share sum crossing back to
-- 0, so it cannot share Tier 1's bug. That makes "does Tier 2 say CLOSED while Tier 1 still shows an
-- OPEN lot in that window" an oracle that does not depend on trusting Tier 1's own pairing logic --
-- exactly the phantom-open-leg failure mode, caught by clause (1). Clauses (2)/(3) catch a subtler
-- drift: Tier 1 producing the right COUNT of open vs closed lots but the wrong share/P&L split
-- between them (e.g. a FIFO-ordering or proration bug) -- a bug clause (1) alone would miss.
--
-- FIFO/campaign-window correctness note (not a heuristic): Tier 1 (FIFO by fill-time) and Tier 2
-- (campaign boundary = running signed-share sum returns to 0) are both built off the SAME
-- chronological fill order for the SAME (strategy,ticker). A campaign only closes once its running
-- position returns to flat, so every BUY dated inside that campaign's window is, by construction,
-- fully consumed (FIFO) by a SELL inside that same window -- no BUY from an earlier or later
-- campaign can be matched into this one. Scoping lots to a campaign via
-- `entry_date BETWEEN campaign.entry_date AND campaign.exit_date` is therefore a correct partition
-- of the lots, not an approximation.
--
-- PASSES TRIVIALLY TODAY: every closed (strategy,ticker) pair currently live is a single-entry
-- position (1 BUY, 1 SELL) -- both models' own "SINGLE-ENTRY REGRESSION" comments in
-- bigquery/102_pyramid_aware_lifecycle.sql establish Tier 1 yields exactly one closed lot and Tier 2
-- exactly one campaign, 1-for-1, for that case, so no clause fires until a real pyramid or
-- partial-exit closes for the first time -- exactly the case "allow adds" (the owner directive this
-- ships under) is about to make routine.
--
-- 0.01 epsilon matches the existing dbt mirror's tolerance (assert_current_positions_match_
-- lifecycle.sql's 0.01-share tolerance) -- generous relative to the ~1e-7-scale proration noise
-- NUMERIC's fixed 9-decimal-digit division introduces (bigquery/102's header), tight relative to any
-- real dropped share or dollar.

WITH closed_campaigns AS (
  SELECT campaign_key, strategy, ticker, entry_date, exit_date, realized_pnl, total_shares_sold
  FROM {{ ref('position_campaigns') }}
  WHERE exit_date IS NOT NULL
),
campaign_lots AS (
  SELECT c.campaign_key, c.exit_date AS campaign_exit_date,
    c.realized_pnl AS campaign_realized_pnl, c.total_shares_sold AS campaign_total_shares_sold,
    l.position_key, l.exit_date AS lot_exit_date, l.shares AS lot_shares, l.realized_pnl AS lot_realized_pnl
  FROM closed_campaigns c
  LEFT JOIN {{ ref('position_lifecycle') }} l
    ON l.strategy = c.strategy AND l.ticker = c.ticker
    AND l.entry_date BETWEEN c.entry_date AND c.exit_date
),
agg AS (
  SELECT campaign_key, campaign_total_shares_sold, campaign_realized_pnl,
    COUNT(position_key) AS n_lots,
    COUNTIF(lot_exit_date IS NULL) AS n_open_lots,
    SUM(IF(lot_exit_date IS NOT NULL, lot_shares, 0)) AS closed_shares_total,
    SUM(IF(lot_exit_date IS NOT NULL, lot_realized_pnl, 0)) AS closed_pnl_total
  FROM campaign_lots
  GROUP BY campaign_key, campaign_total_shares_sold, campaign_realized_pnl
)
SELECT campaign_key, n_lots, n_open_lots,
       closed_shares_total, campaign_total_shares_sold,
       closed_pnl_total, campaign_realized_pnl
FROM agg
WHERE n_lots = 0
   OR n_open_lots > 0
   OR ABS(closed_shares_total - campaign_total_shares_sold) > 0.01
   OR ABS(closed_pnl_total - campaign_realized_pnl) > 0.01

-- BigQuery SGOV reconciliation — event-sourced, account-level (fixes B1). Project: stock-trading-498512.
-- Closes the last hand-kept ledger dependency the stack review found: bigquery/04_analytics.sql noted
-- "the EXACT per-strategy SGOV-share allocation ... is NOT yet reconciled ... the §13 tripwire still
-- reads Portfolio_Ledger.md, so Portfolio_Ledger is KEPT." But (a) Portfolio_Ledger.md was retired in
-- the 2026-06-06 cutover and is no longer in the repo, and (b) events.parking_events.strategy is NULL
-- on every row — SGOV is a SHARED, account-level park with no per-strategy tag, so a per-strategy
-- SGOV-share ledger cannot be (and should not be) reconstructed.
--
-- RESOLUTION (matches the v2 redesign's "reframe §13 to account level"):
--   * The TOTAL SGOV share count + cash flow ARE event-sourceable from events.parking_events with no
--     hand ledger — this view does that. D2 Step 0 compares it to the connector (get_account_positions
--     SGOV shares, contract_id 424099317; get_account_balances cash) and flags residual > ~$1 (§13.A).
--   * The per-strategy SGOV-share split is FORMALLY DISSOLVED. Per-strategy BUDGET stays NAV-derived
--     (analytics.strategy_nav.available_funds / sizing_base_2pct), which never needed an SGOV-share ledger.
--
-- Depends on 01_schema.sql (events.parking_events) + 03_twr_engine.sql (state.daily_marks_curated).
-- Idempotent (OR REPLACE). Apply via the BigQuery MCP execute_sql.

-- ===== state.sgov_position — event-sourced SGOV holding (shares + cash flow), account-level =====
-- Signed rollup of every parking event:
--   BUY               -> +shares, account cash -(gross + commission)
--   SELL              -> -shares, account cash +(gross - commission)
--   DIVIDEND_REINVEST -> +shares, account cash  0  (dividend received and immediately reinvested via
--                        IBKR DRIP; income, not a trade-funded buy — see 03_twr_engine.sql §SGOV note)
--   RECON_ADJUST      -> +shares (SIGNED; row carries the +/- delta), account cash 0. A §13.D
--                        reconciliation correction that aligns the events side to the AUTHORITATIVE
--                        connector holding when they drift (the connector is always truth). No cash
--                        impact (gross/commission 0). First used 2026-06-19 to remove a +0.4722 sh
--                        pre-connector screenshot-era capture drift (events 92.7714 -> connector 92.2992).
CREATE OR REPLACE VIEW `stock-trading-498512.state.sgov_position` AS
SELECT
  SUM(CASE action WHEN 'BUY' THEN shares
                  WHEN 'DIVIDEND_REINVEST' THEN shares
                  WHEN 'RECON_ADJUST' THEN shares  -- signed delta (+/-)
                  WHEN 'SELL' THEN -shares
                  ELSE 0 END)                                              AS events_sgov_shares,
  SUM(IF(action = 'BUY',  shares, 0))                                      AS buy_shares,
  SUM(IF(action = 'SELL', shares, 0))                                      AS sell_shares,
  SUM(IF(action = 'DIVIDEND_REINVEST', shares, 0))                         AS drip_shares,
  -- Net cash the park has consumed (BUY) minus returned (SELL); DRIP is cash-neutral. Negative = net
  -- cash deployed into SGOV. Commissions are included exactly (tracked to the cent per §13/§14).
  ROUND(SUM(CASE action
              WHEN 'BUY'  THEN -(gross + COALESCE(commission, 0))
              WHEN 'SELL' THEN  (gross - COALESCE(commission, 0))
              ELSE 0 END), 4)                                             AS events_park_net_cash,
  ROUND(SUM(COALESCE(commission, 0)), 4)                                  AS parking_commissions_total,
  COUNT(*)                                                                 AS parking_event_count,
  MAX(action_date)                                                         AS last_parking_date
FROM `stock-trading-498512.events.parking_events`;

-- ===== state.sgov_reconciliation — the account-level comparison contract for D2 Step 0 (§13.A) =====
-- events_sgov_shares + the latest SGOV close give the events-side expected SGOV market value. D2 compares
-- events_sgov_shares to the connector's live SGOV share count and events_sgov_market_value (+ account
-- cash, expected ~$0) to the connector NLV; an UNEXPLAINED residual > ~$1 trips the §13.A hard stop.
-- Per-strategy attribution is intentionally absent (dissolved — see header); use analytics.strategy_nav
-- for per-strategy budget and analytics.account_reconciliation for the total NAV identity.
CREATE OR REPLACE VIEW `stock-trading-498512.state.sgov_reconciliation` AS
WITH p AS (SELECT * FROM `stock-trading-498512.state.sgov_position`),
mark AS (
  SELECT close AS sgov_close, mark_date AS sgov_mark_date
  FROM `stock-trading-498512.state.daily_marks_curated`
  WHERE ticker = 'SGOV'
  QUALIFY ROW_NUMBER() OVER (ORDER BY mark_date DESC) = 1
)
SELECT
  p.events_sgov_shares,
  p.buy_shares, p.sell_shares, p.drip_shares,
  p.events_park_net_cash,
  p.parking_commissions_total,
  mark.sgov_close,
  mark.sgov_mark_date,
  ROUND(p.events_sgov_shares * mark.sgov_close, 2)                         AS events_sgov_market_value,
  -- Staleness guard (parallels state.freshness): TRUE only when SGOV is marked through the last trading
  -- day, so a stale mark can't quietly understate the events-side SGOV value the reconciliation rests on.
  COALESCE(mark.sgov_mark_date >= (SELECT last_trading_day FROM `stock-trading-498512.state.trading_day_today`),
           FALSE)                                                          AS sgov_mark_fresh,
  CURRENT_TIMESTAMP()                                                      AS checked_at
-- LEFT JOIN (not a comma cross-join): if SGOV ever has no daily_marks row, the share count from p must
-- still surface (sgov_close/market_value NULL, sgov_mark_fresh FALSE) rather than the whole view going
-- empty — this view feeds the §13 hard-stop, so it must never silently return zero rows.
FROM p LEFT JOIN mark ON TRUE;

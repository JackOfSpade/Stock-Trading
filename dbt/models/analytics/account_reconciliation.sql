-- Parallel-run dbt port of bigquery/93_park_accounting.sql:analytics.account_reconciliation
-- (SUPERSEDES bigquery/22_cash_flows.sql's definition) — canonical source is bigquery/93 until owner
-- cutover. §13 account-integrity, ACCOUNT-LEVEL: the events-side expected total, sourced from
-- events.cash_flows (self-improvement audit B-1-exec). D2 Step 0 compares it (+ the connector's live
-- SGOV mark) to the connector NLV / SGOV shares / cash and flags any residual > ~$1. Per-strategy
-- budget = analytics.strategy_nav (available_funds).
--
-- 2026-07-18 (PARK_ROUTER_DESIGN.md v2 §9, AI Park Allocator accounting): two columns added —
-- park_unrealized (current park MV across every ever-held menu ticker, minus cost basis derived from
-- events.parking_events' net cash) and residual_after_park (the existing events-vs-live residual
-- with park_unrealized netted out) — every prior output column is preserved byte-identical. See
-- bigquery/93's header DEVIATION #2: live-verified 2026-07-18, residual_after_park does NOT converge
-- to ~0 with then-current numbers — it remains a useful ongoing drift signal, not a "hits zero today"
-- check. state.signal_marks_curated (bigquery/91) is declared as a state_external source (dbt does
-- not yet own it — out of scope for this dbt-port pass, see sources.yml).

WITH park_marks AS (
  SELECT ticker, mark_date, close FROM {{ ref('daily_marks_curated') }}
  UNION ALL
  SELECT ticker, mark_date, close FROM {{ source('state_external', 'signal_marks_curated') }}
),
-- Latest available close per ticker (daily_marks_curated preferred via mark_date recency — see
-- bigquery/93's own note: a true same-day tie between the two sources for the SAME ticker/date is not
-- expected in practice since a ticker lives in exactly one source at a time).
park_latest_close AS (
  SELECT ticker, close
  FROM park_marks
  QUALIFY ROW_NUMBER() OVER (PARTITION BY ticker ORDER BY mark_date DESC) = 1
),
-- Full-history signed share count + net cash per ticker, same CASE as state.park_position
-- (bigquery/54), generalized across every ticker the park has EVER held (not just the current policy
-- vehicle) so a mid-convergence dual-holding (PARK_ROUTER_DESIGN.md §5) is captured correctly.
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
  FROM {{ source('events', 'parking_events') }}
  WHERE ticker IS NOT NULL
  GROUP BY ticker
),
-- Current park market value + cost basis, dust-guarded (ABS(shares) > 0.0005 -- aligned to the
-- >0.0005 dust floor used elsewhere in the park substrate, was 0.0001 here) so a fully-exited
-- historical vehicle (e.g. SGOV, post-2026-07-15 cutover) does not contribute. LEFT JOIN (was
-- INNER) + COALESCE(lc.close, 0): an above-dust ticker with no mark yet keeps its cost basis
-- (net_cash is independent of marks) and contributes $0 market value instead of silently vanishing
-- from park_unrealized -- mirrors bigquery/93_park_accounting.sql's park_reconciliation-style
-- LEFT-JOIN-safe pattern (canonical source; 2026-07-19 fix). Scalar aggregate (no GROUP BY) always
-- returns exactly one row.
park_now AS (
  SELECT
    SUM(pp.shares * COALESCE(lc.close, 0))   AS park_mv_now,
    SUM(-pp.net_cash)                         AS park_cost_basis
  FROM park_positions pp
  LEFT JOIN park_latest_close lc USING (ticker)
  WHERE ABS(pp.shares) > 0.0005
)
SELECT
  (SELECT ROUND(SUM(amount), 2) FROM {{ source('events', 'cash_flows') }})               AS total_deposits,
  (SELECT ROUND(SUM(realized_pnl), 2) FROM {{ ref('trade_fills_curated') }})              AS strategy_realized_pnl,
  (SELECT ROUND(SUM(nav), 2) FROM {{ ref('strategy_nav') }})                              AS events_side_nav_total,
  (SELECT ROUND(SUM(deployed_mv), 2) FROM {{ ref('strategy_nav') }})                      AS deployed_total,
  (SELECT ROUND(SUM(available_funds), 2) FROM {{ ref('strategy_nav') }})                  AS undeployed_total,
  -- park_unrealized = current park market value - park cost basis (both derived from
  -- events.parking_events + marks).
  ROUND(COALESCE(pn.park_mv_now, 0) - COALESCE(pn.park_cost_basis, 0), 2)                 AS park_unrealized,
  -- residual_after_park = the existing events-vs-live residual (undeployed_total - park MV - cash),
  -- with park_unrealized explicitly netted out (subtracted).
  ROUND(
    (
      (SELECT SUM(available_funds) FROM {{ ref('strategy_nav') }})
      - COALESCE(pn.park_mv_now, 0)
      - COALESCE((SELECT total_cash FROM {{ ref('account_latest') }}), 0)
    ) - (COALESCE(pn.park_mv_now, 0) - COALESCE(pn.park_cost_basis, 0))
  , 2)                                                                                     AS residual_after_park
FROM park_now pn

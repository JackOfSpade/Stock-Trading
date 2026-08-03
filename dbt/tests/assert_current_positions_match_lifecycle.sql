-- Singular test (passes when ZERO rows): the two open-position representations must agree on open
-- shares per (strategy, ticker) within tolerance, AFTER netting out still-working BUY orders
-- (stack review 2026-06-24, RUNBOOK §25 B4; pending-order netting 2026-07-27, RUNBOOK §47).
--
-- Rationale: state.current_positions (← events.position_events, the path analytics.strategy_nav reads
-- for the 2%-sizing base) and analytics.position_lifecycle (← authoritative state.trade_fills_curated,
-- the path the TWR engine / §13 read) are independent. They can diverge with NO existing monitor
-- watching position_events. SUM on both sides absorbs leg-splits; the 0.01-share tolerance ignores
-- small rounding noise while catching a whole position present in one representation but not the other.
-- Audited dust is excluded explicitly rather than relying on a share tolerance: a <=$1 residual may
-- exceed 0.01 shares. This is the dbt mirror of state.position_reconciliation.
--
-- WHY THE PENDING-BUY TERM (must stay in lockstep with bigquery/126_dust_operational_hardening.sql):
-- D2 writes the OPEN events.position_events row for a new entry or a pyramid add AT ORDER-STAGING TIME,
-- while position_lifecycle only ever reflects FILLED shares — so every staged-but-unfilled BUY produces a
-- guaranteed share_diff equal to the working quantity. Without this term the test flags that benign,
-- transient lag as a book discrepancy, which is exactly the false positive that halted D2 on 2026-07-26.
-- The netting is SUPPRESS-ONLY by construction (the `> 0` guard plus the GREATEST(..., 0) floor make
-- |residual| <= |raw diff| identically), so it can never hide drift the old form would have caught beyond
-- the pending quantity itself, and can never manufacture a failure where the raw diff was clean.

WITH cp AS (
  SELECT strategy, ticker, SUM(shares) AS s
  FROM {{ ref('current_positions') }}
  WHERE strategy IS NOT NULL AND ticker IS NOT NULL
  GROUP BY strategy, ticker
),
lc AS (
  SELECT strategy, ticker, SUM(shares) AS s
  FROM {{ ref('position_lifecycle') }}
  WHERE exit_date IS NULL AND strategy IS NOT NULL AND ticker IS NOT NULL
    AND NOT COALESCE(is_dust, FALSE)
  GROUP BY strategy, ticker
),
-- Still-working BUY quantity per (strategy, ticker). open_orders is already pending-only. NULL-strategy
-- park legs are excluded here exactly as they are from cp/lc above, so a park order can never introduce
-- a reconciliation group that does not otherwise exist.
pend AS (
  SELECT strategy, ticker, SUM(qty) AS pending_buy_shares
  FROM {{ ref('open_orders') }}
  WHERE side = 'BUY'
    AND qty > 0
    AND strategy IS NOT NULL AND ticker IS NOT NULL
    AND (
      (entry_window_close IS NOT NULL AND entry_window_close >= CURRENT_DATE('America/Denver'))
      OR staged_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 7 DAY)
    )
  GROUP BY strategy, ticker
),
joined AS (
  SELECT
    strategy,
    ticker,
    COALESCE(cp.s, 0) AS current_positions_shares,
    COALESCE(lc.s, 0) AS lifecycle_open_shares,
    COALESCE(cp.s, 0) - COALESCE(lc.s, 0) AS share_diff
  FROM cp FULL OUTER JOIN lc USING (strategy, ticker)
)
-- LEFT JOIN, never FULL OUTER: a pending BUY on a (strategy,ticker) with no position on either side must
-- not conjure a row here.
SELECT
  j.strategy,
  j.ticker,
  j.current_positions_shares,
  j.lifecycle_open_shares,
  j.share_diff,
  COALESCE(p.pending_buy_shares, CAST(0 AS NUMERIC)) AS pending_buy_shares
FROM joined j
LEFT JOIN pend p USING (strategy, ticker)
WHERE ABS(
        IF(j.share_diff > 0,
           GREATEST(j.share_diff - COALESCE(p.pending_buy_shares, CAST(0 AS NUMERIC)), CAST(0 AS NUMERIC)),
           j.share_diff)
      ) > 0.01

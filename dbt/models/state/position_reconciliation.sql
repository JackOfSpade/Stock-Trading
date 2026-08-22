-- Parallel-run dbt port of bigquery/126_dust_operational_hardening.sql:state.position_reconciliation — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
WITH cp AS (
  SELECT strategy, ticker, SUM(shares) AS current_positions_shares
  FROM {{ ref('current_positions') }}
  WHERE strategy IS NOT NULL AND ticker IS NOT NULL
  GROUP BY strategy, ticker
),
lc AS (
  SELECT strategy, ticker, SUM(shares) AS lifecycle_open_shares
  FROM {{ ref('position_lifecycle') }}
  WHERE exit_date IS NULL
    AND strategy IS NOT NULL AND ticker IS NOT NULL
    AND NOT COALESCE(is_dust, FALSE)
  GROUP BY strategy, ticker
),
pend AS (
  SELECT
    strategy,
    ticker,
    SUM(qty) AS pending_buy_shares,
    ARRAY_AGG(item_key ORDER BY item_key) AS pending_buy_item_keys
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
    COALESCE(cp.current_positions_shares, 0) AS current_positions_shares,
    COALESCE(lc.lifecycle_open_shares, 0) AS lifecycle_open_shares,
    COALESCE(cp.current_positions_shares, 0) - COALESCE(lc.lifecycle_open_shares, 0) AS share_diff
  FROM cp FULL OUTER JOIN lc USING (strategy, ticker)
),
netted AS (
  SELECT
    j.strategy,
    j.ticker,
    j.current_positions_shares,
    j.lifecycle_open_shares,
    j.share_diff,
    COALESCE(p.pending_buy_shares, CAST(0 AS NUMERIC)) AS pending_buy_shares,
    COALESCE(p.pending_buy_item_keys, []) AS pending_buy_item_keys,
    IF(j.share_diff > 0,
       GREATEST(j.share_diff - COALESCE(p.pending_buy_shares, CAST(0 AS NUMERIC)), CAST(0 AS NUMERIC)),
       j.share_diff) AS residual_share_diff
  FROM joined j
  LEFT JOIN pend p USING (strategy, ticker)
)
SELECT
  strategy,
  ticker,
  current_positions_shares,
  lifecycle_open_shares,
  share_diff,
  pending_buy_shares,
  pending_buy_item_keys,
  residual_share_diff,
  ABS(share_diff) > 0.01 AS drifted_raw,
  ABS(share_diff) > 0.01 AND ABS(residual_share_diff) <= 0.01 AS explained_by_pending_buy,
  ABS(residual_share_diff) > 0.01 AS drifted,
  CURRENT_TIMESTAMP() AS checked_at
FROM netted

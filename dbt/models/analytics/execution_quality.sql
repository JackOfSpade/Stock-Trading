-- Parallel-run dbt port of bigquery/37_self_improvement_autonomy.sql:analytics.execution_quality — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
WITH staged AS (
  SELECT strategy, ticker,
    UPPER(JSON_VALUE(payload,'$.side')) AS side,
    CAST(JSON_VALUE(payload,'$.limit_price') AS NUMERIC) AS limit_price,
    event_ts AS staged_ts
  FROM {{ source('events', 'queue_events') }}
  WHERE queue = 'ORDER_STAGED' AND JSON_VALUE(payload,'$.limit_price') IS NOT NULL
),
fills AS (
  SELECT trade_id, strategy, ticker, side, shares, price, commission, fill_ts
  FROM {{ ref('trade_fills_curated') }}
  WHERE ticker != 'SGOV'
),
matched AS (
  SELECT f.*, s.limit_price,
    -- signed adverse slippage in bps: BUY worse when price>limit, SELL worse when price<limit
    CASE WHEN f.side = 'BUY'  THEN SAFE_DIVIDE(f.price - s.limit_price, s.limit_price)
         WHEN f.side = 'SELL' THEN SAFE_DIVIDE(s.limit_price - f.price, s.limit_price)
    END * 10000 AS adverse_slippage_bps
  FROM fills f
  LEFT JOIN staged s
    ON s.strategy = f.strategy AND s.ticker = f.ticker AND s.side = f.side
   AND s.staged_ts <= f.fill_ts
  QUALIFY ROW_NUMBER() OVER (PARTITION BY f.trade_id ORDER BY s.staged_ts DESC) = 1
)
SELECT trade_id, strategy, ticker, side, shares, price, commission, limit_price,
  ROUND(adverse_slippage_bps, 2) AS adverse_slippage_bps, fill_ts
FROM matched

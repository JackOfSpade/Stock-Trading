-- Durable fill-level DRIP-dust classifications written by D2a after inspecting the
-- authoritative connector position. Source BUYs key on source_trade_id; completed
-- dispositions add exact liquidation SELL trade ids so Tier-1 can isolate both sides.
-- The legacy branch preserves the two 2026-07-20 classifications, whose original
-- decision rows predate that key. It is deliberately frozen to the two observed
-- fill signatures and emits nothing if either signature is ambiguous.

WITH decisions AS (
  SELECT entry_id, entry_date, ticker, fields
  FROM {{ source('events', 'decision_log') }}
  WHERE entry_type = 'drip-dust'
),
exact_classifications AS (
  SELECT JSON_VALUE(fields, '$.source_trade_id') AS trade_id,
    COALESCE(JSON_VALUE(fields, '$.dust_id'),
      CONCAT('source:', JSON_VALUE(fields, '$.source_trade_id'))) AS dust_id,
    'source-buy' AS fill_role,
    1 AS priority
  FROM decisions
  WHERE JSON_VALUE(fields, '$.record_type') = 'classification'
    AND JSON_VALUE(fields, '$.classification') = 'dust'
    AND JSON_VALUE(fields, '$.source_trade_id') IS NOT NULL
),
legacy_candidates AS (
  SELECT d.entry_id, f.trade_id
  FROM decisions d
  JOIN {{ ref('trade_fills_curated') }} f
    ON d.ticker = f.ticker
   AND SAFE_CAST(JSON_VALUE(d.fields, '$.fill_date') AS DATE)
       = DATE(f.fill_ts, 'America/New_York')
   AND SAFE_CAST(JSON_VALUE(d.fields, '$.shares') AS NUMERIC) = f.shares
  WHERE JSON_VALUE(d.fields, '$.record_type') IS NULL
    AND JSON_VALUE(d.fields, '$.classification') IS NULL
    AND JSON_VALUE(d.fields, '$.disposition') IS NULL
    AND f.side = 'BUY'
    AND f.strategy = 'B'
    AND (
      (d.ticker = 'IBM' AND DATE(f.fill_ts, 'America/New_York') = DATE '2026-06-11'
        AND f.shares = NUMERIC '0.0007' AND f.price = NUMERIC '271.41')
      OR
      (d.ticker = 'HCA' AND DATE(f.fill_ts, 'America/New_York') = DATE '2026-07-01'
        AND f.shares = NUMERIC '0.0001' AND f.price = NUMERIC '389.77')
    )
),
legacy_classifications AS (
  SELECT trade_id, CONCAT('legacy:', entry_id) AS dust_id,
    'source-buy' AS fill_role, 3 AS priority
  FROM legacy_candidates
  QUALIFY COUNT(*) OVER (PARTITION BY entry_id) = 1
),
liquidation_classifications AS (
  SELECT JSON_VALUE(sell_id) AS trade_id,
    JSON_VALUE(fields, '$.dust_id') AS dust_id,
    'liquidation-sell' AS fill_role,
    2 AS priority
  FROM decisions, UNNEST(JSON_QUERY_ARRAY(fields, '$.liquidation_trade_ids')) sell_id
  WHERE (JSON_VALUE(fields, '$.disposition') = 'filled'
      OR JSON_VALUE(fields, '$.record_type') = 'liquidation-fill')
    AND JSON_VALUE(fields, '$.dust_id') IS NOT NULL
  UNION ALL
  SELECT JSON_VALUE(fields, '$.liquidation_trade_id') AS trade_id,
    JSON_VALUE(fields, '$.dust_id') AS dust_id,
    'liquidation-sell' AS fill_role,
    2 AS priority
  FROM decisions
  WHERE (JSON_VALUE(fields, '$.disposition') = 'filled'
      OR JSON_VALUE(fields, '$.record_type') = 'liquidation-fill')
    AND JSON_VALUE(fields, '$.dust_id') IS NOT NULL
    AND JSON_VALUE(fields, '$.liquidation_trade_id') IS NOT NULL
)
SELECT trade_id, TRUE AS is_dust, dust_id, fill_role
FROM (
  SELECT * FROM exact_classifications
  UNION ALL
  SELECT * FROM liquidation_classifications
  UNION ALL
  SELECT * FROM legacy_classifications
)
WHERE trade_id IS NOT NULL
QUALIFY ROW_NUMBER() OVER (PARTITION BY trade_id ORDER BY priority, dust_id) = 1

-- Singular regression: analytics.position_lifecycle must never pair a dust BUY with a non-dust
-- SELL, nor a dust BUY with a SELL carrying a different dust_id -- the invariant that stops an
-- ordinary SELL from consuming an older dust BUY (position_lifecycle.sql's `matched` CTE join
-- predicate: `s.is_dust = b.is_dust AND (NOT b.is_dust OR s.dust_id = b.dust_id)`).
--
-- Fixed 2026-08-02: the prior version of this file hand-copied that join predicate, built its own
-- synthetic fills, and diffed its inline reimplementation against itself -- `ref()` was never
-- called on the real model, so a regression in position_lifecycle.sql could not make it fail.
--
-- Arm A (the real assertion) reads {{ ref('position_lifecycle') }} for real and cross-checks each
-- CLOSED lot's buy/sell legs against {{ ref('dust_classified_fills') }} -- the durable fill-level
-- classification D2a actually wrote -- independently re-joined by trade_id, NOT a copy of the
-- model's join predicate. buy_trade_id/sell_trade_id are recovered from position_key, which
-- position_lifecycle.sql documents as
-- `CONCAT(strategy, ':', ticker, ':', buy_trade_id, ':', sell_trade_id | 'OPEN')`; ticker and
-- trade_id are verified colon-free in production data, so the split is unambiguous. OPEN lots
-- (exit_date IS NULL) have no real sell leg and are excluded -- checking them against the literal
-- string 'OPEN' would be a false positive, not a check of the invariant.
--
-- Arm B is a retained seeded-edge-case algorithm check from the original file (an ordinary
-- re-entry BUY/SELL pair bracketing a dust BUY/SELL in time must not cross-match) -- kept as an
-- ADDITIONAL arm now that Arm A carries the real-model assertion, not as a replacement for it.
--
-- Sensitivity proof (2026-08-02, run by hand against live data via
-- mcp__claude_ai_Google_Cloud_BigQuery__execute_sql_readonly, not part of this file): Arm A as
-- written returns 0 rows against the live analytics.position_lifecycle / dust_classified_fills
-- views (8 closed lots, all non-dust on both legs). Injecting a synthetic dust classification onto
-- one real closed lot's buy_trade_id (sell leg left real/non-dust) makes the identical query return
-- that lot -- confirming the assertion actually fires on the exact violation it's meant to guard,
-- not merely on a structurally-empty join.
--
-- Checked (2026-08-02) against the campaign_semantics-sibling INNER-JOIN-drops-missing-rows defect
-- class and found NOT to share it, so left as-is: real_lifecycle (FROM, the real model's own
-- closed-lot rows, unfiltered by any join) is the sole driving population, and fill_class is
-- consulted via two LEFT JOINs purely as a per-leg dust-classification LOOKUP -- there is no second
-- independently re-derived enumeration of "the correct set of closed lots" being diffed against it
-- that a join could silently drop rows from. LEFT JOIN already guarantees every real_lifecycle row
-- survives regardless of whether bc/sc find a match.

WITH real_lifecycle AS (
  SELECT position_key,
    SPLIT(position_key, ':')[SAFE_OFFSET(2)] AS buy_trade_id,
    SPLIT(position_key, ':')[SAFE_OFFSET(3)] AS sell_trade_id
  FROM {{ ref('position_lifecycle') }}
  WHERE exit_date IS NOT NULL   -- closed lots only -- OPEN lots have no real sell leg to check
),
fill_class AS (
  SELECT trade_id, COALESCE(is_dust, FALSE) AS is_dust, dust_id
  FROM {{ ref('dust_classified_fills') }}
),
arm_a AS (
  SELECT 'real_model' AS arm, l.position_key AS identifier,
    CONCAT('buy_is_dust=', CAST(COALESCE(bc.is_dust, FALSE) AS STRING),
      ' buy_dust_id=', COALESCE(bc.dust_id, 'NULL')) AS actual,
    CONCAT('sell_is_dust=', CAST(COALESCE(sc.is_dust, FALSE) AS STRING),
      ' sell_dust_id=', COALESCE(sc.dust_id, 'NULL')) AS expected
  FROM real_lifecycle l
  LEFT JOIN fill_class bc ON bc.trade_id = l.buy_trade_id
  LEFT JOIN fill_class sc ON sc.trade_id = l.sell_trade_id
  WHERE COALESCE(bc.is_dust, FALSE) != COALESCE(sc.is_dust, FALSE)
     OR (COALESCE(bc.is_dust, FALSE) AND bc.dust_id IS DISTINCT FROM sc.dust_id)
),
-- Arm B: retained seeded edge case -- an ordinary re-entry BUY/SELL pair must not cross-match with
-- a dust BUY/SELL that brackets it in time, even though all four fills share the same
-- (strategy, ticker).
synthetic_raw_fills AS (
  SELECT * FROM UNNEST([
    STRUCT('dust-buy' AS trade_id, 'B' AS strategy, 'LOWPX' AS ticker,
      TIMESTAMP '2026-08-01 14:00:00+00' AS fill_ts, 'BUY' AS side, NUMERIC '0.25' AS shares),
    STRUCT('real-buy', 'B', 'LOWPX', TIMESTAMP '2026-08-02 14:00:00+00', 'BUY', NUMERIC '0.25'),
    STRUCT('real-sell', 'B', 'LOWPX', TIMESTAMP '2026-08-03 14:00:00+00', 'SELL', NUMERIC '0.25'),
    STRUCT('dust-sell', 'B', 'LOWPX', TIMESTAMP '2026-08-04 14:00:00+00', 'SELL', NUMERIC '0.25')
  ])
),
synthetic_classified AS (
  SELECT * FROM UNNEST([
    STRUCT('dust-buy' AS trade_id, TRUE AS is_dust, 'drip-dust:1:anchor' AS dust_id),
    STRUCT('dust-sell', TRUE, 'drip-dust:1:anchor')
  ])
),
synthetic_fills AS (
  SELECT f.*, COALESCE(c.is_dust, FALSE) AS is_dust, c.dust_id
  FROM synthetic_raw_fills f LEFT JOIN synthetic_classified c USING (trade_id)
),
synthetic_buys AS (
  SELECT *, COALESCE(SUM(shares) OVER (
    PARTITION BY strategy, ticker, is_dust, IF(is_dust, dust_id, '')
    ORDER BY fill_ts, trade_id ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS cum_start
  FROM synthetic_fills WHERE side = 'BUY'
),
synthetic_sells AS (
  SELECT *, COALESCE(SUM(shares) OVER (
    PARTITION BY strategy, ticker, is_dust, IF(is_dust, dust_id, '')
    ORDER BY fill_ts, trade_id ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS cum_start
  FROM synthetic_fills WHERE side = 'SELL'
),
synthetic_actual AS (
  SELECT b.trade_id AS buy_trade_id, s.trade_id AS sell_trade_id
  FROM synthetic_buys b
  JOIN synthetic_sells s
    ON s.strategy = b.strategy AND s.ticker = b.ticker
   AND s.is_dust = b.is_dust
   AND (NOT b.is_dust OR s.dust_id = b.dust_id)
  WHERE LEAST(b.cum_start + b.shares, s.cum_start + s.shares)
        > GREATEST(b.cum_start, s.cum_start)
),
synthetic_expected AS (
  SELECT * FROM UNNEST([
    STRUCT('real-buy' AS buy_trade_id, 'real-sell' AS sell_trade_id),
    STRUCT('dust-buy', 'dust-sell')
  ])
),
arm_b AS (
  SELECT 'seeded_edge_case' AS arm,
    COALESCE(a.buy_trade_id, e.buy_trade_id) AS identifier,
    CONCAT('actual_sell=', COALESCE(a.sell_trade_id, 'NULL')) AS actual,
    CONCAT('expected_sell=', COALESCE(e.sell_trade_id, 'NULL')) AS expected
  FROM synthetic_actual a FULL OUTER JOIN synthetic_expected e USING (buy_trade_id)
  WHERE a.buy_trade_id IS NULL OR e.buy_trade_id IS NULL
     OR a.sell_trade_id IS DISTINCT FROM e.sell_trade_id
)
SELECT * FROM arm_a
UNION ALL
SELECT * FROM arm_b

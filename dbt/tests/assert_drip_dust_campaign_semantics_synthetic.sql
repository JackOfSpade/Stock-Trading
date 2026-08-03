-- Singular regression: analytics.position_campaigns.is_dust must agree with what the fill-level
-- dust classifications (analytics.dust_classified_fills, written by D2a from the authoritative
-- connector position, not price/direction inference) imply for that campaign's BUY fills: TRUE iff
-- at least one BUY fill in the campaign is dust-classified AND no BUY fill in the campaign is
-- un-classified.
--
-- Fixed 2026-08-02: the prior version of this file hand-copied position_campaigns.sql's is_dust
-- formula, built its own synthetic fills, and diffed its inline reimplementation against itself --
-- `ref()` was never called on the real model, so a regression in position_campaigns.sql could not
-- make it fail.
--
-- Arm A (the real assertion) reads {{ ref('position_campaigns') }} for real and diffs its is_dust
-- column against an expectation recomputed from {{ ref('dust_classified_fills') }}. Campaign
-- membership -- which fill belongs to which campaign_key -- isn't exposed by position_campaigns'
-- output columns, so it is reconstructed from {{ ref('trade_fills_curated') }} using the same
-- 0->nonzero running-position transition position_campaigns.sql documents as the definition of a
-- campaign; that reconstruction is necessary scaffolding to attribute fills to a campaign_key, not
-- a copy of the is_dust invariant under test (the is_dust formula itself IS the thing being
-- recomputed as the "expected" side and diffed against the model's real output column, same shape
-- as assert_thesis_outcomes_regime_asof.sql's as-of recompute-and-diff pattern).
--
-- Arm B is a retained seeded-edge-case algorithm check from the original file (option contracts,
-- short opens, null-price fills, mixed dust/real buys, tiny-but-authorized buys all classify as
-- expected) -- kept as an ADDITIONAL arm now that Arm A carries the real-model assertion, not as a
-- replacement for it.
--
-- Sensitivity proof (2026-08-02, run by hand against live data via
-- mcp__claude_ai_Google_Cloud_BigQuery__execute_sql_readonly, not part of this file): Arm A as
-- written returns 0 rows against the live analytics.position_campaigns / dust_classified_fills /
-- state.trade_fills_curated views (22 campaigns, including 2 real dust campaigns -- B:HCA:2 and
-- B:IBM:2 -- both correctly TRUE on both the actual and independently-recomputed-expected side).
-- Inverting the diff condition (IS NOT DISTINCT FROM instead of IS DISTINCT FROM) returns all 22
-- rows, confirming the recomputed expectation tracks real per-campaign dust status -- including the
-- two genuinely-dust campaigns -- rather than being a vacuous always-false/always-true column.
--
-- Fixed 2026-08-02 (2nd pass): Arm A's real-vs-expected diff used a plain INNER JOIN, which -- unlike
-- the value-mismatch check above -- silently DROPS any campaign present on one side but missing from
-- the other, so a regression making the model emit the wrong SET of campaigns would pass with 0
-- rows. Now FULL OUTER JOIN with explicit NULL-side checks. Re-verified live: as-written still
-- returns 0 rows (22 campaigns, all matched). Filtering campaign_key = 'B:IBM:2' out of the
-- position_campaigns side (simulating the model silently dropping a real dust campaign) makes the
-- identical query return exactly that 1 row, tagged "MISSING (absent from real position_campaigns)"
-- -- the old INNER JOIN form re-run against the same dropped-campaign input returns 0 rows,
-- confirming this is the exact blind spot being closed. Liquidation check: injecting the 2026-08-03
-- closing SELL fills for the two open dust lots (IBM 0.0007 sh, HCA 0.0001 sh) into the fills CTE
-- does not change the result (still 0 rows) -- is_dust is computed from BUY fills only
-- (position_campaigns.sql's GROUP BY formula), so a later closing SELL cannot flip it and the fix
-- will not false-fail once those lots are liquidated.

WITH fills AS (
  SELECT f.trade_id, f.strategy, f.ticker, f.fill_ts, f.side, f.shares,
    COALESCE(dcf.is_dust, FALSE) AS fill_is_dust
  FROM {{ ref('trade_fills_curated') }} f
  LEFT JOIN {{ ref('dust_classified_fills') }} dcf USING (trade_id)
  WHERE f.ticker != 'SGOV' AND f.shares IS NOT NULL AND f.shares > 0
),
running AS (
  SELECT *,
    COALESCE(SUM(IF(side = 'BUY', shares, -shares)) OVER (
      PARTITION BY strategy, ticker ORDER BY fill_ts, trade_id
      ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS prev_running_shares,
    SUM(IF(side = 'BUY', shares, -shares)) OVER (
      PARTITION BY strategy, ticker ORDER BY fill_ts, trade_id
      ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_shares
  FROM fills
),
seqd AS (
  SELECT *, COUNTIF(prev_running_shares = 0 AND running_shares != 0) OVER (
    PARTITION BY strategy, ticker ORDER BY fill_ts, trade_id
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS campaign_seq
  FROM running
),
expected AS (
  SELECT CONCAT(strategy, ':', ticker, ':', CAST(campaign_seq AS STRING)) AS campaign_key,
    COUNTIF(side = 'BUY' AND fill_is_dust) > 0
      AND COUNTIF(side = 'BUY' AND NOT fill_is_dust) = 0 AS expected_is_dust
  FROM seqd
  GROUP BY strategy, ticker, campaign_seq
),
arm_a AS (
  -- FULL OUTER (not INNER): an INNER JOIN here would silently DROP any campaign present in
  -- position_campaigns but missing from the recomputed `expected` set, or vice versa -- i.e. a
  -- regression that makes the model emit the wrong SET of campaigns (extra/missing/differently
  -- keyed) would produce zero rows and this test would still pass. The FULL OUTER JOIN plus the
  -- explicit NULL checks turn a missing-on-either-side campaign into a reported failure row, with
  -- the actual/expected text saying which side it was absent from.
  SELECT 'real_model' AS arm,
    COALESCE(c.campaign_key, e.campaign_key) AS identifier,
    CASE WHEN c.campaign_key IS NULL THEN 'MISSING (absent from real position_campaigns)'
         ELSE CONCAT('is_dust=', CAST(c.is_dust AS STRING)) END AS actual,
    CASE WHEN e.campaign_key IS NULL THEN 'MISSING (absent from recomputed expected set)'
         ELSE CONCAT('is_dust=', CAST(e.expected_is_dust AS STRING)) END AS expected
  FROM {{ ref('position_campaigns') }} c
  FULL OUTER JOIN expected e USING (campaign_key)
  WHERE c.campaign_key IS NULL
     OR e.campaign_key IS NULL
     OR c.is_dust IS DISTINCT FROM e.expected_is_dust
),
-- Arm B: retained seeded edge cases -- audited source-fill classification, not price/direction
-- inference, controls dust; a mixed campaign (one dust BUY + one non-dust BUY) is NOT dust.
synthetic_fills AS (
  SELECT * FROM UNNEST([
    STRUCT('dust-buy' AS trade_id, 'B' AS strategy, 'IBM' AS ticker, TIMESTAMP '2026-06-11 14:00:00+00' AS fill_ts, 'BUY' AS side, NUMERIC '0.0007' AS shares, NUMERIC '271.41' AS price),
    STRUCT('dust-sell', 'B', 'IBM', TIMESTAMP '2026-08-03 14:00:00+00', 'SELL', NUMERIC '0.0007', NUMERIC '223.65'),
    STRUCT('mixed-dust-buy', 'B', 'HCA', TIMESTAMP '2026-07-01 14:00:00+00', 'BUY', NUMERIC '0.0001', NUMERIC '389.77'),
    STRUCT('mixed-real-buy', 'B', 'HCA', TIMESTAMP '2026-07-15 14:00:00+00', 'BUY', NUMERIC '0.10', NUMERIC '400'),
    STRUCT('option-buy', 'C', 'XYZ   260821C00050000', TIMESTAMP '2026-06-12 14:00:00+00', 'BUY', NUMERIC '1', NUMERIC '0.50'),
    STRUCT('short-open', 'E', 'PAIRSHORT', TIMESTAMP '2026-06-13 14:00:00+00', 'SELL', NUMERIC '10', NUMERIC '50'),
    STRUCT('null-price-buy', 'A', 'NULLPX', TIMESTAMP '2026-06-14 14:00:00+00', 'BUY', NUMERIC '1', CAST(NULL AS NUMERIC)),
    STRUCT('tiny-authorized-buy', 'D', 'TINY', TIMESTAMP '2026-06-15 14:00:00+00', 'BUY', NUMERIC '1', NUMERIC '0.50'),
    STRUCT('real-buy', 'D', 'RTX', TIMESTAMP '2026-06-16 14:00:00+00', 'BUY', NUMERIC '0.2', NUMERIC '140'),
    STRUCT('open-position-drip', 'D', 'RTX', TIMESTAMP '2026-06-17 14:00:00+00', 'BUY', NUMERIC '0.0006', NUMERIC '140')
  ])
),
synthetic_classified AS (
  SELECT * FROM UNNEST([
    STRUCT('dust-buy' AS trade_id, TRUE AS is_dust),
    STRUCT('mixed-dust-buy', TRUE)
  ])
),
synthetic_joined AS (
  SELECT f.*, COALESCE(c.is_dust, FALSE) AS fill_is_dust,
    IF(side = 'BUY', shares, -shares) AS signed_shares
  FROM synthetic_fills f LEFT JOIN synthetic_classified c USING (trade_id)
),
synthetic_running AS (
  SELECT *,
    SUM(signed_shares) OVER w AS running_shares,
    COALESCE(SUM(signed_shares) OVER (PARTITION BY strategy, ticker ORDER BY fill_ts, trade_id
      ROWS BETWEEN UNBOUNDED PRECEDING AND 1 PRECEDING), 0) AS prev_running_shares
  FROM synthetic_joined
  WINDOW w AS (PARTITION BY strategy, ticker ORDER BY fill_ts, trade_id
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
),
synthetic_seqd AS (
  SELECT *, COUNTIF(prev_running_shares = 0 AND running_shares != 0) OVER (
    PARTITION BY strategy, ticker ORDER BY fill_ts, trade_id
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS campaign_seq
  FROM synthetic_running
),
synthetic_actual AS (
  SELECT CONCAT(strategy, ':', ticker, ':', CAST(campaign_seq AS STRING)) AS campaign_key,
    COUNTIF(side = 'BUY' AND fill_is_dust) > 0
      AND COUNTIF(side = 'BUY' AND NOT fill_is_dust) = 0 AS is_dust
  FROM synthetic_seqd GROUP BY strategy, ticker, campaign_seq
),
synthetic_expected AS (
  SELECT * FROM UNNEST([
    STRUCT('B:IBM:1' AS campaign_key, TRUE AS is_dust),
    STRUCT('B:HCA:1', FALSE),
    STRUCT('C:XYZ   260821C00050000:1', FALSE),
    STRUCT('E:PAIRSHORT:1', FALSE),
    STRUCT('A:NULLPX:1', FALSE),
    STRUCT('D:TINY:1', FALSE),
    STRUCT('D:RTX:1', FALSE)
  ])
),
arm_b AS (
  SELECT 'seeded_edge_case' AS arm, COALESCE(a.campaign_key, e.campaign_key) AS identifier,
    CONCAT('is_dust=', CAST(a.is_dust AS STRING)) AS actual,
    CONCAT('is_dust=', CAST(e.is_dust AS STRING)) AS expected
  FROM synthetic_actual a FULL OUTER JOIN synthetic_expected e USING (campaign_key)
  WHERE a.campaign_key IS NULL OR e.campaign_key IS NULL OR a.is_dust IS DISTINCT FROM e.is_dust
)
SELECT * FROM arm_a
UNION ALL
SELECT * FROM arm_b

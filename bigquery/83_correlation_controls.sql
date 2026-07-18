-- Concurrent-position correlation controls (2026-07-17 whole-system deep audit, finding M1
-- [strategy-quality]). Project: stock-trading-498512. Apply AFTER 03_twr_engine.sql /
-- 40_options_marks.sql (analytics.strategy_daily_returns) and 01_schema.sql (state.current_positions,
-- state.daily_marks_curated).
--
-- WHY. Operating_Protocols.md §232/242/250: after the 2026-05-30 owner directive removed ALL
-- holdings-count caps on Strategy B, "KL #12 metric (d) average-pairwise-correlation monitoring is
-- the SOLE concurrent-position-correlation control" — if avg pairwise correlation of open B longs
-- exceeds 0.5, the per-trade 2% loss bound no longer bounds portfolio-level loss. The protocol says
-- to check metric (d) at each monthly review — but NO routine owns a B monthly review and NO SQL
-- anywhere computes return correlation (grep 'CORR(' over bigquery/ dbt/ = empty). This file encodes
-- it once. It ALSO gives SL4's "redundancy" retirement signal (rolling return-correlation with a peer
-- above threshold, Claude_Task_Plan.md:2220; bigquery/35:595 admits it is unencoded) its missing
-- substrate — WIRED 2026-07-18 (audit follow-up: the view sat consumer-less for a day): SL4 STEP 1's
-- redundancy bullet now reads analytics.strategy_return_correlation (corr >= 0.7, overlap_days >= 40,
-- dominated-member-only, default-KEEP on ambiguity). Both views are record-only inputs; the D1/W3
-- alert wiring (a record-only warning, never an entry block — Rev 35's no-cap doctrine is untouched)
-- lives in Claude_Task_Plan.md.

-- ===== analytics.b_pairwise_correlation — the KL #12 metric (d) control (single-row summary) =====
-- Trailing ~63-trading-day (90 calendar-day) daily-return CORR across every pair of open Strategy-B
-- positions. Single-row aggregate (self-bootstrapping — always exactly one row even with 0/1 open B
-- positions, so a consumer join can never drop out). avg_offdiagonal_corr is NULL when <2 positions.
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.b_pairwise_correlation` AS
WITH b_pos AS (
  SELECT DISTINCT ticker
  FROM `stock-trading-498512.state.current_positions`
  WHERE strategy = 'B' AND ticker IS NOT NULL
),
rets AS (
  SELECT ticker, mark_date,
    SAFE_DIVIDE(close, LAG(close) OVER (PARTITION BY ticker ORDER BY mark_date)) - 1 AS r
  FROM `stock-trading-498512.state.daily_marks_curated`
  WHERE ticker IN (SELECT ticker FROM b_pos)
    AND mark_date >= DATE_SUB(CURRENT_DATE('America/New_York'), INTERVAL 90 DAY)
),
pairs AS (
  SELECT a.ticker AS t1, b.ticker AS t2, a.r AS r1, b.r AS r2
  FROM rets a JOIN rets b ON a.mark_date = b.mark_date AND a.ticker < b.ticker
  WHERE a.r IS NOT NULL AND b.r IS NOT NULL
),
pair_corr AS (
  SELECT t1, t2, CORR(r1, r2) AS corr, COUNT(*) AS overlap_days
  FROM pairs GROUP BY t1, t2
)
SELECT
  (SELECT COUNT(*) FROM b_pos) AS n_positions,
  (SELECT COUNT(*) FROM pair_corr) AS n_pairs,
  (SELECT AVG(corr) FROM pair_corr WHERE overlap_days >= 40) AS avg_offdiagonal_corr,
  -- min over the SAME >=40-day population as AVG/MAX (2026-07-18 audit): an unfiltered global MIN
  -- let a single fresh position drag min_overlap_days below D1's `min_overlap_days >= 40` AND-term
  -- and suppress the KL #12 alert for the WHOLE book — the exact routine state (2 mature correlated
  -- positions + 1 new one) the control exists for. NULL when no qualifying pair exists, which still
  -- correctly fails D1's condition (no mature evidence -> no alert).
  (SELECT MIN(overlap_days) FROM pair_corr WHERE overlap_days >= 40) AS min_overlap_days,
  (SELECT MAX(corr) FROM pair_corr WHERE overlap_days >= 40) AS max_pairwise_corr,
  CURRENT_TIMESTAMP() AS computed_at;

-- ===== analytics.strategy_return_correlation — SL4 "redundancy" retirement-signal substrate =====
-- Trailing ~63-trading-day CORR of strategy-level deployed daily returns (r_deployed) between every
-- pair of strategies with data. One row per (strategy pair); overlap_days guards a noise read.
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.strategy_return_correlation` AS
WITH r AS (
  SELECT strategy, as_of_date, r_deployed
  FROM `stock-trading-498512.analytics.strategy_daily_returns`
  WHERE as_of_date >= DATE_SUB(CURRENT_DATE('America/New_York'), INTERVAL 90 DAY)
    AND r_deployed IS NOT NULL
)
SELECT a.strategy AS strategy_a, b.strategy AS strategy_b,
       CORR(a.r_deployed, b.r_deployed) AS corr,
       COUNT(*) AS overlap_days
FROM r a JOIN r b ON a.as_of_date = b.as_of_date AND a.strategy < b.strategy
GROUP BY a.strategy, b.strategy;

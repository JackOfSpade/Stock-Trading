-- Beta-Binomial shrinkage calibration; retires the binary 30-trade -> BQML-logistic cliff (2026-07-03,
-- self-improvement audit S-2/B-2). Project: stock-trading-498512. Apply after 04_analytics.sql
-- (analytics.conviction_features / calibration_summary).
--
-- PROBLEM: analytics.calibration_summary.win_rate is a raw MLE (SAFE_DIVIDE(wins,closed)) with no
-- interval — at today's 8/8 closed-B-wins it reads 1.000, the exact "100% hit rate" overfitting
-- hazard the project's own foundation doc warns against. The only PLANNED next step was a BQML
-- LOGISTIC_REG model gated at >=30 closed GO trades (04_analytics.sql) — a fit on ~30 fee-dominated,
-- single-class, non-independent (one regime, correlated) binary outcomes with 4 categorical features
-- and no CV/walk-forward. That model is DEPRECATED here in favor of shrinkage, which is honest from
-- trade 1 and never needs the both-classes precondition the logistic fit requires.
--
-- FIX: per conviction tier, a Beta-Binomial posterior mean (shrunk toward a FIXED prior, not the
-- in-sample rate) plus a Wilson 95% interval on the raw count, plus a hard `trustworthy_edge` gate.
-- PRIOR CHOICE: Beta(2,2) (centered at 0.5, pseudocount 4) -- deliberately NOT the pooled sample win
-- rate (which at 8/8 computes p0=1.0 and "shrinks" to 1.0, regularizing nothing precisely when
-- regularization matters most -- a bug in an earlier draft of this fix caught by adversarial review).
-- 0.5 is a conservative, uninformative anchor; a future refinement could replace it with the
-- net-of-fee breakeven win rate implied by the B gap-fill target/stop payoff geometry once that is
-- precisely spec'd as a versioned constant -- NOT derived ad hoc here (self-improvement audit,
-- deferred "missing idea").

CREATE OR REPLACE VIEW `stock-trading-498512.analytics.calibration_shrunk` AS
WITH base AS (
  SELECT COALESCE(conviction, '(unscored)') AS conviction, ANY_VALUE(conviction_ordinal) AS ord,
    COUNT(*) AS go_theses, COUNTIF(position_closed) AS closed, COUNTIF(was_profitable) AS wins
    -- was_profitable is realized_pnl > 0 (analytics.thesis_outcomes <- analytics.position_lifecycle
    -- <- state.trade_fills_curated.realized_pnl), which is the BROKER's net-of-commission realized
    -- P&L per fill -- already the NET label the self-improvement audit's S-4 fix asked calibration to
    -- consume; no separate net conversion needed here.
  FROM `stock-trading-498512.analytics.conviction_features`
  GROUP BY conviction
),
prior AS (SELECT 2.0 AS prior_a, 2.0 AS prior_b),
wilson AS (
  SELECT b.*, p.prior_a, p.prior_b,
    SAFE_DIVIDE(b.wins, b.closed) AS p_hat,
    -- Wilson score interval (z=1.96), the standard honest-at-low-N interval -- distinct from the
    -- shrunk point estimate (shrinkage and interval width are two separate small-sample corrections).
    SAFE_DIVIDE(SAFE_DIVIDE(b.wins, b.closed) + (1.96*1.96)/(2*b.closed), 1 + (1.96*1.96)/b.closed) AS wilson_center,
    SAFE_DIVIDE(
      1.96 * SQRT(SAFE_DIVIDE(SAFE_DIVIDE(b.wins, b.closed) * (1 - SAFE_DIVIDE(b.wins, b.closed)), b.closed)
                  + (1.96*1.96)/(4*b.closed*b.closed)),
      1 + (1.96*1.96)/b.closed
    ) AS wilson_margin
  FROM base b, prior p
)
SELECT
  conviction, ord, go_theses, closed, wins,
  ROUND(p_hat, 3) AS win_rate,   -- raw MLE -- DO NOT read this alone; see wilson_low / trustworthy_edge
  ROUND(SAFE_DIVIDE(wins + prior_a, closed + prior_a + prior_b), 3) AS win_rate_shrunk,
  -- closed=0 has no Wilson interval to compute (n=0); represent it as maximal uncertainty [0,1]
  -- rather than NULL, which would read as "couldn't compute" instead of "known to be uninformative".
  ROUND(GREATEST(0.0, COALESCE(wilson_center - wilson_margin, 0.0)), 3) AS wilson_low,
  ROUND(LEAST(1.0, COALESCE(wilson_center + wilson_margin, 1.0)), 3) AS wilson_high,
  -- trustworthy_edge: the ONLY gate that may change behavior off this view. >=15 closed is still a
  -- directional-signal bar, not the foundation doc's stated >=30/200 for statistical proof -- deliberately
  -- conservative pending real volume. Below it, consumers read win_rate_shrunk as a lightly-informative
  -- prior-anchored estimate, never as a directive.
  (closed >= 15 AND COALESCE(wilson_center - wilson_margin, 0.0) > 0.55) AS trustworthy_edge
FROM wilson
ORDER BY ord;

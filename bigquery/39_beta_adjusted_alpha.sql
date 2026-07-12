-- Beta-adjusted alpha component (ITEM 10, self-improvement audit 2026-07-11; finding H-4). Project:
-- stock-trading-498512. Apply after 03_twr_engine.sql (events.daily_marks, state.daily_marks_curated,
-- analytics.strategy_daily_returns, perf.strategy_daily) and 35_strategy_arsenal.sql
-- (state.strategy_retirement_candidacy — this file's rebuild of that view must land AFTER 35's).
--
-- WHY: every quantitative gate driving SISA's autonomous decisions — perf.kill_flags
-- (m2m_underperf_review, interim_underperf_warning) and state.strategy_retirement_candidacy
-- (edge_decay_signal) — compares deployed TWR only against the SGOV cash benchmark, never separating
-- market-beta exposure from idiosyncratic stock-picking skill. In a sustained bull regime this inflates
-- excess-vs-SGOV on pure beta (biasing SL1/SL3 toward over-adopting "beta wearing a narrative costume");
-- in a bear regime it can fire a false underperformance review on a strategy that is genuinely
-- outperforming the market on a risk-adjusted basis but still trails a positive-yielding cash benchmark.
-- Strategy D's OWN pre-mortem (strategy/08_pre_mortems.md) specified exactly this beta-adjusted-alpha test
-- as its primary edge-decay indicator after 5 revision cycles; this file generalizes it into a reusable
-- component (BigQuery's native REGR_SLOPE/REGR_INTERCEPT — a verified, non-LLM-computed regression,
-- mirroring the rigor c_options_math.py provides for Strategy C) and closes both the systemic gap AND D's
-- own unimplemented commitment, well ahead of its ~2028-04 24-month checkpoint.
--
-- SCOPE (deliberately bounded, see the ADDITIVE-ONLY note below): wired as an ADDITIONAL suppressing
-- condition on perf.kill_flags.m2m_underperf_review / interim_underperf_warning and
-- state.strategy_retirement_candidacy.edge_decay_signal — the three gates reading DEPLOYED (live-capital)
-- daily returns from perf.strategy_daily. state.strategy_paper_readiness.excess_met (Item 8) is
-- DELIBERATELY NOT touched here: PAPER-phase incubation measures a cumulative sim_twr/sgov_twr INDEX
-- ratio (analytics.strategy_incubation_perf), not a raw daily-return series, so a comparable beta
-- regression would need a materially different, lower-confidence construction against a much smaller N
-- (paper_days>=60 is already a thin sample for a 40-observation-minimum regression) — left as a documented
-- future extension, not attempted here to avoid a low-quality beta reading gating live-capital promotion.
--
-- ADDITIVE ONLY, NEVER A REPLACEMENT: the SGOV excess-real-return success metric (Experiment_Parameters.md)
-- is UNCHANGED — this file only ever SUPPRESSES a review/edge-decay-signal firing when a confident
-- (min_n_met) beta reading shows the SGOV-relative underperformance is fully explained by non-positive
-- market-beta alpha; it can never fire a NEW review/kill that the unmodified SGOV-relative check would not
-- already have fired. drawdown_kill / runaway_review / gate_reached (absolute-magnitude checks, not
-- SGOV-relative) are untouched. Idempotent (CREATE OR REPLACE); safe to re-run.

-- ============================================================================
-- analytics.spy_daily_return — SPY's ACTUAL total return (close + dividend), the market-beta benchmark.
-- Mirrors analytics.sgov_daily_return (03_twr_engine.sql) exactly. Fed by D2a's daily mark-ingest, which
-- now pulls SPY unconditionally alongside SGOV (Claude_Task_Plan.md D2a STEP 1, ITEM 10).
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.spy_daily_return` AS
WITH s AS (
  SELECT mark_date, close, COALESCE(dividend, 0) AS dividend,
         LAG(close) OVER (ORDER BY mark_date) AS prev_close
  FROM `stock-trading-498512.state.daily_marks_curated`
  WHERE ticker = 'SPY'
)
SELECT mark_date AS as_of_date, SAFE_DIVIDE(close + dividend - prev_close, prev_close) AS r_spy
FROM s WHERE prev_close IS NOT NULL;

-- ============================================================================
-- analytics.strategy_beta — rolling 60-trading-day OLS beta/alpha of each strategy's deployed daily
-- return (analytics.strategy_daily_returns.r_deployed) against SPY's daily total return. BigQuery
-- GoogleSQL has NO REGR_SLOPE/REGR_INTERCEPT (an Oracle/Snowflake convention this file's first draft
-- wrongly assumed and which failed live with "Function not found" before this fix) — computed instead
-- via the standard closed-form OLS solution from BigQuery-native statistical aggregates, used as WINDOW
-- functions: beta = Cov(y,x)/Var(x) (COVAR_SAMP/VAR_SAMP), alpha = mean(y) - beta*mean(x). Verified,
-- non-LLM-computed regression; mathematically identical to REGR_SLOPE/REGR_INTERCEPT's definition. One
-- row per (strategy, as_of_date) — the full historical series, for audit/back-testing; consumers read
-- analytics.strategy_beta_latest below.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.strategy_beta` AS
WITH joined AS (
  SELECT sdr.as_of_date, sdr.strategy, sdr.r_deployed, spy.r_spy
  FROM `stock-trading-498512.analytics.strategy_daily_returns` sdr
  JOIN `stock-trading-498512.analytics.spy_daily_return` spy USING (as_of_date)
),
windowed AS (
  SELECT
    as_of_date, strategy, r_deployed, r_spy,
    COUNT(*) OVER w AS n_obs,
    SAFE_DIVIDE(COVAR_SAMP(r_deployed, r_spy) OVER w, VAR_SAMP(r_spy) OVER w) AS beta_hat,
    AVG(r_deployed) OVER w
      - SAFE_DIVIDE(COVAR_SAMP(r_deployed, r_spy) OVER w, VAR_SAMP(r_spy) OVER w) * AVG(r_spy) OVER w
      AS alpha_daily_hat
  FROM joined
  WINDOW w AS (PARTITION BY strategy ORDER BY as_of_date ROWS BETWEEN 59 PRECEDING AND CURRENT ROW)
)
SELECT
  as_of_date, strategy, n_obs, beta_hat, alpha_daily_hat,
  -- Annualized alpha (compounds the daily-regression intercept over ~252 trading days) — the
  -- human-readable magnitude every consumer below actually reads. Floored at -100% when the daily
  -- intercept implies a total-or-worse loss (base <= 0): POWER's even exponent (252) would otherwise
  -- flip a catastrophically-negative alpha_daily_hat into a large POSITIVE alpha_annualized, which
  -- would spuriously SATISFY the `alpha_annualized <= 0` suppression term below (adversarial
  -- self-audit fix, rev 2026-07-11).
  IF(1 + alpha_daily_hat <= 0, -1.0, POWER(1 + alpha_daily_hat, 252) - 1) AS alpha_annualized,
  (n_obs >= 40) AS min_n_met
FROM windowed;

-- ============================================================================
-- analytics.strategy_beta_latest — latest reading per strategy (the join surface every gate below uses).
-- Fail-closed by construction: a strategy absent from this view (zero deployed days, or the join to SPY
-- returns is empty) simply has no row, and every consumer below treats a missing row as
-- "beta not measurable" (LEFT JOIN + COALESCE(min_n_met, FALSE)) — never a NULL that silently defaults to
-- suppressing a genuine underperformance signal.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.analytics.strategy_beta_latest` AS
SELECT as_of_date, strategy, n_obs, beta_hat, alpha_daily_hat, alpha_annualized, min_n_met
FROM `stock-trading-498512.analytics.strategy_beta`
QUALIFY ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY as_of_date DESC) = 1;

-- ============================================================================
-- perf.kill_flags — REBUILD with the beta-adjusted suppression folded into m2m_underperf_review and
-- interim_underperf_warning (drawdown_kill / runaway_review / gate_reached UNCHANGED — absolute-magnitude
-- checks, not SGOV-relative). Suppression logic: `NOT min_n_met OR alpha_annualized <= 0` — if beta is not
-- yet measurable (min_n_met=FALSE), the AND-term reduces to TRUE and behavior is IDENTICAL to before this
-- file (fires on the original SGOV-relative condition alone); if beta IS measurable and alpha is
-- non-positive, the term is also TRUE (genuine underperformance, unaffected); only when alpha is
-- confidently POSITIVE (real stock-picking skill, SGOV-relative shortfall fully explained by low/negative
-- beta exposure rather than bad decisions) does the term go FALSE and suppress the review/warning that the
-- unmodified SGOV-only check would have fired. This is a byte-for-byte copy of 03_twr_engine.sql's
-- perf.kill_flags definition with only the two named columns changed — keep the two files' comments in
-- sync if either changes.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.perf.kill_flags` AS
SELECT
  k.strategy, k.as_of_date, k.deployed_unit_value, k.peak_unit_value, k.current_drawdown,
  k.excess_vs_sgov, k.deployed_days, k.closed_trades, k.gate_n,
  k.current_drawdown <= -0.50                                                AS drawdown_kill,        -- kill #1
  (k.deployed_unit_value >= 2 AND k.closed_trades < 30 AND k.deployed_days >= 30) AS runaway_review,   -- kill #3
  ((k.deployed_days >= 756 AND k.excess_vs_sgov <= -0.10)
   AND (NOT COALESCE(b.min_n_met, FALSE) OR COALESCE(b.alpha_annualized, 0) <= 0)) AS m2m_underperf_review, -- kill #4, beta-adjusted (ITEM 10)
  (k.closed_trades >= 30)                                                    AS gate_reached,         -- 30-trade gate
  ((k.deployed_days >= 90 AND k.excess_vs_sgov <= -0.15)
   AND (NOT COALESCE(b.min_n_met, FALSE) OR COALESCE(b.alpha_annualized, 0) <= 0)) AS interim_underperf_warning, -- beta-adjusted (ITEM 10)
  b.beta_hat, b.alpha_annualized, COALESCE(b.min_n_met, FALSE) AS beta_min_n_met
FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY as_of_date DESC) rn
      FROM `stock-trading-498512.perf.strategy_daily`) k
LEFT JOIN `stock-trading-498512.analytics.strategy_beta_latest` b ON b.strategy = k.strategy
WHERE k.rn = 1;

-- ============================================================================
-- state.strategy_retirement_candidacy — REBUILD (bigquery/35_strategy_arsenal.sql's definition) with the
-- SAME beta-adjusted suppression folded into edge_decay_signal / candidacy_fired. This file must be
-- applied AFTER 35_strategy_arsenal.sql on any full DR rebuild (see header). Byte-for-byte copy of that
-- view with only edge_decay_signal's condition changed to add the beta AND-term — keep in sync.
-- ============================================================================
CREATE OR REPLACE VIEW `stock-trading-498512.state.strategy_retirement_candidacy` AS
WITH latest AS (
  SELECT strategy AS strategy_code, excess_vs_sgov, deployed_days
  FROM `stock-trading-498512.perf.strategy_daily`
  QUALIFY ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY as_of_date DESC) = 1
),
beta AS (
  SELECT strategy AS strategy_code, alpha_annualized, min_n_met
  FROM `stock-trading-498512.analytics.strategy_beta_latest`
),
rails AS (SELECT * FROM `stock-trading-498512.state.arsenal_rails`),
ars AS (SELECT enabled, incubation_frozen FROM `stock-trading-498512.state.arsenal_enabled`)
SELECT
  r.strategy_code,
  l.excess_vs_sgov,
  l.deployed_days,
  b.alpha_annualized,
  COALESCE(b.min_n_met, FALSE) AS beta_min_n_met,
  ((l.deployed_days >= 252 AND l.excess_vs_sgov < 0)
   AND (NOT COALESCE(b.min_n_met, FALSE) OR COALESCE(b.alpha_annualized, 0) <= 0)) AS edge_decay_signal,
  rails.active_count,
  rails.active_count > rails.n_min AS floor_ok,
  (ars.enabled AND NOT ars.incubation_frozen) AS arsenal_ok,
  NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.roster_change_log` cl
              WHERE cl.strategy_code = r.strategy_code
                AND cl.to_state = 'RETIREMENT_PROPOSED'
                AND cl.change_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 90 DAY)) AS cooldown_clear,
  (COALESCE(l.deployed_days, 0) >= 252
   AND COALESCE(l.excess_vs_sgov, 0) < 0
   AND (NOT COALESCE(b.min_n_met, FALSE) OR COALESCE(b.alpha_annualized, 0) <= 0)
   AND rails.active_count > rails.n_min
   AND ars.enabled AND NOT ars.incubation_frozen
   AND NOT EXISTS (SELECT 1 FROM `stock-trading-498512.ops.roster_change_log` cl
                   WHERE cl.strategy_code = r.strategy_code
                     AND cl.to_state = 'RETIREMENT_PROPOSED'
                     AND cl.change_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 90 DAY))) AS candidacy_fired
FROM `stock-trading-498512.state.strategy_roster` r
JOIN latest l USING (strategy_code)
LEFT JOIN beta b USING (strategy_code)
CROSS JOIN rails CROSS JOIN ars
WHERE r.current_state = 'ADOPTED';

-- Concentration observability under free sizing. Project: stock-trading-498512.
--
-- WHY THIS EXISTS. Owner directive 2026-08-05 retired BOTH hard Capital-at-Risk envelopes (per-name
-- aggregate <=10% of strategy portfolio, per-strategy total deployed <=75%; Experiment_Parameters.md
-- rev 19). Sizing now carries no numeric ceiling at any level. The same directive removed
-- Operating_Protocols KL#12 monitoring metric (b), "long exposure > 10% of strategy portfolio",
-- because under free sizing an AGGREGATE-exposure threshold carries no information: 10% long exposure
-- is either one deliberately concentrated thesis or six small ones, and the metric cannot tell them
-- apart. That removal was correct, but it left a real blind spot, and this view is the honest
-- replacement for it.
--
-- THE BLIND SPOT. The surviving KL#12 metric (d) is average pairwise correlation across active long B
-- positions. It catches "several positions secretly acting as one". It says NOTHING about the case
-- free sizing newly makes possible: a SINGLE position that is most of a strategy. With one dominant
-- name there are no pairs to correlate, so (d) is undefined or meaningless exactly where concentration
-- is at its maximum. Aggregate exposure could not distinguish that case; largest-single-name share can,
-- and it is scale-free -- it presupposes no cap, which is why it survives the envelope retirement that
-- killed metric (b).
--
-- ############################################################################################
-- THIS IS NEVER A GATE. IT HAS NO THRESHOLD. DO NOT ADD ONE.
-- ############################################################################################
-- No routine may decline, defer, resize or delay an entry because a number in this view is high, and
-- no alert fires off it. A threshold here would be a soft cap wearing a monitoring badge -- it would
-- re-impose through the back door the exact bound the owner deliberately removed, and it would repeat
-- KL#12 metric (b)'s original failure, where a number explicitly documented as "not an entry gate"
-- was nonetheless reasoned about as if it bounded risk. This view exists to MEASURE, so the experiment
-- can later ask whether concentrated theses actually paid, not to PROTECT. It restores no safety and
-- is not intended to: the -50% deployed-TWR drawdown kill remains the only quantitative backstop, and
-- it is a detector that fires after a loss is realised rather than a bound that caps it.
--
-- WHAT THE NUMBER MEANS, AND WHERE IT IS ONLY APPROXIMATE. Capital at Risk is instrument-dependent:
--   long equity  -- CaR = full notional. There is no stop-loss in this experiment, so the honest worst
--                   case is total loss and cost basis IS the CaR. EXACT here.
--   short equity -- CaR = notional x the short stop distance, and that stop distance is not carried in
--                   state.current_positions. Cost basis OVERSTATES the risk. APPROXIMATE.
--   options (C)  -- CaR = max_loss inclusive of the bounded early-assignment cascade, which is neither
--                   cost basis nor derivable here. APPROXIMATE.
-- The `basis_fidelity` column labels every row accordingly rather than silently mixing the three, so a
-- reader never mistakes an approximate share for a measured one. Do not "fix" this by inventing a stop
-- distance or a max_loss in SQL -- the correct source is the DECLARED per-thesis CaR that
-- thesis-construction and action-conversion now record as structured `fields` on their
-- events.decision_log rows (Claude_Task_Plan.md, same 2026-08-05 change). This view measures REALISED
-- concentration from the book; that field captures INTENDED risk budget. They are different questions
-- and both are worth having.
--
-- POINT-IN-TIME, NOT A SERIES. state.current_positions is a latest-state view, so this is concentration
-- as of now. A historical series is deliberately NOT built here: reconstructing per-day positions would
-- duplicate the engine, and the retrospective question ("did the big bets pay?") is better answered
-- from the declared-CaR field joined to realised outcomes than from a nightly snapshot of cost basis.
--
-- Defines ONE view and nothing else. No table, no procedure, no INSERT, no alert registration. Apply
-- after bigquery/01_schema.sql (state.current_positions) and bigquery/127_strategy_nav_dust_exclusion.sql
-- (analytics.strategy_nav, current definition). Re-apply safe (CREATE OR REPLACE).

CREATE OR REPLACE VIEW `stock-trading-498512.analytics.strategy_concentration` AS
WITH by_name AS (
  SELECT
    strategy,
    ticker,
    SUM(cost_basis) AS name_cost_basis,   -- summed across tranches: a multi-tranche name counts ONCE,
                                          -- the same aggregation the retired per-name envelope used
    MIN(shares)     AS min_shares         -- negative on any leg => a short is present in this strategy
  FROM `stock-trading-498512.state.current_positions`
  WHERE strategy IS NOT NULL
  GROUP BY strategy, ticker
),
ranked AS (
  SELECT
    strategy,
    ticker,
    name_cost_basis,
    min_shares,
    ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY name_cost_basis DESC, ticker) AS rn,
    SUM(name_cost_basis) OVER (PARTITION BY strategy) AS deployed_cost_basis,
    COUNT(*)             OVER (PARTITION BY strategy) AS n_names,
    MIN(min_shares)      OVER (PARTITION BY strategy) AS strategy_min_shares
  FROM by_name
)
SELECT
  r.strategy,
  CURRENT_DATE('America/Denver') AS as_of_date,
  r.n_names,
  r.ticker                              AS largest_name,
  ROUND(r.name_cost_basis, 2)           AS largest_name_cost_basis,
  ROUND(n.nav, 2)                       AS strategy_nav,
  -- THE metric: largest single name as a share of the strategy portfolio. No threshold attaches.
  ROUND(100 * SAFE_DIVIDE(r.name_cost_basis, n.nav), 2)      AS largest_name_share_pct,
  ROUND(100 * SAFE_DIVIDE(r.deployed_cost_basis, n.nav), 2)  AS deployed_share_pct,
  -- Herfindahl over names, on deployed capital: 1.0 = a single position IS the book, ~1/n = even.
  ROUND(
    (SELECT SUM(POW(SAFE_DIVIDE(b.name_cost_basis, r.deployed_cost_basis), 2))
     FROM by_name b WHERE b.strategy = r.strategy), 4)       AS name_hhi,
  CASE
    WHEN r.strategy = 'C'            THEN 'APPROXIMATE-OPTIONS: CaR is max_loss, not cost basis'
    WHEN r.strategy_min_shares < 0   THEN 'APPROXIMATE-SHORT-LEG: CaR is notional x stop distance for the short side'
    ELSE 'EXACT-LONG-EQUITY: no stop-loss, so cost basis IS Capital at Risk'
  END                                   AS basis_fidelity
FROM ranked r
JOIN `stock-trading-498512.analytics.strategy_nav` n USING (strategy)
WHERE r.rn = 1;

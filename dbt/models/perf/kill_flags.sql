-- Parallel-run dbt port of bigquery/39_beta_adjusted_alpha.sql:perf.kill_flags (rebuilt there, not
-- bigquery/03_twr_engine.sql, as of ITEM 10 2026-07-11) — canonical source is that file until owner cutover.
-- Kill-trigger flags off the LATEST row per strategy of perf.strategy_daily.
-- perf.strategy_daily is the procedure-maintained engine TABLE (ops.sp_recompute_engine),
-- so it is a SOURCE here, not a model — kill_flags ref()s nothing it can build, it source()s it.
--
-- MIN-SAMPLE FLOOR + INTERIM WARNING (2026-07-03, self-improvement audit strategy-risk findings
-- 4 & 5): runaway_review now requires deployed_days>=30 (a lucky first week is not a runaway-success
-- signal); interim_underperf_warning is a WARNING-ONLY early signal for long-horizon strategies
-- (deployed_days>=90 AND excess<=-15%) that does not feed all_green or any kill action.
--
-- BETA-ADJUSTED SUPPRESSION (ITEM 10, self-improvement audit 2026-07-11): m2m_underperf_review and
-- interim_underperf_warning are SGOV-relative only, which conflates market-beta exposure with
-- idiosyncratic stock-picking skill. Both now ALSO require `NOT min_n_met OR alpha_annualized <= 0` —
-- if beta is not yet measurable (min_n_met=FALSE, analytics.strategy_beta_latest), behavior is IDENTICAL
-- to before (fires on the SGOV condition alone); once beta is measurable, a confidently POSITIVE
-- SPY-alpha reading suppresses the review (underperformance fully explained by low/negative beta
-- exposure, not bad decisions). Never adds a NEW trigger the unmodified SGOV-only check would not have
-- fired. drawdown_kill / runaway_review / gate_reached are absolute-magnitude checks, untouched.

SELECT k.strategy, k.as_of_date, k.deployed_unit_value, k.peak_unit_value, k.current_drawdown,
       k.excess_vs_sgov, k.deployed_days, k.closed_trades, k.gate_n,
       k.current_drawdown <= -0.50                                                  AS drawdown_kill,        -- kill #1
       (k.deployed_unit_value >= 2 AND k.closed_trades < 30 AND k.deployed_days >= 30) AS runaway_review,     -- kill #3
       ((k.deployed_days >= 756 AND k.excess_vs_sgov <= -0.10)
        AND (NOT COALESCE(b.min_n_met, FALSE) OR COALESCE(b.alpha_annualized, 0) <= 0)) AS m2m_underperf_review, -- kill #4
       (k.closed_trades >= 30)                                                      AS gate_reached,         -- 30-trade gate
       ((k.deployed_days >= 90 AND k.excess_vs_sgov <= -0.15)
        AND (NOT COALESCE(b.min_n_met, FALSE) OR COALESCE(b.alpha_annualized, 0) <= 0)) AS interim_underperf_warning,
       b.beta_hat, b.alpha_annualized, COALESCE(b.min_n_met, FALSE) AS beta_min_n_met
FROM (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY as_of_date DESC) rn
  FROM {{ source('perf', 'strategy_daily') }}
) k
LEFT JOIN {{ source('analytics_external', 'strategy_beta_latest') }} b ON b.strategy = k.strategy
WHERE k.rn = 1

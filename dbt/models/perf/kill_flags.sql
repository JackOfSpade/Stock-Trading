-- Parallel-run dbt port of bigquery/03_twr_engine.sql:perf.kill_flags — canonical source is that file until owner cutover.
-- Kill-trigger flags off the LATEST row per strategy of perf.strategy_daily.
-- perf.strategy_daily is the procedure-maintained engine TABLE (ops.sp_recompute_engine),
-- so it is a SOURCE here, not a model — kill_flags ref()s nothing it can build, it source()s it.
--
-- MIN-SAMPLE FLOOR + INTERIM WARNING (2026-07-03, self-improvement audit strategy-risk findings
-- 4 & 5): runaway_review now requires deployed_days>=30 (a lucky first week is not a runaway-success
-- signal); interim_underperf_warning is a WARNING-ONLY early signal for long-horizon strategies
-- (deployed_days>=90 AND excess<=-15%) that does not feed all_green or any kill action.

SELECT strategy, as_of_date, deployed_unit_value, peak_unit_value, current_drawdown,
       excess_vs_sgov, deployed_days, closed_trades, gate_n,
       current_drawdown <= -0.50                                                AS drawdown_kill,        -- kill #1
       (deployed_unit_value >= 2 AND closed_trades < 30 AND deployed_days >= 30) AS runaway_review,       -- kill #3
       (deployed_days >= 756 AND excess_vs_sgov <= -0.10)                       AS m2m_underperf_review, -- kill #4
       (closed_trades >= 30)                                                    AS gate_reached,         -- 30-trade gate
       (deployed_days >= 90 AND excess_vs_sgov <= -0.15)                        AS interim_underperf_warning
FROM (
  SELECT *, ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY as_of_date DESC) rn
  FROM {{ source('perf', 'strategy_daily') }}
)
WHERE rn = 1

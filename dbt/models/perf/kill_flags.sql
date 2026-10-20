-- Parallel-run dbt port of bigquery/259_live_ramp.sql:perf.kill_flags — canonical source is that file until
-- owner cutover. Generated MECHANICALLY by scripts/gen_dbt_port.py from that canonical body — the
-- only edit is ref()/source() substitution for fully-qualified names — and proved token-identical
-- to it by scripts/verify_dbt_port.py. Do not hand-edit the BODY: re-generate, then re-verify.
-- Regenerating REPLACES this header, so any hand-written provenance above the body must be put
-- back by the person who regenerates it.
SELECT
  k.strategy, k.as_of_date, k.deployed_unit_value, k.peak_unit_value, k.current_drawdown,
  k.excess_vs_sgov, k.deployed_days, k.closed_trades, k.gate_n,
  k.current_drawdown <= -0.50                                                AS drawdown_kill,        -- kill #1
  (k.deployed_unit_value >= 2 AND k.closed_trades < 30 AND k.deployed_days >= 30) AS runaway_review,   -- kill #3
  ((k.deployed_days >= 756 AND k.excess_vs_sgov <= -0.10)
   AND (NOT COALESCE(b.min_n_met, FALSE) OR COALESCE(b.alpha_annualized, 0) <= 0)) AS m2m_underperf_review, -- kill #4, beta-adjusted (ITEM 10)
  (k.closed_trades >= 30)                                                    AS gate_reached,         -- historical: the retired 30-trade gate
  ((k.deployed_days >= 90 AND k.excess_vs_sgov <= -0.15)
   AND (NOT COALESCE(b.min_n_met, FALSE) OR COALESCE(b.alpha_annualized, 0) <= 0)) AS interim_underperf_warning, -- beta-adjusted (ITEM 10)
  COALESCE(sr.evidence_kill, FALSE)                                          AS evidence_kill,        -- rev 20: SPRT lower boundary on the declared edge
  b.beta_hat, b.alpha_annualized, COALESCE(b.min_n_met, FALSE) AS beta_min_n_met
FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY as_of_date DESC) rn
      FROM {{ source('perf', 'strategy_daily') }}) k
LEFT JOIN {{ source('analytics_external', 'strategy_beta_latest') }} b ON b.strategy = k.strategy
LEFT JOIN {{ ref('strategy_ramp') }} sr ON sr.strategy_code = k.strategy
WHERE k.rn = 1

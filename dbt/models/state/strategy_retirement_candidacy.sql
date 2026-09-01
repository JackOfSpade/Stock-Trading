-- Parallel-run dbt port of bigquery/81_arsenal_fixes.sql:state.strategy_retirement_candidacy — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH latest AS (
  -- newest deployed-perf row per strategy; has_perf_row is the LEFT-JOIN sentinel (survives USING, which
  -- only coalesces the join key) that distinguishes "never deployed" from "deployed with a NULL metric".
  SELECT strategy AS strategy_code, excess_vs_sgov, deployed_days, TRUE AS has_perf_row
  FROM {{ source('perf', 'strategy_daily') }}
  QUALIFY ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY as_of_date DESC) = 1
),
sustained AS (
  -- trailing 63 trading days per strategy; count of negative-excess days. NULL excess -> predicate FALSE
  -- (not counted); < 63 rows -> a smaller count. Both fail-conservative toward KEEP (H3 part 2).
  SELECT strategy AS strategy_code, COUNTIF(excess_vs_sgov < 0) AS neg_days_63
  FROM (
    SELECT strategy, excess_vs_sgov
    FROM {{ source('perf', 'strategy_daily') }}
    QUALIFY ROW_NUMBER() OVER (PARTITION BY strategy ORDER BY as_of_date DESC) <= 63
  )
  GROUP BY strategy
),
beta AS (
  -- fail-closed by construction: a strategy absent here (zero deployed days) has no row, and the
  -- COALESCE(min_n_met, FALSE) below treats a missing row as "beta not measurable" (verbatim from 39).
  SELECT strategy AS strategy_code, alpha_annualized, min_n_met
  FROM {{ source('analytics_external', 'strategy_beta_latest') }}
),
rails AS (SELECT * FROM {{ ref('arsenal_rails') }}),
-- defense-in-depth (rev 2026-07-10b, code-review finding #3): SL4 is blocked entirely at the shared
-- ops.sp_assert_arsenal_enabled gate when incubation_frozen=TRUE, but this view ALSO folds it in here,
-- matching its 3 siblings, so it stays internally safe even if ever queried without that gate first.
ars AS (SELECT enabled, incubation_frozen FROM {{ ref('arsenal_enabled') }})
SELECT
  r.strategy_code,
  l.excess_vs_sgov,
  l.deployed_days,
  COALESCE(s.neg_days_63, 0) AS neg_days_63,          -- trailing-63d negative-excess day count (H3 part 2)
  -- days since adopted_date for a strategy that has ZERO perf rows (never deployed live capital); NULL once
  -- it has been deployed. The objective "adopted but idle" signal SL4 previously had no surface for (H3 part 1).
  IF(COALESCE(l.has_perf_row, FALSE), NULL,
     DATE_DIFF(CURRENT_DATE('America/Denver'), r.adopted_date, DAY)) AS never_deployed_days,
  b.alpha_annualized,
  COALESCE(b.min_n_met, FALSE) AS beta_min_n_met,
  -- edge_decay_signal: latest-row condition AND sustained (>=42/63) negativity AND the beta-adjusted
  -- suppression (preserved from 39). COALESCE defaults make it FALSE (never NULL) when unmeasurable.
  (COALESCE(l.deployed_days, 0) >= 252
   AND COALESCE(l.excess_vs_sgov, 0) < 0
   AND COALESCE(s.neg_days_63, 0) >= 42
   AND (NOT COALESCE(b.min_n_met, FALSE) OR COALESCE(b.alpha_annualized, 0) <= 0)) AS edge_decay_signal,
  rails.active_count,
  rails.active_count > rails.n_min AS floor_ok,
  (ars.enabled AND NOT ars.incubation_frozen) AS arsenal_ok,
  NOT EXISTS (SELECT 1 FROM {{ source('ops', 'roster_change_log') }} cl
              WHERE cl.strategy_code = r.strategy_code
                AND cl.to_state = 'RETIREMENT_PROPOSED'
                AND cl.change_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 90 DAY)) AS cooldown_clear,
  (COALESCE(l.deployed_days, 0) >= 252
   AND COALESCE(l.excess_vs_sgov, 0) < 0
   AND COALESCE(s.neg_days_63, 0) >= 42
   AND (NOT COALESCE(b.min_n_met, FALSE) OR COALESCE(b.alpha_annualized, 0) <= 0)
   AND rails.active_count > rails.n_min
   AND ars.enabled AND NOT ars.incubation_frozen
   AND NOT EXISTS (SELECT 1 FROM {{ source('ops', 'roster_change_log') }} cl
                   WHERE cl.strategy_code = r.strategy_code
                     AND cl.to_state = 'RETIREMENT_PROPOSED'
                     AND cl.change_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 90 DAY))) AS candidacy_fired
FROM {{ source('state_external', 'strategy_roster') }} r
LEFT JOIN latest l USING (strategy_code)
LEFT JOIN sustained s USING (strategy_code)
LEFT JOIN beta b USING (strategy_code)
CROSS JOIN rails CROSS JOIN ars
WHERE r.current_state = 'ADOPTED'

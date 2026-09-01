-- Parallel-run dbt port of bigquery/72_constant_tuning_oos_watch.sql:state.exec_rule_oos_watch — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH last_change AS (
  SELECT change_key, rule_name, change_ts, old_value, new_value
  FROM {{ source('ops', 'exec_rule_change_log') }}
  WHERE NOT ENDS_WITH(change_key, ':REVERT') AND rule_name IS NOT NULL
  QUALIFY ROW_NUMBER() OVER (PARTITION BY rule_name ORDER BY change_ts DESC) = 1
),
pre AS (
  SELECT lc.rule_name, AVG(q.adverse_slippage_bps) AS avg_pre
  FROM last_change lc
  JOIN {{ ref('execution_quality') }} q
    ON q.fill_ts < lc.change_ts
  WHERE q.adverse_slippage_bps IS NOT NULL
  GROUP BY 1
),
post AS (
  SELECT lc.rule_name, COUNT(*) AS n_post, AVG(q.adverse_slippage_bps) AS avg_post
  FROM last_change lc
  JOIN {{ ref('execution_quality') }} q
    ON q.fill_ts >= lc.change_ts
  WHERE q.adverse_slippage_bps IS NOT NULL
  GROUP BY 1
)
SELECT lc.*, pre.avg_pre, post.n_post, post.avg_post,
  (COALESCE(post.n_post, 0) >= 8
   AND post.avg_post > COALESCE(pre.avg_pre, 0) + 10
   AND NOT EXISTS (SELECT 1 FROM {{ source('ops', 'exec_rule_change_log') }} r
                   WHERE r.change_key = CONCAT(lc.change_key, ':REVERT'))) AS degraded_revert
FROM last_change lc
LEFT JOIN pre ON pre.rule_name = lc.rule_name
LEFT JOIN post ON post.rule_name = lc.rule_name

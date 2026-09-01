-- Parallel-run dbt port of bigquery/72_constant_tuning_oos_watch.sql:state.process_constant_oos_watch — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH last_change AS (
  SELECT routine, deadline_key, change_key, change_ts, old_value, new_value
  FROM {{ source('ops', 'process_constant_change_log') }}
  WHERE NOT ENDS_WITH(change_key, ':REVERT') AND routine IS NOT NULL AND deadline_key IS NOT NULL
  QUALIFY ROW_NUMBER() OVER (PARTITION BY routine, deadline_key ORDER BY change_ts DESC) = 1
),
post AS (
  SELECT lc.routine, lc.deadline_key,
    COUNT(*) AS n_cycles, COUNTIF(o.threat_pattern) AS n_threat
  FROM last_change lc
  JOIN {{ source('ops', 'process_reliability_observations') }} o
    ON o.routine = lc.routine AND o.deadline_key = lc.deadline_key
   AND TIMESTAMP(o.cycle_date) > lc.change_ts
  GROUP BY 1, 2
)
SELECT lc.*,
  COALESCE(p.n_cycles, 0) AS n_post_cycles,
  COALESCE(p.n_threat, 0) AS n_post_threat,
  (COALESCE(p.n_cycles, 0) >= 3 AND COALESCE(p.n_threat, 0) >= 2
   AND NOT EXISTS (SELECT 1 FROM {{ source('ops', 'process_constant_change_log') }} r
                   WHERE r.change_key = CONCAT(lc.change_key, ':REVERT'))) AS degraded_revert
FROM last_change lc
LEFT JOIN post p ON p.routine = lc.routine AND p.deadline_key = lc.deadline_key

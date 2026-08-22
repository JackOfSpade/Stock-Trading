-- Parallel-run dbt port of bigquery/37_self_improvement_autonomy.sql:state.process_reliability_readiness — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
WITH ranked AS (
  SELECT routine, deadline_key, cycle_date, threat_pattern,
    ROW_NUMBER() OVER (PARTITION BY routine, deadline_key ORDER BY cycle_date DESC) AS rn
  FROM {{ source('ops', 'process_reliability_observations') }}
  WHERE deadline_key IS NOT NULL
),
trailing3 AS (
  SELECT routine, deadline_key,
    COUNT(*) AS n_recent_cycles,
    COUNTIF(threat_pattern) AS n_recent_threat
  FROM ranked WHERE rn <= 3
  GROUP BY routine, deadline_key
)
SELECT
  t.routine,
  t.deadline_key,
  t.n_recent_cycles,
  t.n_recent_threat,
  (t.n_recent_cycles >= 3 AND t.n_recent_threat = 3) AS threat_streak_met,
  NOT EXISTS (SELECT 1 FROM {{ source('ops', 'process_constant_change_log') }} cl
              WHERE cl.routine = t.routine AND cl.deadline_key = t.deadline_key) AS not_already_changed,
  (t.n_recent_cycles >= 3 AND t.n_recent_threat = 3
   AND NOT EXISTS (SELECT 1 FROM {{ source('ops', 'process_constant_change_log') }} cl
                   WHERE cl.routine = t.routine AND cl.deadline_key = t.deadline_key)) AS ready_for_change
FROM trailing3 t

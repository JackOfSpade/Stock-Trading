-- Parallel-run dbt port of bigquery/184_inflight_guard_hosted_runs.sql:state.catchup_available — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
WITH catchup_safe_routines AS (
  SELECT routine FROM UNNEST(['D1', 'D3', 'OPS1', 'SL3']) AS routine
),
in_flight AS (
  -- Latest ops.run_log row per (routine, run_date); "in flight" iff that latest row is a fresh
  -- 'started' (log_ts within the last 3h). DISTINCT routine because the consumer joins on routine
  -- alone now — see this file's header.
  SELECT DISTINCT routine
  FROM (
    SELECT routine, run_date, status, log_ts,
      ROW_NUMBER() OVER (PARTITION BY routine, run_date ORDER BY log_ts DESC) AS rn
    FROM {{ source('ops', 'run_log') }}
  )
  WHERE rn = 1
    AND status = 'started'
    AND log_ts >= TIMESTAMP_SUB(CURRENT_TIMESTAMP(), INTERVAL 3 HOUR)
)
SELECT w.routine, w.schedule, w.today
FROM {{ ref('cadence_watch') }} w
JOIN catchup_safe_routines s USING (routine)
LEFT JOIN in_flight f ON f.routine = w.routine
WHERE w.needs_attention
  AND f.routine IS NULL

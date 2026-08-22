-- Parallel-run dbt port of bigquery/57_append_only_integrity_promotion.sql:state.append_only_integrity_promotion_readiness — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
WITH by_day AS (
  -- Dedupe to ONE row per check_date before ranking (same defensive rationale as
  -- state.ddl_drift_promotion_readiness — a day counts clean only if EVERY logged row that day was
  -- clean, so a same-day duplicate can never promote a day early).
  SELECT check_date, LOGICAL_AND(clean) AS clean
  FROM {{ source('ops', 'monitor_health_history') }}
  WHERE check_id = 'append_only_integrity'
  GROUP BY check_date
),
ranked AS (
  SELECT check_date, clean,
    ROW_NUMBER() OVER (ORDER BY check_date DESC) AS rn
  FROM by_day
),
trailing14 AS (
  SELECT COUNT(*) AS n_recent, COUNTIF(clean) AS n_recent_clean
  FROM ranked WHERE rn <= 14
)
SELECT
  t.n_recent, t.n_recent_clean,
  (t.n_recent >= 14 AND t.n_recent_clean = 14) AS baseline_met,
  NOT EXISTS (SELECT 1 FROM {{ source('ops', 'monitor_promotion_log') }} pl WHERE pl.check_id = 'append_only_integrity') AS not_already_promoted,
  (t.n_recent >= 14 AND t.n_recent_clean = 14
   AND NOT EXISTS (SELECT 1 FROM {{ source('ops', 'monitor_promotion_log') }} pl WHERE pl.check_id = 'append_only_integrity')) AS ready
FROM trailing14 t

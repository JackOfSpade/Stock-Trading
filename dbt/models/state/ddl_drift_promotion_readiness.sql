-- Parallel-run dbt port of bigquery/45_monitor_promotion.sql:state.ddl_drift_promotion_readiness — canonical source is that
-- file until owner cutover. Added 2026-08-22 (dbt view-coverage burn-down): this view had
-- NO dbt presence at all, so scripts/dbt_parity.py had nothing to compare and it carried
-- ZERO row-level parity protection. Ported MECHANICALLY from the canonical body — the only
-- edit is ref()/source() substitution for the fully-qualified table names.
WITH by_day AS (
  -- BUG FIX (rev 2026-07-11, adversarial self-audit): dedupe to ONE row per check_date BEFORE ranking.
  -- cadence_check.sql now upserts (MERGE) so a same-day re-run should never create a second row for one
  -- day going forward, but this view defends independently against any duplicate already in the table
  -- (or any future write path that regresses to a plain INSERT) -- ranking raw, non-deduplicated ROWS
  -- would let a trailing-14-ROW window span FEWER than 14 actual distinct calendar days, promoting a day
  -- or more early than the "14 consecutive DISTINCT logged days" bar this view's own header states.
  -- Fail-closed on the (should-be-impossible-post-upsert) same-day-multi-row case: a day counts clean
  -- only if EVERY logged row that day was clean.
  SELECT check_date, LOGICAL_AND(clean) AS clean
  FROM {{ source('ops', 'monitor_health_history') }}
  WHERE check_id = 'ddl_drift'
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
  NOT EXISTS (SELECT 1 FROM {{ source('ops', 'monitor_promotion_log') }} pl WHERE pl.check_id = 'ddl_drift') AS not_already_promoted,
  (t.n_recent >= 14 AND t.n_recent_clean = 14
   AND NOT EXISTS (SELECT 1 FROM {{ source('ops', 'monitor_promotion_log') }} pl WHERE pl.check_id = 'ddl_drift')) AS ready
FROM trailing14 t

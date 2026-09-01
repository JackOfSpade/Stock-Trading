-- Parallel-run dbt port of bigquery/122_decision_correction_append_only.sql:state.add_candidate_reviews — canonical source is that file until
-- owner cutover. Added 2026-09-01 (dbt view-coverage burn-down): this view had NO dbt presence,
-- so scripts/check_dbt_view_coverage.py reported it uncovered and it carried no port at all.
-- Generated MECHANICALLY by scripts/gen_dbt_port.py from the canonical body — the only edit is
-- ref()/source() substitution for fully-qualified names — and proved token-identical to that body
-- by scripts/verify_dbt_port.py. Do not hand-edit: re-generate, then re-verify.
WITH reviews AS (
  SELECT
    entry_id,
    entry_date,
    event_ts,
    body_md                                                              AS process_note,
    source_session,
    SAFE_CAST(JSON_VALUE(fields, '$.n_evaluated') AS INT64)              AS n_evaluated,
    SAFE_CAST(JSON_VALUE(fields, '$.n_flagged') AS INT64)                AS n_flagged,
    SAFE_CAST(JSON_VALUE(fields, '$.n_declined_hard_gate') AS INT64)     AS n_declined_hard_gate,
    JSON_QUERY_ARRAY(fields, '$.positions')                              AS positions
  FROM {{ source('events', 'decision_log') }}
  WHERE entry_type = 'add-candidate-review'
    AND entry_id NOT IN (
      SELECT superseded_by
      FROM {{ source('events', 'decision_log') }}
      WHERE superseded_by IS NOT NULL
    )
)
SELECT
  r.entry_id, r.entry_date, r.event_ts, r.source_session,
  r.n_evaluated, r.n_flagged, r.n_declined_hard_gate, r.process_note,
  JSON_VALUE(pos, '$.ticker')                                      AS ticker,
  JSON_VALUE(pos, '$.strategy')                                    AS strategy,
  SAFE_CAST(JSON_VALUE(pos, '$.mark_vs_cost_pct') AS NUMERIC)      AS mark_vs_cost_pct,
  JSON_VALUE(pos, '$.trigger_type')                                AS trigger_type,
  JSON_VALUE(pos, '$.disposition')                                 AS disposition,
  JSON_VALUE(pos, '$.reason')                                      AS reason,
  SAFE_CAST(JSON_VALUE(pos, '$.invalidation_status_null') AS BOOL) AS invalidation_status_null,
  SAFE_CAST(JSON_VALUE(pos, '$.invalidation_criteria_evaluable') AS BOOL)
    AS invalidation_criteria_evaluable
FROM reviews r, UNNEST(r.positions) AS pos

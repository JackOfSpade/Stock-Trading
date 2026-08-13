-- Parallel-run dbt port of the final effective state.current_positions definition.
-- Lifecycle state is latest-wins, while invalidation criteria and the LTCG anchor carry forward from
-- the latest populated row. Raw omissions remain visible in events.position_events and are still
-- caught by assert_no_invalidation_status_regression; they can no longer erase live risk state.

WITH enriched AS (
  SELECT
    p.*,
    LAST_VALUE(ltcg_date IGNORE NULLS) OVER w AS carried_ltcg_date,
    LAST_VALUE(
      CASE
        WHEN invalidation_status IS NULL OR TO_JSON_STRING(invalidation_status) = 'null' THEN NULL
        ELSE invalidation_status
      END IGNORE NULLS
    ) OVER w AS carried_invalidation_status,
    ROW_NUMBER() OVER (PARTITION BY position_key ORDER BY event_ts DESC, event_id DESC) AS rn
  FROM {{ source('events', 'position_events') }} p
  WINDOW w AS (
    PARTITION BY position_key
    ORDER BY event_ts, event_id
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  )
)
SELECT
  event_id, event_ts, position_key, event_type, status, strategy, ticker, contract_id,
  cost_basis, shares,
  convergence_target,
  time_exit_date,
  carried_ltcg_date AS ltcg_date,
  carried_invalidation_status AS invalidation_status,
  conviction,
  model_at_entry,
  source_thesis_ref,
  note
FROM enriched
WHERE rn = 1 AND event_type <> 'CLOSE'

-- Singular test (passes on zero rows): current_positions must expose the latest populated invalidation
-- criteria and LTCG anchor for every open key, even when its latest raw lifecycle event is sparse.

WITH expected AS (
  SELECT
    position_key,
    ARRAY_AGG(ltcg_date IGNORE NULLS ORDER BY event_ts DESC, event_id DESC LIMIT 1)[SAFE_OFFSET(0)] AS ltcg_date,
    ARRAY_AGG(
      CASE
        WHEN invalidation_status IS NULL OR TO_JSON_STRING(invalidation_status) = 'null' THEN NULL
        ELSE invalidation_status
      END IGNORE NULLS
      ORDER BY event_ts DESC, event_id DESC LIMIT 1
    )[SAFE_OFFSET(0)] AS invalidation_status
  FROM {{ source('events', 'position_events') }}
  GROUP BY position_key
)
SELECT cp.position_key
FROM {{ ref('current_positions') }} cp
JOIN expected e USING (position_key)
WHERE cp.ltcg_date IS DISTINCT FROM e.ltcg_date
   OR TO_JSON_STRING(cp.invalidation_status) IS DISTINCT FROM TO_JSON_STRING(e.invalidation_status)

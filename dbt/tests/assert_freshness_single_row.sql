-- Singular test (passes when ZERO rows): state.freshness must return EXACTLY ONE row.
--
-- Rationale (bigquery/10_observability.sql): freshness is the dead-man's-switch input and feeds
-- the single-row system_health rollup via a CROSS JOIN. If freshness produced 0 or >1 rows the
-- rollup would silently mis-fire. Assert exactly one row.

SELECT COUNT(*) AS n
FROM {{ ref('freshness') }}
HAVING COUNT(*) <> 1

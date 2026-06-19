-- Singular test (passes when ZERO rows): state.system_health must return EXACTLY ONE row.
--
-- Rationale (bigquery/10_observability.sql): system_health is consumed as a one-row green/red
-- rollup (the dead-man's-switch reads its `all_green` flag). A CROSS JOIN of freshness x
-- embedding_health that ever fans out to 0 or >1 rows would make `IF NOT all_green` ambiguous or
-- skip the alert entirely — silent failure of the control plane. Assert the row count is 1.

SELECT COUNT(*) AS n
FROM {{ ref('system_health') }}
HAVING COUNT(*) <> 1

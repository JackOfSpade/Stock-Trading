-- Singular test (passes when ZERO rows): analytics.account_reconciliation must return EXACTLY ONE row.
--
-- Rationale (bigquery/04_analytics.sql): this is the account-level §13 events-side total that D2
-- Step 0 diffs against the connector. It is a scalar rollup (one row of SELECT-subquery aggregates);
-- D2 reads it as a single record. >1 row (or 0) would break the reconciliation comparison.

SELECT COUNT(*) AS n
FROM {{ ref('account_reconciliation') }}
HAVING COUNT(*) <> 1

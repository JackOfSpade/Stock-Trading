-- Parallel-run dbt port of bigquery/14_weekly_report.sql:state.account_latest — canonical source is that file until owner cutover.
-- Latest account-level NAV/cash/TWR snapshot. ops.account_snapshot is written daily by D2 Step 0b
-- from the IBKR connector (procedure/agent-maintained table — modeled as a SOURCE, like run_log).
SELECT *
FROM {{ source('ops', 'account_snapshot') }}
QUALIFY ROW_NUMBER() OVER (ORDER BY snapshot_date DESC, ingest_ts DESC) = 1

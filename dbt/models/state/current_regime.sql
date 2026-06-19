-- Parallel-run dbt port of bigquery/01_schema.sql:state.current_regime — canonical source is that file until owner cutover.
-- Latest reading per (scope, key). regime_events.as_of_date IS the observation date,
-- so a newer as_of_date is a newer reading -> ORDER BY as_of_date DESC, event_ts DESC.

SELECT *
FROM {{ source('events', 'regime_events') }}
QUALIFY ROW_NUMBER() OVER (PARTITION BY scope, key ORDER BY as_of_date DESC, event_ts DESC) = 1

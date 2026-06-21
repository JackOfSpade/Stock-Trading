-- Parallel-run dbt port of bigquery/01_schema.sql:state.current_regime — canonical source is that file until owner cutover.
-- Latest reading per (scope, key). regime_events.as_of_date IS the observation date,
-- so a newer as_of_date is a newer reading -> ORDER BY as_of_date DESC, event_ts DESC.
-- event_id DESC is a deterministic tiebreaker for rows that share (as_of_date, event_ts) within a
-- (scope, key) — without it ROW_NUMBER resolves the tie arbitrarily (nondeterministic regime).

SELECT *
FROM {{ source('events', 'regime_events') }}
QUALIFY ROW_NUMBER() OVER (PARTITION BY scope, key ORDER BY as_of_date DESC, event_ts DESC, event_id DESC) = 1

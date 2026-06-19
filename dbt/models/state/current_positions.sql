-- Parallel-run dbt port of bigquery/01_schema.sql:state.current_positions — canonical source is that file until owner cutover.
-- Latest event per position_key (position_events.event_ts is set explicitly by the
-- parser, so event_ts DESC alone is correct), excluding positions whose latest event is CLOSE.

SELECT * FROM (
  SELECT *
  FROM {{ source('events', 'position_events') }}
  QUALIFY ROW_NUMBER() OVER (PARTITION BY position_key ORDER BY event_ts DESC) = 1
)
WHERE event_type <> 'CLOSE'

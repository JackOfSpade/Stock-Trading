-- Parallel-run dbt port of bigquery/01_schema.sql:state.open_queue_detail — canonical source is that file until owner cutover.
-- Full latest-wins projection per (queue, item_key) INCLUDING the bulky payload JSON + note.
--
-- TRAP (documented in 01_schema.sql): order latest-wins by event_ts (the INSERT-time
-- transition order), NOT due_date. due_date is a TARGET date; ordering by it lets an
-- older 'created' event outrank a later 'complete'/'superseded' event, leaving a closed
-- item in the open queue forever.
--
-- Case-normalized terminal-status filter: the status column has drifted case before
-- ('complete' vs 'COMPLETE'); a mixed-case terminal row past a case-sensitive list would
-- keep a closed item open forever. 'filled'/'expired'/'abandoned' are the ORDER_STAGED
-- terminal statuses (staged-order registry; state.open_orders).

SELECT * FROM (
  SELECT *
  FROM {{ source('events', 'queue_events') }}
  QUALIFY ROW_NUMBER() OVER (
    PARTITION BY queue, item_key
    ORDER BY event_ts DESC
  ) = 1
)
WHERE UPPER(status) NOT IN ('COMPLETE','SUPERSEDED','DROPPED',
                            'FILLED','EXPIRED','ABANDONED')

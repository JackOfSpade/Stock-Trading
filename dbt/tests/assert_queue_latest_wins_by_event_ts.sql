-- Singular test (passes when ZERO rows): the open_queue latest-wins ordering must use event_ts,
-- NOT due_date.
--
-- Rationale (bigquery/01_schema.sql, the long ordering note): due_date is a TARGET date, not a
-- transition time. If the projection ordered by due_date, an older 'created' event could outrank a
-- later 'complete'/'superseded' event (which often carries a NULL or earlier due_date), leaving a
-- CLOSED item in the open queue forever. This test catches that regression directly: an item_key
-- must NOT appear in state.open_queue if a STRICTLY-LATER event_ts row for that (queue, item_key)
-- carries a terminal status. (If ordering ever reverts to due_date, the terminal row would be hidden
-- behind a non-terminal one with a later due_date and the open item would survive -> this fires.)

WITH terminal_later AS (
  SELECT q.queue, q.item_key
  FROM {{ ref('open_queue') }} oq
  JOIN {{ source('events', 'queue_events') }} q
    ON q.queue = oq.queue AND q.item_key = oq.item_key
  WHERE q.event_ts > oq.event_ts
    AND UPPER(q.status) IN ('COMPLETE','SUPERSEDED','DROPPED','FILLED','EXPIRED','ABANDONED')
)
SELECT DISTINCT queue, item_key
FROM terminal_later

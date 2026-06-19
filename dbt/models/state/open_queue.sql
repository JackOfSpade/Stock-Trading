-- Parallel-run dbt port of bigquery/01_schema.sql:state.open_queue — canonical source is that file until owner cutover.
-- Routing/identity scalar columns ONLY (no payload, no note) so `SELECT *` stays compact
-- and tabular no matter how verbose an item is. has_note/has_payload flag where the prose
-- lives. This is what the drain routines (D2/D3) and state.daily_briefing read.

SELECT
  event_id, event_ts, queue, item_key, item_type, status, strategy, ticker,
  due_date, conservative_default, artifact_path,
  note IS NOT NULL AS has_note,
  payload IS NOT NULL AS has_payload
FROM {{ ref('open_queue_detail') }}

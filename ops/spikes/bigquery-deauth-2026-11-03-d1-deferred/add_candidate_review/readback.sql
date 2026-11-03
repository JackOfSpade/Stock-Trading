SELECT entry_id, event_ts, entry_type, superseded_by, BYTE_LENGTH(body_md) AS body_bytes,
  BYTE_LENGTH(TO_JSON_STRING(fields)) AS fields_bytes
FROM `stock-trading-498512.events.decision_log`
WHERE entry_date = DATE '2026-11-03'
  AND 'sha256:7197395b5762aef4249a9fe2db9b0b7dee8ac237678501cb77348d0af423c586' IN UNNEST(tags)
ORDER BY event_ts;

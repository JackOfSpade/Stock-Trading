SELECT entry_id, event_ts, entry_type, superseded_by, BYTE_LENGTH(body_md) AS body_bytes,
  BYTE_LENGTH(TO_JSON_STRING(fields)) AS fields_bytes
FROM `stock-trading-498512.events.decision_log`
WHERE entry_date = DATE '2026-11-08'
  AND 'sha256:75e5d8d25e1a8014f76da3c44d1efc1b1bd17712d71f523e7d2a34f3907c5111' IN UNNEST(tags)
ORDER BY event_ts;

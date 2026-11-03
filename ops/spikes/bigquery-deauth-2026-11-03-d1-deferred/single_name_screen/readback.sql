SELECT entry_id, event_ts, entry_type, superseded_by, BYTE_LENGTH(body_md) AS body_bytes,
  BYTE_LENGTH(TO_JSON_STRING(fields)) AS fields_bytes
FROM `stock-trading-498512.events.decision_log`
WHERE entry_date = DATE '2026-11-03'
  AND 'sha256:30cceaa8189ccce4db1acd50dcc4000e7cadac18e15a5e7c9c3361061057b2ce' IN UNNEST(tags)
ORDER BY event_ts;

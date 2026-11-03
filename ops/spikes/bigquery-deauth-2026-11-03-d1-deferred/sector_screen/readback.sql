SELECT entry_id, event_ts, entry_type, superseded_by, BYTE_LENGTH(body_md) AS body_bytes,
  BYTE_LENGTH(TO_JSON_STRING(fields)) AS fields_bytes
FROM `stock-trading-498512.events.decision_log`
WHERE entry_date = DATE '2026-11-03'
  AND 'sha256:dbbd4698e19e44e40274c5a91592f3b2ab5806e07bcd2198996d304bf83bbecc' IN UNNEST(tags)
ORDER BY event_ts;

SELECT entry_id, event_ts, entry_type, superseded_by, BYTE_LENGTH(body_md) AS body_bytes,
  BYTE_LENGTH(TO_JSON_STRING(fields)) AS fields_bytes
FROM `stock-trading-498512.events.decision_log`
WHERE entry_date = DATE '2026-11-04'
  AND 'sha256:bbd7c6280f688c7f0b6fabc4d94c391aee8d628ad124b1416e48061c92ea55ca' IN UNNEST(tags)
ORDER BY event_ts;

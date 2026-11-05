SELECT entry_id, event_ts, entry_type, superseded_by, BYTE_LENGTH(body_md) AS body_bytes,
  BYTE_LENGTH(TO_JSON_STRING(fields)) AS fields_bytes
FROM `stock-trading-498512.events.decision_log`
WHERE entry_date = DATE '2026-11-05'
  AND 'sha256:cb7a075850ab0925e780fdeece52c2f976f711dade4cc32943e90c1606800127' IN UNNEST(tags)
ORDER BY event_ts;

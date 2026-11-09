CALL `stock-trading-498512.ops.sp_log_decision_staged`(
  DATE '2026-11-08',  -- in_entry_date
  'research-screen',  -- in_entry_type
  CAST(NULL AS STRING),  -- in_strategy
  CAST(NULL AS STRING),  -- in_ticker
  CAST(NULL AS STRING),  -- in_decision
  CAST(NULL AS STRING),  -- in_conviction
  CAST(NULL AS NUMERIC),  -- in_conviction_pct
  CAST(NULL AS STRING),  -- in_sub_pattern
  CAST(NULL AS STRING),  -- in_theater_check
  'Single-name move screen 2026-11-06 (router-gated): 63 passed, index-only while B is gated',  -- in_title
  'Router-gated single-name move screen for session 2026-11-06 (prior 2026-11-05), written by D1 2026-11-08 hosted inline by OPS2. 1971 names measured on Nasdaq discovery closes, 279 at >=5%. 67 carried an own-event EDGAR filing in the reaction window and were measured on IBKR daily bars: 63 passed (>=5% on IBKR), 4 dropped below 5% on IBKR, 0 unmeasured. Compact rejections: ANCHOR_UNRESOLVED 89, DAY'
  '2_EVENT_PRIOR 125, POST_MOVE_EVENT 2. B reads DO-NOT-ACTIVATE (held pending div-B-202611-2), so passes go to the new-entry index only; no thesis handoff. No metered call.',  -- in_body_md
  CAST(NULL AS STRING),  -- in_fields
  CAST([] AS ARRAY<STRING>),  -- in_refs
  CAST(['D1', 'research-screen', 'router-gated', 'OPS2-hosted'] AS ARRAY<STRING>),  -- in_tags
  CAST(NULL AS STRING),  -- in_superseded_by
  'D1 2026-11-08',  -- in_source_session
  CAST(['fields'] AS ARRAY<STRING>),  -- in_staged_args
  '75e5d8d25e1a8014f76da3c44d1efc1b1bd17712d71f523e7d2a34f3907c5111'  -- in_expected_sha256
);

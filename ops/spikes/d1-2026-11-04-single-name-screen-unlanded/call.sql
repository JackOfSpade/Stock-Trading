CALL `stock-trading-498512.ops.sp_log_decision_staged`(
  DATE '2026-11-04',  -- in_entry_date
  'research-screen',  -- in_entry_type
  CAST(NULL AS STRING),  -- in_strategy
  CAST(NULL AS STRING),  -- in_ticker
  CAST(NULL AS STRING),  -- in_decision
  CAST(NULL AS STRING),  -- in_conviction
  CAST(NULL AS NUMERIC),  -- in_conviction_pct
  CAST(NULL AS STRING),  -- in_sub_pattern
  CAST(NULL AS STRING),  -- in_theater_check
  'Single-name move screen 2026-11-04 (router-gated): 93 passed, index-only while B is gated',  -- in_title
  'D1 2026-11-04 single-name move screen, ROUTER-GATED MODE (Strategy B DO-NOT-ACTIVATE). Population: US-listed common stocks with market cap >= $2B and |close-to-close| >= 5% on 2026-11-04 against 2026-11-03. Discovery from key-less Nasdaq closes measured 2009 names; 666 cleared 5% on that basis on a broad rally day (discovery median +2.3%). Event identity from the key-less Nasdaq earnings calendar '
  'and one scripted EDGAR submissions batch only; no metered call. 93 names with a stamped own-event release in the reaction window were confirmed >= 5% on IBKR regular-session bars and pass (index-only watchlist adds while B is gated). 10 near-floor names fell below 5% on IBKR and were dropped. 574 rejected names are carried in rejected_compact by code with discovery-basis closes. No deal-pinned tar'
  'get. Close-chain: 2 forward-chain hits (DUOL, NVTS) against the unlanded 2026-11-03 row, both legitimate after-close anchors.',  -- in_body_md
  CAST(NULL AS STRING),  -- in_fields
  CAST([] AS ARRAY<STRING>),  -- in_refs
  CAST(['D1', 'research-screen', 'router-gated'] AS ARRAY<STRING>),  -- in_tags
  CAST(NULL AS STRING),  -- in_superseded_by
  'D1 2026-11-04',  -- in_source_session
  CAST(['fields'] AS ARRAY<STRING>),  -- in_staged_args
  'bbd7c6280f688c7f0b6fabc4d94c391aee8d628ad124b1416e48061c92ea55ca'  -- in_expected_sha256
);

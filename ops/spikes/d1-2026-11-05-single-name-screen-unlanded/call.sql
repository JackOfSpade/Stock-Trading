CALL `stock-trading-498512.ops.sp_log_decision_staged`(
  DATE '2026-11-05',  -- in_entry_date
  'research-screen',  -- in_entry_type
  CAST(NULL AS STRING),  -- in_strategy
  CAST(NULL AS STRING),  -- in_ticker
  CAST(NULL AS STRING),  -- in_decision
  CAST(NULL AS STRING),  -- in_conviction
  CAST(NULL AS NUMERIC),  -- in_conviction_pct
  CAST(NULL AS STRING),  -- in_sub_pattern
  CAST(NULL AS STRING),  -- in_theater_check
  'Single-name move screen 2026-11-05 (router-gated): 138 passed, index-only while B is gated',  -- in_title
  'D1 2026-11-05 single-name move screen, ROUTER-GATED MODE (Strategy B DO-NOT-ACTIVATE). Population: US-listed common stocks (incl. ADSs/LP units) with market cap >= $2B and |close-to-close| >= 5% on 2026-11-05 against 2026-11-04. Discovery: key-less Nasdaq screener + per-symbol quote/info closes dated Nov 5 measured 1993 names; 591 cleared 5% on that basis on a broad DOWN day (discovery median -2.7'
  '%). Event identity from the Nasdaq earnings calendar (schedule only) and one scripted EDGAR submissions batch; no metered call.\u000a\u000aIBKR confirmation (figure of record) is complete for every reaction-window name with an explaining own-event filing: 140 names were measured on regular-session daily bars (88 in the first pass, the remaining 52 in a paced second pass) and 138 pass (>= 5% with a'
  ' stamped own-event filing in the reaction window); 2 measured below 5% on IBKR (CMI -4.93%, JOBY +4.95%). Other rejected names (452 compact tuples): ANCHOR_UNRESOLVED 196, DAY2_EVENT_PRIOR 214, POST_MOVE_EVENT 42. Compact closes are Nasdaq discovery closes.\u000a\u000aFiling text was read for all non-2.02 window filings: non-explaining ones (buy-backs, dividends, notes offerings, presentations, mo'
  'nthly metrics, a completed earlier deal, ADS redomiciliation artifact CDLR) went to ANCHOR_UNRESOLVED. No deal-pinned target found.\u000a\u000aClose-chain: 22 forward-chain hits against the landed 2026-11-04 row, all names coded POST_MOVE_EVENT there (filing after the 11-04 close) that now pass with an after-close 2026-11-04 anchor; legitimate, recorded in each reason. Degraded legs are in fields.'
  'degraded_legs.\u000a',  -- in_body_md
  CAST(NULL AS STRING),  -- in_fields
  CAST([] AS ARRAY<STRING>),  -- in_refs
  CAST(['D1', 'research-screen', 'router-gated'] AS ARRAY<STRING>),  -- in_tags
  CAST(NULL AS STRING),  -- in_superseded_by
  'D1 2026-11-05',  -- in_source_session
  CAST(['fields'] AS ARRAY<STRING>),  -- in_staged_args
  'cb7a075850ab0925e780fdeece52c2f976f711dade4cc32943e90c1606800127'  -- in_expected_sha256
);

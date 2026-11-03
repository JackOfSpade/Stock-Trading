CALL `stock-trading-498512.ops.sp_log_decision_checked`(
  DATE '2026-11-03',  -- in_entry_date
  'research-screen',  -- in_entry_type
  CAST(NULL AS STRING),  -- in_strategy
  CAST(NULL AS STRING),  -- in_ticker
  CAST(NULL AS STRING),  -- in_decision
  CAST(NULL AS STRING),  -- in_conviction
  CAST(NULL AS NUMERIC),  -- in_conviction_pct
  CAST(NULL AS STRING),  -- in_sub_pattern
  CAST(NULL AS STRING),  -- in_theater_check
  'D1 sector-move screen 2026-11-03: XLP, XLB, XLK surfaced',  -- in_title
  'Session 2026-11-03 vs 2026-11-02, IBKR regular-session daily closes. 4 of 11 sector ETFs cleared the 1% rail; 3 are written up.\u000a\u000aTable (prior -> event, %): XLK 174.22 -> 176.51 +1.31; XLC 100.26 -> 101.44 +1.18; XLI 169.71 -> 171.32 +0.95; XLRE 43.64 -> 43.67 +0.07; XLV 184.60 -> 184.02 -0.31; XLU 43.67 -> 43.42 -0.57; XLF 57.56 -> 57.19 -0.64; XLY 118.16 -> 117.33 -0.70; XLE 67.25 -> 66'
  '.68 -0.85; XLB 53.67 -> 52.59 -2.01; XLP 90.83 -> 88.95 -2.07.\u000a\u000aWritten up: XLP -2.07% and XLB -2.01% (both clear the old 2% bar) reversed Monday\'s defensive/cyclical rotation gains as chipmakers rebounded; XLK +1.31% is the dip-buy in semis (SMH +2.01%) after a three-session liquidation. XLC +1.18% rejected as the same Big Tech rebound.\u000a\u000aBrent (BZUSD, provisional same-evening'
  ' read) 104.36 on 2026-11-03, vs 104.77 on 2026-11-02 in the same series (-0.39%); XLE -0.85%. Degraded: BigQuery down, so nothing is written to BigQuery by this run; see fields.degraded_legs.',  -- in_body_md
  '{"routine":"D1","screen":"sector-move","population_rail":"any GICS sector ETF close-to-close move >=1% (11 SPDR sector ETFs, IBKR regular-session daily bars) or notable intraday dispersion","legacy_rule":"sector ETF move >=2% (old record-only bar)","selection_rule":"All 11 SPDR sector ETFs measured on IBKR ONE_DAY regular-session bars (outside_rth=false) at the registry contract ids; Layer-2 AI-si'
  'gnificance judgment in regime context applied to the 4 that cleared the 1% rail; drivers from one Tavily market-wrap search (max_results 12) plus Reuters/Benzinga/MarketWatch snippets.","rail_tally":4,"universe_measured":11,"surfaced_count":3,"agreement":{"both":2,"ai_only":1,"rule_only":0},"passed":[{"name":"XLP","metric_pct":-2.0698,"prior_close":90.83,"event_close":88.95,"conviction_pct":60,"re'
  'ason":"Staples reversed Monday\'s +1.58% with the day\'s worst sector move (-2.07%, ~1.76% on the S&P index per Reuters) as money rotated from defensives back into chipmakers; Benzinga midday attributed part of it to Sysco\'s weak sales outlook. Notable because staples had been the leading defensive trade (52-week highs) in the post-Friday rotation, so the rotation paused rather than extended.","b'
  'elow_spec_floor":false,"legacy_rule_pass":true},{"name":"XLB","metric_pct":-2.0123,"prior_close":53.67,"event_close":52.59,"conviction_pct":60,"reason":"Materials fell -2.01% (-1.75% on the S&P index per Reuters) as industrial metals retreated (copper futures -2.6% to about $6.40/lb per Benzinga midday) after Monday\'s +1.76% gain on 1.74x volume; the cyclical-reflation leg of the rotation gave ba'
  'ck its gain. Oil was flat-to-lower (Brent 104.36 vs 104.77), so this is a metals move, not an oil one.","below_spec_floor":false,"legacy_rule_pass":true},{"name":"XLK","metric_pct":1.3144,"prior_close":174.22,"event_close":176.51,"conviction_pct":45,"reason":"Technology +1.31%, led by semiconductors (SMH +2.01% on IBKR; Nvidia +2.3%, Micron +2.6%, AMD +4.9% before its after-close print) as a dip-b'
  'uy after a three-session ~10% SOXX liquidation and the Nasdaq-100 entering correction; Apple (-1.9%) and Palantir fell on earnings but were outweighed. Moderate conviction: a bounce within a still-damaged AI trade, and no sub-2% legacy trigger.","below_spec_floor":false,"legacy_rule_pass":false}],"rejected_notable":[{"name":"XLC","metric_pct":1.1769,"prior_close":100.26,"event_close":101.44,"convi'
  'ction_pct":30,"reason":"Communication Services +1.18% cleared the 1% rail but moved with the same Big Tech rebound as XLK (Benzinga midday +0.9%, no sector-specific catalyst found); judged not independently significant.","below_spec_floor":false,"legacy_rule_pass":false}],"degraded_legs":["BigQuery down (de-authed): house-series and prior-row reads unavailable; prior closes taken from Daily.md 202'
  '6-11-02 and IBKR bars","Sector driver sources were intraday/close wrap snippets (Reuters/Business Times, Benzinga midday, MarketWatch); no single post-close sector table read"],"brent":{"label":"Brent (BZUSD, provisional same-evening read)","event_close":104.36,"event_date":"2026-11-03","prior_close":104.77,"prior_date":"2026-11-02","source":"FMP commodities-historical-price-eod-light"},"all_secto'
  'rs":{"XLK":{"prior_close":174.22,"event_close":176.51,"metric_pct":1.3144},"XLF":{"prior_close":57.56,"event_close":57.19,"metric_pct":-0.6428},"XLV":{"prior_close":184.6,"event_close":184.02,"metric_pct":-0.3142},"XLY":{"prior_close":118.16,"event_close":117.33,"metric_pct":-0.7024},"XLP":{"prior_close":90.83,"event_close":88.95,"metric_pct":-2.0698},"XLE":{"prior_close":67.25,"event_close":66.68'
  ',"metric_pct":-0.8476},"XLI":{"prior_close":169.71,"event_close":171.32,"metric_pct":0.9487},"XLB":{"prior_close":53.67,"event_close":52.59,"metric_pct":-2.0123},"XLU":{"prior_close":43.67,"event_close":43.42,"metric_pct":-0.5725},"XLRE":{"prior_close":43.64,"event_close":43.67,"metric_pct":0.0687},"XLC":{"prior_close":100.26,"event_close":101.44,"metric_pct":1.1769}},"id_check":"XLK/XLF/XLE/XLY/X'
  'LB/XLP/XLI/XLRE/XLU/XLC/XLV prior closes agree with 2026-11-02 Daily.md (XLK 174.22, XLE 67.25, XLY 118.16, XLF 57.56; XLB +1.76%, XLP +1.58%, XLI +1.38%, XLRE +1.09%, XLU +0.55%, XLC +0.36%, XLV -0.15% day moves reproduced); no id re-resolved."}',  -- in_fields
  CAST([] AS ARRAY<STRING>),  -- in_refs
  CAST(['D1', 'research-screen', 'degraded-bigquery-down'] AS ARRAY<STRING>),  -- in_tags
  CAST(NULL AS STRING),  -- in_superseded_by
  'D1 2026-11-03',  -- in_source_session
  'dbbd4698e19e44e40274c5a91592f3b2ab5806e07bcd2198996d304bf83bbecc'  -- in_expected_sha256
);

CALL `stock-trading-498512.ops.sp_log_decision_staged`(
  DATE '2026-11-03',  -- in_entry_date
  'research-screen',  -- in_entry_type
  CAST(NULL AS STRING),  -- in_strategy
  CAST(NULL AS STRING),  -- in_ticker
  CAST(NULL AS STRING),  -- in_decision
  CAST(NULL AS STRING),  -- in_conviction
  CAST(NULL AS NUMERIC),  -- in_conviction_pct
  CAST(NULL AS STRING),  -- in_sub_pattern
  CAST(NULL AS STRING),  -- in_theater_check
  'Single-name move screen 2026-11-03 (router-gated, BigQuery down)',  -- in_title
  'Router-gated single-name screen for 2026-11-03 (prior session 2026-11-02). Layer-1 rail: >=5% close-to-close and market cap >=$2B, discovered from Nasdaq quote/info closes dated 2026-11-03 across 2,117 measured names; 146 names cleared it. 49 were IBKR-confirmed, judged and passed; STVN (-28.57%) is the one rejected_notable item because its release time cannot be resolved from EDGAR (6-Ks stamped '
  'after the close).\u000a\u000aPassed (IBKR regular-session closes 11-02 to 11-03): GPK +21.22% (Q3 earnings; pre-open; conv 75; 1 prior >=5%); XMTR +16.55% (Q3 earnings; pre-open; conv 30; 3 prior >=5%); BETA +16.00% (Q3 earnings; pre-open; conv 75; 1 prior >=5%); DT -14.69% (Q3 earnings plus new $1B buyback authorization; pre-open; conv 60; 1 prior >=5%); CVI -13.09% (Q3 earnings plus a $4.2B cash'
  ' acquisition of Marathon Petroleum refinery assets (CVI is the acquirer, not a target); pre-open; conv 45; 2 prior >=5%); FISV +12.46% (Q3 earnings; pre-open; conv 60; 1 prior >=5%); RRX +11.81% (Q3 earnings; pre-open; conv 45; 2 prior >=5%); DRVN -11.24% (Q3 earnings plus Item 4.02 non-reliance on prior financials; pre-open; conv 60; 1 prior >=5%); LIND -10.64% (Q3 earnings; pre-open; conv 60; 0 '
  'prior >=5%); SRAD +10.33% (Q3 earnings (6-K); pre-open; conv 45; 2 prior >=5%); TRI -9.87% (Q3 earnings (6-K); pre-open; conv 45; 1 prior >=5%); SHC -9.64% (Q3 earnings; pre-open; conv 45; 0 prior >=5%); SYY -9.33% (Q3 earnings plus CFO appointment; pre-open; conv 45; 0 prior >=5%); ADEA -13.59% (Q3 earnings; after-close; conv 30; 3 prior >=5%); NBIX +13.42% (Q3 earnings; after-close; conv 60; 0 p'
  'rior >=5%); LSCC +10.98% (Q3 earnings; after-close; conv 30; 3 prior >=5%); TBBB +10.53% (Q3 earnings (6-K); after-close; conv 60; 0 prior >=5%); AEIS +9.63% (Q3 earnings; after-close; conv 30; 3 prior >=5%); PTCT +11.89% ($500M share repurchase authorization (Q3 earnings were 10-29); pre-open; conv 60; 1 prior >=5%); SHOP -8.74% (Q3 earnings; pre-open; conv 45; 1 prior >=5%); ZBRA -8.76% (Q3 earn'
  'ings; pre-open; conv 45; 0 prior >=5%); MDGL -8.08% (Q3 earnings; pre-open; conv 45; 0 prior >=5%); MTCH -8.49% (Q3 earnings; after-close; conv 45; 0 prior >=5%); RVTY +7.84% (Q3 earnings; pre-open; conv 45; 1 prior >=5%); RYTM -7.49% (Q3 earnings; pre-open; conv 45; 0 prior >=5%); TLN +7.29% (Q3 earnings; pre-open; conv 45; 1 prior >=5%); ADM -6.82% (Q3 earnings; pre-open; conv 45; 0 prior >=5%);'
  ' ALSN +5.16% (Q3 earnings; after-close; conv 45; 0 prior >=5%); APTV -6.53% (Q3 earnings (post-spin Aptiv; Item 8.01 supplemental investor information); pre-open; conv 45; 0 prior >=5%); BALL -7.14% (Q3 earnings; pre-open; conv 45; 0 prior >=5%); CALX -7.97% (Q3 earnings; after-close; conv 45; 0 prior >=5%); CE +5.05% (Q3 earnings (8-K 2.02 plus Item 7.01 webcast notice); after-close; conv 45; 0 p'
  'rior >=5%); DD +8.61% (Q3 earnings; pre-open; conv 45; 0 prior >=5%); ETN +7.00% (Q3 earnings; pre-open; conv 45; 2 prior >=5%); FN +15.45% (Q3 earnings; after-close; conv 30; 5 prior >=5%); GRAB +9.09% (Q3 earnings (6-K; the calendar scheduled it after-hours 11-02, EDGAR shows 6-K stamps only on 11-03 pre-open); pre-open; conv 45; 1 prior >=5%); HGTY +7.17% (Q3 earnings; pre-open; conv 45; 0 prio'
  'r >=5%); IT -13.19% (Q3 earnings; pre-open; conv 45; 2 prior >=5%); JAZZ +7.13% (Q3 earnings; after-close; conv 45; 0 prior >=5%); KDP -5.65% (Q3 earnings; pre-open; conv 45; 0 prior >=5%); KMX -5.39% (Strategic Update investor event at 8:00 ET (8-K Item 7.01); pre-open; conv 45; 0 prior >=5%); LBTYK +5.51% (Q3 earnings (8-K 2.02/7.01; spin-off plan discussed, no signed deal); pre-open; conv 45; 0'
  ' prior >=5%); LDOS -6.55% (Q3 earnings (8-K accepted 2026-11-02 22:38Z; the calendar scheduled it pre-market 11-03); after-close; conv 45; 0 prior >=5%); MSA -6.64% (Q3 earnings; after-close; conv 45; 0 prior >=5%); NPO +6.06% (Q3 earnings; pre-open; conv 45; 1 prior >=5%); OTTR -8.85% (Q3 earnings; pre-open; conv 45; 0 prior >=5%); PAY -11.50% (Q3 earnings; after-close; conv 60; 1 prior >=5%); RI'
  'G -5.30% (Q3 earnings plus fleet status report; after-close; conv 45; 2 prior >=5%); ULS +7.00% (Q3 earnings; pre-open; conv 45; 0 prior >=5%).\u000a\u000aNoisy names: FN has 5 other >=5% sessions in the prior 10; XMTR, ADEA, LSCC and AEIS have 3; CVI, RRX, SRAD, ETN, IT and RIG have 2.\u000a\u000aDegraded: BigQuery down, so the durable close-chain check did not run; Deal-pinned: none found. Meter'
  'ed calls: none.',  -- in_body_md
  CAST(NULL AS STRING),  -- in_fields
  CAST([] AS ARRAY<STRING>),  -- in_refs
  CAST(['D1', 'research-screen', 'degraded-bigquery-down'] AS ARRAY<STRING>),  -- in_tags
  CAST(NULL AS STRING),  -- in_superseded_by
  'D1 2026-11-03',  -- in_source_session
  CAST(['fields'] AS ARRAY<STRING>),  -- in_staged_args
  '30cceaa8189ccce4db1acd50dcc4000e7cadac18e15a5e7c9c3361061057b2ce'  -- in_expected_sha256
);

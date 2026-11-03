-- NOT EXECUTED (BigQuery down). Issue verbatim when BigQuery is available; idempotent on (as_of_date, scope, key).
INSERT INTO `stock-trading-498512.events.regime_events` (as_of_date, scope, key, value, numeric_value, rationale, source_review_ref)
VALUES (
  DATE '2026-11-03',
  'TECHNICAL_INPUT',
  'EQUITY_BREADTH_PCT',
  'Barchart $S5TH',
  NUMERIC '61.63',
  'Source: https://www.barchart.com/stocks/quotes/$S5TH/overview?cb=20261103 via tavily_extract (advanced), fetched ~22:07Z 2026-11-03 (~17:07 ET). Figure as published: 61.63, -1.78 (-2.81%), page stamp 16:52 ET (at/after the 16:00 ET close, settled), headed "Quote Overview for Tue, Nov 3rd, 2026"; Day Low 61.63, Day High 63.81, Open 62.02, Previous Close 63.41 (matches stored 2026-11-02 value 63.41 exactly). Not an exact repeat of the prior session. SINGLE usable settled source: EODData https://www.eoddata.com/stockquote/INDEX/S5TH.htm (WebFetch, cb=20261103) read 61.82 with quote-box stamp 15:15 ET (pre-close, UNSETTLED), table row 03 Nov Open 62.02 High 63.81 Low 61.43 Close 61.82, PREV 63.41; it can share Barchart''s feed and is not counted as an independent or settled corroboration (gap 0.19pp, far inside the 5pp disagreement bar). ChartRow https://chartrow.com/sp500/market-breadth (WebFetch, cache-busted, read twice: ~22:05Z and a final re-read ~22:09Z) states "as of market close, Nov 2, 2026": 313 of 496 eligible (63%) although its header says Nov 3 4:00 PM ET with Nov 3 values labelled live; chartrow_unconfirmed=lag session 2026-11-02. chartrow_lagged_dod_gap=0.03 for 2026-11-02 (ChartRow 294/497 = 59.16% on 2026-10-30 -> 313/496 = 63.10% on 2026-11-02 = +3.94pp vs $S5TH +3.97pp 59.44 -> 63.41). Direction of the 2026-11-03 move (-1.78pp) is therefore not yet cross-checked by ChartRow; the next run''s lagged read settles it. Single-source disclosure: value of record rests on Barchart alone. Prior session 2026-11-02 stored 63.41 is unrevised on Barchart (Previous Close 63.41).',
  'D1 2026-11-03 EQUITY-BREADTH OBSERVATION'
);
